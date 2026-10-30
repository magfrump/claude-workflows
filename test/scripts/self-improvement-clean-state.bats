#!/usr/bin/env bats
# @category slow
# End-to-end clean-state tests for scripts/self-improvement.sh.
#
# Runs the REAL main loop against a throwaway repo, with `claude` replaced by a
# stub that dispatches on prompt text (writes the ideas/tasks files, makes an
# implementer change and message file for the loop to commit, prints the code-review sentinel, fails the conflict
# resolver on demand). Each test pins one defect from the 2026-09-18 clean-
# state audit where the fix lives inside the main-execution guard and so
# cannot be reached by sourcing:
#   A1  failing conflict resolver aborted the run mid-merge; trap then deleted
#       the approved-but-unmerged branch
#   A2  SIGTERM left implementer processes running after worktree removal
#   A3  an earlier run's kept branch was deleted by this run's trap
#   A4  stale gitignored ideas/tasks files passed the "did claude write it" check
#   A5  round-history.json from earlier runs broke the prior-round verdicts
#   A9  conflict_unresolved tasks were logged as completed / hypothesised
#   A11 convergence exit skipped the round report
#   Q146 the loop commits each implementer's work (the children cannot)
# A3 also pins the main loop's print_round_summary call (stdout + log line).
# Unit-level tests for the helpers are in test/si-clean-state.bats.
#
# Usage: bats test/scripts/self-improvement-clean-state.bats

SI="$BATS_TEST_DIRNAME/../../scripts/self-improvement.sh"

setup() {
  # Stub claude (hermeticity convention: test/fixture-hermeticity.bats).
  BIN="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$BIN"
  cat > "$BIN/claude" <<'STUB'
#!/usr/bin/env bash
prompt="${!#}"
round() { printf '%s' "$prompt" | grep -oE 'feature-ideas-round-[0-9]+' | head -1 | grep -oE '[0-9]+$'; }
case "$prompt" in
  *"Follow the divergent-design workflow"*)
    r=$(round)
    printf '%s' "$prompt" > "$STUB_DIR/ideas-prompt.r$r"
    [ "$r" = 1 ] && printf '# ideas\n1. one\n2. two\n' > "docs/working/feature-ideas-round-$r.md"
    ;;
  *"Find the Diagnose section"*) echo "${STUB_PROBLEMS:-[]}" ;;
  *"comparing two sets of problem"*) echo "${STUB_OVERLAP:-0}" ;;
  *"For each surviving idea"*) cp "$STUB_DIR/tasks.json" "docs/working/tasks-round-$(round).json" ;;
  *"You are in /away mode"*)
    # As strict as the real CLI the loop builds for the implementer: only
    # -p, the prompt and claude_headless_flags() output; no tool grants
    # (--allowedTools, --settings) and so no way to commit (Q-146 [1]).
    [ "$1" = "-p" ] || { echo "stub: implementer argv must start with -p" >&2; exit 2; }
    shift
    while [ $# -gt 1 ]; do
      case "$1" in
        --permission-mode) [ "$2" = acceptEdits ] || exit 2; shift 2 ;;
        --add-dir) [ -d "$2" ] || exit 2; shift 2 ;;
        *) echo "stub: unexpected implementer flag $1" >&2; exit 2 ;;
      esac
    done
    if [ -n "${STUB_IMPL_SLEEP:-}" ]; then
      echo $$ >> "$STUB_DIR/impl.pids"
      exec sleep "$STUB_IMPL_SLEEP"
    fi
    [ -z "${STUB_IMPL_NOCHANGE:-}" ] || exit 0
    # Test-only: detach HEAD so the loop's commit lands off the task branch.
    [ -z "${STUB_IMPL_DETACH:-}" ] || git checkout -q --detach
    echo "content from ${PWD##*/}" > shared.txt
    [ -n "${STUB_IMPL_NOMSG:-}" ] || printf 'feat: change from %s\n\nConfidence: high\nNotes: stub\n' "${PWD##*/}" > .si-commit-msg
    ;;
  *"Run the code-review skill"*)
    printf '%s: 0\n' "$(printf '%s' "$prompt" | grep -oE 'CODE_REVIEW_RED\[[0-9a-f]+\]' | head -1)" ;;
  *"There are merge conflicts"*) exit "${STUB_RESOLVER_RC:-1}" ;;
  *"diagnosed problems and a list of merged"*) echo "[]" ;;
esac
exit 0
STUB
  chmod +x "$BIN/claude"
  PATH="$BIN:$PATH"
  export STUB_DIR="$BATS_TEST_TMPDIR"

  # Two tasks that both rewrite shared.txt: the second merge always conflicts.
  cat > "$STUB_DIR/tasks.json" <<'JSON'
