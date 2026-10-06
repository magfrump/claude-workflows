Commit: ab71bce5

# Test Strategy: feat/build-loop-u1d, final confirming pass (iteration 3 of 3)

**Scope:** full branch, `git diff main...HEAD -- scripts test` (83cdb005, 6c83af2a, 07c354c5, merged with main at ab71bce5).
**Reviewed:** 2026-10-06
**Method:** This pass builds on the merged k=3 fact-check (`code-fact-check-report-build-loop-u1d.md`, 93 mutant runs) and does not redo its mutants. I read every changed test step and its fixture helpers (`test/lib/build-loop-fixtures.bash`), plus `shared_branches`, `status_line` and `marker_kind` in full. I ran three new probes in `git archive HEAD` copies under `.../scratchpad/review-u1d/f-test/`, each under `timeout`, and all of them exited: (a) the row-299 mutant `|| rc=$?` dropped; (b) the three Claim-18 chains split (`split.diff`), run against the whole build-loop-read and hermeticity suites; (c) one broken fixture step per split chain.

## Test Conventions

- The tests use bats with `run --separate-stderr`. Each assertion has the form `[ ... ] || { echo "$output"; return 1; }` and is an exact string, unless the tail holds a SHA or a date. Test bodies run under bats' errexit. A command that is not the last one in an `&&` list is exempt from errexit, so a failing fixture step there does not fail the test. That gap is Claim 18.
- The fixture helpers (`settings`, `brief`, `constraints`, `commit_all`) are `&&` chains themselves. Their non-zero return is the last status of the chain, so a helper called as its own statement does fail the test.
- Each new case goes into the test that owns its path: T3, T6, T7 and T44, or one of the three U1d `@test`s.
- The suite already has two ways to make a fixture failure visible. The first is a sentinel: `:480` creates brief `n` with `Branch: feat/\x01n`, so if the overwrite fails, the exact assertion fails too. The second is cleanup that doubles as a check: at `:84`, which predates this branch, `:85`'s `git replace -d` is a standalone statement and fails when no replace ref was made.

## Deferred test-gap rows: accounting

Every row the branch set out to close is either closed by a test that kills its named regression, or carried by a 2026-10-06 override row.

| Row | Gap(s) | Status at ab71bce5 | Evidence |
|---|---|---|---|
| 246 | "not an allowed glob form", "twice", review with a malformed never line, slots line for an absent or unread file, `-h` | **Closed** | `:416-422`, `:430-431`, T3 `:55`, help tests `:441-447` and dev-cycle.bats `:1322`. FC Claims 4 and 10: each step kills its mutant. |
| 279 | caller's GIT_CONFIG_COUNT; fence half of the next-line rule; whitespace-only blank narrowed | **Closed** | `:432-438` and `:476-478` (FC: mutants guardskip and cfg0 are killed); `:423-427`; `:428`, which has a tab. Caveat: `:436` can pass vacuously if its fixture step fails (G15). |
| 284 | main_entry does not run pathform itself | **Closed** | `lib:265` guard. dev-cycle.bats `:1330-1337` fails when the guard is reverted (FC Claim 14). The error-word and caller residue is carried by rows 306 and 308 (2026-10-06). |
| 291 | the NUL refusal and F31's open-only filter in build-loop-read.bats | **Closed** | Commit NUL: T7 `:296-300`, which fails both with the check deleted and with the fixture broken (FC Claim 12). Brief NUL: `:480-482`. F31 filter: `:456-462`. |
| 295 | row 246's G7-G11, trigger met | **Closed** | Same evidence as row 246. |
| 299 | main with no open brief; the CRLF arm; U1c iteration-2 C19's G5-G7 | **Closed** | No open brief: `:451-455`. My mutant m299 (`\|\| rc=$?` dropped, U1c C28 G3's named regression) **fails at :455**. CRLF: `:463-466`, caveat G16. G5 1-char stopped reason: `:257-259`. G6 Dispatched 0 and 99: `:455`, `:462`. G7 fenced `H2:`: `:188-189`. Treating exit 1 as a failure is equivalent through `--status`, as the `:452` comment says (a queried open brief is always on main and always listed). |
| 304 | C29 local BRIEF; C30 anchored closed/ | **Closed for the regressions named; one half carried** | Moving the call: the q step `:472-475` (83cdb005 Notes; FC). Un-anchoring closed/: `:468-471`, caveat G17. Dropping only `BRIEF=()` is unobservable through the CLI and is carried by **row 312** (2026-10-06, revisit U2). |

