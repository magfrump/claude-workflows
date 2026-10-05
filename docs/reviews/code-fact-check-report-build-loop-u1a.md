Commit: 2da477b7

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u1a (claude-workflows, branch feat/build-loop-u1a)
**Scope:** `git diff main...feat/build-loop-u1a` (d6426e3e, c8435580, 2da477b7) over scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, skills/dev-cycle/SKILL.md, test/scripts/dev-cycle.bats, plus the three commit messages. docs/reviews/ files are not under review.
**Checked:** 2026-10-05
**Commit:** 2da477b7
**Replication:** k=3
**Total claims checked:** 54
**Summary:** 42 verified, 9 mostly accurate, 0 stale, 2 incorrect, 1 unverifiable

Merged most-severe-wins from `code-fact-check-report-build-loop-u1a-r1.md` (42 claims), `-r2.md` (30) and `-r3.md` (31), all stamped `Commit: 2da477b7`, numbered on r1 (the finest granularity). Every replicate ran the suite at HEAD (66/66) and probed under mawk 1.3.4; per-replicate execution logs are in `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/fc{1,2,3}/`. Evidence below is r1's unless a claim's verdict was won by another replicate, whose reasoning is then in the annotations field.

## Claim 1: "a stray carriage return, a NUL byte, or a byte-order mark on line 1" (--check-brief refusal list)

**Location:** `scripts/dev-cycle.sh:42`
**Type:** Behavioral
**Verdict:** Verified
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
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
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
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
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
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
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
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
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified
**Replicate annotations:** none
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
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
**Replicate annotations:** r1: "only one caller exists; build-loop.sh has not landed" (MA)
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
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
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
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
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
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
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
**Verdict:** Mostly accurate
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r2: "fence() refuses NUL (and CR, BOM) inside fences too: a NUL between ``` lines gives odd 2 nul; the header lists them after 'outside a fence' — say 'anywhere in the file'" (scripts/lib/dev-cycle-read.sh:174-176)
**Legibility-target:** for-author
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
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: under mawk 1.3.4 "\0" is a one-byte NUL; NUL lines reach awk intact; fires at line start/middle/end/inside a fence, never on NUL-free lines
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
**Replicate verdicts:** r1=Unverifiable · r2=— · r3=Unverifiable
**Replicate annotations:** r1+r2+r3: in an awk whose strings stop at NUL (BWK/one-true-awk, busybox) "\0" may be "" and index(s,"") may be 1, so every non-empty line would be refused: fails closed, but every brief and answer is skipped (reasoning only; none installed). r1: fix by sprintf("%c",0) or a BEGIN check length("\0")==1
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
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
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
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** none
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
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: ls-tree exits 128 on a bad commit, 0 with empty output for a missing path; only callers check_brief and check_answer both skip on error
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
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "the call also lists each named directory's children" (49 entries; override row 220)
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
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that pathform's alphabet (`NAMECHARS='abc…XYZ0123456789._/-'`, :139) contains no character git quotes under core.quotePath, and that both callers pass pathform-clean paths (check_brief via :313, check_answer fixed literals); does not establish pathspec-magic safety in a caller without dev-cycle.sh's `GIT_LITERAL_PATHSPECS=1` (:125) — pathform also excludes `*`/`?` there unless glob mode, so none arises today.

**Evidence:** `scripts/lib/dev-cycle-read.sh:139-149,313,538`, `scripts/dev-cycle.sh:125`

---

## Claim 17: brief_fields contract — "for each key, the first line outside a fence … whole, after one trailing CR is dropped … (a key with no such line stays unset) … empties BRIEF_ODD … sets no key and returns 1, with BRIEF_ODD "odd N WHY" … or "unbalanced N" …; a NUL byte is refused too, so each value is the line as stored"

