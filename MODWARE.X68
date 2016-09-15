*        TSBUG2 - 68000 monitor - version of 05 January 2010 

	 ORG      $0
         DC.L     STACK,RESET
*                                   Symbol equates 
BS       EQU      $08               Back_space 
CR       EQU      $0D               Carriage_return 
LF       EQU      $0A               Line_feed 
SPACE    EQU      $20               Space 
WAIT     EQU      'W'               Wait character (to suspend output) 
ESC      EQU      $1B               ASCII escape character (used by TM) 
CTRL_A   EQU      $01               Control_A forces return to monitor 
*                                   Device addresses 
STACK    EQU      $4400             Stack_pointer
ACIA_1   EQU      $8001             Console ACIA control 
ACIA_2   EQU      ACIA_1            Auxilary ACIA control 
X_BASE   EQU      $4000             Start of exception vector table 
TRAP_14  EQU      $4E4E             Code for TRAP #14 
MAXCHR   EQU      64                Length of input line buffer  
* 
DATA     EQU      $4800             Data origin 
LNBUFF   DS.B     MAXCHR            Input line buffer
BUFFEND  EQU      LNBUFF+MAXCHR-1   End of line buffer 
BUFFPT   DS.L     1                 Pointer to line buffer 
PARAMTR  DS.L     1                 Last parameter from line buffer 
ECHO     DS.B     1                 When clear this enable input echo 
U_CASE   DS.B     1                 Flag for upper case conversion 
UTAB     DS.L     1                 Pointer to user command table 
CN_IVEC  DS.L     1                 Pointer to console input DCB 
CN_OVEC  DS.L     1                 Pointer to console output DCB 
TSK_T    DS.W     37                Frame for D0-D7, A0-A6, USP, SSP, SW, PC 
BP_TAB   DS.W     24                Breakpoint table 
FIRST    DS.B     512               DCB area 
BUFFER   DS.B     256               256 bytes for I/O buffer 
* 
************************************************************************* 
* 
*  This is the main program which assembles a command in the line 
*  buffer, removes leading/embedded spaces and interprets it by matching 
*  it with a command in the user table or the built-in table COMTAB 
*  All variables are specified with respect to A6 
*
         ORG      $1000             Monitor Origin
RESET:   EQU      *
         LEA.L    DATA,A6           A6 points to data area 
	 MOVE.L	  A6,TSK_T+56(A6)   initialize A6 in the regster Frame
         CLR.L    UTAB(A6)          Reset pointer to user extension table 
         CLR.B    ECHO(A6)          Set automatic character echo 
         CLR.B    U_CASE(A6)        Clear case conversion flag (UC<-LC) 
         BSR.S    SETACIA           Setup ACIAs 
	 BSR.L	  X_SET		    what change did i do here
         BSR.L    SET_DCB           Setup DCB table in RAM
         BSR.S    NEWLINE
         LEA.L    BANNER(PC),A4    
         BSR.S    PSTRING
         BSR.S    NEWLINE           
	 LEA.L	  MODIFY(PC),A4
         BSR.S    PSTRING
         BSR.S    NEWLINE
	 LEA.L	  WHY(PC),A4
         BSR.S    PSTRING
         BSR.S    NEWLINE
	 LEA.L	  WHERE(PC),A4
         BSR.S    PSTRING
         BSR.S    NEWLINE
	 LEA.L	  ADDRE(PC),A4
         BSR.S    PSTRING
         BSR.S    NEWLINE
         MOVE.L   #$3000,A0         A0 points to extension ROM 
         MOVE.L   (A0),D0           Read first longword in extension ROM 
         CMP.L    #'ROM2',D0        If extension begins with 'ROM2' then 
         BNE.S    NO_EXT            call the subroutine at EXT_ROM+8 
         JSR      8(A0)             else continue 
NO_EXT:  NOP                        Two NOPs to allow for a future 
         NOP                        call to an initialization routine 
WARM:    CLR.L    D7                Warm entry point - clear error flag 
         BSR.S    NEWLINE           Print a newline 
         BSR.S    GETLINE           Get a command line 
         BSR      TIDY              Tidy up input buffer contents 
         BSR      EXECUTE           Interpret command 
         BRA      WARM              Repeat indefinitely 
