Commit: 7ddff454

# API Consistency Review: build-loop U2a3b (iteration 2)

**Scope:** `git diff 45ad17b0..7ddff454 -- scripts test` (commits 1ccc8b65 and 7ddff454). The public surface is `scripts/lib/dev-cycle-read.sh`: the caller contract at the top of the file, and the return-status contracts of `import_targets`, `instruction_names`, `imported_names` and `isimported`. These are compared with `main_imports`' contract, which is context from U2a3. The callers are `scripts/dev-cycle.sh` `check_fix` and the function inventory in `test/scripts/dev-cycle.bats:1085-1086`.
**Fact-check input:** `docs/reviews/code-fact-check-report-build-loop-u2a3b-i2.md` (22 verified, 3 mostly accurate). I build on its Claims 1, 5, 12, 16b and 24 and did not re-verify them.
**Probe:** a scratch copy of 7ddff454 at `/tmp/u2a3b-api-wcsx` (removed afterwards). It held a fixture repo with `AGENTS.md` → `@docs/a.md`, plus `docs/b.md`, which nothing imports. `bash scripts/dev-cycle.sh --check-fix docs/a.md docs/b.md` was run before and after `printf junk > .git/index`. Both exits were 0.

### Baseline Conventions

- **Failure is a return, plus a sentinel.** A walk that fails returns 1 and sets its result variable to the literal `error`. The result is cached under a `*_DONE` key, and a cached error returns 1 again. `main_imports` set this convention (`:566-628`, header `:554-565`), and `imported_names` now follows it (`:531-532`).
- **Failing commands are mapped explicitly.** grep's "no match" maps to 0 and any other status to non-zero, with `|| [[ $? -eq 1 ]]`. `import_targets` uses this at `:505`, and `instruction_names` now does too, at `:524`. A listing ends in `rc=0`/`rc=1` and is read with `mapfile -d ''` (`main_imports` `:574`, `:583`; `imported_names` `:534`).
- **Shell options are set locally.** A function that needs pipefail declares `local -; set -o pipefail` (`brief_fields`, `main_imports` `:567`, and now `imported_names` `:529`).
- **isimported fails closed.** It answers 0 ("imported") for anything it cannot decide. The header says that a caller who wants to word a failure differently runs the walk first (`:630-633`).
- **need_root exits.** It does not return. The top-of-file contract (`:12-21`) says to call exiting checks in the caller's shell.

### Name-Pattern Audit

The range adds no new public names. All five functions it touches (`import_targets`, `instruction_names`, `untracked_md`, `imported_names`, `isimported`) already exist and already appear in the inventory at `test/scripts/dev-cycle.bats:1085-1086`. The new identifiers are locals: `c w n toks b s` in `import_targets`, and `lp out recs` in `imported_names`. No global, flag or file name is added. Walk naming is settled (override row 343).

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| _(none)_ | — | — | none — searched the `+` lines of `git diff 45ad17b0..7ddff454 -- scripts test` for new function definitions and new globals | No new public names |
| `IMPORTED=error` (new sentinel value for an existing global) | state value | `IMPORTED_MAIN=error` | `scripts/lib/dev-cycle-read.sh:474`, `:570` | Consistent: the same literal and the same meaning |

### Findings

#### 1. check_fix words a failed tree walk as "an instruction file imports it", which the isimported contract says a caller should not do

**Severity:** Inconsistent
**Location:** `scripts/dev-cycle.sh:181`; `scripts/lib/dev-cycle-read.sh:630-633`, `:640`
**Move:** 3 (trace the consumer contract), 4 (error consistency)
**Confidence:** High
**Legibility-target:** for-author

Evidence, from the isimported header (`:630-633`):
```
# A failed walk, or a walk name that is neither, answers imported (0), so
# a caller testing it with `if` refuses; a caller that words a failed walk
# runs main_imports first.
```
and from `scripts/dev-cycle.sh:181-182` (excerpt ends :182; enclosing check_fix() continues to :184, `else check_path "$a"; fi` — read):
```
  elif isimported tree "$lp"; then
    echo "skip $a: an instruction file imports it with @ (directly or through another import), so it is read as instructions; file it instead"
```
Probe output after corrupting the index. `docs/b.md` is imported by nothing:
```
fatal: .git/index: index file smaller than expected
skip docs/a.md: an instruction file imports it with @ (directly or through another import), so it is read as instructions; file it instead
skip docs/b.md: an instruction file imports it with @ (directly or through another import), so it is read as instructions; file it instead
rc=0
```
Before this range, the tree walk could not fail, so check_fix's single message was always true. Now `tree) imported_names || return 0` (`:640`) folds a failed walk into "imported". check_fix prints a reason that is false for every path, and exits 0. The refusal is still fail-closed, which is the intent. The problem is the reason text, which sends the user looking for an import that does not exist. The header's way to word a failure ("runs main_imports first") names only the main walk, so the contract offers no tree-side way to do this. The `fatal:` line appears once, because the cache absorbs it on later calls, so a multi-argument run shows one stderr line and N wrong reasons.

