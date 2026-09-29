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
# An import is `@` followed by a path: `@/abs`, `@./x`, `@../x`, `@~/x`, or a
# relative `@dir/x` / `@x.md`. The `@` must not follow a word character, so an
# email address or `foo@bar/baz` is not one. Inline code spans are removed
# first: Claude Code does not expand imports inside them.
find_imports() {
  # shellcheck disable=SC2016  # the backticks are literal regex characters
  sed -E 's/`[^`]*`//g' "$1" \
    | grep -nE '(^|[^[:alnum:]_.@/-])@(~?/|\.{1,2}/|[[:alnum:]_][[:alnum:]_.-]*(/|\.md([^[:alnum:]]|$)))'
}

@test "the import finder catches every @-import form and nothing else" {
  local pos="$BATS_TEST_TMPDIR/pos.md" neg="$BATS_TEST_TMPDIR/neg.md"
  cat > "$pos" <<'EOF'
- **@./workflows/pr-prep.md** — the old AGENTS.md form
@README.md
@workflows/x.md
load @~/.aws/credentials here
(@./x.md)
"@../y.md"
[@/abs/z.md]
EOF
  cat > "$neg" <<'EOF'
mail someone@example.com today
ping @alice about it
use `@./x.md` in a code span
the @ sign alone, and foo@bar/baz
decorators like @dataclass
EOF
  run find_imports "$pos"
  [ "$(printf '%s\n' "$output" | grep -c .)" -eq 7 ] || { echo "missed imports; matched:"; echo "$output"; return 1; }
  run find_imports "$neg"
  [ -z "$output" ] || { echo "false positives:"; echo "$output"; return 1; }
}

@test "AGENTS.md and the global instructions have no @-imports" {
  local f matches failed=0
  for f in "$AGENTS" "$REPO_ROOT/global-instructions/CLAUDE.md"; do
    if matches=$(find_imports "$f"); then
      echo "$f contains @-imports, which Claude Code expands into every session:"
      echo "$matches"
      failed=1
    fi
  done
  [ "$failed" -eq 0 ]
}
