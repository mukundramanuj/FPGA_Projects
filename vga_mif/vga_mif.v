module vga_mif (
    input  MAX10_CLK1_50,	 // 50MHz onboard clock
	 input greyscale,
	 input contrast,
	 input brightness,
	 input invert,
	 input threshold,
	 input sepia,
	 input button_inc, 
	 input button_dec,
	 output [3:0] VGA_R,    // Red 4-bit
    output [3:0] VGA_G,    // Green 4-bit
    output [3:0] VGA_B,    // Blue 4-bit
    output VGA_HS,         // H-Sync
    output VGA_VS          // V-Sync
);

    // Timing Constants for 640x480 @ 60Hz
    parameter H_VISIBLE = 640;
    parameter H_FRONT   = 16;
    parameter H_SYNC    = 96;
    parameter H_BACK    = 48;
    parameter H_TOTAL   = 800;

    parameter V_VISIBLE = 480;
    parameter V_FRONT   = 10;
    parameter V_SYNC    = 2;
    parameter V_BACK    = 33;
    parameter V_TOTAL   = 525;

    // Image Constants
    parameter IMG_WIDTH  = 171;
    parameter IMG_HEIGHT = 233;

    // Internal Signals
    wire vga_clk;          // 25.175 MHz from PLL
    wire [11:0] rom_data;
    reg  [15:0] rom_addr;  // 16-bit address for 65536 depth
	 
	 
	 
	 
	 // -------------------------IMAGE PROCESSING LOGIC---------------------------------
	 // 1. greyscale point processing
	 wire [3:0] raw_r = rom_data[11:8];
	 wire [3:0] raw_g = rom_data[7:4]; 
	 wire [3:0] raw_b = rom_data[3:0];
	 wire [5:0] rgb_sum = raw_r + raw_g + raw_b;
	 wire [3:0] gray = rgb_sum / 3;
	
	 
	 // 2. brightness adjustment
	 reg [3:0] brightness_amt = 4'd3; // Adjust this value
	 
	 // 3. contrast adjustment (gain)
	 // Simple Contrast (Multiply by 1.5 using: (pixel + pixel/2))
	 wire [4:0] r_cont_15 = raw_r + {1'b0, raw_r[3:1]};
	 wire [4:0] g_cont_15 = raw_g + {1'b0, raw_g[3:1]};
	 wire [4:0] b_cont_15 = raw_b + {1'b0, raw_b[3:1]};
	 
	 // 4. inversion (negative)
	 wire [3:0] inv_r = 4'd15 - raw_r;
	 wire [3:0] inv_g = 4'd15 - raw_g;
	 wire [3:0] inv_b = 4'd15 - raw_b;
	 
	 // 5. thresholding (binarization)
	 wire [5:0] luma = raw_r + raw_g + raw_b; // Combined intensity
	 wire [3:0] thresh_val = 4'd20; // Mid-point of the sum (0 to 45)

	 wire [3:0] bw_pixel = (luma > thresh_val) ? 4'd15 : 4'd0;
	 // Assign bw_pixel to R, G, and B to see it on screen.
	 
	 // 6. color channel isolation (tinting)
	 // Night Vision (Green channel only)- "sepia" effect
	 wire [3:0] night_r = 4'd0;
	 wire [3:0] night_g = raw_g;
	 wire [3:0] night_b = 4'd0;
	 //-------------------------------------------------------------------------------------

	 
	 
	 // h and v counters initialization
    reg [9:0] h_cnt = 0;
    reg [9:0] v_cnt = 0;

    // --- 1. PLL Instance ---
    // Note: Ensure your PLL IP 'inclk0' is set to 50MHz in the Wizard
    sync_clk pll_inst (
        .inclk0 (MAX10_CLK1_50), 
        .c0     (vga_clk),    
        .c1     ()            
    );

    // --- 2. ROM Instance ---
    image_mem rom_inst (
        .address (rom_addr),
        .clock   (vga_clk),
        .data    (12'b0),      
        .wren    (1'b0),      
        .q       (rom_data)
    );

    // --- 3. Sync Generation ---
    always @(posedge vga_clk) begin
        if (h_cnt < H_TOTAL - 1) 
            h_cnt <= h_cnt + 1;
        else begin
            h_cnt <= 0;
            if (v_cnt < V_TOTAL - 1) 
                v_cnt <= v_cnt + 1;
            else 
                v_cnt <= 0;
        end
    end

    assign VGA_HS = (h_cnt >= (H_VISIBLE + H_FRONT) && h_cnt < (H_VISIBLE + H_FRONT + H_SYNC)) ? 1'b0 : 1'b1;
    assign VGA_VS = (v_cnt >= (V_VISIBLE + V_FRONT) && v_cnt < (V_VISIBLE + V_FRONT + V_SYNC)) ? 1'b0 : 1'b1;

    // --- 4. Video Display Logic ---
    wire video_on = (h_cnt < H_VISIBLE) && (v_cnt < V_VISIBLE);
    
    // Check if we are inside the image bounds (drawing at top-left 0,0)
    wire img_on = (h_cnt < IMG_WIDTH) && (v_cnt < IMG_HEIGHT);

    always @(posedge vga_clk) begin
        if (img_on)
            rom_addr <= h_cnt + (v_cnt * IMG_WIDTH);
        else
            rom_addr <= 0;
    end

   // --- 5. Image Processing Multiplexer ---
	 reg [3:0] filtered_r, filtered_g, filtered_b;
    always @(*) begin
		  filtered_r = raw_r;
		  filtered_g = raw_g;
	     filtered_b = raw_b;
	 
        if (greyscale) begin
            // Processed Mode: Grayscale
            filtered_r = gray;
            filtered_g = gray;
            filtered_b = gray;
        end
        else if (contrast) begin
				// Processed Mode: Contrast Adjustment
				filtered_r = (r_cont_15 > 5'd15) ? 4'd15 : r_cont_15[3:0];
				filtered_g = (g_cont_15 > 5'd15) ? 4'd15 : g_cont_15[3:0];
				filtered_b = (b_cont_15 > 5'd15) ? 4'd15 : b_cont_15[3:0];
		  end
		  else if (invert) begin
				// Processed Mode: Inversion
				filtered_r = inv_r;
				filtered_g = inv_g;
				filtered_b = inv_b;
		  end
		  else if (threshold) begin
				// Processed Mode: Thresholding
				filtered_r = bw_pixel;
				filtered_g = bw_pixel;
				filtered_b = bw_pixel;
		  end
		  else if (sepia) begin
				// Processed Mode: Color channel isolation
				filtered_r = night_r;
				filtered_g = night_g;
				filtered_b = night_b;
		  end
    end
	
	
	// Brightness adjustment stage
	reg [3:0] bright_offset = 4'd0;
	
	// Contrast adjustment stage
	reg [3:0] contrast_multiplier = 4'd1; // default contrast multiplier value is always 1 and can never be 0

	reg b_inc_prev, b_dec_prev;
	
	always @(posedge vga_clk) begin
	b_inc_prev <= button_inc;
	b_dec_prev <= button_dec;
	
	if(brightness) begin
		 // Detect Falling Edge (Press)
		 if (b_inc_prev == 1'b1 && button_inc == 1'b0) begin
			  if (bright_offset < 4'd12) bright_offset <= bright_offset + 4'd3;
		 end
		 else if (b_dec_prev == 1'b1 && button_dec == 1'b0) begin
			  if (bright_offset > 4'd0)  bright_offset <= bright_offset - 4'd3;
		 end
	end
	
	else if(contrast) begin
		 // Detect Falling Edge (Press)
		 if (b_inc_prev == 1'b1 && button_inc == 1'b0) begin
			  if (contrast_multiplier < 4'd4) contrast_multiplier <= contrast_multiplier + 4'd1;
		 end
		 else if (b_dec_prev == 1'b1 && button_dec == 1'b0) begin
			  if (contrast_multiplier > 4'd1)  contrast_multiplier <= contrast_multiplier - 4'd1;
		 end
	end
	
	end
	

	// --- 2. Data Path (Apply the offset to EVERY pixel instantly) ---
	wire [4:0] r_calc_brightness = filtered_r + bright_offset;
	wire [4:0] g_calc_brightness = filtered_g + bright_offset;
	wire [4:0] b_calc_brightness = filtered_b + bright_offset;
	
	wire[3:0] out_r_brightness = (r_calc_brightness > 15) ? 4'd15 : r_calc_brightness[3:0];
	wire[3:0] out_g_brightness = (g_calc_brightness > 15) ? 4'd15 : g_calc_brightness[3:0];
	wire[3:0] out_b_brightness = (b_calc_brightness > 15) ? 4'd15 : b_calc_brightness[3:0];

	
	wire [5:0] r_calc_contrast = out_r_brightness* contrast_multiplier;
	wire [5:0] g_calc_contrast = out_g_brightness * contrast_multiplier;
	wire [5:0] b_calc_contrast = out_b_brightness * contrast_multiplier;
	
	// Use wire/assign for colors to avoid 1-clock delay
	wire[3:0] out_r = (r_calc_contrast > 15) ? 4'd15 : r_calc_contrast[3:0];
	wire[3:0] out_g = (g_calc_contrast > 15) ? 4'd15 : g_calc_contrast[3:0];
	wire[3:0] out_b = (b_calc_contrast > 15) ? 4'd15 : b_calc_contrast[3:0];
	
	
	// Final o/p signal assignments
	assign VGA_R = (video_on && img_on) ? out_r : 4'b0;
	assign VGA_G = (video_on && img_on) ? out_g : 4'b0;
	assign VGA_B = (video_on && img_on) ? out_b : 4'b0;

endmodule