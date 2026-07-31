# Tech Debt Triage — `exp/cross-model-openrouter-sweep`

Commit: e9d05ea
Scope: `git diff main...HEAD` (13 files, +2375/−20)
Role: advisory contextual critic (tech-debt-triage). No finding here blocks merge on
correctness grounds; the question answered is "what does this branch cost to carry, and
what does it cost to fix later."

Fact-check findings from Stage 1 (k=3 merged) were taken as given and not re-verified.
Two of them are used below as *evidence of a debt mechanism* rather than as new findings.

---

## Triage Summary

| # | Debt Item | Carrying Cost | Cost of Deferral | Failure Cost | Fix Cost | Urgency | Recommendation |
|---|-----------|:---:|:---:|:---:|:---:|:---:|---|
| 1 | `k=3` arity hardcoded across ~18 prose + test sites, with a documented plan to change it to k=2 | Medium | +~1 k-coupled site per Stage-1 revision | | Hours | Trigger named in-doc | Fix opportunistically |
| 2 | The k=3 rationale is copy-pasted into 5 artifacts with no canonical source; already drifted | Medium | +1 verbatim copy per artifact that cites the rationale (3 added this branch) | | Hours | None | Fix opportunistically |
| 3 | `docs/decisions/log.md` rows have become essay-length; the log violates its own promotion rule | Medium | +1 oversized row per decision-heavy branch (3 landed 2026-07-30) | | Hours | None | Fix opportunistically |
| 4 | New bats suite: one near-vacuous assertion + the duplicated k=3 restatements are unguarded | Low | +~1 unguarded restatement per Stage-1 edit | | Hours | None | Fix opportunistically |
| 5 | 244 KB of DD-sweep artifacts committed with no committed runner and a hand-written summary table | Low | +~250 KB and one unreproducible arm per sweep | | Hours | Next sweep | Defer and monitor |
| 6 | State doc §1 uses three different "done" markers and retains shipped items under "Definitely needed" | Low | +1 divergent status marker per implemented §1 item | | Hours | None | Carry intentionally |
| 7 | **Decision-log ID collision — this branch adds a second row `26`; three artifacts now cite "log row 26" ambiguously** | Medium | +1 colliding ID per branch that appends without checking (IDs are already non-monotonic and 16 is missing) | | Hours | Now — cheap only before the ID is cited more widely | Fix now |

The Failure Cost column is left blank throughout. Every item here is documentation- and
process-ergonomics debt in a solo-dev tooling repo; none of it sits in a security,
payments, data-integrity, or compliance path, and inventing a `Low × Low` for any of it
would add noise without signal. Item 5 is the closest call (a future decision could be
built on a mis-summarized sweep — and two errors in that summary have already been found),
but incident probability there is not estimable from one branch, so it is discussed in
prose instead of scored.

### Recommended Order

0. **Item 7 first** — it is a one-character-class edit (renumber the new row) that gets
   strictly more expensive with every artifact that cites "log row 26", and item 3's fix
   explicitly depends on row numbers being stable identifiers.
1. **Items 1 + 2 together** — they have the same fix (one canonical "Replication
   parameters + rationale" block in `skills/code-review/SKILL.md`; every other site becomes
   a cross-reference). Doing them separately means touching the same ~18 sites twice.
2. **Item 4** immediately after, in the same pass — the test file's assertions must be
   re-pointed at the canonical block anyway, which is the natural moment to tighten the
   vacuous regex and add a whole-file arity-consistency assertion.
3. **Item 3** independently, whenever `log.md` is next edited — no dependency on 1/2/4.
4. **Item 5** at the start of the *next* sweep, not now — the fix is "commit the runner
   you are about to use," which costs nothing then and costs a reconstruction now.
5. **Item 6** — carry.

---

## Tech Debt Triage 1: `k=3` arity is hardcoded across ~18 sites, and the branch schedules its own change

**Severity:** Medium
**Location:** `skills/code-review/SKILL.md:26, 214, 246, 252, 258, 260, 264, 272, 278-280, 303, 306, 331, 347, 1066-1068, 1139`; `test/skills/code-review-factcheck-replication.bats:37, 39`; `docs/decisions/log.md:48`; `docs/thoughts/code-review-evaluation-state.md:39-45`
**Nature:** Structural — a single parameter (replicate count) expressed as ~18 independent literal restatements in prose, with no parameter block to change.
**Cost of Deferral:** `+~1 k-coupled site per Stage-1 revision`
**Failure Cost:** (blank — not material; see summary note)
**Confidence:** High — the site list is enumerated by `grep -n "k=3\|\bthree\b\|r1=\|r<N>\|3 fact-check" skills/code-review/SKILL.md`, 14 hits in that file plus 4 outside it.
**Legibility-target:** for-author

