# C-compiler
Un mini compilateur du langage C
lex -o lexer.c lexer.l
yacc -o parser.c parser.y
gcc -o myprogram myprogram.c lexer.c parser.c
