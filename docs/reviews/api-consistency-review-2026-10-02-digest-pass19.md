Commit: 1b0c4ff (A) / 462e561 (B)

# API Consistency Review — dev-cycle pass 19 (pass-18 fix round)

**Scope:** Partial. A: `git diff 36417f5..1b0c4ff -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (worktree `/workspace/.claude/wt-digest`). B: `git diff db24c74..462e561 -- skills/dev-cycle/SKILL.md docs/dev-cycle.md` (worktree `/workspace/.claude/wt-devcycle`). Everything else is context only.
**Date:** 2026-10-02
**Based on:** `docs/reviews/code-fact-check-report-digest-pass18.md` (loop pass 18 k=1 fact-check; Stage-1 context per the shared brief), commit messages of 1b0c4ff and 462e561.
**Replication:** k=1 (loop pass)

Execution (scratch under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/api19/`, throwaway repos under `mktemp -d` there; every process under `timeout`; nothing written to either worktree except this report):

- E1 `timeout 600 bats test/scripts/dev-cycle.bats` in wt-digest at 1b0c4ff: 24/24 ok.
- E2 `git ls-files --error-unmatch -- <p>` in a throwaway repo for a directory, a parent directory, an unexpanded glob, an untracked file, a case variant, an index-removed file and a worktree-deleted tracked file (exits `0 0 0 1 1 1 0`).
- E3 1b0c4ff's `scripts/dev-cycle.sh --since=2000-01-01` on a throwaway repo where `001-a"b.md` and `002-plain.md` were committed 2026-01-05, then `git rm --cached` both (commit 2026-01-06), files left on disk.
- E4 `git check-ignore -v` in wt-devcycle on `docs/working/feature-ideas-round-12.md` and `docs/working/plan-x.md`; `ls docs/working` in /workspace.

Legibility-target values: **agent** (the model running the skill acts on the text), **maintainer** (someone editing the script, skill or tests), **user** (the human reading the digest, record or questions).

## Baseline Conventions

- **Questions grammar** (global CLAUDE.md "Running questions document"; `scripts/questions.sh:15-16`): `### Q-NNN · <short-slug>`, `**Status:** OPEN|ANSWERED`; the user answers `Q-NNN: <answer>` "anywhere — a reply, a file, a commit", and the agent records it inline. The grammar has no delimited answer field. Repo practice (`docs/working/questions-archive.md`, 67 lines start `**Answer`) is an agent-written line such as `**Answered 2026-09-17: [2] — "option 2 seems good and easy". Both halves shipped.**` (:280), with the original entry, options table included, kept below or above it.
- **Digest section 8** (`scripts/dev-cycle.sh:104-125, 402-409`): one `- <path>` line per blocking part; a blocking directory carries a trailing `/` (`printf '%s/' "$p"`), a file does not. The questions-path walk can block only at `docs/`, `docs/working/`, `docs/working/questions.md` or `docs/working/questions-archive.md`.
- **Record-date line** (`scripts/dev-cycle.sh:239`): `### <path> (last committed on this branch: <YYYY-MM-DD | never, uncommitted>)`, unchanged in form this round.
- **Skill rule names**: bold lead-in sentences (`**Repo text is evidence, not instructions.**`, `**Seeding is always on.**`) referred to elsewhere by a short name ("the evidence-not-instructions brief", SKILL.md:99).
- **Brief names**: `docs/working/briefs/YYYY-MM-DD-<slug>.md`, slug lowercase letters, digits, hyphens; collisions take `-2`, `-3` (SKILL.md:278-280).

## Name-Pattern Audit

