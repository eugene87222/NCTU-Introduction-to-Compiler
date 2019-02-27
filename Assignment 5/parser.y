%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "header.h"
#include "symtab.h"
#include "semcheck.h"
#include "codegen.h"

extern int linenum;
extern FILE	*yyin;
extern char	*yytext;
extern char buf[256];
extern int Opt_Symbol;		/* declared in lex.l */

FILE *fpout;
int isEntryFunc = 1;
int isConstDecl = 0;
int VarIdx;
int labelIdx = 0;
int labelIdx_if = 0;
int IdListIdx = 0;
int inFor = 0;
int inWhile = 0;
int scope = 0;
int inloop = 0;
char fileName[256];
struct SymTable *symbolTable;
struct PType *funcReturn;
struct PType *currentType;
struct PTypeList *currentParamType;
__BOOLEAN paramError;
__BOOLEAN semError = __FALSE;

%}

%union {
    int intVal;
    float floatVal;	
    char *lexeme;
    struct idNode_sem *id;
    struct ConstAttr *constVal;
    struct PType *ptype;
    struct param_sem *par;
    struct expr_sem *exprs;
    struct expr_sem_node *exprNode;
    struct constParam *constNode;
    struct varDeclParam* varDeclNode;
};

%token	LE_OP NE_OP GE_OP EQ_OP AND_OP OR_OP
%token	READ BOOLEAN WHILE DO IF ELSE TRUE FALSE FOR INT PRINT BOOL VOID FLOAT DOUBLE STRING CONTINUE BREAK RETURN CONST
%token	L_PAREN R_PAREN COMMA SEMICOLON ML_BRACE MR_BRACE L_BRACE R_BRACE ADD_OP SUB_OP MUL_OP DIV_OP MOD_OP ASSIGN_OP LT_OP GT_OP NOT_OP

%token <lexeme>ID
%token <intVal>INT_CONST 
%token <floatVal>FLOAT_CONST
%token <floatVal>SCIENTIFIC
%token <lexeme>STR_CONST

%type<ptype> scalar_type dim
%type<par> array_decl parameter_list
%type<constVal> literal_const
%type<constNode> const_list 
%type<exprs> variable_reference logical_expression logical_term logical_factor relation_expression arithmetic_expression term factor logical_expression_list literal_list initial_array
%type<intVal> relation_operator add_op mul_op dimension
%type<varDeclNode> identifier_list


%start program
%%

