# Test Strategy: exp/cross-model-openrouter-sweep — Stage-1 context as review-quality default

Commit: fbd8597

**Scope:** `git diff main...HEAD` (10 files, +207/−7). Executable surface: `scripts/cross-model-review.py` (docstring + new stderr warning, lines 419–427 post-change). Contract surface: `skills/code-review/SKILL.md` Step 1 partial-scope labelling rule. Remainder is docs (`docs/decisions/021`, `docs/decisions/log.md`, `docs/thoughts/code-review-evaluation-state.md`, `docs/working/experiment-stage1-fp-kill-2026-07-31.md`) and raw experiment data (`runs/cross-model/s1-*/`).
**Reviewed:** 2026-07-31

## Test Conventions

- **Framework:** Bats 1.8.2. Suites live in `test/*.bats`; skill/prose-contract suites in `test/skills/*.bats`. Each file opens with a `# @category fast|slow` tag and a header comment explaining *why the suite exists* (usually: a defect that shipped because the surface was untested).
- **Python-facing tests:** invoked through the CLI via `run env ... "$SCRIPT" ...` (subprocess), or by loading the module with `importlib.util.spec_from_file_location` for pure functions (see `test/cross-model-review-stage1.bats:85` for `split_range`). No pytest in the repo.
- **Hermeticity:** keyless-by-default (`env -u OPENROUTER_API_KEY`), throwaway fixture git repo built in `setup_file()` under `$BATS_FILE_TMPDIR`, PATH shims for network-capable binaries in `setup()` (`test/round-log-functions.bats:24-27`). The one deliberately "live" test (`test/cross-model-review-stage1.bats:100`) uses a bogus key and relies on `fetch_pricing` swallowing the network failure → all models unpriced → cost guard exits. That pattern is the established handle for exercising the non-dry-run path without network.
- **Prose-contract enforcement:** `test/skills/code-review-assurance-contract.bats` is the repo's precedent that *a normative rule stated only in `SKILL.md` prose is treated as unenforced*. Its own header states the standing evidence: "an unenforced instruction does not execute." Assertions are `grep -qiE` over `$SKILL_CONTENT` and over extracted sections.
- **Stderr separation:** Bats 1.8.2 supports `run --separate-stderr` (`$stderr` / `$output`); no suite in this repo uses it yet, so a new test would be the first — the alternative, `2>"$file"` redirection, is equally acceptable and slightly more portable.
- **Existing suite for this file:** `test/cross-model-review-stage1.bats`, 8 tests, `@category fast`. Test 6 pins the diff-only prompt sha stability.

## Untested Paths Touched by the Change

- `scripts/cross-model-review.py:422-427` — live (non-dry-run) run with `--context-base` unset emits the diff-only WARNING at all — not covered
- `scripts/cross-model-review.py:417-427` — dry-run diff-only must *not* emit the warning (the `return` at :421 precedes it) — not covered
- `scripts/cross-model-review.py:422` — live run *with* `--context-base` must not emit the warning (negative arm of the `if not args.context_base` branch) — not covered
- `scripts/cross-model-review.py:425-427` — warning is written to `sys.stderr` only, keeping stdout's machine-readable lines (`context mode: …`, `prompt sha …`, `projected spend: …`) uncontaminated — not covered
- `scripts/cross-model-review.py:422-430` — ordering: the warning fires *before* the unpriced cost-guard `sys.exit`, so an aborted run still asserts "findings from this run must not be treated as review verdicts" for a run that produced no findings — not covered (existing test 8 asserts the guard text but, using plain `run`, cannot distinguish the two streams and does not assert warning presence/absence)
- `skills/code-review/SKILL.md:101` — the partial-scope labelling rule (out-of-scope sibling work labelled context-only; critics must check `git log main..HEAD` before flagging work "missing") exists only as prose, with no assertion that the rule is present or that its two mandated clauses (a) and (b) survive future edits — not covered
- `scripts/cross-model-review.py:20-22` and `skills/code-review/SKILL.md:101` — both new texts cite `docs/working/experiment-stage1-fp-kill-2026-07-31.md` as a backticked path, not a markdown link; `test/cross-reference-integrity.bats` only resolves `[text](path)` links under `workflows|skills|guides|patterns`, so neither citation is checked for existence — not covered
- `scripts/cross-model-review.py:354-356` — `--context-base` argparse help still reads "Omit for the historical diff-only prompt", neutral, while the docstring now declares it "the RECOMMENDED mode"; `--help` is the surface a user actually reads and no test pins the two in agreement — not covered

Numbering: G1 (live diff-only warning fires), G2 (dry-run silence), G3 (`--context-base` silence), G4 (stderr-only destination), G5 (warning/cost-guard ordering), G6 (SKILL.md partial-scope rule unenforced), G7 (cited doc path unchecked), G8 (`--help` vs docstring drift), in the order listed above.