**Location:** `scripts/lib/dev-cycle-read.sh:268-279`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r3: "each value is the line as stored" is not exact: one trailing CR is dropped (stated earlier in the same comment; test 66); the NUL clause sits inside the "unbalanced N" parenthetical though it concerns "odd N nul" (MA) · r2: values byte-for-byte (TAB, UTF-8, 0xff, backslash) minus the one trailing CR · r1: Branch value with every byte 0x01-0xFF except LF/CR byte-identical · r2: if git cat-file fails while brief_fields is called inside `if !`, set -e is off and it returns 0 with no keys set; check_brief turns that into a skip (safe today), a U1b caller skipping main_entry would see keys unset (scripts/lib/dev-cycle-read.sh:286, escalated to security-reviewer)
**Legibility-target:** for-author
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
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
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
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
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
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
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
**Verdict:** Mostly accurate
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r2: kept phrase "once step 1 has archived an entry, questions-archive.md" no longer matches: an entry archived this cycle is still read from main's questions.md until the cycle lands, and main's archive is read whenever it exists there (skills/dev-cycle/SKILL.md:292-293)
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both outcomes (claim 2's runs); does not establish the unchanged clause "once step 1 has archived an entry, `questions-archive.md`" — an entry archived only in the working tree is not read from the archive until that lands (main's questions.md still has it, so the answer is unaffected).

**Evidence:** `skills/dev-cycle/SKILL.md:289-297`, `L/probe3.txt`, `L/bats-head.txt`

---

## Claim 22: test name "check_answer reads git only: no ROOT_REAL needed, SKIPPED untouched, skip without main by name"

