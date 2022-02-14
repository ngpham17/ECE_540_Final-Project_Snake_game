/*
	Nguyen Pham
	The movement module has 4-bit movements such as up, down, left, and right  from the inputs of the user 
		by pressing buttons on FPGA A7 board 
*/

module movement(
	input logic reset, clk,					// system clock: 100MHZ
	input logic up, down, left, right, center,// 5 push buttons
	output logic [4:0] go
	);

	// // internal variables
	always_ff @(posedge clk, posedge reset) begin
	   if (reset) begin
	       go <= 5'b00000;
	   end
	   else begin
			if(up)
               go <= 5'b00001;      // go up
            else if (down)
               go <= 5'b00010;      // go down
            else if (left)
               go <= 5'b00100;      // go left
            else if (right)
               go <= 5'b01000;      // go right
            else if (center)
                go <= 5'b10000;		// restart a game
            else
               go <= go;		// keep the previous direction if no any button is pushed
	   end
	end
endmodule
