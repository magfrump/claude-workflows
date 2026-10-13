Commit: 4e14d1cc

# API Consistency Review — feat/build-loop-u4a, iteration 2 (fix range)

**Scope:** Partial scope: the fix range 722c2e10..4e14d1cc (70d24331, c0cafb66, 4e14d1cc) in `scripts/build-loop.sh`, `test/scripts/build-loop-orchestrator.bats` and `docs/working/plan-build-loop-handoff.md`; 722c2e10 is context only. Public surface judged: `--land-cycle --main SHA`, its usage and refusal text, the `landed` line's documentation, `--cycle-diff`'s new refusal lines, the plan's new "Script interface" bullet.
**Date:** 2026-10-13
**Based on:** `docs/reviews/code-fact-check-report-2026-10-13-u4a-i2.md` (reused: claims 1, 3, 4b, 6-9, 11, 13, 20; its executed probes E3/E4 stand in for mine: no probe of my own ran, so nothing under `/tmp/u4a-api2-` exists)

## Baseline Conventions

Surveyed `scripts/build-loop.sh` (header :6-262, parser :524-545, `deny_why`-style wording :1140-1156, `--check`'s CAS refusal :1354, cycle_rules/asked_rule/land_cycle :1868-2037), `scripts/dev-cycle.sh:184-197` (`--check-fix`), `scripts/lib/dev-cycle-read.sh:1905-1922` (truthrule) and the plan's "Script interface" (:192-222):

- **Value flags are named for their referent or placeholder:** `--expect SHA` (a branch tip, :1354), `--approved Q-NNN`, `--answered Q-NNN`, `--dir DIR`. Full 40/64-hex ids only, checked as a usage error (exit 1).
- **CAS refusals** name actual then given: `refuse BRIEF: the tip of BR is SHA, not the expected EXPECT` (:1354).
- **Refusal lines** are `refuse SUBJECT: WHY`, SUBJECT a path, `HEAD`, `index`, `state WHAT` or a brief; WHY is prose for a reader. cycle_rules prints every per-path finding (`bad=1; continue`) and returns early only on whole-file questions failures.
- **truthrule's class words are internal:** the lib says "Each caller words the words and adds its own rules" (`scripts/lib/dev-cycle-read.sh:1911`); `--check` maps them to prose ("one of the dev cycle's own files", "the user's constraints doc, which every loop prompt carries", :1148-1149), and `--check-fix` prints one prose list of the classes (`scripts/dev-cycle.sh:192`).
- **Plan layout:** "Read modes:", "Gate:" (`--check`, `--merge`, the writing pair), "Dispatch:"; and "read modes exit 0 when every argument was answered; writing modes exit 2 on any refusal" (:196-198).

## Iteration 1 findings: resolution

| i1 # | Finding | Status in 4e14d1cc | Evidence |
|---|---|---|---|
| 1 | `--expect` meant main under `--land-cycle`, the tip under `--check`/`--merge` | Resolved | Parser :537 takes `--main` only for land-cycle; `--expect` there is a usage error (fact-check claim 1, E4 L3). Header :235-237 "--main the default branch's commit (the one --cycle-diff checked; --merge's --expect is a branch tip instead)". |
| 2 | Shared refusals said "index" under `--land-cycle`; "(PATH a file)" | Resolved | `refuse index: the questions files could not be listed` moved into `cycle_diff` (:1887); `k="$side"` gives "its merge copy" (claim 8, E4 L2); header :252-253 "(PATH a file; a copy of the merge is "its merge copy")". No `refuse index:` line is reachable from land_cycle (grep of :1903-2037). |
| 3 | Header refusal list omitted read failures | Resolved | :259-260 "or a read that fails (HEAD's commit, the merge, its paths)" (claim 9). |
| 4 | `landed` fields and reflog under-documented | Resolved | :248-251 defines B, HEAD, TREE, NEW and the reflog "build-loop: cycle land of B" (claim 7, executed); function comment :2003 now says "landed B HEAD TREE NEW". |
| 5 | Plan lacked a `--land-cycle` bullet; `entry` line absent | Resolved | Plan :210 adds the bullet; the U4a As-built note (:339) records that row 674's `entry` line and rows 680/683 moved to U4b, with the reason. (Placement of the bullet: Finding 2 below.) |
| 6 | Collapsed usage message | Kept (as recommended, reworded with the rename) | :540 "--land-cycle takes --main SHA (the default branch's full commit id), once, and --answered Q-NNN, one ID each". |
| 7 | `--cycle-diff` narrows; U4b documents | Carried to U4b (not this range) | — |

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--main SHA` (under `--land-cycle`) | CLI flag | `--expect SHA`, `--dir DIR`, `--approved Q-NNN` | `scripts/build-loop.sh:11-15, 524` | Consistent — named for what it binds, as i1 asked; no collision with the `--main-log` mode in parsing (it is accepted only after `--land-cycle`). The internal `store_check --main` (:1061) is a private function flag, not surface. |
| `refuse HEAD: the default branch is at X, not --main's Y; ... land with --main X` | refusal text | `refuse BRIEF: the tip of BR is X, not the expected Y` | `scripts/build-loop.sh:1354` | Consistent — actual, then given; and the remedy now names the flag and value to retry with. |
| usage `--land-cycle needs --main SHA, the default branch's commit --cycle-diff checked` | usage text | `--main-log takes one full 40- or 64-hex commit id` | `scripts/build-loop.sh:533` | Consistent |
| SIDE `index` / `merge`, "its merge copy" | refusal word | "its base copy", "its index copy" | `scripts/build-loop.sh:1955-1956` | Consistent — same slot, a word true for each mode |
| `refuse PATH: a file sessions or later cycles read as truth (WORD); an in-cycle fix edits only docs --check-fix allows` | refusal text | `refuse PATH: the gate's own code; an in-cycle fix ...`; `--check`'s worded DENY; `--check-fix`'s prose list | `scripts/build-loop.sh:1148-1149, 1912`; `scripts/dev-cycle.sh:192` | Shape consistent with its GATE_CODE sibling; prints truthrule's raw class word: Finding 1 |
| `refuse PATH: its Asked: line adds X, which names no question entry this change files` | refusal text | `refuse PATH: its first Asked: line drops or changes an ID it held; ...` | `scripts/build-loop.sh:1990` | Mostly consistent; empty-item and "first" wording: Finding 3 |
| `refuse PATH: deleted or renamed with its Asked: line; the cycle only moves a brief to closed/ under its name` | refusal text | `refuse PATH: it is deleted` (roadmap, idea log) | `scripts/build-loop.sh:1928` | Consistent — path subject, cause then the allowed move |
| `chore_msg`, `asked_rule`, `LAND_MAIN` | internal names | `gate_msg`, `cycle_rules`/`chore_record`, `EXPECT`/`APPROVED` | `scripts/build-loop.sh:1450-1456, 1730, 524-525` | Consistent — `chore_msg` pairs with `gate_msg` |

## Findings

#### 1. The truth-file refusal prints truthrule's internal class word instead of wording it

**Severity:** Minor
**Location:** `scripts/build-loop.sh:1913`; pinned by `test/scripts/build-loop-orchestrator.bats:324-326`
**Move:** 4 (error consistency), 2 (naming)
**Confidence:** High
**Legibility-target:** for-consumer (the orchestrator reading a refusal, and U4b's SKILL.md author)

Precedent: each caller words truthrule's class words, used in `scripts/lib/dev-cycle-read.sh:1911` ("Each caller words the words and adds its own rules"), `scripts/build-loop.sh:1147-1150` and `scripts/dev-cycle.sh:192`

Evidence (verbatim): `echo "refuse $p: a file sessions or later cycles read as truth ($TRUTH_WHY); an in-cycle fix edits only docs --check-fix allows"`; the test pins `refuse AGENTS.md: ... (instr)` and `refuse docs/dev-cycle.md: ... (settings)`. The words `instr`, `dot`, `settings`, `user` and `record` are the lib's private enum; the header (:218-221) describes the classes by file ("an instruction or prompt file, a dot path, docs/dev-cycle.md, ...") but never maps them to these words, and `settings` for `docs/dev-cycle.md` or `record` for `docs/human-author/` is not self-explanatory. `--check` and `--check-fix`, refusing the same paths, print prose. A consumer gets a third vocabulary for one rule, and the test now freezes the enum as output.

**Recommendation:** Word the class as `--check` does (a short `case "$TRUTH_WHY"` to prose: "an instruction or prompt file", "a dot path", "the dev cycle's settings", "the user's constraints doc", "a decision record"), or drop the parenthetical; update the test strings with it.

#### 2. The plan files `--land-cycle` under "Read modes:", though it moves main

**Severity:** Minor
**Location:** `docs/working/plan-build-loop-handoff.md:210`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-author

Precedent: the writing mode that lands a branch, `--merge`, is listed under "Gate:" in `docs/working/plan-build-loop-handoff.md:213-215`; the plan's exit rule distinguishes "read modes" from "writing modes" (:197-198)

Evidence (verbatim): the bullet follows `--cycle-diff` in the "Read modes:" list: "`--land-cycle --main SHA [--answered Q-…]` (U4a; gated) → `landed B HEAD TREE NEW`, or `refuse HEAD: why` / `refuse PATH: why` (exit 2): lands the orchestrator's committed ... HEAD ... then `--merge`'s move (D7, D13)". The bullet's own text calls it gated and a land, and its exit-2 behaviour is the writing-mode rule. A reader skimming the section headings for what can move main would miss it. The bullet's content is otherwise accurate (refusal subjects are `HEAD` and paths only, which matches the code now that `refuse index:` is `--cycle-diff`'s alone).

**Recommendation:** Move the bullet to "Gate:" after `--merge` (or add a "Cycle:" group holding `--cycle-diff` and `--land-cycle`).

#### 3. Asked: refusals: an empty item prints as "adds , which", and "first" is dropped in the new line

**Severity:** Minor
**Location:** `scripts/build-loop.sh:1988-1996`; header :223-224
**Move:** 4 (error consistency)
**Confidence:** High (fact-check claim 3, executed E3 P6)
**Legibility-target:** for-consumer

Precedent: the sibling refusal says "its first Asked: line" in `scripts/build-loop.sh:1990`, matching the header's "A brief's first unfenced "Asked:" line" (:222)

Evidence (verbatim): E3 P6, a new brief with a bare `Asked:` line: `refuse docs/working/briefs/2026-10-02-y.md: its Asked: line adds , which names no question entry this change files`. The same empty item arises from a trailing `", "` on an extension. The header says "(none on BASE: any line)", so a caller reading the contract expects a bare line to pass. The new line also says "its Asked: line" where its sibling and the header say "first", the line the rule actually judges.

**Recommendation:** Say "an empty item" when `$x` is empty (or refuse a bare/trailing-separator line with its own WHY), write "its first Asked: line adds ...", and make the header "any non-empty line". (The unanchored item form, fact-check claim 4b, is known and slated for its own fix; when it is anchored, the refusal for a malformed item should name the expected form, `Q-NNN` or `Q-NNN@SHA`, rather than "names no question entry".)

#### 4. The moved questions guard now hides `--cycle-diff`'s other refusals for that run

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1879-1891`
**Move:** 4 (error consistency), 3 (subtle behaviour change)
**Confidence:** High (fact-check claim 11, executed E3 P7)
**Legibility-target:** for-author

Evidence: on 722c2e10, a run with a gate-code path and a questions change while main changed the questions files printed `refuse scripts/lib/a.sh: the gate's own code; ...` then the guard line; on 4e14d1cc it prints only the guard line (exit 2 both times). cycle_rules' convention is one line per per-path finding in a run; the guard now returns before any of them, so the caller learns of the rest only after merging main and running again. The verdict is unchanged and no consumer exists yet (U4b), so this is a wording/UX shift, not a break; the header (:202-205) does not say the guard pre-empts the other rules.

**Recommendation:** Either run `cycle_rules` and then the guard (print both, keep exit 2), or add "(alone: merge main first, then the other rules run)" to the header so U4b's text sets the expectation.

#### 5. The plan's `--cycle-diff` bullet does not name row 745's rules

**Severity:** Informational
**Location:** `docs/working/plan-build-loop-handoff.md:209`, D13 "Before the chore commit" (:104)
**Move:** 3 (documentation drift)
**Confidence:** Medium (the header is the contract; the plan bullets summarise, and U4b may restate these)
**Legibility-target:** for-author

Evidence (verbatim): ":209 `--cycle-diff [--answered Q-…]` → `ok`, or `refuse PATH: why` (exit 2); run in the orchestrator's worktree against the fork point of HEAD and `MAIN_SHA` (U3c)." The U4a As-built note (:339) records the new rules, but the interface bullet and D13 still describe `--cycle-diff` as judging only questions, roadmap and idea log; it now also refuses GATE_CODE paths, truth files, and Asked: changes, and `refuse HEAD`/`refuse index` subjects exist besides PATH.

**Recommendation:** One clause on the :209 bullet ("also refuses the gate's code, truth files but the cycle's own, and Asked: lines other than extended by new entries (U4a)"), or leave to U4b and say so in its brief.

## What Looks Good

- `--main SHA` resolves i1's main inconsistency cleanly: the flag names its referent, the header contrasts it with `--merge`'s `--expect`, `--expect` given to `--land-cycle` is a usage error rather than a silent reinterpretation, and every test call moved with it.
- The CAS refusal now tells the caller exactly how to retry (`land with --main $MAIN_SHA`), parallel to `--check`'s actual-then-expected shape.
- SIDE makes the shared rules' wording true in both modes ("its index copy" / "its merge copy") without forking the refusal set; the header documents it.
- `landed B HEAD TREE NEW` is now documented to `merged`'s level (fields, parent order, reflog text), and the function comment uses the same placeholders.
- `chore_msg` pairs with `gate_msg` as the single writer of a message `--main-log` reads back.
- The new refusals keep the path subject and the cause-then-allowed-action shape of their siblings ("...; the cycle only moves a brief to closed/ under its name").

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Truth-file refusal prints truthrule's raw class word (`instr`, `settings`, ...) where `--check`/`--check-fix` word it | Minor | `scripts/build-loop.sh:1913` | High |
| 2 | Plan lists `--land-cycle` under "Read modes:"; `--merge` is under "Gate:" | Minor | `docs/working/plan-build-loop-handoff.md:210` | High |
| 3 | Asked: refusal prints "adds , which" for an empty item; drops "first" | Minor | `scripts/build-loop.sh:1988-1996`, header :223-224 | High |
| 4 | Moved questions guard pre-empts the run's other refusals | Informational | `scripts/build-loop.sh:1879-1891` | High |
| 5 | Plan's `--cycle-diff` bullet and D13 omit row 745's rules | Informational | `docs/working/plan-build-loop-handoff.md:209, 104` | Medium |

## Overall Assessment

The fix range resolves all five of iteration 1's actionable API findings: `--land-cycle` now takes `--main SHA`, named for main's commit and contrasted with `--merge`'s tip-binding `--expect`; the shared rules' wording is correct in both modes; the header documents the read failures, the `landed` fields and the reflog; and the plan carries an interface bullet and an As-built note recording where the `entry` line went. What remains is small and fixable in place. The new truth-file refusal leaks the lib's internal class words where every other consumer words them. The interface bullet sits under "Read modes" though the mode moves main. The Asked: refusal reads badly for an empty item. Two documentation and UX notes stay informational. No consumer exists before U4b, so nothing breaks. Finding 1 is the one to fix before U4b quotes these refusals, because the test now pins the raw words.

## Goal-Alignment Note

- **Success criterion (verbatim from the brief):** "a markdown report saved at the exact path your own prompt names, structured per your skill."
- **Alignment:** saved at `docs/reviews/api-consistency-review-2026-10-13-u4a-i2.md`, first line `Commit: 4e14d1cc`, with the partial-scope label, the skill's sections (Baseline, Name-Pattern Audit, Findings with Severity, Location, Evidence, Confidence and Legibility-target, What Looks Good, Summary Table, Overall Assessment) and an i1-resolution table. The known Incorrect claim 4b (unanchored item form) is not filed again. No probe ran, and nothing else in /workspace or the worktree was written.
