Commit: b88a9c4 (A) / 79b1bfe (B)

# Performance Review — dev-cycle pass 10 (k=1 loop pass; pass-9 fix round)

**Scope:** Partial: the pass-9 fix round only. A: `git diff d503a43..b88a9c4 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (worktree `/workspace/.claude/wt-digest`). B: `git diff 1ae9b21..79b1bfe -- skills/dev-cycle/SKILL.md docs/dev-cycle.md docs/roadmap.md docs/decisions/log.md docs/working/questions.md docs/working/seed-build-loop-handoff.md global-instructions guides/skill-creation.md workflows/codebase-onboarding.md` (worktree `/workspace/.claude/wt-devcycle`, read at 79b1bfe). Everything else on both branches is context only.
**Date:** 2026-10-01
**Based on:** `docs/reviews/code-fact-check-report-digest-pass9.md` (Stage-1 context; it covers the round before this one, so no claim of this round has an execution verdict yet), and `docs/reviews/performance-review-2026-10-01-digest-pass9.md`.

Line numbers: A at b88a9c4 (`git show b88a9c4:scripts/dev-cycle.sh`), B at 79b1bfe. Probes ran under `timeout` in `mktemp -d` dirs under `scratchpad/perf10/` (`scale.sh`, `kinds.sh`, run against a copy of the script at b88a9c4). Nothing was written to either worktree except this file, and no process was left running. Bats at b88a9c4: 20/20 in 5.3 s wall.

## Data Flow and Hot Paths

**A (digest).** `scripts/dev-cycle.sh` runs once per dev cycle: a cold path ("cycles vary from fortnightly to many a day", SKILL.md:182-183). The round adds `skipped()` (line 96): for an input that exists in some form (`-e` or `-L`) but fails `inrepo`, it appends the path to the `SKIPPED` array. It is called only on paths where `inrepo` has already failed: in the cycle-record and decision-record glob loops (123, 159), and on the else branches for the log, questions, roadmap (twice) and idea log (180, 205, 227, 277, 296). A new section 8 (302-308) prints the array once through `sort -u`. A path that is absent stops at `[[ -e || -L ]]` with no fork. A plain path never reaches `skipped`. So the round adds work only for inputs that are present but skipped. N is the number of committed symlinks (or non-regular files) at input paths: zero in a normal repo, and bounded only by the repo's own content.

**B (skill).** The autonomous build-loop handoff (6b) is gone. Step 6 now writes up to 3 build briefs, which land with step 7 and are listed in the final message. In flight means "has an open brief". Its exits are "branch merged → Done" or "user dropped it → Ideas". The cost units are agent tool calls per cycle and the user's attention. No step spends a whole autonomous build loop any more. Pass-9 findings 1–5 were all about build-loop round trips, the in-flight cap against live loops, or loops filing entries. Those mechanisms are removed at 79b1bfe, so the findings are moot: there is no 6b, no `Paths`, and no loop that files entries. Pass-9 finding 6 (the per-access symlink check and the unbounded `## Skipped paths`) survives unchanged in text, and the digest now feeds that section (finding 2 below).

## Findings

