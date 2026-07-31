# API Consistency Review — exp/cross-model-openrouter-sweep

Commit: 62594fb

**Scope:** `git diff main...HEAD` — reviewable surface: `scripts/cross-model-review.py` (new flags `--context-base`/`--max-inline-kb`/`--dry-run`, record schema), `scripts/dd-cross-model-sweep.py` (new CLI), `scripts/self-improvement.sh` Gate 1h hunk, `skills/code-review/SKILL.md` contract surface, `test/skills/code-review-factcheck-replication.bats`, `test/skills/code-review-soundness-crosscheck.bats`, decision/state docs. `runs/` artifacts and prior `docs/reviews/` reports treated as immutable evidence.
**Date:** 2026-07-31
**Based on:** Stage-1 merged code-fact-check findings (M14 merged-report/Gate-1h drift; `context_base` schema note; three docstring drifts) — behavior claims from that report are built on, not re-verified.

## Baseline Conventions

Observed conventions the diff must match:

- **CLI flags** (`scripts/cross-model-review.py:289-297`): kebab-case long flags, no short flags; unit suffix embedded in the flag name (`--max-usd`); mode toggles as bare `store_true` (`--analyze-only`); required-arg validation via explicit `sys.exit("<flags> are required unless <mode>")` messages rather than argparse `required=` (so mode combinations can relax them).
- **findings.jsonl records**: snake_case keys (`prompt_sha`, `parse_ok`, `n_findings`); error and success records share a common core; readers tolerate absent keys via `.get()` (`scripts/cross-model-review.py:425-429`).
- **Module-level constants** for prompts: `PROMPT_TEMPLATE`, `JUDGE_PROMPT` (`scripts/cross-model-review.py:62,96`).
- **Gate detail JSON** in `self-improvement.sh`: snake_case with full words separated by underscores (`red_findings`, `rubric_red`, `rubric_sentinel_agree`).
- **Review-artifact metadata**: every saved review artifact carries a `Commit: <hash>` top line (`skills/code-review/SKILL.md:1207`); the code-fact-check report schema has exactly five bolded header fields (Repository, Scope, Checked, Total claims checked, Summary — `skills/code-fact-check/SKILL.md:225-229`) enforced by `test/skills/code-fact-check-format.bats`.
- **Sibling scripts**: `cross-model-review.py` fails env/arg errors with `sys.exit(<message>)`, guards spend with `--max-usd`, takes models via `--models`.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--context-base` | CLI flag | `--max-usd`, `--analyze-only`, `--range` | `scripts/cross-model-review.py:289-297` | Consistent — kebab-case, prose help, validated in the explicit-exit style |
| `--max-inline-kb` | CLI flag | `--max-usd` | `scripts/cross-model-review.py:295` | Consistent — `max-<unit>` shape matches; unit semantics see Finding 9 |
| `--dry-run` | CLI flag | `--analyze-only` | `scripts/cross-model-review.py:297` | Consistent — `store_true` mode toggle, standard idiom |
| `context_base` | JSONL field | `prompt_sha`, `rev_range` (as `range`), `parse_ok` | `scripts/cross-model-review.py:374-410` | Consistent — snake_case, present in all three record shapes |
| `PROMPT_TEMPLATE_STAGE1` | constant | `PROMPT_TEMPLATE`, `JUDGE_PROMPT` | `scripts/cross-model-review.py:62,96` | Consistent — suffix-variant of the existing constant |
| `split_range`, `build_stage1_context` | function | `fetch_pricing`, `parse_findings`, `jaccard` | `scripts/cross-model-review.py:200-260` | Consistent — snake_case verb-noun |
| `factcheck_replication` | JSON key (gate detail) | `red_findings`, `rubric_red`, `rubric_sentinel_agree` | `scripts/self-improvement.sh:1519` | Minor — neighbors separate every word with `_`; `fact_check_replication` would match (Finding 7) |
| `CR_FC_REPORT`, `CR_FC_COMMIT`, `CR_REPLICATION` | shell var | `CR_ARCHIVE`, `CR_COMMIT`, `CR_RUBRIC_RED` | `scripts/self-improvement.sh:1404-1480` | Consistent — `CR_` prefix family |
| `dd-cross-model-sweep.py` | script name | `cross-model-review.py` | `scripts/` | Consistent name; interface style diverges (Finding 8) |
| `code-fact-check-report-r<N>.md` | artifact path | `code-fact-check-report.md` | `skills/code-review/SKILL.md:1192-1195`, both bats files | Consistent — suffix pattern, identical in SKILL, tests, and Output Locations tree |
| `**Replication:**` | report header field | `**Summary:**`, `**Total claims checked:**` | `skills/code-fact-check/SKILL.md:225-229` | Consistent — bolded-field style; Gate 1h's sed pattern matches it exactly |
| `**Replicate verdicts:**` | per-claim field | the five mandatory claim fields | `skills/code-fact-check/SKILL.md:235-238` | Consistent — additive sixth field, format bats unaffected |
| `Contested-Soundness` | severity vocab | `Contested` (Confirmed-Good cross-check) | `skills/code-review/SKILL.md:661-663` | Consistent — deliberate, distinguishable extension of the existing `Contested` label |
| `k=3` / `k=2 (one replicate failed)` | vocab token | — (first of its kind) | none — searched `skills/code-review/SKILL.md`, `scripts/self-improvement.sh`, both bats files | New category — identical string in SKILL:332-333,371-373, Gate 1h case arms (`self-improvement.sh:1502-1515`), and bats; convention established coherently |

## Findings

#### 1. Merged-report `Commit:` contract is split across distant clauses; the merge spec reads as complete without it, and Gate 1h silently no-ops when it is absent

**Severity:** Inconsistent
**Location:** `skills/code-review/SKILL.md:352-373` (merge spec), `skills/code-review/SKILL.md:292` (per-replicate mandate), `scripts/self-improvement.sh:1482-1500` (consumer)
**Move:** #3 (consumer contract)
**Confidence:** High

Gate 1h binds on two merged-report fields: `**Replication:**` and `Commit:` (`self-improvement.sh:1493-1494`). The SKILL mandates `Commit:` explicitly only on the per-replicate reports (step 4, SKILL:292), while the merged-report spec (merge step 3) declares the format "exactly — … the five header fields" plus `**Replication:**` — a list that reads as exhaustive and omits `Commit:`. The only mandate covering the merged report is the generic artifact rule ~850 lines away (SKILL:1207). The Gate 1h comment (`self-improvement.sh:1483-1485`) claims Stage 1 "stamps the merged report with a `**Replication:**` header field plus a `Commit:` line" — overstating what the local spec says. If an orchestrator follows the merge spec literally and omits `Commit:`, the stale-report check silently skips (`[ -n "$CR_FC_COMMIT" ]` guard) and a stale replication field is trusted — exactly the failure the hunk exists to catch. This corroborates fact-check M14.

**Recommendation:** Add `Commit: <current HEAD short SHA>` (and its short-vs-full matching rule) to merge step 3's header requirements, mirroring step 4's wording, so producer spec and Gate 1h consumer agree locally. Optionally assert it in `code-review-factcheck-replication.bats`.

**Legibility-target:** for-automated-gate

#### 2. Documented binary-file handling ("listed but not inlined") does not match the code path consumers will hit

**Severity:** Inconsistent
**Location:** `scripts/cross-model-review.py:22-23,109-110,154-162`
**Move:** #3 (documentation drift)
**Confidence:** Medium (behavior claim from Stage-1 fact-check; consistency assessment mine)

The module docstring and skip-list design promise that non-inlinable files are "listed but not inlined" (`:22-23`), and the `\x00` sniff (`:160-161`) implies binaries are tolerated and routed to the skip list. But `sh()` runs with `text=True` (`:109-110`), so a genuinely non-decodable binary raises `UnicodeDecodeError` before the sniff runs, crashing the whole run — the documented surface (graceful skip) and the actual surface (crash) disagree for any repo whose diff touches a binary. Additionally, when the sniff *does* catch a decodable pseudo-binary, it lands under the header `FILES TOO LARGE TO INLINE` (`:171-172`) with reason `binary` — the section title asserts a reason the entry contradicts.

**Recommendation:** Catch decode failure per-file (e.g., run the `git show` for context files with `errors="replace"` or bytes mode) and route it to the skip list; rename the section to cover both reasons (e.g., `FILES NOT INLINED`).

**Legibility-target:** for-author

#### 3. Keyless dry-run prints a "$0.00" projection and then states no projection was made

**Severity:** Minor
**Location:** `scripts/cross-model-review.py:334-359`
**Move:** #4 (error/degraded-mode consistency)
**Confidence:** High

With `--dry-run --models …` and no `OPENROUTER_API_KEY`, `pricing` is `{}` so every model prices to `(0, 0)`; line 348 unconditionally prints `projected spend: $0.00 across N models x R`, then line 359 appends `(no OPENROUTER_API_KEY: token counts only, no $ projection)`. The two lines contradict each other, and `$0.00` is indistinguishable from a genuine near-zero projection. The sibling degraded-mode messages (`:434-435` stage-1-only judge fallback) name the degradation without emitting a fake value — this path should match that pattern.

**Recommendation:** Guard the `projected spend` line with `if pricing:` (the per-model loop already is), so keyless dry-runs print only the token counts and the explanatory note.

**Legibility-target:** for-author

#### 4. Help/docstring units drift: "per-section token estimates" are char counts, and one "char count" is a file count

**Severity:** Minor
**Location:** `scripts/cross-model-review.py:26-27` vs `:341-346`; `:125` vs `:174`
**Move:** #3 (documentation drift)
**Confidence:** High (per Stage-1 fact-check)

The module docstring promises `--dry-run` prints "per-section token estimates"; the actual output prints per-section **char** counts (`sibling diff {…} chars`), with a token estimate only for the whole prompt. `build_stage1_context`'s docstring says "stats maps section -> char count", but `stats["skipped_files"]` is a count of files. Downstream, `docs/working/stage1-context-cost-2026-07-31.md:32-49` correctly re-derives tokens via the stated ~4 chars/token heuristic and labels KB/token columns, so the doc chain is internally honest — the drift is confined to the script's self-description, but that is the surface a CLI consumer reads first.

**Recommendation:** Change the docstring to "per-section char counts and a total token estimate" and the stats docstring to "section -> char count (plus `skipped_files`: count)".

**Legibility-target:** for-author

#### 5. Stage-1 prompt declares "three kinds of section" but emits a fourth, undeclared kind

**Severity:** Minor
**Location:** `scripts/cross-model-review.py:78-84` (preamble) vs `:170-172` (skip-list section)
**Move:** #7 (asymmetry — the prompt is the consumer contract for the models)
**Confidence:** High

`PROMPT_TEMPLATE_STAGE1` tells the model "The material has three kinds of section" and enumerates UNDER REVIEW / ALREADY COMMITTED / CURRENT FILE CONTENTS. When files are skipped, the context also contains `=== FILES TOO LARGE TO INLINE … ===`, a fourth section shape the preamble never introduces. The template's own design note (`:66-68`) argues labelling is "a build requirement, not decoration" — by that standard an unenumerated section is a contract gap: the model receives material whose review status (context-only? under review?) it must guess. Low practical risk (the header text is self-explanatory), but it violates the template's own stated principle.

**Recommendation:** Either fold the skip list into the enumerated taxonomy (e.g., make it a `CURRENT FILE CONTENTS - CONTEXT ONLY (<path>): omitted (<reason>)` entry) or extend the preamble to name the fourth section kind.

**Legibility-target:** for-author

#### 6. `--analyze-only` pools records across context modes without stratifying or warning; `--dry-run` is silently ignored under `--analyze-only`

**Severity:** Minor
**Location:** `scripts/cross-model-review.py:311,422-431`
**Move:** #3 (consumer contract) / #6 (versioning of comparability)
**Confidence:** Medium

The record schema now distinguishes context mode (`context_base` null vs ref, plus a mode-dependent `prompt_sha`), and the docstring stakes comparability on that distinction ("historical numbers stay comparable", `:24-25`). But the analysis path keys records only by `(model, replicate)` (`:430`) and never reads `context_base` or groups by `prompt_sha` — so a findings.jsonl containing both a diff-only run and a stage1 run of the same range (same `--out` reused) is silently pooled into one overlap analysis, and later `(model, replicate)` records overwrite earlier ones in `by_key`. Old records lacking `context_base` are tolerated fine (nothing reads the key — good), but the tool that stamps the comparability metadata doesn't honor it when analyzing. Relatedly, `--dry-run --analyze-only` accepts both flags and ignores `--dry-run` without comment. Both are latent today (one out-dir per run in practice) but the schema invites exactly this misuse.

**Recommendation:** In the analysis pass, warn (or refuse) when records carry >1 distinct `prompt_sha`/`context_base`, and error on the `--dry-run --analyze-only` combination.

**Legibility-target:** for-orchestrator-synthesis

#### 7. `factcheck_replication` compresses a word its sibling keys would separate

**Severity:** Minor
**Location:** `scripts/self-improvement.sh:1519`
**Move:** #2 (naming)
**Confidence:** High

Precedent: fully-underscore-separated snake_case keys (`red_findings`, `rubric_red`, `rubric_sentinel_agree`) used in `scripts/self-improvement.sh:1517-1519` (same jq object) and other `record_gate_detail` payloads (`diff_size`, `file_scope`, `critical_files`).

The new gate-detail key runs "fact check" together as `factcheck` while every neighbor separates words with underscores; prose throughout the repo writes "fact-check". Anyone querying gate JSON by convention will guess `fact_check_replication` first.

**Recommendation:** Rename to `fact_check_replication` now, while this branch is the key's only producer and no consumer parses it yet.

**Legibility-target:** for-automated-gate

#### 8. `dd-cross-model-sweep.py` diverges from its sibling's CLI error surface and conventions

**Severity:** Minor
**Location:** `scripts/dd-cross-model-sweep.py:21-25`
**Move:** #1/#4 (baseline conventions, error consistency)
**Confidence:** High

The sibling harness fails cleanly (`sys.exit("OPENROUTER_API_KEY not set")`, `cross-model-review.py:313`), takes models via `--models`, and guards spend with `--max-usd`. The new script raises a bare `KeyError` traceback on a missing key and `IndexError` on missing positionals (`:22-24`), hardcodes `MODELS`, and has no cost guard. The docstring honestly declares the minimalism ("sends a single free-form prompt once per model … nothing more") and the script is primarily an archival record of how `runs/dd-cross-model-2026-07-30/` was produced, which caps this at Minor — but the error surface (traceback vs message) is the part future sweep-runners will actually hit, and it costs three lines to match the sibling.

**Recommendation:** Guard the env var and argv with the sibling's `sys.exit(...)` style; leave the deliberate minimalism (hardcoded models, no argparse) as documented.

**Legibility-target:** for-author

#### 9. `--max-inline-kb` measures decoded characters against a KB label

**Severity:** Informational
**Location:** `scripts/cross-model-review.py:163-169`
**Move:** #8-adjacent (unit contract)
**Confidence:** Medium

The threshold compares `len(content)` — Unicode characters of the decoded text — against `max_inline_kb * 1024`, and the skip list prints `{n // 1024} KB` from the same char count. "KB" implies bytes; for multibyte UTF-8 files the two diverge (a 70 KB file of non-ASCII text can pass a 64 "KB" cap). Since the cap exists to bound prompt size and pricing is per token (~chars), chars are arguably the *more* correct unit — the label is what's off, not the mechanism. The cost doc inherits these char-derived "KB" figures (`docs/working/stage1-context-cost-2026-07-31.md:36-46`) but consistently pairs them with token conversions, so no downstream number is misused.

**Recommendation:** No behavior change needed; note in the help text that the unit is "KB of decoded text (chars)" or rename mentally to a char cap if the flag is ever revised.

**Legibility-target:** for-author

## What Looks Good

- **Backward-compatible flag additions done right.** All three new flags are optional; omitting `--context-base` provably reproduces the pre-021 prompt byte-for-byte, so `prompt_sha` values remain comparable with historical runs and the diff-only sha is stable across this change. The relaxed validation messages (`:315-317`) were updated in lockstep with the relaxed requirements and are accurate for every flag combination I traced (`--dry-run` without key, without `--models`, `--analyze-only` without repo/range).
- **`context_base` added symmetrically to all three record shapes** (success `:409`, api-error `:377`, empty-content `:395`), and the analyze path's `.get()`-based reading means old records without the key parse unchanged.
- **Mode is legible in outputs**: `context mode: stage1(base=…)`/`diff-only` plus `prompt_sha` on stdout, and `context_base` in every record, make stage1 vs diff-only runs distinguishable after the fact.
- **The k=3 vocabulary is genuinely unified.** `**Replication:** k=3`, `k=2 (one replicate failed)`, `code-fact-check-report-r<N>.md`, most-severe-wins wording, and the severity ladder (`Incorrect (high) > … > Verified`) appear with identical spellings in SKILL.md, both bats suites, and Gate 1h's case arms; both suites pass (21/21) against the SKILL as written. Gate 1h's sed pattern matches the SKILL's bolded field exactly, and its short-SHA prefix match (`${CR_COMMIT#"$CR_FC_COMMIT"}`) handles both short and full SHAs in the report.
- **The merged report is format-compatible by construction**: keeping the five-header/five-field schema and adding `**Replicate verdicts:**` as a sixth field means the existing `code-fact-check-format.bats` gates the merged report unchanged.
- **`Contested-Soundness` extends, rather than collides with, the existing `Contested` vocabulary**, and the Soundness channel's tier semantics (lift-only, terminal 🟡, excluded from escalation) are restated consistently at all four sites that touch tier rules (channel section, advisory rule, escalation rule, Stage-3 cross-check).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Merged-report `Commit:` mandate split/omitted in merge spec; Gate 1h stale check no-ops without it | Inconsistent | `skills/code-review/SKILL.md:352-373`, `scripts/self-improvement.sh:1482-1500` | High |
| 2 | Binary files documented as "listed", actually crash (and mislabelled "too large" if listed) | Inconsistent | `scripts/cross-model-review.py:22-23,109,154-172` | Medium |
| 3 | Keyless dry-run prints `$0.00` projection then claims no projection | Minor | `scripts/cross-model-review.py:348,357-359` | High |
| 4 | "Per-section token estimates" are chars; "char count" stat is a file count | Minor | `scripts/cross-model-review.py:26-27,125,174` | High |
| 5 | Stage-1 prompt enumerates three section kinds, emits four | Minor | `scripts/cross-model-review.py:78-84,170-172` | High |
| 6 | `--analyze-only` ignores `context_base`/`prompt_sha` stratification; `--dry-run` silently ignored with it | Minor | `scripts/cross-model-review.py:311,422-431` | Medium |
| 7 | `factcheck_replication` vs word-separated sibling keys | Minor | `scripts/self-improvement.sh:1519` | High |
| 8 | Sweep script's KeyError/IndexError surface vs sibling's `sys.exit` convention | Minor | `scripts/dd-cross-model-sweep.py:21-25` | High |
| 9 | `--max-inline-kb` is a char cap wearing a KB label | Informational | `scripts/cross-model-review.py:163-169` | Medium |

## Overall Assessment

The change is strongly consistent where it matters most: the new CLI flags follow the harness's established naming and validation style, the diff-only path is provably byte-stable (preserving `prompt_sha` comparability), the record schema evolves additively and symmetrically, and the k=3/soundness-channel vocabulary is impressively uniform across SKILL prose, bats contracts, and the Gate 1h consumer — the bats suites pass against the SKILL as written. No Breaking findings: nothing here invalidates an existing consumer's code or data. The two Inconsistent findings are both producer-spec/consumer drift of the same shape — a surface's local self-description reading as complete while the real contract lives elsewhere (merge spec vs Gate 1h's `Commit:` dependence; docstring's graceful-skip promise vs the decode crash path) — and both are fixable in place with a sentence and a few lines respectively. The Minors are polish on brand-new surfaces with no consumers yet, which is exactly when renames and message fixes are free.

## Goal-Alignment Note

The PR's goal is to make the review pipeline's noisiest judgment (fact-check verdicts) measured rather than sampled, and to make degraded runs *visible* (Gate 1h) rather than silent. Finding 1 is the one item that bears directly on that goal: the visibility mechanism depends on a `Commit:` line the local merge spec does not require, so the exact silent-degradation class the PR targets can recur through the gap between producer spec and gate consumer. Findings 3-6 affect the decision-021 cost/dry-run instrumentation's self-description, not its measurements — the committed cost numbers remain trustworthy. Nothing in this review argues against the PR's design; the findings are alignment tightenings, not challenges to the mechanism. I did not review `runs/` artifacts or prior reports per scope, and I deferred to Stage-1 fact-check for behavior claims (binary crash, docstring drift) rather than re-deriving them.
