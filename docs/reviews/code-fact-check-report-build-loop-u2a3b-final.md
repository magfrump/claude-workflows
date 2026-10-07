# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2a3b (branch feat/build-loop-u2a3b)
**Commit:** e48cf0f7
**Replication:** k=3
**Scope:** `git diff main...HEAD -- scripts test docs/working` (comments, test names and test comments, known issue A5, plan row F11) and commit e48cf0f7's message; final confirming pass, merged from replicates r1, r2 and r3 (`code-fact-check-report-build-loop-u2a3b-final-r1.md`, `-r2.md`, `-r3.md`) by most-severe-wins
**Checked:** 2026-10-07 (UTC; replicates ran 2026-10-07T05:00Z-05:13Z)
**Total claims checked:** 51
**Summary:** 43 verified, 8 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Merge method. Claims were clustered across the three replicates on (file, line range within ±5 lines, substance) and emitted at the finest granularity any replicate used (decision 033). A replicate that verdicted only a compound claim is recorded on each sub-claim row as `(compound)`. Each row carries the most severe verdict any replicate assigned, with the evidence and `Scope:` of the replicate that assigned it (ties broken by the most specific `Scope:`, then by the lowest replicate number). Annotations (scope residues, caveats, placement notes, escalations) are the union across replicates. This is collation only: no claim or evidence below is new. Execution logs live in each replicate's scratch copy: r1 `/tmp/u2a3b-fcf1-kK2Z/logs/`, r2 `/tmp/u2a3b-fcf2-zUrB/logs/`, r3 `/tmp/u2a3b-fcf3-SR9y/logs/`. All three replicates read the hallucination-pattern log and found no matching pattern.

---

## Claim 1: "a name holding a backslash-escaped space (`@my\ notes.md`, which Claude Code reads as `my notes.md`; both walks end the token at the backslash)"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Legibility-target:** working doc
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parser's output and Claude Code 2.1.292's (harness) output for `@my\ notes.md`, and that both walks call the same parser. It does not establish Claude Code versions other than 2.1.292.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish Claude Code's behavior independently of that quote (not re-extracted here)" (r2 relied on the U2a2 review's quoted regex; r1 and r3 ran the 2.1.292 harness, and r3 also grepped the installed binary)

(r1) Claude Code's token regex is `/(?:^|\s)@((?:[^\s\\]|\\ )+)/g`, followed by `H.replaceAll("\\ "," ")` (`/tmp/u2a2f-sec-nefJ/cc.js:3`). The harness printed `my notes.md`. The parser's regex stops at any backslash: `IMPORT_RE='(^|[^[:alnum:]])@[^[:space:]\\#]+'` (`scripts/lib/dev-cycle-read.sh:489`). `import_targets` printed `my` for the same line. Both walks use that parser: `out="$(import_targets "$d" < "$f")"` (`:581`, tree) and `git cat-file blob "$MAIN_SHA:$f" | import_targets "$d"` (`:634`, main).

**Evidence:** `scripts/lib/dev-cycle-read.sh:489`, `:581`, `:634`; `/tmp/u2a3b-fcf1-kK2Z/logs/probe-parser.txt`; r3 `logs/cmp1.txt` (c02), `logs/reo-grep.txt`

---

## Claim 2: "Both walks share one token parser (`import_targets`) that follows Claude Code 2.1.292's import regex and Markdown lexer (U2a2 and U2a3b security reviews ...); revisit trigger: a Claude Code upgrade that changes either, which can make the walks miss imports."

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Legibility-target:** for-author
**Type:** Reference / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the shared parser, the version, the review citations and the bats pointer. Does not evaluate the revisit trigger's sufficiency, which is a judgement.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Mostly accurate (compound)
**Replicate annotations:** r3: its compound verdict covers the whole A5 sentence including the "`test/agents-gemini-sync.bats` pins another copy of the regex" clause (Claim 3); r3 states "'Both walks share one token parser' holds ... and both reviews are cited", and its Mostly-accurate rests on the pins clause · r1: "does not establish that the parser matches 2.1.292 on every input; Claims 9-13 check the shapes this branch names" · r2: "does not establish parity with Claude Code beyond the shapes those reviews executed (this replicate did not re-run Claude Code's lexer)"; r2 gave Medium confidence because "the 'follows' half rests on those reviews' differential runs"

(r3) "Both walks share one token parser" holds (`scripts/lib/dev-cycle-read.sh:581`, `:634`), and both reviews are cited. "pins another copy of the regex" is loose: `test/agents-gemini-sync.bats:50` holds a start-only finder `(^|[^[:alnum:]])@(\./|~/|/|[[:alnum:]._-])` written against v2.1.284 (`:37`), not a copy of the import regex. (r1) The U2a2 final security review says "I used Claude Code 2.1.292's real loader ... Function `reo` ... lexes the file with the bundled marked" (`docs/reviews/security-reviewer-review-2026-10-06-final-build-loop-u2a2.md:11`), and the U2a3b review says "the marked lexer extracted from Claude Code 2.1.292, with `reo` transcribed around it" (`docs/reviews/security-reviewer-review-2026-10-06-build-loop-u2a3b.md:11`).

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`; `test/agents-gemini-sync.bats:37-51`; `scripts/lib/dev-cycle-read.sh:581`, `:634`; `docs/reviews/security-reviewer-review-2026-10-06-final-build-loop-u2a2.md:11`; `docs/reviews/security-reviewer-review-2026-10-06-build-loop-u2a3b.md:11`

---

## Claim 3: "`test/agents-gemini-sync.bats` pins another copy of the regex" (A5)

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Legibility-target:** working doc
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the cited test file holds. It does not establish whether the two encodings should be merged; the architecture review advised against merging them.
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Mostly accurate · r3=Mostly accurate (compound)
**Replicate annotations:** r1: verdicted this pointer and its copy at `scripts/lib/dev-cycle-read.sh:512` as one claim (Claim 26 here) · r2: "does not establish whether the two encodings agree on any input"; r2 counts Claims 3 and 23 (this row and Claim 26) as "one finding at two locations" · r3: "Does not evaluate the revisit trigger's sufficiency"

(r1) The file holds a different, prefix-only finder regex: `grep -nE '(^|[^[:alnum:]])@(\./|~/|/|[[:alnum:]._-])'` (`test/agents-gemini-sync.bats:51`). Its comment documents it against "Claude Code v2.1.284" (`:37`). It shares IMPORT_RE's start condition `(^|[^[:alnum:]])@` but has no token body or end rules, and it is neither IMPORT_RE nor CC 2.1.292's `/(?:^|\s)@((?:[^\s\\]|\\ )+)/g`. The pointer's purpose holds: it names a second place to re-check on a Claude Code grammar change. The precise version: "test/agents-gemini-sync.bats holds a second, over-approximating encoding of Claude Code's import start rule (v2.1.284)". Comment/doc only.

**Evidence:** `test/agents-gemini-sync.bats:37-52`; `docs/reviews/architecture-review-review-2026-10-06-build-loop-u2a3b.md:48`

---

## Claim 4: F11 "a backslash-escaped space in a name ... The shared token parser follows Claude Code 2.1.292's grammar (U2a3b); a Claude Code upgrade that changes its import regex or Markdown lexer reopens this row."

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Legibility-target:** working doc
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the agreement between F11 and A5 and the shared parser. It does not establish the plan's other gap entries, which were unchanged by this branch.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish Claude Code parity beyond the security reviews' executed shapes (same residue as Claim 2)" (r2 confidence Medium) · r3: "'follows' holds with the gaps A5 lists"; r3 confirmed the installed package is 2.1.292 and its regex and `#` cut match the parser's model

(r1) The gap matches A5's new entry (Claim 1). The parser is shared (Claim 2). The sentence about reopening the row on an upgrade is a policy statement that agrees with A5's revisit trigger.

**Evidence:** `docs/working/plan-build-loop-handoff.md:126`; `docs/working/known-issues-dev-cycle.md:18`

---

## Claim 5: check_fix "skip $a: the instruction-file import walk failed, so an import of it cannot be ruled out; file it instead" (reached for every walk failure kind, in the caller's shell)

**Location:** `scripts/dev-cycle.sh:181-182`
**Legibility-target:** code comment (user-facing message)
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these walk failures under `--check-fix`: a failing git ls-files, a failing untracked_md, instruction_names' grep exiting 2, an unreadable start file, sed or the parser's grep failing, and a newline start name. It also covers the cache being shared with the following `isimported`. It does not cover a failing `tr`: check_fix never reaches the walk then, because the script exits 1 earlier with no output. That is fail-closed, but the message is not printed.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: with a failing `tr` the wording is never printed (r1: "the script exits 1 earlier with no output"; r2: "does not establish the wording for a failure in check_fix's own earlier `tr` (`:173`, not this unit's)"; r3: "`dev-cycle.sh --check-fix` exits 1 with no output before this branch is reached ... The likely cause is `check_fix`'s own `lp="$(printf '%s' "$a" | tr ...)"` (`:175`) under `set -euo pipefail` (`:83`); the exact exit line was not traced because the script re-execs through `scrub`") · r3: escalated the tr case to security-reviewer as advisory (see Escalations)

(r1) The branch is `elif ! imported_names; then echo "skip $a: the instruction-file import walk failed, ..."` followed by `elif isimported tree "$lp"; then` (`scripts/dev-cycle.sh:181-183`). check_fix is called directly from the dispatch loop: `--check-fix) check_fix "$a" ;;` (`:202`), not inside `$(...)`, so `IMPORTED_DONE` persists. Each of the seven failure kinds printed the skip line. A two-argument run printed it for both paths. The `tr` shim produced rc=1 with no output.

**Evidence:** `scripts/dev-cycle.sh:170-206`; `/tmp/u2a3b-fcf1-kK2Z/logs/probe-cf.txt`; r2 `/tmp/u2a3b-fcf2-zUrB/logs/p4.log`; r3 `logs/checkfix.txt`

---

## Claim 6: "imported_names and main_imports return 1 when the walk fails: call them under if or ||."

**Location:** `scripts/lib/dev-cycle-read.sh:18-19`
**Legibility-target:** code comment
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the return status of both walks on failure and that the production callers comply. It does not establish that test callers comply: `dev-cycle.bats:1176` calls `imported_names` bare under `set -e`, on a success path.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r3: `test/scripts/dev-cycle.bats:1176-1177` calls `imported_names` bare under `set -e`, only on a walk that succeeds · r2: "does not establish that every repository caller follows the advice (see Claim 8)" · r3: main walk's failure path covered "by the suite's tests 11 and 20", not by its own probe

