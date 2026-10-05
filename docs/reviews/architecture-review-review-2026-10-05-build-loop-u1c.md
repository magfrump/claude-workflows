Commit: 553a50d5

# Architecture Review — feat/build-loop-u1c (constraints line and --status)

**Scope:** `git diff feat/build-loop-u1b...feat/build-loop-u1c` (859e29e8, aaae80c6, 553a50d5): `scripts/build-loop.sh`, `test/lib/build-loop-fixtures.bash`, `test/scripts/build-loop-read.bats`; `scripts/lib/dev-cycle-read.sh` read as context only
**Date:** 2026-10-05
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u1c.md` (Commit 553a50d5); `docs/reviews/override-log.md` rows dated 2026-10-05

**Scope check:** in scope. The unit adds a public mode (`--status`) and two output contracts (the `constraints` line, the `ok|skip` status line) that U2's `--check`, U3's `--start` and U4's skill will consume. It also adds script-local parsers (`CONSTRAINTS_AWK`, `marker_kind`, `shared_branches`) next to the shared lib. The test and fixture files are reviewed only where they define the contract.

**Trust-boundary cross-reference:** not run. `ls docs/reviews/security-review-*.md` matches nothing; the security reviews are named `security-reviewer-review-*.md`. That naming gap is settled (override-log row "architecture-review's security glob ... misses", deferred to the next edit of skills/architecture-review).

## Dependency Map

- `scripts/build-loop.sh` sources `scripts/lib/dev-cycle-read.sh` from its own directory. It calls `main_entry`, `brief_fields`, `check_brief`, `check_branch`, `isbrief`, `lower`, `FENCE_AWK`, `oddwhy`, `MAIN_SHA` and `resolve_main`/`main_by_name`. Dependencies point one way, script → lib. The lib does not know about build-loop.sh except in its header comment.
- Inside build-loop.sh this unit adds a two-stage pipeline:
  1. Load main's state into globals: `read_settings` sets POLICY, NEVER and the `*_LINE` strings, now including CONSTRAINTS_LINE. `shared_branches` sets SHARED_BRANCHES.
  2. Judge each brief: `status_line` → `check_brief` (lib) → `brief_fields` (lib) → `check_branch` (lib) → `marker_kind` (script).
- U2's `--check`, U3's `--start` and U3b's `--marker` are planned to live in the same script (plan "Script interface", `docs/working/plan-build-loop-handoff.md:201-216`). So the script-local helpers will be reused within one file. They do not cross into the lib.
- `dev-cycle.sh` is the lib's other caller. Nothing in this unit touches it, and it needs neither markers nor the shared-branch rule.

## Findings

#### 1. F31's shared-branch set fails open when a mode does not compute it first

**Severity:** Coupling
**Location:** `scripts/build-loop.sh:283`, `:312`, `:335`
**Move:** 7 (coupling surface: temporal coupling through globals)
**Confidence:** High
**Legibility-target:** U2's author adding `--check`, which plan F31 says must also skip both briefs

**Evidence:**
```
283	SHARED_BRANCHES=""
```
```
312	  if [[ "$st" == open && "$SHARED_BRANCHES" == *$'\n'"$(lower "$br")"$'\n'* ]]; then
```
```
335	    read_settings; shared_branches
```
(`status_line` runs from `:296` to `:331`, all read.)

`status_line` judges F31 from a global that only `shared_branches` fills. The global's initial value `""` can never match the `*$'\n'NAME$'\n'*` pattern, so a mode that calls `status_line` (or copies its check) without first calling `shared_branches` passes every brief silently. POLICY has the opposite default: its fallback is `review`, which fails closed. Plan row F31 (`plan-build-loop-handoff.md:146`) assigns the same rule to U2's `--check`, which is a second caller that must remember the same call order. If that caller forgets, F31 is unenforced and no test fails unless T28 is copied to the gate suite.

**Recommendation:** Make the unset state fail closed. Either `status_line` refuses (or calls `shared_branches` itself) when SHARED_BRANCHES is still `""`, or one `load_main_state` function runs `read_settings` and `shared_branches` together for every mode that judges a brief. The `$'\n'`-framed format was already in place. This change is about the default value and the call order, not the format.

#### 2. Two definitions of "the briefs on main": F31 counts only `briefs/`, while --status accepts `briefs/closed/`

**Severity:** Minor
**Location:** `scripts/build-loop.sh:289`; `scripts/lib/dev-cycle-read.sh:324`
**Move:** 3 (module boundary) / 2 (responsibility)
**Confidence:** High (reproduced)
**Legibility-target:** U2's gate author; the U5 docs author

**Evidence:**
```
289	    if ! isbrief "$f" || [[ "$(main_entry "$f")" != blob ]] || ! brief_fields "$f"; then continue; fi
```
```
324	  if ! isbrief "$a" && [[ ! "$a" =~ ^docs/working/briefs/closed/$DIGIT{4}-$DIGIT{2}-$DIGIT{2}-$SLUG\.md$ ]]; then
```
`shared_branches` runs from `:284` to `:295`, all read; `check_brief` continues to `:357` and was read. The closed/ regex also appears in `writable()` at `scripts/lib/dev-cycle-read.sh:161`.

The lib has no single predicate for "a brief path". `isbrief` covers only `briefs/`, and the `closed/` form is spelled out inline twice (`:161`, `:324`). `shared_branches` chose `isbrief` and lists only `docs/working/briefs/` (`:287`). `status_line` gets the wider set through `check_brief`. As a result, the scope of the F31 rule depends on the directory layout, not on the brief's own `Status:` line.

Probe in my scratch dir: an open brief `docs/working/briefs/2026-10-01-a.md` and an open `docs/working/briefs/closed/2026-10-01-b.md` both on `feat/x` print:
```
ok docs/working/briefs/2026-10-01-a.md open review feat/x absent - - 0
ok docs/working/briefs/closed/2026-10-01-b.md open review feat/x absent - - 0
```
(fact-check escalation at `:287`, Claim 13). Today the effect is small: step 6 moves only done/dropped briefs to closed/, `writable()` stops loops from writing there, and `--start` needs an absent branch. But U2's gate will rebuild the same "open briefs on main" set, and it should not inherit an unstated layout rule.

**Recommendation:** Pick one rule and put it in one place. Either F31 counts every `Status: open` brief under `briefs/` and `briefs/closed/`, or an open brief in `closed/` is a skip (anomalous state). Add a lib predicate, for example `isbriefpath` (for briefs/ or closed/), that `writable`, `check_brief` and `shared_branches` all use. A U5 doc line stating the rule would also help.

#### 3. The constraints result is exported only as a display string; its consumer `--start` will have to parse prose

**Severity:** Minor
**Location:** `scripts/build-loop.sh:183`, `:244-247`
**Move:** 3 (module boundary: public surface shape) / 5
**Confidence:** Medium
**Legibility-target:** U3's `--start` author (plan: "the constraints doc must read `ok` (D2)")

**Evidence:**
```
183	POLICY=review; POLICY_LINE=""; SLOTS_LINE=""; NEVER=(); NEVER_LINE=""; CONSTRAINTS_LINE=""
```
```
244	      ok) if [[ "$c" -gt 0 ]]; then CONSTRAINTS_LINE="constraints ok $c-hard $l1-soft: $f on the default branch"
245	          else CONSTRAINTS_LINE="constraints none-hard: $f on the default branch has $l1 soft constraints and no hard one (H1: with a success: line)"; fi ;;
246	      nosuccess) CONSTRAINTS_LINE="constraints unreadable: hard constraint $c (line $l1) has no success: line before the next constraint" ;;
247	      *) CONSTRAINTS_LINE="constraints unreadable: constraint $c is listed twice (lines $l1 and $l2)" ;;
```
(`read_settings` continues to `:250` and was read.)

For policy and never, `read_settings` exposes two things: a machine value for in-process judges (`POLICY`, `NEVER`) and a display line. Constraints get only the display line. U3's `--start` (D2) is the dispatch gate, and in-process it would have to string-match `CONSTRAINTS_LINE == "constraints ok "*`. That ties a gate decision to wording that may change, and the U1b row "The never line's status word has no fixed position" shows these lines already move.

**Recommendation:** Set a `CONSTRAINTS=ok|missing|none-hard|unreadable` value next to the line, the same way POLICY sits next to POLICY_LINE, and have `--start` read that value. This takes one line now and avoids a string-parse contract later.

#### 4. --status is "from main's commit" except for one working-tree gate it inherits from check_brief

**Severity:** Informational
**Location:** `scripts/build-loop.sh:36-37`, `:298`; `scripts/lib/dev-cycle-read.sh:327`
**Move:** 4 (layer: which source of truth a read mode uses)
**Confidence:** High
**Legibility-target:** the orchestrator skill (U4) and anyone running --status from a loop's worktree

**Evidence:**
```
36	#   --status  one line per brief path, in argument order, from the default
37	#             branch's commit:
```
```
298	  out="$(check_brief "$a")"
```
```
327	  if [[ -n "$(blocker "$a" file)" ]]; then echo "skip $a: reached through a symlink, or not a regular file"; return; fi
```
`check_brief` was designed for dev-cycle.sh, which writes the working tree, so it also refuses a brief path that is not plain in the working tree. The lib header documents this (`dev-cycle-read.sh:29-31`), but build-loop.sh's header does not (fact-check Claim 4). `shared_branches` (`:289`) does not go through `check_brief`, so within one mode, one brief's status depends on the working tree and the shared-branch set does not.

This fails closed (a planted symlink causes a skip, never a false `ok`), so it is not a defect. It does mean --status's output depends on which worktree it runs from, and the header says otherwise.

**Recommendation:** Add one clause to the `--status` header ("a brief path that is not plain in the working tree is a skip, as --check-brief"), or give `check_brief` a commit-only variant when U2's gate needs one. Do not change the lib in this unit.

#### 5. status_line parses each brief twice because check_brief's parse cannot leave its subshell

**Severity:** Informational
**Location:** `scripts/build-loop.sh:298-302`
**Move:** 5 (interface segregation: print-channel vs. global-channel)
**Confidence:** High
**Legibility-target:** U2's gate author

**Evidence:**
```
298	  out="$(check_brief "$a")"
299	  [[ "$out" == "ok "* ]] || { echo "$out"; return; }
300	  read -r _ _ st _ <<<"$out"
301	  if [[ "$st" == new ]]; then echo "ok $a new review - absent - - 0"; return; fi
302	  brief_fields "$a" || { echo "skip $a: the brief is not read"; return; }
```
(excerpt ends `:302`; `status_line` continues to `:331`, all read)

The lib header requires `check_brief` to be captured with `$(...)` so that its `need_root` exit stops the run. That means the `BRIEF` array it fills is lost, and the caller has to run `brief_fields` again. The second call re-reads the same blob from the same commit, so the two cannot disagree. But every caller that wants both the state and the fields now pays for two parses, and has to handle a "not read" branch (`:302`) that cannot be reached once `check_brief` has said `ok`. The `--check` gate will have the same shape. This follows from settled design (row "BRIEF holds whole lines in one global array", Won't-Fix). I am noting the consequence, not re-raising the row.

**Recommendation:** No change now. If U2 repeats the pattern, consider a lib `brief_state` that sets the globals in the caller's shell after one `need_root` at the mode's top level.

#### 6. Revisit trigger met: lib header still calls build-loop.sh "planned"

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:2-3`, `:10-12`
**Move:** 3
**Confidence:** High
**Legibility-target:** the next reader of the lib header