[{"id":"a","description":"task a","files_touched":["shared.txt"],"independent":true,"category":"maintenance","evaluator":"user","hypothesis_source":"planner","hypothesis":"ha","hypothesis_window":1},
 {"id":"b","description":"task b","files_touched":["shared.txt"],"independent":true,"category":"maintenance","evaluator":"user","hypothesis_source":"planner","hypothesis":"hb","hypothesis_window":1}]
JSON

  export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
  export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
  REPO="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$REPO"
  git -C "$REPO" init -q -b main
  # No test/ dir in the fixture, so the run skips its bats baseline.
  printf '.claude/\ndocs/working/\n' > "$REPO/.gitignore"
  echo base > "$REPO/shared.txt"
  git -C "$REPO" add . && git -C "$REPO" commit -qm init
  mkdir -p "$REPO/docs/working"
  WD="$REPO/docs/working"
  export REPO_DIR="$REPO" TMPDIR="$BATS_TEST_TMPDIR"
}

run_si() {
  run bash "$SI"
}

@test "A1/A9: a failing conflict resolver leaves main clean and keeps the unmerged branch" {
  export STUB_RESOLVER_RC=1
  run_si
  [ "$status" -eq 0 ]
  run git -C "$REPO" rev-parse -q --verify MERGE_HEAD
  [ "$status" -ne 0 ]
  [ -z "$(git -C "$REPO" status --porcelain --untracked-files=no)" ]
  git -C "$REPO" show-ref --verify --quiet refs/heads/feat/r1-b
  [ "$(jq -r '.merges.b' "$WD/round-1-report.json")" = "conflict_unresolved" ]
  # A9: only the merged task is logged as completed / hypothesised.
  grep -q -- '- \*\*a\*\*' "$WD/completed-tasks.md"
  run grep -- '- \*\*b\*\*' "$WD/completed-tasks.md"
  [ "$status" -ne 0 ]
  run grep -E '^\| 1 \| b \|' "$WD/hypothesis-log.md"
  [ "$status" -ne 0 ]
}

@test "a run refused on a dirty tree leaves the user's in-progress merge alone" {
  # The EXIT trap is armed before the clean-main preflight, so it fires on a
  # refusal too; it must only abort a merge this run started.
  git -C "$REPO" switch -qc other
  echo theirs > "$REPO/shared.txt" && git -C "$REPO" commit -qam theirs
  git -C "$REPO" switch -q main
  echo ours > "$REPO/shared.txt" && git -C "$REPO" commit -qam ours
  run git -C "$REPO" merge other --no-edit
  [ "$status" -ne 0 ]
  echo resolved-by-user > "$REPO/shared.txt" && git -C "$REPO" add shared.txt

  run_si
  [ "$status" -ne 0 ]
  git -C "$REPO" rev-parse -q --verify MERGE_HEAD
  [ "$(cat "$REPO/shared.txt")" = "resolved-by-user" ]
}

@test "A3: a branch kept by an earlier run survives and its task is skipped" {
  git -C "$REPO" branch feat/r1-a
  local sha
  sha=$(git -C "$REPO" rev-parse feat/r1-a)
  export STUB_RESOLVER_RC=0
  run_si
  [ "$status" -eq 0 ]
  [[ "$output" == *"feat/r1-a"*"already exists"* ]]
  [ "$(git -C "$REPO" rev-parse feat/r1-a)" = "$sha" ]
  # Main-loop wiring of print_round_summary (the smoke suite calls it by hand,
  # so only a real run can see the call go missing): the skipped task a is not
  # counted as launched, and the line lands on stdout AND in the round's log.
  echo "$output" | grep -qx 'Round 1: 1 launched, 1 approved, 0 rejected'
  [ "$(tail -n 1 "$WD/validation-round-1.log")" = "Round 1: 1 launched, 1 approved, 0 rejected" ]
}

@test "A4: stale ideas/tasks files from an earlier run do not start another round" {
  printf '# stale\n1. x\n' > "$WD/feature-ideas-round-2.md"
  cp "$STUB_DIR/tasks.json" "$WD/tasks-round-2.json"
  export STUB_RESOLVER_RC=0
  run_si
  [ "$status" -eq 0 ]
  [[ "$output" == *"Stopping after 1 rounds"* ]]
  [ "$(jq -r '.outcome' "$WD/round-2-report.json")" = "exhausted" ]
}

