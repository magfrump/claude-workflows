# Test Strategy: code-review 032 #3/#4 calibration

**Scope:** `HEAD~3..HEAD` (de9ccf7, 45fa1df, 2f5ad0b)
**Commit:** 2f5ad0b
**Reviewed:** 2026-08-07

Files under review: `skills/code-review/SKILL.md`, `docs/decisions/032-review-loop-token-reduction-levers.md`,
`docs/decisions/log.md`, and new run artifacts under `runs/review-arms/baseline-2026-08-06/`.
`git diff HEAD~3..HEAD -- test/` is empty: **the change shipped with zero test changes.**

Everything outside this range is *already committed — context only, not under review*. Existing
suites were checked before anything below was called a gap.

---

## Test Conventions

**Framework.** bats-core. Suites live in `test/*.bats` (repo-level / script contracts) and
`test/skills/*.bats` (skill-document contracts). Each carries a `# @category fast` marker and a
header comment explaining *which contract and which measured failure* motivates the suite.

**The dominant pattern for docs-as-code contracts** (`test/skills/code-review-assurance-contract.bats`,
`code-review-soundness-crosscheck.bats`, `code-review-factcheck-replication.bats`): read the SKILL
into a variable, extract a named section with `sed`, grep-assert on it.

```bash
setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  SKILL="$REPO_ROOT/skills/code-review/SKILL.md"
  [ -f "$SKILL" ] || skip "code-review SKILL.md not found at $SKILL"
  SKILL_CONTENT=$(tr -d '\r' < "$SKILL")
}
fail() { echo "$1" >&2; return 1; }
subsection() { echo "$SKILL_CONTENT" | sed -n "/^#\+ .*$1/,/^### /p" | sed '$d'; }
```

**Golden-fixture pattern.** `test/skills/code-review/rubric-current-format.md` is the rubric format
spec in executable form; `code-review-format-contract.bats` asserts the fixture's table headers and
`## ` headings are byte-equal to the fenced template extracted from SKILL.md (`skill_template()` +
`table_headers()` awk pair). This covers the **rubric template only** — not pipeline prose.

**Cross-artifact drift-guard pattern.** `test/sandbox-tool-map-drift.bats` is the precedent for
"a claim in doc A must still be true of artifact B": the doc carries machine-readable marker lines
(`allow-prefix: X`), the test resolves each against the live artifact, and it `skip`s rather than
fails when the second artifact is unavailable. This is the pattern to reuse for SKILL-vs-measurement
numeric claims.

**Parser/format coupling.** `test/code-review-gate.bats:146-150` runs the real `count_rubric_red`
parser against the golden fixture — the one place the emitted format and the consuming parser are
checked against each other. Naming: `test/skills/code-review-<contract-name>.bats`. No mocking
infrastructure is needed for document contracts; PATH-shim stubbing
(`test/round-log-functions.bats`) applies only to suites that could invoke network binaries, which
none of the recommendations below do.

**Baseline at HEAD.** `code-review-gate.bats` 19/19 and `code-review-format-contract.bats` 17/17
green — and neither suite reads a single line of the prose this change touched.

---

## Untested Paths Touched by the Change

