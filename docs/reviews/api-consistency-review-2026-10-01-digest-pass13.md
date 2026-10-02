Commit: 591f098 (A) / 44d06b7 (B)

# API Consistency Review: dev-cycle digest + skill, loop pass 13 (pass-12 fix round)

**Scope:** A `git diff 71e618d..591f098 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (6d6637d, 591f098); B `git diff 8286c2b..44d06b7 -- skills/dev-cycle/SKILL.md` (44d06b7). Partial scope: the rest of both branches is context only.
**Date:** 2026-10-01
**Based on:** `docs/reviews/code-fact-check-report-digest-pass12.md` (Stage-1 context); shared brief for pass 13.
**Surface reviewed:** the digest's printed format (Window line variants, section 2, inline skip notes, section 8) and the A↔B contract (step 0's two bullets, the record's `## Skipped inputs`, the stale-brief rule).

Verification: `bats test/scripts/dev-cycle.bats` at 591f098 gives 22/22 ok. Probes ran on a copy of `dev-cycle.sh` at 591f098 in throwaway repos under `scratchpad/api13/` (each under `timeout`). The cases were: `docs` a symlink; `docs` a regular file; a cycle record that is a directory; `docs/roadmap.md` a directory with `docs/decisions/log.md` a symlink while one record has triggers. Their outputs are quoted below.

## Baseline Conventions

- **Skip predicate.** One function, `blocker()` (lines 103-113), decides every skip. It walks the path top down. The first part that exists but is not plain blocks the path, and that part is printed: a parent gets a trailing `/`, a directory in dir mode gets `/`, and a file in file mode prints bare. `skipped()` records it in `SKIPPED` and `SKIP_AT`. `skipnote()` prints the inline sentence. `inrepo()` runs the walk before `rawfile()`. The glob loops call `rawfile()` directly, after `plaindir()` has passed on their directory.
- **Inline skip sentence.** Sections 3 and 5 print `skipnote` as a bare line, and section 7 prints `- $(skipnote ...)`. The shape is `<input> is not read: <blocking part> is not a plain file or directory (section 8).`
- **Window line source notes.** There are four variants: (1) `--since`. (2) `the last cycle record, docs/working/cycles/cycle-D.md`, optionally followed by `; a newer record, docs/working/cycles/cycle-D2.md, was skipped as not a plain file (section 8), so this window may start too early`. (3) `no readable cycle record (records or their directory were skipped as not plain: section 8), so the default of 14 days`. (4) `no cycle record found, so the default of 14 days (...)`.
- **Section 8.** A fixed header line, then `- <blocking part>` per entry, de-duplicated by `sort -u`.
- **Section 7 bullet shape.** Every line has the form `- <Label>: <value>`: `- Roadmap Now: n item(s)`, `- Roadmap: none yet (nothing to brief)`, `- Last brainstorm: ...`, `- Ideas seeded since: ...`, `- No docs/working/idea-log.md: ...` (lines 313, 322, 327, 338-346).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `rawfile` (renamed from the old `inrepo`) | function | `plaindir`, `inrepo`, `trig` | `scripts/dev-cycle.sh:92-120` | Consistent. It pairs with `plaindir`: both are bare predicates on one path with no walk. |
| `blocker` | function | `skipped`, `skipdir`, `plaindir` | `scripts/dev-cycle.sh:103-119` | Consistent. It is a noun-named function that prints a value, unlike the predicate names. That fits, because it returns text, not a status. |
| `skipnote` | function | `skipped`, `skipdir` | `scripts/dev-cycle.sh:118-120` | Consistent. It keeps the `skip*` prefix. |
| `SKIP_AT` | global var | `SKIPPED`, `SINCE`, `MAIN_SHA` | `scripts/dev-cycle.sh:71,102,126` | Consistent: upper-snake global. |
| `inrepo` (redefined: walk, then `rawfile`) | function | the old `inrepo`, `plaindir` | `git show 71e618d:scripts/dev-cycle.sh` | Consistent. Every fixed-name caller (log, questions, roadmap twice, idea log) keeps the same call shape, and only the semantics got stricter. |
| `skipped "$1" [file\|dir]` (new optional `$2`) | param | `skipdir "$1"` | `scripts/dev-cycle.sh:118-119` | Consistent. It defaults to `file`, so every one-argument call is unchanged. |
| Inline note `X is not read: P is not a plain file or directory (section 8).` | printed text | the old `X is not a plain file (...): NOT read (section 8).`; section 2's `No revisit triggers read: ... (section 8).` | `scripts/dev-cycle.sh:120,227` | Mixed. Sections 3, 5 and 7 now agree with each other, but section 2 does not use the form (F1, F2). |
| Section 8 header `Each is a symlink, or a file or directory of the wrong kind, ...` | printed text | the old header | `scripts/dev-cycle.sh:353` | Consistent with what `blocker` records. The trailing-slash convention is not explained (F4). |

