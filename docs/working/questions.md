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
| [Q-103](#q-103--dev-cycle-build-loop-policy) | you: judgment | May the dev cycle's build loops (step 6b) merge their own branches in claude-workflows, or must each stop f... | 2026-10-01 |
| [Q-084](#q-084--q076-live-checks) | you: terminal | Q-076 (`cc-push`, the exit scan) was verified only with bats: stubbed docker and local-path remotes, on git... | 2026-09-27 |
| [Q-075](#q-075--si-loop-trust-before-resume) | agent | Q-068 was answered "resume", but only once the user trusts `scripts/self-improvement.sh` not to break their... | 2026-09-27 |
| [Q-079](#q-079--canon-instance-proposal-filter) | agent | Design, per Q-072, (a) a script that turns a commit or commit range into a canon instance, and (b) the high... | 2026-09-27 |
| [Q-088](#q-088--spike-weaker-nested-sandbox) | agent | Spike, per Q-081 [2]: can Claude Code's `sandbox.enableWeakerNestedSandbox` run Bash sandboxed inside cc-is... | 2026-09-28 |
| [Q-089](#q-089--host-tools-trust-category) | agent | Implement Q-083 [1]: host-only tools (`cc-push.sh`, `cc-exit-scan.sh`, `cc-gitdir.sh`) get their own trust-... | 2026-09-28 |
| [Q-092](#q-092--drop-hook-deny-reader) | agent | Per Q-082's answer (`permissions.deny` beats a hook `allow`), remove the Bash deny reader from `hooks/auto-... | 2026-09-28 |
| [Q-096](#q-096--exit-scan-insteadof-target) | agent | The exit scan records a `url.<base>.insteadOf` / `pushInsteadOf` base but never the URL it rewrites to, inc... | 2026-09-28 |
| [Q-097](#q-097--exit-scan-older-routes) | agent | The Q-094 review documented two older Medium routes the exit scan does not see, both now under the guide's ... | 2026-09-28 |
| [Q-067](#q-067--regenerate-skill-eval-reports) | deferred | When should the skill eval reports be regenerated, so that the 50 `@needs-reports` suites constrain the cur... | 2026-09-26 |
| [Q-098](#q-098--global-allowlist-after-sandbox) | deferred | Ship a global `permissions.allow` in `hooks/wiring.json` once cc-isolated has a Bash sandbox (Q-088). Branc... | 2026-09-28 |
| [Q-074](#q-074--failure-pattern-writer-trigger) | trigger | After the Q-018 backfill (164 entries), `docs/thoughts/failure-patterns.md` has gained 1 entry across about... | 2026-09-26 |
| [Q-090](#q-090--run-tests-jobs) | trigger | When `parallel` is present in the image (Q-084 step 4 prints a version), add `--jobs N` to `scripts/run-tes... | 2026-09-28 |
<!-- index:end -->

## Open

### Q-103 · dev-cycle-build-loop-policy
**Needs:** you: judgment · **Opened:** 2026-10-01 · **Status:** OPEN

May the dev cycle's build loops (step 6b) merge their own branches in claude-workflows, or must each stop for your review?

- **Why it's yours:** you said this depends on the project and is settled at onboarding; claude-workflows was onboarded before the setting existed.
- **Read:** `skills/dev-cycle/SKILL.md` step 6b · `docs/dev-cycle.md` · decision log row 68

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] review** | Each loop runs pr-prep's review-fix loop and stops; the next cycle files one "merge <branch>?" entry (no PRs here) and merges once you approve | One decision per finished item | Finished work queues up behind you; at most 3 items in flight |
| **[2] self-merge** | Each loop lands its branch through pr-prep's local merge on its own, but only for work outside skills/, workflows/, scripts/, test/, guides/ and instruction files; anything else still stops for review | None for that work, which here is mostly docs; most work in this repo still comes to you as under [1] | A bad change that pr-prep's automated review misses lands on main; afterwards the next cycle's health check, spot-check (2 sampled merges by default) and code-without-docs check might catch it |

- **Interim:** [1] `review`, recorded as `Build-loop policy: review (interim; Q-103)`; the skill counts that line as unset (so `review`) and does not re-ask while this entry is open.
- **On either answer:** in `docs/dev-cycle.md`, replace the policy line with `Build-loop policy: review` ([1]) or `Build-loop policy: self-merge` ([2]) and delete the paragraph starting "Interim note:".

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

- **Interim:** every enforcement-file commit on Q-076 carries `Live-verified: no`.
- **If the answer differs:** a refusal on step 3, a warning on step 1, or a version refused that git's release notes list as fixed means a follow-up fix. Also check git's May 2024 security release notes against the version list in the `cc-push.sh` header, which was written from memory.

### Q-096 · exit-scan-insteadof-target
**Needs:** agent · **Opened:** 2026-09-28 · **Status:** OPEN

The exit scan records a `url.<base>.insteadOf` / `pushInsteadOf` base but never the URL it rewrites to, including at the top level, so a session can repoint a remote through a rewrite the scan does not follow. Found in the Q-094 review and now listed in the guide's "Known routes it does not see". Close it: the rewritten local-path target is walked as a remote, as `_snap_remote` does for `remote.*.url`.

- **Read:** Q-094 rubric `docs/reviews/code-review-rubric-2026-09-28-q094-exit-scan-worktree-layout.md` · `_snap_config` / `_snap_remote` in `devcontainer-config/cc-exit-scan.sh`
- **Constraint:** enforcement file: pre-mortem with bypass families first (decision log 61), under the 400-line cap. Start after Q-094's branches merge (same file).
- **Interim:** documented as a known route. cc-push, which runs no git in the checkout, is still the way to push.

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
- **Trigger:** Q-088 answers [1] (build the sandbox) and the sandbox denies reads of `~/.claude/.credentials.json` and writes to `~/.claude/settings*.json`. Then re-run the leak list inside it before merging any list.
- **Interim:** no global allow list. cc-isolated sessions prompt for commands not in their project's `.claude/settings.json`.

### Q-092 · drop-hook-deny-reader
**Needs:** agent · **Opened:** 2026-09-28 · **Status:** OPEN

Per Q-082's answer (`permissions.deny` beats a hook `allow`), remove the Bash deny reader from `hooks/auto-approve-allowed-commands.sh`: the settings-file deny loading, `--deny`, the de-quoted matching and their tests. Update the hook header's rule table to match. This is architecture-review finding 1 on Q-076.

- **Read:** Q-082 in the archive · decision log 53 (amended 2026-09-28) · the hook header
- **Constraint:** this changes an enforcement file, so the plan's pre-mortem lists the bypass families and marks each covered or not before implementing. One case to check explicitly: the host result covers `allow` only. If the hook can ever emit `ask` (#39344 shows `ask` overriding deny), the reader may still be needed on that path.
- **Interim:** the reader stays. It is redundant for `allow`, not harmful.

### Q-088 · spike-weaker-nested-sandbox
**Needs:** agent · **Opened:** 2026-09-28 · **Status:** OPEN

Spike, per Q-081 [2]: can Claude Code's `sandbox.enableWeakerNestedSandbox` run Bash sandboxed inside cc-isolated without allowing user namespaces (Docker's default seccomp gives `unshare -Ur` → EPERM)? Success: a sandboxed Bash call in a cc-isolated container that has `bubblewrap` and `socat` but unchanged seccomp/runArgs, with a read of `~/.claude/.credentials.json` refused. Failure: bwrap still needs user namespaces, or the weaker mode drops the filesystem restriction. Then come back with [1] (build the full sandbox) or [3] (accept deny + container) as a `you: judgment` entry.

- **Read:** Q-081 in the archive · the auto-approve hook header · decision log 53.
- **Constraint:** the image has no bwrap/socat and this sandbox has no egress, so the live half needs a Dockerfile branch (an enforcement file) and one host run. Keep that branch unmerged until the spike's answer is in.
- **Interim:** nothing sandboxes Bash in cc-isolated (Q-081's interim [3]).

### Q-089 · host-tools-trust-category
**Needs:** agent · **Opened:** 2026-09-28 · **Status:** OPEN

Implement Q-083 [1]: host-only tools (`cc-push.sh`, `cc-exit-scan.sh`, `cc-gitdir.sh`) get their own trust-manifest section and commit trailer (e.g. `Host-tool-tested:`) instead of `Live-verified:`; `cc-push` verifies its own hash before running; `check_manifest` stops blocking cc-isolated launches when only a host tool changed; decision log row 45 is amended.

- **Read:** `docs/reviews/q076-architecture-review-2026-09-27.md` Finding 3 · decision log 45 · `hooks/live-verify-gate.sh` · `enforcement_files` in `devcontainer-config/cc-isolated.sh`.
- **Constraint:** this changes enforcement files, so per RPI step 3 the plan's pre-mortem lists the bypass families (e.g. a tampered cc-push that skips its own check, a manifest section swap) and marks each covered or not before implementing. The unit counts against the ~400-line cap (decision log 62).
- **Interim:** host tools stay in the enforcement set (Q-083's interim [2]).

### Q-090 · run-tests-jobs
**Needs:** trigger · **Opened:** 2026-09-28 · **Status:** OPEN

When `parallel` is present in the image (Q-084 step 4 prints a version), add `--jobs N` to `scripts/run-tests.sh` (suite-level `bats --jobs`, serial when `parallel` is missing) and measure the full-suite wall time against the 742 s serial baseline. install-host.bats, the slowest suite, bounds the speedup.

- **Interim:** the suite stays serial.
- **From the Q-086 review (C2, C5):** `bats --jobs N` with N>1 aborts without `parallel` even on one file, so the serial fallback must test `command -v parallel`, not the file count. bats runs `parallel` without `--will-cite`, so check its citation notice and Perl locale warnings stay out of test output. `--jobs` also parallelizes tests *within* a file, and install-host.bats may flake, since `install.sh`'s `procs_in_checkout` scans the real /proc; consider `--no-parallelize-within-files`.
