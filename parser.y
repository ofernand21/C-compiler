%{
#include <stdlib.h>
#include <stdio.h>

struct cell
{
	char* lexeme;
	double value;
	int data_type;
	struct cell* suivant;
};

typedef struct cell entry_t;

double Evaluer (double lhs_value,int assign_type,double rhs_value);
int type_courant;
int yyerror(char *msg);
%}

%union
{
	double dval;
	entry_t* entry;
	int ival;
}

/* Déclaration des terminaux returner par lex */
%token <entry> IDENTIFIER
%token <dval> DEC_CONSTANT HEX_CONSTANT
%token STRING
%token LOGICAL_AND LOGICAL_OR LS_EQ GR_EQ EQ NOT_EQ
%token MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN SUB_ASSIGN
%token LEFT_ASSIGN RIGHT_ASSIGN AND_ASSIGN XOR_ASSIGN OR_ASSIGN
%token INCREMENT DECREMENT
%token SHORT INT LONG LONG_LONG SIGNED UNSIGNED CONST
%token IF FOR WHILE CONTINUE BREAK RETURN

/*Déclaration des non-terminaux */
%type <dval> expression
%type <dval> condition
%type <dval> constant
%type <dval> unary_expr
%type <dval> arithmetic_expr
%type <dval> assignment_expr
%type <entry> lhs
%type <ival> assign_op

%start starter

%left ','
%right '='
%left LOGICAL_OR
%left LOGICAL_AND
%left EQ NOT_EQ
%left '<' '>' L_EQ G_EQ
%left '+' '-'
%left '*' '/' '%'
%right '!'

%nonassoc UMINUS
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%
  /* Programme est fait de multiple blocs de constructeur. */
starter: starter builder
	|builder;

 /* Chaque bloc de constructeur block est une ou une déclaration */
builder: function
	|declaration;

 /* Constructeur de fonction */
function: type IDENTIFIER '(' argument_list ')' bloc_stmt;

 /* On vas definir maintenant pour nos type spécifique */

type :data_type pointer
    |data_type;

pointer: '*' pointer
    |'*'
    ;

data_type :sign_specifier type_specifier
    |type_specifier
    ;

sign_specifier :SIGNED
    |UNSIGNED
    ;

type_specifier :INT		{type_courant = INT;}
    |SHORT INT		{type_courant = SHORT;}
    |SHORT			{type_courant = SHORT;}
    |LONG			{type_courant = LONG;}
    |LONG INT			{type_courant = LONG;}
    |LONG_LONG		{type_courant = LONG_LONG;}
    |LONG_LONG INT	{type_courant = LONG_LONG;}
    ;

 /* Les règles de grammaire pour les argument  */
 /* On peut ne pas avoir d'argument */
argument_list :arguments
    |
    ;
 /* Les arguments peuvent être separé par des virgules */
arguments :arguments ',' arg
    |arg
    ;

 /* arg est une déclaration d'identificateur */
arg :type IDENTIFIER
   ;

 /* stmt define l'agencement des bloc d'intruction */
stmt:bloc_stmt
    |single_stmt
    ;

 /* Bloc d'instruction, peut être le corps de fonction de boucle... */
bloc_stmt :'{' statements '}'
    ;

statements:statements stmt
    |
    ;

 /* Grammaire pour constituer nos instruction courantes */
single_stmt :if_block
	|for_block
	|while_block
	|declaration
	|function_call ';'
	|RETURN ';'
	|CONTINUE ';'
	|BREAK ';'
	|RETURN condition ';'
    ;

for_block:FOR '(' expression_stmt  expression_stmt ')' stmt
    |FOR '(' expression_stmt expression_stmt expression ')' stmt
    ;

if_block:IF '(' expression ')' stmt %prec LOWER_THAN_ELSE
	|IF '(' expression ')' stmt ELSE stmt
    ;

while_block: WHILE '(' expression ')' stmt
		;

declaration:type declaration_list ';'
	|declaration_list ';'
	| unary_expr ';'

declaration_list: declaration_list ',' sub_decl
	|sub_decl;

sub_decl: assignment_expr
    |IDENTIFIER		{$1 = malloc(sizeof(entry_t));  $1->data_type = type_courant;}
    |array_index
    ;

/* Cela on pour avec des blocs sans instructions */
expression_stmt:expression ';'
    |';'
    ;

expression:
    expression ',' condition	{$$ = $1,$3;}
    |condition			       {$$ = $1;}
	;

