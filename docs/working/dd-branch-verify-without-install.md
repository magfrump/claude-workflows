# DD: verify a branch without installing it on the host

- **Goal**: Choose how a branch's cc-isolated changes get a live host verification without installing them over main's config, so that Q-117 (egress fix), Q-130/Q-125 (Bash sandbox) and later Q-098 (global allow list) can be settled while the harness keeps running.
- **Project state**: roadmap Next 3, design only, on `docs/branch-verify-without-install` · inputs: `docs/working/research-branch-verify-without-install.md` (the inventory) · not blocked; the choice is the user's (see the report's questions)
- **Task status**: in-progress (steps 1-4 done; step 4 resolved down Path C, a tentative recommendation awaiting the user; no step-5 decision record until the user answers)

Workflow: `workflows/divergent-design.md`. Steps 1-3 are here in full. Step 4 renders the decision block. Step 5 (`docs/decisions/NNN-…`) waits for the user's choice.

## Step 1 — Diverge

### 1.0 Pre-generation grep

`grep -B1 -A20 "Pruned candidates" docs/decisions/*.md | rg -i "install|prefix|verify|live|probe|second|nested|docker|scratch|WSL"` and the `log.md` scan surfaced:

- **016 [4] hybrid central + blessed override**: "two code paths and two trust regimes". **Carried forward** as soft constraint S3. It decides between [5] and [6] below.
- **015 / 016 [9] WSL2-distro family**: declined in 015's Path-B consult as the *production* boundary. **Revived** as [8] for a different job: a verify host, not the boundary. Why this time is different: the user's motive here is not isolating everyday sessions, but keeping verify runs away from main's install, and a second distro is the most complete side-by-side there is.
- **035 [7] move the installer off the repo**: declined on unverifiability. **Carried forward**, not re-proposed. Nothing here moves install.sh.
- **037 [8 G] pinned worktree**: "the agent can move the worktree HEAD". **Carried forward** as a design rule for every survivor: stage from a resolved tree id, never from a worktree or branch name read later.
- **Decision log row 45** (blessed ≠ verified; the `Live-verified:` gate) and **row 71** (host tools are their own trust category). Not pruned candidates, but they bound the field: a verify must produce live evidence (H4), and a new host-side script falls under row 71.

### 1.1 Candidates

0. **Status quo**: install the branch over main's prefix (the Q-117 / Q-130 pastes), verify, reinstall main.
1. **Status quo with auto-revert**: a wrapper installs the branch, runs the check, and reinstalls main from an EXIT trap.
2. **Second prefix by hand**: install.sh from a main-merged branch worktree with `CLAUDE_DEVC_CONFIG_DIR`/`CLAUDE_DEVC_BIN_DIR` set to a verify prefix. Launch that prefix's cc-isolated on a scratch clone, then delete the prefix.
3. **Second prefix with a scoped gate**: as [2], but install.sh's agent gate looks only at the checkout and at verify containers when the destination is not main's.
4. **Ephemeral stage, by hand**: `git archive` the merge tree (main + branch) into a temp stage. Run *main's installed* cc-isolated with `CLAUDE_DEVC_CONFIG_DIR=<stage>` on a scratch clone (register the profile, probe, run the check), then remove the containers, volumes, image, stage and clone by hand.
5. **Ephemeral stage, as a host tool (`cc-verify`)**: [4] as a reviewed script. It stages the merge tree, refuses unsafe `devcontainer.json` keys, shows the config diff against main's install, drives main's launcher, and tears down from a trap. A `--clean` mode sweeps crash leftovers.
6. **`cc-isolated --verify <tree>`**: [5]'s behaviour built into the launcher itself, with a salted project id, a `cc-verify` label and its own volume names.
7. **Nested container**: docker-in-docker inside a privileged outer container builds and runs the branch image.
8. **Second WSL2 distro as a verify host**: its own docker, devcontainer CLI and install. Branch installs happen there and never in the main distro.
9. **Second docker daemon** (rootless, or a rootful dockerd with its own data-root) selected by `DOCKER_HOST` for verify runs.
10. **Cloud VM or CI runner**: push the branch and verify on a hosted machine with docker. *(Feels wrong: this host never pushes.)*
11. **Merge first, verify on main's first launch**, and revert on failure. *(Time-shifted.)*
12. **Grow the image's own boot self-tests** (the firewall's end-of-run probes, a sandbox self-check at start) until every normal launch is the verification. *(Reframe.)*
13. **Accept `Live-verified: no`**: merge on bats and review alone. *(Do-nothing extreme; feels wrong.)*
14. **Park**: leave the three branches unmerged until some later redesign. *(The literal status quo since 2026-10-12.)*
15. **Scheduled verify window**: batch every pending verify into one weekly slot when the user stops all sessions anyway, using [0] or [1].
16. **Dedicated verify VM with snapshots** (Hyper-V), restored after each run. *(Ideal if effort were free.)*

