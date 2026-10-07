Commit: 34edec56

# API Consistency Review — feat/build-loop-u2a3 (iteration 2)

**Scope:** `git diff main...HEAD` (base 62d366a7, HEAD 34edec56): the public surface of `scripts/lib/dev-cycle-read.sh` (`main_imports`, `isimported main`, `IMPORTED_MAIN`, `IMPORTED_MAIN_DONE`, the lib header contract), checked against plan F11/U2a3/U2b and known issue A5
**Date:** 2026-10-06
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2a3-i2.md` (i2 summary), `docs/reviews/code-fact-check-report-build-loop-u2a3.md` (iteration 1)

## Baseline Conventions

Read in full: `need_root` (:94-98), `inrepo`/`inrepo_here`/`dirok`/`skipped` (:124-131), `main_by_name`/`main_entry`/`entry_why` (:252-303), `brief_fields` (:317-341), `check_brief` (:350-387), `check_branch` (:397-410), `resolve_main` (:416-438), `imported_names` (:514-531), `main_imports` (:545-615), `isimported` (:621-630), and the caller `check_fix` (`scripts/dev-cycle.sh:170-184`).

- **Names.** Functions are snake_case. Commit-reading helpers take a `main_` prefix and a noun (`main_by_name`, `main_entry`). Predicates are bare `is…` words (`isbrief`, `isclosed`, `isimported`). Globals are UPPER_SNAKE, and a cached result comes in pairs: `IMPORTED` plus `IMPORTED_DONE` (the cache key).
- **Preconditions.** File checks that exit call `need_root` first, in the caller's shell. Commit readers check `main_by_name` and refuse (`check_brief` prints a skip, `main_entry` prints `error`, `brief_fields` returns 1 with `BRIEF_ODD=error`).
- **Failure reporting.** A function that refuses reports *why* in a word or global the caller can word: `main_entry` prints `absent|notfile|notdir PART|badform|error` and `entry_why` words it. `brief_fields` sets `BRIEF_ODD` to `odd N WHY|unbalanced N|error`. `skipped` sets `SKIP_AT` to the blocking part.
- **Fail-closed predicates.** If a predicate cannot answer, it answers the refusing way under `if`. `isimported` with an unknown walk name returns 0 (imported). No function in the lib or its callers returns 2 (searched `return 2|exit 2|rc -eq 2` in `scripts/lib/dev-cycle-read.sh`, `scripts/dev-cycle.sh`, `scripts/build-loop.sh`).
- **Pipefail.** Functions that pipe a blob read set `local -; set -o pipefail` (`brief_fields`).
- **Caches** are keyed on `ROOT_REAL`. The only way to recompute is a different key. No reset function exists.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `main_imports` | function | `main_entry`, `main_by_name`, `imported_names` | `scripts/lib/dev-cycle-read.sh:253,269,514` | Consistent with the `main_` + noun family. Its mismatch with `imported_names` is settled (override-log row 343, Won't-Fix) |
| `main` (walk-name argument of `isimported`) | parameter value | `tree` | `scripts/lib/dev-cycle-read.sh:627`; announced in U2a2's docstring ("U2a3 adds main") | Consistent: a bare noun naming what the walk reads |
| `IMPORTED_MAIN` | global (result) | `IMPORTED`, `BRIEF_ODD`, `MAIN_SHA` | `scripts/lib/dev-cycle-read.sh:252,317,472` | Consistent: mirrors `IMPORTED` (newline-framed, lower-cased). The `error` sentinel matches `BRIEF_ODD=error` and `main_entry`'s `error` |
| `IMPORTED_MAIN_DONE` | global (cache key) | `IMPORTED_DONE` | `scripts/lib/dev-cycle-read.sh:472,517` | Consistent: the key widens from `ROOT` to `SHA ROOT`. See finding 4 on what the key leaves out |
| `m:` / `t:` queue prefixes | private | — | — | Private locals; not audited |

No naming findings.

## Findings

#### 1. `main_imports` reports one undifferentiated `error` for about fifteen refusal causes, where the lib's other commit readers return a reason

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:532-544, 549-603` (main_imports' comment and every `IMPORTED_MAIN=error; return 1`)
**Move:** 4 (error consistency)
**Confidence:** High
**Legibility-target:** U2a4/U2c authors wording the floor's refusal; an operator reading a refused `--check`

Evidence (excerpt of the function's comment; ends :544, enclosing `main_imports()` continues to :615 — read):
```
# The main walk; returns 1, with IMPORTED_MAIN set to "error", when main is not
# found by name, the commit's tree or the untracked list cannot be listed whole,
# a tree record does not parse, the listing holds a name twice (git's lookups
...
# newline or a NUL, or has a .. after a symlink, or a checkout path it
# would read exists but is not a plain file (a symlink, or under one) or a
# plain directory, so a caller refuses
```
```
          if [[ -z "$out" || "$out" == *$'\n'* || "$out" == /* ]]; then IMPORTED_MAIN=error; return 1; fi
...
            [[ "$c" != .. || -z "$lk" ]] || { IMPORTED_MAIN=error; return 1; }
```
Compare with the established readers:
```
# BRIEF_ODD "odd N WHY" (FENCE_AWK refused line N; WHY for oddwhy),
# "unbalanced N" (the fence opened at line N never closes) or "error" (no
```
```
# (a path pathform refuses: a .git* part such as .gitattributes, say) or "error"
```

The function and its comment list causes ranging from "main is not found by name" to "a checkout path … is a symlink". Every one of them sets the same `IMPORTED_MAIN=error` and names no path. `brief_fields` returns a reason (`odd N WHY`, `unbalanced N`) and keeps `error` for read failures only. `main_entry` returns a word per kind of refusal, `entry_why` words that word, and `skipped` names the blocking part in `SKIP_AT`. The walk instead refuses every path at once with one error, so the floor's eventual skip line can only say something like "could not be walked" (U2a's draft `FLOOR_WHY`). That line names no file. It also does not say whether the fix is to the commit (a doubled name, bad link text) or to the checkout (a stray symlink, an unreadable untracked file). Override-log row 344 defers the walk-failure wording to U2c, but a caller cannot word a reason the function never returns. The single word also weakens the tests. Every fail-closed test asserts only `want walk failed`, so it cannot pin which arm fired. The i2 fact-check's surviving mutant at :600 (the checkout half `! -L "$p"` removed) shows this: the main-side arm produces the same `error`.

**Recommendation:** Keep `IMPORTED_MAIN=error` as the sentinel, and also set a reason global on each failure: `IMPORTED_MAIN_WHY="KIND PATH"` (for example `doubled PATH`, `linktext PATH`, `checkout-link PATH`, `unreadable PATH`, `nomain`). This follows `BRIEF_ODD`'s "word plus position" shape. Tests could then assert the kind. If that is out of scope for U2a3, add a Defer row whose trigger is U2a4's floor.

#### 2. The checkout-dependency contract is stated three ways, and the lib's statement is the narrowest

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:29-35` (header), `:464-469` (Not covered); `docs/working/plan-build-loop-handoff.md:126` (F11), `:278` (U2b); `docs/working/known-issues-dev-cycle.md:18` (A5)
**Move:** 3 (consumer contract: documentation drift)
**Confidence:** High
**Legibility-target:** U2a4/U2b authors who read the lib header as the contract

Evidence, lib header (:31-34):
```
# writes), and so does main_imports (it also reads the checkout's untracked
# start files and imported files main lacks, which can only add imports, and
# needs resolve_main to have found main by name, or it fails);
```
Plan F11 (:126):
```
The walk reads the checkout for its untracked starts, for targets main lacks, and for whether a path it would read is a symlink, so U2b names the checkout `--check` runs in.
```
Lib "Not covered" (:466-468) against A5 (:18):
```
# untracked nested repo (neither listing enters one either), an @ token's path
# (link text is checked above) through a directory main stores as a symlink
# when the checkout does not have that link, other names that one file has on a case-insensitive checkout, and
```
```
an import path through a directory main stores as a symlink when the checkout lacks that link
```

The plan names three ways the walk reads the checkout. The header, which callers in this lib are told to read first, names two. It leaves out the `-L` probes (:581-582, :600), which change the result: a checkout symlink fails the walk. The "Not covered" sentence limits the symlinked-directory gap to "@ token's path (link text is checked above)". The i2 fact-check (Claims 3 and 19, Incorrect, Q10/Q11 executed) shows that link text with no `..` through such a directory also fails open. So A5's and F11's wider "an import path" is correct and the lib comment is the one that disagrees. A U2a4 author who trusts the lib comment would believe link text is fully handled. This is documentation drift, not a behaviour change; the behaviour itself is the security reviewer's (escalated there).

**Recommendation:** In the "Not covered" sentence, drop "(link text is checked above)" and say "an import path or link text". In the header, add "and whether a path it would read is a symlink", matching F11. Then all three statements list the same inputs.

#### 3. `isimported main` packs three outcomes into two return codes, so a caller that words its refusal must call twice

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:616-630`
**Move:** 3 (consumer contract), 7 (asymmetry)
**Confidence:** High
**Legibility-target:** U2a4's floor author

Evidence (whole unit):
```
# Whether path $2 (any case) is imported, by the walk $1 names: tree or main.
# A failed main walk, or a walk name that is neither, answers imported (0), so
# a caller testing it with `if` refuses; a caller that words a failed walk
# runs main_imports first. Run it in the caller's shell: the walk exits
# through need_root and caches its result.
isimported() {
  local lp
  need_root
  lp="$(lower "$2")"
  case "$1" in
    main) main_imports || return 0; [[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]] ;;
    tree) imported_names; [[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]] ;;
    *) return 0 ;;
  esac
}
```
This keeps the lib's fail-closed predicate convention: no function returns 2, and an unknown walk name also answers 0. It also replaces U2a's draft `rc -eq 2` (on `feat/build-loop-u2a`, never on main) with a documented two-call protocol, which is the more consistent choice. Two consequences remain. First, the protocol relies on the cache: the second call (`isimported`) reads the result of the first (`main_imports`). Second, a caller that skips the first call cannot tell "imported" from "walk failed". Both are documented. Recorded so that U2a4 follows the protocol rather than restoring an rc-2 arm. At HEAD the tree arm cannot fail; U2a3b gives it the same failure shape (fixed in U2a3b, stacked).

**Recommendation:** None for U2a3. U2a4's floor should call `main_imports` once before its per-path loop. With finding 1's reason global, that one call also supplies the wording.

#### 4. The cache key leaves out checkout state, and the only reset is the undocumented `IMPORTED_MAIN_DONE=""`

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:469-472, 549-550`
**Move:** 3 (consumer contract)
**Confidence:** High (executed)
**Legibility-target:** U2b's `--check` and any long-lived caller

Evidence (:549-550; excerpt ends :550, enclosing `main_imports()` continues to :615 — read):
```
  [[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $ROOT_REAL" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }
  IMPORTED_MAIN=error; IMPORTED_MAIN_DONE="$MAIN_SHA $ROOT_REAL"
```
Probe (script `scratchpad/u2a3/api-i2-cacheprobe.sh`, scratch `/tmp/u2a3-api-i2-orPF`; fixture with a committed `AGENTS.md` importing `docs/x.md`, and `docs/x.md` a checkout symlink; one shell):
```
first:failed
second-cached:failed          <- symlink removed; cached failure returned
after-reset:ok                <- IMPORTED_MAIN_DONE="" forces a re-walk
y cached: -                   <- untracked AGENTS.local.md importing docs/y.md added after the walk
y after reset: imported
```
The key matches `IMPORTED_DONE`'s precedent: the result is cached per root, and the tree walk also reads a working tree that can change. So this is consistent, not a new convention. The cached answer is wrong in both directions. A stale failure fails closed. A start file added after the walk fails open (`y cached: -`), and that is the case escalated to architecture and security as fact-check escalation (a). The API point is narrower: the contract comment says the result is "cached for the commit and root" but does not list the checkout as an input. It also offers no reset, so a caller must know to clear `IMPORTED_MAIN_DONE`. The planned callers are one-shot CLI invocations (`build-loop.sh --check`), which limits the exposure.

**Recommendation:** Add a sentence to the comment at :469-471: "the checkout is read but not part of the key: a caller that changes the checkout between calls clears IMPORTED_MAIN_DONE". Alternatively, add the untracked listing's hash to the key. The behavioural decision belongs to the architecture/security escalation.

## What Looks Good

- **Names follow the grain.** `main_imports`, `IMPORTED_MAIN` and `IMPORTED_MAIN_DONE` slot into the existing `main_*` and `IMPORTED*` families. `isimported` grows by one walk name rather than adding a sibling predicate, as U2a2's docstring anticipated.
- **The fail-closed shape matches the lib.** Return 1 with the global set to `error` mirrors `brief_fields`/`BRIEF_ODD`. Every `return 1` after :575 resets `IMPORTED_MAIN=error` (checked at :580, :582, :586, :591, :593, :598, :603), so a partial list never escapes. `IMPORTED_MAIN` starts as `error` at source time, so reading it before any walk refuses.
- **Preconditions match the commit readers.** `need_root` comes first, then `main_by_name`. The pipefail is scoped `local -` "as brief_fields". The header's "exit 1 (need_root)" sentence was widened to "the import walks".
- **Result format matches.** Newline-framed and lower-cased like `IMPORTED`, so one membership test serves both arms. Start files are excluded from both walks' sets, as before.
- **The sourcing inventory test was updated** (`test/scripts/dev-cycle.bats:1086,1090`) for the new function and both globals, so a rename or removal is caught.
- **The plan's F11/U2a3/U2b rows and A5** were updated in step with the lib comment's refusal list (apart from finding 2's link-text wording).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | One undifferentiated `error` for ~15 refusal causes; other commit readers return a reason | Minor | `scripts/lib/dev-cycle-read.sh:532-603` | High |
| 2 | Checkout-dependency and not-covered contract stated three ways; the lib's is narrowest (fact-check i2 Claims 3/19) | Minor | `scripts/lib/dev-cycle-read.sh:31-34, 466-468` | High |
| 3 | `isimported main`'s two-call protocol for wording a failed walk | Informational | `scripts/lib/dev-cycle-read.sh:616-630` | High |
| 4 | Cache key leaves out checkout state; undocumented reset (executed) | Informational | `scripts/lib/dev-cycle-read.sh:469-472, 549-550` | High |

## Overall Assessment

The new surface is consistent with the lib's conventions. Names extend the existing `main_*`/`IMPORTED*` families. Preconditions, fail-closed returns, the `error` sentinel and the result format all mirror `brief_fields`, `main_entry` and `imported_names`. No existing consumer breaks: `check_fix` still calls `isimported tree` unchanged, and `isimported main` has no caller until U2a4. Two issues should be fixed in place, both small and both in the contract a U2a4 author will read. First (finding 1), the walk collapses every refusal into one reasonless `error`. That departs from the lib's word-plus-position reporting, will leave the floor's refusal unactionable, and stops tests from pinning which arm fired. Second (finding 2), the lib comment's "Not covered" and header sentences are narrower than A5/F11. Findings 3 and 4 are documented contracts a caller must follow and are recorded for U2a4/U2b. Nothing here suggests the author skipped surveying conventions.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to docs/reviews/api-consistency-reviewer-review-2026-10-06-build-loop-u2a3.md, structured per the api-consistency-reviewer skill."
- **Answered:** Yes. The report is saved at that path with every skill section (Baseline, Name-Pattern Audit, Findings, What Looks Good, Summary Table, Overall Assessment). The public surface named in the task (`main_imports`, `isimported main`, `IMPORTED_MAIN`, `IMPORTED_MAIN_DONE`, the header contract) was checked against `imported_names`/`isimported tree`, the `check_*` functions, `need_root` and `resolve_main`/`main_by_name`.
- **Out of scope:** The fail-open behaviour of Q10/Q11 link text, and the cache's fail-open on an added untracked start, belong to security/architecture (already escalated). Finding 2 covers only the comment wording, and finding 4 only the contract wording. Parser and `lower`-failure behaviour is fixed in U2a3b (stacked). Settled override rows 342-345 and 347 are not re-filed.
- **Escalate:** None new. Finding 4's probe adds executed evidence to fact-check escalation (a), which is already routed to architecture/security.
