# Code Fact-Check Report

Commit: e48cf0f7

**Repository:** /workspace/.claude/wt-build-loop-u2a3b (branch feat/build-loop-u2a3b)
**Scope:** `git diff main...HEAD -- scripts test docs/working` (comments, test names and test comments, known issue A5, plan F11) and the message of commit e48cf0f7. Enclosing functions read in full: `scripts/lib/dev-cycle-read.sh:440-680` (UNI_SPACES, IMPORT_RE, lower, import_targets, instruction_names, untracked_md, nul_list, tree_starts, imported_names, main_imports, isimported) and `check_fix` in `scripts/dev-cycle.sh:164-185`. Replicate 2 of 3, final confirming pass.
**Checked:** 2026-10-07
**Total claims checked:** 40
**Summary:** 36 verified, 4 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Execution provenance: every executed command ran under `timeout` in the scratch copy `/tmp/u2a3b-fcf2-zUrB` (made by `git archive HEAD | tar -x`), with `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 LC_ALL=C`, between 2026-10-07T05:03Z and 05:13Z. Captured output is in `/tmp/u2a3b-fcf2-zUrB/logs/`. The probe scripts are `p1.sh` (parser token probes), `p5.sh` (each tree-walk failure kind), `p4.sh` (`--check-fix` end to end), `mut.sh` (mutants) and `rb.sh`/`rb2.sh` (rebase replay). No background process was started. The hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) was read, and no claim matches a logged pattern.

---

## Claim 1: "a name holding a backslash-escaped space (`@my\ notes.md`, which Claude Code reads as `my notes.md`; both walks end the token at the backslash)"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the walk side (both walks call the one parser, which ends the token at `\`) and Claude Code's side as the U2a2 security review quotes its regex; does not establish Claude Code's behavior independently of that quote (not re-extracted here).

Both walks call `import_targets`: `out="$(import_targets "$d" < "$f")"` (`scripts/lib/dev-cycle-read.sh:581`) and `out="$(git cat-file blob "$MAIN_SHA:$f" | import_targets "$d")"` (`:634`). The token class is `IMPORT_RE='(^|[^[:alnum:]])@[^[:space:]\\#]+'` (`:486`), which excludes the backslash. Executed (`p1.sh`): input `@my\ notes.md` yields only `my`. Claude Code's side comes from `docs/reviews/security-reviewer-review-2026-10-06-final-build-loop-u2a2.md:11`: "It runs `/(?:^|\s)@((?:[^\s\\]|\\ )+)/g` ... cuts at `#`, and replaces `\ ` with a space". So `my\ notes.md` is captured and read as `my notes.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:486`, `:581`, `:634`; `docs/reviews/security-reviewer-review-2026-10-06-final-build-loop-u2a2.md:11`; `/tmp/u2a3b-fcf2-zUrB/logs/p1.log` (cmd `LC_ALL=C timeout 60 bash ../p1.sh ../scripts/lib/dev-cycle-read.sh`, cwd `/tmp/u2a3b-fcf2-zUrB/probe`, exit 0, 2026-10-07T05:04Z)

---

## Claim 2: "Both walks share one token parser (`import_targets`) that follows Claude Code 2.1.292's import regex and Markdown lexer (U2a2 and U2a3b security reviews ...); revisit trigger: a Claude Code upgrade that changes either, which can make the walks miss imports."

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers both walks calling one parser and both cited reviews naming 2.1.292 and executing against its extracted lexer; does not establish parity with Claude Code beyond the shapes those reviews executed (this replicate did not re-run Claude Code's lexer).

The two call sites are quoted in Claim 1 (`:581`, `:634`). `docs/reviews/security-reviewer-review-2026-10-06-build-loop-u2a3b.md:11` reads "the marked lexer extracted from Claude Code 2.1.292, with `reo` transcribed around it". The U2a2 final review (`:11`) names the same version. Medium confidence: the "follows" half rests on those reviews' differential runs, not on a run of this replicate's own.

**Evidence:** `scripts/lib/dev-cycle-read.sh:581`, `:634`; `docs/reviews/security-reviewer-review-2026-10-06-build-loop-u2a3b.md:11`, `:157`; `docs/reviews/security-reviewer-review-2026-10-06-final-build-loop-u2a2.md:11`

---

## Claim 3: "`test/agents-gemini-sync.bats` pins another copy of the regex"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what that file holds; does not establish whether the two encodings agree on any input.

The file holds a separate import *finder*, modeled on an older Claude Code version and matching only the token's first character. It is neither a copy of `IMPORT_RE` nor of 2.1.292's regex. `test/agents-gemini-sync.bats:37` reads "Claude Code v2.1.284 (its extractor, read from the binary during review)", and `:51` reads `| grep -nE '(^|[^[:alnum:]])@(\./|~/|/|[[:alnum:]._-])'`. The pointer's purpose holds: it is another encoding of Claude Code's import grammar that a Claude Code upgrade should re-check. The precise version: "holds a separate import finder modeled on Claude Code 2.1.284". Doc only.

**Evidence:** `test/agents-gemini-sync.bats:37-51`; `docs/reviews/architecture-review-review-2026-10-06-build-loop-u2a3b.md:48`

---

## Claim 4: F11: gaps include "a backslash-escaped space in a name"; "The shared token parser follows Claude Code 2.1.292's grammar (U2a3b); a Claude Code upgrade that changes its import regex or Markdown lexer reopens this row."

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers consistency with A5 and the shared parser; does not establish Claude Code parity beyond the security reviews' executed shapes (same residue as Claim 2).

The F11 gap list now matches A5's added item, which reads "a name holding a backslash-escaped space" (`known-issues-dev-cycle.md:18`). The shared-parser claim is the one verified in Claim 2.

**Evidence:** `docs/working/plan-build-loop-handoff.md:126`; `docs/working/known-issues-dev-cycle.md:18`

---

## Claim 5: check_fix: `elif ! imported_names; then echo "skip $a: the instruction-file import walk failed, so an import of it cannot be ruled out; file it instead"` — reached for every failure kind, in the caller's shell

**Location:** `scripts/dev-cycle.sh:181-182`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk-failure kinds probed (start-listing grep, untracked listing, parser grep, unreadable import target, corrupt index via the suite) and the cache shared with the next `isimported tree`; does not establish the wording for a failure in check_fix's own earlier `tr` (`:173`, not this unit's).

