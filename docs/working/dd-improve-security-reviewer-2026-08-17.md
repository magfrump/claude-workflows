# DD: Improve the security-reviewer critic persona (2026-08-17)

- **Goal**: Decide how to restructure the `security-reviewer` skill so its high-failure affirmative-endorsement mode stops producing wrong Confirmed-Good rubric rows, without damaging its high-yield finding mode.
- **Project state**: review-arms persona-attribution follow-up · downstream of the decision to upgrade code-fact-check to execution-based verification (decision 033 lineage) · not blocked.
- **Task status**: complete (decision drafted; SKILL.md edits not yet applied).

## Context

Attribution analysis (`docs/working/pipeline-persona-attribution-2026-08-17.md` §2 item 3) shows security-reviewer is **bimodal**:

- **Finding mode — strong.** Sole catch of the only runtime-breaking Must Fix (csp-R1, `connect-src 'self'` breaking `fetch(dataUrl)`); 6/9 canon hits on postfix; origin of the sec-A1 bypass enumeration.
- **Endorsement mode — the most wrong of any persona.** Authored/co-signed N1 ("App Router prefetches are RSC payloads... not a bug" — wrong: prefetched documents ship CSP-less), C4 (matcher Confirmed Good), N3 (praised localhost-default removal as SSRF hardening — broke documented local-dev), D6 (cache "contains only response + usage" — false one call-site away: the non-streaming path writes prompts in plaintext).
- **Triage loss.** It FOUND N11 (dev-only flag enforceable in production), then downgraded it to Low, where it died in synthesis.

The failure shape (per the attribution doc): **partial evidence promoted to a categorical clean verdict — evidence that stops one hop short of the failure.** In both sampled reports the wrong claims live in the "What Looks Good" section or in Informational "no risk" findings, phrased categorically ("contains only", "not a bug", "correctly reflects", "safe to merge"), while the current SKILL.md's only instruction for that section is two sentences: *"Note security practices in the diff that are correctly implemented. This prevents the review from being purely negative and confirms which parts don't need rework."* — no evidence bar, no scoping rule, nothing.

**Upstream design constraint (decided):** code-fact-check is being upgraded to carry execution-based verification, feeding every critic. Candidates should compose with it — e.g., security endorsements could become claims routed to fact-check for execution rather than verdicts.

## Step 1 — Diverge

Pre-generation grep (`Pruned candidates` in `docs/decisions/*.md`, keywords: security, endorsement, critic, verify, confirm, gate):

