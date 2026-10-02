Commit: 90364c73 (main; delta 6f3d55e..5652d33f / 2fd9401..2da55741)

# API Consistency Review: dev-cycle pass 38 (final k=1 delta, post-merge)

**Scope:** A: `git diff 6f3d55e..5652d33f -- . ':!docs/reviews'` (scripts/dev-cycle.sh). B: `git diff 2fd9401..2da55741 -- . ':!docs/reviews'` (scripts/dev-cycle.sh, skills/dev-cycle/SKILL.md, test/scripts/dev-cycle.bats). Partial scope: everything else is context only.
**Date:** 2026-10-02
**Based on:** shared brief `pass38-orchestrator/brief.md`; Stage-1 report `docs/reviews/code-fact-check-report-2026-10-02-digest-pass38.md`; pass-37 API report `docs/reviews/api-consistency-review-2026-10-02-digest-pass37.md`.

Public surface reviewed: the `--check-fix` and `--check-brief` `ok`/`skip` lines and their reasons, `--help` (`scripts/dev-cycle.sh:2-77`), the in-code design comments above `check_fix` and `imported_names`, and SKILL.md's restatement (`skills/dev-cycle/SKILL.md:71-85,170-175`). One probe (`/tmp/claude-1000/pass38-api/p1.sh`, `set -eu`, own `mktemp -d` dir, `$PWD` checked before every write, every process under `timeout`, finished before this report) ran a copy of the script at 90364c73 against a synthetic temp repo. Behaviour the fact-check already executed is cited from it and not re-run.

## Baseline Conventions

- **Check-mode output:** one line per argument, `ok <path> [fields]` or `skip <arg>: <reason>`. A reason is a lower-case clause naming the cause the caller can act on, and the `--check-fix` reasons end in `; file it instead`.
- **Help and skill:** the help gives each mode's `ok` shape and its accepted set. The skill restates the `--check-fix` set word for word (apart from backticks), and the cycle agent treats it as the complete refusal set (`SKILL.md:71-72`: "edits only a file that `--check-fix '<path>'` prints `ok` for").
- **Design comments:** each check function has a block comment stating its rule; for `check_fix` that is `scripts/dev-cycle.sh:404-408`, and for the import walk `:414-421`.
- **Names:** UPPER_SNAKE globals (`MAIN_SHA`, `SKIPPED`, `INSTRUCTION_FILE`), lower_snake helpers (`inrepo`, `writable`, `pathform`).

## Status of pass-37 API findings

| Pass-37 finding | 5652d33f target? | Status at 90364c73 | Evidence |
|---|---|---|---|
| 1. Generic `--check-fix` reason said "dot-directories" for a dotfile (Minor) | yes | **Fixed, consistent.** Reason, help and skill now all name dotfiles. | Probe: `skip docs/.dot.md: in-cycle fixes edit only tracked .md documentation under docs/ (not working/, human-author/, reviews/, decisions/, dev-cycle.md, dot-directories or dotfiles, or instruction files) and README.md; file it instead`. Help `:51-52` `a dot-directory` / `or dotfile`; skill `:74` `a dot-directory or dotfile`. |
| 2. Help/skill promise imports of any instruction file, code scanned only tracked ones (Minor) | yes | **Fixed for untracked and gitignored files**: the code was widened to match the documented set. The documented set is now contradicted by other shapes; see Finding 1. | Probe: gitignored `AGENTS.local.md` with `@docs/loc.md` → `skip docs/loc.md: an instruction file imports it with @ …` (pass 37: `ok`). |
| 3. `check_fix` block comment lags the help (Informational) | no | **Open, unchanged**; see Finding 3. | `:404-408` unchanged by the delta. |
| 4. Transitive and trailing-punctuation imports not refused (Informational) | yes | **Fixed** for transitive chains and trailing `.,;:!?`. | Probe: `docs/a.md` (direct) and `docs/n.md` (through `docs/a.md`) both print the import reason; fact-check Claims 4b, 9. |
| 5. Gitlink at a brief path → `ok new` (Informational) | yes | **Fixed, consistent.** The mode is read first; a gitlink or tree gets the existing `not a regular file on the default branch` reason. The help's and skill's "`ok <path> new` when the default branch has no file there" stays accurate. | `:357-361`; fact-check Claim 3 (P3, P4). |
| 6. `*`/`_` answer asymmetry (Informational) | no | Open, not re-filed (not a fix target; fails safe). | fact-check header. |

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `lower` | function (internal helper) | `inrepo`, `writable`, `pathform`, `skipped` | `scripts/dev-cycle.sh:179-257` | Consistent: short lower-case verb/predicate helper. It is not yet used by `check_fix`, which still inlines the same `tr` (`:454`). Internal only. |
| `IMPORT_RE` | global | `INSTRUCTION_FILE`, `NAMECHARS` | `scripts/dev-cycle.sh:202,413` | Consistent: UPPER_SNAKE regex held in a quoted variable, as `INSTRUCTION_FILE`'s comment explains. |
| `skip <path>: an instruction file imports it with @ (directly or through another import), so it is read as instructions; file it instead` | `--check-fix` skip reason | the pass-37 import reason; the generic `--check-fix` reason | `scripts/dev-cycle.sh:460,462` | Consistent: names the cause, ends in `file it instead`. It no longer echoes a basename, which suits the full-path match. |
| `… dot-directories or dotfiles, or instruction files …` | `--check-fix` skip reason (reworded) | help `:51-52`, skill `:74` | same | Consistent with both. |
| `ok <path> new` / `skip <path>: not a regular file on the default branch` (reordered) | `--check-brief` output | `skip … reached through a symlink, or not a regular file` | `scripts/dev-cycle.sh:354,358-360` | Consistent: no new string; a gitlink/tree now gets the existing reason. |

