// This module takes one pixel of image at a time,
// fills the line buffers and outputs successive 
// 3x3 pixel matrices which is fed as i/p to convolution module later on
module imageControl(
	input 				i_clk,
	input 				i_rst,
	input [7:0] 		i_pixel_data,
	input 				i_pixel_data_valid,
	output reg [71:0] o_pixel_data,
	output 				o_pixel_data_valid
);

// Image Constants
 parameter IMG_WIDTH  = 256;
 parameter IMG_HEIGHT = 200;
 parameter PIXELS_IN_3LBS = 600;

//********************  writing to the line buffer  ********************
// Internal Signals
reg select_lb_write [3:0];
reg [1:0] select_lb_write_index;
reg [7:0] pixelCounter;
	 
always @(posedge vga_clk) begin
	if (i_rst || pixelCounter == IMAGE_WIDTH - 1)
		pixelCounter <= 8'b0;
	else if (i_pixel_data_valid)
		pixelCounter <= pixelCounter + 1;
end


always @(posedge vga_clk) begin
	if (i_rst)
		select_lb_write_index <= 0; // enables i_pixel_data to go to lb0
	else if (pixelCounter == IMAGE_WIDTH-1 && i_pixel_data_valid)
		select_lb_write_index <= select_lb_write_index + 1; // if select_lb_write_index is 11, adding another 1 makes it 100 but MSB is dropped making it 00
end

always @(*) begin
		select_lb_write = 4'h0;
		select_lb_write[select_lb_write_index] <= i_pixel_data_valid;
end

// ***************** reading from the line buffer *********************
reg select_lb_read [3:0];
reg [1:0] select_first_lb_read_index;
reg [9:0] totalPixelCounter;
reg [7:0] read_window_counter;
wire [23:0] lb0_data;
wire [23:0] lb1_data;
wire [23:0] lb2_data;
wire [23:0] lb3_data;
reg read_line_buffer;



// instantiating line buffers 
lineBuffer lb0(
.i_clk(i_clk),
.i_rst(i_rst),
.i_data(i_pixel_data),
.i_data_valid(select_lb_write[0]),
.o_data(lb0_data), 
.i_rd_data(select_lb_read[0]));

lineBuffer lb1(
.i_clk(i_clk),
.i_rst(i_rst),
.i_data(i_pixel_data),
.i_data_valid(select_lb_write[1]),
.o_data(lb1_data), 
.i_rd_data(select_lb_read[1]));

lineBuffer lb2(
.i_clk(i_clk),
.i_rst(i_rst),
.i_data(i_pixel_data),
.i_data_valid(select_lb_write[2]),
.o_data(lb2_data), 
.i_rd_data(select_lb_read[2]));

lineBuffer lb3(
.i_clk(i_clk),
.i_rst(i_rst),
.i_data(i_pixel_data),
.i_data_valid(select_lb_write[3]),
.o_data(lb3_data), 
.i_rd_data(select_lb_read[3]));



