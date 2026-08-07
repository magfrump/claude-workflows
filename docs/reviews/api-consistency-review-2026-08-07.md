# API Consistency Review — 032 #3 inlining + #4 calibration (code-review SKILL + decision records + baseline run artifacts)

Commit: 2f5ad0b

**Scope:** `HEAD~3..HEAD` (de9ccf7, 45fa1df, 2f5ad0b) — `skills/code-review/SKILL.md`, `docs/decisions/032-review-loop-token-reduction-levers.md`, `docs/decisions/log.md` row 34, `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md`, `runs/review-arms/baseline-2026-08-06/hunt-verify/*`, `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md`
**Date:** 2026-08-07
**Based on:** merged code-fact-check (k=3) supplied by the orchestrator — Claims 11, 12, 21, 24, 25, 3, 13, 19

Commits and files outside `HEAD~3..HEAD` are treated as *already committed — context only, not under review*; where an out-of-scope file is cited it is as a **consumer** of an in-scope contract, not as work flagged missing.

### Baseline Conventions

Surveyed to establish what "consistent" means here:

1. **Pipeline subsection headings in `skills/code-review/SKILL.md`** — `### Fact-Check Gate` (:461), `### First-red short-circuit (decision 032 #4)` (:474), `### Between-stage status banner` (:281 region), `#### Large diff triage (~1000+ lines)` (:103). Pattern: plain-English feature name, optional `(decision NNN #N)` provenance suffix; anchors are the GitHub slug of the full heading (`#first-red-short-circuit-decision-032-4`, referenced at :210).
2. **Numbered dispatch contracts** — Stage 1 step list (:338-360) and Stage 2 step list (:632-648) are parallel, near-identical instruction sequences (read skill file → paste → scope spec → intent → fact-check → output path). They are the *executable* surface: an orchestrator follows the numbered steps literally. `## Important Reminders` (:1399-1416) is the third restatement of the same rules.
3. **Decision-record amendment convention** — `docs/decisions/023-wire-hooks-from-the-image.md:3` carries `**Amended:** 2026-07-30 (A, B below)` in the header plus `## Amendment A/B` sections; `022:72` uses a `> **Superseded by [023](…)**` blockquote; `docs/decisions/log.md` row 29 uses an inline `[Corrected 2026-07-31 per the k=3 fact-check: …]` bracket. In-place rewrites without any of these three markers are not the established form.
4. **Decision-record citation style** — `032:116` cites `runs/review-arms/baseline-2026-08-06/` repo-root-relative; `032:5-8` cites working docs by bare filename only when they live in a directory the header already names (`**Grounded in**: E1 (`e1-results-2026-08-06.md`)`). New SKILL citations at :240 and :496 use full repo-relative paths.
5. **Run-artifact schema, `runs/review-arms/baseline-2026-08-06/`** — one directory per instance (`csp/`, `lean/`, `hygiene/`, `secdeps/`, `fscompat/`, `corpus/`, `postfix/`, `deploy/`), each holding `fact-check.md` + `critic-<domain>.md`; every artifact's first line is `Commit: <sha>`; `manifest.json` is the declared machine ledger and `token-ledger.md` the declared per-agent token record (`manifest.json.authoritative_records`). `runs/review-arms/e3-loops/` shows purpose-named subdirectories (`csp-arm1`, `validate-T-arm2`) are an accepted sibling pattern for sub-runs.
6. **Code-fact-check report schema** — header block `**Repository:** / **Scope:** / **Checked:** / **Total claims checked:** N / **Summary:** a verified, b mostly accurate, c stale, d incorrect, e unverifiable`, then one `## Claim N` per claim with `**Verdict:**`. The `**Summary:**` line is the field Stage 2 step 5 (`SKILL.md:642-644`) and the Stage-1 merge consume when they decide which rows to forward.

### Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `Inline shared-context prefix (decision 032 #3)` | H3 heading | `First-red short-circuit (decision 032 #4)`; `Fact-Check Gate` | `skills/code-review/SKILL.md:474` | Consistent — now matches the `<feature> (decision NNN #N)` shape exactly (the prior title's `(prompt-cache discipline — decision 032 #3)` parenthetical was the outlier) |
| `#inline-shared-context-prefix-decision-032-3` | intra-doc anchor | `#first-red-short-circuit-decision-032-4` | `skills/code-review/SKILL.md:210` | Consistent — slug matches the heading; no stale references to the old anchor exist anywhere in the repo |
| `**Size guard — when NOT to inline.**` | bolded lead-in label | `**Stability rules that make the cache actually hit:**`; `**Partial-scope reviews must label out-of-scope sibling work.**` | `skills/code-review/SKILL.md:268`, `:101` | Consistent |
| `Critic-stage trigger (limited)` | numbered-step label | `Earliest trigger — the fact-check gate` | `skills/code-review/SKILL.md:493` | Consistent (parenthetical qualifier is new but reads as the same label family) |
| `canon-adjacent` | evidence-provenance label | `canon` / `canon labels`; run docs say "hunted commit" / "candidate A/B" | No existing precedent in `skills/`, `docs/`, `runs/` (sole occurrence: `SKILL.md:495`) | Minor — see Finding 9; severity downgraded one tier per the no-precedent rule |
| `levers-3-4-measurement.md` | run-doc filename | `token-ledger.md`, `results.md`, `k1-recall-reconstruction.md` | `runs/review-arms/e3-loops/k1-recall-reconstruction.md` | Consistent |
| `hunt-factcheck-behavioral-lie.md` | run-doc filename | same as above | `runs/review-arms/e3-loops/corpus-pass1-under-T.md` | Consistent |
| `hunt-verify/` | run sub-directory | `csp-arm1/`, `validate-T-arm2/`, `carry-arm2-pass2/` | `runs/review-arms/e3-loops/` | Consistent (purpose-named sub-run dirs have precedent) |
| `candA-critic-api-consistency.md`, `candB-fact-check.md` (8 files) | run-artifact filenames | `csp/critic-api-consistency.md`, `csp/fact-check.md` | `runs/review-arms/baseline-2026-08-06/csp/`, `…/lean/`, +5 more cells | Inconsistent — see Finding 4 |
| `hunt-verify/results.md` | run-doc filename | `runs/review-arms/baseline-2026-08-06/results.md` | same run directory | Minor — name is right, but it now collides within one run tree; see Finding 6 |

### Findings

#### 1. Step 1's new inline-by-default policy is contradicted by both numbered dispatch contracts and the Important Reminders

**Severity:** Breaking
**Location:** `skills/code-review/SKILL.md:99` vs `:340-344`, `:634-636`, `:1406`
**Move:** Trace the consumer contract / Look for the asymmetry
**Confidence:** High
**Evidence:**
```
99: Diff delivery to agents is conditional (decision 032 #3, see [Inline shared-context prefix](#inline-shared-context-prefix-decision-032-3)): for a normal-sized diff, inline it once as the shared cacheable prefix of every agent prompt; …
340: 3. Include the scope specification (e.g., "Review files changed on the current branch relative
341:    to main using `git diff main...HEAD`"). …
634: 3. Include the scope specification so the agent runs its own `git diff`. If the scope is
1406: - **Pass scope, not diffs.** Each agent runs its own `git diff` to avoid context budget issues.
```
**Legibility-target:** for-author

The consumer of this contract is an orchestrator executing the pipeline, and it does not execute the prose at :99 — it executes the numbered dispatch steps at :340 and :634, then sanity-checks itself against `## Important Reminders`. All three still specify the pre-#3 behavior, and :1406 states it as a categorical prohibition ("Pass scope, not diffs") on exactly what :99 now mandates as the default. This is the failure mode the fact-check flagged three times independently (Claims 21, 24, 25). The practical consequence is that the lever this commit exists to ship never fires: an orchestrator following the steps produces the old self-read dispatch, and the measured ~5% cost benefit at `levers-3-4-measurement.md` is not realized. It also creates a live self-contradiction for a reader trying to decide what to do.

