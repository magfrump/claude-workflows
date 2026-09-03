# Security Review — egress hardening bd41aef..abbd42d

Commit: abbd42d

**Scope:** `git diff bd41aef..HEAD -- devcontainer-config/` — `init-firewall.sh` (reviewed as greenfield: the resulting 948-line file), `cc-sni-proxy.py` (new), `Dockerfile`, `devcontainer.json`, `egress/base.txt`, `egress/llm.txt`. `devcontainer-config/cc-isolated.sh` read as context (`enforcement_files`, `compute_manifest`, `check_manifest`, `probe_boundary`, the post-start re-assert). Pass 1 of a split review: enforcement files only; `test/`, `guides/`, `docs/` are a later pass and were consulted only to avoid false "missing" claims.
**Date:** 2026-09-03
**Based on:** docs/reviews/code-fact-check-report.md (k=3 merged)

No HALT-class pattern was detected. No plaintext credential is committed, no TLS verification is disabled, no privileged endpoint is unauthenticated, and no user-facing SQL/command-injection sink is introduced.

---

## Trust Boundary Map

```
B1: host shell env (GH_TOKEN, OPENROUTER_API_KEY)
      → devcontainer.json "containerEnv" ${localEnv:*}
      → every process env inside the container, incl. `node`            (moved: GH_TOKEN added)

B2: host-side config dir (devcontainer.json, Dockerfile, init-firewall.sh,
    cc-isolated.sh, egress/*.txt, projects/*.profile)
      → cc-isolated.sh check_manifest()  → image build → /usr/local/bin
      ✗ cc-sni-proxy.py enters the image on this path but is NOT in
        enforcement_files() — it crosses B2 unhashed                    (new, unguarded)

B3: agent (uid node) → `sudo /usr/local/bin/init-firewall.sh` (NOPASSWD)
      → root execution of the script AND of every PATH-resolved helper
        (dnsmasq, ipset, iptables, dig, curl, runuser, pkill,
         `env python3` via cc-sni-proxy.py's shebang)                   (moved: 2 new daemons)

B4: agent network syscalls (uid node)
      → nat OUTPUT: CC_DNS (dport 53) / CC_SNI (tcp dport 443) REDIRECT
      → filter OUTPUT: CC_DNS_GUARD, CC_SNI_GUARD, ipset dst,dst
      → outside world                                                   (new; IPv4 only)

B5: remote/attacker-influenced ClientHello bytes on 127.0.0.1:3443
      → read_client_hello() → parse_sni() → normalise_name()
      → Allowlist.allows() → getaddrinfo(sni) → open_connection()       (new)

B6: api.github.com/meta JSON + DNS A records (phase A)
      → regex validation → `ipset add ... hash:net,port` members        (moved: net → net,port)

B7: /etc/resolv.conf + egress/*.txt (root-owned)
      → compose_dns_resolvers / compose_domains → compose_dnsmasq_conf
      → /etc/dnsmasq.d/cc-allowlist.conf directives                     (new)

B8: root-written /run/cc-sni-proxy/{allowlist,proxy.pid,proxy.log}
      → proxy after setuid(ccproxy); log+dir world-readable to `node`   (new)
```

| S | Source | Mutability class | Trust per sink class |
|---|--------|------------------|----------------------|
| S1 | `/etc/resolv.conf` | Docker-runtime-mutable, root-owned; **not asserted by this repo** (`init-firewall.sh:519-527` says so explicitly) | Untrusted toward `iptables -d` (an injected `nameserver <attacker>` earns a scoped accept) and toward `server=/…/<ns>` dnsmasq directives. Mitigated only by octet validation in `compose_dns_resolvers`. |
| S2 | `/etc/cc-egress-profile` + `/usr/local/share/cc-egress/*.txt` | Build-time-fixed, 0444/0555 root-owned; agent cannot rewrite | Trusted for *content*, untrusted for *grammar* — the code correctly re-validates before `ipset add`, `dig`, and dnsmasq config. |
| S3 | `api.github.com/meta` JSON | Remote, fully attacker-controlled if GitHub or the TLS path is subverted | Untrusted toward `ipset add` — validated by `jq -e` shape check + per-CIDR regex at `:326-339`. Widening risk remains: a compromised `/meta` widens the CIDR ingest by construction. |
| S4 | DNS A records for allowlisted names | Remote, cache-lifetime-mutable | Untrusted toward `ipset add` — regex-validated at `:373`. Determines the address set for the whole session. |
| S5 | SNI in a ClientHello arriving at 127.0.0.1:3443 | Fully attacker-controlled per connection (any local process may connect; `-o lo` accepts it) | Untrusted toward `getaddrinfo()` and `open_connection()` — the single highest-consequence untrusted→trusted transition in the diff. Constrained by `LABEL` + `Allowlist.allows`. |
| S6 | `/run/cc-sni-proxy/*`, `/run/cc-dnsmasq.pid` | Root-written; `/run` and `/run/cc-sni-proxy` are 0755 root-owned, so `node` may read, not write | Trusted toward `os.kill` / `kill` **only because** `node` cannot write them; the `cmdline`/`comm` checks are the second line, not the first. Log is readable by `node`. |
| S7 | `CC_*` env vars (`CC_SNI_PROXY_BIN`, `CC_DNSMASQ_CONF`, `CC_SNI_PORT`, `CC_EGRESS_DIR`, …) | Caller-controlled | Untrusted toward `exec`/`iptables`; neutralised **only** by sudo `env_reset`, which this repo asserts in comments (`:26`, `:78`, `:393`) but never verifies. |
| S8 | `GH_TOKEN`, `OPENROUTER_API_KEY` in `containerEnv` | Host-export-controlled, present for the whole session | High-consequence secrets readable by every in-container process including a compromised agent. |
| S9 | The bless manifest (`enforcement_files()` output) | Host-side, human-blessed | Trusted as the integrity anchor for B2 — and therefore load-bearing for every file it omits. |

The diff moves the boundary in the right direction: address matching (B6) is joined by name matching at two layers — a REFUSED-by-default resolver (B7) and an SNI splice proxy (B5) — and both new daemons run as distinct non-root uids so the `-m owner` exemptions are expressible. The residual risk concentrates in three places: the controls are installed only in the IPv4 tables (F1), the script that installs them has no mutual exclusion despite being agent-invokable (F2), and the new proxy is the one enforcement file the trust manifest does not cover (F4).

