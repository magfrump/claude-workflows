Commit: f47de85 (A) / cb2e5f9 (B)

# API Consistency Review: dev-cycle pass 15 (pass-14 fix round)

**Scope:** A `git diff 096042b..f47de85 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (f920f0d, f47de85); B `git diff 374d559..cb2e5f9 -- skills/dev-cycle/SKILL.md` (cb2e5f9). Partial scope. Everything else is context only.
**Date:** 2026-10-01
**Based on:** `docs/reviews/code-fact-check-report-digest-pass14.md` (Stage-1 context, k=1), the pass-14 API review (F1–F6) and the rubric's "Pass 14" rows R1, A1–A3, C1.
**Replication:** `bats test/scripts/dev-cycle.bats` gives 23/23 ok. The worktree HEAD is a3e2fea, which only adds review docs, and `git diff f47de85 HEAD -- scripts test` is empty. Probe: a throwaway script under `scratchpad/api15/` (in `mktemp -d`, removed afterwards) ran the f47de85 digest over 3 questions.md states × 3 archive states × questions.sh present/absent. That is 18 runs, and their section 3 and section 8 output is quoted below.

## Baseline Conventions

- **Digest notice shapes (A).** A skipped input gets `skipnote`: "`<path>` is not read: `<blocker>` is not a plain file or directory (section 8)." Every skipped input is also added to `SKIPPED`, which section 8 prints. A section that could not do its job prints a bold banner: `**questions.sh open failed** — watched questions were NOT checked. Its error:` (`dev-cycle.sh:268`). The rule (`:96-101`) is that the blocking part is what section 8 lists and what the inline note names.
- **Skill keys on digest text (B).** Step 0 quotes Window-line phrases. Step 3 keys on section 3's banners. Step 0's "Its sections feed the steps" (`SKILL.md:96-99`) maps section 8 to the record's `## Skipped inputs`.
- **Idempotency guards (B).** Filing steps carry "unless one is already open". This was already true of the stale-brief ask and is now also true of step 0's `agent` entry.
- **Questions grammar.** `**Needs:** <route> · **Opened:** YYYY-MM-DD · **Status:** OPEN|ANSWERED` (`scripts/questions.sh:16`). There is no answer-date field. Answer dates exist only by archive convention (`**Answered 2026-09-12: …**`) and are absent from the one-line `Q-NNN: [2]` answer form.

## Name-Pattern Audit

| New name / string | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `**Watched questions were NOT checked** — <skipnote>` | printed banner | `**questions.sh open failed** — watched questions were NOT checked.` | `scripts/dev-cycle.sh:268` | Mostly consistent: same bold-lead + em-dash shape, but it bolds the consequence where the sibling bolds the cause (F5) |
| `No revisit triggers in the decision inputs that were read; the skipped ones above were not read.` | printed summary | `No revisit triggers recorded.`, `Not read: <p> is not a plain file or directory (section 8); its triggers are missing above.` | `scripts/dev-cycle.sh:234,239` | Consistent: it now asserts only what holds, and it points at the `Not read:` lines printed just above |
| `dirok` (comment reference) | helper name | `dirok`, `inrepo`, `rawfile`, `plaindir` | `scripts/dev-cycle.sh:92-120` | Consistent: the comment now names the gate the globs actually pass (`:149`, `:204`) |
| "records, or a directory above them, were skipped" (step 0 quote) | skill → digest key | the Window variant at `dev-cycle.sh:174` | `scripts/dev-cycle.sh:174` | Consistent: an exact substring of the printed text |
| "watched questions were NOT checked (a skipped archive)" (step 3) | skill → digest key | "`questions.sh open` failed" | `skills/dev-cycle/SKILL.md:156` | Consistent for the two banner states, but it does not cover two other not-checked states (F2) |
| `Kept: <the answer's date>`, "keep or drop the brief for <item>?" | skill record fields | the same strings in 374d559 | `skills/dev-cycle/SKILL.md:227-236` | Consistent: steps 2 and 3 quote the question identically, so the search key and the filed text match |

## Findings

#### F1. Step 2's "else today" answer date makes an undated "keep" apply every cycle and lets an old brief's answer apply

**Severity:** Inconsistent
**Location:** `skills/dev-cycle/SKILL.md:229-233` (B, cb2e5f9)
**Move:** 9 (idempotency), 3 (consumer contract with the questions grammar)
**Confidence:** Medium-High. The precondition is an answer recorded without a date. The questions grammar has no answer-date field (`scripts/questions.sh:16`), and the user's sanctioned one-line form `Q-NNN: [2]` carries none.
**Legibility-target:** the model running step 6 on later cycles

