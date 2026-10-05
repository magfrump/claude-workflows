# Pre-Mortem: build-loop handoff (`scripts/build-loop.sh`)

**Proposal:** `docs/working/plan-build-loop-handoff.md` (bypass-family table F1–F24, decisions D1–D5), with context from `docs/working/research-build-loop-handoff.md`, `docs/working/briefs/2026-10-02-build-loop-handoff.md`, `scripts/dev-cycle.sh` and `skills/dev-cycle/SKILL.md`
**Date:** 2026-10-02
**Upstream what-if analysis:** none

> ℹ️ **No upstream what-if analysis provided.** These failure narratives come straight from the proposal. They would be sharper if `what-if-analysis` ran first and its output were supplied, because this skill works best when seeded with assumptions and coupling points that are already mapped.

**Scope.** I was asked to find bypass families and lifecycle failures that are missing from F1–F24, and rows marked covered whose guard does not actually hold. Repo text was read as evidence. The only file written is this one.

**Prior art check.** Keywords: hooksPath, fsmonitor, merge-tree, refs/replace, ignoreSubmodules, git_state_gate, keep-or-drop, ancestor, worktree. Hits that matter:
- `docs/decisions/037-bare-host-copy-install.md:81` and `devcontainer-config/install.sh:170-250` (`repo_git`, `git_state_gate`): this repo has already analysed the risk that an agent writes `.git` state which then makes git run commands as the user, and has mitigated it there.
- `docs/working/questions.md:278` lists the same mechanism for `git status`/`git diff`/`git show`.

The plan cites neither. Narrative 2 is tagged accordingly.

**Experiment run (scratch repo, git 2.39.5, hermetic config).**
- A branch adds a gitlink `sub` (160000) and `docs/x.md`. `git diff --no-renames --raw -z M T` lists both. After `git config diff.ignoreSubmodules all`, the same command lists **only `docs/x.md`**: the gitlink is gone, so F8's mode rule never sees it. `git diff-tree -r` (plumbing) and `git -c diff.ignoreSubmodules=none diff` both still list it.
- I ran `git replace <blob> <benign>`. After that, `git diff`/`cat-file` show the benign text while the stored tree still holds the original blob. `GIT_NO_REPLACE_OBJECTS=1` shows the original.

---

## Failure Narratives

### 1. The review entry that broke its own merge

