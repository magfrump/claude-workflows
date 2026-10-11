Commit: e25a6e89

# Security Review: feat/build-loop-u3a3 (iteration 2, loop pass)

**Scope:** `git diff a7a4f784..HEAD` (fix commit e25a6e89 only; partial scope: 18f32952 and a7a4f784 were reviewed in iteration 1 and are read here as context): scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-merge.bats, docs/reviews/override-log.md
**Date:** 2026-10-10
**Based on:** docs/reviews/code-fact-check-report-u3a3-i2.md (13 Verified, 1 Mostly accurate: header :215 "(under --approved, the N rules' lines only)" is too narrow); shared brief u3a3-i2/brief.md; iteration-1 security review and rubric
**Threat model:** a hostile build loop (same uid) controls its branch and worktree. Questions for this pass: does widening GATE_CODE close iteration 1's R1, does it regress anything, did the wording or trailer change open a path to a landing, and is the A1 interim adequate?

## Trust Boundary Map

```
B1: loop branch tip, changed paths (S1, lower-cased) → check_line: nrules, then `=~ $GATE_CODE` → VERDICT[gate]  (GATE_CODE widened)
B2: questions entry on main (S2)                      → check_answer → "keep|drop|done|open|unrecognized|skip" + ANSWER_HEADING → approval() case  (cases split, var renamed)
B3: VERDICT[stem, tip:0:12, gate] + EXPECT (S5)       → approval()'s exact heading compare → land(AUTH, Q-NNN) → trailer keyed on AUTH  (trailer condition moved)
B4: changed path (S1) under self-merge                → floor (truthrule, then GATE_CODE → "gate") → floor_why → srules DENY  (floor now refuses skills/dev-cycle/)
B5: merged content on main (S1 after landing)         → dev-cycle skill run by the orchestrator (installed SKILL.md; checkout's health check) → code that runs with the orchestrator's authority  (unchanged; context for R1's coverage)
```

Input-source classification:

```
S1: loop branch tip, its tree and paths — runtime-mutable (loop-owned) — UNTRUSTED for every sink (merge content, gate bit, floor)
S2: docs/working/questions{,-archive}.md at MAIN_SHA — written by the user/orchestrator; N rules deny both
                                           (now executed: build-loop-merge.bats:217-224) — trusted as authorisation,
                                           parsed fail-closed
S3: brief path / stem                    — orchestrator argument, checked open on main — trusted for naming
S5: --expect SHA, --approved Q-NNN        — orchestrator arguments — format-checked (full 40/64 hex, required for --merge;
                                           ^Q-[0-9]+$ once). Where U4 sources --expect is the A1 question.
S6: GATE_CODE regex                       — code-constant — trusted; its coverage is the R1 question
```

The fix changes no boundary's shape. It widens one code-constant (S6), which raises B1's gate bit and B4's floor refusal for more paths. It splits approval()'s refusal case into more arms that all return 1, and it moves land's trailer condition from "$2 non-empty" to "$1 == approved". The only new reach is B4 refusing more paths, which is stricter.

## Findings

#### 1. Code the dev-cycle skill runs from the checkout (scripts/health-check.sh and the suites it runs) is outside GATE_CODE and the floor (pre-existing; not introduced or regressed by e25a6e89)

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:1923` (GATE_CODE), `skills/dev-cycle/SKILL.md:159-160`, plan `docs/working/plan-build-loop-handoff.md` D5 "In this repo"
**Boundary:** B5, B1, B4
**Move:** 5 (invert the access control model), 11
**Confidence:** Low (it depends on the brief's Paths: listing the file or test files, and on how D13 isolates the orchestrator from a same-uid loop. It may sit inside Q-103's same-uid family.)
**Legibility-target:** the plan's D5 "In this repo" paragraph and the Q-103 residual list. A reader should be able to see which in-repo code takes effect on merge.

Evidence (verbatim):
```
GATE_CODE='^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/'
```
```
  the repo's health check, if it has one (e.g. `scripts/health-check.sh` in claude-workflows),
