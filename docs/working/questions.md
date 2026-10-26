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
| [Q-217](#q-217--merge-2026-10-20-cc-verify-host-tool-e87a79122092) | you: judgment | Merge `feat/cc-verify-host-tool` at e87a79122092d919e9f6c032db90549c6977cd00 (brief `docs/working/briefs/20... | 2026-10-20 |
| [Q-218](#q-218--merge-2026-10-25-log-row-73-trigger-241278a4f811) | you: judgment | Merge `docs/log-row-73-trigger` at 241278a4f81124cca3a3a381b35b80463b249973 (brief `docs/working/briefs/202... | 2026-10-25 |
| [Q-219](#q-219--merge-2026-10-25-widen-fix-drift-check-4695470b98b1) | you: judgment | Merge `feat/widen-fix-drift-check` at 4695470b98b1d76642233f1bc1d90d5d40a20bba (brief `docs/working/briefs/... | 2026-10-25 |
| [Q-084](#q-084--q076-live-checks) | you: terminal | Q-076 (`cc-push`, the exit scan) was verified only with bats: stubbed docker and local-path remotes, on git... | 2026-09-27 |
| [Q-167](#q-167--post-install-host-probes) | you: terminal | The install is done: the image was built from main at fbe67674 on 2026-10-16 (Q-156), and it carries all th... | 2026-10-15 |
| [Q-169](#q-169--q117-spike-paste) | you: terminal | Run only if Q-165 is answered [1], [2] or [3], after Q-162's paste has landed the doc on main. (Both are me... | 2026-10-15 |
| [Q-214](#q-214--egress-pin-resolver-release) | you: terminal | Release decision 039 (the resolver pin that fixes herald's `dl.google.com` outages) and `android`'s new `pl... | 2026-10-20 |
| [Q-215](#q-215--retire-egress-dnsmasq-ipset-branch) | you: terminal | Decision 039 (merged) fixes the same bug as the unmerged `fix/egress-dnsmasq-ipset` (decision 038, Q-117, t... | 2026-10-20 |
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
| [Q-173](#q-173--exit-scan-split-groups) | agent | Q-168's final pass split off four groups, each shown end to end (exit scan returns 0, then a host git comma... | 2026-10-15 |
| [Q-067](#q-067--regenerate-skill-eval-reports) | deferred | When should the skill eval reports be regenerated, so that the 50 `@needs-reports` suites constrain the cur... | 2026-09-26 |
| [Q-098](#q-098--global-allowlist-after-sandbox) | deferred | Ship a global `permissions.allow` in `hooks/wiring.json` once cc-isolated has a Bash sandbox (Q-088). Branc... | 2026-09-28 |
| [Q-074](#q-074--failure-pattern-writer-trigger) | trigger | After the Q-018 backfill (164 entries), `docs/thoughts/failure-patterns.md` has gained 1 entry across about... | 2026-09-26 |
| [Q-161](#q-161--revive-hermeticity-layer2-after-q125) | trigger | When Q-125's sandbox merges (bwrap in the cc-isolated image), decision 017's T2 fires: revive hermeticity l... | 2026-10-14 |
<!-- index:end -->

## Open

### Q-219 · merge-2026-10-25-widen-fix-drift-check-4695470b98b1
**Needs:** you: judgment · **Opened:** 2026-10-25 · **Status:** OPEN

Merge `feat/widen-fix-drift-check` at 4695470b98b1d76642233f1bc1d90d5d40a20bba (brief `docs/working/briefs/2026-10-25-widen-fix-drift-check.md`, roadmap In flight)?

- **What it does** (from the loop's report): the fix-drift lite check's prompt (`PROMPT_FIX_DRIFT` in `scripts/lite-review.py`) now also reports factual errors in prose a fix adds or changes, and a specific claim about something the diff does not show (another file's contents or order, a line number, what a list includes) comes back as a Low "unverified claim" finding that names what to check; the loop agent then checks it. Still one lite call, no new agent run. `workflows/review-fix-loop.md` (Fix-commit drift check) and `workflows/pr-prep.md` step 3c describe the wider scope, the unverified-claim handling and the cost. Decision 031 gets a dated 2026-10-25 amendment and a note under its fourth trigger (original text unchanged); log row 77 records it, following row 63's precedent. New `test/lite-review-fix-drift-prompt.bats` runs the script end to end against a temp repo with a strict `claude` stub (exact argv, refuses `--bare`); its first case fails on the old prompt.
- **A deviation the loop flags:** the brief said "the doc change is the change itself", but the check's behaviour lives only in the script's prompt, so a workflow-only edit would describe a check that does not run (H2). It edited the script (7 lines) and added the test. The drift check itself was not run live on the fix commits (needs a live `claude` call); independent subagent reviews stood in (first pass 0 red, 3 amber, fixed in 821d26d4; confirming pass clean). Health check, hermeticity lint and the touched suites pass.
- **Read:** `git diff d40e4bae8ad014c30be81e0891ffac2e6ef35771 4695470b98b1d76642233f1bc1d90d5d40a20bba` · `docs/working/research-2026-10-25-widen-fix-drift-check.md` on that branch (five options; it picked C)
- **Gate output** (`build-loop.sh --check`):
  - `ok docs/working/briefs/2026-10-25-widen-fix-drift-check.md 4695470b98b1d76642233f1bc1d90d5d40a20bba b539f520fbb18c01f8c666b0557dccf5bdb8dd41`
  - `path docs/working/briefs/2026-10-25-widen-fix-drift-check.md M docs/decisions/031-review-loop-tier-and-factcheck-policy.md`
  - `path docs/working/briefs/2026-10-25-widen-fix-drift-check.md M docs/decisions/log.md`
  - `path docs/working/briefs/2026-10-25-widen-fix-drift-check.md M docs/working/briefs/2026-10-25-widen-fix-drift-check.md`
  - `path docs/working/briefs/2026-10-25-widen-fix-drift-check.md A docs/working/research-2026-10-25-widen-fix-drift-check.md`
  - `path docs/working/briefs/2026-10-25-widen-fix-drift-check.md M scripts/lite-review.py`
  - `path docs/working/briefs/2026-10-25-widen-fix-drift-check.md A test/lite-review-fix-drift-prompt.bats`
  - `path docs/working/briefs/2026-10-25-widen-fix-drift-check.md M workflows/pr-prep.md`
  - `path docs/working/briefs/2026-10-25-widen-fix-drift-check.md M workflows/review-fix-loop.md`
- **Path notes:** `scripts/lite-review.py` holds a prompt the review loop sends to a model, and the two `workflows/` files are on this repo's self-merge never line; `docs/decisions/` paths are your records. Self-merge's floor would have refused all of these. None is gate code or a dot path.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] merge** | The orchestrator runs `--merge --approved` at exactly 4695470b | Reading a 7-line prompt change, two workflow sections and 031's amendment | Noisier lite-check findings on docs-heavy loops; one revert undoes it |
| **[2] drop** | The brief closes; the branch stays for you | None | 031's fourth trigger stays answered on paper only |
| **[3] changes needed** | Your note goes back to the loop (for example: keep it docs-only) | A note | One more loop run |

- **Interim:** unmerged; the lite check runs as before.

### Q-218 · merge-2026-10-25-log-row-73-trigger-241278a4f811
**Needs:** you: judgment · **Opened:** 2026-10-25 · **Status:** OPEN

Merge `docs/log-row-73-trigger` at 241278a4f81124cca3a3a381b35b80463b249973 (brief `docs/working/briefs/2026-10-25-log-row-73-trigger.md`, roadmap In flight)?

- **What it does** (from the loop's report, docs only): `docs/working/constraints-builder-hardening.md`'s second revisit trigger now fires when "an agent outside the operator's own sessions and loops" can write a target repo's `.git/config`, `.git/config.worktree`, `refs/replace/` or their includes, and adds one sentence naming the operator's own loops and sessions as Q-103's accepted same-uid residual (Q-213 [1]). Log row 73 gets a dated "Amended 2026-10-25 (Q-213 [1])" note in its last cell; the original text stays (row about 1.1 KB). `skills/constraints-builder/SKILL.md` "Scope (v1)" was read and does not restate the old wording, so it is unchanged. The loop fact-checked the diff against Q-213 and the answers file itself (doc-only); `bats test/scripts/dev-cycle.bats` passed (79).
- **Read:** `git diff d40e4bae8ad014c30be81e0891ffac2e6ef35771 241278a4f81124cca3a3a381b35b80463b249973` · `docs/working/research-2026-10-25-log-row-73-trigger.md` on that branch
- **Gate output** (`build-loop.sh --check`):
  - `ok docs/working/briefs/2026-10-25-log-row-73-trigger.md 241278a4f81124cca3a3a381b35b80463b249973 7c57a70836aa81cf6f4b16a2bae1cb89e74b1113`
  - `path docs/working/briefs/2026-10-25-log-row-73-trigger.md M docs/decisions/log.md`
  - `path docs/working/briefs/2026-10-25-log-row-73-trigger.md M docs/working/briefs/2026-10-25-log-row-73-trigger.md`
  - `path docs/working/briefs/2026-10-25-log-row-73-trigger.md M docs/working/constraints-builder-hardening.md`
  - `path docs/working/briefs/2026-10-25-log-row-73-trigger.md A docs/working/research-2026-10-25-log-row-73-trigger.md`
- **Path notes:** `docs/decisions/log.md` is your record, which self-merge's floor would have refused; none is gate code, a dot path or an instruction or prompt file.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] merge** | The orchestrator runs `--merge --approved` at exactly 241278a4 | Reading a five-line trigger reword and one log amendment | A wording slip in a trigger; one revert undoes it |
| **[2] drop** | The brief closes; the branch stays for you | None | The trigger keeps reading as firing on the build loops |
| **[3] changes needed** | Your note goes back to the loop | A note | One more loop run |

- **Interim:** unmerged; nothing changes on main.

### Q-217 · merge-2026-10-20-cc-verify-host-tool-e87a79122092
**Needs:** you: judgment · **Opened:** 2026-10-20 · **Status:** OPEN

Merge `feat/cc-verify-host-tool` at e87a79122092d919e9f6c032db90549c6977cd00 (brief `docs/working/briefs/2026-10-20-cc-verify-host-tool.md`, roadmap In flight)?

- **What it does** (from the loop's report; nothing run on a host, the sandbox has no docker): `devcontainer-config/cc-verify.sh` (`cc-verify [--profile P] --check FILE REPO BRANCH`, `--clean`, `--help`) stages `git merge-tree --write-tree` of main and BRANCH (refusing a conflict), checks the staged `devcontainer.json` against main's installed copy (JSONC parsed with python3 stdlib; refuses new keys, changed host-reaching keys, runArgs outside NET_ADMIN/NET_RAW plus a staged seccomp file, extra mounts, new host variables, duplicate keys), shows the diffs and asks y/N, runs main's installed `cc-isolated` on a `VERIFY-<tree8>` scratch clone, runs the check file in the container, prints a `Live-verified: <hash> — cc-verify of tree <id>` trailer on a pass, and tears down from an exit trap. Exit codes 0 pass, 1 error or declined, 2 usage, 3 check failed. The pre-mortem's seven mitigations each have bats cases (`test/cc-verify.bats`, 13); it also checks itself against `host-tools.sha256` and main's launcher against `manifest.sha256`. Full health check, hermeticity-lint and shellcheck pass.
- **Decisions the loop flags:** (1) split into two stacked units over the ~400-line cap (core 6870e947, 360 lines; hardening, wiring and docs d5fa26c1, 210 lines; 620 in all): merge the tip only, as unit 1 alone lacks the JSONC refusal. (2) One line added to `cc-isolated.sh` (`host_tool_files`), which the brief's out-of-scope line excluded but its acceptance criterion needs (confidence medium). (3) python3 becomes a host requirement for cc-verify only; the preflight refuses without it. (4) Not taken from review: an exec failure exits 3, not 1 (errs toward a false fail); the trailer hash is the blessed stage hash, not `cc-isolated --list`'s. (5) Deferred: an interactive mode for Q-130's `/login`, and a multi-branch merge for Q-098.
- **After merge:** a `you: terminal` entry for the first host run, adding `~/cc-verify` to the agents' sandbox `denyWrite` first; the research doc's §6 lists 11 things that run must show (including whether the devcontainer CLI's JSONC parser treats U+2028 as a line break).
- **Read:** `git log c1a28e20..e87a79122092d919e9f6c032db90549c6977cd00` · `docs/working/research-2026-10-20-cc-verify-host-tool.md` on that branch
- **Gate output** (`build-loop.sh --check`):
  - `ok docs/working/briefs/2026-10-20-cc-verify-host-tool.md e87a79122092d919e9f6c032db90549c6977cd00 b43d4eb620e195723e0c932393ae26d4c4fcfa41`
  - `path docs/working/briefs/2026-10-20-cc-verify-host-tool.md M devcontainer-config/cc-isolated.sh`
  - `path docs/working/briefs/2026-10-20-cc-verify-host-tool.md A devcontainer-config/cc-verify.sh`
  - `path docs/working/briefs/2026-10-20-cc-verify-host-tool.md M devcontainer-config/install.sh`
  - `path docs/working/briefs/2026-10-20-cc-verify-host-tool.md M docs/working/briefs/2026-10-20-cc-verify-host-tool.md`
  - `path docs/working/briefs/2026-10-20-cc-verify-host-tool.md M docs/working/dd-branch-verify-without-install.md`
  - `path docs/working/briefs/2026-10-20-cc-verify-host-tool.md A docs/working/research-2026-10-20-cc-verify-host-tool.md`
  - `path docs/working/briefs/2026-10-20-cc-verify-host-tool.md M guides/cc-isolated-usage.md`
  - `path docs/working/briefs/2026-10-20-cc-verify-host-tool.md M hooks/live-verify-gate.sh`
  - `path docs/working/briefs/2026-10-20-cc-verify-host-tool.md M test/cc-isolated-functions.bats`
  - `path docs/working/briefs/2026-10-20-cc-verify-host-tool.md A test/cc-verify.bats`
  - `path docs/working/briefs/2026-10-20-cc-verify-host-tool.md M test/install-host.bats`
- **Path notes:** none is gate code, a dot path or an instruction or prompt file. `hooks/live-verify-gate.sh`, `devcontainer-config/cc-isolated.sh` and `devcontainer-config/install.sh` are enforcement and host-install files: the commits carry `Live-verified: no` and `Host-tool-tested: no` with reasons, and `install.sh` links the new tool, so the change reaches your host at the next install.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] merge** | The orchestrator runs `--merge --approved` at exactly e87a7912; then a host-run entry is filed | Reading a 620-line host tool and its tests | A flaw in a host tool that runs docker on your machine; it only runs when you invoke it, and one revert undoes it |
| **[2] drop** | The brief closes; the branch stays for you | None | Q-117, Q-125 and Q-098 stay parked |
| **[3] changes needed** | Your note goes back to the loop | A note | One more loop run |

- **Interim:** unmerged; nothing changes on main or the host.

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
- **2026-10-23:** Q-215 was answered [2]: `fix/egress-dnsmasq-ipset`, this paste's target, is to be deleted (decision 039 replaced it). Once it is gone this paste has nothing to verify; reply `Q-169: drop` to close it.

### Q-173 · exit-scan-split-groups
**Needs:** agent · **Opened:** 2026-10-15 · **Status:** OPEN

Q-168's final pass split off four groups, each shown end to end (exit scan returns 0, then a host git command runs a planted hook): (1) the relative-path base per working tree: R3 (a `--separate-git-dir` repo), **R6 (High: a relative `core.hooksPath` in a linked worktree inside the checkout is never walked)**, A14, A16; (2) `@[` in local paths (R4); (3) `gitdir:` include parity (R5, A15, T3); (4) one reader for `gitdir:`/commondir files (T1; a container-form `.git` ending in CR). Waits on Q-172; R6 is the first to build under any option, unless [2] puts it outside the boundary.

- **Read:** Q-168's rubric, the R3–R6 and A14–A17 rows
- **Interim:** documented as known routes once Q-171's iteration lands; cc-push stays the safe path.
- **2026-10-23:** Q-172 answered [2]: close only routes that need no state planted before launch, list the rest as known routes, and the guide says to push with cc-push. First step: sort the four groups by that rule. R6 (a relative `core.hooksPath` in a linked worktree inside the checkout) needs only state a session can write in the checkout, so it is inside the boundary and builds first.
- **Stuck (dev cycle 2026-10-25):** unblocked by Q-172 [2] but needs a build loop (sort the groups, build R6 first), not a docs edit; no choice pending.

### Q-160 · implement-q104-per-iteration-cap
**Needs:** agent · **Opened:** 2026-10-14 · **Status:** OPEN

Log row 62's trigger fired again: units grew during review from 102 to 842 code lines (581d41d8), 157 to 603 (73589cd7), 217 to 538 (dfa75374) and 392 to 570 (626dc300). Write Q-104 [2] into the process. pr-prep or the review-fix loop re-measures the unit with step 1a's command after each iteration, tolerates up to ~800 lines, and stops for a waiver past that. Amend log row 62 to point at it.

- **Read:** Q-104 in `docs/working/questions-archive.md` · `workflows/pr-prep.md` step 1a · `workflows/review-fix-loop.md` (early split trigger) · `docs/working/merge-msg-build-loop-u2a3b.md` (cites "Q-104 [2]'s ~800")
- **Interim:** applied by hand per loop (waivers Q-113, Q-120, Q-131). Nothing enforces it, so it holds only while each loop remembers.
- **Built 2026-10-15:** `fix/q160-iteration-cap` (4a44d2f3), merged by Q-162's paste. This entry closes when it lands.
- **Landed (dev cycle 2026-10-17):** 4a44d2f3 is on main through f265d7f2; `workflows/review-fix-loop.md` has the size re-check and log row 62 carries the 2026-10-15 amendment. Its closure condition is met; ready to archive.
- **Done (dev cycle 2026-10-25):** 4a44d2f3 is on main (roadmap Done, f265d7f2). Ready for you to set ANSWERED.

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

### Q-110 · health-check-not-run-undercount
**Needs:** agent · **Opened:** 2026-10-02 · **Status:** OPEN

In one `scripts/health-check.sh` run (2026-10-02, main at 188e0a7d), the test runner printed `NOT RUN: 50 report-dependent suite(s)`, but the health check's own summary said `4 report-dependent BATS suite(s) NOT RUN`. Find out why the summary under-counts and fix it, with a test.

- **Read:** `scripts/health-check.sh` (check 5's NOT RUN summary) · `scripts/run-tests.sh` ("Report gating") · the review of `chore/dev-cycle-2026-10-02` (`docs/reviews/code-fact-check-report-devcycle-cycle-2026-10-02.md`)
- **Cause (reproduced in this branch's pass-2 review):** `test/skills/eval-helpers-gating.bats` runs nested `run-tests.sh --fast` calls (lines 76–91; the pass-2 review reproduced it with the line-76 test) that do not override `RUN_TESTS_NOT_RUN_FILE`. The nested run inherits the parent's file and overwrites the parent's count (50, written before any suite runs, `scripts/run-tests.sh:356-357`) with its own 4. Fix: unset the variable in that suite's `setup()` (not at top level of `test/lib/hermetic-env.bash`: `run-tests.sh` sources that file before its own write, so the count would vanish), or have the runner stop passing the variable to the bats processes it starts; add a test that the parent's file is untouched. Having the runner refuse an inherited value cannot work: the health check passes the variable through the environment (`scripts/health-check.sh`, check 5).
- **Interim:** trust the runner's own NOT RUN list, not the summary line.
- **Landed (dev cycle 2026-10-17):** 70aa3a78 is on main through f265d7f2 (`scripts/run-tests.sh` unsets the variable; test in `test/skills/eval-helpers-gating.bats`). The 2026-10-17 health check's summary and runner both say 50 NOT RUN. Ready to archive.
- **Done (dev cycle 2026-10-25):** 70aa3a78 is on main (roadmap Done, f265d7f2). Ready for you to set ANSWERED.

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

### Q-096 · exit-scan-insteadof-target
**Needs:** agent · **Opened:** 2026-09-28 · **Status:** OPEN

The exit scan records a `url.<base>.insteadOf` / `pushInsteadOf` base but never the URL it rewrites to, including at the top level, so a session can repoint a remote through a rewrite the scan does not follow. Found in the Q-094 review and now listed in the guide's "Known routes it does not see". Close it: the rewritten local-path target is walked as a remote, as `_snap_remote` does for `remote.*.url`.

- **Read:** Q-094 rubric `docs/reviews/code-review-rubric-2026-09-28-q094-exit-scan-worktree-layout.md` · `_snap_config` / `_snap_remote` in `devcontainer-config/cc-exit-scan.sh`
- **Constraint:** enforcement file: pre-mortem with bypass families first (decision log 61), under the 400-line cap. Start after Q-094's branches merge (same file).
- **Interim:** documented as a known route. cc-push, which runs no git in the checkout, is still the way to push.
- **Unblocked 2026-10-02 (dev cycle):** Q-094's branches merged (7bf3b581), so the "start after" condition is met. Briefed as `docs/working/briefs/2026-10-02-exit-scan-insteadof-target.md`.
- **Built 2026-10-15:** `fix/q096-exit-scan-insteadof-target` (8717fd72, loop closed), merged by Q-162's paste; this entry closes when it lands. Host probe: Q-167. Split-off: Q-168. Review history: The first security pass found five Mediums, all confirmed by probe. One is pre-existing: a remote with no `url` is pushed to as a path, and the scan skips it. The commit carries `Host-tool-tested: no` (decision log row 71), not `Live-verified`.
- **Landed (dev cycle 2026-10-17):** 8717fd72 is on main through f265d7f2, and its brief reads done. Its closure condition is met; the host probe stays with Q-167, the split-off with Q-168. Ready to archive.
- **Done (dev cycle 2026-10-25):** 8717fd72 is on main; the host probe stays with Q-167 and the split-off with Q-168. Ready for you to set ANSWERED.

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

### Q-092 · drop-hook-deny-reader
**Needs:** agent · **Opened:** 2026-09-28 · **Status:** OPEN

Per Q-082's answer (`permissions.deny` beats a hook `allow`), remove the Bash deny reader from `hooks/auto-approve-allowed-commands.sh`: the settings-file deny loading, `--deny`, the de-quoted matching and their tests. Update the hook header's rule table to match. This is architecture-review finding 1 on Q-076.

- **Read:** Q-082 in the archive · decision log 53 (amended 2026-09-28) · the hook header
- **Constraint:** this changes an enforcement file, so the plan's pre-mortem lists the bypass families and marks each covered or not before implementing. One case to check explicitly: the host result covers `allow` only. If the hook can ever emit `ask` (#39344 shows `ask` overriding deny), the reader may still be needed on that path.
- **Interim:** the reader stays. It is redundant for `allow`, not harmful.
- **Landed (dev cycle 2026-10-20):** U1 merged at 79c8a6a6, U2 and U3 (Q-177 [3]'s split-word refusal) at dfc78e9a. The hook emits only `allow` (its header says it never emits `ask`), so the ask-path case is moot; the host deny check was Q-176. Ready to archive.
- **Done (dev cycle 2026-10-25):** U1 79c8a6a6 and U2/U3 dfc78e9a are on main; spot-check re-ran `test/auto-approve-allowed-commands.bats` 37/37 and the hook emits only `allow`. Ready for you to set ANSWERED (the cycle cannot close an entry).

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

### Q-147 · q089-loop-split-source-guard
**Needs:** agent · **Opened:** 2026-10-14 · **Status:** OPEN

Q-089 unit A's review-fix loop ran a 4th iteration before recording a cap decision. It is now recorded as `split`: the static source-set test (rubric A6/R2/R4) moves to its own unit, `feat/q089-source-guard` (at fa059477). The rest of unit A starts a new loop. That source-guard unit needs a fresh loop that first narrows the test's claim to "plain spellings, accidental drift". Pass 4 showed grep can't cover every bash form.

- **Read:** `docs/reviews/code-review-rubric-2026-10-14-feat-q089-host-tool-trust.md` "Iteration-4 gate"
- **Interim:** unit A ships without the static guard. The runtime checks don't depend on it, and the guard is hardening against a future refactor.
- **Stuck (dev cycle 2026-10-25):** the source-guard unit needs a fresh build loop that narrows the test's claim; no choice pending.

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
**Needs:** you: terminal · **Opened:** 2026-10-20 · **Status:** OPEN

**Answered (docs/human-author/answers-10-22-26.txt): [2], delete it.**

Decision 039 (merged) fixes the same bug as the unmerged `fix/egress-dnsmasq-ipset` (decision 038, Q-117, the Q-169 spike's target), with no CAP_NET_ADMIN resolver and ~5% of the code. What happens to the old branch?

- **Read:** decision 039's "Why not the alternatives" and Revisit trigger

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Keep it parked** | The branch stays, unmerged, as 039's fallback for `.zone` rotation | None | Clutter. Q-169's spike still names it as its target |
| **[2] Delete it** | `git -C /workspace worktree remove .claude/wt-egress-dnsmasq-ipset && git -C /workspace branch -D fix/egress-dnsmasq-ipset` | One paste | 038's design survives only in git reflog. The decision text is quoted in `docs/working/dd-egress-pin-resolver.md` |

- **Interim:** [1]. Nothing deleted.
- **If the answer differs:** none; deletion is the only action.
- **2026-10-23:** the recording session's deletion was refused by its permission classifier, so nothing is deleted yet. Paste on the host or as `! <command>` in a session (both are local to this checkout; the branch's two commits are not on origin, which [2] accepts):

```
git -C /workspace worktree remove .claude/wt-egress-dnsmasq-ipset && git -C /workspace branch -D fix/egress-dnsmasq-ipset
```

  Close this entry once `git -C /workspace branch --list fix/egress-dnsmasq-ipset` prints nothing.

