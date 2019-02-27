%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int linenum;
extern FILE *yyin;
extern char *yytext;
extern char buf[256];
extern int level;
extern int Opt_Symbol;

int yylex();
int yyerror( char *msg );

char *func_ = "function";
char *para_ = "parameter";
char *var_ = "variable";
char *const_ = "constant";

struct dim_list{
    char *size;
    struct dim_list *next;
};
struct dim_list *dim_head = NULL;
struct dim_list *dim_end = NULL;
void add_dim(char *size);

struct const_var_list{
    char *name;
    char *value;
    struct const_var_list *next;
};
struct const_var_list *const_var_head = NULL;
struct const_var_list *const_var_end = NULL;
void add_const_var(char *name, char *value);
void free_const_var_list();

struct var_list{
    char *name;
    struct dim_list *dim;
    struct var_list *next;
};
struct var_list *var_head = NULL;
struct var_list *var_end = NULL;
void add_var(char *name, struct dim_list *dim);
void free_var_list();

struct para_list{
    char *name;
    char *type;
    struct dim_list *dim;
    struct para_list *next;
};
struct para_list *para_head = NULL;
struct para_list *para_end = NULL;
void add_para(char *name, char *type, struct dim_list *dim);

struct entry_list{
    int linenum;
    char *name;
    char *kind;
    int level;
    char *type;
    struct para_list *para;
    struct dim_list *dim;
    char *const_value;
    int is_func_def;
    struct entry_list *next;
};
struct entry_list *entry_head;
struct entry_list *entry_end;
void add_entry(int linenum, char *name, char *kind, int level, char *type, 
            struct para_list *para, struct dim_list *dim, char *const_value, int is_func_def);
void pop_entry(int level, int print);

%}

%token  ID
%token  INT_CONST
%token  FLOAT_CONST
%token  SCIENTIFIC
%token  STR_CONST

%token  LE_OP
%token  NE_OP
%token  GE_OP
%token  EQ_OP
%token  AND_OP
%token  OR_OP

%token  READ
%token  BOOLEAN
%token  WHILE
%token  DO
%token  IF
%token  ELSE
%token  TRUE
%token  FALSE
%token  FOR
%token  INT
%token  PRINT
%token  BOOL
%token  VOID
%token  FLOAT
%token  DOUBLE
%token  STRING
%token  CONTINUE
%token  BREAK
%token  RETURN
%token  CONST

%token  L_PAREN
%token  R_PAREN
%token  COMMA
%token  SEMICOLON
%token  ML_BRACE
%token  MR_BRACE
%token  L_BRACE
%token  R_BRACE
%token  ADD_OP
%token  SUB_OP
%token  MUL_OP
%token  DIV_OP
%token  MOD_OP
%token  ASSIGN_OP
%token  LT_OP
%token  GT_OP
%token  NOT_OP

%union {
    char *stringValue;
}

%type <stringValue> scalar_type
%type <stringValue> ID
%type <stringValue> array_decl
%type <stringValue> INT BOOL STRING FLOAT DOUBLE VOID
%type <stringValue> INT_CONST FLOAT_CONST SCIENTIFIC STR_CONST
%type <stringValue> TRUE FALSE
%type <stringValue> literal_const

%start program
%%

program 
    : decl_list funct_def decl_and_def_list { pop_entry(0, 1*Opt_Symbol); }
    ;

decl_list
    : decl_list var_decl
    | decl_list const_decl
    | decl_list funct_decl
    |
    ;

decl_and_def_list 
    : decl_and_def_list var_decl
    | decl_and_def_list const_decl
    | decl_and_def_list funct_decl
    | decl_and_def_list funct_def
    | 
    ;

funct_def
    : scalar_type ID L_PAREN R_PAREN compound_statement
    {
        add_entry(linenum, $2, func_, level, $1, para_head, NULL, NULL, 1);
        para_head = NULL;
    }
    | scalar_type ID L_PAREN parameter_list R_PAREN  compound_statement
    {
        add_entry(linenum, $2, func_, level, $1, para_head, NULL, NULL, 1);
        para_head = NULL;
    }
    | VOID ID L_PAREN R_PAREN compound_statement
    {
        add_entry(linenum, $2, func_, level, $1, para_head, NULL, NULL, 1);
        para_head = NULL;
    }
    | VOID ID L_PAREN parameter_list R_PAREN compound_statement
    {
        add_entry(linenum, $2, func_, level, $1, para_head, NULL, NULL, 1);
        para_head = NULL;
    }
    ;

