# Code Fact-Check Report (merged, k=3 most-severe-wins)

Commit: e9d05ea

**Repository:** /workspace/.claude/worktrees/cross-model-review-sweep
**Scope:** git diff main...HEAD (branch exp/cross-model-openrouter-sweep)
**Checked:** 2026-07-30
**Total claims checked:** 28 merged clusters (r1: 26 claims · r2: 30 · r3: 24)
**Summary:** 20 verified, 3 mostly accurate, 0 stale, 3 incorrect, 2 unverifiable (cluster-level, post-merge)

Merged per `skills/code-review/SKILL.md` Stage 1: claims clustered by (file, ±5-line
range, claim substance); each cluster takes the most severe verdict any replicate
assigned; per-replicate verdicts recorded (`—` = replicate did not surface the claim).
Full per-claim evidence lives in the replicate reports (`code-fact-check-report-r1..3.md`);
this merged report carries the cluster verdicts and the evidence for non-Verified clusters.

(Prior report at this path — 2026-06-23, commit eb545b1, feat/batch-feedback branch —
is preserved in git history.)

---

## Merged clusters

| # | Claim (abbrev.) | Location(s) | r1 | r2 | r3 | Merged verdict |
|---|---|---|---|---|---|---|
| M1 | Log row 27 (formerly numbered 26 in the reviewed commit) describes the shipped k=3 Stage-1 contract | `docs/decisions/log.md:48` | Verified | Verified | Verified | Verified (High) |
| M2 | "fact-check Incorrect is the pipeline's *only* 🔴-promotion channel" | `docs/decisions/log.md:48` · `skills/code-review/SKILL.md:27,264,1142` · `test/skills/code-review-factcheck-replication.bats:6-8` | **Incorrect** | Verified | Mostly accurate | **Incorrect (High)** |
| M3 | Result 14a flip + J_self 0.14–0.25 citations | log.md:48 · SKILL.md:265-268 | Verified | Verified | Verified | Verified (High) |
| M4 | Per-replicate reports persist; decision-25 gap closed | log.md:48 · SKILL.md | Verified | Verified | Verified | Verified (High) |
| M5 | ≥90%/≥20-claim falsifier carried | log.md:48 · SKILL.md · state doc:198 | Verified | Verified | Verified | Verified (High) |
| M6 | All four DD-sweep families ranked this action first | log.md:48 · README.md:31 · state doc:43 | Verified | Verified | Verified | Verified (High) |
| M7 | State doc: "implemented **exactly** as shaped below" | `docs/thoughts/code-review-evaluation-state.md:41-44` | Mostly accurate | Verified | Mostly accurate | **Mostly accurate (High)** |
| M8 | Open question #2 marked Instrumented | state doc:198 | Verified | Verified | Verified | Verified (High) |
| M9 | "byte-identical prompt" to all four arms | `runs/dd-cross-model-2026-07-30/README.md:3` | Unverifiable | Unverifiable | Unverifiable | Unverifiable (Medium) |
| M10 | Inputs embedded in prompt.md as listed | README.md:9-11 | Verified | Verified | Verified | Verified (High) |
| M11 | All four runs single-response / no-tools / §5.1-comparable | README.md:19-21 | Verified | — | Verified | Verified (Medium) |
| M12 | 4/4 convergence on k≥3 fact-check as top action | README.md:31-33 | Verified | Verified | Verified | Verified (High) |
| M13 | Results-table metrics (latency/tokens/survivors/paths/confidence) | README.md:35-40 | Verified | Verified | Verified | Verified (High) |
| M14 | Fable arm: "~5 min", forbidden to read other files | README.md:22-25,37 | Unverifiable | Unverifiable | Unverifiable | Unverifiable (Medium) |
| M15 | Template fidelity across all four outputs | README.md:44-47 | Verified | Verified | Verified | Verified (High) |
| M16 | Kimi runner-up = "doc-order status quo" | README.md:40 | — | **Incorrect** | **Incorrect** | **Incorrect (High)** |
| M17 | Kimi "at ~9× Sol's latency" | README.md:48-49 | **Incorrect** | **Incorrect** | **Incorrect** | **Incorrect (High)** |
| M18 | Gemini thinnest, only Path A / 95% | README.md:49-50 | Verified | Verified | Verified | Verified (High) |
| M19 | Divergence bullets (Fable/Gemini/Kimi characterizations) | README.md:51-57 | Verified | — | Verified | Verified (High) |
| M20 | API cost $1.21 (0.56/0.42/0.23) | README.md:57 | Verified | Verified | Verified | Verified (High) |
| M21 | Files table inventory | README.md:59-68 | Verified | Verified | Verified | Verified (High) |
| M22 | "Per §5.2 discipline" framing | README.md:26-28 | — | — | Mostly accurate | Mostly accurate (Medium) · single-replicate detection |
| M23 | "strongest cross-family agreement this program has recorded" | README.md:33 | — | — | Unverifiable | Unverifiable (Low) · single-replicate detection |
| M24 | Severity-order definition text in Stage 1 | SKILL.md:323-325 | Verified | — | — | Verified (High) · single-replicate detection |
| M25 | bats header enforcement rationale | bats:12-14 | Verified | Verified | Verified | Verified (High) |
| M26 | bats tests assert what they claim; 10/10 pass | bats:25-100 | Verified | Verified | Verified | Verified (High) |
| M27 | Commit-message claims (e9d05ea, b6114ac) | commit messages | — | Verified | — | Verified (High) · single-replicate detection |
| M28 | State-doc/log cross-refs to decision 25 & §1.1 sections | multiple | Verified | Verified | Verified | Verified (High) |

