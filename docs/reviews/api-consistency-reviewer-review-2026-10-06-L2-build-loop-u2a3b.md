Commit: be94c871

# API Consistency Review — feat/build-loop-u2a3b, loop 2 iteration 1 (full panel)

**Scope:** `git diff main...HEAD -- scripts test docs/working skills` at be94c871 (import_targets / IMPORT_AWK, tree_starts, imported_names, isimported, main_imports' consumption of import_targets, check_fix, the --check-fix help text, skills/dev-cycle/SKILL.md, dev-cycle.bats' inventory)
**Date:** 2026-10-06
**Based on:** Stage-1 code-fact-check summary (fcL2-summary.md; full report docs/reviews/code-fact-check-report-build-loop-u2a3b-L2-i1.md). No escalation was addressed to api-consistency-reviewer; Claim 18a (status 3 at the bound) is built on in Finding 1, and Claim 1(c) (mawk `-v` escapes) is cross-referenced in Finding 4 (security owns it).

## Baseline Conventions

- **Return statuses in the lib are 0/1.** `nul_list` ("emptied and 1 unless ..."), `instruction_names` ("returns 0 when no name matches and 1 when grep fails", which deliberately folds grep's 2 into 1 via `|| [[ $? -eq 1 ]]`), `imported_names` and `main_imports` ("return 1 when the walk fails"). Callers in this diff test them under `if`/`||`.
- **Shared awk programs are `*_AWK` string variables** (`FENCE_AWK`, `ANSWER_AWK` in the lib; `SETTINGS_AWK`, `CONSTRAINTS_AWK` in scripts/build-loop.sh), run as `env LC_ALL=C awk ... "$X_AWK"`. The one `-v` precedent (`awk -v id="$a"` at scripts/lib/dev-cycle-read.sh:793) passes a value already validated to `Q-NNN`, never a free-form path.
- **Walk names are `tree` and `main`** (`isimported tree|main`); helpers are snake_case noun phrases (`untracked_md`, `instruction_names`, `imported_names`, `main_imports`).
- **Skip messages** have the shape `skip <path>: <reason>; file it instead`, and state a reason the reader can act on. A failure that only bounds knowledge is worded as such ("cannot be ruled out", added in this diff).
- **Fail-closed answers**: `isimported` answers imported (0) for every failure; the inventory test in test/scripts/dev-cycle.bats lists every function and exported variable consumers rely on.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `IMPORT_AWK` (replaces `IMPORT_RE`) | exported variable (awk program) | `FENCE_AWK`, `ANSWER_AWK`, `SETTINGS_AWK` | `scripts/lib/dev-cycle-read.sh:194,721`, `scripts/build-loop.sh:150` | Consistent: `<NOUN>_AWK`, run under `env LC_ALL=C awk`. Removing `IMPORT_RE` breaks no consumer: `rg IMPORT_RE` outside docs/reviews finds only the inventory row, which the diff updates |
| `tree_starts` | function | `untracked_md`, `instruction_names`, `main_imports` | `scripts/lib/dev-cycle-read.sh:560-571` | Consistent: `tree` matches `isimported`'s walk name; its 0/1 status matches `nul_list`, which it feeds |
| `skip <path>: the instruction-file import walk failed, so an import of it cannot be ruled out; file it instead` | CLI output line | the other `check_fix` skip lines | `scripts/dev-cycle.sh:178-185` | Consistent shape (`skip $a: <reason>; file it instead`) |
| `IMPORTED=error` initial value | variable state | `IMPORTED_MAIN=error` | `scripts/lib/dev-cycle-read.sh:481` | Consistent: the two walks now share the "error until a walk succeeds" sentinel (raw IMPORTED reads are a settled row) |

No new CLI flags, no new parameters. dev-cycle.bats' inventory now matches the lib's function set (checked: `declare -F` after sourcing against the inventory list, the only difference being parse noise); `NAMECHARS`, `DIGIT` and `SLUG` are absent from the variable inventory, as they were at main (not this diff).

## Findings

#### 1. import_targets returns awk's status (3 at the work bound), not the documented 1

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:504-505` (contract), `scripts/lib/dev-cycle-read.sh:558` (code), `IMPORT_AWK`'s `exit 3` in `emit`
**Move:** 4 (error consistency) / 3 (consumer contract)
**Confidence:** High
**Legibility-target:** a future caller of import_targets who reads its comment and the lib's 0/1 convention (e.g. one that tests `[[ $? -eq 1 ]]` the way `instruction_names` does)

Evidence (contract): `# It returns 1 when sed or awk fails, or when the candidates run past a` / `# work bound (so a pathological file fails the walk rather than stalling it).` Evidence (code): `printf '%s\n' "$toks" | env LC_ALL=C awk -v dir="$1" -v root="$ROOT_REAL" "$IMPORT_AWK"` with `work += length(c); if (work > 50000000) exit 3`. Probe (scratch copy, mawk 1.3.4): 3 MB of `@aaaa...` lines piped to `import_targets ""` prints `rc=3`. An awk runtime or syntax error likewise returns awk's own status (2). The sed step does `|| return 1`, so the function's two failure paths disagree. Both in-tree callers (`imported_names` :592, `main_imports` :647) test with `||`, so nothing fails open today; the defect is the documented contract versus the lib's established 0/1 convention.

**Recommendation:** end the pipeline with `|| return 1` (smallest fix; keeps the comment true). Tested in a scratch copy together with Finding 4's patch: the bound probe then prints `rc=1`, and all 121 tests of the five suites pass.

#### 2. "imports it with @" is now asserted for names the superset only over-reads

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:184` (skip line), `scripts/dev-cycle.sh:51-55` (--check-fix help), `skills/dev-cycle/SKILL.md:75`, `test/scripts/dev-cycle.bats` ("an email-shaped token is over-read (superset)" test)
**Move:** 3 (documentation drift) / 7 (asymmetry with the sibling skip line)
**Confidence:** High (mechanism); Medium (consumer impact)
**Legibility-target:** the dev-cycle agent and the user reading --check-fix output and SKILL.md

Precedent: knowledge-bounded refusals are worded as such ("so an import of it cannot be ruled out") in `scripts/dev-cycle.sh:182`.

Evidence: `echo "skip $a: an instruction file imports it with @ (directly or through another import), so it is read as instructions; file it instead"`. Under be94c871 this line also fires for names Claude Code 2.1.292 does not import: `Mail user@docs/email.md` (the diff's own test now expects `skip docs/email.md: an instruction file imports`), every prefix of a longer run (probe: `x@docs/a.md.bak and @docs/b.md,` yields `docs/a.md` and `docs/b.md,` among 17 candidates), and `@` names inside code spans and fences. The help text ("a file an instruction file imports with @") and SKILL.md say the same. The refusal is correct (fail toward imported, as designed); the stated reason is a fact for some paths and a guess for others. A reader told "it is read as instructions" about `user@docs/email.md` learns a false fact about Claude Code and may act on it (for example by "fixing" the instruction file, or by citing the doc as instruction text).

**Recommendation:** reword the reason to say what the parser knows, in the same voice as line 182, e.g. `skip $a: an instruction file names it after an @ (directly or through another import), so it may be read as instructions; file it instead`. Mirror "names ... after an @ (read broadly)" in the help text and SKILL.md, and adjust the two tests that grep `an instruction file imports`. Doc and test wording only; no behavior change.

#### 3. main_imports' "path main lacks" check now runs on every candidate prefix: an ignored `.env` beside `@.env.example` fails the gate's walk

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:611-613` (contract), the `[[ -d "$p" && ! -L "$p" ... ]] || [[ ! -e "$p" && ! -L "$p" ]] || { IMPORTED_MAIN=error; return 1; }` line in main_imports' read loop
**Move:** 3 (subtle behavior change for an existing consumer of import_targets)
**Confidence:** High (probed)
**Legibility-target:** the U2a3c author (checkout-side walk) and the gate's user

Evidence: the contract says the walk fails when `an imported path main lacks ... exists in the checkout as anything but a plain directory below the root`. "Imported path" now means every candidate, prefixes included. Probe (scratch repo, GEMINI.md on main holding `See @.env.example for settings`, `.env.example` committed, an untracked `.env` in the checkout): be94c871's `main_imports` prints `main walk failed`; with `.env` moved away, `ok`. At main the token was only `.env.example`, so the walk passed. This fails closed, and A5 already says a developer checkout with ignored files fails and the gate needs a fresh worktree until U2a3c. So it is no defect in this unit. But "anything untracked whose name is a prefix of an @ run" is a much wider trigger than "an imported path", and U2a3c's checkout phase will inherit it.

**Recommendation:** no code change in U2a3b. Add one clause to main_imports' contract comment (and A5): "an imported path" includes every candidate prefix. Route to U2a3c: decide there whether a checkout-only candidate that main lacks should fail the walk or, like the tree walk, simply be walked as a possible import.

#### 4. import_targets' `$1` (and ROOT_REAL) reach awk through `-v`, which processes backslash escapes (cross-reference; security owns)

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:558`
**Move:** 3 (contract: "for a file in directory $1")
**Confidence:** High
**Legibility-target:** the security-reviewer and orchestrator (Stage-1 Claim 1(c))

Evidence: `env LC_ALL=C awk -v dir="$1" -v root="$ROOT_REAL" "$IMPORT_AWK"`. The lib's only other `-v` (`-v id="$a"`, :793) carries a validated `Q-NNN`, so this is the first use with an arbitrary path. A directory name holding `\` is no longer the `$1` the contract names.

**Recommendation (tested):** pass both through the environment: `env LC_ALL=C IT_DIR="$1" IT_ROOT="$ROOT_REAL" awk "$IMPORT_AWK" || return 1` with `BEGIN { dir = ENVIRON["IT_DIR"]; root = ENVIRON["IT_ROOT"] }` as IMPORT_AWK's first rule. In a scratch copy, `printf '@x\\y/z.md\n' | import_targets 'sub\\dir'` keeps both backslashes, and 121/121 pass.

## What Looks Good

- `IMPORT_AWK` follows the `*_AWK` convention and the `env LC_ALL=C awk` call shape. Retiring `IMPORT_RE` breaks no consumer, and the inventory test is updated in the same commit.
- `imported_names` now has the same contract as `main_imports`: an `error` sentinel, a return of 1, and a cached error that returns 1 again. `isimported tree` gained `|| return 0`, which matches `main`. The tree and main walks are now symmetric (move 7), which closes an asymmetry the earlier code had.
- `check_fix` words a failed walk separately ("cannot be ruled out") before asking `isimported`, as the lib header tells callers to. The help text ("and for every path when the import walk fails") and SKILL.md ("refuses every path when the import walk fails") both document it, and a test covers the corrupt-index case.
- `instruction_names` now separates "no match" (0) from "grep failed" (1), and `tree_starts` feeds `nul_list`, which checks completeness. Both follow the lib's existing listing contract.
- import_targets' output contract (one repo-relative path per line, case kept, each once) holds. Removing `.` (the old `realpath` of `x/..`) and duplicates within a file only narrows what consumers had to tolerate.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | import_targets returns awk's 3 (or 2), not the documented 1 | Minor | `scripts/lib/dev-cycle-read.sh:504-505,558` | High |
| 2 | "imports it with @" asserted for over-read names (email-shaped, prefixes, code spans) | Minor | `scripts/dev-cycle.sh:184,51-55`; `skills/dev-cycle/SKILL.md:75` | High |
| 3 | main_imports' checkout-only-path failure now fires on every prefix (ignored `.env` beside `@.env.example`) | Informational | `scripts/lib/dev-cycle-read.sh:611-613` | High |
| 4 | `-v dir=`/`-v root=` escape processing (cross-ref Stage-1 1(c)) | Informational | `scripts/lib/dev-cycle-read.sh:558` | High |

## Overall Assessment

The public surface stays consistent with the lib's conventions. The new names fit their neighbours, the walk-failure contract is now symmetric across `tree` and `main`, and the one exported-variable removal has no consumer left. No finding is Breaking. Two Minor items can be fixed in place. Finding 1 is a one-token `|| return 1`. Finding 2 is a wording change so the --check-fix reason stops claiming that over-read names are real imports. The over-read itself is the intended superset and does not make --check-fix useless: the measured cost is 0 new false positives. The two Informational items are a note to carry into U2a3c and a cross-reference to the security finding, with a tested patch.

## Goal-Alignment Note

Success criterion (verbatim): "A markdown report saved at the output path named in your role section below, structured per your skill, with a `Commit: be94c871` line at the top."

This report is saved at docs/reviews/api-consistency-reviewer-review-2026-10-06-L2-build-loop-u2a3b.md in the worktree. It has `Commit: be94c871` as its first line and follows the api-consistency-reviewer structure (baseline, name-pattern audit, findings, what looks good, summary, assessment). Probes ran only in /tmp/u2a3b-apiL2-42y6 (scratch copy via git archive) with TMPDIR /tmp/u2a3b-apiL2-tmp-xY4J. No tracked worktree file was edited.