funct_decl 
    : scalar_type ID L_PAREN R_PAREN SEMICOLON
    {
        add_entry(linenum, $2, func_, level, $1, para_head, NULL, NULL, 0); para_head = NULL;
    }
    | scalar_type ID L_PAREN parameter_list R_PAREN SEMICOLON
    {
        add_entry(linenum, $2, func_, level, $1, para_head, NULL, NULL, 0); para_head = NULL;
        pop_entry(level+1, 0);
    }
    | VOID ID L_PAREN R_PAREN SEMICOLON
    {
        add_entry(linenum, $2, func_, level, $1, para_head, NULL, NULL, 0); para_head = NULL;
    }
    | VOID ID L_PAREN parameter_list R_PAREN SEMICOLON
    {
        add_entry(linenum, $2, func_, level, $1, para_head, NULL, NULL, 0); para_head = NULL;
        pop_entry(level+1, 0);
    }
    ;

parameter_list 
    : parameter_list COMMA scalar_type ID         
    { 
        add_para($4, $3, NULL); 
        add_entry(linenum, $4, para_, level+1, $3, NULL, NULL, NULL, 0);
    }
    | parameter_list COMMA scalar_type array_decl
    { 
        add_para($4, $3, dim_head); 
        add_entry(linenum, $4, para_, level+1, $3, NULL, dim_head, NULL, 0); dim_head=NULL;
    }
    | scalar_type array_decl                      
    { 
        add_para($2, $1, dim_head); 
        add_entry(linenum, $2, para_, level+1, $1, NULL, dim_head, NULL, 0); dim_head=NULL; 
    }
    | scalar_type ID                              
    { 
        add_para($2, $1, NULL); 
        add_entry(linenum, $2, para_, level+1, $1, NULL, NULL, NULL, 0);
    }
    ;

var_decl 
    : scalar_type identifier_list SEMICOLON
    {
        struct var_list *current = var_head;
        while(current != NULL){
            add_entry(linenum, current->name, var_, level, $1, NULL, current->dim, NULL, 0);
            current = current->next;
        }
        free_var_list();
        dim_head = NULL;
    }
    ;

identifier_list 
    : identifier_list COMMA ID                                 { add_var($3, NULL); }
    | identifier_list COMMA ID ASSIGN_OP logical_expression    { add_var($3, NULL); }
    | identifier_list COMMA array_decl ASSIGN_OP initial_array { add_var($3, dim_head); dim_head = NULL; }
    | identifier_list COMMA array_decl   { add_var($3, dim_head); dim_head = NULL; }
    | array_decl ASSIGN_OP initial_array { add_var($1, dim_head); dim_head = NULL; }
    | array_decl                         { add_var($1, dim_head); dim_head = NULL; }
    | ID ASSIGN_OP logical_expression    { add_var($1, NULL); }
    | ID                                 { add_var($1, NULL); }
    ;

initial_array
    : L_BRACE literal_list R_BRACE
    ;

literal_list 
    : literal_list COMMA logical_expression
    | logical_expression
    | 
    ;

const_decl 
    : CONST scalar_type const_list SEMICOLON
    {
        struct const_var_list *current = const_var_head;
        while(current != NULL){
            add_entry(linenum, current->name, const_, level, $2, NULL, NULL, current->value, 0);
            current = current->next;
        }
        free_const_var_list();
    }
    ;

const_list 
    : const_list COMMA ID ASSIGN_OP literal_const { add_const_var($3, $5); }
    | ID ASSIGN_OP literal_const                  { add_const_var($1, $3); }
    ;

array_decl 
    : ID dim { $$ = $1; }
    ;

dim 
    : dim ML_BRACE INT_CONST MR_BRACE { add_dim($3); }
    | ML_BRACE INT_CONST MR_BRACE     { add_dim($2); }
    ;

compound_statement 
    : L_BRACE var_const_stmt_list R_BRACE { pop_entry(level+1, 1*Opt_Symbol); }
    ;

var_const_stmt_list 
    : var_const_stmt_list statement 
    | var_const_stmt_list var_decl
    | var_const_stmt_list const_decl
    |
    ;

statement 
    : compound_statement
    | simple_statement
    | conditional_statement
    | while_statement
    | for_statement
    | function_invoke_statement
    | jump_statement
    ;     

simple_statement 
    : variable_reference ASSIGN_OP logical_expression SEMICOLON
    | PRINT logical_expression SEMICOLON
    | READ variable_reference SEMICOLON
    ;

conditional_statement 
    : IF L_PAREN logical_expression R_PAREN compound_statement
    | IF L_PAREN logical_expression R_PAREN compound_statement ELSE compound_statement
    ;

while_statement 
    : WHILE L_PAREN logical_expression R_PAREN compound_statement
    | DO compound_statement WHILE L_PAREN logical_expression R_PAREN SEMICOLON
    ;

for_statement 
    : FOR L_PAREN initial_expression_list SEMICOLON control_expression_list SEMICOLON increment_expression_list R_PAREN 
    compound_statement
    ;