There is no new open test gap beyond G15-G17. Iteration 2's G13 was fixed in 07c354c5 (C14; FC Claim 10 verified the comment at `:118-119`). G14 is Won't-Fix under row 313.

## Untested Paths Touched by the Change

These continue iteration 2's numbering. All three are FC Claim 18, re-examined. In each one, a fixture step that fails leaves the assertion satisfied, so the step's target regression could slip through at the same moment.

- **G15** — test/scripts/build-loop-read.bats:436 — `git replace … && git config core.useReplaceRefs true`: if `git replace` (or the `rev-parse`/`hash-object` inside it) fails, no replacement exists and main's file reads `review` anyway. `:438`'s `policy review set:` then holds even with the guard pair dropped (mutant guardskip) — not covered on fixture failure. Severity: low. Confidence: high (FC executed the vacuous pass; I executed the split, where `git replace --bogus` fails the test). Legibility-target: for-author.
- **G16** — test/scripts/build-loop-read.bats:464 — `brief p … && printf CRLF > "$B" && commit_all crlf`: if the overwrite or the commit fails, main keeps p as an LF open brief on feat/x. `:466`'s `skip … another open brief` then holds even with `\r?` dropped from the git grep pattern — not covered on fixture failure. Severity: low. Confidence: high (FC executed; in the split, a failing printf fails the test). Legibility-target: for-author.
- **G17** — test/scripts/build-loop-read.bats:469 — `mkdir -p … && printf … > …/1-x.md && commit_all odd-dir`: if any step fails, no `2026-10-0closed` brief reaches main. `:471`'s `ok … 99` then holds even with the closed/ prefix un-anchored (C30's regression) — not covered on fixture failure. Severity: low. Confidence: high (FC executed; in the split, a failing commit fails the test). Legibility-target: for-author.

### Claim 18: how likely, how severe, now or U2

- **How likely it is to matter.** Very low. A gap only bites when two things happen in the same edit: a fixture step fails, and the targeted regression lands. The steps are plain `printf`, `mkdir`, `git replace`, `hash-object -w` and `git commit` in a fresh temp repo under bl_setup's hermetic environment. None of them is version-sensitive. T7's `hash-object --literally` was, which is why 07c354c5 had to split T7. The suite's own helpers have run the same commands, in the same `&&` shape, hundreds of times without a failure. A fixture failure that does happen also tends to show up somewhere else: for example, a failing `commit_all` in `brief q` (`:473`) would change later outputs.
- **How bad it would be.** Low. Each of the three is the only test for its regression: the replace guard under a caller's COUNT, the CRLF arm, and the anchored closed/ prefix. But all three regressions fail open in a narrow way (a replace ref is honoured, or a CRLF or odd-directory brief is or is not counted for F31). Nothing reaches a merge decision until U2/U3 consume these readings, and those units add their own tests. A vacuous pass also stays vacuous only until the fixture is fixed. It does not erase coverage permanently.
- **Recommendation: carry it to U2, with a 2026-10-06 Defer row** (Legibility-target: for-orchestrator-synthesis). There are three reasons:
  1. This is the cap iteration. The project's rule (row 283: "edits after the final pass go unreviewed, as R3 showed") is to defer post-final edits, and the expected loss here is close to zero.
  2. The best fix is a small class fix, and a reviewer should check it once. The split is the minimum. For `:436` the suite's own idiom is better: `:84-85` follow the replace with a standalone `git replace -d`, which proves the ref existed. U2 can sweep every fixture chain in the file the same way, and check each by breaking its fixture.
  3. 07c354c5's "The two other new && chains are split too" is history either way (Accepted-immutable). Fixing now would not make that message exact.
- **Suggested row:** "| 2026-10-06 | `feat/build-loop-u1d` | Three new fixture `&&` chains (build-loop-read.bats:436, :464, :469) let their target mutants pass when a fixture step fails (FC Claim 18; test-strategy G15-G17) | 🟢 Consider | Defer | Plain local writes and commits in a temp repo; a failure must coincide with the regression. Revisit trigger: U2's first commit that edits test/scripts/build-loop-read.bats. Split each chain into standalone statements (for :436, add a standalone `git replace -d` as at :84-85), and its review breaks each fixture step to confirm the test fails. |"
- **If the orchestrator prefers to fix now,** the patch below is checked, though no reviewer has seen it. `split.diff` in my scratch directory (+8/−3, no assertion or command changed) passes 21/21 across build-loop-read and fixture-hermeticity. With one broken fixture step per chain (`git replace --bogus`, `printf > /nonexistent`, `git commit --bogus`), each owning test fails. A split can only make a fixture failure louder, so the worst outcome of an unreviewed split is a loud failure, never a silent one.