#### 1. An open brief never expires: three briefs the user does not start (or that merge in a way "branch merged" cannot see) stop the cycle from writing any new brief, indefinitely

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:212-214`, `skills/dev-cycle/SKILL.md:224-225`
**Move:** Find the contention point (a fixed cap of 3, released only by two exits)
**Classification:** Macro (throughput of the cycle's main output drops to zero, whatever the data size) / Cold path, per cycle
**Confidence:** Medium (the text has no third exit. How often it bites depends on how often the user leaves briefs unstarted, and on whether merges keep the branch as an ancestor of the default branch, which pr-prep's local merge does)
**Legibility-target:** for-orchestrator-synthesis
**Baseline:** no baseline available — flagged as speculative

**Evidence:** "**In flight**: items with an open build brief, each linking it. Every cycle checks each: its branch merged into the default branch → Done; the user dropped it (closed the brief, or said so) → Ideas, with the reason. Either way the brief gets `Status: closed`." (212-214) and "Take the Now items whose first step needs no open choice (no open `you: judgment` names them), while fewer than 3 briefs are open, counting earlier cycles'." (224-225)

The pass-9 text had a third exit ("still building with no commit on its branch for 7 days → Ideas"). 79b1bfe drops it along with the loops, so now only the user can release a slot. A brief whose branch the user never creates, or whose work lands by squash or rebase (no longer an ancestor), or under another branch name, stays In flight for good. Once three are open, every later cycle writes no briefs. It still reports `<k>/3 open` (line 245) and re-lists the same three paths in each final message (261-263). The user then rereads stale items every cycle. The cost is attention per cycle plus a silent stall in what the cycle hands over, not compute. It stays Low because the final message surfaces the three paths every time, so the stall is visible, and because the fix belongs to the user.

**Recommendation:** Add an observable stale rule that proposes rather than acts. For example: "an open brief whose branch does not exist, or has no commit, after N cycles → one `you: judgment` entry 'drop or keep <brief>?'". Or have the record line say `3/3 open — no new briefs` so the stall is named. Accept "merged" by content where needed, for example by checking that the brief's branch has no commits not already on the default branch (`git cherry`).

#### 2. Digest section 8 and the record's `## Skipped paths` are unbounded, unlike sections 6 and 7 (carried forward from pass-9 finding 6, now fed by the digest)

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:302-308`; `skills/dev-cycle/SKILL.md:65`, `skills/dev-cycle/SKILL.md:96-97`, `skills/dev-cycle/SKILL.md:246`
**Move:** Trace the memory lifecycle (committed-record growth); what's the size of N
**Classification:** Macro (output grows linearly with the number of skipped paths) / Cold path (once per cycle; N is zero in a normal repo)
**Confidence:** High for the shape (measured); Low that it matters in practice
**Legibility-target:** for-orchestrator-synthesis
**Baseline:** digest output 1,772 bytes with no skipped inputs, measured by `scratchpad/perf10/scale.sh` on 2026-10-01 against b88a9c4

**Evidence:** `printf '%s\n' "${SKIPPED[@]}" | sort -u | while IFS= read -r f; do echo "- ${f//$'\n'/ }"; done` (307), in contrast to sections 6 and 7: `printf '%s\n' "${flagged[@]:0:30}"` (247) and `sed -n '1,20s/^/    - /p'` (267). Skill: "8 skipped inputs (the record's `## Skipped paths`)" (96-97).

Probe: with 1,000 symlinked decision records, section 8 had 1,000 bullets and the digest was 30,719 bytes. With 3,000 it had 3,000 bullets and 90,719 bytes (about 30 bytes per path), against 1,772 bytes with none. Step 0 maps section 8 straight into the committed record's `## Skipped paths`, so the same N lines land in git every cycle. Sections 6 and 7 already cap their lists at 30 and 20 with a "… n more" line. N needs a repo with many committed symlinks at input paths, so this costs nothing in practice. It is the only uncapped list in the digest.

**Recommendation:** Cap section 8 the way section 6 does (the first 30 and "… n more"), and let the record copy the capped list.

