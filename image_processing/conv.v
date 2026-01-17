// Multiply Accumulate module (MAC)

module conv(
input i_clk,
input [71:0] i_pixel_data,
input reg i_pixel_data_valid,
output reg [7:0] o_convolved_data,
output reg o_convolved_data_valid);

integer i;
reg [7:0] kernel [8:0];
reg [15:0] multData[8:0];
reg [15:0] sumDataInt;
reg [15:0] sumData;
reg multDataValid;
reg sumDataValid;

// operation performed is box blur
// initalize all 9 values in the kernel to 1
initial begin
  for (i = 0; i < 9; i = i+1) begin
    kernel[i] = 1;
  end
end

// multiplication
always @(posedge i_clk) begin
  for (i = 0; i < 9; i = i+1) begin
    multData[i] <= kernel[i]*i_pixel_data[i*8+:8];
  end
multDataValid <= i_pixel_data_valid;
end

// summation using parallel adder (purely combinational)
always @(*) begin
sumDataInt = 0;
  for (i = 0; i < 9; i = i+1) begin
    sumDataInt = sumDataInt + multData[i];
  end
end

always @(posedge i_clk) begin
  sumData <= sumDataInt;
  sumDataValid <= multDataValid;
end

// Division by 9
always @(posedge i_clk) begin
  o_convolved_data <= sumData / 9; // only integer part of the division will be considered
  o_convolved_data_valid <= sumDataValid;
end

endmodule