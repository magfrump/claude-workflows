# Security Review — cc-isolated egress hardening, round-3 (pass 2)

Commit: 6edaa21 + working-tree pass-2 fixes

**User goal:** Pass 2 of a review-fix loop on the `devcontainer-config/init-firewall.sh`
firewall boundary, before a local merge. The round-3 (uncommitted) edits — a
`fail_closed_on_abort` EXIT trap, a fail-closed DNS `else` branch, and `|| true` on the
`curl`/`dig` command substitutions — are the primary target. Threat model: a compromised
in-container Claude Code agent (user `node`, holding NOPASSWD sudo for exactly this
script) trying to exfiltrate data or reach an attacker host.

**Scope:** `devcontainer-config/init-firewall.sh` (whole file, current working-tree
state), read against `devcontainer-config/Dockerfile`, `devcontainer.json`,
`cc-isolated.sh`, `egress/*.txt`.
**Date:** 2026-08-29
**Based on:** the unanimous k=3 code-fact-check (`docs/reviews/code-fact-check-report-pass2-r{1,2,3}.md`)
and pass 1 (`docs/reviews/security-review-cc-isolated-egress-2026-08-29.md`). Facts
established there (octet regex is a true 0–255 match; `|| echo` guards do not abort under
`set -e`; `-o lo` already admits loopback and Docker's embedded DNS is DNAT'd off port 53
before filter OUTPUT; `iptables -F` does not reset policies) are taken as given and not
re-verified.

Three claims in this review were verified empirically in this session with a stubbed
script rather than argued from documentation; the transcripts are quoted inline (F2, and
the fix sketch under it).

## Trust Boundary Map

```
B1 (new emphasis): [in-container agent, node]  → [NOPASSWD sudo re-run of init-firewall.sh] → [bootstrap window: empty chains, inherited policy]  → [host net / Internet]
B2:                [/etc/resolv.conf]          → [awk + 0–255 octet regex]                   → [OUTPUT --dport 53 ACCEPT rules]
B3:                [api.github.com/meta JSON]  → [`-z` check + jq shape check + CIDR regex]  → [allowed-domains ipset]
B4:                [DNS A records for profile domains] → [IPv4 regex]                        → [allowed-domains ipset]
B5 (new):          [script abort / signal / kill] → [EXIT trap fail_closed_on_abort]         → [iptables default policies: DROP vs ACCEPT]
B6:                [any host that can reach the container] → [INPUT chain, `--sport 53` blanket accept] → [in-container processes]
```

The round-3 diff adds B5 outright and changes what B1 means: the script now has an
explicit, documented position that the post-flush/pre-DROP region is a wide-open window
that must never be *left* open. That position is right, and the trap is a real
improvement. But the boundary that governs the window is the script's own control flow,
and control flow is partly reachable by the very principal the boundary exists to contain
— `node` can invoke this script at will through sudo. Nothing in the diff makes the
resolv.conf trust assumption (B2) worse; the fail-closed `else` makes it strictly better.

---

## Findings

#### The bootstrap window is agent-triggerable on demand, and the trap does not narrow it

**Severity:** High
**Location:** `devcontainer-config/init-firewall.sh:73-99` (the trap and its rationale), `:102-107` (flush), `:222-250` (the fetch that runs inside the window)
**Boundary:** B1, B5
**Move:** #5 (invert the access control model) / #3 (check the error path)
**Confidence:** High (mechanism), Medium (that the owner considers it in scope)

The round-3 comment frames the post-flush window as an inherent bootstrap cost and
addresses only what happens if the script *aborts* inside it. The window itself is
untouched, and it is not a rare fresh-container event — it is reachable **on demand by
the agent**:

```
node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh          # Dockerfile:398
```

A compromised session runs `sudo /usr/local/bin/init-firewall.sh`, and from
`iptables -F` (`:102`) until `iptables -P OUTPUT DROP` (`:301`) the OUTPUT chain is empty
with the policy inherited from the previous successful run — DROP on a re-run, so this is
*not* the fresh-container fail-open case the trap fixes. Verbatim from `:102-107` and
`:299-301`:

```
iptables -F
iptables -X
...
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP
```

