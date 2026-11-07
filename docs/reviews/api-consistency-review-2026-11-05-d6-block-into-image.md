Commit: 4dd68cdc

# API Consistency Review — refactor/d6-block-into-image

**Scope:** `git diff 5b20d4bd..HEAD -- . ':!docs/reviews'` at 4dd68cdc (9 files)
**Date:** 2026-11-05
**Based on:** `docs/reviews/code-fact-check-report-2026-11-05-d6-block-into-image.md`, stamped 9f80368a, one commit before this HEAD. Its claims 22a, 26b, 28b and 37 were addressed or reworded by 4dd68cdc; the d6.sh behaviour below was re-run at 4dd68cdc.

**Result:** the contract holds. No Breaking finding. Every exit the skill reads matches d6.sh, nothing consumes the removed refusal wordings, and exit 127 conflicts with no mode. Five low-severity findings: one refusal that names the wrong cause, three doc restatements left behind, and one exit no longer stated in the skill.

## Baseline Conventions

- **Script names** in `scripts/` are descriptive kebab-case: `build-loop.sh`, `dev-cycle.sh`, `health-check.sh`, `confine-tests.sh`.
- **Refusals** go to stdout as `refuse <subject>: WHY` with exit 2 (`refuse state default-branch: ...`, `refuse main-log: ...`). Bad usage goes to stderr with exit 1 and no `refuse` prefix.
- **A `GIT_CONFIG_COUNT` that is not plain decimal** is exit 1 "bad usage" in both neighbours (`scripts/build-loop.sh:558`, `scripts/dev-cycle.sh:85`).
- **GATE_CODE** has one definition in the lib; restatements in prose are pinned by a test where one exists.
- **The plan** keeps superseded text and adds dated amendment bullets, but its F and T tables are updated in place. This diff updated F38, T36 and T37 that way.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `scripts/d6.sh` | script | `build-loop.sh`, `dev-cycle.sh`, `questions.sh` | `scripts/*.sh` | Departs from descriptive kebab names, but matches its own `refuse d6:` prefix and the plan's D6 term. No action: the prefix is the contract |
| `d6:` usage line on stderr, exit 1 | error | `--main-log takes one full 40- or 64-hex commit id` | `scripts/build-loop.sh`, moved unchanged from the block | Consistent |
| `refuse d6: refs/heads/$n could not be read` | error | `refs/replace could not be listed`, `the grafts path could not be read` | old block in `skills/dev-cycle/SKILL.md` at 5b20d4bd | Consistent wording |
| `D6_OPT`, `no`, `g` | private | same names in the old block | old block at 5b20d4bd | Moved unchanged |
| `s`, `x`, `f`, `n`, `rc`, `have` | private locals | n/a | n/a | Skipped as private |
| "through d6" (skill prose) | term | "through the D6 block" | `skills/dev-cycle/SKILL.md` at 5b20d4bd | Consistent; replaced at every site, and the test forbids "D6 block" |

## Contract Checks

**Exits, skill against d6.sh.** Re-run against a stand-in image at 4dd68cdc.

| Case | Observed | Skill's reading | Match |
|---|---|---|---|
| Pass | script's own status, through `exec` | per mode | yes |
| Refusal | stdout `refuse d6: WHY`, exit 2 | Rules: nothing ran, a stop | yes |
| No d6.sh | stderr `bash: PATH/d6.sh: No such file or directory`, empty stdout, exit 127 | Rules: same refusal, a stop | yes |
| Bad or missing first argument | stderr `d6: the first argument is ...`, exit 1 | not stated; see Finding 5 | n/a |
| Not a repository | stderr `fatal: not a git repository ...`, then `refuse d6: refs/heads/main could not be read`, exit 2 | a stop | yes |

"First line" means stdout's first line. On a failed read git's stderr line comes first in merged output. The old block did the same, and d6.sh's header says so.

**Refusal wording, old block to d6.sh.**

