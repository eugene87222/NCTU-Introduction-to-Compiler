%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include"datatype.h"
#include"symtable.h"

extern int linenum;
extern FILE	*yyin;
extern char	*yytext;
extern char buf[256];
extern int Opt_SymTable; //declared in lex.l

int scope = 0; //default is 0(global)
int hasError = 0;
int inLoop = 0;
int LastStateisReturn = 0;
BTYPE currType = -1;
BTYPE currFuncType = -1;
int currElemNum = -1;
int currElemNum_var = 0;
int currDim = 0;
int arrTypeError = 0;

struct SymTableList *symbolTableList; //create and initialize in main.c
struct ExtType *funcReturnType;

%}
%union{
    int    intVal;
    float  floatVal;
    double doubleVal;
    char   *stringVal;
    char   *idName;
    BTYPE  bType;
    struct Variable		*variable;
    struct VariableList	*variableList;
    struct ArrayDimNode	*arrayDimNode;
    struct FuncAttrNode	*funcAttrNode;
    struct Attribute	*attribute;
    struct SymTableNode	*symTableNode;
    struct ExpTypeNode  *expType;
};

%token <idName> ID
%token <intVal> INT_CONST
%token <floatVal> FLOAT_CONST
%token <doubleVal> SCIENTIFIC
%token <stringVal> STR_CONST

%type <expType> variable_reference
%type <expType> factor
%type <expType> term
%type <expType> arithmetic_expression
%type <expType> relation_expression
%type <expType> logical_factor
%type <expType> logical_term
%type <expType> logical_expression
%type <expType> logical_expression_list
%type <expType> array_list
%type <expType> control_expression

%type <variable> array_decl
%type <variableList> identifier_list
%type <arrayDimNode> dim
%type <funcAttrNode> parameter_list
%type <attribute> literal_const 
%type <symTableNode> const_list
%type <bType> scalar_type

%token LE_OP
%token NE_OP
%token GE_OP
%token EQ_OP
%token AND_OP
%token OR_OP

%token READ
%token BOOLEAN
%token WHILE
%token DO
%token IF
%token ELSE
%token TRUE
%token FALSE
%token FOR
%token INT
%token PRINT
%token BOOL
%token VOID
%token FLOAT
%token DOUBLE
%token STRING
%token CONTINUE
%token BREAK
%token RETURN
%token CONST

%token L_PAREN
%token R_PAREN
%token COMMA
%token SEMICOLON
%token ML_BRACE
%token MR_BRACE
%token L_BRACE
%token R_BRACE
%token ADD_OP
%token SUB_OP
%token MUL_OP
%token DIV_OP
%token MOD_OP
%token ASSIGN_OP
%token LT_OP
%token GT_OP
%token NOT_OP

/*	Program 
    Function 
    Array 
    Const 
    IF 
    ELSE 
    RETURN 
    FOR 
    WHILE
*/
%start program
%%

