# API Consistency Review — feat/build-loop-u4b2, iteration 2 (adc8a176)

**Scope:** `git diff main...HEAD` (full branch, HEAD adc8a176): `skills/dev-cycle/SKILL.md`, `test/scripts/build-loop-orchestrator.bats`
**Date:** 2026-10-13
**Based on:** `docs/reviews/code-fact-check-report-2026-10-13-u4b2-i1.md` (iteration 1, A1-A7; fixed in adc8a176) and the shared brief `u4b2-i2/shared.md`

The "API" reviewed: the contract between the dev-cycle skill's steps and the script modes they call
(argument forms, printed lines, refusal texts the skill matches), the questions-entry grammar
(slugs, `Asked:`/`Applied:`/`Dispatched:` brief lines, merge headings), the record template other
readers parse, and naming within SKILL.md and against plan D1-D14.

## Baseline Conventions

- **Script output is line-typed by a first word** (`ok`, `skip`, `refuse`, `path`, `deny`, `merged`,
  `landed`, `dispatched`), documented in each script's header (`scripts/build-loop.sh:6-519`,
  `scripts/dev-cycle.sh` header). Callers act on the first word and on fixed refusal substrings
  (`build-loop.sh:494-497` names the two dispatch refusals that clear without a repo change).
- **Answers have one vocabulary.** `--check-answer` (`scripts/dev-cycle.sh:61-68`, ANSWER_AWK
  `option()` at `scripts/lib/dev-cycle-read.sh:2070-2081`) reads `[1]`/`1`/`keep`, `[2]`/`2`/`drop`,
  `[3]`/`3`/`done`, else `unrecognized`. Its only consumers before this branch were keep-or-drop
  entries, whose labels were literally keep/drop/done. `--merge --approved` (`approval()`,
  `build-loop.sh:1442-1457`) requires `keep`.
- **Entry slugs** are `WORDS-STEM-N` for anything on an `Asked:` line (`build-loop.sh:230-234`,
  example `keep-or-drop-STEM-N`), and `merge-STEM-SHA12` / `merge-gate-STEM-SHA12` for approvals
  (`build-loop.sh:409-414`, `approval()`).
- **Brief machine lines** are `Key: value` at column 0, first occurrence wins: `Status:`, `Branch:`,
  `Policy:`, `Paths:`, `Dispatched: N` (`build-loop.sh:70-98`, regex at `:902`), `Asked:` (judged by
  `--cycle-diff`, `:224-237`).
- **Record lines** the scripts read: `Branch: B` anywhere in a `docs/working/cycles/cycle-YYYY-MM-DD.md`
  (`--main-log` chore, `--land-cycle`, `build-loop.sh:158-163, 250-251`) and `^Main at: ` (step 0.2).
