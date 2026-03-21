# Code Fact-Check Report

**Repository:** claude-workflows-cleanup
**Scope:** fd66df8~1..HEAD (last 10 commits)
**Checked:** 2026-03-20
**Total claims checked:** 24
**Summary:** 17 verified, 2 mostly accurate, 1 stale, 3 incorrect, 1 unverifiable

---

## Claim 1: "Fact-check reports from the `fact-check` skill"

**Location:** `CLAUDE.md:41`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The `fact-check` skill exists at `skills/fact-check.md`. It produces reports to `docs/reviews/fact-check-report.md` as described.

**Evidence:** `skills/fact-check.md:114`

---

## Claim 2: "Critic critiques from `cowen-critique`, `yglesias-critique`, and any future critic skills"

**Location:** `CLAUDE.md:42`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

Both `skills/cowen-critique.md` and `skills/yglesias-critique.md` exist. Both produce output to `docs/reviews/` as described in their Output Location sections.

**Evidence:** `skills/cowen-critique.md:222-225`, `skills/yglesias-critique.md:240-242`

---

## Claim 3: "Verification rubrics from the `draft-review` orchestrator"

**Location:** `CLAUDE.md:43`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The `draft-review` skill at `skills/draft-review.md` produces a verification rubric document saved as `docs/reviews/verification-rubric.md`.

**Evidence:** `skills/draft-review.md:204`

---

## Claim 4: "This parallels `docs/working/` (RPI artifacts) and `docs/decisions/` (design decisions)."

**Location:** `CLAUDE.md:45`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** Medium

`docs/decisions/` exists and contains three decision documents. However, `docs/working/` does not currently exist as a directory in this repository. The RPI workflow (`workflows/research-plan-implement.md:13-17`) describes `docs/working/` as the location for working documents, but it is described as project-specific (created in the project being worked on, not in this workflow repo). Since CLAUDE.md is meant to be copied into projects, the reference is directionally correct but `docs/working/` does not exist in this repo.

**Evidence:** `docs/decisions/` exists; `docs/working/` does not exist in this repo; `workflows/research-plan-implement.md:13`

---

## Claim 5: "the cross-analysis matrix (Theme 9) identified that FC's methodology... could be adapted for code"

**Location:** `docs/decisions/001-code-fact-checking.md:5`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low

The "cross-analysis matrix" and "Theme 9" are not present in any file in this repository. They appear to reference an external analysis document that preceded the work in this diff.

**Evidence:** Searched entire repo for "cross-analysis matrix" and "Theme 9" — no results outside the decision documents themselves.

---

## Claim 6: "Build approach #1: Direct port of FC as a standalone skill (`code-fact-check`)."

**Location:** `docs/decisions/001-code-fact-checking.md:19`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The `code-fact-check` skill exists at `skills/code-fact-check.md` and follows the structure of the prose `fact-check` skill, adapted for code claims as described.

**Evidence:** `skills/code-fact-check.md:1-200`, `skills/fact-check.md:1-135`

---

## Claim 7: "Verdict scale: Verified, Mostly accurate, Stale, Incorrect, Unverifiable (adapted from FC's five-tier system, with 'Stale' replacing 'Disputed' and 'Unverifiable' replacing 'Unverified')"

**Location:** `docs/decisions/001-code-fact-checking.md:47`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The code-fact-check skill uses verdicts: Verified, Mostly accurate, Stale, Incorrect, Unverifiable (line 88-97). The prose fact-check skill uses: Accurate, Mostly accurate, Disputed, Inaccurate, Unverified (lines 44-53). The substitutions match the claim.

**Evidence:** `skills/code-fact-check.md:88-97`, `skills/fact-check.md:44-53`

---

## Claim 8: "Build three independent critic skills following CC/YC conventions — security-reviewer, performance-reviewer, API-consistency-reviewer."

**Location:** `docs/decisions/002-critic-style-code-review.md:26`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

All three skills exist: `skills/security-reviewer.md`, `skills/performance-reviewer.md`, `skills/api-consistency-reviewer.md`. Each follows a similar structure to the CC/YC critics (structured cognitive moves, YAML frontmatter with `requires:` declaring `code-fact-check` as a soft dependency, markdown output).

**Evidence:** `skills/security-reviewer.md`, `skills/performance-reviewer.md`, `skills/api-consistency-reviewer.md`

---

## Claim 9: "Each declares `code-fact-check` as a soft dependency via `requires:`."

**Location:** `docs/decisions/002-critic-style-code-review.md:26`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

All three code-review critics have a `requires:` section in their YAML frontmatter listing `code-fact-check` with a description indicating it is optional ("Without this input, the [...] review proceeds on code analysis only").

**Evidence:** `skills/security-reviewer.md:14-21`, `skills/performance-reviewer.md:14-21`, `skills/api-consistency-reviewer.md:14-24`

---

## Claim 10: "Each produces markdown output to `docs/reviews/`."

**Location:** `docs/decisions/002-critic-style-code-review.md:26`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High

