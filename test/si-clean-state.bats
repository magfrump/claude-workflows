#!/usr/bin/env bats
# @category fast
# Unit tests for the self-improvement.sh helpers that keep a crashed or
# interrupted run from leaving the repo dirty or destroying kept work:
#   cleanup (EXIT trap), untrack_branch, create_task_worktree,
#   file_in_declared_scope
#
# Regressions covered (2026-09-18 clean-state audit):
#   A1 — a crash mid-merge left main with MERGE_HEAD, and the trap then
#        force-deleted approved-but-unmerged branches.
#   A2 — a signal removed worktrees while implementer processes kept running.
#   A3 — a leftover branch/dir from an earlier run was tracked before the
#        (failing) `worktree add`, so this run's trap deleted it.
#   A8 — the file-scope gate matched substrings, not whole paths.
#   Review — cleanup aborted a merge the user had in progress when the run
#        was merely refused (dirty tree); it now aborts only its own merge.
#
# End-to-end coverage of the same fixes (driving the real main loop with a
# stubbed claude) lives in test/scripts/self-improvement-clean-state.bats.
#
# Usage: bats test/si-clean-state.bats

setup() {
  # Source for functions only; the main-execution guard skips the loop.
  source "$BATS_TEST_DIRNAME/../scripts/self-improvement.sh"

  # Stub the claude CLI so no sourced function can reach the real one.
  # Convention enforced by test/fixture-hermeticity.bats.
  mkdir -p "$BATS_TEST_TMPDIR/stub-bin"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$BATS_TEST_TMPDIR/stub-bin/claude"
  chmod +x "$BATS_TEST_TMPDIR/stub-bin/claude"
  PATH="$BATS_TEST_TMPDIR/stub-bin:$PATH"

  # Hermetic git: no user/system config (signing, hooks, default branch).
  export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
  export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
  REPO_DIR="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$REPO_DIR"
  cd "$REPO_DIR" || return 1
  git init -q -b main
  echo base > f && git add f && git commit -qm init
  WORKTREE_BASE="$REPO_DIR/.claude/wt"
  RUN_WORKTREES=()
  RUN_BRANCHES=()
  RUN_PIDS=()
}

# --- untrack_branch ---

@test "untrack_branch drops only the branch and keeps the worktree tracked" {
  RUN_WORKTREES=("/wt/a" "/wt/b")
  RUN_BRANCHES=("feat/a" "feat/b")

  untrack_branch "feat/a"

  [ "${RUN_WORKTREES[*]}" = "/wt/a /wt/b" ]
  [ "${RUN_BRANCHES[*]}" = "feat/b" ]
}

@test "untrack_branch draining the last branch is safe under set -u" {
  set -u
  RUN_BRANCHES=("feat/only")
  untrack_branch "feat/only"
  [ "${#RUN_BRANCHES[@]}" -eq 0 ]
}

# --- cleanup: merge state (A1) ---

@test "cleanup aborts a merge this run left in progress on main" {
  git switch -qc other && echo other > f && git commit -qam other
  git switch -q main && echo mine > f && git commit -qam mine
  run git merge other --no-edit
  [ "$status" -ne 0 ]
  git rev-parse -q --verify MERGE_HEAD

  RUN_MERGING=1
  cleanup

  run git rev-parse -q --verify MERGE_HEAD
  [ "$status" -ne 0 ]
  [ -z "$(git status --porcelain --untracked-files=no)" ]
}

@test "cleanup leaves alone a merge this run did not start" {
  git switch -qc other && echo other > f && git commit -qam other
  git switch -q main && echo mine > f && git commit -qam mine
  run git merge other --no-edit
  [ "$status" -ne 0 ]
  echo resolved > f && git add f

  # shellcheck disable=SC2034  # read by the sourced cleanup()
  RUN_MERGING=""
  cleanup

  git rev-parse -q --verify MERGE_HEAD
  [ "$(cat f)" = "resolved" ]
}

@test "cleanup keeps an approved (branch-untracked) branch but removes its worktree" {
  create_task_worktree "$WORKTREE_BASE-ok" "feat/r1-ok"
  create_task_worktree "$WORKTREE_BASE-rej" "feat/r1-rej"
  # Approval-time untrack, as the verdict step does.
  untrack_branch "feat/r1-ok"

  cleanup

  [ ! -d "$WORKTREE_BASE-ok" ]
  [ ! -d "$WORKTREE_BASE-rej" ]
  git show-ref --verify --quiet refs/heads/feat/r1-ok
  run git show-ref --verify --quiet refs/heads/feat/r1-rej
  [ "$status" -ne 0 ]
}

