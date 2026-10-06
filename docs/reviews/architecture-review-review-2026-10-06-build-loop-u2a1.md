Commit: 6f624cdf

# Architecture Review — feat/build-loop-u2a1

**Scope:** `git diff main...HEAD` (one commit, 6f624cdf): `scripts/lib/dev-cycle-read.sh`, `scripts/build-loop.sh`, `scripts/dev-cycle.sh`, `skills/dev-cycle/SKILL.md`, `test/lib/build-loop-fixtures.bash`, `test/scripts/build-loop-read.bats`, `test/scripts/dev-cycle.bats`, plan step 5 note, Q-119
**Date:** 2026-10-06
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2a1.md` (k=1, 24 claims, 0 Incorrect); settled rows in `docs/reviews/override-log.md` (202-204, 228, 233, 284, 292, 298, 306-320)

**Scope check.** In scope under "Public APIs": the lib's caller contract changes (main_entry gains the word `badform`; two new lib functions, `entry_why` and `isclosed`, are called from both scripts) and `--check-fix`'s refusal set widens. Test, fixture and wording hunks (rows 314, 317-320) are out of scope for this lens and are not reviewed here.

**Trust-boundary scan.** `ls docs/reviews/security-review-*.md` matched no file in the worktree, so the cross-reference is a no-op.

## Dependency Map

Direction is unchanged: `scripts/dev-cycle.sh` and `scripts/build-loop.sh` source `scripts/lib/dev-cycle-read.sh` from their own directory; the lib calls nothing in either script. The diff adds two lib functions with callers in both scripts:

- `entry_why` (lib:282-290) is called by check_brief (lib:352), check_answer (lib:570) and build-loop.sh's main_file (:133). Each caller keeps its own `absent`/`blob` arms and passes every other word to `entry_why`.
- `isclosed` (lib:159) is defined through `isbrief`, and is called by writable (lib:162), check_brief (lib:342) and build-loop.sh's shared_branches (:318).
- `check_fix` stays in dev-cycle.sh (row 204's settled Won't-Fix). It reads the lib's `writable`, `INSTRUCTION_FILE`, `pathform` and the walk's `IMPORTED` cache. The cache read is row 205's Defer, which U2a2's `isimported` closes.

No new cycle, no new module, and no new lib-to-script dependency.

## Findings

#### F1. Row 204's read-as-truth list is not shared, and the divergence is settled in plan prose rather than by either outcome the row named

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:181-183`; `docs/working/plan-build-loop-handoff.md:274`
**Move:** 2 (responsibility boundaries), 7 (coupling surface)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
scripts/dev-cycle.sh:181-182
  elif [[ ! "$lp" =~ ^docs/.*\.md$|^readme\.md$ || "$lp" =~ ^docs/(working|human-author|reviews|decisions)/ \
    || "$lp" == docs/dev-cycle.md || "$lp" == docs/constraints.md || "$a" == */.* || "$low" =~ $INSTRUCTION_FILE ]]; then
```
```
docs/working/plan-build-loop-handoff.md:274 (excerpt; the line continues with "U1d's carried wording and fixture rows.")
   - **U2a1**: ... `check_fix` also refuses `docs/constraints.md` (row 204: the user writes it, D2; `docs/thoughts/` stays fixable in-cycle as a living doc, so `check_fix` and the floor differ there on purpose); ...
