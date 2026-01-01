%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symbols.h"
#include "semantic.h"
#include "icg.h"
#include "src/parser_error_log.h"
extern int line_no;
void yyerror(const char *s);
int yylex();
/* Prototype for Flex restart function to avoid implicit declaration warning */
extern void yyrestart(FILE *);
%}

%union {
    char* sval;
    int ival;
    float fval;
    int bval;
    int type;
}

%token IF ELSE WHILE FOR RETURN INPUT OUTPUT
%token TOK_INT TOK_FLOAT TOK_BOOL
%token <sval> ID
%token <ival> INT_CONST
%token <fval> FLOAT_CONST
%token <bval> BOOL_CONST
%token <sval> RELOP ADDOP MULOP
%token ASSIGN LAND LOR LNOT

%type <type> type expr

%left LOR
%left LAND
%right LNOT
%left RELOP
%left ADDOP
%left MULOP

%%

program:
      decl_list
;

decl_list:
      decl_list decl
    | decl
;

decl:
      type ID ';'        
      { 
          if (!insert_symbol(global_symbol_table, $2, $1, KIND_VAR)) {
              report_semantic_error(line_no, "Redeclaration of '%s'", $2);
          }
          free($2);
      }
    | func_def
    | error ';' { yyerror("Skipping invalid declaration"); yyerrok; }
;

type:
      TOK_INT      { $$ = TYPE_INT; }
    | TOK_FLOAT    { $$ = TYPE_FLOAT; }
    | TOK_BOOL     { $$ = TYPE_BOOL; }
;

func_def:
      type ID '(' param_list_opt ')' 
      { 
          current_func_name = $2;
          current_func_ret_type = $1;
          if (!insert_symbol(global_symbol_table, $2, $1, KIND_FUNC)) {
              report_semantic_error(line_no, "Redeclaration of function '%s'", $2);
          }
          enter_scope(global_symbol_table);
      }
      block
      { 
          exit_scope(global_symbol_table);
          current_func_name = NULL;
      }
;

param_list_opt:
      /* empty */
    | param_list
;

param_list:
      param
    | param_list ',' param
;

param:
      type ID
      {
          if (!insert_symbol(global_symbol_table, $2, $1, KIND_PARAM)) {
              report_semantic_error(line_no, "Redeclaration of parameter '%s'", $2);
          }
          free($2);
      }
;

block:
      '{' stmt_list '}'
;

stmt_list:
      stmt_list stmt
    | /* empty */
;

stmt:
      type ID ';'
      {
          if (!insert_symbol(global_symbol_table, $2, $1, KIND_VAR)) {
              report_semantic_error(line_no, "Redeclaration of '%s'", $2);
          }
          free($2);
      }
    | assign_stmt
    | input_stmt
    | output_stmt
    | if_stmt
    | while_stmt
    | for_stmt
    | return_stmt
    | block_stmt
    | ';'
    | error ';'  { yyerror("Skipping invalid statement"); yyerrok; }
;

block_stmt:
      '{' { enter_scope(global_symbol_table); } stmt_list '}' { exit_scope(global_symbol_table); }
;

assign_stmt:
      ID ASSIGN expr ';'
      {
          Symbol *sym = lookup_symbol(global_symbol_table, $1);
          if (!sym) {
              report_semantic_error(line_no, "Undeclared variable '%s'", $1);
          } else {
              check_assignment(sym->type, expr_type, line_no);
              set_initialized(global_symbol_table, $1);
              gen_assign($1);
          }
          free($1);
      }
;

input_stmt:
      INPUT '(' ID ')' ';'
      {
          if (!lookup_symbol(global_symbol_table, $3)) {
              report_semantic_error(line_no, "Undeclared variable '%s'", $3);
          }
          free($3);
      }
;

output_stmt:
      OUTPUT '(' expr ')' ';'
;

if_stmt:
      IF '(' expr ')' stmt
    | IF '(' expr ')' stmt ELSE stmt
;

while_stmt:
      WHILE '(' expr ')' stmt
;

for_stmt:
      FOR '(' for_init ';' expr ';' for_update ')' stmt
;

for_init:
      assign_stmt_no_semi
    | type ID ASSIGN expr
      {
          if (!insert_symbol(global_symbol_table, $2, $1, KIND_VAR)) {
              report_semantic_error(line_no, "Redeclaration of '%s'", $2);
          }
          free($2);
      }
    | /* empty */
;

for_update:
      assign_stmt_no_semi
    | /* empty */
;

