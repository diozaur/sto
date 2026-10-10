#include <stdio.h>
#include <string.h>
#include <windows.h>

int show_line_numbers = 0;
int skip_empty_lines = 0;
int show_ends = 0;
int squeeze_blank = 0;
int show_tabs = 0;
int show_nonprinting = 0;
int line_counter = 1;

void print_stream(FILE *f) {
    int c = fgetc(f);
    int is_new_line = 1;
    int empty_line_count = 0;

    while (c != EOF) {
        if (is_new_line && c == '\n') {
            empty_line_count++;
            if (squeeze_blank && empty_line_count > 1) {
                c = fgetc(f);
                continue;
            }
        } else if (c != '\n') {
            empty_line_count = 0;
        }

        if (is_new_line) {
            if ((show_line_numbers || skip_empty_lines) && c != '\n') {
                printf("%6d  ", line_counter++);
                is_new_line = 0;
            }
            else if (show_line_numbers && !skip_empty_lines && c == '\n') {
                printf("%6d  ", line_counter++);
                is_new_line = 0;
            }
        }

        if (show_ends && c == '\n') {
            putc('$', stdout);
        }

        int next_is_newline = (c == '\n');

        if (c == '\t' && show_tabs) {
            printf("^I");
        } else if (show_nonprinting && c != '\t' && c != '\n') {
            if (c >= 32 && c < 127) {
                putc(c, stdout);
            } else if (c == 127) {
                printf("^?");
            } else {
                printf("^%c", c + 64);
            }
        } else {
            putc(c, stdout);
        }

        if (next_is_newline) {
            is_new_line = 1;
        }

        c = fgetc(f);
    }
}

void print_file(char *name) {
    if (strcmp(name, "-") == 0) {
        print_stream(stdin);
        return;
    }

    FILE *f = fopen(name, "rt");
    if (f != NULL) {
        print_stream(f);
        fclose(f);
    } else {
        fprintf(stderr, "mycat: %s: Нет такого файла или каталога\n", name);
    }
}

int main(int argc, char *argv[]) {
    SetConsoleCP(CP_UTF8);
    SetConsoleOutputCP(CP_UTF8);

    int first_file_index = 1;

    while (first_file_index < argc && argv[first_file_index][0] == '-') {
        if (argv[first_file_index][1] == '\0') {
            break;
        }

        if (strcmp(argv[first_file_index], "--") == 0) {
            first_file_index++;
            break;
        }

        if (argv[first_file_index][1] == '-') {
            char *long_flag = &argv[first_file_index][2];

            if (strcmp(long_flag, "number-nonblank") == 0) {
                skip_empty_lines = 1;
            } else if (strcmp(long_flag, "number") == 0) {
                show_line_numbers = 1;
            } else if (strcmp(long_flag, "show-ends") == 0) {
                show_ends = 1;
            } else if (strcmp(long_flag, "squeeze-blank") == 0) {
                squeeze_blank = 1;
            } else if (strcmp(long_flag, "show-tabs") == 0) {
                show_tabs = 1;
            } else if (strcmp(long_flag, "show-nonprinting") == 0) {
                show_nonprinting = 1;
            } else if (strcmp(long_flag, "show-all") == 0) {
                show_nonprinting = 1;
                show_ends = 1;
                show_tabs = 1;
            } else {
                fprintf(stderr, "mycat: нераспознанный параметр '%s'\n", argv[first_file_index]);
                return 1;
            }
        }
        else {
            char *flag_ptr = &argv[first_file_index][1];
            while (*flag_ptr != '\0') {
                switch (*flag_ptr) {
                    case 'n':
                        show_line_numbers = 1;
                        break;
                    case 'b':
                        skip_empty_lines = 1;
                        break;
                    case 'E':
                        show_ends = 1;
                        break;
                    case 'e':
                        show_ends = 1;
                        show_nonprinting = 1;
                        break;
                    case 's':
                        squeeze_blank = 1;
                        break;
                    case 't':
                        show_tabs = 1;
                        show_nonprinting = 1;
                        break;
                    case 'T':
                        show_tabs = 1;
                        break;
                    case 'v':
                        show_nonprinting = 1;
                        break;
                    case 'A':
                        show_nonprinting = 1;
                        show_ends = 1;
                        show_tabs = 1;
                        break;
                    default:
                        fprintf(stderr, "mycat: неизвестный флаг -- '%c'\n", *flag_ptr);
                        return 1;
                }
                flag_ptr++;
            }
        }
        first_file_index++;
    }
    
    if (first_file_index >= argc) {
        print_stream(stdin);
    } else {
        for (int i = first_file_index; i < argc; i++) {
            print_file(argv[i]);
        }
    }

    return 0;
}
