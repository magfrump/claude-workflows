Commit: 36417f5 (A) / db24c74 (B)

# API Consistency Review — dev-cycle pass 18 (pass-17 fix round)

**Scope:** A: `git diff 723c242..36417f5 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (wt-digest; commits cf18055, 36417f5). B: `git diff 1f36885..db24c74 -- skills/dev-cycle/SKILL.md docs/dev-cycle.md` (wt-devcycle; commit db24c74). Partial scope: everything else is context only.
**Date:** 2026-10-02
**Based on:** `docs/reviews/code-fact-check-report-digest-pass17.md` (Stage 1, on 723c242 / 1f36885); prior critic pass `docs/reviews/api-consistency-review-2026-10-02-digest-pass17.md` (Findings 1–7 there are what this round fixes).

Method notes. I read the 36417f5 script's header, option parser, window logic and section 2 whole (`git show 36417f5:scripts/dev-cycle.sh`, lines 1–240) and the db24c74 skill whole. I read `scripts/questions.sh` (db24c74) for `assert_write_target(s)`, `cmd_init`, `cmd_archive`, `cmd_check` and the entry parser, and checked `docs/roadmap.md`, `docs/dev-cycle.md` and `docs/working/seed-build-loop-handoff.md` at db24c74. wt-devcycle HEAD c626285 merges 36417f5. `git diff --stat db24c74 c626285` on the skill, settings and seed is empty, and `git diff --stat 36417f5 c626285` on the script and bats is empty, so the two halves reviewed here are the ones that ship together. `timeout 600 bats test/scripts/dev-cycle.bats` in wt-digest (no `scripts/`/`test/` diff from 36417f5): 24/24 ok. I ran one date probe (`scratchpad/api18/probe.sh`) under `timeout 120` in a `mktemp -d` repo, removed on exit, against `git show 36417f5:scripts/dev-cycle.sh`. Nothing was written to either worktree except this report.

Legibility-target values follow the Stage-1 report: **agent** (the model running the skill acts on the text), **maintainer** (someone editing the script or tests), **user** (the human reading the digest or record).

## Baseline Conventions

- **Digest CLI and printed format** (unchanged this round). Long options in `--opt X` / `--opt=X` form plus `-h|--help`. Errors are one plain stderr sentence naming the flag, exit 1. There are eight `## N. Title` sections. Record headers read `### <path> (last committed on this branch: <YYYY-MM-DD | never, uncommitted>)`. GNU `date -d` already validates dates (`scripts/dev-cycle.sh:175,182`).
- **Questions grammar** (global CLAUDE.md "Running questions document", enforced in part by `questions.sh check`). Headers are `### Q-NNN · <slug>` with slug `[a-z0-9-]+`. Option cells are `**[N] <name>**`. The user answers `Q-NNN: [2]` ("a bare `[2]` is a complete instruction"). Answers are recorded inline as `**Answered YYYY-MM-DD: [2] — …**` (`docs/working/questions-archive.md:280`) or as free prose (`:186`, `:230`). The grammar promises "a stable ID and a name, so … two entries are never confused while reading". `cmd_check` rejects duplicate IDs and missing slugs. It does not reject duplicate slugs.
- **Repo paths in prose.** `docs/roadmap.md` writes repo files as backticked repo-root paths (`docs/working/seed-build-loop-handoff.md`, `docs/reviews/code-review-rubric-2026-08-07-main.md`), never as Markdown links. Brief files are `docs/working/briefs/YYYY-MM-DD-<slug>.md`, made unique ("a path no brief has used before; add `-2`, `-3`", SKILL.md:268-270).
- **Temp output.** Global CLAUDE.md "Tool Preferences": "Temp files: `$TMPDIR` or the session scratchpad, never bare `/tmp`". pr-prep: "Write the gate's full output to a file" (`workflows/pr-prep.md:335`), location unspecified.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `keep-or-drop-<brief slug>` | questions entry slug | `[a-z0-9-]+` slugs; unique brief paths `YYYY-MM-DD-<slug>[-N]` | `scripts/questions.sh` `cmd_check`; `skills/dev-cycle/SKILL.md:268-270` | Alphabet consistent. Not unique per brief or per ask: Finding 4 |
| answer tokens `[1]`/`1`/`keep`, `[2]`/`2`/`drop` (any case, "starts with") | answer grammar | `Q-NNN: [2]`; `**Answered …: [2] — …**` | global CLAUDE.md; `docs/working/questions-archive.md:280` | Tokens consistent. The anchor of "starts with" does not match either recorded form: Finding 2 |
| "plain-paths rule" (SKILL.md:92) | term | the rule's heading "Plain paths inside the repo only" (SKILL.md:61) | `skills/dev-cycle/SKILL.md:61` | Consistent: a clear back-reference |
| `.git` component (path rule) | path constraint | `..` component; digest `rawfile` "into .git" | `SKILL.md:65`; `docs/dev-cycle.md:27`; `scripts/dev-cycle.sh:91-94` | Consistent. Skill and settings doc now use the same "component" wording |
| brief link = backticked `docs/working/briefs/YYYY-MM-DD-<slug>.md` | roadmap field format | backticked repo-root paths in the roadmap | `docs/roadmap.md` (Now, Next) | Consistent with the roadmap. The skill's own verb "linking" is not: Finding 5 |
| help text "a plain file, a real date and not future-dated" | CLI help | `--since must be a real YYYY-MM-DD date` | `scripts/dev-cycle.sh:13,182` | Consistent. The same "real date" wording and the same `date -d` check |
| `--diff-merges=combined` | git invocation (internal) | per-file `git log -1 -- f` fallback | `scripts/dev-cycle.sh:219,228` | Private; noted for Finding 7 |
| `last_date`, `${last_date[$f]+set}` | private shell locals | n/a | n/a | Private. Not audited |

