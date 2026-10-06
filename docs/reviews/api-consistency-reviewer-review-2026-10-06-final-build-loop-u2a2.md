Commit: 7697c6e6

# API Consistency Review — feat/build-loop-u2a2 (iteration 3, final confirming pass)

**Scope:** net branch diff `git diff main...HEAD` (main 20347279, HEAD 7697c6e6): the lib's caller contract (`scripts/lib/dev-cycle-read.sh` header, `isimported tree`, `import_targets`, `inrepo_here`, `instruction_names`, `untracked_md`), `--check-fix` output (`scripts/dev-cycle.sh`), and the test-helper conventions in `test/scripts/build-loop-check.bats` against `build-loop-read.bats` / `dev-cycle.bats`
**Date:** 2026-10-06
**Based on:** `/home/node/.claude/jobs/814a541d/tmp/rv/fc3-summary.md` (Stage-1, k=3 at 7697c6e6); prior api review `api-consistency-reviewer-review-2026-10-06-build-loop-u2a2.md` (iteration 2) and rubric `code-review-rubric-2026-10-06-feat-build-loop-u2a2.md` rows B1-B14 (context)

## Baseline Conventions

Read whole: the lib header (`dev-cycle-read.sh:1-31`), `need_root`/`rawfile`/`plaindir`/`blocker`/`inrepo`/`inrepo_here`/`dirok`/`skipped` (:91-128), `isbrief`/`isclosed` (:160-161), `entry_why` (:284-311), the import block (:436-525: `INSTRUCTION_FILE`, `UNI_SPACES`, `IMPORT_RE`, `lower`, `import_targets`, `instruction_names`, `untracked_md`, `imported_names`, `isimported`); `check_path`, `check_write`, `check_fix` (`dev-cycle.sh:144-184`) and the `--check-fix` help paragraph (:50-55); `test/lib/build-loop-fixtures.bash`; `build-loop-read.bats:1-60`; the lib tests in `dev-cycle.bats:1083-1170, 1339-1356`; `fixture-git-env.bats`; U2a3's lib at `feat/build-loop-u2a3` 579ebca2 (consumer shape only).

- **Root precondition.** Functions that read the checkout either exit 1 through `need_root` (and are listed in the header: `inrepo, dirok, skipped, check_brief, isimported and the walk`) or fail closed without it (`rawfile`/`plaindir`/`blocker` "read nothing as plain while ROOT_REAL is unset"). No lib reader answers a permissive result when `ROOT_REAL` is missing.
- **Answers.** Predicates (`is*`, `inrepo*`, `dirok`) return 0/1; readers print one item per line (`brief_fields`, `oddwhy`) or NUL-separated lists for path listings (`matches` in dev-cycle.sh); fail-closed words (`error`, "imported") on anything unknown.
- **Names.** `is*` predicates; `*_names` for name lists (`imported_names`); UPPER_SNAKE constants (`IMPORT_RE`, `INSTRUCTION_FILE`, `FENCE_AWK`); `X`/`X_DONE` result-cache pairs.
- **`--check-*` output.** One line per argument, `ok <path>` or `skip <path>: <reason>`, reasons in prose that repeat the help paragraph's rule.
- **Tests.** `@category fast`; `bats_require_minimum_version 1.5.0`; `bl_setup` + `commit_all` fixtures for build-loop suites; unit or plan tags in test names (`(T1)`, `(U1d, U2a1)`); assertions as `[ "$status" -eq 0 ] && [ ... ] && [ -z "$stderr" ] || { echo "$output $stderr"; return 1; }`; local assertion helpers echo `want: ...` then the output on a miss (`settings_is`, `settings_like`); lib-level tests run `bash -c 'set -euo pipefail; source "$1"; ...' _ "$LIB"`.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `import_targets DIR <text` | function | `brief_fields`, `oddwhy`, `imported_names` | `scripts/lib/dev-cycle-read.sh:234,315,491` | Consistent noun-phrase reader, one item per line; its `ROOT_REAL` precondition is unstated and unguarded (Finding 1) |
| `isimported WALK PATH` | function | `isbrief`, `isclosed` | `dev-cycle-read.sh:160-161` | Consistent `is*` predicate; word-first order already noted (iteration 2 I-2, not re-filed); unknown word fails closed and is tested |
| `inrepo_here` | function | `inrepo`, `dirok`, `rawfile` | `dev-cycle-read.sh:96,121,127` | Acceptable `_here` variant, documented at its definition; fails closed without `ROOT_REAL` via `blocker` (executed); not named in the header (Informational I-1) |
| `instruction_names` | function | `imported_names` | `dev-cycle-read.sh:491` | Consistent (`*_names` = name list, NUL in/NUL out) |
| `untracked_md` | function | `matches` (dev-cycle.sh), `instruction_names` | `scripts/dev-cycle.sh:140-142`; `dev-cycle-read.sh:487` | Consistent: NUL-separated listing like `matches`; `GIT_LITERAL_PATHSPECS=0` matches `matches`' own spelling |
| `UNI_SPACES` | constant (array) | `IMPORT_RE`, `INSTRUCTION_FILE` | `dev-cycle-read.sh:439,455` | Consistent UPPER_SNAKE constant; sits in the source-test inventory (`dev-cycle.bats:1089`) |
| `imps WALK PATH...`, `want PATH WORD` | test helpers | `settings_is`, `settings_like`, `line` | `test/lib/build-loop-fixtures.bash:40-45` | Consistent: `want` prints `want: ...` then the output, like `settings_is`; local to the suite as `make_repo` is in `dev-cycle.bats:25` |
| `build-loop-check.bats` | test file | `build-loop-read.bats`, `fixture-git-env.bats` | `test/scripts/build-loop-*.bats` | Consistent `build-loop-<mode>` naming, header and setup shape copied from `build-loop-read.bats:1-11` |

