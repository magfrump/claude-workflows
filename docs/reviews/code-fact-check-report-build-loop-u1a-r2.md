Commit: 2da477b7

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u1a (claude-workflows, branch `feat/build-loop-u1a`)
**Scope:** `git diff main...feat/build-loop-u1a` over scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, skills/dev-cycle/SKILL.md, test/scripts/dev-cycle.bats, plus the messages of d6426e3e, c8435580 and 2da477b7 (docs/reviews/ files in the diff are not under review). Replicate fc2, review-fix iteration 2.
**Checked:** 2026-10-05
**Total claims checked:** 30
**Summary:** 27 verified, 3 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 5 entries) was read first. No claim below matches a logged pattern; the closest class (a specific measured value quoted from an artifact set) applies to the "measured 49 entries" figure in 2da477b7's message, which was re-measured and matches (Claim 29).

Environment for every executed claim: `awk` is `/usr/bin/mawk` (mawk 1.3.4 20200120); `nawk` also resolves to mawk; gawk, busybox and one-true-awk are not installed. GNU bash 5.2.15, git 2.39.5. Scratch/log dir (all captured output): `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/fc2/` (abbreviated `$FC2` below). Old-commit trees for counter-tests were built as `$FC2/tree-<rev>/scripts/{dev-cycle.sh,lib/dev-cycle-read.sh}` from `git show <rev>:...`, with HEAD's (or d6426e3e's) `test/scripts/dev-cycle.bats` copied beside them; the tests are hermetic (each builds its repo under `$BATS_TEST_TMPDIR`, `test/scripts/dev-cycle.bats:8-19`).

Key executions:
- E1 full suite at HEAD: `cd /workspace/.claude/wt-build-loop-u1a && LC_ALL=C.UTF-8 bats test/scripts/dev-cycle.bats`, exit 0, 2026-10-05T10:58:58Z, 66/66 ok → `$FC2/bats-full.txt`.
- E2 new tests against c8435580's scripts: `cd $FC2 && bats -f 'check_answer reads git only|a NUL byte refuses|template parses|first unfenced copy' tree-c8435580/test/scripts/dev-cycle.bats`, exit 1, 2026-10-05T10:59:48Z → `$FC2/bats-old-c8435580.txt` (only the NUL test fails, with output `ok docs/working/briefs/2026-01-01-n.md open <sha>`).
- E3 same filter against main's scripts: exit 1, 2026-10-05T10:59:49Z → `$FC2/bats-old-main.txt` (all four fail).
- E4 d6426e3e's test file against main's scripts: `cd $FC2 && bats tree-d6t/test/scripts/dev-cycle.bats`, exit 1, 2026-10-05T11:03:39Z → `$FC2/bats-d6-vs-main.txt`.
- E5 awk NUL probe: `printf ... | env LC_ALL=C awk '{print NR, length($0), index($0,"\0")}'` etc., cwd `$FC2`, exit 0, 2026-10-05T10:58:42Z → `$FC2/probe1.txt`.
- E6 ls-tree probe on the real repo's main, cwd worktree, exit 0, 2026-10-05T11:01:08Z → `$FC2/lstree.txt`.
- E7 brief_fields byte-fidelity and NUL-position probe, cwd `$FC2/p3`, exit 0, 2026-10-05T11:03:03Z → `$FC2/p3.txt`.
- E8 symlinked briefs dir on main, old vs new check_brief, cwd `$FC2/p4`, exit 0, 2026-10-05T11:03:11Z → `$FC2/p4.txt`.
- E9 invalid MAIN_SHA: HEAD check_brief/check_answer (cwd `$FC2/p5`, 2026-10-05T11:03:39Z → `$FC2/p5.txt`) and c8435580 check_brief (2026-10-05T11:03:54Z, exit 0 → `$FC2/p6.txt`).
- E10 A4 SKIPPED probe, ROOT_REAL set, main vs c8435580 lib, cwd `$FC2/a4`, exit 0, 2026-10-05T11:00:04Z → `$FC2/a4.txt`.

---

## Claim 1: "a stray carriage return, a NUL byte, or a byte-order mark on line 1" (--check-brief refusal list)

**Location:** `scripts/dev-cycle.sh:42`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --check-brief through dev-cycle.sh skipping a brief on main whose line 2 holds a NUL, and a NUL at line end, alone on a line, at EOF without newline and inside a fence (lib level); does not establish the behavior under an awk other than mawk.