**Evidence** (verbatim, showing the same parameter restated in six unrelated registers):

`skills/code-review/SKILL.md:26`
```
  Runs as **k=3 parallel replicates** on byte-identical prompts, merged most-severe-wins
```
`skills/code-review/SKILL.md:214`
```
- Total agent count (3 fact-check replicates + N critics)
```
`skills/code-review/SKILL.md:258-260`
```
### Stage 1: Code Fact-Check (k=3 replicated)

Spawn **three** agents with the code-fact-check skill, in parallel, on **byte-identical
```
`skills/code-review/SKILL.md:278-280`
```
4. Instruct the agent to save its report as `docs/reviews/code-fact-check-report-r<N>.md`
   (N = 1, 2, 3). This per-replicate path is the **only** permitted difference between the
   three prompts — anything else varying would confound the disagreement measurement.
```
`skills/code-review/SKILL.md:331`
```
   carries a `Replicate verdicts: r1=<verdict> · r2=<verdict> · r3=<verdict>` line (`—` for
```
`skills/code-review/SKILL.md:1139`
```
- **Always run fact-checking first, and always as k=3 replicates.** Even if the user only
```

And the same file states, in the merge step, that this number is expected to change:

`skills/code-review/SKILL.md:338-340`
```
   flip into a tracked metric (state doc open question #2). If cumulative measurements
   across runs show ≥90% verdict agreement on a ≥20-claim sample, k can drop to 2 — that
   is §1.1's stated falsifier; record the observed rate either way.
```

### Carrying Cost: Medium

Nothing is broken today and the k=3 instructions are internally consistent as written. The
cost is entirely prospective and entirely load-bearing: this branch simultaneously (a)
spread one integer across ~18 restatements in four files and (b) documented the specific
empirical condition under which that integer changes. The k=2 transition is not a
hypothetical future refactor — it is a falsifier the branch instrumented every run to
evaluate. When it fires, the edit is 14 prose sites, 2 grep assertions pinned to the
literal strings `\(k=3 replicated\)` and `Spawn \*\*three\*\*`, one decision-log row, and
one state-doc status paragraph. A missed site does not fail loudly; it produces an
orchestrator prompt that says "k=3" in the skill-list bullet and "two replicates" in Stage
1, and the model resolves the contradiction however it likes. Secondary carrying cost: the
arity is also the per-review cost multiplier (3× fact-check agent spend on every
invocation) with no documented way for a user to opt down for a small diff, so "is this
worth 3 agents on a two-file diff" cannot be answered without editing the skill.

### Fix Cost
- **Scope:** localized — one new block in `skills/code-review/SKILL.md`, plus mechanical
  edits at the ~18 referencing sites and 2 test assertions.
- **Effort:** hours
- **Risk:** low — the tests are the safety net and they currently pass (10/10 verified);
  the risk is that over-genericizing the prose ("k replicates" everywhere) makes the
  instruction *less* legible to the executing model than a concrete "three", which is a
  real regression in a prose-driven skill. Mitigation: keep one concrete worked example.
- **Incremental?** yes — the canonical block can land first with cross-references added
  opportunistically.

### Urgency Triggers
- **Named in-doc and instrumented:** the §1.1 falsifier (≥90% agreement over a ≥20-claim
  cumulative sample → k=2). Every run now emits the input to this test, so the trigger
  arrives on its own schedule.
- Any future change to the merge rule, replicate paths, or checkpoint arity — each such
  edit touches a subset of the same ~18 sites.
- No trigger before the first k=3 run has executed (the state doc records that it has not:
  "the first k=3 run has not executed").

### Recommendation

**Recommendation:** Fix opportunistically

The duplication is real and the change that will expose it is already scheduled, but
nothing is wrong today and the fix has a genuine downside risk (genericized prose reads
worse to the model that executes it). Schedule it for the next substantive Stage 1 edit,
or immediately when the agreement data crosses the falsifier — whichever comes first. Fix
it in the same pass as item 2; they share a fix.

---

## Tech Debt Triage 2: the k=3 rationale is copy-pasted into 5 artifacts with no canonical source — and has already drifted

