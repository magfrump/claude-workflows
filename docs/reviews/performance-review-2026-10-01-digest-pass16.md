Commit: 09f6fe7 (A) / 5423a33 (B)

# Performance Review — dev-cycle pass 16 (pass-15 fix round, k=1)

**Scope:** Partial. A: `git diff f47de85..09f6fe7 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (commit 09f6fe7), in `/workspace/.claude/wt-digest`. B: `git diff cb2e5f9..5423a33 -- skills/dev-cycle/SKILL.md`, in `/workspace/.claude/wt-devcycle`. Everything else on both branches is context only.
**Date:** 2026-10-01
**Based on:** `docs/reviews/code-fact-check-report-digest-pass15.md` (Stage-1 context named in the brief). It covers the pass-14 round at f47de85 / cb2e5f9, not this round's diff, so none of its verdicts is an execution verdict on the lines under review. Its Claim 19b (Incorrect) binds this review: it refuted the date-bounded "each answer counts once" mechanism that my pass-15 report endorsed (see Endorsements).

Scratch: `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/perf16/` (`perf16/` below).
- `bats.log`: `timeout 600 bats test/scripts/dev-cycle.bats`, cwd `/workspace/.claude/wt-digest` (`git diff --stat 09f6fe7 HEAD -- scripts test` empty), 2026-10-02T06:50:00Z, exit 0, 23/23 ok, 7.698 s wall.
- `probe.log` (script `perf16/probe.sh`): `timeout 300`, 2026-10-02T06:49:47Z, exit 0. Throwaway repos under `mktemp -d`, removed on exit. For the 09f6fe7 script, it counts `realpath -e` calls and `questions.sh open` forks inside section 3 under `bash -x`. It covers questions.md x archive, each absent / plain / symlinked / a directory (16 combinations, questions.sh present), plus questions.sh absent (two cases) and a symlinked `docs/working/`. It also records section 3's first lines, section 8's list, and the mean of 20 full digest runs.
- `probe-old.log` (script `perf16/probe-old.sh`): the same probe against the f47de85 script and its questions.sh (from `git show`, copied into scratch), run the same day. It gives the before/after comparison below.

Legibility-target values: **maintainer** (someone editing the script or tests), **agent** (the model running the skill), **user** (the human reading the digest).

## Data Flow and Hot Paths

A: `dev-cycle.sh` runs once per dev cycle, by hand or by an agent, and the skill reruns it at most once with `--since`. Section 3 (`scripts/dev-cycle.sh:242-278`) is now one `if/elif` chain over two fixed paths of depth 3. Each `blocker` walk is a command-substitution subshell plus one `realpath` fork per existing component, and at most one `bash questions.sh open` fork runs (only in the final `else`). All of it is **cold** and fixed-size: nothing in it loops over repo data. Measured: a full digest averages 56 ms on a near-empty repo (`perf16/probe.log`, 20 runs; 61 ms for f47de85 in `probe-old.log`, the same within noise).

B: the In-flight rule (`skills/dev-cycle/SKILL.md:224-237`) runs once per cycle for each open build brief. Step 6 caps open briefs at 3 (`:247-248`). Step 2 now searches `questions.md` and `questions-archive.md` for questions naming the brief's path, then compares each answered hit's ID with the brief's `Answered:` line. The archive grows without bound over a project's life, but it is searched, never read whole, and only for briefs that are still open.

Measured section-3 cost, `realpath -e` calls (f47de85 → 09f6fe7; `questions.sh open` forks unchanged in every row):

| questions.md / archive | f47de85 | 09f6fe7 |
|---|---|---|
| plain / plain (the normal case) | 12 | 9 |
| plain / absent | 11 | 8 |
| absent / plain, absent / symlink | 6 | 7 |
| plain / absent, questions.sh absent | 9 | 8 |
| all other 13 rows | same | same |

## Findings

#### The archive is now walked even when questions.md is absent

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:250` (A, 09f6fe7)
**Evidence (verbatim):** `qa_at=""; skipped "$QA" && qa_at="$SKIP_AT"` (the unit continues to `:251-278`: the `nc=` banner and the five-way chain; `qa_at` is first read at `:258`, `elif [[ -n "$qa_at" ]]; then`)
**Move:** Work that moved to the wrong place
**Classification:** Micro (one fixed-depth path walk) / Cold path (once per digest run)
**Confidence:** High
**Baseline:** absent-questions.md rows go from 6 to 7 `realpath -e` calls in section 3, with a 56 ms mean full digest, measured in `perf16/probe.log` and `perf16/probe-old.log` (2026-10-02T06:49Z)
**Legibility-target:** maintainer

The archive check moved from inside two branches to before the chain. In repos with no questions.md, section 3 now does one archive walk it used to skip: one subshell and at most one more `realpath` fork, under 1 ms of a 56 ms run. That walk is what lists a non-plain archive in section 8 in those rows (probe: `qm=absent qa=symlink` and `qa=dir` both list `- docs/working/questions-archive.md`). So it buys a stated feature of this round at a cost that cannot grow. The `mktemp` and its `trap` stay inside the `else` branch (`:261`), so no temp file is made on the early-exit branches.

**Recommendation:** None.

#### Test 10 gains one full digest run

**Severity:** Informational
**Location:** `test/scripts/dev-cycle.bats:220-226` (A, 09f6fe7)
**Evidence (verbatim):** `rm docs/working/questions.md` / `run --separate-stderr bash "$DC"` (the unit continues to `:224-226`, the two assertions and the restoring `printf '# Running questions\n\n## Open\n' > docs/working/questions.md`, then the existing mixed-case block)
**Move:** Hidden multiplication
**Classification:** Micro / Cold (test suite)
**Confidence:** High
**Baseline:** 7.698 s wall for the 23-test suite, measured in `perf16/bats.log` (2026-10-02T06:50:00Z); one digest run measured at 56 ms mean in `perf16/probe.log`
**Legibility-target:** maintainer

