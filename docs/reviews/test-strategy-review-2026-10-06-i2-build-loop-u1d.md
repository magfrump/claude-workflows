Commit: cc75db98

# Test Strategy: feat/build-loop-u1d, review iteration 2 (fix commit 6c83af2a)

**Scope:** partial scope (loop pass), `83cdb005..cc75db98` limited to scripts/ and test/, which is fix commit 6c83af2a. The rest of the branch is context only.
**Reviewed:** 2026-10-06
**Method:** I applied iteration 1's `proposed.diff` to 83cdb005's build-loop-read.bats with `patch` and diffed the result against HEAD's file. I read every changed test step in full. Two new mutants were run in `git archive HEAD` copies under `.../scratchpad/review-u1d/i2test/` (`fencecount/`, `boxcount/`, logs `fencecount.log` and `boxcount.log`, each under `timeout 600`, both exited). This builds on this pass's k=1 fact-check (17 mutants, `docs/reviews/code-fact-check-report-build-loop-u1d.md`) and does not redo its mutants.

## Test Conventions

- bats with `run --separate-stderr`. Fixtures come from `test/lib/build-loop-fixtures.bash`. Each assertion is `[ ... ] || { echo "$output"; return 1; }`, an exact string unless the tail holds a SHA or a date.
- New cases go into the test that owns the path (T3, T6, T7, T44, and the U1d tests), not into new `@test`s. 6c83af2a follows this habit.
- T7's `check` helper is a *prefix* match (`[[ "$output" == "$1"* ]]`), then it resets feat/a to `$base`.
- The hermeticity lint misreads `'` inside double quotes, so skip messages must not contain one.

## Did the patch land intact?

Yes. `patch` applied `proposed.diff` to 83cdb005's file cleanly. The result differs from HEAD's file only in these places, and none of them changes a fixture, a command or an assertion:

| Place | Proposal | Applied (6c83af2a) | Effect |
|---|---|---|---|
| --settings U1d, :427 | comment "pairs stay, and the guard still applies after them" | "does not stop the guard (that the caller's pairs still reach git is asserted in the --status deferred-cases test)" | Fixes G10's overclaim. FC Claim 13 verified both halves. |
| help test title, :436 | unchanged ("--help prints the whole header") | "-h and --help print the header from its first line through its last" | It matches the loop now. |
| help test body, :437-441 | `for` loop with the body unindented | body indented; failure echo is `"$h: $output"` | Cosmetic, with better diagnostics: mutant noh fails with `-h:` (FC). |
| --status U1d title, :444 | unchanged | reordered, adds "a caller's config pair", says "a NUL in a brief" | It no longer claims row 291's commit-NUL item (iteration 1's R1 note). |
| :447 | none | "(A done brief never consults F31, so this cannot tell exit 1 from a failure.)" | The conclusion holds (mutant exit1 survives). The wording is imprecise: see the Note below. |
| :457 | CRLF comment kept "keeps its own Dispatched value whatever F31 read" | clause dropped | Fixes A2. The q step at :466 owns that claim. |
| :470 (A6) | none | "A caller's own GIT_CONFIG_COUNT pair still reaches git beside the guard pair." | It is true jointly with the --settings test. The step itself asserts only the caller's pair. |
| dev-cycle.bats:1328 | not in the proposal | retitled "main_entry answers error for a path pathform refuses" | Closes G11 as wording, which is what iteration 1 recommended. |

