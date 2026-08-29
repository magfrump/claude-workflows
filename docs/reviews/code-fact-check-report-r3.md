# Code Fact-Check Report

Commit: c44c33a

**Repository:** /workspace (branch `harden/cc-isolated-egress`)
**Scope:** commit c44c33a — `devcontainer-config/init-firewall.sh` (code) and `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md` (review artifact, factual claims about the firewall mechanism)
**Checked:** 2026-08-29
**Total claims checked:** 11
**Summary:** 9 verified, 0 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable

Empirical note: the `set -e` / `set -o pipefail` behavior underpinning Claims 2 and 9 was verified by running isolated reproductions of the exact `awk … | grep -E … | sort -u` pipeline (results quoted inline), not by reasoning about bash semantics alone.

---

## Claim 1: Outbound DNS is scoped to the container's configured resolvers, removing the direct `attacker_ip:53` exfil path

**Location:** `devcontainer-config/init-firewall.sh:94-115`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** `security-reviewer` — this is the defense-in-depth claim the security critic builds on; it must be able to trust that only resolver IPs are admitted on port 53.

When at least one IPv4 nameserver parses, the code emits a per-resolver ACCEPT bound to that destination IP rather than a blanket accept:

```bash
# devcontainer-config/init-firewall.sh:108-115
dns_resolvers="$(awk '/^[[:space:]]*nameserver/ {print $2}' /etc/resolv.conf 2>/dev/null \
  | grep -E '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' | sort -u)"
if [ -n "$dns_resolvers" ]; then
  while read -r ns; do
    echo "Allowing DNS to configured resolver $ns"
    iptables -A OUTPUT -p udp -d "$ns" --dport 53 -j ACCEPT
    iptables -A OUTPUT -p tcp -d "$ns" --dport 53 -j ACCEPT
  done < <(echo "$dns_resolvers")
```

I confirmed the scoped branch runs and admits exactly the parsed resolvers by executing the identical pipeline with a two-nameserver `resolv.conf`:

```
SURVIVED; dns_resolvers=[127.0.0.11
8.8.8.8]
would allow 127.0.0.11
would allow 8.8.8.8
exit=0
```

The comment's claim that this "removes that direct path" while NOT closing recursive-forward tunnelling (lines 100-103) is a correct characterization: an IP firewall bound to resolver IPs cannot inspect query names, so a name recursed through the legitimate resolver still leaves (paraphrased — no quote available because the residual concerns the absence of DNS-payload filtering, which is a property of the whole rule set, not a single quotable line).

**Evidence:** `devcontainer-config/init-firewall.sh:108-115`, `devcontainer-config/init-firewall.sh:94-103`

---

## Claim 2: "Fail OPEN if we cannot parse any resolver" — the `else` branch re-adds a blanket DNS accept so session start is never bricked

**Location:** `devcontainer-config/init-firewall.sh:105-107` (comment) and `116-120` (else branch)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** future maintainer and `security-reviewer` — the comment promises an availability guarantee (session start survives a missing/unparseable resolver) that the code does not deliver; a reader trusting it would mis-model the failure mode.

The comment and the `else` branch both assert a graceful fail-open:

```bash
# devcontainer-config/init-firewall.sh:105-107
# Fail OPEN if we cannot parse any resolver: bricking DNS bricks session start,
# and this repo's boundary changes never trade availability for a partial hardening
# (cf. the statsig NXDOMAIN incident). A warning marks the degraded case.
```

```bash
# devcontainer-config/init-firewall.sh:116-120
else
  echo "WARNING: no IPv4 nameserver in /etc/resolv.conf — allowing DNS to any host (unscoped)" >&2
  iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
  iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
fi
```

The `else` branch is unreachable. The script sets `set -euo pipefail` at the top:

```bash
# devcontainer-config/init-firewall.sh:20
set -euo pipefail  # Exit on error, undefined vars, and pipeline failures
```

`dns_resolvers` is empty precisely when `grep -E` matches nothing — and a no-match `grep` exits `1`. With `pipefail`, that non-zero status becomes the pipeline's status, and because the pipeline is the command substitution of a plain assignment (`dns_resolvers="$(…)"`), `set -e` aborts the script at line 108-109 before the `if` is ever evaluated. I reproduced the two documented trigger scenarios with the exact pipeline from the file:

No `nameserver` line present (grep no-match):
```
# printf 'search foo\n' | awk … | grep -E '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' | sort -u
exit=1        # "SURVIVED assignment" never printed — script aborted at the assignment
```

