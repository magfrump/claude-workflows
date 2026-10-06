Commit: 7697c6e6
# Code Fact-Check Report

**Repository:** claude-workflows
**Scope:** `git diff main...HEAD` at 7697c6e6 (feat/build-loop-u2a2, final confirming pass)
**Checked:** 2026-10-06
**Total claims checked:** 10 merged clusters below (non-Verified clusters, plus the load-bearing Verified ones); replicates checked 41, 38 and 30 claims
**Summary:** 3 Incorrect, 1 Stale, 3 Mostly accurate, 3 Verified (selected); 0 Unverifiable in the diff (Claude Code's own rule was executed by r1 and r3)
**Commit:** 7697c6e6
**Replication:** k=3

Merged from `code-fact-check-report-build-loop-u2a2-f-r1.md`, `-f-r2.md`, `-f-r3.md` (all `Commit: 7697c6e6`), most-severe-wins. Verified claims not listed here are in the replicates; none carries a caveat naming a risk beyond the annotations below.

## Claim 1: "UTF-8 spaces that end an import token, as a blank does" (scripts/lib/dev-cycle-read.sh:450)
**Verdict:** Incorrect
**Confidence:** high
**Verification mode:** executed
**Evidence:** `grep -aoE "$IMPORT_RE"` (:482) runs through a UNI_SPACES character's bytes, so one match swallows the next @token, and the cut at :472 drops it: `@docs/a.md<NBSP>@docs/b.md` yields only docs/a.md; `--check-fix docs/b.md` prints ok. Claude Code 2.1.292 imports both.
**Scope:** covers both walks through import_targets; does not establish a regression (main misses b.md too).
**Replicate verdicts:** r1=Incorrect (18b) · r2=— · r3=Incorrect (9b)
**Replicate annotations:** r1+r3: "not a regression; U2a3's walk inherits it"; E1
**Legibility-target:** for-author

## Claim 2: import_targets' comment: a token ends at "( ) [ or ]" (:461-462)
**Verdict:** Incorrect
**Confidence:** high
**Verification mode:** executed
**Evidence:** IMPORT_RE `[^][:space:]\\#\`()]` has no `[`; `@c[x].md` reads `c[x`. Carried from main's comment.
**Scope:** the comment only.
**Replicate verdicts:** r1=Incorrect (21) · r2=Incorrect (14c) · r3=—
**Replicate annotations:** r1: E2 "( ) or ] inside a real intermediate file name ends the token early (fail-open, not a regression)"
**Legibility-target:** for-author

## Claim 3: bff4ded2 Notes "refuse slightly more (never less)"
**Verdict:** Incorrect
**Confidence:** medium
**Verification mode:** executed
**Evidence:** an import reached through a file whose name holds a Unicode space was refused on main and is ok at HEAD (HEAD resolves it as Claude Code does).
**Scope:** commit message; one corner.
**Replicate verdicts:** r1=Mostly accurate (12) · r2=Incorrect (24b) · r3=Verified
**Replicate annotations:** r1: "direct targets cannot change: pathform accepts ASCII names only"
**Legibility-target:** for-author

## Claim 4: questions.md:393 "[3] replaces U2a2's walk"
**Verdict:** Stale
**Confidence:** high
**Verification mode:** static
**Evidence:** the update at :392 says U2a3 is the unit replaced.
**Scope:** doc.
**Replicate verdicts:** r1=Stale (11) · r2=Mostly accurate (7) · r3=—
**Replicate annotations:** none
**Legibility-target:** for-author

## Claim 5: rubric B10 "Fixed here (inrepo_here)"
**Verdict:** Mostly accurate
**Confidence:** high
**Verification mode:** static
**Evidence:** the comment beside inrepo_here says it; the header (:15) does not name it.
**Scope:** doc.
**Replicate verdicts:** r1=— · r2=Mostly accurate (1b) · r3=—
**Replicate annotations:** none
**Legibility-target:** for-author

## Claim 6: test 1's "a NUL hides no import"
**Verdict:** Mostly accurate
**Confidence:** high
**Verification mode:** executed
**Evidence:** docs/c.md also imports b.md, so a reader that stops at the NUL passes (the no-`-a` mutant still fails).
**Scope:** test name.
**Replicate verdicts:** r1=— · r2=Mostly accurate (19b) · r3=—
**Replicate annotations:** r2: "imps' comment and main arm reference main_imports, absent until U2a3" (r3 Claim 22 agrees)
**Legibility-target:** for-author

## Claim 7: "~/ and absolute paths ... are dropped"
**Verdict:** Mostly accurate
**Confidence:** high
**Verification mode:** executed
**Evidence:** every token starting with `~` is dropped (`@~x.md`), as on main.
**Scope:** comment and code.
**Replicate verdicts:** r1=— · r2=Mostly accurate (14f) · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-author

## Claim 8: UNI_SPACES holds JavaScript's 19 non-ASCII \s code points incl. U+FEFF
**Verdict:** Verified
**Confidence:** high
**Verification mode:** executed
**Evidence:** decoded and compared with node's \s set.
**Scope:** the list; Claim 1 covers how the list is used.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

## Claim 9: check_fix changes only toward refusing more; no existing --check-fix expectation changed
**Verdict:** Verified
**Confidence:** high
**Verification mode:** executed
**Evidence:** existing tests pass unchanged; ..x, U+FEFF, NUL turn ok into skip.
**Scope:** behaviour of direct targets; Claim 3 is the one corner; the elif context disables set -e (architecture final F2).
**Replicate verdicts:** r1=Mostly accurate (12) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "the walk now runs inside an elif condition, where errexit is off (read, not run)"
**Legibility-target:** for-orchestrator-synthesis

## Claim 10: counts: 2 tests, 100 across five suites, 166 code lines; C12/C13 patches applied byte for byte
**Verdict:** Verified
**Confidence:** high
**Verification mode:** executed
**Evidence:** reproduced by all three.
**Scope:** as stated.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "Q-119's 400/480 figures have no committed measurement (Unverifiable)"
**Legibility-target:** for-orchestrator-synthesis

## Escalations
- E1 (r1, r3 → security, orchestrator): Claim 1, lib:482/:472. Read by the security critic (final F1 adds Markdown cases).
- E2 (r1 → security): ( ) ] inside an intermediate file name, lib:456. Read by the security critic.
- E4 (r1 → U2a3 review): U2a3's known-issues A5 says "(main_imports, U2a2)".
- Note (r2): r2 removed /tmp/u2a2f-x-* during cleanup; r1 and r3 report 100/100 regardless.

## Verdict stability
Clusters with two or more reporting replicates: 8. Agreed: 4 (Claims 2, 8, 10 and the Verified token rules). Disagreed: Claim 1 (r2 silent), Claim 3 (MA/Inc/V), Claim 4 (Stale/MA), Claim 7 (MA/V), Claim 9 (MA/V/V). Agreement 4/8 = 50% on contested clusters (single-replicate detections excluded).
