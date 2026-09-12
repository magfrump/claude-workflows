# Chat Synthesis Format

Reference for the `code-review` skill. Load this file at Stage 3, before writing the chat
deliverable. Extracted from the skill body 2026-09-11 (prompt audit F8). Edit here, not in
the skill.

## Deliverable 1: Chat Synthesis

Present this directly in the chat. It should be self-contained — assume the user has NOT read the individual agent reports.

### Structure the chat synthesis as:

**Scope summary:** What was reviewed — branch, files, diff size.

### Considered overrides

Surface every row collected as `<considered-overrides>` in Step 3.5. For each match, list:

- the override's `PR ref` and `Date`,
- the finding it applied to (with `path/to/file:line`),
- the `Original verdict → Override verdict` shorthand, and
- the `Reason` recorded by the prior reviewer.

Then, for each, state whether the current run's finding (if any) **inherits** the prior call, **departs** from it (and why), or is **not applicable** (different code, same location coincidentally). If a critic surfaced a finding that matches a prior `Won't-Fix` override and you are still flagging it as Must-Fix, explain the delta — new evidence, scope change, or you believe the prior call was wrong. Re-arguing a settled call without acknowledging it is the failure mode this section exists to prevent.

If Step 3.5 found no matching rows, render the section with the single line: "No prior overrides matched this diff." The heading must still appear so absence is auditable across runs.

### Coverage and Escalations

Surface the items collected in the Goal-alignment scan above so the user sees coverage limits before reading findings:

- For each sub-agent that answered `no` or `partial`: list the agent name and the
  one-phrase reason.
- For each non-trivial `Out of scope:` bullet: list the agent name and what was set
  aside.
- For each non-trivial `Escalate:` bullet: list the agent name and what the
  orchestrator should action separately.

If the scan surfaced nothing, render this section with a single line: "All sub-agents fully addressed their scope; no out-of-scope or escalate items." The heading must still appear so the section is auditable across runs.

**Factual issues:** What the code fact-check found. Group into: claims that need fixing (Incorrect), claims that need updating (Stale, Mostly Accurate), and claims that are solid (Verified).

**Cross-critic findings:** Highest signal. Issues raised independently by 2+ critics targeting the same code region or overlapping concern. These indicate structural problems that manifest across multiple dimensions (e.g., a pattern that's both a security risk and a performance problem). Convergence detection is semantic — same file region plus overlapping concern — not mechanical keyword matching.

**Per-domain findings:** Organize remaining findings by severity within each critic domain. Lead with Critical/High, then Medium, then Low/Informational.

**Contextual critic findings:** If contextual critics ran, present their findings separately as advisory input. These inform but do not block.

**What the code gets right:** Strengths the pipeline actually established — verified endorsement claims (Stage-2.5 verdicts) and critics' scoped endorsements presented with their `Verified / Not verified` scope. Critics no longer write free-form "What Looks Good" praise; do not launder a routed-but-unverified claim into a strength — label it *pending execution verification*. The author needs to know what to preserve during revisions.

**Failure-mode escalation:** Count the distinct new failure modes named across critic findings — the per-finding failure-mode phrase that `for-author` findings already carry per the [orchestrated-review pattern](../../../patterns/orchestrated-review.md#legibility-target-tagging) (location, evidence, attack scenario or failure mode where applicable, recommendation). Dedupe overlapping concerns in the same code region to a single mode so the count tracks distinct modes, not finding multiplicity. If >=3 new failure modes are flagged, recommend `/pre-mortem` on the diff for narrative analysis; include the recommendation in the Chat Synthesis. The recommendation is advisory — the user decides whether to invoke `/pre-mortem`, not the orchestrator. The >=3 threshold is intentionally conservative to avoid escalation fatigue: at that count, independent failure modes start to suggest coupling and ordering between them that a narrative pre-mortem surfaces but per-critic flags miss. Below the threshold, the per-critic flags already carry the signal and a separate pre-mortem pass would be redundant.

**Actionable guidance:** Key changes to make, ordered by severity. Where multiple critics agree, note the convergence.

**Questions to clarify (if any sub-agent emitted them):** Scan each sub-agent's Goal-Alignment Note for the optional "Questions I would have asked" bullet. If one or more sub-agents emitted questions, surface them under a `### Questions to clarify` heading near the end of the chat synthesis, just before "Actionable guidance" or as a sibling subsection. De-duplicate: if multiple sub-agents asked semantically the same question, list it once and note the agreement (multiple sub-agents asking the same question is a strong signal that the prompt was under-specified). Attribute each question to the sub-agent that raised it. If no sub-agent emitted the bullet, omit the section entirely — do not invent placeholder questions.

Worked example:

> ### Questions to clarify
>
> Two sub-agents flagged that scope was ambiguous:
>
> - **Should the scripts under `scripts/migrations/` be in scope?** *(security-reviewer,
>   performance-reviewer — both flagged independently.)* Both agents reviewed them; if
>   you intended to exclude one-shot migration scripts, re-run with `--files` narrowed to
>   `src/`.
> - **Is the experimental `src/feature-flags/` directory production code or a sandbox?**
>   *(api-consistency-reviewer.)* The critic treated it as production and flagged a
>   breaking change in `flags.ts:42`; mark this as 🟢 Consider if it's sandbox-only.

**Recommended next action (required final line):** End the chat synthesis with this exact line so the user always sees a concrete next step:

> Recommended next action: [merge | fix red items then re-review | split PR | escalate to /pre-mortem | block on architectural review].

**Single-sample label (required when the run is clean):** when the derivation below lands
on `merge`, or the rubric status is `✅ PASSES REVIEW`, the line immediately *above*
`Recommended next action:` must read exactly:

> Single-sample review; absence of findings is not an attestation.

This is the same standing label the rubric status line carries (see
[The single-sample label](rubric.md#the-single-sample-label)) and it is the whole of the hedging —
one line, no elaboration. Omit it entirely on any other next action: a review that already
tells the author to fix things is not being consumed as assurance.

Choose exactly one bracketed value. The choice is **mechanically derived from the rubric** per [Next-action derivation](#next-action-derivation) below — it is not a free-form judgment call, and the line must not hedge or list multiple options. The line is required even when the rubric is clean (rule 5 still applies). If the derivation ladder ever needs new rules, update the ladder first so the mapping stays the single source of truth.

#### Next-action derivation

Evaluate the rules top-to-bottom; the first matching rule wins. Inputs are the rubric the synthesis just produced (counts of 🔴 / 🟡 rows and which critics ran, including the `## ⏭️ Skipped Core Critics` section) and the diff size from `git diff --stat`.

1. **block on architectural review** — Either: (a) Step 5 auto-selected
   `architecture-review` but it did not produce a report this run (excluded via
   `--exclude architecture-review`, failed, or otherwise skipped), or
   (b) architecture-review ran and produced ≥1 🔴 Structural finding.
   Architectural questions are a wider conversation than a line-fix — rerun with
   architecture-review enabled, or address the structural finding in a separate
   design pass before any other action.
2. **split PR** — Total diff is >500 changed lines (added + removed per
   `git diff --stat`) AND ≥1 🔴 item exists (and rule 1 did not match). Large
   diffs combined with red findings multiply review risk per iteration; split
   before iterating on fixes.
3. **escalate to /pre-mortem** — 🔴 items span 3+ distinct critic domains (e.g.,
   security + performance + api-consistency), OR ≥3 🔴 items total. Systemic
   risk — invoke the `pre-mortem` skill before attempting line-level fixes,
   because the failure mode is likely architectural rather than a sum of
   independent defects.
4. **fix red items then re-review** — ≥1 🔴 item exists (and rules 1–3 did not
   match), OR 0 🔴 but >2 🟡 items are open without author notes resolving them.
   The label covers the general non-merge fix path; amber-heavy reviews land
   here because resolving the load through inline notes alone is impractical.
5. **merge** — 0 🔴 items AND ≤2 🟡 items. Rubric status is either
   ✅ PASSES REVIEW or a low-friction 🟡 CONDITIONAL PASS where amber items can
   be resolved with inline author notes during merge prep.

**Worked examples:**

- 0 🔴, 0 🟡 → rule 5 → `Recommended next action: merge.`
- 0 🔴, 1 🟡 → rule 5 → `Recommended next action: merge.`
- 0 🔴, 4 🟡 → rule 4 (>2 amber, no red) → `Recommended next action: fix red items then re-review.`
- 2 🔴 both in security, 200-line diff → rule 4 → `Recommended next action: fix red items then re-review.`
- 1 🔴 in security, 800-line diff → rule 2 → `Recommended next action: split PR.`
- 1 🔴 security + 1 🔴 performance + 1 🔴 api-consistency, 300-line diff → rule 3 (3 domains) → `Recommended next action: escalate to /pre-mortem.`
- 4 🔴 all in security, 200-line diff → rule 3 (≥3 reds total) → `Recommended next action: escalate to /pre-mortem.`
- 1 🔴 from architecture-review tagged Structural → rule 1 → `Recommended next action: block on architectural review.`
- Diff adds a new module; architecture-review excluded via `--exclude` → rule 1 → `Recommended next action: block on architectural review.`

**How to use legibility-target tags during synthesis:** Findings tagged `for-author` are the primary content of the chat synthesis and the rubric's 🔴 / 🟡 / 🟢 tiers. Findings tagged `for-orchestrator-synthesis` feed your reasoning — coverage maps, convergence detection, "what got reviewed" — but do not get repeated verbatim in the chat output. Findings tagged `for-automated-gate` drive the rubric status line and any escalation blocks; they are referenced once (not duplicated as prose bullets) and link to the source critique. If a critic tagged everything `for-author`, note that in your synthesis as a calibration gap rather than treating it as signal.