## Findings

#### 1. The widened plain-paths rule forbids the scratch files the cycle itself writes

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:61-62` (db24c74), against `:103-104` and `:126-128`
**Move:** 3 (contract against the rest of the instruction set)
**Confidence:** Medium
**Legibility-target:** agent

**Evidence (verbatim):**
> "**Plain paths inside the repo only.** The cycle, and every subagent it starts, reads and writes files only by plain paths inside the checkout. This covers every path taken from repo text: …" (SKILL.md:61-63; the paragraph continues to :74 with the lexical rule, the brief-link form, the symlink walk and the skip-and-list rule)

> "then run the repo's health check, if it has one …, to a file, and wait for it to finish" (SKILL.md:126-128)

> "Keep its output." (SKILL.md:104, the digest)

At 1f36885 the rule covered "repo files (idea sources and their glob matches, the idea log, briefs, the record, the roadmap, questions)". db24c74 widened the first sentence to "files", for the cycle and every subagent. Read literally, the health-check output file and the kept digest output must now sit inside the checkout. The global rule says temp files go to `$TMPDIR` or the scratchpad, so the two rules conflict. An agent that obeys the skill leaves untracked files in the cycle branch's working tree. "Stage named paths only" keeps them out of commits, but they show up in `git status`, and the health check runs from that tree. The same sentence also covers reading `~/.claude/scripts/questions.sh` and the global instructions, which the skill tells the agent to do. The commit message states the intent, which is scoping by source ("every path taken from repo text"). The second sentence carries that intent. The first sentence overreaches.

Precondition: an agent applies the rule's first sentence literally. Impact: stray scratch files in the checkout, or an agent that hesitates between two rules.

**Recommendation:** Scope the first sentence to repo files: "reads and writes repo files only by plain paths inside the checkout; scratch output goes where the global instructions put temp files". Keep the second sentence as it is.

#### 2. Keep-or-drop "starts with" has no anchor that matches either recorded answer form

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:245-248` (db24c74)
**Move:** 7 (write side vs read side) / 3
**Confidence:** Medium
**Legibility-target:** agent

**Evidence (verbatim):**
> "read the user's answer (the reply they wrote on the entry, such as `Q-NNN: [1]`): one that starts with `[1]`, `1` or `keep` (any case) sets `Kept: <today>` (YYYY-MM-DD); one that starts with `[2]`, `2` or `drop` closes the brief as in 1." (sentence complete; it continues "Either way add the ID to `Applied:` …")

