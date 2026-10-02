Commit: 096042b (A) / 374d559 (B)

# API Consistency Review: dev-cycle digest + skill, loop pass 14 (pass-13 fix round)

**Scope:** A `git diff 591f098..096042b -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (096042b); B `git diff 44d06b7..374d559 -- skills/dev-cycle/SKILL.md` (374d559). This is a partial scope: the rest of both branches is context only.
**Date:** 2026-10-01
**Based on:** `docs/reviews/code-fact-check-report-digest-pass13.md` (Stage-1 context), `docs/reviews/api-consistency-review-2026-10-01-digest-pass13.md` (the findings this round fixes), and the shared brief for pass 14.
**Surface reviewed:** the digest's printed format (the Window line, section 2, section 3, section 8) and the A↔B contract (step 0's bullets, the record's `## Skipped inputs`, the stale-brief rule, and step 3, which consumes section 3).

Verification: `bats test/scripts/dev-cycle.bats` gives 23/23 ok. The worktree HEAD is dd1548a, which differs from 096042b only in docs/reviews, and `git diff 096042b dd1548a -- scripts test` is empty. The wt-devcycle HEAD 3d3b877 has no change to `skills/dev-cycle/` since 374d559. The probes ran on `git show 096042b:scripts/dev-cycle.sh` in a throwaway repo under `scratchpad/api14/` (`mktemp -d`, each run under `timeout 30`, removed afterwards). Their outputs are quoted below.

## Baseline Conventions

- **The skip predicate.** `blocker()` (dev-cycle.sh:103-113) is still the one rule. `inrepo` and the new `dirok` both run it before any lookup. `skipped`/`skipdir` record the blocking part in `SKIPPED`/`SKIP_AT`.
- **The inline skip sentence** (`skipnote`, :123) is `<input> is not read: <part> is not a plain file or directory (section 8).` Pass 13 settled on that phrase as the convention.
- **The failure banner in section 3** (:266) is `**questions.sh open failed** — watched questions were NOT checked. Its error:`. Skill step 3 (SKILL.md:156) keys on it: "If the digest says `questions.sh open` failed, fix that first".
- **Window variants.** There are four: (1) `--since`; (2) the last record, optionally followed by `; a newer record, … was skipped as not a plain file (section 8), …`; (3) `no readable cycle record (records, or a directory above them, were skipped as not a plain file or directory: section 8), so the default of 14 days`; (4) `no cycle record found, …`.
- **Step-0 matching.** Pass 13 found that step 0's bullets matched the Window text *verbatim* (pass-13 report, "What Looks Good"). Its F2 recommendation said to change the quoted trigger text in the same commit "so the substring match keeps working".
- **Entry filing.** In the skill, only the stale-brief rule guards against re-filing ("unless one is already open", SKILL.md:227).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `dirok` | function (private) | `inrepo`, `plaindir`, `rawfile` | `scripts/dev-cycle.sh:92-117` | Acceptable. It is the directory twin of `inrepo` (walk first, then a kind test), but the two names do not pair: `inrepo`/`dirok`. The helper is private and has no external consumer, so no finding. |
| `QA` | variable (private) | `QS`, `LOG` | `scripts/dev-cycle.sh:243,345` | Consistent. Upper-case short names for fixed paths. |
| `Not read: <part> is not a plain file or directory (section 8); its triggers are missing above.` | printed text | `skipnote` form `<input> is not read: <part> …` | `scripts/dev-cycle.sh:123,234` | Deliberate variant. It dedups by blocking part, so the input name is not available. It shares the phrase and the `(section 8)` pointer. |
| `No revisit triggers read: every decision input that exists was skipped.` | printed text | old `… decision records or the log were skipped as not plain files (section 8).` | `scripts/dev-cycle.sh:238` | Inaccurate in one case (F1). |
| `Watched questions were NOT checked: questions.sh reads the archive too.` | printed text | `**questions.sh open failed** — watched questions were NOT checked.` | `scripts/dev-cycle.sh:251,266` | Differs in shape from the banner, and the skill does not key on it (F3). |
| Window variant (3) `records, or a directory above them, were skipped` | printed text | step 0's `records (or a directory above them) were skipped` | `scripts/dev-cycle.sh:174`, `skills/dev-cycle/SKILL.md:103` | Matches in meaning but is no longer a verbatim substring (F2). |
| `Kept: <the answer's date>` | record field (semantics changed) | `Kept: YYYY-MM-DD` (date applied); `**Opened:** YYYY-MM-DD` | `skills/dev-cycle/SKILL.md:227`, `scripts/questions.sh:16` | Format kept. The source of "the answer's date" is not defined (F5). |

