# Code Fact-Check Report

**Commit:** 6edaa21

**Repository:** `/workspace` (branch `harden/cc-isolated-egress`)
**Scope:** `git diff main...HEAD` — `devcontainer-config/init-firewall.sh` (whole file read), plus the branch's doc/commit claims in `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md` and the messages of `c44c33a` and `6edaa21`
**Checked:** 2026-08-29
**Total claims checked:** 16
**Summary:** 10 verified, 3 mostly accurate, 0 stale, 2 incorrect, 1 unverifiable

**Method note.** Claims about *shell semantics* (regex range matching, double-quote survival of `\.` and trailing `$`, `set -e` interaction with `|| echo` and `|| true`, branch reachability across resolv.conf variants) were tested empirically in a scratch bash shell with a stubbed `iptables`; those claim blocks say "executed". Claims about *iptables/netfilter semantics* (chain traversal order, DNAT rewrite, `-F` vs. `-P`, `lo` routing) could not be executed — this session has no root and `iptables-save` returns `Permission denied (you must be root)` — so those blocks say "reasoned, not executed" and carry reduced confidence.

**Hallucination-pattern log.** `docs/reviews/hallucination-patterns.md` was read before checking. Its two logged patterns are both of the form *a specific measured statistic quoted from a checked-in artifact set that does not contain that value*. Claim 8 and Claim 13 below are the closest relatives in this run (an availability guarantee asserted about a configuration the branch that asserts it cannot be in), but neither fabricates a symbol or API, so neither qualifies for the log. No claim in this run matches a logged pattern.

---

## Claim 1: "Scoping to the real resolvers removes that direct path: the agent must go through the embedded/host resolver, which only does name recursion."

**Location:** `devcontainer-config/init-firewall.sh:94-100`
**Type:** Behavioral / Architectural
**Verdict:** Mostly accurate
**Confidence:** Medium
**Legibility-target:** A reviewer deciding whether the DNS-scoping patch is a real control or a no-op.

The direct-exfil path is closed, but by the **deletion** of the old blanket rule, not by the addition of the scoped ones. The pre-patch rule was a wildcard accept:

```bash
# main:devcontainer-config/init-firewall.sh (removed by c44c33a)
-iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
```

With that gone, any UDP/53 packet to a non-resolver destination falls through to the terminal reject:

```bash
# devcontainer-config/init-firewall.sh:250-251
# Explicitly REJECT all other outbound traffic for immediate feedback
iptables -A OUTPUT -j REJECT --reject-with icmp-admin-prohibited
```

So the security gain is real. What the added rules contribute depends on the resolver: they are load-bearing only when the resolver is **not** a loopback address (see Claim 9). This container's own resolver is non-loopback, so in a deployment shaped like this one the scoped accepts do carry weight:

```
# /etc/resolv.conf (observed in this container)
nameserver 192.168.65.7
```

The residual-risk half of the claim is separately verified as Claim 2. The precise version of the sentence is: *removing the blanket accept* removes the direct path; the scoped accepts restore reachability to the configured resolver where `-o lo` would not already cover it.

**Evidence:** `devcontainer-config/init-firewall.sh:94-100`, `devcontainer-config/init-firewall.sh:125-149`, `devcontainer-config/init-firewall.sh:250-251`

---

## Claim 2: "Recursive-forward DNS tunnelling — `<data>.attacker.com` resolved through the legitimate resolver — is NOT closed by this; that needs a filtering resolver, not an IP firewall."

**Location:** `devcontainer-config/init-firewall.sh:101-103`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** A reader who might otherwise treat DNS exfil as solved.

Nothing anywhere in the script inspects DNS payloads or query names; the only DNS-related rules are destination-IP and port matches:

```bash
# devcontainer-config/init-firewall.sh:134-135
iptables -A OUTPUT -p udp -d "$ns" --dport 53 -j ACCEPT || echo "WARNING: could not add UDP DNS rule for $ns" >&2
iptables -A OUTPUT -p tcp -d "$ns" --dport 53 -j ACCEPT || echo "WARNING: could not add TCP DNS rule for $ns" >&2
```

An accept keyed on `-d "$ns" --dport 53` cannot distinguish `github.com` from `<base32-data>.attacker.com`, so a query forwarded by the legitimate resolver is unaffected by the rule (paraphrased — no quote available because the claim covers the *absence* of any name-inspecting code; `rg` over the file returns no payload/DPI match beyond the two lines quoted above).

