Commit: 722884c7

# Performance Review — feat/build-loop-u1a (U1a, review-fix iteration 3, final confirming pass)

**Scope:** `git diff main...feat/build-loop-u1a -- . ':!docs/reviews'` (scripts/lib/dev-cycle-read.sh, scripts/dev-cycle.sh, skills/dev-cycle/SKILL.md, test/scripts/dev-cycle.bats)
**Date:** 2026-10-05
**Based on:** Stage-1 merged fact-check summary (k=3; `docs/reviews/code-fact-check-report-build-loop-u1a-r1/-r2/-r3.md`, all at 722884c7)

## Data Flow and Hot Paths

The changed code is the shared reader lib's check modes. `scripts/dev-cycle.sh`'s check-mode loop calls them once per argument, a few times per dev cycle, and the user starts those runs by hand. That is a **cold path**. There is no request handler or high-frequency loop. The future U1b/U1c consumers (build-loop.sh `--status`, constraints line) are not part of this diff.

These are the changes since iteration 2 (2da477b7..722884c7, code lines only):

- `main_entry` (dev-cycle-read.sh:258-274): stderr is now dropped, and a `dup` check costs one assoc-array membership test per ls-tree line. Each lookup stays at one `git ls-tree` process over about 49 lines. The extra cost is negligible.
- `brief_fields` (:289-310): checks its own preconditions (A13), `pathform "$1"` and `[[ "$(main_entry "$1")" != blob ]]`. check_brief has already run both on the same path (:323 and :330), so **each check_brief now runs `git ls-tree` twice**.
- `check_answer` (:545-574) and `brief_fields`: a `|| { …; return; }` arm on the `cat-file | awk` pipeline. This adds no work.

I measured in my scratch dir. Each reader came from `git show <rev>:scripts/{dev-cycle.sh,lib/dev-cycle-read.sh}` and was sourced in-process against this repo's main (f6357ea1), with mawk, `LC_ALL=C.UTF-8`, and wall clock from `date +%s%N`. The brief was `docs/working/briefs/2026-10-02-build-loop-handoff.md`.

| Measurement | main's reader | 2da477b7 | 722884c7 |
|---|---|---|---|
| git subcommands per `check_brief` (PATH shim) | cat-file 1, log 1, ls-tree 1 | cat-file 1, log 1, ls-tree 1 | cat-file 1, log 1, **ls-tree 2** |
| `check_brief` × 50 in one process (3 rounds) | 533 / 539 / 580 ms | 626 / 630 / 637 ms | 850 / 886 / 889 ms |
| `check_answer` × 20 archived IDs (3 rounds) | — | 237 / 238 / 243 ms | 238 / 246 / 249 ms |
| `--check-brief` 3 briefs, output md5 | 572dbe66… | 572dbe66… | 572dbe66… |
| `check_answer` 20 IDs, output md5 | — | cce42cc2… | cce42cc2… |

Isolated in the same harness: `x="$(main_entry …)"` takes about 3.3 ms per call (163 to 169 ms per 50, with one 639 ms outlier round), and `brief_fields` takes about 5.2 ms per call (255 to 266 ms per 50).

## Findings

#### check_brief runs main_entry (one `git ls-tree` fork) twice per brief since A13's precondition check in brief_fields

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:292` (brief_fields), called from `:338` after check_brief's own `:330`
**Move:** Count the hidden multiplications
**Classification:** Micro (one redundant fork plus subshell per brief, constant per call) / Cold path (a `--check-brief` CLI run about once per cycle over a handful of briefs; U1c's `--status` will call it once per brief)
**Confidence:** High. The PATH-shim count is exact. The timing comes from 3 rounds of 50.
**Baseline:** 17.0 to 17.8 ms per `check_brief` at 722884c7, against 12.5 to 12.7 ms at 2da477b7 and 10.7 to 11.6 ms on main's reader. These are in-process loops of 50 against this repo's main, measured in the reviewer's scratch dir on 2026-10-05.
**Evidence:**
```
  e="$(main_entry "$a")"
```
(check_brief :330)
```
  if ! brief_fields "$a"; then
```
(check_brief :338; check_brief() continues to :350, and I read it)
```
  if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]; then BRIEF_ODD=error; return 1; fi