@test "cleanup runs once: a second call is a no-op" {
  create_task_worktree "$WORKTREE_BASE-x" "feat/r1-x"
  cleanup
  [ ! -d "$WORKTREE_BASE-x" ]
  # Recreate a same-named branch; the guarded second call must not touch it.
  git branch feat/r1-x
  RUN_BRANCHES=("feat/r1-x")
  RUN_WORKTREES=("$WORKTREE_BASE-x")
  cleanup
  git show-ref --verify --quiet refs/heads/feat/r1-x
}

# --- cleanup: background implementers (A2) ---

@test "cleanup stops tracked implementer subshells and their children" {
  local pidfile="$BATS_TEST_TMPDIR/child.pid"
  # Mirrors the loop: a subshell whose child is the long-running process.
  ( sleep 60 & echo $! > "$pidfile"; wait ) &
  RUN_PIDS=("$!")
  for _ in $(seq 1 50); do [ -s "$pidfile" ] && break; sleep 0.1; done
  local child
  child=$(cat "$pidfile")
  kill -0 "$child"

  local sub=${RUN_PIDS[0]}

  cleanup

  [ "${#RUN_PIDS[@]}" -eq 0 ]
  run kill -0 "$sub"
  [ "$status" -ne 0 ]
  run kill -0 "$child"
  [ "$status" -ne 0 ]
}

# --- create_task_worktree (A3) ---

@test "create_task_worktree creates and tracks a fresh worktree" {
  run create_task_worktree "$WORKTREE_BASE-new" "feat/r1-new"
  [ "$status" -eq 0 ]
  create_task_worktree "$WORKTREE_BASE-new2" "feat/r1-new2"
  [ -d "$WORKTREE_BASE-new2" ]
  [ "${RUN_WORKTREES[*]}" = "$WORKTREE_BASE-new2" ]
  [ "${RUN_BRANCHES[*]}" = "feat/r1-new2" ]
}

@test "create_task_worktree refuses an existing branch without tracking it" {
  git branch feat/r1-kept
  local sha
  sha=$(git rev-parse feat/r1-kept)

  run create_task_worktree "$WORKTREE_BASE-kept" "feat/r1-kept"
  [ "$status" -eq 1 ]
  [[ "$output" == *"already exists"* ]]
  create_task_worktree "$WORKTREE_BASE-kept" "feat/r1-kept" || true
  [ "${#RUN_BRANCHES[@]}" -eq 0 ]
  [ "${#RUN_WORKTREES[@]}" -eq 0 ]

  cleanup
  [ "$(git rev-parse feat/r1-kept)" = "$sha" ]
}

@test "create_task_worktree refuses an existing worktree dir without tracking it" {
  mkdir -p "$WORKTREE_BASE-dir"
  echo keep > "$WORKTREE_BASE-dir/file"

  create_task_worktree "$WORKTREE_BASE-dir" "feat/r1-dir" 2>/dev/null || true
  [ "${#RUN_WORKTREES[@]}" -eq 0 ]
  cleanup
  [ -f "$WORKTREE_BASE-dir/file" ]
}

# --- file_in_declared_scope (A8) ---

@test "file_in_declared_scope accepts an exact declared path" {
  run file_in_declared_scope "scripts/a.sh" $'README.md\nscripts/a.sh'
  [ "$status" -eq 0 ]
}

@test "file_in_declared_scope rejects a path that is only a substring of a declared one" {
  run file_in_declared_scope "a.sh" "scripts/a.sh.bak"
  [ "$status" -eq 1 ]
  run file_in_declared_scope "foo.md" "docs/foo.md"
  [ "$status" -eq 1 ]
}

@test "file_in_declared_scope treats a trailing-slash entry as a directory" {
  run file_in_declared_scope "test/skills/schemas/x.json" "test/skills/schemas/"
  [ "$status" -eq 0 ]
  run file_in_declared_scope "test/skills/schemasX/x.json" "test/skills/schemas/"
  [ "$status" -eq 1 ]
}

@test "file_in_declared_scope treats a slash-less or ./ directory entry as a directory" {
  run file_in_declared_scope "skills/foo/SKILL.md" "skills/foo"
  [ "$status" -eq 0 ]
  run file_in_declared_scope "skills/foo/SKILL.md" "./skills/foo/"
  [ "$status" -eq 0 ]
  run file_in_declared_scope "scripts/a.sh" "./scripts/a.sh"
  [ "$status" -eq 0 ]
  run file_in_declared_scope "skills/foobar/SKILL.md" "skills/foo"
  [ "$status" -eq 1 ]
}

@test "file_in_declared_scope rejects everything for an empty declared list" {
  run file_in_declared_scope "a" ""
  [ "$status" -eq 1 ]
}