| Wording | Status |
|---|---|
| `X is missing`, `X is not a regular file`, `the default branch is not exactly one of main and master` | kept |
| `a replace ref exists (F38)`, `info/grafts exists (F38)`, `refs/replace could not be listed`, `the grafts path could not be read` | removed (R6c) |
| `refs/heads/$m is a symbolic ref`, `refs/heads/$m names no commit` | removed (R6d); `--state` keeps its own lines |
| `X is not root-owned, a plain path and unwritable here` | removed (R6e); a symlink now reads `not a regular file` |
| `refs/heads/$n could not be read` | new |

Refusal order changed too: the image checks now run before the git reads.

**Consumers of `refuse d6:`.** `git grep` over the tree finds no script or hook that parses it. The consumers are the skill (lines 46, 53, 216, 357) and the bats tests. The only WHY text the skill keys on is "a missing image file", and that wording is kept. No live entry in `docs/working/questions.md` quotes a removed line, so step 0.1's "unless an open one quotes the same lines" is unaffected.

**Exit 127 against documented exits.** No conflict.

- No file in `scripts/` documents 127; the only hits in `scripts`, `skills` and `hooks` are this change's own lines.
- A script's internal 127 (command not found) carries a different stderr line. The Rules key on the `No such file or directory` line naming d6.sh, and the later shorthands ("that exit 127", "its exit 127", "the exit 127 above") refer back to it.
- For `build-loop.sh`, any such exit already falls under "any other exit ... means nothing was decided".
- Line 174 (a check exiting non-zero stops the step) and line 315 (digest failure) agree with the Rules' stop.
- Line 254's "Any other exit ... None of these stops the iteration" belongs to the plain `git diff --quiet`, not a d6 call.
- Line 356's "If either fails ... go on" carries the carve-out. The migration remedy's "failing" at lines 392-394 has none, as it had none for `refuse d6:` before; the Rules' general sentence covers it, and step 0.1 stops first.

**GATE_CODE restatements.**

| Site | State |
|---|---|
| `scripts/lib/dev-cycle-read.sh:1034` | updated, the definition |
| `skills/dev-cycle/SKILL.md:229` (PATHS) | updated, test-pinned |
| `skills/dev-cycle/SKILL.md:617` (slug rule) | updated, test-pinned |
| `scripts/build-loop.sh:453` (header) | updated |
| `docs/working/plan-build-loop-handoff.md:73` | updated |
| `test/scripts/build-loop-check.bats` floor list | updated |
| `docs/working/plan-build-loop-handoff.md:63` | **not updated** (Finding 3) |

Other live uses read the variable (`build-loop.sh:1485, 2117, 2215`; lib `:1066`), so they follow it. `hooks/live-verify-gate.sh`'s enforcement set is `devcontainer-config/` only, so d6.sh does not belong there, and no permission rule in `hooks/wiring.json` names either call form.

## Findings

#### 1. A lib or `git_harden` failure refuses with the wrong cause

**Severity:** Minor
**Location:** `scripts/d6.sh:36`, `scripts/d6.sh:50-52`
**Move:** #4 (error consistency)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**

```bash
# scripts/d6.sh:36
g() { ( source "$D6_OPT/scripts/lib/dev-cycle-read.sh" && git_harden && git "$@" ); }
# scripts/d6.sh:50-52
  rc=0; g show-ref --verify -q "refs/heads/$n" || rc=$?
  [[ "$rc" -le 1 ]] || no "refs/heads/$n could not be read"
  [[ "$rc" -ne 0 ]] || have+="$n "
```

Probe at 4dd68cdc, with `GIT_CONFIG_COUNT=abc`:

```
d6.bash: GIT_CONFIG_COUNT is not a plain decimal count
d6.bash: GIT_CONFIG_COUNT is not a plain decimal count
refuse d6: the default branch is not exactly one of main and master
rc=2
```

With a lib whose last line is `return 1`, the same refusal printed and stderr was empty.

