Commit: e48cf0f7

# Security Review — feat/build-loop-u2a3b (final confirming pass, iteration 3)

**Scope:** `git diff main...HEAD -- scripts test docs/working` at e48cf0f7 (four commits). I read `import_targets`, `instruction_names`, `untracked_md`, `nul_list`, `tree_starts`, `imported_names`, `main_imports` and `isimported` in full (`scripts/lib/dev-cycle-read.sh:440-700`), and `check_fix` (`scripts/dev-cycle.sh:170-185`).
**Date:** 2026-10-06
**Based on:** the Stage-1 summary `fc-final-summary.md` (k=3: 0 Incorrect, wording-only Mostly accurate) and replicates `docs/reviews/code-fact-check-report-build-loop-u2a3b-final-r{1,2,3}.md`. Claude Code's grammar comes from `docs/reviews/security-reviewer-review-2026-10-06-final-build-loop-u2a2.md` and this unit's iteration-2 review.

**Threat model (from the brief).** The tree walk decides which docs an autonomous loop's in-cycle fix may edit (`--check-fix`). The main walk feeds U2a4's self-merge floor. A fail-open means Claude Code loads a file as instructions and a walk misses it. Over-reading only over-refuses.

**Method.** I used the same differential harness as before: the marked lexer extracted from Claude Code 2.1.292, with `reo` transcribed around it (copied read-only from `/tmp/u2a3b-sec-fQHv/{marked.js,cc.js}`). I ran it against `import_targets` at main (f6fdda68), at HEAD (e48cf0f7) and on a candidate fix. The work had three parts:
1. Handcrafted cases.
2. A random-document fuzzer: about 15,000 documents built from 70 Markdown fragments (`h/gen.js`, `h/ccall.js`, `h/walkall.sh`), giving roughly 3,600 names that Claude Code resolves.
3. End-to-end fixture repos (`h/e2e.sh`) running `dev-cycle.sh --check-fix` and `isimported main`.

Everything ran in `/tmp/u2a3b-secf-XcAr` (from `git archive`) under `timeout`, with `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 LC_ALL=C`. No background processes were started. With the candidate fix applied, all five suites passed (119/119; `TMPDIR=/tmp/u2a3b-secf-tmp-NadK`).

## Trust Boundary Map

```
B1: [instruction / imported file text (S1)]  → [import_targets: sed, HTML pass, grep IMPORT_RE, cut + strip] → [IMPORTED (tree) / IMPORTED_MAIN]
B2: [checkout listings (S2)]                 → [tree_starts via nul_list, newline-name guard]               → [tree walk start queue]
B3: [IMPORTED]                               → [isimported tree / check_fix]                               → [autonomous in-cycle doc edit (--check-fix ok)]
B4: [Claude Code 2.1.292 loader (S5)]        ⊆? [the parser's token set (S4)]                              → [fail-open iff not a superset]
B5: [main's blobs (S6)]                      → [import_targets (shared), main_imports]                     → [IMPORTED_MAIN → U2a4 self-merge floor]
B6: [host: tr / process faults (S7)]         → [main_imports batch lower + count guard (context)]          → [main walk start list]
```

| Label | Source | Mutability | Trust, by sink class |
|---|---|---|---|
| S1 | Text of every instruction file and imported file in the checkout | runtime-mutable (any commit, or an untracked file written by any same-uid process) | UNTRUSTED toward path construction and the imported/not-imported decision |
| S2 | `git ls-files -z`, `untracked_md` names | runtime-mutable | UNTRUSTED. Extra starts are safe; missing or colliding starts fail open |
| S3 | The `--check-fix` argument | request-time | UNTRUSTED. It passes `pathform` (letters, digits, `. _ - /`) |
| S4 | `IMPORT_RE`, `UNI_SPACES`, the cut set, the strip set, the HTML pass | code-constant | Trusted only as far as it is a superset of S5 |
| S5 | Claude Code 2.1.292's `reo` over marked (`gfm:false`) | external, version-dependent | The reference, executed from shipped bytes |
| S6 | main's committed blobs | runtime-mutable at every merge | As S1 |
| S7 | tr and the other host tools, process lifetime | host | Trusted for integrity. For availability they can fail, and a failure must fail closed |

