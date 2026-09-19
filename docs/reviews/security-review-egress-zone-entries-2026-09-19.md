# Security Review — `.zone` egress entries and the Artifact frame zone (fix/artifact-frame-zone)

Commit: 7c970bfe1660681c71ea51853eb894416fb31131
**User goal:** Adversarially review commit 7c970bf (the `.zone[:ports]` profile grammar and `.frame.claudeusercontent.com` in `base`) for grammar bypasses, cross-layer inconsistency, what the zone admits in practice, the canary-resolution approach, and the accuracy of the security claims in comments and docs.
**Scope:** `git diff main..fix/artifact-frame-zone`, which touches `devcontainer-config/init-firewall.sh`, `devcontainer-config/egress/base.txt`, `test/init-firewall-rules.bats`, `docs/decisions/log.md` (row 55), `guides/cc-isolated-usage.md` and `guides/devcontainer-setup.md`. I also read the unchanged `devcontainer-config/cc-sni-proxy.py` and the resolver, ipset and SNI blocks of `init-firewall.sh`.
**Date:** 2026-09-19
**Threat model:** A prompt-injected agent running as uid `node` tries to exfiltrate data or reach unapproved hosts. It has NOPASSWD sudo for `init-firewall.sh` with env_reset. The profiles are root-owned.

> ⚠️ **No code fact-check report provided.** The security claims in comments and documentation were checked only by reading the code and by the local experiments below. They have not been independently verified.

No escalation patterns matched.

## Trust Boundary Map

```
B1: [egress/*.txt profile lines]        → parse_entry (HOST_RE | ZONE_RE, port grammar) → [ALLOWED_ENTRIES: ipset members, SNI allowlist, dig args]
B2: [egress/*.txt profile lines (raw)]  → compose_dnsmasq_conf (strip :ports, strip one '.', HOST_RE) → [dnsmasq server=/zone/ directives]
B3: [upstream DNS answers for apex + cc-isolated-canary.<zone>] (new) → IPv4 regex → [allowed-domains ipset on the entry's ports]
B4: [node's TLS ClientHello SNI]        → cc-sni-proxy Allowlist.allows (exact | zone suffix) → [proxy resolves SNI via dnsmasq, connects, ipset-checked]
B5: [bytes on the wire to <any>.frame.claudeusercontent.com] (new) → nothing (TLS spliced) → [Anthropic-operated artifact frame origin; content authored by any artifact publisher]
```

| Source | Mutability | Trust (per sink) |
|---|---|---|
| S1: profile lines in `egress/*.txt` | deploy-time: root-owned, blessed, needs a human rebuild | Trusted as policy. Still grammar-checked before shell or config sinks (dnsmasq directives, dig argv, ipset argv) as a guard against author error |
| S2: DNS answers for the zone apex and the canary name | request-time (at firewall run) | UNTRUSTED for the ipset sink: the owner of the name picks the answer |
| S3: SNI from node's ClientHello | request-time | UNTRUSTED for all sinks |
| S4: content served under `<uuid>.frame.claudeusercontent.com` | runtime-mutable by any artifact publisher | UNTRUSTED for all sinks: ingress to the agent's context, and a possible write sink (unverified) |
| S5: the `cc-isolated-canary` label | code-constant, public in this repo | Trusted as a string. It is predictable, which matters to S2 |

What enters from outside: profile lines, which are root-owned and trusted as policy; DNS answers during phase A; node's SNI; and, new with this commit, content from artifacts published by anyone. The diff assumes three things. First, that every name under a zone resolves into the same address pool as the canary. Second, that the parties who can obtain names under a zone cannot choose their DNS answers. Third, that the frame origin is a read surface only. The shipped zone satisfies the second assumption, because artifact UUIDs are assigned by the server. The grammar does not enforce any of the three.

## Findings

#### 1. The predictable canary label lets a zone's name holders choose the ipset contents, and a zone entry on a port other than 443 has no name check at all

**Severity:** Low (latent: no shipped profile reaches it)
**Location:** `devcontainer-config/init-firewall.sh:506-513` (canary), `:143` and `:153` (ZONE_RE accepts any ports), `test/init-firewall-rules.bats` (`.objects2.cdn.example:8443` is pinned as valid)
**Boundary:** B3, B1
**Move:** 11 (bypass enumeration), 5 (invert the model)
**Confidence:** High for the mechanism (traced); Low for its relevance to the shipped zone

Phase A fills the ipset from `dig A cc-isolated-canary.<zone>` plus the apex. The label is a fixed string published in this repo. Suppose a zone's names can be registered or pointed by third parties: a per-tenant hosting suffix, a CDN customer zone, or any zone a future profile adds. Whoever claims `cc-isolated-canary.<zone>` then chooses which address lands in `allowed-domains` on that entry's ports. There are two outcomes:

- **443:** the same party also controls another name under the zone, so the SNI check passes. The address check is then satisfied by the address they planted through the canary. The ipset's defence-in-depth role, which is the reason `.zone` is resolved at all, is void for that zone.
- **Any port other than 443, for example `.zone:8443`:** these ports are not steered through the proxy, so the entry means "whatever the canary and apex resolve to, open on 8443 to every uid." There is no name check at any layer. This is a direct, non-TLS egress to an address the name holder chose. The guide's claim that a zone entry "admits the zone and every name under it at all three layers" (`guides/cc-isolated-usage.md`, egress section) does not hold on these ports. There, a zone is just two unverified DNS answers.

Why it is not reachable today: artifact frame names are assigned by Anthropic's server. A UUID cannot be chosen, so no party can plant the canary answer for the shipped zone.

**Recommendation:** Restrict `ZONE_RE` entries to port 443 exactly. Reject `.zone:<anything but 443>` in `parse_entry`, because on other ports there is no layer that reads the name. Randomize the canary label on each run (for example `cc-isolated-canary-$(od -An -N6 -tx1 /dev/urandom | tr -d ' ')`) so it cannot be registered in advance. Also state in the `base.txt` grammar comment that a zone is acceptable only when its labels are assigned by the operator, not claimable by users.

#### 2. "Three labels = not a registrable domain" is false, and the rule admits whole multi-tenant namespaces

**Severity:** Low
**Location:** `devcontainer-config/init-firewall.sh:140-143`, `devcontainer-config/egress/base.txt:30-33`, `docs/decisions/log.md` row 55 ("Three labels minimum stops a zone from covering a whole registrable domain")
**Boundary:** B1, B2
**Move:** 11
**Confidence:** High (executed)

I ran these entries through `--print-entries` and `--print-dnsmasq-conf` with `CC_EGRESS_DIR`. All three are accepted, and each produces a zone at all three layers:

- `.example.co.uk` is a whole registrable domain under a public suffix.
- `.s3.amazonaws.com` covers every S3 bucket, which is attacker-writable.
- `.blob.core.windows.net` covers every Azure storage account.

The comment says "the point of a zone entry is one delegated sub-tree, never a site." The grammar cannot tell one from the other. Label counting is not a substitute for the Public Suffix List. The profiles are root-owned, so this is a guard against author error, not a boundary against the agent. Its danger is that the stated guarantee is stronger than the one the code provides, and that could let a reviewer approve `.s3.amazonaws.com`-shaped entries.

**Recommendation:** Rewrite the comment and decision row 55 to describe the check as a minimum that rejects `.com` and `.example.com`-shaped zones only. Optionally, add a small denylist of known multi-tenant suffixes (`s3.amazonaws.com`, `blob.core.windows.net`, `*.co.uk`-style second-level suffixes, `storage.googleapis.com`), or require a `# residual:` comment line to sit immediately above every zone entry and check for it in `parse`/bats.

#### 3. The residual justification ("reading adds no new sink") is imprecise: it ignores ingress, and the frame origin's write surface is unverified

**Severity:** Low
**Location:** `devcontainer-config/egress/base.txt:62-63`, `devcontainer-config/init-firewall.sh:1176-1180`, `docs/decisions/log.md` row 55
**Boundary:** B5
**Move:** 1 (trust boundaries), 5
**Confidence:** Medium

Three claims in the justification have problems:

1. **"Reading a frame adds no destination the agent could not already write to."** The zone admits every artifact anyone publishes. For the agent, that means a free, anonymous, attacker-editable host under an allowlisted name. It can be used for second-stage prompt-injection payloads and polled C2 (the attacker updates the artifact and the agent re-reads it). That is an ingress and command channel, and the justification only discusses writes.
2. **Writes to the frame origin.** Artifact pages can declare runtime capabilities (shared database, file storage, "ask Claude"). I could not verify whether any of these are served as HTTP endpoints under `<uuid>.frame.claudeusercontent.com` that accept unauthenticated writes, or writes authenticated only by the artifact URL. If they are, an injected agent could POST data into an attacker-owned artifact's shared store, and the attacker could read it back. That is a write sink this commit adds.
3. **"The Artifact tool already PUBLISHES through api.anthropic.com."** I could not verify this; the tool may publish via `claude.ai`. The conclusion probably still holds, because both hosts are in `base`.

The overall conclusion, that this does not materially widen exfiltration, is still probably right. The 2026-08-29 review already records `api.anthropic.com` as an irreducible general-purpose channel, and records base GitHub egress (gists, repo pushes, raw content) as attacker-readable and attacker-writable. But that is the argument the comments should make, not the one they do make.

