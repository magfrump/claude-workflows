# Research: verify a branch without installing it on the host

- **Goal**: List what Q-117's, Q-130's, Q-098's and Q-125's checks need from the host, and for each need, whether a side-by-side install (a second config prefix, image tag or volume namespace) or a nested container could supply it without touching main's install.
- **Project state**: roadmap Next 3, research and design only, on `docs/branch-verify-without-install` (from main b279a2ba) · feeds `docs/working/dd-branch-verify-without-install.md` · not blocked
- **Task status**: complete (inventory done; the DD recommends an approach; no code written)

Last verified: 2026-10-15 against main b279a2ba, `feat/q125-cc-isolated-sandbox` 2961ca2f, `fix/egress-dnsmasq-ipset` b26d4b8b, `feat/wiring-allowlist-b` 4b6da9f9.
Relevant paths: `devcontainer-config/install.sh`, `devcontainer-config/cc-isolated.sh`, `devcontainer-config/devcontainer.json`, `devcontainer-config/Dockerfile`, `docs/decisions/037-bare-host-copy-install.md`, `hooks/live-verify-gate.sh`

Everything below was read from the repo and the branches with `git show` / `git diff`. Nothing here ran on the host. The claims marked **[unverified]** depend on host behaviour this sandbox cannot see. The next unit's first step checks them.

## 1. Why a branch install blocks the harness and leaves a hazard

The Q-117 and Q-130 pastes (questions-archive.md:2441, :2522) both run the branch's own `install.sh` from a temp worktree. That one step causes both problems the user named on 2026-10-12.

- **It blocks.** `agent_gate` (install.sh:1188) refuses when it finds any Claude Code process of the uid (pgrep, :1195), any process whose cwd is in the checkout (`procs_in_checkout`, :1166), or any running container labelled `cc-project` (`docker ps --filter label=cc-project`, :1240). It runs at startup (:1344), before the devcontainer copy (:560) and around the host target (:793, :1005). The gate is not scoped to the destination. A run with `CLAUDE_DEVC_CONFIG_DIR` pointing at a second prefix still refuses while any session runs anywhere. Decision 037's Trust model ("no agent may run during an install", Q-058 [2]) is why.
- **It replaces main's config.** `DEST` defaults to `~/.config/claude-devcontainer` and `BIN_DIR` to `~/.local/bin` (install.sh:1310-1311). The install bless-es what it copied (:607) and repoints `~/.local/bin/cc-isolated` and `cc-push` at it (:598, :603). From then on, every project's next launch rebuilds from the branch's config: `check_manifest` passes and `container_config_matches` fails, so the container is recreated (cc-isolated.sh:888-896). That lasts until someone runs `install.sh` from main again, which is the "forgotten test install".
- **What gets installed is old main too, not just the branch.** Both branches are far behind main: Q-125 U2 is 356 commits behind and the egress fix 476. Neither has `host_tool_files` (Q-089, merged 2026-10-14). So installing either one today also rolls back the host-tools trust split, `cc-push`'s self-check and everything else merged since. A forgotten branch install is a rollback of the boundary and host tools, not just "the branch's config". `feat/q125-cc-isolated-sandbox` also conflicts with main in `hooks/live-verify-gate.sh` (`git merge-tree`), and `hooks/` is in the image payload (install.sh:135). The egress branch merges cleanly.
- **The Q-130 paste targets the user's own claude-workflows project.** `cc-isolated ~/claude-workflows` uses `project_id` = sha256 of the path (cc-isolated.sh:372), the same id as the user's everyday claude-workflows sessions. `--probe-only` always runs `devcontainer up --remove-existing-container` (:883) on the container carrying that `--id-label` (:836). So the verify run removes the harness's own running container and shares its `~/.claude` volume (devcontainer.json:78-79). The Q-117 paste does the same to herald's container.

## 2. What already supports side-by-side

