Commit: e9d05ea

# Security Review — branch `exp/cross-model-openrouter-sweep`

**Scope:** `git diff main...HEAD` — 13 files, +2375/−20. Substantive surface: `skills/code-review/SKILL.md`, `test/skills/code-review-factcheck-replication.bats`, `docs/decisions/log.md`, `docs/thoughts/code-review-evaluation-state.md`, `runs/dd-cross-model-2026-07-30/**`.
**Date:** 2026-07-30
**Based on:** Stage 1 code-fact-check report (k=3 merged) supplied by the orchestrator; its findings are treated as established and not re-verified.

No escalation patterns matched. The `runs/` artifacts were scanned for plaintext credentials, API keys, and OpenRouter tokens — the `.meta.json` files carry only model IDs, token counts, cost, and latency; no key material, account identifiers, or request headers are present. No TLS, crypto, SQL, or shell-execution surface exists in this diff, so escalation patterns 2–5 are structurally inapplicable.

This is a process-and-prose diff with no application code. The security-relevant substance is that it changes **how a merge-blocking gate is computed**, **how many write-capable agents an unattended loop spawns**, and **what third-party content is now resident in the trusted repo**. Those are the three axes reviewed.

## Trust Boundary Map

```
B1 (new): [third-party inference providers: OpenAI / Google / Moonshot] → [manual commit into runs/dd-cross-model-2026-07-30/] → [trusted in-tree markdown read by future agents]
B2 (new): [3 parallel fact-check sub-agents, write-capable under acceptEdits] → [docs/reviews/code-fact-check-report-r{1,2,3}.md] → [orchestrator merge input]
B3 (moved): [analyst sub-agent verdict] → [orchestrator-authored merged report, most-severe-wins] → [Fact-Check Gate / 🔴 merge-blocking rubric row]
B4 (new): [committed docs/reviews artifacts from any prior branch or run] → [`code-fact-check-report-r*.md` glob] → [Stage 3 Confirmed-Good cross-check]
B5 (widened): [unattended self-improvement.sh round/task loop] → [3× agent fan-out per code-review invocation] → [filesystem writes + external API spend]
```

What enters from outside: raw completions from three external inference vendors (B1), now committed as ordinary tracked markdown. What crosses trust levels internally: the fact-check verdict, whose authority is merge-blocking — the diff moves the point where that verdict is finalised from an analyst sub-agent to the orchestrator itself (B3), and introduces on-disk intermediate artifacts (B2) that a later stage re-reads by wildcard (B4). The load-bearing assumption throughout is that everything under `docs/reviews/` and `runs/` is this-run, this-branch, self-authored content. Both `docs/reviews/` and `runs/` are git-tracked (neither appears in `.gitignore`; `git ls-files docs/reviews/` lists 20+ committed reports), so that assumption is false by construction the moment a replicate report is committed.

## Findings

#### Stale committed replicate reports are indistinguishable from this run's, and feed the Confirmed-Good gate

**Severity:** Medium
**Location:** `skills/code-review/SKILL.md:936-939`, `skills/code-review/SKILL.md:1064-1068`
**Boundary:** B4
**Move:** #4 (time-of-check to time-of-use), #2 (implicit sanitization assumption)
**Confidence:** High
**Legibility-target:** for-author

The Stage 3 Confirmed-Good cross-check selects its inputs by wildcard:

```
**4. Cross-check every ✅ row against the fact-check reports (Stage 3, before publishing).**
For each candidate ✅ row, re-read the merged fact-check report **and each per-replicate
report** (`code-fact-check-report-r*.md` — an observation recorded by only one replicate
may be absent from the merged claim it lost the severity contest to, and it still counts)
```

and the Output Locations tree places those files in a directory that is tracked in git, not ignored:

```
docs/reviews/
├── code-fact-check-report.md      (merged, most-severe-wins — the canonical report)
├── code-fact-check-report-r1.md   (replicate — audit + Confirmed-Good observation scan)
├── code-fact-check-report-r2.md   (replicate)
├── code-fact-check-report-r3.md   (replicate)
```

