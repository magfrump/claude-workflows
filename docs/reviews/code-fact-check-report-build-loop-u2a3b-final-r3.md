# Code Fact-Check Report

Commit: e48cf0f7

**Repository:** /workspace/.claude/wt-build-loop-u2a3b (branch feat/build-loop-u2a3b)
**Scope:** `git diff main...HEAD -- scripts test docs/working` (scripts/lib/dev-cycle-read.sh, scripts/dev-cycle.sh, test/scripts/build-loop-check.bats, test/scripts/dev-cycle.bats, A5 in docs/working/known-issues-dev-cycle.md, F11 in docs/working/plan-build-loop-handoff.md) and commit e48cf0f7's message. Final confirming pass, replicate 3 of 3.
**Checked:** 2026-10-06 (container clock 2026-10-07 05:03-05:10 UTC)
**Total claims checked:** 45
**Summary:** 42 verified, 3 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Method. I self-read lib `:440-681` (INSTRUCTION_FILE through isimported), `need_root`/`blocker`/`inrepo_here` (`:95-128`) and `check_fix` with its dispatch (`scripts/dev-cycle.sh:170-203`). Probes ran on a `git archive HEAD` copy in `/tmp/u2a3b-fcf3-SR9y` (the cwd for every executed claim unless stated), under `timeout`, with `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 LC_ALL=C`. The Claude Code reference is a copy of the U2a3b security reviewer's harness (`h/cc.js` around the marked lexer extracted from 2.1.292). I also grepped the installed binary (`@anthropic-ai/claude-code` 2.1.292, `bin/claude.exe`) for the import regex; the logged match is `/(?:^|\s)@((?:[^\s\\]|\\ )+)/g` followed by `H.indexOf("#")` (`logs/reo-grep.txt`). No background processes were started. Hallucination-pattern log read; no claim matches a logged pattern.

---

## Claim 1: "imported_names and main_imports return 1 when the walk fails: call them under if or ||."

