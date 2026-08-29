# Code Fact-Check Report

**Commit:** 6edaa21

**Repository:** `/workspace` (branch `harden/cc-isolated-egress`)
**Scope:** `git diff main...HEAD` — full branch changeset (c44c33a, 6edaa21). Code file: `devcontainer-config/init-firewall.sh`; doc artifacts: `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md`; commit messages for both commits. Supporting files consulted: `devcontainer-config/Dockerfile`, `devcontainer-config/devcontainer.json`, `test/cc-isolated-functions.bats`.
**Checked:** 2026-08-29
**Total claims checked:** 15
**Summary:** 10 verified, 2 mostly accurate, 0 stale, 2 incorrect, 1 unverifiable

**Method note.** Where a claim turns on shell semantics (`set -euo pipefail` propagation, `||` guards, ERE behaviour under double quotes) I executed it in a scratch bash shell and report the observed result. Where a claim turns on netfilter/iptables runtime behaviour I have **no root and no iptables in this environment**; those are reasoned from the script text plus documented netfilter ordering and are tagged as such with reduced confidence.

**Prior-pattern check.** Compared every claim against `docs/reviews/hallucination-patterns.md` (2 logged entries, both "specific measured value quoted from a checked-in artifact set that does not contain it"). Claim 13 (`52 bats`, `shellcheck clean`) is the only claim in this scope of that shape; it was recomputed and matches. No claim in this scope resembles either logged pattern.

---

## Claim 1: "Selectively restore ONLY internal Docker DNS resolution"

**Location:** `devcontainer-config/init-firewall.sh:82`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** `security-reviewer` — the whole DNS-scoping argument assumes nothing wider than the Docker embedded-resolver NAT survives the flush; a wider restore would reopen paths the filter rules are assumed to gate.

The restored set is exactly the nat-table lines captured before the flush that mention the embedded resolver address:

```bash
# devcontainer-config/init-firewall.sh:71
DOCKER_DNS_RULES=$(iptables-save -t nat | grep "127\.0\.0\.11" || true)
```

and they are replayed verbatim into the nat table only:

```bash
# devcontainer-config/init-firewall.sh:85-87
iptables -t nat -N DOCKER_OUTPUT 2>/dev/null || true
iptables -t nat -N DOCKER_POSTROUTING 2>/dev/null || true
echo "$DOCKER_DNS_RULES" | xargs -L 1 iptables -t nat
```

The explicit `-N` for the two chains is consistent with the grep capturing only `-A` rule lines and not `iptables-save`'s `:CHAIN - [0:0]` declaration lines, which contain no `127.0.0.11` (paraphrased — no quote available because the claim is about the *absence* of matching text in `iptables-save` output, which is runtime data not present in the repo). Confidence is Medium rather than High because the exact set of restored lines depends on the running Docker daemon's nat table, which I cannot dump here.

**Evidence:** `devcontainer-config/init-firewall.sh:71`, `devcontainer-config/init-firewall.sh:83-90`

---

## Claim 2: "First allow DNS and localhost before any restrictions"

**Location:** `devcontainer-config/init-firewall.sh:92`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** future maintainer — sets the reader's mental model of rule ordering for the whole block below it.

The DNS and loopback accepts are appended at lines 134-135/147-148 and 163-164:

```bash
# devcontainer-config/init-firewall.sh:163-164
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
```

and every restriction (the default policies and the terminal REJECT) is appended strictly later in the file:

```bash
# devcontainer-config/init-firewall.sh:239-241
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP
```

```bash
# devcontainer-config/init-firewall.sh:251
iptables -A OUTPUT -j REJECT --reject-with icmp-admin-prohibited
```

**Evidence:** `devcontainer-config/init-firewall.sh:92`, `devcontainer-config/init-firewall.sh:134-135`, `devcontainer-config/init-firewall.sh:163-164`, `devcontainer-config/init-firewall.sh:239-241`, `devcontainer-config/init-firewall.sh:251`

---

## Claim 3: "Outbound DNS is scoped to the container's CONFIGURED resolvers (from /etc/resolv.conf), not to 0.0.0.0/0"

**Location:** `devcontainer-config/init-firewall.sh:94-100`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** `security-reviewer` — this is the headline defense-in-depth claim of commit c44c33a; the critic must be able to trust that no blanket port-53 accept survives anywhere in the script.

Every port-53 OUTPUT accept in the file carries a `-d` destination. The scoped branch:

```bash
# devcontainer-config/init-firewall.sh:134-135
iptables -A OUTPUT -p udp -d "$ns" --dport 53 -j ACCEPT || echo "WARNING: could not add UDP DNS rule for $ns" >&2
iptables -A OUTPUT -p tcp -d "$ns" --dport 53 -j ACCEPT || echo "WARNING: could not add TCP DNS rule for $ns" >&2
```

and the fallback branch:

```bash
# devcontainer-config/init-firewall.sh:147-148
iptables -A OUTPUT -p udp -d 127.0.0.11 --dport 53 -j ACCEPT || echo "WARNING: could not add UDP DNS fallback rule" >&2
iptables -A OUTPUT -p tcp -d 127.0.0.11 --dport 53 -j ACCEPT || echo "WARNING: could not add TCP DNS fallback rule" >&2
```

`rg -n -e '--dport 53' devcontainer-config/init-firewall.sh` returns exactly five lines: the four rules above plus the prose mention in the comment at `:95` — there is no unscoped `--dport 53 -j ACCEPT` anywhere in the file (paraphrased — no quote available because the claim covers the absence of code; the grep's only non-quoted hit is comment prose, not a rule). The only unscoped port-53 rule is on the INPUT chain for responses:

```bash
# devcontainer-config/init-firewall.sh:151
iptables -A INPUT -p udp --sport 53 -j ACCEPT
```

which is an inbound accept and does not grant an outbound path.

Caveat on the *effect* claim in the same comment ("the agent must go through the embedded/host resolver"): see Claim 6 — in the default Docker configuration the loopback accept at line 164 makes the scoped rules redundant, but that does not weaken this claim, because the security-relevant change is the *removal* of the arbitrary-destination accept, which is real in every configuration.

**Evidence:** `devcontainer-config/init-firewall.sh:94-103`, `devcontainer-config/init-firewall.sh:134-135`, `devcontainer-config/init-firewall.sh:147-148`, `devcontainer-config/init-firewall.sh:151`

---

## Claim 4: "`node` (which can re-run this script via its NOPASSWD sudo, see Dockerfile) cannot write it [/etc/resolv.conf]"

**Location:** `devcontainer-config/init-firewall.sh:105-111`
**Type:** Invariant / Architectural
**Verdict:** Mostly accurate
**Confidence:** Medium
**Legibility-target:** `security-reviewer` — the entire DNS-scoping control inverts if this trust assumption is false, so the critic needs to know which half is code-verifiable and which is environmental.

The re-run half is verified in the image definition:

```dockerfile
# devcontainer-config/Dockerfile:398
  echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall && \
```

and that path is what actually runs at start:

```jsonc
// devcontainer-config/devcontainer.json:93
  "postStartCommand": "sudo /usr/local/bin/init-firewall.sh && /usr/local/bin/link-claude-home.sh",
```

The "cannot write `/etc/resolv.conf`" half is **not established anywhere in this repo**: `rg -n 'resolv\.conf' devcontainer-config/` returns no hits outside `init-firewall.sh` itself — there is no `chown`/`chmod` on `/etc/resolv.conf` in the Dockerfile and no mount or `--dns` setting in `devcontainer.json` (paraphrased — no quote available because the claim covers the absence of code; the grep returns zero matching lines). It rests on Docker's runtime behaviour of writing a root-owned `/etc/resolv.conf`, which is true by default but is an environmental property, not one the repo enforces. The comment's own wording ("Keep resolv.conf root-owned and not agent-writable, or this control inverts") is the accurate framing; the flat assertion "cannot write it" reads as a guarantee the codebase does not provide.

**Evidence:** `devcontainer-config/init-firewall.sh:105-111`, `devcontainer-config/Dockerfile:383-384`, `devcontainer-config/Dockerfile:398-399`, `devcontainer-config/devcontainer.json:93`

---

## Claim 5: "The octet alternation is a real 0–255 match, not a `[0-9]{1,3}` shape check"

**Location:** `devcontainer-config/init-firewall.sh:113-118` (pattern at `:125-127`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** `security-reviewer` — fix A2 from the pass-1 loop; the critic needs the range check to actually hold, including through the double-quoted interpolation.

The pattern and its use:

```bash
# devcontainer-config/init-firewall.sh:125-127
octet='(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])'
dns_resolvers="$(awk '/^[[:space:]]*nameserver/ {print $2}' /etc/resolv.conf 2>/dev/null \
  | grep -E "^${octet}(\.${octet}){3}$" | sort -u || true)"
```

I ran this pattern (executed, not reasoned) against a fixture file. The double-quoting concerns both resolve correctly. The interpolated pattern expands to exactly:

```
^(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}$
```

— the trailing `$` before the closing double quote stays literal (bash does not expand `$` when the next character is `"`), so it functions as the ERE end-of-line anchor; and `\.` survives double-quoting (backslash-dot is not one of bash's escapable sequences inside double quotes, so the backslash is passed through), so it remains a literal-dot match rather than an any-character match.

Observed match results for the requested test inputs:

| Input | Result |
|---|---|
| `0.0.0.0` | accepted |
| `255.255.255.255` | accepted |
| `127.0.0.11` | accepted |
| `8.8.8.8`, `192.168.1.1`, `10.0.0.1`, `25.25.25.25`, `199.99.99.99`, `249.1.1.1`, `250.1.1.1` | accepted |
| `256.1.1.1` | rejected |
| `999.999.999.999` | rejected |
| `260.1.1.1`, `300.1.1.1` | rejected |
| `1.2.3` | rejected |
| `01.2.3.4` | rejected |
| `1.2.3.4 ` (trailing space) | rejected |
| ` 1.2.3.4` (leading space) | rejected |
| `1.2.3.4.5` | rejected |
| empty line | rejected |

Every valid dotted quad in the sample is accepted and every out-of-range or malformed input is rejected. The claim holds as written.

**Evidence:** `devcontainer-config/init-firewall.sh:113-118`, `devcontainer-config/init-firewall.sh:125-127`

---

## Claim 6: "which iptables then treats as a hostname, fails to resolve, and exits non-zero — aborting the script under `set -e` AFTER the flush but BEFORE the DROP policy, i.e. brick-OPEN"

**Location:** `devcontainer-config/init-firewall.sh:114-118`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Legibility-target:** `security-reviewer` — this is the stated *motivation* for fix A2; if the premise is wrong the fix is still harmless, but the threat model attached to it would be wrong.

The structural half is verifiable and holds — see Claim 12 for the flush/DROP ordering. The iptables half is not: I have no root and no `iptables` binary in this environment, so I cannot execute `iptables -A OUTPUT -d 999.999.999.999 --dport 53 -j ACCEPT` and observe the exit status (paraphrased — no quote available because the claim describes the runtime behaviour of an external binary that is not present in this environment). Verifying it would require a privileged container with `iptables` where the malformed value can be passed directly and `$?` inspected.

Note that with fix A2 shipped, this path is doubly guarded: the regex rejects the value before it reaches `iptables` (Claim 5), and the `|| echo` guard would absorb a non-zero exit if it did (Claim 8). The premise being unverified does not affect the safety of the shipped code.

**Evidence:** `devcontainer-config/init-firewall.sh:114-118`, `devcontainer-config/init-firewall.sh:125-127`, `devcontainer-config/init-firewall.sh:134-135`

---

## Claim 7: "`|| true` is load-bearing: … grep exits 1 when it matches zero resolvers — which would abort the script HERE (after the flush, before the DROP policy) … Swallowing the status makes an empty result reachable."

**Location:** `devcontainer-config/init-firewall.sh:120-124`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** `security-reviewer` and future maintainer — this is fix R1, the behavioral red from pass 1; both the defect and the fix must be independently reproducible.

The guarded assignment:

```bash
# devcontainer-config/init-firewall.sh:126-127
dns_resolvers="$(awk '/^[[:space:]]*nameserver/ {print $2}' /etc/resolv.conf 2>/dev/null \
  | grep -E "^${octet}(\.${octet}){3}$" | sort -u || true)"
```

I reproduced both directions empirically. With an IPv6-only fixture (`nameserver fe80::1` / `nameserver 2001:4860:4860::8888`) and `set -euo pipefail; IFS=$'\n\t'`:

- **With** `|| true`: the script survives, `dns_resolvers` is empty, and the `else` branch at `:137` is reached. Observed output: `SURVIVED, resolvers=[]` / `else-branch REACHED`, exit 0.
- **Without** `|| true` (same script, that one token removed): the script aborts at the assignment. Exit 1, no further output.

The mechanism is as the comment states: `||` binds to the whole pipeline (lower precedence than `|`), and although `sort -u` itself exits 0, `pipefail` promotes grep's exit-1 to the pipeline status — confirmed separately with `bash -c 'set -euo pipefail; echo hi | grep -q zzz | sort -u; echo reached'`, which exits 1 without printing `reached`.

The comment's characterisation of the pre-fix behaviour ("the exact wide-open brick the fail-open branch below exists to prevent") is consistent with Claim 12's ordering finding for a first run in a fresh container.

**Evidence:** `devcontainer-config/init-firewall.sh:120-127`, `devcontainer-config/init-firewall.sh:137-149`

---

## Claim 8: "`|| echo` (not a bare call): a failed add must not abort the script in the post-flush/pre-DROP wide-open window"

**Location:** `devcontainer-config/init-firewall.sh:131-135` (same construct at `:147-148`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** `security-reviewer` — fix A2's second half; the critic's "fails closed for that resolver, not open for everything" reasoning depends on this construct actually suppressing `set -e`.

The construct:

```bash
# devcontainer-config/init-firewall.sh:134
iptables -A OUTPUT -p udp -d "$ns" --dport 53 -j ACCEPT || echo "WARNING: could not add UDP DNS rule for $ns" >&2
```

Executed with a stub `iptables` that returns 1, under `set -euo pipefail; IFS=$'\n\t'`: the warning is printed to stderr, `$?` immediately after the compound command is **0**, and the script continues to completion (observed: `WARNING: could not add UDP DNS rule for 1.2.3.4` / `compound status was: 0` / `SCRIPT SURVIVED`, exit 0). The same script with a bare (unguarded) call to the failing stub exits 1 with no further output. A command-not-found variant (`nosuchcmd_xyz ... || echo "WARN" >&2`) also survives with exit 0, so the guard covers a missing binary as well as a non-zero exit.

Both halves of the claim hold: `set -e` is suppressed, and the compound command's exit status is 0 (which matters because it is the last statement in the `while` body and the last statement in the `else` branch — a non-zero status there would itself trip `set -e`).

**Evidence:** `devcontainer-config/init-firewall.sh:131-135`, `devcontainer-config/init-firewall.sh:147-148`

---

## Claim 9: "Scope the fallback to Docker's embedded resolver (127.0.0.11), which is the resolver in the overwhelming common case … so this preserves resolution for the standard Docker network without reopening arbitrary-host DNS"

**Location:** `devcontainer-config/init-firewall.sh:138-145`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** `security-reviewer` and future maintainer — the comment states an availability guarantee ("must not brick session start") for the degraded path; a reader trusting it would believe the fallback restores DNS in the case that triggers it, which it does not.

The branch's own entry condition contradicts its stated rationale. It is reached only when no IPv4 nameserver parses out of `/etc/resolv.conf`:

```bash
# devcontainer-config/init-firewall.sh:128
if [ -n "$dns_resolvers" ]; then
```

```bash
# devcontainer-config/init-firewall.sh:137-148
else
  # Fail OPEN but SCOPED, not wide: no parseable IPv4 resolver (IPv6-only resolv.conf,
  ...
  echo "WARNING: no IPv4 nameserver in /etc/resolv.conf — scoping DNS fallback to the Docker embedded resolver 127.0.0.11" >&2
  iptables -A OUTPUT -p udp -d 127.0.0.11 --dport 53 -j ACCEPT || echo "WARNING: could not add UDP DNS fallback rule" >&2
  iptables -A OUTPUT -p tcp -d 127.0.0.11 --dport 53 -j ACCEPT || echo "WARNING: could not add TCP DNS fallback rule" >&2
fi
```

`127.0.0.11` is a valid IPv4 dotted quad and is accepted by the octet regex (verified empirically under Claim 5). Therefore, in the "standard Docker network" case the comment invokes — where `/etc/resolv.conf` contains `nameserver 127.0.0.11` — `dns_resolvers` is non-empty and control takes the **`if`** branch, never this `else`. The two cases are mutually exclusive: the `else` branch is unreachable in exactly the configuration whose resolution it claims to preserve.

In the configurations that do reach it — the comment's own examples, an IPv6-only `resolv.conf` or an unreadable/unparseable file — `127.0.0.11` is by construction *not* the configured resolver, so the two rules it adds permit traffic to an address nothing will send DNS to. The fallback therefore preserves no IPv4 resolution at all.

The stated goal (not bricking session start) is nevertheless met in the IPv6-only case, but by an unrelated mechanism the comment mentions only parenthetically: IPv6 DNS is entirely unfiltered (Claim 11). In the unreadable-`resolv.conf` case, resolution is already broken independently of the firewall. So no availability regression is introduced — but the stated causal explanation is wrong.

The precise version would be: *no IPv4 resolver parsed, so there is nothing to scope to; add a 127.0.0.11 accept as a harmless best-effort and rely on the unfiltered IPv6 path (or the `-o lo` accept) for resolution.*

**Evidence:** `devcontainer-config/init-firewall.sh:126-128`, `devcontainer-config/init-firewall.sh:137-149`

---

## Claim 10: "127.0.0.11 … is already reachable via the `-o lo` accept below regardless"

**Location:** `devcontainer-config/init-firewall.sh:142-143`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** `security-reviewer` — determines whether the DNS-scoping change is load-bearing in the default Docker configuration or only in non-loopback-resolver setups; the critic should not overstate the fix's reach.

The referenced rule exists, unconditionally, and is not gated on anything:

```bash
# devcontainer-config/init-firewall.sh:164
iptables -A OUTPUT -o lo -j ACCEPT
```

Traffic to `127.0.0.11` is loopback-destined and is routed out the `lo` interface, so it matches `-o lo` regardless of protocol or port (paraphrased — no quote available because this is standard Linux loopback routing behaviour, not repo code, and I have no root/iptables here to demonstrate it). The claim as written is accurate.

**The redundancy consequence is real.** In the default Docker configuration (`nameserver 127.0.0.11`), the `if` branch emits `-d 127.0.0.11 --dport 53 -j ACCEPT` rules at `:134-135` — for a destination that line 164 already accepts unconditionally. The fallback rules at `:147-148` are redundant in the same way. So the *added accept rules* are no-ops in the common case.

This does **not** make the hardening theater, and the distinction matters for the security critic:

- What actually changed security posture is the **removal** of the previous blanket `--dport 53 -j ACCEPT` to `0.0.0.0/0`. That removal closes the direct `attacker_ip:53` socket path in *every* configuration, including the default one — the `-o lo` rule does not admit a non-loopback destination.
- What the *new rules* add is only relevant where the configured resolver is a non-loopback address (e.g. a `--dns 8.8.8.8` override or a host resolver on the bridge subnet); there they are what keeps DNS working.

So in the default Docker configuration the hardening is real (a channel was closed) even though the newly added rules are inert.

**Evidence:** `devcontainer-config/init-firewall.sh:134-135`, `devcontainer-config/init-firewall.sh:142-143`, `devcontainer-config/init-firewall.sh:147-148`, `devcontainer-config/init-firewall.sh:163-164`

---

## Claim 11: "this script has no ip6tables rules — a pre-existing gap this line neither creates nor worsens"

**Location:** `devcontainer-config/init-firewall.sh:144-145`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** `security-reviewer` — establishes that IPv6 egress is entirely outside this control, which the critic must carry into any residual-risk statement.

`rg -n 'ip6tables' devcontainer-config/init-firewall.sh` returns zero hits; the only matches for `ip6|IPv6` in the file are the three comment lines at `:138`, `:144` and `:145` (paraphrased — no quote available because the claim covers the absence of code, i.e. an empty grep result). Every firewall invocation in the file is `iptables` or `ipset`, both IPv4-only in this usage.

The implication for the IPv6 DNS path the comment waves at: because no `ip6tables` policy is ever set, the IPv6 filter table retains its default `ACCEPT` policy, so IPv6 DNS — and in fact **all IPv6 egress** — is unrestricted, not merely unscoped. That is strictly wider than "IPv6 DNS is unfiltered here anyway"; the comment understates the gap by scoping it to DNS. It is however accurate that this is pre-existing and that the fallback line neither creates nor worsens it. (The default-ACCEPT policy conclusion is reasoned from the absence of any `ip6tables -P` call — I cannot run `ip6tables -L` here.)

**Evidence:** `devcontainer-config/init-firewall.sh:138`, `devcontainer-config/init-firewall.sh:144-145`

---

## Claim 12: "after the flush but before the DROP policies, leaving the container wide open"

**Location:** `devcontainer-config/init-firewall.sh:189-191` (the same window is invoked at `:115-117`, `:122-123`, `:132-133`, `:139`)
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** `security-reviewer` — pass 1 recommended setting `-P OUTPUT DROP` before appending accepts and that recommendation was **not** applied; the critic needs to know the window still exists and how wide it is.

The flush:

```bash
# devcontainer-config/init-firewall.sh:74-80
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
ipset destroy allowed-domains 2>/dev/null || true
```

The DROP policies, 159 lines later:

```bash
# devcontainer-config/init-firewall.sh:238-241
# Set default policies to DROP first
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP
```

`iptables -F` flushes rules but does not reset chain policies (paraphrased — no quote available because this is documented `iptables(8)` behaviour, not repo code; I have no iptables here to demonstrate it). On a **fresh container** the filter-table policies are `ACCEPT` before the script runs, so after the flush the container is unfiltered — the "wide open" characterisation holds for the normal first-run path. Note the asymmetric case the comments do not mention: on a **re-run** (which `node` can trigger via its NOPASSWD sudo, Claim 4), the policies are already `DROP` from the prior run and `-F` leaves them there, so a re-run aborts fail-*closed*, not open.

**The window still exists for other commands — the pass-2 fixes only guarded the DNS block.** Inside lines 74-241 the script still contains six unguarded hard exits and several `set -e`-fatal calls:

```bash
# devcontainer-config/init-firewall.sh:172-175
if [ -z "$gh_ranges" ]; then
    echo "ERROR: Failed to fetch GitHub IP ranges"
    exit 1
fi
```

The remaining exits in the window are at `:179` (GitHub meta missing fields), `:186` (invalid CIDR), `:206` (`api.anthropic.com` unresolvable), `:215` (invalid IP from DNS) and `:228` (host IP undetectable). Beyond the explicit exits, `set -e`-fatal statements in the window include the `xargs` restore at `:87`, `ipset create` at `:167`, the `gh_ranges=$(curl -s ...)` and `ips=$(dig ... | awk ...)` assignments at `:171` and `:198` (both bare command substitutions under `pipefail`, the same construct that produced defect R1), the `ipset add -exist` calls at `:192`/`:220`, and the two `iptables -A` host-network rules at `:235-236`. Every one of those aborts leaves the container in the flushed, policy-ACCEPT state on a first run.

So the claim is accurate, and the pass-1 structural recommendation remains unimplemented — the DNS block is now guarded against contributing to the window, but the window itself is unchanged in extent.

**Evidence:** `devcontainer-config/init-firewall.sh:74-80`, `devcontainer-config/init-firewall.sh:87`, `devcontainer-config/init-firewall.sh:171-175`, `devcontainer-config/init-firewall.sh:177-180`, `devcontainer-config/init-firewall.sh:184-193`, `devcontainer-config/init-firewall.sh:198-221`, `devcontainer-config/init-firewall.sh:225-236`, `devcontainer-config/init-firewall.sh:238-241`

---

## Claim 13: "SSH to ALLOWLISTED hosts (all of GitHub, via the api.github.com/meta CIDRs added below) still works … the OUTPUT accept near the end matches on dst regardless of port, and the ESTABLISHED,RELATED accept covers the return path"

**Location:** `devcontainer-config/init-firewall.sh:152-161`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** `security-reviewer` — security-review finding #1 rests on "GitHub SSH still works via CIDR"; an overstated scope here could hide a real availability regression for non-`git`/`web`/`api` GitHub services.

The three mechanical sub-claims all check out. The dst-match is port-agnostic:

```bash
# devcontainer-config/init-firewall.sh:248
iptables -A OUTPUT -m set --match-set allowed-domains dst -j ACCEPT
```

The return path is covered:

```bash
# devcontainer-config/init-firewall.sh:244-245
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
```

And the absence of a blanket port-22 accept is confirmed: `rg -n 'dport 22' devcontainer-config/init-firewall.sh` returns a single hit, the comment prose at `:152` itself — no `iptables` rule mentions port 22 (paraphrased — no quote available because the claim covers the absence of code; the grep's only hit is the comment being checked).

The imprecision is "**all** of GitHub". The script ingests only three of the meta response's range keys:

```bash
# devcontainer-config/init-firewall.sh:193
done < <(echo "$gh_ranges" | jq -r '(.web + .api + .git)[]' | aggregate -q)
```

and the validity gate only checks those three:

```bash
# devcontainer-config/init-firewall.sh:177
if ! echo "$gh_ranges" | jq -e '.web and .api and .git' >/dev/null; then
```

`api.github.com/meta` publishes further range keys (`actions`, `packages`, `pages`, `codespaces`, `dependabot`, `copilot`, `importer`, …) that are not added (paraphrased — no quote available because the claim is about the shape of an external API response, not repo code; no cached meta fixture exists in this repo). For the SSH statement specifically the claim is fine — Git-over-SSH endpoints fall under the `git` key, which *is* added — so the sentence is directionally correct. The precise version would be "all of GitHub's `web`/`api`/`git` ranges" rather than "all of GitHub".

**Evidence:** `devcontainer-config/init-firewall.sh:152-161`, `devcontainer-config/init-firewall.sh:177`, `devcontainer-config/init-firewall.sh:193`, `devcontainer-config/init-firewall.sh:244-248`

---

## Claim 14: "All 52 bats pass; shellcheck clean" (commit 6edaa21 message)

**Location:** `devcontainer-config/init-firewall.sh` — commit message for `6edaa21`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** repo owner and `code-review` orchestrator — the verification evidence the review-fix loop's exit criterion rests on.

Both halves reproduce at `6edaa21`. `bats test/cc-isolated-functions.bats` emits the plan line `1..52`, 52 `ok` lines, and zero `not ok` lines (paraphrased — no quote available because this is command output, not a repo file; the counts were obtained by piping the run through `rg -c '^ok '` / `rg -c '^not ok'`). `shellcheck devcontainer-config/init-firewall.sh` exits 0 with no diagnostics.

This claim also does not match either logged entry in `docs/reviews/hallucination-patterns.md` — both logged patterns are "measured value quoted from a checked-in artifact set that does not contain it"; here the value is a live test count that recomputes correctly.

Immutability note: this claim lives in an already-created commit message and cannot be edited without a rewrite; it is recorded as verified, not as a fixable item.

**Evidence:** `devcontainer-config/init-firewall.sh`, `test/cc-isolated-functions.bats`

---

## Claim 15: "the fallback is scoped to Docker's embedded resolver `127.0.0.11` … so the degraded path does not re-grant the exact channel this fix removes, while still resolving in the standard Docker case (session start can never brick)"

**Location:** `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:84-88`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** `security-reviewer` and repo owner — this is the shipped-fix description in the review artifact that downstream readers will treat as the authoritative account of DNS behaviour; it inherits the defect in Claim 9.

The doc text:

```markdown
<!-- docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:84-88 -->
   `/etc/resolv.conf` (validated to real 0–255-octet IPv4 addresses). When no
   IPv4 resolver parses, the fallback is scoped to Docker's embedded resolver
   `127.0.0.11` — **not** a blanket `0.0.0.0/0` accept — so the degraded path
   does not re-grant the exact channel this fix removes, while still resolving in
   the standard Docker case (session start can never brick). This removes the
```

The first two assertions are accurate against the code: the octet validation is a real range check (Claim 5) and the fallback is `-d 127.0.0.11`-scoped rather than `0.0.0.0/0` (Claim 3). The clause "while still resolving in the standard Docker case" is wrong for the reason given in Claim 9 — the standard Docker case has `nameserver 127.0.0.11` in `/etc/resolv.conf`, which parses, so it takes the `if` branch at `:128` and never reaches the fallback. The fallback resolves nothing in any configuration that actually triggers it.

The related summary line at `:133-135` ("with a `127.0.0.11`-scoped (not `0.0.0.0/0`) fail-open fallback and non-fatal per-resolver adds") is accurate as a description of the mechanism and carries no availability claim, so it needs no change.

Unlike Claim 14, this is a working document, not an immutable commit message, and is editable.

**Evidence:** `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:82-94`, `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:133-135`, `devcontainer-config/init-firewall.sh:126-149`

---

## Claims Requiring Attention

### Incorrect
- **Claim 9** (`devcontainer-config/init-firewall.sh:138-145`): the fail-open comment says scoping the fallback to `127.0.0.11` "preserves resolution for the standard Docker network", but the standard Docker network has `nameserver 127.0.0.11` in `resolv.conf`, which parses and takes the `if` branch — the `else` branch is unreachable in exactly the case it claims to serve, and in the cases that do reach it (IPv6-only / unparseable resolv.conf) `127.0.0.11` is not the resolver, so it preserves nothing. No availability regression results (IPv6 is unfiltered), but the stated mechanism is wrong; reword to say the fallback is a harmless best-effort and that non-bricking comes from the unfiltered IPv6 path.
- **Claim 15** (`docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:84-88`): the review artifact repeats the same claim ("while still resolving in the standard Docker case"); same correction applies. Editable, unlike the commit message.

### Mostly Accurate
- **Claim 4** (`devcontainer-config/init-firewall.sh:105-111`): "`node` … cannot write it [resolv.conf]" — the NOPASSWD-sudo half is verified in `Dockerfile:398`, but nothing in this repo enforces resolv.conf ownership; it is a Docker runtime default. The comment's own closing sentence ("Keep resolv.conf root-owned … or this control inverts") is the accurate framing; tighten the flat assertion to match it.
- **Claim 13** (`devcontainer-config/init-firewall.sh:152-161`): "all of GitHub, via the api.github.com/meta CIDRs" — only `.web + .api + .git` are ingested (`:193`); other meta range keys (`actions`, `packages`, `pages`, `codespaces`, …) are not. Correct for the SSH point being made (SSH endpoints are in `.git`); tighten to "GitHub's web/api/git ranges".

### Unverifiable
- **Claim 6** (`devcontainer-config/init-firewall.sh:114-118`): "iptables treats `999.999.999.999` as a hostname, fails to resolve, and exits non-zero" — requires a privileged container with `iptables` to confirm; not reproducible here. The shipped code is safe regardless (regex rejects it, and the `|| echo` guard would absorb a failure).

### Noted but not a claim defect
- **Claim 10** (`devcontainer-config/init-firewall.sh:142-143`, `:134-135`, `:147-148`): the comment is accurate, but its consequence is worth surfacing — because `-o lo -j ACCEPT` (`:164`) already admits `127.0.0.11`, the newly added scoped DNS accepts are inert in the default Docker configuration. The hardening is still real there (the removed `0.0.0.0/0` port-53 accept is what closed the channel); the new rules are load-bearing only where the resolver is a non-loopback address.
- **Claim 12** (`devcontainer-config/init-firewall.sh:74-241`): pass 1's structural recommendation (set `-P OUTPUT DROP` before appending accepts) was not applied. The post-flush/pre-DROP window is unchanged in extent — six explicit `exit 1`s plus a dozen `set -e`-fatal statements still abort inside it on a first run.

---

## Goal-Alignment Note

The stated goal of the branch is to harden the devcontainer egress firewall by (1) removing the blanket outbound-SSH accept and (2) scoping outbound DNS to configured resolvers; commit 6edaa21 additionally claims to fix one behavioral red and two Medium security findings from pass 1. Against that:

- **Objective (1) remains met and accurately documented.** No `--dport 22` accept survives, and the port-agnostic `allowed-domains` dst-match plus ESTABLISHED,RELATED return path genuinely keep GitHub SSH working (Claim 13). The only imprecision is the phrase "all of GitHub" — only the `web`/`api`/`git` meta ranges are ingested.
- **The three pass-2 fixes are real and independently reproducible.** R1 (`|| true` on the command substitution) is confirmed by executing the branch with and without the token: the `else` branch is now reachable and was not before (Claim 7). A2's octet regex is a genuine 0–255 range check that survives the double-quoted interpolation intact, including the trailing `$` anchor and the `\.` literal-dot (Claim 5, executed against 20 inputs), and the `|| echo` guards do suppress `set -e` while returning status 0 (Claim 8, executed). A1's fallback is `-d 127.0.0.11`-scoped, not `0.0.0.0/0` (Claim 3). C1's trust-assumption comment is half-verified in the Dockerfile (Claim 4).
- **Objective (2)'s documentation still overstates the result, in a new place.** Pass 1 found the fail-open branch unreachable; 6edaa21 made it reachable but attached a rationale that does not hold — the branch cannot fire in the "standard Docker network" whose resolution it claims to preserve, and cannot preserve resolution in the cases where it does fire (Claims 9, 15). This is a documentation defect rather than a functional one: no availability regression follows, because IPv6 egress is entirely unfiltered (Claim 11) and `-o lo` covers loopback (Claim 10). But a reader acting on the comment would mis-model the degraded path.
- **Two structural facts the security critic should carry forward, neither of which is a claim defect.** First, the added DNS accepts are no-ops in the default Docker configuration because `-o lo -j ACCEPT` already admits `127.0.0.11`; the hardening there consists entirely of the *removal* of the old `0.0.0.0/0` port-53 accept, which is real (Claim 10). Second, pass 1's recommendation to set `-P OUTPUT DROP` before appending accepts was not applied — the post-flush/pre-DROP wide-open window persists at full width for the six explicit `exit 1`s and the dozen-odd `set -e`-fatal statements outside the DNS block (Claim 12).
- **Verification claims in the commit message check out.** 52/52 bats pass and shellcheck is clean at 6edaa21 (Claim 14). Both commit messages are already written and therefore immutable; the one editable doc inaccuracy is Claim 15 in the security-review artifact.

No fabricated symbols, APIs, or nonexistent behaviors were found — the two Incorrect verdicts are a mis-stated causal mechanism, not a fabrication — so no new entry is added to `docs/reviews/hallucination-patterns.md`.