**Summary.** This range makes `import_targets` keep Markdown marks inside a token and recover Claude Code's names through prefixes and a comment-splice pass. It also makes the tree walk fail closed. The fuzzer shows a large net gain: across six seeds, main misses 152-206 of the 301-398 names Claude Code resolves per seed, and HEAD misses 3-6 per seed. Two classes are still missing, and one of them is a regression this range introduced (F1). Every fix from iterations 1-2 that I re-ran holds (see "Prior findings re-checked").

## Findings

#### F1. A second import joined to the first by a Markdown token (`[@a](u)/[@b](v)`, `` @a`x`@b ``, `@a<br>@b`, `**@a**@b`, `@a<http://x>@b`, `@a![i](u)@b`) is never read. The grep swallows the second `@` into the first token. For links and code spans this regresses from main.

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:489` (`IMPORT_RE`) with `:529-547` (one name set per grep match); consumed at `scripts/dev-cycle.sh:183` (tree) and through `main_imports` (the U2a4 floor)
**Boundary:** B4, B1 → B3, B5
**Move:** 11 (bypass enumeration of the widened token), 2 (the implicit assumption that a token holds only one import start)
**Confidence:** High. Both sides were executed: the extracted lexer, and `--check-fix` plus `isimported main` end to end.
**Legibility-target:** for-author. The `import_targets` comment (`:500-503`) says each token "yields its whole and its part before each of [ ] ( ) < ! * _ and backtick". That covers only the token's prefixes, never a suffix that starts at an inner `@`.

Evidence (verbatim, `:489` and `:532`):
`IMPORT_RE='(^|[^[:alnum:]])@[^[:space:]\\#]+'`
`    t="${t#*@}"; n=$'\n'; cs=$'\n'; r="$t"`
(the second excerpt ends inside the token loop `:530-547`. The rest, read, walks `r` back through prefixes at each cut mark (`:534-546`) and never looks past the first `@`.)

`grep -o` reports matches that do not overlap. The token class now admits `` ` < > [ ] ( ) * _ ! ``, so `@docs/a.md](u)/[@docs/b.md](v)` is one match. Its second `@` cannot start a match of its own, and the prefix loop only shortens from the right. Marked ends a text token at the code span, inline HTML, autolink, link, image or emphasis. The next text token then begins with `@`, which Claude Code's `(?:^|\s)@` accepts as `^`. At main the regex stopped at `` ] ( ) ` ``, so the link and code-span shapes were read there.

Differential (`h/cmp.sh`, "miss" = names CC resolves that the walk does not list):

| Line | CC | main miss | HEAD miss |
|---|---|---|---|
| `[@docs/a.md](u)/[@docs/b.md](v)` | a, b | — | **b** (regression) |
| ``See @docs/a.md`x`@docs/b.md`` | a, b | — | **b** (regression) |
| `\| @docs/a.md<br>@docs/b.md \|` | a, b | a, b | b |
| `**@docs/a.md**@docs/b.md` | a, b | a, b | b |
| `See @docs/a.md<http://x>@docs/b.md` | a, b | a, b | b |
| `See @docs/a.md![i](u)@docs/b.md` | a, b | a | b |
| `_@docs/a.md_@docs/b.md` | a, b | a, b | b |

The fuzzer agrees: every HEAD miss across seeds 1-3 and 11-16 falls in this class or is the escaped-space shape (settled row 350, A5). Two fuzz rows are regressions against main.

End to end (`h/e2e.sh`). AGENTS.md holds `Read [@docs/a.md](u)/[@docs/b.md](v) first.` and ``See @docs/c.md`,`@docs/code_b.md …``, and `docs/b.md` holds `chain: @chained.md`:

| `--check-fix` / `isimported main` | main | HEAD | candidate |
|---|---|---|---|
| docs/b.md | skip / imported | **ok / -** | skip / imported |
| docs/code_b.md | skip / imported | **ok / -** | skip / imported |
| docs/chained.md (through b.md) | skip / imported | **ok / -** | skip / imported |

So an in-cycle fix may edit a file every session loads, together with everything that file imports. From U2a4 a branch could also self-merge a change to it.

**Recommendation:** Also tokenize every suffix that starts at an inner `@` preceded by a non-alphanumeric byte (an over-read). Tested candidate, in the token loop:
`q=("$t"); x="$t"; while [[ "$x" == *[^[:alnum:]]@* ]]; do x="${x#*[^[:alnum:]]@}"; q+=("$x"); done; for t in "${q[@]}"; do r="$t"; …existing prefix loop…; done`.
It closes every row above. The only fuzz misses left are escaped-space (A5). Add the link-pair and code-span lines to the "both walks read what Claude Code reads" fixture (`test/scripts/build-loop-check.bats:339`).

