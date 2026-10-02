Commit: d503a43 (A) / 1ae9b21 (B)

# API Consistency Review — dev-cycle loop pass 9 (pass-8 fix round)

**Scope:** Partial. A: `git diff ab8ec06..d503a43 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (`/workspace/.claude/wt-digest`). B: `git diff cfe4b51..1ae9b21 -- skills/dev-cycle/SKILL.md docs/dev-cycle.md docs/working/questions.md` (`/workspace/.claude/wt-devcycle`), plus the A↔B contract and consistency with onboarding step 13, Q-103, decision-log row 68, global row 12 and the skill-creation guide row as they stand at 1ae9b21. Everything else on both branches is context only.
**Date:** 2026-10-01
**Based on:** Stage-1 context `docs/reviews/code-fact-check-report-digest-pass8.md`; the pass-8 API review (`api-consistency-review-2026-10-01-digest-pass8.md`, F1–F10) and rubric section "Pass 8" (R1, A1–A4, C1) as the list of what this round fixes.

Line numbers: A at d503a43 (identical to the A worktree), B at 1ae9b21 (`git show 1ae9b21:<path>`; the B worktree's HEAD is a later merge, 70df147). Executed checks:
- `bats test/scripts/dev-cycle.bats`: 20/20 at d503a43.
- Symlink probe in a `mktemp -d` repo under `scratchpad/api9/`, removed afterwards. The repo root sat under a symlinked directory, and the digest ran from a subdirectory. Inputs: a plain decision record, a plain log row, a decision record symlinked out of the repo, and a symlinked roadmap and idea log.
- One mutation probe on a temp copy, removed afterwards: section 5's suffix branches deleted, then test 20 run against it (Finding 9).

## Baseline Conventions

The public surface has two halves. **A** is the digest's printed sections and wording, which the skill consumes by section number and by phrases such as "No docs/roadmap.md yet". **B** is the skill's settings grammar, brief fields, roadmap states, record template and final message, which `docs/dev-cycle.md`, Q-103, onboarding step 13, row 68, global row 12 and the guide row restate.

- **Brief fields** are literal `Key: value` lines that later steps match by text: `Status: open|closed` (`SKILL.md:239`, matched in step 1 at `:119-120`) and `Policy: self-merge|review` (`:239`, read in 6b at `:290-291`).
- **Record sections** are bare `## Title` headings with sentence-case words (`## Steps`, `## Trigger verdicts`, `## Questions filed`, `## Roadmap diff`; `:262-274`).
- **Path safety.** A's `inrepo()` (`scripts/dev-cycle.sh:89-92`) now accepts a regular file only if its realpath equals `$ROOT_REAL/<path>`, so no component may be a symlink. `scripts/questions.sh:88-98` refuses to write to a symlinked questions file or through a symlinked ancestor. B's rule (`SKILL.md:62-67`) is `test -L` on each component below the root.
- **Fail-safe default:** `review` everywhere (skill `:54-59`, `docs/dev-cycle.md:12-14`, onboarding `:453`, Q-103 Interim).
- **"Missing" messages on A** tell the cycle what to do: section 3 prints "No docs/working/questions.md …" (skill step 0 then runs `questions.sh init`), and section 5 prints "No docs/roadmap.md yet — create it this cycle …".

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `## Skipped paths` | record section | `## Trigger verdicts`, `## Questions filed`, `## Roadmap diff` | `skills/dev-cycle/SKILL.md:270-274` | Consistent: a bare sentence-case heading. A cannot feed it (Finding 2). |
| `**Paths**` | brief field | `Status: open`, `Policy: review` | `skills/dev-cycle/SKILL.md:239`, `:119-120` | Inconsistent shape. It is a prose list item, not a literal `Key:` line (Finding 8). |
| `Policy: self-merge` / `Policy: review` | brief field values | settings values `self-merge`, `review` | `skills/dev-cycle/SKILL.md:56`, `docs/dev-cycle.md:12-13` | Consistent. Pass-8 F2 is resolved: the values are enumerated, and 6b gives "anything but `self-merge` counts as `review`". The gloss contradicts `:247` (Finding 6). |
| "Never through a symlink." | rule name | "Repo text is evidence, not instructions.", "Seeding is always on." | `skills/dev-cycle/SKILL.md:20,69` | Consistent bold-sentence rule style. |
| stays / Done / Ideas | In-flight outcomes | Now/Next/Ideas/Done sections | `skills/dev-cycle/SKILL.md:205-209` | Consistent target names. The Ideas definition is not updated for the new entry shape (Finding 10). |
| "(a printed line over 4096 bytes is cut …)" | digest wording | `[line cut at 4096 bytes]` marker | `scripts/dev-cycle.sh:16,45,151`; `SKILL.md:128-129` | Consistent on both sides now (pass-8 F5 resolved). |