**Location:** `test/scripts/dev-cycle.bats:1160`
**Type:** Behavioral
**Verdict:** Verified
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** none
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
**Replicate verdicts:** r1=Incorrect · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: with ROOT_REAL set the old reader gives skipped=1 (probe sets ROOT_REAL, which the test does not) · r3: the test fails against main's reader at the ROOT_REAL check before reaching the SKIPPED assertion · r1: two SKIPPED-appending mutants of HEAD's check_answer pass the test because the second call runs from docs/
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
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: test 64 fails against c8435580's lib (`ok … open` for Status: op<NUL>en)
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
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r1+r2: fixture has no Motive section (the skill's template lists one) and its Date line comes from real briefs; it still parses · r3: the three real briefs on main also parse
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
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
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
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: against main's scripts tests 34, 54, 60-64 fail
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
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** none
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
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** none
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
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** none
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
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** none
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
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified (compound)
**Replicate annotations:** none
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
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r1: an entry absent from main reads skip … no such entry, not open; both fail closed; help and SKILL.md already fixed
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
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** none
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
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r1+r3: only the FENCE_AWK readers (check_brief/brief_fields, check_answer) skip; dev-cycle.sh's digest readers (r1: :263, :382; r3: section 3 via scripts/questions.sh, :328-361) list a questions.md holding a NUL instead of skipping it · r1: brief_fields also drops a trailing CR by design
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
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** none
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
**Replicate verdicts:** r1=Incorrect · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** same residue as claim 23
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
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate (compound) · r3=—
**Replicate annotations:** same as claim 25
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
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—
**Replicate annotations:** none
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
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified
**Replicate annotations:** r1+r3: 49 entries re-measured at main and HEAD
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
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=—
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both modes end to end through dev-cycle.sh (test 64's first two runs, probe1) and both help lists (:42, :68); does not establish other awks.

**Evidence:** `test/scripts/dev-cycle.bats:1174-1183`, `scripts/dev-cycle.sh:42,68`, `L/bats-head.txt`, `L/probe-main-entry-nul.txt`

---

---

## Claim 42: r2 claim 18 — "The caller has checked main_by_name and that the path is a blob on main (main_entry), and calls it in its own shell: it sets globals."

**Location:** `scripts/lib/dev-cycle-read.sh:277-279`
**Type:** Behavioral
**Verdict:** Verified
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** none (r1 claim 17 and r3 claim 16 cover the same contract compound)
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers check_brief as the one caller in this diff; does not establish U1b's callers.

check_brief calls main_entry first and brief_fields only on `blob` (r2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:318-327` (r2)

---

## Claim 43: r3 claim 22 — d6426e3e "The symlinked-questions case now commits its symlink."

**Location:** `test/scripts/dev-cycle.bats:652`
**Type:** Behavioral
**Verdict:** Verified
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the test's setup line; nothing about other symlink cases.

The test commits the symlink before calling --check-answer (r3).

**Evidence:** `test/scripts/dev-cycle.bats:652` (r3)

---

## Submitted Claims

Stage 2.5 (k=1, opus): critics' routed endorsement claims, verdicted in `code-fact-check-submitted-claims-build-loop-u1a.md` as Claims 45-53 and renumbered here 44-52 to continue this report (submitted 45 → 44, 46a/46b → 45a/45b, … 53 → 52).

## Claim 44: "the branch's `--check-answer` and `--check-brief` run within ±15% of main's wall-clock time, and `check_brief` output is identical to main's on the repo's real briefs"

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:286-299`, `scripts/lib/dev-cycle-read.sh:538-547`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers wall-clock time of one `dev-cycle.sh --check-brief` call over the repo's three real briefs and one `--check-answer` call over eight real IDs (Q-001..003, Q-104..108), main's scripts vs the branch's, on this machine, plus byte-identical `--check-brief` (and `--check-answer`) output on those inputs; does not establish timing on a larger docs/ tree or history, on a closed/ brief (none exists), under gawk, or under build-loop.sh's future per-brief `--status` calls.

Command: `./bench.sh` (cwd `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/submitted`; the script `cd`s to the worktree and runs each script 15 times per mode, two alternating rounds), started 2026-10-05T11:18:06Z, exit 0 for every run (`rc=0` in each line). Output:

```
main brief N=15 total_ms=672 per_ms=44 rc=0
main answer N=15 total_ms=1546 per_ms=103 rc=0
branch brief N=15 total_ms=727 per_ms=48 rc=0
branch answer N=15 total_ms=1512 per_ms=100 rc=0
main brief N=15 total_ms=715 per_ms=47 rc=0
main answer N=15 total_ms=1591 per_ms=106 rc=0
branch brief N=15 total_ms=731 per_ms=48 rc=0
branch answer N=15 total_ms=1534 per_ms=102 rc=0
```

Branch vs main per call: `--check-brief` 48/44 = +9% and 48/47 = +2%; `--check-answer` 100/103 = -3% and 102/106 = -4%. All within ±15%. `diff out-main-brief.txt out-branch-brief.txt` printed nothing (`BRIEF_IDENTICAL`); both print, for all three briefs, `ok docs/working/briefs/<name>.md open cac2ba0cdc350c163fa530b0fa868c84c574406b`. The `--check-answer` outputs were also identical (empty `diff`), which holds here only because the worktree's questions files match main's for those IDs. Confidence is Medium because the sample is 2 × 15 runs on a shared machine and only three briefs, all `open`, exist.

**Evidence:** `scripts/lib/dev-cycle-read.sh:281-300`, `scripts/lib/dev-cycle-read.sh:309-347`, `scripts/lib/dev-cycle-read.sh:534-560`; captured output `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/submitted/bench-output.txt`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/submitted/out-main-brief.txt`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/submitted/out-branch-brief.txt`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/submitted/bench.sh`

---

## Claim 45a: "check_answer as changed discharges override-log rows 206 ... and 217"

**Submitted by:** architecture-review
**Location:** `scripts/lib/dev-cycle-read.sh:534-556`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers row 206 (check_answer read questions.md from the working tree) and row 217 (check_answer appended to SKIPPED via `skipped`), both checked against the rewritten function and its tests; does not establish anything about build-loop.sh's future callers (U3).

Row 206 (`docs/reviews/override-log.md:206`) reads: "check_answer, now in the shared lib, reads questions.md from the working tree (F28) ... Revisit trigger: U1." Row 217 (`:217`) reads: "check_answer appends to SKIPPED via skipped; check_brief does not ... the side effect goes with it. Revisit trigger: U1."

The rewritten function reads only main's commit and no longer calls `skipped`:

```bash
# scripts/lib/dev-cycle-read.sh:538-547
  for f in docs/working/questions.md docs/working/questions-archive.md; do
    e="$(main_entry "$f")"
    case "$e" in
      absent) continue ;;
      blob) ;;
      ...
    esac
    r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk -v id="$a" "$FENCE_AWK$ANSWER_AWK")"
```
(excerpt ends :547; enclosing check_answer() continues to :560 — read; the rest only interprets `r` and prints.)

`grep -n 'skipped ' scripts/lib/dev-cycle-read.sh` finds `skipped` defined at `:125` and called nowhere inside `check_answer` (paraphrased — no quote available because the claim covers absence of code: no `skipped` call in `:534-560`). The bats test "check_answer reads git only: no ROOT_REAL needed, SKIPPED untouched, skip without main by name" passed and asserts `skipped=0` with a symlinked archive on main; "--check-answer reads main's commit: a working-tree or branch-only answer is open (T34)" passed. Command: `bats --filter '<7 U1a test names>' test/scripts/dev-cycle.bats` (cwd `/workspace/.claude/wt-build-loop-u1a`, `LC_ALL=C.UTF-8`), 2026-10-05T11:18:22Z, exit 0, 7/7 ok. My probe P4 (`probe.sh`, 2026-10-05T11:18:46Z, exit 0) made a scratch repo's `docs/working` mode 000 and `--check-answer Q-1` still printed `keep Q-1` from main's commit.

**Evidence:** `docs/reviews/override-log.md:206`, `docs/reviews/override-log.md:217`, `scripts/lib/dev-cycle-read.sh:125`, `scripts/lib/dev-cycle-read.sh:528-560`, `test/scripts/dev-cycle.bats:393-405`; captured output `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/submitted/bats-targeted.txt`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/submitted/probe-output.txt`

