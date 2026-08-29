# Security Review — init-firewall.sh egress hardening (SSH removal + DNS scoping)

Commit: c44c33a (+ working-tree fix)
**User goal:** Review the firewall-boundary hardening in `devcontainer-config/init-firewall.sh` before a local merge — removing the blanket outbound-SSH accept and scoping outbound DNS to the resolvers in `/etc/resolv.conf`. Threat model: a compromised in-container agent trying to exfiltrate data or reach an attacker host. Confirm the change does not open a new hole or weaken the boundary.

**Scope:** `devcontainer-config/init-firewall.sh` (commit `c44c33a` + the working-tree `|| true` fix on line 114), read against `devcontainer-config/Dockerfile`, `devcontainer.json`, `egress/*.txt`, and the threat-model doc `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md`.
**Date:** 2026-08-29
**Based on:** the k=3 fact-check summarized in the task brief (GitHub SSH survives the dport-22 removal; the DNS fail-open `else` was unreachable under `set -euo pipefail` until the `|| true` fix). Those facts are taken as established and built upon, not re-verified.

> ⚠️ **No formal code-fact-check report file was provided.** A fact-check *summary* was supplied in the task brief and is treated as the verified foundation. Comment claims not covered by that summary were checked against the code directly.

## Trust Boundary Map

```
B1: [/etc/resolv.conf contents]      → [awk 'nameserver' + IPv4 regex + sort -u]  → [iptables -A OUTPUT -d $ns --dport 53 ACCEPT]   (new)
B2: [in-container agent `node`]       → [NOPASSWD sudo: init-firewall.sh only]     → [re-applies firewall from current resolv.conf]  (interaction is new)
B3: [agent outbound sockets]          → [OUTPUT chain: DNS-scope / allowed-domains dst / REJECT] → [network]  (SSH exception removed)
```

- **B1 (new):** the diff makes `/etc/resolv.conf` *content* load-bearing for the shape of the firewall. Before the patch the resolver list was irrelevant to egress (blanket `--dport 53`); now the set of admitted DNS destinations is derived from that file. resolv.conf is thus a fresh input to the boundary-building code, filtered only by an IPv4 shape regex.
- **B2:** `node` holds `NOPASSWD` sudo for exactly `init-firewall.sh` (Dockerfile:398). It can re-run the firewall at will, re-reading resolv.conf each time. This pre-existing capability now *interacts* with B1: the resolver set is re-derived on every agent-triggered re-run.
- **B3:** the egress boundary itself. The SSH exception (`--dport 22` to `0.0.0.0/0`) is removed; SSH to allowlisted dst IPs still traverses via the `allowed-domains` dst-match (line 224).

Every finding below anchors to one of these labels.

## Findings

#### Fail-open branch reinstates the exact channel the patch removes — and widens it to TCP
**Severity:** Medium
**Location:** `devcontainer-config/init-firewall.sh:121-125`
**Boundary:** B1, B3
**Move:** #3 (check the error/degraded path) · #5 (invert: what does the fallback *permit*?)
**Confidence:** Medium

When the IPv4 regex matches zero resolvers, the `else` branch installs a blanket accept to **any** host:

```sh
echo "WARNING: no IPv4 nameserver in /etc/resolv.conf — allowing DNS to any host (unscoped)" >&2
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
```

This is precisely the "point a socket at `attacker_ip:53` and stream data in the query names" channel the change exists to close (B3). It fires whenever resolv.conf is IPv6-only or contains no parseable IPv4 `nameserver` — realistic under a v6-only Docker network or a `--dns` override. The warning goes to stderr in the middle of `postStartCommand`, where nobody is watching, so the boundary silently degrades to the pre-patch posture with no failed probe (the end-of-script probes test reachability of example.com/GitHub, not DNS scope). Note also this branch adds blanket **TCP/53**, which the *original* pre-patch rule never had (it was `udp` only) — the degraded state is strictly wider than what shipped before.

A fail-*closed*-but-not-bricking middle ground exists and is cheap: in the Docker default case the resolver is the embedded `127.0.0.11`, already reachable via the `-o lo` accept (line 140); falling back to `-d 127.0.0.11 --dport 53` (or the detected `HOST_NETWORK`, already accepted on line 212) preserves resolution for the common case without re-opening 0.0.0.0/0. Fail-open to *any host* should be the last resort, not the first.

**Recommendation:** Replace the `0.0.0.0/0` fallback with a scoped one: allow DNS to `127.0.0.11` and/or `$HOST_NETWORK` and only then, if even that cannot be determined, fall through to unscoped with the warning. At minimum, drop the blanket TCP/53 from the fallback so the degraded state is no wider than the pre-patch rule.