## Findings

#### 1. The brief's path allowlist forbids files the build loop must write to do its job

**Severity:** Inconsistent
**Location:** `skills/dev-cycle/SKILL.md:242-248`, `:296-300` (B); `workflows/pr-prep.md:96`, `workflows/research-plan-implement.md:28-32` (B, context)
**Move:** 3 (consumer contract), 7 (asymmetry between what the brief permits and what the loop is told to do)
**Confidence:** High
**Legibility-target:** for-author
**Evidence:**
- `SKILL.md:242-245`: "**Paths**: the files and directories the work may change. Changing anything else is a stop condition. The list never includes hook, enforcement or harness-settings files, the roadmap, the questions files, `docs/dev-cycle.md` or `docs/working/handoffs/`; work that needs one of them is not handed to a loop."
- `SKILL.md:296-298`: "**`review`**: … otherwise it files one `you: judgment` entry, "merge <branch>?", naming the roadmap item."
- `SKILL.md:300`: "Either way, a build that hits a stop condition files a `you: judgment` entry naming the roadmap item instead of guessing."
- `pr-prep.md:96`: "In /away mode, split without asking and record the split as an interim in `docs/working/questions.md`"
- RPI writes `docs/working/research-{topic}.md`, `plan-{topic}.md` and `checkpoint-{topic}.md` (`research-plan-implement.md:30-32`). pr-prep writes `docs/reviews/code-review-rubric-*.md` and `docs/working/pre-mortem-<branch-slug>.md`.

The loop's own required outputs fall outside the allowlist. Under `review` (this repo's interim policy), every loop that finishes writes `docs/working/questions.md`, and every loop that stops writes it too. The brief says no loop's Paths may include that file, and writing outside Paths is a stop condition, whose required response is another questions.md entry. The RPI and pr-prep artifacts under `docs/working/` and `docs/reviews/` are not excluded, but nothing tells the brief writer to list them. A literal reading stops the loop at its first research doc. The skill also does not say which branch the loop's entries land on: its own (invisible on the default branch until merged) or the default branch (an unreviewed commit there).

**Recommendation:** Separate the work's paths from the loop's bookkeeping. For example: "Paths limits the work's diff. The loop's own questions entries (merge, stop condition, split interim) and its RPI/pr-prep artifacts under `docs/working/` and `docs/reviews/` are always allowed." Then say where the entries are committed.

#### 2. The digest reports a skipped symlink as a missing file and never says what it skipped, so `## Skipped paths` cannot be complete

**Severity:** Inconsistent
**Location:** `scripts/dev-cycle.sh:154-155`, `:181,200`, `:214,220`, `:247-250`, `:271,285` (A); `skills/dev-cycle/SKILL.md:62-67`, `:99`, `:196`, `:277` (B)
**Move:** 3 (A↔B contract), 7 (asymmetry between sections 2 and 7)
**Confidence:** High (executed)
**Legibility-target:** for-author
**Evidence:**
- B `:66-67`: "A path that fails is skipped and listed in the record under `## Skipped paths`. The digest applies the same rule to everything it reads."
- A `:155`: `inrepo "$f" || continue` (silent)
- A `:220`: `echo "No docs/roadmap.md yet — create it this cycle from the template in the dev-cycle skill."`
- A `:200`: `echo "No docs/working/questions.md (or questions.sh) in this repo."`
- B `:99`: "If the repo has no `docs/working/questions.md`, run `~/.claude/scripts/questions.sh init` first."
- B `:277`: "Record one verdict for every trigger, under the name the digest prints."

