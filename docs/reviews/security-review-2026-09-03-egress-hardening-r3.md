# Security Review — egress hardening pass 3, 2839e59..1434fc9

Commit: 1434fc9

**Scope:** `git diff 2839e59..1434fc9 -- devcontainer-config/` — `init-firewall.sh`, `Dockerfile`, `cc-sni-proxy.py`. Third review pass over the second fix round (6eaa9a0, 1434fc9), verifying the six r2 findings and reviewing the new code as attack surface. `test/*.bats`, `docs/reviews/*` and `docs/working/questions.md` in the range are committed context, read to avoid false "missing" claims and not adjudicated. Threat model unchanged: a compromised in-container agent (uid `node`, NOPASSWD sudo for exactly `/usr/local/bin/init-firewall.sh`) trying to exfiltrate or reach an attacker host.
**Date:** 2026-09-03
**Based on:** `docs/reviews/security-review-2026-09-03-egress-hardening-r2.md` and the k=1 loop-pass `docs/reviews/code-fact-check-report.md` (16 Verified / 1 Stale / 1 Mostly accurate on 6eaa9a0; the Stale item is the Dockerfile ownership comment, fixed in 1434fc9).

No HALT-class pattern was detected in the diff: no plaintext credential added, no TLS verification disabled, no unauthenticated privileged endpoint, no new user-facing SQL/command-injection sink.

Two framing notes before the tables. First, this round is materially better than the last: the Critical is closed at the image *and* asserted at runtime, the resolver-grammar fail-safe is restored and executed, the lock is moved out of a namespace `node` can reach, the probe's evidence channel is scoped so a loopback forgery no longer satisfies it, and the IPv6 posture is decided as a precondition with the dangerous combination made fatal before the flush. All 59 cases in `test/init-firewall-rules.bats` pass in this sandbox, including the five new negative cases. Second, everything filed below is Low: the residuals are scope and timing edges around controls that now exist, not holes in them. The remaining blocker on the boundary is not in this range — it is the live-container verification still tracked in `docs/working/questions.md`, without which the redirect/ipset/guard-chain endorsements stay read-static.

---

## Prior findings status

| r2 # | Finding | Status | Evidence |
|---|---|---|---|
| 1 | `/usr/local/share` node-owned → agent can replace `cc-egress` and have the firewall install its own allowlist | **closed** — the build-time chown is narrowed to `npm-global`, `cc-egress` is defensively re-chowned root, and the script now refuses to run unless `EGRESS_DIR` and its parent are uid 0 and not group/world-writable. Residual scope in N4. | `Dockerfile:59-66`, `:419`; `init-firewall.sh:302-311` |
| 2 | Single-label profile entry becomes a whole-TLD resolver zone | **closed** — one `HOST_RE` shared by `parse_entry` and `compose_dnsmasq_conf`, requiring ≥2 labels; executed below. `com:443` is now a hard `malformed egress entry` abort and emits no `server=` line. | `init-firewall.sh:121-140`, `:216-222`; `test/init-firewall-rules.bats:853-865` |
| 3 | Negative-probe log evidence forgeable over loopback; redirect rule unasserted | **closed for the filed mechanism, residual for its siblings** — the grep now requires `orig_dst=$ANTHROPIC_PROBE_IP:443`, which a direct 127.0.0.1:3443 connection cannot produce, and `iptables -t nat -C OUTPUT -p tcp --dport 443 -j CC_SNI` asserts the jump. `CC_SNI_GUARD`, the `REDIRECT` inside `CC_SNI`, and both DNS guard chains are still unasserted — N2. | `init-firewall.sh:1062-1082`; `cc-sni-proxy.py:157-160` |
| 4 | `node` can hold the firewall lock and veto every re-assert | **closed** — the lock moved to `/run/cc-firewall/lock` in a 0700 root directory, file chmod 0600, wait value numerically validated. `node` cannot open the file, so it cannot take the advisory lock. New residual from the same edit in N1. | `init-firewall.sh:523-544`; `test/init-firewall-rules.bats:906-916` |
| 5 | IPv6 default-deny best-effort; its absence warns rather than gates | **closed for the dangerous case** — the posture is decided in phase A: usable table → default-deny; no table **and** a global IPv6 address → `exit 1` before the flush; no table and no address → warn. Point-in-time residual and the missing `-w` in N3. | `init-firewall.sh:500-518`, `:576-594` |
| 6 | Main-path `iptables`/`ipset` take no `-w` | **open, accepted** — unchanged in this range, and the new `iptables -t nat -C` at `:1074` follows the same pattern. Carried forward, not re-filed. | `init-firewall.sh:1074` and the phase-B rebuild generally |

