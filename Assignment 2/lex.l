%{
#include <string.h>
#include "y.tab.h"

#define MAX_LINE_LENGTH 257
#define MAX_ID_LENGTH 257
#define MAX_STRING_LENGTH 257
#define LIST                strncat(buf, yytext, MAX_LINE_LENGTH)
#define token(t)            {LIST; if (Opt_Token) printf("<\"%s\">\n", t); }
#define tokenInteger(t, i)  {LIST; if (Opt_Token) printf("<%s:%d>\n", t, i);}
#define tokenString(t, s)   {LIST; if (Opt_Token) printf("<%s:%s>\n", t, s);}
int Opt_Source = 1;
int Opt_Token = 1;
int Opt_Statistic = 1;
int linenum = 1;
char buf[MAX_LINE_LENGTH];
char str[MAX_LINE_LENGTH];
typedef struct node {
    char id[MAX_ID_LENGTH];
    int freq;
    struct node *next;
}NODE;
NODE *first_node = NULL;

NODE* searchNode();
void insertNode();
void printList();

%}

digit   [0-9]
letter  [a-zA-Z]
integer 0|[1-9]{digit}*
float   {digit}+\.{digit}+
real    (0*{integer})|{float}
id      ({letter}|_)({letter}|{digit}|_)*

%X COMMENT STR
%X PRAGMA PRAGMA_DONE PRAGMA_CMT PRAGMA_END

%%
<INITIAL>"/*" {BEGIN COMMENT; LIST;}
<COMMENT>. LIST;
<COMMENT>\n {
    LIST;
    if (Opt_Source)
        printf("%d:%s\n", linenum, buf);
    ++linenum;
    buf[0] = '\0';
}
<COMMENT>"*/" {BEGIN INITIAL; LIST;}

<INITIAL>\" {
    BEGIN STR;
    LIST;
    strcpy(str, "\0");
}
<STR>\\\" {
    LIST;
    strcat(str, "\"");
}
<STR>\\\\ {
    LIST;
    strcat(str, "\\");  
}
<STR>\" {
    BEGIN INITIAL;
    tokenString("string", str);
	return(STRING_);
}
<STR>\n {
    fprintf(stderr, "Error at line %d: %s\n", linenum, yytext);
    exit(1);
}
<STR>. {
    LIST;
    strcat(str, yytext);  
}

<INITIAL>^"#pragma"(\ +)"source"(\ +)"on"     {BEGIN PRAGMA_DONE; LIST; Opt_Source = 1;}
<INITIAL>^"#pragma"(\ +)"source"(\ +)"off"    {BEGIN PRAGMA_DONE; LIST; Opt_Source = 0;}
<INITIAL>^"#pragma"(\ +)"token"(\ +)"on"      {BEGIN PRAGMA_DONE; LIST; Opt_Token = 1;}
<INITIAL>^"#pragma"(\ +)"token"(\ +)"off"     {BEGIN PRAGMA_DONE; LIST; Opt_Token = 0;}
<INITIAL>^"#pragma"(\ +)"statistic"(\ +)"on"  {BEGIN PRAGMA_DONE; LIST; Opt_Statistic = 1;}
<INITIAL>^"#pragma"(\ +)"statistic"(\ +)"off" {BEGIN PRAGMA_DONE; LIST; Opt_Statistic = 0;}

<PRAGMA_DONE>\ *    |
<PRAGMA_DONE>"//".* |
<PRAGMA_END>"//".*  |
<PRAGMA_CMT>. LIST;

<PRAGMA_DONE>"/*" {BEGIN PRAGMA_CMT; LIST;}

<PRAGMA_DONE>\n |
<PRAGMA_END>\n {
    BEGIN INITIAL;
    LIST;
    if (Opt_Source)
        printf("%d:%s\n", linenum, buf);
    ++linenum;
    buf[0] = '\0';
}

<PRAGMA_DONE>. |
<PRAGMA_END>. {
    fprintf(stderr, "Error at line %d: %s\n", linenum, yytext);
    exit(1);
}
<PRAGMA_CMT>\n {
    BEGIN COMMENT;
    LIST;
    if (Opt_Source)
        printf("%d:%s\n", linenum, buf);
    ++linenum;
    buf[0] = '\0';
}
<PRAGMA_CMT>"*/" {BEGIN PRAGMA_END; LIST;}
<PRAGMA_END>"/*" {BEGIN PRAGMA_CMT; LIST;}

"//".* {
    LIST;
}

; {
	// semicolon
    tokenString("delim", yytext);
	return(SEMICOLON);
}

, {
	// comma
    tokenString("delim", yytext);
	return(COMMA);
}

