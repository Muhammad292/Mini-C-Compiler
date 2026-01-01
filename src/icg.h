#ifndef ICG_H
#define ICG_H

void init_icg();
void gen_const_int(int v);
void gen_const_float(float v);
void gen_id(char* name);
void gen_binary_op(char* op);
void gen_assign(char* id);
void print_icg();

#endif