- **The config prefix is already a parameter end to end.** install.sh takes `CLAUDE_DEVC_CONFIG_DIR` and `CLAUDE_DEVC_BIN_DIR` (usage, install.sh:33-36; :1310-1311). cc-isolated's `config_dir()` reads the same variable (cc-isolated.sh:68), and `bless_cmd` names it when set (:323). devcontainer.json takes its build context, Dockerfile and (on the Q-125 branch) the seccomp file from `${localEnv:CC_CONFIG_DIR}`, which the launcher sets from `config_dir` (cc-isolated.sh:820). The bats suites already run against a temp prefix (test/cc-isolated-functions.bats:25-31).
- **Main's launcher runs host code only from its own directory.** It sources `cc-exit-scan.sh` and `cc-gitdir.sh` from `CC_ISOLATED_DIR`, its own resolved path (cc-isolated.sh:714-718), after `verify_host_tools` checks them there. It does not source them from `config_dir`. So main's installed launcher run with `CLAUDE_DEVC_CONFIG_DIR=<stage>` takes only the container config (Dockerfile, devcontainer.json, firewall, egress lists, payload) from the stage. No branch code runs on the host.
- **The per-project namespace is the workspace path.** Container id-label, both volumes and the H6 volume stamp all key on `project_id(path)` (cc-isolated.sh:372, :583/:836; devcontainer.json:78-79; probe at cc-isolated.sh:634-647). A verify run on a *different path* (a scratch clone) therefore gets its own container and volumes with no code change. The egress profile is per prefix: `$(config_dir)/projects/<pid>.profile` (cc-isolated.sh:389).
- **The receipt is per prefix.** `verified-live.sha256` sits in `config_dir` (cc-isolated.sh:80, :113). The `Live-verified:` trailer is free text (hooks/live-verify-gate.sh header). The blessed hash covers `claude-home/.manifest`, which stamps `assembled_from=$REPO_ROOT` (install.sh:360). So a hash from any other install path never equals the hash main's post-merge install will show anyway. A verify hash can be cited as "verified in a side-by-side stage of <sha>". main's post-merge install is probed on its first launch regardless, because an unverified blessed config always triggers the probe (cc-isolated.sh:872-877).

## 3. What does not support side-by-side

| Gap | Where | Effect on a second-prefix install |
|---|---|---|
| The agent gate is global | install.sh:1188-1283 | Still refuses while any session runs. A second prefix removes the forgotten-install hazard but not the blocking. |
| The bin link defaults to `~/.local/bin` | install.sh:598-604 | Forgetting `CLAUDE_DEVC_BIN_DIR` repoints main's `cc-isolated` command at the branch's launcher, which still reads main's config dir by default. The hazard comes back in a subtler shape. |
| `config_dir` comes from the environment, not from the launcher's own location | cc-isolated.sh:68 | Running a verify-prefix launcher without the env var acts on main's config. |
| Same workspace path means the same project | cc-isolated.sh:372 | A verify on `~/claude-workflows` or herald recreates that project's real container (see §1). Use a scratch clone. |
| Image naming | devcontainer CLI | **[unverified]** The CLI names the image from the workspace folder (from memory: `vsc-<basename>-<hash>`), so a distinct path should mean a distinct image tag. Check with `docker images` before and after one verify run. |
| Branch host code | the branch's install.sh and cc-isolated.sh | A second-prefix install still runs the branch's (356- or 476-commit-old) install.sh on the host, and launching runs that prefix's cc-isolated.sh. Both are host code from an agent-writable branch. The global gate is what currently guards the review of that code. |

## 4. Inventory: each check, what it needs, and who can provide it

Columns: **S** = a second prefix installed by install.sh (`CLAUDE_DEVC_CONFIG_DIR`/`CLAUDE_DEVC_BIN_DIR`) plus a scratch-clone workspace. **E** = an ephemeral stage: the branch's container config extracted from a commit into a temp dir, launched by *main's* installed cc-isolated with `CLAUDE_DEVC_CONFIG_DIR=<stage>`, no install. **N** = a nested container (docker-in-docker inside a privileged outer container on the same daemon). ✓ provides it without touching main's install · ~ partly, or with a caveat · ✗ cannot.

### Q-117 — the egress fix (`fix/egress-dnsmasq-ipset`; questions-archive.md:2441)

The branch changes only `init-firewall.sh` (+293/-55) plus docs and tests. Everything it changes runs inside the container.

