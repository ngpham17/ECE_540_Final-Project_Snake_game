//This is the collision module for Snake Game
//Final Project: Snake Game
//ECE 540
//Fall 2021

module snake_collision(
                      input  logic        clk,
                      input  logic        vga_clk,
		      input  logic        reset,
		      input  logic [11:0] pixel_row,
		      input  logic [11:0] pixel_col,
		      input  logic        up, down, left, right,center,
		      input  logic [4:0]  go,
		      input  reg   [4:0]  score,
		      input  reg          wall,
		      output logic        snake_body,
		      output logic        snake_head,
		      output logic        game_over,
		      output logic        diamond,
		      output logic        snake_length,
                      output logic        snake_alive					  
		      );
			
//--------------Internal Signals------------//			
logic snake_collide;
logic snake_dead;

  
//----------Initialize Snake_body module-----------//
  snake_body body(
             .clk(clk),
             .vga_clk(vga_clk),
             .clk_20(clk_20),
	     .pixel_row(pixel_row),
	     .pixel_col(pixel_col),
	     .go(go),
	     .score(score),
	     .up(up), 
	     .down(down), 
	     .left(left), 
	     .right(right),
	     .center(center),
	     .snake_head(snake_head),
	      .snake_length(snake_length)
	       );

//----------Initialize Diamond module-----------//				
  diamond food(
          .vga_clk(vga_clk),	
          .snake_alive(snake_alive),
	  .reset(reset),
	  .game_over(game_over),
	  .pixel_row(pixel_row),
	  .pixel_col(pixel_col),
	  .diamond(diamond)		
	   );
					 
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
  
//---------------Conditions for the status of Snake during the game--------//  
  always_ff @(posedge vga_clk) 
  begin
    snake_alive   <=  diamond && snake_head;
    snake_collide <= (snake_head && snake_body) || (wall && snake_head);
  end
 
// Update a snake's body, score and reset score
	always_ff @(posedge vga_clk) begin
		//score & body length update
		if (~(direction == 5'b10000)) begin 
			if(eat_diamond)  begin
				score <= score + 1;
				body_count <= body_count + 1;
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
	
	// snake dead status
	assign game_over = (snakeX[0] < 20) || (snakeX[0] + 12 >620)		
					|| (snakeY[0] < 20) || (snakeY[0] + 12 > 460);
							
endmodule
				 
