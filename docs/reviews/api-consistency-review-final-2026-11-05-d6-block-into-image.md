Commit: 48498ba6

# API Consistency Review — refactor/d6-block-into-image (final pass)

**Scope:** `git diff 5b20d4bd..48498ba6 -- . ':!docs/reviews'` (9 files)
**Date:** 2026-11-05
**Based on:** `docs/reviews/code-fact-check-report-final-2026-11-05-d6-block-into-image.md` (k=3, stamped 1c5fd04f; its prose findings were fixed in 48498ba6) and the first pass, `docs/reviews/api-consistency-review-2026-11-05-d6-block-into-image.md` (stamped 4dd68cdc).

**Result:** the contract holds. All five first-pass findings are fixed. No Breaking or Inconsistent finding. Two new low-severity findings, neither a reason to hold the merge: the new lib-load refusal has no release paste in step 0.1, and one test title omits that refusal.

## Baseline Conventions

Unchanged from the first pass, re-read at this commit:

- **Refusals** go to stdout as `refuse <subject>: WHY` with exit 2. Bad usage goes to stderr with exit 1 and no `refuse` prefix.
- **Read failures** say "could not be read" (`scripts/build-loop.sh:728,782,908`).
- **A `GIT_CONFIG_COUNT` that is not plain decimal** is exit 1 in `build-loop.sh` and `dev-cycle.sh`, printed by `git_harden` itself (`scripts/lib/dev-cycle-read.sh:338`).
- **GATE_CODE** has one definition in the lib, and restatements are pinned by a test where one exists.
- **The plan's F and T tables** are amended in place.

## First-Pass Findings, Rechecked

| # | First-pass finding | State at 48498ba6 | How checked |
|---|---|---|---|
| 1 | Lib or `git_harden` failure refused as a default-branch problem | **Fixed.** `scripts/d6.sh:52` tries `( harden )` alone before the loop, so exit 1 in the loop comes from `show-ref` | Probe: `GIT_CONFIG_COUNT=abc` and `=010`, a lib with a syntax error, a lib with no `git_harden`, and an unreadable lib all print the new line, exit 2 |
| 2 | Plan rows F39 and T33 described the removed check and block | **Fixed.** F39 reads "the image's own ownership, not a runtime check"; T33 reads "SKILL.md states the one-line call once" | Read `docs/working/plan-build-loop-handoff.md:167,408` |
| 3 | GATE_CODE restatement missed at plan line 63 | **Fixed.** The brace list now holds `d6` | Read line 63; `git grep` of the brace and list forms finds no other live restatement |
| 4 | "Older than this skill" stale for `refuse d6:` | **Fixed.** Skill lines 217-218 split the sentence; d6.sh's header and T37's title say "a partial image"; the pin at `build-loop-orchestrator.bats:301` matches | Read the sites; test passes |
| 5 | Skill no longer stated exit 1 or where refusals are listed | **Fixed.** Rules line 46-47 state both, and research line 21 now says the Rules state it | Read the sites |

## Name-Pattern Audit

New since the first pass. Rows the first pass audited are unchanged.

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `refuse d6: LIB did not load, or its git_harden refused this environment` | error | `X is missing`, `X is not a regular file`, `refs/heads/$n could not be read` | `scripts/d6.sh:47-48,56` | Consistent shape: subject path first, same prefix, stream and exit. "did not load" has no neighbour; `git grep` over `scripts` and `hooks` finds no other load-failure wording. Two causes in one line: see Finding 1 |
| `harden` | private function | `git_harden`, `g`, `no` | `scripts/d6.sh`, `scripts/lib/dev-cycle-read.sh:335` | Private helper, skipped |

## Contract Checks

**Exits, skill against d6.sh.** Re-run against a stand-in image at 48498ba6 (the shipped file with the `D6_OPT` literal changed).

