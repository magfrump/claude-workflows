Commit: c034a75 (A) / a218ad8 (B)

# Performance Review — dev-cycle pass 11 (k=1 loop pass; pass-10 fix round)

**Scope:** Partial: the pass-10 fix round only. A: `git diff b88a9c4..c034a75 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (worktree `/workspace/.claude/wt-digest`; HEAD 9e23ea8 has the same content for both files). B: `git diff 79b1bfe..a218ad8 -- skills/dev-cycle/SKILL.md docs/working/questions.md docs/working/seed-build-loop-handoff.md` (worktree `/workspace/.claude/wt-devcycle`, read at a218ad8). Everything else on both branches is context only.
**Date:** 2026-10-01
**Based on:** `docs/reviews/code-fact-check-report-digest-pass10.md` (Stage-1 context. It covers the round before this one, so no claim of this round has an execution verdict yet) and `docs/reviews/performance-review-2026-10-01-digest-pass10.md`.

Line numbers: A at c034a75 (`git show c034a75:scripts/dev-cycle.sh`), B at a218ad8. Probes ran under `timeout` in `mktemp -d` dirs under `scratchpad/perf11/` (`probe.sh`, `cycles.sh`), against a copy of the script at c034a75 (`scratchpad/perf11/dc.sh`). Nothing was written to either worktree except this file, and no process was left running. Bats at 9e23ea8 (same script and test content as c034a75): 21/21 passed in 5.2 s wall.

## Data Flow and Hot Paths

**A (digest).** `scripts/dev-cycle.sh` runs once per dev cycle. That is a cold path: cycles "vary from fortnightly to many a day". The round makes these changes:

- It adds `plaindir` (line 95), which forks one `realpath`.
- It guards the two globs: the cycle records (128-136) and the decision records (173-176). A directory that is not plain is recorded once by `skipdir` (102) and is never expanded.
- `skipped()` now replaces a newline in a name before storing it (101).
- It adds two counters, `records_skipped` (137) and `n_before_triggers` (175), and uses them to choose the wording of the window line (144-148) and of section 2 (200-203).
- Section 8 now prints with `sort -u | sed` instead of a `while read` loop (328).

The new fixed cost is two `realpath` forks per run, one for each guarded directory. An empty repo ran in 20–21 ms per digest (5 runs), against 24 ms in pass 10. The per-file cost inside the globs is unchanged. With 1,000 plain cycle records, the digest took 955 ms against 24 ms with none, about 0.93 ms per record. That cost predates this round: the loop body was only re-indented. Records accrue at one per cycle.

**B (skill).** This round adds three things:

- A third exit-adjacent rule for In flight: a brief "open for 14 days with no commit on its branch" gets one `you: judgment` "keep or drop" entry.
- A `(3/3: no new briefs)` marker on the record line.
- A `## Skipped inputs` rename, a step-0 sentence for skipped records, and the reminder in the final message.

Here the cost units are user attention per cycle and agent work per cycle. The new rule is evaluated for each open brief in each cycle, and there are at most 3 open briefs. It responds to pass-10 finding 1.

## Findings

#### 1. "Keep" has no memory: once the user answers "keep" and the entry closes, the next cycle re-files the same "keep or drop?" entry, so an unstarted brief the user wants to keep costs one judgment per cycle indefinitely

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:216-219` (a218ad8)
**Move:** Count the hidden multiplications (one entry per brief, multiplied by every cycle after day 14)
**Classification:** Macro (the number of re-asks grows with the cycle count, without bound, while the condition holds) / Cold path (per cycle). The cost is user attention, not compute.
**Confidence:** Medium. The text has no state that records a "keep" answer. How often this bites depends on how often a user keeps a brief unstarted for weeks.
**Legibility-target:** for-orchestrator-synthesis
**Baseline:** no baseline available — flagged as speculative

**Evidence:** "A brief open for 14 days with no commit on its branch gets one `you: judgment` entry, "keep or drop the brief for <item>?" (unless one is already open), so unstarted briefs do not hold the slots for good." (216-219, the end of the In flight bullet)

The only guard is "unless one is already open". A "keep" answer closes the entry and gets archived, and the brief stays `Status: open`. Its branch still has no commit, so the trigger condition still holds at the next cycle and the rule files a new entry. The text has no "kept on <date>" marker in the brief and no snooze window. With cycles "many a day", one kept brief can mean several identical asks per day, and up to 3 at once with 3 kept briefs. That is the queue this repo's attention-budget rule exists to prevent. The rule does fix pass-10 finding 1 for the case it names (a brief the user never starts, without a decision), so this is a regression in a narrower case. It stays Low because the user can stop it by answering "drop", and because each entry is cheap to answer.

**Recommendation:** Make "keep" durable. For example, on a "keep" answer write `Kept: YYYY-MM-DD` into the brief and count the 14 days from the later of its open date and its last `Kept:` date. Or phrase the rule as "14 days since the brief opened or was last kept".

#### 2. The 14-day rule fires only on "no commit": a brief whose branch has commits but stalls, or lands by squash or rebase (no longer an ancestor of the default branch), still holds its slot indefinitely (pass-10 finding 1, residual half)

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:214-219`, `skills/dev-cycle/SKILL.md:229-230` (a218ad8)
**Move:** Find the contention point (a fixed cap of 3 open briefs)
**Classification:** Macro (the brief output drops to zero, whatever the data size) / Cold path, per cycle
**Confidence:** Medium. The text decides it. Whether it bites depends on how the user's work lands: pr-prep's local merge keeps the branch as an ancestor, so in this repo the merged case is usually detected.
**Legibility-target:** for-orchestrator-synthesis
**Baseline:** no baseline available — flagged as speculative