* 
************************************************************************* 
* 
*  Some initialization and basic routines 
* 
SETACIA  EQU      *                 Setup ACIA parameters 
         LEA.L    ACIA_1,A0         A0 points to console ACIA 
         MOVE.B   #$03,(A0)         Reset ACIA1 
         MOVE.B   #$03,1(A0)        Reset ACIA2 
         MOVE.B   #$19,(A0)         Set up ACIA1 constants (no IRQ, 
         MOVE.B   #$19,1(A0)        RTS* low, 8 bit, no parity, 1 stop) 
         RTS                        Return 
* 
NEWLINE  EQU      *                 Move cursor to start of newline 
         MOVEM.L  A4,-(A7)          Save A4 
         LEA.L    CRLF(PC),A4       Point to CR/LF string 
         BSR.S    PSTRING           Print it 
         MOVEM.L  (A7)+,A4          Restore A4 
         RTS                        Return 
* 
PSTRING  EQU      *                 Display the string pointed at by A4 
         MOVE.L   D0,-(A7)          Save D0 
PS1      MOVE.B   (A4)+,D0          Get character to be printed 
         BEQ.S    PS2               If null then return 
         BSR      PUTCHAR           Else print it 
         BRA      PS1               Continue 
PS2      MOVE.L   (A7)+,D0          Restore D0 and exit 
         RTS 
* 
HEADING  BSR      NEWLINE           Same as PSTRING but with newline 
         BSR      PSTRING 
         BRA      NEWLINE 
* 
************************************************************************* 
* 
*  GETLINE  inputs a string of characters into a line buffer 
*           A3 points to next free entry in line buffer 
*           A2 points to end of buffer 
*           A1 points to start of buffer 
*           D0 holds character to be stored 
* 
GETLINE  LEA.L    LNBUFF(A6),A1     A1 points to start of line buffer 
         LEA.L    (A1),A3           A3 points to start (initially) 
         LEA.L    MAXCHR(A1),A2     A2 points to end of buffer 
GETLN2   BSR      GETCHAR           Get a character 
         CMP.B    #CTRL_A,D0        If control_A then reject this line 
         BEQ.S    GETLN5            and get another line 
         CMP.B    #BS,D0            If back_space then move back pointer 
         BNE.S    GETLN3            Else skip past wind-back routine 
         CMP.L    A1,A3             First check for empty buffer 
         BEQ      GETLN2            If buffer empty then continue 
         LEA      -1(A3),A3         Else decrement buffer pointer 
         BRA      GETLN2            and continue with next character 
GETLN3   MOVE.B   D0,(A3)+          Store character and update pointer 
         CMP.B    #CR,D0            Test for command terminator 
         BNE.S    GETLN4            If not CR then skip past exit 
         BRA      NEWLINE           Else new line before next operation 
GETLN4   CMP.L    A2,A3             Test for buffer overflow 
         BNE      GETLN2            If buffer not full then continue 
GETLN5   BSR      NEWLINE           Else move to next line and 
         BRA      GETLINE           repeat this routine 
* 
************************************************************************* 
* 
*  TIDY cleans up the line buffer by removing leading spaces and multiple 
*       spaces between parameters. At the end of TIDY, BUFFPT points to 
*       the first parameter following the command. 
*       A0 = pointer to line buffer. A1 = pointer to cleaned up buffer 
* 
TIDY     LEA.L    LNBUFF(A6),A0     A0 points to line buffer 
         LEA.L    (A0),A1           A1 points to start of line buffer 
TIDY1    MOVE.B   (A0)+,D0          Read character from line buffer 
         CMP.B    #SPACE,D0         Repeat until the first non-space 
         BEQ      TIDY1             character is found 
         LEA.L    -1(A0),A0         Move pointer back to first char 
TIDY2    MOVE.B   (A0)+,D0          Move the string left to remove 
         MOVE.B   D0,(A1)+          any leading spaces 
         CMP.B    #SPACE,D0         Test for embedded space 
         BNE.S    TIDY4             If not space then test for EOL 
TIDY3    CMP.B    #SPACE,(A0)+      If space skip multiple embedded 
         BEQ      TIDY3             spaces 
         LEA.L    -1(A0),A0         Move back pointer 
TIDY4    CMP.B    #CR,D0            Test for end_of_line (EOL) 
         BNE      TIDY2             If not EOL then read next char 
         LEA.L    LNBUFF(A6),A0     Restore buffer pointer 
TIDY5    CMP.B    #CR,(A0)          Test for EOL 
         BEQ.S    TIDY6             If EOL then exit 
         CMP.B    #SPACE,(A0)+      Test for delimiter 
         BNE      TIDY5             Repeat until delimiter or EOL 