## Findings

#### 1. The documented `--check-fix` refusal set ("a file an instruction file imports with @") is contradicted by `_` paths, a regression from 6f3d55e

**Severity:** Inconsistent
**Location:** `scripts/dev-cycle.sh:423` (`IMPORT_RE`), `:439-445`; help `scripts/dev-cycle.sh:52-53`; skill `skills/dev-cycle/SKILL.md:74-75`; design comment `scripts/dev-cycle.sh:414-421`
**Move:** 3 (consumer contract: subtle narrowing of the refused set; documentation drift)
**Confidence:** High on the behaviour (executed here and in fact-check P2). Medium that Claude Code reads the whole `_` path (fact-check read the 2.1.288 bundle statically).
**Legibility-target:** the cycle agent, which takes the skill's list as the complete refusal set; and the author choosing between fixing the walk and narrowing the wording.

**Evidence (verbatim):** Help: `or dotfile, an instruction file, or a file an instruction file` / `imports with @; compared ignoring case) or README.md`. Skill: `` `docs/decisions/`, `docs/dev-cycle.md`, a dot-directory or dotfile, an instruction file, or a `` / `` file an instruction file imports with `@`; compared ignoring case) or ``. Code: `IMPORT_RE='(^|[[:space:](*_])@[^[:space:]`)*_]+'`. Probe, temp repo whose tracked `AGENTS.md` reads `Read @docs/my_notes.md and @docs/a.md.`:

```
skip docs/a.md: an instruction file imports it with @ (directly or through another import), so it is read as instructions; file it instead
ok docs/my_notes.md
```

The token stops at `_`, so the recorded path is `docs/my`, and `docs/my_notes.md` prints `ok`. At 6f3d55e this file was refused (fact-check Claim 4a), so a consumer who relied on the pass-37 contract sees the refused set shrink with no wording change. The other shapes the fact-check found (Claim 1b) also print `ok` while the help says they are refused: `@docs/q.md#intro`, a symlink target or a path through a symlinked directory (Claim 6b), imports in a symlinked instruction file (Claim 5), and an absolute in-repo path (Claim 7). The design comment above `imported_names` adds two promises that these cases break: "as Claude Code does" and "(~/ and absolute paths lead outside the repo and are not followed)". The exposure (fail-open on a safety control, Medium for `_`) belongs to the security critic. This finding is the contract side: help, skill and comment state a set the code does not implement.

Failure scenario (run): an instruction file imports `@docs/CODING_STANDARDS.md`-style paths; step 1's in-cycle fix runs `--check-fix 'docs/my_notes.md'`, gets `ok`, and edits a file Claude Code loads as instructions, while the skill's text says that cannot happen.

**Recommendation:** Fix the token (allow `_` and `*` inside it, keep them only in the left context, cut at `#`) rather than narrowing the wording, since the help's wording is the intended contract. For any shape left unhandled (symlinks, absolute paths), say so in the help and the skill, and correct the design comment's "as Claude Code does" and "lead outside the repo" in the same edit.

#### 2. Help and skill describe direct imports; the code and the skip reason refuse transitive ones too

**Severity:** Informational
**Location:** help `scripts/dev-cycle.sh:52-53`; skill `skills/dev-cycle/SKILL.md:74-75`; reason `scripts/dev-cycle.sh:462`; comment `:414-416`
**Move:** 3 (documentation drift) / 7 (asymmetry between the documented set and the printed reason)
**Confidence:** High
**Legibility-target:** the cycle agent reading the skill.

**Evidence (verbatim):** Comment: `# Code's "@path" syntax), followed transitively`. Reason: `an instruction file imports it with @ (directly or through another import)`. Help: `or a file an instruction file` / `imports with @`. Probe: `docs/n.md`, imported only by `docs/a.md`, prints `skip docs/n.md: an instruction file imports it with @ (directly or through another import), …`.

The help and skill were not updated with 5652d33f, so the code refuses more than they list. This fails safe, and the printed reason explains itself, so no consumer is misled into an edit. It is only drift between three statements of one rule.

**Recommendation:** When touching the help and skill for Finding 1, write "a file an instruction file imports with @, directly or through another import".