Counting note: the summary line counts M9+M14 as the two Unverifiable root causes
(both are "run-condition claim without a send-side artifact"); M23's superlative is
annexed to that band. Cluster verdict counts: Verified 20 · Mostly accurate 3 (M7,
M22, plus M2's minority reading subsumed into M2's Incorrect) · Incorrect 3 (M2, M16,
M17) · Unverifiable 2.

---

## Evidence for non-Verified clusters

### M2 — Incorrect (High) — "only 🔴-promotion channel"

The claim (introduced by this diff in three files) asserts an exclusivity the codebase
contradicts. `skills/code-review/SKILL.md:976` (Unified Severity Mapping) maps to 🔴:
Security Critical/High, Performance Critical, API Consistency Breaking, Architecture
Structural, and Fact-Check Incorrect (high confidence). The upstream source itself —
`docs/thoughts/code-review-evaluation-state.md` §1.0 — says "a `code-fact-check`
verdict of Incorrect, **or an api-consistency Breaking**". The accurate wording is
"the only *verdict-driven escalation* channel available to documentation-class findings"
or "one of the two blocking verdicts §1.0 names". (Evidence: r1 claims 2/21/24;
r3 claims 2/23.)

**The replicate split on this cluster is itself the finding the mechanism exists for:**
r1=Incorrect, r2=Verified, r3=Mostly accurate on identical text — a live
Result-14a-shaped instability, resolved by most-severe-wins exactly as designed.

Upstream: the compression originates *outside* the diff in the state doc's §1.1 opening
("a fact-check Incorrect verdict is the *only* thing that promotes a finding to 🔴") —
fixing only the in-diff copies leaves the source to re-propagate (r1 escalation).

### M16 — Incorrect (High) — Kimi runner-up misattributed

`runs/dd-cross-model-2026-07-30/README.md:40` says "runner-up doc-order status quo".
The artifact's banner (`moonshotai_kimi-k3.md:171`) reads "▶ recommend [3] k≥3
fact-check, most-severe-wins · confidence 75% · runner-up [2]" — candidate [2] is
**measurement-first**; doc-order status quo is candidate [0], ranked fourth of five.
(Evidence: r2 claim 16; r3 claim 16.)

### M17 — Incorrect (High, unanimous) — "~9× Sol's latency"

955.9 s / 154.5 s ≈ **6.2×** (arithmetic-verified independently by two replicates).
~9× matches the Kimi-to-**Gemini** ratio (955.9/112.2 ≈ 8.5×) — likely a swapped
denominator. (Evidence: r1 claim 16; r2 claim 18; r3 claim 18.)

### M7 — Mostly accurate (High) — "implemented exactly as shaped below"

