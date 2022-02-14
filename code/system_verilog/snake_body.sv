//This is the Snake_body module for Snake Game
//Final Project: Snake Game
//ECE 540
//Fall 2021

module snake_body(
                 input  logic        clk,
                 input  logic        vga_clk,
		 input  logic        clk_20,
		 input  logic [11:0] pixel_row,
		 input  logic [11:0] pixel_col,
		 input  logic [4:0]  go,
		 input  logic [4:0]  score,
		 input  logic        up, down, left, right,center,
		 output logic        snake_head,
		 output logic        snake_length 
                 );
				 
//-----Internal signals--------//
  integer snake_block;
  integer snake_growth;
  
  logic [11:0] snakeX[0:5];
  logic [11:0] snakeY[0:5];
  logic        snakeL_X;
  logic        snakeL_Y;
  logic        snakeH_X;
  logic        snakeH_Y;
  
 //-----Initialize movement module------------// 
	movement mov(
		 .clk(clk),	  // input clock
		 .up(up),	      // input BTNU
		 .left(left),	  // input BTNL
		 .right(right), // input BTNR
		 .down(down),	  // input BTND
		 .center(center),
		 .go(go)	      // output direction
	         );
		  
//-------set initial position of the snake when starting the game--------//
  initial 
  begin
	snakeX[0] = 10'd200;
	snakeY[0] = 9'd200;
  end
	
	always_ff @(posedge vga_clk) begin
		if (!game_over) begin
			counter <= counter + 32'd1;
		end
		// when eat diamond: adjust speed if possible
		if (eat_diamond && ((curr_speed + 1) < max_speed)) begin
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
		   // check a push button
		   if (direction == 5'b00001)
			   snakeY[0] <= snakeY[0] - 12;		// go up
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

  always_ff @(posedge clk_20) 
  begin
    for(snake_block = 6; snake_block > 0; snake_block = snake_block - 1)
	begin
	  if(snake_block <= score - 1)
	  begin
		snakeX[snake_block] <= snakeX[snake_block - 1];
		snakeY[snake_block] <= snakeY[snake_block - 1];
	  end
	end

    //Set Snake direction
	if (go == 5'b00001)
	       snakeX[0] <= snakeX[0] - 5;	   // go up
	else if(go == 5'b00010)
		snakeX[0] <= snakeX[0] + 5;	   // go down
	else if(go == 5'b00100)
		snakeY[0] <= snakeY[0] - 5;	   // go left
	else if(go == 5'b01000)
		snakeY[0] <= snakeY[0] + 5;	   // go right
  end

// Draw a snake's body
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

// Draw a snake's head
	always_ff @(posedge vga_clk) begin
		snake_head_Y <= (pixel_row > snakeY[0]) & (pixel_row < (snakeY[0] + 12)) ;
		snake_head_X <= (pixel_col > snakeX[0]) & (pixel_col < (snakeX[0] + 12));
		snake_head <= snake_head_X & snake_head_Y;
	end
	
endmodule
