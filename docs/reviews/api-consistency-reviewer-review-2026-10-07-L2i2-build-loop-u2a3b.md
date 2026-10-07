Commit: 98e3b1df

# API Consistency Review — feat/build-loop-u2a3b, loop 2 iteration 2

**Scope:** `git diff be94c871..98e3b1df -- . ':!docs/reviews'` (commits dd51e9a7, 98e3b1df), with the rest of the branch as context
**Date:** 2026-10-07
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2a3b-L2-i2.md` (42 claims; its verdicts are taken as given and not re-verified here)

## Baseline Conventions

- **Refusal lines** (`scripts/dev-cycle.sh:146-184`): `skip <path>: <reason>`. The `--check-fix` refusals that route to filing end in `; file it instead` (`:180`, `:182`, `:184`). Tests match on a stable prefix (`skip docs/x.md: an instruction file names it`), not on the whole line.
- **Help/skill parity:** the `--check-fix` paragraph in the `scripts/dev-cycle.sh` header (`:49-55`) and `skills/dev-cycle/SKILL.md:72-76` use the same wording for the refusal set. `docs/dev-cycle.md` does not describe `--check-fix` (rg for `check-fix|import|@` finds nothing), so it has nothing to drift.
- **Lib globals** (`scripts/lib/dev-cycle-read.sh`): UPPER_SNAKE names, prefixed by subsystem (`IMPORTED*`, `IMPORT_AWK`, `MAIN_*`, `SKIP*`, `FENCE_AWK`, `ANSWER_AWK`). They are assigned unconditionally at source time, so the environment cannot set them. The sourcing test (`test/scripts/dev-cycle.bats:1100-1117`) lists the lib's functions and globals as its contract.
- **Values passed to awk:** repo text goes through the environment with a short script prefix when escapes matter. Precedent: `PQ_WANT` with `ENVIRON["PQ_WANT"]` in `scripts/paper-queue.sh:205-212`, which carries the same rationale comment ("awk expands escape sequences in a -v assignment"). Values without escapes use `-v` elsewhere (`scripts/lib/dev-cycle-read.sh:823`, `scripts/questions.sh:222`).
- **Failure contract:** lib walk functions return 1 and leave their result at `error`. Callers test them under `if`/`||` (lib header `:19-21`).
- **External tools:** where a dependency is optional, the script states it and says what happens without it. Precedents: `hooks/claude-config-audit.sh:18,52` for python3 missing, and README.md:162 ("Depends on `shfmt` + `jq`").

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `IMPORT_OUT_MAX` | lib global (bound) | `IMPORT_AWK`, `IMPORTED_MAIN_DONE`, local `max=50` in `check_path` | `scripts/lib/dev-cycle-read.sh:481,522`; `scripts/dev-cycle.sh:145` | Consistent with the `IMPORT*` prefix. It is the first `_MAX` global (rg `[A-Z]_(MAX\|LIMIT\|CAP)` over `scripts/`, `hooks/` finds only this one), so it sets the convention. The unit and the override story are covered in F2. |
| `IT_DIR`, `IT_ROOT` | awk environment names | `PQ_WANT` | `scripts/paper-queue.sh:209-212` | Consistent: a short script prefix (`IT` = import_targets), set only on `env ... awk` and never exported. A caller's inherited `IT_*` cannot leak in, because `env` assigns both. |
| skip reason "an instruction file names it after an @ (directly or through another import), so it may be read as instructions; file it instead" | CLI output line | `skip $a: the instruction-file import walk failed, ...; file it instead`; `skip $a: in-cycle fixes edit only ...; file it instead` | `scripts/dev-cycle.sh:180,182` | Consistent: same `skip <path>: <reason>; file it instead` shape. All five test matchers moved to the new prefix (`test/scripts/dev-cycle.bats:1027,1063,1070,1084,1097`). |
| help/skill phrase "a file an instruction file names after an @, read broadly" | help text / skill doc | the same paragraph's old "imports with @" | `scripts/dev-cycle.sh:53-54`, `skills/dev-cycle/SKILL.md:75` | Consistent: the two are worded identically (fact-check Claim 6). |

## Findings

#### F1. The lib's new python3 dependency is not stated where its callers would look

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:8-11` (header), `:569-575` (`import_targets`); `scripts/dev-cycle.sh` and `scripts/build-loop.sh` headers
**Move:** 3 (consumer contract: documentation drift)
**Confidence:** High
**Evidence (verbatim):**
```
# Sourced, never run: it only defines functions and variables. Each script
# sources it from its own directory (never from the repo it acts on), so a copy
# of scripts/ with its lib/ is self-contained.
```
```
    d="$(printf '%s\n' "$toks" | python3 -I -c 'import sys; sys.stdout.buffer.write(sys.stdin.buffer.read().decode("utf-8", "replace").encode())')" || return 1
```
Reasoned, plus fact-check Claim 12 (executed).

