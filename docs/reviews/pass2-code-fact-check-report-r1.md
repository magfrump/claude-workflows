Commit: 02d14b0

# Code Fact-Check Report

**Repository:** /workspace (claude-workflows), branch `integrate/q076-q080`
**Scope:** Partial — `git diff main...HEAD -- skills guides/skill-format-audit.md` at 02d14b0 (the Q-080 skill-description rewrite: 25 `skills/*/SKILL.md` frontmatter descriptions + new/extended `## When to use` bodies, and the F4 status note in `guides/skill-format-audit.md`), plus the three commit messages that touch those paths (f51db1c, c2fb944, 750178d). Everything else on the branch is context only (pass 1). Replicate r1.
**Checked:** 2026-09-27
**Total claims checked:** 15
**Summary:** 9 verified, 6 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read before checking. Four of its five entries are "a specific measured value quoted from an artifact that does not contain it". Every count and length on this branch (37,064 → 10,084; 364–438; 951–2969; batch ranges; "all 25") was therefore recomputed, not trusted. None matches a logged pattern: every figure recomputes exactly.

Scratch artifacts (scripts, captured outputs) are under `/tmp/claude-1000/-workspace/dbfd30e0-d8d5-40c1-8bac-572239fc44fd/scratchpad/pass2-r1/`, referred to below as `$S/`. Per the brief, no repo file other than this report was written, so captured outputs live in scratch rather than `docs/reviews/execution-logs/`.

Legibility target: Incorrect / Stale / Mostly accurate → **for-author**; Verified / Unverifiable → **for-orchestrator-synthesis**.

---

## Claim 1: "Displaced long-tail trigger phrases … moved into a `## When to use` section … nothing was supposed to be deleted" (trigger-phrase atom)

**Location:** `guides/skill-format-audit.md:20`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every double-quoted phrase in each of the 25 old (`main`) descriptions: each one appears somewhere in the corresponding new SKILL.md, case- and whitespace-normalized. Does not establish that unquoted prose (scope notes, caveats) survived (see Claim 2), or that phrases kept their original section or emphasis.
**Legibility target:** for-orchestrator-synthesis

Command: `python3 $S/cmp.py $S`, cwd `/workspace`, exit 0, at 2026-09-27T23:2xZ (the timestamp is in the first line of `$S/cmp.log`). The script pulls each old description with `git show main:skills/<s>/SKILL.md`, extracts every `"..."` phrase, and greps the new whole file. 24 of 25 skills report `missing=[]`. The three residues are not trigger phrases:

- **pre-mortem:** "the project failed — what does the post-incident review say?", "what could go wrong from here?", "this has failed — why?". These are illustrative framings, not user triggers. The body keeps their content: `skills/pre-mortem/SKILL.md:25` "is dead, six months from now. Perform the post-incident review." and `:36-37` "*"the project failed — what's the story?"* … *"this is the plan — what could go wrong?"*".
- **what-if-analysis:** "what if this assumption is wrong?", "what would need to be true for this to fail?". These are descriptive framings, and moves #1 and #4 carry them (`skills/what-if-analysis/SKILL.md:85` "### 1. Name the load-bearing assumptions", `:111` "### 4. Invert the confidence"). Treated as covered.
- **yglesias-critique:** "what's the 10-million -people test". This is a folding artifact of the old YAML line break. The new body has the normalized form: `skills/yglesias-critique/SKILL.md:33` `"what's the 10-million-people test"`.

**Evidence:** `$S/cmp.log`, `$S/cmp.py`, `skills/pre-mortem/SKILL.md:25`, `skills/pre-mortem/SKILL.md:36-37`, `skills/what-if-analysis/SKILL.md:85`, `skills/what-if-analysis/SKILL.md:111`, `skills/yglesias-critique/SKILL.md:33`

---

## Claim 2: "The displaced long-tail trigger phrases and caveats moved into a `## When to use` section" (scope-note / caveat / NOTE atom)

**Location:** `guides/skill-format-audit.md:20`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every sentence of the 25 old descriptions. Each was flagged by a 3-gram overlap scan (`$S/sent.py`, threshold <0.6) and then read by hand against the new file. Does not establish that every body section is equally prominent to a model at trigger time.
**Legibility target:** for-author

