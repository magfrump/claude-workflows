Commit: d5d9121 (A) / fbc7101 (B)

# API Consistency Review: dev-cycle pass 21 (pass-20 fix round)

**Scope:** Partial, the pass-20 fix round only. A: `git diff 546b86e..d5d9121 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (worktree `/workspace/.claude/wt-digest`). B: `git diff 46d3423..fbc7101 -- skills/dev-cycle/SKILL.md` (worktree `/workspace/.claude/wt-devcycle`, HEAD f493fc6 only merges A in), plus `docs/dev-cycle.md` and the archive's real answer lines as the consumer side. Everything else is context.
**Date:** 2026-10-02
**Based on:** `docs/reviews/code-fact-check-report-digest-pass20.md` (Stage-1 context, pass-19 round; 0 Incorrect) and `docs/reviews/api-consistency-review-2026-10-02-digest-pass20.md` (the findings this round fixes).

Probes (scratch `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/api21/`): one throwaway repo under a `mktemp -d` dir there (now removed), every run under `timeout`. `bats test/scripts/dev-cycle.bats` gives 26/26 (`LC_ALL=C.utf8`). Nothing was written to either worktree except this file.

## Baseline Conventions

- **Check-mode output.** Each line is `ok <path>` or `skip <arg or match>: <reason>`. The reason is a short lowercase phrase: "not an allowed path form", "reached through a symlink, or not a regular file", "no tracked file (or ignored file under docs/working/) matches". Exit is 0 once every argument has an answer and 1 on bad usage (`scripts/dev-cycle.sh:29-31`).
- **Script references in skills.** Skills call the installed `~/.claude/scripts/<name>.sh`. The exception is inside claude-workflows, where they call the repo's own copy. Precedent: `questions.sh` at `skills/dev-cycle/SKILL.md:135-136`, and the digest call at `:101`.
- **Answer recording in this repo.** The agent records the answer inline as a bold labelled line, and the archive holds the result. Of the 80 non-index `**Answer…**` lines in `docs/working/questions-archive.md`:
  - 65 put the answer inside the bold and follow it with prose (`**Answered 2026-09-20: [1].** File tools: …`, `:530`);
  - 6 put only the label in bold (`**Answer (2026-10-01, in chat):** [1]. …`, `:1832`);
  - 9 end the line at the bold close.
- **The cycle's own files.** These are `docs/roadmap.md`, `docs/working/{questions,questions-archive,idea-log}.md`, `docs/working/cycles/cycle-YYYY-MM-DD.md` and `docs/working/briefs/YYYY-MM-DD-<slug>.md`, with slugs in lowercase letters, digits and hyphens (`SKILL.md:277-279`).

## Name-Pattern Audit

The round adds no flags, functions or exported names. Its new public surface is two reason strings and one skill term. `writable()` is private, like its neighbours `inrepo`, `dirok` and `pathform`.

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `skip <a>: not one of the files the dev cycle writes` | output reason | "not an allowed path form", "reached through a symlink, or not a regular file" | `scripts/dev-cycle.sh:176-201` | Consistent shape. Its claim ("the files the dev cycle writes") conflicts with the skill's in-cycle writes (Finding 1). |
| `skip <a>: matches more than 50 files; the rest are not listed` | output reason | "no tracked file (or ignored file under docs/working/) matches" | `scripts/dev-cycle.sh:181,186` | Consistent: names the argument, says what was not done. |
| "label colon" (answer text after it) | skill term | `Q-NNN: …` answering protocol (global instructions); `**Answer…**` lines | `docs/working/questions-archive.md:1521,1697,1832` | Consistent with the archive's label shape. Its scope stops short of the house style (Finding 3). |
| `writable` | private function | `inrepo`, `dirok`, `rawfile`, `plaindir` | `scripts/dev-cycle.sh:110-136` | Consistent: a predicate named for the property. |

## Findings

#### 1. Narrowing `--check-write` to the cycle's own files leaves the skill's in-cycle fixes either forbidden or unchecked

**Severity:** Inconsistent
**Location:** `skills/dev-cycle/SKILL.md:68-70` against `:37-41`, `:146`, `:166-169`, `:181-183`; `scripts/dev-cycle.sh:188-201`
**Move:** 3 (consumer contract)
**Confidence:** High that the conflict exists; Medium on which reading an agent takes
**Legibility-target:** agent, user

**Evidence:**
> "Before writing a file (the record, a brief, the idea log, the roadmap, the questions files), run the same script with `--check-write '<path>'` and write only on `ok`; it allows only those files." (`SKILL.md:68-70`)
>
> "the doc is written in-cycle if that is mechanical" (`:38-39`); "Fix what is mechanical now, one commit per concern." (`:146`); "if it is mechanical, fits in one commit and needs no choice, do it in-cycle" (`:167`); "A claim that no longer holds is a finding: fix it if mechanical" (`:182`)
>
> Probe: `--check-write README.md docs/dev-cycle.md docs/decisions/log.md` gives `skip README.md: not one of the files the dev cycle writes` (likewise for the other two), exit 0.

Before d5d9121, `--check-write` accepted any plain path, so the skill's in-cycle fixes also passed through the check. The round limits `writable()` to the cycle's own files and states that limit in both the skill and the script ("the files the dev cycle writes"). It leaves the four places where the skill writes other files untouched. Read as covering every write, the rule forbids the documented in-cycle fixes, and the script's reason contradicts the skill: the cycle does write `README.md`-type docs in-cycle. Read as covering only the listed files, the rule lets in-cycle fixes write a path that repo text named (the doc a merge forgot, the file a claim lives in) with no symlink check. The rule's own heading says such paths "go through the digest's check". Pass 20 asked for exactly this narrowing (security M1), so the fix is right. What is missing is the consumer side.

**Recommendation:** Name the in-cycle case in the rule. One sentence would do: "An in-cycle fix edits only an existing file that `--check-path` prints `ok` for (tracked, plain); a fix that needs a new file is filed, not written." `--check-path` already enforces tracked, plain and not a symlink. Otherwise, say that in-cycle fixes go through `pr-prep` and are not written by the cycle.

#### 2. `local LC_ALL=C` prints a setlocale warning on every return when the caller's locale is not installed, as in this container

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:152-163` (called from `:176`, `:182`, `:198`)
**Move:** 3 (consumer contract: what the caller sees)
**Confidence:** High
**Legibility-target:** agent

