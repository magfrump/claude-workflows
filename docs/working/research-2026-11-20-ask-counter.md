# Research: `questions.sh counts`, the ask counter (brief 2026-11-20-ask-counter)

Date: 2026-11-20 · Branch: feat/ask-counter (dispatched at b7663bf2) · Policy: review

Failure-pattern grep: `rg -n -i "questions\.sh|under-count|undercount|silently dropped|vacuous" docs/failure-patterns.md` — no entry names questions.sh; the live class is `vacuous-assertion` (FP-163 subject relocated so the real default goes untested, FP-168 bare `! grep` in bats). Failure-pattern skip: the one fix commit (958c0044) repairs a failure swallowed by a process substitution, in code not yet merged; that class is already FP-147 (exit status read through a process substitution is lost), so a new entry would duplicate it.

Applied: the tests run `counts` from inside a fixture repo with no `QUESTIONS_*` override (the default position), every assertion is a positive match on an exact row, and each refusal case asserts the exit code and the message.

## What was built (the doc changes criterion 7 asks to list)

- `scripts/questions.sh counts --since YYYY-MM-DD [--until YYYY-MM-DD]`, and the usage text naming it.
- `skills/dev-cycle/SKILL.md`, weekly digest (step 9): the ask-counter bullet now says to paste `counts` output for the digest's window. No other change to the skill.
- `test/scripts/questions-counts.bats`: 12 cases on fixture files in a fixture git repo with set commit dates.
- This doc.

## How it counts

- **Entries and routes**: `parse_entries` and `ROUTES`/`ROUTE_HOME`; no second grammar parser. Owner routes are those with no `ROUTE_HOME`. A `you: judgment` entry is `merge` (slug `merge-`), `re-dispatch` (`stopped-`, `blocked-`) or `real choice`; the other owner routes are one row each, in `ROUTES` order (walkthrough, terminal, fyi).
- **Opened**: owner entries in the live file and the archive whose `Opened:` date is in the window, whatever their status.
- **Answer date and sitting**: one `git log -p --diff-merges=first-parent` pass over the archive; the date is the earliest author date of a commit that adds the line `### Q-NNN ·`, and that commit is the sitting. `--diff-merges=first-parent` is needed: Q-181 to Q-193 entered the archive in a merge's conflict resolution (0ec49d44), which a plain `git log -p` does not diff, so the first run listed all 13 as undated.
- **First option**: the dev cycle's answer rule, `ANSWER_AWK` in `scripts/lib/dev-cycle-read.sh`, sourced, not restated (S3). Its `keep` (`[1]`, `1`, `keep`) is first option; `drop`/`done` are other options; `unrecognized` (free text, `withdrawn`, and `[4]` or higher, which the rule does not model) counts as not first and is listed by ID. A file the rule refuses (a stray fence, a CR, an unclosed comment) stops the count. First option is reported for the three judgment classes only; terminal, walkthrough and fyi answers (`done`, `met`, `seen`) print `n/a`, as the area-B hand count did.
- **Waits**: answer date minus `Opened:`, in days; median (mean of the middle two for an even count) and maximum.
- **Fails loudly (H2)**: an answered entry with no archive commit (or still in `questions.md`) is listed as undated. These stop the run, naming the entry or file: a route outside `ROUTES`, an Opened that is not a calendar date, a Status other than OPEN or ANSWERED, a missing slug, a duplicate ID, an answer dated before its Opened, a file it cannot read, a git history it cannot read, a missing `lib/dev-cycle-read.sh`, and bad arguments. Entries on non-owner routes answered in the window are listed as not counted. `check` stays the validator for the rest (an OPEN entry in the archive, a stale index).
- **Batched answer**: read as several entries recorded in one commit (one sitting), as with "Q-235..Q-237: merge all three"; each entry still carries its own answer line, which is what the rule reads.

## Check against the area-B hand count (`docs/working/research-2026-11-19-area-b-ask-habituation.md` section 3.2)

