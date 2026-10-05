Commit: 2da477b7

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u1a (claude-workflows, branch feat/build-loop-u1a)
**Scope:** `git diff main...feat/build-loop-u1a` over scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, skills/dev-cycle/SKILL.md, test/scripts/dev-cycle.bats, plus the three commit messages (d6426e3e, c8435580, 2da477b7). docs/reviews/ files in the diff are not under review.
**Checked:** 2026-10-05
**Total claims checked:** 42
**Summary:** 34 verified, 5 mostly accurate, 0 stale, 2 incorrect, 1 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first: none of its five entries (measured counts quoted from artifact sets, a mis-attributed consumer) matches a claim here. The one measured value in scope ("measured 49 entries", claim 40) was recomputed and holds.

Execution provenance: every executed claim ran under `LC_ALL=C.UTF-8` (bats) and the lib's own `env LC_ALL=C awk` (= `/usr/bin/mawk` 1.3.4 20200120; `nawk` is also mawk; no gawk, busybox or one-true-awk is installed). Captured output files are in `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/fc1/logs/` (abbreviated `L/` below); each file starts with its UTC timestamp and the cwd/command. Probe scripts: `fc1/probe1.sh`, `fc1/probe2.sh`, `fc1/probe3.sh`. Old-lib variants were built with `git archive 2da477b7 scripts test` plus `git show <rev>:scripts/lib/dev-cycle-read.sh` into `fc1/t-<rev>/`.

Key runs:
- `L/bats-head.txt` — `cd /workspace/.claude/wt-build-loop-u1a && timeout 500 bats test/scripts/dev-cycle.bats`, 2026-10-05T10:59:21Z, exit 0, 66/66 ok.
- `L/bats-c8435580.txt` — tests 63/64 at 2da477b7 against c8435580's lib, cwd `fc1/`, 11:00:04Z, exit 1 (64 fails: `ok docs/working/briefs/2026-01-01-n.md open …`).
- `L/bats-main.txt`, `L/bats-mainnoroot.txt`, `L/bats-nosym.txt`, `L/bats-mutA.txt`, `L/bats-mutB.txt` — test 63 against main's lib, main's lib with need_root stubbed, main's lib with the symlink lines removed, and two SKIPPED-appending mutants of the HEAD lib; 11:00:05–11:00:53Z.
- `L/bats-d6426e3e.txt` — d6426e3e's suite with its own lib, 11:04:00Z, exit 1.
- `L/nul-mawk.txt` (10:58:06Z, exit 0), `L/probe-main-entry-nul.txt` (`timeout 120 bash probe1.sh`, 11:02:12Z, exit 0), `L/probe2.txt` (`timeout 120 bash probe2.sh`, 11:03:54Z, exit 0), `L/probe3.txt` (`timeout 60 bash probe3.sh`, 11:05:47Z, exit 0).

---

## Claim 1: "a stray carriage return, a NUL byte, or a byte-order mark on line 1" (--check-brief refusal list)

**Location:** `scripts/dev-cycle.sh:42`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --check-brief skipping a brief on main that has a NUL at line start, middle, end, or inside a fence, under mawk; does not establish behavior under other awk implementations (claim 11b) or which reason is named when one line has both a CR and a NUL (CR is checked first and wins).

