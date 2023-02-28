.text
.global _start

_start:         LDR     R10, =0xFF200020 // store the address of the hex displays 3-0
                LDR     R1, =0xFF200050 // store the address of the pushbuttons 3-0
                MOV     R0, #0 // number to be displayed on hex displays
                MOV     R2, #0 // memory for number counter
                MOV     R3, #0 // value of pushbuttons 3-0 register
                MOV     SP, #0x40000000 // setup the stack pointer

MAIN:           LDR     R3, [R1] // get the value of the pushbuttons parallel port
                CMP     R3, #8 // check if key3 is pressed
                BEQ     KEY3_PRESS

                CMP     R3, #4 // check if key2 is pressed
                BEQ     KEY2_PRESS

                CMP     R3, #2 // check if key1 is pressed
                BEQ     KEY1_PRESS

                CMP     R3, #1 // check if key0 is pressed
                BEQ     KEY0_PRESS

                // else no key is being pressed, keep looping to check for when a key is pressed
                B       MAIN

KEY3_PRESS:     BL      WAIT // wait until key is released
                MOV     R0, #0
                STR     R0, [R10] // write 0 to the display to blank it
                MOV     R0, #-1 // also write -1 to our number register to indicate it is blank
                B       MAIN

KEY2_PRESS:     BL      WAIT // wait until key is released
                CMP     R0, #-1 // check if the display is turned off
                BEQ     RESET // reset the display if key3 was pressed before key2

                // check if number counter is equal to 0
                CMP     R0, #0
                BEQ     MAIN // do nothing if the number counter is equal to 0

                SUB     R0, #1 // subtract 1 from number counter
                MOV     R2, R0 // backup the number counter to R2
                BL      SEG7_CODE // get bit code for number counter for hex display
                STR     R0, [R10] // write to the hex display
                MOV     R0, R2 // restore the number we are on from R2
                B       MAIN

KEY1_PRESS:     BL      WAIT // wait until key is released
                CMP     R0, #-1 // check if the display is turned off
                BEQ     RESET // reset the display if key3 was pressed before key1

                // check if number counter is equal to 9
                CMP     R0, #9
                BEQ     MAIN // do nothing if the number counter is equal to 9

                ADD     R0, #1 // add 1 to number counter
                MOV     R2, R0 // backup the number counter to R2
                BL      SEG7_CODE // get bit code for number counter for hex display
                STR     R0, [R10] // write to the hex display
                MOV     R0, R2 // restore the number we are on from R2
                B       MAIN

KEY0_PRESS:     BL      WAIT
                MOV     R0, #0 // set the number counter to 0
                BL      SEG7_CODE // get the bit code for 0 for the hex display
                STR     R0, [R10] // write to the hex display
                MOV     R0, #0 // restore 0 to the number counter
                B       MAIN

                // this label will reset the display to 0
RESET:          MOV     R0, #0 // write 0 to our number counter
                BL      SEG7_CODE // get bit code for 0 in the hex display
                STR     R0, [R10]; // write 0 to the hex display
                MOV     R0, #0 // store 0 back in our number counter
                B       MAIN // return to main to wait until next key is pressed

                // this subroutine consistently waits until a key is not pressed via polling
WAIT:           LDR     R3, [R1] // store the value of the pushbuttons in R3
                CMP     R3, #0 // check if the pushbuttons are released
                BNE     WAIT
                BX      LR

                /* Subroutine to convert the digits from 0 to 9 to be shown on a HEX display.
				 *    Parameters: R0 = the decimal value of the digit to be displayed
				 *    Returns: R0 = bit patterm to be written to the HEX display
				 */
SEG7_CODE:		PUSH    {R1} // push the memory location of the pushbuttons onto the stack
                MOV		R1, #BIT_CODES
				ADD		R1, R0         // index into the BIT_CODES "array"
				LDRB	R0, [R1]       // load the bit pattern (to be returned)
                POP     {R1} // pop the memory location of the pushbuttons back into R1
				BX		LR

                // bit codes for the hex display
BIT_CODES:		.byte	0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
				.byte	0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
				.skip	2 // pad with 2 bytes to maintain word alignment