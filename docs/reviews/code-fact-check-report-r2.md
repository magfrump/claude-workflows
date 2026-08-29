# Code Fact-Check Report

**Commit:** c44c33a
**Repository:** /workspace (branch `harden/cc-isolated-egress`)
**Scope:** commit c44c33a — `devcontainer-config/init-firewall.sh` (code) + `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md` (companion doc, factual claims about the firewall mechanism only)
**Checked:** 2026-08-29
**Total claims checked:** 9
**Summary:** 7 verified, 0 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) was read first. Neither Incorrect verdict below is a fabricated symbol/API — both are behavioral-mismatch bugs (comment describes intended behavior the code does not produce), so neither matches or adds to that log.

---

## Claim 1: "First allow DNS and localhost before any restrictions"

**Location:** `devcontainer-config/init-firewall.sh:92`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Operator reasoning about rule-evaluation order / why DNS is reachable under a default-DROP policy.

The DNS ACCEPT rules are appended to the `OUTPUT` chain before the DROP policy is set. The per-resolver accepts are at lines 113-114:

```bash
# devcontainer-config/init-firewall.sh:113-114
iptables -A OUTPUT -p udp -d "$ns" --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp -d "$ns" --dport 53 -j ACCEPT
```

and the default-DROP policy is set later, at line 212:

```bash
# devcontainer-config/init-firewall.sh:210-212
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP
```

Because iptables evaluates chain rules in order and the policy applies only when no rule matches, DNS to a configured resolver matches the ACCEPT rule regardless of the (later) DROP policy. Ordering claim holds.

**Evidence:** `devcontainer-config/init-firewall.sh:113-114`, `devcontainer-config/init-firewall.sh:210-212`, `devcontainer-config/init-firewall.sh:218-222`

---

## Claim 2: "Outbound DNS is scoped to the container's CONFIGURED resolvers (from /etc/resolv.conf), not to 0.0.0.0/0"

**Location:** `devcontainer-config/init-firewall.sh:94-100`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Security reviewer assessing the DNS-exfil channel (does a compromised session still have an unscoped UDP/53 socket?).

When at least one IPv4 nameserver parses, the accepts are `-d "$ns"` scoped, not blanket:

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

I reproduced the parse pipeline against a `resolv.conf` containing `nameserver 192.168.1.1` / `nameserver 8.8.8.8`: it yields exactly those two IPs and takes the scoped branch (paraphrased — no quote available because the evidence is a runtime execution of the pipeline in a scratch shell, not a source snippet). The old blanket `iptables -A OUTPUT -p udp --dport 53 -j ACCEPT` is gone from the happy path, confirming the "not 0.0.0.0/0" claim for the configured-resolver case.

**Evidence:** `devcontainer-config/init-firewall.sh:108-120`

---

## Claim 3: "Fail OPEN if none parse" / "no IPv4 nameserver in /etc/resolv.conf — allowing DNS to any host (unscoped)"

**Location:** `devcontainer-config/init-firewall.sh:104-107` and `:117`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** Operator debugging a bricked session start; the availability guarantee the comment explicitly promises ("bricking DNS bricks session start … never trade availability for a partial hardening").

The comment claims that when no resolver parses, the script falls through to a blanket DNS accept and continues (fail-open). It does not. Under `set -euo pipefail` (line 20) the empty-match case aborts the whole script *before* the `else` branch is ever reached.

The assignment is a pipeline inside a command substitution:

```bash
# devcontainer-config/init-firewall.sh:108-109
dns_resolvers="$(awk '/^[[:space:]]*nameserver/ {print $2}' /etc/resolv.conf 2>/dev/null \
  | grep -E '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' | sort -u)"
```

When `/etc/resolv.conf` has no `nameserver` line (or is missing), `grep` receives no matching input and exits `1`. With `set -o pipefail`, the pipeline's status becomes that non-zero `grep` status (the trailing `sort -u` exiting `0` does not mask it). The `2>/dev/null` on `awk` suppresses only awk's stderr, not any exit code. A bare global assignment `var="$(pipeline)"` propagates the command-substitution status as the assignment's own status, so `set -e` fires and the script exits `1` at line 109 — the `else` fail-open block at lines 116-120 is dead in exactly the scenario the comment says it protects.

I verified this empirically in a scratch shell reproducing lines 20-21 and 108-115 against (a) a missing resolv.conf, and (b) a resolv.conf with no `nameserver` line: both aborted at the assignment with exit `1` and never printed a post-assignment line, while a resolv.conf *with* nameservers took the scoped branch normally (paraphrased — no quote available because the evidence is runtime shell execution, not a source snippet).

Net effect: instead of failing open, the script aborts. Because it dies at line 109 — before `iptables -P OUTPUT DROP` at line 212 — no firewall is configured at all and session start fails, which is the precise "brick" the comment claims this design avoids. The behavior is the opposite of documented.

**Evidence:** `devcontainer-config/init-firewall.sh:20`, `devcontainer-config/init-firewall.sh:104-120`, `devcontainer-config/init-firewall.sh:210-212`