---

## Claim 45b: "check_answer as changed discharges override-log row ... 216"

**Submitted by:** architecture-review
**Location:** `scripts/lib/dev-cycle-read.sh:534-537`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two parts of row 216 that check_answer itself can carry (add main_by_name; no longer exit via need_root); does not establish row 216's "accept only a positive line" part, which is an obligation on U3's `--approved` capture and is met here only by header guidance.

Row 216 (`docs/reviews/override-log.md:216`) reads: "check_answer is print-only and exits via need_root; --approved will capture it as a merge authorisation, so U1's rewrite should accept only a positive line and add main_by_name". The rewrite adds the gate:

```bash
# scripts/lib/dev-cycle-read.sh:537
  if ! main_by_name; then echo "skip $a: no default branch found by name (origin/HEAD, main or master), or resolve_main has not run"; return; fi
```

and no longer calls `need_root` (the only `need_root` calls in the file are at `:121`, `:124`, `:125`, `:311` and `:420`; paraphrased — no quote available because the claim covers absence of a call in `:534-560`). The "accept only a positive line" part is not something check_answer can enforce: it still prints non-positive answer lines (`open`, `unrecognized`) and skip lines, and the safe-capture rule lives in the lib header, `scripts/lib/dev-cycle-read.sh:24-27`: "check_branch and check_answer answer with one printed line per argument ... treat any line that is not a positive answer as a refusal." So the row's U1 parts are discharged; its positive-line part remains with the consumer (U3 `--approved`), which does not exist yet. "Discharges" is right for what U1 can do but imprecise as a statement about the whole row.

**Evidence:** `docs/reviews/override-log.md:216`, `scripts/lib/dev-cycle-read.sh:22-27`, `scripts/lib/dev-cycle-read.sh:534-560`

---

## Claim 46: "check_brief now reads its Status line through brief_fields, so briefs have one parser"

**Submitted by:** architecture-review, api-consistency-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:327-337`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the only code reading a brief's machine-line values (Status here; Branch/Policy/Paths/Asked/Dispatched for U1b) is brief_fields' single awk pass, and that no other script in `scripts/` parses brief lines; does not establish that check_brief's commit lookup (`git log -G'^Status: '`, which matches any Status line, fenced or not, by design) uses that parser, nor how future U1b consumers judge the values.

```bash
# scripts/lib/dev-cycle-read.sh:328-337
  if ! brief_fields "$a"; then
    case "$BRIEF_ODD" in
      ...
    esac
    return
  fi
  st="${BRIEF[status]-}"
  if [[ ! "$st" =~ ^Status:\ (open|done|dropped)$ ]]; then
```
(excerpt ends :337; enclosing check_brief() continues to :347 — read.) The old inline awk (`!seen && /^Status:/ ...`) is removed in the diff. After `:337` check_brief reads no further brief text: `:344` runs `git log -1 --format=%H --first-parent --diff-merges=first-parent -s -G'^Status: ' "$MAIN_SHA" -- "$a"` to pick the commit, a history search rather than a value parse (its comment at `:339-343` says "Any such line counts (a quoted one ...)"). `rg -n 'briefs' scripts/` outside the lib finds only dev-cycle.sh comments and `skipdir docs/working/briefs` (`scripts/dev-cycle.sh:461`), and the one other `^Status:` match, `scripts/questions.sh:179`, parses question entries, not briefs (paraphrased — no quote available because the claim covers absence of other brief parsers across `scripts/`). Bats tests "brief_fields reads each machine line's first unfenced copy ... check_brief agrees (T31)" and the template test passed (see Claim 46a's run).

**Evidence:** `scripts/lib/dev-cycle-read.sh:281-300`, `scripts/lib/dev-cycle-read.sh:309-347`, `scripts/dev-cycle.sh:461`, `scripts/questions.sh:179`

---

## Claim 47: "main_entry prints `error`, never `absent`, when ls-tree fails or there is no default branch found by name, and both callers (check_brief, check_answer) skip on `error`"

**Submitted by:** architecture-review, api-consistency-reviewer, security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:256-267`, `scripts/lib/dev-cycle-read.sh:320-326`, `scripts/lib/dev-cycle-read.sh:539-545`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main_entry's two error branches (main_by_name false; ls-tree non-zero exit, exercised with an unset MAIN_BY_NAME, a missing object, a short unknown SHA and a blob SHA) and the two callers' `error)` arms; does not establish behavior when ls-tree exits 0 but prints a truncated listing, or the handling of ls-tree's unscrubbed stderr (`fatal: ...`), which reaches the caller's stderr.

