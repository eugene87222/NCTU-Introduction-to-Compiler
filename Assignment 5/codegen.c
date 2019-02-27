#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "codegen.h"
#include "symtab.h"
#include "semcheck.h"

extern FILE *fpout;
extern int scope;
extern struct buf *labelNumBuf;
extern struct buf *labelNumBuf_if;
extern int isEntryFunc;
extern int VarIdx;
extern int inWhile;
extern int inFor;

void pushBuf(int labelNum) {
    labelNumBuf->num[labelNumBuf->size] = labelNum;
    labelNumBuf->size++;
}

void popBuf() {
    labelNumBuf->size--;
}

void pushBuf_if(int labelNum) {
    labelNumBuf_if->num[labelNumBuf->size] = labelNum;
    labelNumBuf_if->size++;
}

void popBuf_if() {
    labelNumBuf_if->size--;
}

void genHeader() {
    trueIdx = 0;
    falseIdx = 0;
	fprintf(fpout, ".class public output\n");
    fprintf(fpout, ".super java/lang/Object\n");
    fprintf(fpout, ".field public static _sc Ljava/util/Scanner;\n");
}

void genGlobalVar(struct varDeclParam *ptr) {
    if(scope == 0) {
        if(ptr->para->pType->type == INTEGER_t)
            fprintf(fpout, ".field public static %s I\n", ptr->para->idlist->value);
        else if(ptr->para->pType->type == BOOLEAN_t)
            fprintf(fpout, ".field public static %s Z\n", ptr->para->idlist->value);
        else if(ptr->para->pType->type == FLOAT_t)
            fprintf(fpout, ".field public static %s F\n", ptr->para->idlist->value);
        else if(ptr->para->pType->type == DOUBLE_t)
            fprintf(fpout, ".field public static %s D\n", ptr->para->idlist->value);
    }
}

