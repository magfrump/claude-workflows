Commit: 02d14b0

# Code Fact-Check Report

**Repository:** /workspace (branch integrate/q076-q080)
**Scope:** Partial. `git diff main...HEAD -- skills guides/skill-format-audit.md` at 02d14b0 (26 files: 25 `skills/*/SKILL.md` descriptions plus `guides/skill-format-audit.md`), and the three commit messages f51db1c, c2fb944 and 750178d. The rest of the branch is context only. Delivery mode: self-read.
**Checked:** 2026-09-27
**Total claims checked:** 12
**Summary:** 8 verified, 3 mostly accurate, 1 stale, 0 incorrect, 0 unverifiable

Scratch artifacts (scripts and captured output) are in `/tmp/claude-1000/-workspace/dbfd30e0-d8d5-40c1-8bac-572239fc44fd/scratchpad/pass2-r2/`. The brief allowed no repo writes except this report, so they were not copied to `docs/reviews/execution-logs/`.

- `extract.py` / `lengths.log`: old and new description lengths. It hand-parses the folded `>` scalar (joins the lines of each paragraph with one space).
- `phrases.py` / `phrases.log`: checks where old trigger phrases went, whether any phrase moved between skills, and whether referenced skills exist.
- `frontload.txt`: character offsets of the disambiguation and triggers.
- `yaml-parse.log`: parse with CPAN::Meta::YAML.
- `health.log`: `scripts/health-check.sh`.
- `bats-desc.log`: the bats tests that pin description text.

---

## Claim 1: "Resolved for all 25 skills … runs 364–438 characters (was 951–2969)"

**Location:** `guides/skill-format-audit.md:20`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the length of each of the 25 `description` values as read back by a folded-scalar parser, old (main) versus new (HEAD). It does not establish that the live skill listing counts characters the same way. The listing may count bytes, or cut at a point other than 250.

Command `python3 extract.py res.pkl`, run in `/workspace` at 2026-09-27T23:18:22Z, exited 0. It printed the new lengths ranging from `self-eval … new= 364` to `yglesias-critique … new= 438`, and the old ones from `fact-check old=  951` to `business-plan-critique-market-sizing old= 2969`, with the final line `TOTAL 37064 10084`. That matches the brief's "37,064 → 10,084". A second parser (CPAN::Meta::YAML, see Claim 8) returned the same length for each of the 24 descriptions it could read, e.g. `skills/yglesias-critique/SKILL.md len=438 nl=0`.

**Evidence:** `guides/skill-format-audit.md:20`; scratchpad `pass2-r2/lengths.log`, `pass2-r2/yaml-parse.log`

---

## Claim 2: "The purpose and the disambiguation fall inside the first ~250 characters in all but a few cases; the trigger list starts there and finishes by ~440."

**Location:** `guides/skill-format-audit.md:20`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the character offsets of the disambiguation ("not this — use X") clauses and of `Triggers:` in the 25 new descriptions. It does not establish where the harness actually truncates.

Offsets (0-based, in the folded string; `frontload.txt` plus the targeted `find` calls) put the whole disambiguation inside 250 characters for most skills. Five skills cross 250:

- `architecture-review`: "Security, performance and API naming belong to their own critics." runs 219–284.
- `business-plan-critique-moat`: the "market size → business-plan-critique-market-sizing" pointer ends at 261.
- `design-space-situating`: the main pointer ("Choosing among options → divergent-design") ends at 191, but "…escalating here only if it fails." runs 255–288.
- `what-if-analysis`: the pre-mortem pointer ends at 214, but "is the argument good → cowen-critique or yglesias-critique" ends at 273.
- `yglesias-critique`: the pointers run 226–278, and the listing's 250-character cut lands in the middle of "many lenses → ai-personas-critique".

`Triggers:` starts after 250 in six skills: architecture-review 285, arithmetic-eval 300, design-space-situating 289, what-if-analysis 275, yglesias-critique 280 and business-plan-critique-moat 263. For those, the brief's goal of "main triggers in the first ~250" is not met. The note hedges this ("the trigger list starts there"). "All but a few" is fair for five of the ~21 descriptions that have a disambiguation line. The precise version is: all but five, and the trigger list starts after 250 in six. Four skills have no "not this" line, and none did before: arithmetic-eval, matrix-analysis, self-eval and tech-debt-triage. In arithmetic-eval and tech-debt-triage, the sibling names that appear are not disambiguations.