```
(brief_fields :292; brief_fields() continues to :310, and I read it)

**Legibility-target:** for-orchestrator-synthesis

check_brief already checks `main_by_name`, `pathform` and `main_entry == blob` before it calls brief_fields. brief_fields then repeats `pathform` and a full `main_entry`, which is a second `$(...)` subshell, a second `git ls-tree -t --full-tree` and a second parse of about 49 lines. The tree is the same at the same `MAIN_SHA`, so the second answer cannot differ. The shim count confirms 2 ls-tree calls per brief, against 1 at 2da477b7 and on main. The measured cost is about +5 ms per brief over iteration 2 and about +6.5 ms over main (about 60%). Most of that is the second ls-tree, which costs about 3.3 ms per call in isolation. Override row 229 (C7, "~2 ms more per brief") settled the iteration-2 delta. This doubled call is new since then (the A13 fix), so that row does not cover it. The cost stays linear in briefs, with a handful of briefs per cycle, so it does not matter today. It would add up only if U1c's `--status`, or a polling loop, ran check_brief for many briefs on every tick.

**Recommendation:** You can keep this as it is (Won't-Fix is reasonable, because A13's self-contained preconditions are a deliberate safety contract). If U1c measures `--status` and wants the 3 ms back, split out an unguarded internal reader, such as `_brief_parse`. brief_fields would call it after its own checks, and check_brief would call it directly after its `main_entry == blob` arm. Re-measure against the 17 ms per brief baseline above.

## Escalations received

None of the Stage-1 escalations is addressed to the performance critic:

- The `--help` range (`sed -n '2,80p'`) is a correctness or doc regression with no runtime cost.
- The pipefail dependency of the R2 fix is a correctness or caller-contract issue.
- main_entry's corruption modes are a correctness issue.

Settled rows that I did not re-raise:

- **201** (check_brief's `git log -G` walk grows with history): the walk is unchanged in this diff. Its revisit trigger is U1's `--status`, which this diff does not contain.
- **213** (need_root fork per brief).
- **220** (`ls-tree -t` lists the children of named directories): still one process per lookup, about 49 entries.
- **C6/228** (each ID re-reads both questions files): measured flat, 237 to 249 ms per 20 IDs at both 2da477b7 and 722884c7.
- **C7/229**: see Finding 1, which covers the new delta only.

I found no new evidence against any of these rows.

## Endorsements

- At 722884c7, main_entry's duplicate-name check adds one assoc-array membership test per ls-tree output line inside the existing read loop. It adds no extra process and no second pass over `$out`. `[read: scripts/lib/dev-cycle-read.sh:258-274]`
- The R2 fixes (`|| { …; return; }` on the `git cat-file | awk` pipelines in check_answer :562-563 and brief_fields :295-302) add no process and no extra read. The pipeline is unchanged and only its exit status is now consulted. `[read: scripts/lib/dev-cycle-read.sh:295-302, :562-563]`
- Claim: on this repo's main at f6357ea1, `check_answer` over 20 archived IDs runs within 5% of 2da477b7's wall clock (237–243 ms vs 238–249 ms) with byte-identical output. `check_brief` at 722884c7 issues exactly 2 `git ls-tree`, 1 `cat-file` and 1 `log` per brief whose main entry is a blob. `[unverified — submitted as claim]` (route: code-fact-check. Probe: a PATH shim on git that logs `$1`, plus the in-process 50× loops described under Data Flow.)

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | check_brief runs main_entry (git ls-tree) twice per brief since brief_fields gained its own preconditions | Informational | `scripts/lib/dev-cycle-read.sh:292` (via `:330`, `:338`) | High |

## Overall Assessment

This change carries no meaningful performance risk. Every changed path is a cold CLI check mode. The iteration-3 fixes are free except one: A13's precondition check in brief_fields makes check_brief look up main's tree twice. That costs about 5 ms more per brief than iteration 2 and about 6.5 ms more than main (17 ms per brief against 11 ms). With a handful of briefs per cycle the cost is negligible, and a later unguarded helper can remove it without weakening A13. check_answer stays level with iteration 2, and its output is unchanged. Nothing needs to be fixed before merge. The one item to carry forward is to measure U1c's `--status`, which calls check_brief per brief (row 201's trigger), against the 17 ms per brief baseline.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u1a/docs/reviews/performance-reviewer-review-2026-10-05-build-loop-u1a.md (overwrite the iteration-2 one), first line `Commit: 722884c7`, structured per the performance-reviewer skill, every finding with Severity, Location, verbatim Evidence, Confidence and Legibility-target, ending with the canonical Goal-Alignment Note.
- Answered: performance review of the full `main...feat/build-loop-u1a` diff at 722884c7, with measured baselines across main's reader, 2da477b7 and 722884c7, including the brief_fields/check_brief double main_entry that the orchestrator asked about. It has one Informational finding and nothing blocking.
- Out of scope: the `--help` sed range regression (correctness, fact-check), the pipefail caller contract, main_entry corruption modes, U1b/U1c consumers, and the bats suite result (not run by this critic).
- Escalate: none. Finding 1 is a forward note for whoever measures U1c's `--status` (row 201's trigger).