void genArithmeticOp(SEMTYPE L, SEMTYPE R, OPERATOR Op) {
    if(Op == ADD_t) {
        if(L == INTEGER_t && R == INTEGER_t) {
            fprintf(fpout, "\tiadd\n");
        }
        else if(L == FLOAT_t && R == INTEGER_t) {
            fprintf(fpout, "\ti2f\n");
            fprintf(fpout, "\tfadd\n");
        }
        else if(L == DOUBLE_t && R == INTEGER_t) {
            fprintf(fpout, "\ti2d\n");
            fprintf(fpout, "\tdadd\n");
        }
        else if(L == INTEGER_t && R == FLOAT_t) {
            fprintf(fpout, "\tfstore 98\n");
            fprintf(fpout, "\ti2f\n");
            fprintf(fpout, "\tfload 98\n");
            fprintf(fpout, "\tfadd\n");
        }
        else if(L == INTEGER_t && R == DOUBLE_t) {
            fprintf(fpout, "\tdstore 98\n");
            fprintf(fpout, "\ti2d\n");
            fprintf(fpout, "\tdload 98\n");
            fprintf(fpout, "\tdadd\n");
        }
        else if(L == FLOAT_t && R == FLOAT_t) {
            fprintf(fpout, "\tfadd\n");
        }
        else if(L == FLOAT_t && R == DOUBLE_t) {
            fprintf(fpout, "\tdstore 98\n");
            fprintf(fpout, "\tf2d\n");
            fprintf(fpout, "\tdload 98\n");
            fprintf(fpout, "\tdadd\n");
        }
        else if(L == DOUBLE_t && R == FLOAT_t) {
            fprintf(fpout, "\tf2d\n");
            fprintf(fpout, "\tdadd\n");
        }
        else if(L == DOUBLE_t && R == DOUBLE_t) {
            fprintf(fpout, "\tdadd\n");
        }
    }
    else if(Op == SUB_t) {
        if(L == INTEGER_t && R == INTEGER_t) {
            fprintf(fpout, "\tisub\n");
        }
        else if(L == FLOAT_t && R == INTEGER_t) {
            fprintf(fpout, "\ti2f\n");
            fprintf(fpout, "\tfsub\n");
        }
        else if(L == DOUBLE_t && R == INTEGER_t) {
            fprintf(fpout, "\ti2d\n");
            fprintf(fpout, "\tdsub\n");
        }
        else if(L == INTEGER_t && R == FLOAT_t) {
            fprintf(fpout, "\tfstore 98\n");
            fprintf(fpout, "\ti2f\n");
            fprintf(fpout, "\tfload 98\n");
            fprintf(fpout, "\tfsub\n");
        }
        else if(L == INTEGER_t && R == DOUBLE_t) {
            fprintf(fpout, "\tdstore 98\n");
            fprintf(fpout, "\ti2d\n");
            fprintf(fpout, "\tdload 98\n");
            fprintf(fpout, "\tdsub\n");
        }
        else if(L == FLOAT_t && R == FLOAT_t) {
            fprintf(fpout, "\tfsub\n");
        }
        else if(L == FLOAT_t && R == DOUBLE_t) {
            fprintf(fpout, "\tdstore 98\n");
            fprintf(fpout, "\tf2d\n");
            fprintf(fpout, "\tdload 98\n");
            fprintf(fpout, "\tdsub\n");
        }
        else if(L == DOUBLE_t && R == FLOAT_t) {
            fprintf(fpout, "\tf2d\n");
            fprintf(fpout, "\tdsub\n");
        }
        else if(L == DOUBLE_t && R == DOUBLE_t) {
            fprintf(fpout, "\tdsub\n");
        }
    }
    else if(Op == MUL_t) {
        if(L == INTEGER_t && R == INTEGER_t) {
            fprintf(fpout, "\timul\n");
        }
        else if(L == FLOAT_t && R == INTEGER_t) {
            fprintf(fpout, "\ti2f\n");
            fprintf(fpout, "\tfmul\n");
        }
        else if(L == DOUBLE_t && R == INTEGER_t) {
            fprintf(fpout, "\ti2d\n");
            fprintf(fpout, "\tdmul\n");
        }
        else if(L == INTEGER_t && R == FLOAT_t) {
            fprintf(fpout, "\tfstore 98\n");
            fprintf(fpout, "\ti2f\n");
            fprintf(fpout, "\tfload 98\n");
            fprintf(fpout, "\tfmul\n");
        }
        else if(L == INTEGER_t && R == DOUBLE_t) {
            fprintf(fpout, "\tdstore 98\n");
            fprintf(fpout, "\ti2d\n");
            fprintf(fpout, "\tdload 98\n");
            fprintf(fpout, "\tdmul\n");
        }
        else if(L == FLOAT_t && R == FLOAT_t) {
            fprintf(fpout, "\tfmul\n");
        }
        else if(L == FLOAT_t && R == DOUBLE_t) {
            fprintf(fpout, "\tdstore 98\n");
            fprintf(fpout, "\tf2d\n");
            fprintf(fpout, "\tdload 98\n");
            fprintf(fpout, "\tdmul\n");
        }
        else if(L == DOUBLE_t && R == FLOAT_t) {
            fprintf(fpout, "\tf2d\n");
            fprintf(fpout, "\tdmul\n");
        }
        else if(L == DOUBLE_t && R == DOUBLE_t) {
            fprintf(fpout, "\tdmul\n");
        }
    }
    else if(Op == DIV_t) {
        if(L == INTEGER_t && R == INTEGER_t) {
            fprintf(fpout, "\tidiv\n");
        }
        else if(L == FLOAT_t && R == INTEGER_t) {
            fprintf(fpout, "\ti2f\n");
            fprintf(fpout, "\tfdiv\n");
        }
        else if(L == DOUBLE_t && R == INTEGER_t) {
            fprintf(fpout, "\ti2d\n");
            fprintf(fpout, "\tddiv\n");
        }
        else if(L == INTEGER_t && R == FLOAT_t) {
            fprintf(fpout, "\tfstore 98\n");
            fprintf(fpout, "\ti2f\n");
            fprintf(fpout, "\tfload 98\n");
            fprintf(fpout, "\tfdiv\n");
        }
        else if(L == INTEGER_t && R == DOUBLE_t) {
            fprintf(fpout, "\tdstore 98\n");
            fprintf(fpout, "\ti2d\n");
            fprintf(fpout, "\tdload 98\n");
            fprintf(fpout, "\tddiv\n");
        }
        else if(L == FLOAT_t && R == FLOAT_t) {
            fprintf(fpout, "\tfdiv\n");
        }
        else if(L == FLOAT_t && R == DOUBLE_t) {
            fprintf(fpout, "\tdstore 98\n");
            fprintf(fpout, "\tf2d\n");
            fprintf(fpout, "\tdload 98\n");
            fprintf(fpout, "\tddiv\n");
        }
        else if(L == DOUBLE_t && R == FLOAT_t) {
            fprintf(fpout, "\tf2d\n");
            fprintf(fpout, "\tddiv\n");
        }
        else if(L == DOUBLE_t && R == DOUBLE_t) {
            fprintf(fpout, "\tddiv\n");
        }
    }
    else if(Op == MOD_t) {
        fprintf(fpout, "\tirem\n");
    }
}

