# Test Strategy: prompt-audit application (2d679ce..HEAD)

**Commit:** 0661353
**Scope:** `git diff -M -C 2d679ce..HEAD` — 27 files; the load-bearing subset is
`skills/code-review/{SKILL.md,references/*}`, the four re-pointed contract suites under
`test/skills/`, `devcontainer-config/install.sh`, and `scripts/health-check.sh`.
**Reviewed:** 2026-09-12
**Harness state:** 97/97 `test/skills/code-review-*.bats` pass; 18/18 across
`lever-measurement-drift`, `cross-reference-integrity`, `guide-index-sync`,
`agents-gemini-sync`, `link-claude-home-wiring`; `scripts/health-check.sh` exits non-zero
with six `✗` (four shellcheck, two MD-consistency), all pre-existing.

---

## Test Conventions

- **Framework:** bats-core 1.8.2, suites under `test/` (repo-wide) and `test/skills/`
  (skill-contract suites). `# @category fast` tags the fast tier.
- **Dominant pattern:** *prose-contract tests* — read a markdown file into `SKILL_CONTENT`,
  extract a section with `sed -n '/^### Start/,/^### End/p'`, then `grep -qiE` for the clause
  that must be present. `fail()` is defined per-suite. The stated rationale (repeated in
  several suite headers) is that "an unenforced prose instruction does not execute".
- **Shell-script conventions:** hermetic tests build a fake `$SRC`/`$DEST` under `mktemp -d`
  and exercise the repo's own copy of the script (`test/link-claude-home-wiring.bats`),
  stubbing unrelated payload entries rather than copying the real tree.
- **Drift guards:** a separate pattern (`test/sandbox-tool-map-drift.bats`,
  `test/lever-measurement-drift.bats`) pins a figure or list across every document that
  restates it.
- **Anchor-existence guards:** two suites already carry an explicit
  `@test "the section-extraction end anchor exists (no silent extract-to-EOF)"` (tech-debt D1,
  2026-07-31). The pattern exists; this diff outran it.
- **`scripts/health-check.sh` has no unit tests at all.** It is exercised only by being run.

---

## Untested Paths Touched by the Change

