# Project
Diamond Snake Game on FPGA A7

Finished:
The snake game is implemented on the FPGA A7 board and VGA by SystemVerilog.
The snake's head is red, and its body is blue, while a border/wall is green.
The movement module has 4-bit movements such as up, down, left, and right from the user's inputs by pressing buttons on the FPGA A7 board.
Diamond_gen module generates a random value for a diamond or snake food on the map on the screen.
Vga module is the main module to control the snake game, and it uses the system 100MHz clock and 20Hz clock.
The Segment_display module is a scoreboard that displays how many diamonds are eaten by the snake.
After eating a diamond, the snake increases its speed. There are ten different speeds for the snake movement.
There are some objects in the game map to make the game harder.

# How to run the game:
1. open Visual studio.
2. on platformIO, add bitstream path. 
3. upload the bit stream.
4. run 71_7SegDispl.S assembly code for 7 segment displays.

