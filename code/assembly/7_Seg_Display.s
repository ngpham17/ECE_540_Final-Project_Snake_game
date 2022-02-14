/*
    ECE 540
    Melinda Van
    7 segment display
*/
#----------------------------------------------------------------------------
# Read score stored in vga address and then display on 7-seg display by 
# converting its value in hex to binary coded decimal (BCD) value
# Constant register used: 
#   - s3: stored score in hex
#   - s4: stored score in BCD
#-----------------------------------------------------------------------------

#define SegEnable_ADDR  0x80001038  #7-seg digit enable address
#define SegDigit_ADDR   0x8000103C  #7-seg displayed number address
#define VGA             0x80003000  #VGA base address
#define DELAY           0x1000000   #delay value between display numbers
#define TEN_THOUSANDS   10000
#define THOUSANDS       1000
#define HUNDREDS        100
#define TENS            10

.globl main
main:
    li s9, DELAY            #load the delay number
    li s1, SegEnable_ADDR   #load the digit enable address
    li t6, 0xE0             #enable the five right most digits of 7-seg display
    sb t6, 0(s1)            #write it to the digit enable address

    li s1, SegDigit_ADDR    #load the displayed number address
    li s2, VGA              #load VGA base address
    #li s3, 0x2b67          #testing numbers --> BCD = 11,111
    li s5, 4                #compared loop value, 4 = load ten thousands digit
    li s6, 3                #3 = load thousands digit
    li s7, 2                #2 = load hundreds digit
    li s8, 1                #1 = load tens digit
    
repeat:
#-------------------Score input----------------------#
    lw s3, 0(s2)            #read game score stored in the VGA address

#-------------------Initialization-------------------# 
    add s4, zero, zero      #BCD value
    li t5, 4                #loop counter

#-------------------Delay loop----------------------#
    add t3, zero, zero      #initiate the counter value to 0
delay_loop:
    addi t3, t3, 1          #increment the counter by 1
    blt t3, s9, delay_loop  #continue to increment until equal to delay value

#-----------------BCD conversion--------------------#
BCD_conversion:
    add t4, zero, zero              #initialize temp register to hold temp BCD digit
#Determine which digit value to load
    beq t5, s5, ten_thousands_digit #t5 = 4
    beq t5, s6, thousands_digit     #t5 = 3
    beq t5, s7, hundreds_digit      #t5 = 2
    beq t5, s8, tens_digit          #t5 = 1

ten_thousands_digit:
    li t3, TEN_THOUSANDS    #load ten thousands 
    j extract_digit

thousands_digit:
    li t3, THOUSANDS        #load thousand
    j extract_digit

hundreds_digit:
    li t3, HUNDREDS         #load hundreds
    j extract_digit

tens_digit:
    li t3, TENS             #load tens
    j extract_digit

extract_digit:
    blt s3, t3, continue    #if displayed number less than 10,000, go check for thousands
    sub s3, s3, t3          #subtract the display number by 10,000
    addi t4, t4, 1          #increment ten thousand digit by 1
    j extract_digit         #go back to 

continue:
    add s4, s4, t4          #store temp value in the BCD
    slli s4, s4, 4          #shift to the left by 4
    addi t5, t5, -1         #decrement the loop counter by 1
    bnez t5, BCD_conversion #return to the loop to extract the next digit 

    add s4, s4, s3          #add ones to BCD          
    sw s4, 0(s1)            #write BCD value to 7-seg digit address

    j repeat