On a **re-run** the inherited DROP policy makes the window closed, not open — which is
why this is not Critical. The exposure is the **fresh-container first run**, which is
exactly the case the trap was written for, and which the trap covers only for the abort
path: during a *successful* first run there are seconds-to-minutes (see F5) of
policy-ACCEPT, empty-chain, unrestricted egress, and the launcher's own probe
(`cc-isolated.sh:252`) runs only *after* the script completes. Combined with F2 below,
that transient state can be made permanent.

**Recommendation:** stop relying on the inherited policy. Immediately after the flush, set
`-P INPUT/OUTPUT/FORWARD DROP`, then install an explicit *narrow bootstrap* allowlist —
`-o lo`, the scoped resolver `:53` rules (already computed at that point), ESTABLISHED,
RELATED, and a temporary accept for the A records of `api.github.com` only — then fetch
`/meta` and build the ipset, then delete the temporary rule. This shrinks the window from
"everything, all ports" to "DNS + api.github.com", both of which the finished firewall
permits anyway, so the net new exposure is ~zero. It also fixes F4 as a side effect.

#### The EXIT trap does not fail closed when the script is terminated by a signal

**Severity:** High
**Location:** `devcontainer-config/init-firewall.sh:89-99`
**Boundary:** B5
**Move:** #3 (check the error path, not just the happy path)
**Confidence:** High — verified empirically

`local rc=$?` captures the right status for `set -e` aborts and explicit `exit N`
(verified: `exit 7` → `rc=7`, `false` under `set -e` → `rc=1`, and the original status
propagates in both cases). It does **not** capture a nonzero status when bash is
terminated by SIGTERM/SIGINT/SIGHUP. Bash *does* run the EXIT trap in that case, but `$?`
inside the handler is the status of the last *completed* command — 0 — so the
`if [ "$rc" -ne 0 ]` guard is false and **no DROP policy is installed**:

```
$ cat t4.sh
#!/bin/bash
set -euo pipefail
f(){ local rc=$?; if [ "$rc" -ne 0 ]; then echo "TRAP: DROP (rc=$rc)"; else echo "TRAP: NO-OP rc=0 -> LEFT OPEN"; fi; }
trap f EXIT
true
sleep 30
$ ./t4.sh & sleep 0.4; kill -TERM $!; wait
TRAP: NO-OP rc=0 -> LEFT OPEN
exit=143
```

So on a fresh container, a Ctrl-C at the host during a slow startup, a `devcontainer up`
timeout, a `docker stop` racing the postStart command, or an agent that kills its own
`sudo init-firewall.sh` mid-window, all land in precisely the state the trap exists to
prevent: chains flushed, policy ACCEPT, container wide open — and now *persistently* so,
because the script is no longer running to finish the job. The script's own comment
(`:73-81`) asserts the opposite: "any abort in that region … would leave the container
with NO rules and an ACCEPT policy" is presented as the thing the trap fixes, but signal
aborts are still in that state. This is the mechanism that turns F1's transient window
into an indefinite one.

Mitigating context: the launcher's egress probe (`cc-isolated.sh:252-256`) would catch
the open container on the next `cc-isolated` invocation and re-assert the firewall before
starting Claude, so a *subsequent* session does not begin in the open state. The exposure
is the interval before that, and any in-container process still alive across it.

**Recommendation:** two changes, both verified working together:

1. Convert terminating signals into shell exits so the EXIT trap sees a nonzero status:
   `trap 'exit 130' INT; trap 'exit 143' TERM; trap 'exit 129' HUP` installed alongside
   the EXIT trap.
2. Better, and strictly more robust than testing `$?` at all: add a completion sentinel.
   Set `FIREWALL_COMPLETE=0` before the flush, `FIREWALL_COMPLETE=1` on the last line
   after the verification probes, and make the trap force DROP unless
   `[ "$rc" -eq 0 ] && [ "$FIREWALL_COMPLETE" -eq 1 ]`. This fails closed on *any* path
   that did not run to completion, including future exit-0-but-incomplete paths, rather
   than on the specific ones `$?` happens to report.

Verified:

```
trap 'exit 130' INT; trap 'exit 143' TERM; trap 'exit 129' HUP
trap f EXIT   # f drops unless rc==0 && DONE==1
→ SIGTERM mid-run: "SENTINEL-TRAP: DROP (rc=143 done=0)", exit=143
```