program
    : decl_list funct_def decl_and_def_list 
    {
        checkUndefinedFunc(symbolTable);
        if(Opt_Symbol == 1)
            printSymTable(symbolTable, scope);	
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
        verifyEntryFunc();
        funcReturn = $1; 
        struct SymNode *node;
        node = findFuncDeclaration(symbolTable, $2);
        if(node != 0) {
            verifyFuncDeclaration(symbolTable, 0, $1, node);
        }
        else {
            insertFuncIntoSymTable(symbolTable, $2, 0, $1, scope, __TRUE);
        }
        genFunctionHeader(symbolTable, $2);
    } compound_statement
    {
        funcReturn = 0;
        genFunctionEnd();
        isEntryFunc = 0;
    }	
    | scalar_type ID L_PAREN parameter_list R_PAREN  
    {
        verifyEntryFunc();
        funcReturn = $1;
        paramError = checkFuncParam($4);
        if(paramError == __TRUE) {
            fprintf(stdout, "########## Error at Line#%d: param(s) with several fault!! ##########\n", linenum);
            semError = __TRUE;
        }
        // check and insert function into symbol table
        else {
            struct SymNode *node;
            node = findFuncDeclaration(symbolTable, $2);
            if(node != 0) {
                if(verifyFuncDeclaration(symbolTable, $4, $1, node) == __TRUE) {	
                    insertParamIntoSymTable(symbolTable, $4, scope+1);
                }				
            }
            else {
                insertParamIntoSymTable(symbolTable, $4, scope+1);				
                insertFuncIntoSymTable(symbolTable, $2, $4, $1, scope, __TRUE);
            }
        }
        genFunctionHeader(symbolTable, $2);
    } compound_statement
    {
        funcReturn = 0;
        genFunctionEnd();
        isEntryFunc = 0;
    }
    | VOID ID L_PAREN R_PAREN 
    {
        verifyEntryFunc();
        funcReturn = createPType(VOID_t); 
        struct SymNode *node;
        node = findFuncDeclaration(symbolTable, $2);
        if(node != 0) {
            verifyFuncDeclaration(symbolTable, 0, createPType(VOID_t), node);					
        }
        else {
            insertFuncIntoSymTable(symbolTable, $2, 0, createPType(VOID_t), scope, __TRUE);	
        }
        genFunctionHeader(symbolTable, $2);
    } compound_statement
    {
        funcReturn = 0;
        genFunctionEnd_void();
        isEntryFunc = 0;
    }	
    | VOID ID L_PAREN parameter_list R_PAREN
    {		
        verifyEntryFunc();		
        funcReturn = createPType(VOID_t);
        paramError = checkFuncParam($4);
        if(paramError == __TRUE) {
            fprintf(stdout, "########## Error at Line#%d: param(s) with several fault!! ##########\n", linenum);
            semError = __TRUE;
        }
        // check and insert function into symbol table
        else {
            struct SymNode *node;
            node = findFuncDeclaration(symbolTable, $2);
            if(node != 0) {
                if(verifyFuncDeclaration(symbolTable, $4, createPType(VOID_t), node) == __TRUE) {	
                    insertParamIntoSymTable(symbolTable, $4, scope+1);				
                }
            }
            else {
                insertParamIntoSymTable(symbolTable, $4, scope+1);				
                insertFuncIntoSymTable(symbolTable, $2, $4, createPType(VOID_t), scope, __TRUE);
            }
        }
        genFunctionHeader(symbolTable, $2);
    } compound_statement
    {
        funcReturn = 0;
        genFunctionEnd_void();
        isEntryFunc = 0;
    }
    ;

funct_decl
    : scalar_type ID L_PAREN R_PAREN SEMICOLON
    {
        insertFuncIntoSymTable(symbolTable, $2, 0, $1, scope, __FALSE);	
    }
    | scalar_type ID L_PAREN parameter_list R_PAREN SEMICOLON
    {
        paramError = checkFuncParam($4);
        if(paramError == __TRUE) {
            fprintf(stdout, "########## Error at Line#%d: param(s) with several fault!! ##########\n", linenum);
            semError = __TRUE;
        }
        else {
            insertFuncIntoSymTable(symbolTable, $2, $4, $1, scope, __FALSE);
        }
    }
    | VOID ID L_PAREN R_PAREN SEMICOLON
    {				
        insertFuncIntoSymTable(symbolTable, $2, 0, createPType(VOID_t), scope, __FALSE);
    }
    | VOID ID L_PAREN parameter_list R_PAREN SEMICOLON
    {
        paramError = checkFuncParam($4);
        if(paramError == __TRUE) {
            fprintf(stdout, "########## Error at Line#%d: param(s) with several fault!! ##########\n", linenum);
            semError = __TRUE;	
        }
        else {
            insertFuncIntoSymTable(symbolTable, $2, $4, createPType(VOID_t), scope, __FALSE);
        }
    }
    ;

parameter_list
    : parameter_list COMMA scalar_type ID
    {
        struct param_sem *ptr;
        ptr = createParam(createIdList($4), $3);
        param_sem_addParam($1, ptr);
        $$ = $1;
    }
    | parameter_list COMMA scalar_type array_decl
    {
        $4->pType->type= $3->type;
        param_sem_addParam($1, $4);
        $$ = $1;
    }
    | scalar_type array_decl 
    { 
        $2->pType->type = $1->type;  
        $$ = $2;
    }
    | scalar_type ID { $$ = createParam(createIdList($2), $1); }
    ;

