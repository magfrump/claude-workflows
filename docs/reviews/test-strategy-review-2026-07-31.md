# Test Strategy: exp/cross-model-openrouter-sweep

Commit: 62594fb
**Scope:** `git diff main...HEAD` — `scripts/cross-model-review.py` (split_range, build_stage1_context, --dry-run), `scripts/dd-cross-model-sweep.py`, `scripts/self-improvement.sh` Gate 1h replication hunk, `skills/code-review/SKILL.md` + `test/skills/code-review-factcheck-replication.bats` + `test/skills/code-review-soundness-crosscheck.bats`
**Reviewed:** 2026-07-31
**Reviewer:** test-strategy critic (advisory — 🟢 Consider tier unless lifted by an evidence-gated channel)

## Test Conventions

- **Shell**: bats under `test/` and `test/scripts/`; the Gate-1h idiom is to extract logic into `scripts/lib/si-functions.sh` and unit-test the extracted function (`test/code-review-gate.bats` for `parse_code_review_red` / `code_review_gate_verdict`; same pattern backs Gate 1e via `test-baseline-gate.bats`). Hermeticity helpers in `test/lib/hermetic-env.bash`; network-capable binaries are PATH-shimmed (`test/round-log-functions.bats`).
- **Prose contracts**: bats files grepping SKILL.md sections (`test/skills/*-format.bats`, `code-review-assurance-contract.bats`), usually section-scoped via `sed -n '/heading/,/next-heading/p'`.
- **Python**: **no harness exists.** `pytest` is not installed; no `test/**/*.py`. `scripts/claude_config_audit.py` is likewise untested. Any Python recommendation below must either shell out from bats (`python3 -c` + `importlib.util.spec_from_file_location`, needed because `cross-model-review.py` has a hyphenated, un-importable name) or use stdlib `unittest` driven from a bats wrapper so `scripts/run-tests.sh` picks it up. Do **not** propose pytest without a separate decision — it would be the repo's first Python dev-dependency.

## Untested Paths Touched by the Change

