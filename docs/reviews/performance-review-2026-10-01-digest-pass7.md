Commit: 47c9a8e (A) / d6e1f24 (B)

# Performance Review — dev-cycle loop pass 7 (two fix rounds since final pass 5)

**Scope:** A: `git diff 28c6178..47c9a8e -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (wt-digest; commits ef0471c, 47c9a8e). B: `git diff c079e8c..d6e1f24` on the skill, `docs/dev-cycle.md`, onboarding step 13, Q-103, log rows 67–68 and the guide row (wt-devcycle; commits 5e8bfd9, d6e1f24). Also the A↔B contract where these rounds changed it.
**Date:** 2026-10-01
**Based on:** shared brief `digest-pass7-brief-dc1aa358.md`; Stage-1 context `docs/reviews/code-fact-check-report-digest-pass6.md` (its Incorrect claims 5, 13 and 15b on the scrub's linearity wording and test 5 are the prior verdicts this review builds on); prior pass `docs/reviews/performance-review-2026-10-01-digest-final5.md`.

## Data Flow and Hot Paths

`scripts/dev-cycle.sh` is a read-only CLI that runs once per dev cycle. Cycles run "from fortnightly to many a day" (SKILL.md:160-161). Every finding on A is on a **cold path**. Severity goes above the cold default only where a cost can stall the cycle itself. The skill stops the whole cycle on a failed or killed digest, writes no record, and so the next run meets the same input (SKILL.md:82-84). The agent's default Bash timeout is 2 minutes.

Repo text that reaches the digest is untrusted, per the brief's threat model. That includes decision-record trigger sections, the roadmap, the idea log, commit subjects and file names. All numbers below are my own measurements from 2026-10-01 in this sandbox (perl 5, mawk as `/usr/bin/awk`, git 2.39.5). The scripts are in `scratchpad/perf7/`. Test repos lived under a `mktemp -d` there and have been deleted.

| Measurement | Result |
|---|---|
| Full digest, this repo (1,899 commits, 33 records), `--since=2026-09-01`, 3 runs at 47c9a8e | 362–395 ms (pass 5 at 28c6178: 340–351 ms) |
| `scrub` (47c9a8e), one line, worst shapes I found under the cut: 2,000-layer nested C1 / 1,024-layer nested tag / 1,365-layer nested 3-byte / 2,048 adjacent pairs / flat 4,096 bytes | 3.3 / 2.6 / 2.9 / 3.0 / 1.9 ms, including ~2 ms perl start-up |
| `scrub`, 1,000 such lines (4 MB): nested C1 / adjacent pairs / nested 3-byte / 2,000 nested + 2,096 plain / flat | 1,202 / 912 / 852 / 582 / 9 ms, so **≤ 1.2 ms per line** at worst |
| `scrub`, one 100 MB nested line (cut to 4,096 + marker) | 86 ms; perl peak RSS 200 MB (VmHWM) |
| Old `1 while s///g` loop **plus** the new cut, one 2,048-layer line / 1,000 such lines / test 5's 1,000-layer line | 70 ms / 67,064 ms / 19 ms |
| Full digest, temp repo, one 100 MB line in a decision record's `## Revisit triggers` | 66.7 s, exit 0; 60.4 s of it is the `trig` awk alone |
| mawk reading one record of 1 / 4 / 16 / 100 MB (`{ x = 1 }` or the `trig` program) | 4 / 36 / 557–643 / 60,380 ms |
| Seed awk (`:274`) on one line `- x` + k×`(signal: )` + `z`, k = 1k / 4k / 16k / 64k (10 B per k) | 6 / 71 / 1,108 / 19,097 ms |
| Full digest, temp repo, that line in `docs/working/idea-log.md` at k = 16k (160 KB) / 64k (640 KB); baseline without it | 1,166 / 18,699 ms; baseline 28–31 ms |
| Old seed awk (28c6178, `/^- /`) on the 640 KB line | 2 ms |
| Heading awk (`:261`) vs exact match on a 200,000-line, 4.5 MB roadmap | 31 ms vs 10 ms |