`--check-brief` goes to `check_brief`, which refuses on `BRIEF_ODD` from brief_fields (`scripts/lib/dev-cycle-read.sh:328-333`: `if ! brief_fields "$a"; then case "$BRIEF_ODD" in odd\ *) … echo "skip $a: line $n $(oddwhy "$why"), so the brief is not read"`). probe1 output: `a: skip …-a.md: line 1 holds a NUL byte`, `b: … line 1 holds a NUL byte`, `c: … line 2 holds a NUL byte` (NUL inside a ``` fence), and `d` (`Status: open\r\0`) reports `holds a carriage return that does not end it`. Test 64 asserts `skip $b: line 2 holds a NUL byte, so the brief is not read` and passes.

**Evidence:** `scripts/dev-cycle.sh:42`, `scripts/lib/dev-cycle-read.sh:213-216,328-333`, `L/probe-main-entry-nul.txt`, `L/bats-head.txt`

---

## Claim 2: "read from docs/working/questions.md or its archive on the default branch's commit (an answer only in the working tree reads open, or no such entry, until it is committed there)"

**Location:** `scripts/dev-cycle.sh:56-59`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both outcomes for a working-tree-only answer (entry on main but unanswered → `open`; no entry on main → `skip … no such entry`) and a branch-only commit reading `open`; does not establish what "committed there" means for a default branch resolved from origin/HEAD that has not been fetched.

`check_answer` reads `git cat-file blob "$MAIN_SHA:$f"` (`scripts/lib/dev-cycle-read.sh:547`), never the working-tree file. Test 60 (`test/scripts/dev-cycle.bats:1118-1135`) gets `open Q-1` for a working-tree-only and a side-branch-only answer, and passes. probe3 (no questions.md on main, an answered one in the working tree) prints `skip Q-1: no such entry in docs/working/questions.md or questions-archive.md on the default branch`, matching `scripts/lib/dev-cycle-read.sh:559`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:538-559`, `test/scripts/dev-cycle.bats:1118-1135`, `L/probe3.txt`, `L/bats-head.txt`

---

## Claim 3: "a stray carriage return, a NUL byte, a byte-order mark on line 1, a question heading inside a fence, a questions file that is not a regular file under plain directories on the default branch"

**Location:** `scripts/dev-cycle.sh:64-70`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the NUL and non-regular-file/non-directory skip reasons of --check-answer (symlinked questions.md, symlinked docs/working on main); does not establish the gitlink or tree-at-path cases, which reach the same `*)` branch but were not run.

`check_answer` maps main_entry's result: `notdir\ *) echo "skip $a: ${e#notdir } is not a directory on the default branch, …"` and `*) echo "skip $a: $f is not a regular file on the default branch, so no entry in it is read"` (`scripts/lib/dev-cycle-read.sh:543-545`). Test 61 gets both messages; test 64 gets `skip Q-1: line 4 of docs/working/questions.md holds a NUL byte, …`. Both pass.

**Evidence:** `scripts/lib/dev-cycle-read.sh:538-553`, `test/scripts/dev-cycle.bats:1137-1151,1174-1190`, `L/bats-head.txt`

---

## Claim 4: "--check-brief, --check-branch and --check-answer need a default branch found by name (origin/HEAD, main or master): they read its commit" / Exit 1 "no default branch (for the digest, --check-brief, --check-branch and --check-answer)"

**Location:** `scripts/dev-cycle.sh:71-72`, `scripts/dev-cycle.sh:78-80`, `scripts/dev-cycle.sh:187-193`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the --check-answer gate's exit 1 with empty stdout when only a non-main/master branch exists; does not establish the digest's own exit (pre-existing: it exits 1 only when even the current-branch fallback fails).

```bash
# scripts/dev-cycle.sh:191-193
if [[ "$CHECK" == --check-brief || "$CHECK" == --check-branch || "$CHECK" == --check-answer ]] && ! main_by_name; then
  echo "$CHECK needs a default branch (origin/HEAD, main or master); found none" >&2; exit 1
fi
```

Test 62 (`test/scripts/dev-cycle.bats:1153-1158`) asserts `status -eq 1`, empty output and `needs a default branch` on stderr; passes.

**Evidence:** `scripts/dev-cycle.sh:187-193`, `test/scripts/dev-cycle.bats:1153-1158`, `L/bats-head.txt`

---

## Claim 5: help prints the header (`sed -n '2,80p'`)

**Location:** `scripts/dev-cycle.sh:110`
**Type:** Configuration
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the help range ending on the header's last line (:80); does not establish rendering of every header line.

Line 80 is `# default branch (for the digest, --check-brief, --check-branch and --check-answer); …` and line 81 is blank; `bash scripts/dev-cycle.sh --help | tail -3` ends with that Exit paragraph (paraphrased — no quote available because the output was viewed inline in the session, not saved; it is reproducible with the command given).

**Evidence:** `scripts/dev-cycle.sh:78-81,110`

---

## Claim 6: "A change here runs under both callers' suites (test/scripts/dev-cycle.bats, and build-loop.sh's suites under test/scripts/ as they land)"

**Location:** `scripts/lib/dev-cycle-read.sh:10-12`
**Type:** Architectural
**Verdict:** Mostly accurate
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which callers and suites exist at 2da477b7; does not establish whether a future build-loop suite will be wired into the runner.

There is one caller today: `rg` finds `scripts/dev-cycle.sh` sourcing the lib and no `scripts/build-loop.sh`; `test/scripts/` holds `dev-cycle.bats` and no build-loop suite (paraphrased — no quote available because the claim covers the absence of a file, checked with `ls scripts/ test/scripts/`). "both callers' suites" is present tense for a second caller that does not exist yet; "as they land" hedges the suite but not the caller. Precise version: "runs under test/scripts/dev-cycle.bats, and under build-loop.sh's suites once build-loop.sh lands". (Iteration 1's claim 4 — naming the nonexistent `build-loop-read.bats` — is fixed.)

**Evidence:** `scripts/lib/dev-cycle-read.sh:1-12`, `scripts/dev-cycle.sh:91-96`

---

## Claim 7: "inrepo, dirok, skipped, check_brief and the import walk (imported_names) exit 1 (need_root) unless ROOT_REAL is set" (check_answer removed from the list)

**Location:** `scripts/lib/dev-cycle-read.sh:15-18`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_answer no longer calling need_root (directly or via skipped); does not re-verify the other listed functions (unchanged lines).

`check_answer` (`scripts/lib/dev-cycle-read.sh:534-560`, read in full) calls only `main_by_name`, `main_entry`, `git cat-file` and awk; no `need_root`/`skipped`. Test 63 runs it with ROOT_REAL unset and from `docs/` with status 0; passes. Against main's lib the same test dies with `dev-cycle-read.sh: ROOT_REAL is not set` (`L/bats-main.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:534-560`, `test/scripts/dev-cycle.bats:1160-1172`, `L/bats-head.txt`, `L/bats-main.txt`

---

## Claim 8: "check_brief, check_branch and check_answer skip every argument unless it returned 0 with main found by name"

**Location:** `scripts/lib/dev-cycle-read.sh:21-23`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the check_answer guard newly added; does not establish the case of MAIN_SHA set by name but stale (row 208 territory).

`if ! main_by_name; then echo "skip $a: no default branch found by name (origin/HEAD, main or master), or resolve_main has not run"; return; fi` (`scripts/lib/dev-cycle-read.sh:537`). Test 63's first output line is exactly that message for a call before resolve_main.

**Evidence:** `scripts/lib/dev-cycle-read.sh:312,359,537`, `L/bats-head.txt`

---

## Claim 9: "Inputs: check_brief, check_branch, check_answer, main_entry and brief_fields read the default branch's commit, never the working tree (check_brief also refuses a brief path that is not plain in the working tree, which the cycle writes)"

**Location:** `scripts/lib/dev-cycle-read.sh:29-32`
**Type:** Architectural
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the content reads of the five functions (git objects only) and check_brief's working-tree blocker; does not establish that check_branch reads only "the default branch's commit" in a narrow sense (it also reads refs/heads/<name>, which is still not the working tree).

main_entry uses `git ls-tree … "$MAIN_SHA"` (:261), brief_fields `git cat-file blob "$MAIN_SHA:$1"` (:286), check_answer `git cat-file blob "$MAIN_SHA:$f"` (:547), check_brief `blocker "$a" file` (:317) then main_entry/brief_fields. Test 66 overwrites the working-tree brief (`printf 'Status: dropped\nBranch: wt\n' > "$b"`) and still reads `status=[Status: open]`; passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:256-300,309-347,534-560`, `test/scripts/dev-cycle.bats:1207-1240`, `L/bats-head.txt`

---

## Claim 10: "a NUL byte (a caller reading the output through $(...) would lose it)" — FENCE_AWK refuses the whole file

**Location:** `scripts/lib/dev-cycle-read.sh:174-177`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stated reason ($(...) drops NUL) and that the refusal makes the whole file a skip for brief_fields/check_brief and check_answer; does not establish behavior under non-mawk awks (claim 11b).

The reason is reproduced: c8435580's lib (no NUL refusal) reads `Status: op\0en` as `ok docs/working/briefs/2026-01-01-n.md open …` (`L/bats-c8435580.txt`), i.e. bash's `$(...)` dropped the NUL. At HEAD, `fence()` sets `odd` and every later line returns 1 (`if (odd) return 1`, :214), and both END blocks print `odd …` first (:292, :522).

**Evidence:** `scripts/lib/dev-cycle-read.sh:204,213-216,292,522`, `L/bats-c8435580.txt`, `L/bats-head.txt`

---

## Claim 11a: `if (index(l, "\0")) { refuse("nul"); return 1 }  # $(...) drops NUL, so a printed line would not be the line read` — refuses exactly the lines holding a NUL (mawk)

**Location:** `scripts/lib/dev-cycle-read.sh:216`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers mawk 1.3.4 (the installed awk, reached by `env LC_ALL=C awk`): `"\0"` is a one-byte NUL string, input lines keep their NULs, and the test fires for NUL at start/middle/end and never on a NUL-free line; does not establish any other awk (claim 11b).

`L/nul-mawk.txt`: `BEGIN{s="\0"; print length(s)}` prints `1` and emits byte `\0`; on input `\0abc`, `ab\0c`, `abc\0`, `abc`, `` the program prints `1 1 4`, `2 3 4`, `3 4 4`, `4 0 3`, `5 0 0` (NR, index, length) — lines are not truncated at NUL and index is 0 without one. The FENCE_AWK string is shell-single-quoted (`FENCE_AWK='` at :186), so awk receives the two characters `\0`. No false refusal: the full 66-test suite passes and the three real briefs on this repo's main parse `ok … open` (`L/probe2.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:186,213-217`, `L/nul-mawk.txt`, `L/probe-main-entry-nul.txt`, `L/probe2.txt`

---

## Claim 11b: the same NUL refusal under other awk implementations

**Location:** `scripts/lib/dev-cycle-read.sh:216`
**Type:** Behavioral
**Verdict:** Unverifiable
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing executed (no gawk, busybox or one-true-awk installed); does not establish that the refusal is correct on macOS/BSD awk.

Execution required, blocked: only mawk is present (`/usr/bin/awk`, `/usr/bin/nawk` → mawk). By reading, a C-string awk that terminates the `"\0"` literal at its NUL would make the needle `""`; mawk itself returns `1` for `index("abc","")` (`L/nul-mawk.txt`), so if such an awk behaves the same, every non-empty line would be refused "nul" (fail closed, every brief and questions file skipped) (paraphrased — no quote available because the other implementations are not installed to quote or run). Needs a run under gawk and BSD/one-true-awk.

**Evidence:** `scripts/lib/dev-cycle-read.sh:216`, `L/nul-mawk.txt`

---

## Claim 12: `nul) echo "holds a NUL byte"`

**Location:** `scripts/lib/dev-cycle-read.sh:237`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reason text reaching both check_brief's and check_answer's skip lines; does not establish other reasons.

Test 64 asserts `… line 2 holds a NUL byte, so the brief is not read` and `… line 4 of docs/working/questions.md holds a NUL byte, so no entry in docs/working/questions.md is read`; passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:231-241,330,551`, `test/scripts/dev-cycle.bats:1174-1190`, `L/bats-head.txt`

---

## Claim 13: "check_brief, check_branch and check_answer read its commit, so they answer only when it was found by name"

**Location:** `scripts/lib/dev-cycle-read.sh:242-244`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each of the three having the main_by_name guard; does not establish brief_fields, which relies on its caller for the guard (documented at :277-278).

Guards at :312, :359 and :537 (same text as claim 8); test 63 line 1 and test 62 exercise check_answer's.

**Evidence:** `scripts/lib/dev-cycle-read.sh:242-246,312,359,537`, `L/bats-head.txt`

---

## Claim 14: main_entry prints "blob", "absent", "notfile", "notdir PART" or "error" ("no default branch found by name, or ls-tree failed: never read as absent")

**Location:** `scripts/lib/dev-cycle-read.sh:247-252`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all five outputs, the ls-tree failure path (bad MAIN_SHA, exit 128), that a valid SHA with a nonexistent path exits 0 (so reads absent correctly), and that both callers (check_brief, check_answer — the only ones in the repo) map "error" to a skip; does not establish a git that exits 0 while printing a partial listing.

```bash
# scripts/lib/dev-cycle-read.sh:256-267 (whole function)
main_entry() {
  local p="" rest="$1" out mode path want=()
  local -A m=()
  main_by_name || { echo error; return; }
  …
  out="$(git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1")" || { echo error; return; }
  while IFS=$'\t' read -r mode path; do [[ -n "$path" ]] && m["$path"]="${mode%% *}"; done <<<"$out"
  for p in "${want[@]}"; do
    case "${m[$p]-}" in '') echo absent; return ;; 040000) ;; *) echo "notdir $p"; return ;; esac
  done
  case "${m[$1]-}" in '') echo absent ;; 100644|100755) echo blob ;; *) echo notfile ;; esac
}
```

`out` is declared by the earlier `local`, so the assignment carries ls-tree's status (not a pipeline; nothing mid-pipeline to lose). probe1: `git ls-tree -t --full-tree HEAD -- nope/x.md` → `exit=0`; bad SHA → `fatal: not a tree object`, `exit=128`; `missing dir: absent  dir as file: notfile  under file: notdir top.md`. probe2 at HEAD with `MAIN_SHA=000…`: `main_entry=error`, `skip …: the default branch's tree could not be read`, `skip Q-1: the default branch's tree could not be read, so docs/working/questions.md is not read`; c8435580's lib prints `main_entry=absent` / `ok … new` for the same input. `rg main_entry` finds callers only at :320 and :539.

**Evidence:** `scripts/lib/dev-cycle-read.sh:256-267,320-327,539-546`, `L/probe-main-entry-nul.txt`, `L/probe2.txt`

---

## Claim 15: "One ls-tree call lists the path and every directory above it (-t: trees too; --full-tree: paths from the top level, whatever the current directory)"

**Location:** `scripts/lib/dev-cycle-read.sh:252-254`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one process listing every ancestor tree and the target, and --full-tree giving the same answer from a subdirectory; does not establish "only those entries": each named directory's children are listed too (settled Won't-Fix, override row 220).

probe1 `git ls-tree -t --full-tree HEAD -- docs docs/working docs/working/briefs docs/working/briefs/2026-01-01-a.md` prints `docs`, `docs/other`, `docs/working`, `docs/working/briefs` and all five briefs; `from docs/: blob blob` shows the same result after `cd docs`. Test 63's second call runs from `docs/` and still finds the archive symlink.

**Evidence:** `scripts/lib/dev-cycle-read.sh:252-261`, `L/probe-main-entry-nul.txt`, `test/scripts/dev-cycle.bats:1160-1172`

---

## Claim 16: "The caller has checked main_by_name and the path's form (pathform, so ls-tree prints it unquoted)"

**Location:** `scripts/lib/dev-cycle-read.sh:254-255`
**Type:** Invariant
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that pathform's alphabet (`NAMECHARS='abc…XYZ0123456789._/-'`, :139) contains no character git quotes under core.quotePath, and that both callers pass pathform-clean paths (check_brief via :313, check_answer fixed literals); does not establish pathspec-magic safety in a caller without dev-cycle.sh's `GIT_LITERAL_PATHSPECS=1` (:125) — pathform also excludes `*`/`?` there unless glob mode, so none arises today.

**Evidence:** `scripts/lib/dev-cycle-read.sh:139-149,313,538`, `scripts/dev-cycle.sh:125`

---

## Claim 17: brief_fields contract — "for each key, the first line outside a fence … whole, after one trailing CR is dropped … (a key with no such line stays unset) … empties BRIEF_ODD … sets no key and returns 1, with BRIEF_ODD "odd N WHY" … or "unbalanced N" …; a NUL byte is refused too, so each value is the line as stored"

**Location:** `scripts/lib/dev-cycle-read.sh:268-279`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the six keys, first-unfenced-copy selection, unset absent keys, both BRIEF_ODD forms, the NUL refusal and byte-exact values (every byte 0x01–0xFF but LF/CR, plus trailing spaces/tabs) under mawk; does not establish behavior when the caller's precondition is broken (a non-blob path: `out="$(…)"` then fails, which exits a `set -e` caller called bare, or returns 0 with no keys inside `if`), and the NUL clause sits inside the "unbalanced N" parenthetical though it applies to every value.

```bash
# scripts/lib/dev-cycle-read.sh:286-299 (excerpt ends :299; enclosing brief_fields() continues to :300 — read)
  out="$(git cat-file blob "$MAIN_SHA:$1" | env LC_ALL=C awk "$FENCE_AWK"'
    { sub(/\r$/, "") }
    fence($0) { next }
    match($0, /^(Status|Branch|Policy|Paths|Asked|Dispatched):/) {
      k = tolower(substr($0, 1, RLENGTH - 1)); if (!(k in got)) { got[k] = 1; kv[++nk] = k "\t" $0 }
    }
    END { if (odd) print "odd " odd " " oddwhy; else if (infence) print "unbalanced " fline; else for (i = 1; i <= nk; i++) print kv[i] }')"
  while IFS= read -r l; do
    case "$l" in
      '') ;;
      odd\ *|unbalanced\ *) BRIEF=(); BRIEF_ODD="$l"; return 1 ;;
      *) BRIEF["${l%%$'\t'*}"]="${l#*$'\t'}" ;;