## Findings

#### 1. import_targets reads ROOT_REAL with no guard and no stated precondition: called without it, it prints nothing and returns 0, which a caller reads as "nothing imported"

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:458-482` (header list at :12-17)
**Move:** 8 (absent-state contract), 3 (consumer contract)
**Confidence:** High (executed)

Evidence (the only `ROOT_REAL` use; whole function read):
```
      p="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${1:+$1/}$t" 2>/dev/null)" || continue
```
Probe in a scratch repo, stdin `see @docs/a.md`:
```
ROOT_REAL unset, set -euo pipefail:  "ROOT_REAL: unbound variable" (x2 on stderr), no lines, rc=0
ROOT_REAL unset, no set -u:          no lines, rc=0
ROOT_REAL set:                       docs/a.md, rc=0
```
The unbound-variable error ends only the `$(...)` subshell, and `|| continue` swallows it. Every other checkout reader in the lib either exits through `need_root` or fails closed ("read nothing as plain"); `import_targets` is the one whose missing-root answer is the permissive one for its consumers (an empty import list means "not imported"). Today both callers are safe: `imported_names` runs `need_root` first, and U2a3's `main_imports` does too (579ebca2). But `import_targets` is now a named, shared lib entry point ("Every import walk shares these rules"), it sits in the source-test inventory as public surface (`dev-cycle.bats:1086`), and its comment names its inputs (stdin, `$1`) without `ROOT_REAL`. A `need_root` inside it would not help (it runs in `< <(...)`, where an exit ends only the substitution), so the contract has to be stated.

**Recommendation:** Add to its comment "Reads ROOT_REAL; the caller has run need_root (unset, it prints nothing)" and name it beside `inrepo_here` in the header as a function that relies on its caller's `need_root`.

#### 2. The shared parser's comments still describe two token rules the code does not follow (Stage-1, not re-verified)

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:450-452` (UNI_SPACES comment), `:461-462` (import_targets comment)
**Move:** 3 (documentation drift)
**Confidence:** High (per fact-check r1 Claims 18b, 21; r2 Claim 14c; r3 Claim 9b)

