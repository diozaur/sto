#define _POSIX_C_SOURCE 200809L

#include <errno.h>
#include <regex.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>

typedef struct {
  bool i;
  bool v;
  bool c;
  bool l;
  bool n;
  bool h;
  bool s;
  bool o;
} Flags;

typedef struct {
  char **patterns;
  int pattern_count;
  char **files;
  int file_count;
} Arguments;

static int add_single_pattern(Arguments *args, const char *pattern,
                              size_t length) {
  char **tmp =
      realloc(args->patterns, (args->pattern_count + 1) * sizeof(char *));

  if (!tmp) return 1;

  args->patterns = tmp;

  args->patterns[args->pattern_count] = malloc(length + 1);

  if (!args->patterns[args->pattern_count]) return 1;

  memcpy(args->patterns[args->pattern_count], pattern, length);
  args->patterns[args->pattern_count][length] = '\0';
  args->pattern_count++;

  return 0;
}

static int add_pattern(Arguments *args, const char *pattern) {
  int result = 0;
  const char *start = pattern;
  const char *end;
  do {
    end = strchr(start, '\n');
    size_t length = end ? (size_t)(end - start) : strlen(start);
    result = add_single_pattern(args, start, length);
    if (end) start = end + 1;
  } while (end && !result);
  return result;
}

static void free_patterns(Arguments *args) {
  for (int i = 0; i < args->pattern_count; i++) free(args->patterns[i]);

  free(args->patterns);
  free(args->files);
}

static int read_pattern_file(Arguments *args, const char *name) {
  FILE *file = strcmp(name, "-") == 0 ? stdin : fopen(name, "r");
  char *line = NULL;
  size_t capacity = 0;
  ssize_t length;
  int result = 0;

  if (!file) {
    fprintf(stderr, "s21_grep: %s: %s\n", name, strerror(errno));

    return 1;
  }

  while (!result && (length = getline(&line, &capacity, file)) != -1) {
    if (length > 0 && line[length - 1] == '\n') {
      line[--length] = '\0';
    }
    if (add_pattern(args, line)) {
      result = 1;
    }
  }

  if (ferror(file)) {
    fprintf(stderr, "s21_grep: %s: %s\n", name, strerror(errno));
    result = 1;
  }

  free(line);
  if (file != stdin) fclose(file);
  return result;
}

static int parse_option_group(int argc, char **argv, int *index, Flags *f,
                              Arguments *args, bool *pattern_found) {
  char *arg = argv[*index];

  for (int j = 1; arg[j] != '\0'; j++) {
    switch (arg[j]) {
      case 'i':
        f->i = true;
        break;

      case 'v':
        f->v = true;
        break;

      case 'c':
        f->c = true;
        break;

      case 'l':
        f->l = true;
        break;

      case 'n':
        f->n = true;
        break;

      case 'h':
        f->h = true;
        break;

      case 's':
        f->s = true;
        break;

      case 'o':
        f->o = true;
        break;

      case 'e': {
        const char *pattern = NULL;

        if (arg[j + 1] != '\0') {
          pattern = arg + j + 1;
        } else {
          if (*index + 1 >= argc) return 1;

          (*index)++;
          pattern = argv[*index];
        }

        if (add_pattern(args, pattern)) return 1;

        *pattern_found = true;

        return 0;
      }

      case 'f': {
        const char *filename = NULL;

        if (arg[j + 1] != '\0') {
          filename = arg + j + 1;
        } else {
          if (*index + 1 >= argc) return 1;

          (*index)++;
          filename = argv[*index];
        }

        if (read_pattern_file(args, filename)) return 1;

        *pattern_found = true;

        return 0;
      }

      default:
        return 1;
    }
  }

  return 0;
}

static int parse_args(int argc, char **argv, Flags *f, Arguments *args) {
  bool pattern_found = false;
  bool options = true;
  args->files = malloc((size_t)argc * sizeof(char *));
  if (!args->files) return 1;

  for (int i = 1; i < argc; i++) {
    char *arg = argv[i];

    if (options && !strcmp(arg, "--")) {
      options = false;
    } else if (options && arg[0] == '-' && arg[1] != '\0') {
      if (parse_option_group(argc, argv, &i, f, args, &pattern_found)) return 1;
    } else {
      args->files[args->file_count++] = arg;
    }
  }

  if (!pattern_found) {
    if (args->file_count == 0 || add_pattern(args, args->files[0])) return 1;
    args->file_count--;
    memmove(args->files, args->files + 1,
            (size_t)args->file_count * sizeof(char *));
  }

  return 0;
}

static int compile_patterns(const Arguments *args, const Flags *f,
                            regex_t **regex) {
  int flags = 0;

  if (f->i) flags |= REG_ICASE;

  if (args->pattern_count == 0) return 0;

  *regex = malloc(args->pattern_count * sizeof(regex_t));

  if (!*regex) return 1;

  for (int i = 0; i < args->pattern_count; i++) {
    const char *pattern = args->patterns[i][0] ? args->patterns[i] : "^";
    int error = regcomp(&(*regex)[i], pattern, flags);

    if (error) {
      char message[256];
      regerror(error, &(*regex)[i], message, sizeof(message));
      fprintf(stderr, "s21_grep: %s\n", message);

      for (int j = 0; j < i; j++) regfree(&(*regex)[j]);

      free(*regex);
      *regex = NULL;

      return 1;
    }
  }

  return 0;
}

