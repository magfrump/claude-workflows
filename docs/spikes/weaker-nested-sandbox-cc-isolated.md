# Spike: Can `sandbox.enableWeakerNestedSandbox` sandbox Bash in cc-isolated without user namespaces?

Date: 2026-10-07
Last verified: 2026-10-07
Relevant paths: devcontainer-config/devcontainer.json, devcontainer-config/Dockerfile, devcontainer-config/cc-isolated.sh
Branch: spike/q088-weaker-nested-sandbox-2026-10-07 (record only; no spike code)
Time spent: ~15 minutes

- **Goal**: Find out whether Claude Code's weaker nested sandbox mode can run sandboxed Bash in cc-isolated with unchanged seccomp and runArgs (Q-088, per Q-081 [2]).
- **Project state**: Answers Q-088 · feeds the Q-081 decision ([1] build the full sandbox vs [3] accept deny + container), now Q-124 · not blocked
- **Task status**: complete

## Criteria (from Q-088)

- **Success looks like:** a sandboxed Bash call runs in a cc-isolated container that has `bubblewrap` and `socat` but unchanged seccomp and runArgs, and a read of `~/.claude/.credentials.json` is refused.
- **Failure looks like:** bwrap still needs user namespaces, or weaker mode drops the filesystem restriction.
- **Ambiguous if:** the bwrap arguments depend on runtime detection that a static read cannot settle.

## Answer

**No: the failure criterion holds.** In Claude Code 2.1.293, weaker mode changes exactly one bwrap argument: `--proc /proc` becomes `--bind /proc /proc`. `--unshare-user` and `--unshare-pid` are still passed every time. This container refuses every namespace type, with zero effective capabilities and no CAP_SYS_ADMIN in the bounding set. bwrap therefore cannot start here, whether it runs unprivileged or setuid. A live run with bwrap installed would not change the answer, so the Dockerfile branch and the host run that Q-088 planned are unnecessary.

## Key findings

- **What weaker mode does (static read of the shipped bundle).** In the Linux wrapper in `@anthropic-ai/claude-code/bin/claude.exe` 2.1.293, the bwrap argv is built in this order: `--new-session --die-with-parent`, `--unshare-net` (when network is restricted), the filesystem binds, `--dev /dev`, `--unshare-pid`, then `--unshare-user …`. Last comes `!enableWeakerNestedSandbox ? --proc /proc : --bind /proc /proc`. The settings schema says the same thing: *"Linux only: Run without the fresh /proc mount, for hosts such as unprivileged Docker containers that cannot create one. **Reduces security** — the host /proc stays readable by sandboxed commands."* The mode is for hosts that can create user namespaces but cannot mount a fresh procfs. It does not avoid namespaces.
- **What the container allows (live, ctypes `unshare(2)` in forked children).** `CLONE_NEWUSER`, `NEWNS`, `NEWPID`, `NEWNET`, `NEWUTS`, `NEWIPC` and `NEWUSER|NEWNS` all return EPERM. `CapEff` is 0 and `Seccomp: 2` (filter mode, 3 filters). `user.max_user_namespaces` is 96083, so the kernel allows user namespaces; the refusal comes from Docker's default seccomp profile, which allows namespace flags only with CAP_SYS_ADMIN.
- **Setuid bwrap is no way around it.** The bounding set is CHOWN DAC_OVERRIDE FOWNER FSETID KILL SETGID SETUID SETPCAP NET_BIND_SERVICE NET_ADMIN NET_RAW SYS_CHROOT MKNOD AUDIT_WRITE SETFCAP: Docker's default plus the `--cap-add=NET_ADMIN/NET_RAW` in `devcontainer.json`. It has no SYS_ADMIN, so a setuid-root bwrap cannot create mount or pid namespaces either.
- **This container stands in for cc-isolated.** cc-isolated launches from the same `devcontainer.json` (`--override-config "$(config_dir)/devcontainer.json"` in `cc-isolated.sh`), whose only runArgs are the two cap-adds. The bounding set above matches that exactly.
- **Gotcha for [1].** Weaker mode also leaves the host `/proc` readable inside the sandbox. It is listed among the settings that make Claude Code refuse device tools ("sandbox_weakened"). If [1] adds a seccomp profile that allows user namespaces, a fresh `/proc` mount should then work, so [1] should not need weaker mode at all.

## Recommendation

The weaker mode cannot be used as tested. The Q-081 decision goes back to the user as a `you: judgment` entry (Q-124): [1] build the full sandbox, or [3] accept deny + container. Under [1], the open design point is how to let user namespaces through: a custom seccomp profile (Docker's default plus `CLONE_NEWUSER`), `--cap-add=SYS_ADMIN`, or `seccomp=unconfined`. The first is far narrower than the other two. If [1] is picked, it starts with an RPI pass and with Q-088's original live half (Dockerfile branch, one host run) applied to that profile.

## What the spike did NOT answer

- Whether bwrap works under a custom seccomp profile that allows `CLONE_NEWUSER` on this WSL2 kernel (6.18), with or without AppArmor. That is the live check [1] would need.
- Whether a later Claude Code release changes the argv. The read is pinned to 2.1.293; re-check if `enableWeakerNestedSandbox`'s description changes.