#### Out-of-range octet in a resolver line aborts the script in the wide-open window
**Severity:** Medium
**Location:** `devcontainer-config/init-firewall.sh:114,118-119`
**Boundary:** B1
**Move:** #2 (validate content, not just shape) · #3 (error path)
**Confidence:** Low (exploitability gated on resolv.conf write access; impact if triggered is total)

The resolver filter validates *shape* but not *range*: `^[0-9]{1,3}(\.[0-9]{1,3}){3}$` accepts `999.999.999.999` and `256.1.1.1`. Such a value passes the `if [ -n ... ]` guard and is handed to `iptables -A OUTPUT -p udp -d "$ns" --dport 53`. iptables cannot parse an out-of-range dotted quad, falls back to treating it as a hostname, fails to resolve it, and exits non-zero. Under `set -euo pipefail` that aborts the script **after the flush (line 74) but before `-P OUTPUT DROP` (line 217)** — leaving the OUTPUT policy at its default `ACCEPT`, i.e. the container fully open, with the script dead and no probe reached. This is the exact "brick open" hazard the rest of the file guards against deliberately: the GitHub-CIDR loop and the domain-resolution loop both use `ipset add -exist` and strict validation with explanatory comments (lines 165-167, 194) precisely to avoid dying in this window. The new DNS loop has no such guard and no `|| true` on the iptables calls.

Likelihood is low because a benign resolv.conf never contains out-of-range octets, and resolv.conf is root-owned (see next finding) — so triggering it requires the same write access that would already be game-over. But the failure mode is the worst available (default-ACCEPT egress), and it is a regression from the defensive standard the file otherwise holds.

**Recommendation:** Either tighten the regex to a real 0–255 octet match, or make the per-resolver iptables calls non-fatal in the dangerous window (e.g. append `|| echo "WARNING: could not add DNS rule for $ns" >&2` and continue), so a malformed entry degrades gracefully instead of leaving the policy at ACCEPT. Reordering so `-P OUTPUT DROP` is set *before* the accept rules are appended would also eliminate the wide-open window for the whole script.

#### DNS scoping now depends on `/etc/resolv.conf` integrity — an assumption the script neither states nor enforces
**Severity:** Low
**Location:** `devcontainer-config/init-firewall.sh:113-120`
**Boundary:** B1, B2
**Move:** #1 (new trust dependency) · #4 (re-run TOCTOU via NOPASSWD sudo)
**Confidence:** Medium

The patch converts resolv.conf from a security-irrelevant file into an input that determines which DNS destinations the firewall admits (B1). The agent `node` can re-run the firewall through `NOPASSWD` sudo (Dockerfile:398 — `node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh`) (B2). If resolv.conf were ever agent-writable — a future volume mount, a misconfiguration, or a `--dns`/`--dns-search` value the agent can influence — a compromised session could write `nameserver <attacker_ip>`, re-run the firewall, and obtain a *scoped* `-d attacker_ip --dport 53 ACCEPT` rule: the direct-exfil channel restored through the front door, this time looking legitimate.

In the current build this is not exploitable: resolv.conf is Docker-managed and root-owned, and `node` is non-root, so it cannot write the file. The finding is that the change silently takes on this dependency without documenting it or asserting it (e.g. no check that resolv.conf is root-owned). Under the old blanket rule this attack surface did not exist. Worth recording so a later change to how DNS is configured (host `--dns` flags, a resolver sidecar, an overlay mount) doesn't quietly hand the agent a resolver-poisoning primitive.

**Recommendation:** Add a one-line comment pinning the assumption ("safe only while /etc/resolv.conf is root-owned and not agent-writable") next to the block, mirroring the H2/H6 immutability notes elsewhere. Optionally assert it: skip resolver-scoping and warn if `stat -c %U /etc/resolv.conf` is not `root`.

#### `|| true` cannot distinguish "zero resolvers" from a grep/awk error — both fail open
**Severity:** Informational
**Location:** `devcontainer-config/init-firewall.sh:113-114`
**Boundary:** B1
**Move:** #3 (error path)
**Confidence:** High

The working-tree fix (`... | sort -u || true`) is correct and load-bearing: without it, `grep` exiting 1 on zero matches propagates through `pipefail` to the `dns_resolvers=$(...)` assignment and aborts under `set -e` — in the post-flush/pre-DROP window, exactly the brick the fail-open branch is meant to prevent, and it also made that branch unreachable. Good fix. The residual nuance: `|| true` swallows *all* non-zero pipeline statuses, so a genuine grep error (exit 2, bad regex/read error) is indistinguishable from "no IPv4 resolver" (exit 1) — both land in the fail-open `else`. Given the deliberate fail-open philosophy this is acceptable, but it means a malformed-command bug in this line would degrade the boundary silently rather than surface. Non-blocking.