---

## Claim 4: "SSH to ALLOWLISTED hosts (all of GitHub …) still works — dst IPs in allowed-domains ipset, matched by the OUTPUT accept near the end regardless of port; ESTABLISHED,RELATED covers the return path"

**Location:** `devcontainer-config/init-firewall.sh:123-132`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Developer who relied on `git+ssh` to GitHub and needs to know the SSH removal did not break it.

The blanket `--dport 22` accept is indeed removed from the diff, and the replacement path holds. GitHub's CIDRs are added to the `allowed-domains` ipset unconditionally (not profile-gated):

```bash
# devcontainer-config/init-firewall.sh:154-164
while read -r cidr; do
    ...
    ipset add -exist allowed-domains "$cidr"
done < <(echo "$gh_ranges" | jq -r '(.web + .api + .git)[]' | aggregate -q)
```

The OUTPUT accept matches destination membership in that ipset with no protocol/port qualifier, so a TCP SYN to a GitHub IP on port 22 matches:

```bash
# devcontainer-config/init-firewall.sh:219
iptables -A OUTPUT -m set --match-set allowed-domains dst -j ACCEPT
```

and the return path is covered by the ESTABLISHED,RELATED accepts on both chains:

```bash
# devcontainer-config/init-firewall.sh:215-216
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
```

One external dependency the static trace cannot itself confirm: that GitHub's SSH endpoint IPs actually fall within the fetched `.web + .api + .git` union at runtime (that depends on the live `api.github.com/meta` response and DNS). The iptables mechanism — dst-match accepts any port for any ipset member — is verified with high confidence; the "all of GitHub reachable over SSH" conclusion inherits GitHub's own publishing of its git-source ranges in `.git`.

**Evidence:** `devcontainer-config/init-firewall.sh:138`, `devcontainer-config/init-firewall.sh:154-164`, `devcontainer-config/init-firewall.sh:215-216`, `devcontainer-config/init-firewall.sh:219`

---

## Claim 5 (companion doc): "the allowlist matches on destination IP, not SNI/Host"

**Location:** `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:23-27`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Security reviewer weighing CDN/GFE shared-IP overreach.

The match is IP-based: domains are resolved to A records and their IPs added to the ipset, and the accept rule matches `dst` set membership — there is no TLS/SNI inspection anywhere in the script.

```bash
# devcontainer-config/init-firewall.sh:169
ips=$(dig +noall +answer A "$domain" | awk '$4 == "A" {print $5}')
```
```bash
# devcontainer-config/init-firewall.sh:219
iptables -A OUTPUT -m set --match-set allowed-domains dst -j ACCEPT
```

No `--sni`, `-m string`, or L7 module appears in the file (paraphrased — no quote available because this is a claim about the *absence* of SNI/Host matching; a grep of the script returns no such rule).

**Evidence:** `devcontainer-config/init-firewall.sh:169`, `devcontainer-config/init-firewall.sh:219`

---

## Claim 6 (companion doc): "GitHub CIDRs — the union of .web + .api + .git … added for every project regardless of profile"

**Location:** `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:16-20` and `:36`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Security reviewer assessing the always-on writable-GitHub exfil surface.

The GitHub fetch/add block sits in the main firewall path with no dependence on `ALLOWED_DOMAINS` or the profile file, and consumes exactly `.web + .api + .git`:

```bash
# devcontainer-config/init-firewall.sh:142-164
gh_ranges=$(curl -s https://api.github.com/meta)
...
done < <(echo "$gh_ranges" | jq -r '(.web + .api + .git)[]' | aggregate -q)
```

The block is not inside the `for domain in $ALLOWED_DOMAINS` loop and is not guarded by any profile check, so it runs for every launch regardless of `CC_EGRESS_PROFILE`. Verdict confirmed.

**Evidence:** `devcontainer-config/init-firewall.sh:140-164`, `devcontainer-config/init-firewall.sh:166-167`

---

## Claim 7 (companion doc / llm.txt): "host.docker.internal … dst-match opens EVERY host port to the container, not just the model server's"

**Location:** `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:47`; `devcontainer-config/egress/llm.txt` (host.docker.internal SCOPE CAVEAT)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Owner deciding whether the `llm` profile's host reach is acceptably scoped.