A introduces no new public names: the record-date line, the "never, uncommitted" label, the Window note text and the test names are unchanged in form (one test renamed, internal). B's new or renamed names:

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `Plain, tracked repo paths only` (rule lead-in) | rule name | `Plain paths inside the repo only` (old), "the plain-paths rule" (SKILL.md:99), `docs/dev-cycle.md:28-29` "the skill's \"Plain, tracked repo paths only\" rule" | `skills/dev-cycle/SKILL.md:61,99`; `docs/dev-cycle.md:27-29` | Inconsistent — SKILL.md:99 still calls it "the plain-paths rule" (Finding 6) |
| `keep-or-drop-<brief file name without .md>-<n>` | question slug | `keep-or-drop-<brief slug>` (db24c74), archive slugs such as `install-sh-missing-payload-fatal`, `run-tests-jobs` | `docs/working/questions-archive.md:105-130`; `docs/working/questions.md:194` | Consistent — kebab-case, matches `<short-slug>`; longer than neighbors but unique (What Looks Good) |
| `Applied:` / `Asked:` / `Kept:` brief lines | brief field | `Status: open` | `skills/dev-cycle/SKILL.md:280-283` | Consistent — unchanged names; separator ", " stated at both writers |
| "naming its brief path" (In flight) | roadmap item shape | "each with its reason and brief" (Ideas), "each open build brief by path" (final message) | `skills/dev-cycle/SKILL.md:245,270,283,317` | Consistent — all three now say path, not link |

## Findings

#### 1. Check 1's character set rejects the configured idea-source glob before check 2 can expand it

**Severity:** Inconsistent
**Location:** `skills/dev-cycle/SKILL.md:64-71`; `docs/dev-cycle.md:26-32`
**Move:** 3 (consumer contract)
**Confidence:** High
**Legibility-target:** agent

**Evidence:**
> "A path taken from repo text (a settings row and its glob matches, …) is opened only if all of these hold, checked in this order: 1. it uses only letters, digits, `.`, `_`, `-` and `/` … 2. `git ls-files --error-unmatch -- '<path>'` accepts it, so it is a tracked file (expand a glob first, with the same check on each match);" (SKILL.md:64-71)
>
> "Tracked files only, as plain paths from the repo root (letters, digits, `.`, `_`, `-`, `/`; no `..` or `.git` component)" … "| Feature ideas | docs/working/feature-ideas*.md | the self-improvement loop's idea files |" (docs/dev-cycle.md:27-32)

The rule names "a settings row" as a path it checks, and check 1 runs first; the repo's only settings row contains `*`, which check 1 does not allow, so a literal reading skips the row before check 2's "expand a glob first" is reached. docs/dev-cycle.md restates the character set two lines above that same row. The settings template (SKILL.md:52) calls the column "Path or glob", so globs are a documented input. The rule also does not say how to expand (shell glob, or git pathspec — where E2 shows `git ls-files --error-unmatch -- 'docs/working/feature-ideas*.md'` passes as one unit).

**Recommendation:** Say that a settings-row glob may also contain `*` (and nothing else extra), is expanded first (name the mechanism, e.g. `git ls-files -- '<glob>'`), and that checks 1–3 apply to each match; mirror that in docs/dev-cycle.md:27-28.

#### 2. Tracked-only skips the files the idea-source row exists for, and most plans step 4 reads

**Severity:** Inconsistent
**Location:** `skills/dev-cycle/SKILL.md:70-71`; `docs/dev-cycle.md:32`; `.gitignore:26-28`
**Move:** 3 (consumer contract)
**Confidence:** High (the files are ignored); Medium (on how often step 4 needs an ignored plan)
**Legibility-target:** agent, user

**Evidence:**
> "| Feature ideas | docs/working/feature-ideas*.md | the self-improvement loop's idea files |" (docs/dev-cycle.md:32)
>
> `.gitignore:28:docs/working/feature-ideas-round-*.md` and `.gitignore:26:docs/working/plan-*.md` (E4, `git check-ignore -v`)
>
> 462e561 message: "Notes: \"tracked only\" means an untracked idea source is skipped; the default source here (docs/working/feature-ideas.md) is tracked."

