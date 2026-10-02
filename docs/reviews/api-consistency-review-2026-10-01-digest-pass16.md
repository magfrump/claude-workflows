Commit: 09f6fe7 (A) / 5423a33 (B)

# API Consistency Review: dev-cycle pass 16 (pass-15 fix round)

**Scope:** A `git diff f47de85..09f6fe7 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (09f6fe7); B `git diff cb2e5f9..5423a33 -- skills/dev-cycle/SKILL.md` (5423a33). Partial scope; everything else on both branches is context only.
**Date:** 2026-10-01
**Based on:** `docs/reviews/code-fact-check-report-digest-pass15.md` (Stage-1 context, k=1), the pass-15 API review (F1–F5) and the rubric's "Pass 15" rows R1, A1, A2, C1.
**Replication:** `bats test/scripts/dev-cycle.bats` at 09f6fe7: 23/23 ok. Probe: a throwaway script (`scratchpad/api16/probe.sh`, all repos under one `mktemp -d`, removed on exit, every run under `timeout`) ran the 09f6fe7 digest over questions.md {absent, plain, symlink, directory} × archive {absent, plain, symlink, directory} × questions.sh {present, absent}, plus a symlinked `docs/working/` with both files plain, for each questions.sh state. That is 34 runs; their section 3 and section 8 lines are summarised below. A second throwaway probe ran `questions.sh init` beside a symlinked archive.

## Baseline Conventions

- **Digest notice shapes (A).** A skipped input gets `skipnote`: "`<path>` is not read: `<blocker>` is not a plain file or directory (section 8)." (`scripts/dev-cycle.sh:123`). Every skipped input is appended to `SKIPPED`, and section 8 prints that list (`:371-377`). A section that could not do its job now prints one bold banner followed by the cause. Before this round, two banner styles existed: `**questions.sh open failed** — watched questions were NOT checked.` and `**Watched questions were NOT checked** — <skipnote>` (f47de85 `:253, :268`).
- **Skill keys on digest text (B).** Step 0 quotes Window-line phrases as exact substrings ("records, or a directory above them, were skipped", `SKILL.md:103` ↔ `dev-cycle.sh:174`). Step 3 keys on section 3's banner. Step 0's section map sends section 8 to the record's `## Skipped inputs` (`SKILL.md:96-99`).
- **Brief fields (B).** Build briefs carry `Capitalised-word:` lines: `Status: open|closed`, `Kept: <date>` (`SKILL.md:227, 233, 249`).
- **Questions grammar.** `**Needs:** <route> · **Opened:** YYYY-MM-DD · **Status:** OPEN|ANSWERED` (`scripts/questions.sh:16`). IDs are stable `Q-NNN`, and answered entries keep their ID when archived. The user answers with a one-line `Q-NNN: <answer>`.
- **Idempotency guards (B).** Filing steps carry an "unless one is already open" guard (step 0's `agent` entry, In-flight step 3).

## Name-Pattern Audit

| New name / string | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `nc` = `**Watched questions were NOT checked** —` (now used by all four not-checked branches) | printed banner | the f47de85 archive banner; the f47de85 `**questions.sh open failed** — …` banner | `scripts/dev-cycle.sh:251-259, 274` (09f6fe7); f47de85 `:253, :268` | Consistent. There is now one shape, bold consequence + em-dash + cause, which closes pass-15 F5 |
| `questions.sh was not found (next to this script or in ~/.claude/scripts).` | printed cause | the `QS` lookup | `scripts/dev-cycle.sh:243-244` | Consistent. It names exactly the two places the script looks, so it no longer reads as "in this repo" |
| `No docs/working/questions.md in this repo.` | printed status | step 0's cue "If the repo has no `docs/working/questions.md`" | `skills/dev-cycle/SKILL.md:99-100` | Consistent. The cue and the message name the same path, and the message now prints only for a truly absent file (probe: 8/8 absent runs, 0 others) |
| `qa_at` | local var | `SKIP_AT`, `skipped_record`, `last_record` | `scripts/dev-cycle.sh:102, 148` | Consistent (snake_case local holding a blocker path) |
| "keep or drop <brief path>?" | filed question text | "keep or drop the brief for <item>?" (cb2e5f9) | `skills/dev-cycle/SKILL.md:236` | Consistent with step 2's key ("names the brief's path"), but the key is wider than the text (F1) |
| `Answered:` (brief line, list of Q-IDs) | record field | `Status:`, `Kept:` (brief); `**Status:** … ANSWERED` (questions) | `skills/dev-cycle/SKILL.md:227-233`; `scripts/questions.sh:16` | Shape consistent; meaning differs from the questions grammar's `ANSWERED` (F4) |
| "watched questions were NOT checked" (step 3 key) | skill → digest key | step 0's exact-substring quotes | `skills/dev-cycle/SKILL.md:103` | Matches every banner by meaning; it is not an exact substring (case of "W") (F2) |

## Findings

#### F1. The brief-path key matches any question that names the brief, not only its keep-or-drop questions

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:228-237` (B, 5423a33)
**Move:** 3 (consumer contract: the questions files as a query surface), 9 (idempotency/duplicate-ask guard)
**Confidence:** Medium. The precondition is a second questions entry, open or answered, whose text contains the brief's path. Plausible cases: a `you: judgment` entry that blocks the item and links its brief under `**Read:**`, the step-0 `agent` entry listing skipped paths, or an `agent` entry about the brief's branch.
**Legibility-target:** the model running step 6 on later cycles

**Evidence (verbatim; In-flight step 2 runs :228-233, step 3 runs :234-237, and the list item ends at :237 "slot."):**
```
  2. If the brief is still open, apply answers to its keep-or-drop questions. Each such question names the brief's path;
     the brief keeps an `Answered:` line listing the IDs of the ones already applied. Search
     `questions.md` and `questions-archive.md` for questions naming this brief (the cycle's
     step 1 has already archived answered entries; search, do not read the archive whole), and apply
     each answered one whose ID is not on that line: "keep" adds its ID to `Answered:` and
     sets `Kept: <today>`; "drop" adds its ID and closes the brief as in 1.
  3. Then, if the brief is still open and the branch has no commit beyond the default branch (or does not exist yet) 14
     days after the brief's last `Kept:` date (none yet: the brief's own date), and no
     question naming this brief is open, file one `you: judgment` entry, "keep or drop <brief path>?". Until it is
     answered, the brief still holds its slot.
