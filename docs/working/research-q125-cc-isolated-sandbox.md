# Research: Q-125 — Claude Code's Bash sandbox in cc-isolated

- **Goal**: Make Claude Code's Bash sandbox run in cc-isolated, refusing sandboxed reads of `~/.claude/.credentials.json` and writes of `~/.claude/settings*.json`, without granting the container a capability (Q-124 [1]).
- **Problem framing**: The container's seccomp profile refuses the namespace syscalls bubblewrap needs, and nothing enforcing configures the sandbox. Considered and discarded: "the image is missing bwrap and socat". That is true but secondary: the Q-088 spike showed bwrap cannot start here even when installed.
- **Project state**: Builds Q-124 [1] as Q-125, in two stacked units (U1 seccomp, U2 managed settings) · unblocks Q-098 (global allowlist) · blocked on one host run (cite: docs/spikes/weaker-nested-sandbox-cc-isolated.md)
- **Task status**: in-progress (implemented on branches; host probe passed 2026-10-07; live run pending)

## What exists

- `devcontainer-config/devcontainer.json`: runArgs are `--cap-add=NET_ADMIN/NET_RAW` only, so Docker's default seccomp profile applies [observed]. Build paths are absolute via `${localEnv:CC_CONFIG_DIR}` because `--override-config` resolves relative paths against the target repo [observed, header comment].
- `devcontainer-config/Dockerfile`: shared toolchain layers, then a per-project tail (`ARG CC_EGRESS_PROFILE` onwards) that bakes the egress profile root-owned [observed]. No bwrap, no socat, no managed settings [observed].
- `link-claude-home.sh` merges `hooks/wiring.json` into the volume's `settings.json`. Its own comment says this is "a default, not a boundary — `node` can still edit the merged result … Anything that must be enforced belongs in the image" [observed]. So the sandbox block cannot live in wiring.json.
- `init-firewall.sh --print-entries` composes base + profile and parses each entry into `domain<TAB>ports`. It exits before any rule is touched and is unit-tested (`test/init-firewall-rules.bats`) [observed].
- The trust manifest (`cc-isolated.sh enforcement_files`), `install.sh PAYLOAD` and `hooks/live-verify-gate.sh`'s `enforcement` regex must all name a new boundary file. A bats test pins PAYLOAD ⊆ enforcement_files [observed].
- Docker's default profile (moby v28.3.3) [observed, fetched]:
  - Rule 15 allows `clone, clone3, mount, setns, umount2, unshare` only with CAP_SYS_ADMIN.
  - Rule 16 allows `clone` without it only when `flags & 0x7E020000 == 0`, i.e. no namespace flags.
  - Rule 18 returns ENOSYS for `clone3` without SYS_ADMIN.
  - `pivot_root` appears in no rule.
- Claude Code 2.1.293, read from the binary [observed]:
  - Managed settings live at `/etc/claude-code/managed-settings.json` (plus a `managed-settings.d/` drop-in dir).
  - The bwrap argv is `--new-session --die-with-parent [--unshare-net] <fs binds> --dev /dev --unshare-pid --unshare-user --cap-drop ALL --proc /proc`.
  - A denyRead file is masked with `--ro-bind /dev/null <file>`; denyWrite becomes `--ro-bind`.
  - The embedded apply-seccomp helper calls `unshare(CLONE_NEWUSER)`, `unshare(CLONE_NEWPID|CLONE_NEWNS)` and `mount(/proc)`.
  - The dependency check wants `bwrap` and `socat`.
  - Settings keys: `failIfUnavailable`, `allowUnsandboxedCommands` (default true), `autoAllowBashIfSandboxed` (default true), `network.allowManagedDomainsOnly`, `network.strictAllowlist`, `filesystem.{denyRead,denyWrite,allowWrite}`.
  - In `allowedDomains`, `*.x` matches subdomains only, not `x` itself.
  - The runtime has a built-in write-deny list (`.gitconfig`, `.bashrc`, `.zshrc`, `.mcp.json`, …) and treats `.git`, `.vscode` and `.idea` as protected directories.

## Invariants

