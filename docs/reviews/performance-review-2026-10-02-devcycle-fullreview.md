Commit: 2fd9401

# Performance Review — feat/dev-cycle k=1 full review (whole branch)

**Scope:** `git diff main...2fd9401 -- . ':!docs/reviews'`: 13 files, about 2,500 added lines. The main subjects are `scripts/dev-cycle.sh` (the digest and its six `--check-*` modes) and `skills/dev-cycle/SKILL.md` (the per-cycle call pattern).
**Date:** 2026-10-02
**Based on:** pass 36's k=1 fact-check (`/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass36.md`, used as context) and the rubric `code-review-rubric-2026-09-29-feat-dev-cycle-digest.md`, passes 21–36. Every finding is graded against my own execution on 2fd9401.

Probes are in `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/perffull/`: P1 `p1-thisrepo.sh`, P2 `p2-synth.sh` with `gen.py`, P3 `p3-bats.sh`, P4 `p4-components.sh`, plus their logs. Each probe script makes its own temp dir with `mktemp -d -p` and checks `$PWD` against it before writing. Every generator and every run was under `timeout`. The one background watcher was stopped by its task ID. Nothing was written to either worktree except this file, and `git status` in wt-devcycle shows only the sibling critics' untracked reports.

## Data Flow and Hot Paths

The skill runs `dev-cycle.sh` once per cycle, or twice when step 0 reruns it with `--since`. Then it makes a few dozen check-mode calls, at most a few per brief and per write. Cycles start by hand, "fortnightly to many a day" (`SKILL.md:239-240`), and at most one record is written per day (`SKILL.md:349`). **Every path in this diff is cold.** The scale inputs are history length, the number of decision records and log rows, cycle records, the questions archive, briefs, and the merges in the window.

Measured on 2fd9401 (P1, P2, P4). All runs exit 0, and the outputs are byte-identical with and without a commit-graph.

