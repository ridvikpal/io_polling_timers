.text
.global _start

_start:         LDR     R10, =0xFF200020 // store the address of the hex displays 3-0
                LDR     R1, =0xFF200050 // store the address of the pushbuttons 3-0
				LDR 	R9, =0xFFFEC600 // store the address of the A9 Timer in R9
                MOV     R0, #0 // D0 digit to be displayed on hex display 0 (number counter 1)
                MOV     R2, #0 // D1 digit to be displayed on hex display 1 (number counter 2)
				MOV 	R7, #0 // S1 digit to be displayed on hex display 2 (number counter 3)
				MOV 	R8, #0 // S2 digit to be displayed on hex display 3 (number counter 4)
				MOV 	R4, #0 // combined bit code to push to the hex display
                MOV     R3, #0 // value of pushbuttons 3-0 register or A9 timer
                MOV     R5, #0 // counter to check when button is pressed
                MOV     SP, #0x40000000 // setup the stack pointer
				
				// setup the timer with the correct initial values
				LDR 	R3, =2000000 // start decrementing the timer from 2x10^6 for a 0.01 sec delay
				STR 	R3, [R9] // push the load value into the timer
				MOV 	R3, #0b011
				STR 	R3, [R9, #0x8] // enable the timer and auto reload the timer

MAIN:           // check for a key press
				LDR     R3, [R1, #0xC] // load the value of the pushbuttons edgecapture into R3
                CMP     R3, #0 // check if no buttons are pressed
                BLNE    PAUSE // if a button is pressed, then we need to pause the counter

DISPLAY:        MOV R6, R0 // backup the count in R0 in R6
                BL      SEG7_CODE
                MOV     R4, R0 // store the bit code to be pushed into the hex display in R4

                MOV     R0, R2 // store the tens digit in R2 in R0 because SEG7_CODE takes in R0 as parameter
                BL      SEG7_CODE
                LSL     R0, #8
                ORR     R4, R0 // merge the tens and ones digit and store in R4
				
				MOV R0, R7 // store the seconds ones digit in R0
				BL 		SEG7_CODE
				LSL 	R0, #16
				ORR		R4, R0 // merge the seconds ones digit in R4
				
				MOV R0, R8 // store the seconds tens digit in R0
				BL 		SEG7_CODE
				LSL 	R0, #24
				ORR 	R4, R0 // merge the seconds tens digit in R4
				
				STR     R4, [R10] // write to the hex display

                // delay before going to the next iteration
DELAY:          LDR 	R3, [R9, #0xC] // read the status register
				CMP 	R3, #0 // if the status register is 0
				BEQ 	DELAY
				// else the status register is 1
				STR 	R3, [R9, #0xC] // because status register is 1, then we can reset it by writing 1 to it

                MOV 	R0, R6 // restore the count from R6 back into R0

                CMP     R0, #9 // check if R0 is 9
                BNE     ADD_ONES
                BEQ     ADD_TENS // if R0 is 9, then we need to add tens to the milliseconds
				
CONTINUE_1:		B       MAIN

ADD_ONES:       ADD     R0, #1 // add 1 to R0
                B       CONTINUE_1

ADD_TENS:       CMP     R2, #9 // check if R2 is 9
                ADDNE   R2, #1 // add 1 to R2 if it is not 9
                BEQ		ADD_ONES_SEC // if R2 is 9, then we have to update the ones seconds spot
CONTINUE_2:     MOV     R0, #0 // because we are updating the tens spot, the ones spot will always have to go to 0
                B       CONTINUE_1
				
ADD_ONES_SEC:	MOV 	R2, #0 // reset R2 to 0
				CMP 	R7, #9 // check if R7 is 9
				ADDNE 	R7, #1 // add 1 to R7
				BEQ		ADD_TENS_SEC // if R2 is 9, then we have to update the tens seconds spot
CONTINUE_3:		B 		CONTINUE_2

ADD_TENS_SEC:	MOV 	R7, #0 // reset R7 to 0
				CMP 	R8, #5 // check if R8 is 5
				ADDNE 	R8, #1 // add 1 to R8 if it is not 5
				MOVEQ 	R8, #0 // if R8 is 5, then replace it with 0
				MOV 	R0, #0 // because we are updating the tens seconds spot, the ones seconds spot will always have to go to 0
				B 		CONTINUE_3

PAUSE:			PUSH	{LR}
				BL 		CHECK_RELEASE // wait until the button is released to do anything
				POP		{LR}
				
				PUSH	{LR}
				BL		RESET_EDGECAP // reset the edge caputure register after the button is released
				POP		{LR}
				
				// now we must disable the timer as well
				MOV 	R3, #0b010
				STR 	R3, [R9, #0x8] // set the enable bit in the timer off
				
PAUSE_LOOP:		LDR     R3, [R1, #0xC] // load the value of the pushbuttons edgecapture into R3
                CMP     R3, #0 // check if no buttons are pressed
                BEQ	    PAUSE_LOOP // if no button is pressed, then we need to pause the counter
				
				// at this point a button is pressed
				PUSH 	{LR}
				BL		CHECK_RELEASE // wait until the button is released
				POP 	{LR}
				
				PUSH	{LR}
				BL		RESET_EDGECAP // reset the edge caputure register after the button is released
				POP		{LR}
				
				// now we have to enable the timer
				MOV 	R3, #0b011
				STR 	R3, [R9, #0x8] // set the enable bit in the timer on
				
				BX 		LR // return after button is pressed again
				
				/* Subroutine to reset edgecaputre pushbutton register */
RESET_EDGECAP:	MOV     R3, #0xf //load 1111 into R3
                STR	    R3, [R1, #0xC] // reset the edgecapture register by replacing it with 1111
				BX		LR //exit after edgecaputre is reset
				
				/* Subroutine to check if a button is released */
CHECK_RELEASE:  LDR     R3, [R1] // load in value of pushbuttons data
                CMP     R3, #0   // check if button is released
                BNE     CHECK_RELEASE // if button is not released, stay on the loop
                BX      LR // after button is released, return

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