(r1) imported_names returns 1 on every failure path (`:568`, `:571`, `:572`, `:581`, `:584`), and main_imports does too (for example `main_by_name || return 1`, `:607`). The production callers are `elif ! imported_names` (`scripts/dev-cycle.sh:181`), `imported_names || return 0` and `main_imports || return 0` (`:677-678`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:563-588`, `:601-666`, `:677-678`; `/tmp/u2a3b-fcf1-kK2Z/logs/probe-walk.txt`

---

## Claim 7: imported_names "returns 1, with IMPORTED set to "error", when the start listing (git ls-files, untracked_md, instruction_names), lower, a file read or the parser fails, or a start file's name holds a newline"

**Location:** `scripts/lib/dev-cycle-read.sh:451-453`
**Legibility-target:** for-orchestrator-synthesis
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named failure kind on a fixture repo: a corrupt index and a `git ls-files -z` shim (tracked listing), a git shim failing `--others` (untracked_md), a grep shim failing `-z` (instruction_names), a tr shim (lower), `chmod 000` on a start file and on an imported file (file read), a sed shim (parser), and a committed `a<NL>b/CLAUDE.md` (newline name). Does not establish a lower that fails on only some inputs.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish lower failing alone in the import loop (`:584`), which was read but not isolated, because tr also fails the start loop first" · r2: "does not establish behavior for failures inside inrepo_here/blocker (Claim 9 covers that they skip)"

(r3) Each case printed `1: failed rc` and `IMPORTED=[error]`. The code: `IMPORTED_DONE="$ROOT_REAL"; IMPORTED=error` then `nul_list recs tree_starts || return 1`, `[[ "$f" != *$'\n'* ]] || return 1`, `lp="$(lower "${f##*/}")" || return 1` (`:567-572`); `IMPORTED=$'\n'` is set only after the start loop (`:577`); `out="$(import_targets "$d" < "$f")" || { IMPORTED=error; return 1; }` (`:581`); `lp="$(lower "$p")" || { IMPORTED=error; return 1; }` (`:584`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:563-588`; r3 `logs/walk-fail.txt`; `/tmp/u2a3b-fcf2-zUrB/logs/p5.log`; `/tmp/u2a3b-fcf1-kK2Z/logs/probe-walk.txt`

---

## Claim 8: "(each call sits in an `if` or `||`, where set -e is off)"

**Location:** `scripts/lib/dev-cycle-read.sh:453`
**Legibility-target:** for-orchestrator-synthesis
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every call site of imported_names in scripts/ and test/; does not establish any behavior difference in the uncovered calls beyond exit-on-failure.
**Replicate verdicts:** r1=Verified (compound) · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r3: read the clause as covering "the failing calls inside imported_names and its two script callers" and "Does not cover the bare test call at `test/scripts/dev-cycle.bats:1176`, which runs only on a succeeding walk" · r1: notes the same bare test call in its Claim 5 scope ("`dev-cycle.bats:1176` calls `imported_names` bare under `set -e`, on a success path")

(r2) The production calls fit the claim: `elif ! imported_names` (`scripts/dev-cycle.sh:181`) and `imported_names || return 0` (`:677`), as do the build-loop-check.bats calls (`if imported_names`). Two test calls are bare under `set -euo pipefail`, though: `ROOT_REAL="$(pwd -P)"; imported_names; printf "%s" "$IMPORTED"` (`test/scripts/dev-cycle.bats:1176-1177`). They work because that walk succeeds. A precise version would read "each call in scripts/ sits in ...". Comment only.

**Evidence:** `scripts/dev-cycle.sh:181`; `scripts/lib/dev-cycle-read.sh:677`; `test/scripts/dev-cycle.bats:1176-1177`

---

## Claim 9: "an inrepo_here that fails skips its path"

**Location:** `scripts/lib/dev-cycle-read.sh:453-454`
**Legibility-target:** for-orchestrator-synthesis
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers start candidates and imported targets that fail inrepo_here; does not establish that a skipped imported target is left out of IMPORTED (it is recorded, by design, `:584`).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r3: "Does not establish what Claude Code does with a symlinked file (known issues A2 and A3)"; "The target's name is still recorded (`IMPORTED+="$lp"$'\n'`, `:584`), and only the walk into it is skipped"

(r2) Code: `if [[ ! "$lp" =~ $INSTRUCTION_FILE ]] || ! inrepo_here "$f"; then continue; fi` (`:574`) and `... && inrepo_here "$p"; then seen+=...; queue+=...` (`:585`). Executed: an untracked symlink `l/AGENTS.md` gives `symlinkstart rc0 IMPORTED=$'\ndocs/a.md\ndocs/b.md\n'`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:574`, `:585`; `/tmp/u2a3b-fcf2-zUrB/logs/p5.log`

---

## Claim 10: "One result is cached, for the root in IMPORTED_DONE; a call for another ROOT_REAL recomputes it, and a cached error returns 1 again."

**Location:** `scripts/lib/dev-cycle-read.sh:454-456`
**Legibility-target:** for-orchestrator-synthesis
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cached error surviving the removal of its cause, and recomputation after `IMPORTED_DONE` is cleared. The another-root half rests on the existing dev-cycle.bats test at `:1170-1180`, which passed.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish that any caller resets IMPORTED_DONE (none does)"

(r3) `[[ "$IMPORTED_DONE" == "$ROOT_REAL" ]] && { [[ "$IMPORTED" != error ]]; return; }` (`:566`). Probe: walk with a failing tr, then the real tr on the same root, then `IMPORTED_DONE=""`. Output: `shimmed: failed` / `unshimmed same root: failed (cached)` / `after reset: walked [|docs/a.md|]`. r1 and r2 ran the same sequence with the same result.

**Evidence:** `scripts/lib/dev-cycle-read.sh:566-567`; r3 `logs/cache.txt`; `/tmp/u2a3b-fcf1-kK2Z/logs/probe-cache.txt`; `/tmp/u2a3b-fcf2-zUrB/logs/p5.log`

---

## Claim 11: `IMPORTED=error` initially (no reader reads IMPORTED before imported_names runs; nothing treats "error" differently)

**Location:** `scripts/lib/dev-cycle-read.sh:481`
**Legibility-target:** code comment (initial value; commit claim "like IMPORTED_MAIN")
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every reader in scripts/ and test/. It does not establish external consumers outside this repo, and none is known.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—
**Replicate annotations:** r2: "does not establish behavior for an out-of-repo sourcer of the lib"; "`IMPORTED_DONE` starts as `""` while `need_root` guarantees a non-empty `ROOT_REAL`. So the initial `error` is never returned from the cache" · r3 (in its commit-message Claim 39 scope, a different location): "A lookup against `error` answers not-imported, the same as the old `$'\n'`"

(r1) `rg '\bIMPORTED\b'` outside docs finds these readers only: imported_names itself (`:566-584`), `isimported` after `imported_names || return 0` (`:678`), `dev-cycle.bats:1176-1177` after a call, and the sourcing test's `declare -p` (`dev-cycle.bats:1100`), which only checks that the variable is set. `scripts/build-loop.sh` does not reference it (paraphrased — no quote available because the claim covers absence of code: no matching grep results).

**Evidence:** `scripts/lib/dev-cycle-read.sh:481`, `:566`, `:678`; `test/scripts/dev-cycle.bats:1096-1100`, `:1176-1177`

---

## Claim 12: UNI_SPACES "end an import token as a blank does (import_targets makes each one a blank before it matches tokens): U+00A0, U+1680, U+2000-200A, U+2028/2029, U+202F, U+205F, U+3000 and U+FEFF (Claude Code's token ends at JavaScript's \s, which includes U+FEFF)"

**Location:** `scripts/lib/dev-cycle-read.sh:482-488`
**Legibility-target:** for-orchestrator-synthesis
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the array equals JavaScript's non-ASCII `\s` set and the sed-before-grep order. Does not cover ASCII `\s` members, which `[:space:]` in the C locale handles.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish JavaScript `\s` beyond the Unicode Zs set plus FEFF, 2028 and 2029, which is the ECMAScript definition" · r2: "does not establish behavior under a non-C locale (every call is `env LC_ALL=C`)"; r2's JS `\s` set is "paraphrased — no quote available because the source is the ECMAScript definition"

(r3) Node enumerates 19 non-ASCII `\s` code points, and their UTF-8 bytes equal the 19 `UNI_SPACES` entries byte for byte. `for u in "${UNI_SPACES[@]}"; do s+=(-e "s/$u/ /g"); done` and `toks="$(env LC_ALL=C sed "${s[@]}")"` (`:516-518`) run before the grep at `:529`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:486-488`, `:516-529`; r3 `logs/js-space.txt`; `/tmp/u2a3b-fcf1-kK2Z/logs/bats.txt`

---

## Claim 13: "A token may follow any byte but a letter or digit (so user@host is not one)" as a superset of Claude Code's start rule

**Location:** `scripts/lib/dev-cycle-read.sh:493-494`
**Legibility-target:** for-orchestrator-synthesis
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the start rule as an over-read of 2.1.292's `(?:^|\s)@`. The walk starts a token after any non-alnum byte, so it reads more than CC (`*@docs/e.md*` is found by both). Does not establish CC's later `EP(H)` filter, which the harness omits.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r3: its claim also quotes the UNI_SPACES comment (`:484-485`, Claim 12) · r1: `u@host.md a@b.md` gave no output · r2: `a@x.md` gives nothing, `x-@x.md` gives `x.md`

(r3) `IMPORT_RE='(^|[^[:alnum:]])@...'` (`:489`). The binary needs `^` or `\s` before `@`. In every differential case the walk's names include CC's, except the stated A5 escaped-space gap and the unrepresentable NUL name.

**Evidence:** `scripts/lib/dev-cycle-read.sh:489`, `:493-494`; r3 `logs/reo-grep.txt`, `logs/cmp1.txt`

---

## Claim 14: "it ends at a blank, a UNI_SPACES space included, or at a backslash, as the import token of Claude Code does, and at #, where Claude Code cuts the name it captured (so a token after a # is an over-read ...)"

**Location:** `scripts/lib/dev-cycle-read.sh:494-497`
**Legibility-target:** for-orchestrator-synthesis
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the token end against 2.1.292's regex (binary grep plus harness) for `\ `, `\b`, `\\` and `#`. Does not establish token ends for Claude Code versions other than 2.1.292.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1: "It does not establish the backslash-escaped-space case beyond what the comment itself defers to A5"; `x#@b.md` gave `b.md`, "which the CC harness does not yield (an over-read, as stated)" · r2: "does not establish Claude Code's behavior beyond that quote" (U2a2 review's quoted regex); tab, CR, VT and FF each separate tokens

(r3) `IMPORT_RE='(^|[^[:alnum:]])@[^[:space:]\\#]+'` (`:489`). The binary's regex is `(?:[^\s\\]|\\ )+`, then `H.indexOf("#")` cuts. Differential: `@docs/a#frag.md` gives CC `docs/a`, walk `docs/a`. `@docs/a\b.md` gives both `docs/a`. `@my\ notes.md` gives CC `my notes.md` and the walk `my`, which is the parenthetical's stated A5 gap.

**Evidence:** `scripts/lib/dev-cycle-read.sh:489`, `:494-498`; r3 `logs/cmp1.txt` (c01-c03, c17), `logs/reo-grep.txt`; `/tmp/u2a3b-fcf1-kK2Z/logs/probe-parser.txt`

---

## Claim 15: "a name holding a backslash-escaped space is not read, known issue A5"

**Location:** `scripts/lib/dev-cycle-read.sh:497-498`
**Legibility-target:** for-orchestrator-synthesis
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 1; does not establish more.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** none

(r2) Executed: `@my\ notes.md` gives `my` only. A5 lists the gap (`known-issues-dev-cycle.md:18`).

**Evidence:** `/tmp/u2a3b-fcf2-zUrB/logs/p1.log`; `docs/working/known-issues-dev-cycle.md:18`

---

## Claim 16: "That regex keeps brackets, parentheses, backticks and trailing punctuation in a name (@x.md. reads x.md.)"

**Location:** `scripts/lib/dev-cycle-read.sh:498-500`
**Legibility-target:** for-orchestrator-synthesis
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regex capture. Does not establish what the Markdown lexer leaves of such a name (Claim 17).
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** none

(r3) The binary's class `[^\s\\]` excludes no bracket, parenthesis, backtick or punctuation. The harness shows `@docs/a.md...` → CC `docs/a.md...` and ``@docs/q.md` `` → CC ``docs/q.md` `` (c11, c13).

**Evidence:** `scripts/lib/dev-cycle-read.sh:498-500`; r3 `logs/reo-grep.txt`; r3 `logs/cmp1.txt` (c11, c13)

---

## Claim 17: "so each token yields its whole and its part before each of [ ] ( ) < ! * _ and backtick, each also with trailing . , ; : ! ? * _ ~ ) ] or backticks stripped, each path once"

**Location:** `scripts/lib/dev-cycle-read.sh:500-504`
**Legibility-target:** for-orchestrator-synthesis
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every cut mark alone, repeated and mixed, and the strip set, per token. "each path once" holds per token only: `n=$'\n'` is reset for each token (`:532`), so the same path can print twice across tokens or across the HTML re-read copy (`docs/p` twice in `logs/cmp1.txt` c07). Both walks tolerate the duplicates.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: "each path once" is per token; `@a.md @a.md` prints `a.md` twice; r1: "The tree walk's `seen` (`:585`) and the main walk's `seen[$p]` (`:658`) make duplicates harmless"; r2: "the empty prefix is skipped" · r2+r3 (decisions): each chose the per-token reading as the natural one; r3 "recorded the cross-token duplicates in Scope rather than verdicting Mostly accurate"

(r3) `cut="[][()<!*_$b]"` (`:515`); `v="$r"; while [[ "$v" == *[.,\;:!?*_~\)\]] || "$v" == *"$b" ]]; do v="${v%?}"; done` (`:535`); `[[ "$r" == *$cut* ]] || break` / `r="${r%$cut*}"` (`:543-545`). Probes: `@a**b__c` → `a**b__c a**b_ a**b a* a`; `@x[a-z]y_z` → `x[a-z]y_z x[a-z]y x[a-z x`; `` @a`b `` → `` a`b a ``; `@!!!` → `!!! !! !`. Each pass strictly shortens `r`, so the loop ends.

**Evidence:** `scripts/lib/dev-cycle-read.sh:513-548`; r3 `logs/cut.txt`; `/tmp/u2a3b-fcf1-kK2Z/logs/probe-parser.txt`; `/tmp/u2a3b-fcf2-zUrB/logs/p1.log`

---

## Claim 18: The cut loop `[[ "$r" == *$cut* ]] || break; r="${r%$cut*}"` with the comments "the cut marks as a glob bracket (b: a backtick)" and "r walks back through the token's prefixes, one per cut mark"

**Location:** `scripts/lib/dev-cycle-read.sh:515`, `:533-545`
**Legibility-target:** for-orchestrator-synthesis
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both unquoted-pattern uses, the backtick and `!` members, and termination; does not establish behavior with `extglob` changing `!(`-style patterns (bash's `[...]` bracket is unaffected, and the lib does not set extglob).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r3: "Does not establish anything about the strip step (Claim 9)" (Claim 17 here)

(r2) An unquoted `$cut` is a pattern in both `[[ == ]]` and `${r%...}`. The bracket `[][()<!*_` + backtick + `]` takes the first `]` literally and `!` (not first) literally. Each pass removes at least the last mark, so `r` shrinks strictly and the loop ends. An empty `r` fails the test and breaks. Executed: the `!`, `*`, `_`, `<`, `(`, `)`, `[`, `]` and backtick prefixes all appear, so no prefix is dropped. (r1) `@a[b]c(d)e<f!g*h_i`j.md` yielded 10 names, one per mark.

**Evidence:** `scripts/lib/dev-cycle-read.sh:515`, `:533-546`; `/tmp/u2a3b-fcf2-zUrB/logs/p1.log`; r3 `logs/cut.txt`

---

## Claim 19: "Claude Code deletes the HTML comments of a block that opens with <!-- and reads what is left, so text holding <!-- is also read once more with every closed comment removed."

**Location:** `scripts/lib/dev-cycle-read.sh:504-506`
**Legibility-target:** code comment
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the re-read copy for one comment, several comments, a comment spanning lines, and an unclosed `<!--`, and covers the claim that the re-read cannot suppress a name. It does not establish behavior for names that themselves contain `<!--`.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: CC splices only a block that both opens with `<!--` and holds `-->`; the code's re-read also drops everything after an unclosed `<!--`; no name is lost because the first copy is still read · r2+r3: a block with an unclosed comment is not read at all by CC (r3: "skipped whole", `<!-- unclosed\n@docs/u.md` → CC reads nothing, c16) · r1: "The only divergence found is a name that holds `<!--` itself (CC `docs/xy.md<!--zz`; parser `docs/xy.md`)"; r1 explicitly did not file this to security-reviewer: "outside any pathform-allowed name; noted for completeness, not filed" · r2: "does not establish a fail-open (the first copy is still read, Claim 19)" · r3: "Does not establish block boundaries for HTML kinds other than comments"

(r1) The re-read loop is `while [[ "$x" == *'<!--'* ]]; do y+="${x%%'<!--'*}"; x="${x#*'<!--'}"; if [[ "$x" == *'-->'* ]]; then x="${x#*'-->'}"; else x=""; fi; done; toks+=$'\n'"$y$x"` (`:521-525`). It removes every closed comment, and also every byte after an unclosed `<!--` (`x=""`). Claude Code applies the splice only when the block also contains `-->`: `if(H.startsWith("<!--")&&H.includes("-->")){let z=w.replace(/<!--[\s\S]*?-->/g,"")` (`cc.js:3`). Executed: `@a<!-- x -->b<!-- y -->c.md` yields `abc.md`. In `<!-- c --> see @docs/q.md <!-- z @docs/t.md`, CC reads `docs/t.md` from the unclosed tail; the re-read copy drops it, but the first copy still yields it, because the re-read is appended (`toks+=`). The precise version: "read once more with every closed comment, and any unclosed comment's tail, removed". Comment/doc only.

**Evidence:** `scripts/lib/dev-cycle-read.sh:519-526`; `/tmp/u2a3b-fcf1-kK2Z/logs/probe-parser.txt`; `docs/reviews/security-reviewer-review-2026-10-06-build-loop-u2a3b.md:92`; r3 `logs/cmp1.txt` (c06-c08, c15, c16)

---

## Claim 20: "A NUL counts as a blank."

**Location:** `scripts/lib/dev-cycle-read.sh:506`
**Legibility-target:** for-orchestrator-synthesis
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk's rule. It is not a claim about Claude Code, which does not treat NUL as `\s` (CC reads `docs/a.md\0@docs/b.md` as one name, which no path can hold).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish anything about NUL in symlink text (main_imports refuses that separately)"

(r3) `s=(-e 's/\x0/ /g')` (`:514`). `x @docs/a.md\0@docs/b.md` → walk `docs/a.md docs/b.md` (c09).

**Evidence:** `scripts/lib/dev-cycle-read.sh:514`; r3 `logs/cmp1.txt` (c09); `/tmp/u2a3b-fcf2-zUrB/logs/p1.log`

---

## Claim 21: "Over-reading only over-refuses." (the re-read copy cannot suppress a name the first copy yields)

**Location:** `scripts/lib/dev-cycle-read.sh:506-507`
**Legibility-target:** for-orchestrator-synthesis
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim that the re-read copy cannot suppress a name the first copy yields; does not establish that every over-read name is harmless to a caller other than the walks (none exists).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "It does not establish over-refusal costs, which are settled override rows"; "In the main walk an extra name can only add a queue entry or fail the walk (`:660-663`), and both refuse more"

(r2) The re-read is appended, not substituted: `toks+=$'\n'"$y$x"` (`:526`). The grep and the token loop then emit the union of both copies' tokens, and nothing in the loop removes earlier output. Executed: in the unclosed case, `tail.md` and `q.md` still come out (from the first copy), so the re-read suppressed nothing.

**Evidence:** `scripts/lib/dev-cycle-read.sh:520-547`; `/tmp/u2a3b-fcf2-zUrB/logs/p1.log`

---

## Claim 22: "~/ and absolute paths, and paths leaving the repo (.. or ../, not a ..x name), are dropped."

**Location:** `scripts/lib/dev-cycle-read.sh:507-508`
**Legibility-target:** code comment
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `~/`, `/`, `../`, `a/../../`, `..`, `~x` and `..x`. It does not establish symlink-relative resolution, a settled A5 item.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "Does not cover absolute imports into the repo, which A5 lists as a gap"

(r1) The filters are `[[ -n "$w" && "$w" != \~/* && "$w" != /* ...` (`:537`) and `[[ "$p" != .. && "$p" != ../* ...` (`:540`). `@~/x.md @~x.md @/abs.md @../up.md @..x.md @a/../../b.md @..` yields only `~x.md` and `..x.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:537-540`; `/tmp/u2a3b-fcf1-kK2Z/logs/probe-parser.txt`

---

## Claim 23: "It reads ROOT_REAL without checking it (the caller has run need_root)"

**Location:** `scripts/lib/dev-cycle-read.sh:508-509`
**Legibility-target:** for-orchestrator-synthesis
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both script callers. Does not cover direct test calls of import_targets, which set ROOT_REAL themselves.
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=Verified
**Replicate annotations:** none

(r3) import_targets has no `need_root`. Its only script callers are imported_names (`need_root` at `:565`, call at `:581`) and main_imports (`need_root` at `:604`, call at `:634`) (paraphrased — no quote available because the claim covers absence of other callers; `grep -rn import_targets scripts` lists only `:513`, `:581`, `:634`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:513-548`, `:565`, `:581`, `:604`, `:634`

---

## Claim 24: "and returns 1 when sed or grep fails"

**Location:** `scripts/lib/dev-cycle-read.sh:509`
**Legibility-target:** for-orchestrator-synthesis
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a sed shim exiting 4, a directory as stdin (sed read error, the suite's test 20), and a grep shim exiting 2 on `-ao`, each with and without matches. Does not cover a realpath failure, which skips the name (`|| continue`, `:539`) by design.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: realpath failures skip a name rather than returning 1, which the comment does not claim

(r3) `toks="$(env LC_ALL=C sed "${s[@]}")" || return 1` (`:518`) and `... | env LC_ALL=C grep -aoE "$IMPORT_RE")" || [[ $? -eq 1 ]] || return 1` (`:529`). Grep shim: `grepfail rc=1` for a file with an import and one without. Real grep: `normal rc=0` for both.

**Evidence:** `scripts/lib/dev-cycle-read.sh:518`, `:529`; r3 `logs/grepfail.txt`, `logs/walk-fail.txt` ("shim sed")

---

## Claim 25: "The rules follow Claude Code 2.1.292's import regex and Markdown lexer (U2a2 security review); re-check them when Claude Code changes either"

**Location:** `scripts/lib/dev-cycle-read.sh:509-511`
**Legibility-target:** for-author
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the version (the installed package is 2.1.292 and its binary holds the regex) and the two pointers. Does not establish the rules for other Claude Code versions.
**Replicate verdicts:** r1=— · r2=Verified · r3=Mostly accurate (compound)
**Replicate annotations:** r3: its compound claim also covers the pins-copy pointer at `:512` (Claim 26); its finding (b) on this row is the review citation · r2: "Same residue as Claim 2" (does not establish CC parity beyond the security reviews' executed shapes); r2 confidence Medium; r2: "The cut set covers marked's non-gfm stop set ``[\\<!\[`*_]`` ... plus `]`, `(` and `)` as over-reads"

(r3) The version is right: `"version": "2.1.292"`, and the binary holds `/(?:^|\s)@((?:[^\s\\]|\\ )+)/g`. (b) The HTML-comment rule comes from the U2a3b security review (F2), not the U2a2 one. A5 cites both reviews, but this comment cites only U2a2. Precise version: "(U2a2 and U2a3b security reviews)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:509-512`; `docs/reviews/security-reviewer-review-2026-10-06-final-build-loop-u2a2.md:11`; `docs/reviews/security-reviewer-review-2026-10-06-build-loop-u2a3b.md:83-96`; r3 `logs/reo-grep.txt`

---

## Claim 26: "(test/agents-gemini-sync.bats pins another copy of the regex)"

**Location:** `scripts/lib/dev-cycle-read.sh:512`
**Legibility-target:** code comment
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the cited test file holds. It does not establish whether the two encodings should be merged; the architecture review advised against merging them.
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Mostly accurate · r3=Mostly accurate (compound)
**Replicate annotations:** r1: verdicted this and the A5 copy (Claim 3) as one claim · r2: "Claims 3 and 23 are one finding at two locations" · r3: compound with the 2.1.292/U2a2 sentence (Claim 25)

(r1) The file holds a different, prefix-only finder regex: `grep -nE '(^|[^[:alnum:]])@(\./|~/|/|[[:alnum:]._-])'` (`test/agents-gemini-sync.bats:51`), documented against "Claude Code v2.1.284" (`:37`). It is neither IMPORT_RE nor CC 2.1.292's regex. The pointer's purpose holds: it names a second place to re-check on a Claude Code grammar change. Comment/doc only.

**Evidence:** `test/agents-gemini-sync.bats:37-52`; `docs/reviews/architecture-review-review-2026-10-06-build-loop-u2a3b.md:48`

---

## Claim 27: "Two steps, not a pipe: under pipefail grep's "no match" would hide a sed failure."

**Location:** `scripts/lib/dev-cycle-read.sh:517`
**Legibility-target:** code comment
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash's pipefail status rule as used with `|| [[ $? -eq 1 ]]`. It does not establish other shells.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish anything about grep's own SIGPIPE behavior" · r3: "Does not cover callers without pipefail, where a piped sed's failure would be invisible anyway"

(r1) Under pipefail the pipeline status is the rightmost non-zero one: `set -o pipefail; (exit 4) | (exit 1); echo $?` prints `1`. A `sed | grep` pipe followed by `|| [[ $? -eq 1 ]]` (`:529`'s form) would therefore accept a sed failure.

**Evidence:** `scripts/lib/dev-cycle-read.sh:517-529`; `/tmp/u2a3b-fcf1-kK2Z/logs/probe-herestring.txt`

---

## Claim 28: "A pipe, not a here-string: bash writes a long here-string to a temp file, and a failed write would read as "no match"."

**Location:** `scripts/lib/dev-cycle-read.sh:527-528`
**Legibility-target:** code comment
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15 with a write that fails with an error (EFBIG with SIGXFSZ ignored). It does not cover a default-disposition `ulimit -f` breach: there SIGXFSZ kills the shell (rc 153) rather than producing "no match", which is still fail-closed.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: does not establish other bash builds' threshold · r2+r3: a here-string mutant of `:529` fails the suite (r2: tests 11 and 20; r3: `test/scripts/build-loop-check.bats:385`)

(r1) With 66000 bytes or more, `trap '' XFSZ; ulimit -f 0` and `grep -aoE "$IMPORT_RE" <<<"$toks"` print `cannot create temp file for here-document: File too large` and `rc=1 []`. At 60000 and 65000 bytes the here-string goes through a pipe and finds the import. The pipe form returns `docs/big.md`, rc 0, under `ulimit -f 0`. (r2 measured the threshold at 65536 bytes.)

**Evidence:** `scripts/lib/dev-cycle-read.sh:527-529`; `/tmp/u2a3b-fcf1-kK2Z/logs/probe-herestring.txt`; `/tmp/u2a3b-fcf2-zUrB/logs/mut-herestring.log`; r3 `logs/mutant-m2.txt`

---

## Claim 29: instruction_names "returns 0 when no name matches and 1 when grep fails (grep's own no-match is 1)"

**Location:** `scripts/lib/dev-cycle-read.sh:552-554`
**Legibility-target:** code comment
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exit 1 (no match) mapped to 0 and exit 2 mapped to 1, and NUL-terminated output for `nul_list`. It does not establish grep exits above 2, which map to 1 the same way.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "Does not cover grep killed by a signal (status above 128, also returned as 1)"

(r1) The function is `env LC_ALL=C grep -zaiE '...' || [[ $? -eq 1 ]]` (`:554`). A grep `-z` shim exiting 2 made the walk fail (probe and suite). The baseline repos with no other instruction file still walk `ok`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:554`, `:559`; `/tmp/u2a3b-fcf1-kK2Z/logs/probe-walk.txt`; r3 `logs/instruction-names.txt`

---

## Claim 30: nul_list's "output empty or ended in NUL" rule holds for instruction_names' output (as used by tree_starts)

**Location:** `scripts/lib/dev-cycle-read.sh:558`
**Legibility-target:** for-orchestrator-synthesis
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers GNU grep -z output framing; does not establish other grep implementations.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: covered in its instruction_names claim ("`grep -z` ends each output record with a NUL, so nul_list's 'empty or ended in NUL' rule holds") · r3: covered in its tree_starts claim ("each record NUL-terminated, empty output gives `rc=0` alone")

(r2) `grep -z` ends every output record with NUL. Executed: `a/Claude.MD\0` is shown NUL-terminated, and tree_starts' output `C L A U D E . m d \0` likewise. An empty output passes. A non-zero exit empties the array (`nul_list ... printf rc=1`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:558`, `:562`; `/tmp/u2a3b-fcf2-zUrB/logs/instrnames.log`, `/tmp/u2a3b-fcf2-zUrB/logs/p5.log`

---

## Claim 31: tree_starts "tracked and untracked names through instruction_names, failing when any of the three commands fails"

**Location:** `scripts/lib/dev-cycle-read.sh:560-562`
**Legibility-target:** code comment
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each of the three failing alone. It does not establish that pipefail leaks to the caller: `local -` restores it, and nul_list runs it in a process substitution.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: a git shim failing on `--others` gives `rc=128` and "its partial output `CLAUDE.md\0` is still printed, so the nul_list rc check is what rejects it"; "does not establish behavior when tree_starts is called outside nul_list (no caller does)" · r3: "Does not cover a listing that succeeds with wrong content"

(r1) The function is `tree_starts() { local -; set -o pipefail; { git ls-files -z && untracked_md; } | instruction_names; }` (`:562`). A git ls-files shim, a git `--others` shim and a grep `-z` exit-2 shim each gave `walk failed IMPORTED=error`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:559-568`; `/tmp/u2a3b-fcf1-kK2Z/logs/probe-walk.txt`

---

## Claim 32: "seen is newline-separated: a name holding a newline could hide another start."

**Location:** `scripts/lib/dev-cycle-read.sh:570`
**Legibility-target:** code comment
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the guard at `:571` and the suite case `a\nb/CLAUDE.md` with `b/CLAUDE.md`. It does not establish newlines in imported (non-start) names, which `lower` and `seen` treat line-wise; the parser's grep emits no newline inside a token.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "Does not cover main_imports, which has its own newline check (`:612`, `:618`)"

(r1) The guard is `[[ "$f" != *$'\n'* ]] || return 1` (`:571`). The suite test (`build-loop-check.bats:368-370`) and the probe `newline start name` both fail the walk.

**Evidence:** `scripts/lib/dev-cycle-read.sh:569-576`; `/tmp/u2a3b-fcf1-kK2Z/logs/probe-walk.txt`

---

## Claim 33: isimported "A failed walk, a failed lower of $2, or a walk name that is neither answers imported (0) ...; a caller that words a failed walk runs the walk first (imported_names or main_imports, under if)."

**Location:** `scripts/lib/dev-cycle-read.sh:667-671`
**Legibility-target:** code comment
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all three branches and check_fix as the wording caller. It does not establish a main-walk wording caller, which does not exist yet (U2a4).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish that U2a4's future floor follows the 'runs the walk first' advice" · r3: "Does not separate a lower failure of $2 from a walk failure in one run, because a tr shim fails both"; the main branch "rests on the suite"

(r1) The function body is `lp="$(lower "$2")" || return 0` with `main) main_imports || return 0; ...`, `tree) imported_names || return 0; ...` and `*) return 0 ;;` (`:675-679`). The tr-shim test prints `docs/z.md imported` for both walks, and the bogus-name test prints `bogus: imported`. check_fix calls `imported_names` before `isimported` (`scripts/dev-cycle.sh:181-183`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:672-681`; `scripts/dev-cycle.sh:181-183`; `/tmp/u2a3b-fcf1-kK2Z/logs/bats.txt`

---

## Claim 34: imps "walk: ok" or "walk: failed" "(main_imports' or imported_names' return)"

**Location:** `test/scripts/build-loop-check.bats:14`
**Legibility-target:** test name/comment
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the helper's walk line. It does not establish anything for other walk names, which print `walk: failed`.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** none

(r1) The helper line is `if { [[ "$w" == main ]] && main_imports; } || { [[ "$w" == tree ]] && imported_names; }; then echo "walk: ok"; else echo "walk: failed"; fi` (`:20`).

**Evidence:** `test/scripts/build-loop-check.bats:13-22`

---

## Claim 35: tree-walk test comments "Two NBSPs in one run: the token ends at the first. docs/z.md is imported only after the NUL; gone/ does not exist, and the path is still resolved as written." / "Docs/NB.MD and CLAUDE.md: isimported takes a path in any case."

**Location:** `test/scripts/build-loop-check.bats:28-36`
**Legibility-target:** for-orchestrator-synthesis
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fixture's shapes (test 1 passes). The second NBSP follows `for`, not a token, so this test does not show that a second NBSP becomes a blank. Test 4 shows that instead (mutant m4 fails test 4 and passes test 1, `logs/mutant-m4.txt`).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1: "It does not establish that `docs/nb.md.` asserts `-`, which is read from the call (`imps tree "${ps[@]}" docs/other.md docs/nb.md.`) and not from this comment" · r2: "does not establish more than the fixture's shapes"

(r3) The fixture holds `@docs/nb.md\xc2\xa0for\xc2\xa0you`, `@gone/../docs/m.md` and `@docs/a.md\0 then @docs/z.md` (`:31`), and `ps` holds `docs/z.md docs/m.md Docs/NB.MD CLAUDE.md` (`:38`), all wanted imported.

**Evidence:** `test/scripts/build-loop-check.bats:26-41`; r3 `logs/suites.txt`, `logs/mutant-m4.txt`

---

## Claim 36: "Without ROOT_REAL it stops (need_root) for any walk name, before answering."

**Location:** `test/scripts/build-loop-check.bats:47`
**Legibility-target:** test name/comment
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers isimported with the bogus name (need_root is its first statement). It does not establish other entry points.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r3: "Does not separately run tree or main without ROOT_REAL"

(r1) isimported starts with `local lp` and then `need_root` (`lib :673-674`). The test asserts status 1, empty output and `ROOT_REAL is not set` (`:50`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:672-675`; `test/scripts/build-loop-check.bats:47-50`

---

## Claim 37: test "both walks: every Unicode space JavaScript's \s holds ends a token; SKILL.md starts them; an untracked upper-case .MD starts the tree walk (U2a3b)"

**Location:** `test/scripts/build-loop-check.bats:53-70`
**Legibility-target:** test name/comment
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each clause. It does not establish that the main walk accepts an untracked start (by design it fails closed until U2a3c, as the comment at `:65` says).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: covers "the 19 non-ASCII spaces (the ASCII ones are covered at `:28-41`)"; main's fail-closed rule is `[[ "${cand[i]:0:1}" == m ]] || return 1` (`dev-cycle-read.sh:625`) · r3: mutant m3 (no `skill` in INSTRUCTION_FILE) fails this test with `want: docs/u0.md: imported`

(r1) `sub/SKILL.md` is the only instruction file in the fixture (`bl_setup` and `commit_all` add none: `commit_all() { git add -A && git commit -q --allow-empty -m "${1:-fixture}"; }`, `test/lib/build-loop-fixtures.bash:28`). Each `docs/uN.md` is imported on main and tree only if the space ended the token. `docs/k.md` is reachable only from the untracked `docs/AGENTS.MD` (`:66`).

**Evidence:** `test/scripts/build-loop-check.bats:53-70`; `/tmp/u2a3b-fcf1-kK2Z/logs/bats.txt`; r3 `logs/mutant-m3.txt`

---

## Claim 38: test "both walks read what Claude Code reads: an @ after a Unicode space, Markdown and a code span around a token, ( ) in a name; ~x is over-read, ~/ dropped" and its comments (a cut mark earlier in the name does not hide a later one; two NBSPs on a line both become blanks; an HTML block's comment splices a name)

**Location:** `test/scripts/build-loop-check.bats:339-355`
**Legibility-target:** test name/comment
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed case on both walks (the suite passes) and that the cases discriminate. A cut only at the first mark yields `docs/my` rather than `docs/my_notes.md`, and a bare token without the comment splice misses `docs/secret.md`. It does not establish CC parity for shapes outside this corpus.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: mutant m4 (`s/$u/ /` without `g`) fails this test with `want: docs/q.md: imported`; the CC harness confirms `docs/secret.md` and `docs/my_notes.md` are what 2.1.292 reads for these shapes · r3: the test's "(U2a3)" unit tag noted as a label (Claim 39)

(r1) The cases are `@docs/my_notes.md\x60c\x60`, `@docs/p.md\xc2\xa0@docs/q.md\xc2\xa0@docs/r.md` and `<!-- note --> See @docs/sec<!-- x -->ret.md` (`:344-345`). `'~/x.md'` asserts `-` (`:353`). If `~/` were not dropped, the literal path `~/x.md` would be recorded and matched.

**Evidence:** `test/scripts/build-loop-check.bats:339-355`; `/tmp/u2a3b-fcf1-kK2Z/logs/probe-parser.txt`; r3 `logs/mutant-m4.txt`

---

## Claim 39: the "(U2a3)" unit tags on the two tests this branch adds

**Location:** `test/scripts/build-loop-check.bats:339`, `:357`
**Legibility-target:** test name/comment
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers which unit added the tests. It does not establish whether the tag is meant as the U2a3 family name.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r3: "The unit tag reads '(U2a3)' although the test was added on this branch (U2a3b), unlike the branch's other new tests, which read '(U2a3b)'. That is a label, not a behavioral claim"; r3 decision: "Treated the '(U2a3)' unit tags on two new test names as labels, noted in Claims 29-30, not verdicted" · r2: verdicted the test names including the tag without comment on it

(r1) Both tests are absent from main's file (`git show main:test/scripts/build-loop-check.bats` lists neither name). `git log -S'both walks read what Claude Code reads'` gives `43b9edb6 fix(dev-cycle-read): ... (U2a3b)`. The sibling test added by the same branch is tagged `(U2a3b)` (`:53`). The precise tag is "(U2a3b)". Comment/doc only, Low.

**Evidence:** `test/scripts/build-loop-check.bats:53`, `:339`, `:357`

---

## Claim 40: test "both walks fail closed when tr fails; the tree walk fails closed when its start listing fails or a start name holds a newline; the parser returns 1 when it cannot read its input", with comments "A grep that fails on the start listing (instruction_names, grep -z) only" and "An untracked start under a directory whose name holds a newline: b/X.md would read as seen"

**Location:** `test/scripts/build-loop-check.bats:357-371`
**Legibility-target:** test name/comment
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each clause and its discrimination. The nul_list-ignoring mutant fails this test (Claim 50), and the newline case would print `-` without the `:571` guard, because `a\nb/CLAUDE.md` sorts first and puts `\nb/CLAUDE.md\n` into `seen`. It does not establish the cache claim at `:372` (Claim 41).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not cover main_imports' new import-loop lower guard (`:657`), since main fails at its start-list `tr` first" (also escalated, see Escalations) · r3: "`imps` now calls `imported_names` itself, so the tree half's 'walk failed' is the walk's own failure, which closes iteration 2's Claim 12 caveat"; same "(U2a3)" label note as Claim 39

(r1) The grep shim matches only `-z*` as `$1` (`:364`). Only instruction_names calls `grep -zaiE` in the tree walk, and the parser calls `grep -aoE`. `import_targets "" < docs` reads a directory, sed fails, and the test prints `failed`.

**Evidence:** `test/scripts/build-loop-check.bats:357-393`; `/tmp/u2a3b-fcf1-kK2Z/logs/bats.txt`, `/tmp/u2a3b-fcf1-kK2Z/logs/mutant-nul_list.txt`

---

## Claim 41: "The tree walk itself, called twice: the second call returns its cached error."

**Location:** `test/scripts/build-loop-check.bats:372-378`
**Legibility-target:** test name/comment
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the code behavior, which I executed separately. It does not establish that this test proves it.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: the behavior is true of the code, but the test keeps the failing `tr` shim on PATH for both calls, so it cannot tell a cached error from a recomputed one · r2: "A mutant that deletes the cache line (`:566` → `:`) passes all of build-loop-check.bats and dev-cycle.bats" (`mut-nocache.log`, bats rc=0, 96 ok) · r3: "It does catch a cache that returns 0" · r1+r2: escalated to test-strategy (see Escalations)

(r1) The code returns a cached error: `[[ "$IMPORTED_DONE" == "$ROOT_REAL" ]] && { [[ "$IMPORTED" != error ]]; return; }` (`lib :566`). In the test, though, both calls run under the same failing tr (`env PATH="$BATS_TEST_TMPDIR/bin:$PATH"`, `:373`), so a recomputing walk prints the same `walk failed` twice. The precise version: "called twice under a failing tr: both calls fail (the second from the cache)". The `dev-cycle.bats` cache test (`:1168-1180`) covers recomputation only for another root. Test/comment only.

**Evidence:** `test/scripts/build-loop-check.bats:372-378`; `scripts/lib/dev-cycle-read.sh:566`; `/tmp/u2a3b-fcf1-kK2Z/logs/probe-cache.txt`; `/tmp/u2a3b-fcf2-zUrB/logs/mut-nocache.log`

---

## Claim 42: "A file past bash's here-string pipe size (64 KiB) with no room for a temp file (ulimit -f 0): the import at its end is still read."

**Location:** `test/scripts/build-loop-check.bats:380-384`
**Legibility-target:** test name/comment
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 64 KiB threshold on bash 5.2.15 and the test's discrimination. Under the here-string mutant, SIGXFSZ kills bash (rc 153) and the test's `status -eq 0` fails. It does not establish other bash builds' pipe size.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

(r1) Here-strings of 65000 bytes still use the pipe; at 66000 bytes they need a temp file (Claim 28). The fixture is 70000 bytes plus the import line (`:381`).

**Evidence:** `test/scripts/build-loop-check.bats:380-384`; `/tmp/u2a3b-fcf1-kK2Z/logs/probe-herestring.txt`

---

## Claim 43: "A corrupt index: git ls-files fails, so the tree walk has no start list." (build-loop-check) / "A corrupt index: git ls-files fails, so the walk has no start list." (dev-cycle)

**Location:** `test/scripts/build-loop-check.bats:386`; `test/scripts/dev-cycle.bats:1053`
**Legibility-target:** for-orchestrator-synthesis
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's response to a 4-byte index. Does not cover other index corruptions.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** none

(r3) `printf 'junk' > .git/index` gives `fatal: .git/index: index file smaller than expected` and `1: failed rc`. (r1) The build-loop-check corrupt-index case prints `walk failed` and `docs/z.md: imported` (`:386-392`).

**Evidence:** `test/scripts/build-loop-check.bats:386-392`; `test/scripts/dev-cycle.bats:1053-1056`; r3 `logs/walk-fail.txt`

---

## Claim 44: test "--check-fix words a failed import walk as one and refuses (U2a3b)"

**Location:** `test/scripts/dev-cycle.bats:1048-1057`
**Legibility-target:** test name/comment
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ls-files failure kind end to end. Claim 5 covers the other kinds. It does not establish exit status, which the test does not assert; the script exits 0 after printing.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2+r3: the test checks `ok docs/notes.md` before the corruption (control run)

(r1) The test asserts `[[ "$output" == "skip docs/notes.md: the instruction-file import walk failed"* ]]` (`:1055`). The mutant that ignores nul_list's failure fails this test (`not ok 95` across five suites; r3 `not ok 76` across two).

**Evidence:** `test/scripts/dev-cycle.bats:1048-1057`; `/tmp/u2a3b-fcf1-kK2Z/logs/mutant-nul_list.txt`; r3 `logs/mutant-m1.txt`

---

## Claim 45: "Rebased onto main f6fdda68 (U2a3 merged at 97aa2d35 after its split; the lib merged without conflicts, the tests and the override log were resolved by keeping both sides)."

**Location:** commit e48cf0f7 message
**Legibility-target:** commit message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a replay, in a scratch clone, of the reflog's pre-rebase commits (`ac1a8b7b` on 45ad17b0) onto 97aa2d35 and then onto f6fdda68. It does not establish how the author resolved the conflicts, beyond the result matching the real rebased commits byte for byte.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: verdicted only "the lib merged without conflicts" and "does not verify the commit's companion claim that the tests and override log were resolved 'by keeping both sides' (the replay resolved them mechanically)" · r3: "Does not verify 'keeping both sides' as the resolution method"; r3 replayed the picks with `git cherry-pick`

(r1) The reflog shows `3a805acf ... rebase (finish) ... onto 97aa2d35` and `d894b3f0 ... onto f6fdda68`. The replay onto 97aa2d35 conflicted only in `test/scripts/build-loop-check.bats` (commit 1), and in `docs/reviews/override-log.md` plus that test file (commit 2). `scripts/lib/dev-cycle-read.sh` auto-merged. With the conflicted files taken from the real commits, the result equals `3a805acf` (empty `git diff --stat`). The second rebase onto f6fdda68 had no conflicts and equals `d894b3f0`.

**Evidence:** `/tmp/u2a3b-fcf1-kK2Z/logs/rebase1.txt`; `/tmp/u2a3b-fcf2-zUrB/logs/rebase-replay.log`; r3 `logs/repick.txt`

---

## Claim 46: the post-rebase bullets: "imported_names reads its start list through U2a3's nul_list helper (tree_starts ...), so the rc=0 listing check is written once (I2-C3)"; "IMPORTED starts as error, like IMPORTED_MAIN (I2-C5)"; "Patch A's Unicode-space test runs the untracked .MD start on the tree walk only"; "Override rows close the three rows routed to U2a3 (fixed there in c42f017f), I2-C5 and I2-A6"

**Location:** commit e48cf0f7 message
**Legibility-target:** commit message
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each bullet against the tree and the commit's diff. It does not re-verify the substance of the closed rows beyond c42f017f's subject.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r3: "no reader reads IMPORTED before `imported_names` runs ... A lookup against `error` answers not-imported, the same as the old `$'\n'`"; `rc=0` now appears only in nul_list (`:559`; "d894b3f0 had a second copy at `:566-567`")

(r1) `rg 'rc=0'` in the lib hits only nul_list (`:559`). `IMPORTED=error; ... IMPORTED_MAIN=error` (`:481`). The test runs `imps main` before `docs/AGENTS.MD` exists and `imps tree` after (`build-loop-check.bats:62-69`). c42f017f is on main (`merge-base --is-ancestor`). The commit adds three override rows: the closure of the three U2a3-routed rows, I2-C5 and I2-A6.

**Evidence:** `scripts/lib/dev-cycle-read.sh:481`, `:559`; `test/scripts/build-loop-check.bats:53-70`; `docs/reviews/override-log.md:414-416`

---

## Claim 47: "Known issue A5 and plan F11 name Claude Code 2.1.292's grammar, its revisit trigger and the backslash-escaped-space gap (I2-A6, second half)."

**Location:** commit e48cf0f7 message
**Legibility-target:** for-orchestrator-synthesis
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers presence of the three items in both rows. Their precision is covered by Claims 35-37 (Claims 1-4 here).
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=Verified
**Replicate annotations:** none

(r3) A5 holds "a backslash-escaped space (`@my\ notes.md` ...)" and "revisit trigger: a Claude Code upgrade". F11 holds "a backslash-escaped space in a name" and "reopens this row".

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`; `docs/working/plan-build-loop-handoff.md:126`

---

## Claim 48: "Tests: 119/119 across the five suites"

**Location:** commit e48cf0f7 message
**Legibility-target:** commit message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the five named suites at e48cf0f7 and shellcheck on the two changed scripts. It does not establish the full repository suite.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** none

(r1) The run printed `1..119` and 119 `ok` lines, and bats exited 0 (`TMPDIR=/tmp/u2a3b-fcf1-tmp-v2YS bats test/scripts/build-loop-check.bats test/scripts/build-loop-read.bats test/scripts/dev-cycle.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats`, 2026-10-07T05:00:48Z). r2 and r3 each reproduced 119 `ok`.

**Evidence:** `/tmp/u2a3b-fcf1-kK2Z/logs/bats.txt`; `/tmp/u2a3b-fcf2-zUrB/logs/suites.log`; r3 `logs/suites.txt`

---

## Claim 49: "shellcheck clean"

**Location:** commit e48cf0f7 message
**Legibility-target:** for-orchestrator-synthesis
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two changed scripts with the repo's `.shellcheckrc`. Does not cover the bats files.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: ran `shellcheck -x`; "does not establish shellcheck on the .bats files"

(r3) `shellcheck scripts/lib/dev-cycle-read.sh scripts/dev-cycle.sh` exited 0 with no output.

**Evidence:** r3 `logs/shellcheck.txt` (empty); `/tmp/u2a3b-fcf1-kK2Z/logs/shellcheck.txt`; `/tmp/u2a3b-fcf2-zUrB/logs/shellcheck.log`

---

## Claim 50: "a mutant that ignores nul_list's failure fails two tests"

**Location:** commit e48cf0f7 message
**Legibility-target:** commit message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mutant `nul_list recs tree_starts || true` on the five suites. It does not establish other mutant forms.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r3: ran the mutant over build-loop-check.bats and dev-cycle.bats only ("the other three suites do not reach the tree walk"), so its test numbers differ (`not ok 76`)

(r1) Result: `not ok 20 both walks fail closed when tr fails; ...` and `not ok 95 --check-fix words a failed import walk as one and refuses (U2a3b)`. Exactly two tests fail.

**Evidence:** `scripts/lib/dev-cycle-read.sh:568`; `/tmp/u2a3b-fcf1-kK2Z/logs/mutant-nul_list.txt`; `/tmp/u2a3b-fcf2-zUrB/logs/mut-nullist.log`; r3 `logs/mutant-m1.txt`

---

## Claim 51: "230 changed code lines against main."

**Location:** commit e48cf0f7 message
**Legibility-target:** commit message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers pr-prep step 1a's count (added plus deleted lines, excluding `docs/`). It does not establish anything else.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: its pr-prep 1a command printed 230 with a different per-file split ("2 + 127 + 90 + 11"); r1 and r3 report `2 0`, `89 38`, `86 4`, `11 0` (the same per-file totals: 127 and 90)

(r1) `git diff --numstat main...HEAD -- . ':!docs'` prints `2 0` for dev-cycle.sh, `89 38` for the lib, `86 4` for build-loop-check.bats and `11 0` for dev-cycle.bats, a sum of 188 + 42 = 230 (`workflows/pr-prep.md:91` uses the same count).

**Evidence:** `workflows/pr-prep.md:86-92`; r3 `logs/numstat.txt`

---

## Submitted Claims

## Claim 52: "At e48cf0f7, every name Claude Code 2.1.292 resolves in the fuzz corpus (seeds 1-3, 11-16; harness and corpora in /tmp/u2a3b-secf-XcAr, read-only) is listed by `import_targets`, except F1-class names (an inner @ swallowed by one grep match) and escaped-space names."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:513-548`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 16,500 corpus documents for seeds 1-3 and 11-16. Each was regenerated byte-identical from `h/gen.js` and compared against the harness's extracted-lexer emulation `h/ccall.js`. The claim holds: every one of the 44 names the walk misses is either F1-class (35) or escaped-space (9). This does not establish that `h/cc.js`/`ccall.js` behave as the real Claude Code 2.1.292 binary does (they are the reviewer's extraction, used as given). It also does not cover fragments outside the generator's 70-fragment alphabet, the F2 stray-`<!--` shape (which the generator does not produce), or names `ccall.js` filters out (`..`, absolute, or holding a newline).

The parser takes one token per grep match and only ever shortens it from the right:

```bash
# scripts/lib/dev-cycle-read.sh:529-535
  toks="$(printf '%s\n' "$toks" | env LC_ALL=C grep -aoE "$IMPORT_RE")" || [[ $? -eq 1 ]] || return 1
  while IFS= read -r t; do
    [[ -n "$t" ]] || continue
    t="${t#*@}"; n=$'\n'; cs=$'\n'; r="$t"
    # r walks back through the token's prefixes, one per cut mark.
    while :; do
      v="$r"; while [[ "$v" == *[.,\;:!?*_~\)\]] || "$v" == *"$b" ]]; do v="${v%?}"; done
```
(excerpt ends :535; enclosing import_targets() continues to :548, read: the dedup and realpath loop at :536-542, then the cut at :543-545.)

How the misses were classified (paraphrased — no quote available because this is a procedure over captured files, not code). First, the corpus was regenerated from `gen.js` for each seed and `diff -rq` against `fz.N` found no differences. Then the CC name set (`ccall.js`) was compared with the walk's name set (`h/walkall.sh` on the e48cf0f7 lib) using `comm -23`, which gave 44 misses. A miss counts as escaped-space when the name holds a space and its file holds `\ `: 9 misses. A miss counts as F1-class when a lib with **only** the F1 suffix-token hunk applied (`lib-f1only.sh`, which adds tokens at an inner `@` that follows a non-alphanumeric byte, and nothing else) lists the name while e48cf0f7 does not: 35 misses. That leaves 0 "other". Example rows: `- @docs/x.md</a>@d/p_q_r.md1.` (F1-class) and `@docs/x.md@d/p_q_r.md\ - ``` (escaped-space).

Commands (cwd `/tmp/u2a3b-fc25-logs-wGTS/fuzz`): `bash run.sh` (gen check, `node ccall.js`, `walkall.sh` on both libs, `comm`), exit 0, 2026-10-07T05:36:05Z, output `run.log`; then `bash classify.sh`, exit 0, output `classify.log` (summary line `TOTAL HEAD misses=44 F1-class=35 escaped-space=9 other=0`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:489`, `scripts/lib/dev-cycle-read.sh:513-548`, /tmp/u2a3b-fc25-logs-wGTS/fuzz/run.log, /tmp/u2a3b-fc25-logs-wGTS/fuzz/classify.log, /tmp/u2a3b-fc25-logs-wGTS/fuzz/miss-h.1 (and .2 .3 .11-.16), /tmp/u2a3b-fc25-logs-wGTS/fuzz/lib-f1only.sh

---

## Claim 53: "With the F1 and F2 candidate patches in docs/reviews/security-reviewer-review-2026-10-06-final-build-loop-u2a3b.md's Appendix applied, only escaped-space misses remain, the five suites pass 119/119, and the end-to-end fixture refuses all seven paths in both walks."

**Submitted by:** security-reviewer
**Location:** `docs/reviews/security-reviewer-review-2026-10-06-final-build-loop-u2a3b.md:199-235` (Appendix; untracked review file in the worktree)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the patched lib on the same nine-seed corpus (9 misses, all escaped-space), the five suites with the patched lib (119/119), and the seven-path e2e fixture (`--check-fix` skips all seven, and `isimported main` answers imported for all seven). It does not establish the patch's cost on large files, its fidelity beyond the emulated lexer (see Claim 52), or that the patch closes F2 shapes other than the fixture's one (only the fixture's fenced `x<!--` variant was re-run here).

`/tmp/u2a3b-secf-XcAr/fix/lib.sh` was diffed against the e48cf0f7 lib. The diff is exactly the Appendix's three hunks: the per-line splice at :519-526, `q=("$t")` with the inner-`@` suffix loop at :532, and the extra `done`. I used a copy of it (`fuzz/patched-lib.sh`; the applied diff is saved as `c2/patch-applied.diff`). Results:
- Corpus: every `miss-f.N` row is a `docs/x.md@d/p_q_r.md -`-shaped or `docs/x.md@ `-shaped escaped-space name (`TOTAL FIX misses=9 non-escaped-space=0`).
- Suites: `bats rc=0 ok=119 notok=0`.
- e2e (the reviewer's `h/e2e.sh` fixture rebuilt under my own mktemp dirs). At e48cf0f7 it printed `ok docs/b.md`, `ok docs/code_b.md`, `ok docs/secret.md` and `ok docs/chained.md`, with `main docs/b.md -` and so on. With the patch it printed seven `skip … an instruction file imports it` lines and seven `main … imported` lines.

Commands: `bash run.sh` (cwd `/tmp/u2a3b-fc25-logs-wGTS/c2`), exit 0, 2026-10-07T05:43:52Z, output `c2/run.log` and `c2/suites.log`; corpus as in Claim 52.

**Evidence:** /tmp/u2a3b-fc25-logs-wGTS/c2/run.log, /tmp/u2a3b-fc25-logs-wGTS/c2/suites.log, /tmp/u2a3b-fc25-logs-wGTS/c2/patch-applied.diff, /tmp/u2a3b-fc25-logs-wGTS/fuzz/classify.log, `scripts/lib/dev-cycle-read.sh:513-548`

---

## Claim 54: "`cs` dedups each candidate before its realpath fork, so a plain token forks realpath once, as at main. (lib :532-546)"

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:532-546`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a plain token, meaning one with no trailing strip character and no cut mark: one realpath fork at e48cf0f7 and at main f6fdda68. It also confirms that the `cs` test runs before the fork. It does not establish fork parity for tokens with cut marks: `[@docs/a.md](u)` forks 4 times at e48cf0f7 and once at main, by design of the prefix walk. A trailing-punctuation token forks twice at both.

```bash
# scripts/lib/dev-cycle-read.sh:536-540
      for w in "$r" "$v"; do
        [[ -n "$w" && "$w" != \~/* && "$w" != /* && "$cs" != *$'\n'"$w"$'\n'* ]] || continue
        cs+="$w"$'\n'
        p="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${1:+$1/}$w" 2>/dev/null)" || continue
        [[ "$p" != .. && "$p" != ../* && "$n" != *$'\n'"$p"$'\n'* ]] || continue
```
(excerpt ends :540; enclosing import_targets() continues to :548, read: the plain token has no cut mark, so `[[ "$r" == *$cut* ]] || break` at :543 ends its loop after one pass.)

For a plain token `r == v`, so the second `w` is rejected by `cs` before `realpath` runs. Main's version (`f6fdda68`, lib :501-506) breaks after the first fork when `v == t`. A realpath PATH shim that counts calls recorded: e48cf0f7 `see @docs/a.md` 1, `see @docs/a.md.` 2, `see [@docs/a.md](u)` 4; main 1, 2, 1.

Command: `bash p.sh` (cwd `/tmp/u2a3b-fc25-logs-wGTS/probe`), exit 0, 2026-10-07T05:37:54Z, output `probe/p.log` (section C3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:532-546`, /tmp/u2a3b-fc25-logs-wGTS/main-lib.sh (main's lib, :495-509), /tmp/u2a3b-fc25-logs-wGTS/probe/p.log

---

## Claim 55: "imported_names has main_imports' contract: returns 1 with IMPORTED=error, the error is cached and returns 1 again, and IMPORTED becomes $'\n' only after the start listing succeeds."

**Submitted by:** api-consistency-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:563-588`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `return 1` in imported_names (:568, :571, :572, :581, :584): each leaves IMPORTED=error. It also covers the cached-error return and the point where IMPORTED becomes `$'\n'`, after the whole start loop and not just the listing. It does not establish that the two caches are keyed alike (imported_names keys on ROOT_REAL only, main_imports on MAIN_SHA, MAIN_BY_NAME and ROOT_REAL), or the need_root exit path, which exits rather than returning.

```bash
# scripts/lib/dev-cycle-read.sh:566-577
  [[ "$IMPORTED_DONE" == "$ROOT_REAL" ]] && { [[ "$IMPORTED" != error ]]; return; }
  IMPORTED_DONE="$ROOT_REAL"; IMPORTED=error
  nul_list recs tree_starts || return 1
  for f in "${recs[@]}"; do
    # seen is newline-separated: a name holding a newline could hide another start.
    [[ "$f" != *$'\n'* ]] || return 1
    lp="$(lower "${f##*/}")" || return 1
    if [[ ! "$lp" =~ $INSTRUCTION_FILE ]] || ! inrepo_here "$f"; then continue; fi
    [[ "$seen" == *$'\n'"$f"$'\n'* ]] && continue
    seen+="$f"$'\n'; queue+=("$f")
  done
  IMPORTED=$'\n'
```
(excerpt ends :577; enclosing imported_names() continues to :588, read: :581 and :584 set `IMPORTED=error` before `return 1`.) This mirrors main_imports `:605-606` and `:629` (`IMPORTED_MAIN=error; IMPORTED_MAIN_DONE=…` … `IMPORTED_MAIN=$'\n'`).

Probe output: `before any walk: IMPORTED=error`; with a failing sed, `call1(sed fails): rc=1 IMPORTED=error`; with the real sed, `call2(real sed, cached): rc=1 IMPORTED=error`; with the tracked listing failing, `rc=1 IMPORTED=error`; on a clean walk, `rc=0 IMPORTED=$'\ndocs/a.md\n'` and the cached call returns 0.

Command: `bash p.sh` (cwd `/tmp/u2a3b-fc25-logs-wGTS/probe`), exit 0, 2026-10-07T05:37:54Z, output `probe/p.log` (section C4).

**Evidence:** `scripts/lib/dev-cycle-read.sh:481`, `scripts/lib/dev-cycle-read.sh:563-588`, `scripts/lib/dev-cycle-read.sh:601-629`, /tmp/u2a3b-fc25-logs-wGTS/probe/p.log

---

## Claim 56: "`isimported tree` uses `imported_names || return 0`, as the main arm does, and a failed lower of $2 answers imported."

**Submitted by:** api-consistency-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:672-681`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both arms' failed-walk answer and the failed-lower answer for `tree` and `main` (and the unknown-walk answer, which is read only). It does not establish that `--check-fix` can ever reach the failed-lower arm: check_fix's own `tr` at `scripts/dev-cycle.sh:175` exits the script under `set -e` first (see Claim 60).

```bash
# scripts/lib/dev-cycle-read.sh:672-681
isimported() {
  local lp
  need_root
  lp="$(lower "$2")" || return 0
  case "$1" in
    main) main_imports || return 0; [[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]] ;;
    tree) imported_names || return 0; [[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]] ;;
    *) return 0 ;;
  esac
}
```

A tr shim that fails only on input holding `trfail` gave: `tree docs/trfail.md: imported`, `tree docs/z.md: -`, `tree docs/a.md: imported` (the walk itself succeeded), and `main docs/trfail.md: imported`, `main docs/z.md: -`. With a failing sed, the tree walk failed and answered `tree docs/z.md with failing sed walk: imported`.

Command: `bash p.sh` (cwd `/tmp/u2a3b-fc25-logs-wGTS/probe`), exit 0, 2026-10-07T05:37:54Z, output `probe/p.log` (section C5).

**Evidence:** `scripts/lib/dev-cycle-read.sh:672-681`, /tmp/u2a3b-fc25-logs-wGTS/probe/p.log

---

## Claim 57: "instruction_names' `|| [[ $? -eq 1 ]]` returns 0 on no match and 1 on a grep failure, which fits nul_list's \"CMD exited 0\" contract."

**Submitted by:** api-consistency-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:554`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers grep's exit 0 (match), 1 (no match), 2 (error) and an empty input. Any status other than 0 or 1, a signal included, maps to 1 by the same test (read, not run). It does not establish that the grep shim used in test 20 pins this line deterministically: see Claim 66b, where a SIGPIPE race on the left side of `tree_starts` lets the `|| true` mutant pass.

```bash
# scripts/lib/dev-cycle-read.sh:554
instruction_names() { env LC_ALL=C grep -zaiE '(^|/)((claude|agents?|gemini)(\.[a-z0-9_-]+)?|skill)\.md$' || [[ $? -eq 1 ]]; }
```
and nul_list's contract at :558-559: `… or is emptied and 1 unless CMD exited 0 and its output was empty or ended in NUL.` / `mapfile -d '' nl_a < <("$@" && printf rc=0 || printf rc=1)`.

Probe: `no match: rc=0`, `match: rc=0` (output `AGENTS.md\0`), `grep exits 2: rc=1`, `empty input: rc=0`.

Command: `bash p.sh` (cwd `/tmp/u2a3b-fc25-logs-wGTS/probe`), exit 0, 2026-10-07T05:37:54Z, output `probe/p.log` (section C6).

**Evidence:** `scripts/lib/dev-cycle-read.sh:554`, `scripts/lib/dev-cycle-read.sh:558-559`, /tmp/u2a3b-fc25-logs-wGTS/probe/p.log

---

## Claim 58: "tree_starts reuses nul_list correctly: grep -z ends each record in NUL, and an empty listing exits 0."

**Submitted by:** api-consistency-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:560-562`, `scripts/lib/dev-cycle-read.sh:568`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a repo with one start (the record is NUL-terminated, and nul_list returns 0 with n=1) and a repo with no instruction file (0 bytes, nul_list returns 0 with n=0, and the walk succeeds with `IMPORTED=$'\n'`). It does not establish behavior when only one side of `{ git ls-files -z && untracked_md; }` fails (test-strategy G6, mutant M19), or the SIGPIPE interaction noted in Claim 66b.

```bash
# scripts/lib/dev-cycle-read.sh:562
tree_starts() { local -; set -o pipefail; { git ls-files -z && untracked_md; } | instruction_names; }
```
called as `nul_list recs tree_starts || return 1` (:568). Probe: `od -c` of tree_starts shows `A G E N T S . m d \0`; `listing with starts: rc=0 n=1 recs=AGENTS.md`; in the empty repo `raw bytes: 0`, `empty listing: rc=0 n=0`, `walk on no starts: rc=0 IMPORTED=$'\n'`.

Command: `bash p.sh` (cwd `/tmp/u2a3b-fc25-logs-wGTS/probe`), exit 0, 2026-10-07T05:37:54Z, output `probe/p.log` (section C7).

**Evidence:** `scripts/lib/dev-cycle-read.sh:558-562`, `scripts/lib/dev-cycle-read.sh:568`, /tmp/u2a3b-fc25-logs-wGTS/probe/p.log

---

## Claim 59: "Both walks and build-loop-check.bats:374 check import_targets' return 1; an empty input returns 0."

**Submitted by:** api-consistency-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:581`, `scripts/lib/dev-cycle-read.sh:634`, `test/scripts/build-loop-check.bats:374`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the presence of the check at both call sites and in the test, and the return codes for empty input (0), text with no token (0), a sed failure (1) and a grep exit 2 (1). It does not establish that any test exercises the tree walk's :581 failure arm. Mutants M08 and M09 pass all 119 tests at e48cf0f7 (Claim 65).

```bash
# scripts/lib/dev-cycle-read.sh:581
    out="$(import_targets "$d" < "$f")" || { IMPORTED=error; return 1; }
# scripts/lib/dev-cycle-read.sh:634 (main_imports sets pipefail at :602)
      100644|100755) out="$(git cat-file blob "$MAIN_SHA:$f" | import_targets "$d")" || { IMPORTED_MAIN=error; return 1; } ;;
# test/scripts/build-loop-check.bats:374
        if import_targets "" < docs; then echo read; else echo failed; fi
```
(the bats line sits inside the test that ends at :393, read. It expects `failed`.) Probe: `empty input (/dev/null), no pipefail: rc=0`, `empty input, pipefail: rc=0 out=[]`, `no token: rc=0`, `sed fails: rc=1`, `grep exits 2: rc=1`.

Command: `bash p.sh` (cwd `/tmp/u2a3b-fc25-logs-wGTS/probe`), exit 0, 2026-10-07T05:37:54Z, output `probe/p.log` (section C8).

**Evidence:** `scripts/lib/dev-cycle-read.sh:513-548`, `scripts/lib/dev-cycle-read.sh:581`, `scripts/lib/dev-cycle-read.sh:602`, `scripts/lib/dev-cycle-read.sh:634`, `test/scripts/build-loop-check.bats:357-393`, /tmp/u2a3b-fc25-logs-wGTS/probe/p.log

---

## Claim 60: "check_fix's new skip reason runs before isimported, so it never prints the false \"imports it\" reason on a failed walk."

**Submitted by:** api-consistency-reviewer
**Location:** `scripts/dev-cycle.sh:181-184`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a walk failed by sed (the parser) or by the tracked listing: every path gets the walk-failed reason. A walk that succeeds is cached, so isimported's own walk call cannot fail afterwards. It does not establish wording when check_fix's own lower-casing `tr` (:175) fails. That case exits the script with rc=1 and no line (a fail-closed silence, recorded in the security reviewer's escalation dispositions), and it is the only way isimported's failed-lower arm could otherwise be reached.

```bash
# scripts/dev-cycle.sh:181-184
  elif ! imported_names; then
    echo "skip $a: the instruction-file import walk failed, so an import of it cannot be ruled out; file it instead"
  elif isimported tree "$lp"; then
    echo "skip $a: an instruction file imports it with @ (directly or through another import), so it is read as instructions; file it instead"
```
(excerpt ends :184; enclosing check_fix() continues to :185, read: `else check_path "$a"; fi`.)

Probe through `scripts/dev-cycle.sh --check-fix docs/a.md docs/b.md`: with no shim, `skip docs/a.md: an instruction file imports it…` and `ok docs/b.md`. With a failing sed, and again with a failing tracked listing, both paths printed `skip …: the instruction-file import walk failed…`, rc 0. With a tr that fails only on `trfail`, it printed `ok docs/b.md` and then exited rc=1 at docs/trfail.md with no line.

Command: `bash p.sh` (cwd `/tmp/u2a3b-fc25-logs-wGTS/probe`), exit 0, 2026-10-07T05:37:54Z, output `probe/p.log` (section C9).

**Evidence:** `scripts/dev-cycle.sh:170-185`, `scripts/lib/dev-cycle-read.sh:566`, /tmp/u2a3b-fc25-logs-wGTS/probe/p.log

---

## Claim 61: "The dev-cycle digest (scripts/dev-cycle.sh) never prints revisit triggers written only in docs/working/ or code comments."

**Submitted by:** architecture-review
**Location:** `scripts/dev-cycle.sh:261-372`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the text of a trigger. Section 2 reads only `docs/decisions/NNN-*.md` `## Revisit triggers` sections and `docs/decisions/log.md` rows. Probe triggers in `docs/working/dd-*.md`, a plan doc, a cycle record and the idea log, and in shell and C comments, were all absent from the digest. It does not establish silence about docs/working/questions.md: section 3 (:374-411) prints the ID, route and slug of an open `trigger`- or `deferred`-routed question. So a watched trigger recorded there surfaces by its handle (`- Q-001  trigger  revisit-worktrig-iota`), though not its text. Commit subjects (sections 1, 4 and 6) are printed and were not probed for trigger text.

```bash
# scripts/dev-cycle.sh:264-266
trig() { awk '/^## Revisit triggers/ { on = 1; next } on && /^## / { exit } on && NF { print }'; }
n_before_triggers=${#SKIPPED[@]}
decisions_glob=()
```
(excerpt ends :266; section 2 continues to :372, read: the glob is `docs/decisions/[0-9][0-9][0-9]-*.md` at :267, and the log parser reads `docs/decisions/log.md` at :302-350.) The section's own preamble at :262 says so: `a trigger written elsewhere in a record, or in a docs/working/ design doc such as dd-*.md, is not found`.

Fixture digest token check: `DECTRIG-ALPHA: PRINTED`, `LOGTRIG-OMEGA: PRINTED`, and `WORKTRIG-BETA/GAMMA/EPS/ZETA/ETA/IOTA` absent, `CODETRIG-DELTA/THETA` absent, `worktrig-iota: PRINTED: - Q-001  trigger  revisit-worktrig-iota` (slug only).

Command: `bash p.sh` (cwd `/tmp/u2a3b-fc25-logs-wGTS/c10`; it runs `DEV_CYCLE_TODAY=2026-10-06 bash scripts/dev-cycle.sh --since=2026-01-01` in a fixture repo), exit 0, digest rc 0, 2026-10-07T05:38:26Z, output `c10/p.log` and `c10/digest.md`.

**Evidence:** `scripts/dev-cycle.sh:261-372`, `scripts/dev-cycle.sh:374-411`, /tmp/u2a3b-fc25-logs-wGTS/c10/p.log, /tmp/u2a3b-fc25-logs-wGTS/c10/digest.md

---

## Claim 62: "After this branch, the rc=0 listing check is written only inside nul_list."

**Submitted by:** architecture-review
**Location:** `scripts/lib/dev-cycle-read.sh:559`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every non-docs, non-archive file at e48cf0f7 (`git grep 'rc=0'` and `rc=1|printf rc|nl_a\[-1\]`). The only `printf rc=0`/`== rc=0` sentinel is in nul_list. Every other `rc=0` hit is an unrelated local status variable. It does not establish that every NUL listing is checked. `main_imports`' batch lower-casing (:620-621, U2a3 context) checks only the record count, as the security reviewer's N1 notes, and the digest's `matches` loop at `scripts/dev-cycle.sh:148` reads NUL output without a status check.

```bash
# scripts/lib/dev-cycle-read.sh:559
nul_list() { local -n nl_a="$1"; shift; mapfile -d '' nl_a < <("$@" && printf rc=0 || printf rc=1); [[ ${#nl_a[@]} -gt 0 && "${nl_a[-1]}" == rc=0 ]] || { nl_a=(); return 1; }; unset 'nl_a[-1]'; }
```
The branch diff (`git diff f6fdda68 e48cf0f7`) adds no other sentinel. imported_names now calls `nul_list recs tree_starts` (:568) where main's version read `< <({ git ls-files -z; untracked_md; } | instruction_names)` unchecked.

Command: `git -C /workspace/.claude/wt-build-loop-u2a3b grep -n 'rc=0' e48cf0f7 -- ':!docs' ':!archive'` (cwd /workspace/.claude/wt-build-loop-u2a3b), exit 0, 2026-10-07T05:38Z, output `c11-grep.txt`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:559`, `scripts/lib/dev-cycle-read.sh:568`, `scripts/lib/dev-cycle-read.sh:620-621`, `scripts/dev-cycle.sh:148`, /tmp/u2a3b-fc25-logs-wGTS/c11-grep.txt

---

## Claim 63: "No caller reads IMPORTED or IMPORTED_MAIN without first running its walk."

**Submitted by:** architecture-review
**Location:** `scripts/lib/dev-cycle-read.sh:677-678`
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every reference at e48cf0f7 outside docs/ and archive/. The value is read only at lib :677-678, after `main_imports || return 0` / `imported_names || return 0`, and at `test/scripts/dev-cycle.bats:1176-1177`, after `imported_names`. Writes inside the walks are not reads. `dev-cycle.bats:1101` runs `declare -p IMPORTED … IMPORTED_MAIN` before any walk, but that checks only that the variables are declared, not their value. It does not establish anything about out-of-repo callers or prose callers under docs/ (excluded from the grep).

```bash
# scripts/lib/dev-cycle-read.sh:677-678
    main) main_imports || return 0; [[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]] ;;
    tree) imported_names || return 0; [[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]] ;;
# test/scripts/dev-cycle.bats:1176
        ROOT_REAL="$(pwd -P)"; imported_names; printf "%s" "$IMPORTED" | tr "\n" " "; echo
```
No reference exists in `scripts/dev-cycle.sh` or `scripts/build-loop.sh`.

Command: `git -C /workspace/.claude/wt-build-loop-u2a3b grep -nE 'IMPORTED' e48cf0f7 -- ':!docs' ':!archive'` (cwd the worktree), exit 0, 2026-10-07T05:38Z, output `c12-grep-all.txt` (30 lines).

**Evidence:** `scripts/lib/dev-cycle-read.sh:481`, `scripts/lib/dev-cycle-read.sh:563-681`, `test/scripts/dev-cycle.bats:1101`, `test/scripts/dev-cycle.bats:1176-1177`, /tmp/u2a3b-fc25-logs-wGTS/c12-grep-all.txt

---

## Claim 64: "With the patch in Appendix A of docs/reviews/test-strategy-review-2026-10-06-final-build-loop-u2a3b.md (also /tmp/u2a3b-tsf-2n1r-h/g.patch) applied to e48cf0f7, the five suites pass 120/120."

**Submitted by:** test-strategy
**Location:** `test/scripts/build-loop-check.bats:370-393` (patch target; Appendix A of the untracked test-strategy review)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one run of the five suites on e48cf0f7 plus g.patch: 120 ok, 0 not ok. The Appendix diff in the report was checked byte-identical to g.patch with `diff`. It does not establish that the new test 21 is free of the SIGPIPE-style flakiness found in Claim 66b (one run only).

Applied with `patch -p1 --quiet < g.patch` in a fresh copy, then the five suites: `none pat5 rc=0 ok=120 notok=0`.

Command: `bash run.sh none pat5` (cwd `/tmp/u2a3b-fc25-logs-wGTS/mut`, run under `xargs -P 6`), exit 0, between 2026-10-07T05:36:32Z and 05:41:21Z, output `mut/none.pat5.log`.

**Evidence:** /tmp/u2a3b-fc25-logs-wGTS/mut/none.pat5.log, /tmp/u2a3b-fc25-logs-wGTS/mut/none.pat5.res, /tmp/u2a3b-fc25-logs-wGTS/mut/g.patch, /tmp/u2a3b-fc25-logs-wGTS/mut/run.sh

---

## Claim 65: "With that patch, mutants M01, M08-M13 and M19 (as defined in that report) each fail a test, and without it they survive."

**Submitted by:** test-strategy
**Location:** `scripts/lib/dev-cycle-read.sh:562`, `scripts/lib/dev-cycle-read.sh:566`, `scripts/lib/dev-cycle-read.sh:581`, `scripts/lib/dev-cycle-read.sh:584`, `scripts/lib/dev-cycle-read.sh:657`, `scripts/lib/dev-cycle-read.sh:675`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the eight mutants exactly as `mutants.py` defines them (each search string matched once). Unpatched, each passed all five suites (119 ok). Patched, each failed exactly one test in build-loop-check.bats: test 20 for M01, the new test 21 for M08-M13 and M19. This was one run per mutant per side, and only build-loop-check.bats ran on the patched side. It does not establish kills that hold across repeated runs under load (compare Claim 66b), or results for the other four suites under the patch.

Mutant sites (e.g. M08): `out="$(import_targets "$d" < "$f")" || { IMPORTED=error; return 1; }` → `… || true` at `scripts/lib/dev-cycle-read.sh:581`; M19: `{ git ls-files -z && untracked_md; }` → `{ git ls-files -z; untracked_md; }` at :562. Results (`mut/*.res`): `M01-cache-del base5 rc=0 ok=119 notok=0` / `pat1 … not ok 20`; `M08…M13, M19 base5 rc=0 ok=119 notok=0` / `pat1 rc=1 ok=20 notok=1 not ok 21 the walks fail closed past the start list…`.

Command: `xargs -P 6 -L 1 timeout 1500 bash run.sh < jobs.txt` (cwd `/tmp/u2a3b-fc25-logs-wGTS/mut`; modes base5 and pat1), exit 0, 2026-10-07T05:36:32Z to 05:41:21Z, outputs `mut/<mutant>.base5.log` and `mut/<mutant>.pat1.log`, summary `mut/first-pass-results.txt`.

**Evidence:** /tmp/u2a3b-fc25-logs-wGTS/mut/mutants.py, /tmp/u2a3b-fc25-logs-wGTS/mut/first-pass-results.txt, /tmp/u2a3b-fc25-logs-wGTS/mut/M08-readfail.base5.log, /tmp/u2a3b-fc25-logs-wGTS/mut/M08-readfail.pat1.log (and the same pair for M01, M09-M13, M19)

---

## Claim 66a: "The suite at e48cf0f7 kills M02, M05-M07, M14-M16, M18 and M21-M25."

**Submitted by:** test-strategy
**Location:** `scripts/lib/dev-cycle-read.sh:515-583` (mutant sites), `scripts/dev-cycle.sh:181-182` (M15)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 13 of the 14 named mutants. Each failed at least one test in build-loop-check, build-loop-read and dev-cycle, one run each: M02 (20), M05 (20, 95), M06 (20), M07 (20), M14 (20), M15 (95), M16 (20), M18 (19), M21 (3, 20, 97, 103), M22 (103), M23 (19), M24 (19, 96), M25 (19). It does not establish that these kills are deterministic across repeated runs. Each ran once, under six-way parallel load.

Results lines, e.g. `M05-startlist-true base3 rc=1 ok=113 notok=2 not ok 20 …;not ok 95 --check-fix words a failed import walk as one and refuses (U2a3b);`.

Command: `xargs -P 6 -L 1 timeout 1500 bash run.sh < jobs.txt` (cwd `/tmp/u2a3b-fc25-logs-wGTS/mut`, mode base3), exit 0, 2026-10-07T05:36:32Z to 05:41:21Z, outputs `mut/<mutant>.base3.log`, summary `mut/first-pass-results.txt`.

**Evidence:** /tmp/u2a3b-fc25-logs-wGTS/mut/first-pass-results.txt, /tmp/u2a3b-fc25-logs-wGTS/mut/M02-cache-ok.base3.log (and the other base3 logs), /tmp/u2a3b-fc25-logs-wGTS/mut/mutants.py

---

## Claim 66b: "The suite at e48cf0f7 kills … M26."

**Submitted by:** test-strategy
**Location:** `scripts/lib/dev-cycle-read.sh:554` (M26: `|| [[ $? -eq 1 ]]; }` → `|| true; }`), `test/scripts/build-loop-check.bats:364-367`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers three full runs of the three suites with M26 and 200 isolated walks under the test's grep shim. The kill is nondeterministic: test 20 killed M26 in 2 of 3 suite runs and let it survive in 1 (the parallel-load run). It does not establish a survival rate under CI load, or whether any other test would catch M26.

The precise version: test 20 kills M26 **most of the time**. Its only discriminating step is the `gbin` grep shim that exits 2 on `-z` without reading stdin:

```bash
# test/scripts/build-loop-check.bats:364-367
    g="$(command -v grep)" && mkdir -p "$BATS_TEST_TMPDIR/gbin"
    printf '#!/bin/sh\ncase "$1" in -z*) exit 2 ;; esac\nexec %s "$@"\n' "$g" > "$BATS_TEST_TMPDIR/gbin/grep" && chmod +x "$BATS_TEST_TMPDIR/gbin/grep"
    PATH="$BATS_TEST_TMPDIR/gbin:$PATH" imps tree docs/a.md docs/z.md; want walk failed; want docs/z.md imported
    imps tree docs/a.md docs/z.md; want walk ok; want docs/z.md -
```
(excerpt ends :367; enclosing test continues to :393, read.) With M26 the shim's status 2 becomes 0. `tree_starts` (`set -o pipefail`, :562) then fails only if `git ls-files -z` or `untracked_md` takes SIGPIPE from writing into the shim's already-closed pipe, and that depends on timing. When the write lands first the walk "succeeds" and the test catches the mutant. When git is still writing, it gets SIGPIPE, the walk fails as the test expects, and the mutant survives. (Mechanism inferred from the measurements below; paraphrased — no quote available because the race is in kernel pipe timing, not in repo code.)

Measured: the first parallel run gave `M26-names-true base3 rc=0 ok=115 notok=0` (survived). Two sequential reruns each gave `rc=1 ok=114 notok=1 not ok 20` (killed). In 200 isolated `imported_names` calls under the shim, the original lib gave `walk ok=0 walk failed=200`, and M26 gave `walk ok=199 walk failed=1`. The one failure is a run in which test 20 would let M26 pass. The test-strategy report's own run (`/tmp/u2a3b-tsf-2n1r-h/M26-names-true.res`) killed it.

Commands: (1) `xargs -P 6 … run.sh` as in Claim 66a, exit 0, 2026-10-07T05:36:32Z, result in `mut/first-pass-results.txt` (that run's log file was overwritten by the reruns; its summary line is preserved there). (2) `bash run.sh M26-names-true base3` twice (cwd `/tmp/u2a3b-fc25-logs-wGTS/mut`), exit 0, 2026-10-07T05:41:45Z, outputs `mut/M26-names-true.base3.rerun1.log` and `.rerun2.log`. (3) `N=200 bash race.sh` (cwd `/tmp/u2a3b-fc25-logs-wGTS/m26`), exit 0, 2026-10-07T05:43:11Z, output `m26/race.log`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:554`, `scripts/lib/dev-cycle-read.sh:562`, `test/scripts/build-loop-check.bats:357-393`, /tmp/u2a3b-fc25-logs-wGTS/mut/first-pass-results.txt, /tmp/u2a3b-fc25-logs-wGTS/mut/M26-names-true.base3.rerun1.log, /tmp/u2a3b-fc25-logs-wGTS/mut/M26-names-true.base3.rerun2.log, /tmp/u2a3b-fc25-logs-wGTS/m26/race.log

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 66b** (`scripts/lib/dev-cycle-read.sh:554`, `test/scripts/build-loop-check.bats:364-367`): test 20 kills M26 only when git's write into the early-exiting grep shim avoids SIGPIPE (survived 1 of 3 suite runs; 1 of 200 isolated walks). Say "usually kills". A deterministic pin needs a shim that drains stdin before exiting 2 (e.g. `cat >/dev/null; exit 2`).

### Unverifiable
(none)

## Claims Requiring Attention

### Incorrect
None.

### Stale
None.

### Mostly Accurate
- **Claim 2** (`docs/working/known-issues-dev-cycle.md:18`): r3 verdicted the whole A5 sentence Mostly accurate because of its "pins another copy" clause; r1 and r2 verified the shared-parser and 2.1.292 half. Doc only, High.
- **Claim 3** (`docs/working/known-issues-dev-cycle.md:18`): `test/agents-gemini-sync.bats` holds a separate start-only import finder documented against v2.1.284, not a copy of IMPORT_RE or of 2.1.292's regex. Doc only, High (all three replicates).
- **Claim 8** (`scripts/lib/dev-cycle-read.sh:453`): "each call sits in an `if` or `||`" holds for scripts/ only; two test calls are bare under `set -e` (`test/scripts/dev-cycle.bats:1176-1177`), on a succeeding walk. Comment only, High (r2).
- **Claim 19** (`scripts/lib/dev-cycle-read.sh:504-506`): CC splices only a `<!--` block that also holds `-->`, and the re-read copy also drops an unclosed comment's tail; no name is lost, since the first copy is still read. Comment only, High (all three replicates).
- **Claim 25** (`scripts/lib/dev-cycle-read.sh:509-511`): the HTML-comment rule comes from the U2a3b security review, but the comment cites only U2a2's. Comment only, High (r3).
- **Claim 26** (`scripts/lib/dev-cycle-read.sh:512`): the same "pins another copy of the regex" looseness as Claim 3. Comment only, High (all three replicates).
- **Claim 39** (`test/scripts/build-loop-check.bats:339`, `:357`): the two tests this branch adds are tagged "(U2a3)"; the sibling test and the adding commit say U2a3b. Test name only, Medium (r1).
- **Claim 41** (`test/scripts/build-loop-check.bats:372`): "the second call returns its cached error" is true of the code, but the test keeps the failing tr on PATH for both calls, so it cannot tell a cache from a recompute (a no-cache mutant passes). Test/comment only, High (r1).

### Unverifiable
None.

## Escalations

- **`test/scripts/build-loop-check.bats:372-378`** · raised by r1, r2 · addressee: test-strategy. No test isolates imported_names' cached-error path: both calls run under the same failing tr, so a recomputing walk passes; r2's no-cache mutant (`scripts/lib/dev-cycle-read.sh:566` → `:`) passes build-loop-check.bats and dev-cycle.bats. r1: "A probe that clears the failure between calls (restore PATH) distinguishes the two." (r3's Claim 31 scope reports the same limitation without escalating.)
- **`scripts/lib/dev-cycle-read.sh:657`** · raised by r2 · addressee: test-strategy. No test exercises main_imports' new lower guard in its import loop, since main fails at its start-list `tr` first.
- **`scripts/dev-cycle.sh:175`** · raised by r3 (advisory; r1 and r2 record the same behavior in their check_fix Scope lines, r2 citing `:173`) · addressee: security-reviewer. With a failing `tr`, `dev-cycle.sh --check-fix` exits 1 with no output before check_fix's walk branch. It fails closed but carries no wording; r3 rates it "A host fault, low".
- **`scripts/lib/dev-cycle-read.sh:453`, `:504-506`, `:512`; `docs/working/known-issues-dev-cycle.md:18`** · raised by r2 · addressee: orchestrator (author). "The author should fix the wording of Claims 3/23, 8 and 17" (Claims 3, 26, 8 and 19 here).

Not escalated, recorded for completeness: r1 stated "None for security-reviewer" on the Claim 19 divergence (a name holding `<!--` itself is under-read: `docs/xy.md` vs CC `docs/xy.md<!--zz`), as "outside any pathform-allowed name".

## Verdict stability

- **Total clusters:** 51 (emitted at sub-claim granularity; one single-replicate detection, Claim 16, r3 only)
- **Agreed (all reporting replicates gave the same verdict):** 46
- **Disagreed:** 5
  - Claim 2 (`docs/working/known-issues-dev-cycle.md:18`, shared parser/2.1.292): r1=Verified · r2=Verified · r3=Mostly accurate (compound)
  - Claim 8 (`scripts/lib/dev-cycle-read.sh:453`, "each call sits in an if or ||"): r1=Verified (compound) · r2=Mostly accurate · r3=Verified
  - Claim 25 (`scripts/lib/dev-cycle-read.sh:509-511`, "follow 2.1.292 ... (U2a2 security review)"): r1=— · r2=Verified · r3=Mostly accurate (compound)
  - Claim 39 (`test/scripts/build-loop-check.bats:339`, `:357`, "(U2a3)" tags): r1=Mostly accurate · r2=Verified (compound) · r3=Verified (compound)
  - Claim 41 (`test/scripts/build-loop-check.bats:372`, cached-error test): r1=Mostly accurate · r2=Verified · r3=Verified
- **Agreement rate:** 46/51 = 90.2%

All five disagreements are Verified vs Mostly accurate on comment, doc or test-label precision. In three of them (Claims 8, 39, 41) the non-dissenting replicates recorded the same underlying observation as a scope note rather than a verdict. No replicate assigned Incorrect, Stale or Unverifiable to any cluster.