Test 64 (`test/scripts/dev-cycle.bats:1174`) runs `bash "$DC" --check-brief "$b"` on a brief committed with `Status: op\0en` and asserts `"skip $b: line 2 holds a NUL byte, so the brief is not read"` (`test/scripts/dev-cycle.bats:1179-1180`); it passes in E1. E7 adds the edge positions: `refused [odd 2 nul]` for a NUL as the last byte with no newline, a line that is only a NUL, and a NUL inside a ``` fence.

**Evidence:** `scripts/dev-cycle.sh:42`, `scripts/lib/dev-cycle-read.sh:216`, `test/scripts/dev-cycle.bats:1174-1190`, `$FC2/bats-full.txt`, `$FC2/p3.txt`

---

## Claim 2: "from docs/working/questions.md or its archive on the default branch's commit (an answer only in the working tree reads open, or no such entry, until it is committed there)"

**Location:** `scripts/dev-cycle.sh:57-59`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --check-answer reading both files from MAIN_SHA, a working-tree-only or side-branch-only ANSWERED entry reading `open`, and a deleted working-tree file still reading main's; does not establish the "no such entry" wording for an entry that exists only in the working tree beyond reading the code path.

`check_answer` reads `git cat-file blob "$MAIN_SHA:$f"` (`scripts/lib/dev-cycle-read.sh:547`). Test 60 asserts `"open Q-1"` after answering only in the working tree and again after committing only on `side`, then `"drop Q-1"` after merging with no working-tree file (`test/scripts/dev-cycle.bats:1122-1134`); passes in E1. An entry absent from main's files ends at `else echo "skip $a: no such entry in docs/working/questions.md or questions-archive.md on the default branch"` (`scripts/lib/dev-cycle-read.sh:559`).

**Evidence:** `scripts/dev-cycle.sh:57-59`, `scripts/lib/dev-cycle-read.sh:538-559`, `test/scripts/dev-cycle.bats:1118-1135`, `$FC2/bats-full.txt`

---

## Claim 3: "a stray carriage return, a NUL byte, ... a questions file that is not a regular file under plain directories on the default branch" (--check-answer refusal list)

**Location:** `scripts/dev-cycle.sh:68-70`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the NUL refusal, a symlinked questions.md and a symlinked docs/working on main (working tree plain); does not establish gitlink/tree entries at the path (code path `*)` at `scripts/lib/dev-cycle-read.sh:545`, read but not executed).

Test 64 asserts `"skip Q-1: line 4 of docs/working/questions.md holds a NUL byte, so no entry in docs/working/questions.md is read"` (`test/scripts/dev-cycle.bats:1181-1183`); test 61 asserts the `not a regular file on the default branch` and `docs/working is not a directory on the default branch` lines (`test/scripts/dev-cycle.bats:1143-1150`). Both pass in E1.

**Evidence:** `scripts/dev-cycle.sh:68-70`, `test/scripts/dev-cycle.bats:1137-1151`, `test/scripts/dev-cycle.bats:1174-1183`, `$FC2/bats-full.txt`

---

## Claim 4: "--check-brief, --check-branch and --check-answer need a default branch found by name (origin/HEAD, main or master): they read its commit." / Exit 1 "or no default branch (for the digest, --check-brief, --check-branch and --check-answer)" / the comment at :187-190

**Location:** `scripts/dev-cycle.sh:71-72`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three check modes exiting 1 with no output when only `trunk` exists, and the guard naming exactly those three modes; does not establish that the other check modes truly never use MAIN (not traced).

The guard is `if [[ "$CHECK" == --check-brief || "$CHECK" == --check-branch || "$CHECK" == --check-answer ]] && ! main_by_name; then ... exit 1` (`scripts/dev-cycle.sh:191-192`). Test 62 deletes main, checks out `trunk` and asserts `[ "$status" -eq 1 ] && [ -z "$output" ] && [[ "$stderr" == *"needs a default branch"* ]]` (`test/scripts/dev-cycle.bats:1153-1158`), passing in E1. `--help` (`sed -n '2,80p'`, `scripts/dev-cycle.sh:110`) ends on the Exit line naming --check-answer (`$FC2/help.txt`).

**Evidence:** `scripts/dev-cycle.sh:71-72`, `scripts/dev-cycle.sh:78-80`, `scripts/dev-cycle.sh:187-193`, `test/scripts/dev-cycle.bats:1153-1158`, `$FC2/bats-full.txt`, `$FC2/help.txt`

---

## Claim 5: "A change here runs under both callers' suites (test/scripts/dev-cycle.bats, and build-loop.sh's suites under test/scripts/ as they land)"

**Location:** `scripts/lib/dev-cycle-read.sh:10-12`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that dev-cycle.bats exercises the lib and that no build-loop.sh or build-loop suite exists yet (the "as they land" qualifier); does not establish that any runner selects dev-cycle.bats when only the lib changes.

`rg -l build-loop scripts test` hits only `scripts/lib/dev-cycle-read.sh` and `scripts/dev-cycle.sh` (paraphrased — no quote available because the claim covers absence of files: no `scripts/build-loop.sh`, no `test/scripts/build-loop*.bats`). dev-cycle.bats sources the lib directly, e.g. `"$REPO_ROOT/scripts/lib/dev-cycle-read.sh"` (`test/scripts/dev-cycle.bats:1167`). c8435580's header named a nonexistent suite: `callers' suites (test/scripts/dev-cycle.bats and build-loop-read.bats)` (`git show c8435580:scripts/lib/dev-cycle-read.sh`, line 11); HEAD no longer names a file.

**Evidence:** `scripts/lib/dev-cycle-read.sh:10-12`, `test/scripts/dev-cycle.bats:1160-1172`

---

## Claim 6: "inrepo, dirok, skipped, check_brief and the import walk (imported_names) exit 1 (need_root) unless ROOT_REAL is set" (check_answer dropped from the list)

**Location:** `scripts/lib/dev-cycle-read.sh:15-17`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that check_answer no longer calls need_root (runs with ROOT_REAL unset and from a subdirectory); does not re-verify the need_root behavior of the other listed functions (unchanged; covered by test 56, which passes).

`check_answer` (`scripts/lib/dev-cycle-read.sh:534-560`, read in full) contains no `need_root`, `skipped` or `inrepo` call. Test 63 runs `check_answer Q-1; resolve_main; cd docs; check_answer Q-1` with no ROOT_REAL and gets status 0 (`test/scripts/dev-cycle.bats:1165-1168`); passes in E1, fails against main's lib with `ROOT_REAL is not set` (E3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:15-17`, `scripts/lib/dev-cycle-read.sh:534-560`, `test/scripts/dev-cycle.bats:1160-1172`, `$FC2/bats-full.txt`, `$FC2/bats-old-main.txt`