**Evidence (verbatim; step 2 ends at :233, step 3 follows at :234-237):**
```
     already archived answered entries), not by reading the archive whole. An answer's date
     is the one written with it, else today. Apply it only if it is dated after the brief's
     last `Kept:` date (no `Kept:` yet: on or after the brief's own date) and not after
     today, so each answer counts once and an older brief's answer never applies. "Keep"
     adds `Kept: <the answer's date>`; "drop" closes the brief as in 1.
```

Take an undated "keep" answer through two cycles.

- **Cycle N.** Its date is today_N. That is on or after the brief's date and not after today, so it applies, and `Kept: today_N` is added.
- **Cycle N+1.** Step 2 finds the same archived answer again, and its date is now today_{N+1}. That is after `Kept: today_N`, so it applies again and `Kept:` moves forward.

`Kept:` therefore follows the calendar. Step 3's 14-day clock never runs out, and the brief is never asked about again. It keeps its In-flight slot forever. This contradicts the step's own invariant, "so each answer counts once".

The same fallback breaks the second invariant, "an older brief's answer never applies". Suppose a new brief for the same `<item>` replaces an old one. An undated answer to the old brief's question is dated today, which is on or after the new brief's date, so it applies to the new brief.

The pass-14 F5(b) recommendation was to name where the date comes from. "Else today" names a source, but that source is not fixed: it moves each cycle. A dated "drop" and any dated answer behave correctly.

**Recommendation:** Pin the date the first time it is used. For example: "an undated answer: write today's date into it (`Answered YYYY-MM-DD`) when you first apply it, and use that date from then on". Another option is to use the entry's `Opened:` date, which questions.sh validates (`:267`). That stays fixed, and it is always on or after the brief's date for that brief's own question.

#### F2. Step 3's not-checked trigger misses two digest states that also leave watched questions unchecked

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:156-157` (B, cb2e5f9); `scripts/dev-cycle.sh:249-251, 272-273` (A, f47de85)
**Move:** 3 (consumer contract), 4 (error consistency)
**Confidence:** High (reproduced)
**Legibility-target:** the step-3 subagent

Precedent: `**questions.sh open failed** — watched questions were NOT checked.` used in `scripts/dev-cycle.sh:268`. Step 3 now keys on it at `skills/dev-cycle/SKILL.md:156`.

**Evidence (verbatim, skill step 3; the step ends at :157):**
```
- If the digest says `questions.sh open` failed, or that watched questions were NOT checked
  (a skipped archive), fix or report that first; the section was not checked.
```
**Evidence (verbatim, probe output, section 3 only):**
```
=== withqs qmd=link archive=plain rc=0
docs/working/questions.md is not read: docs/working/questions.md is not a plain file or directory (section 8).
=== noqs qmd=plain archive=plain rc=0
No docs/working/questions.md (or questions.sh) in this repo.
```

In both states the section checked nothing, but no text says so.

- **questions.md skipped.** Only the generic `skipnote` prints. Step 0's "If the repo has no `docs/working/questions.md`, run … `init`" does not fire either, because the file exists as a symlink.
- **questions.md plain, questions.sh not found.** The line reads as if questions.md were absent. "In this repo" is wrong for questions.sh, which is looked up in `$SCRIPT_DIR` and then `~/.claude/scripts` (`:243-244`). Step 0's `init` instruction cannot help, because questions.sh is the missing piece.

The step-3 subagent sees no `trigger`/`deferred` list and no banner. If it reads by meaning it will probably still conclude that nothing was checked. But the skill gives no instruction for either state, and the pass-14 F3 recommendation named the skipped-questions.md state explicitly. The round fixed the archive state only.

**Recommendation:** Print the banner in all three not-checked branches of `dev-cycle.sh`:
- `**Watched questions were NOT checked** — <skipnote questions.md>` when questions.md is skipped;
- `**Watched questions were NOT checked** — questions.sh not found (looked in <dir> and ~/.claude/scripts)` when questions.sh is missing;
- keep `No docs/working/questions.md in this repo.` only for a truly absent questions.md.

Then drop "(a skipped archive)" from step 3, so that it keys on the one phrase.

#### F3. Section 8 lists a symlinked archive in one "not read" branch but not in the other two

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:249-253, 272-273` (A, f47de85)
**Move:** 3 (consumer: the record's `## Skipped inputs`, via `SKILL.md:98-99`), 7 (asymmetry)
**Confidence:** High (reproduced)
**Legibility-target:** the record's `## Skipped inputs` and the maintainer