**Recommendation:** Replace the justification in all three places. It should say that the zone gives attacker-authored ingress and possibly an owner-readable write sink, and that this is accepted because base already carries equivalent channels (the `api.anthropic.com` channel and GitHub gists/raw), citing `security-review-cc-isolated-egress-2026-08-29.md`. Queue a check, through a running container, of whether the frame origin accepts non-GET requests.

#### 4. The resolver's RESIDUAL comment was not updated for the new zone

**Severity:** Informational
**Location:** `devcontainer-config/init-firewall.sh:915-922`
**Boundary:** B2
**Move:** 2 (implicit assumption)
**Confidence:** High (read-static)

The DNS residual block lists "the base zones" and asserts that none of them delegate to third parties. The list is already stale: it omits `claude.com`, `code.claude.com`, `downloads.claude.ai` and `mcp-proxy.anthropic.com`. It now also omits `frame.claudeusercontent.com`. That is the one base zone whose names are generated per object, and it is the one most likely to be served by a CDN or hosting vendor's authoritative servers. `server=/frame.claudeusercontent.com/` forwards `<any-data>.frame.claudeusercontent.com` upstream. The data therefore reaches whoever is authoritative for that sub-tree. If that is Anthropic or its DNS provider, the attacker cannot read it. I could not check the delegation (no egress; the local resolver REFUSED the NS query).

**Recommendation:** Add the zone to the list, or replace the list with "every base entry, see base.txt". Queue a host-side `dig NS frame.claudeusercontent.com` and `dig NS claudeusercontent.com`.

#### 5. The dnsmasq composer enforces a weaker grammar than `parse_entry` and depends on call order

**Severity:** Informational
**Location:** `devcontainer-config/init-firewall.sh:231-239`
**Boundary:** B2
**Move:** 2
**Confidence:** High (executed + traced)

`compose_dnsmasq_conf` strips one leading dot and then checks `HOST_RE`, so a two-label `.claudeusercontent.com` becomes `server=/claudeusercontent.com/`. That config is never produced in a real run, because `parse_entry` aborts the run first. I executed this: the bats test "a two-label zone aborts a full run before any network read" passes. Even if it were produced, it would match what an exact `claudeusercontent.com` entry already produces, because the resolver side has always been zone-scoped. So there is no bypass. However, the comment on line 235 ("HOST_RE is the same grammar parse_entry enforces") is no longer literally true, and the three-label rule protects only the SNI layer.

**Recommendation:** Update the comment to say that the three-label rule constrains the SNI layer only, and that the resolver is zone-scoped for every entry anyway.

#### 6. The canary is assumed to be equivalent to real names, and the apex addresses are added too

**Severity:** Informational (availability)
**Location:** `devcontainer-config/init-firewall.sh:498-517`
**Boundary:** B3
**Move:** 8
**Confidence:** Low (unverifiable offline)

If the frame zone is not a wildcard, the canary gets NXDOMAIN. The same happens if real names are geo- or round-robin-balanced across a larger pool than one answer shows. The ipset then under-covers, and requests fail with `FAIL … not admitted by the ipset`. This fails closed. The proxy also connects only to `infos[0]` (`cc-sni-proxy.py:201`), with no fallback. The apex addresses are admitted on the entry's ports as well. That is harmless on 443, where the SNI layer still applies, but see Finding 1 for ports other than 443.

**Recommendation:** None required beyond Finding 1. Verify live once: resolve three real artifact UUIDs and compare them with the canary's answer.

## Untested bypass candidates

- **Domain fronting on the frame front.** A request can carry SNI `x.frame.claudeusercontent.com` with an HTTP `Host:` naming another tenant of the same CDN edge. The proxy checks only the SNI and never sees the Host header, because TLS is spliced. If the front does not enforce SNI/Host agreement, the zone admits other tenants. This class already exists for every allowlisted 443 name and I found no prior review that covers it. Not tested: it needs live egress.
- **Unauthenticated write endpoints under the frame origin** (Finding 3). Not tested: needs live egress.
- **DNS tunnelling to a third-party authoritative for `frame.claudeusercontent.com`** (Finding 4). Not tested: NS lookup REFUSED locally.

## Tested bypass candidates (grammar, B1/B2)

I ran each entry through `--print-entries` and `--print-dnsmasq-conf` with a temporary `CC_EGRESS_DIR`:

| Input | Result |
|---|---|
| `.a.b.c\r` (CRLF profile) | rejected |
| `.a.b.c ` (trailing space) | rejected |
| `.a..b.c` | rejected |
| `.a.b.c/x` (dnsmasq `/` directive syntax) | rejected |
| `.a.b.c:` | rejected |
| `.a.b.c:443:22` | rejected |
| `..x`, `.`, `*.x.y.z`, trailing dot, leading hyphen | rejected (existing bats tests) |
| `.A.B.C` | accepted. Harmless: dnsmasq matches case-insensitively and the proxy lowercases |
| `.a.b.c:0443,22` | accepted and canonicalised to `443,22` |
| an 80-character label | accepted. Harmless: dig fails, so the entry is warn-skipped and stays blocked |
| `.1.2.3` (all-numeric) | accepted. Inert |

