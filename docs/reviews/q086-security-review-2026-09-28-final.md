Commit: ed28f76

# Security Review — review/q086 (Q-086, GNU parallel in the cc-isolated image), final confirming pass

**Scope:** full branch `git diff main...HEAD` in `/workspace/.claude/wt-q086`. The code diff is `devcontainer-config/Dockerfile`: `parallel \` added to the base apt RUN (`:43`) and a 3-line header rationale (`:4-6`). Commit messages 1ef3090, 577bef7 and ed28f76 are also in scope. The `docs/reviews/` artifacts are review records with no security surface.
**Date:** 2026-09-28
**Based on:** `docs/reviews/q086-code-fact-check-report-final.md` (22 claims: 17 verified, 4 mostly accurate, 1 unverifiable, 0 incorrect)

Environment: this sandbox is a build of the current cc-isolated image, without `parallel`, and has no egress and no Docker. Anything that needs the package index or a rebuilt image is marked unverified. I read the iteration-1 security review and re-derived each point below myself.

## Trust Boundary Map

```
B1: [Debian bookworm archive (signed apt index)] → [apt-get install as root, image build, Dockerfile:22-46] → [/usr/bin/parallel + Depends closure in the boundary image]
B2: [in-container agent (uid node, untrusted)]   → [parallel CLI / $PARALLEL / ~/.parallel/]              → [child processes as uid node; egress still via init-firewall allowlist]
B3: [uid node]                                   → [sudo init-firewall.sh "" (env_reset, !setenv)]         → [root firewall setup]   (unchanged; re-checked because an exec tool was added)
```

| Label | Source | Mutability | Trust classification (per sink class) |
|---|---|---|---|
| S1 | Debian `parallel` package and its Depends closure | deploy-time (image build) | Trusted for exec on the same footing as every other package in the RUN (same signing root, same unpinned-version policy). Closure not observed offline (settled C3). |
| S2 | `$PARALLEL`, `~/.parallel/config`, profiles | runtime-mutable by uid node | UNTRUSTED toward exec sinks. The sink runs as node, the same principal that can write the source, so this is no escalation. |
| S3 | Command lines given to `parallel` (by the agent, or by `bats-exec-suite:420`) | request-time | UNTRUSTED for exec, same principal as the caller. |
| S4 | `/etc/parallel/config` if the package ships one | deploy-time, root-owned | Trusted toward node's runs (node cannot write /etc). It does not exist in the current image (`ls /etc/parallel` → no such file). |

The diff adds an executable that runs commands as its caller. It adds no boundary crossing. In the container the caller is uid node, which already has bash, `xargs`, perl and ssh (executed here: `which perl ssh xargs` → `/usr/bin/perl /usr/bin/ssh /usr/bin/xargs`). The one privileged path is B3, and it does not reach `parallel`. I checked this at ed28f76 as follows:
- The sudoers grant is a bare-invocation, env-reset grant (`Dockerfile:528`).
- `devcontainer.json:141` runs `sudo /usr/local/bin/init-firewall.sh` and then runs `link-claude-home.sh` as node, not under sudo.
- `grep -n -w -E 'parallel|sem|niceload|env_parallel'` over `devcontainer-config/*.sh`, `*.py` and `devcontainer.json` returns no matches.

## Findings

No findings.

For the record:
- Iteration-1 Finding 1 (the addition had no rationale) was fixed in 577bef7, and the header now carries it at `Dockerfile:4-6`. The fact-check verifies all three clauses (Claims 1a–1c).
- Iteration-1 Finding 2 (the Depends closure, possibly `sysstat`) is settled as C3 and deferred to the rebuild check. I have no new evidence on it.

The fact-check found a new edge: a one-file `--jobs 2` run also aborts. That is a wording nuance with no security consequence.

### Untested bypass candidates

Move 11 does not strictly apply, because the diff adds no guardrail. These are the ways a new exec tool could widen the boundary:

- **Root-context invocation via sudo (B3):** tested (static). The grant covers only `init-firewall.sh ""` under `env_reset, !setenv` (`Dockerfile:528`), and no root-run script calls `parallel`. `$PARALLEL` cannot cross into root.
- **PATH shadowing of root-run tools by `parallel`/`sem`/`niceload`:** tested (static). They install root-owned into /usr/bin, and no root-run script invokes those names.
- **New egress via `--sshlogin`:** tested (reasoned from the executed `which ssh`). ssh is already present, and egress is set by the unchanged init-firewall.sh.
- **setuid/setgid files or an auto-started service in the Depends closure:** untested. This needs the package index or the rebuilt image, and belongs to settled C3's rebuild check.

## Endorsement Claims

- **Claim:** Adding `parallel` does not widen node's root path. The only sudo grant is a bare, env-reset invocation of `init-firewall.sh`, and no root-run script in `devcontainer-config/` invokes `parallel`, `sem` or `niceload`.
  **Location:** `devcontainer-config/Dockerfile:528`, `devcontainer-config/devcontainer.json:141`
  **Evidence:** read-static
  **Verified:** the sudoers `printf` at `Dockerfile:528`; the `postStartCommand` at `devcontainer.json:141` (the second command runs as node); the `grep -w` over `devcontainer-config/*.sh`, `*.py` and `devcontainer.json` returned nothing.
  **Not verified:** the live `/etc/sudoers.d/node-firewall` (mode 0440, unreadable to node), and any root-run Depends maintainer script or unit that the rebuilt image may carry (C3).
  **route: code-fact-check**

- **Claim:** The capabilities `parallel` gives node (spawning commands, remote exec over ssh, config from `$PARALLEL`/`~/.parallel`) were already available to node through binaries in the current image.
  **Location:** `devcontainer-config/Dockerfile:43`
  **Evidence:** executed
  **Verified:** `which perl ssh xargs` resolves all three in the current image; `/etc/parallel` is absent.
  **Not verified:** the rebuilt image with `parallel` installed, and parallel's bookworm-packaged feature set (no package offline).
  **route: code-fact-check**

## Primitive sweep

Primitive: process exec (GNU parallel spawns commands)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `devcontainer-config/Dockerfile:43` (install only) | S1 | signed apt index | cleared: install, not an invocation |
| `/usr/libexec/bats-core/bats-exec-suite:420` (outside the repo; runs as node when `--jobs N>1`) | S3 | none needed, same principal | cleared: no privilege transition |
| `devcontainer-config/*.sh`, `*.py`, `devcontainer.json` (incl. root-run init-firewall.sh) | none | n/a | cleared: no call site (grep) |
| Future `scripts/run-tests.sh --jobs` (Q-090) | S3 | n/a | not in this diff; review it with Q-090 |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| — | No findings | — | — | — | — |

## Overall Assessment

Within the code paths I read, the change widens no trust boundary. `parallel` runs commands as its caller. node already has equivalent exec, perl and ssh capability. The privileged path (the bare, env-reset sudo grant to init-firewall.sh) never reaches `parallel`, and egress is still governed by the unchanged firewall. The iteration-1 rationale gap is fixed. The only open point is the package's Depends closure: whether it brings setuid files or auto-started services. That is settled C3, deferred to the rebuild's live check, and needs the rebuilt image. So the verdict is: no findings within the code paths read; endorsement claims pending execution verification for the parts that need the rebuilt image.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-q086/docs/reviews/q086-security-review-2026-09-28-final.md, structured per the security-reviewer skill.
- Answered: yes
- Out of scope: package-index lookups and the image rebuild (no egress, no Docker); settled findings A2, B1 and C1–C6 (no new evidence); the 1ef3090/bb9982f duplicate (already escalated); Q-090's future `--jobs` wiring.
- Escalate: nothing new. The C3 rebuild check (`apt-cache depends parallel`, then a setuid diff with `find / -xdev -perm /6000 -type f` against the current baseline) stays with the Q-084 live verification.
- Decisions I made: I treated the sandbox as the current image. I did not re-file iteration-1 Finding 2, because it matches settled C3.
