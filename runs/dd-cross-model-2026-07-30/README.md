# Divergent-design cross-model sweep — 2026-07-30

Four frontier models were given a **byte-identical prompt** (`prompt.md` in this
directory) and asked to run the `divergent-design` workflow, end to end, on the
decision:

> "Which actions should be taken next to improve this repo's code-review process?"

Inputs embedded in the prompt: `docs/thoughts/code-review-evaluation-state.md`,
`skills/divergent-design/SKILL.md`, and the full `workflows/divergent-design.md`.

**Purpose (primary):** compare how the DD skill executes across model families —
candidate breadth, constraint discipline (hard/soft + `success:` lines), matrix
quality, stress-test usage, template fidelity of the Decision presentation block.
**Purpose (secondary):** mine the four analyses for actions actually worth taking.

## Config — read before comparing

- All four runs are **single-response, no tools, prompt-inline** — the
  Result-10-comparable config of the evaluation-state doc §5.1. None of these runs
  measure the agentic pipeline.
- The local Fable arm ran inside Claude Code as a subagent but was explicitly
  forbidden to read any file other than the prompt, to stay comparable. It differs
  from the OpenRouter arms in harness (Claude Code agent loop vs. raw chat
  completion), not in available context.
- Per §5.2 discipline: when comparing, score on *which candidate actions and
  constraints each model surfaced*, not on cosmetic scoring differences.

## Results at a glance (details in each file)

All four models independently converged on the **same top action: k≥3
`code-fact-check` replication with most-severe-wins (§1.1)** — the strongest
cross-family agreement this program has recorded on any question.

| Model | Latency | Completion tok (reasoning) | Candidates | Survivors | Path | Confidence | Recommendation |
|---|---|---|---|---|---|---|---|
| Fable 5 (local) | ~5 min | n/a (agent) | 16 | 5 | C | 78% | Portfolio: k≥3 fact-check + evidence-bearing Confirmed Good in parallel; then MD1-R1 replication, then §1.2 escalation sub-DD; vendor-in-fact-check deferred behind 021 Stage 1 |
| GPT-5.6 Sol | 155 s | 9,147 (2,233) | — | 5 | C | 78% | Fact-check replication first; runner-up Confirmed-Good evidence; axis = "unstable blocker promotion vs unsupported positive assurance" |
| Gemini 3.1 Pro | 112 s | 15,594 (11,870) | — | 4 | A | 95% | k=3 incumbent fact-check dominates; vendor addition and soundness routing are fast-follows gated on the stabilized baseline |
| Kimi K3 | 956 s | 32,487 (24,306) | 14 | 5 | C | 75% | k≥3 fact-check scoped to promotion-candidate claims (k set by pre-flight disagreement measurement); runner-up doc-order status quo |

Skill-fidelity notes for the primary (cross-model) reading:

- **Template fidelity:** all four rendered the Decision presentation block with
  the box-drawing scorecard, legend, ★ marker, and recommendation banner; none
  left unfilled `<…>` slots. All four honored the no-`AskUserQuestion` constraint.
- **Depth spread:** Kimi produced the most aggressive stress-test pass (scope
  narrowing of k≥3 to promotion decisions only; queue-volume caps on human
  routing) at ~9× Sol's latency. Gemini was the thinnest (~15k chars) and the
  only Path A / 95% call. Fable and Sol landed near-identical confidence (78%)
  and near-identical runner-up axes.
- **Divergence worth reading:** where they differ is *sequencing and scoping* —
  Fable defers the second vendor behind 021 Stage-1 context; Gemini treats
  baseline stabilization as a hard prerequisite for everything; Kimi challenges
  the state doc's own §1 serial ordering ("content adopted, schedule rejected").

API cost: $1.21 total (Kimi $0.56 · Sol $0.42 · Gemini $0.23).

## Files

| File | Arm |
|---|---|
| `prompt.md` | The shared prompt (identical bytes to all four models) |
| `local_claude-fable-5.md` | Fable 5, local Claude Code subagent |
| `openai_gpt-5.6-sol.md` | GPT-5.6 Sol via OpenRouter |
| `google_gemini-3.1-pro-preview.md` | Gemini 3.1 Pro via OpenRouter |
| `moonshotai_kimi-k3.md` | Kimi K3 via OpenRouter |
| `*.meta.json` | Per-run latency/usage/finish_reason (OpenRouter arms) |
