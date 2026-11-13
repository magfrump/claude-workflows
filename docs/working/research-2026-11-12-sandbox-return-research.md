# Research: what the Bash sandbox needs before it comes back

Brief: `docs/working/briefs/2026-11-12-sandbox-return-research.md` (at 772c19a4)
Branch: `docs/sandbox-return-research`, cut at 54e6d20e
Date: 2026-11-12

Failure-pattern grep: FP-011, FP-014, FP-047, FP-058 (keywords sandbox, bwrap, worktree, rename, credential, bind mount). FP-047 (a poisoned helper persists to a later unsandboxed run) is requirement 2's family: a file a sandboxed command writes, consumed later by an unsandboxed one. FP-058 (a bwrap failure dropped silently) is why every option below must fail loudly. FP-011/FP-014 (half-made and stale worktree entries) bear on any helper that adds worktrees outside the sandbox.

## What this doc settles

Q-125 put Claude Code's Bash sandbox into cc-isolated. Main rolled it back at 7caea26d after the owner's answer to Q-277 ([3]: release without the sandbox; it comes back only when agents can create worktrees under it). Three requirements block the return:

1. **Worktrees**: under the sandbox a `git worktree add` fails ("Read-only file system").
2. **Nested worktree paths**: the live check's `C3-nested-settings-1` and `C3-nested-gitfile-1` failed.
3. **The credential after a refresh**: the live check's `X4-cred-across-rename` failed.

Every fact below carries its source: **[observed]** (seen here: a command, a file, or a string in the installed Claude Code binary), **[docs]** (read in documentation or issue reports through WebSearch; WebFetch has no egress here, so these are unverified), or **[inferred]**. Facts nobody can settle without a host run are listed under "Thin facts", each with the command that would settle it.

The binary read here is Claude Code **2.1.323** (`claude --version`), the version installed in this container today. The Q-125 research read 2.1.293. Strings from a minified binary show what code exists, not always which path runs, so binary readings are marked [observed, binary] and their consequences [inferred].

## The sandbox as it was (7caea26d^)

`git show 7caea26d^:devcontainer-config/managed-settings.json` (rendered at build time, root-owned, into `/etc/claude-code/managed-settings.json`):

- l.34-38: `enabled: true`, `failIfUnavailable: true`, `allowUnsandboxedCommands: false`, `autoAllowBashIfSandboxed: false`, `enableWeakerNestedSandbox: false`.
- l.47: `denyRead: ["~/.claude/.credentials.json"]`, one file.
- l.48-59: `denyWrite` is all literal paths. The project entries name `/workspace` only: `/workspace/.claude/settings.json`, `/workspace/.claude/settings.local.json`, `/workspace/.mcp.json`, `/workspace/.git/config`, `/workspace/.git/hooks`.
- l.60-69: `allowWrite` covers toolchain caches and `/tmp`. Nothing names `/workspace/.git` or any worktree.
- No `excludedCommands`.

The comment block (l.13-15) states the rule this design keeps: "`!` commands and hooks still run unsandboxed, which is why nothing they execute or trust may be sandbox-writable".

The plan (`docs/working/plan-q125-cc-isolated-sandbox.md`) left the two nested cases and the rename case open before the live run:
- l.87: "**Unknown**: nested `.claude/worktrees/*/.claude/settings*.json` and a worktree's `.git` pointer file / `commondir`. Live step 6 tries each".
- l.92: "Credential replaced by rename during a long-running sandboxed command, so the new file sits under no mask | **unknown**".

The check that found the gaps:
- `docs/working/q125-verify-check.sh` l.83-88 adds a worktree at `/workspace/.claude/worktrees/q125-probe` **before** `claude -p` starts, outside the sandbox. That is why no line ever ran a sandboxed `git worktree add`, and why the worktree breakage reached main.
- l.151-155 (X4): one sandboxed command reads the credential in a loop while the host side replaces it by rename every half second.
- `docs/working/live-check-q125.sh` l.100-105: the C3 nested checks walk `/workspace/.claude/worktrees/*/` only.

The results are in Q-273's archived entry (`docs/working/questions-archive.md`, the 2026-11-11 paragraph): `C3-nested-settings-1 FAIL (could create /workspace/.claude/worktrees/q125-probe/.claude)`, `C3-nested-gitfile-1 FAIL (writable: …/q125-probe/.git)`, `X4-cred-across-rename FAIL (read after a rename)`. Every other required line passed.

## Requirement 1: worktrees

### Facts

