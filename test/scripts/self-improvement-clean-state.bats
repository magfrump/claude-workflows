#!/usr/bin/env bats
# @category slow
# End-to-end clean-state tests for scripts/self-improvement.sh.
#
# Runs the REAL main loop against a throwaway repo, with `claude` replaced by a
# stub that dispatches on prompt text (writes the ideas/tasks files, makes an
# implementer commit, prints the code-review sentinel, fails the conflict
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
    if [ -n "${STUB_IMPL_SLEEP:-}" ]; then
      echo $$ >> "$STUB_DIR/impl.pids"
      exec sleep "$STUB_IMPL_SLEEP"
    fi
    echo "content from ${PWD##*/}" > shared.txt
    git add shared.txt && git commit -qm "feat: change from ${PWD##*/}"
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