#### A fail-open region survives *before* the trap is installed, and its comment claims otherwise

**Severity:** Medium
**Location:** `devcontainer-config/init-firewall.sh:61-71` (comment and pre-trap code), trap installed at `:99`
**Boundary:** B5
**Move:** #3 (error path) / #1 (trust boundaries — where the guarantee starts)
**Confidence:** High

Everything from `set -e` (`:20`) to the `trap … EXIT` (`:99`) runs unprotected. Three
reachable aborts live there: `compose_domains` returning 1 on an unknown profile
(`:45-46`, propagated to `set -e` through the assignment at `:63`), the empty-allowlist
`exit 1` (`:64-67`), and `iptables-save` failing at `:71` (the `|| true` covers grep's
no-match, not a missing/erroring `iptables-save`). The comment at `:61-62` justifies this
placement:

```
# Only the firewall path needs root; composing the list does not. Fail before
# flushing anything if the profile is bad, so a typo can't leave us wide open.
```

That reasoning is wrong for the case the trap was added to address. On a **fresh**
container, "not flushing" does not leave the container closed — it leaves it in Docker's
default all-ACCEPT state, i.e. exactly as wide open as a flush would. Aborting before the
flush is only safe on a *re-run*, where the previous run's DROP policies persist. So the
diff's central insight ("a fresh container starts open, so aborting early is not safe")
was applied to the post-flush region but not to the pre-flush region that has the same
property.

**Recommendation:** move `trap fail_closed_on_abort EXIT` up to immediately after the
`--print-domains` early exit (after `:59`), so it covers profile composition and the
`iptables-save` capture too. It must stay *after* the `--print-domains` block — that path
runs unprivileged in the bats suite and must keep exiting 0 without touching iptables.
Correct the `:61-62` comment to say the pre-flush position is safe only on a re-run.

#### Failing fully closed makes a transient failure permanently unrecoverable in place

**Severity:** Medium
**Location:** `devcontainer-config/init-firewall.sh:89-99` interacting with `:102` and `:228`; `cc-isolated.sh:410-413`
**Boundary:** B5
**Move:** #3 (what state is the system in after failure)
**Confidence:** High

This is the direct answer to "is there a case where failing fully closed is worse than
the status quo." Yes, on availability — and it is a new consequence of the trap.

Because `iptables -F` does not reset policies, a container whose run aborted now carries
`-P OUTPUT DROP` with **empty chains** into every subsequent run. The next run flushes,
enters the bootstrap window with a DROP policy and no accepts, and
`curl -s https://api.github.com/meta` (`:228`) cannot connect → empty → `exit 1` (`:231`)
→ trap → still DROP. The script can never bootstrap again. Recovery requires a root
`iptables -P OUTPUT ACCEPT` inside the container or
`devcontainer up --remove-existing-container`.

Before round 3 this brick existed only for containers that had previously succeeded; the
trap extends it to the fresh-container first run, so a single transient GitHub `/meta`
5xx or a DNS blip now bricks a brand-new container. `cc-isolated.sh:412` re-asserts by
re-running the same script and will loop into the same failure — and note its exit status
is unchecked there, so the failure surfaces only as the subsequent probe's behavior.

**Recommendation:** the F1 fix resolves this: if the script installs its own explicit
bootstrap allowlist (lo + resolvers:53 + ESTABLISHED + api.github.com) after setting the
DROP policies, bootstrap succeeds regardless of the inherited policy, making the script
self-healing *and* the window narrow. One change, both problems. Absent that, at minimum
have `cc-isolated.sh:412` report the non-zero status and print the recovery command.

#### No timeouts on `curl` or `dig` — the wide-open window has no upper bound

**Severity:** Medium
**Location:** `devcontainer-config/init-firewall.sh:228`, `:258`
**Boundary:** B1, B3, B4
**Move:** #8 ("what if there are a million of these" — here, unbounded duration rather than count)
**Confidence:** High

```
gh_ranges=$(curl -s https://api.github.com/meta || true)
...
ips=$(dig +noall +answer A "$domain" | awk '$4 == "A" {print $5}' || true)
```

