# Pipeline persona attribution: who finds what, who vouches wrong (2026-08-17)

**Question**: can pipeline findings be credited to specific critic personas; do any
personas have bad track records; is there a coherent persona that would cover the
newly surfaced (pipeline-missed) issues?
**Evidence**: per-critic reports + rubric Source/Domain columns for all 8 canon
instances (`external/meta-formalism-copilot/docs/reviews/` for the 7 dirty
instances — corpus at the top level — and
`runs/review-arms/mfc-2026-08-06/groundtruth/` for postfix). Three attribution
agents, session 2026-08-17; ledger frame: 56-row ledger.

## 1. Attribution is fully recoverable

Every rubric carries a Domain/Source column and the individual critic reports
survive, so all 33 pipeline-found rows credit cleanly. Aggregate:

| Persona | Ran on | Sole-source rows | Co-source rows | Noise profile |
|---|---|---|---|---|
| **api-consistency** | 8/8 | csp-A1, lean-A1, hyg-A1, fsc-A2, cor-A1 | csp-A3/R2/A4, lean-R1/R2, hyg-R1, sec-R1/A1, dep-R1/R2, fsc-R1/A1, cor-A2, pf-A1/A2/A4/A6/A8 | best hit-rate of any persona; 16/16 findings→rubric rows in the secdeps/deploy/fscompat set; ~zero noise |
| **code-fact-check** | 8/8 | csp-R2, hyg-R1 (origin), dep-R1, fsc-R1, fsc-A1 (origins) | csp-A2/A3, lean-R1, dep-R2, cor-A3/A4, pf-A1/A3/A5/A7/A8 | verdicts reliable **within claim-vs-text scope**; the danger is downstream laundering (see §2) |
| **security** | 8/8 | csp-R1 (the only runtime-breaking Must Fix) | csp-A2, sec-R1/A1 (bypass enumeration origin), hyg-R1 (seeded), 6/9 postfix rows | bimodal: real catches + the most wrong endorsements (§2) |
| **architecture** | corpus, postfix only | pf-R1 (sole structural-root catch) | cor-A2/A4, pf-A1/A3/A4/A8 | highest hit density where present (4/5 postfix findings→canon) |
| **performance** | 8/8 | fsc-A3 | lean-R2, csp-A3 (commentary), pf-A5 | ~1 substantive row/instance at best; 0 in hygiene, deploy, corpus ambers |
| **test-strategy** | csp, fscompat only | csp-A4, fsc-A4 (its single recommended test each time) | — | 2-for-2 when present; its explicit waivers sit exactly on later misses |
| **dependency-upgrade** | secdeps only | C7 | — | owns the worst single verdict (§2) |
| **tech-debt-triage** | corpus only | — | cor-A3 | detects mechanisms (D5, N12) then defers them to green |
| **ui-visual** | lean, postfix | — | pf-A6 (co) | polish; ~0 ledger overlap |

Convergence matters: the escalated red/amber rows are mostly 2–4-critic
convergences (pf-A1 four-way; sec-R1 security+api; lean-R2
performance+api). The single-critic sole catches concentrate in api-consistency
(contract seams) and security (csp-R1).

## 2. Bad track records

Ranked by damage. The recurring shape (spotted by the secdeps agent): **partial
evidence promoted to a categorical clean verdict — evidence that stops one hop
short of the failure.**

