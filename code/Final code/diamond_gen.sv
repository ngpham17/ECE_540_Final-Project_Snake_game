/*
	Origin from "https://github.com/mohamedAlmorsi/snake-game-FPGA-Verilog/blob/master/random_apple.v"
	The diamond_gen module generates a random position for a diamond to be appeared on the map
*/
//640 x 480 (pixel_col x pixel_row)

module diamond_gen(
	input logic reset, vga_clk,					// vga clock: 31.5MHZ
	output logic [11:0] x_rand,	
	output logic [11:0] y_rand
	);

	// // internal variables
	logic [5:0] x_pos;		// position on x-axis
	logic [5:0] y_pos = 10;		// position on y-axis
	
	always_ff @(posedge vga_clk, posedge reset) begin
	   if (reset) begin
	       x_pos <= 0;
	   end
	   else begin
	       x_pos <= x_pos + 5;
	   end	
	end
	
	always_ff @(posedge vga_clk, posedge reset)begin
	   if (reset) begin
	       y_pos <= 0;
	   end
	   else begin
            y_pos <= y_pos + 5;
       end
	end
	
	// randomly location on x-axis
	always_ff @(posedge vga_clk, posedge reset) begin	
	   if (reset) begin
	       x_rand <= 0;
	   end
	   else begin
            if(x_pos > 62)
                x_rand <= 600;
            else if (x_pos < 1)
                x_rand <= 60;
            else
                x_rand <= (x_pos * 5);
	   end
	end
	
	// randomly location on y-axis
	always_ff @(posedge vga_clk, posedge reset) begin
	   if (reset) begin
	       y_rand <= 0;
	   end
	   else begin	
            if(y_pos < 1)
                y_rand <= 60;
            else if (y_pos > 469)
                y_rand <= 400;
            else
                y_rand <= (y_pos * 5);
	   end
	end
endmodule