`curl -s` has no `--max-time` (unlike the two verification probes at `:315`/`:323`, which
correctly use `--connect-timeout 5`), and `dig` has no `+time`/`+tries`, so it defaults to
5s × 3 tries × N resolvers per domain. The composed allowlist is ~20+ domains. A black-holed
resolver or a hung TCP connection therefore stretches F1's ACCEPT-policy window from
seconds to minutes on a fresh container — and the duration is influenced by network
conditions an attacker who already controls a name in the profile could affect.

**Recommendation:** `curl -s --max-time 20 --connect-timeout 5` and
`dig +time=2 +tries=1`. Both fail into error paths that already exist and already fail
closed.

#### Blanket inbound `--sport 53` accept bypasses the INPUT DROP policy

**Severity:** Low
**Location:** `devcontainer-config/init-firewall.sh:200-201`
**Boundary:** B6
**Move:** #5 (invert the access control model)
**Confidence:** High (redundancy), Medium (reachability)

```
# Allow inbound DNS responses
iptables -A INPUT -p udp --sport 53 -j ACCEPT
```

Round 1 scoped *outbound* 53 to configured resolvers and (per pass 1) deleted the SSH
rule's inbound companion, but this inbound rule kept its `0.0.0.0/0` source. It is now
redundant: legitimate DNS replies to the scoped OUTPUT accepts are covered by
`iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT` (`:304`). What it adds
is an unsolicited-inbound path — any host that can address the container and sets source
port 53 gets through the INPUT DROP policy, which is a one-way command channel to an
already-compromised in-container process. Reachability is limited: the container is behind
Docker NAT and `devcontainer.json` publishes no ports, so realistically this means the
host and other containers on the bridge (which the `HOST_NETWORK` accept at `:295` already
admits anyway).

**Recommendation:** delete the rule, or scope it `-s "$ns"` inside the resolver loop for
symmetry with the outbound rules. Deleting is cleaner — ESTABLISHED,RELATED already covers
the legitimate case. Test the delete against a container whose resolver is non-loopback
before shipping.

#### The trap's `iptables` calls are unverified and take no xtables lock wait

**Severity:** Low
**Location:** `devcontainer-config/init-firewall.sh:94-96`
**Boundary:** B5
**Move:** #3 (error path)
**Confidence:** Medium

```
iptables -P OUTPUT DROP || true
iptables -P INPUT DROP || true
iptables -P FORWARD DROP || true
```

The `|| true` is correct — the trap must not itself abort — but it means the last-resort
fail-closed action can silently not happen. The realistic cause is xtables lock
contention (`Another app is currently holding the xtables lock`); no call in this script
uses `-w`. If it loses that race, the container stays open and the only signal is the
message the trap already printed, which claims the DROP was applied.

**Recommendation:** `iptables -w 5 -P OUTPUT DROP` and, after all three, re-read
`iptables -S | head -3` (or `iptables -L -n | head`) and print a distinct
`ERROR: could not force DROP policy — container may be OPEN` if the policy is not DROP.
An unactionable failure is still worth making loud when it is the last line of defence.

#### The new `|| true`s do not weaken anything

**Severity:** Informational
**Location:** `devcontainer-config/init-firewall.sh:228`, `:258`
**Boundary:** B3, B4
**Move:** #3 (error path)
**Confidence:** High

Assessed as asked, and clean. Both make an existing `if [ -z … ]` handler reachable
instead of dead. Nothing is silently swallowed that mattered:

- **curl:** a failed transfer (including a TLS verification failure) produces empty
  output → `-z` → `exit 1`. A non-2xx or captive-portal response yields a *non-empty* body
  that passes `-z` — but `curl -s` already exits 0 in that case, so `|| true` changes
  nothing there, and the `jq -e '.web and .api and .git'` shape check at `:234` is the
  real guard. It is adequate: a proxy's HTML error page fails it.
- **dig:** `pipefail` propagates dig's status through the `awk` pipe; `|| true` swallows
  it and the `-z` branch then applies the intended warn-and-skip (or the
  `api.anthropic.com` hard fail). A skipped domain stays *blocked*, i.e. the safe
  direction.

The only status now lost is the distinction between "resolved nothing" and "resolver
unreachable", which the warning text does not report. That is a diagnosability nit, not a
security one; adding `+time`/`+tries` (F5) matters more.