The lib now forks `python3`, found on PATH, whenever an instruction file holds a byte above 0x7f. Without python3, `--check-fix` refuses every path ("the instruction-file import walk failed"), and the gate's main walk fails closed. Only the comment inside the function says so (`:515`, "returns 1 when sed, python3 or awk fails"). The header still calls a copy of `scripts/` "self-contained", and neither entry script's usage block names python3. The commit's justification ("python3 is already a dependency (questions.sh)") holds only for `questions.sh check`, which is a different consumer (fact-check Claim 38a). The failure is safe, since the walk fails closed. But an operator on a host without python3 sees `python3: command not found` on stderr next to a "walk failed" refusal, with nothing in the scripts' own docs linking the two. This repo's own instruction files contain non-ASCII text, so here the fork is the normal path, not the edge case (fact-check Claim 36b: about 0.5 s added over 942 paths). Precedent for stating it: `hooks/claude-config-audit.sh:18` ("python3 missing" is a listed case) and README.md:162 ("Depends on `shfmt` + `jq`").

**Recommendation:** Add one clause to the lib header next to "self-contained", for example "needs python3 when an instruction file holds non-ASCII text; without it the import walks fail closed". Optionally add the same clause to the `--check-fix` paragraph in `scripts/dev-cycle.sh`'s header.

#### F2. `IMPORT_OUT_MAX` reads as a caller knob, but it is not one: no header entry, no cache key, and a character count named in bytes

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:482-485,603,618,694`; `test/scripts/dev-cycle.bats:1112`; `test/scripts/build-loop-check.bats:398-404`
**Move:** 3 (consumer contract), 8 (contract clarity)
**Confidence:** Medium
**Evidence (verbatim):**
```
# Each walk fails once import_targets has printed this many bytes in all: the
# parser's own bound is per file, while the bash side's cost grows with
# everything printed (performance L2 F2); /workspace's walks print about 2 KB.
IMPORT_OUT_MAX=4000000
```
```
  [[ "$IMPORTED_DONE" == "$ROOT_REAL" ]] && { [[ "$IMPORTED" != error ]]; return; }
```
```
        IMPORT_OUT_MAX=4000000; IMPORTED_DONE=""; IMPORTED_MAIN_DONE=""; imported_names && ...