initial_expression_list 
    : initial_expression
    |
    ;

initial_expression 
    : initial_expression COMMA variable_reference ASSIGN_OP logical_expression
    | initial_expression COMMA logical_expression
    | logical_expression
    | variable_reference ASSIGN_OP logical_expression
    ;

control_expression_list 
    : control_expression
    |
    ;

control_expression 
    : control_expression COMMA variable_reference ASSIGN_OP logical_expression
    | control_expression COMMA logical_expression
    | logical_expression
    | variable_reference ASSIGN_OP logical_expression
    ;

increment_expression_list 
    : increment_expression 
    |
    ;

increment_expression 
    : increment_expression COMMA variable_reference ASSIGN_OP logical_expression
    | increment_expression COMMA logical_expression
    | logical_expression
    | variable_reference ASSIGN_OP logical_expression
    ;

function_invoke_statement 
    : ID L_PAREN logical_expression_list R_PAREN SEMICOLON
    | ID L_PAREN R_PAREN SEMICOLON
    ;

jump_statement 
    : CONTINUE SEMICOLON
    | BREAK SEMICOLON
    | RETURN logical_expression SEMICOLON
    ;

variable_reference 
    : array_list
    | ID
    ;

logical_expression 
    : logical_expression OR_OP logical_term
    | logical_term
    ;

logical_term 
    : logical_term AND_OP logical_factor
    | logical_factor
    ;

logical_factor 
    : NOT_OP logical_factor
    | relation_expression
    ;

relation_expression 
    : relation_expression relation_operator arithmetic_expression
    | arithmetic_expression
    ;

relation_operator 
    : LT_OP
    | LE_OP
    | EQ_OP
    | GE_OP
    | GT_OP
    | NE_OP
    ;

arithmetic_expression 
    : arithmetic_expression ADD_OP term
    | arithmetic_expression SUB_OP term
    | term
    ;

term 
    : term MUL_OP factor
    | term DIV_OP factor
    | term MOD_OP factor
    | factor
    ;

factor 
    : SUB_OP factor
    | literal_const
    | variable_reference
    | L_PAREN logical_expression R_PAREN
    | ID L_PAREN logical_expression_list R_PAREN
    | ID L_PAREN R_PAREN
    ;

logical_expression_list 
    : logical_expression_list COMMA logical_expression
    | logical_expression
    ;

array_list 
    : ID dimension
    ;

dimension 
    : dimension ML_BRACE logical_expression MR_BRACE         
    | ML_BRACE logical_expression MR_BRACE
    ;

scalar_type 
    : INT
    | DOUBLE
    | STRING
    | BOOL
    | FLOAT
    ;
 
literal_const 
    : INT_CONST
    | FLOAT_CONST
    | SCIENTIFIC
    | STR_CONST
    | TRUE
    | FALSE
    ;

%%

void add_entry(int linenum, char *name, char *kind, int level, char *type, 
            struct para_list *para, struct dim_list *dim, char *const_value, int is_func_def){
    if(entry_head == NULL){
        struct entry_list *node = malloc(sizeof(struct entry_list));
        node->linenum = linenum;
        node->name = strndup(name, 32);
        node->kind = kind;
        node->level = level;
        node->type = strdup(type);
        node->para = para;
        node->dim = dim;
        if(const_value){ node->const_value = strdup(const_value); }
        else{ node->const_value = NULL; }
        node->is_func_def = is_func_def;
        node->next = NULL;
        entry_head = node;
        entry_end = node;
    }
    else{
        struct entry_list *current = entry_head;
        while(current != NULL){
            if(strncmp(current->name, name, 32) == 0 && current->level == level){
                if(!is_func_def){
                    char *tmp = strndup(name, 32);
                    printf("##########Error at Line #%d: %s redeclared.##########\n", linenum, tmp);
                    free(tmp);
                }/*
                else if(current->is_func_def){
                    char *tmp = strndup(name, 32);
                    printf("##########Error at Line #%d: %s redeclared.##########\n", linenum, tmp);
                    free(tmp);
                }*/
                return;
            }
            current = current->next;
        }
        struct entry_list *node = malloc(sizeof(struct entry_list));
        node->linenum = linenum;
        node->name = strndup(name, 32);
        node->kind = kind;
        node->level = level;
        node->type = strdup(type);
        node->para = para;
        node->dim = dim;
        if(const_value){ node->const_value = strdup(const_value); }
        else{ node->const_value = NULL; }
        node->is_func_def = is_func_def;
        node->next = NULL;
        entry_end->next = node;
        entry_end = node;
    }
}

