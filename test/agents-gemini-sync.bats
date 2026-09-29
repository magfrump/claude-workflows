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
# Claude Code v2.1.284 (its extractor, read from the binary during review)
# imports an `@` that starts a markdown text token or follows whitespace, when
# the next character is `./`, `~/`, `/` or one of [A-Za-z0-9._-]; it skips code
# blocks and code spans. Imitating its markdown tokenizer in awk proved
# fragile both ways (a four-backtick fence hid the rest of a file), so this
# finder over-approximates instead: it flags any such `@` not preceded by a
# letter or digit, and removes only same-line inline code spans. It therefore
# also flags some things Claude Code would skip (`(@./x)`, `@` inside fenced or
# indented code); a false alarm costs one edit, a miss costs every session.
# Known remaining miss: an import inside an inline code span in a tight list
# item, which Claude Code still expands.
find_imports() {
  # shellcheck disable=SC2016  # the backticks are literal regex characters
  sed -E 's/``([^`]|`[^`])*``//g; s/`[^`]*`//g' "$1" \
    | grep -nE '(^|[^[:alnum:]])@(\./|~/|/|[[:alnum:]._-])'
}

@test "the import finder flags every form Claude Code imports, and not emails or code spans" {
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
[@./x.md](url) link text
>@./quoted.md
~~@./struck.md~~
<span>@./html.md</span>
````
```
````
@./after-a-four-backtick-fence.md
EOF
  cat > "$neg" <<'EOF'
mail someone@example.com today
use `@./x.md` in a code span, or ``@./y.md`` in a double one
the @ sign alone, and foo@bar/baz
EOF
  run find_imports "$pos"
  [ "$(printf '%s\n' "$output" | grep -c '@')" -eq 16 ] || { echo "missed imports; matched:"; echo "$output"; return 1; }
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