**Evidence:**
> `local LC_ALL=C p="$1" rest c set='^[A-Za-z0-9._/-]+$'` (`:155`; the loop to `:162` follows)
>
> Probe in this sandbox (`LC_ALL=en_US.UTF-8`, `locale -a` = C, C.utf8, POSIX): `scripts/dev-cycle.sh --check-path 'docs/working/*'` prints one `scripts/dev-cycle.sh: line 182: warning: setlocale: LC_ALL: cannot change locale (en_US.UTF-8)` on stderr per match, plus one for line 176 per argument, interleaved with the `ok` lines.

The C-locale change works: a probe shows `local LC_ALL=C` switches `=~` to bytes inside the function in bash 5.2.15 and restores the caller's locale afterwards. The restore is a `setlocale` call, though. When the caller's `LC_ALL` names a locale that is not installed, every restore warns. That is the user's own environment, so a 50-file glob adds about 51 warning lines. An agent's Bash tool merges stderr into the output it reads. No warning starts with `ok `, so nothing is misread, but the noise grows with the cap. The tests use `--separate-stderr` and set no broken locale, so they cannot see it.

**Recommendation:** Set the locale once and do not restore it. For example, `export LC_ALL=C` at the top of the `if [[ -n "$CHECK" ]]` block (`:203`), before the loop, with no restore in the check modes since they exit right after. Alternatively, spell the classes without ranges.