**Recommendation:** Update Stage-1 step 3 and Stage-2 step 3 to "Include the shared-context block per [Inline shared-context prefix](#inline-shared-context-prefix-decision-032-3) — inline the diff + enclosing files by default; pass the scope spec instead when the size guard applies", and rewrite the :1406 reminder to "**Diff delivery is conditional.** Inline the shared diff/context prefix by default; fall back to scope-only on large diffs." Keep one canonical statement and make the other two point at it, as :1401-1404 already does for the k-replication rule.

---

#### 2. Decision 032 and log row 34 still describe the SKILL as *not* inlining — the same commit that made it inline

**Severity:** Inconsistent
**Location:** `docs/decisions/032-review-loop-token-reduction-levers.md:102-107`, `:120-126`; `docs/decisions/log.md:53` (row 34)
**Move:** Look for the asymmetry / Assess the versioning impact
**Confidence:** High
**Evidence:**
```
102: - **#3 shared-context prefix / prompt-cache discipline** — added to `skills/code-review/SKILL.md`
103:   as a new "Shared-context prefix" subsection under **The Pipeline**: the shared block is built
122:   production Agent-tool loop does **not** inline — critic agents self-read the diff/files/fact-check
124:   billing-rate effect, invisible to the token-count metric. Realizing even the ~5% needs a SKILL
125:   restructure to inline the shared diff+fact-check prefix. **Verdict: leave caching on (free),
```
and, from log row 34: `(that figure assumed the cross-model harness's diff-inlining; the production SKILL has critics self-read, so the shared cacheable prefix is ~330 tok)`.

**Legibility-target:** for-author

The commit recalibrated the #4 bullet in both files but left the #3 bullets untouched, so the decision record — which is the citation authority the SKILL points back to — now asserts in the present tense that the production SKILL does not inline and that realizing the saving "needs a SKILL restructure", while that restructure is in the same commit. `:103` additionally names the subsection `"Shared-context prefix"`, a title that no longer exists after the rename to `Inline shared-context prefix`. Consumers are future readers reconciling the two documents and any later measurement run that reads 032 to learn the as-shipped configuration; both get the wrong baseline. This is the same asymmetry class as Finding 1, one level up.

**Recommendation:** Amend 032's Implementation-status bullet to the new heading title and the inline-by-default form, and add a sentence to the measured bullet — "the restructure is now shipped (SKILL `Inline shared-context prefix`, 2026-08-07); the ~5% is therefore in play, still cost-side only." Mirror the same clause in log row 34 so the two stay in sync, and add `**Amended:** 2026-08-07` to the 032 header per the `023:3` precedent.

---

#### 3. Cross-document restatements of "sub-agents run their own git diff" now contradict the new default

**Severity:** Inconsistent
**Location:** `guides/sub-agent-briefing.md:78`, `patterns/orchestrated-review.md:153` (consumers of the in-scope contract at `skills/code-review/SKILL.md:99`)
**Move:** Trace the consumer contract
**Confidence:** High
**Evidence:**
```
guides/sub-agent-briefing.md:78: **Fix:** Pass the path, not the contents. … For code review, sub-agents run their own `git diff` rather than receive a pasted diff.
patterns/orchestrated-review.md:153: … (2) the scope spec: the exact slice the sub-agent should examine …, with instructions to gather its own primary evidence (e.g., run its own `git diff`) rather than relying on a paste;
```
**Legibility-target:** for-author

Both documents state the old rule as general guidance and name code review as the worked example, and `SKILL.md:648` cites `patterns/orchestrated-review.md` as normative for dispatch (legibility-target tagging), so the pattern doc is a live upstream of the pipeline, not incidental prose. An author writing a new orchestrator from the briefing guide will build the pre-#3 dispatch. These files are outside `HEAD~3..HEAD`, so this is documentation drift *caused by* the in-scope change rather than pre-existing work — the contract moved and its restatements did not.

