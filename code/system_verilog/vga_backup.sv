/*	
	ECE 540
	Top module Snake
	This module control the snake game susch as snake movement, drawing a diamond randomly in a game map, making size of diamonds, a snake head, a snake body and objects.
	Also it control the 10 different speeds of snake movement, and what appears in the game
*/
module vga(
          input  logic         reset,
          input logic          clk,		// 100Mhz
          input  logic         vga_clk,	//31.5 MHz
          input logic [4:0]    push_btt,
          input logic [15:0]    switches,
 
//////////////////////////////////////////////////////   
		   input logic          wb_reset,
         input logic          wb_m2s_vga_cyc, 
         input logic   [31:0] wb_m2s_vga_dat, 
         input logic          wb_m2s_vga_we, 
         input logic          wb_m2s_vga_stb, 
           
         output logic  [31:0] wb_s2m_vga_dat,
         output logic         wb_s2m_vga_ack,
////////////////////////////////////////////////////////	   

		   output logic [3:0]   vga_r,
		   output logic [3:0]   vga_g,
		   output logic [3:0]   vga_b,
		   output logic         vga_vs,
		   output logic         vga_hs,
////////////////////////////////////////////////////////////
		   output logic AUD_PWM,   //speaker output
    	   output logic AUD_SD     //audio enable
		   );
		   
//////wires////////////
wire        video_on;
wire [31:0] pix_num;
wire [3:0]  doutb;
wire [11:0] pixel_row;
wire [15:0] cursor_row;
wire [11:0] pixel_col;
/////////////////////////////

////Code to implement a new single register for a new VGA register///////
////This could be a sprite position register or something else//////////

///////////////Internal signals//////////////////
///////////////////////////////////////////////////////////
	localparam body_max = 128;

	logic [4:0] direction;
	logic [11:0] x_rand;
    logic [11:0] y_rand;

	logic game_over;
	logic diamond, diamond_X_X, diamond_Y_Y;
	logic wall, wall_X, wall_Y;
	logic [11:0] diamondX;
	logic [11:0] diamondY;
	logic inX;
	logic inY;
	
	logic [11:0] body_index[0:body_max-1];
	logic [11:0] move_index[0:body_max-1];
	
	logic [11:0] snakeX[0:body_max-1];
	logic [11:0] snakeY[0:body_max-1];
	logic [body_max-1:0] body_check;
	logic [body_max-1:0] body_count;	//max num = 2^5 = 32
	
	logic [11:0] minX, maxX;
	logic [11:0] minY, maxY; 

	logic snake_head, snake_head_X, snake_head_Y;
	logic snake_body, snake_body_X, snake_body_Y;
	logic eat_diamond;
	logic win;
	
	logic [15:0]score;
	logic [15:0]win_score;

	logic [3:0] start_screen;
	//speed
	logic [31:0] counter;
	
	// scale down from system clock 100Mhz
	logic [31:0] counter_max;
	logic [31:0] curr_speed;
	logic [31:0] max_speed;
	logic [31:0] counter_max_presets[9:0];
	
