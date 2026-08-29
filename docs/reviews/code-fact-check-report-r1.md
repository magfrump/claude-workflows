# Code Fact-Check Report

Commit: c44c33a

**Repository:** /workspace (branch `harden/cc-isolated-egress`)
**Scope:** commit c44c33a — `devcontainer-config/init-firewall.sh` (code) and `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md` (review artifact, factual claims about the firewall mechanism)
**Checked:** 2026-08-29
**Total claims checked:** 11
**Summary:** 9 verified, 0 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) was read before checking. The two logged patterns both concern fabricated corpus/denominator statistics in the CRB benchmark; neither resembles any claim in this firewall change. No claim below matches a logged pattern.

---

## Claim 1: "Outbound DNS scoped to configured resolvers from /etc/resolv.conf, not 0.0.0.0/0"

**Location:** `devcontainer-config/init-firewall.sh:94-100`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** A maintainer reasoning about whether a compromised session can point a UDP socket at an attacker-controlled nameserver; the comment is the security rationale for the per-resolver scoping.

The `if` branch parses IPv4 nameservers and adds a `-d "$ns"` scoped ACCEPT for each, rather than a blanket `--dport 53` accept:

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

When at least one IPv4 nameserver parses, the emitted rules are destination-scoped (`-d "$ns"`), so a socket aimed at `attacker_ip:53` is not matched by these ACCEPTs and falls through to the final REJECT (`init-firewall.sh:222`). The scoping claim holds for the non-degenerate case.

**Evidence:** `devcontainer-config/init-firewall.sh:108-115`, `devcontainer-config/init-firewall.sh:222`

---

## Claim 2: "Fail OPEN if none parse" — the else branch re-adds a blanket DNS accept when no resolver parses

**Location:** `devcontainer-config/init-firewall.sh:106-107, 116-120`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** An operator relying on the stated invariant "bricking DNS bricks session start, and this repo's boundary changes never trade availability for a partial hardening" — i.e. the promise that a missing/empty resolver list degrades to open DNS rather than aborting.

The comment and diff assert the degenerate case fails open by re-adding an unscoped accept:

```bash
# devcontainer-config/init-firewall.sh:116-120
else
  echo "WARNING: no IPv4 nameserver in /etc/resolv.conf — allowing DNS to any host (unscoped)" >&2
  iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
  iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
fi
```

This `else` branch is **unreachable in exactly the cases it is written for.** The script runs under `set -euo pipefail`:

```bash
# devcontainer-config/init-firewall.sh:20
set -euo pipefail  # Exit on error, undefined vars, and pipeline failures
```

The resolver list is built by a pipeline inside a command substitution assigned to a variable (`init-firewall.sh:108-109`, quoted in Claim 1). To reach the `else` branch, `dns_resolvers` must be empty — which requires `grep -E` to find zero IPv4 matches, so `grep` exits 1. With `pipefail` set, a nonzero exit from any pipeline stage makes the whole pipeline's status nonzero; a bare `var="$(pipeline)"` assignment then carries that nonzero status, and `set -e` aborts the script **at line 108** before the `if`/`else` is ever evaluated. The same happens if `/etc/resolv.conf` is absent (`awk` exits nonzero; `2>/dev/null` hides the message but not the exit code).

I confirmed this empirically with the exact construct:

```
$ bash -c 'set -euo pipefail; x="$(printf "" | grep -E "foo" | sort -u)"; echo REACHED'
$ echo $?
1                     # "REACHED" never prints — abort at the assignment
$ bash -c 'set -euo pipefail; x="$(awk "..." /nonexistent 2>/dev/null | grep -E "[0-9]" | sort -u)"; echo REACHED'
1                     # same — abort at the assignment
```

So the actual behavior when no IPv4 resolver parses is **not** "allow DNS to any host"; it is an abort of the whole script. Worse, that abort lands *after* the iptables flush (`init-firewall.sh:74-80`) but *before* the default DROP policies are set (`init-firewall.sh:210-212`), where iptables default policy is still `ACCEPT` — so the failure mode is a fully-open firewall plus a broken session start, the opposite of the controlled "fail open (DNS only)" the comment claims. The claim "Fail OPEN if none parse" and the WARNING branch describe a code path that does not execute.

