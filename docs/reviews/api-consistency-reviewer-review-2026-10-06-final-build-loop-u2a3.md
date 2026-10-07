Commit: cc1aa864

# API Consistency Review — feat/build-loop-u2a3 (final confirming pass, i3)

**Scope:** `git diff main...HEAD` (base 62d366a7, HEAD cc1aa864): the public surface of `scripts/lib/dev-cycle-read.sh` (`main_imports`, `isimported main`, `nul_list`, `IMPORTED_MAIN`, `IMPORTED_MAIN_DONE`, the lib header contract), plus the docs that restate it (plan F11/U2a3/U2b, known issue A5)
**Date:** 2026-10-06
**Based on:** the Stage 1 final fact-check summary (k=3: `code-fact-check-report-build-loop-u2a3-f-r1.md`, `-f-r2.md`, `-f-r3.md`), and this critic's iteration-2 report `api-consistency-reviewer-review-2026-10-06-build-loop-u2a3.md`

## Baseline Conventions

Read in full: the lib header (:1-36), `need_root`, `inrepo`/`inrepo_here`/`dirok`/`skipped` (:95-132), `main_by_name`/`main_entry`/`entry_why` (:254-310), `brief_fields` (:319-), `resolve_main` (:417-438), `lower`, `instruction_names`, `untracked_md`, `nul_list` (:484-519), `imported_names` (:520-536), `main_imports` (:537-617), and `isimported` (:618-633). For the nameref convention I also read `scripts/lib/si-morning-summary.sh:1525-1560`.

