// DIAMOND MODULE
// ECE 540
// Final Project
// Fall 2021

module diamond(
	       input  logic        vga_clk,
               input  logic        snake_alive,
	       input  logic        reset,
	       input  logic        game_over,
	       input  logic [11:0] pixel_row,
	       input  logic [11:0] pixel_col,
               output logic        diamond
	       );
			  
  logic [11:0] diamondX;
  logic [11:0] diamondY;
  logic [11:0] x_rand;
  logic [11:0] y_rand;
  logic        diamond_onX;
  logic        diamond_onY;
  
//----------Initialize Random Diamond module-----------//
  diamond_gen random(
	      .vga_clk(vga_clk),
	      .x_rand(x_rand),
	      .y_rand(y_rand)
	       );
			  
//---------------diamond positions--------------------//
  always_ff @(posedge vga_clk) 
  begin
//-----------Initial diamond's positions when starting the game----//
    if(reset || game_over) 
    begin
      diamondX <= 200;
      diamondY <= 200;
    end
//-------------diamond's postition during the game---------------//
     else if (snake_alive) 
     begin
       diamondX <= x_rand;
       diamondY <= y_rand;
     end
  end
	
  always_ff @(posedge vga_clk) 
  begin
    diamond_onX <= (pixel_row > diamondX) & (pixel_row < (diamondX + 10));
    diamond_onY <= (pixel_col > diamondY) & (pixel_col < (diamondY + 10));
    diamond     <= diamond_onX & diamond_onY;
  end
	
endmodule
