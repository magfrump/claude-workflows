Commit: 4aa2e98e

# Code Fact-Check Report

**Repository:** claude-workflows (worktree /workspace/.claude/wt-build-loop-u1a, branch feat/build-loop-u1a)
**Scope:** branch diff `git diff main...feat/build-loop-u1a` (code files: scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, skills/dev-cycle/SKILL.md, test/scripts/dev-cycle.bats) plus commit messages `git log main..HEAD`; replicate r3 of the iteration-4 confirming pass
**Checked:** 2026-10-05
**Total claims checked:** 32
**Summary:** 29 verified, 3 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Execution provenance (shared by every `executed` claim below; cwd for each is the scratch dir
`/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i4/fc-r3/`, which holds `git archive HEAD scripts test`
copies of the branch at 4aa2e98e: `base/` unmodified and four mutants):

| ID | Command (cwd: fc-r3/) | Exit | UTC time | Captured output |
|---|---|---|---|---|
| E1 | `bash /workspace/.claude/wt-build-loop-u1a/scripts/dev-cycle.sh --help` | 0 | 2026-10-05T16:31:01Z | `logs/help.out`, `logs/help.err` |
| E2 | `(cd base && LC_ALL=C.UTF-8 bats test/scripts/dev-cycle.bats)` (TMPDIR unset) | 0 (68/68 ok) | 2026-10-05T16:31:14Z | `logs/bats-base.out` |
| E3 | `(cd help80 && bats -f 'help prints the whole header' ...)`, mutant: help sed restored to `'2,80p'` | 1 | 2026-10-05T16:31:14Z+ | `logs/bats-help80.out` |
| E4 | same filter on `help77/` (control: `'2,81p'`, the true header end) | 0 | same run | `logs/bats-help77.out` |
| E5 | `(cd ans_nopf && bats -f 'unreadable blob' ...)`, mutant: check_answer's `local -` and `set -o pipefail` removed | 1 | same run | `logs/bats-ans_nopf.out` |
| E6 | `(cd bf_nopf && bats -f 'unreadable blob' ...)`, mutant: brief_fields' `local -` and `set -o pipefail` removed | 1 | same run | `logs/bats-bf_nopf.out` |
| E7 | `timeout 60 bash localdash.sh` (caller options before/after check_answer and brief_fields under no options, `set -eu`, `set -euo pipefail`; `local -` restoring `set -e`/`-x`) | 0 | 2026-10-05T16:31:54Z | `logs/localdash.out` |
| E8 | `timeout 60 bash probe2.sh` (awk identity; git's read of a doubled tree name; FENCE_AWK on fenced NUL/CR and a line-2 BOM) | 0 | 2026-10-05T16:32:47Z | `logs/probe2.out` |
| E9 | sed range probes on `hdr.sh` / `hdr2.sh` (a blank line inside a header; a non-comment line 2), GNU sed 4.x and `sed --posix` | 0 | 2026-10-05T16:31:01Z | inline below (claim 7b) |

All captured files are under `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i4/fc-r3/`. The
`setlocale` warnings in the logs come from the sandbox's LC_ALL and are unrelated. The hallucination
pattern log (`docs/reviews/hallucination-patterns.md`, 5 patterns) was read; no claim below matches a
logged pattern.

---

## Claim 1: "a stray carriage return, a NUL byte, or a byte-order mark on line 1" (--check-brief and --check-answer skip reasons)

**Location:** `scripts/dev-cycle.sh:42`, `scripts/dev-cycle.sh:68`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that a NUL byte in a brief or questions file on main yields a skip naming the line through both CLI modes; does not establish behavior under awks other than mawk (covered by override row 224).
**Legibility-target:** for-orchestrator-synthesis

FENCE_AWK refuses the line: `if (index(l, "\0")) { refuse("nul"); return 1 }` (`scripts/lib/dev-cycle-read.sh:216`), and oddwhy maps it: `nul) echo "holds a NUL byte" ;;` (`scripts/lib/dev-cycle-read.sh:237`). The bats test "a NUL byte refuses a brief or a questions file..." asserts `skip $b: line 2 holds a NUL byte, so the brief is not read` and `skip Q-1: line 4 of docs/working/questions.md holds a NUL byte, ...` (`test/scripts/dev-cycle.bats` NUL test), and it passed in E2.

**Evidence:** `scripts/lib/dev-cycle-read.sh:213-241`, `test/scripts/dev-cycle.bats` (NUL test), `logs/bats-base.out`

---

## Claim 2: "read from docs/working/questions.md or its archive on the default branch's commit"

**Location:** `scripts/dev-cycle.sh:56-58`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that check_answer reads both files' blobs from `$MAIN_SHA` and never the working tree; does not establish which commit MAIN_SHA is beyond resolve_main's by-name order.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/lib/dev-cycle-read.sh:551-562
  for f in docs/working/questions.md docs/working/questions-archive.md; do
    e="$(main_entry "$f")"
    ...
    r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk -v id="$a" "$FENCE_AWK$ANSWER_AWK")" \
      || { echo "skip $a: $f could not be read from the default branch"; return; }