```

Tests 64–66 pass (`refused [odd 2 nul] 0`, `refused [odd 2 fence] 0`, `refused [unbalanced 2] 0`, `branch=[unset] odd=[]`, all six keys from the first unfenced copy). probe1 writes a `Branch:` line holding every byte 0x01–0xFF except LF/CR and ending in `  \t `; `cmp` of `BRIEF[branch]` with the stored line: `branch value byte-identical to stored line (cmp exit=0)`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:268-300`, `test/scripts/dev-cycle.bats:1174-1240`, `L/probe-main-entry-nul.txt`, `L/bats-head.txt`

---

## Claim 18: "The whole blob is read (no early exit: SIGPIPE under pipefail)"

**Location:** `scripts/lib/dev-cycle-read.sh:284`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the absence of `exit` in brief_fields' awk program and in FENCE_AWK; does not establish behavior on a write error elsewhere in the pipeline.

The program quoted in claim 17 has no `exit`; FENCE_AWK (:186-230) has none either (paraphrased — no quote available because the claim covers the absence of a statement, checked by reading both programs whole).

**Evidence:** `scripts/lib/dev-cycle-read.sh:186-230,286-292`

---

## Claim 19: check_brief "its Status line from brief_fields … A brief FENCE_AWK refuses … is not read at all, and neither is one stored as anything but a regular file under plain directories (main_entry)"