**Evidence:** "its branch merged into the default branch → Done; the user dropped it (closed the brief, or said so) → Ideas, with the reason. Either way the brief gets `Status: closed`. A brief open for 14 days with no commit on its branch gets one `you: judgment` entry" (214-217), and "while fewer than 3 briefs are open, counting earlier cycles'." (230)

The new rule covers the never-started case: a branch that does not exist reads as "no commit", which is the intended reading. It does not cover a branch that has one or more commits and then goes idle, or one whose content landed under another history. Both stay In flight until the user says otherwise. The new `(3/3: no new briefs)` marker (250) names the stall in the record, and the final message re-lists the open briefs every cycle. So the stall is visible, and this is Informational rather than Low.

**Recommendation:** Optionally widen the condition to "no commit on its branch in the last 14 days". The same entry (with finding 1's durable keep) then covers stalled branches as well. Leave squash merges to the user.

#### 3. Digest section 8 and the record's `## Skipped inputs` are still uncapped, unlike sections 6 and 7 (pass-10 finding 2, carried forward, partly reduced)

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:323-329` (c034a75); `skills/dev-cycle/SKILL.md:66`, `skills/dev-cycle/SKILL.md:97-98`, `skills/dev-cycle/SKILL.md:251` (a218ad8)
**Move:** What's the size of N; trace the memory lifecycle (committed-record growth)
**Classification:** Macro (output grows linearly with the number of skipped paths) / Cold path (N is zero in a normal repo)
**Confidence:** High for the shape; Low that it matters in practice
**Legibility-target:** for-orchestrator-synthesis
**Baseline:** about 30 bytes of digest output per skipped path (1,000 skipped records gave 30,719 bytes against 1,772 bytes with none), measured by `scratchpad/perf10/scale.sh` on 2026-10-01 against b88a9c4. The bullet format is unchanged at c034a75.

**Evidence:** `printf '%s\n' "${SKIPPED[@]}" | sort -u | sed 's/^/- /'` (328)

This round shrinks the worst realistic case. A whole symlinked `docs/decisions` or `docs/working/cycles` is now one bullet (`skipdir`, 102) instead of one bullet per file in the target. Probe case A listed only `- docs/decisions/`. N is now bounded by individually symlinked files inside plain directories. That needs many committed symlinks, so the cost is nil in practice.

**Recommendation:** None needed. If the section is touched again, cap it like section 6: the first 30, then "… n more".

## Outside the performance lane (routed, not graded)

These bear on the brief's claim 1 ("can a skipped record coexist with a readable one and mislead?", and "can [section 2's branch] fire when triggers were read, or miss a skip?"). They are correctness issues, so the fact-check and security stages own them. Severity is not graded here. Both were executed by `scratchpad/perf11/probe.sh`.

- **Section 2 misses a skipped `docs/decisions/` directory: it prints "No revisit triggers recorded." while section 8 lists `- docs/decisions/`.** **Location:** `scripts/dev-cycle.sh:174-175`, `:200-203`. **Evidence:** `if plaindir docs/decisions; then decisions_glob=(docs/decisions/[0-9][0-9][0-9]-*.md); else skipdir docs/decisions || true; fi` followed by `n_before_triggers=${#SKIPPED[@]}` (174-175). The baseline count is taken *after* `skipdir` has already appended `docs/decisions/`. So `${#SKIPPED[@]} -gt $n_before_triggers` (201) is true only if `docs/decisions/log.md` is skipped as well, and that happens only when the symlink target happens to contain a `log.md`. Probe case A: `docs/decisions` was a symlink to a directory holding `001-x.md` with a Revisit-triggers section and no `log.md`. Section 2 printed "No revisit triggers recorded." and section 8 printed "- docs/decisions/". New test 7 (`test/scripts/dev-cycle.bats:157-174`) does not assert section 2's wording. Test 6 covers only per-file symlinks inside a plain directory, and probe case C (a symlinked `log.md` only) printed the correct "No revisit triggers read" line. Fix: move `n_before_triggers=${#SKIPPED[@]}` above line 174. **Confidence:** High (executed). **Legibility-target:** for-fact-check.
- **A skipped newer cycle record next to a readable older one: the window silently widens to the older record, and the Window line gives no hint.** **Location:** `scripts/dev-cycle.sh:137-148`. **Evidence:** `elif [[ -n "$last_record" ]]; then SINCE="$last_record"; source_note="the last cycle record, docs/working/cycles/cycle-$last_record.md"` (140-141). The `records_skipped` wording applies only in the `else` branch (144-145). Probe case B: plain `cycle-2026-01-01.md` and symlinked `cycle-2026-02-20.md` gave "Window: since 2026-01-01 (from the last cycle record, docs/working/cycles/cycle-2026-01-01.md)", with the newer record only in section 8. Step 0's existing rule ("If the window starts before the last cycle you know ran … rerun with `--since`", SKILL.md:101-103) catches it only if the agent knows that cycle ran. The new step-0 sentence ("If instead it says the records were skipped") never triggers here, because the Window line does not say so. The performance side is a wider window, so sections 1, 4 and 6 walk and list more merges. That is cold, and output stays capped at 30. **Confidence:** High (executed). **Legibility-target:** for-fact-check.

## Endorsements

- The two guarded globs cut the cost of a symlinked directory from one or two `realpath` forks per file in the target (`inrepo`, then `skipped`'s repeat) to a single `realpath` fork for the directory. Nothing in the target is listed or stat'ed. [read: scripts/dev-cycle.sh:92-102, 127-136, 173-185]
- The round adds a constant two forks per run and nothing per input. An empty-repo digest measured 20–21 ms over 5 runs, against 24 ms at b88a9c4 (pass-10 probe). [read: scripts/dev-cycle.sh:95, 128, 174]
- Section 8 replaced a per-line `while read … echo` bash loop with one `sed` process. The newline is now replaced in `skipped()` before the name is stored, so the substitution runs at store time and is no longer dead code at print time. Test 7's FORGED case passes. [read: scripts/dev-cycle.sh:101, 323-329]
- Claim: the 14-day rule costs at most 3 branch-existence/commit checks per cycle (one per open brief), because the cap of 3 bounds open briefs and "unless one is already open" bounds the entries filed per cycle to one per brief. [unverified — submitted as claim]
- Claim: the 21-test suite runs in about 5 s on this host (measured 5.2 s once). The one added test (test 7, two digest runs) adds well under a second. [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | "Keep" has no memory: the closed "keep or drop?" entry is re-filed every cycle while the brief stays unstarted | Low | `skills/dev-cycle/SKILL.md:216-219` | Medium |
| 2 | 14-day rule fires only on "no commit"; stalled or squash-landed branches still hold slots | Informational | `skills/dev-cycle/SKILL.md:214-219, 229-230` | Medium |
| 3 | Section 8 / `## Skipped inputs` still uncapped (about 30 bytes per path), now one line per symlinked directory | Informational | `scripts/dev-cycle.sh:323-329`; `skills/dev-cycle/SKILL.md:66, 97-98, 251` | High / Low |

## Overall Assessment

A (the digest) is clean for performance and slightly better than at pass 10. A symlinked directory now costs one fork and one output line instead of work proportional to its target. The fixed overhead is two forks per run (measured 20–21 ms per empty-repo digest). Section 8's print loop is now a single `sed`. The routed correctness notes matter more for this round's claim 1. Section 2 still says "No revisit triggers recorded." when the whole `docs/decisions/` is a skipped symlink, because `n_before_triggers` is captured one statement too late; this is a one-line move. A skipped newer cycle record silently widens the window with no hint in the Window line. B (the skill) closes pass-10 finding 1's main case with the 14-day rule and the `3/3: no new briefs` marker. It brings one new Low: a "keep" answer is not remembered, so an intentionally unstarted brief is re-asked every cycle. Nothing here needs profiling. Finding 1 can be fixed with one sentence (a `Kept:` date). Nothing in this lane rates above Low.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file." This report is saved at `/workspace/.claude/wt-digest/docs/reviews/performance-review-2026-10-01-digest-pass11.md`, with first line `Commit: c034a75 (A) / a218ad8 (B)`. It has the skill's header, Data Flow, Findings (each with Severity, Location, Move, Classification, Confidence, Baseline, and the brief's Evidence and Legibility-target), evidence-tagged Endorsements, Summary Table and Overall Assessment. It serves the user goal (merge both branches once a clean pass is reached). No performance finding rates above Low, so this lane does not block a clean pass. The two routed correctness notes, chiefly the `n_before_triggers` ordering in section 2, go to the fact-check stage and would need a fix round before the pass is clean.