---

## Findings

#### IPv6 egress is entirely unenforced, and the new DNS/SNI controls are IPv4-only by construction

**Severity:** High
**Location:** `devcontainer-config/init-firewall.sh:510-512`, `:558-559`, `:653-654`; `devcontainer-config/cc-sni-proxy.py:182-183`
**Boundary:** B4, B5, B7
**Move:** 5 (invert the access-control model), 11 (enumerate bypasses)
**Confidence:** Medium
**Evidence:**
> `# gateway-DNS accept below already admit it and`
> `# these rules are redundant. They are load-bearing only for a resolver that is`
> …
> `# this script installs no ip6tables rules, so the whole`
> `# allowlist — not just DNS — is unenforced for IPv6 (a pre-existing gap).`

and, in the proxy:
> `            infos = await asyncio.get_running_loop().getaddrinfo(`
> `                sni, upstream_port, family=socket.AF_INET, type=socket.SOCK_STREAM)`
> (… remainder of `handle()`'s connect block not shown: `ip = infos[0][4][0]`, the `wait_for(open_connection(...))`, the `except (OSError, asyncio.TimeoutError)` FAIL log, then the ALLOW log, `up_w.write(raw)` and the `gather(pump, pump)` splice.)

**Legibility-target:** for-author
Every control added in this range lives in `iptables` (IPv4) tables only: the `-P … DROP` policies, the `allowed-domains` `dst,dst` accept, the `CC_DNS`/`CC_SNI` nat REDIRECTs, and both filter guard chains. `ip6tables` is never invoked, so its default `ACCEPT` policies stand over empty chains. Wherever the container has a routable IPv6 address (Docker Desktop with IPv6 enabled, a user-defined IPv6 network, or an `--ip6tables` daemon), a compromised `node` reaches `[attacker]:443` with no ipset match, no SNI redirect, and no proxy involvement, and — if `/etc/resolv.conf` names an IPv6 nameserver — resolves arbitrary names without ever touching dnsmasq, restoring the full recursive-forward tunnel finding 6 was written to close. Failure mode: **dual-stack control-plane omission**. The script's comments correctly identify this as pre-existing, but it is now load-bearing for two controls that did not exist before, and the fix is cheap.

**Recommendation:** In phase B, mirror the three policy calls and a flush into `ip6tables` (`ip6tables -P INPUT/OUTPUT/FORWARD DROP; ip6tables -F; ip6tables -X`) so IPv6 fails closed by default, and add a verification probe. Alternatively (or additionally) add `--sysctl net.ipv6.conf.all.disable_ipv6=1` to `runArgs` in `devcontainer.json` and assert it in the script, so the assumption is checked rather than hoped for.

---

#### `init-firewall.sh` has no mutual exclusion; two concurrent agent-triggered runs can produce a "complete" ruleset with the DNS guards missing

**Severity:** High
**Location:** `devcontainer-config/init-firewall.sh:472-483`, `:693-696`, `:715-723`, `:731`
**Boundary:** B3, B4
**Move:** 3 (check the error path), 4 (TOCTOU), 5 (invert the access-control model)
**Confidence:** Medium
**Evidence:**
> `iptables -P INPUT DROP`
> `iptables -P FORWARD DROP`
> `iptables -P OUTPUT DROP`
>
> `# Flush existing rules and delete existing ipsets (policies set above persist)`
> `iptables -F`
> `iptables -X`
> (… remainder of the flush block not shown: the three `-t nat` / `-t mangle` `-F`/`-X` pairs and `ipset destroy allowed-domains 2>/dev/null || true`.)

and the ordering-critical append:
> `iptables -A OUTPUT -d 127.0.0.11 -j CC_DNS_GUARD`
> `iptables -A OUTPUT -p udp --dport 53 ! -d 127.0.0.1 -j CC_DNS_GUARD`
> `iptables -A OUTPUT -p tcp --dport 53 ! -d 127.0.0.1 -j CC_DNS_GUARD`
> `iptables -A OUTPUT -o lo -j ACCEPT`

**Legibility-target:** for-author
`node` holds NOPASSWD sudo for this exact script and can invoke it any number of times in parallel. There is no `flock`, no pidfile, and no `-w` on any main-path `iptables` call (`-w 5` appears only inside `fail_closed_on_abort`, `:250-253`), so two runs interleave freely over one shared ruleset. Concretely: if run B reaches the flush (`:477`) while run A sits between `:722` and `:723`, A's guard jumps are deleted and A then appends `-o lo -j ACCEPT` as the *first* rule of the empty OUTPUT chain; A continues, wins the `ipset create` race at `:731`, installs its nat `CC_SNI` rules and the ipset accept, passes all four probes (example.com is still blocked, api.github.com is still reachable, and both SNI probes exercise A's freshly installed nat chain) and sets `FIREWALL_COMPLETE=1`, while B aborts on the duplicate `ipset create` and appends only unreachable rules after A's terminal REJECT. The resulting "verified complete" container has no `CC_DNS_GUARD` jump, so `node` sends queries straight to `127.0.0.11:<embedded-resolver-port>` — read from `/proc/net/udp`, never carrying dport 53, therefore never redirected — and gets unfiltered recursion for `<data>.attacker.com`. Failure mode: **unserialised rebuild of a shared kernel table under attacker-controlled invocation**.

**Recommendation:** Take an exclusive lock as the first statement of the script (`exec 9>/run/cc-firewall.lock; flock -n 9 || { echo "another run in progress" >&2; exit 1; }`) so a second invocation refuses rather than interleaves, and add `-w 5` to every `iptables`/`ipset` call on the main path so a contended xtables lock waits instead of aborting mid-rebuild.

---

#### Root execution of every helper — including the SNI proxy — resolves through `PATH`; the stated PATH-hijack immunity rests on an unasserted sudo `secure_path`

