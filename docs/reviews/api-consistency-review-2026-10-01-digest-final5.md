Commit: 28c6178 (A) / c079e8c (B)

# API Consistency Review — dev-cycle digest + skill, final pass 5 (confirming pass on the fixes)

**Scope:** A `git diff db0e5ca..28c6178 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (wt-digest); B `git diff 6ee33e3..c079e8c -- skills/dev-cycle/SKILL.md docs/decisions/log.md docs/roadmap.md guides/skill-creation.md global-instructions/CLAUDE.md docs/dev-cycle-sources.md` (wt-devcycle); and the A↔B contract
**Date:** 2026-10-01
**Based on:** Stage-1 merged fact-check summary (k=3), `docs/reviews/code-fact-check-report-r{1,2,3}-digest-final5.md`; prior pass `docs/reviews/api-consistency-review-2026-10-01-digest-final4.md`

Public surface reviewed: the digest CLI (`--since`, `--sample`, `-h/--help`, exit codes) and its printed format (Window line, section headings 1–7, the lines the skill reads); the skill's citations of digest sections; every file format either side writes or reads (cycle record, roadmap sections, idea log and `## Brainstorm` heading, `docs/dev-cycle-sources.md`, handoff briefs); consistency with decision-log rows 67–68, global decision-tree row 12, and the `guides/skill-creation.md` row.

Runtime evidence (scratch under `scratchpad/api5/`): `bats test/scripts/dev-cycle.bats` 20/20 ok; the digest run in wt-devcycle (`--since=2026-09-25`, exit 0, headings 1–7 as the skill cites them); a throwaway repo probe (below, F3/F5).

## Baseline Conventions

- **Digest output.** Numbered `## N. Title` sections; every section always printed, with an explicit "none" line when empty ("None in the window.", "No docs/roadmap.md yet — …", "No $LOG: …"). Counts as `- <label>: <n>`; lists capped with `… N more`. A failed sub-step is reported in-band in bold (`**questions.sh open failed**`) and the run otherwise exits non-zero.
- **Paths.** Fixed repo-relative paths under `docs/` (`docs/working/questions.md`, `docs/roadmap.md`, `docs/working/cycles/cycle-YYYY-MM-DD.md`, `docs/working/idea-log.md`); no configuration file is read. Sibling `scripts/questions.sh` likewise hard-codes `docs/working/questions.md` (with a `QUESTIONS_LIVE` env override).
- **Dated working-doc names** in this repo put a kind prefix before the date or the date mid-name: `docs/working/triage-2026-09-17-backlog.md`, `proposal-DATE-…`, `audit-test-constraint-DATE.md`, `fn-trace-skill-levers-DATE.md`, `cycle-YYYY-MM-DD.md`; the global instructions already own `docs/working/handoff-diagnosis-{bug-description}.md` for a "handoff".
- **Section headings** in docs the digest parses are matched exactly at the start of a line (`^## Revisit triggers`, `^## Next`, `^## Brainstorm …`).
- **Decision log.** A row that a later row replaces is marked in place: row 43 "**SUPERSEDED BY #44 — …**", row 48 "Superseded in part by row 49".

## Name-Pattern Audit

