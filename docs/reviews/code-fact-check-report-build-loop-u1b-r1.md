**Commit:** 0ae7d801

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u1b (branch feat/build-loop-u1b)
**Scope:** unit diff feat/build-loop-u1a...feat/build-loop-u1b: scripts/build-loop.sh, test/lib/build-loop-fixtures.bash, test/scripts/build-loop-read.bats, and commit messages 0797ed32, 224dd52d, 30676e57, 0ae7d801 (replicate r1 of 3)
**Checked:** 2026-10-05
**Total claims checked:** 38
**Summary:** 34 verified, 1 mostly accurate, 0 stale, 3 incorrect, 0 unverifiable

Execution provenance (all runs; cwd and logs as listed; scratch dir `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i2/fc-r1/`, abbreviated `$S`):

- E1 suites: `cd /workspace/.claude/wt-build-loop-u1b && export LC_ALL=C.UTF-8 && bats test/scripts/build-loop-read.bats test/scripts/dev-cycle.bats`, exit 0, 2026-10-05T11:09:03Z, 75/75 ok (9 + 66). Log: `$S/bats.log`.
- E2 behaviour probes: throwaway repo `$S/p1/r` (hermetic git env, LC_ALL=C), one commit per case and `bash scripts/build-loop.sh --settings`, all rc 0, about 2026-10-05T11:10Z. Logs: `$S/probe1.log` (never-line and hidden-copy shapes), `$S/probe2.log` (duplicate globs, `printf '%s\n'` with no arguments, read-only check, a preset DEV_CYCLE_SCRUBBED, the -h range).
- E3 mutations, made on copies of scripts/ and test/ under `$S/m1`..`$S/m6` (never in the worktree): `bats -f 'T45'` (or `T4`), 2026-10-05T11:11:24Z and 11:12:25Z, bats 1.8.2. Logs: `$S/mutation.log` (m1 drops `IFS=' '`, m2 drops the tab/VT/FF/CR test, m3 drops both), `$S/mutation-and.log` (m4, m5) and `$S/mutation-m6.log` (m6).

Hallucination-pattern log (docs/reviews/hallucination-patterns.md) checked. Claim 38, an executed result stated in a commit message that does not reproduce, closely resembles the logged "claimed test tally / suite outcome" entries (commit 59ca38f "All 85 tests", commit 37c5ea9 "mode1-equiv 33"). This replicate writes nothing outside its report, so the log was not updated.

---

## Claim 1: "It is set only when exactly one line, outside code fences, starts "Build-loop policy:" and reads exactly "Build-loop policy: self-merge" or "Build-loop policy: review" (one trailing CR is dropped)."

**Location:** `scripts/build-loop.sh:12-15`
**Type:** Behavioral
**Legibility-target:** header contract (the reader of `-h` / the orchestrator skill)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count (exactly one counted line), the exact-text match and the single trailing CR. It does not establish what "starts" means beyond the counting rule (Claim 6), and it relies on FENCE_AWK for "outside code fences".

`SETTINGS_AWK` drops one trailing CR before `fence()` runs (`{ sub(/\r$/, "") }`, `scripts/build-loop.sh:102`), and FENCE_AWK refuses any CR left in the line (`if (index(l, "\r")) { refuse("cr"); return 1 }`, lib `:215`). So one trailing CR is dropped, and a second one refuses the file. The exactness check is `elif [[ "${text[policy]}" =~ ^Build-loop\ policy:\ (self-merge|review)$ ]]` (`scripts/build-loop.sh:174`), and a count above 1 gives `policy review unset: $(many ...)` (`:173`). T1 (the CR case) and T2 (the variants, the duplicates and the prose mentions) pass in E1.

**Evidence:** `scripts/build-loop.sh:102-111`, `scripts/build-loop.sh:172-179`, `scripts/lib/dev-cycle-read.sh:213-229`, `test/scripts/build-loop-read.bats:13-40`, `$S/bats.log`

---

## Claim 2: "Any other case, or a malformed never line, means review."

**Location:** `scripts/build-loop.sh:16`
**Type:** Behavioral / Invariant
**Legibility-target:** header contract
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every branch of read_settings that sets POLICY_LINE: POLICY starts as review and is set to self-merge on only one branch. It does not establish how later modes (--status, the gate in U1c and later) consume POLICY.

`POLICY=review` (`:133`), and the only assignment of another value is `else POLICY="$v"` (`:178`), reached only when `[[ "$v" == self-merge && -z "$never_ok" ]]` (`:176`) is false. The never_ok flag is cleared on a duplicate never line (`:153`) and on a malformed one (`:169`). The file-not-read branch (`:139-143`) never touches POLICY. In E2, `a\vb`, `a\fb`, NBSP, lower-case `self-merge never:`, `a//` and `/` each print `policy review unset: line 1 reads self-merge, but the Self-merge never: line is malformed, so self-merge is off` (`$S/probe1.log`).

**Evidence:** `scripts/build-loop.sh:133-185`, `$S/probe1.log`, `test/scripts/build-loop-read.bats:107-113`

---

## Claim 3: "How many build loops may run at once: one line "Build-loop slots: N" with N from 1 to 9, else 3."

**Location:** `scripts/build-loop.sh:17-19`
**Type:** Behavioral / Configuration
**Legibility-target:** header contract
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regex, the duplicate rule and the default of 3. It does not establish how many loops any caller actually runs (no consumer exists in U1b).