var_decl
    : scalar_type identifier_list SEMICOLON
    {
        struct varDeclParam *ptr;
        struct SymNode *newNode;
        for(ptr = $2; ptr != 0; ptr = (ptr->next)) {						
            if(verifyRedeclaration(symbolTable, ptr->para->idlist->value, scope) == __FALSE) {}
            else {
                if(verifyVarInitValue($1, ptr, symbolTable, scope) ==  __TRUE) {	
                    newNode = createVarNode(ptr->para->idlist->value, scope, ptr->para->pType);
                    insertTab(symbolTable, newNode);
                    if(!ptr->para->pType->isArray) {
                        genGlobalVar(ptr);
                    }
                }
            }
        }
        IdListIdx = 0;
    }
    ;

identifier_list
    : identifier_list COMMA ID
    {					
        struct param_sem *ptr;	
        struct varDeclParam *vptr;				
        ptr = createParam(createIdList($3), createPType(VOID_t));
        vptr = createVarDeclParam(ptr, 0);	
        addVarDeclParam($1, vptr);
        $$ = $1;
        if(currentType->type == DOUBLE_t) IdListIdx++;
        IdListIdx++;
    }
    | identifier_list COMMA ID ASSIGN_OP logical_expression
    {
        struct param_sem *ptr;	
        struct varDeclParam *vptr;
        ptr = createParam(createIdList($3), createPType(VOID_t));
        vptr = createVarDeclParam(ptr, $5);
        vptr->isArray = __TRUE;
        vptr->isInit = __TRUE;	
        addVarDeclParam($1, vptr);	
        $$ = $1;
        genStoreInitVar(IdListIdx, currentType, $3, $5);
        if(currentType->type == DOUBLE_t) IdListIdx++;
        IdListIdx++;
    }
    | identifier_list COMMA array_decl ASSIGN_OP initial_array
    {
        struct varDeclParam *ptr;
        ptr = createVarDeclParam($3, $5);
        ptr->isArray = __TRUE;
        ptr->isInit = __TRUE;
        addVarDeclParam($1, ptr);
        $$ = $1;	
    }
    | identifier_list COMMA array_decl
    {
        struct varDeclParam *ptr;
        ptr = createVarDeclParam($3, 0);
        ptr->isArray = __TRUE;
        addVarDeclParam($1, ptr);
        $$ = $1;
    }
    | array_decl ASSIGN_OP initial_array
    {	
        $$ = createVarDeclParam($1 , $3);
        $$->isArray = __TRUE;
        $$->isInit = __TRUE;	
    }
    | array_decl 
    { 
        $$ = createVarDeclParam($1 , 0); 
        $$->isArray = __TRUE;
    }
    | ID ASSIGN_OP logical_expression
    {
        struct param_sem *ptr;					
        ptr = createParam(createIdList($1), createPType(VOID_t));
        $$ = createVarDeclParam(ptr, $3);		
        $$->isInit = __TRUE;
        genStoreInitVar(IdListIdx, currentType, $1, $3);
        if(currentType->type == DOUBLE_t) IdListIdx++;
        IdListIdx++;
    }
    | ID 
    {
        struct param_sem *ptr;					
        ptr = createParam(createIdList($1), createPType(VOID_t));
        $$ = createVarDeclParam(ptr, 0);
        if(currentType->type == DOUBLE_t) IdListIdx++;
        IdListIdx++;		
    }
    ;
         
initial_array
    : L_BRACE literal_list R_BRACE { $$ = $2; }
    ;

literal_list
    : literal_list COMMA logical_expression
    {
        struct expr_sem *ptr;
        for(ptr = $1; (ptr->next) != 0; ptr = (ptr->next));
        ptr->next = $3;
        $$ = $1;
    }
    | logical_expression
    {
        $$ = $1;
    }
    |
    ;