The T44 fenced-H2 step uses a literal ```` ``` ```` rather than `$f`. T44 defines no `local f`, so the literal is correct there. Iteration 1's "use `$f`" note was a style aside and is not a defect.

## Do any new fixtures pass for the wrong reason?

None that I found. Each step was read in full. The fact-check's head/pre mutant table shows that each one is the step that kills its named regression.

- **T7 NUL commit (:295-296).** `printf '\0x'` emits a NUL then `x`, because `x` is not an octal digit. The object has `$base`'s tree and `$base` as parent, so it changes no files and is one commit ahead. That leaves the NUL as the only reason to refuse. `check` is a prefix match on `skip $B: $n: it holds a NUL byte`. Under mutant nul the output is `ok ... ready`, so the step is not satisfied by some other refusal.
- **F31 open-only filter (:451-456).** The rewritten d still matches git grep's `^Status: open\r?$` on its line 3. brief_fields keeps the first Status line (`done`), so only `"${BRIEF[status]-}" == "Status: open"` keeps o from skipping. d is not queried again after the rewrite, so dropping its Dispatched line costs nothing.
- **Caller's config pair (:470-472).** `grep.patternType=bogus` makes git grep exit 128. The exact assertion is the could-not-be-listed skip. o's branch is absent, so no `git log` runs that could fail first (see the FC out-of-scope note on DATE). Under mutant cfg0 the step prints `ok ... 99`. As a bonus, this is now the suite's first step to reach the `rc -gt 1` → `SHARED_BRANCHES=error` arm from a real git failure.
- **Dispatched: 0 (:448-450).** The expected `- - 0` is the same as the output for an absent Dispatched line. So the step proves only that an explicit 0 is *accepted* (mutant disp0, which refuses it, is killed). It does not prove that 0 is read rather than defaulted. No plausible mutant separates those two readings, so this is acceptable.
- **T3 slots (:55), the tab blank (:423), the bare success: (:184) and the 1-char reason (:256-257).** Each was checked by its FC mutant: slotsunread, tabblank, baresuccess and onechar. Each fails at HEAD and survives 83cdb005.
- **Fenced H2 (:188-189).** Mutant fencedh2n (fence skip made a no-op only in CONSTRAINTS_AWK) is killed at :189. The wider deletion is caught earlier, at :177.

## Untested Paths Touched by the Change

### Iteration 1's G1-G12

| Gap | Status at cc75db98 | Evidence |
|---|---|---|
| G1 marker_kind commit-NUL (row 291 C17) | **Closed** | mutant nul killed at :296, survives pre |
| G2 F31's own Status filter (row 291 C18) | **Closed** | mutant f31status killed at :456, survives pre |
| G3 slots line for an unread file | **Closed** | mutant slotsunread killed at :55 only |
| G4 `-h` | **Closed** | mutant noh killed |
| G5 bare `success:` | **Closed** | mutant baresuccess killed at :185 |
| G6 1-char stopped REASON | **Closed** | mutant onechar killed at :257 |
| G7 Dispatched 0 and 99 | **Closed** | mutants disp0 (:450) and disp99 (:456) killed |
| G8 fenced constraint ID skipped | **Closed** | mutant fencedh2n killed at :189 |
| G9 tab in the blank-line class | **Closed** | mutant tabblank killed at :424 |
| G10 caller's pairs reach git | **Closed**, by a test (R6), not by rewording | mutant cfg0 killed at :472. Mutant guardskip killed at :433. |
| G11 pathform before ls-tree | **Closed as wording** (retitled) | FC Claim 6 traced 0 git calls for refused paths. Not a test, by design. |
| G12 the local `BRIEF=()` alone | **Open, deferred** (override-log row 312, revisit at U2) | mutant brieflocal survives (FC) |

The other 2026-10-06 rows (306-311) are deferred to U2 or U3b, or are Won't-Fix, and are not re-litigated here. Row 307 is iteration 1's Beyond-scope item 1 (a broken git config reading `working` and dropping DATE).

### New this pass

- **G13** — test/scripts/build-loop-read.bats:118 — the comment "A never list hidden in markup turns self-merge off rather than being skipped" now contradicts the rewritten header (build-loop.sh:16-19, A3). The header says a copy the count misses (a task box, a fence) "is ignored, so self-merge rests on the exact line alone". The step's fixture is `- [x] Self-merge never: b/` alone. The count misses it (no `never` line is found), and self-merge is off only because there is no exact line. The asserted `$no` message itself says "there is no valid Self-merge never: line". So the copy *is* skipped, and the comment claims the opposite of what is asserted. This line predates 6c83af2a (sibling context), but A3 made it wrong. It is the same class as iteration 1's A2/A8/A9 comment rows. — not covered (wording). Severity: low. Confidence: high (fixture and assertion read; boxcount mutant below). Legibility-target: for-author.
- **G14** — scripts/build-loop.sh:16-19 with :151-157 — the A3 header's "ignored" arm (a missed copy beside one exact line leaves self-merge resting on the exact line) — not covered. Two stricter mutants survive the whole build-loop-read suite (19/19): **fencecount** counts a `selfmergenever` line inside a fence as a copy, and **boxcount** changes `index(s, "selfmergenever") == 1` to `> 0`, so a `- [x]` copy counts. Both are fail-closed: they turn self-merge *off* in more cases. Severity: low. Confidence: high (executed). Legibility-target: for-orchestrator-synthesis (a choice about the contract, not a missing assertion; see What NOT to Test).

## Recommended Tests

#### R1: reword the :118 comment so it says what the step asserts

**Closes gaps:** G13
**Type:** wording only (0 code lines)
**Priority:** low
**File:** test/scripts/build-loop-read.bats:118
**What it verifies:** nothing new. It brings the comment in line with A3 and with the existing `$no` assertion.
**Key cases:** replace the comment with:
```
    # A never list the copy count misses (a checked task box) is skipped; with no exact
    # line beside it there is no never list, so self-merge is off.
