Commit: 4aa2e98e

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-build-loop-u1a`, branch `feat/build-loop-u1a`)
**Scope:** branch diff `git diff main...feat/build-loop-u1a` (code files: scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, skills/dev-cycle/SKILL.md, test/scripts/dev-cycle.bats) plus the branch's commit messages (d6426e3e..4aa2e98e). U1a review iteration 4 of 4, replicate r1.
**Checked:** 2026-10-05
**Total claims checked:** 29
**Summary:** 26 verified, 3 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read; no claim below matches a logged pattern.

**Execution provenance (shared by every `executed` claim).** Host: GNU bash 5.2.15, GNU sed 4.9, mawk 1.3.4 (`/usr/bin/awk`). Scratch dir `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i4/fc-r1/` (written `$S` below); captured output under `$S/logs/`. No tracked file was modified; mutants are copies of `scripts/` and `test/scripts/` under `$S/m1`..`$S/m6`.

| Run | Command | cwd | Exit | Time (UTC) | Output |
|---|---|---|---|---|---|
| E1 | `LC_ALL=C.UTF-8 bats test/scripts/dev-cycle.bats` | worktree | 0 (68/68 ok) | 2026-10-05T16:31:16Z | `$S/logs/bats-full.txt` |
| E2 | `bash scripts/dev-cycle.sh --help` | worktree | 0 (80 lines) | 2026-10-05T16:31Z | `$S/logs/help.txt` |
| E3 | `bats -f 'help prints the whole header' m{1,2}/test/scripts/dev-cycle.bats` (m1: help reverted to `sed -n '2,80p'`; m2: main's `'2,77p'`) | `$S` | 1, 1 | 2026-10-05T16:32Z | `$S/logs/mut1.txt`, `$S/logs/mut2.txt` |
| E4 | `bats -f 'unreadable blob' m{3..6}/test/scripts/dev-cycle.bats` (m3: check_answer without `set -o pipefail`; m4: brief_fields without it; m5: brief_fields without `local -`; m6: check_answer without `local -`) | `$S` | 1, 1, 1, 1 | 2026-10-05T16:32Z | `$S/logs/mut3.txt`..`$S/logs/mut6.txt` |
| E5 | `bash probe-localdash.sh` (`local -` restore after `return 1`, of `-u`, `-f` and pipefail) | `$S` | 0 | 2026-10-05T16:32Z | `$S/logs/probe-localdash.txt` |
| E6 | `sed -n '2,/^[^#]/{/^#/p}'` on `sed1.txt` (blank line inside a header) and `sed2.txt` (line 2 not a comment) | `$S` | 0 | 2026-10-05T16:33Z | `$S/logs/sed-edge.txt` |
| E7 | fixture repo `$S/fx1`: questions.md blob removed, `check_answer Q-1` with no shell options and with `set -eu` only | `$S/fx1` | 0 | 2026-10-05T16:33Z | `$S/logs/probe-noopts.txt` |
| E8 | `git cat-file -p "$w:questions.md"` on a mktree listing questions.md twice (symlink first) | `$S/fx1` | 0 | 2026-10-05T16:33Z | `$S/logs/dup-read.txt` |
| E9 | `check_answer Q-2` on a committed questions.md with a NUL, then a CR, inside a fenced block | `$S/fx1` | 0 | 2026-10-05T16:33Z | printed in session; reproduced by the command in Claim 10 |
| E10 | `git show <c>:scripts/dev-cycle.sh \| grep -n 'help) sed'` and `grep -n -m1 '^[^#]'` for main and each branch commit | worktree | 0 | 2026-10-05T16:33Z | quoted in Claim 26 |

---

## Claim 1: "a stray carriage return, a NUL byte, or a byte-order mark on line 1" (--check-brief skip reasons)

**Location:** `scripts/dev-cycle.sh:42`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the NUL-byte addition to --check-brief's skip list, end to end through dev-cycle.sh; does not re-establish the pre-existing reasons on that line (CR, BOM, fence, HTML, refdef), which this diff did not change.

FENCE_AWK refuses a NUL line before any fence logic, `scripts/lib/dev-cycle-read.sh:216`: `if (index(l, "\0")) { refuse("nul"); return 1 }`, and oddwhy maps it, `:237`: `nul) echo "holds a NUL byte" ;;`. check_brief reaches it through brief_fields (`:340-342`: `odd\ *) read -r _ n why <<<"$BRIEF_ODD"; echo "skip $a: line $n $(oddwhy "$why"), so the brief is not read" ;;`). Test 64 passes in E1 with `[ "$output" = "skip $b: line 2 holds a NUL byte, so the brief is not read" ]` (`test/scripts/dev-cycle.bats` test "a NUL byte refuses a brief or a questions file").

**Evidence:** `scripts/dev-cycle.sh:42`, `scripts/lib/dev-cycle-read.sh:216`, `scripts/lib/dev-cycle-read.sh:237`, `scripts/lib/dev-cycle-read.sh:340-346`, `$S/logs/bats-full.txt`

---

## Claim 2: "read from docs/working/questions.md or its archive on the default branch's commit (an answer only in the working tree is not seen: it reads what main's copy says, until committed)"

**Location:** `scripts/dev-cycle.sh:56-59`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the source of the read (the default branch's commit) and the working-tree-only case; does not hold for the literal "until committed", which a commit on a branch other than the default branch does not satisfy.

The reader takes both files only from `$MAIN_SHA`, `scripts/lib/dev-cycle-read.sh:561`: `r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk -v id="$a" "$FENCE_AWK$ANSWER_AWK")"`. T34 (passing in E1) shows the gap in "until committed": after `git checkout -q -b side && git commit -qam answer && git checkout -q main`, the answer is committed yet `--check-answer Q-1` still prints `open Q-1`; only after `git merge -q side` does it print `drop Q-1` (`test/scripts/dev-cycle.bats`, test "--check-answer reads main's commit"). The same is true when the cycle runs on a non-default branch and commits there: `$MAIN_SHA` does not move. The opening clause ("on the default branch's commit") carries the right rule, so the mechanism and conclusion hold; the precise version is "until it is committed to the default branch" (SKILL.md's "until it lands" says this).