Evidence:
```
# UTF-8 spaces that end an import token, as a blank does: ...
# ... it ends at a
# blank, a UNI_SPACES space, \, #, a backtick, ( ) [ or ].
```
Stage 1 found `[` does not end a token (`IMPORT_RE` excludes `]` but not `[`; `@c[x].md` reads `c[x`, carried from main), and a UNI_SPACES space does not end a token "as a blank does" when an `@` follows it directly (E1: `@docs/a.md<NBSP>@docs/b.md` yields only `a.md`; `--check-fix docs/b.md` prints ok; not a regression). This comment is now the one authoritative description of the parser that U2a3's commit walk inherits (rubric B9 moved it here), so the drift is in the consumer-facing contract, not a side note. The E1 behaviour itself is a security/correctness matter for the panel; this finding is only the description.

**Recommendation:** Drop `[` from the list (or add it to `IMPORT_RE`, which only refuses more), and qualify "as a blank does" until E1 is fixed; if E1 is fixed in this unit, add `@a.md<NBSP>@b.md` to test 1.

#### I-1. inrepo_here is not named in the header's precondition paragraph (Stage-1)

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:12-17`, `:122-124`
**Move:** 3
**Confidence:** High

The header lists the functions that exit through `need_root` and those that fail closed without `ROOT_REAL`; `inrepo_here` (no `need_root`, documented at :122-123) is in neither list. It does fail closed (executed: `inrepo_here f.md` with `ROOT_REAL` unset prints `notplain`, via `blocker`), so no consumer is misled into a permissive answer; fact-check noted the header half of rubric B10 is absent. Pairs naturally with Finding 1's header line.

#### I-2. isimported's own need_root is unpinned; test 2 checks output only

**Severity:** Informational
**Location:** `test/scripts/build-loop-check.bats:41-45`; `scripts/lib/dev-cycle-read.sh:514-516`
**Move:** 4 (error consistency), test conventions
**Confidence:** Medium (mutant survival by reading, not executed)

Evidence:
```
    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; resolve_main; ROOT_REAL="$(pwd -P)"
        if isimported bogus docs/z.md; then echo "bogus: imported"; fi' _ "$LIB"
    [ "$output" = "bogus: imported" ] || { echo "$output $stderr"; return 1; }
