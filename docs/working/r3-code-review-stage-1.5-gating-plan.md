# R3 — code-review Stage 1.5 critic-gating plan

## Problem

The orchestrator currently has two critic-selection mechanisms in `skills/code-review.md`:

1. **Step 4 (pre-Stage-1, diff-shape-based)** — auto-selects *contextual* critics (test-strategy, dependency-upgrade, tech-debt-triage, ui-visual-review) by inspecting the diff file list and content (line 150-163).
2. **"Core critic relevance check" (post-Stage-1, mixed-signals)** — added by R1 (commit `a2ba60b`); allows skipping core critics (security/perf/api-consistency) when the diff is unambiguously out of their domain. Uses *diff signals primarily*, with fact-check findings as a "run anyway" override (lines 271-306).

The existing flow conflates two concerns. R1's gate is structurally an extension of the diff-shape selector (Step 4), but applied after Stage 1 and to core critics. The fact-check report — actual evidence about what's *in* the diff that critics would examine — is consulted only as an override, not as a primary signal.

## Goal

Reframe the post-Stage-1 down-selection as **Stage 1.5: Evidence-based critic gating**, explicitly positioned as the second of two gates:

- **First gate** (R1 / Step 4 / start of "Core critic relevance check"): pre-Stage-1, *diff-shape-based*. Examines the diff file list and content to determine which critics' domains are clearly absent.
- **Second gate** (this round): post-Stage-1, *evidence-based*. Examines the fact-check report to determine which critics' domains had no corroborating evidence surfaced by Stage 1. If fact-check found no claims/code in a critic's domain, downgrade that critic from "always run" to "skip with one-line note."

The boring version: **consult fact-check to optionally downgrade critics, do not re-derive the critic set from scratch.** The set entering Stage 1.5 is whatever survived Step 4 selection + the first gate's diff-shape skips + user overrides; Stage 1.5 only narrows it further on absence-of-evidence grounds.

## What the new section does (and does not) do

**Does:**
- Run after the Fact-Check Gate, before launching critics.
- For each *remaining* core critic, identify its domain heuristic (security: auth/crypto/I/O/input/serialization; performance: hot paths/queries/loops/data-structure changes; api-consistency: exports/schemas/contracts/CLI flags).
- Cross-reference the fact-check report: did Stage 1 surface *any* claim — at any verdict — that touches that domain? Did the diff (which fact-check scoped over) contain any relevant files?
- If the answer is unambiguously no, downgrade the critic to "skip with one-line note" recorded in the rubric's existing `## ⏭️ Skipped Core Critics` section.
- Default to "run." Skipping is conservative; the cost of running an extra critic is small.

**Does not:**
- Re-derive the critic set from scratch. Step 4 + first gate already established the candidate set; Stage 1.5 only downgrades.
- Promote critics. If Step 4 didn't select a contextual critic, Stage 1.5 doesn't add it. If the first gate skipped a core critic, Stage 1.5 doesn't reverse that.
- Apply to contextual critics. Contextual critics are already evidence-selected at Step 4 (they only run when their diff trigger fired); applying a second evidence gate would double-filter them.
- Override `--all-critics` or `--include`/`--only` user flags.

## Authoring approach

The existing "Core critic relevance check" already contains all the operational machinery (skip table, override conditions, logging in rubric). Rather than duplicate it, I will:

1. **Rename the section** to `### Stage 1.5: Critic gating` so it has a numbered stage anchor matching the 1 / 2 / 3 vocabulary used elsewhere in the file.
2. **Add a short preamble** explicitly stating the two-gate framing: first gate (diff-shape, pre-Stage-1, Step 4 + the skip-table portion) and second gate (evidence-based, post-Stage-1, the new "consult fact-check" step).
3. **Add a new "Evidence consultation" subsection** that articulates the new behavior: examine fact-check findings; downgrade critics whose domain had no corroborating evidence. Position it *before* the existing skip table so evidence-based gating is the lead signal, with diff-shape skips as a complementary mechanism.
4. **Keep the existing skip table** (R1's contribution) as the operational complement. Note that fact-check evidence overrides the diff-shape skip (already true), and absence of fact-check evidence reinforces it.
5. **Keep the existing logging requirements** in the rubric's `⏭️ Skipped Core Critics` section. Skipped critics from either signal land in the same place.
6. **Keep `--all-critics` semantics**: it disables both signals (entire Stage 1.5 is bypassed when `--all-critics` is set).

## Out of scope

- Restructuring the Step 4 contextual-critic auto-selection.
- Adding a new evidence override to contextual critics.
- Changing the rubric format or escalation rule.
- Promoting/inflating any critic (Stage 1.5 only downgrades).
- Adding new fact-check verdict tags or domain taxonomy. The "domain heuristic" for each critic is the same as the existing skip-table's "Run anyway when" column — auth/crypto/IO/input for security, etc.

## Files to modify

- `skills/code-review.md` — rename section to "Stage 1.5: Critic gating" and add evidence consultation subsection. Net add: ~30-40 lines.

## Risks and mitigations

- **Risk: Stage 1.5 fires when fact-check happens to find no claims in a domain, but actual code in that domain is present.** Mitigation: domain heuristic considers *both* fact-check claims and diff contents (fact-check report references file paths the orchestrator can cross-check). When in doubt, run.
- **Risk: Two overlapping signals (diff-shape + evidence) make the section dense.** Mitigation: explicit preamble names the two gates; "lead with evidence consultation, fall through to skip table" keeps reading order linear.
- **Risk: Authors may interpret "Stage 1.5" as a full pipeline stage requiring its own status banner.** Mitigation: explicitly state in the section that no banner is emitted (status banners are still Stage-1-end and Stage-2-end only).