| Case | Observed | Skill's reading | Match |
|---|---|---|---|
| Script's own failure (`questions.sh open`, fresh repo) | exit 1 with the script's own lines, through `exec` | per mode | yes |
| `GIT_CONFIG_COUNT=abc` or `010` | stderr `d6.sh: GIT_CONFIG_COUNT is not a plain decimal count`, stdout the lib-load line, exit 2 | a stop, stderr filed with it | yes |
| Lib with a syntax error, no `git_harden`, or unreadable | bash's line on stderr, stdout the lib-load line, exit 2 | a stop | yes |
| `GIT_CONFIG_COUNT=1` with no key | stderr `error: missing config key GIT_CONFIG_KEY_0`, stdout `refuse d6: refs/heads/main could not be read`, exit 2 | a stop; git's line names the cause | yes |
| A valid caller pair | `--state` prints `ok`, exit 0 | passes | yes |
| Bad, missing or `--help` first argument | stderr `d6: the first argument is ...`, exit 1, empty stdout | Rules line 46-47: nothing ran | yes |
| Both branches, or `main` a junk file alone | `refuse d6: the default branch is not exactly one of main and master`, exit 2 | a stop; the junk case is what research item 5 states | yes |

**Exit 2 against exit 1 for a bad count.** `build-loop.sh` and `dev-cycle.sh` exit 1 on this input, and d6.sh exits 2 with a `refuse d6:` line. That follows d6.sh's own contract, where every refusal before the script runs is exit 2. The skill treats both as "nothing ran", so no consumer sees a difference.

**The header against the code.** d6.sh's Exit paragraph lists all five refusal families the code has: missing, not regular, lib load, default branch, git read above 1. The skill's pointer ("d6.sh's header lists them") therefore holds. Plan T36 and research item 5 also carry the lib-load refusal.

**Consumers.** No hook, permission rule or test outside `build-loop-orchestrator.bats` names `bash -s` or the `/opt/.../scripts/` path. No live file under `scripts`, `hooks`, `skills`, `workflows`, `guides` or `global-instructions` still says "D6 block" or "D6 snippet". The remaining hits are closed briefs, old research, merge messages and the roadmap's name for this unit.

**Tests and lint.** `shellcheck -x scripts/d6.sh` is clean. `bats --filter 'd6|gate copy|git_harden|skill.s PATHS|GATE_CODE' test/scripts/build-loop-orchestrator.bats`: 15 of 15 pass.

## Findings

#### 1. Step 0.1's release paste does not reach the lib-load refusal, and that line joins two causes with different remedies

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:217-218`, `scripts/d6.sh:52`
**Move:** #4 (error consistency), #3 (contract)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**

```
   exit is a stop as the Rules say (the exit 127 above means an image older than this
   skill, and a `refuse d6:` naming a missing image file a partial image: wherever either is filed, it also gives the release paste below).