Nothing in Stage 1 or Stage 3 scopes the glob to the current run, stamps the replicate reports with a commit or run identity, or clears prior replicates before writing. `docs/reviews/code-fact-check-report.md` is already a committed, tracked file, so the same will be true of `-r1..3.md` after the first run that commits its artifacts. From then on, every worktree checked out from that branch — including the fresh worktrees `scripts/self-improvement.sh` reviews — starts with a populated `code-fact-check-report-r*.md` set describing *a different diff*. The cross-check will read those observations, and its documented behaviour on a contradiction is not advisory: the ✅ row is demoted to 🟡 with `Severity: Contested`. A prior branch's observations can therefore contest a clean row on an unrelated change, and — in the other direction — a genuinely clean run inherits stale evidence rather than the absence of evidence it should record. This is the same failure class decision log row 25 already paid for: `select_run_rubric()` was introduced precisely because `ls -1 …/code-review-rubric*.md | head -1` "reliably [picked] the *oldest* rubric whenever a prior branch's rubric is carried in-tree, which is the norm," and two measurement batches were discarded to it. The new glob reintroduces the pattern one directory over.

**Recommendation:** Scope the replicate artifacts to the run — either write them under a per-run subdirectory (`docs/reviews/<commit-or-run-id>/code-fact-check-report-r<N>.md`) and glob within it, or require Stage 1 to delete any pre-existing `code-fact-check-report-r*.md` before dispatching replicates and require the cross-check to skip any replicate whose header commit does not match the reviewed commit. Adding `docs/reviews/code-fact-check-report-r*.md` to `.gitignore` is a cheaper partial fix but does not protect the self-improvement worktrees if the files are ever committed by hand.

#### Unattended 3× fan-out of write-capable agents with no cap or budget guard

**Severity:** Medium
**Location:** `skills/code-review/SKILL.md:260-262`, `skills/code-review/SKILL.md:292-293`; consumer at `scripts/self-improvement.sh:1106,1419`
**Boundary:** B5, B2
**Move:** #8 ("what if there are a million of these?"), #3 (error path)
**Confidence:** Medium
**Legibility-target:** for-author

Stage 1 triples the agent count unconditionally:

```
Spawn **three** agents with the code-fact-check skill, in parallel, on **byte-identical
prompts** — same skill text, same scope spec, same instructions, differing only in the
output path each is told to write.
```

```
7. Launch via the Agent tool with `subagent_type: "general-purpose"` — all three replicates
   in a single message so they run in parallel and cannot see each other's output.
```

The primary consumer is not an interactive user. `scripts/self-improvement.sh:1106` iterates `for TASK_ID in $LAUNCHED_TASKS; do`, nested inside `for ROUND in $(seq 1 $MAX_ROUNDS)`, and line 1419 invokes a headless `claude -p` code-review per task, per round, with `mapfile -t CR_FLAGS < <(claude_headless_flags "$CR_ADD_DIR")` — i.e. `--permission-mode acceptEdits` plus `--add-dir`. Each of those invocations now spawns three write-capable fact-check agents instead of one, so the multiplier is 3 × tasks × rounds on an overnight loop with no human present. There is no per-run agent cap, no token or cost ceiling, and no back-off if a provider rate-limits. The realistic failure is not an attacker but the loop itself: a rate-limit or quota exhaustion mid-round degrades replicates silently into the k=2 path (see next finding) or fails the review step, and the archived-artifact copy at line 1433 (`cp -f "$WT_DIR"/docs/reviews/*.md "$CR_ARCHIVE/"`) triples per-round archive volume. The three replicates also write concurrently into one shared worktree under `acceptEdits`; the distinct output paths make a clobber unlikely, but nothing in the prompt forbids a replicate from writing the canonical `code-fact-check-report.md` path instead, which is a tracked file.

**Recommendation:** Gate k on the invocation context — keep k=3 for interactive/PR reviews and make it configurable (e.g. `SI_FACTCHECK_K`, default 1 or 2) for the self-improvement loop, since that loop consumes only the `CODE_REVIEW_RED` count and not the stability metric. At minimum, state an explicit ceiling on concurrent fact-check agents in the skill and have Stage 1 refuse to dispatch if a replicate output path already exists.

#### The blocking artifact is now authored by the orchestrator, carving an exception to an "absolute" rule with no provenance check

**Severity:** Low
**Location:** `skills/code-review/SKILL.md:314-330` (merge step), rule at `skills/code-review/SKILL.md:56-62`
**Boundary:** B3
**Move:** #1 (trace the trust boundaries), #7 (serialization boundary — what is asserted vs. what is verified)
**Confidence:** High
**Legibility-target:** for-author

Mandatory Execution Rule 1 is stated as unconditional:

```
## Mandatory Execution Rules

These rules are absolute. Do not deviate from them under any circumstances.

1. You MUST use the Agent tool to spawn sub-agents for ALL fact-checking and critique work.
   You MUST NOT write fact-checks or critiques yourself. You are the orchestrator, not an
   analyst. If you find yourself writing analytical observations about the code, STOP — you
```

The merge step then has the orchestrator author the canonical report, asserting the activity is not analysis:

```
Produce the canonical `docs/reviews/code-fact-check-report.md` yourself by merging the
replicate reports. This is mechanical collation, not analysis — you are combining verdicts
the replicates already produced, never adding claims or evidence of your own (Mandatory
Execution Rule 1 still stands).
```

The disclaimer is not supported by the procedure it introduces. Step 1 requires semantic judgment — "Clustering is semantic — replicates word the same claim differently; match on (file, line-range, claim substance), not on string equality" — and cluster boundaries determine which verdict wins and what the agreement rate is. Two claims wrongly merged discard the more severe verdict's independence; two wrongly split inflate the agreement denominator. The security consequence is that the single file every downstream gate consumes ("Everything downstream — the Fact-Check Gate, Stage 1.5 critic gating, critic prompts, the Confirmed-Good cross-check, and the severity mapping — consumes the **merged** report") is now produced by a component the skill elsewhere forbids from analysing code, and there is no contract test on the merged report's provenance: `test/skills/code-fact-check-format.bats:11` loads `docs/reviews/code-fact-check-report.md` and validates format only. Nothing detects an orchestrator that quietly drops or downgrades a cluster.

**Recommendation:** Either narrow Rule 1 explicitly ("collation of sub-agent verdicts is permitted; origination of claims or evidence is not") so the exception is legible rather than asserted away, or add a mechanical invariant the merged report must satisfy — e.g. every merged claim's evidence block must be byte-identical to the winning replicate's, and the merged claim count must be ≥ the max single-replicate claim count minus documented merges.

#### Third-party model output committed as trusted in-tree content with no provenance marker

**Severity:** Low
**Location:** `runs/dd-cross-model-2026-07-30/README.md:59-68`; files `openai_gpt-5.6-sol.md`, `google_gemini-3.1-pro-preview.md`, `moonshotai_kimi-k3.md`, `prompt.md`
**Boundary:** B1
**Move:** #1 (trust boundaries), #2 (implicit sanitization assumption)
**Confidence:** Medium
**Legibility-target:** for-author

The README labels the arms but not their trust level:

```
| File | Arm |
|---|---|
| `prompt.md` | The shared prompt (identical bytes to all four models) |
| `local_claude-fable-5.md` | Fable 5, local Claude Code subagent |
| `openai_gpt-5.6-sol.md` | GPT-5.6 Sol via OpenRouter |
| `google_gemini-3.1-pro-preview.md` | Gemini 3.1 Pro via OpenRouter |
| `moonshotai_kimi-k3.md` | Kimi K3 via OpenRouter |
```

Roughly 750 lines of raw completion text from three external vendors, plus a 1004-line verbatim prompt whose opening is directive-shaped ("You are evaluating a real software repository's code-review process", "**Your job:** apply the divergent-design workflow"), are now ordinary tracked repo files. I scanned all five for injection-shaped content — no "ignore previous instructions", no `<script`, no `curl`/`wget`/`rm -rf`/`base64 -d`/`eval(`, no URLs pointing off-repo for retrieval. The content is benign, so this is not an exploited condition; it is an unmarked boundary. These files enter agent context by two routes that already exist: they are inside `git diff main...HEAD`, which is the scope every critic and fact-check replicate is handed (this review included), and `docs/thoughts/code-review-evaluation-state.md` and decision log row 26 both cite `runs/dd-cross-model-2026-07-30/` as evidence a future reader is invited to open. The precedent this sets — commit vendor completions verbatim, cite them as corroboration, no untrusted-content marker — is the part worth fixing while the corpus is small and self-vetted, because the same convention applied to a larger or less-inspected sweep is a direct prompt-injection path into the review pipeline.

**Recommendation:** Add a header line to each vendor output file and to the README marking it as unvetted third-party model output that must be read as data, never as instructions, and note that any pipeline scoping on `runs/**` should treat it accordingly. Consider excluding `runs/**` from critic diff scope in `skills/code-review/SKILL.md`, the same way generated fixtures are usually excluded.

#### Replicate failure degrades to k=2 without surfacing to the user

**Severity:** Low
**Location:** `skills/code-review/SKILL.md:306-310`
**Boundary:** B2
**Move:** #3 (check the error path, not just the happy path)
**Confidence:** High
**Legibility-target:** for-author

