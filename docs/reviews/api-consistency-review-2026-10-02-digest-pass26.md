Commit: 10c2809 (A) / 875b41f (B)

# API Consistency Review — dev-cycle pass 26 (pass-25 fix round)

**Scope:** Partial: the pass-25 fix round only. A: `git diff cbfdf35..10c2809 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` in `/workspace/.claude/wt-digest` (HEAD 18cb059 adds review docs only). B: `git diff 77e21af..875b41f -- skills/dev-cycle/SKILL.md` in `/workspace/.claude/wt-devcycle` (merge bf5dfac; its `SKILL.md` matches 875b41f, and its `scripts/dev-cycle.sh` and the bats file match 10c2809). Everything else is context only (rubric section "Pass 25").
**Date:** 2026-10-02
**Based on:** `docs/reviews/code-fact-check-report-digest-pass25.md` (Stage 1, at cbfdf35 / 77e21af), plus this pass's own probes.
**Replication:** k=1 (loop pass).

**Probe discipline.** I wrote each probe as one script. Each script starts with `set -eu`, creates its own `mktemp -d -p api26/` dir and checks `case "$PWD"` before any `git init`, commit or write. Each script took the code under review with `git show <commit>:scripts/dev-cycle.sh` or `git archive`, and every process ran under `timeout`. All scripts ended with `pgrep` reporting "no leftover processes". The only reads from `/workspace`'s own checkout were copies of `docs/working/questions.md` and `questions-archive.md`. I wrote nothing outside `api26/` except this report. The scratch dir is `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/api26/`, called `api26/` below.

- **probe1** (`api26/probe1.sh`, temp dir `tmp.n9R9PWvVoK`) ran four checks:
  - `bats test/scripts/dev-cycle.bats` on 10c2809 gave 41 ok and exit 0.
  - `shellcheck scripts/dev-cycle.sh` exited 0.
  - `python3 scripts/hermeticity-lint --root .` exited 0 ("no unstubbed network spawns").
  - `--check-answer` ran on all 99 real IDs under both 10c2809 and cbfdf35. `diff` was empty: every reading is unchanged. Every real entry has exactly one `**Needs:**` line, and every header's status field is exactly `**Status:** OPEN` or `**Status:** ANSWERED` at the end of the line. No real entry has an odd count of fence lines.
- **probe2** (`api26/probe2.out`) covered P1–P5: the check modes with no default branch found by name, the commit that `--check-brief` prints after a `--no-ff` merge, header variants, instruction-file names and the tip date's time zone.
- **probe3** (`api26/probe3.out`) tested an odd number of fence lines in the target entry.

Legibility-target values:
- **agent**: the model running the skill or the digest acts on the text.
- **maintainer**: someone editing the script or the tests.
- **user**: the human reading the help, the record or the commit log.

## Baseline Conventions

These are the conventions in the existing script and skill that the diff is checked against:

- **Check-mode output.** Each argument gets one line. The shapes are `ok <arg> [fields…]`, `absent <name>`, `skip <arg>: <reason>` and, for `--check-answer`, `<option> Q-NNN`. Fields are space-separated and positional. A skip is an answer (exit 0), and only usage or environment failures exit 1, with a message on stderr. See `scripts/dev-cycle.sh:22-53` and `:59-61`.
- **Usage errors on stderr.** The shape is `<flag> needs …`, as in `"$CHECK needs at least one argument"` (`:123`) and `need()` (`:114`).
- **Dates.** Dates are `YYYY-MM-DD` in the committer's own zone (git `%cs`), as `--since` already documents (`:16-17`).
- **Locale-independent patterns.** Character sets are written out one by one rather than as ranges (`:182-186`: NAMECHARS; `:234-235`: DIGIT and SLUG). Global pattern variables are UPPER_SNAKE.
- **Skill vocabulary.** Every interface is quoted with its exact printed form. Every count of briefs should use one defined term; this round introduces "holds a slot" (`SKILL.md:81-84`).
- **Questions header.** A second reader of the same header already exists. `scripts/questions.sh`'s `parse_entries` reads every `**Needs:**` line (the last one wins) and treats the `Status:` field between ` · ` separators as exact `OPEN|ANSWERED` (`scripts/questions.sh:171-181`, `:269`, `:379`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `<YYYY-MM-DD>` (5th field of `--check-branch ok`) | output field | `--since` `YYYY-MM-DD` (%cs), cycle-record dates, `Kept: <today>` (YYYY-MM-DD) | `scripts/dev-cycle.sh:16-17`, `skills/dev-cycle/SKILL.md:280` | Consistent: same format and the same zone basis as `--since` |
| `<date>` (the skill's name for that field) | doc placeholder | `<n>`, `<commit>` | `skills/dev-cycle/SKILL.md:86` | Consistent with the skill's short placeholders. The help uses `<YYYY-MM-DD>`, a harmless divergence. |
| `INSTRUCTION_FILE` | global pattern variable | `NAMECHARS`, `DIGIT`, `SLUG` | `scripts/dev-cycle.sh:186`, `:234-235` | The name is consistent (UPPER_SNAKE). Its value uses ranges, unlike its siblings (Finding 6). |
| `"$CHECK needs a default branch (origin/HEAD, main or master); found none"` | stderr message | `"$CHECK needs at least one argument"`, `"--since needs a value"` | `scripts/dev-cycle.sh:114`, `:123` | Consistent `<flag> needs …` shape |
| `skip <path>: its first Status: line is not exactly Status: open, done or dropped` | skip reason | `skip <a>: not an allowed path form`, `skip <a>: not an open build brief (…)` | `scripts/dev-cycle.sh:257-259` | Consistent `skip <arg>: <reason>` shape |
| "holds a slot" / "hold a slot" | skill term | "open brief", "`<k>/3 open`", "open build brief" | `skills/dev-cycle/SKILL.md:160`, `:259`, `:337`, `:354` | Inconsistent: the new term coexists with the old one in the record template and step 1 (Finding 4) |

## Findings

#### 1. The no-default-branch gate refuses all six check modes, though four of them never read the default branch

**Severity:** Breaking (precondition: a repo with no `origin/HEAD` and no `main` or `master` branch, e.g. a `trunk` or `develop` repo with no remote. The installed copy "serves any project".)
**Location:** `scripts/dev-cycle.sh:52-53`, `:412-416`; `skills/dev-cycle/SKILL.md:89-90`
**Move:** 3 (consumer contract), 6 (versioning impact)
**Confidence:** High (executed)
**Legibility-target:** agent / user

**Evidence:**
- The help says:
  ```
  #   The check modes need a default branch found by name (origin/HEAD, main
  #   or master): they read its commit.
  ```
- The gate:
  ```bash
  if [[ -n "$CHECK" && -z "$MAIN_BY_NAME" ]]; then
    echo "$CHECK needs a default branch (origin/HEAD, main or master); found none" >&2; exit 1
  fi
  ```
  The `for a in "${CHECK_ARGS[@]}"` dispatch at `:417-429` follows it; I read it.
- Probe P1 used a repo on `trunk` with no main or master. At 10c2809 all six modes printed `--check-<mode> needs a default branch (origin/HEAD, main or master); found none`. At cbfdf35 the same calls printed `ok docs/guide.md` (`--check-path`), `ok docs/roadmap.md` (`--check-write`), `ok docs/guide.md` (`--check-fix`), `keep Q-1` (`--check-answer`), `ok … new` (`--check-brief`) and `absent feat/x` (`--check-branch`).
- `check_path`, `check_write`, `check_fix` and `check_answer` (`:213-228`, `:242-248`, `:299-309`, `:374-388`) never use `MAIN`, `MAIN_SHA` or `MAIN_BY_NAME`. Only `check_brief` (`:260`, `:266`) and `check_branch` (`:282`, `:286`) do.

The rationale ("they read its commit") holds for two modes. For `--check-brief` and `--check-branch` the refusal is right: a current-branch fallback there would read the cycle branch as "default". The other four modes worked in such a repo before this commit and now exit 1. The skill turns that exit into "the step that needed it stops" (`SKILL.md:89-90`). Every path from repo text goes through `--check-path`, so in such a repo steps 2–6 all stop, while the digest itself still runs on the current branch. Before this round, a consumer that called `--check-path` in such a repo got answers, and now it gets a hard failure. The only test, "the check modes need a default branch found by name" (bats `:763-769`), exercises `--check-branch` alone.

**Recommendation:** Apply the gate only to `--check-brief` and `--check-branch` (the two that read `MAIN_SHA`), and say "--check-brief and --check-branch need …" in the help. Alternatively, keep the gate for all six and change the help's reason, accepting the breakage on purpose. Either way, add a test for one of the other four modes.

#### 2. The skill asks for "the date it was asked", but no interface it allows supplies that date

**Severity:** Inconsistent
**Location:** `skills/dev-cycle/SKILL.md:276-279` (with `:89`, `:273-274`, `:293`)
**Move:** 3 (consumer contract), 7 (asymmetry)
**Confidence:** Medium-High (static; it rests on reading the Rules as written)
**Legibility-target:** agent

**Evidence:**
- `SKILL.md:276-279`: "`open` is not answered yet (or the answer is not recorded: an entry is read only once its header says ANSWERED): leave the ID, and list it in the final message with the date it was asked, so a reply written in place gets recorded."
- `SKILL.md:89`: "A question ID from a brief is read only through `--check-answer`."
- `SKILL.md:293`: "and add its ID to `Asked:` (IDs separated by ", ")"
- `scripts/dev-cycle.sh:46`: `--check-answer  "<option> Q-NNN" …`

The `Asked:` line holds bare IDs. `--check-answer` prints only `<option> Q-NNN`, and the Rules forbid reading a brief's question ID any other way. The `**Opened:**` date is in the entry's header, which only `--check-answer` may read for these IDs, and that check never prints it. An agent that follows the Rules cannot produce the date. An agent that produces it has read the entry outside the check, which is the bypass the Rules exist to prevent. The commit message for 875b41f states the date as part of the fix ("An ID still open is listed in the final message with its date").

**Recommendation:** Pick one. Option 1: drop "with the date it was asked", since the ID alone lets the user find the entry. Option 2: record the date on the brief, e.g. `Asked: Q-123 (2026-10-02)`, which the skill writes itself. Option 3: have `--check-answer` print the entry's `Opened:` date as an extra field (a contract change; update the help and test 38).

#### 3. `--check-brief` names the merge commit, not the status-setting commit, when the default branch also edited the brief

**Severity:** Minor (precondition: the default branch changed the brief after the build branch forked. Cycles do this by adding `Asked:`, `Applied:` or `Kept:` to an open brief, so it applies to every brief that went through keep-or-drop.)
**Location:** `scripts/dev-cycle.sh:253-254`, `:266`; `skills/dev-cycle/SKILL.md:262-263`
**Move:** 3 (documentation drift)
**Confidence:** High (executed)
**Legibility-target:** user / agent

**Evidence:**
- The script comment (`:253-254`): "The commit that last changed the file there is printed: the commit that set the status, which a merge brought in (not the merge itself)."
- The skill (`SKILL.md:262-263`): "naming the commit it prints (the commit that set the status; the merge that brought it in follows it)".
- The code (`:266`): `c="$(git log -1 --format=%H "$MAIN_SHA" -- "$a")"`
- Probe P3: main had `Status: open` with an added `Asked: Q-9`, and a feature branch set `Status: done`. After the `--no-ff` merge (an auto-merge), the output was `setdone=bdc1390… merge=68af11c…` followed by `ok docs/working/briefs/2026-01-01-a.md done 68af11cdd9dc4875987135a4133068f553a1f230`. That is the merge commit.

git's history simplification skips a merge only when the merge is TREESAME to one parent. When both sides changed the file, the merge differs from both parents and is printed itself. The value is still a usable Done reference: the merge contains the change. Only the parenthetical promise is wrong.

**Recommendation:** Change the text to "the last commit that changed the file there: usually the one that set the status, or the merge when the default branch also edited the brief". Alternatively, print the commit that last changed the `Status:` line (`git log -1 -G '^Status:' …`). That would be a behavior change and needs a test.

#### 4. The single slot rule shares the skill with the older "open" count in the record template, step 1 and the final message

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:337`, `:160`, `:354` (rule at `:81-84`)
**Move:** 2 (naming against the grain), 7 (asymmetry)
**Confidence:** Medium-High
**Legibility-target:** agent / user

Precedent: "holds a slot" / "hold a slot" used in `skills/dev-cycle/SKILL.md:81-84`, `:294`, `:308`

**Evidence:**
- The rule (`SKILL.md:81-84`): "**A brief holds a slot** when the glob lists it or this cycle wrote it, unless `--check-brief` prints `done` or `dropped` for it; a brief the check skips keeps its slot (recorded) until the cause is fixed."
- The record template (`:337`): "6. roadmap: <done>; briefs: <written this cycle, or none>; <k>/3 open (3/3: no new briefs)"
- Step 1 (`:160-161`): "Skip any branch or worktree an open brief (found as in the Rules) names: work on it may be in progress."
- The final message (`:353-354`): "… and each open build brief by path"

Under the new rule, two kinds of brief hold a slot without being "open" to `--check-brief`: one it prints `new` for, and one it skips. 875b41f says the rule is "stated once in the Rules … Build briefs points at it instead of counting its own way". The record's `<k>/3`, which is what the user sees, still counts "open". Step 1 says "found as in the Rules", but the Rules no longer define "open brief". One reading would let step 1 skip-protect fewer branches than step 6 counts. A `done` brief not yet moved also sits in the glob when step 1 runs. A related unstated point: "the glob lists it" does not say whether a glob `skip` line (a symlinked brief) counts as listed.

**Recommendation:** Use the term from the rule in all three places: the template becomes "`<k>/3 slots held`", and step 1 and the final message say "a brief that holds a slot (as in the Rules)". State that the glob's `ok` lines are what "lists" means.

#### 5. Moving the fence test before the heading test lets an odd fence count in the target entry run into later entries

**Severity:** Minor (precondition: an odd number of fence-like lines in the target entry, e.g. a four-backtick fence wrapping a three-backtick line, which is valid CommonMark. No real entry has this: probe1 found zero odd-count entries.)
**Location:** `scripts/dev-cycle.sh:350-353` (the `ANSWER_AWK` main rules, `:349-373`, read through `END`)
**Move:** 3 (consumer contract: "a duplicate heading" → skip)
**Confidence:** High (executed)
**Legibility-target:** maintainer / agent

**Evidence:**
```awk
inside && /^(```|~~~)/ { fence = !fence; next }
inside && fence { next }
heading($0) { count++; inside = (count == 1); fence = 0; header = 0; next }
/^(#|##|###) / { inside = 0 }
```
- Probe3: Q-1 is ANSWERED with a body of ` ```` ` / ` ``` ` / ` ```` `, followed by Q-2, then `## Archived` and a second `### Q-1` heading. At 10c2809 the output was `unrecognized Q-1;drop Q-2;`. At cbfdf35 it was `skip Q-1: more than one entry with this heading in docs/working/questions.md;drop Q-2;`.

Before this round, the next heading reset `fence` and ended the entry, so fence-parity errors (``` and ~~~ toggle one shared flag, and fence length is ignored) stayed inside one entry. Now a fence left open hides every later `###`/`##` line. As a result, the duplicate-heading skip promised in the help (`:49-51`, "a duplicate heading") is lost, and lines of the following entries are read as the target's body. If a later entry's fences re-balance the flag, its `**Answer:**` line can then be read as the target's answer. The help's "Lines inside a fence in the entry are skipped, headings included" (`:316-317`) describes the intent. The unbounded case is a side effect.

**Recommendation:** Let the dup count see every heading, even inside a fence: count `heading($0)` matches before the fence rules, or in a separate rule that does not `next`. Alternatively, close an entry's fence at an unfenced `### Q-` heading that is not this ID. Match fences by marker and length if parity matters. Add a test with an odd-count entry followed by a duplicate heading.

#### 6. `INSTRUCTION_FILE` uses character ranges, against the script's stated listed-characters convention

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:298`
**Move:** 1 (baseline conventions)
**Confidence:** High (static); its practical effect is nil
**Legibility-target:** maintainer

**Evidence:**
- `:298`: `INSTRUCTION_FILE='^(claude|agents|gemini)(\.[a-z0-9_-]+)?\.md$|^skill\.md$'`
- `:182-185`: "Characters are listed one by one, not as ranges, so the check does not depend on the caller's locale (a range like A-Z can take in other letters …)"

`low` is already lower-cased with an explicit `tr` (`:303`), and `pathform` (`:302`) limits names to ASCII NAMECHARS. A locale-widened range could therefore only refuse more names. Behavior is not at risk, but the file now has a pattern that breaks the rule it states two screens up. The siblings DIGIT and SLUG (`:234-235`) were written out to follow that rule. Probe P5 shows the anchors and the top-level `|` work under `=~ $INSTRUCTION_FILE`: `Agents.Local.MD` and `gemini.md.md` were refused, and `agents-notes.md` was allowed. P5 also shows that "and the like" (`:296`) does not cover two-segment names: `AGENTS.override.local.md` and `skill.local.md` got `ok`. I am noting that, not calling it a defect.

**Recommendation:** Write the class with SLUG's spelled-out characters plus `_`, e.g. `(\.[abcdefghijklmnopqrstuvwxyz0123456789_-]+)?`, or reuse a variable.

#### 7. Two descriptions of the final message disagree on the unanswered keep-or-drop IDs

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:353-354` vs `:277-279`
**Move:** 7 (asymmetry)
**Confidence:** Medium
**Legibility-target:** agent

**Evidence:**
- `:353-354`: "Then send the final message: list the new `you: judgment` entries by ID and name, any keep-or-drop answer step 6 could not read, and each open build brief by path"
- `:277-279`: "leave the ID, and list it in the final message with the date it was asked"

The Close step is the canonical list of what the final message holds. It has no item for `open` IDs, or for their dates. "could not read" most naturally covers `unrecognized` and `skip` (`:281`, `:285`), because an `open` ID was read and found unanswered. An agent working from the Close step will omit the open IDs that 875b41f added.

**Recommendation:** Add "each keep-or-drop ID still `open` (step 6.2)" to the Close list, and settle Finding 2's date question there too.

#### 8. Two readers of the questions header now pick different lines and match status differently

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:355`; `scripts/questions.sh:171-181`
**Move:** 7 (asymmetry)
**Confidence:** High (executed); no real entry is affected
**Legibility-target:** maintainer

**Evidence:**
- `dev-cycle.sh:355`: `!header && /^\*\*Needs:\*\*/ { header = 1; answered = ($0 ~ /\*\*Status:\*\* ANSWERED( |$)/); next }`
- `questions.sh:179`: `if (f[i] ~ /^Status:/) { status = substr(f[i], 9) }` (inside a rule that fires on every `**Needs:**` line)
- Probe P4 at 10c2809 gave `keep Q-1;open Q-2;open Q-3;`. The cases:
  - Q-1 has `**Status:** ANSWERED (2026-02-01)`. dev-cycle reads it as answered. questions.sh reads the status as `ANSWERED (2026-02-01)`: `check` flags it and `archive` does not move it.
  - Q-2 has `**Status:** Answered`.
  - Q-3 has two `**Needs:**` lines, OPEN then ANSWERED. dev-cycle reads the first line and gives open. questions.sh takes the last line and would archive the entry.

The two readers agree on every header that questions.sh writes, and probe1 found no real header outside that grammar. The case-sensitivity change (cbfdf35 matched `answered` in any case) brings dev-cycle into line with questions.sh's exact `ANSWERED`, which is good. Only the first-vs-last-line choice and the `( |$)` tolerance differ.

**Recommendation:** None needed now. If either reader changes, make it the exact field (`· **Status:** ANSWERED$`) on the first `**Needs:**` line in both.

#### 9. The tip date is in the committer's zone, while "today" is the runner's

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:275`, `:286`; `skills/dev-cycle/SKILL.md:295-296`
**Move:** 8 (field contract)
**Confidence:** High (executed)
**Legibility-target:** agent

**Evidence:**
- `:275`: "the date of its tip commit, YYYY-MM-DD in the committer's zone."
- The skill (`:295`): "prints a tip date more than 14 days before today"
- Probe P5: the commit had committer date `2026-01-01T23:30:00-10:00`. The check printed `ok feat/z bdd07fa… 1 2026-01-01`, and the same commit's UTC date is `2026-01-02`.

The two dates can disagree by at most one day at the 14-day boundary. This matches `--since`'s documented basis (`:16-17`). The script comment states the zone, but the help line (`:35-37`) and the skill do not.

**Recommendation:** Optional: add "(committer's zone)" to the help's `<YYYY-MM-DD>` description.

#### 10. "Its line corrected" has no target for a brief that never landed

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:84-85`
**Move:** 3
**Confidence:** Medium
**Legibility-target:** agent

**Evidence:** "A roadmap In flight path that `--check-path` skips (the brief moved, or never landed) is recorded and its line corrected."

For "moved", the correction is clear: point the line at `closed/`. For "never landed" (for example, a cycle whose step 7 did not merge), nothing says what the line becomes: removed, moved back to Now, or left pointing at the path with a note.

**Recommendation:** Name the correction for each case, e.g. "moved: point it at `closed/`; never landed: move the item back to Now".

## What Looks Good

- **`--check-branch`'s fifth field was added in a coordinated way.** It is appended (positional readers of fields 1–4 are unaffected), its format and zone basis match `--since`, and it is documented in the help (`:35-37`), the comment (`:273-275`), the skill (`SKILL.md:86`, `:295`) and the test (bats `:738`). A repo-wide search (`rg` over both worktrees, excluding `docs/reviews/` and `docs/working/`) found no other consumer of the four-field form.
- **The header-only ANSWERED gate is correct and complete against the real files.** All 99 IDs read the same at 10c2809 as at cbfdf35 (empty `diff`). The case-sensitive exact `ANSWERED` now matches `questions.sh`'s own status grammar. The test at bats `:745-761` covers the quoted-status body and a fenced `#` comment.
- **The `--check-brief` status awk is correct as specified.** It takes the first unfenced line starting `Status:`, an exact match is required, a CR is stripped, and there is an early `exit`. The new skip reason follows the `skip <arg>: <reason>` shape.
- **The error message follows the `<flag> needs …` shape of `:114` and `:123`, and the exit code (1) matches the documented Exit line.**
- **The `INSTRUCTION_FILE` anchors are correct.** Moving the pattern into a quoted variable keeps `^…$|^…$` as a top-level alternation under `=~ $VAR` (P5), and the hermeticity lint is now clean.
- **The help range `sed -n '2,62p'` is correct.** Line 62 is the blank line before `set -euo pipefail` at `:63`, and the new lines 52–53 are inside the range.
- **The 14-day idle rule fits "Kept:".** A slow but active branch is asked at most once per 14 days after each `keep`, and only when its tip is more than 14 days old. That matches the stated intent, so I am not reporting it as a finding. A squash-merged branch is now reached, as the comment at `:273-275` says.
- **The Build-briefs name check now covers this cycle's own unstaged briefs.** It uses the three conditions at `SKILL.md:312-314`.
- **The commit messages hold up.** 10c2809's claims match the code and the probes (41/41, shellcheck and the lint all clean), apart from the side effect in Finding 5. 875b41f's "One rule for a brief's slot, stated once" holds for Build briefs but not for the record template (Finding 4), and its "with its date" is Finding 2.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | The no-default-branch gate refuses all six check modes, though only two read the default branch | Breaking (no origin/HEAD, main or master) | `scripts/dev-cycle.sh:52-53, 412-416`; `SKILL.md:89-90` | High |
| 2 | "The date it was asked" has no source the Rules allow | Inconsistent | `SKILL.md:276-279` (`:89`, `:293`) | Medium-High |
| 3 | `--check-brief` prints the merge commit when the default branch also edited the brief | Minor | `scripts/dev-cycle.sh:253-254, 266`; `SKILL.md:262-263` | High |
| 4 | The slot term coexists with the "open" count in the record, step 1 and the final message | Minor | `SKILL.md:337, 160, 354` | Medium-High |
| 5 | An odd fence count in the target entry hides later headings, so the dup skip is lost | Minor | `scripts/dev-cycle.sh:350-353` | High |
| 6 | `INSTRUCTION_FILE` uses ranges, against the stated convention | Minor | `scripts/dev-cycle.sh:298` | High |
| 7 | The final-message lists disagree on open keep-or-drop IDs | Minor | `SKILL.md:353-354` vs `:277-279` | Medium |
| 8 | The header readers differ (first vs last `**Needs:**`, `( \|$)` tolerance) | Informational | `scripts/dev-cycle.sh:355`; `scripts/questions.sh:171-181` | High |
| 9 | The tip date's zone is not in the help or the skill | Informational | `scripts/dev-cycle.sh:35-37, 275`; `SKILL.md:295` | High |
| 10 | "Its line corrected" has no target for a never-landed brief | Informational | `SKILL.md:84-85` | Medium |

## Overall Assessment

The pass-25 fixes are consistent with the established check-mode conventions. The new output field, error message and skip reason all follow the existing shapes, and the header-only ANSWERED gate changes no reading on the real files. One change goes past its rationale. The default-branch gate was meant for the two modes that read the default branch's commit, but it also refuses `--check-path`, `--check-write`, `--check-fix` and `--check-answer`, and the help explains this as "they read its commit". In any repo without `origin/HEAD`, `main` or `master`, this takes away the path checks the cycle depends on (Finding 1, Breaking under that precondition; a two-line scope fix). On the skill side, the new final-message instruction asks for a date that no allowed interface provides (Finding 2). The single slot rule is not yet the only vocabulary: the record template still counts "open" (Finding 4). The rest are wording or edge cases that the real data does not trigger. All are fixable in place, and none suggests the author skipped surveying conventions.

## Goal-Alignment Note

Success criterion (verbatim from the brief): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/api-consistency-review-2026-10-02-digest-pass26.md`, and its first line is `Commit: 10c2809 (A) / 875b41f (B)`. It follows the api-consistency-reviewer structure: header, Baseline Conventions, Name-Pattern Audit, Findings, What Looks Good, Summary Table and Overall Assessment. Every finding that cites a location carries Severity, Location, Evidence (verbatim), Confidence and Legibility-target, and naming-shaped Finding 4 carries a `Precedent:` line. It covers the brief's focus areas:

- the check modes' interface, output shapes and help, including the date field, the brief status reader and the no-default-branch exit;
- the skill's instructions against what the checks print;
- the single slot rule across the skill;
- `--check-answer` against the real answer lines (all 99 IDs; no reading changed).

It was not committed. The probes wrote only under `api26/`.
