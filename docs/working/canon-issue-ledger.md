# Canon issue ledger: every known defect in the canon set, with per-review provenance

**Date**: 2026-08-14 · **Companion to**: `review-canon.md` §1 (instances/labels) ·
Living, append-only, like the canon itself — a re-adjudication updates a row's status
column, never deletes the row.

One row per **distinct underlying issue**. "Found by" columns:

- **Pipeline** — the full agentic `code-review` harness. ✓(label) = the historical
  review that produced the canon label (24/24 on stratum A by construction);
  ✓(E1) = found by the 2026-08-06 fresh full-pipeline re-runs, not by the historical
  panel; ✗ = the pipeline missed it at the state where it was findable.
- **E2** — sonnet-5 k=1 headless, Stage-1 context (`e2-results-2026-08-06.md`).
- **E4** — opus-5 k=3 headless union, Stage-1 context (`e4-results-2026-08-14.md`).
  Votes given as k/3. "raw" = present in replicate raw output but dropped by the
  engine's multi-path parser (harness bug, E4 doc §5).
- n/a = the issue lives outside that arm's reviewed range (e.g. introduced by a fix
  commit the arm never saw).

## Count reconciliation

| Stratum | Rows |
|---|---|
| A. Original review labels, 7 dirty instances (the E2/E4 "canon-24" frame) | 24 |
| B. mfc-postfix labels (pipeline ground-truth run 2026-08-06; the canon's 8th row) | 9 |
| C. Appended labels/candidates (found by headless arms, absent from the original rubrics) | 4 |
| D. Live-at-HEAD defects surfaced by the E1 fresh re-runs on post-fix states | 6 |
| **Total distinct issues** | **43** |

Cross-cutting tallies (overlapping the strata): **later-fix-confirmed: 7** (A-csp-R1,
A-corpus-A1..A4, C1 dev-eval, C4 matcher-prefix); **apparently live at HEAD: 7**
(D1–D6 + C3; last verified 2026-08-13/14). If mfc-postfix is excluded (it was never in
the E2/E4 24-label frame), the total is 34.

## Stratum A — original review labels (7 dirty instances, 24 issues)

| ID | Issue (1-line) | Pipeline | E2 | E4 | Status / fix |
|---|---|---|---|---|---|
| csp-R1 | `connect-src 'self'` blocks the `data:`/blob fetch in `exportGraph.ts` — PNG export breaks (gold stratum: 3 archived cells filed it Confirmed Good) | ✓(label; fresh-rerun recovery is config-dependent — oc 3/3, k=3-lean-brief 0/3, rich-brief 3/3) | ✗ | ✗ (cross-file) | fix-confirmed `4f018ab` (toBlob) |
| csp-R2 | `proxy.ts:35-36` comment claims Edge runtime; middleware defaults to Node.js | ✓(label) | ✗ | ✗ (in-diff miss; rep1 ranged past the line) | fixed in review chain |
| csp-A1 | CSP set on response only, never on forwarded request headers — Next.js can't extract the nonce (dead `x-nonce` plumbing) | ✓(label) | ✓ | ✓ 3/3 | fixed in review chain |
| csp-A2 | `style-src 'unsafe-inline'` misattributed to Tailwind v4 | ✓(label) | ✗ | ✗ | fixed in review chain |
| csp-A3 | `layout.tsx:27-30` comment misstates why `await headers()` is needed | ✓(label) | ✗ | ✓ 3/3 (rep2 states the correct mechanism) | fixed in review chain |
| csp-A4 | No tests pin the CSP directive list | ✓(label) | ✗ | ✗ (test-strategy class) | — |
| lean-R1 | README/ARCHITECTURE docs stale (removed mock-pass fallback / localhost default still documented) | ✓(label) | ✗ | ✗ (cross-file: docs outside diff) | — |
| lean-R2 | Non-2xx verifier response masked as "unavailable", upstream body discarded | ✓(label) | ✓ | ✓ 3/3 | fix pending post-c95c9cb |
| lean-A1 | `verifyLean()` client drops the route's typed `reason`/`detail` fields | ✓(label) | ✓ | ✓ 3/3 | — |
| hyg-R1 | SSE protocol JSDoc documents `{error, details}`; emit site sends `{error}` only | ✓(label) | ✓ | ✓ 3/3 | — |
| hyg-A1 | Invalid-JSON logging asymmetry: shared `artifactRoute.ts:107` still logs 500-char preview after edit/artifact tightened | ✓(label) | ✗ | ✗ (cross-file) | — |
| sec-R1 | `react/no-danger: "warn"` contradicts the fail-loudly comment (warn exits 0) | ✓(label) | ✓ | ✓ 3/3 | — |
| sec-A1 | `trust` AST-selector gaps: string-quoted key / shorthand / computed keys bypass the guardrail | ✓(label) | partial (found sibling class only) | ✓ 3/3 as-worded | — |
| dep-R1 | CLAUDE.md:77 claims Vercel writes go to `/tmp`/warm container — refuted by `persist.ts`/`cache.ts` writing `cwd()/data` (EROFS, swallowed) | ✓(label) | ✗ | near-hit (mechanism named; CLAUDE.md treated as authority, not flagged) | — |
| dep-R2 | README:120 "does not persist across invocations" — right conclusion, wrong mechanism (writes silently *fail*, not merely not-persist) | ✓(label) | ✗ | ✓ 3/3 | fixed in review chain |
| fsc-R1 | `persist.ts:6-7` references a "Deploy to Vercel" README section that doesn't exist | ✓(label) | ✗ | ✓ 1/3 (union-only; consensus would drop it) | — |
| fsc-A1 | Docstring omits that `/tmp` is per-Function-instance — concurrent analytics divergence | ✓(label) | ✗ | ✓ 2/3 | — |
| fsc-A2 | Inconsistent rest-args vs join-at-callsite convention | ✓(label) | ✗ | ✗ (convention survey class) | — |
| fsc-A3 | Cache hit-rate collapse on Vercel — cost impact | ✓(label) | ✗ | ✗ (deployment-model reasoning) | — |
| fsc-A4 | `dataDir()` deploy invariant untested | ✓(label) | ✗ | ✗ (test-strategy class) | — |
| cor-A1 | `customTypeIds`→`customArtifactTypeIds` naming inconsistency | ✓(label) | ✗ | ✗ (enumeration class) | fix-confirmed (follow-up commit) |
| cor-A2 | storeAdapter `state/` blob path bypasses the `paths.ts` choke point | ✓(label) | ✗ | ✗ (enumeration class) | fix-confirmed (follow-up commit) |
| cor-A3 | Stale comments (layout.ts ref in storeAdapter header; workspaceStore:44-46 ref) | ✓(label) | ✗ | raw only (2/3 reps; parse-dropped) | fix-confirmed (follow-up commit) |
| cor-A4 | Manifest codec docstring drift: silent createdAt/updatedAt defaults vs "never silent default"; phantom `browser-storage-cleared` | ✓(label) | ✓ | ✓ 3/3 | fix-confirmed (follow-up commit) |

## Stratum B — mfc-postfix labels (9c9edf5..7f30210 ground-truth run, 9 issues)

Pipeline ✓ by construction for all nine (this rubric *is* the pipeline's 2026-08-06
output). E2 = the base arm pre-scored in the 2026-08-06 comparison (1 hit + 1 FP —
the referenced-but-not-touched-constant class). E4 run 2026-08-14 post-sweep
($0.48; adjudicated same-session): union 4/9, and one confirmed FP of its own — a
hedged, single-vote test-vacuity speculation refuted by the CollapsibleSection
source (children always rendered). Both headless FPs on the whole canon are on this
instance; the E4 one dies at the k≥2 consensus gate (which would also drop the
1-vote A2/A8 hits).

| ID | Issue (1-line) | E2 | E4 |
|---|---|---|---|
| pf-R1 | `mergeStreamingPreview<T>` types partial-JSON parses as complete `T`; `between` contract disagrees 3 ways; next partial-field crash latent in 3 panels | ✗ | ✗ (structural: caught the pf-A6 symptom, never the type-seam root) |
| pf-A1 | `allowUnsafeEval` defaults fail-open: `NODE_ENV !== "production"` grants `'unsafe-eval'` to test/staging/custom envs | ✓ | ✓ 3/3 |
| pf-A2 | Default `buildCsp` call path untested (tests pin both explicit arms; production runs the default) | ✗ | ✓ 1/3 (union-only) |
| pf-A3 | Eval policy caller-selectable: exported `allowUnsafeEval` param means "dev-only" is enforced by there being one call site | ✗ | ✗ (in-diff miss) |
| pf-A4 | `process.env.NODE_ENV` read in a default parameter — ambient state in a previously pure formatter | ✗ | ✗ (in-diff miss; cited in A1/A2 findings but never as the coupling defect) |
| pf-A5 | `data.results` used without truncation; misbehaving OpenAlex `per_page` turns `Math.max(...allWorks)` into a RangeError cliff | ✗ | ✗ (cross-file) |
| pf-A6 | Guard tests array presence not element presence: one-element `between` renders a dangling `A ↔` row | ✗ | ✓ 2/3 |
| pf-A7 | connect-src docstring enumeration omits the DD-009 corpus git worker (silently drifts when S4/S5 ships) | ✗ | ✗ (enumeration class) |
| pf-A8 | Comment-accuracy residue: dropped parity claim survives at `evidenceStore.ts:17`; "optional chaining" mischaracterization | ✗ | partial 1/3 (evidenceStore residue confirmed at HEAD; misses the optional-chaining half) |

## Stratum C — appended labels/candidates found by headless arms (4 issues)

| ID | Issue (1-line) | Pipeline | E2 | E4 | Status |
|---|---|---|---|---|---|
| C1 | csp: no dev-mode `'unsafe-eval'` relaxation — dev breaks under the new CSP | ✗ (at d90d6bb; the pipeline later reviewed the *fix* in the postfix range) | ✓ | ✓ 3/3 | **fix-confirmed `2e23824`** |
| C2 | secdeps: `no-restricted-imports` misses `require()`/dynamic `import()` (sibling of sec-A1) | ✗ | ✓ (near-miss, appended) | ✓ 3/3 | candidate label |
| C3 | corpus: `process.env?.NEXT_PUBLIC_CORPUS_FS` optional chaining likely breaks Next build-time inlining (`flag.ts`) | ✗ (survived review-fix `4de2b00`) | ✓ | ✓ 1/3 (independent second sighting) | **live at HEAD**; pending one `next build` runtime adjudication |
| C4 | csp: middleware matcher lookahead is prefix-based, not segment-based (`api-foo`, `favicon.ico.png` slip through) — contradicts a rubric Confirmed-Good row | ✗ | ✗ | ✓ 2/3 | **fix-confirmed `ab4dbdb`** |

## Stratum D — live-at-HEAD defects from the E1 fresh re-runs (6 issues)

Found by full-pipeline re-runs on *post-fix* states (`e1-results-2026-08-06.md`) — i.e.
by the pipeline's fresh eyes, not by the historical panels, and mostly missed by the
loops that shipped the fixes. All six verified still live at project HEAD 2026-08-13.
E2/E4 columns: n/a where the defect was introduced by a fix commit outside the arm's
reviewed dirty range.

| ID | Issue (1-line) | Pipeline | E2 | E4 | Notes |
|---|---|---|---|---|---|
| D1 | csp fix's test guard regex is vacuous — `/\bhttp:\b/` can never match (proved by execution, 3/3 replicates) | ✓(E1: csp-clean R1) | n/a | n/a | fix-introduced defect |
| D2 | corpus fix's production hard-refuse fails open: `typeof process !== "undefined"` gating is asymmetric vs the ungated localStorage enable path | ✓(E1: corpus-clean R2) | n/a | n/a | fix-introduced defect |
| D3 | Rehydration seam bypass: legacy `migrateFromV2()` re-fires over corpus state on every load, ungated by `isCorpusEnabled` (existed in the dirty state too) | ✓(E1: corpus-clean R1; the dirty pass missed it) | ✗ | ✓ raw only (2/3 reps; parse-dropped) — independent rediscovery, initially misfiled as "new" in the E4 doc | not in any rubric label set |
| D4 | False "fresh ArrayBuffer view" comment above a plain `w.write(bytes)` (both corpus states) | ✓(E1: 3/3, both states) | ✗ | ✓ 1/3 | comment-accuracy class |
| D5 | OPFS write race — un-serialized/un-debounced write seam (not on the author's carry list) | ✓(E1) | ✗ | probable — "drops debouncing and write serialization" (3/3) targets the same seam; same-issue match unadjudicated | rubric green C4 acknowledges the seam, defers to S2/S3/S5 |
| D6 | fscompat cacheKey stored inside the cache file + double-hashing (both states) | ✓(E1) | ✗ | ✗ | — |

## Stratum E — candidate rows from E5/E6/E7 (2026-08-14/15; see e5-e6-results + e7-rep1-results docs)

Candidate issues surfaced by the Claude-Code arms, all adjudicated true by scoring
agents; N1 is fix-confirmed and a full row, the rest pend fix/HEAD adjudication.
Per-issue found-by columns live in the CSV (which is the per-issue source of truth for
E5/E6/E7 across all strata — the tables above predate those arms):

- **N1** csp: middleware prefetch-skip serves real HTML with no CSP (E5; **fix-confirmed
  `ab4dbdb`**)
- N2 secdeps: the new npm-audit CI gate fails on this very branch — commit message's
  "lands green" claim is false (E5, verified by execution)
- N3 lean: localhost-default removal breaks the documented local-dev flow (E5)
- N4 lean: decomposition path maps `unavailable`→"unverified", silent in node mode (E5)
- N5 lean: formalizeNode treats `unavailable` as failed and skips dependents (E5)
- N6 deploy: "+ Factor" streaming race persists a partial causal-graph snapshot (E5;
  pre-existing at the base commit — out-of-diff-scope candidate)
- N7 csp: no `worker-src` under `'strict-dynamic'` — pdf.js worker blocked/degraded (E6,
  verifier-kept; never fixed at HEAD)
- **N8** lean: workspaceStore partialize persists transient `unavailable` across reloads —
  live persist path bypasses the branch's own sanitizer (E7r1)
- **N9** secdeps: unscoped eslint rules block crashes lint on the first `.cjs` file
  (plugin-react not found; E7r1, reproduced by execution)
- **N10** deploy: CLAUDE.md claims unset `LEAN_VERIFIER_URL` → mock; unset actually
  defaults to `localhost:3100` real verification (E7r1)
- **N11** corpus: flag enforceable in production — no `NODE_ENV` gate despite DEV-ONLY
  docstring; dirty-state ancestor of D2 (E7r1)
- **N12** corpus: storeAdapter awaited `fs.writeFile` uncaught — write errors become
  unhandled rejections (E7r1)
- **N13** corpus: non-NotFound read error renders pristine defaults, next write clobbers
  the intact OPFS file (E7r1)

E7r1 also re-found N1, N2 (by execution), N3, N4, N5, and N7 — independent second
sightings for six of the seven E5/E6 candidates (N6 not re-found).

As candidates graduate, denominators grow — published recall figures are dated to the
ledger revision they were computed against (E2/E4/E5/E6/E7 figures above: the 43-row
ledger of 2026-08-14).

## Adjacent true findings deliberately NOT counted as issues

Kept out of the 43 to avoid inflating the ledger: rubric-green/Consider-tier items the
arms independently rediscovered (hygiene C1/C4/C6, csp C3 dynamic-render tradeoff,
fscompat C3 /tmp-no-eviction + C6 containment, deploy C3 env-var docs, secdeps C1/C2
audit nits, corpus quota-error masking + slug collision + DOMException forward-compat +
fake/OPFS empty-dir divergence, deploy public-reachability advisory), and
true-but-by-design items (lean retry error-wipe, csp prefetch behavior, corpus
analytics path placement). Each is recorded with its adjudication in the E2/E4 results
docs; promote to Stratum C/D only if a later fix or HEAD adjudication elevates it.

## Process recall against the living ledger (the headline table)

**Framing rule (author call, 2026-08-14): the purpose of this program is real-world
value — every valid issue caught before production — not benchmark performance against
frozen rubrics.** Rubrics are themselves pipeline output, so scoring only against them
is circular in the incumbent's favor; an arm finding a bug the pipeline missed is the
*ideal* finding, and it counts against the pipeline's recall here. Denominator per
process = ledger issues **findable** in the input that process actually reviewed
(an issue introduced by a fix commit a process never saw is excluded for it, not
counted as a miss).

| Process | Findable | Found | Recall | Missed |
|---|---|---|---|---|
| Full pipeline **as operated** (historical loops + postfix ground-truth run; ~$14.60/instance ≈ **$116.80 per 8-instance sweep** — the sweep-total comparable to the arms' sweep costs) | 43 | 33 | **77%** | C1–C4 (headless-only finds; C4 filed Confirmed Good) + D1–D6 (own-fix defects and dirty-state issues the loops never surfaced — "the historical loops never re-reviewed their own fixes with fresh eyes", E1) |
| Full pipeline **incl. E1 fresh re-runs** (same process, re-run as an experiment) | 43 | 39 | **91%** | C1–C4 — still invisible to every pipeline pass at any vintage |
| E4 opus-k3 union (~$0.69/instance) | 41 (D1/D2 outside its ranges) | 20 firm + D3 (raw-only, parse-dropped) + D5 (probable-same, unadjudicated) | **49–54%** | the cross-file-verification / enumeration / test-strategy / structural classes |
| E5 built-in /code-review, agentic dockerized (~$0.88/instance, exact per-run cost) | 41 | 18 firm + 1 partial | **~46%** | enumeration/convention, test-strategy, structural (pf-R1), D6 — but uniquely lands lean-R1, hyg-A1, and firm D3/D5 |
| E6 ultrareview (one cleanly scored cell — all 3 sessions exited nonzero; deploy's empty result is abstention-vs-failure-unresolved; secdeps crashed; $0 billed, free tier consumed) | 8 (csp) | 3 | **3/8 on csp** | uniquely lands csp-R1 — the only non-pipeline catch of the gold cross-file defect |
| E7 fable rep1 (subscription-billed; ~$8.90/scored instance **list-price estimate**, $77.54 attempted-sweep incl. hygiene's $15.24 budget-cap death; 7/8 cells scored) | 39 (hygiene's 2 rows excluded — budget-cap failure; D1/D2 outside ranges) | 17 firm + 3 partial | **~44% firm, ~51% incl. partials** | perfect deploy (2/2 incl. **dep-R1, first non-pipeline full hit**) and secdeps (3/3); best-ever csp cell (5/8+1p incl. csp-R1); 0 FPs across all 7 cells; caveat: summary-only evidence base — fscompat 0/6 and cor-A3/D4 are partly output-truncation artifacts (full reports unsaved) |
| E2 sonnet k=1 (~$0.12/instance) | 41 | 10 | **24%** | everything outside the in-diff doc-vs-code stratum |

Notes on the judgment calls embedded above: pipeline-as-operated is charged with D1–D6
because reviewing its own fix commits was in the loops' scope (and when the process
*was* pointed at fix commits — the postfix instance, the E1 re-runs — it found this
class); C1–C4 are charged to every pipeline variant because all four existed at states
it reviewed, one under an explicit Confirmed-Good verdict. Precision is not symmetric
across rows: the arms' FP counts are measured (2 confirmed across both, both on
mfc-postfix), while the pipeline's historical precision is unmeasurable retrospectively
(acceptance-filtered corpora, §5.4 trap 2). The union of all processes is 43/43 by
construction — the ledger *is* the union — which is itself the finding: no single
process, at any price point, currently exceeds ~91% of known issues, and the cheap and
expensive processes miss disjoint classes.

Frozen-label recall (15/33 for E4, 7/33 for E2) remains in the E2/E4 results docs as a
secondary comparability number for prior arms — it is not the headline metric.

## Reading the found-by pattern (what the ledger shows at a glance)

- **Headless-blind classes are consistent**: cross-file verification (csp-R1, lean-R1,
  hyg-A1, dep-R1's last step, D6), repo-wide enumeration/convention (cor-A1/A2, fsc-A2),
  test-strategy (csp-A4, fsc-A4), and structural/type-seam reasoning (pf-R1) are found
  only by the full pipeline. That is the ~$14 tier's moat, unchanged by model tier or k.
- **Pipeline-blind spots are real and recurrent**: 4 of the 43 (C1–C4) were found only
  by ≤$1 headless arms, two of them later fix-confirmed, and two contradicting rubric
  Confirmed-Good rows. Fresh-eyes re-runs (D1–D6) add six more the shipping loops
  missed. No single process dominates.
- **E4 ⊇ E2 on this corpus**: every E2 hit is also an E4 hit (secdeps sec-A1 upgraded
  from sibling-class to as-worded; postfix pf-A1 reproduced 3/3), plus 7 additional
  stratum-A labels, 3 more postfix labels, C4, and the D3/D4 rediscoveries. E2's
  remaining unique value is price ($0.81 vs $5.51/sweep incl. postfix). Headless FP
  count across the whole canon: 2 (one per arm, both on mfc-postfix, different
  classes; E4's is single-vote and consensus-killable).
