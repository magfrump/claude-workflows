# DD — cc-isolated egress steering without a loopback redirect

**Goal**: Choose a redesign of the cc-isolated egress boundary's kernel-enforced steering so that non-exempt uids reach the filtering resolver and the SNI proxy, without depending on `REDIRECT`-to-`127.0.0.0/8` for locally generated packets.

**Project state**: `main`, working tree clean · standalone follow-up to decision log rows 40/41/43 (the cc-isolated egress hardening) · not blocked, but every candidate is blocked on one live-container probe before implementation.

**Task status**: `complete` (decision drafted, Path A; implementation and live verification not started)

---

## 0. Why this DD exists

Decision log #43 (2026-09-09) diagnosed the black-holed agent network as a martian-packet drop and shipped the fix: `--sysctl net.ipv4.conf.all.route_localnet=1` in `devcontainer.json` runArgs, plus a phase-A assertion in `init-firewall.sh` refusing to build the boundary without it.

**That fix was applied and did not work.** With `net.ipv4.conf.all.route_localnet = 1` confirmed live, `node` still has no DNS and no tcp/443. So the `docs/working/diagnosis-cc-isolated-login-dns.md` hypothesis log needs one correction before anything else: **H5's causal claim is now REFUTED, not confirmed.** What H5 *did* establish — and what remains solid — is the *correlation*: the only variable between the query that answers and the query that fails is whether the packet traverses a redirect to loopback. What H5 asserted and got wrong is *why*: "the kernel discards it as a martian, and `route_localnet=1` fixes that." The experiment the theory predicted would succeed was run, and it failed. Per the repo's own rule (`feedback_hypothesis_evaluation_rigor` — untested ≠ refuted, but *tested and contradicted* is refuted), H5's mechanism goes in the anti-portfolio.

This matters for candidate generation: it means **the precise kernel mechanism is unknown**, and any candidate whose correctness argument runs through "…because route_localnet now makes 127/8 routable" is resting on a refuted premise. The design that wins should be the one that is correct *whichever* of the surviving mechanisms is real.

### What this bug isn't (carried from the diagnosis doc + this session)

| Ruled out | Tested by | What the refutation eliminates |
|---|---|---|
| SNI-proxy decision logic (allowlist, ipset admission, CDN rotation) | `grep -E '(FAIL\|REJECT)' /run/cc-sni-proxy/proxy.log` — log holds only its `listening` line | The whole tcp/443 decision path; the connection never arrives |
| `compose_dnsmasq_conf` generation | `--print-dnsmasq-conf` | Config generation; the `server=` line is emitted correctly |
| Stale baked image / stale `base.txt` | Re-register + rebuild | Staleness; a *fresh* container fails harder and earlier |
| Resolve-at-start address divergence between root's `dig` and ccproxy's | Both return `160.79.104.10` | Rotation divergence as a cause of *this* failure |
| **`route_localnet` on `conf.all` as the missing precondition** | **Set via `--sysctl`, container recreated, confirmed `= 1` live; node still black-holed** | **The `conf.all` knob. Any design whose correctness depends on it is dead.** |

### Two mechanisms still live (neither confirmed)

- **M1 — output-path re-route failure.** `nf_nat_ipv4_local_fn` calls `ip_route_me_harder()` after the DNAT and returns `NF_DROP_ERR` if the re-route fails. The re-route preserves the already-chosen source (the eth0 address, `FLOWI_FLAG_ANYSRC`) and looks up `127.0.0.1`. If this lookup is what fails, the packet dies inside the nat hook — after the counter increments, which matches evidence item 1 exactly, and before `nat POSTROUTING` or `filter OUTPUT` ever run.
- **M2 — input-path martian on loopback receive.** `ip_rcv` / `ip_route_input_slow` rejects `ipv4_is_loopback(daddr)` unless `IN_DEV_NET_ROUTE_LOCALNET(in_dev, net)`. This is the path decision #43 aimed at — but `IN_DEV_ORCONF` **ORs** the `all` value with the per-device value, so `conf.all = 1` already satisfies it for every `in_dev`. If M2 were the mechanism, #43's fix would have worked. Evidence item 4 is therefore direct counter-evidence against M2 — which is what pushes weight onto M1, or onto something not yet named.

Both M1 and M2 are **specific to a `127.0.0.0/8` destination**. That is the single load-bearing observation for the decision below: a candidate that puts an *ordinary local unicast address* on the destination side is correct under M1, under M2, and under any third `ipv4_is_loopback()`-gated check nobody has found yet. It does not need the mechanism resolved.

---

## 1. Diverge

### 1.0 Pre-generation grep — prior pruning carried forward

`grep -B 1 -A 20 "Pruned candidates" docs/decisions/*.md | rg -i "redirect|resolver|loopback|iptables|egress"`

`Prior pruning grep: no matches found for [redirect, loopback, resolver, iptables]` in any `## Pruned candidates` section. Records 015 and 016 pruned *isolation architectures* (WSL2 distro, bwrap launcher, micro-VM, sidecar workbench), not egress-steering mechanisms.

The prior pruning that *is* relevant lives in the decision **log** rows rather than in full-record Pruned-candidates sections, so it is carried forward explicitly:

- `[resolv.conf rewrite]` — **carried from log #40**: Docker bind-mounts and regenerates `/etc/resolv.conf` on every start, so a rewrite is silently reverted; it also destroys the upstream list `compose_dns_resolvers` needs on re-run; and it is cooperative, not kernel-enforced. Not re-proposed as a primary; re-listed below only as the naive-perspective candidate the health check requires.
- `[squid ssl_bump peek+splice]`, `[sniproxy]` — **carried from log #41**: large apt dependency with a config surface far wider than the job / unmaintained and connects to a static table rather than resolving the SNI. Not revived; nothing about this bug changes those objections.
- `[REDIRECT to 127.0.0.1 + route_localnet]` — **revived from log #43 as candidates 2 and 3, and only as experiments**: #43 chose it and shipped it; the reason to re-examine is that the *variant* of the knob (`conf.default`, `conf.<dev>`) was never separated from the knob itself. See the honest assessment in §4.

### 1.1 Candidates

**0. Status quo (do-nothing).** Keep `REDIRECT --to-ports` at `127.0.0.1` with `conf.all.route_localnet=1` asserted in phase A — i.e. exactly what is shipped and measured broken.

**1. Revert decisions 40 and 41 (reframe).** Delete the filtering resolver and the SNI proxy, restore plain address+port ipset matching, and reopen security-review findings 5 and 6 as known-accepted risks until a design can be live-tested first.

**2. `--sysctl net.ipv4.conf.default.route_localnet=1` (minimal change).** Bet that `conf.default` is the template eth0 inherits at creation, and that the per-device value is what some consult site actually reads.

**3. `--sysctl net.ipv4.conf.eth0.route_localnet=1`.** Bet that Docker applies the OCI sysctl list *after* libnetwork has moved the veth into the netns, so a per-device key is settable after all. Fails loudly (container refuses to start) if the ordering is the other way.

