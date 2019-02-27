all: parser
lex: yacc
	lex -o lex.yy.c lex.l
yacc:
	yacc -o y.tab.c -d -v yacc.y
parser: lex yacc
	gcc -o parser lex.yy.c y.tab.c -ly -ll

clean:
	rm parser lex.yy.c y.output y.tab.h y.tab.c