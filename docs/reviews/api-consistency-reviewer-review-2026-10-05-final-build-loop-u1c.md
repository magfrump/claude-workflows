Commit: 4dc84ce4

# API Consistency Review — feat/build-loop-u1c (U1c), final confirming pass (iteration 3)

**Scope:** `git diff main...feat/build-loop-u1c` at 4dc84ce4. The public surface under review is `scripts/build-loop.sh`'s help (`:1-80`), the `--settings` constraints line and the `--status` line formats.
**Date:** 2026-10-05
**Based on:** the Stage-1 merged fact-check (docs/reviews/code-fact-check-report-build-loop-u1c.md), plan rev 4 (docs/working/plan-build-loop-handoff.md `:204-205`, D2, F31, F55, T44), the iteration-2 rubric (A13, A16, A17, C23), and the override-log rows dated 2026-10-05.

## Baseline Conventions

These are unchanged from iteration 2 and re-checked at HEAD.

- **Read-mode output.** Each argument gets one line, either `ok <arg> FIELDS...` or `skip <arg>: <reason>`, in argument order. A run exits 0 when every argument is answered, and bad usage exits 1. Sources: `scripts/dev-cycle.sh:22-71`, `:106-109`; plan `:205`.
- **Settings lines.** Each line is `KEY ... STATUS: WHY`, and the status words are fixed by plan `:204`.
- **WHY prose pluralisation.** dev-cycle.sh writes `merge(s)`, `commit(s)`, `file(s)`, `item(s)` and `day(s)` (`scripts/dev-cycle.sh:259,400,433,449`).
- **Usage errors.** dev-cycle.sh prints `<mode> needs at least one argument` and exits 1. build-loop.sh adds its own `(usage: ...)` suffix, set in U1b.

## Name-Pattern Audit

4dc84ce4 adds no new public name: no new mode, field, status word or skip reason. These rows re-check the names whose wording changed.

| New / changed name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `constraints none-hard: ... has N soft constraint(s) ...` | WHY prose | `merge(s)`, `commit(s)`, `file(s)` | `scripts/dev-cycle.sh:259,400` | Consistent. C23 is fixed in the house style. Probe output: `has 0 soft constraint(s)`, `has 1 soft constraint(s)`, `has 2 soft constraint(s)`. |
| `constraints ok N-hard M-soft\|missing\|none-hard\|unreadable` | output line | plan `:204` | `scripts/build-loop.sh:29`, plan `:204` | Consistent. Unchanged since iteration 2 and matches the plan. |
| `ok BRIEF STATE POLICY BRANCH LOOP SHA DATE DISPATCHED [REASON]` / `skip BRIEF: WHY` | output line | `--check-brief`, `--check-branch` lines | `scripts/dev-cycle.sh:29-49`, plan `:205` | Consistent. Unchanged. |
| `--status needs at least one brief path` | usage error | `--check-brief needs at least one argument` | `scripts/dev-cycle.sh:109` | Consistent in shape and exit code (probe: both exit 1). "brief path" is more specific than "argument", which is fine. |

## Iteration-2 wording fixes, checked against the code

- **A13 (constraints help) holds.** The help now reads `constraint or "#" heading; no ID repeats; fences are skipped.` and `... (after marks and a task box) but not exact makes the file unreadable (best effort).` (`:35-38`). These clauses match the code: `fence($0) { next }` (`:167`), the task-box strip `sub(/^([^a-zA-Z]|\[[ xX]\])*/, "", s)` (`:175`) and the column-0 `/^#/` (`:177`). I probed four shapes, and each printed `constraints unreadable: line 3 looks like a constraint ...`: `- [x] H2: x`, `- [X] h2: x`, `1) H2 x` and `* [ ] S2: y`. A12's fix works as the help describes it.
- **A17 (F31 skip clause) holds.** The help now reads `for an open brief, another open brief on main (in briefs/ or closed/) names the same branch (ignoring case)` (`:68-69`). That matches `if [[ "$st" == open && "$SHARED_BRANCHES" == *$'\n'"$(lower "$br")"$'\n'* ]]` (`:333`).
- **A16 (marker help) is half fixed.** The second-line clause and the "does not start handoff:" wording are fixed. The 0-ahead half is not; see F1.
- **C23 holds.** See the audit row above.

