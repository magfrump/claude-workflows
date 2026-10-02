Commit: 28c6178 (A) / c079e8c (B)

# Performance Review — dev-cycle final pass 5 (digest fixes + skill update)

**Scope:** A: `git diff db0e5ca..28c6178 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (wt-digest). B: `git diff 6ee33e3..c079e8c -- skills/dev-cycle/SKILL.md` and companions (wt-devcycle). The A–B contract is also in scope.
**Date:** 2026-10-01
**Based on:** Stage-1 merged fact-check summary `digest-final5-stage1-dc1aa358.md` (replicates `docs/reviews/code-fact-check-report-r{1,2,3}-digest-final5.md`); prior pass `docs/reviews/performance-review-2026-10-01-digest-final4.md`.

## Data Flow and Hot Paths

`scripts/dev-cycle.sh` is a read-only CLI run about once per dev cycle. The skill says cycles range "from fortnightly to many a day" (SKILL.md:151). The agent running step 0 reads the whole output. Every finding on A is on a **cold path**. Severity rises above the cold default only where a cost can stall the cycle itself: the skill stops the whole cycle when the digest fails or is killed (SKILL.md:74-76).

Repo text that reaches `scrub` is untrusted. It includes decision-record trigger sections, decision-log rows, commit subjects, file names, roadmap lines and stderr from questions.sh.

All numbers below are my own measurements from 2026-10-01 in this sandbox (bash 5, perl 5, git 2.39.5). Scripts are in `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/perf5/`.

| Measurement | Result |
|---|---|
| Full digest, this repo (1,895 commits, 33 records), `--since=2026-09-01`, 3 runs | 340–351 ms |
| Same, body only (`DEV_CYCLE_SCRUBBED=1`, so no re-exec and no scrub) | 344–355 ms; the re-exec plus two perl filters cost no measurable time |
| Section 7 walk (new), this repo | 24 ms |
| 33 `realpath` forks (`inrepo`, section 2) | 17 ms (the existing 33 `git log -1 -- f` calls take 98 ms) |
| Synthetic 220,000-commit repo (final-pass-4 generator, regenerated, then deleted), 14-day window, no commit-graph: db0e5ca vs 28c6178 full digest | 37.09 s vs 36.56 s |
| Same, with a commit-graph and Bloom filters | 9.36 s vs 7.64 s |
| Section 7 alone on the synthetic repo, old (net diff) vs new (path-limited walk), no graph / with graph | 2.34 s vs 1.00 s / 2.35 s vs 0.57 s |
| `scrub` on one line of k×`\xC2` followed by k×`\x80` (nested C1), k = 1,000 / 4,000 / 16,000 / 32,000 | 19 ms / 265 ms / 4,132 ms / 17,809 ms |
| `scrub` on a flat 1 MB line / 900 KB of 300,000 separate C1 pairs | 3 ms / 36 ms |
| End-to-end digest, temp repo, one 32,000-byte nested line in a decision record's `## Revisit triggers` | 4,131 ms (8,000-byte line: 281 ms) |

## Findings

#### 1. `1 while s///g` makes `scrub` quadratic on nested sequences: a committed 64 KB line stalls the digest for about 18 s, a 128 KB line passes the agent's 2-minute Bash timeout, and the cycle stops

**Severity:** Medium
**Location:** `scripts/dev-cycle.sh:34` (fed by `:137`, `:148`, `:123`, `:193`)
**Move:** Asymptotic behavior / parsing untrusted input with a parser that is slow on adversarial input (serialization tax)
**Classification:** Macro (passes × line length = O(L²)) / Cold path (once per cycle). Raised from Low because the cold path blocks the cycle: the digest fails, the cycle stops with no record, and the next run fails the same way.
**Confidence:** High (measured end to end)
**Baseline:** 17,809 ms of scrub time for one 64,000-byte line, measured 2026-10-01 (`perf5/nest.sh`). A clean 1 MB line takes 3 ms.
**Legibility-target:** for-author

**Evidence:**
```
  env -u PERL_UNICODE -u PERL5OPT LC_ALL=C perl -C0 -pe 'BEGIN { $| = 1 } tr/\000-\010\013-\037\177//d; 1 while s/\xC2[\x80-\x9F]|\xE2\x80[\x8E\x8F\xAA-\xAE]|\xE2\x81[\xA6-\xA9]|\xF3\xA0[\x80\x81][\x80-\xBF]//g'
```
(complete `scrub()` body, `:33-35`). An example feeding site, `:137`: `  trig < "$f" | sed 's/^/> /'`. That loop prints every non-blank line of a record's `## Revisit triggers` section, with no length limit.