| Input | Digest | Notes |
|---|---|---|
| This repo (2,087 commits, 32 records, 68 rows, 14-day window) | 566 ms, 123 git calls (112 are section 6's per-merge `git diff`), 28.7 KB | Window starting 2000-01-01: 1.3 s, 445 git calls |
| Synthetic: 242,001 commits, 22,000 first-parent merges, 300 records, 300 revisit rows, 365 cycle records, 890 KB archive, 500 closed briefs | 11.7 s with no commit-graph, 6.8 s with changed-paths bloom; 69 KB | 365-day window: 16.9 s / 15.7 s |

Components on the synthetic repo, bloom / no graph (P4): commits walk `:606` 2.6 s / 2.6 s; first-parent merges walk `:603` 0.47 / 1.09 s; section 7 walk `:764` 0.77 / 1.30 s; date map `:631` 0.19 / 1.17 s; 300 log rows `:653-662` 0.69 s; 300 records `:634-651` 0.9–2.3 s (cache noise); 365 cycle records `:561-572` 0.6 s; section 6 `:745-750` 0.5–1.1 s for 13 merges in the window, 5.2–6.1 s for 2,451 merges in a year.

Check modes, per call (P1 on this repo; P2 on the synthetic repo):

- **Fixed floor.** `--check-write`, `--check-fix` and `--check-path` on one plain file each take 17–25 ms. The cost is two bash processes, two perl scrubs, and three git calls to resolve the default branch.
- **`--check-brief`.** 16 ms for `new`. A landed brief takes 222 ms with bloom and 1,110 ms with no graph on the synthetic repo, where its Status line dates from the root commit, 242k commits back.
- **`--check-branch`.** Three names take 104 ms with bloom and 598 ms with no graph, including one branch forked about 150k commits back.
- **`--check-answer`.** About 10 ms per ID on this repo's 189 KB archive: 103 IDs took 1.04 s. On the 890 KB archive, about 28–45 ms per ID.

The bats suite takes 16.7 s for 49 tests, all passing (P3). The merge 2fd9401 leaves main's `scripts/` and `test/` untouched apart from the two dev-cycle files: `git diff bf54363 2fd9401 -- scripts test` shows nothing else.

## Findings

Nothing at Medium or above. Every item below is cold. Each was already filed in an earlier pass and kept by decision, or is new at Informational. **No new known issue for the loop.**

#### 1. Each digest run walks the whole history three times, so the digest's floor grows with repo age, not with the window

**Severity:** Low (carried: rubric full-review C3 and final-4 C2, kept)
**Location:** `scripts/dev-cycle.sh:603`, `:606`, `:764-765`. I read section 1 (`:598-609`) and section 7 (`:758-776`) in full, and followed `merges_full` to section 6 (`:745-750`) and `changed` to `:766-767`.
**Evidence (verbatim):** `commits="$(git log "$MAIN_SHA" --format=%cs | awk -v s="$SINCE" '$1 >= s' | wc -l)"`
**Move:** 2 (size of N); 9 (asymptotic behavior)
**Classification:** Macro (linear in total history, not in the window) / Cold path (once per cycle)
**Confidence:** High (measured)
**Baseline:** 2.6 s for the commits walk alone at 242,001 commits; whole digest 6.8 s with bloom, 11.7 s with no commit-graph (P2/P4, 2026-10-02)
**Legibility-target:** maintainer

The walks are deliberately unbounded. They are the R3 fix: `--since` stopped at the first old-dated commit. So the digest pays O(history) on every run. At a quarter-million commits the digest still finishes in under 12 s, which is about a tenth of the 120 s Bash default. Reaching that limit would take roughly ten times this history.

**Recommendation:** No change for merge. If a much larger repo adopts the skill, `--since-as-filter` with a margin (git ≥ 2.37; this sandbox has 2.39.5) is the known lever. Its margin claim is still pending verification.

#### 2. Section 6 forks one `git diff` per merge in the window, so a wide `--since` rerun costs seconds per thousand merges

**Severity:** Low (carried: full-review C1, kept as "bounded for realistic windows")
**Location:** `scripts/dev-cycle.sh:745-750` (the whole loop, plus the cap at `:751-756`)
**Evidence (verbatim):** `counts="$(git diff --name-only -z "$full^1" "$full" | awk -v RS='\0' 'NF { b = tolower($0); sub(/.*\//, "", b); p = tolower($0); if (p ~ /^docs\// || p ~ /\.md$/ || b == "readme" || index(b, "readme.") == 1) d++; else c++ } END { print c + 0, d + 0 }')"`
**Move:** 1 (hidden multiplication)
**Classification:** Macro (linear in the window's merges, at about 2 ms each) / Cold path
**Confidence:** High (measured)
**Baseline:** 5.2–6.1 s for 2,451 merges in a 365-day window on the synthetic repo; 112 of this repo's 123 git calls in a 14-day window (P1/P4, 2026-10-02)
**Legibility-target:** maintainer

Step 0 can rerun the digest with `--since` set to the last cycle known to have run (`SKILL.md:145-149`). After a long gap, that window is wide. The output is capped at 30 lines, but the work is not. A single `--first-parent --merges --diff-merges=first-parent --name-only` walk measured 4.2–4.5 s here against 5.2–6.1 s for the loop. So the earlier "0.5 s vs 25 s" estimate does not carry over to a repo with 22k merges in total. The saving depends on the shape of the history.

**Recommendation:** No change. The loop is linear and its windows are short in practice. Do not adopt the one-walk alternative on the strength of the earlier figure alone.

#### 3. The skill makes one check-mode call per item where every mode takes many arguments, about 18 calls per cycle where about 7 would do

**Severity:** Informational (new at this level of detail; the fixed per-call floor was noted in pass 24 #2)
**Location:** `skills/dev-cycle/SKILL.md:269-312` (In flight checks 1–3), `:323-334` (new-brief naming), `:61-103` (the Rules' check list). I read all three in full, plus the dispatch loop at `scripts/dev-cycle.sh:545-557`.
**Evidence (verbatim):** `A brief's state comes only from \`--check-brief '<path>'\`` and `for a in "${CHECK_ARGS[@]}"; do`
**Move:** 1 (hidden multiplication: process and agent-turn cost per item)
**Classification:** Micro (fixed cost per call) / Cold path (once per cycle)
**Confidence:** Medium. The counts are derived from the skill text. The per-call floor is measured.
**Baseline:** 17–25 ms per call floor: two bash processes, two perl processes and three git calls (P1, 2026-10-02)
**Legibility-target:** agent running the skill

Take a cycle with three briefs holding slots. It makes the glob call, then four calls per brief (`--check-path`, `--check-brief`, `--check-answer`, `--check-branch`), then about four `--check-write` calls at close: roughly 18 calls before any repo-text paths. Every input those calls need (the paths, the unapplied IDs, the branch names) is known as soon as the In flight lines and briefs are read. One call per mode would carry them all, and each output line names its argument. The script time is under a second either way. What batching saves is about ten agent tool turns per cycle. Nothing grows: slots are capped at 3, and only IDs not yet applied are passed, which is at most one per brief because a new question waits until the last one is answered (`SKILL.md:300-302`).

**Recommendation:** Optional. One sentence in the Rules: "each check mode takes many arguments; pass all of a step's values to one call."

#### 4. Every trigger is re-judged every cycle, so the agent's step-2 work grows with the decision history

**Severity:** Informational (carried: full-review #5; the design is the user's Q-101 [1] choice)
**Location:** `scripts/dev-cycle.sh:612-677`; `skills/dev-cycle/SKILL.md:177-188`
**Evidence (verbatim):** `The previous record's verdicts are context, never the answer: decide each one again.`
**Move:** 2 (size of N)
**Classification:** Macro (linear in decision records and log rows) / Cold path
**Confidence:** High (measured sizes)
**Baseline:** Section 2 is 18.3 KB of the 28.7 KB digest on this repo (22 trigger sources, 61 trigger lines), and 66.4 KB of 69.3 KB with 300 + 300 sources (P1/P2, 2026-10-02)
**Legibility-target:** user

This repo has added about 37 records in six months. Every one with a trigger is added to every future cycle's verdict list. The script cost is small: 300 rows take 0.69 s and 300 records 0.9–2.3 s. The agent cost of a written verdict with evidence per trigger is what grows. That cost was the price of cutting carry-forward, and the user accepted it.

**Recommendation:** None for merge. The existing deep-audit and revisit machinery is the place to retire triggers that have fired or no longer apply.

#### 5. `--check-brief` walks back to the commit that set the brief's Status line, about 1 s per brief at 242k commits with no commit-graph

**Severity:** Informational (carried: pass 25 #1, pass 27 #1)
**Location:** `scripts/dev-cycle.sh:372-373`, in `check_brief` (`:346-375`, read in full)
**Evidence (verbatim):** `c="$(git log -1 --format=%H --first-parent --diff-merges=first-parent -s -G'^Status: ' "$MAIN_SHA" -- "$a")"`
**Move:** 9 (asymptotic behavior)
**Classification:** Macro (linear in the first-parent history since the Status line was set) / Cold path (at most about 6 calls per cycle)
**Confidence:** High (measured)
**Baseline:** 1,110 ms for one brief and 3,603 ms for three with no graph; 222 / 675 ms with bloom. The worst case is a Status line set at the root commit (P2, 2026-10-02)
**Legibility-target:** maintainer

Real briefs live for weeks, so the walk is short. The synthetic case is an upper bound.

**Recommendation:** None.

#### 6. Small linear costs that grow with the bookkeeping files, all bounded at realistic sizes

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:561-572` (the cycle-record loop: one `realpath` subshell and one `date` per record); `:499-503` (`--check-answer`: two awk passes over both questions files per ID)
**Evidence (verbatim):** `r="$(env LC_ALL=C awk -v id="$a" "$FENCE_AWK$ANSWER_AWK" "$f")"`
**Move:** 2 (size of N)
**Classification:** Micro / Cold path
**Confidence:** High (measured)
**Baseline:** 365 cycle records take 0.6 s, about 1.6 ms each. `--check-answer` takes about 10 ms per ID at 189 KB of archive and 28–45 ms per ID at 890 KB (P1/P2/P4, 2026-10-02)
**Legibility-target:** maintainer

There is at most one cycle record per day, so a year of daily cycles adds 0.6 s. The skill passes `--check-answer` only the IDs not yet applied, a handful per cycle, so the archive's growth costs milliseconds.

**Recommendation:** None.

## Endorsements

- The date map replaces one `git log` per record with one walk: 300 records cost 0.19 s with bloom and 1.17 s with no graph (P4). The earlier figure was records × history, 167.7 s at 301 records (rubric pass 17). `[unverified — submitted as claim]`
- The digest and every check mode give byte-identical output with and without a changed-paths commit-graph on the 242k-commit repo (P2). `[unverified — submitted as claim]`
- The skill's per-cycle check-call count does not grow with the age of the repo. Slots are capped at 3 (`SKILL.md:324`), and `--check-answer` receives only IDs not yet applied, with a new keep-or-drop entry filed only once no `Asked:` ID is still open (`SKILL.md:285-302`). `[read: skills/dev-cycle/SKILL.md:269-312, 323-325]`
- Main's run-tests `--jobs` work is untouched by merge 2fd9401: no path under `scripts/` or `test/` differs from bf54363 except the two dev-cycle files. `[unverified — submitted as claim]`
- None of pass 33–36's FENCE_AWK fixes (`opencomment` split, single-`match` marker strip) regressed: real-file `--check-answer` over all 103 IDs here took 1.04 s with no skips (P1). `[unverified — submitted as claim]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Three whole-history walks per digest run (6.8–11.7 s at 242k commits) | Low (carried) | `scripts/dev-cycle.sh:603,606,764` | High |
| 2 | Section 6: one `git diff` per window merge (5–6 s for a year's 2,451 merges) | Low (carried) | `scripts/dev-cycle.sh:745-750` | High |
| 3 | One check call per item instead of one per mode (about 18 vs about 7 calls per cycle) | Informational | `skills/dev-cycle/SKILL.md:269-334` | Medium |
| 4 | Every trigger re-judged every cycle; section 2 is most of the digest | Informational (carried, user's choice) | `scripts/dev-cycle.sh:612-677`; `SKILL.md:177-188` | High |
| 5 | `--check-brief`'s `-G` walk is about 1 s per brief with no graph at 242k commits | Informational (carried) | `scripts/dev-cycle.sh:372-373` | High |
| 6 | Cycle-record loop and `--check-answer` are linear in their files | Informational | `scripts/dev-cycle.sh:561-572, 499-503` | High |

## Overall Assessment

The branch's performance posture is sound for what it is: a cold path run by hand once per cycle. On this repo the digest takes 0.57 s and each check call takes 17–25 ms. On a synthetic history 116 times larger (242k commits, 300 records, 300 trigger rows, 365 cycle records, a 0.9 MB archive) the digest takes 6.8–11.7 s and a year-wide rerun about 16 s, all far under the 120 s tool limit. The check modes stay under 1.2 s per call. Every earlier cliff is gone and measured gone: per-record `git log`, the uncapped glob, the quadratic scrub, `opencomment` and `refdef`. What remains is linear and cold: the full-history walks (#1, #2) were kept by decision, and the trigger re-judging cost (#4) is the user's chosen design. The one new item (#3) is an optional sentence that would save agent turns, not compute. Nothing needs profiling before merge. **From the performance lane, this full pass finds no known issue.**

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file." This report is saved at `/workspace/.claude/wt-devcycle/docs/reviews/performance-review-2026-10-02-devcycle-fullreview.md`, first line `Commit: 2fd9401`. It follows the performance-reviewer structure: header, data flow, findings with Baseline and Classification plus the requested Severity, Location, Evidence, Confidence and Legibility-target fields, evidence-tagged endorsements, summary table and overall assessment. It covers the whole branch: the digest on this repo and on a large synthetic history, every check mode, and the skill's per-cycle call cost. It serves the user's goal of a clean k=1 full pass: from this lane, nothing needs fixing before the merge.