**Recommendation:** Add the conditional to both: "for code review, the shared diff is inlined once as a cacheable prefix by default and self-read only on large diffs (decision 032 #3)". One sentence each; do not restate the size threshold in three places — link to the SKILL section.

---

#### 4. `hunt-verify/` flattens the per-instance artifact layout the rest of the run uses

**Severity:** Inconsistent
**Location:** `runs/review-arms/baseline-2026-08-06/hunt-verify/candA-fact-check.md`, `…/candA-critic-{api-consistency,performance,test-strategy}.md`, `…/candB-{fact-check,critic-api-consistency,critic-architecture,critic-security}.md`
**Move:** Establish the baseline conventions / Check naming against the grain
**Confidence:** High
**Evidence:** directory listing of the same run — `csp/critic-api-consistency.md`, `csp/critic-architecture.md`, `csp/critic-performance.md`, `csp/critic-security.md`, `csp/critic-test-strategy.md`, `csp/fact-check.md` (identically for `lean/`, `hygiene/`, `secdeps/`, `fscompat/`, `corpus/`, `postfix/`, `deploy/`).
**Precedent:** `<instance>/critic-<domain>.md` + `<instance>/fact-check.md` used in `runs/review-arms/baseline-2026-08-06/*/`
**Legibility-target:** for-author

Candidates A and B are review instances exactly like the eight canon cells — same stage set, same artifact types — but their artifacts are flattened into one directory with a `candA-`/`candB-` filename prefix instead of `candA/` and `candB/` directories. `manifest.json.authoritative_records` describes the layout as "All 38 review artifacts on disk under `<cell>/`", and the run's declared resume procedure ("scan artifacts, validate Commit line, dispatch only missing stages", `manifest.json.method`) is keyed to that shape; a resume pass or a later scorer globbing `*/critic-*.md` silently misses these eight. The worktrees for the same candidates *did* follow convention (`wt-candA`, `wt-candB`), which makes the artifact layout the odd one out within its own sub-run.

**Recommendation:** Move to `hunt-verify/candA/{fact-check,critic-*}.md` and `hunt-verify/candB/…`, updating the four citing references (`levers-3-4-measurement.md`, `hunt-verify/results.md`, `032:130`, `SKILL.md:496`). If the flat layout is deliberate because these are not canon cells, say so in one line at the top of `hunt-verify/results.md` so the deviation is legible.

---

#### 5. The hunt sub-run's 8 agents and 577,971 tokens are absent from the run's declared authoritative ledgers

**Severity:** Inconsistent
**Location:** `runs/review-arms/baseline-2026-08-06/manifest.json` (`totals`, `authoritative_records`, `known_gaps`), `runs/review-arms/baseline-2026-08-06/token-ledger.md`
**Move:** Trace the consumer contract / Verify the nullability contract
**Confidence:** Medium
**Evidence:**
```
manifest.json: "authoritative_records": "token-ledger.md (per-agent tokens + gating), results.md (cost + recall scoring). All 38 review artifacts on disk under <cell>/, each first line Commit-stamped."
manifest.json: "totals": {"stage1_factcheck_tokens": 627745, "stage2_critic_tokens": 2358346, "core_pipeline_tokens": 2986091, "agents": 38, "critics_skipped_by_gating": 9}
token-ledger.md:3: Tokens = subagent_tokens from task notifications (same instrument as E1/E3). Append as stages land.
```
and `hunt-verify/results.md` §Measurement cost: `A pass 252,992 … + B fc 86,824 = **577,971 tokens** (plus the earlier 3-agent history hunt ≈ 335k)`.
**Legibility-target:** for-author

