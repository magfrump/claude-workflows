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
| `agent` | Mechanical. Should not be here long. |
| `trigger` | Not a question yet — a condition being watched. Costs you nothing. |
| `deferred` | Scheduled behind an event that has not happened. |

Maintained by `scripts/questions.sh` (`check` · `index` · `archive` · `next-id` · `open`).
The index below is generated — edit entries, not the table.

## Index

<!-- index:start -->
| ID | Needs | Question | Opened |
|---|---|---|---|
| [Q-103](#q-103--dev-cycle-build-loop-policy) | you: judgment | The build-loop handoff is built: may build loops in claude-workflows land their own branches through the ga... | 2026-10-01 |
| [Q-149](#q-149--self-merge-never-scope) | you: judgment | How wide should this repo's `Self-merge never:` line be: every directory that takes effect without a releas... | 2026-10-14 |
| [Q-150](#q-150--build-loop-c1-questions-writer) | you: judgment | Should the orchestrator stay the only writer of the questions files, with build loops carrying their questi... | 2026-10-14 |
| [Q-151](#q-151--build-loop-c2-blocked-slot) | you: judgment | Does a blocked build loop give up its slot while it waits for your answer? (Plan C2.) | 2026-10-14 |
| [Q-152](#q-152--build-loop-c3-blocked-wait) | you: judgment | When every thread is blocked on you, should the orchestrator loop keep polling, or stop until you restart i... | 2026-10-14 |
| [Q-153](#q-153--build-loop-c4-merged-branch-deletion) | you: judgment | May the dev cycle delete merged branches without asking, which your global instructions forbid today ("dele... | 2026-10-14 |
| [Q-155](#q-155--constraints-doc-missing) | you: judgment | This repo has no `docs/constraints.md`, so the orchestrator dispatches no build loop here: write one now, o... | 2026-10-14 |
| [Q-163](#q-163--merge-gate-fix-q145-ancestor-vanish-c035f2e77f8c) | you: judgment | Merge `fix/q145-ancestor-vanish` at c035f2e77f8c083156b397fb32e164dd17cc6b44? It changes gate code (`script... | 2026-10-14 |
| [Q-164](#q-164--merge-gate-feat-build-loop-u5-7c91b97455db) | you: judgment | Merge U5, the build-loop handoff's last unit (`feat/build-loop-u5` at 7c91b97455db9fba1b155a2bb866abf6b86f1... | 2026-10-14 |
| [Q-165](#q-165--branch-verify-approach) | you: judgment | How should a branch's container config be verified on the host without installing it over main (roadmap Now... | 2026-10-15 |
| [Q-166](#q-166--staged-run-counts-as-live-verify) | you: judgment | If Q-165 picks [1], [2] or [3], does a passing staged run (main's launcher on the staged merge tree) count ... | 2026-10-15 |
| [Q-170](#q-170--decision-015-isolation-rerun) | you: judgment | Q-105 [3] asked for decision 015's step 4 (Docker vs podman vs other) to be re-run as a divergent design. T... | 2026-10-15 |
| [Q-171](#q-171--q168-landing-at-cap) | you: judgment | Q-168 (`fix/q096b-exit-scan-remote-names`, 75d08a94, stacked on Q-096) used its 3 review iterations. The fi... | 2026-10-15 |
| [Q-172](#q-172--exit-scan-parity-boundary) | you: judgment | How much host-git parity should the exit scan chase? It grew from 761 to 1,364 lines in 18 days. Every revi... | 2026-10-15 |
| [Q-174](#q-174--q106-iteration-4-gate) | you: judgment | Q-106 [2] is built (`feat/q106-host-settings-merge`, c6d7544f, built on an earlier `merge/ready-2026-10-15`... | 2026-10-15 |
| [Q-175](#q-175--q106-merge-program-gate-coverage) | you: judgment | Q-106 moved the settings merge jq into `hooks/lib/wiring-merge.jq`, which is outside `live-verify-gate.sh`'... | 2026-10-15 |
| [Q-179](#q-179--row-66-router-uptake-verdict) | you: judgment | Log row 66's three-cycle window has closed. Its trigger was "multi-file merges to main still land without p... | 2026-10-15 |
| [Q-084](#q-084--q076-live-checks) | you: terminal | Q-076 (`cc-push`, the exit scan) was verified only with bats: stubbed docker and local-path remotes, on git... | 2026-09-27 |
| [Q-156](#q-156--image-lag) | you: terminal | Cut a release: rebuild and bless the image from main once `feat/build-loop-u5` has merged, so the installed... | 2026-10-14 |
| [Q-162](#q-162--merges-and-cleanup-2026-10-14) | you: terminal | This session cannot merge into main (the auto-mode classifier refuses it as a shared-resource write), so fi... | 2026-10-14 |
| [Q-167](#q-167--post-install-host-probes) | you: terminal | After Q-162's paste lands, run `./devcontainer-config/install.sh` in your host checkout (review the diff it... | 2026-10-15 |
| [Q-169](#q-169--q117-spike-paste) | you: terminal | Run only if Q-165 is answered [1], [2] or [3], after Q-162's paste has landed the doc on main. It live-veri... | 2026-10-15 |
| [Q-176](#q-176--q092-deny-matcher-live-check) | you: terminal | Q-092 removes the auto-approve hook's own deny reader, so for quoted, backslashed or compound spellings, wh... | 2026-10-15 |
| [Q-079](#q-079--canon-instance-proposal-filter) | agent | Design, per Q-072, (a) a script that turns a commit or commit range into a canon instance, and (b) the high... | 2026-09-27 |
| [Q-092](#q-092--drop-hook-deny-reader) | agent | Per Q-082's answer (`permissions.deny` beats a hook `allow`), remove the Bash deny reader from `hooks/auto-... | 2026-09-28 |
| [Q-096](#q-096--exit-scan-insteadof-target) | agent | The exit scan records a `url.<base>.insteadOf` / `pushInsteadOf` base but never the URL it rewrites to, inc... | 2026-09-28 |
| [Q-097](#q-097--exit-scan-older-routes) | agent | The Q-094 review documented two older Medium routes the exit scan does not see, both now under the guide's ... | 2026-09-28 |
| [Q-108](#q-108--decision-037-stale-lines) | agent | Decision 037 has two stale lines. Line 58 says "035's still-pending regex", but the regex landed in addae61... | 2026-10-02 |
| [Q-110](#q-110--health-check-not-run-undercount) | agent | In one `scripts/health-check.sh` run (2026-10-02, main at 188e0a7d), the test runner printed `NOT RUN: 50 r... | 2026-10-02 |
| [Q-125](#q-125--build-cc-isolated-sandbox) | agent | Implement Q-124 [1] as an RPI unit. Add a seccomp profile file: Docker's default with `unshare` and `clone`... | 2026-10-07 |
| [Q-147](#q-147--q089-loop-split-source-guard) | agent | Q-089 unit A's review-fix loop ran a 4th iteration before recording a cap decision. It is now recorded as `... | 2026-10-14 |
| [Q-160](#q-160--implement-q104-per-iteration-cap) | agent | Log row 62's trigger fired again: units grew during review from 102 to 842 code lines (581d41d8), 157 to 60... | 2026-10-14 |
| [Q-168](#q-168--q096b-remote-names-unit) | agent | Q-096's iteration 2 found that the exit scan parses remote names and legacy `remotes/`/`branches/` files mo... | 2026-10-15 |
| [Q-180](#q-180--harden-and-repin-host-pastes) | agent | The landing review of the 0357 cycle branch (Q-178) stopped at its 3-iteration cap with only amber and advi... | 2026-10-15 |
| [Q-067](#q-067--regenerate-skill-eval-reports) | deferred | When should the skill eval reports be regenerated, so that the 50 `@needs-reports` suites constrain the cur... | 2026-09-26 |
| [Q-098](#q-098--global-allowlist-after-sandbox) | deferred | Ship a global `permissions.allow` in `hooks/wiring.json` once cc-isolated has a Bash sandbox (Q-088). Branc... | 2026-09-28 |
| [Q-173](#q-173--exit-scan-split-groups) | deferred | Q-168's final pass split off four groups, each shown end to end (exit scan returns 0, then a host git comma... | 2026-10-15 |
| [Q-177](#q-177--q092-merge) | deferred | When Q-176 is answered: merge Q-092's two units, `fix/q092a-drop-deny-option` (d27a3891), then `fix/q092-dr... | 2026-10-15 |
| [Q-074](#q-074--failure-pattern-writer-trigger) | trigger | After the Q-018 backfill (164 entries), `docs/thoughts/failure-patterns.md` has gained 1 entry across about... | 2026-09-26 |
| [Q-161](#q-161--revive-hermeticity-layer2-after-q125) | trigger | When Q-125's sandbox merges (bwrap in the cc-isolated image), decision 017's T2 fires: revive hermeticity l... | 2026-10-14 |
<!-- index:end -->

## Open

### Q-179 · row-66-router-uptake-verdict
**Needs:** you: judgment · **Opened:** 2026-10-15 · **Status:** OPEN

Log row 66's three-cycle window has closed. Its trigger was "multi-file merges to main still land without pr-prep's `← carried from RPI` line or a committed code-review rubric". Over the window, 4 of 45 multi-file merges since 2026-10-02 had neither: 188e0a7d, 52053432, b8807e76 and 0fbf9742, all small fixes from 10-02 to 10-06. None of the 41 since then lacks both. Taken alone, the RPI line is missing on 19 of 45 merges, but 15 of those 19 committed a rubric. Does row 66's decision stand?

- **Why it's yours:** the trigger, read literally, fired (4 > 0), and it reopens a choice: whether selection, not discovery, is the bottleneck.
- **Read:** `docs/decisions/log.md` row 66 · roadmap Next 1 · this iteration's record, "Trigger verdicts"

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] close, routers work** | Record the tally on row 66 and move roadmap Next 1 to Done. The four misses came in the first four days | One answer | A selection problem stays hidden until another trigger catches it |
| **[2] reopen row 66** | Treat the line-alone misses (19/45) as a selection problem and open a DD on router selection | A DD review | Work on a problem the rubric numbers say is solved |

- **Blocks:** roadmap Next 1 (measure router uptake).
- **Interim:** Next 1 carries the cycle-3 tally and stays open. Row 66 is unchanged, because decision records are outside the cycle's writes.

### Q-162 · merges-and-cleanup-2026-10-14
**Needs:** you: terminal · **Opened:** 2026-10-14 · **Status:** OPEN

This session cannot merge into main (the auto-mode classifier refuses it as a shared-resource write), so finished branches wait for you. Paste the block from `/workspace` with `main` checked out. It merges `merge/ready-2026-10-15` by its reviewed tip, a760a5e5 (a branch name can move; a hash cannot, once the paste has checked that no replace refs exist), then deletes the twelve build-loop branches already merged into main, along with their worktrees. That branch is main (as of b279a2ba) plus seven reviewed units, the branch-verify research and spike docs (`docs/branch-verify-without-install`, docs only: Q-165, Q-169), the decision-015 divergent design (`docs/dd-015-step4`, one doc: Q-170), and this cycle's record, each merged with `--no-ff`: T69, Q-110, doc drift, Q-160, Q-096, the rebuild-hint fix and the one-workspace rule. It exists because every pair of these units conflicts only in the append-only `docs/reviews/override-log.md`, and it resolves that by keeping both sides' rows. Run it before Q-163 and Q-164. Their pastes abort on a conflict, and once main moves, the loop rebuilds their merge branches.

**Not runnable yet (2026-10-15):** main has moved past this pin. After Q-178's landing of the 0357 cycle branch, merging a760a5e5 conflicts in `docs/reviews/override-log.md` (and, before it, in the questions, roadmap and idea-log files), so the paste below aborts and deletes nothing. The next cycle rebuilds `merge/ready-2026-10-15` on main, keeping both sides' appends, and replaces the hash in the paste; run it only after that.

```
cd /workspace && test "$(git branch --show-current)" = main && \
{ test -z "$(git for-each-ref refs/replace/)" || { echo "replace refs present: stop"; false; }; } && \
{ git merge --no-ff a760a5e5057ef3f0abd13145e7d945ef500b8abd -m "Merge branch 'merge/ready-2026-10-15': T69, Q-110, doc drift, Q-160, Q-096, the rebuild-hint fix, the one-workspace rule and the 2026-10-14 cycle record (override-log appends resolved)" || { git merge --abort; echo "conflict: merge aborted, nothing deleted"; false; }; } && \
for u in u3a1 u3a2 u3a3 u3b1 u3b2 u3b3 u3c u3d u4a u4b1 u4b2 u4c; do git worktree remove .claude/wt-build-loop-$u && git branch -d feat/build-loop-$u; done
```

- **Read:**
  - `fix/t69-stage-race` (4ee81106): T69 in `test/install-host.bats` failed 3 out of 3 runs alone on main b279a2ba. Its feed waited for a file the test's own `--yes` run had already left, so the tamper hit no stage. The old test fails and the new one passes 4/4. The test file is the only change.
  - `fix/q110-not-run-undercount` (f5b7e49d): the runner unsets `RUN_TESTS_NOT_RUN_FILE` after writing it. A regression test fails on the old runner. Review loop closed (`docs/reviews/code-review-rubric-2026-10-14-fix-q110-not-run-undercount.md`). Its gate went red only on the `/tmp` race Q-145 fixes; the slow suites passed 300/300. Q-110 closes once this lands.
  - `fix/doc-drift-cycle1` (c8e87a69; added 2026-10-15): the 2026-10-02 doc-drift brief. Both guides now recommend `cc-isolated --probe-only` then `cc-isolated` over a bare `devcontainer up --remove-existing-container` and say why. devcontainer-setup's claim that a recreate picks up a newer Claude Code was wrong (Docker reuses the cached layer) and is corrected. The guides index names cc-push and the exit scan, and AGENTS.md and GEMINI.md list dev-cycle. 6 files, +26/−10. Loop closed at the 3-iteration cap (`docs/reviews/code-review-rubric-2026-10-15-fix-doc-drift-cycle1.md`); the last wording fix had a narrow check, not a full pass. agents-gemini-sync 3/3.
  - `fix/q160-iteration-cap` (4a44d2f3; added 2026-10-15): Q-104 [2] is written into `workflows/review-fix-loop.md` § Size re-check. After each iteration and at pr-prep 6c the unit is re-measured; past ~800 lines (or a waiver's limit) the loop stops for a waiver, /away included, and the agent does not split the unit itself. 43 code lines. Its first loop escalated on four wording corner cases. I took the simplify option, which cut the clauses that produced them, and a narrow check passed after it (`docs/reviews/code-review-rubric-2026-10-15-fix-q160-iteration-cap.md`). Log row 62 gets a new revisit trigger the agent chose, "2+ waivers past the in-loop re-check within 14 days". Say so if you want a different one. The health check went red only on the Q-145 `/tmp` race in suites this branch does not touch.
  - `fix/q096-exit-scan-insteadof-target` (8717fd72; added 2026-10-15): the exit scan walks every URL an `insteadOf` or `pushInsteadOf` rule rewrites a remote to, your own config's remotes and rules included, and every matching rule, not only git's longest. It matches by byte. Three caps fail closed: 4 KiB per URL, 100k comparisons and 2,000 targets. Every `read` runs under `LC_ALL=C`, which also fixes an older UTF-8 hiding bug. 399 lines, under the 400 cap. Loop closed after 3 iterations and a final pass (`docs/reviews/code-review-rubric-2026-10-15-q096-exit-scan-insteadof-target.md`); the security critic's probe-confirmed bypasses in iterations 1–2 are fixed. Commits carry `Host-tool-tested: no`. Its host probe is Q-167. A family of older, loose remote-name parsing routes was split off as Q-168 and listed in the guide as a known route.
  - `fix/rebuild-hint-recreate` (47da5a4b; added 2026-10-15, built on this branch): after the firewall fails closed, the launcher's hint said a plain `cc-isolated <repo>` rebuilds, but a plain launch reuses that container and fails again (traced, with a regression test). The hint's first line is now `cc-isolated --probe-only WS && cc-isolated WS`. The copyable lines lose their trailing `# …` notes, because interactive zsh passes those as arguments and the last one becomes the workspace. "Rebuild" becomes "recreate" where the container is recreated. 131 code lines; only comments and `echo` text change in the scripts. Loop closed at the 3-iteration cap; the last fix had a narrow fact-check (rubric `docs/reviews/code-review-rubric-2026-10-15-fix-rebuild-hint-recreate.md`). 290/290 in its suites; health reds were 3 fast tests, each passing alone (the one outside the import walk, build-loop-merge's "--merge leaves main where another writer moved it", re-run 3/3 here); slow suites 300/300. Commits carry `Live-verified: no`; Q-167 holds the probe. Both scripts are in the trust manifest, so install re-blesses and each project's container is recreated once.
  - `fix/cc-isolated-one-workspace` (f6f37fad; added 2026-10-15, built on this branch): `cc-isolated` refuses, with exit 2 before any action, a second workspace, a `#` word before `--` (a pasted note) and a `--profile` value starting with `#` or `-`. Before this, `cc-isolated  # --bless` and `--profile '#' --bless` ran a bless. `--` takes one word. install.sh's "Next steps" lines lose their notes, and the `--help` and guide command references are reformatted. 260 code lines. Iteration 1 had independent critics; the closing passes were the builder's self-review after nested critics hung. An independent closing review run from the orchestrator was clean, 0 Must (`docs/reviews/independent-review-2026-10-15-one-workspace.md`): 17 claims held and ~45 crafted argv probes reached no action. Related suites 436/436 under `LC_ALL=C.UTF-8`; health reds were 3 import-walk tests, each passing alone; slow suites pass. Commits carry `Live-verified: no`; probe in Q-167 (b).
  - **Gate for the whole branch** (3fe6d6e3, 2026-10-15): the health check's fast suites had one red, build-loop-check 983, an import-walk test that passes 3/3 alone, from the race Q-145 fixes. The branch changes no gate or lib code. The slow suites, which a fast red skips, were run separately: 300/300. The tip, a760a5e5, adds after that gate the rebuild-hint and one-workspace unit merges (each ran its own gate, above), two docs-branch merges and nine cycle-record merges; it holds exactly the units listed.
- **Interim:** main's health check stays red on T69 until the merge. That red is the test, not install.sh. The rebuild and re-pin are agent work for the next cycle, together with the rest of Q-180. Do not run this entry's paste until Q-180 is done.
- **If the answer differs:** to leave a unit out, say which one and the loop rebuilds the branch without it.

### Q-163 · merge-gate-fix-q145-ancestor-vanish-c035f2e77f8c
**Needs:** you: judgment · **Opened:** 2026-10-14 · **Status:** OPEN

Merge `fix/q145-ancestor-vanish` at c035f2e77f8c083156b397fb32e164dd17cc6b44? It changes gate code (`scripts/lib/dev-cycle-read.sh`), which lands only on your approval.

- **Why it's yours:** GATE_CODE. The fix also accepts one residual the security critic asked you to confirm. A non-atomic save (delete, then re-create) of an existing instruction file, such as the global CLAUDE.md, is skipped if the gap falls exactly on find's stat; main fails closed there instead. An attacker gains nothing from this (they could edit the file anyway), and the code comment discloses it.
- **Read:** rubric `docs/reviews/code-review-rubric-2026-10-14-fix-q145-ancestor-vanish.md` on the branch. What changed: the top-level ancestor and config-dir listing uses `find -ignore_readdir_race`, retries up to 3 times, keeps a listing only if it ran with no error, and re-checks that every top is still a directory. A deterministic race test fails on main's lib and passes on the branch; five mutants fail it. Review: 3 iterations (the cap) with the security critic. The final pass found only wording items, fixed after it, and a narrow check verified them 11/11, so it is not marked "loop closed". The health check passed at 2aba4bf0. The tip adds two commits on top: FP-174 renumbered (db325bcb) and Q-110 merged in (c035f2e7), so the failure-patterns and override-log appends do not conflict. Merging this therefore also brings Q-110, a no-op if Q-162 ran first.
- **Paste for [1]:** it merges the branch alone, or `merge/u5-and-q145` at a04d9776 (both units, the override-log appends resolved) if U5 is already on main. Both are pinned by hash.

```
cd /workspace && test "$(git branch --show-current)" = main && \
{ test -z "$(git for-each-ref refs/replace/)" || { echo "replace refs present: stop"; false; }; } && \
if git merge-base --is-ancestor 7c91b97455db9fba1b155a2bb866abf6b86f1904 HEAD; then B=a04d97762518389f053c3c609a3dfcc4531d553b; else B=c035f2e77f8c083156b397fb32e164dd17cc6b44; fi && \
{ git merge --no-ff "$B" -m "Merge branch 'fix/q145-ancestor-vanish': the gate's ancestor listing survives entries that vanish mid-listing (Q-145)" || { git merge --abort; echo "conflict: merge aborted; the loop rebuilds this entry's branch against main"; }; }
```

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] merge** | The paste above. The gate stops flaking on `/tmp` churn once the image is rebuilt (Q-156, filed on `feat/build-loop-u5`; it reaches main with Q-164) | One paste | The delete-and-re-create window lets one listing miss an instruction file that a non-atomic save is rewriting |
| **[2] drop** | Branch deleted; gates keep flaking under load (3 re-runs this cycle alone) | Re-runs | Q-145's one-hour revisit trigger keeps counting |
| **[3] changes needed** | Your note goes back to a fresh loop | A note | — |

- **Blocks:** Q-145's revisit clock (re-runs this cycle: U5 2, Q-110 1).
- **Interim:** unmerged. Re-run a red gate whose log shows `find: '/tmp/…': No such file or directory`. Do not run this entry's paste until Q-180 is done.
- **If the answer differs:** [2] `git branch -D fix/q145-ancestor-vanish`.

### Q-164 · merge-gate-feat-build-loop-u5-7c91b97455db
**Needs:** you: judgment · **Opened:** 2026-10-14 · **Status:** OPEN

Merge U5, the build-loop handoff's last unit (`feat/build-loop-u5` at 7c91b97455db9fba1b155a2bb866abf6b86f1904)? It edits `skills/dev-cycle/SKILL.md` (gate code), and its review loop ended in `escalate`.

- **Why it's yours:** GATE_CODE, and the review-fix loop's iteration-4 gate. The last fix, 3718bcd0 (Q-156's paste refuses `core.attributesFile` in any repository config scope, in the reviewer's own executed check form), had no full review pass. Option [2]'s narrow check was run on 2026-10-15. The paste's exact test was executed in a throwaway repo on git 2.39.5 with the value in each place it can come from. It refused the local, worktree, included, `includeIf`-included, environment (`GIT_CONFIG_COUNT`) and empty lowercase-key cases, and passed with nothing set or a global value. One residual is by design: a global config that includes a file inside the repo reports as global and passes, and a sandbox cannot write your global config.
- **Read:**
  - The merge message `docs/working/merge-msg-build-loop-u5.md` and the rubric `docs/reviews/code-review-rubric-2026-10-14-feat-build-loop-u5.md` on the branch.
  - What it does: `docs/dev-cycle.md` describes the handoff as built, with a wider `Self-merge never:` line (Q-149 asks how wide). It adds decision-log row 72 and roadmap items (a)–(g), files Q-149..Q-156 (C1–C5, the constraints doc, the image-lag release entry), re-routes Q-103 to you, and marks the handoff brief done.
  - Size: 26 code lines outside `docs/`, 409 lines outside `docs/reviews/`.
  - Health check: red only on the Q-145 `/tmp` race (passes alone); slow suites 300/300.
  - Deferred, with an override row and a roadmap Idea: install.sh's `git archive` follows replace refs and a repository-scope `core.attributesFile` (pre-existing, decision 035's boundary). Q-156's paste refuses both for this release.
- **Paste for [1]:** it merges `merge/build-loop-u5-resolved` at 0f94bb77 (this cycle's chore branch, Q-110 and U5, with the questions, roadmap and override-log conflicts resolved; U5's reviewed tip is unchanged inside it), or `merge/u5-and-q145` at a04d9776 if Q-145 is already on main, each pinned by hash. Then Q-156's release paste.

```
cd /workspace && test "$(git branch --show-current)" = main && \
{ test -z "$(git for-each-ref refs/replace/)" || { echo "replace refs present: stop"; false; }; } && \
if git merge-base --is-ancestor c035f2e77f8c083156b397fb32e164dd17cc6b44 HEAD; then B=a04d97762518389f053c3c609a3dfcc4531d553b; else B=0f94bb7702073f78992b8eba25ac131473b49825; fi && \
{ git merge --no-ff "$B" -m "Merge branch 'feat/build-loop-u5': the build-loop handoff as built (U5; see docs/working/merge-msg-build-loop-u5.md)" || { git merge --abort; echo "conflict: merge aborted; the loop rebuilds this entry's branch against main"; }; }
```

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] merge** | Handoff closes; Q-149..Q-156 and Q-103 become live asks; Q-156's release puts the D6 block in the image | One paste, then the release | A defect in the unreviewed Q-156 paste fix shows when you run it. It is a refusal check, so it fails closed |
| **[2] one more narrow pass first** | Done 2026-10-15 (see Why it's yours): the check held | — | — |
| **[3] changes needed** | Your note goes back to a loop | A note | — |

- **Blocks:** Q-156 (the release), Q-103, and dispatch (Q-155: `docs/constraints.md`).
- **Interim:** unmerged. Cycles keep running by hand. Do not run this entry's paste until Q-180 is done.
- **If the answer differs:** [2] runs on the next iteration, which then asks again.

### Q-165 · branch-verify-approach
**Needs:** you: judgment · **Opened:** 2026-10-15 · **Status:** OPEN

How should a branch's container config be verified on the host without installing it over main (roadmap Now, "Verify a branch without installing it": Q-117, Q-125/Q-130 and Q-098 wait on this)?

- **Why it's yours:** it adds a host tool that drives docker, a new trust surface, and the choice sets how the three blocked merges get unblocked.
- **Read:** `docs/working/research-branch-verify-without-install.md` and `docs/working/dd-branch-verify-without-install.md` on `docs/branch-verify-without-install` (22a4bb1f; the branch tip, d25254da, adds the spike doc and its review commits). What they found:
  - No check needs main's install, but install.sh's `agent_gate` is global, so even a second install prefix blocks while any session runs.
  - Both blocked branches are hundreds of commits behind main and would roll back Q-089's host-tools split if installed as they are.
  - Container and volume names are keyed on the workspace path. A `--probe-only` of `~/claude-workflows` therefore recreates the harness's own container.
  - Main's launcher loads its code only from its own directory. So main's `cc-isolated` run with `CLAUDE_DEVC_CONFIG_DIR` set to a staged merge tree, on a scratch clone, runs no branch code on the host and installs nothing.
  - The gap: a branch's `devcontainer.json` (`initializeCommand`, `runArgs`, `mounts`) reaches docker without an install diff, so it needs an allowlist refusal plus a diff stop.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] `cc-verify` host tool** (recommended, 70%) | A hand spike on Q-117 first, then a ~300-line `devcontainer-config/cc-verify.sh` (a host tool, so it carries a `Host-tool-tested:` trailer) | One paste for the spike, then one command per verify | A second host script assumes the launcher's layout; a test pins that assumption |
| **[2] `cc-isolated --verify`** | The same behaviour inside the launcher | The same per verify, but the launcher change first needs its own install and probe | It grows a 944-line enforcement file and is slower to unblock |
| **[3] Hand paste only** | Stop after the spike and reuse the paste for each verify | A ~30-line paste per verify, with teardown and the diff check done by hand | Teardown or the `devcontainer.json` check gets skipped one day |
| **[4] Park** | Keep Q-117, Q-125 and Q-098 unmerged | Nothing | The egress fix and the sandbox stay off indefinitely |

- **Blocks:** the roadmap Now item "Verify a branch without installing it", and through it Q-125's merge, Q-098 and `fix/egress-dnsmasq-ipset`.
- **Interim:** the spike paste (step one of [1], and safe under [2] and [3]) is written and reviewed: Q-169.
- **If the answer differs:** [4] drops the spike; [2] reuses the spike's findings for the launcher change.

### Q-166 · staged-run-counts-as-live-verify
**Needs:** you: judgment · **Opened:** 2026-10-15 · **Status:** OPEN

If Q-165 picks [1], [2] or [3], does a passing staged run (main's launcher on the staged merge tree) count as the live-verified host run that Q-117 and Q-125 need before merging?

- **Read:** `docs/working/dd-branch-verify-without-install.md` on `docs/branch-verify-without-install`.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Yes** | Merge on a passing staged run, with the trailer `Live-verified: <hash> — cc-verify of tree <id>`. Main's post-merge install re-probes on first launch anyway | Nothing extra | A difference between the staged and installed config shows only at that first launch; revert as in Q-125's rollback plan. For Q-125 that difference is real: a staged run never executes its `install.sh` `PAYLOAD` or `cc-isolated.sh` `enforcement_files()` changes (Q-117 changes only `init-firewall.sh`) |
| **[2] Yes, plus a post-merge check** | As [1], but Q-117 and Q-125 close only after main's first post-merge `--probe-only` passes | One probe at your next normal install | Little: the entries just stay open a bit longer |
| **[3] No** | A staged run is evidence, not the gate; the install-over-main run stays | The blocking install you already declined | Back to the problem in Q-117's answer |

- **Interim:** [2].
- **If the answer differs:** only the closing step of Q-117 and Q-125 changes.

### Q-167 · post-install-host-probes
**Needs:** you: terminal · **Opened:** 2026-10-15 · **Status:** OPEN

After Q-162's paste lands, run `./devcontainer-config/install.sh` in your host checkout (review the diff it shows; it blesses), then run the two probes below.

**(a) The rebuild hint** (clears the rebuild-hint commits' `Live-verified: no`): the install's bless output should show `Verified live:  NO — a bless is a review, not a test.` followed by `Next: cc-isolated --probe-only <repo>` alone on its line, and `cc-isolated --list` should show `Blessed config <hash> — verified live: NO (run: cc-isolated --probe-only <repo>)`. Then:

```
cc-isolated --probe-only ~/code/ANY-REPO && cc-isolated --list | grep -i 'verified live'
```

Paste back the hash `--list` prints, for a `Live-verified: <hash>` record.

**(b) The one-workspace rule** (clears its `Live-verified: no`). Paste these lines as written in default zsh; each of the first three must print an ERROR and `exit=2` with nothing done:

```
cc-isolated ~/code/a ~/code/b; echo "exit=$?"
cc-isolated --list  # registered projects; echo "exit=$?"
cc-isolated --profile '#' --bless; echo "exit=$?"
cc-isolated --probe-only -- ~/code/ANY-REPO
```

The last must pass its probe; then `cc-isolated --list` shows it verified live.

**(c) Q-096's exit scan:** a planted pre-receive hook in a repository that a remote is rewritten to must be caught.

```
T="$(mktemp -d)" && git init -q "$T/proj" && cd "$T/proj" && git -c user.name=p -c user.email=p@p commit -q --allow-empty -m init && git remote add o https://example.invalid/repo && git config "url.$T/proj/mirror-.insteadOf" https://example.invalid/ && git init -q --bare "$T/proj/mirror-repo" && cc-isolated "$T/proj"; echo "cc-isolated exit=$?   (expect 3, naming hook …/mirror-repo/hooks/pre-receive)"; cd "$HOME" && rm -rf "$T"
```

Step 2, inside the session at Claude's prompt, then exit the session:

```
! printf '#!/bin/sh\necho planted\n' > mirror-repo/hooks/pre-receive && chmod +x mirror-repo/hooks/pre-receive
```

- **Interim:** bats-only verification (193/193), as the commits' `Host-tool-tested: no` trailers say. Do not run this entry's paste until Q-180 is done.
- **If the answer differs:** any exit but 3, or a warning that does not name the hook, is a bug in Q-096; paste the output.

### Q-168 · q096b-remote-names-unit
**Needs:** agent · **Opened:** 2026-10-15 · **Status:** OPEN

Q-096's iteration 2 found that the exit scan parses remote names and legacy `remotes/`/`branches/` files more loosely than git, all predating Q-096. These were split off under the early split trigger. Finish `fix/q096b-exit-scan-remote-names` (3c8fbf4a, unreviewed, stacked on 013f1b3d): rebase it onto Q-096's tip, run its own research-plan-implement pass with the bypass pre-mortem, then the review loop.

- **Built 2026-10-15:** 75d08a94, stopped at the review cap; landing is Q-171, the parity boundary Q-172, the split groups Q-173. This entry closes when the branch lands.
- **Read:** 3c8fbf4a's commit message (it lists the open gaps) · the guide's "Remote names and legacy remote files, read loosely" known-route bullet · Q-097, which may absorb it
- **Interim:** a listed known route; cc-push is still the way to push.

### Q-169 · q117-spike-paste
**Needs:** you: terminal · **Opened:** 2026-10-15 · **Status:** OPEN

Run only if Q-165 is answered [1], [2] or [3], after Q-162's paste has landed the doc on main. It live-verifies `fix/egress-dnsmasq-ipset` (Q-117) without installing it. It stages main merged with the branch, runs main's installed `cc-isolated` on a scratch clone under `~/cc-verify/run-<RUN>.d/`, runs Q-117's container block, and tears everything down.

- **The paste:** the single ```bash block in `docs/working/spike-cc-verify-q117.md` (498 lines with its fences). Take it from the reviewed commit, not the working tree, and check its hash before running:

  ```
  cd ~/claude-workflows && mkdir -p ~/cc-verify && git -c core.useReplaceRefs=false show a760a5e5057ef3f0abd13145e7d945ef500b8abd:docs/working/spike-cc-verify-q117.md | awk '/^```bash$/{f=1;next} f&&/^```$/{exit} f' > ~/cc-verify/q117-spike.txt && sha256sum ~/cc-verify/q117-spike.txt
  ```

  Run it on the host, in your checkout (replace `~/claude-workflows` if it lives elsewhere), not in a container. The hash must be `032cc9a81e4e1c9266ec3ad3b5fe7053d9876eb21f5ffa7f0a35f2ccfed4afb7`; otherwise stop. Then paste the contents of `~/cc-verify/q117-spike.txt` (under the `denyWrite` below), editing only its last line, the checkout path. Its first output line must be `script sha256 a65f4c30ba1b8907`; any other value means it is not the reviewed block, so press Ctrl-C.
- **Before you run it:** add `~/cc-verify` to your agents' sandbox `denyWrite`, or run it while no agent that can write `~/cc-verify` is running. A same-uid writer there is the one threat left open (residuals A17 and A18: it could redirect the stage extraction's writes, or edit the stage into host code execution during the build).
- **Expect:** up to about an hour (image build, then Q-117's wait of up to 45 min for a pool rotation). Exit 0 with `RESULT Q-117 pass` and five `CHECK … ok` lines is a pass; 2 means no rotation was seen, so rerun later; 1 is a failure or refusal, named by step. On an interrupted teardown, rerun the same block with `--clean` as its last argument.
- **Paste back:** the `script sha256` line, the `RESULT`, `CHECK`, `NOTE`, `TEARDOWN` and `REFUSED:` lines.
- **Read:** the doc's step table (every command cited to file:line), "Not verified" (8 items only this run can show) and "Residual risks"; rubric `docs/reviews/code-review-rubric-2026-10-15-cc-verify-spike.md` (CONDITIONAL PASS: 2 iterations, 3 narrow passes, matrix 27/27 in a stub harness).
- **Interim:** Q-117 stays unverified; the egress fix stays unmerged. Do not run this entry's paste until Q-180 is done.
- **If the answer differs:** if Q-165 is [4], this entry is dropped.

### Q-170 · decision-015-isolation-rerun
**Needs:** you: judgment · **Opened:** 2026-10-15 · **Status:** OPEN

Q-105 [3] asked for decision 015's step 4 (Docker vs podman vs other) to be re-run as a divergent design. The re-run recommends keeping Docker: none of the 6 session-breaking fixes since 2026-07-13 was Docker's. Which outcome?

- **Why it's yours:** it amends a decision record's revisit trigger, and [A] adds a merge refusal for boundary changes.
- **Read:** `docs/working/dd-015-step4-isolation-mechanism.md` (lands with Q-162). Motive test: of the 6 fixes, 4 came from this repo's own boundary changes, 1 from the devcontainer CLI's path handling and 1 from kernel netfilter, so no runtime swap removes the cause. 4 of the 6 merged without a live-container run, and since 2026-09-09 87 of 116 `devcontainer-config/` commits carry `Live-verified: no`. 18 candidates, 5 scored. Confidence 80%. §6 holds the exact amendment text for 015's trigger, which splits runtime-caused from boundary-layer breakage.
- **Also tell me (V1, the one fact that could change the answer):** the dates and reasons you fell back to running sessions on the host since July (Q-121), because Docker Desktop incidents leave no commit.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[A] Keep Docker; amend 015; verify-before-merge** (recommended) | Apply §6's amendment now. Once `cc-verify` exists (Q-165), boundary merges without a `Live-verified:` hash are refused unless overridden with a logged reason | Approve one text amendment now | If Desktop is breaking sessions off the record, the runtime half of the trigger fires; podman is the named fallback |
| **[B] Keep Docker; amend 015 only** | The amendment, with no merge refusal: churn is watched, not prevented | Approve one text amendment | The boundary half of the trigger keeps firing and routes back to [A]; sessions break meanwhile |
| **[C] Spike rootless Docker or podman first** | One host paste covering the doc's checks V2–V7 and V12, then decide | One ~30-minute paste and reading the results | Spends a session on a runtime that removes none of the recorded causes |
| **[D] Sidecar egress proxy** | Keep Docker; replace the in-container netfilter/DNS stack with an internal network and a proxy container | Reviewing a multi-day boundary rewrite plus its live run | A large unverified boundary change, the very thing behind 4 of the 6 breakages |

- **Blocks:** nothing urgent. 015's trigger stays as it is until answered.
- **Interim:** [B] in substance: nothing changes, and the cycle reads 015's trigger as the DD's split.
- **If the answer differs:** [C] or [D] become roadmap items; the amendment is dropped.

### Q-171 · q168-landing-at-cap
**Needs:** you: judgment · **Opened:** 2026-10-15 · **Status:** OPEN

Q-168 (`fix/q096b-exit-scan-remote-names`, 75d08a94, stacked on Q-096) used its 3 review iterations. The final pass found 4 reds; 3 predate the unit and 1 is new counting that is no regression. The blocker for merging is that the scan's header and the guide still claim git parity it lacks, plus one incomplete performance fix (A17). How should it land?

- **Why it's yours:** a 4th iteration passes the review-fix loop's iteration-4 gate.
- **Read:** rubric `docs/reviews/code-review-rubric-2026-10-15-q168-exit-scan-remote-names.md` on the branch. Fixed and tested against git 2.39.5:
  - remote names counted only from what git reads for that repo;
  - your own `pushDefault`/`branch.*` walked;
  - legacy files read byte-wise, through symlinked dirs, failing closed on a NUL byte or a line over 8 KiB;
  - `file://` decoded;
  - every local-path form git tries, `gitdir:` files included, walked.

  13 new tests, each failing before its fix; 206/206 pass. 562 changed lines, over the 400 cap and under the 800 stop. Health check: only Q-145-race reds, which pass alone; slow suites 300/300.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] One more doc-and-A17 iteration** (recommended) | Iteration 4: correct the parity wording, add the split routes to the guide's known routes, key the include hash on the real path, run one confirming pass, then add it to Q-162's branch | One answer | Scope grows if the confirming pass finds more |
| **[2] Hold until the split units land** | Leave it unmerged until Q-173's groups are fixed | None now | Fixed families wait on harder ones, and the branch goes stale |
| **[3] Merge as is** | Land 75d08a94 with the reds listed | None | The guide tells you parsing matches git when it does not |

- **Interim:** unmerged; the open families are known routes, and cc-push is still the safe way to push.
- **If the answer differs:** [2] parks the branch; [3] needs only a merge-message note.

### Q-172 · exit-scan-parity-boundary
**Needs:** you: judgment · **Opened:** 2026-10-15 · **Status:** OPEN

How much host-git parity should the exit scan chase? It grew from 761 to 1,364 lines in 18 days. Every review pass of Q-094, Q-096 and Q-168 found new looser-than-git families, mostly bugs that predate the pass, each confirmed end to end with a planted hook running.

- **Why it's yours:** it sets the scan's threat-model boundary and how much review attention the scan keeps consuming.
- **Read:** Q-168's rubric (tech-debt T4) · the guide's "Known routes it does not see" · cc-push, the route that runs no git in the checkout

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Keep closing families one unit at a time** | Q-173's groups each become a unit, and so does whatever their reviews find | Review attention per unit, open-ended | Growth with no end; each pass finds more |
| **[2] Set a boundary** | Close only routes that need no state planted before launch; list the rest as known routes; the guide says to push with cc-push | One decision now | Routes that need launch-time state stay open by design |
| **[3] Re-architect** | One "resolve like git" layer plus one reader for `gitdir:`/commondir files, then re-audit | One larger unit | The tech-debt critic doubts a rewrite stops new families |

- **Blocks:** Q-173.
- **Interim:** no new exit-scan family units start; Q-096 lands as reviewed.
- **If the answer differs:** only what Q-173 becomes changes.

### Q-173 · exit-scan-split-groups
**Needs:** deferred · **Opened:** 2026-10-15 · **Status:** OPEN

Q-168's final pass split off four groups, each shown end to end (exit scan returns 0, then a host git command runs a planted hook): (1) the relative-path base per working tree: R3 (a `--separate-git-dir` repo), **R6 (High: a relative `core.hooksPath` in a linked worktree inside the checkout is never walked)**, A14, A16; (2) `@[` in local paths (R4); (3) `gitdir:` include parity (R5, A15, T3); (4) one reader for `gitdir:`/commondir files (T1; a container-form `.git` ending in CR). Waits on Q-172; R6 is the first to build under any option, unless [2] puts it outside the boundary.

- **Read:** Q-168's rubric, the R3–R6 and A14–A17 rows
- **Interim:** documented as known routes once Q-171's iteration lands; cc-push stays the safe path.

### Q-174 · q106-iteration-4-gate
**Needs:** you: judgment · **Opened:** 2026-10-15 · **Status:** OPEN

Q-106 [2] is built (`feat/q106-host-settings-merge`, c6d7544f, built on an earlier `merge/ready-2026-10-15` commit, 184396ea; it is not in the ready branch Q-162 merges). install.sh's host target now runs the container's provenance merge on your `~/.claude/settings.json`, inside its review and gated by your y. Its review loop stopped at the iteration-4 gate with one Medium open. Authorize a 4th iteration?

- **Why it's yours:** the iteration-4 gate, and the change writes your host hardening.
- **Read:** rubric `docs/reviews/code-review-rubric-2026-10-15-feat-q106-host-settings-merge.md` and plan `docs/working/plan-q106-host-settings-merge.md` (pre-mortem) on the branch.
  - **One merge program:** `hooks/lib/wiring-merge.jq`, shared with `link-claude-home.sh` and run with an empty HOME and environment.
  - **Review before your y:** a `settings.json:` diff plus a by-name UNWIRE/ADD/REMOVE list.
  - **Refuses:** a symlinked, unreadable or non-object file, a missing jq, any `wiring.json` hook that is not `bash|python3 {{CLAUDE_DIR}}/hooks/<path>`, or a file that changed since the review.
  - **Recovery:** a backup is taken before the rename, with the mode kept.
  - **Also closes Q-108:** 037's stale lines are corrected, and the "035's regex lands" trigger is discharged.
  - **Size:** 561 code lines (under 800).
  - **Tests:** T93–T103 11/11, link-claude-home 16/16. The health check's only reds are the Q-145 race, each passing alone; slow suites pass.
  - **S3-F1 (open, Medium, low confidence):** the wiring shape check covers each hook but not the group around it. An object-valued `hooks`, an object `matcher` or extra group keys would pass and be written.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Authorize iteration 4** (recommended) | Tighten the group shape (only `matcher`/`hooks`, typed), anchor the regexes with `\A…\z`, count duplicate hooks: about 20 lines, then the k=3 confirming pass, then into Q-162's branch | One later merge | Agent time spent on a check that may not matter |
| **[2] Merge as is** | Land c6d7544f with S3-F1–F3 listed in the merge message | One merge now | A hostile branch's malformed group lands in settings.json after your y; if Claude Code rejects a schema-invalid file, deny rules stop applying until it is fixed |
| **[3] Host check first** | A small paste: does Claude Code reject the whole file or skip one malformed group? The answer picks [1] or [2] | One paste | Only delay |

- **After it merges:** the branch's host verification block (in the rubric's report; it installs into a temp dir with a copy of your settings.json, never the real one) joins Q-167.
- **Interim:** unmerged; the installer keeps printing the manual-merge reminder.
- **If the answer differs:** [2] merges as is; [3] adds one terminal entry.

### Q-175 · q106-merge-program-gate-coverage
**Needs:** you: judgment · **Opened:** 2026-10-15 · **Status:** OPEN

Q-106 moved the settings merge jq into `hooks/lib/wiring-merge.jq`, which is outside `live-verify-gate.sh`'s `enforcement` regex. On main that jq is inline in `link-claude-home.sh`, which the regex covers (`hooks/live-verify-gate.sh:83`), so the move takes away coverage the program has today. The trust manifest still hashes it, and both installs show it in their reviews. Should the commit gate cover it?

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Accept it in the `hooks/**` class** | Same status as `wiring.json` and `guard-trusted-writes.py` | Nothing | A change to the merge program commits without a `Live-verified:` trailer, which it cannot today |
| **[2] Add it to the enforcement regex** | A small gate-code change with its test | One gate-code review | Every commit touching the program owes a container probe |
| **[3] Its own trailer** | Like `Host-tool-tested:` | A new category to maintain | More trailers to remember |

- **Interim:** [1] in name only: Q-106 is unmerged (Q-174), so nothing has lost coverage yet. The security review of this entry (`docs/reviews/security-review-2026-10-15-0357.md` F6) leans to [2].
- **If the answer differs:** [2] or [3] becomes a small unit after Q-106 lands.

### Q-176 · q092-deny-matcher-live-check
**Needs:** you: terminal · **Opened:** 2026-10-15 · **Status:** OPEN

Q-092 removes the auto-approve hook's own deny reader, so for quoted, backslashed or compound spellings, whether a denied command is stopped depends only on Claude Code's deny matcher. Main's hook stays silent on `.cred""entials.json`, `.c\redentials.json`, `git "push"` and `cat "secret"`; the branch's hook approves them (the review's MA1 names all four; the check below tries each shape). This check settles it with a throwaway hook that approves only the nine test commands below and stays silent on anything else, so every other command prompts as usual; it needs no merge. Run on the host:

```
mkdir -p ~/q092/.claude && cd ~/q092 && git init -q && jq --version && echo canary > x.q092-canary && echo secret > secret && cat > ~/q092/.claude/allow-tests.sh <<'EOF' && cat > ~/q092/.claude/settings.local.json <<'JSON' && claude --version && claude
#!/bin/sh
c=$(jq -r '.tool_input.command // empty')
printf '%s\n---\n' "$c" >> "$HOME/q092/seen.log"
case "$c" in
  'cat x.q092-canary'|'cat x.q092-ca""nary'|'cat x.q092-c\anary'|'rm -rf ./nothing-here'|'echo hi && rm -rf ./nothing-here'|'cat secret'|'cat "secret"'|'git push'|'git "push"')
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}' ;;
esac
EOF
{
  "permissions": { "deny": ["Bash(*.q092-canary*)", "Bash(rm -rf:*)", "Bash(git push:*)", "Bash(cat secret)"] },
  "hooks": { "PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "sh \"$HOME/q092/.claude/allow-tests.sh\"" } ] } ] }
}
JSON
```

It needs `jq` on the host (the paste stops at `jq --version` without it). `~/q092` is its own git repository with no remote, so a `git push` that runs pushes nothing. In that session, check that `/hooks` lists the hook. Answer **no** to any prompt for a command not on this list. Then ask Claude to run each of these one at a time, exactly as written, and note for each whether it **runs**, **prompts** or is **denied**:
1. `cat x.q092-canary` (control for the glob rule: must be denied)
2. `cat x.q092-ca""nary`
3. `cat x.q092-c\anary`
4. `rm -rf ./nothing-here` (control for the `:*` prefix rule: must be denied)
5. `echo hi && rm -rf ./nothing-here`
6. `cat secret` (control for the exact rule: must be denied)
7. `cat "secret"`
8. `git push` (control for the `:*` prefix rule: must be denied)
9. `git "push"`

Then exit, keep a copy of `~/q092/seen.log`, and `rm -rf ~/q092`, even if the session errored. Also run `claude --version` inside any `cc-isolated` session: the hook runs in the container, so the result counts for Q-092 only if the two versions match. Paste back both version lines, the nine results and `seen.log`. A result counts only if `seen.log` shows the hook saw that exact command: if Claude rewrote it (for example dropping the quotes), re-ask with the exact text. A "prompts" on 2, 3, 5, 7 or 9 means the hook did not see that spelling, so that test is void and is re-run. If a control is not denied, the whole check is void.

- **Interim:** Q-092's two branches stay unmerged (Q-177). Do not run this entry's paste until Q-180 is done.
- **If the answer differs:** any "runs" on 2, 3, 5, 7 or 9 sends Q-177 to its options; all five "denied", every control denied, `seen.log` showing each exact command and matching versions land Q-092; anything else re-runs the void tests (at the container's version, if the versions differ).

### Q-177 · q092-merge
**Needs:** deferred · **Opened:** 2026-10-15 · **Status:** OPEN

When Q-176 is answered: merge Q-092's two units, `fix/q092a-drop-deny-option` (d27a3891), then `fix/q092-drop-hook-deny-reader` (aeda94b2)?

- **Read:** both rubrics (`docs/reviews/code-review-rubric-2026-10-15-fix-q092a-drop-deny-option.md`, `…-fix-q092-drop-hook-deny-reader.md`) and the independent closing review `docs/reviews/independent-review-2026-10-15-q092b.md` on U2. The hook never emits `ask`, and tests pin its stdout, so Q-082's "deny beats a hook allow" applies to every path. The independent reviewer found no way to make the hook allow outside the allow rules, and all fail-closed cases held. Hook suite 35/35; health check passed clean. U1 had an independent clean terminal pass; U2's terminal pass was self-review, then the independent closing review (MA1: this live check, now Q-176). Sizes 413 + 451 lines.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Merge if Q-176 is all "denied"** | The loop adds both units to the ready branch | Nothing more | A spelling Q-176 did not try runs without a prompt, as in [2] |
| **[2] Q-176 shows a spelling that runs: accept it** | Merge anyway: the same class as the `.c*` glob residual; Q-125's sandbox is the real fix | One answer | A quoted credential read runs without a prompt where no sandbox exists (cc-isolated until Q-125) |
| **[3] Q-176 shows a spelling that runs: keep a quote check** | Before merging, the hook's shape allowlist refuses words containing quotes or backslashes mid-word | An enforcement-file unit | Some legitimate quoted commands prompt again |

- **Interim:** [1]'s condition; nothing merges until Q-176's result.
- **If the answer differs:** [3] adds a unit before the merge.

### Q-180 · harden-and-repin-host-pastes
**Needs:** agent · **Opened:** 2026-10-15 · **Status:** OPEN

The landing review of the 0357 cycle branch (Q-178) stopped at its 3-iteration cap with only amber and advisory items left, all in host-paste text. Fix them together with the re-pin of the ready branch that Q-162 already calls for, then review that change before any of these pastes is run.

- **Read:** rubric `docs/reviews/code-review-rubric-2026-10-15-chore-dev-cycle-2026-10-15-0357.md` (iteration 3); `docs/reviews/security-review-2026-10-15-0357-final.md` F1–F4; `docs/reviews/code-fact-check-report-2026-10-15-0357-final-r{1,2,3}.md`; `docs/reviews/tech-debt-triage-review-2026-10-15-0357-final.md` F5.
- **The work, in one unit:**
  - Rebuild `merge/ready-2026-10-15` (and `merge/u5-and-q145`, `merge/build-loop-u5-resolved`) on main, then re-pin Q-162, Q-163 and Q-164, and re-pin Q-169 to the docs branch's own commit (its file is identical at d25254da).
  - The replace-ref guard in Q-162, Q-163 and Q-164 also refuses `info/grafts` and `shallow`, as `scripts/build-loop.sh:622` and the dev-cycle skill's D6 snippet already do. A planted graft let a pinned merge pass the guard and land other content (security final F1, executed). The "a hash cannot move" wording follows.
  - The merge pastes say they run in the container's `/workspace`, not the host checkout (security final F2).
  - Q-167(b) line 3 becomes `cc-isolated --profile '#' --list`: on a launcher older than the fix, `--bless` blesses without a prompt (security final F3).
  - Q-176 creates `~/q092` with `mkdir` without `-p`, so a planted directory stops it (security final F4).
  - Wording: Q-169's "Not verified" has 12 items, not 8. Q-170's count is 88 of 116. Q-162's pre-landing conflict list adds `questions-archive.md`, and only Q-110, doc drift and Q-160 conflict with each other. The cycle-2 tally excludes cycle 1's three landings.
- **Blocks:** the pastes of Q-162, Q-163, Q-164, Q-167, Q-169 and Q-176. Each says so in its Interim.
- **Interim:** every merge paste aborts on today's main or once Q-178's landing is on main, and Q-169's extraction stops on a wrong hash, so nothing runs in the meantime.

### Q-160 · implement-q104-per-iteration-cap
**Needs:** agent · **Opened:** 2026-10-14 · **Status:** OPEN

Log row 62's trigger fired again: units grew during review from 102 to 842 code lines (581d41d8), 157 to 603 (73589cd7), 217 to 538 (dfa75374) and 392 to 570 (626dc300). Write Q-104 [2] into the process. pr-prep or the review-fix loop re-measures the unit with step 1a's command after each iteration, tolerates up to ~800 lines, and stops for a waiver past that. Amend log row 62 to point at it.

- **Read:** Q-104 in `docs/working/questions-archive.md` · `workflows/pr-prep.md` step 1a · `workflows/review-fix-loop.md` (early split trigger) · `docs/working/merge-msg-build-loop-u2a3b.md` (cites "Q-104 [2]'s ~800")
- **Interim:** applied by hand per loop (waivers Q-113, Q-120, Q-131). Nothing enforces it, so it holds only while each loop remembers.
- **Built 2026-10-15:** `fix/q160-iteration-cap` (4a44d2f3), merged by Q-162's paste. This entry closes when it lands.

### Q-161 · revive-hermeticity-layer2-after-q125
**Needs:** trigger · **Opened:** 2026-10-14 · **Status:** OPEN

When Q-125's sandbox merges (bwrap in the cc-isolated image), decision 017's T2 fires: revive hermeticity layer 2 as an in-session gate, and re-run decision 014's layer-3 per-suite confinement RPI, reconsidering its pruned candidate 15. 014 T3 has already fired: the Q-126 host probe showed bwrap starting on WSL2 under Q-125's seccomp profile.

- **Read:** `docs/decisions/014-secure-tool-guidance-layers.md` and `docs/decisions/017-polyglot-test-hermeticity.md` (Revisit triggers) · Q-126 in the archive · Q-125
- **Interim:** nothing changes until Q-125 merges. The condition: `command -v bwrap` succeeds in a cc-isolated session on main's image.

### Q-108 · decision-037-stale-lines
**Needs:** agent · **Opened:** 2026-10-02 · **Status:** OPEN

Decision 037 has two stale lines. Line 58 says "035's still-pending regex", but the regex landed in addae610 and `test/hooks/live-verify-gate.bats` ("install.sh is gated although it is not manifest-hashed") covers install.sh. Line 37 says "Q-049 is open", but Q-049 was answered on 2026-09-23. Amend both, and record that the "035's regex lands" trigger is discharged. Decision records are outside the dev cycle's in-cycle fix scope, so this is filed rather than fixed.

- **Read:** `docs/decisions/037-bare-host-copy-install.md` lines 37 and 58 · Q-106 (line 37's wording depends on its answer)
- **Interim:** the lines stay stale. Neither one changes behavior.

### Q-110 · health-check-not-run-undercount
**Needs:** agent · **Opened:** 2026-10-02 · **Status:** OPEN

In one `scripts/health-check.sh` run (2026-10-02, main at 188e0a7d), the test runner printed `NOT RUN: 50 report-dependent suite(s)`, but the health check's own summary said `4 report-dependent BATS suite(s) NOT RUN`. Find out why the summary under-counts and fix it, with a test.

- **Read:** `scripts/health-check.sh` (check 5's NOT RUN summary) · `scripts/run-tests.sh` ("Report gating") · the review of `chore/dev-cycle-2026-10-02` (`docs/reviews/code-fact-check-report-devcycle-cycle-2026-10-02.md`)
- **Cause (reproduced in this branch's pass-2 review):** `test/skills/eval-helpers-gating.bats` runs nested `run-tests.sh --fast` calls (lines 76–91; the pass-2 review reproduced it with the line-76 test) that do not override `RUN_TESTS_NOT_RUN_FILE`. The nested run inherits the parent's file and overwrites the parent's count (50, written before any suite runs, `scripts/run-tests.sh:356-357`) with its own 4. Fix: unset the variable in that suite's `setup()` (not at top level of `test/lib/hermetic-env.bash`: `run-tests.sh` sources that file before its own write, so the count would vanish), or have the runner stop passing the variable to the bats processes it starts; add a test that the parent's file is untouched. Having the runner refuse an inherited value cannot work: the health check passes the variable through the environment (`scripts/health-check.sh`, check 5).
- **Interim:** trust the runner's own NOT RUN list, not the summary line.

### Q-103 · dev-cycle-build-loop-policy
**Needs:** you: judgment · **Opened:** 2026-10-01 · **Status:** OPEN

The build-loop handoff is built: may build loops in claude-workflows land their own branches through the gate (`self-merge`), or must each finished branch stop for your review (`review`)?

- **Why it's yours:** you said this depends on the project and is settled at onboarding; claude-workflows was onboarded before the setting existed. Re-routed from `deferred` on 2026-10-14, when the handoff landed (U5).
- **Read:** decision log row 72 · `docs/working/plan-build-loop-handoff.md`, "What the gate can and cannot do" and the bypass-family table (F1–F59) · `docs/dev-cycle.md`

**What the gate can and cannot do.** Loops run as your uid, with a shell, in worktrees that share `/workspace/.git`. No script can contain a loop that turns hostile with its shell: it could run plain `git merge` or `git push`, write any working tree under `/workspace`, or plant `.git` state. The design makes the honest path safe and checkable, and makes the commonest honest slip, a git command run in the wrong directory, fail loudly instead of landing (D13). Content reaches main only through a gate that decides from main's committed state and the exact merge result, and the gate that runs is the root-owned image copy, which no loop can edit (D6, Q-140 [1]). Each iteration checks that main moved only by the orchestrator's merges, the gate's merges and answer-only commits (D13). With no human reading briefs (D10), the gate and your review of `ready` work are the checks on what lands.

The residual families. None blocks self-merge mechanically; each is a way around the gate for a loop that already has a shell and the session's tools, not a hole in the gate's own rules:

- **F11, `@`-imports (partly).** The floor refuses instruction files and what they import, by a walk of main's commit and then of the gate's checkout. Precondition: the walk reads the checkout, so the gate runs it in a clean checkout at `MAIN_SHA` (`checkout_gate` refuses anything else). `checkout_gate` closes checkout conversions, `core.symlinks` false, sparse checkout and untracked nested repositories for the gate. Still open (known issue A5): start files under a symlinked directory, a FIFO start, other names one file has on a case-insensitive filesystem whose `core.ignoreCase` is false, and a checkout file swapped between the gate's check and the walk's read; and instruction files outside the repo that the container cannot see (the host's own). A Claude Code upgrade that changes its import grammar reopens it.
- **F19, plain git to main (partly).** An honest wrong-directory commit fails, and any commit on main that is not the orchestrator's, the gate's or answers-only is reported at the next iteration (`--main-log`). A deliberate `git push`, or a commit shaped like an answers commit, is not caught.
- **F21, text injection (partly).** Briefs are written and read from main's commit, and every prompt says repo text is evidence. Under self-merge the allowlist bounds what lands; under review you read the result. What a steered loop does outside git is bounded only by the sandbox.
- **F29, a checked-out main (partly).** The gate refuses a worktree with main checked out unless it is on main, clean and mid no rebase, bisect or merge. Left: that worktree switches branch between the check and the fast-forward.
- **F35, the session's other tools (not covered).** The loop prompt forbids pushing, publishing, starting build loops, background agents and schedules, but a loop subagent shares the orchestrator's permission mode.
- **F37, two orchestrators (partly).** A worktree lock and an atomic branch create stop a second loop on one brief. Two chore branches can mint the same Q-ID; `questions.sh check` catches it, at the land or, after a merge-in of main (which skips step 1's check), at the next health check.
- **F58, releases (partly).** Code the image carries reaches running sessions through a release, and your review of the release is the gate. The release entry (`image-lag`) lists every commit and changed path since the image's commit and flags self-merge subjects. The release paste runs `devcontainer-config/install.sh` before it shows its diff, so that directory is on this repo's never line (Q-149).
- **F59, constraint drift (partly).** A loop decides alone when one option dominates. Step 4's drift check samples one such decision per sampled merge, and a finding triggers the deep audit's constraints dimension.
- **R8, racing the gate's temp files.** A same-uid writer can race the gate's GATE_TMP between its writes and its reads: `git/config`, `git/info/`, `git/refs/`, `git/HEAD`, `work/.gitattributes`, `err`, `diff`, and `answer`, the file holding `--approved`'s verdict on the merge entry (override rows 509, 684).
- **Also routed here during the build** (rows are override-log rows in `docs/reviews/override-log.md`, by line; the U2b3a item is from the plan's U2b3a bullet and the U4c item from SKILL.md's D6 Rule):
  - a loop editing the worktree registry in the shared common dir (U2b3a);
  - objects re-hashed once per run, so one rewritten in place afterwards, and objects not re-hashed at all (the tip's parent, merge bases) (U3a1);
  - a planted `core.bare` with the index deleted (U3a2, Low), and a hand-edited rebase todo holding an `update-ref` main line (row 668);
  - a same-uid shell's PATH, exported functions or settings around the D6 block (U4c);
  - a loop pointing `origin/HEAD` at its own branch, which `dev-cycle.sh`'s reader settings then read (row 548);
  - planted hooks in the common git dir around the orchestrator's own commit, and a FIFO swapped for the health-check lock (rows 749, 750);
  - a rewrite of main to a history that never held a cycle record, which bootstraps `--main-log` again (row 784);
  - the dispatch count written after the dispatch, so a session ending between the two admits one dispatch past the cap (row 786);
  - after a restart, `--prompt --steal` taking another live session's loop that has not committed for two hours (row 787);
  - merge entries flagging floor paths by class, not the floor's own reasons, so an `@`-imported doc reaches you unflagged (row 797);
  - `--start`/`--prompt` reading main after step 10's last `--main-log` (a window of seconds) (row 801);
  - `--cycle-diff`/`--land-cycle` accepting any `--answered` ID, so only skill text stops a merge entry being landed as answered (row 802);
  - the health check that [2]'s last column relies on is itself code the gate could land, which is why this repo's never line holds `scripts/`, `test/`, `hooks/` and `devcontainer-config/` (row 682, Q-149).

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] review** | Every `ready` branch the N rules (both policies) pass gets one merge entry (`merge-STEM-SHA12`, or `merge-gate-…` for gate code) holding `--check`'s output; the orchestrator merges on your `[1] merge` | One decision per finished item | Finished work queues behind you; loops keep running into free slots meanwhile |
| **[2] self-merge** | A brief with `Policy: self-merge` lands through the gate with no review when every changed path is in its `Paths:` line or is one of the brief's own files, and is off the floor and the never line; a path refusal falls to [1]'s entry, a conflict ends stopped and an environment refusal is retried | None for that work; with this repo's never line (Q-149) only docs the floor does not protect, `README.md`, `runs/`, `archive/` and paths under a new top-level name can self-merge, so most work still comes to you | A bad change pr-prep's review missed lands on main, through one of the families above or plainly; the next cycle's health check, spot-check and drift check might catch it |

- **Interim:** [1] `review`, recorded as `Build-loop policy: review (interim; Q-103)`, which `--settings` reads as unset, which means `review`.
- **If the answer differs:** nothing to redo. Either answer is recorded the same way: in `docs/dev-cycle.md`, replace the policy line with `Build-loop policy: review` ([1]) or `Build-loop policy: self-merge` ([2]), and drop the Policy note's clause about "(interim; Q-103)"; for [2] the never line must stay valid.

### Q-067 · regenerate-skill-eval-reports
**Needs:** deferred · **Opened:** 2026-09-26 · **Status:** OPEN

When should the skill eval reports be regenerated, so that the 50 `@needs-reports` suites constrain the current SKILL.md files instead of being NOT RUN?

- **Why it's yours:** regenerating means one headless model run per fixture, about 180 fixtures across 23 skills. Memory [[run-a8-measurement-after-settling]] says no big compute before the A8 measurement.
- **Read:** `docs/working/audit-test-constraint-2026-09-26.md` batch G, and commit 48680e2 (stamps plus the per-skill gate).

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Fold into A8** | Regenerate as part of the A8 run once the code settles | None now | Skill-prompt regressions go uncaught until then, as they have all along |
| **[2] One skill now** | Regenerate one high-value skill (e.g. security-reviewer) to prove the loop end to end | About 12 model runs | A little quota spent before A8 |
| **[3] All now** | `bash test/skills/generate-reports.bash` for every skill | About 180 runs, which may skew A8's baseline | Quota spent, and A8 comparability muddied |

- **Interim:** [1]. The suites print NOT RUN, and health-check warns with the count, so no one mistakes them for a pass.
- **Deferred 2026-09-26 behind Q-071:** under the current stamp design, regenerated reports go stale at the next contract edit, so the suite design comes first.
- **2026-09-27:** Q-071 was answered [1] (narrow stamp, committed reports), so one regeneration now stays valid until the skill itself changes. This remains deferred behind A8 only ([[run-a8-measurement-after-settling]]).
- **If the answer differs:** nothing to redo; only when regeneration happens changes.

### Q-074 · failure-pattern-writer-trigger
**Needs:** trigger · **Opened:** 2026-09-26 · **Status:** OPEN

After the Q-018 backfill (164 entries), `docs/thoughts/failure-patterns.md` has gained 1 entry across about 128 `fix` commits. The writer is still pr-prep Step 0, a workflow step that is advisory only. If it reaches 2026-10-26 with fewer than 5 new entries, reopen L1 as a judgment: automate the harvest, or drop the "do not skip" line.

- **Interim:** nothing changed. The read side (the RPI failure-pattern grep) works.

### Q-079 · canon-instance-proposal-filter
**Needs:** agent · **Opened:** 2026-09-27 · **Status:** OPEN

Design, per Q-072, (a) a script that turns a commit or commit range into a canon instance, and (b) the higher-level heuristic that decides which candidates get *proposed*. The canon should stay compact and broad in issue types. Growth should be justified by coverage, not triggered by volume. Draft it as a divergent-design doc. The filter choice then comes back as a `you: judgment` entry.

- **Read:** `docs/working/canon-issue-ledger.md` · `review-canon.md` §1 · the 112 September `docs/reviews/` artifacts as the candidate pool
- **Interim:** the ledger is unchanged.

### Q-084 · q076-live-checks
**Needs:** you: terminal · **Opened:** 2026-09-27 · **Status:** OPEN

Q-076 (`cc-push`, the exit scan) was verified only with bats: stubbed docker and local-path remotes, on git 2.39.5. After merging, re-run `install.sh` (it re-blesses; `cc-push.sh`, `cc-exit-scan.sh` and `cc-gitdir.sh` are new), then run this on the host:

```
git --version          # cc-push refuses below 2.39.4 / 2.40.2 / 2.41.1 / 2.42.2 / 2.43.4 / 2.44.1 / 2.45.1 (or <2.46 otherwise)
# 1. a clean session: launch, make one commit, exit claude -> expect exit 0 and no WARNING
cc-isolated ~/path/to/a/scratch/repo
# 2. while that container is still up, in another host shell -> expect a refusal naming the running container
cc-push --remote <your real remote URL> ~/path/to/a/scratch/repo
# 3. stop the container (or exit cc-isolated), then push for real -> expect the preview, then the push
cc-push ~/path/to/a/scratch/repo
# 3b. (Q-093, after re-running install.sh) leave .git/commondir holding '.' in place -> expect the push, no refusal
# 1b. (Q-094) a session that leaves an agent worktree behind -> expect exit 0 and one 'note:' line, no WARNING
# 4. inside any cc-isolated session on the rebuilt image (Q-086, 9e5477a) -> expect a version line
parallel --version | head -1
apt-cache depends parallel                 # Q-086 review C3: note any hard dependency (e.g. sysstat)
bats --jobs 2 test/agents-gemini-sync.bats 2>&1 | grep -iE 'cite|locale'   # expect no output (C2)
```

**2026-09-28 (answers-9-28-26-2.txt), step 3:** `cc-push` refused on `~/claude-workflows` itself (not a scratch repo): "`.git/commondir` exists (a linked worktree's layout)". Cause: the main checkout's `.git` has a stray 1-byte `commondir` holding `.` (it points to itself, so git behaves as if it weren't there). Next to it are an empty `config.worktree` and an empty `modules/`, all dated 2026-07-09 13:45. No commit that day runs `git worktree`, so some tool probably wrote them. `extensions.worktreeConfig` is unset, so git never reads `config.worktree`. `cc-push.sh:272` refuses any `commondir` without resolving it: a false positive on this repo. The fix is Q-091. Steps 1, 2 and 4 are not reported yet.

**2026-09-28, step 2:** passed. With the container still running, `cc-push` refused and named the running container, as expected. The stray `commondir` behind step 3's refusal is removed (Q-091 [1]), so step 3 needs a rerun. Steps 1 and 4 are not reported yet.

**2026-09-28, step 3:** passed. `cc-push` worked on `~/claude-workflows`, but only after the user deleted `.git/commondir` again. It had come back since Q-091 [1], which is now Q-093. Step 1 has not been run as written. Every session exited today gave a WARNING, mostly listing worktrees. The cause was reproduced in a scratch repo with the real `git_exit_scan`: a worktree still present at exit adds three records (`+ dotgit <wt>/.git`, `+ commondir-file .git/worktrees/<name>/commondir`, `+ hooksdir .git/worktrees/<name>/hooks missing`), so the scan returns 1. With the worktree removed and pruned it returns 0. That behaviour is what the scan specifies, not a bug, and whether it should change is Q-094. Step 1 is still a valid test as written: a scratch repo with no worktrees should exit 0. Steps 1 and 4 are not reported yet.

**2026-09-30 (answers-9-30-26.txt):** host git is now **2.55.0**. WSL's apt had an old version that `cc-push` refused, and apt listed nothing newer. **Step 1 passed:** a small test commit, then exit with no error. **Step 2 passed** again: refused while a session ran. **Steps 3 and 3b passed:** `cc-push` showed the preview and pushed without `.git/commondir` being deleted, which confirms Q-093's relaxation live. **Step 4 passed:** `GNU parallel 20221122`, which is bookworm's version, so it ran in the image (compare Q-086's host reading of 20210822). `apt-cache depends parallel` lists hard deps on `procps`, `sysstat` and `perl`, so sysstat comes into the image with parallel (review C3: noted, no action). The `bats --jobs 2 … | grep -iE 'cite|locale'` check printed nothing (C2 holds). That fires Q-090's trigger. **Still not reported: step 1b** (Q-094): a session that leaves an agent worktree behind should exit 0 with one `note:` line. Q-084 stays open for that step alone.

- **Interim:** every enforcement-file commit on Q-076 carries `Live-verified: no`.
- **If the answer differs:** a refusal on step 3, a warning on step 1, or a version refused that git's release notes list as fixed means a follow-up fix. Also check git's May 2024 security release notes against the version list in the `cc-push.sh` header, which was written from memory.

### Q-096 · exit-scan-insteadof-target
**Needs:** agent · **Opened:** 2026-09-28 · **Status:** OPEN

The exit scan records a `url.<base>.insteadOf` / `pushInsteadOf` base but never the URL it rewrites to, including at the top level, so a session can repoint a remote through a rewrite the scan does not follow. Found in the Q-094 review and now listed in the guide's "Known routes it does not see". Close it: the rewritten local-path target is walked as a remote, as `_snap_remote` does for `remote.*.url`.

- **Read:** Q-094 rubric `docs/reviews/code-review-rubric-2026-09-28-q094-exit-scan-worktree-layout.md` · `_snap_config` / `_snap_remote` in `devcontainer-config/cc-exit-scan.sh`
- **Constraint:** enforcement file: pre-mortem with bypass families first (decision log 61), under the 400-line cap. Start after Q-094's branches merge (same file).
- **Interim:** documented as a known route. cc-push, which runs no git in the checkout, is still the way to push.
- **Unblocked 2026-10-02 (dev cycle):** Q-094's branches merged (7bf3b581), so the "start after" condition is met. Briefed as `docs/working/briefs/2026-10-02-exit-scan-insteadof-target.md`.
- **Built 2026-10-15:** `fix/q096-exit-scan-insteadof-target` (8717fd72, loop closed), merged by Q-162's paste; this entry closes when it lands. Host probe: Q-167. Split-off: Q-168. Review history: The first security pass found five Mediums, all confirmed by probe. One is pre-existing: a remote with no `url` is pushed to as a path, and the scan skips it. The commit carries `Host-tool-tested: no` (decision log row 71), not `Live-verified`.

### Q-097 · exit-scan-older-routes
**Needs:** agent · **Opened:** 2026-09-28 · **Status:** OPEN

The Q-094 review documented two older Medium routes the exit scan does not see, both now under the guide's "Known routes it does not see". (a) A symlink in the working tree to a repository outside the checkout is not walked. (b) A non-standard container-form `.git` (`gitdir: /workspace/...`) left at launch can map to a different git dir under `git worktree repair`, which picks by worktree name. Close each or record why it stays open, one enforcement unit each, after Q-096.

- **Read:** `docs/reviews/code-review-rubric-2026-09-28-q094-final-B.md` · the guide's known-routes list · override-log row 135 (fold the `commondir` reader into `cc-gitdir.sh`; its trigger was moved, not met)
- **Interim:** documented. cc-push is still the only way to push.

### Q-098 · global-allowlist-after-sandbox
**Needs:** deferred · **Opened:** 2026-09-28 · **Status:** OPEN

Ship a global `permissions.allow` in `hooks/wiring.json` once cc-isolated has a Bash sandbox (Q-088). Branch `feat/wiring-allowlist-b` holds the 778-rule list, its tests and two review passes. It stays unmerged: without a sandbox, allowed tools leak through their own flags. The hook's shape check (decision log 64) cannot see that.

- **Read:** `docs/reviews/code-fact-check-report-wiring-pass1-5094b99.md` (on that branch) · `docs/reviews/code-fact-check-report-wiring-pass2-e511a14.md` (on that branch; the leak list's source) · decision log 64 · Q-088
- **Leak list, to use as the sandbox spike's test set.** Each item was approved with no prompt by the 778-rule list and the shape-checked hook, or was run in a scratch repo:
  - `git diff --no-index /dev/null ~/.claude/.c*` reads the credentials file;
  - `git log -1 --format=%B --output=/home/node/.claude/settings.json` writes the config volume (`guard-trusted-writes.py` does not catch `--output`);
  - `git status`, `git diff`, `git log -p` and `git show` run `core.fsmonitor`, `diff.external` and textconv drivers from repo config the agent can edit;
  - `man -l <file>` and `date -f <file>` read a file (both reproduced by the unit-A pass-2 fact-check).
  - Not on this list because the hook now refuses them whatever the rules say: bash builtins that evaluate their arguments (`read 'a[$(cmd)]'`, `test -v`, `printf -v`, `mapfile -C`, `hash -p`) and the shell constructs in decision log 64.
- **Trigger:** Q-125 lands (Q-124 answered [1], build the sandbox) and the sandbox denies reads of `~/.claude/.credentials.json` and writes to `~/.claude/settings*.json`. Then re-run the leak list inside it before merging any list.
- **Interim:** no global allow list. cc-isolated sessions prompt for commands not in their project's `.claude/settings.json`.

### Q-092 · drop-hook-deny-reader
**Needs:** agent · **Opened:** 2026-09-28 · **Status:** OPEN

Per Q-082's answer (`permissions.deny` beats a hook `allow`), remove the Bash deny reader from `hooks/auto-approve-allowed-commands.sh`: the settings-file deny loading, `--deny`, the de-quoted matching and their tests. Update the hook header's rule table to match. This is architecture-review finding 1 on Q-076.

- **Read:** Q-082 in the archive · decision log 53 (amended 2026-09-28) · the hook header
- **Constraint:** this changes an enforcement file, so the plan's pre-mortem lists the bypass families and marks each covered or not before implementing. One case to check explicitly: the host result covers `allow` only. If the hook can ever emit `ask` (#39344 shows `ask` overriding deny), the reader may still be needed on that path.
- **Interim:** the reader stays. It is redundant for `allow`, not harmful.

### Q-125 · build-cc-isolated-sandbox
**Needs:** agent · **Opened:** 2026-10-07 · **Status:** OPEN

Implement Q-124 [1] as an RPI unit. Add a seccomp profile file: Docker's default with `unshare` and `clone`/`clone3` `CLONE_NEWUSER` allowed without CAP_SYS_ADMIN, nothing else widened. Load it from `devcontainer.json` runArgs as `--security-opt seccomp=<file>`. Add `bubblewrap` and `socat` to the Dockerfile. Add a `sandbox` settings block with no `enableWeakerNestedSandbox`, `autoAllowBashIfSandboxed` decided explicitly, `allowedDomains` matched to the egress allowlist, and reads of `~/.claude/.credentials.json` / writes of `~/.claude/settings*.json` denied. Amend decision log 53.

- **Read:** `docs/spikes/weaker-nested-sandbox-cc-isolated.md` (the RPI seed, plus "What the spike did NOT answer") · Q-081, Q-088, Q-124 in the archive · decision log 53 · Q-098's leak list
- **Constraint:** enforcement files (Dockerfile, `devcontainer.json`, the profile, settings), so the plan's pre-mortem lists the bypass families and marks each covered or not, and the commit needs a live-verified host run: in cc-isolated, a sandboxed `cat ~/.claude/.credentials.json` is refused, Q-098's leak list is re-run inside the sandbox, and `gh`/`git push` paths do not prompt. The unit counts against the ~400-line cap (decision log 62). Keep the branch unmerged until the host run passes.
- **Open, for the RPI research:** does bwrap work under that profile on the WSL2 6.18 kernel (and any AppArmor on the host)? The live check above settles it.
- **Interim:** nothing sandboxes Bash in cc-isolated.
- **Update 2026-10-07:** built, unmerged, in two stacked units (decision-62 cap):
  - U1 `feat/q125a-seccomp` (6fdd62d6): the profile, runArgs, bwrap/socat.
  - U2 `feat/q125-cc-isolated-sandbox`: root-owned managed settings rendered from the egress allowlist.
  - Two departures from the text above. The profile also allows `mount`/`umount2`/`pivot_root`, and allows `unshare`/`clone` without the NEWUSER bit, because bwrap and Claude Code's seccomp helper need them; the kernel still cap-gates all of them. The settings live in `/etc/claude-code/managed-settings.json`, not in `wiring.json`, which the agent can edit.
  - Open: a fresh `/proc` mount is probably refused under Docker's masked `/proc` paths. Q-126 tests that, Q-127 decides the fallback, and the live run is the step after Q-126. See `docs/working/plan-q125-cc-isolated-sandbox.md`.

  - **Update 2026-10-07 (Q-126):** the host probe passed, so a fresh `/proc` works and Q-127 is moot. U2 has merged main (2961ca2f), so the live run installs current payload. Next is Q-130.

### Q-147 · q089-loop-split-source-guard
**Needs:** agent · **Opened:** 2026-10-14 · **Status:** OPEN

Q-089 unit A's review-fix loop ran a 4th iteration before recording a cap decision. It is now recorded as `split`: the static source-set test (rubric A6/R2/R4) moves to its own unit, `feat/q089-source-guard` (at fa059477). The rest of unit A starts a new loop. That source-guard unit needs a fresh loop that first narrows the test's claim to "plain spellings, accidental drift". Pass 4 showed grep can't cover every bash form.

- **Read:** `docs/reviews/code-review-rubric-2026-10-14-feat-q089-host-tool-trust.md` "Iteration-4 gate"
- **Interim:** unit A ships without the static guard. The runtime checks don't depend on it, and the guard is hardening against a future refactor.

### Q-149 · self-merge-never-scope
**Needs:** you: judgment · **Opened:** 2026-10-14 · **Status:** OPEN

How wide should this repo's `Self-merge never:` line be: every directory that takes effect without a release (as written), only `workflows/`, or nothing?

- **Why it's yours:** it decides which of this repo's files may land with no review once Q-103 allows self-merge.
- **Read:** `docs/dev-cycle.md` (Never line) · plan D5 "In this repo" and F57 in `docs/working/plan-build-loop-handoff.md` · override row 682 · `docs/reviews/security-review-2026-10-14-u5-i1.md` F1, F3, F4

The plan assumed code here reaches running sessions only through an image release, with `workflows/` the one exception. Review found more: sessions read `skills/` (beyond `SKILL.md`, which the floor already refuses), `guides/` and `patterns/` from their checkout as well; the health check the orchestrator runs every iteration executes `scripts/`, `test/`, `hooks/` and `devcontainer-config/` from its worktree; and the release paste runs `devcontainer-config/install.sh` before it shows its diff. Two docs off the floor are also read as authority and stay self-mergeable under every option: `docs/evaluation-rubric.md` (self-eval's rubric) and `docs/spikes/` (seeds later work loads); listing them too is a fourth choice, open to you as a note on [1].

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Wide** (as written) | `workflows/ scripts/ test/ hooks/ devcontainer-config/ skills/ guides/ patterns/ templates/ global-instructions/`: self-merge lands only docs the floor does not protect, `README.md`, `runs/`, `archive/` and paths under a new top-level name | Nearly every change comes to you as a merge entry | Self-merge buys little here; code fixes queue behind you |
| **[2] `workflows/` only** | The plan's interim: code self-merges when its brief lists it | None for listed code | A self-merged script or test runs in the next health check, and a self-merged `install.sh` runs on your host at the next release, unreviewed |
| **[3] None** | `Self-merge never: none` | None | Everything [2] risks, plus workflow changes that steer every later session here |

- **Blocks:** nothing while the policy is `review` (Q-103): the never line only narrows self-merge.
- **Interim:** [1], fail-closed.
- **If the answer differs:** an edit to the never line in `docs/dev-cycle.md` (`none`, not an empty line, keeps self-merge possible), to its Never-line prose there, Q-103 [2], Q-103's F58 bullet and its last "also routed" item, and to its test line in `test/scripts/build-loop-read.bats`.

### Q-150 · build-loop-c1-questions-writer
**Needs:** you: judgment · **Opened:** 2026-10-14 · **Status:** OPEN

Should the orchestrator stay the only writer of the questions files, with build loops carrying their questions in a `handoff: blocked` marker, or should loops write entries themselves? (Plan C1.)

- **Read:** plan D11 and F41 in `docs/working/plan-build-loop-handoff.md` · `docs/working/handoff-build-loop-handoff.md` C1

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Orchestrator only** (built) | A loop ends with a `blocked` marker; the orchestrator files its question as an entry, the body quoted line by line (`--marker`) | None | A loop's question appears one orchestrator iteration later than it could |
| **[2] Loops write directly** | Each loop edits the questions files on its own branch | A new gate unit to review | Up to slots+1 sessions edit one file, minting colliding IDs, and a loop's text can plant an answer line the readers take as yours (F41, reproduced) |

- **Interim:** [1], as built (D11).
- **If the answer differs:** [2] reopens D11 and F41: `--marker`, `--cycle-diff` and the N rules change, in a reviewed unit.

### Q-151 · build-loop-c2-blocked-slot
**Needs:** you: judgment · **Opened:** 2026-10-14 · **Status:** OPEN

Does a blocked build loop give up its slot while it waits for your answer? (Plan C2.)

- **Read:** plan D9 · `docs/working/handoff-build-loop-handoff.md` C2

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Frees the slot** (built) | Only a live or queued loop counts against the slots; a blocked item re-enters the queue on its existing branch once answered, ahead of new briefs | None | More work is in flight at once than the slot count suggests, so more answers wait on you |
| **[2] Holds the slot** | A blocked item counts against `Build-loop slots:` until answered | None | Blocked work starves the cap: with 3 blocked items nothing else runs |

- **Interim:** [1], as built (D9).
- **If the answer differs:** [2] is a change to the skill's slot counts in steps 8 and 10.

### Q-152 · build-loop-c3-blocked-wait
**Needs:** you: judgment · **Opened:** 2026-10-14 · **Status:** OPEN

When every thread is blocked on you, should the orchestrator loop keep polling, or stop until you restart it? (Plan C3.)

- **Read:** plan D12 · `skills/dev-cycle/SKILL.md`, the wait rule at the end of step 10 · `docs/working/handoff-build-loop-handoff.md` C3

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Poll** (built) | It wakes every 1200–1800 s and runs a full cycle only when main moved past its last land (a committed answer moves it), a retry's wait ran out or you wrote; otherwise the wakeup does nothing | None | A little spend per idle wakeup while you are away |
| **[2] Stop** | The `/loop` ends; you start `/loop /dev-cycle` again after answering | One command per return | Answered work sits until you remember to restart |

- **Interim:** [1], as built (D12).
- **If the answer differs:** [2] replaces the skill's wait rule with an end-of-loop line.

### Q-153 · build-loop-c4-merged-branch-deletion
**Needs:** you: judgment · **Opened:** 2026-10-14 · **Status:** OPEN

May the dev cycle delete merged branches without asking, which your global instructions forbid today ("deleting branches" needs approval in every mode)? (Plan C4.)

- **Why it's yours:** it changes your own global instructions, and your answer 2 ("safe branch deletion doesn't need to wait") conflicts with them as written.
- **Read:** `docs/working/handoff-build-loop-handoff.md` C4 and answer 2 · roadmap Ideas, "Merged-branch deletion"

Every orchestrator iteration leaves a `chore/dev-cycle-DATE-HHMM` branch and every loop a feature branch, so they pile up.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Narrow the global rule** | Merged branches, `git branch -d` only (git refuses an unmerged one), need no approval, in every project | None after the edit | A branch merged by mistake loses its name in every project (the commits stay reachable from main) |
| **[2] This project only** | The same exception, written for claude-workflows alone | None here | Other projects keep asking |
| **[3] Keep asking** | Nothing deletes branches; they wait for you | A cleanup pass now and then | Branch lists grow by one or more per iteration |

- **Blocks:** roadmap item "Merged-branch deletion".
- **Interim:** [3]: nothing deletes a branch.
- **If the answer differs:** [1] or [2] is an instruction edit plus the roadmap item's health-step change.

### Q-155 · constraints-doc-missing
**Needs:** you: judgment · **Opened:** 2026-10-14 · **Status:** OPEN

This repo has no `docs/constraints.md`, so the orchestrator dispatches no build loop here: write one now, or leave dispatch off until a process for writing one exists?

- **Why it's yours:** the hard constraints steer every design choice a loop makes alone (D2), so they must be yours, not inferred.
- **Read:** plan D2 · `skills/dev-cycle/SKILL.md` "Constraints" · `scripts/build-loop.sh` header, the `constraints` line of `--settings` · roadmap Ideas, "A process for writing a repo's constraints doc"

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Write it now** | You write `H1: …` lines, each with a `success:` line, and any `S1: …` soft ones, and commit them on main | An hour or so of your time | Loops decide by constraints you wrote in a hurry; the drift check and deep audit surface the misses |
| **[2] Wait for the process** | Dispatch stays off until the roadmap item yields a way to write one | None now | The orchestrator runs every step but dispatch, so briefs pile up unbuilt |

- **Blocks:** dispatch in this repo (step 10).
- **Interim:** [2]. `--settings` prints `constraints missing`, and step 10 files no second entry while one with this slug exists, open or answered.
- **If the answer differs:** nothing to redo.

### Q-156 · image-lag
**Needs:** you: terminal · **Opened:** 2026-10-14 · **Status:** OPEN

Cut a release: rebuild and bless the image from main once `feat/build-loop-u5` has merged, so the installed dev-cycle skill and the gate it runs (the image copy, Q-140 [1]) carry the build-loop handoff as built.

- **Read:** `skills/dev-cycle/SKILL.md` step 0.1 (this entry's slug is the one step 0.1 files and rewrites) · decision log row 72 · plan D6 and F58

The image's commit C is `8d0e660e2e5a9769200500ac3dcfb4b113a32589` (`/opt/claude-workflows/.manifest`, assembled from `/home/magfrump/claude-workflows`), on main's first-parent history. M is `8cff4877aa30a9417b48bd792ef60319502d7e78`, the last commit on `feat/build-loop-u5` that changes anything the release installs; the branch's later commits change only `docs/`, so the merge's released trees equal M's. (Step 0.1's own rewrite of this entry uses main's commit as M.) At writing, main was `b279a2ba`. The image's dev-cycle skill lacks the D6 block (U4c), so the orchestrator loop cannot run as written until this release.

Gate code changed from C to M: `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `skills/dev-cycle/SKILL.md`.

First-parent commits after C (none is a `(build-loop self-merge)`: every one was merged by hand or committed in session), then this branch's merge:

- 308196e7 Merge branch 'feat/build-loop-u4c': the D6 block always runs the root-owned image copy (Q-140 [1]); step 0.1's image checks (Q-144 [1])
- 5cad0964 docs(checkpoint): U4c merged at 308196e7 on Q-144 [1]; Q-144 answered and archived; next a release, then U5
- 33555624 docs(questions): Q-145, the lib's ancestor listing races with /tmp churn; blocks Q-102's merge
- f66fd9f2 Merge branch 'feat/q102-parallel-gates': health-check runs its test gate in parallel by default (Q-102 [1], Q-145 [2])
- 4ab9a51f docs(working): Q-075 evidence on what self-improvement.sh can write; Q-146 filed
- 6d9a2962 docs(questions): Q-147 and Q-148 on main, so the open Q-089 asks are visible before its branches land
- ed4976bf docs(roadmap): drop Q-088 from Next (answered 2026-10-07), note Q-089 waiting on Q-148
- 626dc300 Merge branch 'feat/q089a2b-cc-push-self-check': host-only tools get their own trust manifest; cc-push checks itself (Q-089 units A1+A2, Q-148 [1])
- df18413a Merge branch 'feat/q089b4-host-tool-gate': host tools carry Host-tool-tested, not Live-verified (Q-089 unit B, Q-148 [1])
- d7e140ea docs(questions, roadmap): Q-148 answered [1] and archived; Q-089 merged (626dc300, df18413a)
- b279a2ba docs(reviews): carry the first Q-089 loop's review history to main before its branch is deleted
- the merge of `feat/build-loop-u5` (this unit: docs, settings, questions; SKILL.md step 0.1's release listing and step 10's constraints slug)

Paths changed from C to M outside `docs/` (about 500 paths under `docs/` besides, nearly all `docs/reviews/`; the image carries none of `docs/`): `README.md`, `devcontainer-config/cc-exit-scan.sh`, `devcontainer-config/cc-gitdir.sh`, `devcontainer-config/cc-isolated.sh`, `devcontainer-config/cc-push.sh`, `devcontainer-config/install.sh`, `guides/cc-isolated-usage.md`, `guides/devcontainer-setup.md`, `hooks/live-verify-gate.sh`, `hooks/wiring.json`, `scripts/build-loop.sh`, `scripts/health-check.sh`, `scripts/lib/dev-cycle-read.sh`, `scripts/run-tests.sh`, `skills/code-review/SKILL.md`, `skills/dev-cycle/SKILL.md`, `test/cc-isolated-functions.bats`, `test/cc-push.bats`, `test/hooks/live-verify-gate.bats`, `test/install-host.bats`, `test/lib/d6-snippet.bash` (deleted), `test/scripts/build-loop-orchestrator.bats`, `test/scripts/build-loop-read.bats`, `test/scripts/health-check.bats`, `test/scripts/run-tests.bats`, `workflows/codebase-onboarding.md`, `workflows/pr-prep.md`, `workflows/research-plan-implement.md`.

Paste on the host once `feat/build-loop-u5` has merged and the host checkout is on main (then launch a new sandbox). Before install.sh runs, with only `rev-parse`, `for-each-ref` and `config --get-all` (none runs a hook or fsmonitor) and replace refs ignored, it checks that HEAD is at main's commit, that no replace ref exists (install.sh's `git archive` would honor one) and no graft file, that no config but your global or system one (the repository's, its worktree's or anything they include) sets `core.attributesFile` (whose `export-ignore` or `export-subst` would change what the archive writes), and that the root `.gitattributes` and every directory the release installs from are the same tree at HEAD as at M; so it refuses when main has moved a released path past what this entry lists:

```bash
cd /home/magfrump/claude-workflows && ( export GIT_NO_REPLACE_OBJECTS=1; M=8cff4877aa30a9417b48bd792ef60319502d7e78; test "$(git rev-parse HEAD)" = "$(git rev-parse refs/heads/main)" || { echo "release refused: HEAD is not main"; exit 1; }; test -z "$(git for-each-ref refs/replace/)" || { echo "release refused: replace refs present"; exit 1; }; test ! -e "$(git rev-parse --git-common-dir)/info/grafts" || { echo "release refused: info/grafts present"; exit 1; }; test -z "$(git config --includes --show-scope --get-all core.attributesFile | grep -Ev '^(global|system)[[:space:]]')" || { echo "release refused: core.attributesFile set"; exit 1; }; for p in .gitattributes devcontainer-config global-instructions guides hooks patterns scripts skills workflows; do test "$(git rev-parse "HEAD:$p")" = "$(git rev-parse "$M:$p")" || { echo "release refused: $p differs from M"; exit 1; }; done ) && ./devcontainer-config/install.sh
```

- **Interim:** the image's older gate and skill run; the orchestrator loop is not started here before this release.
- **If the answer differs:** each refusal names its cause. `differs from M`: main changed a released path after M, which the lists above do not cover; read `git log --first-parent M..main` before rewriting this entry with a new M. `HEAD is not main`: put the host checkout at main's commit first, knowing that a checkout runs any hook a sandbox planted. Replace refs, grafts or `core.attributesFile`: planted state; remove it and find out who wrote it before releasing.