**Evidence:** `devcontainer-config/init-firewall.sh:20`, `devcontainer-config/init-firewall.sh:108-120`, `devcontainer-config/init-firewall.sh:74-80`, `devcontainer-config/init-firewall.sh:210-212`

---

## Claim 3: "The per-resolver DNS ACCEPTs are added before the default `-P OUTPUT DROP` policy so they take effect"

**Location:** `devcontainer-config/init-firewall.sh:108-120` relative to `:212`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** A reader verifying the rules are actually in force and not shadowed by the DROP policy or the trailing REJECT.

The DNS `-A OUTPUT` rules are appended at lines 113-114 / 118-119 (quoted in Claims 1 and 2), which precede the policy line:

```bash
# devcontainer-config/init-firewall.sh:210-212
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP
```

Because iptables evaluates chain rules in append order and a policy applies only when no rule matches, the DNS ACCEPTs (first entries in `OUTPUT`) are reached before the final `REJECT` at `:222` and before the `DROP` policy takes over. Filter rules persist across a policy change, so adding them while the policy is still the default `ACCEPT` does not affect their later effect. Ordering claim holds.

**Evidence:** `devcontainer-config/init-firewall.sh:113-114`, `devcontainer-config/init-firewall.sh:210-212`, `devcontainer-config/init-firewall.sh:219-222`

---

## Claim 4: "SSH to allowlisted hosts (all of GitHub) still works — dst IPs are in the allowed-domains ipset, matched by the OUTPUT accept regardless of port"

**Location:** `devcontainer-config/init-firewall.sh:123-132`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** A maintainer who removed the blanket `--dport 22` accept and needs assurance that `git+ssh` to GitHub is not collateral damage.

The trailing OUTPUT accept matches on destination-set membership only, with no port qualifier:

```bash
# devcontainer-config/init-firewall.sh:218-219
# Then allow only specific outbound traffic to allowed domains
iptables -A OUTPUT -m set --match-set allowed-domains dst -j ACCEPT
```

GitHub's published ranges are unconditionally added to that ipset:

```bash
# devcontainer-config/init-firewall.sh:159-163
    echo "Adding GitHub range $cidr"
    ...
    ipset add -exist allowed-domains "$cidr"
```

fed from `.web + .api + .git` of `api.github.com/meta`:

```bash
# devcontainer-config/init-firewall.sh:164
done < <(echo "$gh_ranges" | jq -r '(.web + .api + .git)[]' | aggregate -q)
```

Tracing an outbound SSH SYN to a GitHub IP: OUTPUT policy is `DROP`, but the packet's destination is in `allowed-domains`, so the `-m set --match-set allowed-domains dst` rule accepts it *irrespective of TCP dport 22*. The mechanism the comment describes is exactly what the code does. One residual: "all of GitHub" depends on GitHub's SSH host IPs being present in the `.web/.api/.git` union of the meta feed — `github.com`'s git/SSH endpoints are published in that feed, so this is accurate in practice (paraphrased — no quote available because it depends on the live `api.github.com/meta` response, which is fetched at runtime and not in the repo).

**Evidence:** `devcontainer-config/init-firewall.sh:140-164`, `devcontainer-config/init-firewall.sh:218-219`

---

## Claim 5: "The ESTABLISHED,RELATED accept covers the return path"

**Location:** `devcontainer-config/init-firewall.sh:128-129`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** A reader confirming that removing the explicit inbound-SSH-response rule (`-A INPUT ... --sport 22 --state ESTABLISHED`) does not break return traffic.

Both directions have a stateful ESTABLISHED,RELATED accept:

```bash
# devcontainer-config/init-firewall.sh:214-216
# First allow established connections for already approved traffic
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
```

Once the outbound SYN to a GitHub IP is accepted (Claim 4), the connection is tracked, and the generic INPUT ESTABLISHED,RELATED rule admits the responses — no port-specific inbound rule is needed. The removed `-A INPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT` was a subset of this rule. Claim holds.

**Evidence:** `devcontainer-config/init-firewall.sh:214-216`