New or changed public names in this delta (A: none new on the CLI; B: new file formats and paths).

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `## 7. Inputs for steps 4b and 5` (lines `- Roadmap Now/In flight/Next: n item(s)`, `- Last brainstorm: …`, `- Ideas seeded since: n`) | digest section | `## 5. Roadmap`, `## 6. Merges with code but no docs` | `scripts/dev-cycle.sh:188-214` | Consistent shape; but its heading match differs from section 5's (F3) |
| `docs/dev-cycle-sources.md` | config file (table) | none read by any script | none — searched `scripts/*.sh` for `sources` and `docs/*.md` | New category; read by the skill only, never by the digest (F1) |
| `docs/working/idea-log.md` + `## Brainstorm YYYY-MM-DD` | file + heading | `docs/working/questions.md`, `docs/working/feature-ideas.md` | `scripts/dev-cycle.sh:244-250`; `docs/dev-cycle-sources.md:9` | Consistent between digest, sources file and skill step 5 for the default path |
| `docs/working/handoffs/<date>-<slug>.md` | file path | `docs/working/handoff-diagnosis-{bug}.md`, `docs/working/cycles/cycle-YYYY-MM-DD.md`, `docs/working/triage-DATE-backlog.md` | `global-instructions/CLAUDE.md` (Debugging defaults 5); `scripts/dev-cycle.sh:93` | Inconsistent — reuses "handoff" for a different doc kind; `<date>` format unstated (F7) |
| `chore/dev-cycle-<date>` | branch | `feat/…`, `fix/…`, `chore/…` | `git branch -a` | Consistent |
| `## In flight` | roadmap section | `## Now`, `## Next`, `## Ideas`, `## Done` | `docs/roadmap.md:13-50` | Consistent; present in template, repo roadmap and digest |
| `Model:` (cycle-record line) | record field | `Window:` | skill `:204-205` | Consistent `Key: value` shape |
| "done-criteria" / "acceptance criteria" | brief field | — | skill `:38`, `:194` | Inconsistent — one field, two names (F8) |

## Findings

#### F1. The skill lets `docs/dev-cycle-sources.md` relocate the seed log; the digest hard-codes `docs/working/idea-log.md`

**Severity:** Inconsistent
**Location:** `skills/dev-cycle/SKILL.md:41-44,159-160` (B); `scripts/dev-cycle.sh:244-258` (A); `docs/dev-cycle-sources.md:9` (B)
**Move:** 3 (consumer contract), 7 (asymmetry)
**Confidence:** High
**Legibility-target:** the skill's "Seeding is always on" paragraph and the digest's section 7 comment

Evidence (skill):
```
The idea log is the file
`docs/dev-cycle-sources.md` names as its seed log when that file exists, else
`docs/working/idea-log.md`.
```
```
… Then append `## Brainstorm YYYY-MM-DD` to the idea log, so the next digest counts
seeds from here; …
```
Evidence (digest):
```
LOG=docs/working/idea-log.md
if inrepo "$LOG"; then
… (lines 246-256 count from $LOG) …
else
  echo "- No $LOG: no ideas seeded, no brainstorm recorded"
fi
```
The skill promises "the next digest counts seeds from here" for whatever file the sources table names; the digest never reads `docs/dev-cycle-sources.md`. In a repo whose sources file names another seed log, section 7 prints "No docs/working/idea-log.md: no ideas seeded, no brainstorm recorded", so step 5's "10+ ideas seeded" never fires and "a week or more since the last brainstorm" has no date. Not live in this repo (its sources row names the default path). Stage 1 (r1, r2, r3) escalated this.

**Recommendation:** Pick one side: either drop "names as its seed log" from the skill and the sources file's Seed log row (the path is fixed), or have the digest read the Seed log row's path (through `inrepo`) and print which file it used in the section 7 line.

#### F2. Section 7's "items ready for 6b" vocabulary and the skill's "Now + Next … ready" condition do not match what is countable or handoff-eligible

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:237-242` (A); `skills/dev-cycle/SKILL.md:146-148,190-191` (B)
**Move:** 7 (asymmetry)
**Confidence:** High
**Legibility-target:** step 5's first condition