**Severity:** Medium
**Location:** `devcontainer-config/init-firewall.sh:430-436`, `:874-875`; `devcontainer-config/cc-sni-proxy.py:1`; `devcontainer-config/Dockerfile:60-61`, `:354-355`, `:419`
**Boundary:** B3, S7
**Move:** 1 (trust boundaries), 5 (invert the access-control model), 12 (sweep call sites)
**Confidence:** Medium
**Evidence:**
> `# overridable for the unit tests only; in the image they are the root-owned`
> `# defaults. The proxy binary is executed directly (root-owned, 0555, hashed by the`
> `# launcher's manifest) rather than via a `python3` on PATH, so a PATH hijack by`
> ``# `node` cannot substitute the interpreter.``
> (… remainder of the SNI-preconditions block not shown: the `SNI_PROXY_BIN`/`SNI_RUN_DIR`/`SNI_ALLOWLIST`/`SNI_PIDFILE`/`SNI_LOG`/`SNI_PORT` assignments, the `-x` check, and the `CCPROXY_UID` numeric/non-zero/distinct-from-dnsmasq check.)

against the file it describes:
> `#!/usr/bin/env python3`

and the node-writable directory on `node`'s own PATH:
> `RUN mkdir -p /usr/local/share/npm-global && \`
> `  chown -R node:node /usr/local/share`
> …
> `ENV PATH=$PATH:/usr/local/share/npm-global/bin`

**Legibility-target:** for-author
The comment's reasoning is wrong: executing `$SNI_PROXY_BIN` directly still runs its shebang, `#!/usr/bin/env python3`, which searches `PATH` for the interpreter. `node` owns `/usr/local/share` recursively and `/usr/local/share/npm-global/bin` is on its PATH, so an attacker-supplied `python3` there is a ready-made payload. The same exposure covers every other helper the script invokes by bare name as root — `dnsmasq`, `iptables`, `ipset`, `dig`, `curl`, `jq`, `aggregate`, `runuser`, `pkill`, `xargs`. What actually prevents the escalation is sudo's `env_reset` plus Debian's default `Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"`, none of which this repo sets, tests, or asserts — the sudoers fragment it *does* write (`Dockerfile:419`) contains only the command rule. This is exactly the class of unasserted distro default the script flags for `/etc/resolv.conf` at `:519-527`, and here the consequence is root code execution rather than a scoped DNS accept. Failure mode: **security property delegated to an unverified environment default**.

**Recommendation:** Change the shebang to an absolute `#!/usr/bin/python3` (and/or invoke the proxy as `/usr/bin/python3 "$SNI_PROXY_BIN"`), and pin the environment explicitly in the sudoers fragment — e.g. `Defaults!/usr/local/bin/init-firewall.sh secure_path="/usr/sbin:/usr/bin:/sbin:/bin"` — so the guarantee is stated in the config rather than inherited. Correct the `:434-436` comment to name `secure_path`, not "executed directly", as the reason.

---

#### `cc-sni-proxy.py` is an enforcement file outside the bless manifest

**Severity:** Medium
**Location:** `devcontainer-config/cc-sni-proxy.py:24-25`; `devcontainer-config/cc-isolated.sh:50-65`; `devcontainer-config/Dockerfile:386-388`
**Boundary:** B2
**Move:** 1 (trust boundaries)
**Confidence:** High
**Evidence:**
> `Single file, stdlib only (python3.11 ships in the node:22 base — no apt package,`
> `no pip), root-owned in the image and hashed by the launcher's trust manifest.`

against `enforcement_files()`:
> `  echo "devcontainer.json"`
> `  echo "Dockerfile"`
> `  echo "init-firewall.sh"`
> `  echo "cc-isolated.sh"`
> (… remainder of `enforcement_files()` not shown: the comment about order-stable globs and the subshell emitting sorted `egress/*.txt` and `projects/*.profile`. `cc-sni-proxy.py` appears nowhere in the function.)

**Legibility-target:** for-author
This confirms fact-check Claim 10 / escalation E1. The manifest is the integrity anchor for boundary B2 — `check_manifest()` refuses to build or launch when any listed file changed since the last `--bless`. `cc-sni-proxy.py` is now the sole enforcement point for name-based filtering on tcp/443, yet a host-side rewrite of it (malware, a stray sync, a compromised editor session) is copied into the image and executed as root at every firewall run without tripping the check. A one-line edit to `Allowlist.allows` returning `True` silently reverts the entire SNI control while every probe still passes. Failure mode: **enforcement file outside its own integrity envelope**.

**Recommendation:** Add `echo "cc-sni-proxy.py"` to `enforcement_files()` between `init-firewall.sh` and `cc-isolated.sh` and re-bless before the rebuild. Correct the docstring only after the manifest actually covers it.

---

#### The negative SNI probe passes on any non-zero curl exit, so `FIREWALL_COMPLETE` can be set with the SNI control absent

**Severity:** Medium
**Location:** `devcontainer-config/init-firewall.sh:934-948`
**Boundary:** B4, B5
**Move:** 3 (check the error path), 11 (enumerate bypasses)
**Confidence:** Medium
**Evidence:**
> `if runuser -u node -- curl --connect-timeout 5 --max-time 15 \`
> `        --resolve "not-allowlisted.invalid:443:$ANTHROPIC_PROBE_IP" https://not-allowlisted.invalid/ >/dev/null 2>&1; then`
> `    echo "ERROR: Firewall verification failed - a non-allowlisted SNI reached an allowlisted address"`
> `    exit 1`
> `else`
> `    echo "Firewall verification passed - non-allowlisted SNI refused as expected"`
> `fi`
> `FIREWALL_COMPLETE=1`

**Legibility-target:** for-author
This addresses escalation E3. The probe's pass condition is "curl did not exit 0", which is satisfied by a great many outcomes other than a proxy refusal — most importantly by the *no-redirect* case: with the `CC_SNI` nat jump absent, the connection goes straight to `$ANTHROPIC_PROBE_IP:443` (in the ipset on tcp:443), the server presents a certificate for `api.anthropic.com` against a requested `not-allowlisted.invalid`, and curl exits 60. The positive probe also passes in that state, because direct reachability of api.anthropic.com is exactly what it tests. So all four verification steps green-light a container in which tcp/443 is address-matched only — the pre-hardening posture — and the completion sentinel is set. F2 above supplies a concrete way to reach that state. Failure mode: **verification that cannot distinguish the control from its absence**.

