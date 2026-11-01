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
| [Q-242](#q-242--merge-gate-2026-10-31-failure-patterns-out-of-thoughts-c3f3f0e49f17) | you: judgment | Merge `refactor/failure-patterns-out-of-thoughts` at c3f3f0e49f1721319de7279ddc47ec15bdac7695? It does what... | 2026-10-31 |
| [Q-243](#q-243--merge-gate-2026-11-01-relax-dev-cycle-skill-prose-7e6f1e0e9655) | you: judgment | Merge `docs/relax-dev-cycle-skill-prose` at 7e6f1e0e96550bda192e7d8cece50a6266d76b47? This is unit 3 of you... | 2026-11-01 |
| [Q-244](#q-244--merge-2026-11-01-relax-referenced-prose-stops-8ca8ec2e0591) | you: judgment | Merge `docs/relax-referenced-prose-stops` at 8ca8ec2e059138d0f42e380cdcfc6476c652ea0e? This is unit 2 of yo... | 2026-11-01 |
| [Q-245](#q-245--merge-gate-2026-11-01-relax-gate-git-state-75dbfa2a6e80) | you: judgment | Merge `refactor/relax-gate-git-state` at 75dbfa2a6e80104d33ecb8aa5741f06c3444b013? This is unit 1 of your r... | 2026-11-01 |
| [Q-084](#q-084--q076-live-checks) | you: terminal | Q-076 (`cc-push`, the exit scan) was verified only with bats: stubbed docker and local-path remotes, on git... | 2026-09-27 |
| [Q-167](#q-167--post-install-host-probes) | you: terminal | The install is done: the image was built from main at fbe67674 on 2026-10-16 (Q-156), and it carries all th... | 2026-10-15 |
| [Q-222](#q-222--install-cc-verify-and-r6) | you: terminal | Four approved merges landed today, two of them in host tools: the `cc-verify` host tool (37b24c02, Q-217) a... | 2026-10-28 |
| [Q-227](#q-227--image-lag) | you: terminal | - The failure-pattern library is `docs/failure-patterns.md`. It stays protected (the self-merge floor, the ... | 2026-10-29 |
| [Q-234](#q-234--migrate-questions-owner-routes-040) | you: terminal | The convention migration `questions-owner-routes-040` (decision 040: `questions.md` holds only owner routes... | 2026-10-29 |
<!-- index:end -->

## Open

### Q-245 · merge-gate-2026-11-01-relax-gate-git-state-75dbfa2a6e80
**Needs:** you: judgment · **Opened:** 2026-11-01 · **Status:** OPEN

**If you say no:** every gated mode keeps refusing ordinary honest setups (git-lfs, `merge.conflictStyle`, `include.path`, fsmonitor, SSH signing, a husky hooks path, duplicate packed and loose objects, autocrlf, sparse or case-insensitive checkouts). Each refusal still stops the iteration and files an entry for you.

**What an attacker would want here:** nothing new from an outside party. The checks removed only stopped planted git state or forged objects, which S1 puts out of scope. The gate still computes the merge in its own empty repository and lands it by update-ref, so no configured merge driver or hook runs (H1). It still refuses shallow and partial clones and the variables that point git at another repository or index (H2).

Merge `refactor/relax-gate-git-state` at 75dbfa2a6e80104d33ecb8aa5741f06c3444b013? This is unit 1 of your restriction audit. It narrows the gate's git-state checks to in-scope threats (10 files, +459/-526).

- **Why it's yours:** it changes the gate's own code (`scripts/build-loop.sh`, `scripts/lib/`, `skills/dev-cycle/SKILL.md`), which never self-merges.
- **What changes:**
  - **`state_gate`** refuses only a shallow or partial clone. Merge, diff, filter, include, hook, gpg and fsmonitor config, info/attributes, grafts, alternates and replace refs all pass now.
  - **`store_check`** (re-hashing every object, refusing duplicate copies) is removed. Its useful half, checking that every blob the merge names exists, is a shared `blobs_present` used by `--check` and `--land-cycle`.
  - **`checkout_gate`** keeps HEAD at main, a clean status (an unmerged path still refuses), and the five variables (GIT_DIR, GIT_WORK_TREE, GIT_INDEX_FILE, GIT_OBJECT_DIRECTORY, GIT_COMMON_DIR). It drops the per-file hashing and the ignoreCase, sparse, symlinks, nested-repo and skip-worktree refusals.
  - **`caller_gate`** refuses only those five variables.
  - **`git_harden`** drops the commit-graph and multi-pack-index pins.
  - **SKILL.md:** step 0.1's `--state` paragraph and the Hardened git note now describe this.
- **Two audit verdicts the loop reversed, with reasons (research doc D2, D4):**
  - **The default-branch rules stay** (origin/HEAD naming another branch, main and master both existing). The D6 block also requires exactly one of main and master, so relaxing only the gate would make the two disagree. This waits for unit 7.
  - **`GIT_CONFIG_GLOBAL=/dev/null` stays in the gate,** so your global merge settings can't change the merge it computes.
- **Checks:**
  - 10 new cases, one per honest setup above, plus one `--merge` case with all of them at once that checks no hook runs. Each failed on the old code. The build-loop suites pass 233/233, and the loop's full health check passed.
  - Two review iterations. Iteration 1 used two independent reviewers and found nothing High. Fixed: an unreadable origin/HEAD refuses again (H2), symlink blobs are checked, and the lfs tests now actually run the filter. Iteration 2's reviewer broke each new check on purpose and the tests caught every break.
  - I read the `build-loop.sh` code diff myself.
- **Residual (research doc):** an exported `GIT_CONFIG_PARAMETERS` is no longer refused and reaches the gate's merge. A nested repository's instruction files are not walked (unit 6's area).
- **Merge order with Q-243 and Q-244:** all three were built from the same main. This one and Q-243 both edit SKILL.md's Hardened git passage, and this one and Q-244 both add decision-log row 79. Merge this first. A later one that then conflicts comes back as a `stopped` entry. Answer it `[1]` and its loop runs one round to merge main in.
- **Takes effect:** at the next release, since the gate runs from the image.
- **`--check` printed:** `ok docs/working/briefs/2026-11-01-relax-gate-git-state.md 75dbfa2a6e80104d33ecb8aa5741f06c3444b013 3fc2c1c141be7b0559881e8cb17fd5ec756ee060`, plus 10 path lines:
  - `docs/decisions/log.md`, the brief and the research doc;
  - `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh` and `skills/dev-cycle/SKILL.md`;
  - four test files under `test/scripts/`.
- **Paths self-merge's floor would refuse:** the gate code above and `docs/decisions/log.md`.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] merge** | The next iteration merges 75dbfa2a; it takes effect at the next release | None beyond this answer | One `git revert` of the merge |
| **[2] drop** | The brief closes; the gate keeps refusing honest setups | None now | Refusals keep reaching you |
| **[3] changes needed** | Your note goes back to the loop | A one-line note | Another loop round |

- **Blocks:** audit units 4-7 (they edit the same files).
- **Interim:** the branch waits.

### Q-244 · merge-2026-11-01-relax-referenced-prose-stops-8ca8ec2e0591
**Needs:** you: judgment · **Opened:** 2026-11-01 · **Status:** OPEN

**If you say no:** "stop and wait" keeps firing on failing tests and ambiguous requirements in /away, the plan gate stays unconditional, a long review unit waits for your waiver, and security review keeps rating hostile-loop routes as Must Address.

**What an attacker would want here:** nothing new for an outside party. Outside text that turns a loop stays in scope for security review at its normal severity. Only routes that need a deliberately hostile loop, branch or planted git state drop to Informational (S1). The threat-model lines are read from main, never from the branch under review, so a branch can't scope out its own attack.

Merge `docs/relax-referenced-prose-stops` at 8ca8ec2e059138d0f42e380cdcfc6476c652ea0e? This is unit 2 of your restriction audit. It narrows the stops and over-wide rules in the workflows and skills the cycle uses (prose only; 14 files, +192/-34).

- **Why it's yours:** it changes `global-instructions/CLAUDE.md` and instruction files under `skills/` and `workflows/`. These are on the self-merge floor, and `workflows/` is also on your never line.
- **What changes:**
  - **Global instructions (/away):** failing tests with no obvious fix, and costly ambiguity, now mean set the task aside, file the question and keep working. You're still stopped for irreversible operations, and for a merge conflict only when its resolution would discard a change that can't be combined. The any-mode "guessing wrong would waste significant work" line goes. Net: 3 lines shorter.
  - **RPI:**
    - The plan-approval gate applies in /active only.
    - A context overrun gets a checkpoint, not a stop.
    - The enforcement-file pre-mortem lists bypass families within the project's threat model (H1 is always in).
    - A clean revert range counts as the Rollback.
  - **Review-fix loop:** in /away, a unit past ~800 lines splits automatically. It waits for your waiver only when no split exists. A re-firing finding gets the deeper fix. Only findings below Must Fix may be accepted and documented.
  - **Security review:** a mechanism only an attacker the constraints doc puts out of scope can reach becomes Informational, `out of scope (constraints S1)`. Code review pastes those lines into the security critic's brief.
  - **constraints-builder** may run the repo's tests, lint or build in its sandboxed scratch copy, under `timeout`.
  - **`guides/convention-changes.md`:** migration pastes are collected into one.
- **The loop departed from the brief on one point (K94).** The brief said the Fact-Check Gate should default to **Fix first** when no one is there to answer. The loop chose **Continue**: Incorrect findings still reach the critics and block merge at their tier, and the terminal pass needs the full panel anyway, so Fix first would cost a second full pass with no recall gain (S7). I agree, but it's your call. If you want Fix first, answer [3] with that note.
- **Checks:**
  - Three review iterations by a fact-check subagent and a contradiction-and-scope critic. They fixed two leftover /away contradictions, an H1 hole in the threat-model rule, a self-authorising constraints read and unattended accept-and-document of a Must Fix.
  - Three findings were declined, each with an override-log row. One is a follow-up: `skills/draft-review/SKILL.md` has the same Fact-Check Gate and still asks unattended.
  - The full health check passed. I read the global-instructions, security-reviewer and code-review diffs myself.
- **Takes effect:** your host install at the next host install, and sessions in the image at the next release.
- **`--check` printed:** `ok docs/working/briefs/2026-11-01-relax-referenced-prose-stops.md 8ca8ec2e059138d0f42e380cdcfc6476c652ea0e 6b330fd20c1373c30df5b8dc750d47b84959c2c7`, plus 14 path lines:
  - `docs/decisions/log.md` (row 79), `docs/reviews/override-log.md`, the brief and the research doc;
  - `global-instructions/CLAUDE.md`, `guides/convention-changes.md` and `guides/pr-prep-quick-ref.md`;
  - `skills/code-review/SKILL.md`, `skills/constraints-builder/SKILL.md`, `skills/research-plan-implement/SKILL.md` and `skills/security-reviewer/SKILL.md`;
  - `workflows/pr-prep.md`, `workflows/research-plan-implement.md` and `workflows/review-fix-loop.md`.
- **Paths self-merge's floor would refuse:** the instruction files above, `workflows/` (your never glob) and `docs/decisions/log.md`.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] merge** | The next iteration merges 8ca8ec2e | None beyond this answer | One `git revert` of the merge |
| **[2] drop** | The brief closes and the stops stay | None now | Loops keep stopping on you |
| **[3] changes needed** | Your note goes back to the loop (for example, Fix first for K94) | A one-line note | Another loop round |

- **Blocks:** nothing.
- **Interim:** the branch waits.

### Q-243 · merge-gate-2026-11-01-relax-dev-cycle-skill-prose-7e6f1e0e9655
**Needs:** you: judgment · **Opened:** 2026-11-01 · **Status:** OPEN

**If you say no:** the dev-cycle skill keeps its hardened-git wrapper, the identity routine, the repeated state checks and the main-log stop. An iteration keeps costing about 40 tool calls, most of them those rituals.

**What an attacker would want here:** nothing new from an outside party. The change drops defences against planted git config and disguised commits, which S1 puts out of scope. It keeps the run-from-image gate (H1), the argument allowlist, staging named paths only, and `--cycle-diff`.

Merge `docs/relax-dev-cycle-skill-prose` at 7e6f1e0e96550bda192e7d8cece50a6266d76b47? This is unit 3 of your restriction audit (`docs/working/research-2026-11-01-restriction-audit.md`). It drops the dev-cycle skill's rituals that only defend against a hostile loop.

- **Why it's yours:** it changes `skills/dev-cycle/SKILL.md`, which is gate code and never self-merges.
- **What changes:**
  - **Git commands:** the orchestrator's own git is plain `git -C PATH` with your normal config and identity, and the `hg` wrapper and identity routine go. It checks that `user.name` and `user.email` are set before committing, and keeps three cheap pins: no signature in logs whose output is read, no commit signing, and literal pathspecs on add/mv/rm.
  - **Fewer checks:** no extra `--state` runs before commits, merges and the gate checkout; no `--check-write` before writes; no re-check before staging; no tree-equality check. `--cycle-diff` still bounds what lands.
  - **Main-log refusal:** a `refuse main-log:` line is reported in the record and the final message. The iteration re-anchors at the current main, with no entry and no hold.
  - **Worktree removal:** plain `worktree remove`. `--force` is kept only where a stop leaves edits meant to be discarded.
  - **Branch names:** a checked branch name may reach git as `refs/heads/NAME`.
  - **Untouched:** the D6 block and step 0.1's `--state` paragraph. Unit 1 owns that paragraph, and the D6 block goes in a later unit.
- **Checks:**
  - The loop re-checked every audit row it acted on, with three divergent-design decisions, each with one clear winner.
  - Two review iterations by an independent reviewer. Iteration 1 found 1 Must Fix (the `refs/heads/` wording broke `branch -d`) and 2 Must Address (a plain remove left a stopped WT behind; a false claim about git refusing commits without an identity). All were fixed. Iteration 2 found nothing at either level.
  - A new bats case checks that the dropped rules stay gone and the kept ones remain, and it fails on the old SKILL.md. The loop's full health check passed.
  - I read the SKILL.md diff myself.
- **Takes effect:** for the orchestrator, at the next release (the skill is read from the image), after Q-227's.
- **Expect a conflict:** unit 1 (`refactor/relax-gate-git-state`, still running) edits the same "Hardened git" passage. Whichever merges second merges main in first.
- **Residual:** an outside party's repo with a symlinked `docs/working/briefs/closed/` could take one `git mv` out of the tree, because the digest does not check that directory.
- **Follow-up, outside this unit:** `scripts/dev-cycle.sh:193`'s skip message still says "use --check-write".
- **`--check` printed:** `ok docs/working/briefs/2026-11-01-relax-dev-cycle-skill-prose.md 7e6f1e0e96550bda192e7d8cece50a6266d76b47 35b83234a8bf0614454e8c58d550a93d3c28254e`, plus path lines for the brief, `docs/working/plan-build-loop-handoff.md`, the research doc, `skills/dev-cycle/SKILL.md` and `test/scripts/build-loop-orchestrator.bats` (5 files, +213/-115).
- **Paths self-merge's floor would refuse:** `skills/dev-cycle/SKILL.md` (gate code).

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] merge** | The next iteration merges 7e6f1e0e; the orchestrator follows it after the next release | None beyond this answer | One `git revert` of the merge |
| **[2] drop** | The brief closes and the rituals stay | None now | Iterations keep their cost |
| **[3] changes needed** | Your note goes back to the loop | A one-line note | Another loop round |

- **Blocks:** nothing.
- **Interim:** the branch waits.

### Q-242 · merge-gate-2026-10-31-failure-patterns-out-of-thoughts-c3f3f0e49f17
**Needs:** you: judgment · **Opened:** 2026-10-31 · **Status:** ANSWERED

**If you say no:** `docs/thoughts/` stays on the self-merge floor, so a branch that touches a thoughts note keeps going to your review, in this repo and the others.

**What an attacker would want here:** nothing new from an outside party. The change moves one file and narrows what the floor refuses. It reads and writes nothing outside the repo.

Merge `refactor/failure-patterns-out-of-thoughts` at c3f3f0e49f1721319de7279ddc47ec15bdac7695? It does what you asked on 2026-10-31. The failure-pattern library moves to `docs/failure-patterns.md`, next to `dev-cycle.md` and `constraints.md`. `docs/thoughts/` leaves the self-merge floor, so branches that edit thoughts notes can self-merge.

- **Why it's yours:** it changes the gate's own code (`scripts/build-loop.sh`, `scripts/lib/`, `skills/dev-cycle/SKILL.md`), which never self-merges.
- **What changes:**
  - **The library stays protected at its new path.** The floor, the cycle's in-cycle fixes and the cycle's land check all refuse it, and the old path too, so a repo that hasn't migrated can't lose its library unreviewed.
  - **The rest of `docs/thoughts/` is open** to all three.
  - **About 40 references now name the new path:** the gate, `self-improvement.sh`, `questions.sh`, three workflows, a guide and the tests.
  - **Your other repos:** a migration, `failure-patterns-out-of-thoughts` (`git mv docs/thoughts/failure-patterns.md docs/failure-patterns.md`). The dev cycle files it as a paste for you in each repo after the release. Until a repo runs it, only a `fix(...)` branch there with no skip line is held, with a message naming the remedy; every other branch passes.
- **Checks:**
  - The loop ran two review rounds. Both Mediums in round 1 were fixed: the old path had been unguarded, and two lists of truth files were stale. Round 2 found only Lows, fixed but one: a new stderr line in `self-improvement.sh` has no test.
  - Every new or changed test fails on the code before the change.
  - The loop's full health check passed.
  - On the tree the branch makes with main (a1310a3f), the six touched suites pass 308/308.
  - I read the floor, migration and gate diffs myself.
- **Takes effect:** at the next release (Q-227), since the gate runs from the image; then once per repo, its migration.
- **`--check` printed:** `ok docs/working/briefs/2026-10-31-failure-patterns-out-of-thoughts.md c3f3f0e49f1721319de7279ddc47ec15bdac7695 a1310a3f3f4f5a8e4dad436cf92060124d662b9d`, plus 23 path lines. The code paths are `scripts/build-loop.sh`, `scripts/dev-cycle.sh`, `scripts/lib/dev-cycle-read.sh`, `scripts/lib/migrations.sh`, `scripts/questions.sh`, `scripts/self-improvement.sh`, `skills/dev-cycle/SKILL.md`, three workflows, `guides/harness-feedback.md` and six test files. The docs are `docs/decisions/log.md`, the moved library, the plan, the brief and its research doc.
- **Paths self-merge's floor would refuse:** the gate code and `SKILL.md` above; `docs/decisions/log.md`; the library at both paths.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] merge** | The next iteration merges c3f3f0e4; it takes effect at the next release | None beyond this answer | One `git revert` of the merge, plus moving the file back in any repo that already migrated |
| **[2] drop** | The brief closes; `docs/thoughts/` stays on the floor | None now | Thoughts edits keep coming to your review |
| **[3] changes needed** | Your note goes back to the loop (for example, take the library off the floor too) | A one-line note | Another loop round |

- **Blocks:** nothing.
- **Interim:** the branch waits.

**Answered:** [1] (owner, in session 2026-11-01: "Q-242: [1]"; recorded by the dev cycle)

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

### Q-227 · image-lag
**Needs:** you: terminal · **Opened:** 2026-10-29 · **Status:** OPEN

**Release notes** (trial T1; rewritten 2026-11-01 for main at 18e9cb79). Installed image: `46929c81`, read from `/opt/claude-workflows/.manifest`. Main is ahead in gate code: the failure-patterns move you approved (Q-242). The image runs the gate, so the move is not live until you run the paste.

**⚑ Merged without your review:** none.

**What changes for you** (approved by you, Q-242):
- The failure-pattern library is `docs/failure-patterns.md`. It stays protected (the self-merge floor, the cycle's fixes and its land check refuse it, at both the old and new paths).
- The rest of `docs/thoughts/` leaves the self-merge floor, so build-loop branches that edit thoughts notes can self-merge.
- Your other repos: after this release, the dev cycle files a one-line migration paste in each (`git mv docs/thoughts/failure-patterns.md docs/failure-patterns.md`). Until a repo runs it, only a `fix(...)` branch there with no skip line is held.

**Not listed:** 2 routine dev-cycle record lands. Paths changed outside `docs/` (7 under `docs/` not listed): `guides/harness-feedback.md`, `scripts/build-loop.sh`, `scripts/dev-cycle.sh`, `scripts/lib/dev-cycle-read.sh`, `scripts/lib/migrations.sh`, `scripts/questions.sh`, `scripts/self-improvement.sh`, `skills/dev-cycle/SKILL.md`, `workflows/codebase-onboarding.md`, `workflows/pr-prep.md`, `workflows/research-plan-implement.md`, and six test files.

**The paste** (host terminal in WSL, not inside a session; stop every session first):

```
cd /home/magfrump/claude-workflows && git merge-base --is-ancestor 18e9cb7951f5a68535d1c495195afb2d38364d01 HEAD && ./devcontainer-config/install.sh
```

The `merge-base` check runs no hook and only confirms that your checkout holds at least these changes.

- **Interim:** the image at 46929c81 runs; `docs/thoughts/` stays on the floor until then.
- **Blocks:** nothing.

### Q-234 · migrate-questions-owner-routes-040
**Needs:** you: terminal · **Opened:** 2026-10-29 · **Status:** ANSWERED

The convention migration `questions-owner-routes-040` (decision 040: `questions.md` holds only owner routes) is pending here. The digest found an old-shape line in `docs/working/questions.md` (line 103 when filed: `**Needs:** agent`, Q-168's entry), and 11 open entries still carry an `agent`, `trigger` or `deferred` route. `questions.sh migrate` moves them, without loss, to `docs/working/watching.md` (watches) and `docs/working/roadmap-from-questions.md` (agent work, which the next dev cycle folds into the roadmap). Run this from the repo's root in a session (not the host), then commit the files it changed:

```
cd /workspace && ~/.claude/scripts/questions.sh migrate && git add docs/working/questions.md docs/working/watching.md docs/working/roadmap-from-questions.md && git commit -m "docs(questions): run questions.sh migrate (Q-234, migration questions-owner-routes-040)"
```

- **Read:** `scripts/lib/migrations.sh` (the registry line) · `docs/decisions/040-questions-doc-owner-only.md` · Q-229 in the archive (the unit that added `migrate`)
- **Blocks:** nothing.
- **Now (2026-10-30):** unit 3 merged (01022de2, Q-235 [1]). Run this after the Q-227 release, because the digest reads `watching.md` only from the image.
- **Interim:** the iteration goes on; every reader still reads the old routes in `questions.md`. The cycle cannot run it itself: `--cycle-diff` refuses a chore commit that rewrites entries' **Needs:** lines. Run it only after unit 3 (`feat/questions-owner-only-unit3`, roadmap In flight; sent back to its loop this cycle) has merged: until then the digest reads watches only from `questions.md`, so migrating first drops them from the cycle's view (the unit 3 brief's motive).

**Answered:** done (owner, in session 2026-11-01: "Q-234: do it"). Run in session from the image copy (`questions.sh migrate`): 9 entries moved, Q-161, Q-067, Q-098 to `watching.md`, six agent entries folded into roadmap Now (Q-173 dropped: settled by Q-238 [1]).
