Commit: 380ed01b

# API Consistency Review — feat/build-loop-u2a3c, final confirming pass after Q-128 [1]

**Scope:** `git diff main...HEAD` (HEAD 380ed01b), reviewed hardest at 4b7f2357. Surface: the reader lib's function contracts in `scripts/lib/dev-cycle-read.sh` (`main_checkout ENT MEMO PATH` and its new PATH guard, `capped_read`, `lower_all`, `import_work`, `IMPORT_WORK_MAX`, `IMPORT_WORK_LEFT`, the parser's `/N` trailer) and the walk's caller contract as stated in the lib block comment, known issue A5, plan F11 and the U2b bullet.
**Date:** 2026-10-07
**Based on:** Stage-1 summary (`u2a3c-i4-stage1.md`) and the `## Escalations` of `docs/reviews/code-fact-check-report-build-loop-u2a3c-r{1,2,3}.md` (Commit 380ed01b); prior pass `api-consistency-reviewer-review-2026-10-07-build-loop-u2a3c-final.md` (Commit 3a35c8b9).

## Baseline Conventions

- **Contract placement.** Each lib function's contract is the comment directly above it. A5 and F11 point to the lib for the parser's superset claim ("stated once, above `import_targets`"). The walk's caller contract has two homes by a settled deferral (override row "The walk's caller contract lives in two places ... Defer ... Revisit trigger: U2a4"): the lib block above `IMPORTED=` holds the cache rules, and the U2b bullet holds the rest.
- **Return codes.** Predicates return 0/1. `main_checkout` is the lib's one three-valued function (0 walk, 2 nothing loads, 1 refuse), a Won't-Fix row. Both call sites test the code explicitly (`:832`, `:877`).
- **Bounds.** A global `*_MAX` default is passed per call as an env `*_LEFT`, which awk reads with `+ 0`. A caller that changes a `*_MAX` clears both caches.
- **Mode words.** Optional behaviour is selected by a bare word argument (`capped_read drain`), as `md_ls`/`nul_list` take plain argv.
- **Namerefs.** Array outputs and inputs are passed by name (`nul_list NAME`, `import_work OUT TOTAL`, `main_checkout ENT MEMO`), with a function-prefixed local nameref (`nl_a`, `iw_o`, `mc_e`).

## Name-Pattern Audit

