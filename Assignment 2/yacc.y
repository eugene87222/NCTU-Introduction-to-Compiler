%{
#include <stdio.h>
#include <stdlib.h>

extern int linenum;             /* declared in lex.l */
extern FILE *yyin;              /* declared by lex */
extern char *yytext;            /* declared by lex */
extern char buf[256];           /* declared in lex.l */
%}

%token SEMICOLON COMMA
%token LBRACKET RBRACKET LBRACE RBRACE LPAREN RPAREN
%token ID
%token INTEGER FLOATING SCIENTIFIC STRING_
%token CONST BOOL INT FLOAT DOUBLE STRING
%token VOID WHILE IF ELSE READ DO TRUE FALSE FOR PRINT
%token BOOLEAN CONTINUE BREAK RETURN
	
%token ASSIGN

%left OR_OP
%left AND_OP
%right NOT
%left LT_OP LE_OP EQ_OP GE_OP GT_OP NE_OP
%left PLUS MINUS
%left STAR SLASH MOD

%%

program
	: other func_def
	| func_def
	| other func_def anything
	| func_def anything
	;

anything
	: decl_and_def
	| anything decl_and_def
	;
	
decl_and_def
	: func_var_decl
	| func_def
	;

other
	: func_var_decl
	| other func_var_decl
	;
	
func_var_decl
	: func_decl
	| var_decl
	;

func_decl
	: var_type ID LPAREN arguments RPAREN SEMICOLON
	| var_type ID LPAREN RPAREN SEMICOLON
	| VOID ID LPAREN arguments RPAREN SEMICOLON
	| VOID ID LPAREN RPAREN SEMICOLON
	;

func_def
	: var_type ID LPAREN arguments RPAREN many_compound_statement
	| var_type ID LPAREN RPAREN many_compound_statement
	| VOID ID LPAREN arguments RPAREN many_compound_statement
	| VOID ID LPAREN RPAREN many_compound_statement
	;

arguments
	: var_type ID
	| var_type ID array_bracket
	| arguments COMMA var_type ID
	| arguments COMMA var_type ID array_bracket
	;
	
var_decl
    : CONST var_type var_list_with_init SEMICOLON
    | var_type var_list SEMICOLON
    ;
	
var_type
    : BOOL
    | INT
    | FLOAT
    | DOUBLE
    | STRING
    ;

var_list_with_init
	: ID ASSIGN value
	| var_list_with_init COMMA ID ASSIGN value
	;

var_list
    : var
	| var_list COMMA var
    ;
	
var
	: ID
	| ID ASSIGN expr
	| ID array_bracket
	| ID array_bracket ASSIGN LBRACE RBRACE
	| ID array_bracket ASSIGN LBRACE value_list RBRACE
	;
	
array_bracket
	: single_bracket
	| array_bracket single_bracket
	;
	
single_bracket
	: LBRACKET INTEGER RBRACKET
	
value_list
	: expr
	| value_list COMMA expr
	;

value
	: INTEGER
	| FLOATING
	| SCIENTIFIC
	| STRING_
	| TRUE
	| FALSE
	;

many_statement
	: statement
	| many_statement statement
	
statement
	: many_compound_statement
	| simple_many_statement
	| conditional
	| while
	| for
	| jump
	;
	
for
	: FOR LPAREN many_for_component RPAREN LBRACE many_statement RBRACE
	| FOR LPAREN many_for_component RPAREN LBRACE RBRACE
	;

many_for_component
	: many_expr_for SEMICOLON many_expr_for SEMICOLON many_expr_for
	| SEMICOLON many_expr_for SEMICOLON many_expr_for
	| many_expr_for SEMICOLON SEMICOLON many_expr_for
	| many_expr_for SEMICOLON many_expr_for SEMICOLON
	| many_expr_for SEMICOLON SEMICOLON
	| SEMICOLON many_expr_for SEMICOLON
	| SEMICOLON SEMICOLON many_expr_for
	| SEMICOLON SEMICOLON
	;

for_component
	: expr
	| expr ASSIGN expr
	;
	
many_expr_for
	: for_component
	| many_expr_for COMMA for_component

while
	: while_loop
	| do_while_loop
	;

while_loop
	: WHILE LPAREN expr RPAREN LBRACE many_statement RBRACE
	| WHILE LPAREN expr RPAREN LBRACE RBRACE
	;
	
do_while_loop
	: DO LBRACE many_statement RBRACE WHILE LPAREN expr RPAREN SEMICOLON
	| DO LBRACE RBRACE WHILE LPAREN expr RPAREN SEMICOLON
	;
	
conditional
	: if_statement else_statement
	| if_statement
	;

if_statement
	: IF LPAREN expr RPAREN LBRACE many_statement RBRACE
	| IF LPAREN expr RPAREN LBRACE RBRACE
	;

else_statement
	: ELSE LBRACE many_statement RBRACE
	| ELSE LBRACE RBRACE
	;
	
expr
	: NOT expr
	| expr PLUS expr
	| expr MINUS expr
	| expr STAR expr
	| expr SLASH expr
	| expr MOD expr
	| MINUS expr %prec STAR
	| LPAREN expr RPAREN
	| expr OR_OP expr
	| expr AND_OP expr
	| expr LT_OP expr
	| expr LE_OP expr
	| expr EQ_OP expr
	| expr GE_OP expr
	| expr GT_OP expr
	| expr NE_OP expr
	| value
	| variable
	| func_invoke
	;

variable
	: ID
	| ID array_bracket_expr
	;

array_bracket_expr
	: single_bracket_expr
	| array_bracket_expr single_bracket_expr
	;
	
single_bracket_expr
	: LBRACKET expr RBRACKET

func_invoke
	: ID LPAREN many_expr RPAREN
	| ID LPAREN RPAREN
	;

many_expr
	: expr
	| many_expr COMMA expr
	;

many_compound_statement
	: LBRACE many_statement RBRACE
	| LBRACE RBRACE
	;

simple_many_statement
	: simple_statement
	;
		
simple_statement
	: var_decl
	| variable ASSIGN expr SEMICOLON
	| READ variable SEMICOLON
	| PRINT expr SEMICOLON
	| func_invoke SEMICOLON
	;

jump
	: RETURN expr SEMICOLON
	| BREAK SEMICOLON
	| CONTINUE SEMICOLON
	;
	
%%

int yyerror( char *msg )
{
    fprintf( stderr, "\n|--------------------------------------------------------------------------\n" );
    fprintf( stderr, "| Error found in Line #%d: %s\n", linenum, buf );
    fprintf( stderr, "|\n" );
    fprintf( stderr, "| Unmatched token: %s\n", yytext );
    fprintf( stderr, "|--------------------------------------------------------------------------\n" );
    exit(-1);
}

int main( int argc, char **argv )
{
    if( argc != 2 ) {
        fprintf( stdout, "Usage:  ./parser  [filename]\n");
        exit(0);
    }

    FILE *fp = fopen( argv[1], "r" );

    if( fp == NULL )  {
        fprintf( stdout, "Open  file  error\n" );
        exit(-1);
    }

    yyin = fp;
    yyparse();

    fprintf( stdout, "\n" );
    fprintf( stdout, "|--------------------------------|\n" );
    fprintf( stdout, "|  There is no syntactic error!  |\n" );
    fprintf( stdout, "|--------------------------------|\n" );
    exit(0);
}