Health check. Clustering: [2], [3], [4], [5] and [6] all assume "a second namespace on the same daemon". [7], [8], [9], [10] and [16] break that assumption with a second daemon or machine, and [11]-[15] break it by changing the process instead. Missing perspectives: do-nothing is covered by [13] and [14], the naive option by [0], ideal-if-free by [16], and a newcomer's suggestion by [10]. Dimensional anchoring: candidates move on four named dimensions, so no anchoring: *where the config lives* (prefix vs stage), *which launcher runs* (branch's vs main's), *which daemon or kernel* ([7]-[10], [16]), and *when the evidence arrives* ([11], [12], [15]). No candidate was added after the check.

## Step 2 — Diagnose

Hard constraints:

- **H0 The verification happens.** Q-117, Q-125 and Q-098 get a pass/fail verdict from a live run. *success:* a `RESULT`/`pass` verdict line for Q-117's block and for C1-C10 of `live-check-q125.sh`, recorded in the questions archive.
- **H1 Non-blocking.** The verify runs while other Claude sessions and cc-isolated containers keep running (the user's Q-117 answer). *success:* during the run, `pgrep -af claude` lists at least one other session and `docker ps --filter label=cc-project` lists at least one non-verify container, and those containers' IDs are the same before and after.
- **H2 Main's install untouched.** *success:* `sha256sum` of `~/.config/claude-devcontainer/{manifest,host-tools,verified-live}.sha256` and `readlink ~/.local/bin/cc-isolated ~/.local/bin/cc-push` are identical before and after the run.
- **H3 Nothing left to forget** (the user's named risk). *success:* after the run ends (pass, fail or Ctrl-C), `docker ps -a`, `docker volume ls` and `docker images` show no object the run created, the verify root is empty, and an ordinary `cc-isolated <project>` reports the same blessed hash as before.
- **H4 Fidelity: the host's own kernel and dockerd, with the branch's runArgs.** Q-125's open question is bwrap under that profile on WSL2 6.18. *success:* the verify container's `docker inspect … .HostConfig.SecurityOpt` and `.CapAdd` equal the branch's `devcontainer.json` runArgs, on the user's dockerd, with no outer container.
- **H5 No unreviewed branch code runs on the host.** *success:* the host-side commands of a verify run are main's installed files (whose `host-tools.sha256` check passes) plus docker and the devcontainer CLI. The branch's `devcontainer.json` (runArgs, mounts, `initializeCommand`, which runs **on the host** at `devcontainer up`) is shown as a diff against main's installed copy, or is checked against an allowlist, before the build.
- **H6 Verify what would land.** *success:* the staged tree id equals `git merge-tree --write-tree main <branch>` (or the multi-branch merge, for Q-098), and the stage's `claude-home/.manifest` records it.

Soft constraints:

- **S1 Low attention per verify**: one paste, at most two prompts.
- **S2 Small code**: one unit under the ~400-line cap (decision log 62). No growth of `cc-isolated.sh` (944 lines) or `install.sh` (1355), both already over 500.
- **S3 One code path per job** [carried from 016 [4]]: reuse the reviewed launcher rather than a second launcher or installer.
- **S4 Both kinds of check**: non-interactive (Q-117: `devcontainer exec` a shell block) and interactive (Q-130: a Claude session, `/login`).

Non-obvious constraints found in research: the branches are 356 and 476 commits behind main, and Q-125 conflicts with main, so anything staging the branch *tip* tests a stale boundary. A same-path verify recreates that project's real container (`project_id` is the path). Main's launcher sources host code only from its own directory (cc-isolated.sh:714-718), which is what makes the stage approaches H5-clean.

## Step 3 — Match and prune

| # | Approach | H0 | H1 | H2 | H3 | H4 | H5 | H6 | S1 | S2 | S3 | S4 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | Status quo install | ✓ | ✗ | ⚠ | ⚠ | ✓ | ~ | ✗ | ~ | ✓ | ✓ | ✓ |
| 1 | Auto-revert wrapper | ✓ | ✗ | ~ | ~ | ✓ | ~ | ~ | ✓ | ✓ | ✓ | ✓ |
| 2 | Second prefix by hand | ✓ | ✗ | ~ | ~ | ✓ | ~ | ~ | ✗ | ✓ | ✓ | ✓ |
| 3 | Second prefix, scoped gate | ✓ | ✓ | ~ | ~ | ✓ | ⚠ | ~ | ~ | ~ | ✓ | ✓ |
| 4 | Ephemeral stage, by hand | ✓ | ✓ | ✓ | ~ | ✓ | ~ | ✓ | ~ | ✓ | ✓ | ✓ |
| 5 | Ephemeral stage, `cc-verify` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | ~ | ✓ |
| 6 | `cc-isolated --verify` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ | ✓ |
| 7 | Nested container | ~ | ✓ | ✓ | ~ | ✗ | ⚠ | ✓ | ~ | ~ | ~ | ~ |
| 8 | Second WSL2 distro | ✓ | ✓ | ✓ | ~ | ~ | ~ | ~ | ✗ | ✓ | ✓ | ✓ |
| 9 | Second docker daemon | ~ | ✓ | ✓ | ~ | ✗ | ~ | ✓ | ~ | ~ | ~ | ✓ |
| 10 | Cloud VM / CI | ~ | ✓ | ✓ | ✓ | ✗ | ✓ | ✓ | ~ | ~ | ✗ | ~ |
| 11 | Merge first | ✓ | ~ | ⚠ | ⚠ | ✓ | ~ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 12 | Boot self-tests | ~ | ~ | ✗ | ~ | ~ | ~ | ~ | ✓ | ~ | ✓ | ✗ |
| 13 | Accept `Live-verified: no` | ✗ | ✓ | ✓ | ✓ | ✗ | ✓ | ✗ | ✓ | ✓ | ✓ | ✗ |
| 14 | Park | ✗ | ✓ | ✓ | ✓ | ✗ | ✓ | ✗ | ✓ | ✓ | ✓ | ✗ |
| 15 | Scheduled window | ✓ | ✗ | ⚠ | ~ | ✓ | ~ | ~ | ~ | ✓ | ✓ | ✓ |
| 16 | Verify VM with snapshots | ✓ | ✓ | ✓ | ✓ | ~ | ~ | ~ | ✗ | ✓ | ✗ | ✓ |

Scoring notes on the cells that decide a prune:

- [0], [1], [2], [15] fail **H1**: every install, to any prefix, passes install.sh's global agent gate (install.sh:1188-1283). [0] and [15] are also ⚠ on H2/H3, because they replace main's config, which is exactly the forgotten-install risk. [2]'s ~ on H2 is the bin-dir trap (install.sh:598-604).
- [3] is ⚠ on **H5**: it lifts the gate from an install whose launcher, `cc-isolated.sh` in the verify prefix, then runs on the host. That is the one case the gate is there for.
- [7] and [9] fail **H4**: a privileged outer container, or a rootless daemon that already runs inside a user namespace, changes the seccomp/userns context Q-125 is testing. [7] is also ⚠ on H5, since a privileged container is a bigger hole than the risk it removes.
- [10] fails **H4** (not the WSL2 6.18 kernel) and **S3**. This host also never pushes (solo dev, local merges).
- [11] is ⚠ on **H2/H3**: Q-125's own text says "keep the branch unmerged until the host run passes", and decision log row 45 exists because merging before the live run shipped six days without DNS.
- [12] cannot express the 45-minute pool rotation or an interactive `/login`, and still needs an install. **Absorbed** as a later complement, not a rival.
- [13] and [14] fail **H0/H4** by construction. [14] is the honest status quo, and it stays the fallback if the user rejects every survivor.
- [16]: ideal if effort were free. S1 ✗ (setup and per-run snapshot handling) and H4 ~ (a Hyper-V VM is not the WSL2 kernel unless it runs that build).

Survivors: **[5] [6] [4] [8]**. Fix sketches:

- [4]'s H3 ~ (teardown by hand can be forgotten): the leftovers are inert, because their project id is the scratch path's and no ordinary command uses them. But a `/login` credential would linger in the verify volume, so the paste ends with the teardown lines, and Q-117 needs no login at all. [4]'s H5 ~: the paste prints `diff main-installed/devcontainer.json stage/devcontainer.json` and stops for a y.
- [5]'s S2 ~: a new file (~250-300 lines with bats). It sits in `host_tool_files`, never in the image. [5]'s S3 ~: a second host script, but it installs nothing and drives the one launcher, so there is one launcher code path and one host-tool trust regime (row 71).
- [6]'s S2 ✗ is not fixable in place: it adds install.sh-style staging (git archive, payload assembly) to a 944-line enforcement file, and that change itself needs a `Live-verified:` run, through the install path this item is trying to avoid.
- [8]'s H4 ~: the same WSL2 kernel, but a different dockerd install. Two dockerds in WSL2 distros may share one network namespace and both manage iptables **[unverified]**.

## Step 4 — Tradeoffs and decision

| # | Approach | Effort | Risk | Coverage (hard) | Key downside |
|---|---|---|---|---|---|
| 5 | `cc-verify` host tool | one unit, ~250-300 lines incl. bats (~150k tokens) | low | 7/7 | a new host script to review and keep in step with the launcher's assumptions |
| 6 | `cc-isolated --verify` | one unit, ~250 lines into the launcher, plus its own live run | med | 7/7 | grows a 944-line enforcement file, and its own verify needs a main install |
| 4 | Ephemeral stage by hand | ~1 h to write the paste; 0 code | med | 5/7 (H3, H5 ~) | a ~30-line paste per verify, with teardown and the diff stop left to the user |
| 8 | Second WSL2 distro | 1-2 days of the user's host setup; 0 code | med | 4/7 (H3, H4, H5, H6 ~) | a whole second environment to keep current and not to mistake for main |

Falsifiable hypotheses:

- **[5]** If chosen, then within 2 weeks of the unit merging, Q-117 and Q-130 each get a verdict from a run during which at least one other session kept running, with main's manifest hashes unchanged. Counter-evidence: a run that needs sessions closed; a post-run `docker volume ls` or verify-root listing with leftovers; or a container whose SecurityOpt differs from the branch's runArgs.
- **[6]** If chosen, the same verdicts arrive within 3 weeks: the launcher change first needs its own install and probe. Counter-evidence: the `--verify` unit's review loop splits it past one unit, or its own live run is deferred like Q-117's.
- **[4]** If chosen, the first paste gives Q-117 a verdict within a week without closing sessions. Counter-evidence: main's launcher refuses the stage (a manifest or host-tool error), or the user reports leftovers or a skipped diff stop after a run.
- **[8]** If chosen, a branch verify runs in the second distro within 2 weeks of setup. Counter-evidence: the second dockerd conflicts with the first's iptables, or the distro drifts from main's toolchain so far that results stop transferring.

Stress-test pass:

- **Boring alternative** (on [5]): is [4] enough? For a verify every few weeks, maybe. But the brief's named risk is the *forgotten* step, and [4] makes teardown and the `devcontainer.json` stop the user's memory again. *Changed:* [4] is kept as [5]'s **first step** (the spike that proves the four unverified claims, and gives Q-117's verdict at the same time), not as the destination.
- **Invert the thesis** (argue [6] over [5]): one launcher means no drift between `cc-verify`'s assumptions and the launcher's. That is real. The assumption [5] rests on is "the launcher sources host code only from its own directory" (cc-isolated.sh:714-718). *Changed:* [5] must ship a bats test pinning that property, and refuse to run if it fails, so a future launcher change cannot silently turn a stage into host code.
- **Failure-driven** (on [5], [4]): a new failure class neither the status quo nor [2] has: the branch's `devcontainer.json` reaches the host daemon *without* the install diff. `initializeCommand` runs on the host; `runArgs` can say `--privileged`, `-v /:/host`, `--pid=host` or `seccomp=unconfined`; `mounts`/`workspaceMount` can bind host paths; `build.options` passes flags to `docker build`. *Changed:* H5 now names these, [5]'s key downside is "mitig.", and the pre-mortem below takes them in turn.
- **Push to extreme** (on [5]): ten pending verifies at once, as with Q-098's three-way merge. Each run is keyed on its scratch path, so runs don't collide. The cost is disk (one image per run) and build time. Base layers are shared with main's image only if the Dockerfile prefix is byte-identical. *No change*, but the plan should say "one verify at a time" by default.
- **Revealed preferences** (on [8]): the user declined the WSL-distro family once (015 Path B) and answers terminal entries by batch. A 1-2 day host setup gets parked. *Changed:* [8]'s effort glyph stays ○.

### Decision presentation

```
┌─ DECISION: verify a branch's cc-isolated change live without installing it over main ─┐
│ 4 candidates survived step-3 pruning · scored on the step-4 axes                       │
└────────────────────────────────────────────────────────────────────────────────────────┘

  legend   ● strong / low   ◐ partial / medium   ○ weak / high   ✗ fails hard constraint

   #    approach                 effort         risk     coverage      key downside
  ───  ──────────────────────  ─────────────  ───────  ────────────  ──────────────────────────────────────
   5 ★ cc-verify host tool      ◐ 1 unit       ● low    ● 7/7 hard    ◐ new host script tied to launcher (mitig.)
   6   cc-isolated --verify     ◐ 1 unit+run   ◐ med    ● 7/7 hard    ○ grows 944-line enforcement file
   4   ephemeral stage by hand  ● ~1 h         ◐ med    ◐ 5/7 hard    ◐ teardown and diff stop left to memory
   8   second WSL2 distro       ○ 1-2 days     ◐ med    ○ 4/7 hard    ○ second environment to keep current
```

```
╭─ [5] cc-verify host tool   ★ recommended ──────────────────────────────────────╮
│ effort    1 unit (~250-300 lines incl. bats; ~150k tokens)   risk  low          │
│ coverage  7/7 hard · 3/4 soft (S2, S3 partial)                                   │
│ hypothesis  "If chosen, Q-117 and Q-130 each get a verdict within 2 weeks of     │
│             the unit merging, from a run with ≥1 other session alive and main's  │
│             manifest hashes unchanged; counter-evidence = sessions had to close, │
│             leftovers after a run, or SecurityOpt ≠ the branch's runArgs."       │
│ stress-tests applied                                                             │
│   · Boring alternative → [4] becomes [5]'s first step (spike + Q-117 verdict)    │
│   · Invert the thesis → bats pin: launcher sources host code only from its dir   │
│   · Failure-driven → devcontainer.json allowlist + diff stop (initializeCommand) │
│ key downside  a second host script that assumes the launcher's layout; mitigated │
│               by the pinning test and by refusing on a failed self-check        │
╰──────────────────────────────────────────────────────────────────────────────────╯
```

Expand any other candidate's card by naming its `#`.

```
▶ recommend [5] cc-verify host tool · confidence 70% · runner-up [6], axis = separate host tool vs one launcher code path
```

**Path C** (no human present): the static block above is the record. The choice goes to the user through the caller's report as a question with an options table, not through `docs/working/questions.md` (this unit is not allowed to edit it). Tentative pick: [5], starting with [4] as its first step. Axis of disagreement between [5] and [6]: *a separate host tool vs one launcher code path*. The project's stated preference along that axis is S3 (016 [4]: avoid two code paths), which favours [6]. S2 (no growth of the over-500-line enforcement files) and H1-in-practice (a launcher change needs its own install-path live run, which is what this item exists to avoid) favour [5]. Tiebreaker: the constraint that unblocks the three merges soonest wins, which is [5].

**Status quo.** [14] (park) remains a valid answer. It costs nothing and keeps Q-117, Q-125 and Q-098 parked indefinitely. [0] (install over main) is not: it fails the user's own H1 and their named risk.

## Bypass and safety pre-mortem (for [5], applies to [4] too)

Assume `cc-verify` shipped and, three months later, caused a security incident or a false verdict. The stories:

1. **The forgotten verify session.** The user opens a Q-130 verify, gets distracted, and the next day keeps working in that window, thinking it is claude-workflows. Work runs under an unmerged boundary, and commits land in a scratch clone that teardown deletes. *Root cause:* a verify session looks like a real one. *Mitigation:* `CC_PROJECT_NAME=VERIFY-<tree8>` (it becomes the devcontainer's display name, devcontainer.json:22; docker's own container name is generated), a banner at start and exit, the scratch clone under `~/cc-verify/verify-<tree8>`, and teardown at session exit (the launcher returns, the trap runs). Teardown refuses to delete a clone holding commits that are not in the source repo, and prints them instead.
2. **Crash leftovers holding a credential.** A `kill -9` or power loss skips the trap. A container, a `cc-<pid>-claude-config` volume holding a `/login` credential, and the stage survive. *Root cause:* trap-only cleanup. *Mitigation:* everything a run creates is named from the run's id (stage dir, clone path, pid-derived volumes) and recorded in a run file under the verify root before creation. `cc-verify` refuses to start a new run while a run file exists, until `cc-verify --clean` has removed it. Nothing is picked up by ordinary commands, because the project id is the scratch path's (cc-isolated.sh:372).
3. **A hostile `devcontainer.json` on the branch** (the bypass family this design introduces). An agent-written branch adds `initializeCommand` (runs on the host), `--privileged`, a host bind in `mounts`, or `seccomp=unconfined`. Under the status quo the install diff showed it. Here nothing would. *Mitigation:* before `devcontainer up`, (a) refuse when the staged `devcontainer.json` has any top-level key outside main's installed copy's key set, or any `initializeCommand`, `features`, `build.options` or `workspaceMount` that differs from main's; (b) refuse runArgs outside an allowlist (`--cap-add=NET_ADMIN`, `--cap-add=NET_RAW`, `--security-opt seccomp=<file inside the stage>`); (c) refuse `mounts` other than the two `cc-${localEnv:CC_PROJECT_ID}-*` volumes; (d) show the diff against main's installed copy and ask y/N. Prefer the CLI's resolved view (`devcontainer read-configuration`) **[unverified]**, since devcontainer.json is JSONC and a text check of comments and strings is easy to fool.
4. **Stage swapped between review and build.** A same-uid host process rewrites `seccomp-cc-sandbox.json` in the stage after the y. Main's launcher's manifest does not hash that file (its `enforcement_files` predates Q-125), so the build uses the swapped file and the verdict is about a different profile. *Mitigation:* hash the whole stage (install.sh's `tree_hash` approach) before the review, and again after the container is created. Refuse the verdict on a mismatch. Residual: a swap-and-revert inside that window, the same residual decision 037 accepts for install target 1. cc-isolated agents cannot reach the stage at all.
5. **A launcher change turns the stage into host code.** A later main change makes cc-isolated source a helper from `config_dir` instead of its own directory. From then on every verify runs branch code on the host, and nobody notices. *Mitigation:* the bats pin from the stress test. Also, `cc-verify` checks at start that the stage holds no file the launcher would source (it compares `host_tool_files` against the launcher's `source` lines), and it removes the host tools from the stage after the bless.
6. **False pass from the wrong tree.** The verify stages the branch tip, 356 commits behind, passes, and the merge brings in a conflict resolution nobody verified. *Mitigation:* H6, staging only `git merge-tree --write-tree main <branch>`, refusing on conflict. The tree id goes into the trailer (`Live-verified: <hash> — cc-verify of tree <id>`).
7. **Agent-run verify.** A bare-host agent runs `cc-verify` itself with an agent-written branch. *Mitigation, partial:* refuse when `CLAUDECODE` is set (install.sh's target-2 rule). This stops accidents only. An agent with docker access on a bare host already has host root through docker, and cc-isolated agents have no docker. Recorded as a residual, not covered.

| Bypass family | Covered? |
|---|---|
| Host execution via `initializeCommand` / lifecycle hooks | covered by refusal (3a) |
| Container privilege via runArgs / mounts / build options | covered by allowlist (3b, 3c), plus diff stop |
| Stage tampering after review | partly (4): hash at both ends; swap-and-revert residual |
| Launcher sourcing branch code | covered by pin and self-check (5) |
| Verdict on a stale tree | covered (6) |
| Leftover credential / container | covered by run file and `--clean` (2) |
| Forgotten session mistaken for real | partly (1): naming, banner, exit teardown; a user can still ignore them |
| Agent invoking the tool | residual (7) |
| Collision with a real project's container/volume/image | covered for container and volumes by the scratch path; image **[unverified]**, checked by the first step |

## Next unit

1. **Spike (candidate [4] as [5]'s first step).** The agent writes a `you: terminal` paste, about 30 lines. It stages `git merge-tree --write-tree main fix/egress-dnsmasq-ipset` into `~/cc-verify/stage-<tree8>` (the PAYLOAD items from `devcontainer-config/`, plus `claude-home/` assembled from `global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts` and a `.manifest`). It clones the repo to `~/cc-verify/verify-<tree8>`, runs `CLAUDE_DEVC_CONFIG_DIR=<stage> cc-isolated --register <clone> --profile android`, then `--probe-only`, then `devcontainer exec` with Q-117's container block, records `docker ps -a / volume ls / images` and main's hashes before and after, and tears down. One run settles Q-117 and the four unverified claims in the research doc §7. Size: small, a doc and a paste, no code.
2. **Build `devcontainer-config/cc-verify.sh`**, if the spike passes, as an RPI unit under the decision-62 cap (~250-300 lines incl. bats). It is a host tool (`host_tool_files`, `Host-tool-tested:`), with the pre-mortem's mitigations 1-7 as its test list.
3. **Then** merge main into `feat/q125-cc-isolated-sandbox` (resolving the `hooks/live-verify-gate.sh` conflict), and run Q-130 through `cc-verify`.

## Hypothesis

Not emitted: this is a standalone single-shot DD, not a multi-round context.
