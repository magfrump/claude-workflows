Commit: c143b929

# Architecture Review — feat/build-loop-u1c, final pass (iteration 2)

**Scope:** `git diff feat/build-loop-u1b...feat/build-loop-u1c` at c143b929: `scripts/build-loop.sh` and its use of `scripts/lib/dev-cycle-read.sh`
**Date:** 2026-10-05
**Based on:** Stage-1 merged code-fact-check (`docs/reviews/code-fact-check-report-build-loop-u1c.md`: 32 Verified, 10 Mostly accurate, 0 Stale, 0 Incorrect); iteration-1 rubric `docs/reviews/code-review-rubric-2026-10-05-feat-build-loop-u1c.md` (A4, A5); fix diff c143b929.

Scope check: in scope. The diff adds a public mode (`--status`), a fourth `--settings` output line, and line formats that U2-U4 parse (trigger categories 2 and 3).

Trust-boundary cross-reference: no-op. No file matches `docs/reviews/security-review-*.md`; the security critic's files are named `security-reviewer-review-*`. No finding below moves a trust-boundary crossing.

## Dependency Map

- `scripts/build-loop.sh` sources `scripts/lib/dev-cycle-read.sh` from its own directory. It uses `resolve_main`/`main_by_name`, `main_entry`, `FENCE_AWK`/`oddwhy`, `brief_fields` (the global `BRIEF`), `check_brief`, `check_branch`, `isbrief`, `lower` and `NAMECHARS`. `scripts/dev-cycle.sh` sources the same lib. Dependencies point one way, script to lib. The lib does not know build-loop.sh exists, apart from two comment lines.
- Inside build-loop.sh, the `status` mode calls `read_settings`, which sets `POLICY`. It then calls `status_line` once per argument. `status_line` calls `check_brief`, then `brief_fields`, then (since c143b929) `shared_branches` on its first use, then `check_branch`, then `marker_kind`.
- `shared_branches` calls `isbrief` and `brief_fields` for every brief on main. Both it and `status_line` write the lib's one global `BRIEF` array, which is where the new coupling in F1 comes from.
- Downstream contracts: `ok BRIEF STATE POLICY BRANCH LOOP SHA DATE DISPATCHED [REASON]` and `skip BRIEF: WHY` for U4's skill, and the `constraints …` line for the orchestrator. Plan rev 4 also says U2's `--check` must do the F31 skip (plan `:146`) and read `BRIEF[paths]` for the gate.

## Prior findings: status at c143b929

