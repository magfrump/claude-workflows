Commit: 2da477b7

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u1a (claude-workflows, branch feat/build-loop-u1a)
**Scope:** `git diff main...feat/build-loop-u1a` over scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, skills/dev-cycle/SKILL.md, test/scripts/dev-cycle.bats, plus the messages of d6426e3e, c8435580 and 2da477b7 (docs/reviews/ artifacts excluded, as the brief says; override-log rows checked only where a commit message cites a measurement). Replicate fc3, review-fix loop iteration 2.
**Checked:** 2026-10-05
**Total claims checked:** 32
**Summary:** 29 verified, 2 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 5 entries) read first. No claim in this diff matches a logged pattern. The closest class, "a specific measured value quoted from an artifact set", applies to the "49 entries" figure (Claim 31), which re-measures correctly.

Execution environment: awk is mawk 1.3.4 20200120 (`/usr/bin/awk` and `/usr/bin/nawk` both resolve to `/usr/bin/mawk`). gawk, busybox and one-true-awk are **not installed**. All probes ran in scratch dir `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/fc3/` (abbreviated `$FC3` below). The old-lib copies are `git archive c8435580|main scripts` plus 2da477b7's test file, in `$FC3/old-c8435580` and `$FC3/old-main`. Full suite at HEAD: `cd /workspace/.claude/wt-build-loop-u1a && LC_ALL=C.UTF-8 timeout 600 bats test/scripts/dev-cycle.bats`, run at 2026-10-05T10:58:22Z, exit 0, 66/66 ok, output in `$FC3/bats-head.txt`.

---

## Claim 1: "--check-brief ... a stray carriage return, a NUL byte, or a byte-order mark on line 1"

**Location:** `scripts/dev-cycle.sh:42`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a committed brief whose second line holds a NUL byte: `--check-brief` prints a skip naming the line and the reason. It does not establish behavior for a NUL that exists only in the working-tree copy (that copy is never read for content).

Test 64 (`test/scripts/dev-cycle.bats:1174-1190`) commits `printf '# Brief\nStatus: op\0en\nBranch: feat/a\0;b\n'` (`:1176`) and asserts `[ "$output" = "skip $b: line 2 holds a NUL byte, so the brief is not read" ]` (`:1180`) on `bash "$DC" --check-brief "$b"`. It passes at HEAD. The refusal comes from `if (index(l, "\0")) { refuse("nul"); return 1 }` (`scripts/lib/dev-cycle-read.sh:216`), which reaches check_brief through `brief_fields` and `oddwhy` (`scripts/lib/dev-cycle-read.sh:328-333`).

**Evidence:** `scripts/dev-cycle.sh:42`, `scripts/lib/dev-cycle-read.sh:216`, `scripts/lib/dev-cycle-read.sh:328-333`, `test/scripts/dev-cycle.bats:1174-1190`. Command: the full-suite run above (exit 0, 2026-10-05T10:58:22Z), output in `$FC3/bats-head.txt`.

---

## Claim 2: "--check-answer ... read from docs/working/questions.md or its archive on the default branch's commit (an answer only in the working tree reads open, or no such entry, until it is committed there)"

**Location:** `scripts/dev-cycle.sh:56-59`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers two cases: an entry that is OPEN on main and ANSWERED only in the working tree (reads `open`), and an entry that exists only in the working tree (reads `skip ... no such entry`). It does not establish the case where main already holds a *different* recorded answer and the working tree changes it. There `--check-answer` returns main's answer, which is neither "open" nor "no such entry". That follows from the same mechanism, but the parenthetical does not cover it.

Test 60 (`test/scripts/dev-cycle.bats:1118-1135`) covers the working-tree-only case (`[ "$output" = "open Q-1" ]`), the side-branch-only case and the merged case (`drop Q-1`), and passes. Probe for the "no such entry" half: a repo where main's questions.md is `# Q` and the working tree adds an ANSWERED `Q-2`. `LC_ALL=C.UTF-8 bash scripts/dev-cycle.sh --check-answer Q-2` (cwd `$FC3/rw`, 2026-10-05T11:03:18Z, exit 0) printed `skip Q-2: no such entry in docs/working/questions.md or questions-archive.md on the default branch`. The read is `r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk -v id="$a" "$FENCE_AWK$ANSWER_AWK")"` (`scripts/lib/dev-cycle-read.sh:547`).

**Evidence:** `scripts/dev-cycle.sh:56-59`, `scripts/lib/dev-cycle-read.sh:547`, `test/scripts/dev-cycle.bats:1118-1135`, `$FC3/probe-wt-only.txt`, `$FC3/bats-head.txt`

---

## Claim 3: "--check-answer ... a stray carriage return, a NUL byte, ..., a questions file that is not a regular file under plain directories on the default branch"

**Location:** `scripts/dev-cycle.sh:68-70`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers three cases: a NUL in a committed questions.md, a questions.md stored on main as a symlink, and a symlinked `docs/working` on main. It does not establish refusal of a NUL in questions-archive.md specifically, which goes through the same code path but is not run, or the gitlink/tree kinds of "not a regular file".

