// Multiply Accumulate module (MAC)

module conv(
  input i_clk,
  input [71:0] i_pixel_data,
  input i_pixel_data_valid,
  input [71:0]       i_kernel,              // 9 × 8-bit kernel
  output reg signed [7:0] o_convolved_data,
  output reg o_convolved_data_valid
);

integer i;
reg signed [7:0] kernel [8:0];
reg signed [15:0] multData[8:0];
reg signed [15:0] sumDataInt;
reg signed [15:0] sumData;
reg multDataValid;
reg sumDataValid;

always @(*) begin
  for (i = 0; i < 9; i = i + 1) begin
    kernel[i] = i_kernel[i*8 +: 8];
  end
end


// multiplication
always @(posedge i_clk) begin
  for (i = 0; i < 9; i = i+1) begin
    multData[i] <= kernel[i]*i_pixel_data[i*8+:8];
  end
multDataValid <= i_pixel_data_valid;
end

// summation using parallel adder (purely combinational) - balanced adder tree for proper timing
always @(*) begin
sumDataInt = 0;
  for (i = 0; i < 9; i = i+1) begin
    sumDataInt = sumDataInt + multData[i];
  end
end

always @(posedge i_clk) begin
  sumData <= sumDataInt; // sumDataInt behaves as an accumulator
  sumDataValid <= multDataValid;
end

always @(posedge i_clk) begin
  o_convolved_data <= sumData[15:8];
  o_convolved_data_valid <= sumDataValid;
end

endmodule