program
    : decl_list funct_def decl_and_def_list
    {
        if(Opt_SymTable == 1)
            printSymTable(symbolTableList->global);
        if(checkAllFuncDef(symbolTableList->global) != 1) hasError = ErrMsg("there are some undefined functions.", linenum);
        deleteLastSymTable(symbolTableList);
    }
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
    : scalar_type ID L_PAREN R_PAREN 
    {
        currFuncType = $1;
        funcReturnType = createExtType($1, 0, NULL);
        struct SymTableNode *node = findName(symbolTableList->global, $2);
        if(node == NULL)
        {
            struct SymTableNode *newNode = createFunctionNode($2, scope, funcReturnType, NULL, 1);
            insertTableNode(symbolTableList->global, newNode);
        }
        else if(node->kind != FUNCTION_t) hasError = ErrMsg("the name has been used.", linenum);
        else if(node->beenDef) hasError = ErrMsg("function redefined.", linenum);
        else if(!node->beenDef)
        {
            if(node->type->baseType != $1) hasError = ErrMsg("definition must match declaration.", linenum);
            else if(node->attr != NULL) hasError = ErrMsg("definition must match declaration.", linenum);
            else { node->beenDef = 1; }
        }
        free($2);
    } compound_statement
    {
        if(LastStateisReturn == 0) hasError = ErrMsg("the last statement must be return.", linenum);
        LastStateisReturn = 0;
    }
    | scalar_type ID L_PAREN parameter_list R_PAREN 
    {
        currFuncType = $1;
        funcReturnType = createExtType($1, 0, NULL);
        struct Attribute *attr = createFunctionAttribute($4);
        struct SymTableNode *node = findName(symbolTableList->global, $2);
        if(node == NULL)
        {
            struct SymTableNode *newNode = createFunctionNode($2, scope, funcReturnType, attr, 1);
            insertTableNode(symbolTableList->global, newNode);
        }
        else if(node->kind != FUNCTION_t) hasError = ErrMsg("the name has been used.", linenum);
        else if(node->beenDef) hasError = ErrMsg("function redefined.", linenum);
        else if(!node->beenDef)
        {
            int paramNum1 = node->attr->funcParam->paramNum;
            int paramNum2 = attr->funcParam->paramNum;
            if(node->type->baseType != $1) hasError = ErrMsg("definition must match declaration.", linenum);
            else if(node->attr == NULL) hasError = ErrMsg("definition must match declaration.", linenum);
            else if(paramNum1 != paramNum2) hasError = ErrMsg("definition must match declaration.", linenum);
            else if(paramNum1 == paramNum2)
            {
                if(checkParam(node->attr->funcParam->head, attr->funcParam->head) == 0)
                {
                    hasError = ErrMsg("definition must match declaration.", linenum);
                }
                else { node->beenDef = 1; }
            }
        }
    } L_BRACE 
    { //enter a new scope
        ++scope;
        AddSymTable(symbolTableList);
        //add parameters
        struct FuncAttrNode *attrNode = $4;
        while(attrNode != NULL)
        {
            struct SymTableNode *node = findName(symbolTableList->tail, attrNode->name);
            if(node != NULL) hasError = ErrMsg("parameter redeclared.", linenum);
            else
            {
                struct SymTableNode *newNode = createParameterNode(attrNode->name, scope, attrNode->value, 0);
                insertTableNode(symbolTableList->tail, newNode);
            }
            attrNode = attrNode->next;
        }
    } var_const_stmt_list R_BRACE
    {
        if(LastStateisReturn == 0) hasError = ErrMsg("the last statement must be return.", linenum);
        LastStateisReturn = 0;
        if(Opt_SymTable == 1)
            printSymTable(symbolTableList->tail);
        deleteLastSymTable(symbolTableList);
        --scope;
        free($2);
    }
    | VOID ID L_PAREN R_PAREN
    {
        currFuncType = VOID_t;
        funcReturnType = createExtType(VOID_t, 0, NULL);
        struct SymTableNode *node = findName(symbolTableList->global, $2);
        if(node == NULL)
        {
            struct SymTableNode *newNode = createFunctionNode($2, scope, funcReturnType, NULL, 1);
            insertTableNode(symbolTableList->global, newNode);
        }
        else if(node->kind != FUNCTION_t) hasError = ErrMsg("the name has been used.", linenum);
        else if(node->beenDef) hasError = ErrMsg("function redefined.", linenum);
        else if(!node->beenDef)
        {
            if(node->type->baseType != VOID_t) hasError = ErrMsg("definition must match declaration.", linenum);
            else if(node->attr != NULL) hasError = ErrMsg("definition must match declaration.", linenum);
            else { node->beenDef = 1; }
        }
        free($2);
    } compound_statement
    | VOID ID L_PAREN parameter_list R_PAREN
    {
        currFuncType = VOID_t;
        funcReturnType = createExtType(VOID_t, 0, NULL);
        struct Attribute *attr = createFunctionAttribute($4);
        struct SymTableNode *node = findName(symbolTableList->global, $2);
        if(node == NULL)
        {
            struct SymTableNode *newNode = createFunctionNode($2, scope, funcReturnType, attr, 1);
            insertTableNode(symbolTableList->global, newNode);
        }
        else if(node->kind != FUNCTION_t) hasError = ErrMsg("the name has been used.", linenum);
        else if(node->beenDef) hasError = ErrMsg("function redefined.", linenum);
        else if(!node->beenDef)
        {
            int paramNum1 = node->attr->funcParam->paramNum;
            int paramNum2 = attr->funcParam->paramNum;
            if(node->type->baseType != VOID_t) hasError = ErrMsg("definition must match declaration.", linenum);
            else if(node->attr == NULL) hasError = ErrMsg("definition must match declaration.", linenum);
            else if(paramNum1 != paramNum2) hasError = ErrMsg("definition must match declaration.", linenum);
            else if(paramNum1 == paramNum2)
            {
                if(checkParam(node->attr->funcParam->head, attr->funcParam->head) == 0)
                {
                     hasError = ErrMsg("definition must match declaration.", linenum);
                }
                else { node->beenDef = 1; }
            }
        }
    } L_BRACE 
    { //enter a new scope
        ++scope;
        AddSymTable(symbolTableList);
        //add parameters
        struct FuncAttrNode *attrNode = $4;
        while(attrNode != NULL)
        {
            struct SymTableNode *node = findName(symbolTableList->tail, attrNode->name);
            if(node != NULL) hasError = ErrMsg("parameter redeclared.", linenum);
            else
            {
                struct SymTableNode *newNode = createParameterNode(attrNode->name, scope, attrNode->value, 0);
                insertTableNode(symbolTableList->tail, newNode);
            }
            attrNode = attrNode->next;
        }
    } var_const_stmt_list R_BRACE
    {	
        if(Opt_SymTable == 1)
            printSymTable(symbolTableList->tail);
        deleteLastSymTable(symbolTableList);
        --scope;
        free($2);
    }
    ;

