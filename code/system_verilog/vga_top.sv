// Final Project
// ECE 540
// FALL 2021

//The vga module is the top module to control the snake game
//640 x 480 display

module vga(
           input  logic        reset,
           input  logic        clk,
           input  logic        vga_clk,	       //31.5 MHz
           input  logic [4:0]  push_btt,  
	   input  logic        wb_reset,
           input  logic        wb_m2s_vga_cyc, 
           input  logic [31:0] wb_m2s_vga_dat, 
           input  logic        wb_m2s_vga_we, 
           input  logic        wb_m2s_vga_stb, 
           output logic [31:0] wb_s2m_vga_dat,
           output logic        wb_s2m_vga_ack,
           output logic [3:0]  vga_r,
	   output logic [3:0]  vga_g,
	   output logic [3:0]  vga_b,
	   output logic        vga_vs,
	   output logic        vga_hs
	  );

//--------------Internal signals------------------//
       logic        clk_20;
	logic        video_on;
	logic [11:0] pixel_row;
	logic [11:0] pixel_col;
	logic [4:0]  go;
	logic        diamond;
	logic        wall;
	logic        red;
	logic        green;
	logic        blue;
	logic        snake_body;
	logic        game_over;
	logic        snake_head;
	logic        snake_length;
	logic        snake_Xalive;
	logic [4:0]  score;
	
//--------------------dtg module--------------------//
	dtg dtg(
	    .clock(vga_clk),
	    .rst(reset), 
	    .video_on(video_on), 
	    .horiz_sync(vga_hs), 
	    .vert_sync(vga_vs),
	    .pix_num(pix_num),		
	    .pixel_row(pixel_row),  
	    .pixel_column(pixel_col)
	     );
	 
//--------Using 20Hz clock, will change the module name-----//
	clk_25Hz clk_25Hz(
		 .clk(clk),
		 .clk_out_20(clk_20)
         	  );
//------------Instantiate Snake Collision module-----------//	
	snake_collision collide(
	                 .clk(clk),
                         .vga_clk(vga_clk),
			 .reset(reset),
			 .pixel_row(pixel_row),
			 .pixel_col(pixel_col),
			 .go(go),
			 .score(score),
			 .up(push_btt[1]),      // input BTNU
		         .down(push_btt[4]),	// input BTND
		         .left(push_btt[2]),	// input BTNL
		         .right(push_btt[3]),	// input BTNR
		         .center(push_btt[0]),  // input BTNC
			 .wall(wall),
			 .snake_body(snake_body),
			 .snake_head(snake_head),
			 .game_over(game_over),
	                 .diamond(diamond),
		        .snake_length(snake_length),
                        .snake_alive(snake_alive)			 
			 );
	
//---------------------Colors---------------------------//
	always_comb 
	begin
	  red   = (video_on && (snake_alive || game_over));
	  green = (video_on & (diamond | snake_length & ~game_over));
	  blue  = (video_on & (wall & ~game_over));
	end
	
//-------------------On-screen-------------------------//
	always_comb 
	begin
	  vga_r = {red,red,red,red};
          vga_g = {green,green,green,green};
          vga_b = {blue,blue,blue,blue};
	end

endmodule