TIDY6    MOVE.L   A0,BUFFPT(A6)     Update buffer pointer 
         RTS 
* 
************************************************************************* 
* 
*  EXECUTE matches the first command in the line buffer with the 
*  commands in a command table. An external table pointed at by 
*  UTAB is searched first and then the in-built table, COMTAB. 
* 
EXECUTE  TST.L    UTAB(A6)          Test pointer to user table 
         BEQ.S    EXEC1             If clear then try built-in table 
         MOVE.L   UTAB(A6),A3       Else pick up pointer to user table 
         BSR.S    SEARCH            Look for command in user table 
         BCC.S    EXEC1             If not found then try internal table 
         MOVE.L   (A3),A3           Else get absolute address of command 
         JMP      (A3)              from user table and execute it 
* 
EXEC1    LEA.L    COMTAB(PC),A3     Try built-in command table 
         BSR.S    SEARCH            Look for command in built-in table 
         BCS.S    EXEC2             If found then execute command 
         LEA.L    ERMES2(PC),A4     Else print "invalid command" 
         BRA.L    PSTRING           and return 
EXEC2    MOVE.L   (A3),A3           Get the relative command address 
         LEA.L    COMTAB(PC),A4     pointed at by A3 and add it to 
         ADD.L    A4,A3             the PC to generate the actual 
         JMP      (A3)              command address. Then execute it. 
* 
SEARCH   EQU      *                 Match the command in the line buffer 
         CLR.L    D0                with command table pointed at by A3 
         MOVE.B   (A3),D0           Get the first character in the 
         BEQ.S    SRCH7             current entry. If zero then exit 
         LEA.L    6(A3,D0.W),A4     Else calculate address of next entry 
         MOVE.B   1(A3),D1          Get number of characters to match 
         LEA.L    LNBUFF(A6),A5     A5 points to command in line buffer 
         MOVE.B   2(A3),D2          Get first character in this entry 
         CMP.B    (A5)+,D2          from the table and match with buffer 
         BEQ.S    SRCH3             If match then try rest of string 
SRCH2    MOVE.L   A4,A3             Else get address of next entry 
         BRA      SEARCH            and try the next entry in the table 
SRCH3    SUB.B    #1,D1             One less character to match 
         BEQ.S    SRCH6             If match counter zero then all done 
         LEA.L    3(A3),A3          Else point to next character in table 
SRCH4    MOVE.B   (A3)+,D2          Now match a pair of characters 
         CMP.B    (A5)+,D2 
         BNE      SRCH2             If no match then try next entry 
         SUB.B    #1,D1             Else decrement match counter and 
         BNE      SRCH4             repeat until no chars left to match 
SRCH6    LEA.L    -4(A4),A3         Calculate address of command entry 
         OR.B     #1,CCR            point. Mark carry flag as success 
         RTS                        and return 
SRCH7    AND.B    #$FE,CCR          Fail - clear carry to indicate 
         RTS                        command not found and return 
* 
************************************************************************* 
* 
* 
*  PARAM reads a parameter from the line buffer and puts it in both 
*  PARAMTR(A6) and D0. Bit 1 of D7 is set on error. 
* 
PARAM    MOVE.L   D1,-(A7)          Save D1 
         CLR.L    D1                Clear input accumulator 
         MOVE.L   BUFFPT(A6),A0     A0 points to parameter in buffer 
PARAM1   MOVE.B   (A0)+,D0          Read character from line buffer 
         CMP.B    #SPACE,D0         Test for delimiter 
         BEQ.S    PARAM4            The permitted delimiter is a 
         CMP.B    #CR,D0            space or a carriage return 
         BEQ.S    PARAM4            Exit on either space or C/R 
         ASL.L    #4,D1             Shift accumulated result 4 bits left 
         SUB.B    #$30,D0           Convert new character to hex 
         BMI.S    PARAM5            If less than $30 then not-hex 
         CMP.B    #$09,D0           If less than 10 
         BLE.S    PARAM3            then continue 
         SUB.B    #$07,D0           Else assume $A - $F 
         CMP.B    #$0F,D0           If more than $F 
         BGT.S    PARAM5            then exit to error on not-hex 
PARAM3   ADD.B    D0,D1             Add latest nybble to total in D1 
         BRA      PARAM1            Repeat until delimiter found 
