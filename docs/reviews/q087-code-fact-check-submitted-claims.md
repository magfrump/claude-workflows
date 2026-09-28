Commit: 182d143

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q087 (branch `review/q087`)
**Scope:** Stage 2.5 submitted-claims pass only — three critic endorsements against `main...HEAD` at 182d143; no fresh harvesting
**Checked:** 2026-09-28
**Total claims checked:** 3
**Summary:** 3 verified, 0 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination pattern log: none of the three claims asserts a symbol or API; no logged pattern applies.

---

## Submitted Claims

## Claim 28: "In the Stage 1 replication paragraph, the only condition that selects k=1 is the `--loop-pass` flag. No rubric-file check remains in that paragraph."

**Submitted by:** security-reviewer
**Location:** `skills/code-review/SKILL.md:443-456`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the whole Stage 1 "Replication is loop-aware" paragraph (`:443-456`, read to its end; the next unit starts at `:458` "For each of the three replicate agents:"); does not establish that every other k-mentioning passage in SKILL.md is consistent with it — the Step 7 plan text at `:259-260` still says "3 fact-check replicates" unconditionally (pre-existing on `main`, not a rubric check, but it does not mention k=1 on loop passes).

The paragraph's only k=1 selector is the flag:

```
skills/code-review/SKILL.md:444-445
031 overrules the earlier blanket k=3 mandate).** Every `--loop-pass` of a review-fix loop
(which requires **2 consecutive clean passes** before merge) runs **k=1**. Run a
```

and the k=3 side is defined as the complement of the flag, with an explicit statement that no rubric check is used:

```
skills/code-review/SKILL.md:451-454
1−(1−p)³ for N≥3 draws). The **k=3 protocol below applies to every run without `--loop-pass`**:
standalone single-pass reviews and a loop's final confirming pass, which runs without the flag per
[Step 1](#step-1-determine-scope). The flag alone sets k, so no rubric check is needed to tell the
two apart. Loop passes review only the delta since the last stamp, so code no fix touched is drawn
```
(excerpt ends :454; paragraph continues to :456 — read; :455-456 are rationale citing decision log 63, no condition.)

The diff removes the former rubric test from this paragraph: `main` had "is recognized by the branch's canonical rubric existing without a `Loop closed at` line" and "(no `--loop-pass` and no open loop rubric for the branch)"; both lines are `-` lines in `git diff main...HEAD -- skills/code-review/SKILL.md` and no rubric/`Loop closed at` reference remains in `:443-456` (paraphrased — no quote available because the claim is about absence; `grep -n "Loop closed at"` on the file hits only `:121`, `:128`, `:739`, `:744`, all outside the paragraph).

On the critic's stated gap: mechanic 6 does read the rubric (`:735-744`), but only to decide the once-per-loop short-circuit; its k statement is `:739` "The run still implies `--no-gate` and k=1", which applies to a run that is already a `--loop-pass` run (the short-circuit is enabled only by the flag: `:247-248` "`--loop-pass` — mark this run as a **non-final pass** … Enables the [first-red short-circuit]"). So rubric state gates the short-circuit, not k. Step 7 (`:259-260`) reads "Total agent count (3 fact-check replicates + N critics, …" — no rubric check, but unconditional; this line is identical on `main` (`git show main:… | grep` hits `:260`), so it is a pre-existing count imprecision, not a residue of the removed check.

**Evidence:** `skills/code-review/SKILL.md:443-456`, `skills/code-review/SKILL.md:247-250`, `skills/code-review/SKILL.md:259-260`, `skills/code-review/SKILL.md:735-744`

---

## Claim 29: "A rubric gets `Loop closed at` only from a run without `--loop-pass`, so every closed loop's final pass is one that the new rule assigns k=3."

**Submitted by:** security-reviewer
**Location:** `skills/code-review/SKILL.md:126-128`, `skills/code-review/SKILL.md:450-453`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every written instruction in the repo (excluding `docs/reviews/` artifacts and `archive/`) that adds a `Loop closed at` line — SKILL.md Step 1, `references/rubric.md`, decision log row 60 — and the k rule that maps flagless runs to k=3; does not establish that an orchestrator actually omits `--loop-pass` on the final pass at run time (a procedural-compliance question, covered only by the instructions at SKILL.md `:249-250` and pr-prep 3d), nor what a clean *standalone* run writes (irrelevant to k, since it too is flagless and k=3).

The sole writer in SKILL.md is the final confirming pass, defined as the flagless run:

```
skills/code-review/SKILL.md:126-128
summary (Step 7). Only the final confirming pass (the one run to declare the branch clean) runs
without `--loop-pass`, and it keeps the full-branch default; when it is clean, it adds
`Loop closed at <reviewed HEAD sha>` under the rubric's `Commit:` line. Every earlier pass in the loop,
```
(excerpt ends :128; paragraph continues to :136 — read; remainder covers delta-range passes and the recall rationale, no other writer.)

The rubric reference agrees and adds no other writer:

```
skills/code-review/references/rubric.md:24-26
`-final` suffixes), or neither rule can find the file. When the final confirming pass is
clean it adds `Loop closed at <sha>` under the `Commit:` line; a later loop pass that finds it
starts a new loop with full-branch scope and removes both marker lines (same dated file) or leaves them out (new file); this is the one case where a prior loop's rubric is updated in place. Both rules
```

Loop passes only remove it (`:121-125` "remove both marker lines … or leave them out"), and mechanic 6's copy-forward copies the short-circuit marker "unless that file is closed (`Loop closed at`)" (`:743-744`), so no loop pass carries a `Loop closed at` line forward. Decision log row 60 (`docs/decisions/log.md:83`) says the same: "only the final confirming pass, run without `--loop-pass`, is full-branch, and when clean it writes `Loop closed at <sha>`". The flag definition forbids the flag on that pass: `:249-250` "Never pass it on the terminal pass". The k rule then maps it to k=3: `:451` "The **k=3 protocol below applies to every run without `--loop-pass`**". A repo-wide `grep -rn "Loop closed at"` (excluding `docs/reviews/`, `archive/`, `.git/`) returned only the five locations above (paraphrased — no quote available because the claim covers absence of any other writer; the grep result is a location list).

**Evidence:** `skills/code-review/SKILL.md:119-128`, `skills/code-review/SKILL.md:247-250`, `skills/code-review/SKILL.md:450-453`, `skills/code-review/SKILL.md:739-744`, `skills/code-review/references/rubric.md:21-28`, `docs/decisions/log.md:83`

---

## Claim 30: "k keys on one explicit input (the flag), not on inferred rubric state. This removes the ambiguity the u4 override row recorded"

**Submitted by:** api-consistency-reviewer
**Location:** `skills/code-review/SKILL.md:453-454`; `docs/reviews/override-log.md:131`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Stage 1 k rule, the two other places that restate it (`:20`, `:1279-1281`), and the u4 row's scenario (flagless second standalone review of a branch with an open canonical rubric); does not establish uniform k-wording elsewhere — Step 7's "3 fact-check replicates" (`:259-260`, pre-existing) is unconditional, and Stage 2.5's submitted-claims pass is a fixed k=1 keyed on the stage (`:1032-1035`), neither of which reads rubric state.

The rule is keyed on the flag alone:

```
skills/code-review/SKILL.md:453-454
[Step 1](#step-1-determine-scope). The flag alone sets k, so no rubric check is needed to tell the
two apart. Loop passes review only the delta since the last stamp, so code no fix touched is drawn
```
(excerpt ends :454; paragraph continues to :456 — read.)

Restatements match: `:20` "(k=1 on `--loop-pass` passes, decision 031; the loop's final confirming pass runs k=3, decision log 63)" and `:1279-1281` "k=1 per `--loop-pass` inside the review-fix loop …; k=3 for standalone single-pass reviews and the loop's final confirming pass (decision log 63)".

The u4 row's ambiguity was the rubric-state test:

```
docs/reviews/override-log.md:131
| 2026-09-28 | `feat/u4-code-review-skill` | ~~A second standalone review of a branch finds a canonical rubric with no `Loop closed at` line and is classed as a loop final pass, so it runs k=1 instead of k=3 (`skills/code-review/SKILL.md` Stage 1 replication) — fact-check iter3 claim 10~~ (moot since decision log 63: every run without `--loop-pass` is k=3) | …
```
(excerpt ends inside the row; remainder is the verdict/reason cells "🟢 Consider | Defer | … Revisit if Q-087 raises the final pass to k=3." — read.)

Under the new rule that second standalone review is flagless, hence k=3 by `:451`, whether or not a rubric exists; the misclassification cannot change k any more. The only remaining rubric-state reader near k is mechanic 6 (`:735-744`), which gates the short-circuit on an already-`--loop-pass` run, not k (see Claim 28).

**Evidence:** `skills/code-review/SKILL.md:20`, `skills/code-review/SKILL.md:443-456`, `skills/code-review/SKILL.md:1032-1035`, `skills/code-review/SKILL.md:1279-1281`, `docs/reviews/override-log.md:131`

---

## Claims Requiring Attention

None. (Scope notes on Claims 28 and 30 name one pre-existing adjacent imprecision: Step 7's plan text, `skills/code-review/SKILL.md:259-260`, says "3 fact-check replicates" unconditionally although loop passes run k=1. Unchanged from `main`; not a rubric check.)

---

## Goal-Alignment Note

- **Success criterion (verbatim):** a markdown report saved at the output path your role section names, structured per your role skill, every finding/claim carrying verbatim Evidence with `path:line`, and a Goal-Alignment Note appended.
- **Answered:** All three submitted claims (28–30) verdicted Verified with quoted `path:line` evidence, full enclosing-unit reads (Stage 1 paragraph `:443-456`, Step 1 paragraph `:113-136`, mechanic 6, rubric.md marker paragraph), and each critic's stated gap checked.
- **Out of scope:** No fresh harvesting from the diff; Step 7's unconditional "3 fact-check replicates" wording is noted as a pre-existing residue only, not verdicted as a claim; runtime compliance of orchestrators omitting `--loop-pass` is not verifiable statically.
- **Escalate:** None.