```
(excerpt ends :562; enclosing check_answer() continues to :575 — read). No working-tree read remains in the function (paraphrased — no quote available because the claim covers absence of code: the whole unit :547-575 was read and its only file reads are `git ls-tree` via main_entry and `git cat-file`). T34 ("--check-answer reads main's commit...") passed in E2.

**Evidence:** `scripts/lib/dev-cycle-read.sh:547-575`, `test/scripts/dev-cycle.bats` (T34), `logs/bats-base.out`

---

## Claim 3: "an answer only in the working tree is not seen: it reads what main's copy says, until committed"

**Location:** `scripts/dev-cycle.sh:58-59`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the working-tree half (verified) and the "until committed" end condition; does not establish anything about how the skill records answers (override row 227).
**Legibility-target:** for-author

The working-tree half is right. "Until committed" is imprecise: a commit is seen only once it is on the default branch's commit (`$MAIN_SHA`, `scripts/lib/dev-cycle-read.sh:561`). The branch's own T34 test proves a commit on another branch is still not seen:

```bash
# test/scripts/dev-cycle.bats (T34)
    # Committed only on another branch: still open.
    git checkout -q -b side && git commit -qam answer && git checkout -q main
    ...
    [ "$output" = "open Q-1" ] || { echo "$output"; return 1; }
```
That test passed in E2. A build-loop worktree on a feature branch that commits an answer would still read main's copy. The precise version is "until it lands on the default branch", which is the wording SKILL.md already uses ("not seen until it lands", `skills/dev-cycle/SKILL.md:294`).

**Evidence:** `scripts/dev-cycle.sh:56-59`, `scripts/lib/dev-cycle-read.sh:561`, `test/scripts/dev-cycle.bats` (T34), `logs/bats-base.out`

---

## Claim 4: "keep, drop, done, open (not marked ANSWERED yet) or unrecognized (answered, but no answer line was found, or the first one's text does not start with one of the options)"

**Location:** `scripts/dev-cycle.sh:59-62`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the positive outcome words check_answer can print; does not establish the full option-token grammar (`option()`), which is unchanged from main.
**Legibility-target:** for-orchestrator-synthesis

```awk
# scripts/lib/dev-cycle-read.sh:534-540
END {
  if (odd) print "odd " odd " " oddwhy
  else if (infence) print "unbalanced " fline
  else if (qline) print "quoted " qline
  else if (count > 1) print "dup"
  else if (count) print (!answered ? "open" : done ? result : "unrecognized")
}'
```
`result` comes from `option()`, which returns only keep, drop, done or unrecognized (`scripts/lib/dev-cycle-read.sh:488-501`), and check_answer prints `"$hit $a"` (`:573`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:487-540`, `scripts/lib/dev-cycle-read.sh:573`

---

## Claim 5: --check-answer skip list "(not a question ID, no such entry, a heading twice in one file or in both files, ..., a questions file that is not a regular file under plain directories on the default branch, or a default branch whose tree or file could not be read)"

**Location:** `scripts/dev-cycle.sh:62-71`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every skip echo in check_answer (:549-574) reachable through dev-cycle.sh; does not cover the lib-only "no default branch found by name" skip (:550), which the CLI never reaches because it exits 1 first (claim 6).
**Legibility-target:** for-orchestrator-synthesis

Mapping each echo in `scripts/lib/dev-cycle-read.sh:547-575` to the list: `not a question ID (Q- and digits)` (:549); notdir (`is not a directory on the default branch`, :556) and notfile (`is not a regular file on the default branch`, :558), the "not a regular file under plain directories" item; `the default branch's tree could not be read` (:557) and `$f could not be read from the default branch` (:562), the "tree or file could not be read" item; `more than one entry with this heading in $f` (:564) and `an entry with this heading in both $where and $f` (:570), "a heading twice in one file or in both files"; the `odd` reasons via oddwhy (:566; html, comment, refdef, cr, nul, bom, fence, `:231-241`) match the fence, `<`, `<!--`, link-reference, carriage return, NUL and BOM items; `unbalanced` (:567) is "a code fence never closed"; `quoted` (:568) is "a question heading inside a fence"; the final `no such entry ... on the default branch` (:574) is "no such entry". No echo is missing from the list.

**Evidence:** `scripts/dev-cycle.sh:62-71`, `scripts/lib/dev-cycle-read.sh:231-241`, `scripts/lib/dev-cycle-read.sh:547-575`

---

## Claim 6: "--check-brief, --check-branch and --check-answer need a default branch found by name ... Exit: ... 1 ... no default branch (for the digest, --check-brief, --check-branch and --check-answer)"

**Location:** `scripts/dev-cycle.sh:72-73`, `scripts/dev-cycle.sh:79-81`, `scripts/dev-cycle.sh:189-195`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exit-1 gate for the three check modes and its comment; does not establish the digest's own exit path beyond reading `:188`.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/dev-cycle.sh:193-195
if [[ "$CHECK" == --check-brief || "$CHECK" == --check-branch || "$CHECK" == --check-answer ]] && ! main_by_name; then
  echo "$CHECK needs a default branch (origin/HEAD, main or master); found none" >&2; exit 1