## Recommended Tests

#### diff-only live run warns on stderr, and only on stderr

**Closes gaps:** G1, G4
**Type:** integration (CLI subprocess, keyless-equivalent via bogus key)
**Priority:** high
**File:** `test/cross-model-review-stage1.bats` (append; keep `@category fast`)
**What it verifies:** A non-dry-run invocation without `--context-base` prints the decision-021 misattribution warning to stderr and nothing of it to stdout.
**Key cases:**
- `env OPENROUTER_API_KEY=sk-or-bogus-offline "$SCRIPT" --repo "$FIX" --range "$LEFT..$RIGHT" --models fake/model --replicates 1 --out …` with `run --separate-stderr` → `$stderr` matches `WARNING: diff-only mode is a recall probe`; `$stderr` mentions `--context-base` as the fix.
- Same invocation → `$output` (stdout) does **not** contain `WARNING`; stdout still carries `context mode: diff-only`.
**Setup needed:** None beyond the existing `setup_file()` fixture repo. Mirrors the bogus-key pattern already used by test 8 — no network reached (pricing fetch fails, is swallowed).
**Legibility-target:** for-author

#### the warning is absent in dry-run and in --context-base mode

**Closes gaps:** G2, G3
**Type:** integration (CLI subprocess)
**Priority:** high
**File:** `test/cross-model-review-stage1.bats` (append)
**What it verifies:** The warning is scoped to live diff-only runs only — the two negative arms.
**Key cases:**
- Existing `run_dry` (dry-run, `--context-base main`) → neither stream contains `WARNING`.
- Dry-run **without** `--context-base` (the invocation from test 6) → neither stream contains `WARNING` (guards the `return` at :421 staying above the warning; if someone reorders, dry-run prompt-building sessions start emitting scary text).
- Live run **with** `--context-base main` and the bogus key → `$stderr` contains no `WARNING`; exit status non-zero with the cost-guard text (proving we reached past :422).
**Setup needed:** None; reuse `run_dry` and the bogus-key form.
**Legibility-task note:** the second case can be folded into test 6 rather than added as a new test, if the author prefers fewer subprocess spawns.
**Legibility-target:** for-author

#### SKILL.md states the partial-scope labelling contract