Every "If a (code-)fact-check report is provided…" instruction survived:
- In the 5 code critics, e.g. `skills/ui-visual-review/SKILL.md` When-to-use: "If a code-fact-check report is provided, use it as the foundation for what the code does and do not re-verify documented behavior."
- In the 5 draft critics as "Typically invoked by `draft-review`… If one is provided, use it as the factual foundation…".
- dependency-upgrade's special "sole source of execution results… cite its claim ids" rule, verbatim in its When-to-use.
- what-if-analysis's "didn't examine" guidance, at `skills/what-if-analysis/SKILL.md:52` "treat them as a map of *already-examined territory*. Explore the territory they didn't cover."

The low-overlap sentences are nearly all rewordings or "Produces a structured Markdown critique/report" lines whose content the body's output-format section already holds. For example, the section layouts at `skills/business-plan-critique-market-sizing/SKILL.md:273` "Use this exact section layout" and `skills/business-plan-critique-unit-economics/SKILL.md:137`.

One substantive narrowing was not carried over. The old design-space-situating description said *"Also trigger when RPI research turns up a decision touching authority, time, reversibility, formality, social structure, or legibility in ways the user has not named."* The body's pre-existing bullet is narrower, and the rewrite did not widen it:

```
// skills/design-space-situating/SKILL.md:28
- **Implicit defaults in RPI.** When RPI research surfaces a decision touching social structure, temporal commitment, or legibility in ways the user hasn't named, ...
```

The new "More trigger phrases" and "Output" bullets (`:29-30`) don't restore it. **Authority, reversibility and formality are no longer named anywhere as RPI triggers.** The `when:` field keeps only the generic "RPI surfaces an unnamed design-space default" (`:9`). Fix: add the three dimensions to `:28`.

**Evidence:** `$S/sent.log`, `$S/sent.py`, `skills/design-space-situating/SKILL.md:9`, `skills/design-space-situating/SKILL.md:28-30`, `skills/what-if-analysis/SKILL.md:52`, `skills/business-plan-critique-market-sizing/SKILL.md:273`, `skills/business-plan-critique-unit-economics/SKILL.md:137`

---

## Claim 3: "shared phrases ('review this draft', 'what am I missing', 'poke holes in this proposal') stay in every description that had them" / "no routing claim was reassigned"