#### The DNS `else` branch: fail-closed is the right call, and the enumeration holds

**Severity:** Informational
**Location:** `devcontainer-config/init-firewall.sh:174-199`
**Boundary:** B2
**Move:** #5 (enumerate what the check does not cover)
**Confidence:** Medium-High

Assessed as asked. Installing no rules is correct, and the reasoning in the comment is
sound: reaching the branch means nothing in `resolv.conf` parsed as IPv4, so by
construction there is no address that is both safe and useful to name; the two candidates
are a `0.0.0.0/0` accept (re-grants the exact channel being removed) and `127.0.0.11`
(inert, since it parses as valid IPv4 and would have taken the `if` branch). Both
rejections are right.

I looked for a fourth reachable case beyond IPv6-only / loopback / host-/24 and did not
find one that breaks legitimate resolution:

- `nameserver` naming a hostname, or an IPv4-mapped IPv6 literal (`::ffff:8.8.8.8`) —
  the actual traffic is IPv6 or already broken; IPv6 is unfiltered, so resolution is
  unaffected.
- `/etc/resolv.conf` missing or unreadable (`awk 2>/dev/null` → empty) — the container
  cannot resolve regardless of firewall rules; failing closed adds nothing.
- A resolver on a *different* subnet than the default-route /24 (a user-defined Docker
  network with a DNS sidecar, or a corporate resolver at `10.x` behind a `172.17.x`
  gateway) — this is the interesting one, but it takes the **`if`** branch, not the
  `else`, because such an address parses fine. It is the case the scoped rules are
  load-bearing for, which matches the comment's PRECISION note.

What genuinely remains is a malformed `resolv.conf` naming a non-loopback IPv4 resolver
in a form the regex rejects — a broken configuration that should fail loudly. The
three-line warning does that. No change recommended.

---

## What Looks Good

- **The trap's core design is right, and the two hard questions in the brief check out.**
  `local rc=$?` captures the correct status for `set -e` and explicit-`exit` paths
  (verified: `exit 7` → `rc=7`), the trap does not call `exit` so the original status
  propagates (verified: script exit stays 7 / 1), all three `iptables` calls are guarded
  so the handler cannot abort under `set -e`, and it is idempotent on the success path.
  The `--print-domains` early exit at `:56-59` precedes the trap, so the bats suite is
  genuinely untouched.
- **Forcing `INPUT DROP` on abort does not lock the launcher out.** `devcontainer exec`
  is `docker exec` — the runtime creates the process directly in the namespace and
  proxies stdio over its own fds; nothing traverses the container's `INPUT` chain. Every
  check in `probe_boundary` (`cc-isolated.sh:232-323`) is either a local filesystem/git
  assertion or a *negative* egress assertion, so all of them still work — and pass —
  against a fully-DROP container. `devcontainer.json` publishes no ports, so no inbound
  path is lost either. `FORWARD DROP` is a no-op in a container namespace that routes
  nothing. (Corollary worth knowing: because the probes pass against a fully-closed
  container, the launcher cannot distinguish "configured" from "aborted closed" — which
  makes the trap comment's claim at `:87-88` that "the launcher's probe still sees the
  failure" true only for the `postStartCommand` `&&`, not for the re-assert path at
  `cc-isolated.sh:412`, where the status is unchecked. Worth correcting the comment.)
- **The fail-closed DNS `else` and its comment** are a clear improvement over the
  `127.0.0.11` pin, and the comment now documents the load-bearing precision (the win is
  the *deletion* of the blanket accept; the scoped rules matter only for a resolver
  outside loopback and the host /24). Accurate.
- **`aggregate -q` / `jq` failure in the process substitution at `:250`** is not caught by
  `pipefail` (separate process), but it fails safe: the loop reads nothing, the ipset
  gets no GitHub ranges, and the `api.github.com/zen` verification probe at `:323` fails →
  `exit 1` → trap → closed. Correct by luck rather than by design, but correct.
- **The build-time boundary discipline around this script** — root-owned
  `/etc/cc-egress-profile`, `env_reset` under sudo, root-owned toolchains, the
  image-provenance probe — is coherent and is what keeps the sudo grant from being a
  self-service widening primitive.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Bootstrap window is agent-triggerable; trap narrows abort, not the window | High | B1, B5 | `init-firewall.sh:73-99,102-107,222-250` | High |
