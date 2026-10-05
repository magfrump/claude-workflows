**Commit:** 1d79ffef

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u1b (branch feat/build-loop-u1b)
**Scope:** `feat/build-loop-u1a...feat/build-loop-u1b` (HEAD 1d79ffef): comments in scripts/build-loop.sh, test/lib/build-loop-fixtures.bash, test/scripts/build-loop-read.bats; test titles; commit messages 0797ed32, 224dd52d, 30676e57, 0ae7d801, 1d79ffef. Review iteration 3 (final).
**Checked:** 2026-10-05
**Total claims checked:** 37
**Summary:** 31 verified, 5 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Execution environment for every `executed` claim: probes and mutants ran from the scratch dir
`/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i3/fc-r3/` (abbreviated `$S` below), between
2026-10-05T11:42Z and 11:48Z, `LC_ALL=C.UTF-8`. `$S/probe.sh NAME` commits stdin as
`docs/dev-cycle.md` on `main` in a fresh repo `$S/repos/NAME` and runs
`bash /workspace/.claude/wt-build-loop-u1b/scripts/build-loop.sh --settings` there. Mutants are
copies of scripts/, test/ and docs/ under `$S/m-*`, run with `bats test/scripts/build-loop-read.bats`
from that copy. Baseline: `bats test/scripts/build-loop-read.bats` in the worktree, exit 0, 9/9
(`$S/baseline-wt.log`, 11:43Z) and in the scratch copy (`$S/baseline.log`, exit 0).

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`): Claim 31b resembles the
logged family "commit claims a test/mutation result that does not reproduce" (cf. the A9 row for
0ae7d801); no fabricated symbol, so no new log entry.

---

## Claim 1a: "--settings  three lines from the default branch's commit, never the working tree (a build loop can write any working tree)"

**Location:** `scripts/build-loop.sh:9-10`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the blob read (`git cat-file blob "$MAIN_SHA:$f"`) and the T4/T45/T9 working-tree cases; does not establish which commit counts as "default" when origin/HEAD points at a loop branch (C18, settled Defer).
**Legibility-target:** for-orchestrator-synthesis

`scripts/build-loop.sh:82`: `FILE_OUT="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk "$FENCE_AWK$2")"`. A mutant reading the working tree (`cat "$f"`, `$S/m-wt`) fails T4 (`:81`), T45 (`:140`) and test 9 (`:176`); a mutant reading `HEAD:$f` (`$S/m-head`) fails T4 (`:84`) and T45 (`:140`).

**Evidence:** `scripts/build-loop.sh:82`; `$S/mut-wt.log`; `$S/mut-head.log` (both exit 1, 11:45Z).

---

## Claim 1b: "a second copy, or a file the lib's FENCE_AWK refuses, leaves the default (WHY says which)"

**Location:** `scripts/build-loop.sh:11-12`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all three lines' output for a second copy and a refused file; does not establish anything about the U1c lines.
**Legibility-target:** for-author

True for policy (`policy review unset`) and slots (`slots 3 default`). For the never line, neither case leaves the default status `none`: a second copy prints `never malformed: more than one line starts ...` (`scripts/build-loop.sh:188`, `NEVER_LINE="never malformed: $(many 'Self-merge never:' never)"; never_ok=""`), and a refused file prints `never malformed: ...` (`:178`). Both turn self-merge off. Lines 23-24 of the header say this ("Malformed (or a file not read) turns self-merge off"), but :11-12 says "leaves the default" for all three. Only the NEVER array stays at its default (empty). A precise version: "...leaves policy and slots at their defaults and makes the never line malformed (WHY says which)". Executed: T3 `:47-49` (open comment gives `never malformed`); `$S/copy-probes2.log`.

**Evidence:** `scripts/build-loop.sh:176-178`, `:187-188`; `test/scripts/build-loop-read.bats:47-49`, `:120-121`.

---

## Claim 2: "Set only by "Build-loop policy: self-merge" or "...: review", exactly (one trailing CR dropped); else review."

**Location:** `scripts/build-loop.sh:14-15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exact-match regex and CR strip; does not establish behavior beyond review/self-merge values (none exist).
**Legibility-target:** for-orchestrator-synthesis

`scripts/build-loop.sh:210`: `elif [[ "${text[policy]}" =~ ^Build-loop\ policy:\ (self-merge|review)$ ]]`. The CR is stripped by `{ sub(/\r$/, "") }` (`:97`) before FENCE_AWK sees the line. A self-merge value with a malformed never line also gives review (`:212-213`), which :23-24 states. T1 and T2 pass (baseline).

