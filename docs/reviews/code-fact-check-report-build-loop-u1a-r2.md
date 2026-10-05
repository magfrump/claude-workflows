Commit: 4aa2e98e

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u1a (claude-workflows, branch feat/build-loop-u1a)
**Scope:** `git diff main...feat/build-loop-u1a`, code files only (scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, skills/dev-cycle/SKILL.md, test/scripts/dev-cycle.bats; docs/reviews/ excluded as review artifacts), plus commit bodies of 4aa2e98e and c8435580's check_brief claim. Replicate r2 of the iteration-4 final confirming pass, at 4aa2e98e.
**Checked:** 2026-10-05
**Total claims checked:** 40
**Summary:** 35 verified, 3 mostly accurate, 1 stale, 0 incorrect, 1 unverifiable

I read `docs/reviews/hallucination-patterns.md` first (8 logged patterns). No claim below matches a logged pattern, and no new fabrication was found.

Execution environment: GNU bash 5.2.15, GNU sed 4.9, mawk 1.3.4, bats at /usr/bin/bats, `LC_ALL=C.UTF-8`, TMPDIR unset. All execution ran in the scratch dir `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i4/fc-r2/` (abbreviated `$FC` below) or ran the worktree's bats suite, which builds its fixtures under `$BATS_TEST_TMPDIR`. Captured output is in `$FC/logs/`. Runs:

| Run | Command (cwd) | Exit | Time (UTC) | Log |
|---|---|---|---|---|
| E1 | `bats test/scripts/dev-cycle.bats` (worktree) | 0 (68/68 ok) | 2026-10-05T16:32:36Z | `$FC/logs/E1-bats-full.log` |
| E2 | `bash scripts/dev-cycle.sh --help`, compared with `sed -n '2,81p'` of the script; `sed -n '2,/^[^#]/{/^#/p}'` on probe inputs p1-p4 (`$FC`) | 0 | 2026-10-05T16:32:59Z, 16:34:43Z | `$FC/logs/E2-help.log`, `$FC/logs/E2-sed-probes.log` |
| E3 | `bats -f 'prints the whole header'` against mutants with `sed -n '2,80p'` (m80) and `'2,77p'` (m77) (`$FC/m80`, `$FC/m77`) | 1, 1 | 2026-10-05T16:33:19Z | `$FC/logs/E3-m80.log`, `$FC/logs/E3-m77.log` |
| E4 | `bats -f 'unreadable blob'` against mutants without `set -o pipefail` in check_answer (mpf_ans) or brief_fields (mpf_bf) | 1, 1 | 2026-10-05T16:33:19Z | `$FC/logs/E4-mpf_ans.log`, `$FC/logs/E4-mpf_bf.log` |
| E5 | `bats -f 'unreadable blob'` against a mutant with `local` in place of `local -` in both functions (mnl) | 1 | 2026-10-05T16:33:35Z | `$FC/logs/E5-mnl.log` |
| E6 | `bash $FC/probe.sh <lib> none|eu|euo` in a fixture repo with two blobs deleted (`$FC/e6/r`) | 0 | 2026-10-05T16:33:45Z | `$FC/logs/E6-local-dash.log` |
| E7 | duplicate-name tree built with `git mktree`; `git ls-tree -t --full-tree`, `git cat-file -p`, `main_entry` (`$FC/e7/r`) | 0 | 2026-10-05T16:33:53Z | `$FC/logs/E7-dup-tree.log` |
| E8 | `--check-brief` with main's dev-cycle.sh and with the branch's, in a fixture where docs/working/briefs is a symlink on main (`$FC/e8/r`) | 0 | 2026-10-05T16:34:06Z | `$FC/logs/E8-notdir.log` |

Override-log filter: rows 220-238 (all dated 2026-10-05, `feat/build-loop-u1a`) were read. Where a claim touches one, the row is noted.

---

## Claim 1: "a stray carriage return, a NUL byte, or a byte-order mark on line 1" (--check-brief skip reasons)

**Location:** `scripts/dev-cycle.sh:42`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the NUL refusal reaching --check-brief through FENCE_AWK as a skip that names the line; does not establish NUL handling under awks other than mawk (override row 224).
**Legibility-target:** for-orchestrator-synthesis

FENCE_AWK's `fence()` refuses a NUL line: `if (index(l, "\0")) { refuse("nul"); return 1 }` (`scripts/lib/dev-cycle-read.sh:216`), and check_brief maps the `odd` result to `skip $a: line $n $(oddwhy "$why"), so the brief is not read` (`scripts/lib/dev-cycle-read.sh:342`). Test 64 asserts `skip $b: line 2 holds a NUL byte, so the brief is not read` (`test/scripts/dev-cycle.bats:1183`) and passed in E1.

**Evidence:** `scripts/lib/dev-cycle-read.sh:213-229`, `scripts/lib/dev-cycle-read.sh:340-347`, `test/scripts/dev-cycle.bats:1177-1193`, `$FC/logs/E1-bats-full.log`

---

## Claim 2: "an answer only in the working tree is not seen: it reads what main's copy says, until committed"

**Location:** `scripts/dev-cycle.sh:57-59`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the working-tree-only case and the "reads main's copy" mechanism; does not establish that committing alone is enough, which it is not unless the commit is on the default branch.
**Legibility-target:** for-author

Both readers take main's blob, not the working tree: `r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk ...` (`scripts/lib/dev-cycle-read.sh:561`). The T34 test shows the "until committed" qualifier is too loose. A commit on another branch still reads `open`:

```bash
# test/scripts/dev-cycle.bats:1126-1129
    # Committed only on another branch: still open.
    git checkout -q -b side && git commit -qam answer && git checkout -q main
    [ "$(git show main:docs/working/questions.md | grep -c ANSWERED)" -eq 0 ]
    run --separate-stderr bash "$DC" --check-answer Q-1
```

