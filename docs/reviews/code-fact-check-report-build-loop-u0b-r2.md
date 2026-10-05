Commit: 698348ac
# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-handoff (claude-workflows)
**Scope:** U0b full range `feat/build-loop-u0a..feat/build-loop-u0b` (0b53fe50, fbe3a219, 698348ac): `scripts/lib/dev-cycle-read.sh`, `scripts/dev-cycle.sh`, `test/scripts/dev-cycle.bats`, and the three commit messages. Final confirming pass, replicate 2 of 3.
**Commit:** 698348ac
**Checked:** 2026-10-05
**Total claims checked:** 11
**Summary:** 9 verified, 1 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

The hallucination-pattern log was read. All test counts in this range match the bats runs. The shared execution provenance (E-bats, E-modes, E-mut, E-probe1, E-probe2, E-moved, SCRATCH) is defined in `docs/reviews/code-fact-check-report-build-loop-u0a-r2.md`, and every log it names is under `SCRATCH/logs/`. Additional run for this unit:
- **E-nomain:** in SCRATCH, a scratch repo on branch `trunk` with one commit. Each tree's dev-cycle.sh is run with no mode and with `--check-brief`, `--check-branch`, `--check-path` and `--check-answer`. Started at 07:33Z. Output files `SCRATCH/logs/nomain-{main,u0a,u0b,u0c}.txt`, identical across all four trees. Separately, an unborn repo with no commits prints "Could not resolve a default branch …" from both main's copy and u0c's.

The u0b lib header's need_root parenthetical ("set -u fires there") is carried unchanged from U0a. It is reported once, as Incorrect, in the U0a report (Claim 7), and is not counted again here.

---

## Claim 1: "inrepo, dirok, skipped and check_brief exit 1 (need_root) when ROOT_REAL is unset or is not the current directory; rawfile, plaindir and blocker then read nothing as plain."

**Location:** `scripts/lib/dev-cycle-read.sh:12-14` (u0b)
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the complete list of exiting lib functions at u0b. check_answer is still in dev-cycle.sh at this tip, and check_branch and resolve_main read no files. It does not establish anything about the u0c list (see the u0c report, Claim 1).
**Legibility target:** for-orchestrator-synthesis

```bash
# scripts/lib/dev-cycle-read.sh check_brief (u0b)
check_brief() {
  local a="$1" st c n why
  need_root
```