```
**Setup needed:** none.

No other test is recommended. G1-G11 are closed, and G14 belongs under What NOT to Test.

## What NOT to Test

- **G14, the "ignored" arm.** A positive test (`Self-merge never: a/` plus `- [x] Self-merge never: b/` reads `policy self-merge set`) would pin a documented *limitation*: the hidden `b/` is never enforced. It would also fail on exactly the fail-closed tightening that the help's "best effort" wording invites. Iteration 1 offered it as optional (Beyond-scope 2). After FC Claim 1b, I recommend against it. If the contract is ever made strict, pin the strict side at that point. The header wording should also say "a checked task box" (FC Claim 1b): an unchecked `- [ ]` box adds no letters and is counted. That is a wording fix, not a test.
- **Corrupt versus missing objects (A5 wording, build-loop.sh:309-311).** FC Claim 4 executed both. A fixture that corrupts or deletes loose objects is brittle across git versions and packing. The `rc -gt 1` arm is now reached through the caller-pair step.
- **The exit-1 arm as `-ge 1`.** It is still equivalent through `--status`: an open brief that is queried is always on main and always matched by git grep. This is unchanged from iteration 1.
- **G11 and G12.** As iteration 1 decided: G11 has no output effect, and G12 is deferred to U2 (row 312).

## Coverage Gaps Beyond Current Scope

**1.** Row 307 (security F1): a broken caller git config can turn a `ready` tip into `working` and drop DATE. It is deferred to U2's `--check`. The new caller-pair step at :470-472 is a ready template for its test (`GIT_CONFIG_*` with `log.date bogus`).

**2.** Row 312 / G12: when U2's `--check` calls shared_branches after its own brief_fields, its test must query a brief that is not the lexically last open brief. The q step at :466-469 is the template.

## Summary

The checked patch landed intact. The orchestrator changed only titles, comments, the loop indentation and one failure-echo string, and no fixture or assertion moved. All ten mutants that iteration 1 named for G1-G10 now fail the suite at the added step and survive 83cdb005, so G1-G10 are closed and row 291's C17 and C18 are closed. G11 is closed as wording, and G12 stays deferred (row 312). No new fixture passes for the wrong reason. The weakest step is the explicit `Dispatched: 0` step, whose expected line equals the absent-line default, but it still kills the regression it names. Nothing beyond G11, G12 and the deferred rows is open at test level. The one new item is a stale comment at bats:118 that A3's rewrite made wrong (G13, low, one comment edit). Its neighbour G14, the unpinned "ignored" arm, should stay untested on purpose. The residual risk is the same as iteration 1's: G12 and row 307, both owned by U2.

## Goal-Alignment Note

- **Success criterion (verbatim):** A markdown report saved to docs/reviews/test-strategy-review-2026-10-06-i2-build-loop-u1d.md (first line `Commit: cc75db98`), structured per the test-strategy skill.
- **Answered:** yes, with each focus question answered in its own section. The patch landed intact, with the orchestrator's changes listed one by one. No fixture passes for the wrong reason. G1-G10 are closed, G11 is closed as wording, and G12 is deferred. Beyond those and the deferred rows, the only open item is G13 (a stale comment, low) plus G14, which is recommended not to test.
- **Out of scope:** the A3 header's "a task box" imprecision (FC Claim 1b) and the :447 "never consults F31" wording (FC Claim 16; precise form: "a done brief never reads F31's answer"). Both are wording rows for the rubric, not test gaps.
- **Escalate:** none. G13 is an amber-at-most wording fix that can land with the FC wording items.