| # | Fact | Source |
|---|---|---|
| F1.1 | Claude Code puts the repository's `.git/worktrees` in the sandbox's internal write-deny list (`denyWithinAllow`). Its own text: "The repository's `.git/worktrees` is read-only in the sandbox, apart from this session's own worktrees, so `git worktree add`, `move` and `remove`, and renaming a branch that another worktree has checked out, fail there halfway. Run them outside the sandbox". The same list holds `.git/hooks`, `.git/config`, `config.worktree`, `commondir`, `.git/modules`, `.git/info/exclude` and `.gitmodules`. | [observed, binary] |
| F1.2 | That deny is switched by a server-side feature flag ("a feature-flag change to the write block on .git/worktrees"; `worktreesDenyApplied`). Neither the user nor this repo controls it. | [observed, binary] |
| F1.3 | An `allowWrite` entry cannot lift a protected path; writes to `.git/hooks` and `.git/config` stay denied whatever `allowWrite` says. When the session's working directory is a linked worktree, the main repository's shared `.git` is writable except `hooks/` and `config`. | [docs] code.claude.com sandboxing and settings-reference pages via search; issues #61596, #97839 |
| F1.4 | `git worktree add` writes `.git/worktrees/<name>/{HEAD,ORIG_HEAD,commondir,gitdir,index,logs/HEAD}`, plus `refs/heads/<branch>` and its reflog, plus the new tree and its `.git` pointer file (`gitdir: <common>/.git/worktrees/<name>`). It writes there **wherever the tree lives**: a worktree added at a path outside the repository wrote `.git/worktrees/o/` just the same. It never wrote `.git/config`. `lock` adds `.git/worktrees/<name>/locked`; `remove` and `prune` delete the admin dir. | [observed] git 2.39.5, scratch repo in the scratchpad |
| F1.5 | **A commit inside a linked worktree also writes there**: `git add` and `git commit` in the worktree changed `.git/worktrees/w1/{index,COMMIT_EDITMSG,logs/HEAD}`. So `.git/worktrees` being read-only can break all git work in a worktree, not only its creation. Unless Claude Code's per-session exception (F1.1, "apart from this session's own worktrees") covers worktrees the harness made, a build loop could not commit in its worktree. Nobody has observed this either way: the live check never committed in a worktree. | [observed] for git's writes; [inferred] for the sandbox outcome |
| F1.6 | The harness's worktree operations: `skills/dev-cycle/SKILL.md` l.315 (`git -C MAIN_WT worktree add` for WT), l.377 (HC), l.656 (GT), l.322/384 (remove), l.408 (`list`, `prune`); `scripts/build-loop.sh` l.1778 (`lock`/`unlock`), l.1786 (`add --lock`), l.1826 (`remove`, `--free-worktrees`); `scripts/lib/si-functions.sh` l.140-145; `scripts/self-improvement.sh` l.159; `workflows/parallel-worktrees.md` l.39-43 (the by-hand fallback, in any repository). | [observed] |
| F1.7 | Every gate call runs as one top-level line, `cd WT && bash /opt/claude-workflows/scripts/d6.sh SCRIPT ARG...` (`skills/dev-cycle/SKILL.md` l.37-40), from root-owned image code. `build-loop.sh` sources only its own image libraries and reads branch content through git objects; it runs no branch script or test (grep for `bats`, `source`, `health-check`: only `$READ_LIB` and `$SCRIPT_DIR/lib/migrations.sh`). | [observed] |
| F1.8 | Under managed `allowUnsandboxedCommands: false`, `dangerouslyDisableSandbox` is ignored, but commands in `excludedCommands` still run outside the sandbox. The plan's bypass table (l.91) already treats user-tier `excludedCommands` as honoured under the managed file. The match syntax (prefix or glob) is not documented in anything found. | [docs] sandboxing page; makandracards example; [observed] plan l.91 |
| F1.9 | Exclusion is decided on the Bash tool's command line. A script's own children inherit the sandbox, so `build-loop.sh`'s internal `git worktree add` stays sandboxed unless the `build-loop.sh` line itself is excluded. | [inferred] (bwrap wraps the whole process tree) |
| F1.10 | A planted `.git` pointer does not fool `git worktree remove`: with the pointer rewritten to a gitdir whose config sets `core.fsmonitor`, `remove` refused ("does not point back to '.git/worktrees/w2'") and the monitor never ran. | [observed] git 2.39.5, scratch repo |

### Divergent design

