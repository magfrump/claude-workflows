# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2a3b (branch feat/build-loop-u2a3b)
**Commit:** e48cf0f7
**Scope:** `git diff main...HEAD -- scripts test docs/working` (comments, test names and test comments, known issue A5, plan row F11) and commit e48cf0f7's message; final confirming pass, replicate 1 of 3
**Checked:** 2026-10-07 (UTC)
**Total claims checked:** 36
**Summary:** 32 verified, 4 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Method. I read the enclosing units in full: `scripts/lib/dev-cycle-read.sh:440-681` (UNI_SPACES, IMPORT_RE, lower, import_targets, instruction_names, untracked_md, nul_list, tree_starts, imported_names, main_imports, isimported), need_root/blocker/inrepo_here (`:95-128`), and `check_fix` with its dispatch loop (`scripts/dev-cycle.sh:170-206`). I executed probes in a `git archive` copy at `/tmp/u2a3b-fcf1-kK2Z`, every one under `timeout`. The reference for Claude Code 2.1.292 was the U2a2 final security review's differential harness (`/tmp/u2a2f-sec-nefJ/cc.js`, the extracted marked lexer plus transcribed `reo`), which I ran read-only. No background processes were started. Execution logs (captured output) are in `/tmp/u2a3b-fcf1-kK2Z/logs/`. Under the brief's isolation rule, no file was written in the worktree except this report. The hallucination pattern log (`docs/reviews/hallucination-patterns.md`) was read. Its commit-message test-count entries (lines 28 and 30) are the nearest pattern, and the 119 count was executed below. No new pattern was found.

Every claim carries a **Legibility-target** naming the artifact the claim lives in, so its reader can be identified: `code comment`, `test name/comment`, `working doc`, or `commit message`.

---

## Claim 1: "a name holding a backslash-escaped space (`@my\ notes.md`, which Claude Code reads as `my notes.md`; both walks end the token at the backslash)"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Legibility-target:** working doc
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parser's output and Claude Code 2.1.292's (harness) output for `@my\ notes.md`, and that both walks call the same parser. It does not establish Claude Code versions other than 2.1.292.

Claude Code's token regex is `/(?:^|\s)@((?:[^\s\\]|\\ )+)/g`, followed by `H.replaceAll("\\ "," ")` (quoted from `/tmp/u2a2f-sec-nefJ/cc.js:3`). The harness printed `my notes.md`. The parser's regex stops at any backslash: `IMPORT_RE='(^|[^[:alnum:]])@[^[:space:]\\#]+'` (`scripts/lib/dev-cycle-read.sh:489`). `import_targets` printed `my` for the same line. Both walks use that parser: `out="$(import_targets "$d" < "$f")"` (`:581`, tree) and `git cat-file blob "$MAIN_SHA:$f" | import_targets "$d"` (`:634`, main).

Command: `printf '@my\\ notes.md\n' | ./it.sh` and `node /tmp/u2a2f-sec-nefJ/cc.js c.md ""`, cwd `/tmp/u2a3b-fcf1-kK2Z`, exit 0, 2026-10-07T05:07Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:489`, `:581`, `:634`; `/tmp/u2a3b-fcf1-kK2Z/logs/probe-parser.txt`

---

## Claim 2: "Both walks share one token parser (`import_targets`) that follows Claude Code 2.1.292's import regex and Markdown lexer (U2a2 and U2a3b security reviews ...); revisit trigger: a Claude Code upgrade that changes either, which can make the walks miss imports."

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Legibility-target:** working doc
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the shared parser and the existence of both cited reviews with their 2.1.292 basis. It does not establish that the parser matches 2.1.292 on every input; Claims 9-13 check the shapes this branch names. The "pins another copy" clause in the same sentence is Claim 15.

Both walks call `import_targets` (`:581` and `:634`, quoted in Claim 1). The U2a2 final security review says: "I used Claude Code 2.1.292's real loader ... Function `reo` ... lexes the file with the bundled marked" (`docs/reviews/security-reviewer-review-2026-10-06-final-build-loop-u2a2.md:11`). The U2a3b review says: "the marked lexer extracted from Claude Code 2.1.292, with `reo` transcribed around it" (`docs/reviews/security-reviewer-review-2026-10-06-build-loop-u2a3b.md:11`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:581`, `:634`; `docs/reviews/security-reviewer-review-2026-10-06-final-build-loop-u2a2.md:11`; `docs/reviews/security-reviewer-review-2026-10-06-build-loop-u2a3b.md:11`

---

## Claim 3: F11 "a backslash-escaped space in a name ... The shared token parser follows Claude Code 2.1.292's grammar (U2a3b); a Claude Code upgrade that changes its import regex or Markdown lexer reopens this row."

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Legibility-target:** working doc
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the agreement between F11 and A5 and the shared parser. It does not establish the plan's other gap entries, which were unchanged by this branch.

The gap matches A5's new entry (Claim 1). The parser is shared (Claim 2). The sentence about reopening the row on an upgrade is a policy statement that agrees with A5's revisit trigger.

**Evidence:** `docs/working/plan-build-loop-handoff.md:126`; `docs/working/known-issues-dev-cycle.md:18`

---

## Claim 4: check_fix "skip $a: the instruction-file import walk failed, so an import of it cannot be ruled out; file it instead" (reached for every walk failure kind, in the caller's shell)