```
Reasoned, plus fact-check Claim 7 (executed).

The name looks like the lib's other caller-visible state, and the test overrides it after sourcing. Should a caller do the same? The lib never says. Four things a caller would trip on:
- **The cache ignores it.** The cache keys (`IMPORTED_DONE`, `IMPORTED_MAIN_DONE`) leave it out, so lowering it after a successful walk changes nothing until the caller also clears the `_DONE` markers. The test does exactly that.
- **The header omits it.** The lib header documents the `IMPORTED_MAIN_DONE=""` reset (`:477-479`) but says nothing about this variable.
- **The sourcing test omits it.** The contract test lists `FENCE_AWK ANSWER_AWK INSTRUCTION_FILE IMPORT_AWK UNI_SPACES` but not `IMPORT_OUT_MAX`. An unset value fails both walks closed (`used <= 0`), so the omission is safe, but the test would not catch the variable being dropped.
- **"Bytes" is really characters.** The comment says "bytes", but `${#out}` counts characters in the caller's locale (fact-check Claim 7). Under C.utf8 a non-ASCII name counts as fewer.

Because the source-time assignment cannot be set from the environment, a hostile environment cannot raise the bound. That part is right.

**Recommendation:** Say in its comment that it is a lib constant, with tests as the only override and the `_DONE` markers cleared afterwards. Change "bytes" to "characters (bytes under LC_ALL=C)". Add it to the sourcing test's variable list.

#### F3. `import_targets` now returns 1 for an empty ROOT_REAL, but an unset one aborts under `set -u` instead

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:515,561,580`
**Move:** 4 (error consistency)
**Confidence:** High
**Evidence (verbatim):**
```
# It returns 1 when sed, python3 or awk fails, when ROOT_REAL is empty, or when the
```
```
  printf '%s\n' "$toks" | env LC_ALL=C IT_DIR="$1" IT_ROOT="$ROOT_REAL" awk "$IMPORT_AWK" || return 1
```
Executed in `/tmp/u2a3bapiL2i2-LCPw` (a `git archive 98e3b1df` copy of the lib) under `set -euo pipefail`:

| Call | Result |
|---|---|
| `ROOT_REAL=` then `import_targets ""` under `if` | `failed 1` |
| `unset ROOT_REAL` then a bare call | `line 580: ROOT_REAL: unbound variable`, and the calling shell exits 1 |
| `unset ROOT_REAL` then a call under `if` | `failed`; the shell survives, because the pipe runs the function in a subshell |

The change from be94c871 (an empty root gave rc 0 with no names) to rc 1 tightens the contract toward failing closed. Both real callers (`:616`, `:672`) run `need_root` first and treat any non-zero status as a walk failure, so neither is affected. The lib header says the lib tolerates an unset ROOT_REAL for the plain-file checks (`:17-18`). `import_targets` does not tolerate it: a direct call outside `if`/`||` ends the caller rather than returning 1. Only tests call it directly today, and they set ROOT_REAL.

**Recommendation:** Either change the comment to "when ROOT_REAL is unset or empty (unset aborts under set -u)", or use `${ROOT_REAL:-}` at `:580` so both cases reach the BEGIN block's `exit 2` and return 1.

## What Looks Good

- **The reworded skip reason** keeps the sibling shape and the `; file it instead` tail. "May be read as instructions" matches the over-read design. Every matcher that grepped the old prefix (`an instruction file imports`) was moved, and rg over `scripts/`, `skills/`, `workflows/`, `hooks/`, `test/` and `docs/dev-cycle.md` finds no consumer still matching "imports it with @". The only hits for "read as instructions" are this line and an unrelated hook banner (`hooks/claude-config-audit.sh:117`).
- **Help and skill parity** holds word for word. The help's omission of the transitive case is known issue C3 (fail-safe) and is not re-raised.
- **`IT_DIR`/`IT_ROOT`** follow the repo's existing environment-not-`-v` idiom and its rationale comment (`scripts/paper-queue.sh:205-212`).
- **The `import_targets` return contract** is now uniform (1 on every failure, never awk's 2 or 3, per fact-check Claims 12 and 37), which suits callers that only test for non-zero.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | python3 runtime dependency not stated in the lib or entry-script headers | Minor | `scripts/lib/dev-cycle-read.sh:8-11,574` | High |
| F2 | `IMPORT_OUT_MAX`: override status, cache keys, sourcing-test list and "bytes" unit undocumented | Informational | `scripts/lib/dev-cycle-read.sh:482-485` | Medium |
| F3 | Empty ROOT_REAL returns 1, but unset ROOT_REAL aborts under `set -u` | Informational | `scripts/lib/dev-cycle-read.sh:515,580` | High |

Legibility targets: F1 for-author. F2 for-author, plus for-automated-gate (sourcing-test list). F3 for-author.

## Overall Assessment

The fixes are consistent with the codebase's interface conventions. The new skip wording matches its siblings, the help and the skill, and every test consumer was updated; no workflow, script or doc still matches the old wording. The new environment names follow an existing idiom exactly. The remaining issues are documentation gaps in the lib's caller contract: an undocumented python3 dependency (F1), an ambiguously scoped bound (F2), and a stated failure case that does not cover unset ROOT_REAL (F3). All three fail closed, none breaks a consumer, and each is a one- or two-line fix.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A markdown report saved at the output path named in your role section, structured per your skill, with a `Commit: 98e3b1df` line at the top.
- **Answered:**
  - Skip reason, help and SKILL.md consistency, including every consumer of the old wording: consistent, none stale.
  - `IMPORT_OUT_MAX` and `IT_*` naming and overrideability: F2, plus the audit table.
  - The `import_targets` return contract against its callers: F3, with no caller broken.
  - The python3 dependency against documented requirements: F1.
- **Out of scope:** the cost of the python3 fork (performance critic) and the `~/` superset gap (fact-check Claim 9; that is about correctness, not interface consistency).
- **Escalate:** none.
- **Decisions I made:**
  - I treated `docs/dev-cycle.md` as having no `--check-fix` text, after confirming it by rg.
  - I classed F1 as Minor rather than Inconsistent, because the failure is fail-closed and the repo has no single requirements list to be inconsistent with.
  - I kept the probe in `/tmp/u2a3bapiL2i2-LCPw`. No processes were left running.