Each `s///g` pass removes only the matches that are adjacent at that moment. For `\xC2`×k followed by `\x80`×k, only the innermost pair matches, so the loop runs k passes and each pass scans the whole line: O(L²). Doubling the line quadruples the time. The measurements show this: 4 KB 265 ms, 16 KB 4.1 s, 32 KB 17.8 s. Extrapolated, 128 KB takes about 70 s, 256 KB about 5 min and 1 MB about 75 min. Any committed decision record, decision-log row, roadmap Next line or merge subject can carry such a line. Section 2 prints every trigger on every run (`:16`, "nothing carries forward"), so the stall repeats every cycle until someone removes the line by hand. The lines that trigger it are the same nested-sequence inputs the R1 fix targets, so the fix turned a security bypass into a slowdown. The skill runs the digest with no timeout of its own. Under the agent's default 2-minute Bash timeout, a line of about 128 KB kills the digest, and SKILL.md:74-76 then stops the cycle. At 64 KB the digest finishes but is about 18 s slower.

**Recommendation:** Keep fixed-point semantics but rescan only around each deletion. One version, which I ran: `pos($_)=0; while (/PAT/g) { my $s=$-[0]; substr($_,$s,$+[0]-$s,""); pos($_) = $s>3 ? $s-3 : 0 }` (patterns are at most 4 bytes, so backing up 3 bytes is enough). It produced output identical to the current scrub on a 20,000-line random fuzz over the trigger bytes. On the 64 KB nested line it took 40 ms instead of 17.8 s. It still takes 8.7 s on a 1 MB nested line because `substr` has to move memory. Also cap each printed line before the scrub, for example `substr($_, 0, 4096)` plus a marker. That bounds both time and digest size. Add a bats case with a 64 KB nested line under `timeout 5`.

#### 2. Skill: an In-flight slot is freed only by a merge, so a build loop that hits a stop condition holds one of the 3 slots for good, and after three such loops 6b never launches again

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:190-196`, `:228-232`, `:181`
**Move:** Resource lifecycle (when is this freed?) / contention point
**Classification:** Macro (the capped pool leaks, and once it is full the loop's main output stops) / Cold path (once per cycle). Raised from Low because the failure is permanent and silent: 6b is the last step of every cycle and nothing reports the starvation.
**Confidence:** Medium (read from the skill text; not observed, since no cycle has run under c079e8c)
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** for-author

**Evidence:**
```
`you: judgment` names them), up to the in-flight cap: at most 3 loops in flight at once,
counting earlier cycles'.
```
(`:191-192`; the step continues through `:196`, "…before any loop starts.")
```
(`research-plan-implement`) on the brief's branch, from the default branch. A build that hits
a stop condition files a `you: judgment` entry instead of guessing. The cycle does not wait for
the loops; their merges come back through the next digest, where step 4 checks their claims
and docs, and the next cycle moves a merged item from In flight to Done.
```
(`:229-232`; the step ends with the final-message paragraph at `:234-235`.)

The only exit from In flight the skill names is "a merged item from In flight to Done". A loop that stops on a stop condition, crashes, or stalls (a known failure mode, per the memory note "Agent worktrees stall") never merges. Its item stays In flight and keeps counting against the cap of 3 in every later cycle. Step 1's cleanup also skips every branch and worktree "an open handoff brief names" (`:88-90`), and nothing defines when a brief stops being open. So stalled loops also leave worktrees behind. The digest prints `Roadmap In flight: N item(s)` (`scripts/dev-cycle.sh:237-240`), but nothing compares that count with live loops. With a 3-slot pool, three stopped loops end all handoffs. Brainstorm condition 1 (`:148`) looks only at Now + Next, so it does not notice the blockage either.

**Recommendation:** In step 3 or step 6, give each In-flight item a status check: merged → Done; branch has a `you: judgment` stop entry, or no commits for N days → back to Now, marked blocked with its Q-NNN. Only items that are actually running count against the cap. Define "open brief" as "its item is still In flight".

#### 3. Skill: every cycle now lands its chore branch through `pr-prep`, so a full review-fix loop runs on a docs-only branch once per cycle, at a cadence of up to many a day

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:222-224`, `:151`
**Move:** Price the deployment environment (cost per run × run frequency) / hidden multiplication
**Classification:** Micro per cycle (one review loop) / effectively hot when cycles run "many a day"
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** for-author