- **G1** — `scripts/cross-model-review.py:154-161` — committed **binary file** at `right`: `sh()` runs with `text=True`, so decoding raises `UnicodeDecodeError` *before* the `"\x00" in content[:8192]` guard at line 160 ever runs; the `except subprocess.CalledProcessError` at 155 does not catch it — not covered (Stage-1 fact-check empirically reproduced the crash; the binary-skip branch at 160-162 is dead code for real binary blobs)
- **G2** — `scripts/cross-model-review.py:114-119` — `split_range` three-dot semantics: for `a...b`, `left=a`, but `git diff a...b` starts at `merge-base(a,b)`, so the sibling section (`context_base...a`, line 138) and the reviewed diff can overlap or leave a gap; also `right` defaults to `"HEAD"` for `a..` while `git diff a..` diffs the *worktree* — the inlined file contents (`git show HEAD:path`, line 154) can disagree with the reviewed diff — not covered
- **G3** — `scripts/cross-model-review.py:144-147` — empty-sibling-diff arm (the `(none: no sibling commits …)` placeholder) — not covered
- **G4** — `scripts/cross-model-review.py:155-159` — deleted/renamed-file arm (`CalledProcessError` → "file does not exist at {right}" note) — not covered
- **G5** — `scripts/cross-model-review.py:163-172` — oversize-file skip arm (`> max_inline_kb` → skipped list + "FILES TOO LARGE TO INLINE" section) — not covered
- **G6** — `scripts/cross-model-review.py:217-238` — `parse_findings`: `FINDINGS: NONE` short-circuit, malformed finding line rejected, missing `:<lines>` (→ `line_start=None`), the `parse_ok` return — not covered
- **G7** — `scripts/cross-model-review.py:241-250` — `stage1_candidates`: basename mismatch, `line_start is None` pass-through-to-judge, exact-slack boundary (`line_end + slack == line_start`) — not covered
- **G8** — `scripts/cross-model-review.py:441-459` — degraded stage-1-only greedy one-to-one matching: the comment at 448-450 documents a fixed Jaccard>1 bug (multiple `fa` claiming one `fb`); no regression test pins `J ≤ 1` — not covered
- **G9** — `scripts/cross-model-review.py:354-360` — `--dry-run` end-to-end: prompt.txt written, function returns before any `api()` call, works with `OPENROUTER_API_KEY` unset — not covered
- **G10** — `scripts/cross-model-review.py:311-317` — argument-validation arms (dry-run without `--models` allowed; missing `--repo`/`--range` exits; missing key exits only when not dry-run) — not covered
- **G11** — `scripts/self-improvement.sh:1487-1512` — the entire new Gate 1h replication hunk: the `**Replication:**` / `Commit:` sed extraction (1492-1493), the prefix-based stale test (1495), and all four `case` arms (`k=3*`, `stale`, `""`, `*`) — inline in the gate loop, **not** extracted to `si-functions.sh`, so unlike its siblings (`parse_code_review_red`, tested in `test/code-review-gate.bats:31-60`) it has zero bats coverage
- **G12** — `scripts/self-improvement.sh:1493-1495` — format-coupling fail-open: if the merged report writes `**Commit:**` (bolded, per the style of every other header field) instead of bare `Commit:`, `CR_FC_COMMIT` is empty, the stale check is silently skipped, and a stale report's `Replication: k=3` is trusted — not covered on either side (no bats pins the SKILL's `Commit:` spelling either; see G14)
- **G13** — `test/skills/code-review-factcheck-replication.bats:97-102` — the "Confirmed-Good cross-check scans the per-replicate reports" test greps **SKILL_CONTENT globally** for `code-fact-check-report-r\*\.md`, but that string also appears in the Stale-replicate guard (SKILL.md:298) and the Output Locations tree region — mutating out the Confirmed-Good amendment (SKILL.md:993-999) leaves this test **passing**; it does not pin the contract it claims to pin
- **G14** — `test/skills/code-review-factcheck-replication.bats` (whole file) — no assertion pins the `**Replication:** k=3` header field (SKILL.md:371-373) or the `Commit: <current HEAD short SHA>` line (SKILL.md:292) — the two exact strings Gate 1h parses at `self-improvement.sh:1492-1493`. Renaming either in SKILL.md passes the full suite while permanently degrading Gate 1h's check to its "missing field" arm — the cross-artifact contract is unpinned
- **G15** — `test/skills/code-review-factcheck-replication.bats:87-95` — weak anchors: the falsifier test pins the numbers (`90%.*20`) but not the consequence ("k can drop to 2"); the checkpoint test pins the phrase "at least **two** substantive" but not the blocking consequence ("tell the user and ask how to proceed") — a mutation keeping the phrase and inverting the behavior passes
- **G16** — `test/skills/code-review-factcheck-replication.bats:104-117` — the step-3b brief test anchors existence, the claims list, the exercising-code directive, and the uniformity clarification, but **not** "include it verbatim in all three prompts" (SKILL.md:285-286) — the MD1-R1 regression this branch diagnosed was precisely orchestrators dropping the brief from the dispatched prompts, and the shared-verbatim clause is the un-anchored half

Spot-check credit where due: `code-review-soundness-crosscheck.bats` is well built — every assertion is section-scoped via `channel()`, the fixed vocabulary (`Severity: Contested-Soundness`, `Source: … (found by <critic>)`), the negative controls (`sim.ts:625-628` / `proxy.ts:14`), terminality, and the escalation exclusion are each pinned by a grep that fails if that exact clause is removed (mentally mutated: deleting the "Lift only, never demote" clause fails test 21; deleting the convention-exclusion sentence fails test 2). The replication suite is good on the merge core (severity order at :69-73 would fail on any reorder) but has the anchoring holes in G13-G16.

## Recommended Tests

#### T1 — build_stage1_context on a fixture repo (binary, oversize, deleted, sibling)