- **Names.** Functions are snake_case. Commit readers take a `main_` prefix and a noun (`main_by_name`, `main_entry`). Listing helpers are noun pairs (`instruction_names`, `untracked_md`, `imported_names`). Predicates are bare `is…` words. Globals are UPPER_SNAKE. A cached result comes as a pair: a value and a `_DONE` key.
- **Preconditions.** Exiting checks call `need_root` in the caller's shell. Commit readers check `main_by_name` first.
- **Failure reporting.** A refusal returns 1 and sets a global to the `error` sentinel (`BRIEF_ODD=error`, `main_entry` prints `error`). Readers that can name a reason do so (`BRIEF_ODD`, `main_entry`'s words, `SKIP_AT`). No function returns 2.
- **Fail-closed predicates.** When a predicate cannot answer, it answers the refusing way under `if`.
- **Out-parameters.** Until now, this lib returned results only through fixed globals. A caller-named nameref array has precedent elsewhere in `scripts/lib/`: `si-morning-summary.sh:1532,1555` uses function-prefixed local names to avoid collisions.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `main_imports` | function | `main_entry`, `main_by_name`, `imported_names` | `scripts/lib/dev-cycle-read.sh:254,270,520` | Consistent with the `main_` + noun family. The mismatch with `imported_names` is settled (earlier override row) |
| `main` (walk name for `isimported`) | parameter value | `tree` | `scripts/lib/dev-cycle-read.sh:629-630` | Consistent: a bare noun for what the walk reads |
| `nul_list` | function (helper) | `untracked_md`, `instruction_names`, `lower` | `scripts/lib/dev-cycle-read.sh:484,514,517` | Consistent: a short noun-pair helper with a one-line usage comment above it, as `untracked_md` has |
| `nul_list`'s `NAME` out-argument (`local -n nl_a`) | parameter | `_srf_out`, `arr_ref` | `scripts/lib/si-morning-summary.sh:1532,1555` | Consistent with the repo's nameref style (a prefixed local name). It is the first one in this lib. See finding 2 for its failure state |
| `IMPORTED_MAIN` | global (result) | `IMPORTED`, `BRIEF_ODD` | `scripts/lib/dev-cycle-read.sh:476,318` | Consistent: newline-framed and lower-cased like `IMPORTED`, with the `error` sentinel as in `BRIEF_ODD` |
| `IMPORTED_MAIN_DONE` | global (cache key) | `IMPORTED_DONE` | `scripts/lib/dev-cycle-read.sh:476` | Consistent. The key is now `SHA MAIN_BY_NAME ROOT`, and the reset contract is stated at :473-475 |

No naming findings.

## Status of iteration-2 findings (this critic)

- **1 (no reason word):** deferred to U2a4 under an override row (`IMPORTED_MAIN_WHY="KIND PATH"`). Not re-filed.
- **2 (header and not-covered wording):** fixed. The header (:31-35) now names all three checkout inputs, and "Not covered" (:465-469) no longer says "(link text is checked above)". This pass found new drift in the same header sentence; see finding 1.
- **3 (two-call protocol):** no action needed, as recommended.
- **4 (cache key and reset):** the contract is documented at :473-475, and `MAIN_BY_NAME` was added to the key. The checkout part is deferred under an override row. Not re-filed.

## Findings

#### 1. The header promises "the checkout can only add imports or fail it", but an untracked start file can remove a refusal

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:31-35` (header contract); behaviour at `:568-573` (starts marked seen) and `:609-614` (parent-link check after the seen test)
**Move:** 3 (consumer contract: documentation drift)
**Confidence:** High (the fact-check executed it; this critic did not re-run it)
**Legibility-target:** U2a4/U2b authors, who are told to read the lib header as the contract

Evidence, header (:31-35):
```
# writes), and so does main_imports (it also reads the checkout's untracked
# start files, imported files main lacks and whether a path it would read is a
# symlink there, which can only add imports or fail it, and
# needs resolve_main to have found main by name, or it fails);
```
Evidence, queueing (:609-614; excerpt ends :614, and the enclosing `while` loop and `main_imports()` continue to :617, which I read):
```
      [[ -z "${seen[$p]+set}" ]] || continue
      seen[$p]=1
      if [[ -n "${ent[$p]+set}" ]]; then queue+=("m:$p"); continue; fi
      # Main lacks p: under a directory link main stores (the checkout may lack it), fail.
      for (( c = ${#p}; c > 0; c-- )); do [[ "${p:c:1}" != / || "${ent[${p:0:c}]:-}" != 120000 ]] || { IMPORTED_MAIN=error; return 1; }; done
```
Starts are added to `seen` at :572 before the walk runs, so a start path skips the `continue` guard and never reaches the parent-link check. The final fact-check (r2 Claims 13, 18, 27, executed) built this case: main has `ld -> deep` and a CLAUDE.md holding `@ld/CLAUDE.md`. Main alone fails the walk. Adding a checkout where `ld` is a plain directory holding an untracked `ld/CLAUDE.md` makes the walk succeed, with `deep/CLAUDE.md` answered `-`. So the checkout turned a failure into "ok" and removed an import. The header is the one sentence a floor author will rely on to reason that the checkout cannot weaken the gate. The fact-check also found the header's input list narrower than the code (Mostly accurate): the walk also lstats link-text components and checks path types. It also found that a target under a mode-000 checkout directory reads as absent rather than failing (r2 Claim 19b), which contradicts "a checkout file it cannot read fails the walk" (block comment :465, A5, F11).

**Recommendation:** Prefer fixing the behaviour so the contract holds: run the parent-link check on start candidates too (:568-573). This is already escalated to the implementer by the fact-check. If that waits, narrow every copy of the sentence (header :34, e7b5d7ed's rationale in the block comment, A5, F11) to say starts are exempt. Decide whether "cannot read" covers an unsearchable directory, and word the four copies to match.

#### 2. `nul_list` does not say what the array holds when it returns 1

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:518-519`
**Move:** 3 (consumer contract), 8 (nullability)
**Confidence:** High (executed)
**Legibility-target:** U2a3b's author, who will reuse `nul_list` after rebasing

Evidence (whole unit):
```
# nul_list NAME CMD...: array NAME gets CMD's NUL-split output, or 1 unless CMD exited 0 (&& || keep errexit off).
nul_list() { local -n nl_a="$1"; shift; mapfile -d '' nl_a < <("$@" && printf rc=0 || printf rc=1); [[ ${#nl_a[@]} -gt 0 && "${nl_a[-1]}" == rc=0 ]] || return 1; unset 'nl_a[-1]'; }
```
Probe (scratch `/tmp/u2a3-api-i3-QNJB`, since removed; lib sourced from the worktree):
```
f rc=1 n=3 [a b rc=1]      <- CMD printed a\0b\0 and exited 3
g rc=1 n=2 [a brc=0]       <- CMD exited 0 without a trailing NUL: refused (good)
h rc=0 n=2 [a b]
empty rc=0 n=0
```
On failure the caller's array is overwritten with partial output plus the `rc=1` sentinel (or a record merged with `rc=0`). Both current callers (:556, :564) return 1 immediately, so this is safe today. Lib globals that carry a failure state document it (`IMPORTED_MAIN` reads "error" until a walk succeeds, and `BRIEF_ODD=error`). `nul_list`'s comment documents only the success case. A second caller in U2a3b that reads the array after an `||` arm, or that reuses an array name, would see the sentinel as a record. The refusal of a listing with no trailing NUL is a good, undocumented property: it is what "listed whole" means.

**Recommendation:** Add a few words to the comment, for example "on 1 NAME holds partial output; do not read it". Optionally clear the array (`nl_a=()`) before `return 1`. Either is a one-line change and can ride with U2a3b's reuse.

#### 3. The refusal list now differs across its four copies: the root and FIFO causes appear in only one

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:537-547` (return-1 comment) against `:458-466` (block comment), `docs/working/known-issues-dev-cycle.md:18` (A5), `docs/working/plan-build-loop-handoff.md:126` (F11), `:276` (U2a3 bullet)
**Move:** 3 (documentation drift)
**Confidence:** High (fact-check r3, and confirmed by reading all four)
**Legibility-target:** whoever acts on the override row stating "the three copies now agree"

Evidence, return-1 comment (:545-547):
```
# symlink, or a checkout path it would read exists but is neither a plain file
# nor a plain directory below the root (a symlink, under one, the root itself,
# a FIFO); need_root exits instead. Queue items are "m:PATH" or "t:PATH".
```
The block comment, A5, F11 and the U2a3 bullet end their lists at "a checkout symlink it would read". After c42f017f, the return-1 comment names the root and a FIFO; the other copies do not. Separately, the fact-check verified that an import of the repo root or of a FIFO fails the walk through the generic arm (the fix-drift lead's "no code" claim is refuted), so this is wording only. The earlier Won't-Fix override row (architecture F4-F6) rests on "the three copies now agree", which c42f017f made untrue for the refusal list.

**Recommendation:** Generalise the last item in the four copies to "a checkout path it would read that is not a plain file or directory (a symlink, under one, the root, a FIFO)". Alternatively, have them point at the return-1 comment as the full list.

## What Looks Good

- **`nul_list` is a well-shaped shared helper.** It has one job, a usage line in the `NAME CMD...` form, and a nameref with a prefixed local name, as in `si-morning-summary.sh`. It works with lib functions as CMD (`untracked_md`). It also enforces the "listed whole" rule both ways: a non-zero exit, and output that does not end in a NUL. Factoring it out of two copies before U2a3b reuses it is the right order.
- **The cache key is now complete for the walk's main-side inputs** (`$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL`), and the comment states it and the reset contract (:473-475).
- **The fail-closed shape is intact.** `IMPORTED_MAIN` is `error` at source time and at the start of each walk. Every `return 1` after `IMPORTED_MAIN=$'\n'` sets it back to `error` (:581, :583, :587, :591, :593, :598, :603, :614). The `nul_list` failures happen while it is still `error`. `isimported main` answers imported on failure, as `*)` does.
- **The process-substitution change keeps the interface the same** while removing the 64 KiB temp-file path for the import list (fact-check confirms the mutant is killed).
- **The sourcing inventory test** (`test/scripts/dev-cycle.bats:1086,1090`) covers `main_imports`, `IMPORTED_MAIN` and `IMPORTED_MAIN_DONE`. It does not list `nul_list`. A missing helper would still fail the walk tests, so this is a note, not a finding.
- **No existing consumer breaks.** `check_fix` still calls `isimported tree`, and `isimported main` has no caller before U2a4.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Header's "can only add imports or fail it" is false for untracked starts (fact-check r2, executed); input list and "cannot read" also narrower than the code | Minor | `scripts/lib/dev-cycle-read.sh:31-35, 568-573, 609-614` | High |
| 2 | `nul_list` leaves partial output plus the sentinel in the caller's array on return 1, undocumented | Informational | `scripts/lib/dev-cycle-read.sh:518-519` | High |
| 3 | Refusal list's root/FIFO causes appear in the return-1 comment only, not in the block comment, A5, F11 or the U2a3 bullet | Informational | `scripts/lib/dev-cycle-read.sh:458-466, 537-547`; A5; F11 | High |

## Overall Assessment

The public surface is consistent with the lib's conventions. Names extend the `main_*`, `IMPORTED*` and noun-pair helper families. `nul_list` follows the repo's nameref style. Preconditions, the `error` sentinel, fail-closed answers and the result format mirror `brief_fields`, `main_entry` and `imported_names`. All four iteration-2 findings are fixed or carry override rows. The one item worth acting on before merge is finding 1. Its consequence belongs to security and the implementer (already escalated by the fact-check): the header's guarantee that the checkout can only add imports or fail the walk is false for start-shaped paths. Either the behaviour or the sentence has to change, because U2a4's floor author will reason from that sentence. Findings 2 and 3 are one-line comment fixes that can ride with U2a3b or U2a4.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to docs/reviews/api-consistency-reviewer-review-2026-10-06-final-build-loop-u2a3.md, structured per the api-consistency-reviewer skill."
- **Answered:** Yes. Saved at that path with the skill's sections (Baseline, Name-Pattern Audit, Findings, What Looks Good, Summary Table, Overall Assessment) covering `main_imports`, `isimported main`, `nul_list`, `IMPORTED_MAIN`, `IMPORTED_MAIN_DONE` and the header contract at cc1aa864.
- **Out of scope:** the exploitability of the start-path bypass and of the unsearchable checkout directory (security/implementer, already escalated by the fact-check). The :596 link-text here-string and c42f017f's "read as no imports" wording (fact-check, commit-message row). Parser and `lower`/`grep` failure behaviour (fixed in U2a3b, stacked). The settled override rows (reason word, cache-ignoring-checkout, three-copies Won't-Fix, D8) are not re-filed. Finding 3 cites new evidence against the three-copies row.
- **Escalate:** Finding 1 to the implementer, with the fact-check's existing escalation. Fix the behaviour (parent-link check on starts) or narrow every copy of the header claim before U2a4 relies on it.
