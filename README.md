# CECS 525 Group 3 - Project 2

The repository contains the modified firmware (MODWARE) that is to be ran on the Motorola 6800 Minimal Computer Board

### Group Members
* Sheldon Burks
* Jacob Matchuny
* David Decker
* Nick Disibio
* Brad Olges

### Todo
* Part 1
    * Remove unessecary code
* Part 2
    * Login Subroutine
    	* Display password as asterisks
	* Does not run correctly on board
    * ~~Help Command and Subroutine~~
    * ~~RAM Test Subroutine~~
* Part 3 (Reference Text about Interrupts for vector locations)
    * Initialiaze all vector table locations
    * Bus Error Exception
    * Address Error Exception
    * Illegal Instruction Exception
    * Divide By Zero Exception
    * Privilege Violation Exception
    * Trap #0
    	* This will allow users to call firmware functions
    * Trap #14
        * Allow user application breakpoints
    * Trap #15
        * Allow a user application to exit back to MODWARE prompt or do a WARM RESET
    * Rengineer calculator programs from project 1 to call exception service routines 
    from firmware via Trap #0
* Part 4
    * Write unique application which implements the pushbuttons, LEDS, and LCD display.
