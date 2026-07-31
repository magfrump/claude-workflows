# Experiment: does MD1 R1 recovery replicate at opus under the current (k=3) review config?

Date run: 2026-07-30 → 2026-07-31 (cells executed overnight into the 31st; rubrics are dated 2026-07-31).
Answers open question #1 of `docs/thoughts/code-review-evaluation-state.md` §3, caveat on H4 in §5.3.

## Verdict (one line)

**Failed-config (with a twist): current-config recovery is 1/3 while original-config recovery is 3/3
(original r1 + 2 fresh replicates), so Result 11's recovery was not n=1 variance — the original
config finds R1 reliably, and the k=3-era config *lost* the fact-check recovery path while its new
Confirmed-Good/soundness cross-checks partially compensated (the one current-config recovery came
through architecture-review + the cross-check, at 🟡 instead of 🔴, without the `toBlob` fix).**

## Ground truth (GT-R1)

`connect-src 'self'` (added in `proxy.ts` within d86d2dc..d90d6bb) blocks the `fetch(dataUrl)` of
`data:image/png` URIs at `app/lib/utils/exportGraph.ts:24,37` — a module not in the diff — breaking
graph PNG/zip export. Human fix: `html-to-image`'s `toBlob()`. Independently re-verified this run:
`git grep -n 'fetch(' d90d6bb -- app` lists both call sites; `git show d90d6bb:app/lib/utils/exportGraph.ts`
confirms `fetch(dataUrl)` on the `toPng()` output.
Scoring per state doc §5.2: **detection at any tier**, not tier.

## Setup

- Reviewed commit: `d90d6bb` (verified equal to the original `md1-opus-r1/repo` checkout by file
  comparison — that repo is a now-orphaned worktree, so new cells are fresh clones of
  `/workspace/external/meta-formalism-copilot`, `checkout --detach d90d6bb`, `git clean -fdx`).
- Hygiene (state doc §5.4 traps): every cell verified `git status` clean before launch; **no
  `docs/reviews/` directory exists at all at `d90d6bb`** (the old run's rubrics were untracked run
  artifacts), so temporal leakage from prior rubrics is structurally impossible in these cells.
  Rubrics were selected/scored by content (`Commit: d90d6bb` + fresh review date), not filename.
- Prompt: original `md1-opus-r1/prompt.txt` verbatim with only the skills path changed
  (verified by diff: substituting the path back reproduces the original byte-for-byte).
  Original-config (oc) cells reuse the original prompt verbatim, unmodified.
- Invocation: `claude -p "$(cat ../prompt.txt)" --model opus --permission-mode acceptEdits --add-dir <skills root>`
  from inside each cell's `repo/`, sequentially.
- Config provenance:
  - **cc** (current config): `/workspace/.claude/worktrees/cross-model-review-sweep/skills/` —
    k=3 replicated fact-check with most-severe-wins merge, Confirmed-Good cross-check,
    soundness-contradiction channel, single-sample label.
  - **oc** (original config): `/home/node/.claude/skills/` — verified still pre-k=3 (zero matches
    for `k=3` / `Confirmed-Good cross-check` in `code-review/SKILL.md`).
  - `diff -ru` of the two trees: the **only** differing files are `code-review/SKILL.md` (the k=3 /
    cross-check machinery) and `arithmetic-eval/SKILL.md` (irrelevant). All critic sub-skills,
    including security-reviewer and architecture-review, are byte-identical across configs.

## Per-cell results

| Cell | Config | rc | Elapsed | GT-R1 outcome | Surfacing critic | Rubric tier | Call sites 24+37 | `toBlob` fix |
|---|---|---|---|---|---|---|---|---|
| md1-opus-r1 (prior art) | oc | 0 | 1269s | **Recovered** | fact-check + security + api-consistency + architecture (convergent) | 🔴 (their R2) | both | yes |
| md1-opus-cc-r2 | cc | 0 | 1414s | **Affirmatively cleared** | — (✅ Confirmed Good row certifies `connect-src 'self'` "breaks no current client fetch") | ✅ | no | no |
| md1-opus-cc-r3 | cc | 0 | 1200s | **Affirmatively cleared** (contested basis; see below) | — (security: "correctly scoped… holds"; cross-check demoted the ✅ row to 🟡 `Contested` for defective enumeration but still called the conclusion "probably right") | ✅→🟡 basis-contested | no | no |
| md1-opus-cc-r4 | cc | 0 | 1218s | **Recovered** | architecture-review, promoted by Confirmed-Good + soundness cross-checks | 🟡 (A1, `Contested`/`Contested-Soundness`) | both | no (recommends auditing/widening, not `toBlob`) |
| md1-opus-oc-r2 | oc | 0 | 1134s | **Recovered** | api-consistency + security + fact-check (convergent) | 🔴 (their R2) | both | yes |
| md1-opus-oc-r3 | oc | 0 | 983s | **Recovered** | fact-check + security + api-consistency + architecture + test-strategy (convergent) | 🔴 (their R2) | both | yes (plus C4: test asserting `fetch` never called) |