PARAM4   MOVE.L   A0,BUFFPT(A6)     Save pointer in memory 
         MOVE.L   D1,PARAMTR(A6)    Save parameter in memory 
         MOVE.L   D1,D0             Put parameter in D0 for return 
         BRA.S    PARAM6            Return without error 
PARAM5   OR.B     #2,D7             Set error flag before return 
PARAM6   MOVE.L   (A7)+,D1          Restore working register 
         RTS                        Return with error 
* 
************************************************************************* 
* 
*  Output routines 
*  OUT1X   = print one   hexadecimal character 
*  OUT2X   = print two   hexadecimal characters 
*  OUT4X   = print four  hexadecimal characters 
*  OUT8X   = print eight hexadecimal characters 
*  In each case, the data to be printed is in D0 
* 
OUT1X    MOVE.W   D0,-(A7)          Save D0 
         AND.B    #$0F,D0           Mask off MS nybble 
         ADD.B    #$30,D0           Convert to ASCII 
         CMP.B    #$39,D0           ASCII = HEX + $30 
         BLS.S    OUT1X1            If ASCII <= $39 then print and exit 
         ADD.B    #$07,D0           Else ASCII := HEX + 7 
OUT1X1   BSR      PUTCHAR           Print the character 
         MOVE.W   (A7)+,D0          Restore D0 
         RTS 
* 
OUT2X    ROR.B    #4,D0             Get MS nybble in LS position 
         BSR      OUT1X             Print MS nybble 
         ROL.B    #4,D0             Restore LS nybble 
         BRA      OUT1X             Print LS nybble and return 
* 
OUT4X    ROR.W    #8,D0             Get MS byte in LS position 
         BSR      OUT2X             Print MS byte 
         ROL.W    #8,D0             Restore LS byte 
         BRA      OUT2X             Print LS byte and return 
* 
OUT8X    SWAP     D0                Get MS word in LS position 
         BSR      OUT4X             Print MS word 
         SWAP     D0                Restore LS word 
         BRA      OUT4X             Print LS word and return 
* 
************************************************************************* 
* 
* JUMP causes execution to begin at the address in the line buffer 
* 
JUMP     BSR     PARAM              Get address from buffer 
         TST.B   D7                 Test for input error 
         BNE.S   JUMP1              If error flag not zero then exit 
         TST.L   D0                 Else test for missing address 
         BEQ.S   JUMP1              field. If no address then exit 
         MOVE.L  D0,A0              Put jump address in A0 and call the 
         JMP     (A0)               subroutine. User to supply RTS!! 
JUMP1    LEA.L   ERMES1(PC),A4      Here for error - display error 
         BRA     PSTRING            message and return 
* 
************************************************************************* 
* 
PSPACE   MOVE.B   D0,-(A7)          Print a single space 
         MOVE.B   #SPACE,D0 
         BSR      PUTCHAR 
         MOVE.B   (A7)+,D0 
         RTS 
************************************************************************* 
* 
*  LOAD  Loads data formatted in hexadecimal "S" format from Port 2 
*        NOTE - I/O is automatically redirected to the aux port for 
*        loader functions. S1 or S2 records accepted 
* 
LOAD     MOVE.L   CN_OVEC(A6),-(A7) Save current output device name 
         MOVE.L   CN_IVEC(A6),-(A7) Save current input device name 
         MOVE.L   #DCB4,CN_OVEC(A6) Set up aux ACIA as output 
         MOVE.L   #DCB3,CN_IVEC(A6) Set up aux ACIA as input 
         ADD.B    #1,ECHO(A6)       Turn off character echo 
         BSR      NEWLINE           Send newline to host 
         BSR      DELAY             Wait for host to "settle" 
         BSR      DELAY 
         MOVE.L   BUFFPT(A6),A4     Any string in the line buffer is 
LOAD1    MOVE.B   (A4)+,D0          transmitted to the host computer 
         BSR      PUTCHAR           before the loading begins 
         CMP.B    #CR,D0            Read from the buffer until EOL 
         BNE      LOAD1 
         BSR      NEWLINE           Send newline before loading 
LOAD2    BSR      GETCHAR           Records from the host must begin 
         CMP.B    #'S',D0           with S1/S2 (data) or S9/S8 (term) 
         BNE.S    LOAD2             Repeat GETCHAR until char = "S" 
         BSR      GETCHAR           Get character after "S" 
         CMP.B    #'9',D0           Test for the two terminators S9/S8 
         BEQ.S    LOAD3             If S9 record then exit else test 
         CMP.B    #'8',D0           for S8 terminator. Fall through to 
         BNE.S    LOAD6             exit on S8 else continue search 