**Evidence:** `scripts/dev-cycle.sh:56-59`, `scripts/lib/dev-cycle-read.sh:551-562`, `test/scripts/dev-cycle.bats:1118-1135`, `$S/logs/bats-full.txt`

---

## Claim 3: "keep, drop, done, open (not marked ANSWERED yet) or unrecognized (answered, but no answer line was found, or the first one's text does not start with one of the options)"

**Location:** `scripts/dev-cycle.sh:59-62`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the outcome words check_answer prints as a positive line; does not establish ANSWER_AWK's option-token grammar (unchanged by this diff).

ANSWER_AWK's END prints exactly these for a single entry, `scripts/lib/dev-cycle-read.sh:539`: `else if (count) print (!answered ? "open" : done ? result : "unrecognized")`, with `result` from `option()` returning only keep, drop, done or unrecognized (`:488-501`), and check_answer prints `"$hit $a"` (`:573`). "first one's text" matches the `!done` rule taking the first answer line (`:519-533`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:488-501`, `scripts/lib/dev-cycle-read.sh:519-540`, `scripts/lib/dev-cycle-read.sh:573`

---

## Claim 4: --check-answer skip list "(not a question ID, no such entry, a heading twice in one file or in both files, a code fence never closed or not in plain column-0 form, ..., a stray carriage return, a NUL byte, a byte-order mark on line 1, a question heading inside a fence, a questions file that is not a regular file under plain directories on the default branch, or a default branch whose tree or file could not be read)"

**Location:** `scripts/dev-cycle.sh:62-71`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers completeness against every `echo "skip ..."` in check_answer reachable through dev-cycle.sh; does not cover the lib's "no default branch found by name" skip (`:550`), which dev-cycle.sh never reaches because it exits 1 first (Claim 5).