The referenced doc corroborates rather than contradicts:

```markdown
# docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:116-119
6. **Recursive-forward DNS tunnelling.** Even with resolver-scoping (patch 2), a
   session can resolve `<base32-data>.attacker.com` through the legitimate
   resolver, which forwards it to the attacker's authoritative NS. Closing this
   needs a **filtering resolver** ...
```

**Evidence:** `devcontainer-config/init-firewall.sh:101-103`, `devcontainer-config/init-firewall.sh:134-135`, `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:116-121`

---

## Claim 3: "The file is Docker-managed and root-owned; `node` (which can re-run this script via its NOPASSWD sudo, see Dockerfile) cannot write it."

**Location:** `devcontainer-config/init-firewall.sh:105-111`
**Type:** Invariant / Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** A future maintainer changing the sudoers grant or adding a mount.

The NOPASSWD grant is exactly one path, not a wildcard:

```dockerfile
# devcontainer-config/Dockerfile:398-399
  echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall && \
  chmod 0440 /etc/sudoers.d/node-firewall
```

and that is the script the container invokes at start, confirming the "can re-run" half:

```jsonc
// devcontainer-config/devcontainer.json:93
"postStartCommand": "sudo /usr/local/bin/init-firewall.sh && /usr/local/bin/link-claude-home.sh",
```

No mount in `devcontainer.json` targets `/etc/resolv.conf`, so the file stays Docker-managed (paraphrased — no quote available because the claim covers the absence of a matching mount entry: `rg -n 'resolv'` over `devcontainer.json` and `Dockerfile` returns zero hits).

**Evidence:** `devcontainer-config/init-firewall.sh:105-111`, `devcontainer-config/Dockerfile:398-399`, `devcontainer-config/devcontainer.json:93`

---

## Claim 4: "The octet alternation is a real 0–255 match, not a `[0-9]{1,3}` shape check."

**Location:** `devcontainer-config/init-firewall.sh:113-118, 125-127`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Anyone touching the resolver-validation regex.

The pattern under test, quoted from source:

```bash
# devcontainer-config/init-firewall.sh:125-127
octet='(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])'
dns_resolvers="$(awk '/^[[:space:]]*nameserver/ {print $2}' /etc/resolv.conf 2>/dev/null \
  | grep -E "^${octet}(\.${octet}){3}$" | sort -u || true)"
```

**Executed.** An exhaustive sweep of `$i.$i.$i.$i` for `i` in 0..300 produced zero false accepts and zero false rejects: all 256 in-range values matched, all 45 out-of-range values were rejected. The spot-check list from the brief behaved as claimed — accepted: `0.0.0.0`, `255.255.255.255`, `127.0.0.11`, `10.0.0.1`; rejected: `256.1.1.1`, `999.999.999.999`, `1.2.3`, `01.2.3.4`, `1.2.3.4.5`, `8.8.8.8x`, and both `8.8.8.8␠` (trailing space) and `␠␠8.8.8.8` (leading spaces).

