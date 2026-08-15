# FC model mini-sweep: which model should the Stage-1 fact-check pin to?

**Date**: 2026-08-15 · **Motivation**: the pipeline's Stage-1 fact-check inherits the
session model (whatever the user happens to be running); its **Incorrect** verdicts are
load-bearing — they feed the Stage-1.5 critic gate and are one of the two
verdict-driven blocking channels. No fact-check-*only* model comparison has ever been
run (the 2026-07-29 critic-model measurements were Stage-2 critics; E2/E4 were
whole-arm). Author decision 2026-08-15: pin a fixed model for the fact-check stage;
this sweep picks it. **Sequencing**: results → pin the model in
`~/.claude/skills/code-review/SKILL.md` → pipeline settled → A8 token measurement.

## Design

- **Stage isolated**: one `code-fact-check` agent per run — the production Stage-1
  replicate, k=1 form (decision 031), reproduced faithfully: full skill text +
  scope + the same rich shared brief (step 3b), identical across models.
- **Cells** (densest doc-claim ground truth): **mfc-csp** (`main...review`, HEAD
  `d90d6bb`) and **mfc-deploy** (HEAD `4329d6e`), clones in
  `external/cc-review-eval/`. csp's known-bad claims are in-diff; deploy's dep-R1
  requires cross-file verification — the two cells discriminate on exactly the axis
  where cheap models historically fail.
- **Models × reps**: `sonnet` / `opus` / `fable` (Agent-tool `model` override;
  sonnet is only ever admissible *with* the role-skill prompt per the 2026-07-29
  rule — the pasted skill text IS that prompt, so all three get it identically),
  **k=2 replicates** each — enough for a first verdict-stability read (Result 14a:
  verdict flip on identical input is the documented Stage-1 failure mode).
  Total 12 runs, in-session via Agent tool (subscription; ~100–130k tokens each).
- **Prompt control**: per cell, one shared prompt file (`prompt-<cell>.md`);
  every agent gets the byte-identical instruction "read this file and follow it",
  differing **only** in the report output path — the same only-permitted-difference
  clause as production Stage 1. (Deviation from production's paste-into-prompt
  delivery: agents here read the prompt file themselves; content delivered is
  identical across all 12, so the confound control holds.)
- **Leak guard**: agents are confined to the clone directory and explicitly barred
  from reading `/workspace/docs` or `/workspace/runs` (the ledger holds the
  answers). Briefs point at claim *locations* only, never verdicts.

## Ground truth (scored per report, from the canon ledger 2026-08-15)

Known-bad documentation claims findable in each cell's range:

| Row | Claim (where) | Correct verdict direction |
|---|---|---|
| csp-R2 | `proxy.ts` comments claim the proxy runs in the Edge runtime; Next.js middleware/proxy here defaults to Node.js | Incorrect / Mostly accurate |
| csp-A2 | `style-src 'unsafe-inline'` attributed to "Tailwind v4 emits inline styles" | Incorrect |
| csp-A3 | `layout.tsx:23-27` comment misstates why `await headers()` is needed / claims Next auto-tags bootstrap scripts from the response header (dead `x-nonce` plumbing) | Incorrect / Stale |
| dep-R1 | CLAUDE.md deployment bullet: cache+analytics "write to `/tmp`/warm container" on Vercel — refuted by `persist.ts`/`cache.ts` writing `cwd()/data` | Incorrect |
| dep-R2 | README analytics "does not persist across invocations" — right conclusion, wrong mechanism (writes silently fail) | Mostly accurate |
| N10 | CLAUDE.md/README: unset `LEAN_VERIFIER_URL` → mock — unset actually defaults to `http://localhost:3100` real verification | Incorrect |

## Metrics, in priority order

1. **False-attestation rate** (the killer): a known-bad claim checked and verdicted
   **Verified**. This is the failure that silently skips critics downstream.
2. **Detection recall**: known-bad claims surfaced with a wrong-direction-free verdict
   (Incorrect/Stale/Mostly-accurate all count as caught; partial credit noted).
3. **Verdict stability**: agreement between the two replicates per model-cell.
4. **FP check**: Incorrect verdicts on claims that are actually fine (spot-adjudicated).
5. Cost/tokens per replicate (secondary — Stage 1 is already the cheap block).

## Outputs

- Reports: `runs/review-arms/fc-model-sweep/<cell>/<model>-r<N>.md` (12 files).
- Results/adjudication: `docs/working/fc-model-sweep-results-2026-08-15.md`.
- Decision consumer: the fact-check model pin in `code-review/SKILL.md` (after
  results), then A8.