- **Plan** D1-D14 (`docs/working/plan-build-loop-handoff.md:39-106`) is the spec the skill names.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `blocked-STEM-N`, `stopped-STEM-N` | entry slug | `keep-or-drop-STEM-N` | `scripts/build-loop.sh:230-234`, `test/scripts/build-loop-orchestrator.bats:478` | Consistent: WORDS-STEM-N |
| `capped-STEM-N` | entry slug | `stopped-STEM-N`; plan D1 "`stopped: dispatch cap`" | `docs/working/plan-build-loop-handoff.md:42` | Fits the slug grammar; diverges from D1's naming (finding 9) |
| `merge-STEM-SHA12`, `merge-gate-STEM-SHA12` | entry slug | `approval()` heading | `scripts/build-loop.sh:1435-1457` | Consistent (exact heading, path or deny lines after A3's fix) |
| `Applied: Q-NNN, ...` | brief line | `Asked: Q-NNN@SHA, ...`; old `Applied:` | `scripts/build-loop.sh:224-237`; `git show main:skills/dev-cycle/SKILL.md` (old step 6) | Consistent with the old Applied: line; not judged by `--cycle-diff` (free) |
| `Dispatched: N` | brief line | `--status` reader | `scripts/build-loop.sh:87, 902` | Consistent (`^Dispatched: (0-99)$`, replaced not appended: matches "first line" reader) |
| `Policy: self-merge` / `Policy: review`, `Paths: PATH ...`, `Branch: NAME` | brief lines | `--status`/`--check` readers | `scripts/build-loop.sh:73-76, 382-392` | Consistent |
| `## Iteration DATE-HHMM` | record heading | `# Cycle YYYY-MM-DD` (one block per cycle) | `git show main:skills/dev-cycle/SKILL.md` step 9 template | New convention; no reader parses it (only `Branch:`, `Main at:`, file name) — fine |
| `7. collect`, `8. briefs`, `10. dispatch` | record step lines | `0.`-`6.` lines | `skills/dev-cycle/SKILL.md:566-574` | Consistent, but no `9.` line (finding 8) |
| `queue <k>/<slots>` | record field | old `<k>/3 slots held` | main's step 9 template | Renamed: "queue" vs the Rules' surviving "holds a slot" (finding 3) |
| `.claude/wt-dev-cycle-gate-DATE-HHMM` (GT) | worktree path | `.claude/wt-dev-cycle-DATE-HHMM`, `.claude/wt-STEM` | `skills/dev-cycle/SKILL.md:258-259`; `build-loop.sh:461` | Consistent; STEMs start with a date, so no collision with `wt-dev-cycle-*` |
| `chore/dev-cycle-DATE-HHMM` | branch | `--main-log`/`--land-cycle` branch forms | `scripts/build-loop.sh:158-160, 242-243` | Consistent |
| step names `7 collect`, `8 build briefs`, `9 record and land`, `10 dispatch` | skill steps | Flow line, description, plan D4 "skill step 7" | `skills/dev-cycle/SKILL.md:4, 213-216`; plan `:56` | Consistent across Flow, headings and description |

## Findings

#### 1. Blocked entries are answered through a keep/drop/done reader: a loop's 4th option or a free-text fact reads `unrecognized` forever, so the brief is never re-dispatched

**Severity:** Breaking
**Location:** `skills/dev-cycle/SKILL.md:497-510`; `scripts/lib/dev-cycle-read.sh:2070-2081`; plan `docs/working/plan-build-loop-handoff.md:46-48`
**Move:** 3 (consumer contract), 7 (asymmetry)
**Confidence:** High

Evidence (SKILL.md): "A blocked entry's options are the loop's, in the quoted body" … "Then answers, only through `--check-answer` … `[1]`, `[2]` and `[3]` read as `keep`, `drop` and `done`." … "`open`: wait; the final message lists it with its brief. A `skip` or `unrecognized`: the record and the final message." … "A blocked entry, answered: step 10 re-dispatches the brief, naming the ID."

Evidence (lib): `if (!match(s, /^(1|2|3|keep|drop|done)/)) return "unrecognized"`.

The loop writes the blocked body as "plain prose and an options table" (loop prompt, `build-loop.sh:1689`), and D2 routes "a fact only you have" to `blocked` too. `--check-answer` maps only options 1-3 or the words keep/drop/done. Executed probe (`u4b2-i2/api/probe-answer.sh`, temp repo, main's questions.md): `**Answer:** [4]` → `unrecognized Q-001`; `**Answer:** use the staging bucket` → `unrecognized Q-002`. The skill routes `unrecognized` to "the record and the final message" only, so such a brief is never re-dispatched and is asked again only by the user rewriting the answer in keep/drop/done terms. D2 says "On your answer the loop resumes with your pick". The re-dispatch line ("Answered for you: Q-NNN, read from the default branch's questions files") already sends the loop to read the answer itself, so for blocked entries the orchestrator needs only "answered or not". It is asking for a reading it cannot get.

**Recommendation:** For a blocked entry, treat any answered state (`keep`, `drop`, `done` or `unrecognized`, i.e. Status ANSWERED) as answered and re-dispatch. Or say in the entry's own question line that the answer must start with `[N]` and cap the loop's options at 3 in the loop prompt. Either way, the blocked branch of step 7 should not depend on the keep/drop/done mapping.

#### 2. Option labels and the answer vocabulary disagree: `merge`, `re-dispatch` and `changes needed` are not words the reader accepts, and `done` on a stopped or capped entry has no action

**Severity:** Inconsistent
**Location:** `skills/dev-cycle/SKILL.md:486-487, 500, 505-515, 652-653`
**Move:** 2 (naming), 7 (asymmetry)
**Confidence:** High

Precedent: option labels equal to answer words (`[1] keep`, `[2] drop`, `[3] done`) used in `git show main:skills/dev-cycle/SKILL.md` (old step 6 check 3) and `test/scripts/dev-cycle.bats:650-941`

Evidence: "Options **[1] merge**, **[2] drop**, **[3] changes needed**" · "a stopped one's are **[1] re-dispatch** and **[2] drop**" · "A stopped entry: `keep` re-dispatches (a `capped-` one's changes nothing); `drop` closes the brief" · capped: "options **[1] keep** … and **[2] drop**".

Probe: `**Answer:** merge` → `unrecognized`; `**Answer:** re-dispatch` → `unrecognized`; `**Answer:** done` on a `stopped-` entry → `done`. The reader accepts the word `done`, but step 7 lists only `keep` and `drop` for stopped entries, so the orchestrator has no rule for it. The user is offered labels that they cannot type as words, and one word that reads as a third option that the entry never offered. Under the old keep-or-drop convention the label was the token, so a word answer always worked.

**Recommendation:** Either name the options by the reader's words (for example, "[1] keep (merge)") or state in each entry "answer with the number". Add a rule for `done` on stopped and capped entries (treat it as unrecognized, or as drop).

#### 3. "Slot" now has two definitions: the Rules' "holds a slot" counts every open brief, while step 8/10 and D9 count only live loops

**Severity:** Inconsistent
**Location:** `skills/dev-cycle/SKILL.md:167-170, 311-312, 546, 522-525, 634-635`; plan `:90`
**Move:** 2 (naming), 7 (asymmetry)
**Confidence:** High

Precedent: D9 "Only a live dispatched loop holds a slot. A `blocked`, `ready`-awaiting-review or `stopped` item holds none" used in `docs/working/plan-build-loop-handoff.md:90`

Evidence (Rules, unchanged): "**A brief holds a slot** when the glob prints `ok` for it … or this cycle wrote it, unless it is under `closed/` or `--check-brief` prints `done` or `dropped` for it". That includes blocked, stopped and ready briefs, and step 1 ("a brief holding a slot (as in the Rules)") and step 8 ("a skipped brief keeps its slot") still use this sense. Step 8 (new): "while the queue is shorter than `--settings`' `slots` line (D9): open briefs whose loop step 7 read as absent or working … (a blocked, stopped or ready one … is not counted)". Step 10: "Fill free slots (`--settings`' `slots` less the loops this session runs)". These are three different counts under one noun. Step 8's queue counts another session's `working` loop, while step 10's free slots do not. So the two steps disagree on how many loops may start.

**Recommendation:** Rename the Rules' sense, for example "a brief is live" or "in flight", in the Rules, step 1 and step 8's skip sentence. Keep "slot" for D9's meaning, and give step 8 and step 10 one shared definition of occupied slots.

#### 4. A self-merge refusal on an N-rule `deny` falls through to a merge entry that `--approved` can never land

**Severity:** Inconsistent
**Location:** `skills/dev-cycle/SKILL.md:476-478, 513-514`; `scripts/build-loop.sh:356-366, 393-407`
**Move:** 3 (consumer contract), 4 (error consistency)
**Confidence:** Medium

Evidence (SKILL.md): "A refusal that `path` or `deny` lines follow falls through to review: a merge entry as below, quoting `--merge`'s lines". Header: "The N rules, under either policy: a path pathform refuses …; a mode other than 100644 or 100755 …; the brief's own file …; the dev cycle's own files … and docs/constraints.md" · "With --approved Q-NNN it lands a brief of either policy under the N rules alone".

A `deny` line can come from an N rule (a symlink, a `.github/` path, a cycle file) as well as an S rule. Under review policy, step 7 files the same N-rule refusal from `--check` as `stopped`. Under self-merge it becomes a merge entry. The user answers `[1]`, `--merge --approved` refuses again under the same N rule, and only then is it filed `stopped`. So the same condition gets two different error paths depending on policy, and the user's answer is wasted. D4 (plan `:58`) frames the fall-through as being for S-rule refusals ("each S-rule refusal flagged").

**Recommendation:** Fall through to review only when every `deny` WHY is an S-rule reason. The floor's `floor_why` texts, a never-glob reason and the Paths: reason are distinguishable from the N-rule texts. Alternatively, have `--merge` mark N-rule denies, and file an N-rule deny as `stopped` as review does.

#### 5. Stale consumer docs still name step 6's removed keep-or-drop entries and `Kept:` line

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:61`; `scripts/build-loop.sh:234, 1969-1972`; `scripts/lib/dev-cycle-read.sh:501, 2035`
**Move:** 3 (documentation drift)
**Confidence:** High

Precedent: header examples name the entry kinds the skill files, used in `scripts/build-loop.sh:230-234` and `scripts/dev-cycle.sh:61`

Evidence: `--check-answer  "<option> Q-NNN" for a keep-or-drop-or-done question` (dev-cycle.sh:61); `as keep-or-drop-STEM-N` (build-loop.sh:234); `# Step 6 only appends IDs to a brief's first Asked: line … as step 6's keep-or-drop-STEM-N` (build-loop.sh:1969-1972); `never a later Asked:/Kept: edit` (lib:501). This branch removes step 6's keep-or-drop checks and the `Kept:` line (diff of SKILL.md, old lines "slug `keep-or-drop-<brief file name without .md>-<n>`", "`keep` sets `Kept: <today>`"). Asked: items are now written by step 7, and the reader serves merge, stopped, capped and blocked entries. These headers are what the skill tells the orchestrator to trust ("its header gives each line's exact form").

**Recommendation:** In the change that touches the scripts next (gate code: a merge-gate entry), reword the headers to "step 7's entries (blocked-, stopped-, capped-STEM-N)" and "--check-answer reads [1]-[3]/keep/drop/done for any entry". Or file the rewording on the roadmap now, since this branch cannot touch gate code.

#### 6. A failed land is not retried before the next step 7 (D13), so the next iteration re-derives `Asked:` and merge entries from a main that lacks them

**Severity:** Inconsistent
**Location:** `skills/dev-cycle/SKILL.md:59-66, 463-464, 620-624, 655-659`; plan `docs/working/plan-build-loop-handoff.md:104`
**Move:** 3 (consumer contract vs spec), 9 (idempotency)
**Confidence:** Medium

Evidence (plan D13): "Dispatch happens only after `git merge-base --is-ancestor <chore tip> main` confirms the land. A failed land is retried before the next iteration's step 7, so `Asked:` state is never re-derived from a main that lacks it (F49)." SKILL.md: "Each stop ends the iteration there, with no record … A stop after step 0.3 removes WT … (with `--force` …; its branch stays)" · 9.5: "refuses while it has tracked edits or is mid-merge: a stop" · step 7's dedupe: "an item on its `Asked:` line ends `@TIP`, or WT's questions files hold its merge entry's heading".

Neither dedupe key survives a failed land. The next iteration's WT comes from main, so every blocked, stopped and merge entry the failed iteration filed is filed again under fresh IDs (next-id from main, possibly the same numbers). The text gives no retry path. The idempotency guarantee D13 states ("an entry is filed once per marker SHA", D4 `:62`) holds only on the success path.

**Recommendation:** Add D13's retry: at step 0, if the previous iteration's `chore/dev-cycle-*` branch exists and is not an ancestor of main, land it (9.2-9.5 from a fresh WT on that branch) before step 7. Or state the deviation from D13 and its duplicate-entry consequence as a residual.

#### 7. A capped entry can write `Q-NNN@-`, which `--cycle-diff` refuses

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:500-501, 650-653`; `scripts/build-loop.sh:72-79, 229-231`
**Move:** 8 (nullability)
**Confidence:** Medium

Evidence: step 10, "A brief `--status` read with DISPATCHED 4 … one entry as step 7 files them, slug `capped-STEM-N`". Step 7 files with "Add `Q-NNN@TIP` to the brief's `Asked:` line", where TIP is "the line's SHA". `--status`: SHA is "`-`" when absent. `--cycle-diff`: "Each item added … must be exactly Q-NNN or Q-NNN@SHA (7-64 hex)". A brief at the cap whose branch was deleted (for example, by the user after step 1's merged-branch list) reads LOOP absent. Step 7 hands it to step 10 ("absent: not dispatched yet; step 10 takes it"), and the capped entry's `Asked:` item `Q-NNN@-` makes the second land refuse, which is a stop. TIP is a nullable field, and the skill uses it as if it were always a SHA.

**Recommendation:** For a capped entry with SHA `-`, write the bare `Q-NNN` (the form `--cycle-diff` allows). Or check the cap in step 7 before the absent bullet, and key it on DISPATCHED alone.

#### 8. The record template has no `9.` line, and the second land's paths are not listed

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:209-210, 565-581, 595-599, 655-657`
**Move:** 7 (asymmetry)
**Confidence:** Medium

Evidence: "Every step ends with a line in the cycle record, including "skipped: <reason>"". The template's Steps run `… 7. collect … 8. briefs … 10. dispatch` with no `9.`. Step 10: "Then land again as step 9 does (1 to 5): the briefs' `Dispatched:` lines and the record's `10.` line". 9.1: "Before the record's last write, list under `### Paths landed` what the land carries". In the second land, the record's last write (the `10.` line) comes before 9.1 would re-list, and the text does not say whether `### Paths landed` is rewritten for the second land's carried paths (rows 722, 772).

**Recommendation:** Add `9. record and land: <landed NEW / stop: why>` to the template, or exempt step 9 in the Flow sentence. Say that the second land appends its own `### Paths landed` listing, or that its carried paths are named on the `10.` line.

#### 9. `capped` is a third terminal state where D1 names it a stopped reason

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:650-653, 511`; plan `:42`
**Move:** 2 (naming)
**Confidence:** Medium

Precedent: "after which it is `stopped: dispatch cap`" used in `docs/working/plan-build-loop-handoff.md:42` (D1)

Evidence: "slug `capped-STEM-N` … with options **[1] keep** (it stays open, for work by hand) and **[2] drop**" vs D4's stopped options "**[1] re-dispatch** and **[2] drop**". The skill's choice is sensible, because re-dispatch is impossible at the cap. But it creates a name and option set that D1/D4 do not have, and step 7's "a `capped-` one's changes nothing" is the only place that ties the two together.

**Recommendation:** Note in the plan (or in a decision-log row) that the dispatch cap files `capped-STEM-N` rather than `stopped-`, with keep/drop.

#### 10. Docs that describe the skill still say "writes build briefs … User-started, no timer"

**Severity:** Minor
**Location:** `global-instructions/CLAUDE.md:32`; `skills/dev-cycle/SKILL.md:4, 670-674`
**Move:** 3 (documentation drift)
**Confidence:** Medium

Evidence: CLAUDE.md row 12: "roadmap (`docs/roadmap.md`), then writes build briefs for its top items. User-started, no timer." The new description says "(`/loop /dev-cycle` repeats it) … collect build-loop results, write build briefs into free slots, record and land, and dispatch build loops". Wait (D12) adds "a 1800 s fallback wakeup". Plan U5 (`:345-356`) updates `docs/dev-cycle.md` and onboarding, not the decision-tree row. The skill's own rule says "A feature without documentation is a bug".

**Recommendation:** Add the row-12 wording to U5's doc list (it is an instruction file, so it lands by review), or file it on the roadmap.

#### 11. D4's `Review handoff: pull request` path is neither implemented nor deferred in the skill

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:108-131, 479`; plan `:59, 346`
**Move:** 3 (consumer contract vs spec)
**Confidence:** Medium

Evidence (D4): "`ready` under `review` → where `docs/dev-cycle.md` says `Review handoff: pull request`, push the branch and open a draft PR … Otherwise it files one merge entry". The skill's settings block and step 7 have no such line or branch, and `--settings` prints no such line (`build-loop.sh:19-66`). U5 is due to document the setting (plan `:346`). A repo that sets it will get merge entries without warning.

**Recommendation:** Add one line to step 7 (or the settings list) saying the PR handoff is not built and every review brief gets a merge entry. Or drop the setting from U5's list.

#### 12. Small naming drift in the contract text: "newest" vs "last" `Main at:`, and `Asked:` items vs IDs

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:235-236, 586-587, 503-505, 185-186`
**Move:** 2 (naming)
**Confidence:** Low

Precedent: "the last record's `Main at:` SHA" used in `docs/working/plan-build-loop-handoff.md:101` (D13)

Evidence: step 0.2 "SINCE is the newest `Main at:` line of the newest record"; step 9 "step 0.2 takes the file's last `Main at:` line as the next SINCE". These are equivalent only while blocks are append-only, which step 9 requires. Step 7 runs `--check-answer` "with the IDs of every brief's `Asked:` items", but the items are `Q-NNN@TIP`, and the Rules skip any value with a character outside letters, digits, `.`, `_`, `-`, `/`, `*` and `?` (so `@` is skipped). Stripping `@TIP` is implied, not stated.

**Recommendation:** Use "last" in both places. Write "the IDs (each item up to `@`)".

## What Looks Good

- The merge-entry heading rule now matches `approval()` exactly, including `deny` lines and the full-TIP binding ("TIP the full one the entry names, never the branch's live tip"), and a test pins the GATE_CODE copy.
- The new slugs (`blocked-`, `stopped-`, `capped-STEM-N`) fit `--cycle-diff`'s `WORDS-STEM-N` grammar. Merge entries are kept off `Asked:` (and tracked on `Applied:`), which avoids the slug rule they could not satisfy.
- Refusal texts the skill matches ("retry once it ends", "under 2 hours old") are substrings of the script's actual messages (`build-loop.sh:2145, 1612`). `ok BRIEF BRANCH DIR` / `dispatched N` and the "every line after" prompt relay match `--start`'s header.
- The brief's machine lines (`Branch:`, `Policy:`, `Paths:`, `Dispatched: N` replaced in place) match the `--status`/`--check` readers' forms. The record's `Branch:`/`Main at:` stay unfenced at column 0 for `--main-log`/`--land-cycle`.
- Step naming is consistent across the description, Flow, headings and record lines, and step 7/D4, step 8/D9, step 10/D1 and D12 cite the plan's decision numbers correctly.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Blocked answers go through keep/drop/done; `[4]` or a fact reads unrecognized forever, no re-dispatch | Breaking | `SKILL.md:497-510` | High |
| 2 | Option labels (merge, re-dispatch, changes needed) not reader words; `done` on stopped/capped unhandled | Inconsistent | `SKILL.md:486-515, 652` | High |
| 3 | "Slot" means open brief (Rules, step 1) vs live loop (steps 8, 10, D9); 8 and 10 count differently | Inconsistent | `SKILL.md:167-170, 522-525, 634-635` | High |
| 4 | Self-merge N-rule deny falls through to an unlandable merge entry | Inconsistent | `SKILL.md:476-478` | Medium |
| 5 | Headers still name keep-or-drop / `Kept:` | Minor | `dev-cycle.sh:61`, `build-loop.sh:234, 1972` | High |
| 6 | No D13 failed-land retry; entries re-filed from main | Inconsistent | `SKILL.md:59-66, 620-624` | Medium |
| 7 | Capped entry with absent branch writes `Q-NNN@-`, refused | Minor | `SKILL.md:500, 650-653` | Medium |
| 8 | No `9.` record line; second land's Paths landed unspecified | Minor | `SKILL.md:565-581, 655` | Medium |
| 9 | `capped` vs D1's `stopped: dispatch cap` | Informational | `SKILL.md:650-653` | Medium |
| 10 | CLAUDE.md row 12 "User-started, no timer" stale | Minor | `global-instructions/CLAUDE.md:32` | Medium |
| 11 | D4 `Review handoff: pull request` neither built nor deferred | Informational | `SKILL.md:108-131, 479` | Medium |
| 12 | "newest" vs "last" Main at:; `Asked:` items vs IDs | Informational | `SKILL.md:235, 586, 503` | Low |

## Overall Assessment

The skill-to-script contract is mostly tight. Line forms, slugs, headings and the refusal substrings
the skill matches agree with the headers and code, and iteration 1's A1-A4 fixes hold up from the
interface side. The defects concentrate in the **answer channel**. Step 7 reuses `--check-answer`,
whose vocabulary was designed for keep-or-drop entries, for four new entry kinds whose option labels
and open-ended (blocked) answers it cannot read (findings 1, 2). This blocks the blocked → answer →
re-dispatch loop, which is the core of D2/D4, and it needs a fix in place before merge. The rest is
naming drift ("slot", finding 3), one fall-through that ignores the N/S rule split (4), one spec
divergence with idempotency consequences (6), and stale consumer docs (5, 10). All are fixable in
SKILL.md, except 5, which touches gate code and belongs to a later merge-gate change.

## Goal-Alignment Note

Success criterion: "An API-consistency review saved at the given path, structured per the
api-consistency-reviewer skill." Met. The report has the required header, Baseline Conventions,
Name-Pattern Audit table, Findings (each with Severity, Location, verbatim Evidence, Confidence and a
Precedent/No-precedent line on naming findings), What Looks Good, Summary Table and Overall
Assessment. It is saved at `docs/reviews/api-consistency-review-2026-10-13-u4b2-i2.md` in the worktree.
Legibility target: every finding quotes the SKILL.md text and the script header or code line it
disagrees with, so a reader can check it without re-running anything. Findings 1-2 rest on an
executed probe (`scratchpad/u4b2-i2/api/probe-answer.sh`, a temp repo with `--check-answer` run
against main's commit: `[4]`, free text, `merge` and `re-dispatch` → `unrecognized`; `done` on a
stopped entry → `done`). The other findings are static readings of the cited lines. Not covered:
security of GT's `worktree add` checkout (left to security-reviewer) and the full `--cycle-diff`
refusal list (fact-check's claim 20). This is a single-sample review, and an absence of findings is
not an attestation.