The row's Format column names "the self-improvement loop's idea files", which are the per-round `feature-ideas-round-*.md` files the glob was written to match; they are gitignored, so check 2 skips every one and only `feature-ideas.md` is read. The commit note covers `feature-ideas.md` only. Step 4 reads the "plan" a merge rests on (SKILL.md:183-184); `docs/working/plan-*.md` and `research-*.md` are ignored too (some are force-added: `plan-q093-…`, `plan-q094-…` are tracked; `plan-skill-fixtures*.md` in /workspace is not). Each skip is listed under `## Skipped inputs`, so it is visible, not silent, but it recurs every cycle and the row's documented purpose is not met.

**Recommendation:** Decide which the row means: either narrow it to `docs/working/feature-ideas.md` and reword its Format, or state in docs/dev-cycle.md that round files are deliberately not read (ignored, local-only). For step 4, say an ignored plan is skipped and the claim is checked from the commit message or log row instead.

#### 3. "2 more weeks" is applied as drop

**Severity:** Inconsistent
**Location:** `skills/dev-cycle/SKILL.md:253-259`
**Move:** 3 (consumer contract), against the questions grammar
**Confidence:** High (the mechanics); Medium (how often users answer this way)
**Legibility-target:** agent, user

**Evidence:**
> "read the option the user chose: the first `[1]` or `[2]` in their answer (as in `Q-NNN: [1]`), or, if there is none, its first word when that is exactly `1`, `keep`, `2` or `drop` (any case). `[1]`, `1` or `keep` sets `Kept: <today>` (YYYY-MM-DD); `[2]`, `2` or `drop` closes the brief as in 1;" (truncated; :257-259 continue with the unrecognized case and `Applied:`, read)

On the three realistic answers the brief names: `Q-012: [2]` → drop (correct); `[1] keep, it's close` → keep (correct); `2 more weeks` → no `[n]`, first word exactly `2` → **drop**, the opposite of what the user means. The grammar invites free-text answers ("`Q-NNN: <answer>` anywhere"), so a bare leading number is not reliably an option index. The consequence is a closed brief moved to Ideas, recoverable by hand but against the user's choice.

**Recommendation:** Accept a bare `1`/`2`/`keep`/`drop` only when it is the whole answer (ignoring trailing punctuation); anything longer without `[n]` is unrecognized, which already re-asks via item 3.

#### 4. "Their answer" has no boundary in the grammar; the recorded entry also holds the options table

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:253-255`
**Move:** 7 (asymmetry: writer vs reader of the answer)
**Confidence:** Medium
**Legibility-target:** agent

**Evidence:**
> "read the option the user chose: the first `[1]` or `[2]` in their answer" (SKILL.md:254)
>
> "asking \"keep or drop <brief path>?\" with options **[1] keep** and **[2] drop**" (SKILL.md:264-265)
>
> Recorded practice: "**Answered 2026-09-17: [2] — \"option 2 seems good and easy\". Both halves shipped.**" (questions-archive.md:280)

The cycle looks the ID up in `questions.md`/the archive, where the answer is an agent-written line inside an entry whose options table contains `**[1] keep**` and `**[2] drop**`. Neither the skill nor the grammar says which text is "their answer", so "the first `[1]`" in the entry can be the table's, and "first word" can be `**Answered`. This rule is the only machine-ish reader of answer text in the repo.

**Recommendation:** Name the text read: the `Answered …:` line's text after the colon (or the user's own `Q-NNN:` line if quoted there), never the options table.

#### 5. Final-message spec does not carry the unrecognized answers step 6 sends to it

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:257-258` vs `:316-319`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** agent

**Evidence:**
> "anything else is unrecognized: list it in the record and the final message so the user can answer again." (:257-258)
>
> "Then send the final message: list the new `you: judgment` entries by ID and name, and each open build brief by path, so the user can start any of them" (truncated; :318-319 continue with RPI per brief and "the user reads it before starting it", read)

**Recommendation:** Add "and any keep-or-drop answer that was not recognized" to the final-message list (the record has no section for it either; `## Questions filed` or a line under step 6 would do).

