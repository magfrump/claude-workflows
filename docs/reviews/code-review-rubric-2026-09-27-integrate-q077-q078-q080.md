Commit: d0415b1

# Code Review Rubric — integrate/q077-q078-q080

**Scope:** `git diff main...integrate/q077-q078-q080` (Q-077 auto-approve deny backstop, Q-078 report stamp, Q-080 skill descriptions). Q-076 (exit scan, cc-push) was split out by user decision at the review-loop cap and is reviewed separately.
**Status:** 0 🔴 · 0 🟡 open (2 🟡 Acknowledged with a revisit trigger) · 🟢 items deferred or won't-fix, each with an override-log row. **Mergeable.** Single-sample review; absence of findings is not an attestation.

## How this review ran
- **Fact-check (k=3, three rounds on the combined branch):** `iter1-code-fact-check-report.md` (ce6bee6), `iter2-code-fact-check-report.md` (02d14b0), iteration-3 replicates `code-fact-check-report-r1..r3.md` (a42e37f). Q-077/Q-078 Incorrects were fixed in df11830, 376a8a2 and 7dc7843; round 3 found no regressions in these items.
- **Pass 2 (Q-080 prose, k=3):** `pass2-code-fact-check-report-r1..r3.md` (02d14b0). 0 Incorrect, 1 Stale; fixed in 29f18c6 and 09ae379.
- **Critics (opus, parallel, on 795ff71):** `security-review-2026-09-27.md`, `performance-review-2026-09-27.md`, `api-consistency-review-2026-09-27.md`, `architecture-review-2026-09-27.md`, `tech-debt-triage-review-2026-09-27.md`. Fixes: 184b499 (hook), b3e2d85 (stamp), 09ae379 (skill).
- **Critic re-review:** `security-review-2026-09-27-iter2.md` (184b499). Its new F1/F2 were fixed in 85fae02. **85fae02 itself was not re-reviewed by a critic**; it carries regression tests that fail on 184b499.
- **Tests at d0415b1:** `run-tests.sh --fast` passes; `install-host.bats` 92/92. One health-check slow-suite failure (install-host T33) was environmental: a stray probe process left by a fact-check agent. The rerun is green.

## 🔴 Must Fix
None open.

## 🟡 Must Address
| ID | Finding | Source | Status |
|---|---|---|---|
| S1 | Deny loader failed open on a malformed or wrong-shaped settings file | security F1 | ✅ Fixed 184b499 |
| S2 | Deny matched quoted forms literally (`git "push"`, `git \push`, `${X:-push}`) | security F2 | ✅ Fixed 184b499 |
| S3 | Hook read `$HOME/.claude`; linker writes `${CLAUDE_CONFIG_DIR:-…}` (fail-open on bare hosts) | security F3, architecture 2 | ✅ Fixed 184b499 |
| S4 | Docs overclaimed "never approves" | security F4 | ✅ Fixed 184b499 |
| S5 | NUL inside a rule string split records: deny→allow, dropped credentials rule | security re-review F1 | ✅ Fixed 85fae02 |
| A1 | Allow and deny used two parsers with different semantics | architecture 3, api-consistency F1 | ✅ Fixed 184b499 (one parser; differences documented as a table) |
| A2 | Hook duplicates Claude Code's permission engine on an unverified premise (#39344 shows `ask`, not `allow`) | architecture 1 | 🟢 Acknowledged: override-log row; host check filed as Q-082 |
| A3 | A determined injection still spells past the credentials rule in cc-isolated | security F5 | 🟢 Acknowledged: override-log row; sandbox half filed as Q-081 |

## 🟢 Consider
| ID | Finding | Source | Status |
|---|---|---|---|
| P1 | Per-call hook latency 108→193 ms from extra jq passes | performance 1 | ✅ Fixed 184b499 (≈143→62 ms) |
| T1 | Sandbox half had no tracker once Q-077 closes | tech-debt 1 | ✅ Filed Q-081 |
| T2 | Allow and deny each listed the settings files | tech-debt 2 | ✅ Fixed 184b499 |
| C1 | Stamp had no format version; regenerate messages lacked the commit step; harness drift silent | api F9/F10, architecture 5/6 | ✅ Fixed b3e2d85 |
| C2 | architecture-review routed "→ own critics" (no skill named) | api F6 | ✅ Fixed 09ae379 |
| L1 | Low: relative CLAUDE_CONFIG_DIR / newline in settings path dropped global deny rules | security re-review F2 | ✅ Fixed 85fae02 |
| D1 | `Bash(*)`/`Bash(**)` treated alike | api F2 | Won't-Fix (override-log) |
| D2 | `--deny`/`--permissions` pairing and empty-value semantics | api F3/F4 | Won't-Fix (override-log) |
| D3 | Five phrasings of the routing line; one-way pointers | api F5/F7 | Defer (override-log) |
| D4 | pre-mortem/what-if "When to Use" heading variant | api F8 | Defer (override-log) |
| D5 | Description shape unenforced; no description↔body phrase check; stale `when:` | architecture 7, tech-debt 3 | Defer (override-log) |
| D6 | No pinning test for `Bash(rm *)` vs bare `rm` | tech-debt, api | Defer to Q-082 (override-log) |
| D7 | FIFO or /dev/zero settings path hangs the hook (fails safe) | security re-review F3 | Won't-Fix (override-log) |
| D8 | 01c40eb message: "8 edits … staled every skill's reports" (7 predate stamps) | fact-check | Accepted-immutable (override-log) |
| D9 | Hook copy baked into `devcontainer-config/claude-home/` is stale until `install.sh` reruns | api escalation | Deployment note: re-run `install.sh` after merge |

## Considered overrides
Rows 81 (deny-rule path form, Q-049) and 92/98–101 (generate-reports/runner-contract waivers) matched by file. None was re-raised: the new Bash rule avoids the `{{CLAUDE_DIR}}` token row 81 concerns, and this diff doesn't touch the waived lines.

## 🧩 Composition check
No multi-source co-located clusters qualified beyond the ones already merged above: security F3 with architecture 2, and architecture 3 with api F1 and tech-debt 2. They were treated as one finding each.

## Not verified
- #39344 / Claim 20b: whether Claude Code applies `permissions.deny` after a hook `allow` (Q-082).
- Whether Claude Code accepts the leading `*` in `Bash(*.credentials.json*)` (Q-082).
- That the shorter descriptions actually appear in the live skill listing. Only a fresh session after merge shows this.
