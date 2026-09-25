#include <stdio.h>
#include <string.h>

typedef struct {
    int number_lines;
    int number_nonempty_lines;
    int show_nonprinting;
    int show_tabs;
} Flags;

static int check_flag(const char *argument, Flags *flags) {
    if (strcmp(argument, "-n") == 0) {
        flags->number_lines = 1;
        return 1;
    }

    if (strcmp(argument, "-b") == 0) {
        flags->number_nonempty_lines = 1;
        return 1;
    }

    if (strcmp(argument, "-v") == 0) {
        flags->show_nonprinting = 1;
        return 1;
    }

    if (strcmp(argument, "-T") == 0) {
        flags->show_tabs = 1;
        return 1;
    }

    return 0;
}

static void parse_flags(int argc, char *argv[], Flags *flags) {
    for (int i = 1; i < argc; i++) {
        check_flag(argv[i], flags);
    }
}

static int print_file(const char *file_index, Flags flags, int *line_number, int *new_line) {
    FILE *file;
    int c;

    file = fopen(file_index, "rb");

    if (file == NULL) {
        printf("Error opening file\n");
        return 1;
    }

    while ((c = fgetc(file)) != EOF) {
        if (*new_line) {
            if (flags.number_lines) {
                printf("%6d\t", *line_number);
                (*line_number)++;
                *new_line = 0;
            } else if (flags.number_nonempty_lines && c != '\n') {
                printf("%6d\t", *line_number);
                (*line_number)++;
                *new_line = 0;
            }
        }
        
        if (flags.show_nonprinting && c >= 0 && c < 32 && c != '\n' && c != '\t') {
            putchar('^');
            if (c == 0) {
                putchar('@');
            } else {
                putchar('A' + c - 1);
            }
        } else if (flags.show_tabs && c == '\t') {
            putchar('^');
            putchar('I');
        } else {
            putchar(c);
        }

        if (c == '\n') {
            *new_line = 1;
        }
        
    }

    fclose(file);

    return 0;
}

int main(int argc, char *argv[]) {
    Flags flags = {0};
    int line_number = 1;
    int new_line = 1;

    if (argc < 2) {
        printf("File input error\n");
        return 0;
    }

    parse_flags(argc, argv, &flags);

    for (int i = 1; i < argc; i++) {
        if (!check_flag(argv[i], &flags)) {
            print_file(argv[i], flags, &line_number, &new_line);
        }
    }

    return 0;
}