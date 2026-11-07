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
| [Q-256](#q-256--canon-proposal-filter-choice) | you: judgment | How should new instances get proposed for the canon, the fixed set of known defects that review arms are sc... | 2026-11-05 |
| [Q-265](#q-265--merge-2026-11-03-q125-verify-check-60138c791b1f) | you: judgment | Merge the live-check file for the Bash sandbox (Q-125), and have a build loop resolve the sandbox branch's ... | 2026-11-06 |
| [Q-266](#q-266--merge-gate-2026-11-06-codify-trial-practices-e49f133c98fd) | you: judgment | Merge the change that writes the first trial set's seven practices (T1-T7, defined in `docs/working/trials/... | 2026-11-06 |
| [Q-084](#q-084--q076-live-checks) | you: terminal | Q-076 (`cc-push`, the exit scan) was verified only with bats: stubbed docker and local-path remotes, on git... | 2026-09-27 |
| [Q-167](#q-167--post-install-host-probes) | you: terminal | The install is done: the image was built from main at fbe67674 on 2026-10-16 (Q-156), and it carries all th... | 2026-10-15 |
| [Q-255](#q-255--herald-egress-fix-unconfirmed) | you: terminal | The fix for herald's `dl.google.com` build failures was released on 2026-10-28 (Q-214), but no output was k... | 2026-11-05 |
| [Q-261](#q-261--image-lag) | you: terminal | Run the paste below to bring the installed dev-cycle scripts up to main. | 2026-11-06 |
<!-- index:end -->

## Open

### Q-266 · merge-gate-2026-11-06-codify-trial-practices-e49f133c98fd
**Needs:** you: judgment · **Opened:** 2026-11-06 · **Status:** OPEN

Merge the change that writes the first trial set's seven practices (T1-T7, defined in `docs/working/trials/2026-10-30-friction-engagement.md`) into the dev cycle?

**If you say no:** the practices keep running only because each session reads the trial doc and session memory. Nothing else changes.

**What an attacker would want here:** an outside party gains little. The one logic change adds dated weekly digests under `docs/working/weekly/` to the files the cycle may land itself, and a build loop's branch still cannot write them.

**What it does.** Each practice is written once in `skills/dev-cycle/SKILL.md`, where the writer meets it: short release notes, the "If you say no:" line, batched answers, the weekly digest with its stale-entry line, the reserved security marker, and treating a warning printed on every run as a bug.

**Things to weigh:**

- **T4 is narrower than the trial said.** The cycle cannot close one of your `you:` entries (`--cycle-diff` refuses it), so an entry whose closure line is met gets a proposed fate in the weekly digest instead. Watches and agent items close as before.
- **T3 now has a written bound.** A batched answer counts only as an unconditional instruction with an option, naming the IDs or the orchestrator's own last block. It covers only the merge entries that block listed.
- **T5 is only partly live before the release.** The digest can land with the record now; the refusal of a wrong-case path and the digest's listing wait for the next install.
- **Review was lighter than the skill asks.** Fact-checks ran once, not three times, on the final pass, and the last pass was a review of the latest changes rather than the full two clean passes. The architecture review was not run. The rubric has 0 red and 0 amber open, with three "consider" notes, and it does not spell out all of these departures. If you want a full final pass first, answer [3].
- **Tests:** the last full run passed at `4873ac59` (1981 tests). After that only two prose clauses changed, and the loop reran 6 affected tests. One earlier full run failed one test, because of a helper left by another test run; it passed alone and in both later full runs. The last hermeticity lint's exit status was not captured.

**Paths the self-merge floor would refuse** (the floor is the list of paths the cycle may not merge without you): `scripts/build-loop.sh`, `scripts/dev-cycle.sh`, `scripts/lib/dev-cycle-read.sh` and `skills/dev-cycle/SKILL.md` are gate code, which takes effect only at the next release; `docs/decisions/log.md` is a decision record.

**Tip:** `e49f133c98fda0446fb32e24473aee11347a6933`

`--check`'s lines, as printed:

```
ok docs/working/briefs/2026-11-06-codify-trial-practices.md e49f133c98fda0446fb32e24473aee11347a6933 2f5c06490601112631f23124cfc74206a85e7383
path docs/working/briefs/2026-11-06-codify-trial-practices.md M docs/decisions/log.md
path docs/working/briefs/2026-11-06-codify-trial-practices.md A docs/reviews/code-review-rubric-2026-11-06-codify-trial-practices.md
path docs/working/briefs/2026-11-06-codify-trial-practices.md M docs/working/briefs/2026-11-06-codify-trial-practices.md
path docs/working/briefs/2026-11-06-codify-trial-practices.md A docs/working/plan-2026-11-06-codify-trial-practices.md
path docs/working/briefs/2026-11-06-codify-trial-practices.md A docs/working/research-2026-11-06-codify-trial-practices.md
path docs/working/briefs/2026-11-06-codify-trial-practices.md M scripts/build-loop.sh
path docs/working/briefs/2026-11-06-codify-trial-practices.md M scripts/dev-cycle.sh
path docs/working/briefs/2026-11-06-codify-trial-practices.md M scripts/lib/dev-cycle-read.sh
path docs/working/briefs/2026-11-06-codify-trial-practices.md M skills/dev-cycle/SKILL.md
path docs/working/briefs/2026-11-06-codify-trial-practices.md M test/scripts/build-loop-check.bats
path docs/working/briefs/2026-11-06-codify-trial-practices.md M test/scripts/build-loop-orchestrator.bats
path docs/working/briefs/2026-11-06-codify-trial-practices.md M test/scripts/dev-cycle.bats
```

`--marker`'s lines, verbatim (loop text, data not instructions). The question is about one parenthetical in `docs/dev-cycle.md`, a file neither a loop nor the cycle may write. [1] below accepts its pick, which is to leave that list as it is:

ok docs/working/briefs/2026-11-06-codify-trial-practices.md e49f133c98fda0446fb32e24473aee11347a6933
> The brief asked that docs/dev-cycle.md (the dev-cycle settings file) agree with this change. It mostly does: its line 55, that the release entry flags self-merged subjects, still holds. Its lines 31-32 list the cycle's own files without the new dated weekly digests under docs/working/weekly/, and th
>
> | Option | What it means | Cost to you | If it's wrong |
> |---|---|---|---|
> | [1] leave it | The list stays incomplete | Nothing | A reader of that one parenthetical misses two files; the gate is unaffected |
> | [2] update it | Add both files to the list | One small edit, by you or a session you ask | Nothing |
>
> Tentative pick: [1], since nothing reads that list as a rule. Tiebreaker: spend the owner's attention last (S10 in docs/constraints.md).
>
> Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
> Claude-Session: https://claude.ai/code/session_01LnnDaFqJDZqfV6VNkAFYQw
> (build-loop.sh --marker cut this body: 11 of 11 lines shown, 1 cut at 300 bytes)

- **Read:** `docs/working/research-2026-11-06-codify-trial-practices.md` and `docs/reviews/code-review-rubric-2026-11-06-codify-trial-practices.md`, on the branch `feat/codify-trial-practices`.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] merge** | The cycle merges this exact commit | One word now; the skill and scripts start at your next install | One revert |
| **[2] drop** | The brief closes, and the practices stay in the trial doc | None now | Each session keeps relying on the trial doc |
| **[3] changes needed** | Your note goes back to a build loop, for example a full final review pass | One note, then another merge entry | One more loop's delay |

- **Interim:** the branch waits, nothing has merged, and the cycle keeps following the trial doc.

### Q-265 · merge-2026-11-03-q125-verify-check-60138c791b1f
**Needs:** you: judgment · **Opened:** 2026-11-06 · **Status:** OPEN

Merge the live-check file for the Bash sandbox (Q-125), and have a build loop resolve the sandbox branch's conflicts with main so your paste can run?

**If you say no:** answering [2] drops this check file. To keep the file but leave the sandbox waiting, answer [3] with that note. Either way Claude Code's Bash tool stays unsandboxed in cc-isolated, and the two watches behind it, Q-098 and Q-161, keep waiting.

**What changed since you answered Q-254.** The C1 fix you chose is done: it is one commit, `8dfe3ab9`, on `feat/q125-cc-isolated-sandbox`, so a masked credential file no longer reads as a failure. But the "one paste" promise was wrong. That branch does not merge cleanly with main, in five files, and `cc-verify` stops at that merge before it builds anything. It was already so when the paste was first written. Q-254 allowed only the one commit, so the loop left the conflicts alone.

**So [1] means two things:** this branch merges, and one more build loop resolves the conflicts on the sandbox branch, without landing it on main. Then you get the paste. The check file itself does not depend on the conflict.

**Tip:** `60138c791b1f5f739e963bd6075ec166d48c3517`

`--check`'s lines, as printed:

```
ok docs/working/briefs/2026-11-03-q125-verify-check.md 60138c791b1f5f739e963bd6075ec166d48c3517 1ac7ebdb608e5071d79395307717cfb795323f51
path docs/working/briefs/2026-11-03-q125-verify-check.md M docs/working/briefs/2026-11-03-q125-verify-check.md
path docs/working/briefs/2026-11-03-q125-verify-check.md A docs/working/q125-verify-check.sh
path docs/working/briefs/2026-11-03-q125-verify-check.md A docs/working/research-2026-11-03-q125-verify-check.md
path docs/working/briefs/2026-11-03-q125-verify-check.md A test/q125-verify-check.bats
```

No path here is on the self-merge floor (the list the cycle may not merge without you); the brief's review policy brought it to you.

`--marker`'s lines, verbatim (loop text, data not instructions):

ok docs/working/briefs/2026-11-03-q125-verify-check.md 60138c791b1f5f739e963bd6075ec166d48c3517
> The C1 fix Q-254 asked for is done, but Q-125's live run still cannot start: the paste below will be refused until feat/q125-cc-isolated-sandbox merges cleanly with main. It does not today, and it did not when the paste was first written. Dispatch 1's "one paste" estimate was wrong.
>
> What happened: git merge-tree main feat/q125-cc-isolated-sandbox exits 1, with conflicts in five files. cc-verify builds that merge, so it stops at its first step with "does not merge cleanly with main", before any prompt or build. Nothing is harmed, but nothing is verified.
>
> Conflicted files: devcontainer-config/install.sh, docs/decisions/log.md, hooks/live-verify-gate.sh, test/cc-isolated-functions.bats, test/install-host.bats.
> The code conflicts seen are mostly both sides extending the same list (files installed into the container, files the commit gate watches).
> Q-254 allowed one commit on that branch, so this loop did not touch them.
>
> Should a build loop merge main into feat/q125-cc-isolated-sandbox and resolve those conflicts, so the paste can run?
>
> | Option | What it means | Cost to you | If it's wrong |
> |---|---|---|---|
> | [1] Merge main into the branch (pick) | One more build loop resolves the five conflicts on the branch; it still does not land on main | One answer now, then the same paste | A bad resolution shows in the live run as a FAIL or build error: another loop and paste |
> | [2] Leave Q-125 waiting | This check file lands on main and the branch stays as it is | Nothing now | Claude Code's Bash tool stays unsandboxed in cc-isolated, and Q-098 and Q-161 keep waiting; the branch drifts further from main |
>
> Pick: [1]. Tiebreaker: the owner already chose to get this run done in Q-254, and [1] is the only option that lets it happen. This branch can merge under either answer: it does not depend on the conflict.
>
> The paste, for after the conflicts are resolved and this branch is on main. Run it on the host from the root of your claude-workflows checkout, on main, and answer y at cc-verify's one prompt:
>
>     cc-verify --check docs/working/q125-verify-check.sh . feat/q125-cc-isolated-sandbox; echo "cc-verify exit $?"
>
> What it does: cc-verify builds main + the branch in a throwaway container. The check file runs headless claude -p against a local model stub (no login, no LLM, nothing leaves the container).
> The stub asks for two sandboxed Bash tool calls: the file's own X checks, then the branch's live-check-q125.sh. It takes about 5 to 15 minutes (an estimate; it has never run) and cleans up after itself.
>
> Expected output: indented "  | RESULT <id> pass|FAIL ..." lines, then "  | VERDICT pass|FAIL", then cc-verify's own "RESULT cc-verify pass|fail" and "cc-verify exit 0|3".
> Paste back: every line from the first "| RESULT" through the "cc-verify exit" line.
>
> What changed on the branch: 8dfe3ab9 (one commit, docs/working/live-check-q125.sh only). All four C1 reads now judge by what they print, not by exit status, and the result ids are the same.
> cat fails on any byte of output rather than a marker grep, so the abort does not depend on knowing the credential's format.
>
> Checked: a scratch probe of the script's C1 section only, plus one independent review (no Must fix). The sandbox's real /dev/null bind could not be run here, so the live run is its first real test. The whole health check passes on this branch.
>
> Known and left alone, none of them reachable from the paste unless noted:
> - The script's --watch loop (C10) has the same exit-status bug. The paste does not use --watch; a hand run would print a false FAIL.
> - On an unsandboxed hand run, a credential with no bytes passes C1 and continues to the write checks. The check file always plants a canary, so the paste cannot reach this.
> - On an unsandboxed hand run, a readable credential is now copied into a 0700 temp dir until exit, not sent to /dev/null.
> - Reachable from the paste: C3-nested-settings-1 may FAIL. The repo tracks no .claude/ directory, so the check tries mkdir there, which the sandbox probably allows. That would be a real finding about agent worktrees.
> - Reachable from the paste: the stub path is unverified live. If Claude Code does not talk to it as expected, the Q0-* lines FAIL and name the cause; it never passes vacuously.
>
> Files: docs/working/q125-verify-check.sh, test/q125-verify-check.bats, docs/working/research-2026-11-03-q125-verify-check.md.
>
> Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
> Claude-Session: https://claude.ai/code/session_01LnnDaFqJDZqfV6VNkAFYQw

- **Read:** `docs/working/research-2026-11-03-q125-verify-check.md` on the branch `feat/q125-verify-check`.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] merge** | This branch merges, and a build loop resolves the five conflicts on the sandbox branch | One word now, then the paste | A bad resolution shows in the live run as a FAIL or build error: another loop and paste |
| **[2] drop** | The brief closes, and the check file does not land | None now | The check file would have to be rebuilt to verify the sandbox |
| **[3] changes needed** | Your note goes back to a build loop, for example to merge this file and leave the sandbox waiting | One note | The branch drifts further from main while it waits |

- **Blocks:** Q-125's live run; behind it the watches Q-098 and Q-161.
- **Interim:** the branch waits, and nothing runs on the host.

### Q-261 · image-lag
**Needs:** you: terminal · **Opened:** 2026-11-06 · **Status:** OPEN

Run the paste below to bring the installed dev-cycle scripts up to main.

**Release notes.** The installed image is the root-owned copy of the dev-cycle scripts and skill. It is at `dff98910` (read from `/opt/claude-workflows/.manifest`), and main is ahead of it by the two merges you approved today, Q-259 and Q-260. Neither is live until you run the paste below.

**If you say no:** the cycle keeps pasting the roughly 60-line block into every script call, and finished build loops keep their worktrees (2.85 GiB at last count) and branches. Nothing breaks.

**What changes for you:**

- That block becomes `scripts/d6.sh`, one line to call, and drops the five checks the restriction audit judged hostile-only (from Q-259).
- Each cycle's cleanup step removes a finished loop's worktree, so its merged branch can then be deleted (from Q-260).
- Agents get the rule to explain every internal reference in plain language (from Q-263). The build-loop prompt and skill parts start here; the global-instructions part reaches sessions with the host install.

**Merged without your review:** one design record and its brief, both docs (`e9f3e176`, flagged below). The image carries neither.

**Commits since the image:**

- `85080263` Merge branch 'refactor/free-merged-loop-worktrees' (build-loop approved merge)
- `aeab6745` Merge branch 'refactor/d6-block-into-image' (build-loop approved merge)
- `771c84e8` Merge branch 'feat/owner-entry-gloss-rule' (build-loop approved merge)
- `e9f3e176` Merge branch 'docs/merge-friction-design' (build-loop self-merge): no one reviewed it
- `21399f53` Merge branch 'docs/trial-feedback-2026-11-06' (your end-of-trial feedback, one doc)
- `3ca1bc5c`, `9f3758c5`, `abea6674`, `37a56702`, `62687b97`, `657b96b4`, `65fd1b17` and `f979bc57`: cycle lands, records only

**Gate files changed:** `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `scripts/lib/migrations.sh`, `skills/dev-cycle/SKILL.md`, and the new `scripts/d6.sh`.

**Paths outside `docs/`** (37 paths under `docs/` also changed; the image carries none of them): `global-instructions/CLAUDE.md`, `scripts/build-loop.sh`, `scripts/d6.sh`, `scripts/lib/dev-cycle-read.sh`, `scripts/lib/migrations.sh`, `skills/dev-cycle/SKILL.md`, `test/questions-doc.bats`, `test/scripts/build-loop-check.bats`, `test/scripts/build-loop-dispatch.bats`, `test/scripts/build-loop-free.bats`, `test/scripts/build-loop-orchestrator.bats`

**The paste** (host terminal in WSL, not inside a session; stop every session first):

```
cd /home/magfrump/claude-workflows && test "$(git rev-parse HEAD)" = 771c84e8a1800c095aaa9821607713d11ef0928b && ./devcontainer-config/install.sh
```

The `rev-parse` check runs no hook. It only confirms your checkout is at `771c84e8`, which holds Q-263's rule. Main will be past that commit by the time you read this, because the cycle's own land moves it, so check out `771c84e8` first. That checkout, like any other git command on the host, can run a hook a sandbox session planted, which is `install.sh`'s own trust model. If the install re-blesses, it also prints the hint that Q-167's step (a) still needs.

- **Interim:** the image at `dff98910` runs.

### Q-256 · canon-proposal-filter-choice
**Needs:** you: judgment · **Opened:** 2026-11-05 · **Status:** OPEN

How should new instances get proposed for the canon, the fixed set of known defects that review arms are scored against?

**If you say no:** with no answer the interim [1] stands, so nothing is built and no instance is added until a recall run (a measured re-test of review quality) is briefed. Nothing is burning.

No review work now scheduled needs a new instance, and the canon has had no run in about 11 weeks. There is a gap for harness work: 12% to 20% of the sampled in-scope findings sit in three classes the canon lacks (hostile-shaped text, instruction prose, performance). That figure comes from this repo only, and the classes and the 12-row cap are the build loop's own. The loop's tentative pick is [1], at 55% confidence.

- **Read:** `docs/working/research-2026-11-05-canon-proposal-filter.md`, sections 8 and 10 (the rule, the dry run and the script spec).

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Scheduled pass** | Nothing is built now. When a recall run is briefed, one pass applies the rule and proposes at most 3 instances | About 10 minutes, once, at that run | No run comes, and nothing differs from [4] |
| **[2] One pass now** | The same rule today with this repo as the subject: build the script, add 1 or 2 dev-cycle candidates as rows | About 10 minutes now | Effort goes into harness-only instances no run may use |
| **[3] Standing scan** | A script checks new rubrics each cycle and files proposals | A triage entry when one fires | A standing script for a rule that closes after one pass |
| **[4] Leave it** | No proposals; the canon grows only by hand | None | A recall run on shell or prose work has no instance and picks ad hoc |

- **Interim:** [1]. The canon and ledger are unchanged. The watch on "a recall run is briefed" is filed once you answer [1].
- **If the answer differs:** [2] starts a build brief, [3] adds a classifier, [4] needs no watch. Nothing needs undoing.

### Q-255 · herald-egress-fix-unconfirmed
**Needs:** you: terminal · **Opened:** 2026-11-05 · **Status:** OPEN

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