`elif [[ "${text[slots]}" =~ ^Build-loop\ slots:\ ([123456789])$ ]]` (`:182`), and every other branch prints `slots 3 default` (`:180-183`). The slots test (0, 10, a trailing space, 05, three, a duplicate, fenced) passes in E1.

**Evidence:** `scripts/build-loop.sh:180-183`, `test/scripts/build-loop-read.bats:87-98`, `$S/bats.log`

---

## Claim 4: "Self-merge never: GLOB ..." (single spaces, no tab; each glob uses letters, digits, . _ - / * ?, with an optional trailing /; no empty, . or .. part, not starting / or -; none twice, a trailing / ignored)."

**Location:** `scripts/build-loop.sh:20-25`
**Type:** Behavioral
**Legibility-target:** header contract
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed grammar rule as implemented at `:155-167` and in globform. It does not establish that the header is complete: the code is also stricter than stated (VT, FF and CR are refused as well as tab, and the prefix must be exactly `Self-merge never: ` in that case even though counting is case-blind). A part `.git` is accepted (Claim 16).

The code checks `[[ "$t" != "Self-merge never: "* || "$v" == *[$'\t\v\f\r']* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]` (`:157`), splits with `IFS=' ' read -ra parts` (`:161`), calls `globform "${g%/}"` (`:164`) and checks `seen[${g%/}]` (`:165-166`). globform's character class is `^[*?$NAMECHARS]+$` (`:124`), where NAMECHARS is `abc…XYZ0123456789._/-` (lib `:139`). E2 results: `a/ b/*`, `x a*`, `*`, `* a` and `a *` are set; `a* a*`, `a? a?/` and `* *` print "lists entry 2 twice"; `a//` and `/` print "not an allowed glob form" (`$S/probe1.log`, `$S/probe2.log`). An earlier worry, that an entry `*` would collide with the associative array's `[*]` all-elements subscript, is refuted: `a *` and `* a` are both set, and only `* *` is a duplicate.

**Evidence:** `scripts/build-loop.sh:118-129`, `scripts/build-loop.sh:155-170`, `scripts/lib/dev-cycle-read.sh:139`, `$S/probe1.log`, `$S/probe2.log`

---

## Claim 5: "A malformed line, or a settings file that is not read, turns self-merge off."

**Location:** `scripts/build-loop.sh:26-27`
**Type:** Behavioral / Invariant
**Legibility-target:** header contract
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both triggers on --settings' POLICY and POLICY_LINE. It does not establish the effect in later modes that read NEVER or POLICY.

On the not-read branch (`if ! main_file "$f" "$SETTINGS_AWK"; then`, `:139`), POLICY keeps its initial `review` and the branch prints `policy review unset: $why` (`:141`). A malformed line clears never_ok (`:169`), which blocks self-merge (`:176-177`). T3 asserts that an open-comment file gives both `policy review unset: …` and `never malformed: …` (`build-loop-read.bats:46-49`), and it passes in E1.

**Evidence:** `scripts/build-loop.sh:139-143`, `scripts/build-loop.sh:169-178`, `test/scripts/build-loop-read.bats:46-49`

---

## Claim 6: "A line outside a fence counts as a settings line when it starts with the key (any case) after any blanks, >, list markers, # * _ ` ~ and byte-order marks, so a quoted, bold, heading or indented copy is a second line, not a hidden one."

**Location:** `scripts/build-loop.sh:28-31`
**Type:** Behavioral
**Legibility-target:** header contract
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stated strip set and the four named shapes (quoted, bold, heading, indented), plus numbered lists, tabs, `~~` and a trailing-blank variant. It does NOT establish that every Markdown shape rendering as the key is counted. These stay uncounted, so they are hidden copies (E2): a GFM task item `- [ ] Build-loop policy: self-merge`, link text `[Build-loop policy: self-merge](x)`, a leading NBSP, a backslash-escaped heading `\# Build-loop policy: …`, an entity `&#66;uild-loop policy: …` and a table row `| Build-loop policy: … |`.

