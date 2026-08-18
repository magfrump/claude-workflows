# DD — Improve the `dependency-upgrade` critic persona (decision record draft)

- **Goal**: Decide how to change `~/.claude/skills/dependency-upgrade/SKILL.md` so the N2 failure class (fabricated-or-stale execution evidence under a clean verdict) is structurally impossible, given the upstream decision that `code-fact-check` is being upgraded to carry execution-based verification.
- **Project state**: review-pipeline hardening after the 2026-08-17 persona-attribution audit · feeds the same initiative as decisions 028/030/031/033 · not blocked.
- **Task status**: in-progress (decision drafted by DD subagent, awaiting author review)

## Context

Attribution audit (`docs/working/pipeline-persona-attribution-2026-08-17.md` §2.2): dependency-upgrade owns the pipeline's **worst single incident**. In the secdeps review (`external/meta-formalism-copilot/docs/reviews/security-deps-guardrails/dependency-upgrade-review.md`) it printed a purported execution of the new CI gate twice (Q1 and Q3):

```
$ npm audit --omit=dev --audit-level=high
# (no output — exit 0, no high/critical advisories)
```

The gate actually exits 1 with 5 high advisories. The claimed run carries **no provenance whatsoever** — no timestamp, no registry/advisory-DB state, no lockfile hash, no raw output artifact, not even literal output (both "runs" are paraphrase: "(no output — exit 0…)"). It was promoted to two rubric Confirmed Good rows including the ledger's "gate passes" row. Same shape at smaller scale: Q2's `grep … # (no matches)` consumer check is also an unprovenanced execution claim. Nobody else executed the gate; fact-check verified only flag semantics.

What the persona did **well** in the same report: Q2's changelog/breaking-change analysis, Q4's lockfile-vs-manifest reasoning, the postcss-via-next triage, the structured per-package evaluations, follow-up sequencing. That value is judgment-shaped, not execution-shaped, and must survive.

