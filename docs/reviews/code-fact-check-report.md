# Code Fact-Check Report

**Repository:** claude-workflows (`/workspace`), branch `harden/cc-isolated-egress`
**Scope:** `devcontainer-config/init-firewall.sh` and the claims its comments and companion docs make. Pass 2 of a review-fix loop, checked at commit `6edaa21`; defects found here are fixed at `5ec95c5`.
**Checked:** 2026-08-29
**Commit:** 6edaa21
**Replication:** k=3
**Total claims checked:** 11
**Summary:** 5 verified, 3 mostly accurate, 2 incorrect, 1 unverifiable, 0 stale.

Merged most-severe-wins from `code-fact-check-report-pass2-r1.md`, `-r2.md`, `-r3.md`
(byte-identical briefs). Pass 2 targeted the claims introduced by pass 1's *fixes* — code no
critic had yet seen. The pass-1 merged report is retained at `code-fact-check-report-pass1.md`.

## Claim 1: The DNS fail-open fallback "preserves resolution for the standard Docker network"

**Location:** `devcontainer-config/init-firewall.sh:141`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Evidence:** `devcontainer-config/init-firewall.sh:141` — the `else` branch pinned `127.0.0.11`, but it is reached only when `$dns_resolvers` is empty, and `127.0.0.11` is itself matched by the octet regex at `devcontainer-config/init-firewall.sh:125`.
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect

The branch fires only when no IPv4 resolver parsed. Had `127.0.0.11` been the resolver, the
`if` branch would have been taken and the `else` never reached, so the fallback was inert in
every reachable case and the stated availability guarantee described a situation that cannot
coexist with the branch executing. All three replicates verified by simulating the block
against synthetic `resolv.conf` fixtures with a stubbed `iptables`. Resolved at `5ec95c5`: the
branch now installs no rules and fails closed.

## Claim 2: The security-review doc repeats the same fallback guarantee

**Location:** `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:84`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Evidence:** `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:84` — "while still resolving in the standard Docker case", inherited verbatim from the comment in Claim 1.
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect

Resolved at `5ec95c5`: the doc now describes the fail-closed behavior that ships.

## Claim 3: "The octet alternation is a real 0–255 match, not a shape check"

**Location:** `devcontainer-config/init-firewall.sh:125`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Evidence:** `devcontainer-config/init-firewall.sh:125` — `octet='(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])'`; r2 swept inputs 0–300 exhaustively with zero false accepts or rejects.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

Both shell-quoting concerns were checked and are unfounded: the trailing `$` before a closing
double quote remains a literal anchor, and `\.` survives double-quoting. Rejects `256.1.1.1`,
`999.999.999.999`, `1.2.3`, `01.2.3.4`, IPv6 literals, and whitespace variants.

## Claim 4: The trailing `|| true` makes the empty-resolver branch reachable

**Location:** `devcontainer-config/init-firewall.sh:127`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Evidence:** `devcontainer-config/init-firewall.sh:127` — `| sort -u || true)`; r1 and r3 reproduced both directions, confirming that removing the token restores the pass-1 abort.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claim 5: The `|| echo` guards prevent an abort under `set -e`

**Location:** `devcontainer-config/init-firewall.sh:134`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Evidence:** `devcontainer-config/init-firewall.sh:134` — tested with a failing `iptables` stub: the warning prints, the compound command's status is 0, and the script survives.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claim 6: The scoped DNS rules are what deliver the hardening

**Location:** `devcontainer-config/init-firewall.sh:99`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** `devcontainer-config/init-firewall.sh:164` — `iptables -A OUTPUT -o lo -j ACCEPT` already admits loopback unconditionally, so the scoped rules are redundant wherever the resolver is loopback or inside the host /24.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate

The security gain comes from deleting the old blanket `--dport 53` accept, not from adding the
scoped rules. Docker's `DOCKER_OUTPUT` DNAT also rewrites `127.0.0.11:53` to a high port in
nat OUTPUT, which runs before filter OUTPUT, so a `--dport 53` filter rule cannot match
embedded-DNS traffic. The scoped rules are load-bearing only for a resolver outside both sets,
which is this deployment (`nameserver 192.168.65.7`). Resolved at `5ec95c5` by a precision
paragraph stating exactly this.

## Claim 7: The post-flush, pre-DROP interval leaves the container wide open

