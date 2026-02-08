module imageProcessingTop(
	input  MAX10_CLK1_50,
	input i_rst,
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
wire  [7:0]	rom_data;
reg  [15:0] rom_addr;  // 16-bit address for 65536 depth
// ROM pixel coordinates
reg [7:0] rom_h; // ROM image column counter - 0-255
reg [7:0] rom_v; // ROM row counter
reg       rom_data_valid; // indicates when the data arrives from ROM (usually one clock after rom_addr is given)

//PLL Instance ---
//Note: Ensure your PLL IP 'inclk0' is set to 50MHz in the Wizard
sync_clk pll_inst (
.inclk0 (MAX10_CLK1_50),
.c0     (vga_clk)
);

// ROM Instance ---
image_mem rom_inst (
.address (rom_addr),
.clock   (vga_clk),
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

// --- Sync Generation for VGA ---
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

// --- Pipeline Synchronization Delay ---
// The processing pipeline (IPP + Sobel) has a 4-cycle latency.
// We must delay the VGA sync signals so the monitor timing matches the data arrival.
reg [3:0] h_sync_d, v_sync_d;
reg [3:0] video_on_d;
reg [3:0] img_on_d;

wire vga_hs_raw = (h_cnt >= (H_VISIBLE + H_FRONT) && h_cnt < (H_VISIBLE + H_FRONT + H_SYNC)) ? 1'b0 : 1'b1;
wire vga_vs_raw = (v_cnt >= (V_VISIBLE + V_FRONT) && v_cnt < (V_VISIBLE + V_FRONT + V_SYNC)) ? 1'b0 : 1'b1;

// --- 4. Video Display Logic ---
wire video_on = (h_cnt < H_VISIBLE) && (v_cnt < V_VISIBLE);
// Check if we are inside the image bounds (drawing at top-left 0,0)
wire img_on = (h_cnt < IMG_WIDTH) && (v_cnt < IMG_HEIGHT);

always @(posedge vga_clk) begin
	h_sync_d   <= {h_sync_d[2:0], vga_hs_raw};
	v_sync_d   <= {v_sync_d[2:0], vga_vs_raw};
	video_on_d <= {video_on_d[2:0], video_on};
	img_on_d   <= {img_on_d[2:0], img_on};
end

assign VGA_HS = h_sync_d[3];
assign VGA_VS = v_sync_d[3];

// Logic to decide when the ROM should be "running"
// Note: writes are driven by the raw counters (0-latency relative to ROM addr)
wire is_priming_v = (v_cnt >= V_TOTAL - 3); // Rows 522, 523, 524
wire is_visible_v = (v_cnt < IMG_HEIGHT);   // Rows 0 to 255
wire is_active_h  = (h_cnt < IMG_WIDTH);    // Pixels 0 to 199

// The ROM only runs when we are in the 256-pixel "window"
// of a row we care about (Priming or Visible).
wire rom_running = (is_priming_v || is_visible_v) && is_active_h;

always @(posedge vga_clk) begin
	if (v_cnt == V_TOTAL - 3 && h_cnt == 0) begin
		// Reset ROM counters during the "Priming" phase in the Back Porch
		rom_h <= 0;
		rom_v <= 0;
	end
	else if (rom_running) begin
		// Increment ROM address
		if (rom_h < IMG_WIDTH - 1) begin
			rom_h <= rom_h + 1;
		end
		else begin
			rom_h <= 0;
			if (rom_v < IMG_HEIGHT - 1)
				rom_v <= rom_v + 1;
			else
				rom_v <= 0;
		end
	end
	// This creates the 1-cycle delay needed to match the ROM's latency.
	// When rom_running was HIGH in 'Cycle N', rom_data_valid is HIGH in 'Cycle N+1'.
	rom_data_valid <= rom_running;
end

// Your ROM address is then calculated from these custom counters
// assign rom_addr = (rom_v * IMG_WIDTH) + rom_h;

always @(*) begin
	rom_addr <= rom_h + (rom_v * IMG_WIDTH);
end

wire [71:0]	pixel_patch_data;
wire		pixel_patch_data_valid;
wire [7:0]	filtered_data;
wire		filtered_data_valid;

// Iniitiaze image patch provider
imagePatchProvider IPP(
	.i_clk(vga_clk),
	.i_rst(~i_rst), // Inverted for Active Low button (KEY0)
	.i_pixel_data(rom_data),
	.i_pixel_data_valid(rom_data_valid),
	// We use the raw 'img_on' to start the read pipeline.
	// The data will emerge 4 cycles later, matching 'img_on_d[3]'.
	.i_read_enable(img_on), 
	.o_pixel_data(pixel_patch_data),
	.o_pixel_data_valid(pixel_patch_data_valid)
);

sobel SBL(
	.i_clk(vga_clk),
	.i_rst(~i_rst), // Inverted for Active Low button (KEY0)
	.i_pixel_patch_data(pixel_patch_data),
	.i_pixel_patch_data_valid(pixel_patch_data_valid),
	.o_filtered_data(filtered_data),
	.o_filtered_data_valid(filtered_data_valid)
);

// Final o/p signal assignments
// Use the DELAYED video signals to match the pipeline data
assign VGA_R = (video_on_d[3] && img_on_d[3] && filtered_data_valid) ? filtered_data[7:4] : 4'b0;
assign VGA_G = (video_on_d[3] && img_on_d[3] && filtered_data_valid) ? filtered_data[7:4] : 4'b0;
assign VGA_B = (video_on_d[3] && img_on_d[3] && filtered_data_valid) ? filtered_data[7:4] : 4'b0;

endmodule


