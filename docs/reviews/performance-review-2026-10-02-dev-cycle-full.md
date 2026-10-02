Commit: bc5dc76

# Performance Review — feat/dev-cycle, full branch (k=1 final confirming pass)

**Scope:** `git diff main...HEAD -- . ':!docs/reviews'` at bc5dc76 in `/workspace/.claude/wt-devcycle` (13 files). Performance-relevant: `scripts/dev-cycle.sh`, `test/scripts/dev-cycle.bats`, `skills/dev-cycle/SKILL.md` (per-cycle cost). The other 10 files are prose with no execution cost.
**Date:** 2026-10-02
**Based on:** `docs/reviews/code-fact-check-report-dev-cycle-full.md` (the fresh full-branch fact-check, Commit: bc5dc76, 80 claims, 0 incorrect). Its Claims 31 (scrub bounded by the cut, executed) and 33 (re-exec waits for both filters, executed) are used below.

**Working-tree note.** While this review ran, the worktree held uncommitted edits that I did not make, to `skills/dev-cycle/SKILL.md`, `docs/dev-cycle.md` and `docs/working/seed-build-loop-handoff.md`. All SKILL.md citations below are to the committed text (`git show bc5dc76:skills/dev-cycle/SKILL.md`). `scripts/` and `test/` had no uncommitted changes, so every measurement is of the bc5dc76 script.

**Measurements** (all mine, 2026-10-02, this sandbox, git 2.39.5, mawk as `awk`). Scratch: `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/perfF/` (`perfF/` below). Per-section times come from `perfF/sections.sh`, which runs the body with `DEV_CYCLE_SCRUBBED=1` under `bash -x` and timestamps the section headers.

| Run | Result |
|---|---|
| This repo (1,973 commits on HEAD; `main` at bf54363), default 14-day window, 64 merges, 5 runs (`perfF/thisrepo.log`) | 392–437 ms |
| Same, per section (`perfF/sections.sh`) | setup 13, s1 44, s2 151–158, s3 19–23, s4 2, s5 5, s6 124–127, s7 37–39, s8 1 ms |
| This repo, `--since=2026-01-01` (386 merges) | 984–1,015 ms; s6 733–757 ms (1.9 ms per merge) |
| Same, body only (`DEV_CYCLE_SCRUBBED=1`) vs scrubbed, 3 pairs | 977–1,013 ms vs 990–1,015 ms; byte-identical output |
| Synthetic repo (`perfF/gen.py`, `git fast-import`): 200,001 commits, 20,000 first-parent merges, 300 decision records with `## Revisit triggers` created in the root commit, 500 log rows mentioning "Revisit", dates over 9 years; 14-day window (85 merges), **no commit-graph** (`perfF/synth-nograph.log`) | **255.7 s** full digest; s1 2.8 s, **s2 244.6 s**, s5 0.76 s, s6 0.21 s, s7 0.94 s |
| Same, commit-graph **without** Bloom filters (`git commit-graph write --reachable`, what `git gc` writes by default) (`perfF/iso-graphnobloom.log`) | 110.4 s; **s2 107.1 s** |
| Same, commit-graph **with** Bloom filters (`--changed-paths`) (`perfF/synth-graph.log`) | 41.1 s; s1 2.3 s, **s2 37.7 s**, s6 0.28 s, s7 0.49 s |
| Same, Bloom, all-history window `--since=2017-01-01` (20,000 merges) | 103.6 s; s2 37.1 s, **s6 66.6 s** (3.3 ms per merge); 1,852 lines (section 6 capped at 30) |
| One `git log -1 -- <record>` vs one path-limited walk giving the last date of all 301 `docs/decisions` paths (`perfF/iso-*.log`) | no graph 743 vs 736 ms; graph 326 vs 328 ms; Bloom 115 vs 120 ms; this repo 6 vs 13 ms |
| Section 2's log-row loop alone | 500 rows 1,445 ms; this repo's 67 rows 36 ms |
| One long trigger line end to end, temp repo (`perfF/scrub.log`) | nested `\xC2`×500,000+`\x80`×500,000: 51 ms; flat 10 MB: 282 ms; **flat 100 MB: 83.1 s, 288 MB peak RSS**; output line capped at 4,121 bytes in every case |
| mawk `trig` alone on one line (`perfF/mawk.log`) | 10 MB 220 ms; 20 MB 1,078 ms; 40 MB 6,983 ms |
| `bats test/scripts/dev-cycle.bats` (`perfF/bats.log`) | 23/23 ok, 6.24 s wall |