---

## Claim 7: "check_brief, check_branch and check_answer skip every argument unless it returned 0 with main found by name"

**Location:** `scripts/lib/dev-cycle-read.sh:22-23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_answer's new `main_by_name` guard and check_brief's guard; does not establish check_branch (unchanged in this diff; test 58 passes).

`if ! main_by_name; then echo "skip $a: no default branch found by name (origin/HEAD, main or master), or resolve_main has not run"; return; fi` (`scripts/lib/dev-cycle-read.sh:537`); test 63's first expected line is exactly that skip before `resolve_main` (`test/scripts/dev-cycle.bats:1169`). An invalid ID is skipped first (`:536`), which is still a skip.

**Evidence:** `scripts/lib/dev-cycle-read.sh:22-23`, `scripts/lib/dev-cycle-read.sh:536-537`, `test/scripts/dev-cycle.bats:1169-1171`, `$FC2/bats-full.txt`

---

## Claim 8: "Inputs: check_brief, check_branch, check_answer, main_entry and brief_fields read the default branch's commit, never the working tree (check_brief also refuses a brief path that is not plain in the working tree, which the cycle writes)"

**Location:** `scripts/lib/dev-cycle-read.sh:29-32`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the git reads of main_entry, brief_fields, check_answer and check_brief, and test 66's overwritten working-tree brief being ignored; does not trace check_branch (unchanged).

`main_entry` reads `git ls-tree -t --full-tree "$MAIN_SHA"` (`:261`), `brief_fields` reads `git cat-file blob "$MAIN_SHA:$1"` (`:286`), `check_answer` reads `git cat-file blob "$MAIN_SHA:$f"` (`:547`). check_brief's working-tree check is `if [[ -n "$(blocker "$a" file)" ]]; then echo "skip $a: reached through a symlink, or not a regular file"` (`scripts/lib/dev-cycle-read.sh:317`). Test 66 overwrites the working-tree brief with `Status: dropped` and still reads `status=[Status: open]` (`test/scripts/dev-cycle.bats:1216-1226`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:29-32`, `scripts/lib/dev-cycle-read.sh:261`, `scripts/lib/dev-cycle-read.sh:286`, `scripts/lib/dev-cycle-read.sh:547`, `test/scripts/dev-cycle.bats:1207-1226`, `$FC2/bats-full.txt`

---

## Claim 9: "outside a fence, ... a carriage return inside a line (CommonMark ends a line there), a NUL byte (a caller reading the output through $(...) would lose it), or a byte-order mark on line 1: fence() records the first one's line number in `odd` ... and the caller refuses the whole file"

**Location:** `scripts/lib/dev-cycle-read.sh:174-176`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the NUL atom of the FENCE_AWK header (recorded as `odd`, whole file refused, the $(...) rationale); does not establish non-mawk awks (see Claim 10).

The mechanism and the rationale hold: a NUL line sets `odd` and the file is refused (E7, test 64), and c8435580's lib, which lacked the check, printed `ok docs/working/briefs/2026-01-01-n.md open ...` for `Status: op\0en` (E2), i.e. bash's `$(...)` dropped the NUL. The imprecision: the list sits after "outside a fence," but the NUL check runs before the fence state is consulted, so it also refuses a NUL inside a fence:

```
  if (index(l, "\r")) { refuse("cr"); return 1 }
  if (index(l, "\0")) { refuse("nul"); return 1 }  # ...
  if (NR == 1 && substr(l, 1, 3) == "\357\273\277") { refuse("bom"); return 1 }
  if (infence) {
```
(`scripts/lib/dev-cycle-read.sh:215-218`; excerpt ends :218; enclosing fence() continues to :228 — read). E7's `infence` brief (NUL on a line between ``` fences) gives `refused [odd 2 nul]`. The precise version: "anywhere, in a fence or not, a carriage return inside a line, a NUL byte, or a BOM on line 1" (the same applies to the pre-existing CR atom). A reader is misled only toward thinking the refusal is narrower than it is.

**Evidence:** `scripts/lib/dev-cycle-read.sh:163-179`, `scripts/lib/dev-cycle-read.sh:213-228`, `$FC2/p3.txt`, `$FC2/bats-old-c8435580.txt`

---

## Claim 10: `if (index(l, "\0")) { refuse("nul"); return 1 }  # $(...) drops NUL, so a printed line would not be the line read`

**Location:** `scripts/lib/dev-cycle-read.sh:216`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers mawk 1.3.4 (the installed `awk`, run as `env LC_ALL=C awk`): `"\0"` is a one-byte NUL string, records keep NUL bytes intact, and the check fires for NUL at line start, middle, end, EOF-without-newline and alone, never for a NUL-free or empty line; does not establish gawk, busybox or one-true-awk (none installed).

E5 output: `BEGIN{s="\0"; print length(s)}` prints `1` and emits byte `\0`; `printf '\0abc\nab\0c\nabc\0\nabc\n\n' | awk '{print NR, length($0), index($0,"\0")}'` gives `1 4 1`, `2 4 3`, `3 4 4`, `4 3 0`, `5 0 0`; `printf 'ab\0cd\n' | awk '{print}' | od -c` shows `a b \0 c d \n` (no truncation). Residue worth knowing (static, not executed — paraphrased — no quote available because the other awks are not installed): in an awk whose strings are NUL-terminated C strings, `"\0"` would be the empty string, and mawk itself returns `index("abc","")` = `1` (E5), so such an awk could refuse every non-empty line as "nul" (fail closed). The lib always invokes `awk` from PATH, so this matters only where `awk` is not mawk/gawk.