**Recommendation:** Generalise the header sentence to "runs the walk (imported_names or main_imports) first". In check_fix, call `imported_names` under `if !` before the `isimported` branch, and print a distinct skip reason ("the import walk failed; file it instead"). Add the corrupt-index case to the check_fix bats coverage. If this is out of the unit's scope, record it as a Defer row.

#### 2. main_imports' header does not list the failures this range added to it, and the two walk headers now describe errors in different shapes

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:554-565` (main_imports header), `:450-455` (imported_names header), `:622`
**Move:** 7 (asymmetry), 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-author

The imported_names header (`:450-455`) reads:
```
# token rules). It returns 1, with IMPORTED set to "error", when the start
# listing (git ls-files, untracked_md, instruction_names), lower, a file read or
# the parser fails (...); an
# inrepo_here that fails skips its path. ... and a cached error
# returns 1 again.
```
The main_imports header (`:554-565`) lists its own causes: "main is not found by name, the commit's tree or the untracked list cannot be listed whole, a tree record does not parse, … a blob or checkout file cannot be read, …". It names neither `lower` nor the parser, and it does not say that a cached error returns 1 again. The code does both: this range adds `i="$(lower "$p")" || { IMPORTED_MAIN=error; return 1; }` at `:622`, and `:569` reads `[[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $ROOT_REAL" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }`. The header's closing sentence, "IMPORTED_MAIN reads "error" until a walk succeeds; the result is cached", is in a separate paragraph (`:470-472`). The candidate `tr` failure (`:588-589`, fact-check Claim 24) is not named either. The walks are now symmetric in behavior, but a reader comparing the two headers would conclude that only the tree walk fails on lower or parser errors, and only the tree walk re-reports a cached error. The `:622` line is in this range, so this is drift the range introduced, not U2a3 context.

**Recommendation:** Add "lower (or the candidate tr), the parser" and "a cached error returns 1 again" to main_imports' list, in the same order the imported_names header uses.

#### 3. IMPORTED starts as an empty success while IMPORTED_MAIN starts as "error"

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:474`
**Move:** 7 (asymmetry)
**Confidence:** Medium
**Legibility-target:** for-author

```
IMPORTED=$'\n'; IMPORTED_DONE=""; IMPORTED_MAIN=error; IMPORTED_MAIN_DONE=""
```
Precedent: `IMPORTED_MAIN reads "error" until a walk succeeds` used in `scripts/lib/dev-cycle-read.sh:470-471`.
This range gives `IMPORTED` the same `error` sentinel (`:532`), but its initial value still reads as "walked, nothing imported". A consumer that reads `$IMPORTED` directly before any walk sees an empty successful walk, which is a fail-open reading. One direct reader exists, the `dev-cycle.bats:1165` test, and it reads only after a successful call. No production caller reads it directly, because check_fix goes through isimported. The impact is latent. The line is unchanged context, but the asymmetry only matters now that `error` is a meaningful value for `IMPORTED`.

**Recommendation:** Initialise `IMPORTED=error` to match, and add one clause to the imported_names header: "IMPORTED reads "error" until a walk succeeds". Confirm that no test reads `IMPORTED` before a walk.

#### 4. isimported's header omits its new "failed lower answers imported" rule

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:629-633`, `:637`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-author

The code is `lp="$(lower "$2")" || return 0` (`:637`), but the header lists only "A failed walk, or a walk name that is neither" as answering imported (`:630`). This rule runs before either walk, so for `main` a caller that "runs main_imports first" still gets "imported" from a lower failure, with `main_imports` having succeeded. The behavior is fail-closed and correct. The documentation is incomplete.

**Recommendation:** Change the clause to "A failed walk, a failed lower of $2, or a walk name that is neither, answers imported (0)".

#### 5. instruction_names' status contract is undocumented, and it now returns 1 for an error

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:520-524`
**Move:** 4 (error consistency)
**Confidence:** High
**Legibility-target:** for-author

```
instruction_names() { env LC_ALL=C grep -zaiE '(^|/)((claude|agents?|gemini)(\.[a-z0-9_-]+)?|skill)\.md$' || [[ $? -eq 1 ]]; }
```
The idiom matches `import_targets` (`:505`, `|| [[ $? -eq 1 ]] || return 1`), which is consistent. The result is 0 for "no match" and 1 for a grep error, which inverts grep's own convention, where 1 means no match. The comment above it (`:520-523`) says nothing about its status. The 7ddff454 message says it "returns grep's error status", which fact-check Claim 16b rated Mostly accurate. Its only caller (`:534`) reads it through pipefail and `rc=0`, so no consumer breaks. A future caller that knows grep could read the 1 as "no instruction files". The fact-check also notes that nothing pins this behavior (the `instnames-true` mutant survives).

**Recommendation:** Add "returns 0 with no match, non-zero when grep fails" to its comment. Leave the code as is.

#### 6. Callers must now guard bare imported_names calls under set -e (consistent with main_imports, but not stated in the file header)

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:12-21` (top-of-file contract), `:531-535`
**Move:** 3 (trace the consumer contract), 6 (versioning)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

Before this range, `imported_names` always returned 0. It now returns 1 on a failure. Under the caller's `set -euo pipefail`, which the header requires (`:12`), a bare call ends the caller. The only bare call is `test/scripts/dev-cycle.bats:1165` (`ROOT_REAL="$(pwd -P)"; imported_names; printf "%s" "$IMPORTED"`), and it runs on a success path. Production reaches the function only through `isimported`, which guards it with `||`. This now matches `main_imports`, so it is consistent. Still, the top-of-file contract tells callers which checks exit (need_root). It does not say that the walks return 1 and must be called under `if`/`||`. That fact lives only in each walk's own header.

**Recommendation:** Optionally add one sentence to `:12-21`: "imported_names and main_imports return 1 on a failed walk; call them under if or ||, or through isimported."

### What Looks Good

- The two walks' runtime failure contracts are now symmetric. Both set the same `error` sentinel before any early return, keep a cache that re-reports an error, use the same `rc=0` listing guard with a cross-reference comment (`:533`), and guard lower per path (`:549`, `:622`). Both scope pipefail with `local -` in the same way.
- `isimported tree` now treats a failure the same way `main` does: `|| return 0`, fail-closed.
- `import_targets`' header states its new return rule ("returns 1 when sed or grep fails") and its precondition ("reads ROOT_REAL without checking it"). This is the first place in the lib where that precondition is written down.
- The top-of-file caller contract (`:12-34`) is still accurate: need_root exits, imported_names reads the working tree, and main_imports reads main's commit plus the checkout's untracked files. Nothing in this range contradicts it.
- The inventory in `dev-cycle.bats:1085-1086` needs no change, because no function was added or renamed.

### Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | check_fix reports a failed tree walk as "an instruction file imports it"; the isimported header offers a wording route only for main | Inconsistent | `scripts/dev-cycle.sh:181`, `scripts/lib/dev-cycle-read.sh:630-633` | High |
| 2 | main_imports' header omits the lower/parser/tr failures and the cached-error return; the walk headers are asymmetric | Minor | `scripts/lib/dev-cycle-read.sh:554-565`, `:622` | High |
| 3 | `IMPORTED` starts as an empty success, `IMPORTED_MAIN` as `error` | Minor | `scripts/lib/dev-cycle-read.sh:474` | Medium |
| 4 | isimported's header omits "failed lower answers imported" | Minor | `scripts/lib/dev-cycle-read.sh:630`, `:637` | High |
| 5 | instruction_names' status (0 no match / 1 error) is undocumented and inverts grep's | Informational | `scripts/lib/dev-cycle-read.sh:520-524` | High |
| 6 | The file header does not say the walks return 1 and need `if`/`||` | Informational | `scripts/lib/dev-cycle-read.sh:12-21` | Medium |

### Overall Assessment

The behavior is now symmetric: both walks fail closed with the same sentinel, cache rule, listing guard and per-path lower guard, and `isimported` treats both the same way. The documentation is not yet symmetric. The imported_names header is the more complete of the two, and main_imports' header has not caught up with the `:622` guard this range added (F2). The isimported header still describes failure wording only for the main walk (F1, F4). The one consumer-visible effect is F1. `--check-fix` now refuses every path when the tree walk fails, which is correct, but it gives a false reason ("an instruction file imports it") with exit 0. The probe confirmed this. Every finding can be fixed in place with comment edits plus one check_fix branch. None needs a broader survey of conventions.

## Goal-Alignment Note

- Success criterion (verbatim): "A markdown report saved at the output path named in your role section below, structured per your skill, with a `Commit: 7ddff454` line at the top."
- Answered: yes. The report is saved at `docs/reviews/api-consistency-reviewer-review-2026-10-06-build-loop-u2a3b.md` and has every section the skill requires. To the dispatch's questions: the runtime failure contracts are symmetric. They are not documented in the same shape or place (F2, F3, F4). The top-of-file contract is still accurate, but it is silent on the walks' return-1 rule (F6).
- Provenance: F2, F3 and F4 are about lines this range changed, or semantics it introduced. F3's line is unchanged context, but its meaning changed in this range. None is pure "U2a3 code (context)". F2's omission of the candidate-`tr` failure is pre-existing in U2a3's header and could go to either loop.
- Not re-filed: walk naming (row 343), the start-file rule (row 347), A5 items (row 350), and fact-check Claims 3, 12 and 16b's wording issues. F5 adds only the documentation angle to 16b.
- Decisions I made: I rated F1 Inconsistent rather than Breaking, because the refusal is still fail-closed and only the reason text is wrong. I used `AGENTS.md` in the probe fixture because a hook blocks Bash writes of a file named CLAUDE.md. That does not change the result, because `INSTRUCTION_FILE` matches both names.