The three code-review critic skills do not specify an output location. Unlike the prose critics (`cowen-critique.md` lines 222-225, `yglesias-critique.md` lines 240-242) which have explicit "Output Location" sections directing output to `docs/reviews/`, the security-reviewer, performance-reviewer, and api-consistency-reviewer skills have no "Output Location" section. They describe producing a "structured Markdown critique" in their descriptions but do not specify where to save it.

**Evidence:** Read full text of `skills/security-reviewer.md`, `skills/performance-reviewer.md`, `skills/api-consistency-reviewer.md` — none contain an "Output Location" section or reference to `docs/reviews/`.

---

## Claim 11: "Each has 7-9 domain-specific cognitive moves"

**Location:** `docs/decisions/002-critic-style-code-review.md:26`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

Verified by reading the cognitive moves sections of each skill. The security-reviewer has 8 moves, the performance-reviewer has 8 moves, and the api-consistency-reviewer has 8 moves — all within the 7-9 range.

**Evidence:** `skills/security-reviewer.md`, `skills/performance-reviewer.md`, `skills/api-consistency-reviewer.md`

---

## Claim 12: "Added a 'Stress-test pass' subsection to DD step 4 with a table of 7 adapted moves"

**Location:** `docs/decisions/003-critic-moves-in-divergent-design.md:26`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The divergent-design workflow has a "Stress-test pass" subsection under step 4 (line 54) with a table containing exactly 7 moves: Boring alternative, Invert the thesis, Revealed preferences, Push to extreme, Organizational survival, Scale test, Implementation org chart.

**Evidence:** `workflows/divergent-design.md:54-68`

---

## Claim 13: "guidance on which apply when, and instruction to apply 2-4 relevant moves per surviving approach"

**Location:** `docs/decisions/003-critic-moves-in-divergent-design.md:26`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The table includes a "Best for" column indicating when each move applies, and line 68 instructs: "Apply 2-4 of the most relevant moves to each surviving approach."

**Evidence:** `workflows/divergent-design.md:58-68`

---

## Claim 14: "Adapted: CC #1 (boring explanation), CC #2 (invert), CC #3 (revealed preferences), CC #4 (push to extreme), YC #4 (organizational survival), YC #6 (scale test), YC #7 (org chart)."

**Location:** `docs/decisions/003-critic-moves-in-divergent-design.md:38`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

Cross-referencing with the actual critic skills: CC move 1 is "Try the boring explanation first" (cowen-critique.md line 63), CC move 2 is "Invert the claim" (line 76), CC move 3 is "Follow revealed preferences" (line 88), CC move 4 is "Push the argument to its logical extreme" (line 102). YC move 4 is "Check whether the proposal survives an election cycle" (yglesias-critique.md line 110), YC move 6 is "Run the '10 million people' test" (line 143), YC move 7 is "Swap in the implementation org chart" (line 158). All seven adapted moves in the DD stress-test table correspond to these sources.

**Evidence:** `skills/cowen-critique.md:63-127`, `skills/yglesias-critique.md:110-170`, `workflows/divergent-design.md:58-67`

---

## Claim 15: "This workflow follows the [orchestrated review pattern](../patterns/orchestrated-review.md)"

**Location:** `workflows/task-decomposition.md:3`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The file `patterns/orchestrated-review.md` exists at the referenced relative path. Task decomposition is also explicitly mentioned in the pattern document as an instantiation of the pattern (lines 15, 25, 37, 47).

**Evidence:** `patterns/orchestrated-review.md:15,25,37,47`

---

## Claim 16: "The self-review and cleanup steps follow the [orchestrated review pattern](../patterns/orchestrated-review.md), with commits/files as the units of review."

**Location:** `workflows/pr-prep.md:3`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The pattern file exists at the referenced path. PR prep is mentioned in the orchestrated review pattern as an instantiation (lines 16, 26, 38, 48).

**Evidence:** `patterns/orchestrated-review.md:16,26,38,48`

---

## Claim 17: "The diverge -> diagnose -> match -> decide structure follows the [orchestrated review pattern](../patterns/orchestrated-review.md), with candidate approaches as the units of parallel evaluation."

**Location:** `workflows/divergent-design.md:3`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The pattern file exists at the referenced path. Divergent design is mentioned in the orchestrated review pattern as an instantiation (lines 17, 27, 39, 49).

**Evidence:** `patterns/orchestrated-review.md:17,27,39,49`

---

## Claim 18: "invoke the code-review critic skills (`security-reviewer`, `performance-reviewer`, `api-consistency-reviewer`) on your branch diff"

**Location:** `workflows/pr-prep.md:37`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

All three referenced skills exist: `skills/security-reviewer.md`, `skills/performance-reviewer.md`, `skills/api-consistency-reviewer.md`.

**Evidence:** `skills/security-reviewer.md`, `skills/performance-reviewer.md`, `skills/api-consistency-reviewer.md`

---

