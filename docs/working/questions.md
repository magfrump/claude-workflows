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
| [Q-139](#q-139--workspace-hookspath-fails-state-gate) | you: judgment | `/workspace/.git/config` sets `core.hooksPath` to `/home/magfrump/claude-workflows/.git/hooks` (the host sp... | 2026-10-12 |
| [Q-140](#q-140--d6-snippet-trust-root) | you: judgment | Which copy of the gate should the D6 snippet run, and what decides it? | 2026-10-12 |
| [Q-141](#q-141--u4a-asked-binding-residue) | you: judgment | U4a's confirming pass found the Asked: brief binding still matches the wrong brief in one naming shape: mer... | 2026-10-13 |
| [Q-142](#q-142--u4b1-stop-path-worktree-remove) | you: judgment | U4b1's confirming pass found a new Medium in its own fix range (the skill's stop path removed the iteration... | 2026-10-13 |
| [Q-084](#q-084--q076-live-checks) | you: terminal | Q-076 (`cc-push`, the exit scan) was verified only with bats: stubbed docker and local-path remotes, on git... | 2026-09-27 |
| [Q-075](#q-075--si-loop-trust-before-resume) | agent | Q-068 was answered "resume", but only once the user trusts `scripts/self-improvement.sh` not to break their... | 2026-09-27 |
| [Q-079](#q-079--canon-instance-proposal-filter) | agent | Design, per Q-072, (a) a script that turns a commit or commit range into a canon instance, and (b) the high... | 2026-09-27 |
| [Q-089](#q-089--host-tools-trust-category) | agent | Implement Q-083 [1]: host-only tools (`cc-push.sh`, `cc-exit-scan.sh`, `cc-gitdir.sh`) get their own trust-... | 2026-09-28 |
| [Q-092](#q-092--drop-hook-deny-reader) | agent | Per Q-082's answer (`permissions.deny` beats a hook `allow`), remove the Bash deny reader from `hooks/auto-... | 2026-09-28 |
| [Q-096](#q-096--exit-scan-insteadof-target) | agent | The exit scan records a `url.<base>.insteadOf` / `pushInsteadOf` base but never the URL it rewrites to, inc... | 2026-09-28 |
| [Q-097](#q-097--exit-scan-older-routes) | agent | The Q-094 review documented two older Medium routes the exit scan does not see, both now under the guide's ... | 2026-09-28 |
| [Q-107](#q-107--claude-home-payload-second-consumer) | agent | Decision 036's trigger fired: "if a second consumer of the claude-home payload appears → [11]'s seam is o... | 2026-10-02 |
| [Q-108](#q-108--decision-037-stale-lines) | agent | Decision 037 has two stale lines. Line 58 says "035's still-pending regex", but the regex landed in addae61... | 2026-10-02 |
| [Q-110](#q-110--health-check-not-run-undercount) | agent | In one `scripts/health-check.sh` run (2026-10-02, main at 188e0a7d), the test runner printed `NOT RUN: 50 r... | 2026-10-02 |
| [Q-125](#q-125--build-cc-isolated-sandbox) | agent | Implement Q-124 [1] as an RPI unit. Add a seccomp profile file: Docker's default with `unshare` and `clone`... | 2026-10-07 |
| [Q-067](#q-067--regenerate-skill-eval-reports) | deferred | When should the skill eval reports be regenerated, so that the 50 `@needs-reports` suites constrain the cur... | 2026-09-26 |
| [Q-098](#q-098--global-allowlist-after-sandbox) | deferred | Ship a global `permissions.allow` in `hooks/wiring.json` once cc-isolated has a Bash sandbox (Q-088). Branc... | 2026-09-28 |
| [Q-103](#q-103--dev-cycle-build-loop-policy) | deferred | Once the build-loop handoff exists, may its build loops merge their own branches in claude-workflows, or mu... | 2026-10-01 |
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
**Needs:** deferred · **Opened:** 2026-10-01 · **Status:** OPEN

Once the build-loop handoff exists, may its build loops merge their own branches in claude-workflows, or must each stop for your review?

- **Why it's yours:** you said this depends on the project and is settled at onboarding; claude-workflows was onboarded before the setting existed.
- **Read:** `docs/working/seed-build-loop-handoff.md` · `docs/dev-cycle.md` · decision log row 68
- **Deferred 2026-10-01:** the handoff was split out of `feat/dev-cycle`; nothing reads this setting until it lands. Becomes `you: judgment` then.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] review** | Each loop runs pr-prep's review-fix loop and stops; the next cycle files one "merge <branch>?" entry (no PRs here) and merges once you approve | One decision per finished item | Finished work queues up behind you; at most 3 items in flight |
| **[2] self-merge** | Each loop lands its branch through pr-prep's local merge on its own, but only for work outside what later runs follow unreviewed (the seed's list: hooks, enforcement and harness settings, instruction files, skills/, workflows/, scripts/, guides/, patterns/, templates/, test/, devcontainer-config/); anything else still stops for review | None for that work, which here is mostly docs; most work in this repo still comes to you as under [1] | A bad change that pr-prep's automated review misses lands on main; afterwards the next cycle's health check, spot-check (2 sampled merges by default) and code-without-docs check might catch it |

- **Interim:** [1] `review`, recorded as `Build-loop policy: review (interim; Q-103)`. Nothing reads it until the handoff unit lands; its design counts that line as unset, which means `review`.
- **If the answer differs:** nothing to redo. Either answer is recorded the same way: in `docs/dev-cycle.md`, replace the policy line with `Build-loop policy: review` ([1]) or `Build-loop policy: self-merge` ([2]) and delete the paragraph starting "Interim note:".

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

### Q-075 · si-loop-trust-before-resume
**Needs:** agent · **Opened:** 2026-09-27 · **Status:** OPEN

Q-068 was answered "resume", but only once the user trusts `scripts/self-improvement.sh` not to break their setup. Build the evidence for that: list every path, config, hook, credential and git ref the loop can write outside its own working docs, then run it once hermetically with every env-overridable destination redirected, and diff the setup before and after.

- **Read:** `archive/docs/2026-09-18-handoff-self-improvement-loop.md` §4–§5 · memory [[prove-old-code-fails-hermetically]]
- **Interim:** the loop stays dormant.
- **If the answer differs:** n/a. The output is a report the user reads before the first real run.

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


### Q-140 · d6-snippet-trust-root
**Needs:** you: judgment · **Opened:** 2026-10-12 · **Status:** OPEN

Which copy of the gate should the D6 snippet run, and what decides it?

- **Why it's yours:** it changes plan D6's trust root (main's copy, live at the next merge, vs the root-owned image copy) and may need a container setting; both are your design calls.
- **Read:** U3b3's rubric `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b3.md` (final pass, C1); `docs/reviews/security-review-2026-10-12-u3b3-final.md` F1; `docs/reviews/architecture-review-2026-10-12-u3b3-final.md` F1; override rows dated 2026-10-12 for `feat/build-loop-u3b3` (the trust-root row); `test/lib/d6-snippet.bash` header.

Today the snippet runs main's own scripts when main's first-parent root commit is claude-workflows' 640cf007, else the root-owned image copy under /opt. That test reads the repository it is judging. In another project, a loop that moves main onto a copy of 640cf007's public commit gets its own scripts run instead of the image copy. In any project, a loop that rewrites the orchestrator worktree's `.git` file to point at a crafted repository does the same, and in claude-workflows --main-log then sees nothing. (A third route, a late `parent` line, was a parse bug and is fixed.)

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Always the image copy** | The snippet drops main's-copy and always runs /opt's root-owned scripts (closes all three routes; no history walk) | None now; in claude-workflows a gate change takes effect only after a release (gate code already needs a merge-gate- review) | A gate fix waits a release to protect the loop that found it |
| **[2] A trusted outside signal** | Main's copy only when the root test passes AND a value set in the claude-workflows container definition (the caller's environment, trusted) says so | One devcontainer change (an enforcement file: live-verify) and a matching host setting | The gitfile route still works inside claude-workflows; a missing setting silently means /opt |
| **[3] Leave it to Q-103** | Keep today's rule; the routes need a loop that moves main or rewrites the orchestrator's `.git`, the hostile-loop class Q-103 rules on | None | A hostile loop in another project runs its own gate, which can also hide the move it made |

- **Blocks:** U4 writing the selector into SKILL.md (U3b3 merges with the gap named).
- **Interim:** today's rule stays, documented as a known gap in the snippet's header and the plan note; nothing runs the snippet until U4.
- **If the answer differs:** [1] deletes the verified reader and the root test (the snippet keeps its ref and ownership checks; about 30 lines and five tests go); [2] adds one check before the reader and a container setting.

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