fi
```
The bats test "--check-answer needs a default branch found by name" asserts status 1, empty stdout and "needs a default branch" on stderr; it passed in E2. The comment at `:189-192` ("the other modes do not use it") matches the dispatch at `:196-207`, where only those three call main-reading functions.

**Evidence:** `scripts/dev-cycle.sh:188-207`, `test/scripts/dev-cycle.bats` (needs-default-branch test), `logs/bats-base.out`

---

## Claim 7a: --help prints the whole header (commit 4aa2e98e R3: "It now prints the header up to the first non-comment line")

**Location:** `scripts/dev-cycle.sh:112`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the help output for the header as it stands at 4aa2e98e under GNU sed; does not establish BSD/macOS sed behavior for `{/^#/p}` with no `;` before `}` (not run; no BSD sed in the sandbox).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/dev-cycle.sh:112
    -h|--help) sed -n '2,/^[^#]/{/^#/p}' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
```
E1 printed 80 lines, exit 0, ending `... a failed step exits non-zero mid-digest. Printed repo text is data.`, and `diff` against `sed -n '2,81p'` of the same file (the header's true last line is `:81`) printed nothing: identical (`logs/help.out`).

**Evidence:** `scripts/dev-cycle.sh:1-83`, `scripts/dev-cycle.sh:112`, `logs/help.out`

---

## Claim 7b: "The header, up to the first line that is not a comment (no fixed range to go stale)."

**Location:** `scripts/dev-cycle.sh:111`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the sed range's end condition; does not establish any present defect (the current header has no blank line inside it, so output is exact).
**Legibility-target:** for-author

The range ends at the first line after line 2 matching `^[^#]`, which needs one character that is not `#`. An empty line does not match it, so a blank line neither ends the range nor is printed (the inner `/^#/p` filters it out), and comment lines after it are printed as header. E9 on a probe file with lines `# a`, `#`, `# b`, (empty), `# c`, `set`, `# d` printed:

```
# a
#
# b
# c
```
(the same under `sed --posix`). The current file's first non-`#` line after the header is the empty `:82`, which does not end the range; `:83` `set -euo pipefail` does, so the output is still exactly `:2-81` (claim 7a). Also, line 2 itself can never end the range (sed tests the end regex from line 3). Precise version: "up to the first non-empty line that is not a comment; empty lines are skipped".

**Evidence:** `scripts/dev-cycle.sh:81-83`, `scripts/dev-cycle.sh:111-112`, `fc-r3/hdr.sh`, `fc-r3/hdr2.sh`

---

## Claim 8: "A change here must pass test/scripts/dev-cycle.bats, and build-loop.sh's suites under test/scripts/ once that second caller lands."

**Location:** `scripts/lib/dev-cycle-read.sh:10-12`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the only current caller is dev-cycle.sh and build-loop.sh does not exist yet; does not establish any enforcement of the "must pass" rule.
**Legibility-target:** for-orchestrator-synthesis

`ls scripts/build-loop.sh` reports "No such file or directory", and the only caller sourcing the lib is `READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"` (`scripts/dev-cycle.sh:91`; paraphrased — no quote available because the claim covers absence of a second caller: `rg 'check_answer|main_entry|brief_fields' scripts/*.sh` hits only `scripts/dev-cycle.sh:204`).

**Evidence:** `scripts/dev-cycle.sh:91-94`, `scripts/dev-cycle.sh:204`

---

## Claim 9: "The caller sets -euo pipefail"

**Location:** `scripts/lib/dev-cycle-read.sh:12-13`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the caller contract as stated and dev-cycle.sh's compliance; does not establish that every lib function now depends on it (brief_fields and check_answer set pipefail themselves, claim 18).
**Legibility-target:** for-orchestrator-synthesis

`set -euo pipefail` is at `scripts/dev-cycle.sh:83`, before the lib functions run. The contract stays accurate: functions other than brief_fields and check_answer still rely on the caller's options (paraphrased — no quote available because the claim covers absence of `local -` in the other functions, checked by reading `:91-575`).

**Evidence:** `scripts/dev-cycle.sh:83`, `scripts/lib/dev-cycle-read.sh:289-292`, `scripts/lib/dev-cycle-read.sh:548`

---

## Claim 10: "inrepo, dirok, skipped, check_brief and the import walk (imported_names) exit 1 (need_root) unless ROOT_REAL is set"

**Location:** `scripts/lib/dev-cycle-read.sh:15-17`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the list of need_root callers after check_answer was removed from it; does not re-verify need_root's own three conditions (unchanged from main).
**Legibility-target:** for-orchestrator-synthesis

The only need_root calls are in `inrepo() { need_root; ...` (`:121`), `dirok() { need_root; ...` (`:124`), `skipped() { need_root; ...` (`:125`), check_brief (`:323`) and imported_names (`:433`). check_answer (`:547-575`) calls none.

**Evidence:** `scripts/lib/dev-cycle-read.sh:91`, `scripts/lib/dev-cycle-read.sh:121-125`, `scripts/lib/dev-cycle-read.sh:323`, `scripts/lib/dev-cycle-read.sh:433`

---

## Claim 11: "check_brief, check_branch and check_answer skip every argument unless it returned 0 with main found by name"

**Location:** `scripts/lib/dev-cycle-read.sh:21-23`, `scripts/lib/dev-cycle-read.sh:242-244`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the main_by_name guard in all three functions; does not establish resolve_main's candidate order.
**Legibility-target:** for-orchestrator-synthesis

Each has `if ! main_by_name; then echo "skip ...: no default branch found by name ..."; return; fi` (`:324`, `:372`, `:550`). In check_answer the ID-form check (`:549`) comes first, so a malformed ID gets "not a question ID" instead. The test "check_answer reads git only..." asserts the no-main skip line before `resolve_main`; it passed in E2.

**Evidence:** `scripts/lib/dev-cycle-read.sh:324`, `scripts/lib/dev-cycle-read.sh:372`, `scripts/lib/dev-cycle-read.sh:549-550`, `logs/bats-base.out`

---

## Claim 12: "Inputs: check_brief, check_branch, check_answer, main_entry and brief_fields read the default branch's commit, never the working tree (check_brief also refuses a brief path that is not plain in the working tree, which the cycle writes); imported_names reads the working tree at ROOT_REAL."

**Location:** `scripts/lib/dev-cycle-read.sh:29-32`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that none of the five reads working-tree file content (check_brief's blocker check is the stated exception); does not establish that check_branch reads only main: it also reads `refs/heads/<name>` (`:378`), which the "default branch's commit" wording leaves out but which is not the working tree.
**Legibility-target:** for-orchestrator-synthesis

main_entry uses `git ls-tree -t --full-tree "$MAIN_SHA"` (`:263`); brief_fields uses `git cat-file blob "$MAIN_SHA:$1"` (`:297`); check_answer the same (`:561`); check_brief adds `blocker "$a" file` on the working tree (`:329`). The T31 test writes `Status: dropped` into the working-tree brief after committing and asserts `status=[Status: open]`; it passed in E2.

**Evidence:** `scripts/lib/dev-cycle-read.sh:258-312`, `scripts/lib/dev-cycle-read.sh:321-383`, `scripts/lib/dev-cycle-read.sh:547-575`, `logs/bats-base.out`

---

## Claim 13: "and anywhere in the file, fenced or not, a carriage return inside a line ..., a NUL byte (a caller reading the output through $(...) would lose it), or a byte-order mark on line 1"

**Location:** `scripts/lib/dev-cycle-read.sh:173-176`, `scripts/lib/dev-cycle-read.sh:216`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers fenced and unfenced CR/NUL and line-1-only BOM under mawk (the installed awk); does not establish one-true-awk or busybox behavior (override row 224).
**Legibility-target:** for-orchestrator-synthesis

```awk
# scripts/lib/dev-cycle-read.sh:213-218
function fence(l) {  # 1: a fence line or fenced content (not text); 0: ordinary text
  if (odd) return 1   # the file is already refused: nothing after it is read
  if (index(l, "\r")) { refuse("cr"); return 1 }
  if (index(l, "\0")) { refuse("nul"); return 1 }  # $(...) drops NUL, so a printed line would not be the line read
  if (NR == 1 && substr(l, 1, 3) == "\357\273\277") { refuse("bom"); return 1 }
  if (infence) {
```
(excerpt ends :218; enclosing fence() continues to :229 — read). The checks run before the `infence` branch. E8 (awk is `/usr/bin/mawk`): NUL inside a fence gives `odd=2 why=nul`, CR inside a fence `odd=2 why=cr`, a BOM on line 2 is not refused, plain lines give no refusal. bash's `$(...)` dropping NUL is the reason given, and the pre-fix R1 case (`Status: op<NUL>en`) is now refused (NUL test, E2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:163-229`, `logs/probe2.out`, `logs/bats-base.out`

---

## Claim 14: main_entry prints "blob" (100644 or 100755), "absent", "notfile", "notdir PART" or "error" (no default branch found by name, ls-tree failed, ...); "One ls-tree call lists the path and every directory above it (-t: trees too; --full-tree: paths from the top level, whatever the current directory)"

**Location:** `scripts/lib/dev-cycle-read.sh:247-256`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the five result words, the single ls-tree call and cwd independence; does not establish the cost of `-t` listing each named directory's children (override row 220).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/lib/dev-cycle-read.sh:261-273
  main_by_name || { echo error; return; }
  while [[ "$rest" == */* ]]; do p="${p:+$p/}${rest%%/*}"; rest="${rest#*/}"; want+=("$p"); done
  out="$(git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1" 2>/dev/null)" || { echo error; return; }
  ...
  for p in "${want[@]}"; do
    case "${m[$p]-}" in '') echo absent; return ;; 040000) ;; *) echo "notdir $p"; return ;; esac
  done
  case "${m[$1]-}" in '') echo absent ;; 100644|100755) echo blob ;; *) echo notfile ;; esac