funct_decl
    : scalar_type ID L_PAREN R_PAREN SEMICOLON
    {
        funcReturnType = createExtType($1, 0, NULL);
        struct SymTableNode *node = findName(symbolTableList->global, $2);
        if(node == NULL)
        {
            struct SymTableNode *newNode = createFunctionNode($2, scope, funcReturnType, NULL, 0);
            insertTableNode(symbolTableList->global, newNode);
        }
        else if(node->kind != FUNCTION_t) hasError = ErrMsg("the name has been used.", linenum);
        else hasError = ErrMsg("function redeclared.", linenum);
        free($2);
    }
    | scalar_type ID L_PAREN parameter_list R_PAREN SEMICOLON
    {
        funcReturnType = createExtType($1, 0, NULL);
        struct Attribute *attr = createFunctionAttribute($4);
        struct SymTableNode *node = findName(symbolTableList->global, $2);
        if(node == NULL)
        {
            struct SymTableNode *newNode = createFunctionNode($2, scope, funcReturnType, attr, 0);
            insertTableNode(symbolTableList->global, newNode);
        }
        else if(node->kind != FUNCTION_t) hasError = ErrMsg("the name has been used.", linenum);
        else hasError = ErrMsg("function redeclared.", linenum);
        free($2);
    }
    | VOID ID L_PAREN R_PAREN SEMICOLON
    {
        funcReturnType = createExtType(VOID_t, 0, NULL);
        struct SymTableNode *node = findName(symbolTableList->global, $2);
        if(node == NULL)
        {
            struct SymTableNode *newNode = createFunctionNode($2, scope, funcReturnType, NULL, 0);
            insertTableNode(symbolTableList->global, newNode);
        }
        else if(node->kind != FUNCTION_t) hasError = ErrMsg("the name has been used.", linenum);
        else hasError = ErrMsg("function redeclared.", linenum);
        free($2);
    }
    | VOID ID L_PAREN parameter_list R_PAREN SEMICOLON
    {
        funcReturnType = createExtType(VOID_t, 0, NULL);
        struct Attribute *attr = createFunctionAttribute($4);
        struct SymTableNode *node = findName(symbolTableList->global, $2);
        if(node == NULL)
        {
            struct SymTableNode *newNode = createFunctionNode($2, scope, funcReturnType, attr, 0);
            insertTableNode(symbolTableList->global, newNode);
        }
        else if(node->kind != FUNCTION_t) hasError = ErrMsg("the name has been used.", linenum);
        else hasError = ErrMsg("function redeclared.", linenum);
        free($2);
    }
    ;

parameter_list
    : parameter_list COMMA scalar_type ID
    {
        struct FuncAttrNode *newNode = (struct FuncAttrNode*)malloc(sizeof(struct FuncAttrNode));
        newNode->value = createExtType($3, 0, NULL);
        newNode->name = strdup($4);
        free($4);
        newNode->next = NULL;
        connectFuncAttrNode($1, newNode);
        $$ = $1;
    }
    | parameter_list COMMA scalar_type array_decl
    {
        struct FuncAttrNode *newNode = (struct FuncAttrNode*)malloc(sizeof(struct FuncAttrNode));
        newNode->value = $4->type; //use pre-built ExtType(type is unknown)
        newNode->value->baseType = $3; //set correct type
        newNode->name = strdup($4->name);
        newNode->next = NULL;
        free($4->name);
        free($4);
        connectFuncAttrNode($1, newNode);
        $$ = $1;
    }
    | scalar_type array_decl
    {
        struct FuncAttrNode *newNode = (struct FuncAttrNode*)malloc(sizeof(struct FuncAttrNode));
        newNode->value = $2->type; //use pre-built ExtType(type is unknown)
        newNode->value->baseType = $1; //set correct type
        newNode->name = strdup($2->name);
        newNode->next = NULL;
        free($2->name);
        free($2);
        $$ = newNode;
    }
    | scalar_type ID
    {
        struct FuncAttrNode *newNode = (struct FuncAttrNode*)malloc(sizeof(struct FuncAttrNode));
        newNode->value = createExtType($1, 0, NULL);
        newNode->name = strdup($2);
        free($2);
        newNode->next = NULL;
        $$ = newNode;
    }
    ;

var_decl
    : scalar_type identifier_list SEMICOLON
    {
        struct Variable* listNode = $2->head;
        struct SymTableNode *newNode;
        struct SymTableNode *node;
        while(listNode != NULL)
        {
            node = findName(symbolTableList->tail, listNode->name);
            if(node != NULL) hasError = ErrMsg("variable redeclared.", linenum);
            else
            {
                newNode = createVariableNode(listNode->name, scope, listNode->type, 0);
                newNode->type->baseType = $1;
                insertTableNode(symbolTableList->tail, newNode);
            }
            listNode = listNode->next;
        }
        deleteVariableList($2);
        currType = -1;
    }
    ;

