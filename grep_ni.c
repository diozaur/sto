#include <stdio.h>
#include <string.h>
#include <locale.h>
#include <ctype.h>

#ifdef _WIN32
#include <windows.h>
#endif

#define MAX_LINE_LENGTH 4096

// Глобальные флаги
int ignore_case = 0;
int invert_match = 0;
int count_only = 0;
int files_with_matches = 0;
int show_line_numbers = 0;
char *pattern = NULL;


void to_lowercase(const char *src, char *dest) {
    while (*src) {
        *dest = (char)tolower((unsigned char)*src);
        src++;
        dest++;
    }
    *dest = '\0';
}

int check_match(const char *line, const char *pat) {
    if (ignore_case) {
        char lower_line[MAX_LINE_LENGTH];
        char lower_pat[MAX_LINE_LENGTH];

        to_lowercase(line, lower_line);
        to_lowercase(pat, lower_pat);

        return (strstr(lower_line, lower_pat) != NULL);
    }
    return (strstr(line, pat) != NULL);
}

void search_in_file(char *filename, int multiple_files) {
    FILE *f = fopen(filename, "r");

    if (f == NULL) {
        fprintf(stderr, "mygrep: %s: Нет такого файла или каталога\n", filename);
        return;
    }

    char line[MAX_LINE_LENGTH];
    int line_number = 1;
    int match_count = 0;

    while (fgets(line, sizeof(line), f) != NULL) {
        int is_match = check_match(line, pattern);

        if (invert_match) {
            is_match = !is_match;
        }

        if (is_match) {
            match_count++;

            if (files_with_matches) {
                printf("%s\n", filename);
                fclose(f);
                return;
            }

            if (!count_only) {
                if (multiple_files) {
                    printf("%s:", filename);
                }
                if (show_line_numbers) {
                    printf("%d:", line_number);
                }

                printf("%s", line);

                size_t len = strlen(line);
                if (len > 0 && line[len - 1] != '\n') {
                    printf("\n");
                }
            }
        }
        line_number++;
    }

    if (count_only) {
        if (multiple_files) {
            printf("%s:%d\n", filename, match_count);
        } else {
            printf("%d\n", match_count);
        }
    }

    fclose(f);
}

int main(int argc, char *argv[]) {
#ifdef _WIN32
    SetConsoleCP(CP_UTF8);
    SetConsoleOutputCP(CP_UTF8);
#else
    setlocale(LC_ALL, "");
#endif

    if (argc < 2) {
        printf("Использование: mygrep [-ivcln] [-e шаблон] [шаблон] <файл1> <файл2> ...\n");
        return 1;
    }

    int i = 1;
    while (i < argc && argv[i][0] == '-' && argv[i][1] != '\0') {
        char *flag_ptr = &argv[i][1];

        while (*flag_ptr != '\0') {
            switch (*flag_ptr) {
                case 'i': ignore_case = 1; break;
                case 'v': invert_match = 1; break;
                case 'c': count_only = 1; break;
                case 'l': files_with_matches = 1; break;
                case 'n': show_line_numbers = 1; break;
                case 'e':
                    if (i + 1 < argc) {
                        pattern = argv[++i];
                    } else {
                        fprintf(stderr, "mygrep: флаг -e требует аргумента\n");
                        return 1;
                    }
                    break;
                default:
                    fprintf(stderr, "mygrep: неизвестный флаг -- '%c'\n", *flag_ptr);
                    return 1;
            }
            flag_ptr++;
        }
        i++;
    }

    if (pattern == NULL) {
        if (i < argc) {
            pattern = argv[i++];
        } else {
            fprintf(stderr, "mygrep: не указан шаблон для поиска\n");
            return 1;
        }
    }

    int files_count = argc - i;
    if (files_count <= 0) {
        fprintf(stderr, "mygrep: не указаны файлы для чтения\n");
        return 1;
    }

    int multiple_files = (files_count > 1);

    while (i < argc) {
        search_in_file(argv[i], multiple_files);
        i++;
    }

    return 0;
}