LOAD3    EQU      *                 Exit point from LOAD 
         MOVE.L   (A7)+,CN_IVEC(A6) Clean up by restoring input device 
         MOVE.L   (A7)+,CN_OVEC(A6) and output device name 
         CLR.B    ECHO(A6)          Restore input character echo 
         BTST   #0,D7             Test for input errors 
         BEQ.S    LOAD4             If no I/P error then look at checksum 
         LEA.L    ERMES1(PC),A4     Else point to error message 
         BSR      PSTRING           Print it 
LOAD4    BTST   #3,D7             Test for checksum error 
         BEQ.S    LOAD5             If clear then exit 
         LEA.L    ERMES3(PC),A4     Else point to error message 
         BSR      PSTRING           Print it and return 
LOAD5    RTS 


         RTS                         and return 
* 
************************************************************************* 
RANGE    EQU      *                 Get the range of addresses to be 
         CLR.B    D7                transmitted from the buffer 
         BSR      PARAM             Get starting address 
         MOVE.L   D0,A3             Set up start address in A3 
         BSR      PARAM             Get end address 
         MOVE.L   D0,A2             Set up end address in A2 
         RTS 
* 
DELAY    EQU       *                Provide a time delay for the host 
         MOVEM.L   D0/A4,-(A7)      to settle. Save working registers 
         MOVE.L    #$4000,D0        Set up delay constant 
DELAY1   SUB.L     #1,D0            Count down         (8 clk cycles) 
         BNE       DELAY1           Repeat until zero  (10 clk cycles) 
         MOVEM.L   (A7)+,D0/A4      Restore working registers 
         RTS 
* 
************************************************************************* 
* 
*  This routine sets up the system DCBs in RAM using the information 
*  stored in ROM at address DCB_LST. This is called at initialization. 
*  CN_IVEC contains the name "DCB1" and IO_VEC the name "DCB2" 
* 
SET_DCB  MOVEM.L A0-A3/D0-D3,-(A7) Save all working registers 
         LEA.L   FIRST(A6),A0    Pointer to first DCB destination in RAM 
         LEA.L   DCB_LST(PC),A1  A1 points to DCB info block in ROM 
         MOVE.W  #5,D0           6 DCBs to set up 
ST_DCB1  MOVE.W  #15,D1          16 bytes to move per DCB header 
ST_DCB2  MOVE.B  (A1)+,(A0)+     Move the 16 bytes of a DCB header 
         DBRA    D1,ST_DCB2      from ROM to RAM 
         MOVE.W  (A1)+,D3        Get size of parameter block (bytes) 
         MOVE.W  D3,(A0)         Store size in DCB in RAM 
         LEA.L   2(A0,D3.W),A0   A0 points to tail of DCB in RAM 
         LEA.L   4(A0),A3        A3 contains address of next DCB in RAM 
         MOVE.L  A3,(A0)         Store pointer to next DCB in this DCB 
         LEA.L   (A3),A0         A0 now points at next DCB in RAM 
         DBRA    D0,ST_DCB1      Repeat until all DCBs set up 
         LEA.L   -4(A3),A3       Adjust A3 to point to last DCB pointer 
         CLR.L   (A3)            and force last pointer to zero 
         MOVE.L  #DCB1,CN_IVEC(A6) Set up vector to console input DCB 
         MOVE.L  #DCB2,CN_OVEC(A6) Set up vector to console output DCB 
         MOVEM.L (A7)+,A0-A3/D0-D3 Restore registers 
         RTS 
* 
************************************************************************* 
* 
*  IO_REQ handles all input/output transactions. A0 points to DCB on 
*  entry. IO_REQ calls the device driver whose address is in the DCB. 
* 
IO_REQ   MOVEM.L A0-A1,-(A7)     Save working registers 
         LEA.L   8(A0),A1        A1 points to device handler field in DCB 
         MOVE.L  (A1),A1         A1 contains device handler address 
         JSR     (A1)            Call device handler 
         MOVEM.L (A7)+,A0-A1     Restore working registers 
         RTS 
