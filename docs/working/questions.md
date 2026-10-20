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
| [Q-172](#q-172--exit-scan-parity-boundary) | you: judgment | How much host-git parity should the exit scan chase? It grew from 761 to 1,364 lines in 18 days. Every revi... | 2026-10-15 |
| [Q-174](#q-174--q106-iteration-4-gate) | you: judgment | Q-106 [2] is built (`feat/q106-host-settings-merge`, c6d7544f, built on an earlier `merge/ready-2026-10-15`... | 2026-10-15 |
| [Q-175](#q-175--q106-merge-program-gate-coverage) | you: judgment | Q-106 moved the settings merge jq into `hooks/lib/wiring-merge.jq`, which is outside `live-verify-gate.sh`'... | 2026-10-15 |
| [Q-194](#q-194--decision-031-t4-fix-drift-miss) | you: judgment | Decision 031's fourth revisit trigger fired in letter: on `fix/doc-drift-cycle1` (merged in f265d7f2) the f... | 2026-10-17 |
| [Q-213](#q-213--log-row-73-shared-uid-git-config) | you: judgment | Log row 73's second revisit trigger holds in this repo: build loops and other sessions run as the same uid ... | 2026-10-20 |
| [Q-215](#q-215--retire-egress-dnsmasq-ipset-branch) | you: judgment | Decision 039 (merged) fixes the same bug as the unmerged `fix/egress-dnsmasq-ipset` (decision 038, Q-117, t... | 2026-10-20 |
| [Q-084](#q-084--q076-live-checks) | you: terminal | Q-076 (`cc-push`, the exit scan) was verified only with bats: stubbed docker and local-path remotes, on git... | 2026-09-27 |
| [Q-167](#q-167--post-install-host-probes) | you: terminal | The install is done: the image was built from main at fbe67674 on 2026-10-16 (Q-156), and it carries all th... | 2026-10-15 |
| [Q-169](#q-169--q117-spike-paste) | you: terminal | Run only if Q-165 is answered [1], [2] or [3], after Q-162's paste has landed the doc on main. (Both are me... | 2026-10-15 |
| [Q-196](#q-196--host-check-cc-isolated-profile-names) | you: terminal | After Q-195's branch is merged and installed, check `cc-isolated --register`'s new profile-name check on th... | 2026-10-17 |
| [Q-214](#q-214--egress-pin-resolver-release) | you: terminal | Release decision 039 (the resolver pin that fixes herald's `dl.google.com` outages) and `android`'s new `pl... | 2026-10-20 |
| [Q-079](#q-079--canon-instance-proposal-filter) | agent | Design, per Q-072, (a) a script that turns a commit or commit range into a canon instance, and (b) the high... | 2026-09-27 |
| [Q-092](#q-092--drop-hook-deny-reader) | agent | Per Q-082's answer (`permissions.deny` beats a hook `allow`), remove the Bash deny reader from `hooks/auto-... | 2026-09-28 |
| [Q-096](#q-096--exit-scan-insteadof-target) | agent | The exit scan records a `url.<base>.insteadOf` / `pushInsteadOf` base but never the URL it rewrites to, inc... | 2026-09-28 |
| [Q-097](#q-097--exit-scan-older-routes) | agent | The Q-094 review documented two older Medium routes the exit scan does not see, both now under the guide's ... | 2026-09-28 |
| [Q-108](#q-108--decision-037-stale-lines) | agent | Decision 037 has two stale lines. Line 58 says "035's still-pending regex", but the regex landed in addae61... | 2026-10-02 |
| [Q-110](#q-110--health-check-not-run-undercount) | agent | In one `scripts/health-check.sh` run (2026-10-02, main at 188e0a7d), the test runner printed `NOT RUN: 50 r... | 2026-10-02 |
| [Q-125](#q-125--build-cc-isolated-sandbox) | agent | Implement Q-124 [1] as an RPI unit. Add a seccomp profile file: Docker's default with `unshare` and `clone`... | 2026-10-07 |
| [Q-147](#q-147--q089-loop-split-source-guard) | agent | Q-089 unit A's review-fix loop ran a 4th iteration before recording a cap decision. It is now recorded as `... | 2026-10-14 |
| [Q-160](#q-160--implement-q104-per-iteration-cap) | agent | Log row 62's trigger fired again: units grew during review from 102 to 842 code lines (581d41d8), 157 to 60... | 2026-10-14 |
| [Q-168](#q-168--q096b-remote-names-unit) | agent | Q-096's iteration 2 found that the exit scan parses remote names and legacy `remotes/`/`branches/` files mo... | 2026-10-15 |
| [Q-067](#q-067--regenerate-skill-eval-reports) | deferred | When should the skill eval reports be regenerated, so that the 50 `@needs-reports` suites constrain the cur... | 2026-09-26 |
| [Q-098](#q-098--global-allowlist-after-sandbox) | deferred | Ship a global `permissions.allow` in `hooks/wiring.json` once cc-isolated has a Bash sandbox (Q-088). Branc... | 2026-09-28 |
| [Q-173](#q-173--exit-scan-split-groups) | deferred | Q-168's final pass split off four groups, each shown end to end (exit scan returns 0, then a host git comma... | 2026-10-15 |
| [Q-074](#q-074--failure-pattern-writer-trigger) | trigger | After the Q-018 backfill (164 entries), `docs/thoughts/failure-patterns.md` has gained 1 entry across about... | 2026-09-26 |
| [Q-161](#q-161--revive-hermeticity-layer2-after-q125) | trigger | When Q-125's sandbox merges (bwrap in the cc-isolated image), decision 017's T2 fires: revive hermeticity l... | 2026-10-14 |
<!-- index:end -->

## Open

### Q-213 · log-row-73-shared-uid-git-config
**Needs:** you: judgment · **Opened:** 2026-10-20 · **Status:** OPEN

Log row 73's second revisit trigger holds in this repo: build loops and other sessions run as the same uid as the operator, and `/workspace/.git/config` is writable to them, so the constraints-builder skill's "the operator's own git config" premise does not hold where build loops run. How should the trigger be answered?

- **Why it's yours:** it reopens row 73's choice to ship v1 for sole-author repos and harden later.
- **Read:** `docs/decisions/log.md` row 73 · `docs/working/constraints-builder-hardening.md` (Revisit trigger, lines 5-8) · `skills/constraints-builder/SKILL.md` ("Scope (v1)")
- **Evidence:** `test -w /workspace/.git/config` prints writable for uid node (cycle 2026-10-20, step 2); no bwrap or sandbox denyWrite covers it. Nothing hostile is there now: `git config --list --show-scope` shows plain local keys, no `refs/replace`, an unused `config.worktree`.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Read it as the same-uid residual** | Treat this as Q-103's accepted same-uid residual; reword the trigger to "an agent outside the operator's own sessions and loops" | One read of the reworded trigger | A loop that plants git config in a repo the skill reads can run a command during a constraints-builder run |
| **[2] Harden first** | Build the hardening doc's config allowlist and hardened git flags before the skill runs again in a repo with build loops | Review of one more unit | A unit spent on a risk no loop has acted on |
| **[3] Run it only with no loop live** | Add a precondition to the skill: no build loop holds a lock in the target repo | One read of the precondition | A loop started mid-run, or a config planted earlier, still gets through |

- **Blocks:** nothing; `docs/constraints.md` is already ratified (2620b419) and no constraints-builder run is pending here.
- **Interim:** no constraints-builder run in a repo with live build loops until this is answered.
- **If the answer differs:** only the trigger text, or one hardening unit, changes.

### Q-196 · host-check-cc-isolated-profile-names
**Needs:** you: terminal · **Opened:** 2026-10-17 · **Status:** OPEN

After Q-195's branch is merged and installed, check `cc-isolated --register`'s new profile-name check on the host, on a scratch repo. The first command should exit 1 with "unknown egress profile" and write nothing; the second should exit 0 and print the `base -> base,python` transition.

```
mkdir -p ~/scratch-q196 && cd ~/scratch-q196 && git init -q
cc-isolated --register ~/scratch-q196 --profile ../egress/python; echo "exit=$?"
cc-isolated --register ~/scratch-q196 --profile python; echo "exit=$?"
```

- **Interim:** the change is tested hermetically only (`test/cc-isolated-functions.bats`, 207/207); its commit carries `Live-verified: no`.
- **Blocks:** nothing; the result goes back here as a reply.

### Q-194 · decision-031-t4-fix-drift-miss
**Needs:** you: judgment · **Opened:** 2026-10-17 · **Status:** OPEN

Decision 031's fourth revisit trigger fired in letter: on `fix/doc-drift-cycle1` (merged in f265d7f2) the fix-drift lite check on 9e0ff1a5..258f9ec4 printed "FINDINGS: NONE", and the next full pass found D1 (a fact-check "Mostly accurate" doc amber) in text 258f9ec4 itself added to `guides/devcontainer-setup.md`. How should the trigger respond?

- **Why it's yours:** the trigger reopens 031's cost/recall tradeoff for the review loop.
- **Read:** `docs/decisions/031-review-loop-tier-and-factcheck-policy.md` (Revisit triggers) · `docs/reviews/code-review-rubric-2026-10-15-fix-doc-drift-cycle1.md` row D1 · `git show 258f9ec4`

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Scope the trigger** (recommended) | Amend 031 T4 to fire only on a missed behavioral or security defect; record this miss (a doc-only amber the full pass caught) as non-firing | One read of the amendment | A real prose-accuracy gap in fix-introduced text stays unwatched |
| **[2] Widen the drift check** | The fix-drift lite check also fact-checks prose that fixes add | None now; a little more per-iteration cost | More lite-check findings on docs-heavy loops |
| **[3] Drop the lite gate** | Every fix iteration gets a full pass | None now | Review loops cost noticeably more for little recall |

- **Blocks:** nothing.
- **Interim:** no change to 031; the full pass caught D1 before merge, so nothing shipped wrong.
- **If the answer differs:** only 031's trigger text or the review-fix loop's drift step changes.

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

### Q-169 · q117-spike-paste
**Needs:** you: terminal · **Opened:** 2026-10-15 · **Status:** OPEN

Run only if Q-165 is answered [1], [2] or [3], after Q-162's paste has landed the doc on main. (Both are met as of 2026-10-16: Q-165 was answered [1] in `docs/human-author/answers-10-16-26.txt`, the doc is on main through f265d7f2, and the hash below re-checked.) It live-verifies `fix/egress-dnsmasq-ipset` (Q-117) without installing it. It stages main merged with the branch, runs main's installed `cc-isolated` on a scratch clone under `~/cc-verify/run-<RUN>.d/`, runs Q-117's container block, and tears everything down.

- **The paste:** the single ```bash block in `docs/working/spike-cc-verify-q117.md` (498 lines with its fences). Take it from the reviewed commit, not the working tree, and check its hash before running:

```
mkdir -p ~/cc-verify && git -C ~/claude-workflows -c core.useReplaceRefs=false show d25254dae30fe05fd385b3ff430104fb63c39158:docs/working/spike-cc-verify-q117.md | awk '/^```bash$/{f=1;next} f&&/^```$/{exit} f' > ~/cc-verify/q117-spike.txt && sha256sum ~/cc-verify/q117-spike.txt
```

Run it on the host, not in a container, and replace `~/claude-workflows` if your checkout lives elsewhere. It uses `git -C` rather than `cd`, so a zsh prompt does not run `git status` in the checkout (an agent-planted `core.fsmonitor` would run on the host). The hash must be `032cc9a81e4e1c9266ec3ad3b5fe7053d9876eb21f5ffa7f0a35f2ccfed4afb7`; otherwise stop. Then paste the contents of `~/cc-verify/q117-spike.txt` (under the `denyWrite` below), editing only its last line, the checkout path. Its first output line must be `script sha256 a65f4c30ba1b8907`; any other value means it is not the reviewed block, so press Ctrl-C.
- **Before you run it:** add `~/cc-verify` to your agents' sandbox `denyWrite`, or run it while no agent that can write `~/cc-verify` is running. A same-uid writer there is the one threat left open (residuals A17 and A18: it could redirect the stage extraction's writes, or edit the stage into host code execution during the build).
- **Expect:** up to about an hour (image build, then Q-117's wait of up to 45 min for a pool rotation). Exit 0 with `RESULT Q-117 pass` and five `CHECK … ok` lines is a pass; 2 means no rotation was seen, so rerun later; 1 is a failure or refusal, named by step. On an interrupted teardown, rerun the same block with `--clean` as its last argument.
- **Paste back:** the `script sha256` line, the `RESULT`, `CHECK`, `NOTE`, `TEARDOWN` and `REFUSED:` lines.
- **Read:** the doc's step table (every command cited to file:line), "Not verified" (12 items only this run can show) and "Residual risks"; rubric `docs/reviews/code-review-rubric-2026-10-15-cc-verify-spike.md` (CONDITIONAL PASS: 2 iterations, 3 narrow passes, matrix 27/27 in a stub harness).
- **Interim:** Q-117 stays unverified; the egress fix stays unmerged.
- **If the answer differs:** if Q-165 is [4], this entry is dropped.

### Q-172 · exit-scan-parity-boundary
**Needs:** you: judgment · **Opened:** 2026-10-15 · **Status:** OPEN

How much host-git parity should the exit scan chase? It grew from 761 to 1,364 lines in 18 days. Every review pass of Q-094, Q-096 and Q-168 found new looser-than-git families, mostly bugs that predate the pass, each confirmed end to end with a planted hook running.

- **Why it's yours:** it sets the scan's threat-model boundary and how much review attention the scan keeps consuming.
- **Read:** Q-168's rubric (tech-debt T4) · the guide's "Known routes it does not see" · cc-push, the route that runs no git in the checkout

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Keep closing families one unit at a time** | Q-173's groups each become a unit, and so does whatever their reviews find | Review attention per unit, open-ended | Growth with no end; each pass finds more |
| **[2] Set a boundary** | Close only routes that need no state planted before launch; list the rest as known routes; the guide says to push with cc-push | One decision now | Routes that need launch-time state stay open by design |
| **[3] Re-architect** | One "resolve like git" layer plus one reader for `gitdir:`/commondir files, then re-audit | One larger unit | The tech-debt critic doubts a rewrite stops new families |

- **Blocks:** Q-173.
- **Interim:** no new exit-scan family units start; Q-096 lands as reviewed.
- **If the answer differs:** only what Q-173 becomes changes.

### Q-173 · exit-scan-split-groups
**Needs:** deferred · **Opened:** 2026-10-15 · **Status:** OPEN

Q-168's final pass split off four groups, each shown end to end (exit scan returns 0, then a host git command runs a planted hook): (1) the relative-path base per working tree: R3 (a `--separate-git-dir` repo), **R6 (High: a relative `core.hooksPath` in a linked worktree inside the checkout is never walked)**, A14, A16; (2) `@[` in local paths (R4); (3) `gitdir:` include parity (R5, A15, T3); (4) one reader for `gitdir:`/commondir files (T1; a container-form `.git` ending in CR). Waits on Q-172; R6 is the first to build under any option, unless [2] puts it outside the boundary.

- **Read:** Q-168's rubric, the R3–R6 and A14–A17 rows
- **Interim:** documented as known routes once Q-171's iteration lands; cc-push stays the safe path.

### Q-174 · q106-iteration-4-gate
**Needs:** you: judgment · **Opened:** 2026-10-15 · **Status:** OPEN

Q-106 [2] is built (`feat/q106-host-settings-merge`, c6d7544f, built on an earlier `merge/ready-2026-10-15` commit, 184396ea; it is not in the ready branch Q-162 merges). install.sh's host target now runs the container's provenance merge on your `~/.claude/settings.json`, inside its review and gated by your y. Its review loop stopped at the iteration-4 gate with one Medium open. Authorize a 4th iteration?

- **Why it's yours:** the iteration-4 gate, and the change writes your host hardening.
- **Read:** rubric `docs/reviews/code-review-rubric-2026-10-15-feat-q106-host-settings-merge.md` and plan `docs/working/plan-q106-host-settings-merge.md` (pre-mortem) on the branch.
  - **One merge program:** `hooks/lib/wiring-merge.jq`, shared with `link-claude-home.sh` and run with an empty HOME and environment.
  - **Review before your y:** a `settings.json:` diff plus a by-name UNWIRE/ADD/REMOVE list.
  - **Refuses:** a symlinked, unreadable or non-object file, a missing jq, any `wiring.json` hook that is not `bash|python3 {{CLAUDE_DIR}}/hooks/<path>`, or a file that changed since the review.
  - **Recovery:** a backup is taken before the rename, with the mode kept.
  - **Also closes Q-108:** 037's stale lines are corrected, and the "035's regex lands" trigger is discharged.
  - **Size:** 561 code lines (under 800).
  - **Tests:** T93–T103 11/11, link-claude-home 16/16. The health check's only reds are the Q-145 race, each passing alone; slow suites pass.
  - **S3-F1 (open, Medium, low confidence):** the wiring shape check covers each hook but not the group around it. An object-valued `hooks`, an object `matcher` or extra group keys would pass and be written.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Authorize iteration 4** (recommended) | Tighten the group shape (only `matcher`/`hooks`, typed), anchor the regexes with `\A…\z`, count duplicate hooks: about 20 lines, then the k=3 confirming pass, then into Q-162's branch | One later merge | Agent time spent on a check that may not matter |
| **[2] Merge as is** | Land c6d7544f with S3-F1–F3 listed in the merge message | One merge now | A hostile branch's malformed group lands in settings.json after your y; if Claude Code rejects a schema-invalid file, deny rules stop applying until it is fixed |
| **[3] Host check first** | A small paste: does Claude Code reject the whole file or skip one malformed group? The answer picks [1] or [2] | One paste | Only delay |

- **After it merges:** the branch's host verification block (in the rubric's report; it installs into a temp dir with a copy of your settings.json, never the real one) joins Q-167.
- **Interim:** unmerged; the installer keeps printing the manual-merge reminder.
- **If the answer differs:** [2] merges as is; [3] adds one terminal entry.

### Q-175 · q106-merge-program-gate-coverage
**Needs:** you: judgment · **Opened:** 2026-10-15 · **Status:** OPEN

Q-106 moved the settings merge jq into `hooks/lib/wiring-merge.jq`, which is outside `live-verify-gate.sh`'s `enforcement` regex. On main that jq is inline in `link-claude-home.sh`, which the regex covers (`hooks/live-verify-gate.sh:83`), so the move takes away coverage the program has today. The trust manifest still hashes it, and both installs show it in their reviews. Should the commit gate cover it?

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Accept it in the `hooks/**` class** | Same status as `wiring.json` and `guard-trusted-writes.py` | Nothing | A change to the merge program commits without a `Live-verified:` trailer, which it cannot today |
| **[2] Add it to the enforcement regex** | A small gate-code change with its test | One gate-code review | Every commit touching the program owes a container probe |
| **[3] Its own trailer** | Like `Host-tool-tested:` | A new category to maintain | More trailers to remember |

- **Interim:** [1] in name only: Q-106 is unmerged (Q-174), so nothing has lost coverage yet. The security review of this entry (`docs/reviews/security-review-2026-10-15-0357.md` F6) leans to [2].
- **If the answer differs:** [2] or [3] becomes a small unit after Q-106 lands.

### Q-160 · implement-q104-per-iteration-cap
**Needs:** agent · **Opened:** 2026-10-14 · **Status:** OPEN

Log row 62's trigger fired again: units grew during review from 102 to 842 code lines (581d41d8), 157 to 603 (73589cd7), 217 to 538 (dfa75374) and 392 to 570 (626dc300). Write Q-104 [2] into the process. pr-prep or the review-fix loop re-measures the unit with step 1a's command after each iteration, tolerates up to ~800 lines, and stops for a waiver past that. Amend log row 62 to point at it.

- **Read:** Q-104 in `docs/working/questions-archive.md` · `workflows/pr-prep.md` step 1a · `workflows/review-fix-loop.md` (early split trigger) · `docs/working/merge-msg-build-loop-u2a3b.md` (cites "Q-104 [2]'s ~800")
- **Interim:** applied by hand per loop (waivers Q-113, Q-120, Q-131). Nothing enforces it, so it holds only while each loop remembers.
- **Built 2026-10-15:** `fix/q160-iteration-cap` (4a44d2f3), merged by Q-162's paste. This entry closes when it lands.
- **Landed (dev cycle 2026-10-17):** 4a44d2f3 is on main through f265d7f2; `workflows/review-fix-loop.md` has the size re-check and log row 62 carries the 2026-10-15 amendment. Its closure condition is met; ready to archive.

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

### Q-110 · health-check-not-run-undercount
**Needs:** agent · **Opened:** 2026-10-02 · **Status:** OPEN

In one `scripts/health-check.sh` run (2026-10-02, main at 188e0a7d), the test runner printed `NOT RUN: 50 report-dependent suite(s)`, but the health check's own summary said `4 report-dependent BATS suite(s) NOT RUN`. Find out why the summary under-counts and fix it, with a test.

- **Read:** `scripts/health-check.sh` (check 5's NOT RUN summary) · `scripts/run-tests.sh` ("Report gating") · the review of `chore/dev-cycle-2026-10-02` (`docs/reviews/code-fact-check-report-devcycle-cycle-2026-10-02.md`)
- **Cause (reproduced in this branch's pass-2 review):** `test/skills/eval-helpers-gating.bats` runs nested `run-tests.sh --fast` calls (lines 76–91; the pass-2 review reproduced it with the line-76 test) that do not override `RUN_TESTS_NOT_RUN_FILE`. The nested run inherits the parent's file and overwrites the parent's count (50, written before any suite runs, `scripts/run-tests.sh:356-357`) with its own 4. Fix: unset the variable in that suite's `setup()` (not at top level of `test/lib/hermetic-env.bash`: `run-tests.sh` sources that file before its own write, so the count would vanish), or have the runner stop passing the variable to the bats processes it starts; add a test that the parent's file is untouched. Having the runner refuse an inherited value cannot work: the health check passes the variable through the environment (`scripts/health-check.sh`, check 5).
- **Interim:** trust the runner's own NOT RUN list, not the summary line.
- **Landed (dev cycle 2026-10-17):** 70aa3a78 is on main through f265d7f2 (`scripts/run-tests.sh` unsets the variable; test in `test/skills/eval-helpers-gating.bats`). The 2026-10-17 health check's summary and runner both say 50 NOT RUN. Ready to archive.

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
- **Built 2026-10-15:** `fix/q096-exit-scan-insteadof-target` (8717fd72, loop closed), merged by Q-162's paste; this entry closes when it lands. Host probe: Q-167. Split-off: Q-168. Review history: The first security pass found five Mediums, all confirmed by probe. One is pre-existing: a remote with no `url` is pushed to as a path, and the scan skips it. The commit carries `Host-tool-tested: no` (decision log row 71), not `Live-verified`.
- **Landed (dev cycle 2026-10-17):** 8717fd72 is on main through f265d7f2, and its brief reads done. Its closure condition is met; the host probe stays with Q-167, the split-off with Q-168. Ready to archive.

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

### Q-147 · q089-loop-split-source-guard
**Needs:** agent · **Opened:** 2026-10-14 · **Status:** OPEN

Q-089 unit A's review-fix loop ran a 4th iteration before recording a cap decision. It is now recorded as `split`: the static source-set test (rubric A6/R2/R4) moves to its own unit, `feat/q089-source-guard` (at fa059477). The rest of unit A starts a new loop. That source-guard unit needs a fresh loop that first narrows the test's claim to "plain spellings, accidental drift". Pass 4 showed grep can't cover every bash form.

- **Read:** `docs/reviews/code-review-rubric-2026-10-14-feat-q089-host-tool-trust.md` "Iteration-4 gate"
- **Interim:** unit A ships without the static guard. The runtime checks don't depend on it, and the guard is hardening against a future refactor.

### Q-214 · egress-pin-resolver-release
**Needs:** you: terminal · **Opened:** 2026-10-20 · **Status:** OPEN

Release decision 039 (the resolver pin that fixes herald's `dl.google.com` outages) and `android`'s new `plugins-artifacts.gradle.org`, and probe that name for domain fronting first. Paste the block on the host. Answer `Q-214: <output>`.

- **Read:** `docs/decisions/039-pin-resolver-to-phase-a.md` · `docs/working/dd-egress-pin-resolver.md` · log row 76

```bash
# 1. Fronting probe for the new android name (the Q-045 probe). Expect 403 or 404 "fronted"; a 200 <title>Google/GitHub means it fronts.
b=$(mktemp); probe() { r=$(curl -sS -m 10 -o "$b" -w '%{http_code}' "$@" 2>&1); t=$(grep -o -i -m1 '<title>[^<]*' "$b" | head -c 50); echo "$r $t"; }
for tgt in www.google.com www.python.org www.cloudflare.com github.com; do printf '%-16s fronted=[%s]\n' "$tgt" "$(probe -H "Host: $tgt" https://plugins-artifacts.gradle.org/)"; done; rm -f "$b"
# 2. Install main's config (read the diff, answer y), then re-bless and probe herald.
git -C ~/claude-workflows log -1 --oneline main    # expect 9fa8bbd0 or later
(cd ~/claude-workflows && ./devcontainer-config/install.sh)
HERALD=~/code/belegarth-herald                       # EDIT if herald lives elsewhere
cc-isolated --register "$HERALD" --profile android && cc-isolated --probe-only "$HERALD"
```

- **After it passes:** in herald's next session, the agent runs the handoff's `probe.sh OUTDIR 1800 20` and `grep -c host-record /etc/dnsmasq.d/cc-allowlist.conf`. Pass is 0 `FAIL sni=dl.google.com` lines. Then it runs a cold `./gradlew :app:assembleDebug` and retires its "dl.google.com refused TLS" memory.
- **If the probe shows fronting:** the entry gets an ACCEPTED RISK note like Google's (Q-052), or it is removed. The choice is yours; a follow-up entry will ask.
- **Interim:** merged on main (9fa8bbd0) with `Live-verified: no`. Nothing changes until `install.sh` runs. Herald's workaround stays `sudo /usr/local/bin/init-firewall.sh`.
- **If it fails:** paste the output. Revert with `git revert -m1 9fa8bbd0`, then reinstall.

### Q-215 · retire-egress-dnsmasq-ipset-branch
**Needs:** you: judgment · **Opened:** 2026-10-20 · **Status:** OPEN

Decision 039 (merged) fixes the same bug as the unmerged `fix/egress-dnsmasq-ipset` (decision 038, Q-117, the Q-169 spike's target), with no CAP_NET_ADMIN resolver and ~5% of the code. What happens to the old branch?

- **Read:** decision 039's "Why not the alternatives" and Revisit trigger

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Keep it parked** | The branch stays, unmerged, as 039's fallback for `.zone` rotation | None | Clutter. Q-169's spike still names it as its target |
| **[2] Delete it** | `git -C /workspace worktree remove .claude/wt-egress-dnsmasq-ipset && git -C /workspace branch -D fix/egress-dnsmasq-ipset` | One paste | 038's design survives only in git reflog. The decision text is quoted in `docs/working/dd-egress-pin-resolver.md` |

- **Interim:** [1]. Nothing deleted.
- **If the answer differs:** none; deletion is the only action.