**Closes gaps:** G1, G3, G4, G5
**Type:** integration (fixture git repo)
**Priority:** high
**File:** `test/scripts/cross-model-review-context.bats` (new; follows `test/scripts/*.bats` + `fixture-hermeticity` conventions — build the repo in `$BATS_TEST_TMPDIR` with `git -c user.email=… commit`, load `lib/hermetic-env`)
**What it verifies:** each `build_stage1_context` arm produces its labelled section instead of crashing or silently omitting.
**Key cases:**
- Repo with base commit → sibling commit → reviewed commit; range `<sib>..<head>`, `--context-base <base>`: output contains `ALREADY COMMITTED - CONTEXT ONLY` with the sibling hunk, and `CURRENT FILE CONTENTS - CONTEXT ONLY (<file> at <head>)`.
- Reviewed commit adds a **binary blob** (`printf '\x00\x01…' > img.bin`): expect the file in the skipped list with reason `binary` — **this test fails today** (UnicodeDecodeError, G1); land it alongside the fix (`sh(..., text=False)` + decode with `errors=` handling, or catch `UnicodeDecodeError` at :155), or commit it first as the reproduction per debugging default 1.
- Reviewed commit deletes a file: expect the "file does not exist at {right}" note, no exception.
- File larger than `--max-inline-kb 1`: expect it in `FILES TOO LARGE TO INLINE`, `skipped_files` stat = 1, content not inlined.
- No sibling commits (`--context-base` == range left): expect the `(none: no sibling commits …)` placeholder.

**Setup needed:** helper that loads the hyphen-named module: `python3 -c 'import importlib.util,sys; spec=importlib.util.spec_from_file_location("cmr", sys.argv[1]); …'` — put it in a small `test/scripts/lib/pyload.bash` (or inline) so T3/T4 reuse it. No network, no key.

#### T2 — --dry-run end-to-end asserts no network and a well-formed prompt

**Closes gaps:** G9, G10
**Type:** e2e (subprocess, hermetic)
**Priority:** high
**File:** same bats file as T1
**What it verifies:** the dry-run path is safe to run keyless and produces the artifact the mode exists for.
**Key cases:**
- `env -u OPENROUTER_API_KEY python3 scripts/cross-model-review.py --repo <fixture> --range a..b --context-base <base> --dry-run --out $BATS_TEST_TMPDIR/out` → exit 0; `prompt.txt` exists and contains `=== UNDER REVIEW`, `=== ALREADY COMMITTED`, and the diff hunk; stdout contains `no calls made`.
- Same without `--models`: still exit 0 (dry-run exempts the `--models` requirement, :316-317).
- Non-dry-run without key: exit ≠ 0 with `OPENROUTER_API_KEY not set` (:312-313).
- Network hermeticity: with the key unset, `fetch_pricing` is skipped (:333) and `main` returns at :360 — belt-and-braces, add the repo's PATH-shim/hermetic-env so an accidental future `urllib` call in the dry path fails loudly rather than escaping.

**Setup needed:** fixture repo from T1.

#### T3 — split_range unit table incl. three-dot boundary semantics

**Closes gaps:** G2
**Type:** unit + one semantic pin
**Priority:** high
**File:** same bats file (python one-liners)
**What it verifies:** the tuple contract, and — the part no unit assert can fake — what the three-dot form actually feeds `build_stage1_context`.
**Key cases:**
- `'a..b'`→`('a','b')`; `'a...b'`→`('a','b')`; `'a..'`→`('a','HEAD')`; `'abc'`→`('abc','HEAD')`; whitespace `' a .. b '` trimmed.
- Semantic pin on the fixture repo: for range `<branchA>...<head>` where `<branchA>` is ahead of the merge-base, assert (and thereby *document*) whether hunks in the sibling section also appear in the UNDER REVIEW diff. Today they can — the sibling boundary is `left`, not `merge-base(left,right)`. If overlap is intended ("context may repeat review"), the test freezes that; if not, it is the failing reproduction for the fix (`git merge-base` before building the sibling diff).

**Setup needed:** none beyond T1.

#### T4 — parse_findings / stage1_candidates / degraded-Jaccard pure-function units

**Closes gaps:** G6, G7, G8
**Type:** unit
**Priority:** medium
**File:** same bats file
**What it verifies:** the deterministic analysis layer every sweep's numbers flow through.
**Key cases:**
- `parse_findings("FINDINGS: NONE")` → `([], True)`; a well-formed row parses path/sev/lines; a garbage line inside the block is dropped; text with no `FINDINGS:` at all → `parse_ok` False; row without `:<lines>` → `line_start is None`.
- `stage1_candidates`: same basename + ranges exactly `slack` apart → True; `slack+1` apart → False; `line_start=None` on either side → True.
- **Jaccard ≤ 1 regression** (pins the fixed bug at :448-450): `fa` = 3 findings all overlapping one `fb` finding, no key (degraded mode) → J = 1/3, never > 1. Drive via a `findings.jsonl` fixture + `--analyze-only` with key unset, so the whole analysis block (:421-459) is exercised as shipped.

