# Code Fact-Check Report

**Commit:** 6edaa21

**Repository:** `/workspace` (branch `harden/cc-isolated-egress`)
**Scope:** `git diff main...HEAD` — `devcontainer-config/init-firewall.sh` (whole file read), plus the claims in `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md` and the commit messages of `c44c33a` and `6edaa21`. Supporting reads: `devcontainer-config/Dockerfile`, `devcontainer-config/devcontainer.json`.
**Checked:** 2026-08-29
**Total claims checked:** 12
**Summary:** 6 verified, 3 mostly accurate, 0 stale, 2 incorrect, 1 unverifiable

**Pass note:** This is pass 2 of a review-fix loop. The DNS block was rewritten in `6edaa21`; none of pass 1's (`code-fact-check-report-r3.md`) conclusions about that block were carried over. Claim 2 below is a *new* defect in the *replacement* code, not a restatement of pass 1's finding — pass 1's finding (unreachable `else` branch) is confirmed fixed under Claim 5.

**Method note (empirical vs. reasoned):** Claims 1, 5, and the `|| true` half of the octet-comment claim were tested empirically in a scratch bash 5 shell (regex interpolation, `set -euo pipefail` propagation through command substitution, `|| echo` compound status, guarded-body `while read` loops). Claims 3, 4, and 7 concern iptables/netfilter runtime behavior; **no root and no iptables are available in this environment**, so those are reasoned from the rule text plus documented netfilter semantics and are marked with correspondingly lower confidence. Claim 8's test/lint half was run for real (`bats`, `shellcheck` are both installed).

**Hallucination-pattern log:** `docs/reviews/hallucination-patterns.md` read before checking. Its two logged patterns are both "a specific measured value quoted from a checked-in artifact set that does not contain it." The closest match in this scope is the "all 52 bats pass" count in Claim 8 — explicitly compared against the pattern and **not** a recurrence: the count is correct (see Claim 8).

---

## Claim 1: "The octet alternation is a real 0–255 match, not a `[0-9]{1,3}` shape check"

**Location:** `devcontainer-config/init-firewall.sh:113-118`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** `security-reviewer` — this is the A2 fix from `6edaa21`; the critic needs to know the malformed-entry-reaches-iptables path is genuinely closed, not shape-checked.

The comment claims a real range match and names the failure it prevents:

```bash
# devcontainer-config/init-firewall.sh:113-118
# The octet alternation is a real 0–255 match, not a `[0-9]{1,3}` shape check: a
# shape check passes `999.999.999.999`, which iptables then treats as a hostname,
# fails to resolve, and exits non-zero — aborting the script under `set -e` AFTER
# the flush but BEFORE the DROP policy, i.e. brick-OPEN. Rejecting out-of-range
# octets here (and the `|| echo` guard on each add below) keeps a malformed entry
# from ever reaching that window.
```

The pattern and its use site:

```bash
# devcontainer-config/init-firewall.sh:125-127
octet='(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])'
dns_resolvers="$(awk '/^[[:space:]]*nameserver/ {print $2}' /etc/resolv.conf 2>/dev/null \
  | grep -E "^${octet}(\.${octet}){3}$" | sort -u || true)"
```

**Empirically tested** (scratch bash 5, real `awk`/`grep -E`/`sort`, a synthetic `resolv.conf` containing every value the brief named). Two shell-quoting sub-questions were the point of the test and both resolve favorably:

- The trailing `$"` is a literal anchor. `$` immediately before a closing double quote is not a parameter/command expansion in bash, so it survives into the ERE. The interpolated pattern printed as `^(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}$` — anchors intact.
- `\.` survives double-quoting. `\.` is not one of the escapes bash processes inside double quotes (`$`, `` ` ``, `"`, `\`, newline), so the backslash reaches `grep` and `.` stays a literal dot rather than "any character." Confirmed in the same printed pattern.

Accept/reject results on the brief's test vector (paraphrased — no quote available because this is scratch-shell output, not repo source; the input list is `0.0.0.0`, `255.255.255.255`, `127.0.0.11`, `256.1.1.1`, `999.999.999.999`, `1.2.3`, `01.2.3.4`, `8.8.8.8 ` (trailing space), a leading-whitespace `   nameserver 1.1.1.1`, `fe80::1`, `1.2.3.4.5`): accepted exactly `0.0.0.0`, `1.1.1.1`, `127.0.0.11`, `255.255.255.255`, `8.8.8.8`; rejected `256.1.1.1`, `999.999.999.999`, `1.2.3`, `1.2.3.4.5`, `fe80::1`, and the leading-zero `01.2.3.4`. Trailing whitespace is stripped before `grep` sees it because `awk` field-splits on whitespace and prints only `$2`.

Two behaviors worth stating precisely, neither contradicting the comment: `01.2.3.4` is **rejected** (the alternation has no leading-zero branch) even though `iptables` would accept it, and the leading-whitespace `nameserver` line is matched by the `awk` guard `/^[[:space:]]*nameserver/` as written.

**Evidence:** `devcontainer-config/init-firewall.sh:20`, `devcontainer-config/init-firewall.sh:113-118`, `devcontainer-config/init-firewall.sh:125-127`

---

## Claim 2: "so this preserves resolution for the standard Docker network without reopening arbitrary-host DNS"

**Location:** `devcontainer-config/init-firewall.sh:141-145`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** `security-reviewer` and future maintainer — the comment advertises an availability guarantee ("must not brick session start") as the justification for the whole `else` branch. A reader trusting it would believe DNS survives the degraded case; in the case that actually triggers the branch, this rule contributes nothing.

The comment:

```bash
# devcontainer-config/init-firewall.sh:138-145
  # Fail OPEN but SCOPED, not wide: no parseable IPv4 resolver (IPv6-only resolv.conf,
  # a --dns override, or a parse failure) must not brick session start, but it must
  # also not re-grant the 0.0.0.0/0 DNS channel this change exists to remove. Scope
  # the fallback to Docker's embedded resolver (127.0.0.11), which is the resolver in
  # the overwhelming common case and is already reachable via the `-o lo` accept below
  # regardless — so this preserves resolution for the standard Docker network without
  # reopening arbitrary-host DNS. (IPv6 DNS is unfiltered here anyway: this script has
  # no ip6tables rules — a pre-existing gap this line neither creates nor worsens.)
```

The defect is a self-cancelling condition. The branch is guarded by `dns_resolvers` being empty:

```bash
# devcontainer-config/init-firewall.sh:128,137
if [ -n "$dns_resolvers" ]; then
...
else
```

`127.0.0.11` is a valid dotted quad and, per Claim 1's empirical test, is **accepted** by the octet regex. Therefore the `else` branch can only run when `127.0.0.11` is *not* a `nameserver` line in `/etc/resolv.conf` — i.e. by construction, the branch fires exactly when the container is *not* on "the standard Docker network" with the embedded resolver. In that state the fallback rule admits traffic to a resolver the container is not configured to use, and the sentence "this preserves resolution for the standard Docker network" describes a case that cannot coexist with the branch executing.

Walking the three triggers the comment itself names:

- **IPv6-only `resolv.conf`** — the fallback rule is a no-op. What actually preserves resolution here is the absence of any `ip6tables` rules (Claim 6), not this line. The comment's own parenthetical states that fact but attaches it as a footnote about a "pre-existing gap" rather than as the mechanism the availability guarantee is actually resting on.
- **A `--dns` override** — this trigger appears to be misattributed. A `--dns 8.8.8.8`-style override that reaches `/etc/resolv.conf` writes a parseable IPv4 nameserver, so the `if` branch takes it and the `else` never runs.
- **A parse failure / missing or unreadable `resolv.conf`** — the fallback is a no-op for the real resolver, so IPv4 DNS fails **closed** (the terminal `iptables -A OUTPUT -j REJECT --reject-with icmp-admin-prohibited` at line 251 catches it), except where the resolver happens to be on the host `/24` and is caught by `iptables -A OUTPUT -d "$HOST_NETWORK" -j ACCEPT` (line 236).

So the "fail OPEN" framing is accurate only in the weak sense that the *script* no longer aborts (that part is Claim 5, and it is fixed). It is not accurate in the sense the comment asserts — that resolution is preserved. Precise version: *the fallback keeps the script running and does not widen DNS, but it does not restore resolution in the scenarios that trigger it; IPv4 DNS fails closed there, and IPv6 DNS works only because the script writes no `ip6tables` rules.*

Note the scope of this verdict: the branch is not *harmful* — it grants nothing an attacker can use (see Claim 3) — and the security posture claim ("without reopening arbitrary-host DNS") is correct. Only the availability half is wrong.

**Evidence:** `devcontainer-config/init-firewall.sh:125-127`, `devcontainer-config/init-firewall.sh:128`, `devcontainer-config/init-firewall.sh:137-149`, `devcontainer-config/init-firewall.sh:236`, `devcontainer-config/init-firewall.sh:251`

---

## Claim 3: "127.0.0.11 ... is already reachable via the `-o lo` accept below regardless"

**Location:** `devcontainer-config/init-firewall.sh:142-143`
**Type:** Architectural / Behavioral
**Verdict:** Verified (the `-o lo` claim); the *implication* the comment leaves unstated is material — see below
**Confidence:** High for the rule's existence; Medium for the routing behavior (no iptables/root available to test)
**Legibility-target:** `security-reviewer` — this determines whether the DNS-scoping hardening is load-bearing or theater in the default Docker configuration. The critic should not credit the added ACCEPTs with closing a channel they do not touch.

The rule the comment points at exists, and it is below the DNS block:

```bash
# devcontainer-config/init-firewall.sh:163-164
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
```

Traffic to `127.0.0.11` egresses via `lo` (paraphrased — no quote available because this is a kernel routing property, not a snippet in this repo: the `local` route table contains `127.0.0.0/8 dev lo`, so any packet destined to a `127/8` address is routed out the loopback device and `-o lo` matches it in filter OUTPUT). So the comment's literal claim holds.

**The unstated implication is the important part, and it is real:** because `-o lo` accepts all loopback egress unconditionally, *both* the fallback rules at lines 147-148 *and* the scoped rules at lines 134-135 in the default Docker case (where `resolv.conf` holds `nameserver 127.0.0.11`) are redundant. They match a subset of what line 164 already accepts. Claim 4 shows they are redundant for a second, independent reason.

Consequence for the headline hardening claim, stated precisely: in the **default Docker configuration**, the added scoped-ACCEPT rules change nothing. What *does* change everything in that configuration is the **deletion** of the old blanket rule — the pre-patch `iptables -A OUTPUT -p udp --dport 53 -j ACCEPT` to `0.0.0.0/0` is gone (confirmed in `git diff main...HEAD`), so a socket aimed at `attacker_ip:53` now falls through to the terminal REJECT at line 251. That is a genuine closure, not theater. The scoped ACCEPTs are load-bearing only where the resolver is a **non-loopback** address outside the host `/24` — e.g. a default-bridge container whose `resolv.conf` was copied from a host using a public resolver. So: the security win is real; the *mechanism* the comments emphasize (adding scoped accepts) is not the mechanism delivering it in the common case (removing the blanket accept is).

**Evidence:** `devcontainer-config/init-firewall.sh:134-135`, `devcontainer-config/init-firewall.sh:147-148`, `devcontainer-config/init-firewall.sh:163-164`, `devcontainer-config/init-firewall.sh:236`, `devcontainer-config/init-firewall.sh:251`

---

## Claim 4: Docker embedded-DNS NAT interaction — does a filter rule `-d 127.0.0.11 --dport 53` still match?

**Location:** `devcontainer-config/init-firewall.sh:71`, `devcontainer-config/init-firewall.sh:83-90`, `devcontainer-config/init-firewall.sh:147-148`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium — netfilter traversal order is documented and stable, but I have no root/iptables here to observe the actual restored DNAT rules, and the exact rule text varies by Docker version
**Legibility-target:** `security-reviewer` — a critic reasoning about "which rule admits embedded DNS" will get the wrong answer if it takes the scoped `--dport 53` rules at face value.

The script preserves and replays Docker's `127.0.0.11` nat rules before the DNS block runs:

```bash
# devcontainer-config/init-firewall.sh:71
DOCKER_DNS_RULES=$(iptables-save -t nat | grep "127\.0\.0\.11" || true)
```

```bash
# devcontainer-config/init-firewall.sh:83-87
if [ -n "$DOCKER_DNS_RULES" ]; then
    echo "Restoring Docker DNS rules..."
    iptables -t nat -N DOCKER_OUTPUT 2>/dev/null || true
    iptables -t nat -N DOCKER_POSTROUTING 2>/dev/null || true
    echo "$DOCKER_DNS_RULES" | xargs -L 1 iptables -t nat
```

Analysis (paraphrased — no quote available because the DNAT rules are generated by the Docker daemon at container start and exist only in the live kernel nat table, not in this repo): Docker's embedded-resolver rules take the form `-A DOCKER_OUTPUT -d 127.0.0.11/32 -p udp -m udp --dport 53 -j DNAT --to-destination 127.0.0.11:<ephemeral>`, with a matching `DOCKER_POSTROUTING` SNAT restoring `:53` on the reply. The **destination address is preserved** (`127.0.0.11` → `127.0.0.11`); only the **destination port** is rewritten to a high ephemeral port. For a connection's first packet, `nat` OUTPUT is traversed before `filter` OUTPUT, and subsequent packets bypass `nat` entirely via the conntrack fast path.

Therefore, for locally-originated embedded-DNS traffic, a filter rule matching `-d 127.0.0.11 --dport 53` **does not match** — by the time filter OUTPUT sees the packet, `--dport` is the ephemeral port, not 53. The `-d 127.0.0.11` half still matches; the `--dport 53` half does not.

What actually permits embedded-DNS traffic is `iptables -A OUTPUT -o lo -j ACCEPT` (line 164, quoted under Claim 3), which is port-agnostic and matches post-DNAT just as well as pre-DNAT.

This does not make any comment in the diff false — no comment asserts that the `--dport 53` rules are what carry embedded DNS, and line 142-143 explicitly says `-o lo` covers `127.0.0.11` "regardless." Verdict is **Mostly accurate** rather than Verified because the comment's framing ("scope the fallback to Docker's embedded resolver ... so this preserves resolution") invites the reader to believe the port-53 rule is doing the work, when the DNAT rewrite means it cannot be. Precise version: *the fallback rules never match embedded-resolver traffic; `-o lo` does.*

**Evidence:** `devcontainer-config/init-firewall.sh:71`, `devcontainer-config/init-firewall.sh:83-90`, `devcontainer-config/init-firewall.sh:141-148`, `devcontainer-config/init-firewall.sh:163-164`

---

## Claim 5: "`|| echo` (not a bare call): a failed add must not abort the script" and "`|| true` is load-bearing"

**Location:** `devcontainer-config/init-firewall.sh:120-124`, `devcontainer-config/init-firewall.sh:131-135`, `devcontainer-config/init-firewall.sh:147-148`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High — tested empirically
**Legibility-target:** `security-reviewer` and future maintainer — these two guards are the R1 and A2 fixes; both are the difference between "fails closed for one resolver" and "aborts in the wide-open window."

The two comments:

```bash
# devcontainer-config/init-firewall.sh:120-124
# `|| true` is load-bearing: under `set -euo pipefail` a bare `var="$(pipeline)"`
# assignment propagates the pipeline's exit status to `set -e`, and grep exits 1
# when it matches zero resolvers — which would abort the script HERE (after the
# flush, before the DROP policy), the exact wide-open brick the fail-open branch
# below exists to prevent. Swallowing the status makes an empty result reachable.
```

```bash
# devcontainer-config/init-firewall.sh:131-133
    # `|| echo` (not a bare call): a failed add must not abort the script in the
    # post-flush/pre-DROP wide-open window — skipping a resolver fails CLOSED for
    # that resolver, which is the safe direction; aborting fails OPEN for everything.
```

**Empirically tested** in separate `bash -c` processes so the parent's `set -e` suppression inside `if` conditions could not contaminate the result (paraphrased — no quote available because this is scratch-shell output, not repo source):

- `bash -c 'set -euo pipefail; v="$(printf "x\n" | grep -E "^zzz$" | sort -u)"; echo REACHED'` → exits **1**, `REACHED` never printed. Confirms the abort the comment describes.
- The same with `|| true` inside the substitution → exits **0**, prints `REACHED` with `v` empty. Confirms `|| true` is load-bearing and makes the `else` branch reachable. This is pass 1's R1 finding, **confirmed fixed**.
- `bash -c 'set -eu; ...'` without `pipefail` → exits 0, because `sort` (the last stage) succeeds. This makes the comment's attribution precise as written: it names `pipefail` as the reason, and that is correct — `set -e` alone would not have aborted here.
- `f() { return 1; }; f || echo "WARNING" >&2` under `set -euo pipefail` → execution continues and `$?` of the compound command is **0**. Confirmed for both the standalone case and inside the `while read -r ns; do ... done < <(...)` process-substitution loop shape the script actually uses (line 129-136): both iterations ran, both warned, and the loop exited normally.

Both guards behave exactly as the comments claim, and the compound-command exit status is 0 as required.

**Evidence:** `devcontainer-config/init-firewall.sh:20`, `devcontainer-config/init-firewall.sh:120-136`, `devcontainer-config/init-firewall.sh:147-148`

---

## Claim 6: "this script has no ip6tables rules"

**Location:** `devcontainer-config/init-firewall.sh:144-145`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** `security-reviewer` — the comment uses this to dismiss the IPv6 DNS path as a pre-existing gap; the critic should know the gap is total, not partial.

```bash
# devcontainer-config/init-firewall.sh:144-145
  # reopening arbitrary-host DNS. (IPv6 DNS is unfiltered here anyway: this script has
  # no ip6tables rules — a pre-existing gap this line neither creates nor worsens.)
```

Verified by search: `rg -n 'ip6tables' devcontainer-config/init-firewall.sh` returns exactly one hit — line 145, the comment itself. There is no `ip6tables` invocation anywhere in the file (paraphrased — no quote available because the claim covers the *absence* of code; there is no matching line to quote).

Implication, stated precisely: the script establishes default-deny for IPv4 only (`iptables -P OUTPUT DROP`, line 241). The IPv6 `filter` table retains whatever policy the container started with, which for a Docker container is `ACCEPT` with no rules. So **all** IPv6 egress is unfiltered, not just DNS — the entire allowlist model is IPv4-only. The comment's narrower framing ("IPv6 DNS is unfiltered") is true but understates the scope; the same gap admits IPv6 HTTP, IPv6 SSH, and everything else, to the extent the container has IPv6 connectivity at all (which for a default Docker bridge without `--ipv6` it typically does not, making the practical exposure small). This is not a defect introduced by the diff — the pre-patch script had no `ip6tables` rules either.

**Evidence:** `devcontainer-config/init-firewall.sh:144-145`, `devcontainer-config/init-firewall.sh:239-241`

---

## Claim 7: The "post-flush/pre-DROP wide-open window" (repeated in several comments)

**Location:** `devcontainer-config/init-firewall.sh:115-116`, `devcontainer-config/init-firewall.sh:122-123`, `devcontainer-config/init-firewall.sh:132-133`, `devcontainer-config/init-firewall.sh:189-191`
**Type:** Behavioral / Architectural
**Verdict:** Mostly accurate
**Confidence:** Medium — the rule ordering is quoted directly, but "policies are ACCEPT after `-F`" depends on runtime state I cannot observe without root
**Legibility-target:** `security-reviewer` and repo owner — three separate comments justify their guards by this window. If the window is broader than the guards cover, the security review's "shipped fix" framing is incomplete.

The window's endpoints are both in the file, in the claimed order. Flush:

```bash
# devcontainer-config/init-firewall.sh:74-79
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
```

Policy set 160+ lines later:

```bash
# devcontainer-config/init-firewall.sh:238-241
# Set default policies to DROP first
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP
```

Two precisions on the claim as written:

**(a) `iptables -F` does not itself set policies to ACCEPT.** `-F` flushes *rules*; chain policies are unaffected by it (paraphrased — no quote available because this is documented `iptables` behavior, not repo source; setting a policy requires `-P`, and the file's only `-P` calls are lines 239-241). The window is wide-open because a Docker container's filter chains *start* at policy ACCEPT, not because `-F` opened them. This matters for a specific case: `node` has NOPASSWD sudo to re-run this exact script —

```
# devcontainer-config/Dockerfile:398
  echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall && \
```

— and on a **re-run**, policies are already DROP from the first run, so an abort in the window leaves the container fail-**closed**, not wide open. The comments' "brick-OPEN" framing is correct for the first run (the normal container-start path) and inverted for a re-run.

**(b) The window still exists for many other commands; the fixes only guarded the DNS block.** Between line 79 and line 239 the following can abort under `set -euo pipefail`, none of them guarded:

```bash
# devcontainer-config/init-firewall.sh:87
    echo "$DOCKER_DNS_RULES" | xargs -L 1 iptables -t nat
```

```bash
# devcontainer-config/init-firewall.sh:151
iptables -A INPUT -p udp --sport 53 -j ACCEPT
```

```bash
# devcontainer-config/init-firewall.sh:163-164,167
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
...
ipset create allowed-domains hash:net
```

and, more directly, **five explicit `exit 1` calls sit inside the window** — a deliberate abort into the wide-open state:

```bash
# devcontainer-config/init-firewall.sh:172-180
if [ -z "$gh_ranges" ]; then
    echo "ERROR: Failed to fetch GitHub IP ranges"
    exit 1
fi

if ! echo "$gh_ranges" | jq -e '.web and .api and .git' >/dev/null; then
    echo "ERROR: GitHub API response missing required fields"
    exit 1
fi
```

plus the invalid-CIDR exit (185-187), the invalid-IP exit (214-216), the missing-host-IP exit (227-229), and the critical-domain exit (204-207). So a transient `api.github.com` outage — the single most likely failure on this path — exits the script inside the window on a first run.

Verdict is **Mostly accurate** rather than Incorrect because every comment that invokes the window is locally true about its own guard; what none of them says (and what the security review's "shipped fix" summary also omits) is that the window is a property of the whole 160-line region, and the structural fix pass 1's security review recommended — set `-P OUTPUT DROP` *before* appending accepts — was **not applied**. Confirmed by the ordering quoted above: the DROP policies remain at lines 239-241, after every `-A` in the file.

**Evidence:** `devcontainer-config/init-firewall.sh:74-79`, `devcontainer-config/init-firewall.sh:87`, `devcontainer-config/init-firewall.sh:151`, `devcontainer-config/init-firewall.sh:163-167`, `devcontainer-config/init-firewall.sh:172-180`, `devcontainer-config/init-firewall.sh:185-187`, `devcontainer-config/init-firewall.sh:204-207`, `devcontainer-config/init-firewall.sh:214-216`, `devcontainer-config/init-firewall.sh:227-229`, `devcontainer-config/init-firewall.sh:238-241`, `devcontainer-config/Dockerfile:398`

---

## Claim 8: "SSH to ALLOWLISTED hosts (all of GitHub ...) still works ... matches on dst regardless of port ... ESTABLISHED,RELATED accept covers the return path"

**Location:** `devcontainer-config/init-firewall.sh:152-161`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** `security-reviewer` — this is the load-bearing "no regression" claim for the SSH removal; if it were false the removal would be a functional break, not a hardening.

The comment:

```bash
# devcontainer-config/init-firewall.sh:155-159
# SSH to ALLOWLISTED hosts (all of GitHub, via the
# api.github.com/meta CIDRs added below) still works — those destination IPs are
# in the allowed-domains ipset, which the OUTPUT accept near the end matches on
# dst regardless of port, and the ESTABLISHED,RELATED accept covers the return
# path.
```

All three components check out. GitHub's meta CIDRs are added unconditionally, on the path every run takes:

```bash
# devcontainer-config/init-firewall.sh:192-193
    ipset add -exist allowed-domains "$cidr"
done < <(echo "$gh_ranges" | jq -r '(.web + .api + .git)[]' | aggregate -q)
```

The OUTPUT accept matches on destination only, with no `-p`/`--dport` qualifier:

```bash
# devcontainer-config/init-firewall.sh:248
iptables -A OUTPUT -m set --match-set allowed-domains dst -j ACCEPT
```

The return path is covered by a general (not port-22-specific) INPUT accept:

```bash
# devcontainer-config/init-firewall.sh:243-245
# First allow established connections for already approved traffic
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
```

This general rule strictly supersedes the removed `iptables -A INPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT` (confirmed removed in `git diff main...HEAD`), so deleting the inbound companion strands nothing. Both accepts are appended *after* `-P INPUT DROP`/`-P OUTPUT DROP` (lines 239-241), which is correct — rules are evaluated before the chain policy.

**Evidence:** `devcontainer-config/init-firewall.sh:152-161`, `devcontainer-config/init-firewall.sh:192-193`, `devcontainer-config/init-firewall.sh:239-248`

---

## Claim 9: "The file is Docker-managed and root-owned; `node` ... cannot write it"

**Location:** `devcontainer-config/init-firewall.sh:105-111`
**Type:** Invariant
**Verdict:** Unverifiable
**Confidence:** Medium
**Legibility-target:** `security-reviewer` — this is the C1 fix from `6edaa21` and the trust anchor for the whole DNS-scoping control; the critic needs to know it is an assumption stated as one, not a verified property.

```bash
# devcontainer-config/init-firewall.sh:105-108
# TRUST ASSUMPTION: this scoping is only as trustworthy as /etc/resolv.conf. The
# file is Docker-managed and root-owned; `node` (which can re-run this script via
# its NOPASSWD sudo, see Dockerfile) cannot write it. If that ever changes — an
# agent-writable resolv.conf via a mount or a `--dns` value the agent influences —
```

The claim is about the ownership and mode of a file created by the Docker daemon at container start; it cannot be established from this repo alone. What the repo *does* support:

- Nothing in the build writes or chowns `/etc/resolv.conf` (paraphrased — no quote available because the claim covers the absence of code: `rg -n 'resolv' devcontainer-config/Dockerfile` returns only unrelated hits on the word "resolve" in comments about interpreter/PATH resolution, and no `resolv.conf` reference at all).
- No mount targets it. The only mounts are the two named volumes:

```jsonc
// devcontainer-config/devcontainer.json:57-60
  "mounts": [
    "source=cc-${localEnv:CC_PROJECT_ID}-bashhistory,target=/commandhistory,type=volume",
    "source=cc-${localEnv:CC_PROJECT_ID}-claude-config,target=/home/node/.claude,type=volume"
  ],
```

- The sudo scope is exactly as the comment says — one script, nothing else:

```
# devcontainer-config/Dockerfile:398
  echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall && \
```

So the comment is consistent with everything checkable in the repo, and it is explicitly labelled a trust assumption rather than asserted as fact. Confirming it would need `ls -l /etc/resolv.conf` inside a running container.

**Evidence:** `devcontainer-config/init-firewall.sh:105-111`, `devcontainer-config/Dockerfile:398`, `devcontainer-config/devcontainer.json:57-60`

---

## Claim 10: `6edaa21` commit message — "All 52 bats pass; shellcheck clean"

**Location:** commit `6edaa21` message body
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** repo owner — this is the verification claim the review-fix loop's exit rests on.

Both halves re-run against the committed tree (paraphrased — no quote available because this is command output, not repo source):

- `bats test/cc-isolated-functions.bats` → 52 `ok` lines, 0 `not ok`. The count matches exactly.
- `shellcheck devcontainer-config/init-firewall.sh` → no output, exit 0.

Explicitly compared against the logged hallucination pattern *"a specific measured value quoted from a checked-in artifact set that does not contain it"* (both entries in `docs/reviews/hallucination-patterns.md`): **not a recurrence** — the "52" is a real count of a real file, reproduced here.

Note the same "52" appears as a code-adjacent claim in the security review doc, and is likewise correct:

```markdown
<!-- docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:138-140 -->
Both edits are inside the firewall-application path (after the `--print-domains`
early exit), so `compose_domains` and the 52 `test/cc-isolated-functions.bats`
tests are unaffected.
```

The "unaffected" half is also correct: the `--print-domains` early exit sits above every changed line, so the tested path never reaches the DNS block:

```bash
# devcontainer-config/init-firewall.sh:56-59
if [ "${1:-}" = "--print-domains" ]; then
  compose_domains
  exit 0
fi
```

**Immutability note:** `6edaa21` is the branch tip and its message is already written; a commit message cannot be edited without a rewrite. This claim is Verified, so nothing needs fixing — recorded here for completeness of the pass.

**Evidence:** commit `6edaa21`; `devcontainer-config/init-firewall.sh:56-59`; `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:138-140`

---

## Claim 11: Security-review doc — "the fallback is scoped to Docker's embedded resolver `127.0.0.11` ... while still resolving in the standard Docker case (session start can never brick)"

**Location:** `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:82-94`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** repo owner and `security-reviewer` — the doc is the durable artifact of this hardening; a future reader will treat its "Fix (shipped)" list as the record of what the boundary now guarantees.

The doc's description of the shipped behavior:

```markdown
<!-- docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:84-89 -->
   `/etc/resolv.conf` (validated to real 0–255-octet IPv4 addresses). When no
   IPv4 resolver parses, the fallback is scoped to Docker's embedded resolver
   `127.0.0.11` — **not** a blanket `0.0.0.0/0` accept — so the degraded path
   does not re-grant the exact channel this fix removes, while still resolving in
   the standard Docker case (session start can never brick). This removes the
   *direct* "socket at `attacker_ip:53`" path.
```

Three of the four assertions are correct against the code: the 0–255 validation is real (Claim 1), the fallback is `127.0.0.11` and not `0.0.0.0/0` (lines 147-148), and the direct `attacker_ip:53` path is removed (Claim 3). The fourth — *"while still resolving in the standard Docker case"* — carries the same self-cancelling condition as Claim 2: the fallback branch is unreachable whenever `127.0.0.11` is the configured resolver, because `127.0.0.11` parses cleanly and takes the `if` branch (line 128). The doc inherits the code comment's error verbatim.

The parenthetical *"session start can never brick"* is now accurate in the narrow sense that the script no longer aborts on the no-resolver path (Claim 5 — pass 1's R1 defect is genuinely fixed). It is inaccurate as an end-to-end guarantee: DNS resolution itself is not preserved on that path (Claim 2), and the script retains five in-window `exit 1` calls on the GitHub-fetch and host-IP paths that will brick session start for unrelated reasons (Claim 7).

The doc's "What was changed" summary repeats the same framing and inherits the same defect:

```markdown
<!-- docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:133-136 -->
  - Scoped outbound DNS to `/etc/resolv.conf` resolvers (0–255-octet validated),
    with a `127.0.0.11`-scoped (not `0.0.0.0/0`) fail-open fallback and non-fatal
    per-resolver adds so a malformed entry cannot abort the script in the
    post-flush/pre-DROP wide-open window.
```

That last clause is correct as far as it goes (per Claim 5), but reads as if the wide-open window is now closed; per Claim 7 the window persists for every other command in the region and the recommended structural fix was not applied.

Unlike Claim 10, this doc is an ordinary tracked file on the branch and is editable.

**Evidence:** `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:82-94`, `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:133-136`, `devcontainer-config/init-firewall.sh:128`, `devcontainer-config/init-firewall.sh:137-149`

---

## Claim 12: "Outbound DNS is scoped to the container's CONFIGURED resolvers (from /etc/resolv.conf), not to 0.0.0.0/0"

**Location:** `devcontainer-config/init-firewall.sh:94-103`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** `security-reviewer` — the headline claim of the whole diff; the critic's threat-model delta depends on it being precise about *which* rule delivers the scoping.

```bash
# devcontainer-config/init-firewall.sh:94-100
# Outbound DNS is scoped to the container's CONFIGURED resolvers (from
# /etc/resolv.conf), not to 0.0.0.0/0. A blanket `--dport 53 ACCEPT` lets a
# compromised session point a UDP socket straight at an attacker-controlled
# authoritative nameserver (attacker_ip:53) and stream data out in the query
# names — a clean, high-bandwidth exfil channel that bypasses the whole
# allowlist.
```

The narrow claim is true and the described channel is genuinely closed: no rule in the file now accepts port 53 to an unconstrained destination, and unmatched egress hits the terminal reject:

```bash
# devcontainer-config/init-firewall.sh:250-251
# Explicitly REJECT all other outbound traffic for immediate feedback
iptables -A OUTPUT -j REJECT --reject-with icmp-admin-prohibited
```

Two qualifiers keep this from being a clean Verified, both established under Claim 3:

1. "Scoped to the configured resolvers" is an incomplete description of the resulting outbound-53 surface. `iptables -A OUTPUT -o lo -j ACCEPT` (line 164) admits port 53 to any `127/8` address, and `iptables -A OUTPUT -d "$HOST_NETWORK" -j ACCEPT` (line 236) admits port 53 to every address on the host `/24`. The effective scope is *configured resolvers ∪ loopback ∪ host `/24`*, not just the configured resolvers. Neither addition is attacker-reachable in the threat model (an attacker's nameserver is not on loopback or the host bridge), so the security conclusion holds — but a reader auditing "what can reach :53" from this comment alone would undercount.
2. The scoping is delivered by the **removal** of the blanket accept, not by the added scoped accepts, in the default Docker configuration where those accepts are redundant with `-o lo` (Claim 3) and unmatchable after DNAT (Claim 4).

Precise version: *the blanket `--dport 53` accept to `0.0.0.0/0` is removed; outbound 53 now reaches only the configured IPv4 resolvers, loopback, and the host `/24`, and everything else is rejected.*

**Evidence:** `devcontainer-config/init-firewall.sh:94-103`, `devcontainer-config/init-firewall.sh:128-149`, `devcontainer-config/init-firewall.sh:163-164`, `devcontainer-config/init-firewall.sh:236`, `devcontainer-config/init-firewall.sh:250-251`

---

## Claims Requiring Attention

### Incorrect
- **Claim 2** (`devcontainer-config/init-firewall.sh:141-145`): "preserves resolution for the standard Docker network" cannot hold in the case that triggers the branch — `127.0.0.11` parses cleanly and takes the `if` branch, so the `else` runs only when the embedded resolver is *not* configured. Fix the comment to say the fallback keeps the script running and does not widen DNS, but does not restore resolution; and that what actually preserves DNS in the IPv6-only case is the absence of `ip6tables` rules. Also drop "a `--dns` override" from the trigger list — a `--dns` value that lands in `resolv.conf` is a parseable IPv4 address and takes the `if` branch.
- **Claim 11** (`docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:82-94`): the doc inherits Claim 2's error ("while still resolving in the standard Docker case") and its "session start can never brick" is true only of the script not aborting on that one path, not of DNS availability or of session start generally (five in-window `exit 1` calls remain). Editable file — update alongside the comment.

### Stale
- (none)

### Mostly Accurate
- **Claim 4** (`devcontainer-config/init-firewall.sh:141-148`): the scoped `--dport 53` rules cannot match embedded-resolver traffic, because Docker's `DOCKER_OUTPUT` DNAT rewrites the destination port to an ephemeral one in `nat` OUTPUT, which is traversed before `filter` OUTPUT. `-o lo` (line 164) is what admits that traffic. Worth one clarifying sentence so a future reader does not "fix" a rule that was never carrying the traffic.
- **Claim 7** (`devcontainer-config/init-firewall.sh:115-116, 122-123, 132-133, 189-191`): the "wide-open window" framing is right for a first run but inverted on a `sudo init-firewall.sh` re-run (policies are already DROP → fail-closed). More importantly the window is unguarded for everything *except* the DNS block — five explicit `exit 1` calls sit inside it, including the likely `api.github.com` fetch failure. Tighten to "guards the DNS block's contribution to the window"; the structural fix (set `-P OUTPUT DROP` before appending accepts) remains unapplied.
- **Claim 12** (`devcontainer-config/init-firewall.sh:94-103`): effective outbound-53 scope is configured resolvers ∪ loopback ∪ host `/24`, not configured resolvers alone. Security conclusion unaffected; the enumeration is what's imprecise.

### Unverifiable
- **Claim 9** (`devcontainer-config/init-firewall.sh:105-111`): `/etc/resolv.conf` ownership/mode is a property of the running container. Repo-side evidence is consistent (no Dockerfile write, no mount targeting it, sudo scoped to one script), but confirming needs `ls -l /etc/resolv.conf` inside a live container. The comment already labels itself a trust assumption.

---

## Goal-Alignment Note

The branch's stated goal is two egress hardenings: (1) remove the blanket outbound-SSH accept, (2) scope outbound DNS to the resolvers in `/etc/resolv.conf`. `6edaa21` additionally claims to fix pass 1's three findings. Against those:

- **Objective (1) is met and accurately documented.** The `--dport 22` accept and its inbound companion are gone; GitHub SSH genuinely survives via the port-agnostic `allowed-domains` dst-match plus the general ESTABLISHED,RELATED accepts (Claim 8). Nothing in this pass disturbs pass 1's conclusion here.

- **`6edaa21`'s three fixes are real.** Pass 1's R1 (unreachable `else` under `set -e`) is fixed and empirically re-verified: `|| true` on the command substitution makes the branch reachable, and the abort without it reproduces (Claim 5). A2's octet regex is a genuine 0–255 match that survives double-quoting intact, verified against the full test vector (Claim 1). A1's `0.0.0.0/0` fallback is gone. C1's trust assumption is pinned, and is consistent with everything checkable in the repo (Claim 9). This is the strongest part of the branch.

- **Objective (2) is real but its documentation misdescribes the mechanism, and the fix to A1 introduced a new documentation defect.** The security win is genuine and comes from *deleting* the blanket `--dport 53` accept — an attacker-aimed socket now hits the terminal REJECT (Claims 3, 12). But the added scoped accepts, which the comments foreground as the fix, are redundant no-ops in the default Docker configuration for two independent reasons: `-o lo` already admits all loopback egress (Claim 3), and the `DOCKER_OUTPUT` DNAT rewrites the port before `filter` OUTPUT sees it (Claim 4). They are load-bearing only where the resolver is a non-loopback address outside the host `/24`. Layered on that, the A1 fix's own comment — and the security review doc that mirrors it — assert an availability guarantee that is self-cancelling: the fallback claims to preserve the standard-Docker case, but can only execute when the standard-Docker resolver is absent (Claims 2, 11). This is the one place a reader acting on the documentation would be materially misled, and unlike pass 1's finding it is a documentation defect, not a behavioral one — the code is safe, the comment overstates what it delivers.

- **The structural recommendation from pass 1 was not applied, and the comments do not say so.** `-P OUTPUT DROP` still runs at line 241, after every `-A` in the file. Three separate comments justify their guards by "the post-flush/pre-DROP wide-open window" without noting that the window is a property of the whole 160-line region and remains unguarded for everything else in it, including five explicit `exit 1` calls (Claim 7). A reader of `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:133-136` would reasonably conclude the window is addressed; it is narrowed by one block.

**Confidence apportionment.** Claims 1, 5, 6, 8, 10 rest on direct execution or direct file evidence and are high-confidence. Claims 3, 4, 7 involve netfilter runtime behavior that could not be executed here (no root, no iptables) and are reasoned from rule text plus documented traversal order — the substance is stable, but a maintainer with a live container should confirm Claim 4's DNAT port-rewrite before acting on it.

No fabricated symbols, APIs, or nonexistent behaviors were found. The two Incorrect verdicts are a self-cancelling conditional in prose and its verbatim inheritance by a doc — semantic defects, not fabrications — so **no new entry is added to `docs/reviews/hallucination-patterns.md`**. The one value-quoting claim in scope ("all 52 bats pass") was explicitly compared against both logged patterns and reproduced exactly.
