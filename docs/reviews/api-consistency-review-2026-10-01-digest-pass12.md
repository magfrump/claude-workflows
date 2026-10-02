Commit: 71e618d (A) / 8286c2b (B)

# API Consistency Review — dev-cycle loop pass 12 (pass-11 fix round)

**Scope:** A `git diff c034a75..71e618d -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (e08d526, 5dd5377, 71e618d); B `git diff a218ad8..8286c2b -- skills/dev-cycle/SKILL.md docs/working/questions.md`. Partial scope: everything else on both branches is context only.
**Date:** 2026-10-01
**Based on:** `docs/reviews/code-fact-check-report-digest-pass11.md` (loop pass 11 k=1 fact-check, Stage-1 context); rubric section "Pass 11".
**Execution:** `bats test/scripts/dev-cycle.bats` 22/22 at 71e618d. Probes P1–P5 ran in throwaway repos under `mktemp -d` in the scratchpad (`DEV_CYCLE_TODAY=2026-03-01`, each run under `timeout 30`). Nothing was written into either worktree except this file.

## Baseline Conventions

The consumer of the digest is the dev-cycle skill's agent. It reads the printed text: the Window line (step 0), the section bodies, inline "NOT read (section 8)" notes, and section 8 (copied into the record's `## Skipped inputs`). The conventions already set on the branch:

- **One rule for skipped and absent.** An input that exists but is not plain is *skipped* and named in two places: inline where it would have been read, and in section 8. An input that does not exist is *absent* and gets the section's own "No …" line (`scripts/dev-cycle.sh:96-99`).
- **Paths are printed repo-relative and in full** (`docs/working/cycles/cycle-$last_record.md` in the Window line at `:158`; section 8 entries; `### docs/decisions/…` headings). Directories carry a trailing `/` (`:109`, `:114`).
- **"None…" lines for empty sections** ("None open.", "None in the window.", "None: …").
- **Brief and record metadata are `Field: value` lines** (`Status: open` / `Status: closed` in briefs, `Model:` in the record).
- **Step 0's contract:** each Window-line wording maps to one diagnosis branch.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `skipped_record` | internal variable | `last_record`, `records_skipped` | `scripts/dev-cycle.sh:139,154` | Consistent: `<adj>_record` like `last_record` |
| Window note `; a newer record, cycle-<date>.md, was skipped as not a plain file (section 8), so this window may start too early` | printed message | `the last cycle record, docs/working/cycles/cycle-<date>.md`; `no readable cycle record (one or more were skipped as not plain files: section 8)` | `scripts/dev-cycle.sh:158,165` | Mostly consistent. The "skipped as not plain file(s) (section 8)" phrasing matches `:165`. The record is named by basename, but the same line names the other record by full path: F5 |
| `None: no input was skipped.` | printed message | `None open.`, `None in the window.` | `scripts/dev-cycle.sh:237,286` | Consistent. Also true now when inputs are merely absent (fixes pass-11 C1) |
| Section 8 header `Reached through a symlink, or not a regular file or directory, so not read; nothing below a listed directory was read or probed:` | printed message | inline `is not a plain file (reached through a symlink, or not a regular file): NOT read (section 8).` | `scripts/dev-cycle.sh:247,269` | Consistent in vocabulary. The "nothing … probed" promise is not kept for every entry (F1), and "not a … directory" misfits one case (F6) |
| `Kept: YYYY-MM-DD` | brief field | `Status: open`, `Status: closed`; record `Model:` | `skills/dev-cycle/SKILL.md:219-222,235,246` | Consistent `Field: value` shape |
| test title `a symlinked directory is listed and nothing below it is read or probed; …` | test name | `no input is read through a symlink, inside or outside the repo` | `test/scripts/dev-cycle.bats:126` | Consistent |
| test `a skipped newer cycle record is named in the window line` | test name | `the window defaults to the newest cycle record's date and says so` | `test/scripts/dev-cycle.bats:206` | Consistent |

## Findings

#### F1. `skipdir` probes below a non-plain parent: section 8 lists a directory beneath a listed directory, and the Window line flips between "no cycle record found" and "skipped" depending on what exists outside the repo

**Severity:** Inconsistent
**Location:** `scripts/dev-cycle.sh:114`, with call sites `:152` (`skipdir docs/working/cycles`) and `:195` (`skipdir docs/decisions`); Window wording `:164-168`; skill reader `skills/dev-cycle/SKILL.md:100-106`
**Move:** 3 (consumer contract), 7 (asymmetry between `skipped()` and `skipdir()`)
**Confidence:** High (executed)
**Legibility-target:** the cycle agent reading the Window line and section 8; the user reading the record's `## Skipped inputs`