- **G1** — `skills/code-review/SKILL.md:99` vs `:340-344`, `:634`, `:1406` — the new conditional
  diff-inlining contract is asserted in two places and flatly contradicted in three un-updated
  dispatch instructions; nothing checks the four for agreement — **not covered**

  **Evidence** (`:99`, new):
  > Diff delivery to agents is conditional (decision 032 #3, see [Inline shared-context prefix](#inline-shared-context-prefix-decision-032-3)): for a normal-sized diff, inline it once as the shared cacheable prefix of every agent prompt

  **Evidence** (`:634`, unchanged Stage-2 dispatch step 3):
  > 3. Include the scope specification so the agent runs its own `git diff`. If the scope is

  **Evidence** (`:1406`, unchanged Important Reminders):
  > - **Pass scope, not diffs.** Each agent runs its own `git diff` to avoid context budget issues.

  **Evidence** (`:340`, unchanged Stage-1 replicate dispatch step 3):
  > 3. Include the scope specification (e.g., "Review files changed on the current branch relative

- **G2** — `skills/code-review/SKILL.md:99` and `:261-266` — the "do **not** inline" arm cites a
  single "~1000-line / >40%-churn threshold", but `:116` defines the churn ratio as an explicitly
  *size-independent, per-file* greenfield-review rule, not a diff-size gate; no test checks that the
  cited threshold exists or that the citation matches the rule it names — **not covered**

  **Evidence** (`:263`, new):
  > threshold (the ~1000-line / >40%-churn triage in Step 1) **or** the assembled shared block would be

  **Evidence** (`:116`, pre-existing, contradicts the framing):
  > Separately from total diff size, watch the per-file churn ratio. When any single file in the diff has more than 40% of its lines changed … treat that file's review as greenfield

  Note the arm asymmetry: a 40-line diff whose single file is 90% rewritten satisfies `:263`'s
  literal text and would suppress inlining, which is the opposite of the size-guard's stated intent
  ("for a large diff the window, not the bill, is the binding constraint", `:261-262`).

- **G3** — `skills/code-review/SKILL.md:246-255` — the six-part **fixed order** of the shared block,
  with the fact-check summary pinned last; the ordering is what makes the cache-stability rule at
  `:271-275` true, and no test asserts the parts are present, numbered 1–6, or that part 6 is last
  — **not covered**

  **Evidence** (`:243-244`):
  > order (omit a part only when it does not apply, but keep the order so the cached prefix stays
  > stable):

  **Evidence** (`:273-275`):
  > pass and therefore sits **last**, so whatever prefix is unchanged remains a cacheable common
  > prefix.

- **G4** — `skills/code-review/SKILL.md:265` — new required orchestrator output ("state which mode
  you used"), with no slot in the rubric template, no entry in the golden fixture, and no defined
  "plan summary" schema anywhere in the skill — **not covered**

  **Evidence** (`:264-265`):
  > `git diff` and read what it needs. State which mode you used in the plan summary. (This is why Step 1

  ("plan summary" appears only as informal prose at `:111` and `:151`; it has no template.)

- **G5** — `skills/code-review/SKILL.md:279-282` — the production-loop-only guard asserts a
  reciprocal note exists in `scripts/cross-model-review.py`'s module docstring; the two can drift
  independently and nothing checks the pair — **not covered**

  **Evidence** (SKILL `:281-282`):
  > byte-identical *across models* and stamped by `prompt_sha`. Prompt caching is deliberately absent
  > there (decision 032 H4) — see the guard note in that file's module docstring.

  **Evidence** (`scripts/cross-model-review.py:55-57`, the note being cited):
  > - DO NOT add prompt caching (`cache_control` breakpoints) here. This is the
  >   … byte-identical ACROSS models and stamped by prompt_sha, and caching is a

  The fact-check noted this docstring "gained a line" since the last claim about it — i.e. it is
  already a moving target.

- **G6** — `skills/code-review/SKILL.md:493-499` — the #4 fact-check-gate **fire** arm, carrying a
  new numeric claim (~73%) and a citation to a run artifact; no test binds the number in the skill
  to the number in the artifact — **not covered**

  **Evidence** (`:494-496`):
  > the **entire** Stage-1.5/Stage-2 critic panel for this pass. This is the largest saving (the
  > whole critic block) — measured at **~73% of the pass** on the one canon-adjacent case that
  > fired it (`runs/review-arms/baseline-2026-08-06/hunt-verify/results.md`).

  **Evidence** (`hunt-verify/results.md:19`, the source):
  > - **#4 saving = 238,155 tokens = 73.3% of the red-gated pass.**

  Partial-coverage note: nothing at all in `test/` references the short-circuit section, so both
  arms of the gate are uncovered — this entry is the fire arm, G7 is the no-fire arm.

- **G7** — `skills/code-review/SKILL.md:493-504` — the **polarity inversion** that is the substance
  of this commit: the fact-check gate went from "the common case" to "**not** the common case", and
  the critic-stage trigger from "largest saving" framing to "saves little / measured 0". A revert to
  the old framing would be a silent, invisible regression — **not covered**

  **Evidence** (`:496-499`, new):
  > But it is **not** the
  > common case: fact-check finds a *behavioral* 🔴 rarely — most fact-check Incorrects are
  > comment/doc (→🟡, no fire)

  **Evidence** (`:502-504`, new):
  > panel is one parallel wave already in flight, so there is usually nothing left to skip (measured:
  > a critic-surfaced red saved 0).

  **Evidence** (pre-change text, `git show HEAD~1:skills/code-review/SKILL.md`):
  > (the whole critic block, ~350–550k) and the common case, because fact-check runs first.

- **G8** — `skills/code-review/SKILL.md:276-278` vs `docs/decisions/032-…:120-126` vs
  `docs/decisions/log.md:53` — the #3 benefit magnitude ("single-digit-% of input cost, 0% of token
  count" / "~5% cost-equivalent, 0% token-count") is now stated in three documents that must agree;
  no test enforces the agreement — **not covered**

  **Evidence** (SKILL `:276-277`):
  > - **Measured benefit is modest — single-digit-% of input cost, 0% of token count** (caching is a
  >   billing-rate effect, not a token-count reduction).

  **Evidence** (`032:120`):
  > - **#3 prompt-cache: ~5% cost-equivalent, 0% token-count — NOT 20–40%.** The 20–40% estimate was

- **G9** — `skills/code-review/SKILL.md:241-242` vs `docs/decisions/032-…:123` and
  `docs/decisions/log.md:53` — the decision docs still describe the *pre-change* SKILL in the
  present tense ("the production SKILL has critics self-read"), which this commit made false, and
  the SKILL rounds the measured prefix to "~nothing" against a measured "~330 tok"; no test flags
  a decision doc describing a superseded state of the artifact it governs — **not covered**

  **Evidence** (SKILL `:241-242`):
  > only captured when the shared material is actually inlined as one cacheable prefix; agents
  > self-reading via tools shares no prefix and captures ~nothing)

  **Evidence** (`032:122-123`):
  > via tools — so the shared cacheable *prefix* is small (~330 tok as-run). Caching is also a

  **Evidence** (`log.md:53`, still present tense after this commit's edit):
  > (that figure assumed the cross-model harness's diff-inlining; the production SKILL has critics self-read, so the shared cacheable prefix is ~330 tok)

- **G10** — `docs/decisions/032-…:135-136` vs `hunt-verify/results.md:42-45` — the trigger-rate
  claim ("~1 clean trigger in 225 commits") is a derived statistic whose source says the hunt found
  **2** candidates of which **1** fired; no test binds the derived figure to its source — **not
  covered**

  **Evidence** (`032:135-136`):
  > canon; ~1 clean trigger in 225 commits). **Verdict: keep wired for loop safety — the rare

  **Evidence** (`results.md:43-45`):
  > canon reviewed states **0/8**; the 225-commit hunt found **2** candidates, and **1 of those 2 (A)
  > still classified 🟡** at fact-check because its impact was masked.

- **G11** — `skills/code-review/SKILL.md:99` — the new intra-document anchor
  `#inline-shared-context-prefix-decision-032-3` is exempt from the only link checker in the repo,
  because `test/cross-reference-integrity.bats:31` filters out targets beginning with `#` before
  resolution; renaming the `### Inline shared-context prefix (decision 032 #3)` heading silently
  breaks the reference — **not covered**

  **Evidence** (`test/cross-reference-integrity.bats:30-32`):
  > `| grep -v '^https\{0,1\}://' \`
  > `| grep -v '^#' \`
  > `| grep -E '(workflows|skills|guides|patterns)/' \`

**Coverage summary.** 11 gaps. None of the three suites that read `skills/code-review/SKILL.md`
(`code-review-assurance-contract`, `code-review-soundness-crosscheck`,
`code-review-factcheck-replication`) touch the Pipeline shared-context section or the
short-circuit section; `code-review-format-contract` reads only the fenced rubric template. The
36 green tests at HEAD are green because they look somewhere else — which is exactly why the three
Stale internal contradictions in G1 survived the commit.

---

## Recommended Tests

#### 1. Diff-delivery contract suite — one contract, four call sites

**Closes gaps:** G1, G2, G3, G4
**Type:** contract
**Priority:** high
**Legibility-target:** for-author
**File:** `test/skills/code-review-context-delivery.bats` (new; follow the
`code-review-assurance-contract.bats` header/setup/`subsection()` shape)
**What it verifies:** that the conditional-inlining contract is stated once and that every
dispatch site in the skill defers to it rather than restating the superseded unconditional
self-read rule.

**Key cases:**
- The `### Inline shared-context prefix (decision 032 #3)` section exists and states both arms:
  grep the section for `inline` **and** for a fallback clause (`fall back|do not inline`). One arm
  without the other is the regression this catches.
- **The contradiction check (G1 — this is the load-bearing case).** For each dispatch site — Stage-1
  replicate step 3 (`:340-344`), Stage-2 critic step 3 (`:634`), Important Reminders (`:1406`) —
  assert the surrounding line does **not** assert unconditional self-read. Implement as: every line
  matching `runs its own .git diff.` or `Pass scope, not diffs` must also match a conditionality
  marker (`conditional|unless|when not inlin|large diff|see .*shared-context`). Today all three fail;
  land the test with the three prose fixes in the same commit. Prefer this
  "every-occurrence-must-be-qualified" form over asserting exact replacement wording — it survives
  rewording and still catches a fourth site added later.
- Assert the count of unqualified occurrences is exactly 0 (not "at least one qualified one"), so a
  newly added dispatch step cannot slip in.
- **G2:** the strings referenced by the size guard resolve to real rules — `~1000` appears under the
  `#### Large diff triage` heading, and the section that defines `40%` churn is checked for whether
  it is scoped per-file. Minimum viable assertion: the size-guard sentence at `:261-266` and the
  Step 1 rule at `:116` must not disagree on whether churn is a diff-size gate — assert the size
  guard names a *line-count* threshold and that any churn mention there carries a per-file
  qualifier. If the author instead decides churn should not gate inlining at all, the fix is to drop
  `>40%-churn` from `:99`/`:263` and this case becomes a plain "no churn reference in the size
  guard" assertion.
- **G3:** the shared block enumerates items `1.`–`6.` in the stated fixed order; the item containing
  `fact-check summary` is item **6** and no numbered item follows it. Assert positionally (line
  order within the extracted section), not by string match, since the stability rule at `:271-275`
  depends on position, not wording.
- **G4:** the size guard requires the chosen mode to be reported (`grep -qi 'state which mode'`), and
  — the part that actually makes it execute — some emitted artifact has a slot for it. Given this
  repo's standing evidence that unenforced prose does not run (`code-review-assurance-contract.bats`
  header), pair this with a fixture case (test 2 below) or accept it as prose-only and record why.

**Setup needed:** None beyond the standard `SKILL_CONTENT` + `subsection()` helpers. No fixtures,
no stubs.

---

#### 2. Golden-fixture slot for the context-delivery mode

**Closes gaps:** G4
**Type:** snapshot (golden fixture)
**Priority:** medium
**Legibility-target:** for-author
**File:** `test/skills/code-review/rubric-current-format.md` + an assertion in
`test/skills/code-review-format-contract.bats`
**What it verifies:** that the inline-vs-self-read mode a run chose is recorded in a durable
artifact, not only in ephemeral chat.

**Key cases:**
- The golden fixture carries a line recording the mode (e.g. `**Context delivery:** inlined |
  self-read`), and the fixture value is one of the two permitted tokens.
- The existing `golden's section headings match the skill's rubric template` test still passes —
  i.e. if the slot is added as a `## ` heading it must be mirrored into the SKILL template in the
  same commit, per that suite's stated rule.

**Setup needed:** Decide first whether the mode belongs in the rubric or in the chat synthesis. If
the answer is "chat only", skip this test and move G4 to What NOT to Test with that reason — a
fixture slot for something the rubric does not carry is worse than no test. Flagging this as the
one open design question in the plan.

---

#### 3. First-red short-circuit contract suite — both arms

**Closes gaps:** G6, G7
**Type:** contract
**Priority:** high
**Legibility-target:** for-author
**File:** `test/skills/code-review-shortcircuit-contract.bats` (new)
**What it verifies:** that the #4 mechanics keep both the fire arm and the no-fire arm, and that the
calibration this commit installed (rare trigger, critic-stage saves ~nothing) cannot silently revert.

**Key cases:**
- The mechanics list has all five numbered items, and item 5 still says the terminal pass never
  short-circuits — this is the recall-preserving invariant the whole lever rests on (`:507-511`).
  It is unchanged by this diff but is the thing a careless edit to items 2–3 would take out.
- **Fire arm (G6):** item 2 states the gate skips the entire critic panel **and** cites a run
  artifact path that exists on disk (`[ -f "$REPO_ROOT/$cited_path" ]`). Extract the backticked
  path from the section rather than hardcoding it, so a moved artifact fails loudly.
- **No-fire arm, polarity (G7):** item 2 must carry a rarity qualifier — assert it matches
  `not the common case|rarely|low-frequency` **and** does **not** match `\bthe common case\b`
  unnegated. The negative half is the one that catches a revert to the pre-commit wording.
- **No-fire arm, critic stage (G7):** item 3 must state the limitation (`saves little|saved 0|
  nothing left to skip`). Without this, the item reads as a second big lever, which the measurement
  refuted.
- Item 1's tier-policy T definition still distinguishes behavioral from comment/doc Incorrect —
  this is the precise discriminator that made candidate A not fire, so the calibration prose in
  items 2–3 is only coherent while item 1 stands.
- The short-circuit note and the `## ⏭️ Skipped Core Critics` reason string (`:513-516`) still
  agree with the section heading used in the golden fixture (`rubric-current-format.md:77`).

**Setup needed:** None. Pure document assertions on `SKILL_CONTENT`.

---

#### 4. Lever-measurement drift guard (SKILL ↔ decision docs ↔ run artifacts)

**Closes gaps:** G6, G8, G9, G10
**Type:** contract (cross-artifact drift guard)
**Priority:** medium
**Legibility-target:** for-author
**File:** `test/lever-measurement-drift.bats` (new; repo-level, modelled directly on
`test/sandbox-tool-map-drift.bats`)
**What it verifies:** that every measured figure quoted in the skill and the decision records still
matches the run artifact it was derived from.

**Key cases:**
- `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md` carries the panel total `238,155`
  and the ratio `73`; assert `docs/decisions/032-…` and `docs/decisions/log.md` quote the same two
  figures, and that `skills/code-review/SKILL.md:493-499` quotes the same ratio.
- The `0/8` canon tally appears identically in the SKILL's supporting text, `032`, and
  `levers-3-4-measurement.md`.
- **G10:** the `225` hunt figure in `032` co-occurs with the source's own tally; assert `results.md`
  states how many candidates the hunt produced (`2`) and how many fired (`1`), and that `032`'s
  derived phrasing does not contradict it. A cheap correct version: require `032`'s trigger-rate
  sentence to cite `results.md` or `hunt-verify` so the derivation is traceable — chasing exact
  arithmetic equivalence across prose is not worth the maintenance.
- **G8:** `single-digit` / `~5%` / `0% ... token` appear consistently; specifically, assert no
  document in this set claims a token-*count* saving for #3, since the whole correction is that
  caching is a billing-rate effect. Phrase as a negative: no line matching `#3` may match
  `20–40%|20-40%` outside an explicitly-superseded context.
- **G9:** decision docs must not describe the SKILL's *current* behaviour as self-read. Assert that
  any line in `032`/`log.md` matching `production SKILL has critics self-read` also carries a
  past-tense/as-measured marker (`as-run|as measured|pre-#3|at the time`). This is the drift class
  that turns a decision record into a false statement about live code — currently failing, and the
  fix is a two-word edit.
- Skip cleanly (`skip`, not fail) if `runs/review-arms/baseline-2026-08-06/` is absent, matching the
  `require_live_settings` convention — run artifacts are large and may be pruned.

**Setup needed:** None. Consider adding explicit machine-readable markers to `results.md`
(e.g. `measured: panel_tokens=238155`, `measured: panel_share_pct=73`) so the test greps a marker
rather than prose — that is exactly what `guides/sandbox-tool-map.md` does with `allow-prefix:` and
it is why that guard has stayed maintainable.

---

#### 5. Reciprocal guard-note check for `cross-model-review.py`

**Closes gaps:** G5
**Type:** contract
**Priority:** medium
**Legibility-target:** for-author
**File:** add to `test/cross-model-review-stage1.bats` (existing suite already owns this script) or
to the new `test/lever-measurement-drift.bats`
**What it verifies:** that the SKILL's "see the guard note in that file's module docstring" still
resolves to an actual guard note.

**Key cases:**
- `scripts/cross-model-review.py` contains a `DO NOT add prompt caching` (or equivalent
  `cache_control`) prohibition within its module docstring, and it cites decision 032.
- The script contains no live `cache_control` usage — the guard is about behaviour, not only prose,
  and this is the assertion that would actually catch someone adding caching there.
- The SKILL's production-loop-only bullet still names the script by path, so the pair stays
  discoverable from both ends.

**Setup needed:** None; both files are in-repo.

---

#### 6. Intra-document anchor resolution

**Closes gaps:** G11
**Type:** contract
**Priority:** low
**Legibility-target:** for-author
**File:** `test/cross-reference-integrity.bats` (extend; do not create a second link checker)
**What it verifies:** that `#`-only markdown links resolve to a heading in the same file.

**Key cases:**
- For each `[text](#anchor)` in `workflows/ skills/ guides/ patterns/`, slugify every `#`-heading in
  the source file (lowercase, strip punctuation, spaces→`-`) and require a match. The new
  `#inline-shared-context-prefix-decision-032-3` is the immediate subject; it currently resolves.
- Keep the existing "checked > 0" guard so a slugifier bug that matches nothing fails loudly.
- Deliberately scope to same-file anchors; cross-file `path#anchor` fragment validation is more
  slug-normalisation surface than it is worth here.

**Setup needed:** A small `slugify()` bash helper. This is the highest-fiddliness / lowest-risk item
in the plan; if effort is constrained, drop it — a broken anchor degrades navigation, it does not
mis-steer an orchestrator.

---

## What NOT to Test

- **The exact prose of the measured-benefit paragraphs.** Asserting on wording like "modest" or
  "high-variance" is wording trivia with a high false-failure rate. Test the *polarity* markers and
  the *numbers* (tests 3 and 4), not the sentences around them.
- **The run artifacts under `runs/review-arms/baseline-2026-08-06/`.** These are immutable
  measurement records — append-only evidence, not a contract. The two documented defects in them
  (the "both already fixed, HEAD clean" claim contradicted by the same doc's line 13; the
  `candB-fact-check.md:8-9` header that miscounts its own body as 7/1 vs an actual 8/0) are
  corrections to make by hand, not regressions to guard. A self-consistency linter for fact-check
  report headers is a plausible *separate* tool, listed below as a beyond-scope item.
- **Re-deriving the token measurement.** Reproducing a 578k-token measurement in CI is absurd. Test
  that the quoted figures match the recorded ones (test 4); do not test that the recorded ones are
  right.
- **The rubric template's structure.** Already covered by `code-review-format-contract.bats`'s
  golden↔template sync tests; this change did not touch the template.
- **Whether the prompt cache actually hits.** Not observable from this repo; it is a property of the
  Anthropic API, not of the document. The document contract is that the block is built first and
  byte-identical — that is what tests 1 and 3 can reach.
- **`docs/decisions/log.md` row ordering.** Row 34 sits above rows 33/32 in the file. Cosmetic; not
  worth a test.

---

## Coverage Gaps Beyond Current Scope

**Legibility-target:** for-orchestrator-synthesis (this section only)

**1. No suite asserts SKILL.md internal self-consistency at all.** G1 is one instance of a general
class: the skill is ~1400 lines with the same contract restated in Step 1, the Stage dispatch steps,
and Important Reminders, and nothing checks the three against each other. Three of the four suites
that read this file test *presence* of a contract, never *absence of its negation*. A generic
"Important Reminders must not contradict the body" check would have caught this commit's defect and
would keep catching the next one.

**2. The Stage-1.5 critic gate (#1) — the lever the measurement calls load-bearing — has no
contract test.** `032` concludes "#1 was the load-bearing lever" with ~17% off the ungated panel,
yet the gate's prose is unguarded while the two levers that measured near-zero are the ones being
edited. Coverage effort is currently inverse to measured value.

**3. Fact-check report self-consistency.** The `candB-fact-check.md` header/body count mismatch is a
mechanically detectable class (declared verified/unverifiable counts vs rows in the body) that would
apply to every fact-check artifact this pipeline emits, not just this one.

**4. Decision-record tense drift (G9 generalised).** Decision records describe the state of
artifacts at decision time; when the artifact later changes, the record silently becomes false.
`log.md` row 34 is a live example. A repo-wide convention (as-measured markers, or a `Last verified`
field like the one `guides/doc-freshness.md` already defines for long-lived docs) would make this
checkable rather than requiring a fact-check pass to notice.

**5. No test asserts the two-suite baseline claimed in the commit message.** The commit body asserts
"format-contract 17/17 and gate 19/19 green" as its verification evidence. That is a manual claim in
a repo that has `test/test-baseline-gate.bats` infrastructure for exactly this kind of assertion.

---

## Summary

The highest-value test is **#1's contradiction check** — the "every unconditional self-read
instruction must be qualified" assertion. It is the only recommendation that would have failed on
this commit as landed, it targets the exact defect the fact-check found (three Stale instructions at
`:340-344`, `:634`, `:1406` still commanding behaviour the new `:99` contract reverses), and it costs
one grep with a negative. **#3** is the close second: the entire substance of the `2f5ad0b` #4 edit is
a polarity inversion — "the common case" → "not the common case" — with no artifact that would notice
it flipping back. Residual risk after all six tests: they verify the documents agree with each other
and with the recorded measurements; nothing verifies an orchestrator *obeys* them, so a correct
document with an ignored instruction still fails silently — this repo's own standing evidence (the
override log unwritten for nine runs) says that gap is real, and closing it needs run-artifact
assertions, not document assertions. Two open questions for the author: (a) does the
inline-vs-self-read mode belong in the rubric or chat-only — this decides whether test 2 exists at
all; and (b) is `>40%-churn` genuinely meant to suppress inlining on a small high-churn diff, or is
its appearance in the size guard a mis-citation of the per-file greenfield rule? Test 1's G2 case
takes a different shape depending on the answer.

## Goal-Alignment Note
- Answered: yes — 11 numbered gaps, 6 recommendations, every high/medium gap closed
- Out of scope: fixing the three Stale contradictions and the two run-artifact errors (test plan only, no source edits); reproducing the token measurements; verifying orchestrator runtime compliance
- Escalate: the three Stale instructions at `skills/code-review/SKILL.md:340-344`, `:634`, `:1406` are a live defect, not merely untested — the test in recommendation 1 should land with the prose fix in the same commit; and `docs/decisions/log.md:53` still describes the production SKILL as "critics self-read" in the present tense, which this commit made false
- Questions I would have asked: (1) Should the inline-vs-self-read mode be recorded in the rubric or is chat-only sufficient? (2) Is `>40%-churn` intended to gate inlining, or is that a mis-citation of the per-file greenfield rule?