condition:
    condition '>' condition			{$$ = ($1 > $3);}
    |condition '<' condition			{$$ = ($1 < $3);}
    |condition EQ condition			{$$ = ($1 == $3);}
    |condition NOT_EQ condition		{$$ = ($1 != $3);}
    |condition L_EQ condition		{$$ = ($1 <= $3);}
    |condition G_EQ condition		{$$ = ($1 >= $3);}
    |condition LOGICAL_AND condition	{$$ = ($1 && $3);}
    |condition LOGICAL_OR condition 	{$$ = ($1 || $3);}
    |'!' condition                                     {$$ = (!$2);}
    |arithmetic_expr					{$$ = $1;}
    |assignment_expr                             {$$ = $1;}
    |unary_expr                                     {$$ = $1;}
    ;


assignment_expr :lhs assign_op arithmetic_expr	{$1 = malloc(sizeof(entry_t)); $$ = $1->value = Evaluer($1->value,$2,$3);}
    |lhs assign_op array_index                     		{$$ = 0;}
    |lhs assign_op function_call                   		{$$ = 0;}
    |lhs assign_op unary_expr                   	       {$1 = malloc(sizeof(entry_t));  $$ = $1->value = Evaluer($1->value,$2,$3);}
    |unary_expr assign_op unary_expr                	{$$ = 0;}
    ;

unary_expr:	lhs INCREMENT		{$1 = malloc(sizeof(entry_t));  $$ = $1->value = ($1->value)++;}
	|lhs DECREMENT				{$1 = malloc(sizeof(entry_t));  $$ = $1->value = ($1->value)--;}
	|DECREMENT lhs				{$2 = malloc(sizeof(entry_t));  $$ = $2->value = --($2->value);}
	|INCREMENT lhs				{$2 = malloc(sizeof(entry_t));  $$ = $2->value = ++($2->value);}

lhs:IDENTIFIER		{$1 = malloc(sizeof(entry_t)); $$ = $1; if(! $1->data_type) $1->data_type = type_courant;}
    ;

assign_op:'='		{$$ = '=';}
    |ADD_ASSIGN	{$$ = ADD_ASSIGN;}
    |SUB_ASSIGN	{$$ = SUB_ASSIGN;}
    |MUL_ASSIGN	{$$ = MUL_ASSIGN;}
    |DIV_ASSIGN	{$$ = DIV_ASSIGN;}
    |MOD_ASSIGN	{$$ = MOD_ASSIGN;}
    ;

arithmetic_expr: arithmetic_expr '+' arithmetic_expr    {$$ = $1 + $3;}
    |arithmetic_expr '-' arithmetic_expr				{$$ = $1 - $3;}
    |arithmetic_expr '*' arithmetic_expr				{$$ = $1 * $3;}
    |arithmetic_expr '/' arithmetic_expr				{$$ = ($3 == 0) ? yyerror("Divide by 0!") : ($1 / $3);}
    |arithmetic_expr '%' arithmetic_expr				{$$ = (int)$1 % (int)$3;}
    |'(' arithmetic_expr ')'						{$$ = $2;}
    |'-' arithmetic_expr %prec UMINUS				{$$ = -$2;}
    |IDENTIFIER 								{$1 = malloc(sizeof(entry_t));  $$ = $1 -> value;}
    |constant									{$$ = $1;}
    ;

constant: DEC_CONSTANT		{$$ = $1;}
    |HEX_CONSTANT			{$$ = $1;}
    ;

array_index: IDENTIFIER '[' condition ']'

function_call: IDENTIFIER '(' parameter_list ')'
	|IDENTIFIER '(' ')'
	;

parameter_list:
	parameter_list ','  parameter
	|parameter
	;

parameter: condition
	|STRING
	 ;
%%

#include "lex.yy.c"
#include <ctype.h>

double Evaluer (double lhs_value,int assign_type,double rhs_value)
{
	/* lhs_value assign_type rhs_value */
	switch(assign_type)
	{
		case '=': return rhs_value;
		case ADD_ASSIGN: return (lhs_value + rhs_value);
		case SUB_ASSIGN: return (lhs_value - rhs_value);
		case MUL_ASSIGN: return (lhs_value * rhs_value);
		case DIV_ASSIGN: return (lhs_value / rhs_value);
		case MOD_ASSIGN: return ((int)lhs_value % (int)rhs_value);
	}
}

int main(int argc, char *argv[])
{
	yyin = fopen(argv[1], "r");

	if(!yyparse())
	{
		printf("\nParsing complete\n");
	}
	else
	{
		printf("\nParsing failed\n");
	}
	fclose(yyin);
	return 0;
}

int yyerror(char *msg)
{
	printf("Line no: %d Error message: %s Token: %s\n", yylineno, msg, yytext);
}