**Location:** `scripts/dev-cycle.sh:181-182`
**Legibility-target:** code comment (user-facing message)
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these walk failures under `--check-fix`: a failing git ls-files, a failing untracked_md, instruction_names' grep exiting 2, an unreadable start file, sed or the parser's grep failing, and a newline start name. It also covers the cache being shared with the following `isimported`. It does not cover a failing `tr`: check_fix never reaches the walk then, because the script exits 1 earlier with no output. That is fail-closed, but the message is not printed.

The branch is `elif ! imported_names; then echo "skip $a: the instruction-file import walk failed, ..."` followed by `elif isimported tree "$lp"; then` (`scripts/dev-cycle.sh:181-183`). check_fix is called directly from the dispatch loop: `--check-fix) check_fix "$a" ;;` (`:202`), not inside `$(...)`, so `IMPORTED_DONE` persists. Each of the seven failure kinds printed the skip line. A two-argument run printed it for both paths. The `tr` shim produced rc=1 with no output.

Command: `/tmp/u2a3b-fcf1-kK2Z/probe-cf.sh`, cwd `/tmp/u2a3b-fcf1-kK2Z/c-*`, exit 0, 2026-10-07T05:03:42Z.

**Evidence:** `scripts/dev-cycle.sh:170-206`; `/tmp/u2a3b-fcf1-kK2Z/logs/probe-cf.txt`

---

## Claim 5: "imported_names and main_imports return 1 when the walk fails: call them under if or ||."

**Location:** `scripts/lib/dev-cycle-read.sh:18-19`
**Legibility-target:** code comment
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the return status of both walks on failure and that the production callers comply. It does not establish that test callers comply: `dev-cycle.bats:1176` calls `imported_names` bare under `set -e`, on a success path.