1. **performance-reviewer — worst overall.** Lowest ledger yield per finding AND
   four provably false affirmative endorsements across four instances:
   - lean: "no risk of `unavailable` accumulating in persisted blobs" (falsified by N8);
   - fscompat: "hashing computed once, not called twice per request" (false — `getCachedResult` recomputes internally; it cited the exact lines);
   - corpus: blob writes "debounced by zustand's own middleware" (false premise, directly contradicted by tech-debt's report in the same round; excused D5);
   - deploy: restated the `/tmp` mechanism fact-check had just refuted as Incorrect, as its own analysis.
   Its signature failure is the confident "this is free / already handled" note.
2. **dependency-upgrade — worst single incident.** For N2 it *printed a purported
   execution* of the audit gate ("exit 0, no output") that is unreproducible (the
   gate exits 1 with 5 high advisories); that claimed run became two Confirmed
   Good rows, including the ledger's "gate passes" row. Fabricated-or-stale
   execution evidence under a clean verdict.
3. **security-reviewer — bimodal.** Authored or co-signed the majority of wrong
   Confirmed-Good endorsements: N1 ("prefetches are RSC payloads... not a bug"),
   C4 (matcher Confirmed Good, co-signed), N3 (praised the localhost-default
   removal as SSRF hardening), D6 (cache "contains only response + usage" —
   false for the non-streaming path, which writes prompts in plaintext; it read
   the write signature but not the caller's payload). Also **found N11 and then
   downgraded it to Low** — a triage loss, not a detection loss.
4. **code-fact-check — reliable stamps, dangerous laundering.** Its
   High-confidence Verified verdicts on narrow claim-vs-text checks repeatedly
   became rubric Confirmed-Good rows covering behavior it never tested: C3 (quoted
   the defective `process.env?.` line verbatim and stamped Verified High), N10
   (Verified twice), N11 (verified the DEV-ONLY docstring), secdeps Claim 8
   ("lint passes therefore the rule loads" — true only because no `.cjs` exists
   yet), plus the csp matcher (C4) and lean persistence (N8) stamps.

Also structural, not persona-level: **two detected-then-lost rows** (N11 by
security, D5/N12 by tech-debt-triage) died in severity triage/synthesis, and
test-strategy's explicit waivers ("matcher not worth a test", prod-only manual
checklist, "cache misses are recoverable") sit exactly on C4, C1, and N6.

## 3. The coherent persona for the new issues

Classifying the 23 pipeline-missed rows (C1–C4, D1–D6, graduated N1–N5/N8–N15;
candidates N6/N16 fit too):

| Cluster | Rows |
|---|---|
| Fail-silent / fail-open error paths ("who observes this failure?") | D2, N4, N5, N11, N12, N13, N14 |
| Environment-contract mismatches (dev server, CI, build, deploy target actually exercised) | C1, C3, N2, N3, N9, N10, (N16) |
| State lifecycle / persistence seams (rehydration, races, sanitizer bypass) | D3, D5, N8, (N6) |
| Adversarial probing of guardrails/matchers with bypass inputs | C2, C4, D1, N1 |
| Runtime reach of policy on real content | N15 (+ csp-R1's class) |

Common denominator: **every one is a claim about runtime behavior in a specific
environment, and every pipeline persona is a static reader of the diff.** All 23
were findable by starting the thing, running the gate, feeding the bypass input,
or killing the process mid-write — which is exactly how the CC arms found them
(E5/E7 ran npm audit, lint fixtures, the dev server, compiled the matcher).

The coherent persona is an **execution-based falsificationist** — a hostile
operator / code-level pre-mortem: treats every guarantee in the diff (comment,
gate, matcher, sanitizer, cache, documented workflow) as a hypothesis to refute
by execution, and walks every error path asking what a user observes when it
fires. E7r2's adversarial-verifier machinery *is* this persona, and it cuts both
ways: the same pass that would have caught these 23 also refuted N7 and the
csp-A1 here-and-now break — it kills false ledger rows too.

**Recommendations** (pending author decision):
1. Add a runtime-falsification critic to the `code-review` orchestrator with a
   four-move mandate: execute every executable claim; enumerate silent error
   paths; probe each new guardrail with bypass fixtures; trace
   persistence/rehydration lifecycles.
2. Rubric synthesis rule: no Confirmed-Good row may rest solely on a static
   endorsement or a narrow fact-check stamp — categorical clean verdicts require
   execution evidence or must be scoped to what was actually checked (the
   one-hop-short promotions produced C4, N1, N2, N8, N10, D6).
3. Revisit severity-triage: a detected mechanism (N11, D5, N12) should not be
   green-tier-able on remit grounds alone.