**Evidence (verbatim):**
- Code: `skipdir() { if [[ -e "$1" || -L "$1" ]] && ! plaindir "$1"; then SKIPPED+=("$1/"); return 0; fi; return 1; }`. Compare `skipped()` at `:104-113`, which 5dd5377 changed to walk parents first ("below a parent that is not a plain directory nothing is probed").
- Header: `Reached through a symlink, or not a regular file or directory, so not read; nothing below a listed directory was read or probed:`
- P1 (`docs/working` → an outside dir that holds `cycles/`) section 8 lists both entries:
  ```
  - docs/working/
  - docs/working/cycles/
  ```
  and the Window line says `from no readable cycle record (one or more were skipped as not plain files: section 8), so the default of 14 days`.
- P2 (same symlink, outside dir without `cycles/`) section 8 lists only `- docs/working/`, and the Window line says `from no cycle record found, so the default of 14 days (the previous cycle, if any, did not write its record)`.
- P3/P4 (`docs` → an outside dir) show the same split. P3 lists `- docs/`, `- docs/decisions/` and `- docs/working/cycles/`. P4 lists only `- docs/`.

**What breaks:** Pass 11's A3 fix ("nothing probed below a failing parent") went into `skipped()` only. `skipdir()` still uses `-e`, which follows the symlinked parent. So section 8's new header promise is false whenever `docs/` or `docs/working/` is not plain. The digest's output also reveals whether `cycles/` or `decisions/` exists at the link target, which is the A3 leak again one level up. For the consumer contract, the worse effect is the P2/P4 Window line. It says "no cycle record found … the previous cycle … did not write its record" even though section 8 shows `docs/working/` or `docs/` was skipped. Step 0 reads that wording as its first branch ("or says no cycle record was found when one ran … that cycle skipped step 7"), not the skipped branch, so the agent records the wrong diagnosis and files no `agent` entry for the link. Precondition: a committed symlink, or a non-directory, at `docs/` or `docs/working/`. A FIFO or regular file at `docs/working` gives the same P2 shape, because `-e` on `docs/working/cycles` is false. Test 7 (`test/scripts/dev-cycle.bats:157`) covers only the case where the symlink sits at the globbed directory itself.

**Recommendation:** Give `skipdir` the same parent walk. One way: route it through `skipped()` (for example, factor the loop at `:106-110` into a helper that both call). After that, `docs/working/` is recorded at the cycles check, `records_skipped` becomes 1, and P2/P4 print the "no readable cycle record (… skipped …)" wording. Add a test-7 case with the symlink at `docs/working` (outside dir without `cycles/`) that asserts the Window wording and that section 8 holds no `docs/working/cycles/`.

#### F2. Inline notes for a file below a skipped parent say that file "is not a plain file", but section 8 never lists it and it was never probed

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:247`, `:269`, `:319`, `:338` (the `elif skipped …` branches), together with `skipped()` at `:109`
**Move:** 3 (consumer contract), 8 (presence/absence contract)
**Confidence:** High (executed)
**Legibility-target:** the cycle agent cross-checking an inline note against section 8

**Evidence (verbatim):** In P2 the outside directory holds no `questions.md` and no `idea-log.md`, yet the digest prints:
```
docs/working/questions.md is not a plain file (reached through a symlink, or not a regular file): NOT read (section 8).
- docs/working/idea-log.md: not a plain file (reached through a symlink, or not a regular file), NOT read (section 8)
## 8. Skipped inputs
- docs/working/
```

**What breaks:** Since 5dd5377, `skipped()` returns 0 and records the *parent* when the parent fails, so the inline note names a child path that section 8 does not contain. The note also states as fact that the file exists in some non-plain form, and the code deliberately did not check that. A reader who greps section 8 for the cited path finds nothing. The note's "is not a plain file" claim contradicts the "not probed" promise in section 8's header. The convention set at `:96-99` ("named where it would have been read and listed in section 8") now holds only when the file itself is the failing component.

**Recommendation:** When the failing component is a parent, have the inline note name it, for example `docs/working/questions.md: not read, its directory docs/working/ is not plain (section 8).` One option: `skipped()` sets a variable with the recorded path, and the four call sites print that variable.

#### F3. Step 0's two branches overlap for the newer-skipped-record Window line, and "the cycles directory" omits the parents that produce the same wording

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:100-106` (at 8286c2b)
**Move:** 3 (consumer contract)
**Confidence:** Medium
**Legibility-target:** the cycle agent executing step 0