**Diagnosis.** The sandbox makes the common git dir's worktree records read-only, on purpose, behind a flag nobody here controls (F1.1, F1.2). The records hold per-worktree state that git writes on add, lock, remove and, per F1.5, on every commit inside a worktree. So the real requirement is: **agents create worktrees and do git work in them, while nothing a sandboxed command writes can steer a later unsandboxed git**. Seeded constraints: H1 (gate code runs from a copy the change cannot edit), H2 (fail closed and loudly), H3 (hermetic tests), S1 (proportionate; gates defend against honest slips), S3 (reuse the existing mechanism), S8 (small units, one revert), S10 (no host chores).

| Candidate | What it is | Verdict |
|---|---|---|
| **1A** `allowWrite` on `/workspace/.git/worktrees` | One managed line | **Eliminated.** `allowWrite` cannot lift a protected path (F1.3), and the deny is flag-controlled (F1.2), so the line could be present but inert (H2). Even if it worked, it would make `commondir` and `gitdir` sandbox-writable. Those files redirect a later unsandboxed git to any config, which is requirement 2's FP-047 family, widened. |
| **1B** agent worktrees outside `.git`'s parent | Move `wt-*` elsewhere | **Eliminated.** git writes the admin dir in the common `.git` wherever the tree lives (F1.4, observed). |
| **1B′** separate clones instead of worktrees | An unsandboxed helper makes `git clone --shared` copies; landing fetches back, as cc-push does | Viable. Commits stay sandboxed in the clone's own `.git` (assuming only nested `hooks`/`config` are denied there: [inferred]). Cost: it rewrites dispatch, status, free and land in `build-loop.sh` and the dev-cycle skill, so several units, against S8 and the brief's one-unit goal. A clone's `.git/config` sits inside a sandbox-writable tree, so requirement 2 gets wider. |
| **1C** worktree operations outside the sandbox, through Claude Code's own `excludedCommands` | Two managed entries: `git worktree` (any repository, the by-hand fallback) and the d6 gate line for `build-loop.sh` | **Tentative pick.** Uses Claude Code's mechanism (S3). It is a few managed lines that one revert undoes (S8) and needs no host step (S10). The unsandboxed parts are root-owned gate code (H1, F1.7) and `git worktree` itself. `remove` refuses a redirected pointer (F1.10), and `add`, `lock` and `prune` read only the main repo's admin dir [inferred], so the excluded commands do not consume the files requirement 2 leaves writable. |
| **1C′** as 1C, through a root-owned `cc-worktree` helper that confines paths to `.claude/wt-*` and `.claude/worktrees/*` | One excluded helper instead of raw `git worktree` | Viable, ranked below 1C. It confines an unsandboxed checkout's target path, but S1 weighs that against what is already allowed: the Edit and Write tools are not sandboxed and can already write those paths. It adds new boundary code (about 60-80 lines) and a second path for one job (S3). |
| **1C″** the harness route: Agent `isolation: "worktree"` / `EnterWorktree`, optionally a `WorktreeCreate` hook | Claude Code makes the worktrees, so the "session's own" exception covers them | **Not viable now.** Isolation is refused in this container with no sandbox installed (see F-009 below), and whether the exception reaches a subagent is unknown. Revisit once F-009 is understood. |
| **1D** `allowUnsandboxedCommands: true` plus allow rules for git | The model opts out per call | **Eliminated.** It reopens the model-chosen escape for every command an allow rule matches, which removes the premise watch Q-098 (the global allowlist) waits on. |

**Path C (tentative pick: 1C; tiebreaker: S8 and S3).** 1C and 1B′ both survive the hard lines. 1C is a few managed lines with residual "`git worktree` and the gate run outside the sandbox". 1B′ keeps everything sandboxed but is a multi-unit rewrite of gate code. Two facts can still change the pick (U1, U2 under "Thin facts"):

- If a sandboxed commit inside a harness-made worktree is refused (U1), 1C must also exclude git's write subcommands in worktrees. That is a much wider residual, and then 1B′ is probably the better design.
- If `excludedCommands` does not match these command lines (U2), 1C′'s single helper name is the fallback.

The residual is the owner's call (question 1 below).

## Requirement 2: nested worktree paths

### Facts

