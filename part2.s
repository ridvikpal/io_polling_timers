.text
.global _start

_start:         LDR     R10, =0xFF200020 // store the address of the hex displays 3-0
                LDR     R1, =0xFF200050 // store the address of the pushbuttons 3-0
                MOV     R0, #0 // ones digit to be displayed on hex display 0 (number counter 1)
                MOV     R2, #0 // tens digit to be displayed on hex display 1 (number counter 1)
                MOV     R3, #0 // value of pushbuttons 3-0 register
                MOV     R5, #0 // counter to check when button is pressed
                MOV     SP, #0x40000000 // setup the stack pointer

MAIN:           LDR     R3, [R1, #0xC] // load the value of the pushbuttons edgecapture into R3
                CMP     R3, #0 // check if no buttons are pressed
                BLNE    PAUSE // if a button is pressed, then we need to pause the counter

DISPLAY:        PUSH    {R0} // backup the count in R0 on the stack
                BL      SEG7_CODE
                MOV     R4, R0 // store the bit code to be pushed into the hex display in R4

                MOV     R0, R2 // store the tens digit in R2 in R0 because SEG7_CODE takes in R0 as parameter
                BL      SEG7_CODE
                LSL     R0, #8
                ORR     R4, R0 // merge the tens and ones digit and store in R4
                STR     R4, [R10] // write to the hex display

                // delay before going to the next iteration
DELAY:          //LDR     R7, =500000 // delay count for CPULATOR
				LDR    R7, =20000000 // delay count for hardware implementation
DELAY_LOOP:     SUBS    R7, #1
                BNE     DELAY_LOOP

                POP     {R0} // restore the count from R0 previously back into R0

                CMP     R0, #9 // check if R0 is 9
                BNE     ADD_ONES
                BEQ     ADD_TENS // if R0 is 9, then we need to add tens

CONTINUE:       B       MAIN

ADD_ONES:       ADD     R0, #1 // add 1 to R0
                B       CONTINUE

ADD_TENS:       CMP     R2, #9 // check if R2 is 9
                ADDNE   R2, #1 // add 1 to R2 if it is not 9
                MOVEQ   R2, #0 // if R1 is 9, then replace it with 0
                MOV     R0, #0 // because we are updating the tens spot, the ones spot will always have to go to 0
                B       CONTINUE

PAUSE:			PUSH	{LR}
				BL 		CHECK_RELEASE // wait until the button is released to do anything
				POP		{LR}
				
				PUSH	{LR}
				BL		RESET_EDGECAP // reset the edge caputure register after the button is released
				POP		{LR}
				
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