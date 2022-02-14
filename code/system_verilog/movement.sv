// PushButton Selection module for snake movement
// ECE 540
// Nguyen Pham
// Final Project
// Fall 2021

module movement(
	           input  logic       clk,	   // system clock: 100MHZ
	           input  logic       up, 
	           input  logic       down, 
	           input  logic       left, 
	           input  logic       right,
	           input  logic       center,  
	           output logic [4:0] go
	           );

//-------Select the direction for Snake----------//
	always_ff @(posedge clk) 
	begin
	   go <= 5'b00000;	// default direction
	   if(up)
	     go <= 5'b00001;      // go up
	   else if (down)
	     go <= 5'b00010;      // go down
	   else if (left)
	     go <= 5'b00100;      // go left
	   else if (right)
	     go <= 5'b01000;      // go right
	   else if (center)
		 go <= 5'b10000;	  // restart a game
	   else
	     go <= go;
	end
	
endmodule