void genLogicalOp(SEMTYPE Op) {
    if(Op == NOT_t) {
        fprintf(fpout, "\tldc 1\n");
        fprintf(fpout, "\tixor\n");
    }
	else if(Op == OR_t) fprintf(fpout, "\tior\n");
	else if(Op == AND_t) fprintf(fpout, "\tiand\n");
}

void genRelationalOp(SEMTYPE L, SEMTYPE R, OPERATOR Op) {
    if(L == INTEGER_t && R == INTEGER_t) fprintf(fpout, "\tisub\n");
    else if(L == FLOAT_t && R == INTEGER_t) {
        fprintf(fpout, "\tisub\n");
    }
    else if(L == FLOAT_t && R == INTEGER_t) {
        fprintf(fpout, "\ti2f\n");
        fprintf(fpout, "\tfcmpl\n");
    }
    else if(L == INTEGER_t && R == FLOAT_t) {
        fprintf(fpout, "\tfstore 98\n");
        fprintf(fpout, "\ti2f\n");
        fprintf(fpout, "\tfload 98\n");
        fprintf(fpout, "\tfcmpl\n");
    }
    else if(L == DOUBLE_t && R == INTEGER_t) {
        fprintf(fpout, "\ti2d\n");
        fprintf(fpout, "\tdcmpl\n");
    }
    else if(L == INTEGER_t && R == DOUBLE_t) {
        fprintf(fpout, "\tdstore 98\n");
        fprintf(fpout, "\ti2d\n");
        fprintf(fpout, "\tdload 98\n");
        fprintf(fpout, "\tdcmpl\n");
    }
    else if(L == FLOAT_t && R == FLOAT_t) {
        fprintf(fpout, "\tfcmpl\n");
    }
    else if(L == DOUBLE_t && R == FLOAT_t) {
        fprintf(fpout, "\tf2d\n");
        fprintf(fpout, "\tdcmpl\n");
    }
    else if(L == FLOAT_t && R == DOUBLE_t) {
        fprintf(fpout, "\tdstore 98\n");
        fprintf(fpout, "\tf2d\n");
        fprintf(fpout, "\tdload 98\n");
        fprintf(fpout, "\tdcmpl\n");
    }
    else if(L == DOUBLE_t && R == DOUBLE_t) {
        fprintf(fpout, "\tdcmpl\n");
    }

	if(Op == LT_t) fprintf(fpout, "\tiflt ");
	else if(Op == LE_t) fprintf(fpout, "\tifle ");
    else if(Op == NE_t) fprintf(fpout, "\tifne ");
	else if(Op == GE_t) fprintf(fpout, "\tifge ");
	else if(Op == GT_t) fprintf(fpout, "\tifgt ");
	else if(Op == EQ_t) fprintf(fpout, "\tifeq ");

	fprintf(fpout, "Ltrue_%d\n", trueIdx);
	fprintf(fpout, "\ticonst_0\n");
	fprintf(fpout, "\tgoto Lfalse_%d\n", falseIdx);
	fprintf(fpout, "Ltrue_%d:\n", trueIdx++);
	fprintf(fpout, "\ticonst_1\n");
	fprintf(fpout, "Lfalse_%d:\n", falseIdx++);
}