- **G1** — `test/skills/code-review-assurance-contract.bats:123` — `sed -n '/^## Important
  Reminders/,$p'` now terminates at the end of the four-file *concatenation*, not at the end of
  `SKILL.md`; the assertion is satisfiable by `references/rubric.md` text 300+ lines past the
  section under test — **not covered** (no test pins the extraction's upper bound).
- **G2** — `test/skills/code-review-assurance-contract.bats:166-167` — the negative assertion
  runs against `"$SKILL"` (`SKILL.md` alone), which post-split contains **zero** status lines;
  the property "the single-sample label is never attached to a failing verdict" is
  **not covered** at its new home (`references/rubric.md:1875-1891` of the concatenation).
- **G3** — `devcontainer-config/install.sh:51-56` — the `cp -r … "$STAGE/$(basename "$item")"`
  staging loop: neither the file entry (`global-instructions/CLAUDE.md` → payload root) nor the
  directory entries are asserted to land at the expected payload path — **not covered**.
  `test/link-claude-home-wiring.bats:37` stubs the payload with `touch "$SRC/CLAUDE.md"`, so it
  cannot see a staging regression.
- **G4** — `devcontainer-config/install.sh:55` — the `else` branch (source path missing) emits a
  stderr `WARNING` and continues, producing a payload with no global instructions and a
  zero exit code — **not covered**; this is the failure mode the F1 path change made reachable.
- **G5** — `devcontainer-config/install.sh:47` basenames ↔ `devcontainer-config/link-claude-home.sh:47`
  `ENTRIES=(… CLAUDE.md)` — the two lists are now an implicit contract (the stager decides the
  basename, the linker hard-codes it) — **not covered**.
- **G6** — `scripts/health-check.sh:237` — in `check_md_consistency`, a missing `$GLOBAL_MD`
  hits a bare `continue` (no `warn`), leaving `files=(AGENTS.md GEMINI.md)`; `${#files[@]} -lt 2`
  is false, so the function compares the two siblings — which `test/agents-gemini-sync.bats`
  already guarantees are identical — and prints `✓ All MD files reference the same workflows`
  — **not covered**. Silent wrong answer.
- **G7** — `scripts/health-check.sh:205` and `:871` — the missing-file branches in
  `check_workflow_crossrefs` and `check_md_semantic_divergence` call `warn` (`scripts/health-check.sh:47`
  — yellow output only, does **not** touch `FAIL`), so a lost instructions file degrades three
  checks to green-ish without failing the run — **not covered**.
- **G8** — `scripts/health-check.sh:944,965` — the associative-array keys changed from the
  literal `CLAUDE.md` to `$GLOBAL_MD`; if the population loop at `:868` and the consumption at
  `:944/:965` ever diverge, both `-n "${h2_set[$GLOBAL_MD]+x}"` guards go false and the whole
  divergence report is skipped silently — **not covered** (no unit test reaches this function).
- **G9** — `test/skills/code-review-soundness-crosscheck.bats:138-143` — the end-anchor guard
  asserts `### Rubric Status Line` exists *somewhere in the concatenation*; with a multi-file
  `SKILL_CONTENT` that no longer proves the anchor *follows* `channel()`'s start anchor, which
  is the property the guard was written for — **partially covered** (existence yes, ordering no).
- **G10** — repo invariant, no owner — nothing asserts that a `CLAUDE.md` has not reappeared at
  the repo root. That single fact *is* the whole point of `c56be81` (single load), and it is
  **not covered**.
- **G11** — repo invariant, no owner — nothing asserts that `skills/code-review/SKILL.md` has not
  re-inlined the extracted reference material (the F8 property: reference content is read at the
  stage that needs it, not resident on every trigger) — **not covered**.
- **G12** — `skills/code-review/SKILL.md:86-91,1137,1147,1188` + 14 further
  `references/*.md#anchor` links — `test/cross-reference-integrity.bats:31` filters link targets
  to `(workflows|skills|guides|patterns)/`, so a relative `references/rubric.md` target matches
  nothing and is never resolved; anchor fragments are stripped and never checked at all —
  **not covered**. (A *rename* of a reference file is caught incidentally: the four suites' `cat`
  in `setup()` would fail. A *renamed heading* is not.)
- **G13** — `skills/draft-review/SKILL.md:49`, `skills/matrix-analysis/SKILL.md:34`,
  `patterns/orchestrated-review.md:131` — the F2/F3/F4 rewrites (pressure language removed,
  `## Mandatory Execution Rules` → `## Execution rules`, `Default output cap` → `Default output
  shape`) have no regression test; `skills/ui-visual-review/SKILL.md:58` still carries
  `## Mandatory Execution Rules`, and nothing flags the inconsistency — **not covered**.

**Pre-existing, not introduced by this diff (listed so they are not misattributed):**
`code-review-soundness-crosscheck.bats:41`'s `channel()` spans `### Soundness-Contradiction
Channel` → `### Rubric Status Line`, which encloses `### Executable-Defect Channel`; the same
heading order held at `2d679ce` (`### Soundness…` 1619, `### Executable…` 1689, `### Rubric
Status Line` 1739). Likewise `code-review-executable-defect.bats:88`'s cross-check range encloses
`#### Fragment-Composition cross-check`. Both widenings predate the split.

---

## Findings

### F1 — the Important-Reminders assertion became unfalsifiable

**Severity:** Medium
**Legibility-target:** the suite that guards the Confirmed-Good contract
**Location:** `test/skills/code-review-assurance-contract.bats:122-126`
**Closes-gap:** G1
**Evidence** (verbatim):

```
@test "Important Reminders carries the Confirmed-Good contract" {
  echo "$SKILL_CONTENT" | sed -n '/^## Important Reminders/,$p' \
    | grep -qiE 'Confirmed Good.*claim, not an output' \
    || fail "Important Reminders does not carry the Confirmed-Good contract"
```

At `2d679ce`, `## Important Reminders` was the last section of `SKILL.md`, so `,$p` was exactly
that section. Post-split the concatenation is 1949 lines and `## Important Reminders` sits at
1192; `,$p` now captures 757 further lines, including
`references/rubric.md`'s own `### Confirmed Good is a claim, not an output` heading (concat line
1556) and a cross-link at 1475. Deleting *both* real Important-Reminders bullets (concat lines
1231 and 1239) leaves the test green:

```
$ cat SKILL.md references/chat-synthesis.md references/rubric.md references/override-log.md > concat.md
$ awk 'NR!=1231 && NR!=1239' concat.md | sed -n '/^## Important Reminders/,$p' \
    | grep -qiE 'Confirmed Good.*claim, not an output' && echo PASSES
PASSES
$ awk 'NR!=1231 && NR!=1239' skills/code-review/SKILL.md | sed -n '/^## Important Reminders/,$p' \
    | grep -qiE 'Confirmed Good.*claim, not an output' || echo "fails (pre-split behaviour)"
fails (pre-split behaviour)
```

**Confidence:** High (mutation executed, both directions).

Note the asymmetry: `test/skills/code-review-factcheck-replication.bats:144` runs the *same*
`sed -n '/^## Important Reminders/,$p'` idiom, was **not** re-pointed, and therefore still reads
`SKILL.md` alone — so it still binds correctly. The suite that was updated is the one that broke.

---

### F2 — the failing-verdict negative assertion now scans a file with no verdicts in it

**Severity:** Medium
**Legibility-target:** §1.4 single-sample-label contract
**Location:** `test/skills/code-review-assurance-contract.bats:163-167`
**Closes-gap:** G2
**Evidence** (verbatim):

```
@test "the label is not attached to a failing verdict" {
  # `run !` rather than a bare `!`: a leading `!` on a non-final command does not
  # fail a bats test, so the bare form would assert nothing (SC2314).
  run ! grep -qE "DOES NOT PASS.*$LABEL" "$SKILL"
  run ! grep -qE "CONDITIONAL PASS.*$LABEL" "$SKILL"
}
```

Every other test in this suite was migrated from `$SKILL` to `$SKILL_CONTENT`; these two were
not. The status lines they police moved to `references/rubric.md`:

```
$ grep -c 'PASSES REVIEW\|DOES NOT PASS\|CONDITIONAL PASS' skills/code-review/SKILL.md
0
$ grep -n 'DOES NOT PASS' skills/code-review/references/rubric.md | head -1
9:- Any 🔴 unresolved: `**Status: 🔴 DOES NOT PASS** — <n> blocking finding(s)`   (line numbers relative to the file)
```

The `run !` mechanism itself is sound under bats 1.8.2 (verified: `run ! grep -q root
/etc/passwd` reports `not ok`); the BW02 warnings are cosmetic. The defect is the target file.
Fix is one word: `"$SKILL"` → `<<<"$SKILL_CONTENT"`.

**Confidence:** High.

---

### F3 — `health-check.sh` reports a green MD-consistency check when the instructions file is gone

**Severity:** Medium
**Legibility-target:** the check that exists to catch drift between the instructions file and its
two siblings
**Location:** `scripts/health-check.sh:232-246`, with `warn` at `:47`
**Closes-gaps:** G6, G7
**Evidence** (verbatim):

```
    for mdfile in "$GLOBAL_MD" AGENTS.md GEMINI.md; do
        local path="$REPO_ROOT/$mdfile"
        [[ -f "$path" ]] || continue
        files+=("$mdfile")
```
```
    if [[ ${#files[@]} -lt 2 ]]; then
        warn "Fewer than 2 MD files found, skipping consistency check"
        return
    fi
```
```
warn() { yellow "  ⚠ $*"; }
```

With `$GLOBAL_MD` absent, `files` holds the two siblings, the `-lt 2` guard does not fire, and the
comparison reduces to AGENTS.md vs GEMINI.md — a pair `test/agents-gemini-sync.bats` already keeps
byte-identical. The function then prints `✓ All MD files reference the same workflows`. Two
sibling checks (`:205`, `:871`) degrade to `warn`, which never touches `FAIL`.

Verification command (reversible):

```
cd /workspace && mv global-instructions/CLAUDE.md global-instructions/_x.md \
  && bash scripts/health-check.sh 2>&1 | grep -A4 'MD file consistency' ; \
  mv global-instructions/_x.md global-instructions/CLAUDE.md
```

Expected before the fix: a `✓` line rather than a `✗`.

**Confidence:** Medium-High (read from source; the `-lt 2` arithmetic and `warn`'s body are
unambiguous, but I did not execute the rename — the command above is offered for the orchestrator).

---

### F4 — the commit messages' cited evidence does not exercise the change