**Evidence:** `guides/skill-format-audit.md:20`; `skills/architecture-review/SKILL.md:4-8`; `skills/business-plan-critique-moat/SKILL.md:5-9`; `skills/design-space-situating/SKILL.md:4-8`; `skills/what-if-analysis/SKILL.md:4-8`; `skills/yglesias-critique/SKILL.md:6-10`; scratchpad `pass2-r2/frontload.txt`

---

## Claim 3a: "The displaced long-tail trigger phrases and caveats moved into a `## When to use` section in each SKILL.md body", for 22 of the 25 skills

**Location:** `guides/skill-format-audit.md:20`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every double-quoted phrase in each old description (checked by script against the new description plus body) and a manual diff read of the unquoted scope notes, caveats and "report provided" NOTEs for 22 skills (all except cowen-critique, fact-check and design-space-situating; see 3b). It does not establish that body text carries the same trigger weight as description text in the skill loader.

`phrases.log` shows zero old quoted phrases missing from the new file for 22 skills. The three reported "missing" are paraphrased in the body rather than dropped:

- pre-mortem: "the project failed — what does the post-incident review say?" and "this has failed — why?". The body keeps them as "Perform the post-incident review." (`skills/pre-mortem/SKILL.md:25`) and the mechanical-test table (`:37-42`).
- what-if-analysis: "what if this assumption is wrong?" and "what would need to be true for this to fail?". The body keeps these ideas in its moves, e.g. `:115` "Invert them. What if the "obvious" thing is wrong?".
- yglesias-critique: "what's the 10-million -people test". This was a line-wrap artifact, and the body now reads "what's the 10-million-people test" (`skills/yglesias-critique/SKILL.md:33`).

Every "if a (code-)fact-check report is provided…" NOTE was kept in the body:

- `skills/api-consistency-reviewer/SKILL.md:41`
- `skills/architecture-review/SKILL.md:68`
- `skills/performance-reviewer/SKILL.md:32`
- `skills/security-reviewer/SKILL.md:63`
- `skills/ui-visual-review/SKILL.md:51`
- `skills/dependency-upgrade/SKILL.md:24` ("sole source of execution results…")
- cowen-critique, yglesias-critique and the three business-plan critics each have a "Typically invoked by `draft-review`…" bullet

The two section layouts dropped from the business-plan descriptions already exist as body headings (`skills/business-plan-critique-market-sizing/SKILL.md:279-285`, `skills/business-plan-critique-unit-economics/SKILL.md:142-148`). All 25 files have exactly one `## When to use…` heading (case-insensitive grep count = 1 for each).

**Evidence:** scratchpad `pass2-r2/phrases.log` (command `python3 phrases.py`, cwd `/workspace`, 2026-09-27T23:18:29Z, exit 0); `skills/pre-mortem/SKILL.md:25,37-42,57`; `skills/what-if-analysis/SKILL.md:48,115`; `skills/yglesias-critique/SKILL.md:28-35`

---

## Claim 3b: Same claim ("nothing deleted"), for cowen-critique, fact-check and design-space-situating

**Location:** `guides/skill-format-audit.md:20`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers three unquoted scope enumerations in these three skills' old descriptions. It does not establish that dropping them changes routing: each skill keeps a broader statement that still covers the case.

**cowen-critique.** The old description began "Critically review a draft (blog post, essay, article, op-ed, research note, or similar written piece)" (main:`skills/cowen-critique/SKILL.md:6`). A grep of the new file for `op-ed|research note|blog post` finds nothing. What remains is the broader "a written argument" (`skills/cowen-critique/SKILL.md:4`) and `when: … a written draft`.

**fact-check.** The old "(blog post, essay, article, policy piece, or any prose with checkable assertions)" is gone from both the description and the new When-to-use bullets. The broader `requires: - A draft (prose or document)` (`skills/fact-check/SKILL.md:16`) remains.