**Severity:** Medium
**Location:** `skills/code-review/SKILL.md:26-28` and `264-270`; `docs/decisions/log.md:48`; `test/skills/code-review-factcheck-replication.bats:5-10`; `docs/thoughts/code-review-evaluation-state.md:50`
**Nature:** Structural / documentation — one justification narrative (only-🔴-channel + Result 14a + most-severe-wins) maintained as five independent hand-written copies.
**Cost of Deferral:** `+1 verbatim copy per artifact that cites the rationale (3 added this branch)`
**Failure Cost:** (blank — not material; see summary note)
**Confidence:** High — the propagation is enumerable by grep, and Stage 1's fact-check independently rated the propagated claim Incorrect in three of the sites *simultaneously*, which is the duplication cost realized rather than predicted.
**Legibility-target:** for-orchestrator-synthesis

**Evidence** — the same claim, five places, one of them pre-existing:

`skills/code-review/SKILL.md:26-28`
```
  Runs as **k=3 parallel replicates** on byte-identical prompts, merged most-severe-wins
  (see Stage 1) — its verdict is the pipeline's only 🔴-promotion channel and is measurably
  unstable on a single sample (state doc §1.1, Result 14a).
```
`skills/code-review/SKILL.md:264-268`
```
**Why three.** The fact-check verdict is the *only* channel that promotes a finding to 🔴
(see [Unified Severity Mapping](#unified-severity-mapping)), and it is the least stable
judgment in the pipeline: on identical input, the same comment defect was rated
**Incorrect** by one run and **Mostly Accurate** by another, flipping the same finding
between 🔴 and 🟡 (`docs/thoughts/code-review-evaluation-state.md` §1.1, Result 14a).
```
`test/skills/code-review-factcheck-replication.bats:6-10`
```
#   The fact-check verdict is the pipeline's only 🔴-promotion channel and is the least
#   stable judgment in it (Result 14a: the same defect rated Incorrect by one run and
#   Mostly Accurate by another, on identical input). Stage 1 therefore runs three
#   replicates on byte-identical prompts and merges most-severe-wins, logging
#   per-replicate verdicts so the disagreement rate is a tracked metric.
```
`docs/decisions/log.md:48` (excerpt)
```
a fact-check Incorrect verdict is the pipeline's *only* 🔴-promotion channel, and Result 14a showed it flipping between Incorrect and Mostly Accurate on identical input
```
`docs/thoughts/code-review-evaluation-state.md:50` (pre-existing origin)
```
**Why.** Per Result 16, a fact-check Incorrect verdict is the *only* thing that promotes a
```

Note that `SKILL.md:264` cross-references `#unified-severity-mapping` — the table at
`SKILL.md:974-978` that Stage 1's fact-check used to rate the claim Incorrect. The
contradiction is *in the same file, two hundred lines apart, with a working anchor link
between them*.

### Carrying Cost: Medium

This is the debt whose cost has already been paid once on this very branch: a single
factual error propagated to three new locations in one commit, and Stage 1's fact-check had
to file it three times. Every future correction, refinement, or hedge to the rationale is a
five-file coordinated edit, and there is no mechanism — no test, no anchor, no include —
that makes a partial edit visible. The specific hazard is that `log.md` is append-only by
convention: once the wrong rationale is in row 26, correcting it means either editing
history-shaped content or leaving a decision record justified by a premise the repo has
since refuted. That is worse than ordinary prose duplication, because decision-log rows are
what future design work cites.