`/etc/resolv.conf` missing (awk error suppressed, grep no-match):
```
exit=1        # again aborted before reaching the else branch
```

The trigger is specifically `pipefail` + `set -e`; with `set -e` but no `pipefail`, `sort -u`'s exit-0 masks grep and the script survives:
```
exit(pipefail+e)=1      # aborts
exit(e,no-pipefail)=0   # survives
```

Because this script is the container firewall init, aborting with a non-zero exit fails the boundary setup — the opposite of the "fail OPEN … never trade availability" behavior the comment claims. The unscoped-DNS `else` branch can only be reached if `dns_resolvers` is empty *and* the pipeline exited 0, which cannot happen while `grep` is the pipeline's exit-status determiner. The IPv6-only-resolver case named verbatim in the line 117 warning ("no IPv4 nameserver") is exactly a grep-no-match case, so it aborts rather than warning-and-continuing.

**Evidence:** `devcontainer-config/init-firewall.sh:20`, `devcontainer-config/init-firewall.sh:108-120`

---

## Claim 3: SSH to allowlisted hosts (all of GitHub) still works after removing the blanket `--dport 22` accept, via the dst-matched `allowed-domains` ACCEPT

**Location:** `devcontainer-config/init-firewall.sh:123-132`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** `security-reviewer` and repo owner — the security review's finding #1 rests on "GitHub SSH still works via CIDR"; this must be traceable so the removal is not mistaken for a regression.

The comment claims GitHub SSH survives because GitHub's IPs sit in `allowed-domains`, matched on destination regardless of port. Both halves check out. GitHub's meta CIDRs are added unconditionally:

```bash
# devcontainer-config/init-firewall.sh:154-164
while read -r cidr; do
    ...
    ipset add -exist allowed-domains "$cidr"
done < <(echo "$gh_ranges" | jq -r '(.web + .api + .git)[]' | aggregate -q)
```

and the OUTPUT accept matches that ipset on destination with no port qualifier:

```bash
# devcontainer-config/init-firewall.sh:219
iptables -A OUTPUT -m set --match-set allowed-domains dst -j ACCEPT
```

An outbound SSH SYN to a GitHub IP therefore hits `-P OUTPUT DROP` (line 212) but is matched and accepted by line 219 before reaching the final REJECT (line 222), independent of the removed dport-22 rule. The scoping of "all of GitHub" to the `.git` meta ranges is correct in the sense that GitHub publishes its git/SSH server ranges in the `.git` field consumed at line 164 (paraphrased — no quote available because whether every GitHub SSH endpoint IP is contained in the live `api.github.com/meta` `.git` set is a property of GitHub's published data, not of this file; it is GitHub's documented contract but not statically verifiable here).

**Evidence:** `devcontainer-config/init-firewall.sh:123-132`, `devcontainer-config/init-firewall.sh:154-164`, `devcontainer-config/init-firewall.sh:212`, `devcontainer-config/init-firewall.sh:219-222`

---

## Claim 4: "the ESTABLISHED,RELATED accept covers the return path"

**Location:** `devcontainer-config/init-firewall.sh:129-130`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** `security-reviewer` — confirms the SSH removal does not strand return traffic for allowed connections.

The comment states the return path for allowlisted SSH (and all admitted outbound) is covered by the ESTABLISHED,RELATED accepts. Both directions exist:

```bash
# devcontainer-config/init-firewall.sh:214-216
# First allow established connections for already approved traffic
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
```

Return packets for a connection whose outbound SYN was accepted by line 219 are ESTABLISHED and admitted by the INPUT rule at line 215, so the removed inbound `--sport 22 … ESTABLISHED` rule is redundant with this general accept.

**Evidence:** `devcontainer-config/init-firewall.sh:214-216`

---

## Claim 5: DNS ACCEPT rules are added before the default `-P OUTPUT DROP` policy so the per-resolver accepts take effect

**Location:** `devcontainer-config/init-firewall.sh:108-120` relative to `212`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** future maintainer — establishes that rule-append order relative to the policy switch preserves DNS reachability.

The DNS accepts are appended at lines 113-119; the default DROP policy is set later:

```bash
# devcontainer-config/init-firewall.sh:210-212
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP
```