The implementation deviates deliberately from §1.1's shape in one particular: clustering
is by (file, ±5-line range, claim **substance**) rather than §1.1's "(file, line-range,
claim text)". "Exactly" overstates; "as shaped below, with semantic rather than textual
claim matching" is precise. (Evidence: r1 claim 7; r3 claim 7.)

### M22 — Mostly accurate (Medium, single-replicate) — "Per §5.2 discipline"

State doc §5.2 is about scoring *detection vs. tier* in code-review sweeps; the README
extends it to candidate/constraint comparison in a DD sweep. The extension is reasonable
but is the README's own, not §5.2's text. (Evidence: r3 claim 13.)

### M9 / M14 / M23 — Unverifiable — run-condition claims without recording artifacts

Byte-identical prompt delivery, the Fable arm's file-read prohibition and ~5-min latency,
and the "strongest cross-family agreement recorded" superlative have no send-side
artifacts (no per-arm prompt hash, no local-arm meta.json, no agreement-comparison
corpus) in the repo. Token counts in the meta.json files are *consistent with* identical
prompts but not probative. (Evidence: r1 claims 9/14; r2 claims 7/9/11; r3 claims 9/12/14.)

---

## Verdict stability

- **Clusters:** 28 merged (from 26 + 30 + 24 replicate claims).
- **Multi-replicate clusters:** 23; **single-replicate detections:** 5 (M22, M23, M24, M27, and M16 at 2-of-3).
- **All reporting replicates agreed:** 21 of 23 multi-replicate clusters.
- **Disagreements:** 2 —
  - **M2:** r1=Incorrect · r2=Verified · r3=Mostly accurate — a three-way split spanning the claim's full severity range.
  - **M7:** r1=Mostly accurate · r2=Verified · r3=Mostly accurate.
- **Agreement rate:** 21/23 ≈ **0.91** (cluster level, first measured sample).
- **Reading:** the headline rate nominally clears the §1.1 falsifier threshold (≥90% on
  ≥20 claims), but this is one run, and both disagreements sit on Verified↔Incorrect
  boundaries — the exact 14a class the mechanism guards. The disagreement concentrated on
  the diff's single most consequential claim (M2, the would-be 🔴). Do **not** drop to
  k=2 on this sample; keep accumulating per the cumulative bar.

---

## Claims Requiring Attention

### Incorrect
- **M2** (`skills/code-review/SKILL.md:27,264,1142` + `docs/decisions/log.md:48` + `test/skills/code-review-factcheck-replication.bats:6`): "only 🔴-promotion channel" contradicted by the Unified Severity Mapping (five 🔴 sources) and §1.0's own "or an api-consistency Breaking". Reword in all three files; fix the upstream state-doc sentence too.
- **M16** (`runs/dd-cross-model-2026-07-30/README.md:40`): Kimi runner-up is [2] measurement-first, not doc-order status quo.
- **M17** (`runs/dd-cross-model-2026-07-30/README.md:48-49`): ~9× → ~6× (or name the Gemini comparison the ratio actually matches).

### Stale
- none

### Mostly Accurate
- **M7** (`docs/thoughts/code-review-evaluation-state.md:41-44`): "exactly as shaped" → note the deliberate clustering-key deviation.
- **M22** (`runs/dd-cross-model-2026-07-30/README.md:26-28`): attribute the comparison discipline as an extension of §5.2, not as §5.2 itself.

### Unverifiable
- **M9/M14/M23** (`runs/dd-cross-model-2026-07-30/README.md:3,22-25,33,37`): run-condition claims (byte-identical delivery, Fable-arm constraints/latency, superlative) lack recording artifacts; add artifacts on future sweeps (prompt SHA per arm, local-arm timing) or soften to "constructed to be identical".

## Goal-Alignment Note
- Answered: yes — all three replicates covered the full diff scope
- Out of scope: claims *inside* the immutable model-output artifacts (per orchestrator scoping); prompt-transmission verification set aside as unrecordable post-hoc
- Escalate: M2's upstream source (state doc §1.0/§1.1 "only" phrasing) predates this branch — fixing only in-diff copies leaves it to re-propagate (r1)