**Location:** commit f51db1c (message body); commit c2fb944 (message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every quoted phrase that appeared in 2+ old descriptions, and every quoted phrase in a new description, checked against that skill's own old description. Does not establish routing behavior of the live skill loader.
**Legibility target:** for-orchestrator-synthesis

An inline `python3` scan (cwd `/workspace`, exit 0, run 2026-09-27; stdout reproduced here because it was short, and the script's logic is `$S/cmp.py` plus a cross-skill index) printed `'poke holes in this proposal' [('ai-personas-critique', True), ('yglesias-critique', True)]`, `'what am i missing' [('ai-personas-critique', True), ('cowen-critique', True), ('draft-review', True)]`, `'review this draft' [('cowen-critique', True), ('draft-review', True)]`, `'pre-mortem this' [('pre-mortem', True), ('what-if-analysis', True)]`. Every shared phrase is still in every new description that had it. The reverse check printed nothing under `--- new-desc quoted phrases absent from that skill old desc:`: no quoted phrase appeared in a skill's new description that its old description lacked. No trigger phrase moved between skills. Cowen and yglesias both keep "DEFAULT critic" (`skills/cowen-critique/SKILL.md:5` "The DEFAULT critic for a draft's reasoning"; `skills/yglesias-critique/SKILL.md:5` "The DEFAULT critic when a draft pairs a goal with a mechanism").

**Evidence:** `$S/cmp.py`, `skills/cowen-critique/SKILL.md:5`, `skills/yglesias-critique/SKILL.md:5`

---

## Claim 4: Every "not this — use X" / "distinct from X" line names an existing skill and preserves the old meaning

**Location:** `skills/*/SKILL.md:3-8` (all 25 descriptions)
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers all skill names in the 25 new descriptions against `ls skills`, and the carried-over pointers against the old text. Does not cover the five new pointers' sourcing (Claim 5) or the test-strategy pointer's precision (Claim 6).
**Legibility target:** for-orchestrator-synthesis

Every skill named in a new description exists among the 25 directories: code-fact-check, fact-check, code-review, cowen-critique, yglesias-critique, ai-personas-critique, what-if-analysis, pre-mortem, divergent-design, the three business-plan critics, security-reviewer, performance-reviewer, api-consistency-reviewer, architecture-review, matrix-analysis, and workflows/divergent-design.md. (paraphrased — no quote available because the check is a set comparison across 25 frontmatter blocks and a directory listing.)

The carried-over pointers match the old text:
- cowen: "mechanism feasibility → yglesias-critique, many lenses → ai-personas-critique", old "Distinct from yglesias-critique (… mechanisms) and ai-personas-critique (… multiple orthogonal lenses)".
- what-if: "is the argument good → cowen-critique or yglesias-critique", old "Differentiated from critique skills (cowen-critique, yglesias-critique)".
- perf, api, market-sizing, moat, unit-economics, draft-review, code-review and pre-mortem: the same check, with the same result.

The moat critic now names the market-sizing sibling: `skills/business-plan-critique-moat/SKILL.md:6` "market size → business-plan-critique-market-sizing". The old text said "a future market-sizing critic".

**Evidence:** `skills/cowen-critique/SKILL.md:4-6`, `skills/what-if-analysis/SKILL.md:4-6`, `skills/business-plan-critique-moat/SKILL.md:5-6`, `$S/*.old.txt`

---

## Claim 5: "Five skills gained a 'not this' line derived from guides/skill-trigger-guide.md 'Also consider' column"; commit f51db1c: "fact-check's disambiguation adds 'claims about code -> code-fact-check', taken from guides/skill-trigger-guide.md"; c2fb944: "ui-visual-review and security-reviewer … matching guides/skill-trigger-guide.md's 'Also consider' column"

**Location:** commits f51db1c, c2fb944, 750178d; `skills/fact-check/SKILL.md:6`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the sourcing of each new routing pointer against the trigger guide. Does not establish that the guide itself is correct.
**Legibility target:** for-author

Four of the five do match the "Also consider" column: `guides/skill-trigger-guide.md:13` "Security audit | `security-reviewer` | `code-review` …", `:21` test-strategy → `code-review`, `:22` dependency-upgrade → `code-review`, `:23` ui-visual-review → `code-review`.

**fact-check's pointer does not come from that column.** `:18` reads "Fact-check a draft | `fact-check` | `draft-review` (includes fact-check as Stage 1)". The code-fact-check routing comes from the guide's prose section instead: `:57` "**When to use which:** `code-fact-check` for anything in or about code. `fact-check` for prose…". So the commit's wording ("taken from guides/skill-trigger-guide.md") is correct. The brief's "Also consider column" description of it is not.

**The count of new pointers is six, not five.** design-space-situating also gained a new one: `skills/design-space-situating/SKILL.md:5` "Choosing among options → divergent-design". The old description never said this. It does match guide `:33` "Frame a decision before choosing | `design-space-situating` | `divergent-design`". The commit messages don't list it as a new disambiguation.

**Evidence:** `guides/skill-trigger-guide.md:13`, `guides/skill-trigger-guide.md:18`, `guides/skill-trigger-guide.md:21-23`, `guides/skill-trigger-guide.md:33`, `guides/skill-trigger-guide.md:57`, `skills/design-space-situating/SKILL.md:4-6`, `skills/fact-check/SKILL.md:5-6`

---

## Claim 6: "Inside a full PR review, code-review runs it." (test-strategy; the same phrasing is on dependency-upgrade, and ui-visual-review has "Within a full PR review, code-review invokes it.")

**Location:** `skills/test-strategy/SKILL.md:5`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers code-review's contextual-critic selection rules for test-strategy, dependency-upgrade and ui-visual-review. Does not establish Stage 1.5 gating interactions.
**Legibility target:** for-author

code-review runs these three only when their diff trigger fires:

```
// skills/code-review/SKILL.md:196-199
| Source files changed (`src/`, `lib/`, etc.) without corresponding test file changes ... | `test-strategy` | ...
| Dependency manifests changed (`package.json`, ...) | `dependency-upgrade` | ...
| Diff touches UI rendering code: ... | `ui-visual-review` | ...
```

For dependency-upgrade and ui-visual-review, the skill's own trigger is the same condition (a manifest change, UI code), so the unconditional wording is accurate in context. **test-strategy is the exception.** code-review runs it only when source changes lack test changes. A PR that already has tests, where the user asks "what's the test plan", gets no test-strategy from code-review. Precise version: "Inside a full PR review, code-review runs it when source changes lack tests."

**Evidence:** `skills/code-review/SKILL.md:34-37`, `skills/code-review/SKILL.md:196-199`, `skills/test-strategy/SKILL.md:4-6`, `skills/dependency-upgrade/SKILL.md:4-6`, `skills/ui-visual-review/SKILL.md:5-6`

---

## Claim 7: Front-loading: "The purpose and the disambiguation fall inside the first ~250 characters in all but a few cases; the trigger list starts there and finishes by ~440."

**Location:** `guides/skill-format-audit.md:20`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers character offsets of the routing clause and of `Triggers:` in each parsed description. Does not establish where the live skill listing actually truncates.
**Legibility target:** for-author

An inline `python3` offset scan (cwd `/workspace`, exit 0, 2026-09-27; reads `$S/<skill>.new.txt`) found that every routing clause starts before char 250. Examples: what-if 129, yglesias 148, moat 150, design-space-situating 150, fact-check 124, architecture-review's SKIP gate 187 and its "Security, performance…" line 219. The one partial overrun: yglesias's second pointer ("many lenses → ai-personas-critique") runs from about 226 to about 290.

Four skills have no "not this" line at all: arithmetic-eval, matrix-analysis, self-eval, tech-debt-triage. Their old descriptions had none either, so this is a gap rather than a loss.

**The `Triggers:` list starts after char 250 in six skills:** architecture-review @285, arithmetic-eval @300, design-space-situating @289, business-plan-critique-moat @263, what-if-analysis @275, yglesias-critique @280. In those six, a ~250-char truncation hides every main trigger phrase. The brief's "first ~250 chars carry … the main triggers" doesn't hold for them. The guide sentence ("the trigger list starts there") describes this correctly.

The audit table row `guides/skill-format-audit.md:198` "F4: Front-load descriptions within 250 chars … **Done**" overstates it. Descriptions are 364–438 chars. Purpose and routing are within 250; the triggers are not, for those six. The last trigger phrase ends at up to char 438 in every skill.

**Evidence:** `$S/*.new.txt`, `guides/skill-format-audit.md:20`, `guides/skill-format-audit.md:198`

---

## Claim 8: "runs 364–438 characters (was 951–2969)"; brief "37,064 → 10,084 chars"; "Resolved for all 25 skills"

**Location:** `guides/skill-format-audit.md:20`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the YAML-folded (space-joined) description lengths for main and HEAD. Does not establish lengths under a different folding convention.
**Legibility target:** for-orchestrator-synthesis

`$S/cmp.log` shows each old and new length. The minimum new length is self-eval at 364 and the maximum is yglesias-critique at 438. Old lengths run from fact-check at 951 to market-sizing at 2969. The final line reads `totals 37064 10084`. There are 25 skill directories and 25 were changed. `perl $S/y.pl` re-parses with CPAN::Meta::YAML and gets the same lengths (`$S/yaml.log`, exit 0).

**Evidence:** `$S/cmp.log`, `$S/yaml.log`

---

## Claim 9: Per-batch length ranges in commit messages: f51db1c "~380-440 characters (was 951-2969)"; c2fb944 "~380-430 characters"

**Location:** commits f51db1c, c2fb944
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the lengths of the skills each commit lists. Does not cover batch 3, which states no range.
**Legibility target:** for-orchestrator-synthesis

- Batch 1: cowen 425, yglesias 438, ai-personas 398, moat 413, unit-economics 397, market-sizing 388, fact-check 382, code-fact-check 388 → 382–438. Its old lengths run 951–2969. ✓
- Batch 2: code-review 414, draft-review 404, matrix 382, security 426, performance 418, api 397, architecture 408, ui-visual 396 → 382–426. ✓
- The batch file lists (9 + 8 + 8 = 25) cover every skill exactly once.

(paraphrased — no quote available because the figures are per-skill rows of `$S/cmp.log`.)

**Evidence:** `$S/cmp.log`

---

## Claim 10: YAML: every frontmatter parses and the folded `description: >` reads back as intended

**Location:** `skills/*/SKILL.md:1-~25`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `description` scalar of all 25 files under two independent parsers and the repo's health-check. Does not establish that other frontmatter keys parse under a strict YAML 1.2 parser (see the note below).
**Legibility target:** for-orchestrator-synthesis

Command: `perl $S/y.pl $S` (CPAN::Meta::YAML), cwd `/workspace`, exit 0. For 24 files it prints `parsed … match_manual=yes`: the parsed description equals the hand-folded one from `$S/cmp.py`. None of the rewritten descriptions contains a character that breaks folding.

The 25th file, code-fact-check, fails in this parser, but on an **unchanged, pre-existing** `adaptation-latitude` item. It is a plain scalar containing ": " ("…a refuted mechanism: verdict compound claims…"). That line is on `main` too (`git show main:skills/code-fact-check/SKILL.md | grep -c "refuted mechanism: verdict"` → 1) and is outside this diff.

`scripts/health-check.sh` (cwd `/workspace`, started 2026-09-27T23:1xZ) printed "── Skill YAML frontmatter ──" followed by 25 `✓` lines and "✓ 25 skill(s) checked" (`$S/health.log:4-31`). The full script was then killed by the replicate's own `timeout 300` in its later test phase (exit 124, with no `✗` line before the kill), so its overall exit status was not observed.

**Evidence:** `$S/yaml.log`, `$S/y.pl`, `$S/health.log`

---

## Claim 11: Tests that pin description text still hold ("arithmetic-eval keeps 'bare arithmetic' and 'scientific' in the description because test/skills/arithmetic-eval-format.bats asserts on them")

**Location:** commit 750178d; `test/skills/arithmetic-eval-format.bats:50-56`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `test/skills/*.bats` file that references SKILL.md, excluding `*-eval.bats` (they call models). Does not cover the skipped report-grading tests, which have no generated reports.
**Legibility target:** for-orchestrator-synthesis

The test asserts on the frontmatter:

```
# test/skills/arithmetic-eval-format.bats:51-55
  fm=$(echo "$SKILL_CONTENT" | awk '/^---$/ { n++; next } n==1 { print } n>=2 { exit }')
  echo "$fm" | grep -qiE '(bare arithmetic|simple.*arithmetic|numbers and operators)'
  echo "$fm" | grep -qiE 'scientific'
```

The new description has both: `skills/arithmetic-eval/SKILL.md:5-6` "Two modes: bare arithmetic via a safe AST evaluator, and scientific computing".

Command: `bats $(rg -l SKILL.md test/skills --glob '*.bats' | grep -v -- -eval.bats)`, run through bash, cwd `/workspace`, started 2026-09-27T23:16:02Z, `exit=0`. Result: 648 tests, 0 `not ok`, 226 real passes (the rest skip for lack of generated reports). That includes "description mentions both modes", "all skills have required frontmatter fields" and the divergent-design router body-contract tests. `rg -n description test` found no other test that pins description wording.

**Evidence:** `$S/bats-skills.log`, `test/skills/arithmetic-eval-format.bats:50-56`, `skills/arithmetic-eval/SKILL.md:4-8`

---

## Claim 12: arithmetic-eval description: "scientific computing (numpy, scipy, pandas, sympy, statistics) behind an allowlist checker"

**Location:** `skills/arithmetic-eval/SKILL.md:6-7`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the description's summary of Mode 2's safety boundary against the body. Does not re-verify `check.py` itself.
**Legibility target:** for-author

The old description ended the Mode 2 clause with "…then run under OS confinement". The new one drops that, leaving the checker as the only named safeguard. The body says the checker is not the boundary:

```
# skills/arithmetic-eval/SKILL.md:32
3. **Mode 1 is sound; the Mode 2 static gate is only a speed-bump.** ... The **OS sandbox is Mode 2's actual boundary**; the gate is defense-in-depth in front of it.
```

The OS-confinement fact is kept in the When-to-use body (`:24` "…then run under OS confinement"), so nothing is deleted. But "behind an allowlist checker" presents the speed-bump as the gate. Precise version: "…behind an allowlist checker and OS sandbox".

**Evidence:** `skills/arithmetic-eval/SKILL.md:6-7`, `skills/arithmetic-eval/SKILL.md:24`, `skills/arithmetic-eval/SKILL.md:32`

---

## Claim 13: New descriptions' claims about their bodies (modes, outputs, orchestration lists) match the SKILL.md bodies

**Location:** `skills/*/SKILL.md:3-8`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the checkable body claims in the descriptions:
- ai-personas "3-4 … catalog of 17"
- self-eval "five auto-rated dimensions, four human prompts … docs/reviews/self-eval-{target}.md"
- test-strategy "named gaps (G1, G2...)"
- code-review's and draft-review's pipelines, draft-review's critic list and ensemble mode
- ui-visual "WCAG 2.2"
- divergent-design "Route … into workflows/divergent-design.md"
- pre-mortem "3–5 … root causes"

Does not establish claims marked Mostly accurate elsewhere (Claims 6, 12). It also does not cover code-review's Stage 1.5 gating: the description's "security, performance, API-consistency … in parallel" does not say that Stage 1.5 can gate core critics off (`skills/code-review/SKILL.md:685`). That wording is pre-existing in the body (`:171` "Core critics (always run in Stage 2)").
**Legibility target:** for-orchestrator-synthesis

- `skills/ai-personas-critique/SKILL.md:58` "Defines 17" and `:78` "## Step 3: Select 3-4 Personas".
- `skills/self-eval/SKILL.md:233` "Save the evaluation report to `docs/reviews/self-eval-{target-name}.md`." and `:257` "All five rows are required".
- `skills/test-strategy/SKILL.md:98` "- **G1** — path/to/file.ext:LINE-LINE…".
- `skills/pre-mortem/SKILL.md:158` "Generate 3–5 such narratives."
- `skills/draft-review/SKILL.md:110` "If the user requested ensemble mode…".
- `skills/ui-visual-review/SKILL.md:33` "**WCAG 2.2** — visible focus indicators…".
- The divergent-design body hands off to "`workflows/divergent-design.md`".
- The code-review stages are sequential, per `:64-67` "The stages are sequential… Finish Stage 1 (code fact-check)… before dispatching Stage 2".

**Evidence:** `skills/ai-personas-critique/SKILL.md:58`, `skills/ai-personas-critique/SKILL.md:78`, `skills/self-eval/SKILL.md:233`, `skills/self-eval/SKILL.md:257`, `skills/test-strategy/SKILL.md:98`, `skills/pre-mortem/SKILL.md:158`, `skills/draft-review/SKILL.md:110`, `skills/ui-visual-review/SKILL.md:33`, `skills/code-review/SKILL.md:64-67`, `skills/code-review/SKILL.md:171`, `skills/code-review/SKILL.md:685`

---

## Claim 14: moat critic "now names business-plan-critique-market-sizing instead of 'a future market-sizing critic' (the sibling exists)"

**Location:** commit f51db1c; `skills/business-plan-critique-moat/SKILL.md:6`
**Type:** Reference / Staleness
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the description change and the sibling's existence. Also covers the bodies of the moat and unit-economics skills, which still call it "future". Those body lines are unchanged by this diff.
**Legibility target:** for-author

The description change is accurate: `skills/business-plan-critique-market-sizing/` exists, and the moat description names it. The unit-economics description also drops "the future". **Both bodies still call the sibling "future", contradicting their new descriptions.** Those lines are pre-existing and untouched by this diff:

```
// skills/business-plan-critique-moat/SKILL.md:45-46
- **Market-sizing critique** (TAM/SAM/SOM realism, segment definition, addressable customer
  count) — future `business-plan-critique-market-sizing` skill.
```
```
// skills/business-plan-critique-unit-economics/SKILL.md:41
- **Market-sizing critique** (TAM/SAM/SOM realism, segment definition, addressable customer count) — future `business-plan-critique-market-sizing`.
```

Fix: drop "future" at both locations.

**Evidence:** `skills/business-plan-critique-moat/SKILL.md:5-6`, `skills/business-plan-critique-moat/SKILL.md:45-46`, `skills/business-plan-critique-unit-economics/SKILL.md:41`

---

## Claim 15: "appended to the existing section in design-space-situating, pre-mortem and what-if-analysis"; each SKILL.md has a `## When to use` section

**Location:** `guides/skill-format-audit.md:20`; commit 750178d
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the section structure of all 25 bodies. Does not assess prose quality.
**Legibility target:** for-author

Every one of the 25 files has exactly one heading matching `^## When to use` (case-insensitive grep count = 1 each). The three "appended" cases are real: design-space-situating's pre-existing `## When to use` got two bullets at `:29-30`, and the pre-mortem and what-if-analysis `## When to Use This Skill (vs. …)` sections got a paragraph each.

One small flaw. pre-mortem's appended paragraph opens "More trigger phrases:" but includes "give me the failure stories", which is already in the description:

```
// skills/pre-mortem/SKILL.md:55
More trigger phrases: "it's six months later and this didn't work — what happened", "give me the failure stories", "what does the incident report say if this goes wrong". ...
```

(`skills/pre-mortem/SKILL.md:7` description: `"give me the failure stories".`) It's harmless duplication, but the "More" label is inaccurate for that item. design-space-situating's "More trigger phrases" bullet (`:29`) likewise repeats "frame this before we choose" and "are we even framing this right" from its description.

**Evidence:** `skills/pre-mortem/SKILL.md:7`, `skills/pre-mortem/SKILL.md:55`, `skills/design-space-situating/SKILL.md:29`, `skills/what-if-analysis/SKILL.md:48`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 2** (`skills/design-space-situating/SKILL.md:28`): the old RPI trigger dimensions "authority, … reversibility, formality" were dropped. The body bullet names only social structure, temporal commitment and legibility. Add the three back.
- **Claim 5** (commits / brief): fact-check's code-fact-check pointer comes from the guide's "When to use which" prose (`guides/skill-trigger-guide.md:57`), not the "Also consider" column (`:18` says draft-review). There are also six new routing pointers, not five: design-space-situating gained "Choosing among options → divergent-design".
- **Claim 6** (`skills/test-strategy/SKILL.md:5`): code-review runs test-strategy only when source changes lack test changes. Qualify "Inside a full PR review, code-review runs it".
- **Claim 7** (`guides/skill-format-audit.md:198`): in six skills (architecture-review, arithmetic-eval, design-space-situating, moat, what-if-analysis, yglesias-critique) the trigger list starts at char 263–300. "Front-load within 250 chars — Done" holds for purpose and routing, not triggers.
- **Claim 12** (`skills/arithmetic-eval/SKILL.md:6-7`): "behind an allowlist checker" drops the OS sandbox, which the body names as Mode 2's actual boundary (`:32`).
- **Claim 14** (`skills/business-plan-critique-moat/SKILL.md:46`, `skills/business-plan-critique-unit-economics/SKILL.md:41`): these bodies still call `business-plan-critique-market-sizing` "future", contradicting the new descriptions. The lines are pre-existing, not part of this diff.
- **Claim 15** (`skills/pre-mortem/SKILL.md:55`): the "More trigger phrases" paragraph repeats a phrase already in the description. Cosmetic.

### Unverifiable
(none)

---

## Goal-Alignment Note

- **Success criterion (verbatim):** A code-fact-check report saved at the dispatch path in the skill's schema, covering the claims above, with a Goal-Alignment Note.
- **Answered:** Every claim family in the brief has a verdict: nothing-lost for triggers and for caveats/NOTEs, routing preserved, front-loading offsets, description-vs-body accuracy, YAML parse, pinned tests, and the F4 note plus commit-message counts. All counts recompute exactly (37,064 → 10,084; 364–438; 951–2969; batch ranges; 25 skills). No trigger phrase was lost or moved between skills. The only substantive content loss is design-space-situating's three RPI dimensions (Claim 2).
- **Out of scope:**
  - The pre-existing YAML ": " plain scalar in code-fact-check's `adaptation-latitude` (Claim 10). It is not in the diff, but a strict YAML parser reads it as a mapping; worth a separate look.
  - The pre-existing "future" wording in two bodies (Claim 14) is flagged but predates the diff.
  - Scripts, hooks and test harness on the branch (pass 1).
- **Escalate:**
  - The full `scripts/health-check.sh` run hit this replicate's `timeout 300` (exit 124) during its later bats phase. Only its skill-frontmatter section (25 ✓) was observed, with no `✗` lines before the kill. The orchestrator may want its final exit status from another replicate or a re-run.
  - Whether "Done" is the right F4 status given six skills with triggers past char 250 is a judgment call for the author.
