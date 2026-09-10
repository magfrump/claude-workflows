# Diagnosis — cc-isolated session cannot log in (`getaddrinfo` on platform.claude.com)

Status: **resolved and verified live** · Started and closed 2026-09-09 · Outcome: decision log #44 (H5 mechanism refuted, H6 confirmed)
(#43 was a refuted attempt; see the DD at `dd-cc-isolated-loopback-redirect.md` for the design pass)

## Reproduction

1. `cc-isolated <repo>` (host, normal WSL terminal)
2. Inside the session: `claude` → `/login`
3. Observe: `OAuth error: getaddrinfo ETIMEOUT platform.claude.com` / `Press Enter to retry.`

## Hypothesis log

- **H1**: The SNI proxy (`cc-sni-proxy.py`, decision 41) refuses or fails the connection to
  `platform.claude.com` — either `REJECT` (name not in the exact-match allowlist) or `FAIL`
  (resolved address not admitted by the resolve-at-start ipset).
  · tested: `grep -E '(FAIL|REJECT)' /run/cc-sni-proxy/proxy.log` inside the container
  · result: **refuted**
  · learned: no proxy log lines at all, and `getaddrinfo` fails before any TCP connection is
    attempted, so the proxy is downstream of the failure. Eliminates the entire tcp/443 path
    (SNI matching, ipset admission, CDN IP rotation) from the search space.

- **H2**: `compose_dnsmasq_conf` fails to emit a `server=/platform.claude.com/<upstream>` line,
  so the filtering resolver (decision 40) REFUSES the name.
  · tested: `CC_EGRESS_DIR=devcontainer-config/egress bash devcontainer-config/init-firewall.sh
    --print-dnsmasq-conf /etc/resolv.conf`
  · result: **refuted**
  · learned: the line is generated correctly from the current repo/installed `base.txt`.
    Config *generation* is not the bug; if the zone is missing in the container it is because
    the container holds different inputs, not because the generator is wrong.

- **H3**: The running container predates the 2026-09-03 egress hardening, so it holds a stale
  baked `/usr/local/share/cc-egress/base.txt` that lacks `platform.claude.com`.
  · tested: not yet — needs container-side observation
  · result: **open (leading)**
  · supporting evidence gathered host-side:
    - `platform.claude.com` was added to `base.txt` in `b04090c` (2026-09-03); no commit
      removes it, so any image built before that date lacks the host entirely.
    - `~/.config/claude-devcontainer/` matches the repo exactly, but was installed
      **2026-09-09 12:15** — after the hardening, and after the container was last built.
    - No project has been re-registered since **2026-08-22** (newest file in
      `~/.config/claude-devcontainer/projects/`), and registration is what forces an image
      rebuild; `devcontainer up` otherwise reuses the existing container by `--id-label`.
    - The empty proxy log corroborates this independently: `init-firewall.sh:1132` *requires*
      a `REJECT sni=not-allowlisted.invalid` line to exist or the launch aborts. A session
      that started with an empty/absent log is a session whose firewall script never ran the
      SNI block — i.e. a pre-hardening image.

- **H3 outcome**: **refuted as the root cause.** The image was already current; re-registering and
  rebuilding produced a *fresh* container that fails **earlier and harder** — `init-firewall.sh`
  now aborts at its own launch probe (`init-firewall.sh:1105`) with
  `node cannot reach https://api.anthropic.com through the SNI proxy`, forces DROP, and
  `postStartCommand` exits 1 so no session starts at all.
  · learned: staleness was not it, and the failure is not specific to `platform.claude.com`.
    It reproduces on `api.anthropic.com`, which the script itself treats as critical. The bug is
    in the SNI-proxy path, and it is **non-deterministic** — the earlier container passed the same
    probe at boot and only failed later, at login.

- **H4**: The address the SNI proxy resolves at connect time is not the address phase A put in the
  ipset, so the proxy's own egress is REJECTed. Mechanism: phase A's `dig` runs **as root**, which
  `CC_DNS` exempts (`init-firewall.sh:836`), so it queries the upstream resolver directly; the
  proxy resolves **as `ccproxy`**, which is redirected through dnsmasq. Both reach the same
  upstream, but Cloudflare-fronted names return a rotating subset of a large pool per query, so the
  two answers routinely disagree. The proxy then connects to an address the `hash:net,port` set
  never admitted (`cc-sni-proxy.py:191-197` → logged as `FAIL … address not admitted by the ipset`).
  · predicts: whether any given boot succeeds is luck — exactly the observed non-determinism.
  · tested: pending — needs `/run/cc-sni-proxy/proxy.log` from the failed container
  · result: **open (leading)**

- **H4 outcome**: **refuted.** In the failed container, `dig +short api.anthropic.com @127.0.0.1`
  (dnsmasq) and `dig +short api.anthropic.com` (upstream direct) both return `160.79.104.10`.
  No rotation divergence. Eliminates resolve-at-start staleness as the cause of *this* failure.
  · learned: the decisive observation from the same run is that `/run/cc-sni-proxy/proxy.log`
    contains **only** its `listening on 127.0.0.1:3443` line — no ALLOW/REJECT/FAIL. The
    connection never reached the proxy at all, so every hypothesis about proxy *decisions*
    (allowlist matching, upstream connect, ipset admission) is off the table. The failure is in
    the REDIRECT itself.

- **H5**: `net.ipv4.conf.*.route_localnet` is 0, so both nat REDIRECTs are rewritten and then
  dropped in routing as martians. Linux refuses to route a packet to 127.0.0.0/8 whose source /
  route is non-loopback unless `route_localnet=1`; this is the standard prerequisite for
  `REDIRECT`-to-loopback on locally generated traffic. Nothing in `devcontainer.json` or the
  `Dockerfile` sets it (grep: only `--cap-add=NET_ADMIN`), and `init-firewall.sh` never touches
  sysctls.
  · explains every observation at once:
    - node → 127.0.0.1:3443 dropped ⇒ proxy log holds only the listening line ⇒ probe at
      `init-firewall.sh:1105` fails.
    - node → 127.0.0.1:53 dropped ⇒ `getaddrinfo ETIMEDOUT platform.claude.com`, the original
      reported symptom. The login failure and the probe failure are **one bug**, not two.
    - root is exempt from both redirects (`CC_DNS`/`CC_SNI` RETURN on uid 0), goes direct, and
      its probes (`example.com` blocked, `api.github.com` reachable) pass.
    - `dig @127.0.0.1` as root works because src and dst are both loopback — no redirect, no
      martian check.
    - dnsmasq's own upstream queries are exempt, so the resolver looks healthy in isolation.
  · **provenance**: decisions 40 and 41 both shipped with this exact check explicitly deferred —
    #40 "needs a live-container check on Docker Desktop (xt_owner/REDIRECT availability) before
    bless"; #41 "needs one live-container check of REDIRECT on locally generated packets".
    This is that deferred verification, failing.
  · tested: pending — `sysctl net.ipv4.conf.all.route_localnet` plus `iptables -t nat -L CC_SNI -n -v`
    packet counters (nonzero REDIRECT count + empty proxy log = confirmed)
  · result: **open (leading, high confidence)**

- **H5 outcome**: **mechanism REFUTED; observation stands** (2026-09-09). The observation — a
  redirect-to-loopback that matches packets and then loses them — is solid and reproduced. The
  *explanation* (`route_localnet=0`) is not: `--sysctl net.ipv4.conf.all.route_localnet=1` was
  applied and verified live, and the failure is unchanged. `IN_DEV_ORCONF` ORs the `all` value
  with the per-device value, so `all=1` already covered every consult site and `eth0=0` is
  cosmetic. That makes the failed fix the disproof of the theory. See
  `dd-cc-isolated-loopback-redirect.md` for the two mechanisms still live (M1 output-path
  re-route failure inside the nat hook; M2 input-path martian, which item 4 argues against).
  Original evidence, all from the failed container:
  - `net.ipv4.conf.all.route_localnet = 0`.
  - `iptables -t nat -L CC_DNS -n -v` shows **4 udp packets matching the REDIRECT** — the rule
    fires and the packets are rewritten.
  - As `node`, `dig api.anthropic.com @127.0.0.1` (destination already loopback, so the
    rewrite is a no-op and no martian check applies) **answers `160.79.104.10`**.
  - As `node`, the same query via `resolv.conf` (`192.168.65.7`, off-box, so the source stays
    the container's `172.17.0.x`) returns **`host unreachable`** — the kernel's martian
    signature — and dnsmasq never sees it.
  - The only variable between the answering query and the failing one is whether the packet
    traverses the REDIRECT.
  - `sysctl -w` inside the container returns `permission denied`: Docker mounts `/proc/sys`
    read-only, so this cannot be fixed from `init-firewall.sh` and must be set at container
    creation.

- **H6**: The DNAT lands correctly but the *filter* chain then rejects the rewritten packet, because
  `-o lo -j ACCEPT` does not match traffic that nat rerouted to a local address. `__ip_local_out`
  passes `skb_dst(skb)->dev` into `nf_hook()` when it enters the LOCAL_OUT hook point, so the
  out-device is fixed before any chain runs; nat's `ip_route_me_harder()` updates `skb_dst` but not
  the already-built `nf_hook_state` that filter `OUTPUT` receives. Filter therefore still sees
  `out = eth0`.
  · tested: diffed `iptables-save -c` across exactly one 86-byte `node` DNS query in the failing
    container
  · result: **confirmed**
  · learned: the deltas were `CC_DNS` DNAT +1/+86, `CC_DNS_GUARD` `-d $CONTAINER_IP` RETURN +1/+86,
    terminal `REJECT` +1/+86, and `-o lo` +1/**+114**. The 114 bytes are not the query — they are the
    ICMP admin-prohibited the REJECT generated (20 IP + 8 ICMP + the 86-byte original), which is also
    what `dig` reported as `host unreachable` *from 192.168.65.7*, since conntrack reverses the
    address in the ICMP payload. Two controls bracket it: as `node`, `dig @172.17.0.2` and
    `dig @127.0.0.1` both answered `160.79.104.10`, so dnsmasq's bind, the C4 INPUT drops and the
    `-i lo` accept were all fine; only the steered path died.
  · fix: accept on the destination, which survives the rewrite — three
    `OUTPUT -d "$CONTAINER_IP" --dport {53/udp,53/tcp,$SNI_PORT/tcp} -j ACCEPT` rules, scoped to the
    steering endpoints rather than a blanket `-d "$CONTAINER_IP"` so the accept does not also expose
    anything else bound on that address.
  · **verified live 2026-09-09**: with the destination-scoped accepts in place the container
    comes up, `init-firewall.sh` completes, and a session reaches the Anthropic API. The
    original reported symptom (`getaddrinfo` at `/login`) is gone.
  · **why Probe 1 missed it**: Probe 1 ran with `iptables -F` and `-P OUTPUT ACCEPT`. It validated
    the nat layer and, by construction, nothing downstream of it — including the guard chain the same
    change was restructuring. A pre-implementation probe has to run against the assembled ruleset.

## Resolution — decision log #44

Both nat chains DNAT to the container's own address instead of REDIRECTing to `127.0.0.1`.
`REDIRECT` on `LOCAL_OUT` hardcodes the loopback destination and the kernel then discards the
rewritten packets before any socket sees them; an ordinary local unicast destination is delivered
normally. Confirmed live *before* implementation — a DNAT to the container address answered where
the REDIRECT did not — which was the explicit gate on whether to write the code. That probe was
necessary but not sufficient: it cleared the filter table, so the second half of the outage (H6, the
`-o lo` predicate) survived it and took a further round to find.

Design pass (10 candidates, constraint matrix, bless gate): `dd-cc-isolated-loopback-redirect.md`.

**#43 below is retained as the record of a refuted attempt.** `route_localnet=1` was applied,
verified live, and changed nothing; the phase-A precondition it added asserted a prerequisite that
is not required and has been removed. The refutation earned its place: it is what moved the
suspected mechanism off the input path and established that avoiding a loopback destination is
correct regardless of which mechanism is real.

Decision log #43. `devcontainer.json` runArgs gain
`"--sysctl", "net.ipv4.conf.all.route_localnet=1"`; `init-firewall.sh` asserts the value in
phase A and aborts with a message naming the runArg; a martian guard
(`INPUT ! -i lo -d 127.0.0.0/8 -j DROP`) is installed ahead of the ESTABLISHED accept and added
to the end-of-run rule assertions. 4 new bats tests (68 in `test/init-firewall-rules.bats`);
sibling suite and shellcheck clean.

**To apply**: `install.sh`, then `cc-isolated --bless`, then **recreate** the container —
`--sysctl` is container-creation-time, so a rebuild alone will not pick it up:
`devcontainer up --remove-existing-container --workspace-folder <repo>`.

## Superseded tension

H3 explained the reachability failure but not cleanly the *error class*: a missing ipset entry
should surface as a connect failure, not `getaddrinfo`. **H5 resolves this.** The redirect that
was black-holing was the DNS one, so `node` had no working resolver at all — `getaddrinfo` is
exactly the right error class, and it had nothing to do with `platform.claude.com` specifically.
That was simply the first name the OAuth flow tried to resolve. The login failure and the
launch-probe failure were always one bug.

## Retrospective note

The tension above was the strongest available signal and it was set aside as "does not change the
next action". It did: an error class that does not fit the hypothesis is evidence against the
hypothesis, and taking it seriously would have pointed at the resolver path two hypotheses
earlier. Worth carrying into `guides/debugging-examples.md` if a third instance shows up.