////////////////dtg module//////////
	dtg dtg(
		.clock(vga_clk),
		.rst(reset), 
		.video_on(video_on), 
		.horiz_sync(vga_hs), 
		.vert_sync(vga_vs),
		.pix_num(pix_num),
		.pixel_row(pixel_row),  // part b signals
		.pixel_column(pixel_col)// part b signals
	 );
	 
	 /////////////memory module///////////	
    blk_mem_gen_0 start_screen_memory 
    (  
      .clka(vga_clk),    // input wire clka
      .wea(1'b0),      // input wire [0 : 0] wea
      .addra(19'b0),  // input wire [18 : 0] addra
      .dina(4'b0),    // input wire [3 : 0] dina
      .clkb(vga_clk),    // input wire clkb
      .addrb(pix_num),  // input wire [18 : 0] addrb
      .doutb(start_screen)  // output wire [3 : 0] doutb
    );

///////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////

	// Randomly generate a diamond
	diamond_gen random(
	   .vga_clk(vga_clk),
	   .x_rand(x_rand),
	   .y_rand(y_rand)
	);
	
	// Movement
	movement mov(
		.clk(clk),			// input clock
		.up(push_btt[1]),	// input BTNU
		.down(push_btt[4]),	// input BTND
		.left(push_btt[2]),	// input BTNL
		.right(push_btt[3]),	// input BTNR
		.center(push_btt[0]),   // input BTNC
		.go(direction)		// output direction
	);

////////////////////////////////////////////////
	
	// set initial position of the snake when starting the game
	initial begin
		
		snakeX[0] = 12'd300;
		snakeY[0] = 12'd300;
		
		// speeds
		counter_max_presets[9] = 32'd4_500_000;
		counter_max_presets[8] = 32'd5_000_000;
		counter_max_presets[7] = 32'd5_500_000;
		counter_max_presets[6] = 32'd6_000_000;
		counter_max_presets[5] = 32'd6_500_000;
		counter_max_presets[4] = 32'd7_000_000;
	    counter_max_presets[3] = 32'd7_500_000;
		counter_max_presets[2] = 32'd8_000_000;
		counter_max_presets[1] = 32'd9_000_000;
		counter_max_presets[0] = 32'd10_000_000;
		diamondX = 12'd400;
		diamondY = 12'd400;
		score = 16'd0;
		win_score = 16'd3;
		counter = 32'd0;
		curr_speed = 32'd0;
		max_speed = 32'd10;
		body_count = 16'd0;
	end
		
	// Wall border
	always_ff @(posedge vga_clk) begin
		wall_Y <= (pixel_row >= 0) & (pixel_row < 20) 	//top wall
							| (pixel_row >= 460) & (pixel_row < 481);	// bottom wall;
		wall_X <= (pixel_col >= 0) & (pixel_col < 20) 	// left wall
							| (pixel_col >= 620) & (pixel_col < 641);	// right wall;
		wall <= wall_X | wall_Y;
	end
	
	
		// snake eat status
	// assign eat_diamond = (inX & snake_head_X) & (inY & snake_head_Y);
	assign eat_diamond = (snakeX[0] < diamondX + 12) && (snakeX[0] + 12 > diamondX)
							&& (snakeY[0] < diamondY + 12) && (snakeY[0] + 12 > diamondY);
	// snake dead status
	assign game_over = (snakeX[0] < 20) || (snakeX[0] + 12 >620)		
							|| (snakeY[0] < 20) || (snakeY[0] + 12 > 460);
	
	// check if a diamond appears on any boundary
	always_ff @(posedge vga_clk) begin
    	if(direction == 5'b10000) begin
            diamondX <= 12'd400;
            diamondY <= 12'd400;
        end	// if
        //diamond's postition during the game
        else begin
            if (eat_diamond == 1) begin
            // if diamond is on the boundary
                if (x_rand < 20 || x_rand > 620 || y_rand <20 || y_rand > 480) begin
                    diamondX <= 12'd100;
                    diamondY <= 12'd100;
                end	// if
                else begin
                    diamondX <= x_rand;
                    diamondY <= y_rand;
                end    // else
            end	// if
        end // else
    end	//always_ff
            
    always_ff @(posedge vga_clk) begin
        inY <= (pixel_row > diamondY) & (pixel_row < (diamondY + 12));
        inX <= (pixel_col > diamondX) & (pixel_col < (diamondX + 12));
		diamond <= inX & inY;
    end

	// update snake's body
	int j;
	always_ff @(posedge vga_clk) begin
		for(j = 0; j <body_max; j = j + 1) begin
			body_index[j] = j;
			if( body_index[j] < body_count) begin
				body_check[j] <= (pixel_row > snakeY[j+1]) & (pixel_row < snakeY[j+1] + 12) & (pixel_col > snakeX[j+1]) & (pixel_col < snakeX[j+1] + 12);
			end
			else begin
				body_check[j] <= 0;
			end
		end
		snake_body <= |body_check;
	end

	// draw snake_head
	always_ff @(posedge vga_clk) begin
		snake_head_Y <= (pixel_row > snakeY[0]) & (pixel_row < (snakeY[0] + 12)) ;
		snake_head_X <= (pixel_col > snakeX[0]) & (pixel_col < (snakeX[0] + 12));
		snake_head <= snake_head_X & snake_head_Y;
	end
	
    assign counter_max = counter_max_presets[curr_speed];
	// Movement
	int i;
	always_ff @(posedge vga_clk) begin
		if (game_over == 0) begin
			counter <= counter + 32'd1;
		end
		// when eat diamond: adjust speed if possible
		if ((eat_diamond == 1)&& ((curr_speed + 1) < max_speed)) begin
			curr_speed <= curr_speed + 1;
			counter <= 32'd0;
		end

		if (counter >= counter_max) begin
			//do move body to the head
			for(i = body_max; i > 0; i = i - 1) begin
				move_index[i] = i;
				// do moving
				if(move_index[i] <= body_count) begin
					snakeX[i] <= snakeX[i-1];
					snakeY[i] <= snakeY[i-1];
				end
				// keep the same location/ don't move
				else begin
					snakeX[i] <= snakeX[i];
					snakeY[i] <= snakeY[i];
				end
			end

		   if (direction == 5'b00001)
			   snakeY[0] <= snakeY[0] - 12;		// go up
		   else if(direction == 5'b00010)
			   snakeY[0] <= snakeY[0] + 12;		// go down
		   else if(direction == 5'b00100)
			   snakeX[0] <= snakeX[0] - 12;	// go left
		   else if(direction == 5'b01000)
			   snakeX[0] <= snakeX[0] + 12;	// go right
			else begin
				snakeX[0] <= snakeX[0];
			   snakeY[0] <= snakeY[0];
			end
		   counter <= 32'd0;	//reset the counter
	   end    // if		
   end  //always_ff

	//score & body length update
	always_ff @(posedge vga_clk) begin
	   if (~(direction == 5'b10000)) begin
            if(eat_diamond == 1)  begin
                score <= score + 1;
                body_count <= body_count + 1;
            end
            else begin
                score <= score;
                body_count <= body_count;
            end
        end // if
        else begin
            score <= 16'd0;
        end // else
    end // always
    
	// check win
	always_ff @(posedge vga_clk) begin
		if (score >= win_score)
			win <= 1;
		else
			win <= 0;
	end    // always
  
//----------store score to vga address------------------//
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
	 // colors
	always_ff @(posedge vga_clk) begin
	   case (switches[0])
           1'b0: begin
               vga_r <= start_screen;
               vga_g <= start_screen;
               vga_b <= start_screen;
           end
           1'b1: begin
                if((game_over == 0) && (win == 0)) begin    // game map
                    vga_r <= {4{video_on & snake_head}};
                    vga_g <= {4{video_on & (diamond | snake_body)}};
                    vga_b <= {4{video_on & wall}};
                end
                else if (win == 1) begin    // green screen
                    vga_r <= {4{1'b0}};
                    vga_g <= {4{1'b1}};
                    vga_b <= {4{1'b0}};
                end
                else if (game_over == 1) begin  // red screen
                    vga_r <= {4{1'b1}};
                    vga_g <= {4{1'b0}};
                    vga_b <= {4{1'b0}};
                end
                else begin                      // blue screen
                    vga_r <= {4{1'b0}};
                    vga_g <= {4{1'b0}};
                    vga_b <= {4{1'b1}};
                end
            end
        endcase
	end
   
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

endmodule