Sanity checks: every completed cell rc=0, stderr empty, stdout ~30KB, fresh rubric in
`repo/docs/reviews/code-review-rubric.md` naming `d86d2dc..d90d6bb` / `Commit: d90d6bb` with a
2026-07-31 review date.

### Token usage (summed `message.usage` over the cell's transcript jsonl)

| Cell | input | output | cache_creation | cache_read |
|---|---|---|---|---|
| md1-opus-r1 | 89 | 137,879 | 269,374 | 4,214,748 |
| md1-opus-cc-r2 | 86,542 | 203,572 | 567,624 | 5,085,133 |
| md1-opus-cc-r3 | 73 | 184,665 | 370,877 | 3,500,016 |
| md1-opus-cc-r4 | 60 | 181,114 | 374,046 | 2,775,191 |
| md1-opus-oc-r2 | 85 | 128,056 | 293,748 | 3,443,948 |
| md1-opus-oc-r3 | 51 | 110,507 | 257,975 | 1,808,479 |

## Decision-rule outcome

Phase 1 (cc): 1/3 recovered → ≤1/3 → Phase 3 diagnosis triggered.
Phase 3 (oc): 2 additional original-config cells.

## Diagnosis

### The fact-check channel collapsed under the current config

- Under **oc**, the (single) fact-check agent found GT-R1 itself in **3/3 runs** (r1, oc-r2,
  oc-r3), rating the `connect-src`-sufficiency commit claim **Incorrect**, which fed the
  escalation mapping → 🔴, with critics converging on top.
- Under **cc**, **0/9 fact-check replicates** (3 runs × k=3) surfaced `exportGraph.ts` at all.
  The replicates that did enumerate client fetches did it with scheme-shaped patterns
  (`rg 'fetch\("http'`, `https?://`) or spot-listing — structurally blind to `fetch(dataUrl)`
  where `dataUrl` is a `data:` URI. The merged report then certified claim 6 as
  "Mostly accurate — conclusion holds" ("all client `fetch(` under `app/` target relative
  `/api/…` paths" — false), and downstream critics, whose skills instruct them not to re-verify
  fact-checked behavior, inherited the clearance. (3/3 oc fact-check samples hit vs 0/9 cc
  replicates; Fisher exact one-sided p ≈ 0.0045 — not per-sample variance.)

### Why the replicate prompts were weaker (suspect mechanism)

Read directly from the transcripts (`Agent` tool dispatches):

- oc orchestrators wrote **rich fact-check briefs (4.5–5.1KB)** containing a
  "Claims that particularly need checking" list, including, verbatim in both oc runs:
  *"`connect-src 'self'` is sufficient because … — verify against actual client-side
  fetch/network code in the app."* That directive aims the agent straight at the enumeration
  that finds `exportGraph.ts`.
- cc orchestrators wrote **lean, generic replicate prompts (2.3–3.0KB, byte-identical across
  replicates, no claims list)** in all three cc runs. The k=3 spec's uniformity clause ("the
  per-replicate output path is the **only** permitted difference between the three prompts —
  anything else varying would confound the disagreement measurement") is the plausible nudge:
  it frames the prompt as a controlled instrument rather than a tailored brief, and every cc
  orchestrator independently converged on minimal scope text. The skill's "paste the full skill
  contents" instruction was also not followed by either config's orchestrator (both pointed the
  sub-agent at the skill file/tool instead), so the 20.5KB skill text itself was equal across
  arms — the differentiator was the orchestrator-authored brief.