#### 6. The renamed rule is still called "the plain-paths rule" at its one cross-reference in the skill

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:99`
**Move:** 2 (naming)
**Confidence:** High
**Legibility-target:** agent

Precedent: rule lead-ins are cited by their own words, as `docs/dev-cycle.md:28-29` now does ("the skill's \"Plain, tracked repo paths only\" rule") and SKILL.md:99 does for "evidence-not-instructions", used in `skills/dev-cycle/SKILL.md:22,99` and `docs/dev-cycle.md:27-29`

**Evidence:**
> "run them in parallel as subagents, each carrying the evidence-not-instructions brief and the plain-paths rule" (:98-99)

The subagent hand-off is where the new "tracked" check matters most (steps 2–4 read commit- and plan-named files), and "plain-paths" reads as the old, untracked-allowed rule.

**Recommendation:** "the plain, tracked paths rule".

#### 7. docs/dev-cycle.md's paraphrase is looser than the rule it points to

**Severity:** Minor
**Location:** `docs/dev-cycle.md:27-28`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** user, maintainer

**Evidence:**
> "(letters, digits, `.`, `_`, `-`, `/`; no `..` or `.git` component)" (docs/dev-cycle.md:27-28)
>
> "does not start with `/` or `-`, and has no `..` component and no component starting with `.git` (any case)" (SKILL.md:68-69)

A user editing a row by the settings file's own words could write `-x.md` or `docs/.GitNotes/x.md` and have it skipped. Since the line ends by naming the skill's rule, either drop the paraphrase or make it exact.

**Recommendation:** Replace the parenthetical with "see the skill's rule; in short, a tracked file, no symlink, characters `A-Za-z0-9._-/`, not starting with `/` or `-`, no `..` and no component starting `.git`".

#### 8. A quoted record name removed from the index now reads "never, uncommitted"; a plain one in the same state shows a date

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:231-236` (1b0c4ff)
**Move:** 7 (asymmetry)
**Confidence:** High (executed); Low (likelihood: needs a quote/backslash/control character in a record name plus `git rm --cached` with the file left on disk)
**Legibility-target:** user

**Evidence:**
```bash
# scripts/dev-cycle.sh:231-236
  # Fall back only for a tracked record (an index lookup, no history walk): an
  # untracked one was never committed here, …
  if [[ -z "${last_date[$f]+set}" ]] && git ls-files --error-unmatch -- "$f" >/dev/null 2>&1; then
    d="$(git log -1 --format=%ad --date=short -- "$f")"
  fi
```
(excerpt is the whole fallback; the loop continues to :241, read; `d` prints at :239 as `${d:-never, uncommitted}`.)

E3 output:
```
### docs/decisions/001-a"b.md (last committed on this branch: never, uncommitted)
### docs/decisions/002-plain.md (last committed on this branch: 2026-01-06)
```
Both were committed; the comment's "an untracked one was never committed here" is not true for an index-removed file, and the two names get different answers for the same state (at 36417f5 both got 2026-01-06). E2 confirms `--error-unmatch` fails for an index-removed path. The common cases are right: a quoted tracked name gets its date and an untracked new record never walks history (test 11, E1).

**Recommendation:** Accept it and reword the comment to "an untracked one (new, or removed from the index) is shown as uncommitted", or print "not tracked" instead of "never" for that case. No code change is needed for the performance goal.

