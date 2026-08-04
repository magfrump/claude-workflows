# Handoff — Stand up the SWR-Bench GT-interpretation fork as its own project

- **Goal**: Give a fresh session everything needed to spin the benchmark (decision 029) out of claude-workflows into a standalone SWR-Bench fork project.
- **Project state**: benchmark design decided (029) and pre-mortem gated · claude-workflows remains the system-under-test, the fork becomes the measuring instrument · not blocked.
- **Task status**: complete (this doc is the deliverable; implementation happens in the new project)

## Why a separate project

The benchmark is a full project (judge implementation, dataset handling, metrics,
calibration protocol) whose lifecycle is independent of the review process it measures.
Keeping it in-repo couples instrument to subject and bloats this repo's scope. This doc is
the boundary artifact: the new project starts from here, this repo keeps only the
system-under-test and the interface contract.

## The decision being implemented

**Design [A] from `docs/decisions/029-code-review-benchmark-architecture.md`** — a
SWR-Bench fork with GT-side reinterpretation:

1. **Categorize GT/predicted feedback** — TP / VU / OOS / NB / FP taxonomy so accurate
   low-impact findings are scored differentially from FPs that request bug-introducing
   changes (that differential is the design point, not a loophole — see revised
   pre-mortem narrative 2).
2. **Assess accuracy of every predicted item by default** — Stage-1 fact verification
   with quote/line grounding, attestation-before-severity.

Chosen framing (Diamond 1): *decision instrument ranking review-process configs by
verified-bug recall per dollar; clean-PR specificity and human-calibrated judge are hard
validity preconditions.* External comparability to published SWRBench tables is a **soft**
constraint — deliberately deprioritized, not forgotten.

Falsifiable hypothesis for the whole effort: *judge–human kappa ≥ 0.6 on 30 stratified
findings, and diff-only vs agentic arms separate beyond bootstrap CI, within 2 weeks of
implementation start; counter-evidence = kappa < 0.4 or overlapping CIs at n=30.*

## Documents to copy into the new project (in this order of authority)

| Artifact (path in this repo) | Role in new project |
|---|---|
| `docs/gemini-SWRench.md` | **The v2 judge spec** — normative. §2 taxonomy+WUS, §3 sequential judge flow, §4 static-context protocol, §5 prompts, §6 audit artifacts, §7 acceptance criteria. Already draft-reviewed (1 factual error + 9 must-address items applied, commit `728bcc4`). |
| `docs/decisions/029-code-review-benchmark-architecture.md` | Decision record + revisit triggers. Copy verbatim as the project's founding decision. |
| `docs/reviews/pre-mortem.md` | **Sequencing authority** — its two must-address items are implementation gates (below). Narrative 2 was revised 2026-08-03 after author correction; use the revised version only. |
| `docs/working/dd-code-review-benchmark.md` | Full DD trail: constraints (H1–H5, S1–S4), pruned candidates, stress tests. Reference, not normative. |
| `docs/working/swrbench-adapter-2026-07-31.md` | Adapter state, first judged numbers, cost measurements, run inventory. |
| `docs/reviews/fact-check-report.md`, `ai-personas-critique.md`, `yglesias-critique.md` | The draft-review artifacts on the spec — why the spec says what it says. |

## Existing code and data (the fork already exists locally)

`/workspace/external/SWRench` — clone of `https://github.com/ZZR0/SWRench.git` (upstream
base `67ae1d4`) with three local commits:

- `305edc9` — `swrbench/cw_review.py`: generation baseline running this repo's review
  process against SWRBench instances → judge-ready `generation.jsonl`. Backends:
  `--backend openrouter` (headless cross-model harness, `--context-mode {stage1,diff-only}`)
  and `--backend agentic` (one headless `claude -p` run of the full `code-review`
  orchestrator per instance, in a reconstructed PR worktree).
- `a85f416` — agentic backend.
- `02ee503` — offline evaluation unblock: fix for real `os.getenv[...]` import-time bug in
  `swrbench/utils.py`, stdlib shims for PyPI-blocked deps (`shims/`), and
  `scripts/judge_claude_cli.py` — stock `evaluation_struct.py` prompts/parsers/metrics with
  only `utils.run_chat` transport swapped to Claude CLI.
- Untracked: `scripts/color_crosstab.py` (commit or drop when migrating).

Data/runs under `logs/swr_datasets_d5c5/` (dataset revision **d5c5** — pin it):

