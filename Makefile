CC = gcc
CFLAGS = -std=c11 -Wall -Wextra -Werror -g

.PHONY: all test clean rebuild
all: s21_cat

s21_cat: s21_cat.c
	$(CC) $(CFLAGS) $< -o $@

test: s21_cat
	sh ./test_cat.sh

clean:
	rm -f s21_cat s21_cat.exe *.o

rebuild:
	$(MAKE) clean
	$(MAKE) all