```
```
docs/reviews/override-log.md (row 204, Decision/Rationale cells)
| Defer | U2 shares one list or files a `you: judgment` entry (plan amendment). |
```

Row 204 left U2 two outcomes: one shared list, or a `you: judgment` entry. The branch takes a third: it adds `docs/constraints.md` to check_fix's inline regex and records the `docs/thoughts/` asymmetry as intentional in the plan. No decision-log row, override-log closure or questions entry carries it. The asymmetry is defensible: check_fix is an allowlist for in-cycle doc edits and D5's floor is a denylist for unreviewed merges, so the two do differ in purpose. The structural cost comes when U2a2 lands, because the user-owned and record subset (`constraints.md`, `decisions/`, `human-author/`) will then be spelled in two modules: here in dev-cycle.sh's regex, and in the lib's `floor` (D5 item 4). A later user-owned file (another D2-style input, say) would then need two edits in two files, and nothing would catch a missed one.

**Recommendation:** In U2a2, put the shared subset in a lib predicate (something like `usertruth`: `docs/constraints.md`, `docs/decisions/`, `docs/human-author/`). `floor` calls it plus its own extra items (`docs/thoughts/`, other briefs' working docs), and check_fix calls it plus its own extras (`working/`, `reviews/`, `dev-cycle.md`), so only the intended differences remain spelled per caller. In this unit's pr-prep, close row 204 with the "differ on purpose" reading, either as a `docs/decisions/log.md` row or as the override-log closure. The user should be able to see the choice without reading plan step 5.

#### F2. check_fix's refusal set is restated in five places; this diff had to edit all five, and one copy has already drifted

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:50-54`, `:167-171`, `:181-183`; `skills/dev-cycle/SKILL.md:72-75`
**Move:** 7 (coupling surface)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
scripts/dev-cycle.sh:167-171
# An in-cycle fix edits documentation only: a tracked .md file under docs/,
# outside the cycle's own files, working/, human-author/ (the user's), reviews/
# and decisions/ (records), the settings file, constraints.md (the user's: plan
# D2), any dot-directory, and any instruction file (CLAUDE.md, AGENT(S).md,
# GEMINI.md, SKILL.md, any case); or README.md. Anything else is filed.
```
```
skills/dev-cycle/SKILL.md:74
`docs/decisions/`, `docs/dev-cycle.md`, `docs/constraints.md`, a dot-directory or dotfile, an instruction file, or a
```

The regex, the skip message, the `--help` header, the function comment and SKILL.md each list the set. Adding one file (`constraints.md`) meant five edits. The fact-check (Mostly accurate, `:167-171`) already finds the function comment missing two refusals the other four copies carry (dotfiles, `@`-imported files). This is the set F1 proposes to partly move into the lib, so the copy count will matter again in U2a2.

**Recommendation:** Make the function comment point to the `--check-fix` help text instead of listing the set again. SKILL.md is a separate audience and keeps its copy. That brings the count down to three, all in places a reviewer already reads.

#### F3. The "open or closed brief" union is spelled at three sites, and U2b adds a fourth

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:162`, `:342`; `scripts/build-loop.sh:318`
**Move:** 8 (extension points)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
scripts/lib/dev-cycle-read.sh:162
    || "$1" =~ ^docs/working/cycles/cycle-$DIGIT{4}-$DIGIT{2}-$DIGIT{2}\.md$ ]] || isbrief "$1" || isclosed "$1"
scripts/lib/dev-cycle-read.sh:342
  if ! isbrief "$a" && ! isclosed "$a"; then
scripts/build-loop.sh:318
    if ! { isbrief "$f" || isclosed "$f"; } || ! brief_fields "$f"; then continue; fi
```

`isclosed` does what row 292 asked: the closed/ rule now has one spelling, built on `isbrief`'s date and slug grammar. Each caller still writes the disjunction itself, though, and row 298 moves F31's brief enumeration into the lib in U2b, which adds another. This costs little today because each site is one short line.

**Recommendation:** When U2b moves enumeration into the lib, consider an `anybrief` predicate (`isbrief || isclosed`) for all of them. Optional.

#### F4. Refusal reasons have an ordering dependency that U2a2's floor should respect

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:282-290`, `:340-341`, `:265-266`
**Move:** 3 (module boundary)
**Confidence:** Medium
**Legibility-target:** for-author (U2a2)

**Evidence:**
```
scripts/lib/dev-cycle-read.sh:265-266
  if ! main_by_name; then echo error; return; fi
  if ! pathform "$1"; then echo badform; return; fi
scripts/lib/dev-cycle-read.sh:285-286
    badform) echo "$2 is not an allowed path form" ;;
    error) echo "the tree of the default branch could not be read" ;;
scripts/lib/dev-cycle-read.sh:341
  if ! pathform "$a"; then echo "skip ${a//$'\n'/ }: not an allowed path form"; return; fi
```