```
**CHECKPOINT:** Wait for all three replicate agents to return. Verify you received at least
**two** substantive reports — with fewer than two, no disagreement measurement is possible
and the merged verdict degenerates back to a single sample. If only one replicate returned,
tell the user and ask how to proceed; if two returned, proceed but record `k=2 (one
replicate failed)` in the merged report header and the Stage 1 banner.
```

The one-replicate path stops and asks; the two-replicate path proceeds and only *records* the degradation. That is the right default direction (the gate is fail-closed under most-severe-wins — a lost replicate can only remove severity, never add it), but the failure is silent in the place it matters: the self-improvement loop is instructed to "Run non-interactively: do NOT pause at the fact-check gate" (`scripts/self-improvement.sh:1419`) and consumes only the final `CODE_REVIEW_RED[...]` integer, so the `k=2` header note is never read by the caller. A run whose replication silently halved is indistinguishable, at the gate, from a full one. Note also that "substantive" is undefined — a replicate returning a well-formed report with zero claims satisfies the check while contributing no independent sample.

**Recommendation:** Define "substantive" (e.g. a parseable report with ≥1 claim and a Goal-Alignment Note), and propagate degradation into the machine-readable output the loop consumes — e.g. a second final line `FACTCHECK_K[<nonce>]: 2` alongside `CODE_REVIEW_RED`, so a degraded run is visible to the gate and not only to a human reading the header.

#### Replication triples the volume of verbatim source quotations committed to a tracked directory

**Severity:** Informational
**Location:** `skills/code-review/SKILL.md:1064-1068`
**Boundary:** B2
**Move:** #6 (follow the secrets)
**Confidence:** Medium
**Legibility-target:** for-author

Fact-check reports quote reviewed source verbatim as evidence — that is the format's core requirement. The Output Locations tree now persists three additional such reports per review in `docs/reviews/`, which is git-tracked and, per `scripts/self-improvement.sh:1431-1433`, additionally copied wholesale into `$WORKING_DIR/reviews/round-$ROUND/$TASK_ID`. In this repo the reviewed material is workflow prose, so the exposure is nil. The structural point is that any future review of a diff containing a credential, a fixture token, or a private path now produces three extra committed copies of that text instead of one, in a directory that is neither ignored nor pruned. No cleanup or retention rule is stated.

**Recommendation:** Add a retention line to the Output Locations section — replicate reports are run-scoped audit artifacts and should be gitignored or pruned after the rubric is published; the merged report is the durable one.

#### k=3 hardens one of five 🔴-promotion channels while the diff's prose claims it is the only one

**Severity:** Informational
**Location:** `skills/code-review/SKILL.md:26-29`, `skills/code-review/SKILL.md:263-270`, table at `skills/code-review/SKILL.md:974-978`
**Boundary:** B3
**Move:** #5 (invert the access control model — enumerate what the control does *not* cover)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The Stage 1 rationale rests on exclusivity:

```
**Why three.** The fact-check verdict is the *only* channel that promotes a finding to 🔴
(see [Unified Severity Mapping](#unified-severity-mapping)), and it is the least stable
judgment in the pipeline
```

The table it cites lists five:

```
| Rubric Tier | Security | Performance | API Consistency | Architecture | Fact-Check |
|---|---|---|---|---|---|
| 🔴 Must Fix | Critical, High | Critical | Breaking | Structural | Incorrect (high confidence) |
```

The orchestrator's fact-check already filed the exclusivity claim as Incorrect, so I am not re-verifying it; the security-relevant consequence is what the correction implies for assurance. Inverting the control: after this change, one of five merge-blocking channels is sampled k=3 and reports a stability metric, while Security Critical/High, Performance Critical, API Breaking, and Architecture Structural remain single-sample — and those are the four channels that carry the actual vulnerability verdicts. A reader of the new `## Verdict stability` section, or of the Stage 1 banner's "verdict agreement 10/12 clusters", can reasonably infer the pipeline's blocking decisions are now measured. They are not; the security blocking channel is exactly as unmeasured as before. Decision log row 25 already installed a "single-sample review; absence of findings is not an attestation" line for clean runs, which is the right instinct — this diff should not be allowed to quietly weaken that framing for non-clean runs.

**Recommendation:** When correcting the exclusivity wording (already required by the fact-check), scope the `## Verdict stability` section's claim explicitly — e.g. "agreement rate covers the fact-check channel only; the four critic 🔴 channels remain single-sample" — so the metric is not read as pipeline-wide assurance.

