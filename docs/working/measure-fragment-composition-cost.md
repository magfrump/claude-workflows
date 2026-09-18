# Measurement: Fragment-Composition Cross-Check — Cost/Benefit

**Date:** 2026-08-21 · **Method:** pure artifact analysis (no model runs, no edits to review artifacts)
**Script:** `scratchpad/fragcomp.py` (session scratchpad) — regex citation harvest (`path.ext:NN[-MM]`), suffix-chain path canonicalization, per-file union clustering with ±15-line slack, tier check against red/amber rubric rows + merged fact-check Incorrect/Stale claims.
**Data:** 3 complete review runs under `/workspace/external/crb-eval/{grafana-PR79265, discourse-graphite-PR4, cal_com-PR11059}/docs/reviews/`. Sources = merged `code-fact-check-report.md` (one source) + each critic report (one source each). Excluded as sources: replicate reports (`-r1/-r2/-r3`), the rubric (it is the output), override-log, hallucination-patterns, execution-logs, `.review-diff.txt`.

## Proposed mechanism (recap)

At Stage-3 synthesis, inline (no new agent): harvest all cited locations from the in-context reports, cluster by file + ±15-line overlap, and for each cluster with **2+ distinct sources AND ≥1 red/amber-tier finding**, answer one forced question — "single root defect no fragment states? one sentence, or 'distinct defects' + reason" — and log a one-row disposition.

## 1. Cluster census per cell

| Cell | Source reports | Citations | Clusters | 2+ sources | **Qualifying** |
|---|---|---|---|---|---|
| grafana-PR79265 | 5 (FC, sec, perf, api, arch) | 305 | 49 | 22 | **10** |
| discourse-graphite-PR4 | 7 (+ test-strategy, ui-visual) | 273 | 61 | 18 | **11** |
| cal_com-PR11059 | 7 (+ tech-debt, test-strategy) | 349 | 49 | 17 | **11** |
| **Total** | — | **927** | **159** | **57** | **32** |

Per-source citation counts (for scale): grafana FC 75 / arch 91 / api 61 / sec 43 / perf 35; discourse FC 80 / ui-visual 43 / perf 47 / api 35 / test 24 / arch 23 / sec 21; cal.com api 78 / test 54 / tech-debt 52 / perf 47 / arch 46 / sec 40 / FC 32.

**Census caveats (mechanical honesty):**
- **Mega-clusters.** ±15-line chaining merges hot files into whole-file clusters: grafana `anonstore/database.go:15-166` (69 citations, 5 sources, 16 tier tags), `impl.go:25-129` (60 citations), cal.com `app-credential.ts:4-92` (56 citations). The forced one-sentence question is under-specified for a cluster carrying 9–16 tiered findings; see verdict for the fix.
- **Path ambiguity.** Bare short paths that suffix-match two real files (grafana's two `config.ts`) cannot be mechanically canonicalized; 2 small clusters were left unmerged (both non-qualifying). A synthesizer with the reports in context resolves these trivially, so census counts are a slight undercount of merges, not of qualifying clusters.

## 2. Token overhead estimate

Overhead = qualifying × ~90 output tokens (answer + disposition row) + ~60 fixed (section header):

| Cell | Qualifying | Output tokens | % of ~1M-token pass |
|---|---|---|---|
| grafana | 10 | ~960 | 0.096% |
| discourse | 11 | ~1,050 | 0.105% |
| cal.com | 11 | ~1,050 | 0.105% |
| **Mean** | **10.7** | **~1,020** | **~0.10%** |

**What is genuinely NEW work:** nothing on the input side. Harvest/cluster operates on reports already in the synthesizer's context — Stage 3 already re-reads every report to build the rubric, and (per the grafana rubric's Unverified-Findings note) already re-reads load-bearing citations. The one place new input could creep in: verifying a *composed* claim against repo source. In the one real composition below, the needed code excerpts (both `time.Now().UTC()` call sites) are already quoted verbatim in the reports' evidence blocks. **Recommendation: constrain compositions to cite only already-quoted evidence; anything needing fresh file reads gets disposition "needs-adjudication" instead of a composed claim.** That pins marginal cost to output tokens only.

## 3. Hit-rate check (benefit)

