module lineBuffer(
  input i_clk,
  input i_rst,
  input [7:0] i_data,
  input i_data_valid,
  output [23:0] o_data, // 3 pixels (8-bpp)
  input i_rd_data  // if i_rd_data is high => read mode
);

reg [7:0] line [255:0]; // actual line buffer memory where pixel data is stored
reg [7:0] wrPntr; // 0 to 255 addresses => if incremented beyond 255, overflows to 0
reg [7:0] rdPntr;

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
// Use Clamp-to-Edge boundary replication for a cleaner visual result
wire [7:0] idx0 = rdPntr;
wire [7:0] idx1 = (rdPntr == 8'd255) ? 8'd255 : (rdPntr + 8'd1);
wire [7:0] idx2 = (rdPntr >= 8'd254) ? 8'd255 : (rdPntr + 8'd2);

assign o_data = {line[idx2], line[idx1], line[idx0]};

// reset and increment of read pointer
always @(posedge i_clk)
begin
  if(i_rst)
    rdPntr <= 'd0;
  else if (i_rd_data)
    rdPntr <= rdPntr + 'd1;
end

endmodule