- No capability is added and no broad switch is flipped (`SYS_ADMIN`, `seccomp=unconfined`, `systempaths=unconfined`). Q-124 chose [1] over [2] for this [observed: Q-124 entry]. Pinned by `test/seccomp-cc-sandbox.bats`.
- Every upstream seccomp rule is preserved exactly. Pinned by the canonical hash.
- Boundary files are root-owned and not writable by node, and so are their parent directories (FP-142) [observed: Dockerfile pattern].
- The firewall stays the network boundary. The sandbox's allowedDomains must never admit a name the firewall did not parse (FP-139/140) [observed].
- A new boundary file is installed, hashed and gated together (bats pin) [observed].
- The shared Dockerfile layers stay cached: a new package goes in a new late layer, not the first apt line [inferred: that layer precedes the Android/Rust/.NET layers].

## Prior art

- The egress profile is baked root-owned at build time in the per-project tail. Managed settings follow the same pattern and render from the same allowlist.
- Pinned third-party artifacts are verified by hash (shfmt, elan, dotnet). The seccomp profile follows this with a canonical-form hash of upstream.

## Gotchas

- **REFUTED 2026-10-07 by the host probe (Q-126):** under the Q-125 profile, bwrap 0.8.0 started with a fresh `--proc /proc` on 6.18.35.2-microsoft-standard-WSL2, no LSM (variant A, T1 pass); Docker's default profile still refuses (B, T1 FAIL), and nothing else widened (T4). The reasoning below was wrong about this kernel and Docker build; kept for the record.
- **The fresh `/proc` mount (the main open question)** [inferred from kernel source, not observed — refuted above]:
  - Docker masks `/proc/kcore`, `/proc/keys`, `/proc/timer_list` and others by binding `/dev/null` over them.
  - In a new user and mount namespace those mounts become locked. The kernel's `mnt_already_visible()` then refuses a new procfs mount unless every locked child sits on an empty directory, and a file mount does not.
  - So bwrap's `--proc /proc` (and the helper's `mount(/proc)`) may fail with EPERM even with the namespace syscalls allowed.
  - Claude Code's weaker mode exists for exactly this case ("hosts such as unprivileged Docker containers that cannot create one"). The spike's claim that a fresh `/proc` "should then work" is unverified.
  - `docs/working/probe-q125-bwrap.sh` tests it on the host.
- **Weaker mode's leak** [inferred; moot, weaker mode unused]: the probe's T3 read failed with EACCES both ways, which is weak evidence only (mounts in a user namespace are implicitly nodev, so the `/dev/null` mask reads as `Permission denied`). with `--bind /proc /proc`, a sandboxed process can probably reach a same-uid container process's `/proc/<pid>/root/…`. That would bypass the `/dev/null` mask on `.credentials.json`. Probe test T3.
- `clone3` cannot be filtered by flags (they sit in a struct), so it stays ENOSYS and glibc falls back to `clone` [observed: upstream rule 18].
- The shell guard hook refuses Bash commands that name `hooks/` or `*settings*` paths. Edits to those files go through Edit/Write.
- The bats suites need `LC_ALL=C.UTF-8` here: `en_US.UTF-8` is not installed, and the setlocale warning corrupts asserted output (environment, not code).
- Failure-pattern grep: FP-047, FP-050, FP-058, FP-061, FP-081, FP-139, FP-140, FP-142 (see Prior failures)

## Prior failures

- FP-058: a bwrap runtime failure dropped the computation silently (fail-open). Hence `failIfUnavailable: true`.
- FP-142: a node-owned parent directory let the agent replace a root-owned boundary file. Hence `/etc/claude-code` is root-owned 0555.
- FP-139/140: boundary too wide. Hence allowedDomains is derived from the firewall's own parse.
- FP-047/050/061/081: older sandbox tiers in other code (poisoned helper, shared mount ns, hardcoded home, UDP). They do not apply directly; noted for completeness.

Moved to plan: all [assumed] items are either probe-tested or recorded as risks.

## Files read

Last verified: 2026-10-07
devcontainer-config/devcontainer.json
devcontainer-config/Dockerfile
devcontainer-config/link-claude-home.sh
devcontainer-config/install.sh
devcontainer-config/cc-isolated.sh
devcontainer-config/init-firewall.sh
devcontainer-config/egress/base.txt
hooks/live-verify-gate.sh
test/cc-isolated-functions.bats
test/install-host.bats
docs/spikes/weaker-nested-sandbox-cc-isolated.md
docs/decisions/log.md
docs/working/questions.md
docs/working/questions-archive.md
docs/thoughts/failure-patterns.md