**Location:** `scripts/lib/dev-cycle-read.sh:301-308`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the Status line coming from brief_fields, refusal on BRIEF_ODD, and the notdir/notfile/error skips; does not establish the `git log -G` commit lookup (unchanged lines).

`st="${BRIEF[status]-}"; if [[ ! "$st" =~ ^Status:\ (open|done|dropped)$ ]]; then echo "skip …"` (:335-338). probe2, brief directory a symlink on main and plain in the working tree: main's lib `ok …-a.md new`; c8435580 and HEAD `skip …: docs/working/briefs is not a directory on the default branch`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:309-347`, `L/probe2.txt`, `L/bats-head.txt`

---

## Claim 20: check_answer "from docs/working/questions.md and questions-archive.md on the default branch's commit, never the working tree … A file stored as anything but a regular file under plain directories there is not read (main_entry). It reads only git objects, so it needs no ROOT_REAL and adds nothing to SKIPPED."

**Location:** `scripts/lib/dev-cycle-read.sh:528-533`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the function's behavior (no ROOT_REAL use, no `skipped`/`SKIPPED` reference, main-only reads); does not establish that test 63 would catch a regression that appends to SKIPPED (it would not — claims 23, 37).

The whole function (:534-560) has no `need_root`, `skipped` or `SKIPPED` (paraphrased — no quote available because the claim covers absence, checked by reading the function whole). Tests 60, 61, 63 pass.

