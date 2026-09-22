#include <stdio.h>
#include <string.h>

int main(int argc, char *argv[]) {
    int line_number = 1;
    int new_line = 1;
    int number_lines = 0;
    int number_nonempty_lines = 0;
    int file_index = 1;

    FILE *file;
    int c;

    if (argc > 1 && strcmp(argv[1], "-n") == 0) {
        number_lines = 1;
    }

    if (argc > 1 && strcmp(argv[1], "-b") == 0) {
        number_nonempty_lines = 1;
    }

    if (number_lines || number_nonempty_lines) {
        file_index = 2;
    }

    file = fopen(argv[file_index], "r");

    if (file == NULL) {
        printf("Error opening file\n");
        return 1;
    }
    
    
    while ((c = fgetc(file)) != EOF) {
        if ((number_lines || number_nonempty_lines) && new_line && c != '\n') {
            printf("%6d\t", line_number);
            line_number++;
            new_line = 0;
        }
        
        putchar(c);

        if (c == '\n') {
            new_line = 1;
        }
        
    }

    fclose(file);

    return 0;
}