The answer is seen only after `git merge -q side` (`:1132`). The test passed in E1. A more precise wording is "until it lands on the default branch", which matches SKILL.md's "until it lands" (`skills/dev-cycle/SKILL.md:294`). The same help sentence opens with "on the default branch's commit", so the mechanism is stated correctly; only the closing qualifier is loose.

**Evidence:** `scripts/dev-cycle.sh:56-59`, `scripts/lib/dev-cycle-read.sh:551-562`, `test/scripts/dev-cycle.bats:1118-1135`, `$FC/logs/E1-bats-full.log`

---

## Claim 3: --check-answer's outcome set "keep, drop, done, open (not marked ANSWERED yet) or unrecognized (answered, but no answer line was found, ...)"

**Location:** `scripts/dev-cycle.sh:59-62`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the set of positive words ANSWER_AWK can print; does not re-check the pre-existing "does not start with one of the options" wording (unchanged context, not in this diff).
**Legibility-target:** for-orchestrator-synthesis

`else if (count) print (!answered ? "open" : done ? result : "unrecognized")` (`scripts/lib/dev-cycle-read.sh:539`). `result` comes from `option()`, which returns only `keep`, `drop`, `done` or `unrecognized` (`scripts/lib/dev-cycle-read.sh:490-500`). check_answer echoes it as `echo "$hit $a"` (`:573`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:487-540`, `scripts/lib/dev-cycle-read.sh:573`

---

## Claim 4: the skip-reason list "(not a question ID, no such entry, a heading twice in one file or in both files, a code fence never closed ..., a NUL byte, ..., a question heading inside a fence, a questions file that is not a regular file under plain directories on the default branch, or a default branch whose tree or file could not be read)"

**Location:** `scripts/dev-cycle.sh:62-71`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `echo "skip ..."` in check_answer that dev-cycle.sh can reach; does not cover the "no default branch found by name" skip (`:550`), which dev-cycle.sh cannot reach because it exits 1 first (`scripts/dev-cycle.sh:193-195`).
**Legibility-target:** for-orchestrator-synthesis

I mapped each echo in check_answer to the list: `not a question ID (Q- and digits)` (`:549`), `notdir` gives "is not a directory on the default branch" (`:556`), `error` gives "the default branch's tree could not be read" (`:557`), other entry types give "is not a regular file on the default branch" (`:558`), and a failed cat-file gives "could not be read from the default branch" (`:562`). `dup` gives "more than one entry with this heading in $f" (`:564`). `odd` covers fence, html, comment, refdef, cr, nul and bom through `oddwhy` (`:231-241`, `:566`). The other arms are `unbalanced` (`:567`), `quoted` (`:568`), "an entry with this heading in both" (`:570`) and "no such entry" (`:574`). Each reason is in the help list. Tests 61-67 assert several of these strings and passed in E1.

**Evidence:** `scripts/lib/dev-cycle-read.sh:547-575`, `scripts/lib/dev-cycle-read.sh:231-241`, `scripts/dev-cycle.sh:62-71`, `$FC/logs/E1-bats-full.log`

---

## Claim 5: "--check-brief, --check-branch and --check-answer need a default branch found by name (origin/HEAD, main or master): they read its commit."

**Location:** `scripts/dev-cycle.sh:72-73` (also the comment at `:189-192`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exit-1 gate for the three modes; does not establish behavior when origin/HEAD names a branch that starts with `-` (resolve_main skips it, `scripts/lib/dev-cycle-read.sh:396`).
**Legibility-target:** for-orchestrator-synthesis

`if [[ "$CHECK" == --check-brief || "$CHECK" == --check-branch || "$CHECK" == --check-answer ]] && ! main_by_name; then` (`scripts/dev-cycle.sh:193`). Test "--check-answer needs a default branch found by name" (`test/scripts/dev-cycle.bats:1153-1158`) asserts status 1, empty stdout and "needs a default branch" on stderr. It passed in E1.

**Evidence:** `scripts/dev-cycle.sh:188-195`, `test/scripts/dev-cycle.bats:1153-1158`, `$FC/logs/E1-bats-full.log`

---

## Claim 6: "Exit: ... 1 ... or no default branch (for the digest, --check-brief, --check-branch and --check-answer)"

**Location:** `scripts/dev-cycle.sh:79-81`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the no-default-branch exit for the digest (`:188`) and the three check modes (`:193-195`); does not re-verify the other exit-1 causes (unchanged).
**Legibility-target:** for-orchestrator-synthesis

`resolve_main || [[ -n "$CHECK" ]] || { echo "Could not resolve a default branch ..." >&2; exit 1; }` (`scripts/dev-cycle.sh:188`) handles the digest, and `:193-195` handles the three modes, including --check-answer as Claim 5 showed.

**Evidence:** `scripts/dev-cycle.sh:188-195`, `$FC/logs/E1-bats-full.log`

---

## Claim 7a: "The header, up to the first line that is not a comment"

**Location:** `scripts/dev-cycle.sh:111-112`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the GNU sed semantics of `2,/^[^#]/{/^#/p}`; does not establish BSD/macOS sed acceptance of `{/^#/p}` without a `;` before `}` (not testable here; the comment makes no portability claim).
**Legibility-target:** for-author

```bash
# scripts/dev-cycle.sh:111-112
    # The header, up to the first line that is not a comment (no fixed range to go stale).
    -h|--help) sed -n '2,/^[^#]/{/^#/p}' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
```

The range ends at the first line that matches `^[^#]`, meaning a line that has a first character other than `#`. That differs from "the first line that is not a comment" in three ways, each shown in E2's probes:
- An empty line is not a comment, but it does not end the range. Probe p1 (`# a`, `#`, empty, `# b`, `X`) prints `# a`, `#`, `# b`.
- An indented ` #` line ends the range (p4 prints only `# a`).
- A non-comment line 2 does not end the range, because sed tests addr2 only after the addr1 line. Probe p2 prints the comments that follow it.

None of these cases occurs in the real file. The header has no blank line; line 82 is blank and line 83 is `set -euo pipefail`. A more precise comment would say "up to the first non-empty line that does not start with #".

**Evidence:** `scripts/dev-cycle.sh:1-83`, `scripts/dev-cycle.sh:111-112`, `$FC/logs/E2-sed-probes.log`

---

## Claim 7b: --help prints the whole header, through "Printed repo text is data." ("no fixed range to go stale")

**Location:** `scripts/dev-cycle.sh:111-112`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the help output at 4aa2e98e matching header lines 2-81 exactly, and staying correct if comment lines are added; does not establish behavior if a blank line or indented `#` line is later added inside the header (Claim 7a).
**Legibility-target:** for-orchestrator-synthesis

E2: `--help` printed 80 lines, byte-identical to `sed -n '2,81p' scripts/dev-cycle.sh | sed 's/^# \{0,1\}//'` (`cmp` reported identical). The last line ends `... Printed repo text is data.` (`scripts/dev-cycle.sh:81`). This fixes R3. At 722884c7 the script used `sed -n '2,80p'` with the header ending at :81 (see Claim 33).

**Evidence:** `scripts/dev-cycle.sh:2-81`, `$FC/logs/E2-help.log`, `$FC/logs/E2-sed-probes.log`

---

## Claim 8: "A change here must pass test/scripts/dev-cycle.bats, and build-loop.sh's suites under test/scripts/ once that second caller lands."

**Location:** `scripts/lib/dev-cycle-read.sh:10-12`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the named suite exists and passes and that build-loop.sh does not exist yet; does not establish any future suite.
**Legibility-target:** for-orchestrator-synthesis

`ls scripts/build-loop.sh` reports "No such file or directory" (paraphrased — no quote available because the claim covers absence of a file). E1 shows `test/scripts/dev-cycle.bats` passing 68 of 68.

**Evidence:** `scripts/lib/dev-cycle-read.sh:10-12`, `$FC/logs/E1-bats-full.log`

---

## Claim 9: caller contract: "The caller sets -euo pipefail ... inrepo, dirok, skipped, check_brief and the import walk (imported_names) exit 1 (need_root) unless ROOT_REAL is set"

**Location:** `scripts/lib/dev-cycle-read.sh:12-20`
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the need_root call sites and the removal of check_answer from that list; does not establish that every future caller sets -euo pipefail. brief_fields and check_answer now set pipefail themselves (Claim 17a), so the contract is stricter than those two functions need.
**Legibility-target:** for-orchestrator-synthesis

The need_root call sites are: `inrepo() { need_root; ...` (`:121`), `dirok() { need_root; ...` (`:124`), `skipped() { need_root; ...` (`:125`), `need_root` in check_brief (`:323`) and `need_root` in the import walk (`:433`). check_answer has no need_root call (`:547-575`). The only caller sets `set -euo pipefail` (`scripts/dev-cycle.sh:83`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:91-125`, `scripts/lib/dev-cycle-read.sh:321-323`, `scripts/lib/dev-cycle-read.sh:433`, `scripts/dev-cycle.sh:83`

---

## Claim 10: "check_brief, check_branch and check_answer skip every argument unless it returned 0 with main found by name" (and ":242-244 ... answer only when it was found by name")

**Location:** `scripts/lib/dev-cycle-read.sh:21-23`, `scripts/lib/dev-cycle-read.sh:242-244`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the main_by_name guard in all three functions; does not establish behavior if a caller sets MAIN_SHA/MAIN_BY_NAME by hand.
**Legibility-target:** for-orchestrator-synthesis

Each function opens with the same guard: `if ! main_by_name; then echo "skip ...: no default branch found by name ...` (check_brief `:324`, check_branch `:372`, check_answer `:550`). Test 62 calls `check_answer Q-1` before `resolve_main` and asserts the first output line `skip Q-1: no default branch found by name (origin/HEAD, main or master), or resolve_main has not run` (`test/scripts/dev-cycle.bats:1171`). It passed in E1.

**Evidence:** `scripts/lib/dev-cycle-read.sh:245-246`, `scripts/lib/dev-cycle-read.sh:324`, `:372`, `:550`, `test/scripts/dev-cycle.bats:1160-1175`

---

## Claim 11: "Inputs: check_brief, check_branch, check_answer, main_entry and brief_fields read the default branch's commit, never the working tree (check_brief also refuses a brief path that is not plain in the working tree ...)"

**Location:** `scripts/lib/dev-cycle-read.sh:29-32`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the content reads (ls-tree and cat-file against `$MAIN_SHA`) and check_brief's working-tree blocker; does not establish isolation from repo config or refs/replace (override row 235).
**Legibility-target:** for-orchestrator-synthesis

The reads are `git ls-tree -t --full-tree "$MAIN_SHA"` (`:263`), `git cat-file blob "$MAIN_SHA:$1"` (`:297`) and `git cat-file blob "$MAIN_SHA:$f"` (`:561`). check_brief's working-tree check is `blocker "$a" file` (`:329`). In tests 63 and 66 the working-tree copy differs from main's and is ignored (`test/scripts/dev-cycle.bats:1141-1144`, `:1219-1220`). Both passed in E1.

**Evidence:** `scripts/lib/dev-cycle-read.sh:258-312`, `:329`, `:547-575`, `test/scripts/dev-cycle.bats:1137-1151`, `:1210-1243`

---

## Claim 12: FENCE_AWK: "and anywhere in the file, fenced or not, a carriage return inside a line ..., a NUL byte (a caller reading the output through $(...) would lose it), or a byte-order mark on line 1"

**Location:** `scripts/lib/dev-cycle-read.sh:173-176` (also `:216`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order of checks in `fence()` (CR, NUL and BOM before the `infence` branch) under mawk; does not establish NUL handling under one-true-awk or busybox (override row 224).
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
(excerpt ends :218; enclosing fence() continues to :229 — read)

Both callers run `fence($0)` on every line (`:299`, `:509`). Test 64 refuses a NUL brief and a NUL questions file (passed in E1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:163-230`, `test/scripts/dev-cycle.bats:1177-1193`, `$FC/logs/E1-bats-full.log`

---

## Claim 13: main_entry prints "blob", "absent", "notfile", "notdir PART" or "error" (no default branch found by name, ls-tree failed, or the tree lists a name twice ...; never read as absent)

**Location:** `scripts/lib/dev-cycle-read.sh:247-254`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all five result words and the three error causes; does not establish handling of a tree entry whose name holds a slash (override row 236).
**Legibility-target:** for-orchestrator-synthesis

Each result word has its own line: `main_by_name || { echo error; return; }` (`:261`), `|| { echo error; return; }` after ls-tree (`:263`), `[[ -z "$dup" ]] || { echo error; return; }` (`:269`), `echo "notdir $p"` (`:271`), and `case "${m[$1]-}" in '') echo absent ;; 100644|100755) echo blob ;; *) echo notfile ;; esac` (`:273`). E7 builds a tree that lists questions.md twice: main_entry prints `error`. Test 64 prints `error` for main_entry without resolve_main and for a bogus MAIN_SHA. E8 shows `notdir`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:258-274`, `$FC/logs/E7-dup-tree.log`, `$FC/logs/E8-notdir.log`, `test/scripts/dev-cycle.bats:1187-1192`

---

## Claim 14: "One ls-tree call lists the path and every directory above it (-t: trees too; --full-tree: paths from the top level, whatever the current directory)"

**Location:** `scripts/lib/dev-cycle-read.sh:254-256`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the single ls-tree invocation and its output; does not establish its cost on large directories (override row 220).
**Legibility-target:** for-orchestrator-synthesis

`out="$(git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1" 2>/dev/null)"` (`:263`) is the only git call in main_entry. E7's ls-tree output lists `docs`, `docs/working` and both `docs/working/questions.md` entries. Test 62 runs check_answer from `docs/` (`cd docs; check_answer Q-1`, `test/scripts/dev-cycle.bats:1168`) and gets the same answer.

**Evidence:** `scripts/lib/dev-cycle-read.sh:258-274`, `$FC/logs/E7-dup-tree.log`, `test/scripts/dev-cycle.bats:1160-1175`

---

## Claim 15: "The caller has checked main_by_name and the path's form (pathform, so ls-tree prints it unquoted)."

**Location:** `scripts/lib/dev-cycle-read.sh:256-257`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three in-lib callers (check_brief, brief_fields, check_answer) and main_entry's own guard; does not establish future callers (U1b/U1c).
**Legibility-target:** for-author

main_entry checks main_by_name itself: `main_by_name || { echo error; return; }` (`:261`). One caller does not check it first. brief_fields runs `if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]; then BRIEF_ODD=error; return 1; fi` (`:294`) with no main_by_name test, so it relies on main_entry's guard. The path-form half holds: check_brief runs pathform at `:325`, brief_fields at `:294`, and check_answer passes only the two constant paths (`:551`). A more precise comment: "The caller has checked the path's form (pathform ...); without a default branch found by name main_entry answers error itself."

**Evidence:** `scripts/lib/dev-cycle-read.sh:256-261`, `:294`, `:324-325`, `:550-552`

---

## Claim 16: brief_fields contract: first unfenced line per key "whole, after one trailing CR is dropped"; "a key with no such line stays unset"; "Otherwise it sets no key and returns 1, with BRIEF_ODD "odd N WHY" ..., "unbalanced N" ... or "error" (... any main_entry answer but blob, its error included, or the blob could not be read)"

**Location:** `scripts/lib/dev-cycle-read.sh:275-287`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every documented return path; does not establish how callers judge the values (by design, "The callers judge the values").
**Legibility-target:** for-orchestrator-synthesis

`BRIEF=(); BRIEF_ODD=""` (`:293`), then the error return at `:294` and the read-failure return `|| { BRIEF_ODD=error; return 1; }` (`:304`). An `odd`/`unbalanced` line resets with `BRIEF=(); BRIEF_ODD="$l"; return 1` (`:308`). On success the function ends with the while loop, whose status is 0. Test 66 asserts every key, the CR drop (`Status: open\r` read as `Status: open`), the `odd 2 fence` and `unbalanced 2` results, and absent keys left unset. Test 67 asserts `refused [error]` for a deleted blob. Both passed in E1.

**Evidence:** `scripts/lib/dev-cycle-read.sh:288-312`, `test/scripts/dev-cycle.bats:1210-1243`, `:1245-1266`, `$FC/logs/E1-bats-full.log`

---

## Claim 17a: "pipefail for this function only (local -), so a failed read is caught whatever the caller set" (brief_fields; check_answer "as brief_fields")

**Location:** `scripts/lib/dev-cycle-read.sh:290-292`, `scripts/lib/dev-cycle-read.sh:548`
**Type:** Error-handling / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15: the read failure is caught with no caller options, with `set -eu`, and with `set -euo pipefail`, and the caller's options, including pipefail, are restored after a normal return, after an early `return 1`, and after `set -f`/`set +u` inside a `local -` function; does not establish bash 4.4-5.0 (Claim 17b).
**Legibility-target:** for-orchestrator-synthesis

`local - out l; set -o pipefail` (`:292`) and `local - a="$1" f e r hit="" where="" n why; set -o pipefail  # as brief_fields` (`:548`). In E6, under all three caller settings, check_answer printed `skip Q-1: docs/working/questions.md could not be read from the default branch` and brief_fields printed `refused [error]`. After each call, including brief_fields' early `return 1` on a bad path, `$-` and `pipefail` were unchanged (e.g. `after-check_answer: opts=[ehuB] pipefail=off`). A probe function that ran `local -; set -o pipefail; set -f; set +u; return 1` also left noglob off and `u` set.

The guard depends on the pipefail. With it removed from check_answer (mutant mpf_ans, E4), the read falls through to the archive and answers `keep Q-1`. With it removed from brief_fields (mpf_bf), brief_fields returns 0 with no keys. With `local -` replaced by `local` (mnl, E5), the caller's pipefail stays on and the test fails at "caller unchanged".

**Evidence:** `scripts/lib/dev-cycle-read.sh:289-312`, `:547-562`, `$FC/logs/E6-local-dash.log`, `$FC/logs/E4-mpf_ans.log`, `$FC/logs/E4-mpf_bf.log`, `$FC/logs/E5-mnl.log`

---

## Claim 17b: the same claim ("for this function only"; 4aa2e98e: "the caller's options come back on return") on bash 4.4-5.0

**Location:** `scripts/lib/dev-cycle-read.sh:290-292`, `scripts/lib/dev-cycle-read.sh:548`
**Type:** Invariant
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what bash's own release notes say about `local -` before 5.1; does not establish actual behavior on 4.4/5.0 (no such bash in the sandbox), and does not apply to bash 5.1+ (Claim 17a).
**Legibility-target:** for-orchestrator-synthesis

Bash's NEWS for 4.4 (`/usr/share/doc/bash/NEWS.gz:601-603`) says: "The `local' builtin takes a new argument: `-', which will cause it to save and the single-letter shell options and restore their previous values at function return." pipefail has no single-letter form. CHANGES for bash-5.1-alpha (`/usr/share/doc/bash/CHANGES.gz:647-648`) says: "i. Several changes to how `local -' restores the values of options and $SHELLOPTS." So on 4.4/5.0 the function-local pipefail may leak to a caller that had it off. This would not weaken the read check itself. Bash older than 4.4 rejects `local -`, but the lib already needs 4.2+ for `declare -gA` (`:288`). No minimum bash version is stated for these scripts: the only repo hits are in `hooks/auto-approve-allowed-commands.sh:436` and `:710` (paraphrased — no quote available because the claim covers the absence of a version statement for dev-cycle; `rg` over the repo, excluding docs/reviews and docs/working). Verifying this needs a bash 4.4 or 5.0 binary.

**Evidence:** `scripts/lib/dev-cycle-read.sh:288-292`, `/usr/share/doc/bash/NEWS.gz:601-603`, `/usr/share/doc/bash/CHANGES.gz:647-648`

---

## Claim 18: "The whole blob is read (no early exit: SIGPIPE under pipefail)."

**Location:** `scripts/lib/dev-cycle-read.sh:295`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the absence of `exit` in brief_fields' awk program and FENCE_AWK; does not measure SIGPIPE behavior.
**Legibility-target:** for-orchestrator-synthesis

The awk program has rules `{ sub(/\r$/, "") }`, `fence($0) { next }`, a `match(...)` rule and `END { ... }` (`:298-303`). FENCE_AWK (`:186-230`) holds only functions. Neither contains `exit` (paraphrased — no quote available because the claim covers absence of code; read in full).

**Evidence:** `scripts/lib/dev-cycle-read.sh:186-230`, `:297-304`

---

## Claim 19: check_brief: "its Status line from brief_fields ... neither is one stored as anything but a regular file under plain directories (main_entry)"; c8435580: "check_brief also skips a brief whose directory is not a directory on main (before, ls-tree printed nothing and it read as "new")"

**Location:** `scripts/lib/dev-cycle-read.sh:313-320` (commit c8435580 body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the symlinked-parent-directory case before and after the change, and the Status read through brief_fields; does not re-test gitlinks (override row 230).
**Legibility-target:** for-orchestrator-synthesis

E8 put a symlinked `docs/working/briefs` on main and a plain copy in the working tree. Main's dev-cycle.sh printed `ok docs/working/briefs/2026-01-01-a.md new`, while the branch's printed `skip docs/working/briefs/2026-01-01-a.md: docs/working/briefs is not a directory on the default branch`. The code is `notdir\ *) echo "skip $a: ${e#notdir } is not a directory on the default branch"; return ;;` (`:336`) and `st="${BRIEF[status]-}"` (`:348`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:321-360`, `$FC/logs/E8-notdir.log`

---

## Claim 20: check_answer "reads only git objects, so it needs no ROOT_REAL and adds nothing to SKIPPED"

**Location:** `scripts/lib/dev-cycle-read.sh:541-546`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_answer's own body, which has no need_root, skipped, or working-tree file test; does not establish that git itself reads no working-tree state (config, alternates).
**Legibility-target:** for-orchestrator-synthesis

check_answer's body calls only `main_entry` and `git cat-file blob "$MAIN_SHA:$f"` (`:552`, `:561`). It has no `need_root` or `skipped` call (paraphrased — no quote available because the claim covers absence of calls; body `:547-575` read in full). Test 62 runs with ROOT_REAL set at the top level and a symlinked archive, then unset in `docs/`. It asserts `skipped=0` and the same skip line both times, and passed in E1.

**Evidence:** `scripts/lib/dev-cycle-read.sh:547-575`, `test/scripts/dev-cycle.bats:1160-1175`

---

## Claim 21: "A failed read is a skip, never a fall-through to the other file."

**Location:** `scripts/lib/dev-cycle-read.sh:560`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a missing questions.md blob with an answering archive present, under any caller options on bash 5.2; does not establish a partially readable blob (truncated object).
**Legibility-target:** for-orchestrator-synthesis

`r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk ...)" || { echo "skip $a: $f could not be read from the default branch"; return; }` (`:561-562`). Test 67 asserts that skip with a `[1]` answer in the archive, and passed in E1. Without the function's pipefail (E4 mpf_ans) the same input answers `keep Q-1`, which is the fall-through the comment rules out.

**Evidence:** `scripts/lib/dev-cycle-read.sh:560-563`, `test/scripts/dev-cycle.bats:1245-1257`, `$FC/logs/E4-mpf_ans.log`

---

## Claim 22: "it reads `questions.md` and `questions-archive.md` from the default branch's commit, so an answer, or an archive move, made only in the working tree is not seen until it lands (it reads what main's copy says, usually `open` or no such entry)"

**Location:** `skills/dev-cycle/SKILL.md:292-295`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the read source and the two usual outcomes; "usually" hedges the others (main's older answer, `unrecognized`, a skip), which A14 asked to be acknowledged. It does not establish each of those outcomes by test.
**Legibility-target:** for-orchestrator-synthesis

Test 63 (T34) asserts `open Q-1` for a working-tree-only answer and for a branch-only commit, and `drop Q-1` once merged into main. An entry absent on main falls to `skip $a: no such entry ... on the default branch` (`scripts/lib/dev-cycle-read.sh:574`).

**Evidence:** `skills/dev-cycle/SKILL.md:289-298`, `test/scripts/dev-cycle.bats:1118-1135`, `scripts/lib/dev-cycle-read.sh:573-574`

---

## Claim 23: "A questions.md that is not plain is reported, not passed over to the archive."

**Location:** `test/scripts/dev-cycle.bats:650`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the committed-symlink case in the test; the assertion is a prefix match (`*`), so it does not pin the rest of the line.
**Legibility-target:** for-orchestrator-synthesis

The archive written at `:642` holds Q-100. After `git add -A && git commit -qm link` (`:652`) the test asserts `skip Q-100: docs/working/questions.md is not a regular file on the default branch"*` (`:654`), not an archive answer. It passed in E1.

**Evidence:** `test/scripts/dev-cycle.bats:625-655`, `scripts/lib/dev-cycle-read.sh:558`

---

## Claim 24: test title "--check-brief and --check-branch need a default branch found by name; the others do not"

**Location:** `test/scripts/dev-cycle.bats:767`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the title against the gate at 4aa2e98e; the test body checks only --check-path for "the others", so its assertions still hold.
**Legibility-target:** for-author

This branch adds --check-answer to the modes that need a default branch: `if [[ "$CHECK" == --check-brief || "$CHECK" == --check-branch || "$CHECK" == --check-answer ]] && ! main_by_name; then` (`scripts/dev-cycle.sh:193`). Test "--check-answer needs a default branch found by name" (`test/scripts/dev-cycle.bats:1153`) asserts exit 1, and it passed in E1. So "the others do not" is no longer true of --check-answer. The title is unchanged context in a file this branch edits, and it is not in the override log. A precise title: "--check-brief, --check-branch and --check-answer need a default branch found by name; --check-path does not". Optionally `--check-answer` could join the loop at `:770`.

**Evidence:** `test/scripts/dev-cycle.bats:767-778`, `test/scripts/dev-cycle.bats:1153-1158`, `scripts/dev-cycle.sh:193`

---

## Claim 25: T34 test: "--check-answer reads main's commit: a working-tree or branch-only answer is open" and its comments (":1122 Answered only in the working tree: still open"; ":1126 Committed only on another branch: still open"; ":1131 A working tree with no questions file at all reads main's.")

**Location:** `test/scripts/dev-cycle.bats:1118-1135`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the title and comments against the assertions; does not cover build-loop.sh's T34 side (override row 221).
**Legibility-target:** for-orchestrator-synthesis

The assertions are `[ "$output" = "open Q-1" ]` (`:1125`, `:1130`) and, after `git merge -q side && rm docs/working/questions.md`, `[ "$output" = "drop Q-1" ]` (`:1134`). They match each comment, and the test passed in E1.

**Evidence:** `test/scripts/dev-cycle.bats:1118-1135`, `$FC/logs/E1-bats-full.log`

---

## Claim 26: test "--check-answer refuses a questions file or directory that is not plain on main, whatever the working tree holds" and comments at :1141, :1146

**Location:** `test/scripts/dev-cycle.bats:1137-1151`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a symlinked file and a symlinked parent directory on main; does not cover a gitlink.
**Legibility-target:** for-orchestrator-synthesis

The test asserts `skip Q-1: docs/working/questions.md is not a regular file on the default branch, so no entry in it is read` with a plain working-tree file present (`:1144`). It then asserts `skip Q-1: docs/working is not a directory on the default branch, so docs/working/questions.md is not read` (`:1149`). It passed in E1.

**Evidence:** `test/scripts/dev-cycle.bats:1137-1151`, `scripts/lib/dev-cycle-read.sh:556-558`

---

## Claim 27: test "check_answer reads git only: no ROOT_REAL needed, SKIPPED untouched, skip without main by name"

**Location:** `test/scripts/dev-cycle.bats:1160-1175`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the title's three properties against the assertions; does not re-run the comment's historical claim that the old working-tree reader added the symlinked archive to SKIPPED (78703f22 reports this as mutation-checked).
**Legibility-target:** for-orchestrator-synthesis

The expected output is the no-main skip line, then the archive-not-regular skip, then `skipped=0`, then the same skip from `docs/` with ROOT_REAL unset (`:1171-1174`). It passed in E1.

**Evidence:** `test/scripts/dev-cycle.bats:1160-1175`, `$FC/logs/E1-bats-full.log`

---

## Claim 28: test "a NUL byte refuses a brief or a questions file, never dropped into a value; main_entry fails closed"

**Location:** `test/scripts/dev-cycle.bats:1177-1193`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the brief, the questions file and main_entry's error without main or with a bad MAIN_SHA; does not cover awks other than mawk.
**Legibility-target:** for-orchestrator-synthesis

The test asserts the brief skip, the questions skip at `line 4`, and `error` / `refused [odd 2 nul] 0` / `error` (`:1190-1192`). It passed in E1.

**Evidence:** `test/scripts/dev-cycle.bats:1177-1193`

---

## Claim 29: T31 tests: "a brief shaped like the skill's template parses: check_brief and brief_fields agree" and "brief_fields reads each machine line's first unfenced copy from main in one pass; check_brief agrees"

**Location:** `test/scripts/dev-cycle.bats:1195-1208`, `test/scripts/dev-cycle.bats:1210-1243`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the titles and the :1219 and :1230 comments against the assertions; "in one pass" is checked statically (one awk invocation, `scripts/lib/dev-cycle-read.sh:297`); the template test does not compare against the skill's live template text.
**Legibility-target:** for-orchestrator-synthesis

The first test asserts `[Status: open] [unset]` and `ok $b open ...` (`:1207`). The second asserts all six keys from the first unfenced copies, ignoring the fenced `Status: done`/`Branch: fenced` and the later duplicates. It also asserts that the working-tree overwrite is ignored, and the `odd`/`unbalanced` refusals (`:1226-1242`). Both passed in E1.

**Evidence:** `test/scripts/dev-cycle.bats:1195-1243`, `scripts/lib/dev-cycle-read.sh:297-303`

---

## Claim 30: test 67 "an unreadable blob or a tree naming a file twice is a skip, never a fall-through or a read of the other copy"; ":1254 Delete the two blobs ...: neither read may pass as absent or empty"; ":1260 The same without the caller's pipefail: each function sets its own."

**Location:** `test/scripts/dev-cycle.bats:1245-1266`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the assertions can fail: three mutants make the test fail; does not cover a caller with no options at all inside the test (E6 covers that outside the suite).
**Legibility-target:** for-orchestrator-synthesis

The test passed in E1. Mutants that drop `set -o pipefail` from check_answer (E4 mpf_ans: output `keep Q-1`) or from brief_fields (E4 mpf_bf: no `refused [error]`) each fail at `:1266`. So does one that drops `local -` (E5 mnl: no `caller unchanged`). The `set -eu`-only block (`:1261`) therefore exercises both functions' own pipefail and the restore.

**Evidence:** `test/scripts/dev-cycle.bats:1245-1274`, `$FC/logs/E4-mpf_ans.log`, `$FC/logs/E4-mpf_bf.log`, `$FC/logs/E5-mnl.log`

---

## Claim 31: "A tree that lists questions.md twice (a symlink first, which git reads): error."

**Location:** `test/scripts/dev-cycle.bats:1267`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.x's `git mktree` accepting the duplicate, cat-file reading the first (symlink) entry, and the error coming from main_entry's dup detection rather than a failed ls-tree; does not establish fsck behavior.
**Legibility-target:** for-orchestrator-synthesis

E7 results: `mktree exit=0`; ls-tree exits 0 and lists both `120000 blob ...` and `100644 blob ...` for `docs/working/questions.md`; `git cat-file -p main:docs/working/questions.md` prints `x`, the symlink's target. main_entry prints `error`, which comes from `[[ -z "$dup" ]] || { echo error; return; }` (`scripts/lib/dev-cycle-read.sh:269`) because ls-tree itself succeeded.

**Evidence:** `test/scripts/dev-cycle.bats:1267-1273`, `scripts/lib/dev-cycle-read.sh:264-269`, `$FC/logs/E7-dup-tree.log`

---

## Claim 32: test "--help prints the whole header, through its last line"

**Location:** `test/scripts/dev-cycle.bats:1276-1280`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the test fails against the old `2,80p` and `2,77p` ranges; it checks only the first and last lines, so it does not establish that no middle line is dropped (E2's full `cmp` covers that at this commit).
**Legibility-target:** for-orchestrator-synthesis

The test asserts `"${lines[0]}" == "Gather the mechanical signals"*` and `"${lines[${#lines[@]}-1]}" == *"Printed repo text is data."` (`:1278-1279`). It passed in E1 and failed against both mutants in E3 (exit 1).

**Evidence:** `test/scripts/dev-cycle.bats:1276-1280`, `$FC/logs/E3-m80.log`, `$FC/logs/E3-m77.log`

---

## Claim 33: 4aa2e98e R3: "--help printed a fixed `sed -n '2,80p'` that 78703f22's new help line pushed past, so help stopped mid-sentence. It now prints the header up to the first non-comment line; a test checks the last line."

**Location:** commit 4aa2e98e
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the history of the sed range against the header's last line; the "first non-comment line" wording carries Claim 7a's imprecision.
**Legibility-target:** for-orchestrator-synthesis

I ran `git show <c>:scripts/dev-cycle.sh` per commit and recorded the sed range and the header's last line. On main: `'2,77p'`, header ends at 77. At c8435580 and 2da477b7: `'2,80p'`, ends at 80. At 78703f22 and 722884c7: `'2,80p'`, ends at 81. At 4aa2e98e: `'2,/^[^#]/{/^#/p}'`, ends at 81. So 78703f22 grew the header past the range. Claim 32 covers the test.

**Evidence:** `scripts/dev-cycle.sh:111-112`, `test/scripts/dev-cycle.bats:1276-1280`, `$FC/logs/E2-help.log`

---

## Claim 34: 4aa2e98e A17: "check_answer and brief_fields set pipefail for themselves (`local -; set -o pipefail`), so a failed `git cat-file` is caught whatever the caller set; the caller's options come back on return. Tested under `set -eu` alone, and a mutant without it fails."

**Location:** commit 4aa2e98e
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2 (Claim 17a) and the test and mutant statements; the "caller's options come back" residue on bash 4.4-5.0 is Claim 17b. The literal `local -; set -o pipefail` is shorthand: the code is `local - out l; set -o pipefail` and `local - a=... ; set -o pipefail`.
**Legibility-target:** for-orchestrator-synthesis

The test runs `bash -c 'set -eu; ...'` (`test/scripts/dev-cycle.bats:1261`). The no-pipefail mutants fail it (E4), as does the no-`local -` mutant (E5).

**Evidence:** `scripts/lib/dev-cycle-read.sh:292`, `:548`, `test/scripts/dev-cycle.bats:1260-1266`, `$FC/logs/E4-mpf_ans.log`, `$FC/logs/E4-mpf_bf.log`, `$FC/logs/E5-mnl.log`, `$FC/logs/E6-local-dash.log`

---

## Claim 35: 4aa2e98e A14/A15: "the help and SKILL.md say a working-tree-only answer reads what main's copy says (usually open or no such entry)"

**Location:** commit 4aa2e98e
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both files saying "what main's copy says"; the parenthetical appears only in SKILL.md (the help says "until committed" instead, see Claim 2).
**Legibility-target:** for-orchestrator-synthesis

The help says `it reads what main's copy says, until committed` (`scripts/dev-cycle.sh:59`). SKILL.md says `(it reads what main's copy says, usually `open` or no such entry)` (`skills/dev-cycle/SKILL.md:294-295`).

**Evidence:** `scripts/dev-cycle.sh:56-59`, `skills/dev-cycle/SKILL.md:292-295`

---

## Claim 36: 4aa2e98e A16: "--check-answer's skip list names "not a question ID" and a heading in both files."

**Location:** commit 4aa2e98e
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two named additions; completeness of the whole list is Claim 4.
**Legibility-target:** for-orchestrator-synthesis

`<reason>" when it cannot be read (not a question ID, no such` and `entry, a heading twice in one file or in both files, ...` (`scripts/dev-cycle.sh:63-64`).

**Evidence:** `scripts/dev-cycle.sh:62-71`

---

## Claim 37: 4aa2e98e "Override-log rows: A18 and iteration 3's C9 residue, C11-C15."

**Location:** commit 4aa2e98e
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the rows exist and were added in this commit; does not judge the rows' dispositions (settled).
**Legibility-target:** for-orchestrator-synthesis

`git show 4aa2e98e --stat` lists `docs/reviews/override-log.md | 7 +++++++`. The rows are `docs/reviews/override-log.md:232` (A18), `:233` (C11), `:234` (C12), `:235` (C13), `:236` (C14), `:237` (C15) and `:238` (C9 residue), each tagged with its ID in the row text.

**Evidence:** `docs/reviews/override-log.md:232-238`

---

## Claim 38: c8435580: "dev-cycle.sh --check-answer exits 1 without such a branch, like --check-brief and --check-branch"

**Location:** commit c8435580
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exit code and stderr; same evidence as Claim 5.
**Legibility-target:** for-orchestrator-synthesis

`echo "$CHECK needs a default branch (origin/HEAD, main or master); found none" >&2; exit 1` (`scripts/dev-cycle.sh:194`). The test at `test/scripts/dev-cycle.bats:1153-1158` passed in E1.

**Evidence:** `scripts/dev-cycle.sh:193-195`, `test/scripts/dev-cycle.bats:1153-1158`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
- **Claim 24** (`test/scripts/dev-cycle.bats:767`): the test title says modes other than --check-brief/--check-branch do not need a default branch found by name, but --check-answer now does (`scripts/dev-cycle.sh:193`). Rename the title, or add --check-answer to its loop.

### Mostly Accurate
- **Claim 2** (`scripts/dev-cycle.sh:59`): "until committed" should be "until it lands on the default branch". A commit on another branch still reads open (T34).
- **Claim 7a** (`scripts/dev-cycle.sh:111`): the range ends at the first non-empty line not starting with `#`. An empty line does not end it, and an indented `#` does. Harmless for the current header.
- **Claim 15** (`scripts/lib/dev-cycle-read.sh:256-257`): main_entry checks main_by_name itself, and brief_fields does not check it before calling. The comment should say only the path form is the caller's job.

### Unverifiable
- **Claim 17b** (`scripts/lib/dev-cycle-read.sh:292`, `:548`): whether `local -` restores pipefail on bash 4.4-5.0. Bash 4.4 NEWS says it saves only single-letter options, and 5.1 changed it. Checking needs a 4.4/5.0 bash. No minimum bash version is stated for these scripts.

Hallucination-pattern log: no Incorrect verdicts, so nothing to append.

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved to docs/reviews/code-fact-check-report-build-loop-u1a-r2.md, structured per the code-fact-check skill, first line `Commit: 4aa2e98e`.
- Answered: yes
- Out of scope: BSD/macOS sed acceptance of `{/^#/p}` and bash 4.4/5.0 `local -` behavior (no such binaries in the sandbox); claims in 2da477b7/78703f22/722884c7 bodies already verdicted by earlier iterations were not re-run beyond what overlaps the claims above.
- Escalate: to the orchestrator/rubric synthesis: Claim 24, a stale test title that is new to this pass and not in the override log. To api-consistency-reviewer or the orchestrator: whether a minimum bash version (5.1+ for `local -` restoring pipefail, per Claim 17b) should be stated for scripts/lib/dev-cycle-read.sh. That is a portability/contract question, not a correctness defect in the read check.
- Decisions I made: Split the help sed comment into 7a (mechanism, Mostly accurate) and 7b (outcome, Verified), and split the `local -` claim into 17a (bash 5.2, executed, Verified) and 17b (older bash, Unverifiable). Captured execution logs under my scratch dir, not docs/reviews/execution-logs/, so that no tracked file but this report changes.