void genVariableRef(struct SymNode *node) {
    if(node->category == VARIABLE_t || node->category == PARAMETER_t) {
        if(node->scope == 0) {
            if(node->type->type == INTEGER_t) {
  				fprintf(fpout, "\tgetstatic output/%s I\n", node->name);
  			}
  			else if(node->type->type == FLOAT_t) {
  				fprintf(fpout, "\tgetstatic output/%s F\n", node->name);
  			}
  			else if(node->type->type == DOUBLE_t) {
  				fprintf(fpout, "\tgetstatic output/%s D\n", node->name);
  			}
  			else if(node->type->type == BOOLEAN_t) {
  				fprintf(fpout, "\tgetstatic output/%s Z\n", node->name);
  			}
        }
        else{
			if(node->type->type == INTEGER_t || node->type->type == BOOLEAN_t)
				fprintf(fpout, "\tiload %d\n", node->varNum);
            else if(node->type->type == FLOAT_t)
				fprintf(fpout, "\tfload %d\n", node->varNum);
            else if(node->type->type == DOUBLE_t)
				fprintf(fpout, "\tdload %d\n", node->varNum);
		}
    }
    else if(node->category == CONSTANT_t){
        if(node->type->type == INTEGER_t) {
			fprintf(fpout, "\tldc %d\n", node->attribute->constVal->value.integerVal);
		}
		else if(node->type->type == FLOAT_t) {
			fprintf(fpout, "\tldc %f\n", node->attribute->constVal->value.floatVal);
		}
		else if(node->type->type == DOUBLE_t) {
			fprintf(fpout, "\tldc %lf\n", node->attribute->constVal->value.doubleVal);
		}
		else if(node->type->type == BOOLEAN_t) {
			if(node->attribute->constVal->value.booleanVal == __TRUE)
				fprintf(fpout, "\ticonst_1\n");
			else if(node->attribute->constVal->value.booleanVal == __FALSE)
				fprintf(fpout, "\ticonst_0\n");
		}
		else if(node->type->type == STRING_t) {
			// fprintf(fpout, "\tldc \"%s\"\n", node->attribute->constVal->value.stringVal);
            fprintf(fpout, "\tldc \"");
            int i = 0;
            for(; i < strlen(node->attribute->constVal->value.stringVal); i++) {
                if(node->attribute->constVal->value.stringVal[i] == '"')
                    fprintf(fpout, "\\");
                fprintf(fpout, "%c", node->attribute->constVal->value.stringVal[i]);
            }
            fprintf(fpout, "\"\n");
		}
	}
}

void genNeg(SEMTYPE type) {
    if(type == INTEGER_t) fprintf(fpout, "\tineg\n");
    else if(type == FLOAT_t) fprintf(fpout, "\tfneg\n");
    else if(type == DOUBLE_t) fprintf(fpout, "\tdneg\n");
}