**Evidence:**
```
questions changes, then land `chore/dev-cycle-<date>` on the default branch through `pr-prep`
before step 6b: the next digest and the build loops both start from the default branch.
```
(`:223-224`; the paragraph starts at `:220`, "Record one verdict for every trigger…")
```
- a week or more since the last brainstorm, by date (cycles vary from fortnightly to many a day);
```
The old skill (6ee33e3:31-32) sent only *code fixes* through `pr-prep`. Now the cycle record, the roadmap, questions.md and the handoff briefs go through it every cycle. pr-prep step 5 runs the code-review orchestrator, which includes a k-replicate fact-check and parallel critics. I found no docs-only shortcut in `workflows/pr-prep.md` or `skills/code-review/SKILL.md` (grep for "docs-only|doc-only"). The lightweight review path in decision 030 may cover this; that is unverified. Cost per cycle grows with cycle frequency. 6b waits for the landing, so review latency also delays every handoff.

**Recommendation:** Name the review tier for the cycle's own branch, either decision 030's lightweight path or "local merge after `questions.sh check` and the health check". Keep the full `pr-prep` loop for code fixes, as the old text did.

#### 4. Section 7 counts every touch, so step 4b's "skill or workflow file changed" trigger fires on almost every cycle, and the "substantially changed" judgment costs one diff read per listed file

**Severity:** Low
**Location:** `scripts/dev-cycle.sh:221-232`; `skills/dev-cycle/SKILL.md:133-141`
**Move:** Question the cache (hit rate of a conditional gate) / hidden multiplication
**Classification:** Macro (judgment work grows with the number of files touched in the window) / Cold path
**Confidence:** Medium
**Baseline:** 43 skill/workflow files and 17 decision records listed for the window `--since=2026-09-01` on this repo (69 merges), measured 2026-10-01
**Legibility-target:** for-author

**Evidence:**
```
changed="$(git log "$MAIN_SHA" --first-parent --diff-merges=first-parent --name-only --format='@%cs' -- skills workflows docs/decisions \
  | awk -v s="$SINCE" '/^@/ { on = (substr($0, 2) >= s); next } on && NF' | sort -u)"
```
(`:221-222`; the per-kind print loop follows at `:226-233` and caps each list at 20 names plus "… N more".)
```
It is too large for every cycle, so this step
only decides whether one is due.
```
(SKILL.md:132-133; the triggers follow at `:135-137`: "a skill or workflow file added or substantially changed in the window".)

Fixing A8 correctly made section 7 a union of every touch. The cost is that a one-line wording edit and a reverted change both count as "changed", with no size information. In an active repo the list is rarely empty: 43 files in one month here. The skill then has two bad choices. It can open the diff for each file to judge "substantially", which costs N reads and has no hint for the 23 files hidden behind "… more". Or it can treat any count above zero as fired, which files a deep-audit task every cycle and defeats "too large for every cycle".

**Recommendation:** Print churn next to each name (`--numstat`, summed over the window, with "+a −b" and "reverted" when the net change is 0). Sort the list by churn so the 20 names shown are the largest. Then the skill can state a threshold, for example "≥ 20 % of the file's lines". The union semantics A8 asked for stay.

#### 5. `inrepo` forks `realpath` once per read site

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:67`, `:130`
**Move:** Hidden multiplication
**Classification:** Micro (one fork per decision record plus 4 fixed calls) / Cold path
**Confidence:** High
**Baseline:** 17 ms for the 33 calls in section 2 on this repo, measured 2026-10-01. The pre-existing `git log -1 -- "$f"` in the same loop takes 98 ms.
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
inrepo() { local r; [[ -f "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" && [[ "$r" == "$ROOT_REAL"/* ]]; }
```
This is linear in the number of records and about a sixth of the cost of the loop's existing git call. No action needed.

**Recommendation:** None. Final pass 4's finding 2 (the git call for each record) is still the larger cost, if anyone tunes this loop.

