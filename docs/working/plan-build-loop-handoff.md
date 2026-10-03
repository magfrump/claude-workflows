# Plan: build-loop handoff

- **Goal**: The dev cycle can hand a build brief to an autonomous build loop and later collect its result, with the state and checks in a small tested script (`scripts/build-loop.sh`) rather than in prose.
- **Project state**: delivers the build-loop handoff (script, tests, skill/doc changes) · roadmap In flight item, split out of `feat/dev-cycle`; Q-103 waits on it · not blocked (cite: docs/working/briefs/2026-10-02-build-loop-handoff.md)
- **Task status**: in-progress (plan revision 2 after pre-mortem, architecture review and test strategy; awaiting approval; no code written)

Research: docs/working/research-build-loop-handoff.md
Plan-time reviews: `docs/reviews/pre-mortem-build-loop-handoff.md`, `docs/reviews/architecture-review-build-loop-handoff.md`, `docs/reviews/test-strategy-build-loop-handoff.md`

## What the gate can and cannot do (read first)

Loops run as the user's own uid, with a shell, in worktrees that share `/workspace/.git`. No script can contain a loop that turns hostile with its shell: it could run plain `git merge`, write `/workspace`'s working tree, or plant `.git` state. What this script does is make the **honest path** safe and checkable. Content reaches main only through a gate that decides from main's committed state and the exact merge result, and the gate never runs code the loop could have changed. The residual families (F11, F19, F28) are stated plainly in Q-103, so the policy choice is made knowing them.

## Decisions for the user to confirm at approval

- **D1. The cycle does not spawn loops.** `build-loop.sh --start <brief>` checks the brief and creates the branch and worktree from main's commit, then prints the loop's prompt. `--prompt <brief>` re-prints it for an existing branch (a resume, a stop, a needed main merge). The user starts each session, and that start is the user's reading of the brief. Why: the brief requires a human read; headless subscription runs and Agent-tool worktree isolation are broken here (memory); scheduling is out of scope.
- **D2. Plan approval stays in the loop.** The prompt says a brief is not plan approval. A loop needs an explicit "approve plan" message from the user in its session. Without one, it ends at its plan with the marker `handoff: plan`, and the user approves later in a resumed session (`--prompt`). Resuming alone is not approval.
- **D3. Markers are answered through the existing keep-or-drop entry, filed early.** When a branch tip is a marker (`ready`, `plan`, `stopped: <reason>`), the cycle files the keep-or-drop `you: judgment` entry at once instead of after 14 idle days. It does so only when the marker's commit date is later than the brief's last `Kept:` date (none: its own date), so a `keep` is not re-asked until a new marker. The entry text depends on the marker. A `ready` entry offers only **[1] keep** (waiting for my review) and **[2] drop**, with the merge command; there is no "done" (merging is what marks it done). A `plan` entry names the plan path and the `--prompt` command. A `stopped` entry gives the reason. The answers are read by the existing `--check-answer`/`Asked:`/`Applied:` path, so there is no new answer grammar.
- **D4. The approved merge is a command the user runs**: `~/.claude/scripts/build-loop.sh --merge <brief> --expect <full-sha>`. Running it is the approval, and `--expect` pins the reviewed tip. Under `self-merge`, the loop runs the same installed command.
- **D5. The self-merge gate is an allowlist.** A path may change only if the brief's `Paths:` lists it or it is one of the loop's own files. A denylist floor equal to dev-cycle.sh's `check_fix` predicate (plus code directories, dotfiles and root-level non-`.md` files) applies to `Paths:` entries and changed paths as defense in depth (FP-033, FP-041, FP-056).
- **D6. The gate runs only from outside the repo it judges.** `--check` and `--merge` refuse when the script's own real path is inside any worktree of the target repo. In claude-workflows that means the blessed image copy at `/opt/claude-workflows/scripts` (`~/.claude/scripts`). A loop that edits `scripts/build-loop.sh` on its branch therefore never runs its own gate. **Consequence:** the handoff works in this repo only after the image is rebuilt and blessed with U3 (Q-083 flow). Until then, briefs stay user-started as today.
- **D7. Merges are computed, not checked out.** `git merge-tree --write-tree MAIN TIP` (git ≥ 2.38; this host has 2.39.5) gives the exact result tree R. Every rule runs on `diff-tree -r --no-renames --raw -z MAIN R`. Then `commit-tree R -p MAIN -p TIP` makes the commit, and main moves by a compare-and-swap. No ancestry requirement, so a cycle landing on main between the review and the merge does not block it (pre-mortem L1). All git calls go through `install.sh`'s hardened pattern: `--no-optional-locks`, `-c core.hooksPath=/dev/null`, `-c core.fsmonitor=false`, `GIT_NO_REPLACE_OBJECTS=1`, and a state gate that refuses local `filter.*`/`include*`/`core.fsmonitor`/`hook.*`/`merge.*.driver`/`diff.*` keys, a non-empty `info/attributes` and any `refs/replace/`.