**Closes gaps:** G6
**Type:** contract/prose assertion (bats grep over SKILL.md)
**Priority:** high
**File:** `test/skills/code-review-assurance-contract.bats` (add a third contract section, matching the file's existing §1.3/§1.4 structure) — or a sibling `test/skills/code-review-scope-label-contract.bats` if the author prefers one contract per file.
**What it verifies:** The Step-1 rule survives edits, with both of its mandated clauses intact.
**Key cases:**
- `$SKILL_CONTENT` matches `Partial-scope reviews must label out-of-scope sibling work` (or a looser `partial.scope.*label` regex if the heading wording is expected to churn).
- The rule's paragraph mentions the scope triggers: `--range`, `--staged`, `--files`.
- It mentions the context-only label wording (`already committed`, `not under review`).
- It mentions the check-before-flagging obligation (`missing` plus `git log main..HEAD` or `git diff main...HEAD`).
- It states the exemption: full-branch scope needs no label.
**Setup needed:** Reuse `setup()` from `code-review-assurance-contract.bats` (`SKILL="$REPO_ROOT/skills/code-review/SKILL.md"`, `[ -f "$SKILL" ] || skip`).
**Legibility-target:** for-author

#### cited experiment-doc paths resolve

**Closes gaps:** G7
**Type:** integration (repo-invariant assertion)
**Priority:** medium
**File:** `test/cross-reference-integrity.bats` (extend) — add a check for backticked `docs/**.md` paths, or, if that is too broad a sweep to land here, a narrow assertion in `test/cross-model-review-stage1.bats` that the path named in the script docstring exists.
**What it verifies:** The validation evidence both the docstring and the SKILL.md rule lean on is actually in the tree; a rename or archival move doesn't silently orphan the justification for a normative rule.
**Key cases:**
- Every `` `docs/(working|decisions|thoughts)/...md` `` occurrence in `scripts/cross-model-review.py` and `skills/code-review/SKILL.md` resolves to an existing file.
- Negative: a deliberately bogus path in a fixture string is reported (only if the check is implemented as a reusable helper).
**Setup needed:** None. Note the archival risk: `scripts/archive-working-docs.bats` exists, so `docs/working/` files may be *designed* to move — if so, scope the check to `docs/decisions/` and `docs/thoughts/` and skip `docs/working/`, or the test becomes a time bomb. Confirm before implementing.
**Legibility-target:** for-orchestrator-synthesis

#### --help agrees with the docstring on the recommended mode

**Closes gaps:** G8
**Type:** integration (CLI `--help` subprocess)
**Priority:** low
**File:** `test/cross-model-review-stage1.bats`
**What it verifies:** `--context-base`'s help text tells a user it is the recommended review-quality mode, so the recommendation isn't only visible to someone reading the source.
**Key cases:**
- `"$SCRIPT" --help` → the `--context-base` help mentions `recommended` (case-insensitive), and the diff-only phrasing carries the recall-probe caveat rather than the neutral "Omit for the historical diff-only prompt".
**Setup needed:** None.
**Author note:** this test should be written *after* the help string is updated — as of fbd8597 it would fail. If the author judges the docstring sufficient, move G8 to What NOT to Test with that rationale.
**Legibility-target:** for-author

## What NOT to Test

- **G5 (warning-before-cost-guard ordering) as a behavioral assertion.** The fact-check flagged that a live diff-only run aborting at the unpriced-model guard still prints "Findings from this run must not be treated as review verdicts" for a run with no findings. It is cosmetic: the run exits non-zero, produces no `findings.jsonl` rows, and no consumer parses stderr. Writing a test that *pins* the current ordering would freeze a wart; writing one that pins the corrected ordering presumes a fix nobody has decided to make. Recommendation: leave untested, and if the author moves the warning below the two `sys.exit` guards (a two-line move), the G1 test above continues to pass unchanged because the bogus-key run's guard exit happens *after* the warning either way — so re-verify the G1 test still reaches the warning if the move is made.
- **The docs-only files** (`docs/decisions/021`, `log.md`, `docs/thoughts/…`, `docs/working/experiment-…`). Prose describing a completed experiment; no executable claim beyond the path-existence check already covered by G7.
- **`runs/cross-model/s1-*/findings.jsonl` and `overlap.json`.** These are immutable raw experiment records. A schema test over them would pin the *analysis* format, which `--analyze-only` already re-derives; a snapshot test over recorded model output tests nothing about this repo.
- **The prompt-sha stability of the diff-only prompt.** Already covered by existing test 6 (`968d268b1689` byte-identical), and the fact-check independently confirmed it. Do not add a second assertion.
- **Whether the warning's *claim* is true** (that diff-only manufactures FPs). That's an empirical result from the D3/D4 re-run, validated at n=8; a unit test cannot re-derive it and should not pretend to.

## Coverage Gaps Beyond Current Scope

**1. The whole non-dry-run path of `scripts/cross-model-review.py` (lines 434–500) is exercised by exactly one test, and only up to the cost guard.** Per-model error isolation (`except Exception` → error row, sweep continues), the empty-`content` reasoning-model handling (`finish_reason` capture), and `parse_findings` are all untested. `parse_findings` in particular is a pure function and is trivially testable via the `importlib` pattern already used for `split_range`. The binary-crash class that motivated this suite's creation lived in exactly this kind of untested-parser territory.

**2. Prose contracts in `skills/code-review/SKILL.md` are enforced selectively.** Two contracts (§1.3, §1.4) have a bats suite; the new partial-scope rule (and, judging by the file, several older Step-1 instructions) do not. Without a convention that *every* normatively-worded Step rule gets an assertion, the enforcement suite drifts from a contract into a sample. Worth a decision-log row on where the line sits.

## Summary

The single highest-value test is the pair covering G1–G4: one live-arm assertion that the diff-only warning fires on stderr, plus its two negative arms (dry-run, `--context-base`). Together they cost roughly fifteen lines in an existing suite, reuse the bogus-key hermeticity pattern already proven by test 8, and close the only genuinely new executable behavior in the diff — which is currently at zero coverage, including its stderr-only destination, the property that keeps the script's stdout machine-parseable. The second priority is G6: this repo has already concluded, in writing, that an unenforced `SKILL.md` instruction does not execute, and the new partial-scope labelling rule is the most consequential thing in this diff — it is the mechanism by which the validated experiment result actually changes reviewer behavior, and it currently has no assertion behind it. Residual risk after these tests: the ordering wart (G5) stays unpinned by choice, and the empirical claim behind the warning remains backed by the n=8 experiment rather than by any test. Open question for the author: is `--help` supposed to carry the recommendation (G8)? If yes, that's a source fix plus a one-line test; if no, say so in the docstring so the divergence reads as deliberate.

## Goal-Alignment Note
- Answered: yes — concrete gap list and prioritized test plan for the fbd8597 diff
- Out of scope: whether the D3/D4 experiment's n=8 result justifies the default change (empirical, not testable here); the ordering wart's fix decision, deliberately left to the author
- Escalate: G6 — the partial-scope labelling rule is the diff's behavior-changing artifact and has no enforcement, in a repo whose own test headers argue unenforced prose does not execute
- Questions I would have asked: are `docs/working/` files subject to archival relocation (`scripts/archive-working-docs.bats`)? The answer decides whether the G7 path-existence check is durable or a time bomb.
