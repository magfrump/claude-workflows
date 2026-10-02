Commit: 723c242 (A) / 1f36885 (B)

# API Consistency Review — dev-cycle pass 17 (full-review fix round)

**Scope:** A: `git diff 09f6fe7..723c242 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (wt-digest). B: `git diff 074164b..1f36885 -- skills/dev-cycle/SKILL.md docs/dev-cycle.md docs/working/seed-build-loop-handoff.md` (wt-devcycle). Partial scope: everything outside these diffs is context only.
**Date:** 2026-10-02
**Based on:** `docs/reviews/code-fact-check-report-dev-cycle-full.md` (Stage 1, full review on bc5dc76; claims 58, 60 and 72 concern text this round rewrote and were re-checked here)

Method notes: the 723c242 script was read whole (`git show 723c242:scripts/dev-cycle.sh`, 396 lines) and run under `timeout` in a throwaway repo under `scratchpad/api17/` (merge-only record, a side-branch change the merge discarded, names containing `"`, `\`, TAB and a space, a rename). Every option form was run under bash. `bats test/scripts/dev-cycle.bats`: 23/23 ok (wt-digest HEAD d0f1c6a has no `scripts/` or `test/` diff from 723c242). The 1f36885 skill was read whole. `scripts/questions.sh` was read for `init`, `archive`, `open`, `check` and the entry grammar. Nothing was written to either worktree except this report.

## Baseline Conventions

- **Digest CLI** (`scripts/dev-cycle.sh` header and parser). Long options in both `--opt X` and `--opt=X` forms, plus `-h|--help`. Errors go to stderr as one plain sentence naming the flag (`--sample must be a non-negative integer`, `--since must be a real YYYY-MM-DD date`, `Unknown option: X`), with exit 1. The sibling `scripts/questions.sh` uses subcommands, not flags, so for flag style the digest is its own precedent.
- **Digest printed format.** There are eight `## N. Title` sections. Inline notes take a fixed shape: `X is not read: Y is not a plain file or directory (section 8).` An empty result is a sentence (`None open.`, `None in the window.`, `None: no input was skipped.`). Record headers read `### <path> (last committed on this branch: <YYYY-MM-DD | never, uncommitted>)`.
- **Questions grammar** (global CLAUDE.md "Running questions document"; enforced by `scripts/questions.sh check`). Headers are `### Q-NNN · <slug>`, where the slug matches `[a-z0-9-]+` (`questions.sh` check, `^\#\#\#\ Q-[0-9]{3}\ ·\ [a-z0-9-]+$`). Option cells are `**[1] <name>**`. Answers are given as `Q-NNN: [2]` and recorded inline, for example `**Answered 2026-09-27: [3] resume — …**` (`docs/working/questions-archive.md`, Q-068). Dates are `YYYY-MM-DD`.
- **Working-dir layout.** `docs/working/<plural noun>/` holds dated files: `docs/working/cycles/cycle-YYYY-MM-DD.md` and `docs/reviews/`. Briefs now follow it as `docs/working/briefs/YYYY-MM-DD-<slug>.md`.
- **Brief line fields** (pre-existing, context). `Status: open|closed`, plus `Asked:`, `Applied:` and `Kept:` as `Key: value` lines. The questions file's `**Status:** OPEN|ANSWERED` uses a different case and bolding. That convention predates this round and is out of scope.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--since needs a value` / `--sample needs a value` | CLI error message | `--sample must be a non-negative integer`, `--since must be a real YYYY-MM-DD date`, `Unknown option: X` | `scripts/dev-cycle.sh:82,85,181` | Consistent. Flag-first plain sentence on stderr, exit 1. It replaces bash's `${2:?}` text, which carried a `line N:` prefix. |
| `Open by route: none` | printed value | `None open.`, `None in the window.`, `None: no input was skipped.` | `scripts/dev-cycle.sh:282,328,392` | Consistent in spirit. The lower-case `none` is the value slot of a `Key: value` line, not a sentence. |
| Section 2 lead sentence (scope of "every trigger") | printed prose | sections 6 and 7 lead lines | `scripts/dev-cycle.sh:316-319,344` | Consistent. See Finding 4 for the skill side. |
| `docs/working/briefs/` | directory | `docs/working/cycles/`, `docs/reviews/`, `docs/decisions/` | `skills/dev-cycle/SKILL.md:269`, `scripts/dev-cycle.sh:152` | Consistent. Plural noun with dated files inside. |
| brief slug `[a-z0-9-]` | file-name grammar | questions slug `[a-z0-9-]+` | `scripts/questions.sh` `cmd_check` header regex | Consistent. The same alphabet as the questions slug. |
| `**[1] keep**` / `**[2] drop**` | question options | `**[1] <name>**` option cells; `Answered …: [3] resume` | global CLAUDE.md options table; `docs/working/questions-archive.md` (Q-068) | Consistent. See Finding 3 on how answers are matched. |
| `Kept: <today>` (YYYY-MM-DD) | brief field value | `**Opened:** YYYY-MM-DD`, `cycle-YYYY-MM-DD.md` | `scripts/questions.sh:16`, `skills/dev-cycle/SKILL.md:269` | Consistent. |
| `Asked:` / `Applied:` separator `", "` | brief field value | none. These are the only multi-ID fields. | none. Searched `skills/`, `scripts/questions.sh`, `docs/working/questions*.md` | New convention, now stated for both fields. Consistent between the two. |
| `need()`, `last_date`, `routes` | private shell helpers and locals | n/a | n/a | Private. Not audited. |

