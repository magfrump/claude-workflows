# CRB arm plan: fair-competition measurements via Code Review Bench

**Date**: 2026-08-14 · **Status**: both dry runs green; paid runs pending API key
**Companion to**: `canon-issue-ledger.md`, `review-canon.md` ·
**Benchmark**: `external/code-review-benchmark` (withmartian, MIT; offline half)

## What the benchmark gives us

Two measurement directions, both wanted; **(2) is the priority**:

1. **Our processes on their dataset** — 50 PRs across sentry/grafana/cal.com/
   discourse/keycloak with human-curated golden comments (severity + category),
   plus **checked-in scored results for ~49 tools** under three judge models
   (`offline/results/{judge}/evaluations.json`). Running our arm through their
   judge slots us into an existing leaderboard without re-running any other tool.
2. **Their format + judge on our canon** — express the canon issue ledger as
   golden comments; any review output we can collect locally then gets scored by
   a third-party extract→dedup→judge pipeline we didn't write. That is the
   "fair competition" arm: same judge, same matching rules, incumbent has no
   home-field advantage.

## The no-GitHub-app insight (verified 2026-08-14)

Only steps 0–1 of the offline pipeline touch GitHub (forking PRs, downloading
bot comments via `gh`). **Steps 2 → 2.5 → 3 → dashboard operate purely on local
JSON** (`results/benchmark_data.json`), and the LLM client is a plain
OpenAI-compatible endpoint configured by env vars:

```
MARTIAN_API_KEY / MARTIAN_BASE_URL / MARTIAN_MODEL
```

So both directions bypass the GitHub-app machinery by writing
`benchmark_data.json` entries directly. Verified judge-endpoint options:

- **OpenRouter** (`MARTIAN_BASE_URL=https://openrouter.ai/api/v1`, key =
  `OPENROUTER_API_KEY`) — what the E2/E4 sweeps already use.
- **Anthropic's OpenAI-compat endpoint** (`https://api.anthropic.com/v1/`) with
  `MARTIAN_MODEL=claude-opus-4-5-20251101` — this exactly matches the model id
  of a checked-in results dir, minimizing judge-variance caveats when comparing
  against the published leaderboard. Prefer this for direction (1) scoring.

Results land in `results/{MARTIAN_MODEL sanitized}/`; keep our runs in a
separate work dir (below) so the vendored repo stays clean.

## Dry-run state (all green, $0 spent)

Working dir: `runs/review-arms/crb/`

| Piece | Status |
|---|---|
| `scripts/canon-to-crb.py` | canon-issue-ledger.csv → `offline-work/golden_comments/meta_formalism_copilot.json` (8 instances, **45 goldens**) + `offline-work/results/benchmark_data.json` with tools `e2` and `e4-union` injected from existing findings.jsonl |
| Steps 2 / 2.5 / 3 end-to-end | run with `shims/` (deterministic no-network `openai`+`tqdm` stand-ins on `PYTHONPATH`); all 8 instances × 2 tools extract, dedup, judge, and aggregate cleanly into `evaluations.json` |
| Benchmark PR materialized locally | anonymous `git clone --filter=blob:none` of `code-review-benchmark/discourse__…__PR3__…` (public org, 800 forks); PR#1 head/base refs fetched; merge-base = base sha |
| Our harness accepts it | `review-arms.py --dry-run` on the clone: prompt built, ~30k tokens, ~$0.075/call projected |

Stub caveats (dry-run only, replaced by a real judge): extraction shim keeps
only each comment's first line; judge shim is a word-overlap heuristic. The
near-zero stub scores are meaningless by design.

Reproduce the (2) dry run:

```bash
python3 scripts/canon-to-crb.py
cd runs/review-arms/crb/offline-work
export PYTHONPATH=../shims:/workspace/external/code-review-benchmark/offline
export MARTIAN_API_KEY=stub MARTIAN_MODEL=stub/dry-run
python3 -m code_review_benchmark.step2_extract_comments
python3 -m code_review_benchmark.step2_5_dedup_candidates
python3 -m code_review_benchmark.step3_judge_comments --dedup-groups results/stub_dry-run/dedup_groups.json
```

(Sandbox note: pypi is blocked here, hence the shims; on the host, `uv sync` in
`offline/` + real env vars replaces them — unset `PYTHONPATH` and the real
packages take over.)

## Canon-as-goldens mapping decisions (adjudication pending)

- 8 entries keyed by pseudo-URLs `https://local.invalid/meta-formalism-copilot/{instance}`
  (keys are opaque to steps 2–3).
- Included: strata A (24) + B (9) + C (4) + D6 + N1–N7 = 45. **Excluded**:
  D1–D5 (live on fix commits `4f018ab`/`4de2b00`, not findable in any of the 8
  reviewed inputs). If we later add fix-state instances, they become two more
  entries.
