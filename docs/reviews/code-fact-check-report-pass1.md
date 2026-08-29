# Code Fact-Check Report

**Commit:** c44c33a
**Replication:** k=3
**Scope:** `devcontainer-config/init-firewall.sh` (+ companion doc `security-review-cc-isolated-egress-2026-08-29.md`)
**Date:** 2026-08-29
**Total claims checked:** 11 (merged across replicates)

Merged most-severe-wins from `code-fact-check-report-r{1,2,3}.md`. All three replicates
ran byte-identical briefs and converged on one material defect (now fixed).

## Claim 1: DNS fail-open branch is reachable and "never bricks session start"

**Verdict:** Incorrect
**Confidence:** High
**Location:** `devcontainer-config/init-firewall.sh:113-125` (as committed at c44c33a); companion doc lines 82-86
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect

Under `set -euo pipefail`, the bare assignment `dns_resolvers="$(awk … | grep -E … | sort -u)"`
propagates the pipeline's exit status to `set -e`. `grep` exits 1 on zero matches, so when no
IPv4 nameserver parses the script **aborts at the assignment** — before the `if`/`else` is
evaluated, making the documented fail-open `else` branch unreachable dead code. The abort lands
after the `iptables -F` flush but before `-P OUTPUT DROP`, i.e. the container is left wide open
AND session start breaks — the exact opposite of the comment's "fails open … never bricks."
All three replicates reproduced this empirically (missing resolv.conf and no-nameserver cases
both abort with exit 1; `pipefail` isolated as the trigger). The orchestrator independently
reproduced it as well.

**Resolution:** FIXED in working tree — appended `|| true` to the command substitution so a
zero-match grep yields an empty string and the fail-open branch becomes reachable. Verified:
no-resolver case now reaches the branch and the script exits 0.

## Claim 2: SSH to GitHub still works after removing the blanket `--dport 22` accept

**Verdict:** Verified
**Confidence:** High
**Location:** `devcontainer-config/init-firewall.sh` (allowed-domains dst-match + GitHub CIDR block + ESTABLISHED,RELATED)
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

GitHub CIDRs from `api.github.com/meta` are added unconditionally to the `allowed-domains`
ipset; `-A OUTPUT -m set --match-set allowed-domains dst -j ACCEPT` matches destination IP on
any port (including 22); the general `ESTABLISHED,RELATED` accepts cover the return path. The
removed inbound `--sport 22 --state ESTABLISHED` rule was redundant with the general INPUT
ESTABLISHED accept. No setup step (postStartCommand, self-probe) depends on outbound SSH.

## Claim 3: DNS rules are added before the default `-P OUTPUT DROP` policy

**Verdict:** Verified · **Confidence:** High · **Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claim 4: Companion-doc mechanism claims (IP-not-SNI matching, GitHub CIDRs always-on, `host.docker.internal` opens all host ports, 52 bats tests unaffected)

**Verdict:** Verified · **Confidence:** High · **Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

Doc's `host.docker.internal` claim confirmed against `egress/llm.txt`; GitHub-CIDR-always-on
against the meta-fetch block (no profile gate); IP/dst-not-SNI matching against the
`--match-set allowed-domains dst` rule. `rg -c '^@test'` on the bats file = 52.

## Verdict stability

Total clusters: ~5 semantic clusters across the three replicates. All reporting replicates
**agreed** on every cluster — including unanimous Incorrect on the one defect (Claim 1).
Agreement rate: 5/5 (100%) on this sample. The lone blocking finding was corroborated by an
independent orchestrator-run reproduction.

## Goal-Alignment Note
- Answered: yes — all high-weight comment/doc claims checked against the code that exercises them.
- Out of scope: none.
- Escalate: nothing — the one behavioral Incorrect was fixed and re-verified in-loop.