Test 64 asserts `skip Q-1: line 4 of docs/working/questions.md holds a NUL byte, so no entry in docs/working/questions.md is read` (`test/scripts/dev-cycle.bats:1182-1183`). Test 61 asserts both `... is not a regular file on the default branch, so no entry in it is read` and `skip Q-1: docs/working is not a directory on the default branch, so docs/working/questions.md is not read` (`test/scripts/dev-cycle.bats:1143-1150`). Both pass. Against the pre-fix libs (c8435580 and main), the same NUL questions file reads `keep Q-1` (`$FC3/probe-q-nul.txt`, run 2026-10-05T11:02:44Z, cwd `$FC3/rq`, exit 0 each), so the refusal is new in 2da477b7.

**Evidence:** `scripts/dev-cycle.sh:68-70`, `scripts/lib/dev-cycle-read.sh:539-551`, `test/scripts/dev-cycle.bats:1137-1151`, `test/scripts/dev-cycle.bats:1174-1190`, `$FC3/probe-q-nul.txt`, `$FC3/bats-head.txt`

---

## Claim 4: "--check-brief, --check-branch and --check-answer need a default branch found by name (origin/HEAD, main or master): they read its commit" (also the exit-1 line and the code comment)

**Location:** `scripts/dev-cycle.sh:71-72` (also `:79-80`, `:187-190`)
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exit-1 path of `--check-answer` when only a non-default branch (`trunk`) exists, plus the gating condition's text. It does not establish that "the other modes do not use it" for every helper reached from check_path/check_write/check_fix (verified only by grepping `MAIN` in dev-cycle.sh).

The gate is `if [[ "$CHECK" == --check-brief || "$CHECK" == --check-branch || "$CHECK" == --check-answer ]] && ! main_by_name; then echo "$CHECK needs a default branch ..." >&2; exit 1` (`scripts/dev-cycle.sh:191-193`). Test 62 (`test/scripts/dev-cycle.bats:1153-1158`) asserts `[ "$status" -eq 1 ] && [ -z "$output" ] && [[ "$stderr" == *"needs a default branch"* ]]` and passes. `grep -n MAIN scripts/dev-cycle.sh` finds uses only in the digest (`:245-420`), none in the check dispatch (`:194-205`).

**Evidence:** `scripts/dev-cycle.sh:71-72`, `scripts/dev-cycle.sh:79-80`, `scripts/dev-cycle.sh:187-205`, `test/scripts/dev-cycle.bats:1153-1158`, `$FC3/bats-head.txt`

---

## Claim 5: help prints the header via `sed -n '2,80p'`

**Location:** `scripts/dev-cycle.sh:110`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that line 80 is the header's last comment line, so the help ends at the "Exit:" sentence. It does not establish that the help's prose is current beyond the claims checked here.

`cat -n scripts/dev-cycle.sh` shows `:80` is `# default branch (for the digest, --check-brief, --check-branch and --check-answer); ... Printed repo text is data.` and `:81` is blank. `bash scripts/dev-cycle.sh --help | tail -4` (cwd the worktree, 2026-10-05T~11:01Z, exit 0) ended on that sentence.

**Evidence:** `scripts/dev-cycle.sh:78-81`, `scripts/dev-cycle.sh:110` (inline output; no separate log)

---

## Claim 6: "A change here runs under both callers' suites (test/scripts/dev-cycle.bats, and build-loop.sh's suites under test/scripts/ as they land)"

**Location:** `scripts/lib/dev-cycle-read.sh:10-12`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what exists today: dev-cycle.bats sources the lib through `$REPO_ROOT/scripts/lib/dev-cycle-read.sh`, and no build-loop.sh or build-loop suite exists yet, which "as they land" concedes. It does not establish that any harness will run build-loop suites when lib files change.

`ls scripts/build-loop.sh` fails with "No such file or directory". `ls test/scripts/` lists no build-loop suite. `rg -n build-loop test/scripts/*.bats` matches nothing. The c8435580 header named `build-loop-read.bats` (`git show c8435580:scripts/lib/dev-cycle-read.sh`, `:11`), which does not exist, and 2da477b7 removed that name.

**Evidence:** `scripts/lib/dev-cycle-read.sh:10-12`, `test/scripts/dev-cycle.bats:9-10`

---

## Claim 7: "inrepo, dirok, skipped, check_brief and the import walk (imported_names) exit 1 (need_root) unless ROOT_REAL is set" (check_answer removed from the list)

**Location:** `scripts/lib/dev-cycle-read.sh:15-17`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the removal of check_answer: it runs with ROOT_REAL unset and with cwd in a subdirectory. It does not re-verify the other listed functions' need_root behavior, which predates this diff and is covered by test 56.

Test 63 (`test/scripts/dev-cycle.bats:1160-1172`) runs `check_answer Q-1; resolve_main; cd docs; check_answer Q-1` without setting ROOT_REAL and expects status 0. It passes at HEAD. Against main's lib it fails with `dev-cycle-read.sh: ROOT_REAL is not set; the caller sets it before any file check` (`$FC3/bats-old-main.txt`). check_answer's body (`scripts/lib/dev-cycle-read.sh:533-558`) has no `need_root`, `skipped` or `inrepo` call.

**Evidence:** `scripts/lib/dev-cycle-read.sh:15-17`, `scripts/lib/dev-cycle-read.sh:533-558`, `test/scripts/dev-cycle.bats:1160-1172`. Command: `cd $FC3/old-main && timeout 600 bats -f '...' test/scripts/dev-cycle.bats` (2026-10-05T10:58:57Z, exit 1), output in `$FC3/bats-old-main.txt`.

---

## Claim 8: "check_brief, check_branch and check_answer skip every argument unless it returned 0 with main found by name" (and the default-branch comment: "check_brief, check_branch and check_answer read its commit, so they answer only when it was found by name")