```bash
# scripts/lib/dev-cycle-read.sh:259-261
  main_by_name || { echo error; return; }
  while [[ "$rest" == */* ]]; do p="${p:+$p/}${rest%%/*}"; rest="${rest#*/}"; want+=("$p"); done
  out="$(git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1")" || { echo error; return; }
```
(excerpt ends :261; enclosing main_entry() continues to :267 — read; `absent` is printed only at `:264` and `:266`, after a successful ls-tree.) Callers: `scripts/lib/dev-cycle-read.sh:325` `error) echo "skip $a: the default branch's tree could not be read"; return ;;` and `:544` `error) echo "skip $a: the default branch's tree could not be read, so $f is not read"; return ;;`. `grep main_entry` finds no other caller in `scripts/` (paraphrased — no quote available because the claim covers absence of further call sites).

Probe P3 (`./probe.sh`, cwd the scratch dir, 2026-10-05T11:18:46Z, exit 0) printed: `before resolve_main: error`, `by name: blob`, `absent path: absent`, `MAIN_SHA=a blob: error`, `MAIN_SHA=short unknown: error`, `MAIN_BY_NAME empty: error`, `check_answer, bad sha: skip Q-1: the default branch's tree could not be read, so docs/working/questions.md is not read`. The bats test "a NUL byte refuses ... main_entry fails closed" (all-zero MAIN_SHA) passed in the run under Claim 46a.

**Evidence:** `scripts/lib/dev-cycle-read.sh:256-267`, `scripts/lib/dev-cycle-read.sh:320-326`, `scripts/lib/dev-cycle-read.sh:539-545`, `test/scripts/dev-cycle.bats:407-423`; captured output `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/submitted/probe-output.txt`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/submitted/p3-stderr.txt`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/submitted/bats-targeted.txt`

---

## Claim 48: "the NUL refusal sits in the shared FENCE_AWK, so every FENCE_AWK reader refuses such a file"

**Submitted by:** architecture-review
**Location:** `scripts/lib/dev-cycle-read.sh:216`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both FENCE_AWK readers that exist (brief_fields, and so check_brief; check_answer via ANSWER_AWK) under mawk 1.3.4, with a NUL at line start, mid-file, inside a fence, in an unterminated last line and as a run of NULs; does not establish the behavior under gawk or another awk (not installed here; the lib runs whatever `awk` is on PATH), nor readers U1b/U3 add later.

```awk
# scripts/lib/dev-cycle-read.sh:214-217
  if (odd) return 1   # the file is already refused: nothing after it is read
  if (index(l, "\r")) { refuse("cr"); return 1 }
  if (index(l, "\0")) { refuse("nul"); return 1 }  # $(...) drops NUL, so a printed line would not be the line read
  if (NR == 1 && substr(l, 1, 3) == "\357\273\277") { refuse("bom"); return 1 }
```
(excerpt ends :217; enclosing fence() continues to :229 — read.) The check runs before the `infence` branch at `:218`, so fenced lines are covered too. `grep -n FENCE_AWK scripts/*.sh scripts/lib/*.sh` shows the two awk invocations, `scripts/lib/dev-cycle-read.sh:286` (brief_fields) and `:547` (check_answer); dev-cycle.sh mentions it only in a comment (`scripts/dev-cycle.sh:88`). Both END blocks print `odd` first (`:292`, `:522`).