**Location:** `devcontainer-config/init-firewall.sh:108`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** `devcontainer-config/init-firewall.sh:108` — `iptables -F` does not reset chain policies, so a re-run inherits the prior `DROP` and the interval is closed; only a fresh container starts at the all-ACCEPT default.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate

Two precisions the comments omitted: the interval is wide open only on a fresh container, and
the pass-1 fixes guarded the DNS block alone — five to six explicit `exit 1` paths plus two
bare command substitutions under `pipefail` remained unguarded inside it. Resolved at
`5ec95c5` by moving every network read ahead of the flush and the DROP policies immediately
after it.

## Claim 8: "SSH to allowlisted hosts (all of GitHub) still works"

**Location:** `devcontainer-config/init-firewall.sh:152`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** `devcontainer-config/init-firewall.sh:193` — only `(.web + .api + .git)` are ingested from the meta endpoint, not `actions`, `packages`, `pages`, or `codespaces`.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified

The SSH mechanism itself is verified; "all of GitHub" overstates the ingested ranges. GitHub's
SSH endpoints are inside `.git`, so the operative claim holds. Resolved at `5ec95c5`.

## Claim 9: "`node` cannot write /etc/resolv.conf"

**Location:** `devcontainer-config/init-firewall.sh:105`
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Evidence:** `devcontainer-config/Dockerfile` — the NOPASSWD sudo grant is confirmed, but no file in `devcontainer-config/` asserts or enforces `resolv.conf` ownership.
**Replicate verdicts:** r1=Mostly accurate · r2=Unverifiable · r3=Unverifiable

Root ownership is a Docker runtime default that this repository neither sets nor checks.
Resolved at `5ec95c5` by reframing the comment as an unasserted runtime default.

## Claim 10: Commit `6edaa21` claims "all 52 bats pass; shellcheck clean"

**Location:** commit `6edaa21` message, verification paragraph
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Evidence:** reproduced at that commit — `1..52` with 52 `ok` and 0 `not ok`; `shellcheck` exits 0 with no diagnostics.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claim 11: "This script has no ip6tables rules"

**Location:** `devcontainer-config/init-firewall.sh:1`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Evidence:** `devcontainer-config/init-firewall.sh` — a search for `ip6tables` across the file returns no matches.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

The consequence, flagged independently by all three replicates: the entire allowlist, not only
DNS, is unenforced over IPv6. Recorded as an accepted residual risk rather than fixed here.

## Claims Requiring Attention

### Incorrect

- **Claim 1** — `devcontainer-config/init-firewall.sh:141`: the `127.0.0.11` fail-open fallback
  was inert in every case that could reach it. Fixed at `5ec95c5`.
- **Claim 2** — `docs/reviews/security-review-cc-isolated-egress-2026-08-29.md:84`: the same
  guarantee, inherited verbatim. Fixed at `5ec95c5`.

### Mostly Accurate

- **Claim 6** — the hardening comes from removing the blanket accept, not from the scoped rules.
- **Claim 7** — the open interval applies to a fresh container only, and the pass-1 guards
  covered the DNS block alone.
- **Claim 8** — "all of GitHub" overstates the three ingested range keys.

### Unverifiable

- **Claim 9** — `resolv.conf` ownership is a runtime default this repository does not assert.

## Verdict stability

Merged clusters: 11. Clusters where all reporting replicates agreed: 11. Disagreements: 0.
Agreement rate: **11/11 (100%)**. Combined with pass 1's 5/5, cumulative agreement on this
branch is 16/16.

Replicate-only detections, which is the recall argument for k>1: r1 alone surfaced Claim 8 and
located the two bare command substitutions; r2 alone identified this deployment's non-loopback
resolver, establishing that the scoped rules are load-bearing here rather than inert; r3 alone
caught that `iptables -F` does not itself set policies to ACCEPT. Most-severe-wins merged all
three.

## Goal-Alignment Note
- Answered: yes — every claim introduced by pass 1's fixes was checked against the code that exercises it.
- Out of scope: kernel and netfilter semantics (DNAT ordering, `-F` versus `-P`, loopback routing) — no root or `iptables` in this environment; those claims are reasoned and labelled as such.
- Escalate: nothing — both Incorrect verdicts are fixed and re-verified; the precision items are folded into comments.