* 
************************************************************************* 
* 
*  CON_IN handles input from the console device 
*  This is the device driver used by DCB1. Exit with input in D0 
* 
CON_IN   MOVEM.L D1/A1,-(A7)     Save working registers 
         LEA.L   12(A0),A1       Get pointer to ACIA from DCB 
         MOVE.L  (A1),A1         Get address of ACIA in A1 
         CLR.B   19(A0)          Clear logical error in DCB 
CON_I1   MOVE.B  (A1),D1         Read ACIA status 
         BTST  #0,D1           Test RDRF 
         BEQ     CON_I1          Repeat until RDRF true 
         MOVE.B  D1,18(A0)       Store physical status in DCB 
         AND.B   #%011110100,D1  Mask to input error bits 
         BEQ.S   CON_I2          If no error then skip update 
         MOVE.B  #1,19(A0)       Else update logical error 
CON_I2   MOVE.B  2(A1),D0        Read input from ACIA 
         MOVEM.L (A7)+,A1/D1     Restore working registers 
         RTS 
* 
************************************************************************* 
* 
*   This is the device driver used by DCB2. Output in D0 
*   The output can be halted or suspended 
* 
CON_OUT  MOVEM.L A1/D1-D2,-(A7)  Save working registers 
         LEA.L   12(A0),A1       Get pointer to ACIA from DCB 
         MOVE.L  (A1),A1         Get address of ACIA in A1 
         CLR.B   19(A0)          Clear logical error in DCB 
CON_OT1  MOVE.B  (A1),D1         Read ACIA status 
         BTST  #0,D1           Test RDRF bit (any input?) 
         BEQ.S   CON_OT3         If no input then test output status 
         MOVE.B  2(A1),D2        Else read the input 
         AND.B   #%01011111,D2   Strip parity and bit 5 
         CMP.B   #WAIT,D2        and test for a wait condition 
         BNE.S   CON_OT3         If not wait then ignore and test O/P 
CON_OT2  MOVE.B  (A1),D2         Else read ACIA status register 
         BTST  #0,D2           and poll ACIA until next char received 
         BEQ     CON_OT2 
CON_OT3  BTST  #1,D1           Repeat 
         BEQ     CON_OT1          until ACIA Tx ready 
         MOVE.B  D1,18(A0)       Store status in DCB physical error 
         MOVE.B  D0,2(A1)        Transmit output 
         MOVEM.L (A7)+,A1/D1-D2  Restore working registers 
         RTS 
* 
************************************************************************* 
* 
*  AUX_IN and AUX_OUT are simplified versions of CON_IN and 
*  CON_OUT for use with the port to the host processor 
* 
AUX_IN   LEA.L   12(A0),A1       Get pointer to aux ACIA from DCB 
         MOVE.L  (A1),A1         Get address of aux ACIA 
AUX_IN1  BTST.B  #0,(A1)         Test for data ready 
         BEQ     AUX_IN1         Repeat until ready 
         MOVE.B  2(A1),D0        Read input 
         RTS 
* 
AUX_OUT  LEA.L   12(A0),A1       Get pointer to aux ACIA from DCB 
         MOVE.L  (A1),A1         Get address of aux ACIA 
AUX_OT1  BTST.B  #1,(A1)         Test for ready to transmit 
         BEQ     AUX_OT1         Repeat until transmitter ready 
         MOVE.B  D0,2(A1)        Transmit data 
         RTS 
* 
************************************************************************* 
* 
*  GETCHAR gets a character from the console device 
*  This is the main input routine and uses the device whose name  
*  is stored in CN_IVEC. Changing this name redirects input. 
* 
GETCHAR  MOVE.L  A0,-(A7)        Save working register 
         MOVE.L  CN_IVEC(A6),A0  A0 points to name of console DCB 
         BSR.S   IO_OPEN         Open console (get DCB address in A0) 
         BTST  #3,D7           D7(3) set if open error 
         BNE.S   GETCH3          If error then exit now 
         BSR     IO_REQ          Else execute I/O transaction 
         AND.B   #$7F,D0         Strip msb of input 
         TST.B   U_CASE(A6)      Test for upper -> lower case conversion 
         BNE.S   GETCH2          If flag not zero do not convert case 
         BTST  #6,D0           Test input for lower case 
         BEQ.S   GETCH2          If upper case then skip conversion 
         AND.B   #%11011111,D0   Else clear bit 5 for upper case conv 
GETCH2   TST.B   ECHO(A6)        Do we need to echo the input? 
         BNE.S   GETCH3          If ECHO not zero then no echo 
         BSR.S   PUTCHAR         Else echo the input 