@test "A5: earlier runs' round-history entries do not hide this run's verdicts" {
  # An earlier run's round 1 with a different verdict for the same task id.
  echo '[{"round":1,"validation":{"a":{"verdict":"rejected","tests":"fail"}},"outcome":"completed"}]' \
    > "$WD/round-history.json"
  export STUB_RESOLVER_RC=0
  run_si
  [ "$status" -eq 0 ]
  grep -q 'APPROVED (already implemented' "$STUB_DIR/ideas-prompt.r2"
  grep -q -- '  - a: task a' "$STUB_DIR/ideas-prompt.r2"
}

@test "A11: a converged round still writes its report and history entry" {
  echo '{"1":["p"]}' > "$WD/problem-history.json"
  export STUB_PROBLEMS='["p"]' STUB_OVERLAP=100
  run_si
  [ "$status" -eq 0 ]
  [[ "$output" == *"Convergence detected"* ]]
  [ "$(jq -r '.outcome' "$WD/round-1-report.json")" = "converged" ]
  [ "$(jq -r '.[-1].outcome' "$WD/round-history.json")" = "converged" ]
}

@test "A2: SIGTERM stops running implementers before their worktrees are removed" {
  export STUB_IMPL_SLEEP=60
  bash "$SI" > "$BATS_TEST_TMPDIR/out.txt" 2>&1 &
  local si_pid=$!
  for _ in $(seq 1 100); do
    [ -f "$STUB_DIR/impl.pids" ] && [ "$(wc -l < "$STUB_DIR/impl.pids")" -ge 2 ] && break
    sleep 0.1
  done
  [ "$(wc -l < "$STUB_DIR/impl.pids")" -ge 2 ]

  kill -TERM "$si_pid"
  local rc=0
  wait "$si_pid" || rc=$?
  [ "$rc" -eq 143 ]

  local p alive=""
  for p in $(cat "$STUB_DIR/impl.pids"); do
    if kill -0 "$p" 2>/dev/null; then alive="$alive $p"; kill "$p"; fi
  done
  [ -z "$alive" ]
  [ ! -d "$REPO/.claude/wt-a" ]
  [ ! -d "$REPO/.claude/wt-b" ]
}

@test "Q146: the loop commits the implementer's work with its message file" {
  export STUB_RESOLVER_RC=1
  run_si
  [ "$status" -eq 0 ]
  # Task a merged: main carries the stub's message, and never the message file.
  git -C "$REPO" log --format=%s main | grep -qx 'feat: change from wt-a'
  git -C "$REPO" log -1 --format=%B feat/r1-b | grep -qx 'Confidence: high'
  run git -C "$REPO" log --all --name-only --format=
  [[ "$output" != *".si-commit-msg"* ]]
  [ "$(jq -r '.validation.a.commits' "$WD/round-1-report.json")" = pass ]
}

@test "Q146: with no message file the commit message is the task description" {
  export STUB_RESOLVER_RC=1 STUB_IMPL_NOMSG=1
  run_si
  [ "$status" -eq 0 ]
  git -C "$REPO" log --format=%s main | grep -qx 'task a'
  [ "$(git -C "$REPO" log -1 --format=%s feat/r1-b)" = 'task b' ]
}

@test "Q146: an implementer that changes nothing gets no commit and a named rejection" {
  export STUB_IMPL_NOCHANGE=1
  run_si
  [ "$status" -eq 0 ]
  [ "$(git -C "$REPO" rev-list --count main)" -eq 1 ]
  [ "$(jq -r '.validation.a.commits' "$WD/round-1-report.json")" = fail ]
  [ "$(jq -r '.validation.a.verdict_detail.reject_reason' "$WD/round-1-report.json")" \
    = "no commits on branch (implementer left no changes)" ]
  grep -q '\[a\] REJECTED: no commits on branch (implementer left no changes)' "$WD/validation-round-1.log"
}

@test "Q146: a failed commit rejects the task with git's reason" {
  # No committer identity: git refuses the loop's commit.
  unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
  git -C "$REPO" config user.useConfigOnly true
  run_si
  [ "$status" -eq 0 ]
  [ "$(jq -r '.validation.a.commits' "$WD/round-1-report.json")" = fail ]
  jq -r '.validation.a.verdict_detail.reject_reason' "$WD/round-1-report.json" \
    | grep -q '^implementer commit failed: git commit failed in .*wt-a'
}

@test "Q146: a commit that does not land on the task branch rejects the task" {
  export STUB_IMPL_DETACH=1
  run_si
  [ "$status" -eq 0 ]
  [ "$(jq -r '.validation.a.commits' "$WD/round-1-report.json")" = fail ]
  [ "$(jq -r '.validation.a.verdict_detail.reject_reason' "$WD/round-1-report.json")" \
    = "implementer commit failed: the commit did not land on feat/r1-a" ]
}