#### 9. Check 2 accepts directories and pathspec globs, so "so it is a tracked file" overstates it

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:70-71`
**Move:** 3
**Confidence:** High (executed)
**Legibility-target:** agent

**Evidence:**
> "`git ls-files --error-unmatch -- '<path>'` accepts it, so it is a tracked file" (:70)

E2: `docs` → 0, `docs/working` → 0, `'docs/working/feature-ideas*.md'` → 0, a tracked file deleted from the worktree → 0. With check 1 forbidding `*` and the cycle opening files, the practical gap is a directory name or a worktree-deleted file passing; both fail harmlessly at open. Without `GIT_LITERAL_PATHSPECS=1` (the digest sets it, `scripts/dev-cycle.sh:128`; the skill does not) other pathspec magic is also interpreted, though check 1's character set excludes `:` and `*`.

**Recommendation:** "…accepts it and `test -f '<path>'` holds", or compare `git ls-files -- '<path>'` output to the path itself.

#### 10. Step 0 promises step 1 will create questions.md in a case where step 1 now skips init

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:114-115` vs `:138-139`; `scripts/dev-cycle.sh:276-281`
**Move:** 3
**Confidence:** High (by reading); Low (likelihood)
**Legibility-target:** agent

**Evidence:**
> "If the digest says the repo has no `docs/working/questions.md`, step 1 creates it." (:114-115)
>
> "If the digest's section 8 lists `docs/`, `docs/working/` or a questions file, skip the next two commands" (:138-139)

With `questions.md` absent and `questions-archive.md` a symlink, the digest prints "No docs/working/questions.md in this repo." (:280-281, since the archive check only sets `qa_at`) and lists the archive in section 8. The skip is the safe reading and wins on precedence; step 0's sentence just needs "unless step 1 skips init".

**Recommendation:** Add "(unless section 8 lists a questions path; step 1)" to :114-115.

#### 11. Smaller fit notes on the path rule

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:62-63, 68-69, 76-78`
**Move:** 3
**Confidence:** Medium
**Legibility-target:** agent

**Evidence:**
> "Files the cycle creates (the record, a new brief, the idea log) use those fixed names, under directories that pass check 3." (:76-78)
>
> "their own scratch output (the health-check log, the kept digest) goes to the usual temp directory" (:62-63)

- The fixed-name list omits `docs/roadmap.md` (created from the template, step 6) and `docs/working/questions.md` (questions.sh init). Both are fixed names, so the omission is wording only.
- "Any case `.git` prefix" also bars `.gitignore` and `.gitattributes` (both tracked, `git ls-files`), so step 4 cannot read them when a merge's claim rests on them. That looks deliberate; a sentence saying so would stop an agent from treating the skip as a finding.
- "the usual temp directory" is undefined in the skill; the global instructions say `$TMPDIR` or the session scratchpad.
- Ascending ID order (:253) does not say what happens to a later `keep` after an earlier `drop` closed the brief. Step 3 asks again only once every Asked ID is answered, so two pending answers need a lapse; low likelihood.

**Recommendation:** Name roadmap.md and questions.md in the fixed-name list; one clause each on `.git*` and the temp directory; "stop at the first answer that closes the brief".

## What Looks Good

- **Step 1's skip condition matches what the digest prints, and covers every case.** Section 8 prints blocking directories with a trailing slash (`printf '%s/'`, `scripts/dev-cycle.sh:110,113`), exactly as the skill writes `docs/` and `docs/working/`, and a blocked file as its bare path. The blocker walk for either questions file can only stop at `docs/`, `docs/working/` or the file itself, so "`docs/`, `docs/working/` or a questions file" is complete. Correct.
- **The keep-or-drop slug is unique.** `keep-or-drop-<stem>-<n>` with an integer `n` cannot collide across briefs: `X-n == Y-m` with `X ≠ Y` would need the extra text to be all digits with no hyphen, but brief stems differ by a `-` suffix. It is kebab-case like every archived slug (`install-sh-missing-payload-fatal`, `run-tests-jobs`).
- **Unrecognized answers re-ask instead of sticking.** Putting every read ID on `Applied:` keeps the answer from being re-read forever. Because `Kept:` does not move, item 3's 14-day condition already holds, so the same cycle files the next `-<n+1>` entry. That is what "so the user can answer again" needs.
- **Brief references are one shape everywhere.** In flight "naming its brief path", the build-briefs step "naming the brief's path", Ideas "with its reason and brief", the final message "by path", and the path rule's "written in the roadmap as that repo-root path in backticks" all agree now.
- **The ordered path checks close the classes they name.** The character set comes first, so single-quoting is always safe (no `'` can appear), case variants of `.git` and leading `-` option injection are excluded, and tracking blocks untracked local secrets. Running the symlink check after `ls-files` is the right order, because a tracked file replaced by a symlink in the worktree still fails check 3.
- **A: the tracked-only fallback keeps the date contract and the line format.** A quoted tracked name gets its per-file date, an untracked new record prints "never, uncommitted" without a history walk, and test 11 covers both (E1, 24/24). The rewritten date-map comment now states a general rule ("in either direction … always a real commit on this branch that touched the record"), consistent with fact-check 6a/6b's executed scenarios. The skipped-record Window note now applies the same `date -d` check as the main branch at :160, so the two Window notes cannot disagree about what counts as a date.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Check 1 rejects the configured glob row before check 2 expands it | Inconsistent | `skills/dev-cycle/SKILL.md:64-71`; `docs/dev-cycle.md:26-32` | High |
| 2 | Tracked-only skips the round idea files the row is for, and ignored plans | Inconsistent | `skills/dev-cycle/SKILL.md:70-71`; `docs/dev-cycle.md:32`; `.gitignore:26-28` | High / Medium |
| 3 | "2 more weeks" parses as drop | Inconsistent | `skills/dev-cycle/SKILL.md:253-259` | High / Medium |
| 4 | "Their answer" undelimited; options table can supply the first `[1]` | Minor | `skills/dev-cycle/SKILL.md:253-255` | Medium |
| 5 | Final message spec omits unrecognized answers | Minor | `skills/dev-cycle/SKILL.md:257-258, 316-319` | High |
| 6 | "the plain-paths rule" after the rename | Minor | `skills/dev-cycle/SKILL.md:99` | High |
| 7 | docs/dev-cycle.md paraphrase looser than the rule | Minor | `docs/dev-cycle.md:27-28` | High |
| 8 | Quoted index-removed record says "never"; plain one shows a date | Minor | `scripts/dev-cycle.sh:231-236` | High / Low |
| 9 | Check 2 accepts directories and globs | Informational | `skills/dev-cycle/SKILL.md:70-71` | High |
| 10 | Step 0 "step 1 creates it" vs step 1 skip | Informational | `skills/dev-cycle/SKILL.md:114-115, 138-139` | High / Low |
| 11 | Fixed-name list, `.git*`, temp dir, order after drop | Informational | `skills/dev-cycle/SKILL.md:62-63, 68-69, 76-78, 253` | Medium |