void genStoreVar(struct SymNode *node, struct expr_sem *expr) {
    if(node->category == PARAMETER_t || node->category == VARIABLE_t) {
        if(node->scope == 0) {
            if(node->type->type == INTEGER_t && expr->pType->type == INTEGER_t) {
                fprintf(fpout, "\tputstatic output/%s I\n", node->name);
  			}
  			else if(node->type->type == FLOAT_t && expr->pType->type == INTEGER_t) {
                fprintf(fpout, "\ti2f\n");
  				fprintf(fpout, "\tputstatic output/%s F\n", node->name);
  			}
            else if(node->type->type == DOUBLE_t && expr->pType->type == INTEGER_t) {
                fprintf(fpout, "\ti2d\n");
  				fprintf(fpout, "\tputstatic output/%s D\n", node->name);
  			}
            else if(node->type->type == FLOAT_t && expr->pType->type == FLOAT_t) {
                fprintf(fpout, "\tputstatic output/%s F\n", node->name);
  			}
            else if(node->type->type == DOUBLE_t && expr->pType->type == FLOAT_t) {
                fprintf(fpout, "\tf2d\n");
  				fprintf(fpout, "\tputstatic output/%s D\n", node->name);
  			}
  			else if(node->type->type == DOUBLE_t && expr->pType->type == DOUBLE_t) {
  				fprintf(fpout, "\tputstatic output/%s D\n", node->name);
  			}
  			else if(node->type->type == BOOLEAN_t) {
  				fprintf(fpout, "\tputstatic output/%s Z\n", node->name);
  			}
        }
        else{
			if((node->type->type == INTEGER_t || node->type->type == BOOLEAN_t) && 
                (expr->pType->type == INTEGER_t || expr->pType->type == BOOLEAN_t)) {
				fprintf(fpout, "\tistore %d\n", node->varNum);
            }
            else if(node->type->type == FLOAT_t && expr->pType->type == INTEGER_t){
                fprintf(fpout, "\ti2f\n");
                fprintf(fpout, "\tfstore %d\n", node->varNum);
            }
            else if(node->type->type == DOUBLE_t && expr->pType->type == INTEGER_t){
                fprintf(fpout, "\ti2d\n");
                fprintf(fpout, "\tdstore %d\n", node->varNum);
            }
            else if(node->type->type == FLOAT_t && expr->pType->type == FLOAT_t){
                fprintf(fpout, "\tfstore %d\n", node->varNum);
            }
            else if(node->type->type == DOUBLE_t && expr->pType->type == FLOAT_t){
                fprintf(fpout, "\tf2d\n");
                fprintf(fpout, "\tdstore %d\n", node->varNum);
            }
            else if(node->type->type == DOUBLE_t && expr->pType->type == DOUBLE_t){
                fprintf(fpout, "\tdstore %d\n", node->varNum);
            }
		}
    }
}

void genStoreInitVar(int ListIdx, struct PType *currentType, char *id, struct expr_sem *expr) {
    if(scope != 0) {
        if(currentType->type == INTEGER_t && expr->pType->type == INTEGER_t) {
            fprintf(fpout, "\tistore %d\n", ListIdx + VarIdx);
        }
        else if(currentType->type == FLOAT_t && expr->pType->type == INTEGER_t) {
            fprintf(fpout, "\ti2f\n");
            fprintf(fpout, "\tfstore %d\n", ListIdx + VarIdx);
        }
        else if(currentType->type == DOUBLE_t && expr->pType->type == INTEGER_t) {
            fprintf(fpout, "\ti2d\n");
            fprintf(fpout, "\tdstore %d\n", ListIdx + VarIdx);
        }
        else if(currentType->type == FLOAT_t && expr->pType->type == FLOAT_t) {
            fprintf(fpout, "\tfstore %d\n", ListIdx + VarIdx);
        }
        else if(currentType->type == DOUBLE_t && expr->pType->type == FLOAT_t) {
            fprintf(fpout, "\tf2d\n");
            fprintf(fpout, "\tdstore %d\n", ListIdx + VarIdx);
        }
        else if(currentType->type == DOUBLE_t && expr->pType->type == DOUBLE_t) {
            fprintf(fpout, "\tdstore %d\n", ListIdx + VarIdx);
        }
        else if(currentType->type == BOOLEAN_t && expr->pType->type == BOOLEAN_t) {
            fprintf(fpout, "\tistore %d\n", ListIdx + VarIdx);
        }
    }
    else {
        if(currentType->type == INTEGER_t) {
			fprintf(fpout, "\tputstatic output/%s I\n", id);
		}
		else if(currentType->type == FLOAT_t) {
			fprintf(fpout, "\tputstatic output/%s F\n", id);
		}
        else if(currentType->type == DOUBLE_t) {
			fprintf(fpout, "\tputstatic output/%s D\n", id);
		}
		else if(currentType->type == BOOLEAN_t) {
			fprintf(fpout, "\tputstatic output/%s Z\n", id);
		}
    }
}

