#!/bin/sh
set -u
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROGRAM="$SCRIPT_DIR/s21_grep"
REFERENCE=${GREP_REFERENCE:-$(command -v grep)}
if [ ! -x "$PROGRAM" ]; then
  echo "Build s21_grep first" >&2
  exit 1
fi
. "$SCRIPT_DIR/../common/test_helpers.sh"
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/s21_grep_test.XXXXXX") || exit 1
trap 'rm -rf "$TEMP_DIR"' EXIT HUP INT TERM
cd "$TEMP_DIR" || exit 1
printf 'apple apple\nAlpha 123\nalpha 456\nerror 789\nwarning\nba\n\nlast' > main.txt
printf 'APPLE\nerror\napple42\nnone\n' > second.txt
printf 'nothing\nzzz\n' > no_match.txt
printf 'apple\nerror\n' > patterns.txt
printf '\n' > blank_pattern.txt
printf 'apple\r\n' > crlf_pattern.txt
printf 'apple\r\napple\n' > crlf.txt
printf 'a\nbb\n' > ./-n
: > empty.txt
printf 'ba\naba\nxaaa\n' > zero.txt
printf 'alpha\n' > stdin.txt
run_test 'no options' apple main.txt
run_test stdin alpha
run_test 'stdin dash' alpha -
run_test 'empty file' apple empty.txt
run_test 'missing file' apple missing.txt
run_test 'continue after missing file' apple missing.txt main.txt
run_test 'silent missing' -s apple missing.txt
run_test 'invalid regex' '[' main.txt
run_test 'invalid option' --invalid-option apple main.txt
run_test 'missing e argument' -e
run_test 'missing f argument' -f
run_test 'missing pattern'
run_test 'empty pattern' '' main.txt
run_test 'blank pattern file' -f blank_pattern.txt main.txt
run_test 'empty pattern file' -f empty.txt main.txt
run_test 'invert empty pattern file' -v -f empty.txt main.txt
run_test 'missing pattern file' -f missing.txt main.txt
run_test 'silent missing pattern file' -f missing.txt -s main.txt
run_test 'pattern file stdin' -f - main.txt
run_test 'multiline pattern' -e 'apple
error' main.txt
run_test 'trailing newline pattern' -e 'apple
' main.txt
run_test 'attached e' -eapple main.txt
run_test 'attached f' -fpatterns.txt main.txt
run_test 'pattern after --' -- apple main.txt
run_test 'option-like filename' -e a -- -n
run_test 'option after file' apple main.txt -n
run_test 'explicit pattern after operand' main.txt -e apple
run_test 'repeated patterns' -e apple -e apple -f patterns.txt main.txt
run_test 'cl no match' -cl apple no_match.txt
run_test 'lc mixed files' -lc apple no_match.txt main.txt
run_test 'o skip empty match' -o 'a*' zero.txt
run_test 'o empty alternative' -o -e '' -e a zero.txt
run_test 'o longest alternative' -o -e a -e apple main.txt
run_test 'o anchors' -on '^a' zero.txt
run_test 'o end anchor' -o '$' zero.txt
run_test 'o anchored alternatives' -o -e '^' -e a zero.txt
run_test 'basic regex groups' '\(apple\)\{1,2\}' main.txt
run_test 'single -e' -e apple main.txt
run_test 'single -i' -i apple main.txt
run_test 'single -v' -v apple main.txt
run_test 'single -c' -c apple main.txt
run_test 'single -l' -l apple main.txt
run_test 'single -n' -n apple main.txt
run_test 'single -h' -h apple main.txt
run_test 'single -s' -s apple main.txt
run_test 'single -f' -f patterns.txt main.txt
run_test 'single -o' -o apple main.txt
run_test 'pair -e -e ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -e apple -e apple main.txt second.txt
run_test 'pair -e -e ['"'"'no_match.txt'"'"']' -e apple -e apple no_match.txt
run_test 'pair -e -e ['"'"'empty.txt'"'"']' -e apple -e apple empty.txt
run_test 'pair -e -i ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -e apple -i main.txt second.txt
run_test 'pair -e -i ['"'"'no_match.txt'"'"']' -e apple -i no_match.txt
run_test 'pair -e -i ['"'"'empty.txt'"'"']' -e apple -i empty.txt
run_test 'pair -e -v ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -e apple -v main.txt second.txt
run_test 'pair -e -v ['"'"'no_match.txt'"'"']' -e apple -v no_match.txt
run_test 'pair -e -v ['"'"'empty.txt'"'"']' -e apple -v empty.txt
run_test 'pair -e -c ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -e apple -c main.txt second.txt
run_test 'pair -e -c ['"'"'no_match.txt'"'"']' -e apple -c no_match.txt
run_test 'pair -e -c ['"'"'empty.txt'"'"']' -e apple -c empty.txt
run_test 'pair -e -l ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -e apple -l main.txt second.txt
run_test 'pair -e -l ['"'"'no_match.txt'"'"']' -e apple -l no_match.txt
run_test 'pair -e -l ['"'"'empty.txt'"'"']' -e apple -l empty.txt
run_test 'pair -e -n ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -e apple -n main.txt second.txt
run_test 'pair -e -n ['"'"'no_match.txt'"'"']' -e apple -n no_match.txt
run_test 'pair -e -n ['"'"'empty.txt'"'"']' -e apple -n empty.txt
run_test 'pair -e -h ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -e apple -h main.txt second.txt
run_test 'pair -e -h ['"'"'no_match.txt'"'"']' -e apple -h no_match.txt
run_test 'pair -e -h ['"'"'empty.txt'"'"']' -e apple -h empty.txt
run_test 'pair -e -s ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -e apple -s main.txt second.txt
run_test 'pair -e -s ['"'"'no_match.txt'"'"']' -e apple -s no_match.txt
run_test 'pair -e -s ['"'"'empty.txt'"'"']' -e apple -s empty.txt
run_test 'pair -e -f ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -e apple -f patterns.txt main.txt second.txt
run_test 'pair -e -f ['"'"'no_match.txt'"'"']' -e apple -f patterns.txt no_match.txt
run_test 'pair -e -f ['"'"'empty.txt'"'"']' -e apple -f patterns.txt empty.txt
run_test 'pair -e -o ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -e apple -o main.txt second.txt
run_test 'pair -e -o ['"'"'no_match.txt'"'"']' -e apple -o no_match.txt
run_test 'pair -e -o ['"'"'empty.txt'"'"']' -e apple -o empty.txt
run_test 'pair -i -e ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -i -e apple main.txt second.txt
run_test 'pair -i -e ['"'"'no_match.txt'"'"']' -i -e apple no_match.txt
run_test 'pair -i -e ['"'"'empty.txt'"'"']' -i -e apple empty.txt
run_test 'pair -i -i ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -i -i apple main.txt second.txt
run_test 'pair -i -i ['"'"'no_match.txt'"'"']' -i -i apple no_match.txt
run_test 'pair -i -i ['"'"'empty.txt'"'"']' -i -i apple empty.txt
run_test 'pair -i -v ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -i -v apple main.txt second.txt
run_test 'pair -i -v ['"'"'no_match.txt'"'"']' -i -v apple no_match.txt
run_test 'pair -i -v ['"'"'empty.txt'"'"']' -i -v apple empty.txt
run_test 'pair -i -c ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -i -c apple main.txt second.txt
run_test 'pair -i -c ['"'"'no_match.txt'"'"']' -i -c apple no_match.txt
run_test 'pair -i -c ['"'"'empty.txt'"'"']' -i -c apple empty.txt
run_test 'pair -i -l ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -i -l apple main.txt second.txt
run_test 'pair -i -l ['"'"'no_match.txt'"'"']' -i -l apple no_match.txt
run_test 'pair -i -l ['"'"'empty.txt'"'"']' -i -l apple empty.txt
run_test 'pair -i -n ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -i -n apple main.txt second.txt
run_test 'pair -i -n ['"'"'no_match.txt'"'"']' -i -n apple no_match.txt
run_test 'pair -i -n ['"'"'empty.txt'"'"']' -i -n apple empty.txt
run_test 'pair -i -h ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -i -h apple main.txt second.txt
run_test 'pair -i -h ['"'"'no_match.txt'"'"']' -i -h apple no_match.txt
run_test 'pair -i -h ['"'"'empty.txt'"'"']' -i -h apple empty.txt
run_test 'pair -i -s ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -i -s apple main.txt second.txt
run_test 'pair -i -s ['"'"'no_match.txt'"'"']' -i -s apple no_match.txt
run_test 'pair -i -s ['"'"'empty.txt'"'"']' -i -s apple empty.txt
run_test 'pair -i -f ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -i -f patterns.txt main.txt second.txt
run_test 'pair -i -f ['"'"'no_match.txt'"'"']' -i -f patterns.txt no_match.txt
run_test 'pair -i -f ['"'"'empty.txt'"'"']' -i -f patterns.txt empty.txt
run_test 'pair -i -o ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -i -o apple main.txt second.txt
run_test 'pair -i -o ['"'"'no_match.txt'"'"']' -i -o apple no_match.txt
run_test 'pair -i -o ['"'"'empty.txt'"'"']' -i -o apple empty.txt
run_test 'pair -v -e ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -v -e apple main.txt second.txt
run_test 'pair -v -e ['"'"'no_match.txt'"'"']' -v -e apple no_match.txt
run_test 'pair -v -e ['"'"'empty.txt'"'"']' -v -e apple empty.txt
run_test 'pair -v -i ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -v -i apple main.txt second.txt
run_test 'pair -v -i ['"'"'no_match.txt'"'"']' -v -i apple no_match.txt
run_test 'pair -v -i ['"'"'empty.txt'"'"']' -v -i apple empty.txt
run_test 'pair -v -v ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -v -v apple main.txt second.txt
run_test 'pair -v -v ['"'"'no_match.txt'"'"']' -v -v apple no_match.txt
run_test 'pair -v -v ['"'"'empty.txt'"'"']' -v -v apple empty.txt
run_test 'pair -v -c ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -v -c apple main.txt second.txt
run_test 'pair -v -c ['"'"'no_match.txt'"'"']' -v -c apple no_match.txt
run_test 'pair -v -c ['"'"'empty.txt'"'"']' -v -c apple empty.txt
run_test 'pair -v -l ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -v -l apple main.txt second.txt
run_test 'pair -v -l ['"'"'no_match.txt'"'"']' -v -l apple no_match.txt
run_test 'pair -v -l ['"'"'empty.txt'"'"']' -v -l apple empty.txt
run_test 'pair -v -n ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -v -n apple main.txt second.txt
run_test 'pair -v -n ['"'"'no_match.txt'"'"']' -v -n apple no_match.txt
run_test 'pair -v -n ['"'"'empty.txt'"'"']' -v -n apple empty.txt
run_test 'pair -v -h ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -v -h apple main.txt second.txt
run_test 'pair -v -h ['"'"'no_match.txt'"'"']' -v -h apple no_match.txt
run_test 'pair -v -h ['"'"'empty.txt'"'"']' -v -h apple empty.txt
run_test 'pair -v -s ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -v -s apple main.txt second.txt
run_test 'pair -v -s ['"'"'no_match.txt'"'"']' -v -s apple no_match.txt
run_test 'pair -v -s ['"'"'empty.txt'"'"']' -v -s apple empty.txt
run_test 'pair -v -f ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -v -f patterns.txt main.txt second.txt
run_test 'pair -v -f ['"'"'no_match.txt'"'"']' -v -f patterns.txt no_match.txt
run_test 'pair -v -f ['"'"'empty.txt'"'"']' -v -f patterns.txt empty.txt
run_test 'pair -v -o ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -v -o apple main.txt second.txt
run_test 'pair -v -o ['"'"'no_match.txt'"'"']' -v -o apple no_match.txt
run_test 'pair -v -o ['"'"'empty.txt'"'"']' -v -o apple empty.txt
run_test 'pair -c -e ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -c -e apple main.txt second.txt
run_test 'pair -c -e ['"'"'no_match.txt'"'"']' -c -e apple no_match.txt
run_test 'pair -c -e ['"'"'empty.txt'"'"']' -c -e apple empty.txt
run_test 'pair -c -i ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -c -i apple main.txt second.txt
run_test 'pair -c -i ['"'"'no_match.txt'"'"']' -c -i apple no_match.txt
run_test 'pair -c -i ['"'"'empty.txt'"'"']' -c -i apple empty.txt
run_test 'pair -c -v ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -c -v apple main.txt second.txt
run_test 'pair -c -v ['"'"'no_match.txt'"'"']' -c -v apple no_match.txt
run_test 'pair -c -v ['"'"'empty.txt'"'"']' -c -v apple empty.txt
run_test 'pair -c -c ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -c -c apple main.txt second.txt
run_test 'pair -c -c ['"'"'no_match.txt'"'"']' -c -c apple no_match.txt
run_test 'pair -c -c ['"'"'empty.txt'"'"']' -c -c apple empty.txt
run_test 'pair -c -l ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -c -l apple main.txt second.txt
run_test 'pair -c -l ['"'"'no_match.txt'"'"']' -c -l apple no_match.txt
run_test 'pair -c -l ['"'"'empty.txt'"'"']' -c -l apple empty.txt
run_test 'pair -c -n ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -c -n apple main.txt second.txt
run_test 'pair -c -n ['"'"'no_match.txt'"'"']' -c -n apple no_match.txt
run_test 'pair -c -n ['"'"'empty.txt'"'"']' -c -n apple empty.txt
run_test 'pair -c -h ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -c -h apple main.txt second.txt
run_test 'pair -c -h ['"'"'no_match.txt'"'"']' -c -h apple no_match.txt
run_test 'pair -c -h ['"'"'empty.txt'"'"']' -c -h apple empty.txt
run_test 'pair -c -s ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -c -s apple main.txt second.txt
run_test 'pair -c -s ['"'"'no_match.txt'"'"']' -c -s apple no_match.txt
run_test 'pair -c -s ['"'"'empty.txt'"'"']' -c -s apple empty.txt
run_test 'pair -c -f ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -c -f patterns.txt main.txt second.txt
run_test 'pair -c -f ['"'"'no_match.txt'"'"']' -c -f patterns.txt no_match.txt
run_test 'pair -c -f ['"'"'empty.txt'"'"']' -c -f patterns.txt empty.txt
run_test 'pair -c -o ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -c -o apple main.txt second.txt
run_test 'pair -c -o ['"'"'no_match.txt'"'"']' -c -o apple no_match.txt
run_test 'pair -c -o ['"'"'empty.txt'"'"']' -c -o apple empty.txt
run_test 'pair -l -e ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -l -e apple main.txt second.txt
run_test 'pair -l -e ['"'"'no_match.txt'"'"']' -l -e apple no_match.txt
run_test 'pair -l -e ['"'"'empty.txt'"'"']' -l -e apple empty.txt
run_test 'pair -l -i ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -l -i apple main.txt second.txt
run_test 'pair -l -i ['"'"'no_match.txt'"'"']' -l -i apple no_match.txt
run_test 'pair -l -i ['"'"'empty.txt'"'"']' -l -i apple empty.txt
run_test 'pair -l -v ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -l -v apple main.txt second.txt
run_test 'pair -l -v ['"'"'no_match.txt'"'"']' -l -v apple no_match.txt
run_test 'pair -l -v ['"'"'empty.txt'"'"']' -l -v apple empty.txt
run_test 'pair -l -c ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -l -c apple main.txt second.txt
run_test 'pair -l -c ['"'"'no_match.txt'"'"']' -l -c apple no_match.txt
run_test 'pair -l -c ['"'"'empty.txt'"'"']' -l -c apple empty.txt
run_test 'pair -l -l ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -l -l apple main.txt second.txt
run_test 'pair -l -l ['"'"'no_match.txt'"'"']' -l -l apple no_match.txt
run_test 'pair -l -l ['"'"'empty.txt'"'"']' -l -l apple empty.txt
run_test 'pair -l -n ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -l -n apple main.txt second.txt
run_test 'pair -l -n ['"'"'no_match.txt'"'"']' -l -n apple no_match.txt
run_test 'pair -l -n ['"'"'empty.txt'"'"']' -l -n apple empty.txt
run_test 'pair -l -h ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -l -h apple main.txt second.txt
run_test 'pair -l -h ['"'"'no_match.txt'"'"']' -l -h apple no_match.txt
run_test 'pair -l -h ['"'"'empty.txt'"'"']' -l -h apple empty.txt
run_test 'pair -l -s ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -l -s apple main.txt second.txt
run_test 'pair -l -s ['"'"'no_match.txt'"'"']' -l -s apple no_match.txt
run_test 'pair -l -s ['"'"'empty.txt'"'"']' -l -s apple empty.txt
run_test 'pair -l -f ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -l -f patterns.txt main.txt second.txt
run_test 'pair -l -f ['"'"'no_match.txt'"'"']' -l -f patterns.txt no_match.txt
run_test 'pair -l -f ['"'"'empty.txt'"'"']' -l -f patterns.txt empty.txt
run_test 'pair -l -o ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -l -o apple main.txt second.txt
run_test 'pair -l -o ['"'"'no_match.txt'"'"']' -l -o apple no_match.txt
run_test 'pair -l -o ['"'"'empty.txt'"'"']' -l -o apple empty.txt
run_test 'pair -n -e ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -n -e apple main.txt second.txt
run_test 'pair -n -e ['"'"'no_match.txt'"'"']' -n -e apple no_match.txt
run_test 'pair -n -e ['"'"'empty.txt'"'"']' -n -e apple empty.txt
run_test 'pair -n -i ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -n -i apple main.txt second.txt
run_test 'pair -n -i ['"'"'no_match.txt'"'"']' -n -i apple no_match.txt
run_test 'pair -n -i ['"'"'empty.txt'"'"']' -n -i apple empty.txt
run_test 'pair -n -v ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -n -v apple main.txt second.txt
run_test 'pair -n -v ['"'"'no_match.txt'"'"']' -n -v apple no_match.txt
run_test 'pair -n -v ['"'"'empty.txt'"'"']' -n -v apple empty.txt
run_test 'pair -n -c ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -n -c apple main.txt second.txt
run_test 'pair -n -c ['"'"'no_match.txt'"'"']' -n -c apple no_match.txt
run_test 'pair -n -c ['"'"'empty.txt'"'"']' -n -c apple empty.txt
run_test 'pair -n -l ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -n -l apple main.txt second.txt
run_test 'pair -n -l ['"'"'no_match.txt'"'"']' -n -l apple no_match.txt
run_test 'pair -n -l ['"'"'empty.txt'"'"']' -n -l apple empty.txt
run_test 'pair -n -n ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -n -n apple main.txt second.txt
run_test 'pair -n -n ['"'"'no_match.txt'"'"']' -n -n apple no_match.txt
run_test 'pair -n -n ['"'"'empty.txt'"'"']' -n -n apple empty.txt
run_test 'pair -n -h ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -n -h apple main.txt second.txt
run_test 'pair -n -h ['"'"'no_match.txt'"'"']' -n -h apple no_match.txt
run_test 'pair -n -h ['"'"'empty.txt'"'"']' -n -h apple empty.txt
run_test 'pair -n -s ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -n -s apple main.txt second.txt
run_test 'pair -n -s ['"'"'no_match.txt'"'"']' -n -s apple no_match.txt
run_test 'pair -n -s ['"'"'empty.txt'"'"']' -n -s apple empty.txt
run_test 'pair -n -f ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -n -f patterns.txt main.txt second.txt
run_test 'pair -n -f ['"'"'no_match.txt'"'"']' -n -f patterns.txt no_match.txt
run_test 'pair -n -f ['"'"'empty.txt'"'"']' -n -f patterns.txt empty.txt
run_test 'pair -n -o ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -n -o apple main.txt second.txt
run_test 'pair -n -o ['"'"'no_match.txt'"'"']' -n -o apple no_match.txt
run_test 'pair -n -o ['"'"'empty.txt'"'"']' -n -o apple empty.txt
run_test 'pair -h -e ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -h -e apple main.txt second.txt
run_test 'pair -h -e ['"'"'no_match.txt'"'"']' -h -e apple no_match.txt
run_test 'pair -h -e ['"'"'empty.txt'"'"']' -h -e apple empty.txt
run_test 'pair -h -i ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -h -i apple main.txt second.txt
run_test 'pair -h -i ['"'"'no_match.txt'"'"']' -h -i apple no_match.txt
run_test 'pair -h -i ['"'"'empty.txt'"'"']' -h -i apple empty.txt
run_test 'pair -h -v ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -h -v apple main.txt second.txt
run_test 'pair -h -v ['"'"'no_match.txt'"'"']' -h -v apple no_match.txt
run_test 'pair -h -v ['"'"'empty.txt'"'"']' -h -v apple empty.txt
run_test 'pair -h -c ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -h -c apple main.txt second.txt
run_test 'pair -h -c ['"'"'no_match.txt'"'"']' -h -c apple no_match.txt
run_test 'pair -h -c ['"'"'empty.txt'"'"']' -h -c apple empty.txt
run_test 'pair -h -l ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -h -l apple main.txt second.txt
run_test 'pair -h -l ['"'"'no_match.txt'"'"']' -h -l apple no_match.txt
run_test 'pair -h -l ['"'"'empty.txt'"'"']' -h -l apple empty.txt
run_test 'pair -h -n ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -h -n apple main.txt second.txt
run_test 'pair -h -n ['"'"'no_match.txt'"'"']' -h -n apple no_match.txt
run_test 'pair -h -n ['"'"'empty.txt'"'"']' -h -n apple empty.txt
run_test 'pair -h -h ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -h -h apple main.txt second.txt
run_test 'pair -h -h ['"'"'no_match.txt'"'"']' -h -h apple no_match.txt
run_test 'pair -h -h ['"'"'empty.txt'"'"']' -h -h apple empty.txt
run_test 'pair -h -s ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -h -s apple main.txt second.txt
run_test 'pair -h -s ['"'"'no_match.txt'"'"']' -h -s apple no_match.txt
run_test 'pair -h -s ['"'"'empty.txt'"'"']' -h -s apple empty.txt
run_test 'pair -h -f ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -h -f patterns.txt main.txt second.txt
run_test 'pair -h -f ['"'"'no_match.txt'"'"']' -h -f patterns.txt no_match.txt
run_test 'pair -h -f ['"'"'empty.txt'"'"']' -h -f patterns.txt empty.txt
run_test 'pair -h -o ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -h -o apple main.txt second.txt
run_test 'pair -h -o ['"'"'no_match.txt'"'"']' -h -o apple no_match.txt
run_test 'pair -h -o ['"'"'empty.txt'"'"']' -h -o apple empty.txt
run_test 'pair -s -e ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -s -e apple main.txt second.txt
run_test 'pair -s -e ['"'"'no_match.txt'"'"']' -s -e apple no_match.txt
run_test 'pair -s -e ['"'"'empty.txt'"'"']' -s -e apple empty.txt
run_test 'pair -s -i ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -s -i apple main.txt second.txt
run_test 'pair -s -i ['"'"'no_match.txt'"'"']' -s -i apple no_match.txt
run_test 'pair -s -i ['"'"'empty.txt'"'"']' -s -i apple empty.txt
run_test 'pair -s -v ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -s -v apple main.txt second.txt
run_test 'pair -s -v ['"'"'no_match.txt'"'"']' -s -v apple no_match.txt
run_test 'pair -s -v ['"'"'empty.txt'"'"']' -s -v apple empty.txt
run_test 'pair -s -c ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -s -c apple main.txt second.txt
run_test 'pair -s -c ['"'"'no_match.txt'"'"']' -s -c apple no_match.txt
run_test 'pair -s -c ['"'"'empty.txt'"'"']' -s -c apple empty.txt
run_test 'pair -s -l ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -s -l apple main.txt second.txt
run_test 'pair -s -l ['"'"'no_match.txt'"'"']' -s -l apple no_match.txt
run_test 'pair -s -l ['"'"'empty.txt'"'"']' -s -l apple empty.txt
run_test 'pair -s -n ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -s -n apple main.txt second.txt
run_test 'pair -s -n ['"'"'no_match.txt'"'"']' -s -n apple no_match.txt
run_test 'pair -s -n ['"'"'empty.txt'"'"']' -s -n apple empty.txt
run_test 'pair -s -h ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -s -h apple main.txt second.txt
run_test 'pair -s -h ['"'"'no_match.txt'"'"']' -s -h apple no_match.txt
run_test 'pair -s -h ['"'"'empty.txt'"'"']' -s -h apple empty.txt
run_test 'pair -s -s ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -s -s apple main.txt second.txt
run_test 'pair -s -s ['"'"'no_match.txt'"'"']' -s -s apple no_match.txt
run_test 'pair -s -s ['"'"'empty.txt'"'"']' -s -s apple empty.txt
run_test 'pair -s -f ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -s -f patterns.txt main.txt second.txt
run_test 'pair -s -f ['"'"'no_match.txt'"'"']' -s -f patterns.txt no_match.txt
run_test 'pair -s -f ['"'"'empty.txt'"'"']' -s -f patterns.txt empty.txt
run_test 'pair -s -o ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -s -o apple main.txt second.txt
run_test 'pair -s -o ['"'"'no_match.txt'"'"']' -s -o apple no_match.txt
run_test 'pair -s -o ['"'"'empty.txt'"'"']' -s -o apple empty.txt
run_test 'pair -f -e ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -f patterns.txt -e apple main.txt second.txt
run_test 'pair -f -e ['"'"'no_match.txt'"'"']' -f patterns.txt -e apple no_match.txt
run_test 'pair -f -e ['"'"'empty.txt'"'"']' -f patterns.txt -e apple empty.txt
run_test 'pair -f -i ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -f patterns.txt -i main.txt second.txt
run_test 'pair -f -i ['"'"'no_match.txt'"'"']' -f patterns.txt -i no_match.txt
run_test 'pair -f -i ['"'"'empty.txt'"'"']' -f patterns.txt -i empty.txt
run_test 'pair -f -v ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -f patterns.txt -v main.txt second.txt
run_test 'pair -f -v ['"'"'no_match.txt'"'"']' -f patterns.txt -v no_match.txt
run_test 'pair -f -v ['"'"'empty.txt'"'"']' -f patterns.txt -v empty.txt
run_test 'pair -f -c ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -f patterns.txt -c main.txt second.txt
run_test 'pair -f -c ['"'"'no_match.txt'"'"']' -f patterns.txt -c no_match.txt
run_test 'pair -f -c ['"'"'empty.txt'"'"']' -f patterns.txt -c empty.txt
run_test 'pair -f -l ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -f patterns.txt -l main.txt second.txt
run_test 'pair -f -l ['"'"'no_match.txt'"'"']' -f patterns.txt -l no_match.txt
run_test 'pair -f -l ['"'"'empty.txt'"'"']' -f patterns.txt -l empty.txt
run_test 'pair -f -n ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -f patterns.txt -n main.txt second.txt
run_test 'pair -f -n ['"'"'no_match.txt'"'"']' -f patterns.txt -n no_match.txt
run_test 'pair -f -n ['"'"'empty.txt'"'"']' -f patterns.txt -n empty.txt
run_test 'pair -f -h ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -f patterns.txt -h main.txt second.txt
run_test 'pair -f -h ['"'"'no_match.txt'"'"']' -f patterns.txt -h no_match.txt
run_test 'pair -f -h ['"'"'empty.txt'"'"']' -f patterns.txt -h empty.txt
run_test 'pair -f -s ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -f patterns.txt -s main.txt second.txt
run_test 'pair -f -s ['"'"'no_match.txt'"'"']' -f patterns.txt -s no_match.txt
run_test 'pair -f -s ['"'"'empty.txt'"'"']' -f patterns.txt -s empty.txt
run_test 'pair -f -f ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -f patterns.txt -f patterns.txt main.txt second.txt
run_test 'pair -f -f ['"'"'no_match.txt'"'"']' -f patterns.txt -f patterns.txt no_match.txt
run_test 'pair -f -f ['"'"'empty.txt'"'"']' -f patterns.txt -f patterns.txt empty.txt
run_test 'pair -f -o ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -f patterns.txt -o main.txt second.txt
run_test 'pair -f -o ['"'"'no_match.txt'"'"']' -f patterns.txt -o no_match.txt
run_test 'pair -f -o ['"'"'empty.txt'"'"']' -f patterns.txt -o empty.txt
run_test 'pair -o -e ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -o -e apple main.txt second.txt
run_test 'pair -o -e ['"'"'no_match.txt'"'"']' -o -e apple no_match.txt
run_test 'pair -o -e ['"'"'empty.txt'"'"']' -o -e apple empty.txt
run_test 'pair -o -i ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -o -i apple main.txt second.txt
run_test 'pair -o -i ['"'"'no_match.txt'"'"']' -o -i apple no_match.txt
run_test 'pair -o -i ['"'"'empty.txt'"'"']' -o -i apple empty.txt
run_test 'pair -o -v ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -o -v apple main.txt second.txt
run_test 'pair -o -v ['"'"'no_match.txt'"'"']' -o -v apple no_match.txt
run_test 'pair -o -v ['"'"'empty.txt'"'"']' -o -v apple empty.txt
run_test 'pair -o -c ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -o -c apple main.txt second.txt
run_test 'pair -o -c ['"'"'no_match.txt'"'"']' -o -c apple no_match.txt
run_test 'pair -o -c ['"'"'empty.txt'"'"']' -o -c apple empty.txt
run_test 'pair -o -l ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -o -l apple main.txt second.txt
run_test 'pair -o -l ['"'"'no_match.txt'"'"']' -o -l apple no_match.txt
run_test 'pair -o -l ['"'"'empty.txt'"'"']' -o -l apple empty.txt
run_test 'pair -o -n ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -o -n apple main.txt second.txt
run_test 'pair -o -n ['"'"'no_match.txt'"'"']' -o -n apple no_match.txt
run_test 'pair -o -n ['"'"'empty.txt'"'"']' -o -n apple empty.txt
run_test 'pair -o -h ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -o -h apple main.txt second.txt
run_test 'pair -o -h ['"'"'no_match.txt'"'"']' -o -h apple no_match.txt
run_test 'pair -o -h ['"'"'empty.txt'"'"']' -o -h apple empty.txt
run_test 'pair -o -s ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -o -s apple main.txt second.txt
run_test 'pair -o -s ['"'"'no_match.txt'"'"']' -o -s apple no_match.txt
run_test 'pair -o -s ['"'"'empty.txt'"'"']' -o -s apple empty.txt
run_test 'pair -o -f ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -o -f patterns.txt main.txt second.txt
run_test 'pair -o -f ['"'"'no_match.txt'"'"']' -o -f patterns.txt no_match.txt
run_test 'pair -o -f ['"'"'empty.txt'"'"']' -o -f patterns.txt empty.txt
run_test 'pair -o -o ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' -o -o apple main.txt second.txt
run_test 'pair -o -o ['"'"'no_match.txt'"'"']' -o -o apple no_match.txt
run_test 'pair -o -o ['"'"'empty.txt'"'"']' -o -o apple empty.txt
run_test 'combined -ii' -ii apple main.txt second.txt no_match.txt
run_test 'combined -iv' -iv apple main.txt second.txt no_match.txt
run_test 'combined -ic' -ic apple main.txt second.txt no_match.txt
run_test 'combined -il' -il apple main.txt second.txt no_match.txt
run_test 'combined -in' -in apple main.txt second.txt no_match.txt
run_test 'combined -ih' -ih apple main.txt second.txt no_match.txt
run_test 'combined -is' -is apple main.txt second.txt no_match.txt
run_test 'combined -io' -io apple main.txt second.txt no_match.txt
run_test 'combined -vi' -vi apple main.txt second.txt no_match.txt
run_test 'combined -vv' -vv apple main.txt second.txt no_match.txt
run_test 'combined -vc' -vc apple main.txt second.txt no_match.txt
run_test 'combined -vl' -vl apple main.txt second.txt no_match.txt
run_test 'combined -vn' -vn apple main.txt second.txt no_match.txt
run_test 'combined -vh' -vh apple main.txt second.txt no_match.txt
run_test 'combined -vs' -vs apple main.txt second.txt no_match.txt
run_test 'combined -vo' -vo apple main.txt second.txt no_match.txt
run_test 'combined -ci' -ci apple main.txt second.txt no_match.txt
run_test 'combined -cv' -cv apple main.txt second.txt no_match.txt
run_test 'combined -cc' -cc apple main.txt second.txt no_match.txt
run_test 'combined -cl' -cl apple main.txt second.txt no_match.txt
run_test 'combined -cn' -cn apple main.txt second.txt no_match.txt
run_test 'combined -ch' -ch apple main.txt second.txt no_match.txt
run_test 'combined -cs' -cs apple main.txt second.txt no_match.txt
run_test 'combined -co' -co apple main.txt second.txt no_match.txt
run_test 'combined -li' -li apple main.txt second.txt no_match.txt
run_test 'combined -lv' -lv apple main.txt second.txt no_match.txt
run_test 'combined -lc' -lc apple main.txt second.txt no_match.txt
run_test 'combined -ll' -ll apple main.txt second.txt no_match.txt
run_test 'combined -ln' -ln apple main.txt second.txt no_match.txt
run_test 'combined -lh' -lh apple main.txt second.txt no_match.txt
run_test 'combined -ls' -ls apple main.txt second.txt no_match.txt
run_test 'combined -lo' -lo apple main.txt second.txt no_match.txt
run_test 'combined -ni' -ni apple main.txt second.txt no_match.txt
run_test 'combined -nv' -nv apple main.txt second.txt no_match.txt
run_test 'combined -nc' -nc apple main.txt second.txt no_match.txt
run_test 'combined -nl' -nl apple main.txt second.txt no_match.txt
run_test 'combined -nn' -nn apple main.txt second.txt no_match.txt
run_test 'combined -nh' -nh apple main.txt second.txt no_match.txt
run_test 'combined -ns' -ns apple main.txt second.txt no_match.txt
run_test 'combined -no' -no apple main.txt second.txt no_match.txt
run_test 'combined -hi' -hi apple main.txt second.txt no_match.txt
run_test 'combined -hv' -hv apple main.txt second.txt no_match.txt
run_test 'combined -hc' -hc apple main.txt second.txt no_match.txt
run_test 'combined -hl' -hl apple main.txt second.txt no_match.txt
run_test 'combined -hn' -hn apple main.txt second.txt no_match.txt
run_test 'combined -hh' -hh apple main.txt second.txt no_match.txt
run_test 'combined -hs' -hs apple main.txt second.txt no_match.txt
run_test 'combined -ho' -ho apple main.txt second.txt no_match.txt
run_test 'combined -si' -si apple main.txt second.txt no_match.txt
run_test 'combined -sv' -sv apple main.txt second.txt no_match.txt
run_test 'combined -sc' -sc apple main.txt second.txt no_match.txt
run_test 'combined -sl' -sl apple main.txt second.txt no_match.txt
run_test 'combined -sn' -sn apple main.txt second.txt no_match.txt
run_test 'combined -sh' -sh apple main.txt second.txt no_match.txt
run_test 'combined -ss' -ss apple main.txt second.txt no_match.txt
run_test 'combined -so' -so apple main.txt second.txt no_match.txt
run_test 'combined -oi' -oi apple main.txt second.txt no_match.txt
run_test 'combined -ov' -ov apple main.txt second.txt no_match.txt
run_test 'combined -oc' -oc apple main.txt second.txt no_match.txt
run_test 'combined -ol' -ol apple main.txt second.txt no_match.txt
run_test 'combined -on' -on apple main.txt second.txt no_match.txt
run_test 'combined -oh' -oh apple main.txt second.txt no_match.txt
run_test 'combined -os' -os apple main.txt second.txt no_match.txt
run_test 'combined -oo' -oo apple main.txt second.txt no_match.txt
run_test 'combined -ie' -ie apple main.txt
run_test 'combined -if' -if patterns.txt main.txt
run_test 'combined -ve' -ve apple main.txt
run_test 'combined -vf' -vf patterns.txt main.txt
run_test 'combined -ce' -ce apple main.txt
run_test 'combined -cf' -cf patterns.txt main.txt
run_test 'combined -le' -le apple main.txt
run_test 'combined -lf' -lf patterns.txt main.txt
run_test 'combined -ne' -ne apple main.txt
run_test 'combined -nf' -nf patterns.txt main.txt
run_test 'combined -he' -he apple main.txt
run_test 'combined -hf' -hf patterns.txt main.txt
run_test 'combined -se' -se apple main.txt
run_test 'combined -sf' -sf patterns.txt main.txt
run_test 'combined -oe' -oe apple main.txt
run_test 'combined -of' -of patterns.txt main.txt
# CR is part of the POSIX pattern; Windows ports of grep may strip it.
printf 'apple\r\n' > crlf_expected.txt
run_expected 'CR preserved in pattern file' 0 crlf_expected.txt -f crlf_pattern.txt crlf.txt
finish_tests