const_decl
    : CONST { isConstDecl = 1; } scalar_type const_list SEMICOLON { isConstDecl = 0; }
    {
        struct SymNode *newNode;				
        struct constParam *ptr;
        for(ptr = $4; ptr != 0; ptr = (ptr->next)) {
            if(verifyRedeclaration(symbolTable, ptr->name, scope) == __TRUE) {//no redeclare
                if(ptr->value->category != $3->type) {//type different
                    if(!(($3->type == FLOAT_t || $3->type == DOUBLE_t) && ptr->value->category == INTEGER_t)) {
                        if(!($3->type == DOUBLE_t && ptr->value->category == FLOAT_t)) {	
                            fprintf(stdout, "########## Error at Line#%d: const type different!! ##########\n", linenum);
                            semError = __TRUE;	
                        }
                        else {
                            newNode = createConstNode(ptr->name, scope, $3, ptr->value);
                            insertTab(symbolTable, newNode);
                        }
                    }							
                    else {
                        newNode = createConstNode(ptr->name, scope, $3, ptr->value);
                        insertTab(symbolTable, newNode);
                    }
                }
                else {
                    newNode = createConstNode(ptr->name, scope, $3, ptr->value);
                    insertTab(symbolTable, newNode);
                }
            }
        }
    }
    ;

const_list
    : const_list COMMA ID ASSIGN_OP literal_const
    {				
        addConstParam($1, createConstParam($5, $3));
        $$ = $1;
    }
    | ID ASSIGN_OP literal_const
    {
        $$ = createConstParam($3, $1);	
    }
    ;

array_decl
    : ID dim 
    {
        $$ = createParam(createIdList($1), $2);
    }
    ;

dim
    : dim ML_BRACE INT_CONST MR_BRACE
    {
        if($3 == 0) {
            fprintf(stdout, "########## Error at Line#%d: array size error!! ##########\n", linenum);
            semError = __TRUE;
        }
        else
            increaseArrayDim($1, 0, $3);			
        }
    | ML_BRACE INT_CONST MR_BRACE	
    {
        if($2 == 0) {
            fprintf(stdout, "########## Error at Line#%d: array size error!! ##########\n", linenum);
            semError = __TRUE;
        }			
        else {	
            $$ = createPType(VOID_t); 			
            increaseArrayDim($$, 0, $2);
        }		
    }
    ;
    
compound_statement
    : {scope++;} L_BRACE var_const_stmt_list R_BRACE
    { 
        // print contents of current scope
        if(Opt_Symbol == 1)
            printSymTable(symbolTable, scope);        
        deleteScope(symbolTable, scope);	// leave this scope, delete...
        scope--;
    }
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
    {
        // check if LHS exists
        __BOOLEAN flagLHS = verifyExistence(symbolTable, $1, scope, __TRUE);
        // id RHS is not dereferenced, check and deference
        __BOOLEAN flagRHS = __TRUE;
        if($3->isDeref == __FALSE) {
            flagRHS = verifyExistence(symbolTable, $3, scope, __FALSE);
        }
        // if both LHS and RHS are exists, verify their type
        if(flagLHS==__TRUE && flagRHS==__TRUE)
            verifyAssignmentTypeMatch($1, $3);
        if($1->pType->type != ERROR_t) {
            struct SymNode *node = lookupSymbol(symbolTable, $1->varRef->id, scope, __FALSE);
            genStoreVar(node, $3);
        }
    }
    | PRINT { genPreparePrint(); } logical_expression SEMICOLON 
    { 
        if(verifyScalarExpr($3, "print") == __TRUE) {
            genPrint($3);
        }
    }
    | READ variable_reference SEMICOLON
    { 
        if(verifyExistence(symbolTable, $2, scope, __TRUE) == __TRUE)						
            if(verifyScalarExpr($2, "read") == __TRUE) {
                struct SymNode *node = lookupSymbol(symbolTable, $2->varRef->id, scope, __FALSE);
                genRead(node);
            }
    }
    ;

conditional_statement
    : IF L_PAREN conditional_if R_PAREN compound_statement if_continute ;

conditional_if
    : logical_expression 
    {
        verifyBooleanExpr($1, "if");
        pushBuf_if(labelIdx_if);
        labelIdx_if++;
        genIfElse_if();
    };