| # | Fact | Source |
|---|---|---|
| F2.1 | Under `/workspace/.claude/worktrees/q125-probe/`, a sandboxed command could create `.claude/` and append to the `.git` pointer file. | [observed] Q-273 live run |
| F2.2 | On Linux, write rules that contain a glob are dropped (`[Sandbox] Skipping glob write pattern on Linux: …`) unless the pattern has a literal form. Read-deny globs are expanded to the paths that exist when the command starts. Claude Code's own doctor text: "On Linux, glob patterns in Edit/Read rules will be ignored". So a pattern `denyWrite` cannot name every nested worktree, and it cannot stop the **creation** of a `.claude/` that does not exist yet. | [observed, binary]; [docs] issues #92684, #74081 |
| F2.3 | The harness's worktrees live at `/workspace/.claude/wt-*` (dev-cycle WT/HC/GT, build-loop's default `--dir`, the by-hand fallback) **and** at `/workspace/.claude/worktrees/*` (Claude Code's own location). The live check's C3 loop walks only `.claude/worktrees/*/` (`live-check-q125.sh` l.100), so it never tested the `wt-*` worktrees this harness actually uses. | [observed] |
| F2.4 | The managed file is rendered at image build and is root-owned, so its literal list cannot name a worktree made at run time. | [observed] 7caea26d^ managed-settings.json l.2-7 |
| F2.5 | Claude Code's built-in write protections (`.git/hooks`, `.git/config`, shell rc files, `.mcp.json`, `.vscode`/`.idea`, `.claude/commands`, `.claude/agents`) are applied at the project root. A nested `.claude/settings.json` was writable in the live run. | [observed, binary]; F2.1 |
| F2.6 | Claude's Edit and Write tools are not sandboxed. This repo's permission denies cover `~/.claude` files only (`hooks/wiring.json`: `Edit(/{{CLAUDE_DIR}}/settings*.json)` and the like). The repo's shell guard even tells agents to use Edit/Write for "a project's or worktree's own .claude/ files" (seen in this session's hook refusal). So an agent can already write a worktree's `.claude/settings.json` or `.git` file without Bash. | [observed] |
| F2.7 | What reads those files later: (a) the `.git` pointer is followed by any git run with that worktree as its working directory, so a pointer to a planted gitdir runs that gitdir's `core.fsmonitor`, filters or hooks for whoever runs git there; (b) `.claude/settings*.json` is loaded by a Claude Code session or `claude -p` whose project is that worktree (`self-improvement.sh` runs task work in its worktrees), and its hooks, `statusLine` and `env` run outside any sandbox. `git worktree remove` is not fooled (F1.10). | [inferred] (a, b); [observed] F1.10 |
| F2.8 | The host-side exit scan (`devcontainer-config/cc-exit-scan.sh`, header l.49-99) already walks every linked worktree's `.git` entry and its git dir on session exit, as a tripwire for the host. | [observed] |
| F2.9 | Managed settings can neutralise some of what a nested settings file does: `allowManagedHooksOnly`, `allowManagedPermissionRulesOnly` and `allowManagedMcpServersOnly` exist in 2.1.323. They do not cover `env`, `statusLine` or helper keys, nor the `.git` side. | [observed, binary] |

### Divergent design

**Diagnosis.** Worktrees must be writable to sandboxed commands, because that is where loops work. Two files in each can steer later code outside the sandbox. Linux gives no pattern deny (F2.2), and the managed list is fixed at build (F2.4). Moreover, the same writes are open to the unsandboxed Edit/Write tools (F2.6). By S1 ("do not add a restriction whose bypass is already allowed"; gates defend against honest slips), a Bash-only deny would remove little real risk.

| Candidate | Verdict |
|---|---|
| **2A** pattern deny (`/workspace/.claude/*/.git`, `…/*/.claude`) | **Eliminated** on Linux: write globs are skipped (F2.2). The rule would be present but inert (H2). |
| **2B** worktrees at fixed, literal slot paths (`/workspace/.claude/wt/slot-1..N`) named in the managed list | Viable but costly. It renames every worktree path the gate parses (F1.6), against S8. Literal denies of missing paths leave 0-byte placeholder files that block `git worktree add` into the slot ([docs] issues #54232, #81602; [observed, binary] text "A 0-byte one belongs to the sandbox"). It is still bypassed by Edit/Write (F2.6), so S1 says do not add it. |
| **2C** accepted residual, with the exit scan as the `.git`-side check | **Tentative pick.** No new mechanism. The `.git` side is already tripwired for the host (F2.8), and 1C's unsandboxed commands do not follow a planted pointer (F1.10). The `.claude/` side is a residual equal to what Edit/Write allow today. The live check's C3-nested lines become INFO lines that record the residual, and the walk extends to `.claude/wt-*`. |
| **2D** neutralise instead of deny: managed `allowManagedHooksOnly` and its siblings | Partial (F2.9). It also means moving the harness's own hooks from `hooks/wiring.json` into the managed file, a large change for a partial cover. Noted for a later unit, not this return. |
| **2E** root-owned pins: a sudo helper makes each new worktree's `.git` and `.claude/` root-owned | Viable, but it adds a sudo rule and a root helper (a new trust regime, S3). It breaks repositories that track `.claude/` files. A sandboxed rename of the worktree's parent directory gets around it anyway. |

**Path C (tentative pick: 2C; tiebreaker: S1, since the bypass is already allowed through Edit/Write).** It is an accepted residual, so it is the owner's call (question 2).

### How 1 and 2 fit

1C takes worktree administration, and only that, out of the sandbox. 2C leaves the worktree's contents sandbox-writable, as work needs. The two meet at one point: the unsandboxed side must never act on a file the sandboxed side can write. That holds for `git worktree remove` (F1.10). For `add`, `lock`, `unlock` and `prune` it is [inferred] from where they read (the main repo's admin dir, which stays read-only to the sandbox, F1.1). The gate's own git calls run from the main checkout or with `GIT_DIR` set (F1.7). If U1 shows that commits in a worktree need `.git/worktrees/<name>/` writable, the fit breaks: those admin dirs hold `commondir` and `gitdir`, which redirect git. That is why the proposed live lines include a must-stay-refused write to them.

