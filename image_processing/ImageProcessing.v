module ImageProcessing(
	input  MAX10_CLK1_50,
	input i_rst,
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
    parameter IMG_WIDTH  = 200;
    parameter IMG_HEIGHT = 200;

    // Internal Signals
    wire vga_clk;          // 25.175 MHz from PLL
    wire [7:0] rom_data;
	 reg [7:0] lb_data [2:0];
	 reg  [1:0] lb_data_index;
	 reg [1:0]  c;
    reg  [15:0] rom_addr;  // 16-bit address for 65536 depth

	 reg[9:0] x;
	 reg[9:0] y;
	 wire i_data_valid = 1;
	 
always @(posedge vga_clk) begin
	if(i_rst) begin
		rom_addr <= 16'b0;
		x <= 10'b0;
		y <= 10'b0;
		lb_data_index <= 0;
	end
end

always @(posedge vga_clk) begin
	 rom_addr <= x + (y * IMG_WIDTH);
end 

always @(posedge vga_clk) begin
	if(x == IMAGE_WIDTH)
		x <= 10'b0;
	else
		x <= x + 1;
end

always @(posedge vga_clk) begin
	if(y == IMAGE_HEIGHT)
		y <= 10'b0;
	else
		y <= y + 1;
end

always @(posedge vga_clk) begin
	IF (lb_data_index == 2b'11)
		lb_data_index <= 0;
	else if (x == IMAGE_WIDTH)
		lb_data_index <= lb_data_index + 1;
end

always @(posedge vga_clk) begin
	lb_data[lb_data_index] <= rom_data;
end

// --- 2. ROM Instance ---
image_mem rom_inst (
  .address (rom_addr),
  .clock   (vga_clk),
  .data    (12'b0),      
  .wren    (1'b0),      
  .q       (rom_data)
);
 