The second half of the new bats test asserts `[ "$status" -eq 1 ] … "ROOT_REAL is not set"` for check_brief. The mutant `b-brief-noneed` is KILLED. check_branch has no file read and no need_root call. (Paraphrased: no quote available because this is a claim about absence of code; check_branch's body reads only refs.)

**Evidence:** `scripts/lib/dev-cycle-read.sh` check_brief/check_branch (u0b), `SCRATCH/logs/mutations.txt`

---

## Claim 2: "The caller runs resolve_main once per process (a second call re-reads main); check_brief and check_branch skip every argument unless it returned 0 with main found by name."

**Location:** `scripts/lib/dev-cycle-read.sh:16-18` (u0b)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers resolve_main resetting and recomputing the three globals, and the skip covering never-run, fallback and by-name cases. It does not establish the case where MAIN_SHA was resolved in a different repository. That case is settled as Won't-Fix in override-log row 208.
**Legibility target:** for-orchestrator-synthesis

`resolve_main() { local c sha cur origin_head candidates=(); MAIN=""; MAIN_SHA=""; MAIN_BY_NAME=""` … `[[ -n "$MAIN_SHA" ]]; }`, and `main_by_name() { [[ -n "$MAIN_SHA" && -n "$MAIN_BY_NAME" ]]; }`. The bats test "check_brief and check_branch skip, not answer, without a default branch found by name" gets four skips and no `ok` line. E-mut KILLS `b-brief-nomain`, `b-branch-nomain` and `b-mbn-shaonly`. dev-cycle.sh calls resolve_main once (`scripts/dev-cycle.sh:183`, u0c).

**Evidence:** `scripts/lib/dev-cycle-read.sh` resolve_main/main_by_name, `scripts/dev-cycle.sh:183`, `SCRATCH/logs/mutations.txt`

---

## Claim 3: "The default branch, set by resolve_main (below). check_brief and check_branch read its commit, so they answer only when it was found by name, never for the current branch's fallback or before resolve_main has succeeded." / check_branch: "The default branch is refused, and so is every name when there is no default branch found by name (main_by_name)."

**Location:** globals block above `MAIN=""; MAIN_SHA=""; MAIN_BY_NAME=""`; check_branch's comment (u0b; u0c `:227-231`, `:284-285`)
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the guards at the top of both functions, and their initial values when the lib is sourced. It does not establish anything about a caller that writes MAIN_SHA or MAIN_BY_NAME directly.
**Legibility target:** for-orchestrator-synthesis

Both functions open with `if ! main_by_name; then echo "skip …: no default branch found by name (origin/HEAD, main or master), or resolve_main has not run"; return; fi`. E-probe1 P5 (u0c lib): after resolve_main, `check_branch main` prints `skip main: the default branch`.

**Evidence:** `SCRATCH/logs/probe1.txt` (P5), `SCRATCH/logs/bats-u0b.txt`

---

## Claim 4: resolve_main "sets MAIN (its name), MAIN_SHA and MAIN_BY_NAME (1 when the name is origin/HEAD's, main or master, not the current branch's), and returns 1 when MAIN_SHA is empty"

**Location:** `scripts/lib/dev-cycle-read.sh` resolve_main comment (u0c `:300-302`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fallback to the current branch, the empty-repo and outside-repo return, and the by-name flag. It does not establish anything about an origin/HEAD that names a locally created branch, which is deferred in override-log row 209.
**Legibility target:** for-orchestrator-synthesis

The bats test "resolve_main returns instead of exiting…" asserts `trunk <sha> by-name=no` and then `none 1: [] []`. The mutant `b-resolve-exit` (`|| exit 1`) is KILLED.

**Evidence:** `test/scripts/dev-cycle.bats` resolve_main test, `SCRATCH/mut/b-resolve-exit.out`

---

## Claim 5: dev-cycle.sh "from this script's own directory: the scrub, the file and path rules, FENCE_AWK, the brief and branch checks, and the default branch."

**Location:** `scripts/dev-cycle.sh:83-85` (u0b)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the list against the u0b lib's definitions. It does not establish anything about later units.
**Legibility target:** for-orchestrator-synthesis

At u0b the lib defines FENCE_AWK, oddwhy, check_brief, check_branch, resolve_main and main_by_name on top of U0a's set. (Paraphrased: no quote available because this is a claim about which symbols the file defines; T29 at u0b lists them.)

**Evidence:** `scripts/lib/dev-cycle-read.sh` (u0b), T29

---

## Claim 6: commit 0b53fe50: "FENCE_AWK and oddwhy, check_brief, check_branch and the default-branch resolution, moved verbatim. The resolution becomes resolve_main, which returns 1 instead of exiting … dev-cycle.sh keeps its exit and message."

**Location:** commit 0b53fe50 message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line diff at 0b53fe50 and the refusal message and exit after the change. It does not cover fbe3a219's and 698348ac's declared guard additions.
**Legibility target:** for-orchestrator-synthesis

E-moved (0b53fe50): the moved FENCE_AWK, oddwhy, check_brief and check_branch lines are identical. The only differences are an added SC2034 to FENCE_AWK's directive (dropped again in fbe3a219), the resolution wrapped as a function with `local` and a final `[[ -n "$MAIN_SHA" ]]`, and dev-cycle.sh's `resolve_main || [[ -n "$CHECK" ]] || { echo "Could not resolve a default branch (tried origin/HEAD, main, master, the current branch)" >&2; exit 1; }` (`scripts/dev-cycle.sh:183`, u0c). E-nomain: identical output and exit codes from main and every tip.

**Evidence:** `SCRATCH/rm-0b53fe50.txt`, `SCRATCH/add-0b53fe50.txt`, `SCRATCH/logs/nomain-*.txt`

---

## Claim 7: commit 0b53fe50: "a new test checks that resolve_main falls back to the current branch and returns 1 outside a repo."

**Location:** commit 0b53fe50 message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the test asserted at 0b53fe50. It does not cover the tip, where fbe3a219 tightened the test as its own message says.
**Legibility target:** for-author

At 0b53fe50 the test runs `resolve_main || echo "none: [$MAIN] [$MAIN_SHA]"` and expects `none: [] []`. It asserts a non-zero return, not 1 specifically. fbe3a219's bullet "The resolve_main test now asserts the return code of 1" (`none $?:` → `none 1:`) closes this inside the range. Precise version for 0b53fe50: "…and returns non-zero outside a repo."

**Evidence:** `git show 0b53fe50:test/scripts/dev-cycle.bats:1068-1077`, `test/scripts/dev-cycle.bats` (tip)

---

## Claim 8: commit fbe3a219: "the found-by-name rule lived only in dev-cycle.sh, so a second caller of the lib could get a landed brief read as 'new', or a brief's Status read from a loop-written current branch."

**Location:** commit fbe3a219 message
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both pre-fix outcomes, using the lib at 0b53fe50. It does not cover other second-caller misuse.
**Legibility target:** for-orchestrator-synthesis

E-probe2 (b), lib at 0b53fe50. Without resolve_main, a brief committed on main as `Status: done` gave `ok docs/working/briefs/2026-10-02-a-b.md new`, after `line 238: MAIN_SHA: unbound variable` inside the substitution. With main renamed and `loop` checked out, `MAIN=loop by=no` and the brief read `ok … open <loop commit>`. Its other bullets also hold: MAIN, MAIN_SHA and MAIN_BY_NAME start empty, dev-cycle.sh exits first (`:187-189`), "four skips, no ok line" is the test's assertion, and FENCE_AWK's directive is SC2016 only.

**Evidence:** `SCRATCH/logs/probe2.txt` (b), `scripts/dev-cycle.sh:183-189` (u0c)

---

## Claim 9: commit 698348ac: "the header said a check run without ROOT_REAL exits 1, but check_brief called blocker directly and skipped every brief as 'reached through a symlink'." and "dev-cycle.sh's found-by-name exit uses main_by_name instead of its own -z "$MAIN_BY_NAME" test (same condition)."

**Location:** commit 698348ac message
**Type:** Error-handling / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pre-fix skip (lib at fbe3a219) and the claim that the two exit conditions are equivalent within dev-cycle.sh. It does not establish the equivalence for a caller that sets MAIN_BY_NAME without MAIN_SHA, which resolve_main never does.
**Legibility target:** for-orchestrator-synthesis

E-probe2 (c), lib at fbe3a219 with main found by name and no ROOT_REAL: both an existing brief and an absent one print `skip …: reached through a symlink, or not a regular file`, because `docs/` itself is reported as blocked. resolve_main sets `MAIN_BY_NAME=1` only together with a non-empty `MAIN_SHA` (`if [[ -n "$sha" ]]; then MAIN="$c"; MAIN_SHA="$sha"; MAIN_BY_NAME=1; break; fi`), so `! main_by_name` and `-z "$MAIN_BY_NAME"` agree after resolve_main.

**Evidence:** `SCRATCH/logs/probe2.txt` (c), `scripts/lib/dev-cycle-read.sh` resolve_main, `scripts/dev-cycle.sh:187`

---

## Claim 10: commit 698348ac Notes: "all 58 tests at this tip pass (main's 53 among them); the digest, --check-brief and --check-branch output on this repo, and the no-main-branch refusal, are unchanged." (and 0b53fe50/fbe3a219's equivalent lines)

**Location:** commit 698348ac, fbe3a219, 0b53fe50 messages
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the u0b tip: 58 tests, main's 53 names present, all modes identical, and the refusal identical. It does not cover byte-identity at the intermediate commits 0b53fe50 and fbe3a219 (test counts at those commits: 57 and 58, from the files).
**Legibility target:** for-orchestrator-synthesis

E-bats u0b: 58 ok. E-modes: `cmp` identical. E-nomain: identical.

**Evidence:** `SCRATCH/logs/bats-u0b.txt`, `SCRATCH/logs/modes-u0b.txt`, `SCRATCH/logs/nomain-u0b.txt`

---

## Claim 11: commit 0b53fe50 and later: the stated motive "so build-loop.sh can report it its own way"

**Location:** commit 0b53fe50 message
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers only that resolve_main returns rather than exits. It does not establish how build-loop.sh will report the result, because that script does not exist until U1.
**Legibility target:** for-orchestrator-synthesis

The return behaviour is verified (Claim 4). The consumer is planned, not present (`ls scripts/build-loop.sh` fails). Verifying the motive needs U1's code.

**Evidence:** `docs/working/plan-build-loop-handoff.md:268-270`

---

## Claims Requiring Attention

### Incorrect
- None new. The need_root "set -u fires there" clause is carried from U0a; see the U0a report, Claim 7.

### Stale
- None.

### Mostly Accurate
- **Claim 7** (commit 0b53fe50): at that commit the test asserted a non-zero return, not 1. fbe3a219 corrected the test inside the range, so nothing needs fixing.

### Unverifiable
- **Claim 11** (commit 0b53fe50): build-loop.sh's use of resolve_main can only be checked once U1 adds the script.

## Goal-Alignment Note

U0b's goal is a behaviour-neutral move plus fail-closed guards for a second caller. Both hold. dev-cycle.sh's output, including the no-main refusal, is byte-identical to main's. The guards are pinned by tests, and every guard mutant fails its test. The two pre-fix bugs described in the fix commits reproduce on the parent code. Nothing in this unit blocks landing.
