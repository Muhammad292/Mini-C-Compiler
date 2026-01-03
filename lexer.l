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

/* helper to count decimal digits in float */
static int count_decimal_digits(const char *text) {
	const char *dot = strchr(text, '.');
	if (!dot) return 0;
	return strlen(dot + 1);
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

"\""([^"\n]*)"\""   { 
        /* extract inner string without quotes */
        int n = strlen(yytext);
        char *tmp = (char*)malloc(n-1);
        if (n >= 2) {
          strncpy(tmp, yytext+1, n-2);
          tmp[n-2] = '\0';
        } else {
          tmp[0] = '\0';
        }
        yylval.sval = tmp;
        return STRING;
      }

{ID}         { 
              if (strlen(yytext) > 30) {
                printf("Lexical Error at line %d: Identifier '%s' exceeds maximum length of 30 characters\n", line_no, yytext);
                FILE *f = fopen("errors.log", "a");
                if (f) {
                  fprintf(f, "Lexical Error at line %d: Identifier '%s' exceeds maximum length of 30 characters\n", line_no, yytext);
                  fclose(f);
                }
              }
              yylval.sval = strdup(yytext); 
              return ID; 
            }

{FLOAT_CONST} { 
              int decimal_digits = count_decimal_digits(yytext);
              if (decimal_digits < 1 || decimal_digits > 6) {
                printf("Lexical Error at line %d: Float '%s' must have 1-6 decimal digits (found %d)\n", line_no, yytext, decimal_digits);
                FILE *f = fopen("errors.log", "a");
                if (f) {
                  fprintf(f, "Lexical Error at line %d: Float '%s' must have 1-6 decimal digits (found %d)\n", line_no, yytext, decimal_digits);
                  fclose(f);
                }
              }
              yylval.fval = atof(yytext); 
              return FLOAT_CONST; 
            }
{INT_CONST}   { yylval.ival = atoi(yytext); return INT_CONST; }

"=="         { return EQ; }
"!="         { return NE; }
"<="         { return LE; }
">="         { return GE; }
"<"          { return LT; }
">"          { return GT; }
"+"          { return ADD; }
"-"          { return SUB; }
"*"          { return MUL; }
"/"          { return DIV; }
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

"//"[^\n]*   { /* //skip single line comment */ }
"/*"([^*]|"*"+[^*/])*"*"+"/"   { /* skip block comment */ }

{WS}         ; // ignore whitespace
"\n"         { line_no++; }

.            { printf("Lexical Error at line %d: Unknown symbol %s\n", line_no, yytext); log_lex_error(line_no, yytext); }

%%

int yywrap(){ return 1; }
