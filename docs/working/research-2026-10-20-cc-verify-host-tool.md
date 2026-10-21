# Research, design and plan: the cc-verify host tool

- **Brief**: `docs/working/briefs/2026-10-20-cc-verify-host-tool.md` (at c1a28e20)
- **Branch**: `feat/cc-verify-host-tool`, dispatched at c1a28e20
- **Workflow**: research-plan-implement, no plan gate; design choices through divergent design seeded with `docs/constraints.md` (H1-H4, S1-S11) and the DD's own H0-H6
- **Inputs**: `docs/working/dd-branch-verify-without-install.md` (candidate [5], "Bypass and safety pre-mortem", "Next unit"), `docs/working/spike-cc-verify-q117.md` (the hand version, not yet run on a host: Q-169 is still open), Q-165 [1] (with "the verify tool needs to take the config it verifies as an argument"), Q-166 [2]

## 1. What the code says (research)

- **The launcher on a stage.** `cc-isolated.sh` reads every config path through `config_dir()` (`CLAUDE_DEVC_CONFIG_DIR`, :68-70), and loads host code only from its own resolved directory: `source "$CC_ISOLATED_DIR/cc-exit-scan.sh"` (:749), which in turn sources `cc-gitdir.sh` from its own directory (`cc-exit-scan.sh:12`). These are the only `source` lines in the three files. So main's installed launcher run with `CLAUDE_DEVC_CONFIG_DIR=<stage>` executes no staged file; the stage's `cc-isolated.sh` is hashed (it is an enforcement file) but never run.
- **What the launcher writes into the stage.** `--register WS --profile P` writes `projects/<pid>.profile`, then `bless_manifest` writes `manifest.sha256` and `host-tools.sha256` (:281-319). `compute_host_tools_manifest` fails if a `host_tool_files` entry is missing, so the stage must hold the host tools at bless time. `--probe-only` runs `check_manifest` (enforcement files only, :332-350), `devcontainer up --remove-existing-container`, `probe_boundary`, and on a pass writes `verified-live.sha256` (:113-115). Nothing after the bless reads the stage's host tools, so they can be removed then (pre-mortem 5).
- **Identity.** `project_id` is `printf %s <toplevel> | sha256sum | cut -c1-12` (:372-374); `CC_PROJECT_NAME` is the workspace's basename (:880), which becomes the devcontainer's display name (`devcontainer.json:22`). A workspace named `VERIFY-<tree8>` therefore names the container `cc-isolated (VERIFY-<tree8>)`, and its container label and `cc-<pid>-*` volumes are keyed on the scratch path, never on a real project's.
- **What reaches the host from `devcontainer.json`.** `initializeCommand` runs on the host; `build` (dockerfile, context, args, options) reaches `docker build`; `runArgs`, `mounts`, `workspaceMount` reach `docker run`; any `${localEnv:NAME}` copies a host variable into the container. Main's copy has runArgs `--cap-add=NET_ADMIN`, `--cap-add=NET_RAW` and two `cc-${localEnv:CC_PROJECT_ID}-*` volume mounts. `feat/q125-cc-isolated-sandbox` adds `--security-opt` + `seccomp=${localEnv:CC_CONFIG_DIR}/seccomp-cc-sandbox.json`, and nothing else that reaches docker.
- **Installed host tools (row 71).** `install.sh` copies `PAYLOAD` (:110) to the config dir, `chmod +x`es the scripts (:596) and links `cc-isolated` and `cc-push` into the bin dir (:598-604). A test pins `PAYLOAD` ⊆ `enforcement_files` ∪ `host_tool_files` (`test/cc-isolated-functions.bats:1035`), and another pins the gate's `host_tools` regex to `host_tool_files` in both directions (`test/hooks/live-verify-gate.bats:343-368`). So "a host tool under row 71" means: in `PAYLOAD`, in `host_tool_files`, in the gate's `host_tools` regex, and blessed into `host-tools.sha256`.
- **Host dependencies.** No host tool uses python3 or jq today. `git merge-tree --write-tree` needs git >= 2.38 (sandbox: 2.39.5).

