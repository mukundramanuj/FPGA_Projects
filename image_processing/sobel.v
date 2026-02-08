module sobel(
	input			i_clk,
	input			i_rst,
	input [71:0]	i_pixel_patch_data,
	input			i_pixel_patch_data_valid,
	output [7:0]	o_filtered_data,
	output			o_filtered_data_valid
);

wire [7:0] 	convolved_data;
wire 		convolved_data_valid;

assign o_filtered_data = convolved_data;
assign o_filtered_data_valid = convolved_data_valid;

conv conv(
	.i_clk(i_clk),
	.i_pixel_data(i_pixel_patch_data),
	.i_pixel_data_valid(i_pixel_patch_data_valid),
	.o_convolved_data(convolved_data),
	.o_convolved_data_valid(convolved_data_valid)
);

endmodule