```

```bash
( harden ) || no "$D6_OPT/scripts/lib/dev-cycle-read.sh did not load, or its git_harden refused this environment"
```

The skill offers the paste only for a `refuse d6:` "naming a missing image file". Two image defects fall outside that wording: `X is not a regular file`, which d6.sh's header also calls "a partial image", and the "did not load" half of the new line. Both need the same rebuild, and neither entry would carry the paste.

The new line also covers a cause the paste would not cure: a bad `GIT_CONFIG_COUNT` in the caller's shell, whose remedy is to fix that variable. So widening the skill's wording to "an image file" would send that case to a rebuild.

Impact is small. Every case is still a correct stop, and the Rules file stderr with the line, which separated the causes in every probe (`GIT_CONFIG_COUNT is not a plain decimal count` against bash's own message). Reachability is low too: a damaged image or a bad exported count. The cost is an owner entry with no remedy in it. This wording is new with the refusal, so the first pass could not have raised it.

**Recommendation:** Not needed for this merge. If taken, split the refusal so each line has one cause: `( source "$lib" ) || no "$lib did not load"`, then the combined call with `no "git_harden refused this environment"`. Then widen step 0.1 to "a `refuse d6:` naming an image file" and update the pin at `build-loop-orchestrator.bats:301`. Both files are GATE_CODE, so this costs a release whenever it lands.

#### 2. The refusal test's title and the research test plan omit the lib-load case

**Severity:** Informational
**Location:** `test/scripts/build-loop-orchestrator.bats:332`, `docs/working/research-2026-11-05-d6-block-into-image.md:109`
**Move:** #3 (test drift)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**

```
@test "d6.sh refuses before running anything: not exactly one of main and master, a repository git cannot read, an image file missing or not a regular file, another first argument (T36, U3b3, brief 2026-11-05-d6-block-into-image)" {
```

```
Each refusal and the pass path in `build-loop-orchestrator.bats`, against the shipped file with D6_OPT changed: both or neither default branch, a non-repository, missing and non-regular files (a directory and a dangling link), a bad first argument; the 127 path through the skill's own call line; the variable scrub and closed stdin; hardening through the T26 shim; the dropped checks pinned as passing, and `--state` still refusing the two default-branch shapes.
```

The test body does cover the refusal (lines 344-347), and plan row T36 names it, so nothing is untested. The title reads as a complete list and is one family short of d6.sh's header, which matters only to someone mapping refusals to tests by title.

**Recommendation:** Add "an image lib that does not load" to the title with the next edit to this file. No separate change is warranted.

## What Looks Good

- **The fix for first-pass Finding 1 is the one recommended,** and it keeps the `refuse d6:` shape: exit 2, one stdout line, nothing run.
- **The lib-load refusal is complete across its sites:** header, research item 5, plan T36 and the test agree. Both causes are tested, the `return 1` lib and `GIT_CONFIG_COUNT=010`.
- **The refusal runs after the file checks,** so a missing lib still reads `is missing`, not "did not load".
- **The skill's Rules now carry all three non-script outcomes** (`refuse d6:`, the exit 1 usage line, exit 127) in one place, and the header is a reliable index for the first.
- **`git_harden`'s own stderr line prefixes `d6.sh:`** through `${0##*/}`, so the owner sees which script refused.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Release paste misses the lib-load refusal, which joins two causes | Minor | `skills/dev-cycle/SKILL.md:217-218`, `scripts/d6.sh:52` | High |
| 2 | Test title and research test plan omit the lib-load case | Informational | `test/scripts/build-loop-orchestrator.bats:332` | High |

## Overall Assessment

The change is consistent with the codebase's patterns, and existing consumers keep working. The skill's contract with d6.sh matches on every exit I ran, including the new refusal. Finding 1 affects only what an owner entry suggests after a correct stop, in a state that needs a damaged image or a bad exported variable. Finding 2 is a label. Neither needs to hold the merge. Finding 1 touches two GATE_CODE files, so taking it costs a further review round now or a small follow-up later.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to docs/reviews/api-consistency-review-final-2026-11-05-d6-block-into-image.md, first line `Commit: 48498ba6`, each finding with Severity, Location, verbatim Evidence, Confidence and Legibility-target, ending with a Goal-Alignment Note (patterns/orchestrated-review.md). Edit nothing else; do not commit.
- Answered: yes — the five first-pass findings checked as fixed, then the new lib-load refusal and the rest of the surface re-checked, with probes against the shipped file.
- Out of scope: security of the dropped checks and of the release window in research item 3 (S1, the security review); a lib that exits 0 at top level, which a probe showed reads as a default-branch refusal, because the lib only defines names and no real image reaches it; historical docs that mention the block.
- Escalate: nothing.
- Decisions I made: Rated Finding 1 Minor rather than Informational, matching how the first pass rated its Finding 4 (a wrong diagnosis in an owner entry); the other reading is that a correct stop with stderr filed is enough. Did not run the full test gate, only the d6 filter, since this review is of the contract and the gate belongs to the merge.