### Fix Cost
- **Scope:** localized to cross-cutting — the canonical statement belongs in exactly one
  place (Stage 1's "Why three" block is the natural home); the other four become one-line
  pointers. `log.md:48` is the awkward one: a log row cannot cross-reference in place of
  stating its rationale, so the honest fix there is a correction note, not a pointer.
- **Effort:** hours
- **Risk:** low-medium — the bats header comment is documentation and can simply shrink;
  the decision-log row is the judgment call (correct in place vs. append a superseding
  row). Getting that wrong makes the decision record harder to read, not incorrect.
- **Incremental?** yes

### Urgency Triggers
- None imminent. The correction itself is already owned by the Stage 1 fact-check finding;
  this item is about not re-incurring the propagation next time.
- Would escalate if a *second* rationale (e.g. the most-severe-wins justification, which
  is already stated three times) begins the same fan-out.

### Recommendation

**Recommendation:** Fix opportunistically

Batch with item 1 — the canonical "Replication parameters + rationale" block that fixes the
arity duplication is also the single source of truth that fixes this. Handle `log.md:48`
separately and deliberately: a decision row whose stated rationale has been refuted wants
an explicit correction, not silent deletion, and that is a judgment the author should make
rather than a mechanical dedup.

---

## Tech Debt Triage 3: decision-log rows have outgrown the log format

**Severity:** Medium
**Location:** `docs/decisions/log.md:15` (the rule), `:44` (2,493 chars), `:46` (2,958), `:47` (4,014), `:48` (1,823 — added by this branch)
**Nature:** Structural / documentation format — a table-row format carrying full-record content.
**Cost of Deferral:** `+1 oversized row per decision-heavy branch (3 landed on 2026-07-30 alone)`
**Failure Cost:** (blank — not material)
**Confidence:** High — measured directly (`awk '{print NR": "length($0)}' docs/decisions/log.md | sort -t: -k2 -rn`); the file is 48 lines / 31,296 bytes.
**Legibility-target:** for-author

**Evidence** — the log states its own promotion rule:

`docs/decisions/log.md:15`
```
**Rule of thumb:** if you can state the decision, context, and rationale in one table row below, it belongs here. If you find yourself wanting subsections, options lists, or "consequences" — promote it to a full record. When in doubt, start with a log entry — you can always promote it later if the rationale turns out to be more nuanced than you thought.
```

Row 25 (`log.md:47`, 4,014 chars) has subsections inside a table cell — exactly the stated
promotion trigger:
```
| 25 | 2026-07-30 | Treat `✅ Confirmed Good` as a claim requiring evidence … | Three fixes from `docs/thoughts/code-review-evaluation-state.md` §1.3/§1.4/§5.4. **(1) Confirmed Good.** … **(2) Single-sample label.** … **(3) Rubric selection.** …
```

Row 26, added by this branch (`log.md:48`, 1,823 chars), is the moderate end of the trend —
no subsections, but still ~7× the length the format was designed for, and it renders in
`git diff` as a single unreviewable line:
```
| 26 | 2026-07-30 | Stage 1 of `code-review` runs `code-fact-check` as k=3 parallel replicates on byte-identical prompts; … | Implements state-doc §1.1, the highest-leverage change the evaluation program identified: …
```

### Carrying Cost: Medium

Two concrete costs, both observable on this branch. First, review: a 1.8–4 KB single-line
table cell shows up in `git diff` as one changed line with no internal structure, so a
reviewer either reads the whole cell or skips it — and on this branch, the incorrect
"only 🔴-promotion channel" claim was in exactly such a cell. The format actively hides the
content it carries. Second, the log's purpose is scannability (its own framing: state it in
one row, or promote it); at 31 KB across 48 lines it no longer renders as a scannable
table in any viewer, which means the "cheap alternative to a full record" is now more
expensive to read than the full records it was meant to avoid. Rows 22–26 have full-record
content without full-record structure — no options considered, no consequences section, no
stable heading to link to.

Mitigating: this predates the branch (rows 24 and 25 are the worst offenders and are
already on main). Row 26 continues the trend rather than establishing it.

### Fix Cost
- **Scope:** localized — promote rows 24 and 25 to `docs/decisions/0NN-*.md` full records
  and replace the cells with one-line summaries plus a Full Record link, which is the
  workflow the log header already documents. Row 26 is borderline and could stay.
- **Effort:** hours
- **Risk:** low — pure documentation restructuring. The one hazard is breaking inbound
  references: the state doc and the new bats header cite "log row 26" / "log row 25" by
  number, so row numbers must be preserved as stable identifiers, not renumbered — which
  is why item 7 (the duplicate `26`) has to be resolved before this item is attempted.
- **Incremental?** yes — one row at a time.

### Urgency Triggers
- None imminent.
- Would escalate if a decision row needs to be *superseded* — amending a 4 KB table cell in
  place is materially worse than adding a Status: Superseded header to a full record, and
  item 2 has already created one candidate for exactly that.

### Recommendation

**Recommendation:** Fix opportunistically

The debt is real and self-diagnosed by the file's own rule, but it is inert between edits
and the fix is mechanical. Promote rows 24 and 25 the next time `log.md` is touched; keep
row-number stability. Do not treat this as a blocker for the current branch — row 26 is the
least offensive of the three that landed today.

---