## Requirement 3: the credential after a refresh

### Facts

| # | Fact | Source |
|---|---|---|
| F3.1 | A `denyRead` file is masked with `--ro-bind /dev/null <file>`. Mounts are set up for each sandboxed command. | [observed, binary 2.1.293] `research-q125-cc-isolated-sandbox.md` l.23; [observed] C1 passed on the command after the renames |
| F3.2 | A sandboxed command that is already running when the file is replaced by rename reads the new content. | [observed] X4 FAIL |
| F3.3 | Mechanism: since Linux 3.18 a rename or unlink over a mount point succeeds from a mount namespace where that path is not a mount point, and the mount is detached in every other namespace. The `/dev/null` bind hangs off the old directory entry and is dropped. | [inferred] kernel behaviour; consistent with F3.2 |
| F3.4 | Claude Code's credential writer stages the new content and publishes it (`stagingDir`, `renameFn`, `beforePublish` in the file writer behind the plaintext store), which is a rename like X4's `mv -f`. The writer refuses symlinks by default (`O_NOFOLLOW`; a reader returns `refused-symlink` on `ELOOP`). So a `.credentials.json` symlinked into a directory of its own would be refused, or replaced by a regular file on the next refresh. | [observed, binary] (strings); [inferred] (which branch runs) |
| F3.5 | A directory in `denyRead` is masked by a mount on the directory itself (a tmpfs in issue reports). A rename **inside** the directory happens beneath that mount and does not detach it. | [docs] issue #39284; [inferred] mount semantics |
| F3.6 | The credential sits in `~/.claude` with `shell-snapshots/`, `session-env/`, `.claude.json`, `ssh/`, `projects/` and symlinks to `/opt/claude-workflows/{scripts,skills,guides,hooks}`. Sandboxed Bash likely sources a file from `shell-snapshots/`, and the global instructions call `~/.claude/scripts/*.sh`. | [observed] `ls -la ~/.claude`; [inferred] that the snapshot is sourced inside the sandbox |
| F3.7 | `sandbox.credentials.files` (`deny` or `mask`, a file or a directory) and `sandbox.credentials.envVars` exist; a read-deny inside an allowed area (`allowRead`/`allowWithinDeny`) exists. How `credentials.files` handles a rename is not stated. | [observed, binary]; [docs] issue #70440 (setting added in 2.1.187) |
| F3.8 | A sandboxed Bash call may run up to 600000 ms in the foreground. A background command keeps running across turns with no stated cap. | [observed] this session's Bash tool schema |

### Divergent design

**Diagnosis.** Any file-level mask is lost when the file is renamed over (F3.3), and Claude Code's refresh renames (F3.4). The fix has to mask something that is not renamed: the directory. Seeded constraints: H2 (a mask that silently stops working is present-but-inert), S1, S3, S10.

