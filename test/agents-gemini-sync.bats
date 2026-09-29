#!/usr/bin/env bats
# @category fast
# Validates that AGENTS.md and GEMINI.md stay in sync.
# Strips the first 3 lines (tool-specific headers) from each file, then diffs.
# Any difference means an edit was made to one file but not the other.
#
# Usage: bats test/agents-gemini-sync.bats

setup() {
  REPO_ROOT="$BATS_TEST_DIRNAME/.."
  AGENTS="$REPO_ROOT/AGENTS.md"
  GEMINI="$REPO_ROOT/GEMINI.md"
}

@test "AGENTS.md and GEMINI.md content is in sync (ignoring headers)" {
  [ -f "$AGENTS" ] || { echo "AGENTS.md not found"; return 1; }
  [ -f "$GEMINI" ] || { echo "GEMINI.md not found"; return 1; }

  local agents_body gemini_body
  agents_body=$(tail -n +4 "$AGENTS")
  gemini_body=$(tail -n +4 "$GEMINI")

  if ! diff_output=$(diff <(echo "$agents_body") <(echo "$gemini_body")); then
    echo "AGENTS.md and GEMINI.md have drifted (after stripping headers):"
    echo "$diff_output"
    return 1
  fi
}

# Claude Code loads AGENTS.md as this repo's project instructions (the root
# CLAUDE.md moved to global-instructions/, decision log row 47) and expands
# `@path` imports inline. The old `@./workflows/*.md` list pulled ~89K tokens
# of workflow text into every session and subagent here, invisible to the
# usage hook. global-instructions/CLAUDE.md loads in every project, so it is
# held to the same rule.
#
# The finder mirrors Claude Code's own import extractor (read from the
# v2.1.284 binary during review; the docs were unreachable offline): an `@` at
# the start of a text token or after whitespace, followed by `./`, `~/`, `/` or
# a character in [A-Za-z0-9._-]. So `@README`, `@x.md`, `@dir/x` and even
# `@alice` are imports, while `(@./x)`, `foo@bar` and email addresses are not.
# Emphasis markers (`**@./x**`) do not start a new token in the markdown text,
# so `*` and `_` count as token starts here. Fenced code blocks and inline
# code spans (single or double backtick) are blanked first, keeping line
# numbers: Claude Code skips both.
find_imports() {
  # shellcheck disable=SC2016  # the backticks are literal regex characters
  awk '/^[[:space:]]*```/ { fence = !fence; print ""; next } fence { print ""; next } { print }' "$1" \
    | sed -E 's/``([^`]|`[^`])*``//g; s/`[^`]*`//g' \
    | grep -nE '(^|[[:space:]*_])@(\./|~/|/|[[:alnum:]._-])'
}

@test "the import finder matches Claude Code's import grammar" {
  local pos="$BATS_TEST_TMPDIR/pos.md" neg="$BATS_TEST_TMPDIR/neg.md"
  cat > "$pos" <<'EOF'
- **@./workflows/pr-prep.md** — the old AGENTS.md form
@README
@README.md
@package.json
@workflows/x.md
load @~/.aws/credentials here
see @../y.md
@/abs/z.md
@.claude/x.md
@x.MD
ping @alice about it
EOF
  cat > "$neg" <<'EOF'
mail someone@example.com today
use `@./x.md` in a code span, or ``@./y.md`` in a double one
the @ sign alone, and foo@bar/baz
(@./x.md) "@../y.md" [@/abs/z.md]
```
@./inside/a/fence.md
```
EOF
  run find_imports "$pos"
  [ "$(printf '%s\n' "$output" | grep -c .)" -eq 11 ] || { echo "missed imports; matched:"; echo "$output"; return 1; }
  run find_imports "$neg"
  [ -z "$output" ] || { echo "false positives:"; echo "$output"; return 1; }
}

@test "AGENTS.md and the global instructions have no @-imports" {
  local f matches failed=0
  for f in "$AGENTS" "$REPO_ROOT/global-instructions/CLAUDE.md"; do
    [ -r "$f" ] || { echo "$f is missing or unreadable"; failed=1; continue; }
    if matches=$(find_imports "$f"); then
      echo "$f contains @-imports, which Claude Code expands into every session:"
      echo "$matches"
      failed=1
    fi
  done
  [ "$failed" -eq 0 ]
}