identifier_list
    : identifier_list COMMA ID
    {
        struct ExtType *type = createExtType(VOID, false, NULL); //type unknown here
        struct Variable *newVariable = createVariable($3, type);
        free($3);
        connectVariableList($1, newVariable);
        $$ = $1;
    }
    | identifier_list COMMA ID ASSIGN_OP logical_expression
    {    
        struct ExtType *type = createExtType(VOID, false, NULL); //type unknown here
        struct Variable *newVariable = createVariable($3, type);
        connectVariableList($1, newVariable);
        $$ = $1;
        if($5->type->baseType == ERROR_t) hasError = ErrMsg("expression type error.", linenum);
        if(checkCoercion(currType, $5->type->baseType))
            hasError = ErrMsg("the type of LHS must match the type of RHS.", linenum);
        free($3);
    }
    | identifier_list COMMA array_decl
    {
        currElemNum = getElemNum($3->type->dimArray);
        currElemNum_var = 0;
        arrTypeError = 0;
    } ASSIGN_OP initial_array
    {
        connectVariableList($1, $3);
        $$ = $1;
        if(arrTypeError != 0) hasError = ErrMsg("array initializers type error.", linenum);
        if(currElemNum_var > currElemNum) hasError = ErrMsg("too many initializers.", linenum);
    }
    | identifier_list COMMA array_decl
    {
        connectVariableList($1, $3);
        $$ = $1;
    }
    | array_decl
    {
        currElemNum = getElemNum($1->type->dimArray);
        currElemNum_var = 0;
        arrTypeError = 0;
    } ASSIGN_OP initial_array
    {
        $$ = createVariableList($1);
        if(arrTypeError != 0) hasError = ErrMsg("array initializers type error.", linenum);
        if(currElemNum_var > currElemNum) hasError = ErrMsg("too many initializers.", linenum);
    }
    | array_decl { $$ = createVariableList($1); }
    | ID ASSIGN_OP logical_expression
    {
        struct ExtType *type = createExtType(VOID, false, NULL); //type unknown here
        struct Variable *newVariable = createVariable($1, type);
        $$ = createVariableList(newVariable);
        if($3->type->baseType == ERROR_t) hasError = ErrMsg("expression type error.", linenum);
        if(checkCoercion(currType, $3->type->baseType))
            hasError = ErrMsg("the type of LHS must match the type of RHS.", linenum);
        free($1);
    }
    | ID
    {
        struct ExtType *type = createExtType(VOID, false, NULL); //type unknown here
        struct Variable *newVariable = createVariable($1, type);
        $$ = createVariableList(newVariable);
        free($1);
    }
    ;

initial_array
    : L_BRACE literal_list R_BRACE
    | L_BRACE R_BRACE
    ;

literal_list
    : literal_list COMMA logical_expression
    {
        if(checkCoercion(currType, $3->type->baseType)) arrTypeError = 1;
        currElemNum_var++;
    }
    | logical_expression
    {
        if(checkCoercion(currType, $1->type->baseType)) arrTypeError = 1;
        currElemNum_var++;
    }
    ;

const_decl
    : CONST scalar_type const_list SEMICOLON
    {
        struct SymTableNode *list = $3; //symTableNode base on initailized data type, scalar_type is not used
        struct SymTableNode *node;
        while(list != NULL)
        {
            node = findName(symbolTableList->tail, list->name);
            if(node == NULL) insertTableNode(symbolTableList->tail, list);
            else if(node->kind == CONSTANT_t) hasError = ErrMsg("const redeclared.", linenum);
            else hasError = ErrMsg("the name has been used.", linenum);
            list = list->next;
        }
    }
;

const_list
    : const_list COMMA ID ASSIGN_OP literal_const
    {
        struct ExtType *type = createExtType($5->constVal->type, false, NULL);
        struct SymTableNode *temp = $1;
        while(temp->next != NULL) temp = temp->next;
        temp->next = createConstNode($3, scope, type, $5, 0);	
        free($3);
    }
    | ID ASSIGN_OP literal_const
    {
        struct ExtType *type = createExtType($3->constVal->type, false, NULL);
        $$ = createConstNode($1, scope, type, $3, 0);	
        free($1);
    }    
    ;

array_decl
    : ID dim
    {
        struct ExtType *type = createExtType(VOID, true, $2); //type unknown here
        struct Variable *newVariable = createVariable($1, type);
        free($1);
        $$ = newVariable;
    }
    ;