**Evidence:** `scripts/lib/dev-cycle-read.sh:528-560`, `L/bats-head.txt`

---

## Claim 21: "both from the default branch's commit (an answer recorded only in the working tree reads `open`, or no such entry, until it lands)"

**Location:** `skills/dev-cycle/SKILL.md:292-294`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both outcomes (claim 2's runs); does not establish the unchanged clause "once step 1 has archived an entry, `questions-archive.md`" — an entry archived only in the working tree is not read from the archive until that lands (main's questions.md still has it, so the answer is unaffected).

**Evidence:** `skills/dev-cycle/SKILL.md:289-297`, `L/probe3.txt`, `L/bats-head.txt`

---

## Claim 22: test name "check_answer reads git only: no ROOT_REAL needed, SKIPPED untouched, skip without main by name"

**Location:** `test/scripts/dev-cycle.bats:1160`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the named behaviors as properties of HEAD's check_answer (test passes; claim 20); does not establish that the "SKIPPED untouched" assertion can fail for a SKIPPED-appending reader (claim 23).

**Evidence:** `test/scripts/dev-cycle.bats:1160-1172`, `L/bats-head.txt`

---

## Claim 23: "# A symlinked archive on main: the working-tree reader added it to SKIPPED."

**Location:** `test/scripts/dev-cycle.bats:1163`
**Type:** Behavioral
**Verdict:** Incorrect
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the old reader and SKIPPED-appending mutants do on this test's fixture; does not establish the old reader's behavior with ROOT_REAL set at the root (where it would record the archive — not a condition this test creates).

In this fixture the working-tree reader never adds the archive: ROOT_REAL is unset and the second call runs after `cd docs`. Main's lib exits in need_root (`dev-cycle-read.sh: ROOT_REAL is not set`, `L/bats-main.txt`) whether or not the symlink lines exist (`L/bats-nosym.txt`, same failure). With need_root stubbed, it records `docs/` — first call: `skip Q-1: docs/ is not a plain file or directory`, `skipped=1` — because nothing is plain without ROOT_REAL; it never records the archive (`L/bats-mainnoroot.txt`). Two mutants of HEAD's check_answer that append to SKIPPED (`if [[ -n "$(blocker "$f" file)" ]]; then SKIPPED+=("$f"); fi`, and the same with `[[ -L "$f" ]]`) both **pass** the test (`L/bats-mutA.txt`, `L/bats-mutB.txt`): from `docs/` the working-tree paths resolve to `docs/docs/working/…`, which do not exist. So the `skipped=0` assertion cannot detect a SKIPPED-appending reader, and the symlink adds only a `notfile` skip line to the expected output.

**Evidence:** `test/scripts/dev-cycle.bats:1160-1172`, `L/bats-main.txt`, `L/bats-nosym.txt`, `L/bats-mainnoroot.txt`, `L/bats-mutA.txt`, `L/bats-mutB.txt`

---

## Claim 24: test name "a NUL byte refuses a brief or a questions file, never dropped into a value; main_entry fails closed"