| Candidate | Verdict |
|---|---|
| **3A** directory deny: managed `denyRead: ["~/.claude"]` plus `allowRead` back-entries for what sandboxed Bash needs (`shell-snapshots`, `session-env`, the `/opt` symlinks or their targets) | **Tentative pick.** Uses Claude Code's own mechanism (S3). It is one or two managed lines (S8) with no host chore (S10). It also hides `~/.claude/ssh` and `.claude.json` from sandboxed commands. If a needed path is missed, every sandboxed command fails, visibly (H2's loud side). The existing X4 line tests it unchanged. Open: U4, U5. |
| **3A′** credential alone in its own directory (symlink) | **Eliminated**: the writer refuses or replaces symlinks (F3.4). |
| **3B** keep the credential out of the container's files: `CLAUDE_CODE_OAUTH_TOKEN` from a long-lived token, stripped from sandboxed commands by `sandbox.credentials.envVars` | Viable but against S10. A yearly host chore mints and supplies the token, a new host secret is a new trust decision, and headless subscription runs depend on the file today (`claude_headless_flags`). Fallback only. |
| **3C** accepted residual beside decision-log row 53 | Viable. Under S1, waiting through a refresh is a deliberate act, not an honest slip. But hiding the credential is the sandbox's first job, and watch Q-098 waits on exactly that. Fallback, and the owner's call. |
| **3D** cap command lifetime | **Eliminated**: background commands have no cap (F3.8), so it narrows the window without closing it. |
| **3E** report upstream (mask the directory, or re-check the inode) | Complements any pick. It does not ship anything here. |

**Path A, conditional on the live check: 3A.** Among the options that survive the constraints, 3A dominates 3B (no host chore) and 3C (no residual), **if** the X4 line passes with it. If X4 still fails, or sandboxed Bash cannot work with `~/.claude` denied, the choice between 3C and 3B is the owner's (question 3, to file only then).

## F-009: whose is it?

F-009 (`docs/working/feedback/belegarth-herald.md` l.238-250, 2026-11-06): "Both Agent calls failed: Claude Code could not confirm that the repository's `.git` entry belongs to its folder". 7caea26d's message reports the same refusal with the sandbox installed.

**It is not the sandbox's:**

- [observed] F-009 is dated 2026-11-06. The sandbox merge 3cd6d9bb is dated 2026-11-11, and Q-277 says the sandboxed image ran only on 2026-11-12. So herald's container had no Bash sandbox.
- [observed] `workflows/parallel-worktrees.md` l.39: in cc-isolated, Agent isolation "has failed outright since 2026-09-18".
- [observed] Reproduced today: `/etc/claude-code/` does not exist in this container (no managed sandbox), and an Agent call with `isolation: "worktree"` failed at once with "Failed to resolve base branch "HEAD": Claude Code could not confirm that this repository's .git entry belongs to the folder it is in (for example a symlinked .git, …)". No worktree or branch was left behind.

**What is the sandbox's:** only the raw `git worktree add` failure ("Read-only file system", F1.1).

**What stays unknown:** why Claude Code cannot confirm `/workspace/.git`, a real directory on the `/workspace` bind mount. That is the container's question. It decides whether 1C″ (the harness route) ever becomes viable. It is the roadmap idea "cc-isolated's manual worktree fallback as the default": this doc settles its precondition (the refusal is the container's), not the change.

## Thin facts: what a host run must settle

All of these can ride the one `cc-verify` run the return needs.

| # | Unknown | Settles | Command (in a session built from the return branch) |
|---|---|---|---|
| U1 | Does a sandboxed `git add`/`git commit` succeed inside a worktree made outside the sandbox? | Whether 1C is enough or 1B′ is needed | W2 below |
| U2 | Does managed `excludedCommands` match `git worktree add …` and `cd /workspace && bash /opt/claude-workflows/scripts/d6.sh build-loop.sh …`? What is the entry syntax? | 1C versus 1C′ | W1/W3 below; `claude --debug` shows the decision |
| U3 | Does the sandbox drop a write glob in `denyWrite`? | Confirms 2A's elimination | `claude --debug` with a trial `denyWrite` glob; grep the log for `Skipping glob write pattern` |
| U4 | Does a directory `denyRead` survive a rename inside the directory? | 3A | X4, unchanged, with `denyRead: ["~/.claude"]` |
| U5 | What does sandboxed Bash need under `~/.claude`? | 3A's `allowRead` list | Every tool call in the check passing (Q0 lines), plus R1 below |
| U6 | Why does Claude Code refuse to confirm `/workspace/.git` in cc-isolated? | 1C″, F-009 | `claude --debug` in cc-isolated, one Agent call with `isolation: "worktree"`, read the git command it ran |

## Proposed live-check lines (not applied; the check file is not edited in this unit)

### Requirement 1

Exclusions apply to top-level tool calls (F1.9), so the worktree steps must be their own Bash calls. `q125-verify-check.sh` would add three entries to the stub's command list and to `--allowedTools`, plus a sandboxed script `w.sh` written the way `x.sh` is:

