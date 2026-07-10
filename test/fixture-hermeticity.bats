#!/usr/bin/env bats
# @category fast
# Fixture-hermeticity lint: no bats suite may be able to reach a real
# network-capable binary (claude, curl, wget, gh) during a test run.
#
# THE RULE
#   If a suite's code — the .bats file itself plus any repo script it
#   sources or executes (scripts/ and hooks/, resolved transitively) —
#   contains a call site of claude, curl, wget, or gh, the suite must do
#   one of:
#
#   (a) Stub the binary in setup(): create an executable named after the
#       binary in a test-local directory and prepend that directory to
#       PATH (the pattern from round-log-functions.bats):
#
#         mkdir -p "$BATS_TEST_TMPDIR/stub-bin"
#         printf '#!/usr/bin/env bash\nexit 0\n' > "$BATS_TEST_TMPDIR/stub-bin/claude"
#         chmod +x "$BATS_TEST_TMPDIR/stub-bin/claude"
#         PATH="$BATS_TEST_TMPDIR/stub-bin:$PATH"
#
#   (b) Opt out with an annotation in the file's first 15 lines, when the
#       suite genuinely needs the real binary (a reason is required):
#
#         # @network: allowed — <why the real binary is required>
#
# WHY
#   Commit 4d39475: a smoke test reached a live `claude -p` through sourced
#   self-improvement.sh — a real LLM call plus sandbox network prompts,
#   hidden inside every `run-tests.sh --all`. The suites only skipped the
#   LLM path when their fixtures happened to carry no verdicts. Stubbing in
#   setup() makes hermeticity deliberate instead of accidental; this lint
#   (decision record 014, layer 2) enforces it as a convention.
#
# HOW DETECTION WORKS (static; no network, no $HOME, nothing machine-specific)
#   - Full-line comments are stripped before matching.
#   - A "call site" is a network binary in command position: at line start,
#     after one of ; & | ( or $(, or as the target of bats `run`. Binary
#     names inside prose, echo strings, or comments do not count.
#   - Scripts referenced by a suite (any *.sh token resolving by basename
#     into scripts/, scripts/lib/, hooks/, or hooks/lib/) are scanned too,
#     transitively — the 4d39475 incident was indirect, via a sourced
#     script. This over-approximates reachability on purpose: sourcing a
#     file that contains a call site counts as "can invoke".
#   - A stub is recognized as: a file named after the binary created in the
#     suite (redirect / touch / cp / install / ln / chmod +x) plus a PATH
#     prepend ending in :$PATH.
#   - This suite exempts itself: its self-checks below reference the
#     call-site scripts by path without ever executing them, which the
#     reachability over-approximation cannot distinguish.

NETWORK_BINS="claude curl wget gh"

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

# --- helpers -----------------------------------------------------------

# Print FILE with full-line comments blanked out.
strip_comments() {
  sed 's/^[[:space:]]*#.*$//' "$1"
}

# True if stdin (comment-stripped shell text) invokes BIN in command
# position: line start, after ; & | ( or $(, or as the target of `run`
# (optionally with run's own flags, e.g. `run -0 --separate-stderr`).
has_callsite() {
  local bin="$1"
  grep -Eq "(^|[;&|(])[[:space:]]*${bin}([[:space:]]|\$)|^[[:space:]]*run[[:space:]]+(-[^[:space:]]+[[:space:]]+)*${bin}([[:space:]]|\$)"
}

# Print the repo scripts FILE references, one absolute path per line:
# every *.sh token in the (comment-stripped) text whose basename resolves
# into scripts/, scripts/lib/, hooks/, or hooks/lib/ under REPO_ROOT.
referenced_scripts() {
  local file="$1" tok base dir
  strip_comments "$file" \
    | grep -oE '[A-Za-z0-9_./${}"-]*\.sh' \
    | while IFS= read -r tok; do
        base="${tok##*/}"
        [ -n "$base" ] || continue
        for dir in scripts scripts/lib hooks hooks/lib; do
          [ -f "$REPO_ROOT/$dir/$base" ] && printf '%s\n' "$REPO_ROOT/$dir/$base"
        done
      done | sort -u
}