**Recommendation:** None required. If you want to be strict, capture the exit status explicitly (`rc=$?`) and only treat `rc<=1` as "no resolvers," letting `rc>=2` be a hard error — but this trades a little availability for signal and is a judgment call.

## What Looks Good

- **SSH removal introduces no gap (B3).** Removing the blanket `--dport 22` accept does not break GitHub SSH: GitHub CIDRs are added unconditionally to `allowed-domains`, and `-A OUTPUT -m set --match-set allowed-domains dst -j ACCEPT` (line 224) matches the destination on *any* port, including 22; the general `-A OUTPUT/INPUT -m state --state ESTABLISHED,RELATED` accepts (lines 220-221) cover the return path. The removed inbound `--sport 22 --state ESTABLISHED` rule was redundant with the general INPUT ESTABLISHED accept, so its removal loses nothing. No setup step depends on outbound SSH — `postStartCommand` is `sudo init-firewall.sh && link-claude-home.sh`, and the self-probes use HTTPS (example.com, api.github.com/zen), not SSH.
- **DNS scoping is honestly represented.** The comment (lines 96-103) correctly states that scoping closes only the *direct* socket-at-attacker-NS path and explicitly does **not** close recursive-forward tunnelling (`<data>.attacker.com` via the legitimate resolver). No over-claim; the residual is named and cross-referenced to the threat-model doc.
- **Rule ordering is sound.** The per-resolver accepts are appended to OUTPUT ahead of the `allowed-domains` accept and the terminal REJECT, and iptables evaluates in order, so DNS to a scoped resolver is admitted before REJECT. Setting `-P OUTPUT DROP` (line 217) later does not shadow earlier accept rules (policy is terminal only when no rule matches). No shadowing.
- **Injection is adequately contained.** `$ns` is constrained to `[0-9.]` by the anchored regex before reaching the quoted `iptables -d "$ns"`, so no shell metacharacter or argument-injection path exists. (The residual is the *range* gap in finding #2, not an injection.)

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Fail-open branch reinstates blanket DNS (and adds TCP/53) | Medium | B1, B3 | `init-firewall.sh:121-125` | Medium |
| 2 | Out-of-range octet aborts script in wide-open window | Medium | B1 | `init-firewall.sh:114,118-119` | Low |
| 3 | Undeclared dependency on resolv.conf integrity (+ NOPASSWD re-run) | Low | B1, B2 | `init-firewall.sh:113-120` | Medium |
| 4 | `\|\| true` masks grep/awk error as "no resolvers" | Informational | B1 | `init-firewall.sh:113-114` | High |

## Overall Assessment

Net positive and safe to merge locally. The two intended hardenings are real: the SSH removal closes a genuine unconditional tunnel with no collateral (GitHub SSH survives via dst-match), and DNS scoping closes the direct socket-at-attacker-NS exfil path while honestly disclaiming the recursive-forward residual. The change does not weaken the boundary in the nominal (Docker default, IPv4 `127.0.0.11` resolver) case. IPv6 remaining unfiltered (no `ip6tables` anywhere in the script) is a pre-existing gap this diff neither creates nor worsens, but it is the reason the IPv6-only fail-open path (finding #1) is worth closing.

Every finding is fixable in place — none indicates an architectural problem with the patch. The single most important item is **finding #1**: the fail-open `else` should degrade to `127.0.0.11`/`$HOST_NETWORK` rather than `0.0.0.0/0`, so the one path that silently hands back the removed channel is closed. Findings #2 and #3 share a root theme worth a follow-up: this file has several "abort after flush, before DROP = brick open" hazards, and the cleanest structural fix is to set `-P OUTPUT DROP` *before* appending accept rules, removing the wide-open window entirely.

## Goal-Alignment Note

The change advances the stated goal — hardening the compromised-agent egress boundary — without regressing it in the common case, so it is aligned with the user's intent to tighten the sandbox before merge. The one place the goal and the code diverge is the fail-open `else` (finding #1): the user's aim is to *remove* the direct-DNS-exfil channel, but the fallback re-grants exactly that channel (wider, on TCP too) whenever no IPv4 resolver parses — an availability-over-security default that undercuts the change's purpose in the precise degraded case an attacker could try to induce. Closing that path aligns the code with the goal; the remaining findings are hardening of the new resolv.conf trust dependency the goal implicitly took on.