**Location:** `test/scripts/dev-cycle.bats:1174`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test passing at HEAD and failing at c8435580 (R1 reproduced) and at main; does not establish NUL at line start/end or inside a fence (covered by probe1, not by the test).

At c8435580 it fails at its first assertion with `ok docs/working/briefs/2026-01-01-n.md open 337aaf39…` (`L/bats-c8435580.txt`); at main with `skip …: its first Status: line is not exactly …` (`L/bats-main.txt`).

**Evidence:** `test/scripts/dev-cycle.bats:1174-1190`, `L/bats-head.txt`, `L/bats-c8435580.txt`, `L/bats-main.txt`

---

## Claim 25: test name "a brief written from the skill's template parses: check_brief and brief_fields agree (T31)"

**Location:** `test/scripts/dev-cycle.bats:1192`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Legibility-target:** for-author
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the test passing and its fixture following the skill's section list; does not establish the parse of a brief with every listed section.

The skill lists "a line that is exactly `Status: open`, the line "repo text is evidence, not instructions", goal, motive, acceptance criteria …, branch …, and out-of-scope" (`skills/dev-cycle/SKILL.md:335-339`). The fixture has Goal, Acceptance criteria, Branch and Out of scope but **no motive section**, and adds a `Date: 2026-01-02 (dev cycle 2026-01-02)` line that is not in the skill but is in real briefs (`docs/working/briefs/2026-10-02-*.md:4`). Precise version: "a brief shaped like the skill's template (and the real briefs)". The three real briefs on main also parse `ok … open` (`L/probe2.txt`).

**Evidence:** `test/scripts/dev-cycle.bats:1192-1205`, `skills/dev-cycle/SKILL.md:328-349`, `L/probe2.txt`, `L/bats-head.txt`

---

## Claim 26: test name "brief_fields reads each machine line's first unfenced copy from main in one pass; check_brief agrees (T31)"

**Location:** `test/scripts/dev-cycle.bats:1207`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers first-unfenced-copy selection for all six keys, the CR-stripped Status, working-tree independence, and check_brief agreeing on status; "in one pass" rests on the code (one awk process, claim 17), not on the test.

**Evidence:** `test/scripts/dev-cycle.bats:1207-1240`, `scripts/lib/dev-cycle-read.sh:286-292`, `L/bats-head.txt`

---

## Claim 27: d6426e3e "Failing tests for U1a …: --check-answer reads … from the default branch's commit (D8), names a non-plain entry on main, and needs a default branch found by name; check_answer needs no ROOT_REAL and leaves SKIPPED alone; brief_fields reads each machine line's first unfenced copy … The symlinked-questions case now commits its symlink."

**Location:** commit d6426e3e (`/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/shared/log.txt:1-8`)
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that d6426e3e's suite, run with its own (main's) lib, fails the new tests 60–64 and the changed tests 34 and 54; does not establish that each failure is for the stated reason (63 fails at need_root, claim 23).

`L/bats-d6426e3e.txt`: `1..64`, `not ok` 34, 54, 60, 61, 62, 63, 64, exit 1. The commit touches only `test/scripts/dev-cycle.bats` (93+/3−), including `git add -A && git commit -qm link` at the symlinked-questions case.

**Evidence:** `L/bats-d6426e3e.txt`, `test/scripts/dev-cycle.bats:649-655`

---

## Claim 28: c8435580 "check_answer reads … from the default branch's commit, never the working tree … It now skips without a default branch found by name, reads only git objects (no ROOT_REAL, nothing added to SKIPPED), and dev-cycle.sh --check-answer exits 1 without such a branch, like --check-brief and --check-branch."

**Location:** commit c8435580 (`shared/log.txt:17-23`)
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers c8435580's lib passing test 63 (`L/bats-c8435580.txt`, `ok 1`) and HEAD passing 60–63; does not establish the fail-closed ls-tree path, which c8435580 lacked (claim 36).

**Evidence:** `L/bats-c8435580.txt`, `L/bats-head.txt`, `scripts/lib/dev-cycle-read.sh:534-560`, `scripts/dev-cycle.sh:191-193`

---

## Claim 29: c8435580 "main_entry PATH: how a path is stored on main (blob, absent, notfile, or notdir PART …), from one `ls-tree -t --full-tree` call, so no reader takes a symlink's target text or reads through a symlinked directory on main."

**Location:** commit c8435580 (`shared/log.txt:26-29`)
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both readers (check_brief, check_answer) gating `cat-file` on `blob`; does not establish fail-closed on ls-tree failure at c8435580 (it printed absent — claim 36).

Test 61 (symlinked questions.md, symlinked docs/working) and probe2 (symlinked briefs dir, c8435580 lib) skip.

**Evidence:** `L/bats-head.txt`, `L/probe2.txt`, `scripts/lib/dev-cycle-read.sh:320-327,539-547`

---

## Claim 30: c8435580 "brief_fields PATH: the first unfenced Status/Branch/Policy/Paths/Asked/Dispatched line, in one FENCE_AWK pass over main's blob, into BRIEF[...]; a refused file sets none and returns 1 with BRIEF_ODD. check_brief now reads its Status line through it, so a brief has one parser (T31)."

**Location:** commit c8435580 (`shared/log.txt:30-34`)
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim at HEAD (claim 17, test 66) and check_brief's call at :328; does not establish value integrity at c8435580 itself, where a NUL inside a line was silently dropped (R1, `L/bats-c8435580.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:281-300,328-338`, `L/bats-head.txt`, `L/bats-c8435580.txt`

---

## Claim 31: c8435580 "check_brief also skips a brief whose directory is not a directory on main (before, ls-tree printed nothing and it read as "new")."