**4. DNAT to the container's own eth0 address.** Both nat chains target `<container-ip>:<port>` instead of `127.0.0.1:<port>`; both daemons bind `<container-ip>` (computed at run time, C6). The destination becomes an ordinary local unicast address — no `ipv4_is_loopback()` check anywhere on the path.

**5. Dedicated dummy interface.** `ip link add cc0 type dummy` + a private `/32` (e.g. `10.255.255.1`); daemons bind it, both nat chains DNAT there. Stable address, independent of Docker's IPAM.

**6. Daemons bind `0.0.0.0`, DNAT to the container address.** Same steering as 4, simplest bind, C4 rests entirely on the `INPUT DROP` policy rather than on the bind.

**7. Link-local `/32` alias on eth0.** `ip addr add 169.254.1.1/32 dev eth0`; DNAT there. Gets candidate 5's address stability without adding an interface or depending on the `dummy` module.

**8. Keep the loopback redirect, SNAT the source to `127.0.0.1`.** Add `-t nat -A POSTROUTING -o lo -d 127.0.0.1 -j SNAT --to-source 127.0.0.1` so no packet ever carries a loopback destination with a non-loopback source.

**9. Policy-route the flow onto `lo` before nat.** `mangle OUTPUT` mark for non-exempt 53/443 + `ip rule add fwmark 1 lookup 100` + `ip route add local default dev lo table 100`, so the *routing decision itself* selects loopback and the source becomes `127.0.0.1` before any rewrite.

**10. Sidecar boundary container.** dnsmasq and `cc-sni-proxy.py` move to a second container on the bridge with its own address; the agent container DNATs 53/443 to that address. No loopback anywhere, and the agent (which has `NET_ADMIN` and NOPASSWD sudo to the firewall script) can no longer kill the daemons it is filtered by.

**11. Gateway netns / `--network container:cc-gw` (ideal if effort were free).** The agent container joins a boundary container's network namespace, or sits behind it as its only route. The agent gets no `NET_ADMIN` at all and cannot see, let alone edit, the boundary.

**12. Abandon transparency: REJECT + published local daemons (naive).** Kernel-enforce *denial* only — REJECT every non-exempt 53/443 flow — and steer cooperatively (`resolv.conf` → `127.0.0.1`, `HTTPS_PROXY`). A process that hardcodes `8.8.8.8` gets a loud rejection instead of transparent filtering.

**13. Rewrite `/etc/resolv.conf` to `nameserver 127.0.0.1` (naive; previously pruned).** Carried from log #40.

**14. `LD_PRELOAD` / seccomp interception of `connect()` (wrong-feeling).** Rewrite the destination in userspace before the syscall reaches the kernel.

**15. Bind the daemons to a veth pair created inside the container.** Variant of 5 that trades the `dummy` module for the `veth` module.

#### Generation health check

- **Clustering**: candidates 4, 5, 6, 7, 15 are one cluster — "change the DNAT target address." Shared assumption: *nat OUTPUT DNAT works in this environment at all, and only the loopback destination is the problem.* Candidates violating it were generated in response: 8 and 9 (keep loopback, change the source), 10 and 11 (move the destination out of the container), 12/13/14 (abandon kernel steering).
- **Missing perspectives**: do-nothing = 0; minimal-change = 2; naive = 12, 13, 14; ideal-if-free = 11; reframe = 1. Present.
- **Vagueness**: every candidate names a specific rule, sysctl key, or topology. None is "use a better approach."
- **Dimensional anchoring**: dimensions moved are — *sysctl value* (2, 3), *NAT destination address* (4, 5, 6, 7, 15), *NAT source address* (8), *routing decision* (9), *process topology* (10, 11), *steering model, kernel vs cooperative* (12, 13, 14), *scope of the boundary* (1). Seven dimensions across fifteen candidates. No anchoring.

`◇ step 1 diverge    15 candidates → docs/working/dd-cc-isolated-loopback-redirect.md`

---

## 2. Diagnose — constraints

### Hard

**C1 — Kernel-enforced DNS steering.** Every non-exempt uid's port-53 traffic reaches the filtering resolver even if the process ignores `/etc/resolv.conf` and hardcodes an address.
`success:` as `node`, `dig api.anthropic.com @8.8.8.8` returns the dnsmasq answer, and `dig somethingunlisted.example.com @8.8.8.8` returns `REFUSED` (not `NXDOMAIN`, not an answer); `iptables -t nat -L CC_DNS -n -v` shows a nonzero counter on the steering rule for both.

**C2 — Kernel-enforced tcp/443 steering.** Same for 443; the agent must never reach the ipset ACCEPT for 443 directly.
`success:` as `node`, `curl --resolve not-allowlisted.invalid:443:<anthropic-ip> https://not-allowlisted.invalid/` fails **and** `/run/cc-sni-proxy/proxy.log` contains `REJECT sni=not-allowlisted.invalid orig_dst=<anthropic-ip>:443` — the `orig_dst` field naming the *pre-NAT* address is what proves the flow arrived through the steering rather than by a direct connection to the proxy's own socket.

**C3 — Exemptions preserved.** DNS: the `dnsmasq` uid and root. 443: the `ccproxy` uid and root. Phase A must work on a fresh container before either daemon exists.
`success:` `iptables -t nat -S CC_DNS` shows `RETURN` for `--uid-owner $DNSMASQ_UID` and `--uid-owner 0` ahead of the steering rule, `CC_SNI` likewise for `$CCPROXY_UID`/`0`; and a run on a fresh container reaches the `Configuring filtering resolver (dnsmasq)...` line with its phase-A `dig`s and `/meta` fetch all successful.

**C4 — Not reachable off-box.** Neither daemon becomes reachable from outside the container.
`success:` from a second container on the same bridge **and** from the WSL2 host: `dig +time=3 +tries=1 api.anthropic.com @<container-ip>` times out, and `nc -vz <container-ip> 3443` fails.

**C5 — Fail closed.** Any incomplete run ends at DROP policies; new preconditions abort in phase A, before the flush, while the previous ruleset is intact.
`success:` the existing bats tests `an aborted run forces DROP policies rather than leaving the container open`, `the flush-to-DROP window contains no network call`, and `all three DROP policies are set before the flush` still pass unchanged, and any new precondition has its own `aborts before the flush` test.

**C6 — No baked container address.** The container IP is not stable across restarts; anything keyed on it is computed at run time inside `init-firewall.sh`.
`success:` `rg -n '\b(172|10|192)\.[0-9]+\.[0-9]+\.[0-9]+\b' devcontainer-config/init-firewall.sh` returns no address literal used as a rule target; after `docker restart`, the installed nat rule's `--to-destination` matches the live `ip route get <gateway>` source.

**C7 — Testability in the existing bats harness.** `test/init-firewall-rules.bats` runs the script for real with PATH stubs and asserts the command sequence; candidates must stay assertable that way, and must state explicitly what is *not* covered.
`success:` `bats test/init-firewall-rules.bats` passes with new assertions naming the new rule form, **and** the decision record carries a "live-container check" section with one runnable command per kernel-semantics assumption.

**C8 — No dependency on a sysctl unsettable from inside the container.** `/proc/sys` is read-only under Docker; `sysctl -w` returns EPERM even as root with `CAP_NET_ADMIN`. A container-creation-time knob makes every fix require a *recreate*, not a rebuild, and a per-interface key cannot be set that way at all.
`success:` the boundary builds and all probes pass on a container created with **no** `--sysctl` runArgs.