**Evidence:** `scripts/build-loop.sh:97`, `:208-215`; `$S/baseline-wt.log`.

---

## Claim 3: "Loops at once: "Build-loop slots: N", N from 1 to 9; else 3."

**Location:** `scripts/build-loop.sh:17`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regex `([123456789])` and the default 3 on every other branch; does not establish how a later mode uses N.
**Legibility-target:** for-orchestrator-synthesis

`scripts/build-loop.sh:218`: `=~ ^Build-loop\ slots:\ ([123456789])$`; every other arm sets `slots 3 default` (`:176`, `:216-219`). The slots test (0, 10, `3 `, 05, three) passes.

**Evidence:** `scripts/build-loop.sh:216-219`; `test/scripts/build-loop-read.bats:90-101`; `$S/baseline-wt.log`.

---

## Claim 4a: "single spaces, then a blank line or the end"

**Location:** `scripts/build-loop.sh:19-20`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what counts as "the next line" for the never line, including fences, comments, CRLF, whitespace-only lines and EOF; does not establish Markdown lazy-continuation cases beyond these.
**Legibility-target:** for-author

The "next line" checked is not the next physical line. It is the next line FENCE_AWK passes as text. `SETTINGS_AWK` runs `fence($0) { next }` (`:98`) before `if (pk != "") { nx[pk] = ($0 ~ /^[ \t]*$/); pk = "" }` (`:100`), so fence lines and fenced content are skipped and `pk` carries past them. EOF counts as blank (`nx[k] = 1` at `:105`). Executed (`$S/never-probes.log`, `$S/never-probes2.log`):
- `Self-merge never: a/` then a fence then EOF gives `set` (a fence opener counts as "a blank line or the end"; Markdown agrees, because a fence interrupts a paragraph).
- `Self-merge never: a/` then a fenced block then the text line `x` gives `malformed: line 2 is followed by a non-blank line`. Markdown would not join `x` to line 2, and the line named in WHY is not the one that triggered it. This fails closed.
- A whitespace-only, tab-only or CRLF-blank next line counts as blank, `b/\r` counts as non-blank, a one-line `<!-- c -->` counts as non-blank, and EOF with no trailing newline gives `set`.

A precise version: "then a blank line, the end, or a code fence (the next line outside fences)". This always fails closed.

**Evidence:** `scripts/build-loop.sh:96-105`, `:194`; `$S/never-probes.log`; `$S/never-probes2.log`.

---

## Claim 4b: "A glob uses letters, digits, . _ - / * ? (a trailing / ignored when comparing), has no empty, . or .. part, does not start with / or -, and is listed once. Malformed (or a file not read) turns self-merge off."

**Location:** `scripts/build-loop.sh:20-24`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers globform, the `seen` duplicate check (including `*`/`?` as associative-array keys), and the never_ok effect on the policy; does not establish how U2 matches the globs.
**Legibility-target:** for-orchestrator-synthesis

`globform` (`:156-163`) applies `^[*?$NAMECHARS]+$`, the leading `/`/`-` refusal and the empty/`.`/`..` part check. Duplicates: `if [[ -n "${seen[${g%/}]-}" ]]; then why="lists entry $i twice"` (`:201`). Because the subscript comes from an expansion, `*` and `?` act as literal keys and not as the all-elements subscript. Probes: `a/ *` and `* a/` give `set`; `* *`, `? ?`, `a* a*/`, `a a/`, `a/ a` give `twice`; `a//` gives "not an allowed glob form", because only one trailing `/` is stripped and an empty part remains; VT and FF give malformed. A malformed never line with a self-merge policy prints `policy review unset: ... so self-merge is off` (`:212-213`). An unread file prints `never malformed` (`:178`).

**Evidence:** `scripts/build-loop.sh:156-163`, `:196-206`, `:212-213`; `$S/never-probes.log`; `test/scripts/build-loop-read.bats:110-119`.

---

## Claim 5: "A line counts as a copy when its letters alone, case folded, start with the key's ("buildlooppolicy"), so markup, a table or a misplaced colon cannot hide one."

**Location:** `scripts/build-loop.sh:25-27`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the letters-only mechanism and the markup/table/link/colon shapes; does not establish that every Markdown shape is caught. The settled C19 row covers entities and zero-width characters; the shapes below are not entities.
**Legibility-target:** for-author