```
Plan D5: "Code such as scripts, skills, hooks and guides reaches running sessions only through a release you cut ... So the release is the real gate".

Probe `security/probe-floor.sh` (executed): `scripts/health-check.sh: -   no GATE_CODE match`. The floor does not refuse it, and neither does GATE_CODE. The widening closes the skill's own directory. The behaviour the skill runs also includes the health check, which step 1 runs from the checkout of main, not from the release. A self-merge whose Paths: lists `scripts/health-check.sh`, or test files that the health check's suites run, lands code that the orchestrator executes at the next cycle's step 1, with no review entry. The plan's claim that scripts reach sessions only through a release has this exception, alongside the `workflows/` exception it already names. This diff did not create the gap and does not widen it. It is filed because the brief asked whether R1 is fully closed against changes to what the skill does.

**Recommendation:** do not fix this in U3a3. Route it as a D5 "In this repo" exception, either in Q-103's residual list or in a U5 entry alongside `Self-merge never: workflows/`. The options are a `Self-merge never:` glob for `scripts/health-check.sh`, or a recorded acceptance that the health check runs main's tests by design.

#### 2. A sibling skill or routing text can redirect "run the dev cycle" under a plain `merge-` slug

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1923`, `scripts/build-loop.sh:1047`
**Boundary:** B1, B3
**Move:** 11
**Confidence:** High (behaviour). This is the class already deferred as override row "A plain merge- approval lands the floor-protected paths too ... (i1 security 3)".
**Legibility-target:** U4's merge-entry body.

Evidence (verbatim, probe-floor.sh): `skills/dev-cycle-2/skill.md: instr` / `no GATE_CODE match`; `global-instructions/agents.md: instr` / `no GATE_CODE match`.

