Commit: 02d14b0

# Code Fact-Check Report

**Repository:** /workspace (claude-workflows), branch `integrate/q076-q080`
**Scope:** Partial. Review pass 2 of 2: `git diff main...HEAD -- skills guides/skill-format-audit.md` at 02d14b0 (the 25 `skills/*/SKILL.md` description rewrites, the new/extended `## When to use` sections, the audit F4 status note) plus commit messages f51db1c, c2fb944, 750178d. Everything else on the branch (cc-isolated.sh, hooks, test harness) is context only (pass 1). Delivery mode: self-read.
**Checked:** 2026-09-27
**Total claims checked:** 16
**Summary:** 9 verified, 6 mostly accurate, 1 stale, 0 incorrect, 0 unverifiable

Replicate: r3. Scratch scripts and captured output are under `/tmp/claude-1000/-workspace/dbfd30e0-d8d5-40c1-8bac-572239fc44fd/scratchpad/pass2-r3/` (below, `$S`). Nothing in the repo was modified except this report. Per the brief, `docs/reviews/hallucination-patterns.md` was read (no entry matches a claim here; the closest are the commit-message count patterns, and every count re-checked below held). It was **not** appended to, because the brief allows no repo edit beyond this report and there are no Incorrect verdicts anyway.

Method notes (shared by several claims):
- `$S/extract.py` parses each folded `description: >` block by hand. On both `main` and HEAD it checks indentation and tabs, folds the lines, measures the length and compares the top-level frontmatter key lists. Output: `$S/logs/extract.log`.
- `$S/phrases.py` pulls every double-quoted phrase from each OLD description (245 phrases in all) and checks whether it appears anywhere in the NEW SKILL.md, whitespace-normalized. Output: `$S/logs/phrases.log`.
- `$S/nomove.py` pulls every quoted phrase from each NEW description (135) and checks that it came from the same skill's OLD file. Output: `$S/logs/nomove.log`.
- The unquoted remainder of each old description was compared to the new file with a clause-level word-coverage scan (`$S/clauses.py`). I then read all 1,205 lines of the diff by hand.

---

## Claim 1: "F4 (description length) — Resolved for all 25 skills … runs 364–438 characters (was 951–2969)" (and the brief's "37,064 → 10,084 chars")

**Location:** `guides/skill-format-audit.md:20`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the character counts (Python `len`, code points) of all 25 folded descriptions on `main` and at HEAD; does not establish the byte lengths (the `→` arrows count 3 bytes each, which puts four skills 4–6 higher in bytes, e.g. yglesias 442 bytes) or what length the live skill listing actually truncates at.

The folded descriptions measure as follows. Minimum new is `self-eval 1207 364`; maximum new is `yglesias-critique 2069 438`; minimum old is `fact-check 951 382`; maximum old is `business-plan-critique-market-sizing 2969 388`. The totals line reads:

```
total 37064 10084 364 438 951 2969
```
(`$S/logs/extract.log`, final line)

All 25 skills changed (`26 files changed, 309 insertions(+), 428 deletions(-)` including the guide).

Command: `python3 $S/extract.py $S/desc.json` · cwd `/workspace` · exit 0 · 2026-09-27T16:18:32-07:00.

**Evidence:** `guides/skill-format-audit.md:20`, `$S/logs/extract.log`

---

## Claim 2: "Each description now leads with the purpose, then the "not this, use X" line, then the main trigger phrases"

**Location:** `guides/skill-format-audit.md:20`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the order of purpose / disambiguation / triggers in each of the 25 new descriptions; does not establish whether a disambiguation line is warranted for the skills that lack one.

21 of 25 descriptions follow the purpose → "not this" → triggers order. Four have no "not this, use X" line:
- **arithmetic-eval.** The description goes straight from purpose to modes to triggers: `Two modes: bare arithmetic via a safe AST evaluator, and scientific computing … Triggers: "compute"` (`skills/arithmetic-eval/SKILL.md:6-8`).
- **matrix-analysis.** `Prefer it over an ad-hoc pros/cons list; also a sub-procedure of divergent-design and RPI plans.` (`skills/matrix-analysis/SKILL.md:5-6`) This is a relationship, not a route-away.
- **self-eval.** `Score one skill or workflow against docs/evaluation-rubric.md (five auto-rated dimensions, four human prompts) into docs/reviews/self-eval-{target}.md. Triggers:` (`skills/self-eval/SKILL.md:4-5`)
- **tech-debt-triage.** `Prefer it over an ad-hoc opinion on "is fixing this worth it"; compares many items via the matrix-analysis pattern.` (`skills/tech-debt-triage/SKILL.md:5-6`) This is a method reference, not a route-away.

None of the four had a disambiguation in its OLD description either, so nothing was lost (paraphrased — no quote available because the claim covers absence of text in four old descriptions, checked via `git show main:skills/<s>/SKILL.md`). The precise version: "each description leads with the purpose, then (where the skill has a sibling to route to) the 'not this' line…". The same imprecision is in c2fb944 (Claim 15b).

