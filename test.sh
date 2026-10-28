#!/usr/bin/env bash
# Black-box tests for ./pub against a temp PUB_ROOT.
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
export PUB_ROOT="$TMP/root" PUB_URL="https://t.example/"
PUB="$HERE/pub"
fails=0 n=0

# run <cmd...>: sets OUT, ERR, RC
run() {
  RC=0
  OUT=$("$PUB" "$@" 2>"$TMP/err") || RC=$?
  ERR=$(cat "$TMP/err")
}
check() { # check <name> <cond-result 0|1>
  n=$((n + 1))
  if [ "$2" -ne 0 ]; then fails=$((fails + 1)); echo "FAIL: $1 (rc=$RC out=[$OUT] err=[$ERR])"; fi
}
ok() { run "$@"; [ "$RC" -eq 0 ]; check "ok: $*" $?; }
bad() { run "$@"; [ "$RC" -ne 0 ] && [ -n "$ERR" ] && [ -z "$OUT" ]; check "error: $*" $?; }
eq() { [ "$OUT" = "$2" ]; check "$1" $?; }
file_is() { [ -f "$1" ] && [ "$(cat "$1")" = "$2" ]; check "file $1" $?; }
absent() { [ ! -e "$1" ]; check "absent $1" $?; }
reset() { rm -rf "$PUB_ROOT"; }

# slugify (observed via url)
for pair in "Hello World|hello-world" "  --Foo__Bar!!  |foo-bar" "A///B...C|a-b-c" "ABC123|abc123" "x|x"; do
  ok url "${pair%%|*}"; eq "slug '${pair%%|*}'" "https://t.example/${pair##*|}/"
done

# url does not touch disk
reset
ok url demo; eq "url" "https://t.example/demo/"
absent "$PUB_ROOT"

# PUB_URL without trailing slash
PUB_URL="https://t.example" run url demo; eq "url no trailing slash" "https://t.example/demo/"

# path
reset
ok path "My Page"; eq "path prints" "$PUB_ROOT/my-page"
[ -d "$PUB_ROOT/my-page" ]; check "path creates dir" $?

# add .html / .htm
reset
echo '<h1>a</h1>' > "$TMP/a.html"; echo '<h1>b</h1>' > "$TMP/b.htm"
ok add Alpha "$TMP/a.html"; eq "add html url" "https://t.example/alpha/"
file_is "$PUB_ROOT/alpha/index.html" '<h1>a</h1>'
absent "$PUB_ROOT/alpha/a.html"
ok add beta "$TMP/b.htm"; eq "add htm url" "https://t.example/beta/"
file_is "$PUB_ROOT/beta/index.html" '<h1>b</h1>'

# add other file keeps name, merges into existing page
echo css > "$TMP/style.css"
ok add alpha "$TMP/style.css"; eq "add other url" "https://t.example/alpha/"
file_is "$PUB_ROOT/alpha/style.css" css
file_is "$PUB_ROOT/alpha/index.html" '<h1>a</h1>'

# add dir: contents merged, no wipe
mkdir -p "$TMP/site/sub"; echo i > "$TMP/site/index.html"; echo j > "$TMP/site/sub/j.js"
ok add alpha "$TMP/site"; eq "add dir url" "https://t.example/alpha/"
file_is "$PUB_ROOT/alpha/index.html" i
file_is "$PUB_ROOT/alpha/sub/j.js" j
file_is "$PUB_ROOT/alpha/style.css" css
absent "$PUB_ROOT/alpha/site"

# ls: newest first, "slug  URL", names with spaces tolerated, files ignored
reset
mkdir -p "$PUB_ROOT/old" "$PUB_ROOT/mid page" "$PUB_ROOT/new"
touch "$PUB_ROOT/not-a-dir"
touch -t 202001010000 "$PUB_ROOT/old"
touch -t 202101010000 "$PUB_ROOT/mid page"
touch -t 202201010000 "$PUB_ROOT/new"
ok ls
eq "ls order+format" "new  https://t.example/new/
mid page  https://t.example/mid page/
old  https://t.example/old/"
reset; mkdir -p "$PUB_ROOT"
ok ls; eq "ls empty" ""

# rm
reset
mkdir -p "$PUB_ROOT/gone" "$PUB_ROOT/keep"
ok rm Gone; eq "rm silent" ""
absent "$PUB_ROOT/gone"
[ -d "$PUB_ROOT/keep" ]; check "rm leaves others" $?

# help / usage
ok help; case "$OUT" in *Usage*) check "help usage" 0 ;; *) check "help usage" 1 ;; esac
ok; case "$OUT" in *Usage*) check "no-arg usage" 0 ;; *) check "no-arg usage" 1 ;; esac

# publish-html skill: frontmatter valid; every `pub <cmd>` it names is in `pub help`
SKILL="$HERE/skills/publish-html/SKILL.md"
[ "$(sed -n 1p "$SKILL" 2>/dev/null)" = "---" ] && grep -qx 'name: publish-html' "$SKILL" && grep -qE '^description: *[^ ]' "$SKILL"
check "skill frontmatter" $?
ok help; HELP=$OUT
cmds=$(grep -oE '\bpub [a-z]+' "$SKILL" 2>/dev/null | cut -d' ' -f2 | sort -u)
[ -n "$cmds" ]; check "skill names pub commands" $?
for c in $cmds; do
  printf '%s\n' "$HELP" | grep -qE "^  $c( |$)"; check "skill command 'pub $c' in help" $?
done

# errors
reset
bad bogus
case "$ERR" in *Usage*|*usage*) check "unknown cmd usage on stderr" 0 ;; *) check "unknown cmd usage on stderr" 1 ;; esac
bad path
bad url
bad add
bad add only-slug
bad add demo "$TMP/does-not-exist"
absent "$PUB_ROOT/demo"
bad rm
bad rm unknown-slug
for empty in "" "!!!" "---" " "; do
  bad path "$empty"; bad url "$empty"; bad add "$empty" "$TMP/a.html"; bad rm "$empty"
done
absent "$PUB_ROOT"

echo "$((n - fails))/$n passed"
[ "$fails" -eq 0 ]
