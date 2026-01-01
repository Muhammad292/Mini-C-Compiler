%{
#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int line_no = 1;
/* helper to log lexical errors */
static void log_lex_error(int line, const char *text) {
	FILE *f = fopen("errors.log", "a");
	if (!f) return;
	fprintf(f, "Lexical Error at line %d: Unknown symbol %s\n", line, text);
	fclose(f);
}
%}

ID          [a-zA-Z_][a-zA-Z0-9_]*
INT_CONST   [0-9]+
FLOAT_CONST [0-9]+"."[0-9]+
WS          [ \t\r]+

%%

"int"        { return TOK_INT; }
"float"      { return TOK_FLOAT; }
"bool"       { return TOK_BOOL; }

"if"         { return IF; }
"else"       { return ELSE; }
"while"      { return WHILE; }
"for"        { return FOR; }
"return"     { return RETURN; }

"true"       { yylval.bval = 1; return BOOL_CONST; }
"false"      { yylval.bval = 0; return BOOL_CONST; }

"input"      { return INPUT; }
"output"     { return OUTPUT; }

{ID}         { yylval.sval = strdup(yytext); return ID; }

{FLOAT_CONST} { yylval.fval = atof(yytext); return FLOAT_CONST; }
{INT_CONST}   { yylval.ival = atoi(yytext); return INT_CONST; }

"=="         { yylval.sval = strdup(yytext); return RELOP; }
"!="         { yylval.sval = strdup(yytext); return RELOP; }
"<="         { yylval.sval = strdup(yytext); return RELOP; }
">="         { yylval.sval = strdup(yytext); return RELOP; }
"<"          { yylval.sval = strdup(yytext); return RELOP; }
">"          { yylval.sval = strdup(yytext); return RELOP; }
"+"          { yylval.sval = strdup(yytext); return ADDOP; }
"-"          { yylval.sval = strdup(yytext); return ADDOP; }
"*"          { yylval.sval = strdup(yytext); return MULOP; }
"/"          { yylval.sval = strdup(yytext); return MULOP; }
"&&"                                     { return LAND; }
"||"                                     { return LOR; }
"!"                                      { return LNOT; }

"="          { return ASSIGN; }
";"          { return ';'; }
","          { return ','; }
"("          { return '('; }
")"          { return ')'; }
"{"          { return '{'; }
"}"          { return '}'; }

"//"[^\n]*   { /* skip single line comment */ }
"/*"([^*]|"*"+[^*/])*"*"+"/"   { /* skip block comment */ }

{WS}         ;
"\n"         { line_no++; }

.            { printf("Lexical Error at line %d: Unknown symbol %s\n", line_no, yytext); log_lex_error(line_no, yytext); }

%%

int yywrap(){ return 1; }