```
(the `...` is :264-269, the read loop and duplicate check — read). The NUL test asserts `error` before resolve_main and with a bogus all-zero MAIN_SHA; the "git only" test runs check_answer after `cd docs` and gets the same answer as from the top level; both passed in E2.

**Evidence:** `scripts/lib/dev-cycle-read.sh:258-274`, `test/scripts/dev-cycle.bats` (NUL test, git-only test), `logs/bats-base.out`

---

## Claim 15: "or the tree lists a name twice; git's own reads would take the first copy, which may not be the one a check saw, so this answers error instead; never read as absent"

**Location:** `scripts/lib/dev-cycle-read.sh:252-254`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the duplicate-name error and git's first-copy read for a symlink-then-blob tree; does not establish ordering for other duplicate shapes (fsck-invalid trees, override row 236).
**Legibility-target:** for-orchestrator-synthesis

`[[ -z "${m[$path]+set}" ]] || dup=1` then `[[ -z "$dup" ]] || { echo error; return; }` (`:266`, `:269`). E8 built a tree listing `questions.md` as a symlink (`x`) and then as a blob (`real`); `git cat-file -p "$w:questions.md"` printed `[x]`, the first copy. The bats test's mktree case asserts the "tree could not be read" skip (E2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:264-269`, `logs/probe2.out`, `logs/bats-base.out`