`iptables -P` sets only the chain's default policy and does not remove appended rules, and the default policy is evaluated only after no rule matches. The DNS ACCEPT rules (lines 113-119) also precede the terminal `-j REJECT` (line 222), so a DNS packet to an admitted resolver matches ACCEPT before reaching either the REJECT or the DROP policy. Ordering is correct for the scoped-branch case.

**Evidence:** `devcontainer-config/init-firewall.sh:113-120`, `devcontainer-config/init-firewall.sh:210-212`, `devcontainer-config/init-firewall.sh:222`

---

## Claim 6 (doc): "the allowlist matches on destination IP, not SNI/Host … per-IP for all ports"

**Location:** `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:23-27`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** repo owner — this "load-bearing weakness" framing drives findings 5 and the CDN-overreach entries; it must match the actual match rule.

The doc's central mechanism claim maps directly onto line 219:

```bash
# devcontainer-config/init-firewall.sh:219
iptables -A OUTPUT -m set --match-set allowed-domains dst -j ACCEPT
```

`--match-set allowed-domains dst` matches solely on destination IP; there is no `--dport`/`--sport` or layer-7 qualifier, so any port to an admitted IP is accepted. The ipset is `hash:net` (line 138), holding both CIDRs and resolved A-record IPs — consistent with "a domain is resolved once at start."

**Evidence:** `devcontainer-config/init-firewall.sh:138`, `devcontainer-config/init-firewall.sh:219`

---

## Claim 7 (doc): GitHub CIDRs are "added for every project regardless of profile"

**Location:** `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:16-18` and `:36`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** repo owner — the doc treats GitHub as the widest always-on surface; that depends on the CIDR fetch being unconditional.

The GitHub meta fetch and ipset population sit on the unconditional firewall path, gated by no profile check:

```bash
# devcontainer-config/init-firewall.sh:141-146
echo "Fetching GitHub IP ranges..."
gh_ranges=$(curl -s https://api.github.com/meta)
if [ -z "$gh_ranges" ]; then
    echo "ERROR: Failed to fetch GitHub IP ranges"
    exit 1
fi
```

The only inputs to profile composition are the `base` file plus `/etc/cc-egress-profile` (lines 30-51); the GitHub block runs afterward for all profiles. `base.txt` itself notes "GitHub's IP ranges are added separately from api.github.com/meta, not listed here," matching the doc.

**Evidence:** `devcontainer-config/init-firewall.sh:141-164`, `devcontainer-config/egress/base.txt:2`

---

## Claim 8 (doc): `host.docker.internal` "opens every host port to the container, not just the model server"

**Location:** `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:47`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** repo owner — the `llm` profile risk note; the "all host ports" consequence follows from the same dst-match property as Claim 6.

`host.docker.internal` appears only as a domain in the `llm` egress profile; when that profile is active it is resolved to the host IP and added to `allowed-domains` (lines 167-193), then admitted by the port-agnostic dst-match at line 219. Because line 219 carries no port qualifier, every port on that host IP is reachable, not only Ollama's `:11434`. The consequence is a correct restatement of the Claim 6 mechanism.

**Evidence:** `devcontainer-config/egress/llm.txt`, `devcontainer-config/init-firewall.sh:167-193`, `devcontainer-config/init-firewall.sh:219`

---

## Claim 9 (doc): "Scoped outbound DNS to `/etc/resolv.conf` resolvers, fail-open with warning"

**Location:** `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:83-86` and `:124-125`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** repo owner reviewing the shipped patch — the doc records "fail open (with a warning) if none parse so session start can never brick" as a delivered property; per Claim 2 it is not delivered.

The doc asserts the fail-open guarantee twice:

> "scoped outbound 53 to the resolvers in `/etc/resolv.conf`, failing open (with a warning) if none parse so session start can never brick." (lines 84-86)

> "Scoped outbound DNS to `/etc/resolv.conf` resolvers, fail-open with warning." (line 125)

The "scoped to resolvers" half is accurate (Claim 1). The "fail-open … session start can never brick" half is contradicted by the same `set -euo pipefail` + no-match-`grep` interaction documented in Claim 2: when no IPv4 resolver parses, the script aborts at the `dns_resolvers=` assignment (line 108-109) instead of reaching the unscoped `else` accept, which fails the firewall init — a brick, not a fail-open. Same underlying defect as Claim 2, surfaced here because the review artifact repeats the incorrect guarantee.

**Evidence:** `devcontainer-config/init-firewall.sh:20`, `devcontainer-config/init-firewall.sh:108-120`, cross-reference Claim 2.