**C9 — Rule-order invariants intact.** The steered flow must still be accepted before the ipset accept; the ipset accept must remain unreachable to `node` for 443; the DNS guards must still precede the `-o lo` accept; the 127.0.0.11 bypass jump must still precede it too.
`success:` bats `the 127.0.0.11 bypass reject precedes the loopback accept`, `a missing tcp/443 redirect rule fails verification even with a logged refusal`, and `every boundary rule is asserted present before completion` all pass against the new rule literals.

**C10 — Correct under mechanism uncertainty.** Because neither M1 nor M2 is confirmed, the chosen candidate's correctness argument must not depend on which one is real.
`success:` the candidate's correctness argument cites no `ipv4_is_loopback()`-gated kernel behaviour and no `route_localnet` value; the Probe-1 command in §6 returns an answer.

### Soft

**S1 — `SO_ORIGINAL_DST` semantics unchanged**, so the proxy's log discriminator and the negative probe survive without a Python change.

**S2 — Minimal, auditable diff.** The boundary is read by humans and re-derived by future sessions; prefer the candidate whose new rules need the fewest new "why" comments.

**S3 — No new package in the image.** Decision 41 chose ~300 lines of stdlib Python specifically to avoid one.

**S4 — Loud failure over silent degradation.** Consistent with the uv / Android-SDK / rust stance (log #18/#19/#26) and with the reason #43's assertion existed at all.

`◇ step 2 diagnose    14 constraints (10 hard · 4 soft) → docs/working/dd-cc-isolated-loopback-redirect.md`

---

## 3. Match and prune

✓ addresses well · ~ partial or uncertain · ✗ doesn't address · ⚠ actively makes worse

| # | Approach | C1 | C2 | C3 | C4 | C5 | C6 | C7 | C8 | C9 | C10 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | Status quo (REDIRECT + `conf.all`) | ✗ | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ | ⚠ |
| 1 | Revert 40 + 41 | ✗ | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 2 | `conf.default.route_localnet=1` | ~ | ~ | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ | ⚠ |
| 3 | `conf.eth0.route_localnet=1` | ~ | ~ | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ | ⚠ |
| **4** | **DNAT to own eth0 address** | **✓** | **✓** | **✓** | **~→✓** | **✓** | **✓** | **✓** | **✓** | **✓** | **✓** |
| **5** | **Dummy interface + DNAT** | **✓** | **✓** | **✓** | **✓** | **~** | **✓** | **✓** | **✓** | **✓** | **~** |
| **6** | **Bind `0.0.0.0` + DNAT** | **✓** | **✓** | **✓** | **~** | **✓** | **✓** | **✓** | **✓** | **✓** | **✓** |
| **7** | **Link-local `/32` alias + DNAT** | **✓** | **✓** | **✓** | **✓** | **✓** | **✓** | **✓** | **✓** | **✓** | **~** |
| 8 | REDIRECT + SNAT source to loopback | ~ | ~ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ⚠ |
| 9 | fwmark + `local default dev lo` | ~ | ~ | ✓ | ✓ | ~ | ✓ | ~ | ✓ | ~ | ⚠ |
| 10 | Sidecar boundary container | ✓ | ✓ | ~ | ⚠ | ~ | ✓ | ✗ | ✓ | ~ | ✓ |
| 11 | Gateway netns | ✓ | ✓ | ~ | ✓ | ~ | ✓ | ✗ | ✓ | ~ | ✓ |
| 12 | REJECT + cooperative steering | ✗ | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 13 | `resolv.conf` rewrite | ✗ | ✗ | ✓ | ✓ | ✓ | ✓ | ~ | ✓ | ✓ | ✓ |
| 14 | `LD_PRELOAD` / seccomp | ✗ | ✗ | ~ | ✓ | ✗ | ✓ | ✗ | ✓ | ✗ | ✓ |
| 15 | veth pair inside the container | ✓ | ✓ | ✓ | ✓ | ~ | ✓ | ✓ | ✓ | ✓ | ~ |

### Prune reasoning

- **0** — ⚠ on C10; it *is* the measured failure. Discarded.
- **1** — clean on everything except the two constraints that are the entire point. Discarded as a design; **retained as the named fallback of last resort** (see the trigger-bound rule in §4), because a boundary that is honestly open beats a boundary that silently black-holes and looks healthy to root.
- **2, 3** — `~` on C1/C2 because they might work; ⚠ on C10 because their correctness argument runs entirely through the refuted premise, and ✗ on C8 because both are container-creation-time knobs. **Discarded as designs; retained as free-riding experiments** (§4, Q5).
- **8** — ⚠ on C10. Under M1 the packet is already dropped inside `nf_nat_ipv4_local_fn` (which re-routes and returns `NF_DROP_ERR`) *before* `nat POSTROUTING` runs, so the SNAT never gets a chance to fire. It can only work if M2 is the mechanism — and M2 is the one the evidence argues against. Discarded.
- **9** — ⚠ on C10 for the same reason plus a second: `iptable_mangle_hook` re-routes via `ip_route_me_harder()`, which *preserves* `iph->saddr` (the already-chosen eth0 address) under `FLOWI_FLAG_ANYSRC`. Marking the packet moves the route but not the source, so the loopback-destination-with-non-loopback-source condition survives. Also `~` on C7 (`ip rule`/`ip route` are new stub surfaces). Discarded.
- **10** — ⚠ on C4: a sidecar on the default bridge is addressable by every other container on it, so the daemons become a *shared* filtered resolver rather than a per-container one; fixing that needs a per-project user-defined network, which is a decision-016 architecture change. ✗ on C7: the bats suite runs `init-firewall.sh`; a two-container topology is outside its reach. Discarded for this fix; **named as the Reverse-branch fallback** if the DNAT family is disproven.
- **11** — the ideal-if-free option; strictly the best C1/C2/C4 story and it removes `NET_ADMIN` from the agent entirely. ✗ on C7 and a rewrite of decisions 015/016. Discarded for this fix; recorded as the long-term direction.
- **12** — ✗ on C1/C2 by construction: it kernel-enforces *denial* but steers cooperatively, so a client that hardcodes a resolver breaks loudly rather than being filtered. That is arguably a defensible security posture, but it is not the constraint set. Discarded.
- **13** — ✗ on C1; carried pruning from log #40 (Docker regenerates the file; it destroys the upstream list; it is cooperative). Discarded.
- **14** — ✗ on C1/C5/C7/C9: defeated by any static binary or direct syscall, and unassertable. The wrong-feeling candidate that stays wrong. Discarded.
- **15** — functionally identical to 5 with a different module dependency. Folded into 5 rather than carried separately.

### Fix sketches for survivors

- **4** — C4 is `~` because the daemons move from a loopback bind to an address other bridge neighbours can *address* (they still cannot reach it: `INPUT` policy is DROP with only `-i lo` and ESTABLISHED accepted). **Fix**: add three explicit `INPUT ! -i lo -p {udp,tcp} --dport 53 / -p tcp --dport $SNI_PORT -j DROP` rules alongside the existing `INPUT ! -i lo -d 127.0.0.0/8 -j DROP` martian guard, and add them to the end-of-run `-C` assertion list. That restores belt-and-braces: the policy closes it, and a rule states the invariant. → C4 becomes ✓.
- **5** — C5 is `~` because `ip link add cc0 type dummy` is a new phase-B operation that can fail (the `dummy` module may not be loadable in Docker Desktop's kernel, and `modprobe` from a container needs it present host-side). **Fix**: probe it in phase A (`ip link add cc-probe type dummy && ip link del cc-probe`) so a missing module aborts before the flush. C10 stays `~` regardless: it substitutes one unverified kernel feature for another, which is the exact bug class.
- **6** — C4 stays `~`: a wildcard bind means the daemons listen on every present and future address, and the only thing between them and the bridge is the policy. Not fixable without giving up the wildcard, which turns it into candidate 4.
- **7** — C10 is `~`: `169.254.0.0/16` has its own kernel special-casing (`ipv4_is_linklocal_169`, scope-link assignment by iproute2), so it trades a documented `ipv4_is_loopback()` gate for a less-travelled one. Fixable only by testing it live — at which point candidate 4 has already been tested and is simpler.

`◇ step 3 match       4 of 15 survived → [4] [7] [5] [6]`

---

## 4. Tradeoff matrix and decision

| # | Approach | Effort | Risk | Coverage (hard) | Key downside |
|---|---|---|---|---|---|
| 4 | DNAT to own eth0 address | ~0.5 d code + 0.5 d live verify | low | 10/10 (with the INPUT-drop fix) | Daemons are *addressable* (not reachable) from the bridge; C4 now leans on rules rather than on the bind (mitig.) |
| 7 | Link-local `/32` alias + DNAT | ~0.6 d | medium | 9/10 (C10 `~`) | Swaps a known kernel gate for a less-travelled one — same bug class that produced this incident |
| 5 | Dummy interface + DNAT | ~0.9 d | medium | 8/10 (C5, C10 `~`) | New kernel-module dependency inside a container whose kernel is Docker Desktop's |
| 6 | Bind `0.0.0.0` + DNAT | ~0.4 d | low-med | 9/10 (C4 `~`) | Wildcard bind: every present and future interface, with only the DROP policy between it and the bridge |

### Falsifiable hypotheses

- **[4]** If chosen, a `node`-run `dig api.anthropic.com` answers and `curl https://api.anthropic.com/` returns a status code within one container recreate, with `/run/cc-sni-proxy/proxy.log` showing `ALLOW sni=api.anthropic.com -> <ip>:443 orig_dst=<real-anthropic-ip>:443`; counter-evidence = the node `dig` still returns `host unreachable`, or the proxy log still holds only its `listening` line, while `iptables -t nat -L CC_DNS -n -v` shows a nonzero counter.
- **[7]** As [4], plus: `ip addr add 169.254.1.1/32 dev eth0` succeeds and `ip route get 169.254.1.1` reports `local … dev lo`; counter-evidence = the DNAT lands but the packet is dropped, or the reply is not un-NAT'd (`dig` sees a reply from `169.254.1.1` instead of the original nameserver).
- **[5]** As [4], plus: `ip link add cc0 type dummy` succeeds; counter-evidence = `RTNETLINK answers: Operation not supported`.
- **[6]** As [4]; counter-evidence additionally = a second container on the bridge reaches `<container-ip>:53`, proving the wildcard bind is not covered by the policy.
- **[2] / [3] (experiments, not designs)** If applied, `/proc/sys/net/ipv4/conf/eth0/route_localnet` reads `1` after a recreate **and** the existing REDIRECT starts working for `node`; counter-evidence = eth0's knob still reads `0` (Docker applies the sysctl list before the veth is in the netns), or it reads `1` and node's `dig` still fails — either outcome kills the whole `route_localnet` theory in one rebuild.

### Stress-test pass

**Boring alternative** (applied to [4]). Is [6] the 80% version? It is genuinely simpler — no address needed for the bind, only for the DNAT target. But [4]'s extra cost is one `ip route get` in a script that already computes `HOST_IP` from `ip route` at line 958; the marginal complexity is a single variable. [6] pays for that saving with C4, which is a hard constraint. Complexity earns its keep. *No matrix change; [6] confirmed as [4]'s fallback rather than its equal.*

**Invert the thesis** (applied to [4], arguing for [5]). Sincere case for the dummy interface: its address is chosen by us, not by Docker's IPAM, so the rule literals are stable across restarts and easier to reason about in `iptables -S` output; and it is never an address a bridge neighbour can even *name*. Counter: the address only ever exists inside one running script's variables — nothing persists it across runs, so "stability" buys nothing that a run-time computation doesn't; and the module dependency is a new unverified kernel feature in the environment that just burned us on an unverified kernel feature. The C4 half of the argument survives, though. *Matrix change: [4]'s C4 upgraded from `~` to `✓` by adopting the explicit `INPUT ! -i lo --dport {53,3443} -j DROP` rules — a mitigation lifted directly from [5]'s strength.*

**Failure-driven** (applied to [4]). New failure categories this candidate introduces:
1. *No derivable source address* (`--network none`, host networking, an exotic compose network). `ip route get` returns nothing usable and the script would install `--to-destination :53`. → **must** validate the address with the same octet grammar `compose_dns_resolvers` uses and abort in phase A. Becomes a code requirement and a bats test.
2. *DNAT target and daemon bind disagree* (script reads one address, dnsmasq binds another, e.g. on a multi-homed container). → **must** compute once into a single variable and pass that same variable to the DNAT rule, `listen-address=`, and `--listen`. Becomes a bats assertion.
3. *Bridge neighbour probes the daemon ports.* → mitigated above.
4. *Container renumbered while running.* Docker does not renumber a running container, and `init-firewall.sh` runs on every `postStartCommand`, so the address is recomputed at every start. Residual accepted; recorded as a revisit trigger.
*Matrix change: [4]'s effort revised up from ~0.3 d to ~0.5 d to absorb requirements 1 and 2.*

**Revealed preferences** (applied across). What do transparent proxies actually do? `redsocks`, `mitmproxy`, and squid's intercept mode all document `-t nat -A OUTPUT -j REDIRECT --to-port <n>` with the daemon on `127.0.0.1`, and it works on ordinary Linux — which is exactly why decision 41 believed it and why the reviewers waved it through. The variable here is the *environment* (Docker Desktop on WSL2), not the pattern. That is not an argument for any candidate; it is an argument that **no candidate may be blessed on pattern-familiarity again**, which is what makes the §6 live checklist a gate rather than a courtesy. *No matrix change; it hardens C7's success line.*

### Decision presentation

```
┌─ DECISION: steer non-exempt 53/443 to the in-container daemons without a 127/8 redirect ─┐
│ 4 candidates survived step-3 pruning · scored on the step-4 axes                          │
└───────────────────────────────────────────────────────────────────────────────────────────┘

  legend   ● strong / low   ◐ partial / medium   ○ weak / high   ✗ fails hard constraint

   #    approach                     effort        risk       coverage        key downside
  ───  ─────────────────────────  ────────────  ──────────  ──────────────  ─────────────────────────────
   4 ★ DNAT to own eth0 addr       ● 1.0 d       ● low       ● 10/10 hard    ◐ daemons addressable from bridge (mitig.)
   7   link-local /32 alias        ● 0.6 d       ◐ med       ◐  9/10 hard    ○ untested kernel gate — same bug class
   6   bind 0.0.0.0 + DNAT         ● 0.4 d       ◐ low-med   ◐  9/10 hard    ○ wildcard bind; C4 rests on policy alone
   5   dummy interface + DNAT      ◐ 0.9 d       ◐ med       ○  8/10 hard    ○ needs the `dummy` module in DD's kernel
```

```
╭─ [4] DNAT to own eth0 address   ★ recommended ──────────────────────────╮
│ effort    1.0 d (~40-line script diff, 0-line proxy diff,               │
│           ~10 bats edits + 3 new; 0.5 d of live probes)                 │
│ risk      low            coverage  10/10 hard · 4/4 soft                │
│ hypothesis  If chosen, a node-run `dig api.anthropic.com` answers and   │
│             `curl https://api.anthropic.com/` returns a status code     │
│             within one container recreate, with the proxy log showing   │
│             ALLOW … orig_dst=<real-anthropic-ip>:443; counter-evidence  │
│             = node's dig still returns `host unreachable` while the     │
│             CC_DNS counter is nonzero.                                  │
│ stress-tests applied                                                    │
│   · Boring alternative → [6] confirmed as fallback, not equal           │
│   · Invert the thesis  → C4 lifted ~→✓ via explicit INPUT port drops    │
│   · Failure-driven     → address validation + single-variable rule;     │
│                          effort 0.3 d → 0.5 d                           │
│   · Revealed preferences → hardened C7 into a bless gate                │
│ key downside  Daemons bind an address the bridge can name; closed by    │
│               INPUT DROP + three explicit port drops (mitig. — see      │
│               Stress-test mitigations)                                  │
╰─────────────────────────────────────────────────────────────────────────╯
```

`▶ recommend [4] DNAT to own eth0 address · confidence 85% · runner-up [6], axis = bind narrowness vs diff size`

**Drill-down**: cards for [5], [6], [7] are collapsed to their scorecard rows; name a `#` to expand one.

### Decision — Path A (one approach dominates, 85% confidence)

**Chosen: candidate 4 — DNAT both nat chains to the container's own eth0 address, computed at run time, with both daemons binding that same address.**

It is the only survivor whose correctness argument cites no `127.0.0.0/8`-gated kernel behaviour and no sysctl (C10, C8), it keeps every rule shape the bats suite already asserts (C7, C9), it changes zero lines of `cc-sni-proxy.py`, and after the invert-the-thesis mitigation it covers all ten hard constraints. [6] loses on C4 alone; [7] and [5] each trade the loopback unknown for a *different* unverified kernel feature, which is precisely the failure mode this DD exists to stop repeating.

Confidence is 85%, not higher, for one reason: if mechanism **M1** is real and the failure is in the generic `ip_route_me_harder()` re-route to *any* `RTN_LOCAL` destination rather than in the loopback-specific gates, then [4], [5], [6] and [7] all fail together. Nothing in the current evidence set discriminates. **That is what Probe 1 in §6 is for, and it must run before a line of code is written.**

#### Trigger-bound decision rule (evidence arrives after the design commits)

| Branch | Trigger condition | Action |
|---|---|---|
| **Continue** | Probe 1 (§6) — a `node`-run `dig` through a hand-installed `DNAT --to-destination <container-ip>:53` answers | Implement candidate 4 as specified in §5 |
| **Revisit** | Probe 1 answers only intermittently, or answers for udp/53 but Probe 2 (tcp/3443) does not | Re-run the step-4 stress test with the measured asymmetry before committing; [6] and [7] re-enter as live options |
| **Reverse** | Probe 1 does **not** answer while `iptables -t nat -L OUTPUT -n -v` shows the rule matching | Mechanism M1 is real: nat-OUTPUT DNAT to any local address is broken here. The whole DNAT family is dead — fall back to **candidate 10 (sidecar boundary container)**, whose destination is a genuinely remote address, and re-scope for the decision-016 network change it implies. If that is out of budget, **candidate 1 (revert 40+41)** is the honest floor: an open-and-known boundary beats one that black-holes while looking healthy. |

Pre-naming candidate 10 matters here: under Reverse-branch pressure the cheap instinct will be to try candidates 5 and 7 one at a time, which are the *same* bet at a different address.

---

## 5. What exactly changes (candidate 4)

### `devcontainer-config/init-firewall.sh`

1. **Delete** the route_localnet precondition block (lines 559–596) and the `CC_ROUTE_LOCALNET_PATH` seam. It is now a *false* precondition — it would abort on any container created without the runArg, blocking the actual fix.
2. **Add**, in phase A alongside the dnsmasq/SNI preconditions (so it aborts before the flush, C5), a single run-time address computation:

   ```sh
   # The one address both daemons bind and both nat chains target. Docker
   # renumbers the container on every create, so nothing may be baked (C6);
   # `ip route get` is a routing-table query, not a packet, so it is safe in
   # phase A. Taking the SOURCE the kernel would choose for an off-box
   # destination is deliberate: it is exactly the source address the redirected
   # packet carries, so destination and source end up on the same interface.
   CONTAINER_IP="$(ip -4 route get "$(ip route | awk '/^default/{print $3; exit}')" 2>/dev/null \
                   | awk '{for (i=1;i<NF;i++) if ($i=="src") { print $(i+1); exit }}')"
   ```
   Then validate it with the same octet grammar `compose_dns_resolvers` enforces, and abort with a named error if it is empty or malformed (failure category 1 from the stress test). **Move `HOST_IP` detection (currently line 958) into phase A too**, since this depends on it.
3. **`CC_DNS` steering** (lines 876–877): `-j REDIRECT --to-ports 53` → `-j DNAT --to-destination "$CONTAINER_IP:53"`, for both udp and tcp. Chain structure, the two `RETURN`s, and the `-I OUTPUT 1` insert positions are unchanged (C3, C9).
4. **`CC_SNI` steering** (line 1088): `-j REDIRECT --to-ports "$SNI_PORT"` → `-j DNAT --to-destination "$CONTAINER_IP:$SNI_PORT"`.
5. **DNS guard jumps** (lines 922–923): today `-p udp --dport 53 ! -d 127.0.0.1 -j CC_DNS_GUARD`. Under DNAT the steered packet carries `-d $CONTAINER_IP`, so **as written today these two rules would REJECT the very traffic the redesign steers.** They become `! -d 127.0.0.1 ! -d "$CONTAINER_IP"` (keeping 127.0.0.1 permitted so the `dig @127.0.0.1` diagnostic that cracked this incident keeps working). Update the matching literals in the end-of-run `-C` assertion list (lines 1122–1123) in the same edit — the script's own drift-detection depends on the two agreeing.
6. **C4 guards** — new, placed with the martian guard at line 915, i.e. before the `-i lo` accept and before the ESTABLISHED accept at line 1003:
   ```sh
   iptables -A INPUT ! -i lo -p udp --dport 53 -j DROP
   iptables -A INPUT ! -i lo -p tcp --dport 53 -j DROP
   iptables -A INPUT ! -i lo -p tcp --dport "$SNI_PORT" -j DROP
   ```
   Add all three to the end-of-run `-C` assertion list. Keep `INPUT ! -i lo -d 127.0.0.0/8 -j DROP` — with the sysctl gone, 127/8 is non-routable by default again and the guard becomes a cheap statement of an invariant rather than a load-bearing rule.
7. **Comments**: the `HOW TRAFFIC IS STEERED` block (lines 782–799) and the `SNI PROXY` header (lines 1017–1028) both say "REDIRECT … to 127.0.0.1". Rewrite to name the container address and to record *why* loopback was abandoned, with a pointer to this document. The `MARTIAN GUARD` comment (907–914) loses its `route_localnet=1 is what makes the two nat REDIRECTs work` premise entirely.
8. **Probe-log discriminator comment** (lines 1177–1180): "a direct connection to `127.0.0.1:3443` … would log `orig_dst=127.0.0.1:3443`" → `$CONTAINER_IP:$SNI_PORT`. The grep at line 1181 asserts `orig_dst=$ANTHROPIC_PROBE_IP:443` and is **unchanged** — the pre-NAT address is still the discriminator.

### `compose_dnsmasq_conf` (lines 199–235)

Takes a **third argument**, the bind address, and emits two lines where it emits one today:

```
listen-address=127.0.0.1
listen-address=<container-ip>
```

`bind-interfaces`, `port=53`, `user=dnsmasq`, `no-resolv`, `no-hosts`, `no-poll` and the `server=/…/` generation are untouched. `bind-interfaces` plus explicit `listen-address` means dnsmasq still never binds a wildcard — that is the C4 property, with the INPUT drops as the second layer. Update the two call sites: the `--print-dnsmasq-conf` hook (line 238; pass a fixed placeholder so the hook stays offline and the bats assertions stay deterministic) and the real call at line 846.

### `devcontainer-config/cc-sni-proxy.py`

**No code change.** `--listen` is already a `host:port` string parsed by `rpartition(":")` (line 210), so `--listen 172.17.0.2:3443` works as-is; `original_dst()` (line 151) is unchanged. Docstring only: lines 4–7 say "REDIRECTs … to `127.0.0.1:<port>`" → "DNATs … to `<container-address>:<port>`". Leave the `--listen` default at `127.0.0.1:3443` — `init-firewall.sh` always passes it explicitly, and the default is only a convenience for the Python unit tests' loopback splice cases.

### `devcontainer-config/devcontainer.json`

Delete `"--sysctl", "net.ipv4.conf.all.route_localnet=1"` and its ~20-line comment block (lines ~45–67). `--cap-add=NET_ADMIN` and `--cap-add=NET_RAW` stay. Replace the comment with a short note recording that the boundary deliberately needs **no** sysctl, so future boundary changes need only a rebuild, not a container recreate — that is a real operational win and it should be stated so nobody re-adds a sysctl casually.

### `test/init-firewall-rules.bats`

- **Delete**: `route_localnet=0 aborts before the flush and names the runArg` (1032), `an unreadable route_localnet knob aborts before the flush` (1045), and the `CC_ROUTE_LOCALNET_PATH` seam in `setup()` (209–213).
- **Update literals**: `tcp/443 is redirected to the proxy for every uid except ccproxy and root` (781), `the 127.0.0.11 bypass reject precedes the loopback accept` (589), `the negative probe asserts the nat redirect rule` (930), `a refusal logged from a direct loopback connection does not satisfy the probe` (936), `a missing tcp/443 redirect rule fails verification` (1018), `every boundary rule is asserted present before completion` (986), and the `print-dnsmasq-conf` tests (486, 510, 520) for the second `listen-address` line.
- **Add**: (a) both nat steering rules target the same run-time-computed address and no literal is baked; (b) `listen-address=`, `--to-destination` and `--listen` all carry that one address; (c) a container with no derivable IPv4 source address aborts before the flush; (d) the three new `INPUT ! -i lo --dport` drops precede the ESTABLISHED accept and are in the assertion list.

### Docs

- New `docs/decisions/log.md` row superseding #43, cross-referencing this document.
- Amend #43 in place (or in the new row) to record that `route_localnet=1` was applied, verified live, and **did not** restore the redirect.
- Update `docs/working/diagnosis-cc-isolated-login-dns.md`: status `resolved` → `reopened`; H5's outcome downgraded from CONFIRMED to **correlation confirmed / mechanism REFUTED**, with the `What this bug isn't` table from §0 folded into its hypothesis log.

### Q3 — does this interact with `SO_ORIGINAL_DST`?

**No, and the reason is structural rather than incidental.** `REDIRECT` is not a separate NAT operation — `nf_nat_redirect_ipv4()` computes `newdst` (hardcoded to `127.0.0.1` on the `LOCAL_OUT` hook) and then calls the same `nf_nat_setup_info()` that any `DNAT --to-destination` calls. `SO_ORIGINAL_DST` is served by conntrack's getsockopt handler, which looks the flow up by the accepted socket's 4-tuple and returns the reply tuple's source — i.e. the pre-NAT destination — with no knowledge of which target module wrote the mapping. So `original_dst()` at `cc-sni-proxy.py:151` returns the real `api.anthropic.com:443` under DNAT exactly as it does under REDIRECT.

One consequence worth writing down: the *negative* case changes cosmetically. Today a direct connection to the proxy's own socket logs `orig_dst=127.0.0.1:3443`; under candidate 4 it logs `orig_dst=<container-ip>:3443`. The end-of-run probe greps for `orig_dst=$ANTHROPIC_PROBE_IP:443`, so the discriminator is unaffected — only the comment explaining it needs the new address. **Confirm live with Probe 2 anyway** (§6); this paragraph is a source-reading, and source-readings are what shipped this bug.

---

## 6. Live-container checklist — the bless gate

> ### STATUS — 2026-09-09: boundary VERIFIED LIVE, gate partially discharged
>
> A container built from the fixed script comes up, `init-firewall.sh` completes, and a
> session reaches the Anthropic API. That single fact discharges three probes, because
> the script's own end-of-run verification asserts them and fails closed without them:
>
> | Probe | Status | What discharged it |
> |---|---|---|
> | **1** — DNAT to a local address delivers | ✅ satisfied | The `node`-run positive SNI probe reaches `api.anthropic.com`, which needs both the udp/53 and the tcp/443 steering to work end to end. Supersedes the flawed pre-implementation run (which flushed the filter table — see the note under Probe 1). |
> | **2** — `SO_ORIGINAL_DST` intact under DNAT | ✅ satisfied | The negative probe greps for `REJECT sni=not-allowlisted.invalid orig_dst=$ANTHROPIC_PROBE_IP:443` — the **pre-NAT** address, which only conntrack can supply. Reaching `FIREWALL_COMPLETE=1` proves the grep matched. |
> | **6** — boots with no sysctl at all | ✅ satisfied | `devcontainer.json` carries no `--sysctl`; the container came up anyway. |
> | **3** — daemons unreachable off-box | ⬜ outstanding | The three `INPUT ! -i lo` drops are asserted *present*, but their effect has never been probed from the host or a second container. Presence ≠ effect — that distinction is the whole incident. |
> | **4** — hardcoded-resolver bypass refused | ⬜ outstanding | Not exercised by the boot run. |
> | **5** — address recomputed across restart | ⬜ outstanding | One boot cannot show this; needs a stop/start that renumbers the container. |
>
> Probes 3, 4 and 5 are **not** blockers on the fix — they check properties the design
> claims, not the outage it repaired — but leaving them unrun is the same debt that
> produced this incident, so they are tracked rather than closed.

This is the whole lesson of the incident: decisions 40 and 41 both shipped with the phrase *"needs a live-container check … before bless"*, and that check never ran. **Probe 1 runs before implementation, not after.** It is the discriminator between Continue and Reverse in §4's decision rule, and it takes about ten minutes.

Run everything as root inside the container unless a line says otherwise. Root is exempt from both chains, so **every functional probe must go through `runuser -u node --`** — a root-run probe proves nothing, which is exactly how the boundary looked healthy while the agent had no network.

### Preflight — record the environment

```sh
ip -4 -o addr show scope global
ip route
ip route get "$(ip route | awk '/^default/{print $3; exit}')"     # must print `src <container-ip>`
cat /proc/sys/net/ipv4/conf/{all,default,eth0,lo}/route_localnet
cat /proc/sys/net/ipv4/conf/{all,default,eth0,lo}/rp_filter
cat /etc/resolv.conf
```

### Probe 1 — THE decisive check: does nat-OUTPUT DNAT to a local non-loopback address deliver?

Run on a container whose `postStartCommand` has already failed (so the firewall is at DROP), with the boundary deliberately out of the way:

```sh
iptables -F; iptables -t nat -F; iptables -P OUTPUT ACCEPT; iptables -P INPUT ACCEPT
CIP=$(ip -4 route get "$(ip route | awk '/^default/{print $3; exit}')" \
      | awk '{for(i=1;i<NF;i++) if($i=="src"){print $(i+1); exit}}'); echo "CIP=$CIP"
NS=$(awk '/^nameserver/{print $2; exit}' /etc/resolv.conf); echo "NS=$NS"

pkill -x dnsmasq
dnsmasq --no-daemon --no-resolv --no-hosts --bind-interfaces \
        --listen-address=127.0.0.1 --listen-address="$CIP" \
        --server=/api.anthropic.com/"$NS" &

# 1a — bind reachability, no NAT involved. Must ANSWER.
runuser -u node -- dig +time=3 +tries=1 +short api.anthropic.com @"$CIP"

# 1b — THE LINE THAT DECIDES THE DESIGN. Must ANSWER.
iptables -t nat -A OUTPUT -p udp --dport 53 -m owner ! --uid-owner 0 \
         -j DNAT --to-destination "$CIP:53"
runuser -u node -- dig +time=3 +tries=1 +short api.anthropic.com

# 1c — the rule must have matched (nonzero counter), whatever 1b did.
iptables -t nat -L OUTPUT -n -v
```

- **1b answers** → mechanism is loopback-specific; candidate 4 is sound. **Continue.**
- **1b fails with a nonzero counter in 1c** → nat-OUTPUT DNAT to *any* local address is broken here (mechanism M1). The whole DNAT family dies together. **Reverse** to candidate 10.

> **Outcome (2026-09-09): 1b PASSED and the decision continued — but the probe as written flushes the filter table, so it cannot see a filter-side rejection of the rewritten packet. It missed mechanism M3 (see §7), which cost a further round. Before re-using this probe, install the rules under test into the *live* ruleset instead of clearing it.**
- **1a fails** → the problem is not NAT at all; stop and re-diagnose from scratch.

### Probe 2 — tcp/443 through DNAT, with `SO_ORIGINAL_DST` intact

```sh
/usr/local/bin/cc-sni-proxy.py --daemon --pidfile /tmp/p.pid --user ccproxy \
    --listen "$CIP:3443" --allowlist /run/cc-sni-proxy/allowlist --log /tmp/p.log
iptables -t nat -A OUTPUT -p tcp --dport 443 -m owner ! --uid-owner 0 \
         -j DNAT --to-destination "$CIP:3443"

runuser -u node -- curl -sS --connect-timeout 5 --max-time 15 \
        -o /dev/null -w '%{http_code}\n' https://api.anthropic.com/
grep 'sni=api.anthropic.com' /tmp/p.log
# REQUIRED: the line reads ALLOW sni=api.anthropic.com -> <ip>:443 orig_dst=<REAL-ANTHROPIC-IP>:443
# NOT orig_dst=$CIP:3443 — that would mean SO_ORIGINAL_DST lost the pre-NAT destination
# and the negative probe's discriminator is gone.

# Negative: forged SNI against an admitted address must be refused, through the DNAT.
AIP=$(dig +short api.anthropic.com @"$CIP" | head -1)
runuser -u node -- curl -sS --connect-timeout 5 --max-time 15 \
        --resolve "not-allowlisted.invalid:443:$AIP" https://not-allowlisted.invalid/ ; echo "exit=$?"
grep "REJECT sni=not-allowlisted.invalid orig_dst=$AIP:443" /tmp/p.log
```

### Probe 3 — C4, from outside the container

```sh
# host side (WSL2), with the container running:
dig +time=3 +tries=1 api.anthropic.com @<CIP>      # must TIME OUT
nc -vz <CIP> 3443                                  # must FAIL
nc -vzu <CIP> 53                                   # must FAIL

# from a second container on the same bridge:
docker run --rm --network bridge nicolaka/netshoot \
    dig +time=3 +tries=1 api.anthropic.com @<CIP>  # must TIME OUT
docker run --rm --network bridge nicolaka/netshoot nc -vz <CIP> 3443   # must FAIL
```

### Probe 4 — C1/C2 kernel enforcement (the hardcoded-resolver case)

```sh
runuser -u node -- dig +time=3 +tries=1 api.anthropic.com @8.8.8.8   # must ANSWER (steered to dnsmasq)
runuser -u node -- dig +time=3 +tries=1 notallowed.example.com @8.8.8.8   # must be REFUSED
runuser -u node -- curl -sS --connect-timeout 5 --max-time 15 https://example.com/ ; echo "exit=$?"  # must FAIL
```

### Probe 5 — C6, across a restart

```sh
docker restart <container>
# then inside:
ip route get "$(ip route | awk '/^default/{print $3; exit}')"   # note the src
iptables -t nat -S CC_DNS ; iptables -t nat -S CC_SNI           # --to-destination must equal that src
grep listen-address /etc/dnsmasq.d/cc-allowlist.conf            # must equal it too
```

### Probe 6 — C8, no sysctl at all

Recreate with the `--sysctl` runArg removed and confirm the full boot succeeds:

```sh
devcontainer up --remove-existing-container --workspace-folder <repo>
# then inside:
cat /proc/sys/net/ipv4/conf/all/route_localnet    # expect 0
runuser -u node -- dig +short api.anthropic.com   # must still ANSWER
```

### What each candidate would still need live, if chosen instead

| Candidate | Still requires a live check for |
|---|---|
| 4 (chosen) | Probe 1b (DNAT-to-local delivers), Probe 2 (`SO_ORIGINAL_DST` under DNAT), Probe 3 (bridge/host unreachability of a non-loopback bind), Probe 5 (address recomputation across restart) |
| 6 | All of the above, **plus** proof that a wildcard bind is genuinely closed by the DROP policy from every present interface — Probe 3 becomes load-bearing rather than confirmatory |
| 7 | All of candidate 4's, **plus** that `169.254.1.1/32` on eth0 is treated as `RTN_LOCAL` and that the reply is un-NAT'd (`ip route get 169.254.1.1` must say `local … dev lo`; `dig` must see the reply from the original nameserver, not from `169.254.1.1`) |
| 5 | All of candidate 4's, **plus** `ip link add cc0 type dummy` succeeding in Docker Desktop's kernel, and the dummy address surviving a container restart |
| 2 / 3 | `cat /proc/sys/net/ipv4/conf/eth0/route_localnet` after a recreate, plus a `node`-run `dig` through the existing REDIRECT |

**None of the above is reachable from `test/init-firewall-rules.bats`.** The bats suite runs the script with PATH stubs and asserts the *command sequence*; it can prove that a `DNAT --to-destination <addr>:53` rule is issued with the right address and in the right order, and it can prove that a malformed address aborts before the flush. It cannot execute a single packet. Everything in this section is the complement of what bats covers, and the reason this bug shipped with 68 green tests.

---

## 7. Q5 — is candidate 2 worth testing first anyway?

**Not first, but yes as a free rider on the Probe-1 rebuild.** Three reasons it should not gate the redesign:

1. **The kernel ORs, so `default` cannot add anything `all` doesn't already give.** Every consult site for this key goes through `IN_DEV_ORCONF`/`IN_DEV_NET_ORCONF`, which ORs the namespace-wide `all` value with the per-device value. `conf.default.*` is only the template a *newly created* interface copies into its own per-device value — and the OR already subsumes any per-device value. For `conf.default` to matter, there would have to be a consult site that reads the per-device value *without* the OR, and none is known for this key (contrast `rp_filter`, which uses `IN_DEV_MAXCONF` — a genuinely different combining rule, and worth a glance in the Preflight for that reason).
2. **The experiment the theory predicted has already run and failed.** Evidence item 4 is the theory's own prediction, tested, contradicted. A second variant of the same knob is a low-information draw.
3. **Even if it worked, it fails C8.** It is still a container-creation-time knob, so every future boundary change would need a recreate rather than a rebuild, and a per-interface key still cannot be set at creation for an interface that may not exist yet. Winning this bet buys a design the constraint set already rejects.

What *is* worth doing, because it costs one extra runArg on a rebuild that is happening anyway: put **both** `net.ipv4.conf.default.route_localnet=1` **and** `net.ipv4.conf.eth0.route_localnet=1` (candidate 3) on the Probe-1 container and read the answer with one `cat`:

- Container refuses to start on the `eth0` key → Docker applies sysctls before the veth is in the netns, and candidate 3 is dead by construction.
- Container starts and `conf/eth0/route_localnet` reads `1` → the per-device key *is* settable, which is a genuinely new fact worth recording even though C8 still rejects it.
- It reads `1` and `runuser -u node -- dig` still fails → the `route_localnet` theory is dead in full, mechanism M2 is off the table, and the M1 hypothesis is the only one standing. That is the single most useful thing this rebuild can produce, and it is one `cat` and one `dig` away.

Record whichever outcome occurs in the diagnosis doc's hypothesis log with the `tested:` / `learned:` fields, whether or not it changes the decision.

---

## 8. What stays open

- **The kernel mechanism is RESOLVED (2026-09-09, post-implementation), and it is neither M1 nor M2 — call it M3.** `__ip_local_out` enters the hook point as `nf_hook(..., NF_INET_LOCAL_OUT, ..., skb, NULL, skb_dst(skb)->dev, dst_output)`: the out-device is captured once, before any chain runs. nat's `ip_route_me_harder()` updates `skb_dst` but not the `nf_hook_state` that filter `OUTPUT` is handed, so filter still matches against `out = eth0` — the *original* destination's device. `-o lo -j ACCEPT` therefore never matched the steered packets and they fell to the terminal REJECT. Measured by diffing `iptables-save -c` across one 86-byte `node` DNS query: DNAT +1/+86, guard RETURN +1/+86, REJECT +1/+86, `-o lo` +1/+114 (the ICMP the REJECT generated, not the query). M1 is refuted — the re-route succeeds fine; M2 was already refuted by #43. The decision's mechanism-independence argument still holds and in fact paid off: candidate 4 was correct under M3 too, and needed only an additional filter rule rather than a different design. **This belongs in `docs/thoughts/`** — the next person to reach for `REDIRECT`, or to write `-o lo` next to a nat rewrite, will need it.
- **Probe 1 was necessary but not sufficient, and that is a defect in the probe, not in the candidate.** It ran with `iptables -F` and `-P OUTPUT ACCEPT`, which is exactly what let M3 through: it validated the nat layer against a cleared filter table, including clearing the guard chain the same change was restructuring. Any future pre-implementation probe of a steering change must run against the **assembled** ruleset. Probes 2–6 below inherit the same fix.
- **Root remains unfiltered.** Unchanged by this decision and worth restating: root is exempt from both chains by design (C3), so the SNI check and the filtering resolver apply to the agent, not to root. That is the boundary that matters *given* that `node` reaches root only through the root-owned firewall script.
- **Candidate 11 (gateway netns) is the real long-term answer** and this decision does not advance toward it. It removes `NET_ADMIN` from the agent entirely and puts the boundary outside the blast radius of a compromised session. Worth a spike when decision 016's per-project network model is next revisited.
- **The verification asymmetry that let this ship.** `init-firewall.sh` *does* run node-scoped probes (lines 1152–1185), and on a fresh container they correctly abort the boot — the diagnosis doc records exactly that. What they cannot do is say *why*: `node cannot reach https://api.anthropic.com through the SNI proxy` points at the proxy, which is three layers downstream of the actual fault. A probe that fails informatively (e.g. a `node`-run `dig` against the steered destination immediately after installing the nat rules, before the daemons are even involved) would have cut the 2026-09-09 diagnosis from five hypotheses to one. Worth adding regardless of which candidate is implemented; not in scope here.
- **Revisit triggers.** *How to read: each entry is a concrete, observable condition that should prompt re-evaluating this decision.* if Probe 1b fails → decision reverses to candidate 10 (see §4 rule). if Docker begins renumbering running containers, or a compose network with multiple container addresses is adopted → the single-`CONTAINER_IP` assumption breaks. if a profile adds a redirected port beyond 53/443 → confirm the one-variable/N-rules generalisation still holds. if the agent container ever loses `CAP_NET_ADMIN` → the whole in-container-iptables model goes and candidate 11 becomes the design. if `test/init-firewall-rules.bats` count drops below the current 68 minus the 2 deleted route_localnet tests → coverage regressed silently.