## Findings

#### F1. Section 2 is the one section whose skip note neither names the blocking part nor appears when a trigger was found

**Severity:** Inconsistent
**Location:** `scripts/dev-cycle.sh:212-229` (A, 591f098)
**Move:** 4 (error/report consistency), 3 (consumer contract)
**Confidence:** High (probe D reproduces it)
**Legibility-target:** the step-2 subagent, which the skill feeds section 2 alone ("2 triggers (step 2)", SKILL.md:96-97)

Precedent: `skipnote <input>` inline at the point of use, used in `scripts/dev-cycle.sh:253,275,325,344`

**Evidence (verbatim, script):**
```
else
  skipped docs/decisions/log.md || true
fi
if [[ $found -eq 0 ]]; then
  if [[ ${#SKIPPED[@]} -gt $n_before_triggers ]]; then echo "No revisit triggers read: decision records or the log were skipped as not plain files (section 8)."
  else echo "No revisit triggers recorded."; fi
fi
```
**Evidence (verbatim, probe D: `docs/decisions/log.md` a symlink, `001-a.md` plain with a trigger):**
```
### docs/decisions/001-a.md (last committed on this branch: never, uncommitted)
> x

## 3. Watched questions (trigger and deferred routes)
```
and section 8 of the same run lists `- docs/decisions/log.md`.

This round moved sections 3, 5 and 7 to `skipnote`, which names the input and its blocking part where the input would have been read. Section 2 still has a single aggregate sentence, and that sentence prints only when *nothing* was found. If one record has triggers and the log, or another record, is skipped, section 2 says nothing about the skip. A step-2 subagent that gets only section 2 would then give verdicts for the triggers it sees, and nothing marks that the log rows are missing. The skill requires "one verdict for every trigger, under the name the digest prints" (SKILL.md:269). That count is now incomplete, and nothing in section 2 says so. Section 8 and the record's `## Skipped inputs` still list the skipped log, so the information exists in the digest, but not in the section that is handed to step 2. The behavior was there before this round, and the round's uniform-naming goal leaves it as the one exception.

**Recommendation:** Print a `skipnote` line in section 2 whenever a decision input is skipped, whatever `found` is. One line per blocking part is enough: `skipped docs/decisions/log.md && skipnote docs/decisions/log.md`, and once after the glob loop for records. Keep the `No revisit triggers recorded.` line for the clean case only. Add an assertion to test 6 or 7 with one plain record that has triggers plus a skipped log.

#### F2. One predicate is described three ways: "not a plain file or directory", "not plain", "not plain files"

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:120`, `:166`, `:171`, `:227` (A, 591f098)
**Move:** 2 (naming against the grain), 4
**Confidence:** High
**Legibility-target:** a human reading the digest or the record's Window line, and the skill's step 0 matcher

Precedent: `is not a plain file or directory (section 8)` used in `scripts/dev-cycle.sh:120` (`skipnote`, the form this round standardizes on)

**Evidence (verbatim):**
```
skipnote() { echo "$1 is not read: $SKIP_AT is not a plain file or directory (section 8)."; }
```
```
    source_note+="; a newer record, docs/working/cycles/cycle-$skipped_record.md, was skipped as not a plain file (section 8), so this window may start too early"
