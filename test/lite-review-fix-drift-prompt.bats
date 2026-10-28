#!/usr/bin/env bats
# @category fast
# The fix-drift lite check (decision 031, L=fix-drift) also fact-checks prose a
# fix adds or changes, and flags specific claims about material the diff does
# not show as "unverified claim" findings (031's 2026-10-25 amendment, after T4
# fired on D1: a guide sentence about Dockerfile layer order the diff did not
# show). The workflow text in review-fix-loop.md describes that scope, but only
# PROMPT_FIX_DRIFT makes it run, so these tests pin what the script actually
# sends: lite-review.py runs end to end against a temp repo, with a strict
# PATH-stub `claude` that records its stdin. No network, no live claude.

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export STUB_PROMPT="$BATS_TEST_TMPDIR/prompt.txt"
  mkdir -p "$BATS_TEST_TMPDIR/stub-bin"
  # Strict: accepts only the argv lite-review.py's run_claude() builds, so a
  # changed or extra flag (--bare above all, which drops subscription auth)
  # fails here instead of passing silently.
  cat > "$BATS_TEST_TMPDIR/stub-bin/claude" <<'STUB'
#!/usr/bin/env bash
args=("$@")
[ "${#args[@]}" -eq 10 ] || { echo "stub claude: unexpected argc ${#args[@]}: $*" >&2; exit 64; }
expect=(-p --model claude-haiku-4-5-20251001 --output-format json)
for i in 0 1 2 3 4; do
  [ "${args[$i]}" = "${expect[$i]}" ] || { echo "stub claude: argv[$i]=${args[$i]}" >&2; exit 64; }
done
[ "${args[5]}" = "--system-prompt" ] && [ -n "${args[6]}" ] || { echo "stub claude: no system prompt" >&2; exit 64; }
[ "${args[7]}" = "--tools" ] && [ "${args[8]}" = "" ] || { echo "stub claude: tools not empty" >&2; exit 64; }
[ "${args[9]:-}" = "--no-session-persistence" ] || { echo "stub claude: argv[9]=${args[9]:-}" >&2; exit 64; }
cat > "$STUB_PROMPT"
printf '%s\n' '{"type":"result","subtype":"success","is_error":false,"num_turns":1,"result":"FINDINGS: NONE","usage":{"input_tokens":1,"output_tokens":1}}'
STUB
  chmod +x "$BATS_TEST_TMPDIR/stub-bin/claude"
  PATH="$BATS_TEST_TMPDIR/stub-bin:$PATH"

  # A two-commit repo whose fix commit adds a guide sentence about a file the
  # diff does not show (the D1 shape).
  export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
  REPO="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$REPO"
  git -C "$REPO" init -q
  printf 'base\n' > "$REPO/guide.md"
  git -C "$REPO" add guide.md
  git -C "$REPO" -c user.name=t -c user.email=t@example.invalid commit -q -m base
  printf 'Reuse holds until a toolchain version above the install layer changes.\n' >> "$REPO/guide.md"
  git -C "$REPO" -c user.name=t -c user.email=t@example.invalid commit -q -am fix
}

@test "fix-drift mode sends the prose fact-check and unverified-claim clauses" {
  run python3 "$REPO_ROOT/scripts/lite-review.py" --repo "$REPO" --range HEAD~1..HEAD --mode fix-drift
  [ "$status" -eq 0 ]
  [[ "$output" == *"FINDINGS: NONE"* ]]
  prompt="$(cat "$STUB_PROMPT")"
  [[ "$prompt" == *"=== FIX COMMIT DIFF (HEAD~1..HEAD) ==="* ]]
  [[ "$prompt" == *"factual errors in any prose this diff adds or changes"* ]]
  [[ "$prompt" == *'domain "unverified claim"'* ]]
  [[ "$prompt" == *"say in the description what to check and where"* ]]
  # The diff itself reaches the model.
  [[ "$prompt" == *"a toolchain version above the install layer"* ]]
}

@test "full mode does not carry the fix-drift clauses" {
  run python3 "$REPO_ROOT/scripts/lite-review.py" --repo "$REPO" --range HEAD~1..HEAD --mode full
  [ "$status" -eq 0 ]
  prompt="$(cat "$STUB_PROMPT")"
  [[ "$prompt" == *"=== DIFF (HEAD~1..HEAD) ==="* ]]
  [[ "$prompt" != *"unverified claim"* ]]
}

@test "the stub refuses --bare, so a drifted call cannot pass these tests" {
  # Ten argv, so the argc check passes and the --bare in place of
  # --no-session-persistence is what gets refused.
  run claude -p --model claude-haiku-4-5-20251001 --output-format json --system-prompt x --tools "" --bare
  [ "$status" -eq 64 ]
  [[ "$output" == *"stub claude: argv[9]=--bare"* ]]
}