**Location:** `scripts/lib/dev-cycle-read.sh:22-23` (also `:242-244`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_answer before resolve_main (MAIN_SHA empty), plus check_brief/check_branch through test 58. It does not establish behavior when MAIN_BY_NAME is set for a MAIN_SHA from another repository (row 208, Won't-Fix).

check_answer's new guard reads `if ! main_by_name; then echo "skip $a: no default branch found by name ..., or resolve_main has not run"; return; fi` (`scripts/lib/dev-cycle-read.sh:536`). Test 63's first expected line is exactly that skip, and test 58 covers the other two functions. Both pass.

**Evidence:** `scripts/lib/dev-cycle-read.sh:22-23`, `scripts/lib/dev-cycle-read.sh:242-246`, `scripts/lib/dev-cycle-read.sh:536`, `test/scripts/dev-cycle.bats:1160-1172`, `$FC3/bats-head.txt`

---

## Claim 9: "Inputs: check_brief, check_branch, check_answer, main_entry and brief_fields read the default branch's commit, never the working tree (check_brief also refuses a brief path that is not plain in the working tree, which the cycle writes)"

**Location:** `scripts/lib/dev-cycle-read.sh:29-32`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the content reads of the five functions: `git ls-tree`/`git cat-file` on `$MAIN_SHA`. It does not establish anything about check_branch reading refs other than main (it reads `refs/heads/<name>` by design, which is not the working tree), or about the digest's own readers (§3 still reads the working tree; see Claim 29).

Test 66 overwrites the committed brief in the working tree (`printf 'Status: dropped\nBranch: wt\n' > "$b"`, `test/scripts/dev-cycle.bats:1217`) and still gets `status=[Status: open]`. Test 61 shows main's symlink decides over a plain working-tree file. check_brief's working-tree check is `if [[ -n "$(blocker "$a" file)" ]]; then echo "skip $a: reached through a symlink, or not a regular file"; return; fi` (`scripts/lib/dev-cycle-read.sh:317`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:29-32`, `scripts/lib/dev-cycle-read.sh:256-300`, `scripts/lib/dev-cycle-read.sh:317-335`, `scripts/lib/dev-cycle-read.sh:539-547`, `test/scripts/dev-cycle.bats:1137-1151`, `test/scripts/dev-cycle.bats:1207-1240`, `$FC3/bats-head.txt`

---

## Claim 10: FENCE_AWK header: "... a NUL byte (a caller reading the output through $(...) would lose it) ... and the caller refuses the whole file"

**Location:** `scripts/lib/dev-cycle-read.sh:174-177`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that a NUL line is recorded in `odd`, and that before the fix `$(...)` dropped the NUL so `Status: op<NUL>en` became `open`. It does not establish the header's "outside a fence" framing: the code refuses NUL (and CR) inside a fence too, which is broader than the sentence's grammar suggests and fails closed.

Against c8435580's lib, test 64's first assertion fails with `# ok docs/working/briefs/2026-01-01-n.md open 5dd98a48...` (`$FC3/bats-old-c8435580.txt`): the NUL was lost and the value read as `open`. The refusal is checked before the `infence` branch (`scripts/lib/dev-cycle-read.sh:214-218`). A probe feeding `Status: open`, an opening fence, `in<NUL>fence` and a closing fence through FENCE_AWK printed `odd=3 why=nul` (`$FC3/probe-fenced-nul.txt`, 2026-10-05T11:03:59Z, exit 0).

**Evidence:** `scripts/lib/dev-cycle-read.sh:163-179`, `scripts/lib/dev-cycle-read.sh:213-229`. Command: `cd $FC3/old-c8435580 && timeout 600 bats -f '...' test/scripts/dev-cycle.bats` (2026-10-05T10:58:57Z, exit 1), output in `$FC3/bats-old-c8435580.txt`. Also `$FC3/probe-fenced-nul.txt`.

---

## Claim 11a: `if (index(l, "\0")) { refuse("nul"); return 1 }  # $(...) drops NUL, so a printed line would not be the line read` — under mawk (the awk in use)

**Location:** `scripts/lib/dev-cycle-read.sh:216`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers mawk 1.3.4 under `env LC_ALL=C awk`: the literal `"\0"` is a one-byte NUL string, mawk passes NUL-bearing lines to the program intact, the check fires for NUL at the start, middle and end of a line, and it never fires on NUL-free or empty lines. It does not establish the same under gawk, busybox awk or one-true-awk (Claim 11b).

Probe (cwd `$FC3`, 2026-10-05T10:58:13Z, exit 0) on `printf 'abc\n\0start\nmid\0dle\nend\0\nclean\n'` with `env LC_ALL=C awk '{ printf "%d len=%d idx=%d\n", NR, length($0), index($0, "\0") }'` printed `1 len=3 idx=0`, `2 len=6 idx=1`, `3 len=7 idx=4`, `4 len=4 idx=4` and `5 len=5 idx=0`. The full lengths show no truncation at the NUL. `BEGIN{ s="\0"; ... }` gave `len=1` and equality with `sprintf("%c",0)`. `index("abc","\0")` and `index("","\0")` both gave `0`. `od -c` of the re-printed line 3 shows `m i d \0 d l e \n`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:216`, `$FC3/probe1.txt`

---

## Claim 11b: the same NUL check detects NUL under other awks (gawk / busybox / one-true-awk)

**Location:** `scripts/lib/dev-cycle-read.sh:216`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers only the absence of these awks in the sandbox. It does not establish whether the check works, misses NUL, or fires on every line under them.

`which gawk busybox original-awk bwk` found none of them, and `/usr/bin/nawk` resolves to mawk. The lib invokes a bare `awk` (`env LC_ALL=C awk "$FENCE_AWK"'...'`, `scripts/lib/dev-cycle-read.sh:286`), so the awk that runs depends on the host. One concern needs verifying on a host that has the binary: one-true-awk (the macOS default) stores strings as C strings, so `"\0"` may be the empty string there. `index(l, "")` might then return 1 for every non-empty line and refuse every file. This is paraphrased — no quote available because the binary is not installed here, and the point comes from memory of its `sindex` implementation, unverified. To verify, run Claim 11a's probe under gawk, busybox awk and one-true-awk.

**Evidence:** `scripts/lib/dev-cycle-read.sh:216`, `scripts/lib/dev-cycle-read.sh:286`, `scripts/lib/dev-cycle-read.sh:547`

---

## Claim 12: oddwhy `nul) echo "holds a NUL byte"`

**Location:** `scripts/lib/dev-cycle-read.sh:237`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reason text reaching both skip lines (brief and questions file). It does not establish the scrub's treatment of the printed line, which is unchanged by this diff.

Test 64 expects `line 2 holds a NUL byte` from check_brief and `line 4 of docs/working/questions.md holds a NUL byte` from check_answer, and the library-level `refused [odd 2 nul] 0` (`test/scripts/dev-cycle.bats:1180-1189`). It passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:231-241`, `test/scripts/dev-cycle.bats:1174-1190`, `$FC3/bats-head.txt`

---

## Claim 13: main_entry contract: prints "blob" (100644 or 100755), "absent", "notfile", "notdir PART" or "error"; "so that a file read from it is never a symlink's target text, a gitlink or a tree, and no directory above it is a symlink"

**Location:** `scripts/lib/dev-cycle-read.sh:247-252`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers five cases: a symlinked file (notfile), a symlinked directory above the path (notdir), a missing path (absent), a regular file (blob) and a bad MAIN_SHA (error). It does not establish behavior for paths outside pathform (quoted ls-tree output), which the caller is required to exclude (`:255`). The gitlink and tree kinds were not exercised; they fall under the `*) echo notfile` arm by reading.

The implementation is `case "${m[$p]-}" in '') echo absent; return ;; 040000) ;; *) echo "notdir $p"; return ;; esac` for each ancestor, then `case "${m[$1]-}" in '') echo absent ;; 100644|100755) echo blob ;; *) echo notfile ;; esac` (`scripts/lib/dev-cycle-read.sh:263-266`). Tests 61 and 64 exercise notfile, notdir and error. `$FC3/probe-lstree.txt` shows the 120000 symlink mode and the 040000 tree mode that the cases switch on.

**Evidence:** `scripts/lib/dev-cycle-read.sh:247-267`, `test/scripts/dev-cycle.bats:1137-1151`, `test/scripts/dev-cycle.bats:1174-1190`, `$FC3/probe-lstree.txt`, `$FC3/bats-head.txt`

---

## Claim 14: main_entry prints "error" "(no default branch found by name, or ls-tree failed: never read as absent)"

**Location:** `scripts/lib/dev-cycle-read.sh:251-252`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both error triggers and every caller in the repo. It does not establish failure detection for a git failure that exits 0 with partial output; none was observed, and a valid SHA with a missing path legitimately exits 0 with no output, which is the "absent" case.

The code is `main_by_name || { echo error; return; }` and `out="$(git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1")" || { echo error; return; }` (`scripts/lib/dev-cycle-read.sh:259-261`). This is a plain assignment from a command substitution, not a pipeline, so ls-tree's own exit status is what `||` tests. Probe `$FC3/probe-lstree.txt` (2026-10-05T10:59:55Z) showed a bad SHA giving `fatal: not a tree object` and `exit=128`, and a valid SHA with a nonexistent path giving `exit=0` with empty output. `rg -n main_entry` outside docs/ finds exactly two callers. check_brief has `error) echo "skip $a: the default branch's tree could not be read"; return ;;` (`:325`), and check_answer has `error) echo "skip $a: the default branch's tree could not be read, so $f is not read"; return ;;` (`:543`). The library probe (`$FC3/probe-a2.txt`, cwd `$FC3/ra2`, 2026-10-05T11:01:41Z, exit 0) sets `MAIN_SHA=000…0`. It shows the c8435580 lib printing `ok docs/working/briefs/2026-01-01-a.md new` and `main_entry: absent`, and HEAD printing the two skip lines, `main_entry: error`, and `unnamed: error` with MAIN_BY_NAME emptied.

**Evidence:** `scripts/lib/dev-cycle-read.sh:251-267`, `scripts/lib/dev-cycle-read.sh:320-327`, `scripts/lib/dev-cycle-read.sh:539-545`, `$FC3/probe-lstree.txt`, `$FC3/probe-a2.txt`

---

## Claim 15: "One ls-tree call lists the path and every directory above it (-t: trees too; --full-tree: paths from the top level, whatever the current directory)"

**Location:** `scripts/lib/dev-cycle-read.sh:252-254`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that a single `git ls-tree -t --full-tree` process prints every ancestor tree and the path, from any cwd. It does not establish that it lists *only* those: it also prints the other children of each named directory (49 entries for questions.md on this repo; row 220, Won't-Fix).

`$FC3/probe-lstree.txt`: `git ls-tree -t --full-tree $S -- docs/working/questions.md` alone printed `040000 tree … docs`, `040000 tree … docs/working` and the file entry. Without `-t`, the ancestors were missing. From `cd docs` without `--full-tree` it printed `./`, and with `--full-tree` it printed the full paths. The real-repo count (`git ls-tree -t --full-tree main -- docs docs/working docs/working/questions.md | wc -l`) is 49.

**Evidence:** `scripts/lib/dev-cycle-read.sh:252-261`, `$FC3/probe-lstree.txt`

---

## Claim 16: brief_fields contract: first unfenced line per key among Status/Branch/Policy/Paths/Asked/Dispatched, "whole, after one trailing CR is dropped"; sets BRIEF[...] ("a key with no such line stays unset"); empties BRIEF_ODD; a refused file "sets no key and returns 1, with BRIEF_ODD 'odd N WHY' ... or 'unbalanced N'"; "read in one pass"

**Location:** `scripts/lib/dev-cycle-read.sh:268-276`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers keys, first-copy selection, fence skipping, CR stripping, unset keys, both BRIEF_ODD forms, the reset on refusal and the single awk pass. It does not establish behavior when the caller's precondition fails (a non-blob path: `git cat-file` fails, `out` is empty, and the function returns 0 with no keys, so check_brief's Status regex then skips) or for keys that differ only in case (`Status:` is matched case-sensitively, so `status:` is not a machine line).

The implementation is the awk at `scripts/lib/dev-cycle-read.sh:286-292`: `match($0, /^(Status|Branch|Policy|Paths|Asked|Dispatched):/) { k = tolower(...); if (!(k in got)) { got[k] = 1; kv[++nk] = k "\t" $0 } }`, and `END` prints either the odd/unbalanced line or the kv pairs. The bash loop then does `odd\ *|unbalanced\ *) BRIEF=(); BRIEF_ODD="$l"; return 1 ;;` (`:296`). Test 66 (`test/scripts/dev-cycle.bats:1207-1240`) checks every key, the fenced `Status: done` skipped, `Branch: second` ignored, `Status: open\r` read as `Status: open`, `refused [odd 2 fence] 0`, `refused [unbalanced 2] 0`, and `branch=[unset] odd=[]` after a refusal. It passes. Test 64 checks `refused [odd 2 nul] 0`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:268-300`, `test/scripts/dev-cycle.bats:1174-1190`, `test/scripts/dev-cycle.bats:1207-1240`, `$FC3/bats-head.txt`

---

## Claim 17: "(the fence opened at line N never closes; a NUL byte is refused too, so each value is the line as stored)"

**Location:** `scripts/lib/dev-cycle-read.sh:275-277`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the NUL half, which is now true: no stored value has lost a NUL byte, because a NUL-bearing file sets no value at all. It does not support "the line as stored" literally: a stored line ending in CR is returned without that CR. Nor does it support the clause's position, which reads as part of the `unbalanced N` gloss.

Execution against 2da477b7 shows NUL lines never reach a value: test 64 gives `refused [odd 2 nul] 0`, so no key is set. "the line as stored" is not exact, though. The awk runs `{ sub(/\r$/, "") }` before capture (`scripts/lib/dev-cycle-read.sh:287`), and test 66 stores `Status: open\r` but reads `status=[Status: open]` (`test/scripts/dev-cycle.bats:1212`, `:1223`). The same comment already says "after one trailing CR is dropped" (`:271`). The clause also sits inside the parenthetical explaining `"unbalanced N"`, though it concerns `"odd N nul"`. A precise version would say "each value is the stored line less one trailing CR". This is the iteration-1 "whole" finding's residue, now narrower: the NUL part of the claim is fixed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:268-292`, `test/scripts/dev-cycle.bats:1174-1190`, `test/scripts/dev-cycle.bats:1207-1240`, `$FC3/bats-head.txt`

---

## Claim 18: "The whole blob is read (no early exit: SIGPIPE under pipefail)"

**Location:** `scripts/lib/dev-cycle-read.sh:284`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the absence of an `exit` in brief_fields' awk program and in FENCE_AWK. It does not establish that git cat-file never gets SIGPIPE for other reasons, such as awk crashing.

The program at `scripts/lib/dev-cycle-read.sh:286-292` has no `exit` statement, and it skips with `fence($0) { next }`. FENCE_AWK (`:186-230`) has no `exit` either (paraphrased — no quote available because the claim concerns the absence of a token across the 45-line awk text, which was read in full).

**Evidence:** `scripts/lib/dev-cycle-read.sh:186-230`, `scripts/lib/dev-cycle-read.sh:284-292`

---

## Claim 19: check_brief comment: "its Status line from brief_fields ... neither is one stored as anything but a regular file under plain directories (main_entry). 'new' when the default branch has no file at that path"

**Location:** `scripts/lib/dev-cycle-read.sh:301-308`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers three things: check_brief's Status comes from brief_fields, the notdir and error skips, and absent giving `ok … new`. It does not establish the Status-commit lookup (`git log -G`, `:344-345`), which is unchanged by this diff.

The code is `e="$(main_entry "$a")"; case "$e" in absent) echo "ok $a new"; return ;; blob) ;; notdir\ *) ...; error) ...` (`:320-327`), then `st="${BRIEF[status]-}"` (`:335`). Test 66's last line (`ok $b open …`) agrees with brief_fields. Probe `$FC3/probe-notdir.txt` (cwd `$FC3/rd`, 2026-10-05T11:02:51Z, exit 0) uses a symlinked `docs/working/briefs` on main and a plain directory in the working tree. main's lib printed `ok docs/working/briefs/2026-01-01-a.md new`, and c8435580's printed `skip …: docs/working/briefs is not a directory on the default branch`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:301-347`, `test/scripts/dev-cycle.bats:1207-1240`, `$FC3/probe-notdir.txt`

---

## Claim 20: check_answer comment: reads both files "on the default branch's commit, never the working tree ... A file stored as anything but a regular file under plain directories there is not read (main_entry). It reads only git objects, so it needs no ROOT_REAL and adds nothing to SKIPPED."

**Location:** `scripts/lib/dev-cycle-read.sh:527-532`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers no ROOT_REAL, SKIPPED left at 0 even with a symlinked archive on main, running from a subdirectory, and non-regular files not read. It does not establish the D8 rationale ("a build loop can write any working tree"), which is design intent.

The body (`:533-558`) calls only `main_by_name`, `main_entry`, `git cat-file` and awk. Test 63 expects `skipped=0` with a symlinked archive committed and passes. Probe `$FC3/probe-a4.txt` (cwd `$FC3/r63`, 2026-10-05T10:59:35Z, exit 0) sets ROOT_REAL in the same repo: main's lib reports `skipped=1`, while c8435580's lib reports `skipped=0`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:527-558`, `test/scripts/dev-cycle.bats:1160-1172`, `$FC3/probe-a4.txt`, `$FC3/bats-head.txt`

---

## Claim 21: SKILL.md: "`questions-archive.md`, both from the default branch's commit (an answer recorded only in the working tree reads `open`, or no such entry, until it lands)"

**Location:** `skills/dev-cycle/SKILL.md:293-294`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the same behavior as Claim 2, with "lands" meaning reachable from the default branch's commit (test 60's side-branch case stays `open`). It does not establish the case where main holds an older answer that the working tree changes (Claim 2's residue).

See Claim 2's executed evidence: test 60 passes, and the wt-only probe gives `skip Q-2: no such entry …`.

**Evidence:** `skills/dev-cycle/SKILL.md:290-297`, `test/scripts/dev-cycle.bats:1118-1135`, `$FC3/probe-wt-only.txt`, `$FC3/bats-head.txt`

---

## Claim 22: d6426e3e: "The symlinked-questions case now commits its symlink."

**Location:** `test/scripts/dev-cycle.bats:652`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the added commit line and the updated expectation. It does not establish anything beyond that one test.

The diff adds `git add -A && git commit -qm link` (`test/scripts/dev-cycle.bats:652`) before the run, and the expectation becomes `"skip Q-100: docs/working/questions.md is not a regular file on the default branch"*` (`:654`).

**Evidence:** `test/scripts/dev-cycle.bats:650-655`

---

## Claim 23: test 63 name "check_answer reads git only: no ROOT_REAL needed, SKIPPED untouched, skip without main by name" and 2da477b7's "A4: the SKIPPED test now has a symlinked archive on main, so it fails against the old working-tree reader"

**Location:** `test/scripts/dev-cycle.bats:1160`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the test passes at HEAD and fails against main's working-tree reader, and that the symlinked archive does make that reader grow SKIPPED once ROOT_REAL is set. It does not establish that the SKIPPED assertion is what catches the old reader in this test as written: the old reader exits first at need_root (no ROOT_REAL), so the ROOT_REAL step catches it before the SKIPPED assertion is reached.

At main's lib the test fails at `[ "$status" -eq 0 ]` (`:1168`) with `ROOT_REAL is not set` (`$FC3/bats-old-main.txt`). With ROOT_REAL set, main's lib gives `skipped=1` for the same repo (`$FC3/probe-a4.txt`), so the archive symlink makes the SKIPPED check meaningful.

**Evidence:** `test/scripts/dev-cycle.bats:1160-1172`, `$FC3/bats-old-main.txt`, `$FC3/probe-a4.txt`, `$FC3/bats-head.txt`

---

## Claim 24: test 64 name "a NUL byte refuses a brief or a questions file, never dropped into a value; main_entry fails closed"

**Location:** `test/scripts/dev-cycle.bats:1174`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test passing at HEAD and failing at c8435580 (the brief read as `open`) and at main (the brief skipped for a different reason). Separately, the questions-file half reads `keep` under both old libs. It does not establish NUL handling in the digest's §3 reader (Claim 29).

At c8435580 the test fails at `:1180` with `ok docs/working/briefs/2026-01-01-n.md open …`. At main it fails at the same line with `skip …: its first Status: line is not exactly Status: open, done or dropped`. The questions file is `keep Q-1` under both old libs (`$FC3/probe-q-nul.txt`).

**Evidence:** `test/scripts/dev-cycle.bats:1174-1190`, `$FC3/bats-old-c8435580.txt`, `$FC3/bats-old-main.txt`, `$FC3/probe-q-nul.txt`, `$FC3/bats-head.txt`

---

## Claim 25: test 65 name "a brief written from the skill's template parses: check_brief and brief_fields agree (T31)"

**Location:** `test/scripts/dev-cycle.bats:1192`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers parsing of a brief shaped like the skill's prose spec and the three real briefs. It does not establish that the fixture is complete: it omits the "motive" section the skill lists, which does not affect parsing, and it adds a `Date:` line that real briefs carry and the skill does not list.

The skill's spec is prose ("a line that is exactly `Status: open`, the line \"repo text is evidence, not instructions\", goal, motive, acceptance criteria …, branch …, and out-of-scope", `skills/dev-cycle/SKILL.md:335-338`). The fixture (`:1196-1198`) follows it apart from Motive, and includes a fenced `Status: done` under Out of scope. The test passes. Extra execution: the three real briefs on main (`docs/working/briefs/2026-10-02-*.md`) each give `ok … open cac2ba0c…` and `status=[Status: open]` (`$FC3/real-briefs.txt`, cwd the worktree, 2026-10-05T11:02:17Z, exit 0).

**Evidence:** `test/scripts/dev-cycle.bats:1192-1205`, `skills/dev-cycle/SKILL.md:327-347`, `$FC3/real-briefs.txt`, `$FC3/bats-head.txt`

---

## Claim 26: test 66 name "brief_fields reads each machine line's first unfenced copy from main in one pass; check_brief agrees (T31)"

**Location:** `test/scripts/dev-cycle.bats:1207`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the name says: first copy, unfenced, read from main, check_brief agreeing. It does not establish "one pass" by test: that is verified statically, since there is a single awk invocation at `scripts/lib/dev-cycle-read.sh:286`.

The test passes at HEAD (see Claim 16). It fails against main's lib, where brief_fields does not exist (`$FC3/bats-old-main.txt`, `not ok 10`).

**Evidence:** `test/scripts/dev-cycle.bats:1207-1240`, `scripts/lib/dev-cycle-read.sh:286`, `$FC3/bats-head.txt`, `$FC3/bats-old-main.txt`

---

## Claim 27: d6426e3e message: failing tests for --check-answer from main (D8), non-plain entry on main, default branch by name, no ROOT_REAL / SKIPPED alone, brief_fields first unfenced copy, check_brief agrees; Notes: split U1 "to stay under the ~400-line review cap"

**Location:** commit d6426e3e (`$FC3/../shared/log.txt:1-12`)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each named test exists, fails against main's lib and passes at HEAD, and that U1a's code-and-test diff is under 400 lines. It does not establish U1b's size.

`$FC3/bats-old-main.txt` shows tests 60-66 (`not ok 4`-`not ok 10` in the filtered run) failing against main's lib, apart from the pre-existing filtered tests. `git diff --stat main...HEAD -- scripts skills test` gives `259 insertions(+), 53 deletions(-)`, which is 312 lines.

**Evidence:** `test/scripts/dev-cycle.bats:1118-1240`, `$FC3/bats-old-main.txt`

---

## Claim 28: c8435580 message: check_answer reads from main, skips without a default branch by name, "reads only git objects (no ROOT_REAL, nothing added to SKIPPED)", --check-answer exits 1 without such a branch; main_entry "from one `ls-tree -t --full-tree` call, so no reader takes a symlink's target text or reads through a symlinked directory on main"; brief_fields "a refused file sets none and returns 1 with BRIEF_ODD"; "check_brief also skips a brief whose directory is not a directory on main (before, ls-tree printed nothing and it read as "new")"; Notes: a working-tree-only answer "reads ... as open and lists it in the final message; that fails closed"

**Location:** commit c8435580 (`$FC3/../shared/log.txt:17-45`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed behavior against HEAD, and the "before … new" history against main's lib. It does not establish c8435580's own fail-open main_entry on ls-tree failure, which 2da477b7 later fixed (Claim 30), or the Notes' unchecked line "The installed image copy is unchanged until a release", which sits outside the repo.

The executed evidence is in Claims 4, 7, 13, 15, 16, 19 and 20. The "before" case is `$FC3/probe-notdir.txt`, where main's lib prints `ok … new`. The fails-closed note matches the skill's `open` handling, which says "leave the ID, and list it in the final message with its brief" (`skills/dev-cycle/SKILL.md:294-296`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:247-347`, `scripts/lib/dev-cycle-read.sh:527-558`, `skills/dev-cycle/SKILL.md:290-297`, `$FC3/probe-notdir.txt`, `$FC3/bats-head.txt`

---

## Claim 29: 2da477b7: "FENCE_AWK now refuses any line holding a NUL byte ("holds a NUL byte"), so every reader skips such a file and no value loses a byte"

**Location:** commit 2da477b7 (`$FC3/../shared/log.txt:54-57`)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two FENCE_AWK readers in the lib (brief_fields via check_brief, and check_answer), both of which skip NUL files. It does not hold for "every reader" read literally: the digest's §3 "Watched questions" reads docs/working/questions.md through scripts/questions.sh, not through FENCE_AWK, and it reads and lists a NUL-bearing questions file.

`rg -n FENCE_AWK scripts/` finds only two uses: `scripts/lib/dev-cycle-read.sh:286` (brief_fields) and `:547` (check_answer). Both skip, as shown by test 64. Probe: a repo whose committed questions.md holds an open `trigger` entry with a NUL in its body. `timeout 60 bash scripts/dev-cycle.sh` (cwd `$FC3/rnul`, 2026-10-05T11:01:19Z, exit 0) printed `- Q-001  trigger         wath` and `Open by route: trigger=1` under "## 3. Watched questions" (`$FC3/digest-nul.txt`), so the file was read, not skipped. The NUL was outside the heading here, so whether any byte of a printed field was lost was not tested. A precise version: "both FENCE_AWK readers (check_brief/brief_fields and check_answer) skip such a file". The "no value loses a byte" part holds for BRIEF values (Claim 17, apart from the documented CR drop).

**Evidence:** `scripts/lib/dev-cycle-read.sh:286`, `scripts/lib/dev-cycle-read.sh:547`, `scripts/dev-cycle.sh:328-361`, `$FC3/digest-nul.txt`, `$FC3/bats-head.txt`

---

## Claim 30: 2da477b7: "A2: main_entry printed "absent" when ls-tree failed, which check_brief turned into "ok ... new". It now prints "error" without a default branch found by name or on a failed ls-tree, and both callers skip." (also R1's "Status: op<NUL>en read as open (main refused it)", the Comments bullet, and Notes "dev-cycle.sh's --check-brief and --check-answer refuse such files too")

**Location:** commit 2da477b7 (`$FC3/../shared/log.txt:54-73`)
**Type:** Error-handling / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the before and after of main_entry on a failed ls-tree, R1's before (c8435580 reads `open`) and main's refusal, the removal of the nonexistent suite name from the lib header, and the help-text claims. It does not establish the A4 sub-claim beyond Claim 23's scope.

`$FC3/probe-a2.txt` shows c8435580 printing `ok docs/working/briefs/2026-01-01-a.md new` and `main_entry: absent` on `fatal: not a tree object`, and HEAD printing both skip lines. The old main_entry had `out="$(git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1")"` with no failure arm (`git show c8435580:scripts/lib/dev-cycle-read.sh`, main_entry). Under main's lib, the R1 brief gives `skip …: its first Status: line is not exactly Status: open, done or dropped` (`$FC3/bats-old-main.txt`), which confirms "main refused it". The old header named `test/scripts/dev-cycle.bats and build-loop-read.bats`, and the latter file does not exist. Test 64 runs both NUL refusals through `bash "$DC"`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:10-12`, `scripts/lib/dev-cycle-read.sh:256-267`, `scripts/dev-cycle.sh:42`, `scripts/dev-cycle.sh:68`, `$FC3/probe-a2.txt`, `$FC3/bats-old-main.txt`, `$FC3/bats-old-c8435580.txt`, `test/scripts/dev-cycle.bats:1174-1190`

---

## Claim 31: 2da477b7 / override row: "A3 (ls-tree cost, measured 49 entries, Won't-Fix)"

**Location:** commit 2da477b7 (`$FC3/../shared/log.txt:68-69`)
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the entry count for the questions.md lookup on this repo at main and at HEAD. It does not establish the cost of other paths, or the count as docs/ grows.

`git ls-tree -t --full-tree <rev> -- docs docs/working docs/working/questions.md | wc -l` gives 49 at main and 49 at HEAD (cwd the worktree, 2026-10-05T~11:04Z, exit 0, inline output).

**Evidence:** `scripts/lib/dev-cycle-read.sh:261`, `docs/reviews/override-log.md` (row dated 2026-10-05, feat/build-loop-u1a, A3)

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 17** (`scripts/lib/dev-cycle-read.sh:275-277`): "so each value is the line as stored" leaves out the trailing CR that the same comment says is dropped (test 66 stores `Status: open\r` and reads `Status: open`), and the NUL clause sits inside the `unbalanced N` gloss. Suggested wording: "each value is the stored line less one trailing CR", with the clause moved out of the parenthetical.
- **Claim 29** (commit 2da477b7 message): "every reader skips such a file" holds for the two FENCE_AWK readers (check_brief/brief_fields, check_answer). The digest's §3 Watched questions (questions.sh) still reads and lists a NUL-bearing questions.md (`$FC3/digest-nul.txt`). Suggested wording: "both FENCE_AWK readers skip such a file".

### Unverifiable
- **Claim 11b** (`scripts/lib/dev-cycle-read.sh:216`): whether `index(l, "\0")` detects NUL under gawk, busybox awk or one-true-awk. None is installed. To verify, run `$FC3/probe1.txt`'s probe under each. Watch one-true-awk in particular, where `"\0"` may be an empty string, which would make the check fire on every non-empty line.

---

## Goal-Alignment Note

Goal: the final confirming fact-check for U1a before merge. All three iteration-1 fixes check out by execution against 2da477b7:
- **R1/A1:** NUL is refused, and test 64 fails against c8435580's lib, which read the brief as `open`.
- **A2:** main_entry fails closed, with the before and after probed, and both callers have an `error` arm.
- **A4:** test 63 fails against main's reader. It fails at need_root before reaching the SKIPPED assertion, but the symlinked archive does grow SKIPPED under the old reader once ROOT_REAL is set.

No Incorrect or Stale claims. The two Mostly accurate items are wording only (a comment and a commit message) and change no behavior.

Escalate:
- **Portability, for security-reviewer and the orchestrator** (`scripts/lib/dev-cycle-read.sh:216`, `:286`, `:547`): the lib runs a bare `awk` whose NUL detection was verified only on mawk. If a host's awk treats `"\0"` as the empty string (suspected for one-true-awk; unverified), every brief and questions file is refused. That fails closed, but it would make every check a skip.
- **Digest NUL handling, for the orchestrator** (`scripts/dev-cycle.sh:328-361`, via scripts/questions.sh): the digest's §3 does not apply FENCE_AWK's refusals to questions.md, NUL included. This is outside U1a's stated scope, but it is the basis of Claim 29's residue.