- **A5 (SHARED_BRANCHES fail-open default): resolved for `--status`, but the fix adds the coupling in F1.** `status_line:326` runs `[[ -n "$SHARED_BRANCHES" ]] || shared_branches`. `shared_branches` always leaves at least `$'\n'` in the variable (`:307`), so the guard works as a "computed" flag, and a mode can no longer skip F31 by forgetting a top-level call. The variable is still global and still reads as "nothing shared" when empty, so a new caller that matches against it directly (U2's `--check`, which also needs F31) still fails open. Only callers that go through `status_line` are protected. F1's recommendation covers both problems.
- **A4 (closed/ briefs not counted; no single brief-path predicate): the behaviour is resolved; the predicate is not.** `:301` now lists `briefs/` and `briefs/closed/`, and `:303` accepts a `closed/` entry with `isbrief "${f/closed\//}"`. T28 now covers an open brief left in `closed/`. I traced the substitution and it is sound: `ls-tree` without `-r` lists only direct children, and a slug cannot contain `/`, so stripping the first `closed/` matches only the `closed/` directory part. But the lib still has no `closed/` predicate. The rule "a brief path, optionally under `closed/`" now has three spellings (F2).

## Findings

#### F1. The lazy `shared_branches` call overwrites `BRIEF` in the middle of `status_line`, but only on the first call

**Severity:** Coupling
**Location:** `scripts/build-loop.sh:316-326` (with `:298-309`)
**Move:** 7 (coupling surface; temporal coupling via shared global state)
**Confidence:** High
**Legibility-target:** the author of U2's `--check` (the next function that judges a brief, does F31 and reads `BRIEF`)

**Evidence:**
```
   316	  brief_fields "$a" || { echo "skip $a: the brief is not read"; return; }
   317	  if [[ -z "${BRIEF[branch]+set}" ]]; then echo "skip $a: no Branch: line on the default branch"; return; fi
   ...
   325	  [[ "$POLICY" == self-merge && "${BRIEF[policy]-}" == "Policy: self-merge" ]] && pol=self-merge
   326	  [[ -n "$SHARED_BRANCHES" ]] || shared_branches
   (remainder :327-346 reads only br, st, pol, disp and local values, not BRIEF)
```
```
   302	  while IFS= read -r f; do
   303	    if ! isbrief "${f/closed\//}" || ! brief_fields "$f"; then continue; fi
```
Probe: a copy of the script under the scratch dir, instrumented to print `BRIEF` right after `:326`, run with `--status a.md a.md` on a repo whose main holds briefs `a` (`Branch: feat/a`, `Policy: self-merge`) and `z` (`Branch: feat/z`):
```
PROBE after-shared: BRIEF[branch]=Branch: feat/z BRIEF[policy]=unset
ok docs/working/briefs/2026-10-01-a.md open review feat/a absent - - 0
PROBE after-shared: BRIEF[branch]=Branch: feat/a BRIEF[policy]=Policy: self-merge
ok docs/working/briefs/2026-10-01-a.md open review feat/a absent - - 0
```

Before c143b929, the mode ran `read_settings; shared_branches` once before the loop, so `BRIEF` always held the brief that `status_line` had just parsed. With the A5 fix, `shared_branches` runs inside `status_line`, after `brief_fields "$a"`. On the first call only, it leaves `BRIEF` holding the last brief in the `ls-tree` listing. Today's output is correct because nothing after `:326` reads `BRIEF`. But whether a read of `BRIEF` placed after that line is correct now depends on whether this is the first brief in the argument list, and the tests would catch that only if the first brief listed and the last brief on main differ in the field read. The plan has U2's `--check` doing F31 and then reading `BRIEF[paths]` and `BRIEF[policy]` for the gate. If it copies this order, the gate would judge brief A's diff against brief Z's `Paths:` on the first brief of a run. Override row 229 settled "BRIEF holds whole lines in one global array" as a convention. Its premise did not cover a call that overwrites `BRIEF` between a caller's parse and its reads, and c143b929 introduced that, so this is not a re-file of row 229.

**Recommendation:** Hide the shared-branch state behind a predicate such as `branch_shared NAME`, which computes on first use and is what every caller asks. Then a caller cannot read the fail-open empty value (the rest of A5). Also make sure nothing reads `BRIEF` after the call can clobber it: either call the predicate before `brief_fields "$a"` (move the guard above `:316`), or have `shared_branches` collect its fields without writing `BRIEF`. Add a one-line comment on `shared_branches` saying it overwrites `BRIEF`.

#### F2. The "brief path, optionally under closed/" rule now has three spellings

**Severity:** Minor
**Location:** `scripts/build-loop.sh:303`; `scripts/lib/dev-cycle-read.sh:157`, `:161`, `:326`
**Move:** 3 (module boundary: a rule the lib owns, re-encoded by a client)
**Confidence:** High
**Legibility-target:** whoever next changes the brief naming rule (slug alphabet, date form, or a third directory)

**Evidence:**
```
lib:157  isbrief() { [[ "$1" =~ ^docs/working/briefs/$DIGIT{4}-$DIGIT{2}-$DIGIT{2}-$SLUG\.md$ ]]; }
lib:161      || "$1" =~ ^docs/working/briefs/closed/$DIGIT{4}-$DIGIT{2}-$DIGIT{2}-$SLUG\.md$ ]] || isbrief "$1"
lib:326  if ! isbrief "$a" && [[ ! "$a" =~ ^docs/working/briefs/closed/$DIGIT{4}-$DIGIT{2}-$DIGIT{2}-$SLUG\.md$ ]]; then
bl:303       if ! isbrief "${f/closed\//}" || ! brief_fields "$f"; then continue; fi
```
Iteration-1 A4 asked for one predicate in the lib. c143b929 fixed the bug, but it did so by adding a third form, and this one is a string trick in the client script. It works only because of an unstated fact about the caller's input (`ls-tree` lists direct children only). A reader has to work out that "strip `closed/`, then `isbrief`" equals the inline regexes at lib `:161`/`:326`. A change to one spelling (say, allowing uppercase slugs, or adding `briefs/parked/`) silently diverges from the others. The divergence fails toward a skip in `check_brief`, but toward not counting a brief in `shared_branches`, which is the fail-open direction for F31.

**Recommendation:** Add `isbrief_any` (or `isbrief "$1" closed`) to the lib, holding the one regex with `(closed/)?`, and use it at lib `:161`, lib `:326` and build-loop `:303`. That is a three-line change, and it closes A4 as originally filed.

#### F3. `shared_branches` skips briefs it cannot read, so F31 does not count them

**Severity:** Informational
**Location:** `scripts/build-loop.sh:303`
**Move:** 2 (responsibility boundary: what F31 promises versus what the counter sees)
**Confidence:** Medium
**Legibility-target:** U2 author; help-text reader of `:66`

**Evidence:**
```
   303	    if ! isbrief "${f/closed\//}" || ! brief_fields "$f"; then continue; fi
   304	    [[ "${BRIEF[status]-}" == "Status: open" && "${BRIEF[branch]-}" =~ ^Branch:\ ([^\ ]+)$ ]] || continue
```
An open brief that FENCE_AWK refuses, or whose `Branch:` line is not exact, is not counted. A readable brief that names the same branch therefore prints `ok`. This is harmless in U1: the unreadable brief is itself a skip, so it cannot be dispatched. It becomes a design decision once a brief can be fixed on main while its loop is running. I am recording it so U2's `--check` makes the choice explicitly instead of inheriting it. The help at `:66` ("another open brief … names the same branch") does not say "readable".

**Recommendation:** None needed for U1. In U2, decide whether F31 means "readable open briefs", and say so in the help.

## What Looks Good

- The dependency direction stays clean. build-loop.sh adds no lib edits beyond comments, and every new reader (`main_file`, `marker_kind`, `shared_branches`) is built from lib primitives instead of copying them.
- `marker_kind` now lets git parse the commit object (`rev-list --parents`, `log --format=%B`, `rev-parse ^{tree}`) instead of a hand parser, which removes an object-format coupling (A1). The two-tree-lines test pins this down.
- `main_file` gives `read_settings` one shape, "a file on main through FENCE_AWK plus a program", for both `docs/dev-cycle.md` and `docs/constraints.md`. That is the right extension point for the next settings-like file.
- The output contracts are positional, documented in the help, and kept even for `new` (`new review - absent - - 0`), so U4's parser has one shape per line kind.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Lazy `shared_branches` overwrites `BRIEF` mid-`status_line` on the first call only; `SHARED_BRANCHES` is still a fail-open global for non-`status_line` callers | Coupling | `scripts/build-loop.sh:316-326` | High |
| 2 | Brief-path rule spelled three ways (`${f/closed\//}` trick plus two inline regexes); A4's predicate not added | Minor | `scripts/build-loop.sh:303`, lib `:161`, `:326` | High |
| 3 | Unreadable open briefs are not counted for F31 | Informational | `scripts/build-loop.sh:303` | Medium |

## Overall Assessment

U1c keeps the structure sound. Dependencies run one way into the lib, the new mode reuses the lib's readers, and the output contracts are explicit. c143b929 resolves A4 and A5 as behaviour: `closed/` briefs count, and `--status` can no longer skip F31. Neither is resolved as structure. The fix moves the `shared_branches` call into `status_line`, after the caller's own `brief_fields`, which adds a first-call-only overwrite of the global `BRIEF` (F1). Nothing reads `BRIEF` after that point today, so nothing is wrong now. It matters because U2's `--check` must do F31 and then read `BRIEF[paths]`. Both items can be fixed in place in a few lines: a `branch_shared` predicate called before `brief_fields`, and one `(closed/)?` predicate in the lib. F1 is the most important concern, and it is best fixed now or recorded as a U2 precondition.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved at the output path your task names, structured per your skill, with a `Commit: c143b929` first line.
- Answered: whether A5 and A4 are resolved at c143b929 (resolved as behaviour, not as structure), and whether the fix added coupling (yes, F1: the lazy call overwrites `BRIEF`, shown by an instrumented probe); F2 and F3 cover the rest.
- Out of scope: correctness, security and performance of `marker_kind`/`CONSTRAINTS_AWK` (other critics); the Claim 8 fence/look-alike constraint escalation (security and api critics, plus the orchestrator under Q-112); the performance of `shared_branches` (override rows 266 and 267); a machine-readable CONSTRAINTS value (row 270); the main_entry case-block copies (row 228).
- Escalate: F1 to the orchestrator. Fix it in U1c, or record it as a U2 precondition ("call the F31 predicate before `brief_fields`, or never read `BRIEF` after it"), because U2's `--check` is the first caller that reads `BRIEF` after the F31 check.
