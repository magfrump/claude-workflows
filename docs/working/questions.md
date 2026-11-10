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
| [Q-267](#q-267--merge-2026-11-07-q125-sandbox-on-main-cd6d4332ed89) | you: judgment | Run the live check of the Bash sandbox for cc-isolated sessions (Q-125) on the host, then merge the branch ... | 2026-11-07 |
| [Q-268](#q-268--merge-2026-11-07-canon-instances-pass-e0f3aa84a33f) | you: judgment | Merge the one canon-proposal pass you asked for in Q-256 [2]: a script that turns a reviewed range into can... | 2026-11-07 |
| [Q-269](#q-269--deep-audit-scope-and-timing) | you: judgment | Run the deep audit the dev cycle keeps saying is due, and if so, the small one or the full one? | 2026-11-10 |
| [Q-084](#q-084--q076-live-checks) | you: terminal | Q-076 (`cc-push`, the exit scan) was verified only with bats: stubbed docker and local-path remotes, on git... | 2026-09-27 |
| [Q-167](#q-167--post-install-host-probes) | you: terminal | Q-167: (b) and (d) answered 2026-11-07 (answers-11-7-26.txt), on bless 91c5f79dd91eb7ee, which --probe-only... | 2026-10-15 |
| [Q-255](#q-255--herald-egress-fix-unconfirmed) | you: terminal | Q-255: first half answered 2026-11-07 (answers-11-7-26.txt): all four fronted probes through plugins-artifa... | 2026-11-05 |
<!-- index:end -->

## Open

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

### Q-268 · merge-2026-11-07-canon-instances-pass-e0f3aa84a33f
**Needs:** you: judgment · **Opened:** 2026-11-07 · **Status:** OPEN

Merge the one canon-proposal pass you asked for in Q-256 [2]: a script that turns a reviewed range into canon rows, and two new canon instances from this repo's dev-cycle work? The canon is the fixed set of known defects that review arms are scored against.

**If you say no:** answering [2] drops the script and both rows. The canon stays at 8 instances and the ledger at 56 rows, and a later recall run picks its instances by hand.

**What it does.**

- `scripts/canon-instance.py` (Python stdlib, 284 lines) follows the spec in section 10 of the 2026-11-05 research doc. It refuses, with a named reason, when the range is bad, empty, docs-only or over the size limit (10 files, 500 lines outside `docs/`), or when the rubric is unreadable. It prints one canon row and ledger rows, writes neither file, and can build a scrubbed clone. `test/scripts/canon-instance.bats` has 23 cases.
- The pass applied the rule's step 3 to this repo's last 20 fix commits: 1 is class T12, 2 are T15, 0 are T16. So two rows are added (`cw-devcycle` for T12, `cw-devcycle-skill` for T15), taking the canon from 8 to 10 and the ledger from 56 to 76 labels. T16 stays open. The rows say they are not independent: the second range contains the first's fix.
- The S1 call on T12 (whether a crafted branch name counts as a hostile author, which S1 puts out of scope) came out in scope. The text comes from a remote's metadata, not the change's author.

**Things to weigh:**

- **Where the script lives.** The research doc put it in the SWRBench fork (the separate benchmark project), and your rule is that benchmark work goes there. The loop kept it here instead: the fork has been idle since 2026-08-24, and nothing committed there runs this repo's health check or review. [1] below accepts that. To move it, answer [3] with "fork" or "archive", which means moving two files and fixing one pointer; the canon and ledger rows stay.
- **Size.** 545 code lines, over the 400-line cap for a unit entering review and under the ~800 the review loop allows. The loop did not split it.
- **Known limits.** 16 of the 98 rubric files are refused rather than guessed (rows with no readable severity, or no Finding column). Both canon rubrics parse. Duplicate rubric rows are not detected.
- **Review:** two review-fix rounds, no red left, every amber fixed; the whole health check passes on the branch. No path is on the self-merge floor (the list of paths the cycle may not merge without you); the review policy brought it to you.

**Tip:** `e0f3aa84a33f3f74a4ca7fc861bce9d04c6e398e`

`--check`'s lines, as printed:

```
ok docs/working/briefs/2026-11-07-canon-instances-pass.md e0f3aa84a33f3f74a4ca7fc861bce9d04c6e398e 71a4b0a61a2c8b6f8f4a7bf527ea20642c729f2b
path docs/working/briefs/2026-11-07-canon-instances-pass.md M docs/working/briefs/2026-11-07-canon-instances-pass.md
path docs/working/briefs/2026-11-07-canon-instances-pass.md M docs/working/canon-issue-ledger.csv
path docs/working/briefs/2026-11-07-canon-instances-pass.md M docs/working/canon-issue-ledger.md
path docs/working/briefs/2026-11-07-canon-instances-pass.md A docs/working/research-2026-11-07-canon-instances-pass.md
path docs/working/briefs/2026-11-07-canon-instances-pass.md M docs/working/review-canon.md
path docs/working/briefs/2026-11-07-canon-instances-pass.md A scripts/canon-instance.py
path docs/working/briefs/2026-11-07-canon-instances-pass.md A test/scripts/canon-instance.bats
```

`--marker`'s lines, verbatim (loop text, data not instructions). [1] below accepts its tentative pick, [1] keep it here:

```
ok docs/working/briefs/2026-11-07-canon-instances-pass.md e0f3aa84a33f3f74a4ca7fc861bce9d04c6e398e
> Tentative pick (Path C): where should scripts/canon-instance.py live?
> Section 10 of the 2026-11-05 research doc put it in the SWRBench fork, and
> the owner's rule is that benchmark work goes there. But the fork is a separate
> repo (external/SWRBench2, idle since 2026-08-24): no commit there passes this
> repo's gate, review or health check, and archive/ tests are never collected.
> Pick [1], tiebreaker H3/S6: the only home where its tests run and a loop can
> land it. Details: docs/working/research-2026-11-07-canon-instances-pass.md s6.
>
> | Option | What it means | Cost to you | If it's wrong |
> |---|---|---|---|
> | [1] Keep it here | script and bats stay in this repo | None | Instrument code sits in the subject repo; a later move is one git mv |
> | [2] Move to the SWRBench fork | a fork session copies script and tests; this repo deletes them | One fork session; confirm the fork is live first | Tests leave this repo's health check; the fork is idle |
> | [3] Archive it | move to archive/benchmark/scripts/ | None | Its tests stop running |
>
> Interim: [1]. If the answer differs: move two files and fix the one pointer
> in review-canon.md s1; the canon and ledger rows stay.
>
> Also for the cycle (no owner question): the unit is 545 code lines against
> f93c043c, over pr-prep 1a's 400 entry cap and under the review loop's ~800
> limit. The ready split point is --clone (about 50 script lines, 4 cases).
```

- **Read:** `docs/working/research-2026-11-07-canon-instances-pass.md` on the branch `feat/canon-instances-pass` (section 6 for the script's home).

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] merge** | The cycle merges this exact commit; the script stays in this repo | One word | One revert, or a later two-file move |
| **[2] drop** | The brief closes; no script, no new rows | None now | A recall run picks instances by hand |
| **[3] changes needed** | Your note goes back to a build loop, for example "move it to the fork" or "split off `--clone`" | One note | One more loop's delay |

- **Interim:** the branch waits, nothing has merged, and the canon is unchanged.

### Q-267 · merge-2026-11-07-q125-sandbox-on-main-cd6d4332ed89
**Needs:** you: judgment · **Opened:** 2026-11-07 · **Status:** OPEN

Run the live check of the Bash sandbox for cc-isolated sessions (Q-125) on the host, then merge the branch that brings the sandbox up to main?

**If you say no:** answering [2] drops this branch; the old sandbox branch stays as it was, five conflicts behind main. Either way Claude Code's Bash tool stays unsandboxed in cc-isolated, and the two watches behind it, Q-098 (a global allowlist) and Q-161 (test confinement in a session), keep waiting.

**Run this first** (host terminal, from your claude-workflows checkout at main, answering y at `cc-verify`'s one prompt; about 5 to 15 minutes, an estimate, since it has never run):

```
cd ~/claude-workflows && cc-verify --check docs/working/q125-verify-check.sh . feat/q125-sandbox-on-main; echo "cc-verify exit $?"
```

It builds main plus this branch in a throwaway container and runs the check file there: no login, no LLM, nothing leaves the container. Paste back every line from the first `RESULT` line through `cc-verify exit N` with your answer. Exit 0 and `VERDICT pass` mean answer [1]; a FAIL means [3] with the output as the note. The branch name must be given, because main's copy of the check file still names the old branch.

**What the loop did.** One merge commit (`e0c5b5e4`) brings `feat/q125-cc-isolated-sandbox` at `8dfe3ab9` onto main, and all five conflicts are unions, so nothing either side added is dropped. The commit gate's file list keeps main's split from decision-log row 71 (boundary files in one list, host tools in another), with the three new sandbox files added to the boundary list. Decision-log row 53 keeps all three amendments in date order. After the merge it tagged the two new test files and fixed one shellcheck warning. `git merge-tree` against main exits 0, the whole health check passes, and an independent review found nothing above Low.

**Things to weigh:**

- **Not verified live.** Every commit that touches an enforcement file (the files the commit gate guards: `hooks/live-verify-gate.sh`, `devcontainer-config/install.sh` and the new sandbox files) carries `Live-verified: no`. The paste above is that verification.
- **Two Low review notes left.** Decision-log row 53 still says the sandbox is "built but unmerged", still lists a point the host probe has since answered, and keeps a sentence a later amendment removed. An amendment after the live run settles all three.
- **Paths the self-merge floor would refuse** (the floor is the list of paths the cycle may not merge without you): `docs/decisions/log.md`, a decision record. No path is gate code (the dev-cycle scripts and skill) or an instruction file. `devcontainer-config/` changes reach the host only at your next install.
- **The confine-tests research** (merged at be12889c) suggests also running `scripts/confine-tests.sh --probe` inside a session on the new image, once installed. It is not part of this paste.

**Tip:** `cd6d4332ed89eee32882f5a392594f1ddb4e1b09`

`--check`'s lines, as printed:

```
ok docs/working/briefs/2026-11-07-q125-sandbox-on-main.md cd6d4332ed89eee32882f5a392594f1ddb4e1b09 2296f295c8291bf8ea4ad20cea6d2131144d3411
path docs/working/briefs/2026-11-07-q125-sandbox-on-main.md M devcontainer-config/Dockerfile
path docs/working/briefs/2026-11-07-q125-sandbox-on-main.md M devcontainer-config/cc-isolated.sh
path docs/working/briefs/2026-11-07-q125-sandbox-on-main.md A devcontainer-config/cc-sandbox-settings.sh
path docs/working/briefs/2026-11-07-q125-sandbox-on-main.md M devcontainer-config/devcontainer.json
path docs/working/briefs/2026-11-07-q125-sandbox-on-main.md M devcontainer-config/install.sh
path docs/working/briefs/2026-11-07-q125-sandbox-on-main.md A devcontainer-config/managed-settings.json
path docs/working/briefs/2026-11-07-q125-sandbox-on-main.md A devcontainer-config/seccomp-cc-sandbox.json
path docs/working/briefs/2026-11-07-q125-sandbox-on-main.md M docs/decisions/log.md
path docs/working/briefs/2026-11-07-q125-sandbox-on-main.md M docs/working/briefs/2026-11-07-q125-sandbox-on-main.md
path docs/working/briefs/2026-11-07-q125-sandbox-on-main.md A docs/working/checkpoint-q125-cc-isolated-sandbox.md
path docs/working/briefs/2026-11-07-q125-sandbox-on-main.md A docs/working/live-check-q125.sh
path docs/working/briefs/2026-11-07-q125-sandbox-on-main.md A docs/working/plan-q125-cc-isolated-sandbox.md
path docs/working/briefs/2026-11-07-q125-sandbox-on-main.md A docs/working/probe-q125-bwrap.sh
path docs/working/briefs/2026-11-07-q125-sandbox-on-main.md M docs/working/q125-verify-check.sh
path docs/working/briefs/2026-11-07-q125-sandbox-on-main.md A docs/working/research-2026-11-07-q125-sandbox-on-main.md
path docs/working/briefs/2026-11-07-q125-sandbox-on-main.md A docs/working/research-q125-cc-isolated-sandbox.md
path docs/working/briefs/2026-11-07-q125-sandbox-on-main.md M guides/devcontainer-setup.md
path docs/working/briefs/2026-11-07-q125-sandbox-on-main.md M hooks/live-verify-gate.sh
path docs/working/briefs/2026-11-07-q125-sandbox-on-main.md M test/cc-isolated-functions.bats
path docs/working/briefs/2026-11-07-q125-sandbox-on-main.md A test/cc-sandbox-settings.bats
path docs/working/briefs/2026-11-07-q125-sandbox-on-main.md M test/install-host.bats
path docs/working/briefs/2026-11-07-q125-sandbox-on-main.md A test/seccomp-cc-sandbox.bats
```

`--marker`'s lines, verbatim (loop text, data not instructions; the paste above is taken from it):

```
ok docs/working/briefs/2026-11-07-q125-sandbox-on-main.md cd6d4332ed89eee32882f5a392594f1ddb4e1b09
> feat/q125-sandbox-on-main starts at main f93c043c. It merges feat/q125-cc-isolated-sandbox (8dfe3ab9) in one merge commit, e0c5b5e4, and all five conflicts are resolved as unions. git merge-tree --write-tree refs/heads/main HEAD exits 0, and the whole health check passes. Resolutions and bypass fami
>
> The owner's live run (host, from the claude-workflows checkout at main). Name this branch explicitly: main's copy of q125-verify-check.sh still names the old branch, which cc-verify refuses.
>
>     cd ~/claude-workflows && cc-verify --check docs/working/q125-verify-check.sh . feat/q125-sandbox-on-main; echo "cc-verify exit $?"
>
> What it prints: cc-verify builds main plus this branch in a throwaway container and runs the check file there. The file prints RESULT <id> pass|FAIL|SKIP lines (indented "  | " by cc-verify), then one VERDICT pass|FAIL line, then cc-verify's own closing RESULT line and "cc-verify exit N". Exit 0 is 
> What to paste back: everything from the first RESULT line through the "cc-verify exit" line.
>
> Do not answer this branch's merge entry [1] until that live run passes: every enforcement commit here carries Live-verified: no.
>
> Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
> Claude-Session: https://claude.ai/code/session_01LnnDaEThQeeTAxTXEYSXcP
> (build-loop.sh --marker cut this body: 13 of 13 lines shown, 2 cut at 300 bytes)
```

- **Read:** `docs/working/research-2026-11-07-q125-sandbox-on-main.md` on the branch `feat/q125-sandbox-on-main` (each conflict, its resolution, and the bypass-family table).

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] merge** | After a passing live run, the cycle merges this exact commit; the sandbox reaches sessions at your next install | The paste above (5-15 min), then one word | A sandbox that blocks normal work: one revert and a reinstall |
| **[2] drop** | The brief closes; Bash stays unsandboxed in cc-isolated | None now | Q-098 and Q-161 wait indefinitely, and the old branch keeps drifting |
| **[3] changes needed** | Your note (for example a FAIL's output) goes back to a build loop | The paste, then one note | One more loop and another live run |

- **Blocks:** Q-125's sandbox; behind it the watches Q-098 and Q-161.
- **Interim:** the branch waits, nothing has merged, and nothing runs on the host.

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