GETCH3   MOVE.L  (A7)+,A0        Restore working register 
         RTS                     and return 
* 
************************************************************************* 
* 
*  PUTCHAR sends a character to the console device 
*  The name of the output device is in CN_OVEC. 
* 
PUTCHAR  MOVE.L  A0,-(A7)        Save working register 
         MOVE.L  CN_OVEC(A6),A0  A0 points to name of console output 
         BSR.S   IO_OPEN         Open console (Get address of DCB) 
         BSR     IO_REQ          Perform output with DCB pointed at by A0 
         MOVE.L  (A7)+,A0        Restore working register 
         RTS 
* 
************************************************************************* 
* 
*  BUFF_IN and BUFF_OUT are two rudimentary input and output routines 
*  which input data from and output data to a buffer in RAM. These are 
*  used by DCB5 and DCB6, respectively. 
* 
BUFF_IN  LEA.L   12(A0),A1       A1 points to I/P buffer 
         MOVE.L  (A1),A2         A2 gets I/P pointer from buffer 
         MOVE.B  -(A2),D0        Read char from buffer and adjust A2 
         MOVE.L  A2,(A1)         Restore pointer in buffer 
         RTS 
* 
BUFF_OT  LEA.L   12(A0),A1       A1 points to O/P buffer 
         MOVE.L  4(A1),A2        A2 gets O/P pointer from buffer 
         MOVE.B  D0,(A2)+        Store char in buffer and adjust A2 
         MOVE.L  A2,(A1)         Restore pointer in buffer 
         RTS 
* 
************************************************************************* 
* 
*  Open - opens a DCB for input or output. IO_OPEN converts the 
*  name pointed at by A0 into the address of the DCB pointed at 
*  by A0. Bit 3 of D7 is set to zero if DCB not found 
* 
IO_OPEN  MOVEM.L  A1-A3/D0-D4,-(A7) Save working registers 
         LEA.L    FIRST(A6),A1   A1 points to first DCB in chain in RAM 
OPEN1    LEA.L    (A1),A2        A2 = temp copy of pointer to DCB 
         LEA.L    (A0),A3        A3 = temp copy of pointer to DCB name 
         MOVE.W   #7,D0          Up to 8 chars of DCB name to match 
OPEN2    MOVE.B   (A2)+,D4       Compare DCB name with string 
         CMP.B    (A3)+,D4 
         BNE.S    OPEN3          If no match try next DCB 
         DBRA     D0,OPEN2       Else repeat until all chars matched 
         LEA.L    (A1),A0        Success - move this DCB address to A0 
         BRA.S    OPEN4          and return 
OPEN3    EQU      *              Fail - calculate address of next DCB 
         MOVE.W   16(A1),D1      Get parameter block size of DCB 
         LEA.L    18(A1,D1.W),A1 A1 points to pointer to next DCB 
         MOVE.L   (A1),A1        A1 now points to next DCB 
         CMP.L    #0,A1          Test for end of DCB chain 
         BNE      OPEN1          If not end of chain then try next DCB 
         OR.B     #8,D7          Else set error flag and return 
OPEN4    MOVEM.L  (A7)+,A1-A3/D0-D4 Restore working registers 
         RTS 
* 
************************************************************************* 
* 
*  Exception vector table initialization routine 
*  All vectors not setup are loaded with uninitialized routine vector 
* 
X_SET   MOVE.W  #7,D0             Now clear the breakpoint table 
        LEA.L   BP_TAB(A6),A0     Point to table 
X_SET2  CLR.L   (A0)+             Clear an address entry 
        CLR.W   (A0)+             Clear the corresponding data 
        DBRA    D0,X_SET2         Repeat until all 8 cle
*  GO executes a program either from a supplied address or 
*  by using the data in the display frame 
GO       BSR     PARAM               Get entry address (if any) 
         TST.B   D7                  Test for error in input 
         BEQ.S   GO1                 If D7 zero then OK 
         LEA.L   ERMES1(PC),A4       Else point to error message, 
         BRA     PSTRING             print it and return 
GO1      TST.L   D0                  If no address entered then get 
        
         MOVE.L  D0,TSK_T+70(A6)     Else save address in display frame 
         MOVE.W  #$0700,TSK_T+68(A6) Store dummy status in frame 
