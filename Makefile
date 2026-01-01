 # POSIX-compatible Makefile for MiniC Compiler
CC=gcc
CFLAGS=-Wall -std=c99 -I src
FLEX=flex
BISON=bison
TARGET=bin/minic.exe
SRCS=src/symbols.c src/semantic.c src/icg.c

.PHONY: all clean test

all: $(TARGET)

lex.yy.c: lexer.l
	$(FLEX) lexer.l

parser.tab.c parser.tab.h: parser.y
	$(BISON) -d parser.y

$(TARGET): lex.yy.c parser.tab.c $(SRCS)
	mkdir -p bin
	$(CC) $(CFLAGS) -o $(TARGET) lex.yy.c parser.tab.c $(SRCS)

test: $(TARGET)
	@echo "Running compiler on tests..."
	$(TARGET) tests/test_features.mc || true
	$(TARGET) tests/error_type_mismatch.mc || true
	$(TARGET) tests/missing_semicolon.mc || true
	$(TARGET) tests/undeclared_var.mc || true
	$(TARGET) tests/redeclaration.mc || true

clean:
	rm -f lex.yy.c parser.tab.c parser.tab.h
	rm -f $(TARGET)
	rm -f errors.log
	@echo "Cleaned generated files"
