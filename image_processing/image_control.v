// This module takes one pixel of image at a time,
// fills the line buffers and outputs successive 
// 3x3 pixel matrices which is fed as i/p to convolution module later on
module image_control(
	input 				i_clk,
	input 				i_rst,
	input [7:0] 		i_pixel_data,
	input 				i_pixel_data_valid,
	output reg [71:0] o_pixel_data,
	output 				o_pixel_data_valid
);

// Image Constants
 parameter IMG_WIDTH  = 200;
 parameter IMG_HEIGHT = 200;

// Internal Signals
reg lb_data_valid [3:0];
reg [1:0] lb_data_valid_index;
reg [7:0] wrPtr;
	 
always @(posedge vga_clk) begin
	if (i_rst)
		wrPtr <= 8'b0;
	else if(wr == IMAGE_WIDTH)
		wrPtr <= 8'b0;
	else
		wrPtr <= wrPtr + 1;
end


always @(posedge vga_clk) begin
	if (i_rst)
		lb_data_valid_index <= 0; // enables i_pixel_data to go to lb0
	else if (wrPtr == IMAGE_WIDTH-1 & i_pixel_data_valid)
		lb_data_valid_index <= lb_data_valid_index + 1; // if lb_data_valid_index is 11, adding another 1 makes it 100 but MSB is dropped making it 00
end

always @(posedge vga_clk) begin
		lb_data_valid = 4'h0;
		lb_data_valid[lb_data_valid_index] <= 1'b1;
end

// instantiating line buffers 
lineBuffer lb0(
.i_clk(i_clk),
.i_rst(i_rst),
.i_data(i_pixel_data),
.i_data_valid(lb_data_valid[0]),
.o_data(), 
.i_rd_data());

lineBuffer lb1(
.i_clk(i_clk),
.i_rst(i_rst),
.i_data(i_pixel_data),
.i_data_valid(lb_data_valid[1]),
.o_data(), 
.i_rd_data());

lineBuffer lb2(
.i_clk(i_clk),
.i_rst(i_rst),
.i_data(i_pixel_data),
.i_data_valid(lb_data_valid[2]),
.o_data(), 
.i_rd_data());

lineBuffer lb3(
.i_clk(i_clk),
.i_rst(i_rst),
.i_data(i_pixel_data),
.i_data_valid(lb_data_valid[3]),
.o_data(), 
.i_rd_data());