Probe P1/P2 (`./probe.sh`, 2026-10-05T11:18:46Z, exit 0): brief variants with NUL at line 2, line 3, inside a fence, as an unterminated last line and as `\0\0\0` each printed `skip ...: line N holds a NUL byte, so the brief is not read`; a NUL-free control printed `ok ... open <sha>`; a questions file with a NUL inside a fence printed `skip Q-1: line 6 of docs/working/questions.md holds a NUL byte, so no entry in docs/working/questions.md is read`, and its clean control `keep Q-1`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:186-230`, `scripts/lib/dev-cycle-read.sh:286-292`, `scripts/lib/dev-cycle-read.sh:521-527`, `scripts/lib/dev-cycle-read.sh:547`, `scripts/dev-cycle.sh:88`; captured output `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/submitted/probe-output.txt`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/submitted/probe.sh`

---

## Claim 49: "scripts/dev-cycle.sh has a single main-by-name gate for the --check-* modes"

**Submitted by:** architecture-review
**Location:** `scripts/dev-cycle.sh:191`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that dev-cycle.sh tests main_by_name at exactly one place, for --check-brief, --check-branch and --check-answer together; does not establish that --check-path, --check-write or --check-fix are gated (they are not, by design: they do not read main), and does not count the lib's own per-function main_by_name guards.

```bash
# scripts/dev-cycle.sh:191-193
if [[ "$CHECK" == --check-brief || "$CHECK" == --check-branch || "$CHECK" == --check-answer ]] && ! main_by_name; then
  echo "$CHECK needs a default branch (origin/HEAD, main or master); found none" >&2; exit 1
fi
```
`grep -n 'main_by_name\|MAIN_BY_NAME' scripts/dev-cycle.sh` returns only line 191 (paraphrased — no quote available because the claim covers absence of any other gate). The dispatch loop follows at `:194-204`. The lib functions also skip without main by name (`scripts/lib/dev-cycle-read.sh:312`, `:359`, `:537`), a second layer, not a second gate in dev-cycle.sh.

**Evidence:** `scripts/dev-cycle.sh:186-204`, `scripts/lib/dev-cycle-read.sh:312`, `scripts/lib/dev-cycle-read.sh:359`, `scripts/lib/dev-cycle-read.sh:537`

---

## Claim 50: "the --check-answer behaviour change (reads main's commit) is documented in the help text, its Exit line, `skills/dev-cycle/SKILL.md:291-294` and the commit notes, and `skills/dev-cycle/SKILL.md:100-101` covers the new exit 1"

**Submitted by:** api-consistency-reviewer
**Location:** `scripts/dev-cycle.sh:56-80`, `skills/dev-cycle/SKILL.md:100-101`, `skills/dev-cycle/SKILL.md:291-294`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four named places and that `--help` actually prints the changed lines including the Exit line; does not establish that every other doc naming --check-answer (for example docs outside the skill) was updated, nor the installed image copy (the commit notes say it is unchanged until a release).

Command: `bash scripts/dev-cycle.sh --help` (cwd `/workspace/.claude/wt-build-loop-u1a`), 2026-10-05T11:18:55Z, exit 0. Its output includes "from docs/working/questions.md or its archive on the default branch's commit (an answer only in the working tree reads open, or no such entry, until it is committed there)", "--check-brief, --check-branch and --check-answer need a default branch found by name", and ends with the Exit line "default branch (for the digest, --check-brief, --check-branch and --check-answer); a failed step exits non-zero mid-digest. Printed repo text is data." (help output lines 77-79; the `sed -n '2,80p'` range at `scripts/dev-cycle.sh:110` reaches the Exit line's end at `:80`). `skills/dev-cycle/SKILL.md:292-293` reads "both from the default branch's commit (an answer recorded only in the working tree reads `open`, or no such entry, until it lands)". `skills/dev-cycle/SKILL.md:100-101` reads "A check that exits non-zero (no default branch, say) is recorded, and the step that needed it stops." (pre-existing text that covers any check mode's exit 1). Commit c8435580's body says "check_answer reads docs/working/questions{,-archive}.md from the default branch's commit ... dev-cycle.sh --check-answer exits 1 without such a branch".

**Evidence:** `scripts/dev-cycle.sh:56-60`, `scripts/dev-cycle.sh:70-71`, `scripts/dev-cycle.sh:78-80`, `scripts/dev-cycle.sh:110`, `skills/dev-cycle/SKILL.md:100-101`, `skills/dev-cycle/SKILL.md:291-294`, commit c8435580; captured output `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/submitted/help-output.txt`

---

## Claim 51: "check_answer reads only `MAIN_SHA:<constant path>` objects and never a working-tree path"

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:538-547`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_answer's file inputs: the loop's two literal paths, read only through `git ls-tree` on MAIN_SHA (main_entry) and `git cat-file blob "$MAIN_SHA:$f"`, with awk reading stdin only; does not establish git-level indirection inside the object store (for example `refs/replace/` objects, which cat-file honors) or what MAIN_SHA names when a caller sets it by hand rather than through resolve_main.

```bash
# scripts/lib/dev-cycle-read.sh:538-547
  for f in docs/working/questions.md docs/working/questions-archive.md; do
    e="$(main_entry "$f")"
    ...
    r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk -v id="$a" "$FENCE_AWK$ANSWER_AWK")"
