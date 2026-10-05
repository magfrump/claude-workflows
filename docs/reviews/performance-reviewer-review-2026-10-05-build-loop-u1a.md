Commit: 4aa2e98e

# Performance Review — feat/build-loop-u1a (U1a, review-fix iteration 4, final confirming pass)

**Scope:** `git diff main...feat/build-loop-u1a` code files (scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, skills/dev-cycle/SKILL.md, test/scripts/dev-cycle.bats); docs/reviews/ excluded
**Date:** 2026-10-05
**Based on:** Stage-1 merged fact-check summary (k=3 at 4aa2e98e; `docs/reviews/code-fact-check-report-build-loop-u1a-r{1,2,3}.md`)

## Data Flow and Hot Paths

The diff changes the shared reader lib's check modes: `main_entry` (one `git ls-tree -t --full-tree` per lookup), `brief_fields` (one `git cat-file | awk` pass over a brief), `check_brief` (now built on both) and `check_answer` (now reads both questions files from main's commit instead of the working tree). `scripts/dev-cycle.sh` calls them once per argument in a check-mode run that a person starts a few times per dev cycle. Every changed path is **cold**: a CLI invocation over a handful of briefs or question IDs, with no request handler or high-frequency loop. The U1b/U1c consumers (build-loop.sh `--settings`, `--status`) are not in this diff.

The iteration-4 code delta (722884c7..4aa2e98e) is three lines of runtime code:

- `brief_fields` (`scripts/lib/dev-cycle-read.sh:292`) and `check_answer` (`:548`) add `local -; set -o pipefail`. That is an in-process option save and restore, with no fork and no extra read.
- `--help` (`scripts/dev-cycle.sh:112`) swaps a fixed `sed -n '2,80p'` for the address range `2,/^[^#]/{/^#/p}`. sed still reads the 471-line script to its end, because it has no `q`, the same as the old fixed range.

I measured both revisions in my scratch dir. Each reader came from `git show <rev>:scripts/lib/dev-cycle-read.sh` and was sourced in-process against /workspace's main (0aea04c3), with `LC_ALL=C.UTF-8` and wall clock from `date +%s%N`. The brief was `docs/working/briefs/2026-10-02-build-loop-handoff.md`, and the IDs were the last 20 headings in main's questions-archive.md.

| Measurement | 722884c7 (iteration 3) | 4aa2e98e (HEAD) |
|---|---|---|
| `check_brief` × 50, 3 rounds | 929 / 932 / 965 ms | 890 / 901 / 896 ms |
| `check_answer` × 20, 3 rounds | 286 / 323 / 232 ms | 238 / 231 / 245 ms |
| git subcommands per `check_brief` (PATH shim) | cat-file 1, log 1, ls-tree 2 | cat-file 1, log 1, ls-tree 2 |
| git subcommands per `check_answer` (Q-111, both files present) | cat-file 2, ls-tree 2 | cat-file 2, ls-tree 2 |
| output md5 (3 briefs + 21 IDs, incl. absent Q-999) | 0be9d6c2… | 0be9d6c2… |
| `dev-cycle.sh --help` wall clock, 3 runs | — | 8 / 8 / 8 ms |

`--help` output is byte-identical to header lines 2-81 after the `# ` strip, as the fact-check replicates also found.

## Findings

No findings.

## Escalations received and settled rows

None of the Stage-1 escalations is addressed to the performance critic. The `local -` minimum bash version, BSD sed's `{/^#/p}` grammar, the stale test title at `test/scripts/dev-cycle.bats:767` and the "Mostly accurate" comments are portability or documentation issues with no runtime cost.

Settled rows I did not re-raise, with no new evidence against any of them:

- **233**: check_brief runs `ls-tree` twice per brief. The shim still shows 2. The cost is level with iteration 3 (about 18 ms per brief at both revisions on this host), and its revisit trigger is U1c.
- **201**: check_brief's `git log -G` walk grows with history. The walk is unchanged, and its trigger is U1c's `--status`.
- **220**: `ls-tree -t` lists the children of each named directory. It is still one process per lookup.
- **228**: both questions files are re-read per ID. Measured flat between the two revisions.
- **229**: check_brief's iteration-2 delta.

## Endorsements

- The iteration-4 `local -; set -o pipefail` lines in `brief_fields` (`scripts/lib/dev-cycle-read.sh:292`) and `check_answer` (`:548`) are shell builtins in the function's own shell. They add no process, no subshell and no read of the blob. The `cat-file | awk` pipelines they guard are unchanged. `[read: scripts/lib/dev-cycle-read.sh:289-312, :547-576]`
- Claim: on /workspace's main at 0aea04c3, 4aa2e98e's `check_brief` and `check_answer` run within round-to-round noise of 722884c7 (890 to 901 against 929 to 965 ms per 50 briefs; 231 to 245 against 232 to 323 ms per 20 IDs), with the same git subcommand counts and byte-identical output. `[unverified — submitted as claim]` (route: code-fact-check. Probe: the PATH shim on git that logs `$1`, plus the in-process loops described under Data Flow.)
- Claim: the `--help` range `2,/^[^#]/` costs the same as the old `2,80p`, because sed reads the whole 471-line file in both cases (neither has `q`), and the run takes 8 ms end to end, including the scrub re-exec. `[unverified — submitted as claim]` (route: code-fact-check)

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| — | No findings | — | — | — |

## Overall Assessment

The branch carries no performance risk, and the iteration-4 fixes cost nothing measurable. `local -` with pipefail is a builtin option save, and the `--help` range reads the same bytes as the old fixed range. All changed paths are cold CLI check modes over a handful of inputs. Timings, git subcommand counts and outputs match iteration 3. The one standing cost (row 233: two `ls-tree` per brief, about 18 ms per brief here) is settled and carries forward to U1c's `--status` measurement together with row 201. Nothing needs to be fixed before merge, and no profiling is needed to land U1a.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to docs/reviews/performance-reviewer-review-2026-10-05-build-loop-u1a.md, structured per the performance-reviewer skill, first line `Commit: 4aa2e98e`.
- Answered: yes. The full-branch performance review at 4aa2e98e, with the iteration-4 delta measured against 722884c7, found no findings.
- Out of scope: portability of `local -` and BSD sed (api-consistency/orchestrator), the stale bats test title, the comment accuracy items from Stage 1, U1b/U1c consumers, and the bats suite run.
- Escalate: nothing.
- Decisions I made: I measured against iteration 3 (722884c7) rather than main, because the iteration-3 report already holds the main-reader baseline and row 233 settled that delta.
