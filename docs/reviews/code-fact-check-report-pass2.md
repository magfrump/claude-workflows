# Code Fact-Check Report

**Commit:** 6edaa21
**Replication:** k=3
**Scope:** `devcontainer-config/init-firewall.sh` (branch `harden/cc-isolated-egress`, pass 2)
**Date:** 2026-08-29
**Total claims checked:** 16 (merged across replicates; 11–16 per replicate)

Merged most-severe-wins from `code-fact-check-report-pass2-r{1,2,3}.md`. Pass 2 targeted the
claims introduced by pass 1's *fixes* — code no critic had yet seen.

## Claim 1: The DNS fail-open fallback "preserves resolution for the standard Docker network"

**Verdict:** Incorrect
**Confidence:** High
**Location:** `devcontainer-config/init-firewall.sh:141-148` (at 6edaa21)
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect

The `else` branch pinned `127.0.0.11`, but it fires **only** when no IPv4 resolver parsed —
and `127.0.0.11` is itself a valid IPv4 the octet regex accepts. Had it been the resolver, the
`if` branch would have been taken and the `else` never reached. The fallback was therefore
**inert in every reachable case**, and the stated availability guarantee described a situation
that cannot coexist with the branch executing. r3 additionally noted "a `--dns` override" is a
misattributed trigger, since that writes a parseable IPv4 address. All three replicates
verified by simulating the block against synthetic resolv.conf fixtures with a stubbed
`iptables`; the orchestrator independently confirmed `127.0.0.11` passes the regex.

**Resolution:** FIXED. The branch now installs no rules and fails closed, with a comment
enumerating why that is safe (IPv6 unfiltered / loopback via `-o lo` / host-/24 accept).

## Claim 2: The security-review doc repeats the same false fallback guarantee

**Verdict:** Incorrect · **Confidence:** High · **Legibility-target:** for-author
**Location:** `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:84-89`
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect

Verbatim inheritance of Claim 1. **Resolution:** FIXED (doc rewritten to describe fail-closed).

## Claim 3: "The octet alternation is a real 0–255 match"

**Verdict:** Verified · **Confidence:** High · **Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

Exhaustively tested (r2 swept 0–300 with zero false accepts/rejects). Both shell-quoting
concerns resolved: the trailing `$` before the closing double quote remains a literal anchor,
and `\.` survives double-quoting. Rejects `256.1.1.1`, `999.999.999.999`, `1.2.3`, `01.2.3.4`,
IPv6, and whitespace variants.

## Claim 4: `|| true` makes the fail-open branch reachable (pass 1's R1 is genuinely fixed)

**Verdict:** Verified · **Confidence:** High · **Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

r1 and r3 reproduced both directions: with `|| true` the branch is reached and the script
exits 0; removing that one token reproduces the pass-1 abort.

## Claim 5: The `|| echo` guards prevent an abort under `set -e`

**Verdict:** Verified · **Confidence:** High · **Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

Tested with a failing `iptables` stub: warning printed, compound status 0, script survives.

## Claim 6: The scoped DNS rules are what deliver the hardening

**Verdict:** Mostly Accurate · **Confidence:** High · **Legibility-target:** for-author
**Location:** `init-firewall.sh:94-103`
**Replicate verdicts:** r1=Mostly Accurate · r2=Mostly Accurate · r3=Mostly Accurate

The security gain comes from **deleting** the old blanket `--dport 53` accept, not from adding
the scoped rules. Where the resolver is loopback or in the host /24, `-o lo` and the
`HOST_NETWORK` accept already admit it, so the added rules are redundant no-ops — and Docker's
`DOCKER_OUTPUT` DNAT rewrites `127.0.0.11:53` to a high port in nat OUTPUT (which runs before
filter OUTPUT), so a `--dport 53` filter rule cannot match embedded-DNS traffic anyway. The
rules are load-bearing only for a resolver outside both sets — which *is* this deployment
(`nameserver 192.168.65.7`). Not theater, but the mechanism was mis-emphasized.