---

## Claim 16: "The caller has checked main_by_name and the path's form (pathform, so ls-tree prints it unquoted)."

**Location:** `scripts/lib/dev-cycle-read.sh:256-257`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the stated caller preconditions against main_entry's body and its three callers; does not establish any misbehavior (main_entry fails closed without main by name).
**Legibility-target:** for-author

main_entry checks main_by_name itself: `main_by_name || { echo error; return; }` (`scripts/lib/dev-cycle-read.sh:261`), so that part is not a caller precondition. The tests rely on this: the NUL test calls `main_entry "$2"` before `resolve_main` and asserts `error`. Only the path form is a real precondition. check_brief (`:325`) and brief_fields (`:294`) call pathform first; check_answer passes two literal paths (`:551`) without pathform, which is safe because they are fixed. Precise version: "main_entry answers error itself without a default branch found by name; the caller has checked the path's form (pathform, so ls-tree prints it unquoted)."

**Evidence:** `scripts/lib/dev-cycle-read.sh:256-261`, `scripts/lib/dev-cycle-read.sh:294`, `scripts/lib/dev-cycle-read.sh:325`, `scripts/lib/dev-cycle-read.sh:551`

---

## Claim 17: brief_fields comment: first unfenced line per key "whole, after one trailing CR is dropped"; "a key with no such line stays unset"; "Otherwise it sets no key and returns 1, with BRIEF_ODD 'odd N WHY', 'unbalanced N' or 'error' (no default branch found by name, a path pathform refuses, any main_entry answer but blob, its error included, or the blob could not be read)"

**Location:** `scripts/lib/dev-cycle-read.sh:275-287`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every documented outcome of brief_fields; does not establish how later callers (U1b/U1c) judge the values.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/lib/dev-cycle-read.sh:293-294, 303-311
  BRIEF=(); BRIEF_ODD=""
  if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]; then BRIEF_ODD=error; return 1; fi
  ...
    END { if (odd) print "odd " odd " " oddwhy; else if (infence) print "unbalanced " fline; else for (i = 1; i <= nk; i++) print kv[i] }')" \
    || { BRIEF_ODD=error; return 1; }
  while IFS= read -r l; do
    case "$l" in
      '') ;;
      odd\ *|unbalanced\ *) BRIEF=(); BRIEF_ODD="$l"; return 1 ;;
```
(excerpt ends :308; enclosing brief_fields() continues to :312 — read). No-main reaches `error` via main_entry's own guard. The two T31 tests assert the first unfenced copy per key, CR dropping (`Status: open\r\n` reads `Status: open`), unset absent keys, `refused [odd 2 fence] 0` and `refused [unbalanced 2] 0`; the unreadable-blob test asserts `refused [error]`; all passed in E2.

**Evidence:** `scripts/lib/dev-cycle-read.sh:275-312`, `test/scripts/dev-cycle.bats` (T31 tests, unreadable-blob test), `logs/bats-base.out`

---

## Claim 18: "pipefail for this function only (local -), so a failed read is caught whatever the caller set." (and check_answer's "# as brief_fields"; commit 4aa2e98e A17: "the caller's options come back on return")

**Location:** `scripts/lib/dev-cycle-read.sh:290-292`, `scripts/lib/dev-cycle-read.sh:548`
**Type:** Error-handling / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers catching a failed `git cat-file` under no options, `set -eu` and `set -euo pipefail`, and restoring the caller's options after normal and early returns, on bash 5.2.15; does not establish behavior on bash < 4.4, where `local -` does not exist (the repo states no minimum bash version; the lib already needs 4.2+ for `declare -gA`).
**Legibility-target:** for-orchestrator-synthesis

`local - out l; set -o pipefail` (`:292`) and `local - a="$1" f e r hit="" where="" n why; set -o pipefail  # as brief_fields` (`:548`). E7: with no caller options, pipefail is `off` before and after check_answer, after its early `not a question ID` return, and after brief_fields' `return 1`. Under `set -eu` the flags after the calls are `ehuBc` with pipefail off. Under `set -euo pipefail` pipefail stays `on`. A function that sets `+e` and `-x` after `local -` returns with `-e` back and `-x` off (`flags=ehBc`). The failed read is caught without the caller's pipefail: the bats block under `set -eu` alone asserts the skip line, `refused [error]` and `caller unchanged` (E2). Mutants E5 (check_answer without it) print `keep Q-1`, a fall-through to the archive, and E6 (brief_fields without it) prints no `refused` line; both fail the test.