`token-ledger.md` declares itself append-only for per-agent tokens from this instrument, and `manifest.json` declares itself the run's machine index; both now under-report the directory they describe (46 artifacts, not 38; 11 measured agents beyond the 38). The tension is real in the other direction too — `2,986,091` is a *defined denominator* cited by `032:116`, `log.md` row 34, and `results.md` §5, so folding hunt tokens into `core_pipeline_tokens` would silently move a published baseline. That argues for recording, not merging.

**Recommendation:** Leave `totals` untouched and add a sibling key — e.g. `"sub_runs": {"hunt-verify": {"agents": 8, "tokens": 577971, "purpose": "032 #4 empirical trigger measurement", "excluded_from_totals": true}}` — plus a `## Sub-run — hunt-verify (#4)` section in `token-ledger.md` with the per-agent rows already tabulated in `hunt-verify/results.md`. State explicitly that it is excluded from the baseline denominator.

---

#### 6. `hunt-verify/results.md` is cited by a bare relative path that does not resolve from `docs/decisions/`

**Severity:** Minor
**Location:** `docs/decisions/032-review-loop-token-reduction-levers.md:129-130`; same form in `docs/decisions/log.md:53`
**Move:** Trace the consumer contract / Check naming against the grain
**Confidence:** High
**Evidence:**
```
129:   Empirically fired on a hunted commit (evidence-integrate `counterexamples`/`scenarios`,
130:   `hunt-verify/results.md`): fact-check confirmed the behavioral 🔴 and #4 skipped the whole critic
```
**Precedent:** repo-root-relative run citations used in `docs/decisions/032-review-loop-token-reduction-levers.md:116` (`runs/review-arms/baseline-2026-08-06/`) and `skills/code-review/SKILL.md:496` (`runs/review-arms/baseline-2026-08-06/hunt-verify/results.md`)
**Legibility-target:** for-author

`hunt-verify/results.md` resolves nowhere from `docs/decisions/`, and the basename is ambiguous now that two `results.md` files exist under the same run (Finding 6 in the audit table). `test/cross-reference-integrity.bats` only validates links whose target contains `workflows|skills|guides|patterns`, so nothing catches this — the cost lands on a human or agent following the citation. The in-scope SKILL edit at `:496` got this right, which is the pattern to copy.

**Recommendation:** Expand both citations to `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md`, matching `032:116` and `SKILL.md:496`.

---

#### 7. `candB-fact-check.md`'s Summary field disagrees with its own body

**Severity:** Minor
**Location:** `runs/review-arms/baseline-2026-08-06/hunt-verify/candB-fact-check.md:8-9`
**Move:** Verify the nullability contract / Verify error consistency
**Confidence:** High
**Evidence:**
```
8: **Total claims checked:** 9
9: **Summary:** 7 verified, 0 mostly accurate, 0 stale, 1 incorrect, 1 unverifiable
```
The body carries nine `**Verdict:**` lines (`:17, :46, :72, :139, :161, :184, :204, :230, :258`): eight Verified and one Incorrect, zero Unverifiable.
**Legibility-target:** for-author

This is fact-check Claim 12, and it matters here because `**Summary:**` is a parsed field, not decoration: `SKILL.md:642-644` has Stage 2 forward only Incorrect/Stale/Mostly-Accurate rows for reports over 200 lines, and this report is 290 lines. A reader or downstream stage trusting the header believes an unverifiable claim exists that does not, which slightly overstates the uncertainty behind the headline "#4 fires on candidate B" result. The sibling cell reports (e.g. `csp/fact-check.md:7-8`) keep header and body in agreement. Fact-check Claim 13 also places the same report's `integrateValidation.ts:56` citation at `:51`.

**Recommendation:** Correct line 9 to `8 verified, 0 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable` and fix the `integrateValidation.ts` line number at `:129,:131`.

---

#### 8. `pr-prep.md`'s restatement of #4 still promises the saving the SKILL just downgraded