**Resolution:** FIXED (a PRECISION paragraph now states exactly this).

## Claim 7: The post-flush/pre-DROP "wide-open window"

**Verdict:** Mostly Accurate · **Confidence:** High · **Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly Accurate · r2=Mostly Accurate · r3=Mostly Accurate

Two precisions the comments omitted: `iptables -F` does **not** reset policies, so the window
is wide open only on a **fresh** container (a re-run inherits the prior DROP and fails closed);
and the fixes guarded only the DNS block — five to six explicit `exit 1` paths plus two bare
command substitutions under `pipefail` (`gh_ranges=$(curl…)`, `ips=$(dig…)`, the same
construct as pass 1's R1) remained unguarded inside it.

**Resolution:** FIXED structurally — network reads moved before the flush (phase A), DROP
policies moved to immediately after it, `|| true` added to both substitutions, and a
completion-sentinel EXIT trap added so any incomplete run ends at DROP.

## Claim 8: "SSH to allowlisted hosts (all of GitHub) still works"

**Verdict:** Mostly Accurate · **Confidence:** High · **Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly Accurate · r2=Verified · r3=Verified

The SSH mechanism is verified; "all of GitHub" is overstated — only `.web + .api + .git` are
ingested, not `actions`/`packages`/`pages`/`codespaces`. GitHub's SSH endpoints are in `.git`,
so the SSH claim itself holds. **Resolution:** FIXED (comment now names the three keys).

## Claim 9: "`node` … cannot write /etc/resolv.conf"

**Verdict:** Unverifiable · **Confidence:** Medium · **Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly Accurate · r2=Unverifiable · r3=Unverifiable

The NOPASSWD-sudo half is verified against the Dockerfile; the ownership half is a Docker
runtime default that nothing in this repo enforces or asserts.
**Resolution:** FIXED (comment reframed as an unasserted runtime default).

## Claim 10: `6edaa21`'s "all 52 bats pass; shellcheck clean"

**Verdict:** Verified · **Confidence:** High · **Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

Reproduced at 6edaa21: `1..52`, 52 ok, 0 not ok; shellcheck exit 0.

## Claim 11: "this script has no ip6tables rules"

**Verdict:** Verified · **Confidence:** High · **Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

Confirmed. Consequence flagged by all three: the **entire** allowlist, not just DNS, is
unenforced over IPv6. Recorded as a residual risk in the threat-model doc.

## Immutable-history items (not tiered)

`6edaa21`'s commit message describes the A1 fix as producing a working scoped fallback; it
produced a no-op. The commit cannot be edited without a rewrite; the mutable equivalents
(Claims 1 and 2) are fixed. Routed here rather than raised as a blocking finding, per the
immutable-history exception.

## Verdict stability

Merged clusters: 11. Clusters where all reporting replicates agreed: 11. Disagreements: 0 —
including unanimous Incorrect on both defects and unanimous Mostly Accurate on all three
precision items. Agreement rate: **11/11 (100%)**. Combined with pass 1's 5/5, cumulative
agreement across this branch is 16/16 on a 16-claim sample.

Replicate-only detections worth noting (the recall argument for k>1): r1 alone surfaced the
"all of GitHub" overstatement (Claim 8) and the two bare command substitutions by line number;
r2 alone identified this deployment's actual non-loopback resolver, which established that the
scoped rules are load-bearing here rather than inert; r3 alone caught the `--dns override`
misattribution and that `iptables -F` does not itself set policies to ACCEPT. Most-severe-wins
merged all three.

## Goal-Alignment Note
- Answered: yes — all claims introduced by pass 1's fixes were checked against the code.
- Out of scope: kernel/netfilter semantics (no root in this environment; reasoned and labelled).
- Escalate: nothing — both Incorrects fixed and re-verified; precision items folded into comments.
