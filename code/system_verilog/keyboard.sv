// Keyboard module for 1 player. If one player works properly, then we can add code for second player.

module keyboard(
               input  logic clk,
               input  logic kclk,
               input  logic kdata,
               output logic up, down, left, right, reset      // Keyboard for player
               );
    
    logic kclkf, kdataf;
    logic [10:0]datacur;
    logic [3:0]cnt;
    logic isBreak;
    
    parameter              // Parameter keyboard button for player 
        UP    = 8'h1D,     // W button 
        DOWN  = 8'h1B,     // S button
        LEFT  = 8'h1C,     // A button
        RIGHT = 8'h23,     // D button
        RESET = 8'h29;     // Space button
        
    always_comb 
	begin
      cnt     = 4'b0000;
      isBreak = 1'b0;
    end
    
    debouncer debounce(
             .clk(clk),
             .I0(kclk),
             .I1(kdata),
             .O0(kclkf),
             .O1(kdataf)
             );
    
    always_ff @(negedge(kclkf))
    begin
      if(isBreak == 1'b1)         // when the key is released
	  begin
        datacur [cnt] = kdataf;
        cnt = cnt + 1;
        if (cnt == 11) cnt = 0;
        
        if (datacur[8:1] == UP && cnt == 0)    begin up    = 0; isBreak = 0; end
        if (datacur[8:1] == DOWN && cnt == 0)  begin down  = 0; isBreak = 0; end
        if (datacur[8:1] == LEFT && cnt == 0)  begin left  = 0; isBreak = 0; end
        if (datacur[8:1] == RIGHT && cnt == 0) begin right = 0; isBreak = 0; end
        if (datacur[8:1] == RESET && cnt == 0) begin reset = 0; isBreak = 0; end
		
		if (cnt == 0) begin isBreak = 0; end
        
      end
     else                       // When the key is pressed
	 begin
       datacur[cnt] = kdataf; 
	   cnt = cnt + 1; 
	   if(cnt ==11) cnt = 0;
        
       if (datacur[8:1] == UP && cnt == 0)    up    = 1; 
       if (datacur[8:1] == DOWN && cnt == 0)  down  = 1;
       if (datacur[8:1] == LEFT && cnt == 0)  left  = 1;
       if (datacur[8:1] == RIGHT && cnt == 0) right = 1;
       if (datacur[8:1] == RESET && cnt == 0) reset = 1;
          
       if (datacur[8:1] == 8'hF0) isBreak = 1;             // set the isbreak, when not sending any data
     end
   end
   
endmodule
/* 
//For this code we need to send the 32 bit keycodeout to vga address and then have firmware to control the direction

module keyboard(
    input clk,
    input kclk,
    input kdata,
    output [31:0] keycodeout
    );
    
    
    wire kclkf, kdataf;
    reg [7:0]datacur;
    reg [7:0]dataprev;
    reg [3:0]cnt;
    reg [31:0]keycode;
    reg flag;
    
    initial begin
        keycode[31:0]<=0'h00000000;
        cnt<=4'b0000;
        flag<=1'b0;
    end
    
debouncer debounce(
    .clk(clk),
    .I0(kclk),
    .I1(kdata),
    .O0(kclkf),
    .O1(kdataf)
);
    
always@(negedge(kclkf))begin
    case(cnt)
    0:;//Start bit
    1:datacur[0]<=kdataf;
    2:datacur[1]<=kdataf;
    3:datacur[2]<=kdataf;
    4:datacur[3]<=kdataf;
    5:datacur[4]<=kdataf;
    6:datacur[5]<=kdataf;
    7:datacur[6]<=kdataf;
    8:datacur[7]<=kdataf;
    9:flag<=1'b1;
    10:flag<=1'b0;
    
    endcase
        if(cnt<=9) cnt<=cnt+1;
        else if(cnt==10) cnt<=0;
        
end

always @(posedge flag)begin
    if (dataprev!=datacur)begin
        keycode[31:24]<=keycode[23:16];
        keycode[23:16]<=keycode[15:8];
        keycode[15:8]<=dataprev;
        keycode[7:0]<=datacur;
        dataprev<=datacur;
    end
end
    
assign keycodeout=keycode;

endmodule*/