`^skills/dev-cycle/` needs the slash, so a new `skills/dev-cycle-2/SKILL.md`, or an edited routing row in the global instructions, does not set the gate bit. Either one can change which procedure a session runs for "run the dev cycle". Under self-merge the floor refuses both as `instr`. Under `--approved` they land under a plain slug. Both are instruction files, so they fall under the deferred i1 security 3 row. Its revisit (U4's entry body lists each path the floor would refuse, with its floor_why reason) covers them, and no new row is needed. Per plan D6 the gate itself runs from the root-owned installed SKILL.md, so neither path reaches the gate before a release.

**Recommendation:** none for U3a3. When U4 writes the entry body, check that `instr` paths outside `skills/dev-cycle/` are flagged there.

#### 3. The header's "(under --approved, the N rules' lines only)" can be read as dropping the --expect check, which is the whole of the A1 interim's binding; no test runs a mismatched --expect under --approved

**Severity:** Informational
**Location:** `scripts/build-loop.sh:213-216`, `scripts/build-loop.sh:992`, `test/scripts/build-loop-merge.bats:194-251`
**Boundary:** B3
**Move:** 4 (check vs use), 11
**Confidence:** High (code, read-static); the test gap was confirmed by grep
**Legibility-target:** for-author (the U4 writer who relies on the header's A1 sentence)

Evidence (verbatim):
```
#             (under --approved, the N rules' lines only), but an ok
```
```
  if [[ -n "$EXPECT" && "$sha" != "$EXPECT" ]]; then echo "refuse $a: the tip of $br is $sha, not the expected $EXPECT"; return; fi
```
The code is sound. The --expect refusal runs before anything that reads AUTH, and arg parsing requires a full 40- or 64-hex `--expect` with `--merge` (`build-loop.sh:313-325`). The fact-check's Mostly-accurate verdict on :215 matters for security because A1's interim is "the caller passes the full TIP; --expect binds it". A reader who takes "the N rules' lines only" literally could conclude that the expect check does not apply under `--approved`. None of the `--approved` tests passes a wrong `--expect`.

**Recommendation:** use the fact-check's wording, "(under --approved, without the S rules or the checkout refusal)". Add one T35 line in which `--approved` with an answered [1] and a matching heading still refuses on a mismatched `--expect`.

#### 4. The floor's new refusal of `skills/dev-cycle/` under self-merge has no floor test

**Severity:** Informational
**Location:** `test/scripts/build-loop-check.bats:1302-1303`
**Boundary:** B4
**Move:** 5
**Confidence:** High
**Legibility-target:** for-author

Evidence (verbatim): `scripts/build-loop.sh "$GATE" scripts/dev-cycle.sh "$GATE" scripts/questions.sh "$GATE"` / `scripts/lib/dev-cycle-read.sh "$GATE" scripts/lib/new.sh "$GATE" Scripts/Build-Loop.sh "$GATE"`. No skills/dev-cycle path appears there. The behaviour was confirmed by executing probe-floor.sh: `skills/dev-cycle/references/x.md: gate`, and `skills/dev-cycle/skill.md: instr` (truthrule runs before GATE_CODE). The `--approved` side is tested (`build-loop-merge.bats:242`). The self-merge side the commit message claims ("the floor refuses it under self-merge too") is not.

**Recommendation:** add `skills/dev-cycle/references/x.md "$GATE"` to the floor test at :1302.

## Answers to the brief's focus questions

- **R1 closed?** It is closed for the skill's own directory and every path under it, in any case (`lower_all` runs before the match). The bypass candidates were dispositioned below. A symlink or gitlink at or under `skills/dev-cycle` is refused by nrules' mode rule (`build-loop.sh:777`, modes 100644 and 100755 only). Replacing the directory with a file or a symlink named `skills/dev-cycle` needs a `D` record for `skills/dev-cycle/SKILL.md`, which sets the gate bit. `skills/./dev-cycle` and `skills//dev-cycle` fail pathform. The gate code does not source files outside `scripts/` (`SCRIPT_DIR` is used only for `lib/` and `questions.sh`). The skill reads `docs/dev-cycle.md` and `docs/constraints.md`, which the N rules deny (`cycle`, `user`). What stays open is behaviour-level. Findings 1 and 2 cover the code and instruction files outside the directory that change what the skill does. Neither is a regression.
- **Regression?** There is none in safety terms. The floor now also refuses non-SKILL.md files under `skills/dev-cycle/` under self-merge (probe: `references/x.md: gate`; before this commit it gave `-`). This is stricter and fails closed. In another repo that has its own `skills/dev-cycle/`, those paths go to review. No caller tests GATE_CODE apart from floor and check_line (grep). `dev-cycle.sh --check-fix` does not use it. build-loop-check.bats passed 146/146 and build-loop-merge.bats 12/12 (serial).
- **Wording or trailer change opens a landing?** No. approval() proceeds only on the exact string `"keep $1"`. The new `drop` and `done` arms, `*` and the existing `open` and `skip` arms all set MERGE_WHY and `return 1`. `r="$(< file)"` runs inside the `elif ! approval` condition, so a read failure leaves r empty and goes to `*` (refuse). check_answer empties ANSWER_HEADING before reading. No `ANSWER_HEAD` reference is left (`grep -rnw ANSWER_HEAD scripts test`: none), so a missed rename could not even compare against a stale value. The heading compare is unchanged (a quoted `==`, byte-exact). The trailer is equivalent: the merge arm sets `AUTH=approved` exactly when APPROVED is non-empty and calls `land "$AUTH" "$APPROVED"`. The trailer only labels the message and decides nothing.
- **A1 interim adequate?** Yes, as an interim. No caller passes `--approved` today (U4 is unbuilt). `--merge` requires a full-hex `--expect`, and check_line compares it to the tip before any AUTH-dependent step. The heading's SHA12 is taken from that same tip, so passing the full TIP from the entry binds all of it. The plan already accepts the 48-bit slug (F48 row: "a loop that grinds a prefix collision is F19-level") and puts the full 40-hex TIP in the entry body (D4). The override row's revisit trigger is placed at U4's entry writer, which is where the rule has to be enforced. Finding 3 is the one legibility fix that keeps the interim from being misread.

## Untested bypass candidates

- **Unicode-lookalike directory names** (e.g. `skills/dev‐cycle/` with U+2010): not executed. pathform's character set likely refuses them as a path form (`build-loop.sh:776`), but this was not run for that spelling. On a non-normalising filesystem it would be a different directory, so the loader would not read it as the dev-cycle skill.
- **How the installed skill is chosen** (image copy vs `~/.claude/skills` vs checkout): not testable here. Plan D6 and F39 describe it, and U3b/U4 build it.

Candidates tested (none bypass): case variants (`Scripts/Lib/x.sh` and `skills/dev-cycle/references/x.md` tests, executed); symlinks and gitlinks (mode rule, read-static); a file named `skills/dev-cycle` (probe: `-`, which cannot exist while the directory exists without a D record under it); an answer of `merge` (executed test :231, refuses as not read); options [2] and [3] (executed, refuse); a stale or absent ANSWER_HEADING (read-static, refuses).

## Endorsement Claims

- **Claim:** under `--approved`, every check_answer result other than the exact line `keep Q-NNN` makes approval() return 1 before the heading compare.
  **Location:** `scripts/build-loop.sh:1076-1092`
  **Evidence:** executed (build-loop-merge.bats test 10: [2], [3], `merge`, open, working-tree-only, no entry; 12/12 ok)
  **Verified:** the case statement's arms and the tests' refusal lines.
  **Not verified:** check_answer's `unrecognized`, `odd` and `unbalanced` paths through approval in an executed run. They reach `*` or `skip`, which was read but not run in this pass.
  **route: code-fact-check**

- **Claim:** the widened GATE_CODE sets VERDICT[gate] for any changed path under `skills/dev-cycle/`, after lower-casing, and the floor refuses those paths under self-merge.
  **Location:** `scripts/lib/dev-cycle-read.sh:1923,1955`, `scripts/build-loop.sh:1047`
  **Evidence:** executed (merge test 11 for `skills/dev-cycle/references/x.md`; probe-floor.sh for the floor)
  **Verified:** gate-slug refusal and acceptance under `--approved`; the floor words `gate` and `instr` for two paths.
  **Not verified:** an upper-case `Skills/Dev-Cycle/...` path through the floor in a self-merge `--merge` run (lower_all was exercised only by the Scripts/Lib case).
  **route: code-fact-check**

- **Claim:** land writes the `Build-loop-approved:` trailer exactly when the merge arm's AUTH is `approved`, which happens exactly when APPROVED is non-empty.
  **Location:** `scripts/build-loop.sh:1177,1217,1225`
  **Evidence:** executed (merge test 8, message and trailers) plus read-static (merge arm)
  **Verified:** the AUTH assignment, the land call and the printf condition.
  **Not verified:** a self-merge landing's message after this change. Test 1's message assertion covers it but was not inspected line by line in this pass.

## Primitive sweep

Primitive: authorisation decision (answer → land)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:1224` approval "$APPROVED" | S2, S1 (tip), S3 (stem), S6 (gate bit) | exact `keep Q-NNN` + byte-exact heading | cleared (new arms all refuse); gate-bit coverage → Findings 1, 2 (non-regressions) |
| `scripts/build-loop.sh:1223` review-policy refusal | S1 policy from main | AUTH=self-merge | cleared: unchanged by e25a6e89 |
| `scripts/build-loop.sh:1225` land "$AUTH" "$APPROVED" | S5 | format `^Q-[0-9]+$`; trailer keyed on AUTH | cleared: printf `%s`; equivalent condition |

Primitive: GATE_CODE match
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:1047` gc bit | S1 lower-cased | lower_all, pathform, mode rule | cleared for the directory; Findings 1, 2 for the neighbours |
| `scripts/lib/dev-cycle-read.sh:1955` floor gate word | S1 lower-cased | truthrule runs before it (SKILL.md → instr) | cleared; test gap → Finding 4 |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | The checkout's health check (and the suites it runs), executed by the skill, is outside GATE_CODE and the floor (pre-existing, not a regression) | Medium | B5, B1, B4 | `skills/dev-cycle/SKILL.md:159-160`, `dev-cycle-read.sh:1923` | Low |
| 2 | A sibling skill or routing row can redirect the dev cycle under a plain slug (deferred i1 security 3 class) | Informational | B1, B3 | `dev-cycle-read.sh:1923` | High |
| 3 | Header :215 can be read as dropping --expect under --approved; no mismatched---expect test under --approved | Informational | B3 | `build-loop.sh:213-216` | High |
| 4 | No floor test for skills/dev-cycle/ under self-merge | Informational | B4 | `build-loop-check.bats:1302` | High |

## Overall Assessment

e25a6e89 closes iteration 1's R1 for the dev-cycle skill's directory without opening any new path to a landing. The widened GATE_CODE fails closed under self-merge, approval()'s new refusal arms all return 1, the trailer change only labels the message, and the questions-archive N-denial is now executed. Both suites pass serially (146/146, 12/12). The A1 interim is adequate: `--expect` is mandatory and full-hex, the plan already accepts the 48-bit slug, and the revisit sits at U4's entry writer. The one Medium is pre-existing. The skill runs the checkout's health check, which no gate category covers, and that belongs in Q-103 or a D5 "In this repo" entry rather than this unit. The single most useful in-place change is Finding 3's header wording plus one T35 line, because the A1 interim depends on readers knowing that `--expect` still binds under `--approved`. No findings block the merge within the code paths read; endorsement claims pending execution verification.

## Goal-Alignment Note

Success criterion (verbatim): "a report saved to /workspace/.claude/wt-build-loop-u3a3/docs/reviews/security-review-2026-10-10-u3a3-i2.md, structured per the security-reviewer skill, with `Commit: e25a6e89` at the top."

This report is at that path, with `Commit: e25a6e89` on its first line. It has the skill's structure: boundary map, source table, findings, untested bypass candidates, endorsements, primitive sweep, summary and assessment. It serves the user goal of getting U3a3 through its loop and merged locally. It finds no regression and no new landing path in the fix commit. It leaves one pre-existing Medium to route and three Informational items, the cheapest being a header wording change and two test lines.
