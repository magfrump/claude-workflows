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
| [Q-281](#q-281--constraint-s4-keep-promote-drop) | you: judgment | Should soft constraint S4 in `docs/constraints.md` ("mechanical steps go in tested scripts, not prose") sta... | 2026-11-13 |
| [Q-282](#q-282--constraint-s8-no-growth-clause) | you: judgment | Should the "no growth of the 500-plus-line files" clause of soft constraint S8 stay as it is, be reworded a... | 2026-11-13 |
| [Q-283](#q-283--constraint-s10-owner-wait-clause) | you: judgment | Should the S10 clause "no merge or loop that waits on the user's manual action when a fail-closed alternati... | 2026-11-13 |
| [Q-284](#q-284--constraint-instrument-code-in-fork) | you: judgment | Should the unwritten rule "benchmark and review-instrument code lives in the SWRBench fork" stay out of `do... | 2026-11-13 |
| [Q-285](#q-285--review-gap-audit-which-repo) | you: judgment | Which repo should the review-gap audit run on first, or should the item be dropped? | 2026-11-13 |
| [Q-286](#q-286--trial-set-2-ends) | you: judgment | The second trial set (T8–T12) ends about today. Which of them should stay? | 2026-11-13 |
| [Q-287](#q-287--merge-2026-11-13-small-records-review-68b106d0a358) | you: judgment | Merge the four small record fixes (brief `docs/working/briefs/2026-11-13-small-records-review.md`, branch `... | 2026-11-13 |
| [Q-288](#q-288--merge-2026-11-13-cc-verify-clean-and-relative-repo-f16bbdcedaf8) | you: judgment | Merge the three `cc-verify` fixes (brief `docs/working/briefs/2026-11-13-cc-verify-clean-and-relative-repo.... | 2026-11-13 |
| [Q-084](#q-084--q076-live-checks) | you: terminal | Q-076 (`cc-push`, the exit scan) was verified only with bats: stubbed docker and local-path remotes, on git... | 2026-09-27 |
| [Q-167](#q-167--post-install-host-probes) | you: terminal | Q-167: (b) and (d) answered 2026-11-07 (answers-11-7-26.txt), on bless 91c5f79dd91eb7ee, which --probe-only... | 2026-10-15 |
| [Q-255](#q-255--herald-egress-fix-unconfirmed) | you: terminal | Q-255: first half answered 2026-11-07 (answers-11-7-26.txt): all four fronted probes through plugins-artifa... | 2026-11-05 |
<!-- index:end -->

## Open

### Q-287 · merge-2026-11-13-small-records-review-68b106d0a358
**Needs:** you: judgment · **Opened:** 2026-11-13 · **Status:** OPEN

Merge the four small record fixes (brief `docs/working/briefs/2026-11-13-small-records-review.md`, branch `docs/small-records-review`)?

**If you say no:** nothing merges; the health check keeps printing the `Harness feedback` warning, and the decision log still says every cycle iteration is a full cycle.

The four fixes, all docs, 113 lines added and 6 removed:
1. Decision-log row 89 records your Q-270 [2] (the light pass between full cycles) as the new answer to D12, the build-loop handoff plan's "every iteration is a full cycle", and the plan is corrected to match.
2. `AGENTS.md` and `GEMINI.md` each gain a 2-line `## Harness feedback` section, a tool-neutral version of the global instructions' section (it names `guides/harness-feedback.md` and lets an agent run `harness-feedback.py` from `~/.claude/scripts/` or a claude-workflows clone). Those files are symlinked into other projects, which is why they need it. This ends the warning every health check printed.
3. Decision 018 cites its reference pattern in `scripts/confine-tests.sh` by the comment's text instead of a line number that drifted.
4. A new failure pattern, FP-181: under `sh` where `sh` is bash, `exec "$@"` reads a dash-leading word as an option (`-a NAME CMD` runs a different program; fixed in `b0ebed19`).

Tip `68b106d0a358945a9341fc6a857416f48e856db3`. The gate's check, as printed:

```
ok docs/working/briefs/2026-11-13-small-records-review.md 68b106d0a358945a9341fc6a857416f48e856db3 8e504d69b7d7c841db99c1fde94761009da9f4e1
path docs/working/briefs/2026-11-13-small-records-review.md M AGENTS.md
path docs/working/briefs/2026-11-13-small-records-review.md M GEMINI.md
path docs/working/briefs/2026-11-13-small-records-review.md M docs/decisions/018-argv-exec-over-shell-string-interpolation.md
path docs/working/briefs/2026-11-13-small-records-review.md M docs/decisions/log.md
path docs/working/briefs/2026-11-13-small-records-review.md M docs/failure-patterns.md
path docs/working/briefs/2026-11-13-small-records-review.md M docs/working/briefs/2026-11-13-small-records-review.md
path docs/working/briefs/2026-11-13-small-records-review.md M docs/working/plan-build-loop-handoff.md
path docs/working/briefs/2026-11-13-small-records-review.md A docs/working/research-2026-11-13-small-records-review.md
```

Self-merge's rules would have refused `AGENTS.md` and `GEMINI.md` (instruction files other agents load) and the decision records and failure patterns (your records), which is why this one comes to you. The loop's marker had no question. Its tests, as it reported them: health check passed with the warning gone, the AGENTS/GEMINI sync test 4 of 4, the hermeticity lint clean; two review passes found nothing that had to be fixed.

- **Read:** `git diff refs/heads/main...68b106d0` · `docs/working/research-2026-11-13-small-records-review.md` (on the branch)

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] merge** | the four fixes land on main | none | a wording in the new `AGENTS.md` section misleads another agent; one revert undoes it |
| **[2] drop** | the brief closes; the four items return to the roadmap | none | the warning keeps printing every health check |
| **[3] changes needed** | your note goes back to the loop | one line | n/a |

- **Blocks:** the roadmap Now items for D12, the `Harness feedback` warning and two confine-tests records.
- **Interim:** unmerged.
- **If the answer differs:** n/a.

### Q-288 · merge-2026-11-13-cc-verify-clean-and-relative-repo-f16bbdcedaf8
**Needs:** you: judgment · **Opened:** 2026-11-13 · **Status:** OPEN

Merge the three `cc-verify` fixes (brief `docs/working/briefs/2026-11-13-cc-verify-clean-and-relative-repo.md`, branch `fix/cc-verify-clean-and-relative-repo`)?

**If you say no:** nothing merges; `cc-verify --clean` still exits 2 silently on a leftover run directory, and `cc-verify --check FILE . main` still fails to clone `.`.

`cc-verify` is the host tool that runs a check file against a fresh clone in a container (`devcontainer-config/cc-verify.sh`). The fixes, 188 lines added and 6 removed, each with a test that the loop saw fail first:
1. `--clean` cleans a run directory with no `record` file, and keeps a live run that has not written one yet, by checking whether the PID in the directory's own name is a running `cc-verify`.
2. A relative REPO is made absolute before the script changes directory; an empty REPO is refused. `--help`, `guides/cc-isolated-usage.md` and the check file's header say what REPO must be.
3. The launcher self-check (`source_lines_ok`) reads a last line with no newline; this closes the 2026-11-05 Defer row in `docs/reviews/override-log.md`.

Tip `f16bbdcedaf8086a4b90585060a397fd8aace3b8`. The gate's check, as printed:

```
ok docs/working/briefs/2026-11-13-cc-verify-clean-and-relative-repo.md f16bbdcedaf8086a4b90585060a397fd8aace3b8 b946d0ac33b3b18dd48e406a4f5fc2f16b5f6322
path docs/working/briefs/2026-11-13-cc-verify-clean-and-relative-repo.md M devcontainer-config/cc-verify.sh
path docs/working/briefs/2026-11-13-cc-verify-clean-and-relative-repo.md M docs/failure-patterns.md
path docs/working/briefs/2026-11-13-cc-verify-clean-and-relative-repo.md M docs/working/briefs/2026-11-13-cc-verify-clean-and-relative-repo.md
path docs/working/briefs/2026-11-13-cc-verify-clean-and-relative-repo.md M docs/working/q125-verify-check.sh
path docs/working/briefs/2026-11-13-cc-verify-clean-and-relative-repo.md A docs/working/research-2026-11-13-cc-verify-clean-and-relative-repo.md
path docs/working/briefs/2026-11-13-cc-verify-clean-and-relative-repo.md M guides/cc-isolated-usage.md
path docs/working/briefs/2026-11-13-cc-verify-clean-and-relative-repo.md M test/cc-verify.bats
```

`cc-verify.sh` is an enforcement file (it reaches your host at the next install), so every code commit carries `Host-tool-tested: no (host run follows the merge)`; the host check comes after the merge as one `you: terminal` paste. The loop's tests: 418 related tests, 0 failures, the hermeticity lint clean (`scripts/confine-tests.sh --probe` exited 3 here, so unconfined); two review rounds, both ambers fixed (an exported `CDPATH`, an empty REPO).

**A numbering clash to know about.** This branch adds failure patterns FP-181 and FP-182, and Q-287's branch also adds an FP-181, both written at the same time. Whichever merges second will conflict on `docs/failure-patterns.md`. If you approve both, answer this one **[3]** with "renumber to FP-182 and FP-183 after Q-287" and the loop does that one-line change, or answer [1] and the cycle files the conflict back to you as a re-dispatch.

The loop's marker also said the host paste must wait for Q-277 (whether to install the Bash sandbox with its gaps). That is out of date: Q-277 was answered [3] on 2026-11-12 and the sandbox was rolled back, so an install from main carries no sandbox. The paste will be filed after the merge, at your checkout `/home/magfrump/claude-workflows` (the path Q-280's paste used).

- **Read:** `git diff refs/heads/main...f16bbdce` · `docs/working/research-2026-11-13-cc-verify-clean-and-relative-repo.md` (on the branch; the design and a pre-mortem with five bypass families)

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] merge** | the fixes land on main and reach the host at the next install | the host paste after the merge | a `--clean` that keeps or removes the wrong directory; the tests cover both cases |
| **[2] drop** | the brief closes; the two items return to the roadmap | none | the two defects stay |
| **[3] changes needed** | your note goes back to the loop (for example, the renumbering above) | one line | n/a |

- **Blocks:** the roadmap Now items for `cc-verify --clean` and `source_lines_ok`.
- **Interim:** unmerged.
- **If the answer differs:** n/a.

### Q-281 · constraint-s4-keep-promote-drop
**Needs:** you: judgment · **Opened:** 2026-11-13 · **Status:** OPEN

Should soft constraint S4 in `docs/constraints.md` ("mechanical steps go in tested scripts, not prose") stay soft, become hard, or go?

**If you say no:** S4 stays soft and unchanged, which is the audit's recommendation. The drift check keeps noting when a loop says S4 "pruned" an option.

This is call A of four from the small constraint-drift audit, which you asked for on 2026-11-11 (Q-269 [1]). Its four calls only reached you in a cycle's final message, never this file, so you never had a way to answer them; that is fixed here. A soft constraint ranks options, and a hard one refuses them. S4 was flagged at 605d4c18 and 85080263, where the option it "pruned" lost only on ranking, and it was traded away twice (3dbf43cb, 1f14e270), so in practice it is soft.

- **Read:** `docs/working/research-2026-11-11-constraint-drift-audit.md`, "Call A" (merged b3d3e8f4)

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Keep soft, unchanged** | no edit | none | loops keep calling a soft-line loss "pruned"; the drift check keeps flagging it |
| **[2] Promote to hard** | needs a `success:` line, e.g. a bats case for every new mechanical step | one commit by you | the two units that rightly kept prose would have been refused |
| **[3] Drop** | S3 and S6 still rank most of these | one commit by you | mechanical steps written only as prose come back unranked |

- **Blocks:** nothing.
- **Interim:** [1].
- **If the answer differs:** you commit the edit to `docs/constraints.md` (no build loop may); the audit doc has the text ready to paste.

### Q-282 · constraint-s8-no-growth-clause
**Needs:** you: judgment · **Opened:** 2026-11-13 · **Status:** OPEN

Should the "no growth of the 500-plus-line files" clause of soft constraint S8 stay as it is, be reworded as a preference, or become a hard line?

**If you say no:** S8 stays unchanged, which is the audit's recommendation.

Call B of the four from the constraint-drift audit (see Q-281 for why these are only reaching you now). The clause was flagged at aeab6745 and 1f14e270, and neither time did it change the outcome. Four merges since 2026-10-19 grew those files anyway, all approved by you (one was Q-241 [1], +177/−27 to `install.sh`).

- **Read:** `docs/working/research-2026-11-11-constraint-drift-audit.md`, "Call B"

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Keep soft, unchanged** | no edit | none | loops keep reading "no growth" as a prune |
| **[2] Reword as a preference** | "prefer no growth of [...]", so it is clear it only ranks | one commit by you | none known; a softer word might let growth through more often |
| **[3] Promote to hard** | split into its own hard line with a line-count (`numstat`) check | one commit by you | the Q-106 host-settings work would have been refused |

- **Blocks:** nothing.
- **Interim:** [1].
- **If the answer differs:** you commit the edit to `docs/constraints.md`.

### Q-283 · constraint-s10-owner-wait-clause
**Needs:** you: judgment · **Opened:** 2026-11-13 · **Status:** OPEN

Should the S10 clause "no merge or loop that waits on the user's manual action when a fail-closed alternative exists" stay soft, become a new hard constraint (H5), or go?

**If you say no:** the clause stays soft and unchanged, which is the audit's recommendation.

Call C of the four from the constraint-drift audit (see Q-281). It was flagged at 546788f2, which was a false alarm: the option it pruned also failed hard constraint H4 (an LLM must not be the enforcement). Of all the soft clauses, this one is worded most like a hard rule, and it matches your standing rule against new owner stops.

- **Read:** `docs/working/research-2026-11-11-constraint-drift-audit.md`, "Call C" (option [2]'s H5 text is in its "Proposed amendment" section)

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Keep soft, unchanged** | no edit | none | a loop may again treat it as a prune; no outcome has changed yet |
| **[2] Promote to hard (H5), trim S10** | designs that wait on you are refused before choosing | one commit by you; one more line in every loop prompt | an owner step that is truly needed must argue past it; its check misses waits that go through a questions entry |
| **[3] Drop the clause** | the rest of S10 still ranks your cost | one commit by you | designs that wait on you lose their explicit counterweight |

- **Blocks:** nothing.
- **Interim:** [1].
- **If the answer differs:** you commit the edit to `docs/constraints.md`.

### Q-284 · constraint-instrument-code-in-fork
**Needs:** you: judgment · **Opened:** 2026-11-13 · **Status:** OPEN

Should the unwritten rule "benchmark and review-instrument code lives in the SWRBench fork" stay out of `docs/constraints.md`, or be added as a soft or hard line?

**If you say no:** it stays out of the file, which is the audit's recommendation; its home stays `archive/README.md:18-19`.

Call D of the four from the constraint-drift audit (see Q-281). The rule decided where 605d4c18's script went, but `docs/constraints.md` does not hold it. It matters only for benchmark or review-instrument work.

- **Read:** `docs/working/research-2026-11-11-constraint-drift-audit.md`, "Call D" (option [2]'s S12 text is in its "Proposed amendment" section)

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Leave it out of the file** | the archive README stays its home; loops find it as they did | none | a future recall-run loop might miss it and put instrument code here |
| **[2] Add it as a soft line (S12)** | every loop prompt carries it | one commit by you; one line in every prompt | a line nearly every design ignores costs context for no gain |
| **[3] Add it as a hard line** | instrument code here is refused | one commit by you, plus a path check for its `success:` line | a small helper that belongs here gets refused |

- **Blocks:** nothing.
- **Interim:** [1].
- **If the answer differs:** you commit the edit to `docs/constraints.md`.

### Q-285 · review-gap-audit-which-repo
**Needs:** you: judgment · **Opened:** 2026-11-13 · **Status:** OPEN

Which repo should the review-gap audit run on first, or should the item be dropped?

**If you say no:** the item stays parked on the roadmap and nothing runs.

Your 2026-10-29 feedback (`docs/human-author/feedback-10-29-26.txt`, point 3) asked for an audit of a repo that committed code-review rubrics with open amber or red rows: for each, find the merge that carried it, whether a fix round followed, and which gate or rule should have stopped it. You were asked in session that day which repo to run it on, but the question never reached this file, so the roadmap has shown it as waiting on you for two weeks with no way to answer.

- **Read:** the roadmap Now item "Owner feedback 2026-10-29", point 3

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Name a repo** | answer `Q-285: [1] <repo>`; a read-only audit procedure is briefed and tried there (in this repo, or written up for that repo's own session if it lives elsewhere) | one line | the first repo may have too few rubrics to show a pattern; a second can follow |
| **[2] This repo** | run it on claude-workflows' own `docs/reviews/` | one line | this repo's rubrics may not be the ones you were worried about |
| **[3] Drop it** | the point closes as not needed now | one line | a review gap you suspected stays unexamined |

- **Blocks:** the roadmap item's point 3.
- **Interim:** nothing runs.
- **If the answer differs:** n/a; each option sets what runs.

### Q-286 · trial-set-2-ends
**Needs:** you: judgment · **Opened:** 2026-11-13 · **Status:** OPEN

The second trial set (T8–T12) ends about today. Which of them should stay?

**If you say no:** all five keep running as they are, and the cycle asks again at the next weekly digest.

The trials are in `docs/working/trials/2026-11-06-attention-and-trust.md`. In short: T8, final messages open with what needs you; T9, final messages end with at most two links worth opening; T10, while a release is pending, one line on the change most worth your look; T11, one deliberate read a week in the weekly digest; T12, the weekly digest lists what the gates and reviews actually stopped. No feedback on any of them is recorded yet. To be honest about how they ran, the cycle has not kept to them every iteration: today's first final message (iteration 1925) left out T8's split, T9's links and the trials line, and the weekly digest was first written without T12's section (added in this iteration).

- **Read:** the trial doc above · `docs/working/weekly/2026-11-13.md`

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Keep all five** | the cycle writes them into the skill, as T1–T7 were (one merge-gate entry later) | one line now; one merge entry later | a practice that does not help keeps costing lines in every message |
| **[2] Keep some** | answer `Q-286: [2] T8 T11` (the ones to keep); the rest stop now | one line | a dropped one might have helped with more time |
| **[3] Drop all** | final messages and the digest go back to the T1–T7 shape | one line | none known; nothing was relying on them |

- **Blocks:** nothing.
- **Interim:** all five keep running.
- **If the answer differs:** dropped trials stop at the next iteration; kept ones go into one skill change.

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