`check_fix` runs in the script's shell: `--check-fix) check_fix "$a" ;;` (`scripts/dev-cycle.sh:202`), with no `$(...)`. So the `IMPORTED`/`IMPORTED_DONE` that `imported_names` sets are the ones the next line's `isimported tree "$lp"` reads. Executed (`p4.sh`): with `grep -z` failing, both args printed "skip …: the instruction-file import walk failed …". The same message came for a failing `git ls-files --others`, a failing parser grep, and an unreadable imported file. The control run printed `ok docs/n.md` and the import refusal for `docs/a.md`.

**Evidence:** `scripts/dev-cycle.sh:164-185`, `:202`; `/tmp/u2a3b-fcf2-zUrB/logs/p4.log` (cmd `bash /tmp/u2a3b-fcf2-zUrB/p4.sh`, cwd `/tmp/u2a3b-fcf2-zUrB/fx`, exit 0, 2026-10-07T05:10Z)

---

## Claim 6: "imported_names and main_imports return 1 when the walk fails: call them under if or ||."

**Location:** `scripts/lib/dev-cycle-read.sh:18-19`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers imported_names' failure returns (executed) and main_imports' `|| return 1` / `IMPORTED_MAIN=error; return 1` paths (read); does not establish that every repository caller follows the advice (see Claim 8).

