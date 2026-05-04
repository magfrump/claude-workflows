# Plan: SI Duplicate Detector

**Goal:** Surface candidate-vs-prior matches in the SI loop after DD generation so the round can review near-duplicates before pruning.
**Project state:** SI loop currently has no automatic duplicate check; idea #15 from `feature-ideas-round-1.md` calls for one · standalone task within R1 cycle · not blocked.
**Task status:** in-progress (implementation phase)

## Context

The SI loop in `scripts/self-improvement.sh` runs a divergent-design pass each round, writing candidates to `docs/working/feature-ideas-round-$ROUND.md`. Today, near-duplicate detection happens implicitly when DD itself prunes against `completed-tasks.md` context. Round 1 idea #15 calls for explicit pre-prune duplicate surfacing.

## Decision (interpretation of "pre-diverge")

Run the duplicate check **between DD generation and the SI loop's task-filtering (prune) step**, in line with the task description's literal wording: "surfacing near-duplicates at generation time" and "list of candidate-vs-prior matches the round can review before pruning."

A truly pre-generation hook can't compare "each new candidate" because no candidates exist yet — so this is the only consistent reading.

## Approach

1. **New function** `detect_duplicate_candidates` in `scripts/lib/si-functions.sh`:
   - Args: `(round, working_dir)`
   - Reads `feature-ideas-round-$round.md` and extracts numbered candidate entries
   - Globs prior idea/completed-task files: `feature-ideas-round-*.md` (excluding current), `archive/*feature-ideas-round-*.md`, `completed-tasks.md`, `archive/*completed-tasks.md`
   - For each candidate: tokenize the bolded name (4+ char words, stopwords removed, lowercased)
   - For each prior file: count keyword hits; compute % of candidate keywords present
   - Threshold: `DUPLICATE_OVERLAP_THRESHOLD` env var (default 50%)
   - Writes `duplicates-round-$round.md` report with each flagged candidate's prior matches

2. **Wire-in** in `scripts/self-improvement.sh`:
   - Insert call after the ideas count is recorded (after `update_round_log '.ideas'`)
   - Update round log with a `.duplicates` field summarising counts
   - Print one-line status to stdout

## Tradeoffs considered

- **Pure-bash keyword overlap vs Claude semantic match:** Pure bash is deterministic, fast, free, and the report is informational (human reviews); semantic matching adds cost and latency for marginal gain at this stage.
- **Name-only vs full-entry tokenization:** Names are short and topical; descriptions are noisy. Using just names yields cleaner matches.
- **Auto-prune vs report-only:** Task says "the round can review before pruning" → report only. Don't auto-modify the candidate list.

## Non-goals

- No new test files (file scope constraint forbids `test/*.bats`).
- No semantic similarity (purely keyword overlap).
- No automatic pruning or reordering of candidates.

## Verification

- Manual smoke test: source `si-functions.sh`, invoke on the existing `~/claude-workflows/docs/working/feature-ideas-round-1.md` with prior archive files, inspect generated report.
- Shellcheck the modified files.
