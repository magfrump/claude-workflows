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
| [Q-102](#q-102--default-test-parallelism) | you: judgment | `scripts/run-tests.sh --jobs 8` runs the full suite about 3× faster (140 s against 451 s serial), but no c... | 2026-09-30 |
| [Q-119](#q-119--u2a-split-at-cap) | you: judgment | U2a (the self-merge floor) hit the 3-iteration review cap, and the agent split it in /away mode: is the spl... | 2026-10-06 |
| [Q-084](#q-084--q076-live-checks) | you: terminal | Q-076 (`cc-push`, the exit scan) was verified only with bats: stubbed docker and local-path remotes, on git... | 2026-09-27 |
| [Q-109](#q-109--delete-merged-branches-2026-10-02) | you: terminal | Four local branches are fully merged into `main` (0 commits beyond it) and no brief names them. Deleting br... | 2026-10-02 |
| [Q-117](#q-117--verify-egress-resolve-time-ipset) | you: terminal | Live-verify `fix/egress-dnsmasq-ipset` (the dl.google.com fix) on the host before it merges. Answer `Q-117:... | 2026-10-05 |
| [Q-130](#q-130--q125-live-run) | you: terminal | Install the Q-125 branch on the host, rebuild and probe cc-isolated, then have a session run the sandbox ch... | 2026-10-07 |
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

### Q-117 · verify-egress-resolve-time-ipset
**Needs:** you: terminal · **Opened:** 2026-10-05 · **Status:** OPEN

Live-verify `fix/egress-dnsmasq-ipset` (the dl.google.com fix) on the host before it merges. Answer `Q-117: pass`, or paste the container block's output.

- **Why it's yours:** the rebuild runs on the host, and the sandbox can't run iptables or dnsmasq. The branch's 105 bats tests only cover how the config and rules are put together.
- **Read:** `docs/working/egress-android-build.md` (Correction section, on the branch) · `docs/decisions/038-sni-resolve-time-ipset.md` · `docs/reviews/security-review-2026-10-05-egress-sni-resolve-time-ipset.md`
- **What it proves:** four dnsmasq/kernel behaviours the fix assumes but nobody has observed: the ipset add lands before the reply goes out; matching is by query name, so addresses behind a CNAME are added; re-adding refreshes the 1 h timeout; CAP_NET_ADMIN survives dnsmasq dropping to its user. The firewall's own boot check covers the first and last. The rotation wait below covers the CNAME case, which is the real bug: before the fix, every fetch after Google moved the pool failed with `Errno 113`.

Two blocks, because they run in different shells. Edit the two `/path/to/...` lines first.

```bash
# --- HOST: install the branch's devcontainer config, then rebuild herald's container ---
cd /path/to/claude-workflows        # EDIT: your host checkout of this repo
git worktree add --detach ../cw-egress-verify fix/egress-dnsmasq-ipset   # --detach: the branch is checked out in an agent worktree
(cd ../cw-egress-verify && ./devcontainer-config/install.sh)              # read the diff (it is the rebuild gate), answer y
HERALD=/path/to/herald              # EDIT: the herald repo
cc-isolated --probe-only "$HERALD" && cc-isolated "$HERALD"
```

```bash
# --- CONTAINER: in the rebuilt herald session's shell. Takes up to ~45 min (waits for a pool rotation). ---
U=https://dl.google.com/dl/android/maven2/com/android/application/com.android.application.gradle.plugin/8.7.3/com.android.application.gradle.plugin-8.7.3.pom
L=/run/cc-sni-proxy/proxy.log
echo "firewall marker: $(cat /run/cc-firewall/complete 2>&1)"
echo "dnsmasq instances (expect 2): $(pgrep -u dnsmasq dnsmasq | wc -l)"
echo "fetch 1 (expect 200): $(curl -sS -m 10 -o /dev/null -w '%{http_code}' "$U")"
first=$(grep -oE 'ALLOW sni=dl\.google\.com -> [0-9.]+' "$L" | tail -1 | awk '{print $4}')
echo "first ALLOW address: ${first:-NONE}"
echo "waiting for the pool to drop $first (polls every 30 s, gives up after 45 min)..."
for i in $(seq 1 90); do getent ahostsv4 dl.google.com | awk '{print $1}' | grep -qxF "$first" || break; sleep 30; done
echo "pool now: $(getent ahostsv4 dl.google.com | awk '{print $1}' | sort -u | tr '\n' ' ')"
echo "fetch 2 (expect 200): $(curl -sS -m 10 -o /dev/null -w '%{http_code}' "$U")"
echo "FAIL lines for dl.google.com (expect 0): $(grep -c 'FAIL sni=dl\.google\.com' "$L")"
grep -E 'sni=dl\.google\.com' "$L" | tail -5
```

**Pass** = 2 instances, both fetches 200, 0 FAIL lines, and "pool now" no longer lists the first ALLOW address. If the loop gave up with the address still listed, the pool didn't rotate; run the container block again later.

- **Blocks:** merging `fix/egress-dnsmasq-ipset`; herald's Android build.
- **Interim:** branch unmerged. Herald works around it by restarting its container (the firewall re-resolves at startup) and building straight away. Separately, herald should set `buildToolsVersion = "35.0.0"`.
- **If it fails:** paste the output. To put the host back on main's config, run `./devcontainer-config/install.sh` from your main checkout. Either way, finish with `git worktree remove ../cw-egress-verify`.

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

### Q-109 · delete-merged-branches-2026-10-02
**Needs:** you: terminal · **Opened:** 2026-10-02 · **Status:** OPEN

Four local branches are fully merged into `main` (0 commits beyond it) and no brief names them. Deleting branches needs your approval:

```
git -C /workspace branch -d feat/hook-refuse-redirects feat/run-tests-jobs feat/workflow-router-skills fix/agents-md-no-imports
```

- **Interim:** the branches stay. They cost nothing but clutter.

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

### Q-102 · default-test-parallelism
**Needs:** you: judgment · **Opened:** 2026-09-30 · **Status:** OPEN

`scripts/run-tests.sh --jobs 8` runs the full suite about 3× faster (140 s against 451 s serial), but no caller passes `--jobs`. Should health-check.sh and pr-prep's test gate run in parallel by default?

- **Why it's yours:** it trades wall time on every gate against a small flake risk, in the checks you rely on.
- **Read:** Q-090 (archive) · the "Parallel runs" section of the `scripts/run-tests.sh` header · `docs/reviews/code-review-rubric-2026-09-30-feat-run-tests-jobs.md`

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Parallel by default, with an env override** | health-check and pr-prep pass `--jobs 8` (a `RUN_TESTS_JOBS`-style variable picks N, and 1 means serial). Falls back to serial when there is no GNU parallel. | A small reviewed change | A timing race shows up as a flaky gate. So far that is 1 in about 13 runs, since fixed. You re-run, or set N=1. |
| **[2] Opt-in only** | Callers stay serial; agents and you pass `--jobs` by hand | None | Every gate keeps costing about 7.5 min instead of 2.5 min, and agents rarely remember the flag |

- **Interim:** [2]. Nothing calls `--jobs` yet.
- **If the answer differs:** nothing to redo.

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

### Q-130 · q125-live-run
**Needs:** you: terminal · **Opened:** 2026-10-07 · **Status:** OPEN

Install the Q-125 branch on the host, rebuild and probe cc-isolated, then have a session run the sandbox checks.

```
cd ~/claude-workflows && git worktree add --detach /tmp/q125-install feat/q125-cc-isolated-sandbox && /tmp/q125-install/devcontainer-config/install.sh; git -C ~/claude-workflows worktree remove /tmp/q125-install
cc-isolated --probe-only ~/claude-workflows && cc-isolated ~/claude-workflows
```

Then, in that session, type: `Run bash docs/working/live-check-q125.sh with your Bash tool (not !), then run it again with --watch in the background while I /login, and paste me every RESULT line.`

- **Read:** `docs/working/live-check-q125.sh` (on the branch) says what C1–C10 test. It aborts before any write if the credential is readable. Plan step 6 is the spec.
- **Before you paste:** install.sh refuses while any Claude Code process runs on the host (Q-058), so close sessions first. Say **y** to target 1 (devcontainer config) and **N** to target 2 (host `~/.claude`). Target 2 records the repo it ran from as canonical, and this one is a temp worktree that the paste deletes. The branch changes nothing there anyway.
- **What the answer decides:**
  - The session fails to start with `sandbox required but unavailable` → the sandbox broke on the real image. Paste that error; the rollback is install.sh from main (plan Rollback).
  - Every RESULT is pass → pr-prep runs per unit, then U1 and U2 merge with `Live-verified: <the hash cc-isolated --list shows>`.
  - Any FAIL → the agent fixes it on U2 and you re-run this entry.
- **Blocks:** Q-125's merge, and Q-098.
- **Interim:** every cc-isolated project now runs the branch's config until install.sh is re-run from main. To back out, run the same paste with `main` in place of the branch.

### Q-089 · host-tools-trust-category
**Needs:** agent · **Opened:** 2026-09-28 · **Status:** OPEN

Implement Q-083 [1]: host-only tools (`cc-push.sh`, `cc-exit-scan.sh`, `cc-gitdir.sh`) get their own trust-manifest section and commit trailer (e.g. `Host-tool-tested:`) instead of `Live-verified:`; `cc-push` verifies its own hash before running; `check_manifest` stops blocking cc-isolated launches when only a host tool changed; decision log row 45 is amended.

- **Read:** `docs/reviews/q076-architecture-review-2026-09-27.md` Finding 3 · decision log 45 · `hooks/live-verify-gate.sh` · `enforcement_files` in `devcontainer-config/cc-isolated.sh`.
- **Constraint:** this changes enforcement files, so per RPI step 3 the plan's pre-mortem lists the bypass families (e.g. a tampered cc-push that skips its own check, a manifest section swap) and marks each covered or not before implementing. The unit counts against the ~400-line cap (decision log 62).
- **Interim:** host tools stay in the enforcement set (Q-083's interim [2]).


### Q-119 · u2a-split-at-cap
**Needs:** you: judgment · **Opened:** 2026-10-06 · **Status:** OPEN

U2a (the self-merge floor) hit the 3-iteration review cap, and the agent split it in /away mode: is the split, and the redesign it carries, the right call?

- **Why it's yours:** the split replaces "model every tree shape" with "refuse what is not modelled", which makes self-merge refuse every path in a repo holding an odd name. That trades reach for safety on a gate you will rely on.
- **Read:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md` (iterations 1-3 and the gate decision, on branch `feat/build-loop-u2a`) · plan step 5's U2 split note

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Keep the split** | U2a1 (lib wording, `badform`, `isclosed`, constraints.md for `--check-fix`, U1d rows) lands now; U2a2 rebuilds the floor's import walk to fail closed on newline names, absolute or newline symlink text and `..` names, on a fresh 3-iteration loop. | None now. | A repo with such a name gets no self-merge until it is renamed; the refusal names the reason. |
| **[2] Escalate instead** | Undo the split; you review the three iterations and authorize more iterations on one unit. | Reading three rubric sections. | The loop keeps finding one new shape per pass, as it did three times. |
| **[3] Abandon the commit-reading walk** | Run the import walk in a clean worktree checked out at main's commit (the plan's other option) instead. | None now; a design change in U2b. | A checkout costs time per `--check` and touches disk the gate otherwise never writes. |

- **Blocks:** nothing; U2a1 lands, U2a2 proceeds under [1].
- **Interim:** [1]. Split recorded in the U2a rubric and commit e8f76379 on `feat/build-loop-u2a`.
- **Update 2026-10-06:** under [1], U2a2 (the floor plus the walk, 400 code lines before U2a1's carried rows) was split again, then once more at its review's iteration 2 (fixes and tests put it near 480 lines): U2a2 is the shared token parser and `isimported tree`, U2a3 the commit-reading walk, U2a4 the floor. No new judgment: the same refuse-what-is-not-modelled walk, in smaller units. Under [3], U2a3 is the unit replaced.
- **Update 2026-10-08:** U2b was split the same way before any code, for size alone (tests count toward the cap): U2b1a (`--check`'s frame: hardened git, state gate, `--expect`, merge-tree), U2b1b (the changed paths and the N rules), U2b2 (the gate's checkout), U2b3 (the reader model). Plan step 5's U2b split note lists each. No new judgment; commit d0199be6 on `feat/build-loop-u2b1a`. At review iteration 2 U2b1a split again for size (439 lines): U2b1a1 (the reader side `--status` uses) lands first, then U2b1a2 (`--check`); plan step 5's note.
- **If the answer differs:** [2] reverts nothing on main (U2a1 stands either way); [3] replaces U2a3's walk.


