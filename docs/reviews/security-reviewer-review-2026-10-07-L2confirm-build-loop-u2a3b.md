Commit: 4828727d

# Security Review: feat/build-loop-u2a3b, loop 2 confirming pass (Q-120 [1])

**Scope:** `main...4828727d` (full unit; aa379ee9 is the code under first review: top-level-only `.git` skip, per-resolved-path work charge and `tried` memo, import_home keyed on raw HOME)
**Date:** 2026-10-07
**Based on:** Stage 1 summary (`code-fact-check-report-build-loop-u2a3b-L2-confirm-r{1,2,3}.md`, consolidated; not redone); my prior report `security-reviewer-review-2026-10-07-L2final-build-loop-u2a3b.md`; rubric "Loop 2, iteration 3 of 3"; override-log rows for `feat/build-loop-u2a3` and `feat/build-loop-u2a3b`.

Harness (executed): `/tmp/u2a3bsecc-qT5S`, holding `git archive` copies of `scripts/` at 4828727d (`new/`), e1654266 (`old/`) and the merge-base f6fdda68 (`base/`), probe repos, and Claude Code 2.1.292 run headless (`claude -p`, throwaway `HOME` and `CLAUDE_CONFIG_DIR` under the dir, dummy key, no network, an `InstructionsLoaded` hook logging loads, stopped by `timeout 25`, rc 124 each run). Scripts are in the session scratchpad: `u2a3bsecc-p1.sh` (gitfile), `-p2.sh` + `-gen.py` (parser differential), `-p3.sh` (import_home), `-p4.sh` (command files), `-imps.sh` (the bats `imps` helper's shape), `-cc.sh`. No probe process is left running (checked with `ps`).

## Trust Boundary Map

```
B1: instruction-file text (checkout file / main blob)            → import_targets (sed, UTF8_WELL_FORMED gate, python3, IMPORT_AWK) → IMPORTED / IMPORTED_MAIN → check_fix / floor
B2: process environment (HOME, else the passwd entry)            → import_home (keyed on raw HOME) → IMPORT_AWK emit's ~/ join      → B1's name set
B3: checkout file system (nested .git, symlinks, untracked)      → main_imports per-candidate checks (top-level .git skip, parent loop, -d/-e) → walk ok / failed
B4: instruction files outside ROOT_REAL                          → [no transition: never read]                                      → session instructions (routed to U2b)
B5 (new): top-level .git gitfile text (git writes the gate worktree's gitdir path) → main_imports `[[ "$p" != .git ]] || continue` → [not read]
B6: project command files (.claude/commands/*.md)                → [no transition: not a walk start in either walk]                → prompt of an invoked command
```

| Source | Mutability | Trust classification |
|---|---|---|
| S1: text of repo instruction files and the files they name | runtime-mutable (branches the loop writes; main after a self-merge) | UNTRUSTED toward path-construction and the walk/floor decision sinks |
| S2: HOME / passwd home | deploy-time (process env) | trusted for availability; a path prefix, so a relative or empty value must fail or match Claude Code |
| S3: checkout state (nested `.git`, symlinks, untracked files) | runtime-mutable by whoever writes the checkout | UNTRUSTED for the main walk's pass/fail decision |
| S4: top-level `.git` gitfile text | written by git from the worktree/gitdir path the gate (U2b) chooses | host-controlled; read by Claude Code as a file when imported, so its text is S1-like toward the walk decision |
| S5: `.claude/commands/**/*.md` text | runtime-mutable (branch content) | UNTRUSTED; its `@` names load at invocation |
| S6: IMPORT_OUT_MAX, IMPORT_HOME*, UTF8_WELL_FORMED, UNI_SPACES, work bound 50,000,000 | code-constant (reset at source time) | trusted |

What crosses: S1 text becomes path candidates resolved below ROOT_REAL (B1); S2 joins `~/` names (B2); S3 and S4 decide whether the main walk fails or skips (B3, B5); S5 and B4's files are never starts. Within the parser itself (B1, B2) I found no fail-open; both findings are start/skip-set gaps outside the parser.

## Findings

#### F1. The top-level `.git` skip lets a linked worktree's gitfile import pass the main walk; main's walk failed closed on the same tree

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:772-778` (main_imports)
**Boundary:** B5 (S4)
**Move:** 11 (bypasses for every guardrail), 3 (error path)
**Confidence:** High on the mechanism (executed against the 2.1.292 binary); reachability needs a gate checkout whose gitdir path holds whitespace followed by `@`, which only the host sets
**Legibility-target:** for-author
**Evidence:** executed

```
      # The top-level .git (a prefix candidate from @.gitignore; a linked
      # worktree's gitfile) names no file main has, and is skipped. A nested .git
      ...
      [[ "$p" != .git ]] || continue
```

Probe `u2a3bsecc-p1.sh`: main checkout at `$d/a @docs/x.md /m`, main's `CLAUDE.md` is `see @.git`, main stores `docs/x.md`; a linked worktree `$d/wt` at main (U2b's planned gate shape). Its gitfile reads `gitdir: /tmp/u2a3bsecc-qT5S/a @docs/x.md /m/.git/worktrees/wt`.

```
Claude Code:  "file_path":".../wt/.git","load_reason":"include"
              "file_path":".../wt/docs/x.md","load_reason":"include"
main walk 4828727d:  walk: ok   docs/x.md: -      (e1654266: the same)
tree walk 4828727d:  walk: ok   docs/x.md: imported
main walk f6fdda68 (merge-base):  walk: failed   docs/x.md: imported
```

So this is a regression from main in this one shape: main's walk refused because `.git` is a checkout file that is not a plain directory; the unit's skip (dd51e9a7, kept for the top level in aa379ee9) passes it. The skip has a real availability reason: in a worktree gate checkout every `@.gitignore`-like token yields the prefix `.git`, which is a gitfile, so without the skip the walk would always fail. My prior F2 recommendation ended with a U2b note (the gate worktree's path should not hold whitespace followed by `@`). The plan's U2b bullet does not carry it (grep of `plan-build-loop-handoff.md` for gitfile/whitespace finds nothing).

Why Low: branch content cannot write the gitfile or choose the path. Both come from the gate's own worktree creation and the main checkout's location, so the floor rule's reachable-environment bar is not met. The path also needs a space, an `@` and a name that ends at a blank, and main's instruction file must import exactly `.git` (or `./.git`, `.git#x`).

**Recommendation:** Skip the top-level `.git` only when it is a plain directory, or a regular file whose text holds no `@` (for example `[[ -d .git && ! -L .git ]] || ! grep -q @ .git`). Otherwise fail, which is still one line and keeps worktree checkouts passing. Or carry it to U2b as a precondition (the gate worktree's gitfile text holds no `@`) or to U2a3c (phase 2 reads a top-level regular `.git` like any checkout file main lacks). Whichever you choose, put the dropped U2b note into the plan.

#### F2. `@` names in `.claude/commands/` files load when the command is invoked; neither walk starts there (A5's last "untraced" shape, now traced)

**Severity:** Medium (floor rule: named mechanism, executed; exposure today is nil)
**Location:** start sets: imported_names (`tree_starts`, `INSTRUCTION_FILE`), main_imports (`:731`, `.claude/rules/` only); `docs/working/known-issues-dev-cycle.md` A5 ("Untraced (no host probe yet): whether `@` references in `.claude/commands/` files load"); lib `:478-479` ("the one shape A5 lists as untraced")
**Boundary:** B6 (S5)
**Move:** 1 (trust boundaries), 5 (invert: what the start set does not cover)
**Confidence:** High on the mechanism; Medium on its weight (the text arrives as a command's attachment, not as memory)
**Legibility-target:** for-orchestrator-synthesis
**Evidence:** executed

Probe `u2a3bsecc-p4.sh`: `.claude/commands/probe.md` is `cmd body see @docs/cmdimp.md`, and `docs/cmdimp.md` is `CMDIMP-MARKER`. `claude -p "/probe"` (2.1.292): the transcript holds `<command-name>/probe</command-name>`, then `Called the Read tool with the following input: {...cmdimp.md...}` and `Result of calling the Read tool: 1	CMDIMP-MARKER`. In the same repo after a commit:

```
main walk 4828727d:  walk: ok   docs/cmdimp.md: -
tree walk 4828727d:  walk: ok   docs/cmdimp.md: -
merge-base f6fdda68: the same (pre-existing)
```

A command file on main that imports a doc therefore lets `--check-fix` print `ok` for that doc, and an in-cycle fix (or, from U2a4, a self-merge the floor admits) can rewrite text that every later invocation of the command reads as part of its prompt. This is A2's class (a start the walk does not know), not a parser miss. Exposure today: `git ls-tree -r 4828727d` lists no `.claude/` file at all.

**Recommendation:** Update A5 and the lib's header now: the shape is traced, it loads at invocation, and it is not covered. Then either add `.claude/commands/**/*.md` as starts in both walks (the same pattern as main_imports' `.claude/rules/` arm; the tree walk needs it in `tree_starts`), or route it to U2a4's shared start predicate (rubric L2-final architecture F5) beside B4's outside-repo starts. Untested siblings to cover in the same work: `.claude/agents/*.md`, output styles, and user-level `~/.claude/commands/` (B4's family).

## Untested bypass candidates

- `.claude/agents/*.md` and `.claude/output-styles/*.md` bodies holding `@` names. Not probed: invoking a subagent needs a model turn, and this sandbox has no network.
- A HOME symlink retargeted between two walks in one process. `IMPORT_HOME_REAL` is keyed on the HOME string, so it would be stale. No caller does this; the e1654266 key had the same property.
- `@./.git` and `@.git#x` against the binary. Traced only: awk normalizes both to `.git`, and Claude Code cuts at `#` and resolves `./`, so I expect F1's result.
- gawk or busybox awk running IMPORT_AWK's `tried` and `work` arithmetic. Only mawk (this host's awk) was run.

## Endorsement Claims

- **Claim:** aa379ee9's `tried` memo and put's per-resolved-path charge change no output of import_targets for inputs under the work bound. Every name e1654266's parser printed, 4828727d's prints, in the same order.
  **Location:** `scripts/lib/dev-cycle-read.sh:557-577` (put; read to its last line), `:542-556` (emit)
  **Evidence:** executed
  **Verified:** `u2a3bsecc-p2.sh`: 600 generated lines (repeated names, `./`, `../`, `~/`, absolute names into the root and its home, `..`, `#`, escaped spaces, `<!--`/`-->`, `@` after a letter, `(` or a backtick, é, NBSP), each run with dir `""`, `docs` and `docs/sub`, HOME a symlink into the repo (so `home != homereal`). Result: 0 differing outputs, and 0 cases where 4828727d failed but e1654266 succeeded. A 40-line batch printed 332 names, with identical md5 from both libs.
  **Not verified:** inputs near the 50,000,000 work bound, where 4828727d fails by design and e1654266 did not (fail-closed; Stage 1 timed the 4 MiB case); awks other than mawk.
  **route: code-fact-check**

- **Claim:** import_home's raw-HOME key recomputes on every HOME change (set → unset → empty → set → relative). Unset and empty read the passwd home, and a relative HOME makes a `~/` name fail the parser.
  **Location:** `scripts/lib/dev-cycle-read.sh:616-623`, emit `:550-554`
  **Evidence:** executed
  **Verified:** `u2a3bsecc-p3.sh` in one shell: `A` → home=p2home, real=p2root/docs, done=`xset:<A>`; `unset` → `/home/node`, done=`x:`; `empty` → `/home/node`, done=`xset:`; `A2` → A again; `rel` → home=`rel`, and `@~/a.md` makes import_targets return 1. Back at A, `@~/a.md` prints `docs/a.md` through the real spelling, rc 0. Unset (`x:`) and empty (`xset:`) cannot collide, and no set value maps to `x:`.
  **Not verified:** a getent that fails transiently with HOME unset. Traced: `h=""` is cached under the same key, and `~/` names then fail closed until HOME changes.
  **route: code-fact-check**

- **Claim:** My prior report's findings are dispositioned as the rubric says. F1 is named in the lib (`:484-486`), A5 and plan U2b part (a). F2's nested-`.git` arm is gone (`:778`). F3 has the HOME sentence at `:482-483`.
  **Location:** as listed
  **Evidence:** read-static (plus Stage 1's executed skip-any-nested-.git mutant)
  **Verified:** the lines quoted above at 4828727d.
  **Not verified:** F3's sentence sits in main_imports' paragraph and names only IMPORTED_MAIN_DONE as the cache to clear. Stage 1 S2 executed the stale IMPORTED_DONE after a HOME change, so that part of the wording is incomplete. That is a wording item, not a code one; no caller changes HOME (override row 3's premise still holds).

- **Claim:** Each early stop still reaches every caller as a walk failure, and check_fix refuses before `isimported tree` when the walk fails.
  **Location:** `scripts/dev-cycle.sh:181-184`; lib `:683`, `:742`, `:746-747`, `:796-797`
  **Evidence:** read-static (Stage 1 executed the 4 MiB and 200k-name failures)
  **Verified:** each capture is `out="$(...)" || { ...=error; return 1; }` under the walk's own pipefail; `elif ! imported_names` precedes `isimported tree`; isimported maps a failed walk to 0.
  **Not verified:** U2a4's floor caller (not written).

## Primitive sweep

Primitive: path construction from S1 names
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| IMPORT_AWK `put` (`:557-577`) | S1, S2 | lexical normalize, prefix test, `tried` memo | cleared (endorsement 1) |
| imported_names `[[ -f "$p" ... ]] && inrepo_here "$p"` then `head -c 4194305 -- "$f"` (`:690`, `:683`) | S1 | blocker, `--` | cleared; TOCTOU needs host control (prior report) |
| main_imports `.git` skip (`:778`) | S1, S4 | top-level name only | F1 |
| main_imports parent loop and `-d/-e` check (`:781-782`) | S1, S3 | ent modes, blocker | cleared (nested `.git` file now fails; Stage 1 mutant) |
| main_imports symlink arm `realpath -ms` (`:752-759`) | S1 (main blob) | empty/newline/NUL/absolute/`..`-after-link refusals | cleared (unchanged) |
| import_home `realpath -m -- "$h"` (`:621`) | S2 | `/`-prefix test, `--` | cleared |

Primitive: process exec fed data
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `sed "${s[@]}"` (`:630`) | S1 stdin; S6 program | constant program | cleared |
| `awk -v ok="$UTF8_WELL_FORMED"` (`:636`) | S1 stdin | constant | cleared |
| `python3 -I -c ...` (`:637`) | S1 stdin | `-I`, status checked | cleared |
| `awk "$IMPORT_AWK"` via ENVIRON (`:645-646`) | S1, S2, S6 | ENVIRON, no `-v` escapes | cleared |
| `getent passwd "$(id -u)" \| cut` (`:620`) | S2 | none needed | cleared (endorsement 2) |
| `git cat-file blob "$MAIN_SHA:$f"` (`:742`, `:746-747`) | ent names (main) | mode case | cleared (uncapped blob routed to U2a3c, override row) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | Top-level `.git` skip passes a worktree gitfile's import (gitdir path holding ` @name `); main's walk failed closed; prior U2b note not carried | Low | B5 | dev-cycle-read.sh:772-778 | High (executed; host-set path) |
| F2 | `.claude/commands/` `@` names load at invocation (A5's untraced shape, traced); not a start in either walk; pre-existing | Medium | B6 | start sets; A5; lib :478-479 | High mechanism / nil exposure |

## Overall Assessment

I found no fail-open in aa379ee9's parser changes. The `tried` memo and the resolved-path charge changed no output on 1,800 differential runs against e1654266, and the raw-HOME key recomputes on every HOME change, including unset and empty. All of this was executed. My prior findings' fixes hold: the nested `.git` file now fails closed, and the outside-repo starts are named and routed. F3's sentence is incomplete, as Stage 1 S2 says. Both new items are start/skip-set gaps outside the parser contract. F1 is a narrow regression from main that only a host-chosen path can reach, and it has a one-line fix or a U2b carry. F2 converts A5's last untraced shape into a traced, uncovered start kind with no exposure in this repo; it belongs with U2a4's shared start predicate. Neither shows an architectural problem. The most important action is wording: record F2 as traced and uncovered in A5 and the lib header, and choose F1's disposition (fix or carry the dropped U2b note). The endorsements are executed except two read-static ones, each with its next hop named. Within the code paths read, nothing blocks merge once F1 and F2 are dispositioned.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A markdown report saved at the output path named in your role section, structured per your skill, with a `Commit: 4828727d` line at the top.
- **Answered:** fail-opens through aa379ee9: none in the memo, the charge or the HOME key (executed). The top-level-only `.git` skip has one host-reachable miss, which is a regression from main (F1). Fail-closed paths that could become ok: none found; a getent failure stays fail-closed. My prior F1-F3: hold, with F3's wording gap per Stage 1 S2. A5's untraced command-file shape is now traced (F2).
- **Out of scope:** Stage 1's wording items S1-S7 (not redone); the override-log rows (outside-repo starts and reader set to U2b, the main walk's uncapped blob to U2a3c), which no evidence here reopens.
- **Escalate:** F2, for the orchestrator to decide between adding command-file starts here and routing them to U2a4 (my recommendation: route, and fix A5's wording in this unit).
- **Questions I would have asked:** Is a command file's `@` attachment "read as instructions" for --check-fix's contract? It arrives as a Read-tool result inside the invoked command's turn, not as memory.
- **Decisions I made:** I rated F2 Medium under the floor rule (named mechanism, executed) and put its nil exposure in Confidence. I rated F1 Low because only the host sets the gitdir path. I ran the merge-base lib to classify both as regression or pre-existing.
