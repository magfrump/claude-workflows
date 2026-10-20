# DD: rotating address pools strand SNI-proxy names between firewall runs

- **Date:** 2026-10-20
- **Input:** belegarth-herald handoff of 2026-10-17 (item 1). It recorded four dated outages and measured a 30-minute rotation probe: `dl.google.com` answered from five /24s across 142.250.0.0/16 and 142.251.0.0/16, and only 35% of proxy connects succeeded.
- **Prior work:** `fix/egress-dnsmasq-ipset` (unmerged since 2026-10-05) and its decision 038, which exists only on that branch. Its live check (Q-117) was never run: the user declined to install a branch image on the host (answers-10-12-26). Q-165/Q-169 is the verify-without-install process that came out of that.
- **Outcome:** decision 039 (`docs/decisions/039-pin-resolver-to-phase-a.md`).

## Root cause (established, not re-derived)

Phase A resolves each name once into `allowed-domains`. Later, `cc-sni-proxy.py` resolves the SNI name again on every connection, through the filtering dnsmasq, and connects to the first answer. When the upstream pool rotates, that answer is not in the set. The proxy's own connect then fails with `Errno 113`. Only the proxy's upstream address matters: the agent's tcp/443 flows are DNATed to the proxy, and the client's chosen address is never checked against the set.

## Step 1 — Diverge

Prior pruning grep: `Pruned candidates` in `docs/decisions/*.md` on main for `ipset|dnsmasq|resolv|cidr|sni`. No matches on main. Decision 038, on the unmerged branch, considered six options. It is carried as candidate 0, and its rejected options appear as [1]–[4] with their reasons carried forward.