**Recommendation:** Assert the mechanism, not the outcome: require the specific refusal (e.g. `curl -w '%{exitcode}'` matched against 35/52/56 for a proxy-closed connection, or better, grep `$SNI_LOG` for a `REJECT sni=not-allowlisted.invalid` line written during the probe), and additionally assert the rule is present (`iptables -t nat -C OUTPUT -p tcp --dport 443 -j CC_SNI`) before declaring the run complete.

---

#### SNI filtering is bypassable by a client that hides or duplicates the server name (ECH, multi-entry ServerNameList)

**Severity:** Medium
**Location:** `devcontainer-config/cc-sni-proxy.py:85-99`, `:140-142`
**Boundary:** B5
**Move:** 7 (serialization boundary), 9 (cryptographic choices), 11 (enumerate bypasses)
**Confidence:** Low
**Evidence:**
> `        while p + 4 <= end:`
> `            ext_type, ext_len = _u16(body, p), _u16(body, p + 2)`
> `            p += 4`
> `            if ext_type == 0:                       # server_name`
> `                q = p + 2                           # skip ServerNameList length`
> `                while q + 3 <= p + ext_len:`
> `                    name_type, name_len = body[q], _u16(body, q + 1)`
> `                    q += 3`
> `                    if name_type == 0:              # host_name`
> `                        return normalise_name(body[q:q + name_len])`
> (… remainder of `parse_sni()` not shown: `q += name_len`, `p += ext_len`, the closing `raise HelloError("no server_name extension")`, and the `except IndexError` → `HelloError("malformed ClientHello")` wrapper.)

**Legibility-target:** for-author
Peek-then-splice inherits the two structural limits of SNI inspection. (a) The proxy returns the *first* `host_name` in the ServerNameList and stops; an entry-order or duplicate-extension disagreement with the upstream TLS stack lets a client present an allowlisted name to the proxy and a different name to the CDN edge the proxy dials — the proxy still connects to the allowlisted name's IP, but on a shared CDN front the edge serves whatever name *it* parsed, which is precisely the shared-IP overreach the block exists to close. (b) TLS 1.3 Encrypted Client Hello puts the real name in an encrypted inner hello behind a public outer SNI; a client using ECH toward an ECH-capable provider that also fronts the allowlisted name passes the proxy on the outer name and reaches the attacker's zone. Neither is exploitable with the container's current stock curl/OpenSSL, and RFC 6066 duplicate handling makes (a) a genuine parser differential rather than a certainty — hence Low confidence. Failure mode: **name-based filtering on a field the endpoint is not obliged to interpret identically**.

**Recommendation:** Reject a ServerNameList carrying more than one entry and a ClientHello carrying more than one `server_name` extension (fail closed rather than take the first), and record ECH as a named residual in the SNI PROXY block's RESIDUAL paragraph; where the dnsmasq build supports it, add `filter-rr=HTTPS` (dnsmasq ≥ 2.90) so clients cannot fetch an `ECHConfig` through the container's own resolver.

---

#### `OPENROUTER_API_KEY` is injected into every session regardless of egress profile and is exfiltrable through base egress

**Severity:** Medium
**Location:** `devcontainer-config/devcontainer.json:138-148`
**Boundary:** B1
**Move:** 6 (follow the secrets)
**Confidence:** High
**Evidence:**
> `    // Opt-in, and empty unless the host exports it. Only meaningful in a project`
> `    // registered with the `llm` egress profile — without that, openrouter.ai is`
> `    // firewalled and the key is inert.`
> …
> `    // compromised session can exfiltrate through the very channel `llm` opens.`
> `    "OPENROUTER_API_KEY": "${localEnv:OPENROUTER_API_KEY}",`

**Legibility-target:** for-author
The comment scopes the risk to the `llm` profile, but the injection is unconditional: `containerEnv` carries the key into every project's container whenever the host exports it, and the exfiltration channel does not depend on `llm` at all. Base egress admits GitHub's `.web + .api + .git` CIDRs on tcp 443 and 22, and `.github.com` / `.githubusercontent.com` are SNI-allowlisted, so a compromised agent under a base-only profile can push the key to a gist or a repo — a path the sibling `GH_TOKEN` comment names correctly two paragraphs later but this one does not. "The key is inert" is true about *using* the key and false about *stealing* it, which is the operative risk under this threat model. Failure mode: **credential scoped by capability, not by presence**.