**Severity:** Minor
**Location:** `workflows/pr-prep.md:223-231` (consumer of the in-scope contract at `skills/code-review/SKILL.md:500-504`)
**Move:** Look for the asymmetry
**Confidence:** Medium
**Evidence:**
```
pr-prep.md:225: you run to *confirm* the branch is clean. With `--loop-pass`, the review stops as soon as a
pr-prep.md:226: behavioral 🔴 is confirmed (skipping the rest of the critic panel for that pass), since a fix and
SKILL.md:502:    returns a behavioral 🔴, do not launch any *second wave* … Note this saves little in practice: the core
SKILL.md:503:    panel is one parallel wave already in flight, so there is usually nothing left to skip (measured:
```
**Legibility-target:** for-author

`pr-prep.md` is the workflow that actually passes `--loop-pass` (it is named as the wiring site in `032:109`), so it is the primary consumer of #4's contract. Its unqualified "the review stops as soon as a behavioral 🔴 is confirmed (skipping the rest of the critic panel)" is now true only for the fact-check-gate trigger; for the critic-stage trigger the SKILL's own recalibration says there is usually nothing left to skip. The behavioral instruction (pass `--loop-pass` on non-terminal passes) is unchanged and correct — only the expectation it sets is now overstated, which is the same class the 2026-07-31 review flagged at `SKILL.md:101`.

**Recommendation:** Add a half-sentence qualifier — "…in practice this is a large saving only when the red is confirmed at fact-check; a critic-surfaced red usually leaves nothing to skip (decision 032 #4, measured)". Keep the `--loop-pass` instruction as-is.

---

#### 9. `canon-adjacent` is introduced as an evidence-provenance label with no definition and no precedent

**Severity:** Minor
**Location:** `skills/code-review/SKILL.md:494-496`
**Move:** Check naming against the grain
**Confidence:** Medium
**Evidence:**
```
494:    the **entire** Stage-1.5/Stage-2 critic panel for this pass. This is the largest saving (the
495:    whole critic block) — measured at **~73% of the pass** on the one canon-adjacent case that
496:    fired it (`runs/review-arms/baseline-2026-08-06/hunt-verify/results.md`).
```
**Precedent:** No existing precedent in `skills/`, `docs/`, `runs/`, `workflows/`, `patterns/` — sole occurrence in the repo. Severity downgraded one tier (Inconsistent → Minor) per the no-precedent rule.
**Legibility-target:** for-author

The surrounding vocabulary is settled: `review-canon.md` v1 defines "canon" and the labelled cells, and the run docs consistently call these commits "hunted" candidates (`hunt-factcheck-behavioral-lie.md`, `hunt-verify/results.md` §2). "Canon-adjacent" reads as if the case carries some canon status it does not — it is a commit found by a 225-commit hunt specifically *because* no canon cell triggered the gate (0/8). A reader calibrating how much to trust the ~73% figure is nudged the wrong way.

**Recommendation:** Use the existing term: "on the one *hunted* commit that fired it (the canon's 8 reviewed states fired 0/8)". That also carries the frequency caveat the same sentence is trying to make.

---

#### 10. 032's head-of-document claim for #3 still contradicts its own measured section

**Severity:** Informational
**Location:** `docs/decisions/032-review-loop-token-reduction-levers.md:26-32` vs `:120-126`
**Move:** Look for the asymmetry
**Confidence:** High
**Evidence:**
```
31:    path** (H4: the sweep's byte-identical-prompt confound control is load-bearing). Biggest
32:    input-token lever; adopt first and independently.
120: - **#3 prompt-cache: ~5% cost-equivalent, 0% token-count — NOT 20–40%.** The 20–40% estimate was
```
**Legibility-target:** for-orchestrator-synthesis

Pre-existing — introduced by `d4e362d`, which is outside `HEAD~3..HEAD`, so this is context, not a defect of this diff. Noting it because Finding 2 will require touching the same document, and because a reader who stops at the Decision section takes away "biggest input-token lever" while the measured section says single-digit-% and cost-side only. The repo's convention for exactly this situation exists (`023:3` header `**Amended:**`, `022:72` superseded blockquote).