- Net: the k=3 change replicated a **weaker** fact-check 3× instead of running a strong one 1×.
  Most-severe-wins can only merge what some replicate found; it cannot recover recall lost to a
  uniformly under-specified prompt.

### What the new machinery did buy (the twist)

The current config's Confirmed-Good cross-check is doing real work on exactly this row:

- cc-r3: revoked the "`connect-src 'self'` is sufficient" ✅ candidate as having a defective
  enumeration basis (names a nonexistent OpenAlex, omitted the Lean verifier) and published it
  as 🟡 `Contested` — wrong conclusion retained, but the certification was correctly refused.
- cc-r4: architecture-review independently traced CSP consumers (its "derive directives from
  consumers, not memory" framing), found both call sites, and the Confirmed-Good + soundness
  cross-checks revoked the ✅ candidate and published A1 at 🟡. This is the single cc recovery —
  note it came through the one critic whose skill text is *identical* across configs, via the
  cross-check channel the new config added, not through the fact-check channel the old config won
  with. Severity is understated relative to oc (🟡 `Contested` vs 🔴 with 3–4-critic convergence
  and the exact human fix).
- cc-r2 shows the cross-check's failure mode: it demanded an enumeration, got one
  (`rg -n "https?://" app/components app/hooks` — wrong scope *and* wrong shape for a `data:`
  fetch), and certified the false claim with more convincing-looking evidence than a bare
  assertion would have carried.

### Caveat: hint leakage runs the wrong way

The current config's `code-review/SKILL.md` "Confirmed Good is a claim, not an output" section
quotes this very defect class as its worked example ("`connect-src 'self'` is sufficient",
"`data:` URLs fetched client-side" as the recorded-in-passing contradiction). The cc arm was
therefore *tilted toward* recovery by in-prompt hints — and still went 1/3. The measured cc rate
is, if anything, an overestimate of the config's blind performance on this defect shape.

## Interpretation against the brief's Phase-3 rule

Original-config recovers 2/2 fresh replicates (3/3 including the original run) while current
config recovers 1/3 → **config regression**. Named suspect: the k=3 replicate-dispatch spec in
`skills/code-review/SKILL.md` Stage 1 — specifically the byte-identical/minimal-prompt framing
that displaced the rich per-claim fact-check brief the pre-k=3 orchestrators wrote. Changes
affecting only verdict merging/tiering (most-severe-wins, agreement reporting) are not implicated
in the miss; the Confirmed-Good/soundness cross-checks are partially *compensating* for it.

Result 11's statement "the ceiling is a property of the config, not the model" survives — but
inverted onto the new config: MD1 R1 recovery was a property of the *original* pipeline's
fact-check briefing, which the k=3 rewrite quietly removed. H4's falsification stands (the
original config beats the single-pass ceiling reliably, now n=3), but the current config does not
inherit that property.

### Candidate fix (not implemented; for the decision log discussion)

Allow — or require — the Stage-1 dispatch to include a shared "claims to check" brief derived
from the diff's comments/commit messages, identical across replicates (uniformity is preserved;
the clause only needs to forbid *between-replicate* variation, not richness). Alternatively,
have the orchestrator enumerate checkable claims itself and paste the same list into all three
replicate prompts.

## Incidental observations (not the target)

- GT-R2 (Edge-runtime comment wrong; actual default is Node): detected at 🟡 by cc-r2 (A10) and
  cc-r3 (A11) as "runtime attribution unverified/unpinned"; oc cells likewise carry it. No cell
  affirmatively cleared it.
- All five fresh cells (both configs) converge on a 🔴 nonce-propagation finding (CSP set only on
  the response so Next never sees the nonce on the request) — the mechanism behind ground-truth
  A1, here escalated to blocking with runtime-breakage reasoning. Cross-config stable.
- cc k=3 verdict-agreement rates ran well below the ≥90% k-reduction threshold (cc-r4 reports
  47%), consistent with §1.1's premise that the fact-check verdict is the least stable judgment.

## Cell inventory

`/home/node/cr-eval/runs/{md1-opus-cc-r2,md1-opus-cc-r3,md1-opus-cc-r4,md1-opus-oc-r2,md1-opus-oc-r3}/`
each with `prompt.txt`, `repo/`, `stdout.txt`, `stderr.txt`, `status.txt`, and the run's review
artifacts under `repo/docs/reviews/`.
