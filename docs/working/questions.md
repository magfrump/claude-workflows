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
| [Q-269](#q-269--deep-audit-scope-and-timing) | you: judgment | Run the deep audit the dev cycle keeps saying is due, and if so, the small one or the full one? | 2026-11-10 |
| [Q-270](#q-270--light-pass-between-full-cycles) | you: judgment | Between full dev-cycle iterations, should the cycle run a light pass, and if so, what brings a full cycle b... | 2026-11-10 |
| [Q-272](#q-272--confine-tests-fallback-run-or-refuse) | you: judgment | When the test-confinement script cannot use its strong tool, should it still run the tests under its weak o... | 2026-11-10 |
| [Q-084](#q-084--q076-live-checks) | you: terminal | Q-076 (`cc-push`, the exit scan) was verified only with bats: stubbed docker and local-path remotes, on git... | 2026-09-27 |
| [Q-167](#q-167--post-install-host-probes) | you: terminal | Q-167: (b) and (d) answered 2026-11-07 (answers-11-7-26.txt), on bless 91c5f79dd91eb7ee, which --probe-only... | 2026-10-15 |
| [Q-255](#q-255--herald-egress-fix-unconfirmed) | you: terminal | Q-255: first half answered 2026-11-07 (answers-11-7-26.txt): all four fronted probes through plugins-artifa... | 2026-11-05 |
| [Q-273](#q-273--image-lag) | you: terminal | Run the two pastes below: first the live check of the Bash sandbox, then, if it passes, the install that pu... | 2026-11-11 |
<!-- index:end -->

## Open

### Q-273 · image-lag
**Needs:** you: terminal · **Opened:** 2026-11-11 · **Status:** OPEN

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

**Paste 1, the live check** (host terminal in WSL, from your checkout, answering y at `cc-verify`'s one prompt; 5 to 15 minutes, an estimate, since it has never run). It builds main in a throwaway container and runs the check file there: no login, no LLM, nothing installed. Naming `main` as the branch is new: the branch it used to name is merged and deleted, and I have not been able to run this form.

```
cd /home/magfrump/claude-workflows && cc-verify --check docs/working/q125-verify-check.sh . main; echo "cc-verify exit $?"
```

Paste back every line from the first `RESULT` line through `cc-verify exit N`. Exit 0 and `VERDICT pass` mean go on to paste 2. A FAIL means stop: paste the output and the cycle sends it to a build loop.

**Paste 2, the install** (same terminal; stop every session first):

```
cd /home/magfrump/claude-workflows && test "$(git rev-parse HEAD)" = 3cd6d9bb97436ad99e9304a0d88c0a3d4d5b961c && ./devcontainer-config/install.sh
```

The `rev-parse` check runs no hook. It only confirms your checkout is at `3cd6d9bb`, the last merge. Main is already past that commit, because the cycle's own land moves it, so check out `3cd6d9bb` first. That checkout, like any other git command on the host, can run a hook a sandbox session planted, which is `install.sh`'s own trust model. If the install re-blesses, it also prints the hint that Q-167 (the post-install probes) still needs for its step (a).

- **Interim:** the image at `536b7082` runs.

### Q-272 · confine-tests-fallback-run-or-refuse
**Needs:** you: judgment · **Opened:** 2026-11-10 · **Status:** OPEN

When the test-confinement script cannot use its strong tool, should it still run the tests under its weak one, or refuse?

**If you say no:** nothing changes, which is also what happens if you never answer: the script runs under the weak tool after printing a warning, as merged today. Nothing calls the script yet, so no run is exposed while this is open.

**What this is about.** `scripts/confine-tests.sh` runs a test command with the network cut off. It prefers `bwrap`, which also makes the filesystem read-only and gives the tests a private `/tmp`. When `bwrap` is missing or refused it falls back to `unshare`, which cuts the network and nothing else: the tests run as uid 0 inside a user namespace and can write to the real filesystem. Until today that fallback said nothing. A fix merged at b0ebed19 without review (a self-merge) makes it print a warning naming what `unshare` does not confine, and then run.

**Why it comes to you.** One of the four hard constraints in `docs/constraints.md`, H2, says a gate fails closed: "a ... degraded primitive refuses and names what went unenforced ... degradation only ever narrows access". Running with less confinement names the gap but does not refuse. The brief I wrote for the fix asked only for the warning and put a refusal out of scope, so the code follows the brief, not the whole of H2. The build loop's security review rated the remaining gap Medium: a run on a host without `bwrap` can write to that host and still report a pass. The gap is older than today's change, which narrowed it.

- **Why it's yours:** keeping the run means recording an exception to a hard constraint, and only you change those.
- **Read:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md` (its question section and its "Exit statuses" table) · `docs/reviews/security-review-final-2026-11-10-confine-tests-dash-and-fallback.md` · H2 in `docs/constraints.md`

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Run and warn** | As merged. `unshare` becomes a stated exception to H2, which you add to `docs/constraints.md` or ask a session to draft | A line in the constraints file | A host without `bwrap` gets a pass from a run that could write to it |
| **[2] Refuse unless asked** | Without `bwrap` the script exits 3, unless a new flag asks for `unshare` | One more build loop, self-merged | Hosts with only `unshare` lose confined runs until someone passes the flag |
| **[3] Always refuse** | Without `bwrap` the script exits 3; `unshare` stays only behind `--no-loopback` | One more build loop, self-merged | As [2], with no way to opt in |

My recommendation is [2]: it meets H2 as written without an exception, and the weak mode stays available to someone who asks for it. It can wait until the sandbox branch (Q-267) merges, since that is when the image gains `bwrap` and the script first has something to run under. The same answer settles a smaller point: on a fallback, the script's `--probe` check exits 0 with no warning today, and under [2] or [3] it would refuse too.

- **Interim:** [1], as merged.
- **If the answer differs:** one small brief changes the fallback and its tests; nothing merged today is redone.

### Q-270 · light-pass-between-full-cycles
**Needs:** you: judgment · **Opened:** 2026-11-10 · **Status:** OPEN

Between full dev-cycle iterations, should the cycle run a light pass, and if so, what brings a full cycle back?

**If you say no:** nothing changes, which is also what happens if you never answer. Your earlier answer stays: a full cycle every iteration (Q-154, where you said to revisit this "once the costs are visible").

**What the two are.** A full cycle runs four checking steps every time: the revisit triggers on past decisions, the watches, a spot-check of last week's merges, and the check for whether a deep audit is due. A light pass skips those four. It only collects finished build loops, writes briefs, dispatches and lands.

**The numbers you asked for** are in `docs/working/research-2026-11-10-cycle-overhead-numbers.md` (merged at c70bb17a with no review; a build loop wrote it and four reviewer agents checked it). The figures below are that doc's; I re-counted only the total of iterations. From the 100 iterations recorded between 2026-10-16 and 2026-11-10:

- 72 ran the checking steps. 40 found nothing, 10 only repeated "a deep audit is due" onto a task that already exists, and 22 caught something.
- 24 were already light passes. You directed 2; the cycle chose the other 22 itself, with no rule for it in the skill, and stopped doing so after 2026-11-02.
- Time is small: 16 hours in all. A full iteration that found nothing took a median of 3.8 minutes, a light one 2.9.
- Tokens are not recorded anywhere in the repo, so the cost you asked about is still not visible. The doc does not estimate them.

In the table, "replayed" means the doc re-ran the recorded iterations under that rule, and a "catch" is something the checking steps found (22 in 26 days).

- **Why it's yours:** it changes how often past decisions get re-checked, and it replaces an answer you gave.
- **Read:** the doc above, its Summary and section 9 · Q-154 in `docs/working/questions-archive.md`

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Full cycle every iteration** | Your Q-154 answer stays, and the cycle stops choosing light passes on its own | None | The repeats go on: 50 of 72 full iterations found nothing new, at a token cost no one has measured |
| **[2] Full when main moved or a new day starts** | Full on each day's first iteration and whenever main gained anything but the cycle's own land; light otherwise | One merge to approve (the dev-cycle skill) | Things that are not commits wait for the next day; replayed, 4 of 22 catches waited, 2 of them really (1 hour and 3.8 hours) |
| **[3] One full cycle a day** | The day's first iteration is full, the rest light | One merge to approve (the dev-cycle skill) | Replayed, 15 of 22 catches waited a median of 18 hours, up to 5 days; 9 might never be found |
| **[4] Measure tokens first, then decide** | [1] stays for now; a small docs unit totals tokens from existing session transcripts, or the cycle record gains a token line | This question reaches you once more | The repeats continue meanwhile; if transcripts cannot be matched to iterations, it takes weeks of new records |

The build loop recommends [4], then [2] if the tokens show the repeats cost something. Its reason: your own condition, costs visible, is not met yet. If you would rather settle it now, [2] gives up the least. I agree with that order.

One thing to know either way: today the cycle's 30-minute fallback wakeup fired three times while build loops were still working. Each time I checked the loops and main, found nothing to collect, and did not run an iteration. I read that as waiting, not as a light pass, since the skill starts an iteration when a loop finishes.

- **Blocks:** roadmap Next 3 (revisit the light pass).
- **Interim:** [1], your Q-154 answer.
- **If the answer differs:** nothing is redone; [2] or [3] becomes a brief for the dev-cycle skill, [4] a small docs brief.

### Q-269 · deep-audit-scope-and-timing
**Needs:** you: judgment · **Opened:** 2026-11-10 · **Status:** OPEN

Run the deep audit the dev cycle keeps saying is due, and if so, the small one or the full one?

**If you say no:** nothing runs, which is also what happens if you never answer. The cycle keeps adding a line to the roadmap each time the audit's conditions hold, and loops keep making design choices against `docs/constraints.md` as it is.

**What a deep audit is.** Each cycle checks only last week's merges. A deep audit re-reads older conclusions (decision records, the decision log, the skills, the roadmap's finished items) against today's state, because a new skill, a model change or a big design decision can make them stale. The cycle only decides whether one is due; scope and timing are yours, and it runs on its own branch.

**Why ask now.** It has come due in most cycles since 2026-10-02 and never run, because no one asked you. Two things are new today:

- The model running these sessions changed from `claude-opus-5-5` to `claude-fable-5-2`. Past measurements of review quality and cost, and the judgment calls that rest on them, were made under older models.
- A seventh finding of one kind. When a build loop picks between designs, it is meant to rule options out only on the hard constraints in `docs/constraints.md` (the `H` lines) and to rank what is left with the soft ones (the `S` lines). In seven design records since 2026-10-20, a soft line helped rule an option out; in three of them a rule that helped decide was not in the file at all (for example "benchmark code lives in the SWRBench fork"). Every pick still stands, since a hard line or a clearly better option decided each one. The pattern suggests some soft lines are being treated as hard, or should be.

- **Why it's yours:** promoting a soft constraint to hard, or dropping one, changes what every loop may build. The full audit is also a large run, and your standing rule is no big compute until the code settles.
- **Read:** the roadmap's Now item "Agent: scoped deep audit, constraint drift" and its Ideas item "Scoped deep audit" (`docs/roadmap.md`), which list the seven records between them · `docs/constraints.md` (4 hard lines, 10 soft)

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] The small audit now** | One build loop reads the seven flagged design records and drafts changes to `docs/constraints.md` with the `constraints-builder` skill (the skill that drafts that file; its amend mode revises it). You get one later entry: promote, keep soft or drop, per flagged line. Nothing else is re-read. | One loop's compute, then one entry with a handful of yes/no calls | The older conclusions stay unchecked under the new model; you can ask for [2] later |
| **[2] The full audit now** | [1], plus a re-read of every decision record, log row, skill and finished roadmap item against today's state, split over several loops | Several loops' compute over a day or more, and likely several entries | Heavy spend before the A8 token measurement you deferred, and it may muddy that baseline |
| **[3] Wait** | Nothing runs until you say. The cycle keeps recording when it comes due | None | Loops keep ruling options out on soft lines; a wrongly rigid one costs a better design somewhere, unseen |

My recommendation is [1]: it is the part with evidence behind it, it is small, and it does not touch the compute you are holding back.

- **Interim:** [3]. Nothing is burning: every flagged pick was checked and stands.
- **If the answer differs:** nothing is redone; [1] or [2] becomes a brief at the next cycle.

### Q-255 · herald-egress-fix-unconfirmed
**Needs:** you: terminal · **Opened:** 2026-11-05 · **Status:** OPEN
Q-255: first half answered 2026-11-07 (answers-11-7-26.txt): all four fronted probes through plugins-artifacts.gradle.org returned 403 Forbidden (www.google.com, www.python.org, www.cloudflare.com, github.com), so the name does not front. The herald half (probe.sh, the host-record count, a cold assembleDebug) is still open; probe.sh is now a standalone file, docs/working/feedback/herald-probe.sh.

The fix for herald's `dl.google.com` build failures was released on 2026-10-28 (Q-214), but no output was kept, so two things are still unknown: whether the fix works, and whether `plugins-artifacts.gradle.org`, the name added with it, can be used to reach other sites (domain fronting: a request that connects under an allowed name but asks for a different site). Paste this on the host, outside any container, and answer `Q-255: <output>`.

- **Read:** `docs/working/feedback/belegarth-herald.md` (the handoff) · `docs/decisions/039-pin-resolver-to-phase-a.md` · Q-214 in the archive

```bash
b=$(mktemp); probe() { r=$(curl -sS -m 10 -o "$b" -w '%{http_code}' "$@" 2>&1); t=$(grep -o -i -m1 '<title>[^<]*' "$b" | head -c 50); echo "$r $t"; }
for tgt in www.google.com www.python.org www.cloudflare.com github.com; do printf '%-16s fronted=[%s]\n' "$tgt" "$(probe -H "Host: $tgt" https://plugins-artifacts.gradle.org/)"; done; rm -f "$b"
```

Expect 403 or 404 on all four lines. A 200 with that site's title means the name fronts.

- **Also needed, at your next herald session:** ask the herald agent to run the handoff's `probe.sh OUTDIR 1800 20` (appendix of the file above; copy it across if herald has no copy), then `grep -c host-record /etc/dnsmasq.d/cc-allowlist.conf`, then a cold `./gradlew :app:assembleDebug`. Pass is 0 `FAIL sni=dl.google.com` lines and a finished build. It then retires its "dl.google.com refused TLS" memory. This entry stays open until that result is on record here.
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