**Evidence:** `skills/arithmetic-eval/SKILL.md:3-8`, `skills/matrix-analysis/SKILL.md:3-8`, `skills/self-eval/SKILL.md:3-7`, `skills/tech-debt-triage/SKILL.md:3-8`

---

## Claim 3: "The purpose and the disambiguation fall inside the first ~250 characters in all but a few cases; the trigger list starts there and finishes by ~440."

**Location:** `guides/skill-format-audit.md:20`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the character offsets of the disambiguation span and the `Triggers:` token in each new description; does not establish what the live listing's real truncation point is. The "~250" budget is taken from the brief.

Five descriptions (20% of the set) run their disambiguation past 250. In each, the line *starts* before 250 and the last routed skill name ends past it. Offsets are 0-based [start, end), from the Python `str.find` lookups in `$S/logs/offsets.log`, rerun inline:

| Skill | Disambiguation span | `Triggers:` at |
|---|---|---|
| architecture-review | `Security, performance and API naming belong to their own critics.` 219–284 | 285 |
| design-space-situating | `Choosing among options → divergent-design; … escalating here only if it fails.` 150–288 | 289 |
| yglesias-critique | `argument rigor → cowen-critique, many lenses → ai-personas-critique.` 211–279 | 280 |
| what-if-analysis | `Failure already happened (…) → pre-mortem; is the argument good → cowen-critique or yglesias-critique.` 129–274 | 275 |
| business-plan-critique-moat | `market size → business-plan-critique-market-sizing.` 211–262 | 263 |

In the other 20, the disambiguation ends by 239 and `Triggers:` starts between 152 and 240. arithmetic-eval has no disambiguation; its `Triggers:` starts at 300. The longest description ends at 438, so "finishes by ~440" holds. "All but a few" is a fair word for 5 of 25, but a reader would not guess it means one in five. In the architecture-review and design-space-situating cases, the part past 250 is the actual route target ("critics.", "only if it fails."). The precise version: "…in 20 of 25; in the other five (architecture-review, design-space-situating, what-if-analysis, yglesias-critique, business-plan-critique-moat) the disambiguation starts before 250 and ends at 262–288."

Command: `python3 -` (heredoc computing offsets over `$S/desc.json`) · cwd `/workspace` · exit 0 · 2026-09-27T16:13-07:00 (approx.; output captured to `$S/offsets.out` → `$S/logs/offsets.log`).

**Evidence:** `guides/skill-format-audit.md:20`, `$S/logs/offsets.log`, `$S/desc.json`

---

## Claim 4: "The displaced long-tail trigger phrases and caveats moved into a `## When to use` section in each SKILL.md body (appended to the existing section in design-space-situating, pre-mortem and what-if-analysis)" — i.e. nothing was deleted

**Location:** `guides/skill-format-audit.md:20`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every quoted phrase in all 25 old descriptions (script), a manual clause-by-clause read of all 25 old descriptions against the new files, and the placement of the new text. It does not establish that the new body wording is behaviorally equivalent where old text was paraphrased (e.g. "evaluates whether the new surface matches the conventions consumers have already learned" → body intro `check whether the changed API is consistent with patterns already established`, `skills/api-consistency-reviewer/SKILL.md:22-23`).

**Placement.** 22 skills gained a new `## When to use` section (e.g. `+## When to use` at `skills/cowen-critique/SKILL.md:28`). The three named exceptions append to an existing section:
- design-space-situating: `- **More trigger phrases.** …` and `- **Output.** …` (`skills/design-space-situating/SKILL.md:29-30`), under its existing `## When to use`.
- pre-mortem: `More trigger phrases: "it's six months later …` (`skills/pre-mortem/SKILL.md:57`), under `## When to Use This Skill (vs. what-if-analysis)`.
- what-if-analysis: `In scope: a plan, design, migration, …` (`skills/what-if-analysis/SKILL.md:48`), under `## When to Use This Skill (vs. pre-mortem)`.

The only removed lines in the whole skills diff are description-continuation lines (paraphrased — no quote available because the claim covers absence of code: `git diff main...HEAD -- skills | grep '^-' | grep -v '^---' | grep -vc '^-  '` → `0`). Frontmatter key lists are unchanged in all 25 files (`$S/logs/extract.log`: no `KEYS DIFF`). All five "if a code-fact-check report is provided…" NOTEs and all six "if a fact-check report is provided…" NOTEs survive in the bodies, e.g. `If a code-fact-check report is provided, it is the sole source of execution results` (`skills/dependency-upgrade/SKILL.md:24`).

