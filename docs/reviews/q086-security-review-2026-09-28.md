Commit: 1ef3090

# Security Review: review/q086 (Q-086, GNU parallel in the cc-isolated image)

**Scope:** `git diff main...HEAD` in `/workspace/.claude/wt-q086`: one added line, `parallel \`, in the base apt-get RUN of `devcontainer-config/Dockerfile` (enforcement file), plus commit 1ef3090's message
**Date:** 2026-09-28
**Based on:** `docs/reviews/q086-code-fact-check-report.md` (k=1 loop pass, 11 claims)

Environment note: this sandbox is a running build of the cc-isolated image itself (`/etc/cc-config-hash` and `/etc/sudoers.d/node-firewall` are present, both root-owned). Probes marked "executed" below therefore describe the current image **without** `parallel`. Nothing that needs the package index or a rebuilt image could be run (no egress, no Docker).

## Trust Boundary Map

```
B1: [Debian bookworm archive (signed apt index)] → [apt-get install as root, image build] → [/usr/bin/parallel + its Depends in the boundary image]
B2: [in-container agent (uid node, untrusted)]   → [parallel CLI / $PARALLEL / ~/.parallel/config] → [child processes as uid node, egress via init-firewall allowlist]
B3: [uid node]                                   → [sudo init-firewall.sh "" (env_reset, !setenv)]  → [root firewall setup]   (unchanged; checked because a new exec tool was added)
```

| Label | Source | Mutability | Trust classification (per sink class) |
|---|---|---|---|
| S1 | Debian `parallel` package and its dependency closure | deploy-time (image build) | Trusted for exec at build/run on the same footing as every other apt package in the RUN (same signing root, same unpinned-version policy). Dependency closure not observed offline, see Finding 2. |
| S2 | `$PARALLEL`, `~/.parallel/config`, `~/.parallel/*` profiles | runtime-mutable by uid node | UNTRUSTED toward exec sinks. The sink runs as node, the same principal that can write the source, so it is not an escalation path. |
| S3 | Command lines passed to `parallel` (by the agent, or by bats-exec-suite:420) | request-time | UNTRUSTED for exec. Same principal as the caller. |
| S4 | `/etc/parallel/config` (if the Debian package ships one) | deploy-time, root-owned | Trusted. uid node cannot write /etc. |

The diff adds an executable to the image; it adds no boundary crossing of its own. GNU parallel is a Perl program that runs commands as its caller. Inside the container its caller is uid node, which already has bash, `xargs -P`, perl 5.36 and `ssh` (executed: `which perl ssh xargs` → `/usr/bin/perl /usr/bin/ssh /usr/bin/xargs`; openssh-client 1:9.2p1-2+deb12u10 installed). Every parallel feature raised in the brief is therefore a convenience wrapper over capabilities node already has: `--sshlogin` uses the existing `ssh`, and its reachability is set by the unchanged firewall; `$PARALLEL` and `~/.parallel/` configure only node's own runs. The one path that could turn a new exec tool into escalation is B3, and it does not reach `parallel`. The sudoers grant (`Dockerfile:525`) allows only a bare `init-firewall.sh` with `env_reset, !setenv`, and `init-firewall.sh` never invokes `parallel`: `grep -w parallel` finds nothing; its one `xargs` use is at :767.

## Findings

#### 1. Added boundary-image package carries no rationale (header list or comment)

**Severity:** Informational
**Location:** `devcontainer-config/Dockerfile:40` (with the header list at `:1-6`)
**Boundary:** B1
**Move:** 10 (Review dependency changes: "each one should have a clear reason to exist")
**Confidence:** High
**Legibility-target:** for-author

Evidence:

```dockerfile
# devcontainer-config/Dockerfile:2-3
# (anthropics/claude-code .devcontainer). Local changes:
#   - decision 015: added bats, ripgrep, shellcheck (this repo's test suite and SI loop)
```
```dockerfile
# devcontainer-config/Dockerfile:39-41
  bats \
  parallel \
  ripgrep \
```
(excerpt ends :41; the RUN continues with `shellcheck \` and `&& apt-get clean && rm -rf /var/lib/apt/lists/*` at :43, read)

The file's convention for local, non-upstream additions is to record why each is there. The three test-suite tools appear in the header's "Local changes" list, and `dnsmasq-base` has a rationale block (`:45-51`). The same holds for uv, poppler-utils, the JDK and Rust further down. `parallel` is the only local addition with neither, so a later reviewer of the enforcement file cannot tell from the file why a command-spawning tool is in the boundary image. They also cannot tell whether it is safe to remove. The fact-check reached the same point from the staleness side (Claim 1b). This is audit-trail hygiene, not a vulnerability: no mechanism violates a security property (see the B2/B3 analysis above), so the Medium floor rule does not apply.

**Recommendation:** Extend the header line to `decision 015: added bats, ripgrep, shellcheck, parallel (this repo's test suite and SI loop; parallel for bats --jobs, Q-086)`, or put a one-line comment beside `parallel \`. Either is a one-line edit.

#### 2. Dependency closure of `parallel` not observed; possible `sysstat` Depends is unverified

**Severity:** Informational
**Location:** `devcontainer-config/Dockerfile:19-43`
**Boundary:** B1
**Move:** 10 (newly added dependency)
**Confidence:** Low
**Legibility-target:** for-orchestrator-synthesis

Evidence:

```dockerfile
# devcontainer-config/Dockerfile:19
RUN apt-get update && apt-get install -y --no-install-recommends \
```
(excerpt ends :19; the RUN runs to :43, read)

`--no-install-recommends` suppresses Recommends but not Depends. From memory (not verified here), Debian's `parallel` has historically pulled in `sysstat`. sysstat ships a cron entry and a systemd unit, and its collection is off by default. If it is a hard Depends in bookworm, it lands in the boundary image. I expect that to be inert: executed probes show no `cron`/`crond` binary in the current image and no init system that runs units (`/etc/cron.d` holds only `e2scrub_all`). Nothing here establishes the closure, whether any member ships setuid/setgid files, or whether a postinst starts anything. The current image's setuid set is the standard one (umount, mount, su, sudo, passwd, chsh, chfn, gpasswd, newgrp, chage, expiry, ssh-agent, unix_chkpwd), which gives a baseline to diff against.

**Recommendation:** Fold into the Q-084 step-4 live check already required by the commit's `Live-verified: no` trailer: in the rebuilt image, run `apt-cache depends parallel`, `dpkg -L parallel | xargs -r stat -c '%A %n' 2>/dev/null | grep -E '^[^ ]*s'`, and `find / -xdev -perm /6000 -type f`, then compare the last against the baseline above. No change to the diff is needed unless that check shows a new setuid file or an auto-started service.

### Untested bypass candidates

Move 11 does not strictly apply (the diff adds no guardrail). For the record, these ways a new exec tool could widen the boundary were checked or listed:

- **Root-context invocation via sudo (B3):** tested (static). The grant allows only `init-firewall.sh ""` under `env_reset, !setenv` (`Dockerfile:525`), and init-firewall.sh has no `parallel` call. `$PARALLEL` cannot cross into root.
- **PATH shadowing of a root-run tool by `parallel`/`sem`/`niceload`:** tested (static). The package installs root-owned files under /usr/bin, which node cannot write. No root script calls those names.
- **New egress via `--sshlogin`:** tested (reasoned from the executed `which ssh`). ssh was already present, and egress is set by init-firewall.sh, which this diff does not touch.
- **setuid/setgid or auto-started service in the dependency closure:** untested. Needs the package index or the rebuilt image (Finding 2).
- **`/etc/parallel/config` shipped with unsafe defaults:** untested; no package files offline. It is root-owned in any case, and at worst it affects node's own runs.

## Endorsement Claims

- **Claim:** Adding `parallel` does not widen the sudo grant: node's only root path runs `init-firewall.sh` with no arguments and a reset environment, and that script does not invoke `parallel`.
  **Location:** `devcontainer-config/Dockerfile:501-526`, `devcontainer-config/init-firewall.sh`
  **Evidence:** read-static
  **Verified:** sudoers line at `Dockerfile:525` (`Defaults:node env_reset, !setenv` / `node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh ""`); `grep -n -w -E 'parallel|sem'` over init-firewall.sh, link-claude-home.sh, devcontainer.json and cc-*.sh found only `xargs` at init-firewall.sh:767.
  **Not verified:** the live `/etc/sudoers.d/node-firewall` contents (mode 0440, unreadable to node here) and any `postStartCommand` path that runs as root outside those files.
  **route: code-fact-check**

- **Claim:** The capabilities `parallel` offers node (arbitrary command spawn, remote exec over ssh, config from `$PARALLEL`/`~/.parallel`) are already available to node through binaries present in the current image.
  **Location:** `devcontainer-config/Dockerfile:40`
  **Evidence:** executed
  **Verified:** in the current cc-isolated image, `which perl ssh xargs` resolves all three; perl is v5.36.0; openssh-client 1:9.2p1-2+deb12u10 is installed; `~/.parallel` does not exist yet.
  **Not verified:** the rebuilt image with `parallel` present, and parallel's own feature set as packaged in bookworm (no package offline).
  **route: code-fact-check**

## Primitive sweep

Primitive: process exec (GNU parallel spawns commands)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `devcontainer-config/Dockerfile:40` (install only, no invocation) | S1 | signed apt index | cleared: install, not exec |
| `/usr/libexec/bats-core/bats-exec-suite:420` (outside repo; runs as node when `--jobs N>1`) | S3 | none needed: same principal | cleared: runs as the caller, no privilege transition |
| `devcontainer-config/init-firewall.sh` (root) | none | n/a | cleared: no `parallel` call (grep) |
| Future `scripts/run-tests.sh --jobs` (Q-090) | S3 | n/a | not in this diff; review it with Q-090 |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Added boundary-image package carries no rationale | Informational | B1 | `devcontainer-config/Dockerfile:40` | High |
| 2 | Dependency closure (possible sysstat) not observed | Informational | B1 | `devcontainer-config/Dockerfile:19-43` | Low |

## Overall Assessment

The change adds no new capability to an in-container agent. GNU parallel runs commands as its caller, and node already has bash, xargs, perl and ssh. The only privileged path (the bare, env-reset sudo grant to init-firewall.sh) does not touch it, and egress stays governed by the unchanged firewall. There are no findings above Informational within the code paths read. The one edit worth making is a rationale line for `parallel` in the header's "Local changes" list, matching the file's convention for local additions to this enforcement file. The remaining open point, the package's dependency closure and any setuid files or services it brings, is a live check that belongs with the Q-084 step-4 rebuild the commit already defers to. Endorsement claims are pending execution verification for the parts that need the rebuilt image.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-q086/docs/reviews/q086-security-review-2026-09-28.md, structured per the security-reviewer skill.
- Answered: yes
- Out of scope: package-index lookups and image rebuild (no egress, no Docker); Q-090's future run-tests.sh `--jobs` change (not in this diff).
- Escalate: add the Finding 2 checks (`apt-cache depends parallel`, setuid diff against the baseline listed) to the Q-084 step-4 live verification. The fact-check's escalation also applies: 1ef3090 and bb9982f carry the same subject, so reconcile which one lands.
- Decisions I made: rated the missing rationale Informational rather than Low/Medium because no security property is violated. The floor rule needs a mechanism, and there is none. I treated the sandbox as the current image, based on `/etc/cc-config-hash` and `/etc/sudoers.d/node-firewall` being present.