imported_names returns 1 on every failure path (`:568`, `:571`, `:572`, `:581`, `:584`), and main_imports does too (for example `main_by_name || return 1`, `:607`). The production callers are `elif ! imported_names` (`scripts/dev-cycle.sh:181`), `imported_names || return 0` and `main_imports || return 0` (`:677-678`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:563-588`, `:601-666`, `:677-678`; `/tmp/u2a3b-fcf1-kK2Z/logs/probe-walk.txt`

---

## Claim 6: imported_names "returns 1, with IMPORTED set to "error", when the start listing (git ls-files, untracked_md, instruction_names), lower, a file read or the parser fails, or a start file's name holds a newline ...; an inrepo_here that fails skips its path. ... a cached error returns 1 again."

**Location:** `scripts/lib/dev-cycle-read.sh:451-456`
**Legibility-target:** code comment
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named failure kind, executed: an ls-files shim, an ls-files `--others` shim, a grep `-z` shim exiting 2, chmod 000 on a start file and on an imported file, a sed shim, a grep `-aoE` shim, a newline start name, a symlinked start being skipped, and a cached error after the failure is removed. It does not establish lower failing alone in the import loop (`:584`), which was read but not isolated, because tr also fails the start loop first.

`IMPORTED_DONE="$ROOT_REAL"; IMPORTED=error` is set before any check (`:567`). The early returns (`:568`, `:571`, `:572`) leave it at `error`, and the later ones set it: `out="$(import_targets "$d" < "$f")" || { IMPORTED=error; return 1; }` (`:581`). The cache line is `[[ "$IMPORTED_DONE" == "$ROOT_REAL" ]] && { [[ "$IMPORTED" != error ]]; return; }` (`:566`). Every probe printed `walk failed IMPORTED=error`, `2nd failed` and `zz: imported`. The symlinked start was skipped and the walk printed `walk ok`. A cache probe failed under a tr shim, restored PATH, and still printed `2nd failed (cached)`. After `IMPORTED_DONE=""` it printed `3rd ok after reset`.

Command: `/tmp/u2a3b-fcf1-kK2Z/probe-walk.sh` (exit 0, 2026-10-07T05:03:25Z); cache probe in `/tmp/u2a3b-fcf1-kK2Z/w-base` (exit 0, 2026-10-07T05:06Z).

**Evidence:** `scripts/lib/dev-cycle-read.sh:563-588`; `/tmp/u2a3b-fcf1-kK2Z/logs/probe-walk.txt`, `/tmp/u2a3b-fcf1-kK2Z/logs/probe-cache.txt`

---

## Claim 7: `IMPORTED=error` initially (no reader reads IMPORTED before imported_names runs; nothing treats "error" differently)

**Location:** `scripts/lib/dev-cycle-read.sh:481`
**Legibility-target:** code comment (initial value; commit claim "like IMPORTED_MAIN")
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every reader in scripts/ and test/. It does not establish external consumers outside this repo, and none is known.

`rg '\bIMPORTED\b'` outside docs finds these readers only: imported_names itself (`:566-584`), `isimported` after `imported_names || return 0` (`:678`), `dev-cycle.bats:1176-1177` after a call, and the sourcing test's `declare -p` (`dev-cycle.bats:1100`), which only checks that the variable is set. `scripts/build-loop.sh` does not reference it (paraphrased — no quote available because the claim covers absence of code: no matching grep results).

**Evidence:** `scripts/lib/dev-cycle-read.sh:481`, `:566`, `:678`; `test/scripts/dev-cycle.bats:1096-1100`, `:1176-1177`

---

## Claim 8: UNI_SPACES "end an import token as a blank does (import_targets makes each one a blank before it matches tokens): U+00A0, U+1680, U+2000-200A, U+2028/2029, U+202F, U+205F, U+3000 and U+FEFF (Claude Code's token ends at JavaScript's \s, which includes U+FEFF)"

**Location:** `scripts/lib/dev-cycle-read.sh:482-485`
**Legibility-target:** code comment
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 19 byte sequences, the sed rewrite and the test that exercises all of them on both walks. It does not establish JavaScript `\s` beyond the Unicode Zs set plus FEFF, 2028 and 2029, which is the ECMAScript definition.

`for u in "${UNI_SPACES[@]}"; do s+=(-e "s/$u/ /g"); done` and `toks="$(env LC_ALL=C sed "${s[@]}")"` (`:516-518`). The array holds 19 entries (7+7+5, `:486-488`). The test at `test/scripts/build-loop-check.bats:53-70` passes in the 119-test run.

**Evidence:** `scripts/lib/dev-cycle-read.sh:486-488`, `:514-518`; `/tmp/u2a3b-fcf1-kK2Z/logs/bats.txt`

---

## Claim 9: "A token may follow any byte but a letter or digit (so user@host is not one); it ends at a blank, a UNI_SPACES space included, or at a backslash, as the import token of Claude Code does, and at #, where Claude Code cuts the name it captured (so a token after a # is an over-read; ...)"

**Location:** `scripts/lib/dev-cycle-read.sh:493-498`
**Legibility-target:** code comment
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the token start and end bytes against the parser and the CC harness. It does not establish the backslash-escaped-space case beyond what the comment itself defers to A5.

`IMPORT_RE='(^|[^[:alnum:]])@[^[:space:]\\#]+'` (`:489`). Executed results: `u@host.md a@b.md` gave no output; `@a.md\ b.md` gave `a.md`; `@a.md#frag` gave `a.md`; `x#@b.md` gave `b.md`, which the CC harness does not yield (an over-read, as stated). CC's `let G=H.indexOf("#");if(G!==-1)H=H.substring(0,G)` (`/tmp/u2a2f-sec-nefJ/cc.js:3`) is the cut after capture.

**Evidence:** `scripts/lib/dev-cycle-read.sh:489`, `:529`; `/tmp/u2a3b-fcf1-kK2Z/logs/probe-parser.txt`

---

## Claim 10: "each token yields its whole and its part before each of [ ] ( ) < ! * _ and backtick, each also with trailing . , ; : ! ? * _ ~ ) ] or backticks stripped, each path once" (and the cut loop `[[ "$r" == *$cut* ]] || break; r="${r%$cut*}"` with `cut="[][()<!*_$b]"`)

**Location:** `scripts/lib/dev-cycle-read.sh:498-504`, `:515`, `:533-546`
**Legibility-target:** code comment
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every cut mark (backtick included) in both unquoted pattern uses, termination, the prefix set, and the strip set. "Each path once" is per token. It does not establish de-duplication across tokens: `@a.md @a.md` prints `a.md` twice, because `n=$'\n'` is reset per token at `:532`. The tree walk's `seen` (`:585`) and the main walk's `seen[$p]` (`:658`) make duplicates harmless.

The loop is:
```
      [[ "$r" == *$cut* ]] || break
      # shellcheck disable=SC2295  # $cut is the glob bracket, matched as a pattern
      r="${r%$cut*}"
```
(`:543-545`). It sits inside `while :; do` (`:534`), which closes at `:546`. The enclosing `while IFS= read -r t` closes at `:547` (read). `@a[b]c(d)e<f!g*h_i`j.md` yielded 10 names, one per mark: `a[b]c(d)e<f!g*h_i`j.md`, `...h_i`, `...g*h`, `...f!g`, `...e<f`, `...d)e`, `a[b]c(d`, `a[b]c`, `a[b`, `a`. `@a`b`c.md` yielded `a`b`c.md`, `a`b`, `a`. `${r%$cut*}` removes at least one byte each pass, so the loop ends. `@[[[` ended after 3 names. `@x.md`,)` yielded `x.md`,)`, `x.md` and `x.md`,`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:513-548`; `/tmp/u2a3b-fcf1-kK2Z/logs/probe-parser.txt`

---

## Claim 11: "Claude Code deletes the HTML comments of a block that opens with <!-- and reads what is left, so text holding <!-- is also read once more with every closed comment removed."

**Location:** `scripts/lib/dev-cycle-read.sh:504-506` (code `:519-526`)
**Legibility-target:** code comment
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the re-read copy for one comment, several comments, a comment spanning lines, and an unclosed `<!--`, and covers the claim that the re-read cannot suppress a name. It does not establish behavior for names that themselves contain `<!--`.

The re-read loop is:
```
    while [[ "$x" == *'<!--'* ]]; do
      y+="${x%%'<!--'*}"; x="${x#*'<!--'}"
      if [[ "$x" == *'-->'* ]]; then x="${x#*'-->'}"; else x=""; fi
    done
    toks+=$'\n'"$y$x"
```
(`:521-525`). It removes every closed comment, and also every byte after an unclosed `<!--` (`x=""`), not only closed comments. Claude Code applies the splice only when the block also contains `-->`: `if(H.startsWith("<!--")&&H.includes("-->")){let z=w.replace(/<!--[\s\S]*?-->/g,"")` (`cc.js:3`). An unclosed tail stays in CC's text. Executed: `@a<!-- x -->b<!-- y -->c.md` yields `abc.md`, and the version spanning lines yields `ab.md`. In `<!-- c --> see @docs/q.md <!-- z @docs/t.md`, CC reads `docs/t.md` from the unclosed tail. The re-read copy drops it, but the first copy still yields it, because the re-read is appended (`toks+=`), never substituted. So "over-reading only over-refuses" holds. The precise version: "read once more with every closed comment, and any unclosed comment's tail, removed". The only divergence found is a name that holds `<!--` itself (CC `docs/xy.md<!--zz`; parser `docs/xy.md`). Comment/doc only.

**Evidence:** `scripts/lib/dev-cycle-read.sh:519-526`; `/tmp/u2a3b-fcf1-kK2Z/logs/probe-parser.txt`

---

## Claim 12: "A NUL counts as a blank. Over-reading only over-refuses."

**Location:** `scripts/lib/dev-cycle-read.sh:506-507`
**Legibility-target:** code comment
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the NUL rewrite and the additive structure of every over-read (stripped forms, cut prefixes, the comment re-read, tokens after `#`). It does not establish over-refusal costs, which are settled override rows.

`s=(-e 's/\x0/ /g')` (`:514`). `@a.md\0@b.md` yields `a.md` and `b.md`. Every extra name is printed in addition to the whole token (`for w in "$r" "$v"`, `:536`), and the comment copy is appended (`:525`), so no extra name can remove one. In the main walk an extra name can only add a queue entry or fail the walk (`:660-663`), and both refuse more.

**Evidence:** `scripts/lib/dev-cycle-read.sh:514`, `:525`, `:536-541`, `:655-664`; `/tmp/u2a3b-fcf1-kK2Z/logs/probe-parser.txt`

---

## Claim 13: "~/ and absolute paths, and paths leaving the repo (.. or ../, not a ..x name), are dropped."

**Location:** `scripts/lib/dev-cycle-read.sh:507-508`
**Legibility-target:** code comment
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `~/`, `/`, `../`, `a/../../`, `..`, `~x` and `..x`. It does not establish symlink-relative resolution, a settled A5 item.

The filters are `[[ -n "$w" && "$w" != \~/* && "$w" != /* ...` (`:537`) and `[[ "$p" != .. && "$p" != ../* ...` (`:540`). `@~/x.md @~x.md @/abs.md @../up.md @..x.md @a/../../b.md @..` yields only `~x.md` and `..x.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:537-540`; `/tmp/u2a3b-fcf1-kK2Z/logs/probe-parser.txt`

---

## Claim 14: "It reads ROOT_REAL without checking it (the caller has run need_root) and returns 1 when sed or grep fails."

**Location:** `scripts/lib/dev-cycle-read.sh:508-509`
**Legibility-target:** code comment
**Type:** Error-handling / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both production callers and a failing sed, grep and input read. It does not establish realpath failures, which skip a name (`:539`) and are not a return of 1, as the comment does not claim.

`toks="$(env LC_ALL=C sed "${s[@]}")" || return 1` (`:518`); `... | env LC_ALL=C grep -aoE "$IMPORT_RE")" || [[ $? -eq 1 ]] || return 1` (`:529`). The callers run need_root first (`:565`, `:604`). The sed shim (exit 4) and the grep `-aoE` shim (exit 2) each made the walk fail. `import_targets "" < docs` (a directory) prints `failed` in the suite.

**Evidence:** `scripts/lib/dev-cycle-read.sh:518`, `:529`, `:565`, `:604`; `/tmp/u2a3b-fcf1-kK2Z/logs/probe-walk.txt`

---

## Claim 15: "test/agents-gemini-sync.bats pins another copy of the regex" (also A5: "`test/agents-gemini-sync.bats` pins another copy of the regex")

**Location:** `scripts/lib/dev-cycle-read.sh:512`; `docs/working/known-issues-dev-cycle.md:18`
**Legibility-target:** code comment; working doc
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the cited test file holds. It does not establish whether the two encodings should be merged; the architecture review advised against merging them.

The file holds a different, prefix-only finder regex: `grep -nE '(^|[^[:alnum:]])@(\./|~/|/|[[:alnum:]._-])'` (`test/agents-gemini-sync.bats:51`). Its comment documents it against "Claude Code v2.1.284" (`:37`). It shares IMPORT_RE's start condition `(^|[^[:alnum:]])@` but has no token body or end rules, and it is neither IMPORT_RE nor CC 2.1.292's `/(?:^|\s)@((?:[^\s\\]|\\ )+)/g`. The pointer's purpose holds: it names a second place to re-check on a Claude Code grammar change. The precise version: "test/agents-gemini-sync.bats holds a second, over-approximating encoding of Claude Code's import start rule (v2.1.284)". Comment/doc only.

**Evidence:** `test/agents-gemini-sync.bats:37-52`; `docs/reviews/architecture-review-review-2026-10-06-build-loop-u2a3b.md:48`

---

## Claim 16: "Two steps, not a pipe: under pipefail grep's "no match" would hide a sed failure."

**Location:** `scripts/lib/dev-cycle-read.sh:517`
**Legibility-target:** code comment
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash's pipefail status rule as used with `|| [[ $? -eq 1 ]]`. It does not establish other shells.

Under pipefail the pipeline status is the rightmost non-zero one: `set -o pipefail; (exit 4) | (exit 1); echo $?` prints `1`. A `sed | grep` pipe followed by `|| [[ $? -eq 1 ]]` (`:529`'s form) would therefore accept a sed failure.

Command: `bash -c 'set -o pipefail; (exit 4) | (exit 1); echo $?'`, cwd `/tmp/u2a3b-fcf1-kK2Z`, exit 0, 2026-10-07T05:08:05Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:517-529`; `/tmp/u2a3b-fcf1-kK2Z/logs/probe-herestring.txt`

---

## Claim 17: "A pipe, not a here-string: bash writes a long here-string to a temp file, and a failed write would read as "no match"."

**Location:** `scripts/lib/dev-cycle-read.sh:527-528`
**Legibility-target:** code comment
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15 with a write that fails with an error (EFBIG with SIGXFSZ ignored). It does not cover a default-disposition `ulimit -f` breach: there SIGXFSZ kills the shell (rc 153) rather than producing "no match", which is still fail-closed.

With 66000 bytes or more, `trap '' XFSZ; ulimit -f 0` and `grep -aoE "$IMPORT_RE" <<<"$toks"` print `cannot create temp file for here-document: File too large` and `rc=1 []`. At 60000 and 65000 bytes the here-string goes through a pipe and finds the import. The pipe form returns `docs/big.md`, rc 0, under `ulimit -f 0`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:527-529`; `/tmp/u2a3b-fcf1-kK2Z/logs/probe-herestring.txt`

---

## Claim 18: instruction_names "returns 0 when no name matches and 1 when grep fails (grep's own no-match is 1)"

**Location:** `scripts/lib/dev-cycle-read.sh:552-554`
**Legibility-target:** code comment
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exit 1 (no match) mapped to 0 and exit 2 mapped to 1, and NUL-terminated output for `nul_list`. It does not establish grep exits above 2, which map to 1 the same way.

The function is `env LC_ALL=C grep -zaiE '...' || [[ $? -eq 1 ]]` (`:554`). A grep `-z` shim exiting 2 made the walk fail (probe and suite). The baseline repos with no other instruction file still walk `ok`. `grep -z` ends each output record with a NUL, so nul_list's "empty or ended in NUL" rule holds.

**Evidence:** `scripts/lib/dev-cycle-read.sh:554`, `:559`; `/tmp/u2a3b-fcf1-kK2Z/logs/probe-walk.txt`

---

## Claim 19: tree_starts "tracked and untracked names through instruction_names, failing when any of the three commands fails"

**Location:** `scripts/lib/dev-cycle-read.sh:560-562`
**Legibility-target:** code comment
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each of the three failing alone. It does not establish that pipefail leaks to the caller: `local -` restores it, and nul_list runs it in a process substitution.

The function is `tree_starts() { local -; set -o pipefail; { git ls-files -z && untracked_md; } | instruction_names; }` (`:562`). A git ls-files shim, a git `--others` shim and a grep `-z` exit-2 shim each gave `walk failed IMPORTED=error`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:559-568`; `/tmp/u2a3b-fcf1-kK2Z/logs/probe-walk.txt`

---

## Claim 20: "seen is newline-separated: a name holding a newline could hide another start."

**Location:** `scripts/lib/dev-cycle-read.sh:570`
**Legibility-target:** code comment
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the guard at `:571` and the suite case `a\nb/CLAUDE.md` with `b/CLAUDE.md`. It does not establish newlines in imported (non-start) names, which `lower` and `seen` treat line-wise; the parser's grep emits no newline inside a token.

The guard is `[[ "$f" != *$'\n'* ]] || return 1` (`:571`). The suite test (`build-loop-check.bats:368-370`) and the probe `newline start name` both fail the walk.

**Evidence:** `scripts/lib/dev-cycle-read.sh:569-576`; `/tmp/u2a3b-fcf1-kK2Z/logs/probe-walk.txt`

---

## Claim 21: isimported "A failed walk, a failed lower of $2, or a walk name that is neither answers imported (0) ...; a caller that words a failed walk runs the walk first (imported_names or main_imports, under if)."

**Location:** `scripts/lib/dev-cycle-read.sh:667-671`
**Legibility-target:** code comment
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all three branches and check_fix as the wording caller. It does not establish a main-walk wording caller, which does not exist yet (U2a4).

The function body is `lp="$(lower "$2")" || return 0` with `main) main_imports || return 0; ...`, `tree) imported_names || return 0; ...` and `*) return 0 ;;` (`:675-679`). The tr-shim test prints `docs/z.md imported` for both walks, and the bogus-name test prints `bogus: imported`. check_fix calls `imported_names` before `isimported` (`scripts/dev-cycle.sh:181-183`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:672-681`; `scripts/dev-cycle.sh:181-183`; `/tmp/u2a3b-fcf1-kK2Z/logs/bats.txt`

---

## Claim 22: imps "walk: ok" or "walk: failed" "(main_imports' or imported_names' return)"

**Location:** `test/scripts/build-loop-check.bats:14`
**Legibility-target:** test name/comment
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the helper's walk line. It does not establish anything for other walk names, which print `walk: failed`.

The helper line is `if { [[ "$w" == main ]] && main_imports; } || { [[ "$w" == tree ]] && imported_names; }; then echo "walk: ok"; else echo "walk: failed"; fi` (`:20`).

**Evidence:** `test/scripts/build-loop-check.bats:13-22`

---

## Claim 23: tree-walk test comments "Two NBSPs in one run: the token ends at the first. docs/z.md is imported only after the NUL; gone/ does not exist, and the path is still resolved as written." / "Docs/NB.MD and CLAUDE.md: isimported takes a path in any case."

**Location:** `test/scripts/build-loop-check.bats:28-36`
**Legibility-target:** test name/comment
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fixture lines and the asserted names (the suite passes). It does not establish that `docs/nb.md.` asserts `-`, which is read from the call (`imps tree "${ps[@]}" docs/other.md docs/nb.md.`) and not from this comment.

The fixture is `printf 'See @docs/nb.md\xc2\xa0for\xc2\xa0you, ... @gone/../docs/m.md and @docs/a.md\0 then @docs/z.md\n'` (`:30`). `docs/m.md` comes from lexical `realpath -ms` (`:539`), and the any-case lookup comes from `lower "$2"` (`lib :675`).

**Evidence:** `test/scripts/build-loop-check.bats:26-41`; `/tmp/u2a3b-fcf1-kK2Z/logs/bats.txt`

---

## Claim 24: "Without ROOT_REAL it stops (need_root) for any walk name, before answering."

**Location:** `test/scripts/build-loop-check.bats:47`
**Legibility-target:** test name/comment
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers isimported with the bogus name (need_root is its first statement). It does not establish other entry points.

isimported starts with `local lp` and then `need_root` (`lib :673-674`). The test asserts status 1, empty output and `ROOT_REAL is not set` (`:50`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:672-675`; `test/scripts/build-loop-check.bats:47-50`

---

## Claim 25: test "both walks: every Unicode space JavaScript's \s holds ends a token; SKILL.md starts them; an untracked upper-case .MD starts the tree walk (U2a3b)"

**Location:** `test/scripts/build-loop-check.bats:53-70`
**Legibility-target:** test name/comment
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each clause. It does not establish that the main walk accepts an untracked start (by design it fails closed until U2a3c, as the comment at `:65` says).

`sub/SKILL.md` is the only instruction file in the fixture (`bl_setup` and `commit_all` add none: `commit_all() { git add -A && git commit -q --allow-empty -m "${1:-fixture}"; }`, `test/lib/build-loop-fixtures.bash:28`). Each `docs/uN.md` is imported on main and tree only if the space ended the token; otherwise the yielded name would carry the space bytes. `docs/k.md` is reachable only from the untracked `docs/AGENTS.MD` (`:66`).

**Evidence:** `test/scripts/build-loop-check.bats:53-70`; `/tmp/u2a3b-fcf1-kK2Z/logs/bats.txt`

---

## Claim 26: test "both walks read what Claude Code reads: an @ after a Unicode space, Markdown and a code span around a token, ( ) in a name; ~x is over-read, ~/ dropped" and its comments (a cut mark earlier in the name does not hide a later one; two NBSPs on a line both become blanks; an HTML block's comment splices a name)

**Location:** `test/scripts/build-loop-check.bats:339-355`
**Legibility-target:** test name/comment
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed case on both walks (the suite passes) and that the cases discriminate. A cut only at the first mark yields `docs/my` rather than `docs/my_notes.md`, and a bare token without the comment splice misses `docs/secret.md`. It does not establish CC parity for shapes outside this corpus.

The cases are `@docs/my_notes.md\x60c\x60`, `@docs/p.md\xc2\xa0@docs/q.md\xc2\xa0@docs/r.md` and `<!-- note --> See @docs/sec<!-- x -->ret.md` (`:344-345`). `'~/x.md'` asserts `-` (`:353`). If `~/` were not dropped, the literal path `~/x.md` would be recorded and matched.

**Evidence:** `test/scripts/build-loop-check.bats:339-355`; `/tmp/u2a3b-fcf1-kK2Z/logs/probe-parser.txt`

---

## Claim 27: the "(U2a3)" unit tags on the two tests this branch adds

**Location:** `test/scripts/build-loop-check.bats:339`, `:357`
**Legibility-target:** test name/comment
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers which unit added the tests. It does not establish whether the tag is meant as the U2a3 family name.

Both tests are absent from main's file (`git show main:test/scripts/build-loop-check.bats` lists neither name). `git log -S'both walks read what Claude Code reads'` gives `43b9edb6 fix(dev-cycle-read): ... (U2a3b)`. The sibling test added by the same branch is tagged `(U2a3b)` (`:53`). The precise tag is "(U2a3b)". Comment/doc only, Low.

**Evidence:** `test/scripts/build-loop-check.bats:53`, `:339`, `:357`

---

## Claim 28: test "both walks fail closed when tr fails; the tree walk fails closed when its start listing fails or a start name holds a newline; the parser returns 1 when it cannot read its input", with comments "A grep that fails on the start listing (instruction_names, grep -z) only", "An untracked start under a directory whose name holds a newline: b/X.md would read as seen", "A corrupt index: git ls-files fails, so the tree walk has no start list"

**Location:** `test/scripts/build-loop-check.bats:357-393`
**Legibility-target:** test name/comment
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each clause and its discrimination. The nul_list-ignoring mutant fails this test (Claim 33), and the newline case would print `-` without the `:571` guard, because `a\nb/CLAUDE.md` sorts first and puts `\nb/CLAUDE.md\n` into `seen`. It does not establish the cache claim at `:372` (Claim 29).

The grep shim matches only `-z*` as `$1` (`:364`). Only instruction_names calls `grep -zaiE` in the tree walk, and the parser calls `grep -aoE`. `import_targets "" < docs` reads a directory, sed fails, and the test prints `failed`. The corrupt-index case prints `walk failed` and `docs/z.md: imported` (`:386-392`).

**Evidence:** `test/scripts/build-loop-check.bats:357-393`; `/tmp/u2a3b-fcf1-kK2Z/logs/bats.txt`, `/tmp/u2a3b-fcf1-kK2Z/logs/mutant-nul_list.txt`

---

## Claim 29: "The tree walk itself, called twice: the second call returns its cached error."

**Location:** `test/scripts/build-loop-check.bats:372-378`
**Legibility-target:** test name/comment
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the code behavior, which I executed separately. It does not establish that this test proves it.

The code returns a cached error: `[[ "$IMPORTED_DONE" == "$ROOT_REAL" ]] && { [[ "$IMPORTED" != error ]]; return; }` (`lib :566`). My probe failed the first call under a tr shim, restored PATH, and the second call still failed; after `IMPORTED_DONE=""` the walk succeeded. In the test, though, both calls run under the same failing tr (`env PATH="$BATS_TEST_TMPDIR/bin:$PATH"`, `:373`), so a recomputing walk prints the same `walk failed` twice. The comment is true of the code, but the assertion does not distinguish caching. The precise version: "called twice under a failing tr: both calls fail (the second from the cache)". The `dev-cycle.bats` cache test (`:1168-1180`) covers recomputation only for another root. Test/comment only.

**Evidence:** `test/scripts/build-loop-check.bats:372-378`; `scripts/lib/dev-cycle-read.sh:566`; `/tmp/u2a3b-fcf1-kK2Z/logs/probe-cache.txt`

---

## Claim 30: "A file past bash's here-string pipe size (64 KiB) with no room for a temp file (ulimit -f 0): the import at its end is still read."

**Location:** `test/scripts/build-loop-check.bats:380-384`
**Legibility-target:** test name/comment
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 64 KiB threshold on bash 5.2.15 and the test's discrimination. Under the here-string mutant, SIGXFSZ kills bash (rc 153) and the test's `status -eq 0` fails. It does not establish other bash builds' pipe size.

Here-strings of 65000 bytes still use the pipe; at 66000 bytes they need a temp file (Claim 17). The fixture is 70000 bytes plus the import line (`:381`).

**Evidence:** `test/scripts/build-loop-check.bats:380-384`; `/tmp/u2a3b-fcf1-kK2Z/logs/probe-herestring.txt`

---

## Claim 31: test "--check-fix words a failed import walk as one and refuses (U2a3b)" with comment "A corrupt index: git ls-files fails, so the walk has no start list."

**Location:** `test/scripts/dev-cycle.bats:1048-1057`
**Legibility-target:** test name/comment
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ls-files failure kind end to end. Claim 4 covers the other kinds. It does not establish exit status, which the test does not assert; the script exits 0 after printing.

The test asserts `[[ "$output" == "skip docs/notes.md: the instruction-file import walk failed"* ]]` (`:1055`). The mutant that ignores nul_list's failure fails this test (`not ok 95`).

**Evidence:** `test/scripts/dev-cycle.bats:1048-1057`; `/tmp/u2a3b-fcf1-kK2Z/logs/mutant-nul_list.txt`

---

## Claim 32: "Rebased onto main f6fdda68 (U2a3 merged at 97aa2d35 after its split; the lib merged without conflicts, the tests and the override log were resolved by keeping both sides)."

**Location:** commit e48cf0f7 message
**Legibility-target:** commit message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a replay, in a scratch clone, of the reflog's pre-rebase commits (`ac1a8b7b` on 45ad17b0) onto 97aa2d35 and then onto f6fdda68. It does not establish how the author resolved the conflicts, beyond the result matching the real rebased commits byte for byte.

The reflog shows `3a805acf ... rebase (finish) ... onto 97aa2d35` and `d894b3f0 ... onto f6fdda68`. The replay onto 97aa2d35 conflicted only in `test/scripts/build-loop-check.bats` (commit 1), and in `docs/reviews/override-log.md` plus that test file (commit 2). `scripts/lib/dev-cycle-read.sh` auto-merged. With the conflicted files taken from the real commits, the result equals `3a805acf` (empty `git diff --stat`). The second rebase onto f6fdda68 had no conflicts and equals `d894b3f0`.

Command: `git rebase 97aa2d35` / `git rebase f6fdda68` in `/tmp/u2a3b-fcf1-kK2Z/cl` (a clone; `GIT_CONFIG_GLOBAL=/dev/null`), 2026-10-07T05:06Z; exit 1 on conflict, then `--continue`.

**Evidence:** `/tmp/u2a3b-fcf1-kK2Z/logs/rebase1.txt`

---

## Claim 33: "a mutant that ignores nul_list's failure fails two tests"

**Location:** commit e48cf0f7 message
**Legibility-target:** commit message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mutant `nul_list recs tree_starts || true` on the five suites. It does not establish other mutant forms.

Result: `not ok 20 both walks fail closed when tr fails; ...` and `not ok 95 --check-fix words a failed import walk as one and refuses (U2a3b)`. Exactly two tests fail.

Command: `TMPDIR=/tmp/u2a3b-fcf1-tmp-LK6i bats <five suites>`, cwd `/tmp/u2a3b-fcf1-mut-XWtv`, exit 1, 2026-10-07T05:05Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:568`; `/tmp/u2a3b-fcf1-kK2Z/logs/mutant-nul_list.txt`

---

## Claim 34: "Tests: 119/119 across the five suites; shellcheck clean"

**Location:** commit e48cf0f7 message
**Legibility-target:** commit message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the five named suites at e48cf0f7 and shellcheck on the two changed scripts. It does not establish the full repository suite.

The run printed `1..119` and 119 `ok` lines, and bats exited 0. `shellcheck scripts/lib/dev-cycle-read.sh scripts/dev-cycle.sh` exited 0 with no output.

Commands: `TMPDIR=/tmp/u2a3b-fcf1-tmp-v2YS bats test/scripts/build-loop-check.bats test/scripts/build-loop-read.bats test/scripts/dev-cycle.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats`, cwd `/tmp/u2a3b-fcf1-kK2Z`, exit 0, 2026-10-07T05:00:48Z; shellcheck, same cwd, exit 0.

**Evidence:** `/tmp/u2a3b-fcf1-kK2Z/logs/bats.txt`, `/tmp/u2a3b-fcf1-kK2Z/logs/shellcheck.txt`

---

## Claim 35: "230 changed code lines against main."

**Location:** commit e48cf0f7 message
**Legibility-target:** commit message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers pr-prep step 1a's count (added plus deleted lines, excluding `docs/`). It does not establish anything else.

`git diff --numstat main...HEAD -- . ':!docs'` prints `2 0` for dev-cycle.sh, `89 38` for the lib, `86 4` for build-loop-check.bats and `11 0` for dev-cycle.bats, a sum of 188 + 42 = 230 (`workflows/pr-prep.md:91` uses the same count).

**Evidence:** `workflows/pr-prep.md:86-92`

---

## Claim 36: the post-rebase bullets: "imported_names reads its start list through U2a3's nul_list helper (tree_starts ...), so the rc=0 listing check is written once (I2-C3)"; "IMPORTED starts as error, like IMPORTED_MAIN"; "Patch A's Unicode-space test runs the untracked .MD start on the tree walk only"; "Override rows close the three rows routed to U2a3 (fixed there in c42f017f), I2-C5 and I2-A6"

**Location:** commit e48cf0f7 message
**Legibility-target:** commit message
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each bullet against the tree and the commit's diff. It does not re-verify the substance of the closed rows beyond c42f017f's subject.

`rg 'rc=0'` in the lib hits only nul_list (`:559`). `IMPORTED=error; ... IMPORTED_MAIN=error` (`:481`). The test runs `imps main` before `docs/AGENTS.MD` exists and `imps tree` after (`build-loop-check.bats:62-69`). c42f017f is on main (`merge-base --is-ancestor`). The commit adds three override rows: the closure of the three U2a3-routed rows, I2-C5 and I2-A6.

**Evidence:** `scripts/lib/dev-cycle-read.sh:481`, `:559`; `test/scripts/build-loop-check.bats:53-70`; `docs/reviews/override-log.md:414-416`

---

## Claims Requiring Attention

### Incorrect
None.

### Stale
None.

### Mostly Accurate
- **Claim 11** (`scripts/lib/dev-cycle-read.sh:504-506`): the re-read removes every closed comment and also everything after an unclosed `<!--`; CC splices only blocks holding `-->`. No name is lost, because the first copy is still read. Comment-only, High.
- **Claim 15** (`scripts/lib/dev-cycle-read.sh:512`, `docs/working/known-issues-dev-cycle.md:18`): test/agents-gemini-sync.bats holds a different, prefix-only finder regex documented at v2.1.284, not a copy of IMPORT_RE or of CC's regex. Comment/doc only, High.
- **Claim 27** (`test/scripts/build-loop-check.bats:339`, `:357`): the two tests added by this branch are tagged "(U2a3)"; the sibling at `:53` and the adding commit say U2a3b. Test name only, Medium.
- **Claim 29** (`test/scripts/build-loop-check.bats:372`): "the second call returns its cached error" is true of the code (executed), but the test runs both calls under the same failing tr, so it cannot tell a cache from a recompute. Test/comment only, High.

### Unverifiable
None.

## Escalate

- **test-strategy:** Claim 29. No test isolates imported_names' cached-error path; a recomputing mutant would pass. A probe that clears the failure between calls (restore PATH) distinguishes the two.
- None for security-reviewer: the Claim 11 divergence is a name holding `<!--` itself, which the parser under-reads (`docs/xy.md` vs CC `docs/xy.md<!--zz`). That is outside any pathform-allowed name; noted for completeness, not filed.

## Goal-Alignment Note

- **Asked:** the Stage-1 code fact-check replicate (k=3, final confirming pass) of `main...HEAD` at e48cf0f7, covering the scripts, tests and A5/F11 prose and the newest commit message, with the ten listed focus items executed where possible.
- **Answered:** all ten focus items, with 36 claims: 32 Verified, 4 Mostly accurate, no Incorrect. Every failure kind named in imported_names' header and tree_starts' comment was executed, as was check_fix's wording for each kind (tr fails earlier, closed, without the wording). The cut loop and HTML re-read were executed against the CC 2.1.292 harness. The rebase, mutant, 119/119 and 230-line claims were reproduced.
- **Not answered / residue:** CC versions other than 2.1.292, and test callers of imported_names outside `if` (dev-cycle.bats:1176, success path only).
- **Fit:** the iteration-2 fixes (I2-A1 to I2-A4, I2-C1) hold and the rebase changes (nul_list adoption, `IMPORTED=error`) introduce no behavior mismatch; the four findings are comment- or test-precision only and none blocks the merge.