**Evidence (verbatim):** `If the window starts before the last cycle you know ran (or says no cycle record was found when one ran), that cycle skipped step 7: note it in this record and rerun with `--since` set to that cycle's date. If instead it says records were skipped, or names a newer record that was skipped, a record (or the cycles directory) exists but is not a plain file: note that in this record, file one `agent` entry reporting the path (never read, copy or rewrite through it), and rerun with `--since` the same way.`

**What breaks:** Each Window wording does reach a branch. `one or more were skipped as not plain files` matches "says records were skipped", and `a newer record, cycle-<date>.md, was skipped` matches "names a newer record that was skipped". I checked both against P5 and the new test, and both are correct. The overlap: when a newer record was skipped, the window *also* "starts before the last cycle you know ran", so the first branch's condition holds as well. Only the word "instead" tells the agent the second branch wins, and an agent working top-down will already have matched the first. The two branches differ in what they record ("skipped step 7" vs a skipped link plus an `agent` entry). Separately, "a record (or the cycles directory)" does not cover `docs/` or `docs/working/`. Once F1 is fixed, those also produce the "records were skipped" wording, and the path to report is the one in section 8, not "the cycles directory".

**Recommendation:** Put the skipped-record check first ("If the Window line says records were skipped or names a skipped newer record, …; otherwise, if the window starts before …"), and say "a record or a directory above it (the path section 8 lists)".

#### F4. Stale-brief rule: the main case, a brief whose branch does not exist yet, is covered only by inference

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:219-223` (at 8286c2b)
**Move:** 3 (consumer contract)
**Confidence:** Low
**Legibility-target:** the cycle agent applying step 6 to In-flight items

**Evidence (verbatim):** `When a brief's branch has no commit beyond the default branch 14 days after the brief's date (or after its last `Kept:` date), file one `you: judgment` entry, "keep or drop the brief for <item>?", unless one is already open: "keep" adds `Kept: YYYY-MM-DD` to the brief, "drop" closes it as above. Until the user answers, the brief still holds its slot.`

**What breaks:** Briefs are written before anyone starts them, and the user creates the branch (`:270-272`). So the commonest stale brief names a branch that does not exist. "has no commit beyond the default branch" most naturally includes a missing branch, but an agent running `git rev-list main..<branch>` gets an error, not 0. Apart from this, the rule is correct and complete. It is unambiguous about the clock (the brief's date, reset by `Kept:`). It terminates: each answer closes the entry, "keep" restarts the clock, and "drop" closes the brief. It agrees with the cap ("while fewer than 3 briefs are open", `:234`) and with the record line `<k>/3 open (3/3: no new briefs)` (`:254`), because an unanswered entry leaves the brief open and counted.

**Recommendation:** Add "(a branch not created yet counts as none)".

#### F5. The Window note names the skipped record by basename, while the same line names the record it starts from by full path

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:160` (vs `:158`)
**Move:** 2 (naming), 7 (asymmetry)
**Confidence:** High
**Legibility-target:** the cycle agent filing the step-0 `agent` entry "reporting the path"

Precedent: repo-relative full paths for cycle records used in `scripts/dev-cycle.sh:158` (`docs/working/cycles/cycle-$last_record.md`) and in section 8's entries (`scripts/dev-cycle.sh:348`)

**Evidence (verbatim):** `Window: since 2026-01-01 (from the last cycle record, docs/working/cycles/cycle-2026-01-01.md; a newer record, cycle-2026-02-10.md, was skipped as not a plain file (section 8), so this window may start too early).` (P5)

**What breaks:** Step 0 now tells the agent to file an `agent` entry "reporting the path". The path in the Window line is not the path section 8 lists, so the agent has to rebuild it, and a grep for the printed string in section 8 matches only as a suffix. This is low impact, because the date is unambiguous.

**Recommendation:** Print `docs/working/cycles/cycle-$skipped_record.md`, as `:158` does.

#### F6. Section 8 header says "not a regular file or directory", but a plain directory standing at a file's path is listed under it

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:347`
**Move:** 8 (contract wording)
**Confidence:** High (executed)
**Legibility-target:** the user reading `## Skipped inputs`

**Evidence (verbatim):** P5 (`docs/roadmap.md` created as a plain directory):
```
Reached through a symlink, or not a regular file or directory, so not read; nothing below a listed directory was read or probed:
- docs/roadmap.md
```

**What breaks:** The entry is a directory, so "not a … directory" reads as false for it. The inline note at `:269` ("not a regular file") is accurate. This is a rare edge, so it is wording only.

**Recommendation:** Use something like "Reached through a symlink, or not the kind of entry expected (a regular file, or a directory where one is globbed)", or drop "or directory" and let the trailing `/` mark directories.

## Checked and correct