The synthetic repo and all temp repos were deleted. No probe processes remain. Nothing was written to the worktree except this file.

Legibility-target values: **maintainer** (someone editing the script or tests), **agent** (the model running the skill), **user** (the human who starts cycles and reads the digest).

## Data Flow and Hot Paths

`scripts/dev-cycle.sh` runs once per dev cycle, as skill step 0. Step 0 may run it a second time with `--since` (`SKILL.md:105-113` at bc5dc76). Every path in it is **cold**: there is no request path, and nothing runs per user. Because the skill runs the digest under the agent's Bash tool with no timeout of its own (default 120 s), and step 0 stops the cycle when the digest fails (`SKILL.md:115-117`), a cold path that gets slow enough becomes a hard failure. That is the escalation case the skill's hot-path gate names ("the cold path blocks a latency-sensitive operation or runs over large data").

What the cost scales with:
- **Total history (H), every run, whatever the window:** sections 1 and 7 walk all of `main` and filter by `%cs` afterwards (`:190`, `:193`, `:326-327`). Section 2 runs one path-limited `git log -1` per decision record that has triggers (`:210`). That walk goes back to the record's last change, which for a write-once record is close to H. Section 5 runs one more for `docs/roadmap.md` (`:292`).
- **Records (R) and log rows (L), every run:** section 2 prints every trigger (`:198-240`). It forks `realpath` and `git log` per record, and 4–6 processes per log row (`:216-225`).
- **Merges in the window (M):** section 6 forks `git diff` plus `awk` per merge (`:307-312`). The output is capped at 30, but the work is not.
- **Line length:** awk and sed read each line whole before the scrub cuts it at 4,096 bytes (`:36`, `:45`).

The skill's cost per cycle is agent work. Step 2 adjudicates every trigger. Step 4 checks the sample plus every flagged merge. Each cycle runs the health check and lands through `pr-prep`.

## Findings

#### 1. Section 2 runs one history walk per decision record: O(records × history). On large repos it alone exceeds the 120 s tool default, and the skill then stops every cycle

**Severity:** Low (Macro × Cold default). It escalates to Medium under the precondition below, which the shipped repo does not meet.
**Location:** `scripts/dev-cycle.sh:205-214` (the call is `:210`); consequence at `skills/dev-cycle/SKILL.md:115-117` (bc5dc76)
**Evidence (verbatim):** `for f in "${decisions_glob[@]}"; do` / `rawfile "$f" || { skipped "$f" || true; continue; }` / `grep -q '^## Revisit triggers' "$f" || continue` / `found=1` / `echo` / `d="$(git log -1 --format=%ad --date=short -- "$f")"` / … / `trig < "$f" | sed 's/^/> /'` / `done` (the whole loop; `d` is first used at `:212`, `echo "### ${f//$'\n'/ } (last committed on this branch: ${d:-never, uncommitted})"`). Skill: `If the digest fails (non-zero exit or a missing section), stop the cycle: file one \`agent\`` / `entry with the error and write **no** cycle record` (the unit continues: `so the next window still starts at the` / `last good one.`)
**Move:** Count the hidden multiplications; Ask "what's the size of N?"
**Classification:** Macro (R × H) / Cold path (once or twice per cycle), escalation case: it blocks the whole cycle
**Confidence:** High (measured)
**Baseline:** 244.6 s for section 2 (0.82 s per record) on a 200,001-commit synthetic repo with 300 triggered records and no commit-graph, measured 2026-10-02 (`perfF/synth-nograph.log`)
**Legibility-target:** maintainer