## Findings

#### F1. The skip clause still predicts a skip for a 0-ahead tip whose subject starts "handoff:". The code prints `working`, and no LOOP sentence covers that case

**Severity:** Minor
**Location:** `scripts/build-loop.sh:55-62` and `:69-71` (help), `:342-343` (code)
**Move:** 3 (consumer contract, documentation drift)
**Confidence:** High
**Legibility-target:** for-author

Evidence (help, verbatim):
```
#                 absent). A tip is a marker only when the branch is at least
#                 one commit ahead of main and the tip is an empty commit with
...
#                 printed last. A tip whose subject does not start "handoff:" is
#                 working. DISPATCHED: the brief's "Dispatched: N" (0-99), or
...
#                 closed/) names the same branch (ignoring case), or the tip's subject (its
#                 message's first line) starts "handoff:" but it is not a
#                 marker.
```
Code (`:342-343`; excerpt ends at :343, and the enclosing `status_line` continues to :351, which I read):
```
  loop=working
  if [[ "$ahead" -gt 0 ]]; then
```
Probe (scratch repo; main's tip is `handoff: ready`, then `handoff: garbage`, and `feat/a` points at main, so it is 0 commits ahead):
```
ok docs/working/briefs/2026-10-01-a.md open review feat/a working edbb9feb81d0b95a4dc453f2a2627d3d49a82bdd 2026-10-05 0
ok docs/working/briefs/2026-10-01-a.md open review feat/a working 644d3eab03a26a4687e7ca5851236b80ae6f1cc0 2026-10-05 0
```

The help defines this tip as not a marker, because the branch is not at least one commit ahead. Its subject starts `handoff:`. Read literally, the skip clause therefore says "skip". The only working rule now covers a subject that does *not* start `handoff:`, so no sentence predicts the `working` the code prints. T7 asserts `working` (`test/scripts/build-loop-read.bats:295`, "A marker at main's tip with the branch 0 commits ahead is main's, not the loop's"). The behaviour is right and intended. Only the help is out of step, and U4's skill will map LOOP and skip lines to actions from this text.

The rubric's A16 named this half explicitly ("the skip clause omits that it applies only when the branch is at least one commit ahead"). The 4dc84ce4 rewording narrowed "Any other tip is working" and left this case with no rule at all. The 4dc84ce4 commit message lists A16 as fixed.

**Recommendation:** Add one clause to the skip text: "or, on a branch at least one commit ahead, the tip's subject ... starts "handoff:" but it is not a marker". Optionally add to the LOOP text: "a branch 0 commits ahead is working". The change is wording only, and T7 already pins the behaviour.

#### F2. The runtime nosuccess WHY says "heading" where the help now says a "#" heading

**Severity:** Informational
**Location:** `scripts/build-loop.sh:266` (WHY), `:35` (help)
**Move:** 4 (message consistency)
**Confidence:** High
**Legibility-target:** for-author

Evidence:
```
      nosuccess) CONSTRAINTS_LINE="constraints unreadable: hard constraint $c (line $l1) has no success: line before the next constraint or heading" ;;
```
```
#                 constraint or "#" heading; no ID repeats; fences are skipped.
```

A13 tightened the help, but the message a user sees when the check fires still says "heading". That user is a human reading the `you: judgment` entry filed from this line, who may have written a Setext heading. The message is WHY prose, not a parsed field, so this stays at the floor.

**Recommendation:** Optional: change the message to `before the next constraint or "#" heading`. If you change it, the two T44 assertions that quote this message need the same edit.

## Convergence notes (not filed as findings)

- **F31 fails open under forced colour.** This is fact-check Claim 20b, already escalated to security and to the orchestrator. Legibility-target: for-orchestrator-synthesis. I reproduced it from the contract side. With two open briefs on `feat/x`, the default config prints `skip ...: another open brief on the default branch names the same branch (compared ignoring case)`. After `git config color.grep always` the same brief prints `ok docs/working/briefs/2026-10-01-a.md open review feat/x absent - - 0`. The help's skip clause (`:68-69`, which A17 now words correctly) does not hold under that repo config. The comment at `:304-305` ("a superset") is the claim that fails. I am not filing it a second time. The API consequence is that `--status`'s documented contract depends on the caller's git config, unlike every other field. The fix is `--no-color` plus an error for exit status above 1, which the fact-check gives.
- **`- [x ] H2:` (space inside the box) still reads `constraints ok 1-hard 0-soft`.** I confirmed this by probe. The fact-check routed it to the orchestrator, to be placed against override row 290's prefix residue. The help's "after marks and a task box" plus "(best effort)" matches row 290's settled scope, so I am not re-filing it.
- **Override rows checked.** Rows 270 (no machine CONSTRAINTS value), 271 (where the copy paragraph sits), 272 (STATE `new` for a closed/ brief) and 245 (never-line status word) still hold on unchanged premises. The help line at `:69` is 91 columns wide. dev-cycle.sh's help has lines as long (`scripts/dev-cycle.sh:19`, 98 columns), so this is not filed.

## What Looks Good

- C23's `constraint(s)` matches dev-cycle.sh's `(s)` convention exactly. `route: code-fact-check` (`scripts/build-loop.sh:265`, `scripts/dev-cycle.sh:259`)
- A13's help now states the grammar the code enforces: fences skipped, a `#` heading, task boxes stripped, best effort. Each clause matched a probe.
- A17's "for an open brief" matches the `st == open` gate. `route: code-fact-check` (`scripts/build-loop.sh:68-69`, `:333`)
- 4dc84ce4 changes no output format. The `--settings` four-line order, the `--status` field order and every skip reason are byte-identical to c143b929, apart from the C23 prose. U2–U4 parsers written against iteration 2's contract are unaffected. `route: code-fact-check` (`git diff c143b929 4dc84ce4 -- scripts/build-loop.sh`)
- Usage errors match dev-cycle.sh's shape and exit 1.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | The skip clause predicts a skip for a 0-ahead `handoff:` tip, which the code reads as `working`; A16's second half is not fixed | Minor | `scripts/build-loop.sh:55-62`, `:69-71`, `:342-343` | High |
| 2 | The nosuccess WHY says "heading"; the help now says "#" heading | Informational | `scripts/build-loop.sh:266` | High |

## Overall Assessment

The `--settings` and `--status` contracts are consistent with plan rev 4 and with dev-cycle.sh's check modes, and 4dc84ce4 changes no parsed format. The A13, A17 and C23 fixes hold against the code and against probes. A16 is half done. The help still gives no rule for, and contradicts the code on, a 0-ahead tip whose subject starts `handoff:`. That is a one-clause wording fix (F1, Minor). The fail-closed behaviour is correct and tested. The only contract-level defect at HEAD is the F31 colour fail-open, which is already escalated through the fact-check. From the API side it makes the documented skip clause depend on the caller's git config.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved at the output path your task names, structured per your skill, with a `Commit: 4dc84ce4` first line.
- Answered: yes. A13, A16, A17 and C23 are checked against the code with probes. One Minor and one Informational finding.
- Out of scope: the exploitability and tiering of the F31 colour fail-open (security-reviewer and the orchestrator), and the `- [x ]` residue's placement against row 290 (orchestrator). Both were confirmed by probe and noted, not filed.
- Escalate: F31 colour fail-open (fact-check 20b). From the API side, the `--status` skip contract does not hold under `color.grep=always`. It needs a tier from the orchestrator.
- Decisions I made: I did not re-file A16's whitespace-second-line half, which is fixed. I filed the 0-ahead half as F1 because 4dc84ce4's message claims A16 fixed and the help still contradicts T7.