Status 1 from `g` has three possible sources: `show-ref` saying "absent", `source` failing, and `git_harden`'s `exit 1`. d6.sh treats all three as "absent". The refusal then reports a default-branch problem in a repository whose default branch is fine, and the skill quotes that line in the stop. Neighbours call the same `GIT_CONFIG_COUNT` input exit 1 bad usage (`scripts/build-loop.sh:558`, `scripts/dev-cycle.sh:85`). The old block's first failed git read printed `refs/replace could not be listed`, which at least named a read. H2 asks a refusal to name the gap. Pre-mortem item 5 in the research doc accepts this ("the line can name the wrong cause"), and fact-check claim 22a measured it, so this is a known residual, but d6.sh's header still lists only "a git read that fails". Reachability is low: a bad exported count, or a damaged image lib.

**Recommendation:** Harden once before the loop, separately from the read: `( source "$lib" && git_harden ) || no "the image lib could not be sourced"`. Then rc 1 in the loop can only mean absent. If the residual stays, add it to the header's Exit paragraph.

#### 2. Plan rows F39 and T33 still describe the removed check and block

**Severity:** Minor
**Location:** `docs/working/plan-build-loop-handoff.md:167`, `docs/working/plan-build-loop-handoff.md:408`
**Move:** #3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**

```
| F39 | D6 copy choice by file existence; the installed copy reached through the uid-writable `~/.claude/scripts` | covered | `/opt/...` by absolute path with an ownership check, in every repository (Q-140 [1]; the root-commit choice is gone) (T37) |
```

```
| T33 | The D6 snippet (as built, U4c): runs the image copy's four files (build-loop.sh and dev-cycle.sh with their own lib, dev-cycle.sh with its own `questions.sh`); main's and the working tree's copies have no effect; SKILL.md holds the block once (its one copy) | as listed | integration |
```

F39 marks "covered" on the strength of an ownership check this diff removes, and it cites T37, whose uid-owned case this diff also removes. T33 says SKILL.md holds the block once, while the T33 test now asserts there is no block. The diff amended the neighbouring rows F38, T36 and T37 in place, so these two read as current when they are not. Line 88's amendment does state the drop, so the plan is not silent, but a reader of the F table gets the old guarantee. The fact-check did not cover these rows.

**Recommendation:** Amend both in place as F38 was. F39: absolute path with the root a literal, ownership held by the Dockerfile's chown and chmod (amended 2026-11-05, D6). T33: SKILL.md states the one-line call once.

#### 3. One GATE_CODE restatement was missed

**Severity:** Minor
**Location:** `docs/working/plan-build-loop-handoff.md:63`
**Move:** #3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**

```
    - A change to the gate's own files (`scripts/{build-loop,dev-cycle,questions}.sh`, `scripts/lib/`, `skills/dev-cycle/`) gets its own slug, `merge-gate-…`. Plain `--approved` refuses such a change (F52).
```

The research doc's restatement list ("What exists") omits this line and fact-check claim 33 did not reach it, while line 73 of the same plan was updated. It presents itself as the full list and lacks `d6`. Nothing executes it and no test pins it, so a `merge-gate-` decision still reads the lib.

**Recommendation:** Add `d6` to the brace list.

#### 4. "A missing image file means an image older than this skill" no longer holds for `refuse d6:`

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:216-217`, `scripts/d6.sh:20-21`, `test/scripts/build-loop-orchestrator.bats:395`
**Move:** #3 (contract), #4 (error consistency)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence:**

```
   exit is a stop as the Rules say (a `refuse d6:` naming a missing image file, or the
   exit 127 above, means an image older than this skill: its entry also gives the release paste below).
```

```
# nothing run, for an image-copy file that is missing (an image older than the
# skill) or not a regular file, a default branch that is not exactly one of main
```

This was true while the check sat in a skill that could outrun the image. Now the check ships in the image: an image that can print `refuse d6: ... is missing` holds d6.sh, and d6.sh's file list comes from the same commit as the files it lists. Every listed file predates d6.sh, and a missing payload item is fatal at install (FP-158). So this refusal now means a damaged or partial image, which is how the research doc's R6e row describes it ("the stale or partial image"). "Older than this skill" is true only of the exit 127 half of the sentence. The remedy, a rebuild through the release paste, still fits, so the impact is a wrong diagnosis in the owner's entry, not a wrong action. Confidence is Medium because a hand-altered image is outside what I could test.

**Recommendation:** Split the sentence: exit 127 means an image older than this skill, and a `refuse d6:` naming a missing file means a damaged image, with the same paste. Change d6.sh's header and T37's title to match, and update the phrase pinned at `build-loop-orchestrator.bats:300`.

#### 5. The skill no longer states d6's exit 1, or says where refusals are listed

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:36-54`, `docs/working/research-2026-11-05-d6-block-into-image.md:21`
**Move:** #3 (contract)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**

