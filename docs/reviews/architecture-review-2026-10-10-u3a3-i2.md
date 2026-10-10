Commit: e25a6e89

# Architecture Review — feat/build-loop-u3a3 (iteration 2, loop pass)

**Scope:** `git diff a7a4f784..HEAD` (the iteration-1 fix commit e25a6e89 only): `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-merge.bats` (evidence only). PARTIAL SCOPE: 18f32952 and a7a4f784 were reviewed in iteration 1 and are read here as context only.
**Date:** 2026-10-10
**Based on:** `docs/reviews/code-fact-check-report-u3a3-i2.md` (Commit: e25a6e89; 13 verified, 1 mostly accurate, no code defects)

**Scope check:** in scope. The diff changes a shared lib constant consumed by two modules (`GATE_CODE`, now read by the lib's `floor` and by build-loop.sh's `check_line` → `VERDICT[gate]` → `approval`), renames a lib global (`ANSWER_HEAD` → `ANSWER_HEADING`), and amends the lib's caller contract (header capture rule). The rubric rows deferred in iteration 1 (C1 heading producer, C8, C9, C10, C12) are not re-raised.

**Trust-boundary cross-reference:** newest security review is `docs/reviews/security-review-2026-10-10-u3a3-i1.md` (Commit: `a7a4f784`, the review base of this range; it predates e25a6e89, so boundaries may be slightly stale). `GATE_CODE` sits on two of its boundaries: `B3` (VERDICT[gate] decides the `merge-gate-` slug approval compares) and `B4` (floor's word under self-merge). The finding below does not recommend moving either crossing.

## Iteration-1 findings: status

| i1 finding | Rubric row | Status at e25a6e89 | Evidence |
|---|---|---|---|
| F2 lib header's single capture rule vs ANSWER_HEAD | A2 | **Resolved** | `scripts/lib/dev-cycle-read.sh:35-38`: "A caller that also reads ANSWER_HEADING (check_answer's side value: the entry's heading) runs check_answer in its own shell, its output to a file under set -e, since a $(...) would drop the value; check_answer reaches no need_root (it reads only git objects), so nothing exits there." The exception now sits directly after the rule it qualifies, and fact-check Claim 9 verified the no-need_root clause by call graph and probe P2. |
| F3 authority keyed two ways in land | A3 | **Resolved (as scoped by the rubric)** | `scripts/build-loop.sh:1177`: `[[ "$1" != approved ]] \|\| printf 'Build-loop-approved: %s\n' "$2"; }` now matches `:1110` `[[ "$1" != approved ]] \|\| what="approved merge"`. Message, reflog and trailer all key on `$1`; `$2` is only a value. The other half of F3 (check_line reads the `AUTH` global, land takes an argument) was not taken up; the rubric marked A3 Fixed on the trailer alone, and both channels derive from the single assignment at `:1217`, so the two cannot disagree in practice. Not re-raised. |
| F4 floor comment pointed callers at FLOOR_WHY==gate | C4 | **Resolved** | `scripts/lib/dev-cycle-read.sh:1933-1935`: "Its gate word is no test of whether a merge touches gate code (floor runs after the rules before it, and not at all under --approved): test GATE_CODE for that." Fact-check Claim 12 / probe P1 shows why this matters: `skills/dev-cycle/SKILL.md` gets `instr`, not `gate`. |
| F5 plan D4 vs D5 gate lists | C11 | **Code side resolved; plan side still pending** | `GATE_CODE` now includes `^skills/dev-cycle/` (D4's list). Plan D5 item 3 (`docs/working/plan-build-loop-handoff.md:71`) still lists the scripts alone; the rubric routes that to "plan D5 note at merge". See F1 below for the structural consequence. |

## Dependency Map

- `scripts/build-loop.sh` → `scripts/lib/dev-cycle-read.sh`; direction unchanged and correct. No lib function reads a build-loop global.
- `GATE_CODE` (lib constant) has exactly two readers (fact-check Claim 11, grep): the lib's `floor` (`dev-cycle-read.sh:1955`, self-merge S rules only, reached via build-loop's `srules`) and build-loop's `check_line` (`build-loop.sh:1047`, every run, consumed only by `approval` through `VERDICT[gate]`).
- `ANSWER_HEADING`: written by the lib's `check_answer`, read only by build-loop's `approval` (`build-loop.sh:1090`). The capture rule for that side channel is now part of the lib's documented caller contract.
- Authority: one assignment (`build-loop.sh:1217`) → `AUTH` global read by `check_line` (`:988`) and by the merge arm (`:1223-1224`); passed to `land` as `$1`, which alone keys message, reflog and trailer.

## Findings

#### F1. GATE_CODE now carries two policies with different rationales, and its first comment line no longer fits the new alternative

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1918-1923` (GATE_CODE and comment), `:1924` (floor header "plan D5 items 1-4"), `:1955` (floor's use); `scripts/build-loop.sh:1047` (check_line's use); `docs/working/plan-build-loop-handoff.md:61` (D4), `:71` (D5 item 3), `:77` (D6)
**Move:** 2 (responsibility boundaries), 7 (coupling surface)
**Confidence:** Medium
**Legibility-target:** for-author

Evidence:
```
# The gate's own code: main's copy runs the next merge (plan D6), so a change
# to it lands only through a merge-gate- review entry, never a self-merge.
# The dev-cycle skill counts too (plan D4, F52): it carries the D6 snippet
# that copies and runs the gate. One list for floor and build-loop.sh's
# --approved, which tests it on its own (floor does not run there).
GATE_CODE='^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/'
```
Plan D5 (floor) admits only paths that "**take effect on merge with no later review**", item 3 listing "`scripts/build-loop.sh`, `scripts/dev-cycle.sh`, `scripts/questions.sh`, `scripts/lib/dev-cycle-read.sh`. D6 runs main's copy, so it is live at the next merge." Plan D6: "The snippet is inline in the installed SKILL.md, which is the root-owned image copy." Plan D5 "In this repo": "Code such as scripts, skills, hooks and guides reaches running sessions only through a release you cut".

The two consumers answer different questions. The floor asks "does this path take effect on merge with no later review?" (D5). The `merge-gate-` slug asks "does this change touch the gate's own files, so the human should see a distinct entry?" (D4, F52). For the `scripts/` alternatives the answers coincide. For `skills/dev-cycle/` they do not. Main's copy of the skill does not run the next merge: D6 runs the installed image copy, which changes only at a release. So the comment's opening rationale ("main's copy runs the next merge (plan D6)") is false for the alternative just added. The added sentence gives a different reason (F52) that justifies the slug but not the floor. The floor header still says "plan D5 items 1-4" while enforcing a list wider than item 3. Today this fails safe: the floor refuses more under self-merge, which sends the change to review, and `skills/dev-cycle/SKILL.md` was already refused as `instr`. The cost is in how the code can evolve. The two policies are bound through one constant, so a later edit made for one reason (for example, adding a D4-only gate file such as a hook the snippet sources, or removing a path D5 no longer considers live on merge) silently changes the other. No floor test names a `skills/dev-cycle/` path (fact-check Claim 14 scope note), so a later split or narrowing of the list would go unnoticed on the floor side. The commit message admits the divergence ("stricter than plan D5 item 3, which lists the scripts alone"), but the code does not.

**Recommendation:** Keep the one list (it is the simpler, fail-safe choice, and splitting it would make `B3` and `B4` diverge). Make the coupling explicit where a maintainer will see it. Reword the comment's first sentence so it covers both reasons, for example: "a change to the gate's own files needs a merge-gate- entry (D4, F52); the floor refuses them under self-merge too, which is stricter than D5 item 3 for skills/dev-cycle/, whose copy runs only after a release." When the plan note lands at merge (rubric C11), update D5 item 3 to name `GATE_CODE`'s list. Optionally add one floor case for `skills/dev-cycle/references/x.md` → `gate` to `build-loop-check.bats`, so the stricter behavior is pinned rather than incidental.
**Security implication:** none if the list stays single. A future split would let `B3`'s gate bit and `B4`'s floor word disagree on the same path; route any split through a combined architecture/security review.

#### F2. The header's gate-file list is now a third copy of GATE_CODE's alternatives

**Severity:** Informational
**Location:** `scripts/build-loop.sh:229-233`
**Move:** 7 (coupling surface)
**Confidence:** High
**Legibility-target:** for-author

Evidence:
```
#                 lower-cased, is the gate's own code (scripts/build-loop.sh,
#                 dev-cycle.sh, questions.sh, anything under scripts/lib/ or
#                 skills/dev-cycle/). The heading pins only TIP's prefix:
```
The fix updated three places by hand: the regex, the lib comment and this header. All three agree today (fact-check Claim 2). The plan has a fourth copy at D4 and a fifth at D5. This is the drift that produced iteration-1 R1, where D4 and the regex disagreed. Iteration 1's F4 already suggested naming `GATE_CODE` next to the prose list as optional, so this is a reminder, not a new defect.

**Recommendation:** Optional: append "(GATE_CODE in the lib)" to the header's parenthesis, so a reader updating either one finds the other.

## What Looks Good

- **One authority value, one key.** After the trailer fix, `land` derives everything authority-dependent from `$1`, and `$1` comes from the single `AUTH` assignment. The message, reflog and trailer can no longer disagree.
- **The capture exception lives in the contract, not only at the call site.** The lib header now states when a caller may break the `out="$(...)"` rule, and why that is safe (no `need_root` on check_answer's path). A future second reader of `ANSWER_HEADING` has a documented pattern, so it does not have to copy approval's comment.
- **approval's refusals map onto check_answer's vocabulary one to one** (`keep`/`open`/`skip`/`drop`/`done`, with `unrecognized` the only catch-all; fact-check Claim 4). The caller no longer collapses the lib's words, so the boundary stays transparent.
- **floor's comment now steers callers to the right abstraction** (`GATE_CODE`, not a side effect of the floor's rule order).
- **The rename is complete** across code, tests and the shellcheck note (fact-check Claim 13).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | GATE_CODE carries two policies (D5 floor, D4 slug) with different rationales; first comment line false for `skills/dev-cycle/`; floor side unpinned | Minor | `scripts/lib/dev-cycle-read.sh:1918-1924` | Medium |
| 2 | Header gate-file list is a hand-kept copy of GATE_CODE | Informational | `scripts/build-loop.sh:229-233` | High |

## Overall Assessment

e25a6e89 keeps the structure intact and resolves what it set out to fix. F2 (lib capture exception), F3 (as the rubric scoped it: one key in land) and F4 (floor comment) are resolved. F5 is resolved in code, with the plan note still pending at merge. The one structural point this pass raises is a consequence of the R1 fix. Widening `GATE_CODE` to `skills/dev-cycle/` made one constant serve two policies that agree on the scripts but not on the skill: the D4 slug wants it, and the D5 floor's "live on merge" reason does not hold for it. Keeping one list is the right call, because it fails safe and keeps `B3` and `B4` aligned. But the comment still gives only the D5/D6 reason, and nothing pins the floor's new refusal. The fix is in place and small: a comment reword, the already-planned D5 note, and optionally one floor test. Nothing calls for restructuring.

## Goal-Alignment Note

Success criterion (verbatim): "a report saved to /workspace/.claude/wt-build-loop-u3a3/docs/reviews/architecture-review-2026-10-10-u3a3-i2.md, structured per the architecture-review skill (Structural / Coupling / Minor / Informational), with `Commit: e25a6e89` at the top."

This report is saved at that path, opens with `Commit: e25a6e89`, and follows the skill's structure: header, Dependency Map, Findings with severity tiers, What Looks Good, Summary Table, Overall Assessment. It adds an iteration-1 status table for the focus items F2, F3, F4 (and F5). It assesses GATE_CODE's cohesion across scripts/ and skills/ against plan D4, D5 item 3 and D6, which F1 covers. Deferred rubric rows (C1, C8, C9, C10, C12) are not re-raised. No probes were run (static review on top of the fact-check's executed evidence). Nothing was committed.