0. **Decision 038 as built.** A second dnsmasq instance serves the proxy alone, with `ipset=` filling a `hash:ip` set that one ccproxy-only 443 rule reads. About 530 lines. The instance holds CAP_NET_ADMIN.
1. **`ipset=` in the agent-facing dnsmasq** (handoff A). [carried from 038 [1]: gives CAP_NET_ADMIN to the resolver the agent's bytes reach, which is #55's rejection.]
2. **The proxy writes its own resolution into the ipset** (handoff B). It needs CAP_NET_ADMIN in the ClientHello parser.
3. **Periodic re-run** (handoff C). [carried from 038 [6]: a timer only narrows the window, and the measured rotation is 5–10 minutes.]
4. **Exempt ccproxy from the address check on 443.** [carried from 038 [4]: it drops the address layer for every name.]
5. **Admit 142.250.0.0/15 on tcp 443, hardcoded** (handoff D-narrow). Needs a CIDR grammar in the profiles.
6. **Ingest `goog.json` at phase A** (handoff D-full). A new phase-A network read to `www.gstatic.com`, which itself needs admitting on a re-run.
7. **Bake `goog.json` into the image at build time.** A Dockerfile fetch, a root-owned file, and a CIDR ingest like GitHub's.
8. **Pin the resolver to phase A's answers** (new). For every exact name phase A resolved, dnsmasq gets one `host-record=<name>,<ip>` line per address. The proxy, and every client, then gets exactly the addresses the ipset holds. "Resolve twice and hope they match" becomes "resolve once".
9. **The proxy reads a root-written name→address file** instead of re-resolving. Same idea as [8], but in the proxy, and only for 443.
10. **The proxy retries resolution until it gets an admitted answer** (naive). dnsmasq caches for the TTL, so a retry sees the same answer.
11. **A root watchdog re-resolves every 30 s and adds new answers** (additive set). Each rotation still leaves a race window of up to 30 s.
12. **Bake each project's Google artifacts into the image's Gradle cache** (Q-052 [2]) and drop the runtime dependency.
13. **The project uses `maven.google.com` instead of `google()`** (reframe, per-project). `maven.google.com` succeeded in all 81 rounds, but that is not shown to hold, and every Android project would need the change.
14. **TLS interception** (ideal if free). The proxy terminates TLS and checks Host. The design rules it out (#41).

Health check: [5]–[7] cluster on "admit more addresses". [8], [9] and [12] violate that assumption, so the cluster is balanced. Dimensions moved: the address set, the resolver's answers, the proxy's logic, the project, and the schedule. Do-nothing ([3] is minimal), naive ([10]) and ideal-if-free ([14]) are present.

## Step 2 — Diagnose

| ID | Constraint | Kind |
|---|---|---|
| C1 | `dl.google.com` stays reachable through a rotation. success: the handoff's probe (`probe.sh OUTDIR 1800 20`) in a fresh `--profile android` container logs 0 `FAIL sni=dl.google.com` lines across ≥81 rounds | hard |
| C2 | No unprivileged daemon gains a capability or write access to a set. success: `grep CapEff /proc/$(pgrep -u dnsmasq dnsmasq)/status` and the same for ccproxy print `0000000000000000`; `rg -n ipset devcontainer-config/cc-sni-proxy.py` prints nothing | hard |
| C3 | The name still decides, and nothing new becomes reachable by the agent or the proxy. success: the boot-time negative SNI probe passes, and `ipset list allowed-domains` holds only GitHub CIDRs and phase-A answers | hard |
| C4 | Fail closed on malformed input (repo H2). success: a bats case shows a pin line is emitted only for an address that passed phase A's octet regex and a name that passed HOST_RE | hard |
| C5 | Verifiable by hermetic tests (repo H3). success: `bats test/init-firewall-rules.bats` passes with new cases for the pin lines | hard |
| C6 | No recurring human step (S10). success: no doc tells the operator to re-run the firewall as the remedy for a rotation | hard |
| C7 | Small, with no new package, privileged daemon or phase-A network read (S8, S3) | soft |
| C8 | General, covering every profile's rotating names, not only Google | soft |
| C9 | Covers `.zone` entries too | soft |

Console line: `◇ step 2 diagnose 9 constraints (6 hard · 3 soft)`

## Step 3 — Match

| # | C1 | C2 | C3 | C4 | C5 | C6 | C7 | C8 | C9 |
|---|---|---|---|---|---|---|---|---|---|
| 0 | ✓ | ⚠ second instance holds NET_ADMIN | ✓ | ✓ | ✓ | ✓ | ✗ 530 lines | ✓ | ✓ |
| 1 | ✓ | ⚠ | ✓ | ✓ | ✓ | ✓ | ~ | ✓ | ✓ |
| 2 | ✓ | ⚠ | ~ | ✓ | ✓ | ✓ | ~ | ✓ | ✓ |
| 3 | ✗ | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ | ~ | ~ |
| 4 | ✓ | ✓ | ⚠ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 5 | ~ only the /15 seen from one vantage | ✓ | ~ adds a /15 | ✓ | ✓ | ~ hand-maintained | ~ grammar change | ✗ | ✗ |
| 6 | ✓ | ✓ | ~ all of Google | ~ new read on the boot path | ✓ | ✓ | ✗ | ✗ | ✗ |
| 7 | ✓ | ✓ | ~ all of Google | ✓ | ✓ | ~ stale until rebuild | ~ Dockerfile | ✗ | ✗ |
| 8 | ✓ (pending live) | ✓ | ✓ narrows answers to admitted set | ✓ | ✓ | ✓ | ✓ ~40 lines | ✓ | ✗ |
| 9 | ✓ 443 only | ✓ | ✓ | ✓ | ✓ | ✓ | ~ proxy change | ~ | ✗ |
| 10 | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ |
| 11 | ~ race windows | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ new root daemon | ✓ | ~ |
| 12 | ~ only for baked deps | ✓ | ✓ | ✓ | ~ | ✗ rebuild per dep | ✗ | ✗ | ✗ |
| 13 | ~ unshown | ✓ | ✓ | ✓ | ✗ | ✗ per project | ✓ | ✗ | ✗ |
| 14 | ✓ | ⚠ | ✓ | ~ | ~ | ✓ | ✗ | ✓ | ✓ |

Pruned for ⚠ on a hard constraint: [0], [1], [2], [4], [14]. Pruned as mostly ✗: [3], [10], [12], [13]. Survivors: **[8] [9] [7] [5]**. [11] is out on C7 and on its race.

Console line: `◇ step 3 match 4 of 15 survived → [8] [9] [7] [5]`

## Step 4 — Tradeoff and stress test

| # | Effort | Risk | Hard met | Key downside |
|---|---|---|---|---|
| 8 ★ | ~2 h, ~40 lines + tests | low | 6/6 (C1 pending live) | A pinned address that goes dead stays dead until the next firewall run |
| 9 | ~4 h, proxy + firewall | low | 6/6 | Duplicates [8] inside an enforcement daemon and covers only 443 |
| 7 | ~4 h + Dockerfile | med | 5/6 (C3 ~) | Admits all Google ranges to the proxy, and the ranges go stale between image builds |
| 5 | ~2 h + grammar | med | 4/6 | Covers only what one vantage saw that afternoon |

Hypothesis [8]: if chosen, the handoff's 30-minute probe in a fresh android container logs 0 `FAIL sni=dl.google.com` within one run, while `dig dl.google.com` from node returns only the phase-A addresses. Counter-evidence: any `FAIL sni=<exact name>` whose address is in `/etc/dnsmasq.d/cc-allowlist.conf`'s host-records, which would mean the pinned address stopped serving.

Stress tests on [8]:

- **Invert the thesis.** Argument: pinning hides legitimate DNS changes, such as a host migrating. Answer: a migrated address fails today anyway, because the new address is not in the set. A pin turns that into the old address, which still works for anycast and CDN front ends. The remedy, a re-run, is the same. The one case where a pin is worse: phase A got [a, b], a dies, and DNS would now answer only b. The proxy connects to `infos[0]` and may pick a. That is a narrow follow-up (the proxy tries every answer), not a blocker.
- **Push to extreme.** A container that lives for weeks. Google front-end addresses serve every Google hostname (the Q-045 fronting test shows a GFE address serving www.google.com under SNI dl.google.com), so a pinned GFE address keeps serving `dl.google.com` while that address is in service. The live probe, run hours after boot, is the falsifier.
- **Failure-driven.** New failure categories:
  - (a) The pin lines are config syntax. Names pass HOST_RE and addresses pass the octet regex before emission, and both are validated in phase A already.
  - (b) AAAA queries for a pinned name still forward. Clients may get an AAAA answer, IPv6 is default-denied, and they fall back to IPv4, as today.
  - (c) Root's next phase A must not read the pins back. Root is exempt from the DNS steering and digs resolv.conf's upstream directly (FILTERING RESOLVER block, "WHO IS EXEMPT"), so each run re-pins from the upstream.
  - (d) Subdomains of a pinned name still forward. Tested: `host-record` is exact-name only, unlike `address=`, which also answered `x.dl.google.com`.
- **Boring alternative.** [8] is the boring one: two config lines per address, no new process.

Decision path: **A**, [8] dominates at about 85% confidence. Runner-up: [9], on the 443-only axis. [9] is [8] relocated into the proxy.

## Mechanism check (sandbox, dnsmasq 2.90, 2026-10-20)

An unprivileged dnsmasq on :5399 with `server=/dl.google.com/<dead upstream>` plus pin lines:

- `host-record=dl.google.com,A,B` on one line: only the last IPv4 was kept. **Use one line per address.**
- Two `host-record=dl.google.com,…` lines: the A query answered both, locally (`config dl.google.com is …`), with no forward.
- `x.dl.google.com`, AAAA and MX for the name were forwarded as before. Case-insensitive match.
- `address=/dl.google.com/…` also answered `x.dl.google.com`, so it was rejected in favour of `host-record`.

## Pre-mortem: bypass families (the plan changes an enforcement file)

1. **Config injection through a pin line.** A name or address carrying `,` / `/` / newline becomes extra dnsmasq directives. Closed by HOST_RE plus the octet regex on every emitted value, with a bats case.
2. **A pin that widens.** Could a pin make a non-allowlisted name resolve? Pins are emitted only from `ALLOWED_ENTRIES` exact names. A bats case asserts no pin for a zone entry or a GitHub zone.
3. **An agent-written pin.** The config is written by root to a root-owned path under the firewall lock, the same as the existing `server=` lines. Nothing new is agent-writable.
4. **Pin and ipset disagree.** Both come from the same `ips` variable in the same loop iteration, so they cannot drift within a run.
5. **The resolver path is reached without the pins.** The proxy's port-53 traffic is DNATed to this same dnsmasq (CC_DNS), whatever resolv.conf says. That is unchanged.
