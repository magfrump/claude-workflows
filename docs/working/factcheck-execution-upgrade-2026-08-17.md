# Upgrading code-fact-check to carry runtime falsification (2026-08-17)

**Status**: design assessment, pending author decision. Companion to
`pipeline-persona-attribution-2026-08-17.md` (which proposed a separate
runtime-falsification critic) and the three `dd-improve-*-2026-08-17.md` records.

## Why the author's framing is right

The attribution analysis proposed a new "runtime-falsification critic." The
author's counter — upgrade `code-fact-check` instead and feed the results to the
other critics — is structurally better, for three reasons:

1. **The distribution channel already exists.** Every critic already receives the
   fact-check report as its foundation ("do not re-verify documented behavior"),
   and the skill's quoted-evidence rule explicitly names `security-reviewer` /
   `performance-reviewer` as consumers. A new critic would need a new channel;
   upgrading fact-check reuses the highest-leverage seam in the pipeline.
2. **The failure mode lives in fact-check's output contract.** Of the wrong
   Confirmed-Good rows, most trace to a fact-check `Verified (High)` stamp being
   promoted beyond its scope (C3, N10, N11, secdeps Claim 8, C4, N8). Fixing the
   stamp fixes the laundering at the source; a new critic would leave the bad
   stamps in circulation.
3. **Thematic fit.** Fact-check is already falsificationist about *text*; the
   missed classes (executable guarantees, env-contract claims, silent error
   paths) are claims like any other — they just require running things. The
   current skill even acknowledges this boundary: its "Not a runtime tester"
   non-goal routes such claims to Unverifiable. The upgrade converts that
   dead-end into the pipeline's execution arm.

What the upgrade does NOT cover (residual gaps a fact-check can't fill):
adversarial bypass probing of guardrails (sec-A1/C2/C4-class — there is no
*claim* to check, only an implied guarantee; this stays with security-reviewer),
and severity-triage losses (N11, D5, N12 — a synthesis-rule problem). The
persona DDs address those.

## Concrete changes to `code-fact-check/SKILL.md`

1. **New evidence tier: Executed.** Add `**Verification mode:** static |
   executed` as a required per-claim field. `executed` requires provenance:
   exact command, cwd, exit code, timestamp, and raw output captured to a file
   referenced from the report (no more "(no output — exit 0)" prose claims —
   the N2 lesson). Time-varying inputs (advisory databases, registries, network
   services) must be named with an as-of timestamp, and the verdict carries a
   staleness warning ("true as of the audit DB at <time>").
2. **Mandatory-execution rule.** A claim whose subject is an *executable
   guarantee* — a CI/lint/build command behaving some way, a script or gate
   passing, a dev workflow functioning, an env-var default's runtime effect, a
   documented reproduction — MUST be executed when the sandbox permits.
   Static reading caps such a claim's verdict at **Unverifiable (execution
   required)**; it can never be `Verified` from reading alone. This single rule
   would have flipped C3 (run `next build`, inspect the bundle), N10 (unset the
   var, hit the route), secdeps Claim 8 (add a `.cjs` fixture, run lint), C1
   (start `next dev`), N2 (run the gate, capture output), N3 (follow the
   documented docker-compose flow).
3. **Scope line on every verdict.** Required field: one sentence stating what
   the verdict covers *and what it does not establish* (e.g. "covers the
   sanitizer's mapping table; does not establish that all persistence paths
   invoke the sanitizer" — the N8 laundering). Paired rubric-side rule: a
   Confirmed-Good row may only assert what some report's scope line covers.
4. **Second intake: endorsement claims from critics.** Critics' would-be
   "What Looks Good" assertions are submitted to fact-check as claims (a
   `## Submitted claims` section) instead of self-certified. Fact-check verdicts
   them under the same rules — including mandatory execution where applicable.
   This is the "give the results to the other critics" flow run in both
   directions, and it is how the security/performance DD outcomes compose.
5. **Error-path sweep prompt.** Add to the checkable-claim taxonomy: implicit
   fail-loudly/fail-silently claims — any comment or doc asserting an error is
   handled, surfaced, sanitized, or cached invites tracing the actual error
   path (who observes the failure?). This targets the N4/N5/N12/N13/N14 class,
   which is claim-shaped ("sanitizer keeps persisted state correct") more often
   than it first appears.
6. **Retire the "Not a runtime tester" non-goal**, replacing it with: "Runtime
   verification is in scope when the claim's subject is executable in the
   review sandbox; claims requiring external systems or production state remain
   Unverifiable."

## Cost and risk

Execution adds wall-clock and sandbox complexity (network-restricted runs can't
audit registries — those verdicts stay Unverifiable-with-reason rather than
falsely Verified, which is still an improvement). Scale by the existing
adaptation-latitude clause: execution depth follows claim criticality, with
gates/builds/lints cheap and full env simulations reserved for Must-Fix-adjacent
claims. Evidence from the arms: the E7r2 built-in review ran this playbook at
$5–18/instance; a fact-check-scoped version is strictly smaller.

## Interaction with the persona DDs

The three DD records (`dd-improve-{performance-reviewer,dependency-upgrade,
security-reviewer}-2026-08-17.md`) were commissioned under this design as a
constraint: no persona duplicates execution-verification; execution centralizes
here, personas submit claims and consume verdicts.
