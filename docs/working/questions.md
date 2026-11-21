# Running questions

Questions raised during autonomous work that did not justify stopping.

**To answer:** write `Q-0NN: <your answer>` anywhere — a reply, a file, a commit.
The ID is the whole handle; you never have to restate the question. Answers move
the entry to `questions-archive.md`, so this file only ever holds what is still open.

**Needs** is the route — who or what actually discharges the item, from
`docs/working/triage-2026-09-17-backlog.md` §3.1:

| Route | Meaning |
|---|---|
| `you: judgment` | Needs your taste or authority. The only real attention spend. |
| `you: terminal` | Needs your machine, not your mind. Collected into one paste below. |
| `you: walkthrough` | A hands-on walkthrough or playtest only you can do. |
| `you: fyi` | A quick read to acknowledge, answered `seen`. |

Agent work is on the roadmap (`docs/roadmap.md`), and conditions the cycle is watching are in `docs/working/watching.md`.

Maintained by `scripts/questions.sh` (`check` · `index` · `archive` · `next-id` · `open`).
The index below is generated — edit entries, not the table.

## Index

<!-- index:start -->
| ID | Needs | Question | Opened |
|---|---|---|---|
| [Q-357](#q-357--merge-gate-2026-11-20-pipefail-grep-q-265fdab2a55a) | you: judgment | Merge the build loop's fix for pipelines into `grep -q` that can lose a match under `pipefail`, two of whic... | 2026-11-20 |
| [Q-358](#q-358--merge-gate-2026-11-20-answers-file-route-a7a04dc995e1) | you: judgment | Merge the build loop's change that lets a committed `docs/human-author/answers-*` file count as your answer? | 2026-11-20 |
| [Q-359](#q-359--merge-2026-11-20-ingest-project-rename-82e794ae342f) | you: judgment | Merge the build loop's fix so harness-feedback ingest refuses a renamed project instead of storing or seedi... | 2026-11-20 |
| [Q-360](#q-360--merge-gate-2026-11-20-six-still-true-rows-ed98d39e8fba) | you: judgment | Merge the build loop's fixes for six old review findings that were still true, one of them a write-guard gap? | 2026-11-20 |
| [Q-350](#q-350--threat-model-walkthrough-2026-q4) | you: walkthrough | Walk through the risks you accepted in the build-loop design (about 20 minutes) and say for each: keep, tig... | 2026-11-20 |
| [Q-332](#q-332--regenerate-fact-check-reports-host) | you: terminal | Regenerate the fact-check skill's eval reports on the host, where the web works, and commit them. | 2026-11-20 |
| [Q-336](#q-336--image-lag) | you: terminal | Install the release that carries nine changes you approved: the health-checkout preparation step (Q-333), w... | 2026-11-20 |
<!-- index:end -->

## Open

### Q-332 · regenerate-fact-check-reports-host
**Needs:** you: terminal · **Opened:** 2026-11-20 · **Status:** OPEN

Regenerate the fact-check skill's eval reports on the host, where the web works, and commit them.

**If you say no:** fact-check's 3 report-dependent test suites stay NOT RUN in every health check (they need generated reports to test against), and the skill's web-search behaviour goes untested; nothing else waits on it.

- **Why it's yours:** the reports need live WebSearch and WebFetch calls, and this sandbox has no web egress; only the host has it.
- **Read:** `docs/working/research-2026-11-20-eval-web-tools-grant.md` (the fix that merged at 6c0563b5: the report generator, `test/skills/generate-reports.bash`, now grants the web tools a fixture lists; before it, all 23 fact-check reports came out Unverified because every web call was denied) · the closed brief `docs/working/briefs/closed/2026-11-20-eval-web-tools-grant.md`.

**Where:** your claude-workflows checkout on the host, at main's tip (6c0563b5 or later), signed in to Claude Code. It runs the skill on each fixture with headless `claude` (subscription usage), then the three suites:

```
bash test/skills/generate-reports.bash fact-check && bats test/skills/fact-check-eval.bats test/skills/fact-check-edge-cases.bats test/skills/fact-check-format.bats
```

**Pass:** the bats run ends with no `not ok`; then commit `test/skills/fact-check/output/`. **Send back:** `Q-332: done`, or the first `not ok` lines if any fail (a failure is a skill finding for the cycle to file, not something to fix by hand).

- **Interim:** the suites stay NOT RUN; the regeneration of the other skills' reports (brief `docs/working/briefs/2026-11-19-regenerate-skill-reports.md`, held by Q-328 [3] until the F2 and F3 format fixes merge) excludes fact-check.
- **2026-11-20, iteration 2338:** the regeneration loop (merged 4f1e4150) ran fact-check's 23 fixtures in the sandbox with the new grant, and they produced real verdicts, so the host is not needed for the reports. 9 fact-check cases still fail on them (finding F12 in `docs/working/research-2026-11-19-regenerate-skill-reports.md`), so its reports were held back and its suites stay NOT RUN; the fix is now agent work on the roadmap. If you agree, answer `Q-332: drop`; nothing is lost.

### Q-336 · image-lag
**Needs:** you: terminal · **Opened:** 2026-11-20 · **Status:** OPEN

Install the release that carries nine changes you approved: the health-checkout preparation step (Q-333), worktree removals from a parked shell (Q-337), the cycle-record rule (Q-339), trials T9, T11 and T12 in the dev-cycle skill (Q-342), the write guard's corrected comments (Q-343) and its read-only deny hint (Q-356), the commit helper's literal-pathspecs guard (Q-348), the ask counter (Q-354), the digest's out-of-loop landings section (Q-353) and the board's feedback and weekly lines (Q-352): run the one paste below on the host.

**If you say no:** sessions keep running the image built from main 665dbf95: the dev cycle's gate has no `--health-prep` mode and `--settings` prints no `copies` line, so a `Health checkout copies:` line in a repo's `docs/dev-cycle.md` does nothing and philosophy-research keeps copying its Lean cache by hand. Nothing breaks. (The skill and test changes below are in the image too, but sessions read skills from it only after an install.)

- **C (the image's commit):** 665dbf9521413cf4291b4acebd866826b0ae2f52 · **M (main's commit):** 3121e6ed61de83f800b92623a6c69fdc1271a24f
- **Merged without your review** (the gate merged these on their own; the image carries none of `docs/`):
  - 319559d9 Merge branch 'docs/loop-start-dir-research' (build-loop self-merge): a research doc only
  - 6a07b026 Merge branch 'docs/why-its-yours-constraint-research' (build-loop self-merge): a research doc only
  - 6c0563b5 Merge branch 'fix/eval-web-tools-grant' (build-loop self-merge): `test/skills/generate-reports.bash` grants headless report runs the web tools a fixture lists, plus a new test file
  - 7b46a90e Merge branch 'fix/self-improvement-worktrees' (build-loop self-merge): `scripts/self-improvement.sh` puts its worktrees under `.worktrees/` instead of `.claude/`, with its test
  - 5eab5704 Merge branch 'fix/self-improvement-env-followups' (build-loop self-merge): `scripts/self-improvement.sh` runs its commit step with literal pathspecs off and moves its `TMPDIR` fallback from `.claude/tmp` to `.worktrees/si-tmp`, with tests
  - 4f1e4150 Merge branch 'measure/regenerate-skill-reports' (build-loop self-merge): 274 generated skill eval reports under `test/skills/*/output/` for 18 skills (Q-321 [2], held by Q-328 [3] until F2 to F7 merged); no code
  - 867f6546 Merge branch 'docs/review-gap-ba-compare' (build-loop self-merge): a research doc only
  - aa91635c Merge branch 'docs/harness-feedback-triage-2026-11-20' (build-loop self-merge): a research doc only
  - 7f086d40 Merge branch 'docs/board-feedback-research' (build-loop self-merge): a research doc only
  - 8daaa173 Merge branch 'fix/rubric-selection-flake' (build-loop self-merge): `scripts/self-improvement.sh`'s rubric selector reads here-strings instead of `printf | grep -q` (a SIGPIPE under `pipefail` dropped a point and broke ties), with two cases in `test/rubric-selection.bats`
  - 1bb24e5c Merge branch 'docs/stale-report-warnings' (build-loop self-merge): a research doc only
  - 88c695fd Merge branch 'fix/restamp-pre-grant-reports' (build-loop self-merge): the harness line of 81 report stamps under 11 skills' `test/skills/*/output/` updated to the current hash (no report regenerated); clears the health check's 312 stale-report warnings
  - 10785140 Merge branch 'docs/threat-model-walkthrough-prep' (build-loop self-merge): a research doc only
  - c3698169 Merge branch 'docs/reopen-040-asks-per-day' (build-loop self-merge): a research doc only
- **What changes for you:**
  - f6d555d8 (you approved it, Q-333 [1]): `build-loop.sh --health-prep HC` and a sixth `--settings` line, `copies`, read from a `Health checkout copies: PATH ...` line in `docs/dev-cycle.md`; the dev-cycle skill's step 1 copies those gitignored paths into its health checkout, refusing symlinks, unignored paths and anything outside it. To use it in philosophy-research, add `Health checkout copies: verifier/lean-project/.lake` to that repo's `docs/dev-cycle.md`.
  - cd16883e (Q-337 [1]): the dev-cycle skill removes each worktree in a separate call after a bare `cd` into `.worktrees` (R2), so background build loops stop losing commands; the build-loop prompt no longer says "Your shell starts outside any checkout".
  - fec9f7a3 (Q-339 [1]): `--cycle-diff` and `--land-cycle` refuse a cycle-record change that drops or rewrites earlier iteration blocks, or deletes the record; a fix to a landed block now lands by hand.
  - 9e27a4ea (Q-342 [1]): the dev-cycle skill writes trials T9 (links where they help, no cap of two), T11 (one deliberate look a week, counted) and T12 (what the checks caught, each line checkable) into its final message and weekly digest; one line of `docs/audiences/owner.md` changes to match.
  - abd8e21f (Q-343 [1]): comments only in `hooks/guard-trusted-writes.py` (the `.claude/wt-*` worktree case serves leftovers such as `.claude/wt-q096b`), with one test.
  - 2c388cfc (Q-348 [1]): `scripts/lib/si-commit.sh` turns literal pathspecs off for its one `git add`; the caller's copy is removed.
  - b9319b18 (Q-356 [1]): the write guard's Bash deny adds a read-only way forward (the Read tool, or a check in a script file run by path, for reads only); `hooks/web-taint-mark.py`'s docstring and one guide line now say Workflow subagents share the parent's taint.
  - 8409f853 (Q-352 [1]): `scripts/board.sh` prints a `feedback:` line (harness feedback not yet copied here, with the ingest command) and a `weekly:` line per repo; a new read-only `pending` mode in `scripts/harness-feedback.py`.
  - d80b3250 (Q-354 [1], first approved as Q-344): `scripts/questions.sh counts`, the reproducible ask counter, and the weekly digest's bullet to paste it.
  - 24d9ba2a (Q-353 [1]): the digest's new section 6b lists code landing on main outside the build loop, with its rubric state (`scripts/lib/landings.sh`, `scripts/dev-cycle.sh`, `scripts/lib/rubric-check.sh`), and the skill's step 4 files each one.
  - 01eff59e (Q-335 [1]): findings F2 and F3, seven skills' report formats (title first; a field's value word first), with test-helper changes.
  - cef30487 (Q-329 [1]) and ead9191a (Q-330 [1]): findings F4 to F7 and the F5 verdict drift, in six skills and their tests.
  - 21e925d3: your own commit recording the Q-316 and Q-317 answers; 7df4654d: your answers file `docs/human-author/answers-11-20-26.txt`; ad4f0eef: your harness-feedback ingest (three `docs/working/feedback/` files).
  - The routine rest: 50 dev-cycle lands.
- **Full list:** `git -c log.showSignature=false log --first-parent --format='%h %s' 665dbf9521413cf4291b4acebd866826b0ae2f52..3121e6ed61de83f800b92623a6c69fdc1271a24f`
- **Paths changed outside `docs/`, the 274 generated reports under `test/skills/*/output/` counted, not listed (`git diff --name-only 665dbf9521413cf4291b4acebd866826b0ae2f52 3121e6ed61de83f800b92623a6c69fdc1271a24f -- test/skills/` shows them) (80 under `docs/` too, which the image does not carry):** `guides/bare-host-hook-wiring.md`, `guides/cross-project-board.md`, `guides/harness-feedback.md`, `hooks/guard-trusted-writes.py`, `hooks/web-taint-mark.py`, `scripts/board.sh`, `scripts/build-loop.sh`, `scripts/dev-cycle.sh`, `scripts/harness-feedback.py`, `scripts/lib/dev-cycle-read.sh`, `scripts/lib/landings.sh`, `scripts/lib/rubric-check.sh`, `scripts/lib/si-commit.sh`, `scripts/questions.sh`, `scripts/self-improvement.sh`, `skills/ai-personas-critique/SKILL.md`, `skills/arithmetic-eval/SKILL.md`, `skills/business-plan-critique-market-sizing/SKILL.md`, `skills/business-plan-critique-moat/SKILL.md`, `skills/dependency-upgrade/SKILL.md`, `skills/dev-cycle/SKILL.md`, `skills/security-reviewer/SKILL.md`, `skills/tech-debt-triage/SKILL.md`, `skills/ui-visual-review/SKILL.md`, `skills/what-if-analysis/SKILL.md`, `skills/yglesias-critique/SKILL.md`, `test/generate-reports-web-grant.bats`, `test/hooks/guard-trusted-writes.bats`, `test/rubric-selection.bats`, `test/scripts/board.bats`, `test/scripts/build-loop-dispatch.bats`, `test/scripts/build-loop-health-prep.bats`, `test/scripts/build-loop-orchestrator.bats`, `test/scripts/build-loop-read.bats`, `test/scripts/dev-cycle-landings.bats`, `test/scripts/harness-feedback.bats`, `test/scripts/questions-counts.bats`, `test/scripts/self-improvement-clean-state.bats`, `test/si-commit-child-work.bats`, `test/skills/architecture-review-format.bats`, `test/skills/architecture-review/eval-criteria.md`, `test/skills/architecture-review/fixtures/tc-arch6-clean-ports-adapters.py`, `test/skills/business-plan-critique-moat/expected-verdicts.bash`, `test/skills/code-fact-check/eval-criteria.md`, `test/skills/code-fact-check/expected-verdicts.bash`, `test/skills/code-fact-check/fixtures/tc-c2.5-unverifiable.py`, `test/skills/dependency-upgrade-format.bats`, `test/skills/divergent-design/expected-verdicts.bash`, `test/skills/eval-helpers.bash`, `test/skills/field-value-rules.bats`, `test/skills/generate-reports.bash`, `test/skills/helpers-recommendation.bats`, `test/skills/helpers.bash`, `test/skills/matrix-analysis-format.bats`, `test/skills/pre-mortem-format.bats`, `test/skills/tech-debt-triage/expected-verdicts.bash`, `test/skills/test-strategy/eval-criteria.md`, `test/skills/test-strategy/fixtures/tc-ts6-duration-parser.py`, `test/skills/ui-visual-review-eval.bats`, `test/skills/ui-visual-review-format.bats`, `test/skills/ui-visual-review/eval-criteria.md`, `test/skills/ui-visual-review/expected-verdicts.bash`, `test/skills/ui-visual-review/fixtures/tc-uv6-disappearing-controls.tsx`, `test/skills/ui-visual-review/fixtures/tc-uv7-weak-affordance.tsx`, `test/skills/what-if-analysis-format.bats`

Run this on the host, in your claude-workflows checkout at main's tip, then start a new sandbox session:

```
sh -c 'n=0; if cd "/home/magfrump/claude-workflows"; then n=1; fi; if h="$(git rev-parse HEAD)" && test "$h" = "$(git rev-parse refs/heads/main)"; then n=$((n+1)); else echo "release refused: this checkout is not at the tip of main"; fi; for p in scripts/build-loop.sh scripts/d6.sh scripts/dev-cycle.sh scripts/questions.sh scripts/lib/ skills/dev-cycle/ devcontainer-config/install.sh; do if g="$(git rev-parse "HEAD:$p")" && test "$g" = "$(git rev-parse "3121e6ed61de83f800b92623a6c69fdc1271a24f:$p")"; then n=$((n+1)); else echo "release refused: $p changed after 3121e6ed61de83f800b92623a6c69fdc1271a24f: run the dev cycle for a new paste"; fi; done; case "$n" in 9) ./devcontainer-config/install.sh;; *) echo "release refused: $n of 9 checks passed"; false;; esac'
```

**Pass:** the installer finishes without a `release refused` line. **Send back:** `Q-336: done`.

Optional, for watch Q-167 (post-install-host-probes: the hint a fresh bless prints before any probe has never been seen): if the install re-blesses, add `| tee "$TMPDIR/install.log"` to the end of the paste, and right after it, before any probe, send back the output of `grep -E 'Verified live:|^Next:' "$TMPDIR/install.log"` and `cc-isolated --list 2>&1 | grep -i 'blessed config'` (three lines).

Optional, for watch Q-331 (the write-guard fix 61122f34 has no live check): in a session that has done a web search, an edit to an ordinary file inside a `.claude/worktrees/` worktree applies with no ask, while an edit to that worktree's CLAUDE.md still asks. Add `guard: fine`, or what asked.

Optional, for the board change (Q-352, merged 8409f853): after the install, run `~/.claude/scripts/board.sh; echo "board exit $?"` with claude-workflows and at least one project that has `docs/harness-feedback.md` in your board registry. Expect a `feedback:` line under each such project and a `weekly:` line under each repo with digests. Add `board: fine`, or what it printed.

- **Interim:** the image's gate (665dbf95) runs; nothing breaks.

### Q-350 · threat-model-walkthrough-2026-q4
**Needs:** you: walkthrough · **Opened:** 2026-11-20 · **Status:** OPEN

Walk through the risks you accepted in the build-loop design (about 20 minutes) and say for each: keep, tighten or retire.

**If you say no:** every residual stays accepted as listed, and the next walkthrough comes back on or after 2027-02-20 (watch Q-351).

- **Why it's yours:** these are risks you accepted (mostly in Q-103, the build-loop policy entry, answered self-merge on 2026-10-17); only you can keep or retire them. You asked for this each quarter in Q-340 [1].
- **Read:** the table and checks in `docs/working/research-2026-11-20-threat-model-walkthrough-prep.md` §3-§5 (16 rows, R1 to R16; R13 to R16 are out of scope under constraint S1, a hostile author, and get one question together).
- **Time:** about 20 minutes; the checks are git and `rg` commands, one `scripts/questions.sh check`, and a look at GitHub's branch list and `/artifacts`; the host install check (C11) waits for the next release.
- **Three rows worth your look first** (the preparation found them; none is decided): R2's stated bound changed after you accepted it (the plan says the sandbox bounds a steered loop, but decision-log row 88 removed the sandbox on 2026-11-12, so the bound is the container plus `permissions.deny` and the approve hook); R6 is reachable today (`/workspace` holds main and other sessions switch its branch); R10 occurred once (Q-339's approving answer line was written by a cycle session from your in-session answer, and nothing in git records that you gave it).

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] keep all** | Every residual stays accepted as listed. | About 20 minutes. | A risk that has moved stays unaddressed until next quarter. |
| **[2] keep, with changes** | Answer per row, for example "R2 tighten, R8 retire". | About 20 minutes plus one line. | A tighten becomes a roadmap item the cycle builds. |

- **Blocks:** nothing.
- **Interim:** every residual stays accepted as it was; nothing changes until you answer.
- **If the answer differs:** each "tighten" becomes a roadmap item; each "retire" gets a decision-log row and leaves next quarter's table.

### Q-357 · merge-gate-2026-11-20-pipefail-grep-q-265fdab2a55a
**Needs:** you: judgment · **Opened:** 2026-11-20 · **Status:** OPEN

Merge the build loop's fix for pipelines into `grep -q` that can lose a match under `pipefail`, two of which failed open?

**If you say no:** the branch waits unmerged; a self-improvement planner path holding a newline then `..` or a glob followed by a long tail is still accepted, the conflict check after the resolver can still read "no conflicts" wrongly, and the board can print a refusal twice.

The rubric-selection flake (fixed 8daaa173) was this shape: `printf … | grep -q` under `pipefail`, where grep exits at its first match, the writer dies of SIGPIPE, and the `if` reads exit 141 as "no match" (failure pattern FP-175 in `docs/failure-patterns.md`). Brief: `docs/working/briefs/2026-11-20-pipefail-grep-q.md`. `scripts/lib/si-functions.sh` is gate code (everything under `scripts/lib/` is), so this needs your review.

- **Fixed (here-strings, so the exit status is grep's own, each with a comment naming FP-175):** `validate_task_json`'s `..` and glob checks in `scripts/lib/si-functions.sh` (failed open: such a path was accepted); the unmerged-paths check after the conflict resolver in `scripts/self-improvement.sh` (failed open, reading "no conflicts"; no test, since no reachable state gives it a large input); `first_refusal` in `scripts/board.sh` (printed a refusal twice; the brief's list missed it).
- **Marked safe, with reasons in the research doc:** eight single-line sites (grep reads the whole line before it can exit), hooks that do not set `pipefail`, and one `dev-cycle.sh` site that can only abort, not lose a match.
- **Tests:** three new cases with about 200 KB after the match (two in `test/validate-task-json.bats`, one in `test/scripts/board.bats`), each failing on the old code; touched suites, hermeticity lint and health check pass. Rubric clean (0 red, 3 amber, none open).
- **Left for later:** `| head` readers under `set -e` (for example `scripts/self-improvement.sh:1695`) can abort a script rather than lose a match; now a roadmap item.
- **Read:** `docs/working/research-2026-11-20-pipefail-grep-q.md` (the site table); the rubric `docs/reviews/pipefail-grep-q-code-review-rubric-2026-11-20.md`; the diff: `git diff c12095f4 265fdab2 -- scripts/ test/` (5 files, 55 lines added, 6 removed).

TIP: 265fdab2a55ae6a228dc1f546ae84323dfebbac3

`--check`'s lines:

```
ok docs/working/briefs/2026-11-20-pipefail-grep-q.md 265fdab2a55ae6a228dc1f546ae84323dfebbac3 5996a1f326939815afaecdc62d3ebcad126c88ba
path docs/working/briefs/2026-11-20-pipefail-grep-q.md A docs/reviews/pipefail-grep-q-code-review-rubric-2026-11-20.md
path docs/working/briefs/2026-11-20-pipefail-grep-q.md M docs/working/briefs/2026-11-20-pipefail-grep-q.md
path docs/working/briefs/2026-11-20-pipefail-grep-q.md A docs/working/research-2026-11-20-pipefail-grep-q.md
path docs/working/briefs/2026-11-20-pipefail-grep-q.md M scripts/board.sh
path docs/working/briefs/2026-11-20-pipefail-grep-q.md M scripts/lib/si-functions.sh
path docs/working/briefs/2026-11-20-pipefail-grep-q.md M scripts/self-improvement.sh
path docs/working/briefs/2026-11-20-pipefail-grep-q.md M test/scripts/board.bats
path docs/working/briefs/2026-11-20-pipefail-grep-q.md M test/validate-task-json.bats
rubric docs/working/briefs/2026-11-20-pipefail-grep-q.md: clean docs/reviews/pipefail-grep-q-code-review-rubric-2026-11-20.md: 0 red and 3 amber rows, none open
```

- **Paths self-merge would have refused:** `scripts/lib/si-functions.sh` (gate code).
- **What an attacker would want here:** a planner path is model output from the self-improvement loop; a stranger's text that steered a planner could already have used the fail-open path checks, so this change only closes a gap and adds no input.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] merge** | The gate merges TIP above. | Reading a 55-line diff. | One `git revert` undoes it. |
| **[2] drop** | The brief closes; the three sites stay as they are. | Nothing. | Two checks keep failing open on large input. |
| **[3] changes needed** | Your note goes back to the loop. | Writing the note. | Another round. |

- **Interim:** the branch waits; nothing merges.

### Q-358 · merge-gate-2026-11-20-answers-file-route-a7a04dc995e1
**Needs:** you: judgment · **Opened:** 2026-11-20 · **Status:** OPEN

Merge the build loop's change that lets a committed `docs/human-author/answers-*` file count as your answer?

**If you say no:** the branch waits unmerged; an answers file you commit is still read as an `other` commit, and the cycle asks again for answers you already gave in it (as with 7df4654d, your answers to Q-255, Q-302 and Q-327).

You chose this route in Q-345 [1] (the gate reads the file). Brief: `docs/working/briefs/2026-11-20-answers-file-route.md`. The loop's marker has no body: no question left open.

- **What it does:** `--check-answer` (the gate's answer reader) also reads lines `Q-NNN: ANSWER` from files named `answers-*` directly under `docs/human-author/` on main, added on or after the entry's `Opened:` date, by the same answer rule as the questions files (one shared `option()` in `scripts/lib/dev-cycle-read.sh`). The questions file's own answer wins when both agree; when they disagree, or two files disagree, or a file cannot be read, the ID is printed as a skip naming both, never guessed. `--main-log` classes a commit that only adds such files as `answers`. The skill's steps 0.2 and 7 and the board say so.
- **Tests and review:** bats cases in `test/scripts/dev-cycle.bats`, `build-loop-merge.bats`, `build-loop-orchestrator.bats` and `board.bats`; rubric clean (0 red, 1 amber, none open).
- **For you, after it is live:** your untracked answers files in the main checkout (`docs/human-author/answers-11-*.txt`) are not read until committed, and only for entries opened on or before the commit's date.
- **Read:** `docs/working/research-2026-11-20-answers-file-route.md`; the rubric `docs/reviews/code-review-rubric-2026-11-20-answers-file-route.md`; the diff: `git diff 5627e74c a7a04dc9 -- scripts/ skills/ test/` (10 files, 312 lines added, 15 removed).

TIP: a7a04dc995e1080630f596919a6c52cb741ea034

`--check`'s lines:

```
ok docs/working/briefs/2026-11-20-answers-file-route.md a7a04dc995e1080630f596919a6c52cb741ea034 88ae45798916fd38eb118fd2d22946c6fae7649b
path docs/working/briefs/2026-11-20-answers-file-route.md A docs/reviews/code-review-rubric-2026-11-20-answers-file-route.md
path docs/working/briefs/2026-11-20-answers-file-route.md M docs/working/briefs/2026-11-20-answers-file-route.md
path docs/working/briefs/2026-11-20-answers-file-route.md A docs/working/research-2026-11-20-answers-file-route.md
path docs/working/briefs/2026-11-20-answers-file-route.md M scripts/board.sh
path docs/working/briefs/2026-11-20-answers-file-route.md M scripts/build-loop.sh
path docs/working/briefs/2026-11-20-answers-file-route.md M scripts/dev-cycle.sh
path docs/working/briefs/2026-11-20-answers-file-route.md M scripts/lib/dev-cycle-read.sh
path docs/working/briefs/2026-11-20-answers-file-route.md M scripts/lib/rubric-check.sh
path docs/working/briefs/2026-11-20-answers-file-route.md M skills/dev-cycle/SKILL.md
path docs/working/briefs/2026-11-20-answers-file-route.md M test/scripts/board.bats
path docs/working/briefs/2026-11-20-answers-file-route.md M test/scripts/build-loop-merge.bats
path docs/working/briefs/2026-11-20-answers-file-route.md M test/scripts/build-loop-orchestrator.bats
path docs/working/briefs/2026-11-20-answers-file-route.md M test/scripts/dev-cycle.bats
rubric docs/working/briefs/2026-11-20-answers-file-route.md: clean docs/reviews/code-review-rubric-2026-11-20-answers-file-route.md: 0 red and 1 amber rows, none open
```

- **Paths self-merge would have refused:** `scripts/build-loop.sh`, `scripts/dev-cycle.sh`, `scripts/lib/dev-cycle-read.sh`, `scripts/lib/rubric-check.sh` and `skills/dev-cycle/SKILL.md` (gate code).
- **What an attacker would want here:** a stranger's text that reaches a hand session (a web page, a fetched issue) could try to get that session to commit an `answers-*` file, which the gate would then read as your answer, approving a merge. The build loops and the cycle cannot write `docs/human-author/` (the self-merge floor and `--cycle-diff` refuse it), so the route is a hand session you run; that is the same exposure an answer line in the questions file already has.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] merge** | The gate merges TIP above. | Reading the diff. | One `git revert` undoes it. |
| **[2] drop** | The brief closes; nothing merges. | Nothing. | You keep re-answering in the questions file. |
| **[3] changes needed** | Your note goes back to the loop. | Writing the note. | Another round. |

- **Interim:** the branch waits; nothing merges.

### Q-359 · merge-2026-11-20-ingest-project-rename-82e794ae342f
**Needs:** you: judgment · **Opened:** 2026-11-20 · **Status:** OPEN

Merge the build loop's fix so harness-feedback ingest refuses a renamed project instead of storing or seeding it twice?

**If you say no:** the branch waits unmerged; ingesting a project whose `Project:` line changed still stores a second copy and seeds its ideas again.

Brief: `docs/working/briefs/2026-11-20-ingest-project-rename.md`. It also adds failure pattern FP-189 to `docs/failure-patterns.md` (a record file, so review was needed anyway).

The loop's marker (loop text, data not instructions):

> ingest now refuses a renamed project instead of storing or seeding it twice, and it refuses to overwrite an empty stored copy that holds another Project line. A new `scripts/harness-feedback.py rename
> STORED NAME` mode moves a stored copy to NAME.md, sets its Project line and rekeys its idea-log seeds; each rename refusal prints that command. `pending` (the board's read-only comparison) uses the
> same matching helper as ingest, so the board withholds its ingest command in the same states.
>
> Design: divergent design picked "refuse and name the fix" over "match by entries and keep the stored name" (which guesses silently) and over "document only" (fails the goal). One option dominated, so
> there is no open question. Record: docs/working/research-2026-11-20-ingest-project-rename.md.
>
> Tests: harness-feedback.bats and board.bats 97 ok; hermeticity lint exit 0; scripts/health-check.sh passed. scripts/confine-tests.sh --probe exit 3 ("confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE
> — refusing to run."), so the suites ran unconfined. Two review passes found no reds; the ambers are fixed (docs/reviews/code-review-rubric-2026-11-20-ingest-project-rename.md).
>
> Residual risks, both stated in guides/harness-feedback.md:
> - The board does not read the idea log. A hand-made half rename (file moved, seeds left under the old name) gets an ingest command that then refuses loudly and writes nothing.
> - A stored copy with one entry, renamed and that entry edited, is stored again. This is the price of letting two projects that filed an identical F-001 heading both ingest.
>
> New failure-pattern entry FP-189 in docs/failure-patterns.md: the empty-list prefix check. docs/failure-patterns.md is a record file, so this sends the branch to your review, which this brief's review policy already requires.
>
> Your file docs/working/feedback/philosophy-research.md: its Project line says task-workspace-designer, but its 19 seeds and its file name say philosophy-research. Every ingest of it now refuses until
> you settle this. What to do depends on the Project line in that project's own docs/harness-feedback.md, which the sandbox cannot see:
> - If the project says task-workspace-designer, keep the line and run, from claude-workflows: scripts/harness-feedback.py rename docs/working/feedback/philosophy-research.md task-workspace-designer
> - If it still says philosophy-research, change this line back (or run the same rename command with NAME philosophy-research, which does that and keeps the seeds).

In plain words (the cycle's gloss): "the board" is `scripts/board.sh`, the cross-project status page (`guides/cross-project-board.md`); the stored copies are `docs/working/feedback/<project>.md`, copied from each project's `docs/harness-feedback.md`. The last paragraph of the marker is a second, separate step after merging: once this is live, ingest of philosophy-research's feedback refuses until its `Project:` line is settled. If you merge, the cycle files that as its own entry rather than fold it into this one.

- **Read:** `docs/working/research-2026-11-20-ingest-project-rename.md`; the rubric `docs/reviews/code-review-rubric-2026-11-20-ingest-project-rename.md`; the diff: `git diff 5627e74c 82e794ae -- scripts/ guides/ test/` (5 files, 408 lines added, 35 removed).

TIP: 82e794ae342f30d628081b3ac0fab68ab12b5164

`--check`'s lines:

```
ok docs/working/briefs/2026-11-20-ingest-project-rename.md 82e794ae342f30d628081b3ac0fab68ab12b5164 da4892f32c3bbe12f98a58e19916ac20fdb7afc9
path docs/working/briefs/2026-11-20-ingest-project-rename.md M docs/failure-patterns.md
path docs/working/briefs/2026-11-20-ingest-project-rename.md A docs/reviews/code-review-rubric-2026-11-20-ingest-project-rename.md
path docs/working/briefs/2026-11-20-ingest-project-rename.md M docs/working/briefs/2026-11-20-ingest-project-rename.md
path docs/working/briefs/2026-11-20-ingest-project-rename.md A docs/working/research-2026-11-20-ingest-project-rename.md
path docs/working/briefs/2026-11-20-ingest-project-rename.md M guides/cross-project-board.md
path docs/working/briefs/2026-11-20-ingest-project-rename.md M guides/harness-feedback.md
path docs/working/briefs/2026-11-20-ingest-project-rename.md M scripts/harness-feedback.py
path docs/working/briefs/2026-11-20-ingest-project-rename.md M test/scripts/board.bats
path docs/working/briefs/2026-11-20-ingest-project-rename.md M test/scripts/harness-feedback.bats
rubric docs/working/briefs/2026-11-20-ingest-project-rename.md: clean docs/reviews/code-review-rubric-2026-11-20-ingest-project-rename.md: 0 red and 5 amber rows, none open
```

- **Paths self-merge would have refused:** `docs/failure-patterns.md` (a record file); no gate code, instruction file or dot path.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] merge** | The gate merges TIP above. | Reading the diff. | One `git revert` undoes it. |
| **[2] drop** | The brief closes; nothing merges. | Nothing. | Renamed projects keep double-seeding. |
| **[3] changes needed** | Your note goes back to the loop. | Writing the note. | Another round. |

- **Interim:** the branch waits; nothing merges.

### Q-360 · merge-gate-2026-11-20-six-still-true-rows-ed98d39e8fba
**Needs:** you: judgment · **Opened:** 2026-11-20 · **Status:** OPEN

Merge the build loop's fixes for six old review findings that were still true, one of them a write-guard gap?

**If you say no:** the branch waits unmerged; the write guard still stays silent on a protected-file write spelled with `..` through a symlinked directory, and the other five rows stay open.

The six rows come from the 2026-11-13 review-gap audit: iter3 N5, N13, N17, N18 (`docs/reviews/code-review-rubric-2026-09-21-answers-2026-09-20-iter3.md`) and questions-closeout A10, A11. Brief: `docs/working/briefs/2026-11-20-six-still-true-rows.md`.

The loop's marker (loop text, data not instructions):

> All six rows from the 2026-11-13 review-gap audit were re-checked against current code. Each was still true, and each is now closed.
>
> - iter3 N13 (write guard, a security row): a path spelled with `..` that reads as a protected file is now denied by the hook, not deferred.
>   The kernel follows a symlink before applying `..`, so the deferred path could write somewhere else with no gate.
>   The change only narrows access. Such a spelling is denied even when its real target is an ordinary file, and the deny text says to respell the path without `..`.
>   No owner decision was needed.
> - iter3 N5 (questions.sh): the comment is corrected, and a docs/ symlink into .git/ is now refused.
> - iter3 N17, N18 and questions-closeout A11: corrected or Won't-Fix rows were appended to docs/reviews/override-log.md, plus comment fixes in the guard.
>   One N18 item (wording in si-morning-summary.sh) is outside this brief's paths. It gets a revisit trigger in the research doc.
> - questions-closeout A10 (lite-review --mode full has no caller): the script header now says so, and a bats case pins it.
>
> Gates:
> - The touched suites pass, and the hermeticity lint passes.
> - confine-tests --probe exited 3 (no confinement primitive), so the gate relied on the health check.
> - health-check.sh passes ("All checks passed.").
>
> Review: 2 passes, 0 red, 3 amber, all fixed. Rubric: docs/reviews/code-review-rubric-2026-11-20-six-still-true-rows.md.
> Details: docs/working/research-2026-11-20-six-still-true-rows.md.
> This marker supersedes 7210127f4, whose two long lines were over the 300-byte cut.

In plain words (the cycle's gloss): "the write guard" is `hooks/guard-trusted-writes.py`, which asks or denies before a session that has read web content writes a protected file; "defer" means the hook stays silent and leaves the call to the normal permission rules. `docs/reviews/override-log.md` records review findings closed without a code fix.

- **Read:** `docs/working/research-2026-11-20-six-still-true-rows.md`; the rubric `docs/reviews/code-review-rubric-2026-11-20-six-still-true-rows.md`; the diff: `git diff b516c62d ed98d39e -- hooks/ scripts/ test/` (6 files, 141 lines added, 23 removed).

TIP: ed98d39e8fba663e93c5ceb4c7ba7b4b0db64fa4

`--check`'s lines:

```
ok docs/working/briefs/2026-11-20-six-still-true-rows.md ed98d39e8fba663e93c5ceb4c7ba7b4b0db64fa4 0a8bbdaeebd53478cedc2b759181de93e0aacd6f
path docs/working/briefs/2026-11-20-six-still-true-rows.md A docs/reviews/code-review-rubric-2026-11-20-six-still-true-rows.md
path docs/working/briefs/2026-11-20-six-still-true-rows.md M docs/reviews/override-log.md
path docs/working/briefs/2026-11-20-six-still-true-rows.md M docs/working/briefs/2026-11-20-six-still-true-rows.md
path docs/working/briefs/2026-11-20-six-still-true-rows.md A docs/working/research-2026-11-20-six-still-true-rows.md
path docs/working/briefs/2026-11-20-six-still-true-rows.md M hooks/guard-trusted-writes.py
path docs/working/briefs/2026-11-20-six-still-true-rows.md M scripts/lite-review.py
path docs/working/briefs/2026-11-20-six-still-true-rows.md M scripts/questions.sh
path docs/working/briefs/2026-11-20-six-still-true-rows.md M test/hooks/guard-trusted-writes.bats
path docs/working/briefs/2026-11-20-six-still-true-rows.md M test/lite-review-fix-drift-prompt.bats
path docs/working/briefs/2026-11-20-six-still-true-rows.md M test/questions-doc.bats
rubric docs/working/briefs/2026-11-20-six-still-true-rows.md: clean docs/reviews/code-review-rubric-2026-11-20-six-still-true-rows.md: 0 red and 3 amber rows, none open
```

- **Paths self-merge would have refused:** `scripts/questions.sh` (gate code). `hooks/guard-trusted-writes.py` is an enforcement file (its commits carry a `Live-verified:` trailer; the gate does not check that at merge).
- **What an attacker would want here:** a stranger's web text that reaches a session and gets it to write a protected instruction or settings file without an ask, by spelling the path through a symlinked directory and `..`. This change closes that route (deny, not defer) and only narrows what the guard allows.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] merge** | The gate merges TIP above. | Reading the diff. | One `git revert` undoes it. |
| **[2] drop** | The brief closes; nothing merges. | Nothing. | The `..` route in the write guard stays open. |
| **[3] changes needed** | Your note goes back to the loop. | Writing the note. | Another round. |

- **Interim:** the branch waits; nothing merges.