**Location:** `scripts/lib/dev-cycle-read.sh:18-19`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the return status of both walks on failure (tree walk executed here; main walk by the suite's tests 11 and 20). Does not establish that every call site follows the advice: `test/scripts/dev-cycle.bats:1176-1177` calls `imported_names` bare under `set -e`, but only on a walk that succeeds.

The tree walk returns 1 for every failure kind probed (Claim 2), and main_imports' failure path is `|| { IMPORTED_MAIN=error; return 1; }` (`:634`, `:657`). The script call sites match: `elif ! imported_names; then` (`scripts/dev-cycle.sh:181`) and `tree) imported_names || return 0;` (`:678`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:18-19`, `:634`, `:657`, `:678`; `scripts/dev-cycle.sh:181`; command `bash scripts-probe/walk.sh <repo>` per failure kind, exit 0 (rc printed per walk), `logs/walk-fail.txt` at /tmp/u2a3b-fcf3-SR9y, 2026-10-07T05:03Z
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 2: "It returns 1, with IMPORTED set to "error", when the start listing (git ls-files, untracked_md, instruction_names), lower, a file read or the parser fails, or a start file's name holds a newline"

**Location:** `scripts/lib/dev-cycle-read.sh:451-453`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named failure kind on a fixture repo: a corrupt index and a `git ls-files -z` shim (tracked listing), a git shim failing `--others` (untracked_md), a grep shim failing `-z` (instruction_names), a tr shim (lower), `chmod 000` on a start file and on an imported file (file read), a sed shim (parser), and a committed `a<NL>b/CLAUDE.md` (newline name). Does not establish a lower that fails on only some inputs.

Each case printed `1: failed rc` and `IMPORTED=[error]` (`logs/walk-fail.txt`). The code: `IMPORTED_DONE="$ROOT_REAL"; IMPORTED=error` then `nul_list recs tree_starts || return 1`, `[[ "$f" != *$'\n'* ]] || return 1`, `lp="$(lower "${f##*/}")" || return 1` (`:567-572`); `IMPORTED=$'\n'` is set only after the start loop (`:577`); `out="$(import_targets "$d" < "$f")" || { IMPORTED=error; return 1; }` (`:581`); `lp="$(lower "$p")" || { IMPORTED=error; return 1; }` (`:584`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:563-588`; command `bash /tmp/u2a3b-fcf3-SR9y/scripts-probe/walk.sh <repo>` (with `PATH=bins/{tr,grep,sed,gitut,gitls}:$PATH` per case), exit 0, `logs/walk-fail.txt`, 2026-10-07T05:03Z
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 3: "(each call sits in an `if` or `||`, where set -e is off)"

**Location:** `scripts/lib/dev-cycle-read.sh:453`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the failing calls inside imported_names and its two script callers. Does not cover the bare test call at `test/scripts/dev-cycle.bats:1176`, which runs only on a succeeding walk.

Inside the function: `nul_list recs tree_starts || return 1` (`:568`), `lp="$(lower "${f##*/}")" || return 1` (`:572`), `if [[ ! "$lp" =~ $INSTRUCTION_FILE ]] || ! inrepo_here "$f"; then continue; fi` (`:573`), `out="$(import_targets "$d" < "$f")" || {` (`:581`). Callers: `elif ! imported_names` (`scripts/dev-cycle.sh:181`) and `imported_names || return 0` (`:678`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:563-588`, `:678`; `scripts/dev-cycle.sh:181`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 4: "an inrepo_here that fails skips its path"

**Location:** `scripts/lib/dev-cycle-read.sh:453-454`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers start files and import targets: both skip without failing the walk. Does not establish what Claude Code does with a symlinked file (known issues A2 and A3).

Starts: `if [[ ! "$lp" =~ $INSTRUCTION_FILE ]] || ! inrepo_here "$f"; then continue; fi` (`:573`). Targets: `if [[ "$seen" != *$'\n'"$p"$'\n'* ]] && inrepo_here "$p"; then seen+=...; queue+=("$p"); fi` (`:585`). The target's name is still recorded (`IMPORTED+="$lp"$'\n'`, `:584`), and only the walk into it is skipped. A probe with a symlinked `docs/CLAUDE.md` walked (`1: walked`, `logs/walk-fail.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:128`, `:573`, `:584-585`; `logs/walk-fail.txt` ("symlinked start")
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 5: "One result is cached, for the root in IMPORTED_DONE; a call for another ROOT_REAL recomputes it, and a cached error returns 1 again."

**Location:** `scripts/lib/dev-cycle-read.sh:454-456`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cached error surviving the removal of its cause, and recomputation after `IMPORTED_DONE` is cleared. The another-root half rests on the existing dev-cycle.bats test at `:1170-1180`, which passed.

`[[ "$IMPORTED_DONE" == "$ROOT_REAL" ]] && { [[ "$IMPORTED" != error ]]; return; }` (`:566`). Probe: walk with a failing tr, then the real tr on the same root, then `IMPORTED_DONE=""`. Output: `shimmed: failed` / `unshimmed same root: failed (cached)` / `after reset: walked [|docs/a.md|]`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:566-567`; command `bash -c '... imported_names ...' _ scripts/lib/dev-cycle-read.sh bins/tr` in `repo-c-*`, exit 0, `logs/cache.txt`, 2026-10-07T05:04Z
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 6: "UTF-8 spaces that end an import token as a blank does (import_targets makes each one a blank before it matches tokens): U+00A0, U+1680, U+2000-200A, U+2028/2029, U+202F, U+205F, U+3000 and U+FEFF (Claude Code's token ends at JavaScript's \s, which includes U+FEFF)."

**Location:** `scripts/lib/dev-cycle-read.sh:482-488`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the array equals JavaScript's non-ASCII `\s` set and the sed-before-grep order. Does not cover ASCII `\s` members, which `[:space:]` in the C locale handles.

Node enumerates 19 non-ASCII `\s` code points, and their UTF-8 bytes equal the 19 `UNI_SPACES` entries byte for byte (`logs/js-space.txt`). `for u in "${UNI_SPACES[@]}"; do s+=(-e "s/$u/ /g"); done` and `toks="$(env LC_ALL=C sed "${s[@]}")"` (`:516-518`) run before the grep at `:529`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:486-488`, `:516-529`; command `node -e '...'` plus a `UNI_SPACES` hex dump, exit 0, `logs/js-space.txt`, 2026-10-07T05:10Z
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 7: "it ends at a blank, a UNI_SPACES space included, or at a backslash, as the import token of Claude Code does, and at #, where Claude Code cuts the name it captured (so a token after a # is an over-read; a name holding a backslash-escaped space is not read, known issue A5)"

**Location:** `scripts/lib/dev-cycle-read.sh:494-498`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the token end against 2.1.292's regex (binary grep plus harness) for `\ `, `\b`, `\\` and `#`. Does not establish token ends for Claude Code versions other than 2.1.292.

`IMPORT_RE='(^|[^[:alnum:]])@[^[:space:]\\#]+'` (`:489`). The binary's regex is `(?:[^\s\\]|\\ )+`, then `H.indexOf("#")` cuts (`logs/reo-grep.txt`). Differential (`logs/cmp1.txt`): `@docs/a#frag.md` gives CC `docs/a`, walk `docs/a`. `@docs/a\b.md` gives both `docs/a`. `@my\ notes.md` gives CC `my notes.md` and the walk `my`, which is the parenthetical's stated A5 gap. The comment's own exception covers the one case where CC continues past a backslash.

**Evidence:** `scripts/lib/dev-cycle-read.sh:489`, `:494-498`; command `bash scripts-probe/cmp.sh c/*.md`, exit 0, `logs/cmp1.txt` (cases c01-c03, c17), `logs/reo-grep.txt`, 2026-10-07T05:02Z
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 8: "That regex keeps brackets, parentheses, backticks and trailing punctuation in a name (@x.md. reads x.md.)"

**Location:** `scripts/lib/dev-cycle-read.sh:498-500`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regex capture. Does not establish what the Markdown lexer leaves of such a name (Claim 9).

The binary's class `[^\s\\]` excludes no bracket, parenthesis, backtick or punctuation. The harness shows `@docs/a.md...` → CC `docs/a.md...` and `@docs/q.md`` ` → CC ``docs/q.md`` `` (`logs/cmp1.txt` c11, c13).

**Evidence:** `logs/reo-grep.txt`; `logs/cmp1.txt` (c11, c13)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 9: "so each token yields its whole and its part before each of [ ] ( ) < ! * _ and backtick, each also with trailing . , ; : ! ? * _ ~ ) ] or backticks stripped, each path once"

**Location:** `scripts/lib/dev-cycle-read.sh:502-504`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every cut mark alone, repeated and mixed, and the strip set, per token. "each path once" holds per token only: `n=$'\n'` is reset for each token (`:532`), so the same path can print twice across tokens or across the HTML re-read copy (`docs/p` twice in `logs/cmp1.txt` c07). Both walks tolerate the duplicates.

`cut="[][()<!*_$b]"` (`:515`); `v="$r"; while [[ "$v" == *[.,\;:!?*_~\)\]] || "$v" == *"$b" ]]; do v="${v%?}"; done` (`:535`); `[[ "$r" == *$cut* ]] || break` / `r="${r%$cut*}"` (`:543-545`). Probes: `@a**b__c` → `a**b__c a**b_ a**b a* a`; `@x[a-z]y_z` → `x[a-z]y_z x[a-z]y x[a-z x`; `` @a`b `` → `` a`b a ``; `@!!!` → `!!! !! !` (`logs/cut.txt`). Each pass strictly shortens `r`, so the loop ends. No probe dropped a prefix, and the unquoted `$cut` works as a bracket in both the `[[ ]]` test and the `%` removal, the backtick member included.

**Evidence:** `scripts/lib/dev-cycle-read.sh:513-548`; command `bash scripts-probe/it.sh c/cutN.md` for 16 tokens, exit 0, `logs/cut.txt`, 2026-10-07T05:06Z
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 10: "Claude Code deletes the HTML comments of a block that opens with <!-- and reads what is left, so text holding <!-- is also read once more with every closed comment removed."

**Location:** `scripts/lib/dev-cycle-read.sh:504-506`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both halves against the binary's `reo` and the code. Does not establish block boundaries for HTML kinds other than comments.

Both halves are directionally right and the walk is a superset, but each half leaves out a condition. (a) Claude Code deletes comments only when the block opens with `<!--` *and* holds `-->`. The code is `if(H.startsWith("<!--")&&H.includes("-->")){let z=w.replace(/<!--[\s\S]*?-->/g,"")...}continue`, so a block with an unclosed comment is skipped whole (`<!-- unclosed\n@docs/u.md` → CC reads nothing, `logs/cmp1.txt` c16). (b) The walk's re-read copy drops more than the closed comments. It also drops everything after an unclosed `<!--`: `if [[ "$x" == *'-->'* ]]; then x="${x#*'-->'}"; else x=""; fi` (`:523`). The original copy is still read (`toks+=$'\n'"$y$x"`, `:525`), so nothing is lost. A precise version would say "a block that opens with <!-- and closes one" and "with every comment removed, and an unclosed one's tail". Splices (c06, c07 `docs/qr.md`, the multi-line c08 `docs/mn.md`) all came out in the walk.

**Evidence:** `scripts/lib/dev-cycle-read.sh:519-526`; `h/cc.js` (copied `reo`); `logs/cmp1.txt` (c06-c08, c15, c16)
**Legibility-target:** for-author

---

## Claim 11: "A NUL counts as a blank."

**Location:** `scripts/lib/dev-cycle-read.sh:506`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk's rule. It is not a claim about Claude Code, which does not treat NUL as `\s` (CC reads `docs/a.md\0@docs/b.md` as one name, which no path can hold).

`s=(-e 's/\x0/ /g')` (`:514`). `x @docs/a.md\0@docs/b.md` → walk `docs/a.md docs/b.md` (`logs/cmp1.txt` c09).

**Evidence:** `scripts/lib/dev-cycle-read.sh:514`; `logs/cmp1.txt` (c09)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 12: "Over-reading only over-refuses." (the re-read copy cannot suppress a name the first copy yields)

**Location:** `scripts/lib/dev-cycle-read.sh:506-507`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the union of the two copies and the per-token dedup. Does not establish that every over-read is harmless to other consumers (the only consumers are the two walks' import sets).

The comment-stripped copy is appended to the text, not substituted for it: `toks+=$'\n'"$y$x"` (`:525`). Dedup is per token (`n`, `cs` reset at `:532`), so a later token cannot hide an earlier one's output. In every differential case the walk lists all of the original copy's names (`logs/cmp1.txt` c06, c07, c15).

**Evidence:** `scripts/lib/dev-cycle-read.sh:519-547`; `logs/cmp1.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 13: "~/ and absolute paths, and paths leaving the repo (.. or ../, not a ..x name), are dropped."

**Location:** `scripts/lib/dev-cycle-read.sh:507-508`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `~/`, `/abs`, `../`, `..x` and `~y` (kept). Does not cover absolute imports into the repo, which A5 lists as a gap.

`[[ -n "$w" && "$w" != \~/* && "$w" != /* && ...` (`:537`) and `[[ "$p" != .. && "$p" != ../* && ...` (`:540`). `See @~/x.md @/abs.md @../out.md @..x.md @docs/../in.md @~y.md` → walk `..x.md in.md ~y.md` (`logs/cmp1.txt` c10).

**Evidence:** `scripts/lib/dev-cycle-read.sh:537-540`; `logs/cmp1.txt` (c10)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 14: "It reads ROOT_REAL without checking it (the caller has run need_root)"

**Location:** `scripts/lib/dev-cycle-read.sh:508-509`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both script callers. Does not cover direct test calls of import_targets, which set ROOT_REAL themselves.

import_targets has no `need_root`. Its only script callers are imported_names (`need_root` at `:565`, call at `:581`) and main_imports (`need_root` at `:604`, call at `:634`) (paraphrased — no quote available because the claim covers absence of other callers; `grep -rn import_targets scripts` lists only `:513`, `:581`, `:634`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:513-548`, `:565`, `:581`, `:604`, `:634`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 15: "and returns 1 when sed or grep fails"

**Location:** `scripts/lib/dev-cycle-read.sh:509`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a sed shim exiting 4, a directory as stdin (sed read error, the suite's test 20), and a grep shim exiting 2 on `-ao`, each with and without matches. Does not cover a realpath failure, which skips the name (`|| continue`, `:539`) by design.

`toks="$(env LC_ALL=C sed "${s[@]}")" || return 1` (`:518`) and `... | env LC_ALL=C grep -aoE "$IMPORT_RE")" || [[ $? -eq 1 ]] || return 1` (`:529`). Grep shim: `grepfail rc=1` for a file with an import and one without. Real grep: `normal rc=0` for both (`logs/grepfail.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:518`, `:529`; command `PATH=bins/grepa:$PATH bash -c 'source ...; import_targets "" < c/g.md'`, exit 0, `logs/grepfail.txt`, 2026-10-07T05:08Z; `logs/walk-fail.txt` ("shim sed")
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 16: "The rules follow Claude Code 2.1.292's import regex and Markdown lexer (U2a2 security review); re-check them when Claude Code changes either (test/agents-gemini-sync.bats pins another copy of the regex)."

**Location:** `scripts/lib/dev-cycle-read.sh:509-512`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the version (the installed package is 2.1.292 and its binary holds the regex) and the two pointers. Does not establish the rules for other Claude Code versions.

The version is right: `"version": "2.1.292"`, and the binary holds `/(?:^|\s)@((?:[^\s\\]|\\ )+)/g` (`logs/reo-grep.txt`). The two pointers are loose. (a) `test/agents-gemini-sync.bats` holds no copy of this regex or of IMPORT_RE. Its finder is `grep -nE '(^|[^[:alnum:]])@(\./|~/|/|[[:alnum:]._-])'` (`test/agents-gemini-sync.bats:50`), an over-approximation of the token *start* only, and its comment cites "Claude Code v2.1.284" (`:37`). It is a second place to re-check on an upgrade, not a copy. (b) The HTML-comment rule comes from the U2a3b security review (F2), not the U2a2 one. A5 cites both reviews, but this comment cites only U2a2. Precise version: "test/agents-gemini-sync.bats holds a related import-start finder (from 2.1.284)" and "(U2a2 and U2a3b security reviews)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:509-512`; `test/agents-gemini-sync.bats:37-51`; `docs/reviews/security-reviewer-review-2026-10-06-final-build-loop-u2a2.md:11`; `docs/reviews/security-reviewer-review-2026-10-06-build-loop-u2a3b.md:83-96`; command `grep -aoE ... bin/claude.exe`, exit 0, `logs/reo-grep.txt`, 2026-10-07T05:05Z
**Legibility-target:** for-author

---

## Claim 17: "# the cut marks as a glob bracket (b: a backtick)" and "# r walks back through the token's prefixes, one per cut mark."

**Location:** `scripts/lib/dev-cycle-read.sh:515`, `:533`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the bracket's members and the one-prefix-per-mark walk. Does not establish anything about the strip step (Claim 9).

`b=$'\x60'` (`:514`), `cut="[][()<!*_$b]"` (`:515`). Each mark used alone (`a[b`, `a]b`, `a(b`, `a)b`, `a<b`, `a!b`, `a*b`, `a_b`, `` a`b ``) yields `a` (`logs/cut.txt`), and `a[[b]]c` yields one prefix per mark: `a[[b] a[[b a[ a`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:514-515`, `:533-546`; `logs/cut.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 18: "Two steps, not a pipe: under pipefail grep's "no match" would hide a sed failure."

**Location:** `scripts/lib/dev-cycle-read.sh:517`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the pipeline-status reasoning. Does not cover callers without pipefail, where a piped sed's failure would be invisible anyway.

Under pipefail a pipeline's status is the rightmost non-zero one, so a failed sed followed by grep's 1 gives 1, and `|| [[ $? -eq 1 ]]` (`:529`) would read that as no match. The split `toks="$(env LC_ALL=C sed "${s[@]}")" || return 1` (`:518`) checks sed on its own (paraphrased — no quote available because the claim concerns the alternative not written, a pipe).

**Evidence:** `scripts/lib/dev-cycle-read.sh:517-518`, `:529`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 19: "A pipe, not a here-string: bash writes a long here-string to a temp file, and a failed write would read as "no match"."

**Location:** `scripts/lib/dev-cycle-read.sh:527-528`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15's here-string temp-file threshold and a here-string mutant. Does not cover other bash versions.

Under `trap "" XFSZ; ulimit -f 0`, here-strings of 65000 bytes work and 65536 or more print `cannot create temp file for here-document: File too large` (`logs/herestring.txt`). Mutant m2 replaces `:529` with `grep -aoE "$IMPORT_RE" <<<"$toks"`, and the ulimit case fails: `[ "$status" -eq 0 ] && [ "$output" = docs/big.md ]` fails at `test/scripts/build-loop-check.bats:385` (`logs/mutant-m2.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:527-529`; commands `bash -c 'trap "" XFSZ; ulimit -f 0; ... wc -c <<<"$s"'` (exit 0, `logs/herestring.txt`) and `TMPDIR=... bats test/scripts/build-loop-check.bats test/scripts/dev-cycle.bats` in `/tmp/u2a3b-fcf3-SR9y/m2` (exit 1, `logs/mutant-m2.txt`), 2026-10-07T05:07Z
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 20: "It returns 0 when no name matches and 1 when grep fails (grep's own no-match is 1)."

**Location:** `scripts/lib/dev-cycle-read.sh:552-553`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers match, no match, and a grep exiting 2. Does not cover grep killed by a signal (status above 128, also returned as 1).

`instruction_names() { env LC_ALL=C grep -zaiE '...' || [[ $? -eq 1 ]]; }` (`:554`). Runs: match `rc=0`, no match `nomatch rc=0`, grep shim `grep-fail rc=1`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:554`; command `bash scripts-probe/inames.sh` in /tmp/u2a3b-fcf3-SR9y, exit 0, `logs/instruction-names.txt`, 2026-10-07T05:13Z (`logs/walk-fail.txt` "shim grep" shows the walk-level effect)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 21: "The tree walk's start candidates, NUL-separated: tracked and untracked names through instruction_names, failing when any of the three commands fails."

**Location:** `scripts/lib/dev-cycle-read.sh:560-562`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a failing `git ls-files -z`, a failing `untracked_md` and a failing `instruction_names`, plus nul_list's "empty or ended in NUL" rule on grep -z output (each record NUL-terminated, empty output gives `rc=0` alone). Does not cover a listing that succeeds with wrong content.

`tree_starts() { local -; set -o pipefail; { git ls-files -z && untracked_md; } | instruction_names; }` (`:562`), read through `nul_list recs tree_starts || return 1` (`:568`). The shims `gitls`, `gitut` and `grep` each give `1: failed rc`, `IMPORTED=[error]`, and `--check-fix` prints the walk-failed skip (`logs/walk-fail.txt`, `logs/checkfix.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:554-562`, `:568`; `logs/walk-fail.txt`; `logs/checkfix.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 22: "seen is newline-separated: a name holding a newline could hide another start."

**Location:** `scripts/lib/dev-cycle-read.sh:570`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the collision mechanism and that the walk now fails before it. Does not cover main_imports, which has its own newline check (`:612`, `:618`).

`seen+="$f"$'\n'` with `[[ "$seen" == *$'\n'"$f"$'\n'* ]] && continue` (`:574-575`). Once `a<NL>b/CLAUDE.md` is added, the string holds `<NL>b/CLAUDE.md<NL>`. The guard `[[ "$f" != *$'\n'* ]] || return 1` (`:571`) stops the walk first. A committed newline name gives `1: failed rc` (`logs/walk-fail.txt`), and in `--check-fix` it gives the walk-failed skip (`logs/checkfix.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:569-576`; `logs/walk-fail.txt`; `logs/checkfix.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 23: "A failed walk, a failed lower of $2, or a walk name that is neither answers imported (0), so a caller testing it with `if` refuses; a caller that words a failed walk runs the walk first (imported_names or main_imports, under if)."

**Location:** `scripts/lib/dev-cycle-read.sh:668-671`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tree and bogus walk names and a failing tr (the walk and lower of $2 both fail). The main branch rests on the suite. Does not separate a lower failure of $2 from a walk failure in one run, because a tr shim fails both.

`lp="$(lower "$2")" || return 0`; `tree) imported_names || return 0;`; `*) return 0 ;;` (`:675-679`). Every failing probe printed `z: imported` (`logs/walk-fail.txt`). check_fix runs `elif ! imported_names` before `isimported tree` (`scripts/dev-cycle.sh:181-183`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:672-681`; `scripts/dev-cycle.sh:181-183`; `logs/walk-fail.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 24: check_fix: "skip $a: the instruction-file import walk failed, so an import of it cannot be ruled out; file it instead" (reached for every failure kind, in the caller's shell)

**Location:** `scripts/dev-cycle.sh:181-182`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers listing (corrupt index, ls-files and --others shims), name filter (grep -z shim), parser (sed shim), file read (`chmod 000 GEMINI.md`) and newline-name failures, and a second argument served from the same cached error. Does not cover a tr failure: then `dev-cycle.sh --check-fix` exits 1 with no output before this branch is reached (`### shim tr` / `rc=1`), which still fails closed but carries no wording. The likely cause is `check_fix`'s own `lp="$(printf '%s' "$a" | tr ...)"` (`:175`) under `set -euo pipefail` (`:83`); the exact exit line was not traced because the script re-execs through `scrub`.

check_fix runs inline in the dispatch loop: `--check-fix) check_fix "$a" ;;` (`:202`), so the walk's cache is the one `isimported tree` reads next. With two arguments each failing shim printed the walk-failed skip twice and exited 0 (`logs/checkfix.txt`).

**Evidence:** `scripts/dev-cycle.sh:170-185`, `:202`; command `bash scripts/dev-cycle.sh --check-fix docs/notes.md docs/c.md` per shim in `repo-*`, exit 0 (tr: exit 1), `logs/checkfix.txt`, 2026-10-07T05:03Z
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 25: "walk: ok" or "walk: failed" (main_imports' or imported_names' return)

**Location:** `test/scripts/build-loop-check.bats:14`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the imps helper. Does not cover an unknown walk name, which prints "walk: failed" from neither walk.

`if { [[ "$w" == main ]] && main_imports; } || { [[ "$w" == tree ]] && imported_names; }; then echo "walk: ok"; else echo "walk: failed"; fi` (`:20`).

**Evidence:** `test/scripts/build-loop-check.bats:13-24`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 26: "Two NBSPs in one run: the token ends at the first. docs/z.md is imported only after the NUL; gone/ does not exist, and the path is still resolved as written." / "Docs/NB.MD and CLAUDE.md: isimported takes a path in any case."

**Location:** `test/scripts/build-loop-check.bats:29-30`, `:37`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fixture's shapes (test 1 passes). The second NBSP follows `for`, not a token, so this test does not show that a second NBSP becomes a blank. Test 4 shows that instead (mutant m4 fails test 4 and passes test 1, `logs/mutant-m4.txt`).

The fixture holds `@docs/nb.md\xc2\xa0for\xc2\xa0you`, `@gone/../docs/m.md` and `@docs/a.md\0 then @docs/z.md` (`:31`), and `ps` holds `docs/z.md docs/m.md Docs/NB.MD CLAUDE.md` (`:38`), all wanted imported.

**Evidence:** `test/scripts/build-loop-check.bats:26-41`; `logs/suites.txt`; `logs/mutant-m4.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 27: "Without ROOT_REAL it stops (need_root) for any walk name, before answering."

**Location:** `test/scripts/build-loop-check.bats:47`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the bogus walk name, as the test runs it. Does not separately run tree or main without ROOT_REAL.

`isimported() { local lp; need_root; ...` (`scripts/lib/dev-cycle-read.sh:672-674`): need_root comes before any answer. The test asserts status 1, empty output and `ROOT_REAL is not set` (`:50`), and it passes (`logs/suites.txt`).

**Evidence:** `test/scripts/build-loop-check.bats:47-50`; `scripts/lib/dev-cycle-read.sh:95-99`, `:672-674`; `logs/suites.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 28: test "both walks: every Unicode space JavaScript's \s holds ends a token; SKILL.md starts them; an untracked upper-case .MD starts the tree walk (U2a3b)"

**Location:** `test/scripts/build-loop-check.bats:53`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all three clauses. The untracked start is run on the tree walk only, and the comment says why (the main walk fails closed on it until U2a3c: `[[ "${cand[i]:0:1}" == m ]] || return 1`, lib `:625`).

All 19 code points are written as `@../docs/u$i.md<sp>x` into `sub/SKILL.md`, the fixture's only instruction file (`bl_setup` creates none). A space that did not end the token would leave no name equal to `docs/uN.md`. Mutant m3 removes `skill` from INSTRUCTION_FILE and instruction_names, and this test fails with `want: docs/u0.md: imported` (`logs/mutant-m3.txt`). The untracked `docs/AGENTS.MD` with `@k.md` must yield `docs/k.md` (`:63-66`).

**Evidence:** `test/scripts/build-loop-check.bats:53-67`; `test/lib/build-loop-fixtures.bash:7-28`; command `TMPDIR=... bats -f 'Unicode|both walks read what' test/scripts/build-loop-check.bats` in `/tmp/u2a3b-fcf3-SR9y/m3`, exit 1, `logs/mutant-m3.txt`, 2026-10-07T05:09Z
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 29: test "both walks read what Claude Code reads: an @ after a Unicode space, Markdown and a code span around a token, ( ) in a name; ~x is over-read, ~/ dropped (U2a3)" and its comment ("A cut mark earlier in the name (my_notes) does not hide a later one; two NBSPs on a line both become blanks; an HTML block's comment splices a name (sec+ret)")

**Location:** `test/scripts/build-loop-check.bats:339-343`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed shape on both walks. The unit tag reads "(U2a3)" although the test was added on this branch (U2a3b), unlike the branch's other new tests, which read "(U2a3b)". That is a label, not a behavioral claim. Does not establish shapes beyond the fixture.

`docs/my_notes.md`, `docs/p.md docs/q.md docs/r.md` and `docs/secret.md` are in `ps` (`:346-347`) and wanted imported for `tree` and `main`. Mutant m4 (`s/$u/ /` without `g`) fails this test with `want: docs/q.md: imported` (`logs/mutant-m4.txt`). The CC harness confirms `docs/secret.md` and `docs/my_notes.md` are what 2.1.292 reads for these shapes (`logs/cmp1.txt` c04, c06).

**Evidence:** `test/scripts/build-loop-check.bats:339-354`; `logs/mutant-m4.txt`; `logs/cmp1.txt`; `logs/suites.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 30: test "both walks fail closed when tr fails; the tree walk fails closed when its start listing fails or a start name holds a newline; the parser returns 1 when it cannot read its input (U2a3)"

**Location:** `test/scripts/build-loop-check.bats:357`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each clause as the test runs it. `imps` now calls `imported_names` itself, so the tree half's "walk failed" is the walk's own failure, which closes iteration 2's Claim 12 caveat. Same "(U2a3)" label note as Claim 29.

The tr loop runs `imps "$w"` for `tree main` with `want walk failed` (`:360-362`). The grep `-z` shim and a corrupt index cover the start listing (`:364-366`, `:386-392`), `a<NL>b` covers the newline name (`:368-371`), and `import_targets "" < docs` covers the parser. Mutant m1 (`nul_list recs tree_starts || true`) fails this test (`logs/mutant-m1.txt`).

**Evidence:** `test/scripts/build-loop-check.bats:357-393`; `logs/mutant-m1.txt`; `logs/suites.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 31: "The tree walk itself, called twice: the second call returns its cached error."

**Location:** `test/scripts/build-loop-check.bats:372`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** The behavior is true (Claim 5, `logs/cache.txt`). The test does not tell a cached error from a recomputed one, because the tr shim stays on PATH for both calls. It does catch a cache that returns 0.

`run --separate-stderr env PATH="$BATS_TEST_TMPDIR/bin:$PATH" ... if imported_names; ... if imported_names; ...` (`:373-376`) with expected `failed / walk failed / walk failed` (`:377-379`).

**Evidence:** `test/scripts/build-loop-check.bats:372-379`; `scripts/lib/dev-cycle-read.sh:566`; `logs/cache.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 32: "A file past bash's here-string pipe size (64 KiB) with no room for a temp file (ulimit -f 0): the import at its end is still read."

**Location:** `test/scripts/build-loop-check.bats:380-381`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 64 KiB threshold on bash 5.2.15 and that the test catches a here-string. Does not cover other bash builds.

The threshold is measured at 65536 bytes (`logs/herestring.txt`), and the fixture is 70000 bytes plus the import line (`:382`). Mutant m2 fails the test (Claim 19).

**Evidence:** `test/scripts/build-loop-check.bats:380-385`; `logs/herestring.txt`; `logs/mutant-m2.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 33: "A corrupt index: git ls-files fails, so the tree walk has no start list." / "A corrupt index: git ls-files fails, so the walk has no start list."

**Location:** `test/scripts/build-loop-check.bats:386`; `test/scripts/dev-cycle.bats:1053`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's response to a 4-byte index. Does not cover other index corruptions.

`printf 'junk' > .git/index` gives `fatal: .git/index: index file smaller than expected` and `1: failed rc` (`logs/walk-fail.txt`, "corrupt index").

**Evidence:** `test/scripts/build-loop-check.bats:386-392`; `test/scripts/dev-cycle.bats:1053-1056`; `logs/walk-fail.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 34: test "--check-fix words a failed import walk as one and refuses (U2a3b)"

**Location:** `test/scripts/dev-cycle.bats:1048`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the wording and the refusal for a listing failure, after a control run that prints `ok docs/notes.md`. Other failure kinds are covered by Claim 24.

`[[ "$output" == "skip docs/notes.md: the instruction-file import walk failed"* ]]` (`:1056`). Mutant m1 fails it (`not ok 76`, `logs/mutant-m1.txt`).

**Evidence:** `test/scripts/dev-cycle.bats:1048-1057`; `logs/mutant-m1.txt`; `logs/suites.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 35: "a name holding a backslash-escaped space (`@my\ notes.md`, which Claude Code reads as `my notes.md`; both walks end the token at the backslash)"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 2.1.292's reading and the shared parser. Both walks call `import_targets` (`:581`, `:634`).

CC `my notes.md`, walk `my` (`logs/cmp1.txt` c02). The binary's `H.replaceAll("\\ "," ")` follows the capture (`logs/reo-grep.txt`).

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`; `scripts/lib/dev-cycle-read.sh:489`, `:581`, `:634`; `logs/cmp1.txt`; `logs/reo-grep.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 36: "Both walks share one token parser (`import_targets`) that follows Claude Code 2.1.292's import regex and Markdown lexer (U2a2 and U2a3b security reviews; `test/agents-gemini-sync.bats` pins another copy of the regex); revisit trigger: a Claude Code upgrade that changes either, which can make the walks miss imports."

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Reference / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the shared parser, the version, the review citations and the bats pointer. Does not evaluate the revisit trigger's sufficiency, which is a judgement.

"Both walks share one token parser" holds (`:581`, `:634`), and both reviews are cited. "pins another copy of the regex" is loose, for the same reason as Claim 16(a): `test/agents-gemini-sync.bats:50` holds a start-only finder `(^|[^[:alnum:]])@(\./|~/|/|[[:alnum:]._-])` written against v2.1.284 (`:37`), not a copy of the import regex.

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`; `test/agents-gemini-sync.bats:37-51`; `scripts/lib/dev-cycle-read.sh:581`, `:634`
**Legibility-target:** for-author

---

## Claim 37: F11: "a backslash-escaped space in a name" (gap) and "The shared token parser follows Claude Code 2.1.292's grammar (U2a3b); a Claude Code upgrade that changes its import regex or Markdown lexer reopens this row."

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the gap entry (Claim 35) and the version. "follows" holds with the gaps A5 lists.

The installed package is 2.1.292, and its regex and `#` cut match the parser's model (Claim 7). The escaped-space gap is the one executed in Claim 35.

**Evidence:** `docs/working/plan-build-loop-handoff.md:126`; `logs/reo-grep.txt`; `logs/cmp1.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 38: "the lib merged without conflicts, the tests and the override log were resolved by keeping both sides"

**Location:** commit e48cf0f7 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rebase onto 97aa2d35, the one whose reflog shows `rebase (continue)`, replayed in a scratch clone. The rebase onto f6fdda68 picked all three commits cleanly per the reflog. Does not verify "keeping both sides" as the resolution method.

Replaying the picks: 1ccc8b65 onto 97aa2d35 conflicts only in `test/scripts/build-loop-check.bats`; 7ddff454 onto 6069e522 conflicts in `docs/reviews/override-log.md` and `test/scripts/build-loop-check.bats`; ac1a8b7b onto a1cc6294 is clean. The lib conflicts in none of them (`logs/repick.txt`).

**Evidence:** command `git cherry-pick <c>` in `/tmp/u2a3b-fcf3-SR9y/clone` (detached at each base), exit 1/1/0, `logs/repick.txt`, 2026-10-07T05:06Z; `git reflog` of the worktree
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 39: commit bullets: "imported_names reads its start list through U2a3's nul_list helper (tree_starts: git ls-files, untracked_md and instruction_names under pipefail), so the rc=0 listing check is written once (I2-C3)"; "IMPORTED starts as error, like IMPORTED_MAIN (I2-C5)"; "Patch A's Unicode-space test runs the untracked .MD start on the tree walk only"; "Override rows close the three rows routed to U2a3 (fixed there in c42f017f), I2-C5 and I2-A6."

**Location:** commit e48cf0f7 message
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each bullet against the tree. For IMPORTED starting as error, no reader reads IMPORTED before `imported_names` runs. Script and test readers: `:678` after a successful walk; `dev-cycle.bats:1101` (declared only) and `:1176-1177` (after the walk); `build-loop.sh` none. A lookup against `error` answers not-imported, the same as the old `$'\n'`.

`nul_list()` is on main (`git show main:scripts/lib/dev-cycle-read.sh`), and `rc=0` now appears only in it (`:559`; d894b3f0 had a second copy at `:566-567`). `IMPORTED=error; IMPORTED_DONE=""; IMPORTED_MAIN=error` (`:481`). The Unicode test's comment and its `imps tree` call (`test/scripts/build-loop-check.bats:63-64`) match the tree-only bullet. The three override rows are present, and c42f017f is on main.

**Evidence:** `scripts/lib/dev-cycle-read.sh:481`, `:559-568`; `test/scripts/build-loop-check.bats:63-66`; `git diff d894b3f0 e48cf0f7 -- docs/reviews/override-log.md`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 40: "Known issue A5 and plan F11 name Claude Code 2.1.292's grammar, its revisit trigger and the backslash-escaped-space gap (I2-A6, second half)."

**Location:** commit e48cf0f7 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers presence of the three items in both rows. Their precision is covered by Claims 35-37.

A5 holds "a backslash-escaped space (`@my\ notes.md` ...)" and "revisit trigger: a Claude Code upgrade". F11 holds "a backslash-escaped space in a name" and "reopens this row".

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`; `docs/working/plan-build-loop-handoff.md:126`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 41: "Tests: 119/119 across the five suites"

**Location:** commit e48cf0f7 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the five suites named in the shared context at e48cf0f7 on this host.

119 `ok` lines and no `not ok`.

**Evidence:** command `TMPDIR=/tmp/u2a3b-fcf3-tmp-REp6 bats test/scripts/build-loop-check.bats test/scripts/build-loop-read.bats test/scripts/dev-cycle.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats` in /tmp/u2a3b-fcf3-SR9y, exit 0, `logs/suites.txt`, 2026-10-07T05:05Z
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 42: "shellcheck clean"

**Location:** commit e48cf0f7 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two changed scripts with the repo's `.shellcheckrc`. Does not cover the bats files.

No output.

**Evidence:** command `shellcheck scripts/lib/dev-cycle-read.sh scripts/dev-cycle.sh` in /tmp/u2a3b-fcf3-SR9y, exit 0, `logs/shellcheck.txt` (empty), 2026-10-07T05:09Z
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 43: "a mutant that ignores nul_list's failure fails two tests"

**Location:** commit e48cf0f7 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mutant `nul_list recs tree_starts || true` over build-loop-check.bats and dev-cycle.bats (the other three suites do not reach the tree walk).

`not ok 20 both walks fail closed when tr fails; ...` and `not ok 76 --check-fix words a failed import walk as one and refuses (U2a3b)`; 94 ok.

**Evidence:** command `TMPDIR=... bats test/scripts/build-loop-check.bats test/scripts/dev-cycle.bats` in `/tmp/u2a3b-fcf3-SR9y/m1`, exit 1, `logs/mutant-m1.txt`, 2026-10-07T05:07Z
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 44: "230 changed code lines against main"

**Location:** commit e48cf0f7 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers added plus deleted lines outside `docs/` (pr-prep 1a).

`git diff --numstat main...HEAD` outside `docs/`: `2 0 scripts/dev-cycle.sh`, `89 38 scripts/lib/dev-cycle-read.sh`, `86 4 test/scripts/build-loop-check.bats`, `11 0 test/scripts/dev-cycle.bats`. That is 188 + 42 = 230.

**Evidence:** command `git -C /workspace/.claude/wt-build-loop-u2a3b diff --numstat main...HEAD`, exit 0, `logs/numstat.txt`, 2026-10-07T05:10Z
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 45: "UTF-8 spaces ... Claude Code's token ends at JavaScript's \s" and "A token may follow any byte but a letter or digit (so user@host is not one)" as a superset of Claude Code's start rule

**Location:** `scripts/lib/dev-cycle-read.sh:484-485`, `:493-494`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the start rule as an over-read of 2.1.292's `(?:^|\s)@`. The walk starts a token after any non-alnum byte, so it reads more than CC (`*@docs/e.md*` is found by both). Does not establish CC's later `EP(H)` filter, which the harness omits.

`IMPORT_RE='(^|[^[:alnum:]])@...'` (`:489`). The binary needs `^` or `\s` before `@` (`logs/reo-grep.txt`). In every differential case the walk's names include CC's, except the stated A5 escaped-space gap and the unrepresentable NUL name (`logs/cmp1.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:489`, `:493-494`; `logs/reo-grep.txt`; `logs/cmp1.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- **Claim 10** (`scripts/lib/dev-cycle-read.sh:504-506`): Claude Code deletes comments only in a `<!--` block that also holds `-->` (an unclosed one is skipped whole), and the walk's copy also drops the tail after an unclosed `<!--`. Comment/doc only; the walk remains a superset.
- **Claim 16** (`scripts/lib/dev-cycle-read.sh:509-512`): `test/agents-gemini-sync.bats` holds a start-only import finder written for 2.1.284, not a copy of the regex, and the HTML-comment rule comes from the U2a3b security review, not only U2a2's. Comment/doc only.
- **Claim 36** (`docs/working/known-issues-dev-cycle.md:18`): the same "pins another copy of the regex" looseness in A5. Doc only.

### Unverifiable
- None.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved at the output path named in your role section below, structured per your skill, with a `Commit: e48cf0f7` line at the top.
- Answered: yes. All ten brief items were checked, most by execution (CC 2.1.292 harness and binary grep, failure shims, four mutants, the five suites, shellcheck, rebase replay).
- Out of scope: main_imports' own code beyond its one new lower guard (merged with U2a3); docs/reviews/ files; the first three commit messages (Accepted-immutable rows).
- Escalate: (security-reviewer, advisory) with a failing `tr`, `dev-cycle.sh --check-fix` exits 1 with no output before check_fix's walk branch. It fails closed but has no wording (Claim 24 scope). A host fault, low.
- Decisions I made: Read "each path once" (Claim 9) as per token, which the sentence's subject supports, and recorded the cross-token duplicates in Scope rather than verdicting Mostly accurate. Treated the "(U2a3)" unit tags on two new test names as labels, noted in Claims 29-30, not verdicted. Kept execution logs in my scratch dir `/tmp/u2a3b-fcf3-SR9y/logs/` because the brief allows no other worktree file.
