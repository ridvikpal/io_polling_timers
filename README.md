# io_polling_timers
Working code for ECE243 Lab 3 (Winter 2023) at the University of Toronto. The goal is to learn how to use timers and pushbuttons. All code is written and debugged in ARM Assembly. To simulate the code, upload the code and compile using the ARMv7 [CPUlator online tool](https://cpulator.01xz.net/?sys=arm-de1soc "CPUlator"). See the lab handout for more information.

## Part 1
Part 1 display decimal digits on the hex display HEX0. The number displayed can be incremented, decremented, blanked, and zeroed based on the pushbutton pressed:
![image](https://user-images.githubusercontent.com/105998663/221738362-17d82ed1-9b0b-4be8-b9c2-ef5ff12f9a9d.png)

## Part 2
Part 2 creates a two digit decimal coutner displayed on HEX1 and HEX0. The counter increments approximately every 0.25 seconds. The counter can start/stop when any pushbutton is pressed:
![image](https://user-images.githubusercontent.com/105998663/221738868-b0fee51c-857e-4c48-a79f-0d80535c39fc.png)

## Part 3
Part 3 does the same as part 2 but uses the A9 hardware timer to provide an exact delay of 0.25 seconds instead of an approximate delay.

## Part 4
Part 4 creates a real-time clock displaying seconds and hundredths of a second in the format SS:DD on the hex displays HEX3 to HEX0. The clock can start/stop when any pushbutton is pressed:
![image](https://user-images.githubusercontent.com/105998663/221739464-a8bd55f1-d4ec-4efd-940a-8a6fa322bed7.png)