---

## Claim 6: "GitHub's IP ranges are added separately from api.github.com/meta … added for every project regardless of profile"

**Location:** `devcontainer-config/init-firewall.sh:2-11` (header comment) and behavior at `:140-164`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** A reader distinguishing the composed profile allowlist (`base` + profiles) from the always-on GitHub CIDR block.

`base.txt` states GitHub is not listed there but added from meta:

```
# devcontainer-config/egress/base.txt (lines 2-3)
# GitHub's IP ranges are added separately from api.github.com/meta, not listed here.
```

and the GitHub-CIDR block in `init-firewall.sh:140-164` runs unconditionally in the firewall path — it is not guarded by any profile check (the only profile-driven code is `compose_domains`, `init-firewall.sh:30-51`, which composes the *domain* allowlist and does not gate the GitHub fetch). So GitHub CIDRs are added for every project regardless of `CC_EGRESS_PROFILE`. Claim holds.

**Evidence:** `devcontainer-config/egress/base.txt:2-3`, `devcontainer-config/init-firewall.sh:140-164`, `devcontainer-config/init-firewall.sh:30-51`

---

## Claim 7 (companion doc): "the allowlist matches on destination IP, not SNI/Host … per-IP for all ports"

**Location:** `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:24-27`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** A reader of the security review relying on the "load-bearing weakness" framing that drives the CDN/GFE-overreach findings.

The doc claims the match is destination-IP, all-ports. The code's accept rule is `-m set --match-set allowed-domains dst` (`init-firewall.sh:219`, quoted in Claim 4) with no `--dport`/`--sport` and no L7/SNI inspection — pure destination-set membership. The ipset is `hash:net`:

```bash
# devcontainer-config/init-firewall.sh:138
ipset create allowed-domains hash:net
```

so entries are IPs/CIDRs, confirming IP-only, all-ports matching. Doc claim holds.

**Evidence:** `devcontainer-config/init-firewall.sh:138`, `devcontainer-config/init-firewall.sh:219`

---

## Claim 8 (companion doc): "GitHub CIDRs … added for every project regardless of profile"

**Location:** `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:16-18`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** A reader assessing the "GitHub is the single widest always-on exfil surface" finding, which depends on GitHub being reachable even in a `base`-only project.

Same evidence as Claim 6: the GitHub-CIDR block (`init-firewall.sh:140-164`) is unconditional and not profile-gated. Doc claim holds.

**Evidence:** `devcontainer-config/init-firewall.sh:140-164`

---

## Claim 9 (companion doc): "host.docker.internal … dst-match opens every host port to the container, not just the model server"

**Location:** `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:47`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** A reader weighing whether granting the `llm` profile exposes more than local Ollama.

`host.docker.internal` is a domain in the `llm` profile, so it is resolved and its IP pinned into `allowed-domains` by the generic domain loop:

```bash
# devcontainer-config/init-firewall.sh:167-169
for domain in $ALLOWED_DOMAINS; do
    echo "Resolving $domain..."
    ips=$(dig +noall +answer A "$domain" | awk '$4 == "A" {print $5}')
```

Once that IP is in the ipset, the `-m set --match-set allowed-domains dst` accept (Claim 4/7) admits *any* TCP/UDP port to it — there is no per-port restriction. The `llm.txt` profile documents exactly this ("the allowlist matches destination IP only, so this opens EVERY host port to the container"). Doc claim holds.

**Evidence:** `devcontainer-config/init-firewall.sh:167-192`, `devcontainer-config/init-firewall.sh:219`, `devcontainer-config/egress/llm.txt` (host.docker.internal SCOPE CAVEAT block)

---

## Claim 10 (companion doc): "Scoped outbound DNS to /etc/resolv.conf resolvers, failing open (with a warning) if none parse so session start can never brick"

**Location:** `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:84-86, 126`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** A reviewer trusting the review's assurance that the DNS hardening cannot brick session start — the explicit availability guarantee the change is sold on.

