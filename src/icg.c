#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "icg.h"

#define MAX_TAC 1000

char tac[MAX_TAC][100];
int tac_idx = 0;
int temp_count = 0;

char temp_stack[100][20];
int temp_top = -1;

void init_icg() {
    tac_idx = 0;
    temp_count = 0;
    temp_top = -1;
}

char* new_temp() {
    static char temp[20];
    sprintf(temp, "t%d", temp_count++);
    return temp;
}

void push_temp(char* temp) {
    if (temp_top < 99) {
        strcpy(temp_stack[++temp_top], temp);
    }
}

char* pop_temp() {
    if (temp_top >= 0) {
        return temp_stack[temp_top--];
    }
    return "t0";
}

void emit(char* code) {
    if (tac_idx < MAX_TAC) {
        strcpy(tac[tac_idx++], code);
    }
}

void gen_const_int(int v) {
    char code[100];
    char* temp = new_temp();
    sprintf(code, "%s = %d", temp, v);
    emit(code);
    push_temp(temp);
}

void gen_const_float(float v) {
    char code[100];
    char* temp = new_temp();
    sprintf(code, "%s = %.2f", temp, v);
    emit(code);
    push_temp(temp);
}

void gen_const_string(const char *s) {
    char code[200];
    char* temp = new_temp();
    /* store string literal (unquoted) in TAC for clarity */
    snprintf(code, sizeof(code), "%s = \"%s\"", temp, s);
    emit(code);
    push_temp(temp);
}

void gen_id(char* name) {
    char code[100];
    char* temp = new_temp();
    sprintf(code, "%s = %s", temp, name);
    emit(code);
    push_temp(temp);
}

void gen_binary_op(char* op) {
    char code[100];
    char* t2 = pop_temp();
    char* t1 = pop_temp();
    char* result = new_temp();
    sprintf(code, "%s = %s %s %s", result, t1, op, t2);
    emit(code);
    push_temp(result);
}

void gen_assign(char* id) {
    char code[100];
    char* temp = pop_temp();
    sprintf(code, "%s = %s", id, temp);
    emit(code);
}

void gen_output() {
    char code[200];
    char* temp = pop_temp();
    snprintf(code, sizeof(code), "print %s", temp);
    emit(code);
}

void gen_input(const char *id) {
    char code[200];
    snprintf(code, sizeof(code), "read %s", id);
    emit(code);
}

void print_icg() {
    printf("\n=== Three-Address Code (TAC) ===\n");
    for (int i = 0; i < tac_idx; i++) {
        printf("%3d: %s\n", i+1, tac[i]);
    }
    printf("=================================\n");
}
