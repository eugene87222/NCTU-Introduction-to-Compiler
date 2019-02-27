%{
#define LIST                { strncat(buf, yytext, sizeof(buf) - strlen(buf) - 1); }
#define token(t)            { LIST; if (Opt_Token) printf("<\"%s\">\n", t); }
#define tokenString(t, s)   { LIST; if (Opt_Token) printf("<%s:%s>\n", t, s); }
#define MAX_LINE_LENGTH 257
#define MAX_ID_LENGTH 257
#define MAX_ID_NUM 1024
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
id      {letter}({letter}|{digit})*

%X COMMENT STRING
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
    BEGIN STRING;
    LIST;
    strcpy(str, "\0");
}
<STRING>\\\" {
    LIST;
    strcat(str, "\"");
}
<STRING>\\\\ {
    LIST;
    strcat(str, "\\");  
}
<STRING>\" {
    BEGIN INITIAL;
    tokenString("string", str);
}
<STRING>\n {
    fprintf(stderr, "Error at line %d: %s\n", linenum, yytext);
    exit(1);
}
<STRING>. {
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

"["|"]"|[,;{}()] {
    // Delimeter
    tokenString("delim", yytext); 
}

[-\+\*/%=<>!]|<=|!=|>=|==|&&|"||" {
    // Arithmetic, relational, logical opt
    token(yytext); 
}

while|do|if|else|true|false |
for|int|print|const|read|boolean|bool |
void|float|double|string|continue|break|return {
    // Keyword
    tokenString("KW", yytext);
}

{integer} {
    // Integer
    tokenString("integer", yytext);
}

{float} {
    // Floating-point
    tokenString("float", yytext);
}

{real}[eE][-+]?{digit}* {
    // scientific
    tokenString("scientific", yytext);
}

{id} {
    // Identifier
    tokenString("id", yytext);
    NODE *node = searchNode();
    if(node) node->freq += 1;
    else insertNode();
}

" " {
    // Only concatenate to the buffer
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

int main( int argc, char **argv ) {
    if (argc >= 2) {
        yyin = fopen( argv[1], "r" );
        if ( NULL == yyin ) {
            fprintf( stderr, "Cannot open: %s\n", argv[1] );
            exit(-1);
        }
    }
    else yyin = stdin;

    yylex();

    if (Opt_Statistic) {
        // Print frequency table
        printf("frequencies of identifiers:\n");
        printList();
    }
    exit(0);
}

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
