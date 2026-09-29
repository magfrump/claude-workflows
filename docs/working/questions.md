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
| [Q-093](#q-093--cc-push-commondir-recurs) | you: judgment | `.git/commondir` came back after Q-091 [1] removed it, and you deleted it again to get `cc-push` through. R... | 2026-09-28 |
| [Q-094](#q-094--exit-scan-worktree-noise) | you: judgment | Every cc-isolated session that leaves an agent worktree behind exits with the full WARNING (exit 3), becaus... | 2026-09-28 |
| [Q-095](#q-095--allowlist-size-waiver) | you: judgment | Branch `feat/wiring-allowlist` (5d929dd) adds the host's 857-rule allow list to `hooks/wiring.json`, so eve... | 2026-09-28 |
| [Q-084](#q-084--q076-live-checks) | you: terminal | Q-076 (`cc-push`, the exit scan) was verified only with bats: stubbed docker and local-path remotes, on git... | 2026-09-27 |
| [Q-075](#q-075--si-loop-trust-before-resume) | agent | Q-068 was answered "resume", but only once the user trusts `scripts/self-improvement.sh` not to break their... | 2026-09-27 |
| [Q-079](#q-079--canon-instance-proposal-filter) | agent | Design, per Q-072, (a) a script that turns a commit or commit range into a canon instance, and (b) the high... | 2026-09-27 |
| [Q-088](#q-088--spike-weaker-nested-sandbox) | agent | Spike, per Q-081 [2]: can Claude Code's `sandbox.enableWeakerNestedSandbox` run Bash sandboxed inside cc-is... | 2026-09-28 |
| [Q-089](#q-089--host-tools-trust-category) | agent | Implement Q-083 [1]: host-only tools (`cc-push.sh`, `cc-exit-scan.sh`, `cc-gitdir.sh`) get their own trust-... | 2026-09-28 |
| [Q-092](#q-092--drop-hook-deny-reader) | agent | Per Q-082's answer (`permissions.deny` beats a hook `allow`), remove the Bash deny reader from `hooks/auto-... | 2026-09-28 |
| [Q-067](#q-067--regenerate-skill-eval-reports) | deferred | When should the skill eval reports be regenerated, so that the 50 `@needs-reports` suites constrain the cur... | 2026-09-26 |
| [Q-074](#q-074--failure-pattern-writer-trigger) | trigger | After the Q-018 backfill (164 entries), `docs/thoughts/failure-patterns.md` has gained 1 entry across about... | 2026-09-26 |
| [Q-090](#q-090--run-tests-jobs) | trigger | When `parallel` is present in the image (Q-084 step 4 prints a version), add `--jobs N` to `scripts/run-tes... | 2026-09-28 |
<!-- index:end -->

## Open





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

### Q-093 · cc-push-commondir-recurs
**Needs:** you: judgment · **Opened:** 2026-09-28 · **Status:** ANSWERED

**Answer (2026-09-28): [1].** Relax cc-push to accept a `commondir` whose whole content is `.`. Implemented as its own enforcement unit (branch `q093-cc-push-self-commondir`, `Live-verified: no`); the host rerun of Q-084 step 3 without deleting the file is the live check.

`.git/commondir` came back after Q-091 [1] removed it, and you deleted it again to get `cc-push` through. Relax cc-push now (Q-091's fallback), or keep deleting it by hand until the writer is found?

- **What is known:** the host runs 2.1.284, the build whose code Q-091 read. So "2.1.284 no longer creates `commondir`" was wrong, or something else writes it. This container has no bwrap and no `sandbox` setting. This session's commands did not recreate the file: it was still absent after them. The deletion removed the file's mtime, the one clue to its writer.
- **One fact that would pin the writer (optional, one line):** did any exit WARNING today include `+ commondir-file …/claude-workflows/.git/commondir` (with no `worktrees/` in the path)? Yes means a cc-isolated session wrote it. No, with a host `claude` session in this repo since the first rm, points to the host sandbox.
- **Read:** Q-091 in the archive · `devcontainer-config/cc-push.sh:272`

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Relax cc-push (Recommended)** | Accept a `commondir` whose whole content is `.`. That is a self-reference, which git reads exactly as if the file were absent. Refuse everything else as today. This is Q-091's [2]. | An enforcement-file unit: review loop, re-bless, one host rerun of Q-084 step 3 | A parsing bug (e.g. `./`, trailing bytes, a symlinked file) reopens the read-outside-the-checkout hole. Tests must pin the exact accepted bytes. |
| **[2] Keep deleting by hand** | `rm ~/claude-workflows/.git/commondir` before each push. Nothing changes in code. | One command per push, for as long as the writer runs | Nothing unsafe. Friction only, and the writer stays unknown. |

- **Interim:** [2]. Delete by hand before `cc-push`. The exit scan still reports a new `commondir` if a container session writes one.
- **If the answer differs:** nothing is built yet, so nothing is redone.

### Q-094 · exit-scan-worktree-noise
**Needs:** you: judgment · **Opened:** 2026-09-28 · **Status:** ANSWERED

**Answer (2026-09-28): [1].** The exit scan accepts git's standard linked-worktree layout with a `note:` line and exit 0; anything else still warns. Implemented as its own enforcement unit (branch `q094-exit-scan-worktree-layout`, `Live-verified: no`); the live check is a host session that leaves an agent worktree behind and exits 0.

Every cc-isolated session that leaves an agent worktree behind exits with the full WARNING (exit 3), because the worktree's `.git` file, its `commondir` and its missing `hooks/` dir are new records. Should the exit scan accept git's own worktree layout without a warning?

- **Why it's yours:** it trades warning fatigue against the scan's strictness, in an enforcement file.
- **Read:** Q-084's 2026-09-28 step 3 note (the reproduction) · `_snap_gitdir` / `_snap_nested` in `devcontainer-config/cc-exit-scan.sh` · memory [[agent-worktrees-stall-and-stale-base]] (worktrees often outlive the session)

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Accept the standard layout (Recommended)** | A new worktree passes with one `note:` line and exit 0 only when: its `.git` file names `<common>/worktrees/<name>`, that dir's `commondir` is exactly `../..`, and it has no `hooks/`, no `config.worktree` and no symlinks. Any other difference still warns. A linked worktree takes its config and hooks from the common dir, which the scan already covers [inferred; the plan's pre-mortem checks this]. | An enforcement unit: review loop, re-bless, a host rerun | If a linked worktree can run something the common dir does not show, a plant shaped like a standard worktree passes silently. |
| **[2] Clean up before exit** | Scan unchanged. Remove and prune worktrees before leaving a session, e.g. via a reminder at session end. | Your time each session, and a worktree with unmerged work cannot be removed | Warning fatigue: a real plant listed among worktree lines gets skimmed past. |
| **[3] Leave as is** | Every such exit warns. | Reading the list each time | Same fatigue as [2], every time. |

- **Interim:** [3]. Nothing changes. Q-084 step 1 is still testable on a scratch repo with no worktrees.
- **If the answer differs:** nothing is built yet.

### Q-095 · allowlist-size-waiver
**Needs:** you: judgment · **Opened:** 2026-09-28 · **Status:** OPEN

Branch `feat/wiring-allowlist` (5d929dd) adds the host's 857-rule allow list to `hooks/wiring.json`, so every cc-isolated session gets it at container start. The unit is 915 changed code lines, over the ~400-line review cap (decision log 62), and almost all of it is one flat data list. Waive the cap for this unit?

- **Why it's yours:** only you can waive the cap.
- **Read:** `git show 5d929dd` · the new `_comment` lines in `hooks/wiring.json` · decision log 62

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Waive (Recommended)** | Review it as one unit: read the comment, the tests and the two dropped rules, and skim the list against your host copy. | One review pass | A bad rule hides in a long list; it can only widen `allow`, never beat a deny. |
| **[2] Split by rule group** | Stack units of under 400 lines each (e.g. core/git, language toolchains, cloud/infra), each with its own review loop. | Three or four review loops over what is a verbatim copy | Loop overhead with no gain in scrutiny. |
| **[3] Trim, then review** | Cut the list to the rules that matter in a Linux container (drop macOS-only, cloud CLIs with no credentials), aiming under 400. | Deciding what to cut | The list diverges from the host copy; later syncs need a diff by hand. |

- **Interim:** the branch is committed and unmerged; nothing is installed.
- **If the answer differs:** [2] re-cuts the one commit into stacked branches; [3] edits the list, then reviews.

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