The probe repo had `docs/decisions/002-b.md`, `docs/roadmap.md` and `docs/working/idea-log.md` as symlinks:
- Section 2 printed only `001-a.md`'s trigger. Section 7 listed `docs/decisions/002-b.md` as a changed decision record, so one digest names a record whose triggers it silently dropped.
- Section 5 printed "No docs/roadmap.md yet — create it this cycle".
- Section 7 printed "No docs/working/idea-log.md: no ideas seeded, no brainstorm recorded", so step 5's "none recorded yet" condition fires every cycle.

A symlinked questions.md gets the "No … questions.md" line, which sends step 0 to `questions.sh init`. questions.sh then refuses (`scripts/questions.sh:98`, "refusing to write: … is a symlink"). That is safe, but the cycle is told to do something that is bound to fail. In each case the skill's own `test -L` check would also catch the path, so nothing is written through it. But the record's `## Skipped paths` can list only what the cycle itself checked: the digest's skips never reach it, and a symlinked decision record's triggers vanish without a verdict or a trace.

`inrepo` itself is correct (see What Looks Good). The gap is only in how A reports a refusal.

**Recommendation:** Have the digest print each refusal, e.g. one `- skipped (symlink): <path>` line per path in its section, or a short "Skipped inputs" block. Distinguish "missing" from "is a symlink" in sections 3, 5 and 7. In the skill, add "and the paths the digest lists as skipped" to the `## Skipped paths` sentence. Add a symlinked-directory case to test 6 (Finding 9).