**Location:** commit c8435580 (`shared/log.txt:36-37`)
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a symlinked `docs/working/briefs` on main with a plain working tree; does not establish a gitlink directory.

probe2: main's lib `ok docs/working/briefs/2026-01-01-a.md new`; c8435580/HEAD `skip …: docs/working/briefs is not a directory on the default branch`.

**Evidence:** `L/probe2.txt`

---

## Claim 32: c8435580 "The skill's In flight step notes that answers come from main's commit."

**Location:** commit c8435580 (`shared/log.txt:39`)
**Type:** Reference
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the note's presence under `- **In flight**:` (`skills/dev-cycle/SKILL.md:272`) check 2; does not establish other skill sections.

`both from the default branch's commit` (`skills/dev-cycle/SKILL.md:293`).

**Evidence:** `skills/dev-cycle/SKILL.md:272-297`

---

## Claim 33: c8435580 Notes "a dev cycle run from this repo's scripts/ reads an answer it recorded only in the working tree as open and lists it in the final message; that fails closed."

**Location:** commit c8435580 (`shared/log.txt:42-44`)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both outcomes; does not establish the claim's "installed image copy" sentence (external).

Only when the entry exists on main does it read `open`; an entry not yet on main reads `skip Q-1: no such entry … on the default branch` (`L/probe3.txt`), which the skill records as a skip (`skills/dev-cycle/SKILL.md:302-303`). Both fail closed. The precise version is what 2da477b7 put in the help and SKILL.md ("open, or no such entry"). Commit text is immutable; noted for the record.

**Evidence:** `L/probe3.txt`, `skills/dev-cycle/SKILL.md:302-303`

---

## Claim 34: 2da477b7 "R1/A1: brief_fields read awk's output through $(...), which drops NUL bytes, so "Status: op<NUL>en" read as open (main refused it)."

**Location:** commit 2da477b7 (`shared/log.txt:54-55`)
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers c8435580's and main's output on test 64's fixture; does not establish other dropped bytes (none: claim 17).

c8435580: `ok docs/working/briefs/2026-01-01-n.md open …`; main: `skip …: its first Status: line is not exactly Status: open, done or dropped`.

**Evidence:** `L/bats-c8435580.txt`, `L/bats-main.txt`

---

## Claim 35: 2da477b7 "FENCE_AWK now refuses any line holding a NUL byte ("holds a NUL byte"), so every reader skips such a file and no value loses a byte."

**Location:** commit 2da477b7 (`shared/log.txt:56-57`)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the FENCE_AWK readers (brief_fields/check_brief, check_answer) under mawk; does not establish other awks (claim 11b) or the digest's own readers.

Mechanism and conclusion hold for the readers built on FENCE_AWK (claims 10, 11a, 17). Two qualifiers: "every reader" is only the FENCE_AWK readers — dev-cycle.sh's digest readers use their own awk programs (e.g. `trig()` at `scripts/dev-cycle.sh:263`, the roadmap reader at `:382`) and do not refuse NUL; and "no value loses a byte" excludes the trailing CR that brief_fields drops by design (`after one trailing CR is dropped`, `scripts/lib/dev-cycle-read.sh:271`). Precise version: "every FENCE_AWK reader skips such a file, and no brief_fields value loses a byte beyond the documented trailing CR".

**Evidence:** `scripts/lib/dev-cycle-read.sh:216,271,286-299`, `scripts/dev-cycle.sh:263,382`, `L/probe-main-entry-nul.txt`

---

## Claim 36: 2da477b7 "A2: main_entry printed "absent" when ls-tree failed, which check_brief turned into "ok ... new". It now prints "error" without a default branch found by name or on a failed ls-tree, and both callers skip."

**Location:** commit 2da477b7 (`shared/log.txt:58-60`)
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers old and new behavior for a bad MAIN_SHA through main_entry, check_brief and check_answer (claim 14); does not establish an ls-tree that fails with exit 0.

**Evidence:** `L/probe2.txt`, `L/bats-head.txt`, `scripts/lib/dev-cycle-read.sh:259-261,325,544`

---

## Claim 37: 2da477b7 "A4: the SKIPPED test now has a symlinked archive on main, so it fails against the old working-tree reader."

**Location:** commit 2da477b7 (`shared/log.txt:61-62`)
**Type:** Behavioral
**Verdict:** Incorrect
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the causal claim (the symlink is what makes the test fail against the old reader) and whether the SKIPPED assertion bites; does not establish anything about the test's other assertions, which do pin the new skip text.

The test does fail against main's reader, but at `[ "$status" -eq 0 ]` because need_root exits (ROOT_REAL unset) — and it fails identically with the symlink lines removed (`L/bats-nosym.txt`). The `skipped=0` assertion itself still cannot catch a SKIPPED-appending reader: two such mutants of HEAD's check_answer pass the test (`L/bats-mutA.txt`, `L/bats-mutB.txt`), since the second call runs from `docs/` and the first returns before the loop. Details in claim 23. Iteration 1's A4 (the assertion cannot fail) is therefore still open in substance: it would need ROOT_REAL set and the call made from the root, or a mutant-style check.

**Evidence:** `test/scripts/dev-cycle.bats:1160-1172`, `L/bats-main.txt`, `L/bats-nosym.txt`, `L/bats-mutA.txt`, `L/bats-mutB.txt`

---

## Claim 38: 2da477b7 "T31: a brief written from the skill's template parses."