- **Section 2's count** (`:193`, now before `plaindir docs/decisions`). P3/P4 and test 7 print `No revisit triggers read: decision records or the log were skipped as not plain files (section 8).` R1 is fixed. Test 7's new assertion at `test/scripts/dev-cycle.bats:173` asserts what its comment says.
- **Window note** (`:143-147`, `:159-161`). These cases were checked:
  - Several skipped records: the newest non-future one is named (P5: FIFO `02-01`, dangling `02-10`, future `09-09` → `cycle-2026-02-10.md`).
  - A future-dated skipped record is ignored, as future readable records are.
  - Equal dates print no note, which is correct because the readable record has the same date.
  - With `--since`, no note is printed.
  - When no readable record exists, the `:165` wording applies.

  The new test (`:198`) asserts what its title says.
- **`skipped()` parent walk** for the inputs it actually receives. Every call site passes a fixed relative path or a glob item whose parent `plaindir` already passed, so absolute paths, `..` and trailing-slash names never reach it (an absolute path would return 1, "absent"; no caller passes one). Recorded parents are fixed names, so they cannot carry a newline. The glob items still get newline-to-space handling (`:111`).
- **`None: no input was skipped.`** (`:345`) matches the "None…" convention and test 8 (`:185`).
- **Q-103 [2]** now says "harness settings", identical to `docs/working/seed-build-loop-handoff.md:34` at 8286c2b.
- **Symlink-rule wording** (`SKILL.md:66-68`) now states the digest's extra non-regular-file skip.
- **No stale strings** remain. `every input is a plain file`, `they exist but their contents`, `listed once, never its contents`, `fix or report the link` and `open for 14 days` have no hits outside `docs/reviews/` on either branch.
- Tests: 22/22.

## What Looks Good

- All new printed texts reuse the established vocabulary ("not a plain file", "(section 8)", "NOT read"). The consumer still has one phrase to look for.
- `skipped_record` mirrors `last_record`, including the future-date guard, so the two date choices cannot drift apart.
- `Kept: YYYY-MM-DD` follows the `Field: value` metadata shape, and "keep"/"drop" map onto the existing `Status: closed` path rather than adding a new state.
- Step 0 now forbids reading, copying or rewriting through the skipped path, which closes pass-11 A2 without adding a new route.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | `skipdir` probes below a non-plain parent: section 8 header promise broken; Window says "no cycle record found" when `docs/working/` or `docs/` was skipped | Inconsistent | `scripts/dev-cycle.sh:114,152,195,164-168` | High |
| F2 | Inline notes name a child path, absent from section 8 and never probed, as "not a plain file" | Minor | `scripts/dev-cycle.sh:247,269,319,338` | High |
| F3 | Step 0 branches overlap for a newer skipped record; "the cycles directory" omits parents | Minor | `skills/dev-cycle/SKILL.md:100-106` | Medium |
| F4 | Stale-brief rule: a not-yet-created branch is covered only by inference | Minor | `skills/dev-cycle/SKILL.md:219-223` | Low |
| F5 | Window note names the skipped record by basename, the other by full path | Minor | `scripts/dev-cycle.sh:160` | High |
| F6 | Section 8 header "not a … directory" vs a listed plain directory | Informational | `scripts/dev-cycle.sh:347` | High |

## Overall Assessment

The pass-11 round fixed what it set out to fix. Section 2's count is right, the Window line names a skipped newer record, `skipped()` no longer probes below a failing parent, and the "None" line, the section 8 header, test 7's title, Q-103 and the symlink-rule wording all now match the behavior. The one remaining contract break (F1) is the same parent-probing rule applied to `skipped()` but not to its sibling `skipdir()`. When `docs/` or `docs/working/` is a symlink or a non-directory, this makes section 8 contradict its own header. It also lets the Window line steer step 0 into the "skipped step 7" diagnosis. A shared parent-walk helper fixes it in place, and a test-7 case would cover it. F2–F6 are wording-level and fixable in place. No finding needs a version or interface change.

## Goal-Alignment Note

Success criterion (verbatim from the brief): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is at `/workspace/.claude/wt-digest/docs/reviews/api-consistency-review-2026-10-01-digest-pass12.md`, first line `Commit: 71e618d (A) / 8286c2b (B)`. It follows the api-consistency-reviewer structure (title and header, Baseline Conventions, Name-Pattern Audit, Findings, What Looks Good, Summary Table, Overall Assessment). Every finding carries Severity, Location, Evidence (verbatim), Confidence and Legibility-target, and the naming finding (F5) carries a `Precedent:` line. It serves the user goal: one Inconsistent finding (F1) means this delta pass is not clean, and the review-fix loop needs another k=1 delta pass before the full clean pass.