**Evidence:** `scripts/lib/dev-cycle-read.sh:216`, `$FC2/probe1.txt`, `$FC2/p3.txt`

---

## Claim 11: `nul) echo "holds a NUL byte" ;;`

**Location:** `scripts/lib/dev-cycle-read.sh:237`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the oddwhy text reaching both --check-brief and --check-answer skip lines; does not establish other callers (none exist outside the lib).

Test 64's expected lines contain `line 2 holds a NUL byte` and `line 4 of docs/working/questions.md holds a NUL byte` (`test/scripts/dev-cycle.bats:1180-1182`); passes in E1.

**Evidence:** `scripts/lib/dev-cycle-read.sh:231-240`, `test/scripts/dev-cycle.bats:1179-1183`, `$FC2/bats-full.txt`

---

## Claim 12: "check_brief, check_branch and check_answer read its commit, so they answer only when it was found by name, never for the current branch's fallback or before resolve_main has succeeded."

**Location:** `scripts/lib/dev-cycle-read.sh:242-244`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_answer's and check_brief's `main_by_name` guards and the before-resolve_main case; does not establish check_branch (unchanged).

`main_by_name() { [[ -n "$MAIN_SHA" && -n "$MAIN_BY_NAME" ]]; }` (`scripts/lib/dev-cycle-read.sh:246`); check_answer guards at `:537`. Test 63 shows the skip before `resolve_main`; test 62 shows the fallback case via dev-cycle.sh.

**Evidence:** `scripts/lib/dev-cycle-read.sh:242-246`, `scripts/lib/dev-cycle-read.sh:537`, `test/scripts/dev-cycle.bats:1153-1171`, `$FC2/bats-full.txt`

---

## Claim 13: main_entry's contract: prints "blob" (100644 or 100755), "absent", "notfile", "notdir PART", or "error" (no default branch found by name, or ls-tree failed: never read as absent)

**Location:** `scripts/lib/dev-cycle-read.sh:247-252`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every output token, the two error triggers (no main by name; invalid MAIN_SHA making ls-tree exit 128), and that both callers (check_brief, check_answer — the only two, by `rg -n main_entry`) branch on `error` to a skip; does not establish ls-tree failures other than a bad object (e.g. a corrupt repo) or partial output with exit 0.

```
  main_by_name || { echo error; return; }
  ...
  out="$(git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1")" || { echo error; return; }
  while IFS=$'\t' read -r mode path; do [[ -n "$path" ]] && m["$path"]="${mode%% *}"; done <<<"$out"
  for p in "${want[@]}"; do
    case "${m[$p]-}" in '') echo absent; return ;; 040000) ;; *) echo "notdir $p"; return ;; esac
  done
  case "${m[$1]-}" in '') echo absent ;; 100644|100755) echo blob ;; *) echo notfile ;; esac
```
(`scripts/lib/dev-cycle-read.sh:259-266`). The ls-tree call is a single command, not a pipeline, so its exit status is what `|| { echo error; ... }` tests. E6: `git ls-tree` with a valid commit and a nonexistent path exits 0 with no line for it (→ absent, correct); with `0000…0` it prints `fatal: not a tree object` and exits 128. Test 64 asserts `error` before `resolve_main` and with the zero SHA (`test/scripts/dev-cycle.bats:1184-1189`). Callers: check_brief `error) echo "skip $a: the default branch's tree could not be read"; return ;;` (`:325`) and check_answer `error) echo "skip $a: the default branch's tree could not be read, so $f is not read"; return ;;` (`:544`); E9 shows both lines at HEAD, while c8435580's check_brief printed `ok docs/working/briefs/2026-01-01-a.md new` for the same input (`$FC2/p6.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:247-267`, `scripts/lib/dev-cycle-read.sh:320-327`, `scripts/lib/dev-cycle-read.sh:539-546`, `test/scripts/dev-cycle.bats:1184-1189`, `$FC2/lstree.txt`, `$FC2/p5.txt`, `$FC2/p6.txt`

---

## Claim 14: "One ls-tree call lists the path and every directory above it (-t: trees too; --full-tree: paths from the top level, whatever the current directory)."

**Location:** `scripts/lib/dev-cycle-read.sh:252-254`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the single call's output includes the path and each ancestor directory, and that it works from a subdirectory; does not establish output size — it also lists every child of each named ancestor (49 entries for docs/working/questions.md in this repo, the settled A3 cost, override row 220).

E6 on this repo's main: `git ls-tree -t --full-tree <main> -- docs docs/working docs/working/questions.md` lists `docs`, `docs/working`, `docs/working/questions.md` among 49 lines (children of `docs` and `docs/working` included). With only the file path, `-t` alone already prints the two ancestor trees and the blob (3 lines). Test 63 calls check_answer after `cd docs` and gets the expected answer (`test/scripts/dev-cycle.bats:1166-1171`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:252-261`, `test/scripts/dev-cycle.bats:1160-1172`, `$FC2/lstree.txt`

---