**Severity:** Low (process, not runtime)
**Legibility-target:** the `Verified:` block in `c56be81`
**Location:** commit `c56be81` body
**Closes-gaps:** G3, G5, G12
**Evidence** (verbatim from the commit body):

```
Verified: health-check failures are identical to the pre-change baseline (four,
all pre-existing); agents-gemini-sync, cross-reference-integrity, guide-index-sync
and link-claude-home-wiring all pass; the basename staging was simulated against
a file entry and a directory entry.
```

All four named suites pass, but none of them reads the moved file or the staging loop:

| Cited suite | What it actually reads | Touches the move? |
|---|---|---|
| `test/agents-gemini-sync.bats` | diffs `AGENTS.md` against `GEMINI.md` | no |
| `test/cross-reference-integrity.bats` | markdown links **inside** `workflows/ skills/ guides/ patterns/` whose **target** matches `(workflows\|skills\|guides\|patterns)/` — `global-instructions/…` matches neither filter, and `README.md` is not scanned | no |
| `test/guide-index-sync.bats` | `guides/` ↔ `guides/README.md` | no |
| `test/link-claude-home-wiring.bats` | `link-claude-home.sh` against a **stubbed** payload (`:37` `touch "$SRC/CLAUDE.md"`) | no — it stubs the artifact `install.sh` produces |

"the basename staging was simulated" is an uncommitted manual step; nothing in the repo replays
it. The "four, all pre-existing" health-check count is also wrong — there are six `✗` (the
fact-check established this) — so the baseline the `Verified:` line claims identity with is
mis-stated, even though the *set* is genuinely unchanged.

**Confidence:** High (suite bodies read in full; `cross-reference-integrity.bats:31`'s filter is
the decisive line).

---

### F5 — the "no silent extract-to-EOF" guard lost its meaning under multi-file concatenation

**Severity:** Low
**Legibility-target:** the D1 tech-debt guard
**Location:** `test/skills/code-review-soundness-crosscheck.bats:138-143`
**Closes-gap:** G9
**Evidence** (verbatim):

```
@test "the section-extraction end anchor exists (no silent extract-to-EOF)" {
  # Tech-debt D1 (2026-07-31): channel() extracts up to '### Rubric Status Line';
  # if that heading is renamed, extraction runs to EOF and scoped assertions can
  # false-green against unrelated text.
  echo "$SKILL_CONTENT" | grep -qE '^### Rubric Status Line' \
    || fail "channel() end anchor '### Rubric Status Line' missing - extraction unbounded"
```