**design-space-situating.** The old RPI trigger read "a decision touching authority, time, reversibility, formality, social structure, or legibility in ways the user has not named". The body's pre-existing bullet names only three of these: "When RPI research surfaces a decision touching social structure, temporal commitment, or legibility" (`skills/design-space-situating/SKILL.md:28`). Authority, reversibility and formality were dropped. The `when:` field's "RPI surfaces an unnamed design-space default" (`:9`) still covers them in general terms.

Precise version: the displaced text moved, except three draft-type or dimension enumerations that were dropped in favour of the broader wording already present. The eight-dimension list is not among the losses: it survives in the body table (`:153-160`).

**Evidence:** main:`skills/cowen-critique/SKILL.md:6`; main:`skills/fact-check/SKILL.md:4-5`; main:`skills/design-space-situating/SKILL.md:17-18`; `skills/cowen-critique/SKILL.md:4-10,28-35`; `skills/fact-check/SKILL.md:16,47-51`; `skills/design-space-situating/SKILL.md:9,24-30`

---

## Claim 4: "No de-overlap: the cowen/yglesias "DEFAULT critic" claims and phrases shared by several skills were kept as they were."

**Location:** `guides/skill-format-audit.md:20`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the phrases that appeared, quoted, in two or more old descriptions, plus the "DEFAULT critic" string. It does not establish that routing overlap is unchanged for unquoted trigger conditions.

`phrases.log` section "shared phrases" lists every multi-owner phrase, each still in every new description that had it:

- `'what am i missing' {cowen-critique: True, draft-review: True, ai-personas-critique: True}`
- `'poke holes in this proposal' {yglesias-critique: True, ai-personas-critique: True}`
- `'review this draft' {cowen-critique: True, draft-review: True}`
- `'pre-mortem this' {what-if-analysis: True, pre-mortem: True}` (still a route-away phrase in what-if)

"The DEFAULT critic" is at offset 117 in cowen-critique and 148 in yglesias-critique. This also verifies commit f51db1c's "shared phrases (…) stay in every description that had them".

**Evidence:** scratchpad `pass2-r2/phrases.log`; `skills/cowen-critique/SKILL.md:6-10`; `skills/yglesias-critique/SKILL.md:6-10`

---

## Claim 5: Routing preserved: "no routing claim was reassigned" (c2fb944), and every "not this" target exists

**Location:** `skills/*/SKILL.md:1-12` (all 25 frontmatters)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the double-quoted trigger phrases in each new description and every hyphenated skill name those descriptions mention. It does not establish that unquoted trigger conditions (e.g. "or any dependency manifest change") are unambiguous between skills. They were not de-overlapped by design.

The "new-desc quoted phrases absent from same skill old desc" section of `phrases.log` is empty for all 25 skills: no quoted trigger phrase appeared in a skill that did not already carry it. Every skill named in a new description exists under `skills/`. For example, moat's "market size → business-plan-critique-market-sizing" (`skills/business-plan-critique-moat/SKILL.md:7`) and fact-check's "claims about code → code-fact-check" (`skills/fact-check/SKILL.md:6`) both resolve.

The five added pointers match `guides/skill-trigger-guide.md`:

- security-reviewer → code-review: `:14` "| Security audit | `security-reviewer` | `code-review` (includes security as core critic) |"
- test-strategy, dependency-upgrade and ui-visual-review → code-review: `:21-23` (Also consider = `code-review`, "auto-triggers …")
- fact-check → code-fact-check: the source is not the "Also consider" column, whose fact-check row is `:18` "`draft-review` (includes fact-check as Stage 1)". It is `:57` "`code-fact-check` for anything in or about code. `fact-check` for prose…" and `:171`. The commit f51db1c wording "taken from guides/skill-trigger-guide.md" is accurate. Only the brief's attribution to the "Also consider" column is loose.

design-space-situating also gained a pointer the brief does not list, "Choosing among options → divergent-design" (`skills/design-space-situating/SKILL.md:5-6`). It is supported by the trigger guide `:33` "| Frame a decision before choosing | `design-space-situating` | `divergent-design` |".