## Claim 15: "for each key, the first line outside a fence (FENCE_AWK) that starts "Status:", "Branch:", "Policy:", "Paths:", "Asked:" or "Dispatched:", whole, after one trailing CR is dropped" / "read in one pass from the default branch's commit"

**Location:** `scripts/lib/dev-cycle-read.sh:268-271`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers first-unfenced-copy selection, later duplicates ignored, fenced copies skipped, values including the key prefix, trailing CR dropped, a single awk pass over main's blob; does not establish case-insensitive keys (the regex is case-sensitive, so `status:` is not read — consistent with the comment's quoted spellings).

```
    { sub(/\r$/, "") }
    fence($0) { next }
    match($0, /^(Status|Branch|Policy|Paths|Asked|Dispatched):/) {
      k = tolower(substr($0, 1, RLENGTH - 1)); if (!(k in got)) { got[k] = 1; kv[++nk] = k "\t" $0 }
    }
```
(`scripts/lib/dev-cycle-read.sh:287-291`; excerpt ends :291; enclosing brief_fields() continues to :300 — read). Test 66 reads `status=[Status: open]` (the CRLF line, after a fenced `Status: done`) and `branch=[Branch: feat/f]` (not the later `Branch: second`) (`test/scripts/dev-cycle.bats:1223-1226`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:268-300`, `test/scripts/dev-cycle.bats:1207-1226`, `$FC2/bats-full.txt`

---

## Claim 16: "Sets BRIEF[status] ... BRIEF[dispatched] (a key with no such line stays unset) and empties BRIEF_ODD. A file FENCE_AWK refuses sets no key and returns 1, with BRIEF_ODD "odd N WHY" (line N; WHY for oddwhy) or "unbalanced N""

**Location:** `scripts/lib/dev-cycle-read.sh:272-276`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the success path (keys set, absent keys unset, BRIEF_ODD empty) and both refusal forms with `${#BRIEF[@]}` 0 and status 1; does not establish the return value when `git cat-file` itself fails (outside the stated precondition; see Claim 18).

`BRIEF=(); BRIEF_ODD=""` (`:283`) and `odd\ *|unbalanced\ *) BRIEF=(); BRIEF_ODD="$l"; return 1 ;;` (`:296`). Tests assert `refused [odd 2 fence] 0`, `refused [unbalanced 2] 0` and `status=[Status: open] branch=[unset] odd=[]` (`test/scripts/dev-cycle.bats:1231`, `:1238-1239`), and `refused [odd 2 nul] 0` (`:1187-1189`); all pass in E1.

**Evidence:** `scripts/lib/dev-cycle-read.sh:272-300`, `test/scripts/dev-cycle.bats:1227-1240`, `$FC2/bats-full.txt`

---

## Claim 17: "a NUL byte is refused too, so each value is the line as stored"

**Location:** `scripts/lib/dev-cycle-read.sh:276-277`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers byte fidelity of values through awk, `$(...)` and the `read -r` loop for trailing spaces, embedded TAB, UTF-8 and invalid bytes (0xff) and backslashes, and that a NUL refuses rather than being dropped; "as stored" is minus the one trailing CR the comment states at :271, and does not establish fidelity under non-mawk awks.

E7 `od -c` of the values: `Status: open␠␠` kept its two trailing spaces, `Branch: a\tb 303 251 377 \ x` kept TAB, é, 0xff and the backslash, `Policy: p` lost only the trailing CR. Contrast at c8435580 (no NUL check): `Status: op\0en` became `ok ... open` (E2), the R1 defect. Iteration 1 flagged the earlier "whole" wording as contradicted by R1; at 2da477b7 the contradiction is gone because no NUL line survives FENCE_AWK.

**Evidence:** `scripts/lib/dev-cycle-read.sh:276-277`, `scripts/lib/dev-cycle-read.sh:286-299`, `$FC2/p3.txt`, `$FC2/bats-old-c8435580.txt`

---

## Claim 18: "The caller has checked main_by_name and that the path is a blob on main (main_entry), and calls it in its own shell: it sets globals."

**Location:** `scripts/lib/dev-cycle-read.sh:277-279`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the only in-repo caller (check_brief), which checks main_by_name (:312), runs main_entry and proceeds only on `blob` (:320-327), then calls `if ! brief_fields "$a"` in its own shell (:328); does not establish what happens if a future caller skips the preconditions (a failed `git cat-file` inside `if !` leaves set -e inactive, so brief_fields would return 0 with no keys).

```
  e="$(main_entry "$a")"
  case "$e" in
    absent) echo "ok $a new"; return ;;
    blob) ;;
```
(`scripts/lib/dev-cycle-read.sh:320-323`; excerpt ends :323; enclosing check_brief() continues past :345 — read through the Status test at :335-338). `rg -n brief_fields` finds no other caller outside tests.

**Evidence:** `scripts/lib/dev-cycle-read.sh:309-338`

---

## Claim 19: "The whole blob is read (no early exit: SIGPIPE under pipefail)."

**Location:** `scripts/lib/dev-cycle-read.sh:284`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the absence of `exit` in brief_fields' awk program and in FENCE_AWK; does not measure the cost of reading large blobs.

The program is FENCE_AWK (`scripts/lib/dev-cycle-read.sh:186-229`) plus the rules at `:287-292`; neither contains an `exit` statement (paraphrased — no quote available because the claim covers absence of code: no `exit` token in either awk text).

**Evidence:** `scripts/lib/dev-cycle-read.sh:186-229`, `scripts/lib/dev-cycle-read.sh:284-292`

---

## Claim 20: check_brief comment: "its Status line from brief_fields, which must be exactly "Status: open|done|dropped". A brief FENCE_AWK refuses ... is not read at all, and neither is one stored as anything but a regular file under plain directories (main_entry). "new" when the default branch has no file at that path"

**Location:** `scripts/lib/dev-cycle-read.sh:301-305`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exact-Status test, refusals, a symlinked briefs dir on main, and "new" for an absent path; does not establish the closed/ handling or the commit lookup after :338 (unchanged).

`if [[ ! "$st" =~ ^Status:\ (open|done|dropped)$ ]]; then echo "skip $a: its first Status: line is not exactly ..."` (`scripts/lib/dev-cycle-read.sh:336-337`). E8: with `docs/working/briefs` a symlink on main and a plain dir in the working tree, HEAD prints `skip docs/working/briefs/2026-01-01-d.md: docs/working/briefs is not a directory on the default branch`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:301-338`, `$FC2/p4.txt`, `$FC2/bats-full.txt`

---

## Claim 21: check_answer comment: "One answer, from docs/working/questions.md and questions-archive.md on the default branch's commit, never the working tree ... A file stored as anything but a regular file under plain directories there is not read (main_entry). It reads only git objects, so it needs no ROOT_REAL and adds nothing to SKIPPED."

**Location:** `scripts/lib/dev-cycle-read.sh:528-533`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the git-only reads, no need_root, SKIPPED left at 0 with a symlinked archive on main, and from a subdirectory; does not establish the "plan D8" rationale (design intent, not checked).

Test 63 expects `skipped=0` (`test/scripts/dev-cycle.bats:1171`). E10, same repo with ROOT_REAL set: main's working-tree reader prints `skip Q-1: docs/working/questions-archive.md is not a plain file or directory, ...` and `skipped=1`; c8435580/HEAD print `... is not a regular file on the default branch ...` and `skipped=0`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:528-560`, `test/scripts/dev-cycle.bats:1160-1172`, `$FC2/a4.txt`, `$FC2/bats-full.txt`

---

## Claim 22: "it reads `questions.md` and, once step 1 has archived an entry, `questions-archive.md`, both from the default branch's commit (an answer recorded only in the working tree reads `open`, or no such entry, until it lands)"

**Location:** `skills/dev-cycle/SKILL.md:292-293`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the parenthetical (Verified by test 60) and that both files are read from main; the imprecision is the retained "once step 1 has archived an entry" clause, and this does not establish when the cycle's archive commit reaches main.

The new parenthetical is right (Claim 2). The sentence's timing is now loose: check_answer reads the archive on main every time it exists there (`for f in docs/working/questions.md docs/working/questions-archive.md`, `scripts/lib/dev-cycle-read.sh:538`), so an entry that step 1 archives in this cycle's working tree is read from main's questions.md until the cycle's change lands, and from main's archive only afterwards. The precise version: "it reads `questions.md` and `questions-archive.md` from the default branch's commit (an entry step 1 archives this cycle is read from main's `questions.md` until that change lands; an answer recorded only in the working tree reads `open`, or no such entry, until it lands)". The skill says the cycle's files land at step 7 ("The briefs land with step 7", `skills/dev-cycle/SKILL.md:349-350`).

**Evidence:** `skills/dev-cycle/SKILL.md:288-296`, `scripts/lib/dev-cycle-read.sh:538-557`, `test/scripts/dev-cycle.bats:1118-1135`, `$FC2/bats-full.txt`

---

## Claim 23: Test name "check_answer reads git only: no ROOT_REAL needed, SKIPPED untouched, skip without main by name" (and its comment "A symlinked archive on main: the working-tree reader added it to SKIPPED."); 2da477b7: "A4: the SKIPPED test now has a symlinked archive on main, so it fails against the old working-tree reader."

**Location:** `test/scripts/dev-cycle.bats:1160-1172`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test failing against main's reader and the SKIPPED assertion biting on its own when the ROOT_REAL exit is removed from the picture; does not establish anything about c8435580 (the test passes there, as expected, since c8435580 already read git).

E3: against main's lib the test fails at `[ "$status" -eq 0 ]` with `dev-cycle-read.sh: ROOT_REAL is not set` (the old reader called need_root). E10 isolates the SKIPPED leg: with ROOT_REAL set, the old reader gives `skipped=1`, so `skipped=0` in the expected output (`test/scripts/dev-cycle.bats:1171`) would also fail. The setup line is `ln -s questions.md docs/working/questions-archive.md && git add -A && git commit -qm archive-link` (`test/scripts/dev-cycle.bats:1164`).

**Evidence:** `test/scripts/dev-cycle.bats:1160-1172`, `$FC2/bats-old-main.txt`, `$FC2/a4.txt`, `$FC2/bats-full.txt`

---

## Claim 24: Test name "a NUL byte refuses a brief or a questions file, never dropped into a value; main_entry fails closed"

**Location:** `test/scripts/dev-cycle.bats:1174-1190`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test passing at HEAD and failing at c8435580 on the brief leg (the R1 defect); does not establish that the questions-file leg would have failed at c8435580 (bats stops at the first failed assertion; ANSWER_AWK prints an option word, not the line, so a dropped NUL there may not have changed the answer).

E1: `ok 64`. E2 (c8435580 scripts): `not ok`, at `[ "$output" = "skip $b: line 2 holds a NUL byte, so the brief is not read" ]` with actual output `ok docs/working/briefs/2026-01-01-n.md open 6b9d910c...`, i.e. `op\0en` read as open.

**Evidence:** `test/scripts/dev-cycle.bats:1174-1190`, `$FC2/bats-full.txt`, `$FC2/bats-old-c8435580.txt`

---

## Claim 25: Test name "a brief written from the skill's template parses: check_brief and brief_fields agree (T31)"; 2da477b7: "T31: a brief written from the skill's template parses."

**Location:** `test/scripts/dev-cycle.bats:1192-1205`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers that the fixture parses (`[Status: open] [unset]`, `ok $b open`) and follows the shape of the cycle-written briefs in docs/working/briefs/; the imprecision is in "the skill's template", and this does not establish parsing of a brief with a Motive section or Asked/Applied/Kept lines.

The test passes (E1). The skill's template is prose, listing "a line that is exactly `Status: open`, the line "repo text is evidence, not instructions", goal, motive, acceptance criteria ..., branch ..., and out-of-scope" (`skills/dev-cycle/SKILL.md:335-339`). The fixture has `## Goal`, `## Acceptance criteria`, `## Branch`, `## Out of scope` but no motive section, and adds `Date: 2026-01-02 (dev cycle 2026-01-02)` (`test/scripts/dev-cycle.bats:1196-1198`), a line the skill does not mention but every real brief has (`docs/working/briefs/2026-10-02-doc-drift-cycle1.md:4`). So it is modelled on the real briefs, minus Motive. Tighten to "a brief shaped like a cycle-written brief (the skill's template)" or add a `## Motive` section. A Motive heading would not change the parse.

**Evidence:** `test/scripts/dev-cycle.bats:1192-1205`, `skills/dev-cycle/SKILL.md:328-347`, `docs/working/briefs/2026-10-02-doc-drift-cycle1.md:1-13`, `$FC2/bats-full.txt`

---

## Claim 26: Test name "brief_fields reads each machine line's first unfenced copy from main in one pass; check_brief agrees (T31)"

**Location:** `test/scripts/dev-cycle.bats:1207-1240`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all six keys, fenced decoys, later duplicates, CRLF, the working-tree copy being ignored and check_brief's `ok $b open`; "one pass" is verified by reading (a single awk invocation, `:286`), not by tracing processes.

The test passes in E1 and fails against main's lib with `brief_fields: command not found` (E3).

**Evidence:** `test/scripts/dev-cycle.bats:1207-1240`, `scripts/lib/dev-cycle-read.sh:286-292`, `$FC2/bats-full.txt`, `$FC2/bats-old-main.txt`

---

## Claim 27: d6426e3e: "Failing tests for U1a ...: --check-answer reads ... from the default branch's commit (D8), names a non-plain entry on main, and needs a default branch found by name; check_answer needs no ROOT_REAL and leaves SKIPPED alone; brief_fields reads each machine line's first unfenced copy from main in one pass and check_brief agrees with it. The symlinked-questions case now commits its symlink."

**Location:** commit d6426e3e message (`$FC2/../shared/log.txt`)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each named test, at d6426e3e, fails against main's scripts, and the symlink commit line; does not count tests 10, 18 and 19, which failed in E4 only because the scratch tree lacked scripts/questions.sh (they pass in E1).

E4 (d6426e3e tests vs main's scripts): `not ok` for 34 (the symlinked-questions case), 54 (sourcing: `main_entry`, `brief_fields`, `BRIEF` missing), 60, 61, 62, 63 and 64 (brief_fields). The symlink commit is `git add -A && git commit -qm link` (`test/scripts/dev-cycle.bats:652`).

**Evidence:** `test/scripts/dev-cycle.bats:650-655`, `$FC2/bats-d6-vs-main.txt`

---

## Claim 28: c8435580: check_answer reads from main "never the working tree"; "skips without a default branch found by name, reads only git objects (no ROOT_REAL, nothing added to SKIPPED), and dev-cycle.sh --check-answer exits 1 without such a branch"; main_entry "from one `ls-tree -t --full-tree` call, so no reader takes a symlink's target text or reads through a symlinked directory on main"; brief_fields "a refused file sets none and returns 1 with BRIEF_ODD. check_brief now reads its Status line through it"; "check_brief also skips a brief whose directory is not a directory on main (before, ls-tree printed nothing and it read as "new")"; Notes: a working-tree-only answer "reads ... as open and lists it in the final message; that fails closed."

**Location:** commit c8435580 message (`$FC2/../shared/log.txt`)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed behavior at c8435580 and HEAD, including the before/after symlinked-dir case; does not establish the "installed image copy is unchanged until a release" note (deployment state, outside the repo).

E8: main's check_brief prints `ok docs/working/briefs/2026-01-01-d.md new` for a brief under a symlinked dir on main, and the old form `git ls-tree <main> -- docs/working/briefs/2026-01-01-d.md` prints nothing (exit 0); c8435580 prints `skip ...: docs/working/briefs is not a directory on the default branch`. E2: tests 63, 65 and 66 pass at c8435580. The "fails closed" note matches the skill: `open` → "leave the ID, and list it in the final message with its brief" (`skills/dev-cycle/SKILL.md:294-296`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:256-300`, `skills/dev-cycle/SKILL.md:289-296`, `$FC2/p4.txt`, `$FC2/bats-old-c8435580.txt`

---

## Claim 29: 2da477b7 R1/A1 and A2: "brief_fields read awk's output through $(...), which drops NUL bytes, so "Status: op<NUL>en" read as open ... FENCE_AWK now refuses any line holding a NUL byte ("holds a NUL byte"), so every reader skips such a file and no value loses a byte." / "main_entry printed "absent" when ls-tree failed, which check_brief turned into "ok ... new". It now prints "error" without a default branch found by name or on a failed ls-tree, and both callers skip." / Override rows "A3 (ls-tree cost, measured 49 entries, Won't-Fix)"

**Location:** commit 2da477b7 message (`$FC2/../shared/log.txt`)
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** "every reader" covers the lib's two FENCE_AWK readers (brief_fields/check_brief and check_answer, the only `FENCE_AWK` uses per `rg`); it does not cover the digest's questions path, which goes through questions.sh (`scripts/dev-cycle.sh:329-361`), not FENCE_AWK, nor awks other than mawk.

R1: reproduced at c8435580 (E2, `ok ... open`); refused at HEAD (E1, E7). A2: c8435580's check_brief with MAIN_SHA `0000…0` printed `ok docs/working/briefs/2026-01-01-a.md new` (E9 `$FC2/p6.txt`); HEAD prints the two `could not be read` skips (`$FC2/p5.txt`). "49 entries" re-measured: `git ls-tree -t --full-tree <main> -- docs docs/working docs/working/questions.md | wc -l` = `49` (E6). The two override rows are in the diff of `docs/reviews/override-log.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:216`, `scripts/lib/dev-cycle-read.sh:259-261`, `scripts/lib/dev-cycle-read.sh:325`, `scripts/lib/dev-cycle-read.sh:544`, `$FC2/bats-old-c8435580.txt`, `$FC2/p5.txt`, `$FC2/p6.txt`, `$FC2/lstree.txt`

---

## Claim 30: 2da477b7: "Comments: the lib header no longer names a suite that does not exist yet; the default-branch comment names check_answer; the help and SKILL.md say a working-tree-only answer reads open or no such entry." / Notes: "The NUL refusal is in FENCE_AWK, so dev-cycle.sh's --check-brief and --check-answer refuse such files too (help text updated)."

**Location:** commit 2da477b7 message (`$FC2/../shared/log.txt`)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three comment changes and the CLI refusals through dev-cycle.sh; does not re-verify the accuracy of the SKILL.md sentence as a whole (see Claim 22).

Header: Claim 5. Default-branch comment: `# The default branch, set by resolve_main (below). check_brief, check_branch` / `# and check_answer read its commit` (`scripts/lib/dev-cycle-read.sh:242-243`). Help: `scripts/dev-cycle.sh:57-59`; SKILL: `skills/dev-cycle/SKILL.md:292-293`. The CLI refusals: test 64 runs both through `bash "$DC"` and passes (E1); help lists "a NUL byte" at `scripts/dev-cycle.sh:42` and `:68`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:10-12`, `scripts/lib/dev-cycle-read.sh:242-244`, `scripts/dev-cycle.sh:42`, `scripts/dev-cycle.sh:57-59`, `scripts/dev-cycle.sh:68`, `test/scripts/dev-cycle.bats:1178-1183`, `$FC2/bats-full.txt`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 9** (`scripts/lib/dev-cycle-read.sh:174-176`): the NUL (and CR, BOM) atoms sit after "outside a fence," but fence() refuses them inside fences too (E7). Say "anywhere in the file".
- **Claim 22** (`skills/dev-cycle/SKILL.md:292-293`): "once step 1 has archived an entry, questions-archive.md" no longer matches when the archive is read. An entry archived this cycle is read from main's questions.md until the cycle lands, and the archive on main is read whenever it exists.
- **Claim 25** (`test/scripts/dev-cycle.bats:1192`, and 2da477b7's T31 bullet): the fixture follows the real cycle briefs (it has a Date line) but has no Motive section from the skill's template. Add `## Motive`, or call it "a cycle-written brief's shape".

### Unverifiable
(none; non-mawk awk behavior is recorded as residue in Claims 10 and 29, not as a verdict)

---

## Goal-Alignment Note

- **Goal served:** final confirming fact-check of U1a at 2da477b7. All three iteration-1 fixes (R1/A1 NUL, A2 fail-closed main_entry, A4 biting SKIPPED test) were re-verified by execution, including counter-runs against c8435580 and main. The brief_fields "line as stored" comment that iteration 1 flagged is now accurate (Claim 17).
- **Out of reach:** gawk, busybox and one-true-awk are not installed, so the `"\0"` literal was verified under mawk only.
- **Escalate:** (low) portability, to api-consistency-reviewer / the orchestrator. `scripts/lib/dev-cycle-read.sh:216` relies on `"\0"` being a one-byte string. If the lib ever runs under an awk with C-string literals (BWK/macOS awk, busybox), `"\0"` would likely be empty. Since `index(s, "")` returns 1 in mawk and plausibly in those awks too, every non-empty line could then be refused as "holds a NUL byte" (fail closed, but every brief and answer skipped). This comes from static reasoning and was not executed. It only matters if the lib is meant to be portable beyond mawk/gawk.
- **Escalate:** (low) error handling, to security-reviewer. If `git cat-file` fails, `brief_fields` (`scripts/lib/dev-cycle-read.sh:286`) returns 0 with no keys when it is called under `if !`, because set -e is suspended there. check_brief then skips ("its first Status: line is not exactly ..."), which is fail-closed. A U1b caller that reads `BRIEF[...]` without the main_entry precondition would see all keys unset, not a refusal.
