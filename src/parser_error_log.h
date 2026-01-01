#ifndef PARSER_ERROR_LOG_H
#define PARSER_ERROR_LOG_H

#include <stdio.h>

static inline void log_error_msg(const char *msg) {
    FILE *f = fopen("errors.log", "a");
    if (!f) return;
    fprintf(f, "%s\n", msg);
    fclose(f);
}

#endif