## 2. Design choices (divergent design)

### D1: how the tool reaches the host and runs

Motive (S5): the user chose a reusable tool (Q-165 [1]) over the paste ([3]); every boundary merge under decision 015's amendment needs one run.

| # | Option | H1 (gate code from a copy the change cannot edit) | S3 (reuse) | S10 (attention) | Brief |
|---|---|---|---|---|---|
| A | Installed host tool: in `PAYLOAD` and `host_tool_files`, linked as `cc-verify`, gated by `Host-tool-tested:`; checks itself against `host-tools.sha256` and main's launcher against `manifest.sha256` before running | ✓ installed copy | ✓ installer, bless, trailer, bin link | ✓ one command | ✓ names `host_tool_files` |
| B | Run from the checkout (`~/claude-workflows/devcontainer-config/cc-verify.sh`) | ✗ an agent-writable file runs on the host with docker | ✓ | ✓ | ~ |
| C | Hash-checked paste from a commit, like the spike | ~ (needs the hash step each time) | ✗ (second distribution path) | ✗ a recurring host chore | ✗ |
| D | Installed but not hashed | ✗ breaks row 71 and the PAYLOAD pin | ✗ | ✓ | ✗ |
| E | `cc-isolated --verify` | ✓ | ✓ | ✓ | ✗ (Q-165 chose [1]) |

**Path A: [A] dominates** (B, D fail hard lines; C is dominated on S3/S10; E was declined by the user). Cost: a one-line `host_tool_files` entry in `cc-isolated.sh` and a zero-growth edit of `install.sh`'s link step (S8). The brief's out-of-scope line ("any change to cc-isolated.sh beyond what the self-check needs to read") is read as barring launcher behaviour, since its own acceptance criterion names `host_tool_files`, which lives in `cc-isolated.sh` (confidence medium; recorded in the commit's Notes).

### D2: how the `devcontainer.json` check reads JSONC (pre-mortem 3)

| # | Option | Fidelity | Dependency |
|---|---|---|---|
| A | python3 stdlib: strip `//`, `/* */` outside strings and trailing commas, `json.loads`, then structural rules | ✓ structural | python3 on the host (S8's allowed stack); preflight refuses loudly without it (H2) |
| B | `devcontainer read-configuration` | ✓ resolved view | unverified output shape (research §7); a test would need the CLI |
| C | whole-file pin against main's copy (the spike's rule) | ✓ but refuses Q-125's legitimate runArgs change | none |
| D | line grep | ✗ easy to fool (DD) | none |

**Path A: [A]**; [C] would refuse the very branch (Q-125) the tool exists to verify, [B] cannot be tested hermetically (H3), [D] fails H2.

### D3: the check block

The check is a file argument (`--check FILE`), read once at start (so a later edit of the file changes nothing), run as `bash -c` in the container with stdin `/dev/null`, its output relayed with control bytes stripped and indented under `  | ` so it cannot forge the tool's own `RESULT`/`CHECK` lines. Its exit status is the verdict. An interactive session (DD S4, Q-130's `/login`) is **not** in this unit: it needs a terminal through `devcontainer exec`, which defeats the relay, and the clone-commit guard of pre-mortem 1. Recorded below as a follow-up, not built.

## 3. Interface

```
cc-verify [--profile NAME[,NAME...]] --check FILE REPO BRANCH
cc-verify --clean
cc-verify --help
```

