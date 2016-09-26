; C:\USERS\STUDENT\DESKTOP\PROJECT-2\CALCULATOR.C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J. Fondse
; #define ACIAC 0x8001
; #define ACIAD 0x8003
; #define RDRF 1
; #define TDRE 2
; #define MENU "+,-,*,/,q"
; #define PROMPT "Select:"
; #define INPUT "Input:"
; #define CR   0x0D
; #define LF   0x0A
; void reverse_string(char*, int);
; void to_string(int, char*);
; int to_int(unsigned char*);
; void display_menu(void);
; void getstring(unsigned char*);
; unsigned char getchar(void);
; void sendchar(unsigned char c);
; void sendmsg(unsigned int msga);
; void newline(void);
; main()
; {
       section   code
       xdef      _main
_main:
       link      A6,#-16
       movem.l   D2/D3/D4/D5/A2/A3,-(A7)
       lea       _sendmsg.L,A2
       lea       _newline.L,A3
; unsigned char selection;
; unsigned char input_one[4];
; unsigned char input_two[4];
; unsigned char s_result[7];
; int number_one;
; int number_two;
; int result;
; do {
main_1:
; display_menu();
       jsr       _display_menu
; selection = getchar();
       jsr       _getchar
       move.b    D0,D5
; sendchar(selection);
       and.l     #255,D5
       move.l    D5,-(A7)
       jsr       _sendchar
       addq.w    #4,A7
; newline();
       jsr       (A3)
; if (selection == 'q' || selection == 'Q')
       cmp.b     #113,D5
       beq.s     main_5
       cmp.b     #81,D5
       bne.s     main_3
main_5:
; {
; break;
       bra       main_2
main_3:
; }
; sendmsg(&INPUT);
       pea       @calcul~1_1.L
       jsr       (A2)
       addq.w    #4,A7
; getstring(input_one);
       pea       -16(A6)
       jsr       _getstring
       addq.w    #4,A7
; newline();
       jsr       (A3)
; sendmsg(&INPUT);
       pea       @calcul~1_1.L
       jsr       (A2)
       addq.w    #4,A7
; getstring(input_two);
       pea       -12(A6)
       jsr       _getstring
       addq.w    #4,A7
; newline();
       jsr       (A3)
; number_one = to_int(input_one);
       pea       -16(A6)
       jsr       _to_int
       addq.w    #4,A7
       move.l    D0,D4
; number_two = to_int(input_two);
       pea       -12(A6)
       jsr       _to_int
       addq.w    #4,A7
       move.l    D0,D3
; switch(selection)
       and.l     #255,D5
       cmp.l     #45,D5
       beq.s     main_9
       bhi.s     main_12
       cmp.l     #43,D5
       beq.s     main_8
       bhi       main_7
       cmp.l     #42,D5
       beq.s     main_10
       bra       main_7
main_12:
       cmp.l     #47,D5
       beq       main_11
       bra       main_7
main_8:
; {
; case '+':
; result = number_one + number_two;
	move.b   #1,D0
	move.l   d3,d1
	move.l   d4,d2
        trap     #0
        move.b   d1,d2
; break;
       bra       main_7
main_9:
; case '-':
; result = number_one - number_two;
        move.b   #2,D0
	move.l   d3,d1
	move.l   d4,d2
        trap     #0
        move.b   d1,d2
; break;
       bra.s     main_7
main_10:
; case '*':
; result = number_one * number_two;
       move.l    D4,-(A7)
       move.l    D3,-(A7)
       jsr       LMUL
       move.l    (A7),D0
       addq.w    #8,A7
       move.l    D0,D2
 	;move.b   #3,D0
	;move.l   d3,d1
	;move.l   d4,d2
        ;trap     #0
        ;move.b   d1,d2
; break;
       bra.s     main_7
main_11:
; case '/':
; result = number_one / number_two;
       move.l    D4,-(A7)
       move.l    D3,-(A7)
       jsr       LDIV
       move.l    (A7),D0
       addq.w    #8,A7
       move.l    D0,D2
       ;move.b   #4,D0
       ;move.l   d3,d1
       ;move.l   d4,d2
       ;trap     #0
       ;move.b   d1,d2
; break;
main_7:
; }
; to_string(result, s_result);
       pea       -8(A6)
       move.l    D2,-(A7)
       jsr       _to_string
       addq.w    #8,A7
; sendmsg(s_result);
       pea       -8(A6)
       jsr       (A2)
       addq.w    #4,A7
       bra       main_1
main_2:
; } while(1);
; return 0;
       clr.l     D0
       movem.l   (A7)+,D2/D3/D4/D5/A2/A3
       unlk      A6
       rts
; }
; void reverse_string(char* str, int length)
; {
       xdef      _reverse_string
_reverse_string:
       link      A6,#0
       movem.l   D2/D3,-(A7)
       move.l    8(A6),D2
; char* end = str + length - 1;
       move.l    D2,D0
       add.l     12(A6),D0
       subq.l    #1,D0
       move.l    D0,D3
; while(str < end)
reverse_string_1:
       cmp.l     D3,D2
       bhs       reverse_string_3
; {
; do {
; *str = *str^*end;
       move.l    D2,A0
       move.l    D3,A1
       move.b    (A1),D0
       eor.b     D0,(A0)
; *end = *str^*end;
       move.l    D2,A0
       move.b    (A0),D0
       move.l    D3,A0
       move.b    (A0),D1
       eor.b     D1,D0
       move.l    D3,A0
       move.b    D0,(A0)
; *str = *end^*str;
       move.l    D3,A0
       move.b    (A0),D0
       move.l    D2,A0
       move.b    (A0),D1
       eor.b     D1,D0
       move.l    D2,A0
       move.b    D0,(A0)
; } while(0);
; str++;
       addq.l    #1,D2
; end--;
       subq.l    #1,D3
       bra       reverse_string_1
reverse_string_3:
       movem.l   (A7)+,D2/D3
       unlk      A6
       rts
; }
; }
; void to_string(int input, char* result)
; {
       xdef      _to_string
_to_string:
       link      A6,#0
       movem.l   D2/D3/D4/D5/D6,-(A7)
       move.l    12(A6),D2
       move.l    8(A6),D3
; int negative_flag = 0;
       clr.l     D6
; int i = 0;
       clr.l     D4
; if(input == 0)
       tst.l     D3
       bne.s     to_string_1
; {
; result[0] = '0';
       move.l    D2,A0
       move.b    #48,(A0)
; result[1] = '\0';
       move.l    D2,A0
       clr.b     1(A0)
; return;
       bra       to_string_3
to_string_1:
; }
; if(input < 0)
       cmp.l     #0,D3
       bge.s     to_string_4
; {
; negative_flag = 1;
       moveq     #1,D6
; input = input * -1;
       move.l    D3,-(A7)
       pea       -1
       jsr       LMUL
       move.l    (A7),D3
       addq.w    #8,A7
to_string_4:
; }
; while(input != 0)
to_string_6:
       tst.l     D3
       beq       to_string_8
; {
; int rem = input % 10;
       move.l    D3,-(A7)
       pea       10
       jsr       LDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       move.l    D0,D5
; if(rem > 9)
       cmp.l     #9,D5
       ble.s     to_string_9
; {
; result[i++] = (rem - 10) + 'a';
       move.l    D5,D0
       sub.l     #10,D0
       add.l     #97,D0
       move.l    D2,A0
       move.l    D4,D1
       addq.l    #1,D4
       move.b    D0,0(A0,D1.L)
       bra.s     to_string_10
to_string_9:
; }
; else
; {
; result[i++] = rem + '0';
       move.l    D5,D0
       add.l     #48,D0
       move.l    D2,A0
       move.l    D4,D1
       addq.l    #1,D4
       move.b    D0,0(A0,D1.L)
to_string_10:
; }
; input = input / 10;
       move.l    D3,-(A7)
       pea       10
       jsr       LDIV
       move.l    (A7),D3
       addq.w    #8,A7
       bra       to_string_6
to_string_8:
; }
; if(negative_flag)
       tst.l     D6
       beq.s     to_string_11
; {
; result[i++] = '-';
       move.l    D2,A0
       move.l    D4,D0
       addq.l    #1,D4
       move.b    #45,0(A0,D0.L)
to_string_11:
; }
; result[i] = '\0';
       move.l    D2,A0
       clr.b     0(A0,D4.L)
; reverse_string(result, i);
       move.l    D4,-(A7)
       move.l    D2,-(A7)
       jsr       _reverse_string
       addq.w    #8,A7
to_string_3:
       movem.l   (A7)+,D2/D3/D4/D5/D6
       unlk      A6
       rts
; }
; int to_int(unsigned char* input)
; {
       xdef      _to_int
_to_int:
       link      A6,#0
       movem.l   D2/D3/D4/D5,-(A7)
       move.l    8(A6),D5
; int negative = 0;
       clr.l     D4
; int result = 0;
       clr.l     D2
; int i;
; if(input[0] == '-')
       move.l    D5,A0
       move.b    (A0),D0
       cmp.b     #45,D0
       bne.s     to_int_1
; {
; negative = 1;
       moveq     #1,D4
to_int_1:
; }
; for(i = negative; input[i] != '\0'; i++)
       move.l    D4,D3
to_int_3:
       move.l    D5,A0
       move.b    0(A0,D3.L),D0
       beq.s     to_int_5
; {
; result = result * 10 + input[i] - '0';
       move.l    D2,-(A7)
       pea       10
       jsr       LMUL
       move.l    (A7),D0
       addq.w    #8,A7
       move.l    D5,A0
       move.b    0(A0,D3.L),D1
       and.l     #255,D1
       add.l     D1,D0
       sub.l     #48,D0
       move.l    D0,D2
       addq.l    #1,D3
       bra       to_int_3
to_int_5:
; }
; if(negative)
       tst.l     D4
       beq.s     to_int_6
; {
; result = result * -1;
       move.l    D2,-(A7)
       pea       -1
       jsr       LMUL
       move.l    (A7),D2
       addq.w    #8,A7
to_int_6:
; }
; return result;
       move.l    D2,D0
       movem.l   (A7)+,D2/D3/D4/D5
       unlk      A6
       rts
; }
; void display_menu()
; {
       xdef      _display_menu
_display_menu:
; newline();
       jsr       _newline
; sendmsg(&MENU);
       pea       @calcul~1_2.L
       jsr       _sendmsg
       addq.w    #4,A7
; newline();
       jsr       _newline
; sendmsg(&PROMPT);
       pea       @calcul~1_3.L
       jsr       _sendmsg
       addq.w    #4,A7
       rts
; }
; void getstring(unsigned char* input_string)
; {
       xdef      _getstring
_getstring:
       link      A6,#0
       movem.l   D2/D3,-(A7)
; unsigned char temp = 0;
       clr.b     D2
; unsigned int string_length = 0;
       clr.l     D3
; while(1)
getstring_1:
; {
; temp = getchar();
       jsr       _getchar
       move.b    D0,D2
; if(temp == CR)
       cmp.b     #13,D2
       bne.s     getstring_4
; {
; break;
       bra.s     getstring_3
getstring_4:
; }
; sendchar(temp);
       and.l     #255,D2
       move.l    D2,-(A7)
       jsr       _sendchar
       addq.w    #4,A7
; input_string[string_length++] = temp;
       move.l    8(A6),A0
       move.l    D3,D0
       addq.l    #1,D3
       move.b    D2,0(A0,D0.L)
       bra       getstring_1
getstring_3:
; }
; input_string[string_length] = '\0';
       move.l    8(A6),A0
       clr.b     0(A0,D3.L)
       movem.l   (A7)+,D2/D3
       unlk      A6
       rts
; }
; //Subroutine to get a character typed into Hyperterminal
; unsigned char getchar()
; {
       xdef      _getchar
_getchar:
       link      A6,#-8
       move.l    D2,-(A7)
; unsigned char temp = 0;
       clr.b     D2
; unsigned char * const C = (unsigned char *) ACIAC;
       move.l    #32769,-8(A6)
; unsigned char * const D = (unsigned char *) ACIAD;
       move.l    #32771,-4(A6)
; while (temp == 0) {temp = *C & RDRF;}
getchar_1:
       tst.b     D2
       bne.s     getchar_3
       move.l    -8(A6),A0
       move.b    (A0),D0
       and.b     #1,D0
       move.b    D0,D2
       bra       getchar_1
getchar_3:
; temp = *D;
       move.l    -4(A6),A0
       move.b    (A0),D2
; return temp;
       move.b    D2,D0
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; //Subroutine to send a character to Hyperterminal
; void sendchar(unsigned char asciiout)
; {
       xdef      _sendchar
_sendchar:
       link      A6,#-4
       movem.l   D2/D3/D4,-(A7)
; unsigned char temp = 0;
       clr.b     D2
; unsigned char dummyread = 0;
       clr.b     -1(A6)
; unsigned char * const C = (unsigned char *) ACIAC;
       move.l    #32769,D3
; unsigned char * const D = (unsigned char *) ACIAD;
       move.l    #32771,D4
; temp = *C & RDRF;
       move.l    D3,A0
       move.b    (A0),D0
       and.b     #1,D0
       move.b    D0,D2
; while (temp != 0)
sendchar_1:
       tst.b     D2
       beq.s     sendchar_3
; {
; dummyread = *D;
       move.l    D4,A0
       move.b    (A0),-1(A6)
; temp = *C & RDRF;
       move.l    D3,A0
       move.b    (A0),D0
       and.b     #1,D0
       move.b    D0,D2
       bra       sendchar_1
sendchar_3:
; }
; while (temp == 0) {temp = *C & TDRE;}
sendchar_4:
       tst.b     D2
       bne.s     sendchar_6
       move.l    D3,A0
       move.b    (A0),D0
       and.b     #2,D0
       move.b    D0,D2
       bra       sendchar_4
sendchar_6:
; *D = asciiout;
       move.l    D4,A0
       move.b    11(A6),(A0)
       movem.l   (A7)+,D2/D3/D4
       unlk      A6
       rts
; }
; //Subroutine to send a message string to Hyperterminal
; void sendmsg(unsigned int msg)
; {
       xdef      _sendmsg
_sendmsg:
       link      A6,#0
       movem.l   D2/D3,-(A7)
; unsigned char * strptr = (unsigned char *) msg;
       move.l    8(A6),D3
; unsigned char ASCII = *strptr;
       move.l    D3,A0
       move.b    (A0),D2
; while (ASCII != 0)
sendmsg_1:
       tst.b     D2
       beq.s     sendmsg_3
; {
; sendchar(ASCII);
       and.l     #255,D2
       move.l    D2,-(A7)
       jsr       _sendchar
       addq.w    #4,A7
; strptr = strptr + 1;
       addq.l    #1,D3
; ASCII = *strptr;
       move.l    D3,A0
       move.b    (A0),D2
       bra       sendmsg_1
sendmsg_3:
       movem.l   (A7)+,D2/D3
       unlk      A6
       rts
; }
; }
; //Subroutine to start a new line in Hyperterminal
; void newline()
; {
       xdef      _newline
_newline:
; sendchar(LF);
       pea       10
       jsr       _sendchar
       addq.w    #4,A7
; sendchar(CR);
       pea       13
       jsr       _sendchar
       addq.w    #4,A7
       rts
; }
       section   const
@calcul~1_1:
       dc.b      73,110,112,117,116,58,0
@calcul~1_2:
       dc.b      43,44,45,44,42,44,47,44,113,0
@calcul~1_3:
       dc.b      83,101,108,101,99,116,58,0
       xref      LDIV
       xref      LMUL
