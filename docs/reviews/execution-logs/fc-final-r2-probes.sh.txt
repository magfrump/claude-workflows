#!/usr/bin/env bash
# code-fact-check final pass r2 probes; run from worktree root
set -u
find_imports() {
  sed -E 's/`[^`]*`//g' "$1" \
    | grep -nE '(^|[^[:alnum:]_.@/-])@(~?/|\.{1,2}/|[[:alnum:]_][[:alnum:]_.-]*(/|\.md([^[:alnum:]]|$)))'
}
T=$(mktemp -d)
echo "== date: $(date -u +%FT%TZ)  locale: LC_ALL=${LC_ALL:-} LANG=${LANG:-}"
echo "== synthetic positives (from bats test)"
cat > $T/pos.md <<'EOF'
- **@./workflows/pr-prep.md** — the old AGENTS.md form
@README.md
@workflows/x.md
load @~/.aws/credentials here
(@./x.md)
"@../y.md"
[@/abs/z.md]
EOF
find_imports $T/pos.md; echo "count=$(find_imports $T/pos.md | grep -c .)"
echo "== synthetic negatives"
cat > $T/neg.md <<'EOF'
mail someone@example.com today
ping @alice about it
use `@./x.md` in a code span
the @ sign alone, and foo@bar/baz
decorators like @dataclass
EOF
find_imports $T/neg.md; echo "rc=$? (1 = no match)"
echo "== per-line: which alternative matches each positive (grep -o)"
sed -E 's/`[^`]*`//g' $T/pos.md | grep -noE '(^|[^[:alnum:]_.@/-])@(~?/|\.{1,2}/|[[:alnum:]_][[:alnum:]_.-]*(/|\.md([^[:alnum:]]|$)))'
echo "== extra probes (one per line; M = matched, - = not)"
while IFS= read -r line; do
  printf '%s\n' "$line" > $T/one.md
  if find_imports $T/one.md >/dev/null; then r=M; else r=-; fi
  printf '%s  | %s\n' "$r" "$line"
done <<'EOF'
@package.json
@README
@notes.txt
@.claude/settings.md
@x.MD
@CLAUDE.md
@~/.claude/CLAUDE.md
see @alice/pkg on npm
install @types/node
ssh user@host:/path
[mail me](mailto:me@example.com)
<me@example.com>
foo@bar/baz
x-@./y.md
a/@./y.md
.@./y.md
see:@./y.md
—@./y.md
@@./y.md
``@./y.md``
`` code ` @./y.md ``
@x.md.bak
@x.mdx
@x.md,
EOF
echo "== fenced code block with import inside"
printf '```\n@./inside-fence.md\n```\n' > $T/fence.md
find_imports $T/fence.md; echo "rc=$?"
echo "== real files"
for f in AGENTS.md global-instructions/CLAUDE.md GEMINI.md; do
  echo "-- $f"; find_imports "$f"; echo "rc=$?"
done
echo "-- main:AGENTS.md"
git show main:AGENTS.md > $T/old.md; find_imports $T/old.md; echo "count=$(find_imports $T/old.md | grep -c .)"
echo "== raw @ occurrences in global-instructions/CLAUDE.md and AGENTS.md"
grep -n '@' AGENTS.md global-instructions/CLAUDE.md
rm -rf $T