dim
    : dim ML_BRACE INT_CONST MR_BRACE
    {
        connectArrayDimNode($1, createArrayDimNode($3));
        $$ = $1;
    }
    | ML_BRACE INT_CONST MR_BRACE
    {
        $$ = createArrayDimNode($2);
        if($2 <= 0) hasError = ErrMsg("array index must be greater than zero.", linenum);
    }
    ;

compound_statement
    : L_BRACE 
    { //enter a new scope
        ++scope;
        AddSymTable(symbolTableList);
    } var_const_stmt_list R_BRACE
    {	
        if(Opt_SymTable == 1)
            printSymTable(symbolTableList->tail);
        deleteLastSymTable(symbolTableList);
        --scope;
    }
    ;

var_const_stmt_list
    : var_const_stmt_list statement	
    | var_const_stmt_list var_decl { LastStateisReturn = 0;}
    | var_const_stmt_list const_decl { LastStateisReturn = 0;}
    | { LastStateisReturn = 0;}
    ;

statement
    : compound_statement { LastStateisReturn = 0; }
    | simple_statement { LastStateisReturn = 0; }
    | conditional_statement { LastStateisReturn = 0; }
    | while_statement { LastStateisReturn = 0; }
    | for_statement { LastStateisReturn = 0; }
    | function_invoke_statement { LastStateisReturn = 0; }
    | jump_statement
    ;		

simple_statement
    : variable_reference ASSIGN_OP logical_expression SEMICOLON
    {
        if($1->kind == CONSTANT_t) hasError = ErrMsg("re-assignment to a constant.", linenum);
        else if($1->type->baseType == ERROR_t) hasError = ErrMsg("unknown type on the LHS.", linenum);
        else
        {
            if(checkCoercion($1->type->baseType, $3->type->baseType)) 
                hasError = ErrMsg("the type of LHS must match the type of RHS.", linenum);
        }
    }
    | PRINT logical_expression SEMICOLON
    {
        if($2->type->baseType == VOID_t || $2->type->baseType == ERROR_t)
            hasError = ErrMsg("only scalar type is accepted.", linenum);
    }
    | READ variable_reference SEMICOLON
    {
        if($2->type->baseType == VOID_t || $2->type->baseType == ERROR_t)
            hasError = ErrMsg("only scalar type is accepted.", linenum);
    }
    ;

conditional_statement
    : IF L_PAREN logical_expression 
    {
        if($3->type->baseType != BOOL_t) hasError = ErrMsg("condition expression must be boolean type.", linenum);
    } conditional_statement_cont
    ;

conditional_statement_cont
    : R_PAREN compound_statement
    | R_PAREN compound_statement ELSE compound_statement
    ;

while_statement
    : WHILE
    { //enter a new scope
        ++scope;
        AddSymTable(symbolTableList);
    } L_PAREN logical_expression
    {
        if($4->type->baseType != BOOL_t) hasError = ErrMsg("condition expression must be boolean type.", linenum);
    } R_PAREN L_BRACE { inLoop = 1; } var_const_stmt_list R_BRACE
    {	
        if(Opt_SymTable == 1)
            printSymTable(symbolTableList->tail);
        deleteLastSymTable(symbolTableList);
        --scope;
        inLoop = 0;
    }
    | DO L_BRACE
    { //enter a new scope
        ++scope;
        inLoop = 1;
        AddSymTable(symbolTableList);
    } var_const_stmt_list R_BRACE { inLoop = 0; } WHILE L_PAREN logical_expression
    {
        if($9->type->baseType != BOOL_t) hasError = ErrMsg("condition expression must be boolean type.", linenum);
    } R_PAREN SEMICOLON
    {
        if(Opt_SymTable == 1)
            printSymTable(symbolTableList->tail);
        deleteLastSymTable(symbolTableList);
        --scope;
    }
    ;

for_statement
    : FOR
    { //enter a new scope
        ++scope;
        AddSymTable(symbolTableList);
    } L_PAREN initial_expression_list SEMICOLON control_expression_list SEMICOLON increment_expression_list R_PAREN 
    L_BRACE { inLoop = 1; } var_const_stmt_list R_BRACE
    {
        if(Opt_SymTable == 1)
            printSymTable(symbolTableList->tail);
        deleteLastSymTable(symbolTableList);
        --scope;
        inLoop = 0;
    }
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
    {
        //if($1->type->baseType != BOOL_t) hasError = ErrMsg("control expression must be boolean type.", linenum);
    }
    |
    ;