The strip is `match(s, /^([ \t>#*_`~]|[-+][ \t]|[0123456789]+[.)][ \t]|\357\273\277)*/)`, and the key test follows `tolower(s)` (`:106-110`). In E2, `1. `, two tabs, four spaces, `~~…~~` and the bold/heading/emphasis/code-span copies (T2, T45) each count as a second line. The six shapes listed in Scope do not: each prints `policy review set` for a file whose rendered second line reads self-merge (`$S/probe1.log`). The header's four named shapes are all correct. The residue is outside the claim as worded, but it is the answer to "is anything that renders as the key still uncounted?": yes.

**Evidence:** `scripts/build-loop.sh:101-117`, `test/scripts/build-loop-read.bats:33-36`, `test/scripts/build-loop-read.bats:119-123`, `$S/probe1.log`

---

## Claim 7: "A file the lib's FENCE_AWK refuses (its comment lists each shape) is not read at all, and the line printed says why."

**Location:** `scripts/build-loop.sh:31-33`
**Type:** Behavioral
**Legibility-target:** header contract
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the odd and unbalanced outputs and the reason text on all three lines. It does not establish that FENCE_AWK's comment is itself complete (lib, not in this unit).

`odd\ *) … FILE_WHY="line $n of $f $(oddwhy "$why"), so the file is not read"; return 1` and `unbalanced\ *) …` (`:91-92`). The read_settings not-read branch puts `$why` in all three lines (`:141-143`). In E2, `<b>…</b>` prints the html reason on policy, slots and never (`$S/probe1.log`). T3 covers the comment, BOM and unbalanced reasons.

**Evidence:** `scripts/build-loop.sh:89-93`, `scripts/build-loop.sh:139-143`, `$S/probe1.log`, `test/scripts/build-loop-read.bats:42-67`

---

## Claim 8: "Acts on $PWD's git repo, like dev-cycle.sh, and needs its default branch found by name (origin/HEAD, main or master)."

**Location:** `scripts/build-loop.sh:35-36`
**Type:** Behavioral
**Legibility-target:** header contract
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers rev-parse from $PWD (including a subdirectory and a linked worktree) and the main_by_name gate. It does not establish the origin/HEAD path (no test has a remote; resolve_main is lib code, read).

`ROOT="$(git rev-parse --show-toplevel …)"`, then `cd "$ROOT"` (`:65-66`), and `main_by_name || { echo "build-loop.sh needs a default branch found by name …"; exit 1; }` (`:71`). The test that renames main to trunk passes (`build-loop-read.bats:144-146`), as do the subdirectory and worktree runs (`:160-167`).

**Evidence:** `scripts/build-loop.sh:65-71`, `scripts/lib/dev-cycle-read.sh:376-398`, `test/scripts/build-loop-read.bats:144-167`

---

## Claim 9: "Read-only: writes nothing."

**Location:** `scripts/build-loop.sh:36`
**Type:** Invariant
**Legibility-target:** header contract
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the --settings and -h paths: every git call is a read (rev-parse, symbolic-ref, show-ref, ls-tree, cat-file). It does not establish behaviour under a git configured with hooks or an fsmonitor that write (the hermetic env disables global config).

The git calls in the script and the lib functions it reaches are paraphrased — no quote available because they span `:65-89` and lib `resolve_main`/`main_entry`: rev-parse, symbolic-ref, show-ref, ls-tree and cat-file. None writes. In E2, an `ls -la --time-style=full-iso .git | md5sum` before and after a run matched (`0978effa…` both times), and `git status --porcelain` was empty (`$S/probe2.log`).

**Evidence:** `scripts/build-loop.sh:65-89`, `scripts/lib/dev-cycle-read.sh:256-267`, `$S/probe2.log`

---

## Claim 10: "Output passes through the lib's scrub (all but the two start-up errors before it, about perl and the lib, which carry no repo text); printed repo text is data."

**Location:** `scripts/build-loop.sh:37-39`
**Type:** Behavioral
**Legibility-target:** header contract
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the default invocation: the two echo-and-exit lines at `:45` and `:51` are the only output before `scrub_reexec` at `:54`. It does not establish scrubbing when the caller's environment already sets DEV_CYCLE_SCRUBBED (lib-documented: then no scrub runs, as E2 confirmed by running with it preset), or shell-level errors from `cd`/`source` before `:54`.

The script's order is `command -v perl … exit 1` (`:45`), `[[ -f "$READ_LIB" ]] || { echo …; exit 1; }` (`:51`), then `scrub_reexec "${BASH_SOURCE[0]}" "$@"` (`:54`). The lib's `[[ -z "${DEV_CYCLE_SCRUBBED:-}" ]] || return 0` (lib `:77`) is the bypass named in Scope.

**Evidence:** `scripts/build-loop.sh:45-54`, `scripts/lib/dev-cycle-read.sh:76-81`, `$S/probe2.log`

---

## Claim 11: "Exit: 0 every line printed; 1 bad usage, not a git repo, no perl or lib/dev-cycle-read.sh, or no default branch found by name."

**Location:** `scripts/build-loop.sh:40-41`
**Type:** Behavioral
**Legibility-target:** header contract
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed exit path. It does not establish behaviour on a corrupt object store (main_entry `error` is reported as "not a regular file", rc 0; see Claim 14), and -h's exit 0 is not in the list.

The `exit 1` sites are `:45`, `:51`, `:56`, `:65` and `:71`. The script's last statement is the `printf` at `:190`. The usage, trunk, non-repo and bare-copy cases pass in E1 (`build-loop-read.bats:134-158`).

**Evidence:** `scripts/build-loop.sh:45-71`, `scripts/build-loop.sh:187-192`, `test/scripts/build-loop-read.bats:134-158`

---

## Claim 12: "The reader shared with dev-cycle.sh, from this script's own directory (never the target repo's scripts/lib/), so a copy of scripts/ with its lib/ is self-contained."

**Location:** `scripts/build-loop.sh:46-50`
**Type:** Architectural
**Legibility-target:** maintainers of build-loop.sh
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the path computed from BASH_SOURCE before the cd, and the planted-lib test. It does not establish integrity of the sourced lib (D6 hash check deferred to U3b, per the override log).

The code is `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` then `READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"` (`:46-50`). The G16 test (planted `echo PLANTED`, then a bare copy that exits 1) passes.

**Evidence:** `scripts/build-loop.sh:46-54`, `test/scripts/build-loop-read.bats:152-158`

---

## Claim 13: help prints `sed -n '2,41p'`, i.e. the whole header

**Location:** `scripts/build-loop.sh:60`
**Type:** Configuration
**Legibility-target:** -h reader
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that lines 2-41 are exactly the comment header (line 42 blank, line 43 `set -euo pipefail`). It does not establish that the range is guarded against future header edits (it is hard-coded).

`-h|--help) sed -n '2,41p' "$0" | …` (`:60`). Line 41 is `# lib/dev-cycle-read.sh, or no default branch found by name.` In E2, the output of `-h` starts "The build-loop handoff's state…" and ends "…or no default branch found by name." (`$S/probe2.log`).

