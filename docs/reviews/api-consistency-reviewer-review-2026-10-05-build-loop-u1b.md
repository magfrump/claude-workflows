Commit: 2e711a7b

# API Consistency Review: feat/build-loop-u1b (U1b, review iteration 4 of 4, final confirming pass)

**Scope:** `feat/build-loop-u1a...feat/build-loop-u1b` at 2e711a7b: `scripts/build-loop.sh` (`--settings` and its three output lines, the new policy WHY when self-merge has no valid never line, `-h|--help`, usage errors, exit codes), checked against `scripts/dev-cycle.sh` and the plan's Script interface
**Date:** 2026-10-05
**Based on:** the Stage-1 fact-check summary in the shared Stage-2 context (k=3 reports `docs/reviews/code-fact-check-report-build-loop-u1b-r{1,2,3}.md`, all at 2e711a7b), the plan `docs/working/plan-build-loop-handoff.md` (Script interface :201-204), `docs/reviews/override-log.md` (u1b rows 222-224, 235-248, 256-264)

Probes ran in a throwaway repo under `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i4/api/`, against the worktree's scripts, with `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 LC_ALL=C.UTF-8`. Nothing in the worktree was edited except this report. No process was left running.

## Baseline Conventions

These are unchanged from iteration 3. I re-read `scripts/dev-cycle.sh` :1-126 and the plan at :201-204.

- **Output lines:** each answer is one line, a keyword and its subject, then `: WHY`. The plan fixes the `--settings` shapes at :204: `policy self-merge|review set|unset: WHY`, `slots N set|default: WHY`, `never GLOB… set|none|malformed: WHY`.
- **Help:** `-h|--help` prints the header up to the first line that is not a comment. It uses `sed -n '2,/^[^#]/{/^#/p}' "$0" | sed 's/^# \{0,1\}//'` (dev-cycle.sh:111-112) and exits 0.
- **Errors:** errors go to stderr. A script exits 1 for bad usage, no git repo, no perl or lib, or no default branch found by name. It exits 0 once every line is printed. `rev-parse` failures read `Not inside a git repository` (dev-cycle.sh:118).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--settings` | CLI mode | `--check-path`, `--check-brief`, `--check-answer` | `scripts/dev-cycle.sh:8-14`; plan :204 | Consistent |
| `-h` / `--help` | CLI flag | dev-cycle.sh `-h\|--help` | `scripts/dev-cycle.sh:112` | Consistent. The help idiom is now byte-identical to dev-cycle.sh's. The output is 37 lines and ends at the Exit line. |
| `policy … set\|unset: WHY` | output line | plan :204 | `docs/working/plan-build-loop-handoff.md:204` | Consistent |
| `policy review unset: line N reads self-merge, but there is no valid Self-merge never: line ("Self-merge never: none" for an empty list), so self-merge is off` | WHY text (new) | `line N is not exactly "…"` WHYs | `scripts/build-loop.sh:180-182` (the other policy WHYs) | Consistent. It keeps the `line N …` lead, and its first colon is still the one after `unset`, so the "word before the first colon" reading (row 248) holds. It also names the fix (`Self-merge never: none`). |
| `slots N set\|default: WHY` | output line | plan :204 | same | Consistent |
| `never GLOB… set\|none\|malformed: WHY` | output line | plan :204 | same | Consistent (settled as row 248) |
| `… (usage: build-loop.sh --settings)` | usage error | `Unknown option: X` | `scripts/dev-cycle.sh:113` | Accepted at iteration 3 (F4/C7). Already carried forward: U1c (c143b929) reads `(usage: build-loop.sh --settings \| --status BRIEF...)`. |

## Iteration-3 items re-checked at 2e711a7b

| Item | Status at 2e711a7b |
|---|---|
| F1 → R4 (letter-bearing markup hides a copy) | Settled as override row 256 (Q-112 [1]). Its premise holds: no hidden shape raises the policy or adds self-merge, and all three fact-check replicates executed this. I did not re-raise it. One wording residue remains (Finding 3). |
| F2 → plan :74 says "pathform globs" | Settled as row 262 (Defer to U5). |
| F3 → A20 (header "leaves the default") | **Fixed.** Header :11-12 now says "gives review, 3 and malformed (WHY says which)", which matches the code at :143 and :153. |
| F4 → C7 (usage suffix goes stale) | **Resolved downstream.** U1c's `usage()` lists `--status`, and nothing goes stale in this unit. |
| F5 → C5 (empty `NEVER` is ambiguous) | Settled as override row 261. Its premise holds: `POLICY=self-merge` is set only when `never_ok=1` (:172-173, :179-181), so an empty `NEVER` under self-merge means `none`. |
| Row 239 (`--help prints a fixed line range`, Won't-Fix) | **Premise changed, as FC r3 said, and in the item's favour.** :57 now uses dev-cycle.sh's first-non-comment-line idiom, so the issue is fixed rather than waived. The row's Resolution text ("Won't-Fix … each edit re-derives the range") is now inaccurate. I am noting this, not filing a finding (Finding 4). |

## Findings

#### 1. A non-decimal `GIT_CONFIG_COUNT` (`08`) prints a bash error to stderr, skips the replace-ref guard, and still exits 0

**Severity:** Minor
**Location:** `scripts/build-loop.sh:69`, `scripts/build-loop.sh:37-38`
**Move:** 4 (error consistency) / 3 (documented exit contract)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Evidence (`scripts/build-loop.sh:69`):
```
cfg="${GIT_CONFIG_COUNT:-0}"; export "GIT_CONFIG_KEY_$cfg=core.useReplaceRefs" "GIT_CONFIG_VALUE_$cfg=false" GIT_CONFIG_COUNT=$((cfg + 1))
```
Evidence (`scripts/build-loop.sh:37-38`, the header's Exit line):
```
# Exit: 0 every line printed (or help); 1 bad usage, not a git repo, no perl or
# lib/dev-cycle-read.sh, or no default branch found by name.
```
Probe: I exported `GIT_CONFIG_KEY_0..9` and set `GIT_CONFIG_COUNT=08`. Output:
```
…/scripts/build-loop.sh: line 69: 08: value too great for base (error token is "08")
policy self-merge set: line 1 of docs/dev-cycle.md on the default branch
…
exit 0
```
The arithmetic expansion fails, the `export` is abandoned, and `set -e` does not stop the script. The run then exits 0 with all three lines. A consumer that checks only the exit status cannot tell that the guard was skipped. With `010`, bash reads octal 8 and exports the pair at index `010`, which git never reads; that run exits 0 silently. The safety question (is the caller's environment trusted?) belongs to E1 and security-reviewer. The API point here is narrower: under the header's Exit line, a run that printed an error should not exit 0.

**Recommendation:** Before `rev-parse` (:62), validate the count and exit 1 with its own reason, for example `[[ "${GIT_CONFIG_COUNT:-0}" =~ ^(0|[1-9][0-9]{0,3})$ ]] || { echo "GIT_CONFIG_COUNT is not a decimal count" >&2; exit 1; }`. Then add "a bad GIT_CONFIG_COUNT" to the Exit line. This one change also resolves Finding 2.

#### 2. E2: a malformed `GIT_CONFIG_COUNT` reports "Not inside a git repository" (wrong reason, fails closed)

**Severity:** Informational
**Location:** `scripts/build-loop.sh:62`
**Move:** 4 (error consistency)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Precedent: `ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Not inside a git repository" >&2; exit 1; }` used in `scripts/dev-cycle.sh:118`

