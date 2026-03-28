module digital_clock(
    input CLOCK_50,
    input [2:0] SW,        // SW[0]=Hour, SW[1]=Minute, SW[2]=Sec reset
    input [1:0] KEY,       // KEY[0]=inc, KEY[1]=dec (active LOW)
    output reg [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
	 output hour_marker,
	 output minute_marker 
);

//--------------------------------------
// Clock Divider (50 MHz → 1 Hz)
//--------------------------------------
reg [31:0] clk_count = 0;
reg clk_1Hz = 0;

always @(posedge CLOCK_50) begin
    if (clk_count == 25_000_000 - 1) begin
        clk_count <= 0;
        clk_1Hz <= ~clk_1Hz;
    end else begin
        clk_count <= clk_count + 1;
    end
end

//--------------------------------------
// Button Edge Detection
//--------------------------------------
//reg key0_prev = 1, key1_prev = 1;
//
//always @(posedge CLOCK_50) begin
//    key0_prev <= KEY[0];
//    key1_prev <= KEY[1];
//end
//
//wire inc_pressed = (key0_prev == 1 && KEY[0] == 0);
//wire dec_pressed = (key1_prev == 1 && KEY[1] == 0);

//--------------------------------------
// Time Registers
//--------------------------------------
reg [5:0] seconds = 0;
reg [5:0] minutes = 0;
reg [4:0] hours   = 12;

//--------------------------------------
// Clock + Set Logic
//--------------------------------------

always @(posedge clk_1Hz) begin

	 // SET HOURS
    if (SW[0] && !SW[1] && !SW[2]) begin
        if (!KEY[0]) begin
            if (hours == 12) hours <= 1;
            else hours <= hours + 1;
        end
        else if (!KEY[1]) begin
            if (hours == 1) hours <= 12;
            else hours <= hours - 1;
        end
		  else if (!KEY[0] && !KEY[1]) begin
				hours <= 0;
		  end
    end

    // SET MINUTES
    else if (SW[1] && !SW[0] && !SW[2]) begin
        if (!KEY[0]) begin
            if (minutes == 59) minutes <= 0;
            else minutes <= minutes + 1;
        end
        else if (!KEY[1]) begin
            if (minutes == 0) minutes <= 59;
            else minutes <= minutes - 1;
        end
		  else if (!KEY[0] && !KEY[1]) begin
				minutes <= 0;
		  end
    end

    // RESET SECONDS
    else if (SW[2] && !SW[0] && !SW[1]) begin
        seconds = 0;
    end

 
   // NORMAL CLOCK MODE
   else if (!SW[2] && !SW[0] && !SW[1]) begin
        if (seconds == 59) begin
            seconds <= 0;

            if (minutes == 59) begin
                minutes <= 0;

                if (hours == 12)
                    hours <= 1;
                else
                    hours <= hours + 1;

            end else begin
                minutes <= minutes + 1;
            end

        end else begin
            seconds <= seconds + 1;
        end
    end
end

//--------------------------------------
// BCD Conversion
//--------------------------------------
reg [3:0] sec_units, sec_tens;
reg [3:0] min_units, min_tens;
reg [3:0] hr_units, hr_tens;

always @(*) begin
    sec_units = seconds % 10;
    sec_tens  = seconds / 10;

    min_units = minutes % 10;
    min_tens  = minutes / 10;

    hr_units  = hours % 10;
    hr_tens   = hours / 10;
end

//--------------------------------------
// 7-Segment Decoder Function
//--------------------------------------
function [6:0] seg7;
    input [3:0] bcd;
    begin
        case (bcd)
            4'd0: seg7 = 7'b1000000;
            4'd1: seg7 = 7'b1111001;
            4'd2: seg7 = 7'b0100100;
            4'd3: seg7 = 7'b0110000;
            4'd4: seg7 = 7'b0011001;
            4'd5: seg7 = 7'b0010010;
            4'd6: seg7 = 7'b0000010;
            4'd7: seg7 = 7'b1111000;
            4'd8: seg7 = 7'b0000000;
            4'd9: seg7 = 7'b0010000;
            default: seg7 = 7'b1111111;
        endcase
    end
endfunction

//--------------------------------------
// Display Assignment
//--------------------------------------
always @(*) begin
    HEX0 = seg7(sec_units);
    HEX1 = seg7(sec_tens);
    HEX2 = seg7(min_units);
    HEX3 = seg7(min_tens);
    HEX4 = seg7(hr_units);
    HEX5 = seg7(hr_tens);
end

	 assign hour_marker = 1'b0;
	 assign minute_marker = 1'b0;

endmodule