**Location:** commit 2da477b7 (`shared/log.txt:63`)
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Legibility-target:** for-author
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Same as claim 25 (the fixture omits the template's motive section); does not establish more.

**Evidence:** `test/scripts/dev-cycle.bats:1192-1205`, `skills/dev-cycle/SKILL.md:335-339`

---

## Claim 39: 2da477b7 "Comments: the lib header no longer names a suite that does not exist yet; the default-branch comment names check_answer; the help and SKILL.md say a working-tree-only answer reads open or no such entry."

**Location:** commit 2da477b7 (`shared/log.txt:64-66`)
**Type:** Reference
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each of the three edits being present; does not establish that the lib header's "both callers" wording is precise (claim 6).

`git diff c8435580 2da477b7` shows the header now says `build-loop.sh's suites under test/scripts/ as they land` (:11-12), `:242-243` names check_answer, and `scripts/dev-cycle.sh:58-59` / `skills/dev-cycle/SKILL.md:293-294` carry "open, or no such entry".

**Evidence:** `scripts/lib/dev-cycle-read.sh:10-12,242-244`, `scripts/dev-cycle.sh:57-59`, `skills/dev-cycle/SKILL.md:292-294`

---

## Claim 40: 2da477b7 "Override-log rows: A3 (ls-tree cost, measured 49 entries, Won't-Fix) and T34's build-loop.sh and --marker parts (deferred to U3/U3b)."

**Location:** commit 2da477b7 (`shared/log.txt:68-69`)
**Type:** Reference / Performance
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers rows 220/221 existing with those dispositions and the 49 figure; does not establish the row's per-component-fork cost argument.

`git ls-tree -t --full-tree <rev> -- docs docs/working docs/working/questions.md | wc -l` gives `49` on both main and HEAD (same for the archive path) (paraphrased — no quote available because the count was run inline in the worktree, reproducible with the command given). Rows 220 (`Won't-Fix`, "49 entries from one ls-tree process per lookup") and 221 (`Defer`, U3/U3b) are in `docs/reviews/override-log.md`.

**Evidence:** `docs/reviews/override-log.md:220-221`

---

## Claim 41: 2da477b7 Notes "The NUL refusal is in FENCE_AWK, so dev-cycle.sh's --check-brief and --check-answer refuse such files too (help text updated)."

**Location:** commit 2da477b7 (`shared/log.txt:72-73`)
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both modes end to end through dev-cycle.sh (test 64's first two runs, probe1) and both help lists (:42, :68); does not establish other awks.

**Evidence:** `test/scripts/dev-cycle.bats:1174-1183`, `scripts/dev-cycle.sh:42,68`, `L/bats-head.txt`, `L/probe-main-entry-nul.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 23** (`test/scripts/dev-cycle.bats:1163`): in this fixture the working-tree reader never adds the archive to SKIPPED (it exits in need_root; with need_root stubbed it records `docs/`), and SKIPPED-appending mutants pass the test. The comment, and the assertion it justifies, need ROOT_REAL set and a call from the root to mean anything.
- **Claim 37** (commit 2da477b7, A4 bullet): the test fails against the old reader because need_root exits, with or without the symlink; the `skipped=0` assertion still cannot fail (A4 not discharged in substance).

### Stale
- None.

### Mostly Accurate
- **Claim 6** (`scripts/lib/dev-cycle-read.sh:10-12`): "both callers' suites" — only one caller (dev-cycle.sh) exists; say build-loop.sh's suites join once it lands.
- **Claim 25** (`test/scripts/dev-cycle.bats:1192`): fixture lacks the template's motive section and adds a Date line from real briefs; "shaped like the skill's template".
- **Claim 33** (commit c8435580 Notes): a working-tree-only answer reads `open` only when the entry is on main, else `skip … no such entry` (both fail closed; already fixed in help/SKILL.md).
- **Claim 35** (commit 2da477b7, R1/A1 bullet): "every reader" means FENCE_AWK's readers (not the digest's), and "no value loses a byte" excludes the documented trailing-CR drop.
- **Claim 38** (commit 2da477b7, T31 bullet): same as claim 25.

### Unverifiable
- **Claim 11b** (`scripts/lib/dev-cycle-read.sh:216`): `"\0"` and NUL-bearing input under gawk / BSD one-true-awk / busybox — none installed; needs a run on each. If an awk turns the literal into `""`, every non-empty line is refused (fail closed).

---

## Goal-Alignment Note

- **Goal:** final confirming full-panel review of U1a before merge; this pass fact-checks every changed comment, help line, SKILL.md line and commit message.
- **Met:** all 42 claims verdicted. The R1/A1 NUL fix and the A2 fail-closed fix behave as documented under mawk (executed, including old-lib reproductions); the full suite passes (66/66).
- **Not met / residue:** A4 is not discharged. The test's SKIPPED assertion is still vacuous (claims 23, 37). Two mutants prove it.
- **Escalate:**
  - `test/scripts/dev-cycle.bats:1160-1172`, to orchestrator / test-strategy: the "SKIPPED untouched" assertion cannot fail. Run the check with `ROOT_REAL="$(pwd -P)"` from the repo root, against a fixture with a symlinked file on main.
  - `scripts/lib/dev-cycle-read.sh:216`, to orchestrator (portability; api-consistency-reviewer if the lib is meant to be portable): the NUL check depends on how the awk handles `"\0"`. It has been run only under mawk. Under an awk whose `"\0"` becomes `""`, the check would refuse every non-empty line, which fails closed but takes down every brief and answer. This matters if the scripts run on macOS (BSD awk). Consider `sprintf("%c", 0)`, or check that `length("\0") == 1` in BEGIN and fail closed loudly if not.