control_expression
    : control_expression COMMA variable_reference ASSIGN_OP logical_expression
    {
        if($3->type->baseType == ERROR_t) hasError = ErrMsg("expression type error.", linenum);
        if(checkCoercion($3->type->baseType, $5->type->baseType))
            hasError = ErrMsg("the type of LHS must match the type of RHS.", linenum);

        $$ = createExpTypeNode(createExtType(ERROR_t, 0, NULL), UNKNOWN_t);
        hasError = ErrMsg("control expression must be boolean type.", linenum);
    }
    | control_expression COMMA logical_expression
    {
        $$ = createExpTypeNode(createExtType(ERROR_t, 0, NULL), UNKNOWN_t);
        hasError = ErrMsg("control expression must be boolean type.", linenum);
    }
    | logical_expression
    {
        if($1->type->baseType != BOOL_t)
        {
            hasError = ErrMsg("control expression must be boolean type.", linenum);
            $$ = createExpTypeNode(createExtType(ERROR_t, 0, NULL), UNKNOWN_t);
        }
        else $$ = createExpTypeNode(createExtType(BOOL_t, 0, NULL), VARIABLE_t);
    }
    | variable_reference ASSIGN_OP logical_expression
    {
        if($1->type->baseType == ERROR_t) hasError = ErrMsg("expression type error.", linenum);
        if(checkCoercion($1->type->baseType, $3->type->baseType))
            hasError = ErrMsg("the type of LHS must match the type of RHS.", linenum);

        if($1->type->baseType != BOOL_t || $3->type->baseType != BOOL_t)
        {
            hasError = ErrMsg("control expression must be boolean type.", linenum);
            $$ = createExpTypeNode(createExtType(ERROR_t, 0, NULL), UNKNOWN_t);
        }
        else $$ = createExpTypeNode(createExtType(BOOL_t, 0, NULL), VARIABLE_t);
    }
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
    {
        struct SymTableNode *node = findFuncDeclaration(symbolTableList->global, $1);
        if(node == NULL) hasError = ErrMsg("unknown function.", linenum);
        else
        {
            if(node->attr == NULL) hasError = ErrMsg("number of the params must match the func decl / def.", linenum);
            else
            {
                struct FuncAttrNode *FuncType = node->attr->funcParam->head;
                struct ExpTypeNode *ExpType = $3;
                int diffType = 0;
                while(FuncType != NULL && ExpType != NULL)
                {
                    if(checkCoercion(FuncType->value->baseType, ExpType->type->baseType)) diffType = 1;
                    if(FuncType->value->isArray != ExpType->type->isArray) diffType = 1;
                    else if(FuncType->value->dim != ExpType->type->dim) diffType = 1;
                    else if(FuncType->value->isArray == true)
                    {
                        struct ArrayDimNode *b = ExpType->type->dimArray;
                        int ori_size = 0, shift_size;
                        while(b != NULL)
                        {
                            ori_size++;
                            b = b->next;
                        }
                        shift_size = ori_size - ExpType->type->dim;
                        b = ExpType->type->dimArray;
                        while(shift_size)
                        {
                            b = b->next;
                            shift_size--;
                        }

                        struct ArrayDimNode *a = FuncType->value->dimArray;
                        while(a != NULL && b != NULL)
                        {
                            if(a->size != b->size)
                            {
                                diffType = 1;
                                break;
                            }
                            a = a->next;
                            b = b->next;
                        }
                    }
                    ExpType = ExpType->next;
                    FuncType = FuncType->next;
                }
                if(diffType) hasError = ErrMsg("type of the params must match the func decl / def.", linenum);
                if(FuncType != NULL || ExpType != NULL) hasError = ErrMsg("number of the params must match the func decl / def.", linenum);
            }
        }
        free($1);
    }
    | ID L_PAREN R_PAREN SEMICOLON
    { 
        struct SymTableNode *node = findFuncDeclaration(symbolTableList->global, $1);
        if(node == NULL) hasError = ErrMsg("unknown function.", linenum);
        else if(node->attr != NULL) hasError = ErrMsg("number of the params must match the func decl / def.", linenum);
        free($1); 
    }
    ;

jump_statement
    : CONTINUE SEMICOLON
    {
        LastStateisReturn = 0;
        if(!inLoop) hasError = ErrMsg("continue can only appear in loop statements.", linenum);
    }
    | BREAK SEMICOLON
    {
        LastStateisReturn = 0;
        if(!inLoop) hasError = ErrMsg("break can only appear in loop statements.", linenum);
    }
    | RETURN logical_expression SEMICOLON
    {
        LastStateisReturn = 1;
        if(currFuncType == VOID_t) hasError = ErrMsg("procedure has no return value.", linenum);
        else
        {
            if(checkCoercion(currFuncType, $2->type->baseType))
                hasError = ErrMsg("return type must match the func decl / def.", linenum);
        }
    }
    ;

