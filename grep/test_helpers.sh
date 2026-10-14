# Shared differential test runner for cat and grep.
LC_ALL=C
export LC_ALL
PASSED=0
FAILED=0
run_test() {
  name=$1
  shift
  "$REFERENCE" "$@" < "$TEMP_DIR/stdin.txt" > "$TEMP_DIR/expected" 2> "$TEMP_DIR/expected.err"
  expected_status=$?
  "$PROGRAM" "$@" < "$TEMP_DIR/stdin.txt" > "$TEMP_DIR/actual" 2> "$TEMP_DIR/actual.err"
  actual_status=$?
  expected_error=0
  actual_error=0
  [ ! -s "$TEMP_DIR/expected.err" ] || expected_error=1
  [ ! -s "$TEMP_DIR/actual.err" ] || actual_error=1
  if cmp -s "$TEMP_DIR/expected" "$TEMP_DIR/actual" &&
     [ "$expected_status" -eq "$actual_status" ] &&
     [ "$expected_error" -eq "$actual_error" ]; then
    PASSED=$((PASSED + 1))
  else
    printf 'FAIL %s (exit: reference=%s program=%s; stderr: reference=%s program=%s)\n' "$name" "$expected_status" "$actual_status" "$expected_error" "$actual_error"
    diff -u "$TEMP_DIR/expected" "$TEMP_DIR/actual" || true
    FAILED=$((FAILED + 1))
  fi
}
finish_tests() {
  printf 'RESULT: %s passed, %s failed\n' "$PASSED" "$FAILED"
  [ "$FAILED" -eq 0 ]
}
run_expected() {
  name=$1
  expected_status=$2
  expected_file=$3
  shift 3
  "$PROGRAM" "$@" < "$TEMP_DIR/stdin.txt" > "$TEMP_DIR/actual" 2> "$TEMP_DIR/actual.err"
  actual_status=$?
  if cmp -s "$expected_file" "$TEMP_DIR/actual" &&
     [ "$expected_status" -eq "$actual_status" ] &&
     [ ! -s "$TEMP_DIR/actual.err" ]; then
    PASSED=$((PASSED + 1))
  else
    printf 'FAIL %s (explicit expected output; exit: expected=%s program=%s)\n' "$name" "$expected_status" "$actual_status"
    diff -u "$expected_file" "$TEMP_DIR/actual" || true
    FAILED=$((FAILED + 1))
  fi
}
