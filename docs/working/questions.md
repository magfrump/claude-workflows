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
| [Q-139](#q-139--workspace-hookspath-fails-state-gate) | you: judgment | `/workspace/.git/config` sets `core.hooksPath` to `/home/magfrump/claude-workflows/.git/hooks` (the host sp... | 2026-10-12 |
| [Q-141](#q-141--u4a-asked-binding-residue) | you: judgment | U4a's confirming pass found the Asked: brief binding still matches the wrong brief in one naming shape: mer... | 2026-10-13 |
| [Q-142](#q-142--u4b1-stop-path-worktree-remove) | you: judgment | U4b1's confirming pass found a new Medium in its own fix range (the skill's stop path removed the iteration... | 2026-10-13 |
| [Q-146](#q-146--si-children-commit-rights) | you: judgment | How should the self-improvement loop's implementer children get the right to commit, given that the only gr... | 2026-10-14 |
| [Q-149](#q-149--self-merge-never-scope) | you: judgment | How wide should this repo's `Self-merge never:` line be: every directory that takes effect without a releas... | 2026-10-14 |
| [Q-150](#q-150--build-loop-c1-questions-writer) | you: judgment | Should the orchestrator stay the only writer of the questions files, with build loops carrying their questi... | 2026-10-14 |
| [Q-151](#q-151--build-loop-c2-blocked-slot) | you: judgment | Does a blocked build loop give up its slot while it waits for your answer? (Plan C2.) | 2026-10-14 |
| [Q-152](#q-152--build-loop-c3-blocked-wait) | you: judgment | When every thread is blocked on you, should the orchestrator loop keep polling, or stop until you restart i... | 2026-10-14 |
| [Q-153](#q-153--build-loop-c4-merged-branch-deletion) | you: judgment | May the dev cycle delete merged branches without asking, which your global instructions forbid today ("dele... | 2026-10-14 |
| [Q-155](#q-155--constraints-doc-missing) | you: judgment | This repo has no `docs/constraints.md`, so the orchestrator dispatches no build loop here: write one now, o... | 2026-10-14 |
| [Q-084](#q-084--q076-live-checks) | you: terminal | Q-076 (`cc-push`, the exit scan) was verified only with bats: stubbed docker and local-path remotes, on git... | 2026-09-27 |
| [Q-156](#q-156--image-lag) | you: terminal | Cut a release: rebuild and bless the image from main once `feat/build-loop-u5` has merged, so the installed... | 2026-10-14 |
| [Q-079](#q-079--canon-instance-proposal-filter) | agent | Design, per Q-072, (a) a script that turns a commit or commit range into a canon instance, and (b) the high... | 2026-09-27 |
| [Q-089](#q-089--host-tools-trust-category) | agent | Implement Q-083 [1]: host-only tools (`cc-push.sh`, `cc-exit-scan.sh`, `cc-gitdir.sh`) get their own trust-... | 2026-09-28 |
| [Q-092](#q-092--drop-hook-deny-reader) | agent | Per Q-082's answer (`permissions.deny` beats a hook `allow`), remove the Bash deny reader from `hooks/auto-... | 2026-09-28 |
| [Q-096](#q-096--exit-scan-insteadof-target) | agent | The exit scan records a `url.<base>.insteadOf` / `pushInsteadOf` base but never the URL it rewrites to, inc... | 2026-09-28 |
| [Q-097](#q-097--exit-scan-older-routes) | agent | The Q-094 review documented two older Medium routes the exit scan does not see, both now under the guide's ... | 2026-09-28 |
| [Q-107](#q-107--claude-home-payload-second-consumer) | agent | Decision 036's trigger fired: "if a second consumer of the claude-home payload appears → [11]'s seam is o... | 2026-10-02 |
| [Q-108](#q-108--decision-037-stale-lines) | agent | Decision 037 has two stale lines. Line 58 says "035's still-pending regex", but the regex landed in addae61... | 2026-10-02 |
| [Q-110](#q-110--health-check-not-run-undercount) | agent | In one `scripts/health-check.sh` run (2026-10-02, main at 188e0a7d), the test runner printed `NOT RUN: 50 r... | 2026-10-02 |
| [Q-125](#q-125--build-cc-isolated-sandbox) | agent | Implement Q-124 [1] as an RPI unit. Add a seccomp profile file: Docker's default with `unshare` and `clone`... | 2026-10-07 |
| [Q-147](#q-147--q089-loop-split-source-guard) | agent | Q-089 unit A's review-fix loop ran a 4th iteration before recording a cap decision. It is now recorded as `... | 2026-10-14 |
| [Q-067](#q-067--regenerate-skill-eval-reports) | deferred | When should the skill eval reports be regenerated, so that the 50 `@needs-reports` suites constrain the cur... | 2026-09-26 |
| [Q-098](#q-098--global-allowlist-after-sandbox) | deferred | Ship a global `permissions.allow` in `hooks/wiring.json` once cc-isolated has a Bash sandbox (Q-088). Branc... | 2026-09-28 |
| [Q-074](#q-074--failure-pattern-writer-trigger) | trigger | After the Q-018 backfill (164 entries), `docs/thoughts/failure-patterns.md` has gained 1 entry across about... | 2026-09-26 |
<!-- index:end -->

## Open

### Q-107 · claude-home-payload-second-consumer
**Needs:** agent · **Opened:** 2026-10-02 · **Status:** OPEN

Decision 036's trigger fired: "if a second consumer of the claude-home payload appears → [11]'s seam is owed". 037's host target (built in 6793b79a, recorded in 29cdd160) now installs the same `CLAUDE_HOME_SRC` assembly as the devcontainer target (`devcontainer-config/install.sh`: `assemble` at lines 498 and 857). Check whether the shared `assemble()` over `git archive` already meets [11]'s seam. If it does, record that in 036. If not, file the seam work on the roadmap.

- **Read:** `docs/decisions/036-cc-isolated-repo-split.md` (candidate [11], Revisit triggers) · `assemble()` in `devcontainer-config/install.sh`
- **Interim:** both targets share `assemble()`, which is not a `cp -r` encoding one consumer's layout. The risk 036 named is at least partly covered.

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

- **F11, `@`-imports (partly).** The floor refuses instruction files and what they import, by a walk of main's commit and then of the gate's checkout. Precondition: the walk reads the checkout, so the gate runs it in a clean checkout at `MAIN_SHA` (`checkout_gate` refuses anything else). Known gaps (known issue A5): start files under a symlinked directory, in a submodule or in an untracked nested repo; case-insensitive names; checkout conversions; prompt files read by a session started outside the top level; instruction files outside the repo the container cannot see. A Claude Code upgrade that changes its import grammar reopens it.
- **F19, plain git to main (partly).** An honest wrong-directory commit fails, and any commit on main that is not the orchestrator's, the gate's or answers-only is reported at the next iteration (`--main-log`). A deliberate `git push`, or a commit shaped like an answers commit, is not caught.
- **F21, text injection (partly).** Briefs are written and read from main's commit, and every prompt says repo text is evidence. Under self-merge the allowlist bounds what lands; under review you read the result. What a steered loop does outside git is bounded only by the sandbox.
- **F29, a checked-out main (partly).** The gate refuses a worktree with main checked out unless it is on main, clean and mid no rebase, bisect or merge. Left: that worktree switches branch between the check and the fast-forward.
- **F35, the session's other tools (not covered).** The loop prompt forbids pushing, publishing, starting build loops, background agents and schedules, but a loop subagent shares the orchestrator's permission mode.
- **F37, two orchestrators (partly).** A worktree lock and an atomic branch create stop a second loop on one brief. Two chore branches can mint the same Q-ID; `questions.sh check` catches it, at the land or, after a merge-in of main (which skips step 1's check), at the next health check.
- **F58, releases (partly).** Code the image carries reaches running sessions through a release, and your review of the release is the gate. The release entry (`image-lag`) lists every commit and changed path since the image's commit and flags self-merge subjects. The release paste runs `devcontainer-config/install.sh` before it shows its diff, so that directory is on this repo's never line (Q-149).
- **F59, constraint drift (partly).** A loop decides alone when one option dominates. Step 4's drift check samples one such decision per sampled merge, and a finding triggers the deep audit's constraints dimension.
- **R8, racing the gate's temp files.** A same-uid writer can race the gate's GATE_TMP between its writes and its reads: `git/config`, `git/info/`, `git/refs/`, `git/HEAD`, `work/.gitattributes`, `err`, `diff`, and `answer`, the file holding `--approved`'s verdict on the merge entry (override rows 509, 684).
- **Also routed here during the build** (override-log rows in `docs/reviews/override-log.md`, by line):
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
| **[2] self-merge** | A brief with `Policy: self-merge` lands through the gate with no review when every changed path is in its `Paths:` line and off the floor and the never line; anything else falls to [1]'s entry | None for that work; with this repo's never line (Q-149) only docs, `README.md`, `runs/` and `archive/` off the floor can self-merge, so most work still comes to you | A bad change pr-prep's review missed lands on main, through one of the families above or plainly; the next cycle's health check, spot-check and drift check might catch it |

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

### Q-089 · host-tools-trust-category
**Needs:** agent · **Opened:** 2026-09-28 · **Status:** OPEN

Implement Q-083 [1]: host-only tools (`cc-push.sh`, `cc-exit-scan.sh`, `cc-gitdir.sh`) get their own trust-manifest section and commit trailer (e.g. `Host-tool-tested:`) instead of `Live-verified:`; `cc-push` verifies its own hash before running; `check_manifest` stops blocking cc-isolated launches when only a host tool changed; decision log row 45 is amended.

- **Read:** `docs/reviews/q076-architecture-review-2026-09-27.md` Finding 3 · decision log 45 · `hooks/live-verify-gate.sh` · `enforcement_files` in `devcontainer-config/cc-isolated.sh`.
- **Constraint:** this changes enforcement files, so per RPI step 3 the plan's pre-mortem lists the bypass families (e.g. a tampered cc-push that skips its own check, a manifest section swap) and marks each covered or not before implementing. The unit counts against the ~400-line cap (decision log 62).
- **Interim:** host tools stay in the enforcement set (Q-083's interim [2]).


### Q-139 · workspace-hookspath-fails-state-gate
**Needs:** you: judgment · **Opened:** 2026-10-12 · **Status:** OPEN

`/workspace/.git/config` sets `core.hooksPath` to `/home/magfrump/claude-workflows/.git/hooks` (the host spelling of this repo's own default hooks directory). The build-loop state gate refuses any `core.hooksPath`, so every gated mode (`--check`, `--merge`, `--start`, `--prompt`, `--state`, `--main-log`) refuses in this repo. Which way should the gate and the config meet?

- **Why it's yours:** the setting is your host config (no script in this repo sets it, as far as the sessions can see), and the choice is how much the gate trusts repo config it did not write.
- **The threats in play** (a build loop runs as your user and can write `.git/config` and `.git/hooks/`):
  - **T1, a planted hooks directory.** A loop sets `core.hooksPath` to a directory it wrote. The next plain git command anyone runs here (your commit, a pr-prep merge, the orchestrator's own git outside the script) runs the loop's hook as you, outside the loop's sandbox and after review. Refusing every `core.hooksPath` is how the gate catches this.
  - **T2, a hook written into the default directory.** A loop writes `.git/hooks/pre-commit` with no config change at all. No option here touches T2: the gate does not read the hooks directory today, and the script's own git runs with hooks off (`core.hooksPath=/dev/null`). It is listed so that no option below is read as closing it.
  - **T3, a look-alike path.** Under [2], a value that reads as this repo's hooks directory but resolves elsewhere (a symlink, another reader root's spelling, `..` parts) would pass the gate and be T1 again.
- **Read:** `scripts/build-loop.sh` state_gate (STATE_KEYS_RE) and harden · merge message of `feat/build-loop-u3b1` (ef7a1122), Areas of uncertainty.

| Option | What it means | Cost to you | Threat left open if it's wrong |
|---|---|---|---|
| **[1] Unset it on the host** | `git config --unset core.hooksPath` in `~/claude-workflows`; git then uses the same default hooks directory, so the same hooks run. | One terminal command. | None new: T1 stays fully guarded (any `core.hooksPath` is refused). If a host tool sets it again on purpose, the gate refuses again: lost availability, not safety. |
| **[2] Let the gate accept this repo's own hooks directory** | state_gate passes a `core.hooksPath` whose real path is this repository's own `hooks` directory under the git common dir; anything else still refuses. | None now; a small follow-up unit with review. | T3: if the real-path check has a hole, a planted directory passes, and T1 runs a loop's hook in your next plain git command. |
| **[3] Leave it until U4** | No change; decide when the orchestrator first runs here. | None now. | None new; every gated mode keeps refusing here, so the orchestrator's first iteration in this repo stops at `--state` until this is answered. |

- **Blocks:** the orchestrator's first live run in this repo (U4); nothing before it.
- **Interim:** [3]: no code or config change.
- **If the answer differs:** [1] needs nothing from the sessions; [2] is a follow-up unit before U4 lands.
- **Rewritten 2026-10-12** on your note (answers-10-12-26.txt): the threats are now named separately, and the last column says which threat each option leaves open.


### Q-141 · u4a-asked-binding-residue
**Needs:** you: judgment · **Opened:** 2026-10-13 · **Status:** OPEN

U4a's confirming pass found the Asked: brief binding still matches the wrong brief in one naming shape: merge U4a after one more narrow fix, merge it as is, or rework the binding?

- **Why it's yours:** the loop passed its 3-iteration cap and the confirming pass that was to decide the merge found a new Medium, which by the gate written in the rubric stops the merge and comes to you (the U3a2 / Q-138 precedent).
- **Read:** rubric `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4a.md` (iteration-4 gate) on `feat/build-loop-u4a`; `docs/reviews/security-review-2026-10-13-u4a-confirm.md` F-A, F-B; `docs/reviews/code-fact-check-report-2026-10-13-u4a-confirm.md` claim 3b.

An added Asked: ID must name an entry whose heading ends `-STEM-N` for the brief that adds it (so one brief cannot inherit another's answer). The check is anchored at a hyphen, so `keep-or-drop-2026-10-02-foo-2026-10-01-x-1`, an entry for a brief whose name ends in brief x's name, passes on brief x's line (executed by both the fact-check and security). Only the cycle names briefs and writes Asked: lines; no loop can. Also open, Low: the new path allowlist compares the path as spelled, so a fix to `readme.md` or `Docs/x.md` that --check-fix allows is refused (fails closed).

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] One more narrow fix, then merge** | The slug's prefix may hold only letters and hyphens (`^[a-z]+(-[a-z]+)*-STEM-N$`; a stem starts with a date's digit, so no other stem fits), the allowlist compares lower-cased; then a k=1 fact-check + security pass over that fix; merge if clean | None now | One more pass of review cost; U4b inherits the slug contract |
| **[2] Merge as is** | F-A and F-B become override rows (the cycle alone names briefs); U4b proceeds | None | A cycle that names a follow-up brief after its parent could apply the parent's answer to it |
| **[3] Rework the binding** | Bind each Asked: ID by a `Brief:` line in the entry body instead of the slug, defined in U4b's entry grammar | A follow-up unit's review | U4a merges later; U4b's entry grammar grows |

- **Blocks:** U4a's merge, hence U4b.
- **Interim:** [1] (the Q-138 precedent), applied 2026-10-13: fixed in daa09b5f; the second confirming pass found no new Must Fix or Must Address; U4a merged at 15a0d688. The entry stays open for your answer.
- **If the answer differs:** [2] reverts the narrow fix (two lines and a test); [3] adds a follow-up unit after U4b's entry grammar.


### Q-142 · u4b1-stop-path-worktree-remove
**Needs:** you: judgment · **Opened:** 2026-10-13 · **Status:** OPEN

U4b1's confirming pass found a new Medium in its own fix range (the skill's stop path removed the iteration's worktree without `--force`, whose clean check runs a filter planted in the repository's config): merge U4b1 after one more narrow fix, merge it as is, or rework how the orchestrator cleans up?

- **Why it's yours:** the loop passed its 3-iteration cap and the confirming pass that decides the merge found a Medium the range introduced, which by the rubric's gate stops the merge (the Q-138 / Q-141 precedent).
- **Read:** rubric `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4b1.md` (iteration-4 gate) on `feat/build-loop-u4b1`; `docs/reviews/security-review-2026-10-13-u4b1-confirm.md` F1, F2; `docs/reviews/code-fact-check-report-2026-10-13-u4b1-confirm.md` claims 7, 8, 11, 13.

Also open from the same pass, Medium, not introduced by the range: the bootstrap guard read the current tree, so one commit deleting every record's `Main at:` line reopened the bootstrap (no check of what moved main). Neither matters until U4c writes the D6 block and U4b2 writes `Main at:` lines; the skill text is the only change either needs.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] One more narrow fix, then merge** | `worktree remove --force` on both removal paths (no status run; uncommitted edits in WT are discarded), the bootstrap only when main's history never held a `Main at:` line (`git log -G`), `--main-log`'s other lines a dispatch block, not a stop; then a k=1 fact-check + security pass over that fix; merge if clean | None now | One more review pass; a stop discards the iteration's uncommitted cycle edits |
| **[2] Merge as is** | Both become override rows for U4b2/U4c | None | Until fixed, a stop could run a planted filter as the orchestrator, once the D6 block lands |
| **[3] Rework cleanup** | Leave WT in place on any stop and list it for removal by the user (a `you: terminal` entry), no removal by the orchestrator at all | A paste per stopped iteration | Worktrees pile up between your pastes (disk, slower import walks) |

- **Blocks:** U4b1's merge, hence U4b2.
- **Interim:** [1] (the Q-138 / Q-141 precedent), applied 2026-10-13 on `feat/build-loop-u4b1`; the second confirming pass runs next, and U4b1 merges if it finds no new Must Fix or Must Address. The entry stays open for your answer.
- **If the answer differs:** [2] reverts the narrow fix (skill text only); [3] replaces the two removal sentences with a terminal-entry rule.



### Q-146 · si-children-commit-rights
**Needs:** you: judgment · **Opened:** 2026-10-14 · **Status:** OPEN

How should the self-improvement loop's implementer children get the right to commit, given that the only grant in place today also gives arbitrary code execution?

- **Why it's yours:** it sets the trust boundary for an unattended loop on your machine, and it decides whether the loop resumes at all (Q-068 [3]).
- **Read:** `docs/working/si-trust-evidence-2026-10-14.md`: the verdict, F1, F2 and F5, and §5.

The script's own writes are confined, and the probe shows it. The children are not:
- With cwd `/workspace`, the project allowlist applies. `Bash(bats test:*)` together with `acceptEdits` lets a child write a test file and run it, and `git -C /workspace branch:*` lets it force-delete any branch (F1, F2).
- In a worktree or clone, `.claude/` is gitignored, so no allowlist applies. A child cannot run `git commit` (checked live), and every task fails Gate 1a after its tokens are spent (F5).

Under every option below, `REPO_DIR` points at a dedicated clone (§5.1), never at `/workspace`.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Script commits for the child** | The implementer only edits files. After it exits, the script runs `git add -A && git commit` in the worktree with a fixed message, and Gate 1c's file-scope check sees the result. Children get no Bash grants at all | One reviewed change to `self-improvement.sh` (about 20 lines plus tests) | The child's commit message and Confidence line are lost (the summary falls back to the task description), and children still can't run tests or `git diff` while they work |
| **[2] Narrow per-run settings** | The script writes a settings file granting exactly `git add`, `git commit`, `git diff` and `git status` (no `bats`, no `-C`) and passes it with `--settings` to every child | One reviewed change plus a host check that `--settings` stacks with the deny list as expected | The grant leaks wider than intended (the F1 shape again), or `--settings` precedence differs from the docs (unverified here: no egress) |
| **[3] Keep the loop dormant** | Q-068's "resume" stays conditional; the evidence report is the record | Nothing | The repo's idea generator stays off; the dev cycle's Ideas list stays its only source |

- **Blocks:** the live run with real children that Q-075 imagined, and so any resume of the loop.
- **Interim:** [3]. Nothing runs, so nothing is at risk.
- **If the answer differs:** [1] or [2] each become one build item (roadmap Next) followed by the live run in a dedicated clone. Neither undoes anything.

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
| **[1] Wide** (as written) | `workflows/ scripts/ test/ hooks/ devcontainer-config/ skills/ guides/ patterns/ templates/ global-instructions/`: self-merge lands only docs, `README.md`, `runs/` and `archive/` off the floor | Nearly every change comes to you as a merge entry | Self-merge buys little here; code fixes queue behind you |
| **[2] `workflows/` only** | The plan's interim: code self-merges when its brief lists it | None for listed code | A self-merged script or test runs in the next health check, and a self-merged `install.sh` runs on your host at the next release, unreviewed |
| **[3] None** | `Self-merge never: none` | None | Everything [2] risks, plus workflow changes that steer every later session here |

- **Blocks:** nothing while the policy is `review` (Q-103): the never line only narrows self-merge.
- **Interim:** [1], fail-closed.
- **If the answer differs:** a one-line edit to `docs/dev-cycle.md` (`none`, not an empty line, keeps self-merge possible) and its test line in `test/scripts/build-loop-read.bats`.

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
- **If the answer differs:** [2] is a change to the skill's step 10 slot count.

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
- **Interim:** [2]. `--settings` prints `constraints missing`, and step 10 files nothing more while this entry is open.
- **If the answer differs:** nothing to redo.

### Q-156 · image-lag
**Needs:** you: terminal · **Opened:** 2026-10-14 · **Status:** OPEN

Cut a release: rebuild and bless the image from main once `feat/build-loop-u5` has merged, so the installed dev-cycle skill and the gate it runs (the image copy, Q-140 [1]) carry the build-loop handoff as built.

- **Read:** `skills/dev-cycle/SKILL.md` step 0.1 (this entry's slug is the one step 0.1 files and rewrites) · decision log row 72 · plan D6 and F58

The image's commit C is `8d0e660e2e5a9769200500ac3dcfb4b113a32589` (`/opt/claude-workflows/.manifest`, assembled from `/home/magfrump/claude-workflows`), on main's first-parent history. M is `659a1c61f5b843ef574b90eb99a728ab84cf98d5`, the last commit on `feat/build-loop-u5` that changes anything the release installs; the branch's later commits change only `docs/`, so the merge's released trees equal M's. (Step 0.1's own rewrite of this entry uses main's commit as M.) At writing, main was `b279a2ba`. The image's dev-cycle skill lacks the D6 block (U4c), so the orchestrator loop cannot run as written until this release.

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

Paste on the host once `feat/build-loop-u5` has merged and the host checkout is on main (then launch a new sandbox). Before install.sh runs, with only `rev-parse` and `for-each-ref` (neither runs a hook or fsmonitor) and replace refs ignored, it checks that HEAD is main, that no replace ref or graft file exists (`git archive` in install.sh would honor either), and that the root `.gitattributes` and every directory the release installs from are the same tree at HEAD as at M; so it refuses when main has moved a released path past what this entry lists:

```bash
cd /home/magfrump/claude-workflows && ( export GIT_NO_REPLACE_OBJECTS=1; M=659a1c61f5b843ef574b90eb99a728ab84cf98d5; test "$(git rev-parse HEAD)" = "$(git rev-parse refs/heads/main)" || { echo "release refused: HEAD is not main"; exit 1; }; test -z "$(git for-each-ref refs/replace/)" || { echo "release refused: replace refs present"; exit 1; }; test ! -e "$(git rev-parse --git-common-dir)/info/grafts" || { echo "release refused: info/grafts present"; exit 1; }; for p in .gitattributes devcontainer-config global-instructions guides hooks patterns scripts skills workflows; do test "$(git rev-parse "HEAD:$p")" = "$(git rev-parse "$M:$p")" || { echo "release refused: $p differs from M"; exit 1; }; done ) && ./devcontainer-config/install.sh
```

- **Interim:** the image's older gate and skill run; the orchestrator loop is not started here before this release.
- **If the paste refuses:** main changed a released path after M. That change is not in the lists above; read `git log --first-parent M..main` before rewriting this entry with a new M.