```
The header promises `isimported` exits 1 without a valid `ROOT_REAL`. For `tree` that also follows from `imported_names`' guard (tested at `dev-cycle.bats:1157-1160`), but the unknown-word arm depends only on `isimported`'s own `need_root`, and no test runs it without `ROOT_REAL` (the `dev-cycle.bats:1106` loop covers `inrepo dirok skipped`); a mutant dropping that line would pass the suite. Executed at HEAD the guard works (`isimported bogus x` with no `ROOT_REAL`: exit 1, "ROOT_REAL is not set"). Test 2 also omits the `[ "$status" -eq 0 ] ... [ -z "$stderr" ]` half its neighbours (test 1, `dev-cycle.bats` lib tests) assert.

**Recommendation:** Add `"isimported bogus docs/z.md"` to the `dev-cycle.bats:1106` loop, and the status/stderr check to test 2. Optional.

#### I-3. imps documents a `main` walk that does not exist at this commit (Stage-1)

**Severity:** Informational
**Location:** `test/scripts/build-loop-check.bats:14-23`
**Move:** 3
**Confidence:** High

`imps main ...` at 7697c6e6 prints `walk: failed` because `main_imports` is undefined (command not found under `if`), and the helper's comment calls that "main_imports' return". It is a deliberate forward shape for U2a3 (which defines `main_imports`, 579ebca2), no test calls `imps main` here, and the suite header says "main_imports from U2a3". No change needed in this unit; noted so U2a3's first test of `imps main` is read as the helper's first real use.

## What Looks Good

- `--check-fix`'s output contract is byte-for-byte unchanged: same `ok`/`skip` lines, same import reason text; the only change is the predicate (`isimported tree "$lp"`), and it moves only toward refusing. Executed on a scratch repo with `AGENTS.md` holding `@docs/nb.md<NBSP>y and @docs/st.md.`: main prints `ok docs/nb.md`, HEAD prints the import skip for both. The walk now runs lazily (only for paths that reach that `elif`), which changes no output since the script sets `ROOT_REAL` at `dev-cycle.sh:121`.
- `isimported`'s unknown-word arm fails closed, documented and tested, matching the lib's fail-closed baseline (`main_entry` answering `error`, `blocker` defaulting to `file`).
- `instruction_names` and `untracked_md` follow the NUL-listing convention of `matches`, and the walk's own `INSTRUCTION_FILE` test stays the authority, as their comments say.
- The token rules now live on `import_targets` with the shared-parser warning ("a change here changes --check-fix too"), closing iteration 2's Finding 3 / rubric B9.
- The `dev-cycle.bats` source-test inventory lists every new function and `UNI_SPACES`, so a removal is caught.
- `entry_why`'s comment and its one-argument test now agree (carried row C13); `fixture-git-env.bats` unsets `--local-env-vars` itself and compares the victim's index byte for byte (C12), and its inner filter names an existing test (`dev-cycle.bats:1207`).
- `build-loop-check.bats` copies `build-loop-read.bats`' header, `@category fast`, version floor, `bl_setup` setup and unit-tagged names; `want` mirrors `settings_is`' failure output. Shellcheck at the health gate's level (`-S warning`) is clean on it.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `import_targets` reads `ROOT_REAL` unguarded and unstated; unset, it answers "nothing imported" | Minor | `scripts/lib/dev-cycle-read.sh:458-482` | High |
| 2 | Parser comments list `[` as a terminator and say UNI_SPACES end a token "as a blank does" (fact-check 21/14c, E1) | Minor | `scripts/lib/dev-cycle-read.sh:450-452,461-462` | High |
| I-1 | `inrepo_here` absent from the header's precondition paragraph | Informational | `scripts/lib/dev-cycle-read.sh:12-17` | High |
| I-2 | `isimported`'s own `need_root` unpinned; test 2 checks output only | Informational | `test/scripts/build-loop-check.bats:41-45` | Medium |
| I-3 | `imps` documents the U2a3 `main` walk | Informational | `test/scripts/build-loop-check.bats:14-23` | High |

## Overall Assessment

The unit's public surface is consistent with the lib's conventions: an `is*` predicate that fails closed on unknown input, `*_names`/NUL listings matching their neighbours, UPPER_SNAKE constants in the source inventory, and a `--check-fix` whose output format is untouched and whose answers change only toward refusal (one corner, fact-check's bff4ded2 note on Unicode-space file names, goes the other way and now matches Claude Code). The remaining issues are contract wording: `import_targets`, the new shared entry point, does not say it needs `ROOT_REAL` and answers permissively without it (Finding 1), and its comments overstate two token rules (Finding 2). Both are comment fixes in place; neither blocks U2a3, whose `main_imports` already runs `need_root` before calling the parser.

## Goal-Alignment Note

- **Success criterion (verbatim):** "a markdown report saved at the path given in your tail, structured per your skill, with `Commit: 7697c6e6` as its first line."
- **Answered:** yes: `docs/reviews/api-consistency-reviewer-review-2026-10-06-final-build-loop-u2a2.md`, line 1 `Commit: 7697c6e6`, skill sections in order.
- **Out of scope:** settled override rows (walk-name asymmetry, `isimported` argument order as iteration 2 I-2, C16's copied unset line, B7 queue cost) and the U2a3-routed rubric rows B2-B6, B8, B10 (main half), B11, B12, B14 were not re-filed. Commit-message and questions.md/plan wording items from Stage 1 (questions.md:393, plan :277, bff4ded2/7697c6e6 messages) are outside this lens.
- **Escalate:** fact-check E1 (an `@` directly after a UNI_SPACES character is never read; fail-open, not a regression) is behavioural and belongs to the security critic and the rubric; Finding 2 covers only its description. E2 (`(`, `)`, `]` inside an intermediate file name) likewise.
- **Probe cleanup:** one scratch dir `/tmp/u2a2f-api-INNf` (scratch repo plus main's `dev-cycle.sh`/lib copy), every command under `timeout 10`/`timeout 20`; no process left running. Nothing written to the repo but this report.
