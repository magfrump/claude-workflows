# Security review — cc-isolated egress boundary

**Date**: 2026-08-29 · **Scope**: `devcontainer-config/init-firewall.sh`,
`devcontainer-config/egress/*.txt`, `devcontainer-config/cc-isolated.sh`,
`devcontainer.json`, `Dockerfile` · **Threat model**: a *compromised session* —
the agent (or repo-controlled content it processed) is trying to exfiltrate data
or reach an attacker-controlled host. The firewall is the boundary; everything
below asks "what can a hostile insider send out, and where."

## How egress actually works (the mechanism that shapes every attack)

`init-firewall.sh` sets `OUTPUT` policy to `DROP`, then admits:

1. **DNS** — outbound UDP/TCP 53 (now scoped to configured resolvers; see patch 1).
2. **Localhost** and the **host /24 bridge network** (`HOST_NETWORK`).
3. **GitHub CIDRs** — the union of `.web + .api + .git` from `api.github.com/meta`,
   added for *every* project regardless of profile.
4. **The composed allowlist** — `base` + the project's profiles, each domain
   resolved to A records at container start and pinned into the `allowed-domains`
   ipset.
5. **ESTABLISHED,RELATED** return traffic.

**The load-bearing weakness, true of the whole system:** the allowlist matches on
**destination IP**, not SNI/Host. A domain is resolved once at start; any site
sharing that IP (CDN, cloud frontend) is implicitly admitted, and the match is
per-IP for *all ports*. This is documented as accepted risk in `android.txt` and
`llm.txt`; it is the root of several attacks below.

## Per-egress: intended work vs. adversarial use

| Egress | Intended work | Adversarial use |
|---|---|---|
| **DNS (53)** | Resolve allowlisted domains. | Direct exfil: point a UDP socket at `attacker_ip:53`, stream data in query names. *(Patched — scoped to resolvers; recursive-forward residual, see below.)* |
| **Outbound SSH (22)** | Historically: `git+ssh`. But GitHub is already reachable via its CIDRs. | Blanket `--dport 22` to `0.0.0.0/0` = an unconditional TCP tunnel: run C2 on port 22, `ssh -D`/`-L` any traffic through it, bypassing the entire allowlist. *(Patched — removed; GitHub SSH still works via CIDR.)* |
| **Host /24 bridge** | Docker-internal DNS, sidecars. | Reach any service another container/host exposes on that subnet. Narrow; low value in the single-container launcher. |
| **GitHub CIDRs (always on)** | `git`/`gh` push, clone, releases, API. | GitHub is **writable**: push stolen data to an attacker repo/gist, or POST via `api.github.com` with the container's `gh` token. Available to *every* project, base profile or not. **Intrinsic** — you cannot have git without a writable GitHub. |
| **base: `api.anthropic.com`** | The model API. CC cannot run without it. | General-purpose channel: anything the agent puts in a prompt/response crosses the boundary. **Irreducible.** |
| **base: `claude.ai`, `console.anthropic.com`** | OAuth login. | Same shared-IP (Cloudflare) surface; both resolve to CF IPs, admitting the CF-fronted range by dst. |
| **base: `sentry.io`, `statsig.com`** | CC error/telemetry ingestion. | Writable ingestion endpoints, always open to every project: POST stolen data as a fake Sentry event / Statsig log. Medium bandwidth, low scrutiny. |
| **base: `registry.npmjs.org`** | CC self-update (npm package). | Ingress of attacker-chosen code if a malicious package name resolves; exfil is limited (registry is mostly read). |
| **python: `pypi.org`, `files.pythonhosted.org`** | `uv` installs. | Behind Fastly — shared IPs front thousands of sites; dst-match admits them. Ingress of a typosquatted/backdoored wheel. |
| **rust: `crates.io`, `*.crates.io`** | `cargo` registry. | Behind a CDN; same dst-match overreach; malicious-crate ingress. |
| **dotnet: `api.nuget.org`** | `dotnet restore`. | CDN-fronted; malicious-package ingress. |
| **android: `dl.google.com`, `maven.google.com`, Maven Central, Gradle** | Gradle dependency resolution. | `dl.google.com`/`maven.google.com` resolve to **Google Front End** IPs — SNI-routed, so dst-match admits the *whole* GFE surface, including **writable** `storage.googleapis.com`. Exfil to an attacker's GCS bucket. Documented in `android.txt`. |
| **vscode: marketplace + blob + update** | IDE-attach path. | Azure blob storage frontends; shared-IP overreach. |
| **llm: `openrouter.ai`** | Third-party model calls. | **By design** a general-purpose outbound channel — anything in a prompt leaves. CDN IPs rotate (documented). |
| **llm: `host.docker.internal`** | Local Ollama on the host (`:11434`). | dst-match opens **every** host port to the container, not just the model server. Any host-facing service becomes reachable. Documented in `llm.txt` (added 2026-08-29). |