**Setup needed:** hand-written `findings.jsonl` fixture (also covers the errored-run exclusion at :425-429 for free — include one `"error"` row and assert it's excluded).

#### T5 — extract and unit-test the Gate 1h replication parser

**Closes gaps:** G11, G12
**Type:** unit (bats, per the Gate-1h sibling idiom)
**Priority:** high
**File:** extend `test/code-review-gate.bats`; move the logic at `self-improvement.sh:1490-1495` into `scripts/lib/si-functions.sh` (e.g. `parse_factcheck_replication <report-path> <reviewed-commit>` → prints `k=3…` / `stale` / empty), leaving only the `case` echo-arms inline — exactly how `parse_code_review_red` backs the same gate today
**What it verifies:** the advisory check reads the field it thinks it reads and fails closed on stale reports.
**Key cases:**
- Report with `**Replication:** k=3` + matching `Commit:` short-SHA prefix of the full reviewed SHA → `k=3`.
- `**Replication:** k=2 (one replicate failed)` → passed through (degraded arm).
- Field absent → empty (missing arm).
- `Commit:` mismatching → `stale` even when the field says k=3.
- **Bolded `**Commit:**` line** → currently yields empty `CR_FC_COMMIT` and skips the stale check (G12): assert the chosen contract explicitly — either the parser also accepts the bolded form, or the test documents bare-`Commit:` as canonical *and* T6 pins that spelling in SKILL.md so the two artifacts can't drift apart silently.
- Unreadable/missing report file → empty, no error output.

**Setup needed:** temp report files in `$BATS_TEST_TMPDIR`; `source scripts/lib/si-functions.sh` as `code-review-gate.bats:23` already does.

#### T6 — tighten the replication prose-contract suite

**Closes gaps:** G13, G14, G16
**Type:** contract (bats grep, section-scoped)
**Priority:** medium
**File:** `test/skills/code-review-factcheck-replication.bats`
**What it verifies:** the assertions fail on the regressions they claim to pin.
**Key cases:**
- Rescope the Confirmed-Good test (:97-102) to the Confirmed-Good section (`sed -n '/^### Confirmed Good is a claim/,/^### Unified Severity Mapping/p'`) so deleting the amendment at SKILL.md:993-999 actually fails it.
- Add: Stage 1 requires the `**Replication:** k=3` header field and the `Commit: <current HEAD short SHA>` line — bare-`Commit:` spelling asserted, cross-referencing T5's parser contract.
- Add: the Stale-replicate guard exists (`grep -q 'Stale-replicate guard'` within Stage 1) and mandates matching by `Commit:`, never glob alone (SKILL.md:301-302).
- Add: the brief is included **verbatim in all three prompts** (SKILL.md:285-286) — the un-anchored half of the MD1-R1 regression.

**Setup needed:** none.

#### T7 — strengthen the two weak anchors

**Closes gaps:** G15
**Type:** contract
**Priority:** low
**File:** `test/skills/code-review-factcheck-replication.bats:87-95`
**What it verifies:** consequences, not just phrases: extend the falsifier grep to require `k can drop to 2` in the same flattened span; extend the checkpoint test to require `ask how to proceed` (the single-replicate stop) and `k=2 \(one replicate failed\)` (the two-replicate degraded record).
**Setup needed:** none.

## What NOT to Test

- **`scripts/dd-cross-model-sweep.py` (all 71 lines)** — one-shot archival runner whose output (`runs/dd-cross-model-2026-07-30/`) is already committed; it is ~entirely network I/O with hardcoded models, so any test would mock everything the script does. Its one sharp edge — `KEY = os.environ["OPENROUTER_API_KEY"]` at :22 raising a bare `KeyError` at import — is worth a one-line `os.environ.get` + `sys.exit` fix, not a test. If it is ever re-run for a new sweep, promote it then.
- **`api()` retry/backoff and `fetch_pricing`** (`cross-model-review.py:178-214`) — network boundary; the dry-run and analyze-only tests (T2, T4) already prove the offline paths never reach them, which is the property that matters in this repo's hermetic test environment.
- **`judge_same` / keyed `jaccard`** (`:253-284`) — requires a live judge model; the deterministic pre-filter and the degraded path (T4) cover the logic that is testable without spend. The judge's stability is an experiment-design question tracked in the state doc, not a unit-test target.
- **The full Gate 1h loop end-to-end** — `self-improvement-smoke.bats` covers main-flow smoke; per the repo's own idiom the leverage is in the extracted parser (T5), not in driving the 1500-line orchestrator.

## Coverage Gaps Beyond Current Scope

**1.** The repo now has three Python scripts (`claude_config_audit.py`, `cross-model-review.py`, `dd-cross-model-sweep.py`) and no Python test convention. T1-T4 establish a bats-driven pattern; if Python surface keeps growing, a small decision record choosing bats-driven `python3` vs stdlib `unittest` vs pytest would prevent three ad-hoc idioms. (Legibility-target: for-author.)
**2.** `code-fact-check-format.bats` gates the *merged* report's schema, but nothing validates the per-replicate reports (`-r*.md`) against the same schema even though the Confirmed-Good cross-check now reads them as evidence (SKILL.md:993-999). A malformed replicate silently weakens that cross-check. (Legibility-target: for-orchestrator-synthesis.)
**3.** `prompt_sha` (`cross-model-review.py:330`) is the comparability key across historical runs ("Without --context-base the prompt is byte-identical to the pre-021 harness", :24-25) — a golden test freezing the diff-only prompt bytes for a fixed fixture diff would catch any accidental template edit that silently invalidates cross-run comparisons. (Legibility-target: for-author.)

## Findings (severity-tagged, for the rubric)

- **High** — `scripts/cross-model-review.py:154-161` — binary-file crash (G1) has no test; the fix and its reproduction test should land together. **Legibility-target:** for-author
- **High** — `scripts/self-improvement.sh:1487-1512` — Gate 1h's new arms break the gate's own extract-and-test idiom; parser untested, `**Commit:**` fail-open (G11, G12). **Legibility-target:** for-automated-gate
- **High** — `test/skills/code-review-factcheck-replication.bats` — the `**Replication:**`/`Commit:` strings Gate 1h parses are pinned by no test on either artifact (G14); the Confirmed-Good assertion false-passes under mutation (G13). **Legibility-target:** for-automated-gate
- **Medium** — `scripts/cross-model-review.py:114-119,138` — three-dot sibling-boundary semantics undocumented and untested (G2). **Legibility-target:** for-author
- **Medium** — `scripts/cross-model-review.py:441-459` — fixed Jaccard>1 bug unpinned by a regression test (G8). **Legibility-target:** for-author
- **Low** — `test/skills/code-review-factcheck-replication.bats:87-95,104-117` — phrase-anchors without consequence-anchors; brief-verbatim clause un-anchored (G15, G16). **Legibility-target:** for-orchestrator-synthesis

## Summary

The highest-value single test is T1's binary-blob case: it reproduces a confirmed crash in the exact code path (`build_stage1_context`) this branch exists to add, and lands the bats+fixture-repo pattern that T2-T4 then reuse cheaply. The second-highest is T5: Gate 1h's replication check is the one place where a SKILL.md prose contract and a shell parser must agree on two literal strings, and today no test on either side pins them. Residual risk after the plan: the keyed judge path and true cross-model behavior remain untested by design (network + spend), so sweep-level correctness still rests on the analyze-only determinism tests plus manual inspection of run artifacts. Open question surfaced by the enumeration: whether three-dot sibling overlap with the reviewed diff is intended behavior or a boundary bug — T3's semantic pin forces that decision either way.

## Goal-Alignment Note

The PR's stated goals are context enrichment (021), replicated fact-check with Gate 1h visibility, and the soundness channel (028). The recommendations above are aligned rather than orthogonal: the untested surface *is* the new mechanism — build_stage1_context's arms are the 021 deliverable, the Replication/Commit strings are the k=3 deliverable's coupling to the gate, and the two new bats files are the branch's own chosen enforcement instrument for its prose contracts (the branch itself diagnosed an untested prose contract as the k=3 dispatch regression's root cause — G13/G14/G16 show the new suites partially repeat that pattern). Nothing recommended expands scope beyond what the diff introduced; the soundness-channel suite needs no additions. As a contextual critic these findings are advisory (🟢) unless an evidence-gated channel lifts them; none of them self-qualifies for the Soundness-Contradiction Channel (they are coverage gaps, not behavioural inversions of a quoted intent).
