module sobel(
	input			i_clk,
	input			i_rst,
	input [71:0]	i_pixel_patch_data,
	input			i_pixel_patch_data_valid,
	output [7:0]	o_filtered_data,
	output			o_filtered_data_valid
);

// gradients
wire signed [7:0] Gx;
wire signed [7:0] Gy;
wire Gx_valid;
wire Gy_valid;
wire [7:0] abs_Gx;
wire [7:0] abs_Gy;
wire [8:0] gradient_sum; // intermediate variable to account for overflow

wire [71:0] kernel_x = {
   -8'sd1,  8'sd0,  8'sd1,
   -8'sd2,  8'sd0,  8'sd2,
   -8'sd1,  8'sd0,  8'sd1
};

wire [71:0] kernel_y = {
    -8'sd1,  -8'sd2,  -8'sd1,
    8'sd0,   8'sd0,   8'sd0,
    8'sd1,   8'sd2,   8'sd1
};

assign abs_Gx = (Gx == -8'sd128) ? 8'd127 : ((Gx < 0) ? -Gx :Gx);
assign abs_Gy = (Gy == -8'sd128) ? 8'd127 : ((Gy < 0) ? -Gy :Gy);
assign gradient_sum = abs_Gx + abs_Gy;

assign o_filtered_data = (gradient_sum > 9'd255) ? 8'd255 : gradient_sum[7:0];
assign o_filtered_data_valid = (Gx_valid & Gy_valid);

conv conv_x(
	.i_clk(i_clk),
	.i_pixel_data(i_pixel_patch_data),
	.i_pixel_data_valid(i_pixel_patch_data_valid),
	.i_kernel(kernel_x),
	.o_convolved_data(Gx),
	.o_convolved_data_valid(Gx_valid)
);

conv conv_y(
	.i_clk(i_clk),
	.i_pixel_data(i_pixel_patch_data),
	.i_pixel_data_valid(i_pixel_patch_data_valid),
	.i_kernel(kernel_y),
	.o_convolved_data(Gy),
	.o_convolved_data_valid(Gy_valid)
);

endmodule