## Endorsements (evidence-gated)

- The re-exec through two scrub filters adds no measurable wall time. On this repo the full digest took 340–351 ms with them and 344–355 ms without. `[unverified — submitted as claim]` (my own timing; this is not a fact-check execution verdict)
- Section 7's path-limited walk is faster than the net diff it replaced: 1.00 s vs 2.34 s on a 220,000-commit synthetic repo without a commit-graph, and 0.57 s vs 2.35 s with one. The full digest is not slower than db0e5ca (36.56 s vs 37.09 s; 7.64 s vs 9.36 s). `[unverified — submitted as claim]` (synthetic repo touches no `skills/` or `workflows/` paths, so name output is near zero; a skills-heavy history adds output proportional to touches)
- Section 6 no longer runs a `git log -1` per flagged merge. It reuses the `rest` field from `merges_full` and prints at most 30 lines. This closes the output-size half of final pass 4's finding 3; the per-merge `git diff` + `awk` spawns remain. `[read: scripts/dev-cycle.sh:117-118,202-214]`
- Step 4's fan-out is bounded: one subagent per sampled merge (default `--sample` 2) plus steps 2, 3 and 4b, about 5 concurrent subagents. Section 6's list, which step 4 also checks, is capped at 30 lines. `[read: skills/dev-cycle/SKILL.md:56-60; scripts/dev-cycle.sh:14,47,212-213]`
- Step 1 makes the health check finish before steps 2–4b start their own tests, which keeps two full test runs from competing for the checkout and CPU. Concurrent tests from parallel subagents in steps 2–4 still share one working tree; that contention is unmeasured. `[read: skills/dev-cycle/SKILL.md:80-82]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `1 while s///g` is O(L²) on nested sequences; a committed ~128 KB line kills the digest under a 2-min timeout and stops every cycle | Medium | `scripts/dev-cycle.sh:34` | High |
| 2 | In-flight slots are freed only by a merge; stopped or stalled loops starve 6b for good | Medium | `skills/dev-cycle/SKILL.md:190-196,228-232` | Medium |
| 3 | Every cycle's docs-only chore branch goes through the full `pr-prep` review loop, at up to many cycles a day | Low | `skills/dev-cycle/SKILL.md:222-224` | Medium |
| 4 | Section 7's union list has no size information, so 4b fires on almost every cycle or costs N diff reads | Low | `scripts/dev-cycle.sh:221-232`; `SKILL.md:133-141` | Medium |
| 5 | `inrepo` forks `realpath` per file (17 ms for 33 files) | Informational | `scripts/dev-cycle.sh:67` | High |

## Overall Assessment

Most of A's fixes cost nothing or speed things up. The re-exec adds no measurable time, section 7's walk is faster than the net diff at 220k commits, and section 6 dropped a process per flagged merge and gained a cap. The exception is the R1 scrub fix. Its fixed-point loop is quadratic on exactly the nested input it was written to catch, so the hostile-text threat model now has a slowdown route instead of a bypass route. A committed line of about 128 KB stops every future cycle. A linear rescan, which I tested and which gives identical output on the fuzz input, plus a per-line cap fixes it in place. This should be fixed before merge, because the skill turns any digest failure into "stop the cycle". B's costs are in the process rather than the code. The 3-slot in-flight cap has no release path for loops that do not merge, landing every cycle through `pr-prep` multiplies review cost by cycle frequency, and section 7's sizeless union makes the "conditional" deep-audit check nearly unconditional. All three are fixable in the skill text. Finding 2 needs a slot-release rule before the loop is used unattended. No profiling is needed for finding 1; findings 2–4 should be checked against the first few real cycles.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `docs/reviews/performance-review-2026-10-01-digest-final5.md` in wt-digest. It follows the performance-reviewer structure: header, Data Flow and Hot Paths, Findings with Severity, Location, Move, Classification, Confidence, Baseline and Legibility-target, plus verbatim Evidence and truncation notes, then tagged Endorsements, Summary Table and Overall Assessment. It covers the brief's unit A focus areas (re-exec, `1 while` loop, `inrepo`, section 7 walk) and unit B's cycle cost (parallel subagents, in-flight cap, landing). Probe cleanup: the synthetic repo and the large probe inputs were deleted, no probe processes are left, and nothing was written to either worktree except this file. Not committed.