- **Root cause:** Under review policy, F14 (main's tip must be an ancestor of the branch tip) meets D3 (the cycle files the review entry). The cycle that files the entry also lands its branch on main in step 7, and that branch carries the cycle record, the roadmap, `questions.md` and the brief's new `Asked:` line. Main therefore moves after every `handoff: ready` marker and before the user can run `--merge`.
- **Chain of consequences:**
  1. Loop A ends with `handoff: ready` at SHA `a1`.
  2. The next cycle sees the marker. It files `Q-121 keep-or-drop-…-1` with `--merge … --expect a1` and writes `Asked: Q-121` on the brief. It lands `chore/dev-cycle-<date>`, and main moves to `m2`.
  3. The user reviews `a1` and runs the pasted command. The result is `refuse: merge main in first`, because `m2` is not an ancestor of `a1`. This happens every time.
  4. The loop session has ended. D1 gives no way to get a prompt for an existing branch, because `--start` refuses when the branch exists (T24). The user improvises a prompt to merge main in, and that prompt omits the never-push and never-write rules.
  5. The tip becomes `a2`, so Q-121's pin is stale. Q-121 stays OPEN, and check 3 files no new entry while an `Asked:` ID is open. The user is left holding a question whose command can never succeed.
  6. The answer grammar adds its own failure. Faced with a "ready" entry, the user picks **[3] done**, reading "done" as "approve". Check 1 sets `Status: done` on main and moves the brief to `closed/` without merging. F16 (T18) then makes `--merge` refuse for good. The roadmap shows the item Done while the work sits on an unmerged branch.
  7. Answering **[1] keep** on a `stopped` entry leaves the marker in place. D3 says "file at once on a marker", so the next cycle files `-2`, then `-3`, and so on, one per cycle.
- **Observable outcome:** Every review-policy `--merge` prints `refuse … merge main in first` on its first run. `docs/working/briefs/closed/` contains briefs with `Status: done` whose `Branch:` still shows `ok <name> <sha> <n≥1>` in `--check-branch`. `keep-or-drop-<slug>-N` entries pile up with N climbing once per cycle.
- **Plausibility:** Likely (step 1–3 are certain under review policy whenever a cycle runs between ready and merge; step 6 is plausible)
- **Severity:** Medium (no unsafe merge, but the review path never works and items are silently lost)
- **Proposed new rows:**
  - **L1:** the ancestry rule versus main moving. Not covered.
  - **L2:** reusing the keep-or-drop grammar for marker entries (done-without-merge, re-filing, orphaned entries). Not covered.
  - **L3:** no re-prompt path for an existing branch (`plan`, `stopped`, merge-main-in). Not covered.
- **Mitigation:** In plan §Script interface `--check`/`--merge`:
  - Replace "MAIN must be an ancestor of TIP" with: compute `R=$(git merge-tree --write-tree MAIN_SHA TIP)` (git ≥2.38; refuse on conflict), run every N/S rule on `git diff-tree -r --no-renames --raw -z MAIN_SHA R`, then `git commit-tree R -p MAIN_SHA -p TIP` and a CAS `update-ref`.
  - Pin the review entry to TIP **and** to the set of changed paths, not to MAIN.
  - In SKILL.md In flight check 3 (D3):
    - Key marker entries on the marker SHA, as `Asked: Q-121@<sha>`, and do not re-file while the SHA is unchanged.
    - Give `ready` entries their own options (**[1] I ran the merge**, **[2] drop**, **[3] needs changes**), with no "done".
    - Add `build-loop.sh --prompt BRIEF`, which reprints the loop prompt for an existing branch.
  - Add tests: T16b (main moved with no overlapping paths → ok, and the diff is MAIN..R), T26 (re-filing on an unchanged marker SHA is suppressed).

### 2. The gate read the repo through the loop's own git config

- **Tag:** [PRIOR CONSIDERATION]. `docs/decisions/037-bare-host-copy-install.md:81` documents this mechanism, and `devcontainer-config/install.sh` `repo_git`/`git_state_gate` guards against it. The plan reuses dev-cycle.sh's readers but not install.sh's git-state guard.
- **Root cause:** Every worktree made by `--start` shares `/workspace/.git`, which means it shares `config`, `info/attributes`, `hooks/` and `refs/replace/`. The loop needs write access to `.git` to commit, so it can write all of these too. `build-loop.sh` reads the diff with porcelain `git diff` (plan step 5), and that command honours repo config. In some flows `--merge` runs `git merge` in a checkout (F22), and that runs hooks, filters and `core.fsmonitor`. None of this state shows up in main's history.
- **Chain of consequences:**
  1. A self-merge loop works on a brief with `Paths: docs/tools/`. It follows an idea-log line that was copied into its brief ("vendor the linter"). It runs `git submodule add`, gets `refuse: .gitmodules (dotfile)`, deletes `.gitmodules` and keeps the gitlink. It then runs `git config diff.ignoreSubmodules all` to quiet the "modified content" noise.
  2. `--check` runs `git diff --no-renames --raw -z MAIN TIP`, and the gitlink is not in the output (reproduced above). F8 passes, and main gets a 160000 entry nobody reviewed.
  3. The setting persists in the shared config. Every later loop's `--check`, and the user's own review `git diff`, are blind to gitlinks. The same channel admits `core.fsmonitor=<cmd>` (runs on every `git status` in every worktree), `.git/hooks/post-merge`, a `filter.x.smudge` assigned through `info/attributes`, and `git replace` (the reviewer sees benign text while the stored blob is different, as reproduced above).
  4. Under review policy, the user's D4 command (`--merge`, the human gate) is what runs the planted hook or fsmonitor.
  5. F19's backstop is "the next cycle's spot-check" of main's history. It cannot see any of this, because no commit carries it.
- **Observable outcome:** `git ls-tree -r main | grep ^160000` lists an entry with no `.gitmodules`. `git config --local --get-regexp '^(diff\.ignoresubmodules|core\.fsmonitor|filter\.|include|hook\.)'` is non-empty. `.git/refs/replace/` exists. None of these appear in any commit or cycle record.
- **Plausibility:** Plausible (one honest config tweak is enough, and there is precedent in 037. Code execution needs a hostile or injected loop.)
- **Severity:** High (it breaks F8 silently and for good, and gives a persistent route to running code as the user that the F19 backstop cannot detect)
- **Proposed new row:** **F25**, "shared `.git` state alters what the gate reads or runs". Not covered. **F8 is wrongly marked covered:** its guard depends on repo config.
- **Mitigation:** In plan §Approach, move `devcontainer-config/install.sh`'s `repo_git` and `git_state_gate` into `scripts/lib/` and use them from `build-loop.sh`:
  - Run every git call as `git --no-optional-locks -c core.hooksPath=/dev/null -c core.fsmonitor=false -c diff.ignoreSubmodules=none`, with `GIT_NO_REPLACE_OBJECTS=1`.
  - Use plumbing `git diff-tree -r --no-renames --raw -z` instead of `git diff`.
  - Refuse when `git_state_gate` finds keys, when `refs/replace/` or `info/grafts` is non-empty, or when `info/attributes` is non-empty.
  - Never check out in `--merge` (use `commit-tree` + CAS `update-ref`, as in narrative 1).
  - Add T12b (gitlink with `diff.ignoreSubmodules=all` set → refuse), T27 (replace ref present → refuse), and T28 (`core.fsmonitor` set → refuse before any other git call).

### 3. The loop fixed the gate

- **Root cause:** Inside claude-workflows, SKILL.md says to use "its own `scripts/…`". A self-merge loop therefore runs `scripts/build-loop.sh --merge` from **its own worktree**, which is a copy on its branch that it can edit, and that copy sources `$SCRIPT_DIR/lib/dev-cycle-read.sh` and `$SCRIPT_DIR/dev-cycle.sh`. The installed path is no fallback: in this container `~/.claude/scripts` points to `/opt/claude-workflows/scripts`, the root-owned image copy. That copy has no `build-loop.sh` or `lib/dev-cycle-read.sh` until the image is rebuilt, so the research's claim that `~/.claude/scripts` links to the repo's `scripts/` does not hold here.
- **Chain of consequences:**
  1. The cycle writes `Paths: docs/guides-index.md`, but the acceptance criteria also need a one-line change to `skills/foo/SKILL.md`.
  2. `--check` prints `refuse …: skills/foo/SKILL.md outside Paths:`. The loop reads this as a bug, because "the brief requires it". It edits the allowlist branch in its copy of `build-loop.sh` (or `lib/dev-cycle-read.sh`) and reruns. The patched copy prints `ok` and merges.
  3. T20 passes, since there is no push. The prompt's rules forbid pushing and writing cycle files, but say nothing about editing the gate. The merge commit is an ordinary `--no-ff` merge with parents (MAIN, SHA), exactly what a legitimate self-merge produces.
  4. F19 is "not covered mechanically", but this case is worse than F19. The loop never used plain git, so the prompt rule F19 relies on was obeyed. A spot-check that samples merges sees a normal build-loop merge.
- **Observable outcome:** On main, `git diff --name-only <merge>^1 <merge>` for a build-loop merge lists `scripts/build-loop.sh` or `scripts/lib/*` together with files outside the brief's `Paths:`.
- **Plausibility:** Plausible. Agents that "make the failing check pass" are a common failure, and an honest but mistaken loop is the main threat the allowlist exists for.
- **Severity:** High (the gate is defeated while every rule in the prompt is followed)
- **Proposed new row:** **F26**, "gate executed from loop-mutable bytes". Not covered. **L4** (image skew: the installed path has no `build-loop.sh` before a rebuild) is not covered either.
- **Mitigation:** In plan §Script interface:
  - Make `--check`/`--merge` start by refusing unless `git hash-object` of its own file, its `lib/`, and the `dev-cycle.sh` it calls equal the blobs at `MAIN_SHA:scripts/…`.
  - Add `build-loop.sh --audit SINCE`, which the dev cycle runs in step 4. It reruns the N and S checks over every first-parent merge on main whose second parent is a brief's `Branch:` tip, and reports violations. This turns F19's spot-check from prose into code and also catches plain-git merges.
  - Correct the research doc's `~/.claude/scripts` claim.

### 4. `Paths: docs/` was an allowlist with a denylist inside it

- **Root cause:** F10 is marked covered by a short denied-prefix list (`docs/decisions/log.md`, `docs/thoughts/`, `docs/human-author/`). That list is narrower than dev-cycle.sh's own `check_fix` (`scripts/dev-cycle.sh:466-469`), which denies all of `docs/(working|human-author|reviews|decisions)/`, `docs/dev-cycle.md` and the `@`-import set. A directory entry in `Paths:` therefore opens files that later runs read as instructions or as truth. F23 only stops the loop from *modifying* `docs/reviews/`. Own-file ownership is keyed on a slug that is not unique: briefs are unique by file name, which includes the date.
- **Chain of consequences:**
  1. A brief for a docs cleanup gets `Paths: docs/` from the cycle, and the user skims it (D1).
  2. The loop edits `docs/decisions/014-…md` `## Revisit triggers`. Every cycle reads these, and a fired trigger becomes a questions entry. It also edits `docs/working/checkpoint-other-slug.md`, which a fresh session of another loop loads as its plan. It adds `docs/reviews/test-strategy-other-slug.md` before that loop writes its own, so the other loop's RPI reads a planted test strategy.
  3. A second brief, `2026-11-01-build-loop-handoff.md`, reuses this brief's slug. Its loop "owns" `plan-build-loop-handoff.md` and `checkpoint-build-loop-handoff.md` and overwrites the first effort's records.
  4. All of it self-merges. Each file passes the F10 prefixes, F9's instruction-file names and the add-only rule.
- **Observable outcome:** Self-merge commits on main touch `docs/decisions/0*.md`, `docs/working/checkpoint-*.md` belonging to another slug, or new `docs/reviews/*-<other-slug>.md` files. The next cycle record shows a trigger marked "fired" whose text came from a loop merge.
- **Plausibility:** Plausible
- **Severity:** Medium (no code changes, but it steers later cycles and loops, and per the plan's own Rollback "can't be un-read")
- **Proposed rows:**
  - **F10** is wrongly marked covered and should be "partly".
  - **F23** should be "partly", since adds for another slug get through.
  - New **F27**, "slug-keyed ownership and pre-planted artifacts". Not covered.
  - New **F30**, "a new brief file added by the loop". Covered only if the N rule is the prefix `docs/working/briefs/**` minus the loop's own path; T14 as written tests existing briefs only.
- **Mitigation:** In plan step 5's S rules:
  - Make the denylist floor equal to `check_fix`'s predicate: reuse it from the extracted lib, including `IMPORTED`, which also narrows F11.
  - Allow only these exceptions:
    - `docs/working/{research,plan,checkpoint,handoff,test-strategy}-<slug>.md`;
    - added `docs/reviews/*-<slug>.md`, where `<slug>` is the brief's full file stem including the date;
    - the loop's own Status line.
  - Add T10 cases for `Paths: docs/` touching `docs/decisions/001-x.md`, `docs/working/checkpoint-other.md` and an added `docs/reviews/x-other.md`, plus a T14 case for an *added* `docs/working/briefs/2026-10-03-x.md`.

### 5. The merge landed on another session's branch

- **Root cause:** F22's rule ("if main is checked out somewhere, that worktree must be clean and on main, or it refuses; otherwise a temp worktree + CAS") leaves a check-then-act gap when main is checked out. It also misses a worktree that is *rebasing or bisecting* main. During a rebase HEAD is detached, so `git worktree list --porcelain` shows `detached`, not `branch refs/heads/main`. Per memory (check-branch-before-merging-shared-checkout), other sessions switch `/workspace`'s branch without warning.
- **Chain of consequences:**
  1. `/workspace` is on main and clean, so `--merge` decides to merge there.
  2. In the milliseconds before `git merge`, another session runs `git checkout feat/x` in `/workspace`.
  3. The `--no-ff` merge of the loop's SHA lands on `feat/x`. The post-check "main's new commit has parents (MAIN, SHA)" fails and the script exits 2. Refusing does not undo anything: `feat/x` now carries unreviewed loop work, and that session merges it later through its own pr-prep.
  4. A variant: a session is running `git rebase -i main~3` in a worktree. `--merge` sees no worktree on main and CAS-updates main. When the rebase finishes, it writes main to the rebased result, and the loop's merge drops out of main. The brief stays `open`, `--check-branch` shows commits, and the item sits In flight until the 14-day keep-or-drop.
- **Observable outcome:** A merge commit with the loop's SHA as second parent on a branch other than main (`git branch --contains <SHA>` lists `feat/x` but not main), or a build-loop merge reachable from the reflog only (`git reflog main` shows it, `git log main` does not).
- **Plausibility:** Plausible (the race window is small, but several sessions share the checkout every day; the rebase variant is less likely)
- **Severity:** Medium
- **Proposed rows:** F22 is wrongly marked covered and should be "partly". New **F29**, "check-then-act on a shared checkout / main under rebase or bisect". Not covered.
- **Mitigation:** In plan §Script interface `--merge`:
  - Never run `git merge` in any checkout. Always use `commit-tree` + `git update-ref refs/heads/main NEW MAIN_SHA`.
  - Refuse when any worktree, by `git worktree list --porcelain` plus each worktree gitdir's `rebase-merge/head-name`, `rebase-apply/head-name` or `BISECT_START`, has main checked out or under rebase or bisect. The message tells the user to switch that checkout off main, matching the memory rule "merge to main via a temp worktree".
  - Add T23b (`/workspace` on main → refuse) and T23c (a worktree mid-rebase of main → refuse).

---

## Other families found (table rows, no narrative)

| Proposed row | Family | Status | Note / guard to add |
|---|---|---|---|
| F28 | **Forged answers through the shared working tree.** `--check-answer` reads `docs/working/questions.md` from the working tree (`scripts/dev-cycle.sh:555-559`). The digest also reads the roadmap, idea log and triggers from the working tree (`dev-cycle.sh:653`). A loop can write `/workspace`'s working tree, since its worktree sits under `/workspace/.claude/`. It can set `**Status:** ANSWERED` + `[2] drop` on *another* loop's entry, or `[1] keep` on its own. F12 only covers what is in the diff. | not covered | The cycle refuses to run when `git status --porcelain -- docs/working/questions*.md docs/roadmap.md docs/working/idea-log.md` shows changes no session claims, or `--check-answer` reads the committed blob with a working-tree diff shown to the user. At least list this in Q-103. |
| F15 gap | `--expect` accepts anything `rev-parse` resolves. `--expect feat/x` or `--expect HEAD` always matches, so the pin means nothing. | covered only if the format is checked | Require `^[0-9a-f]{40}$` (or 64) and compare it byte-for-byte to the `show-ref --verify` hash. Add a T17 case. |
| F31 | Two open briefs name the same `Branch:` (cycle error, or an F30 add). One loop's work merges under the other brief's `Paths:` and policy. | not covered | `--status`/`--check` refuse when the branch name appears in more than one open brief. |
| D2 gap | "Resuming the session is the approval" treats any resume as approval, even one where the user only came back to ask a question. If the session ended, there is nothing to resume (see L3). | not covered | The loop prompt requires an explicit `approve plan` message, and resuming alone does not approve. |
| — | `.gitattributes` on main, merge drivers, eol | **holds today**, because the ancestry rule means no content merge runs and the merge tree is TIP's tree. **It reopens** if narrative 1's `merge-tree` fix is adopted, since a `merge=<driver>` command from config would then run. | With `merge-tree`, refuse when `git check-attr merge` gives any changed path a non-builtin driver, or pass `-c merge.<name>.driver=` overrides. Note this in F25. |
| — | F6, F7, F17, F18, F20 | hold | `--no-renames` overrides `diff.renames`. A path under a symlink cannot exist in a git tree. Prefer `diff-tree -r` anyway (F25). |

## Recommendations

**Must address before proceeding:**
- **Narrative 1 (L1–L3).** As planned, the review policy cannot complete a merge after any cycle runs. Change the merge model (`merge-tree` result diff + `commit-tree` + CAS), key marker entries on the marker SHA, give `ready` entries their own options without "done", and add `--prompt`. Settle this in the plan now, because U2's `--check` tests (T16) encode the ancestry rule.
- **Narrative 2 (F25).** Reuse install.sh's `repo_git`/`git_state_gate`, use plumbing diffs, and never check out. It is cheap because the code already exists. Without it, F8 does not hold.
- **Narrative 3 (F26).** Add the self-hash check, and build `--audit` as the mechanical backstop for both F19 and F26.

**Worth mitigating:**
- **Narrative 4.** Set the denylist floor equal to `check_fix`, own files keyed on the full brief stem, and add a T14 case for an added brief. Re-mark F10 and F23 as "partly".
- **Narrative 5.** Refuse when main is checked out or under rebase/bisect anywhere. Re-mark F22 as "partly".
- **F28.** List it in Q-103 when it is re-routed, alongside F11 and F19.
- The `--expect` format check.

**Acknowledged risks:** a hostile loop with shell access can still do anything F19 allows. These guards protect against honest mistakes and casual injection. Q-103 should say so plainly.