## Pairs of accesses (combinations that amplify)

- **DNS + any profile** — DNS is profile-independent, so it amplifies every
  compromise: even a `base`-only project has an exfil channel. (This is why DNS
  is worth hardening even though the residual persists.)
- **SSH + workspace bind mount** — the repo is mounted read-write; a blanket SSH
  tunnel would let a session `scp` the whole tree (and anything host-readable
  through it) to an arbitrary box. *(Closed with the SSH patch.)*
- **GitHub-always + credentials in `~/.claude`/`gh`** — the per-project
  `~/.claude` volume holds session history and any tokens; GitHub is always
  writable; push-exfil needs no extra profile.
- **llm + `OPENROUTER_API_KEY`** — the key lives in the container env; the `llm`
  channel it unlocks is exactly the channel that can carry the key back out
  (documented in `devcontainer.json`). The key exfiltrates over its own door.
- **llm + `host.docker.internal`** — a general model channel *and* all-host-ports
  reach: the broadest combination the system can grant.
- **android/`dl.google.com` (GFE) + writable `storage.googleapis.com`** — one
  admitted GFE IP yields a writable cloud bucket (documented).
- **python/PyPI (Fastly) + any Fastly-fronted attacker site** — shared-IP
  overreach turns a package host into a general channel for co-located sites.

## Ranked findings

### High value / high likelihood — PATCHED

1. **Blanket outbound SSH (`--dport 22` → `0.0.0.0/0`).** A full tunnel out of the
   sandbox that silently defeats the allowlist. Nothing legitimate depended on it
   that the GitHub CIDRs don't already cover. **Fix (shipped):** removed the
   blanket accept from `init-firewall.sh`; SSH to allowlisted hosts (all of
   GitHub) still works via the `allowed-domains` ipset (dst-match, any port).
   Non-GitHub SSH now requires adding the host to a profile — same rule as every
   other destination.

2. **Unrestricted DNS to any resolver.** Direct UDP-to-attacker-NS exfil.
   **Fix (shipped, defense-in-depth):** scoped outbound 53 to the resolvers in
   `/etc/resolv.conf` (validated to real 0–255-octet IPv4 addresses). When no
   IPv4 resolver parses, **no IPv4 DNS accept is installed at all** — the degraded
   path fails closed rather than re-granting the `0.0.0.0/0` channel this fix
   removes. That is safe because the cases that reach it are covered elsewhere:
   IPv6 DNS is unfiltered (the script installs no ip6tables rules), a loopback
   resolver is admitted by `-o lo`, and a host-/24 resolver by the HOST_NETWORK
   accept; what remains is a malformed resolv.conf, which should fail loudly.
   **Note the hardening comes from deleting the old blanket accept, not from the
   scoped rules** — where the resolver is loopback or in the host /24 those rules
   are redundant with accepts that already exist. This removes the
   *direct* "socket at `attacker_ip:53`" path. It does **not** close
   recursive-forward DNS tunnelling (see below). Note the new dependency: DNS
   scoping is only as trustworthy as `/etc/resolv.conf`, which must stay
   root-owned and not agent-writable (a `node`-writable resolv.conf would let a
   session inject `nameserver <attacker_ip>` and re-run the firewall via its
   NOPASSWD sudo to get a *scoped* accept to it).

### High value / low patchability — SURFACED (need architecture, not a config edit)

3. **GitHub is always writable, for every project.** Git requires GitHub; GitHub
   hosts arbitrary writable repos/gists and an API that takes the container's
   token. There is no IP-layer scoping to "only my repos." Closing this needs an
   authenticating egress proxy that restricts `api.github.com`/push targets — out
   of scope for a firewall. **This is the single widest always-on exfil surface.**

4. **`api.anthropic.com` is an irreducible general-purpose channel.** Anything the
   agent can phrase leaves the boundary. Unpatchable by definition — it is the
   product. Mitigation lives at the model/policy layer, not the network.

5. **IP-only (not SNI/Host) matching → CDN/GFE overreach.** The `android` GFE case
   (writable `storage.googleapis.com`), PyPI/crates/nuget behind CDNs, and the
   Anthropic/Cloudflare and Azure-blob frontends all admit far more than the named
   host. **Only a real fix via an SNI-filtering egress proxy** that terminates and
   inspects TLS SNI per connection; a domain edit cannot help. Already flagged as
   accepted risk in `android.txt`/`llm.txt`; recorded here as the top *unpatchable*
   item because it recurs across five profiles.