Ground truth for this sample: exactly 1 real missed bug across the 3 cells is composition-reachable (grafana GR1: FC Claim 6 mechanism — `updateDevice` derives both BETWEEN bounds from `device.UpdatedAt`, not the clock — + rubric R3(ii) dormant-device false denial + architecture's sibling inconsistency, `CountDevices` call site uses `time.Now().UTC()` at `database.go:107` → composed fix: anchor the window at `time.Now().UTC()` like the sibling). cal.com: 0 (its clusters must answer "distinct defects"). discourse: misses were lost at merge/tiering, so any composition is bonus.

Disposition per qualifying cluster (my judgment of what the forced question would plausibly yield):

**grafana-PR79265 (10):**

| Cluster | Tiers | Disposition | Why (one line) |
|---|---|---|---|
| `anonstore/database.go:15-166` | R2,R3,R4,A1,A3,A6,A8,A14,A15,FC3/5/7/9/10 | **composed** | The GR1 catch: FC6's stale-anchor mechanism + R3(ii)'s consequence + arch's `time.Now().UTC()` sibling → one new fix sentence no fragment states. |
| `impl.go:25-129` | R1,R7,A1,A2,A4,A9,FC3/4/14 | distinct | R1 (cache pre-set) and R7 (lost DI seam) are already cross-composed *by the rubric itself* ("deleted the seam that would have caught R1"). |
| `client.go:36-68` | R3,R5,R8,A7,FC7 | distinct | Timeout removal, sentinel leak, DoS amplification — three defects, each fully stated by its fragment. |
| `session.go:82-128` | A3,A8,FC10 | **needs-adjudication** | A3's retry re-execution fires exactly on the SQLite lock-retry path A8 puts on the auth path; composed consequence is plausible but each half is stated. |
| `wire.go:374-375` | R6,FC17 | distinct | R6 already merges arch+api+FC into one finding. |
| `impl.go:170` | A1,FC3 | distinct | Same 61-day-cleanup fact, already inside A1. |
| `pkg/api/admin.go:67` | A2,FC4 | distinct | Fourth duplicate constant — already A2's content. |
| `api/api.go:18` | FC3 | distinct | 30-day misnomer, already A1. |
| `grafana-data/.../config.ts:199-201` | A11 | distinct | One defect (type overstates wire contract), all fragments state it. |
| `grafana-runtime/.../config.ts:83-97` | A12 | distinct | One defect (missing annotation → `undefined` inference), already merged. |

**discourse-graphite-PR4 (11):** `topic_retriever.rb:1-53` (R3+R4 — the single inline `Jobs::PollFeed.new.execute({})` call is simultaneously the amplification vector and the Jobs::Base bypass; root already named in both rows) = **needs-adjudication**; the other 10 (embed.js R6/FC1; embed_controller R5/FC4; retrieve_topic A11; poll_feed R1/A12/FC6; post.rb R1; topic_embed R7/FC2-3; best.html.erb R1; layouts/embed R2; post_revisor FC5; embed_controller_spec A9/FC4) = **distinct** — each is either a single defect already merged across sources, or genuinely separate defects co-located by the R1 XSS chain, which the rubric already composed cross-file. 0 composed — consistent with ground truth (discourse's misses died at merge/tiering, upstream of Stage 3; composition cannot recover them).

**cal_com-PR11059 (11):** all **distinct**. The salesforce `CalendarService.ts:55-100` cluster (R1 missing import, R11 per-query OAuth round trip, R12 statusText predicate, FC17/18/27) is the designed negative control and correctly answers "distinct defects — independent mechanisms, independent fixes." The remaining ten (parseRefreshTokenResponse R5/R10/A16; refreshOAuthTokens R3/R7/R8; app-credential R6/A8/A17; googlecalendar R2; salesforce:20 R13; zoho-bigin R4; zoomvideo A9; constants R9; office365 A7; createOAuthAppCredential FC10) are all findings the rubric already composed across domains (e.g., R8 explicitly subsumes R7; A9 names its shared root with R6/R4). 0 composed — matches ground truth.

**Totals: 1 composed / 29 distinct / 2 needs-adjudication** over 32 qualifying clusters.
- Question-level precision: 1 productive compose per 32 forced questions (~3%); the 29 "distinct" answers are cheap correct answers, not errors.
- PR-level yield: **1 composed catch in 3 PRs** — and it is *the* known composition-reachable missed bug (grafana GR1), i.e., recall 1/1 on the bug the mechanism exists to catch, with 0 false compositions on the designed negative (cal.com).

## 4. Latency

No agent round-trip: the check runs inline in the Stage-3 synthesis turn over reports already in context. The only latency cost is streaming ~1K extra output tokens in that turn (seconds). No new tool calls required if compositions are restricted to already-quoted evidence (§2 recommendation).

## Verdict

**Justified.** ~1,020 output tokens per pass (~0.10% of a measured ~1M-token review pass), zero added round-trips, and on this sample the mechanism converts its entire addressable miss class: 1/1 composition-reachable missed bugs caught (grafana GR1), 0 spurious compositions on the negative control (cal.com), and correct silence where misses were lost upstream (discourse). Even the pessimistic read — 1 real catch per 3–5 PRs at 32 forced questions per 3 PRs — buys a real shipped-bug catch for roughly the token price of one paragraph per PR. Two design fixes before adoption: (1) cap cluster span or ask the forced question per red/amber finding-pair within mega-clusters (69-citation whole-file clusters make "one sentence" under-specified); (2) require composed claims to cite only evidence already quoted in the reports, else emit "needs-adjudication" — this keeps the cost model output-only and blocks hallucinated compositions.

**Falsifiers (prospective measurements that would flip this):**
1. **Volume:** if qualifying-cluster count on typical PRs runs ~5× this sample (≈50/PR), overhead is still only ~4.6K tokens (~0.5%) — cost alone almost cannot falsify; but at that volume the rubric section becomes 50 disposition rows, and if composed-row precision in live runs drops below ~1 true composition per 20 qualifying clusters (5%), the section is mostly noise the author must read — drop or tighten the qualifying gate (e.g., require 3+ sources, or restrict to red-tier).
2. **Precision:** run the mechanism live on the next ≥10 review cells; adjudicate every composed row against the author's actual fix. Abandon if >1 in 4 composed rows is refuted as a hallucinated composition, or if true composed catches fall below ~1 per 10 cells (at that rate the expected value no longer covers the attention cost of the rubric section, even though the token cost stays negligible).
3. **Sample bias:** this sample's ground truth (1 composition-reachable miss in 3 dense, deliberately bug-rich eval PRs) may overstate live incidence; if the first 10 live cells produce 0 composable misses *and* 0 composed rows, the mechanism is inert — cheap, but delete it rather than carry dead process.