Each record's `git log -1 -- "$f"` walks from HEAD back to the record's last change. Decision records are written once, so that is nearly all of history. The cost is R × H. Measured per record on the 200k synthetic repo: 0.82 s with no commit-graph, 0.36 s with the commit-graph `git gc` writes by default (no Bloom filters), and 0.13 s with Bloom filters. The full 14-day digest took 255.7 s, 110.4 s and 41.1 s respectively. Section 2 was 96%, 97% and 92% of it.

Under the 120 s Bash default, the digest times out above about 141 triggered records (no graph), 327 (default graph) or 928 (Bloom) at that history size. The threshold falls in proportion as history grows. A timed-out digest is a non-zero exit, and step 0 then stops the cycle and writes no record. The next cycle's window is the same or wider, so every cycle fails the same way until someone raises the timeout by hand. Step 0's rerun with `--since` doubles the cost when it applies.

**Precondition for Medium:** roughly 140 or more triggered records on a history of about 200k commits without Bloom filters, run under the default tool timeout. This repo (1,973 commits, 11 triggered records) pays 6 ms per record, about 0.15 s in total. The prior rubric holds this as C3 (Low, open); it is unchanged since then. What is new is the measured failure threshold.

**Recommendation:** Replace the per-file call with one path-limited walk before the loop, from HEAD as now so that "on this branch" keeps its meaning. For example: `git log --format=@%ad --date=short --name-only -- docs/decisions`, keeping the first date seen per path in an associative array. It costs about one per-record call (736 ms vs 743 ms with no graph, 120 vs 115 ms with Bloom) and makes section 2 O(H) instead of O(R × H). Check that its dates match the per-file ones on this repo before switching; history simplification at merges differs between pathspecs. Alternatively, have step 0 run the digest with an explicit long timeout. That only moves the cliff.

#### 2. Sections 1 and 7 walk all of history on every run, whatever the window