#### 3. `skipped()` re-runs `inrepo`, so every skipped input pays a second `realpath` fork

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:92`, `scripts/dev-cycle.sh:96`, `scripts/dev-cycle.sh:123`, `scripts/dev-cycle.sh:159`
**Move:** Count the hidden multiplications
**Classification:** Micro (one subshell fork per skipped path) / Cold path
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Baseline:** 1,676 ms for 1,000 plain decision records versus 1,979 ms for 1,000 symlinked ones, `scratchpad/perf10/scale.sh` 2026-10-01 (3,000: 4,964 ms versus 5,845 ms)

**Evidence:** `inrepo "$f" || { skipped "$f" || true; continue; }` (123, 159), with `skipped() { if [[ -e "$1" || -L "$1" ]] && ! inrepo "$1"; then SKIPPED+=("$1"); return 0; fi; return 1; }` (96), and `inrepo` forks `r="$(realpath -e -- "$1" 2>/dev/null)"` (92).

At every call site, `inrepo` has just failed, so the `! inrepo` inside `skipped` repeats a check whose answer is already known. A symlink to a regular file passes `-f` and forks `realpath` again. The measured cost is about 0.3 ms per skipped path, an 18% increase per record over the plain path. It is negligible at any realistic N.

**Recommendation:** None needed. If touched anyway, split `skipped` into an unconditional `note_skipped` used where `inrepo` has just failed, which also makes the call sites read more plainly.

## Outside the performance lane (routed, not graded)

These bear on the brief's claim 1 ("lists it in section 8 exactly once; no plain input is ever listed"). They are correctness and wording issues, so the fact-check and security stages own them. Severity is not graded here.

- **A name holding a newline is listed as two bullets, one of them a path that does not exist.** **Location:** `scripts/dev-cycle.sh:307`. **Evidence:** `printf '%s\n' "${SKIPPED[@]}" | sort -u | while IFS= read -r f; do echo "- ${f//$'\n'/ }"; done`. Probe `scale.sh` case `nl`: symlinked `docs/decisions/001-a<LF>zz.md` plus `002-m.md` printed `- docs/decisions/001-a`, `- docs/decisions/002-m.md`, `- zz.md`. `printf`/`sort`/`read` split on LF before the substitution runs, so `${f//$'\n'/ }` can never match (dead code). The decision-record glob's `*` matches LF. **Confidence:** High (executed). **Legibility-target:** for-fact-check. Section 2's `### ${f//$'\n'/ }` (165) does work, because it substitutes before printing.
- **A directory or FIFO at an input path is reported as "reached through a symlink".** **Location:** `scripts/dev-cycle.sh:96`, `:206`, `:228`, `:306`. **Evidence:** `if [[ -e "$1" || -L "$1" ]] && ! inrepo "$1"` and "Reached through a symlink, so not read." Probe `kinds.sh`: a directory at `docs/decisions/log.md` and a FIFO at `docs/roadmap.md` were both listed under section 8, and section 5 printed "docs/roadmap.md is reached through a symlink: NOT read (section 8)." A dangling symlink was listed correctly. **Confidence:** High (executed). **Legibility-target:** for-fact-check.
- **A symlinked cycle record is listed in section 8 while the window line still says "no cycle record found".** **Location:** `scripts/dev-cycle.sh:121-133` (unchanged lines; the new behaviour is the section-8 listing). **Evidence:** `source_note="no cycle record found, so the default of 14 days (the previous cycle, if any, did not write its record)"` (133). Skill step 0: "If the window starts before the last cycle you know ran (or says no cycle record was found when one ran), that cycle skipped step 7: note it in this record and rerun with `--since`" (98-101). The new test checks only `!= *"from the last cycle record"*`. One digest therefore says the record exists (section 8) and that none was found (window line). That can cost a needless rerun of the digest and a false "skipped step 7" note. **Confidence:** Medium (read-decided, not probed separately). **Legibility-target:** for-fact-check.

## Endorsements

- The round adds no work for plain or absent inputs. `skipped` is reached only after `inrepo` fails, and an absent path stops at `[[ -e || -L ]]` before any fork. The probe's empty-repo digest took 24 ms. [read: scripts/dev-cycle.sh:92-96, 123, 159, 168-181, 187-209, 222-231, 272-300]
- Claim: a FIFO at an input path does not block the digest, because `inrepo`'s `-f` test fails before anything opens it and `skipped` only tests it. Probe `kinds.sh` with a FIFO at `docs/roadmap.md` completed under a 60 s timeout. [unverified — submitted as claim]
- Claim: at 79b1bfe no step of the dev-cycle skill starts an autonomous build loop or reads the build-loop policy, so pass-9 findings 1–5 (loop round trips, in-flight cap against live loops, policy-entry duplication) have no remaining mechanism. The policy bullet says "This skill does not read it." (56-58). [read: skills/dev-cycle/SKILL.md:56-58, 78-86, 211-229, 231-263]
- The brief count and the final message are bounded: at most 3 open briefs, and the final message lists only those plus the new judgment entries. [read: skills/dev-cycle/SKILL.md:224-229, 261-263]
- Claim: the 20-test suite still runs in about 5 s on this host. The one added full digest run in test 20 and the extra symlinks in test 6 cost well under a second. [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Open briefs never expire; three unstarted (or squash-merged) briefs stop new briefs indefinitely | Low | `skills/dev-cycle/SKILL.md:212-214, 224-225` | Medium |
| 2 | Section 8 / `## Skipped paths` uncapped (measured ~30 bytes per path), unlike sections 6–7 | Informational | `scripts/dev-cycle.sh:302-308`; `skills/dev-cycle/SKILL.md:96-97, 246` | High / Low |
| 3 | `skipped()` repeats `inrepo`: a second `realpath` fork per skipped path (~0.3 ms) | Informational | `scripts/dev-cycle.sh:92, 96, 123, 159` | High |

## Overall Assessment

The digest half (A) is clean for performance. The new skip reporting costs nothing on plain or absent inputs. On skipped inputs it costs one extra fork each (measured ~0.3 ms) and one uncapped output line each, and both only matter with thousands of committed symlinks. The routed correctness notes matter more for this round's claim 1: a name with an LF is listed as two bullets, a directory or FIFO is called a symlink, and a symlinked cycle record contradicts the window line. They belong to the fact-check stage. The skill half (B) removes every whole-build-loop cost that drove pass-9's Medium findings. What remains is one Low: In flight releases a slot only on a detectable merge or an explicit drop. Nothing in the procedure needs profiling. Finding 1 is fixable with one sentence, and finding 2 with a cap that copies section 6.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file." This report is saved at `/workspace/.claude/wt-digest/docs/reviews/performance-review-2026-10-01-digest-pass10.md`. It has the skill's header, Data Flow, Findings (each with Severity, Location, Move, Classification, Confidence, Baseline, plus the brief's Evidence and Legibility-target), evidence-tagged Endorsements, Summary Table and Overall Assessment. It serves the user goal (merge both branches once a clean pass is reached) as follows: there are no performance findings above Low, so nothing in this lane blocks the clean pass. The three routed correctness notes go to the fact-check stage for claim 1.