variable_reference
    : array_list { $$ = $1; }
    | ID
    {
        struct SymTableNode *target = NULL;
        struct SymTableNode *tmp;
        struct SymTable *ListNode = symbolTableList->head;
        while(ListNode != NULL)
        {
            tmp = findName(ListNode, $1);
            if(tmp != NULL)
                if(tmp->kind == PARAMETER_t || tmp->kind == VARIABLE_t || tmp->kind == CONSTANT_t)
                    target = tmp;
            ListNode = ListNode->next;
        }
        if(target != NULL) $$ = createExpTypeNode(target->type, target->kind);
        else
        {
            hasError = ErrMsg("unknown variable.", linenum);
            $$ = createExpTypeNode(createExtType(ERROR_t, 0, NULL), UNKNOWN_t);
        }
    }
    ;

logical_expression
    : logical_expression OR_OP logical_term { $$ = checkLogicalType($1, $3, linenum); }
    | logical_term { $$ = $1; }
    ;

logical_term
    : logical_term AND_OP logical_factor { $$ = checkLogicalType($1, $3, linenum); }
    | logical_factor { $$ = $1; }
    ;

logical_factor
    : NOT_OP logical_factor
    {
        if($2->type->baseType == BOOL_t) $$ = $2;
        else $$ = createExpTypeNode(createExtType(ERROR_t, 0, NULL), UNKNOWN_t);
    }
    | relation_expression { $$ = $1; }
    ;

relation_expression
    : relation_expression LT_OP arithmetic_expression { $$ = checkRelationType($1, $3, linenum); }
    | relation_expression LE_OP arithmetic_expression { $$ = checkRelationType($1, $3, linenum); }
    | relation_expression GE_OP arithmetic_expression { $$ = checkRelationType($1, $3, linenum); }
    | relation_expression GT_OP arithmetic_expression { $$ = checkRelationType($1, $3, linenum); }
    | relation_expression EQ_OP arithmetic_expression { $$ = checkEqualType($1, $3, linenum); }
    | relation_expression NE_OP arithmetic_expression { $$ = checkEqualType($1, $3, linenum); }
    | arithmetic_expression { $$ = $1; }
    ;

arithmetic_expression
    : arithmetic_expression ADD_OP term { $$ = checkArithmeticType($1, $3, linenum); }
    | arithmetic_expression SUB_OP term { $$ = checkArithmeticType($1, $3, linenum); }
    | term { $$ = $1; }
    ;

term
    : term MUL_OP factor { $$ = checkArithmeticType($1, $3, linenum); }
    | term DIV_OP factor { $$ = checkArithmeticType($1, $3, linenum); }
    | term MOD_OP factor
    {
        if($1->type->baseType == $3->type->baseType && $1->type->baseType == INT_t)
            $$ = createExpTypeNode(createExtType(INT_t, 0, NULL), VARIABLE_t);
        else
        {
            $$ = createExpTypeNode(createExtType(ERROR_t, 0, NULL), UNKNOWN_t);
            hasError = ErrMsg("both operands for %% must be integers.", linenum);
        }
    }
    | factor { $$ = $1; }
    ;

factor
    : variable_reference { $$ = $1; }
    | SUB_OP factor { $$ = $2; }
    | L_PAREN logical_expression R_PAREN { $$ = $2; }
    | ID L_PAREN logical_expression_list R_PAREN
    {
        struct SymTableNode *node = findFuncDeclaration(symbolTableList->global, $1);
        if(node == NULL)
        {
            hasError = ErrMsg("unknown function.", linenum);
            $$ = createExpTypeNode(createExtType(ERROR_t, 0, NULL), UNKNOWN_t);
        }
        else
        {
            $$ = createExpTypeNode(node->type, node->kind);
            if(node->attr == NULL) hasError = ErrMsg("number of the params must match the func decl / def.", linenum);
            else
            {
                struct FuncAttrNode *FuncType = node->attr->funcParam->head;
                struct ExpTypeNode *ExpType = $3;
                int diffType = 0;
                while(FuncType != NULL && ExpType != NULL)
                {
                    if(checkCoercion(FuncType->value->baseType, ExpType->type->baseType)) diffType = 1;
                    if(FuncType->value->isArray != ExpType->type->isArray) diffType = 1;
                    else if(FuncType->value->dim != ExpType->type->dim) diffType = 1;
                    else if(FuncType->value->isArray == true)
                    {
                        struct ArrayDimNode *b = ExpType->type->dimArray;
                        int ori_size = 0, shift_size;
                        while(b != NULL)
                        {
                            ori_size++;
                            b = b->next;
                        }
                        shift_size = ori_size - ExpType->type->dim;
                        b = ExpType->type->dimArray;
                        while(shift_size)
                        {
                            b = b->next;
                            shift_size--;
                        }

                        struct ArrayDimNode *a = FuncType->value->dimArray;
                        while(a != NULL && b != NULL)
                        {
                            if(a->size != b->size)
                            {
                                diffType = 1;
                                break;
                            }
                            a = a->next;
                            b = b->next;
                        }
                    }
                    ExpType = ExpType->next;
                    FuncType = FuncType->next;
                }
                if(diffType) hasError = ErrMsg("type of the params must match the func decl / def.", linenum);
                if(FuncType != NULL || ExpType != NULL) hasError = ErrMsg("number of the params must match the func decl / def.", linenum);
            }
        }
    }
    | ID L_PAREN R_PAREN
    {
        struct SymTableNode *node = findFuncDeclaration(symbolTableList->global, $1);
        if(node == NULL)
        {
            hasError = ErrMsg("unknown function.", linenum);
            $$ = createExpTypeNode(createExtType(ERROR_t, 0, NULL), UNKNOWN_t);
        }
        else
        {
            $$ = createExpTypeNode(node->type, node->kind);
            if(node->attr != NULL) hasError = ErrMsg("number of the params must match the func decl / def.", linenum);
        }

    }
    | literal_const
    {
        $$ = createExpTypeNode(createExtType($1->constVal->type, 0, NULL), CONSTANT_t);
        killAttribute($1);
    }
    ;