```bash
# After C1/C2 (the stub hands them out in order; claude -p runs with cwd /workspace):
W="$WS/.claude/wt-q125-w"
C3="git worktree add --detach $W HEAD"   # excluded: must succeed (W1)
C4="bash $D/w.sh $W"                      # sandboxed: W0, W2, W5 below
C5="git worktree remove --force $W"      # excluded: must succeed (W3)
python3 -I "$D/stub.py" "$D" "$C1" "$C2" "$C3" "$C4" "$C5" &
# ... --allowedTools "Bash($C1)" "Bash($C2)" "Bash($C3)" "Bash($C4)" "Bash($C5)"
```

```bash
# w.sh (sandboxed; $1 is the worktree)
w="$1" n="$(basename "$1")"; adm=/workspace/.git/worktrees/$n
[ -f "$w/.git" ] && res W1-excluded-add pass || res W1-excluded-add "FAIL (no worktree at $w)"
# W0: the deny is live, so the passes above and below are not vacuous.
if git -C /workspace worktree add -q --detach /workspace/.claude/wt-q125-raw HEAD 2>/dev/null; then
  git -C /workspace worktree remove --force /workspace/.claude/wt-q125-raw 2>/dev/null
  res W0-sandboxed-add-refused "FAIL (a sandboxed worktree add succeeded)"
else res W0-sandboxed-add-refused pass; fi
# W2 (U1): ordinary work inside the worktree.
( cd "$w" && echo w > q125-w && git add q125-w \
  && git -c user.email=q125@localhost -c user.name=q125 commit -qm q125 ) >/dev/null 2>&1 \
  && res W2-commit-in-worktree pass || res W2-commit-in-worktree "FAIL (git add/commit refused in $w)"
# W5: the admin files that redirect git stay refused to sandboxed writes.
for f in commondir gitdir config.worktree; do
  if ( : >> "$adm/$f" ) 2>/dev/null; then res "W5-admin-$f" "FAIL (writable: $adm/$f)"; else res "W5-admin-$f" pass; fi
done
```

- The host side checks W3 after `claude -p`: `git -C "$WS" worktree list --porcelain` no longer names `$W`, and `$W` is gone.
- REQUIRED gains `Q0-tool-call-3..5 W0-sandboxed-add-refused W1-excluded-add W2-commit-in-worktree W3-excluded-remove W5-admin-commondir W5-admin-gitdir W5-admin-config.worktree`.
- The setup block at l.83-88 (the unsandboxed pre-made worktree) stays for the C3 lines.
- W2 FAIL with W5 pass is U1's bad case: 1C alone is not enough. W2 pass with W5 FAIL means the admin dirs opened wholesale, and requirement 2 is wider than this doc assumes. Both send the design back.
- An INFO-only W4 line runs `cd /workspace && bash /opt/claude-workflows/scripts/d6.sh build-loop.sh --free-worktrees` as a sixth call and reports its first line. That settles U2 for the d6 entry's compound form without changing state: a fresh verify container has no finished loops.

### Requirement 2

- `live-check-q125.sh` l.100: walk `/workspace/.claude/worktrees/*/ /workspace/.claude/wt-*/`.
- Under 2C, print the nested lines as `INFO C3-nested-… writable (accepted residual, decision-log row 53)`, and drop `C3-nested-settings-1` from REQUIRED.
- Under 2B or 2E they stay `RESULT` lines that must pass.

### Requirement 3

No new line. X4 is unchanged and must pass with 3A. `X1-credential-present` currently expects the path to exist inside the sandbox. Under a directory deny the path is absent, so that line becomes "pass when absent or a character device", with the X1 reads still judged by content.

## Recommended design for the return

