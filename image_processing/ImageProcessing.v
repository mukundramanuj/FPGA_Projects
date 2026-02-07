module ImageProcessing(
	input  MAX10_CLK1_50,
	input i_rst,
	input sobel,
	output [3:0] VGA_R,    // Red 4-bit
   output [3:0] VGA_G,    // Green 4-bit
   output [3:0] VGA_B,    // Blue 4-bit
   output VGA_HS,         // H-Sync
   output VGA_VS 			// V-Sync
);

	// Timing Constants for 640x480 @ 60Hz
    parameter H_VISIBLE = 640;
    parameter H_FRONT   = 16;
    parameter H_SYNC    = 96;
    parameter H_BACK    = 48;
    parameter H_TOTAL   = 800;

    parameter V_VISIBLE = 480;
    parameter V_FRONT   = 10;
    parameter V_SYNC    = 2;
    parameter V_BACK    = 33;
    parameter V_TOTAL   = 525;

    // Image Constants
    parameter IMG_WIDTH  = 256;
    parameter IMG_HEIGHT = 200;

    // Internal Signals,
    wire vga_clk;          // 25.175 MHz from PLL
    wire [7:0] rom_data;
    reg  [15:0] rom_addr;  // 16-bit address for 65536 depth
	 // ROM pixel coordinates
	 reg [7:0] rom_h; // ROM image column counter - 0-255
	 reg [7:0] row_v; // ROM row counter

    // PLL Instance ---
    // Note: Ensure your PLL IP 'inclk0' is set to 50MHz in the Wizard
    sync_clk pll_inst (
        .inclk0 (MAX10_CLK1_50), 
        .c0     (vga_clk),    
        .c1     ()            
    );

    // ROM Instance ---
    image_mem rom_inst (
        .address (rom_addr),
        .clock   (vga_clk),
        .data    (8'b0),      
        .wren    (1'b0),      
        .q       (rom_data)
    );

	 // -------------------------IMAGE PROCESSING LOGIC---------------------------------
	 // Capture greyscale image, as is
	 wire [3:0] raw_r = rom_data[7:4];  
	 wire [3:0] raw_g = rom_data[7:4]; 
	 wire [3:0] raw_b = rom_data[7:4];

	 // h and v counters initialization
    reg [9:0] h_cnt = 0;
    reg [9:0] v_cnt = 0;
 
	 // --- Sync Generation ---
    always @(posedge vga_clk) begin
        if (h_cnt < H_TOTAL - 1) 
            h_cnt <= h_cnt + 1;
        else begin
            h_cnt <= 0;
            if (v_cnt < V_TOTAL - 1) 
                v_cnt <= v_cnt + 1;
            else 
                v_cnt <= 0;
        end
    end
	 
	 assign VGA_HS = (h_cnt >= (H_VISIBLE + H_FRONT) && h_cnt < (H_VISIBLE + H_FRONT + H_SYNC)) ? 1'b0 : 1'b1;
    assign VGA_VS = (v_cnt >= (V_VISIBLE + V_FRONT) && v_cnt < (V_VISIBLE + V_FRONT + V_SYNC)) ? 1'b0 : 1'b1;

    // --- 4. Video Display Logic ---
    wire video_on = (h_cnt < H_VISIBLE) && (v_cnt < V_VISIBLE);
    
    // Check if we are inside the image bounds (drawing at top-left 0,0)
    wire img_on = (h_cnt < IMG_WIDTH) && (v_cnt < IMG_HEIGHT);

	 // Read next pixel from ROM by updating ROM address
	 always @(posedge vga_clk) begin
        if (img_on)
            rom_addr <= h_cnt + (v_cnt * IMG_WIDTH);
        else
            rom_addr <= 0;
    end
	 
	 reg [3:0] filtered_r, filtered_g, filtered_b;
	 filtered_r = raw_r;
	 filtered_g = raw_g;
	 filtered_b = raw_b;
	 
	 
	 // Final o/p signal assignments
	assign VGA_R = (video_on && img_on) ? filtered_r : 4'b0;
	assign VGA_G = (video_on && img_on) ? filtered_g : 4'b0;
	assign VGA_B = (video_on && img_on) ? filtered_b : 4'b0;

endmodule