**Evidence (verbatim, code; the `if` chain continues to :274):**
```
if skipped docs/working/questions.md; then
  skipnote docs/working/questions.md
  skipped "$QA" || true  # still listed in section 8, so it shows this cycle
elif inrepo docs/working/questions.md && [[ -f "$QS" ]] && skipped "$QA"; then
  echo "**Watched questions were NOT checked** — $(skipnote "$QA")"
```
**Evidence (verbatim, probe; `s8` lines are section 8's list):**
```
=== withqs qmd=link archive=link rc=0
docs/working/questions.md is not read: docs/working/questions.md is not a plain file or directory (section 8).
   s8 - docs/working/questions-archive.md
   s8 - docs/working/questions.md
=== withqs qmd=absent archive=link rc=0
No docs/working/questions.md (or questions.sh) in this repo.
=== noqs qmd=plain archive=link rc=0
No docs/working/questions.md (or questions.sh) in this repo.
```

In all three runs the archive is a symlink and questions.sh is not run on it. Only the first run lists the archive in section 8. The added line's own rationale, "so it shows this cycle", applies equally when questions.md is absent or questions.sh is missing. In those two cases the record's `## Skipped inputs` omits a non-plain archive, and the problem surfaces only in the cycle after questions.md and questions.sh are both in place.

Probing is not the obstacle. The archive has the same ancestors as questions.md, and in these branches no ancestor blocked, so `skipped "$QA"` probes nothing below a non-plain part. That is the pass-14 What-Looks-Good trace. When a parent such as `docs/working/` blocks, the added line re-adds the same blocker, and `sort -u` at `:372` dedups it. That case is correct.

**Recommendation:** Move `skipped "$QA" || true` to run once before the chain, or in the `else` branch too, so that section 8's listing does not depend on which branch section 3 took. Add a test for the questions.md-and-archive-both-symlinked case, so the new line `:251` is covered. No test covers it now.

#### F4. Step 3's 14-day clause reads as a disjunction of two dates

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:234-236` (B, cb2e5f9)
**Move:** 7 (asymmetry between step 2 and step 3), 9
**Confidence:** Medium
**Legibility-target:** the model running step 6

**Evidence (verbatim; step 3 ends at :237 "slot."):**
```
  3. Then, if the branch has no commit beyond the default branch (or does not exist yet) 14
     days after the brief's date or its last `Kept:` date, and no such question is open, file
     one `you: judgment` entry, "keep or drop the brief for <item>?". Until it is answered,
```

The 374d559 text was "14 days after the brief's date (or after its last `Kept:` date)": a parenthetical substitution. Two lines earlier, step 2 spells out the same choice precisely: "the brief's last `Kept:` date (no `Kept:` yet: … the brief's own date)". Step 3 now joins the two dates with a bare "or". Read as a disjunction, it says a brief older than 14 days is asked again the day after a "keep", because "14 days after the brief's date" is already satisfied. The keep answer is then defeated. A careful reader will take the later date, but the two steps state one rule two ways.

**Recommendation:** Mirror step 2: "14 days after its last `Kept:` date (no `Kept:` yet: the brief's date)".

#### F5. The new banner bolds the consequence; its sibling bolds the cause

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:253` vs `:268` (A, f47de85)
**Move:** 2 (naming), 4
**Confidence:** High
**Legibility-target:** a reader scanning section 3

Precedent: `**questions.sh open failed** — watched questions were NOT checked.` used in `scripts/dev-cycle.sh:268`

**Evidence (verbatim):**
```
  echo "**Watched questions were NOT checked** — $(skipnote "$QA")"
```

Both banners share the bold-lead and em-dash shape, which is good. But the shared phrase "watched questions were NOT checked" is bold in one banner and plain in the other, so a reader cannot scan for one bold string. Step 3 keys on the phrase rather than on the bold text, so there is no behavioural effect.

**Recommendation:** Optional. Lead both banners with `**Watched questions were NOT checked** — <cause>`, as `:253` now does. That would also give F2's two new banners one shape.

## What Looks Good

- **Section 2's summary is now true in every combination.** `found=0` with no skips gives "No revisit triggers recorded." `found=0` with skips gives the new line, which claims only that the inputs read had no triggers and points at the `Not read:` lines, which always print just above it under that condition (`:231-236`). With `found=1`, there is no summary and the `Not read:` lines still print. The all-skipped case is vacuously true. Test 10's second run covers the mixed case: a plain record without triggers beside a symlinked log. This closes pass-14 F1 / R1. Test 10 does not assert `$status` on either run. That is a nit, not a contract issue.
- **Section 3's branch order now reports a missing questions.md/questions.sh before the archive check.** The pass-14 F3 complaint was that the archive notice hid those two facts. The probe confirms that all six questions.md-absent or questions.sh-absent rows print the absence line, and none blames the archive. The archive banner fires exactly in the case where questions.sh would have been run (`withqs plain/link`).
- **The comment changes are accurate.** `:246-248` correctly says what `questions.sh` does with the archive: an existence test that follows a symlink, not a read. This matches fact-check 7a. `:116` names `dirok`, the gate the globs pass at `:149` and `:204`.
- **Step 0's quote is exact.** "records, or a directory above them, were skipped" is a verbatim substring of `dev-cycle.sh:174`. The newer-record clause matches `:169` by meaning. The new "unless an open one already reports them" guard matches the stale-brief ask's idempotency convention, which closes pass-14 F2 and F4.
- **The In-flight steps are exhaustive, ordered and terminating, apart from F1 and F4.** The order is close → apply → ask. Step 2 runs after step 1's archive and before step 3's open-entry check, so the duplicate ask of fact-check G1 cannot happen. The date bounds (after `Kept:`, or on/after the brief's date when there is no `Kept:`; not after today) close pass-14 F5(a). Steps 2 and 3 quote the question text identically, so the search key matches the filed entry.
- **Step 3's banner reference matches the digest's text for the archive state** ("watched questions were NOT checked").

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | "Else today" date re-applies an undated keep each cycle; old brief's answer can apply | Inconsistent | `SKILL.md:229-233` (B) | Medium-High |
| F2 | Step 3 / section 3: skipped questions.md and missing questions.sh print no not-checked banner | Minor | `SKILL.md:156-157`; `dev-cycle.sh:249-251,272-273` | High |
| F3 | Section 8 lists a symlinked archive only when questions.md is skipped | Minor | `dev-cycle.sh:249-253,272-273` (A) | High |
| F4 | Step 3's "brief's date or its last `Kept:` date" reads as a disjunction | Minor | `SKILL.md:234-236` (B) | Medium |
| F5 | Banner bolds consequence vs sibling bolds cause | Informational | `dev-cycle.sh:253` vs `:268` (A) | High |

## Overall Assessment

The round closes what pass 14 asked of it:
- section 2's false summary (R1);
- the duplicate stale-brief ask (A1/G1);
- step 0's quote and guard (A3);
- the archive banner, plus its step-3 reference (part of A2).

The A↔B contract is consistent for every state the round targeted.

The remaining issues come from fixes that were applied to one case but not to its siblings:
- F2: two of the three not-checked states of section 3 still have no banner and no step-3 instruction.
- F3: the section-8 listing for the archive depends on which branch section 3 took.
- F4: step 3 does not mirror step 2's date rule.

F1 is the one with real consumer impact. Its "else today" fallback re-introduces the re-application that the `Kept:` rule exists to prevent, whenever an answer carries no date. The questions grammar does not require one. All of these are fixable in place with a sentence or a line each. None is Breaking. F1 needs an answer recorded without a date. F2 and F3 need a symlinked questions.md or a missing questions.sh. F4 needs a literal reading.

## Goal-Alignment Note

Success criterion (verbatim from the brief): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/api-consistency-review-2026-10-01-digest-pass15.md`, and its first line is `Commit: f47de85 (A) / cb2e5f9 (B)`. It follows the api-consistency-reviewer structure: header, Baseline, Name-Pattern Audit, Findings, What Looks Good, Summary Table and Overall Assessment. Every finding carries Severity, Location, verbatim Evidence, Confidence and Legibility-target, and the naming-shaped findings (F2, F5) carry a `Precedent:` line.

It covers the brief's claims:
- section 3 in all nine questions.md × archive combinations, with questions.sh both present and absent (18 probe runs);
- section 2's summary in every read/skipped/with-triggers combination;
- test 10's new assertions;
- commits f920f0d and f47de85;
- the In-flight steps: exhaustive, ordered, terminating, no duplicate ask, date bounds;
- step 0's quote;
- step 3's banner reference;
- commit cb2e5f9.

Nothing was written outside this file and `scratchpad/api15/`. The probe dir was removed. Nothing was committed.