if_continute
    : ELSE { genIfElse_else(); } compound_statement { genIfEnd(); popBuf_if(); }
    | { genIf(); popBuf_if(); }
    ;

while_statement
    : WHILE L_PAREN
    {
        pushBuf(labelIdx);
        labelIdx++;
        genWhileBegin();
        inWhile = 1;
        inFor = 0;
    } logical_expression
    {
        verifyBooleanExpr($4, "while");
        genWhile();
    } R_PAREN { inloop++; }
    compound_statement
    {
        inloop--;
        genWhileEnd();
        popBuf();
        inWhile = 0;
        inFor = 0;
    }
    | { inloop++; } DO 
    { 
        pushBuf(labelIdx); 
        labelIdx++;
        genWhileBegin();
        inWhile = 1;
        inFor = 0;
    } compound_statement WHILE L_PAREN logical_expression R_PAREN SEMICOLON  
    { 
        verifyBooleanExpr($7, "while");
        inloop--; 
        genWhile();
        genWhileEnd();
        popBuf();
        inWhile = 0;
        inFor = 0;
    }
    ;
                
for_statement
    : FOR 
    {
        pushBuf(labelIdx);
        labelIdx++;
        inWhile = 0;
        inFor = 1;
    } L_PAREN initial_expression { genForBegin(); } 
    SEMICOLON control_expression { genFor(); } SEMICOLON increment_expression R_PAREN { inloop++; genIncrement(); genExecute(); }
    compound_statement { inloop--; genForEnd(); popBuf(); inWhile = 0; inFor = 0; }
    ;

initial_expression
    : initial_expression COMMA statement_for
    | initial_expression COMMA logical_expression
    | logical_expression	
    | statement_for
    |
    ;

control_expression
    : control_expression COMMA statement_for
    {
        fprintf(stdout, "########## Error at Line#%d: control_expression is not boolean type ##########\n", linenum);
        semError = __TRUE;
    }
    | control_expression COMMA logical_expression
    {
        if($3->pType->type != BOOLEAN_t) {
            fprintf(stdout, "########## Error at Line#%d: control_expression is not boolean type ##########\n", linenum);
            semError = __TRUE;	
        }
    }
    | logical_expression 
    { 
        if($1->pType->type != BOOLEAN_t) {
            fprintf(stdout, "########## Error at Line#%d: control_expression is not boolean type ##########\n", linenum);
            semError = __TRUE;	
        }
    }
    | statement_for
    {
        fprintf(stdout, "########## Error at Line#%d: control_expression is not boolean type ##########\n", linenum);
        semError = __TRUE;	
    }
    |
    ;

increment_expression
    : increment_expression COMMA statement_for
    | increment_expression COMMA logical_expression
    | logical_expression
    | statement_for
    |
    ;

statement_for
    : variable_reference ASSIGN_OP logical_expression
    {
        // check if LHS exists
        __BOOLEAN flagLHS = verifyExistence(symbolTable, $1, scope, __TRUE);
        // id RHS is not dereferenced, check and deference
        __BOOLEAN flagRHS = __TRUE;
        if($3->isDeref == __FALSE) {
            flagRHS = verifyExistence(symbolTable, $3, scope, __FALSE);
        }
        // if both LHS and RHS are exists, verify their type
        if(flagLHS==__TRUE && flagRHS==__TRUE)
            verifyAssignmentTypeMatch($1, $3);
        if($1->pType->type != ERROR_t) {
            struct SymNode *node = lookupSymbol(symbolTable, $1->varRef->id, scope, __FALSE);
            genStoreVar(node, $3);
        }
    }
    ;
                                      