**Severity:** Low
**Location:** `scripts/dev-cycle.sh:190`, `:193`, `:326-327`
**Evidence (verbatim):** `merges_full="$(git log "$MAIN_SHA" --first-parent --merges --format='%cs %H %h %ad %s' --date=short | awk -v s="$SINCE" '$1 >= s')"` and `commits="$(git log "$MAIN_SHA" --format=%cs | awk -v s="$SINCE" '$1 >= s' | wc -l)"` (section 1's unit continues to `:196`); `changed="$(git -c core.quotePath=false log "$MAIN_SHA" --first-parent --diff-merges=first-parent --name-only --format='@%cs' -- skills workflows docs/decisions \` / `| awk -v s="$SINCE" '/^@/ { on = (substr($0, 2) >= s); next } on && NF' | sort -u)"` (the unit continues to `:338`)
**Move:** Check the asymptotic behavior
**Classification:** Macro (O(H) per run, not O(window)) / Cold
**Confidence:** High
**Baseline:** section 1 took 2.2–2.8 s and section 7 0.47–0.94 s on the 200,001-commit synthetic repo for an 85-merge, 14-day window; this repo 44 ms and 38 ms. Measured 2026-10-02 (`perfF/synth-*.log`, `perfF/thisrepo.log`).
**Legibility-target:** maintainer

The full walk is deliberate: `--since` stops at the first old-dated commit (`:187-188`). It sets a floor of about 3 s per run at 200k commits that grows linearly with history. That floor is small next to finding 1, and it cannot fail the digest on its own at realistic sizes. This is the prior rubric's C2, unchanged.

**Recommendation:** None needed before merge. If finding 1 is fixed and large repos matter, pre-filter with `--since-as-filter` (git 2.37 or newer) using a margin of a day or more, and keep the awk comparison.

#### 3. Section 6 forks a `git diff` and an awk per merge in the window; only the output is capped

**Severity:** Low
**Location:** `scripts/dev-cycle.sh:306-318`
**Evidence (verbatim):** `while read -r _ full rest; do` / `[[ -n "$full" ]] || continue` / `counts="$(git diff --name-only -z "$full^1" "$full" | awk -v RS='\0' '…')"` / `read -r n_code n_docs <<< "$counts"` / `[[ "$n_code" -gt 0 && "$n_docs" -eq 0 ]] && flagged+=("- $rest ($n_code file(s), no doc change)")` / `done <<< "$merges_full"` (the awk body is elided as `…`; the unit continues to `:318` with the 30-line cap)
**Move:** Count the hidden multiplications
**Classification:** Macro (O(M) processes) / Cold; M is bounded by the window
**Confidence:** High
**Baseline:** 3.3 ms per merge (66.6 s for 20,000 merges, all-history window) on the synthetic repo; 1.9 ms per merge on this repo (733 ms for 386). Measured 2026-10-02.
**Legibility-target:** maintainer

At normal windows this costs nothing: 85 merges took 0.21–0.28 s on the synthetic repo, and 64 merges took 0.12 s here. It matters only when the window is wide. That happens with an explicit old `--since`, or with the 14-day default after records lapse, or with step 0's rerun from an old cycle date. On this repo a since-January window costs 0.75 s. Prior rubric C1, now with the output cap in place.

**Recommendation:** None needed before merge. For wide windows, one `git log "$MAIN_SHA" --first-parent --merges --diff-merges=first-parent --name-only -z` pass replaces the loop.

#### 4. awk reads a long line whole before the scrub cuts it, and mawk is superlinear in line length

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:201`, `:213` (also `:295`, `:343`); acknowledged at `:36`
**Evidence (verbatim):** `trig() { awk '/^## Revisit triggers/ { on = 1; next } on && /^## / { exit } on && NF { print }'; }` and `trig < "$f" | sed 's/^/> /'`; header: `scrub's work per line (the awk readers upstream still read a long line whole).`
**Move:** Check the asymptotic behavior
**Classification:** Micro→Macro in line length / Cold
**Confidence:** High
**Baseline:** 83.1 s and 288 MB peak RSS for a full digest of a temp repo whose one trigger line is 100 MB; 282 ms at 10 MB. mawk `trig` alone takes 220 ms, 1,078 ms and 6,983 ms at 10, 20 and 40 MB. Measured 2026-10-02 (`perfF/scrub.log`, `perfF/mawk.log`).
**Legibility-target:** maintainer

The 4,096-byte cut bounds the scrub and the output (every case printed at most 4,121 bytes per line; the nested 500,000-pair line took 51 ms). It does not bound the awk readers upstream, which the header says. Reaching the 120 s cliff needs a single line of more than 100 MB in a working-tree decision record, log or roadmap. That is implausible in practice, and the input is the user's own working tree.

**Recommendation:** None. The header comment already states this limit accurately.

#### 5. The skill re-adjudicates every trigger every cycle, and section 2 is two-thirds of the digest

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:139-146` and `:284` (bc5dc76); `scripts/dev-cycle.sh:198-240`
**Evidence (verbatim):** `The digest prints every trigger in full (an output line over 4096 bytes is cut; read the` / `record itself then). For each, decide **fired / not fired / cannot tell**` / `and write the evidence (a command and its output, a count, a commit).` (the unit continues to `:146`, `waits for the next digest.`); `Record one verdict for every trigger, under the name the digest prints.`
**Move:** Ask "what's the size of N?"
**Classification:** Macro (O(R + L) agent work per cycle) / Cold (once per cycle)
**Confidence:** Medium (the token cost is reasoned from digest size, not measured from a run)
**Baseline:** section 2 is 18,133 of the 27,014 digest bytes on this repo (67%): 11 records with 41 trigger lines plus 11 log rows. On the synthetic repo (300 records, 500 rows) section 2 is 79,285 bytes. Measured 2026-10-02 (`perfF/sec2.md`, `perfF/synth14.md`).
**Legibility-target:** user

Without carry-forward (Q-101 [1], log row 68), every cycle pays for one evidenced verdict on every trigger. That cost grows with the number of decisions, not with the activity in the window. At 22 triggers it is a bounded step-2 subagent job. It grows linearly with R + L, and cycles can run "many a day" (`:197-198`). This is the cost of a deliberate design choice, so it is not a defect.

**Recommendation:** None for this merge. If R + L grows into the hundreds, consider letting step 2 batch "not fired" verdicts for triggers whose evidence paths did not change in the window. That would need a new decision, since it partly reverses Q-101 [1].

#### 6. Fixed agent and wall cost per cycle: a full health check, all flagged merges in step 4, and a pr-prep landing

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:121-125`, `:165-171`, `:287-289` (bc5dc76)
**Evidence (verbatim):** `run` / `the repo's health check, if it has one (e.g. \`scripts/health-check.sh\` in claude-workflows),` / `to a file, and wait for it to finish before steps 2–4b start their own tests and subagents.` (the unit continues to `:125`); `Also check every merge the digest lists under "Merges with code but no docs" (the` / `fourth rule).` (the unit continues to `:171`); `then land \`chore/dev-cycle-<date>\` on the default branch through \`pr-prep\`` (the unit continues to `:289`)
**Move:** Find the work that moved to the wrong place
**Classification:** Micro per cycle × cycle frequency / Cold
**Confidence:** Medium
**Baseline:** the health check takes about 10 min at bc5dc76 (the brief's stated figure, not re-run). Section 6 flags 16 merges in this repo's default 14-day window (27 since January), so step 4 makes 18 checks per cycle with the default sample of 2. Counts measured 2026-10-02 (`perfF/out-default.md`, `perfF/out-wide.md`).
**Legibility-target:** user

Every cycle has a fixed floor: a health check of about 10 minutes before steps 2–4b can start, a pr-prep review-fix loop on a branch that is mostly docs, and step 4 checks of up to 32 merges (the sample plus up to 30 listed). Step 4's per-merge subagent rule names only sampled merges (`:87`), so it does not say whether the up to 30 flagged merges are checked in parallel or in the main thread. On this repo many flagged merges are internal sub-merges into an integration branch (for example `Merge branch 'ans/fixsi' into answers-2026-09-20`), each checked separately. At fortnightly cadence this is fine. At "many a day" the floor dominates. Prior rubric C5 (pr-prep landing, Low, open).

**Recommendation:** Say in step 4 whether flagged merges share the step-4 subagents. Optionally let a cycle reuse a health-check result from the same default-branch commit. Neither is needed before merge.

#### 7. The log-row loop forks 4–6 processes per row

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:215-225`
**Evidence (verbatim):** `while IFS= read -r row; do` / `found=1` / `n="$(awk -F'|' '{ gsub(/ /, "", $2); print $2 }' <<< "$row")"` / `d="$(awk -F'|' '{ gsub(/ /, "", $3); print $3 }' <<< "$row")"` / … / `text="$(grep -oE 'Revisit[^|]*' <<< "$row" | head -1 || true)"` / … / `done < <(grep -E '^\| [0-9]+ \|' docs/decisions/log.md | grep -i 'revisit' || true)` (the comment lines and the fallback `grep -oiE` line are elided as `…`)
**Move:** Count the hidden multiplications
**Classification:** Micro / Cold
**Confidence:** High
**Baseline:** 1,445 ms for 500 rows (synthetic), 36 ms for this repo's 67 rows (11 matching), measured 2026-10-02 (`perfF/iso-*.log`)
**Legibility-target:** maintainer

This is linear, about 3 ms per row. It is negligible beside finding 1 even at 500 rows.

**Recommendation:** None. If section 2 is rewritten for finding 1, one awk pass over log.md would remove the forks at the same time.

## Endorsements (evidence-gated)

- The scrub's work per line is bounded by the 4,096-byte cut taken before control removal: a 500,000-pair nested C1 line runs end to end in 51 ms, and a 2,000,000-pair line in 92 ms. The pass-5 quadratic case is closed. [fact-check: claim 31 — Verified]
- The re-exec through two scrub filters waits for both and returns the body's status. [fact-check: claim 33 — Verified] It adds no measurable wall time: 990–1,015 ms scrubbed vs 977–1,013 ms body-only on this repo, with byte-identical output. [unverified — submitted as claim]
- Section 7 runs one path-limited walk with `--diff-merges=first-parent`, rather than one per commit or per file, and costs 0.47–0.94 s at 200k commits. [read: scripts/dev-cycle.sh:326-338]
- The In-flight check per cycle is bounded. There are at most 3 open briefs (`:252-253`). Each answer is applied once, keyed by ID against `Applied:`. The archive is searched by ID, never read whole. [read: skills/dev-cycle/SKILL.md:227-242 at bc5dc76]
- The test suite stays cheap at 23/23 in 6.24 s wall, with no test building a large repo. [unverified — submitted as claim] (`perfF/bats.log`)

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | One `git log -1` per record: O(R × H); 245 s / 107 s / 38 s at 300 records × 200k commits (no graph / default graph / Bloom); above ~141 / 327 / 928 records it exceeds the 120 s tool default, and the skill then stops every cycle | Low (Medium only above that precondition) | `scripts/dev-cycle.sh:210` | High |
| 2 | Sections 1 and 7 walk all history every run (~3 s floor at 200k commits) | Low | `scripts/dev-cycle.sh:190,193,326` | High |
| 3 | Section 6 forks per merge in the window (3.3 ms each; 66.6 s at 20,000 merges) | Low | `scripts/dev-cycle.sh:306-318` | High |
| 6 | Fixed per-cycle floor: health check (~10 min), step 4 over up to 32 merges (18 here), pr-prep landing | Low | `skills/dev-cycle/SKILL.md:121-125,165-171,287-289` | Medium |
| 4 | mawk reads whole lines before the cut (83 s at a 100 MB line) | Informational | `scripts/dev-cycle.sh:201,213` | High |
| 5 | Every trigger re-adjudicated every cycle; section 2 is 67% of the digest | Informational | `skills/dev-cycle/SKILL.md:139-146` | Medium |
| 7 | The log-row loop forks 4–6 processes per row (1.4 s at 500 rows) | Informational | `scripts/dev-cycle.sh:215-225` | High |

## Overall Assessment

On the repo it ships in, the branch has no performance problem. The digest runs in about 0.4 s for the default window and about 1 s for a nine-month window. The scrub and re-exec cost nothing measurable, the pass-5 quadratic scrub is closed, and the suite runs in 6 s. Every finding is in a cold path, and none is new code since the previous passes: findings 1–3 and 6 are the prior rubric's C3, C2, C1 and C5, re-measured on this full scope.

The one with a real cliff is finding 1. The per-record `git log -1` makes section 2 O(records × history). On a 200k-commit repo it alone exceeds the agent's 120 s Bash default at about 141 triggered records without a commit-graph, or about 327 with git's default graph. Because the skill treats a failed digest as "stop the cycle", that becomes a cycle that never completes rather than a slow one. The precondition does not hold here (11 triggered records, 2k commits). It is a fixable-in-place structural issue: one path-limited walk, already measured at the cost of a single per-record call. It is not a design flaw. I grade it Low by the skill's matrix and name Medium as the escalation if large-history adopters are in scope for this merge. That is a scope call for the orchestrator.

The skill's per-cycle costs (findings 5 and 6) are the price of deliberate choices: no carry-forward, and pr-prep landing. They are bounded at the shipped cadence. I checked the scrub cut, the re-exec, the section 7 walk, the section 6 cap and the In-flight bounds for hidden multiplication and unbounded growth. Within this lens they are correct and complete. No profiling is needed beyond the measurements above. If finding 1 is fixed, compare the new single walk's dates against the per-file dates on this repo.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file." This report is saved at `/workspace/.claude/wt-devcycle/docs/reviews/performance-review-2026-10-02-dev-cycle-full.md`, and its first line is `Commit: bc5dc76`. It follows the performance-reviewer structure: header with Based on, Data Flow and Hot Paths, Findings with Severity, Location, Move, Classification, Confidence and Baseline, Endorsements with evidence tags, Summary Table and Overall Assessment. Each finding also carries the brief's Evidence (verbatim, with truncation markers) and Legibility-target. It serves the user goal (merge `feat/dev-cycle` on a clean pass) with no Critical, High or Medium finding at the shipped scale. The one conditional escalation (finding 1) is stated with its precondition, so the orchestrator can decide whether it blocks. Not committed.