**Evidence:** scratchpad `pass2-r2/phrases.log`; `guides/skill-trigger-guide.md:14,18,21-23,33,57,171`; `skills/fact-check/SKILL.md:4-8`; `skills/design-space-situating/SKILL.md:4-8`

---

## Claim 6: New descriptions accurately describe their bodies (modes, outputs, orchestration)

**Location:** `skills/*/SKILL.md:3-12`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers these assertions, each checked against the body: code-review's pipeline and diff-selected critics; draft-review's stages; matrix-analysis's one sub-agent per criterion; ai-personas-critique's "catalog of 17"; arithmetic-eval's allowlist modules; self-eval's five/four dimensions and output path; ui-visual-review's WCAG 2.2; "code-review runs it" for dependency-upgrade, test-strategy and ui-visual-review; design-space-situating's eight dimensions; divergent-design's target workflow. It does not establish the accuracy of every adjective in every description (medium confidence for that reason).

The checks, in the same order:

- **code-review** auto-selects the three contextual critics: `skills/code-review/SKILL.md:196` "`test-strategy`", `:197` "Dependency manifests changed … | `dependency-upgrade`", `:199` "Diff touches UI rendering code … | `ui-visual-review`".
- **matrix-analysis** `:123` "How many sub-agents will run (one per criterion)".
- **ai-personas-critique** `:58` "Read `personas.md` … Defines 17".
- **arithmetic-eval** `:113` `"math","statistics","scipy","numpy","pandas","sympy",…`.
- **self-eval**: the output path is `:233` "Save the evaluation report to `docs/reviews/self-eval-{target-name}.md`". The description abbreviates `{target-name}` to `{target}`, which is harmless. `## Key Questions` is at `:281`.
- **ui-visual-review** `:33` "**WCAG 2.2** — visible focus indicators (2.4.7)…".
- **design-space-situating** `:153-160` is the eight-row dimension table.
- **divergent-design** routes to `workflows/divergent-design.md`, which exists.
- **draft-review** Stage 1: `:55` "Finish Stage 1…".

**Evidence:** `skills/code-review/SKILL.md:196-199`; `skills/matrix-analysis/SKILL.md:123`; `skills/ai-personas-critique/SKILL.md:58`; `skills/arithmetic-eval/SKILL.md:113`; `skills/self-eval/SKILL.md:233,281`; `skills/ui-visual-review/SKILL.md:33`; `skills/design-space-situating/SKILL.md:153-160`; `skills/draft-review/SKILL.md:55`

---

## Claim 7: Commit batch claims: f51db1c "~380-440 characters (was 951-2969)"; c2fb944 "~380-430 characters", "architecture-review keeps its ONLY/SKIP gate … the four numbered categories move to the body"; 750178d "appended to the existing When-to-use section in design-space-situating, pre-mortem and what-if-analysis"

**Location:** commits `f51db1c`, `c2fb944`, `750178d` (messages)
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the per-batch length ranges and the structural moves each commit message names. It does not establish anything the messages leave out, such as design-space-situating's new divergent-design pointer, which 750178d does not mention.

From `lengths.log`:

- Batch 1: new lengths 382 (fact-check) to 438 (yglesias); old lengths 951 (fact-check) to 2969 (market-sizing).
- Batch 2: code-review 414, draft-review 404, matrix-analysis 382, security-reviewer 426, performance-reviewer 418, api-consistency-reviewer 397, architecture-review 408, ui-visual-review 396. Range 382–426, within "~380-430".

The architecture-review description keeps "ONLY when the diff changes module structure, public APIs, data models or cross-cutting concerns; SKIP implementation-only diffs" (`skills/architecture-review/SKILL.md:4-6`). The numbered list is in the body at `:59-62`.

The three sections that 750178d says received appended text:

- design-space-situating: `## When to use` at `:24`, with appended bullets at `:29-30`.
- pre-mortem: "## When to Use This Skill (vs. what-if-analysis)", with the appended paragraph at `:57`.
- what-if-analysis: the equivalent heading, with the appended paragraph at `:48`.

