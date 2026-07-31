# Tech-Debt Triage Review — branch `exp/cross-model-openrouter-sweep`

Commit: 62594fb
**Date:** 2026-07-31
**Scope:** `git diff main...HEAD` (34 files, +7007/−287). Reviewable surfaces: `scripts/cross-model-review.py`, `scripts/dd-cross-model-sweep.py`, `scripts/self-improvement.sh`, `skills/code-review/SKILL.md`, the two new bats suites, and the docs/working + docs/decisions + docs/thoughts corpus. `runs/` and pre-existing `docs/reviews/` treated as immutable evidence.
**Role:** advisory contextual critic — all findings land in 🟢 Consider unless lifted by an evidence-gated channel.
**Prior art:** `docs/reviews/tech-debt-triage-review-2026-07-30.md` (7 items). This review is delta-focused; prior items are re-litigated only where the branch changed their status.

## Status of the 2026-07-30 items (delta check)

| Prior item | Status on this branch |
|---|---|
| 1 — k=3 arity hardcoded ~18 sites | Unchanged; the k→2 falsifier is now stated in Stage 1 and tested (`code-review-factcheck-replication.bats:87-90`), so the trigger is at least tracked. |
| 2 — k=3 rationale copy-pasted, no canonical source | **Partially remediated** (commit `ec0bff7` "canonicalize k=3 rationale"; SKILL.md now says "the rationale lives in one place — Stage 1's **Why three**"). |
| 3 — decision-log rows essay-length | **Worse** — see D5 below: row 29 (2,098 chars) is the longest row yet, added *after* the flag. |
| 4 — near-vacuous bats assertion | Not re-checked; superseded by the broader fragility-class finding D1. |
| 5 — sweep artifacts with no committed runner | **Remediated** (`scripts/dd-cross-model-sweep.py`, commit `81ab267`, docstring cites the finding). |
| 6 — state-doc §1 status-marker divergence | Unchanged (out of this delta's scope). |
| 7 — decision-log ID collision (two rows `26`) | **Resolved** — row IDs in `docs/decisions/log.md` are now unique (26, 20, 22, 23, 21, 24, 25, 27, 28, 29; still non-monotonic, which is cosmetic). |

Two of seven prior findings were remediated on this branch and one resolved — the review channel is being consumed, which matters for the goal-alignment assessment at the end.

## Triage Summary

| # | Debt Item | Carrying Cost | Cost of Deferral | Failure Cost | Fix Cost | Urgency | Recommendation |
|---|-----------|:---:|:---:|:---:|:---:|:---:|---|
| D1 | ~30 grep-pinned prose contracts now gate a 1,305-line SKILL.md; section extraction uses open-ended sed anchors | Medium | +~10 pinned phrasings per contract suite added (2 suites this branch) | | Hours | Before any SKILL.md restructure/reflow | Fix opportunistically |
| D2 | Phantom `§1.0` anchor cited in 8 files; the state doc has no `### 1.0` heading | Low | +1 citing file per state-doc reference (4 accrued this branch) | | Minutes | Now — cheap only while mutable citers number 4 | Fix now |
| D3 | `cross-model-review.py` at 500 lines / 7 responsibilities; OpenRouter plumbing duplicated in `dd-cross-model-sweep.py` | Low | +1 divergent API-client copy per new sweep script | | Hours | Third OpenRouter consumer, or first non-experimental use | Defer and monitor |
| D4 | No single source of truth for measured numbers; units drift (chars vs bytes vs KB vs tokens) across restatements | Medium | +1 restated (and driftable) figure per doc citing a measurement | | Hours | None imminent | Fix opportunistically |
| D5 | MD1-R1 narrative retold in 4+ places; log row 29 is a 2,098-char essay violating the log's own promotion rule | Medium | +1 divergent retelling per experiment landed | | Hours | None | Fix opportunistically |
| D6 | `docs/working/` at 60+ files with no lifecycle; superseded experiment docs indistinguishable from live ones | Low–Medium | +~4 working docs per experiment branch | | Hours | First onboarding of a second contributor / agent misreads a superseded doc | Fix opportunistically |
| D7 | Gate 1h sed-parses `**Replication:**`/`Commit:` prose fields defined only in SKILL.md; format drift degrades silently to "absent" | Low | +0 — inert while the check stays advisory | | Hours | The replication field ever becomes gating | Carry intentionally |

Failure-cost column left blank throughout: every item here is process/documentation ergonomics with no production, security, or data-integrity path; populating it would be fabrication.

### Recommended Order

1. **D2** (minutes, single file, validates 8 existing citations).
2. **D1** before the next deliberate SKILL.md restructure — and treat D1 as a *constraint* on fixing D4/D5, since trimming duplicated prose can break pinned greps.
3. **D5 + D4 together** (both are "cite, don't restate" fixes; one editing pass).
4. **D6** as a standalone housekeeping commit when convenient.
5. **D3, D7**: no action now; triggers named below.

---

## D1: grep-pinned prose contracts on a 1,305-line living document

**Location:** `skills/code-review/SKILL.md` (1,113 → 1,305 lines on this branch, +17%); `test/skills/code-review-factcheck-replication.bats`; `test/skills/code-review-soundness-crosscheck.bats` (243 lines, ~21 tests, all new)
**Nature:** testing/structural — contract tests coupled to exact prose phrasing and heading names
**Cost of Deferral:** +~10 pinned phrasings per contract suite added (two suites, ~30 assertions, landed on this branch alone)
**Legibility-target:** for-author

### Carrying Cost: Medium

Three coupled mechanisms:

1. **Exact-phrase pins.** Assertions like `grep -qiE 'one rich shared brief'` (`code-review-factcheck-replication.bats:109`), `'majority vote is explicitly the wrong aggregator'` (`:65`), and the full severity-order regex (`:71`) mean SKILL.md prose can no longer be *reworded*, only appended to. The authors know this — `stage1_flat` (`:34`) exists precisely because hard-wrap reflow already broke matching, and the trigger brief records reflow biting this branch twice. Each new contract suite converts more of the document from prose into de-facto frozen API surface.
2. **Open-ended sed extraction.** `stage1()` (`code-review-factcheck-replication.bats:29-31`) extracts `/^### Stage 1: Code Fact-Check/,/^### Fact-Check Gate/`; `channel()` (`code-review-soundness-crosscheck.bats:32-34`) does the same with `/^### Rubric Status Line/` as the end anchor. If a *start* anchor is renamed the tests fail loudly (good). If an *end* anchor is renamed, sed prints to end-of-file — the "section" silently becomes the rest of the document, and section-scoped assertions can pass on text that lives outside the section they claim to check. That is a false-green failure mode, the worst kind for a contract suite.
3. **Document scale.** At 1,305 lines with 190+ added this branch, SKILL.md is a runtime artifact (pasted into agent context) as much as a document. Its own instructions now include cross-references to five external docs, two channels, three cross-checks, and a merge algorithm. The cost is paid on every read by every orchestrator run — and line-number citations from other docs (a Stage-1 fact-check pain point on this branch) break on any reflow, which the grep pins then also punish.

### Fix Cost

- **Scope:** localized — the two new bats suites plus a convention.
- **Effort:** hours. Concrete moves: (a) give each end anchor a *sentinel* it can't silently lose, e.g. assert the end heading exists before extracting (`grep -q '^### Fact-Check Gate'` in `setup()`), so a rename fails loudly instead of over-matching; (b) prefer pinning *structural tokens* the contract actually needs (heading names, field names like `**Replicate verdicts:**`, enum values like `Contested-Soundness`) over connective prose ("never brief quality"); (c) adopt stable HTML anchors or heading-based citations instead of line numbers when other docs cite SKILL.md.
- **Risk:** low — test-only changes; the contracts' meaning is preserved.
- **Incremental?** Yes — per-suite.

### Urgency Triggers

- Any planned restructure or reflow of SKILL.md (including fixes to D4/D5 below, which delete or reword duplicated prose the greps may pin).
- A third contract suite in this style — the convention should be settled before the pattern is copied again.

### Recommendation

**Recommendation:** Fix opportunistically

The prose-grep approach is a reasonable answer to "an unenforced prose instruction does not execute," and the suites caught real regressions on this branch. The debt is not the pattern but two specifics: silently open-ended section extraction (a false-green trapdoor, cheap to close) and pinning connective prose rather than structural tokens. Fix when next touching the suites; do not restructure SKILL.md *first* — sequencing matters here.

---

## D2: phantom `§1.0` anchor — cited in 8 files, defined in none

**Location:** `docs/thoughts/code-review-evaluation-state.md:37-53` (the `## 1.` intro has no `### 1.0` subsection; subsections start at 1.1); citers: `skills/code-review/SKILL.md` (Stage 1 "Why three"), `test/skills/code-review-factcheck-replication.bats:7`, `docs/decisions/log.md`, `docs/thoughts/code-review-evaluation-state.md:53` (self-citation), plus four immutable review artifacts
**Nature:** documentation — dangling cross-reference in the doc's own numbering scheme
**Cost of Deferral:** +1 citing file per state-doc reference; 4 mutable citers accrued on this branch alone
**Legibility-target:** for-author

### Carrying Cost: Low

Every `§1.0` citation currently resolves to nothing a reader can navigate to. The referent is real — the "two verdict-driven blocking channels" statement — but it lives unnumbered in the `## 1.` intro prose. The state doc's numbered-section scheme *invites* this citation form (1.1–1.5 exist, so §1.0 looks legitimate), which is why four independent writers used it. Stage-1 fact-check already burned verification time on it this branch. The cost is small per incident but the anchor is quoted in a bats file header and a SKILL.md channel rationale, so it propagates into every future artifact that copies those.

### Fix Cost

- **Scope:** single file, ~3 lines.
- **Effort:** minutes — insert a `### 1.0 The two blocking channels` heading (or equivalent) above the existing statement in the state doc's §1 intro. All 8 citations, including the immutable ones, become retroactively valid; no citer needs editing.
- **Risk:** low. One check: no bats grep pins the current §1 intro layout (verified — the suites extract SKILL.md, not the state doc).
- **Incremental?** N/A — atomic.

### Urgency Triggers

- Each additional file that cites `§1.0` raises the cost of the alternative fix (renaming the citation), so the heading-insertion fix is cheapest *now*.

### Recommendation

**Recommendation:** Fix now

Trivial-fix class per this skill (single file, under 50 LOC): make the change, run the bats suites, commit. The fix direction matters — add the anchor rather than chase the citers, because half the citers are immutable review artifacts.

---

## D3: `cross-model-review.py` cohesion and the duplicated OpenRouter plumbing

**Location:** `scripts/cross-model-review.py` (362 → 500 lines this branch: second prompt template at :78-94, `build_stage1_context()` at :122-175, dry-run path); `scripts/dd-cross-model-sweep.py:21-42` (independent `call()`, API URL, headers, retry loop)
**Nature:** structural — single-file script accreting subsystems; small cross-script duplication
**Cost of Deferral:** +1 divergent API-client copy per new sweep script (currently 2; retry policy, timeout, and max_tokens already differ between them)
**Legibility-target:** for-author

### Carrying Cost: Low

`cross-model-review.py` now holds seven concerns (arg parsing, git context assembly, two prompt templates, API client with retry, pricing/cost guard, finding parsing/matching/judging, overlap analysis). That is a lot for one file, but the coupling is honest: everything serves one measurement pipeline, the file has a strong module docstring, and functions are cleanly separated — `build_stage1_context()` is already extraction-shaped if a module is ever wanted. The duplication with `dd-cross-model-sweep.py` is ~25 lines and *deliberately* divergent (the sweep script needs `max_tokens: 48000` for reasoning models and a 1800 s timeout; the review harness needs per-run error isolation). Its docstring explicitly disclaims the overlap ("Distinct from scripts/cross-model-review.py…"). Premature extraction of a shared `openrouter.py` would couple two experiments that currently evolve independently — the classic second-order cost this skill warns about.

### Fix Cost

- **Scope:** localized — a ~60-line shared helper (URL, headers, retry, error taxonomy) plus two import edits, *if* done.
- **Effort:** hours.
- **Risk:** medium relative to benefit — both scripts produce committed evidence artifacts (`runs/`, findings.jsonl with `prompt_sha`); any refactor that perturbs prompt bytes or request shape invalidates comparability with historical numbers, which the harness goes out of its way to preserve (`--context-base` omitted ⇒ byte-identical pre-021 prompt).
- **Incremental?** Yes.

### Urgency Triggers

- A **third** script needs the OpenRouter client (rule of three).
- Either script graduates from experiment to routine pipeline component (e.g. Gate integration), at which point tests and a module boundary are warranted.

### Recommendation

**Recommendation:** Defer and monitor

Two consumers with intentionally different policies is below the extraction threshold, and comparability-preservation raises the refactor's real risk above its apparent one. Re-evaluate at the named triggers; until then, keep the cross-references in the two docstrings current — they are what prevents the duplication from becoming *hidden* duplication.

---

## D4: measured numbers have no single source of truth; units drift across restatements

**Location:** corpus-wide; concrete instances this branch: brief sizes as "4.5–5.1KB" / "2.3–3.0KB" / "7.8KB" (`docs/decisions/log.md` row 29, `docs/thoughts/code-review-evaluation-state.md` q#1, `docs/working/experiment-md1-r1-replication-2026-07-30.md`) while the harness measures chars and estimates tokens (`scripts/cross-model-review.py:332-346`, `build_stage1_context()` stats are char counts with a `_kb`-named threshold at :163); Stage-1 fact-check recorded one Incorrect and five Mostly-Accurate verdicts from exactly this class
**Nature:** documentation/process — per-doc duplication of measured values, with unit ambiguity at each copy
**Cost of Deferral:** +1 restated figure per doc citing a measurement; the fact-check noise floor this creates is now *measured* (it produced 6 degraded verdicts on this branch)
**Legibility-target:** for-orchestrator-synthesis

### Carrying Cost: Medium

The brief asks: structural fix, or inherent duplication? The answer splits. **Inherent:** each audience-facing doc legitimately needs *a* number inline — a log row that says "see meta.json" is worse than one that says "7.8KB brief." **Structural and fixable:** (a) the *authoritative* value should live in exactly one machine-written artifact per measurement (the `*.meta.json` files and `--dry-run` `prompt.txt`/stats output already are this for the harness paths — the DD-sweep README data errors came precisely from hand-transcription, per `dd-cross-model-sweep.py:6-9`); (b) restatements should carry their unit explicitly at first use and cite the artifact they were read from. The drift is not random: chars→KB→tokens conversions are done ad hoc in prose, and the ~4 chars/token heuristic (`cross-model-review.py:332`) silently underlies several token claims without being cited. Every restatement is a place a k=3 fact-check replicate must independently verify — this debt directly taxes the pipeline the branch is building.

### Fix Cost

- **Scope:** convention + light retrofit, not a rewrite. (1) Adopt "cite the measurement artifact, restate with unit" as a doc convention (one paragraph in the state doc or CLAUDE.md). (2) The already-committed fix pattern — generate tables from meta.json (C20 remediation) — extends naturally: future experiment docs paste generated blocks. (3) Optionally rename `max-inline-kb`-adjacent internals so char counts aren't labeled KB (`cross-model-review.py:170` prints `n // 1024` as KB from a char count — accurate for ASCII, drift-prone in prose derived from it).
- **Effort:** hours for the convention + a one-pass sweep of the four mutable docs.
- **Risk:** low; caveat from D1 — check bats pins before rewording anything in SKILL.md.
- **Incremental?** Yes — per doc.

### Urgency Triggers

- None imminent; escalates if a gate ever keys on a prose-restated number.

### Recommendation

**Recommendation:** Fix opportunistically

Do not attempt a global registry of numbers — that is over-engineering for a solo research repo. The cheap 80% is the citation convention plus generated tables, both of which the repo has already independently invented in one place each; this finding is "promote the existing pattern to the default."

---

## D5: the MD1-R1 narrative lives in 4+ places; log row 29 breaks the log's own format contract

**Location:** canonical: `docs/working/experiment-md1-r1-replication-2026-07-30.md` (220 lines); retellings: `docs/decisions/log.md` row 29 (2,098 chars, single table row), `docs/thoughts/code-review-evaluation-state.md` q#1 (~350 words), `skills/code-review/SKILL.md` step 3b (~120 words)
**Nature:** documentation — narrative duplication with per-copy wording drift (Stage-1 fact-check confirmed the wordings already differ)
**Cost of Deferral:** +1 divergent retelling per experiment landed; the 2026-07-30 review flagged the same pattern (its item 3) and the branch added the largest instance yet
**Legibility-target:** for-orchestrator-synthesis

### Carrying Cost: Medium

Debt assessment as asked: **the redundancy is partially load-bearing.** Three of the four copies serve distinct audiences with distinct obligations: the experiment doc is the evidence record (full tables, p-values); the state doc is the evaluation ledger (must summarize every result feeding the program); SKILL.md step 3b is an *operational directive* whose one-paragraph "why" is what stops a future editor from re-lean-ifying the brief — and a bats test pins its presence. Cutting any of these to a bare pointer would degrade its function. **The fourth copy is not load-bearing:** log row 29 restates mechanism, statistics (Fisher p≈0.0045), KB figures, validation results, and caveats — a full retelling inside a table row of a log whose own promotion rule says essay-length decisions get a numbered decision file. This exact violation was flagged one day earlier (prior review item 3, "+1 oversized row per decision-heavy branch"); row 29 confirms the predicted deferral rate. Four copies × drift = the fact-check replicates now adjudicate wording differences between them, which is measured noise (5 Mostly-Accurate verdicts).

### Fix Cost

- **Scope:** one file for the acute fix — either promote row 29 to `docs/decisions/029-rich-shared-brief.md` and shrink the row to 2-3 sentences + pointer, or just shrink the row (the experiment doc already holds the full record).
- **Effort:** under an hour.
- **Risk:** low. Sequencing caveat from D1: `code-review-factcheck-replication.bats:104-117` pins phrases in SKILL.md step 3b — leave that copy's wording alone.
- **Incremental?** Yes.

### Urgency Triggers

- The next decision-heavy branch (the observed rate is ~1 oversized row per such branch).

### Recommendation

**Recommendation:** Fix opportunistically

Keep three copies, kill the fourth's bulk: experiment doc as canon, state doc and SKILL.md as audience-specific derivatives that *cite* it, log row as a pointer. This also converts the prior review's item 3 from re-flagged to remediated.

---

## D6: `docs/working/` has no lifecycle — 60+ files, superseded and live docs interleaved

**Location:** `docs/working/` (60+ files: 11+ experiment/DD docs, 5 scope-exception notes, checkpoint files, TSVs, shell verifiers, a `scratch/` and `rounds/` dir); e.g. `dd-reviewer-context-management.md` is superseded by decision 021 + `stage1-context-cost-2026-07-31.md`, but nothing marks it
**Nature:** documentation/process — append-only accumulation with no archive, index, or supersession markers
**Cost of Deferral:** +~4 working docs per experiment branch (this branch added 4; the directory grows monotonically)
**Legibility-target:** for-author

### Carrying Cost: Low–Medium

For the human author the cost is mild clutter. The real reader is agents: session workflows say "read docs/thoughts and relevant working docs," and an agent that greps `docs/working/` cannot distinguish a superseded DD doc from a live one without reading it — the freshness-tracking heuristic (`Last verified`/`Relevant paths`, per CLAUDE.md) exists but most working docs predate it. The branch itself demonstrates the safe pattern (the state doc centralizes current truth and links out), which caps the damage: as long as agents route through `docs/thoughts/`, stale working docs mislead only on direct hits. But this branch's Stage-1 fact-check also shows agents *do* land directly on working docs.

### Fix Cost

- **Scope:** housekeeping — either a `docs/working/archive/` move for docs whose decision landed, or a one-line `Status: superseded by <X>` header stamped on each (cheaper, preserves paths cited elsewhere — prefer this, since review artifacts cite working-doc paths).
- **Effort:** an hour for a sweep; near-zero marginal cost if the header becomes part of the decision-record checklist ("when a DD doc's decision lands, stamp the DD doc").
- **Risk:** low with the header approach; the move approach breaks existing path citations and should be avoided.
- **Incremental?** Fully.

### Urgency Triggers

- An agent or session measurably acts on a superseded working doc (near-miss class already observed via fact-check misreads).
- Any second contributor onboarding.

### Recommendation

**Recommendation:** Fix opportunistically

Stamp, don't move. Add the supersession stamp to the decision-landing checklist so the debt stops accruing, then back-fill the existing docs in one pass when convenient.

---

## D7: Gate 1h parses prose-defined fields out of the fact-check report

**Location:** `scripts/self-improvement.sh:1481-1520` (new advisory check: `sed -n 's/^\*\*Replication:\*\* *//p'`, `sed -n 's/^Commit: *//p'`); field formats defined only in `skills/code-review/SKILL.md` Stage-1 merge step 3 and the replicate-dispatch step 4
**Nature:** structural — cross-artifact format coupling between a 1,800-line bash monolith and SKILL.md prose, with no shared schema or test linking them
**Cost of Deferral:** +0 — inert while the check stays advisory
**Legibility-target:** for-automated-gate

### Carrying Cost: Low

If SKILL.md ever rewords the field (`**Replication:**` → `**Replication (k):**`), the sed match fails and the gate reports "single-sample fact-check … (advisory)" — a false note, logged, never blocking. The degradation is silent but harmless *by design*: the check's own comment records the advisory stance, matches the surrounding pattern (rubric/sentinel cross-check), and stamps its output into the round log where a human would eventually notice a permanently-"absent" field. The bats suite pins the SKILL.md side of the format (`Replicate verdicts:`, `**Replication:** k=3` via the merge-step tests), which partially guards the coupling already.

### Fix Cost

- **Scope:** one bats assertion in an existing suite: generate a minimal conforming merged-report fixture and assert the two sed extractions in `self-improvement.sh` parse it — closing the loop between the prose contract and the consumer.
- **Effort:** under an hour.
- **Risk:** low.
- **Incremental?** Atomic.

### Urgency Triggers

- The `factcheck_replication` detail field (now in the gate's JSON) ever becomes a *blocking* input — at that point the silent-degrade path becomes a gate-bypass and this item jumps to Fix now.

### Recommendation

**Recommendation:** Carry intentionally

The coupling is real but the failure mode is a mislabeled advisory log line. Document the trigger (blocking use) and revisit then; spending the fixture-test hour now is defensible but ranks below every other item here.

---

## What I deliberately did not assess

- Correctness of the scripts (parse loop semantics, Jaccard math) — performance/security/fact-check critics' domain; I read the code only for structure.
- `runs/` artifacts and pre-existing `docs/reviews/` — immutable evidence per the brief.
- Prior-review items 1, 4, 6 beyond the delta table — unchanged status, re-litigating them adds noise.

## Goal-Alignment Note

This branch's goal is to make the review pipeline's judgments *measurable and stable* — k=3 replication, a validated soundness channel, comparable cross-model numbers. None of the debt found blocks that goal, and two findings (D3, D7) are explicitly *not worth fixing yet* because fixing them would risk the goal's own comparability and validation guarantees. The debt that matters most is reflexive: the pipeline's noise floor is now partly *self-inflicted* by its documentation practices — duplicated narratives (D5) and unit-drifting restated numbers (D4) are exactly what the k=3 fact-check then spends replicates adjudicating, and the phantom §1.0 (D2) is a one-heading fix that retroactively validates eight artifacts. Meanwhile the grep-pinned contract suites (D1) are doing their job today but are quietly freezing SKILL.md's prose at the moment the document most needs room to be restructured; sequence any SKILL.md cleanup as tests-first. The healthiest signal in the diff is that last review's findings were consumed (two remediated, one resolved, one with its runner committed and the finding cited in its docstring) — the review-fix loop this repo is building is demonstrably closing on itself, which is precisely the PR's stated purpose. Findings here are advisory (🟢 Consider) and none meets an evidence-gated lift trigger.
