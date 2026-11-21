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
| [Q-352](#q-352--merge-2026-11-20-board-pending-feedback-87ce7a6d7475) | you: judgment | Merge the build loop's cross-project board change, which shows each project's harness feedback not yet copi... | 2026-11-20 |
| [Q-353](#q-353--merge-gate-2026-11-20-out-of-loop-landings-93e88269fbd1) | you: judgment | Merge the build loop's digest section that lists code landing on main outside the build loop, with each lan... | 2026-11-20 |
| [Q-354](#q-354--merge-gate-2026-11-20-ask-counter-8a4df684dfae) | you: judgment | Merge the ask counter (`questions.sh counts`) at its new tip, now that it has merged main in after its conf... | 2026-11-20 |
| [Q-350](#q-350--threat-model-walkthrough-2026-q4) | you: walkthrough | Walk through the risks you accepted in the build-loop design (about 20 minutes) and say for each: keep, tig... | 2026-11-20 |
| [Q-332](#q-332--regenerate-fact-check-reports-host) | you: terminal | Regenerate the fact-check skill's eval reports on the host, where the web works, and commit them. | 2026-11-20 |
| [Q-336](#q-336--image-lag) | you: terminal | Install the release that carries six gate changes you approved: the health-checkout preparation step (Q-333... | 2026-11-20 |
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

Install the release that carries six gate changes you approved: the health-checkout preparation step (Q-333), worktree removals from a parked shell (Q-337), the cycle-record rule (Q-339), trials T9, T11 and T12 in the dev-cycle skill (Q-342), the write guard's corrected comments (Q-343) and the commit helper's literal-pathspecs guard (Q-348): run the one paste below on the host.

**If you say no:** sessions keep running the image built from main 665dbf95: the dev cycle's gate has no `--health-prep` mode and `--settings` prints no `copies` line, so a `Health checkout copies:` line in a repo's `docs/dev-cycle.md` does nothing and philosophy-research keeps copying its Lean cache by hand. Nothing breaks. (The skill and test changes below are in the image too, but sessions read skills from it only after an install.)

- **C (the image's commit):** 665dbf9521413cf4291b4acebd866826b0ae2f52 · **M (main's commit):** c36981691633b6d992d7a7043854695c9312cbdc
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
  - 01eff59e (Q-335 [1]): findings F2 and F3, seven skills' report formats (title first; a field's value word first), with test-helper changes.
  - cef30487 (Q-329 [1]) and ead9191a (Q-330 [1]): findings F4 to F7 and the F5 verdict drift, in six skills and their tests.
  - 21e925d3: your own commit recording the Q-316 and Q-317 answers; 7df4654d: your answers file `docs/human-author/answers-11-20-26.txt`; ad4f0eef: your harness-feedback ingest (three `docs/working/feedback/` files).
  - The routine rest: 43 dev-cycle lands.
- **Full list:** `git -c log.showSignature=false log --first-parent --format='%h %s' 665dbf9521413cf4291b4acebd866826b0ae2f52..c36981691633b6d992d7a7043854695c9312cbdc`
- **Paths changed outside `docs/`, the 274 generated reports under `test/skills/*/output/` counted, not listed (`git diff --name-only 665dbf9521413cf4291b4acebd866826b0ae2f52 c36981691633b6d992d7a7043854695c9312cbdc -- test/skills/` shows them) (67 under `docs/` too, which the image does not carry):** `hooks/guard-trusted-writes.py`, `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `scripts/lib/si-commit.sh`, `scripts/self-improvement.sh`, `skills/ai-personas-critique/SKILL.md`, `skills/arithmetic-eval/SKILL.md`, `skills/business-plan-critique-market-sizing/SKILL.md`, `skills/business-plan-critique-moat/SKILL.md`, `skills/dependency-upgrade/SKILL.md`, `skills/dev-cycle/SKILL.md`, `skills/security-reviewer/SKILL.md`, `skills/tech-debt-triage/SKILL.md`, `skills/ui-visual-review/SKILL.md`, `skills/what-if-analysis/SKILL.md`, `skills/yglesias-critique/SKILL.md`, `test/generate-reports-web-grant.bats`, `test/hooks/guard-trusted-writes.bats`, `test/rubric-selection.bats`, `test/scripts/build-loop-dispatch.bats`, `test/scripts/build-loop-health-prep.bats`, `test/scripts/build-loop-orchestrator.bats`, `test/scripts/build-loop-read.bats`, `test/scripts/self-improvement-clean-state.bats`, `test/si-commit-child-work.bats`, `test/skills/architecture-review-format.bats`, `test/skills/architecture-review/eval-criteria.md`, `test/skills/architecture-review/fixtures/tc-arch6-clean-ports-adapters.py`, `test/skills/business-plan-critique-moat/expected-verdicts.bash`, `test/skills/code-fact-check/eval-criteria.md`, `test/skills/code-fact-check/expected-verdicts.bash`, `test/skills/code-fact-check/fixtures/tc-c2.5-unverifiable.py`, `test/skills/dependency-upgrade-format.bats`, `test/skills/divergent-design/expected-verdicts.bash`, `test/skills/eval-helpers.bash`, `test/skills/field-value-rules.bats`, `test/skills/generate-reports.bash`, `test/skills/helpers-recommendation.bats`, `test/skills/helpers.bash`, `test/skills/matrix-analysis-format.bats`, `test/skills/pre-mortem-format.bats`, `test/skills/tech-debt-triage/expected-verdicts.bash`, `test/skills/test-strategy/eval-criteria.md`, `test/skills/test-strategy/fixtures/tc-ts6-duration-parser.py`, `test/skills/ui-visual-review-eval.bats`, `test/skills/ui-visual-review-format.bats`, `test/skills/ui-visual-review/eval-criteria.md`, `test/skills/ui-visual-review/expected-verdicts.bash`, `test/skills/ui-visual-review/fixtures/tc-uv6-disappearing-controls.tsx`, `test/skills/ui-visual-review/fixtures/tc-uv7-weak-affordance.tsx`, `test/skills/what-if-analysis-format.bats`

Run this on the host, in your claude-workflows checkout at main's tip, then start a new sandbox session:

```
sh -c 'n=0; if cd "/home/magfrump/claude-workflows"; then n=1; fi; if h="$(git rev-parse HEAD)" && test "$h" = "$(git rev-parse refs/heads/main)"; then n=$((n+1)); else echo "release refused: this checkout is not at the tip of main"; fi; for p in scripts/build-loop.sh scripts/d6.sh scripts/dev-cycle.sh scripts/questions.sh scripts/lib/ skills/dev-cycle/ devcontainer-config/install.sh; do if g="$(git rev-parse "HEAD:$p")" && test "$g" = "$(git rev-parse "c36981691633b6d992d7a7043854695c9312cbdc:$p")"; then n=$((n+1)); else echo "release refused: $p changed after c36981691633b6d992d7a7043854695c9312cbdc: run the dev cycle for a new paste"; fi; done; case "$n" in 9) ./devcontainer-config/install.sh;; *) echo "release refused: $n of 9 checks passed"; false;; esac'
```

**Pass:** the installer finishes without a `release refused` line. **Send back:** `Q-336: done`.

Optional, for watch Q-167 (post-install-host-probes: the hint a fresh bless prints before any probe has never been seen): if the install re-blesses, add `| tee "$TMPDIR/install.log"` to the end of the paste, and right after it, before any probe, send back the output of `grep -E 'Verified live:|^Next:' "$TMPDIR/install.log"` and `cc-isolated --list 2>&1 | grep -i 'blessed config'` (three lines).

Optional, for watch Q-331 (the write-guard fix 61122f34 has no live check): in a session that has done a web search, an edit to an ordinary file inside a `.claude/worktrees/` worktree applies with no ask, while an edit to that worktree's CLAUDE.md still asks. Add `guard: fine`, or what asked.

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

### Q-352 · merge-2026-11-20-board-pending-feedback-87ce7a6d7475
**Needs:** you: judgment · **Opened:** 2026-11-20 · **Status:** OPEN

Merge the build loop's cross-project board change, which shows each project's harness feedback not yet copied here and each repo's latest weekly digest?

**If you say no:** the branch waits unmerged; feedback keeps reaching this repo only when you happen to look (37 entries waited a median 5 days, at most 18), and the weekly digest stays off the board.

This is your 2026-11-20 request ("surface projects that have new harness feedback to copy to this repo") plus trial T11's note that the digest belongs on the board. Brief: `docs/working/briefs/2026-11-20-board-pending-feedback.md`; design: `docs/working/research-2026-11-20-board-feedback-research.md` (merged 7f086d40). `scripts/board.sh` is host code (it runs on your machine), which is why it needs your review.

- **What changes:** under each project's `main DATE` line the board prints a `feedback:` line (`N entries, all copied`, or `K not copied (F-a to F-b), C changed` with the `ingest` command, withheld when ingest would refuse or store a duplicate) and a `weekly:` line (the latest `docs/working/weekly/` edition). Any unreadable state prints `UNREADABLE` or `NOT COMPARED` and makes the board exit 1. The comparison is a new read-only `pending` mode in `scripts/harness-feedback.py`.
- **Tests:** both bats suites pass (87 cases), hermeticity lint and health check pass; three review passes, rubric clean (0 red, 3 amber, none open). `board.sh` is 499 lines, one under the 500-line limit.
- **After it merges:** one host step, filed then as a `you: terminal` entry: after the next release, run the board and look for the new lines.
- **Two findings it left for the cycle** (now roadmap items): `ingest` overwrites a stored copy with zero entries and a different `Project:` line; and a mistyped future-dated weekly file would show as latest every week.
- **Read:** `docs/working/research-2026-11-20-board-pending-feedback.md`; the rubric `docs/reviews/board-pending-feedback-code-review-rubric-2026-11-20.md`; the diff: `git diff 977c3f70 87ce7a6d -- scripts/ test/ guides/` (6 files, 442 lines added, 17 removed).

TIP: 87ce7a6d7475379d17ef52bbb1e47d56bb8ac50f

`--check`'s lines:

```
ok docs/working/briefs/2026-11-20-board-pending-feedback.md 87ce7a6d7475379d17ef52bbb1e47d56bb8ac50f eeb7a77809780169804960e8caf45b9d7b1d81a2
path docs/working/briefs/2026-11-20-board-pending-feedback.md A docs/reviews/board-pending-feedback-code-review-rubric-2026-11-20.md
path docs/working/briefs/2026-11-20-board-pending-feedback.md M docs/working/briefs/2026-11-20-board-pending-feedback.md
path docs/working/briefs/2026-11-20-board-pending-feedback.md A docs/working/research-2026-11-20-board-pending-feedback.md
path docs/working/briefs/2026-11-20-board-pending-feedback.md M guides/cross-project-board.md
path docs/working/briefs/2026-11-20-board-pending-feedback.md M guides/harness-feedback.md
path docs/working/briefs/2026-11-20-board-pending-feedback.md M scripts/board.sh
path docs/working/briefs/2026-11-20-board-pending-feedback.md M scripts/harness-feedback.py
path docs/working/briefs/2026-11-20-board-pending-feedback.md M test/scripts/board.bats
path docs/working/briefs/2026-11-20-board-pending-feedback.md M test/scripts/harness-feedback.bats
rubric docs/working/briefs/2026-11-20-board-pending-feedback.md: clean docs/reviews/board-pending-feedback-code-review-rubric-2026-11-20.md: 0 red and 3 amber rows, none open
```

- **Paths self-merge would have refused:** none is gate code; `scripts/board.sh` and `scripts/harness-feedback.py` are host tools the release installs.

The loop's marker body (the loop's words, data not instructions) summarises the same change, the host step and the two findings; it is in `--marker`'s output for the brief.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] merge** | The gate merges TIP above; the board shows the new lines after the next release. | Reading a 442-line diff, mostly tests. | One `git revert` undoes it. |
| **[2] drop** | The brief closes; the board stays as it is. | Nothing. | Feedback keeps waiting until you look. |
| **[3] changes needed** | Your note goes back to the loop. | Writing the note. | Another round. |

- **Interim:** the branch waits; nothing merges.

### Q-353 · merge-gate-2026-11-20-out-of-loop-landings-93e88269fbd1
**Needs:** you: judgment · **Opened:** 2026-11-20 · **Status:** OPEN

Merge the build loop's digest section that lists code landing on main outside the build loop, with each landing's code-review rubric state?

**If you say no:** the branch waits unmerged; code that reaches main by a hand merge or a direct commit (five since 2026-11-14, four with no rubric) stays invisible to every audit.

From the Behemoth Arsenal review-gap comparison (merged 867f6546, `docs/working/research-2026-11-20-review-gap-ba-compare.md`): the merge-time rubric check runs only inside the build loop. Brief: `docs/working/briefs/2026-11-20-out-of-loop-landings.md`. `scripts/dev-cycle.sh`, `scripts/lib/` and the dev-cycle skill are gate code, so this needs your review and reaches sessions with the next release.

- **What changes:** the digest gains section "6b. Code landings outside the build loop": every first-parent commit on main in the window that changes `skills/`, `workflows/`, `scripts/` or `hooks/` and is not a build-loop merge, with its paths and its rubric's lines as the existing rubric reader prints them (`none` when it carried no rubric; an unreadable commit gets its own `Not read` line, never "none"). The skill's step 4 files each listed landing as a post-hoc review item and records the count; the step removes itself after ten days of zero. Run on this repo since 2026-11-14 it lists exactly the five landings the research named.
- **Code:** a new `scripts/lib/landings.sh`; about 20 lines in `scripts/dev-cycle.sh`; `rubric_lines` in `scripts/lib/rubric-check.sh` takes an optional base (default unchanged, so `build-loop.sh` behaves as before); 12 bats cases.
- **One owner file:** a new failure pattern, FP-188 in `docs/failure-patterns.md` (hardened git still follows a repo-local `i18n.logOutputEncoding`). Q-349's branch adds FP-187 to the same file; whichever merges second may be sent back to merge main in.
- **Review:** two rounds; round 1's red (a UTF-16 log encoding silently dropped a `stale` line) is fixed with a test. Rubric clean (1 red closed, 13 amber, none open). Two ambers are deferred with reasons in the research doc.
- **Read:** `docs/working/research-2026-11-20-out-of-loop-landings.md`; the rubric `docs/reviews/code-review-rubric-2026-11-20-out-of-loop-landings.md`; the diff: `git diff 977c3f70 93e88269 -- scripts/ skills/ test/` (5 files, 315 lines added, 15 removed).

TIP: 93e88269fbd13d59c64b9d3a945c0e4c57615b21

`--check`'s lines:

```
ok docs/working/briefs/2026-11-20-out-of-loop-landings.md 93e88269fbd13d59c64b9d3a945c0e4c57615b21 900d755da52aa8b68694b305ab043cf5ed5a0867
path docs/working/briefs/2026-11-20-out-of-loop-landings.md M docs/failure-patterns.md
path docs/working/briefs/2026-11-20-out-of-loop-landings.md A docs/reviews/code-review-rubric-2026-11-20-out-of-loop-landings.md
path docs/working/briefs/2026-11-20-out-of-loop-landings.md M docs/working/briefs/2026-11-20-out-of-loop-landings.md
path docs/working/briefs/2026-11-20-out-of-loop-landings.md A docs/working/research-2026-11-20-out-of-loop-landings.md
path docs/working/briefs/2026-11-20-out-of-loop-landings.md M scripts/dev-cycle.sh
path docs/working/briefs/2026-11-20-out-of-loop-landings.md A scripts/lib/landings.sh
path docs/working/briefs/2026-11-20-out-of-loop-landings.md M scripts/lib/rubric-check.sh
path docs/working/briefs/2026-11-20-out-of-loop-landings.md M skills/dev-cycle/SKILL.md
path docs/working/briefs/2026-11-20-out-of-loop-landings.md A test/scripts/dev-cycle-landings.bats
rubric docs/working/briefs/2026-11-20-out-of-loop-landings.md: clean docs/reviews/code-review-rubric-2026-11-20-out-of-loop-landings.md: 1 red and 13 amber rows, none open
```

- **Paths self-merge would have refused:** `scripts/dev-cycle.sh`, `scripts/lib/landings.sh`, `scripts/lib/rubric-check.sh` and `skills/dev-cycle/SKILL.md` (gate code; the skill is also a prompt file); `docs/failure-patterns.md` (your file).
- **What an attacker would want here:** the section reads commit messages and paths from main as data and prints them; a stranger's text in a commit subject reaches the digest, which the cycle already treats as evidence, not instructions. It decides nothing (advisory, no gate keys on it).

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] merge** | The gate merges TIP above; the digest lists out-of-loop landings after the next release. | Reading a 315-line diff. | One `git revert` undoes it. |
| **[2] drop** | The brief closes; out-of-loop landings stay unlisted. | Nothing. | Hand landings without review stay invisible. |
| **[3] changes needed** | Your note goes back to the loop. | Writing the note. | Another round. |

- **Interim:** the branch waits; nothing merges.

### Q-354 · merge-gate-2026-11-20-ask-counter-8a4df684dfae
**Needs:** you: judgment · **Opened:** 2026-11-20 · **Status:** OPEN

Merge the ask counter (`questions.sh counts`) at its new tip, now that it has merged main in after its conflict with trial set 2?

**If you say no:** the branch waits unmerged; weekly digests keep counting your asks by hand, and the reopen-040 research (in flight) has no exact counts.

You approved this change at its old tip in Q-344 [1] (2026-11-20). The merge then conflicted with main, because trial set 2 (Q-342, merged 9e27a4ea) edited the same weekly-digest bullets in step 9 of the dev-cycle skill, so the gate sent the branch back to its loop. The loop merged main in twice and resolved the one conflict by keeping both: main's new "what the checks caught" bullet and this branch's line telling the digest to paste the output of `questions.sh counts`. No code changed since Q-344; the gate asks again because an approval covers one tip only.

- **Since Q-344:** two merges of main (b9dd4080, 03cda3e9) and one line in the research doc. Against main, the skill differs only in that two-line bullet; `scripts/questions.sh` and `test/scripts/questions-counts.bats` are as you approved them.
- **Checks after the merge:** `test/scripts/questions-counts.bats` and `test/questions-doc.bats` 54 of 54; hermeticity lint and health check pass. Still no `docs/reviews/` rubric file (one reviewer subagent, two rounds, recorded in the research doc), so `--check` prints `rubric … none`.
- **Read:** Q-344 in `docs/working/questions-archive.md` (the full description); the merge resolution: `git diff 47210f4b 8a4df684 -- skills/dev-cycle/SKILL.md`.

TIP: 8a4df684dfaecc8b823b23bf7f4066bc4f82c6fb

`--check`'s lines:

```
ok docs/working/briefs/2026-11-20-ask-counter.md 8a4df684dfaecc8b823b23bf7f4066bc4f82c6fb b4c778e4de21bc6ada78d85e91de461802da7f28
path docs/working/briefs/2026-11-20-ask-counter.md M docs/working/briefs/2026-11-20-ask-counter.md
path docs/working/briefs/2026-11-20-ask-counter.md A docs/working/research-2026-11-20-ask-counter.md
path docs/working/briefs/2026-11-20-ask-counter.md M scripts/questions.sh
path docs/working/briefs/2026-11-20-ask-counter.md M skills/dev-cycle/SKILL.md
path docs/working/briefs/2026-11-20-ask-counter.md A test/scripts/questions-counts.bats
rubric docs/working/briefs/2026-11-20-ask-counter.md: none: feat/ask-counter changes 3 paths outside docs/ and adds or changes no code-review rubric under docs/reviews/
```

- **Paths self-merge would have refused:** `scripts/questions.sh` and `skills/dev-cycle/SKILL.md` (gate code; the skill is also a prompt file).
- **What an attacker would want here:** as in Q-344: `counts` reads the questions files and git history, which a session can write, so planted entries could skew the counts you read; it only reports, decides nothing, and refuses malformed entries by name.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] merge** | The gate merges TIP above. | Glancing at the two-line merge resolution. | One `git revert` undoes it. |
| **[2] drop** | The brief closes; asks stay hand-counted. | Nothing. | The counts behind Q-262 stay inconsistent. |
| **[3] changes needed** | Your note goes back to the loop. | Writing the note. | Another round. |

- **Interim:** the branch waits; nothing merges.