**Evidence:** `scripts/lib/dev-cycle-read.sh:289-312`, `scripts/lib/dev-cycle-read.sh:547-575`, `logs/localdash.out`, `logs/bats-ans_nopf.out`, `logs/bats-bf_nopf.out`, `logs/bats-base.out`

---

## Claim 19: "The whole blob is read (no early exit: SIGPIPE under pipefail)."

**Location:** `scripts/lib/dev-cycle-read.sh:295`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the absence of an awk `exit` in brief_fields' program; does not establish a measured SIGPIPE case.
**Legibility-target:** for-orchestrator-synthesis

The awk program at `:297-303` has rules `{ sub(/\r$/, "") }`, `fence($0) { next }`, a `match(...)` rule and `END { ... }`, with no `exit` (paraphrased — no quote available because the claim covers absence of code; the whole program, FENCE_AWK `:186-230` included, was read and holds no `exit`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:186-230`, `scripts/lib/dev-cycle-read.sh:297-303`

---

## Claim 20: check_brief comment: "its Status line from brief_fields, which must be exactly 'Status: open|done|dropped' ... neither is one stored as anything but a regular file under plain directories (main_entry). 'new' when the default branch has no file at that path"

**Location:** `scripts/lib/dev-cycle-read.sh:313-320`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_brief's main_entry and brief_fields paths; does not re-verify the Status-commit lookup at `:357-358` (unchanged from main).
**Legibility-target:** for-orchestrator-synthesis

`absent) echo "ok $a new"; return ;;`, `notdir\ *) ... is not a directory on the default branch`, `error) ...`, `*) echo "skip $a: not a regular file on the default branch"` (`:333-339`), then `st="${BRIEF[status]-}"` and `[[ ! "$st" =~ ^Status:\ (open|done|dropped)$ ]]` (`:348-349`). The T31 tests show check_brief agreeing with brief_fields (`ok $b open ...`), and the unreadable-blob test shows `skip $b: the brief could not be read from the default branch`; both passed in E2.

**Evidence:** `scripts/lib/dev-cycle-read.sh:321-360`, `logs/bats-base.out`

---

## Claim 21: "One answer, from ... on the default branch's commit, never the working tree ... A file stored as anything but a regular file under plain directories there is not read (main_entry). It reads only git objects, so it needs no ROOT_REAL and adds nothing to SKIPPED."

**Location:** `scripts/lib/dev-cycle-read.sh:541-546`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers no ROOT_REAL dependency, no SKIPPED writes and the main_entry gate; does not establish refs/replace handling (override row 235).
**Legibility-target:** for-orchestrator-synthesis

check_answer has no `need_root` or `skipped` call (paraphrased — no quote available because the claim covers absence of code in `:547-575`, read whole). The test "check_answer reads git only..." runs it with ROOT_REAL set over a symlinked archive on main (asserting `skipped=0`), then unset after `cd docs` (same skip line); the not-plain test asserts the symlink and symlinked-directory skips whatever the working tree holds. Both passed in E2.

**Evidence:** `scripts/lib/dev-cycle-read.sh:541-575`, `test/scripts/dev-cycle.bats` (git-only test, not-plain test), `logs/bats-base.out`

---

## Claim 22: "A failed read is a skip, never a fall-through to the other file."

**Location:** `scripts/lib/dev-cycle-read.sh:560-562`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a missing questions.md blob with an answering archive present; does not establish the stderr scrub of cat-file's `fatal:` line (override row 238).
**Legibility-target:** for-orchestrator-synthesis

`|| { echo "skip $a: $f could not be read from the default branch"; return; }` (`:562`). The unreadable-blob test deletes questions.md's object while the archive answers `[1]`, and asserts the skip line, through dev-cycle.sh and under `set -eu` alone (E2). Mutant E5 shows the fall-through the claim rules out (`keep Q-1`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:560-563`, `logs/bats-base.out`, `logs/bats-ans_nopf.out`

---

## Claim 23: "it reads `questions.md` and `questions-archive.md` from the default branch's commit, so an answer, or an archive move, made only in the working tree is not seen until it lands (it reads what main's copy says, usually `open` or no such entry)"