```
(excerpt ends :547; enclosing check_answer() continues to :560 — read; the remaining lines only compare `r`, `hit` and `where` and print.) `f` is only ever one of the two literals; awk receives no file operand, so it reads the pipe. main_entry reads only `git ls-tree -t --full-tree "$MAIN_SHA" ...` (`:261`). Because the paths have no `./` prefix, `<rev>:<path>` resolves from the tree root, not the current directory, and the test that runs check_answer after `cd docs` passed. Probe P4 (`probe.sh`, 2026-10-05T11:18:46Z, exit 0): with the scratch repo's working `docs/working` at mode 000, `--check-answer Q-1` printed `keep Q-1`. The T34 bats test (working-tree-only and side-branch answers read `open`) passed (Claim 46a's run).

**Evidence:** `scripts/lib/dev-cycle-read.sh:256-267`, `scripts/lib/dev-cycle-read.sh:534-560`, `test/scripts/dev-cycle.bats:351-368`, `test/scripts/dev-cycle.bats:393-405`; captured output `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/submitted/probe-output.txt`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/submitted/bats-targeted.txt`

---

## Claim 52: "the `git cat-file blob "$MAIN_SHA:…"` argument cannot be parsed as an option, because it starts with the hex MAIN_SHA"

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:286`, `scripts/lib/dev-cycle-read.sh:547`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the argument's first character whenever MAIN_SHA was set by resolve_main (the only setter in the lib; it is reset to "" at source time, so the environment cannot preset it) and the guards before each call; does not establish behavior if a caller assigns MAIN_SHA itself, or brief_fields called with an empty MAIN_SHA (no own guard: the argument becomes `:<path>`, which is not an option but reads the index entry instead of main).

MAIN_SHA is assigned only in resolve_main, from `rev-parse --verify`:

```bash
# scripts/lib/dev-cycle-read.sh:386-388
    sha="$(git show-ref --verify --hash "refs/heads/$c" 2>/dev/null || true)"
    [[ -z "$sha" ]] || sha="$(git rev-parse --verify --quiet "$sha^{commit}" 2>/dev/null || true)"
    if [[ -n "$sha" ]]; then MAIN="$c"; MAIN_SHA="$sha"; MAIN_BY_NAME=1; break; fi