No prior finding regressed. One fix (the lock's move to phase B) introduced a new, narrower concurrency residual — N1.

---

## Trust Boundary Map

```
B1: host shell env (GH_TOKEN, OPENROUTER_API_KEY)
      → devcontainer.json containerEnv → every process env, incl. `node`     (unchanged)

B2: host-side config dir → cc-isolated.sh check_manifest() → image build
      → /usr/local/bin, /usr/local/share/cc-egress                           (unchanged this range)

B3: agent (uid node) → `sudo /usr/local/bin/init-firewall.sh` (NOPASSWD, ANY ARGS)
      → root execution with a script-pinned PATH
      → also reaches the --print-* hooks, which take a caller-supplied PATH
        argument and run BEFORE the new ownership assertion                  (N5, pre-existing)

B3a: agent (uid node) → /usr/local/share
      ✓ CLOSED: only /usr/local/share/npm-global is node-owned; cc-egress and
        its parent are root, and the script asserts both at every run         (was r2-F1 Critical)

B4: agent network syscalls → nat/filter OUTPUT → outside world
      → IPv4 as before; IPv6 default-denied where a filter table exists,
        fatal where a global v6 address exists without one, warn otherwise   (moved)

B5: attacker-influenced ClientHello on 127.0.0.1:3443 → parse_sni →
      Allowlist.allows → getaddrinfo → open_connection                       (unchanged)

B6: /run/cc-firewall/lock (root 0600 in a root 0700 dir)
      ✓ CLOSED to `node`: the directory mode denies open(2), so the advisory
        lock cannot be taken by a non-root uid
      → but the critical section now covers phase B ONLY, so a second run's
        phase A resolves against a mid-rebuild network                       (N1, new)

B7: /run/cc-sni-proxy/proxy.log (root 0644, dir 0755) → the completion gate
      ✓ the orig_dst= discriminator is now used, so a line `node` can cause
        over loopback no longer satisfies the grep; causing a MATCHING line
        requires the redirect the gate is proving                            (was r2-F3)
```

| S | Source | Mutability class | Trust per sink class |
|---|--------|------------------|----------------------|
| S1 | `/etc/resolv.conf` | Docker-runtime-mutable, root-owned | Unchanged: untrusted toward `iptables -d` and `server=/…/<ns>`, constrained by octet validation. Also reachable as an *arbitrary path* through the `--print-*` hooks (N5). |
| S2 | `/usr/local/share/cc-egress/*.txt` | Root-owned 0444 in a root-owned 0555 dir, under a root-owned parent — **corrected again, and now asserted at use** | Grammar-validated by `parse_entry`; provenance now checked by the ownership assertion at `:302-311`. The assertion covers the directory and one parent, not the files' own modes (N4). |
| S3 | `api.github.com/meta` JSON | Remote | Unchanged: shape- and regex-validated before `ipset add`. |
| S4 | DNS A records | Remote, cache-lifetime | Unchanged; now resolvable outside the lock while another run rebuilds (N1). |
| S5 | SNI in a ClientHello at 127.0.0.1:3443 | Fully attacker-controlled per connection | Untrusted toward `getaddrinfo`/`open_connection`. **No longer trusted toward the completion gate**: the gate keys on `orig_dst`, which the kernel supplies from conntrack, not on the attacker-supplied name alone. |
| S6 | `/run/cc-sni-proxy/*`, `/run/cc-dnsmasq.pid` | Root-written, node-readable | Unchanged. |
| S7 | `CC_*` env vars | Caller-controlled | Neutralised by sudo `env_reset` + no `SETENV` on the sudoers rule. Still asserted only in comments — and the new ownership assertion's skip condition (`CC_EGRESS_DIR` unset) is now one of the things that rests on it (N4). |
| S8 | `/run/cc-firewall/lock` and its directory | Root-created, 0600 in 0700 | Sound against `node`. Directory *ownership* is not asserted, only its mode is set — safe because `/run` is root 0755 (traced, not observed in the image). |
| S9 | Argument vector of the sudo grant | Fully agent-controlled: `node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh` names no arguments | Untrusted toward the `--print-resolvers` / `--print-dnsmasq-conf` path parameter, which becomes a root-privileged read (N5). |

The direction of travel is right: every boundary this range touches moved toward "checked at use, not assumed at build". The one boundary that *widened* is B6 — deliberately, and in exchange for a shorter critical section — and what it admits is a narrowing of a concurrent run's allowlist, not an egress path.

---

## Findings

#### Phase A now runs outside the lock, so a concurrent rebuild can silently narrow a legitimate run's allowlist

**Severity:** Low
**Location:** `devcontainer-config/init-firewall.sh:523-544` (the moved lock), consumed at `:388-432` (the resolution loop's warn-and-skip)
**Boundary:** B6, B3
**Move:** 4 (TOCTOU / shared-namespace resource), 3 (check the error path), 11 (enumerate bypasses)
**Confidence:** Medium (the ordering is read-static and pinned by a bats case; the interleaving itself is not executed — it needs a live resolver)
**Evidence:**
> # ONE REBUILD AT A TIME. `node` can start this script whenever it likes (NOPASSWD
> `# sudo), including twice at once. Two interleaved rebuilds can each pass their own`
> `# probes while one has flushed the other's half-built guard chains out from under`
> `# it, and the survivor then completes "successfully" with the DNS guards missing.`
> `# Serialise phase B on a root-owned lock. Phase A (network reads, no rule changes)`
> `# deliberately runs OUTSIDE the lock: concurrent phase-A runs are harmless, and`
> `# keeping the critical section to the ~sub-second rebuild means a waiting run is`
> `# never held for the length of a slow resolution.`
> (… remainder of the comment block not shown: it covers the 0700 directory, the trap ordering, and the two test-only env vars, then the `FIREWALL_LOCK` assignments follow.)

and the handling a mid-rebuild resolution reaches:
> `    if [ -z "$ips" ]; then`
> `        if [ "$domain" = "api.anthropic.com" ]; then`
> `            echo "ERROR: Failed to resolve critical domain $domain" >&2`
> `            exit 1`
> `        fi`
> `        echo "WARNING: Failed to resolve $domain - skipping (stays blocked)"`
> `        continue`
> `    fi`

**Legibility-target:** for-author
The comment's claim is that concurrent phase-A runs are harmless. That is true of two phase-A runs against each other, but the case that matters is a phase A concurrent with somebody else's **phase B**: the rebuild stops dnsmasq, flushes nat, and restarts the resolver, and every `dig` issued during that window fails. The failures are handled exactly as the statsig incident taught the script to handle them — warn and skip — so the racing run then takes the lock and installs a *narrower* ipset than its profile grants, or, if `api.anthropic.com` is the domain that lost, exits into the fail-closed trap. Under the previous design the lock wrapped the whole script, so a second invocation waited and resolved against a settled boundary. `node` can trigger this at will (its NOPASSWD sudo is unmetered) against the launcher's own re-assert path in `cc-isolated.sh`, and the observable result is a working container with silently missing allowlist entries, reported as `WARNING` lines nobody reads. The direction is fail-closed and the impact is availability, not egress — hence Low — but the mechanism is new to this range and the comment asserts it does not exist. Failure mode: **a critical section narrowed past the data dependency it was protecting**.

**Recommendation:** Either state the residual in the comment (replace "concurrent phase-A runs are harmless" with the precise claim: they cannot corrupt each other's rules, but a phase A concurrent with another run's phase B may resolve against a torn network and narrow its own allowlist), or take a second, *shared* lock around phase A that phase B upgrades to exclusive, so a rebuild cannot start while a resolution is in flight. A cheap middle ground: after acquiring the lock, re-check that no domain was skipped, and if any was, abort rather than install the narrowed set — a re-run then resolves cleanly.

---

#### The completion gate asserts one of the five rules that make the boundary, so the others still gate nothing

**Severity:** Low
**Location:** `devcontainer-config/init-firewall.sh:1074-1082`, against the rules installed at `:798-813`, `:837-839`, `:1001-1015`
**Boundary:** B7, B4
**Move:** 3 (check the error path), 12 (sweep call sites), 11 (enumerate bypasses)
**Confidence:** High (the asserted string was compared character-by-character against the appended rule; the unasserted rules were enumerated by grep over the file)
**Evidence:**
> `if ! iptables -t nat -C OUTPUT -p tcp --dport 443 -j CC_SNI; then`
> `    echo "ERROR: Firewall verification failed - the tcp/443 redirect to the SNI proxy is not installed"`
> `    exit 1`
> `fi`
> `if ! grep -q "REJECT sni=not-allowlisted.invalid orig_dst=$ANTHROPIC_PROBE_IP:443" "$SNI_LOG" 2>/dev/null; then`
> `    echo "ERROR: Firewall verification failed - the SNI proxy did not log a redirected refusal for not-allowlisted.invalid (see $SNI_LOG)"`
> `    exit 1`
> `fi`
> `echo "Firewall verification passed - non-allowlisted SNI refused by the proxy (logged)"`

against the sibling rules nothing checks:
> `iptables -A OUTPUT -p tcp --dport 443 -j CC_SNI_GUARD`
> `iptables -A OUTPUT -d 127.0.0.11 -j CC_DNS_GUARD`
> `iptables -A OUTPUT -p udp --dport 53 ! -d 127.0.0.1 -j CC_DNS_GUARD`
> `iptables -A OUTPUT -p tcp --dport 53 ! -d 127.0.0.1 -j CC_DNS_GUARD`

**Legibility-target:** for-author
The `-C` string is byte-identical to the `-A` at `:1005`, so the assertion is real and the new bats case (`NO_REDIRECT`) proves it fails closed when the rule is absent. What it does not cover is the rest of the guard set. `CC_SNI_GUARD` is the filter-side rule that stops `node` from reaching tcp/443 *around* the redirect; the `CC_DNS_GUARD` jumps are what stop it talking to 127.0.0.11 or an external resolver directly — which is the whole recursive-forward story. Each of those is installed under `set -e`, so a failure aborts into the trap, and the practical way they could be missing is exactly the interleaving the lock now prevents. So this is a defence-in-depth gap, not a live hole, and Low is the honest severity. It is filed because r2's recommendation named `CC_SNI_GUARD` explicitly and only half of it was implemented, and because a completion sentinel that checks one rule reads, to a later maintainer, as one that checks the ruleset. Failure mode: **a verification step whose coverage is narrower than the claim its success message makes**.

**Recommendation:** Add the four remaining `-C` assertions next to the existing one (`-C OUTPUT -p tcp --dport 443 -j CC_SNI_GUARD`, and the three `CC_DNS_GUARD` jumps), and give them `-w 5` along with the existing `-C` so a contended xtables lock is a wait rather than a spurious "not installed". Then reword the success line to name what was verified.

---

#### The IPv6 posture is a point-in-time phase-A decision that nothing re-checks, and phase B's `ip6tables` calls still take no `-w`

**Severity:** Low
**Location:** `devcontainer-config/init-firewall.sh:500-518`, `:576-594`, `:1087`
**Boundary:** B4
**Move:** 4 (TOCTOU), 3 (check the error path), 11 (enumerate bypasses)
**Confidence:** Medium (`ip -6 addr show scope global` emptiness verified in this sandbox; the Docker-Desktop no-table kernel and the late-address case are traced, not executed)
**Evidence:**
> `IP6_FILTER=0`
> `if command -v ip6tables >/dev/null 2>&1 && ip6tables -w 5 -S OUTPUT >/dev/null 2>&1; then`
> `    IP6_FILTER=1`
> `elif [ -n "$(ip -6 addr show scope global 2>/dev/null || true)" ]; then`
> `    echo "ERROR: this container has a global IPv6 address but no usable ip6tables filter" >&2`
> `    echo "       table — IPv6 egress could not be closed, so the allowlist would have a" >&2`
> `    echo "       bypass. Disable IPv6 for the container or enable the ip6_tables module." >&2`
> `    exit 1`
> `fi`
> (… this is the complete `--- IPv6 preconditions ---` block; the next line is the PHASE B banner.)

and the consumer, which no longer re-derives anything:
> `if [ "$IP6_FILTER" = "1" ]; then`
> `    ip6tables -P INPUT DROP`
> (… remainder of the `if` branch not shown: `-P FORWARD/-P OUTPUT` DROP, `-F`, `-X`, the four loopback/established accepts, and the success echo.)
> `else`
> `    echo "WARNING: no usable ip6tables filter table and no global IPv6 address — IPv6 left unconfigured" >&2`
> `fi`

**Legibility-target:** for-author
This is the right shape and it closes the r2 finding's dangerous branch: address-without-filter is now fatal *before* the flush, so the container never completes a run claiming an IPv6 posture it does not have. The discriminator is also the right one — link-local is excluded (a container with only `fe80::` cannot source traffic to a global destination), and a ULA `fd00::/8` counts as scope global, which errs conservative. Two residuals remain. The check is evaluated once per run: a `docker network connect --ipv6` after a successful `IP6_FILTER=0` run gives the container a routable address with `FIREWALL_COMPLETE=1` already set and no filter table to close it, and nothing re-asserts until the next `postStartCommand`. And the `-P`/`-F`/`-X`/`-A` calls in the phase-B branch still carry no `-w`, unlike the `-S` probe two hundred lines above them and unlike the trap's copies — the same r2-F6 pattern, here on a family whose rules are the last line of defence. Failure mode: **a precondition evaluated once and then treated as an invariant for the life of the container**.

**Recommendation:** Keep the phase-A decision (aborting before the flush is the point), and additionally re-evaluate `ip -6 addr show scope global` immediately after the phase-B IPv6 block: if `IP6_FILTER=0` and an address has appeared, abort into the trap rather than proceeding to `FIREWALL_COMPLETE=1`. Add `-w 5` to the `ip6tables` mutation calls, or route them through the same wrapper the r2-F6 recommendation proposed for IPv4.

---

#### The ownership assertion is scoped to two directories and skipped whenever `CC_EGRESS_DIR` is set, so its guarantee still rests on an unasserted sudo default

**Severity:** Low
**Location:** `devcontainer-config/init-firewall.sh:302-311`
**Boundary:** B3a, S2, S7
**Move:** 1 (trust boundaries), 2 (implicit sanitization assumption), 11 (enumerate bypasses)
**Confidence:** High for the mechanics (`stat`/`find` symlink semantics executed below); Medium for the residual, which depends on a distro default not observed in the built image
**Evidence:**
> `# The profile directory must be root-owned all the way up: directory WRITE`
> `# permission on a parent lets its owner rename or unlink a child regardless of the`
> `# child's own ownership, so a node-owned parent would let the agent swap the whole`
> `# profile tree and then run this script (its one sudo grant) to install its own`
> `# allowlist. Asserted on the image default only; CC_EGRESS_DIR is a test override`
> # that `node` cannot pass through sudo env_reset.
> `if [ -z "${CC_EGRESS_DIR:-}" ]; then`
> `    for d in "$EGRESS_DIR" "$(dirname "$EGRESS_DIR")"; do`
> `        if [ "$(stat -c '%u' "$d")" != "0" ] || [ -n "$(find "$d" -maxdepth 0 -perm /022)" ]; then`
> `            echo "ERROR: $d must be root-owned and not group/world-writable (the egress profiles live under it)" >&2`
> `            exit 1`
> `        fi`
> `    done`
> `fi`
> (… this is the complete block; the next statement is `ALLOWED_DOMAINS="$(compose_domains)"`.)

**Legibility-target:** for-author
The mechanics are sound, and better than they look. The check runs *after* the fail-closed trap and *before* `compose_domains`, so the TOCTOU window between assertion and read is real but only exploitable by someone with write permission on the parent — which is precisely what the assertion excludes. Symlink substitution fails closed twice over: GNU `stat` does not dereference by default, so a `node`-created symlink reports uid 1000, and `find -P` (the default) lstats the starting point, so a symlink's 0777 mode matches `-perm /022`. Both executed below. Three residuals. First, the walk stops at `dirname "$EGRESS_DIR"` — `/usr/local` and `/` are unchecked and are root-owned by construction in the `node:22` base image, which is a fair assumption but is now the *only* unasserted link in a chain the rest of which is asserted; say so in the comment or extend the loop to the root. Second, the assertion covers the directory, not the `*.txt` files' own ownership and modes — with the directory at 0555 root those cannot be replaced, so this is defence in depth rather than a hole. Third, and the one that actually carries the weight: the whole check is skipped when `CC_EGRESS_DIR` is set, and the reason `node` cannot set it is `Defaults env_reset` plus the absence of `SETENV` on the sudoers rule — which the loop-pass fact-check flagged as the one claim resting on a base-image default this repo never asserts. Failure mode: **a runtime assertion whose bypass condition is guarded by an assumption weaker than the assertion itself**.

**Recommendation:** Assert the sudo posture in the image rather than in comments: write the rule as `Defaults!/usr/local/bin/init-firewall.sh env_reset` (or add an explicit `env_delete`) in `/etc/sudoers.d/node-firewall`, and add a build- or launcher-time check that `sudo -l` reports no `SETENV`. Extend the ownership loop up to `/` (three more `stat` calls, no meaningful cost) and add the `*.txt` mode check while the loop is open. If the test override must stay, make it refuse to skip when the process euid is 0 and the parent of the override path is not root-owned.

---

#### The sudo grant names no arguments, so the `--print-*` hooks give `node` a root-privileged read of an arbitrary path — before the ownership assertion runs

**Severity:** Low
**Location:** `devcontainer-config/init-firewall.sh:108-111`, `:231-234`, `:302-311`; granted by `devcontainer-config/Dockerfile:424`
**Boundary:** B3, S9
**Move:** 1 (trust boundaries), 11 (enumerate bypasses)
**Confidence:** High (the hooks and the sudoers line are read-static and unambiguous; the leak's contents are bounded by the filter, executed as part of the resolver fixtures)
**Evidence:**
> `if [ "${1:-}" = "--print-resolvers" ]; then`
> `  compose_dns_resolvers "${2:-/etc/resolv.conf}"`
> `  exit 0`
> `fi`

and the second hook, which takes the same parameter and additionally composes the profile:
> `if [ "${1:-}" = "--print-dnsmasq-conf" ]; then`
> `  compose_dnsmasq_conf "$(compose_dns_resolvers "${2:-/etc/resolv.conf}")" "$(compose_domains)"`
> `  exit 0`
> `fi`

against the grant that reaches them:
> `  echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall && \`

**Legibility-target:** for-author
A sudoers rule that names a command with no argument list permits that command with *any* arguments, so `sudo /usr/local/bin/init-firewall.sh --print-resolvers <path>` is inside the grant. What comes back is narrow — `compose_dns_resolvers` runs `awk '/^[[:space:]]*nameserver/ {print $2}'` and then filters to dotted-quad IPv4 — so the disclosure is at most "does this root-only file contain a line beginning `nameserver` followed by an IPv4 address", plus whether the path exists (via awk's stderr). That is a weak primitive and it is pre-existing, not introduced here. It is filed now for two reasons: the hooks `exit 0` before the new ownership assertion at `:302`, so they are the one root-executing path in the script that no longer shares its provenance guarantee; and the grant's unbounded argument vector is the surface that would matter if a future hook ever prints something richer than filtered nameserver lines. Failure mode: **a privilege grant scoped to a program rather than to an invocation**.

**Recommendation:** Scope the sudoers rule to the invocation the agent actually needs — `node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh ""` (bare, no arguments) — and give the `--print-*` hooks a separate, non-sudo path for the tests, which already run them directly as the invoking user via `CC_EGRESS_DIR`. If the hooks must stay reachable under sudo, drop the caller-supplied path parameter and hard-code `/etc/resolv.conf`.

---

### Untested bypass candidates

**Ownership assertion (`:302-311`)** — (1) `node` replaces `cc-egress` by renaming it in a writable parent → **Tested (traced)**: `Dockerfile:65-66` now chowns only `npm-global`, `:419` re-chowns `cc-egress` root, and the runtime assertion would reject a node-owned parent regardless. (2) `node` substitutes a symlink for `cc-egress` or `/usr/local/share` → **Tested**: `stat -c %u` does not dereference (a node-owned link reports 1000) and `find -P … -perm /022` matches the link's 0777 mode; both branches abort. Executed in this sandbox. (3) TOCTOU between the assertion and `compose_domains` → **Tested (traced)**: the swap requires write on the parent, which the assertion excludes; the assertion precedes the read by seven lines. (4) An unchecked grandparent (`/usr/local`, `/`) being writable → **Listed**: root-owned by construction in `node:22`, not observed in the built image. N4. (5) `CC_EGRESS_DIR` set through sudo to skip the assertion entirely → **Listed**: blocked by `env_reset` + no `SETENV`, still unasserted in-repo. N4. (6) A node-owned or 0666 `*.txt` inside a root 0555 directory → **Listed**: unreachable while the directory mode holds, and the assertion does not cover file modes.

**Shared `HOST_RE` (`:129-130`)** — (1) `com` or another single label becoming a `server=/com/<ns>` zone → **Tested**: `com` and `localhost` both fail the regex; the bats case pins the abort and the absent `server=` line. (2) A trailing-dot FQDN (`example.org.`) slipping past `parse_entry` and reaching dnsmasq with different semantics → **Tested**: rejected by the regex (empty final label). (3) A leading/trailing hyphen label (`a-.b`, `example.org-`) → **Tested**: rejected. (4) An IDN A-label (`xn--bcher-kva.example`) → **Tested**: accepted, which is intended. (5) An IPv4 literal as a profile entry (`1.2.3.4`) → **Tested**: *accepted* by `HOST_RE` and would produce `server=/1.2.3.4/<ns>` plus a `dig A 1.2.3.4`; harmless (dnsmasq gets a zone nothing queries, the dig returns nothing and the entry is skipped) but it is a shape the grammar's comment does not contemplate. (6) A label at or past the 63-octet limit, or a name past 253 → **Listed**: unbounded in the regex, consumed by `dig` and dnsmasq, not executed against either.

**Probe `orig_dst` scoping (`:1074-1082`)** — (1) `node` connects to 127.0.0.1:3443 directly and forges the REJECT line → **Tested**: `SO_ORIGINAL_DST` on an un-NATed socket returns the socket's own destination, so the line reads `orig_dst=127.0.0.1:3443` and misses the grep; the `FORGED_SNI_LOG` bats case pins it. (2) `node` produces a *matching* line by connecting to `$ANTHROPIC_PROBE_IP:443` with a bad SNI → **Tested (traced)**: possible, but only while the redirect is installed — i.e. the forgery requires the property being proven, so it is not a bypass. (3) `node` writes the log file directly → **Tested (traced)**: root-owned 0644 in a root 0755 directory, no write path for `node`; `O_TRUNC` at every proxy start also clears any prior run's lines. (4) `node` installs or removes the nat rule to defeat the `-C` → **Tested (traced)**: no `CAP_NET_ADMIN` as `node`; the only privileged path is this script. (5) The stubbed `-C` in the bats suite proving nothing about real iptables → **Listed and scoped**: the suite proves the script *calls* `-C` with the exact `-A` string and fails closed on non-zero; it cannot prove `iptables` semantics, which is the live-container check still outstanding. (6) `CC_SNI_GUARD` / `CC_DNS_GUARD` absent while `CC_SNI` is present → **Listed**, N2.

**Lock directory (`:536-544`)** — (1) `node` takes the advisory lock on a read-only fd → **Tested (traced)**: the 0700 directory denies `open(2)` to a non-root uid, so the r2 mechanism is gone. (2) `node` pre-creates `/run/cc-firewall` before the first root run → **Tested**: `/run` is root-owned 0755 (executed in this sandbox; traced for the image), so `node` cannot create an entry there. (3) The window between `mkdir -p` (0755 under the root umask) and `chmod 0700` → **Tested (traced)**: the lock *file* is created after the chmod, and `node` cannot write into a root-owned 0755 directory, so there is nothing to place there during the window. (4) An existing `/run/cc-firewall` owned by a non-root uid — `mkdir -p` would not chown it and the script asserts only the mode → **Listed**: unreachable from `/run`'s mode, but the assertion asymmetry with `EGRESS_DIR` is real. (5) `CC_FIREWALL_LOCK_WAIT` set to a huge integer to stall every re-assert → **Listed**: numeric-validated but unbounded; blocked by `env_reset` like every other `CC_*`. (6) A long-lived child inheriting fd 9 → **Tested (traced)**: `9>&-` on both daemon starts, and the proxy closes every inherited fd in `daemonize`; **Listed** for any future child added without it.

**IPv6 gate (`:500-518`)** — (1) A global IPv6 address on a kernel with no v6 filter table → **Tested (traced)**: now fatal before the flush; the `HAS_GLOBAL_V6` bats case pins it. (2) An address added *after* a successful `IP6_FILTER=0` run → **Listed**, N3. (3) Only a link-local address plus a default route via a link-local next hop → **Listed**: global-destination traffic needs a global or ULA source address, so this should be unreachable, but it was not executed. (4) `ip6tables-nft` vs `-legacy` writing a different table from the one `-S OUTPUT` read → **Listed**, unchanged from r2. (5) `ip6tables -t nat`/`mangle` left unflushed while only `filter` is default-denied → **Listed**, unchanged from r2. (6) An IPv6 conntrack entry established before the run and matched by the new `ESTABLISHED,RELATED` accept → **Listed**, needs a live dual-stack container.

---

## Endorsement Claims

- **Claim:** `HOST_RE` requires at least two labels, and both `parse_entry` and `compose_dnsmasq_conf` use it, so no single-label entry can reach either the ipset or a `server=` line.
  **Location:** `devcontainer-config/init-firewall.sh:129-130`, `:139`, `:220`
  **Evidence:** executed
  **Verified:** The regex was extracted verbatim and run over sixteen fixtures: `com`, `localhost`, `a-.b`, `.a`, `a.`, `a..b`, `a b`, `a/b`, `a#b`, `example.org-`, `*.example.org`, `example.org.`, `com.` all fail; `a.b`, `xn--bcher-kva.example`, `1.2.3.4` pass. `bats test/init-firewall-rules.bats` passes 59/59 in this sandbox, including case 48 pinning `com:443` to a `malformed egress entry` abort and no `server=/com/` line.
  **Not verified:** dnsmasq's runtime treatment of the emitted zones (no dnsmasq binary here); label- and name-length limits.
  **route: code-fact-check**

- **Claim:** The ownership assertion fails closed against a symlinked `EGRESS_DIR` or parent, on both of its conditions.
  **Location:** `devcontainer-config/init-firewall.sh:305-309`
  **Evidence:** executed
  **Verified:** GNU `stat -c '%u'` on a symlink reports the *link's* owner, not the target's (a link created by a non-root uid reports that uid); `find <symlink> -maxdepth 0 -perm /022` prints the link, because `find -P` lstats its starting point and symlink modes are 0777. Either condition therefore aborts. Also verified that a 0755 root-owned directory produces no `-perm /022` match and a 0777 one does.
  **Not verified:** That `/usr/local`, `/usr` and `/` are root-owned in the built image — traced from the `node:22` base, not observed.

- **Claim:** The `-C` assertion's rule specification is character-identical to the rule the script appends, so it cannot pass against a differently-shaped rule.
  **Location:** `devcontainer-config/init-firewall.sh:1005` and `:1074`
  **Evidence:** read-static
  **Verified:** `-A OUTPUT -p tcp --dport 443 -j CC_SNI` at `:1005`; `-C OUTPUT -p tcp --dport 443 -j CC_SNI` at `:1074`; the `-t nat` prefix matches. The `NO_REDIRECT` bats case confirms a non-zero `-C` aborts the run into the trap.
  **Not verified:** That real `iptables -C` matches this rule on a live kernel, and that it is the *only* rule matching — the stub in the suite answers by fiat. This is the live-container check tracked in `docs/working/questions.md`.
  **route: code-fact-check**

- **Claim:** Removing `chown -R node:node /usr/local/share` leaves the build's only node-write requirement — the npm global prefix — satisfied.
  **Location:** `devcontainer-config/Dockerfile:59-66`, `:356-380`, `:419`
  **Evidence:** read-static
  **Verified:** The only `npm install -g` is at `:380`, under `USER node` with `NPM_CONFIG_PREFIX=/usr/local/share/npm-global` (`:359`), and that directory is created and chowned to `node` at `:65-66`; npm writes only under its prefix and `$HOME`. `COPY egress/ /usr/local/share/cc-egress/` at `:389` runs without `--chown`, so it creates root-owned entries regardless of the active `USER`, and `:419` re-chowns the tree root as belt and braces.
  **Not verified:** That the image builds and that `ls -ld /usr/local/share /usr/local/share/cc-egress` reports `root:root` on it — no build was run here. The `zsh-in-docker` step at `:371` also runs as `node`; it installs under `$HOME`, but that was traced from the script's documented behaviour, not observed.
  **route: code-fact-check**

- **Claim:** A refusal logged from a direct loopback connection cannot satisfy the completion gate.
  **Location:** `devcontainer-config/init-firewall.sh:1078`; `devcontainer-config/cc-sni-proxy.py:148-160`, `:195`
  **Evidence:** executed
  **Verified:** `bats` case 55 (`FORGED_SNI_LOG`) writes `orig_dst=127.0.0.1:3443` into the log and the run aborts with "did not log a redirected refusal"; case 50 (`SILENT_SNI_NEGATIVE`) still aborts with no line at all; both end at `iptables -w 5 -P OUTPUT DROP`.
  **Not verified:** That `SO_ORIGINAL_DST` on an un-NATed loopback socket really returns `127.0.0.1:3443` on a live kernel — that is the premise the stub encodes, traced from the socket option's semantics rather than executed.
  **route: code-fact-check**

Guardrails deliberately **not** endorsed here because they carry untested bypass candidates: the IPv6 gate (N3), the guard chains `CC_SNI_GUARD` / `CC_DNS_GUARD` (N2, unasserted), the sudo `env_reset` premise under every `CC_*` override (N4), the sudoers argument scope (N5), `parse_sni` / `Allowlist.allows` (r1-F6, unchanged), and the live ipset/redirect behaviour generally.

---

## Primitive sweep

### Ownership/provenance assertion on a privileged job's policy input

| Call site | Source (S-label) | Guard | Disposition |
|---|---|---|---|
| `init-firewall.sh:302-311` | S2, S7 | uid-0 check + `-perm /022` on `EGRESS_DIR` and its parent; after the trap, before `compose_domains` | Closes r2-F1 at use. Symlink-safe on both conditions (executed). Scope stops at one parent, skips on `CC_EGRESS_DIR`, ignores file modes — N4. |
| `init-firewall.sh:41` `PROFILE_FILE` | S2 | 0444 root in root-owned `/etc` | Unchanged, sound; not covered by the new assertion. |

### Advisory file lock as a mutual-exclusion primitive

| Call site | Source (S-label) | Guard | Disposition |
|---|---|---|---|
| `init-firewall.sh:536-544` | S8 | 0700 root directory, 0600 file, numeric wait, taken after the trap, `9>&-` on both daemons | `node` cannot open the file, so r2-F4 is closed. Critical section now excludes phase A — N1. |

### Rule-presence assertion as a completion gate

| Call site | Source (S-label) | Guard | Disposition |
|---|---|---|---|
| `init-firewall.sh:1074` `iptables -t nat -C OUTPUT … -j CC_SNI` | S9 (indirect) | Exact-string match with the `-A` at `:1005`; non-zero aborts into the trap | Sound for the one rule it names; no `-w`, so a contended xtables lock reads as "not installed" (fail-closed, but a false alarm). Four sibling rules unasserted — N2. |
| `init-firewall.sh:1078` `grep -q … orig_dst=$ANTHROPIC_PROBE_IP:443` | S5 → S6 | Kernel-supplied `orig_dst` discriminator; `ANTHROPIC_PROBE_IP` asserted non-empty at `:1062-1067`; log `O_TRUNC` per proxy start | Closes r2-F3: a loopback-originated line no longer matches, and a matching line requires the redirect being proven. |

### Environment-scoped feature switches on a sudo-reachable script

| Call site | Source (S-label) | Guard | Disposition |
|---|---|---|---|
| `CC_EGRESS_DIR` (`:40`, and the `:303` skip), `CC_FIREWALL_LOCK`, `CC_FIREWALL_LOCK_WAIT`, `CC_FIREWALL_PATH`, `CC_DNSMASQ_*`, `CC_SNI_*` | S7 | sudo `env_reset`, no `SETENV` on the sudoers rule | The set keeps growing and every member is now a control-plane switch; the single defence is a distro default this repo asserts only in comments — N4. |

### Argument vector of the sudo grant

| Call site | Source (S-label) | Guard | Disposition |
|---|---|---|---|
| `Dockerfile:424` sudoers rule; `init-firewall.sh:108-111`, `:231-234` | S9 | None — the rule names no arguments | The `--print-*` hooks accept a caller-supplied path and run as root before the ownership assertion; the disclosure is filtered to `nameserver <IPv4>` lines — N5. |

---

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Phase A moved outside the lock; a concurrent rebuild can silently narrow a legitimate run's allowlist | Low | B6, B3 | `init-firewall.sh:523-544`, `:388-432` | Medium |
| 2 | Completion gate asserts one of five boundary rules; `CC_SNI_GUARD` and the DNS guards still gate nothing | Low | B7, B4 | `init-firewall.sh:1074-1082`, `:837-839`, `:1015` | High |
| 3 | IPv6 posture is a point-in-time decision nothing re-checks; phase-B `ip6tables` calls still take no `-w` | Low | B4 | `init-firewall.sh:500-518`, `:576-594` | Medium |
| 4 | Ownership assertion stops at one parent, ignores file modes, and is skipped on an env var guarded only by an unasserted sudo default | Low | B3a, S2, S7 | `init-firewall.sh:302-311` | High / Medium |
| 5 | Sudo grant names no arguments, so the `--print-*` hooks are a root-privileged arbitrary-path read that predates the ownership assertion | Low | B3, S9 | `init-firewall.sh:108-111`, `:231-234`; `Dockerfile:424` | High |

Carried forward unchanged and not re-filed: `-w` on main-path `iptables`/`ipset` (r2-F6, accepted), ECH/multi-SNI (r1-F6), `OPENROUTER_API_KEY` exposure (r1-F7), proxy log readability and unboundedness (r1-F8), the proxy as a single choke point (r1-F9), GitHub CIDRs on tcp/22 (r1-F11).

---

## Overall Assessment

All six r2 findings are addressed. Five are closed — the Critical at both the image and the runtime, the resolver grammar with executed fixtures and a regression test, the lock by relocation into a namespace `node` cannot reach, the probe by using the one field in the log line the agent does not control, and the IPv6 gate by making the genuinely dangerous combination fatal before the flush. The sixth (`-w` on the main path) was explicitly accepted and is unchanged. The fixes are also the *right* fixes rather than the cheapest ones: `HOST_RE` is one grammar with two consumers instead of two regexes kept in sync by comment; the IPv6 decision is a phase-A precondition like every other precondition in the file rather than an inline guard; the probe asserts the mechanism and the evidence, not one or the other. The five new bats cases pin exactly the negative behaviours the r2 findings described, and the whole suite passes here.

Nothing filed this round is above Low, and none of the five opens an egress path. Four are scope or timing edges around controls that now exist — a critical section narrowed past its data dependency (N1), a gate that checks one rule of five (N2), a precondition evaluated once (N3), an assertion whose skip condition is weaker than the assertion (N4) — and the fifth (N5) is a pre-existing weak read primitive that this round's new assertion happens to throw into relief. N4 is the one I would fix first, because it is the only finding that touches the Critical's fix: the runtime assertion added in 6eaa9a0 is genuinely good, and leaving its bypass condition guarded by a distro default the repo never asserts is a smaller version of the mistake r2-F1 caught. It is a two-line sudoers change.

The review remains static with respect to a live kernel and a built image. Three things in this range are asserted by a stub rather than by the system they model — `iptables -C` semantics, `SO_ORIGINAL_DST` on an un-NATed socket, and the ownership of `/usr/local/share` after the build — and each is exactly the kind of claim the pre-`--bless` live-container check tracked in `docs/working/questions.md` exists to convert. **A safe-to-merge conclusion is offered conditionally:** the code in this range is sound as read, no finding is above Low, and I would merge it locally; I would not treat the boundary as *verified* until the live-container run has confirmed `ls -ld /usr/local/share /usr/local/share/cc-egress`, the `-C` match against real iptables, and the redirected-refusal log line on a real proxy.

---

## Goal-Alignment Note
- **Answered:** yes — security design review of `2839e59..1434fc9` restricted to `devcontainer-config/`, with per-finding status for all six r2 findings (five closed, one open-and-accepted), the new code reviewed as attack surface, and ≥3 enumerated bypass candidates for each of the five named guardrails (ownership assertion, `HOST_RE`, probe `orig_dst` scoping, lock directory, IPv6 gate) — six each, marked Tested or Listed. Report at `docs/reviews/security-review-2026-09-03-egress-hardening-r3.md`. Executed in this sandbox: the 59-case `test/init-firewall-rules.bats` suite, sixteen `HOST_RE` fixtures, `stat`/`find` symlink and `-perm /022` semantics, and `/run`'s mode. Everything else is marked read-static or traced.
- **Out of scope:** `test/*.bats`, `docs/reviews/*`, `docs/working/questions.md` and the execution logs in the range — read as committed context, and the bats suite executed as evidence about `init-firewall.sh`, not reviewed as code in its own right. `cc-isolated.sh`, `install.sh` and `devcontainer.json` are outside the diff. The fact-check's "Mostly accurate" residue on the `CC_EGRESS_DIR` rationale is adjudicated here as N4 rather than left to the orchestrator, because it now guards a control rather than only a comment. Nothing was committed; only this report was written.
- **Escalate:** (a) **N4's sudoers hardening** — every `CC_*` override, including the new assertion's own skip condition, rests on `Defaults env_reset` and the absence of `SETENV`, which the repo still asserts only in prose; make it explicit in `/etc/sudoers.d/node-firewall` and check it at launch. (b) **N5 in the same edit** — scoping the grant to a bare invocation closes the argument vector at the same time and in the same file. (c) **N2's four missing `-C` assertions** are cheap and finish the r2-F3 recommendation as written. (d) The **live-container check** (questions.md, decision log #40/#41) is now the gate on three specific conversions from read-static to executed: `ls -ld` on `/usr/local/share` and `cc-egress`, `iptables -t nat -C` against a real kernel, and a real redirected `REJECT … orig_dst=<ip>:443` line. Nothing else in this range is blocked on it.
- **Questions I would have asked:** Is the phase-A-outside-the-lock split (N1) load-bearing for a real latency problem, or was it opportunistic? If the former, a shared/exclusive pair is the clean answer; if the latter, moving the lock back to the top of the script deletes N1 outright. And: should `HOST_RE` reject an IPv4 literal, or is a numeric profile entry a shape someone intends to use?