\[ {
	// left bracker
    tokenString("delim", yytext);
	return(LBRACKET);
}

\] {
	// right bracker
    tokenString("delim", yytext);
	return(RBRACKET);
}

\{ {
	// left brace
    tokenString("delim", yytext);
	return(LBRACE);
}

\} {
	// right brace
    tokenString("delim", yytext);
	return(RBRACE);
}

\( {
    // left parentheses
    tokenString("delim", yytext); 
	return(LPAREN);
}

\) {
    // right parentheses
    tokenString("delim", yytext); 
	return(RPAREN);
}

= {
	// assign
	token(yytext); 
	return(ASSIGN);
}

- {
	token(yytext);
	return(MINUS);
}

\+ {
	token(yytext);
	return(PLUS);
}

\* {
	token(yytext);
	return(STAR);
}

\/ {
	token(yytext);
	return(SLASH);
}

! {
	token(yytext);
	return(NOT);
}

> {
	token(yytext);
	return(GT_OP);
}

\< {
	token(yytext);
	return(LT_OP);
}

% {
	token(yytext);
	return(MOD);
}

\<= {
    token(yytext);
	return(LE_OP);
}

!= {
    token(yytext); 
	return(NE_OP);
}

>= {
    token(yytext); 
	return(GE_OP);
}

== {
    token(yytext); 
	return(EQ_OP);
}

&& {
    token(yytext); 
	return(AND_OP);
}

"||" {
    token(yytext); 
	return(OR_OP);
}

while|do|if|else|true|false |
for|int|print|const|read|boolean|bool |
void|float|double|string|continue|break|return {
    // Keyword
    tokenString("KW", yytext);
	if(!strcmp(yytext, "read")) return(READ);
    else if(!strcmp(yytext, "boolean")) return(BOOLEAN);
    else if(!strcmp(yytext, "while")) return(WHILE);
    else if(!strcmp(yytext, "do")) return(DO);
    else if(!strcmp(yytext, "if")) return(IF);
    else if(!strcmp(yytext, "else")) return(ELSE);
    else if(!strcmp(yytext, "true")) return(TRUE);
    else if(!strcmp(yytext, "false")) return(FALSE);
    else if(!strcmp(yytext, "for")) return(FOR);
    else if(!strcmp(yytext, "const")) return(CONST);
    else if(!strcmp(yytext, "int")) return(INT);
    else if(!strcmp(yytext, "print")) return(PRINT);
    else if(!strcmp(yytext, "bool")) return(BOOL);
    else if(!strcmp(yytext, "void")) return(VOID);
    else if(!strcmp(yytext, "float")) return(FLOAT);
    else if(!strcmp(yytext, "double")) return(DOUBLE);
    else if(!strcmp(yytext, "string")) return(STRING);
    else if(!strcmp(yytext, "continue")) return(CONTINUE);
    else if(!strcmp(yytext, "break")) return(BREAK);
    else if(!strcmp(yytext, "return")) return(RETURN); 
}

{integer} {
    // Integer
    tokenString("integer", yytext);
	return(INTEGER);
}

{float} {
    // Floating-point
    tokenString("float", yytext);
	return(FLOATING);
}

{real}[eE][-+]?{digit}* {
    // scientific
    tokenString("scientific", yytext);
	return(SCIENTIFIC);
}

{id} {
    // Identifier
    tokenString("id", yytext);
    NODE *node = searchNode();
    if(node) node->freq += 1;
    else insertNode();
	return(ID);
}

" " {
    // Only concatenate to the buffer
    LIST;
}

\t {
    LIST;
}

\n {
    LIST;
    if (Opt_Source)
        printf("%d:%s\n", linenum, buf);
    ++linenum;
    buf[0] = '\0';
}

. { // Unrecognized character
    fprintf(stderr, "Error at line %d: %s\n", linenum, yytext);
    exit(1);
}

%%

NODE* searchNode() {
    NODE *node = first_node;
    while(node != NULL) {
        if(strcmp(node->id, yytext) == 0) return node;
        else node = node->next;
    }
    return NULL;
}

void insertNode() {
    NODE *newnode;
    newnode = malloc(sizeof(NODE));
    strcpy(newnode->id, yytext);
    newnode->freq = 1;
    newnode->next = NULL;
    if(first_node == NULL) {
        first_node = newnode;
        return;
    }
    NODE *tail = first_node;
    while(tail->next != NULL) tail = tail->next;
    tail->next = newnode;
}

void printList() {
    NODE *node = first_node;
    while(node != NULL) {
        printf("%s\t%d\n", node->id, node->freq);
        node = node->next;
    }
}
