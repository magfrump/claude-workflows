# Research: a per-repo preparation line for the dev cycle's health checkout

- **Goal**: let a repo name, in `docs/dev-cycle.md`, gitignored paths that a fresh health checkout HC needs from the main checkout before its health check runs, read only through `build-loop.sh --settings` from the default branch's commit, and copied into HC by a tested step.
- **Brief**: `docs/working/briefs/2026-11-20-health-checkout-prep.md` · Branch: `feat/health-checkout-prep` from c24cb1a7 · Policy: review · Date: 2026-11-20
- **Task status**: built (Path A pick: copy, by a new `build-loop.sh --health-prep HC` mode).

Failure-pattern grep: no matches found
(`rg -in -e 'health check' -e 'health checkout' -e 'build cache' -e 'cp -a' -e reflink docs/failure-patterns.md`; the near hits on `worktree`, `symlink` and `cache` (FP-011, FP-013, FP-014, FP-034, FP-062, FP-068, FP-146, FP-167) are about worktree add ordering, symlink TOCTOU on temp paths and stale caches, and none is about copying a directory into a checkout.)

## What exists

All observed at c24cb1a7 unless tagged.

1. **Step 1's HC.** `skills/dev-cycle/SKILL.md` step 1: the health check runs from a detached worktree HC at `WTB/wt-dev-cycle-health-DATE-HHMM`, made with `git -C MAIN_WT worktree add --detach HC W` for this one run and removed with it, so a mid-run entry in WT cannot turn the check red. "Nothing else names HC."
2. **Settings.** `read_settings` (`scripts/build-loop.sh`) reads `docs/dev-cycle.md` from main's commit through `main_file` and the lib's `SETTINGS_AWK` (`scripts/lib/dev-cycle-read.sh`), which counts each key's copies by its letters, case folded. `list_entries` is the shared list grammar (`KEY: none` or `KEY: E ...`, single spaces, each entry passing a form check, listed once) used by `Self-merge never:` and a brief's `Paths:`. `pathform` (lib) refuses a path not of letters, digits and `. _ - /`, one starting `/` or `-`, an empty, `.` or `..` part and any part starting `.git`.
3. **The main checkout.** `wt_of` (build-loop.sh) reads `git worktree list --porcelain -z` and sets `MAINWT`, the first record (empty for a bare repo). `--worktree-base` already writes in the main worktree under the state gate.
4. **git is hardened.** `git_harden` sets `GIT_CONFIG_GLOBAL=/dev/null`, so `check-ignore` inside the script reads the repo's `.gitignore` files and `.git/info/exclude`, never a user's global excludes file.

## Motive (S5)

- **The report.** philosophy-research's harness feedback F-016 (`docs/working/feedback/philosophy-research.md`, 2026-11-10): its health check runs `lake build Philos`, whose cache `verifier/lean-project/.lake` (gitignored, 1.9 GB: Mathlib's packages and the built modules) exists only in the main checkout. A fresh HC would rebuild Mathlib and 304 modules; the iteration copied the cache in by hand ("the build loops' own recipe"), and the gate then took 96 s. F-016 reads "nothing else names HC" as forbidding that.
- **It recurs.** F-019 in the same file (2026-11-14) says the warm Lean cache is copied in from `.claude/lake-build-warm-latest` on every iteration of a fifteen-iteration day. So the by-hand step is not a one-off: it is an unscripted step the cycle repeats each iteration, in prose the skill does not have, against S4 (mechanical steps in tested scripts). Only one repo reports it [observed]; any repo whose check needs a build cache (Lean, a Rust `target/`, a `node_modules`) meets the same cold start [inferred].
- **Status quo options.** (a) By hand: works, but each iteration re-derives it, the skill's text reads as forbidding it, and nothing checks what it copies or where it writes. (b) The repo's own health script prepares itself: possible today (the script runs in HC and can find the main worktree with `git worktree list`), but every such repo writes the same unchecked copy, and a script that links rather than copies writes into the main checkout's cache from the check. Neither refuses a symlink, a path outside the checkout or a path under `.git`.
- **Conclusion.** The need is real and recurring in one repo, small to serve, and the brief's refusal rules (H2) are what a repo-local recipe would not give. Build it, small.

## Divergent design: how HC gets the paths