**Evidence:** scratchpad `pass2-r2/lengths.log`; `skills/architecture-review/SKILL.md:4-6,55-68`; `skills/design-space-situating/SKILL.md:24-30`; `skills/pre-mortem/SKILL.md:32,57`; `skills/what-if-analysis/SKILL.md:33,48`

---

## Claim 8: All 25 frontmatters parse, and each folded `description: >` reads back as one intended paragraph

**Location:** `skills/*/SKILL.md:1-20`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers parsing by `scripts/health-check.sh` (25/25) and by CPAN::Meta::YAML (24/25 files). Each description came back as a single line with no embedded newline and the expected length. This does not cover code-fact-check under a full YAML 1.2 parser, because no PyYAML or js-yaml is available in the sandbox. Code-fact-check's Tiny-parser failure is on an unchanged, out-of-scope line (see below).

**health-check.** Command `bash scripts/health-check.sh`, run in `/workspace` from about 2026-09-27T23:14Z. The run was backgrounded past a 120 s timeout and later exited 0, ending "All checks passed." The frontmatter section completed with "✓ yglesias-critique … ✓ 25 skill(s) checked" (`health.log`).

**CPAN::Meta::YAML.** Command `LC_ALL=C perl y.pl`, cwd `/workspace`, 2026-09-27T23:18:22Z, exit 0. It printed `len=… nl=0` for 24 files, with lengths identical to `lengths.log`.

**code-fact-check.** The Tiny parser failed on the file: "found illegal characters in plain scalar: 'Verdict calibration over precision theater — … a refuted mechanism: verdict compound claims per the "Compound claims" section …'". That text is the `adaptation-latitude` entry, which is unchanged from main (`git show main:skills/code-fact-check/SKILL.md | grep -c "refuted mechanism: verdict"` → 1) and is not in the diff. Under full YAML, `mechanism: verdict` inside that plain sequence item would probably make a mapping rather than a string. That is a pre-existing issue, not a regression.

**Evidence:** scratchpad `pass2-r2/health.log`, `pass2-r2/yaml-parse.log`, `pass2-r2/lengths.log`; `skills/code-fact-check/SKILL.md:17`

---

## Claim 9: "arithmetic-eval keeps "bare arithmetic" and "scientific" in the description because test/skills/arithmetic-eval-format.bats asserts on them" (750178d); tests that pin description text still pass

**Location:** `test/skills/arithmetic-eval-format.bats:50-56`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three bats files that read skill frontmatter: arithmetic-eval-format, divergent-design-router and frontmatter-fields. It does not establish that no other test indirectly depends on a removed description phrase. `rg` for NOTE/"trigger phrases"/"DEFAULT critic"/"fact-check report is provided" in `test scripts hooks` found only runner prompts, not assertions.

The test greps the frontmatter:

```bash
# test/skills/arithmetic-eval-format.bats:54-55
echo "$fm" | grep -qiE '(bare arithmetic|simple.*arithmetic|numbers and operators)'
echo "$fm" | grep -qiE 'scientific'
```

The new description contains "bare arithmetic via a safe AST evaluator, and scientific computing" (`skills/arithmetic-eval/SKILL.md:5-6`). Command `timeout 300 bats test/skills/arithmetic-eval-format.bats test/skills/divergent-design-router.bats test/skills/frontmatter-fields.bats`, cwd `/workspace`, 2026-09-27T23:16:41Z, exit 0: 34 `ok` and 0 `not ok`. The last line was "ok 34 all skills have required frontmatter fields".

**Evidence:** `test/skills/arithmetic-eval-format.bats:50-56`; `skills/arithmetic-eval/SKILL.md:3-8`; scratchpad `pass2-r2/bats-desc.log`

---

## Claim 10: F4 table row "**Done (2026-09-27)** | F4: Front-load descriptions within 250 chars"

**Location:** `guides/skill-format-audit.md:198`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether the row's summary ("within 250 chars") matches the measured result. It does not assess whether "Done" is the right status choice.

The status note directly above (`:20`) admits exceptions ("in all but a few cases"). Claim 2 measured them: five descriptions have their disambiguation past 250, and six have `Triggers:` starting past 250. A bare "Done" for "front-load within 250 chars" overstates this slightly. Precise version: done, with five descriptions whose disambiguation runs to 261–288.

