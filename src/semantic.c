#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include "semantic.h"
#include "parser_error_log.h"

DataType expr_type = TYPE_UNDEFINED;
char *current_func_name = NULL;
DataType current_func_ret_type = TYPE_VOID;
int error_count = 0;
SymbolTable *global_symbol_table = NULL;

void init_globals() {
    global_symbol_table = symbol_table_init();
    error_count = 0;
    expr_type = TYPE_UNDEFINED;
    current_func_name = NULL;
}

void cleanup_globals() {
    symbol_table_close(global_symbol_table);
}

void check_assignment(DataType var_type, DataType e_type, int line) {
    if (var_type == TYPE_UNDEFINED || e_type == TYPE_UNDEFINED) {
        return;
    }
    
    // Allow int to float implicit conversion
    if (var_type == TYPE_FLOAT && e_type == TYPE_INT) {
        return;
    }
    // Allow float-to-int implicit conversion but warn the user
    if (var_type == TYPE_INT && e_type == TYPE_FLOAT) {
        if (line > 0) {
            fprintf(stderr, "Warning at line %d: implicit conversion from %s to %s\n",
                    line, "float", "int");
        } else {
            fprintf(stderr, "Warning: implicit conversion from %s to %s\n", "float", "int");
        }
        return;
    }

    if (var_type != e_type) {
        report_semantic_error(line, "Type mismatch in assignment (expected %s, got %s)",
                type_to_string(var_type), type_to_string(e_type));
    }
}

DataType result_type(DataType t1, DataType t2) {
    if (t1 == TYPE_UNDEFINED || t2 == TYPE_UNDEFINED) {
        return TYPE_UNDEFINED;
    }
    
    // Float dominates
    if (t1 == TYPE_FLOAT || t2 == TYPE_FLOAT) {
        return TYPE_FLOAT;
    }
    
    // Both int
    if (t1 == TYPE_INT && t2 == TYPE_INT) {
        return TYPE_INT;
    }
    
    // Both bool
    if (t1 == TYPE_BOOL && t2 == TYPE_BOOL) {
        return TYPE_BOOL;
    }
    
    return TYPE_INT;
}

void check_return_type(DataType expected, DataType actual, int line) {
    if (expected == TYPE_UNDEFINED || actual == TYPE_UNDEFINED) {
        return;
    }
    if (expected != actual) {
        report_semantic_error(line, "Return type mismatch (expected %s, got %s)",
                type_to_string(expected), type_to_string(actual));
    }
}

void check_bool_operands(DataType t1, DataType t2, int line) {
    if (t1 != TYPE_BOOL || t2 != TYPE_BOOL) {
        report_semantic_error(line, "Logical operators require boolean operands");
    }
}

void report_semantic_error(int line, const char *fmt, ...) {
    char buf[512];
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(buf, sizeof(buf), fmt, ap);
    va_end(ap);

    if (line > 0) {
        fprintf(stderr, "Semantic Error at line %d: %s\n", line, buf);
    } else {
        fprintf(stderr, "Semantic Error: %s\n", buf);
    }
    error_count++;

    FILE *f = fopen("errors.log", "a");
    if (f) {
        if (line > 0) fprintf(f, "Semantic Error at line %d: %s\n", line, buf);
        else fprintf(f, "Semantic Error: %s\n", buf);
        fclose(f);
    }
}