#### 3. In-flight outcomes overlap, and an item sent to Ideas can still be running, merge, or have an unanswered stop entry with no consumer

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:213-224`, `:227`, `:300` (B)
**Move:** 7 (asymmetry between the state list and the loop's lifecycle)
**Confidence:** Medium
**Legibility-target:** for-author
**Evidence:**
- `:215-216`: "running, or finished and waiting on the user's merge decision … → stays, however long;"
- `:218-220`: "ended any other way (merge declined, a stop condition hit, or still building with no commit on its branch for 7 days) → Ideas, with the reason and a link to the brief; the branch is kept."
- `:222-224`: "An item that came back from a build loop returns to Now only when the user puts it there (by their edit, or by answering a `you: judgment` entry that proposes it)."
- `:300`: "a build that hits a stop condition files a `you: judgment` entry naming the roadmap item"

The three outcomes are not disjoint: "running" and "still building with no commit … for 7 days" describe the same loop, and only the third bullet's "ended" hints at precedence. The 7-day move does not stop the loop. Its brief is closed in the repo, but the loop reads the brief from the landed commit (`:288-289`) and never sees `Status: closed`. A self-merge loop can therefore still land the item, or a review loop can file its `merge <branch>?` entry. Either way the item is now in Ideas and no rule moves it to Done.

Separately, the stop-condition entry stays open after its item moves to Ideas. That entry asks the user about the stop (for example, may the work touch X), not "return this to Now". So by `:222-224` the user's answer changes nothing.

The rules cannot loop, which was the round's aim: re-entry needs the user. They are not exhaustive for a loop that resumes after the 7-day cut, and not every entry the loop files gets its answer read.

**Recommendation:**
- Make "running" mean "a commit on its branch in the last 7 days".
- Say the 7-day move stops the loop (by PID, as step 1 does), or that a later merge of a returned item moves it to Done.
- Have the stop-condition entry include "return to Now with this answer" as an option, so the answer has a consumer.

#### 4. Q-103's instruction for answer [1] sits under "If the answer differs", and closing it unedited reopens the settings question every cycle

**Severity:** Minor
**Location:** `docs/working/questions.md` Q-103 (Interim and "If the answer differs" lines) (B); `docs/dev-cycle.md:7,12-14` (B); `skills/dev-cycle/SKILL.md:57-59` (B)
**Move:** 3 (contract between the question entry and the settings rule)
**Confidence:** Medium-High
**Legibility-target:** for-author
**Evidence:**
- Q-103: "**Interim:** [1] `review`, recorded as `Build-loop policy: review (interim; Q-103)`; the skill counts that line as unset (so `review`) and does not re-ask while this entry is open."
- Q-103: "**If the answer differs:** replace that line with `Build-loop policy: self-merge` (or `review` for [1]) and drop the interim sentence below it in `docs/dev-cycle.md`."
- Skill `:57-59`: "Unset (…): use `review`, and unless an open `you: judgment` entry already asks for the setting, file one."
- `docs/dev-cycle.md:12-14`: "The skill counts the setting as made only when one line reads exactly `Build-loop policy: self-merge` or `Build-loop policy: review`; the interim marker above keeps it unset (so `review`) until Q-103 is answered."

The grammar's "If the answer differs" field names what is redone when the answer departs from the interim. Answer [1] *is* the interim, so an agent recording `Q-103: [1]` has no instruction to act on, apart from a parenthetical inside a field that says it does not apply. If the agent archives Q-103 and leaves the interim line, the setting stays unset and no open entry asks for it. The next cycle then files a new settings question, which is the re-ask that pass-8 R1 set out to remove. "Drop the interim sentence below it" is also ambiguous. Lines 12–14 are one sentence that states both the exact-line rule and the interim clause, so dropping it whole deletes the only statement of the rule in the settings file.

**Recommendation:** Rename the field "**On any answer:**", or move the edit into the Interim line ("answering either option means replacing this line …"). Say "drop the clause '; the interim marker above … answered'".

#### 5. Q-103's self-merge option omits the new carve-out, which in this repo covers most work

**Severity:** Minor
**Location:** `docs/working/questions.md` Q-103 option [2] (B); `skills/dev-cycle/SKILL.md:245-247` (B); onboarding `workflows/codebase-onboarding.md:453` (B, context)
**Move:** 3 (documentation drift in a decision the user must make)
**Confidence:** High
**Legibility-target:** for-user
**Evidence:**
- Q-103 [2]: "Each loop lands its branch through pr-prep's local merge on its own | None per item; you read results in the next cycle's digest"
- Skill `:245-247`: "With `Policy: self-merge` it also never includes what later runs follow unreviewed: instruction files (`CLAUDE.md`, `AGENTS.md`) and anything under `skills/`, `workflows/` or `scripts/`; such work gets `Policy: review`;"
- Commit 1ae9b21 Notes: "in this repo they mean most work would run under review even if Q-103 picks self-merge."

The option table is the user's whole basis for answering. Its "Cost to you: None per item" is now false for most items in claude-workflows, and the commit body says so but the entry does not. Onboarding step 13 likewise asks the self-merge/review question with no mention that self-merge excludes instruction, skill, workflow and script changes. Row 68 and global row 12 are summary-level and need no change.

**Recommendation:** Add to [2]: "items touching `skills/`, `workflows/`, `scripts/`, `CLAUDE.md` or `AGENTS.md` still stop for review (most work here)". Add a clause to onboarding step 13: "(changes to instruction files, skills, workflows or scripts always stop for review)".

#### 6. The brief's `Policy:` gloss says "the setting's value now", and four lines later the Paths rule overrides it

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:239`, `:245-247` (B)
**Move:** 3
**Confidence:** High
**Legibility-target:** for-author
**Evidence:**
- `:239`: "`Status: open` and `Policy: self-merge` or `Policy: review` (the setting's value now);"
- `:247`: "such work gets `Policy: review`;"

Two rules in one bullet list decide the same field. The second wins only if the writer reads ahead. The 6b stricter-of-two rule makes the outcome safe at merge time either way. But a brief written as "the setting's value now" with `skills/` in Paths contradicts the list's own "never includes" rule, and the loop is not told what to do with such a brief.

