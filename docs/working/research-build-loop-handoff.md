# Research: build-loop handoff

- **Goal**: The dev cycle can hand a build brief to an autonomous build loop and later collect its result, with the state and checks in a small tested script (`scripts/build-loop.sh`) rather than in prose.
- **Problem framing**: The loop protocol needs code-owned state and gates. The prose version kept failing because each fix opened new edges between separate sessions sharing state. Considered and discarded: "the seed design is right and only needs re-wording", which is how passes 6–9 went. Each re-wording found new reds, and 9 of the 27 findings below are still uncovered by the seed.
- **Project state**: delivers the build-loop handoff (script, tests, skill/doc changes) · roadmap In flight item, split out of `feat/dev-cycle`; Q-103 waits on it · not blocked (cite: docs/working/briefs/2026-10-02-build-loop-handoff.md)
- **Task status**: paused (research done. The goal widened on 2026-10-03: the cycle becomes an orchestrator loop that dispatches build loops with no human gates; see `docs/working/handoff-build-loop-handoff.md`. The "Design forks found" section below is superseded there.)

Brief reading (restated per the terse-instruction rule): "start this" means run RPI on the brief up to the plan-approval gate. The brief says it does not stand in for plan approval. No code is written before the user approves the plan.

## What exists

- **`skills/dev-cycle/SKILL.md`** (388 lines) [observed]. The cycle writes build briefs in step 6 (`docs/working/briefs/YYYY-MM-DD-<slug>.md`, `Status: open`, the evidence line, goal, motive, acceptance criteria, branch, out-of-scope). Up to 3 briefs hold a slot. Briefs land with step 7, and the user starts each one by hand. In flight checks, in order: (1) `--check-brief` prints `done`/`dropped` → Done or Ideas, and the brief is `git mv`'d to `briefs/closed/`; (2) answers to keep-or-drop IDs on the brief's `Asked:` line are applied through `--check-answer` (`keep` sets `Kept:`, `drop`/`done` close it, and each read ID goes on `Applied:`); (3) after 14 idle days (`--check-branch` absent, 0 commits, or a tip date over 14 days old) one keep-or-drop `you: judgment` entry is filed. Lines 14–16 and 56–58 say the handoff "does not run yet". There is no `Policy:`, `Paths:` or `Branch:` machine line in briefs today; the branch is prose under `## Branch`.
- **`scripts/dev-cycle.sh`** (877 lines) [observed]. A read-only digest plus check modes. Reusable pieces:
  - `pathform` (ASCII NAMECHARS, no `.`/`..`/`.git*` component);
  - `blocker`/`inrepo` (no symlink in any component);
  - `FENCE_AWK`, which refuses a file on any Markdown shape it does not model (decision log 69) and reports why through `oddwhy`;
  - `check_brief` (Status from the **default branch's commit**, never the working tree);
  - `check_branch` (refs/heads only, never a same-named tag; prints count and tip date);
  - `ANSWER_AWK`/`check_answer` (keep/drop/done grammar);
  - default-branch resolution (origin/HEAD, main, master, by `show-ref --verify`);
  - `scrub` (re-exec through a perl filter; it removes controls and bidi characters from everything printed).

  **Corrected after the pre-mortem:** `~/.claude/scripts` → `/opt/claude-workflows/scripts`, which is the image's blessed copy, not this checkout [observed: `ls -la ~/.claude/scripts`]. `scripts/lib/` travels with that copy, but a new script reaches it only after a rebuild and bless (`/opt/.../build-loop.sh` is absent today).
- **`docs/dev-cycle.md`** [observed]: `Build-loop policy: review (interim; Q-103)`. It states the exact-line rule, so that interim line counts as unset, which means `review`.
- **`test/scripts/dev-cycle.bats`** (53 tests, 1021 lines) [observed]. Hermetic: `GIT_CONFIG_GLOBAL=/dev/null`, `HOME` in the temp dir, a throwaway repo per test under `$BATS_TEST_TMPDIR`. This is the pattern to copy.
- **`workflows/pr-prep.md`** local-merge path [observed]: `git checkout main && git merge --no-ff <branch> -F <msg>`. Under /active, ask first.
- **`workflows/codebase-onboarding.md:453`** [observed] asks the policy and calls the handoff "a planned unit". That wording changes too.
- **Q-103** (`docs/working/questions.md:143`) [observed]: `deferred`. It becomes `you: judgment` once the handoff lands, with options [1] review and [2] self-merge.

## Invariants

- Brief state is read only from the default branch's commit (`check_brief`, `git cat-file blob "$MAIN_SHA:$a"`) [observed]. The handoff must read `Policy:`/`Paths:`/`Branch:` the same way. This also satisfies the brief's "briefs are read from the landed commit".
- Branch names reach git only as `refs/heads/<name>` through `show-ref --verify` [observed, `check_branch`]. Nothing is passed as an option (no leading `-`).
- A file with any shape `FENCE_AWK` refuses is not read at all (log row 69) [observed]. A refused policy file must therefore resolve to `review`, and a refused brief must give no self-merge.
- Keep-or-drop IDs live on the brief's `Asked:`/`Applied:`/`Kept:` lines and are read only via `--check-answer` [observed, SKILL.md step 6]. The handoff must reuse this rather than add a second answer parser.
- `Status: done` set "in the change that merges this work" moves the item to Done through check 1 [observed]. The loop sets it on its branch, so a merge (either policy) closes the item with no extra state.
- Slots: at most 3 briefs hold a slot. A brief is released only by done/dropped/closed [observed].
- The cycle never commits on another session's branch, and stages named paths only [observed, Rules].
- `/workspace` is shared, and other sessions switch its branch [memory: check-branch-before-merging]. A merge into main must not `git checkout main` in a checkout the script does not own.

## Prior art

- `dev-cycle.sh` check modes are the model. Each takes many arguments and prints one `ok …`/`skip …: reason` line per argument. Exit 0 means every argument got an answer (a skip is an answer), and exit 1 means bad usage or no default branch. The handoff script follows this shape.
- `scripts/lib/si-functions.sh` `require_clean_main`/`merge_landed` (`test/merge-safety.bats`) [observed]: a refused merge leaves zero unmerged paths, so "no conflict" ≠ "merged". Verify the merge landed by its result, not by absence of errors.
- `hooks/live-verify-gate.sh` [observed] keys its enforcement set on a regex. Its comments note that a rename, mode change, add/delete or binary is handled conservatively (refuse). The same conservative stance applies here.
- No existing reader of marker commits.

## Gotchas

- **Research and plan docs are gitignored** (`.gitignore:26-27`: `docs/working/plan-*.md`, `research-*.md`) [observed]. A loop's own research/plan files only appear in a diff if force-added. Precedent force-adds them (`git ls-files` shows 3 plan files and 1 research file). `checkpoint-*.md` is tracked normally.
- **Renames**: `git diff --name-only` with rename detection on shows `hooks/x → docs/x` under the new name only (review finding 12). The diff must use `--no-renames`.
- **Type changes**: a file turned into a symlink shows as `mode change 100644 => 120000`, not `create mode 120000` (finding 19). Check the new mode of every entry with `--raw`, not `--summary` create lines.
- **Mode-only changes** (an executable bit on an allowed file) pass a name-only check (finding 14). Check modes.
- **Diff base**: `main...HEAD` (merge-base) is not what a merge adds when main moved or the branch merged main mid-way (finding "merge-time diff base"). Require main's tip to be an ancestor of the branch tip, then diff `MAIN_SHA TIP`, which is exactly what the merge adds.
- **Tip drift after approval**: commits added after the user approved could be merged unreviewed (subagent inference). Pin the approved SHA (`--expect <sha>`) and refuse when the tip moved.
- **A live loop after its brief closed** could still self-merge, untracked (api-pass9 #3). The merge must re-check `--check-brief` reads `open` on main at merge time.
- **HTML-comment policy line** (finding 8): FENCE_AWK already refuses an unclosed `<!--` and any line starting with `<`. A one-line `<!-- Build-loop policy: self-merge -->` does not start with `Build-loop`, so the exact-line rule already excludes it [inferred]. Add a test.
- **Case-insensitive filesystems**: `Hooks/x` is `hooks/x` on macOS. Compare denylist entries lower-cased.
- **Headless launches are blocked** [memory: cc-bare-headless-ignores-oauth-token; agent-worktrees-stall-and-stale-base]. `claude -p --bare` cannot use subscription auth, and Agent-tool worktree isolation fails or stalls. The cycle should not try to spawn loops itself.
- Failure-pattern grep: FP-033, FP-041, FP-043, FP-056, FP-146, FP-167 (see Prior failures section)

### Prior failures

Grep: `grep -inE 'denylist|allowlist|symlink|reflection-escape|boundary-too-wide|rename|guard-misses-subject' docs/thoughts/failure-patterns.md`.

- FP-033, FP-041, FP-056 (`reflection-escape`, `guard-misses-subject`): substring and name denylists were bypassed by reaching the blocked object indirectly. **Implication:** the self-merge gate is an **allowlist** (the brief's `Paths:` plus a fixed set of loop-owned files). The seed's denylist is defense in depth applied to `Paths:` entries, never the primary gate.
- FP-043 (`boundary-too-wide`, rename/hardlink write escape): renames are the documented bypass. Rename detection stays off.
- FP-146, FP-167 (symlinks hashed by target, tracked symlink to a host path): refuse any 120000 entry, added or type-changed.

### Review history (passes 6–9, 10, 11 and the chore review; 27 findings)

The seed covers 18 of the findings. These are not covered: the HTML-comment policy line; `docs/dev-cycle.md` missing from the self-merge exclusions; renames; mode-only changes; the 100644→120000 type change; the loop's own write-side symlink check; a mechanical check on `briefs/` and `docs/dev-cycle.md`; `Paths:`/`Policy:` line grammar; a live loop after its brief closed; a stop entry whose answer has no consumer; "never pushes"; the merge-time diff base; the seed's 6b removing the human gate; tip drift after approval. Each one is a row in the plan's bypass-family table.

## Design forks found (and why no full divergent-design run)

1. **How a loop is launched** (cycle spawns a subagent / headless `claude -p` / `/schedule` cloud agent / user starts a session from a printed prompt). Constraints settle it, so the choice is not open: the brief requires the user to read each brief before a loop starts; headless subscription auth and Agent worktree isolation are both broken here [memory]; scheduling is out of scope. → The script prepares the worktree and prints the loop prompt; the user starts the session. Recorded as a plan decision for approval.
2. **Plan approval inside a loop.** The brief says the brief does not replace it. A loop that reaches its plan without the user present ends with a `handoff: plan` marker. Resuming the session is the approval. No new answer parser.
3. **How the user approves a merge or a stop.** Reuse the existing keep-or-drop entry, filed early (on a marker instead of after 14 idle days), with marker-specific text. The approved merge is one command the user runs with the reviewed SHA pinned. The seed's "the cycle merges once the entry says yes" needed a new answer grammar and an owner. This reuses `--check-answer` unchanged.

Moved to plan: all [assumed] claims below were investigated or accepted, and the fork list is stable.

## Assumptions

- [assumed] `git update-ref`/`git merge` inside a fresh temporary worktree of main avoids disturbing `/workspace`'s checkout. Standard git behaviour; to be verified by a test.
- [assumed] bats tests can create symlinks and executable-bit changes in temp repos (Linux). Yes on this host; a macOS run is not covered.

## Files read

Last verified: 2026-10-02
docs/working/briefs/2026-10-02-build-loop-handoff.md
docs/working/seed-build-loop-handoff.md
skills/dev-cycle/SKILL.md
docs/dev-cycle.md
scripts/dev-cycle.sh
test/scripts/dev-cycle.bats
docs/roadmap.md
docs/working/questions.md
docs/decisions/log.md
docs/working/known-issues-dev-cycle.md
docs/thoughts/failure-patterns.md
workflows/pr-prep.md
workflows/codebase-onboarding.md
hooks/live-verify-gate.sh
test/merge-safety.bats
.gitignore
.gitattributes
devcontainer-config/link-claude-home.sh
docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md
docs/reviews/