---

## Claim 10 (doc): "Removed the blanket outbound-SSH accept (and its inbound-response companion)"

**Location:** `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:123-124`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** repo owner — the "What was changed" summary; must match the diff.

The diff under review removes both the outbound `iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT` and the inbound `iptables -A INPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT` lines, replacing them with the NOTE comment at lines 123-132 (paraphrased — no quote available because the claim is about deleted lines that no longer appear in the current file; the removal is visible in the reviewed diff hunk, where both `-` lines are the two SSH rules). No `--dport 22` or `--sport 22` rule remains anywhere in the current `init-firewall.sh`.

**Evidence:** `devcontainer-config/init-firewall.sh:123-132` (replacement comment), reviewed diff hunk (removed `-` lines).

---

## Claim 11 (doc): "the 52 `test/cc-isolated-functions.bats` tests are unaffected"

**Location:** `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:129-131`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** repo owner — a specific artifact count; the project's hallucination log has two prior "quoted count that does not exist" fabrications, so this was checked directly.

`test/cc-isolated-functions.bats` contains exactly 52 `@test` cases:

```
# grep -cE '^\s*@test ' test/cc-isolated-functions.bats
52
```

The "unaffected" half is also consistent with the code: both edits are past the `--print-domains` early exit (line 59), and the bats suite exercises `compose_domains` via `--print-domains` (lines 53-59), which the DNS/SSH edits do not touch.

**Evidence:** `test/cc-isolated-functions.bats` (52 `@test` cases), `devcontainer-config/init-firewall.sh:53-59`

---

## Claims Requiring Attention

### Incorrect
- **Claim 2** (`devcontainer-config/init-firewall.sh:105-120`): The "fail OPEN if we cannot parse any resolver" comment and its `else` branch are contradicted by `set -euo pipefail` (line 20): a no-match `grep` in the `dns_resolvers="$(…)"` pipeline aborts the whole firewall script at line 108-109, so the unscoped-DNS `else` branch is unreachable and a missing/IPv6-only/absent resolver bricks session start rather than failing open. Fix: capture the pipeline so grep's exit-1 cannot trip `set -e` — e.g. `dns_resolvers="$(awk … | grep -E … | sort -u || true)"`, or guard with `set +e`/`set -e` around the assignment (verified: adding `|| true` / dropping `pipefail` lets the else branch run).
- **Claim 9** (`docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:83-125`): The review artifact records the fail-open guarantee ("session start can never brick") as shipped; it is not, for the same reason as Claim 2. Update the doc once the code is fixed, or note the guarantee as not-yet-delivered.

### Stale
- (none)

### Mostly Accurate
- (none)

### Unverifiable
- (none)

---

## Goal-Alignment Note

The stated goal of commit c44c33a is to harden the devcontainer egress firewall by (1) removing the blanket outbound-SSH accept and (2) scoping outbound DNS to configured resolvers. Against that goal:

- **Objective (1) is met and its documentation is accurate.** The blanket dport-22 accept and its inbound companion are gone (Claim 10), and SSH to GitHub genuinely still works through the port-agnostic `allowed-domains` dst-match plus ESTABLISHED,RELATED return path (Claims 3, 4). The comments and the review artifact describe this correctly.
- **Objective (2) is half-met, and its documentation overstates the result.** The scoping itself is correct and the direct `attacker_ip:53` exfil path is closed when a resolver parses (Claim 1). But the advertised safety net — "fail OPEN … session start can never brick" (Claims 2, 9) — is not delivered: the very condition it names (no parseable IPv4 resolver) aborts the firewall init under `set -euo pipefail`, the opposite of fail-open. This is the one place where a reader acting on the comment (or the review's "what was changed" summary) would be materially misled, and it is a functional latent bug, not merely a doc drift. It matters most in exactly the degraded environments the comment cites (IPv6-only or missing `resolv.conf`).
- All firewall-mechanism claims in the companion review artifact that I spot-checked (dst-IP not SNI matching, GitHub CIDRs always added, `host.docker.internal` opening all host ports, the 52-test count) are accurate against the code (Claims 6, 7, 8, 11); the only doc inaccuracy is the fail-open guarantee it inherits from the code comment.

No fabricated symbols, APIs, or nonexistent behaviors were found (the two Incorrect verdicts are a behavioral/semantic defect, not a fabrication), so no new entry is added to `docs/reviews/hallucination-patterns.md`.