```
(excerpt ends :388; enclosing resolve_main() continues to :398 — read; the fallback at `:394` also takes `git rev-parse --verify --quiet HEAD`.) The lib resets it on source: `scripts/lib/dev-cycle-read.sh:245` `MAIN=""; MAIN_SHA=""; MAIN_BY_NAME=""`. check_answer reaches `:547` only after `main_by_name` (`:537`), which requires a non-empty MAIN_SHA (`:246`); brief_fields' only caller, check_brief, checks main_by_name at `:312`. Probe P5 printed `byname MAIN_SHA=6df09f6d31da324b6b86e6b1d5f83e6cd219a26d` and the same 40-hex form for the current-branch fallback (supporting evidence only; the verdict rests on reading). Under the claim's premise (a hex prefix) a leading `-` is impossible. The residue in Scope is the unguarded brief_fields entry point.

**Evidence:** `scripts/lib/dev-cycle-read.sh:245-246`, `scripts/lib/dev-cycle-read.sh:281-300`, `scripts/lib/dev-cycle-read.sh:309-312`, `scripts/lib/dev-cycle-read.sh:376-398`, `scripts/lib/dev-cycle-read.sh:537-547`; supporting output `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/submitted/probe-output.txt`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 46b** (`scripts/lib/dev-cycle-read.sh:534-537`): row 216's main_by_name and need_root parts are discharged; its "accept only a positive line" part stays with U3's `--approved` consumer (header guidance only). Say "discharges row 216's U1 part".

### Unverifiable
(none)

## Legibility notes

- Claim 45 holds on a small sample (three open briefs, 2 × 15 runs). The +9% upper reading for `--check-brief` is the closest to the ±15% bound.
- Claim 49 holds under mawk only. gawk is not installed, so `index(l, "\0")` was not run under gawk.
- Claim 53's residue: brief_fields does not guard itself. Called with an empty MAIN_SHA it would read the index's copy of the file (`:<path>`) rather than main's. Its comment puts the main_by_name check on the caller, and its only caller does that check.

---

## Claims Requiring Attention

### Incorrect
- **Claim 23** (`test/scripts/dev-cycle.bats:1163`, high, executed, r1): the `skipped=0` assertion of test 63 still cannot catch a SKIPPED-appending reader: two such mutants of HEAD's check_answer pass, because the second call runs from `docs/` and ROOT_REAL is unset. r2/r3 verified the test fails against main's reader, but it fails at need_root, not at the SKIPPED assertion.
- **Claim 37** (commit 2da477b7, A4 bullet, high, executed, r1): the test fails against the old reader with or without the symlink; iteration 1's A4 is not discharged in substance.

### Stale
- None.

### Mostly Accurate
- **Claim 6** (`scripts/lib/dev-cycle-read.sh:10-12`): "both callers' suites" while only one caller exists.
- **Claim 10** (`scripts/lib/dev-cycle-read.sh:174-176`, r2): NUL/CR/BOM are listed after "outside a fence" but are refused anywhere in the file.
- **Claim 17** (`scripts/lib/dev-cycle-read.sh:275-277`, r3): "each value is the line as stored" except the one trailing CR dropped; the NUL clause sits inside the "unbalanced N" parenthetical.
- **Claim 21** (`skills/dev-cycle/SKILL.md:292-293`, r2): "once step 1 has archived an entry, questions-archive.md" no longer matches reading from main.
- **Claim 25** (`test/scripts/dev-cycle.bats:1192`) and **Claim 38** (2da477b7 T31 bullet): the fixture is not the skill's template (no Motive section).
- **Claim 33** (c8435580 Notes): a working-tree-only answer reads `open` or `skip … no such entry`.
- **Claim 35** (2da477b7 R1/A1 bullet): only FENCE_AWK readers skip a NUL file; the digest's questions readers do not.

### Unverifiable
- **Claim 11b** (`scripts/lib/dev-cycle-read.sh:216`): `"\0"` under gawk / one-true-awk / busybox; none installed. If an awk makes it `""`, every non-empty line is refused (fails closed).

## Escalations

1. `scripts/lib/dev-cycle-read.sh:216` — portability: in an awk whose strings stop at NUL, `"\0"` may be empty and the check would refuse every non-empty line (every brief and answer skipped; fails closed). Raised by r1, r2, r3. Addressee: api-consistency-reviewer / orchestrator.
2. `test/scripts/dev-cycle.bats:1160-1172` — the SKIPPED-untouched assertion cannot fail; needs ROOT_REAL set and the call made from the root, or a mutant-style check. Raised by r1. Addressee: orchestrator / test-strategy.
3. `scripts/lib/dev-cycle-read.sh:286` — if `git cat-file` fails while brief_fields runs under `if !`, set -e is off and it returns 0 with no keys set; check_brief skips (safe today), a U1b caller without the main_entry check would see every key unset. Raised by r2. Addressee: security-reviewer.
4. `scripts/dev-cycle.sh:263`, `:328-361`, `:382` — the digest's questions readers (via scripts/questions.sh) list a questions.md holding a NUL instead of skipping it. Raised by r1, r3 (as claim residue). Addressee: orchestrator.

## Verdict stability

- Clusters: 44 (42 from r1's numbering plus 2 single-replicate claims).
- All reporting replicates agreed: 36.
- Disagreed (8): claim 6 (r1=MA, r2=V, r3=V); 10 (r1=V, r2=MA, r3=V); 17 (r1=V, r2=V, r3=MA); 21 (r1=V, r2=MA, r3=V); 23 (r1=Incorrect, r2=V, r3=V); 25 (r1=MA, r2=MA, r3=V); 35 (r1=MA, r2=V, r3=MA); 37 (r1=Incorrect, r2=V, r3=V).
- Agreement rate: 36/44 = 82% (below the ≥90% falsifier; k stays 3).
