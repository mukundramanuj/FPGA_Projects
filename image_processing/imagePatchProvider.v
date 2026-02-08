// This module takes one pixel of image at a time,
// fills the line buffers and outputs successive 
// 3x3 pixel matrices which is fed as i/p to convolution module later on
module imagePatchProvider(
	input 				i_clk,
	input 				i_rst,
	input [7:0] 		i_pixel_data,
	input 				i_pixel_data_valid,
	input				i_read_enable,
	output reg [71:0] 	o_pixel_data,
	output 				o_pixel_data_valid
);

// Image Constants
 parameter IMG_WIDTH  = 256;
 parameter IMG_HEIGHT = 250;
 parameter PIXELS_IN_3_LINE_BUFFERS = 768; // IMG_WIDTH * 3

//********************  writing to the line buffer  ********************
// Internal Signals
reg select_lb_to_write [3:0];
reg [1:0] select_lb_to_write_index; // Selects LBs 0-3
reg [7:0] pixelCounter;
	 
always @(posedge i_clk) begin	
	if (i_rst)
		pixelCounter <= 0;
	else if (i_pixel_data_valid) begin
		if (pixelCounter == IMG_WIDTH - 1)
			pixelCounter <= 0;
		else
			pixelCounter <= pixelCounter + 1;
	end

end


always @(posedge i_clk) begin
	if (i_rst)
		select_lb_to_write_index <= 0; // enables i_pixel_data to go to lb0
	else if (pixelCounter == IMG_WIDTH-1 && i_pixel_data_valid)
		select_lb_to_write_index <= select_lb_to_write_index + 1; // if select_lb_to_write_index is 11, adding another 1 makes it 100 but MSB is dropped making it 00
end

always @(*) begin
	select_lb_to_write[0] = 1'b0;
	select_lb_to_write[1] = 1'b0;
	select_lb_to_write[2] = 1'b0;
	select_lb_to_write[3] = 1'b0;
	select_lb_to_write[select_lb_to_write_index] <= i_pixel_data_valid;
end

// ***************** reading from the line buffer *********************
reg select_lb_to_read [3:0];
reg [1:0] select_lb_to_read_index; // index of 1st of the three lb read enable signals
reg [9:0] totalPixelCounter;
reg [7:0] readCounter;
wire [23:0] lb_data [3:0];
reg rd_line_buffers;

// total pixel counter logic
always @(posedge i_clk) begin
	if (i_rst)
		totalPixelCounter <= 10'b0;
	else begin
		if (i_pixel_data_valid & !rd_line_buffers)
			totalPixelCounter <= totalPixelCounter + 1;
		else if (rd_line_buffers & !i_pixel_data_valid)
			totalPixelCounter <= totalPixelCounter - 1;
		else
			totalPixelCounter <= totalPixelCounter;
	end
end

// logic for read enable - finite state machine
localparam IDLE = 1'b0,
		   READ = 1'b1;
reg rdState;

always @(posedge i_clk) begin
	if (i_rst) begin
		rdState <= IDLE;
		rd_line_buffers <= 0;
	end
	else begin
		case(rdState)
		IDLE: begin
					if (totalPixelCounter >= PIXELS_IN_3_LINE_BUFFERS - 1 && i_read_enable) begin // all 3 line buffers filled, so start reading
						rdState <= READ;
						rd_line_buffers <= 1'b1;
					end
				end
		READ: begin
					if (readCounter == IMG_WIDTH - 1) begin // all three line buffers not yet filled, so wait
						rdState <= IDLE;
						rd_line_buffers <= 1'b0;
					end
				end
		endcase
	end
end


// line buffers selection
always @(posedge i_clk) begin
	if (i_rst)
		select_lb_to_read_index <= 0;
	else if (readCounter == IMG_WIDTH-1)
		select_lb_to_read_index <= select_lb_to_read_index + 1;
end

// read counter increment
always @(posedge i_clk) begin
	if (i_rst || readCounter == IMG_WIDTH - 1)
		readCounter <= 8'b0;
	else if (rd_line_buffers)
		readCounter <= readCounter + 1;
end

always @(*) begin
	case (select_lb_to_read_index)
	  0:begin
			select_lb_to_read[0] = rd_line_buffers;
			select_lb_to_read[1] = rd_line_buffers;
			select_lb_to_read[2] = rd_line_buffers;
			select_lb_to_read[3] = 1'b0;
	  end
	  1:begin
			select_lb_to_read[0] = 1'b0;
			select_lb_to_read[1] = rd_line_buffers;
			select_lb_to_read[2] = rd_line_buffers;
			select_lb_to_read[3] = rd_line_buffers;
	  end
	  2:begin
			select_lb_to_read[0] = rd_line_buffers;
			select_lb_to_read[1] = 1'b0;
			select_lb_to_read[2] = rd_line_buffers;
			select_lb_to_read[3] = rd_line_buffers;
	  end
	  3:begin
			select_lb_to_read[0] = rd_line_buffers;
			select_lb_to_read[1] = rd_line_buffers;
			select_lb_to_read[2] = 1'b0;
			select_lb_to_read[3] = rd_line_buffers;
	  end
	endcase
end

// concatenating outputs of 3 line buffers
always @(*) begin
	case (select_lb_to_read_index)
		0: begin
			o_pixel_data = {lb_data[2], lb_data[1], lb_data[0]};
		end
		1: begin
			o_pixel_data = {lb_data[3], lb_data[2], lb_data[1]};
		end
		2: begin
			o_pixel_data = {lb_data[0], lb_data[3], lb_data[2]};
		end
		3: begin
			o_pixel_data = {lb_data[1], lb_data[0], lb_data[3]};
		end
	endcase
end

assign o_pixel_data_valid = rd_line_buffers;

// instantiating line buffers 
lineBuffer lb0(
.i_clk(i_clk),
.i_rst(i_rst),
.i_data(i_pixel_data),
.i_data_valid(select_lb_to_write[0]),
.o_data(lb_data[0]), 
.i_rd_data(select_lb_to_read[0]));

lineBuffer lb1(
.i_clk(i_clk),
.i_rst(i_rst),
.i_data(i_pixel_data),
.i_data_valid(select_lb_to_write[1]),
.o_data(lb_data[1]), 
.i_rd_data(select_lb_to_read[1]));

lineBuffer lb2(
.i_clk(i_clk),
.i_rst(i_rst),
.i_data(i_pixel_data),
.i_data_valid(select_lb_to_write[2]),
.o_data(lb_data[2]),
.i_rd_data(select_lb_to_read[2]));

lineBuffer lb3(
.i_clk(i_clk),
.i_rst(i_rst),
.i_data(i_pixel_data),
.i_data_valid(select_lb_to_write[3]),
.o_data(lb_data[3]), 
.i_rd_data(select_lb_to_read[3]));

endmodule

