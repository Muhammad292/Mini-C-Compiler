#include "symbols.h"
#include "semantic.h"

SymbolTable* symbol_table_init() {
    SymbolTable *st = (SymbolTable*)malloc(sizeof(SymbolTable));
    st->symbol_count = 0;
    st->scope_top = 0;
    st->current_scope = 0;
    st->scope_stack[0] = 0;  // Global scope starts at index 0
    return st;
}

void symbol_table_close(SymbolTable *st) {
    free(st);
}

int insert_symbol(SymbolTable *st, const char *name, DataType type, SymbolKind kind) {
    // Check for redeclaration in current scope
    for (int i = st->scope_stack[st->scope_top]; i < st->symbol_count; i++) {
        if (st->symbols[i].scope_level == st->current_scope &&
            strcmp(st->symbols[i].name, name) == 0) {
            report_semantic_error(0, "Redeclaration of '%s'", name);
            return 0;
        }
    }
    
    if (st->symbol_count >= MAX_SYMBOLS) {
        fprintf(stderr, "Error: Symbol table overflow\n");
        return 0;
    }
    
    Symbol *sym = &st->symbols[st->symbol_count];
    strcpy(sym->name, name);
    sym->type = type;
    sym->kind = kind;
    sym->scope_level = st->current_scope;
    sym->initialized = 0;
    sym->is_param = (kind == KIND_PARAM);
    
    st->symbol_count++;
    return 1;
}

Symbol* lookup_symbol(SymbolTable *st, const char *name) {
    // Search from current scope down to global scope
    for (int i = st->symbol_count - 1; i >= 0; i--) {
        if (strcmp(st->symbols[i].name, name) == 0 &&
            st->symbols[i].scope_level <= st->current_scope) {
            return &st->symbols[i];
        }
    }
    return NULL;
}

Symbol* lookup_in_scope(SymbolTable *st, const char *name, int scope) {
    for (int i = 0; i < st->symbol_count; i++) {
        if (strcmp(st->symbols[i].name, name) == 0 &&
            st->symbols[i].scope_level == scope) {
            return &st->symbols[i];
        }
    }
    return NULL;
}

int enter_scope(SymbolTable *st) {
    if (st->scope_top >= MAX_SCOPES - 1) {
        fprintf(stderr, "Error: Scope stack overflow\n");
        return 0;
    }
    st->scope_top++;
    st->current_scope++;
    st->scope_stack[st->scope_top] = st->symbol_count;
    return 1;
}

int exit_scope(SymbolTable *st) {
    if (st->scope_top == 0) {
        fprintf(stderr, "Error: Cannot exit global scope\n");
        return 0;
    }
    st->scope_top--;
    st->current_scope--;
    return 1;
}

void set_initialized(SymbolTable *st, const char *name) {
    Symbol *sym = lookup_symbol(st, name);
    if (sym) {
        sym->initialized = 1;
    }
}

int is_declared(SymbolTable *st, const char *name) {
    return lookup_symbol(st, name) != NULL;
}

char* type_to_string(DataType type) {
    switch(type) {
        case TYPE_INT: return "int";
        case TYPE_FLOAT: return "float";
        case TYPE_BOOL: return "bool";
        case TYPE_VOID: return "void";
        default: return "undefined";
    }
}

void symbol_table_print(SymbolTable *st) {
    printf("\n=== SYMBOL TABLE ===\n");
    printf("%-20s | %-10s | %-10s | %-5s | %-10s\n",
           "Name", "Type", "Kind", "Scope", "Initialized");
    printf("-----------------------------------------------------------\n");
    
    for (int i = 0; i < st->symbol_count; i++) {
        printf("%-20s | %-10s | %-10s | %-5d | %s\n",
               st->symbols[i].name,
               type_to_string(st->symbols[i].type),
               st->symbols[i].kind == KIND_VAR ? "VAR" : 
               st->symbols[i].kind == KIND_FUNC ? "FUNC" : "PARAM",
               st->symbols[i].scope_level,
               st->symbols[i].initialized ? "YES" : "NO");
    }
    printf("-----------------------------------------------------------\n\n");
}