```

The first sentence of step 2 scopes the work to "its keep-or-drop questions". The operative search key is "questions naming this brief", though, and both "apply each answered one" and step 3's guard use that wider key. There are two consequences.

- **Step 3 (duplicate-ask guard).** Any open entry that mentions the brief path suppresses the keep-or-drop ask. If that entry is a stuck `agent` item, the stale brief keeps its slot for as long as the entry stays open. This is the same failure the 14-day clock exists to prevent, reached by a different route.
- **Step 2 (apply).** An answered entry that names the brief but is not a keep-or-drop question is a match. A careful reader skips it, since it is neither "keep" nor "drop", and its ID never reaches `Answered:`, so it is re-read every cycle, which is harmless. A literal reader might take an answer such as `[2] drop it` on a scoping question as a drop.

The ID-keying itself is correct (see What Looks Good). Only the selector is loose.

**Recommendation:** Key both steps on the filed text rather than the path alone. For example, step 2 could search "for `keep or drop <brief path>?`", and step 3 could check "no such question is open". This keeps the search key, the apply set and the duplicate guard identical.

#### F2. Step 3's key is not an exact substring of the banner, unlike step 0's quotes

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:156-158` (B, 5423a33); `scripts/dev-cycle.sh:251` (A, 09f6fe7)
**Move:** 2 (naming against the grain: skill→digest key strings)
**Confidence:** High
**Legibility-target:** the step-3 subagent

Precedent: skill keys quoted as exact substrings of digest text, used in `skills/dev-cycle/SKILL.md:103` ("records, or a directory above them, were skipped" ↔ `scripts/dev-cycle.sh:174`).