**Recommendation:** When applying Finding 2, add `· **Amended:** 2026-08-07 (see "Measured on the canon")` to the 032 header and a one-clause pointer on the `#3` Decision bullet. No change to the decision itself.

---

#### 11. No automated gate binds any of the diff-delivery instructions

**Severity:** Informational
**Location:** `test/skills/code-review-format.bats`, `test/skills/code-review-format-contract.bats`, `test/cross-reference-integrity.bats`
**Move:** Trace the consumer contract
**Confidence:** High
**Evidence:** `test/cross-reference-integrity.bats:33` — `| grep -E '(workflows|skills|guides|patterns)/'` (only content-directory link targets are validated; intra-file anchors and `runs/` paths are skipped). The code-review bats suites assert on rubric section headings (`'Confirmed Good' 'Unverified Findings' 'Skipped Core Critics'`), not on pipeline prose.
**Legibility-target:** for-orchestrator-synthesis

This explains why Findings 1, 3 and 6 could land green: the only consumer that can detect a contradiction between `SKILL.md:99` and `SKILL.md:1406` is a human or an orchestrator at runtime. Worth surfacing to synthesis as a coverage limit on this review class rather than a defect of this diff — the same three-place restatement pattern (Step 1 / dispatch steps / Important Reminders) has now drifted twice in eight days.

