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
| [Q-233](#q-233--merge-gate-2026-10-29-convention-migrations-first-b001677ac0d8) | you: judgment | Merge `feat/convention-migrations-first` at b001677ac0d8ce334290dfc6d7b055534ea49960 (brief `docs/working/b... | 2026-10-29 |
| [Q-084](#q-084--q076-live-checks) | you: terminal | Q-076 (`cc-push`, the exit scan) was verified only with bats: stubbed docker and local-path remotes, on git... | 2026-09-27 |
| [Q-167](#q-167--post-install-host-probes) | you: terminal | The install is done: the image was built from main at fbe67674 on 2026-10-16 (Q-156), and it carries all th... | 2026-10-15 |
| [Q-222](#q-222--install-cc-verify-and-r6) | you: terminal | Four approved merges landed today, two of them in host tools: the `cc-verify` host tool (37b24c02, Q-217) a... | 2026-10-28 |
| [Q-227](#q-227--image-lag) | you: terminal | Main's gate code is ahead of the installed image: the image was built at `ba6d2ec9b3bea765111d3d0a9dc34111a... | 2026-10-29 |
| [Q-079](#q-079--canon-instance-proposal-filter) | agent | Design, per Q-072, (a) a script that turns a commit or commit range into a canon instance, and (b) the high... | 2026-09-27 |
| [Q-097](#q-097--exit-scan-older-routes) | agent | The Q-094 review documented two older Medium routes the exit scan does not see, both now under the guide's ... | 2026-09-28 |
| [Q-108](#q-108--decision-037-stale-lines) | agent | Decision 037 has two stale lines. Line 58 says "035's still-pending regex", but the regex landed in addae61... | 2026-10-02 |
| [Q-125](#q-125--build-cc-isolated-sandbox) | agent | Implement Q-124 [1] as an RPI unit. Add a seccomp profile file: Docker's default with `unshare` and `clone`... | 2026-10-07 |
| [Q-147](#q-147--q089-loop-split-source-guard) | agent | Q-089 unit A's review-fix loop ran a 4th iteration before recording a cap decision. It is now recorded as `... | 2026-10-14 |
| [Q-168](#q-168--q096b-remote-names-unit) | agent | Q-096's iteration 2 found that the exit scan parses remote names and legacy `remotes/`/`branches/` files mo... | 2026-10-15 |
| [Q-173](#q-173--exit-scan-split-groups) | agent | Q-168's final pass split off four groups, each shown end to end (exit scan returns 0, then a host git comma... | 2026-10-15 |
| [Q-067](#q-067--regenerate-skill-eval-reports) | deferred | When should the skill eval reports be regenerated, so that the 50 `@needs-reports` suites constrain the cur... | 2026-09-26 |
| [Q-098](#q-098--global-allowlist-after-sandbox) | deferred | Ship a global `permissions.allow` in `hooks/wiring.json` once cc-isolated has a Bash sandbox (Q-088). Branc... | 2026-09-28 |
| [Q-074](#q-074--failure-pattern-writer-trigger) | trigger | After the Q-018 backfill (164 entries), `docs/thoughts/failure-patterns.md` has gained 1 entry across about... | 2026-09-26 |
| [Q-161](#q-161--revive-hermeticity-layer2-after-q125) | trigger | When Q-125's sandbox merges (bwrap in the cc-isolated image), decision 017's T2 fires: revive hermeticity l... | 2026-10-14 |
<!-- index:end -->

## Open

### Q-222 · install-cc-verify-and-r6
**Needs:** you: terminal · **Opened:** 2026-10-28 · **Status:** OPEN

Four approved merges landed today, two of them in host tools: the `cc-verify` host tool (37b24c02, Q-217) and the exit scan's R6 fix for a relative `core.hooksPath` in a linked worktree (7a5b4f4a, Q-220). Neither runs on your machine until `install.sh` re-installs the host tools. Run this in your host terminal (WSL, not inside a session):

```
cd /home/magfrump/claude-workflows && git merge-base --is-ancestor 37b24c026eed64b12b1c6f9849e31cedba7a5329 HEAD && ./devcontainer-config/install.sh && cc-verify --help | head -5 && cc-isolated --list
```

The first git call only checks that your checkout already holds the cc-verify merge (it runs no hook); if it prints nothing and stops, your checkout is behind main. Before your first real `cc-verify --check`, add `~/cc-verify` to your agents' sandbox `denyWrite` (the guide's cc-verify section says why).

- **Read:** `guides/cc-isolated-usage.md`, section "Verify a branch without installing it: cc-verify" · Q-167 (its probes can run in the same sitting)
- **Blocks:** roadmap Next 1 (Q-125's host live run through `cc-verify`), and behind it Q-098 and Q-161.
- **Interim:** both merges are bats-verified only; your installed exit scan does not yet see R6, and `cc-verify` is not on your PATH.
- **2026-10-28 (owner, in session):** waiting: the install needs every active session stopped first. Q-225, once merged, rides on the same paste.

### Q-167 · post-install-host-probes
**Needs:** you: terminal · **Opened:** 2026-10-15 · **Status:** OPEN

The install is done: the image was built from main at fbe67674 on 2026-10-16 (Q-156), and it carries all three changes below. Run the three probes against it now, before the next release puts more unverified launcher changes on top of them. (If the install did not bless, run `./devcontainer-config/install.sh` in your host checkout first.)

**(a) The rebuild hint** (clears the rebuild-hint commits' `Live-verified: no`): the install's bless output should show `Verified live:  NO — a bless is a review, not a test.` followed by `Next: cc-isolated --probe-only <repo>` alone on its line, and `cc-isolated --list` should show `Blessed config <hash> — verified live: NO (run: cc-isolated --probe-only <repo>)`. Then:

```
cc-isolated --probe-only ~/code/ANY-REPO && cc-isolated --list | grep -i 'verified live'
```

Paste back the hash `--list` prints, for a `Live-verified: <hash>` record.

**(b) The one-workspace rule** (clears its `Live-verified: no`). Paste these lines as written in default zsh; each of the first three must print an ERROR and `exit=2` with nothing done (on a launcher older than the fix, the first line exits 1 with another error (or launches a session if `~/code/b` is a repository) and the second and third print the project list: the install has not taken effect, so stop at the first line that does not print `exit=2`):

```
cc-isolated ~/code/a ~/code/b; echo "exit=$?"
cc-isolated --list  # registered projects; echo "exit=$?"
cc-isolated --profile '#' --list; echo "exit=$?"
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

- **Interim:** bats-only verification (193/193), as the commits' `Host-tool-tested: no` trailers say.
- **If the answer differs:** any exit but 3, or a warning that does not name the hook, is a bug in Q-096; paste the output.

### Q-168 · q096b-remote-names-unit
**Needs:** agent · **Opened:** 2026-10-15 · **Status:** OPEN

Q-096's iteration 2 found that the exit scan parses remote names and legacy `remotes/`/`branches/` files more loosely than git, all predating Q-096. These were split off under the early split trigger. Finish `fix/q096b-exit-scan-remote-names` (3c8fbf4a, unreviewed, stacked on 013f1b3d): rebase it onto Q-096's tip, run its own research-plan-implement pass with the bypass pre-mortem, then the review loop.

- **Built 2026-10-15:** 75d08a94, stopped at the review cap; landing is Q-171, the parity boundary Q-172, the split groups Q-173. This entry closes when the branch lands.
- **Read:** 3c8fbf4a's commit message (it lists the open gaps) · the guide's "Remote names and legacy remote files, read loosely" known-route bullet · Q-097, which may absorb it
- **Interim:** a listed known route; cc-push is still the way to push.
- **2026-10-20:** Q-171 was answered [2] (hold until the split units land), so this waits on Q-173, which waits on Q-172.
- **Stuck (dev cycle 2026-10-25):** held by Q-171 [2] until Q-173's split units land; no choice pending.

### Q-173 · exit-scan-split-groups
**Needs:** agent · **Opened:** 2026-10-15 · **Status:** OPEN

Q-168's final pass split off four groups, each shown end to end (exit scan returns 0, then a host git command runs a planted hook): (1) the relative-path base per working tree: R3 (a `--separate-git-dir` repo), **R6 (High: a relative `core.hooksPath` in a linked worktree inside the checkout is never walked)**, A14, A16; (2) `@[` in local paths (R4); (3) `gitdir:` include parity (R5, A15, T3); (4) one reader for `gitdir:`/commondir files (T1; a container-form `.git` ending in CR). Waits on Q-172; R6 is the first to build under any option, unless [2] puts it outside the boundary.

- **Read:** Q-168's rubric, the R3–R6 and A14–A17 rows
- **Interim:** documented as known routes once Q-171's iteration lands; cc-push stays the safe path.
- **2026-10-23:** Q-172 answered [2]: close only routes that need no state planted before launch, list the rest as known routes, and the guide says to push with cc-push. First step: sort the four groups by that rule. R6 (a relative `core.hooksPath` in a linked worktree inside the checkout) needs only state a session can write in the checkout, so it is inside the boundary and builds first.
- **Stuck (dev cycle 2026-10-25):** unblocked by Q-172 [2] but needs a build loop (sort the groups, build R6 first), not a docs edit; no choice pending.
- **2026-10-28 (dev cycle):** the sort and R6 merged at 7a5b4f4a (Q-220 [1]); group 1's remainder (A14, R3's remote half, A16) is briefed (`docs/working/briefs/2026-10-28-exit-scan-group1-remainder.md`). Groups 2-4 are out of the boundary or tech debt per that unit's research doc.

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
- **Stuck (dev cycle 2026-10-25):** fixed on unmerged `feat/q106-host-settings-merge`; closes when Q-106 lands (Q-174 [1] iteration 4 not yet run).

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
- **Fired (dev cycle 2026-10-28):** 2 entries since the backfill (FP-173, FP-174), under 5 by 2026-10-26; reopened as Q-223.
- **2026-10-29:** Q-226 answered [5] (put both steps where build loops run, checked by the gate); briefed as `docs/working/briefs/2026-10-29-failure-pattern-loop-wiring.md`. This watch is superseded once that brief merges.

### Q-079 · canon-instance-proposal-filter
**Needs:** agent · **Opened:** 2026-09-27 · **Status:** OPEN

Design, per Q-072, (a) a script that turns a commit or commit range into a canon instance, and (b) the higher-level heuristic that decides which candidates get *proposed*. The canon should stay compact and broad in issue types. Growth should be justified by coverage, not triggered by volume. Draft it as a divergent-design doc. The filter choice then comes back as a `you: judgment` entry.

- **Read:** `docs/working/canon-issue-ledger.md` · `review-canon.md` §1 · the 112 September `docs/reviews/` artifacts as the candidate pool
- **Interim:** the ledger is unchanged.
- **Stuck (dev cycle 2026-10-25):** needs a loop to write the design doc; the user's choice comes after it.

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

### Q-097 · exit-scan-older-routes
**Needs:** agent · **Opened:** 2026-09-28 · **Status:** OPEN

The Q-094 review documented two older Medium routes the exit scan does not see, both now under the guide's "Known routes it does not see". (a) A symlink in the working tree to a repository outside the checkout is not walked. (b) A non-standard container-form `.git` (`gitdir: /workspace/...`) left at launch can map to a different git dir under `git worktree repair`, which picks by worktree name. Close each or record why it stays open, one enforcement unit each, after Q-096.

- **Read:** `docs/reviews/code-review-rubric-2026-09-28-q094-final-B.md` · the guide's known-routes list · override-log row 135 (fold the `commondir` reader into `cc-gitdir.sh`; its trigger was moved, not met)
- **Interim:** documented. cc-push is still the only way to push.
- **Stuck (dev cycle 2026-10-25):** enforcement units on `cc-exit-scan.sh`, queued behind Q-173 and Q-168 on the same file.

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
- **Stuck (dev cycle 2026-10-25):** the host live run waits on cc-verify (merge entry Q-217, open).
- **2026-10-28 (dev cycle):** cc-verify merged at 37b24c02 (Q-217 [1]). The live run now waits on the host install (Q-222), then on a probe file and paste (roadmap Next 1).

### Q-147 · q089-loop-split-source-guard
**Needs:** agent · **Opened:** 2026-10-14 · **Status:** OPEN

Q-089 unit A's review-fix loop ran a 4th iteration before recording a cap decision. It is now recorded as `split`: the static source-set test (rubric A6/R2/R4) moves to its own unit, `feat/q089-source-guard` (at fa059477). The rest of unit A starts a new loop. That source-guard unit needs a fresh loop that first narrows the test's claim to "plain spellings, accidental drift". Pass 4 showed grep can't cover every bash form.

- **Read:** `docs/reviews/code-review-rubric-2026-10-14-feat-q089-host-tool-trust.md` "Iteration-4 gate"
- **Interim:** unit A ships without the static guard. The runtime checks don't depend on it, and the guard is hardening against a future refactor.
- **Stuck (dev cycle 2026-10-25):** the source-guard unit needs a fresh build loop that narrows the test's claim; no choice pending.


### Q-227 · image-lag
**Needs:** you: terminal · **Opened:** 2026-10-29 · **Status:** OPEN

Main's gate code is ahead of the installed image: the image was built at `ba6d2ec9b3bea765111d3d0a9dc34111a4078524` (C), main is at `a8e941a5e226f1dfba291ae8c0758c9096f65323` (M), and the gate scripts the dev cycle runs differ in `scripts/build-loop.sh`, `scripts/questions.sh`, `skills/dev-cycle/SKILL.md` (Q-224's owner routes, merged at 236f21ee, Q-228's failure-pattern wiring, merged at f91d7d09, Q-229's `watching.md` and `migrate`, merged at 6ee39f24, and Q-230's session answers, merged at 014e5219; Q-232's harness feedback file, merged at a8e941a5, ships with it). This is the release: your review of what it ships. Run this in your host terminal (WSL, not inside a session), with every session stopped, then start a new sandbox launch:

```
cd /home/magfrump/claude-workflows && test "$(git rev-parse HEAD)" = a8e941a5e226f1dfba291ae8c0758c9096f65323 && ./devcontainer-config/install.sh
```

The only git call before `install.sh`'s own state gate is `rev-parse`, which runs no hook. If the `test` fails, your host checkout is not at M: bring it there first, knowing that any other git command on the host (a checkout included) can run a hook a sandbox session planted, as `install.sh`'s trust model says. This one paste also covers Q-222 (the same `install.sh` run, at a newer commit): run `cc-verify --help | head -5 && cc-isolated --list` after it, as Q-222 asks.

- **Changed gate paths (C to M):** `scripts/build-loop.sh`, `scripts/questions.sh`, `skills/dev-cycle/SKILL.md`
- **Commits on main's first-parent line after C** (rewritten 2026-10-29 for M a8e941a5; a subject ending "(build-loop self-merge)" is flagged ⚑: no one reviewed it before it merged):
  - a8e941a5 Merge branch 'feat/harness-feedback-file' (build-loop approved merge)
  - 014e5219 Merge branch 'feat/session-answers-for-merge-entries' (build-loop approved merge)
  - 6ee39f24 Merge branch 'feat/questions-watching-file' (build-loop approved merge)
  - 02459ad4 Merge branch 'chore/dev-cycle-2026-10-29-2212'
  - fd9531bf merge approval
  - 1d49a0dc Merge branch 'chore/dev-cycle-2026-10-29-2126'
  - cfa3a158 Merge branch 'chore/dev-cycle-2026-10-29-2108'
  - 2d157f5e Merge branch 'chore/dev-cycle-2026-10-29-2045'
  - a5266b26 Merge branch 'chore/dev-cycle-2026-10-29-2045'
  - ff7516c2 Merge branch 'chore/dev-cycle-2026-10-29-2003'
  - 0784fc8e Merge branch 'chore/dev-cycle-2026-10-29-2003'
  - f91d7d09 Merge branch 'feat/failure-pattern-loop-wiring' (build-loop approved merge)
  - eecf0268 owner notes
  - 2e14f670 Merge branch 'chore/dev-cycle-2026-10-29-1937'
  - 93aa71e6 Merge branch 'chore/dev-cycle-2026-10-29-1937'
  - c3154ff3 Merge branch 'chore/dev-cycle-2026-10-29-0240'
  - a36df962 Merge branch 'fix/questions-doc-bats-lint' (build-loop self-merge) ⚑
  - 36951e86 Merge branch 'chore/dev-cycle-2026-10-29-0235'
  - 2b8f492d Merge branch 'chore/dev-cycle-2026-10-29-0217'
  - 2b239b87 Merge branch 'chore/dev-cycle-2026-10-29-0217'
  - fd41989e Merge branch 'chore/dev-cycle-2026-10-29-0133'
  - 4b2f000a Merge branch 'chore/dev-cycle-2026-10-29-0133'
  - 236f21ee Merge branch 'feat/questions-owner-routes' (build-loop approved merge)
  - fd62dd3f Merge branch 'fix/exit-scan-group1-remainder' (build-loop approved merge)
  - 43914fcb formatting fix
  - 1b4d214f Merge branch 'chore/dev-cycle-2026-10-28-2325'
  - 6b490257 merge approvals
  - 9140d21e Merge branch 'chore/dev-cycle-2026-10-28-2314'
  - d32c7eb2 Merge branch 'docs/failure-pattern-use-review' (build-loop self-merge) ⚑
  - dba2fcd6 Merge branch 'chore/dev-cycle-2026-10-28-2302'
  - f682ce93 Merge branch 'chore/dev-cycle-2026-10-28-2302'
  - 7561c88b Merge branch 'chore/dev-cycle-2026-10-28-2223'
  - f7812120 Merge branch 'chore/dev-cycle-2026-10-28-2205'
  - a233a965 Merge branch 'chore/dev-cycle-2026-10-28-2155'
  - 9b8a0b34 Merge branch 'docs/interview-readme-drift' (build-loop self-merge) ⚑
  - 9a14e27b Merge branch 'chore/dev-cycle-2026-10-28-2136'
  - 4b04a1eb Merge branch 'chore/dev-cycle-2026-10-28-2136'
  - 37b24c02 Merge branch 'feat/cc-verify-host-tool' (build-loop approved merge)
  - 7a5b4f4a Merge branch 'fix/exit-scan-r6-hookspath' (build-loop approved merge)
  - 68287ee2 Merge branch 'feat/widen-fix-drift-check' (build-loop approved merge)
  - ce0f8463 Merge branch 'docs/log-row-73-trigger' (build-loop approved merge)
  - f231aaf9 docs(questions): close Q-092, Q-096, Q-110, Q-160 (owner: done)
  - 4e806568 docs: questions doc becomes owner-only (Q-221 [14'], decision 040)
  - 374c6640 docs(dd): seed step 2 from docs/constraints.md
  - d39ee313 docs(working): double diamond on the questions doc's purposes; file Q-221
  - 3fcbc89e docs(questions): record answers-10-28-26 (Q-169, Q-214, Q-215, Q-217-Q-220)
  - f77cbb28 Merge branch 'chore/dev-cycle-2026-10-26-0139'
  - 1e781bde Merge branch 'chore/dev-cycle-2026-10-26-0045'
  - a55491ad Merge branch 'chore/dev-cycle-2026-10-26-0027'
  - 41ea45a4 Merge branch 'chore/dev-cycle-2026-10-26-0002'
  - d40e4bae Merge branch 'chore/dev-cycle-2026-10-26-0002'
  - 4388056e Merge branch 'docs/decision-015-amendment' (build-loop approved merge)
  - 062acde2 fix(wiring): drop the Write(path) deny rules Claude Code never matches
  - be464869 Merge branch 'feat/interview-profile-run2'
- **Paths changed outside `docs/`, C to M:** `devcontainer-config/cc-exit-scan.sh`, `devcontainer-config/cc-isolated.sh`, `devcontainer-config/cc-verify.sh`, `devcontainer-config/install.sh`, `devcontainer-config/link-claude-home.sh`, `global-instructions/CLAUDE.md`, `guides/README.md`, `guides/cc-isolated-usage.md`, `guides/cross-project-setup.md`, `guides/harness-feedback.md`, `hooks/live-verify-gate.sh`, `hooks/wiring.json`, `profiles/interview/CLAUDE.md`, `profiles/interview/README.md`, `profiles/interview/install.sh`, `profiles/interview/practice-task.md`, `profiles/interview/preflight.sh`, `profiles/interview/settings.json`, `scripts/build-loop.sh`, `scripts/harness-feedback.py`, `scripts/lite-review.py`, `scripts/questions.sh`, `skills/dev-cycle/SKILL.md`, `test/cc-isolated-functions.bats`, `test/cc-verify.bats`, `test/install-host.bats`, `test/lib/build-loop-fixtures.bash`, `test/link-claude-home-wiring.bats`, `test/lite-review-fix-drift-prompt.bats`, `test/questions-doc.bats`, `test/scripts/build-loop-check.bats`, `test/scripts/build-loop-dispatch.bats`, `test/scripts/build-loop-merge.bats`, `test/scripts/build-loop-orchestrator.bats`, `test/scripts/dev-cycle.bats`, `test/scripts/harness-feedback.bats`, `workflows/divergent-design.md`, `workflows/pr-prep.md`, `workflows/research-plan-implement.md`, `workflows/review-fix-loop.md` (57 paths under `docs/` are not in the image).
- **Interim:** the image's gate runs (built at C); Q-224, Q-228, Q-229 and Q-230 are on main, but the dev cycle still runs the old `questions.sh`, `build-loop.sh` and dev-cycle skill, and sessions still load the old global instructions.
- **Blocks:** Q-222's host tools (`cc-verify`, the exit-scan fixes) and roadmap Next 1 behind them.


### Q-233 · merge-gate-2026-10-29-convention-migrations-first-b001677ac0d8
**Needs:** you: judgment · **Opened:** 2026-10-29 · **Status:** ANSWERED

**Answered:** [1] (owner, in session 2026-10-29: "probably worth merging Q-233 before the release"; recorded by the dev cycle)

Merge `feat/convention-migrations-first` at b001677ac0d8ce334290dfc6d7b055534ea49960 (brief `docs/working/briefs/2026-10-29-convention-migrations-first.md`, roadmap In flight)? This is the branch you approved as Q-231 [1], plus the reconciliation it needed after Q-229 merged. Merging f1146945 as it was would have left main's own migration test failing, so I sent it back instead of merging.

- **Why it's yours:** gate code (`scripts/dev-cycle.sh`, `scripts/lib/migrations.sh`, `skills/dev-cycle/SKILL.md`), and the commits after your Q-231 approval are new.
- **What changed since Q-231 (four commits on top of f1146945):**
  - 5b6133f6 merges main (4b4f5e23) into the branch, with no conflicts.
  - 63d6f7d7 adds the registry line for Q-229's questions change: `mig questions-owner-routes-040 questions 47e9bd8f3916be62 docs/working/questions.md '^\*\*Needs:\*\* (agent|trigger|deferred)( |$)' '~/.claude/scripts/questions.sh migrate'`. It matches 5 lines in this repo's `questions.md`, so once the digest runs from the next release, the cycle will file the migration as a `you: terminal` entry: the same one-time `migrate` run Q-229 already left with you.
  - 5bc67ede adds a shellcheck exemption for the literal `~` in that remedy text.
  - b1341e36 adds the failure-pattern lines the merged Q-228 check asks for.
  - Test 4 was not a locale problem: it failed for the same missing line. It now also checks its precondition first.
- **Everything else** is as Q-231 described: a registry line per convention change, a merge check, digest section 7b, and step 1b surfacing pending migrations first without stopping the iteration.
- **Tests:** the loop's health check passed on the merged branch (one run failed a `build-loop-check.bats` case this branch does not touch, at load average 11; it passed 3 of 3 alone, and the next full run passed).
- **`--check` printed:**

```
ok docs/working/briefs/2026-10-29-convention-migrations-first.md b001677ac0d8ce334290dfc6d7b055534ea49960 2fd745977ba3eb585f774ba7b83170685dd30fd2
path docs/working/briefs/2026-10-29-convention-migrations-first.md M docs/working/briefs/2026-10-29-convention-migrations-first.md
path docs/working/briefs/2026-10-29-convention-migrations-first.md A docs/working/research-2026-10-29-convention-migrations-first.md
path docs/working/briefs/2026-10-29-convention-migrations-first.md M guides/README.md
path docs/working/briefs/2026-10-29-convention-migrations-first.md A guides/convention-changes.md
path docs/working/briefs/2026-10-29-convention-migrations-first.md M scripts/dev-cycle.sh
path docs/working/briefs/2026-10-29-convention-migrations-first.md A scripts/lib/migrations.sh
path docs/working/briefs/2026-10-29-convention-migrations-first.md M skills/dev-cycle/SKILL.md
path docs/working/briefs/2026-10-29-convention-migrations-first.md A test/scripts/convention-migrations.bats
path docs/working/briefs/2026-10-29-convention-migrations-first.md M test/scripts/dev-cycle.bats
```

- **Paths self-merge's floor would refuse:** `scripts/dev-cycle.sh`, `scripts/lib/migrations.sh` (gate code), `skills/dev-cycle/SKILL.md` (gate code, an instruction file).

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] merge** | The next iteration merges b001677a; it acts after the next release (Q-227) | One `you: terminal` paste per future convention change | One `git revert` of the merge |
| **[2] drop** | The brief closes; point 2 goes back to the roadmap | None now | Format changes keep reaching repos unannounced |
| **[3] changes needed** | Your note goes back to the loop | A one-line note | Another loop round |

- **Blocks:** nothing else.
- **Interim:** the branch waits; nothing on main changes.
