#include "header.h"

int trueIdx;
int falseIdx;

struct buf {
    int size;
    int num[32];
};
void pushBuf(int labelNum);
void popBuf();
void pushBuf_if(int labelNum);
void popBuf_if();

void genHeader();
void genGlobalVar(struct varDeclParam *ptr);
void genArithmeticOp(SEMTYPE L, SEMTYPE R, OPERATOR Op);
void genLogicalOp(SEMTYPE Op);
void genRelationalOp(SEMTYPE L, SEMTYPE R, OPERATOR Op);
void genVariableRef(struct SymNode *node);
void genNeg(SEMTYPE type);
void genStoreVar(struct SymNode *node, struct expr_sem *expr);
void genStoreInitVar(int ListIdx, struct PType *currentype, char *id, struct expr_sem *expr);
void genRead(struct SymNode *node);
void genPreparePrint();
void genPrint(struct expr_sem *node);

void genIfElse_if();
void genIfElse_else();
void genIf();
void genIfEnd();

void genWhileBegin();
void genWhile();
void genWhileEnd();

void genForBegin();
void genFor();
void genExecute();
void genIncrement();
void genForEnd();

void genFunctionHeader(struct SymTable *table, char *id);
void genReturn(SEMTYPE funcType, struct expr_sem *expr);
void genFunctionEnd();
void genFunctionEnd_void();
void genFunctionCall(struct SymTable *table, char *id);
void genCoercion(SEMTYPE paramType, SEMTYPE exprType);

void genContinue();
void genBreak();