**Recommendation:** No action in this PR. If the orchestrator wants durable protection, the cheapest gate is a bats assertion that `## Important Reminders` contains no sentence contradicting the Step 1 diff-delivery mode — or, more robustly, collapsing the three restatements into one canonical statement plus two anchors (Finding 1's recommendation does this for free).

### What Looks Good

- **The anchor-and-provenance heading pattern was followed precisely.** `### Inline shared-context prefix (decision 032 #3)` and its slug mirror `### First-red short-circuit (decision 032 #4)` / `#first-red-short-circuit-decision-032-4` at `:210`, and the new Step 1 link is the first intra-doc anchor reference added to this file that resolves correctly on the first try.
- **The size guard reuses an existing threshold instead of inventing one.** `:262-263` defers to "the ~1000-line / >40%-churn triage in Step 1" rather than declaring a second numeric limit — exactly the right move for a contract with an existing named threshold, and it forecloses the "threshold named in Step 1 but a different figure elsewhere" asymmetry.
- **`State which mode you used in the plan summary` (:265) lands on a real surface.** "Plan summary" is an established output channel in this SKILL (`:111` large-diff triage, `:151` missing-skill gap), so the new instruction is discoverable rather than dangling.
- **Recalibrated prose is honest and consumer-framed.** `:497-499` and `:502-504` state the negative result (rare trigger; critic-stage trigger saves ~0) in the same section that states the win, rather than quoting only the 73% headline. `hunt-verify/results.md` §"What this measures about #4" point 3 goes further and names candidate A as its own counterexample. This directly answers the 2026-07-31 empirical-warrant Must-Fix class.
- **Every new run artifact carries the `Commit: <sha>` first line** (`candA-*` → `e59c7ed`, `candB-*` → `6cf4b0d`), matching the run's stamping convention and preserving the manifest's stated resume-validation property.
- **The production-loop-only fence survived the rewrite intact.** `:277-281` still forbids porting caching to `scripts/cross-model-review.py`, and the reciprocal guard note at `scripts/cross-model-review.py:55-63` still points back at 032 (#3 / H4) — the one place where inlining the diff *is* the sweep's normal behavior, and where confusing the two would silently break confound control.

### Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Step 1 inline-by-default contradicted by both dispatch step lists and Important Reminders | Breaking | `skills/code-review/SKILL.md:99` vs `:340-344`, `:634-636`, `:1406` | High |
| 2 | 032 + log row 34 still describe the SKILL as not inlining; `:103` names the pre-rename heading | Inconsistent | `docs/decisions/032-…levers.md:102-107,120-126`; `docs/decisions/log.md:53` | High |
| 3 | `guides/`+`patterns/` restatements of "sub-agents run their own git diff" now contradict the default | Inconsistent | `guides/sub-agent-briefing.md:78`; `patterns/orchestrated-review.md:153` | High |
| 4 | `hunt-verify/` flattens the `<instance>/critic-<domain>.md` artifact layout | Inconsistent | `runs/review-arms/baseline-2026-08-06/hunt-verify/cand{A,B}-*.md` | High |
| 5 | Hunt sub-run's 8 agents / 577,971 tokens absent from `manifest.json` + `token-ledger.md` | Inconsistent | `runs/review-arms/baseline-2026-08-06/manifest.json`, `token-ledger.md` | Medium |
| 6 | `hunt-verify/results.md` cited by an unresolvable bare relative path | Minor | `docs/decisions/032-…levers.md:129-130`; `docs/decisions/log.md:53` | High |
| 7 | `candB-fact-check.md` Summary field disagrees with its own body (7V/1U vs 8V/0U) | Minor | `runs/…/hunt-verify/candB-fact-check.md:8-9` | High |
| 8 | `pr-prep.md`'s #4 restatement still promises the saving the SKILL downgraded | Minor | `workflows/pr-prep.md:223-231` | Medium |
| 9 | `canon-adjacent` — new undefined provenance label, no precedent | Minor | `skills/code-review/SKILL.md:494-496` | Medium |
| 10 | 032 Decision section's "biggest input-token lever" vs its measured section (pre-existing) | Informational | `docs/decisions/032-…levers.md:26-32` vs `:120-126` | High |
| 11 | No automated gate binds the diff-delivery instructions | Informational | `test/skills/code-review-format*.bats`, `test/cross-reference-integrity.bats` | High |

### Overall Assessment

The substance of this change is sound and the new `Inline shared-context prefix` section is well-formed — it follows the file's heading, anchor, label and threshold-reuse conventions exactly, and its recalibrated #4 prose is a genuine improvement in empirical honesty over the class of overstatement flagged on 2026-07-31. The problem is entirely one of incomplete propagation: this repo states its diff-delivery contract in five places (Step 1 prose, Stage-1 dispatch step 3, Stage-2 dispatch step 3, Important Reminders, plus the `guides/` and `patterns/` restatements) and only the first was changed, so the executable surface — the numbered steps an orchestrator actually follows — still specifies the pre-#3 behavior, and `:1406` categorically forbids the new default. That makes Finding 1 breaking in the operational sense: the lever ships inert and the instructions self-contradict. Every finding is fixable in place with small, local edits; none requires reopening the decision. Findings 1, 2 and 3 should land together (they are one propagation pass), Findings 4–7 are run-artifact hygiene that can follow, and the durable fix suggested under Finding 11 — collapsing the restatements to one canonical statement plus anchors — would prevent the third occurrence of this drift.

## Goal-Alignment Note
- Answered: yes — API-consistency review of `HEAD~3..HEAD`, 11 findings, report at `docs/reviews/api-consistency-review-2026-08-07.md`
- Out of scope: correctness of the token arithmetic and the 73%/~5% measurements (fact-check confirmed all headline arithmetic; not re-verified per the skill's foundation rule); `SKILL.md:1401`'s "always as k=3 replicates" reminder, which contradicts decision 031's k=1 but is pre-existing and unrelated to this diff; recall/security implications of inlining diffs into agent prompts (security-reviewer's surface)
- Escalate: Finding 1 is a shipped-inert lever plus a live self-contradiction in the pipeline's executable instructions — it should be a Must-Fix in the rubric, not an amber. Findings 2, 3 and 8 are the same propagation pass and should be fixed in one commit with it. Separately, `SKILL.md:1401` (k=3 vs decision 031 k=1) deserves its own drift check outside this range.