```
```
    source_note="no readable cycle record (records or their directory were skipped as not plain: section 8), so the default of 14 days"
```
```
  if [[ ${#SKIPPED[@]} -gt $n_before_triggers ]]; then echo "No revisit triggers read: decision records or the log were skipped as not plain files (section 8)."
```
**Evidence (verbatim, probe A: `docs` a symlink):**
```
Window: since 2026-09-17 (from no readable cycle record (records or their directory were skipped as not plain: section 8), so the default of 14 days). ...
No revisit triggers read: decision records or the log were skipped as not plain files (section 8).
docs/working/questions.md is not read: docs/ is not a plain file or directory (section 8).
```

In probe A one blocking part, `docs/`, produces three sentences, and each phrases the predicate differently. The Window says "records or their directory". The blocker here is `docs/`, which is two levels above the records' directory, not "their directory". Section 2 says "not plain files", although what blocked was a directory. The step-0 bullet in the skill names `docs/` and `docs/working/` itself, so the skill's matcher does not misread this. The wording still differs from `skipnote`, the form this round set as the convention. (The newer-record variant really is a file and its wording is accurate.)

**Recommendation:** Use one phrase everywhere ("not plain"), and say "records or a directory above them" in the Window variant, which matches SKILL.md:104-105. Change step 0's quoted trigger text in the same commit, so the substring match keeps working (see "What Looks Good").

#### F3. Step 0 bullet 1 leaves the rerun date and "the path" underdetermined when a directory blocks

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:103-107` (B, 44d06b7)
**Move:** 3 (consumer contract)
**Confidence:** Medium
**Legibility-target:** the model running step 0 of a cycle

**Evidence (verbatim):**
```
- It says records or their directory were skipped, or names a newer record that was skipped:
  a record exists but is not a plain file, or a directory above it (`docs/`, `docs/working/`,
  the cycles directory) is not. Note that in this record, file one `agent` entry reporting
  the path section 8 lists (never read, copy or rewrite through it), and rerun with
  `--since` set to the last cycle's date.
```

There are two consumer-side gaps. (a) For the newer-record variant, the Window names the date (`cycle-D2.md`). For the `no readable cycle record` variant, the digest names no date: below a blocking directory nothing is probed, by design, so record names cannot be known. "The last cycle's date" then has to come from what the agent knows. Bullet 2 says this explicitly ("the last cycle you know ran"), and bullet 1 does not. (b) "The path section 8 lists" is singular, but section 8 often lists several entries (probe D lists two, test 6 lists seven). The bullet does not say which entry goes into the `agent` entry: the record or directory that blocked the window, or every entry.

**Recommendation:** "...reporting the section-8 entry that blocks the records (`docs/`, `docs/working/`, `docs/working/cycles/`, or the record itself), and rerun with `--since` set to the newer record's date the Window names, or, when it names none, the date of the last cycle you know ran."

#### F4. The trailing `/` in section 8 marks the walk position, not the kind of thing skipped

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:108`, `:111-112`, `:353` (A, 591f098)
**Move:** 8 (nullability/shape contract), 7 (asymmetry)
**Confidence:** High (probes B and C)
**Legibility-target:** a human reading section 8 or the record's `## Skipped inputs`

No existing precedent in `scripts/dev-cycle.sh` and `skills/dev-cycle/SKILL.md` (no other output uses a trailing-slash convention). The tier was dropped from Minor to Informational.

**Evidence (verbatim, script):**
```
    plaindir "$p" || { printf '%s/' "$p"; return 0; }
  done
  [[ -e "$1" || -L "$1" ]] || return 0
  if [[ "$2" == dir ]]; then plaindir "$1" || printf '%s/' "$1"
  else rawfile "$1" || printf '%s' "${1//$'\n'/ }"; fi
```
**Evidence (verbatim, probe B: the cycle record is a directory; probe C: `docs` is a regular file):**
```
- docs/working/cycles/cycle-2026-01-01.md
```
```
- docs/
```

A directory sitting where a file was expected is listed without `/`, and a regular file sitting where a directory was expected is listed with `/`. The section 8 header says "nothing below a listed directory was read or probed". A reader who takes `/` to mean "directory" gets both cases wrong. Nothing is read through either one, so safety is not affected. Only the label is off.

**Recommendation:** Either state the convention in the header ("an entry ending in `/` blocked everything below it"), or leave the output as it is and accept the mismatch on purpose. No code change is needed.

#### F5. Section 7's skip lines break the `- <Label>: <value>` shape of their siblings

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:325`, `:344` (A, 591f098)
**Move:** 2
**Confidence:** High
**Legibility-target:** a human scanning section 7, and step 5's threshold check

Precedent: `- <Label>: <value>` used in `scripts/dev-cycle.sh:313,322,327,338-346`

**Evidence (verbatim, probe D):**
```
Step 5 (brainstorm triggers; the thresholds are the skill's):
- docs/roadmap.md is not read: docs/roadmap.md is not a plain file or directory (section 8).
- No docs/working/idea-log.md: no ideas seeded, no brainstorm recorded
```

Before this round the lines read `- Roadmap: not a plain file ..., NOT read (section 8)` and `- $LOG: not a plain file ...`, which fit the label shape. Reusing `skipnote` makes them match sections 3 and 5, and that is the larger consistency win this round wanted. The cost is a sentence with a final period among label lines. This is cosmetic, and I would not reverse the change for it.

**Recommendation:** None required. If wanted: `echo "- Roadmap: $(skipnote docs/roadmap.md)"`.

#### F6. Stale-brief answers from the archive have no "already applied" guard

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:224-229` (B, 44d06b7)
**Move:** 9 (idempotency), 3
**Confidence:** Medium. It depends on how a model reads "apply answers here" on a later cycle.
**Legibility-target:** the model running step 6 on the *next* cycles after an answer

**Evidence (verbatim):**
```
  brief's branch has no commit beyond the default branch (or does not exist yet) 14 days after
  the brief's date (or after its last `Kept:` date), file one `you: judgment` entry, "keep or drop the brief for
  <item>?", unless one is already open: "keep" adds `Kept: YYYY-MM-DD` to the brief, "drop"
  closes it as above. Apply answers here, reading `questions-archive.md` too (step 1 has
  already archived answered entries), and apply each before deciding whether to ask again.
  Until the user answers, the brief still holds its slot.
```

The archive is append-only (`scripts/questions.sh:3,30`: answered entries move there and stay). A "keep" answered in cycle N is still in the archive in cycle N+k. Read literally, "apply answers here" re-applies it every cycle, adding a fresh `Kept:` date each time. The 14-day re-ask would then never fire, and the brief would hold one of the 3 slots for good, which is the stale-slot problem this rule exists to prevent. The fix this round adds (also read the archive) is right for the cycle where the answer first arrives. It needs a bound so that later cycles skip that answer.

**Recommendation:** "Apply an answer only if it is newer than the brief's last `Kept:` date (or the brief's date); one `Kept:` line per answer, dated the answer's date." Using the answer's date rather than today keeps a re-application idempotent.

## What Looks Good

- **The single predicate holds.** `blocker()` is correct and complete for its two modes. An absent part returns empty (absent, not skipped). A dangling symlink parent counts as present (`-L`) and blocks. A non-directory parent blocks. Nothing below a blocking part is tested. Every fixed-name call site runs the walk before any lookup: `inrepo` at :212, :234, :269, :319, :330, `skipdir` at :158 and :201, and `skipped` at :224, :252, :274, :324, :343. Both glob loops (:147-156, :202-203) look things up only inside a directory that has passed `plaindir`. `plaindir` compares the realpath, which proves no ancestor is a symlink, so `rawfile` is the right test there. `QS` lives outside the repo and is gated behind `inrepo docs/working/questions.md`, so `questions.sh` never runs with a blocked `docs/working/`.
- **The same blocking part everywhere.** In probes A and C, `docs/` is the only section-8 entry, and every `skipnote` names `docs/`. In test 7's last block, `docs/working/` is the only entry and the questions note names it. The newer-record Window note now prints the full path that section 8 lists (`docs/working/cycles/cycle-D2.md`), which fixes the pass-12 mismatch.
- **Plain and absent inputs are never listed.** `blocker` prints nothing for either case, and test 9 (`None: no input was skipped`) covers the clean tree.
- **The comments above `rawfile`, `plaindir`, `blocker` and `inrepo` are accurate.** The `blocker` comment's newline claim ("a newline in a name becomes a space before it is ever printed") is substituted only on the final file-mode print. It is still true in practice, because parent components and dir-mode names are fixed literals and glob directories have passed `plaindir`.
- **`[[ "$SKIP_AT" == "$f" ]]` at :152** is always true after a passing `plaindir`, and the glob pattern cannot contain a newline. It is harmless, and it protects the guard if the loop ever changes.
- **The A↔B substring contract matches.** Step 0 bullet 1's "records or their directory were skipped" and "names a newer record that was skipped" match Window variants (3) and (2) verbatim. Bullet 2's "no cycle record was found" matches variant (4). A `--since` rerun prints variant (1), which triggers neither bullet, so the rerun cannot loop. Checking bullet 1 before bullet 2 is the right order, because variant (3) would otherwise also satisfy bullet 2's "window starts before the last cycle".
- **Section 8 feeds the record's `## Skipped inputs`.** The mapping is stated at SKILL.md:98-99, and the `- <path>` lines can be copied directly.
- **Tests.** Test 6 updates all its strings to the new note shape. Test 7's new block checks that `docs/working/` alone is listed, with nothing below it, plus the Window variant and the questions note. Test 10 checks the full-path Window note. All 22 pass.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Section 2 skip note missing when a trigger was found; never names the blocking part | Inconsistent | `scripts/dev-cycle.sh:212-229` | High |
| F2 | Three phrasings of "not plain"; Window says "their directory" when `docs/` blocks | Minor | `scripts/dev-cycle.sh:120,166,171,227` | High |
| F3 | Step 0 bullet 1: rerun date source and "the path" underdetermined | Minor | `skills/dev-cycle/SKILL.md:103-107` | Medium |
| F6 | Archived stale-brief answers have no already-applied guard | Minor | `skills/dev-cycle/SKILL.md:224-229` | Medium |
| F4 | Trailing `/` in section 8 marks position, not kind | Informational | `scripts/dev-cycle.sh:108,111-112,353` | High |
| F5 | Section 7 skip lines break the `- Label: value` shape | Informational | `scripts/dev-cycle.sh:325,344` | High |

## Overall Assessment

The round's main change works. Every skip is now decided by `blocker()`'s walk, every fixed-name lookup runs the walk first, and sections 3, 5 and 7, the Window and section 8 name the same blocking part in every probe I ran. The A↔B substring contract for step 0 matches all four Window variants, and the bullet order is right. Nothing here is Breaking.

The one Inconsistent finding (F1) is section 2. It was not migrated to the per-input `skipnote` convention, so a skipped log or record can disappear from the section that step 2 receives whenever another record has triggers. It can be fixed in place in two lines and one test assertion. F2, F3 and F6 are wording and contract-precision fixes, also in place. F6 is the one with a behavioral tail: a brief could keep its slot forever. F4 and F5 are cosmetic.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/api-consistency-review-2026-10-01-digest-pass13.md`, and its first line is the required `Commit:` line. It follows the skill's structure: header, Baseline Conventions, Name-Pattern Audit, Findings, What Looks Good, Summary Table, Overall Assessment. Every finding carries Severity, Location, Evidence (verbatim), Confidence and Legibility-target. Naming findings carry a `Precedent:` or `No existing precedent in` line, and the downgrade is applied to F4. Brief claims 1 and 2 are covered: `blocker` modes, call sites, consistency of the blocking part, plain and absent inputs, comments, tests 6, 7 and 10, commits 6d6637d, 591f098 and 44d06b7, step 0 bullets against every Window variant, and the stale-brief rule. Nothing was committed, and scratch files are only under `scratchpad/api13/`.