| # | Check | Host resource it needs | S | E | N |
|---|---|---|---|---|---|
| E1 | Get the branch's config built | an install of the branch's config (today: main's prefix, after the global agent gate), or a stage | ~ gate still global | ✓ no install | ~ |
| E2 | Rebuild a container on it | the docker daemon; build-time egress (apt, GitHub releases, the toolchain hosts); `~/.ssh/canary` present for the H1 probe (cc-isolated.sh:823) | ✓ | ✓ | ~ needs a privileged outer container |
| E3 | Project with the `android` profile | a `projects/<pid>.profile` in the prefix (cc-isolated.sh:389); dl.google.com is in `egress/android.txt` only | ✓ register the scratch clone in that prefix | ✓ register it in the stage | ✓ |
| E4 | Firewall marker; 2 dnsmasq instances | NET_ADMIN/NET_RAW (devcontainer.json:58-60); the host kernel's netfilter and ipset support (main already uses ipset); the image's dnsmasq built with ipset (the branch checks this) | ✓ | ✓ | ~ the inner netns sits behind the outer one's |
| E5 | Fetch 1 and fetch 2 return 200 across a pool rotation | real internet egress from the host's network; up to ~45 min of wall time with the container up | ✓ | ✓ | ✓ |
| E6 | 0 `FAIL sni=dl.google.com` lines | in-container proxy log | ✓ | ✓ | ✓ |

No check needs herald itself: the container block is a curl and a log grep. A Claude session isn't needed either, so the block can run through `devcontainer exec` with no `/login`. Under S or E, none of Q-117 needs main's install, herald's container or a closed harness.

### Q-130 — the Q-125 sandbox (`feat/q125-cc-isolated-sandbox`; questions-archive.md:2522; checks in `docs/working/live-check-q125.sh` on the branch)

| # | Check | Host resource it needs | S | E | N |
|---|---|---|---|---|---|
| Q1 | Get a buildable config | a merge of main into the branch first (conflict in `hooks/live-verify-gate.sh`); then an install or a stage | ~ | ✓ stage the merge commit | ~ |
| Q2 | Container starts under `--security-opt seccomp=<file>` | the host docker daemon accepting the custom profile; the path is `${localEnv:CC_CONFIG_DIR}/seccomp-cc-sandbox.json` on the branch, so it resolves into whichever prefix or stage launched it | ✓ | ✓ | ✗ the outer container's seccomp/AppArmor stack changes exactly what is being tested |
| Q3 | bwrap gets user, mount, pid and net namespaces | the **host kernel** (WSL2 6.18) user-namespace support and any host AppArmor; Q-126 probed this on the host 2026-10-07 | ✓ | ✓ | ✗ a privileged outer container is a different kernel-surface context |
| Q4 | Managed settings rendered at build | build only (Dockerfile tail on the branch) | ✓ | ✓ | ✓ |
| Q5 | C1–C4: credential unreadable, settings unwritable, project files unwritable, fsmonitor contained | a Claude Code session, because only Claude's Bash tool is sandboxed (the script says `!` proves nothing); a credential in the project volume | ✓ fresh volume for the scratch clone | ✓ same | ~ |
| Q6 | C3 nested worktrees | `/workspace/.claude/worktrees/*` in the workspace; a fresh scratch clone has none, so it SKIPs | ~ create one in the clone | ~ same | ~ |
| Q7 | C5 network | egress to api.github.com, api.anthropic.com, github.com; example.com denied | ✓ | ✓ | ✓ |
| Q8 | C6 builds (cargo, npm) | registry egress for the clone's profile | ✓ register `rust`/the npm host as needed | ✓ | ✓ |
| Q9 | C10 credential across `/login` | the user at the session doing `/login` (interactive); the credential then sits in the verify volume | ✓ remove the volume afterwards | ✓ same, removed by teardown | ~ |
| Q10 | `gh`/`git push` paths do not prompt (Q-125's own constraint) | a push target and, for `gh`, an exported `GH_TOKEN` | ~ needs a scratch remote | ~ same | ~ |
| Q11 | Merge with `Live-verified: <hash>` | the hash `--list` shows after a passing probe | ✓ per-prefix hash, cited as such | ✓ per-stage hash, cited as such | ~ |

### Q-098 — the global allow list (`feat/wiring-allowlist-b`; questions.md:177)

| # | Check | Host resource it needs | S | E | N |
|---|---|---|---|---|---|
| A1 | The leak list re-run inside the sandbox | Q-125's sandbox *and* the branch's 778-rule `hooks/wiring.json` in the image payload (wired into the volume's settings by `link-claude-home.sh`). So the stage needs a merge of main, Q-125 and wiring-b. wiring-b is 811 commits behind main. | ~ one install of a three-way merge | ✓ stage the three-way merge commit | ~ |
| A2 | The listed commands run unprompted *and* are contained | an interactive session (as Q5) | ✓ | ✓ | ~ |

Q-098's trigger is "Q-125 lands". So in practice, A1 runs after Q-125 merges, as a two-way merge of main and wiring-b.

### Q-125 — its own merge constraint (questions.md:201-216)

Q-125's merge gate is exactly Q-130's run (Q1–Q11). U1 (`feat/q125a-seccomp`) is contained in U2, so verifying U2 covers both.

## 5. Host resources, summarised

| Host resource | Needed by | Shared with main? | Side-by-side? |
|---|---|---|---|
| docker daemon | all | yes, one daemon | yes: distinct containers by id-label, volumes by project id, images by path [unverified] |
| host kernel (userns, netfilter, ipset) | Q2, Q3, E4 | yes, unavoidably | yes: read-only use; nothing is reconfigured on the host |
| host firewall | none | — | the firewall runs in each container's netns; no check touches the host's |
| internet egress, wall time | E5, Q7, Q8 | yes | yes |
| installed config prefix `~/.config/claude-devcontainer` | status-quo pastes only | — | **not needed** by S (second prefix) or E (stage) |
| `~/.local/bin/cc-isolated` link | status quo; S if `CLAUDE_DEVC_BIN_DIR` is forgotten | — | E never writes it |
| host `~/.claude` (install target 2) | none (both pastes say answer N) | — | not needed |
| running sessions / the agent gate | install.sh only | — | S still hits it; E runs no install, so no gate |
| the project's container and volumes | status quo (same path) | yes, collides | a scratch-clone path gives fresh ones |
| a Claude login | Q5, Q9, A2 | no (per-volume) | fresh in the verify volume; deleted after |
| `~/.ssh/canary` | the probe | read-only | yes |
| registries at build | all | yes | yes; base layers likely cache-shared with main's image |

## 6. Findings

1. **No check needs main's install.** Every check in Q-117, Q-130, Q-098 and Q-125 needs the docker daemon, the host kernel, egress and (for Q-125/Q-098) an interactive login. Each of those can be shared read-only or provisioned fresh per verify. The only reasons the pastes touch main's prefix are install.sh's defaults and the habit of verifying on the real project path.
2. **A second prefix (S) fixes the hazard but not the blocking.** install.sh's gate is global, so S still needs every session stopped for the install moment. It also still runs the branch's old host code, and it has two env-var traps (bin dir, config dir).
3. **An ephemeral stage launched by main's launcher (E) needs no install at all.** So no gate runs, nothing is left for later sessions to pick up, and no branch code runs on the host. The branch's `devcontainer.json` does reach the docker daemon (runArgs, mounts), so that file needs a review or a mechanical refusal before the build. E also cannot exercise a branch's changes to host code (`cc-isolated.sh`, `install.sh`, host tools). Those stay bats-tested and `Host-tool-tested:`, and are first exercised by main's post-merge install.
4. **A nested container (N) is the wrong tool for the two kernel-facing checks** (Q2, Q3), which are Q-125's whole open question. It also needs a privileged outer container, a bigger hole than the one it avoids.
5. **Pre-existing hazards in the status-quo pastes, worth knowing whatever is chosen.** They recreate the real project's container (§1), and they install a config hundreds of commits behind main. Q-125's branch must merge main before any verify.
6. **The stage should be a merge commit, not the branch tip.** Verifying `git merge-tree --write-tree main <branch>` checks what would land. That is also the only way to verify Q-098 (a multi-branch payload). A merge with conflicts (Q-125 today) has to be resolved on the branch first.

## 7. Unverified, for the next unit's host check

- The devcontainer CLI's image tag depends on the workspace path, so a scratch clone does not retag main's image.
- `devcontainer read-configuration --workspace-folder <ws> --override-config <stage>/devcontainer.json` prints the resolved runArgs and mounts as JSON (for a mechanical refusal of `--privileged`, host mounts and the like).
- Main's installed cc-isolated run with `CLAUDE_DEVC_CONFIG_DIR=<stage>` builds, probes and records `verified-live.sha256` in the stage, given a stage holding the PAYLOAD items plus an assembled `claude-home/` (Dockerfile:500).
- `docker volume rm` / `docker image rm` after the run leaves `docker ps -a`, `docker volume ls` and `docker images` as they were before it.