Every current caller tests `main_by_name` (check_brief :340, check_answer :564, build-loop.sh's start-up exit) and, where the path is not fixed, `pathform` (check_brief :341) before calling main_entry. So `entry_why`'s `badform` arm and the no-main cause of its `error` arm are reached by no caller today (the fact-check confirms the default arm is unreachable too). That makes the pre-checks a second spelling of two of entry_why's reasons. For check_brief this is justified: pathform has to run before `blocker` reads the working tree. U2a2's floor is the first caller that will pass arbitrary changed paths (`.gitattributes`, `.github/x.yml`), and those read `badform`. If the floor hands them to main_entry before running its own dot-component test, the refusal will cite "not an allowed path form" rather than D5 item 2. If the walk finds a duplicated tree name, `error` reports it as "could not be read".

**Recommendation:** In U2a2, run the floor's own rules (the dot test, gate code, instruction file) before main_entry, so the refusal names the floor item, and leave `entry_why` as the fallback for tree-shape refusals. No change is needed in U2a1.

## What Looks Good

Each row below is a claim submitted for verification, not a certified result.

| Observation | Status |
|---|---|
| main_entry's contract now has a closed shape: "Only blob reads the file, and only absent means there is none: every other word is a refusal" (lib:257-258). U2a2's floor and walk can rely on that, and it is the rule rows 306 and 307 asked for. | [unverified — submitted as claim]; fact-check reports every current caller treats `badform` as a refusal (executed) |
| `entry_why` keeps the reason apart from each caller's framing (`skip $a: …`, `…, so $f is not read`, `FILE_WHY=`), so row 228's single mapping does not force one message shape on every caller | [unverified — submitted as claim] |
| `entry_why`'s default arm names an unknown word rather than mapping it to an existing reason, so a word added to main_entry later fails closed with a visible message | [unverified — submitted as claim]; fact-check: unreachable from current callers |
| `isclosed` is defined through `isbrief`, so the date and slug grammar lives in one regex (lib:158). The three old spellings were not equivalent forms of one rule; they were three separate rules. | [unverified — submitted as claim]; fact-check: equal on 23 edge cases |
| Dependency direction is unchanged: the lib calls nothing in either script, and both new functions are pure (no git, no globals) | [unverified — submitted as claim] |
| The hermeticity test's function list adds `isclosed` and `entry_why` (dev-cycle.bats), so a self-contained copy of the lib cannot quietly drop them | [unverified — submitted as claim] |

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Row 204: no shared read-as-truth list and neither named outcome; the subset will be spelled in two modules once U2a2 lands | Minor | `scripts/dev-cycle.sh:181-183`; plan:274 | Medium |
| 2 | check_fix refusal set restated in five places; comment already drifted | Informational | `scripts/dev-cycle.sh:167-171` (+ :50-54, :183, SKILL.md:74) | High |
| 3 | `isbrief \|\| isclosed` union spelled at three sites, a fourth coming in U2b | Informational | lib:162, :342; build-loop.sh:318 | Medium |
| 4 | Pre-checks duplicate two `entry_why` reasons; the floor should run its own rules before main_entry so refusals name the floor item | Informational | lib:265-266, :282-290, :341 | Medium |

## Overall Assessment

The change improves the lib's structure. It gives main_entry a closed caller contract and one place to word refusals (row 228), one closed/ rule (row 292) and a distinct form-refusal word (row 306), without changing dependency direction or adding public surface beyond two small pure functions. U2a2 can build its floor on this boundary: `badform` and `error` are both refusals, `entry_why` is a fallback the floor can reuse, and `isclosed`/`writable` are the predicates the floor plan names. The most important open point is F1. Row 204's choice between one list and a judgment entry was settled by a third reading, written into plan prose. That reading needs a durable record, and U2a2 should put the user-owned subset in a lib predicate so check_fix and the floor cannot drift apart. Nothing here is Structural or Coupling, and nothing blocks the merge.

## Goal-Alignment Note

- **Success criterion (verbatim):** A markdown report saved to docs/reviews/<critic>-review-2026-10-06-build-loop-u2a1.md inside the worktree, structured per your skill, with `Commit: 6f624cdf` as its first line.
- **Answered:** The lib's caller contract (main_entry's words, `entry_why` as row 228's shared mapping, `isclosed` as row 292's single closed/ rule) holds up structurally. U2a2's floor can build on it (F4 gives guidance on check order). Where check_fix's list and the floor's list should live (row 204): the shared subset belongs in a lib predicate, and the per-caller differences stay with each caller (F1).
- **Out of scope:** Correctness and wording of the test and fixture hunks (rows 314, 317-320); security of `badform` handling (no security review on this branch, so the trust-boundary cross-reference was a no-op); message wording, which is the api-consistency critic's.
- **Escalate:** none.
- **Decisions:** F1 recommends recording row 204's "differ on purpose" closure in `docs/decisions/log.md` or the override log during this unit's pr-prep. The orchestrator decides which.
