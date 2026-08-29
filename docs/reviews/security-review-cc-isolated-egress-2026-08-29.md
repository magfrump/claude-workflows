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
   IPv4 resolver parses, the fallback is scoped to Docker's embedded resolver
   `127.0.0.11` — **not** a blanket `0.0.0.0/0` accept — so the degraded path
   does not re-grant the exact channel this fix removes, while still resolving in
   the standard Docker case (session start can never brick). This removes the
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
    with a `127.0.0.11`-scoped (not `0.0.0.0/0`) fail-open fallback and non-fatal
    per-resolver adds so a malformed entry cannot abort the script in the
    post-flush/pre-DROP wide-open window.

Both edits are inside the firewall-application path (after the `--print-domains`
early exit), so `compose_domains` and the 52 `test/cc-isolated-functions.bats`
tests are unaffected. Because `init-firewall.sh` is an enforcement file, the next
`cc-isolated` launch will refuse until the human re-reviews and runs
`cc-isolated --bless` — the intended human-in-the-loop gate for a boundary change.

## Recommended follow-ups (owner decision)

- **SNI-filtering egress proxy** — the one change that closes findings 5 and 6
  and shrinks 3. The largest lever; also the most work.
- **Host-side key broker** for `OPENROUTER_API_KEY` (already noted in
  `devcontainer.json`) so the credential is never resident in the sandbox.
- **Telemetry opt-out + drop `sentry.io`/`statsig.com` from `base`** if CC runs
  cleanly without them.