Upstream design constraint (decided, not re-litigated here): `code-fact-check` is upgraded to carry execution-based verification (per 033 + the attribution doc's runtime-falsification direction) and its report feeds every critic.

## Step 1 — Diverge (13 candidates)

Prior-pruning grep (`Pruned candidates` in `docs/decisions/*.md`, keywords: dependency, audit, execution, critic, fact-check): matches found —
- [carried from 028-escalation-second-channel, candidate 10 "dedicated soundness critic": "mints new authority from an unvalidated judgment at a full extra dispatch"] → pre-prunes any "add a second dependency-audit critic to double-check the first" candidate; not regenerated.
- [carried from 017-polyglot-test-hermeticity, constraint via 014: "an LLM critic is a detector, not an enforcement primitive"] → enforcement of the evidence rule must live in the output contract + synthesis gate, not in the critic's good intentions.

Candidates (no evaluation yet):

0. **Status quo** — change nothing; rely on the upgraded fact-check to catch fabrications downstream.
1. **Full removal / consume-only** — strip all command execution from dependency-upgrade; every execution-derived statement must cite the fact-check report; standalone it may only *recommend* commands, never report results.
2. **Provenance protocol everywhere** — keep execution, but every claimed run must attach raw output captured to file, exit code, cwd+commit, lockfile hash, timestamp, advisory-DB state; claims without the block are disallowed.
3. **Mode-split hybrid** — inside `code-review` (fact-check report present): consume-only, never runs; standalone (no fact-check pass exists): may execute, but only under the full provenance protocol.
4. **Merge into security-reviewer's dependency remit** — delete the persona; security-reviewer's dep-manifest trigger absorbs it.
5. **Validity windows** — every audit-derived verdict carries an as-of stamp (timestamp + advisory-DB/registry state) and an expiry rule ("re-run at merge if >Nh old or lockfile changed").
6. **Findings-shaped output** — replace Q&A answers with findings + per-finding confidence + evidence pointers, like the other critics.
7. **Structural template gate** — output template gains a mandatory "Execution evidence" section; the template makes "gate passes"-type sentences expressible only as a row referencing an evidence artifact, else the mandated phrasing is "Unverified — run `<cmd>`".
8. **Verification-plan-only** — the persona never asserts gate outcomes at all; it emits a runnable verification script/checklist that CI or fact-check executes.
9. **Naive** — add a "do not fabricate command output" warning bullet to Important. *(deliberately naive)*
10. **Ideal-if-free** — sandboxed execution harness that re-runs every claimed command in a pinned container and diffs claimed vs. actual output automatically.
11. **Reframe: fix synthesis only** — leave the skill untouched; enforce at rubric synthesis that no Confirmed-Good may rest on a critic's self-reported execution (attribution doc rec 2).
12. **Time-shifted demotion** — all execution-derived answers ship marked "Unverified — pending fact-check execution pass"; synthesis must resolve the marker before any rubric row.

Health check: no clustering (candidates move on agent set [4], protocol/text [2,5,7,9], topology/ownership [1,3,8,11,12], output shape [6], infra [10]); do-nothing [0], naive [9], ideal-if-free [10] present. Pass.

## Step 2 — Diagnose (6 constraints: 4 hard · 2 soft)

- **H1 (hard) — prevents the N2 failure class.** A categorical execution verdict ("gate passes", "no matches") must be structurally impossible to state without attached evidence. `success:` on a re-run of the secdeps brief, every command-result sentence in dependency-upgrade output either cites a fact-check claim id or carries a provenance block (raw output artifact/verbatim full output + exit code + cwd/commit + lockfile hash + timestamp); a bare "(no output — exit 0)" line fails the code-review synthesis gate and cannot become a rubric row.
- **H2 (hard) — composes with the upgraded fact-check.** No duplicate executors inside the pipeline whose results can silently diverge; single source of execution truth when a fact-check report exists. `success:` skill text names exactly what is consumed from the fact-check report and forbids re-asserting command outcomes independently when one is provided (the NOTE-line convention the other critics already carry and this skill currently lacks).
- **H3 (hard) — preserves the non-execution value.** Changelog reading, breaking-change-vs-actual-usage matching, migration/rollback planning, transitive/lockfile reasoning stay in-remit. `success:` the secdeps report's Q2 changelog analysis and Q4 lockfile/manifest reasoning would still be produced, unchanged in kind, under the new skill text.
- **H4 (hard) — handles time-variance.** Audit results rot; a verdict true on review day can be false at merge. `success:` the output template forces an "as of {timestamp / advisory-DB state}" field on every audit-derived claim plus a re-run-before-merge trigger (age or lockfile change); no unscoped "no advisories" sentence is expressible in the template.
- **S1 (soft) — cost.** No extra agent dispatch; ≤ ~1 screen of added skill text; no new infrastructure.
- **S2 (soft) — both invocation modes keep working.** Standalone ("should we upgrade X", Dependabot PR triage — the skill's primary documented use) must still yield actionable audit answers, not only "here's a command".

## Step 3 — Match and prune

| # | Candidate | H1 no-fabrication | H2 fc-composition | H3 judgment value | H4 time-variance | S1 cost | S2 both modes |
|---|---|---|---|---|---|---|---|
| 0 | status quo | ✗ | ✗ | ✓ | ✗ | ✓ | ✓ |
| 1 | consume-only | ✓ (pipeline) / ✗ (standalone: no fact-check exists, so either guesses or goes mute) | ✓ | ✓ | ~ (delegated wholesale) | ✓ | ✗ |
| 2 | provenance everywhere | ✓ | ⚠ (two executors, divergent results, doubled runs) | ✓ | ~ (needs 5 bolted on) | ~ | ✓ |
| 3 | mode-split hybrid | ✓ | ✓ | ✓ | ~ (needs 5) | ✓ | ✓ |
| 4 | merge into security-reviewer | ✗ (relocates, doesn't fix; security-reviewer has its own wrong-endorsement record, §2.3) | ~ | ⚠ (changelog/migration remit has no home) | ✗ | ✓ | ✗ |
| 5 | validity windows | ✗ alone (stamps a fabricated run just as happily) | ✓ | ✓ | ✓ | ✓ | ✓ |
| 6 | findings-shaped | ~ (orthogonal) | ~ | ~ | ✗ | ✓ | ~ |
| 7 | structural template gate | ✓ (the "impossible to state" mechanism) | ~ alone (doesn't decide who runs) | ✓ | ~ | ✓ | ✓ |
| 8 | verification-plan-only | ✓ (never asserts) | ✓ | ✓ | ✓ (nothing to rot) | ✓ | ~ (standalone user gets homework, not an answer) |
| 9 | warning bullet | ✗ (not structural; the incident model *believed* its output) | ✗ | ✓ | ✗ | ✓ | ✓ |
| 10 | sandbox diff harness | ✓ | ✓ | ✓ | ✓ | ✗ (new infra, per-review container) | ✓ |
| 11 | synthesis rule only | ~ (protects the rubric, not the report; standalone runs bypass synthesis entirely) | ✓ | ✓ | ✗ | ✓ | ✓ |
| 12 | demote-to-unverified | ~ (marker is prose, same enforcement gap as 9) | ✓ | ✓ | ~ | ✓ | ✓ |

Pruned: 0, 9 (✗ on H1 — not structural); 4 (⚠ H3); 6 (orthogonal — folded as non-decision, keep Q&A shape, see stress test); 10 (✗ S1 — revisit trigger below); 12 (dominated by 7, which makes the same demotion mechanical instead of honor-system).
Absorbed, not discarded: **5** and **7** are components, not rivals — every surviving executor-policy candidate needs them; **11** is already adopted upstream (attribution rec 2, synthesis layer) and complements any winner.
Survivors into step 4: **[3] hybrid (+5+7)**, **[1] consume-only (+7)**, **[2] provenance-everywhere (+5+7)**, **[8] verification-plan-only**.

## Step 4 — Tradeoff matrix and decision

| # | Approach | Effort | Risk | Coverage (hard) | Key downside |
|---|---|---|---|---|---|
| **3★** | mode-split hybrid + evidence template + as-of stamps | ● ~2h skill edits | ● low | ● 4/4 | ◐ two behavioral modes; mode-detection must be unambiguous (mitig.: default = standalone protocol; consume-only fires only when a fact-check report is literally in context — the existing NOTE-line convention) |
| 1 | consume-only + template | ● ~1h | ◐ med | ◐ 3/4 (S2 ✗, H4 delegated) | standalone mode — the skill's primary documented use — loses audit answers entirely |
| 2 | provenance-everywhere + template + stamps | ● ~2h | ◐ med | ◐ 3/4 (H2 ⚠) | duplicate executor inside the pipeline; two "truths" for the same gate, doubled run cost |
| 8 | verification-plan-only | ● ~1.5h | ◐ med | ◐ 3.5/4 (S2 ~) | Dependabot-triage user asking "is this safe?" gets a script instead of a verdict |

Falsifiable hypotheses:
- **[3]** If chosen, we expect the next secdeps-class replicate (E-series rep on mfc-secdeps or equivalent) to contain **zero unprovenanced execution claims** — every command-result sentence cites a fact-check claim id or carries the full provenance block — within the next review-arms run; counter-evidence = any rubric row sourced to a dependency-upgrade execution claim that lacks a raw-output artifact, or a standalone run that answers an audit question with paraphrased output.
- [1] If chosen, pipeline reports are fabrication-free but ≥1 standalone invocation per month either refuses audit questions or silently regresses to guessing; counter-evidence = standalone runs staying both useful and evidence-clean.
- [2] If chosen, no fabrications, but within 3 pipeline runs fact-check and dependency-upgrade report a differing result for the same command once (registry drift between their run times); counter-evidence = sustained agreement at acceptable cost.
- [8] If chosen, zero false verdicts (none asserted) but user friction on Dependabot triage within 2 uses; counter-evidence = users happily running the emitted scripts.

Stress tests applied to [3]:
- **Boring alternative** → is [1] simpler? Yes, but it fails S2: standalone invocations (the description's own trigger list: "should we upgrade X", Dependabot PRs, CVE advisories) have no fact-check pass to consume. [3] *is* the boring option per-mode: consume when a report exists, protocol when it doesn't. No change.
- **Invert the thesis** (argue for [2]: independent duplicate execution catches fact-check's own errors) → the incident's failure was *provenance-free assertion*, not lack of redundancy; a second unprovenanced runner doubles the attack surface for the same failure. Redundancy without provenance produced N2; provenance without redundancy would have caught it. Refuted; matrix unchanged, but recorded 030's principle: the agentic re-verify gate stays singular.
- **Failure-driven** → new failure mode of [3]: mode ambiguity — a run that *thinks* it's standalone executes commands the orchestrator also ran, or a pipeline run with a missing fact-check report goes mute. Mitigation folded into the edit list: the mode rule keys on one observable ("a code-fact-check report is provided in context"), same convention as every other critic's NOTE line, and the no-report pipeline case degrades to the standalone protocol (safe: protocol-compliant execution is always acceptable, unprovenanced assertion never is). Downside tagged (mitig.).
- **Push to extreme** → protocol on *every* command would make trivial greps bureaucratic. Scope rule: the protocol binds any statement of the form "command X produced result Y" that supports a verdict — which **includes** Q2-style greps (its "(no matches)" is the same failure shape) — but compliance for cheap read-only commands is just "paste the actual verbatim output + cwd + commit", no file artifact needed; the file-artifact tier is required only for verdict-bearing gates (audit, install, test). Template edit updated accordingly.

**Decision path A** — [3] dominates at ~90% confidence (only candidate at 4/4 hard coverage; runner-up [2], axis = redundancy vs. single-source-of-execution-truth, resolved by 030's stated preference for a single production re-verify gate).

```
▶ recommend [3] mode-split hybrid + evidence template + as-of stamps · confidence 90% · runner-up [2], axis = redundancy vs single execution truth
```

## Decision and rationale

**Adopt [3]: mode-split hybrid, carried by two structural components.** When a code-fact-check report is in context (the code-review pipeline), dependency-upgrade is consume-only for execution results: it cites fact-check claim ids and never runs or re-asserts command outcomes. When no report exists (standalone), it may execute, but only under an evidence-provenance protocol whose output-template hooks make an unprovenanced "gate passes" sentence structurally inexpressible. All audit-derived claims carry as-of stamps and a re-run-at-merge trigger. This is the only survivor satisfying all four hard constraints: it kills the N2 class in both modes (H1 via the template gate, [7]), gives execution a single source of truth in the pipeline (H2, per 030), leaves the changelog/migration/rollback judgment remit untouched (H3), and makes audit verdicts explicitly time-scoped (H4 via [5]). The upstream synthesis rule ([11], attribution rec 2) remains the belt to this suspenders.

See alternatives considered → **Pruned candidates and why** below.

## Pruned candidates and why

How to read: each entry is `[candidate-ID]: one-line reason for discard`. Future DDs in adjacent areas can grep this section to avoid regenerating already-pruned approaches.
[0]: status quo is the incident. [1]: kills the skill's primary standalone use; absorbed as [3]'s pipeline mode. [2]: runner-up — duplicate executor violates the single re-verify-gate principle (030); its protocol absorbed into [3]'s standalone mode. [4]: relocates the failure into security-reviewer (itself §2.3's wrong-endorsement leader) and orphans the changelog/migration remit. [5]/[7]: absorbed as components of the winner, not discarded. [6]: orthogonal output-shape change; Q&A shape retained — the brief's questions are the user's questions, and the failure was evidence, not shape. [8]: verdict-free answers degrade Dependabot triage; kept as the degraded-mode phrasing ("Unverified — run `<cmd>`") inside [7]'s template. [9]: warnings are not structure; the model believed its output. [10]: claimed-vs-actual diff harness is new infrastructure; see Revisit triggers. [11]: already adopted upstream at synthesis (attribution rec 2); complement, not rival. [12]: dominated by [7], which makes the same demotion mechanical. [second dependency-audit critic]: not regenerated — [carried from 028 candidate 10: "mints new authority from an unvalidated judgment at a full extra dispatch"]. Enforcement placement per [carried from 017/014: "an LLM critic is a detector, not an enforcement primitive"] → template contract + synthesis gate, not exhortation.
Prior pruning grep: matches found for [dependency, audit, execution, critic, fact-check] — both carried, none revived.

## Stress-test mitigations

- How to read: *Failure-driven* mitigation — mode ambiguity in [3] resolved by keying consume-only mode on one observable ("a code-fact-check report is provided in context", the existing cross-critic NOTE convention) and defaulting the missing-report pipeline case to the standalone protocol; key-downside cell tagged (mitig.).
- How to read: *Push to extreme* mitigation — provenance protocol scoped to verdict-bearing command claims with a two-tier compliance bar (verbatim-output-inline for cheap read-only commands; file artifact + fingerprint for gates), preventing bureaucratization of trivial greps while still covering the Q2 grep shape.

## Concrete SKILL.md change list (`~/.claude/skills/dependency-upgrade/SKILL.md`)

1. **Add the orchestrator NOTE (the [3] mode switch), new final sentence of the frontmatter `description`** — currently the description ends at line 14 `…prefer running this skill over skipping it.` and, unlike every other critic skill, has no composition NOTE. Append: `NOTE: This skill can be invoked standalone or by a code-review orchestrator. If a code-fact-check report is provided, it is the sole source of execution results: consume its verdicts and claim ids for any command-outcome statement (audit, install, test, grep) and do not run or re-assert command outcomes yourself.`

2. **New `## Execution evidence protocol` section (the [7]+[2] mechanism), inserted after `## Analysis` intro / before `### 1. Breaking changes impact`:** governs standalone mode. Core text: *"Any statement of the form 'command X produced result Y' that supports a verdict is an execution claim. An execution claim is only expressible with its provenance attached: (a) exact command, (b) cwd + commit SHA + lockfile hash, (c) exit code, (d) timestamp, (e) for audit commands, the advisory-database/registry state the tool reports, (f) the raw output — verbatim and complete inline for short read-only commands; captured to `docs/reviews/{branch}/evidence/{n}-{cmd-slug}.txt` for verdict-bearing gates (audit, install, test). Paraphrased output — '(no output — exit 0)' — is never provenance. If you cannot attach provenance, the only permitted phrasing is: `Unverified — run `<cmd>` and attach output before relying on this.`"* (The paraphrase example is the literal N2 incident string.)

3. **Time-variance rule (the [5] component), amending the `## Important` bullet at line 185** — currently: `**For security upgrades, check the actual advisory.** Is the vulnerability exploitable in this project's usage? …` Append to the bullet: `Advisory data is time-varying: an audit result is a snapshot, not a property of the branch. Scope every audit-derived verdict "as of {timestamp / advisory-DB state}" and state the re-run trigger: re-run the gate at merge time if the review is older than 24h or the lockfile changed since.`

4. **Output template (lines 100–107): make the Summary time-scoped and add an evidence section.** After the `**Risk:** {Low / Medium / High}` line (107), add: `**Audit state:** {as of YYYY-MM-DD HH:MM, advisory DB {metadata} — re-run at merge if >24h old or lockfile changed} / {Consumed from code-fact-check report, claims {ids}} / {Unverified}`. Add a new template section `### Execution Evidence` (before `### Risk Factors`, line 125) with a table `| command | exit | as-of | evidence |` where `evidence` is a fact-check claim id, an evidence-file path, or verbatim inline output — the template offers **no** cell value for "trust me". Rows the skill didn't run and can't cite render as `Unverified — recommended pre-merge check`.

5. **Extend the rollback-rehearsal discipline (lines 89–95) with the same protocol** — current line 143's artifact `**Rehearsal status:** [ ] Rehearsed on {YYYY-MM-DD} on branch \`{scratch-branch-name}\`; verification step passed.` is itself an execution claim; amend to require the verification step's captured output (evidence path or verbatim) on the same line, so "rehearsed, passed" can't be asserted evidence-free either.

6. **`## Important`, new closing bullet:** `**Never present a command you did not run in this session as having been run.** If a result is remembered, inferred, or expected, it is a prediction — label it as such. The evidence protocol exists because a fabricated "exit 0" once became a shipped "gate passes" rubric row (secdeps N2, 2026-04-27).`

Companion edit (owned by the fact-check/code-review upgrade track, listed for traceability): `skills/code-review/SKILL.md` synthesis rule per attribution rec 2 — no Confirmed-Good row rests solely on a critic's self-reported execution.

## Consequences

- Easier: auditing any dependency-upgrade verdict (evidence table is grep-able); trusting "gate passes" rows; detecting stale audits at merge time; pipeline cost drops slightly (no duplicate executions).
- Harder: standalone runs pay a small provenance-capture overhead per verdict-bearing command; reviews of the review must check evidence files exist, not just that the table cites them; the skill text grows ~1 screen.

## Revisit triggers

How to read: each entry is a concrete, observable condition that should prompt re-evaluating this decision. Future readers can grep this section when their context changes to see whether earlier decisions still apply.
if any post-change review-arms replicate contains an unprovenanced execution claim (protocol failed → escalate to candidate [10]'s claimed-vs-actual diff harness). if fact-check's execution upgrade is rolled back or descoped (pipeline mode loses its source of truth → fall back to [2] provenance-everywhere). if standalone invocations drop to ~0 over a quarter (mode split is dead weight → simplify to [1] consume-only). if evidence-file capture proves incompatible with the review-arms sandbox (re-scope tier-2 provenance to verbatim-inline only). if a fact-check-vs-reality divergence is ever observed on an audit command (single-executor assumption broken → revisit redundancy, i.e. [2]).