## Findings

#### 1. The new seed regex is quadratic in mawk: one 640 KB idea-log line adds 18.7 s to the digest, and about 1.6 MB passes the 2-minute timeout, which stops every cycle

**Severity:** Low
**Location:** `scripts/dev-cycle.sh:274` (introduced in 47c9a8e)
**Move:** Asymptotic behavior / parsing untrusted input with a parser that is slow on adversarial input
**Classification:** Macro (O(L²) per line in mawk's backtracking matcher) / Cold path (once per cycle). Held at Low, not raised: the threshold is a ~1.6 MB single line, or many lines whose squared lengths sum to that. Pass 5's Medium was for a 128 KB threshold. It would rise if the idea log ever ingests pasted or generated text.
**Confidence:** High (measured end to end)
**Baseline:** 18,699 ms added to the full digest by one 640,003-byte idea-log line, measured 2026-10-01 (`perf7/s2.64000.txt`, temp repo). The same line takes 2 ms under the 28c6178 pattern.
**Legibility-target:** for-author

**Evidence:**
```
  seeded="$(awk '/^## Brainstorm [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ { c = 0; next } /^- [^ ].*\(signal: .*\)[[:space:]]*$/ { c++ } END { print c + 0 }' "$LOG")"
```
(complete statement, `:274`. Its value is first used at `:280`, `echo "- Ideas seeded since: $seeded"`. The enclosing `if inrepo "$LOG"` block runs `:268-283`.)

The two unanchored `.*` groups backtrack in mawk, Debian's default awk, which the comment at `:272` names as a target. On a line with many `(signal: )` groups and no `)` at the end, every split gets tried. Times grow ×16–17 per ×4 in length: 160 KB takes 1.1 s and 640 KB takes 19.1 s. Extrapolated, 1.6 MB takes about 120 s. Many medium lines add up too: a hundred 160 KB lines cost about 110 s. The idea log is a committed file, and section 7 reads it on every run, so the stall repeats every cycle until someone edits the file. The prior pattern `/^- /` was linear.

**Recommendation:** Use an equivalent linear test: `/^- [^ ]/ && index(substr($0, 4), "(signal: ") && /\)[[:space:]]*$/`. The `substr(…, 4)` keeps the old rule that `[^ ]` consumes the idea's first character. I ran it. It gave identical line selections to the current pattern on 700,000 random fuzz lines (`perf7/fuzz.txt`, `fuzz2.txt`), and it takes 3 ms on the 640 KB line. A 200 KB case under `timeout` in test 19 would pin it.

#### 2. The cut bounds the scrub but not the digest: mawk reads a long record in quadratic time, so a ~100 MB line in a trigger section or the roadmap still costs about a minute per awk pass

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:150`, `:215`, `:261` (all awk readers of repo files); the comment claim is at `:27-28`, `:33`
**Move:** Find the work that moved to the wrong place (the bound sits downstream of the cost)
**Classification:** Macro (O(L²) record read) / Cold path. Pre-existing: these lines are unchanged in this delta except the heading tests. The threshold is ~100 MB in one line, which GitHub's 100 MB file limit mostly rules out.
**Confidence:** High (measured)
**Baseline:** 60,380 ms for the `trig` awk on one 100 MB line, against 86 ms for `scrub` on the same line, measured 2026-10-01. The full digest took 66.7 s.
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
# U+202A-202E, U+2066-2069) and tag characters (U+E0000-E007F), and cuts lines
# longer than 4096 input bytes. Perl is pinned to bytes: PERL_UNICODE, PERL5OPT and PERLIO are
```
```
# control byte inside a sequence or a nested sequence cannot reassemble one;
# each pass is local, and the line cut bounds the total work. Not covered: lone
```
(`:27-28` and `:32-33`; the comment runs `:25-36` and documents `scrub()` at `:37-54`.)
```
trig() { awk '/^## Revisit triggers/ { on = 1; next } on && /^## / { exit } on && NF { print }'; }
```
(complete, `:150`.)

Read in context, "the total work" in the comment means the scrub's work, and that claim holds (≤ 1.2 ms per line, measured). The scrub, though, runs last in the pipeline. mawk reads one record at 4 / 36 / ~600 / 60,380 ms for 1 / 4 / 16 / 100 MB, whatever the program does with it. A huge line therefore still costs time in every awk that reads it before the cut applies. The roadmap goes through awk four times (`:215`, and `:261` three times), so a huge roadmap line costs four times as much. Nothing here is new to these rounds, and the inputs needed are unrealistic. I report it so that no one reads "the line cut bounds the total work" as a bound on the digest's run time.

**Recommendation:** No change needed. If the comment is touched again, say "bounds the scrub's work per line" so the scope is explicit.

#### 3. Test 5's timing case cannot detect a regression of the 3-byte resume: the old `1 while` loop plus the cut passes it in 19 ms

**Severity:** Informational
**Location:** `test/scripts/dev-cycle.bats:104-109`
**Move:** Check the asymptotic behavior (the test pins a constant, not the class)
**Classification:** Micro (test strength) / Cold path
**Confidence:** High (measured)
**Baseline:** 19 ms for the old fixed-point loop plus the cut on the test's 1,000-layer line. The test's limit is `timeout 20` (20,000 ms).
**Legibility-target:** for-author

**Evidence:**
```
    # 1000 nested layers inside the cut are removed entirely; a 80 KB line is cut
    # (which is what bounds the scrub's work) and the run stays fast.
    perl -e 'print "# 003\n\n## Revisit triggers\nif m", "\xC2" x 1000, "\x9B" x 1000, "n.\n- ", "x" x 80000, "\n"' > docs/decisions/003-z.md
    run --separate-stderr timeout 20 bash "$DC"
    [ "$status" -eq 0 ] || { echo "status $status (124 = timed out)"; return 1; }
    [[ "$output" == *"if mn."* && "$output" == *"[line cut at 4096 bytes]"* ]] || { echo "$output" | sed -n '/## 2/,/## 3/p' | cut -c1-120; return 1; }
```
(diff hunk at 47c9a8e. The test continues with the ESC-in-option stderr case.)

Under the cut, the resume matters only across many lines. 1,000 nested lines of 4 KB take 1.2 s with the resume and 67 s with the old loop plus the cut. On one line the difference is 3 ms against 70 ms. The test's single 1,000-layer line can't separate the two, so a revert to `1 while s///g` would still pass. The 80 KB line is flat, so it exercises only the cut. Pass 6's fact-check (Claim 13) asked for a nested line under the cut, and that part is now done. This finding is about timing, not correctness.

**Recommendation:** If the resume is worth pinning, add about 500 lines of 2,000-layer nesting in one trigger section under `timeout 10`. The current code takes about 0.6 s on that input and the old loop about 33 s.

#### 4. Skill: an item that goes idle for 7 days goes back to Now with nothing blocking it, so the next cycle can hand it to a fresh loop, with no retry limit

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:190-194`, `:203-205`
**Move:** Resource lifecycle / hidden multiplication (one full build loop per retry)
**Classification:** Macro (cost grows with the number of retries, and nothing bounds that number) / Cold path (once per cycle), but each retry is one full RPI run plus pr-prep's review-fix loop
**Confidence:** Medium (read from the skill text; no cycle has run under d6e1f24)
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** for-author

**Evidence:**
```
  merge decision (an open PR or `merge <branch>?` entry) → stays, however long; stopped on a
  stop condition, or still building with no commit on its branch for 7 days → back to Now
  marked stalled, with the reason, and its brief `Status: closed`.
```
(`:192-194`. The bullet starts at `:190`, "**In flight**: items handed to a build loop…".)
```
**Handoff queue.** Take the Now items whose first step needs no open choice (no open
`you: judgment` names them), up to the in-flight cap: at most 3 items In flight at once,
```
(`:203-204`. The paragraph runs to `:211`.)

The two stall routes behave differently. A loop that hits a stop condition files a `you: judgment` entry (`:256-257`), and that entry keeps the item out of the queue. A loop that just goes idle files nothing. "Marked stalled" is not one of the queue's exclusion rules, so the next cycle's step 6 can write a new brief and step 6b can launch a new loop on it. An item that stalls for a structural reason will repeat this every ≥7 days. Agent loops stalling is a known failure mode here (memory note "Agent worktrees stall"). Each round costs one of the 3 slots for at least a week, plus a full RPI and review-fix loop. Pass 5's finding 2 (slots leaking) is fixed. This is the retry side of that fix.

**Recommendation:** Treat a second stall of the same item as a stop: file a `you: judgment` (or `agent`) entry naming the reason, so the existing exclusion keeps it out of the queue. Or say that "marked stalled" items wait for one cycle's human or step-3 review before they are re-queued.

#### 5. Skill: the cycle record cannot show when the cap is full, so row 68's own revisit trigger ("if the cap of 3 In flight starves") has no evidence source

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:228`, `:260-261`; `docs/decisions/log.md` row 68
**Move:** Find the contention point (a capped pool, and whether its saturation is observable)
**Classification:** Macro (6b's throughput becomes the user's merge-answer rate once the pool fills) / Cold path
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** for-author

**Evidence:**
```
6b. handoff: <briefs queued in step 6, or none>
```
(`:228`, inside the record template `:218-234`.)
```
Then send the final message: list the new `you: judgment` entries by ID and name, so the user
does not have to open the record to find them.
```
(`:260-261`, the end of the skill.)
```
| **[1] review** | Each loop runs pr-prep's review-fix loop, then files one "merge <branch>?" entry (no PRs here) | One decision per finished item | Finished work queues up behind you; at most 3 items in flight |
```
(Q-103 options table, `docs/working/questions.md` at d6e1f24. The table also has row [2].)

`review` is this repo's interim policy and the default everywhere. Under it, finished items hold their slots "however long" (`:192`). Once three are waiting, 6b launches nothing until the user answers. Q-103 says so, which is fine as designed backpressure. The cost is what the cycle can see. The record's 6b line reads "none" both when nothing was ready and when the pool was full. The final message lists only *new* entries, and the "merge <branch>?" entries were filed by loops in earlier cycles, so they are never surfaced again. Row 68 says to revisit "if the cap of 3 In flight starves or swamps the review", but no cycle record will say whether it starved. Judging that trigger would mean rebuilding history from the roadmap's git log.

**Recommendation:** Make the 6b line `<n queued; k/3 In flight, w waiting on a merge decision>`. Have the final message also list open `merge <branch>?` entries older than this cycle. Both are one-line template changes.

## Endorsements (evidence-gated)

- Claim: the resume plus the 4,096-byte cut bound the scrub at ≤ 1.2 ms per line on the worst shapes I found (nested 2- and 3-byte, nested tag, adjacent pairs, prefix and suffix padding). A 100 MB nested line scrubs in 86 ms, where pass 5 measured 17.8 s at 64 KB. 1,000 nested lines take 1.2 s with the resume and 67 s with the old loop plus the cut. `[unverified — submitted as claim]` (my own timing, not a fact-check execution verdict)
- Claim: the delta adds no measurable wall time to a normal run. The full digest on this repo takes 362–395 ms at 47c9a8e against pass 5's 340–351 ms at 28c6178, which is within run-to-run noise in this sandbox. The heading matcher costs 31 ms against 10 ms for an exact match on a 200,000-line roadmap. `[unverified — submitted as claim]`
- Section 7's `core.quotePath=false` is a config flag on the same single path-limited walk, and the two greps gain only an optional `"` at each end, so no new process or pass is added. `[read: scripts/dev-cycle.sh:239-247]`
- The In-flight check is bounded by the cap: at most 3 items per cycle, each needing one merged/PR/entry lookup and one branch-date lookup. 6b launches at most as many loops as there are free slots, so loop count per cycle does not grow with cycle frequency. `[read: skills/dev-cycle/SKILL.md:190-194,203-211,243-258]`
- The cycle-record glob now forks `realpath` once per record through `inrepo`. Records are named by date and updated in place, so there is at most one per day, about 0.5 ms each (pass 5 measured 17 ms for 33 calls). `[read: scripts/dev-cycle.sh:89,114-119; SKILL.md:215]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | New seed regex is O(L²) in mawk: 640 KB idea-log line +18.7 s; ~1.6 MB passes the 2-min timeout and stops every cycle; tested linear equivalent | Low | `scripts/dev-cycle.sh:274` | High |
| 2 | Cut bounds the scrub, not the digest: mawk reads a 100 MB record in 60 s (pre-existing; comment scope only) | Informational | `scripts/dev-cycle.sh:150,215,261`; `:27-33` | High |
| 3 | Test 5's timing case passes with the old `1 while` loop (19 ms vs a 20 s limit); the resume matters only across many lines | Informational | `test/scripts/dev-cycle.bats:104-109` | High |
| 4 | Idle-stalled items re-enter the queue with no retry limit; each retry is one full RPI and review-fix loop | Low | `skills/dev-cycle/SKILL.md:190-194,203-205` | Medium |
| 5 | Cap saturation is not recorded, so row 68's "cap starves" trigger has no evidence; old merge entries are never re-surfaced | Low | `skills/dev-cycle/SKILL.md:228,260-261`; log row 68 | Medium |

Carried, not re-filed: rubric C5 (each cycle's chore branch goes through full pr-prep) and C6 (section 7 has no churn) stay 🟢 Open. These rounds did not change either one.

## Overall Assessment

The fix for pass 5's Medium (A1) is real. The scrub is now bounded per line: ≤ 1.2 ms worst case, and 86 ms on a 100 MB nested line that used to take hours. Normal runs are no slower. The one regression is new in 47c9a8e. The stricter seed pattern brings back the same failure class A1 removed, quadratic matching on untrusted repo text, this time in mawk on the idea log. Its threshold is about 12 times higher (~1.6 MB against 128 KB), so it ranks Low. A one-line linear rewrite that I tested gives identical selections, so it is worth fixing in place. Findings 2 and 3 are wording and test-strength notes. On B, the In-flight lifecycle no longer leaks slots. What remains is retry and visibility. An item that goes idle is retried indefinitely, and a full pool cannot be seen in the record that row 68's revisit trigger depends on. Both are small template or rule edits. Neither needs profiling. Findings 4 and 5 should be checked against the first real cycles.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/performance-review-2026-10-01-digest-pass7.md`. Its first line is `Commit: 47c9a8e (A) / d6e1f24 (B)`. It follows the performance-reviewer structure: header, Data Flow and Hot Paths with a measurement table, and findings. Each finding carries Severity, Location, Move, Classification, Confidence, Baseline, Legibility-target, verbatim Evidence with unit-remainder notes, and a Recommendation. Then come tagged Endorsements (timing claims as `[unverified — submitted as claim]`), the Summary Table and the Overall Assessment. Scope A (the scrub's worst case under the cut, measured; the heading and seed awk; the section 7 walk with quotePath) and scope B (the costs of In-flight checks and loops per cycle) are both covered. Probe cleanup: every probe ran under `timeout`, temp repos and large inputs were deleted, and no probe processes remain. Nothing was written to either worktree except this file. Not committed.
