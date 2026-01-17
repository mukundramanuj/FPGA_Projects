module lineBuffer(
input i_clk,
input i_rst,
input [7:0] i_data,
input i_data_valid,
output [23:0] o_data, // 3 pixels (8-bpp)
input i_rd_data); // if i_rd_data is high => read mode

reg [7:0] line [511:0]; // actual line buffer memory where pixel data is stored
reg [8:0] wrPntr;
reg [8:0] rdPntr;

// write operation
always @(posedge i_clk)
begin
  if (i_data_valid)
    line[wrPntr] <= i_data; 
end

// reset and increment of write pointer
always @(posedge i_clk)
begin
  if (i_rst)
    wrPntr <= 'd0;
  else if(i_data_valid)
    wrPntr <= wrPntr + 1;
end

// assignment of output done sequentially to avoid 1 clock cycle latency during read operation
assign o_data = {line[rdPntr], line[rdPntr + 1], line[rdPntr + 2]};

// reset and increment of read pointer
always @(posedge i_clk)
begin
  if(i_rst)
    rdPntr <= 'd0;
  else if (i_rd_data)
    rdPntr <= rdPntr + 'd1;
end

endmodule