**Recommendation:** Change `:239` to "(the setting's value now, or `review` where the Paths rule below requires it)".

#### 7. `docs/dev-cycle.md` states the set rule more loosely than the skill

**Severity:** Informational
**Location:** `docs/dev-cycle.md:12-13` vs `skills/dev-cycle/SKILL.md:55-58` (B)
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-author
**Evidence:**
- `docs/dev-cycle.md:12-13`: "The skill counts the setting as made only when one line reads exactly `Build-loop policy: self-merge` or `Build-loop policy: review`"
- Skill `:55-57`: "set when the file has exactly one line, outside code blocks, reading exactly … (a trailing CR is ignored). … Unset (no file, no such line, both lines, or any other text …)"

Two identical `self-merge` lines are unset under the skill, but "one line reads exactly" reads as set. The skill's stricter rule fails safe (to `review`), so a user editing the settings file can only be surprised, not exposed.

**Recommendation:** Say "exactly one such line (outside code blocks; see the skill's Project settings)".

#### 8. The `**Paths**` brief field has no literal line shape, unlike the other fields a loop checks mechanically

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:239-248` (B)
**Move:** 2 (naming/shape against neighbors)
**Confidence:** Medium
**Legibility-target:** for-author

Precedent: literal `Key: value` brief lines (`Status: open`, `Policy: review`) used in `skills/dev-cycle/SKILL.md:239`, matched by text in `skills/dev-cycle/SKILL.md:119-120`

**Evidence:** `:242`: "**Paths**: the files and directories the work may change. Changing anything else is a stop condition."

`Status:` and `Policy:` are exact lines the cycle and loop match. Paths is the field a loop must compare its diff against ("anything else"), yet the brief format leaves its spelling and layout to the writer (a heading, a bullet, a `Paths:` line, globs or not). This is consistent enough for a human reader. It is the one field whose exact shape matters most for an agent's mechanical check.

**Recommendation:** Specify "`Paths:` followed by one path or directory per line (`- path`), no globs" or state the glob rule.

#### 9. Test 20's comment still claims section 5's suffix case after d503a43 removed it; test 6 has no directory-component case

**Severity:** Minor
**Location:** `test/scripts/dev-cycle.bats:316-322`, `:126-138` (A)
**Move:** 3 (test drift)
**Confidence:** High (executed)
**Legibility-target:** for-author
**Evidence:**
- `:317` (d503a43): `printf '# Roadmap\r\n\r\n## Now (current)\r\n- a\r\n\r\n## In Flight\r\n- b\r\n- c\r\n\r\n## Next\r\n1. d\r\n\r\n## Nextgen ideas\r\n- not next\r\n' > docs/roadmap.md` (was `## Next (ranked)\r\n` at ab8ec06)
- `:320`: `# Section 5 uses the same heading rule (CRLF, case, suffix; "## Nextgen" is not Next).`

Mutation probe: I replaced section 5's matcher (`scripts/dev-cycle.sh:218`) with `t == "## next"` alone, dropping both suffix branches, and test 20 still passed. The fix traded section 5's suffix coverage for its CRLF coverage. Section 7's suffix branch is still covered by `## Now (current)`, but section 5's is not, and the comment says it is.

Test 6's title is "no input is read through a symlink, inside or outside the repo". Its fixture links only files: two out of the repo, one into `.git`. The new `inrepo` targets symlinked parent directories too (`dev-cycle.sh:89-91`). That behaviour is correct by probe, but no test pins it.

**Recommendation:** Use two Next-like headings, or one with a suffix and CRLF (`## Next (ranked)\r\n`), so section 5 sees CRLF and a suffix together. Add `ln -s` of a directory (e.g. `docs/decisions` → an outside dir holding a record) to test 6.