## What Looks Good

- **The aggregator choice is correct and correctly justified.** Most-severe-wins is fail-closed: a single replicate proving a defect blocks, and no combination of replicate failures can *lower* a verdict below what any replicate assigned. Majority vote is explicitly rejected in the text ("Majority vote is explicitly the wrong aggregator here"), with the under-calling failure mode named as the reason. For a merge gate, this is the right direction to be wrong in.
- **The confounding surface is pinned deliberately.** `skills/code-review/SKILL.md:279-280` names the output path as "the **only** permitted difference between the three prompts — anything else varying would confound the disagreement measurement," and `test/skills/code-review-factcheck-replication.bats:43-48` enforces that the constraint is stated. Replicates are also dispatched in a single message so they "cannot see each other's output" (`:292-293`) — independence is designed in, not assumed.
- **No secrets, keys, or account identifiers in the committed run artifacts.** The three `.meta.json` files carry model ID, `finish_reason`, token counts, cost, and latency only. Committing `prompt.md` verbatim rather than a summary is also the right call for reproducibility, and it contains no credentials or private paths.
- **The contract suite is honest about what it proves.** `test/skills/code-review-factcheck-replication.bats:12-13` states plainly: "an unenforced prose instruction does not execute. These tests assert the contract is stated." That is the correct scope claim for a prose-contract suite, and it is more than most such suites disclose. The severity-order assertion at `:67-71` is genuinely load-bearing — it pins the mechanical definition of "most severe" against silent reordering.
- **Degradation is bounded rather than open-ended.** The k<2 case stops and consults the user instead of proceeding on a single sample; my finding above is about propagating the k=2 case, not about the existence of the floor.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Stale committed replicate reports feed the Confirmed-Good gate via unscoped glob | Medium | B4 | `skills/code-review/SKILL.md:936-939` | High |
| 2 | Unattended 3× fan-out of write-capable agents, no cap or budget guard | Medium | B5, B2 | `skills/code-review/SKILL.md:260-262`; `scripts/self-improvement.sh:1106,1419` | Medium |
| 3 | Orchestrator authors the blocking artifact; Rule 1 exception unverified | Low | B3 | `skills/code-review/SKILL.md:314-330` | High |
| 4 | Third-party model output committed as trusted in-tree content, unmarked | Low | B1 | `runs/dd-cross-model-2026-07-30/README.md:59-68` | Medium |
| 5 | Replicate failure degrades to k=2 without reaching the automated gate | Low | B2 | `skills/code-review/SKILL.md:306-310` | High |
| 6 | 3× verbatim source quotations persisted to a tracked directory, no retention rule | Informational | B2 | `skills/code-review/SKILL.md:1064-1068` | Medium |
| 7 | Stability metric covers 1 of 5 🔴 channels but reads as pipeline-wide | Informational | B3 | `skills/code-review/SKILL.md:263-270,974-978` | High |

## Overall Assessment

The security posture of this change is sound in its core mechanism and weak in its artifact lifecycle. The gate itself moves in the safe direction — most-severe-wins is fail-closed, replicate independence is designed rather than assumed, and the degradation floor stops before a single sample can masquerade as three. Nothing here is exploitable by an external party, and no escalation pattern is present. The two Medium findings are both consequences of the same unexamined decision: the change introduces persistent on-disk state (`code-fact-check-report-r*.md`) into a git-tracked directory, and then reads that state back by wildcard, without scoping either write or read to the run. That is not a new class of problem for this repo — decision log row 25 documents two measurement batches already lost to the identical stale-artifact pattern one directory over — which is what makes it the single most important thing to address: scope the replicate artifacts to the run (per-run subdirectory or a commit-stamped header the cross-check filters on) before the first run commits them and the failure becomes the default. Everything else is fixable in place; none of it indicates an architectural problem with replication itself.

## Goal-Alignment Note
- Answered: yes — security review of the branch diff, report saved
- Out of scope: internal quality of the immutable `runs/` model outputs (scanned only for secrets and injectable content, per the brief); re-verification of the supplied Stage 1 fact-check findings; `scripts/self-improvement.sh` and `scripts/cross-model-review.py` themselves, which are unchanged on this branch and were read only as consumers
- Escalate: nothing requiring human attention before merge — finding 1 should be fixed before the first k=3 run commits its replicate artifacts, since after that point the stale-glob condition is the default rather than a possibility
