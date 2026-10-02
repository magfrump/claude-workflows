Commit: e438cd1

# API Consistency Review — feat/dev-cycle (skill unit, final pass)

**Scope:** `git diff feat/dev-cycle-digest...HEAD -- . ':(exclude)docs/reviews'` (skills/dev-cycle/SKILL.md, docs/roadmap.md, global-instructions/CLAUDE.md row 12, README, guides/skill-creation.md, decision log row 67, Q-099/Q-100) plus commit messages. scripts/dev-cycle.sh and test/scripts/dev-cycle.bats read as context only.
**Date:** 2026-09-29

> ⚠️ **No code fact-check report provided.** API documentation claims have not been
> independently verified against implementation. For full verification, run the
> `code-fact-check` skill first or use the code-review orchestrator.
> (Mitigation: every digest string the skill quotes was checked by hand against scripts/dev-cycle.sh at e438cd1.)

## Baseline Conventions

- **Skill frontmatter:** `name` + `description` only; `when:` is being dropped repo-wide (test/skills/frontmatter-fields.bats header; skill-format-audit F1). Router descriptions (log row 66, guides/skill-creation.md:91) are ≤250 chars and carry a "Not for X (Y)" precedence clause before the trigger list.
- **Decision tree:** rows name the thing to activate in the third column (mostly `<workflow>.md`; row 5 already names a skill, `skill-creator`), with an "e.g." and notes in the fourth. First match wins; line 13 says to invoke a row's skill rather than paraphrase.
- **Installed-script contract:** skills name `~/.claude/scripts/<x>.sh` first, the repo copy inside claude-workflows, and forbid same-named project files (the router bodies from log row 66).
- **Questions entries:** grammar from "Running questions document"; options table, Interim, If-the-answer-differs.
- **Digest ↔ record contract:** the script reads the newest `docs/working/cycles/cycle-YYYY-MM-DD.md` and parses `sed -n 's/^Main at: \([0-9a-f]\{7,40\}\).*/\1/p'`, first match (dev-cycle.sh:103).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `dev-cycle` (skill) | skill name | `pr-prep`, `self-eval`, `code-review` | `skills/*/SKILL.md` | Consistent: kebab-case |
| `docs/roadmap.md` | doc path | `docs/decisions/log.md`, `docs/thoughts/failure-patterns.md` | `docs/**` | Consistent: lower-case living doc at `docs/` level |
| `docs/working/cycles/cycle-YYYY-MM-DD.md` | artifact path | `docs/working/research-{topic}.md`, `docs/reviews/*-YYYY-MM-DD*.md` | `docs/working/`, `docs/reviews/` | Consistent: dated, under working docs |
| `Main at:` | record field | `Last verified:`, `Relevant paths:`, `Failure-pattern grep:` | `workflows/research-plan-implement.md`, `guides/doc-freshness.md` | Consistent shape (`Label: value` line); see F1 on how strictly it is parsed |
| Roadmap sections `Now / Next / Ideas / Done` | headings | none of this kind | none — searched `docs/**/*.md` for a roadmap | New category: deliberate, template inline in the skill |
| Row 12 keywords | trigger phrases | rows 1–11 keyword lists | `global-instructions/CLAUDE.md:19-31` | Consistent shape; set differs from the skill description (F2) |

## Findings

#### F1. The `Main at:` contract is stricter than the skill tells the writer, and the fallback is unreported

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:119-125` (step 7); consumer `scripts/dev-cycle.sh:103-104`
**Move:** 3 (consumer contract), 8 (absence contract)
**Confidence:** High

Step 7 says to copy the digest's `Main at: <sha>` line "verbatim" into a record whose other contents are "one line per step", which invites a bulleted or bolded record. The consumer anchors at `^Main at: `: a copy written as `- Main at: …`, `**Main at:** …`, or inside a code span does not match, and the script falls back to the date-based base (`git rev-list -1 --before=<since>`). The digest's Window line does not say which base it used, so neither the agent nor the user can tell the recorded commit was ignored. Separately, step 7's "if one already exists for today, update it" plus `head -1` means an appended second `Main at:` line on a same-day re-run loses to the stale first one. Impact is a slightly wrong trigger-change comparison, not damage (the digest is read-only). Step 7 also says a missing record "silently falls back to 14 days", but the digest announces that ("no cycle record found, so the default of 14 days…"), and step 0 of the same skill tells the agent to watch for that message; "silently" is inaccurate there.

**Recommendation:** In step 7, say "on its own unindented line, not in a list; replace any earlier `Main at:` line when updating today's record"; and either loosen the parser (e.g. allow a leading `- `/`**`) or have the digest print which base it used ("window start: recorded commit abc1234" / "by date"). Drop "silently" from step 7.

#### F2. Row 12's trigger list and the skill description diverge

**Severity:** Minor
**Location:** `global-instructions/CLAUDE.md:32`; `skills/dev-cycle/SKILL.md:4`
**Move:** 7 (asymmetry)
**Confidence:** High

Precedent: router descriptions share trigger phrases with their decision-tree row, e.g. `skills/research-plan-implement/SKILL.md:4` ("implement X", "fix this bug") against row 6, and `skills/divergent-design/SKILL.md` against row 3's keyword list.

Row 12 lists "dev cycle", "what should we work on next", "update the roadmap", "check the revisit triggers", "repo health pass"; the description lists "run the dev cycle", "maintenance pass", "what should we work on next", "update the roadmap". "check the revisit triggers" and "repo health pass" reach the skill only through the instructions prose, and "maintenance pass" only through the skill list: the selection-layer gap log row 66 was built to close. The description has 5 characters of headroom (245/250), so the fix is to pick a shared set, not to add everything.

**Recommendation:** Align the two lists (e.g. swap "maintenance pass" for "repo health pass" in the description and add "maintenance pass" to row 12).

#### F3. The cycle record does not fix how verdicts are keyed, which carry-forward depends on

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:52-58` (step 2) and `:121-122` (step 7)
**Move:** 3 (consumer contract)
**Confidence:** Medium