The example answer begins `Q-NNN:`, not `[1]`. The repo's recorded form begins `**Answered 2026-09-17: [2] — …**` (`docs/working/questions-archive.md:280`). Read literally, "starts with" fails both, and the answer falls into "not applied". Most agents will strip the handle without being told. But this is the one place the skill moved from "is" to "starts with", and it gives an example that breaks its own rule. The token set itself is right: `[N]` and bare `N` are the global grammar's answer forms, and the words `keep`/`drop` cover prose answers such as "keep both — …" (`questions-archive.md:186`).

**Recommendation:** Say what the prefix is measured from, for example "the answer text after the `Q-NNN:` handle or the `Answered <date>:` label starts with …".

#### 3. An unapplied answer is re-noted every cycle while the brief is open, re-asked in the same cycle, and reported only in the record

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:244-256` (db24c74), against `:306-309` (final message)
**Move:** 4 (edge handling) / 9 (repeat-run behaviour)
**Confidence:** High (static; the whole of In flight checks 1–3 and Close read)
**Legibility-target:** agent, user

**Evidence (verbatim):**
> "For each answered ID not yet on its `Applied:` line … Any other answer is not applied: leave it off `Applied:` and note it in the record for the user." (SKILL.md:244-250)

> "3. Then, if the brief is still open, no ID on its `Asked:` line is still unanswered, and the branch has no commit beyond the default branch … 14 days after the brief's last `Kept:` date …, file one `you: judgment` entry" (SKILL.md:251-254; it continues with the slug, options and `Asked:` update to :256)

> "Then send the final message: list the new `you: judgment` entries by ID and name, and each open build brief by path" (SKILL.md:306-307)

This answers the brief's claim-2 question. Trace for an answer such as "not sure yet":
- **This cycle.** Check 2 leaves the ID off `Applied:` and notes it. Check 3 counts the ID as answered, not unanswered. If 14 days have passed since `Kept:` or the brief date, it files a new keep-or-drop entry at once. So step 3 does re-ask in the same cycle. That is reasonable, because the user gets a clean question.
- **Every later cycle.** The old ID is still answered and still off `Applied:`, so check 2 re-reads it in the archive and notes it again. This repeats until the brief closes, even after the user has answered the new entry with `[1]`. The record grows by one stale note per cycle.
- **What the user sees.** The note goes only into the record. The final message lists new entries and open briefs, not unapplied answers. Step 1 has already archived the answered entry, so the user learns about it only by reading the record.

There is also an undefined order. If the user edits the old answer to `[2]` and answers the new entry `[1]`, check 2 applies both in whatever order it visits the IDs.

**Recommendation:** Pick one end state. Either (a) add the ID to `Applied:` once a newer `Asked:` ID exists (the re-ask supersedes it), or (b) note an unapplied ID only in the cycle that first sees it, for example by recording it on a `Noted:` line. Also name unapplied answers in the final message, one line each.

#### 4. Entry slug `keep-or-drop-<brief slug>` is not unique per brief or per ask

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:254` (db24c74)
**Move:** 2 (naming)
**Confidence:** Medium
**Legibility-target:** user

Precedent: entries have "a stable ID and a name, so … two entries are never confused while reading" used in `~/.claude/CLAUDE.md` ("Running questions document"); brief paths made unique with `-2`, `-3` used in `skills/dev-cycle/SKILL.md:268-270`

**Evidence (verbatim):**
> "file one `you: judgment` entry, slug `keep-or-drop-<brief slug>`, asking \"keep or drop <brief path>?\"" (SKILL.md:253-255; the sentence continues with the options and the `Asked:` update)

Brief paths are unique by date plus slug, but the entry slug drops the date. Two collisions follow. Two briefs `2026-10-01-foo.md` and `2026-11-01-foo.md` are both allowed and can both be open, and both of their entries would be named `keep-or-drop-foo`. The same brief re-asked every 14 days produces another `keep-or-drop-foo`. `questions.sh check` does not flag either case, because it rejects duplicate IDs, not duplicate slugs. The question text names the full path, so a reader can still tell the entries apart. The index (`ID · slug`) and `questions.sh open` cannot.