**Evidence:**
```
2	# The dev cycle's reader, used by scripts/dev-cycle.sh and kept apart so the
3	# planned scripts/build-loop.sh can share it: the output scrub, the plain-file
```
```
10	# of scripts/ with its lib/ is self-contained. A change here must pass
11	# test/scripts/dev-cycle.bats, and build-loop.sh's suites under test/scripts/
12	# once that second caller lands. The
```
The override-log row "The lib header still calls build-loop.sh 'planned'" (feat/build-loop-u1b) names U1c as its revisit trigger, so the trigger is met. build-loop.sh now has three modes' worth of callers and `test/scripts/build-loop-read.bats` exists. It is not on main yet (`git log main -- scripts/build-loop.sh` is empty), but U1c is the last unit of the U1 stack before it lands.

**Recommendation:** Update lines 2-3 and 10-12 in this unit's fix pass: build-loop.sh is a caller, and a lib change must pass both suites. Alternatively, record in the override log why the trigger moves to the U1 landing merge.

## What Looks Good

- **Marker parsing stays in the script.** `marker_kind` (`:255-280`) is needed only by build-loop.sh's own modes (`--status` now; `--check`'s state gate and U3b's `--marker` later, all in the same file). Keeping it out of the lib keeps dev-cycle.sh's reader free of handoff concepts. Dependencies still point script → lib.
- **`main_file` (`:105-122`) is a good third caller for FENCE_AWK.** One function maps main_entry's result words and FENCE_AWK's refusals to a WHY, and both settings files go through it. This is the shared mapping the settled "case-block copy" row expects (trigger: U2's fourth caller). That trigger is not met yet, but `main_file` is the obvious thing for U2 to lift into the lib.
- **`CONSTRAINTS_AWK` fits the existing pattern.** It is appended to FENCE_AWK the same way SETTINGS_AWK is, and it reports the first problem found as one machine line that the shell maps to prose.
- **Every mode's input comes from main.** `status_line` decides state, branch, policy and dispatch count from `MAIN_SHA` through lib functions. Branch tips reach git only as SHAs from `check_branch`, and T21 pins this.
- **Fail-closed defaults:** POLICY starts at `review` and only the stricter of settings and the brief can raise it (`:311`). A `handoff:` tip that breaks a rule is a skip, not a sixth LOOP value, so consumers get a closed set of LOOP words.
- **Fixture helpers** (`brief`, `work`, `tip`) give U2's gate suite a ready vocabulary for branch and marker states. One note: `status_of` (`fixtures:70`) is unused, which is harmless.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | SHARED_BRANCHES defaults to "no shared branch"; a mode that skips `shared_branches` fails F31 open | Coupling | `scripts/build-loop.sh:283` | High |
| 2 | F31 counts only `briefs/`; --status accepts `closed/`; no single brief-path predicate in the lib | Minor | `scripts/build-loop.sh:289` | High |
| 3 | Constraints result is only a display string; `--start` would parse prose | Minor | `scripts/build-loop.sh:183` | Medium |
| 4 | --status header says main's commit; check_brief also gates on the working tree | Informational | `scripts/build-loop.sh:36` | High |
| 5 | Each brief parsed twice (check_brief's globals lost in its subshell) | Informational | `scripts/build-loop.sh:298` | High |
| 6 | Revisit trigger met (U1c): lib header still says "planned" | Informational | `scripts/lib/dev-cycle-read.sh:3` | High |

## Overall Assessment

The unit keeps the system's structure intact. Dependencies point from script to lib, the new parsers sit in the only module that needs them, and every decision reads main's commit through the lib's existing checks. The concerns are about how state moves between the two stages inside build-loop.sh.

The most important one is Finding 1. The F31 rule depends on a global whose default lets everything through, and U2's `--check` will be the second consumer of that global. Making the default fail closed, or bundling the state load into one function, costs a few lines now and removes a silent bypass from the gate.

Findings 2 and 3 are interface choices that U2 and U3 will copy, so they are cheapest to settle in this unit. All six can be fixed in place; none needs restructuring.

## Goal-Alignment Note
- Success criterion (restated verbatim): Your report saved at the path given in your task tail, structured per your skill, with every finding carrying a verbatim Evidence quote at a `path:line` in this worktree.
- Answered: yes. Saved at the requested path with verbatim evidence for every finding.
- Out of scope: the near-miss constraint shapes being silently dropped (escalated to api-consistency/security); the setlocale warning (performance); Claim 12b's skip-list wording (api-consistency).
- Escalate: Finding 1 to the U2 plan (F31 must be enforced by `--check` without relying on call order). Finding 2's rule (count `closed/` open briefs, or skip them) is a small judgment for the author.
- Questions I would have asked: Is an open brief in `closed/` a state the cycle should refuse outright?
- Decisions I made: I treated the "lib header planned" trigger as met by unit name (U1c), even though build-loop.sh has not reached main. I did not re-raise the settled rows on the case-block copy, the BRIEF global, globform's location or the fixture env.