## Recommended Tests

#### R1: split the three fixture chains so a failed step fails the test (at U2, by the row above)

**Closes gaps:** G15, G16, G17
**Type:** integration (bats fixture hardening, 0 code lines)
**Priority:** low
**File:** test/scripts/build-loop-read.bats:436, :464, :469
**What it verifies:** that each step's assertion runs only against a fixture that was actually built.
**Key cases:**
- `:436` becomes two statements: `git replace …` and `git config core.useReplaceRefs true`. Optionally add a standalone `git replace -d "$(git rev-parse main:docs/dev-cycle.md)"` after `:438`, as at `:85`. With `git replace` broken, the --settings U1d test fails.
- `:464` becomes three statements: `brief p …`, the CRLF `printf`, and `commit_all crlf`. With the printf broken, the --status U1d test fails.
- `:469` becomes three statements: `mkdir -p`, `printf`, and `commit_all odd-dir`. With the commit broken, the --status U1d test fails.
- With all fixtures intact, the targeted mutants (guardskip, the CRLF arm dropped, closed/ un-anchored) still fail at `:438`, `:466` and `:471`.

**Setup needed:** none. The checked diff is at `.../scratchpad/review-u1d/f-test/split.diff`.

No other test is recommended for this branch.

## What NOT to Test

- **The other new `&&` chains** (FC r2 counted 8; 3 matter). In the rest, a fixture failure already fails an assertion: `:430` (the file would still exist), `:453` and `:460` (`d`/`o` would be unset), `:467` (p would stay and `:471` would read `skip`), and `:480` (the `\x01` sentinel). Splitting them adds churn and no detection.
- **Exit 1 versus a failure in shared_branches.** This is equivalent through `--status`, and `:452` says so. It becomes observable only in-process (U2). This matches iteration 2.
- **Row 312 (the local `BRIEF=()` alone) and row 313 (the "ignored" arm).** These are deferred or Won't-Fix and are not re-litigated here.
- **main_entry's other refused forms.** FC Claim 9 traced 8 forms answering error before any ls-tree. The 4 in dev-cycle.bats `:1330-1337` kill the guard-reverted mutant, and more forms add no detection.

## Coverage Gaps Beyond Current Scope

**1.** Row 307: a broken caller config (`log.date bogus`) turns a `ready` tip into `working` and drops DATE. It is owned by U2's `--check`. The caller-pair step at `:476-478` is the template for its test.

**2.** Row 314: bl_setup does not clear an inherited `GIT_DIR`. It is owned by U2's build-loop-check.bats. The same U2 edit is a natural place to land R1.

## Summary

All seven deferred test-gap rows the branch set out to close are accounted for. Rows 246, 279, 284, 291, 295 and 299 are closed by tests that kill their named regressions. For row 299 I confirmed this here: dropping `|| rc=$?` fails at `:455`. Row 304 is closed for both named regressions, and its "local BRIEF alone" half is carried by row 312. The only open items are FC Claim 18's three fixture chains (G15-G17). Each is low severity, and the chance that one matters is very low, because a fixture failure would have to coincide with the exact regression the step guards. The recommended disposition is a Defer row to U2's first edit of build-loop-read.bats, where R1 (a checked split, plus `:84`'s `git replace -d` idiom for `:436`) gets reviewed. If the orchestrator would rather fix now, the split is checked and can only fail loudly. The main residual risk after this unit is the same as before: rows 307, 312 and 314, all owned by U2. Nothing here blocks landing.

## Goal-Alignment Note

- **Success criterion (verbatim):** A markdown report saved to docs/reviews/test-strategy-review-2026-10-06-final-build-loop-u1d.md (first line `Commit: ab71bce5`), structured per the test-strategy skill.
- **Answered:** yes. Every row (246, 279, 291, 295, 299, 304, 284) is shown closed, or carried by row 312 (304's local-BRIEF half) or rows 306 and 308 (284's error-word residue). Claim 18 is assessed: likelihood very low, severity low, recommended carry to U2 with a revisit trigger, and a checked fix-now patch is available. G15-G17 each carry Severity, Confidence and Legibility-target.
- **Out of scope:** FC Claims 13, 15, 17 and 19 (comment and commit-message wording, and an SC2016 info in a .bats file). These are rubric items, not test gaps.
- **Escalate:** none. The new override row G15-G17 needs is drafted above, for the orchestrator to add.