## Tech Debt Triage 4: contract-test gaps — one near-vacuous assertion, and the duplicated k=3 sites are unguarded

**Severity:** Low
**Location:** `test/skills/code-review-factcheck-replication.bats:28` (section range), `:46` (loose regex); absent coverage for `skills/code-review/SKILL.md:26, 214, 246, 252, 1139`
**Nature:** Testing — prose-grep contract assertions with uneven binding strength.
**Cost of Deferral:** `+~1 unguarded restatement per Stage-1 edit`
**Failure Cost:** (blank — not material)
**Confidence:** Medium-High. High on the coverage gap (verified: `grep -rn "Total agent count\|Always run fact-checking\|Stage 1 (fact-check" test/` returns nothing). Medium on the section-range hazard — I tested the failure mode and it is *less* severe than it looks, see below.
**Legibility-target:** for-author

**Evidence:**

The loose assertion, `test/skills/code-review-factcheck-replication.bats:46-47`:
```
  stage1 | grep -qiE 'only.*(difference|permitted).*|(difference|permitted).*only' \
    || fail "Stage 1 does not pin the output path as the only permitted prompt difference"
```
This passes on any Stage-1 line containing "only" and either "difference" or "permitted" in
either order — including prose that says the opposite of the contract. Contrast with the
same file's strongest assertion, `:69`, which is tightly bound and correctly so:
```
  stage1_flat | grep -qE 'Incorrect \(high confidence\)`? > `?Incorrect \(medium confidence\)`? > `?Stale`? > `?Mostly Accurate`? > `?Unverifiable`? > `?Verified' \
```

The section extractor, `:28`:
```
  echo "$SKILL_CONTENT" | sed -n '/^### Stage 1: Code Fact-Check/,/^### Fact-Check Gate/p'
```

**Two things I checked before rating this, and both cut against the obvious complaint:**

1. *The prose-grep pattern itself is not novel debt.* It is the dominant convention here —
   ~40 `*.bats` files use it, and the closest sibling, `test/skills/code-review-assurance-contract.bats`,
   carries 22 `grep -q` assertions over the same SKILL.md. The new file conforms; it does
   not introduce a pattern.
2. *The `sed` range is a mostly-loud failure.* If the start anchor is renamed the range
   emits nothing and every assertion fails visibly. If the end anchor is renamed the range
   runs to EOF — but I measured which assertion strings occur after line 350, and
   `Replicate verdicts:`, `## Verdict stability`, the `90%…20` falsifier, the two-replicate
   checkpoint, and `code-fact-check-report-r<N>.md` all occur **zero** times outside the
   section. Only `byte-identical` (1) and `most.severe` (3) leak. So the silent-vacuous-pass
   surface is 2 of 10 assertions, not 10 of 10. Rated Low accordingly.

The real gap is coverage, not brittleness. All 10 tests pass (verified by running the
suite), and nothing in `test/` asserts that `SKILL.md:26`, `:214`, `:246`, `:252`, or
`:1139` agree with Stage 1 about the arity — which is precisely the drift class that
produced the propagated incorrect claim in item 2.

### Carrying Cost: Low

The suite works and pins the load-bearing parts of the contract (severity order, most-
severe-wins, per-replicate verdicts, the falsifier, the two-replicate floor). What it does
not do is protect the five restatements outside Stage 1, so item 1's fix and any future
arity edit have no mechanical backstop — the tests would go green on a half-completed
change. That is a small, bounded cost that only materializes when someone edits the arity.

### Fix Cost
- **Scope:** localized — one file, ~3 assertion changes.
- **Effort:** hours (realistically under one)
- **Risk:** low — worst case a new assertion is over-tight and fails on a legitimate
  rewording, which fails loudly and is cheap to relax.
- **Incremental?** yes

Concretely: tighten `:46` to require the actual contract phrase; add one whole-file
assertion that every arity statement outside Stage 1 agrees with the Stage 1 heading
(e.g. assert no line matches `k=[^3]` / `(two|four) (fact-check )?replicates`); optionally
make `stage1()` fail explicitly when the end anchor does not match rather than silently
running to EOF.

### Urgency Triggers
- The item 1 refactor — if the arity is de-duplicated into a canonical block, these
  assertions must be re-pointed anyway, and that is the moment to add the consistency check.
- None otherwise.

### Recommendation

**Recommendation:** Fix opportunistically