**Location:** `skills/dev-cycle/SKILL.md:292-295`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers reading from main and "until it lands"; "usually" correctly hedges the other outcomes main's copy can give (an older answer, `unrecognized`, a skip); does not establish the skill's later recording steps (override row 227).
**Legibility-target:** for-orchestrator-synthesis

The mechanism is claim 2's (`git cat-file blob "$MAIN_SHA:$f"`, `scripts/lib/dev-cycle-read.sh:561`). T34 asserts `open Q-1` for working-tree-only and other-branch-only answers, and `drop Q-1` once merged to main with no working-tree file (E2). "No such entry" is the final echo at `:574` when main has neither file's entry.

**Evidence:** `skills/dev-cycle/SKILL.md:289-298`, `scripts/lib/dev-cycle-read.sh:561-574`, `logs/bats-base.out`

---

## Claim 24: Test names added or changed on the branch match their assertions (T34, not-plain-on-main, needs-default-branch, git-only, NUL/main_entry fails closed, T31 template, T31 one-pass, unreadable-blob/duplicate-name, --help)

**Location:** `test/scripts/dev-cycle.bats:649-655`, `test/scripts/dev-cycle.bats:1029-1036`, `test/scripts/dev-cycle.bats:1118-1280`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each new test's name names what its assertions check and that all 68 pass; does not establish the build-loop.sh side of T34 (override row 221).
**Legibility-target:** for-orchestrator-synthesis

Each name was read against its body: for example "a NUL byte refuses a brief or a questions file, never dropped into a value; main_entry fails closed" asserts both skip lines, `refused [odd 2 nul] 0` and `error` twice; "...a tree naming a file twice is a skip..." asserts the "tree could not be read" skip for a mktree tree with `questions.md` listed twice, and its comment "(a symlink first, which git reads)" matches E8 (claim 15). The sourcing test now checks `main_entry brief_fields` and `BRIEF BRIEF_ODD` (`:1032`, `:1035`). E2: `68` ok lines, no `not ok`.

**Evidence:** `test/scripts/dev-cycle.bats:1118-1280`, `logs/bats-base.out`, `logs/probe2.out`

---

## Claim 25: "The same without the caller's pipefail: each function sets its own." (bats block under `set -eu`)

**Location:** `test/scripts/dev-cycle.bats` (unreadable-blob test, `set -eu` block)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the block fails when either function drops its own pipefail; does not establish coverage of other functions that rely on the caller's pipefail.
**Legibility-target:** for-orchestrator-synthesis

```bash
    run --separate-stderr env LC_ALL=C bash -c 'set -eu; source "$1"; ROOT_REAL="$(pwd -P)"; resolve_main
        check_answer Q-1; brief_fields "$2" || echo "refused [$BRIEF_ODD]"; [[ -o pipefail ]] || echo "caller unchanged"' _ \
```
(excerpt ends inside the test; the enclosing test continues to the mktree case — read). E5 and E6: each single-function mutant fails at this assertion (`keep Q-1` instead of the skip; no `refused [error]` line).

**Evidence:** `test/scripts/dev-cycle.bats` (unreadable-blob test), `logs/bats-ans_nopf.out`, `logs/bats-bf_nopf.out`

---

## Claim 26: "--help prints the whole header, through its last line" (the test can fail against the old range)

