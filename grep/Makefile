CC = gcc
CFLAGS = -std=c11 -Wall -Wextra -Werror -g

.PHONY: all test clean rebuild
all: s21_grep

s21_grep: s21_grep.c
	$(CC) $(CFLAGS) $< -o $@

test: s21_grep
	sh ./test_grep.sh

clean:
	rm -f s21_grep s21_grep.exe *.o

rebuild:
	$(MAKE) clean
	$(MAKE) all