| 2 | EXIT trap sees `rc=0` on SIGTERM/INT/HUP → does not fail closed | High | B5 | `init-firewall.sh:89-99` | High |
| 3 | Fail-open region before the trap is installed; `:61-62` comment wrong for fresh containers | Medium | B5 | `init-firewall.sh:61-71`, trap at `:99` | High |
| 4 | Fail-closed abort permanently bricks bootstrap (DROP policy + empty chains) | Medium | B5 | `init-firewall.sh:89-99,102,228`; `cc-isolated.sh:410-413` | High |
| 5 | No `--max-time` / `+time,+tries` → unbounded open window | Medium | B1, B3, B4 | `init-firewall.sh:228,258` | High |
| 6 | Blanket inbound `--sport 53` accept bypasses INPUT DROP; redundant with ESTABLISHED | Low | B6 | `init-firewall.sh:200-201` | High / Med |
| 7 | Trap's `iptables -P` calls unverified, no `-w` | Low | B5 | `init-firewall.sh:94-96` | Medium |
| 8 | New `|| true`s weaken nothing (assessed) | Informational | B3, B4 | `init-firewall.sh:228,258` | High |
| 9 | DNS `else` fail-closed is right; enumeration complete (assessed) | Informational | B2 | `init-firewall.sh:174-199` | Med-High |

## Overall Assessment

Round 3 moves the boundary in the right direction and the reasoning behind it is sound —
the fail-closed DNS `else` is unambiguously better than the inert `127.0.0.11` pin, the
`|| true`s resurrect error paths without swallowing anything that mattered, and the trap
is a correct answer to a real fresh-container fail-open hole. Nothing in the diff makes
the boundary weaker, and the two design questions the brief flagged as risky (does
`INPUT DROP` lock out the launcher; is the `else` enumeration complete) both come out
clean on inspection.

The problem is that the trap's guarantee is narrower than the comment claims, in two
directions that matter: it does not cover signal termination (F2, verified — `$?` is 0 in
the handler, so no DROP is installed on exactly the Ctrl-C-during-startup case a human
will hit), and it does not cover the region before its own installation (F3), where the
comment's stated rationale is actively wrong for a fresh container. Fix those two and the
trap does what it says. The larger observation, which is not a regression but is the thing
the round-3 framing obscures, is that the bootstrap window is not merely an accident of
first boot — `node`'s NOPASSWD sudo makes it reachable on demand (F1), and the absence of
timeouts (F5) makes its duration unbounded. The single most valuable change is the one
that resolves F1, F4 and F5 together: set the DROP policies immediately after the flush
and install a deliberate, narrow bootstrap allowlist (lo + scoped resolvers:53 +
ESTABLISHED + the A records of `api.github.com`) instead of relying on whatever policy the
container happened to inherit. That makes the window narrow, makes the script self-healing
after a failed run instead of permanently bricked, and reduces the trap from a load-bearing
control to the belt-and-braces it should be.

All findings are fixable in place; none indicate an architectural problem with the
approach. Do not merge without F2 — it defeats the stated purpose of the change the merge
is for.

## Goal-Alignment Note

The stated goal was pass 2 of a review-fix loop on the round-3 firewall edits before a
local merge, with the EXIT trap, the fail-closed DNS `else`, and the new `|| true`s as
the named focus and the SSH removal explicitly out of scope. This review answers each of
those directly: the trap is analyzed for status capture, signal behaviour, `set -e`
interaction, `--print-domains` interaction, launcher lockout, and the "is closed ever
worse" question (F2, F4, and the What-Looks-Good entry); the `else` branch is assessed for
completeness including a search for a fourth case (F9); the `|| true`s are assessed and
cleared (F8). The SSH removal was not re-litigated. Two findings (F1, F6) reach slightly
beyond the round-3 diff into adjacent pre-existing structure — included because the brief
asked whether "the overall boundary is now coherent" and because F1 is the context that
determines how much the new trap actually buys. F6 is pre-existing and Low; it is
reported, not escalated. No findings were manufactured: F8 and F9 are recorded as clean
rather than padded into problems.