When `SKILL_CONTENT` was one file, "the anchor exists" implied "the anchor is reachable from the
start anchor" for any section that precedes it. Across four concatenated files it does not: an
anchor could sit in a file ordered *before* the section, and the guard would still pass while
extraction ran to EOF. The setup comment ("Read in document order so section-extraction end
anchors still follow their sections") states the invariant the guard no longer checks. Today the
ordering happens to be correct — `### Soundness-Contradiction Channel` at concat 1755, `###
Rubric Status Line` at 1875 — so no assertion is currently false-greening on this path. F1 is
the case where the same class of drift already landed.

**Confidence:** High.

---

## Recommended Tests

#### T1 — pin the Important-Reminders extraction to `SKILL.md`

**Closes gaps:** G1
**Type:** contract
**Priority:** high
**File:** `test/skills/code-review-assurance-contract.bats:122-126`
**What it verifies:** that the Confirmed-Good contract is restated in `SKILL.md`'s
`## Important Reminders` section, and nowhere else counts.
**Key cases:**
- Change the pipeline to `sed -n '/^## Important Reminders/,$p' "$SKILL"` (the file, not the
  concatenation — this section is `SKILL.md`-resident by design and is its last section).
- Mutation check: deleting the two `Confirmed Good … claim, not an output` bullets from
  `SKILL.md` must turn the test red. Run the one-liner in F1.
- Guard against the class, not the instance: add
  `@test "Important Reminders is the last section of SKILL.md"` asserting
  `[ "$(grep -n '^## ' "$SKILL" | tail -1 | cut -d: -f2-)" = "## Important Reminders" ]`, so the
  `,$p` idiom stays sound if another section is appended.

**Setup needed:** none — `$SKILL` is already in `setup()`.

#### T2 — retarget the failing-verdict negative assertion at the concatenation

**Closes gaps:** G2
**Type:** contract
**Priority:** high
**File:** `test/skills/code-review-assurance-contract.bats:163-167`
**What it verifies:** the single-sample label appears only on `✅ PASSES REVIEW`.
**Key cases:**
- `run ! grep -qE "DOES NOT PASS.*$LABEL" <<<"$SKILL_CONTENT"` (likewise `CONDITIONAL PASS`).
- Add a positive control so the test cannot go vacuous again:
  `grep -qE 'DOES NOT PASS' <<<"$SKILL_CONTENT" || fail "no failing-verdict status line found —
  the negative assertion is scanning the wrong surface"`. This is the missing piece: the current
  form passes identically whether the rule holds or the text is absent.
- Declare `bats_require_minimum_version 1.5.0` at the top of the file to clear BW02 and make the
  `run !` support explicit.

**Setup needed:** none.

#### T3 — hermetic test for `install.sh` payload staging

**Closes gaps:** G3, G4, G5
**Type:** integration (shell, hermetic)
**Priority:** high
**File:** new — `test/install-payload-staging.bats` (model on `test/link-claude-home-wiring.bats`,
which already demonstrates the fake-`$SRC`/`$DEST`-under-`mktemp` convention)
**What it verifies:** every `CLAUDE_HOME_SRC` entry lands in the stage under its basename, and a
missing entry is loud.
**Key cases:**
- Build a fake repo root containing `global-instructions/CLAUDE.md`, `skills/`, `workflows/`,
  `guides/`, `patterns/`, `hooks/`, `scripts/`; run the staging loop; assert
  `[ -f "$STAGE/CLAUDE.md" ]` (payload **root**, not `$STAGE/global-instructions/CLAUDE.md`) and
  `[ -d "$STAGE/skills" ]`.
- Content identity: `cmp "$STAGE/CLAUDE.md" "$FAKE/global-instructions/CLAUDE.md"`.
- Missing-source path (G4): remove `global-instructions/CLAUDE.md`, re-run, assert the `WARNING`
  reaches stderr — and decide whether the installer should exit non-zero for the instructions
  file specifically. A payload that silently ships without the global process doc is the
  highest-blast-radius outcome in this diff; today it is a warning on stderr and exit 0.
- **Basename-collision guard:** assert no two `CLAUDE_HOME_SRC` entries share a basename, so a
  future entry cannot silently clobber another during `cp -r`.
- **Cross-script contract (G5):** extract `CLAUDE_HOME_SRC` from `install.sh` and `ENTRIES` from
  `link-claude-home.sh` and assert `basename` of every staged entry is a member of `ENTRIES`.
  Without this, moving the source again (or renaming) breaks the link silently at the next
  container start.

**Setup needed:** `mktemp -d` fake repo; the loop is small enough to source or replicate — prefer
extracting the staging loop into a function `install.sh` can be sourced for, if that is cheap;
otherwise re-implement the three lines and add a drift assertion that the test's copy matches
`install.sh:51-57`.

#### T4 — make a missing instructions file fail `health-check.sh`

**Closes gaps:** G6, G7, G8
**Type:** unit (shell)
**Priority:** high
**File:** production fix in `scripts/health-check.sh`; test in new
`test/health-check-global-md.bats`
**What it verifies:** the three sibling-comparison checks fail loudly rather than degrading to a
two-file comparison when `$GLOBAL_MD` is absent.
**Key cases:**
- Production change, `scripts/health-check.sh:237`: replace the bare `continue` with
  `{ fail "$mdfile not found — MD consistency cannot be checked"; continue; }`, mirroring the
  `warn`+`continue` at `:205` but escalated, since `$GLOBAL_MD` is the *reference* file
  (`files[0]`), not an optional sibling. Same at `:205` and `:871`: a missing `$GLOBAL_MD` is a
  `fail`; a missing `AGENTS.md`/`GEMINI.md` may stay a `warn`.
- Test: point a copy of the script at a fake `REPO_ROOT` whose `global-instructions/` is empty;
  assert the run exits non-zero and that `✓ All MD files reference the same workflows` does
  **not** appear.
- Positive control: same fake root *with* the file present — the check passes.
- Guard `$GLOBAL_MD` itself: `[ -f "$REPO_ROOT/$GLOBAL_MD" ]` as an explicit precondition near
  `:35`, so `GLOBAL_MD` being repointed at a typo is caught once instead of three times weakly.

**Setup needed:** `mktemp -d` fake root with `AGENTS.md`, `GEMINI.md`, `workflows/`,
`global-instructions/`. Note `health-check.sh` derives `REPO_ROOT` from `$0`'s directory, so the
test must place the script (or a symlink) under `$FAKE/scripts/`.

#### T5 — assert the single-load invariant directly

**Closes gaps:** G10
**Type:** contract
**Priority:** medium
**File:** new test in `test/cross-reference-integrity.bats` (or a small
`test/global-instructions-layout.bats`)
**What it verifies:** the property `c56be81` exists to establish — the instructions file is
loaded once.
**Key cases:**
- `[ ! -e "$REPO_ROOT/CLAUDE.md" ]` — no instructions file at the repo root (it would be loaded a
  second time as this project's own instructions).
- `[ -f "$REPO_ROOT/global-instructions/CLAUDE.md" ]` — it exists at its new home.
- `grep -q 'global-instructions/CLAUDE.md' "$REPO_ROOT/devcontainer-config/install.sh"` — the
  stager still sources it from there.

This is three lines and it is the only test that would have failed had the move been done wrong.
It is also the test whose absence made the `Verified:` block in F4 necessary.

**Setup needed:** none.

#### T6 — extend cross-reference-integrity to intra-skill links and anchors

**Closes gaps:** G12
**Type:** contract
**Priority:** medium
**File:** `test/cross-reference-integrity.bats:31`
**What it verifies:** every relative markdown link inside a content directory resolves, including
`references/…`, and every `#anchor` fragment matches a heading in the target.
**Key cases:**
- Drop the `grep -E '(workflows|skills|guides|patterns)/'` target filter in favour of "any
  non-http, non-bare-`#` target", keeping the existing `realpath -m` resolution relative to the
  source file. This picks up all 20 `references/*.md` links in `skills/code-review/SKILL.md`.
- Anchor resolution: for a target with a fragment, slugify the target file's `^#+ ` headings
  (lowercase, spaces→`-`, strip punctuation) and assert the fragment is in the set. The
  fact-check verified all 54 anchors by hand this round; this makes the next round free.
- Keep the `checked -gt 0` vacuity guard already at `:57`.
- Negative control: a fixture link to `references/does-not-exist.md` must fail.

**Setup needed:** none. Expect a first run to surface pre-existing dangling links elsewhere in
`skills/` — triage before merging, or scope the widened filter to `references/` first.

#### T7 — make the end-anchor guard prove ordering, not existence

**Closes gaps:** G9
**Type:** contract
**Priority:** medium
**File:** `test/skills/code-review-soundness-crosscheck.bats:138-143`, and mirror into
`code-review-executable-defect.bats` and `code-review-assurance-contract.bats`
**What it verifies:** each extraction helper's end anchor follows its start anchor in
`SKILL_CONTENT`, so no range silently runs to EOF.
**Key cases:**
- Replace the existence grep with a line-number comparison:
  `start=$(grep -n '^### Soundness-Contradiction Channel' <<<"$SKILL_CONTENT" | cut -d: -f1)`,
  same for the end anchor, then `[ "$end" -gt "$start" ]`.
- Bound the width: `[ $((end - start)) -lt 200 ]` catches an end anchor that drifted into a later
  file, which is the exact shape of the F1 regression.
- Add the same pair for `channel()` in `code-review-executable-defect.bats:38` and for
  `subsection()` in `code-review-assurance-contract.bats:41`.

**Setup needed:** none.

#### T8 — a drift guard for the reference-file split

**Closes gaps:** G11
**Type:** contract (drift-guard pattern, model on `test/sandbox-tool-map-drift.bats`)
**Priority:** low-medium
**File:** new `test/skills/code-review-reference-split.bats`
**What it verifies:** the F8 property — extracted material stays extracted and stays wired.
**Key cases:**
- The `## Reference files` list in `SKILL.md:81-92` names exactly the files present in
  `skills/code-review/references/` (set equality in both directions), so adding a reference file
  without announcing it, or announcing one that does not exist, goes red.
- Each `references/*.md` is linked from at least one *stage* in `SKILL.md` (not only from the
  `## Reference files` index) — the mechanism by which it is actually loaded.
- Non-residence: the rubric template fence (`**Use this exact format` … ```` ```markdown ````)
  occurs exactly once across `SKILL.md` + `references/`, so a future edit cannot re-inline it
  into `SKILL.md` and leave two divergent copies. `code-review-format-contract.bats:189` extracts
  that fence by position; a second copy would make the extraction ambiguous.

**Setup needed:** none.

#### T9 — a pressure-language regression guard

**Closes gaps:** G13
**Type:** contract
**Priority:** low
**File:** new test in `test/workflow-required-sections.bats` or a small
`test/skills/orchestrator-prose.bats`
**What it verifies:** the F2/F3 rewrite is not re-introduced, and the remaining holdout is visible.
**Key cases:**
- Assert `skills/{draft-review,matrix-analysis,code-review}/SKILL.md` contain
  `## Execution rules` and not `## Mandatory Execution Rules`.
- Assert none of the three contains `non-negotiable`, `No exceptions.`, or
  `under any circumstances`.
- `skills/ui-visual-review/SKILL.md:58` still has `## Mandatory Execution Rules`. Either bring it
  into the rewrite and include it in the assertion, or record the exemption explicitly in the
  test so the divergence is a decision rather than an oversight.
- Assert `patterns/orchestrated-review.md` has `#### Default output shape` and no
  `Default output cap`, and that no inheriting site still cites the old §-name.

**Setup needed:** none. Low priority because the property is stylistic — but it is the only thing
standing between the audit's work and the next author who reaches for a MUST block.

---

## What NOT to Test

- **The moved-block content of `global-instructions/CLAUDE.md`.** The fact-check verified the
  blocks are byte-identical apart from three link-depth fixes; a content test would duplicate
  `git diff -M` and would be brittle against every future edit. T5's three-line layout assertion
  is the durable part.
- **The three un-updated suites** (`code-review-context-delivery`,
  `code-review-factcheck-replication`, `lever-measurement-drift`). I checked each against the
  split and found no assertion that now passes or fails for the wrong reason:
  `context-delivery` reads `SKILL.md` and every anchor it uses (`For each of the three replicate
  agents:`, `**Size guard`, `Budget: 25,000 tokens`, the part-5/part-6 numbering) is still
  `SKILL.md`-resident, and no `runs its own git diff` / `pass scope, not diffs` instruction
  migrated into `references/` (`grep` over the three reference files returns only three
  `git diff --stat` mentions, none of them a self-read instruction);
  `factcheck-replication`'s three `sed` ranges all have both endpoints in `SKILL.md`; and
  `lever-measurement-drift`'s two `SKILL.md` greps (`~73%`, `225`) still hit. Re-pointing them at
  the concatenation would *introduce* the F1 class, not prevent it. Leave them reading `SKILL.md`.
- **`code-review-format.bats`.** It validates whichever rubric is newest in `docs/reviews/`; the
  split does not reach it, and `code-review-format-contract.bats` is the suite that owns the
  template contract.
- **Re-verifying the 97-test pass count or the six health-check `✗` lines.** Both were executed
  this round and are recorded in the header.
- **Unit-testing `health-check.sh`'s 20-odd other checks.** T4 is scoped to the three functions
  this diff touched; a general harness for the script is a separate, larger piece of work (see
  below).

---

## Coverage Gaps Beyond Current Scope

**1.** **`scripts/health-check.sh` has no test harness at all** (~1000 lines, ~20 checks, the
repo's primary CI signal). This diff changed three of its functions and the only verification
available was "run it and compare output". A minimal `test/health-check-lib.bats` that can invoke
one `check_*` function against a fake `REPO_ROOT` would make T4 cheap and unlock the same for
every future change. This is the single highest-leverage missing harness in the repo.

**2.** **`test/cc-isolated-functions.bats:716` carries a shellcheck SC2314 *error*** — a
`! grep -q …` in non-final position, which cannot fail the test under bats. The assertion there
is silently inert. `code-review-assurance-contract.bats:163-167` already documents the fix
(`run !`) in a comment; apply the same at the SC2314 site. Note the pre-existing shellcheck
failure is an `error`, not a warning, so it is currently masking a dead assertion, not just
style.

**3.** **The four re-pointed suites now duplicate an 8-line `cat`-and-comment block verbatim.**
`test/skills/helpers.bash` is already loaded by `code-review-format-contract.bats`; hoisting a
`code_review_skill_content()` helper there would mean the next surface change is one edit rather
than four, and would remove the risk that three suites are migrated and one is forgotten — which
is exactly the residue F2 documents.

**4.** **No suite asserts the `references/*.md` anchor targets resolve.** T6 covers this for the
code-review skill; the same slugify-and-check applies repo-wide, where the fact-check's
hand-verification of 54 anchors is currently the only control.

**5.** **`devcontainer-config/link-claude-home.sh`'s `ENTRIES` list is duplicated knowledge**
(`:47`) with no owner test outside T3's cross-check. A single source — `ENTRIES` read from a
shared file, or `install.sh` deriving its basenames from it — would remove the class.

---

## Summary

The highest-value test in this plan is **T3** (hermetic `install.sh` staging test): it closes the
only path in the diff whose failure mode is silent and total — a payload shipped with no global
instructions, warned to stderr and exited zero — and it is the step the commit message verified
by hand rather than by code. **T4** is a close second, because `health-check.sh` currently prints
a green MD-consistency line in exactly the scenario T3 guards against.

Against the four coverage questions: the split **did** weaken one contract suite —
`code-review-assurance-contract.bats:123`'s Important-Reminders assertion is now satisfiable by
`references/rubric.md`'s own heading and survives deletion of the text it checks (F1, proven by
mutation) — and left a second assertion scanning a file that no longer contains its subject
(F2). No other range helper in the seven suites widened as a result of this diff; the two
pre-existing widenings (`channel()` enclosing the Executable-Defect Channel, the executable-defect
cross-check enclosing Fragment-Composition) held the same shape at `2d679ce`. The three
un-updated suites are all still binding correctly and should stay pointed at `SKILL.md`. And none
of the four suites cited as evidence for the file move reads the moved file or the staging loop —
`cross-reference-integrity.bats:31`'s target filter excludes `global-instructions/` and
`references/` alike, and `link-claude-home-wiring.bats:37` stubs the very artifact `install.sh`
produces.

Residual risk after this plan: the prose-contract testing style is inherently a `grep` for a
clause, so it proves the words are present, never that the pipeline obeys them. T2's positive
control and T7's ordering assertion are the cheap partial answer — they make a *vacuous* test
impossible even when a *shallow* one is all that is available. The open question the enumeration
surfaced is whether a missing global-instructions file should be a `fail` or a hard `exit` in
`install.sh`: today it is a stderr warning, and the blast radius of getting that wrong is every
future session in every project.

---

## Goal-Alignment Note

**Answered:** All five coverage questions in the brief. (1) Yes — F1 and F2, with a mutation and a
`grep -c` as evidence; every range-extraction helper in all seven `code-review-*.bats` suites was
enumerated against the post-split heading map, and the two remaining widenings are shown to
pre-date the diff. (2) G3/G4/G5 (install.sh staging) and G6/G7/G8 (`GLOBAL_MD` indirection), each
with a cheapest-closing test (T3, T4). (3) Yes — F4 tabulates all four cited suites against what
they read; none touches the move. (4) No — the three un-updated suites all still bind correctly,
and the reasoning is recorded under *What NOT to Test* so the next author does not "fix" them
into the F1 failure mode. (5) Yes — T5 (single load, three lines) and T8 (reference material
non-resident).

**Out of scope:** The substance of the prompt-audit rewrites (whether removing pressure language
changes model behaviour) — that is an eval question, not a coverage question, and the commit for
`4d41add` already notes the orchestrator evals were not run because they need model calls.

**Escalate:** None. F1 and F2 are test-harness defects, not product defects; the contracts they
guard are still stated correctly in the skill.

**Questions:**
- Should `install.sh` exit non-zero when `global-instructions/CLAUDE.md` is missing, or is the
  stderr warning the intended contract? T3's third case is written either way, but the assertion
  depends on the answer.
- `skills/ui-visual-review/SKILL.md:58` still carries `## Mandatory Execution Rules`. Was it
  deliberately out of the F2/F3 scope (it is a critic, not an orchestrator), or missed? T9's
  third case should encode whichever answer is intended.