**Quoted trigger phrases.** 239 of 245 old quoted phrases appear verbatim in the new file (`245 6` in `$S/logs/phrases.log`). The 6 misses:
- yglesias `"what's the 10-million -people test"` is a YAML folding artifact in the OLD text: `"what's the 10-million` / `-people test"` across a line break (`git show main:skills/yglesias-critique/SKILL.md:20-21`). The new text fixes it: `"what's the 10-million-people test"` (`skills/yglesias-critique/SKILL.md:33`). Not a loss.
- pre-mortem `"the project failed — what does the post-incident review say?"`, `"what could go wrong from here?"` and `"this has failed — why?"` were descriptive framings, not user triggers. They survive in substance: `the project failed — what's the story?` (`skills/pre-mortem/SKILL.md:34`), `Perform the post-incident review.` (`:25`), and the mechanical-test table at `:37-42`. Not a material loss.
- what-if-analysis `"what if this assumption is wrong?"` survives in substance as the trigger `"what if this assumption doesn't hold"` (`skills/what-if-analysis/SKILL.md:48`). **`"what would need to be true for this to fail?"` is gone from the file entirely** (paraphrased — no quote available because the claim covers absence of text: `grep -n -i "need to be true" skills/what-if-analysis/SKILL.md` returns nothing; on `main` it was only at description line 7).

**Unquoted scope notes lost or narrowed** (manual read):
1. **cowen-critique.** The draft-genre list `(blog post, essay, article, op-ed, research note, or similar written piece)` (`git show main:skills/cowen-critique/SKILL.md:6-7`) appears nowhere in the new file (paraphrased — no quote available because the claim covers absence: `grep -n -i -E "blog post|op-ed|research note"` hits nothing). The new description says only `critique of a written argument` (`skills/cowen-critique/SKILL.md:4`).
2. **fact-check.** The artifact list `(blog post, essay, article, policy piece, or any prose with checkable assertions)` (`git show main:skills/fact-check/SKILL.md:4-5`) is gone (same grep, no hits outside unrelated source-quality prose at `:262`, `:312`). Its routing substance is still in `requires: A draft (prose or document)` (`skills/fact-check/SKILL.md:16`) and in guides/skill-trigger-guide.md:57.
3. **design-space-situating.** The old RPI trigger `a decision touching authority, time, reversibility, formality, social structure, or legibility` (`git show main:skills/design-space-situating/SKILL.md:13-14` of the description) now survives only as the pre-existing body line `a decision touching social structure, temporal commitment, or legibility` (`skills/design-space-situating/SKILL.md:28`). **Authority, reversibility and formality dropped out of the RPI trigger.**
4. Minor rewordings, none of which change routing: ai-personas `This skill provides breadth and surprise.` → `with breadth` (`skills/ai-personas-critique/SKILL.md:7`); what-if `systematically explores … stress-tests the highest-confidence assumptions` → body `High-confidence assumptions are most dangerous …` (`skills/what-if-analysis/SKILL.md:119`).

Every other old clause was found in the new description or body. That includes all the NOTEs, section layouts (e.g. `## TAM Definition Assessment` … `## Overall Assessment`, `skills/business-plan-critique-market-sizing/SKILL.md:277-283`), and the DD `(diverge → diagnose → match → decide)` in the body at `skills/divergent-design/SKILL.md:40`. The claim is right in mechanism and nearly complete. The imprecision: one framing question and three scope notes (items 1–3) were dropped rather than moved.

Commands: `python3 $S/phrases.py` · cwd `/workspace` · exit 0 · 2026-09-27T16:18:32-07:00; `python3 $S/extract.py $S/desc.json` · same.

**Evidence:** `guides/skill-format-audit.md:20`, `$S/logs/phrases.log`, `$S/logs/extract.log`, `skills/what-if-analysis/SKILL.md:48`, `skills/cowen-critique/SKILL.md:1-35`, `skills/fact-check/SKILL.md:1-52`, `skills/design-space-situating/SKILL.md:24-30`, `skills/pre-mortem/SKILL.md:25-57`

---

## Claim 5: "No de-overlap: the cowen/yglesias "DEFAULT critic" claims and phrases shared by several skills were kept as they were." (also f51db1c: shared phrases "review this draft", "what am I missing", "poke holes in this proposal" stay in every description that had them)