**Recommendation:** Gate the variable on the profile rather than the host env — omit it from `containerEnv` and inject it only for `llm`-registered projects (or via a host-side broker, as the comment's own long-term plan says) — and correct the "inert" sentence to state that the key remains exfiltrable through base egress whether or not openrouter.ai is reachable.

---

#### The proxy log records every SNI and original destination in a world-readable, unbounded file

**Severity:** Low
**Location:** `devcontainer-config/cc-sni-proxy.py:153-154`, `:176-190`, `:243`, `:296`; `devcontainer-config/init-firewall.sh:852-854`
**Boundary:** B8
**Move:** 6 (follow the secrets), 8 (what if there are a million of these)
**Confidence:** High
**Evidence:**
> `    log_fd = os.open(args.log, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o644)`

with the containing directory:
> `mkdir -p "$SNI_RUN_DIR"`
> `chmod 0755 "$SNI_RUN_DIR"`
> (… remainder of the SNI-allowlist block not shown: `rm -f "$SNI_ALLOWLIST"`, the `{ … } > "$SNI_ALLOWLIST"` heredoc-style group that writes the 443-scoped names plus the three GitHub zones, and `chmod 0444 "$SNI_ALLOWLIST"`.)

**Legibility-target:** for-author
`/run/cc-sni-proxy` is 0755 root-owned and the log is 0644, so `node` can read a complete, timestamped record of every TLS destination the container reached — including any other process's, if the container ever runs one. The content is low-value here (the agent generated the traffic) but the file has no rotation or size cap and is truncated only on a firewall run, so a compromised agent can also inflate it by looping connections until the container's writable layer fills, at which point the next run's `dnsmasq --pid-file` write or config generation fails and the container fails closed. Failure mode: **unbounded, over-readable audit sink on the agent's own filesystem**.

**Recommendation:** Create the log 0640 root:ccproxy (or 0600 after the drop) so it is not agent-readable, and cap it — either rotate on a size threshold in `serve()` or write through a bounded handler — so log volume is not an agent-controlled resource.

---

#### The proxy is an unbounded, single-point choke for all agent tcp/443 egress

**Severity:** Low
**Location:** `devcontainer-config/cc-sni-proxy.py:102-119`, `:168-197`, `:199-209`
**Boundary:** B5
**Move:** 8 (what if there are a million of these)
**Confidence:** High
**Evidence:**
> `    server = await asyncio.start_server(`
> `        lambda r, w: handle(r, w, allow, args.upstream_port), host, int(port), reuse_address=True)`
> (… remainder of `serve()` not shown: the `log(...)` listening line, the optional `os.write(ready_fd, b"ready")` / `os.close(ready_fd)`, and `async with server: await server.serve_forever()`.)

**Legibility-target:** for-orchestrator-synthesis
`start_server` is called with no `backlog` tuning and no concurrency limit, and `node` may connect to 127.0.0.1:3443 directly (the `-o lo` accept at `init-firewall.sh:723` admits it) as well as through the redirect. Each connection costs a task, up to ~128 KiB of buffered ClientHello, a 10 s `HELLO_TIMEOUT`, and a `getaddrinfo` that occupies one of asyncio's default executor threads. Saturating or OOM-killing the proxy takes down *all* agent HTTPS egress. The direction is safe — with the proxy dead the REDIRECT points at a closed port and 443 fails closed — so this is availability, not containment. It is worth recording because the proxy has now become a single point of failure for the whole session, and F5's probe weakness means a dead proxy is not necessarily noticed at the next re-assert.

**Recommendation:** Add a bounded connection semaphore (a few hundred) and a per-connection cap so the proxy sheds load rather than dying, and consider `dns-forward-max`-style back-pressure. No change is needed for the fail-closed direction.

---

#### Port normalisation disagrees between `parse_entry` and the SNI-allowlist writer, silently blackholing an entry

**Severity:** Low
**Location:** `devcontainer-config/init-firewall.sh:116-134`, `:857-869`
**Boundary:** B6, B5
**Move:** 2 (implicit sanitization assumption), 11 (enumerate bypasses)
**Confidence:** High
**Evidence:**
> `  for port in $(echo "$ports" | tr ',' '\n'); do`
> `    # 10#: a leading zero would otherwise make bash read the number as octal.`
> `    [ "$((10#$port))" -ge 1 ] && [ "$((10#$port))" -le 65535 ] || return 1`
> `  done`
> `  printf '%s\t%s\n' "$domain" "$ports"`

against the consumer:
> `        case ",$ports," in *,443,*) echo "$domain" ;; esac`

**Legibility-target:** for-author
This is fact-check escalation E7, traced. `parse_entry` validates `0443` numerically but emits the *string* verbatim, so an entry `some.host:0443` yields an ipset member `<ip>,tcp:0443` while the SNI-allowlist writer's literal `*,443,*` match fails and omits the name. The result is an address admitted on 443 whose name the proxy will `REJECT`, i.e. a silently unreachable host that reads as a network outage — the exact failure mode the header's "a typo fails the rebuild loudly" stance exists to prevent. The direction is closed, not open, so severity is Low; the defect is that two parsers of the same field disagree. The sibling residues in the same escalation are inert in the current code: a bare `.` line cannot survive `parse_entry`'s `^label(\.label)*$`, and `Allowlist.allows` would not match it anyway because `normalise_name` strips trailing dots; a single-label entry becomes an exact SNI name with no resolver line and no resolvable address, so it is dead rather than permissive.

**Recommendation:** Normalise in `parse_entry` — emit `$((10#$port))` instead of the raw token — so every downstream consumer sees one canonical form, and add a bats case pinning `host:0443` to a `tcp:443` member plus an SNI-allowlist line.

---

#### GitHub CIDRs are admitted on tcp/22 with no name-layer check

**Severity:** Informational
**Location:** `devcontainer-config/init-firewall.sh:736-746`, `:829-831`
**Boundary:** B4, B6
**Move:** 5 (invert the access-control model)
**Confidence:** High
**Evidence:**
> `    ipset add -exist allowed-domains "$cidr,tcp:443"`
> `    ipset add -exist allowed-domains "$cidr,tcp:22"`

**Legibility-target:** for-orchestrator-synthesis
The SNI proxy covers tcp/443 only, by design and for good reason. The consequence worth stating explicitly is that the `.web + .api + .git` aggregate — thousands of addresses, including the GitHub Pages ranges in `.web` — remains a raw, unfiltered TCP channel on port 22 for a compromised agent. Nothing GitHub-operated listens on 22 outside the SSH endpoints, and reaching those still requires a key, so there is no known exploitation path today; but the port-22 grant is now the widest un-name-checked surface left in the base profile, and `.web` is admitted on 22 only because the three meta keys are ingested as one set. `.githubassets.com` in the SNI allowlist (escalation E2) is dead in the other direction — SNI-allowed, never resolvable — and should be resolved as a pair with this.

**Recommendation:** Ingest `.git` (and, if needed, `.api`) for tcp:22 and restrict `.web` to tcp:443, so the SSH grant covers only the key that actually carries SSH endpoints.

---

## Endorsement Claims

- **Claim:** The SNI proxy is started, and verified live, strictly before the `CC_SNI` nat REDIRECT that depends on it is installed, so a proxy that fails to start cannot leave a redirect pointing at a closed port.
  **Location:** `devcontainer-config/init-firewall.sh:874-886`
  **Evidence:** read-static
  **Verified:** The `if ! "$SNI_PROXY_BIN" --daemon … ; then … exit 1; fi` block at `:874-878` precedes `iptables -t nat -N CC_SNI` at `:882` in file order, with no branch between them; `daemonize()` returns 0 only after the parent reads `b"ready"`, which the child writes after `asyncio.start_server` has returned (`cc-sni-proxy.py:202-207`, `:249-253`).
  **Not verified:** That a child which binds and then dies before the first connection is detected — `daemonize()` has already returned 0 (fact-check Claim 13); and that `runuser`'s probe actually traverses the redirect on a live kernel.
  **route: code-fact-check**

- **Claim:** UDP to an allowlisted address and port is denied, because every `allowed-domains` member is written with a `tcp:` proto prefix and the OUTPUT accept matches `dst,dst`.
  **Location:** `devcontainer-config/init-firewall.sh:383-385`, `:744-745`, `:902`
  **Evidence:** read-static
  **Verified:** The only two `ipset add` call sites emit `${ip},tcp:${port}` and `"$cidr,tcp:443"` / `"$cidr,tcp:22"`; no other member form is constructed anywhere in the file, and the single accept is `-m set --match-set allowed-domains dst,dst`.
  **Not verified:** The kernel's `hash:net,port` matching behaviour for a UDP datagram against a `tcp:`-typed member (never executed here); QUIC on udp/443 is denied by this same untested mechanism.
  **route: code-fact-check**

- **Claim:** The dnsmasq uid's exemption from `CC_DNS`/`CC_DNS_GUARD` does not grant it arbitrary outbound port-53 reach; its upstream accepts are address-scoped to the parsed resolvers and the bridge gateway.
  **Location:** `devcontainer-config/init-firewall.sh:541-544`, `:788-791`, `:682-683`, `:694-695`
  **Evidence:** read-static
  **Verified:** Both owner-scoped ACCEPT loops carry `-d "$ns"` / `-d "$HOST_IP"`; the `CC_DNS`/`CC_DNS_GUARD` RETURNs add no accept of their own, so a dnsmasq-uid packet to any other address on 53 reaches the terminal REJECT at `:905`.
  **Not verified:** That `$ns` values are trustworthy — they come from `/etc/resolv.conf` (S1), whose root ownership this repo does not assert (`:519-527`).
  **route: code-fact-check**

- **Claim:** The proxy does not terminate TLS: it replays the captured ClientHello bytes upstream and copies ciphertext in both directions without holding a key or certificate.
  **Location:** `devcontainer-config/cc-sni-proxy.py:157-165`, `:190-192`
  **Evidence:** read-static
  **Verified:** `up_w.write(raw)` writes the exact record bytes accumulated by `read_client_hello`, then `pump` performs unmodified `read`/`write` copies; no `ssl` import, no certificate material, and no write path that alters payload bytes exists in the file.
  **Not verified:** That `raw` is byte-identical to what the client sent in every fragmentation case — inferred from `raw += hdr + body` over `readexactly`, not executed.
  **route: code-fact-check**

- **Claim:** The proxy's privilege drop follows the correct order and the listening socket is bound after it.
  **Location:** `devcontainer-config/cc-sni-proxy.py:273-279`
  **Evidence:** read-static
  **Verified:** `os.setgroups([])` precedes `os.setgid(pw.pw_gid)`, which precedes `os.setuid(pw.pw_uid)`; `asyncio.run(serve(...))` — which performs the bind — is called after all three, and port 3443 needs no privilege.
  **Not verified:** That `daemonize()` is unreachable as root without `--user` in any invocation path other than `init-firewall.sh:874` (the `:240-241` guard covers the documented one).

Guardrails deliberately **not** listed here because they carry untested bypass candidates: `Allowlist.allows` / `parse_sni` / `normalise_name` (F6), the `CC_DNS` redirect and `CC_DNS_GUARD` (F1, F2), the `CC_SNI` redirect and `CC_SNI_GUARD` (F1, F5), the fail-closed trap (F2), and the negative SNI probe (F5).

---

## Untested bypass candidates

**`hash:net,port` ipset match (`:902`)** — (1) IPv6 destination, no ip6tables rule exists at all → **Listed**, no IPv6 stack in the review sandbox; traced statically in F1. (2) UDP/QUIC to an allowlisted `<ip>:443` → **Tested (traced)**: every member is `tcp:`-prefixed, so no match, terminal REJECT. (3) ICMP to an allowlisted address (`hash:net,port` encodes type/code in the port field) → **Tested (traced)**: no `icmp:` member exists, REJECT. (4) A conntrack entry established under a *previous* ruleset surviving the flush and being accepted by `-A OUTPUT -m state ESTABLISHED,RELATED` at `:803` → **Listed**, requires a live kernel to confirm conntrack is not cleared by `iptables -F`.

**`CC_SNI` redirect + `CC_SNI_GUARD` (`:882-896`)** — (1) `node` connecting directly to 127.0.0.1:3443, bypassing the redirect → **Tested (traced)**: `-o lo` admits it, but the proxy applies the identical allowlist check, so the outcome is equivalent, not weaker. (2) tcp/443 escaping nat via conntrack exhaustion → **Listed**, the guard chain is the stated mitigation and was not executed. (3) A process that acquires the `ccproxy` uid (a proxy RCE) → **Listed**, would inherit the RETURN exemption and regain full address-matched 443 reach. (4) ECH / duplicate-SNI parser differential → **Listed**, see F6.

**`CC_DNS` redirect + `CC_DNS_GUARD` (`:681-696`, `:720-722`)** — (1) direct UDP to `127.0.0.11:<embedded port>` from `/proc/net/udp` → **Tested (traced)**: the all-ports `-d 127.0.0.11 -j CC_DNS_GUARD` jump at `:720` covers it *provided rule order holds* — F2 shows an interleaving where it does not. (2) DNS over TCP → **Tested (traced)**: `:685` and `:722` cover tcp/53 symmetrically. (3) DoT on 853 → **Tested (traced)**: not lo, not 53, not 443 → falls to the ipset, no member on 853, REJECT. (4) DoH on 443 to an allowlisted name → **Tested (traced)**: redirected to the SNI proxy, and no allowlisted base/llm host operates a DoH endpoint — but this is a profile-content property, not a rule property, and a future profile entry for a DoH-capable host would open it. (5) IPv6 nameserver in `resolv.conf` → **Listed**, F1. (6) `/etc/hosts` consulted before DNS by `getaddrinfo` → **Tested (traced)**: Docker mounts it root-owned and `node` cannot write it; `no-hosts` additionally stops dnsmasq reading it.

**`parse_entry` (`:116-134`)** — (1) zero-padded port → **Tested (traced)**, F10. (2) single-label domain (`com`) → **Tested (traced)**: passes `parse_entry`, becomes an *exact* SNI entry (not a zone), gets no resolver line from `compose_dnsmasq_conf`'s dot-requiring regex, and resolves to nothing — dead, not permissive. (3) shell/ipset metacharacters in the domain → **Tested (traced)**: the `^label(\.label)*$` bash regex admits only `[A-Za-z0-9-]` and `.`.

**`compose_dnsmasq_conf` hostname regex (`:199`)** — (1) `/` or `#` in a profile name (dnsmasq config syntax) → **Tested (traced)**: rejected with a WARNING, entry omitted. (2) a name arriving with a `:port` suffix → **Tested (traced)**: `d="${d%%:*}"` strips it before the check. (3) a resolver address injected via `/etc/resolv.conf` → **Tested (traced)** for grammar (octet alternation at `:91`), **Listed** for trust (S1 is unasserted).

**`Allowlist.allows` (`cc-sni-proxy.py:140-142`)** — (1) trailing-dot SNI (`api.anthropic.com.`) → **Tested (traced)**: `normalise_name` rstrips it. (2) uppercase/mixed-case SNI → **Tested (traced)**: `.lower()` on both load and parse. (3) a suffix-confusion name (`evil-api.anthropic.com` vs the zone `.github.com`) → **Tested (traced)**: `endswith("." + z)` requires the dot boundary. (4) a bare `.` line producing an empty zone → **Tested (traced)**: unreachable from `parse_entry`, and inert because `normalise_name` guarantees no trailing dot.

**Fail-closed trap (`:246-272`)** — (1) `SIGKILL` of the script → **Listed**, no trap can run; the ruleset is left mid-build with DROP policies already set at `:472-474`, which is the safe direction. (2) losing the xtables lock inside the trap → **Tested (traced)**: `-w 5` plus the `iptables -S` read-back at `:253-259` reports OPEN rather than claiming a DROP. (3) a concurrent run re-flushing after the trap set DROP → **Listed**, F2.

---

## Primitive sweep

### Network connect by attacker-influenced name or address

| Call site | Source (S-label) | Guard | Disposition |
|---|---|---|---|
| `cc-sni-proxy.py:182-183` `getaddrinfo(sni, …, AF_INET)` | S5 | `LABEL` per-label regex + 253-byte cap in `normalise_name`; `Allowlist.allows` before the call | Constrained to allowlisted hostnames; resolution is forced through dnsmasq by the `CC_DNS` REDIRECT (ccproxy is not an exempt uid). IPv6 lookups are excluded by `family=AF_INET`, which is also why F1 does not leak here. |
| `cc-sni-proxy.py:185-186` `open_connection(ip, upstream_port)` | S5 → S4 (resolved address) | Kernel `allowed-domains dst,dst` accept still applies to the ccproxy uid | Defence in depth holds: an SNI that resolves outside the ipset is REJECTed and logged `FAIL`. |
| `init-firewall.sh:320` `curl … https://api.github.com/meta` | fixed URL, response is S3 | `--connect-timeout 5 --max-time 15`, `\|\| true`, `-z` check, `jq -e` shape check, per-CIDR regex | Bounded and validated; a compromised `/meta` still widens the CIDR ingest by design. |
| `init-firewall.sh:358` `dig … A "$domain"` | S2 | `parse_entry` grammar; `+time=3 +tries=2`; per-IP regex at `:373` | Domain cannot carry shell or option syntax; failure warn-and-skips except `api.anthropic.com`. |
| `init-firewall.sh:911`, `:919` verification curls | fixed URLs | `--connect-timeout`/`--max-time` | Bounded. |
| `init-firewall.sh:928`, `:937-938` `runuser -u node -- curl … --resolve` | S4 (`$ANTHROPIC_PROBE_IP`) | Regex-validated at `:373`; the literal name is a fixed `.invalid` | No injection; the *pass condition* is the weakness (F5), not the argument. |

### Process spawn / interpreter resolution as root

| Call site | Source (S-label) | Guard | Disposition |
|---|---|---|---|
| `init-firewall.sh:874-875` `"$SNI_PROXY_BIN" --daemon …` | S7 (path), then the file's own `#!/usr/bin/env python3` | `-x` check at `:443`; root:root 0555 from `Dockerfile:410` | Path is env-overridable but sudo-stripped; the *interpreter* is PATH-resolved — F3. |
| `init-firewall.sh:668` `dnsmasq --conf-file=… --pid-file=…` | S7 (config path), S1/S2 (config content) | `command -v` check at `:397`; config generated root-owned 0644; `--conf-file` replaces the packaged one | Config content is regex-gated; binary is PATH-resolved — F3. |
| `init-firewall.sh:427` `pkill -x -U "$DNSMASQ_UID" dnsmasq` | numeric uid validated at `:404` | `-x` exact-name, `-U` uid-scoped | Bounded to a uid nothing else in the container uses. |
| `init-firewall.sh:490` `echo "$DOCKER_DNS_RULES" \| xargs -L 1 iptables -t nat` | captured `iptables-save` text | grep for the literal `127.0.0.11` | Replays rule text as argv. Injection requires the ability to add a nat rule, i.e. NET_ADMIN, which `node` does not hold (capabilities are granted to the container, not to unprivileged uids). Unchanged in this range; recorded, not filed. |
| `init-firewall.sh:928`, `:937` `runuser -u node -- curl` | fixed | util-linux `runuser`, root-only | Correct direction (drops privilege); PATH-resolved — F3. |

### Config-file interpolation

| Call site | Source (S-label) | Guard | Disposition |
|---|---|---|---|
| `init-firewall.sh:205` `echo "server=/$d/$ns"` | S2 (`$d`), S1 (`$ns`) | Hostname regex at `:199` (rejects `/`, `#`, empty labels); octet alternation at `:91` | Both halves constrained to their literal grammar; a rejected name warns and stays unresolvable. |
| `init-firewall.sh:857-869` SNI allowlist write | S2 | `parse_entry` grammar upstream; `rm -f` then `chmod 0444`, root-owned 0755 dir | Not agent-writable. Port-suffix mismatch is F10. |
| `init-firewall.sh:744-745`, `:753` `ipset add` | S3, S4 | CIDR regex `:335`, IP regex `:373`, port range `:129` | Constrained; `-exist` prevents a duplicate from aborting mid-rebuild. |

### Kill by pid read from a file

| Call site | Source (S-label) | Guard | Disposition |
|---|---|---|---|
| `init-firewall.sh:416-423` `kill "$pid"` / `kill -9` | S6 | `tr -dc '0-9'`; `/proc/$pid/comm == "dnsmasq"`; then a uid-scoped `pkill` sweep | TOCTOU between the `comm` read and the kill is real but requires write access to `/run/cc-dnsmasq.pid`, which `node` lacks. |
| `cc-sni-proxy.py:216-228` `os.kill(pid, SIGTERM/SIGKILL)` | S6 | `b"cc-sni-proxy" in /proc/<pid>/cmdline` — a **substring** match over the whole command line, not a comm check; no uid sweep afterwards | Same TOCTOU, same non-writability mitigation. Weaker than the dnsmasq path on two counts (substring vs exact, no sweep); fold into the E7 cleanup rather than a separate finding. |

### `getsockopt` on an untrusted socket

| Call site | Source (S-label) | Guard | Disposition |
|---|---|---|---|
| `cc-sni-proxy.py:145-150` `getsockopt(SOL_IP, SO_ORIGINAL_DST, 16)` | S5 | `try/except (OSError, struct.error, AttributeError)` → `"unknown"` | Result is used only in the log string, never to select a destination — the property the SNI-steering defence rests on. Confirmed by reading `handle()` end to end: `orig` appears in four `log()` calls and nowhere else. |

---

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | IPv6 egress entirely unenforced; new DNS/SNI controls are IPv4-only | High | B4, B5, B7 | `init-firewall.sh:510-512`, `:558-559`; `cc-sni-proxy.py:182-183` | Medium |
| 2 | No mutual exclusion or `-w`; concurrent agent-triggered runs can drop the DNS guards from a "complete" ruleset | High | B3, B4 | `init-firewall.sh:472-483`, `:715-723`, `:731` | Medium |
| 3 | Root helper resolution goes through PATH; immunity rests on an unasserted sudo `secure_path` | Medium | B3 | `init-firewall.sh:430-436`; `cc-sni-proxy.py:1`; `Dockerfile:60-61`, `:354-355`, `:419` | Medium |
| 4 | `cc-sni-proxy.py` is outside the bless manifest | Medium | B2 | `cc-sni-proxy.py:24-25`; `cc-isolated.sh:50-65` | High |
| 5 | Negative SNI probe passes on any curl failure | Medium | B4, B5 | `init-firewall.sh:934-948` | Medium |
| 6 | SNI filtering bypassable via ECH or a multi-entry ServerNameList | Medium | B5 | `cc-sni-proxy.py:85-99`, `:140-142` | Low |
| 7 | `OPENROUTER_API_KEY` present in every session and exfiltrable through base egress | Medium | B1 | `devcontainer.json:138-148` | High |
| 8 | Proxy log is world-readable and unbounded | Low | B8 | `cc-sni-proxy.py:243`, `:296`; `init-firewall.sh:852-854` | High |
| 9 | Proxy is an unbounded single choke point for all agent 443 egress | Low | B5 | `cc-sni-proxy.py:199-209` | High |
| 10 | Port normalisation disagreement blackholes a zero-padded-port entry | Low | B5, B6 | `init-firewall.sh:116-134`, `:857-869` | High |
| 11 | GitHub CIDRs admitted on tcp/22 with no name-layer check | Informational | B4, B6 | `init-firewall.sh:736-746` | High |

---

## Overall Assessment

This range substantially narrows the egress boundary: the ipset moves from `hash:net` to `hash:net,port` and the OUTPUT accept matches `dst,dst`, the bridge /24 accept collapses to owner-scoped udp/tcp 53 to the gateway, a REFUSED-by-default dnsmasq closes recursive-forward tunnelling, and an SNI splice proxy closes the shared-IP half of finding 5 without terminating TLS. The ordering discipline is good — every network read happens in phase A under the live ruleset, DROP precedes the flush, the proxy is proven listening before the redirect that depends on it is installed, and the completion sentinel is the last statement in the file. The two owner-match exemptions (root and each daemon's own uid) are scoped correctly at the address layer, so neither grants a general outbound channel. The residual risk is not in the new mechanisms but in what surrounds them: they are installed only in the IPv4 tables (F1), the script that installs them is agent-invokable with no lock (F2), the interpreter that runs the proxy is PATH-resolved (F3), the proxy itself is the one enforcement file the trust manifest omits (F4), and the probe that is supposed to prove the SNI control is live cannot distinguish it from its absence (F5). F2 and F5 compound: the race produces exactly the state the probes fail to catch. No findings are unreachable-by-construction, and no Endorsement Claim was executed — the review is entirely static, and the live privileged-container check already tracked as a pre-`--bless` requirement (fact-check E5) is a prerequisite for any of these claims to become verified rather than read. **No safe-to-merge conclusion is offered: there are findings within the code paths read, and the endorsement claims are pending execution verification.** F4 in particular should land before the rebuild and re-bless, since re-blessing without it locks in a manifest that does not cover the new enforcement file.

## Goal-Alignment Note
- Answered: yes — full security design review of the enforcement files at `abbd42d`, report saved to `docs/reviews/security-review-2026-09-03-egress-hardening.md`
- Out of scope: `test/init-firewall-rules.bats`, `test/test_cc_sni_proxy.py`, `guides/cc-isolated-usage.md`, `docs/decisions/log.md`, `docs/working/questions.md` — read only to avoid false "missing" claims (pass 2 covers them); escalations E2, E4 and E6 are author/orchestrator decisions and were noted, not adjudicated
- Escalate: (a) E1 — add `cc-sni-proxy.py` to `enforcement_files()` **before** the re-bless, or the bless certifies an incomplete set (F4); (b) F2's lock is a one-line change that removes a High-severity, agent-triggerable path and should go in the same wave; (c) F1's `ip6tables` fail-closed needs a decision on whether IPv6 is disabled at the runtime or handled in the script; (d) E5's live-container check remains the gate on converting any endorsement claim from read-static to executed