#### 3. The bare-word branch (`keep`, `drop`, `1`, `2`) still fails on the shape 65 of 80 real answer lines take

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:248-258`
**Move:** 3 (consumer contract), against the archive's real lines
**Confidence:** High
**Legibility-target:** agent, user

**Evidence:**
> "taking only the text after that line's label colon, with `*` and a trailing `.` removed. The option is the first `[1]` or `[2]` in that text (as in `Q-NNN: [1]`); with neither, text that is exactly `1`, `keep`, `2` or `drop` (any case) and nothing else." (`:250-253`; the mapping and `Applied:` follow to `:258`)
>
> House style: `**Answered 2026-09-17: backfill. Done.** 164 entries (FP-008..FP-171) harvested` (`questions-archive.md:259`); `**Answered 2026-09-20: either.** Row 1 now fires only when …` (`:549`)

Precedent: date-labelled bold answer with trailing prose used in `docs/working/questions-archive.md:108-162, 259, 495-877, 1263-1635` (65 of the 80 non-index answer lines)

The fix defines the answer text as everything after the label colon, and that includes the prose after the closing `**`. A user's bare `keep`, recorded in the dominant house style as `**Answered 2026-10-20: keep.** Still wanted.`, becomes `keep. Still wanted.`. That is not "exactly `keep`", so it is unrecognized, the ID goes to `Applied:`, and step 3 asks again. Leading whitespace is not stripped either (`**Answered …: keep**` gives ` keep`), although the pass-20 recommendation included it. The bracket branch works on every archived form. The failure is safe, a re-ask rather than a misapplied answer, but it spends the attention the rules call the budget.

**Recommendation:** Bound the answer text at the end of the bold span when the label is bold: the text from the label colon to the closing `**`, or, for a label-only bold, to the end of the first sentence. Then trim whitespace. Alternatively, have step 6 tell the recorder to write the bracket (`[1]`) for a bare keep or drop, which 40+ archive lines already do.

#### 4. A roadmap brief path "counts" on `--check-write ok`, which an absent or impossible-date file also gets

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:70-71`, `:240-265`; `scripts/dev-cycle.sh:191-201`
**Move:** 3 (consumer contract)
**Confidence:** Medium
**Legibility-target:** agent

**Evidence:**
> "A roadmap brief path counts as a brief only if `--check-write` prints `ok` for it." (`SKILL.md:70-71`)
>
> Probe: `--check-write docs/working/briefs/2026-01-01-gone.md docs/working/briefs/2026-13-45-x.md` gives `ok` for both. Neither file exists, and the second date is not a date. `--check-path` on the first gives `skip …: no tracked file (or ignored file under docs/working/) matches`.

`--check-write` checks only the name's shape and that no part of the path blocks it. That is right for a file about to be written, but it is the wrong question for "is this an existing brief". A roadmap In-flight line that names a dated brief path which does not exist (renamed, never landed, a typo) counts as a brief. The In-flight checks then need its `Status:`, `Asked:` and `Kept:` lines, and the read check refuses it. The skill does not say whether such a brief is open, whether it holds one of the three slots (`:276`), or whether it goes to `## Skipped inputs`.

**Recommendation:** Say "counts as a brief only if `--check-write` prints `ok` and `--check-path` prints `ok` for it; otherwise record it under `## Skipped inputs` and move the item to Now with a note". Optionally, have `writable()` take `[01][0-9]-[0-3][0-9]` for the date, as the window logic already demands "a real date".

#### 5. docs/dev-cycle.md still describes the check as before the round

**Severity:** Minor
**Location:** `docs/dev-cycle.md:27-30`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** user, agent

**Evidence:**
> "Each row is passed to `dev-cycle.sh --check-path`, which allows tracked files and gitignored files under `docs/working/` (so the self-improvement loop's ignored round files count), never a symlink, `..`, `.git*` or any other untracked file." (`:27-30`; the charset sentence follows to `:30`)

The skill now names the installed `~/.claude/scripts/dev-cycle.sh`, says "at most 50 per argument", and lists "a directory" among the refusals (`SKILL.md:64-68`). The settings doc a user edits rows in has none of the three. Pass 20 #3 already cited this location, and fbc7101 changed only the skill. A user who writes a broad idea-source glob (`docs/**/*.md`) will not learn from this doc that only the first 50 matches are read.

**Recommendation:** Mirror the skill's sentence: installed path, "at most 50 files per row", "a directory".