## Findings

#### 1. Section 2's "last committed" date says "never, uncommitted" for committed records: a merge-only record, or a name containing `"` or `\`

**Severity:** Inconsistent
**Location:** `scripts/dev-cycle.sh:207-225` (723c242)
**Move:** 3 (consumer contract: the printed field's meaning changed from the per-file lookup it replaced)
**Confidence:** High (executed)
**Legibility-target:** for-author

**Evidence (verbatim):**
```
# cost records x history. A name git still quotes (a control character) misses
# the map and falls back to its own lookup.
...
    git -c core.quotePath=false log --format='@%ad' --date=short --name-only -- docs/decisions \
...
  d="${last_date[$f]-}"
  [[ -n "$d" || "$f" != *[[:cntrl:]]* ]] || d="$(git log -1 --format=%ad --date=short -- "$f")"
```
The quoted lines end inside the unit. The rest of the loop (`:224-226`) prints `### … (last committed on this branch: ${d:-never, uncommitted})` and the triggers.

The brief's claim 1 asks whether the map gives exactly what per-file `git log -1 -- f` gave. It does not in three cases. A probe repo (`scratchpad/api17/tmp.*/r`) gave these results:
- **A merge-only record** (added in the merge commit itself): `git log -1 -- docs/decisions/003-c.md` gives `2026-04-01`. The digest prints `### docs/decisions/003-c.md (last committed on this branch: never, uncommitted)`. `git log --name-only` without `-m`/`--diff-merges` lists no files for a merge, so the name never enters the map, and the fallback only fires for control characters.
- **Names git quotes without a control character.** `core.quotePath=false` still quotes `"` and `\`. Git printed `"docs/decisions/004-a\"q.md"` and `"docs/decisions/005-a\\b.md"`, and both records came out as `never, uncommitted` although they were committed on 2026-04-02. The comment's "(a control character)" understates git's quoting rule, and the `*[[:cntrl:]]*` guard inherits the gap. TAB (`006-a<TAB>t.md`) and space names were correct.
- **A side-branch change that the merge discarded** (`-s ours`): per-file gives `2026-01-01`, the map gives `2026-03-01`. The file-level pathspec simplifies the side branch away, but the directory-level walk keeps it. The date is still a commit reachable on this branch, so this one is defensible and matters less.

Renamed records were correct (`008-renamed.md` gave `2026-04-03`). Preconditions: a decision record whose only commit is a merge, or a record name containing `"` or `\`. Both are rare in this repo. Consumer impact: step 2's agent reads "never, uncommitted" as a work-in-progress record, which is false and can colour a trigger verdict. No test asserts the date in this header (`grep 'last committed' test/scripts/dev-cycle.bats` finds nothing), so the 723c242 change went in unchecked.

**Recommendation:** Fall back on any map miss, not only for control characters: `[[ -n "$d" ]] || d="$(git log -1 … -- "$f")"`. That costs one lookup per miss, and misses are now only genuinely uncommitted or unusual names. It fixes both the merge-only and the quoted-name cases. Fix the comment, and add a bats case with a committed `"`-named record and a merge-only record that asserts the date.

#### 2. "Relative" path rule names no base; brief links are the case where that matters

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:61-64`; `docs/dev-cycle.md:27-28`; `skills/dev-cycle/SKILL.md:264` (1f36885)
**Move:** 3 (contract for paths taken from repo text) / 7 (write side vs read side asymmetry)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence (verbatim):**
> "A path taken from repo text (a settings row, a brief link) must be relative, must not start with `/` or `~`, and must have no `..` component." (SKILL.md:63-64)

> "Relative paths inside the repo only (no leading `/` or `~`, no `..`), never through a symlink." (docs/dev-cycle.md:27-28)

> "Move the item to In flight, linking the brief." (SKILL.md:264)

The rule is complete for the shapes it names. It covers absolute paths, home paths, parent traversal, then the symlink walk, then glob expansion only in a checked directory. Settings rows in this repo are repo-root relative (`docs/working/feature-ideas*.md`). The brief link is the one path the cycle both writes and later reads back (In flight check 1, branch-skip in step 1, `<brief path>` in the keep-or-drop question). Its form is not specified, though. A standard Markdown link from `docs/roadmap.md` to the brief is file-relative (`working/briefs/…`). That passes the rule but resolves to nothing when read as root-relative, and a link written as `../…` would be refused. The docs' "no `..`" also differs slightly from the skill's "no `..` component": read literally, the docs version also forbids a file name such as `a..b.md`.

**Recommendation:** Say "relative to the repo root" in both places. In step 6, say the roadmap links the brief by its repo-root path (`docs/working/briefs/…`). Align the docs wording to "no `..` component".

#### 3. Keep-or-drop answer matching is literal-token and does not say where the answer is read; a non-matching answer is consumed and immediately re-asked

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:238-247` (1f36885)
**Move:** 4 (error and edge handling) / 2 (option shape against the questions grammar)
**Confidence:** Medium
**Legibility-target:** for-author

Precedent: options rendered as `**[N] <name>**` and answers recorded as `Answered YYYY-MM-DD: [N] <name> — …` used in global CLAUDE.md "Running questions document" and `docs/working/questions-archive.md` (Q-068)

**Evidence (verbatim):**
> "\"[1]\" or \"keep\" sets `Kept: <today>` (YYYY-MM-DD); \"[2]\" or \"drop\" closes the brief as in 1; any other answer changes nothing. Either way add the ID to `Applied:`, so each answer counts once."

> "file one `you: judgment` entry, \"keep or drop <brief path>?\", with options **[1] keep** and **[2] drop**, and add its ID to `Asked:` (IDs separated by \", \")."

The option shape matches the grammar, and the `[1]`/`[2]` numbering matches the `Q-NNN: [2]` answer convention. Two edges are left open.
- **Recognised forms.** The user may answer `1`, `Keep`, or the archive's usual `[1] keep — …`, and it is not clear which of these match. There is also no rule for an answer containing both tokens.
- **Location of the answer.** The grammar has no answer field. Answers are prose in the entry (`**Answered …: [3] resume**`).

The fallthrough has a cost. An unmatched answer is added to `Applied:` without setting `Kept:`, so check 3's 14-day clock still runs from the old date and a new keep-or-drop entry is filed in the same cycle. The user sees the question again right after answering it. The entry also needs a `[a-z0-9-]+` slug, which `questions.sh check` enforces, and the skill names none. That is not wrong, but a fixed one (`keep-or-drop-<brief file stem>`) would make the entries greppable.

**Recommendation:** Specify a match of the leading option token of the recorded answer, case-insensitive: `[1]`, `1` or `keep` keeps, and `[2]`, `2` or `drop` drops. When no option token matches, note it in the record without consuming the answer, or else do not re-ask in the same cycle. Optionally fix the slug shape.

#### 4. Step 1's init/archive wording leaves two cases implicit: archive missing with questions.md present, and archive after a failed init

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:101-102,125-130` (1f36885); `scripts/questions.sh` `require_files`, `cmd_init`
**Move:** 3 (contract with questions.sh)
**Confidence:** High
**Legibility-target:** for-author

**Evidence (verbatim):**
> "If the digest says the repo has no `docs/working/questions.md`, step 1 creates it." (SKILL.md:101-102)

> "If the digest said there is no `docs/working/questions.md`, run `~/.claude/scripts/questions.sh init` now, on the cycle branch; if it fails (no questions.sh, a symlinked archive) or the digest listed the archive in section 8, note it in the record. Then `~/.claude/scripts/questions.sh archive` (it also reindexes), so answered entries leave the live file."

The statements that are right: `archive` does reindex (`cmd_archive` ends with `cmd_index`), so dropping the separate `index` is correct. `init` refuses a symlinked archive (`assert_write_target`). Running init on the cycle branch also fixes the old ordering (fact-check claim 58).

Two cases remain implicit.
- **questions.md present, archive missing.** The digest prints `questions.sh open failed` with `run … init first`, not "No docs/working/questions.md". Step 1 then skips init, and `archive` dies in `require_files`. Step 3's "fix or report that first" catches it later, but only after step 1 has run an archive that was bound to fail.
- **What to do after a failure.** "Then … archive" runs even when init failed or the archive is skipped. The behaviour is safe, because questions.sh refuses the symlink or missing file, but the skill does not say to skip the archive or continue. The previous text's "carry on: step 3 reports it" was dropped.

`init` never touches an existing file ("Never touches a file that exists"), so the simplest contract is unconditional.

**Recommendation:** Always run `questions.sh init` in step 1. It is idempotent and covers the archive-missing case. Then run `archive` only if init succeeded and section 8 does not list either questions file. Restore "carry on: step 3 reports it".

#### 5. Skill step 2 still says the digest prints "every trigger"; the digest now states what it does not find

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:142-143` (1f36885) vs `scripts/dev-cycle.sh:201` (723c242)
**Move:** 3 (documentation drift between the two halves of the contract)
**Confidence:** High
**Legibility-target:** for-author

**Evidence (verbatim):**
> skill: "The digest prints every trigger in full (an output line over 4096 bytes is cut; read the record itself then)."

> digest: "Every trigger, in full: each decision record's \`## Revisit triggers\` section and each decision-log row that mentions revisiting (a trigger written elsewhere in a record is not found; …)"

The digest's new scope note is accurate. It matches `trig()` and the `grep -i 'revisit'` row filter. The skill's step 2 and Close ("Record one verdict for every trigger") still promise completeness without that caveat. An agent reading only the skill has no instruction for a trigger written outside the section.

**Recommendation:** Mirror the caveat in step 2 in one clause, for example "every trigger in a `## Revisit triggers` section or a log row mentioning revisiting". It can also say whether the cycle should look further.

#### 6. Step 0's double parenthetical attaches the claude-workflows script note to the wrong noun

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:94-96` (1f36885)
**Move:** 3 (documentation legibility of the invocation contract)
**Confidence:** High
**Legibility-target:** for-author

**Evidence (verbatim):**
> "Run `~/.claude/scripts/dev-cycle.sh` from the root of an up-to-date checkout of the default branch, before the cycle branch is created (the Rules' \"Its own branch\") (inside claude-workflows, its own `scripts/dev-cycle.sh`); never run a same-named script that belongs to another project."

The second parenthetical names which script to run, but it now follows the branch clause. It reads as if it qualified "Its own branch".

**Recommendation:** Move "(inside claude-workflows, its own `scripts/dev-cycle.sh`)" directly after `~/.claude/scripts/dev-cycle.sh`.

#### 7. New digest behaviours lack tests: the two skip checks, `Open by route: none`, and record dates

**Severity:** Minor
**Location:** `test/scripts/dev-cycle.bats` (723c242); `scripts/dev-cycle.sh:285-286,385-388`
**Move:** 3 (test drift)
**Confidence:** High
**Legibility-target:** for-author

**Evidence (verbatim):**
```
skipped docs/dev-cycle.md || true
skipdir docs/working/briefs || true
```
`grep -n 'briefs\|dev-cycle.md\|Open by route\|last committed' test/scripts/dev-cycle.bats` returns nothing. The bats diff adds only the `--since=`/`--sample` cases and the section 7 `skills/demo/tmp.md` row. The option parser is covered (`--since=` gives plain `--since needs a value` with no `line ` prefix, and `--sample` gives exit 1), and section 7's widening is covered. Section 8's listing of a symlinked `docs/dev-cycle.md` or `docs/working/briefs`, the `none` fallback, and the date map (Finding 1) have no test.

**Recommendation:** Extend the existing symlink test, `bats:151`'s loop, to `docs/dev-cycle.md` and `docs/working/briefs`. Add one assertion for `Open by route: none` with an empty questions file, and the date cases from Finding 1.

#### 8. Usage line still shows only the `=` forms and omits `--help`

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:8` (unchanged since 09f6fe7)
**Move:** 2 (CLI surface self-description)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence (verbatim):** `# Usage: scripts/dev-cycle.sh [--since=YYYY-MM-DD] [--sample=N]`

The parser accepts `--since X`, `--since=X`, `--sample N`, `--sample=N` and `-h|--help`. All were executed: rc 0 for valid input; rc 1 with plain messages for `--since`, `--since=`, `--sample`, `--sample=`, `--sample=x`, `--sample -1` and `--since --sample` (which gives `--since must be a real YYYY-MM-DD date`). `--help` prints lines 2–22, which is exactly the header comment. The usage line under-describes this, though not wrongly. This line predates the round.

**Recommendation:** Optional: `[--since[=]YYYY-MM-DD] [--sample[=]N] [-h|--help]`.

## What Looks Good

- **Option parser, every form.** `need()` gives one plain message for a missing or empty value in both the separated and `=` forms. It replaces bash's `${2:?}` diagnostics, which carried a `line N:` prefix and was inconsistent with the other errors. The `--since` value in the separated form, when it is another flag, falls through to the date validator's plain message. The help range `2,22p` now matches the header exactly. Correct and complete.
- **Help text default.** "the newest cycle-YYYY-MM-DD.md in docs/working/cycles that is a plain file and not future-dated" matches `:151-161` exactly (resolves fact-check claim 25).
- **Section 7 widening.** `^"?(skills|workflows)/` counts every file under either tree, quoted names included. It agrees with step 4b's "a skill or workflow file added or substantially changed", and the test asserts `skills/demo/tmp.md`.
- **Section 2 lead sentence** now states its own scope truthfully.
- **`Open by route: ${routes:-none}`** removes the dangling `Open by route: ` line.
- **New skip checks** list a non-plain `docs/dev-cycle.md` or `docs/working/briefs` in section 8 through the same `blocker` rule as every other input. The comment explains why the digest checks inputs it does not read.
- **briefs/ rename is complete.** `git grep 'working/handoffs'` at 1f36885 outside `docs/reviews` and the seed finds nothing. The seed's quoted text keeps `handoffs/` and says so explicitly (seed:43-45). The digest's check uses the new name.
- **ID and date formats.** `Kept: <today>` is pinned to YYYY-MM-DD. The `", "` separator is now stated for both `Asked:` and `Applied:`. The brief slug alphabet equals the questions slug alphabet.
- **Path rule order.** The lexical checks run first, then the per-component `test -L` walk, then glob expansion only inside a checked directory. That order is right, and it covers every path class the skill names (idea sources and their globs, idea log, briefs, record, roadmap, questions). Finding 2 is only about the base of "relative".
- **Seed note** accurately describes the digest as read-only (`inrepo`, `dirok`; "writes nothing", which matches the script header) and points the handoff unit at `Asked:`/`Applied:`.
- **Tests.** 23/23 pass. The test name is now "eight sections", which fixes fact-check claim 72 (Stale).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Record date "never, uncommitted" for merge-only records and `"`/`\` names | Inconsistent | `scripts/dev-cycle.sh:207-225` | High |
| 2 | Path rule's "relative" has no base; brief-link form unspecified | Minor | `SKILL.md:61-64,264`; `docs/dev-cycle.md:27-28` | Medium |
| 3 | Keep-or-drop answer matching literal; unmatched answer re-asked at once | Minor | `SKILL.md:238-247` | Medium |
| 4 | init only on "no questions.md"; archive-missing and after-failure cases implicit | Minor | `SKILL.md:101-102,125-130` | High |
| 5 | Skill step 2 says "every trigger"; digest now states its limits | Minor | `SKILL.md:142-143` | High |
| 6 | Step 0 parenthetical misplaced | Minor | `SKILL.md:94-96` | High |
| 7 | No tests for new skip checks, `none`, record dates | Minor | `test/scripts/dev-cycle.bats` | High |
| 8 | Usage line omits space forms and `--help` | Informational | `scripts/dev-cycle.sh:8` | High |

## Overall Assessment

The fix round achieves its interface goals. The CLI's error surface is now uniform and plain. The help text matches the code. Section 7, the section 2 wording and the `none` value are consistent. The briefs/ rename is complete across the skill, digest and seed. The keep-or-drop question now follows the questions grammar's `[N]` option shape. The exception is the record-date map. It does not reproduce the per-file lookup it replaced: committed records with a merge-only history, or a `"` or `\` in the name, print as "never, uncommitted". The preconditions are rare, but it is a false statement in the printed contract, the fix is one line (fall back on any miss), and nothing tests the date. That is the single Inconsistent finding. The six Minor findings are wording and coverage gaps that can be fixed in place. None indicates that the author missed the conventions. There is no Breaking finding: no existing consumer's invocation or parse of the digest stops working.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/api-consistency-review-2026-10-02-digest-pass17.md`, with first line `Commit: 723c242 (A) / 1f36885 (B)`. It follows the api-consistency-reviewer structure: header, Baseline Conventions, Name-Pattern Audit, Findings, What Looks Good, Summary Table and Overall Assessment. Each finding carries Severity, Location, Evidence (verbatim), Confidence and Legibility-target. It answers the brief's claim-1 question ("the date map gives exactly what per-file `git log -1 -- f` gave"): no, for merge-only and `"`/`\` names, as Finding 1 shows. Scratch work is confined to `scratchpad/api17/`, and nothing was committed.
