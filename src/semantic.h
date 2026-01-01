#ifndef SEMANTIC_H
#define SEMANTIC_H

#include "symbols.h"

extern DataType expr_type;
extern char *current_func_name;
extern DataType current_func_ret_type;
extern int error_count;
extern SymbolTable *global_symbol_table;

void init_globals();
void cleanup_globals();
void check_assignment(DataType var_type, DataType expr_type, int line);
DataType result_type(DataType t1, DataType t2);
void check_return_type(DataType expected, DataType actual, int line);
void check_bool_operands(DataType t1, DataType t2, int line);
void report_semantic_error(int line, const char *fmt, ...);

#endif