The tree-walk failures are executed in Claim 7. In `main_imports`, every failure is `return 1` (`:604-669`, for example `nul_list recs git ls-tree ... || return 1`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:18-19`, `:563-589`, `:604-665`; `/tmp/u2a3b-fcf2-zUrB/logs/p5.log`

---

## Claim 7: "It returns 1, with IMPORTED set to "error", when the start listing (git ls-files, untracked_md, instruction_names), lower, a file read or the parser fails, or a start file's name holds a newline"

**Location:** `scripts/lib/dev-cycle-read.sh:451-453`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named failure kind, executed once each; does not establish behavior for failures inside inrepo_here/blocker (Claim 9 covers that they skip).

The code sets `IMPORTED=error` before any early return: `IMPORTED_DONE="$ROOT_REAL"; IMPORTED=error` (`:567`). The walk loop restores `error` explicitly: `out="$(import_targets "$d" < "$f")" || { IMPORTED=error; return 1; }` (`:581`) and `lp="$(lower "$p")" || { IMPORTED=error; return 1; }` (`:584`). Executed (`p5.sh`; each row prints rc, `IMPORTED`, and `isimported tree docs/zz.md`):

```
untracked      rc1 IMPORTED=error zz:imported
instrnames     rc1 IMPORTED=error zz:imported
tr             rc1 IMPORTED=error zz:imported
parser-grep    rc1 IMPORTED=error zz:imported
sed            rc1 IMPORTED=error zz:imported
fileread       ... Permission denied / rc1 IMPORTED=error zz:imported
newline        rc1 IMPORTED=error zz:imported
lsfiles        fatal: .git/index: index file smaller than expected / rc1 IMPORTED=error zz:imported
```

**Evidence:** `scripts/lib/dev-cycle-read.sh:563-589`; `/tmp/u2a3b-fcf2-zUrB/logs/p5.log` (cmd `bash /tmp/u2a3b-fcf2-zUrB/p5.sh`, cwd `/tmp/u2a3b-fcf2-zUrB/fx`, exit 0, 2026-10-07T05:11:06Z)

---

## Claim 8: "(each call sits in an `if` or `||`, where set -e is off)"

**Location:** `scripts/lib/dev-cycle-read.sh:453`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every call site of imported_names in scripts/ and test/; does not establish any behavior difference in the uncovered calls beyond exit-on-failure.

The production calls fit the claim: `elif ! imported_names` (`scripts/dev-cycle.sh:181`) and `imported_names || return 0` (`:677`), as do the build-loop-check.bats calls (`if imported_names`). Two test calls are bare under `set -euo pipefail`, though: `ROOT_REAL="$(pwd -P)"; imported_names; printf "%s" "$IMPORTED"` (`test/scripts/dev-cycle.bats:1176-1177`). They work because that walk succeeds. A precise version would read "each call in scripts/ sits in ...". Comment only.

**Evidence:** `scripts/dev-cycle.sh:181`; `scripts/lib/dev-cycle-read.sh:677`; `test/scripts/dev-cycle.bats:1176-1177`

---

## Claim 9: "an inrepo_here that fails skips its path"

**Location:** `scripts/lib/dev-cycle-read.sh:453-454`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers start candidates and imported targets that fail inrepo_here; does not establish that a skipped imported target is left out of IMPORTED (it is recorded, by design, `:584`).

Code: `if [[ ! "$lp" =~ $INSTRUCTION_FILE ]] || ! inrepo_here "$f"; then continue; fi` (`:574`) and `... && inrepo_here "$p"; then seen+=...; queue+=...` (`:585`). Executed: an untracked symlink `l/AGENTS.md` gives `symlinkstart rc0 IMPORTED=$'\ndocs/a.md\ndocs/b.md\n'`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:574`, `:585`; `/tmp/u2a3b-fcf2-zUrB/logs/p5.log`

---

## Claim 10: "a call for another ROOT_REAL recomputes it, and a cached error returns 1 again"

**Location:** `scripts/lib/dev-cycle-read.sh:455-456`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cache-hit return value and recompute on a changed key; does not establish that any caller resets IMPORTED_DONE (none does).

Code: `[[ "$IMPORTED_DONE" == "$ROOT_REAL" ]] && { [[ "$IMPORTED" != error ]]; return; }` (`:566`). Executed: the first call failed with a broken `tr`. The second call, made after `tr` was restored, still printed `rc1`, so it came from the cache. After `IMPORTED_DONE=""` the call printed `recomputed rc0`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:566-567`; `/tmp/u2a3b-fcf2-zUrB/logs/p5.log`

---

## Claim 11: `IMPORTED=error` initial value (commit: "IMPORTED starts as error, like IMPORTED_MAIN"): no reader sees it before a walk

**Location:** `scripts/lib/dev-cycle-read.sh:481`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every reference to `IMPORTED` in scripts/, test/ and skills/; does not establish behavior for an out-of-repo sourcer of the lib.

`rg 'IMPORTED[^_]'` finds `IMPORTED` read only inside the lib (`:566`, `:677`) and in `test/scripts/dev-cycle.bats:1176-1177`, which reads it after a successful `imported_names`. `scripts/build-loop.sh` never names it (paraphrased — no quote available because the claim is about absence of grep hits). The cache test needs `IMPORTED_DONE == ROOT_REAL`, and `IMPORTED_DONE` starts as `""` while `need_root` guarantees a non-empty `ROOT_REAL`. So the initial `error` is never returned from the cache.

**Evidence:** `scripts/lib/dev-cycle-read.sh:481`, `:566`, `:677`; `scripts/lib/dev-cycle-read.sh:95-99`; `test/scripts/dev-cycle.bats:1176-1177`

---

## Claim 12: "UTF-8 spaces that end an import token as a blank does (import_targets makes each one a blank before it matches tokens): U+00A0, U+1680, U+2000-200A, U+2028/2029, U+202F, U+205F, U+3000 and U+FEFF (Claude Code's token ends at JavaScript's \s, which includes U+FEFF)."

**Location:** `scripts/lib/dev-cycle-read.sh:482-488`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 19 byte sequences and their conversion before the grep; does not establish behavior under a non-C locale (every call is `env LC_ALL=C`).

`for u in "${UNI_SPACES[@]}"; do s+=(-e "s/$u/ /g"); done` (`:516`) runs before `grep` (`:518`, `:529`). The array's 19 entries match the listed code points. JavaScript's `\s` is ASCII whitespace plus the Zs category, U+2028/2029 and U+FEFF, which is exactly this set (paraphrased — no quote available because the source is the ECMAScript definition, not repository code). The suite test at `test/scripts/build-loop-check.bats:53` passed (Claim 31).

**Evidence:** `scripts/lib/dev-cycle-read.sh:482-488`, `:516-518`; `/tmp/u2a3b-fcf2-zUrB/logs/suites.log`

---

## Claim 13: "A token may follow any byte but a letter or digit (so user@host is not one); it ends at a blank, a UNI_SPACES space included, or at a backslash, as the import token of Claude Code does, and at #, where Claude Code cuts the name it captured (so a token after a # is an over-read ...)"

**Location:** `scripts/lib/dev-cycle-read.sh:493-497`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk's token ends (executed) and Claude Code's per the U2a2 security review's quoted regex; does not establish Claude Code's behavior beyond that quote.

`IMPORT_RE='(^|[^[:alnum:]])@[^[:space:]\\#]+'` (`:486`). Executed (`p1.sh`): `a@x.md` gives nothing. `x-@x.md` gives `x.md`. `@x.md\y.md` and `@x.md#frag` each give `x.md`. Tab, CR, VT and FF each separate tokens (`x.md y.md z.md w.md v.md`), and NBSP ends one. Claude Code's regex `/(?:^|\s)@((?:[^\s\\]|\\ )+)/g` "cuts at `#`" (U2a2 final security review `:11`). That regex ends a token at whitespace and at a backslash, apart from the escaped space Claim 14 covers.

**Evidence:** `scripts/lib/dev-cycle-read.sh:486`, `:493-497`; `/tmp/u2a3b-fcf2-zUrB/logs/p1.log`

---

## Claim 14: "a name holding a backslash-escaped space is not read, known issue A5"

**Location:** `scripts/lib/dev-cycle-read.sh:497-498`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 1; does not establish more.

Executed: `@my\ notes.md` gives `my` only. A5 lists the gap (`known-issues-dev-cycle.md:18`).

**Evidence:** `/tmp/u2a3b-fcf2-zUrB/logs/p1.log`; `docs/working/known-issues-dev-cycle.md:18`

---

## Claim 15: "each token yields its whole and its part before each of [ ] ( ) < ! * _ and backtick, each also with trailing . , ; : ! ? * _ ~ ) ] or backticks stripped, each path once"

**Location:** `scripts/lib/dev-cycle-read.sh:500-504`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers per-token output; "each path once" holds within a token, while the same path from two tokens is printed twice (consumers dedupe through `seen`), and the empty prefix is skipped.

Loop (`:530-547`, read to its end): `cut="[][()<!*_$b]"` (`:515`). In it, `v="$r"; while [[ "$v" == *[.,\;:!?*_~\)\]] || "$v" == *"$b" ]]; do v="${v%?}"; done`, then `for w in "$r" "$v"` with the per-token sets `cs`/`n` (reset at `:532`), then `[[ "$r" == *$cut* ]] || break; r="${r%$cut*}"`. Executed: ``@a!b*c_d<e(f)g[h]i`j.md`` yields the whole and nine prefixes, one before each of `` ` ] [ ) ( < _ * ! ``. ``@d/my_notes.md`c` `` yields `d/my_notes.md`. `@y.md),` yields `y.md),` and `y.md`. `@a.md @a.md` prints `a.md` twice (two tokens).

**Evidence:** `scripts/lib/dev-cycle-read.sh:513-547`; `/tmp/u2a3b-fcf2-zUrB/logs/p1.log`

---

## Claim 16: The cut loop `[[ "$r" == *$cut* ]] || break; r="${r%$cut*}"` with the comment "the cut marks as a glob bracket (b: a backtick)" and "r walks back through the token's prefixes, one per cut mark"

**Location:** `scripts/lib/dev-cycle-read.sh:515`, `:533-545`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both unquoted-pattern uses, the backtick and `!` members, and termination; does not establish behavior with `extglob` changing `!(`-style patterns (bash's `[...]` bracket is unaffected, and the lib does not set extglob).

An unquoted `$cut` is a pattern in both `[[ == ]]` and `${r%...}`. The bracket `[][()<!*_` + backtick + `]` takes the first `]` literally and `!` (not first) literally. Each pass removes at least the last mark, so `r` shrinks strictly and the loop ends. An empty `r` fails the test and breaks. Executed: the `!`, `*`, `_`, `<`, `(`, `)`, `[`, `]` and backtick prefixes all appear (Claim 15's log), so no prefix is dropped.

**Evidence:** `scripts/lib/dev-cycle-read.sh:515`, `:533-546`; `/tmp/u2a3b-fcf2-zUrB/logs/p1.log`

---

## Claim 17: "Claude Code deletes the HTML comments of a block that opens with <!-- and reads what is left, so text holding <!-- is also read once more with every closed comment removed."

**Location:** `scripts/lib/dev-cycle-read.sh:504-506`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the splice loop's output for closed, multiple, multi-line and unclosed comments, and the Claude Code condition as the U2a3b security review quotes it; does not establish a fail-open (the first copy is still read, Claim 19).

The mechanism and conclusion hold, but both halves miss a qualifier. Claude Code splices only a block that also *contains* `-->`: `if(H.startsWith("<!--")&&H.includes("-->")){let z=w.replace(/<!--[\s\S]*?-->/g,"")` (security review U2a3b `:92`). A block with an unclosed comment is not read at all. The code removes more than "every closed comment": `if [[ "$x" == *'-->'* ]]; then x="${x#*'-->'}"; else x=""; fi` (`:524`) also drops everything after an unclosed `<!--`. Executed: `<!-- a -->@s<!-- b -->ec.md <!-- open @tail.md` gives `sec.md` from the re-read, and `tail.md` comes only from the first copy. Multi-line `@m<!--\n-->l.md` gives `ml.md`. The precise version: "...with every comment removed, an unclosed one through the end of the text". Comment only.

**Evidence:** `scripts/lib/dev-cycle-read.sh:519-527`; `docs/reviews/security-reviewer-review-2026-10-06-build-loop-u2a3b.md:92`; `/tmp/u2a3b-fcf2-zUrB/logs/p1.log`

---

## Claim 18: "A NUL counts as a blank."

**Location:** `scripts/lib/dev-cycle-read.sh:506`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers NUL bytes in the stdin text; does not establish anything about NUL in symlink text (main_imports refuses that separately).

`s=(-e 's/\x0/ /g')` (`:514`) runs before the grep. Executed: `@x.md\0@y.md` gives `x.md y.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:514`, `:518`; `/tmp/u2a3b-fcf2-zUrB/logs/p1.log`

---

## Claim 19: "Over-reading only over-refuses." (with the HTML re-read added)

**Location:** `scripts/lib/dev-cycle-read.sh:506-507`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim that the re-read copy cannot suppress a name the first copy yields; does not establish that every over-read name is harmless to a caller other than the walks (none exists).

The re-read is appended, not substituted: `toks+=$'\n'"$y$x"` (`:526`). The grep and the token loop then emit the union of both copies' tokens, and nothing in the loop removes earlier output. Executed: in the unclosed case, `tail.md` and `q.md` still come out (from the first copy), so the re-read suppressed nothing.

**Evidence:** `scripts/lib/dev-cycle-read.sh:520-547`; `/tmp/u2a3b-fcf2-zUrB/logs/p1.log`

---

## Claim 20: "~/ and absolute paths, and paths leaving the repo (.. or ../, not a ..x name), are dropped."

**Location:** `scripts/lib/dev-cycle-read.sh:507-508`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers lexical resolution; does not establish symlink-aware resolution (A5 lists that).

Code: `[[ -n "$w" && "$w" != \~/* && "$w" != /* ...` (`:538`) and `[[ "$p" != .. && "$p" != ../* ...` (`:541`). Executed: `@~/h.md @/etc/p.md @~x.md @../out.md @..x.md @a/../../o.md @.. @~` gives `~x.md ..x.md ~`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:538-542`; `/tmp/u2a3b-fcf2-zUrB/logs/p1.log`

---

## Claim 21: "returns 1 when sed or grep fails"

**Location:** `scripts/lib/dev-cycle-read.sh:509`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers sed and the token grep; does not cover realpath failures, which skip the name (`|| continue`, `:540`) by design.

Code: `toks="$(env LC_ALL=C sed "${s[@]}")" || return 1` (`:518`) and `... | env LC_ALL=C grep -aoE "$IMPORT_RE")" || [[ $? -eq 1 ]] || return 1` (`:529`). Executed (`p2.sh`): a sed exiting 4 and a grep exiting 2 each give `rc1`, both with and without a match. The control gives `x.md rc0` and `nomatch rc0`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:518`, `:529`; command `PATH=$d/{gbin,sbin}:$PATH LC_ALL=C timeout 30 bash -c 'set -euo pipefail; source ../p2.sh "$1"' _ ../scripts/lib/dev-cycle-read.sh`, cwd `/tmp/u2a3b-fcf2-zUrB/probe`, exit 0, 2026-10-07T05:05Z; output transcribed in this claim (rc1/rc1 for each shim, `x.md rc0`/`nomatch rc0` for the control); the same paths are re-run end to end in `/tmp/u2a3b-fcf2-zUrB/logs/p5.log` (`parser-grep`, `sed` rows)

---

## Claim 22: "The rules follow Claude Code 2.1.292's import regex and Markdown lexer (U2a2 security review); re-check them when Claude Code changes either"

**Location:** `scripts/lib/dev-cycle-read.sh:509-511`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Same residue as Claim 2.

The cited review exists and names 2.1.292 (`security-reviewer-review-2026-10-06-final-build-loop-u2a2.md:11`). The token ends match its regex (Claim 13). The cut set covers marked's non-gfm stop set ``[\\<!\[`*_]`` (`:55` there) plus `]`, `(` and `)` as over-reads.

**Evidence:** `docs/reviews/security-reviewer-review-2026-10-06-final-build-loop-u2a2.md:11`, `:55`; `scripts/lib/dev-cycle-read.sh:515`

---

## Claim 23: "(test/agents-gemini-sync.bats pins another copy of the regex)"

**Location:** `scripts/lib/dev-cycle-read.sh:512`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Same as Claim 3.

Same finding as Claim 3. The file holds a separate first-character finder modeled on Claude Code v2.1.284 (`test/agents-gemini-sync.bats:37`, `:51`), not a copy of this regex. Comment only.

**Evidence:** `test/agents-gemini-sync.bats:37-51`

---

## Claim 24: "Two steps, not a pipe: under pipefail grep's "no match" would hide a sed failure."

**Location:** `scripts/lib/dev-cycle-read.sh:517`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reasoning (under pipefail the rightmost non-zero status, grep's 1, would be read as "no match") and the two-step code's sed failure return; does not establish anything about grep's own SIGPIPE behavior.

A sed failure returns 1 before the grep runs (Claim 21, `sbin` shim, no-match input: `nomatch rc1`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:517-518`; Claim 21's run

---

## Claim 25: "A pipe, not a here-string: bash writes a long here-string to a temp file, and a failed write would read as "no match"."

**Location:** `scripts/lib/dev-cycle-read.sh:527-528`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15 here. Here-strings of 65536 bytes or more go to a temp file. With SIGXFSZ ignored the failed write gives status 1 (read as no match); with it at default bash dies. Does not establish other bash builds' threshold.

Executed: with `ulimit -f 0`, here-strings of 65535 bytes succeed and of 65536 bytes fail (rc 153, SIGXFSZ). With `trap '' XFSZ`: `cannot create temp file for here-document: File too large`, then `rc=1 out=[]`. A here-string mutant of `:529` fails tests 11 and 20 of build-loop-check.bats (`logs/mut-herestring.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:527-529`; `/tmp/u2a3b-fcf2-zUrB/hs.sh` (cmd `timeout 10 bash -x hs.sh`, exit 0, 2026-10-07T05:12Z; output transcribed above); `/tmp/u2a3b-fcf2-zUrB/logs/mut-herestring.log` (cmd `bash mut.sh herestring ... test/scripts/build-loop-check.bats`, exit 0 of the driver, bats rc=1)

---

## Claim 26: "It returns 0 when no name matches and 1 when grep fails (grep's own no-match is 1)."

**Location:** `scripts/lib/dev-cycle-read.sh:552-554`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both statuses; does not establish behavior for grep status above 2 (also 1).

Code: `env LC_ALL=C grep -zaiE '...' || [[ $? -eq 1 ]]`. Executed: no-match input gives `nomatch rc=0`. A `grep -z` exiting 2 makes `tree_starts` return `rc=1` (`p5.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:554`; `/tmp/u2a3b-fcf2-zUrB/logs/instrnames.log`; `/tmp/u2a3b-fcf2-zUrB/logs/p5.log`

---

## Claim 27: nul_list's "output empty or ended in NUL" rule holds for instruction_names' output (as used by tree_starts)

**Location:** `scripts/lib/dev-cycle-read.sh:558`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers GNU grep -z output framing; does not establish other grep implementations.

`grep -z` ends every output record with NUL. Executed: `a/Claude.MD\0` is shown NUL-terminated (`instrnames.log`), and tree_starts' output `C L A U D E . m d \0` likewise (`p5.log`). An empty output passes. A non-zero exit empties the array (`nul_list ... printf rc=1`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:558`, `:562`; `/tmp/u2a3b-fcf2-zUrB/logs/instrnames.log`, `/tmp/u2a3b-fcf2-zUrB/logs/p5.log`

---

## Claim 28: "The tree walk's start candidates, NUL-separated: tracked and untracked names through instruction_names, failing when any of the three commands fails."

**Location:** `scripts/lib/dev-cycle-read.sh:560-562`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each of the three commands failing; does not establish behavior when tree_starts is called outside nul_list (no caller does).

`tree_starts() { local -; set -o pipefail; { git ls-files -z && untracked_md; } | instruction_names; }`. Executed: the control gives `rc=0`. A git shim failing on `--others` gives `rc=128`, and its partial output `CLAUDE.md\0` is still printed, so the nul_list rc check is what rejects it. A `grep -z` shim gives `rc=1`, and a corrupt index gives `rc=128`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:562`; `/tmp/u2a3b-fcf2-zUrB/logs/p5.log`

---

## Claim 29: "seen is newline-separated: a name holding a newline could hide another start."

**Location:** `scripts/lib/dev-cycle-read.sh:570-571`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers start candidates; imported targets cannot hold a newline (the token grep is line-based).

`seen=$'\n'` and `[[ "$seen" == *$'\n'"$f"$'\n'* ]] && continue` (`:564`, `:576`). A recorded `a\nb/CLAUDE.md` would make `b/CLAUDE.md` read as seen. Executed: the `newline` row gives rc1. The suite test at `:368-370` passed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:564-577`; `/tmp/u2a3b-fcf2-zUrB/logs/p5.log`; `test/scripts/build-loop-check.bats:368-370`

---

## Claim 30: "A failed walk, a failed lower of $2, or a walk name that is neither answers imported (0), so a caller testing it with `if` refuses; a caller that words a failed walk runs the walk first (imported_names or main_imports, under if)."

**Location:** `scripts/lib/dev-cycle-read.sh:668-671`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all three answer-imported paths and check_fix as the wording caller; does not establish that U2a4's future floor follows the "runs the walk first" advice.

Code: `lp="$(lower "$2")" || return 0`, `main) main_imports || return 0;`, `tree) imported_names || return 0;` and `*) return 0` (`:675-679`). Executed: with `tr` failing, `isimported tree|main|bogus x.md` all print `imported`. Failed-walk rows give `zz:imported` (`p5.log`). `check_fix` runs `imported_names` first (Claim 5).

**Evidence:** `scripts/lib/dev-cycle-read.sh:672-680`; `/tmp/u2a3b-fcf2-zUrB/logs/p5.log`

---

## Claim 31: Test name "both walks: every Unicode space JavaScript's \\s holds ends a token; SKILL.md starts them; an untracked upper-case .MD starts the tree walk (U2a3b)" and its comment "An untracked start: the tree walk reads it (the main walk fails closed on it until U2a3c)."

**Location:** `test/scripts/build-loop-check.bats:53-70`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 19 non-ASCII spaces (the ASCII ones are covered at `:28-41`) and both walks; does not establish that the main walk is exercised on the untracked start (by design, it fails closed there).

The fixture repo holds only an empty initial commit and `sub/SKILL.md` (`test/lib/build-loop-fixtures.bash:21-23`), so SKILL.md is the only start. Each `@../docs/u$i.md<sp>x` would yield `docs/u$i.md<sp>x`, not `docs/u$i.md`, unless the space ends the token. `docs/AGENTS.MD` is created after `commit_all` and imports `@k.md`, and `docs/k.md` must be imported on the tree walk. The main walk's fail-closed rule on it is `[[ "${cand[i]:0:1}" == m ]] || return 1  # main lacks it` (`dev-cycle-read.sh:625`). Passed in the suite run.

**Evidence:** `test/scripts/build-loop-check.bats:53-70`; `scripts/lib/dev-cycle-read.sh:625`; `/tmp/u2a3b-fcf2-zUrB/logs/suites.log`

---

## Claim 32: imps comment "walk: ok" or "walk: failed" (main_imports' or imported_names' return); first test's comments: "Two NBSPs in one run: the token ends at the first. docs/z.md is imported only after the NUL; gone/ does not exist, and the path is still resolved as written." "Docs/NB.MD and CLAUDE.md: isimported takes a path in any case." "Without ROOT_REAL it stops (need_root) for any walk name, before answering."

**Location:** `test/scripts/build-loop-check.bats:14`, `:28-29`, `:35`, `:47`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each comment against its fixture and the passing run; does not establish more than the fixture's shapes.

`:20` reads `if { [[ "$w" == main ]] && main_imports; } || { [[ "$w" == tree ]] && imported_names; }`. In the fixture, `@gone/../docs/m.md` resolves lexically to `docs/m.md` (`realpath -ms`), and `@docs/z.md` follows the `\0`. `CLAUDE.md` is imported via `docs/c.md`'s `@../CLAUDE.md`, and `isimported` lower-cases `$2`. `:48-50` asserts status 1, empty output and "ROOT_REAL is not set". All passed.

**Evidence:** `test/scripts/build-loop-check.bats:14-50`; `/tmp/u2a3b-fcf2-zUrB/logs/suites.log`

---

## Claim 33: Test name "both walks read what Claude Code reads: an @ after a Unicode space, Markdown and a code span around a token, ( ) in a name; ~x is over-read, ~/ dropped (U2a3)" and its comments "A cut mark earlier in the name (my_notes) does not hide a later one; two NBSPs on a line both become blanks; an HTML block's comment splices a name (sec+ret)."

**Location:** `test/scripts/build-loop-check.bats:339-355`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named case on both walks; does not establish Claude Code parity beyond these lines (Claim 2).

`docs/my_notes.md` (from ``@docs/my_notes.md`c` ``) needs a cut at the last backtick, not only at `_`. `docs/r.md` needs the second NBSP converted: otherwise `[^[:space:]\\#]+` would swallow `@docs/r.md` into the q token. `docs/secret.md` needs the splice. `'~/x.md'` must be `-`. All passed on both walks.

**Evidence:** `test/scripts/build-loop-check.bats:339-355`; `/tmp/u2a3b-fcf2-zUrB/logs/suites.log`

---

## Claim 34: Test name "both walks fail closed when tr fails; the tree walk fails closed when its start listing fails or a start name holds a newline; the parser returns 1 when it cannot read its input (U2a3)" and its comment "A grep that fails on the start listing (instruction_names, grep -z) only."

**Location:** `test/scripts/build-loop-check.bats:357-366`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each clause of the name; does not cover main_imports' new import-loop lower guard (`:657`), since main fails at its start-list `tr` first.

`instruction_names` is the lib's only `grep -z` (`rg 'grep -[a-yA-Z]*z'` gives `:554` only). The shim matches `-z*` as `$1`, and instruction_names' first argument is `-zaiE`. Executed: a mutant that ignores nul_list's failure makes this test fail (`logs/mut-nullist.log`, "not ok 20").

**Evidence:** `test/scripts/build-loop-check.bats:357-371`; `scripts/lib/dev-cycle-read.sh:554`; `/tmp/u2a3b-fcf2-zUrB/logs/mut-nullist.log`

---

## Claim 35: "The tree walk itself, called twice: the second call returns its cached error."

**Location:** `test/scripts/build-loop-check.bats:372`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the behavior (the second call does return the cached error, Claim 10); does not establish that this test detects a loss of the cache. A mutant that deletes the cache line (`:566` → `:`) passes all of build-loop-check.bats and dev-cycle.bats, because the `tr` shim stays on PATH and the recomputed walk fails the same way.

**Evidence:** `test/scripts/build-loop-check.bats:372-378`; `/tmp/u2a3b-fcf2-zUrB/logs/mut-nocache.log` (cmd `bash mut.sh nocache ... build-loop-check.bats dev-cycle.bats`, bats rc=0, 96 ok, 2026-10-07T05:09Z)

---

## Claim 36: "A file past bash's here-string pipe size (64 KiB) with no room for a temp file (ulimit -f 0): the import at its end is still read."

**Location:** `test/scripts/build-loop-check.bats:380-384`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15 in this sandbox (threshold 65536 bytes, executed); does not establish other builds' pipe-size constant.

The input is 70000 bytes. The threshold probe and the here-string mutant are in Claim 25: the mutant fails this test.

**Evidence:** `test/scripts/build-loop-check.bats:380-384`; `/tmp/u2a3b-fcf2-zUrB/logs/mut-herestring.log`

---

## Claim 37: "A corrupt index: git ls-files fails, so the tree walk has no start list." (build-loop-check) and test "--check-fix words a failed import walk as one and refuses (U2a3b)" with "A corrupt index: git ls-files fails, so the walk has no start list." (dev-cycle)

**Location:** `test/scripts/build-loop-check.bats:386-392`; `test/scripts/dev-cycle.bats:1048-1057`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the corrupt-index failure kind and the check_fix wording; other kinds are in Claim 5.

The `lsfiles` row in `p5.log` shows `fatal: .git/index: index file smaller than expected` and rc1. The dev-cycle test checks `ok docs/notes.md` before the corruption and the walk-failed skip after it. The nul_list-ignoring mutant fails it ("not ok 95").

**Evidence:** `test/scripts/dev-cycle.bats:1048-1057`; `/tmp/u2a3b-fcf2-zUrB/logs/p5.log`, `/tmp/u2a3b-fcf2-zUrB/logs/mut-nullist.log`

---

## Claim 38: Commit e48cf0f7: "the lib merged without conflicts"

**Location:** commit e48cf0f7 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers replaying the pre-rebase commits (reflog `ac1a8b7b`, base 45ad17b0) onto 97aa2d35, plus the lib being unchanged between 97aa2d35 and f6fdda68; does not verify the commit's companion claim that the tests and override log were resolved "by keeping both sides" (the replay resolved them mechanically).

Replay in a scratch clone: commit 1 conflicts only in `test/scripts/build-loop-check.bats` (`M  scripts/lib/dev-cycle-read.sh`). Commit 2 conflicts only in `docs/reviews/override-log.md`. Commit 3 applies cleanly. The lib does not differ between the two main tips.

**Evidence:** `/tmp/u2a3b-fcf2-zUrB/logs/rebase-replay.log` (cmds `bash rb.sh` then `bash rb2.sh`, cwd `/tmp/u2a3b-fcf2-zUrB`, 2026-10-07T05:12:03Z, rebase finished "Successfully rebased")

---

## Claim 39: Commit e48cf0f7: "imported_names reads its start list through U2a3's nul_list helper (tree_starts: git ls-files, untracked_md and instruction_names under pipefail), so the rc=0 listing check is written once (I2-C3)"; "IMPORTED starts as error, like IMPORTED_MAIN (I2-C5)"; "Known issue A5 and plan F11 name Claude Code 2.1.292's grammar, its revisit trigger and the backslash-escaped-space gap"; "Patch A's Unicode-space test runs the untracked .MD start on the tree walk only"; "Override rows close the three rows routed to U2a3 (fixed there in c42f017f), I2-C5 and I2-A6"

**Location:** commit e48cf0f7 message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each sentence against the diff and main; does not establish c42f017f's content beyond its presence on main.

`nul_list recs tree_starts || return 1` (`:568`) and `IMPORTED=error; ... IMPORTED_MAIN=error` (`:481`) match the first two sentences. A5 and F11 carry the version, trigger and gap (Claims 1-4), and the test is in Claim 31. `git show e48cf0f7 -- docs/reviews/override-log.md` adds three rows: "Closes this unit's three "Defer (routed to U2a3)" rows", "Closes the "IMPORTED starts as $'\n'" Defer row (iteration 2 I2-C5 ...)" and "Closes the plan and known-issues half ... (I2-A6 ...)". `git merge-base --is-ancestor c42f017f main` succeeds.

**Evidence:** `scripts/lib/dev-cycle-read.sh:481`, `:568`; `docs/reviews/override-log.md` (rows added by e48cf0f7)

---

## Claim 40: Commit e48cf0f7: "Tests: 119/119 across the five suites; shellcheck clean; a mutant that ignores nul_list's failure fails two tests. 230 changed code lines against main."

**Location:** commit e48cf0f7 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the five named suites, shellcheck on the two changed scripts, the one mutant, and pr-prep 1a's count; does not establish shellcheck on the .bats files.

The suites ran with `ok` × 119 and bats rc=0. `shellcheck -x scripts/lib/dev-cycle-read.sh scripts/dev-cycle.sh` gave rc=0. The mutant `nul_list recs tree_starts || true` failed exactly "not ok 20" (build-loop-check) and "not ok 95" (`--check-fix words a failed import walk ...`), with 117 ok. pr-prep 1a's command `git diff --numstat main...HEAD -- ':(top)' ':(top,exclude)docs/' | awk ...` printed 230 (2 + 127 + 90 + 11).

**Evidence:** `/tmp/u2a3b-fcf2-zUrB/logs/suites.log` (cmd `TMPDIR=$T timeout 900 bats <five suites>`, cwd `/tmp/u2a3b-fcf2-zUrB`, rc=0, start time in `logs/suites.ts`, 2026-10-07T05:03Z); `/tmp/u2a3b-fcf2-zUrB/logs/shellcheck.log` (rc=0); `/tmp/u2a3b-fcf2-zUrB/logs/mut-nullist.log` (2026-10-07T05:07:18Z); `workflows/pr-prep.md:91`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 3** (`docs/working/known-issues-dev-cycle.md:18`): "test/agents-gemini-sync.bats pins another copy of the regex". That file holds a separate first-character import finder modeled on Claude Code v2.1.284, not a copy of the 2.1.292 regex. Doc only.
- **Claim 8** (`scripts/lib/dev-cycle-read.sh:453`): "each call sits in an `if` or `||`". Two test calls are bare under `set -e` (`test/scripts/dev-cycle.bats:1176-1177`). True for scripts/ only. Comment only.
- **Claim 17** (`scripts/lib/dev-cycle-read.sh:504-506`): the HTML-comment sentence leaves out two things. Claude Code splices only a block that also contains `-->`, and the code's re-read also drops an unclosed comment's tail, not only closed comments. Comment only, no fail-open (Claim 19).
- **Claim 23** (`scripts/lib/dev-cycle-read.sh:512`): same as Claim 3. Comment only.

(Claims 3 and 23 are one finding at two locations.)

### Unverifiable
(none)

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved at the output path named in your role section below, structured per your skill, with a `Commit: e48cf0f7` line at the top.
- Answered: yes. All ten brief items were checked, most by execution. No Incorrect or Stale claims. Four Mostly-accurate rows (three distinct comment/doc imprecisions).
- Out of scope: the earlier three commit messages (Accepted-immutable rows); main_imports' body beyond the one lower guard; checkout-side reads (U2a3c); docs/reviews files.
- Escalate: test-strategy should note that the "called twice: cached error" check (`test/scripts/build-loop-check.bats:372-378`) does not detect a lost cache, since a no-cache mutant passes. It should also note that no test exercises main_imports' new lower guard in its import loop (`scripts/lib/dev-cycle-read.sh:657`). The author should fix the wording of Claims 3/23, 8 and 17.
- Decisions I made: read "each path once" (Claim 15) per token, the natural reading of "each token yields ..."; counted Claims 3 and 23 (the same pointer in two files) as separate rows.