Run on a clone at a0ef9528 (the hand count's commit), window 2026-10-30 to 2026-11-19:

| Class | Hand count | `counts` |
|---|---|---|
| merge | 44 answered, 43 first | 44 answered, 43 first |
| re-dispatch | 9, all first (with Q-281 to Q-284) | 5, all first |
| real choice | 13, 6 first | 18, 10 first |
| terminal | 12 | 12 |
| fyi | 1 | 1 |

As the brief foresaw, the four "keep the interim?" confirmations (Q-281 to Q-284) have no mechanical mark, so `counts` puts them under real choice (5 re-dispatch, 17 real choice). The 18th real choice is Q-278, which the hand count left out as withdrawn; `counts` keeps it and lists it as not read as an option, with Q-286 (free text). No judgment-based class was added. Judgment median wait 0 days in both. Sittings: 32 commits over 15 answer dates.

## Design choices

**Where the counter lives**: decided in the area-B research (section 5.2, option [b], a subcommand of `questions.sh`); taken as given. The brief's fallback (factor the parser into `scripts/lib/questions-parse.sh`) was not needed: `parse_entries` already gives route, Opened, Status and slug, and the answer line is read by the sourced `ANSWER_AWK`. The unit is about 130 lines in `questions.sh` plus 138 of tests, under the ~400 changed-line cap (log row 62).

**How to read the answer line** (divergent design, 4 options):

- [1] Source `lib/dev-cycle-read.sh` and run its `ANSWER_AWK` per answered judgment entry.
- [2] Restate the answer-label rule in `questions.sh`.
- [3] Factor `ANSWER_AWK` into a new shared lib sourced by both.
- [4] Have `parse_entries` emit an answer field under a simpler rule of its own.

Pruning: [2] and [4] each add a second copy of a rule the lib already says to "change all of them together" (S3), and they could disagree with what the dev cycle reads as an answer. [3] moves gate code that `dev-cycle.sh` and `build-loop.sh` both depend on, for no gain in this brief (S8, one `git revert`; a larger gate review). [1] reuses the reviewed mechanism (S3), and the lib is documented as sourceable from a script's own directory ("a copy of scripts/ with its lib/ is self-contained"); `~/.claude/scripts` is the whole `scripts/` link, so `lib/` is there. Its cost: `[4]`+ is listed as unreadable rather than as another option; it is still counted as not first, so the counts are right and only the listing over-reports. **Decision: [1], Path A.**

Other choices (one line each):

- Author date (`%as`), in the author's own offset, so it matches the dev cycle's local `date +%F`; ties go to the older commit. Consequence: a branch commit dated inside a window but merged later changes that window's numbers afterwards (that is why the current archive prints 45 merge answers for the sample window where a0ef9528 prints 44). A digest records what it printed, so this is a known drift of at most the in-flight branches, not a silent one.
- Rows follow `ROUTES` order (walkthrough before terminal), not the brief's list order: one source of order.
- Empty fields in `parse_entries` output collapse under `IFS=$'\t'` (shared with `check`); `counts` refuses an empty slug, and changing the shared reader is out of this brief.
- `--until` is optional and open-ended; both bounds are inclusive.
- Non-owner archive entries in the window are listed, not counted: the brief's classes are owner routes only.
- The interim-vs-first-option split (area-B gotcha 9.2) is not added: the brief asks only for first option, and in the sample they coincide.
- `Opened` counts both files; the live file's ANSWERED entries are undated because they are not yet archived.

## Verification

- Review round 1 (one reviewer subagent) found one High: an unreadable questions file printed an all-zero table with exit 0, because `parse_entries` ran inside `< <(...)`. Fixed in 958c0044 with the Medium and Low items (duplicate, slug and calendar-date checks, the lib's git hardening, undated non-owner entries) and four new cases.
- `bats test/scripts/questions-counts.bats`: 12 of 12. Case 7 (no git history) failed on the first run: the git failure was inside `< <(...)`, so `die` ended only the subshell and the table printed with everything undated. Fixed by reading the history into a variable first.
- `scripts/confine-tests.sh --probe` exits 3: "confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run." So the gate is `scripts/run-tests.sh` plus `scripts/hermeticity-lint --root .` (151 files, no unstubbed network spawns).
- `scripts/run-tests.sh --all` on 6ea3850c: 1703 tests, 0 failures, before its 1500 s timeout stopped it; the 73 suites it had not reached, then `dev-cycle.bats`, `build-loop-orchestrator.bats` and `questions-doc.bats`, all passed on 958c0044. Review round 2 was clean.
- `shellcheck -x scripts/questions.sh`: the one remaining note (SC2016 at the existing `render_index`) is on main too.
