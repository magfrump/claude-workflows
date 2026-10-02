Commit: 6f3d55e (A) / 2e65ad5 (B)

# API Consistency Review — dev-cycle pass 37 (full-review-1 fix round)

**Scope:** A: `git diff 3d580cd..6f3d55e -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (wt-digest); B: `git diff 2fd9401..2e65ad5 -- skills/dev-cycle/SKILL.md` (wt-devcycle, merge 79f50aa). Partial scope: everything else is context only.
**Date:** 2026-10-02
**Based on:** shared brief `digest-pass37-brief-dc1aa358.md`; Stage-1 context `wt-devcycle/docs/reviews/code-fact-check-report-devcycle-fullreview-2026-10-02.md`.

All probes ran as single `set -eu` scripts in their own `mktemp -d` dirs under `scratchpad/api37/`, with `$PWD` checked before every write, every process under `timeout`. Real-repo probes ran on clones in the temp dir. Nothing was written to either worktree except this report.

## Baseline Conventions

- **Check-mode output:** one line per argument, `ok <path> [fields]` or `skip <arg>: <reason>`. A reason is a lower-case clause, and it names the cause the caller has to fix (`reached through a symlink, or not a regular file`, `not an allowed path form`, `not a build brief (...)`). The help gives each mode's `ok` shape and its notable skip reasons. The skill quotes the same lists word for word.
- **Names:** globals are UPPER_SNAKE (`MAIN_SHA`, `SKIP_AT`, `SKIPPED`, `NAMECHARS`, `INSTRUCTION_FILE`). Helpers are lower_snake verbs or predicates (`inrepo`, `writable`, `pathform`, `isbrief`, `skipped`). Per-mode functions are `check_<mode>`.
- **Skill vs help:** the skill restates each mode's accepted set in nearly the help's words. A help change is expected to land in the skill as well, and both fix-scope lists match at A/B (`dev-cycle.sh:50-55`, `SKILL.md:72-76`).
- **Dates:** the window uses the committer date (`%cs`), and so do `--check-branch` (`%cs`) and, after this round, the "last committed" dates (`%cd --date=short`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `imported_names` | function (internal helper) | `inrepo`, `writable`, `skipped`, `matches` | `scripts/dev-cycle.sh:179-257` | Consistent: lower_snake |
| `IMPORTED`, `IMPORTED_DONE` | global | `SKIPPED`/`SKIP_AT`, `MAIN`/`MAIN_SHA`/`MAIN_BY_NAME` | `scripts/dev-cycle.sh:164,545` | Consistent: UPPER_SNAKE with a shared prefix. The `_DONE` memo flag is the first of its kind in this script, and it is internal. |
| `skip <path>: an instruction file imports a file named <base> with @, so it is read as instructions; file it instead` | `--check-fix` skip reason | the generic `--check-fix` reason (`...; file it instead`) | `scripts/dev-cycle.sh:438` | Consistent: same "file it instead" ending, and it names the cause |
| `skip <path>: not a regular file on the default branch` | `--check-brief` skip reason | `reached through a symlink, or not a regular file` | `scripts/dev-cycle.sh:262,354` | Consistent: same wording, with the place added |
| "check 3" | skill cross-reference | "check 1" (`SKILL.md:91,274`) | `skills/dev-cycle/SKILL.md:274-305` | Consistent: In flight's numbered checks are called "check N". The Flow's steps are still "step N" (`steps 1, 3, 4`, line 72). |

## Findings

#### 1. The generic `--check-fix` skip reason still says "dot-directories" for a dotfile

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:438` (A, 6f3d55e). Help: `scripts/dev-cycle.sh:51-53`. Skill: `skills/dev-cycle/SKILL.md:74-75` (B)
**Move:** 3 (documentation drift) / 4 (error message consistency)
**Confidence:** High
**Legibility-target:** the cycle record's `## Skipped inputs` (the reason is copied there word for word) and the user reading it.

Precedent: skip reasons that name the cause the caller can act on, used in `scripts/dev-cycle.sh:262,354,359` (`reached through a symlink, or not a regular file`, `not a regular file on the default branch`)