**Evidence (verbatim; step 3's bullet ends at :158 "the section was not checked."):**
```
- If the digest says watched questions were NOT checked (it gives the cause: a skipped
  questions file or archive, questions.sh missing, or `questions.sh open` failing), fix or
```
```
nc="**Watched questions were NOT checked** —"
```

The digest prints "Watched" with a capital W, inside bold markers. The skill writes "watched", not in quotes. A model reading by meaning matches it, and every one of the 25 probe runs that checked nothing carried the banner. Only a literal or `grep`-style check would miss it. The parenthesised cause list is complete. It names the four causes the digest prints: questions.md (or `docs/working/`) skipped, questions.sh missing, archive skipped, and `open` failing, which includes an absent archive (probe: `✗ missing: …/questions-archive.md`).

**Recommendation:** Optional. Quote the exact text, "**Watched questions were NOT checked**", to match step 0's convention.

#### F3. At 5423a33, B's own copy of the digest does not yet print the banner step 3 now relies on

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:249-274` as it stands at 5423a33 (B), against `skills/dev-cycle/SKILL.md:156-158` (B)
**Move:** 3 (consumer contract across the two branches)
**Confidence:** High
**Legibility-target:** the maintainer merging the branches

**Evidence (verbatim, `git show 5423a33:scripts/dev-cycle.sh`; the chain continues to :274 `fi`):**
```
if skipped docs/working/questions.md; then
  skipnote docs/working/questions.md
  skipped "$QA" || true  # still listed in section 8, so it shows this cycle
```
```
  echo "No docs/working/questions.md (or questions.sh) in this repo."
```

In B's own tree, a skipped questions.md and a missing questions.sh still print no banner. The skill's claim "whatever the cause" (commit 5423a33: "keys on the single … banner, whatever the cause") holds only once 09f6fe7 is merged into `feat/dev-cycle`. This is a merge-order dependency, not a defect, because the goal merges both branches. B must take A's 09f6fe7 before it lands. If B lands first, step 3 works only through the old `questions.sh open failed` and archive banners.

**Recommendation:** Merge `feat/dev-cycle-digest` (at or after 09f6fe7) into `feat/dev-cycle` before B lands. No text change is needed.

#### F4. The brief's `Answered:` line means "applied", while the questions grammar's `ANSWERED` means "answered by the user"

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:229-233, 251-252` (B, 5423a33)
**Move:** 2 (field naming), 8 (field contract)
**Confidence:** Medium
**Legibility-target:** the model running step 6; a user reading a brief

Precedent: `**Status:** OPEN|ANSWERED` used in `scripts/questions.sh:16`, where ANSWERED means the user has answered the entry.

**Evidence (verbatim; the sentence ends at :233 "as in 1."):**
```
     the brief keeps an `Answered:` line listing the IDs of the ones already applied. Search
```
```
     each answered one whose ID is not on that line: "keep" adds its ID to `Answered:` and
     sets `Kept: <today>`; "drop" adds its ID and closes the brief as in 1.
```

The procedure's selection rule is "answered, and not on `Answered:`". The rule works because the step spells out what the line holds, so this is not a defect. But the field's name matches the predicate it excludes, and a reader of the brief alone would take `Answered: Q-031` as a fact about Q-031 rather than about the brief. Two smaller format points:

- The ID separator on the line is unspecified.
- Step 2 "sets" `Kept:` (one line, replaced), while step 3 reads "the brief's last `Kept:` date". The two are compatible, because the set value is always the last, but they describe the field two ways.

**Recommendation:** Optional. Rename the line `Applied:` and say "comma-separated", or keep the name and add "(applied by this procedure)" in the build-brief format line at :251. Pick one of "sets" or "adds" for `Kept:`.

#### F5. Answers other than "keep" or "drop" have no stated handling

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:232-237` (B, 5423a33)
**Move:** 3 (consumer contract: the answer space of the filed entry)
**Confidence:** Medium
**Legibility-target:** the model running step 6

**Evidence (verbatim; step 2 ends at :233):**
```
     each answered one whose ID is not on that line: "keep" adds its ID to `Answered:` and
     sets `Kept: <today>`; "drop" adds its ID and closes the brief as in 1.
```

The filed entry, "keep or drop <brief path>?", must carry an options table under the global grammar. Step 3 does not name the options, and step 2 does not say what to do with any other answer, such as "keep but rescope" or a free-text reply. The outcome is benign. Such an answer is never added to `Answered:`, so it is re-read each cycle, which is a no-op. And once 14 days have passed since the last `Kept:` (or the brief's date), a fresh question is filed, since the answered one is no longer open. The step list is therefore not exhaustive over answers, but it terminates and never double-applies.

**Recommendation:** Optional. Name the two options in step 3 (`[1] keep`, `[2] drop`) and add "any other answer: record it in the brief, add its ID, and treat it as keep".

#### F6. When questions.md is absent, step 0's `init` cue can fail with no instruction for what follows

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:252-257` (A, 09f6fe7); `skills/dev-cycle/SKILL.md:99-100` (B, 5423a33)
**Move:** 3 (consumer contract), 4 (error consistency)
**Confidence:** High (reproduced)
**Legibility-target:** the model running step 0

**Evidence (verbatim, probe, section 3 / section 8):**
```
=== noqs wd=plain q=absent a=link rc=0
  s3 No docs/working/questions.md in this repo.
  s8 - docs/working/questions-archive.md
```
**Evidence (verbatim, `questions.sh init` beside a symlinked archive):**
```
  ✗ questions.sh: refusing to write: /tmp/tmp.FzbW46f0lB/docs/working/questions-archive.md is a symlink
rc=1
```

The chain checks "absent" before "questions.sh missing", so an absent questions.md hides a missing questions.sh. This is a deliberate order, and nothing is lost: with no questions file there is nothing to check. Step 0's cue then runs `~/.claude/scripts/questions.sh init`, and that fails in two states:

- questions.sh is not installed (command not found);
- the archive is non-plain (refused, rc=1).

Neither failure is silent, and in the second state section 8 already lists the archive, so the record's `## Skipped inputs` carries it. The skill just does not say what to do when `init` fails.

**Recommendation:** Optional. Add one clause to step 0: "if `init` fails, file its error as an `agent` entry, or in the record if there is no questions file, and continue."

#### F7. A re-brief at the same path would inherit an old brief's answered "drop"

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:228-233, 249` (B, 5423a33)
**Move:** 9 (idempotency across brief generations)
**Confidence:** Low. The precondition is narrow: on the same date, an item's brief is closed and a new brief with the same slug is written at `docs/working/handoffs/YYYY-MM-DD-<slug>.md`, for example by two cycles on one day with the user re-promoting the item in between.
**Legibility-target:** the model running step 6

**Evidence (verbatim; the format line ends at :253):**
```
For each, write `docs/working/handoffs/YYYY-MM-DD-<slug>.md`: `Status: open`, the line "repo
```

The commit's claim, "An old brief's answer never matches a new brief's path", holds whenever the paths differ, which is every case except the same date and slug. In that one case the new file starts with no `Answered:` line, so the old answered "drop" naming the same path applies and closes the new brief.

**Recommendation:** Optional. Write the new brief under a fresh slug if the path already exists, or seed it with the old brief's `Answered:` line.

## What Looks Good

- **A, section 3 is now one ordered chain, correct and complete.** In all 34 probe runs:
  - Absent questions.md prints exactly "No docs/working/questions.md in this repo." (8/8).
  - Skipped questions.md prints the banner plus a questions.md skipnote. The cases are symlink, directory and symlinked `docs/working/`, the last naming `docs/working/` as the blocker (18/18).
  - Missing questions.sh with a plain questions.md prints the "questions.sh was not found" banner (4/4).
  - A skipped archive with a plain questions.md and questions.sh present prints the archive banner (2/2).
  - An absent archive leads to the `open failed` banner with questions.sh's own `init` hint (1/1).
  - Plain/plain prints "None open." (1/1).
- **A, section 8 always lists a non-plain archive.** In every run where the archive is a symlink or a directory, section 8 lists `docs/working/questions-archive.md` (16/16), whichever branch printed. With `docs/working/` symlinked, the single blocker `docs/working/` is listed once (`sort -u`). This closes pass-15 F3.
- **A, `SKIP_AT` handling is correct.** The up-front `skipped "$QA"` result is saved in `qa_at`. The later `skipped docs/working/questions.md` call resets `SKIP_AT` (to "" when not skipped), and the archive branch restores `SKIP_AT="$qa_at"` before `skipnote`, so the note names the archive's blocker. `qa_at=""; skipped "$QA" && qa_at=…` is safe under `set -e` (a non-final `&&` member).
- **A, one banner style.** All four not-checked branches use the same `$nc` prefix, including `open` failing (`:274`). This closes pass-15 F5.
- **A, test 10.** Test 10 now covers the absent-questions.md case and the section-8 listing of a symlinked archive in that case. The commit 09f6fe7 message is accurate in every claim I checked: the chain order, "every not checked outcome prints the banner", and "a missing questions.sh no longer reads as a missing questions.md".
- **B, ID-keyed answers.** IDs are stable through `archive`, so "apply each answered one whose ID is not on that line" makes each answer apply exactly once regardless of dates, which closes pass-15 F1. The steps are ordered (1 → 2 → 3) and terminate. Steps 2 and 3 are gated on "still open". Step 2 runs before step 3 in the same cycle, so an answer is applied before the guard is evaluated. A "keep" sets `Kept: <today>`, so step 3 cannot fire in the same cycle. The guard prevents a duplicate ask, subject to F1's breadth.
- **B, 14-day clock.** It now reads "the brief's last `Kept:` date (none yet: the brief's own date)", the same parenthetical form as before. This closes pass-15 F4.
- **B, step 3's cause list** covers every banner cause the 09f6fe7 digest prints (F2 has the probe tally).
- **B, step 0's cue** ("If the repo has no `docs/working/questions.md`") still matches the digest's absent message exactly.
- **B, the brief format line** (:251-252) names both new fields and points back to In flight.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Brief-path key matches any question naming the brief; step 3's guard and step 2's apply set are wider than "keep-or-drop questions" | Minor | `skills/dev-cycle/SKILL.md:228-237` | Medium |
| F2 | Step 3's key not an exact substring of the banner (case), unlike step 0's quotes | Informational | `skills/dev-cycle/SKILL.md:156-158` | High |
| F3 | B's own digest copy at 5423a33 lacks the banner step 3 relies on; merge A into B first | Informational | `scripts/dev-cycle.sh:249-274` @5423a33 | High |
| F4 | `Answered:` (applied IDs) vs questions grammar's `ANSWERED`; separator and sets/last `Kept:` wording | Informational | `skills/dev-cycle/SKILL.md:229-233, 251-252` | Medium |
| F5 | No handling stated for an answer other than keep/drop (benign) | Informational | `skills/dev-cycle/SKILL.md:232-237` | Medium |
| F6 | Absent questions.md: step 0's `init` can fail (no questions.sh, or a symlinked archive) with no next step | Informational | `scripts/dev-cycle.sh:252-257`; `SKILL.md:99-100` | High |
| F7 | Same-date, same-slug re-brief inherits an old answered "drop" | Informational | `skills/dev-cycle/SKILL.md:228-233, 249` | Low |

## Overall Assessment

The digest side is clean. Section 3 is one ordered chain with a single banner shape. A non-plain archive is listed in section 8 on every branch. The 34-combination probe found no state where the section checked nothing without saying so, or where a skipped input went unlisted. On the skill side, ID-keyed answers fix pass 15's red: each answer applies once, the steps are ordered and terminate, and the clock and still-open gating are unambiguous. The one finding above Informational is F1. The search key, the brief's path, is wider than the questions it is meant to select, so an unrelated open entry naming the brief can hold off the keep-or-drop ask. It is fixable in place by keying on the filed text. Nothing here breaks an existing consumer. F3 is a merge-order note: B needs A's 09f6fe7 before it lands.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/api-consistency-review-2026-10-01-digest-pass16.md`. Its first line is `Commit: 09f6fe7 (A) / 5423a33 (B)`, and it carries the skill file's sections: header, Baseline Conventions, Name-Pattern Audit, Findings, What Looks Good, Summary Table, Overall Assessment. Every finding carries Severity, Location, verbatim Evidence with its truncation noted, Confidence and Legibility-target. The naming findings F2 and F4 carry a `Precedent:` line. Both briefed claim areas were covered: section 3 in every listed combination, and the In-flight steps, the format line and the step-3 banner reference. Nothing was committed, and no scratch was written outside `scratchpad/api16/` and the removed `mktemp -d` dirs.