#### 6. Carry-over (pass 20 #5): a directory is still refused with the "no tracked file" reason

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:186`; `skills/dev-cycle/SKILL.md:66-68,73-74`
**Move:** 4 (error consistency)
**Confidence:** High
**Legibility-target:** agent, user

**Evidence:**
> Probe on the real repo: `--check-path docs` gives `skip docs: no tracked file (or ignored file under docs/working/) matches`
>
> "`--check-path` allows … never a symlink, a directory, `..`, `.git*` …" (`SKILL.md:66-68`); "Every skip, with its reason, goes in the record" (`:73-74`)

d5d9121 fixed the `skip <arg or match>` half of pass 20 #5 (help `:18-21`), but not the directory reason. The record therefore says a tracked directory has "no tracked file", while the skill's list says directories are refused as directories. Likewise, `./docs/dev-cycle.md` (newly refused for its `.` component) gets "not an allowed path form", and the skill's refusal list does not mention `.` components.

**Recommendation:** Give the directory case its own reason ("names a directory, not a file"), and add "a `.` component" to the skill's list.

#### 7. Edges of the answer rule on real archive lines: a hedged answer reads as keep, and `**Answering …**` matches `**Answer…**`

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:249-253`
**Move:** 3
**Confidence:** Medium
**Legibility-target:** agent