The two whitespace rejections are moot in situ and fail in the safe direction: `awk '{print $2}'` emits a whitespace-free field, so a padded resolver line still yields a bare address (paraphrased — no quote available because the behavior is awk's field-splitting semantics, not a snippet in this repo). Even if a padded value did reach `grep`, rejecting it drops one resolver rather than aborting — the direction Claim 7's guard is designed for.

**Shell-quoting sub-check (executed).** The brief asks specifically whether double-quoting damages the pattern. It does not. Printing the argument bash actually hands `grep` gives:

```
^(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}$
```

`\.` survives double-quoting because `\.` is not one of the four sequences bash treats as an escape inside double quotes (`$`, `` ` ``, `"`, `\`, newline) — the backslash is passed through literally, so ERE sees a literal-dot atom. Confirmed behaviorally: `1x2.3.4.5` does **not** match. The trailing `$` before the closing quote is likewise literal — bash only expands `$` when followed by a name, `{`, `(`, or a special parameter, and here it is followed by `"` — so ERE sees an end anchor. Confirmed behaviorally: `1.2.3.4extra` does **not** match.

**Evidence:** `devcontainer-config/init-firewall.sh:113-118`, `devcontainer-config/init-firewall.sh:125-127`

---

## Claim 5: "a shape check passes `999.999.999.999`, which iptables then treats as a hostname, fails to resolve, and exits non-zero — aborting the script under `set -e` AFTER the flush but BEFORE the DROP policy, i.e. brick-OPEN."

**Location:** `devcontainer-config/init-firewall.sh:113-118`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Legibility-target:** A reviewer weighing whether the regex tightening was necessary.

This is a counterfactual about a code path that no longer exists, and its load-bearing middle step — that `iptables -d 999.999.999.999` attempts hostname resolution and exits non-zero — requires running `iptables` as root, which this session cannot do (`iptables-save -t nat` returns `Permission denied (you must be root)`). The claim is consistent with documented iptables behavior for a non-address `-d` argument, but I did not execute it, so I decline to verdict it Verified.

What *is* checkable is that the claim is now doubly moot, and both mootness conditions hold. The regex rejects the value (Claim 4, executed), and even a hypothetical surviving bad value could not abort, because the add is guarded (Claim 7, executed):

```bash
# devcontainer-config/init-firewall.sh:134
iptables -A OUTPUT -p udp -d "$ns" --dport 53 -j ACCEPT || echo "WARNING: could not add UDP DNS rule for $ns" >&2
```

The "after the flush but before the DROP policy" positional half of the claim is verified separately as Claim 12.

**Evidence:** `devcontainer-config/init-firewall.sh:113-118`, `devcontainer-config/init-firewall.sh:125-127`, `devcontainer-config/init-firewall.sh:134`

---

## Claim 6: "`|| true` is load-bearing: under `set -euo pipefail` a bare `var="$(pipeline)"` assignment propagates the pipeline's exit status to `set -e`, and grep exits 1 when it matches zero resolvers."

**Location:** `devcontainer-config/init-firewall.sh:120-124, 127`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Anyone tempted to "clean up" the trailing `|| true`.

This is the fix for pass 1's R1. **Executed.** A minimal reproduction under `set -euo pipefail` confirms both directions: a bare failing command aborts the script (exit 1, subsequent `echo` never runs), while the same command with a trailing `|| ...` yields compound status 0 and execution continues.

Applied to the real block, an end-to-end simulation with a stubbed `iptables` and five synthetic resolv.conf files — Docker-embedded (`nameserver 127.0.0.11`), IPv6-only, mixed valid+`999.999.999.999`, empty, and a nonexistent path — reached the end of the block with exit 0 in all five cases, and the three no-IPv4 cases entered the `else` branch and emitted its warning. The `else` branch is therefore reachable, which was the defect pass 1 found:

```bash
# devcontainer-config/init-firewall.sh:126-127
dns_resolvers="$(awk '/^[[:space:]]*nameserver/ {print $2}' /etc/resolv.conf 2>/dev/null \
  | grep -E "^${octet}(\.${octet}){3}$" | sort -u || true)"
```

Note the `|| true` is placed inside the command substitution, after `sort -u`, so it neutralizes the whole pipeline's status (including `pipefail`-propagated grep-1) before the assignment sees it. The mixed valid+invalid case also behaved as intended: `999.999.999.999` was dropped and only `8.8.8.8` was added — a bad entry fails closed for itself, not for the script.

**Evidence:** `devcontainer-config/init-firewall.sh:120-124`, `devcontainer-config/init-firewall.sh:126-127`, `devcontainer-config/init-firewall.sh:128-149`

---

## Claim 7: "`|| echo` (not a bare call): a failed add must not abort the script in the post-flush/pre-DROP wide-open window — skipping a resolver fails CLOSED for that resolver ... aborting fails OPEN for everything."

**Location:** `devcontainer-config/init-firewall.sh:131-135, 147-148`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Anyone reviewing error handling inside the flush window.

All four guarded adds use the same construct:

```bash
# devcontainer-config/init-firewall.sh:147-148
iptables -A OUTPUT -p udp -d 127.0.0.11 --dport 53 -j ACCEPT || echo "WARNING: could not add UDP DNS fallback rule" >&2
iptables -A OUTPUT -p tcp -d 127.0.0.11 --dport 53 -j ACCEPT || echo "WARNING: could not add TCP DNS fallback rule" >&2
```

**Executed.** With `iptables` stubbed to return 1, both branches (the `while`-loop branch and the `else` fallback) emitted their warnings, continued past every subsequent statement, and the script exited 0. A direct probe of the compound's status (`cmd || echo ...; rc=$?`) printed `rc = 0`, and the control comparison — the same failing call unguarded — aborted at that line under `set -e`. The "fails CLOSED for that resolver" characterization also holds: a skipped add leaves no accept, and the terminal `-j REJECT` (`init-firewall.sh:251`, quoted in Claim 1) denies that resolver rather than admitting it.

**Evidence:** `devcontainer-config/init-firewall.sh:131-135`, `devcontainer-config/init-firewall.sh:147-148`

---

## Claim 8: "Scope the fallback to Docker's embedded resolver (127.0.0.11), which is the resolver in the overwhelming common case ... so this preserves resolution for the standard Docker network without reopening arbitrary-host DNS."

**Location:** `devcontainer-config/init-firewall.sh:138-145`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Legibility-target:** A maintainer relying on this branch for the "session start can never brick" guarantee.

The "without reopening arbitrary-host DNS" half is true — the destination is a literal, not `0.0.0.0/0`. The **availability guarantee is not**, because the branch's entry condition and the scenario it claims to serve are mutually exclusive.

The branch fires only when `$dns_resolvers` is empty:

```bash
# devcontainer-config/init-firewall.sh:128, 137
if [ -n "$dns_resolvers" ]; then
...
else
```

and (Claim 4, executed) `127.0.0.11` is an address the regex **accepts**. So on the standard Docker user-defined network, whose resolv.conf is exactly `nameserver 127.0.0.11`, control takes the `if` branch, never the `else`. The simulation confirms this directly: the `r_docker.conf` case printed `Allowing DNS to configured resolver 127.0.0.11` and never reached the fallback. The fallback fires only when resolv.conf holds **no** parseable IPv4 nameserver — the IPv6-only, empty, and missing-file cases, all of which entered the `else` branch in the simulation.

In each of those triggering scenarios, `127.0.0.11` is by construction *not* the configured resolver, so a rule permitting traffic to it restores nothing:

- **IPv6-only resolv.conf** — the resolvers are IPv6 addresses; an IPv4 filter rule for `127.0.0.11` is irrelevant to them. Resolution survives here, but for an unrelated reason (Claim 10: no ip6tables rules exist, so IPv6 DNS is unfiltered), not because of this line.
- **Empty / missing resolv.conf** — there is no resolver at all, so there is nothing to preserve.

The precise version: the fallback reopens nothing and preserves nothing; it is inert in every case that reaches it. The "session start can never brick" property in the IPv6-only case comes from the absence of IPv6 filtering, and in the empty case there was no working resolution to brick. Claim 9 shows it is inert a second way even on its own terms.

**Evidence:** `devcontainer-config/init-firewall.sh:128`, `devcontainer-config/init-firewall.sh:137-149`, `devcontainer-config/init-firewall.sh:125-127`

---

## Claim 9: "127.0.0.11 ... is already reachable via the `-o lo` accept below regardless"

**Location:** `devcontainer-config/init-firewall.sh:142-143`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** A reviewer asking whether the loopback DNS rules do any work.

The rule exists, below the DNS block as stated:

```bash
# devcontainer-config/init-firewall.sh:163-164
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
```

**Reasoned, not executed** (no root; `iptables-save` denied): `127.0.0.11` falls in `127.0.0.0/8`, which the kernel routes out the loopback device, so `-o lo` matches packets to it. Rule order does not change the outcome — the loopback accept is appended at position ~3 in `OUTPUT`, after the DNS accepts, but both are `ACCEPT` and both precede the terminal `REJECT` at `init-firewall.sh:251`.

**Consequence the comment does not state, and which the brief asks about explicitly.** If `-o lo` already accepts this traffic, then *both* the `else`-branch fallback rules (`init-firewall.sh:147-148`) *and* the `if`-branch rules when resolv.conf holds the Docker default `127.0.0.11` (`init-firewall.sh:134-135`) are redundant no-ops. That makes the DNS-scoping change a no-op **in a user-defined-network Docker configuration**, where the resolver is loopback.

It does **not** make the change theater overall, for two reasons:

1. The security gain is the *removal* of the blanket rule (Claim 1), which is independent of whether the replacement rules ever match.
2. This deployment does not appear to be the loopback case. `cc-isolated.sh` launches via `devcontainer up` with no network argument, and `devcontainer.json`'s `runArgs` add only capabilities:

```jsonc
// devcontainer-config/devcontainer.json:46-48
"runArgs": [
    "--cap-add=NET_ADMIN",
    "--cap-add=NET_RAW"
```

   With no user-defined network, Docker's embedded resolver is not used and resolv.conf carries host-derived resolvers — matching the non-loopback `nameserver 192.168.65.7` observed in this container. In that shape the scoped `-d "$ns"` accepts are load-bearing and `-o lo` does not cover them.

Net: the comment's assertion is correct, and its corollary is that the fallback it justifies is inert twice over — once because it cannot fire in the case it names (Claim 8), once because `-o lo` would cover it anyway.

**Evidence:** `devcontainer-config/init-firewall.sh:142-143`, `devcontainer-config/init-firewall.sh:163-164`, `devcontainer-config/init-firewall.sh:251`, `devcontainer-config/devcontainer.json:46-48`

---

## Claim 10: "IPv6 DNS is unfiltered here anyway: this script has no ip6tables rules — a pre-existing gap this line neither creates nor worsens."

**Location:** `devcontainer-config/init-firewall.sh:144-145`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** A reader assessing the completeness of the egress boundary.

`rg -n 'ip6tables' devcontainer-config/init-firewall.sh` returns exactly one hit, and it is the comment making the claim — no executable `ip6tables` invocation exists anywhere in the file or in the rest of `devcontainer-config/` (paraphrased — no quote available because the claim covers the *absence* of code; the single grep hit is line 145, the comment itself). The "pre-existing" qualifier holds: the branch diff for this file adds no `ip6tables` line and removes none.

**Implication for the IPv6 DNS path the comment waves at.** Because the whole script operates on the IPv4 `filter`/`nat`/`mangle` tables, the entire default-deny egress boundary — not just DNS — applies to IPv4 only. Any IPv6-reachable destination is unfiltered, so an agent with IPv6 connectivity has an egress channel that no rule in this file constrains. The comment is accurate about DNS specifically, but it understates the scope of what it names: the gap is the boundary, not merely the DNS leg of it. That is an observation about what the code does, not a recommendation.

**Evidence:** `devcontainer-config/init-firewall.sh:144-145`

---

## Claim 11: "SSH to ALLOWLISTED hosts (all of GitHub ...) still works — those destination IPs are in the allowed-domains ipset, which the OUTPUT accept near the end matches on dst regardless of port, and the ESTABLISHED,RELATED accept covers the return path."

**Location:** `devcontainer-config/init-firewall.sh:152-161`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** A user whose `git push` over SSH must keep working after the blanket rule was removed.

Every load-bearing element is present. GitHub's published ranges are added to the set:

```bash
# devcontainer-config/init-firewall.sh:188-192
    echo "Adding GitHub range $cidr"
    ...
    ipset add -exist allowed-domains "$cidr"
```

The set-match accept specifies `dst` and names no protocol or port, so it matches any port including 22:

```bash
# devcontainer-config/init-firewall.sh:247-248
# Then allow only specific outbound traffic to allowed domains
iptables -A OUTPUT -m set --match-set allowed-domains dst -j ACCEPT
```

and the return path is covered:

```bash
# devcontainer-config/init-firewall.sh:243-245
# First allow established connections for already approved traffic
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
```

The "add that host to its egress profile" escape hatch is also real — `compose_domains` reads per-profile files from `EGRESS_DIR`, and eight such files ship (`base.txt`, `python.txt`, `rust.txt`, `android.txt`, `dotnet.txt`, `lean.txt`, `llm.txt`, `vscode.txt`):

```bash
# devcontainer-config/init-firewall.sh:42-50
  for p in $(echo "$profiles" | tr ',' '\n' | sort -u); do
    f="$EGRESS_DIR/$p.txt"
```

**Evidence:** `devcontainer-config/init-firewall.sh:152-161`, `devcontainer-config/init-firewall.sh:188-192`, `devcontainer-config/init-firewall.sh:243-248`, `devcontainer-config/init-firewall.sh:42-50`

---

## Claim 12: "under set -e a duplicate add would kill the script mid-loop, after the flush but before the DROP policies, leaving the container wide open."

**Location:** `devcontainer-config/init-firewall.sh:189-191` (the claim is restated at `:115-118`, `:122-124`, `:132-133`)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Legibility-target:** Anyone adding a new command between the flush and the DROP policies.

The geometry is exactly as claimed. The flush:

```bash
# devcontainer-config/init-firewall.sh:73-79
# Flush existing rules and delete existing ipsets
iptables -F
iptables -X
```

and the policies, 160 lines later:

```bash
# devcontainer-config/init-firewall.sh:238-241
# Set default policies to DROP first
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP
```

**Two qualifiers the comment omits.**

*(a) `-F` does not set policies to ACCEPT; it leaves them as they were.* **Reasoned, not executed** (no root): `iptables -F` flushes rules from chains and does not touch chain policies, which change only via `-P` or `iptables-restore`. So the window is wide open on a **fresh container**, where the built-in `filter` chains still carry the kernel's default `ACCEPT` policy — the script never sets ACCEPT itself. On a **re-run** inside an already-firewalled container (which `node` can trigger via its NOPASSWD sudo, `Dockerfile:398`), the previous run's `DROP` policy survives the flush, so an abort in that region leaves the container closed, not open. The comment's "wide open" is therefore true of the first run and inverted on a re-run.

*(b) The fixes guarded only the DNS block; the window remains for everything else.* The brief asks this directly, and the answer is that many unguarded aborts still live between line 79 and line 241 — several of them deliberate `exit 1` calls, which no `|| echo` idiom could ever cover:

```bash
# devcontainer-config/init-firewall.sh:172-175
if [ -z "$gh_ranges" ]; then
    echo "ERROR: Failed to fetch GitHub IP ranges"
    exit 1
fi
```

```bash
# devcontainer-config/init-firewall.sh:226-229
if [ -z "$HOST_IP" ]; then
    echo "ERROR: Failed to detect host IP"
    exit 1
fi
```

The same pattern recurs at `:177-180` (jq field check), `:184-187` (invalid CIDR from GitHub meta), `:204-207` (critical domain `api.anthropic.com` unresolvable), and `:213-216` (invalid IP from DNS). Bare, unguarded commands in the window include `iptables -t nat -N`/`xargs -L 1 iptables -t nat` (`:85-87`), the inbound-DNS and loopback accepts (`:151`, `:163-164`), `ipset create allowed-domains hash:net` (`:167`), and the two host-network accepts (`:235-236`). So the comment accurately describes a hazard that the branch's fixes narrowed for the DNS block only; the structural fix pass 1's security review recommended — setting `-P OUTPUT DROP` before appending accepts — was not applied, and the window it targets is still present for all of the above.

**Evidence:** `devcontainer-config/init-firewall.sh:73-79`, `devcontainer-config/init-firewall.sh:172-175`, `devcontainer-config/init-firewall.sh:226-229`, `devcontainer-config/init-firewall.sh:238-241`, `devcontainer-config/Dockerfile:398`

---

## Claim 13: "the fallback is scoped to Docker's embedded resolver `127.0.0.11` ... so the degraded path does not re-grant the exact channel this fix removes, while still resolving in the standard Docker case (session start can never brick)."

**Location:** `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:84-89`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Legibility-target:** A reader of the security review who takes the shipped-fix description as a description of shipped behavior.

The doc's first half matches the code — the fallback destination is a literal `127.0.0.11`, not `0.0.0.0/0` (`init-firewall.sh:147-148`, quoted in Claim 7). The clause **"while still resolving in the standard Docker case"** is the same defect as Claim 8, restated in the doc: the standard Docker case parses `127.0.0.11` successfully and therefore takes the `if` branch, so the fallback is never the thing resolving in that case. The doc thus describes an availability property the fallback does not provide in any configuration that reaches it.

The rest of the doc's DNS description checks out against the code:

```markdown
# docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:133-135
  - Scoped outbound DNS to `/etc/resolv.conf` resolvers (0–255-octet validated),
    with a `127.0.0.11`-scoped (not `0.0.0.0/0`) fail-open fallback and non-fatal
    per-resolver adds so a malformed entry cannot abort the script in the
```

— 0–255 validation is Claim 4 (verified), non-fatal adds are Claim 7 (verified), and the recursive-forward residual at `:116-121` is Claim 2 (verified).

**Evidence:** `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:82-92`, `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:133-135`, `devcontainer-config/init-firewall.sh:128-149`

---

## Claim 14: "All 52 bats pass; shellcheck clean" (commit `6edaa21` message)

**Type:** Configuration / Reference
**Location:** commit `6edaa21` message body
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** A reviewer deciding whether to re-run the suite before merging.

**Executed.** `bats --count test/cc-isolated-functions.bats` reports `52`; a full run produced 52 `ok` lines and zero `not ok` lines. `shellcheck devcontainer-config/init-firewall.sh` produced no output and exited 0 (paraphrased — no quote available because the claim is about command exit status and empty output, which has no source snippet to quote).

Note the count is specific to `test/cc-isolated-functions.bats`; the repo's `test/` directory holds ~29 other `.bats` files, so "all 52 bats" reads correctly only as "all 52 tests in the cc-isolated suite" — which is how `c44c33a`'s message phrases it ("all 52 cc-isolated bats tests").

**Evidence:** `test/cc-isolated-functions.bats`, `devcontainer-config/init-firewall.sh`

---

## Claim 15: "Edits are in the firewall-application path after the `--print-domains` early exit; compose_domains and all 52 cc-isolated bats tests are unaffected." (commit `c44c33a` message)

**Type:** Architectural / Reference
**Location:** commit `c44c33a` message body
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** A reviewer judging the blast radius of the branch.

The early exit precedes every changed line — the diff's earliest hunk starts at line 90, and the exit is at line 59:

```bash
# devcontainer-config/init-firewall.sh:56-59
if [ "${1:-}" = "--print-domains" ]; then
  compose_domains
  exit 0
fi
```

`git diff main...HEAD -- devcontainer-config/init-firewall.sh` shows a single hunk header at `@@ -90,14 +90,75 @@`, so no line at or above 59 changed and `compose_domains` (lines 30-51) is untouched (paraphrased — no quote available because the assertion is about which line ranges the diff does *not* contain). The 52-test result is Claim 14 (verified by execution).

**Evidence:** `devcontainer-config/init-firewall.sh:56-59`, `devcontainer-config/init-firewall.sh:30-51`

---

## Claim 16: "R1 ... the DNS fail-open `else` branch was unreachable under `set -euo pipefail` ... Fix: `|| true` on the command substitution." (commit `6edaa21` message)

**Type:** Behavioral / Reference
**Location:** commit `6edaa21` message body
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** A reader auditing the review-fix loop's own record.

The diagnosis and the fix are both accurate as stated, and the fix works — the `else` branch is now reachable in all three no-IPv4 scenarios (Claim 6, executed). The imprecision is in the same-message summary of what A1 accomplished: "Fix: scope the fallback to Docker's embedded resolver 127.0.0.11, never 0.0.0.0/0." That is true about what the rule *says* but, per Claims 8 and 9, the resulting rule is inert — it cannot fire in the standard-Docker case it names, and `-o lo` would cover it anyway. The precise version is that A1 removed a real widening (the `0.0.0.0/0` TCP+UDP re-grant) and replaced it with a no-op rather than with a working fallback.

**This claim is in a commit message and is therefore immutable** — `6edaa21` is the branch tip and the text cannot be corrected without a rewrite. Flagging for the record, not as a fixable defect. The corresponding *mutable* text is the source comment (Claim 8) and the security-review doc (Claim 13), both of which can still be edited.

**Evidence:** commit `6edaa21` message body, `devcontainer-config/init-firewall.sh:126-127`, `devcontainer-config/init-firewall.sh:137-149`

---

## Claims Requiring Attention

### Incorrect
- **Claim 8** (`devcontainer-config/init-firewall.sh:138-145`): the fail-open comment claims the `127.0.0.11` fallback "preserves resolution for the standard Docker network," but the standard Docker network parses `127.0.0.11` successfully and takes the `if` branch — the fallback fires only when *no* IPv4 resolver exists, where `127.0.0.11` is by construction not the resolver. The rule is inert in every case that reaches it. Rewrite to say the fallback reopens nothing and preserves nothing, and that the IPv6-only case survives via the absence of ip6tables rules (Claim 10), not via this line.
- **Claim 13** (`docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:84-89`): the doc repeats the same non-guarantee — "while still resolving in the standard Docker case (session start can never brick)." Same correction; the rest of the doc's DNS description is accurate.

### Stale
- None.

### Mostly Accurate
- **Claim 1** (`devcontainer-config/init-firewall.sh:94-100`): the direct-exfil path is closed by the *removal* of the blanket `--dport 53` accept, not by the added scoped accepts; say so, since the scoped accepts are no-ops wherever the resolver is loopback (Claim 9).
- **Claim 12** (`devcontainer-config/init-firewall.sh:189-191` and three restatements): add two qualifiers — `iptables -F` does not reset policies, so the window is wide open only on a fresh container and is closed on a re-run; and the fixes guarded the DNS block only, leaving ~6 deliberate `exit 1` paths and ~8 unguarded commands still able to abort inside the window.
- **Claim 16** (commit `6edaa21`, immutable): A1's summary describes the fallback as a working scoped fallback when it is a no-op. Not fixable in place; the mutable equivalents are Claims 8 and 13.

### Unverifiable
- **Claim 5** (`devcontainer-config/init-firewall.sh:113-118`): the counterfactual that `iptables -d 999.999.999.999` resolves as a hostname and exits non-zero needs a root shell with `iptables`; this session has neither. The claim is moot either way — the regex rejects the value and the add is guarded.

---

## Goal-Alignment Note

**The goal this pass was given.** Verify the claims made by `6edaa21`'s *fixes* — new, never-fact-checked code — without inheriting pass 1's conclusions, testing shell and iptables semantics empirically where possible.

**How the work maps to it.** All eight enumerated focus areas were checked and appear above: octet regex and its double-quoting (Claim 4), fail-open availability (Claim 8), `-o lo` redundancy (Claim 9), Docker DNAT interaction (Claim 9's reasoning plus the note below), `|| echo` guards (Claim 7), ip6tables absence (Claim 10), the wide-open window (Claim 12), and the commit/doc claims (Claims 13-16). Pass 1's verdicts were not carried forward; the `|| true` fix was re-derived from scratch by executing the block (Claim 6) rather than assumed from R1's write-up.

**Where the method fell short of the brief, explicitly.** The brief asked for empirical testing "where you have bash" and careful reasoning where root is unavailable. Every shell-semantics claim was executed. Every netfilter-semantics claim was *not* — no root, `iptables-save` denied — and those blocks are labeled "Reasoned, not executed" with confidence dropped to Medium (Claims 9, 12) or Unverifiable (Claim 5). In particular, the brief's Claim-4 question about **Docker's embedded-DNS NAT** could not be executed and is answered by reasoning only: Docker's `DOCKER_OUTPUT` rule DNATs `127.0.0.11:53` to `127.0.0.11:<high-port>`, keeping the destination address and rewriting only the port; netfilter traverses `nat OUTPUT` before `filter OUTPUT` for a connection's first packet; therefore a `filter` rule matching `-d 127.0.0.11 --dport 53` sees the rewritten high port and **does not match**. What actually permits embedded-DNS traffic is `iptables -A OUTPUT -o lo -j ACCEPT` (`init-firewall.sh:164`), reached because the destination remains a `127.0.0.0/8` address routed out `lo`. This is a third, independent reason the `127.0.0.11` rules are no-ops, and it reinforces Claims 8 and 9 — but a reader who wants it confirmed should run `iptables-save -t nat` inside a live user-defined-network container and re-check the DNAT target port.

**Scope discipline.** Per the skill's non-goals, this report states what the code does and what the precise wording would be; it does not recommend the structural `-P OUTPUT DROP`-first fix, evaluate whether the DNS-scoping design is the right one, or judge the no-op rules as good or bad. Claim 12's inventory of unguarded exits is reported as a fact about the current window, not as a change request — `security-reviewer` owns that call.

**Hallucination log.** No entry was appended. Both Incorrect verdicts (Claims 8 and 13) are wrong *availability guarantees about a reachable-branch condition*, not fabricated symbols, methods, or APIs, so per the skill's inclusion rules they belong in this report only.