function_invoke_statement
    : ID L_PAREN 
    {
        struct SymNode *node = lookupSymbol(symbolTable, $1, 0, __FALSE);
        if(node == 0) {}
        else if(node->category != FUNCTION_t) {}
        else {
            if(node->attribute->formalParam->paramNum == 0) {
                currentParamType = 0;
            }
            else {
                currentParamType = node->attribute->formalParam->params;
            }
        }
    } logical_expression_list R_PAREN SEMICOLON
    {
        struct expr_sem *tmp = verifyFuncInvoke($1, $4, symbolTable, scope);
        if(tmp->pType->type != ERROR_t) {
            genFunctionCall(symbolTable, $1);
            struct SymNode *node = lookupSymbol(symbolTable, $1, 0, __FALSE);
            if(node->type != VOID_t) fprintf(fpout, "\tpop\n");
        }
        currentParamType = 0;
    }
    | ID L_PAREN R_PAREN SEMICOLON
    {
        struct expr_sem *tmp = verifyFuncInvoke($1, 0, symbolTable, scope);
        if(tmp->pType->type != ERROR_t) {
            genFunctionCall(symbolTable, $1);
            struct SymNode *node = lookupSymbol(symbolTable, $1, 0, __FALSE);
            if(node->type != VOID_t) fprintf(fpout, "\tpop\n");
        }
    }
    ;

jump_statement
    : CONTINUE SEMICOLON
    {
        if(inloop <= 0){
            fprintf(stdout, "########## Error at Line#%d: continue can't appear outside of loop ##########\n", linenum); semError = __TRUE;
        }
        else {
            genContinue();
        }
    }
    | BREAK SEMICOLON 
    {
        if(inloop <= 0) {
            fprintf(stdout, "########## Error at Line#%d: break can't appear outside of loop ##########\n", linenum); semError = __TRUE;
        }
        else {
            genBreak();
        }
    }
    | RETURN logical_expression SEMICOLON
    {
        if(verifyReturnStatement($2, funcReturn)) genReturn(funcReturn->type, $2);
    }
    ;

variable_reference
    : ID
    {
        $$ = createExprSem($1);
    }
    | variable_reference dimension
    {	
        increaseDim($1, $2);
        $$ = $1;
    }
    ;

dimension
    : ML_BRACE arithmetic_expression MR_BRACE
    {
        $$ = verifyArrayIndex($2);
    }
    ;
          
logical_expression
    : logical_expression OR_OP logical_term
    {
        verifyAndOrOp($1, OR_t, $3);
        $$ = $1;
        if($1->pType->type != ERROR_t) genLogicalOp(OR_t);
    }
    | logical_term { $$ = $1; }
    ;

logical_term
    : logical_term AND_OP logical_factor
    {
        verifyAndOrOp($1, AND_t, $3);
        $$ = $1;
        if($1->pType->type != ERROR_t) genLogicalOp(AND_t);
    }
    | logical_factor { $$ = $1; }
    ;

logical_factor
    : NOT_OP logical_factor
    {
        verifyUnaryNot($2);
        $$ = $2;
        if($2->pType->type != ERROR_t) genLogicalOp(NOT_t);
    }
    | relation_expression { $$ = $1; }
    ;

relation_expression
    : arithmetic_expression relation_operator arithmetic_expression
    {
        SEMTYPE L = $1->pType->type, R = $3->pType->type;
        verifyRelOp($1, $2, $3);
        $$ = $1;
        if($1->pType->type != ERROR_t) genRelationalOp(L, R, $2);
    }
    | arithmetic_expression { $$ = $1; }
    ;

relation_operator
    : LT_OP { $$ = LT_t; }
    | LE_OP { $$ = LE_t; }
    | EQ_OP { $$ = EQ_t; }
    | GE_OP { $$ = GE_t; }
    | GT_OP { $$ = GT_t; }
    | NE_OP { $$ = NE_t; }
    ;

arithmetic_expression
    : arithmetic_expression add_op term
    {
        SEMTYPE L = $1->pType->type, R = $3->pType->type;
        verifyArithmeticOp($1, $2, $3);
        $$ = $1;
        if($1->pType->type != ERROR_t) genArithmeticOp(L, R, $2);
    }
    | relation_expression { $$ = $1; }
    | term { $$ = $1; }
    ;

add_op
    : ADD_OP { $$ = ADD_t; }
    | SUB_OP { $$ = SUB_t; }
    ;
           