- Severity/category are **provisional auto-mappings** (hand table in
  `canon-to-crb.py`, benchmark taxonomy: bug/security/…/doc_defect/style);
  each golden carries `mapping_provenance` + `canon_issue_id`. Adjudicate before
  publishing numbers — category drives the Strict/Core/All scoring profiles,
  and much of our canon is doc_defect/test_gap (excluded from Strict; note this
  when quoting profile-relative recall).
- Ledger stays the source of truth; the converter re-derives on demand
  (findable-denominator logic mirrors the ledger's rules).

## Next steps — direction (2), priority order

1. **Real-judge scoring of existing arms on the canon** (~$1–3, needs
   `OPENROUTER_API_KEY` or Anthropic key): re-run steps 2/2.5/3 without shims.
   Output: third-party-judged P/R for e2 and e4-union, directly comparable to
   our hand-scored ledger columns — a calibration check on our own adjudication.
2. **Inject the Pipeline as a tool**: convert the historical rubric findings
   (or better, a fresh pipeline run's report) into `review_comments` for tool
   `pipeline`. The extract LLM handles freeform markdown, so the whole report
   can go in as one general comment. Then the fair-competition table is:
   pipeline vs e2 vs e4 vs e5 (convert E5's dockerized /code-review outputs the
   same way), one judge, one matcher.
3. **Other benchmark tools on the canon, no GitHub app**: locally-runnable
   reviewers only — `claude` CLI (their own `scripts/claude_clone_and_review.clj`
   pattern: checkout dirty state, run /code-review), Codex CLI, Gemini CLI,
   Qodo PR-Agent CLI, CodeRabbit CLI. Each reviews the mfc checkout at the
   instance range; output → `review_comments`. SaaS-only bots (Greptile,
   Graphite, Copilot…) genuinely need hosted PRs + app installs — deferred;
   would require pushing mfc instances as PRs to a public repo (privacy call
   for the author, and against current no-GitHub-routing practice).

## Cubic CLI arm (2026-08-14; author chose Claude-Code auth over API key)

Cubic ships a local CLI (`npm i -g @cubic-dev-ai/cli`, compiled binary) with
`cubic review --base <branch> --json` — reviewable per canon instance without
any GitHub app. Auth via `cubic auth connect claude-code` (reuses the Claude
Code login; alternatives: `codex`/`cursor` connect, `cubic auth login`, or
`ANTHROPIC_API_KEY`/`OPENAI_API_KEY` + `CUBIC_ANTHROPIC_BASE_URL` — OpenRouter's
`/v1/messages` verified Anthropic-compatible if the BYO-key route is ever
wanted).

Runner: **`runs/review-arms/crb/run-cubic.sh`** (setup steps in header; run in
a normal terminal — the CLI can't be executed from sandboxed sessions, the
auto-mode classifier blocks it). Idempotent; worktrees under
`external/crb-cubic/`; output `runs/review-arms/crb/cubic-cli/<inst>/review.json`.
`canon-to-crb.py` already picks those up as tool `cubic-cli` (tolerant schema
parser + freeform fallback; tighten after the first real run shows the schema).

Caveat for the ledger: this is cubic's *local* review, documented by cubic as
"intentionally faster and less thorough" than the cloud PR review their
leaderboard row was scored on. File results as `cubic-cli`, not `cubic`.

## Next steps — direction (1)

1. Script the materialization loop over the 50 PRs (one fork per original PR,
   any tool's copy — e.g. the `__claude__` forks; anonymous partial clones,
   ~20MB–900MB each; discourse smallest, keycloak/grafana largest — budget
   ~15–25GB disk for all 50, or stream one at a time and delete).
2. **Cost-staged runs**:
   - Lite arms (base/k3) on all 50: ~$4–8 total. Cheap first signal.
   - Full pipeline at ~$14.60/instance ≈ **~$730 for 50** — do a stratified
     subset first (2 PRs × 5 repos ≈ $150) before deciding on the full sweep.
3. Convert findings → `review_comments` (tool name e.g. `mfc-pipeline`),
   append to a copy of the benchmark's own `results/benchmark_data.json`, run
   steps 2/2.5/3 with the Anthropic-endpoint judge above, and read our row
   against the checked-in leaderboard rows (same judge model id). Judge cost:
   dominated by step 3's golden×candidate matrix; with opus-4-5 expect
   ~$5–15/tool-sweep, sonnet-4-5 ~1/5 of that.

## Open questions for the author

- Severity/category adjudication of the 45 mapped goldens (30 min with the
  table in `canon-to-crb.py`).
- Which judge to make primary (opus-4-5 for leaderboard comparability vs
  sonnet-4-5 for cost) and whether to run both as a variance check.
- Disk/budget approval for direction (1)'s clone set and the pipeline subset run.