In the full stubbed run, the dotted string never reaches `dig` and no `server=/.` line is emitted. Both are verified by bats and I re-ran them.

## Endorsement Claims

- **Claim:** A leading-dot entry cannot carry `/`, `#`, whitespace, CR, or an empty label into `ALLOWED_ENTRIES`.
  **Location:** `devcontainer-config/init-firewall.sh:134-143, 153`
  **Evidence:** executed
  **Verified:** the table above, plus `bats test/init-firewall-rules.bats` (93/93 passing) on 7c970bf.
  **Not verified:** profile files containing NUL bytes or non-UTF-8 bytes, as seen by `grep -hvE` in `compose_domains`.
- **Claim:** For a 443 zone entry, the resolver and the SNI proxy admit the same set: the apex and every subdomain.
  **Location:** `init-firewall.sh:229-243`, `cc-sni-proxy.py:151-156`
  **Evidence:** read-static (`server=/z/` semantics) + executed (allowlist file contents in bats)
  **Verified:** `Allowlist.allows` checks `name == z or name.endswith("." + z)`, and `server=/z/` matches the zone and every name under it, as documented for dnsmasq.
  **Not verified:** dnsmasq's live behaviour for the apex with this exact config. No dnsmasq was run.
  **route: code-fact-check**
- **Claim:** A two-label zone aborts the run before any network read or flush.
  **Location:** `init-firewall.sh:370-377`
  **Evidence:** executed (bats: "a two-label zone aborts a full run before any network read")
  **Verified:** no `curl`, `dig` or `iptables -F` calls appear in the stub log.
  **Not verified:** the `--print-dnsmasq-conf` hook path, which does not parse entries. It is inspection-only.

## Primitive sweep

Primitive: process exec with profile-derived arguments / config-directive emission

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `init-firewall.sh:518` `dig … A "$name"` | S1 (apex, canary) | parse_entry grammar; canary prefix is a constant | cleared: the executed bats test shows no dotted or dash-leading argument |
| `init-firewall.sh:241` `server=/$d/$ns` written to dnsmasq config | S1 | HOST_RE after stripping one dot | cleared; see Finding 5 |
| `init-firewall.sh:1187-1190` SNI allowlist line | S1 | parse_entry; ports filtered to 443 | cleared: `Allowlist.load` treats the line as data |
| `init-firewall.sh:533-548` ipset member `${ip},tcp:${port}` | S2, S1 | IPv4 shape regex; canonical ports | cleared for injection. **Finding 1** for who chooses the IP |
| `cc-sni-proxy.py:199-203` getaddrinfo(SNI) → connect | S3 | Allowlist + ipset | cleared, unchanged by this diff. Domain fronting is untested (above) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Predictable canary lets name holders choose ipset contents; zone entries on ports other than 443 have no name check | Low (latent) | B3, B1 | `init-firewall.sh:506-513, 143, 153` | High (mechanism) |
| 2 | Three-label rule ≠ non-registrable; admits `.s3.amazonaws.com`, `.example.co.uk` | Low | B1, B2 | `init-firewall.sh:140-143`, `base.txt:30-33`, log row 55 | High |
| 3 | Residual rationale ignores ingress/C2; frame-origin write surface unverified | Low | B5 | `base.txt:62-63`, `init-firewall.sh:1176-1180`, log row 55 | Medium |
| 4 | Resolver RESIDUAL zone list is stale and omits the frame zone | Info | B2 | `init-firewall.sh:915-922` | High |
| 5 | dnsmasq composer grammar is weaker than parse_entry; comment inaccurate | Info | B2 | `init-firewall.sh:231-239` | High |
| 6 | Canary/wildcard equivalence and apex-address admission unverified | Info | B3 | `init-firewall.sh:498-517` | Low |

## Overall Assessment

The grammar change is tight. I found no input that gets a directive, an unintended zone, a wider match, or option-like text into dnsmasq, the SNI allowlist, the ipset or dig, and the three layers agree for 443 zone entries. The shipped zone is defensible: its names are assigned by the server, and the exfiltration and ingress it admits already exist in `base` through `api.anthropic.com` and GitHub. The main weakness is in the general mechanism, not in this entry. A zone on a port other than 443 has no name check at all, and the fixed canary label hands the ipset's contents to whoever can claim a label under the zone. Both become live the first time someone adds a zone with user-claimable labels. The most important fix is to restrict zone entries to port 443 and randomize the canary label. The comment and decision-log claims in Findings 2 and 3 should also be corrected so that they do not overstate the guarantee. No findings within the code paths read are above Low; endorsement claims are pending execution verification where marked.
