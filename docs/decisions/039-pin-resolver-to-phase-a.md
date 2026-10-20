# 039 — The filtering resolver answers each exact name from the addresses the firewall admitted

- **Goal**: stop tcp/443 names with rotating address pools (`dl.google.com`) from going unreachable between firewall runs, without widening which names or addresses are reachable.
- **Project state**: implemented on `fix/egress-pin-resolver` · takes effect at the next `install.sh` + re-bless · live check queued (questions.md, `egress-pin-resolver-release`).
- **Task status**: decided 2026-10-20 by the implementing agent (DD Path A, confidence ~85%). Full diverge/diagnose/match: `docs/working/dd-egress-pin-resolver.md`.

## Context

Phase A of `init-firewall.sh` resolves each allowlisted name once and admits those addresses in the `allowed-domains` ipset. `cc-sni-proxy.py` resolves the SNI name again on every connection, through the filtering dnsmasq, and connects to the answer. When the upstream pool rotates, the proxy's address is not in the set and its connect fails (`Errno 113`). Herald hit this on 2026-09-28, 10-03, 10-05 and 10-17. Its 30-minute probe on 10-17 saw `dl.google.com` move across five /24s, and only 35% of connects succeeded.

The first fix was `fix/egress-dnsmasq-ipset` (decision 038, which exists only on that branch). It added a second dnsmasq instance with `ipset=` that admits each answer as it is served. It is about 530 lines, it gives that instance CAP_NET_ADMIN, and its live check (Q-117) was never run, because it needs a branch image installed on the host.

## Decision

For every **exact** name phase A resolves, `compose_dnsmasq_conf` emits one `host-record=<name>,<ipv4>` line per admitted address. dnsmasq then answers that name's A query locally from exactly the ipset's addresses, and never forwards it. "Resolve twice and hope the answers match" becomes "resolve once". The names and addresses come from the same loop iteration that fills the ipset, and they are re-validated (HOST_RE, octet regex) where they become directives.

Unchanged: subdomains, other query types and `.zone` entries still forward (`host-record` is exact-name only, confirmed against dnsmasq 2.90); root's phase-A digs bypass dnsmasq, so each run re-pins from the upstream; no process gains a capability; no address is added.

## Why not the alternatives

- **038, a second dnsmasq with `ipset=`.** It covers zones too, but it puts CAP_NET_ADMIN in a DNS parser that the proxy reaches, it is ~530 lines, and four of its dnsmasq behaviours are unobserved. The pin needs no privilege and no new process. If zones ever show the same rotation, 038 is the fallback.
- **Admit Google's ranges** (the handoff's option D, narrow or from `goog.json`). It widens the proxy's reachable addresses, needs either a CIDR grammar or a new boot-time read, and covers only Google.
- **A periodic re-run.** The rotation (5–10 min) beats any sane interval.
- **Exempting the proxy from the address check, or giving the proxy or agent-facing dnsmasq write access to the set.** Each removes a layer or adds a privilege (#55, 038).

## Residuals

- A pinned address that its operator takes out of service stays dead until the next firewall run. Google front-end addresses serve every Google hostname, so for GFE this lasts as long as the address does. The remedy is unchanged (`sudo /usr/local/bin/init-firewall.sh`).
- When phase A got [a, b] and a dies, the proxy connects to the first answer and may pick a. A follow-up would have the proxy try each answer.
- `.zone` names keep the old staleness (base has one zone, `.frame.claudeusercontent.com`).
- AAAA queries for a pinned name still forward. IPv6 is default-denied, so clients fall back to IPv4 as before.

## Revisit trigger

Revisit if any `FAIL sni=<exact name> … not admitted by the ipset` appears in `/run/cc-sni-proxy/proxy.log` on an image built with this change. A pin should make that impossible, so it would mean the pin is not being served. Also revisit if a zone name shows the herald-style rotation; then revive 038's `ipset=` design for zones only.

## Pruned candidates

`[0 decision 038]: ⚠ C2, its second dnsmasq holds CAP_NET_ADMIN; ✗ C7 at ~530 lines` `[1 ipset= in the agent-facing dnsmasq]: [carried from 038 [1]: CAP_NET_ADMIN reachable from the agent's bytes]` `[2 proxy writes the set]: ⚠ C2` `[3 periodic re-run]: [carried from 038 [6]: narrows the window only]` `[4 exempt ccproxy on 443]: [carried from 038 [4]: drops the address layer]` `[5 hardcode 142.250.0.0/15]: covers one vantage and needs a CIDR grammar` `[6 goog.json at boot]: a new boot-time network read, and all of Google` `[7 goog.json baked at build]: survived, but all of Google, and stale between builds` `[9 proxy reads a root-written map]: survived as runner-up; it is [8] inside the proxy and covers 443 only` `[10 retry resolution]: dnsmasq's cache returns the same answer` `[11 root watchdog]: race windows plus a new root daemon` `[12 bake Google artifacts]: a rebuild per dependency` `[13 maven.google.com in the project]: per project, unshown` `[14 TLS interception]: ruled out by #41` `Prior pruning grep: no matches on main for [ipset, dnsmasq, resolv, cidr, sni]; 038's options were carried from the unmerged branch.`

## References

`docs/working/dd-egress-pin-resolver.md`; `devcontainer-config/init-firewall.sh` (`compose_dnsmasq_conf`, phase A `PINNED_HOSTS`); `test/init-firewall-rules.bats` (resolver pins section); decision log #40, #41, #55; `fix/egress-dnsmasq-ipset` (038).