**Evidence:** `guides/skill-format-audit.md:20,198`; scratchpad `pass2-r2/frontload.txt`

---

## Claim 11: Moat and unit-economics bodies say the market-sizing critic is "future"

**Location:** `skills/business-plan-critique-moat/SKILL.md:45-46`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Scope-section lines in the two sibling critics, which the diff did not touch. It does not establish other stale "future" references elsewhere in the repo.

```
# skills/business-plan-critique-moat/SKILL.md:45-46
- **Market-sizing critique** (TAM/SAM/SOM realism, segment definition, addressable customer
  count) — future `business-plan-critique-market-sizing` skill.
```

The same wording is in `skills/business-plan-critique-unit-economics/SKILL.md:41`: "— future `business-plan-critique-market-sizing`." `skills/business-plan-critique-market-sizing/SKILL.md` exists. Both rewritten descriptions (moat `:7`, unit-economics `:7`) and their new When-to-use bullets now name it as a live sibling, so each file now contradicts itself. The lines were already present on main; the rewrite fixed the description (per f51db1c's note) but left these body lines.

**Evidence:** `skills/business-plan-critique-moat/SKILL.md:7,45-46`; `skills/business-plan-critique-unit-economics/SKILL.md:7,33,41`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
- **Claim 11** (`skills/business-plan-critique-moat/SKILL.md:45-46`, `skills/business-plan-critique-unit-economics/SKILL.md:41`): the body Scope sections still say the market-sizing sibling is "future" although it exists and the new descriptions name it. Drop "future". Legibility-target: for-author.

### Mostly Accurate
- **Claim 2** (`guides/skill-format-audit.md:20`): "all but a few" is fair, but name them. Architecture-review, moat, design-space-situating, what-if-analysis and yglesias-critique have their disambiguation reaching 261–288, and six have `Triggers:` starting after 250. Legibility-target: for-author.
- **Claim 3b** (`guides/skill-format-audit.md:20`): three enumerations were dropped rather than moved. Cowen's and fact-check's draft-type lists, and design-space-situating's RPI dimensions (authority, reversibility, formality). Broader wording still covers each. Legibility-target: for-author.
- **Claim 10** (`guides/skill-format-audit.md:198`): "Done … within 250 chars" overstates the result for five descriptions; the note at `:20` already qualifies it. Legibility-target: for-author.

### Unverifiable
(none)

Legibility-target for the Verified claims 1, 3a, 4, 5, 6, 7, 8 and 9: for-orchestrator-synthesis.

---

## Goal-Alignment Note

- **Success criterion (verbatim):** "A code-fact-check report saved at the dispatch path in the skill's schema, covering the claims above, with a Goal-Alignment Note."
- **Answered:** The report covers all seven checks the brief asked for: nothing lost (Claims 3a/3b, per skill), routing and "not this" targets (5), front-loading offsets (2, 10), descriptions versus bodies (6), YAML (8), tests that pin text (9), and the F4 note and commit messages (1, 4, 7, 10). Nothing blocks the merge. The findings are one pre-existing stale body line pair (11) and three wording-precision items.
- **Out of scope:** Nothing outside `skills/` and `guides/skill-format-audit.md` was reviewed. I did not append to `docs/reviews/hallucination-patterns.md` (no Incorrect verdicts, and the brief forbids other repo writes). I did not verify the harness's actual truncation length (~250 chars) or the "7 skills showed none" observation. The code-fact-check `adaptation-latitude` YAML quirk (Claim 8) is unchanged from main.
- **Escalate:** (1) The brief attributes fact-check's code-fact-check pointer to the trigger guide's "Also consider" column. The actual source is `guides/skill-trigger-guide.md:57`, which is harmless, but synthesis should not repeat the column attribution. (2) design-space-situating gained a sixth "not this" pointer (→ divergent-design) that is not in the brief's list of five. It is supported by `skill-trigger-guide.md:33`. (3) The pre-existing `skills/code-fact-check/SKILL.md:17` plain scalar containing `mechanism: verdict` may parse as a mapping under full YAML. That is worth a separate look, not in this merge.