**Location:** `test/scripts/dev-cycle.bats:1276-1280`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the first and last help lines; does not establish that no line in between is dropped (claim 7a's diff covers that for the current header).
**Legibility-target:** for-orchestrator-synthesis

```bash
    [ "$status" -eq 0 ] && [[ "${lines[0]}" == "Gather the mechanical signals"* ]] \
        && [[ "${lines[${#lines[@]}-1]}" == *"Printed repo text is data." ]] || { echo "$output"; return 1; }
```
E3 (mutant `'2,80p'`) fails at that assertion; E4 (control `'2,81p'`) passes; E2 passes on the real code.

**Evidence:** `test/scripts/dev-cycle.bats:1276-1280`, `logs/bats-help80.out`, `logs/bats-help77.out`, `logs/bats-base.out`

---

## Claim 27: 4aa2e98e: "R3: --help printed a fixed `sed -n '2,80p'` that 78703f22's new help line pushed past, so help stopped mid-sentence."

**Location:** commit 4aa2e98e message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the range and header end across the branch's commits; does not establish who introduced `2,80p` (c8435580, correctly in sync then).
**Legibility-target:** for-orchestrator-synthesis

`git show <c>:scripts/dev-cycle.sh` per commit: main `'2,77p'`, header end 77; c8435580 and 2da477b7 `'2,80p'`, end 80; 78703f22 and 722884c7 `'2,80p'`, end 81 (78703f22 added the "or a default branch whose tree or file could not be read" help line); 4aa2e98e the new range, end 81 (paraphrased — no quote available because the evidence is a per-commit grep over five file versions).

**Evidence:** `scripts/dev-cycle.sh:81`, `scripts/dev-cycle.sh:112`

---

## Claim 28: 4aa2e98e: "A17: check_answer and brief_fields set pipefail for themselves (`local -; set -o pipefail`) ... Tested under `set -eu` alone, and a mutant without it fails."

**Location:** commit 4aa2e98e message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both functions and both mutants; does not establish the commit's own mutant run (re-run here, not observed).
**Legibility-target:** for-orchestrator-synthesis

Same evidence as claims 18 and 25: `:292` and `:548` hold the code, and E5 and E6 show each mutant fails the `set -eu` block. The commit writes `local -; set -o pipefail` but the code puts `-` in the same `local` as other names (`local - out l; set -o pipefail`), which is equivalent (E7).

**Evidence:** `scripts/lib/dev-cycle-read.sh:292`, `scripts/lib/dev-cycle-read.sh:548`, `logs/bats-ans_nopf.out`, `logs/bats-bf_nopf.out`, `logs/localdash.out`

---

## Claim 29: 4aa2e98e: "A14/A15: the help and SKILL.md say a working-tree-only answer reads what main's copy says (usually open or no such entry). A16: --check-answer's skip list names 'not a question ID' and a heading in both files."

**Location:** commit 4aa2e98e message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the named text exists at the named places; the help's "until committed" imprecision is claim 3's.
**Legibility-target:** for-orchestrator-synthesis

Help: `it reads what main's copy says, until committed` (`scripts/dev-cycle.sh:59`) and `(not a question ID, no such` / `entry, a heading twice in one file or in both files` (`:63-64`). SKILL.md: `copy says, usually \`open\` or no such entry` (`skills/dev-cycle/SKILL.md:295`). The help version omits "usually open or no such entry", which the bullet attributes to both; the help's "what main's copy says" covers it.

**Evidence:** `scripts/dev-cycle.sh:56-71`, `skills/dev-cycle/SKILL.md:292-295`

---

## Claim 30: 4aa2e98e: "Override-log rows: A18 and iteration 3's C9 residue, C11-C15."

**Location:** commit 4aa2e98e message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the rows exist and carry those IDs; does not judge the dispositions.
**Legibility-target:** for-orchestrator-synthesis

`docs/reviews/override-log.md:232` (`... (fact-check 44-45; A18)`), `:233` (`iteration 3 C11`), `:234` (`C12`), `:235` (`C13`), `:236` (`C14`), `:237` (`iteration 3 C15`), `:238` (`iteration 3 C9 residue`).

**Evidence:** `docs/reviews/override-log.md:232-238`

---

## Claim 31: c8435580: "check_brief also skips a brief whose directory is not a directory on main (before, ls-tree printed nothing and it read as 'new')."

**Location:** commit c8435580 message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the old and new code paths; the old behavior was read, not run.
**Legibility-target:** for-orchestrator-synthesis

Old code (diff, main side): `case "$(git ls-tree "$MAIN_SHA" -- "$a" | cut -c1-6)" in '') echo "ok $a new"; return ;;`. A path under a directory stored as a symlink has no tree entry, so it printed nothing and read as new. New code: `notdir\ *) echo "skip $a: ${e#notdir } is not a directory on the default branch"; return ;;` (`scripts/lib/dev-cycle-read.sh:336`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:332-339`

---

## Claims Requiring Attention

### Incorrect
- none

### Stale
- none

### Mostly Accurate
- **Claim 3** (`scripts/dev-cycle.sh:58-59`): "until committed" should say "until it lands on the default branch"; a commit on another branch is still unseen (T34 asserts exactly that).
- **Claim 7b** (`scripts/dev-cycle.sh:111`): the range ends at the first non-empty non-comment line. An empty line inside the header does not end it and is silently dropped, so a comment block after a blank line would print as help. The output is exact today.
- **Claim 16** (`scripts/lib/dev-cycle-read.sh:256-257`): "The caller has checked main_by_name" is not a precondition, because main_entry checks it itself (`:261`, relied on by the NUL test). Only the path form is the caller's job.

### Unverifiable
- none

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved to docs/reviews/code-fact-check-report-build-loop-u1a-r3.md, structured per the code-fact-check skill, first line `Commit: 4aa2e98e`.
- Answered: yes
- Out of scope: BSD/macOS sed's handling of `{/^#/p}` without a `;` before `}` (no BSD sed in the sandbox; the help comment makes no portability claim). bash < 4.4 behavior of `local -` (no stated minimum version in the repo).
- Escalate: api-consistency-reviewer / orchestrator: decide whether BSD-sed portability of the new `--help` sed matters for this repo's supported platforms. If it does, `sed -n '2,/^[^#]/{/^#/p;}'` is the conservative spelling (not executed here). Otherwise nothing.
- Decisions I made: Split the help sed claim into 7a (output, Verified) and 7b (comment's end condition, Mostly accurate) because the verdicts differ. Rated "until committed" Mostly accurate rather than Incorrect because the same help sentence names "the default branch's commit". The execution logs stay in the scratch dir, not under docs/reviews/execution-logs/, because the brief allows only one tracked-file write.