void genRead(struct SymNode *node) {
    fprintf(fpout, "\tgetstatic output/_sc Ljava/util/Scanner;\n");
    if(node->type->type == INTEGER_t) {
        fprintf(fpout, "\tinvokevirtual java/util/Scanner/nextInt()I\n");
    }
    else if(node->type->type == FLOAT_t) {
        fprintf(fpout, "\tinvokevirtual java/util/Scanner/nextFloat()F\n");
    }
    else if(node->type->type == DOUBLE_t) {
        fprintf(fpout, "\tinvokevirtual java/util/Scanner/nextDouble()D\n");
    }
    else if(node->type->type == BOOLEAN_t) {
        fprintf(fpout, "\tinvokevirtual java/util/Scanner/nextBoolean()Z\n");
    }
    if(scope != 0) {
		if(node->type->type == INTEGER_t || node->type->type == BOOLEAN_t) {
			fprintf(fpout, "\tistore %d\n", node->varNum);
		}
        else if(node->type->type == FLOAT_t) {
			fprintf(fpout, "\tfstore %d\n", node->varNum);
		}
        else if(node->type->type == DOUBLE_t) {
			fprintf(fpout, "\tdstore %d\n", node->varNum);
		}
	}
	else{
		if(node->type->type == INTEGER_t) {
			fprintf(fpout, "\tputstatic output/%s I\n", node->name);
		}
		else if(node->type->type == FLOAT_t) {
			fprintf(fpout, "\tputstatic output/%s F\n", node->name);
		}
		else if(node->type->type == DOUBLE_t) {
			fprintf(fpout, "\tputstatic output/%s D\n", node->name);
		}
		else if(node->type->type == BOOLEAN_t) {
			fprintf(fpout, "\tputstatic output/%s Z\n", node->name);
		}
    }
}

void genPreparePrint() {
    fprintf(fpout, "\tgetstatic java/lang/System/out Ljava/io/PrintStream;\n");
}

void genPrint(struct expr_sem *node) {
    if(node->pType->type == STRING_t)
        fprintf(fpout, "\tinvokevirtual java/io/PrintStream/print(Ljava/lang/String;)V\n");
    else if(node->pType->type == INTEGER_t)
        fprintf(fpout, "\tinvokevirtual java/io/PrintStream/print(I)V\n");
    else if(node->pType->type == FLOAT_t)
        fprintf(fpout, "\tinvokevirtual java/io/PrintStream/print(F)V\n");
    else if(node->pType->type == DOUBLE_t)
        fprintf(fpout, "\tinvokevirtual java/io/PrintStream/print(D)V\n");
    else if(node->pType->type == BOOLEAN_t)
        fprintf(fpout, "\tinvokevirtual java/io/PrintStream/print(Z)V\n");
}

void genIfElse_if() {
    fprintf(fpout, "\tifeq Lelse_%d\n", labelNumBuf_if->num[labelNumBuf->size-1]);
}

void genIfElse_else() {
    fprintf(fpout, "\tgoto L_if_exit_%d\n", labelNumBuf_if->num[labelNumBuf->size-1]);
    fprintf(fpout, "Lelse_%d:\n", labelNumBuf_if->num[labelNumBuf->size-1]);
}