## Overall Assessment

A is consistent. The tracked-only fallback keeps the record-date contract and its output format; its one asymmetry (Finding 8) needs an unusual precondition and only affects a label. B's step-1 skip, slug, `Applied:` semantics and brief-path naming now agree with the digest and with each other. The new mechanical path rule has one ordering defect: check 1 rejects the repo's only settings row as written (Finding 1). It also has one fit gap: the tracked-only check excludes the gitignored round idea files the row was written for, and most plan files (Finding 2). The answer-parsing fallback misreads a natural free-text answer as its opposite (Finding 3). All three can be fixed in place with a sentence each and need no rethink. The consumer impact is on the agent running the cycle and on the user's keep-or-drop choices, not on the digest's output. None is Breaking; the round is not clean at the Inconsistent tier.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/api-consistency-review-2026-10-02-digest-pass19.md` with first line `Commit: 1b0c4ff (A) / 462e561 (B)`. It follows the skill's structure: header, Baseline Conventions, Name-Pattern Audit, Findings with Severity, Location, Evidence (verbatim), Confidence and Legibility-target, What Looks Good, Summary Table and Overall Assessment. It covers the four areas asked: the digest↔skill contract, keep-or-drop entry and answer parsing against the questions grammar, the path rule's fit with what the cycle reads and writes, and SKILL.md/docs consistency. It was not committed.