# Print FILE plus the transitive closure of repo scripts it references.
closure() {
  local start="$1"
  local -A seen=()
  local queue=("$start") f ref
  while [ "${#queue[@]}" -gt 0 ]; do
    f="${queue[0]}"
    queue=("${queue[@]:1}")
    [ -n "${seen[$f]:-}" ] && continue
    seen["$f"]=1
    printf '%s\n' "$f"
    while IFS= read -r ref; do
      if [ -n "$ref" ] && [ -z "${seen[$ref]:-}" ]; then
        queue+=("$ref")
      fi
    done < <(referenced_scripts "$f")
  done
  return 0
}

# True if SUITE (comment-stripped) creates a stub executable named BIN and
# prepends a directory to PATH.
has_stub() {
  local suite="$1" bin="$2"
  strip_comments "$suite" \
    | grep -Eq "(>|touch |cp |install |ln (-[a-z]+ )?|chmod \+x )[^#]*/${bin}[\"']?([[:space:]]|\$)" \
    && strip_comments "$suite" | grep -Eq 'PATH=[^[:space:]]*:\$PATH'
}

# True if SUITE carries a "# @network: allowed" annotation with a reason
# (some text after "allowed") within its first 15 lines.
has_optout() {
  head -n 15 "$1" | grep -Eq '^#[[:space:]]*@network:[[:space:]]*allowed[^[:alnum:]]+[[:alnum:]]'
}

# Lint one suite: print a violation line per reachable-but-unstubbed
# binary; print nothing if the suite is clean or opted out.
lint_suite() {
  local suite="$1" bin f hit files
  if has_optout "$suite"; then
    return 0
  fi
  files="$(closure "$suite")"
  for bin in $NETWORK_BINS; do
    hit=""
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      if strip_comments "$f" | has_callsite "$bin"; then
        hit="$f"
        break
      fi
    done <<< "$files"
    if [ -n "$hit" ] && ! has_stub "$suite" "$bin"; then
      printf '%s: can invoke %s (call site in %s) without a setup() stub or "# @network: allowed" annotation\n' \
        "${suite#"$REPO_ROOT"/}" "$bin" "${hit#"$REPO_ROOT"/}"
    fi
  done
  return 0
}

# --- the lint ----------------------------------------------------------

@test "every suite that can reach a network-capable binary stubs it or opts out" {
  local violations suite
  violations="$(
    while IFS= read -r suite; do
      # Self-exemption: see the header note — the self-checks in this file
      # reference call-site scripts by path without executing them.
      if [ "$(basename "$suite")" = "fixture-hermeticity.bats" ]; then
        continue
      fi
      lint_suite "$suite"
    done < <(find "$REPO_ROOT/test" -name '*.bats' | sort)
  )"
  if [ -n "$violations" ]; then
    echo "fixture-hermeticity violations:"
    echo "$violations"
    echo ""
    echo "Fix: stub the binary in setup() (see the header of this file for"
    echo "the pattern), or add '# @network: allowed — <reason>' near the top."
    return 1
  fi
}

# --- heuristic self-checks against the real tree ------------------------
# These anchor the detector to known ground truth so a regression in the
# heuristics fails loudly instead of making the lint vacuously green.

@test "detector sees the claude call sites behind the 4d39475 incident" {
  strip_comments "$REPO_ROOT/scripts/self-improvement.sh" | has_callsite claude
  strip_comments "$REPO_ROOT/scripts/lib/si-morning-summary.sh" | has_callsite claude
}

@test "detector recognizes the round-log-functions stub pattern" {
  # round-log-functions.bats carries the reference stub from commit 4d39475.
  has_stub "$REPO_ROOT/test/round-log-functions.bats" claude
  # Its closure must include the sourced script that holds the call site.
  closure "$REPO_ROOT/test/round-log-functions.bats" \
    | grep -q '/scripts/self-improvement\.sh$'
}

# --- heuristic self-checks against synthetic fixtures --------------------

@test "detector flags an unstubbed direct invocation" {
  local fx="$BATS_TEST_TMPDIR/direct.bats"
  printf '#!/usr/bin/env bats\n' > "$fx"
  printf '@test "calls out" {\n' >> "$fx"
  # The next fixture line puts the binary in `run` position.
  printf '  run claude -p "hello"\n' >> "$fx"
  printf '}\n' >> "$fx"
  local result
  result="$(lint_suite "$fx")"
  [ -n "$result" ]
  [[ "$result" == *"can invoke claude"* ]]
}