void genIf(){
	fprintf(fpout, "\tgoto L_if_exit_%d\n", labelNumBuf_if->num[labelNumBuf->size-1]);
	fprintf(fpout, "Lelse_%d:\n", labelNumBuf_if->num[labelNumBuf->size-1]);
	fprintf(fpout, "L_if_exit_%d:\n", labelNumBuf_if->num[labelNumBuf->size-1]);
}

void genIfEnd() {
    fprintf(fpout, "L_if_exit_%d:\n", labelNumBuf_if->num[labelNumBuf->size-1]);
}

void genWhileBegin() {
    fprintf(fpout, "Lbegin_%d:\n", labelNumBuf->num[labelNumBuf->size-1]);
}

void genWhile() {
    fprintf(fpout, "\tifeq Lexit_%d\n", labelNumBuf->num[labelNumBuf->size-1]);
}

void genWhileEnd() {
    fprintf(fpout, "\tgoto Lbegin_%d\n", labelNumBuf->num[labelNumBuf->size-1]);
    fprintf(fpout, "Lexit_%d:\n", labelNumBuf->num[labelNumBuf->size-1]);
}

void genForBegin() {
    fprintf(fpout, "Lbegin_%d:\n", labelNumBuf->num[labelNumBuf->size-1]);
}

void genFor() {
    fprintf(fpout, "\tifeq Lexit_%d\n", labelNumBuf->num[labelNumBuf->size-1]);
	fprintf(fpout, "\tgoto Lexec_%d\n", labelNumBuf->num[labelNumBuf->size-1]);
    fprintf(fpout, "Linc_%d:\n", labelNumBuf->num[labelNumBuf->size-1]);
}

void genExecute(){
	fprintf(fpout, "Lexec_%d:\n", labelNumBuf->num[labelNumBuf->size-1]);
}

void genIncrement(){
	fprintf(fpout, "\tgoto Lbegin_%d\n", labelNumBuf->num[labelNumBuf->size-1]);
}

void genForEnd(){
	fprintf(fpout, "\tgoto Linc_%d\n", labelNumBuf->num[labelNumBuf->size-1]);
	fprintf(fpout, "Lexit_%d:\n", labelNumBuf->num[labelNumBuf->size-1]);
}

void genFunctionHeader(struct SymTable *table, char *id) {
    struct SymNode *node = findFuncDeclaration(table, id);
	fprintf(fpout, ".method public static %s(", id);
    if(node->attribute->formalParam->paramNum != 0) {
        struct PTypeList *parPtr = node->attribute->formalParam->params;
        for(; parPtr != 0; parPtr = (parPtr->next)) {
			if(parPtr->value->type == INTEGER_t) fprintf(fpout, "I");
            else if(parPtr->value->type == FLOAT_t) fprintf(fpout, "F");
            else if(parPtr->value->type == DOUBLE_t) fprintf(fpout, "D");
            else if(parPtr->value->type == BOOLEAN_t) fprintf(fpout, "Z");
		}
	}
	if(isEntryFunc) fprintf(fpout, "[Ljava/lang/String;)V\n");
    else {
        if(node->type->type == INTEGER_t) fprintf(fpout, ")I\n");
        else if(node->type->type == FLOAT_t) fprintf(fpout, ")F\n");
        else if(node->type->type == DOUBLE_t) fprintf(fpout, ")D\n");
        else if(node->type->type == BOOLEAN_t) fprintf(fpout, ")Z\n");
        else if(node->type->type == VOID_t) fprintf(fpout, ")V\n");
    }

	fprintf(fpout, ".limit stack 100\n");
	fprintf(fpout, ".limit locals 100\n");
    fprintf(fpout, "\tnew java/util/Scanner\n");
    fprintf(fpout, "\tdup\n");
    fprintf(fpout, "\tgetstatic java/lang/System/in Ljava/io/InputStream;\n");
    fprintf(fpout, "\tinvokespecial java/util/Scanner/<init>(Ljava/io/InputStream;)V\n");
    fprintf(fpout, "\tputstatic output/_sc Ljava/util/Scanner;\n");
}