- `cw-agentic-smoke/` (n=1 clean), `cw-agentic-test6/` (n=6 balanced, $90 total),
  `cw-agentic-b30/` (balanced-30, 15 changed + 15 clean, all astropy; generation snapshots
  at n=7 and n=12 present; judged: `evaluation__claude-sonnet-5.json` for the first 7, with
  id-keyed judgment cache `evaluation__*.tmp.jsonl` — cache carries over, don't discard).
- PR reconstruction: cached `--filter=blob:none` clone → worktree at `base_commit` →
  per-commit dataset diffs (tolerant fallback chain). Astropy reconstruction rate 18/20;
  failures are dataset base-drift, diverted to `generation.jsonl.errors` so the judge never
  scores them.

**Migration move:** relocate `external/SWRench` to its own top-level repo (preserve the
three local commits and `logs/`), keep `origin` = ZZR0/SWRench for future rebases. Hosting
is the user's call — this user works local-only by default (no auto-push, no PRs).

## Interface contract with claude-workflows (what stays here)

The fork treats this repo as a black-box system-under-test:

- **Invocation**: headless `claude -p` running the `code-review` orchestrator skill
  (k=3 fact-check + critic panel) inside a reconstructed PR worktree; or the
  `scripts/cross-model-review.py` harness for cheap arms.
- **Output**: judge-ready `generation.jsonl` rows (schema as produced by `cw_review.py`).
- **Cost accounting**: per-instance $ and wall-clock captured by the harness (measured:
  agentic $7.26–$30.83, mean ≈ $14.6, 12–32 min; openrouter arms cents/sub-cent).

Changes to the review process (arms) happen here; the fork only ever consumes
`generation.jsonl` + cost logs. Keep that boundary — it is what makes arm comparisons
clean.

## Implementation sequencing (pre-mortem gates — order is normative)

1. **Gate 1 — kappa pilot before any full-arm judging** (narrative 1, must-address).
   Implement the v2 judge (§3 flow, §5 prompts) → judge a stratified 30-finding pilot
   drawn from the cached n=7 judgments → human-adjudicate (~2 h) → record kappa in run
   config. `run.sh eval` at full scale is blocked until kappa ≥ 0.6. Include NB/OOS-routed
   findings in the sample so misrouting is measured (revised narrative 2), and ≥10 TP
   matches scored for match-tightness (narrative 3).
2. **Gate 2 — Stage-1 falsifiability** (revised narrative 2, must-address). Before the
   pilot, tighten spec §3 Stage 1: entry requires a *falsifiable* factual claim (concrete
   defect or predicted misbehavior); unfalsifiable advisory findings route to FP or a
   dedicated zero-content category, never NB.
3. **Gate 3 — discrimination pilot** (validation, pre-registered). On 10 instances,
   confirm reported WUS + says-clean pair ranks firehose < curated < diff-only via
   denominator dilution as designed. Pre-register the expected ordering in the fork README
   before running.
4. Then: finish balanced-30 judging (reuse cache), report WUS **beside** legacy P/R/F1
   (never standalone — WUS is precision-side-only, §2.2), bootstrap CIs for arm
   separation, clean-PR says-clean rate as first-class metric.
5. Cheap early tasks: §6.1 provenance naming — embed
   `{upstream_commit}__{dataset_rev}__{judge_model}` in every evaluation filename
   (narrative 5); §7 adjudication caps — 30 findings per judge version, top-5 severity VUs
   per sweep (narrative 4).

## Known traps (verified this session or last)

- `OPENROUTER_API_KEY` is **defined but empty** in session env and `/etc/environment` —
  the Gemini judge and cheap openrouter arms are key-blocked until fixed. The Claude-CLI
  judge is the working transport; keep it pinned per run.
- **Claude-judging-Claude bias** is unaudited — before publishing any numbers, add a
  second judge model as robustness check (needs the key fix) and stratify the kappa sample
  across arms.
- 64 dataset PRs are Python-2-era: no Py3 parser handles them — §4's textual quote/line
  verification is the universal baseline; `ast`/`libCST` enrichment is best-effort with
  `parse_fallback: true` flagging. Never assume the toolchain parses Py2 (this was the
  spec's R1 factual error, already fixed).
- All astropy so far — hold out a second repo slice before drawing writeup conclusions.
- All 5 GT change-points in the judged n=7 slice were E-type; F-band recall untested.
- Judge results are only internally comparable while the judge stays pinned; published
  SWRBench tables use a Gemini-flash judge and are not comparable to Claude-judge numbers.

## Definition of done for the standalone project's first milestone

Kappa recorded ≥ 0.6 (else: halt per revisit trigger in 029), discrimination pilot ordering
holds, and one full arm comparison (diff-only vs agentic, n ≤ 30, ≤ $350/arm from logs)
reported as WUS + P/R/F1 + says-clean + $/verified-bug with bootstrap CIs. That table is
what feeds back into `docs/human-author/CodeReviewWriteup.md` here.