```
- The skill's Rules key on a `refuse d6: WHY` first line with exit 2, and on exit 1 for a bad first argument [observed: SKILL Rules, step 0.1, step 1b].
```

The old skill stated this in the block's header ("1 for another first argument") and pointed to it ("the block's header lists every refusal"). Both went with the block, and the Rules' "(1 included)" covers `build-loop.sh` only. So the research doc's invariant overstates the skill as it now reads. Impact is small: the call line says "SCRIPT being one of those three names", and the stderr message explains itself. A mistyped `questions.sh` slot at step 1b would read as "fails, go on", which is also what the old text gave.

**Recommendation:** No code change needed. Either add a clause to the Rules ("exit 1 with a `d6:` line on stderr: a bad first argument, nothing ran"), or correct the research line to say the contract now lives in d6.sh's header.

## What Looks Good

- **The refusal contract survives the move:** same prefix, same stream, same exit, and the kept wordings are byte-identical.
- **The 127 case is deliberate.** The Rules read it at all three sites that treat `refuse d6:`, and a test runs the skill's own call line and pins the phrases.
- **`exec` replaces `env ...; exit "$?"`,** so "the script's own status" holds by construction, and the scrub and closed stdin are pinned by a new test.
- **Hardening has one source.** The repeated `G=` list and its "may stay" allowance are gone, and the subshell keeps pairs out of the script's environment (S3).
- **Release order is symmetric.** A pasted old block works on a new image, since the four files stay; a new skill on an old image stops.
- **`GATE_CODE`, both skill copies and the floor list moved together,** and `d6|` sorts where the test literal expects it.
- **`shellcheck -x scripts/d6.sh`** is clean.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Lib or `git_harden` failure refuses with the wrong cause | Minor | `scripts/d6.sh:36,50-52` | High |
| 2 | Plan rows F39 and T33 describe the removed check and block | Minor | `docs/working/plan-build-loop-handoff.md:167,408` | High |
| 3 | GATE_CODE restatement missed | Minor | `docs/working/plan-build-loop-handoff.md:63` | High |
| 4 | "Older image" reading stale for `refuse d6:` | Minor | `skills/dev-cycle/SKILL.md:216-217` | Medium |
| 5 | Skill no longer states exit 1 or a refusal list | Informational | `skills/dev-cycle/SKILL.md:36-54` | High |

## Overall Assessment

The change is consistent with the codebase's patterns and honours the contract the skill depends on: existing consumers keep working, and the only wording they key on is unchanged. The findings are fixable in place. Findings 2, 3 and 5 are text edits, finding 4 is a text edit plus one pinned phrase, and finding 1 is a small code change or a header sentence. None needs to hold the merge on consumer-impact grounds. Findings 1 and 4 touch GATE_CODE files, so they cost little now and a release later.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to docs/reviews/api-consistency-review-2026-11-05-d6-block-into-image.md, first line `Commit: <HEAD short sha>`, each finding carrying Severity, Location, verbatim Evidence, Confidence and Legibility-target, ending with a Goal-Alignment Note (patterns/orchestrated-review.md). Edit nothing else; do not commit.
- Answered: yes — Rules against exits and messages, refusal wording, `refuse d6:` consumers, GATE_CODE restatements and exit 127 all checked.
- Out of scope: security of the dropped checks (S1 and the owner question in the research doc); historical docs that mention the block (merge messages, closed briefs, cycle records, archive).
- Escalate: nothing.
- Decisions I made: Rated finding 1 Minor rather than Inconsistent, because the author's pre-mortem accepts it and reachability is low; the other reading is that it breaks H2's "names the gap". Treated the plan's F and T tables as live contract rather than history, because this diff edits rows in them.