term
    : term mul_op factor
    {
        if($2 == MOD_t) {
            SEMTYPE L = $1->pType->type, R = $3->pType->type;
            verifyModOp($1, $3);
            if($1->pType->type != ERROR_t) genArithmeticOp(L, R, $2);
        }
        else {
            SEMTYPE L = $1->pType->type, R = $3->pType->type;
            verifyArithmeticOp($1, $2, $3);
            if($1->pType->type != ERROR_t) genArithmeticOp(L, R, $2);
        }
        $$ = $1;
    }
    | factor { $$ = $1; }
    ;

mul_op
    : MUL_OP { $$ = MUL_t; }
    | DIV_OP { $$ = DIV_t; }
    | MOD_OP { $$ = MOD_t; }
    ;
        
factor
    : variable_reference
    {
        verifyExistence(symbolTable, $1, scope, __FALSE);
        $$ = $1;
        $$->beginningOp = NONE_t;
        if($1->pType->type != ERROR_t) {
            struct SymNode *node = lookupSymbol(symbolTable, $1->varRef->id, scope, __FALSE);
            genVariableRef(node);
        }
    }
    | SUB_OP variable_reference
    {
        if(verifyExistence(symbolTable, $2, scope, __FALSE) == __TRUE)
        verifyUnaryMinus($2);
        $$ = $2;
        $$->beginningOp = SUB_t;
        if($2->pType->type != ERROR_t) {
            struct SymNode *node = lookupSymbol(symbolTable, $2->varRef->id, scope, __FALSE);
            genVariableRef(node);
            genNeg(node->type->type);
        }
    }		
    | L_PAREN logical_expression R_PAREN
    {
        $2->beginningOp = NONE_t;
        $$ = $2; 
    }
    | SUB_OP L_PAREN logical_expression R_PAREN
    {
        verifyUnaryMinus($3);
        $$ = $3;
        $$->beginningOp = SUB_t;
        if($3->pType->type != ERROR_t) {
            genNeg($3->pType->type);
        }
    }
    | ID L_PAREN 
    {
        struct SymNode *node = lookupSymbol(symbolTable, $1, 0, __FALSE);
        if(node == 0) {}
        else if(node->category != FUNCTION_t) {}
        else {
            if(node->attribute->formalParam->paramNum == 0) {
                currentParamType = 0;
            }
            else {
                currentParamType = node->attribute->formalParam->params;
            }
        }
    } logical_expression_list R_PAREN
    {
        $$ = verifyFuncInvoke($1, $4, symbolTable, scope);
        $$->beginningOp = NONE_t;
        if($$->pType->type != ERROR_t) {
            genFunctionCall(symbolTable, $1);
        }
        currentParamType = 0;
    }
    | SUB_OP ID L_PAREN 
    {
        struct SymNode *node = lookupSymbol(symbolTable, $2, 0, __FALSE);
        if(node == 0) {}
        else if(node->category != FUNCTION_t) {}
        else {
            if(node->attribute->formalParam->paramNum == 0) {
                currentParamType = 0;
            }
            else {
                currentParamType = node->attribute->formalParam->params;
            }
        }  
    } logical_expression_list R_PAREN
    {
        $$ = verifyFuncInvoke($2, $5, symbolTable, scope);
        $$->beginningOp = SUB_t;
        if($$->pType->type != ERROR_t) {
            genFunctionCall(symbolTable, $2);
            struct SymNode *node = lookupSymbol(symbolTable, $2, 0, __FALSE);
            genNeg(node->type->type);
        }
        currentParamType = 0;
    }
    | ID L_PAREN R_PAREN
    {
        $$ = verifyFuncInvoke($1, 0, symbolTable, scope);
        $$->beginningOp = NONE_t;
        if($$->pType->type != ERROR_t) {
            genFunctionCall(symbolTable, $1);
        }
    }
    | SUB_OP ID L_PAREN R_PAREN
    {
        $$ = verifyFuncInvoke($2, 0, symbolTable, scope);
        $$->beginningOp = SUB_OP;
        if($$->pType->type != ERROR_t) {
            genFunctionCall(symbolTable, $2);
        }
    }
    | literal_const
    {
        $$ = (struct expr_sem *)malloc(sizeof(struct expr_sem));
        $$->isDeref = __TRUE;
        $$->varRef = 0;
        $$->pType = createPType($1->category);
        $$->next = 0;
        if($1->hasMinus == __TRUE) {
            $$->beginningOp = SUB_t;
        }
        else {
            $$->beginningOp = NONE_t;
        }
    }
    ;