assign_stmt_no_semi:
      ID ASSIGN expr
      {
          Symbol *sym = lookup_symbol(global_symbol_table, $1);
          if (!sym) {
              report_semantic_error(line_no, "Undeclared variable '%s'", $1);
          }
          free($1);
      }
;

return_stmt:
      RETURN expr ';'
      {
          if (current_func_name) {
              check_return_type(current_func_ret_type, expr_type, line_no);
          }
      }
    | RETURN ';'
;

expr:
      INT_CONST        
      { 
          expr_type = TYPE_INT; 
          gen_const_int($1); 
          $$ = TYPE_INT;
      }
    | FLOAT_CONST      
      { 
          expr_type = TYPE_FLOAT; 
          gen_const_float($1); 
          $$ = TYPE_FLOAT;
      }
    | BOOL_CONST       
      { 
          expr_type = TYPE_BOOL; 
          $$ = TYPE_BOOL;
      }
    | ID               
      { 
          Symbol *sym = lookup_symbol(global_symbol_table, $1);
          if (sym) {
              expr_type = sym->type;
              gen_id($1);
              $$ = sym->type;
          } else {
              report_semantic_error(line_no, "Undeclared variable '%s'", $1);
              expr_type = TYPE_INT;
              $$ = TYPE_INT;
          }
          free($1);
      }
    | expr ADDOP expr  
      { 
          expr_type = result_type($1, $3); 
          gen_binary_op($2);
          free($2);
          $$ = expr_type;
      }
    | expr MULOP expr  
      { 
          expr_type = result_type($1, $3); 
          gen_binary_op($2);
          free($2);
          $$ = expr_type;
      }
    | expr RELOP expr
      {
          expr_type = TYPE_BOOL;
          gen_binary_op($2);
          free($2);
          $$ = TYPE_BOOL;
      }
    | expr LAND expr
      {
          check_bool_operands($1, $3, line_no);
          expr_type = TYPE_BOOL;
          $$ = TYPE_BOOL;
      }
    | expr LOR expr
      {
          check_bool_operands($1, $3, line_no);
          expr_type = TYPE_BOOL;
          $$ = TYPE_BOOL;
      }
    | LNOT expr
      {
          if ($2 != TYPE_BOOL) {
              report_semantic_error(line_no, "! operator requires boolean operand");
          }
          expr_type = TYPE_BOOL;
          $$ = TYPE_BOOL;
      }
    | '(' expr ')'  { $$ = $2; }
;

%%

void yyerror(const char *s)
{
    char buf[512];
    snprintf(buf, sizeof(buf), "Syntax Error at line %d: %s", line_no, s);
    fprintf(stderr, "%s\n", buf);
    log_error_msg(buf);
    error_count++;
}
static int has_mc_extension(const char *name) {
    if (!name) return 0;
    size_t n = strlen(name);
    return (n > 3) && (strcmp(name + n - 3, ".mc") == 0);
}

int main(int argc, char **argv)
{
    printf("\n=== MiniC Compiler (LALR Parser) ===\n\n");

    init_globals();

    if (argc < 2) {
        fprintf(stderr, "Usage: %s <file1.mc> [file2.mc ...]\n", argv[0]);
        return 1;
    }

    /* Accept only one .mc file. If multiple provided, warn and use the first .mc. */
    int overall_errors = 0;
    int first_mc_index = -1;
    int mc_count = 0;
    for (int i = 1; i < argc; ++i) {
        if (has_mc_extension(argv[i])) {
            if (first_mc_index == -1) first_mc_index = i;
            mc_count++;
        }
    }

    if (mc_count == 0) {
        fprintf(stderr, "Error: no .mc input file provided. Usage: %s <file.mc>\n", argv[0]);
        return 1;
    }

    if (mc_count > 1) {
        fprintf(stderr, "Warning: %d .mc files provided; only the first will be compiled: '%s'\n",
                mc_count, argv[first_mc_index]);
    }

    {
        const char *fname = argv[first_mc_index];
        extern FILE *yyin;
        yyin = fopen(fname, "r");
        if (!yyin) {
            perror("Error opening file");
            return 1;
        }

        /* restart lexer with new input */
#ifdef YY_CURRENT_BUFFER_LVALUE
        yyrestart(yyin);
#else
        yyrestart(yyin);
#endif

        /* parse the single chosen file */
        yyparse();

        if (error_count == 0) {
            printf("\nCompilation of %s successful!\n", fname);
            symbol_table_print(global_symbol_table);
            print_icg();
        } else {
            printf("\nCompilation of %s failed with %d error(s)\n", fname, error_count);
            overall_errors += error_count;
        }

        fclose(yyin);
    }

    cleanup_globals();
    return (overall_errors == 0) ? 0 : 1;
}