Evidence (`scripts/build-loop.sh:62`):
```
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Not inside a git repository" >&2; exit 1; }
```
I probed inside a valid repo. `GIT_CONFIG_COUNT` = `abc`, `-1`, and `08`/`010` (with no keys set) each gave `Not inside a git repository` with exit 1. Git's own message (`error: bogus count in GIT_CONFIG_COUNT` / `fatal: unable to parse command-line config`) is discarded by `2>/dev/null`. `dev-cycle.sh --check-path` gives the identical message for `abc`. The behaviour therefore matches the sibling script, and it fails closed. The cause is the caller's environment, not the new guard: git rejects the bad count before line 69 runs. Only the stated reason is misleading.

**Recommendation:** No change is required for consistency. If Finding 1's check is added before :62, it gives this case its own reason as well. Otherwise, accept this as the shared dev-cycle.sh behaviour.

#### 3. The header says a markup-hidden never list "turns [self-merge] off rather than being skipped"; that is true only when it is the sole never-like line

**Severity:** Minor
**Location:** `scripts/build-loop.sh:15-17` (and the T45 comment in `test/scripts/build-loop-read.bats`, "A never list hidden in markup turns self-merge off rather than being skipped")
**Move:** 3 (documented vs actual contract)
**Confidence:** High
**Legibility-target:** for-author