static bool match_line(const char *line, const regex_t *regex, int count) {
  for (int i = 0; i < count; i++) {
    if (regexec(&regex[i], line, 0, NULL, 0) == 0) return true;
  }

  return false;
}

static void print_matches(const char *line, const char *file, const Flags *f,
                          const regex_t *regex, int regex_count, int number,
                          int files) {
  size_t pos = 0;
  size_t len = strlen(line);

  while (pos < len) {
    regmatch_t best;
    bool found = false;

    for (int i = 0; i < regex_count; i++) {
      regmatch_t match;
      int flags = pos > 0 ? REG_NOTBOL : 0;

      if (regexec(&regex[i], line + pos, 1, &match, flags) == 0) {
        size_t start = pos + match.rm_so;
        size_t end = pos + match.rm_eo;

        if (!found || start < (size_t)best.rm_so ||
            (start == (size_t)best.rm_so && end > (size_t)best.rm_eo)) {
          best.rm_so = (regoff_t)start;
          best.rm_eo = (regoff_t)end;
          found = true;
        }
      }
    }

    if (!found) break;
    if (best.rm_so == best.rm_eo) {
      pos = (size_t)best.rm_eo + 1;
      continue;
    }

    if (files > 1 && !f->h) printf("%s:", file);

    if (f->n) printf("%d:", number);

    printf("%.*s\n", (int)(best.rm_eo - best.rm_so), line + best.rm_so);

    pos = (size_t)best.rm_eo;
  }
}

static int process_file(const char *name, const Flags *f, const regex_t *regex,
                        int regex_count, int file_count) {
  FILE *file = NULL;
  const char *display_name = name;
  char *line = NULL;
  size_t capacity = 0;
  ssize_t length;
  int number = 0;
  int count = 0;
  bool found = false;

  if (!strcmp(name, "-")) {
    file = stdin;
    display_name = "(standard input)";
  } else {
    file = fopen(name, "r");
  }

  if (!file) {
    if (!f->s) fprintf(stderr, "s21_grep: %s: %s\n", name, strerror(errno));

    return 2;
  }

  while ((length = getline(&line, &capacity, file)) != -1) {
    number++;

    if (length > 0 && line[length - 1] == '\n') line[length - 1] = '\0';

    bool matched = match_line(line, regex, regex_count);

    /*
     * -v инвертирует результат поиска.
     */
    if (f->v) matched = !matched;

    if (!matched) continue;

    found = true;
    count++;

    /*
     * -l имеет приоритет над обычным выводом.
     */
    if (f->l) break;

    /*
     * -c только считает количество подходящих строк.
     */
    if (f->c) continue;

    /*
     * Комбинация -v и -o.
     *
     * -v выбирает строки, которые НЕ совпали.
     * -o требует вывести совпавшую часть.
     *
     * В выбранной -v строке совпадения нет,
     * поэтому выводить через -o нечего.
     */
    if (f->o && f->v) continue;

    /*
     * -o выводит только совпавшие части строки.
     */
    if (f->o) {
      print_matches(line, display_name, f, regex, regex_count, number,
                    file_count);
      continue;
    }

    /*
     * Обычный вывод строки.
     */
    if (file_count > 1 && !f->h) printf("%s:", display_name);

    if (f->n) printf("%d:", number);

    printf("%s\n", line);
  }

  /*
   * -l
   */
  if (f->l) {
    if (found) printf("%s\n", display_name);
  }

  /*
   * -c
   */
  else if (f->c) {
    if (file_count > 1 && !f->h) printf("%s:", display_name);

    printf("%d\n", count);
  }

  int read_error = ferror(file);
  free(line);

  if (file != stdin) fclose(file);

  return read_error ? 2 : (found ? 0 : 1);
}

int main(int argc, char **argv) {
  Flags flags = {0};
  Arguments args = {0};
  regex_t *regex = NULL;
  int result = 1;
  bool found = false;
  bool error = false;

  if (parse_args(argc, argv, &flags, &args)) {
    fprintf(stderr, "s21_grep: invalid arguments or unreadable pattern file\n");
    free_patterns(&args);
    return 2;
  }

  if (compile_patterns(&args, &flags, &regex)) {
    free_patterns(&args);
    return 2;
  }

  if (args.file_count == 0) {
    int status = process_file("-", &flags, regex, args.pattern_count, 0);
    found = status == 0;
    error = status == 2;
  } else {
    for (int i = 0; i < args.file_count; i++) {
      int status = process_file(args.files[i], &flags, regex,
                                args.pattern_count, args.file_count);
      if (status == 0) found = true;
      if (status == 2) error = true;
    }
  }

  if (error)
    result = 2;
  else if (found)
    result = 0;

  for (int i = 0; i < args.pattern_count; i++) regfree(&regex[i]);

  free(regex);
  free_patterns(&args);

  if (fflush(stdout) == EOF) result = 2;
  return result;
}