Evidence:
```
    echo "- Roadmap $sec: $n item(s)"
  done
else
  echo "- Roadmap: none yet (0 items ready for 6b)"
```
```
- roadmap Now + Next hold 0–1 items ready for 6b;
```
```
**Handoff queue.** Take the Now items whose first step needs no open choice (no open
`you: judgment` names them), up to the in-flight cap: …
```
Only Now items can be queued for 6b, yet the condition sums Now and Next; and the digest prints raw item counts (not readiness) except in its no-roadmap fallback, which alone uses "ready for 6b". A consumer reading `Roadmap Now: 1, Next: 5` cannot tell from either side whether the condition holds (this repo's run: Now 1, In flight 0, Next 5). Stage 1 noted the Now/Next part.

**Recommendation:** Say "Now holds 0–1 items ready for 6b (readiness is judged; the digest gives counts)", and make the fallback line a count like the others (`- Roadmap: none yet (0 items)`).

#### F3. Section 5 and section 7 match roadmap headings differently, so they can disagree about the same section

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:193` vs `:238` (A)
**Move:** 7 (asymmetry)
**Confidence:** High
**Legibility-target:** section 7's roadmap counts

Evidence:
```
  awk '/^## Next/ { on = 1; next } on && /^## / { exit } on && NF { print "> " $0 }' docs/roadmap.md
```
```
    n="$(awk -v h="## $sec" '$0 == h { on = 1; next } … END { print c + 0 }' docs/roadmap.md)"
```
Probe (throwaway repo, roadmap headings `## Now`, `## In Flight`, `## Next (ranked)` with items under each): section 5 printed `> 1. c` / `> 2. d` under "Its Next section", while section 7 printed `Roadmap In flight: 0 item(s)` and `Roadmap Next: 0 item(s)`. Section 7's exact-equality match silently reports 0 for a heading with trailing text or different case, which is exactly the case that fires the brainstorm condition (F2). The skill's template uses the exact headings, so this bites only hand-edited roadmaps (the repo's own matches today).

**Recommendation:** Use the same match in both (prefix `^## Next` for section 7, or exact for both and print "no `## In flight` heading" when a heading is absent rather than 0).

#### F4. The skill says the next digest starts "from the default branch"; the digest reads triggers, record names, roadmap and idea log from whatever is checked out

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:62-66,220-224` (B); `scripts/dev-cycle.sh:93,110` (A)
**Move:** 3 (consumer contract)
**Confidence:** High
**Legibility-target:** step 0's run instruction

Evidence:
```
Commit the record with the roadmap and
questions changes, then land `chore/dev-cycle-<date>` on the default branch through `pr-prep`
before step 6b: the next digest and the build loops both start from the default branch.
```
```
echo "Window: … those on \`$MAIN\` at ${MAIN_SHA:0:7} … Triggers: all of them, from the working tree. Questions, roadmap, idea log: the working tree."
```
```
for f in docs/working/cycles/cycle-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md; do
```
Only merges, commits and section 7's file lists come from the default branch; the window start (cycle-record glob), triggers, roadmap and idea log come from the working tree. Step 0 never says to run on a checkout of the default branch, and rule 2 creates the cycle branch only "before the first change", i.e. after the digest. Run from a stale feature branch, the digest takes its window from that branch's records. Stage 1 noted the wording.

**Recommendation:** In step 0, say "from an up-to-date checkout of the default branch (the window, triggers, roadmap and idea log are read from the working tree)", and reword step 7's clause to match.

#### F5. "Ideas seeded since" counts any `- ` line in the idea log, but no format for the log's preamble is defined

**Severity:** Minor (downgraded from Inconsistent: no precedent)
**Location:** `scripts/dev-cycle.sh:246-250` (A); `skills/dev-cycle/SKILL.md:41-42` (B); `docs/dev-cycle-sources.md:9` (B)
**Move:** 8 (nullability/presence contract)
**Confidence:** High
**Legibility-target:** the seed-log row of the sources file

No existing precedent in `docs/working/*.md` committed files and `skills/dev-cycle/SKILL.md` (no idea-log template exists)

Evidence:
```
  seeded="$(awk '/^## Brainstorm [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ { c = 0; next } /^- / { c++ } END { print c + 0 }' "$LOG")"
```
Probe: an idea log with `# Idea log`, a "Format:" line and an example bullet `- <idea> (signal: x)` above one real seed printed `Ideas seeded since: 2`. The skill gives a template for the roadmap and the cycle record but not the idea log, so a first writer adding a format example inflates the count until the first `## Brainstorm` heading. Separately, `Last brainstorm: none recorded` has no defined meaning for step 5's "a week or more since" condition (fires or not?).

**Recommendation:** Give the idea log a one-line template in the skill (header, no bullets before the first seed) or count only `- … (signal: …)` lines; state in step 5 whether "none recorded" counts as due.

#### F6. Cycle-record template: `Window: <the digest's Window line>` doubles the key, and the 6b line is written before 6b runs

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:48-49,200-212,228` (B); `scripts/dev-cycle.sh:110` (A)
**Move:** 7 (asymmetry)
**Confidence:** Medium
**Legibility-target:** the step 7 record template

Evidence:
```
Every step ends with a line in the cycle record, including "skipped: <reason>"; a skipped step
is recorded, never silently dropped.
```
```
Window: <the digest's Window line>
…
6b. handoff: <briefs queued, or none>
```
```
Runs after step 7 has landed.
```
The digest's line already begins `Window: since …`, so a literal fill gives `Window: Window: since …`. And the record lands in step 7 before 6b launches anything, so 6b's own outcome (launched / failed to start) never reaches a record, against the Flow's "every step ends with a line in the cycle record"; the template's "briefs queued" quietly records step 6's result instead.

**Recommendation:** Template `<the digest's Window line, verbatim>`; and either say 6b's line records the queue (its launch result goes in the final message / next cycle's In flight check) or carve 6b out of the Flow rule.

#### F7. `docs/working/handoffs/<date>-<slug>.md` reuses "handoff" for a new doc kind and leaves "open" undefined

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:88-90,193-196` (B)
**Move:** 2 (naming), 8 (presence contract)
**Confidence:** Medium
**Legibility-target:** step 6's brief path and step 1's skip rule

Precedent: "handoff" means the diagnosis escape-hatch doc `docs/working/handoff-diagnosis-{bug-description}.md` used in `global-instructions/CLAUDE.md` (Debugging defaults, principle 5); dated working docs spell the date `YYYY-MM-DD` (`docs/working/cycles/cycle-YYYY-MM-DD.md`, `docs/working/triage-2026-09-17-backlog.md`)

Evidence:
```
Skip any
  branch or worktree an open handoff brief (`docs/working/handoffs/`) names: its build loop may
  still be running.
```
```
write a build brief at `docs/working/handoffs/<date>-<slug>.md`
(goal, motive, acceptance criteria including the doc change, branch, out-of-scope, stop
conditions)
```
The brief's field list has no status, and no step closes a brief (6b moves the roadmap item to Done, not the brief), so "open handoff brief" has no observable test and step 1 will skip those branches forever. "Handoff" now names two different doc kinds in `docs/working/`; `<date>` format is unstated where every other dated name says `YYYY-MM-DD`.

**Recommendation:** Define "open" as "its roadmap item is still In flight" (or add a `Status:` field the next cycle sets on Done); call the directory `docs/working/build-briefs/` or the files `build-brief-YYYY-MM-DD-<slug>.md`; spell the date format.

#### F8. One brief field, two names: "done-criteria" (rule 4) vs "acceptance criteria" (step 6)

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:38-39,194` (B)
**Move:** 2 (naming)
**Confidence:** High
**Legibility-target:** the brief field list in step 6

Precedent: the brief field list in `skills/dev-cycle/SKILL.md:194` ("acceptance criteria including the doc change") is the defining list; rule 4 should cite it

Evidence:
```
Every
  6b brief lists the doc change in its done-criteria, and the cycle's own changes follow the
  same rule.
```
```
(goal, motive, acceptance criteria including the doc change, branch, out-of-scope, stop
conditions)
```
Rule 4 also attributes the brief to 6b while step 6 writes it (Stage 1, rule 1 has the same slip). A build loop reading its brief looks for one heading; two names for it invite a brief with neither.

**Recommendation:** Say "every step 6 brief lists the doc change in its acceptance criteria".

#### F9. Sibling docs drift from the skill: row 67 not marked as revised; row 68 "section 7's thresholds" and "full-history deep audit"; guide row's Operating Modes attribution and step count

**Severity:** Minor
**Location:** `docs/decisions/log.md:90-91`; `guides/skill-creation.md:137` (B)
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** log rows 67–68 and the guide row

Precedent: superseded rows are marked in place: "**SUPERSEDED BY #44 — …**" (row 43) and "Superseded in part by row 49" (row 48) in `docs/decisions/log.md`

Evidence (row 67, unchanged):
```
Steps: digest → health and cleanup → revisit-trigger verdicts … → spot-check audit of sampled merges → brainstorm (every idea names its signal) → roadmap (Now / Next ≤5 / Ideas / Done) → cycle record …
```
Evidence (row 68):
```
a new conditional step 4b files a full-history deep audit when a skill, the model or a major decision changes; … Revisit if the 6b cap of 3 starves or swamps the review, or if section 7's thresholds never fire in four cycles.
```
Evidence (skill / digest):
```
None fired: one line saying so. Any fired: add a scoped deep-audit task to the roadmap naming
the trigger; it runs on its own branch, outside this cycle.
```
```
echo "Step 5 (brainstorm triggers; the thresholds are the skill's):"
```
Evidence (guide):
```
| `dev-cycle` | **Adequate** | Workflow-shaped (steps 0–7 plus conditional 4b and 5 and the 6b handoff) but, … with no human checkpoint mid-run beyond the Operating Modes rule (under /active the user confirms the handoff queue, as for any launch; …
```
Row 67 still lists the old step list and roadmap sections (no In flight, unconditional brainstorm, "spot-check audit") with no pointer to row 68; the digest prints row 67's Revisit clause every cycle, so readers land on it. Row 68 calls the thresholds section 7's (the digest says they are the skill's) and says 4b "files a full-history deep audit" where the skill files a "scoped" task. The guide row cites an Operating Modes launch rule the global instructions do not have (Stage 1: Incorrect; the /active list names commits, pushes, PRs, plan gates, architectural decisions) and counts step 5 twice ("0–7 plus … 5").

**Recommendation:** Add "Revised by row 68." to row 67's decision cell (the row-48 form); in row 68 say "the skill's step 5 thresholds" and "files a scoped deep-audit task"; in the guide row say "beyond the skill's own /active confirmation of the handoff queue" and "steps 0–7 (4b and 5 conditional) plus the 6b handoff".

#### F10. Sections 6 and 7 still numbered against different skill steps (prior F6) — mitigated

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:198,216`; `skills/dev-cycle/SKILL.md:66-68`
**Move:** 2 (naming)
**Confidence:** High
**Legibility-target:** step 0's section-to-step map

Precedent: digest sections are numbered independently of skill steps since section 1 (`scripts/dev-cycle.sh:113-216`)

Evidence:
```
Its sections feed the steps: 1 activity (context), 2 triggers
(step 2), 3 watched questions (step 3), 4 spot-check sample and 6 merges with code but no
docs (step 4), 5 roadmap (step 6), 7 inputs (steps 4b and 5).
```
Step 0 now spells the map, and section 7's title names its steps, which closes the prior pass's confusion risk. Noted only so the map stays the single place this is explained.

**Recommendation:** None required; keep the map in step 0 in sync when sections change.

## Prior-pass findings (final pass 4) — status

| Prior | Status | Evidence |
|---|---|---|
| F1 `Main at:` | Closed | `grep -n 'Main at' skills/dev-cycle/SKILL.md` → none |
| F2 carried verdicts | Closed | skill `:100-101` "The previous record's verdicts are context, never the answer" matches digest `:126` |
| F3 section 7 undefined in skill | Closed, except seed-log path (F1) | skill steps 4b/5/6 define In flight, thresholds, `## Brainstorm` |
| F4 section 6 unread / step 0 omits 6–7 | Closed | skill `:66-68`, `:123-124` |
| F5 trigger keys | Closed | skill example `docs/decisions/014-secure-tool-guidance-layers.md` matches digest `### $f` |
| F6 section/step numbering | Mitigated (F10) | step 0 map |
| F7 committer-zone wording | Closed | `--help` `:10-11`; Window line `:110` |
| F8 seeds counted from brainstorm bullets | Closed (brainstorm ideas go to the roadmap); new preamble case F5 | skill `:159-160` |
| F9 Window omits section 7 basis | Closed | Window line names "section 7's changed files" |
| F10 unwaited filters | Closed | re-exec pipeline `:41-44`; 20/20 bats |

## What Looks Good

- The skill cites every digest section by the number and title the digest prints (`## 1`–`## 7`, "Merges with code but no docs", "`questions.sh open` failed"), and the digest's run in wt-devcycle prints exactly those headings.
- `## In flight` is consistent across the skill template, `docs/roadmap.md`, and the digest's section 7 loop.
- The cycle record path and the "only the file name is read" contract match the digest's glob and the `--help` text; trigger names in the record example now match what the digest prints.
- The `## Brainstorm YYYY-MM-DD` heading and the `- <idea> (signal: …)` seed line agree across the skill, the sources file and the digest's parser for the default path.
- CLI unchanged and consistent: `--since`/`--sample` in both `=` and spaced forms, exit 1 on bad usage with a one-line stderr message, `--help` from the header.
- Global row 12's keywords match the skill's description trigger list word for word.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Sources file can rename the seed log; digest hard-codes `idea-log.md` | Inconsistent | skill `:41-44,159-160`; `dev-cycle.sh:244-258`; sources `:9` | High |
| F2 | "ready for 6b": Now+Next condition vs Now-only queue; digest prints counts, fallback says "ready" | Minor | `dev-cycle.sh:237-242`; skill `:148,190` | High |
| F3 | Section 5 prefix-matches `## Next`, section 7 exact-matches: same section, different answers | Minor | `dev-cycle.sh:193,238` | High |
| F4 | "next digest starts from the default branch" vs working-tree reads; step 0 names no checkout | Minor | skill `:62-66,220-224`; `dev-cycle.sh:93,110` | High |
| F5 | Seed count includes any `- ` preamble line; no idea-log template; "none recorded" undefined | Minor (downgraded) | `dev-cycle.sh:246-250`; skill `:41-42` | High |
| F6 | Record template doubles `Window:`; 6b line recorded before 6b runs | Minor | skill `:48-49,204,212,228` | Medium |
| F7 | `handoffs/<date>-<slug>.md`: reused "handoff", no "open" test, date format unstated | Minor | skill `:88-90,193-196` | Medium |
| F8 | "done-criteria" vs "acceptance criteria"; rule 4 says 6b writes briefs | Minor | skill `:38-39,194` | High |
| F9 | Row 67 unmarked; row 68 "section 7's thresholds"/"full-history"; guide row's nonexistent Operating Modes rule, step count | Minor | `log.md:90-91`; `skill-creation.md:137` | High |
| F10 | Section/step numbering (prior F6) mitigated by step 0 map | Informational | `dev-cycle.sh:198,216`; skill `:66-68` | High |

## Overall Assessment

The fixes close every final-pass-4 API finding: the skill no longer references `Main at:` or carried verdicts, it defines everything section 7 assumes, and the section-to-step map, trigger names, record path and `## In flight` heading now agree on both sides. One real contract gap remains (F1): the skill and `docs/dev-cycle-sources.md` let a repo relocate the seed log, which the digest cannot follow, so step 5's seed and date conditions would silently read zero there; it does not bite this repo but should be resolved by choosing one side before the skill ships as the standard loop. The rest are minor, fixable in place with wording (F2, F4, F6, F8, F9), a one-line awk alignment (F3), or small format definitions (F5, F7); none breaks an existing consumer, since both sides land together and nothing else reads these formats.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/api-consistency-review-2026-10-01-digest-final5.md` with `Commit: 28c6178 (A) / c079e8c (B)` first, and follows the api-consistency-reviewer structure (header, Baseline Conventions, Name-Pattern Audit, Findings with Severity/Location/Evidence/Confidence/Legibility-target, What Looks Good, Summary Table, Overall Assessment). It serves the user goal (merge both branches once clean) by confirming the final-pass-4 API findings are closed and naming the one remaining contract gap (F1) that should be decided before merge. Nothing was committed; scratch stayed under `scratchpad/api5/`.