## Findings

#### F1. Section 2's "every decision input that exists was skipped" is false when readable inputs had no triggers

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:237-240` (A, 096042b)
**Move:** 3 (consumer contract), 8 (what the output asserts)
**Confidence:** High (reproduced)
**Legibility-target:** a human or the step-2 subagent reading section 2 alone

**Evidence (verbatim, code; the enclosing `if` ends at :240):**
```
if [[ $found -eq 0 ]]; then
  if [[ ${#SKIPPED[@]} -gt $n_before_triggers ]]; then echo "No revisit triggers read: every decision input that exists was skipped."
  else echo "No revisit triggers recorded."; fi
fi
```
**Evidence (verbatim, probe: `docs/decisions/001-plain.md` plain with no `## Revisit triggers`; `docs/decisions/log.md` a symlink):**
```
Not read: docs/decisions/log.md is not a plain file or directory (section 8); its triggers are missing above.
No revisit triggers read: every decision input that exists was skipped.
```

`found` stays 0 when a record is read but has no triggers heading (:207 `continue`), or when the log is read but has no revisit rows. Only the skip count is tested, so the sentence asserts something the code never checked. In the probe, `001-plain.md` exists and was read. The line above already names the one input that was skipped, so the two lines contradict each other. The impact is small, because the reader can see from the `Not read:` line which input is actually missing. The old wording ("decision records or the log were skipped") made no claim about every input and was accurate. Test 6/7 cover only the case where everything was skipped.

**Recommendation:** Say only what was checked, e.g. `No revisit triggers read; the inputs named above were not read.` Update the two test strings (dev-cycle.bats test 6, test 7). Add the probe above as a case: one plain record without triggers plus a symlinked log.

#### F2. Step 0's bullet 1 no longer matches Window variant (3) verbatim

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:103` (B, 374d559) against `scripts/dev-cycle.sh:174` (A, 096042b)
**Move:** 3 (consumer contract)
**Confidence:** High that the text differs; Medium on impact (a model matching by meaning still matches)
**Legibility-target:** the model running step 0

**Evidence (verbatim):**
```
- It says records (or a directory above them) were skipped, or names a newer record that was
```
```
    source_note="no readable cycle record (records, or a directory above them, were skipped as not a plain file or directory: section 8), so the default of 14 days"
```

Pass 13 recorded that the step-0 trigger text appeared in the Window text verbatim, and asked that the property be kept when the wording changed. Both sides were reworded in this round with different punctuation: parentheses in the skill, commas in the digest. A literal search for the skill's phrase in the Window line now finds nothing. Variant (2) ("names a newer record that was skipped") and bullet 2's "no cycle record was found" still match.

**Recommendation:** Make one side quote the other exactly. For example, the skill could say: It says `records, or a directory above them, were skipped`. Or the digest could drop the commas for parentheses.

#### F3. Section 3's new "archive skipped" state has no consumer in the skill and hides two other facts

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:248-251` (A, 096042b); `skills/dev-cycle/SKILL.md:156` (B, 374d559, unchanged context)
**Move:** 3 (consumer contract), 4 (error consistency)
**Confidence:** Medium
**Legibility-target:** the step-3 subagent

Precedent: `**questions.sh open failed** — watched questions were NOT checked.` used in `scripts/dev-cycle.sh:266`, keyed by `skills/dev-cycle/SKILL.md:156`

**Evidence (verbatim, code; the `if` chain continues to :272 with the run and absent branches):**
```
elif skipped "$QA"; then
  skipnote "$QA"; echo "Watched questions were NOT checked: questions.sh reads the archive too."
```
**Evidence (verbatim, skill step 3):**
```
- If the digest says `questions.sh open` failed, fix that first; the section was not checked.
```
**Evidence (verbatim, probe: `docs/working/questions.md` absent, archive a dangling symlink):**
```
docs/working/questions-archive.md is not read: docs/working/questions-archive.md is not a plain file or directory (section 8).
Watched questions were NOT checked: questions.sh reads the archive too.
```

Section 3 can now report "not checked" in two ways, and step 3 names only one of them: the bold `questions.sh open failed` banner. The new line is not bold, and it does not contain the phrase step 3 keys on. A model reading by meaning will probably still treat it as "not checked", but nothing tells it what to do: fix the archive, or record it as a skipped input only. The archive branch also comes before the absence and `QS` checks. So with no `questions.md`, the digest no longer prints `No docs/working/questions.md …`, which is the cue that pairs with step 0's `questions.sh init` instruction. And with no `questions.sh`, the line says that `questions.sh` "reads the archive too". Neither changes safety: `questions.sh` refuses to write through a symlink (questions.sh:98-99).

**Recommendation:** Extend step 3's bullet: "If section 3 says watched questions were NOT checked (`questions.sh open` failed, or `questions.md` or its archive was skipped), fix that first…". Optionally render the new line in the banner's shape (`**Watched questions were NOT checked** — …`).

#### F4. Step 0's `agent` entry has no "unless one is already open" guard

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:103-108` (B, 374d559)
**Move:** 9 (idempotency)
**Confidence:** Medium. Precondition: the non-plain record or directory persists for more than one cycle, for example while it waits on the user.
**Legibility-target:** the model running step 0 on later cycles

**Evidence (verbatim; the bullet ends at :108):**
```
  file or directory, so records may exist that the digest could not read. Note that in this
  record, file one `agent` entry listing the paths section 8 gives (never read, copy or
  rewrite through them), and rerun with `--since` set to the date of the last cycle you know
  ran (none known: keep the window the digest chose).
```

Every cycle that sees variant (2) or (3) files a new entry. Step 3 (SKILL.md:150-155) then treats each older one as a stale `agent` entry that "gets an action now". The stale-brief rule, rewritten in this same round, guards against exactly this ("unless one is already open", :227). This bullet does not. The bullet itself is older (pass-13 F3 covered its date and its path count), but it was rewritten here, so this is the place to add the guard.

**Recommendation:** Add "unless one is already open for the same paths (then add this cycle's date to it)".

#### F5. The stale-brief rule's comparison has an undefined operand in two cases

**Severity:** Informational (the rule terminates under every consistent reading)
**Location:** `skills/dev-cycle/SKILL.md:225-232` (B, 374d559)
**Move:** 9, 8
**Confidence:** Medium
**Legibility-target:** the model running step 6

**Evidence (verbatim; the bullet ends at :232 "slot."):**
```
  <item>?", unless one is already open: "keep" adds `Kept: <the answer's date>` to the brief,
  "drop" closes it as above. Apply an answer only if it is newer than the brief's last
  `Kept:` date (so each answer counts once); find it by searching `questions.md` and
```

Termination holds. A "keep" writes `Kept:` equal to its own date, so on later cycles the same answer is not newer and is skipped. A new ask needs 14 days past `Kept:`, and the open-entry guard stops repeat asks while one is open. Two gaps remain. (a) A brief with no `Kept:` line has no comparison date. Pass-13 F6 proposed "(or the brief's date)", but the fix left it out. Any reader applies the first answer anyway, so the effect is nil. (b) The questions grammar has no answer-date field (questions.sh:16 has only `**Opened:**`). Answer dates exist only by convention in prose (`**Answered YYYY-MM-DD:**` in the archive). A model could use `Opened:` instead, and that still terminates as long as it is used for both `Kept:` and the comparison.

**Recommendation:** Add "(no `Kept:`: the brief's date)". Name where the date comes from: "the date the answer was recorded in the entry".

#### F6. When `questions.md` itself is skipped, a non-plain archive is neither checked nor listed

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:248-249` (A, 096042b)
**Move:** 3
**Confidence:** High (reproduced)
**Legibility-target:** the record's `## Skipped inputs`

**Evidence (verbatim, probe: both `questions.md` and the archive are leaf symlinks, under a plain `docs/working/`):**
```
docs/working/questions.md is not read: docs/working/questions.md is not a plain file or directory (section 8).
...
- docs/working/questions.md
```

The first branch short-circuits, so the archive is not tested, and section 8 lists one of the two bad inputs. When the blocker is a parent this is correct: nothing below it is probed. When the blocker is the leaf, the archive could be tested safely, because it has the same ancestors. Fixing `questions.md` shows the archive one cycle later.

**Recommendation:** Optional: when `SKIP_AT` equals `docs/working/questions.md` exactly, also run `skipped "$QA" || true` so section 8 lists both. Otherwise keep it as is and accept that problems are found one cycle at a time.

## What Looks Good

- **Section 3's branch order is correct and complete for every combination checked.** The cases are: Q skipped (any archive state) → the Q note only, with the archive not probed. Q plain and archive skipped → the archive note plus NOT checked (test 10). Q plain and archive absent → `questions.sh` runs and its own error shows in the banner (probe: `✗ missing: …/questions-archive.md`). Q plain and archive plain → run. Q absent and archive plain or absent → `No docs/working/questions.md …`. The archive's ancestors are the same as Q's, so after branch 1 passes, `blocker "$QA"` is the only test it needs.
- **No lookup goes through a non-plain ancestor.** I traced every working-tree access. `dirok` (:149, :204) and `inrepo` (:215, :252, :285, :335, :346) run `blocker` before `-d`/`-f`. Glob items are `rawfile`d only inside a directory that passed `dirok`. `skipped`/`skipdir` only walk. `QS` is outside the repo. `git log -- "$f"` reads history, not the tree. When `blocker` stops early because a part is absent, the following `-f`/`-d` fails at that part. The duplicate realpath is gone (`inrepo` = walk + `-f`; the walk's leaf step already ran `rawfile`).
- **Section 2's skip lines.** `SKIPPED[@]:$n_before_triggers` covers only section-2 entries. The archive is added later, in section 3, so it cannot leak in. Duplicates collapse: when `docs/decisions` is a symlink, both the dir and the log record `docs/decisions/`, and `sort -u` prints it once. The order is the same `sort -u` order as section 8. The lines print whatever `found` is (test 10). The wording reuses the convention phrase and the `(section 8)` pointer.
- **The single phrase.** Every printed skip phrase now reads "not a plain file or directory". The one exception is the newer-record Window note, "not a plain file". Pass 13 judged that accurate (`SKIP_AT == f` guarantees the record itself blocked), and it remains accurate.
- **Step 0's bullet 1 holds for every Window variant.** (1) `--since`: neither bullet fires, so a rerun cannot loop. (2) A newer record: it fires, and the rerun date is the last cycle known to have run. (3) No readable record: it fires, and when no cycle is known the window is kept (no rerun). (4) No record found: bullet 2. Listing every section-8 path resolves pass-13 F3(b). The `--since` target resolves F3(a).
- **Tests.** Tests 6 and 7 update the strings for the two reworded messages. New test 10 asserts the section-2 skip line alongside a printed trigger, the archive gate, and that `questions.sh` did not run (`!= *"questions.sh open failed"*`, no target name leaked). All 23 pass.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | "every decision input that exists was skipped" is false when readable inputs had no triggers | Minor | `scripts/dev-cycle.sh:237-240` | High |
| F2 | Step 0 bullet 1 no longer matches Window variant (3) verbatim | Minor | `skills/dev-cycle/SKILL.md:103`, `scripts/dev-cycle.sh:174` | High / Medium |
| F3 | Section 3's archive-skipped state is not named by step 3; it hides absent `questions.md`/`questions.sh` | Minor | `scripts/dev-cycle.sh:248-251`, `SKILL.md:156` | Medium |
| F4 | Step 0's `agent` entry has no already-open guard | Minor | `skills/dev-cycle/SKILL.md:103-108` | Medium |
| F5 | Stale-brief comparison: no `Kept:` fallback; answer date has no defined source | Informational | `skills/dev-cycle/SKILL.md:225-232` | Medium |
| F6 | When `questions.md` is skipped at the leaf, a non-plain archive is not listed | Informational | `scripts/dev-cycle.sh:248-249` | High |

## Overall Assessment

The pass-13 fixes land. `dirok`/`inrepo` are correct, nothing is looked up through a non-plain ancestor, section 3 runs `questions.sh` only when both of its files are plain or absent, section 2 now names skipped inputs whatever else it printed, and the stale-brief rule terminates. Nothing here breaks a consumer. The four Minor findings are all fixable in place with one-line edits. F1 is a sentence that overclaims. F2 and F3 are matching gaps between what the digest prints and what the skill keys on. F4 is a missing idempotency guard that its sibling rule already has.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/api-consistency-review-2026-10-01-digest-pass14.md`, and its first line is the commit line. It follows the skill's structure: header, Baseline Conventions, Name-Pattern Audit, Findings (each with Severity, Location, Evidence verbatim, Confidence and Legibility-target, plus a Precedent line on the naming-shaped F3), What Looks Good, Summary Table and Overall Assessment. Toward the user goal (merging once a clean pass is reached), this pass has no Breaking or Inconsistent findings. It has four Minor findings (F1–F4) that block "no known issues", and two Informational ones.