Fold into the item 1 / item 2 pass. Standalone it is not worth a dedicated change: the
suite is conventional, it passes, and it already binds the parts of the contract that
carry merge-blocking authority.

---

## Tech Debt Triage 5: 244 KB of sweep artifacts committed with no committed runner and a hand-written summary

**Severity:** Low
**Location:** `runs/dd-cross-model-2026-07-30/` (9 files, ~2,100 lines, 244 KB); `runs/dd-cross-model-2026-07-30/README.md:35-41, 47-51`; absent: any script producing `<model>.md` + `<model>.meta.json`
**Nature:** Process / reproducibility — immutable experiment output without its generating harness.
**Cost of Deferral:** `+~250 KB and one unreproducible arm per sweep`
**Failure Cost:** (blank — not scored; discussed in prose)
**Confidence:** Medium-High on the missing runner (`scripts/cross-model-review.py` writes `findings.jsonl` / `overlap.json` per its own usage block and does not emit `*.meta.json`; no other script in `scripts/` targets OpenRouter). Medium on the size assessment — I may be undervaluing repo-size growth over a longer horizon.
**Legibility-target:** for-author

**Evidence:**

The artifact set is byte-identical-prompt experiment output, correctly framed as immutable —
`runs/dd-cross-model-2026-07-30/README.md:3-4`:
```
Four frontier models were given a **byte-identical prompt** (`prompt.md` in this
directory) and asked to run the `divergent-design` workflow, end to end, on the
```
The README's Files table lists inputs and outputs but no invocation —
`runs/dd-cross-model-2026-07-30/README.md:61-68`:
```
| File | Arm |
|---|---|
| `prompt.md` | The shared prompt (identical bytes to all four models) |
| `local_claude-fable-5.md` | Fable 5, local Claude Code subagent |
```
The existing in-repo OpenRouter harness produces a different artifact shape —
`scripts/cross-model-review.py:26-30`:
```
  scripts/cross-model-review.py \
    --repo /path/to/repo --range 'abc123~1..abc123' \
    --models anthropic/claude-opus-4.5 openai/gpt-5.2 google/gemini-3-pro \
    --replicates 2 \
    --out runs/cross-model/abc123
```

**What cuts in the branch's favour, and why this is Low:** committing run artifacts in-tree
is established practice here — `runs/cross-model/` is already tracked (19 files, 524 KB),
and `.gitignore` deliberately excludes *generated* eval reports
(`test/skills/*/output/`, `docs/working/*.json`) while leaving `runs/` tracked. So the
in-tree decision is consistent with an existing, deliberate convention, not a new habit.
At 244 KB against a 2.1 MB `docs/` tree, size is not the issue and I will not pretend it is.

**What the debt actually is:** the sweep cannot be re-run or extended without reconstructing
the harness from memory, and the README's `Results at a glance` table is hand-transcribed
from the `.meta.json` files rather than generated from them. Stage 1's fact-check found two
errors in exactly that table (the Kimi runner-up attribution and the "~9×" latency figure),
which is the predictable failure of hand-summarizing machine output. Decision-log row 26
cites this sweep as corroboration for shipping k=3 — so the summary layer is load-bearing
for a decision, while being the one layer nothing checks.

### Carrying Cost: Low

Nothing depends on re-running the sweep today, and the raw per-model responses and
`.meta.json` files are self-describing enough that a reader can verify any summary claim
by hand. The cost is that each future sweep repeats the reconstruction, and each hand-
written summary table is a fresh opportunity for the transcription errors already observed.

### Fix Cost
- **Scope:** localized — either commit the runner used, or add a `## How this was run`
  section to the README with the exact invocation and model IDs.
- **Effort:** hours (minutes for the README variant)
- **Risk:** low. Honest uncertainty: I cannot estimate the cost of *generalizing*
  `cross-model-review.py` to cover the DD-sweep shape, because I do not know how the DD
  sweep was actually invoked. If the answer is "a throwaway one-liner," committing it is
  trivial; if it was a modified copy of the harness, merging the two is a day, not hours.
- **Incremental?** yes

### Urgency Triggers
- **The next sweep.** The fix is nearly free at that moment (commit the script you are
  already using) and requires archaeology at any other moment.
- A third `runs/` subdirectory appearing with a fourth artifact shape.

### Recommendation

**Recommendation:** Defer and monitor

Re-evaluate at the start of the next cross-model sweep: if a runner is written or reused,
commit it alongside the artifacts and generate the README's results table from the
`.meta.json` files rather than transcribing it. Doing the work now means reconstructing an
invocation from output, which is the expensive direction.