4b7f2357 adds no public name. It changes `main_checkout`'s behaviour (PATH guard, O(1) type check) and the contract text. The table restates the branch's names for completeness. Prior passes audited them, and nothing in 4b7f2357 changes a verdict.

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `main_checkout` | function | `main_entry`, `main_by_name`, `main_imports` | `scripts/lib/dev-cycle-read.sh` | Inconsistent grain (main_* reads main's commit). Won't-Fix row, unchanged |
| `capped_read` | function | `nul_list`, `md_ls`, `lower_all` | same file | Consistent (verb_noun helper, mode word `drain`) |
| `lower_all` | function | `lower` | same file | Consistent (`_all` batch form of `lower`) |
| `import_work` | function | `import_targets`, `import_home` | same file | Consistent (`import_` prefix family) |
| `checkout_md`, `md_ls` | function | `untracked_md`, `tree_starts` | same file | Consistent |
| `IMPORT_WORK_MAX` / `IMPORT_WORK_LEFT` | global / env | `IMPORT_OUT_MAX` / `IMPORT_LEFT` | same file `:500-512`, `:672` | Consistent (mirrors the OUT pair) |
| `/N` trailer | output format | none (the parser printed names only) | none — searched `IMPORT_AWK` and `import_targets` callers in `scripts/lib/dev-cycle-read.sh` | New convention. Printed only when `IMPORT_WORK_LEFT` is set, and stripped strictly by `import_work` |

## Findings

#### 1. U2b's direct-caller precondition allows "a PATH main ... stores as a blob", which the lib comment does not, and its answer there is safe only under a duty the bullet attaches to the walk, not to main_checkout

**Severity:** Minor
**Location:** `docs/working/plan-build-loop-handoff.md:279` (U2b bullet); `scripts/lib/dev-cycle-read.sh:718-761`
**Move:** 3 (consumer contract), 7 (asymmetry between the two statements of main_checkout's contract)
**Confidence:** High (executed)
**Legibility-target:** the first caller of `main_checkout` other than `main_imports` (U2a4/U2b implementer).

Evidence. The U2b bullet (new text in 4b7f2357):

> `A caller of `main_checkout` other than `main_imports` passes a fresh MEMO per walk and ENT (a MEMO hit skips main's mode check too) and a PATH main lacks or stores as a blob (a link or gitlink there answers 1)`

The lib comment above the function (also 4b7f2357):

> `# (PATH's own mode is checked first: main's link or gitlink at PATH answers 1).` … `# main_imports calls it only for paths main lacks.`

The code guards only links and gitlinks at PATH (`[[ ! "${mc_e[$3]:-}" =~ ^1[26]0000$ ]] || return 1`, `:743`). It then answers by the checkout's shape and memoizes a plain searchable directory at PATH as `d` (`:760`). Executed in a scratch dir (ROOT_REAL set; `a/` a checkout directory holding `a/x.md`):

```
ENT=([a]=100644)  main_checkout ent memo a      -> 2, memo=([a]="d")
                  main_checkout ent memo a/x.md -> 0
ENT=([a]=120000)  main_checkout ent memo a      -> 1
```

So a PATH that main stores as a blob, where the checkout holds a directory, admits files below it from the checkout. The same was true at 21b35ebf, and r1 executed it. That is safe only when the checkout cannot differ from main at a tracked path. That condition is U2b's clean-worktree-at-MAIN_SHA duty, which the bullet lists among the "four things" U2b owes *the walk*, not among what a direct `main_checkout` caller owes. The lib comment states only `main_imports`' practice (paths main lacks) and gives no allowance for blobs. The two statements of this function's contract therefore disagree on what a second caller may pass. The wider one, U2b's, is the one a second caller would follow. The narrow guard was chosen over the prior pass's PATH-wide `[[ -z "${mc_e[$3]+set}" ]] || return 1` for the reason in rubric D2 ("a broad 'any ENT path' guard would break T1's blob row"). Stage-1 r1-r3 found that reason Incorrect: T1 never passes a blob PATH, and r1 reports the broad guard passing 66/66. This is new text in 4b7f2357, unreachable from `main_imports`, and covered by no override row.

**Recommendation:** Narrow U2b's clause to "a PATH main lacks" (one phrase; it then matches the lib comment and every current call). Alternatively, keep the allowance and tie it to the clean-worktree duty in both places. A third option is the PATH-wide guard, which r1 shows passes the suite.

#### 2. F11's parenthetical list of the caller contract misses the clean-worktree duty 4b7f2357 added to U2b (and `LC_ALL=C`). This is within the deferred two-homes row, not a new premise

**Severity:** Informational
**Location:** `docs/working/plan-build-loop-handoff.md:126` (F11)
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** a reader who takes F11's list as complete.

Evidence. F11 at HEAD:

> `the caller contract (cache clear, empty `ls-files` stderr, the git environment) is in the U2b bullet.`

U2b at HEAD: `owes the walk four things: that checkout a clean worktree at MAIN_SHA ...; that checkout final before the walk, or IMPORTED_MAIN_DONE cleared ...; a git that prints nothing on stderr for ls-files ...; and the git environment ...`, plus `runs the walk under LC_ALL=C (A5)`. A5 at HEAD: `the plan's U2b bullet holds the rest of what a caller owes the walk: a clean worktree at MAIN_SHA, empty ls-files stderr, the git environment, LC_ALL=C`.

Judgment on the Stage-1 question (new finding or within the deferral). The deferred row's premise is that the contract lives in two homes, with pointers naming which part is where. That premise still holds. F11 points to the U2b bullet, which holds every duty F11 omits, so a reader who follows the pointer loses nothing. The `LC_ALL=C` omission predates 4b7f2357; it was in U2b, absent from F11, and seen by the prior pass's finding 2. The clean-worktree omission is a new instance: 4b7f2357 edited this same F11 line (adding "an unreadable file") without updating the parenthetical, which now names three of U2b's four duties. It is the drift the deferral anticipated (r1: "three statements of one contract, as override row 459 anticipates"), not a changed premise. Its consumer impact is nil while the pointer is followed.

**Recommendation:** Optional now; otherwise at U2a4 with the deferred consolidation. Drop the parenthetical ("the caller contract is in the U2b bullet"), or list all four duties and `LC_ALL=C`.

#### 3. The `IMPORT_LEFT` gloss "its leading digits, or 0" still understates awk's numeric read

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:522-529`, `:626-627`
**Move:** 8 (input contract precision)
**Confidence:** High (executed, mawk)
**Legibility-target:** a direct caller of `import_targets` passing a non-arithmetic bound.

Evidence. The comment says `as awk reads a number otherwise: its leading digits, or 0, so the first name fails it`, and `IMPORT_WORK_LEFT` is `read as IMPORT_LEFT is`. Running `/usr/bin/mawk` on `ENVIRON["X"]+0` gives: `12abc -> 12`, `1e3 -> 1000`, `-5 -> -5`, `0x10 -> 16`, `inf -> inf` (no print bound), `nan -> nan`. "As awk reads a number" is right, but "its leading digits" is not. The prior pass's finding 4 recommended "its leading number, or 0". The comment now also says `Both walks pass numbers`, and both call sites pass `$((...))` (`:782`, `:844`, `:846`), so no consumer can reach this. Fact-check r1-r3 escalated the same issue.

**Recommendation:** If the line is touched again, say "as awk reads a number (its numeric prefix, or 0)". No action needed to land.

## Non-findings checked

- **A5's / the lib block's "or nothing" (Stage-1, r2).** At the function level, a path below a non-plain checkout ancestor answers 1 even when nothing is there (executed: `lnk -> real`, `main_checkout e m lnk/none.md -> 1`). At the walk level, which is what A5 and the block comment describe, every ancestor of a token is itself a prefix candidate (`lnk` precedes `lnk/none.md`), and it already fails under the documented "anything but a plain file or directory there" rule. So the walk-level statement predicts the walk's answer. This is not an API finding. It fails closed either way.
- **`${mc_e[0]@a}`.** It gives the same type answer for an associative array whether or not key `0` exists (executed under the function's `set +u`: `[A] [A]` for `ent=([a]=...)` and an empty `memo`). The function's contract (1 when ENT or MEMO is not associative) is unchanged.
- **The PATH guard's return code** matches the contract's "1 to fail the walk" convention, and both call sites still test `c` explicitly.

## What Looks Good

- 4b7f2357 states the PATH guard in the function comment, in U2b, and in a test whose title names the behaviour ("main_checkout refuses a PATH main stores as a link or gitlink ..."). The MEMO invariant ("set only once its own and every higher ancestor's main mode passed") is now true for the PATH arm too, which closes the prior pass's finding 1.
- A5 now says exactly which part of the contract lives where, which closes the prior pass's finding 2 within its deferral. F11 now says "an unreadable file", which closes the prior pass's finding 3.
- `IMPORT_WORK_LEFT` is documented as `read as IMPORT_LEFT is`. That is one rule for both env bounds, which is more consistent than the two divergent glosses before.
- The function inventory test (`test/scripts/dev-cycle.bats:1108-1110`) lists every new function (`md_ls checkout_md main_checkout lower_all capped_read import_work`).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | U2b allows a blob PATH for a direct `main_checkout` caller that the lib comment does not; its answer (memo d, admit below) is safe only under the walk's clean-worktree duty | Minor | plan `:279`; lib `:718-761` | High |
| 2 | F11's contract parenthetical misses the clean-worktree duty and `LC_ALL=C`; within the deferred two-homes row | Informational | plan `:126` | High |
| 3 | "its leading digits, or 0" understates awk's numeric read (inf, 1e3, 0x10); unreachable | Informational | lib `:522-529` | High |

## Overall Assessment

4b7f2357's code change matches the contract it documents. The PATH guard and the O(1) type check change no return code `main_imports` can observe, and all three earlier api-consistency findings that 4b7f2357 targeted are closed. One new Minor issue is a contract-text problem introduced by 4b7f2357. The U2b bullet admits a blob PATH for a second `main_checkout` caller, the lib comment does not, and the answer there leans on a duty the bullet assigns elsewhere. It is unreachable today, and a one-phrase doc edit fixes it. The F11 drift that Stage-1 raised is a new instance inside the settled two-homes deferral, not a changed premise. It is Informational and costs nothing while F11's pointer is followed. Nothing is Breaking.

## Goal-Alignment Note

- Success criterion (restated verbatim from the goal preamble): "User goal: land `feat/build-loop-u2a3c` (worktree `/workspace/.claude/wt-build-loop-u2a3c`) on main once its review-fix loop is clean." Task line: "Clean → merge; any new finding goes back to the user."
- Answered: yes, for the API surface named in the brief. The contracts of main_checkout (guard and `@a` check), capped_read, lower_all, import_work, IMPORT_WORK_MAX/LEFT and the trailer, and the caller contract across the lib, A5, F11 and U2b were checked. Behaviour claims were executed against the lib in a scratch dir.
- New findings: one Minor (Finding 1, contract text new in 4b7f2357, no override row) and one Informational residual (Finding 3). Finding 2 is within the deferral. Under the task line, Finding 1 goes back to the user. It is a doc-only fix and is unreachable from any current caller.
- Out of scope: test quality and timing (test-strategy), exploitability of the blob-PATH allowance (security), and the history prose in rubric D2 beyond noting that Finding 1's choice rests on it.
- Decisions I made: I judged the F11 drift against the deferred row's premise (two homes with correct pointers), not against "every restatement complete". I treated the walk-level "or nothing" as accurate because prefix candidates make every ancestor a PATH.