6. **Recursive-forward DNS tunnelling.** Even with resolver-scoping (patch 2), a
   session can resolve `<base32-data>.attacker.com` through the legitimate
   resolver, which forwards it to the attacker's authoritative NS. Closing this
   needs a **filtering resolver** that only answers allowlisted names — a DNS
   proxy, not an IP rule. Bandwidth is lower than the direct path (one recursion
   hop, resolver caching/rate-limiting) but it is not zero.

7. **`sentry.io` / `statsig.com` as always-open writable ingestion.** Every
   project can POST to these. Lower value than GitHub (rate-limited, structured
   payloads) but genuinely always-on. Mitigation: set CC's telemetry/error-report
   opt-outs and drop these two from `base` — a behavior/UX call for the owner, not
   a clear win, so surfaced rather than shipped.

## What was changed

- `devcontainer-config/init-firewall.sh`:
  - Removed the blanket outbound-SSH accept (and its inbound-response companion).
  - Scoped outbound DNS to `/etc/resolv.conf` resolvers (0–255-octet validated),
    failing **closed** (no IPv4 DNS accept) when none parse, with non-fatal
    per-resolver adds. Parsing is factored into `compose_dns_resolvers` and exposed
    through a `--print-resolvers <file>` inspection hook (an argument, never an
    env var — see the comment there) so the logic is directly testable.
  - **Restructured the run into two phases.** Phase A performs every network read
    (the GitHub `/meta` fetch and one `dig` per allowlisted domain) *before* any
    rule is touched, while the previous ruleset is still installed and permitting
    exactly those destinations; phase B then rebuilds with no egress required. This
    collapses the old flush→DROP window — during which a fresh container had empty
    chains and a default-ACCEPT policy for as long as a `curl` and N `dig`s took —
    to a few local calls, so the `DROP` policies now go up immediately after the
    flush. A transient GitHub/DNS failure now exits *before* the flush, leaving the
    working firewall untouched instead of half-building one.
  - Added an `EXIT` trap keyed on a **completion sentinel** (not `$?`, which is 0
    inside the trap when the shell is signalled) plus `INT TERM HUP` traps, so every
    incomplete run — signals included — ends at `DROP` rather than wide open.
  - `|| true` on the `curl`/`dig` command substitutions so their own error paths are
    reachable rather than dead code, and bounded timeouts so a blocked SYN fails
    fast instead of hitting the kernel's ~127s retry ceiling.
  - `cc-isolated.sh` now checks the re-assert's exit status and prints the recovery
    command; `probe_boundary` passes against a fully-DROP container, so the probe
    alone cannot distinguish "locked down" from "bricked closed".
  - New `test/init-firewall-rules.bats` (13 tests) runs the real script under PATH
    stubs for `iptables`/`ipset`/`dig`/`curl`, asserting on the command sequence —
    the region had zero coverage before, which is how three defects reached review.

`compose_domains` and the existing 52 `test/cc-isolated-functions.bats` tests are
unaffected (65/65 pass with the new suite). Because `init-firewall.sh` **and**
`cc-isolated.sh` are enforcement files, the next `cc-isolated` launch will refuse
until the human re-reviews and runs `cc-isolated --bless` — the intended
human-in-the-loop gate for a boundary change.

### Residual risks accepted in this change

- **A fresh container can still be bricked closed.** If the very first run dies on a
  transient GitHub/DNS failure, the trap leaves `DROP` with no accept rules, and the
  script's own phase-A reads are then blocked, so it cannot rebuild. This is
  fail-*closed* and therefore the safe direction, but it is terminal in place:
  recovery is `devcontainer up --remove-existing-container`, which the launcher now
  prints. Re-runs on an already-configured container are unaffected (phase A runs
  under the live ruleset).
- **IPv6 is entirely unfiltered.** The script installs no `ip6tables` rules at all,
  so the *whole* allowlist — not just DNS — is unenforced over IPv6. Any IPv6-capable
  destination is reachable regardless of profile. This is pre-existing and unchanged
  by this work, but it is arguably the single largest hole in the boundary and was
  independently flagged by all three fact-check replicates.
- **`/etc/resolv.conf` integrity is assumed, not asserted.** DNS scoping is only as
  trustworthy as that file; Docker writes it root-owned, but nothing in this repo
  enforces or checks that.
- **The inbound `-A INPUT -p udp --sport 53 -j ACCEPT` is broader than needed** and
  redundant with the `ESTABLISHED,RELATED` accept; it bypasses the INPUT DROP policy
  for any source port 53. Low severity, left alone as out of scope for this change.

## Recommended follow-ups (owner decision)

- **SNI-filtering egress proxy** — the one change that closes findings 5 and 6
  and shrinks 3. The largest lever; also the most work.
- **Host-side key broker** for `OPENROUTER_API_KEY` (already noted in
  `devcontainer.json`) so the credential is never resident in the sandbox.
- **Telemetry opt-out + drop `sentry.io`/`statsig.com` from `base`** if CC runs
  cleanly without them.