---

## Tech Debt Triage 6: state-doc §1 status markers have diverged

**Severity:** Low
**Location:** `docs/thoughts/code-review-evaluation-state.md:39, 41, 121, 148, 153`; `:7` (Relevant paths)
**Nature:** Naming / documentation convention.
**Cost of Deferral:** `+1 divergent status marker per implemented §1 item`
**Failure Cost:** (blank — not material)
**Confidence:** High — all four markers are visible in one `grep -n "^#\+ \|implemented\|[Ss]hipped"` pass.
**Legibility-target:** for-author

**Evidence** — four completed items, three marker conventions, two placements:

`:39` (this branch — heading suffix, "implemented", cites a log row)
```
### 1.1 Run `code-fact-check` k≥3 times and combine, before anything downstream — **implemented** (log row 26)
```
`:153` (pre-existing — heading prefix, "Done", cites a commit *and* a log row)
```
### 1.5 Done — headless flags (`96166d5`, log row 24)
```
`:121` (pre-existing — body bold, "Shipped", cites a commit)
```
**Shipped (`a9fa0ba`, log row 25) — with a measured partial.** The rubric's Confirmed Good
```
`:148` (pre-existing — body bold, partial-scope variant)
```
**Label shipped (`a9fa0ba`).** A passing rubric status and a `merge` recommendation both
```

Also, the doc's freshness header was not updated to track the new artifact it now cites —
`:7` lists nine `Relevant paths` and `runs/dd-cross-model-2026-07-30/` is not among them,
though `:44` references it as corroboration.

### Carrying Cost: Low

Four of the five §1 subsections are now shipped or partially shipped while the section is
titled "Definitely needed (evidence is direct, and the failure has been observed)" — a
reader scanning for open work must read every subsection body to learn that most of the
section is closed. This is exactly the failure mode a living doc is supposed to prevent,
but it is cosmetic: every marker is unambiguous once read, and the doc is read start-to-
finish by design ("the shortest path to 'what do we actually know'"). The branch's own
addition is a well-written status paragraph that is honest about what has *not* happened
("the first k=3 run has not executed; the noise floor is still unquantified") — the content
is good; only the convention is inconsistent.

### Fix Cost
- **Scope:** localized — one file, five edits plus one `Relevant paths` addition.
- **Effort:** hours (well under)
- **Risk:** low
- **Incremental?** yes

### Urgency Triggers
- None identified. Would escalate only if §1 became the primary work-queue for another
  contributor, which does not apply in a solo-dev repo.

### Recommendation

**Recommendation:** Carry intentionally

The inconsistency costs a reader seconds, the doc is read linearly, and picking a
convention now would itself be a fifth convention unless applied to all four sites. If it
is touched at all, the cheap high-value piece is adding `runs/dd-cross-model-2026-07-30/`
to the `Relevant paths` line at `:7`, since that field feeds the documented freshness-
tracking heuristic and a cited-but-untracked path silently defeats it.

---

## Tech Debt Triage 7: decision-log ID collision — a second row `26`

**Severity:** Medium
**Location:** `docs/decisions/log.md:41` (row 26, 2026-07-22, Rust toolchain — pre-existing on `main`) and `docs/decisions/log.md:48` (row 26, 2026-07-30, k=3 replication — **added by this branch**). Ambiguous citations: `docs/thoughts/code-review-evaluation-state.md:39` and `:198`, `test/skills/code-review-factcheck-replication.bats:4`.
**Nature:** Identifier / referential integrity — the log's row number is used as a stable citation target and is not unique.
**Cost of Deferral:** `+1 colliding ID per branch that appends without checking`
**Failure Cost:** (blank — documentation referential integrity, not an incident path)
**Confidence:** High — mechanically verified. `awk -F'|' '/^\| *[0-9]+ *\|/ {gsub(/ /,"",$2); print $2}' docs/decisions/log.md | sort -n | uniq -d` prints exactly `26`. The same command run against `git show main:docs/decisions/log.md` prints nothing, so the collision is introduced here, not inherited.
**Legibility-target:** for-author

**Evidence** — both rows, verbatim openings, in ID order as they appear in the file:

`docs/decisions/log.md:41`
```
| 26 | 2026-07-22 | Ship a Rust toolchain in the cc-isolated
```
`docs/decisions/log.md:48`
```
| 26 | 2026-07-30 | Stage 1 of `code-review` runs `code-fact-check` as k=3 parallel replicates on byte-identical prompts; …
```

The new row's ID is cited as a pointer in three places added by this branch:

`docs/thoughts/code-review-evaluation-state.md:39`
```
### 1.1 Run `code-fact-check` k≥3 times and combine, before anything downstream — **implemented** (log row 26)
```
`test/skills/code-review-factcheck-replication.bats:4`
```
# (docs/thoughts/code-review-evaluation-state.md §1.1, decision log row 26):
```

Full ID sequence in file order — non-monotonic, with `16` absent and `26` appearing twice:
```
1 2 3 4 5 6 7 8 9 10 11 12 13 15 14 18 17 19 26 20 22 23 21 24 25 26
```

Worth recording for the orchestrator: all three Stage-1 fact-check replicates checked this
region and all three confirmed the citation resolves — e.g. `docs/reviews/code-fact-check-report-r2.md:310`
states "decision log row 26 exists at `docs/decisions/log.md:48`". Each verified that *a*
row 26 exists; none checked that only one does. That is an existence check standing in for
a uniqueness check, and it is the same shape as the `✅ Confirmed Good` failure decision 25
was written to address.

### Carrying Cost: Medium

Today the cost is that every "log row 26" citation is ambiguous and resolves correctly only
by date or topic inference. That is survivable while three citations exist and the two rows
are on wildly different subjects. It stops being survivable in two ways. First, the log's
own workflow is to promote rows to full records and back-link them — item 3 recommends
exactly that, and it requires row numbers to be stable unique keys; with a duplicate, "the
row 26 record" is undefined. Second, the next appended row will presumably be `27`, which
silently ratifies the collision as permanent history rather than a typo caught in the week
it was made. Nothing in `test/` or `scripts/` reads `docs/decisions/log.md`, so no gate will
ever surface this (verified: `grep -rl "decisions/log" test/ scripts/` returns nothing).

### Fix Cost
- **Scope:** localized — renumber the new row to `27` and update the three citing sites.
- **Effort:** hours (realistically minutes)
- **Risk:** low. The one judgment call is *which* row moves. Renumbering the new row is
  correct: the 2026-07-22 row has been on `main` for eight days and may be cited in
  archived working docs, whereas the new row's only citations are the three added in the
  same commit. Do not renumber the pre-existing row.
- **Incremental?** no — it is a single coordinated four-site edit, and a partial application
  is worse than the current state.

### Urgency Triggers
- **Imminent and self-inflicted:** the next appended log row. After that, fixing the
  collision means renumbering into an established sequence rather than correcting a
  same-week append.
- Item 3's promotion of rows to full records, which presumes unique IDs.
- Any additional artifact citing "log row 26".

### Recommendation

**Recommendation:** Fix now

Carrying cost is only Medium, but this is the rare case where fix cost is minutes *today*
and grows discontinuously with the next log append — and it is the one item on this branch
that is unambiguously a defect rather than a tradeoff. Per the skill's routing, this is a
**trivial fix** (a renumber plus three citation updates, well under 50 LOC across four
files): make the change in place, run `bats test/skills/code-review-factcheck-replication.bats`,
and commit. No research doc or plan doc — the overhead would exceed the work.

Optional follow-on, not required: a one-assertion bats test that `log.md` row IDs are
unique. Cheap, and it is the only mechanical guard the decision log would have.

---

## What I deliberately did not assess

- **Contents of `runs/dd-cross-model-2026-07-30/*.md`** (~2,100 lines) — out of scope per
  the brief; assessed only as an artifact-management question (item 5).
- **Whether k=3 is the right design.** That is a decision question, already answered by the
  sweep and recorded in log row 26. This pass asks only what the *implementation shape*
  costs to carry.
- **Correctness of the "only 🔴-promotion channel" claim.** Taken as given from Stage 1;
  used here only as evidence of the propagation mechanism in item 2.
- **The 3× per-review cost of k=3 as a spend question.** Noted inside item 1's carrying
  cost because the arity is unconfigurable, but the economics of the choice are the
  decision's business, not debt.

## Goal-Alignment Note
- Answered: yes — seven debt items triaged with carry/fix/urgency and a ranked order
- Out of scope: contents of the immutable run artifacts; whether k=3 is the correct design; re-verification of Stage 1 fact-check findings
- Escalate: nothing