void pop_entry(int level, int print){
    if(print){
        printf("=======================================================================================\n");
        printf("Name                             Kind       Level       Type               Attribute   \n");
        printf("---------------------------------------------------------------------------------------\n");
    }
    struct entry_list *current = entry_head;
    struct entry_list *prev = NULL;
    struct entry_list *tmp;
    while(current != NULL){
        if(current->level == level){
            if(print){
                printf("%-33s%-11s", current->name, current->kind);
                char *level_str = malloc(sizeof(char)*16);
                sprintf(level_str, "%d", current->level);
                if(current->level){ strcat(level_str, "(local)"); }
                else{ strcat(level_str, "(global)"); }
                printf("%-12s", level_str);
                free(level_str);
                if(current->para){
                    printf("%-19s", current->type);
                    struct para_list *current_para = current->para;
                    while(current_para != NULL){
                        printf("%s", current_para->type);
                        if(current_para->dim){
                            struct dim_list *current_dim = current_para->dim;
                            while(current_dim != NULL){
                                printf("[%s]", current_dim->size);
                                current_dim = current_dim->next;
                            }
                        }
                        current_para = current_para->next;
                        if(current_para != NULL){ printf(","); }
                    }
                }
                if(current->dim){
                    struct dim_list *current_dim = current->dim;
                    char *attr = strdup(current->type);
                    while(current_dim != NULL){
                        attr = realloc(attr, strlen(attr)+strlen(current_dim->size)+3);
                        strcat(attr, "["); strcat(attr, current_dim->size); strcat(attr, "]");
                        current_dim = current_dim->next;
                    }
                    printf("%-19s", attr);
                    free(attr);
                }
                if(current->const_value){ printf("%-19s%s", current->type, current->const_value); }
                if(!current->const_value && ! current->dim && !current->para){ printf("%-19s", current->type); }
                printf("\n");
            }

            if(prev == NULL){
                prev = current;
                current = current->next;
                entry_head = current;
                free(prev->name); free(prev->type); free(prev->const_value);
                //free para, free dim
                free(prev);
                prev = NULL;
            }
            else{
                prev->next = current->next;
                tmp = current;
                current = current->next;
                if(current == NULL){ entry_end = prev; }
                free(tmp->name); free(tmp->type); free(tmp->const_value);
                //free para, free dim
                free(tmp);
            }
        }
        else{
            prev = current;
            current = current->next;
        }
    }
    if(print)
        printf("=======================================================================================\n");
}

void add_dim(char *size){
    struct dim_list *node = malloc(sizeof(struct dim_list));
    node->size = size;
    node->next = NULL;
    if(dim_head == NULL){
        dim_head = node;
        dim_end = node;
    }
    else{
        dim_end->next = node;
        dim_end = node;
    }
}

void add_const_var(char *name, char *value){
    struct const_var_list *node = malloc(sizeof(struct const_var_list));
    node->name = name;
    node->value = value;
    node->next = NULL;
    if(const_var_head == NULL){
        const_var_head = node;
        const_var_end = node;
    }
    else{
        const_var_end->next = node;
        const_var_end = node;
    }
}

void free_const_var_list(){
    struct const_var_list *current = const_var_head;
    struct const_var_list *next;
    while(current != NULL){
        next = current->next;
        free(current->name); free(current->value); free(current);
        current = next;
    }
    const_var_head = NULL;
}

void add_var(char *name, struct dim_list *dim){
    struct var_list *node = malloc(sizeof(struct var_list));
    node->name = name;
    node->dim = dim;
    node->next = NULL;
    if(var_head == NULL){
        var_head = node;
        var_end = node;
    }
    else{
        var_end->next = node;
        var_end = node;
    }
}

void free_var_list(){
    struct var_list *current = var_head;
    struct var_list *next;
    while(current != NULL){
        next = current->next;
        free(current->name); free(current);
        current = next;
    }
    var_head = NULL;
}

void add_para(char *name, char *type, struct dim_list *dim){
    struct para_list *node = malloc(sizeof(struct para_list));
    node->name = name;
    node->type = type;
    node->dim = dim;
    node->next = NULL;
    if(para_head == NULL){
        para_head = node;
        para_end = node;
    }
    else{
        para_end->next = node;
        para_end = node;
    }
}

int yyerror(char *msg){
    fprintf(stderr, "\n|--------------------------------------------------------------------------\n");
    fprintf(stderr, "| Error found in Line #%d: %s\n", linenum, buf );
    fprintf(stderr, "|\n" );
    fprintf(stderr, "| Unmatched token: %s\n", yytext );
    fprintf(stderr, "|--------------------------------------------------------------------------\n");
    exit(-1);
    //  fprintf( stderr, "%s\t%d\t%s\t%s\n", "Error found in Line ", linenum, "next token: ", yytext );
}