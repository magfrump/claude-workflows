# Research: one canon-proposal pass, with this repo as the subject

- **Goal**: Apply the canon-proposal rule once (Q-256 [2]): build the conversion script that section 10 of `docs/working/research-2026-11-05-canon-proposal-filter.md` specifies, and add at most one canon instance per gap class from this repo's dev-cycle work.
- **Project state**: build loop for `docs/working/briefs/2026-11-07-canon-instances-pass.md` (policy review), dispatched at `f93c043c`.
- **Task status**: complete; one Path C tentative pick (the script's home), question in section 6.

Tags: [observed] checked by reading or running; [inferred] derived from observed facts. No plan doc: the plan is section 5 here, and there was no approval gate.

Failure-pattern grep: FP-009, FP-064, FP-071, FP-108, FP-172 (see Prior failures)
Failure-pattern skip: the one fix(...) commit is review iteration 1 on this branch's own unmerged script (a vacuous test, decode and severity refusals); each shape is already in the library (FP-172 empty input passes, FP-152 vacuous assertion), so none earns a new entry.

## 1. The rule, step by step (section 8 of the 2026-11-05 doc)

1. **Trigger.** The owner's answer Q-256 [2] stands in for a briefed recall run; this pass is the one-shot option [15] that the 2026-11-05 doc ranked second. No recall run is scheduled [observed: brief Motive].
2. **Gap.** Classes with no canon instance: T12, T15, T16 (2026-11-05 doc, section 4; the canon's 8 rows are unchanged since then) [observed].
3. **Relevance: the last 20 fix commits that correct reviewed, merged code, in this repo, classified by hand.** Method: walk `fix(` / `fix:` commits from `f93c043c` backwards. For each one, take the first first-parent commit of main that contains it, and check whether the lines it removes (16 or more characters, outside `docs/`) were already on main before it arrived. Keep commits where nearly all were. Drop in-branch review rounds (0 of N lines on main, for example `e73182e1`, `3066f5b0`), fixes to research docs (`ecaaf3af`) and integration fixes (`63d6f7d7`). Keep one pure-addition fix after reading it (`3db92077`, which corrects the merged Dockerfile's locale). The script was a scratch probe; its output for 90 commits was read by hand [observed].

   | # | Commit | What it corrects | Class |
   |---|---|---|---|
   | 1 | `06ac4c6f` | health-check day count wrong on a DST day | T1 |
   | 2 | `015bd762` | brainstorm trigger counted its own seeds | T1 |
   | 3 | `fe692928` | health check raced the cycle's own writes | T9 |
   | 4 | `3db92077` | image sets a locale it does not generate | T6 |
   | 5 | `904326eb` | relative ROOT broke after a `cd` | T1 |
   | 6 | `b663eb75` | SIGPIPE under pipefail read as "field missing" | T10 |
   | 7 | `8e6d28e2` | test flaked on other processes' /tmp churn | T5 |
   | 8 | `376fccee` | exit scan missed relative remotes per worktree | T7 |
   | 9 | `cf15f4f9` | exit scan missed a relative hooksPath in linked worktrees | T7 |
   | 10 | `062acde2` | Write(path) deny rules that never match (inert guard) | T7 |
   | 11 | `9ad2de46` | egress resolver unpinned from phase A's answers | T6 |
   | 12 | `336c257a` | skill ran the review policy silently when unset | T15 |
   | 13 | `464586d0` | skill steps held the cycle on hand commits | T15 |
   | 14 | `8c3cfc1f` | import guard test skipped the file it claims to check | T5 |
   | 15 | `4ff1cfec` | `--profile ../egress/python` accepted through an unquoted, globbed split | T12 |
   | 16 | `ed06dec1` | hook's own deny reader disagreed with Claude Code's | T7 |
   | 17 | `1a831ffe` | de-quoted deny match, a second interpreter of one rule | T7 |
   | 18 | `cb56299c` | rebuild hint told the user a step that does not rebuild | T3 |
   | 19 | `980a9db4` | copyable line's trailing `# note` became launch arguments | T6 |
   | 20 | `a54bb3b0` | last positional taken as the workspace (same paste) | T6 |

   **Result:** T12 1 of 20 (`4ff1cfec`), T15 2 of 20, T16 0 of 20. T16 is theoretical for this run, so it gets no proposal, which matches the dry run. Rows 19 and 20 sit on the T6/T12 line (text shape reaching argv); I put them in T6 because the cause is zsh's comment handling, not the text. Under the other reading T12 is 3 of 20, and the result is the same [inferred].
4. **Eligibility.**
   - T12, `feat/dev-cycle` R1, range `4225753a..89a3d3b7`. Base is an ancestor of head; 3 commits; 6 files outside `docs/`, +342/−1. The rubric has a Finding column and is pinned at `d8b0cca9`, the commit that added it and fixed every row. Defect re-checked at head 2026-11-07: a hermetic probe of `scripts/dev-cycle.sh` at `89a3d3b7`, with `refs/remotes/origin/HEAD` pointing to `refs/remotes/origin/--output=<victim>`, exited 129 and left the victim file at 0 bytes. Not T13H. S1: see section 2. **Eligible** [observed].
   - T15, `feat/dev-cycle-skill` A1, range `65bd4336..e438cd18`. Ancestor; 7 commits; 4 files outside `docs/`, +129/−1. Rubric pinned at `6ee33e35`, the fix commit. Defect at head: `skills/dev-cycle/SKILL.md` at `e438cd18` never mentions Operating Modes, and the fix adds the branch check, named-path staging and the Operating Modes line [observed]. Amber only; the one T15 red is still unresolved across two branches, so it fails the evidence bar (2026-11-05 doc). **Eligible** [observed].
   - Both scrubbed clones were built by the script under the scratchpad and passed guards (a) and (b). `cw-devcycle` has 3 commits under review and 1,098 older `docs/reviews/` files; `cw-devcycle-skill` has 7 commits and 1,174 files. The clones were then deleted [observed].
5. **Rank.** One candidate per class, so there was nothing to rank. Both are from this repo, so the outside-repo tiebreak has nothing to choose between. No owner nominations.
6. **Limits.** 2 instances (at most 3); the canon goes from 8 to 10 rows (cap 12). T16 is left open, not padded.

## 2. The S1 call on T12

**In scope.** S1 says gates defend against honest slips, not a hostile loop, and the memory note says review briefs never assume a malicious branch or loop author. R1 is neither of those. The text comes from a remote's metadata, not from the change's author, and the repo's own coding rule (CLAUDE.md, Code, first bullet: operator-shaped text reaches a subprocess as its own argv element, with `--` before paths) already treats such text as something to handle. Step 3 shows the class arriving through honest operator input here (`4ff1cfec`: a path-like profile name, an honest slip). The fix (resolve to a hash, refuse a leading `-`) was cheap, and nothing in it assumes intent. A label asks what a reviewer should find, and this one is a rule violation that can be re-checked from the artifact.

## 3. Design choices

**Script home: divergent design (4 options, Path C).**

| # | Home | H3: bats run by the health check | S6: reachable call site | S3/S8 | Separation of instrument and subject (archive README, owner memory) | Can this loop land it? |
|---|---|---|---|---|---|---|
| 1 | `scripts/canon-instance.py` here, tests in `test/scripts/` | ✓ | ✓ named in the canon notes; used to make rows 9 and 10 | ✓ one file, stdlib | ✗ instrument code in the subject repo | ✓ |
| 2 | The SWRBench fork (`external/SWRBench2`, last commit 2026-08-24) | ✗ outside this branch, so this repo's health check never runs it | ~ the fork's runner is not migrated | ✓ | ✓ | ✗ a separate repo: no commit there passes through this gate or review |
| 3 | `archive/benchmark/scripts/` beside its siblings | ✗ `run-tests.sh` does not collect archive tests (archive README) | ✗ archived means not run | ✓ | ~ | ✓ |
| 4 | A checklist, no script | n/a | ✗ | fails S4: the scrub is the step a person gets wrong | ✓ | ✓ |

Hard-line pruning leaves only [1]: [2] and [3] fail H3, and [4] fails S4 and the brief. The owner's stated preference (benchmark work goes to the fork) still points at [2], and only the owner can say whether that preference outranks this loop's constraints, so this is Path C rather than Path A. **Tentative pick [1]**; tiebreaker H3/S6: it is the only home where the tests run and the script has a call site. A move later is one `git mv` plus copying the tests, and the fork is idle, so nothing there conflicts.

Other choices (one line each):

- **Non-doc size**: count files outside `docs/` only. This reproduces both figures in the 2026-11-05 doc (6f +342/−1 and 4f +129/−1), and in this repo `docs/` holds review records, not code.
- **Rubric pinning**: `--rubric-commit` reads the rubric at a commit (FP-064). This option is an addition to the section-10 interface; without it the script reads the file.
- **Ledger header**: `--ledger-csv` reads the header and finds its columns by name, so the skeleton rows fit the real ledger's 15 columns. This is the same header-name rule as the rubric.
- **Guard (b)**: refuse a tree holding a `docs/reviews/` file that names head's 7-character prefix, and only note, not refuse, files naming other commits in the range (the spec says "report"). A commit cannot name its own hash, so guard (b) is tested through its detector function (bats case 22).
- **Clone hardening** (review G1, G2): the source is passed as an absolute path, so a name like `h:x` cannot be read as an ssh URL; every git call runs with `core.hooksPath=/dev/null`; the remote is named `origin` explicitly and its removal is checked.
- **Default repo name** comes from `--git-common-dir`: from a linked worktree it is the main checkout's directory name (`workspace` here), not the worktree's, so pass `--repo-name` when that directory is not named for the repository, as these rows did (review A7, G1 of iteration 2).
- **Stripping GIT_DIR and related variables** from the script's git environment: the lesson of `5a063f0e` (a stray GIT_DIR acted on another repo), with a bats case.
- **Labels in the ledger**: every red and amber row (14 and 6), following the canon's own label rule, as a new stratum F. The headline recall table stays dated to the 56-row ledger (FP-108).
- **Canon placement**: rows appended at the end of the §1 table, after the archived-cells row (append-only).

## 4. Invariants kept

Canon rows are append-only: two rows were appended and no existing row was edited. The script writes neither canon file (bats case 2). The scrub drops the descendant fix commit (bats case 19). Guard (a) itself has no case: after the scrub nothing can survive, so it is defense in depth, as in the archived script. Guard (b) is tested through its detector (case 22). No arm was run and no recall was measured (out of scope).

## 5. What was built

- `scripts/canon-instance.py` (stdlib, 282 lines) and `test/scripts/canon-instance.bats` (23 cases). Mutation check: disabling each refusal condition one at a time (option-spelled, unresolved, base equal to head, not an ancestor, no file, docs only, over 10 files, over 500 lines, no Finding column, row without severity, not a repository) fails at least one case each [observed]. Guard (a) and guard (b)'s `if` are not killed by any case (see section 4).
- Review iteration 1 (one reviewer: correctness, tests, fact-check) found 1 red (a vacuous `&&` assertion), 7 amber and 7 green. All were fixed except G4's duplicate-table and withdrawn-row cases (the rubric's Status column is not parsed; a pass reads the printed rows before pasting them) and G5 (binary files count 0 lines, now stated in the docstring).
- Review iteration 2 (same reviewer, on the fix diff) found no red, 2 amber, 3 green. Fixed: a 🔴/🟡/🟢 marker in any cell now counts as the row's severity, `~~~` fences are skipped, and new cases cover a cell marker, a fenced table, a non-UTF-8 pinned rubric and a global post-checkout hook that must not run. Not given a case: the absolute clone source, `--origin origin`, the `BaseException` cleanup and the all-refs delete (probed by the reviewer, not a refusal). Scan of all 98 `docs/reviews/code-review-rubric*.md` files: 82 parse; 15 refuse because a row carries no machine-readable severity (for example `F1` under `## Final pass 2` with no marker, or `Minor / Low`), and 1 has no Finding column. Refusing these is intended: guessing a severity would mislabel the canon. Both canon rubrics parse.
- Size: 545 code lines against `f93c043c` (script 284, tests 261). That is over pr-prep step 1a's 400-line entry cap and under the review loop's ~800 limit. The ready split point is `--clone` (about 50 script lines and 4 cases); see the marker.
- `docs/working/review-canon.md`: rows `cw-devcycle` and `cw-devcycle-skill`, a §1 note on where they came from, a §4 status line.
- `docs/working/canon-issue-ledger.csv` (+20 rows) and `.md` (stratum F, count reconciliation 56 → 76, revision line).

## 6. The owner's question (Path C)

Where should `canon-instance.py` live? Pick: [1], tiebreaker H3/S6: it is the only home where its tests run in this repo's health check and where a loop can land it.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Keep it here** | `scripts/canon-instance.py` and its bats stay in this repo | None | Instrument code sits in the subject repo, against the fork rule; a move later is one `git mv` |
| **[2] Move it to the SWRBench fork** | A session in the fork copies the script and tests there, and this repo deletes them | One fork session; confirm the fork is the live home first | The tests leave this repo's health check, and the fork has been idle since 2026-08-24 |
| **[3] Archive it** | Move it to `archive/benchmark/scripts/` | None | Its tests stop running, and it rots with the other archived scripts |

- **Interim:** [1].
- **If the answer differs:** [2] or [3] moves two files and updates the one pointer in `review-canon.md` §1; the canon and ledger rows stay.

## Prior failures

- **FP-064** (rubric overwritten each run): rubrics are pinned by commit.
- **FP-071** (a ledger write had no owner when it was possible): this pass writes its own rows.
- **FP-108** (wrong denominator): stratum F is outside every published recall figure until an arm runs on it.
- **FP-009** (SIGPIPE, no output): the script parses structurally and has no shell pipes.
- **FP-172** (empty input passes): empty ranges and docs-only ranges are refused.

## Revisit triggers

If the owner answers section 6 with [2] or [3]. If a recall run is briefed (then the arms' columns for stratum F get filled). If a T16 candidate under the size limit appears.

## Files read

Last verified: 2026-11-07
docs/working/briefs/2026-11-07-canon-instances-pass.md (at f93c043c)
docs/working/research-2026-11-05-canon-proposal-filter.md
docs/working/review-canon.md
docs/working/canon-issue-ledger.md, .csv
docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle.md
docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-skill.md
docs/failure-patterns.md (grep)
archive/benchmark/README.md, archive/benchmark/scripts/prep-cc-review-clones.sh
scripts/build-loop.sh (the Paths: and S rules), scripts/health-check.sh (gates)
test/scripts/harness-feedback.bats, test/scripts/fixture-git-env.bats, test/lib/hermetic-env.bash
The bodies of the 20 fix commits in section 1
