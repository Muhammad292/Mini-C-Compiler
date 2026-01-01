#ifndef SYMBOLS_H
#define SYMBOLS_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef enum {
    TYPE_INT = 1,
    TYPE_FLOAT = 2,
    TYPE_BOOL = 3,
    TYPE_VOID = 4,
    TYPE_UNDEFINED = 0
} DataType;

typedef enum {
    KIND_VAR,
    KIND_FUNC,
    KIND_PARAM
} SymbolKind;

typedef struct {
    char name[256];
    DataType type;
    SymbolKind kind;
    int scope_level;
    int initialized;
    int is_param;
} Symbol;

#define MAX_SYMBOLS 500
#define MAX_SCOPES 20

typedef struct {
    Symbol symbols[MAX_SYMBOLS];
    int symbol_count;
    int scope_stack[MAX_SCOPES];
    int scope_top;
    int current_scope;
} SymbolTable;

/* Function declarations */
SymbolTable* symbol_table_init();
void symbol_table_close(SymbolTable *st);
int insert_symbol(SymbolTable *st, const char *name, DataType type, SymbolKind kind);
Symbol* lookup_symbol(SymbolTable *st, const char *name);
Symbol* lookup_in_scope(SymbolTable *st, const char *name, int scope);
int enter_scope(SymbolTable *st);
int exit_scope(SymbolTable *st);
void set_initialized(SymbolTable *st, const char *name);
int is_declared(SymbolTable *st, const char *name);
void symbol_table_print(SymbolTable *st);
char* type_to_string(DataType type);

#endif
