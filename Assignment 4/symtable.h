#include"datatype.h"
int initSymTableList(struct SymTableList *list);
int destroySymTableList(struct SymTableList *list);
//

int AddSymTable(struct SymTableList *list);
struct SymTable* deleteSymTable(struct SymTable *target);
int deleteLastSymTable(struct SymTableList *list);
int insertTableNode(struct SymTable *table, struct SymTableNode *newNode);
//
struct SymTableNode* deleteTableNode(struct SymTableNode *target);
struct SymTableNode* createVariableNode(const char *name, int level, struct ExtType *type, int beenDef);
struct SymTableNode* createFunctionNode(const char *name, int level, struct ExtType *type, struct Attribute *attr, int beenDef);
struct SymTableNode* createConstNode(const char *name, int level, struct ExtType *type, struct Attribute *attr, int beenDef);
struct SymTableNode* createParameterNode(const char *name, int level, struct ExtType *type, int beenDef);
//
struct Attribute* createFunctionAttribute(struct FuncAttrNode *list);
struct Attribute* createConstantAttribute(BTYPE type, void *value);
struct FuncAttrNode* deleteFuncAttrNode(struct FuncAttrNode *target);
int killAttribute(struct Attribute *target);
struct FuncAttrNode* createFuncAttrNode(struct ExtType *type, const char *name);
int connectFuncAttrNode(struct FuncAttrNode *head, struct FuncAttrNode *newNode);
//
struct ExtType* createExtType(BTYPE baseType, bool isArray, struct ArrayDimNode *dimArray);
int killExtType(struct ExtType *target);
//
struct ArrayDimNode* createArrayDimNode(int size);
int connectArrayDimNode(struct ArrayDimNode *head, struct ArrayDimNode *newNode);
struct ArrayDimNode* deleteArrayDimNode(struct ArrayDimNode *target);
//
struct SymTableNode* findFuncDeclaration(struct SymTable *table, const char *name);
struct SymTableNode* findConstDeclaration(struct SymTable *table, const char *name);
struct SymTableNode* findVarDeclaration(struct SymTable *table, const char *name);
struct SymTableNode* findName(struct SymTable *table, const char *name);
int printSymTable(struct SymTable *table);
int printType(struct ExtType *extType);
int printConstAttribute(struct ConstAttr *constAttr);
int printParamAttribute(struct FuncAttr *funcAttr);

//
struct VariableList* createVariableList(struct Variable *head);
int deleteVariableList(struct VariableList *list);
int connectVariableList(struct VariableList *list, struct Variable *node);
struct Variable* createVariable(const char *name, struct ExtType *type);
struct Variable* deleteVariable(struct Variable *target);

int checkParam(struct FuncAttrNode *a, struct FuncAttrNode *b);
int checkAllFuncDef(struct SymTable *table);
struct ExpTypeNode* createExpTypeNode(struct ExtType *type, KIND kind);
void connectExpTypeNode(struct ExpTypeNode* head, struct ExpTypeNode* node);
struct ExpTypeNode* checkArithmeticType(struct ExpTypeNode *a, struct ExpTypeNode *b, int linenum);
struct ExpTypeNode* checkRelationType(struct ExpTypeNode *a, struct ExpTypeNode *b, int linenum);
struct ExpTypeNode* checkEqualType(struct ExpTypeNode *a, struct ExpTypeNode *b, int linenum);
struct ExpTypeNode* checkLogicalType(struct ExpTypeNode *a, struct ExpTypeNode *b, int linenum);
int checkCoercion(BTYPE a, BTYPE b);
int getElemNum(struct ArrayDimNode *dimArray);
int ErrMsg(char *msg, int linenum);