The doc restates the fail-open guarantee: "failing open (with a warning) if none parse so session start can never brick." This is the same claim refuted in Claim 2: under `set -euo pipefail` the `dns_resolvers` assignment (`init-firewall.sh:108-109`) aborts the script whenever the pipeline yields no match, so the fail-open `else` branch never runs and session start **would** brick (and, because the abort is post-flush/pre-DROP, leaves the firewall open). The review's "can never brick" is contradicted by the code it describes.

**Evidence:** `devcontainer-config/init-firewall.sh:20`, `devcontainer-config/init-firewall.sh:108-120`, `devcontainer-config/init-firewall.sh:74-80`, `devcontainer-config/init-firewall.sh:210-212`

---

## Claim 11 (companion doc): "Both edits are inside the firewall-application path (after the --print-domains early exit) … the 52 test/cc-isolated-functions.bats tests are unaffected"

**Location:** `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:126-131`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** A reviewer checking that the change did not silently alter the tested `compose_domains` surface.

The `--print-domains` early exit is at `init-firewall.sh:56-59`:

```bash
# devcontainer-config/init-firewall.sh:56-59
if [ "${1:-}" = "--print-domains" ]; then
  compose_domains
  exit 0
fi
```

Both edited regions — the DNS block (`:108-120`) and the SSH comment/removal (`:123-132`) — sit well after line 59, so the `--print-domains` path that the bats tests exercise never reaches them. The stated test count is exact:

```
$ grep -c '^@test' test/cc-isolated-functions.bats
52
```

Both the "after the early exit" and "52 tests" claims hold.

**Evidence:** `devcontainer-config/init-firewall.sh:56-59`, `devcontainer-config/init-firewall.sh:108-132`, `test/cc-isolated-functions.bats` (52 `@test` blocks)

---

## Claims Requiring Attention

### Incorrect
- **Claim 2** (`devcontainer-config/init-firewall.sh:106-120`): The DNS "fail OPEN if none parse" else-branch is unreachable — under `set -euo pipefail` the `dns_resolvers="$(… | grep … )"` assignment aborts the script (grep exits 1 on zero matches; pipefail propagates) before the `if`/`else` runs. Instead of allowing unscoped DNS, the no-resolver case aborts mid-configuration, after the flush but before the DROP policies, leaving the firewall fully open and session start broken. Fix: capture the resolver list without letting a zero-match grep abort the script (e.g. append `|| true` to the substitution, or split parse from filter so an empty result is a normal empty string).
- **Claim 10** (`docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:84-86,126`): The review's "failing open … so session start can never brick" repeats the same false guarantee; correct it to match whatever the code is fixed to do (as written, the code fails closed-by-abort, not open).

### Stale
- None.

### Mostly Accurate
- None.

### Unverifiable
- None. (Claim 4's "all of GitHub" sub-point depends on the live `api.github.com/meta` feed, but the accept *mechanism* is fully verified against the code; the practical reachability of GitHub SSH via those CIDRs is confirmed by the script's own `curl https://api.github.com/zen` verification at `:234`.)

---

## Goal-Alignment Note

The change's two stated goals are (1) remove the blanket outbound-SSH accept without breaking GitHub SSH, and (2) scope outbound DNS to configured resolvers. Goal 1 is fully substantiated: the dst-match ipset rule (any port) plus the always-on GitHub CIDRs plus the ESTABLISHED,RELATED return path make GitHub SSH continue to work with no blanket `--dport 22` rule (Claims 4-6, 8). Goal 2 is substantiated **only on its happy path** (Claim 1): when at least one IPv4 resolver parses, DNS is genuinely scoped. The failure path that both the code comment and the security review advertise as the safety net — "fail open if none parse, so session start can never brick" — does not exist as described (Claims 2, 10): `set -euo pipefail` turns the no-resolver case into a mid-configuration abort that leaves the firewall open and breaks startup, which is both a correctness bug and a direct contradiction of the availability guarantee the review uses to justify the design. This is the one place where the documentation would actively mislead a reader (or a future security reviewer) about the boundary's behavior, so it is the finding to action before the change ships. All other checked claims — the IP-not-SNI matching weakness, the always-on GitHub surface, the host.docker.internal all-ports exposure, and the "edits after the --print-domains exit, 52 tests unaffected" scoping note — match the code exactly.