@test "detector ignores binary names in comments and echo strings" {
  local fx="$BATS_TEST_TMPDIR/prose.bats"
  printf '#!/usr/bin/env bats\n' > "$fx"
  printf '# curl and wget and gh and claude discussed in a comment\n' >> "$fx"
  printf '@test "prose only" {\n' >> "$fx"
  printf '  echo "ask claude to curl the wget gh page"\n' >> "$fx"
  printf '  WORKFLOW_DIR="$HOME/.claude/workflows"\n' >> "$fx"
  printf '  [ -n "$WORKFLOW_DIR" ]\n' >> "$fx"
  printf '}\n' >> "$fx"
  local result
  result="$(lint_suite "$fx")"
  [ -z "$result" ]
}

@test "detector accepts a stub for a direct invocation" {
  local fx="$BATS_TEST_TMPDIR/stubbed.bats"
  printf '#!/usr/bin/env bats\n' > "$fx"
  printf 'setup() {\n' >> "$fx"
  printf '  mkdir -p "$BATS_TEST_TMPDIR/stub-bin"\n' >> "$fx"
  printf '  printf "#!/usr/bin/env bash\\nexit 0\\n" > "$BATS_TEST_TMPDIR/stub-bin/gh"\n' >> "$fx"
  printf '  chmod +x "$BATS_TEST_TMPDIR/stub-bin/gh"\n' >> "$fx"
  printf '  PATH="$BATS_TEST_TMPDIR/stub-bin:$PATH"\n' >> "$fx"
  printf '}\n' >> "$fx"
  printf '@test "gh is stubbed" {\n' >> "$fx"
  printf '  run gh pr list\n' >> "$fx"
  printf '}\n' >> "$fx"
  local result
  result="$(lint_suite "$fx")"
  [ -z "$result" ]
}

@test "detector accepts an @network: allowed annotation with a reason" {
  local fx="$BATS_TEST_TMPDIR/optout.bats"
  printf '#!/usr/bin/env bats\n' > "$fx"
  printf '# @network: allowed — exercises the real gh CLI against a local fixture remote\n' >> "$fx"
  printf '@test "real gh" {\n' >> "$fx"
  printf '  run gh --version\n' >> "$fx"
  printf '}\n' >> "$fx"
  local result
  result="$(lint_suite "$fx")"
  [ -z "$result" ]
}

@test "detector rejects an @network annotation without a reason" {
  local fx="$BATS_TEST_TMPDIR/bare-optout.bats"
  printf '#!/usr/bin/env bats\n' > "$fx"
  printf '# @network: allowed\n' >> "$fx"
  printf '@test "real gh" {\n' >> "$fx"
  printf '  run gh --version\n' >> "$fx"
  printf '}\n' >> "$fx"
  local result
  result="$(lint_suite "$fx")"
  [ -n "$result" ]
}

@test "detector follows call sites through referenced repo scripts" {
  # Build a fake repo: a suite that sources a script which sources a lib
  # containing the call site (two hops).
  local fake="$BATS_TEST_TMPDIR/fakerepo"
  mkdir -p "$fake/scripts/lib" "$fake/hooks" "$fake/test"
  printf 'source "$(dirname "$0")/lib/inner.sh"\n' > "$fake/scripts/outer.sh"
  printf 'fetch() {\n  curl https://example.com\n}\n' > "$fake/scripts/lib/inner.sh"
  local fx="$fake/test/indirect.bats"
  printf '#!/usr/bin/env bats\n' > "$fx"
  printf 'setup() {\n  source "$BATS_TEST_DIRNAME/../scripts/outer.sh"\n}\n' >> "$fx"
  printf '@test "indirect" {\n  fetch\n}\n' >> "$fx"
  local result
  result="$(REPO_ROOT="$fake" lint_suite "$fx")"
  [ -n "$result" ]
  [[ "$result" == *"can invoke curl"* ]]
  [[ "$result" == *"inner.sh"* ]]
}