**Evidence:** `scripts/build-loop.sh:1-43`, `$S/probe2.log`

---

## Claim 14: "A file on main for the readers below: sets FILE_WHY and returns 1 when it is absent ("absent"), stored as anything but a regular file under plain directories, or refused by FENCE_AWK; otherwise FILE_OUT holds what the awk program $2 printed over it"

**Location:** `scripts/build-loop.sh:73-77`
**Type:** Behavioral / Error-handling
**Legibility-target:** maintainers (U1c adds callers of main_file)
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the blob, absent, notdir and odd/unbalanced paths. It does not establish the wording on main_entry's `error` result (ls-tree failed), which the comment does not list.

The case is `blob) ;; absent) … notdir\ *) … *) FILE_WHY="$f is not a regular file on the default branch"; return 1 ;;` (`:83-88`). main_entry prints `error` when ls-tree fails (lib `:261`: `|| { echo error; return; }`). That falls into `*)` and is reported as "is not a regular file". The return value fails closed, but the comment's three cases leave out a fourth, and its message names the wrong cause. A precise version would add "or its tree cannot be read (reported as not a regular file)". Reachability is low: main_by_name has already succeeded, so this takes a corrupt or unreadable object store.

**Evidence:** `scripts/build-loop.sh:79-94`, `scripts/lib/dev-cycle-read.sh:256-267`

---

## Claim 15: "One pass over docs/dev-cycle.md: per key, how many lines start with it (after blanks, >, list markers, heading and emphasis marks (# * _ ` ~) and a BOM, any case), the first two line numbers and the first line whole: "KEY COUNT FIRST SECOND<TAB>LINE"."

