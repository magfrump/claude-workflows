# Canon issue ledger: every known defect in the canon set, with per-review provenance

**Date**: 2026-08-14 · **Last revised**: 2026-08-18 (new arm: **cubic CLI** v1.10.4,
backed by Claude Code via ACP, scored on all 8 instances — 38.9% firm, 1 confirmed FP
(re-asserts refuted N7), 2 confirmed false attestations in mfc-postfix; added
`cubic-cli raised` CSV column; added 4 new candidate rows N23–N26, two of which
(N23, N24) are now corroborated by 2 independent sightings from *different* arms; see
cubic-cli-results-2026-08-18.md) · prior revision: 2026-08-18 (E7 rep3 scored — 7/8
cells, 71% firm; E7r2's corpus/fscompat cells recovered from dead-cell status and
scored — 76.5% firm on 7 cells; reps 1–3 union now 78% firm on the 54-row base; added
E7r3 CSV column, corrected E7r2 columns for corpus/fscompat; added 6 new candidate
rows N17–N22; flagged a cross-rep C3 contradiction — E7r1 hit it, E7r2/E7r3 both
assert an unverifiable "empirically refuted" claim; see
e7-rep3-results-2026-08-18.md) · earlier: 2026-08-18 (added CSV `E8 raised` column,
per-row provenance for all 60 rows; added Cost-per-run and False-positives columns to
the process recall table, incl. N7's retroactive FP charge to E6/E7r1) · earlier:
2026-08-18 (E8 evidence-discipline pipeline scored — 47/54=87%, first process past
~80%, 0 FPs; see e8-results-2026-08-18.md) · earlier: 2026-08-17 (E7 rep2; N14–N16;
N7 refuted; graduation pass 43→56) ·
**Companion to**: `review-canon.md` §1 (instances/labels) ·
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
| E. Graduated candidates (2026-08-17 pass): confirmed via fix-in-history, static analysis / execution, or 2+ attestations without contradiction — N1–N5, N8–N15 | 13 |
| **Total distinct issues** | **56** |

Still candidates, outside the 56: **N6** (single E5 attestation, never re-found, no
independent verification), **N16** (plausible-only evidence, single attestation),
**N17–N22** (2026-08-18, from the E7 rep2/rep3 recovery pass — N18/N19/N20 at 2
independent sightings each, N17/N21/N22 at 1; none yet meet the 3-sighting or
fix-in-history bar), **N23–N26** (2026-08-18, from the cubic CLI sweep — N23/N24 at 2
independent sightings **from different arms** each, the strongest cross-arm
corroboration signal on the ledger so far; N25/N26 at 1). **N7** is refuted (E7r2
spec/WPT evidence) and will not graduate absent new evidence; it also collected its
first confirmed false-positive credit (cubic CLI's csp worker-src claim, 2026-08-18) —
a fresh mistake made *after* the refutation, not a holdover from the older runs that
predate it.

Graduation criteria per row: N1 fix-in-history (`ab4dbdb`) + 3 sightings; N2
execution-reproduced ×3 (E5, E7r1, E7r2); N3/N4/N5 three attestations each,
code-verified, no contradiction; N8 two code-verified attestations; N9
execution-reproduced (E7r1); N10 static analysis (`route.ts` localhost default
confirmed by adjudicators — E7r2's "Accurate" stamp was adjudicated a false
attestation, not counter-evidence); N11–N13 code-verified (E7r1); N14 code-verified
against source (E7r2); N15 verified against react-markdown defaults (E7r2).

Cross-cutting tallies (overlapping the strata): **later-fix-confirmed: 8** (A-csp-R1,
A-corpus-A1..A4, C1 dev-eval, C4 matcher-prefix, N1 prefetch-skip); **apparently live
at HEAD: 7** (D1–D6 + C3; last verified 2026-08-13/14 — the graduated N-rows'
HEAD/fix status is still pending adjudication and may grow this tally). If
mfc-postfix is excluded (it was never in the E2/E4 24-label frame), the total is 47.

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

## Stratum E — candidate rows from E5/E6/E7 (2026-08-14/17; see e5-e6-results + e7-rep1/rep2-results docs)

Issues surfaced by the Claude-Code arms, all adjudicated true by scoring agents.
**As of the 2026-08-17 graduation pass, N1–N5 and N8–N15 are confirmed rows counted
in the 56-row total** (criteria in §Count reconciliation); N6 and N16 remain
candidates; N7 is refuted. Fix/HEAD adjudication still pends for most graduated rows
(graduation confirms the issue is real, not that it is fixed).
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
  verifier-kept; never fixed at HEAD). **Candidate REFUTED by E7r2** with spec + WPT
  evidence (w3c/webappsec-csp#200: `'strict-dynamic'` blesses worker creation; the WPT
  strict-dynamic worker test passes in current Chrome/Firefox/Safari) — pending demotion
  adjudication; if demoted it also retro-corrects E6's and E7r1's credited hits.
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

- **N14** hygiene: `edit/artifact` caches unvalidated LLM text and never evicts — a
  malformed response 502s permanently for that input; the sibling `artifactRoute.ts`
  evicts on parse failure (E7r2, code-verified; pre-existing at f2f149b)
- **N15** csp: `img-src 'self' data: blob:` blocks external images in markdown rendered
  via LatexRenderer — unannounced behavior change (E7r2, verified against
  react-markdown defaults)
- **N16** deploy: docs' "no demo mode" + OpenRouter-"fallback" claims contradicted by
  `callLlm.ts` — branches on key presence, not request failure; the deploy env table
  makes the fallback unreachable; the Anthropic→OpenRouter→mock chain is a de facto
  demo mode (E7r2)
- **N17** hygiene: Anthropic SDK still stringifies and logs/streams the full provider
  error body (including request content) despite the redaction diff's explicit
  guarantee — `streamLlm.ts:160` (E7r3, code-verified against `@anthropic-ai/sdk`'s
  `APIError.makeMessage` source; single sighting)
- **N18** corpus: `opfsAdapter.ts`'s `finally { close() }` masks a `QuotaExceededError`
  as generic `{kind:"io"}`, contradicting the module's own no-swallow docstring
  (2 independent sightings — E7r2 and E7r3, both code-traced)
- **N19** corpus: pre-hydration sync-back writes `DEFAULT_STATE` over the OPFS blob
  before rehydration resolves — permanent data loss if the tab closes before hydration
  completes (2 independent sightings, same root cause different manifestation site —
  E7r2's `storeAdapter.ts` hydration race and E7r3's `page.tsx` mount effect)
- **N20** fscompat: `process.env.VERCEL` truthy check also fires locally after `vercel
  env pull`/`vercel dev` (Vercel CLI sets `VERCEL=1` by default), silently redirecting
  local writes to `/tmp` (2 independent sightings — E7r1's "VERCEL-env local-dev
  misroute," adjudicated TRUE-minor at the time but never matched to a ledger row, and
  E7r3's same claim)
- **N21** secdeps: the npm-audit CI gate doesn't cover the `verifier/` subproject (no
  lockfile, absent from dependabot config, eslint globally ignores it) — the part that
  ships as a Docker image is unaudited (E7r3, code-verified; single sighting)
- **N22** csp: `proxy.ts:16` comment cites a nonexistent "OpenAlex" integration/service
  — phantom reference, same class as fsc-R1 (E7r3, code-verified; single sighting)

E7r1 also re-found N1, N2 (by execution), N3, N4, N5, and N7 — independent second
sightings for six of the seven E5/E6 candidates (N6 not re-found). E7r2 (5 scored
cells) re-found N1, N2 (again by execution), N3, N4, N5, and N8; it did **not** re-find
N6, N9, or N10 — and on N10 it went further astray, stamping the exact CLAUDE.md
claim N10 refutes as "Accurate" (a false attestation, though the Vercel-context
outcome coincidentally matches).

**2026-08-18 rep3 pass** (full details: `e7-rep3-results-2026-08-18.md`): E7r2's
previously-dead `mfc-corpus` and `mfc-fscompat` cells recovered and were scored for the
first time (8/11 and 3/5-live respectively); E7r3 scored 7 of 8 cells (postfix dead all
three reps now). Six new candidates surfaced (N17–N22 above), three of them (N18, N19,
N20) at 2 independent sightings — the strongest candidates for a future graduation pass.
**A cross-rep contradiction surfaced on C3**: E7r1 hit it as real; both E7r2 and E7r3
assert an "empirically verified/refuted" claim about Next's build-time inlining that
the independent scoring agents could not reproduce in-sandbox (no working `next build`)
— flagged as a possible unverifiable-claim pattern, not a confirmed false attestation,
but excluded from the reps 1–3 union hit-count pending an actual build verification.

**2026-08-18 cubic CLI sweep** (full details: `cubic-cli-results-2026-08-18.md`): a new
arm, the `cubic` code-review CLI (v1.10.4) — its own logs confirm it orchestrates
Claude Code as its execution backend via ACP, so this measures a different
harness/prompt design on roughly the same model, not a new model. Four new candidates
surfaced:

- **N23** corpus: `workspaceSlug`/`safeSegment` collision — distinct titles (e.g. "My
  Workspace", "my workspace!", "MY-WORKSPACE") all reduce to the same folder slug, no
  collision detection (2 independent sightings **from different arms** — E7r3
  PLAUSIBLE, cubic CONFIRMED)
- **N24** corpus: `manifest.ts`'s `manifestVersion` field is type-checked but never
  compared against the expected `MANIFEST_VERSION` constant — a future format bump
  would silently misparse old manifests (2 independent sightings **from different
  arms** — E7r2 CONFIRMED, cubic CONFIRMED)
- **N25** deploy: the LLM response cache (`cache.ts`) silently fails to write on
  Vercel via the same read-only-`cwd()` mechanism as dep-R1/dep-R2, but the docs'
  Limitations section never mentions the cache (cubic, code-verified; single sighting)
- **N26** csp: missing `form-action 'self'` CSP directive (cubic, code-verified;
  single sighting)

N23 and N24 are the strongest cross-arm corroboration on the ledger to date — two
independent tools with different harnesses, not two reps of the same tool, converging
on the same mechanism. Precision-wise, cubic recorded **1 confirmed false positive**
(its csp `worker-src` finding re-asserts N7's already-refuted claim — the first FP on
N7 recorded *after* the refutation, not a holdover from older runs) and **2 confirmed
false attestations**, both in `mfc-postfix` — a session-summary claim certifying the
CSP `'unsafe-eval'` dev carve-out as "verified with its pinned test suite" when the
tests don't cover the vulnerable path (mirroring E7r1's pf-A5 trap in the same
historically FP-prone cell), and a blanket "all comments verified consistent" claim
contradicted by a stale duplicate comment. Note: `mfc-postfix` suffered a documented
sandbox/shell failure this run (no working `git diff`), so its 0/9-firm score is a
degraded-run artifact, not a clean signal — the false attestations stand regardless.

**Graduation pass 2026-08-17**: N1–N5 and N8–N15 (13 rows) are confirmed and now
count in the reconciliation total and in every process's denominator (criteria and
per-row evidence in §Count reconciliation). N6 and N16 remain candidates; N7 is
refuted. As further candidates graduate, denominators grow — published recall
figures are dated to the ledger revision they were computed against (the headline
table below: the 56-row ledger of 2026-08-17; pre-graduation 43-row figures live in
this file's git history and the per-arm results docs).

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

Denominators below use the **56-row ledger of 2026-08-17** (43 + the 13 graduated
N-rows; N6/N16 still candidates, N7 refuted — none of the three counted). All 13
graduated rows sit inside the dirty-instance ranges every arm reviewed, so
graduation grows every process's denominator; it grows a process's numerator only
where that process actually raised the row. Pre-graduation figures (43-row base)
remain in the git history of this file and the per-arm results docs.

| Process | Findable | Found | Recall | Cost per run | False positives | Missed |
|---|---|---|---|---|---|---|
| Full pipeline **as operated** (historical loops + postfix ground-truth run) | 56 | 33 | **59%** (was 77% on the 43-row base) | ~$14.60/instance ≈ **$116.80/8-instance sweep** (sweep-total comparable to the arms' sweep costs) | unmeasurable retrospectively (acceptance-filtered historical corpora, §5.4 trap 2) | C1–C4 + D1–D6 (as before) + all 13 graduated N-rows — every one found only by the CC/headless arms, which is the graduation pass's headline: the pipeline's blind spot is now 23 confirmed issues, not 10 |
| Full pipeline **incl. E1 fresh re-runs** (same process, re-run as an experiment) | 56 | 39 | **70%** (was 91%) | same ~\$14.60/instance cost model (E1 confirmed pass cost is findings-independent, ratio ≈1.02 dirty/clean; no separate \$ conversion — `e1-results-2026-08-06.md`) | unmeasurable (same class) | C1–C4 + N1–N5, N8–N15 — still invisible to every pipeline pass at any vintage |
| **E8 evidence-discipline pipeline** (branch `feat/critic-evidence-discipline`; execution-upgraded fact-check + endorsement-claim Stage 2.5 + provenance-ruled synthesis; full 8-instance sweep 2026-08-18; see `e8-results-2026-08-18.md` + `runs/review-arms/e8-evidence-pipeline/e8-scoring.md`) | 54 (D1/D2 out of every cell's range) | 47 | **87%** | ~$19–44/instance ≈ **$150–350/8-instance sweep** (indirect triangulation — per-stage token accounting was not recorded, a measurement-provenance miss; a small multiple of, not a fraction of, the historical pipeline's cost) | **0 confirmed** (0 clean false Confirmed-Goods; 1 over-broad-but-scoped-true Confirmed-Good, csp CG4 — masks csp-R1 without itself being a false attestation) | csp-R1 (masked by a scoped Confirmed-Good — the one place scope-narrowing hid a defect), N15 (img-src markdown images), N9 (.cjs crash mechanism), + non-diagnostic C1/C3/pf-A4/pf-A7. Both historical false-attestation traps (N10, pf-A5) caught by the fact-check refusing to attest; pf-R1 type-seam and C4 matcher (ex-Confirmed-Good) both flipped to red by execution. First single process past ~80% of the living ledger. |
| E4 opus-k3 union | 54 (D1/D2 outside its ranges) | 20 firm + D3 (raw-only, parse-dropped) + D5 (probable-same, unadjudicated) | **37% firm, ~41% incl. raw/probable** | ~$0.69/instance ($5.51/8-instance sweep) | **1 confirmed** (single-vote, hedged CollapsibleSection test-vacuity speculation on mfc-postfix, refuted by source; k≥2 consensus would have dropped it) | the cross-file / enumeration / test-strategy / structural classes, plus all graduated N-rows |
| E5 built-in /code-review, agentic dockerized | 54 | 23 firm (18 + graduated N1–N5) + 1 partial | **~43% firm** | ~$0.88/instance, exact `total_cost_usd` ($0.53–$1.14 range; $7.06/8-instance sweep) | **0 confirmed** | enumeration/convention, test-strategy, structural (pf-R1), D6, and 8 of the 13 graduated rows (N8–N15) — but uniquely lands lean-R1, hyg-A1, firm D3/D5, and originated N1–N6 |
| E6 ultrareview (one cleanly scored cell — all 3 sessions exited nonzero; deploy's empty result is abstention-vs-failure-unresolved; secdeps crashed) | 10 (csp rows incl. graduated N1, N15) | 3 (legacy count; its N7 credit is no longer creditable — refuted) | **3/10 on csp** | $0 billed this sweep (free tier, 3/3 consumed); paid-run list price unverified (~$5–25?/cell) | **1 retroactive** — N7 (pdf.js worker-src) was kept as TRUE-minor and never re-scored down; E7r2's 2026-08-17 spec+WPT refutation makes it a false positive in hindsight. The only non-pipeline arm to have credited N7 as real. | uniquely lands csp-R1 — the only non-pipeline catch of the gold cross-file defect |
| E7 fable rep1 (subscription-billed; 7/8 cells scored) | 51 (hygiene's 3 rows excluded — budget-cap failure; D1/D2 outside ranges) | 28 firm (17 + graduated N1–N5, N8–N13) + 3 partial | **55% firm, ~61% incl. partials** | ~$8.90/scored instance **list-price estimate** ($4.14–$15.24 range; $77.54 attempted-sweep incl. hygiene's wasted $15.24 budget-cap death) | **0 confirmed + 1 retroactive** (rep1 re-found and credited N7, since refuted by rep2 — same false positive as E6) + **1 false attestation**, a distinct failure mode: pf-A5's `Math.max` cap arithmetic certified as checking out when it doesn't (endorsing a false claim, not raising a new false finding) | rep1's discovery yield (N8–N13, all now graduated) is what moves its own number; caveats unchanged: summary-only evidence base, fscompat 0/6 partly truncation-artifact |
| E7 fable rep2 **corrected** (2026-08-18; corpus+fscompat recovered from dead-cell status and scored for the first time; postfix still dead) | **34** (7 scored cells; fsc-A2 excluded, already fixed in this checkout; D1/D2, postfix outside ranges) | 26 firm + 1 partial | **76.5% firm, ~79% incl. partial** | ~$10.92/scored instance ($76.45 list across 7 scored cells, up from $53.83 across 5) | **0 confirmed** (rep2 itself *refuted* N7 by execution/spec evidence rather than crediting it — the correction, not the error) + **1 false attestation** (N10, unchanged from prior scoring) + **1 flagged-unverifiable claim** on C3 ("verified inlined by Turbopack" — scoring agent could not reproduce a working `next build` to confirm) | corpus (8/11) and fscompat (3/5 live) close most of the "unscored cells" caveat from the original 5-cell figure |
| E7 fable rep3 (2026-08-18; 7/8 cells, postfix dead a third time) | 45 (7 scored cells; D1/D2, postfix outside ranges) | 32 firm | **71.1% firm** | ~$9.80/scored instance ($68.61 list across 7 scored cells) | **0 confirmed** (N7 not raised — correctly silent, not repeating rep1's error) + **1 flagged-unverifiable claim** on C3 ("empirically REFUTED" — same unreproducible-build pattern as rep2, and contradicts rep1's own hit on this row) | secdeps perfect 5/5 (N2, N9 independently re-executed by the scoring agent); weakest cell fscompat 3/6 |
| **E7 fable reps 1–3 union** | 54 (D1/D2 outside ranges; C3 excluded from the hit-count pending build verification — see contradiction note above) | 42 firm + 1 partial (pf-R1, postfix — only rep1 ever scored it) | **77.8% firm, ~79.6% incl. partial** | ~$222.60 attempted total, list (rep1 $77.54 + rep2-corrected $76.45 + rep3 $68.61) | **1 net confirmed** (N7 — raised true by rep1, self-corrected/refuted by rep2, correctly silent in rep3) + 1 false attestation (N10, rep2-only) + 1 flagged-unverifiable claim pattern (C3, 2 of 3 reps) | best non-pipeline recall on the 54-row base, now within 8–10 points of E8 (87%) rather than 20; only postfix (1 rep only) and the enumeration/comment classes remain a clear pipeline moat |
| E2 sonnet k=1 | 54 | 10 | **19%** | ~$0.12/instance ($0.81/8-instance sweep) | **0 confirmed** (the one historical FP candidate — mfc-postfix's referenced-but-not-touched constant, pre-scored — did not reproduce on this canon) | everything outside the in-diff doc-vs-code stratum |
| cubic CLI v1.10.4 (new arm, 2026-08-18; orchestrates Claude Code as its execution backend via ACP, own harness/prompts) | 54 | 21 firm + 1 partial (pf-R1) | **38.9% firm, ~40.7% incl. partial** | untrackable subscription/CLI billing (same class as E6); 4.5–10.8 min wall-clock/cell | **1 confirmed** (csp's `worker-src` finding re-asserts N7's already-refuted claim) + **2 confirmed false attestations** (both mfc-postfix — a fail-open CSP default falsely certified "verified with its pinned test suite," and a stale duplicate comment falsely certified consistent; mfc-postfix also suffered a documented sandbox failure this run, degrading its score independent of these) | static-only posture: caught every lint-rule-*design* gap on secdeps but missed both execution-only defects (N2, N9); never touches CLAUDE.md on deploy at all; 4 new candidates (N23–N26), two cross-arm-corroborated |

Notes on the judgment calls embedded above: pipeline-as-operated is charged with D1–D6
because reviewing its own fix commits was in the loops' scope (and when the process
*was* pointed at fix commits — the postfix instance, the E1 re-runs — it found this
class); C1–C4 are charged to every pipeline variant because all four existed at states
it reviewed, one under an explicit Confirmed-Good verdict. Precision is not symmetric
across rows: the arms' FP counts are measured, while the pipeline's historical precision
is unmeasurable retrospectively (acceptance-filtered corpora, §5.4 trap 2). **N7's
2026-08-17 refutation (spec + WPT evidence, E7r2) retroactively converts two prior
"true" credits into false positives** — E6 (which kept it, never rescored) and E7 rep1
(which re-found and credited it) — while E7 rep2 and E8 both get credit for either
refuting it directly or never raising it; this is folded into the False positives column
above rather than the Found/Recall columns, since N7 was never in the 56-row confirmed
denominator to begin with. Confirmed FPs unrelated to N7 remain at 2 across all measured
arms (E4's mfc-postfix speculation, E2's now-unreproduced referenced-constant class) plus
2 false attestations (pf-A5 in E7r1, N10 in E7r2) — a failure mode distinct from a raised
FP (endorsing an existing false claim vs. asserting a new one), tracked separately above.
The union of all processes is 56/56 by construction — the ledger *is* the union — which
is itself the finding: no single process, at any price point, currently exceeds ~87% of
known issues (E8, 2026-08-18), and the cheap and expensive processes miss disjoint
classes. The graduation pass compressed the spread among the *older* processes:
pipeline-incl-E1 (70%) and the E7 union (67%) sit three points apart from opposite
directions — the pipeline holds the enumeration/comment/structural classes, the CC arms
hold the 13 graduated discoveries the pipeline never surfaced — but E8 now leads both by
~17–20 points, closing much of the pipeline-only moat (pf-R1, D3–D6, fsc-A3, cor-A1) while
holding the CC arms' 0-FP precision.

Frozen-label recall (15/33 for E4, 7/33 for E2) remains in the E2/E4 results docs as a
secondary comparability number for prior arms — it is not the headline metric.

## Reading the found-by pattern (what the ledger shows at a glance)

- **The headless-blind classes have eroded, not vanished**: cross-file verification fell
  first (E5/E7r1: dep-R1, csp-R1, lean-R1; E7r2 repeated all three plus hyg-A1), and
  E7r2 took a test-strategy row as-worded (csp-A4). What still holds as pipeline-only:
  repo-wide enumeration/convention (cor-A1/A2, fsc-A2, pf-A7), comment-accuracy sweeps
  (csp-A2 — unfound by any arm at any rep — csp-A3, cor-A3, D4, pf-A8), the pf-R1
  type-seam root, and D6. The ~$14 tier's moat is now those classes, not "headless
  can't cross files".
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