## Claim 19: "pressure-test each severity-rated finding with three questions adapted from structured critique methods ([Cowen-critique](../skills/cowen-critique.md) moves 1 & 3, [Yglesias-critique](../skills/yglesias-critique.md) move 7)"

**Location:** `workflows/user-testing-workflow.md:225`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High

Both skill files exist at the referenced paths. CC move 1 is "Try the boring explanation first" which corresponds to UT's question 1 ("Is there a boring explanation?"). CC move 3 is "Follow revealed preferences, ignore stated ones" which corresponds to UT's question 3 ("What does the team's actual behavior suggest?"). However, the claim references YC move 7, which is "Swap in the implementation org chart" (yglesias-critique.md line 158). UT question 2 asks "Who implements the fix, and with what?" — this is loosely inspired by the org chart move but the connection is a stretch. The actual UT question is more about resource constraints than organizational structure. The attribution is directionally correct but the mapping from YC move 7 to question 2 is imprecise.

**Evidence:** `skills/cowen-critique.md:63-100`, `skills/yglesias-critique.md:158-170`, `workflows/user-testing-workflow.md:225-235`

---

## Claim 20: "In draft review: Optional mid-pipeline gate — if fact-check finds high-confidence inaccuracies, pause before running critics so the user can revise"

**Location:** `patterns/orchestrated-review.md:50`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The draft-review skill contains an explicit "Fact-Check Gate (optional)" section (lines 109-128) that pauses after fact-check results if claims are rated Inaccurate at high confidence, offering the user three options (Continue, Revise first, Skip critics).

**Evidence:** `skills/draft-review.md:109-128`

---

## Claim 21: "List all folders in `.skills/skills/`"

**Location:** `skills/draft-review.md:54`
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High

The draft-review skill instructs the agent to discover critic agents by listing folders in `.skills/skills/`. This directory does not exist in the repository. The actual skills are in the `skills/` directory at the repo root, stored as individual `.md` files rather than folders. This appears to be a reference to a different project structure (possibly the Claude Code built-in `.skills/` convention) that does not match the current repository layout. The skill's agent-discovery mechanism would fail when applied to this repository as-is.

**Evidence:** `.skills/` directory does not exist; skills are at `skills/*.md`

---

## Claim 22: "A template is available at `templates/gitattributes-snippet.txt` in this repo."

**Location:** `workflows/research-plan-implement.md:26`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The file exists at `templates/gitattributes-snippet.txt`.

**Evidence:** `templates/gitattributes-snippet.txt` exists

---

## Claim 23: "As a sub-procedure within RPI: When the research phase of `research-plan-implement.md` reveals a design decision, DD is invoked inline."

**Location:** `workflows/divergent-design.md:10`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

The RPI workflow explicitly describes this integration at lines 52-58: "If research reveals a genuine design choice... invoke the Divergent Design workflow (divergent-design.md) as a sub-procedure before proceeding to the plan step."

**Evidence:** `workflows/research-plan-implement.md:52-58`

---

## Claim 24: "Code review pipeline: Decompose into review concerns (security, performance, API consistency), dispatch domain-specific reviewer sub-agents, synthesize into a unified review, gate on severity"

**Location:** `patterns/orchestrated-review.md:66`
**Type:** Architectural
**Verdict:** Stale
**Confidence:** High

This is listed under "Potential future instantiations" of the orchestrated review pattern, but the three domain-specific reviewer skills (security-reviewer, performance-reviewer, api-consistency-reviewer) have already been built. They are described in decision document 002 as phase 1 of a phased approach, with the orchestrator deferred. The pattern document still describes this as a future possibility when the individual components already exist. The orchestrator itself has not been built yet, so the full pipeline is still future, but the description does not acknowledge that the component skills already exist.

**Evidence:** `skills/security-reviewer.md`, `skills/performance-reviewer.md`, `skills/api-consistency-reviewer.md`, `docs/decisions/002-critic-style-code-review.md:24-28`

---

## Claims Requiring Attention

### Incorrect
- **Claim 10** (`docs/decisions/002-critic-style-code-review.md:26`): The three code-review critic skills do not have Output Location sections directing output to `docs/reviews/`, unlike the prose critics they are modeled on.
- **Claim 21** (`skills/draft-review.md:54`): draft-review references `.skills/skills/` for agent discovery, but this directory structure does not exist in the repo. Skills are at `skills/*.md`.

### Stale
- **Claim 24** (`patterns/orchestrated-review.md:66`): Code review pipeline listed as "potential future instantiation" but its component skills already exist.

### Mostly Accurate
- **Claim 4** (`CLAUDE.md:45`): References `docs/working/` as parallel to `docs/reviews/` but `docs/working/` does not exist in this repo (it is project-specific, created in target projects).
- **Claim 19** (`workflows/user-testing-workflow.md:225`): Attribution of UT question 2 to YC move 7 is a loose mapping; the actual question focuses on resource constraints more than organizational structure.

### Unverifiable
- **Claim 5** (`docs/decisions/001-code-fact-checking.md:5`): "Cross-analysis matrix (Theme 9)" is not present in the repository and appears to reference an external document.