The new absent-questions.md case reuses test 10's repo and adds one `run`, under 1% of suite wall time. It also restores questions.md, so the case after it runs on the same fixture as before. This is the cheapest way to cover the case: no new `make_repo`.

**Recommendation:** None.

#### Step 2 re-reads every keep-or-drop question for an open brief each cycle

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:228-233` (B, 5423a33)
**Evidence (verbatim):** `Search` / `` `questions.md` and `questions-archive.md` for questions naming this brief (the cycle's `` / `step 1 has already archived answered entries; search, do not read the archive whole), and apply` / `each answered one whose ID is not on that line:` (the unit continues to `:233`, `"keep" adds its ID to \`Answered:\` and sets \`Kept: <today>\`; "drop" adds its ID and closes the brief as in 1.`, then step 3 at `:234-237`)
**Move:** Ask "what's the size of N?"
**Classification:** Micro (per-hit ID check) / Cold (once per cycle, at most 3 open briefs)
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** agent

Each cycle, the agent finds every question naming an open brief, including ones already applied, and checks each ID against `Answered:`. The hit count per brief is the number of keep-or-drop questions filed for it. Step 3 files one only when none is open and 14 days have passed since the last `Kept:`, and a "keep" resets `Kept:` to today. So the count grows by at most one per 14 days of a brief's life, and the work stops when the brief closes (steps 2 and 3 now apply "if the brief is still open"). With at most 3 open briefs, this stays a few lines of reading.

**Recommendation:** None.

No finding at Low or above. A's chain does strictly less work in the normal case than f47de85 did, and B adds no executable code.

## Endorsements (evidence-gated)

- A, section 3: `questions.sh` is forked only from the final `else`. Every other branch (questions.md or archive skipped, questions.md absent, questions.sh missing) prints a fixed line and forks nothing. The probe's fork count is 0 in all 17 non-`else` rows and 1 in the 2 `else` rows. [read: /workspace/.claude/wt-digest/scripts/dev-cycle.sh:250-278]
- A, section 3: the normal path (questions.md and archive plain, questions.sh present) dropped from 12 to 9 `realpath -e` calls. The chain no longer repeats `inrepo docs/working/questions.md && [[ -f "$QS" ]]` in two `elif`s, which is the fix my pass-15 Informational finding suggested. [read: /workspace/.claude/wt-digest/scripts/dev-cycle.sh:252-260] (counts in `perf16/probe.log` vs `perf16/probe-old.log`)
- B, step 2: each answer is applied at most once by the text's own rule. An answer applies only if its ID is not already on the brief's `Answered:` line, and applying it adds that ID. "Keep" *sets* `Kept: <today>`, so a re-found answer can no longer add a line each cycle. This replaces the date bound that the pass-15 fact-check refuted for undated answers (Claim 19b, Incorrect). My pass-15 endorsement of that date bound is withdrawn. Whether an agent follows the rule reliably is not established by reading it. [read: /workspace/.claude/wt-devcycle/skills/dev-cycle/SKILL.md:228-233]
- B, steps 2–3: applying answers and the 14-day ask now run only for briefs that are still open, so closed briefs drop out of the per-cycle archive search. [read: /workspace/.claude/wt-devcycle/skills/dev-cycle/SKILL.md:228, 234]
- B, step 3: "and no question naming this brief is open" keeps one open keep-or-drop question per brief at a time, so repeated cycles do not stack asks in questions.md. [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | The archive is now walked even when questions.md is absent (+1 `realpath`, <1 ms) | Informational | `scripts/dev-cycle.sh:250` | High |
| 2 | Test 10 gains one digest run (<1% of suite time) | Informational | `test/scripts/dev-cycle.bats:220-226` | High |
| 3 | Step 2 re-reads every keep-or-drop question for an open brief each cycle (≤1 new per 14 days) | Informational | `skills/dev-cycle/SKILL.md:228-233` | Medium |

## Overall Assessment

This round has no performance problems. A's single ordered chain does less work in the normal case (9 rather than 12 `realpath` calls) and one extra fixed walk only in the no-questions.md rows, which is what lets a non-plain archive appear in section 8. Every path is cold, fixed-size, and measured at about 56 ms per digest. B removes the growth path the pass-15 fact-check found, where an undated "keep" re-applied each cycle. ID-keyed application is bounded by the number of questions filed, which is at most one per 14 days per open brief. I checked these rules for hidden multiplication, unbounded growth and wasted forks: section 3's chain in all 19 probed combinations, step 2's ID check, and steps 2–3's "still open" guard. Within this lens they are correct and complete. No profiling is needed.

One note outside this lens, for sibling critics: step 3's guard counts *any* open question naming the brief's path, not only keep-or-drop ones. An unrelated open entry that cites the brief would therefore hold back the ask while it stays open. Whether that is intended is a question for API-consistency or fact-check, not a performance finding.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file." This report is saved at `/workspace/.claude/wt-digest/docs/reviews/performance-review-2026-10-01-digest-pass16.md`. Its first line is `Commit: 09f6fe7 (A) / 5423a33 (B)`, and it follows the skill's structure: header, Data Flow, Findings with Baseline and Classification, Endorsements with evidence tags, Summary Table, Overall Assessment. Each finding also carries the Severity, Location, Evidence (verbatim), Confidence and Legibility-target that the brief asks for. It serves the user goal (merge both branches once a clean pass is reached) by adding no blocking finding from the performance lens for this round.