check_answer's skip lines, `scripts/lib/dev-cycle-read.sh:549-574`, map one to one: `not a question ID (Q- and digits)` (:549); `notdir` and notfile (:556, :558) = "not a regular file under plain directories"; `the default branch's tree could not be read` (:557) and `could not be read from the default branch` (:562) = "tree or file could not be read"; `more than one entry with this heading in $f` (:564) and `an entry with this heading in both` (:570) = "a heading twice in one file or in both files"; `odd` (:566, every FENCE_AWK reason incl. `nul`), `unbalanced` (:567), `quoted` (:568, "question heading inside a fence"); `no such entry` (:574). E9 confirms the NUL and CR reasons through check_answer (`skip Q-2: line 7 of docs/working/questions.md holds a NUL byte, ...`); tests 62, 64 and 67 cover notfile, notdir, NUL, unreadable blob, both-files and duplicate-tree outputs (E1).

**Evidence:** `scripts/dev-cycle.sh:62-71`, `scripts/lib/dev-cycle-read.sh:549-574`, `$S/logs/bats-full.txt`

---

## Claim 5: "--check-brief, --check-branch and --check-answer need a default branch found by name (origin/HEAD, main or master): they read its commit." / Exit "1 ... no default branch (for the digest, --check-brief, --check-branch and --check-answer)"

**Location:** `scripts/dev-cycle.sh:72-73`, `scripts/dev-cycle.sh:79-81`, `scripts/dev-cycle.sh:189-195`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exit-1 gate for the three check modes and the "the other modes do not use it" note (--check-path, --check-write, --check-fix); does not re-verify the digest's own exit-1 path (unchanged).

`scripts/dev-cycle.sh:193-194`: `if [[ "$CHECK" == --check-brief || "$CHECK" == --check-branch || "$CHECK" == --check-answer ]] && ! main_by_name; then` / `echo "$CHECK needs a default branch (origin/HEAD, main or master); found none" >&2; exit 1`. The test "--check-answer needs a default branch found by name" asserts `[ "$status" -eq 1 ] && [ -z "$output" ] && [[ "$stderr" == *"needs a default branch"* ]]` and passes (E1). A grep of dev-cycle.sh finds `MAIN_SHA`/`$MAIN` only in the gate (:193) and the digest (:247-422), not in check_path/check_write/check_fix (paraphrased — no quote available because the claim covers absence of uses; `rg -n 'MAIN_SHA|MAIN\b|main_by_name' scripts/dev-cycle.sh`).

**Evidence:** `scripts/dev-cycle.sh:72-73`, `scripts/dev-cycle.sh:79-81`, `scripts/dev-cycle.sh:189-195`, `$S/logs/bats-full.txt`

---

## Claim 6: "The header, up to the first line that is not a comment (no fixed range to go stale)." with `sed -n '2,/^[^#]/{/^#/p}'`

**Location:** `scripts/dev-cycle.sh:111-112`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what --help prints for the current file (lines 2-81, through "Printed repo text is data.") and the sed range semantics on GNU sed; does not establish BSD/macOS sed acceptance of `{/^#/p}` (no BSD sed on this host), nor the behavior for a header whose line 2 is not a comment.

E2 prints 80 lines, first `Gather the mechanical signals for one dev cycle into a markdown digest.`, last `default branch (for the digest, --check-brief, --check-branch and --check-answer); a failed step exits non-zero mid-digest. Printed repo text is data.` — the whole header, lines 2-81. The mechanism is "up to the first line matching `^[^#]`", which is the first *non-empty* non-comment line: an empty line does not match `^[^#]`, so it does not end the range; `{/^#/p}` then drops it. In this file the range actually ends at line 83 (`set -euo pipefail`), not at the empty line 82. E6 shows the difference on a header with a blank line inside: for `#!/bin/sh`, `# a`, `#`, `# b`, (empty), `# c after blank`, `x=1`, `# d after code` it prints `# a`, `#`, `# b`, `# c after blank` — the range runs past the empty line. E6 also shows GNU's `2,/re/` checks the end address only from line 3, so a non-comment line 2 would not end it. Neither case arises in dev-cycle.sh today (its header has no empty line; line 2 is a comment), so the conclusion holds; the precise version is "up to the first non-empty line that is not a comment".

**Evidence:** `scripts/dev-cycle.sh:1-83`, `scripts/dev-cycle.sh:111-112`, `$S/logs/help.txt`, `$S/logs/sed-edge.txt`

---

## Claim 7: "The caller sets -euo pipefail, cds to the repo root and sets ROOT_REAL ... inrepo, dirok, skipped, check_brief and the import walk (imported_names) exit 1 (need_root) unless ROOT_REAL is set"

**Location:** `scripts/lib/dev-cycle-read.sh:12-18`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the need_root caller list after check_answer's removal and the caller contract as dev-cycle.sh meets it; does not establish that every lib function is pipefail-independent (only brief_fields and check_answer set it themselves).

`rg -n need_root` finds calls in inrepo (`:121`), dirok (`:124`), skipped (`:125`), check_brief (`:323`) and imported_names (`:433`), and none in check_answer (`:547-575`), so removing check_answer from the list is correct. dev-cycle.sh still sets the options, `scripts/dev-cycle.sh:83`: `set -euo pipefail`. The sentence remains a true statement of the caller's contract even though brief_fields and check_answer no longer depend on its pipefail (`:292`, `:548`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:12-18`, `scripts/lib/dev-cycle-read.sh:91-125`, `scripts/lib/dev-cycle-read.sh:323`, `scripts/lib/dev-cycle-read.sh:433`, `scripts/dev-cycle.sh:83`

---

## Claim 8: "check_brief, check_branch and check_answer skip every argument unless it returned 0 with main found by name"

**Location:** `scripts/lib/dev-cycle-read.sh:21-23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_answer's new main_by_name guard; does not cover the order of checks (a non-ID argument is skipped as "not a question ID" before the main check, still a skip).

`scripts/lib/dev-cycle-read.sh:550`: `if ! main_by_name; then echo "skip $a: no default branch found by name (origin/HEAD, main or master), or resolve_main has not run"; return; fi`. Test 65 calls `check_answer Q-1` before `resolve_main` and asserts that exact skip line as its first output (E1, pass).

**Evidence:** `scripts/lib/dev-cycle-read.sh:21-23`, `scripts/lib/dev-cycle-read.sh:549-550`, `$S/logs/bats-full.txt`

---

## Claim 9: "Inputs: check_brief, check_branch, check_answer, main_entry and brief_fields read the default branch's commit, never the working tree (check_brief also refuses a brief path that is not plain in the working tree, which the cycle writes); imported_names reads the working tree at ROOT_REAL."

**Location:** `scripts/lib/dev-cycle-read.sh:29-32`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the content each function reads (git objects at `$MAIN_SHA`, never working-tree file contents) with check_brief's stated lstat exception; does not mean check_branch reads only the default branch (it also resolves `refs/heads/<name>` and counts against `$MAIN_SHA`, unchanged by this diff).

main_entry reads `git ls-tree -t --full-tree "$MAIN_SHA"` (`:263`); brief_fields `git cat-file blob "$MAIN_SHA:$1"` (`:297`); check_answer `git cat-file blob "$MAIN_SHA:$f"` (`:561`); check_brief calls `blocker "$a" file` (`:329`, the stated exception) then main_entry and brief_fields. Test 66 overwrites the brief in the working tree (`printf 'Status: dropped\nBranch: wt\n' > "$b"`) and still reads `status=[Status: open]` (E1, pass); T34 shows the same for answers.

**Evidence:** `scripts/lib/dev-cycle-read.sh:29-32`, `scripts/lib/dev-cycle-read.sh:263`, `scripts/lib/dev-cycle-read.sh:297`, `scripts/lib/dev-cycle-read.sh:329-340`, `scripts/lib/dev-cycle-read.sh:561`, `$S/logs/bats-full.txt`

---

## Claim 10: "and anywhere in the file, fenced or not, a carriage return inside a line (CommonMark ends a line there), a NUL byte (a caller reading the output through $(...) would lose it), or a byte-order mark on line 1"

**Location:** `scripts/lib/dev-cycle-read.sh:173-176`, `scripts/lib/dev-cycle-read.sh:216`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order of checks in fence() (CR, NUL, BOM before the infence branch) and the fenced case through check_answer under mawk; does not establish "\0" handling under other awks (covered by override row 224).

`scripts/lib/dev-cycle-read.sh:214-218`: `if (odd) return 1` / `if (index(l, "\r")) { refuse("cr"); return 1 }` / `if (index(l, "\0")) { refuse("nul"); return 1 }` / `if (NR == 1 && substr(l, 1, 3) == "\357\273\277") { refuse("bom"); return 1 }` / `if (infence) {` — all three precede the fence state (excerpt ends :218; enclosing fence() continues to :229 — read). E9: with a NUL, then a CR, on line 7 inside a ``` block, check_answer printed `skip Q-2: line 7 of docs/working/questions.md holds a NUL byte, ...` and `... holds a carriage return that does not end it, ...`. The `$(...)` rationale matches 2da477b7's R1 description ("Status: op<NUL>en" read as open) and test 64's brief (`Status: op\0en`) now refused.

**Evidence:** `scripts/lib/dev-cycle-read.sh:173-176`, `scripts/lib/dev-cycle-read.sh:213-229`, `$S/fx1` (E9), `$S/logs/bats-full.txt`

---

## Claim 11: main_entry prints "blob" (100644 or 100755), "absent", "notfile", "notdir PART" or "error" (no default branch found by name, ls-tree failed, or the tree lists a name twice; git's own reads would take the first copy ...)

**Location:** `scripts/lib/dev-cycle-read.sh:247-254`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each result word against the code and the "git reads the first copy" rationale; does not cover a tree entry whose name holds a slash (override row 236) or gitlinks beyond the mode switch (override row 230).

`scripts/lib/dev-cycle-read.sh:261`: `main_by_name || { echo error; return; }`; `:263`: `... 2>/dev/null)" || { echo error; return; }`; `:266`/`:269`: `[[ -z "${m[$path]+set}" ]] || dup=1` ... `[[ -z "$dup" ]] || { echo error; return; }`; `:271`: `case "${m[$p]-}" in '') echo absent; return ;; 040000) ;; *) echo "notdir $p"; return ;; esac`; `:273`: `case "${m[$1]-}" in '') echo absent ;; 100644|100755) echo blob ;; *) echo notfile ;; esac`. E8: on a tree listing `120000 ... questions.md` then `100644 ... questions.md`, `git cat-file -p "$w:questions.md"` printed `x` (the symlink blob), so git takes the first copy. Tests 64 (`MAIN_SHA=000...; main_entry` → `error`, and before resolve_main → `error`) and 67 (duplicate tree → `the default branch's tree could not be read`) pass (E1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:247-274`, `$S/logs/dup-read.txt`, `$S/logs/bats-full.txt`

---

## Claim 12: "One ls-tree call lists the path and every directory above it (-t: trees too; --full-tree: paths from the top level, whatever the current directory)."

**Location:** `scripts/lib/dev-cycle-read.sh:254-256`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the single call and its flags; does not cover its cost (override row 220).

`scripts/lib/dev-cycle-read.sh:262-263`: the loop builds `want` from each prefix of the path, then one `git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1"`. Test 65 runs `cd docs; check_answer Q-1` with ROOT_REAL unset and still gets the archive's notfile skip, so the paths resolve from the top level from a subdirectory (E1, pass).

**Evidence:** `scripts/lib/dev-cycle-read.sh:254-263`, `$S/logs/bats-full.txt`

---

## Claim 13: "The caller has checked main_by_name and the path's form (pathform, so ls-tree prints it unquoted)."

**Location:** `scripts/lib/dev-cycle-read.sh:256-257`
**Type:** Architectural / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three in-lib callers (check_brief, brief_fields, check_answer) and the pathform half; does not establish anything about U1b/U1c callers, which do not exist yet.

The pathform half holds: check_brief checks `pathform "$a"` (`:325`), brief_fields `! pathform "$1"` (`:294`), and check_answer passes only the two constant paths `docs/working/questions.md docs/working/questions-archive.md` (`:551`), which pathform accepts. The main_by_name half does not hold for every caller: brief_fields calls `[[ "$(main_entry "$1")" != blob ]]` (`:294`) without a main_by_name check of its own, relying on main_entry's `main_by_name || { echo error; return; }` (`:261`); test 64 calls `main_entry "$2"` before `resolve_main` and expects `error`. Since main_entry checks main_by_name itself and the comment's own result list names that case (`:252`: "error (no default branch found by name, ..."), the precondition sentence is half redundant rather than misleading; the precise version is "The caller has checked the path's form (pathform, ...); main_entry checks main_by_name itself."

**Evidence:** `scripts/lib/dev-cycle-read.sh:252`, `scripts/lib/dev-cycle-read.sh:256-261`, `scripts/lib/dev-cycle-read.sh:294`, `scripts/lib/dev-cycle-read.sh:325`, `scripts/lib/dev-cycle-read.sh:551`

---

## Claim 14: brief_fields comment: first unfenced line per key, "whole, after one trailing CR is dropped"; "a key with no such line stays unset"; "Otherwise it sets no key and returns 1, with BRIEF_ODD 'odd N WHY' ..., 'unbalanced N' ... or 'error' (no default branch found by name, a path pathform refuses, any main_entry answer but blob, its error included, or the blob could not be read)"

**Location:** `scripts/lib/dev-cycle-read.sh:275-287`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed outcome against the code and tests 64, 65, 66, 67; does not establish how later callers (U1b/U1c) judge the values.

`scripts/lib/dev-cycle-read.sh:293-294`: `BRIEF=(); BRIEF_ODD=""` / `if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]; then BRIEF_ODD=error; return 1; fi`; `:298`: `{ sub(/\r$/, "") }`; `:301`: `if (!(k in got)) { got[k] = 1; kv[++nk] = k "\t" $0 }`; `:304`: `|| { BRIEF_ODD=error; return 1; }`; `:308`: `odd\ *|unbalanced\ *) BRIEF=(); BRIEF_ODD="$l"; return 1 ;;`. Test 66 asserts `status=[Status: open]` from a `Status: open\r\n` line after a fenced `Status: done`, `refused [odd 2 fence] 0`, `refused [unbalanced 2] 0` and an unset branch; test 64 `refused [odd 2 nul] 0`; test 67 `refused [error]` for a deleted blob (E1, all pass).

**Evidence:** `scripts/lib/dev-cycle-read.sh:275-312`, `$S/logs/bats-full.txt`

---

## Claim 15: "pipefail for this function only (local -), so a failed read is caught whatever the caller set." (brief_fields; check_answer "# as brief_fields")

**Location:** `scripts/lib/dev-cycle-read.sh:290-292`, `scripts/lib/dev-cycle-read.sh:548`
**Type:** Error-handling / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers catching a failed `git cat-file` with no caller options, with `set -eu` only, and with `-euo pipefail`, and restoring the caller's options after a normal or early return on bash 5.2; does not establish behavior on bash older than 4.4, where `local -` is not supported (no minimum bash version is stated for the lib; see Goal-Alignment Note).

`scripts/lib/dev-cycle-read.sh:292`: `local - out l; set -o pipefail`; `:548`: `local - a="$1" f e r hit="" where="" n why; set -o pipefail  # as brief_fields`. E7, with no shell options: `opts before: hBc pf-off`, then `skip Q-1: docs/working/questions.md could not be read from the default branch`, then `opts after: hBc pf-off`; with `set -eu` only, the same skip and `after: pf-off`. E5: after a function doing `local - x; set -o pipefail; set -f; set +u; return 1`, the caller's `$-` (`huB`) and pipefail (`off`) are unchanged, so `local -` restores every `set` option, also after an early `return 1`. E4: m3 (check_answer without pipefail) falls through to the archive and prints `keep Q-1`; m4 (brief_fields without it) loses `refused [error]`; m5 and m6 (no `local -`) leak pipefail and lose `caller unchanged` — every mutant fails test 67.

**Evidence:** `scripts/lib/dev-cycle-read.sh:289-312`, `scripts/lib/dev-cycle-read.sh:547-575`, `$S/logs/probe-noopts.txt`, `$S/logs/probe-localdash.txt`, `$S/logs/mut3.txt`, `$S/logs/mut4.txt`, `$S/logs/mut5.txt`, `$S/logs/mut6.txt`

---

## Claim 16: "The whole blob is read (no early exit: SIGPIPE under pipefail)."

**Location:** `scripts/lib/dev-cycle-read.sh:295`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers brief_fields' awk program having no `exit`; does not cover FENCE_AWK's functions (they contain no exit either, checked).

The awk program at `scripts/lib/dev-cycle-read.sh:297-303` uses only `next` and an `END` block (`fence($0) { next }`, `END { if (odd) print "odd " odd " " oddwhy; else if (infence) print "unbalanced " fline; else for (i = 1; i <= nk; i++) print kv[i] }`), and FENCE_AWK (`:186-230`) holds no `exit` (paraphrased — no quote available because the claim covers absence of code; `rg -n 'exit' ` over :186-230 returns nothing).

**Evidence:** `scripts/lib/dev-cycle-read.sh:186-230`, `scripts/lib/dev-cycle-read.sh:295-304`

---

## Claim 17: check_brief: "its Status line from brief_fields ... A brief FENCE_AWK refuses ... is not read at all, and neither is one stored as anything but a regular file under plain directories (main_entry). 'new' when the default branch has no file at that path"

**Location:** `scripts/lib/dev-cycle-read.sh:313-320`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the main_entry and brief_fields paths in check_brief; does not cover the commit-selection `git log -G` logic below (unchanged).

`scripts/lib/dev-cycle-read.sh:332-339`: `e="$(main_entry "$a")"` / `absent) echo "ok $a new"; return ;;` / `blob) ;;` / `notdir\ *) ... is not a directory on the default branch"` / `error) ... the default branch's tree could not be read"` / `*) ... not a regular file on the default branch"`; then `:340`: `if ! brief_fields "$a"; then` and `:348`: `st="${BRIEF[status]-}"`. Tests 65 and 66 assert `ok $b open ...` agreeing with brief_fields; test 67 asserts `skip $b: the brief could not be read from the default branch` (E1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:313-360`, `$S/logs/bats-full.txt`

---

## Claim 18: "It reads only git objects, so it needs no ROOT_REAL and adds nothing to SKIPPED."

**Location:** `scripts/lib/dev-cycle-read.sh:545-546`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_answer's whole body (`:547-575`); does not cover main_entry's git config/environment inputs (refs/replace, override row 235).

check_answer's body calls only `main_by_name`, `main_entry` (git ls-tree), `git cat-file` and `oddwhy`; no need_root, skipped, blocker, inrepo or file test (paraphrased — no quote available because the claim covers absence of calls across the 29-line function, read whole at :547-575). Test 65 runs `check_answer` with `ROOT_REAL` set and a symlinked archive on main and prints `skipped=0`, then `unset ROOT_REAL; cd docs; check_answer Q-1` answers without exiting (E1, pass). The diff removed the old `if skipped "$f"; then ...` line, confirming the test comment's "the old working-tree reader added it to SKIPPED".

**Evidence:** `scripts/lib/dev-cycle-read.sh:541-575`, `$S/logs/bats-full.txt`

---

## Claim 19: "A failed read is a skip, never a fall-through to the other file."

**Location:** `scripts/lib/dev-cycle-read.sh:560-562`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a missing blob for questions.md with both files on main; does not cover a git failure that exits 0 with partial output (none known).

`scripts/lib/dev-cycle-read.sh:561-562`: `r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk ...)"` / `|| { echo "skip $a: $f could not be read from the default branch"; return; }`. Test 67 deletes questions.md's blob and asserts that skip (E1); mutant m3 (pipefail removed) prints `keep Q-1` from the archive instead, so the skip depends on the function's own pipefail (E4).

**Evidence:** `scripts/lib/dev-cycle-read.sh:560-563`, `$S/logs/bats-full.txt`, `$S/logs/mut3.txt`

---

## Claim 20: "it reads `questions.md` and `questions-archive.md` from the default branch's commit, so an answer, or an archive move, made only in the working tree is not seen until it lands (it reads what main's copy says, usually `open` or no such entry)"

**Location:** `skills/dev-cycle/SKILL.md:292-295`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the read source and the hedged outcome set ("usually"); does not cover the skill's flow of when step 1's answers get committed (override row 227, deferred to U4).

Same reader as Claim 2 (`scripts/lib/dev-cycle-read.sh:561`). "until it lands" is the precise rule T34 shows (`open Q-1` until `git merge -q side`, then `drop Q-1`). An archive move only in the working tree leaves main's questions.md holding the entry, which is read from main; an entry created only in the working tree yields `no such entry ... on the default branch` (`:574`); "usually" covers main's old answer and the skips (paraphrased — no quote available because the outcome set is inferred from check_answer's branches :549-574 together with T34).

**Evidence:** `skills/dev-cycle/SKILL.md:292-295`, `scripts/lib/dev-cycle-read.sh:549-574`, `$S/logs/bats-full.txt`

---

## Claim 21: test "--help prints the whole header, through its last line"

**Location:** `test/scripts/dev-cycle.bats:1276-1280`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test's power to catch a too-short fixed range (main's and iteration 3's); does not check every middle line of the help.

The test asserts `[[ "${lines[0]}" == "Gather the mechanical signals"* ]] && [[ "${lines[${#lines[@]}-1]}" == *"Printed repo text is data." ]]`. It passes on HEAD (E1) and fails against both mutants: m1 (`sed -n '2,80p'`) and m2 (`sed -n '2,77p'`) each report `not ok 1 --help prints the whole header, through its last line` at the last-line assertion (E3).

**Evidence:** `test/scripts/dev-cycle.bats:1276-1280`, `$S/logs/mut1.txt`, `$S/logs/mut2.txt`

---

## Claim 22: "# The same without the caller's pipefail: each function sets its own." (asserts `caller unchanged`)

**Location:** `test/scripts/dev-cycle.bats:1260-1266`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both functions' own pipefail and their `local -` restore; does not cover a caller with `set +e` (covered separately by E7's no-options probe).

The block runs `set -eu` only, then `check_answer Q-1; brief_fields "$2" || echo "refused [$BRIEF_ODD]"; [[ -o pipefail ]] || echo "caller unchanged"` and expects the skip, `refused [error]` and `caller unchanged`. Each of m3-m6 fails it (E4): m3 prints `keep Q-1`, m4 loses `refused [error]`, m5 and m6 lose `caller unchanged`.

**Evidence:** `test/scripts/dev-cycle.bats:1260-1266`, `$S/logs/mut3.txt`..`$S/logs/mut6.txt`

---

## Claim 23: "# A tree that lists questions.md twice (a symlink first, which git reads): error."

**Location:** `test/scripts/dev-cycle.bats:1267`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git's read of the duplicated name and the test's expected skip; does not cover how other git commands (checkout, fsck) treat such a tree.

E8 reproduces the test's tree: `git cat-file -p "$w:questions.md"` prints `x`, the symlink blob listed first. The test expects `skip Q-1: the default branch's tree could not be read, so docs/working/questions.md is not read` and passes (E1).

**Evidence:** `test/scripts/dev-cycle.bats:1267-1273`, `$S/logs/dup-read.txt`, `$S/logs/bats-full.txt`

---

## Claim 24: "# A symlinked archive on main (and in the working tree): with ROOT_REAL set at the top level, the old working-tree reader added it to SKIPPED."

**Location:** `test/scripts/dev-cycle.bats:1163-1164`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers main's check_answer calling `skipped`; does not re-run main's code (78703f22's message says the mutation was checked).

main's check_answer held `if skipped "$f"; then echo "skip $a: $SKIP_AT is not a plain file or directory, so $f is not read"; return; fi` (removed in the diff), and `skipped` appends to SKIPPED, `scripts/lib/dev-cycle-read.sh:125`: `skipped() { need_root; SKIP_AT="$(blocker "$1" "${2:-file}")"; [[ -n "$SKIP_AT" ]] || return 1; SKIPPED+=("$SKIP_AT"); }`.

**Evidence:** `test/scripts/dev-cycle.bats:1159-1174`, `scripts/lib/dev-cycle-read.sh:125`

---

## Claim 25: T34 test name "--check-answer reads main's commit: a working-tree or branch-only answer is open (T34)" and its comments

**Location:** `test/scripts/dev-cycle.bats:1118-1135`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers dev-cycle.sh's side of T34; does not cover T34's build-loop.sh and `--marker` parts (override row 221).

The test asserts `open Q-1` after a working-tree-only answer, `open Q-1` with the answer committed only on `side` (plus `[ "$(git show main:docs/working/questions.md | grep -c ANSWERED)" -eq 0 ]`), and `drop Q-1` after merging with the working-tree file removed; it passes (E1).

**Evidence:** `test/scripts/dev-cycle.bats:1118-1135`, `$S/logs/bats-full.txt`

---

## Claim 26: 4aa2e98e: "R3: --help printed a fixed `sed -n '2,80p'` that 78703f22's new help line pushed past, so help stopped mid-sentence. It now prints the header up to the first non-comment line; a test checks the last line."

**Location:** commit `4aa2e98e` message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the history of the help range across the branch; "first non-comment line" carries the empty-line nuance of Claim 6.

E10: `main` `'2,77p'` with the first non-comment line at 79 (header ends at 77, fits); `c8435580` and `2da477b7` `'2,80p'` with the header ending at 80 (line 81 empty, code at 82: fits); `78703f22` and `722884c7` `'2,80p'` with the header ending at 81 (`# default branch (for the digest, --check-brief, --check-bra...`), so that last line was cut; `4aa2e98e` `'2,/^[^#]/{/^#/p}'`. The test is Claim 21.

**Evidence:** `scripts/dev-cycle.sh:112`, E10 output (per-commit `help) sed` lines quoted above), `$S/logs/mut1.txt`

---

## Claim 27: 4aa2e98e: "A17: check_answer and brief_fields set pipefail for themselves (`local -; set -o pipefail`), so a failed `git cat-file` is caught whatever the caller set; the caller's options come back on return. Tested under `set -eu` alone, and a mutant without it fails."

**Location:** commit `4aa2e98e` message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the code, the test and the mutant claim on bash 5.2; the literal snippet `local -; set -o pipefail` is a condensed form of `local - out l; set -o pipefail` and the `local - a=...` line, not a quote.

See Claims 15 and 22: E7 (no options and `set -eu`), E5 (options restored after `return 1`), E4 (m3 and m4, each "without it", fail the test).

**Evidence:** `scripts/lib/dev-cycle-read.sh:292`, `scripts/lib/dev-cycle-read.sh:548`, `$S/logs/probe-noopts.txt`, `$S/logs/probe-localdash.txt`, `$S/logs/mut3.txt`, `$S/logs/mut4.txt`

---

## Claim 28: 4aa2e98e: "A14/A15: the help and SKILL.md say a working-tree-only answer reads what main's copy says (usually open or no such entry). A16: --check-answer's skip list names 'not a question ID' and a heading in both files."

**Location:** commit `4aa2e98e` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers presence of the described wording; the help's own wording precision is Claim 2.

`scripts/dev-cycle.sh:58-59`: `branch's commit (an answer only in the working tree is not seen:` / `it reads what main's copy says, until committed)`; `skills/dev-cycle/SKILL.md:294-295`: `(it reads what main's copy says, usually `open` or no such entry)`; `scripts/dev-cycle.sh:63-64`: `<reason>" when it cannot be read (not a question ID, no such` / `entry, a heading twice in one file or in both files, ...`. The help itself does not say "usually open or no such entry"; the commit groups both files under one parenthetical, which describes SKILL.md's text (minor; not split because the help carries the substance).

**Evidence:** `scripts/dev-cycle.sh:56-71`, `skills/dev-cycle/SKILL.md:292-295`

---

## Claim 29: 4aa2e98e: "Override-log rows: A18 and iteration 3's C9 residue, C11-C15."

**Location:** commit `4aa2e98e` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers row presence; does not judge the rows' decisions (settled).

`docs/reviews/override-log.md:232` names A18; `:233`-`:237` name iteration 3 C11, C12, C13, C14, C15; `:238` names "iteration 3 C9 residue".

**Evidence:** `docs/reviews/override-log.md:232-238`

---

## Claims Requiring Attention

### Incorrect
- none

### Stale
- none

### Mostly Accurate
- **Claim 2** (`scripts/dev-cycle.sh:59`): "until committed" should be "until committed to the default branch" (a commit on any other branch, including the one the cycle runs on, is still not seen; T34). Legibility-target: for-author.
- **Claim 6** (`scripts/dev-cycle.sh:111`): the range ends at the first *non-empty* line not starting with `#` (an empty line does not match `^[^#]`); output is correct for the current header. Legibility-target: for-author.
- **Claim 13** (`scripts/lib/dev-cycle-read.sh:256-257`): "The caller has checked main_by_name" is not true of brief_fields and is unnecessary, since main_entry checks it itself (`:261`); the pathform half is accurate. Legibility-target: for-author.

### Unverifiable
- none

Legibility-target for all other claims (1, 3-5, 7-12, 14-29, Verified): for-orchestrator-synthesis.

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved to docs/reviews/code-fact-check-report-build-loop-u1a-r1.md, structured per the code-fact-check skill, first line `Commit: 4aa2e98e`.
- Answered: yes
- Out of scope: BSD/macOS sed acceptance of `{/^#/p}` (no BSD sed on this host; the comment makes no portability claim); bash < 4.4 behavior of `local -` (the lib states no minimum bash version; it already needs bash 4.2+ for `declare -gA`).
- Escalate: to api-consistency-reviewer / architecture-review (portability, not a fact-check finding): whether the lib should state a minimum bash version now that `local -` needs bash 4.4, and whether `--help`'s `{/^#/p}` should be written `{/^#/p;}` for BSD sed if macOS hosts are in scope (unverified here). Nothing else.
- Decisions I made: three Mostly accurate claims tagged for-author but judged minor (wording only; no behavior is wrong). Execution logs kept in the scratch dir, not docs/reviews/execution-logs/, per the brief's rule that no tracked path other than this report is written.