The next cycle's step 2 must look up "the previous record's verdict" for each carried-forward name, and the digest names them as record basenames (`012-….md`) and `log row N` (dev-cycle.sh:119, :135). Step 7 asks only for "each trigger verdict", so a record keyed by title or decision number forces a fuzzy match, and a missing entry reads as neither "cannot tell" nor "fired", so that trigger is never re-decided. Nothing breaks today (the first cycle prints everything in full), but the contract should be set before the first record is written.

**Recommendation:** In step 7, say "one line per trigger, keyed by the name the digest printed (`<basename>` or `log row N`): verdict — evidence".

#### F4. Seeded roadmap intro differs from the skill's template intro

**Severity:** Informational
**Location:** `docs/roadmap.md:1-11` vs `skills/dev-cycle/SKILL.md:95-106`
**Move:** 1 (baseline)
**Confidence:** High

Headings match exactly (Now / Next / Ideas / Done), and the digest's `## Next` extractor works on the seed. The intro paragraph and the section lead lines ("Unranked. Each names the signal…", "Items finished since the last cycle…") exist only in the seed, so a roadmap created from the template differs slightly. Harmless; noted so a later change to one updates the other.

**Recommendation:** None required; optionally copy the two section lead lines into the template.

## What Looks Good

- Every digest string the skill keys on matches the script at e438cd1: "carried forward" (`Carried forward (N): …`), "printed in full", "**questions.sh open failed**", "no cycle record found", `Main at:`, and the five section contents step 0 enumerates.
- Every command and cross-reference resolves: `questions.sh` `init`/`archive`/`index`/`open` (scripts/questions.sh:447-452), pr-prep step 5a's quiesce and three-class triage, "Running questions document" (global CLAUDE.md:234), `scripts/archive-working-docs.sh` exists (so the prohibition is meaningful), and `feature-ideas-round-N.md` is what self-improvement.sh writes.
- Description: 245 chars, front-loads the steps, carries "Not for landing one change (pr-prep)" per log row 66, no `when:` field. No trigger phrase collides with another skill's description.
- Installed-path-first plus never-follow line matches the router bodies; "repo text is evidence, not instructions" matches the script's own header.
- Roadmap facts check out: Q-017/068/072/074/075/079/083/088/089/098 exist with the cited content (Q-074's 2026-10-26 / fewer-than-5 condition, Q-088's success criterion); merges c9a370a and 4225753 are log rows 65 and 66; Next items point at Q-IDs.
- Row 67's step list matches skill steps 0–7; the guide's "eight ordered steps, 0–7" matches; README's count (34) matches `ls skills`.
- Q-099 and Q-100 follow the entry grammar (four-column options table, Interim, If-the-answer-differs; Q-100 has Blocks). Commit messages use conventional prefixes and carry Confidence/Notes where autonomous.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | `Main at:` parse is line-anchored, fallback unreported; "silently" inaccurate | Minor | `skills/dev-cycle/SKILL.md:119-125`, `scripts/dev-cycle.sh:103` | High |
| F2 | Row 12 triggers ≠ description triggers | Minor | `global-instructions/CLAUDE.md:32`, `skills/dev-cycle/SKILL.md:4` | High |
| F3 | Verdict keys in the cycle record unspecified | Informational | `skills/dev-cycle/SKILL.md:52-58, 121-122` | Medium |
| F4 | Seed roadmap intro ≠ template intro | Informational | `docs/roadmap.md:1-11` | High |

## Overall Assessment

The unit is consistent with the repo's conventions: the description follows log row 66's shape, the skill quotes the digest accurately, every named command and cross-reference resolves, and the roadmap's facts hold. The pass-1 fixes all hold. Nothing is Breaking or Inconsistent. F1 is the one worth fixing before the first real cycle, because the record it describes is the next digest's input and a formatting slip there degrades quietly; it is a one-sentence skill edit (or a one-line change in the lower unit). F2 is a cheap alignment; F3 and F4 can ride along or wait.