void genReturn(SEMTYPE funcType, struct expr_sem *expr) {
	if(isEntryFunc) fprintf(fpout, "\treturn\n");
	else if(funcType == INTEGER_t && expr->pType->type == INTEGER_t) {
        fprintf(fpout, "\tireturn\n");
    }
    else if(funcType == FLOAT_t && expr->pType->type == INTEGER_t) {
        fprintf(fpout, "\ti2f\n");
        fprintf(fpout, "\tfreturn\n");
    }
	else if(funcType == DOUBLE_t && expr->pType->type == INTEGER_t) {
        fprintf(fpout, "\ti2d\n");
        fprintf(fpout, "\tdreturn\n");
    }
    else if(funcType == FLOAT_t && expr->pType->type == FLOAT_t) {
        fprintf(fpout, "\tfreturn\n");
    }
    else if(funcType == DOUBLE_t && expr->pType->type == FLOAT_t) {
        fprintf(fpout, "\tf2d\n");
        fprintf(fpout, "\tdreturn\n");
    }
    else if(funcType == DOUBLE_t && expr->pType->type == DOUBLE_t) {
        fprintf(fpout, "\tdreturn\n");
    }
    else if(expr->pType->type == BOOLEAN_t) fprintf(fpout, "\tireturn\n");
}

void genFunctionEnd() {
    fprintf(fpout, ".end method\n");
}

void genFunctionEnd_void() {
    fprintf(fpout, "\treturn\n");
    fprintf(fpout, ".end method\n\n");
}

void genFunctionCall(struct SymTable *table, char *id) {
    struct SymNode *node = lookupSymbol(table, id, 0, __FALSE);
	fprintf(fpout, "\tinvokestatic output/%s(", id);
    if(node->attribute->formalParam->paramNum != 0) {
        struct PTypeList *parPtr = node->attribute->formalParam->params;
        for(; parPtr != 0; parPtr = (parPtr->next)) {
			if(parPtr->value->type == INTEGER_t) fprintf(fpout, "I");
            else if(parPtr->value->type == FLOAT_t) fprintf(fpout, "F");
            else if(parPtr->value->type == DOUBLE_t) fprintf(fpout, "D");
            else if(parPtr->value->type == BOOLEAN_t) fprintf(fpout, "Z");
		}
	}
    if(node->type->type == INTEGER_t) fprintf(fpout, ")I\n");
    else if(node->type->type == FLOAT_t) fprintf(fpout, ")F\n");
    else if(node->type->type == DOUBLE_t) fprintf(fpout, ")D\n");
    else if(node->type->type == BOOLEAN_t) fprintf(fpout, ")Z\n");
    else if(node->type->type == VOID_t) fprintf(fpout, ")V\n");
}

void genCoercion(SEMTYPE paramType, SEMTYPE exprType) {
    if(paramType == FLOAT_t && exprType == INTEGER_t) {
        fprintf(fpout, "\ti2f\n");
    }
    else if(paramType == DOUBLE_t && exprType == INTEGER_t) {
        fprintf(fpout, "\ti2d\n");
    }
    else if(paramType == DOUBLE_t && exprType == FLOAT_t) {
        fprintf(fpout, "\tf2d\n");
    }
}

void genContinue() {
    if(inWhile)
        fprintf(fpout, "\tgoto Lbegin_%d\n", labelNumBuf->num[labelNumBuf->size-1]);
    else if(inFor)
        fprintf(fpout, "\tgoto Linc_%d\n", labelNumBuf->num[labelNumBuf->size-1]);
}

void genBreak() {
    fprintf(fpout, "\tgoto Lexit_%d\n", labelNumBuf->num[labelNumBuf->size-1]);
}