Evidence (`scripts/build-loop.sh:14-17`):
```
#                 Set only by "Build-loop policy: self-merge" or "...: review",
#                 exactly (one trailing CR dropped); else review. Self-merge
#                 also needs a valid never line, so a list hidden in markup
#                 turns it off rather than being skipped.
```
The behaviour is settled: under row 256, a hidden copy next to an exact `Self-merge never:` line is ignored and the exact line governs. Fact-check r1 and r3 rate this sentence Mostly accurate for that reason. The header is the contract a `docs/dev-cycle.md` editor reads. "Rather than being skipped" says a hidden list is never skipped, but it is skipped whenever an exact never line also exists. :28-31 does state best effort, so the two passages read as inconsistent, not wrong. This is wording only. The behaviour is not re-raised.

**Recommendation:** Change "so a list hidden in markup turns it off rather than being skipped" to "so a never list hidden in markup, with no exact line beside it, turns it off".

#### 4. Override row 239 now records the help-range item as Won't-Fix, but it was fixed

**Severity:** Informational
**Location:** `docs/reviews/override-log.md:239`; `scripts/build-loop.sh:57`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Evidence (`docs/reviews/override-log.md:239`):
```
| 2026-10-05 | `feat/build-loop-u1b` | --help prints a fixed line range (architecture M3; C5) | 🟢 Consider | Won't-Fix | Same as dev-cycle.sh; each edit re-derives the range, and help is checked by hand. |
```
Evidence (`scripts/build-loop.sh:57`):
```
  -h|--help) sed -n '2,/^[^#]/{/^#/p}' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;  # the header, to its first non-comment line
```
The code now matches dev-cycle.sh:112, which is better than the row says. A later reader of the log would think the fixed range still ships.

**Recommendation:** Optionally append "(fixed in 2e711a7b: first-non-comment-line idiom, as dev-cycle.sh:112)" to the row's rationale. The orchestrator owns the log.

## What Looks Good

- **The three lines match plan :204 exactly.** Their order (policy, slots, never), their status words, and the `: WHY` tail all match, and the order is pinned by the bats test "prints its three lines in order".
- **The new self-merge WHY is actionable.** It names the line it refused (`line N reads self-merge`) and the exact text that would satisfy it (`"Self-merge never: none" for an empty list`). It also keeps the `line N …` lead used by the other unset WHYs.
- **The header now matches the output for every fail-closed path.** A second copy or a refused file gives review, 3 and malformed. An absent file gives `never none`, and T3 pins that.
- **Help and the repo error match dev-cycle.sh byte for byte.** Usage errors go to stderr with exit 1 and nothing on stdout, and the bats test covers `""`, `--bogus`, `--settings extra` and `--status`.
- **The usage suffix is already extended in U1c.**

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `GIT_CONFIG_COUNT=08` prints a bash error, skips the guard, exits 0 (`010` exits 0 silently) | Minor | `scripts/build-loop.sh:69`, `:37-38` | High |
| 2 | E2: malformed `GIT_CONFIG_COUNT` reads "Not inside a git repository" (same as dev-cycle.sh:118; fails closed) | Informational | `scripts/build-loop.sh:62` | High |
| 3 | Header :16-17 "rather than being skipped" holds only when the hidden list is the sole never-like line | Minor | `scripts/build-loop.sh:15-17`; bats T45 comment | High |
| 4 | Override row 239 says Won't-Fix for an item now fixed | Informational | `docs/reviews/override-log.md:239` | High |

## Overall Assessment

The `--settings` surface is consistent with the plan's Script interface and with dev-cycle.sh's conventions for help, usage errors and repo errors. The iteration-3 api items are fixed (F3/A20), resolved downstream (F4/C7), or settled with their premise intact (F1/row 256, F2/row 262, F5/row 261). Row 239 changed in the item's favour. Nothing breaks a consumer, and both Minor findings are fixable in place. Finding 1 is the only one that touches the exit contract: one line validating `GIT_CONFIG_COUNT` before `rev-parse` would close it and give E2 an accurate reason. Whether it is needed depends on E1's ruling on the caller's environment. Finding 3 is a one-phrase header edit. I see no blocker for landing U1b from the API-consistency side.

## Goal-Alignment Note

Success criterion: "A report saved at the output path named in your tail, structured per your skill, covering the full unit diff at 2e711a7b."

This report is saved at `docs/reviews/api-consistency-reviewer-review-2026-10-05-build-loop-u1b.md`, with `Commit: 2e711a7b` as its first line. It covers the whole unit diff's public surface: `scripts/build-loop.sh` header, parsing, help, errors, exit codes and the three output lines. The test file and fixture were read as contract evidence, and the override-log rows were read as the settled filter. Every section the skill requires is present (Baseline, Name-Pattern Audit, Findings, What Looks Good, Summary Table, Overall Assessment). It also re-checks the iteration-3 items and answers E2.