**Location:** `guides/skill-format-audit.md:20`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three shared phrases named in f51db1c and the two DEFAULT-critic claims across the new descriptions; does not establish that every *other* phrase shared between skills stayed at the same prominence (some shared long-tail phrases, e.g. draft-review's `"multiple perspectives on this piece"`, moved to the body, as the design intended).

- Both "DEFAULT" claims are kept. Cowen: `The DEFAULT critic for a draft's reasoning` (`skills/cowen-critique/SKILL.md:5`). Yglesias: `The DEFAULT critic when a draft pairs a goal with a mechanism` (`skills/yglesias-critique/SKILL.md:5`).
- `"review this draft"` is in cowen `:6` and draft-review `:7`.
- `"what am I missing"` is in cowen `:7`, ai-personas `:7`, and draft-review `:7-8`.
- `"poke holes in this proposal"` is in ai-personas `:8` and yglesias `:6`.

These quotes are from the description blocks at `skills/<s>/SKILL.md:3-9`, as listed in `$S/desc.json`. Each skill that had these phrases in its old description still has them in the new one (paraphrased — no quote available because the cross-check spans 5 files' old and new descriptions; see `$S/logs/phrases.log`, 0 misses for these skills).

**Evidence:** `skills/cowen-critique/SKILL.md:3-9`, `skills/yglesias-critique/SKILL.md:3-9`, `skills/ai-personas-critique/SKILL.md:5-9`, `skills/draft-review/SKILL.md:3-8`

---

## Claim 6: "| 2 | **Done (2026-09-27)** | F4: Front-load descriptions within 250 chars |"

**Location:** `guides/skill-format-audit.md:198`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the status row against the offsets in Claim 3; does not establish that 250 is the right budget.

The row states the finding unconditionally as "Done". Its own status note at `:20` says `in all but a few cases`, and Claim 3 finds five descriptions whose disambiguation ends at 262–288. The trigger list (the truncation risk F4 named, `Prevents trigger-phrase truncation`) starts past 250 in six descriptions (285, 289, 280, 275, 263, 300; see the Claim 3 table). The precise version would be "Done, with five near-miss exceptions noted at :20".

**Evidence:** `guides/skill-format-audit.md:198`, `guides/skill-format-audit.md:20`, `$S/logs/offsets.log`

---

## Claim 7: Every "not this — use X" / "distinct from X" / "→ X" line in the new descriptions names a skill that exists, and no trigger phrase moved from one skill to another

**Location:** `skills/*/SKILL.md:3-9` (description blocks)
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every other-skill name in the 25 new descriptions, plus every quoted trigger in them (135), traced to the same skill's old file. It does not establish that the new routing lines are *complete*: some old "distinct from" detail now lives only in the body, e.g. api-consistency's parentheticals `(structure)` / `(exploitability)`.

The offset script lists the skill names each description mentions. All of them resolve under `ls /workspace/skills`. Examples: `performance-reviewer … names=['security-reviewer', 'api-consistency-reviewer', 'architecture-review']` and `business-plan-critique-moat … names=['business-plan-critique-unit-economics', 'business-plan-critique-market-sizing']` (`$S/logs/offsets.log`). The regex's `unknown=` hits are substring artifacts of hyphenated names (e.g. `plan-critique`, `if-analysis`), not real names.

Old route-aways that became the new "→" lines say the same thing as before. For example, cowen's old `Distinct from yglesias-critique (which targets proposed mechanisms …) and ai-personas-critique (which dispatches multiple orthogonal lenses)` became `mechanism feasibility → yglesias-critique, many lenses → ai-personas-critique` (`skills/cowen-critique/SKILL.md:5-6`). What-if and pre-mortem keep the retrospective/prospective split and the "run what-if first" composition (`skills/pre-mortem/SKILL.md:5-6`, `skills/what-if-analysis/SKILL.md:5-6`).

`nomove.py` output: `checked 135 phrases; not-from-own-old-file: 0` (`$S/logs/nomove.log`).

Command: `python3 $S/nomove.py` · cwd `/workspace` · exit 0 · 2026-09-27T16:18:39-07:00.

**Evidence:** `$S/logs/nomove.log`, `$S/logs/offsets.log`, `skills/cowen-critique/SKILL.md:4-8`, `skills/pre-mortem/SKILL.md:4-8`, `skills/what-if-analysis/SKILL.md:4-8`

---

## Claim 8: fact-check's "claims about code → code-fact-check" is "taken from guides/skill-trigger-guide.md"

**Location:** `skills/fact-check/SKILL.md:5` (claim text in commit f51db1c body)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether the guide supports routing code claims to code-fact-check; does not establish that it comes from the guide's "Also consider" column, as the dispatch brief says. It does not.

The guide supports the route in its prose, not its table: `**When to use which:** \`code-fact-check\` for anything in or about code. \`fact-check\` for prose, articles, essays, policy pieces.` (`guides/skill-trigger-guide.md:57`). In the table, fact-check's "Also consider" entry is `` `draft-review` (includes fact-check as Stage 1) `` (`guides/skill-trigger-guide.md:18`). The new description covers that one too, with `or draft-review's Stage 1 pass` (`skills/fact-check/SKILL.md:7-8`). The commit's wording ("taken from guides/skill-trigger-guide.md") is accurate. The brief's "Also consider column" attribution is imprecise for this one skill (orchestrator-side, not a repo claim).

**Evidence:** `guides/skill-trigger-guide.md:18`, `guides/skill-trigger-guide.md:57`, `skills/fact-check/SKILL.md:3-8`

---

## Claim 9: "For a full multi-concern review use code-review." (new disambiguation)

**Location:** `skills/security-reviewer/SKILL.md:5`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the trigger guide and with code-review's core-critic list; does not establish CLAUDE.md's auto-trigger precedence.

The guide row reads `| Security audit | \`security-reviewer\` | \`code-review\` (includes security as core critic) |` (`guides/skill-trigger-guide.md:14`). code-review lists security-reviewer among its always-run critics under `**Core critics (always run in Stage 2):**` (`skills/code-review/SKILL.md:171`).

**Evidence:** `guides/skill-trigger-guide.md:14`, `skills/code-review/SKILL.md:171-174`

---

## Claim 10: "Inside a full PR review, code-review runs it." / "Within a full PR review, code-review invokes it."

**Location:** `skills/dependency-upgrade/SKILL.md:5`, `skills/test-strategy/SKILL.md:5`, `skills/ui-visual-review/SKILL.md:5-6`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers code-review's contextual-critic selection rules for these three skills; does not establish how often the triggers fire in practice.

code-review runs these three only when the diff triggers them, not in every full review:
- test-strategy: `Source files changed (\`src/\`, \`lib/\`, etc.) without corresponding test file changes … | \`test-strategy\`` (`skills/code-review/SKILL.md:196`)
- dependency-upgrade: `Dependency manifests changed (\`package.json\`, … ) | \`dependency-upgrade\`` (`skills/code-review/SKILL.md:197`)
- ui-visual-review: `Diff touches UI rendering code: JSX/TSX with className or style props, CSS/SCSS files, …` (`skills/code-review/SKILL.md:199`)

The guide source says the same, with the condition attached: `` `code-review` (auto-triggers on manifest changes) `` (`guides/skill-trigger-guide.md:22`). The same pattern holds for test-strategy (`:21`, "auto-triggers when tests are missing") and ui-visual-review (`:23`, "auto-triggers on UI file changes"). The description drops the condition. For routing ("go to code-review for a full review") the meaning holds. Read literally, a user could expect a full review to always include a test plan. Precise version: "in a full PR review, code-review runs it when the diff triggers it". Commit 750178d's "gain 'inside a full PR review, code-review runs it' … from the trigger guide" inherits the same dropped qualifier.

**Evidence:** `skills/code-review/SKILL.md:196-199`, `guides/skill-trigger-guide.md:21-23`, `skills/dependency-upgrade/SKILL.md:3-8`, `skills/test-strategy/SKILL.md:3-8`, `skills/ui-visual-review/SKILL.md:3-8`

---

## Claim 11: Moat/unit-economics now name business-plan-critique-market-sizing as an existing sibling (description) while the body still calls it "future"

**Location:** `skills/business-plan-critique-moat/SKILL.md:46`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the sibling's existence and the body lines that still call it future. The body lines are pre-existing and were not touched by this diff; the new description text contradicts them. Does not establish any other stale sibling references.

The new description routes to it as a live skill: `market size → business-plan-critique-market-sizing.` (`skills/business-plan-critique-moat/SKILL.md:6`). That matches the commit's intent (f51db1c: `names business-plan-critique-market-sizing instead of "a future market-sizing critic" (the sibling exists)`). The skill has existed since 2026-05-15 (`41c4853`, first add of `skills/business-plan-critique-market-sizing`). The body's scope section, a few lines below in the same file, still reads:

```
- **Market-sizing critique** (TAM/SAM/SOM realism, segment definition, addressable customer
  count) — future `business-plan-critique-market-sizing` skill.
```
(`skills/business-plan-critique-moat/SKILL.md:45-46`)

The unit-economics body says the same: `(TAM/SAM/SOM realism, segment definition, addressable customer count) — future \`business-plan-critique-market-sizing\`.` (`skills/business-plan-critique-unit-economics/SKILL.md:41`). Its description also routes to it as live (`:6`). These body lines were true when written and have gone stale. After the description fix, each file now contradicts itself. Drop "future" in both body lines.

**Evidence:** `skills/business-plan-critique-moat/SKILL.md:6`, `skills/business-plan-critique-moat/SKILL.md:45-46`, `skills/business-plan-critique-unit-economics/SKILL.md:6`, `skills/business-plan-critique-unit-economics/SKILL.md:41`

---

## Claim 12: The new descriptions' factual claims about each skill (modes, outputs, counts, pipelines) match the SKILL.md bodies

**Location:** `skills/*/SKILL.md:3-9`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the concrete checkable facts in each new description, listed below. It does not re-verify the bodies' own claims (e.g. that the arithmetic sandbox actually confines, which pass 1 and the bats suite cover), and does not cover the conditional-invocation wording in Claim 10.

Spot-checked facts, each against its body:
- **ai-personas `catalog of 17`.** The body says `Read \`personas.md\` … Defines 17 personas` (`skills/ai-personas-critique/SKILL.md:58-59`), and `personas.md` has 17 `### ` entries.
- **self-eval `five auto-rated dimensions, four human prompts` → `docs/reviews/self-eval-{target}.md`.** Body: `Auto-scored dimensions (…): testability investment, trigger clarity, overlap and redundancy, test coverage, pipeline readiness` plus four flagged ones (`skills/self-eval/SKILL.md:23`); `Save the evaluation report to \`docs/reviews/self-eval-{target-name}.md\`` (`:233`).
- **test-strategy `named gaps (G1, G2...)`.** Body: `- **G1** — path/to/file.ext:LINE-LINE — …` (`skills/test-strategy/SKILL.md:98`).
- **matrix-analysis `one sub-agent per criterion`.** Body: `How many sub-agents will run (one per criterion)` (`skills/matrix-analysis/SKILL.md:123`).
- **code-review pipeline.** Body: `**Fact-checker (fixed — always runs in Stage 1):**` / `**Core critics (always run in Stage 2):**` (`skills/code-review/SKILL.md:168,171`), plus the contextual table at `:196-199`.
- **draft-review pipeline and red/amber/green.** Body: `fact-check → critic agents in parallel → synthesis … red/amber/green status tracking` (`skills/draft-review/SKILL.md:45`).
- **ui-visual-review `per WCAG 2.2`.** Body: `- **WCAG 2.2** — visible focus indicators (2.4.7) …` (`skills/ui-visual-review/SKILL.md:33`).
- **divergent-design routes into `workflows/divergent-design.md`.** Body: `Read and follow **\`workflows/divergent-design.md\`** end to end` (`skills/divergent-design/SKILL.md:39`).
- **arithmetic-eval modules.** numpy, scipy, pandas, sympy and statistics are in the approved-modules list (bats `ok 74 approved-modules list includes core scientific libraries`, Claim 14 log).
- **pre-mortem `3–5`.** Body: `Generate 3–5 such narratives.` (`skills/pre-mortem/SKILL.md:158`).
- **design-space `eight design-technique dimensions`.** The body's record table starts `| 1 | Locus of authority |` (`skills/design-space-situating/SKILL.md:153`). The paraphrase that it has eight rows comes from reading the table (paraphrased — no quote available because the eight rows span the table and quoting all would add nothing).

**Evidence:** `skills/ai-personas-critique/SKILL.md:58-59`, `skills/self-eval/SKILL.md:23`, `skills/self-eval/SKILL.md:233`, `skills/test-strategy/SKILL.md:98`, `skills/matrix-analysis/SKILL.md:123`, `skills/code-review/SKILL.md:168-199`, `skills/draft-review/SKILL.md:45`, `skills/ui-visual-review/SKILL.md:33`, `skills/divergent-design/SKILL.md:39`, `skills/pre-mortem/SKILL.md:158`, `skills/design-space-situating/SKILL.md:153`

---

## Claim 13: Every frontmatter parses and the folded `description: >` reads back as intended

**Location:** `skills/*/SKILL.md:1-20` (frontmatter)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers three independent readers of the 25 frontmatters: the repo's health-check (check 1), a hand-rolled folded-scalar parser, and the CPAN::Meta::YAML (YAML::Tiny) parser. Does not establish parsing by Claude Code's own loader (PyYAML is not installed in the sandbox).

1. **Health check.** `HEALTH_CHECK_SKIP_BATS=1 bash scripts/health-check.sh` · cwd `/workspace` · exit 0 · 2026-09-27T16:14:55-07:00. Output includes `── Skill YAML frontmatter ──` … `✓ 25 skill(s) checked` and zero `✗` lines (`$S/logs/health-check.log`).
2. **Hand parser.** `$S/extract.py` asserts every description header is exactly `description: >`, finds a single indentation width and no tabs in all 25 blocks (empty issue lists in `$S/logs/extract.log`), and folds each to one line (texts in `$S/desc.json`).
3. **Real YAML parser.** `LC_ALL=C perl $S/yamlcheck.pl <file>` over all 25 · cwd `/workspace` · 2026-09-27T16:14:42-07:00 (`$S/logs/yaml-perl.log`). 24 parse `OK`. The code-fact-check failure is `illegal characters in plain scalar: 'Verdict calibration over precision theater …'`, in the untouched `adaptation-latitude` key. The same failure happens on `main` (`git show main:skills/code-fact-check/SKILL.md` → `PARSE-FAIL`), so it is a known YAML::Tiny limitation, pre-existing and outside this diff.

**Evidence:** `$S/logs/health-check.log`, `$S/logs/extract.log`, `$S/logs/yaml-perl.log`, `scripts/health-check.sh:119-143`

---

## Claim 14: Tests that pin description text (arithmetic-eval "bare arithmetic"/"scientific"; router and frontmatter suites) still hold

**Location:** `test/skills/arithmetic-eval-format.bats:50-56`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 26 `test/skills/*-format.bats` + `divergent-design-router.bats` + `frontmatter-fields.bats` files and 9 further static skill suites. The report-dependent tests in them were skipped (no generated reports), so this does not establish report-grading behavior.

The pinning test greps the frontmatter for `(bare arithmetic|simple.*arithmetic|numbers and operators)` and `scientific` (`test/skills/arithmetic-eval-format.bats:54-55`). The new description still has `bare arithmetic via a safe AST evaluator, and scientific computing` (`skills/arithmetic-eval/SKILL.md:6-7`).

- **Run 1:** `bats <26 files>` · cwd `/workspace` · exit 0 · 2026-09-27T16:16:22-07:00. Result `1..477`, 477 `ok`, 443 skipped, 0 `not ok`. The live tests include `ok 65 description mentions both modes (bare arithmetic and scientific)` and `ok 284 all skills have required frontmatter fields` (`$S/logs/bats-skills.log`).
- **Run 2:** `bats test/skills/{yglesias,cowen}-critique/dimensions-skill.bats test/skills/code-review-{format-contract,assurance-contract,soundness-crosscheck,factcheck-replication,context-delivery}.bats test/skills/{fact-check,code-fact-check}-edge-cases.bats` · exit 0 · 2026-09-27T16:16:56-07:00. Result `1..129`, 0 `not ok` (`$S/logs/bats-extra.log`).

`rg -n description test` finds no other assertion on description *text*. The hits are field-presence checks (`test/skills/frontmatter-fields.bats:60`) and unrelated JSON fixtures.

**Evidence:** `test/skills/arithmetic-eval-format.bats:50-56`, `$S/logs/bats-skills.log`, `$S/logs/bats-extra.log`

---

## Claim 15a: Commit f51db1c — "Each description now reads purpose, then the "not this, use X" line, then the main trigger phrases, in ~380-440 characters (was 951-2969) … The `when:` field is left as is"

**Location:** commit f51db1c (message body)
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 8 batch-1 skills (cowen, yglesias, ai-personas, three business-plan critics, fact-check, code-fact-check); does not cover batches 2–3.

The new lengths for batch 1 are 382–438 (cowen 425, yglesias 438, ai-personas 398, market-sizing 388, moat 413, unit-economics 397, fact-check 382, code-fact-check 388). The old lengths are 951–2969. All 8 have a route-away line (Claims 5, 7, 8). No `when:` line changes anywhere in the diff (paraphrased — no quote available because the claim covers absence: `grep -nE '^[-+]when' pass2.diff` returns nothing). Command as in Claim 1.

**Evidence:** `$S/logs/extract.log`, `skills/cowen-critique/SKILL.md:3-9`

---

## Claim 15b: Commit c2fb944 — "Same shape as batch 1: purpose, disambiguation, main triggers in ~380-430 characters … architecture-review keeps its ONLY/SKIP gate in the description; the four numbered categories move to the body … no routing claim was reassigned"

**Location:** commit c2fb944 (message body)
**Type:** Reference / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 8 batch-2 skills; the routing-reassignment part rests on Claim 7's script.

- **Lengths.** 382–426 (code-review 414, draft-review 404, matrix-analysis 382, security 426, performance 418, api-consistency 397, architecture 408, ui-visual 396) (`$S/logs/extract.log`).
- **Architecture gate.** The ONLY/SKIP gate is kept: `ONLY when the diff changes module structure, public APIs, data models or cross-cutting concerns; SKIP implementation-only diffs.` (`skills/architecture-review/SKILL.md:4-6`). The numbered list is in the body at `:59-63`.
- **Routing.** No phrase was reassigned (Claim 7).
- **The imprecision.** matrix-analysis does not have batch 1's shape: it has no "not this, use X" disambiguation. Its middle sentence is `Prefer it over an ad-hoc pros/cons list; also a sub-procedure of divergent-design and RPI plans.` (`skills/matrix-analysis/SKILL.md:5-6`). The same issue as Claim 2.

**Evidence:** `$S/logs/extract.log`, `skills/architecture-review/SKILL.md:3-9`, `skills/architecture-review/SKILL.md:55-68`, `skills/matrix-analysis/SKILL.md:3-8`

---

## Claim 15c: Commit 750178d — "arithmetic-eval keeps "bare arithmetic" and "scientific" in the description because test/skills/arithmetic-eval-format.bats asserts on them … appended to the existing When-to-use section in design-space-situating, pre-mortem and what-if-analysis"

**Location:** commit 750178d (message body)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two stated facts; the dependency-upgrade/test-strategy wording note in the same commit is verdicted under Claim 10.

- **arithmetic-eval.** The test assertion is at `test/skills/arithmetic-eval-format.bats:54-55`, and the kept text is `bare arithmetic via a safe AST evaluator, and scientific computing` (`skills/arithmetic-eval/SKILL.md:6-7`). The executed pass is in Claim 14.
- **Appends.** The three appends sit under pre-existing When-to-use headings (Claim 4, placement).

**Evidence:** `test/skills/arithmetic-eval-format.bats:50-56`, `skills/arithmetic-eval/SKILL.md:3-9`, `skills/pre-mortem/SKILL.md:31-57`, `skills/what-if-analysis/SKILL.md:31-48`, `skills/design-space-situating/SKILL.md:24-30`

---

## Claims Requiring Attention

Legibility target by verdict: Incorrect, Stale and Mostly Accurate are **for-author**; Verified and Unverifiable are **for-orchestrator-synthesis**.

### Incorrect
(none)

### Stale
- **Claim 11** (`skills/business-plan-critique-moat/SKILL.md:46`, also `skills/business-plan-critique-unit-economics/SKILL.md:41`): both bodies still call `business-plan-critique-market-sizing` a "future" skill. The new descriptions route to it as live (it has existed since 41c4853). Drop "future". [for-author]

### Mostly Accurate
- **Claim 2** (`guides/skill-format-audit.md:20`): "Each description … then the 'not this, use X' line". arithmetic-eval, matrix-analysis, self-eval and tech-debt-triage have none (and never had one). Qualify it with "where a sibling exists". [for-author]
- **Claim 3** (`guides/skill-format-audit.md:20`): "all but a few" means 5 of 25: architecture-review 284, design-space-situating 288, yglesias 279, what-if 274, moat 262. Name them. [for-author]
- **Claim 4** (`guides/skill-format-audit.md:20`): "moved, not deleted" nearly holds (239/245 quoted phrases verbatim; the rest are folding artifacts or framings kept in substance). Four things were dropped:
  - the what-if framing `"what would need to be true for this to fail?"`;
  - cowen's draft-genre list (blog post / essay / article / op-ed / research note);
  - fact-check's artifact list (blog post / essay / article / policy piece);
  - authority, reversibility and formality from design-space-situating's RPI trigger (the body keeps only social structure, temporal commitment, legibility).

  Restore these to the When-to-use sections, or accept them as intended trims. [for-author]
- **Claim 6** (`guides/skill-format-audit.md:198`): the F4 row says "Done" unconditionally, but five descriptions miss the 250 budget (Claim 3). [for-author]
- **Claim 10** (`skills/dependency-upgrade/SKILL.md:5`, `skills/test-strategy/SKILL.md:5`, `skills/ui-visual-review/SKILL.md:5-6`): "code-review runs/invokes it" drops the condition. code-review runs these only when the diff triggers them (`skills/code-review/SKILL.md:196-199`). Add "when triggered". [for-author]
- **Claim 15b** (commit c2fb944): "Same shape as batch 1" doesn't hold for matrix-analysis, which has no disambiguation line. [for-author]

### Unverifiable
(none)

Verified claims 1, 5, 7, 8, 9, 12, 13, 14, 15a and 15c are for-orchestrator-synthesis: the length counts, no de-overlap, routing names valid and no phrase moved, the fact-check/security routes, description-vs-body accuracy, YAML parsing, the description-pinning tests, and the batch-1/batch-3 commit claims.

---

## Goal-Alignment Note

- **Success criterion (restated verbatim):** "A code-fact-check report saved at the dispatch path in the skill's schema, covering the claims above, with a Goal-Alignment Note."
- **Answered:**
  - Nothing lost: per-skill quoted-phrase script plus a manual clause read of all 25 (Claim 4, with the dropped items listed).
  - Routing preserved, names exist, no phrase moved (Claims 7–10).
  - Front-loading offsets per skill (Claim 3).
  - Description-vs-body accuracy (Claims 11–12).
  - YAML (Claim 13, three parsers).
  - Pinning tests (Claim 14, executed).
  - Audit F4 note and all three commit messages (Claims 1–6, 15a–c).
- **Out of scope:**
  - Pass-1 branch content (cc-isolated.sh, hooks, harness).
  - De-overlap quality (explicitly not a goal).
  - The `when:` fields.
  - How Claude Code's live listing actually truncates. This session's own skill listing still shows the `main`-era text (it loads installed copies, not this branch), so the listing could not be observed post-change.
- **Escalate:**
  1. The dispatch brief attributes fact-check's new code-fact-check pointer to the trigger guide's "Also consider" column. That column says `draft-review`; the pointer comes from the guide's prose at :57. The commit is correct; only the brief is imprecise (Claim 8).
  2. Per the brief, the hallucination-pattern log was not appended to. No Incorrect verdicts, so nothing would have qualified.
  3. Execution logs live in the session scratchpad, not `docs/reviews/execution-logs/`, because of the brief's no-repo-edit rule. Copy them in if the review artifacts must carry provenance.