**Evidence:**
> `**Answered 2026-09-27: between [1] and [2].** New reviews should not each add a canon entry.` (`questions-archive.md:1452`)
>
> `**Answering "I don't see what action" (2026-09-17):** my entry was wrong to imply a container.` (`questions-archive.md:443`, an agent's reply, in the same entry as an `**Answered …**` line at `:441`)
>
> `**ANSWERED 2026-09-15: no — …` (`:198`)

Under "first `[1]` or `[2]`", the real hedge at `:1452` reads as `[1]`. On a keep-or-drop entry that sets `Kept:` (the conservative action) rather than re-asking. The pattern `**Answer…**` also matches the agent-written `**Answering …**` line. An entry with both kinds of line has two candidates, and the skill says "the … line" (singular). The archive also uses `ANSWERED` in upper case. None of these is likely on a two-option keep-or-drop entry. All are cheap to close.

**Recommendation:** "the user's answer line: `Q-NNN: …` or `**Answer…**`/`**Answered …**` (any case), not `**Answering …**`; with both `[1]` and `[2]` in it, unrecognized."

#### 8. The 50 cap cuts deterministically, but by sort order, and gives no next step

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:164-186`; `skills/dev-cycle/SKILL.md:66-67`
**Move:** 5 (pagination pattern)
**Confidence:** High
**Legibility-target:** agent

**Evidence:**
> Probe: 55 tracked `docs/working/tNN.md` plus an ignored `docs/working/scratch1.md`; `--check-path 'docs/working/*'` gives `ok docs/working/t01.md` … `t50.md`, then `skip docs/working/*: matches more than 50 files; the rest are not listed`. `scratch1.md` is never reached.

The cut is deterministic: `git ls-files` emits in index (path) order, tracked first, then ignored. As a result, a broad glob over `docs/working/` never reaches the ignored round files the read scope exists for once 50 tracked files match. This is the first list-shaped output in the script, so no pagination precedent exists. The skill says "at most 50" but not that the listed 50 are still to be opened, nor that the agent should narrow the glob to see the rest.

**Recommendation:** Add a clause to the skip reason or to the skill: "the first 50 by path, tracked before ignored; narrow the glob to reach the rest".

## What Looks Good

- **Each mode's scope is stated separately** (`SKILL.md:66-71`; help `:18-23`), and the two now agree: the write list in the skill ("the record, a brief, the idea log, the roadmap, the questions files") matches `writable()` exactly. The probe allowed the questions files, idea log, roadmap, cycle records and dated briefs (including `-2` suffixes), and refused `AGENTS.md`, `README.md`, `.env`, uppercase or underscore slugs and `docs/dev-cycle.md`. Pass 20 #1, #4 and #7 are closed.
- **Installed script path** (`:64-65`) now matches the digest call (`:101`) and the `questions.sh` precedent (`:135`). Pass 20 #3 is closed in the skill (but see Finding 5).
- **The `Exit:` line** (`:29-31`) now says a skip is an answer, not an error. **Help** prints the new text in full (`sed -n '2,32p'` ends at the blank line). Pass 20 #6 is closed.
- **Re-answer wording** (`:256-257`) is coherent with step 3. An unrecognized answer sets no `Kept:`, so the 14-day condition that filed the first entry still holds, and step 3 files the next keep-or-drop entry in the same cycle. Pass 20 #9 is closed.
- **Pre-filter skips recorded** (`:72-74`): pass 20 #8 is closed.
- **The ignored-query prefix test** is complete for the cases asked. `*/working/rounds/*`, `d*/working/rounds/*`, `docs/*/rounds/round-1.md`, `**/round-*.md`, `**/scratch1.md`, `docs/w?rking/scratch1.md` and the plain path all still reached the ignored file in the probe. Only arguments whose fixed prefix diverges from `docs/working/` skip the query, and those cannot match there.
- **The C-locale switch takes effect** for `=~` inside the function, and the caller's locale comes back (probe, bash 5.2.15). The explicit `[.][gG][iI][tT]*` class refuses `.Git` (test `:504-507`).
- **Branch-name charset** (`:281`) reuses the path rule's characters minus the glob characters, and refuses a leading `-`. That is consistent with the repo's other option-injection guard (`dev-cycle.sh:209-210`).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Narrowed `--check-write` leaves in-cycle fixes forbidden or unchecked | Inconsistent | `skills/dev-cycle/SKILL.md:68-70` vs `:38-39,146,167,182`; `scripts/dev-cycle.sh:188-201` | High / Medium |
| 2 | `local LC_ALL=C` warns on every return under an uninstalled caller locale | Minor | `scripts/dev-cycle.sh:155` | High |
| 3 | Bare-word answers fail on the house style (65/80 lines carry prose after the bold) | Minor | `skills/dev-cycle/SKILL.md:250-253` | High |
| 4 | Brief "counts" on `--check-write ok`, which absent and impossible-date paths get | Minor | `skills/dev-cycle/SKILL.md:70-71`; `scripts/dev-cycle.sh:191-195` | Medium |
| 5 | docs/dev-cycle.md lacks installed path, cap, directory | Minor | `docs/dev-cycle.md:27-30` | High |
| 6 | Carry-over: directory gets the "no tracked file" reason; `.` component unlisted | Minor | `scripts/dev-cycle.sh:186`; `SKILL.md:66-68` | High |
| 7 | Hedged `[1] and [2]` reads as keep; `**Answering**` matches `**Answer…**` | Informational | `skills/dev-cycle/SKILL.md:249-253` | Medium |
| 8 | 50 cap cuts by sort order, tracked before ignored; no next step | Informational | `scripts/dev-cycle.sh:164-186` | High |

## Overall Assessment

The round closes pass 20's API findings #1, #3 (in the skill), #4, #6, #7, #8 and #9, half of #5, and #2's definitional gap. The modes' help, the `Exit:` line and the skill now describe the same contract. One consumer-side gap is new (Finding 1). The write check is now correctly narrow, but four places in the skill still write other files in-cycle, and the rule neither forbids them nor routes them through `--check-path`. One sentence in the rule fixes it. Finding 2 is a small script fix that matters in the user's own container. Findings 3–6 are wording or doc follow-ups that fail safe. No finding is Breaking, and nothing found here is an Incorrect claim about behaviour.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/api-consistency-review-2026-10-02-digest-pass21.md`, with first line `Commit: d5d9121 (A) / fbc7101 (B)`. It follows the skill's structure: header, Baseline Conventions, Name-Pattern Audit, Findings, What Looks Good, Summary Table, Overall Assessment. Every finding carries Severity, Location, Evidence (verbatim), Confidence and Legibility-target. The one naming-shaped finding (3) carries its `Precedent:` line. It serves the user's goal of reaching a clean pass by naming one new Inconsistent that blocks "no known issues", along with the fixes that close it. Nothing was committed.
