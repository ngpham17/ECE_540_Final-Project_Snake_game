/*	
	ECE 540
	Nguyen Pham
	Top module Snake
	This module control the snake game susch as snake movement, drawing a diamond randomly in a game map, making size of diamonds, a snake head, a snake body and objects.
	Also it control the 10 different speeds of snake movement, and what appears in the game
*/
module vga(
	input  logic         reset,
	input logic          clk,		// system clock = 100Mhz
	input  logic         vga_clk,		// vga clock = 31.5 MHz
	input logic [4:0]    push_btt,		// push buttons
	input logic [15:0]   switches,		// switches
	
	// wishbone bus
	input logic          wb_reset,	
	input logic          wb_m2s_vga_cyc, 
	input logic   [31:0] wb_m2s_vga_dat, 
	input logic          wb_m2s_vga_we, 
	input logic          wb_m2s_vga_stb, 
	output logic  [31:0] wb_s2m_vga_dat,
	output logic         wb_s2m_vga_ack,   
	
	//vga output
	output logic [3:0]   vga_r,
	output logic [3:0]   vga_g,
	output logic [3:0]   vga_b,
	output logic         vga_vs,
	output logic         vga_hs,
	
	// audio
	output logic AUD_PWM,   //speaker output
	output logic AUD_SD     //audio enable
);
///////////////Internal signals//////////////////
	localparam body_max = 128;
	
	// pixels
	wire        video_on;
	wire [31:0] pix_num;
	wire [3:0]  doutb;
	wire [11:0] pixel_row;
	wire [15:0] cursor_row;
	wire [11:0] pixel_col;
	
	// boundary
	logic wall, wall_X, wall_Y;
	
	//objects
	logic object1, object2;
	
	// diamond
	logic [11:0] x_rand;
    	logic [11:0] y_rand;
	logic diamond, diamond_X_X, diamond_Y_Y;
	logic [11:0] diamondX;
	logic [11:0] diamondY;
	logic inX;
	logic inY;
	
	// snake	
	logic [11:0] snakeX[0:body_max-1];
	logic [11:0] snakeY[0:body_max-1];
	logic [body_max-1:0] body_check;
	logic [body_max-1:0] body_count;	//max num = 2^5 = 32

	logic snake_head, snake_head_X, snake_head_Y;
	logic snake_body, snake_body_X, snake_body_Y;
	
	// eat, dead, win
	logic eat_diamond;
	logic game_over;
	logic win;
	
	//score
	logic [15:0] score;
	logic [15:0] win_score;
	
	// welcome screen
	logic [3:0] start_screen;
	
	// movement
	logic [4:0] direction;
	logic [11:0] body_index[0:body_max-1];
	logic [11:0] move_index[0:body_max-1];
	
	//speed
	logic [31:0] counter;
	logic [31:0] counter_max;
	logic [31:0] curr_speed;
	logic [31:0] max_speed;
	logic [31:0] counter_max_presets[9:0];
	
	//-------------------DTG Module---------------------//
	dtg dtg(
		.clock(vga_clk),        // 31.5MHz clock
		.rst(reset),            // Active-high synchronous reset
		.video_on(video_on),        // 1 = in active video area; 0 = blanking;
		.horiz_sync(vga_hs),        // Horizontal sync signal to display
		.vert_sync(vga_vs),        // Vertical sync signal to display
		.pix_num(pix_num),        // (12 bits) current pixel column address
		.pixel_row(pixel_row),     // (12 bits) current pixel row address
		.pixel_column(pixel_col)    // (12 bits) current pixel column address
	);
    

	 
	//-------------------Block Memory---------------------//
	blk_mem_gen_0 start_screen_memory (  
		.clka(vga_clk),    // input wire clka
		.wea(1'b0),      // input wire [0 : 0] wea
		.addra(19'b0),  // input wire [18 : 0] addra
		.dina(4'b0),    // input wire [3 : 0] dina
		.clkb(vga_clk),    // input wire clkb
		.addrb(pix_num),  // input wire [18 : 0] addrb
		.doutb(start_screen)  // output wire [3 : 0] doutb
	);
	
	//---------------Randomly generate a diamond-----------//
	diamond_gen random(
		.vga_clk(vga_clk),	// 31.5 Mhz
		.x_rand(x_rand),	// random location on x-axis
		.y_rand(y_rand)		// random location on y-axis
	);
	
	//-------------------Movement---------------------//
	movement mov(
		.clk(clk),		// input clock
		.up(push_btt[1]),	// input BTNU
		.down(push_btt[4]),	// input BTND
		.left(push_btt[2]),	// input BTNL
		.right(push_btt[3]),	// input BTNR
		.center(push_btt[0]),   // input BTNC
		.go(direction)		// output direction
	);

	//-------------------Audio---------------------//
	audio audio (
	    .clk(clk),
	    .reset(reset),
	    .pbttn(push_btt),
	    .switch_screen(switches[0]),
	    .gameover(game_over),
	    .ate(switches),
	    .AUD_PWM(AUD_PWM),   //speaker output
	    .AUD_SD(AUD_SD)     //audio enable
	    );
	
	/////////////////////////////Game Logic//////////////////////////////
	
	// set initial position of the snake when starting the game
	initial begin
		// 10 speeds
		counter_max_presets[9] = 32'd4_500_000;//4_5 - fastest speed
		counter_max_presets[8] = 32'd5_000_000;//5_0
		counter_max_presets[7] = 32'd5_500_000;//5_5
		counter_max_presets[6] = 32'd6_000_000;
		counter_max_presets[5] = 32'd6_500_000;
		counter_max_presets[4] = 32'd7_000_000;
	   	counter_max_presets[3] = 32'd7_500_000;
		counter_max_presets[2] = 32'd8_000_000;
		counter_max_presets[1] = 32'd9_000_000;
		counter_max_presets[0] = 32'd10_000_000; //10 value - count more - takes more time ==> this is default speed to begin with
		
		snakeX[0] = 12'd300;	// intial a snake's head location in pixel
		snakeY[0] = 12'd300;
		
		diamondX = 12'd400;	// initial a diamond location at the left edge of diamon and at the upper edge
		diamondY = 12'd400;
		
		score = 16'd0;		// initial score
		win_score = 16'd10;	// winning score
		counter = 32'd0;	// counter
		curr_speed = 32'd0;	// current speed ==> lowest speed or counter_max_presets[0]
		max_speed = 32'd10;	// maximum speed options -> 10 speeds
		body_count = 16'd0;	// body size
	end
		
	// snake eat status - when snake touches diamond
	assign eat_diamond = (snakeX[0] < diamondX + 12) && (snakeX[0] + 12 > diamondX)
					&& (snakeY[0] < diamondY + 12) && (snakeY[0] + 12 > diamondY);
	
	// snake dead status - when sname touches boundary
		assign game_over = (snakeX[0] < 20) || (snakeX[0] + 12 >620)								// hit 2 side boundary
				|| (snakeY[0] < 20) || (snakeY[0] + 12 > 460)							// hit top and bottom boundary
				|| ((snakeX[0] < 220) && (snakeX[0] + 12 > 200) && (snakeY[0] < 300) && (snakeY[0] +12 > 150))	// hit object 1
				|| ((snakeX[0] < 400) && (snakeX[0] + 12 > 300) && (snakeY[0] < 230) && (snakeY[0] +12 > 200));	// hit object 2

	
	// reset a diamond location at beginning of the game or reset button is pressed and when diamond condition not in a boundary
	always_ff @(posedge vga_clk) begin
		
		// reset a diamond location - any time reset switch is pressed
		if(direction == 5'b10000) begin
			diamondX <= 12'd400;
			diamondY <= 12'd400;
		end
		
		//diamond's postition during the game
		
		else begin
    		if (eat_diamond) begin
	   		  // if diamond is on the boundary or objects - it must be moved or snake will hit the boundary and game is over - so, avoid that.
				if (x_rand < 20 || x_rand > 620 || y_rand <20 || y_rand > 480
						|| (x_rand >=200 && x_rand < 220) || (x_rand >= 300 && x_rand < 400)
						|| (y_rand >= 150 && y_rand < 300) || (y_rand >= 200 && y_rand < 230)) begin
				    diamondX <= 12'd150;
				    diamondY <= 12'd100;
			     end
			     else begin
				    diamondX <= x_rand;
				    diamondY <= y_rand;
				 end
			 end
		 end
	end
	
	
	// Draw boundaries
	always_ff @(posedge vga_clk) begin
		wall_Y <= (pixel_row >= 0) & (pixel_row < 20) 			//top wall
				| (pixel_row >= 460) & (pixel_row < 481);	// bottom wall;
		wall_X <= (pixel_col >= 0) & (pixel_col < 20)		 	// left wall
				| (pixel_col >= 620) & (pixel_col < 641);	// right wall;
		object1 <= ((pixel_row >= 150) & (pixel_row < 300) & (pixel_col >= 200) & (pixel_col < 220));
		object2 <= (pixel_row >= 200) & (pixel_row < 230) & ((pixel_col >= 300) & (pixel_col < 400));;
		wall <= wall_X | wall_Y | object1 | object2;
	end
	
	// A random diamond's location
	always_ff @(posedge vga_clk) begin
		inY <= (pixel_row > diamondY) & (pixel_row < (diamondY + 12)); // 12 is the Y dimension of the diamond in pixel. Comment by Ataur
		inX <= (pixel_col > diamondX) & (pixel_col < (diamondX + 12)); // 12 is the X dimension of the diamond in pixel. Comment by Ataur
		diamond <= inX & inY;
	end
	
	// Draw a snake's body
	int j;
	always_ff @(posedge vga_clk) begin
		for(j = 0; j <body_max; j = j + 1) begin
			body_index[j] = j;
			if( body_index[j] < body_count) begin
				body_check[j] <= (pixel_row > snakeY[j+1]) & (pixel_row < snakeY[j+1] + 12) & (pixel_col > snakeX[j+1]) & (pixel_col < snakeX[j+1] + 12);
			end
			
			//previous body drawing -> 1 block from 1 to 3
		// example, body lengtt = 3
		//     snake_body <= ( (pixel_row > snakeX[1]) & (pixel_row < (snakeX[3] + 12)) 
		//			& (pixel_col > snakeY[1]) & (pixel_col < (snakeY[3] + 12))
		//		);
			
			else begin
				body_check[j] <= 0;
			end
		end
		snake_body <= |body_check;
	end

	// Draw a snake's head
	always_ff @(posedge vga_clk) begin
		snake_head_Y <= (pixel_row > snakeY[0]) & (pixel_row < (snakeY[0] + 12)) ;
		snake_head_X <= (pixel_col > snakeX[0]) & (pixel_col < (snakeX[0] + 12));
		snake_head <= snake_head_X & snake_head_Y;
	end
	
	// Snake Movement
	int i;
	assign counter_max = counter_max_presets[curr_speed]; // To be begin with counter max = counter_max_presets[0] = 32'd10_000_000
	always_ff @(posedge vga_clk) begin
		if (!game_over) begin
			counter <= counter + 32'd1; // used below for wait before moving in line number 272 or so.
		end
		// when eat diamond: adjust speed if possible
		if (eat_diamond && ((curr_speed + 1) < max_speed)) begin
			curr_speed <= curr_speed + 1;  // speed going up from default or slowest speed
			counter <= 32'd0;
		end

		if (counter >= counter_max) begin
			//do move body to the head
			for(i = body_max; i > 0; i = i - 1) begin
				move_index[i] = i;
				// do moving
				if(move_index[i] <= body_count) begin // for the body
					snakeX[i] <= snakeX[i-1];
					snakeY[i] <= snakeY[i-1];
				// example: how body follows the head 
				// 	snakeX[3] <= snakeX[2];
				// 	snakeY[3] <= snakeY[2];

				// 	snakeX[2] <= snakeX[1];
				// 	snakeY[2] <= snakeY[1];

				// 	snakeX[1] <= snakeX[0];
				// 	snakeY[1] <= snakeY[0];
					
					//  X	 264 276 288 300   276 288 300	       	       288  300
					// y
					// 264						 
					// 276						 	     0
					// 288           		    0			     |
					// 300    -   -  -    0	    -   -   -			 -   -
					// snakeX[0] <= 300      -> snakeX[0] <= 300	snakeX[0] <= 300
					//snakeY[0] <= 300       -> snakeY[0] <= 288	snakeY[0] <= 276
					 
					// snakeX[1] <= 288	 -> snakeX[1] <= 300	snakeX[1] <= 300
					//snakeY[1] <= 300	 ->snakeY[1] <= 300	snakeY[1] <= 288
					
					//snakeX[2] <= 276	 -> snakeX[2] <= 288	snakeX[2] <= 300
					//snakeY[2] <= 300	 -> snakeY[2] <= 300	snakeY[2] <= 300
					
					// snakeX[3] <= 264	-> snakeX[3] <= 276	snakeX[3] <= 288
					// snakeY[3] <= 300	-> snakeY[3] <= 300	snakeX[3] <= 300
				end
				// keep the same location/ don't move
				else begin
					snakeX[i] <= snakeX[i];
					snakeY[i] <= snakeY[i];
				end
			end
			
			
		   // check a push button - when direction changes - this is for the head.
		   if (direction == 5'b00001)
			   snakeY[0] <= snakeY[0] - 12;		// go up by 12 pixel
		   else if(direction == 5'b00010)
			   snakeY[0] <= snakeY[0] + 12;		// go down
		   else if(direction == 5'b00100)
			   snakeX[0] <= snakeX[0] - 12;		// go left
		   else if(direction == 5'b01000)
			   snakeX[0] <= snakeX[0] + 12;		// go right
			else begin	// default
				snakeX[0] <= snakeX[0];
			   	snakeY[0] <= snakeY[0];
			end
		   counter <= 32'd0;	//reset the counter
	   end	
   end

	// Update a snake's body, score and reset score - snake grows here
	always_ff @(posedge vga_clk) begin
		//score & body length update
		if (~(direction == 5'b10000)) begin 
			if(eat_diamond)  begin
				score <= score + 1;
				body_count <= body_count + 1; // snake grows here when it eats a diamond.
			end
			else begin
				score <= score;
				body_count <= body_count;
		   end
		end
	        // reset game
		else begin
			score <= 0;
		     // body_count <= 0;
		end																	
	end
	
	// check win game
	always_ff @(posedge vga_clk) begin
		if (score >= win_score)
			win <= 1;
		else
			win <= 0;
	end
	
  	// output to monitor
	always_ff @(posedge vga_clk) begin
	   case (switches[0])
		   // switch 0 off
		   1'b0: begin
			   vga_r <= start_screen;
			   vga_g <= start_screen;
			   vga_b <= start_screen;
		   end
		   // switch 0 on -> play game
		  1'b1: begin
				 if((game_over == 0) && (win == 0)) begin	// display game layout   
					vga_r <= {4{video_on & snake_head}};
					 vga_g <= {4{video_on & (diamond | snake_body)}}; // Color green for diamond shape and snake_body
					vga_b <= {4{video_on & wall}};
				end
			  else if(win == 1) begin		// display a green screen
				  vga_r <= {4{video_on & 1'b0}}; // video_on must be used for VGA display
				  vga_g <= {4{video_on & 1'b1}}; // Green it is - you may go to round 2
				  vga_b <= {4{video_on & 1'b0}};
				end
			  else if (game_over == 1) begin		//  display a red screen - restart the game.
					vga_r <= {4{video_on & 1'b1}};
					vga_g <= {4{video_on & 1'b0}};
					vga_b <= {4{video_on & 1'b0}};
				end
				else begin				// default: blue screen
					vga_r <= {4{video_on & 1'b0}};	
					vga_g <= {4{video_on & 1'b0}};
					vga_b <= {4{video_on & 1'b1}};
				end
			end
	   endcase
	end
///////////////Wishbone VGA register control////////////////
	reg        wb_vga_ack_ff;
	reg [31:0] wb_vga_reg;

	always_ff @(posedge clk or posedge wb_reset) begin
	   if (wb_reset) begin
		  wb_vga_reg <= 32'h000060004 ;// set this to row/column like hex 5000.
		  wb_vga_ack_ff <= 0 ;
	   end
	   else begin
		  wb_vga_reg <= (wb_vga_ack_ff && wb_m2s_vga_we) ? wb_m2s_vga_dat : wb_vga_reg;
		  wb_vga_ack_ff <= ! wb_vga_ack_ff & wb_m2s_vga_stb & wb_m2s_vga_cyc;
	   end
	end
	assign wb_s2m_vga_ack  = wb_vga_ack_ff;

	//send the score value from vga to the core
	 assign wb_s2m_vga_dat =  {16'b0, score[15:0]};
endmodule
