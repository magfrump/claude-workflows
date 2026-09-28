Commit: ed28f76

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q086 (branch `review/q086`)
**Scope:** Stage 2.5 submitted claims only (k=1), from `docs/reviews/q086-security-review-2026-09-28-final.md`. No harvesting from the diff. Numbering continues from `q086-code-fact-check-report-final.md` (ends at claim 20).
**Checked:** 2026-09-28
**Total claims checked:** 2
**Summary:** 1 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

---

## Submitted Claims

## Claim 21: "Adding `parallel` does not widen node's root path. The only sudo grant is a bare, env-reset invocation of `init-firewall.sh`, and no root-run script in `devcontainer-config/` invokes `parallel`, `sem` or `niceload`."

**Submitted by:** security-reviewer
**Location:** `devcontainer-config/Dockerfile:528`, `devcontainer-config/devcontainer.json:141`
**Type:** Security / configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed (sudo listing, word-boundary grep) + static (Dockerfile, devcontainer.json, init-firewall.sh read)
**Scope:** Covers the sudoers grant written at build (Dockerfile:528-529, whole RUN instruction read), the live sudo policy in this sandbox (a build of the current image), every lifecycle command in `devcontainer.json`, and every script in `devcontainer-config/` including `init-firewall.sh` and the programs it runs as root. Does not cover the rebuilt image (cannot be built here), setuid binaries shipped by the base image, or build-time `RUN` steps (these run as root but do not invoke `parallel` either — grep below).
**Legibility-target:** security-reviewer's "What Looks Good" endorsement; the orchestrator's rubric.

Evidence, per root-run path:

1. **Sudoers.** The Dockerfile's only grant (Dockerfile:528, inside the RUN at 519-529):
   ```
   printf '%s\n' 'Defaults:node env_reset, !setenv' 'node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh ""' > /etc/sudoers.d/node-firewall && \
   ```
   Executed `sudo -n -l` as `node` (uid 1000) in this sandbox: `(root) NOPASSWD: /usr/local/bin/init-firewall.sh ""`, Defaults `env_reset, … secure_path=…, env_reset, !setenv`. `/etc/sudoers.d/` holds only `README` and `node-firewall`. The trailing `""` restricts the grant to a no-argument invocation.
2. **Lifecycle commands.** `devcontainer.json:141`: `"postStartCommand": "sudo /usr/local/bin/init-firewall.sh && /usr/local/bin/link-claude-home.sh"`. The only sudo is the bare firewall call; `link-claude-home.sh` runs as `node`. No `postCreate`/`onCreate`/`updateContent`/`initializeCommand` exists (grep). The image has no `ENTRYPOINT`/`CMD` and finishes with `USER node` (Dockerfile:531).
3. **init-firewall.sh's own invocations.** It pins `PATH` to `/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin` (line 38; `CC_FIREWALL_PATH` is stripped by env_reset). Its root-run programs are iptables, ipset, dig, curl, runuser, dnsmasq and `cc-sni-proxy.py` (comment at lines 32-33, `SNI_PROXY_BIN` at 619). `rg -wn "parallel|sem|niceload"` over `init-firewall.sh cc-sni-proxy.py link-claude-home.sh devcontainer.json install.sh cc-*.sh` returned no matches (rc=1). The Dockerfile's only `parallel` hits are the header comment (line 4) and the package list (line 43).

`parallel` lands in `/usr/bin` (root-owned). Nothing runs it as root, and sudo's env_reset strips `$PARALLEL`, so node's config cannot reach a root process. The claim holds for the current source. The rebuilt image's sudoers is produced by the same unchanged line, so the claim should carry over, but that could not be observed here.

**Evidence:** `devcontainer-config/Dockerfile:502-531`, `devcontainer-config/devcontainer.json:141-142`, `devcontainer-config/init-firewall.sh:25-38,619`, `sudo -n -l` output, `ls /etc/sudoers.d/`

---

## Claim 22: "The capabilities `parallel` gives node (spawning commands, remote exec over ssh, config from `$PARALLEL`/`~/.parallel`) were already available to node through binaries in the current image."

**Submitted by:** security-reviewer
**Location:** `devcontainer-config/Dockerfile:43`
**Type:** Security / capability equivalence
**Verdict:** Mostly accurate
**Confidence:** High (for the current image); rebuilt image not testable
**Verification mode:** executed (`command -v`, `perl -e system`, `ssh -V`, `dpkg -S`, run as `node` in this sandbox)
**Scope:** Covers the binaries on node's PATH in the current image (the sandbox is a build of it). Does not cover the rebuilt image. Does not check whether egress rules permit any ssh destination, which bounds the practical reach of ssh for both `ssh` and `parallel`.
**Legibility-target:** security-reviewer's "What Looks Good" endorsement; the orchestrator's rubric.

Executed as `uid=1000(node)`:

- `command -v`: `perl` → `/usr/bin/perl` (perl-base), `ssh` → `/usr/bin/ssh` (openssh-client, `OpenSSH_9.2p1 Debian-2+deb12u10`), `xargs` → `/usr/bin/xargs` (findutils), `bash`, `sh`, `nohup` and `setsid` are all present. `parallel`, `sem` and `niceload` are MISSING, as the shared block expects.
- `timeout 5 perl -e 'system("true")'` → `perl system ok`. GNU parallel is a Perl script, so every command it can spawn, node can already spawn through the same interpreter. Concurrency is already available through `xargs -P` and bash `&`, and remote exec through `/usr/bin/ssh` directly.
- `openssh-client` is not in the Dockerfile's own apt list (grep for `openssh`/`ssh-client` found nothing), so it comes from the `node:22` base image. It is still "in the current image", as the claim says.

Why this is Mostly accurate rather than Verified: the "config from `$PARALLEL`/`~/.parallel`" part is equivalent in kind, not literally "already available". No existing binary reads those paths. The relevant fact is that node already controls equivalent inputs (`~/.bashrc`, `BASH_ENV`, `PERL5OPT`, `~/.ssh/config`, all node-writable or node-settable), and a node-owned `~/.parallel` only affects `parallel` runs by node (Claim 21: none run as root). Suggested tightening: "…config from `$PARALLEL`/`~/.parallel` only influences node's own runs, as node-controlled `~/.bashrc`/`PERL5OPT`/`~/.ssh/config` already do." `~/.ssh` does not exist in the sandbox, which does not affect the capability.

**Evidence:** executed output above; `devcontainer-config/Dockerfile:14` (`FROM node:22`), `:20-46` (apt RUN, read in full)

---

## Claims Requiring Attention

### Mostly Accurate
- **Claim 22** (`devcontainer-config/Dockerfile:43`): the spawn/ssh parts are verified. The `$PARALLEL`/`~/.parallel` config part is equivalent in kind, not literally pre-existing, so reword it to say it only affects node's own runs.

### Unverifiable
- None. Both claims were checked against the current image. The rebuilt image needs a host check (it cannot be built here), but neither verdict depends on it beyond the unchanged sudoers line.

---

## Goal-Alignment Note

- **Answered:** both submitted security-reviewer endorsements were verdicted as claims 21-22. Claim 21 is Verified: the one sudo grant is bare, env-reset `init-firewall.sh`, and no root-run path invokes `parallel`/`sem`/`niceload`. Claim 22 is Mostly accurate: the config sub-clause is overstated as "already available".
- **Out of scope:** no fresh claims were harvested from the diff. The settled findings (A2, B1, C1-C6) were not revisited. Base-image setuid binaries and egress reachability over ssh were not checked.
- **Escalate:** none. Rebuilt-image behaviour remains a host check, consistent with C1/C3.