- 017-polyglot-test-hermeticity [9]: "an LLM critic is a detector, not an enforcement primitive" — **carried forward**: whatever we add to the skill is detection/discipline, not a gate; enforcement lives in rubric synthesis (informs candidate 8's role as complement, not rival).
- 028-escalation-second-channel [7 severity-keyed softening]: pruned for keying behavior on the critic's internal severity label, "an opinion, in the least stable output dimension" — **relevant tension** with candidate 6 (severity floor); addressed in stress-test: the floor keys on a *mechanism predicate*, not on the severity label itself.
- 028 [10 dedicated soundness critic]: "mints new authority from an unvalidated judgment at a full extra dispatch" — **carried forward** against candidate 7 (split verify-pass): a second static pass is a new dispatch with the same epistemic weakness.

### Candidates

0. **Status quo** — keep SKILL.md unchanged; rely on reviewers reading endorsements skeptically.
1. **Kill "What Looks Good"** — delete the endorsement section outright; the persona only finds.
2. **Asymmetric evidence bar** — endorsements require strictly more evidence than findings: a positive claim needs execution evidence or it may not be stated; negative findings keep the current bar.
3. **Scoped-observation rewrite** — keep endorsements but ban categorical generalizations; every clean verdict must carry an explicit "Verified: \<exactly what was read\> / Not verified: \<adjacent paths\>" scope line ("contains only", "not a bug", "safe" banned without execution evidence).
4. **Endorsements-as-routed-claims** — restructure "What Looks Good" into atomic, falsifiable **endorsement claims** (decision-033 claim grammar) that are routed to the upgraded execution-based code-fact-check; security-reviewer never self-certifies Confirmed-Good — fact-check's execution verdict does or doesn't.
5. **Bypass-fixture mandate** — for every guardrail/matcher/sanitizer/filter in the diff, enumerate ≥3 candidate bypass inputs (sec-A1 style); each is traced/executed or listed under "Untested bypass candidates"; an untested guardrail cannot be endorsed.
6. **Mechanism severity floor** — a finding that names a concrete violation mechanism reachable in a supported environment (N11-class) cannot be rated below Medium; environmental unlikelihood goes in Confidence, not Severity.
7. **Split verify-mode into a separate pass** — a distinct "security-verification" critic does endorsements; the reviewer only finds.
8. **Synthesis-rule-only** — leave SKILL.md untouched; fix downstream: rubric synthesis refuses Confirmed-Good rows resting solely on a static endorsement (attribution doc recommendation 2).
9. **Embedded execution harness (ideal-if-free)** — security-reviewer itself runs the app, probes guardrails, executes every claim it endorses.
10. **Provenance tags** — minimal change: every endorsement line carries `[observed]`/`[inferred]`/`[assumed]` tags; no structural change.

Health check: lens spread OK (1/2/3 procedural-text; 4/7 topology; 6 severity policy; 8 downstream process; 9 technical-extreme; 10 minimal). Do-nothing (0), minimal (10), naive (1), ideal-if-free (9) all present. Initial draft clustered on "edit the endorsement section text" (1,2,3,10) — added 4/6/7/8 to move on the agent-set / communication-topology / triage dimensions.

## Step 2 — Diagnose

Hard:

- **H1 — wrong-endorsement elimination.** N1/C4/N3/D6-class categorical clean verdicts must be unable to reach rubric Confirmed-Good on static reading alone. `success:` replaying the four cases against the revised skill text yields, for each, either a scoped observation naming its unread hop (D6's non-streaming call-site, N1's prefetched-document response class) or a claim routed to fact-check execution — zero unscoped "Confirmed Good"/"not a bug" verdicts.
- **H2 — preserve finding yield.** The finding mode (cognitive moves, HALT escalation, severity ordering) is untouched by the change. `success:` diff to SKILL.md is confined to the endorsement/verification/severity-policy sections; a postfix-instance replay still yields ≥6/9 canon hits and the csp-R1-class Must Fix.
- **H3 — triage-loss prevention.** A found mechanism (N11-class) stays rubric-visible. `success:` N11 replay produces Severity ≥ Medium (or an explicit rubric-visible row), per the floor rule's mechanism predicate.
- **H4 — composition with upgraded fact-check.** No duplicated execution machinery; positive claims are consumable by the execution verifier. `success:` endorsement output parses as atomic claims in the decision-033 grammar (claim text + location + predicted observable), routable without reformatting.

Soft:

- **S5 — cost.** ≤ ~20% added tokens per security review; no new standing agent dispatch.
- **S6 — keep the endorsement function.** Authors still learn what doesn't need rework ("prevents the review from being purely negative").
- **S7 — works standalone.** The discipline must bind when the skill runs outside the orchestrator (N3-style praise appeared in standalone prose), i.e., live in SKILL.md, not only in synthesis.

## Step 3 — Match and prune

| # | Candidate | H1 elim | H2 yield | H3 triage | H4 compose | S5 cost | S6 keep | S7 standalone |
|---|---|---|---|---|---|---|---|---|
| 0 | status quo | ✗ | ✓ | ✗ | ✗ | ✓ | ✓ | ✗ |
| 1 | kill endorsements | ✓ | ✓ | ✗ | ✗ | ✓ | ✗ | ✓ |
| 2 | asymmetric bar | ✓ | ✓ | ✗ | ~ | ~ | ~ | ✓ |
| 3 | scoped observations | ✓ | ✓ | ✗ | ~ | ✓ | ✓ | ✓ |
| 4 | routed claims | ✓ | ✓ | ✗ | ✓ | ✓ | ✓ | ~ |
| 5 | bypass-fixture mandate | ~ (C4/N1 class only) | ✓ | ✗ | ✓ | ~ | ✓ | ✓ |
| 6 | severity floor | ✗ (orthogonal) | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 7 | split verify-pass | ~ (same static epistemics) | ✓ | ✗ | ~ | ✗ (new dispatch) | ✓ | ✗ |
| 8 | synthesis-rule-only | ~ (orchestrated runs only) | ✓ | ~ | ✓ | ✓ | ✓ | ✗ |
| 9 | embedded exec harness | ✓ | ⚠ (crowds out finding mode; duplicates fact-check) | ~ | ⚠ (duplicates upgraded fact-check) | ✗ | ✓ | ✓ |
| 10 | provenance tags | ~ (tags don't stop promotion) | ✓ | ✗ | ~ | ✓ | ✓ | ✓ |

Pruned: **0** (fails H1/H3 — the measured failure), **9** (⚠ H4: duplicates the execution machinery the upstream decision just placed in fact-check), **7** (fails S5/S7 and carries 028-[10]'s carried objection — a second static pass mints authority from the same unvalidated epistemics), **1** (fails S6 and wastes H4 — the endorsements are exactly the raw material the execution verifier wants as claims), **10** (mostly ~; tags without a promotion rule didn't stop C3/N10-style laundering for code-fact-check itself), **2** (dominated by 3+4: "asymmetric bar" is what 3+4 implement concretely; alone it under-specifies what a compliant positive statement looks like).

Survivors: **[4] [3] [6] [5] [8]**. No single candidate covers H1+H3; 3/4 are text-shape vs routing-shape of the same discipline and compose; 6 alone fixes H3; 5 covers the adversarial-guardrail slice of H1 (C4, N1); 8 is the downstream backstop. Fixable-weakness sketches: 4's S7 gap (standalone runs have no fact-check to route to) is closed by 3's scope line as the standalone fallback; 6's severity-as-opinion objection (028) is closed by keying the floor on a mechanism predicate; 8's S7 gap is closed by pairing with any skill-side candidate.

## Step 4 — Tradeoff matrix and decision

The survivors compose rather than compete, so the step-4 field is three packages:

| Approach | Effort | Risk | Coverage (hard) | Key downside |
|---|---|---|---|---|
| **A: 4+3+6 composite** (routed claims, scoped-observation fallback, mechanism floor) | ~0.5 day skill edits, +~10% review tokens | low | 4/4 | fact-check claim-queue growth (mitig. — route only would-be-Confirmed-Good claims) |
| B: 3+6 only (scoping + floor, no routing) | ~0.5 day | low-med | 3/4 (H4 ~) | scoped prose still gets hand-promoted by synthesis; wastes the execution upgrade |
| C: 8+6 only (downstream rule + floor) | ~0.25 day | med | 2/4 (H1 ~, S7 ✗) | standalone runs (N3-class praise) unprotected; skill keeps overclaiming |

Falsifiable hypotheses:

- **A**: If adopted, replaying the four wrong endorsements (N1, C4, N3, D6) against the revised skill yields zero unscoped categorical clean verdicts, and N11 replays at ≥ Medium, within the next review-arms replay cycle; counter-evidence = any of the four still emits an unscoped "Confirmed Good"/"not a bug", or postfix finding yield drops below 6/9, or review tokens grow >20%.
- B: If adopted, the four replays are scoped but ≥1 scoped observation is still promoted to Confirmed-Good by synthesis within one replay cycle (expected — this is why B loses); counter-evidence = no promotion occurs.
- C: If adopted, orchestrated-run Confirmed-Good laundering stops but a standalone run reproduces an N3-class endorsement within two standalone invocations; counter-evidence = standalone runs stay clean without skill edits.

### Stress-test pass

- **Boring alternative** (on A): is C — the quarter-day downstream rule — enough? No: N3's wrong praise was standalone prose feedback that never touched a rubric, and D6's categorical sentence is the *input* synthesis launders; fixing only the laundry leaves the false sentence in every report. C is adopted *inside* A as the backstop rule, not as the alternative.
- **Invert the thesis** ("endorsements are the problem; kill them" — candidate 1): what survives inversion is that endorsements have negative expected value *as verdicts*. But as **claims** they are positive-value: sec-A1 shows the persona's enumeration strength, and the upstream execution verifier needs exactly this claim stream. Inversion strengthens A's core move (demote verdict → claim) over 1's (delete).
- **Failure-driven** (new failure modes A enables): (i) claim-queue flooding of fact-check — mitigated: only claims that would otherwise justify a Confirmed-Good row are routed; trivia stays as scoped prose. (ii) Severity-floor inflation — Medium noise from over-broad mechanism predicate; mitigated by requiring the predicate name a *reachable environment* ("enforceable in production" qualifies; "if an attacker already owns the box" doesn't). (iii) Scope-line boilerplate rot ("Not verified: everything else") — mitigated by requiring the Not-verified line to name the *nearest unread hop* (a specific caller/path), not a generic disclaimer. Matrix updated: A's key downside marked (mitig.).
- **Revealed preferences**: the persona already writes scoped statements when it's right (the fscompat report's finding 3 correctly scoped warm-instance tenancy) — the discipline codifies its own best behavior, so compliance friction is low.

### Decision presentation

```
┌─ DECISION: stop security-reviewer's endorsement mode producing wrong Confirmed-Good rows ─┐
│ 3 packages survived step-3 pruning · scored on the step-4 axes                            │
└───────────────────────────────────────────────────────────────────────────────────────────┘

  legend   ● strong / low   ◐ partial / medium   ○ weak / high   ✗ fails hard constraint

   #   approach                    effort        risk     coverage      key downside
  ───  ─────────────────────────  ───────────   ──────   ──────────    ─────────────────────────────
   A ★ routed-claims composite     ● 0.5d+10%    ● low    ● 4/4 hard    ● claim-queue growth (mitig.)
   B   scoping + floor only        ● 0.5d        ◐ med    ◐ 3/4 hard    ◐ synthesis still launders prose
   C   downstream rule + floor     ● 0.25d       ◐ med    ○ 2/4 hard    ○ standalone runs unprotected
```

```
╭─ [A] routed-claims composite   ★ recommended ───────────────────────────────╮
│ effort    0.5 day skill edits (+~10% review tokens)     risk   low          │
│ coverage  4/4 hard · 3/3 soft                                               │
│ hypothesis  If chosen, replaying N1/C4/N3/D6 yields zero unscoped clean     │
│             verdicts and N11 replays ≥ Medium within the next review-arms   │
│             replay; counter-evidence = any unscoped "Confirmed Good", or    │
│             postfix yield <6/9, or tokens +>20%.                            │
│ stress-tests applied                                                        │
│   · boring alternative → C absorbed as backstop, rejected as substitute     │
│   · invert thesis → confirmed demote-to-claim beats delete (kills cand. 1)  │
│   · failure-driven → 3 new modes named, all mitigated (routing cap,         │
│     reachable-environment predicate, nearest-unread-hop scope line)         │
│ key downside  fact-check claim-queue growth (mitig. — route only            │
│               would-be-Confirmed-Good claims)                               │
╰─────────────────────────────────────────────────────────────────────────────╯

▶ recommend [A] routed-claims composite · confidence 88% · Path A (dominates; no prompt)
```

### Decision and rationale

**Chosen: Package A — the routed-claims composite (candidates 4 + 3 + 6, with 8 as the downstream backstop and 5 folded into the claim discipline for guardrails).** One sentence: the persona's endorsement mode is demoted from verdict-issuer to claim-generator — its positives become atomic falsifiable claims routed to the execution-upgraded code-fact-check, with mandatory read-scope lines as the standalone fallback, a mechanism severity floor so N11-class detections can't triage below visibility, and a bypass-enumeration requirement extending its sec-A1 strength to every guardrail it endorses. This eliminates exactly the measured failure (categorical static clean verdicts promoted one hop short of the failure) while preserving — and feeding — the two things it is measurably best at: finding runtime-breaking issues and enumerating bypasses.

See alternatives considered → Pruned candidates below.

## Pruned candidates and why

How to read: each entry is `[candidate-ID]: one-line reason for discard`. Future DDs in adjacent areas can grep this section to avoid regenerating already-pruned approaches.

`[0]: fails H1/H3 — the status quo is the measured failure. [1]: deletes the claim stream the execution verifier needs; fails S6. [2]: absorbed — 3+4 are the concrete implementation of the asymmetric bar. [5]: absorbed into A's claim discipline for guardrails (untested bypass candidates must be listed; untested guardrails can't be endorsed). [7]: new static dispatch with the same epistemics [carried from 028-escalation-second-channel [10]: "mints new authority from an unvalidated judgment at a full extra dispatch"]. [8]: absorbed as backstop — synthesis rule alone leaves standalone runs (N3-class) unprotected. [9]: ⚠ H4 — duplicates the execution machinery just placed in upgraded code-fact-check. [10]: tags without a promotion rule didn't stop laundering for code-fact-check's own stamps (C3/N10). [B]: scoped prose still hand-promotable; wastes the execution upgrade. [C]: standalone runs unprotected. [carried from 017-polyglot-test-hermeticity [9]: "an LLM critic is a detector, not an enforcement primitive" — the skill edits are discipline, the synthesis backstop is the enforcement seam.]`

## Stress-test mitigations

- How to read: *Failure-driven* mitigation — capped claim routing: only endorsement claims that would otherwise justify a Confirmed-Good rubric row are routed to fact-check execution; minor positives stay as scoped prose. Changed A's key downside to (mitig.).
- How to read: *Failure-driven* mitigation — severity-floor predicate requires a *reachable environment* ("enforceable in production" qualifies; attacker-already-root scenarios don't), answering 028's severity-as-opinion objection by keying on a mechanism predicate rather than the severity label.
- How to read: *Failure-driven* mitigation — the "Not verified:" scope line must name the nearest unread hop (specific caller/path, e.g. D6's non-streaming call-site), never a generic disclaimer, so scope lines can't rot into boilerplate.
- How to read: *Boring alternative* mitigation — candidate 8 (synthesis rule) adopted inside A as the enforcement backstop rather than rejected outright.

## Concrete SKILL.md change list (`~/.claude/skills/security-reviewer/SKILL.md`)

1. **Replace the "What Looks Good" section (lines 394-397).** Current text:
   > `### What Looks Good`
   > `Note security practices in the diff that are correctly implemented. This prevents the review from being purely negative and confirms which parts don't need rework.`

   Replace with `### Endorsement Claims (formerly "What Looks Good")`: each entry is an atomic, falsifiable claim in the decision-033 grammar — `claim:` text + `Location:` + `Evidence: executed | read-static` + a mandatory scope pair `Verified: <exactly the code read> / Not verified: <the nearest unread hop — a specific caller, path, or response class>`. Categorical vocabulary (**"safe"**, **"only"**, **"correct"**, **"not a bug"**, **"correctly reflects"**, **"eliminates"**) is banned on `Evidence: read-static` entries. Entries that would justify a Confirmed-Good rubric row are marked `route: code-fact-check` for execution verification; the reviewer itself never issues Confirmed-Good. (Replays: D6 becomes *"claim: cache files contain only response+usage — Verified: the write signature in cache.ts:62-69 / Not verified: caller payloads on the non-streaming path — route: code-fact-check"*; N1 becomes a routed claim about prefetched-document CSP coverage instead of "not a bug.")

2. **Add a mechanism severity floor to the "Severity guidelines" block (lines 385-390),** after the `Informational` line:
   > *Floor rule: a finding that names a concrete mechanism by which a security property can be violated in a reachable environment (e.g., a dev-only flag enforceable in production) may not be rated below **Medium**. Environmental unlikelihood belongs in **Confidence**, not Severity — downgrading a named mechanism to Low/Informational is how detections die in triage.*
   (Directly prevents the N11 loss.)

3. **Add a bypass-fixture requirement as cognitive move #11** (after move #10, line 261): for every guardrail, matcher, sanitizer, or filter the diff adds or modifies, enumerate ≥3 candidate bypass inputs; each is either traced/executed or listed under an explicit **"Untested bypass candidates"** heading. A guardrail with untested bypass candidates may not appear in Endorsement Claims. (Extends the sec-A1 strength that produced its best amber; would have blocked C4 and N1.)

4. **Amend the last "Important" bullet (lines 433-434).** Current text:
   > `- When a finding depends on context you can't see (e.g., "this is safe IF the caller always validates"), say so explicitly rather than assuming either way.`

   Extend: *The same rule binds positive statements: a clean verdict extends only to the code paths actually read. Every endorsement names what was not read. "I read the write signature" never licenses "the cache contains only X" — the caller's payload is one hop away.*

5. **Amend "Overall Assessment" (lines 404-407):** a "safe to merge" conclusion is permitted only when every Endorsement Claim is either `Evidence: executed` or explicitly scoped with its Not-verified hop named; otherwise the assessment must say *"no findings within the code paths read; endorsement claims pending execution verification."*

6. **Downstream backstop (not in SKILL.md — `code-review` orchestrator/rubric synthesis):** no Confirmed-Good rubric row may rest solely on a static endorsement or narrow fact-check stamp; it requires an executed claim verdict or explicit scope carried into the row. (Attribution doc recommendation 2; enforcement seam per 017-[9].)

## Consequences

- Easier: the upgraded fact-check gets a high-quality claim stream from the persona best at enumerating what to falsify; wrong endorsements become refuted claims (visible) instead of Confirmed-Good rows (invisible); N11-class detections survive triage.
- Harder: security reviews carry more structure per positive statement (~10% tokens); fact-check gains a claim intake it must prioritize; standalone runs without fact-check produce "pending verification" rather than comfort.

## Revisit triggers

How to read: each entry is a concrete, observable condition that should prompt re-evaluating this decision. Future readers can grep this section when their context changes.

`if a post-change review-arms replay still yields any unscoped categorical clean verdict from security-reviewer. if postfix-class finding yield drops below 6/9 after the edits. if fact-check's endorsement-claim queue exceeds ~10 claims/review or becomes the pipeline's cost driver. if the severity floor produces >2 spurious Mediums per instance. if the upgraded code-fact-check design changes such that critics no longer route claims to it.`
