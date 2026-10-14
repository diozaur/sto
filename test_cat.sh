#!/bin/sh
set -u
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROGRAM="$SCRIPT_DIR/s21_cat"
REFERENCE=${CAT_REFERENCE:-$(command -v cat)}
if [ ! -x "$PROGRAM" ]; then
  echo "Build s21_cat first" >&2
  exit 1
fi
. "$SCRIPT_DIR/../common/test_helpers.sh"
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/s21_cat_test.XXXXXX") || exit 1
trap 'rm -rf "$TEMP_DIR"' EXIT HUP INT TERM
cd "$TEMP_DIR" || exit 1
printf 'one\n\n\n\tTabbed\n\001\177\200\377\nlast' > main.txt
printf 'second\n\nend\n' > second.txt
printf 'a\r\nb\r\n\r\n' > crlf.txt
printf '\n\n' > blank.txt
printf 'last' > tail.txt
printf '\nnext\n' > head.txt
printf 'literal option filename\n' > ./-n
: > empty.txt
cp main.txt stdin.txt
run_test 'basic []'
run_test 'basic ['"'"'-'"'"']' -
run_test 'basic ['"'"'main.txt'"'"']' main.txt
run_test 'basic ['"'"'empty.txt'"'"']' empty.txt
run_test 'basic ['"'"'main.txt'"'"', '"'"'second.txt'"'"']' main.txt second.txt
run_test 'basic ['"'"'--'"'"', '"'"'-n'"'"']' -- -n
run_test 'basic ['"'"'--'"'"', '"'"'main.txt'"'"']' -- main.txt
run_test 'basic ['"'"'-Z'"'"']' -Z
run_test 'basic ['"'"'missing.txt'"'"']' missing.txt
run_test 'basic ['"'"'missing.txt'"'"', '"'"'main.txt'"'"']' missing.txt main.txt
run_test 'basic ['"'"'second.txt'"'"', '"'"'-n'"'"', '"'"'main.txt'"'"']' second.txt -n main.txt
run_test 'flag b ['"'"'main.txt'"'"']' -b main.txt
run_test 'flag b ['"'"'crlf.txt'"'"']' -b crlf.txt
run_test 'flag b ['"'"'blank.txt'"'"', '"'"'blank.txt'"'"']' -b blank.txt blank.txt
run_test 'flag b ['"'"'tail.txt'"'"', '"'"'head.txt'"'"']' -b tail.txt head.txt
run_test 'flag e ['"'"'main.txt'"'"']' -e main.txt
run_test 'flag e ['"'"'crlf.txt'"'"']' -e crlf.txt
run_test 'flag e ['"'"'blank.txt'"'"', '"'"'blank.txt'"'"']' -e blank.txt blank.txt
run_test 'flag e ['"'"'tail.txt'"'"', '"'"'head.txt'"'"']' -e tail.txt head.txt
run_test 'flag n ['"'"'main.txt'"'"']' -n main.txt
run_test 'flag n ['"'"'crlf.txt'"'"']' -n crlf.txt
run_test 'flag n ['"'"'blank.txt'"'"', '"'"'blank.txt'"'"']' -n blank.txt blank.txt
run_test 'flag n ['"'"'tail.txt'"'"', '"'"'head.txt'"'"']' -n tail.txt head.txt
run_test 'flag s ['"'"'main.txt'"'"']' -s main.txt
run_test 'flag s ['"'"'crlf.txt'"'"']' -s crlf.txt
run_test 'flag s ['"'"'blank.txt'"'"', '"'"'blank.txt'"'"']' -s blank.txt blank.txt
run_test 'flag s ['"'"'tail.txt'"'"', '"'"'head.txt'"'"']' -s tail.txt head.txt
run_test 'flag t ['"'"'main.txt'"'"']' -t main.txt
run_test 'flag t ['"'"'crlf.txt'"'"']' -t crlf.txt
run_test 'flag t ['"'"'blank.txt'"'"', '"'"'blank.txt'"'"']' -t blank.txt blank.txt
run_test 'flag t ['"'"'tail.txt'"'"', '"'"'head.txt'"'"']' -t tail.txt head.txt
run_test 'flag v ['"'"'main.txt'"'"']' -v main.txt
run_test 'flag v ['"'"'crlf.txt'"'"']' -v crlf.txt
run_test 'flag v ['"'"'blank.txt'"'"', '"'"'blank.txt'"'"']' -v blank.txt blank.txt
run_test 'flag v ['"'"'tail.txt'"'"', '"'"'head.txt'"'"']' -v tail.txt head.txt
run_test 'flag E ['"'"'main.txt'"'"']' -E main.txt
run_test 'flag E ['"'"'blank.txt'"'"', '"'"'blank.txt'"'"']' -E blank.txt blank.txt
run_test 'flag E ['"'"'tail.txt'"'"', '"'"'head.txt'"'"']' -E tail.txt head.txt
run_test 'flag T ['"'"'main.txt'"'"']' -T main.txt
run_test 'flag T ['"'"'crlf.txt'"'"']' -T crlf.txt
run_test 'flag T ['"'"'blank.txt'"'"', '"'"'blank.txt'"'"']' -T blank.txt blank.txt
run_test 'flag T ['"'"'tail.txt'"'"', '"'"'head.txt'"'"']' -T tail.txt head.txt
run_test 'flag -number ['"'"'main.txt'"'"']' --number main.txt
run_test 'flag -number ['"'"'crlf.txt'"'"']' --number crlf.txt
run_test 'flag -number ['"'"'blank.txt'"'"', '"'"'blank.txt'"'"']' --number blank.txt blank.txt
run_test 'flag -number ['"'"'tail.txt'"'"', '"'"'head.txt'"'"']' --number tail.txt head.txt
run_test 'flag -number-nonblank ['"'"'main.txt'"'"']' --number-nonblank main.txt
run_test 'flag -number-nonblank ['"'"'crlf.txt'"'"']' --number-nonblank crlf.txt
run_test 'flag -number-nonblank ['"'"'blank.txt'"'"', '"'"'blank.txt'"'"']' --number-nonblank blank.txt blank.txt
run_test 'flag -number-nonblank ['"'"'tail.txt'"'"', '"'"'head.txt'"'"']' --number-nonblank tail.txt head.txt
run_test 'flag -squeeze-blank ['"'"'main.txt'"'"']' --squeeze-blank main.txt
run_test 'flag -squeeze-blank ['"'"'crlf.txt'"'"']' --squeeze-blank crlf.txt
run_test 'flag -squeeze-blank ['"'"'blank.txt'"'"', '"'"'blank.txt'"'"']' --squeeze-blank blank.txt blank.txt
run_test 'flag -squeeze-blank ['"'"'tail.txt'"'"', '"'"'head.txt'"'"']' --squeeze-blank tail.txt head.txt
run_test 'combined -bb' -bb main.txt second.txt
run_test 'separate -b -b' -b -b main.txt second.txt
run_test 'combined -be' -be main.txt second.txt
run_test 'separate -b -e' -b -e main.txt second.txt
run_test 'combined -bn' -bn main.txt second.txt
run_test 'separate -b -n' -b -n main.txt second.txt
run_test 'combined -bs' -bs main.txt second.txt
run_test 'separate -b -s' -b -s main.txt second.txt
run_test 'combined -bt' -bt main.txt second.txt
run_test 'separate -b -t' -b -t main.txt second.txt
run_test 'combined -bv' -bv main.txt second.txt
run_test 'separate -b -v' -b -v main.txt second.txt
run_test 'combined -bE' -bE main.txt second.txt
run_test 'separate -b -E' -b -E main.txt second.txt
run_test 'combined -bT' -bT main.txt second.txt
run_test 'separate -b -T' -b -T main.txt second.txt
run_test 'combined -eb' -eb main.txt second.txt
run_test 'separate -e -b' -e -b main.txt second.txt
run_test 'combined -ee' -ee main.txt second.txt
run_test 'separate -e -e' -e -e main.txt second.txt
run_test 'combined -en' -en main.txt second.txt
run_test 'separate -e -n' -e -n main.txt second.txt
run_test 'combined -es' -es main.txt second.txt
run_test 'separate -e -s' -e -s main.txt second.txt
run_test 'combined -et' -et main.txt second.txt
run_test 'separate -e -t' -e -t main.txt second.txt
run_test 'combined -ev' -ev main.txt second.txt
run_test 'separate -e -v' -e -v main.txt second.txt
run_test 'combined -eE' -eE main.txt second.txt
run_test 'separate -e -E' -e -E main.txt second.txt
run_test 'combined -eT' -eT main.txt second.txt
run_test 'separate -e -T' -e -T main.txt second.txt
run_test 'combined -nb' -nb main.txt second.txt
run_test 'separate -n -b' -n -b main.txt second.txt
run_test 'combined -ne' -ne main.txt second.txt
run_test 'separate -n -e' -n -e main.txt second.txt
run_test 'combined -nn' -nn main.txt second.txt
run_test 'separate -n -n' -n -n main.txt second.txt
run_test 'combined -ns' -ns main.txt second.txt
run_test 'separate -n -s' -n -s main.txt second.txt
run_test 'combined -nt' -nt main.txt second.txt
run_test 'separate -n -t' -n -t main.txt second.txt
run_test 'combined -nv' -nv main.txt second.txt
run_test 'separate -n -v' -n -v main.txt second.txt
run_test 'combined -nE' -nE main.txt second.txt
run_test 'separate -n -E' -n -E main.txt second.txt
run_test 'combined -nT' -nT main.txt second.txt
run_test 'separate -n -T' -n -T main.txt second.txt
run_test 'combined -sb' -sb main.txt second.txt
run_test 'separate -s -b' -s -b main.txt second.txt
run_test 'combined -se' -se main.txt second.txt
run_test 'separate -s -e' -s -e main.txt second.txt
run_test 'combined -sn' -sn main.txt second.txt
run_test 'separate -s -n' -s -n main.txt second.txt
run_test 'combined -ss' -ss main.txt second.txt
run_test 'separate -s -s' -s -s main.txt second.txt
run_test 'combined -st' -st main.txt second.txt
run_test 'separate -s -t' -s -t main.txt second.txt
run_test 'combined -sv' -sv main.txt second.txt
run_test 'separate -s -v' -s -v main.txt second.txt
run_test 'combined -sE' -sE main.txt second.txt
run_test 'separate -s -E' -s -E main.txt second.txt
run_test 'combined -sT' -sT main.txt second.txt
run_test 'separate -s -T' -s -T main.txt second.txt
run_test 'combined -tb' -tb main.txt second.txt
run_test 'separate -t -b' -t -b main.txt second.txt
run_test 'combined -te' -te main.txt second.txt
run_test 'separate -t -e' -t -e main.txt second.txt
run_test 'combined -tn' -tn main.txt second.txt
run_test 'separate -t -n' -t -n main.txt second.txt
run_test 'combined -ts' -ts main.txt second.txt
run_test 'separate -t -s' -t -s main.txt second.txt
run_test 'combined -tt' -tt main.txt second.txt
run_test 'separate -t -t' -t -t main.txt second.txt
run_test 'combined -tv' -tv main.txt second.txt
run_test 'separate -t -v' -t -v main.txt second.txt
run_test 'combined -tE' -tE main.txt second.txt
run_test 'separate -t -E' -t -E main.txt second.txt
run_test 'combined -tT' -tT main.txt second.txt
run_test 'separate -t -T' -t -T main.txt second.txt
run_test 'combined -vb' -vb main.txt second.txt
run_test 'separate -v -b' -v -b main.txt second.txt
run_test 'combined -ve' -ve main.txt second.txt
run_test 'separate -v -e' -v -e main.txt second.txt
run_test 'combined -vn' -vn main.txt second.txt
run_test 'separate -v -n' -v -n main.txt second.txt
run_test 'combined -vs' -vs main.txt second.txt
run_test 'separate -v -s' -v -s main.txt second.txt
run_test 'combined -vt' -vt main.txt second.txt
run_test 'separate -v -t' -v -t main.txt second.txt
run_test 'combined -vv' -vv main.txt second.txt
run_test 'separate -v -v' -v -v main.txt second.txt
run_test 'combined -vE' -vE main.txt second.txt
run_test 'separate -v -E' -v -E main.txt second.txt
run_test 'combined -vT' -vT main.txt second.txt
run_test 'separate -v -T' -v -T main.txt second.txt
run_test 'combined -Eb' -Eb main.txt second.txt
run_test 'separate -E -b' -E -b main.txt second.txt
run_test 'combined -Ee' -Ee main.txt second.txt
run_test 'separate -E -e' -E -e main.txt second.txt
run_test 'combined -En' -En main.txt second.txt
run_test 'separate -E -n' -E -n main.txt second.txt
run_test 'combined -Es' -Es main.txt second.txt
run_test 'separate -E -s' -E -s main.txt second.txt
run_test 'combined -Et' -Et main.txt second.txt
run_test 'separate -E -t' -E -t main.txt second.txt
run_test 'combined -Ev' -Ev main.txt second.txt
run_test 'separate -E -v' -E -v main.txt second.txt
run_test 'combined -EE' -EE main.txt second.txt
run_test 'separate -E -E' -E -E main.txt second.txt
run_test 'combined -ET' -ET main.txt second.txt
run_test 'separate -E -T' -E -T main.txt second.txt
run_test 'combined -Tb' -Tb main.txt second.txt
run_test 'separate -T -b' -T -b main.txt second.txt
run_test 'combined -Te' -Te main.txt second.txt
run_test 'separate -T -e' -T -e main.txt second.txt
run_test 'combined -Tn' -Tn main.txt second.txt
run_test 'separate -T -n' -T -n main.txt second.txt
run_test 'combined -Ts' -Ts main.txt second.txt
run_test 'separate -T -s' -T -s main.txt second.txt
run_test 'combined -Tt' -Tt main.txt second.txt
run_test 'separate -T -t' -T -t main.txt second.txt
run_test 'combined -Tv' -Tv main.txt second.txt
run_test 'separate -T -v' -T -v main.txt second.txt
run_test 'combined -TE' -TE main.txt second.txt
run_test 'separate -T -E' -T -E main.txt second.txt
run_test 'combined -TT' -TT main.txt second.txt
run_test 'separate -T -T' -T -T main.txt second.txt
# README explicitly requires ^M$ for CRLF with -E; old GNU cat differs.
printf 'a^M$\nb^M$\n^M$\n' > crlf_expected.txt
run_expected 'README -E CRLF' 0 crlf_expected.txt -E crlf.txt
run_expected 'README -e CRLF' 0 crlf_expected.txt -e crlf.txt
printf 'a\r' > cr_tail.txt
printf '\nb\r\n\r\n' > lf_head.txt
run_expected 'README -E CRLF across files' 0 crlf_expected.txt -E cr_tail.txt empty.txt lf_head.txt
printf 'a\r' > lone_cr_expected.txt
run_expected 'README -E lone final CR' 0 lone_cr_expected.txt -E cr_tail.txt
printf 'a\rnext$\n' > lone_cr_middle_expected.txt
printf 'next\n' > next.txt
run_expected 'README -E CR before ordinary character' 0 lone_cr_middle_expected.txt -E cr_tail.txt next.txt
printf '     1\ta^M$\n     2\tb^M$\n     3\t^M$\n' > numbered_crlf_expected.txt
run_expected 'README -bE split CRLF numbering' 0 numbered_crlf_expected.txt -bE cr_tail.txt lf_head.txt
run_expected 'README -nE split CRLF numbering' 0 numbered_crlf_expected.txt -nE cr_tail.txt lf_head.txt
finish_tests