**Evidence (verbatim):** Help after this round: `or dotfile, an instruction file, or a file an instruction file`. Skill: `` `docs/decisions/`, `docs/dev-cycle.md`, a dot-directory or dotfile, an instruction file, or a ``. Code, unchanged at line 438: `echo "skip $a: in-cycle fixes edit only tracked .md documentation under docs/ (not working/, human-author/, reviews/, decisions/, dev-cycle.md, dot-directories or instruction files) and README.md; file it instead"`. Probe (temp repo, `docs/.hid.md` tracked): `skip docs/.hid.md: in-cycle fixes edit only tracked .md documentation under docs/ (not working/, human-author/, reviews/, decisions/, dev-cycle.md, dot-directories or instruction files) and README.md; file it instead`.

This round added "dotfile" to the help and the skill, but the printed reason was not updated. A dotfile skip therefore records a reason that does not cover the file. The test (`"$a" == */.*`) has always caught dotfiles too, so only the wording lags. Nothing breaks: the file is still refused. The cost is a misleading record line. "Compared ignoring case" also appears in the help but not in the reason. That gap matters less, because `DOCS/WORKING/x.md` and `docs/working/x.md` both fall under the reason's own list.

**Recommendation:** Change the reason's parenthetical to "dot-directories or dotfiles". If the reason should track the help, also add "(any case)".

#### 2. Help and skill say "a file an instruction file imports", but only tracked instruction files are scanned

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:416-426` (`imported_names`, `done < <(git ls-files -z)`); help `scripts/dev-cycle.sh:53-54`; skill `skills/dev-cycle/SKILL.md:74-75`
**Move:** 3 (consumer contract: the documented accepted set is wider than the code's)
**Confidence:** High on the behaviour. Medium on the precondition being common.
**Legibility-target:** the cycle agent, which reads the skill's list as the complete refusal set.

**Evidence (verbatim):** The code comment, line 413, is accurate: `# Basenames, lower-cased, that a tracked instruction file pulls in with an @`. The help is not: `or dotfile, an instruction file, or a file an instruction file` / `imports with @; compared ignoring case)`. The skill matches the help: `` file an instruction file imports with `@`; compared ignoring case) ``. The loop reads only `git ls-files -z`. Probe: in a temp repo, a gitignored `AGENTS.local.md` holding `@docs/u.md` leaves `docs/u.md` editable: `ok docs/u.md`. The tracked `AGENTS.md`'s imports are refused.

The instruction-file regex's own comment (line 409) names `CLAUDE.local.md` as an instruction file. By convention that file is gitignored, so the import scan misses exactly the local file the regex lists. Precondition: a project with an untracked `CLAUDE.local.md` or `AGENTS.local.md` that `@`-imports a file under `docs/`. With it, `--check-fix` prints `ok` for a file Claude Code reads as instructions, and the skill's wording says this cannot happen. Whether to scan untracked instruction files is a security or design call. My finding is the gap between the documented set and the code.

**Recommendation:** Either say "a file a tracked instruction file imports" in both the help and the skill, or extend the scan to the untracked `*.local.md` instruction files in the work tree. Keep the help and the skill in step either way.

#### 3. The `check_fix` block comment lags the help it summarizes

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:404-408`
**Move:** 3 (documentation drift, maintainer-facing)
**Confidence:** High
**Legibility-target:** the next maintainer editing `check_fix`.

**Evidence (verbatim):** `# An in-cycle fix edits documentation only: a tracked .md file under docs/,` … `# and decisions/ (records), the settings file, any dot-directory, and any` … `# instruction file (CLAUDE.md, AGENT(S).md, GEMINI.md, SKILL.md, any case); or` … `# README.md. Anything else is filed.` The comment leaves out dotfiles and `@`-imported files, and it says "any case" only of instruction files. The help (lines 51-54) and the code (`lp`, lines 432-439) now cover all three.

**Recommendation:** Bring the comment's list into line with the help in the same edit as finding 1.

