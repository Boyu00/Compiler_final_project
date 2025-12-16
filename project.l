%{
    //Definition Section,Initial C or C++ codes enclosed with %{ and %}
    #include "project.tab.hpp"
	#include<iostream>
	#include<vector>
	using namespace std;
%}
    //Lex definitions :

separator [\t\n\r ]
letter [a-z]
digit [0-9]
number (0|[1-9]{digit}*|-[1-9]{digit}*)
ID {letter}({letter}|{digit}|\-)*
bool_val (#t|#f)
%%
{number} {
	yylval.ival=atoi(yytext);
    return NUMBER;
}
"(" {return '(';}
")" {return ')';}
"+" {return '+';}
"-" {return '-';}
"*" {return '*';}
"/" {return '/';}
">" {return '>';}
"<" {return '<';}
"=" {return '=';}
"mod" {return MOD;}
"and" {return AND;}
"or" {return OR;}
"not" {return NOT;}
"if" {return IF;}
"define" {return DEFINE;}
"fun" {return FUNC;}
"print-num" {return PRINT_NUM;}
"print-bool" {return PRINT_BOOL;}
{separator} {}
{ID} {
	//sval is a pointer, can't point to yytext otherwise it will be erased. duplicate it.
    yylval.sval=strdup(yytext);
	return ID;
}
{bool_val} {
	if(strcmp(yytext, "#t") == 0)yylval.bval=true;
	else yylval.bval=false;
	return BOOL_VAL;
}

. { return yytext[0]; }

%%


