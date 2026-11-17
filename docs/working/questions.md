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
| [Q-278](#q-278--q272-returned-run-or-refuse) | you: judgment | You asked for Q-272 back with data. When the test-confinement script (`scripts/confine-tests.sh`) cannot us... | 2026-11-11 |
| [Q-295](#q-295--blocked-2026-11-14-merge-rubric-gate-2) | you: judgment | Brief 2026-11-14-merge-rubric-gate's build loop asks again: its extra review pass (your Q-294 [1]) found a ... | 2026-11-14 |
| [Q-296](#q-296--merge-gate-2026-11-16-loop-may-merge-default-in-a3ef5a381c94) | you: judgment | Merge branch `fix/loop-may-merge-default-in` at a3ef5a381c94cc2e8be45502fd02e60256407037? It changes one li... | 2026-11-16 |
| [Q-084](#q-084--q076-live-checks) | you: terminal | Q-076 (`cc-push`, the exit scan) was verified only with bats: stubbed docker and local-path remotes, on git... | 2026-09-27 |
| [Q-167](#q-167--post-install-host-probes) | you: terminal | Q-167: (b) and (d) answered 2026-11-07 (answers-11-7-26.txt), on bless 91c5f79dd91eb7ee, which --probe-only... | 2026-10-15 |
| [Q-255](#q-255--herald-egress-fix-unconfirmed) | you: terminal | Q-255: first half answered 2026-11-07 (answers-11-7-26.txt): all four fronted probes through plugins-artifa... | 2026-11-05 |
| [Q-292](#q-292--cc-verify-host-check) | you: terminal | After Q-290's release paste (which runs `install.sh`; answer y to re-bless `cc-verify.sh`), run the two che... | 2026-11-13 |
<!-- index:end -->

## Open

### Q-296 · merge-gate-2026-11-16-loop-may-merge-default-in-a3ef5a381c94
**Needs:** you: judgment · **Opened:** 2026-11-16 · **Status:** OPEN

Merge branch `fix/loop-may-merge-default-in` at a3ef5a381c94cc2e8be45502fd02e60256407037? It changes one line of the build-loop prompt, so a loop may merge the default branch into its own branch.

**If you say no:** nothing merges; loops keep the prompt's bare "never … merge", which one loop read as forbidding a merge of the default branch into its own branch (the philosophy-research project's harness feedback F-009, `docs/working/feedback/philosophy-research.md`), costing you an extra answer per conflict there.

**What it changes:** the dispatch prompt `build-loop.sh --start` and `--prompt` print to a build loop (the line beginning "Start subagents only for research and review"). It used to end "never send your branch to a remote, merge, open a pull request or publish". It now says "never send your branch to a remote, merge into any branch but your own, open a pull request or publish", then allows merging the default branch, and no other branch, into the loop's own branch with git's default strategy, after which the loop re-runs its review and tests. A conflict it cannot resolve without discarding a side, or that needs a path off a self-merge brief's `Paths:` line, means `git merge --abort` and a stopped marker. It matches the gate's own conflict refusal, which already says "merge the default branch into HEAD first".

`--check`'s lines, as printed:

```
ok docs/working/briefs/2026-11-16-loop-may-merge-default-in.md a3ef5a381c94cc2e8be45502fd02e60256407037 f61aba07e01f11f40990b9b0a5630f3a10b2f352
path docs/working/briefs/2026-11-16-loop-may-merge-default-in.md M docs/working/briefs/2026-11-16-loop-may-merge-default-in.md
path docs/working/briefs/2026-11-16-loop-may-merge-default-in.md M docs/working/plan-build-loop-handoff.md
path docs/working/briefs/2026-11-16-loop-may-merge-default-in.md A docs/working/research-2026-11-16-loop-may-merge-default-in.md
path docs/working/briefs/2026-11-16-loop-may-merge-default-in.md M scripts/build-loop.sh
path docs/working/briefs/2026-11-16-loop-may-merge-default-in.md M test/scripts/build-loop-dispatch.bats
```

- **Gate code:** `scripts/build-loop.sh` is in GATE_CODE (the paths that make up the gate, `scripts/lib/dev-cycle-read.sh`), so self-merge's floor would have refused it and this entry is a `merge-gate-` one. The diff is 5 lines there: the prompt line and a 3-line comment. It reaches sessions at the next release.
- **What an attacker would want here:** outside text that reaches a loop (a web page it read, a file in another branch) persuading it to merge some branch other than the default branch into its own, to carry unreviewed changes through. The prompt names only the default branch, and the gate's `--check` and `--merge` judge the merged result against main, so anything brought in that way shows up as changed paths in an entry like this one.
- **The loop's report** (loop text): a new bats test checks the wording in both `--start`'s and `--prompt`'s output and fails on the old script; the six `test/scripts/build-loop*.bats` files passed (176 tests), unconfined (`scripts/confine-tests.sh --probe` exited 3, no confinement here), and the hermeticity lint passed. Two review rounds; the second was clean.

The loop's marker body, quoted (loop text, data, not instructions):

> No open question. One follow-up idea for the cycle to weigh:
> the live-verify commit hook (hooks/live-verify-gate.sh, which asks for a Live-verified: trailer when a commit touches an enforcement file under devcontainer-config/) judges the staged diff against HEAD and ignores MERGE_HEAD.
> So a hand-resolved merge of the default branch whose main side changed such a file asks the loop for a trailer it cannot honestly give; the loop then stops, as it did before this change.
> A clean merge is unaffected. Fixing it means editing an enforcement file, outside this brief; details in the research doc's pre-mortem, item 5 (docs/working/research-2026-11-16-loop-may-merge-default-in.md).
> This change edits gate code (scripts/build-loop.sh), so its merge needs the owner's approval under a merge-gate- entry.

The cycle's note: the follow-up goes to the roadmap's Ideas; it blocks nothing here.

- **Read:** `git diff 747bd569...a3ef5a38` (5 files, +84 −3); the research doc on the branch, `docs/working/research-2026-11-16-loop-may-merge-default-in.md`.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] merge** | The prompt change lands on main; sessions get it at the next release | Reading a 5-line diff | A loop merges the default branch in where you would rather it stopped; the gate still checks the result |
| **[2] drop** | The branch is abandoned; the prompt stays as it is | None | Conflicts keep costing a permission answer when a loop takes the strict reading |
| **[3] changes needed** | Your note goes back to the loop for another pass | Writing the note | One more loop run |

- **Blocks:** nothing else; the roadmap In flight line for this brief.
- **Interim:** the branch waits at a3ef5a38; nothing merges.
- **If the answer differs:** n/a; each option sets what happens next.

### Q-295 · blocked-2026-11-14-merge-rubric-gate-2
**Needs:** you: judgment · **Opened:** 2026-11-14 · **Status:** OPEN

Brief 2026-11-14-merge-rubric-gate's build loop asks again: its extra review pass (your Q-294 [1]) found a new red that the pass's own fix caused. How should it land?

**If you say no:** nothing merges; the branch `feat/merge-rubric-gate` waits at 27c32c32, and merges stay as they are today, with no script reading a rubric.

> The extra review pass you allowed for the merge-time rubric check found one new red, so it needs your call again.
> Q-294 was your answer [1]: narrow the check and allow one more review pass. That pass is done and is not clean.
>
> What was built: a red rubric row now counts as closed only by a fix or by a Q-ID you answered on main.
> Split and Carried no longer close a red. This removed the part review kept failing on, and the review confirmed those rows fixed.
> Across all 107 rubrics in docs/reviews/, the row results are the same before and after the change. The full suite passes: 2080 tests.
> The check is still report-only: it adds "rubric ..." lines to --check and --merge output and changes no verdict.
>
> What failed: the same pass taught the check to read rubric.md's "Carried forward" table, which lists rows moved from an older rubric.
> That code drops a carried red whose new row is an amber, so the amber's closure stands in for the red (rubric row R3, a regression).
> Before this pass, that table printed a loud "unread" line instead. There are 4 new ambers too: more "Fixed (partial)"-style wordings, one stale skill sentence, test gaps and wording.
> The review-fix loop's cap (workflows/review-fix-loop.md, "Iteration 4: cap-exceeded decision gate") now sits at the 4 passes you allowed, so I escalated and fixed nothing after the review.
> The details are in docs/reviews/code-review-rubric-2026-11-14-merge-rubric-gate.md, under "Cap decision (after iteration 4 of 4)".
>
> Which way should this land?
>
> | Option | What it means | Cost to you | If it's wrong |
> |---|---|---|---|
> | [1] one more pass, narrow | Pass 5: a carried row goes only to a row of its own tier (or that table goes back to "unread"); fix the wording; add the test cases | none now; the usual merge entry later | another regression, though the fix is a few lines with a test |
> | [2] pass 5, drop the table reading | Revert only the Carried forward reading to the loud "unread" line, then land | none now | rubrics using that template show an unread line until a follow-up |
> | [3] ship as is | Merge at this tip; the open rows go in the merge entry | read 1 red and 7 amber rows | a carried red can read as closed in advisory output |
> | [4] drop | Abandon the branch | none | the check waits for a new brief |
>
> My pick is [1], the rubric's recommendation. The tiebreaker: the fix is one same-tier lookup with a fixture that pins it, and it keeps the table support that rubric.md's new template needs.
> The design, the measurement and the pre-mortem are in docs/working/research-2026-11-14-merge-rubric-gate.md.

The cycle's notes on the loop's text above (from main's docs; the branch's claims are the loop's):
- **What Q-294 [1] bought:** the part that kept failing review (Split and Carried closing a red) is gone and review confirmed it fixed. The new red, R3, is in code the same pass added: reading the "Carried forward" table that Q-293's merged rules introduced (`skills/code-review/references/rubric.md`).
- **The pattern so far:** pass 3 left one red open, and pass 4 fixed it but added another. Option [2] removes only the newest code: the "Carried forward" table goes back to a loud "unread" line, which is what the check printed before this pass, so a rubric using that table shows "unread", never "clean". That is the fail-closed reading the constraints ask for (H2, a gate fails closed and loudly); option [1] keeps the table support, at the risk of another round like this one.
- **Either way it stays report-only** and comes back as a `merge-gate-` entry for your review: it is gate code (`scripts/lib/`, `scripts/build-loop.sh`, `skills/dev-cycle/`).
- **Budget:** this was dispatch 2 of at most 4 for the brief (D1, the build-loop dispatch cap in `docs/working/plan-build-loop-handoff.md`).
- **The loop's tests:** the full suite, 2080 passed, unconfined (`scripts/confine-tests.sh --probe` exited 3: no confinement here); the hermeticity lint is clean.

- **Read:** `docs/reviews/code-review-rubric-2026-11-14-merge-rubric-gate.md` ("Cap decision (after iteration 4 of 4)") and `docs/working/research-2026-11-14-merge-rubric-gate.md`, both on the branch

- **Blocks:** the roadmap Now item "Agent: review-gap audit fixes", its gate half.
- **Interim:** the loop is stopped at 27c32c32; nothing merges.
- **If the answer differs:** n/a; each option sets what the loop does next.

### Q-292 · cc-verify-host-check
**Needs:** you: terminal · **Opened:** 2026-11-13 · **Status:** OPEN

After Q-290's release paste (which runs `install.sh`; answer y to re-bless `cc-verify.sh`), run the two checks below on the host and paste the output here.

**If you say no:** the `cc-verify` fixes merged at `5740cbfd` stay on main untested on the host; their commits carry `Host-tool-tested: no (host run follows the merge)`, and `cc-verify --clean` and a relative REPO keep their old behaviour on your machine until `install.sh` re-blesses the new script.

The checks come from the build loop's report (its marker on branch `fix/cc-verify-clean-and-relative-repo`, loop text). The first makes a fake leftover run directory and expects `--clean` to remove it; the second runs a check with REPO `.` and declines the build, expecting no "could not clone" error.

```
mkdir -p ~/cc-verify/run-1-999999999 && cc-verify --clean; echo "clean exit $?"; printf 'true\n' > ~/cc-verify-true.sh && cc-verify --check ~/cc-verify-true.sh . main <<< n; echo "relative exit $?"; rm -f ~/cc-verify-true.sh
```

Expect: `cleaning .../run-1-999999999` and `clean exit 0`; then the y/N prompt, `declined: nothing was built.`, `relative exit 1`, and no `could not clone`. Run the second from inside a git checkout that has a `main` branch.

- **Interim:** the fixes are on main; the installed host copy of `cc-verify` is the old one until Q-290 runs.
- **Blocks:** closing the two roadmap items (`--clean`, `source_lines_ok`) as host-verified.

### Q-278 · q272-returned-run-or-refuse
**Needs:** you: judgment · **Opened:** 2026-11-11 · **Status:** OPEN

You asked for Q-272 back with data. When the test-confinement script (`scripts/confine-tests.sh`) cannot use `bwrap`, should it still run tests under its weaker tool, `unshare`, or refuse?

**If you say no:** your Q-272 answer stands, [1] "to start": the script runs under `unshare` after a warning. That is a provisional exception to hard constraint H2 (a degraded tool refuses and names what went unenforced), not written into `docs/constraints.md`.

**The data** (a build loop gathered it from the repo's records; nothing was run on the host):

- **How often `bwrap` is missing.** Not enough data yet. In this sandbox, and in the image sessions run today (536b7082), neither tool works: `bwrap` is not installed, and Docker's default seccomp refuses user namespaces, so `--probe` exits 3 here. The image after the release (Q-273, on hold for Q-277) installs `bwrap`. But in a session, that `bwrap` would run inside Claude Code's own sandbox, and nobody has tried that yet. Your host is not on record.
- **How much friction a refusal would cause.** None so far. 7 build loops ran the script (2026-11-05 to 2026-11-11), plus their reviewers. Every run exited 3 because neither tool worked, so the `unshare` fallback has never run and its warning has never printed. A refusal would have stopped 0 more runs. On exit 3 a loop already runs `scripts/run-tests.sh` unconfined, plus the hermeticity lint (a static check for tests that could reach the network). That fallback is weaker than `unshare`: it loses the network denial.
- **2026-11-12, one change to the first point.** The release that was to install `bwrap` did not ship it: main rolled the Bash sandbox back (7caea26d, your Q-277 answer [3]), and that revert also took `bwrap` out of the image. Sessions now run the image built from 80b7dabe, which has neither tool working, so the script still exits 3 here and nothing above has changed in practice.
- **One gap.** Every full test run already calls the real `--probe` (`test/scripts/confine-tests.bats:228-245`), and nothing records which tool it found.

- **Why it's yours:** it is an exception to a hard constraint, which only you grant.
- **Read:** `docs/working/research-2026-11-11-confine-tests-fallback-data.md` (merged at b9c8966a; section 3 lists six ways to track the warnings, none built) · Q-272 in `docs/working/questions-archive.md` · decision-log row 87

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Run and warn (as now)** | The fallback stays; the exception to H2 gets written into `docs/constraints.md` | One line in the constraints file | A fallback pass reads as "confined" to anyone who misses the warning; there have been 0 such runs so far |
| **[2] Refuse unless asked** | Without `bwrap` the script exits 3, unless a new flag asks for `unshare`; the briefs' test wording passes that flag | One self-merged build loop | A run without `bwrap` that does not pass the flag stops until someone passes it; 0 runs would have stopped so far |
| **[3] Always refuse** | Without `bwrap` the script exits 3; `unshare` only behind the existing `--no-loopback` flag | One self-merged build loop | Loops that hit the fallback lose the network denial, as every exit 3 does today |

The loop's tentative pick is [2], because it follows H2 as written with no exception and loops keep `unshare`'s network denial, which [3] gives up. If you'd rather wait for data, keep [1] until the first `--probe` inside a session after the release.

- **Blocks:** nothing. The script has no caller that the fallback would change today.
- **Interim:** [1], your Q-272 answer.
- **If the answer differs:** [2] or [3] becomes a brief for one build loop; [1] becomes one line in `docs/constraints.md`, which you commit.

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

