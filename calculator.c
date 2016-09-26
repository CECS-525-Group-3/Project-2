#define ACIAC 0x8001
#define ACIAD 0x8003
#define RDRF 1
#define TDRE 2
#define MENU "+,-,*,/,q"
#define PROMPT "Select:"
#define INPUT "Input:"
#define CR   0x0D
#define LF   0x0A

void reverse_string(char*, int);
void to_string(int, char*);
int to_int(unsigned char*);
void display_menu(void);
void getstring(unsigned char*);
unsigned char getchar(void);
void sendchar(unsigned char c);
void sendmsg(unsigned int msga);
void newline(void);

main()
{
    unsigned char selection;
    unsigned char input_one[4];
    unsigned char input_two[4];
    unsigned char s_result[7];

    int number_one;
    int number_two;
    int result;

    do {

        display_menu();
        selection = getchar();
        sendchar(selection);
        newline();

        if (selection == 'q' || selection == 'Q')
        {
            break;
        }

        sendmsg(&INPUT);
        getstring(input_one);
        newline();

        sendmsg(&INPUT);
        getstring(input_two);
        newline();

        number_one = to_int(input_one);
        number_two = to_int(input_two);

        switch(selection)
        {
            case '+':
                result = number_one + number_two;
                break;
            case '-':
                result = number_one - number_two;
                break;
            case '*':
                result = number_one * number_two;
                break;
            case '/':
                result = number_one / number_two;
                break;
        }
        to_string(result, s_result);
        sendmsg(s_result);
	} while(1);

	return 0;
}

void reverse_string(char* str, int length)
{
    char* end = str + length - 1;

    while(str < end)
    {
        do {
            *str = *str^*end;
            *end = *str^*end;
            *str = *end^*str;
        } while(0);
        str++;
        end--;
    }
}

void to_string(int input, char* result)
{
    int negative_flag = 0;
    int i = 0;

    if(input == 0)
    {
        result[0] = '0';
        result[1] = '\0';
        return;
    }

    if(input < 0)
    {
        negative_flag = 1;
        input = input * -1;
    }

    while(input != 0)
    {
        int rem = input % 10;
        if(rem > 9)
        {
            result[i++] = (rem - 10) + 'a';
        }
        else
        {
            result[i++] = rem + '0';
        }
        input = input / 10;
    }

    if(negative_flag)
    {
        result[i++] = '-';
    }

    result[i] = '\0';

    reverse_string(result, i);
}

int to_int(unsigned char* input)
{
    int negative = 0;
    int result = 0;
    int i;

    if(input[0] == '-')
    {
        negative = 1;
    }

    for(i = negative; input[i] != '\0'; i++)
    {
        result = result * 10 + input[i] - '0';
    }

    if(negative)
    {
        result = result * -1;
    }

    return result;
}

void display_menu()
{
    newline();
    sendmsg(&MENU);
    newline();
    sendmsg(&PROMPT);
}

void getstring(unsigned char* input_string)
{
    unsigned char temp = 0;
    unsigned int string_length = 0;

    while(1)
    {
        temp = getchar();
        if(temp == CR)
        {
            break;
        }
        sendchar(temp);
        input_string[string_length++] = temp;
    }
    input_string[string_length] = '\0';
}

//Subroutine to get a character typed into Hyperterminal
unsigned char getchar()
{
    unsigned char temp = 0;
    unsigned char * const C = (unsigned char *) ACIAC;
    unsigned char * const D = (unsigned char *) ACIAD;
    while (temp == 0) {temp = *C & RDRF;}
    temp = *D;
    return temp;
}

//Subroutine to send a character to Hyperterminal
void sendchar(unsigned char asciiout)
{
    unsigned char temp = 0;
    unsigned char dummyread = 0;
    unsigned char * const C = (unsigned char *) ACIAC;
    unsigned char * const D = (unsigned char *) ACIAD;
    temp = *C & RDRF;
    while (temp != 0)
    {
        dummyread = *D;
        temp = *C & RDRF;
    }
    while (temp == 0) {temp = *C & TDRE;}
	*D = asciiout;
}

//Subroutine to send a message string to Hyperterminal
void sendmsg(unsigned int msg)
{
    unsigned char * strptr = (unsigned char *) msg;
	unsigned char ASCII = *strptr;
	while (ASCII != 0)
	{
	   sendchar(ASCII);
	   strptr = strptr + 1;
	   ASCII = *strptr;
	}
}

//Subroutine to start a new line in Hyperterminal
void newline()
{
    sendchar(LF);
    sendchar(CR);
}