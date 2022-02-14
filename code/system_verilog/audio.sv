// Origin: http://www.fpga4fun.com/MusicBox2.html

module audio (
    input bit clk,
    input bit reset,
    input logic [4:0] pbttn,
    input logic switch_screen,
    input logic gameover,
    input logic ate,
    output logic AUD_PWM,   //speaker output
    output logic AUD_SD     //audio enable
    );

    localparam CLK_100_MHz = 100_000_000;
    localparam CLK_8_KHz = 8_000;
    localparam CLK_DIVIDER_8_KHz = ((CLK_100_MHz/CLK_8_KHz) - 1);
    localparam HIT_SOUND_MAX_COUNT = 6182;
    localparam SCORE_SOUND_MAX_COUNT = 2692;
    localparam TURN_SOUND_MAX_COUNT = 8180;
    localparam BACKGROUND_SOUND_MAX_COUNT = 65500;

    
    logic [7:0]     audio_out;
    logic [7:0]     pwm_cnt; 
    logic [15:0]    cnt_clk_8 = 16'b0;
    logic           clk_8;  

    

    always_ff @ (posedge clk) begin
        if (reset) begin
            cnt_clk_8 <= 16'b0;
        end
        else if (cnt_clk_8 == CLK_DIVIDER_8_KHz) begin
                cnt_clk_8 <= 16'b0;
                clk_8 <= 1;
            end
            else begin
                cnt_clk_8 <= cnt_clk_8 + 1'b1;
                clk_8 <= 0;
            end
    end

//------------------start screen------------------//
    logic [15:0] addr_background;
    logic [7:0] dout_background;

    blk_mem_gen_background background_sound (
        .clka(clk_8),    // input wire clka
        .addra(addr_background),  // input wire [16 : 0] addra
        .douta(dout_background)  // output wire [7 : 0] douta
    );

//------------------movement------------------//
    logic [12:0] addr_turn;
    logic [7:0] dout_turn;

    blk_mem_gen_turn turn_sound (
        .clka(clk_8),    // input wire clka
        .addra(addr_turn),  // input wire [12 : 0] addra
        .douta(dout_turn)  // output wire [7 : 0] douta
    );

//------------------eat diamond------------------//
    logic [11:0] addr_score;
    logic [7:0] dout_score;

    blk_mem_gen_score score_sound (
        .clka(clk_8),    // input wire clka
        .addra(addr_score),  // input wire [11 : 0] addra
        .douta(dout_score)  // output wire [7 : 0] douta
    );

//----------------game over----------------//
    logic [12:0] addr_hit;
    logic [7:0] dout_hit;

    blk_mem_gen_hit hit_sound (
        .clka(clk_8),    // input wire clka
        .addra(addr_hit),  // input wire [12 : 0] addra
        .douta(dout_hit)  // output wire [7 : 0] douta
    );

    always_ff @(posedge clk_8) begin 
        if (reset) begin
            addr_background <= 0;
            addr_hit <= 0;
            addr_turn <= 0;
            addr_score <= 0; 
         //   audio_out <= 0;
        end
        else begin
            case (switch_screen)
            1'b0: begin
                if (addr_background == BACKGROUND_SOUND_MAX_COUNT) begin
                    addr_background <= 0;
                end
                else begin
                    addr_background <= addr_background + 1;
                    audio_out <= dout_background;
                end
            end
            1'b1: begin
                if (gameover) begin      
                    if (addr_hit == HIT_SOUND_MAX_COUNT) 
                        addr_hit <= 0;
                    else begin
                        addr_hit <= addr_hit + 1;
                        audio_out <= dout_hit;
                    end
                end //gameover
                else if (pbttn[0] || pbttn[1] || pbttn[2] || pbttn[3] || pbttn[4]) begin
                    if (addr_turn == TURN_SOUND_MAX_COUNT)
                        addr_turn <= 0;
                    else begin
                        addr_turn <= addr_turn + 1;
                        audio_out <= dout_turn;
                    end
                end //turn
                else if (ate) begin
                    if (addr_score == SCORE_SOUND_MAX_COUNT)
                        addr_score <= 0;
                    else begin
                        addr_score <= addr_score + 1;
                        audio_out <= dout_score;
                    end 
                end //score
                else  
                    audio_out <= 8'b0;  //no audio out
            end //play game
            endcase
        end
    end 

//----------------Output PWM signal-----------------//   
    always_ff @ (posedge clk) begin
        if (reset) begin
            pwm_cnt <= 0;
            AUD_PWM <= 0;
        end
        else begin
            pwm_cnt <= pwm_cnt + 1;
            if (pwm_cnt >= audio_out)
                AUD_PWM <= 1;
            else  
                AUD_PWM <= 0;
        end
    end
    
    assign AUD_SD = 1'b1;
  
endmodule