The mechanism holds: `s = tolower($0); gsub(/[^a-z]/, "", s)` then `index(s, "buildlooppolicy") == 1` (`:143-144`), under `env LC_ALL=C awk` (`:82`), so non-ASCII bytes are dropped. Shapes counted as second copies: table cell, link, `1.` list, `> >`, NBSP, a mid-file BOM, a digit inside the key, a 4-space indent, `\-` escape, `&#45;`, `- [ ]` task item, a one-line `<!-- -->` comment, and a prose line starting with the key's words (`$S/copy-probes.log`, `$S/copy-probes2.log`).

The conclusion "markup ... cannot hide one" is too strong. Markup that contains letters before the key hides the copy:
- `- [x] Build-loop policy: review` and `* [X] ...` (checked GFM task items) give `policy self-merge set` with the first line `Build-loop policy: self-merge`.
- `*<span>Build-loop policy: review</span>*` and `**<b>Build-loop policy</b>: review**` (inline HTML not at column 0, so FENCE_AWK's `rawhtml` does not refuse) give `policy self-merge set`.
- `Self-merge never: a/`, a blank line, then `- [x] Self-merge never: b/` gives `never a/ set` and `policy self-merge set`.

A hidden copy cannot raise anything, which is C19's premise and still holds. But it suppresses the "second copy" refusal that the header promises. A precise version: "...so markup without letters (emphasis, headings, quotes, tables, links, an unchecked task box) or a misplaced colon cannot hide one; letters before the key (a checked `[x]`, an inline HTML tag, an entity) can."

**Evidence:** `scripts/build-loop.sh:82`, `:143-147`; `$S/copy-probes.log`; `$S/copy-probes2.log` (probes taskx, taskX, inlinespan, inlinehtml, neverx).

---

## Claim 6: "Acts on $PWD's git repo ... needs its default branch found by name (origin/HEAD, main or master). Read-only: writes nothing."

**Location:** `scripts/build-loop.sh:29-30`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the main_by_name gate and the git commands invoked (ls-tree, cat-file, show-ref, symbolic-ref, rev-parse are all reads); does not establish what git does with a hostile repo config (outside this unit).
**Legibility-target:** for-orchestrator-synthesis

`:58` `ROOT="$(git rev-parse --show-toplevel ...)"`; `:64-65` `resolve_main || true; main_by_name || { echo "build-loop.sh needs a default branch found by name ..." >&2; exit 1; }`. Test 8 (`git branch -m main trunk`, which exits 1 with "needs a default branch") passes. No write command appears in the script (paraphrased — no quote available because the claim covers the absence of code: no redirection to a file, no git write subcommand in `scripts/build-loop.sh`).

**Evidence:** `scripts/build-loop.sh:58-65`; `test/scripts/build-loop-read.bats:153-155`; `$S/baseline-wt.log`.

---

## Claim 7: "Output passes through the lib's scrub (but for the start-up errors about perl and the lib); printed repo text is data."

**Location:** `scripts/build-loop.sh:31-32`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the ordering of the perl and lib checks before `scrub_reexec`; does not establish the scrub's own coverage (lib, U1a).
**Legibility-target:** for-orchestrator-synthesis

`:38` (perl check) and `:44` (lib check) exit before `:47 scrub_reexec "${BASH_SOURCE[0]}" "$@"`. Everything after that line, including usage errors, help and git's own stderr, runs in the child whose stdout and stderr go through `scrub` (lib `:76-81`).

**Evidence:** `scripts/build-loop.sh:38-47`; `scripts/lib/dev-cycle-read.sh:76-81`.

---

## Claim 8: "Exit: 0 every line printed (or help); 1 bad usage, not a git repo, no perl or lib/dev-cycle-read.sh, or no default branch found by name."

**Location:** `scripts/build-loop.sh:33-34`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers help, usage, no-repo, no-default-branch and unread-file runs; does not establish the exit status when perl is absent (not run).
**Legibility-target:** for-orchestrator-synthesis

`bash scripts/build-loop.sh --help` exits 0 and prints header lines 2-34 (`$S/help.out`, 33 lines plus 2 setlocale warnings from the host locale). Test 8 covers usage, no-repo and no-default-branch (exit 1). A dup tree, a missing blob and a gitlink each print three lines and exit 0 (`$S/exec-git-probes.log`).

**Evidence:** `scripts/build-loop.sh:49-56`; `$S/help.out`; `$S/exec-git-probes.log`; `test/scripts/build-loop-read.bats:143-159`.

---

## Claim 9: "The reader shared with dev-cycle.sh, from this script's own directory (never the target repo's scripts/lib/), so a copy of scripts/ with its lib/ is self-contained."

**Location:** `scripts/build-loop.sh:40-42`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the source path; does not establish anything about dev-cycle.sh's own sourcing.
**Legibility-target:** for-orchestrator-synthesis

`:43` `READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"`. Test 9 (a planted `scripts/lib/dev-cycle-read.sh` never runs; a bare copy exits 1) passes, and the mutants in `$S/m-*` ran from copied trees.

**Evidence:** `scripts/build-loop.sh:39-46`; `test/scripts/build-loop-read.bats:161-168`; `$S/baseline-wt.log`.

---

## Claim 10: "Read main's own objects: a replace ref could swap in any settings blob."

**Location:** `scripts/build-loop.sh:62-63`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `git replace` of main's blob and of main's root tree; does not establish other object-substitution routes (grafts, alternates), and no test pins this (the suite has no replace case).
**Legibility-target:** for-orchestrator-synthesis

`export GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1` (`:63`). With main's blob replaced by one reading self-merge (`$S/repos/replB`), HEAD prints `policy review set`. A mutant without the variable (`$S/mut-norepl`) prints `policy self-merge set`. The same happens when main's tree is replaced by another branch's tree (`$S/repos/replT`). Commands: `cd $S/repos/{replB,replT} && bash <script> --settings`, exit 0, 2026-10-05T11:47:53Z.

**Evidence:** `scripts/build-loop.sh:62-63`; `$S/exec-git-probes.log`.

---

## Claim 11: "A file on main: FILE_OUT is what awk program $2 (after FENCE_AWK) printed over it; or it returns 1 with FILE_WHY "absent" or why it was not read (main_entry, a failed read, or FENCE_AWK's "odd N WHY" / "unbalanced N")."

**Location:** `scripts/build-loop.sh:67-69`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every arm of main_file (`:71-88`, read whole) and how each reaches the printed lines; does not establish main_entry's internals (U1a).
**Legibility-target:** for-orchestrator-synthesis

Every arm was produced and printed as described:
- absent: T3 `:57`.
- notdir: T3 `:65`.
- `error`: a tree listing `dev-cycle.md` twice, built with `hash-object --literally`, gives "the default branch's tree could not be read for docs/dev-cycle.md".
- notfile: a symlink (T3), a directory (T3), and a gitlink (`$S/repos/gitlink`) give "is not a regular file".
- failed read: a blob object moved out of the repo gives "could not be read from the default branch" (pipefail fails the `$(...)`).
- odd and unbalanced: T3 `:47`, `:53`.

**Evidence:** `scripts/build-loop.sh:71-88`, `:174-178`; `$S/exec-git-probes.log`; `test/scripts/build-loop-read.bats:44-67`.

---

## Claim 12: "per key, how many lines start with it once everything but letters is dropped and case folded (so markup, blanks, a BOM or a misplaced colon cannot hide a copy), the first two line numbers, whether the line after the first is blank (NEXT 1) or not, and the first line whole"

**Location:** `scripts/build-loop.sh:90-94`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers SETTINGS_AWK `:96-111` and its output format; the two imprecisions are the same as in Claims 4a and 5.
**Legibility-target:** for-author

The output format `k " " c[k] " " l1[k] " " (k in l2 ? l2[k] : 0) " " nx[k] "\t" t[k]` (`:152`) matches "KEY COUNT FIRST SECOND NEXT<TAB>LINE". Two parts need qualifiers:
- "cannot hide a copy" fails for letter-bearing markup (Claim 5's probes).
- "the line after the first" is the next line that FENCE_AWK does not skip, with EOF counting as blank (Claim 4a's probes).

A mid-file BOM does not hide a copy (probe midbom). A BOM on line 1 makes FENCE_AWK refuse the file (T3).

**Evidence:** `scripts/build-loop.sh:96-111`; `$S/copy-probes.log`; `$S/never-probes2.log`.

---

## Claim 13: "A never entry: pathform's rule, but a .git* part (.github/) is allowed, since the list only adds refusals"

**Location:** `scripts/build-loop.sh:112-113`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers globform versus lib pathform's glob mode; does not establish whether U2 treats `.git*` globs safely.
**Legibility-target:** for-orchestrator-synthesis

globform (`:156-163`) matches pathform (lib `:140-149`) with `set="^[*?$NAMECHARS]+\$"`, except that it drops the `[.][gG][iI][tT]*` part refusal. `.gitx/y .GITHUB` gives `set`. A mutant calling `pathform "${g%/}" glob` (`$S/m-pathform`) fails T45 at `:130` (exit 1, 11:45:29Z).

**Evidence:** `scripts/build-loop.sh:156-163`; `scripts/lib/dev-cycle-read.sh:140-149`; `$S/mut-pathform.log`; `$S/never-probes.log`.

---

## Claim 14: "Sets POLICY, POLICY_LINE, SLOTS_LINE, NEVER (an array of the checked globs, each as written, a trailing / kept) and NEVER_LINE from main's commit."

**Location:** `scripts/build-loop.sh:122-124`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the values after one and after repeated calls in one process, including resets (C3); does not establish the later modes' use of POLICY/NEVER (U1c+).
**Legibility-target:** for-orchestrator-synthesis

`:172` `POLICY=review; NEVER=()` at entry; `:206` `NEVER=("${parts[@]}")` only on success. A copy (`$S/mut-twice`) calls read_settings three times with main changed between calls. The results are `NEVER=([0]="a/" [1]="b/*.sh")` and self-merge, then `POLICY="review"` with `NEVER=()` after a malformed line, then the same after the file is removed. Each run rewrites all three *_LINE variables.

**Evidence:** `scripts/build-loop.sh:167-221`; `$S/exec-twice.log` (exit 0, 11:47:58Z).

---

## Claim 15: "An absent file sets nothing; one that is not read turns self-merge off."

**Location:** `scripts/build-loop.sh:177`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `:178` branch; does not establish anything beyond main_file's FILE_WHY values.
**Legibility-target:** for-orchestrator-synthesis

`if [[ "$FILE_WHY" == absent ]]; then NEVER_LINE="never none: $why"; else NEVER_LINE="never malformed: $why"; fi` (`:178`). Executed: absent gives `never none` (T3 `:58`). Dup tree, missing blob and gitlink give `never malformed`.

**Evidence:** `scripts/build-loop.sh:174-178`; `$S/exec-git-probes.log`.

---

## Claim 16: "Split on single spaces only; globform then refuses any other blank in an entry."

**Location:** `scripts/build-loop.sh:191`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers tab, VT and FF within or around entries; does not establish non-ASCII blanks (refused anyway by the character set).
**Legibility-target:** for-orchestrator-synthesis

`:192` `! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$` refuses double, leading and trailing spaces. `:197` `IFS=' ' read -ra parts`. A tab, VT or FF inside an entry reaches globform and is refused ("not an allowed glob form"). Run with T45 tab cases and the VT/FF probes.

**Evidence:** `scripts/build-loop.sh:190-203`; `test/scripts/build-loop-read.bats:112`; `$S/baseline-wt.log`.

---

## Claim 17: "not a bare $v: the shell would expand * and ? against files"

**Location:** `scripts/build-loop.sh:197`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `read -ra` not globbing; does not establish anything about later modes.
**Legibility-target:** for-orchestrator-synthesis

The probe `Self-merge never: * a/` ran with cwd at a repo root holding `docs/`. It printed `never * a/ set`, unexpanded.

**Evidence:** `scripts/build-loop.sh:197`; `$S/never-probes.log` (star2).

---

## Claim 18: "settings LINE...: docs/dev-cycle.md holding these lines (printf %s\n each), committed. With no lines the file holds one empty line."

**Location:** `test/lib/build-loop-fixtures.bash:24-25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers printf with no arguments; does not establish commit_all's behavior when nothing changed (it fails, which fails the test).
**Legibility-target:** for-orchestrator-synthesis

`printf '%s\n' | od -c` outputs `\n`, one byte, which is one empty line (A11 fixed).

**Evidence:** `test/lib/build-loop-fixtures.bash:26`; command output in this session (`0000000  \n`).

---

## Claim 19: "settings_is KEY WANT / settings_like KEY PREFIX: run --settings; its KEY line must equal WANT, or start with PREFIX. On a mismatch, print the whole output."

**Location:** `test/lib/build-loop-fixtures.bash:28-29`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both helpers; "the whole output" is stdout plus stderr on one echo.
**Legibility-target:** for-orchestrator-synthesis

`:31-32` `|| { echo "want: $2"; echo "$output $stderr"; return 1; }`. Mutant failures print `want:` followed by all three lines (`$S/mut-dash.log`, `$S/mut-head.log`).

**Evidence:** `test/lib/build-loop-fixtures.bash:31-32`; `$S/mut-dash.log`.

---

## Claim 20: "line KEY: the --settings output line that starts with KEY."

**Location:** `test/lib/build-loop-fixtures.bash:34`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the first matching line (`grep -m1 "^$1 "`); does not establish behavior for keys with regex metacharacters (none used).
**Legibility-target:** for-orchestrator-synthesis

`:36` `line() { printf '%s\n' "$output" | grep -m1 "^$1 " || true; }`.

**Evidence:** `test/lib/build-loop-fixtures.bash:36`.

---

## Claim 21: "--settings reads main's commit: the working tree and other branches never decide (T4)" and "Committed on a checked-out loop branch: HEAD is not main."

**Location:** `test/scripts/build-loop-read.bats:78`, `:82`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers T4's discrimination of main vs working tree vs HEAD; does not establish origin/HEAD cases (C18).
**Legibility-target:** for-orchestrator-synthesis

The working-tree mutant fails at `:81`; the HEAD mutant fails at `:84`.

**Evidence:** `$S/mut-wt.log`; `$S/mut-head.log`.

---

## Claim 22: "Copies in markup, a table, a link or with a misplaced colon count as second lines too."

**Location:** `test/scripts/build-loop-read.bats:122`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the eight shapes listed at `:123-124`; does not establish that letter-bearing markup counts (it does not, see Claim 5).
**Legibility-target:** for-orchestrator-synthesis

All eight shapes give `never malformed: more than one line` (baseline passes).

**Evidence:** `test/scripts/build-loop-read.bats:123-127`; `$S/baseline-wt.log`.

---

## Claim 23: "A part starting .git is allowed: the list only adds refusals."

**Location:** `test/scripts/build-loop-read.bats:128`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the assertion at `:130`; see Claim 13.
**Legibility-target:** for-orchestrator-synthesis

The pathform mutant fails exactly at `:130`.

**Evidence:** `$S/mut-pathform.log`.

---

## Claim 24: "A never line Markdown would continue on the next line is malformed."

**Location:** `test/scripts/build-loop-read.bats:131`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the plain next-line case at `:132-135`; the fence nuance is in Claim 4a.
**Legibility-target:** for-orchestrator-synthesis

`:133` asserts the exact reason. `:134-135` asserts that a blank line keeps the line set. Both pass.

**Evidence:** `test/scripts/build-loop-read.bats:131-135`; `$S/baseline-wt.log`.

---

## Claim 25: "Raised only on a loop's branch or in the working tree: ignored."

**Location:** `test/scripts/build-loop-read.bats:136`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `:137-140`.
**Legibility-target:** for-orchestrator-synthesis

The HEAD and working-tree mutants both fail at `:140`.

**Evidence:** `$S/mut-head.log`; `$S/mut-wt.log`.

---

## Claim 26: "From a subdirectory and from a linked worktree, it reads the same main."

**Location:** `test/scripts/build-loop-read.bats:169`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main vs the working trees of the main checkout and the linked worktree; does not establish main vs the worktree's HEAD, because the `wt` branch is created at main (`git worktree add -q -b wt ... main`, `:171`) and HEAD equals main's commit in both runs (see Claim 31b).
**Legibility-target:** for-orchestrator-synthesis

The working-tree mutant fails test 9 at `:176`. The HEAD mutant passes test 9.

**Evidence:** `test/scripts/build-loop-read.bats:169-177`; `$S/mut-wt.log`; `$S/mut-head.log`.

---

## Claim 27: Remaining test titles (T1 "a trailing CR included", T2 "policy variants are unset, so review, and say why", T3 "a fenced line, an open comment, a BOM or a file that is not plain on main reads review", slots "1 to 9 on one exact line, else 3", test 8 "prints its three lines in order and exits 0; usage errors and a missing default branch exit 1", test 9 title)

**Location:** `test/scripts/build-loop-read.bats:13`, `:24`, `:43`, `:90`, `:143`, `:161`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each title against its body's assertions as run; does not establish coverage of the settled C14-C17 gaps.
**Legibility-target:** for-orchestrator-synthesis

All 9 pass at HEAD. Each body asserts what its title names (paraphrased — no quote available because the claim spans six test bodies, each read in full).

**Evidence:** `test/scripts/build-loop-read.bats:13-178`; `$S/baseline-wt.log`.

---

## Claim 28: 1d79ffef R2: "The checks are separate commands now; a mutation back to pathform fails T45."

**Location:** commit 1d79ffef message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every settings_is/settings_like pair and loop-body helper; does not establish other `&&` chains (e.g. `:71` `mkdir ... && cp ... && commit_all`, which fails later at `:74` anyway).
**Legibility-target:** for-orchestrator-synthesis

`rg 'settings_(is|like)[^;]*&&'` and `rg '&& *settings_(is|like)'` find no matches. A failing helper inside a loop body is fatal: a mutant accepting `-x` (`$S/m-dash`) fails at `:114`. The pathform mutant fails at `:130`.

**Evidence:** `$S/mut-dash.log`; `$S/mut-pathform.log`.

---

## Claim 29: 1d79ffef R3/A5: "A line now counts as a copy when its letters alone, case folded, start with the key's, so any of them is a second line (policy unset, never malformed). A never line followed by a non-blank line is malformed."

**Location:** commit 1d79ffef message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers "any of them", meaning the named shapes (markup closing before the colon, table cell, link, `Self-merge never :`); does not establish the header's broader "cannot hide" (Claim 5) or the fence nuance (Claim 4a).
**Legibility-target:** for-orchestrator-synthesis

T2 `:33-37` and T45 `:123-127` pass, and the probes confirm the shapes.

**Evidence:** `$S/copy-probes.log`; `$S/baseline-wt.log`.

---

## Claim 30: 1d79ffef A6, A7, A8, A11-A13, C3, C13 ("GIT_NO_REPLACE_OBJECTS=1 ..."; "main_file names main_entry's error and a failed blob read"; "NEVER is an array of the checked entries"; "fixture and header comments; Exit names help; "Unknown option" as in the sibling scripts"; "read_settings resets POLICY and NEVER"; "the no-echo check covers tabs")

**Location:** commit 1d79ffef message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed fix as present and working; see Claims 8, 10, 11, 14, 18.
**Legibility-target:** for-orchestrator-synthesis

The evidence is Claims 10, 11, 14, 18 and 8. `"Unknown option: $1"` (`:55`) matches `scripts/dev-cycle.sh:112` and three other scripts. `test/scripts/build-loop-read.bats:117` includes `"$output" != *$'\t'*`.

**Evidence:** `scripts/build-loop.sh:55`; `scripts/dev-cycle.sh:112`; `test/scripts/build-loop-read.bats:117`; `$S/exec-git-probes.log`; `$S/exec-twice.log`.

---

## Claim 31a: 1d79ffef A14/A15: "T4 and T45 now have a working tree and a checked-out branch that differ from main; a mutant reading HEAD fails them."

**Location:** commit 1d79ffef message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers T4 and T45 under the `HEAD:$f` mutant.
**Legibility-target:** for-orchestrator-synthesis

The `$S/m-head` mutant (`git cat-file blob "HEAD:$f"`) fails T4 (`:84`) and T45 (`:140`). Command: `cd $S/m-head && bats test/scripts/build-loop-read.bats`, exit 1, 2026-10-05T11:45:32Z.

**Evidence:** `$S/mut-head.log`.

---

## Claim 31b: 1d79ffef A14/A15: "the subdirectory and worktree runs ... now have a working tree and a checked-out branch that differ from main; a mutant reading HEAD fails them."

**Location:** commit 1d79ffef message; `test/scripts/build-loop-read.bats:169-177`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers test 9's subdirectory and worktree runs under the HEAD mutant; does not establish a gap in total coverage, since T4/T45 catch the same mutant.
**Legibility-target:** for-author

The worktree's branch is created at main: `git worktree add -q -b wt "$BATS_TEST_TMPDIR/wt" main` (`:171`). The subdirectory run is on `main` itself. In both runs HEAD's commit is main's commit, so only the working tree differs. The HEAD mutant passes test 9 (`ok 9` in `$S/mut-head.log`). Only the working-tree mutant fails it (`:176`, `$S/mut-wt.log`). A14's "worktree HEAD" half is therefore not discriminated by test 9. The defect stays caught overall, because T4 and T45 fail the same mutant. To make the claim true, commit on `wt` after `git worktree add` (as T4 does on `loop`), or drop "a checked-out branch" and "fails them" for those runs.

**Evidence:** `test/scripts/build-loop-read.bats:169-177`; `$S/mut-head.log`; `$S/mut-wt.log`.

---

## Claim 32: 1d79ffef: "The unit is 400 changed code lines"

**Location:** commit 1d79ffef message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `scripts` and `test` in the three-dot diff; does not establish pr-prep's own counting rule beyond that.
**Legibility-target:** for-orchestrator-synthesis

`git diff --numstat feat/build-loop-u1a...HEAD -- scripts test` gives 186 + 36 + 178 = 400 added, 0 removed.

**Evidence:** command output in this session (cwd worktree, exit 0).

---

## Claim 33: 1d79ffef Notes: "the letters-only match can unset the policy for a prose line that starts with the key's words (docs/dev-cycle.md has none; T3's real-file test would catch one)"

**Location:** commit 1d79ffef message (Notes)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the real file at HEAD and test 4 under appended prose lines; does not establish future edits' behavior.
**Legibility-target:** for-author

"has none" holds: the only letters-key line in `docs/dev-cycle.md` is line 7, `Build-loop policy: review (interim; Q-103)`. "T3's real-file test would catch one" holds only for the policy key. Appending `Build-loop policy is set below; see the plan.` makes test 4 fail (`$S/mut-prose.log`). Appending `Self-merge never applies to the paths below.` passes test 4 (`$S/mut-prose2.log`, exit 0), because the test asserts only the policy line. Such a never-key prose line makes the never line malformed, which would unset a future self-merge policy. Slots-key prose is likewise unchecked. A precise version: "T3's real-file test would catch a policy-key one".

**Evidence:** `test/scripts/build-loop-read.bats:70-76`; `$S/mut-prose.log`; `$S/mut-prose2.log`.

---

## Claim 34: Earlier commits' copy-rule and never claims (224dd52d "A line counts when it starts with the key in any case after blanks, > and list markers"; 30676e57 "A tab, VT, FF ... in the value is now malformed", "# * _ ` ~ and BOMs ... a second line", "a and a/ count as the same entry")

**Location:** commits 224dd52d, 30676e57 messages
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the shapes these messages name still behave as stated at HEAD (HEAD replaced the mechanism with the letters-only match, a superset); does not re-verdict the CR wording (A10, settled).
**Legibility-target:** for-orchestrator-synthesis

Every named shape still counts as a copy or is still malformed at HEAD (probes and T2/T45). The mechanism they describe was superseded but not contradicted.

**Evidence:** `$S/copy-probes.log`; `$S/never-probes.log`; `$S/baseline-wt.log`.

---

## Claims Requiring Attention

### Incorrect
- **Claim 31b** (commit 1d79ffef message; `test/scripts/build-loop-read.bats:171`): test 9's subdirectory and worktree runs have HEAD equal to main's commit, so the HEAD mutant passes them. Commit on `wt` or reword.

### Stale
(none)

### Mostly Accurate
- **Claim 1b** (`scripts/build-loop.sh:11-12`): a second copy or an unread file makes the never line `malformed`, not its default `none`.
- **Claim 4a** (`scripts/build-loop.sh:19-20`): the line checked is the next line outside fences. A fence counts as a terminator, and fenced text followed by a text line is malformed with a misleading WHY. This fails closed.
- **Claim 5** (`scripts/build-loop.sh:25-27`): letter-bearing markup hides a copy (`- [x]` task item, inline HTML such as `*<span>…`). These are new shapes outside C19's entity/zero-width row.
- **Claim 12** (`scripts/build-loop.sh:90-94`): same two qualifiers as Claims 4a and 5.
- **Claim 33** (1d79ffef Notes): test 4 catches a policy-key prose line but not a never-key or slots-key one.

### Unverifiable
(none)

---

## Goal-Alignment Note

**Success criterion (verbatim):** A markdown report saved to the path below, structured per the code-fact-check skill.

**Answered:** Yes. Saved at `docs/reviews/code-fact-check-report-build-loop-u1b-r3.md`, first line `**Commit:** 1d79ffef`. All 37 claims carry the seven fields plus Legibility-target, and the executed claims cite captured logs under the scratch dir.

**Out of scope:** Settled override-log rows (C1-C19, A9/A10, u1a rows) were not re-verdicted. One premise note: C19's rationale ("the hidden copy cannot raise the policy") still holds, but Claim 5's checked-task-item and inline-HTML shapes are hidden copies that row does not name. U1c's constraints line and --status are absent by design.

**Escalate:** Claim 31b is a commit-message/test-discrimination mismatch with no coverage loss, since T4/T45 catch the mutant. Claim 5 is an amber-candidate for the orchestrator: a checked `- [x]` or inline-HTML second copy of `Self-merge never:` leaves `never a/ set` with self-merge on, where the header promises a second copy makes the line malformed. It fails open only relative to the header's promise; nothing is raised.

**Questions/Decisions:** Whether to extend C19's Won't-Fix to letter-bearing markup (task-item `[x]`, inline HTML tags), or to strip those shapes before the letters-only match.