************************************************************************* 
* 
X_UN    EQU     *                 Uninitialized exception vector routine 
        LEA.L   ERMES6(PC),A4     Point to error message 
        BSR     PSTRING           Display it 
        
        BRA     WARM              Abort 
* 
************************************************************************* 
* 
* 
*  COMTAB is the built-in command table. All entries are made up of 
*         a string length + number of characters to match + the string 
*         plus the address of the command relative to COMTAB 
* 
COMTAB   DC.B     4,4              JUMP <address> causes execution to 
         DC.B     'JUMP'           begin at <address> 
         DC.L     JUMP-COMTAB                                           
         
         DC.B     4,2              LOAD <string> loads S1/S2 records 
         DC.B     'LOAD'           from the host. <string> is sent to host 
         DC.L     LOAD-COMTAB 
         
         DC.B    4,2               GO <address> starts program execution 
         DC.B    'GO  '            at <address> and loads regs from TSK_T 
         DC.L    GO-COMTAB 
       
         DC.B    0,0 
* 
************************************************************************* 
* 
*  This is a list of the information needed to setup the DCBs 
* 
DCB_LST  EQU     * 
DCB1     DC.B    'CON_IN  '          Device name (8 bytes) 
         DC.L    CON_IN,ACIA_1       Address of driver routine, device 
         DC.W    2                   Number of words in parameter field 
DCB2     DC.B    'CON_OUT ' 
         DC.L    CON_OUT,ACIA_1 
         DC.W    2 
DCB3     DC.B    'AUX_IN  ' 
         DC.L    AUX_IN,ACIA_2 
         DC.W    2 
DCB4     DC.B    'AUX_OUT ' 
         DC.L    AUX_OUT,ACIA_2 
         DC.W    2 
DCB5     DC.B    'BUFF_IN ' 
         DC.L    BUFF_IN,BUFFER 
         DC.W    2 
DCB6     DC.B    'BUFF_OUT' 
         DC.L    BUFF_OT,BUFFER 
         DC.W    2 
* 
************************************************************************* 
* 
*  DCB structure 
* 
*              ----------------------- 
*       0 ->   | DCB  name           | 
*              |---------------------| 
*       8 ->   | Device driver       | 
*              |---------------------| 
*      12 ->   | Device address      | 
*              |---------------------| 
*      16 ->   |Size of param block  | 
*              |---------------------| --- 
*      18 ->   |      Status         |   | 
*              | logical  | physical |   | S 
*              |---------------------|   | 
*              .                     .   . 
*              |---------------------| --- 
*    18+S ->   | Pointer to next DCB | 
* 
**************************************************************************************
*  All strings and other fixed parameters here 
* 
BANNER   DC.B     'TSBUG 2 Version 23.07.86',0,0
MODIFY	 DC.B	  'Modified by Eugene A. Rockey Jr. Jan.05.2010',0,0
WHY      DC.B     'for use with the M68000 Minimal Computer Configuration',0,0 
WHERE    DC.B     'University of Louisville',0,0
ADDRE	 DC.B	  'CECS 525, www.cs.louisville.edu',0,0
CRLF     DC.B     CR,LF,'TS2MON >',0 
HEADER   DC.B     CR,LF,'S','1',0,0 
TAIL     DC.B     'S9  ',0,0 
MES1     DC.B     ' SR  =  ',0 
MES2     DC.B     ' PC  =  ',0 
MES2A    DC.B     ' SS  =  ',0 
MES3     DC.B     '  Data reg       Address reg',0,0 
MES4     DC.B     '        ',0,0 
MES8     DC.B     'Bus error   ',0,0 
MES9     DC.B     'Address error   ',0,0 
MES10    DC.B     'Illegal instruction ',0,0 
MES11    DC.B     'Breakpoint  ',0,0 
MES12    DC.B     'Trace  ',0 
REGNAME  DC.B     'D0D1D2D3D4D5D6D7' 
         DC.B     'A0A1A2A3A4A5A6A7' 
         DC.B     'SSSR' 
         DC.B     'PC  ',0 
ERMES1   DC.B     'Non-valid hexadecimal input  ',0 
ERMES2   DC.B     'Invalid command  ',0 
ERMES3   DC.B     'Loading error',0 
ERMES4   DC.B     'Table full  ',0,0 
ERMES5   DC.B     'Breakpoint not active   ',0,0 
ERMES6   DC.B     'Uninitialized exception ',0,0 
ERMES7   DC.B     ' Range error',0 
         END RESET 
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
