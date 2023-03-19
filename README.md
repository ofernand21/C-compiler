# C-compiler
Un mini compilateur du langage C
# To compile lex file
lex -o scanner.c scanner.l
# To compile yacc file
yacc -o parser.c parser.y
# To compile all project
gcc -o myprogram myprogram.c scanner.c parser.c
# To excecute
./myprogram