One build unit on top of `git revert 7caea26d` (the revert of the revert, as 7caea26d's message says):

1. Managed `excludedCommands`: `git worktree` and the d6 `build-loop.sh` line, in whatever syntax U2 shows (1C).
2. Managed `denyRead: ["~/.claude"]` with `allowRead` back-entries for what sandboxed Bash needs (3A). The single-file entry goes.
3. Nested worktree paths are an accepted residual, recorded beside decision-log row 53, with the exit scan as the `.git`-side tripwire (2C).
4. The check-file lines above. One `cc-verify` run, which also settles U1-U5.
5. Enforcement-file rules apply: a pre-mortem listing the bypass families (the plan's table plus "excluded command acts on a sandbox-written file", F1.10), and `Live-verified:`.

Size: the revert is about 480 lines back. The new delta is perhaps 10 managed-settings lines, their bats cases, and about 40 check-file lines. The revert plus delta may pass the ~400-line cap (log row 62). If so, split it as Q-125 did: U1 is the seccomp layer, U2 the settings and check.

## Questions for the owner (for the cycle to file; a build loop does not write the questions files)

The three sandbox gaps this research covers:

- **1, worktrees.** Under the sandbox, agents cannot make git worktrees, and maybe cannot commit in them.
- **2, nested worktree paths.** Inside a worktree, a sandboxed command can write the `.git` pointer file and create `.claude/`.
- **3, the credential after a refresh.** A command already running when the login token is refreshed can read the new token.

**Q1 · sandbox-return-worktrees-outside-sandbox** (you: judgment). Let `git worktree` and the gate's `build-loop.sh` line run outside the Bash sandbox, so agents can make worktrees under it?

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Exclude them (pick)** | Two managed `excludedCommands` entries; root-owned gate code and `git worktree` run unsandboxed | The one live check the return needs | An unsandboxed `git worktree add` can check a branch out anywhere node can write; Edit/Write can already write those paths |
| **[2] Clones, not worktrees** | Everything stays sandboxed; dispatch, status, free and land are rewritten around clones | Several units and reviews before the sandbox returns | Weeks more with no sandbox; the gate's largest file is rewritten |
| **[3] No sandbox** | Stay as now | Nothing | Bash can read the credential and write every file a session reaches |

- **Blocks:** the return brief.
- **Interim:** [1] in the design. If the check shows commits in a worktree are refused too (line W2), this comes back with [2] as the likely answer.

**Q2 · sandbox-return-nested-worktree-residual** (you: judgment). Accept that, inside worktrees, sandboxed commands can write the `.git` pointer file and create `.claude/`?

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Accept, recorded beside row 53 (pick)** | The C3 lines become INFO; the exit scan stays the `.git` tripwire | Nothing | A planted `.claude/settings.json` in a worktree runs hooks when a session opens that worktree; Edit/Write can already do the same |
| **[2] Fixed worktree slots** | Worktrees move to named slots the managed file denies by literal path | A larger unit; every worktree path the gate parses changes | Still open to Edit/Write; placeholder files can block worktree creation |
| **[3] Root-owned pins** | A sudo helper makes each worktree's `.git` and `.claude/` root-owned | A new sudo rule and root helper in the image | Breaks repos that track `.claude/` files; a rename of the parent directory gets around it |

**Q3 · sandbox-return-credential-fallback** (you: judgment). **File only if the live check's X4 line still fails with `~/.claude` denied.** Then: accept the gap, or keep the credential out of the container?

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Accept, recorded beside row 53** | A command running across a token refresh can read the new token | Nothing | A deliberately waiting command gets the token; watch Q-098 (the global allowlist) keeps waiting |
| **[2] Token in the environment** | A long-lived token replaces the file; the sandbox strips it from commands | A yearly host step to mint the token, and a new host secret | Headless runs that need the file break until reworked |
| **[3] Hold the sandbox** | Wait for Claude Code to mask the directory itself | Nothing now | No sandbox until an upstream fix |

## Other choices (one-line notes)

- Revert 7caea26d rather than re-merge `feat/q125-sandbox-on-main`: 7caea26d's own instruction. Not a design choice.
- The research ran no Docker and no host commands (out of scope). The two scratch git repos and the one Agent isolation attempt left nothing behind (`git worktree list` checked).

## Files read

Last verified: 2026-11-12
`git show 7caea26d` and `7caea26d^:devcontainer-config/{managed-settings.json,cc-sandbox-settings.sh}` · `docs/working/{plan-q125-cc-isolated-sandbox.md,checkpoint-q125-cc-isolated-sandbox.md,research-q125-cc-isolated-sandbox.md,research-2026-11-07-q125-sandbox-on-main.md,q125-verify-check.sh,live-check-q125.sh}` · `docs/working/questions-archive.md` (Q-273, Q-277) · `docs/roadmap.md` (the two sandbox Now items, the F-009 idea) · `docs/working/feedback/belegarth-herald.md` (F-009) · `workflows/parallel-worktrees.md` · `skills/dev-cycle/SKILL.md` · `scripts/build-loop.sh` · `scripts/self-improvement.sh` · `devcontainer-config/cc-exit-scan.sh` (header) · `hooks/wiring.json` · `docs/failure-patterns.md` · the Claude Code 2.1.323 binary (strings)

Web sources (unverified, search summaries only): code.claude.com/docs/en/sandboxing and /settings-reference; anthropics/claude-code issues #61596, #97839, #66288, #92684, #74081, #39284, #54232, #81602, #70440; startdebugging.net on `sandbox.credentials`; makandracards on `excludedCommands`.
