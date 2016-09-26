*-----------------------------------------------------------
* Title      : Test Program
* Written by : 
* Date       : 9/22/2016
* Description: Test Program to Test Assertions
*-----------------------------------------------------------

        ORG     $4C00
        
START   ;MOVE.W  #1,$4001    ;For address error

        ;ILLEGAL             ;For illegal instruction
        
        ;ANDI.W  #$DFFF,SR   ;Go into usermode
        ;RESET
        
        TRAP    #14         ;Breakpoint
        
        TRAP    #15         ;Warm reset


        END     START


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