**Recommendation:** Use the brief's file stem: `keep-or-drop-<YYYY-MM-DD>-<slug>`, which is unique per brief and still in `[a-z0-9-]`. Accept repeat asks as the one remaining duplicate, since their IDs differ and only one is ever open.

#### 5. Step 6 still says "linking" the brief; the rule now says a Markdown link does not count

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:237,260,273` vs `:66-68` (db24c74); `docs/working/seed-build-loop-handoff.md:55,66,98`
**Move:** 2 / 3 (documentation drift inside one file)
**Confidence:** Medium
**Legibility-target:** agent

Precedent: brief and doc references as backticked repo-root paths used in `docs/roadmap.md` (Now, Next)

**Evidence (verbatim):**
> "A brief link counts only if it matches `docs/working/briefs/YYYY-MM-DD-<slug>.md` …, written in the roadmap as that repo-root path in backticks, not as a Markdown link." (SKILL.md:66-68)

> "**In flight**: items with an open build brief, each linking it." (SKILL.md:237)

> "Move the item to In flight, linking the brief." (SKILL.md:273)

The new format matches the roadmap's existing style, which is good. But step 6 is where the cycle writes the reference, and the verb used there is "linking". An agent working in step 6 may write `[brief](working/briefs/…)`. Under the rule that reference "does not count", so it is skipped and listed every cycle. The In flight item then never reaches checks 1–3, so it never moves to Done and its keep-or-drop question is never asked. The seed repeats "linking its brief" and "a link to the brief" in quoted text. That text is historical and says so (`:43-45`), but the handoff unit is told to build on it.

**Recommendation:** In step 6, write "naming the brief by its path in backticks (Plain paths)" at `:237` and `:273`, and likewise "its brief path" at `:260`. Optionally, add one clause to the seed's note at `:43-45` naming the backticked form.

#### 6. The path rule's "(step 4 and step 2 read these)" leaves out steps 3 and 6

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:63-64` (db24c74)
**Move:** 3
**Confidence:** High
**Legibility-target:** agent

**Evidence (verbatim):**
> "and any file a commit message, decision-log row, plan or question names (step 4 and step 2 read these)."

Steps 4 and 2 read commit messages, plans and log rows. Questions are read by step 3, which checks the conditions of `trigger`/`deferred` entries and acts on `agent` entries, and by step 6 check 2. The rule itself says "every path", so it still applies there. Only the pointer is incomplete, and an agent working in step 3 may not recognise that the rule is about its own reads.

**Recommendation:** "(steps 2, 3, 4 and 6 read these)", or drop the parenthetical.

#### 7. The date map's documented difference is a class wider than the commit describes; the comment's condition is right

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:208-221` (36417f5); commit 36417f5 message
**Move:** 3 (printed field against the per-file lookup it replaced)
**Confidence:** High (executed)
**Legibility-target:** maintainer

**Evidence (verbatim):**
```
# to its own lookup. One known difference from per-file `git log -1`: when a
# merge kept the main line's version of a record but a side branch had changed
# it later, this date is that later side commit's.
```
(The comment begins at :208. The map build follows at :216-221, and the per-record lookup with the `+set` fallback at :227-228.)

Commit 36417f5: "a merge that discarded a later side change reports the side commit's date".

The brief's claim-1 question is whether the documented difference is the only one. In the probe (`scratchpad/api18/probe.sh`, 36417f5 digest), the per-file `git log -1` date and the digest header disagreed in three records, and all three fit the comment's condition: the merge's version equals the main line's, and a side commit touches the file later.
- **004, discarded side change** (the conflict resolved with `--ours`): per-file 2026-02-02, map 2026-02-08.
- **001, the identical change made on both sides:** per-file 2026-02-01, map 2026-02-05.
- **002, a change made and reverted on the side only:** per-file 2026-01-01, map 2026-02-07.

A rename (006: 2026-03-02), a side-only change merged cleanly (005), and an uncommitted record (007: `never, uncommitted`) all matched. The 24-test suite's new case covers quoted names and a merge-resolution change (each also fails on 723c242, because `"` and `\` names and merge-listed files missed the old map). So the comment states the general condition correctly. The commit message's "discarded" covers only one of the three shapes. In every case the printed date is a real commit on the branch that touched the file, so the header's "last committed on this branch" still holds. On git older than 2.31, `--diff-merges` is an unknown option. The process substitution's failure is not propagated, the map stays empty, and every record falls back to the exact per-file lookup, which is slow but correct.