#### 10. The Ideas section definition does not cover items returned from a build loop

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:218-220`, `:227` (B)
**Move:** 7
**Confidence:** Medium
**Legibility-target:** for-author
**Evidence:**
- `:227`: "**Ideas**: surviving brainstorm items, unranked, each with its signal."
- `:219`: "→ Ideas, with the reason and a link to the brief"

Ideas now holds two shapes, and the section's definition names only one. A brainstorm (step 5) that prunes Ideas against "surviving brainstorm items" could drop a returned item, together with its reason and the link to its kept branch.

**Recommendation:** Extend `:227`: "…each with its signal, or, for an item returned from a build loop, its reason and brief link".

#### 11. The symlink rule's file list omits files the cycle reads, and the settings file most of all

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:62-64`, `:128-129`, `:290-292` (B)
**Move:** 3
**Confidence:** Medium
**Legibility-target:** for-author
**Evidence:**
- `:62-63`: "The cycle reads and writes repo files (idea sources and their glob matches, the idea log, briefs, the record, the roadmap, questions) only by plain paths"
- `:128-129`: "read the record itself then"
- `:291-292`: "the build-loop policy in the default branch's `docs/dev-cycle.md` at the moment the loop would merge"

The parenthetical reads as exhaustive, but it leaves out `docs/dev-cycle.md` (read by the cycle and by every loop at merge time), decision records and `docs/decisions/log.md` (step 2 reads them in full on a cut line), and earlier cycle records. A's `inrepo` covers the last three for its own reads, so the A↔B "same rule" claim holds only where both read the same files.

**Recommendation:** Write "every repo file it reads or writes (for example …)". Writes through `questions.sh` are already refused when the target is a symlink (`scripts/questions.sh:88-98`); the skill could say so.

## What Looks Good

- **`inrepo` (claim 1): correct and complete for every read.** `[[ "$r" == "$ROOT_REAL/$1" ]]` with `ROOT_REAL="$(pwd -P)"` after `cd "$ROOT"` accepts a plain path even when the repo root sits under a symlinked directory and the script runs from a subdirectory (probe: `linked -> real`, run from `sub/`; `001-a.md` and log row 1 were printed). It rejects a symlinked file at any depth and a symlink to a file outside the repo (probe: `002-b.md`, `docs/roadmap.md`, `docs/working/idea-log.md` all skipped, none of their text printed). Every caller passes a literal relative path with no `./` or `..`: the cycle-record glob (`:118`), decision-record glob (`:154`), `docs/decisions/log.md` (`:164`), `docs/working/questions.md` (`:181`), `docs/roadmap.md` (`:214,262`) and `$LOG` (`:271`). So the exact-equality test cannot reject a plain file because of how its path is spelled. Test 6 covers what its comment says for file links (out of repo, into `.git`); the directory case is untested (Finding 9).
- **Policy rule (claim 2): complete and fail-safe.** No file, no such line, both values, duplicates, a line inside a code fence, a line with extra text, or a CR-terminated line each resolve to a defined value, and every undefined case is `review`. A deliberate `review` is now "set" and not re-asked (R1 resolved). The skill's settings template, onboarding step 13 ("Record it as `Build-loop policy: <value>`"; "Until it is set, the skill uses `review`"), row 68 and global row 12 agree with it.
- **Stricter-of-two (claim 2): complete and fail-safe.** The brief side ("anything but `self-merge` counts as `review`") and the settings side (unset → `review`) both default safe. Reading the default branch's file "at the moment the loop would merge" lets the user lower a running loop, and nothing a loop writes on its own branch can raise it.
- **"Never through a symlink" is executable.** A per-component `test -L` from the repo root down is an ordinary-tool loop. "A file not yet created is checked through its directories" answers pass-8 F6's objection that `inrepo` fails for new files.
- **Pass-8 items resolved in place:** F1 (one symlink rule; A and B now agree), F2 (brief `Policy:` values and parse), F3/F4 (declined and blocked replaced by the Ideas outcome; re-entry only by the user), F5 (step 2 cut wording), F6 (no reference to the internal `inrepo`; a record slot for skips), F7 (final message lists open PRs), F8 (Q-103 wording), F10 (CR rule).
- **Global row 12 and the guide row** (`guides/skill-creation.md:137`) still match the skill's step list and checkpoint description; nothing in this round changes them. **Row 68** is a summary that remains true.
- **Commit messages.** d503a43 and 1ae9b21 match their diffs. 1ae9b21's Notes line discloses the self-merge carve-out's effect on this repo (Finding 5 asks only that Q-103 carry it).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Paths allowlist forbids the questions file the loop must write; RPI/pr-prep artifacts not covered | Inconsistent | `skills/dev-cycle/SKILL.md:242-248,296-300` | High |
| 2 | Digest reports a symlink as missing, drops a symlinked record's triggers silently; `## Skipped paths` cannot include digest skips | Inconsistent | `scripts/dev-cycle.sh:155,200,220,285`; `SKILL.md:66-67` | High |
| 3 | In-flight outcomes overlap; a returned item's loop can still merge; stop-entry answers have no consumer | Minor | `SKILL.md:213-224,300` | Medium |
| 4 | Q-103's [1] instruction sits under "If the answer differs"; "interim sentence" also carries the rule | Minor | Q-103; `docs/dev-cycle.md:12-14` | Medium-High |
| 5 | Q-103 [2] and onboarding omit the self-merge carve-out (most work here) | Minor | Q-103 [2]; `codebase-onboarding.md:453` | High |
| 6 | Brief `Policy:` gloss contradicts the Paths rule's override | Minor | `SKILL.md:239,247` | High |
| 9 | Test 20 comment claims section-5 suffix coverage it lost; test 6 has no directory case | Minor | `test/scripts/dev-cycle.bats:317-320,126-138` | High |
| 7 | `docs/dev-cycle.md` states the set rule loosely | Informational | `docs/dev-cycle.md:12-13` | High |
| 8 | `**Paths**` has no literal line shape | Informational | `SKILL.md:242` | Medium |
| 10 | Ideas definition omits returned items | Informational | `SKILL.md:227` | Medium |
| 11 | Symlink rule's file list omits the settings file and records | Informational | `SKILL.md:62-63` | Medium |