**Location:** `scripts/build-loop.sh:96-99`
**Type:** Behavioral
**Legibility-target:** maintainers of SETTINGS_AWK
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that every listed prefix strips (spaces, tabs, `>`, `-`/`+`/`*` markers, `N.`/`N)` markers, `# * _ ` ~`, and one or more BOMs) and the output format. It does not establish that unlisted shapes that render as the key are counted (task list `[ ]`, link brackets, NBSP, `\`-escapes, entities, `|`: see Claim 6), and "a BOM" understates the code, which strips any number.

The END rule is `print k " " c[k] " " l1[k] " " (k in l2 ? l2[k] : 0) "\t" t[k]` (`:116`), and the parser is `read -r k c l1 l2 <<<"${l%%$'\t'*}"; … text[$k]="${l#*$'\t'}"` (`:147-148`). The `t[k] = $0` stored is the CR-stripped original line, not the stripped `s` (`:111`). So the exactness checks at `:157`, `:174` and `:182` see the raw line, and a counted copy with a prefix fails them (fail closed). Under mawk the octal BOM escape matches mid-file (T2's BOM case passes).

**Evidence:** `scripts/build-loop.sh:101-117`, `scripts/build-loop.sh:145-149`, `$S/probe1.log`, `$S/bats.log`

---

## Claim 16: "A Self-merge never: entry: pathform's characters and glob marks, not starting / or -, no empty, . or .. part. Unlike pathform it allows a part starting .git (.github/, .gitignore): the list only adds refusals, so naming one must not make the line malformed and turn self-merge off."

**Location:** `scripts/build-loop.sh:118-121`
**Type:** Behavioral
**Legibility-target:** maintainers of globform
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the comparison with pathform and that `.github/`/`.gitignore` are now accepted. It does not establish how a later reader (the U3 gate) matches these globs. Note that `.git/` itself and `.GIT` are also accepted (E2: `never .git/ .GIT set`), which is consistent with "allows a part starting .git" and harmless under the comment's own premise (an extra refusal), but that premise, "the list only adds refusals", is a property of the future gate, not checked here.

pathform's part test is `[[ -n "$c" && "$c" != "." && "$c" != ".." && "$c" != [.][gG][iI][tT]* ]]` (lib `:147`). globform's is `[[ -n "$c" && "$c" != "." && "$c" != ".." ]]` (`:127`), and its character test reuses `^[*?$NAMECHARS]+$` (`:124`, the same set as pathform's glob mode, lib `:142`). The T45 `.github/ .gitignore` case passes (E1), and E2 shows `.git/ .GIT` set.

**Evidence:** `scripts/build-loop.sh:122-129`, `scripts/lib/dev-cycle-read.sh:140-149`, `$S/probe1.log`

---

## Claim 17: "Sets POLICY, POLICY_LINE, SLOTS_LINE, NEVER (the globs, or empty) and NEVER_LINE from main's commit. POLICY and NEVER are for the modes that judge a brief (--status, then the gate)."

**Location:** `scripts/build-loop.sh:130-132`
**Type:** Behavioral / Architectural
**Legibility-target:** maintainers (U1c consumers)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which globals read_settings assigns, and that NEVER is set only to the validated value. It does not establish the forward reference: --status and the gate do not exist yet (U1c and later), and nothing in this diff reads POLICY or NEVER.

The globals are set at `:141-143` (POLICY_LINE, SLOTS_LINE, NEVER_LINE), `NEVER="$v"` (`:170`, only when `why` is empty) and `POLICY="$v"` (`:178`). NEVER holds the raw `$v`, the exact string validated entry by entry (with trailing slashes kept), so the stored value matches what was validated. read_settings also defines the helper `many` (`:150`) as a global function, which the comment does not mention (not a claim).

**Evidence:** `scripts/build-loop.sh:133-185`

---

## Claim 18: "An absent file sets nothing; one that is not read turns self-merge off."

**Location:** `scripts/build-loop.sh:142`
**Type:** Behavioral
**Legibility-target:** maintainers
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the never line on the two not-read branches. It does not establish anything beyond --settings.

`if [[ "$FILE_WHY" == absent ]]; then NEVER_LINE="never none: $why"; else NEVER_LINE="never malformed: $why"; fi` (`:143`). T3 asserts `never none: no docs/dev-cycle.md on the default branch` and the open-comment `never malformed:` line, and both pass.

**Evidence:** `scripts/build-loop.sh:139-143`, `test/scripts/build-loop-read.bats:46-49`, `test/scripts/build-loop-read.bats:55-57`

---

## Claim 19: "Single spaces only: a tab or other blank would split differently in a later reader." (with the test `*[$'\t\v\f\r']*`)

**Location:** `scripts/build-loop.sh:156-157`
**Type:** Behavioral
**Legibility-target:** maintainers
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers tab, VT and FF (all executed) and the single-space regex. It does not establish anything about CR: the CR branch is unreachable, because SETTINGS_AWK strips one trailing CR and FENCE_AWK refuses any other. Non-ASCII blanks (NBSP) pass this check but are refused by globform.

In E2, `a\vb` and `a\fb` print `is not exactly "Self-merge never: GLOB ..." with single spaces`, and `a\xc2\xa0b` prints `lists entry 1, which is not an allowed glob form` (`$S/probe1.log`). T45's five tab cases pass (E1).

**Evidence:** `scripts/build-loop.sh:155-158`, `scripts/build-loop.sh:102`, `scripts/lib/dev-cycle-read.sh:215`, `$S/probe1.log`

---

## Claim 20: "not a bare $v: the shell would expand * and ? against files"

**Location:** `scripts/build-loop.sh:161`
**Type:** Behavioral
**Legibility-target:** maintainers
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the unquoted-expansion hazard: noglob is not set anywhere in the script or the lib (grep for `set -f`/`noglob` finds nothing), and the cwd is the repo root after `cd "$ROOT"`. It does not establish behaviour of `read -ra` on backslashes (`-r` is given, and backslash is not in the allowed set anyway).

The line is `IFS=' ' read -ra parts <<<"$v"` (`:161`). Here-string words are not pathname-expanded, so the comment's contrast with `for g in $v` (which would glob) holds.

**Evidence:** `scripts/build-loop.sh:161-167`

---

## Claim 21: "a" and "a/" count as the same entry for "none twice" (header ":25 a trailing / ignored"; code `seen[${g%/}]`)

**Location:** `scripts/build-loop.sh:165-166`
**Type:** Behavioral
**Legibility-target:** header contract / maintainers
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one trailing slash (`a`/`a/`, `a?`/`a?/`) and the glob-character keys `*`, `a*`. It does not establish equivalence of other spellings (`a` vs `./a` is refused outright, and `a` vs `a//` is refused as an empty part).

The code is `if [[ -n "${seen[${g%/}]-}" ]]; then why="lists entry $i twice"; break; fi; seen[${g%/}]=1`. T45's `a a/` case passes. In E2, `a? a?/`, `a* a*` and `* *` give "entry 2 twice", while `a *` and `* a` are set (`$S/probe2.log`, `$S/probe1.log`).

**Evidence:** `scripts/build-loop.sh:162-167`, `$S/probe1.log`, `$S/probe2.log`

---

## Claim 22: "a throwaway repo under $BATS_TEST_TMPDIR with a main branch, the same hermetic git environment as test/scripts/dev-cycle.bats"

**Location:** `test/lib/build-loop-fixtures.bash:2-4`
**Type:** Architectural
**Legibility-target:** test maintainers
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the git env exports. It does not establish identical locale: the fixture adds `LC_ALL=C`, which dev-cycle.bats' setup does not set.

The fixture exports `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`, the author and committer pairs and `HOME="$BATS_TEST_TMPDIR/home" LC_ALL=C` (`build-loop-fixtures.bash:13-16`). dev-cycle.bats' setup exports the same git variables and HOME (`test/scripts/dev-cycle.bats:11-15`).

**Evidence:** `test/lib/build-loop-fixtures.bash:7-21`, `test/scripts/dev-cycle.bats:8-20`

---

## Claim 23: "settings LINE...: docs/dev-cycle.md holding these lines (printf %s\n each), committed. Pass no lines for an empty file."

**Location:** `test/lib/build-loop-fixtures.bash:26-28`
**Type:** Behavioral
**Legibility-target:** test maintainers
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the no-argument case of `settings`. It does not establish any current caller relying on it: no test calls `settings` with no arguments, so no assertion is affected today.

`settings() { mkdir -p docs && printf '%s\n' "$@" > docs/dev-cycle.md && commit_all settings; }`. With no arguments, `printf '%s\n'` still applies its format once, so the file holds one newline (one empty line), not zero bytes. E2: `printf '%s\n' | od -c` gives `\n` with size 1 (`$S/probe2.log`). A test written to this comment for an "empty file" case would actually test a one-blank-line file.

**Evidence:** `test/lib/build-loop-fixtures.bash:28`, `$S/probe2.log`

---

## Claim 24: "settings_is KEY WANT / settings_like KEY PREFIX: run --settings; its KEY line must equal WANT, or start with PREFIX. On a mismatch, print the whole output."

**Location:** `test/lib/build-loop-fixtures.bash:30-34`
**Type:** Behavioral
**Legibility-target:** test maintainers
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the helpers' own behaviour (return 1 and print output plus stderr on a mismatch, as m5 and m6 show). It does not establish that a call site enforces the return value: see Claim 37 for `A && B` call sites where A's failure is swallowed. The helpers do not check `$status`.

The helpers are `settings_is() { run --separate-stderr bash "$BL" --settings; [ "$(line "$1")" = "$2" ] || { echo "want: $2"; echo "$output $stderr"; return 1; }; }`, and settings_like is the same with a prefix match. The m5/m6 logs show the "want:" and output dump.

**Evidence:** `test/lib/build-loop-fixtures.bash:33-38`, `$S/mutation-and.log`, `$S/mutation-m6.log`

---

## Claim 25: "Each test builds a throwaway repo under $BATS_TEST_TMPDIR (test/lib/build-loop-fixtures.bash); this repo is untouched."

**Location:** `test/scripts/build-loop-read.bats:3-5`
**Type:** Invariant
**Legibility-target:** test maintainers
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that setup cds into `$BATS_TEST_TMPDIR/repo` before any write, and that every write path in the suite is relative or under BATS_TEST_TMPDIR. It does not establish isolation when BATS_TEST_TMPDIR is unset (bats always sets it).

`R="$BATS_TEST_TMPDIR/repo"; mkdir -p "$R" && cd "$R" || return 1` (fixtures `:18-19`). The worktree's `git status --short` showed only pre-existing untracked files before and after E1.

**Evidence:** `test/lib/build-loop-fixtures.bash:18-20`, `test/scripts/build-loop-read.bats:152-167`

---

## Claim 26: "# Missing, a symlink, a directory, and a file only in the working tree."

**Location:** `test/scripts/build-loop-read.bats:54`
**Type:** Behavioral
**Legibility-target:** test maintainers
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four cases named. It does not mention a fifth case the block also asserts (`docs` itself a symlink: "docs is not a directory on the default branch", `:62-64`); that is an omission from the list, not a contradiction.

The block runs `git rm …` (missing), `ln -s ../real.md docs/dev-cycle.md` (symlink), `mkdir -p docs/dev-cycle.md` (directory), `ln -s real-docs docs` (parent symlink), and finally a working-tree-only file. It passes in E1.

**Evidence:** `test/scripts/build-loop-read.bats:54-66`, `$S/bats.log`

---

## Claim 27: no-echo assertion: malformed entries are never echoed (A3)

**Location:** `test/scripts/build-loop-read.bats:114-115`
**Type:** Behavioral
**Legibility-target:** test maintainers / reviewers of A3
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `\xc3`, `../x`, `/etc`, `-x` and `./b` across all 15 malformed values (the substrings do not occur in any fixed message text, checked against `:153-183`). It does not establish no-echo for values not containing one of those five substrings (e.g. `a  b`, `a b a`); the code never echoes `$v` on the malformed path (`:169`), so this holds statically.

The assertion is `[[ "$output" != *$'\xc3'* && "$output" != *../x* && "$output" != */etc* && "$output" != *-x* && "$output" != *./b* ]]`, and it passes in E1.

**Evidence:** `test/scripts/build-loop-read.bats:107-116`, `scripts/build-loop.sh:169`

---

## Claim 28: T45 comments: "Bold, heading and emphasis copies count as second lines too." / "A part starting .git is allowed: the list only adds refusals." / "Raised only on a loop's branch or in the working tree: ignored."

**Location:** `test/scripts/build-loop-read.bats:119`, `test/scripts/build-loop-read.bats:124`, `test/scripts/build-loop-read.bats:127`
**Type:** Behavioral
**Legibility-target:** test maintainers
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the loop at `:120-123` (also a code-span copy) and the `:128-131` branch/working-tree case. It does not establish that the `.github/` assertion at `:126` is enforced: its first operand is not (Claim 37).

The `.github` comment's assertion is at `:126`. Its first operand (`never .github/ .gitignore set:`) is swallowed on failure (m4), while the second operand (the policy) is enforced (m5).

**Evidence:** `test/scripts/build-loop-read.bats:119-131`, `$S/mutation-and.log`

---

## Claim 29: "# From a subdirectory and from a linked worktree, it reads the same main."

**Location:** `test/scripts/build-loop-read.bats:160`
**Type:** Behavioral
**Legibility-target:** test maintainers (G20)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that from both places the script runs and reports main's policy. It does not establish that the source is main rather than the local working tree or HEAD: the worktree branch `wt` is created at main and `sub` is in main's own checkout, so all three hold the same content and the assertion cannot tell them apart. T4 (`:77-85`) is what pins main-only reading.

The test does `git worktree add -q -b wt "$BATS_TEST_TMPDIR/wt" main && mkdir -p sub`, then asserts `policy self-merge set:` from each place (`:162-167`), and passes in E1.

**Evidence:** `test/scripts/build-loop-read.bats:160-167`

---

## Claim 30: 0797ed32 body: the tests cover the policy line (exact, one line, CR, variants, fences, comments, BOM, not plain on main or only in the working tree, this repo's real file), slots, Self-merge never: (malformed turns self-merge off; never echoed), usage and exit codes, G16, and G20 from a subdirectory and a linked worktree.

**Location:** commit 0797ed32
**Type:** Reference
**Legibility-target:** git history readers
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each listed area has a test at HEAD that passes. It does not re-check the 0797ed32 tree itself (the tests were since refactored by 0ae7d801).

Each item maps to a test at HEAD: T1-T3 (`:13-67`), G19 (`:69-75`), T4 (`:77-85`), slots (`:87-98`), T45 (`:100-132`), usage (`:134-150`) and G16/G20 (`:152-167`). All pass in E1.

**Evidence:** `test/scripts/build-loop-read.bats:13-168`, `$S/bats.log`

---

## Claim 31: 224dd52d Notes: "A policy of self-merge with a malformed never line prints "policy review unset", so the policy line always shows the policy in force."

**Location:** commit 224dd52d
**Type:** Behavioral
**Legibility-target:** git history readers
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --settings' printed line versus the POLICY variable (they agree on every branch). It does not establish the commit's "byte-exact" wording (settled Won't-Fix in the override log, not re-raised).

`POLICY_LINE="policy review unset: line ${first[policy]} reads self-merge, but the Self-merge never: line is malformed, so self-merge is off"` (`:177`), with POLICY left at review. T45 asserts this for 15 malformed values (E1), and E2 shows the same output for VT, FF, NBSP and other cases.

**Evidence:** `scripts/build-loop.sh:176-178`, `test/scripts/build-loop-read.bats:110-113`, `$S/probe1.log`

---

## Claim 32: 30676e57 R1/A1: "A tab, VT, FF or CR in the value is now malformed, and the split uses IFS=' '."

**Location:** commit 30676e57
**Type:** Behavioral
**Legibility-target:** git history readers / review-loop record
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers tab, VT and FF (executed) and the `IFS=' '` split being present. It does not establish that CR is reachable (it is not; see Claim 19).

Both changes are present at HEAD (`:157`, `:161`) and were present at 30676e57 (`git show 30676e57:scripts/build-loop.sh`, lines 161 and 165). E2 results for VT and FF: malformed.

**Evidence:** `scripts/build-loop.sh:157-161`, `$S/probe1.log`

---

## Claim 33: 30676e57 A2: "The key strip now also drops # * _ ` ~ and BOMs, so such a copy is a second line (policy unset, never malformed)."

**Location:** commit 30676e57
**Type:** Behavioral
**Legibility-target:** git history readers / review-loop record
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bold, heading, emphasis, code-span and mid-file BOM copies for policy and never. It does not establish coverage of other rendered-key shapes (Claim 6's residue).

The strip regex at `:106` includes `#*_`~` and `\357\273\277`. T2's loop (`:33-36`) and T45's loop (`:120-123`) pass.

**Evidence:** `scripts/build-loop.sh:106`, `test/scripts/build-loop-read.bats:33-36`, `test/scripts/build-loop-read.bats:120-123`

---

## Claim 34: 30676e57 A3, A4, "a" vs "a/", and header bullet ("Usage lists -h; the reader rules say which apply outside a fence and that the BOM refusal is line 1 only; the scrub note names the two start-up errors before it.")

**Location:** commit 30676e57
**Type:** Behavioral / Reference
**Legibility-target:** git history readers
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each bullet at the 30676e57 tree, and A3/A4/a-vs-a/ at HEAD. It does not cover the header's reader-rule list at HEAD: 0ae7d801 replaced it with a pointer to FENCE_AWK, as that commit states. This is superseded, not stale.

`git show 30676e57:scripts/build-loop.sh` lines 31-37 carry the list with "outside a fence … anywhere, a stray CR or a NUL byte, or a byte-order mark on line 1". Usage lists `-h | --help` (`:7`). A3 is Claim 27, A4 is Claim 16 and a-vs-a/ is Claim 21.

**Evidence:** `scripts/build-loop.sh:6-7`, `scripts/build-loop.sh:37-39`, `test/scripts/build-loop-read.bats:114-115`, `test/scripts/build-loop-read.bats:124-126`

---

## Claim 35: 30676e57 Notes: "The wider key strip fails closed: a prose line starting "**Build-loop policy:**" now unsets the policy."

**Location:** commit 30676e57
**Type:** Behavioral / Invariant
**Legibility-target:** git history readers
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that widening the strip can only add counted lines, and a counted line can only move policy to unset or never to malformed. It does not establish the converse (shapes still uncounted, Claim 6), which fails open in the sense that a rendered second copy is ignored.

More counted lines can only trigger the `-gt 1` branches (`:153`, `:173`, `:181`). A lone counted prefixed line fails the exact-text tests on the raw `t[k]` (Claim 15). T2's bold case passes.

**Evidence:** `scripts/build-loop.sh:111`, `scripts/build-loop.sh:152-183`, `test/scripts/build-loop-read.bats:33-36`

---

## Claim 36: 0ae7d801: "U1b is 398 lines."

**Location:** commit 0ae7d801
**Type:** Configuration
**Legibility-target:** pr-prep size gate
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the code files' insertions in the unit diff. It does not count docs/reviews/ records.

`git diff --stat feat/build-loop-u1a...feat/build-loop-u1b -- scripts test` prints `3 files changed, 398 insertions(+)` (192 + 38 + 168).

**Evidence:** `scripts/build-loop.sh:1-192`, `test/lib/build-loop-fixtures.bash:1-38`, `test/scripts/build-loop-read.bats:1-168`

---

## Claim 37: 0ae7d801: "No assertion was dropped"

**Location:** commit 0ae7d801; `test/scripts/build-loop-read.bats:80`, `test/scripts/build-loop-read.bats:126`
**Type:** Behavioral
**Legibility-target:** git history readers / reviewers relying on test coverage
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers enforcement of every assertion the refactor rewrote. Textually every assertion is still present; the defect is that two are no longer enforced. It does not establish whether other `&&`-joined helper calls exist in later units.

Before the refactor, each pair was one guarded test, for example `[[ "$(line policy)" == "policy review set:"* && "$(line slots)" == "slots 3 default:"* ]] || { echo "$output"; return 1; }` (from `git diff 30676e57 0ae7d801`). After it, the pair is `settings_like policy "policy review set:" && settings_like slots "slots 3 default:"` (`build-loop-read.bats:80`) and `settings_like never "never .github/ .gitignore set:" && settings_like policy "policy self-merge set:"` (`:126`). Under bash's errexit rules, a failing command on the left of `&&` does not stop the shell, and neither line is the last in its test. So a wrong first operand is silently ignored.

The m4 mutation changes the first operands to `policy WRONG set:` and `never WRONG set:`, and both T4 and T45 still report `ok`. The m5 mutation, which changes the second operand at `:126`, is caught. The m6 mutation, which changes the first operand at `:84` (the last line of T4), is caught. Effect: T4's working-tree check (`:80`, "a self-merge policy in the working tree does not decide") and T45's `.github/` acceptance check (A4's regression test) no longer fail when they should. T4's `:82` and the slots operand at `:80` still partly cover the first.

**Evidence:** `test/scripts/build-loop-read.bats:77-85`, `test/scripts/build-loop-read.bats:124-126`, `test/lib/build-loop-fixtures.bash:33-34`, `$S/mutation-and.log`, `$S/mutation-m6.log`

---

## Claim 38: 0ae7d801: "A mutation check: without the IFS=' ' split, T45 fails on the tab cases; the explicit tab test is a second guard (globform also refuses a tab inside an entry)."

**Location:** commit 0ae7d801
**Type:** Behavioral
**Legibility-target:** git history readers / reviewers deciding whether both guards are needed
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three mutations on the HEAD tree (and the same two guards existed at 30676e57, so the claim was never true of any committed tree). It does not establish what an uncommitted intermediate state the author tested may have held. Matches the logged pattern of commit messages claiming test outcomes that do not reproduce.

Results: m1 (only `IFS=' '` removed, `read -ra parts <<<"$v"`) gives T45 `ok`. m2 (only the `*[$'\t\v\f\r']*` test removed) gives T45 `ok`. m3 (both removed) gives T45 `not ok`, at `:111` with `never a	b set:` (`$S/mutation.log`). Without the IFS split, T45 still passes, because the explicit `\t\v\f\r` test at `:157` refuses every tab case before the split. Each guard alone is sufficient, and T45 fails only when both are gone. The parenthetical is accurate: with `IFS=' '`, `a<TAB>b` is one entry and globform refuses it (m2). But the headline mutation result is refuted, and so is the framing that IFS is primary and the tab test secondary: neither guard is pinned by a test on its own.

**Evidence:** `scripts/build-loop.sh:157-164`, `test/scripts/build-loop-read.bats:107-113`, `$S/mutation.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 23** (`test/lib/build-loop-fixtures.bash:27`): "Pass no lines for an empty file". `printf '%s\n'` with no arguments writes one newline, so the file has one blank line. No caller uses it today.
- **Claim 37** (commit 0ae7d801; `test/scripts/build-loop-read.bats:80`, `:126`): "No assertion was dropped". Two first operands of `settings_like … && settings_like …` are no longer enforced: T4's working-tree policy check and T45's `.github/ .gitignore set` check. The m4 mutation passes.
- **Claim 38** (commit 0ae7d801): "without the IFS=' ' split, T45 fails on the tab cases". It does not: T45 passes with either guard removed and fails only with both removed.

### Stale
- (none)

### Mostly Accurate
- **Claim 14** (`scripts/build-loop.sh:73-77`): main_file's comment omits main_entry's `error` result (ls-tree failed). That case returns 1 but is reported as "is not a regular file on the default branch".

### Unverifiable
- (none)

Notable residues on Verified claims (not defects in the claims as worded):
- **Claim 6/15** (`scripts/build-loop.sh:28-31`, `:96-99`): rendered copies of a key that stay uncounted, so they are hidden: a GFM task item `- [ ] Key:`, link text `[Key: …](x)`, a leading NBSP, `\# Key:`, the entity `&#66;uild-loop policy:` and a table row `| Key: |`.
- **Claim 16** (`:118-121`): `.git/` and `.GIT` are accepted as never entries.
- **Claim 29** (`build-loop-read.bats:160`): the subdirectory and worktree runs cannot tell main from the working tree.

## Goal-Alignment Note

The goal is a full code review of U1b before it lands. The script's behavioural claims (header contract, fail-closed policy, never-line grammar, scrub, exit codes, read-only) all hold under execution. Two results are most relevant to landing. First, the 0ae7d801 refactor that brought U1b under the 400-line cap left two assertions unenforced (Claim 37), one of them the A4 regression test that iteration 1's fix relies on. Second, the commit's mutation evidence for the tab fix does not reproduce (Claim 38): neither tab guard is pinned by a test on its own. Both are test-suite and commit-record problems, not script defects. Fixing Claim 37 (for example `settings_like A; settings_like B` on separate lines, or `|| return 1` per call) would not grow the line count. The counting rule's residual hidden shapes (Claim 6) are outside the header's wording, and are for the security and API critics to weigh.