#### 3. The `check_fix` design comment still lags the help (pass-37 finding 3, not fixed)

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:404-408`
**Move:** 3 (documentation drift, maintainer-facing)
**Confidence:** High
**Legibility-target:** the next maintainer editing `check_fix`; the rubric reader.

**Evidence (verbatim):**

```
# An in-cycle fix edits documentation only: a tracked .md file under docs/,
# outside the cycle's own files, working/, human-author/ (the user's), reviews/
# and decisions/ (records), the settings file, any dot-directory, and any
# instruction file (CLAUDE.md, AGENT(S).md, GEMINI.md, SKILL.md, any case); or
# README.md. Anything else is filed.
```
(the comment ends at :408; `INSTRUCTION_FILE`'s own comment follows at :409)

It omits dotfiles and `@`-imported files, and says "any case" only of instruction files, while the help (`:51-53`), the reason (`:460`) and the code (`lp`, `:454-462`) cover all three. 5652d33f did not target this finding, yet the rubric's Pass 37 status says "API reported 2 Minor + 4 Informational, fixed in 5652d33f", which reads as all six. Findings 3 and 6 were not fixed.

**Recommendation:** Add "dotfile" and "a file an instruction file imports with @ (see imported_names)", and move "any case" to the end of the list. When recording this pass, note that pass-37 findings 3 and 6 remain open (both Informational).

## What Looks Good

- **Pass-37 findings 1, 2 (untracked half), 4 and 5 are fixed, and each fix lands consistently** in the reason, the help and the skill where wording was involved (see the status table). The dotfile wording now matches word for word across all three.
- **The new import reason** follows the established reason shape (cause, then `file it instead`), and it no longer echoes a basename that would mislead now that the match is by full path.
- **Case handling is consistent:** `skip DOCS/A.MD` gets the same import reason as `docs/a.md` (probe), matching the help's "compared ignoring case". The `lp` and `IMPORTED` sides compare in one normal form for every `pathform` path (fact-check Claim 10).
- **`--check-brief`:** the gitlink/tree fix reuses the existing skip reason, so no consumer-visible string was added, and "`ok <path> new` when the default branch has no file there" in the help (`:30-31`) and skill (`:84-85`) stays exactly right, including the symlinked `closed/` parent case (fact-check Claim 3).
- **Skill side (B):** the paste-block rule (`SKILL.md:170-175`) matches what `--check-branch` prints `ok` for; the batching sentence (`:101-102`) matches every mode's `...` usage; the "check 3" references are correct (fact-check Claims 15-17). I re-read these against the help and found no drift. These rules are correct and complete.
- **README.md stays fixable in this repo** (fact-check Claim 20), so the import refusal does not over-refuse a file the cycle needs.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Help/skill/comment promise every `@`-imported file is refused; `_` paths (a regression from 6f3d55e), `#fragment`, symlinked and absolute imports print `ok` | Inconsistent | `scripts/dev-cycle.sh:423,439-445`; help `:52-53`; `SKILL.md:74-75`; comment `:414-421` | High (behaviour) / Medium (Claude Code side) |
| 2 | Help/skill say direct imports; code and reason refuse transitive ones (fail-safe drift) | Informational | `scripts/dev-cycle.sh:52-53,462`; `SKILL.md:74-75` | High |
| 3 | `check_fix` design comment omits dotfiles, imports and case (pass-37 finding 3, unfixed; rubric reads as all fixed) | Informational | `scripts/dev-cycle.sh:404-408` | High |

## Overall Assessment

The output surface itself is consistent: the reworded and new skip reasons follow the script's reason conventions, and pass-37 findings 1, 2, 4 and 5 are fixed consistently across reason, help and skill. The one substantive problem is the contract the help and skill state for the `@`-import refusal: 5652d33f's new token class makes `_` paths (common in doc names) print `ok`, narrowing a refused set that 6f3d55e honoured, and several rarer shapes were never covered. That is fixable in place (the token class, plus wording for any shape left out), and its safety weight belongs to the security critic. Findings 2 and 3 are wording drift that fails safe. **This pass has 1 known open issue (Inconsistent) on the API side, so it is not clean.**

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your role instructions give, structured per your skill file.
- Answered: Saved at `/workspace/docs/reviews/api-consistency-review-2026-10-02-digest-pass38.md` with the required first line, not committed. Structure follows the skill (header, Baseline Conventions, Name-Pattern Audit, Findings with Severity/Location/verbatim Evidence/Confidence/Legibility-target, What Looks Good, Summary Table, Overall Assessment), plus a status table for every pass-37 API finding. Fixed and consistent: pass-37 1, 2 (untracked half), 4, 5. Open: 3 (Finding 3 here), 6 (not re-filed). Fact-check Claim 1b is carried as the contract finding (Finding 1).
- Out of scope: the exposure and severity of the fail-open import gaps (security); the `--check-fix` cost with large ignored trees (performance, fact-check P5); pass-37 finding 6; anything in the rubric's Full review 1 / Pass 37 sections.
- Escalate: security-reviewer owns the severity of `scripts/dev-cycle.sh:423` (`_` token regression) and the symlink/absolute/`#` gaps. Orchestrator: the rubric's Pass 37 line "fixed in 5652d33f" overstates; pass-37 API findings 3 and 6 are still open.