## Bypass-family pre-mortem (before any code)

Assume the handoff shipped and an autonomous loop landed something the user never reviewed. "N" marks a rule that applies under both policies; "S" marks a self-merge-only rule. Rows F25–F31, L1–L3 and the re-marks come from `docs/reviews/pre-mortem-build-loop-handoff.md`.

| # | Family | Covered? | Guard (tests) |
|---|---|---|---|
| F1 | Policy text variants (interim suffix, case, spaces, two lines, fence, HTML comment, BOM) | covered | Exactly one unfenced line, byte-exact after one trailing CR; FENCE_AWK refusal → review (T1–T3) |
| F2 | Policy raised on the loop's branch (settings or brief `Policy:`) | covered | Read from main's commit only; stricter of main and brief; both files N-denied (T4, T5, T14) |
| F3 | Policy lowered after a loop started | covered | Re-read at merge; stricter wins (T5) |
| F4 | Root-level scripts (`install.sh`, `Makefile`) | covered | S-allowlist; denylist refuses root non-`.md` even if listed (T10) |
| F5 | Dotfiles and dot-directories (`.gitattributes`, `.gitmodules`, `.claude/`, `.github/`) | covered | Any `.`-prefixed component denied (T10) |
| F6 | Renames out of a denied directory | covered | `--no-renames`; the D side refuses (T11) |
| F7 | Symlinks: added or type-changed | covered | Old and new mode of each raw entry ∈ {100644, absent} (T12) |
| F8 | Mode-only change, gitlink | covered (with F25's state gate) | Same mode rule; `diff-tree` with `--ignore-submodules=none` (T12, T26) |
| F9 | Instruction-file basenames in allowed dirs | covered | `INSTRUCTION_FILE`, any case, any dir (T10) |
| F10 | Files later runs read as rules or truth (`docs/decisions/`, `docs/thoughts/`, `docs/human-author/`, other loops' `docs/working/` files) | covered (widened) | Denylist floor = `check_fix`'s predicate, except the loop's own files keyed on the **full brief stem** (date included) (T10) |
| F11 | Files an instruction file `@`-imports | **partly** | The floor reuses `check_fix`'s import walk (its known-issues A2/A3 remain). Listed in Q-103 |
| F12 | Cycle-owned files: questions, archive, roadmap, `dev-cycle.md`, idea log, `cycles/`, any other brief **including a new one**, `briefs/closed/` | covered | N-denied via the lib's `writable()` plus `docs/dev-cycle.md`; added briefs too (T14) |
| F13 | Own brief edited beyond its Status line | covered | Merge-result blob = main's blob with the first unfenced `Status: open` → `Status: done` (T15) |
| F14 | Diff base differs from what lands | covered | Rules run on MAIN→R, the exact merge result (D7); conflict → refuse (T16) |
| F15 | Tip moved after review; `--expect` given a name | covered | `--expect` must be 40/64-hex and equal `show-ref --verify` of the branch (T17) |
| F16 | A closed brief's live loop merges | covered | Brief must read `open` on main at merge time (T18) |
| F17 | Non-ASCII, quoted or odd names | covered | `pathform` on every changed path; refuse without echoing (T13) |
| F18 | Case folding | covered | Lower-cased comparison (T10, T14) |
| F19 | The loop merges or pushes with plain git | **not covered** | Prompt (T19); no `push` in the script (T20); the next cycle's spot-check. Listed in Q-103 |
| F20 | Marker spoofing | covered | Empty, single-parent tip, ≥ 1 commit ahead, exact subject, reason charset (T6, T7) |
| F21 | Brief or plan text injection | partly | Evidence line in the prompt (T19); brief read from main's commit (T21); D1 human read; D2 plan approval |
| F22 | The merge disturbs a shared checkout | covered | D7: nothing checked out. If main is checked out in a worktree, see F29 (T22, T23) |
| F23 | Review artifacts as a write channel | covered (narrowed) | S: only *added* `docs/reviews/*` whose name contains the full brief stem (T10) |
| F24 | Gitignored working docs | covered (no bypass) | Only the diff lands (T9) |
| F25 | Shared `.git` state: config, hooks, attributes, replace refs, `diff.ignoreSubmodules` | covered for the gate's own git calls | D7 hardening and state gate (T26). A planted state the gate refuses blocks merges until the user cleans it |
| F26 | The loop edits the gate | covered | D6: refuse to judge from inside the target repo (T27) |
| F27 | Slug collision between briefs | covered | Own files keyed on the full brief stem (T10) |
| F28 | Forged answers or roadmap edits in `/workspace`'s working tree | **not covered** | Same-uid shell; listed in Q-103. Mitigation in U4: the cycle records `git status --porcelain` for its own files before reading answers and reports unexplained changes |
| F29 | Main checked out, under rebase or bisect, or switched mid-merge | partly | Not checked out anywhere → CAS `update-ref`. Checked out in W → W must be clean, `symbolic-ref HEAD` = main, no `rebase-*`/`BISECT_START`/`MERGE_HEAD` in any worktree; then `git -C W merge --ff-only NEW` (hardened) and verify `refs/heads/main` = NEW. Residual: W switches branch in the instant between the check and the ff, and the ff advances a branch that sat exactly at main's old tip. Recorded, not hidden (T22, T23) |
| F30 | The loop adds a new brief | covered | F12 (T14) |
| F31 | Two open briefs name the same branch | covered | `--status`/`--check` skip both (T28) |
| L1 | Cycle commits on main break review merges | covered | D7 drops the ancestry rule (T16) |
| L2 | Keep-or-drop reuse: done-without-merge, re-filing | covered | D3: `ready` entries have no done; the date rule stops re-filing |
| L3 | No way to re-prompt an existing branch | covered | `--prompt` (T24) |

**Not covered: F19, F28. Partly covered: F11, F21, F29.** None of them blocks self-merge mechanically. All are listed in Q-103 when it is re-routed (step 10), with the statement above about what the gate can and cannot do.

## Approach

U0 extracts dev-cycle.sh's reader into `scripts/lib/dev-cycle-read.sh`. The lib holds:

- `scrub` and the re-exec wrapper;
- `pathform`, `FENCE_AWK`/`oddwhy`, `INSTRUCTION_FILE` and the import walk;
- `writable`, `isbrief`, `check_fix`'s predicate;
- default-branch resolution as a function that returns instead of exiting;
- `check_brief`/`check_branch`, operating on a `MAIN`/`MAIN_SHA` the caller sets;
- one `brief_fields` reader that returns Status, Branch, Policy and Paths in one pass, so the brief has one parser (architecture finding 1).

Both scripts source the lib from their own `SCRIPT_DIR` and never from the target repo; a missing lib means exit 1. `build-loop.sh` resolves `MAIN_SHA` once and calls the lib directly, with no subprocess, so there is one view of main (architecture finding 3). Output follows dev-cycle.sh's check-mode conventions:

- `skip X: why` means unreadable; `refuse X: why` is a verdict;
- `-` marks a field that does not apply;
- `--check` ends with one summary line per brief;
- the read modes (`--policy`, `--status`, `--check`) exit 0 when every argument was answered;
- the writing modes (`--start`, `--prompt`, `--merge`) exit 2 on any refusal;
- usage errors exit 1.

## Script interface (`scripts/build-loop.sh`)

- `--policy` → `policy self-merge|review set|unset: <why>` from main's `docs/dev-cycle.md`.
- `--status BRIEF…` → `ok BRIEF STATE POLICY BRANCH LOOP SHA DATE [REASON]`. LOOP is `absent | working | plan | ready | stopped`.
- `--start BRIEF [--dir DIR]` → the brief must be `open` with `Branch:` absent. Runs `worktree add -b BRANCH DIR MAIN_SHA` (default `.claude/wt-<stem>`; DIR must be new and pass pathform, or be absolute). Prints the prompt. On failure, nothing is left behind.
- `--prompt BRIEF` → the brief must be `open` with its branch present. Prints the prompt; adds a worktree only if the branch has none.
- `--check BRIEF… [--expect SHA]` and `--merge BRIEF --expect SHA` → D6, D7, the N rules, and the S rules when the stricter policy is self-merge.
- Prompt content: the evidence line; the brief path and main's commit (`git show COMMIT:PATH`); the resolved policy; the marker rules; "never push; never write the questions files, the roadmap, `docs/dev-cycle.md` or any other brief; in your own brief change only the Status line, open→done, in your final change"; "a brief is not plan approval: get an explicit approve-plan message or end with `handoff: plan`"; "run the gate only as `~/.claude/scripts/build-loop.sh`".
- Brief machine lines (written by the cycle; read by `brief_fields` from main's commit; first unfenced line of each):
  - `Branch: NAME` (required);
  - `Policy: self-merge|review` (else review);
  - `Paths: P…` (space-separated pathform entries; a trailing `/` means a directory and matches at a component boundary; empty or absent means none; a malformed or duplicate entry → no self-merge).
- Own files of a brief with stem `YYYY-MM-DD-slug`:
  - `docs/working/{research,plan,checkpoint,handoff,test-strategy}-YYYY-MM-DD-slug.md`;
  - added `docs/reviews/*YYYY-MM-DD-slug*.md`;
  - its own Status line.

## Steps

Stacked review units (log row 62, ~400 changed code lines outside `docs/`; moved lines count twice). **U0** = step 1, **U1** = steps 2–3, **U2** = steps 4–5, **U3** = steps 6–7, **U4** = steps 8–10. If U0 measures over 400, it splits into U0a (`scrub`, `pathform`, FENCE_AWK, `writable`) and U0b (`check_brief`, `check_branch`, the import walk, default-branch resolution) before its review starts.

1. **Extract the lib** (U0, ~260 moved). Behaviour unchanged apart from the default-branch function returning. Also add T25 (the 53 existing tests stay green), T29 (sourcing the lib defines functions and runs nothing), T30 (a missing lib → exit 1). Commit `refactor:`.
2. **U1 tests**: T1–T8, T21, T28 in `test/scripts/build-loop-read.bats` with `test/lib/build-loop-fixtures.bash`. They fail. Commit `test:`.
3. **`brief_fields` in the lib, plus `build-loop.sh --policy` and `--status`** (~200). `check_brief` uses `brief_fields` (T31: they agree on Status; a brief made from SKILL's template parses). Commit `feat:`.
4. **U2 tests**: T9–T18, T20, T26, T27 in `build-loop-check.bats`. Commit `test:`.
5. **`--check`** (~200): D6, the state gate, merge-tree, the N and S rules, `--expect`. Commit `feat:`.
6. **U3 tests**: T19, T22–T24 in `build-loop-merge.bats`. Commit `test:`.
7. **`--start`, `--prompt`, `--merge`** (~150). Commit `feat:`.
8. **Skill (U4)** (~120 lines in `skills/`):
   - Briefs gain the three machine lines, and the cycle writes `Paths:` only when the policy and floor allow.
   - In flight check 3 takes the branch from `Branch:` and files the early keep-or-drop entry on a marker (D3), using `--status`.
   - Step 1 records unexplained working-tree changes to the cycle's own files (F28 mitigation).
   - Close step: the final message gives each new brief's `--start` command and each marker's command.
   - Remove "does not run yet" and "This skill does not read it".
9. **Docs (U4)**:
   - `docs/dev-cycle.md` drops "not built yet".
   - `workflows/codebase-onboarding.md:453` drops "a planned unit".
   - Decision log row 70 (D1–D7, and what the gate cannot do).
   - The seed's Status line → "superseded by row 70".
   - Research gotcha corrected: the installed copy is the image's, not the repo.
10. **Questions and brief (U4)**:
    - Re-route Q-103 to `you: judgment`, listing F11, F19, F21, F28 and F29, the D6 bless prerequisite and "what the gate cannot do".
    - Add one `you: terminal` entry: rebuild and bless the image once U3 has landed.
    - Set this brief's Status to `done` in U4's merge.

## Implementation order

`1 → 2 → 3 → 4 → 5 → 6 → 7 → [8, 9, 10]`. Sequential through step 7: each unit stacks on the previous one and its review-fix loop.

## Size estimate

- `scripts/build-loop.sh` ~420.
- `scripts/lib/dev-cycle-read.sh` ~320.
- `dev-cycle.sh` ~880 → ~600.
- Tests: three bats files of ~200 each, plus a fixtures helper of ~80.
- Units: U0 ~520 changed (moves), so probably U0a/U0b; U1 ~380; U2 ~420 (tight: if over, T26/T27 move to U3); U3 ~300; U4 ~150.

## Estimated context cost

Research ~150k (done, including three plan reviews). Implementation ~250k across five units. Review ~200k (five review-fix loops). One fresh session per unit, each loading `docs/working/checkpoint-build-loop-handoff.md`.

## Actual context cost (post-implementation)

__

## Test specification

From `docs/reviews/test-strategy-build-loop-handoff.md` (gaps G1–G20; the T-ids it closes are noted). The hermetic throwaway-repo setup is the same as `test/scripts/dev-cycle.bats`. On failure, each test prints the script's whole output and `git log --oneline --graph --all`.

| T | Case | Expected | Level |
|---|---|---|---|
| T1 | Policy exact `self-merge`/`review`, each with a trailing CR | that value, `set` | unit |
| T2 | Variants: interim suffix, case, trailing space, two lines, none, a one-line `<!-- -->` holding the line | review + why | unit |
| T3 | Policy line in a fence; open `<!--`; BOM; settings file missing, a symlink, a directory or only in the working tree; real `docs/dev-cycle.md` (G7, G19) | review | unit |
| T4 | Working tree self-merge vs commit review, and vice versa | the commit wins | unit |
| T5 | Stricter-of: all four combinations, and a brief without `Policy:`; `--check` reads machine lines from main (G15) | review unless both say self-merge | unit |
| T6 | Loop states absent/working/plan/ready/stopped; every field asserted; reason at 120 and 121 chars (G18) | as listed | unit |
| T7 | Spoofed markers: with content, a merge commit, suffixed subject, control/bidi in the reason, an orphan commit, a marker at main's tip with 0 ahead (G5) | working / `unreadable` | unit |
| T8 | A brief FENCE_AWK refuses; no `Branch:`; `Branch: main`/`HEAD`/bad name (G4) | skip + why | unit |
| T9 | Self-merge: `Paths:` changes, own research/plan/checkpoint files, an added `docs/reviews/x-<stem>.md`, own Status line | ok | integration |
| T10 | One refusal per path: outside `Paths:`; `Paths:` naming each code dir, `install.sh`, `.gitattributes`, `docs/.x`, `docs/CLAUDE.md`, `docs/sub/SKILL.md`, `docs/decisions/001-x.md`, `docs/thoughts/x.md`, an `@`-imported doc, `Hooks/x`; `Paths: docs/` touching another stem's checkout and an added review for another stem; a modified review; `Paths:` component boundaries `docs/a` vs `docs/ab.md` and duplicate or malformed entries (G10, G11) | refuse + rule | integration |
| T11 | Rename `hooks/x` → `docs/x` (listed) | refuse | integration |
| T12 | Symlink added; file → symlink; exec bit; gitlink | refuse (mode) | integration |
| T13 | Non-ASCII, space, newline path | refuse, no raw echo | integration |
| T14 | Review policy too: each cycle-owned file, another brief, an **added** brief, `closed/x`, `Docs/Roadmap.md`; and a normal change under review passes (G9) | refuse / ok | integration |
| T15 | Own brief: Status only (ok); `Paths:` changed; → dropped; moved to `closed/` | as listed | integration |
| T16 | Main gains a cycle commit after the tip: still ok, and main's own changes are not judged; a conflict → refuse | as listed | integration |
| T17 | `--expect` stale, a short SHA, a branch name, `HEAD`, missing | refuse / usage | integration |
| T18 | Brief `dropped`/`done`/`new` on main | refuse | integration |
| T19 | `--start`: the prompt holds every required line; worktree HEAD = MAIN_SHA; default dir; `--dir` rules (G8) | as listed | integration |
| T20 | No `push` in `build-loop.sh` or the lib (static) | none | unit |
| T21 | Working-tree edits to a brief's machine lines are ignored by `--start`/`--status`/`--check` | the commit wins | integration |
| T22 | `--merge` with main not checked out: commit parents (MAIN, TIP), CAS; a `git` PATH wrapper moves main between check and update → refuse, main untouched (G17); a repeat merge of a merged tip → refuse (G13) | as listed | integration |
| T23 | Main checked out clean in W → ff and verified; W dirty; W on another branch; any worktree mid-rebase of main or bisecting → refuse | as listed | integration |
| T24 | `--start` with brief not open or branch existing → refuse, nothing left behind; `--prompt` on an existing branch | as listed | integration |
| T25 | All 53 dev-cycle.bats tests after the extraction | pass | characterization |
| T26 | Planted state: hooks (a marker file must not appear), `core.fsmonitor`, a local filter, `info/attributes`, `refs/replace/`, `diff.ignoreSubmodules=all` hiding a gitlink | hooks inert; the rest refuse | integration |
| T27 | Gate run from a copy inside the target repo's worktree | refuse | integration |
| T28 | Two open briefs with one `Branch:`; several briefs in one `--status` call map in order (G6) | skip both; order kept | unit |
| T29–T31 | Lib sourcing is inert; missing lib → exit 1 (G16); `brief_fields` agrees with `check_brief`; run from a subdirectory or linked worktree (G20) | as listed | unit |

Deferred (G3): `build-loop.sh` output is scrubbed through the shared `scrub`. T7 asserts that the reason is not echoed raw, and no separate scrub test is added.

## Failure modes considered

| Failure mode | Guard |
|---|---|
| The extraction changes dev-cycle.sh's behaviour | U0 is its own unit; T25 characterization; T29, T30 |
| A self-merge lands a denied path through an unlisted family | The allowlist is primary (D5); F1–F31; the plan-time pre-mortem output |
| A review merge can never complete after a cycle lands | D7 (merge-tree, no ancestry); T16 |
| The merge lands on the wrong branch | D7 plus F29 checks; T22, T23; residual recorded |
| The gate runs the loop's own code | D6; T27 |
| The docs describe a design the script lacks | U4 lands last; code-fact-check runs in its review loop |

- `/pre-mortem`: triggered (a trust-boundary gate on what autonomous loops may merge). Output: `docs/reviews/pre-mortem-build-loop-handoff.md`; folded in as F25–F31, L1–L3, D6, D7.
- `/architecture-review`: triggered (`scripts/`, `test/`, `skills/`, `workflows/`, `docs/`). Output: `docs/reviews/architecture-review-build-loop-handoff.md`; folded in as the lib scope, one brief parser, no subprocess, CLI conventions and test layout.

## Risks

- **D6 means nothing works here until a re-bless.** Accepted: it is the only guard against F26 that doesn't trust the loop.
- **U0 moves ~260 lines of code that took 38 review passes.** It is pure movement plus one function boundary, under the 53 tests.
- **The state gate (F25) can refuse merges** when a legitimate local config sets a `diff.*` or `merge.*` key. The refusal names the key.
- **F19 and F28 rest on same-uid trust**, stated in Q-103.
- **Existing briefs have no machine lines.** They stay user-started, as today.
- **macOS is not tested.** dev-cycle.sh is already GNU-only.
- Deferred coverage (test-strategy "What NOT to test"): concurrency beyond the injected CAS race, and multi-host setups.

## Rollback

1. Each unit lands as its own `--no-ff` merge on main (U0[a/b], U1–U4). Revert in reverse order: `git revert -m 1 <U4> <U3> <U2> <U1> <U0b> <U0a>`. After the U0 reverts, run `bats test/scripts/dev-cycle.bats` (53 pass).
2. Set Q-103 back to `Needs: deferred` with its old Deferred line, delete the bless `you: terminal` entry, and run `scripts/questions.sh index`.
3. If the image was re-blessed with `build-loop.sh`, re-bless from the reverted main so `/opt/claude-workflows/scripts` no longer ships it (Q-083 flow). Until then, the installed gate stays callable, but no brief has a `Branch:` line the reverted skill would write.
4. A bad self-merge: first commit `Build-loop policy: review` on main, which binds running loops (the stricter value wins). Then `git revert -m 1 <that merge>` and set its brief to `Status: dropped`.
5. Worktrees from `--start`: `git worktree remove .claude/wt-<stem>`. Branch deletion is the user's call.

Irreversible part: none in git. A self-merged doc that a later session already read can't be un-read. The allowlist and the floor keep such changes away from files that later runs follow.