#### F2. The I2-A2 comment-splice pass pairs comments across the whole file, so a stray `<!--` earlier in the file (in a code block, a code span or plain text) shifts the splice. The spliced name then follows an alphanumeric byte and is not read.

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:519-526`
**Boundary:** B4, B1 → B3, B5
**Move:** 11 (bypass of the iteration-2 fix), 4 (the check and the use pair different spans)
**Confidence:** High for the mechanism (executed on both sides and end to end). Reaching it takes deliberately shaped instruction text, as with iteration 2's F2, which this residue belongs to.
**Legibility-target:** for-author. The comment at `:504-506` says text holding `<!--` is "read once more with every closed comment removed". Claude Code removes comments per HTML block, and the block's splice is confined to one line.

Evidence (verbatim, `:519-526`):
```
  if [[ "$toks" == *'<!--'* ]]; then
    x="$toks"; y=""
    while [[ "$x" == *'<!--'* ]]; do
      y+="${x%%'<!--'*}"; x="${x#*'<!--'}"
      if [[ "$x" == *'-->'* ]]; then x="${x#*'-->'}"; else x=""; fi
    done
    toks+=$'\n'"$y$x"
```
(the excerpt ends at `:525`. The rest of import_targets, read: `:526` closes the if, and `:529` greps the joined text.)

Claude Code runs `w.replace(/<!--[\s\S]*?-->/g,"")` on one HTML block's raw text only, and that block starts at a line start. The walk pairs the first `<!--` anywhere in the file with the next `-->`. Take this file:

````
```html
x<!--
```
<!-- note -->@docs/sec<!-- x -->ret.md
````

The walk removes the span from the fenced `x<!--` to `note -->`, which leaves `x@docs/sec` + `ret.md` = `x@docs/secret.md`. `IMPORT_RE` needs a non-alphanumeric byte before `@`, so the name is never read. Claude Code skips the code block, splices the HTML block alone and reads `docs/secret.md`. Executed with `h/cmp.sh` on four variants (stray `x<!--` in plain text, in a code span, across a blank line, in a fence): every one misses `docs/secret.md` at HEAD. End to end, the AGENTS.md above prints `ok docs/secret.md` from `--check-fix`, and `isimported main` answers `-`. A second, minor shape: the pass drops an unclosed `<!--` with all the text after it, while Claude Code keeps both. So `<!-- c -->@docs/sec<!-- x -->ret<!--.md` resolves to `docs/secret<!--.md`, and the walk misses it. Such a name can never pass `pathform`, so it matters only to the main walk.

**Recommendation:** Run the splice per line, which the block grammar makes a superset: a block's splice happens only on the line of its first `-->`. Remove each line's closed comments, and keep an unclosed `<!--` and the text after it. The tested candidate diff is in the Appendix. It closes every variant, including the iteration-2 case and the comment-in-blockquote, list and multi-line-opener cases (`c/m5-m9.md`), and passes 119/119.

## Context note (U2a3 code, not this unit's diff)

**N1 (Low, Confidence Low, B6; Legibility-target: for-orchestrator-synthesis).** `main_imports`' batch lower-casing, `scripts/lib/dev-cycle-read.sh:620-621` (`mapfile -d '' low < <(printf '%s\0' "${cand[@]}" | tr …)` then `[[ ${#low[@]} -eq ${#cand[@]} ]] || return 1`, from fbeae280 on main), checks the record count only. A tr that dies after a partial flush, with the cut inside the last record, leaves the count unchanged and truncates that name. Executed with a shim that cuts the batch output 3 bytes short and exits 1: `z/AGENTS.md` becomes `z/agents.`, the start is dropped, the walk reports ok, and `isimported main docs/a.md` answers `-`. Without the shim it answers `imported`. This needs a host fault, so it is Low. Route it to U2a3c or the backlog: list `low` through `nul_list` with a pipefail helper, so that a missing final NUL or a nonzero tr fails the walk.

## Escalation dispositions

- **Stage-1 → security-reviewer (r3, low): a failing tr makes `--check-fix` exit 1 with no output.** Executed with a `tr` shim that exits 1: `dev-cycle.sh --check-fix docs/b.md docs/a.md` printed nothing, and rc=1. The cause is `check_fix`'s own `lp="$(printf … | tr …)"` under `set -e` (`scripts/dev-cycle.sh:175`, pre-existing, not in the diff), which runs before the new walk-failed branch. Neither path prints `ok`, so this fails closed. No finding: the only difference is the missing wording, which is the fact-check's Mostly-accurate note.
- **Settled rows seen again, not re-filed:** the escaped space `\ ` (row 350, A5) is the only fuzz miss left once the candidate fixes are applied. No new evidence.

## Prior findings re-checked (all hold at e48cf0f7)

- **I2-A1 / iteration-2 F1 (cut only at the first mark):** fixed. Every iteration-2 row in `/tmp/u2a3b-sec-fQHv/cases` passes. The fuzzer finds no prefix-class miss.
- **I2-A2 / iteration-2 F2 (HTML-block splice):** fixed for the reported line. F2 above is a residue.
- **I2-A3 / iteration-2 F3 (newline start names):** `:571` returns 1 before any start is queued. The test is in the suite, and the fact-check executed it.
- **I2-C1 / iteration-2 F4 (here-string temp files):** `:529` and `:547` now use a pipe or a process substitution. Grep's status is checked separately (`|| [[ $? -eq 1 ]] || return 1`).
- **I2-A4 (check_fix wording):** `scripts/dev-cycle.sh:181` runs `imported_names` before `isimported`. On failure it prints a skip. The tr case is covered above.

## Untested bypass candidates

- **Claude Code versions other than 2.1.292, marked upgrades, or `gfm:true`.** These would change S5. Not testable here.
- **The `~/` filter.** The harness resolves `~/x` lexically, while Claude Code expands it to the home directory. The walk drops `~/`. I did not re-check this, because a home-directory path is outside the repo either way.
- **Front matter and other Claude Code pre-processing** (`cc.js` omits the front-matter strip, which only removes imports). Not run.
- **Nested repositories and submodules** (carried from U2a2 final).

## Endorsement Claims

- **Claim:** At e48cf0f7, for every name Claude Code 2.1.292 resolves in about 15,000 random documents built from 70 Markdown fragments, `import_targets` lists the name unless an inner `@` is swallowed (F1) or the name holds an escaped space (A5).
  **Location:** `scripts/lib/dev-cycle-read.sh:513-547`
  **Evidence:** executed
  **Verified:** `comm -23` of the CC and walk name sets, seeds 1-3 and 11-16, against the extracted lexer.
  **Not verified:** fragments outside the generator's alphabet (for example reference-link definitions with titles, or deeply nested containers), and the HTML-pass misalignment (F2, which the generator did not produce).
  **route: code-fact-check**
- **Claim:** With F1's and F2's candidate patches applied, the same corpus leaves only escaped-space misses, all five suites pass (119/119), and the e2e fixture refuses all seven paths in both walks.
  **Location:** the Appendix diff
  **Evidence:** executed
  **Verified:** `h/walkall.sh` on `fix/lib.sh`, `bats` on `fixtree`, `h/e2e.sh`.
  **Not verified:** the cost of the per-line pass and the suffix tokens on large files (a performance-reviewer question).
  **route: code-fact-check**

## Primitive sweep

Primitive: path construction from untrusted text (`realpath -ms`)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:539` (import_targets) | S1, S6 | `~/` and `/` skipped; `..`/`../*` dropped; lexical `-ms` | Cleared for resolution. The token set feeding it is F1 and F2 |
| `main_imports` symlink text (`:640-650`) | S6 | empty/absolute/newline/NUL/`..`-after-link refused | U2a3 context; unchanged |

Primitive: listing and lower-casing of names

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:568` `nul_list recs tree_starts` | S2 | rc=0 sentinel, pipefail inside tree_starts | Cleared (fact-check executed each failure kind) |
| `:571` newline guard | S2 | return 1 | Cleared |
| `:572` `lower` of start basename | S2 | `|| return 1` under pipefail | Cleared |
| `:620-621` batch tr + count guard | S2, S6 | count only | N1 (context) |

Primitive: file read

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `imported_names` `import_targets "$d" < "$f"` | S1, S2 | `inrepo_here` at queue time; status checked | Cleared |
| `main_imports` blob read | S6 | pipefail + status | Context, cleared by U2a3 |

No exec, eval, deserialization or network primitive is in scope.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | An inner `@` after a Markdown token is swallowed by the first token's match; the second import is never read (link/code-span shapes regress from main) | Medium | B4, B1→B3, B5 | `scripts/lib/dev-cycle-read.sh:489`, `:529-547` | High |
| F2 | The comment-splice pass pairs comments file-wide; a stray earlier `<!--` puts an alphanumeric byte before the spliced `@`, so the name is missed | Medium | B4, B1→B3, B5 | `scripts/lib/dev-cycle-read.sh:519-526` | High |
| N1 | (context, U2a3) The batch lower's count guard accepts a truncated last record | Low | B6 | `scripts/lib/dev-cycle-read.sh:620-621` | Low |

## Overall Assessment

This range is a large net security gain. Across seeds, the parser goes from missing about half of Claude Code's names (main) to about 1% (HEAD), and both walks now fail closed on every command failure the fact-check exercised. It is not yet a superset of Claude Code's loader, though. F1 is the most important fix: widening the token to keep Markdown marks lets the first match swallow a second import, so `[@a](u)/[@b](v)` and `` @a`x`@b `` now print `ok` for files main refused, in both walks, the U2a4 floor included. F2 is the remaining edge of the iteration-2 splice fix. Both are a few lines in the existing over-reading style, with tested candidates that keep 119/119. Neither is architectural. No findings beyond these within the code paths read; the endorsement claims are pending execution verification.

## Appendix: candidate patch (tested, not applied)

```diff
@@ import_targets() {
-  local t r v w p u n x y cs toks b=$'\x60' cut s=(-e 's/\x0/ /g')
+  local t r v w p u n x y z l rest cs q toks b=$'\x60' cut s=(-e 's/\x0/ /g')
@@
   if [[ "$toks" == *'<!--'* ]]; then
-    x="$toks"; y=""
-    while [[ "$x" == *'<!--'* ]]; do
-      y+="${x%%'<!--'*}"; x="${x#*'<!--'}"
-      if [[ "$x" == *'-->'* ]]; then x="${x#*'-->'}"; else x=""; fi
+    y=""; rest="$toks"$'\n'
+    while [[ -n "$rest" ]]; do
+      l="${rest%%$'\n'*}"; rest="${rest#*$'\n'}"
+      [[ "$l" == *'<!--'* ]] || continue
+      x="$l"; z=""
+      while [[ "$x" == *'<!--'* ]]; do
+        z+="${x%%'<!--'*}"; x="${x#*'<!--'}"
+        if [[ "$x" == *'-->'* ]]; then x="${x#*'-->'}"; else x="<!--$x"; break; fi
+      done
+      y+="$z$x"$'\n'
     done
-    toks+=$'\n'"$y$x"
+    toks+=$'\n'"$y"
   fi
@@
-    t="${t#*@}"; n=$'\n'; cs=$'\n'; r="$t"
+    t="${t#*@}"; n=$'\n'; cs=$'\n'; q=("$t"); x="$t"
+    while [[ "$x" == *[^[:alnum:]]@* ]]; do x="${x#*[^[:alnum:]]@}"; q+=("$x"); done
+    for t in "${q[@]}"; do r="$t"
@@
       r="${r%$cut*}"
     done
+    done
   done < <(printf '%s\n' "$toks")
```

Evidence files: `/tmp/u2a3b-secf-XcAr/` (`h/` harness and scripts, `c/` cases, `fz.*` fuzz corpora, `cc.*`/`wh.*`/`wm.*`/`wf.*` name sets, `fix/lib.sh`).

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A markdown report saved at the output path named in your role section below, structured per your skill, with a `Commit: e48cf0f7` line at the top.
- **Answered:** A final-pass security review of `main...HEAD`, executed against Claude Code 2.1.292's extracted lexer (handcrafted cases plus a fuzzer of about 15,000 documents) and end to end. It found two Medium fail-opens: F1, a partial regression from widening the token, and F2, a residue of the I2-A2 fix. Both have tested candidate fixes. It also records one context note (N1) and the disposition of the tr escalation.
- **Out of scope:** main_imports beyond the unit's lower guard (N1 is reported as context only), checkout-side reads (U2a3c), and settled rows 346/347/350/355/363 and this unit's 2026-10-06 rows.
- **Escalate:** F1 to this unit's fix loop, because it regresses main for link and code-span shapes and reaches the U2a4 floor. F2 to the same loop or to A5 (fix or defer).
