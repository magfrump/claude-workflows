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
| [Q-277](#q-277--install-sandbox-with-nested-worktree-gap) | you: judgment | The sandbox's live check failed on nested worktrees. Install the release anyway, with the gap written down,... | 2026-11-11 |
| [Q-084](#q-084--q076-live-checks) | you: terminal | Q-076 (`cc-push`, the exit scan) was verified only with bats: stubbed docker and local-path remotes, on git... | 2026-09-27 |
| [Q-167](#q-167--post-install-host-probes) | you: terminal | Q-167: (b) and (d) answered 2026-11-07 (answers-11-7-26.txt), on bless 91c5f79dd91eb7ee, which --probe-only... | 2026-10-15 |
| [Q-255](#q-255--herald-egress-fix-unconfirmed) | you: terminal | Q-255: first half answered 2026-11-07 (answers-11-7-26.txt): all four fronted probes through plugins-artifa... | 2026-11-05 |
| [Q-273](#q-273--image-lag) | you: terminal | Q-273: paste 1 did not run (owner, answers-11-11-26.txt). `cc-verify` refused with "an earlier run left /ho... | 2026-11-11 |
<!-- index:end -->

## Open

### Q-277 · install-sandbox-with-nested-worktree-gap
**Needs:** you: judgment · **Opened:** 2026-11-11 · **Status:** OPEN

The sandbox's live check failed on nested worktrees. Install the release anyway, with the gap written down, or hold it?

**If you say no:** nothing installs, which is also what happens if you never answer. Sessions keep running the image at `536b7082`, with no Bash sandbox at all.

**What happened.** The release entry Q-273 has two pastes: a live check of the new Bash sandbox, then the install. Your check on 2026-11-11 ran to the end and failed: `VERDICT FAIL (3 not pass, 0 missing)`. Two of the three lines are on record, and both say the same thing: inside a nested worktree (`/workspace/.claude/worktrees/<name>/`) a sandboxed command can create `.claude/` and can write the worktree's `.git` pointer file. Files planted there could run code outside the sandbox later. The third line is above the tail you pasted, so I do not know what it is. Everything else in the tail passed: the git-driver check, the network checks and the builds.

**What the gap is next to.** Today no session has a sandbox, so a Bash command can already write those two files and every other file a session can reach. Installing does not open the gap; it closes most of what is open and leaves this part. Holding keeps all of it open until a fix is designed, built and checked again.

- **Why it's yours:** a release is yours, and the sandbox's plan said to go ahead only after this check passed.
- **Read:** Q-273 (its 2026-11-11 paragraphs) · `docs/working/plan-q125-cc-isolated-sandbox.md`, step 6 and the table row on project files that execute later · the roadmap Now item "the sandbox leaves nested worktree paths writable"

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Install now, gap written down** | You run Q-273's paste 2. The gap goes into the guide as a known limit, and the fix follows as its own change and release | Paste 2 now; one more live check and install when the fix lands | Sessions run for some days with a sandbox that one planted file in a nested worktree could step around. If the third failed line is something that breaks normal work, one revert and a reinstall undo the sandbox |
| **[2] Hold the release until the gap is fixed** | Nothing installs. A build loop designs and builds the fix, then you run the live check again | No paste now; the other merges in this release (the dev-cycle skill fixes, the test-confinement script's fixes, the canon script) wait too | Days more with no sandbox at all, to avoid a gap smaller than what is open today |
| **[3] Release without the sandbox** | The sandbox merge is reverted on main, you install the rest, and the sandbox comes back with its fix | One merge entry for the revert, then a paste; later a second merge and release | The same days with no sandbox as [2], plus the work of taking it out and putting it back |

My recommendation is [1], on one condition: the third failed line is another nested-worktree path, or something else that leaves normal work running. I can say which as soon as the lines above the tail are on record (Q-273 asks for them). If it turns out to be a check that shows the sandbox breaking something sessions need, I will say so here before you install.

- **Blocks:** Q-273's paste 2, and with it everything that waits on the sandbox being live (watches Q-098, the global allow list, and Q-161, the test-confinement gate).
- **Interim:** hold. Nothing is installed.
- **If the answer differs:** nothing is redone. [1] is the paste that already exists; [3] becomes a revert brief.

### Q-273 · image-lag
**Needs:** you: terminal · **Opened:** 2026-11-11 · **Status:** OPEN
Q-273: paste 1 did not run (owner, answers-11-11-26.txt). `cc-verify` refused with "an earlier run left /home/magfrump/cc-verify/run-1793211495-572412.d; run: cc-verify --clean", and `cc-verify --clean` then exited 2 and printed nothing. Paste 2 was not run. Second try (owner, in session 2026-11-11): the leftover directory is gone and `cc-verify` started, then stopped at step 1 with "fatal: repository '.' does not exist" and "ERROR: could not clone ..", exit 1; its teardown was clean. Third try (owner, in session 2026-11-11), with full paths: the check ran to the end and failed. `VERDICT FAIL (3 not pass, 0 missing)`, `RESULT cc-verify fail tree=08bf2bc92519798b12322d123e65eab5ed2bea31 config=1887e71a2126a27b (check exit 1)`, `cc-verify exit 3`, teardown ok. The pasted tail shows two of the three: `C3-nested-settings-1 FAIL (could create /workspace/.claude/worktrees/q125-probe/.claude)` and `C3-nested-gitfile-1 FAIL (writable: /workspace/.claude/worktrees/q125-probe/.git)`; C4, the five C5 lines and both C6 lines passed. The third line that did not pass is above the tail and not on record. Paste 2 was not run and is on hold. Still open: the RESULT lines above the tail, and paste 2.

Run the two pastes below: first the live check of the Bash sandbox, then, if it passes, the install that puts today's merges on the host.

**If you say no:** nothing breaks. Sessions keep running the image at `536b7082`: no Bash sandbox, and the dev cycle keeps its old identity check and release paste. The merges stay on main, waiting.

**Release notes.** The installed image is the root-owned copy of the dev-cycle scripts and skill that every session runs. It is at `536b708294d1584be3c7455d78462716ce36edce` (read from `/opt/claude-workflows/.manifest`). Main's last merge is `3cd6d9bb97436ad99e9304a0d88c0a3d4d5b961c`.

**The one change most worth your look:** the Bash sandbox for cc-isolated sessions (`3cd6d9bb`). It changes `devcontainer-config/install.sh`, the Dockerfile and the launcher, and adds a seccomp profile and managed settings. It has never run anywhere: every commit that touches those files says `Live-verified: no`. The first paste is that live run.

**Merged without your review** (self-merges; no one reviewed them):

- `b0ebed19` Merge branch 'fix/confine-tests-dash-and-fallback' (build-loop self-merge): two fixes to `scripts/confine-tests.sh`; its open question is Q-272
- `9d6d6101` Merge branch 'test/confine-tests-bats' (build-loop self-merge): the first tests for that script
- `c70bb17a` Merge branch 'docs/cycle-overhead-numbers' (build-loop self-merge): one research doc; the image carries none of it

**What changes for you** (the three merges you approved today):

- The Bash tool in cc-isolated sessions runs inside a sandbox (`3cd6d9bb`, your Q-267 answer). If it blocks normal work, one revert and a reinstall undo it.
- The dev cycle's identity check accepts an identity from the environment, its record says why a free build-loop slot stayed free, and it writes a release paste that runs from main's tip (`1f14e270`, your Q-271 answer). The new paste appears from the release after this one, because the image's own copy of the skill wrote this entry.
- `scripts/canon-instance.py` and two new canon instances (`1d9d01b4`, your Q-268 answer). The image does not use them.

**The rest:** 8 cycle lands, records only. The full list: `git -c log.showSignature=false log --first-parent --format='%h %s' 536b708294d1584be3c7455d78462716ce36edce..3cd6d9bb97436ad99e9304a0d88c0a3d4d5b961c`

**Gate files changed:** `scripts/lib/migrations.sh`, `skills/dev-cycle/SKILL.md`.

**Paths outside `docs/`** (58 paths under `docs/` also changed; the image carries none of them): `devcontainer-config/Dockerfile`, `devcontainer-config/cc-isolated.sh`, `devcontainer-config/cc-sandbox-settings.sh`, `devcontainer-config/devcontainer.json`, `devcontainer-config/install.sh`, `devcontainer-config/managed-settings.json`, `devcontainer-config/seccomp-cc-sandbox.json`, `guides/devcontainer-setup.md`, `guides/test-hermeticity.md`, `hooks/live-verify-gate.sh`, `scripts/canon-instance.py`, `scripts/confine-tests.sh`, `scripts/lib/migrations.sh`, `skills/dev-cycle/SKILL.md`, `test/cc-isolated-functions.bats`, `test/cc-sandbox-settings.bats`, `test/install-host.bats`, `test/scripts/build-loop-orchestrator.bats`, `test/scripts/canon-instance.bats`, `test/scripts/confine-tests.bats`, `test/seccomp-cc-sandbox.bats`

**2026-11-11, why paste 1 failed.** `cc-verify` did not make the directory it named. The trial script you ran on 2026-10-28 (`q117-spike.txt`, the prototype `cc-verify` was built from) made it. That run was refused at its first step, the merge check, before it built or started anything, so no container, volume or image belongs to it. Its cleanup removed the run's `record` file and left the directory (the `ls` in paste 1 shows whether anything else is in it). `cc-verify` counts any `run-*` name in `~/cc-verify` as an unfinished run and refuses to start. Its `--clean` then fails on a directory that holds no `record` file: it exits 2 and prints nothing. That is a bug in `--clean`. I reproduced it here with stand-ins for docker, and a one-line change makes `--clean` remove such a directory. The fix is a roadmap item, and this release does not need it: you removed the directory by hand before the second try.

**2026-11-11, why the second try failed.** `cc-verify` changes into its own run directory before it clones the repository, so `.` named that empty directory, not your checkout. A full path works: I reproduced both here with stand-ins for docker. The mistake was in the paste, which this entry and the check file's own header both wrote with `.`; `cc-verify` should also resolve the path itself, and that is on the same roadmap item. In my last message I said the `. main` form had run here. It had not: the test I ran passed a full path. The failed try left nothing behind (its teardown reported ok), so nothing needs removing now.

**2026-11-11, the check ran and failed: what it found.** The third try built main's tip (f0a55b8a) in a throwaway container and ran the check file to the end. The parts of the sandbox in the pasted tail work on your host: the git-driver check (C4), the network checks (C5: listed hosts answer, an unlisted one is refused) and the two builds (C6) all passed. Two lines failed, and both are the same gap. Inside a nested worktree (`/workspace/.claude/worktrees/<name>/`, where agents' isolated worktrees live), a sandboxed command could create `.claude/` (so it could write a `settings.json` there) and could write the worktree's `.git` pointer file. The sandbox's deny list names those files only at `/workspace` itself. The plan had marked nested worktrees "Unknown" and left it to this run (`docs/working/plan-q125-cc-isolated-sandbox.md`, the table row on project files that execute later); the run says they are not covered. Why it matters: a settings file or a `.git` pointer planted there could run code outside the sandbox later, if Claude Code or git reads it from that worktree. I have not checked whether a subagent working in a worktree loads that settings file. The fix needs a design pass and is a roadmap item.

**Still needed from paste 1: the lines above the tail.** The verdict counts 3 lines that did not pass and the tail holds 2. If your terminal still has the output, paste every `RESULT` line from the first one down to `C3-nested-settings-1`. If it is gone, re-run the same command (about as long as before):

```
cc-verify --check /home/magfrump/claude-workflows/docs/working/q125-verify-check.sh /home/magfrump/claude-workflows main; echo "cc-verify exit $?"
```

**Paste 2 is on hold.** This entry said a FAIL means stop. Whether to install anyway, with the gap written down, is yours to decide and is Q-277 (install the sandbox with the nested-worktree gap, or hold the release). Do not run the block below until that is answered.

**Paste 2, the install** (same terminal; stop every session first):

```
cd /home/magfrump/claude-workflows && test "$(git rev-parse HEAD)" = 3cd6d9bb97436ad99e9304a0d88c0a3d4d5b961c && ./devcontainer-config/install.sh
```

The `rev-parse` check runs no hook. It only confirms your checkout is at `3cd6d9bb`, the last merge. Main is already past that commit, because the cycle's own land moves it, so check out `3cd6d9bb` first. That checkout, like any other git command on the host, can run a hook a sandbox session planted, which is `install.sh`'s own trust model. If the install re-blesses, it also prints the hint that Q-167 (the post-install probes) still needs for its step (a).

- **Interim:** the image at `536b7082` runs; paste 2 waits for Q-277.

### Q-255 · herald-egress-fix-unconfirmed
**Needs:** you: terminal · **Opened:** 2026-11-05 · **Status:** OPEN
Q-255: first half answered 2026-11-07 (answers-11-7-26.txt): all four fronted probes through plugins-artifacts.gradle.org returned 403 Forbidden (www.google.com, www.python.org, www.cloudflare.com, github.com), so the name does not front. The herald half (probe.sh, the host-record count, a cold assembleDebug) is still open. The same answer asked what the handoff's probe.sh is and which files to copy into the herald session; that went unanswered until 2026-11-11 and is answered below: one file, docs/working/feedback/herald-probe.sh.

The fix for herald's `dl.google.com` build failures was released on 2026-10-28 (Q-214), but no output was kept, so two things are still unknown: whether the fix works, and whether `plugins-artifacts.gradle.org`, the name added with it, can be used to reach other sites (domain fronting: a request that connects under an allowed name but asks for a different site). Paste this on the host, outside any container, and answer `Q-255: <output>`.

- **Read:** `docs/working/feedback/belegarth-herald.md` (the handoff) · `docs/decisions/039-pin-resolver-to-phase-a.md` · Q-214 in the archive

```bash
b=$(mktemp); probe() { r=$(curl -sS -m 10 -o "$b" -w '%{http_code}' "$@" 2>&1); t=$(grep -o -i -m1 '<title>[^<]*' "$b" | head -c 50); echo "$r $t"; }
for tgt in www.google.com www.python.org www.cloudflare.com github.com; do printf '%-16s fronted=[%s]\n' "$tgt" "$(probe -H "Host: $tgt" https://plugins-artifacts.gradle.org/)"; done; rm -f "$b"
```

Expect 403 or 404 on all four lines. A 200 with that site's title means the name fronts.

**Still needed: the herald half** (your two questions of 2026-11-07, answered here).

*What `probe.sh` is.* The script the herald agent wrote on 2026-10-17 to measure the `dl.google.com` failures. The handoff prints it in its appendix. Run inside a container, it sends a HEAD request to every exact name on the egress allowlist every 20 seconds for 30 minutes, records what DNS answered each time, then reads the proxy's log and lists the addresses the firewall refused. It downloads nothing and writes only to its output directory. Before the fix it showed `dl.google.com` failing in 65% of rounds; after the fix it should show none.

*What to copy.* One file: `docs/working/feedback/herald-probe.sh`, the same script as a standalone file. Nothing else. On the host (herald's path is the one whose hash matches the `android` project in your `cc-isolated --list` output):

```
cp /home/magfrump/claude-workflows/docs/working/feedback/herald-probe.sh /home/magfrump/belegarth-herald/probe.sh
```

Then start a herald session and give the herald agent this:

```
Run these three checks and write all of their output to egress-check.txt in the repo root. Do not fix anything you find.
1. bash probe.sh "$(mktemp -d)" 1800 20   (about 30 minutes: run it in the background and wait for it). Then print the summary.txt it names, and the number printed by grep -c 'FAIL sni=dl.google.com' on the proxy-window.log in the same directory.
2. grep -c host-record /etc/dnsmasq.d/cc-allowlist.conf
3. ./gradlew :app:assembleDebug --refresh-dependencies   (the last 30 lines of its output are enough)
If check 1 counts 0 and the build finishes, retire the "dl.google.com refused TLS" note in your memory (sandbox-android-build): the cause was a stale address list in the firewall, fixed in the 2026-10-28 release.
```

Answer `Q-255:` with the contents of `egress-check.txt`. Pass is a count of 0 in check 1 and a finished build. `--refresh-dependencies` stands in for the cold build the handoff asked for: it makes Gradle fetch every dependency again even if herald's cache has filled since. `probe.sh` and `egress-check.txt` can be deleted from herald afterwards. This entry stays open until that result is on record here.

- **Interim:** the name stays listed and `android.txt` still says NOT YET PROBED. Editing that comment changes the blessed hash and forces a re-bless, so it waits for this result and goes out with the next release.
- **If the answer differs:** a name that fronts gets a follow-up entry: accept the risk as Q-052 did for Google, or remove the name. A `FAIL sni=dl.google.com` for an address that is not pinned is decision 039's revisit trigger.

### Q-167 · post-install-host-probes
**Needs:** you: terminal · **Opened:** 2026-10-15 · **Status:** OPEN
Q-167: (b) and (d) answered 2026-11-07 (answers-11-7-26.txt), on bless 91c5f79dd91eb7ee, which --probe-only recorded as verified live. (b): line 1 printed 'two workspaces given' and line 3 printed 'is not an egress profile; it looks like a pasted comment', both errors from the fixed launcher. Line 4's probe passed. The paste showed no exit= lines. Line 2 printed the project list, so the owner's shell treated # as a comment (the echo went with it) and the launcher never saw it, which does not exercise the fix. Live-verified: 91c5f79dd91eb7ee for the one-workspace rule's refusals; the exit codes rest on bats. (d): the live-verify-gate count in the host settings.json is 2, so the hooks are wired. Still open: (a)'s first half, the pre-probe hint a fresh bless prints, which Q-261's install shows if it re-blesses.

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

**2026-11-03 (answers-11-3-2026.txt):** **(c) passed.** `cc-isolated exit=3`. The WARNING named `+ hook /tmp/…/proj/mirror-repo/hooks/pre-receive  file 755` and pointed to `cc-push`, so Q-096's exit scan is live-verified on bless 3c5dd7853cf7a3f9. **(a), second half:** `cc-isolated --list | grep -i 'verified live'` prints `Blessed config 3c5dd7853cf7a3f9 — verified live: yes`, so a probe-only run marks the bless as verified (`Live-verified: 3c5dd7853cf7a3f9`). **Still not reported:** (a)'s first half, the hint text that a fresh bless prints before any probe (`Verified live:  NO …` and `Next: cc-isolated --probe-only <repo>` on its own line, plus `--list` showing `verified live: NO (run: …)`). Any later `install.sh` that re-blesses will show it. **(b)** is also not reported: the four one-workspace-rule lines. Q-167 stays open for those two items only.

**2026-11-06, one more check (d), Q-241's settings merge:** no record shows that `install.sh`'s host target merged the hooks into your `settings.json`. On the host, after that install:

```
grep -c 'live-verify-gate' ~/.claude/settings.json
```

Paste the number back. 1 or more means the hooks are wired (by the merge, or by an earlier hand merge). 0 means they are not, and the install's output says why (`WARNING: settings.json NOT merged: …`). Q-167 now stays open for (a)'s first half, (b) and (d).

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