#### 4. `@`-import coverage: transitive imports and tokens with trailing punctuation are not refused

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:420-425`
**Move:** 3 (contract scope)
**Confidence:** High on the behaviour. Low on whether Claude Code follows a token with trailing punctuation (not verified: no egress).
**Legibility-target:** the security critic and the author deciding the import rule's scope.

**Evidence (verbatim):** The grep is `grep -oE '(^|[[:space:](])@[^[:space:]`)]+'`. Probe results, temp repo, `AGENTS.md` lines → `--check-fix` output:
- `see @docs/e.md.` → `ok docs/e.md`
- `see @docs/f.md, too` → `ok docs/f.md`
- `**@docs/g.md**` → `ok docs/g.md`
- a tracked `docs/Imp.md` (itself imported) holding `@docs/v.md` → `ok docs/v.md`

Correctly refused: `@docs/a.md`, `@./docs/b.md` (as `B.md`), `@~/c.md`, `(@docs/d.md)`, `Docs/a.md`. A `` `@docs/t.md` `` code span is correctly ignored (`ok`).

The help's literal claim ("a file an instruction file imports") is direct imports only, so these cases are not contradicted by the help. The skip reason's rationale ("so it is read as instructions") does apply to transitive imports, though, because Claude Code follows those recursively. The trailing-punctuation cases depend on how Claude Code tokenizes, which I could not check. I am recording this as scope, not drift, and deferring the exposure judgement to the security critic. On the real repo (clone at 79f50aa) the only token found is `skills/dependency-upgrade/SKILL.md: @org/migrate"}`, which matches no file, and `--check-fix` refuses no real `docs/` file for the import reason.

**Recommendation:** If the import rule should match Claude Code's reading, strip trailing `.,;:!?*` from tokens and follow imports from imported files one level or more. Otherwise, add "direct" to the help.

#### 5. `--check-brief`: a gitlink at a brief path reads `ok … new`, while a symlink there is skipped

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:355-360`
**Move:** 7 (asymmetry)
**Confidence:** High
**Legibility-target:** the maintainer reading the new comment.

**Evidence (verbatim):** The comment says `# Only a regular file counts: a symlink's blob is its target text, not a brief.` The mode check runs only after `if [[ "$(git cat-file -t "$MAIN_SHA:$a" 2>/dev/null || true)" != blob ]]; then echo "ok $a new"; return; fi`. Probe: with mode 160000 committed at `docs/working/briefs/2026-01-01-gl.md` on main and a plain file in the work tree, the output is `ok docs/working/briefs/2026-01-01-gl.md new`. A symlink committed there gives `skip docs/working/briefs/2026-01-01-link.md: not a regular file on the default branch`. An executable (100755) brief gives `ok … open <commit>`, as designed.

The help (`"ok <path> new" when the default branch has no file there`) literally covers a gitlink, since a gitlink is not a file. So the output contradicts neither the help nor the skill. It is only asymmetric with the symlink case. The precondition (a gitlink committed at a brief path) is contrived.

**Recommendation:** No change needed. If symmetry is wanted, run the `ls-tree` mode check before the blob test, so any non-regular entry gets the new skip.