`host.docker.internal` is listed in `llm.txt`, so it flows through the resolve-and-add loop and its IP lands in `allowed-domains` (paraphrased — no quote available because the domain's membership spans the profile file `devcontainer-config/egress/llm.txt` and the resolution loop, not a single line). The accept rule that then matches it is port-agnostic:

```bash
# devcontainer-config/init-firewall.sh:219
iptables -A OUTPUT -m set --match-set allowed-domains dst -j ACCEPT
```

Because the rule carries no `--dport`, every TCP/UDP port on that resolved host IP is reachable, not only the Ollama port. The "opens every host port" claim is accurate for the dst-match design.

**Evidence:** `devcontainer-config/egress/llm.txt`, `devcontainer-config/init-firewall.sh:167-193`, `devcontainer-config/init-firewall.sh:219`

---

## Claim 8 (companion doc): "scoped outbound 53 to the resolvers … failing open (with a warning) if none parse so session start can never brick"

**Location:** `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:82-86` (also the table row at `:33`)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** Reviewer trusting the review's own availability assurance; downstream security-reviewer inheriting this report.

This is the companion doc repeating the same fail-open assertion checked in Claim 3, and it is wrong for the same reason. The doc states session start "can never brick" because the no-resolver case falls open. In fact, under `set -euo pipefail`, the no-resolver case aborts the script at the `dns_resolvers=` assignment (grep exits 1 → pipefail → assignment fails → `set -e` exits), before the `else` warning/blanket-accept branch and before any DROP policy is applied (paraphrased — no quote available because this restates the Claim 3 finding; the source lines are quoted there). So the exact "brick" the doc says is avoided is what actually occurs when `/etc/resolv.conf` has no parseable IPv4 nameserver. The scoping-when-resolvers-exist half of the sentence is correct; the fail-open/never-brick half is not.

**Evidence:** `devcontainer-config/init-firewall.sh:20`, `devcontainer-config/init-firewall.sh:108-120`, `devcontainer-config/init-firewall.sh:210-212`

---

## Claim 9 (companion doc): "Both edits are inside the firewall-application path (after the --print-domains early exit), so … the 52 test/cc-isolated-functions.bats tests are unaffected"

**Location:** `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:127-131`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Reviewer confirming the change did not silently alter tested `compose_domains` behavior.

The `--print-domains` early exit is at lines 56-59; both edited regions (DNS lines 108-120, SSH-comment lines 123-132) are below it, so `compose_domains` and the inspection path are untouched. The test file `test/cc-isolated-functions.bats` contains exactly 52 `@test` cases (`rg -c '^@test'` → 52), matching the doc's count.

```bash
# devcontainer-config/init-firewall.sh:56-59
if [ "${1:-}" = "--print-domains" ]; then
  compose_domains
  exit 0
fi
```

The "52 tests unaffected" claim is accurate on both the count and the not-in-the-tested-path reasoning (paraphrased — no quote available because the count comes from a `rg -c` over the bats file, not a single source line).

**Evidence:** `devcontainer-config/init-firewall.sh:56-59`, `devcontainer-config/init-firewall.sh:108-132`, `test/cc-isolated-functions.bats`

---

## Claims Requiring Attention

### Incorrect
- **Claim 3** (`devcontainer-config/init-firewall.sh:104-107,117`): DNS does not fail open when no resolver parses. Under `set -euo pipefail`, the `grep` in the `dns_resolvers=$(…)` command substitution exits 1 on zero matches, pipefail propagates it, and `set -e` aborts the script at line 109 — before the `else` blanket-accept branch and before the DROP policy. It fails closed by aborting session start, the opposite of the documented behavior. Fix options: append `|| true` to the substitution (e.g. `dns_resolvers="$(… | sort -u || true)"`), or split the parse off the pipefail path, so the `else` branch is actually reachable.
- **Claim 8** (`docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:82-86`): the review doc repeats the same fail-open/"can never brick" assurance; it is incorrect for the identical reason and should be corrected once the code is fixed (or reworded to state the current abort-on-no-resolver behavior).

### Stale
- None.

### Mostly Accurate
- None.

### Unverifiable
- None. (Claim 4 carries one external dependency — that GitHub's SSH IPs fall within the runtime `.git` meta ranges — but the in-repo mechanism it documents is fully verified; it is recorded as Verified with that dependency noted, not Unverifiable.)

---

## Goal-Alignment Note

The stated goal of commit c44c33a is to harden the devcontainer egress firewall by (1) removing the blanket outbound-SSH accept and (2) scoping outbound DNS to configured resolvers. The fact-check confirms goal (1) is met and correctly documented (Claim 4), and goal (2) is met for the normal case where resolvers parse (Claim 2). The mechanism claims the hardening relies on — IP/dst matching, unconditional GitHub CIDRs, port-agnostic accept, established-return — are all accurate (Claims 1, 5, 6, 7, 9).

The one material misalignment is the DNS **fail-open** safety property (Claims 3 and 8): the comment and the companion review both promise that an unparseable `/etc/resolv.conf` degrades to unscoped DNS so session start "can never brick," but under the script's own `set -euo pipefail` the no-resolver case aborts before the fallback runs — producing exactly the brick the design cites (the statsig NXDOMAIN incident) as the thing to avoid. This is a documentation-vs-behavior gap in a safety fallback, not a weakening of the intended hardening: when resolvers exist (the overwhelming common case) the scoping works as claimed. It is worth surfacing to the security/robustness critics because it converts a claimed availability guarantee into an availability hazard on malformed resolver config. No fabricated symbols or APIs were found; the hallucination-pattern log needs no new entry.