logical_expression_list
    : logical_expression_list COMMA logical_expression { connectExpTypeNode($1, $3); }
    | logical_expression { $$ = $1; }
    ;

array_list
    : ID { currDim = 0; } dimension
    {
        struct SymTableNode *target = NULL;
        struct SymTableNode *tmp;
        struct SymTable *ListNode = symbolTableList->head;
        while(ListNode != NULL)
        {
            tmp = findName(ListNode, $1);
            if(tmp != NULL)
                if(tmp->kind == PARAMETER_t || tmp->kind == VARIABLE_t || tmp->kind == CONSTANT_t)
                    target = tmp;
            ListNode = ListNode->next;
        }        
        if(target != NULL)
        {
            if(currDim == target->type->dim) $$ = createExpTypeNode(createExtType(target->type->baseType, 0, NULL), target->kind);
            else if(currDim < target->type->dim)
            {
                $$ = createExpTypeNode(target->type, target->kind);
                $$->type->dim -= currDim;
            }
            else $$ = createExpTypeNode(createExtType(ERROR_t, 0, NULL), UNKNOWN_t);
        }
        else
        {
            hasError = ErrMsg("unknown variable.", linenum);
            $$ = createExpTypeNode(createExtType(ERROR_t, 0, NULL), UNKNOWN_t);
        }
    }
    ;

dimension
    : dimension ML_BRACE logical_expression MR_BRACE
    {
        if($3->type->baseType != INT_t) hasError = ErrMsg("index of array must be an integer.", linenum);
        currDim++;
    }
    | ML_BRACE logical_expression MR_BRACE
    {
        if($2->type->baseType != INT_t)  hasError = ErrMsg("index of array must be an integer.", linenum);
        currDim++;
    }
    ;

scalar_type
    : INT { $$ = INT_t; currType = INT_t; }
    | DOUBLE { $$ = DOUBLE_t; currType = DOUBLE_t; }
    | STRING { $$ = STRING_t; currType = STRING_t; }
    | BOOL { $$ = BOOL_t; currType = BOOL_t; }
    | FLOAT { $$ = FLOAT_t; currType = FLOAT_t; }
    ;
 
literal_const
    : INT_CONST
    {
        int val = $1;
        $$ = createConstantAttribute(INT_t, &val);
    }
    | SUB_OP INT_CONST
    {
        int val = -$2;
        $$ = createConstantAttribute(INT_t, &val);
    }
    | FLOAT_CONST
    {
        float val = $1;
        $$ = createConstantAttribute(FLOAT_t, &val);
    }
    | SUB_OP FLOAT_CONST
    {
        float val = -$2;
        $$ = createConstantAttribute(FLOAT_t, &val);
    }
    | SCIENTIFIC
    {
        double val = $1;
        $$ = createConstantAttribute(DOUBLE_t, &val);
    }
    | SUB_OP SCIENTIFIC
    {
        double val = -$2;
        $$ = createConstantAttribute(DOUBLE_t, &val);
    }
    | STR_CONST
    {
        $$ = createConstantAttribute(STRING_t, $1);
        free($1);
    }
    | TRUE
    {
        bool val = true;
        $$ = createConstantAttribute(BOOL_t, &val);
    }
    | FALSE
    {
        bool val = false;
        $$ = createConstantAttribute(BOOL_t, &val);
    }
    ;
%%

int yyerror(char *msg)
{
    fprintf(stderr, "\n|--------------------------------------------------------------------------\n");
    fprintf(stderr, "| Error found in Line #%d: %s\n", linenum, buf);
    fprintf(stderr, "|\n");
    fprintf(stderr, "| Unmatched token: %s\n", yytext);
    fprintf(stderr, "|--------------------------------------------------------------------------\n");
    exit(-1);
    // fprintf(stderr, "%s\t%d\t%s\t%s\n", "Error found in Line ", linenum, "next token: ", yytext);
}