#### 6. `ANSWER_AWK`: `*` and `_` are handled asymmetrically, and a bare `**Answer**:` label is not a label

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:470-478` (`option`), `:500-513`; comment `:461-468`
**Move:** 7 (asymmetry) / 3 (docs)
**Confidence:** High
**Legibility-target:** whoever records answers by hand.

**Evidence (verbatim), probe results at 6f3d55e:**
- `**Answer:** *keep*` → `keep`
- `**Answer:** _keep_` → `unrecognized`
- `**Answer:** keep*not` → `keep`
- `**Answer**: keep` → `unrecognized`
- `**Answer (x)**: keep` → `keep`

The comment says `(a word must be followed by the end, punctuation or a dash)`, and the code now treats `*` as punctuation (`r ~ /^[.,;:!)*]/`). A bare `**Answer**:` fails `low !~ /^\*\*answer(:|ed| \()/`. That matches the documented label set (`"**Answer:", "**Answer (" or "**Answered"`), so it is consistent with the docs. It is still an odd gap next to `**Answer (x)**:`. Every one of these cases fails safe (`unrecognized` means the user is asked again), except `keep*not`, which is harmless in practice. No real answer line has these shapes (see What Looks Good).

**Recommendation:** None required. Optionally write "punctuation (including `*`)" in the comment.

## What Looks Good

- **`--check-answer` against the real answer lines.** `--check-answer` gave identical output at 3d580cd and 6f3d55e for every ID in three real questions-file pairs:
  - `/workspace`: 101 IDs (23 keep, 19 drop, 3 done, 12 open, 42 unrecognized)
  - wt-digest: 100 IDs
  - wt-devcycle: 105 IDs

  No real ID changed, as the brief states. The three shapes the brief names read correctly at 6f3d55e:
  - `**Answer (d)**: **[2]**` → `drop` (was `unrecognized`)
  - `**Answer (d):** [2]` → `drop`
  - `**Answer:** **keep**.` → `keep` (was `unrecognized`)

  `**Answer (2026-10-01)**: drop **because** reasons` changed from `drop` to `unrecognized`. That follows the documented leading-token rule: a word followed by more text is a hedge. The comment's new clause ("and then ends at the bold's close if it opened inside the bold") matches the code's `inbold` test exactly. These rules are correct and complete for the documented label set.
- **The new skip reasons parallel the existing ones.** `not a regular file on the default branch` echoes `reached through a symlink, or not a regular file`. The import reason ends in `file it instead`, like the generic reason, and it prints the caller's own spelling (`$base`) while comparing lower-cased.
- **The help range is right.** `sed -n '2,77p'` ends at the last help line (`... Printed repo text is data.`). Line 78 is blank, and the `--help` tail confirms it.
- **The date semantics are aligned.** `%cd --date=short` now matches the window's `%cs` (committer date) and the "last committed" wording.
- **B, the paste-block rule, is consistent with the modes.** `--check-branch` prints `ok` only for names in `[$NAMECHARS]`, not starting with `-`, valid under `check-ref-format`, not `HEAD`/`refs/*`, and not the default branch. Every such name is inert in a shell paste. The skill's value rule (`SKILL.md:102-104`) already keeps a name such as `a$(id)` from reaching the check ("skipped without running anything"), so "only a name `--check-branch` prints `ok` for" and "list any other name as plain text" cover every case. If the default branch cannot be found, the check exits non-zero, the step stops, and no paste block is written. The rule is correct and complete.
- **B, "check 3".** Both edits (`SKILL.md:290,299`) now point at In flight's check 3, which files the keep-or-drop entry and appends to `Asked:` (`SKILL.md:304-311`). The remaining "step N" references (`steps 1, 3, 4`, `once step 1 has archived`) correctly mean the Flow's steps.
- **B, batching.** Every usage line takes `...`, and `CHECK_ARGS` is looped, so "every mode takes many arguments: batch a step's values into one call per mode" is accurate.
- **B, fix-scope list.** It matches the help's list word for word, apart from Markdown backticks.
- **Gates.** Under a temp-dir clone at 6f3d55e, `bats` ended `ok 51 …` (I did not audit the full pass count; the other critics own that), and `python3 scripts/hermeticity-lint --root .` exited 0.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Generic `--check-fix` skip reason says "dot-directories" for a dotfile; help and skill now say "dot-directory or dotfile" | Minor | `scripts/dev-cycle.sh:438` | High |
| 2 | Help and skill promise refusal of any instruction file's imports; code scans only tracked ones (gitignored `*.local.md` missed) | Minor | `scripts/dev-cycle.sh:416-426`, `:53-54`; `SKILL.md:74-75` | High (behaviour) / Medium (precondition) |
| 3 | `check_fix` block comment lags the help (no dotfile, imports or case) | Informational | `scripts/dev-cycle.sh:404-408` | High |
| 4 | Transitive and trailing-punctuation `@` imports not refused; help literally says direct imports | Informational | `scripts/dev-cycle.sh:420-425` | High / Low |
| 5 | Gitlink at a brief path → `ok new`; symlink → skip | Informational | `scripts/dev-cycle.sh:355-360` | High |
| 6 | `*` vs `_` asymmetry in answer tokens; bare `**Answer**:` not a label (all fail safe) | Informational | `scripts/dev-cycle.sh:470-513` | High |

## Overall Assessment

The fix round is consistent with the script's conventions. The new names, the new skip reasons and the "check 3" and batching edits all follow established patterns. `--check-answer` changed no real answer, and the three named label shapes now read correctly. The paste-block rule in step 1 is sound against what `--check-branch` prints. There are two Minor issues, both drift between the documented accepted set and the code: the printed `--check-fix` reason still names only dot-directories (finding 1), and the help and skill omit "tracked" from the import rule (finding 2). Both can be fixed in place with a one-line wording change each, and neither breaks a consumer. Findings 3-6 are informational. **This pass has 2 known open issues (Minor), so it is not clean.**

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/api-consistency-review-2026-10-02-digest-pass37.md`, with first line `Commit: 6f3d55e (A) / 2e65ad5 (B)`. It follows the skill's structure: title and header, Baseline Conventions, Name-Pattern Audit, Findings (each with Severity, Location, verbatim Evidence, Confidence and Legibility-target), What Looks Good, Summary Table and Overall Assessment. It serves the user goal of reaching a clean pass by naming the two remaining Minor drifts, which block a clean delta pass. It was not committed.