- `REPO` is the host checkout to read objects from; `BRANCH` a branch name or commit in it. The config verified is the `devcontainer-config/` of `git merge-tree --write-tree main BRANCH` (Q-165's note: an argument, never the checkout's working tree).
- `--profile` defaults to `base`. `CC_VERIFY_ROOT` overrides `~/cc-verify`.
- Exit (row 58): 0 pass with a clean teardown; 1 an error, a refusal, a declined prompt or an incomplete teardown; 2 bad usage; 3 the check block failed.
- Lines of its own: `ERROR:`/`NOTE:` prefixes as the siblings use; `CHECK <what>: ok|FAIL`; `RESULT cc-verify pass|fail tree=<id> config=<hash>`; on a pass, the trailer to copy, `Live-verified: <hash> — cc-verify of tree <id>` (Q-166 [2]: Q-117/Q-125 still close only after main's first post-merge probe).

## 4. Plan

**Split (decision log row 62).** Built whole, the change counted 534 code lines outside `docs/` (script 320, bats 186, wiring 28), over the 400 cap, and the brief says to split past it. Two stacked units on this one branch, merged in order, each with its own review-fix loop:

- **Unit 1 (lower): the tool's core, not installed.** `cc-verify.sh` without the hardening of pre-mortem 3-5 (the run file, `--clean`, merge-tree, staging, the diff and y/N, the scratch workspace, register, probe, the check, the verdict, teardown, the self-hash and `CLAUDECODE` refusals) and its bats cases. Nothing installs or links it, so it cannot run on a host before unit 2 lands (S6 is met by unit 2 in the same merge).
- **Unit 2 (upper): hardening, wiring, docs.** The JSONC rules, the stage hash, the launcher self-check, the post-create inspect, and their cases; the row-71 wiring (`PAYLOAD`, `host_tool_files`, the bin link, the gate regex, fixtures); the guide section; the brief's Status.

Steps:

1. `devcontainer-config/cc-verify.sh` (~320 lines): preflight (refusals, self-check), run dir and record, merge-tree, stage from the merge tree's own `PAYLOAD`/`CLAUDE_HOME_SRC`, `devcontainer.json` rules plus diff and y/N, stage hash, scratch workspace at the merge commit, register, host-tool removal, probe, post-create checks, check block, verdict, teardown and `--clean`.
2. Wiring as a row-71 host tool: `PAYLOAD`, `chmod`, bin link (`install.sh`, no net growth); `host_tool_files` (+1 line); the gate's `host_tools` regex; fixtures and pins in `test/cc-isolated-functions.bats`, `test/install-host.bats`, `test/hooks/live-verify-gate.bats`.
3. `test/cc-verify.bats` (stubbed `docker`, `devcontainer`, `claude`; real local git on fixture repos; no network): one case or more per pre-mortem mitigation (§5).
4. Docs: a "Verify a branch without installing it: cc-verify" section in `guides/cc-isolated-usage.md`; the DD's "Next unit" pointing at the tool.

## 5. Pre-mortem and bypass families (enforcement-file plan, CLAUDE.md rule)

The DD's table is the start; each row names its mitigation in this unit and its test.

| # | Bypass family / failure story | Mitigation here | Test |
|---|---|---|---|
| 1 | Forgotten verify session mistaken for a real one | workspace `VERIFY-<tree8>` (display name), banner at start and at exit, everything torn down at exit. The clone-commit guard is a **residual** in this unit: there is no interactive mode, and a check block's commits are discarded by design | naming and banner |
| 2 | Crash leftovers holding a credential | run dir with a `record` (tree8) written before any docker object exists; a new run refuses while any `record` exists; `--clean` recomputes the project id from the run dir's own path, so a planted record can only name a `VERIFY-` project inside it | run file refusal; `--clean` |
| 3 | Host execution or container privilege via `devcontainer.json` (`initializeCommand`, `build`, `runArgs`, `mounts`, `workspaceMount`, `features`, `${localEnv:…}`) | structural JSONC check: top-level keys ⊆ main's; every host-reaching key equal to main's; runArgs allowlist; mounts ⊆ main's; `localEnv` names ⊆ main's; then the diff of `devcontainer.json` and `Dockerfile` and y/N. After create, `docker inspect`: not privileged, CapAdd ⊆ {NET_ADMIN, NET_RAW} | key, runArgs, mounts, localEnv refusals; diff shown; `n` declines |
| 3b | Base image's `devcontainer.metadata` label adds privileges | the Dockerfile diff is in the y/N review; the post-create inspect is a detector (the container has started by then) | post-create inspect refusal |
| 4 | Stage swapped between review and build | one hash over the stage's build inputs (PAYLOAD minus host tools) at review, after the bless, and after the container is created; a mismatch refuses the verdict. Residual: swap-and-revert inside the window (decision 037's accepted residual) | hash mismatch after create |
| 5 | Launcher change makes the stage host code | self-check at start: every `source`/`.` line in main's launcher and the files it sources must load from the file's own directory; refuse otherwise. The stage's host tools are deleted right after the bless. A bats pin runs the self-check on the real launcher. Residual: bash spellings grep cannot see (`eval`, a computed `source`), as row 71's Q-147 | self-check refusal on a mutated copy; pin on the real one; stage host tools gone |
| 6 | Verdict on a stale tree | stage only `merge-tree --write-tree main BRANCH`; refuse on conflict; the workspace is checked out at a commit of that tree; the tree id is in the RESULT line and the trailer | conflict refusal; tree id in output |
| 7 | Agent-run verify | refuse when `CLAUDECODE` is set (install.sh's target-2 rule). Residual: stops accidents only; an agent with host docker already has host root | CLAUDECODE refusal |
| 8 | Tampered installed tool | cc-verify checks itself against `host-tools.sha256` and main's launcher against `manifest.sha256` before anything else; refuses from a repo checkout (no manifest) | self-hash refusal |
| 9 | Host credentials forwarded into branch code | `GH_TOKEN` and `OPENROUTER_API_KEY` unset before the launcher runs (the spike's rule) | covered by the localEnv rule's test |
| 10 | Collision with a real project's image | image removed only when absent from the run's before-snapshot and unused, never `-f`. Unverified until the first host run (§6) | image kept when pre-existing |

Not covered (residuals, as the spike's): a same-uid writer of `~/cc-verify` racing the extraction or editing the stage during the build (add `~/cc-verify` to agents' `denyWrite`, guide says so; S1: gates defend against honest slips, not a hostile same-uid loop); the verdict is attested by the code under test (the branch's firewall runs as root before the check); `main` is resolved by name from the checkout's `.git`.

## 6. What the first host run must show (the spike's open claims)

None of these can be settled in the sandbox (no docker). The guide lists them for the first run's paste-back:

1. The devcontainer CLI's image for `VERIFY-<tree8>` is a new image, not a retag of main's (spike "Not verified" 1, research §7, the image-collision item): the `CHECK verify image new` line and teardown's image line show it.
2. Main's launcher on a stage builds, probes and records `verified-live.sha256` (research §7): `CHECK verified-live receipt` shows it.
3. `devcontainer exec` with the launcher's five exported variables reaches the container and passes the block's exit status back (spike 3, 4): run once with a check file that is just `exit 3`; expect `RESULT cc-verify fail` and exit 3.
4. `docker rm`/`volume rm`/`image rm` leave the before-state (research §7): the `CHECK … gone` lines.
5. git >= 2.38 on the host (spike 5): a refusal names it otherwise.
6. Root-owned files the container writes into the workspace can make teardown fail (spike 11): an incomplete teardown names the path.
7. `devcontainer read-configuration` (research §7): not used; D2 [A] replaces it.
8. Whether the CLI layers a `-uid` image over the `vsc-…` build image (remoteUser `node` on a host uid other than 1000). Teardown removes only the container's own image, so a base `vsc-verify-<tree8>…` image would be left: after the first run, `docker images | grep -i verify` must print nothing (unit-1 review F8).

The two units land together (one merge of the branch tip): unit 1 alone has no JSONC refusal, so its only defence against a branch's `initializeCommand` is the y/N diff (unit-1 review F1). It is not installed or linked until unit 2.

## 7. Follow-ups not built here

- An interactive mode (Q-130's `/login`), with the DD's clone-commit guard.
- A multi-branch merge (Q-098), by merging the branches into one integration branch first.