logical_expression_list
    : logical_expression_list COMMA logical_expression
    {
        struct expr_sem *exprPtr;
        for(exprPtr = $1; (exprPtr->next) != 0; exprPtr = (exprPtr->next));
        exprPtr->next = $3;
        $$ = $1;
        if(currentParamType != 0) {
            genCoercion(currentParamType->value->type, $3->pType->type);
            if(currentParamType->next != 0) {
                currentParamType = currentParamType->next;
            }
        }
    }
    | logical_expression 
    { 
        $$ = $1; 
        if(currentParamType != 0) {
            genCoercion(currentParamType->value->type, $1->pType->type);
            if(currentParamType->next != 0) {
                currentParamType = currentParamType->next;
            }
        }
    }
    ;

scalar_type
    : INT { $$ = createPType(INTEGER_t); currentType = $$; }
    | DOUBLE { $$ = createPType(DOUBLE_t); currentType = $$; }
    | STRING { $$ = createPType(STRING_t); currentType = $$; }
    | BOOL { $$ = createPType(BOOLEAN_t); currentType = $$; }
    | FLOAT { $$ = createPType(FLOAT_t); currentType = $$; }
    ;
 
literal_const
    : INT_CONST
    {
        int tmp = $1;
        $$ = createConstAttr(INTEGER_t, &tmp);
        if(!isConstDecl) fprintf(fpout, "\tldc %d\n", tmp);
    }
    | SUB_OP INT_CONST
    {
        int tmp = -$2;
        $$ = createConstAttr(INTEGER_t, &tmp);
        if(!isConstDecl) fprintf(fpout, "\tldc %d\n", tmp);
    }
    | FLOAT_CONST
    {
        float tmp = $1;
        $$ = createConstAttr(FLOAT_t, &tmp);
        if(!isConstDecl) fprintf(fpout, "\tldc %f\n", tmp);
    }
    | SUB_OP FLOAT_CONST
    {
        float tmp = -$2;
        $$ = createConstAttr(FLOAT_t, &tmp);
        if(!isConstDecl) fprintf(fpout, "\tldc %f\n", tmp);
    }
    | SCIENTIFIC
    {
        double tmp = $1;
        $$ = createConstAttr(DOUBLE_t, &tmp);
        if(!isConstDecl) fprintf(fpout, "\tldc %f\n", tmp);
    }
    | SUB_OP SCIENTIFIC
    {
        double tmp = -$2;
        $$ = createConstAttr(DOUBLE_t, &tmp);
        if(!isConstDecl) fprintf(fpout, "\tldc %f\n", tmp);
    }
    | STR_CONST
    {
        $$ = createConstAttr(STRING_t, $1);
        if(!isConstDecl) {
            fprintf(fpout, "\tldc \"");
            int i = 0;
            for(; i < strlen($1); i++) {
                if($1[i] == '"')
                    fprintf(fpout, "\\");
                fprintf(fpout, "%c", $1[i]);
            }
            fprintf(fpout, "\"\n");
        }
    }
    | TRUE
    {
        SEMTYPE tmp = __TRUE;
        $$ = createConstAttr(BOOLEAN_t, &tmp);
        if(!isConstDecl) fprintf(fpout, "\ticonst_1\n");
    }
    | FALSE
    {
        SEMTYPE tmp = __FALSE;
        $$ = createConstAttr(BOOLEAN_t, &tmp);
        if(!isConstDecl) fprintf(fpout, "\ticonst_0\n");
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
}