**Recommendation:** Optional. Widen the comment's example: "(a discarded side change, the same change made on both sides, or one reverted on the side)".

#### 8. Small wording drifts: step 2's semicolon, the test name, and the skipped-record date

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:147-150` (db24c74); `test/scripts/dev-cycle.bats` "record dates match per-file git log, including quoted names and merge-only changes" (36417f5); `scripts/dev-cycle.sh:157` (36417f5)
**Move:** 3
**Confidence:** High
**Legibility-target:** agent, maintainer

**Evidence (verbatim):**
> skill: "(a trigger written elsewhere in a record is not found; an output line over 4096 bytes is cut; read the record itself then)"

> digest `:202`: "(a trigger written elsewhere in a record is not found; an output line over 4096 bytes is cut: read the record itself then)"

```
      skipped "$f" && [[ "$SKIP_AT" == "$f" && "$d" > "$skipped_record" && ! "$d" > "$TODAY" ]] && skipped_record="$d"
      continue
    fi
    date -d "$d" >/dev/null 2>&1 || continue  # a name that is not a real date
```
- **Step 2's punctuation.** The skill's `;` lets "read the record itself then" seem to apply to the not-found case as well. The digest's `:` ties it to the line cut.
- **The test name.** It says "merge-only changes", but the test exercises a change made in a merge's resolution. That is the same mechanism (combined diff), but a reader may look there for pass 17's merge-added record.
- **The skipped-record date.** The skipped-record branch (:154-158) does not apply the new real-date filter. A symlinked `cycle-2026-02-30.md` is named in the Window line as "a newer record … was skipped". The help text describes only the record the window starts from, so it stays accurate, and the effect is a spurious "may start too early" note that step 0 then handles.

**Recommendation:** Use `:` in the skill, as the digest does. Rename the test to "…quoted names and a merge-resolution change". Optionally, move the `date -d` check above the `rawfile` branch.

## What Looks Good

- **Fallback on any miss** (`[[ -n "${last_date[$f]+set}" ]] ||`, :228). This is exactly pass 17's recommendation. It tests set-ness, not emptiness, so a mapped date is never second-guessed and every miss gets the exact per-file lookup. With the combined merge diffs, the only remaining mismatches are Finding 7's class. Correct and complete for the record classes the brief lists (renamed, merge-added, merge-resolved, quoted, uncommitted).
- **Impossible record dates.** `date -d "$d" || continue` reuses the script's existing date validator (:175, :182), and the help text's new "a real date" uses the same words as `--since must be a real YYYY-MM-DD date`. The amended window test (`cycle-2026-02-30.md` beside 2026-02-10) fails without the guard, because the impossible date would become the window start and then fail at :182.
- **New tests.** The settings-file and briefs-directory skips are asserted in section 8 with the trailing-`/` directory form. `Open by route: none` is asserted with an empty questions doc. The date test compares every header against per-file `git log` instead of hard-coding dates, so it would catch any future divergence of the map on those shapes. 24/24 pass.
- **Step 1 init/archive against questions.sh.** This is correct and complete. `cmd_init` prints `= exists` and exits 0 for an existing file, so "creates only what is missing" is accurate and running it every cycle is safe. It runs `assert_write_targets` first, so a symlinked questions file fails init and the failure is noted. With questions.md present and the archive missing, init now creates the archive, which closes pass 17's Finding 4 gap. `archive` ends in `cmd_index`. "Go on: … reported, not guessed" restores the continue instruction, and step 3's "fix or report that first" still covers the digest side.
- **Step 0 wording.** The script-identity parenthetical now sits on the script, and the branch reference stands alone.
- **Step 2 caveat.** It mirrors the digest's section 2 lead sentence clause for clause, apart from Finding 8's punctuation.
- **Path rule, lexical part.** The skill (`no .. or .git component; it is read from the repo root`) and `docs/dev-cycle.md:26-27` (`relative to the repo root …, no .. or .git component`) now agree word for word on the constraints. The settings row `docs/working/feature-ideas*.md` complies. The brief-link pattern reuses the brief slug alphabet and the roadmap's existing backticked-path style. Subagent briefs now carry the rule (:92). Apart from Findings 1, 5 and 6, the path rule is correct and complete for every path class it names: settings rows and globs, brief links, and files named by commits, log rows, plans and questions.
- **Answer tokens.** `[N]`, bare `N` and the option word, case-insensitive, cover the global grammar's answer forms and the archive's prose answers. Not consuming an unmatched answer lets a corrected answer apply next cycle, as pass 17 Finding 3 asked.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Widened plain-paths rule forbids the cycle's own scratch files | Minor | `SKILL.md:61-62` | Medium |
| 2 | "Starts with" has no anchor matching `Q-NNN: [1]` or `**Answered …: [2]**` | Minor | `SKILL.md:245-248` | Medium |
| 3 | Unapplied answer re-noted every cycle, re-asked the same cycle, record only | Minor | `SKILL.md:244-256,306-309` | High |
| 4 | `keep-or-drop-<brief slug>` not unique per brief or per ask | Minor | `SKILL.md:254` | Medium |
| 5 | Step 6 says "linking"; rule says a Markdown link does not count | Minor | `SKILL.md:237,260,273` | Medium |
| 6 | "(step 4 and step 2 read these)" omits steps 3 and 6 | Informational | `SKILL.md:63-64` | High |
| 7 | Date-map difference is a class (discard, same change, side revert); commit says "discarded" | Informational | `scripts/dev-cycle.sh:208-221` | High |
| 8 | Step 2 `;`, test name "merge-only", skipped record not date-checked | Informational | `SKILL.md:147-150`; bats; `dev-cycle.sh:157` | High |

## Overall Assessment

The round does what pass 17 asked of the interface, and no finding is Breaking or Inconsistent. On the digest side, the record-date header now matches per-file `git log -1` for every record shape the brief lists. The single remaining difference is documented by a comment whose condition is accurate, and it never prints a date that is not a real commit on the branch. The impossible-date guard and the new tests are consistent with the script's existing conventions. On the skill side, the init/archive contract with `questions.sh`, the step 0 and step 2 wording, and the settings doc's path wording are now correct and aligned. The five Minor findings are all in B's new prose, and all can be fixed in place. One sentence overreaches (Finding 1). One example contradicts its own matching rule (Finding 2). The unapplied-answer path has no end state (Finding 3). The new slug drops the date that makes briefs unique (Finding 4). Step 6's verb contradicts the new link format (Finding 5). None of them suggests the author skipped the conventions: each is a seam where a new rule meets older text.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/api-consistency-review-2026-10-02-digest-pass18.md`, with first line `Commit: 36417f5 (A) / db24c74 (B)`. It follows the api-consistency-reviewer structure: header, Baseline Conventions, Name-Pattern Audit, Findings, What Looks Good, Summary Table and Overall Assessment. Every finding carries Severity, Location, Evidence (verbatim), Confidence and Legibility-target. Naming findings 4 and 5 carry `Precedent:` lines. The report covers the role's five areas:
- the digest's output and help after this round (Findings 7–8, What Looks Good);
- the digest↔skill contract (step 2 caveat, Finding 8);
- the keep-or-drop entry against the questions grammar (Findings 2–4);
- the brief-link format in the roadmap (Finding 5);
- consistency among the skill, `docs/dev-cycle.md` and the seed (Findings 1, 5, 6).

It also answers both brief claims. Claim 1: the documented difference is one class with three shapes (Finding 7). Claim 2: an unapplied answer is re-noted every cycle, and step 3 re-asks in the same cycle (Finding 3). Scratch work is confined to `scratchpad/api18/`, and nothing was committed.