Constraints that bite: H1 (no repo-chosen command in the gate's logic), H2 (refuse and name), H3 (hermetic tests), S1 (proportionate), S3 (one mechanism), S4 (a script, not prose), S8 (small, one revert), S10 (no owner chore), and the brief's own: nothing writes outside HC; refuse an absent path, a symlink, a path outside the main checkout or under `.git`.

| Option | What runs | Writes outside HC? | H1 | Cost per iteration |
|---|---|---|---|---|
| **A. Copy** (`cp -a --reflink=auto`) the listed paths from the main worktree into HC | the gate's script, no repo command | no | holds | one copy (a reflink on a filesystem that has them; else a full copy, about what F-019's iteration already does by hand) |
| **B. Symlink** each listed path in HC to the main worktree's | the gate's script | yes: the check's build writes through the link into the main checkout's cache | holds | none |
| **C. A repo-owned prepare hook** (a command named in the settings) | a repo-chosen command, run by the cycle before the check | whatever the command does | breaks the brief's rule (a repo-chosen command in step 1's logic); the health check is already that repo's code, so it adds nothing a health script cannot do (S3) | the command's |
| **D. Status quo** (by hand, or the repo's health script prepares itself) | the cycle's prose or repo code | unchecked | holds | the cycle re-derives it each iteration (S4) |
| **E. A mixed line** (per path, copy or link) | the gate's script | the link half does | holds | mixed |

- **B is out**: it fails the brief's "nothing writes outside the health checkout", and a red check could leave the main checkout's cache half-built. F-016's own by-hand recipe linked `.lake/packages`; that saving is lost under A, and a reflink-capable filesystem recovers most of it.
- **C is out** on the brief's H1 rule, and dominated by D(b) where it is not.
- **E** carries B's defect for the half that links.
- **D** is the status quo the motive weighs: no check on what is copied, and prose the cycle repeats.

**Pick (Path A, one option dominates): A, copy.** It is the only option that writes nothing outside HC and runs no repo command; its cost is a copy per iteration, which the reporting repo already pays by hand.

### Other choices (one-line notes, no 3-way fork)

- **Where the step lives**: a new `build-loop.sh --health-prep HC` mode, since `read_settings` and `wt_of` are there (S3); the alternative, a `dev-cycle.sh` mode, would read the settings a second way.
- **Line form**: `Health checkout copies: PATH ...` or `...: none`, through `list_entries` with `pathform`, the next unfenced line blank (as for `Self-merge never:`), so one grammar serves all three list lines (S3).
- **What `--settings` prints**: a sixth line, `copies PATH... set|none|malformed: WHY`, after `never` and before `constraints`... placed last instead, after `readers`, so callers reading lines by position see the old five unchanged.
- **All or nothing**: every path is checked before any is copied; any refusal copies nothing (H2).
- **On refusal, the cycle**: records `skipped: HC not prepared` with the refuse lines and runs no check (a cold check can run for hours), so the next iteration runs it again, as for `skipped: HC not made`.
- **Paths that must be gitignored**: `git check-ignore` in the main worktree, so a tracked or stray untracked path is refused (a tracked one is in HC already; a stray one would make HC's tree differ from W's).
- **Symlinks inside a copied tree**: refused too, with any other non-regular, non-directory entry, since a copied absolute link would let the check write outside HC. Residual risk: a cache that holds a symlink cannot be listed; the refusal names the first such entry.
- **HC must be a detached worktree of this repo other than the main one**, so the mode cannot write into WT or a loop's worktree.

## Refusals (what `--health-prep` refuses, all naming the gap)

- the copies line malformed, or the settings file not read (`copies malformed`);
- HC not an absolute path `--dir` takes, not a listed detached worktree, the main worktree, or reached through a symlink;
- a bare repository (no main worktree);
- per path: absent in the main worktree; reached through or being a symlink; not a regular file or directory; holding a symlink or special file; not ignored by git there (or `check-ignore` failed); holding HC; already present in HC, or a parent in HC that is a symlink or not a directory;
- a `mkdir` or `cp` that fails (then the line names the path; HC is removed by the cycle anyway).

## The line an owner would add

For philosophy-research's `docs/dev-cycle.md` (the owner's file, out of scope here):

```markdown
Health checkout copies: verifier/lean-project/.lake
```

followed by a blank line.

## Other docs that mention `--settings`' lines

- `skills/dev-cycle/SKILL.md` (step 1 and "Project settings"): changed here.
- `scripts/build-loop.sh` header: changed here.
- No other doc lists `--settings`' lines by count (`rg -n 'five lines' docs skills workflows guides` finds none outside the script and its test).

## Review

(Filled after pr-prep's review-fix loop.)
