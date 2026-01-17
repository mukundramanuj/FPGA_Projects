module imageControl(
input i_clk,
input i_rst,
input [7:0] i_pixel_data,
input i_pixel_data_valid,
output reg [71:0] o_pixel_data, // o_pixel_data becomes the input to the MAC module
output o_pixel_data_valid);

reg [8:0] pixelCounter;
reg [1:0] currentLineBuffer;
reg [3:0] lineBufferDataValid;
reg [3:0] lineBuffRdData;
reg [1:0] currentRdLineBuffer;

wire [23:0] lb0data;
wire [23:0] lb1data;
wire [23:0] lb2data;
wire [23:0] lb3data;

always @(posedge i_clk)
begin
  if(i_rst)
    pixelCounter <= 0;
  else begin
    if(i_pixel_data_valid)
      pixelCounter <= pixelCounter + 1;
  end
end

always @(posedge i_clk) begin
  if (i_rst)
    currentLineBuffer <= 0;
  else begin
    if (pixelCounter == 511 & i_pixel_data_valid) // condition for 512th pixel entering line buffer
      currentLineBuffer <= currentLineBuffer + 1;
  end
end

always @(*)
begin
  lineBufferDataValid = 4'h0;
  lineBufferDataValid[currentLineBuffer] = i_pixel_data_valid;
end

always @(posedge i_clk) begin
  if(i_rst) 
    rdCounter <= 0;
  else begin
    if(rd_line_buffer)
      rdCounter <= rdCounter + 1;
  end
end

always @(posedge i_clk)
begin
  if(i_rst) begin
    currentRdLineBuffer <= 0;
  end
  else begin
    if(rdCounter == 511 & rd_line_buffer)
      currentRdLineBuffer <= currentRdLineBuffer + 1;
  end
end


always @(*)
begin
  case(currentRdLineBuffer)
    0: begin 
      o_pixel_data = {lb2data,lb1data,lb0data}
    end
    1: begin 
      o_pixel_data = {lb3data,lb2data,lb1data}
    end
    2: begin 
      o_pixel_data = {lb0data,lb3data,lb2data}
    end
    3: begin 
      o_pixel_data = {lb1data,lb0data,lb3data}
    end
  endcase
end

always @(*)
begin
  
end

lineBuffer lB0(
.i_clk(i_clk),
.i_rst(i_rst),
.i_data(i_pixel_data),
.i_data_valid(lineBufferDataValid[0]),
.o_data(lb0data),
.i_rd_data(lineBuffRdData[0]));

lineBuffer lB1(
.i_clk(i_clk),
.i_rst(i_rst),
.i_data(i_pixel_data),
.i_data_valid(lineBufferDataValid[1]),
.o_data(lb1data),
.i_rd_data(lineBuffRdData[1]));

lineBuffer lB2(
.i_clk(i_clk),
.i_rst(i_rst),
.i_data(i_pixel_data),
.i_data_valid(lineBufferDataValid[2]),
.o_data(lb2data),
.i_rd_data(lineBuffRdData[2]));

lineBuffer lB3(
.i_clk(i_clk),
.i_rst(i_rst),
.i_data(i_pixel_data),
.i_data_valid(lineBufferDataValid[3]),
.o_data(lb3data),
.i_rd_data(lineBuffRdData[3]));