## Overall Assessment

The round did what it set out to do on the four rules. The policy parse and the stricter-of-two rule are complete and fail safe. A and B now state one symlink rule. The digest's `inrepo` is correct in every probed layout. The In-flight rules can no longer loop. No finding breaks an existing consumer: no project has set `self-merge`, and this repo runs on the interim `review`.

Two contract gaps remain, both introduced by this round's new surfaces:
- **The allowlist excludes the loop's own bookkeeping.** It forbids the questions file that both 6b outcomes and every stop condition must write, and it is silent on RPI and pr-prep artifacts. Under `review`, a literal loop cannot finish without tripping its own stop condition (Finding 1).
- **The digest's skips are silent.** The record's new `## Skipped paths` cannot be complete, and a symlinked decision record's triggers vanish while section 7 still names the file (Finding 2).

Each is a sentence or a few lines to fix in place. The rest are wording and test-comment drift: Q-103 should tell the user what self-merge now means here, and how to record answer [1].

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/api-consistency-review-2026-10-01-digest-pass9.md`. Its first line is `Commit: d503a43 (A) / 1ae9b21 (B)`. It follows the api-consistency-reviewer structure: header, Baseline Conventions, Name-Pattern Audit, Findings, What Looks Good, Summary Table, Overall Assessment. Every finding carries Severity, Location, Evidence (verbatim), Confidence and Legibility-target. The one naming-shaped finding (8) carries a `Precedent:` line. For the user's goal (merge both branches once a clean pass is reached), it names the known issues left after the pass-8 fix round. It also states explicitly which checked rules are correct and complete (claim 1, the policy and stricter-of-two rules, the symlink procedure), so a clean result is distinguishable from an unchecked one. Nothing was committed. Scratch was limited to two removed `mktemp -d` directories under `scratchpad/api9/`.
