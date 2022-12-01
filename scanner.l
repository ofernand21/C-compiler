%{

#include <stdlib.h>
#include <stdio.h>
#include <limits.h>
#include "parser.tab.h"

int cmnt_strt = 0;

%}

letter [a-zA-Z]
digit [0-9]
ws  [ \t\r\f\v]+
identifier (_|{letter})({letter}|{digit}|_){0,31}
hex [0-9a-f]

 /* Etat Exclusive */
%x CMNT

%%
  /* Lexeme*/
"int"		{return INT;}
"long"		{return LONG;}
"long long"	{return LONG_LONG;}
"short"		{return SHORT;}
"signed"		{return SIGNED;}
"unsigned"	{return UNSIGNED;}
"for" 		{return FOR;}
"while"		{return WHILE;}
"break" 		{return BREAK;}
"continue"	{return CONTINUE;}
"if"			{return IF;}
"else"		{return ELSE;}
"return"		{return RETURN;}
{identifier}	{return  IDENTIFIER;}
{ws}                              ;
[+\-]?[0][x|X]{hex}+[lLuU]? 		{ yylval.dval = (int)strtol(yytext, NULL, 16); return  HEX_CONSTANT;}
[+\-]?{digit}+[lLuU]? 			{yylval.dval = atoi(yytext); return  DEC_CONSTANT;}
"/*"							{cmnt_strt = yylineno; BEGIN CMNT;}
<CMNT>.|{ws}			    ;
<CMNT>\n			{yylineno++;}
<CMNT>"*/"			{BEGIN INITIAL;}
<CMNT>"/*"			{printf("Line %3d: Commentaire invalide!\n",yylineno);}
<CMNT><<EOF>>	{printf("Line %3d: Commentaire interminable\n", cmnt_strt); yyterminate();}
"//"(.*)                            	    ;
\"[^\"\n]*\"     {

  if(yytext[yyleng-2]=='\\') /* vérifie s'il s'agit d'une citation échappée */
  {
    yyless(yyleng-1);       /* répousser la citation si elle à échappé */
    yymore();
  }
  else
  	return STRING;
 }

\"[^\"\n]*$		{printf("Line %3d: Unterminated string %s\n",yylineno,yytext);}
{digit}+({letter}|_)+	{printf("Line %3d: Illegal identifier name %s\n",yylineno,yytext);}
\n					{yylineno++;}
"--"				{return DECREMENT;}
"++"			{return INCREMENT;}
"+="			{return ADD_ASSIGN;}
"-="				{return SUB_ASSIGN;}
"*="			{return MUL_ASSIGN;}
"/=" 			{return DIV_ASSIGN;}
"&&"			{return LOGICAL_AND;}
"||"				{return LOGICAL_OR;}
"<="			{return L_EQ;}
">="			{return G_EQ;}
"=="			{return EQ;}
"!="				{return NOT_EQ;}
.                         {return yytext[0];}

%%
