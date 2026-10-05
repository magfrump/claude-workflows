Commit: 4aa2e98e

# Code Fact-Check Report

**Repository:** claude-workflows (`/workspace/.claude/wt-build-loop-u1a`, branch `feat/build-loop-u1a`, HEAD 4aa2e98e, base `main` f6357ea1 = merge-base)
**Scope:** Stage-2.5 submitted-claims pass only (iteration 4, final confirming pass): the 17 critic endorsements in the review's `shared/submitted.md` (S1-S3, P1-P2, A1-A6, G1-G6 → Claims 40-56 in listed order), checked against `scripts/dev-cycle.sh`, `scripts/lib/dev-cycle-read.sh` and `test/scripts/dev-cycle.bats` at 4aa2e98e, with 722884c7's `scripts/` materialised for P1. No harvested claims (numbering continues the main report's).
**Checked:** 2026-10-05
**Total claims checked:** 17
**Summary:** 16 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

I read the hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 5 entries) first. Claim 50 (a test count) belongs to the logged class "a specific measured value quoted from an artifact set". It was checked by running the suite and holds (68 of 68). No other claim resembles a logged pattern.

Environment for every executed claim: Linux (WSL2), GNU bash 5.2.15, git 2.39.5, `awk` = mawk 1.3.4 20200120 (gawk is not installed), GNU sed 4.9. bats ran with `LC_ALL=C.UTF-8` and TMPDIR unset. Probe repos were built with `git init` inside the scratch dir `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i4/submitted/` (abbreviated `$S`), and all captured output is there, not in the repo: this pass may write no repo file other than this report. The worktree's repo was only read. I extracted 722884c7's and 4aa2e98e's `scripts/` with `git archive <rev> scripts | tar -x -C $S/perf/{old,new}`. Each probe script is saved next to its output (`probe.sh` beside `probe.out`). The worktree's only uncommitted changes are under `docs/reviews/`. No code file differs from 4aa2e98e.

Full bats run: `bats test/scripts/dev-cycle.bats`, cwd `/workspace/.claude/wt-build-loop-u1a`, 2026-10-05T16:46:44Z to 16:47:01Z, exit 0. All 68 tests pass. Output: `$S/bats/bats-full.out`.

---

## Submitted Claims

## Claim 40: "check_answer prints a skip line ("could not be read from the default branch") when main's questions.md blob cannot be read, under caller options -euo pipefail, -eu, and +e +u, and leaves the caller's pipefail setting as it found it."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:548`, `scripts/lib/dev-cycle-read.sh:561-562`
**Type:** Error-handling / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a deleted loose object for `docs/working/questions.md` while the archive holds a conflicting ANSWERED entry (a fall-through would print `keep Q-1`), under the caller option sets `-euo pipefail`, `-eu`, `+e +u` and `-e -o pipefail -o noglob`. In each, the skip line prints, there is no fall-through, and `$-` plus the pipefail state match before and after, early-return paths included. It does not establish five things: behaviour on bash older than 5.2 (`local -` semantics; see Claim 48), a packed or truncated object, a read that fails after awk has already printed an answer, git's own `fatal:` line on stderr (it reaches the caller unscrubbed when the lib is used directly; override row 238), or the archive's own unreadable blob.

The function makes pipefail local, and the read's failure branch returns:

```bash
# scripts/lib/dev-cycle-read.sh:548
  local - a="$1" f e r hit="" where="" n why; set -o pipefail  # as brief_fields
# scripts/lib/dev-cycle-read.sh:560-562
    # A failed read is a skip, never a fall-through to the other file.
    r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk -v id="$a" "$FENCE_AWK$ANSWER_AWK")" \
      || { echo "skip $a: $f could not be read from the default branch"; return; }
```
(excerpt ends :562; enclosing check_answer() continues to :575 — read)

Probe: `./probe.sh /workspace/.claude/wt-build-loop-u1a/scripts/lib/dev-cycle-read.sh`, cwd `$S/opts`, 2026-10-05T16:48:13Z, exit 0. Controls: `drop Q-1` with the blobs intact, and `keep Q-1` with the archive alone. After the blob is deleted, every option set prints `skip Q-1: docs/working/questions.md could not be read from the default branch`. The state lines `before:`/`after check_answer:` are identical in each, for example `[ehuBc set +o pipefail]` both times under `-eu`, and `[hBc set +o pipefail]` both times under `+e +u`. Mutant (`$S/opts/mutant-nopipefail.sh`, `set -o pipefail` removed from both functions), same probe at 16:48:24Z: under `-eu` it prints `keep Q-1`, which is the fall-through. The function's own pipefail is load-bearing.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/dev-cycle-read.sh:547-575`, `$S/opts/probe.sh`, `$S/opts/probe.out`, `$S/opts/mutant.out`

---

## Claim 41: "brief_fields returns 1 with BRIEF_ODD=error when cat-file fails or awk alone fails, under -eu."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:292`, `scripts/lib/dev-cycle-read.sh:297-304`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers two failures: a deleted brief blob, and an `awk` that exits 2 after draining stdin (a PATH shim, which `env LC_ALL=C awk` resolves) with the blob intact. Under `-eu`, and also under `-euo pipefail` and `+e +u`, brief_fields returns 1 with `BRIEF_ODD=error` and 0 keys. It does not establish an awk that crashes after printing partial key lines, nor bash versions other than 5.2.

```bash
# scripts/lib/dev-cycle-read.sh:292-294
  local - out l; set -o pipefail
  BRIEF=(); BRIEF_ODD=""
  if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]; then BRIEF_ODD=error; return 1; fi
# scripts/lib/dev-cycle-read.sh:303-304
    END { if (odd) print "odd " odd " " oddwhy; else if (infence) print "unbalanced " fline; else for (i = 1; i <= nk; i++) print kv[i] }')" \
    || { BRIEF_ODD=error; return 1; }
```
(excerpt ends :304; enclosing brief_fields() continues to :312 — read; the `while read` loop at :305-311 runs only on success)

Runs. (1) The deleted blob, in `$S/opts/probe.sh` (2026-10-05T16:48:13Z, exit 0): `brief_fields rc=1 odd=[error] keys=0` under all four option sets. (2) The awk shim, run inline from cwd `$S/opts/repo2` with `PATH="$S/opts/shim:$PATH"` at 16:48:24Z: `-eu: brief_fields rc=1 odd=[error] keys=0`, and the same line for `-euo pipefail` and `+e +u`.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/dev-cycle-read.sh:289-312`, `$S/opts/probe.out`, `$S/opts/awkfail.out`, `$S/opts/shim/awk`

---

## Claim 42: "check_answer reads only main_entry and `git cat-file blob "$MAIN_SHA:$f"` over a two-item constant list; a working-tree-only answer reads open (test 60, T34)."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:547-575`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every git argv check_answer issues for two IDs (logged by a git PATH shim): `ls-tree -t --full-tree <sha> -- docs docs/working <file>` (main_entry) and `cat-file blob <sha>:<file>`, for the two constant files only. It also covers the working-tree independence case: a working-tree-only ANSWERED entry reads `open`, and still does after the working-tree questions.md is made unreadable (mode 000) and the archive is replaced by a dangling symlink. awk gets no file operand. It does not establish syscall-level absence of file opens (no strace in the sandbox), nor anything about git's own repository discovery, which uses the current directory.

```bash
# scripts/lib/dev-cycle-read.sh:551-552
  for f in docs/working/questions.md docs/working/questions-archive.md; do
    e="$(main_entry "$f")"
```
(excerpt ends :552; enclosing check_answer() continues to :575 — read; the only other external command is the `git cat-file blob … | env LC_ALL=C awk …` pipeline at :561, which passes awk no file name)

Probe: `./probe.sh`, cwd `$S/s3`, 2026-10-05T16:51:00Z, exit 0. Output: `open Q-1`, `open Q-2`, then exactly 8 logged argv lines, alternating `git ls-tree -t --full-tree <sha> -- docs docs/working docs/working/questions{,-archive}.md` and `git cat-file blob <sha>:docs/working/questions{,-archive}.md`. After the working tree was broken, the output was again `open Q-1`, `open Q-2`. Bats test 60 (T34) passed in the full run.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/dev-cycle-read.sh:547-575`, `scripts/lib/dev-cycle-read.sh:258-274`, `test/scripts/dev-cycle.bats:1118-1135`, `$S/s3/probe.sh`, `$S/s3/probe.out`, `$S/bats/bats-full.out`

---

## Claim 43: "4aa2e98e's check_brief and check_answer run within noise of 722884c7, with identical git call counts (check_brief: cat-file 1, log 1, ls-tree 2; check_answer: cat-file 2, ls-tree 2) and byte-identical output."

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:321-360`, `scripts/lib/dev-cycle-read.sh:547-575`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a fixture with both questions files present (20 answered and 20 open entries), and a brief whose Status line was committed. The counts are per call after resolve_main, for an `ok … open` brief and for IDs that answer, read open and are absent. Output was compared over 41 IDs and four brief arguments. Timing came from 30 alternating runs per side. It does not establish the counts in other shapes. With an absent archive check_answer issues 1 cat-file. A brief that skips before brief_fields issues no cat-file. The `:358` fallback issues 2 logs. Other machines or loads were not measured.

The two revisions differ in code only by `local -` and `set -o pipefail` at `:292` and `:548` (paraphrased — no quote available because this summarises `git diff 722884c7 4aa2e98e -- scripts/lib/dev-cycle-read.sh`, a 6-line diff, reproduced above in my run log rather than in the source).

Counts: an inline loop sourced each revision's lib with a logging git shim (`$S/perf/shim/git`), cwd `$S/perf/repo`, about 16:48Z. Both revisions give `1 cat-file, 1 log, 2 ls-tree` for check_brief and `2 cat-file, 2 ls-tree` for `check_answer Q-5|Q-25|Q-99`, with identical answer lines. Timing and bytes: `../timing.sh $S`, cwd `$S/perf/repo`, 2026-10-05T16:49:11Z, exit 0. It printed `byte-identical` (cmp of 41-line answer output and 4-line brief output). Medians, old vs new: `--check-answer` with 41 IDs 312.9 vs 315.0 ms (+0.7%); `--check-brief` × 5 73.5 vs 74.2 ms (+0.9%). Minima differ by under 2%.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/dev-cycle-read.sh:289-360`, `scripts/lib/dev-cycle-read.sh:547-575`, `$S/perf/counts.out`, `$S/perf/timing.sh`, `$S/perf/timing.out`, `$S/perf/timing.raw`, `$S/perf/ans.old`, `$S/perf/ans.new`

---

## Claim 44: "The `2,/^[^#]/` help range costs the same as `2,80p` (sed reads the whole 471-line file both times); --help takes ~8 ms."

**Submitted by:** performance-reviewer
**Location:** `scripts/dev-cycle.sh:112`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers GNU sed 4.9. Neither program stops reading early: the script plus a 10 MB tail was piped in, and the producer exited 0 for both, while the control `2,80p;80q` got SIGPIPE (141). The file has 471 lines. Wall time of the whole `--help` invocation is about 8 ms on both revisions. It does not establish BSD or busybox sed, nor a per-sed-process time apart from the script's startup.

```bash
# scripts/dev-cycle.sh:111-112
    # The header, up to the first line that is not a comment (no fixed range to go stale).
    -h|--help) sed -n '2,/^[^#]/{/^#/p}' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
```

Probe: `./probe.sh`, cwd `$S/sedread`, 2026-10-05T16:49:46Z, exit 0. Output: `sed -n '2,80p': producer status 0`, `sed -n '2,/^[^#]/{/^#/p}': producer status 0`, `sed -n '2,80p;80q': producer status 141`, and `471` lines. `--help` timing from `$S/perf/timing.out`: median 8.0 ms (722884c7, `2,80p`) against 7.9 ms (4aa2e98e).

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/dev-cycle.sh:111-112`, `$S/sedread/probe.sh`, `$S/sedread/probe.out`, `$S/perf/timing.out`

---

## Claim 45: "--help prints the whole header, and test 68 checks its last line (scripts/dev-cycle.sh:111-112; bats end)."

**Submitted by:** api-consistency-reviewer
**Location:** `scripts/dev-cycle.sh:111-112`, `test/scripts/dev-cycle.bats:1276-1280`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers today's header. `--help` output is byte-identical to lines 2-81 with `# ` stripped (80 lines, ending "Printed repo text is data."). Line 82 is empty and line 83 is `set -euo pipefail`. Test 68 fails against the `2,80p` and `2,77p` mutants. It does not establish the range's behaviour if the header later gains a line that is empty or starts with an indented `#` (`^[^#]` skips an empty line, so such a header would run on), nor BSD sed's acceptance of `{/^#/p}` without a `;`.

```bash
# test/scripts/dev-cycle.bats:1276-1280
@test "--help prints the whole header, through its last line" {
    run --separate-stderr bash "$DC" --help
    [ "$status" -eq 0 ] && [[ "${lines[0]}" == "Gather the mechanical signals"* ]] \
        && [[ "${lines[${#lines[@]}-1]}" == *"Printed repo text is data." ]] || { echo "$output"; return 1; }
}
```

Runs from cwd `$S/help`, 2026-10-05T16:49:59Z: `bash dev-cycle.sh --help > help.out` exited 0. `cmp help.out expect.out` printed "help == header lines 2-81", where `expect.out` is `sed -n '2,81p' | sed 's/^# \{0,1\}//'`. `grep -v '^#'` over lines 1-81 found nothing. Two mutants were run in a copy of `scripts/` and the test file under `$S/help/mut`, each with `bats -f 'help prints the whole header'`. `2,80p` gave exit 1 (`not ok 1`), and so did `2,77p`. The real file gave exit 0.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/dev-cycle.sh:1-83`, `test/scripts/dev-cycle.bats:1276-1280`, `$S/help/help.out`, `$S/help/expect.out`, `$S/help/mutants.out`, `$S/help/real.out`

---

## Claim 46: "The --check-answer default-branch gate is consistent across help (:72-73), Exit text (:81), code (:193) and its test (bats ~:1153)."

**Submitted by:** api-consistency-reviewer
**Location:** `scripts/dev-cycle.sh:72-73`, `scripts/dev-cycle.sh:81`, `scripts/dev-cycle.sh:193`, `test/scripts/dev-cycle.bats:1153-1158`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four sites named. All say --check-answer needs a default branch found by name and exits 1 without one. A repo whose only branch is `trunk` gives exit 1, empty stdout and `--check-answer needs a default branch …` on stderr, the same as --check-brief and --check-branch. --check-path and --check-write exit 0 there. It does not cover other sites. The title of `test/scripts/dev-cycle.bats:767` ("--check-brief and --check-branch need a default branch found by name; the others do not") is now stale: the body tests only --check-path as an "other", but the title contradicts the gate. Stage 1 replicate r2 flagged this.

Help: `#   --check-brief, --check-branch and --check-answer need a default branch` / `#   found by name (origin/HEAD, main or master): they read its commit.` (`scripts/dev-cycle.sh:72-73`). Exit text: `# default branch (for the digest, --check-brief, --check-branch and --check-answer)` (`scripts/dev-cycle.sh:81`). Code: `if [[ "$CHECK" == --check-brief || "$CHECK" == --check-branch || "$CHECK" == --check-answer ]] && ! main_by_name; then` (`scripts/dev-cycle.sh:193`), followed by `exit 1` at `:194`. Test: `[ "$status" -eq 1 ] && [ -z "$output" ] && [[ "$stderr" == *"needs a default branch"* ]]` (`test/scripts/dev-cycle.bats:1157`).

Probe: `./probe.sh`, cwd `$S/gate`, 2026-10-05T16:50:10Z, exit 0. For example: `--check-answer Q-1 -> exit 1 stdout=[] stderr=[--check-answer needs a default branch (origin/HEAD, main or master); found none]`. After the branch is renamed to `main`, it gives `exit 0 [keep Q-1]`.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/dev-cycle.sh:72-81`, `scripts/dev-cycle.sh:188-195`, `test/scripts/dev-cycle.bats:767-778`, `test/scripts/dev-cycle.bats:1153-1158`, `$S/gate/probe.sh`, `$S/gate/probe.out`

---

## Claim 47: "The --check-answer skip list in the help names every skip reason check_answer can print through dev-cycle.sh."

**Submitted by:** api-consistency-reviewer
**Location:** `scripts/dev-cycle.sh:62-71`, `scripts/lib/dev-cycle-read.sh:547-575`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the full enumeration. check_answer has 13 echo lines; 12 are skips. The `odd` line carries 7 oddwhy reasons, from the `refuse("…")` calls: bom, comment, cr, fence (twice), html, nul, refdef. Each of the 18 distinct reachable skips was produced through `dev-cycle.sh --check-answer` and maps to a phrase in the help. The one unmapped skip ("no default branch found by name …", `:550`) is unreachable through dev-cycle.sh, because `:193-194` exits 1 first (Claim 46). It does not establish the wording's precision for each reason (the help paraphrases), nor reasons reachable only when the lib is called directly.

The enumeration, by grepping `echo` in `:547-575` (paraphrased — no quote available because it covers 13 lines; the full list is in my run log and every line's output is quoted in `$S/skips/probe.out`): not a question ID (:549); no default branch (:550); notdir, error and notfile (:556-558); cat-file failure (:562); dup (:564); odd, unbalanced and quoted (:566-568); both files (:570); the answer itself (:573); no such entry (:574).

Mapping to the help at `scripts/dev-cycle.sh:63-71` ("not a question ID, no such entry, a heading twice in one file or in both files, a code fence never closed or not in plain column-0 form, a line starting (after blanks) with < …, a line leaving a <!-- open, … link reference definition …, a stray carriage return, a NUL byte, a byte-order mark on line 1, a question heading inside a fence, a questions file that is not a regular file under plain directories on the default branch, or a default branch whose tree or file could not be read"):

| Probe case | Printed skip (abridged) | Help phrase |
|---|---|---|
| notid | not a question ID | not a question ID |
| noentry | no such entry … on the default branch | no such entry |
| dup / both | more than one entry … / in both … | a heading twice in one file or in both files |
| unbalanced / fence | fence … never closed / fence-like line not plain column-0 | code fence never closed or not in plain column-0 form |
| html / comment / refdef | starts with < / opens an HTML comment / link reference definition | the three matching phrases |
| cr / nul / bom | carriage return / NUL byte / byte-order mark | stray carriage return / NUL byte / byte-order mark on line 1 |
| quoted | question heading inside a code fence | a question heading inside a fence |
| notfile / notdir | not a regular file / docs/working is not a directory | not a regular file under plain directories |
| treeerror / lstreefail / unreadable | tree could not be read / file could not be read | default branch whose tree or file could not be read |

Probe: `./probe.sh`, cwd `$S/skips`, 2026-10-05T16:50:36Z, exit 0. There are 18 cases, each in a fresh repo. "treeerror" uses a tree listing questions.md twice, built with `git mktree`. "lstreefail" deletes the root tree object, and "unreadable" deletes the blob.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/dev-cycle.sh:56-73`, `scripts/dev-cycle.sh:193-194`, `scripts/lib/dev-cycle-read.sh:213-241`, `scripts/lib/dev-cycle-read.sh:534-575`, `$S/skips/probe.sh`, `$S/skips/probe.out`

---

## Claim 48: "check_answer and brief_fields set pipefail themselves and restore the caller's options on return (bash 5.2); test 67 asserts "caller unchanged"."

**Submitted by:** api-consistency-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:292`, `scripts/lib/dev-cycle-read.sh:548`, `test/scripts/dev-cycle.bats:1261-1266`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15. `$-` and the pipefail state are unchanged after both functions under four caller option sets, including after early returns (`check_answer bogus`, `brief_fields ../x`, an absent ID). Test 67 fails under each of four mutants: `local -` dropped from either function, or `set -o pipefail` dropped from either. It does not establish bash 4.4-5.0, where `local -` saves only single-letter options and pipefail is a `-o` option, so its restore there is unverified (stage 1 r2). No minimum bash version is stated in the repo. It does not establish options other than those probed either.

```bash
# test/scripts/dev-cycle.bats:1261-1266
    # The same without the caller's pipefail: each function sets its own.
    run --separate-stderr env LC_ALL=C bash -c 'set -eu; source "$1"; ROOT_REAL="$(pwd -P)"; resolve_main
        check_answer Q-1; brief_fields "$2" || echo "refused [$BRIEF_ODD]"; [[ -o pipefail ]] || echo "caller unchanged"' _ \
        "$REPO_ROOT/scripts/lib/dev-cycle-read.sh" "$b"
    [ "$output" = "skip Q-1: docs/working/questions.md could not be read from the default branch
refused [error]
caller unchanged" ] || { echo "$output $stderr"; return 1; }
```
(excerpt ends :1266; enclosing test continues to :1274 — read)

Runs. (1) `$S/opts/probe.sh` (Claim 40), 2026-10-05T16:48:13Z: `after early returns: […] same=yes` for all four option sets. (2) Mutants of test 67 under cwd `$S/t67`, 2026-10-05T16:50:47Z, each run with `bats -f 'an unreadable blob or a tree naming a file twice'`. nolocal-brief, nolocal-answer, nopipefail-answer and nopipefail-brief each gave exit 1, `not ok 1`. nopipefail-answer printed `keep Q-1`, the fall-through.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/dev-cycle-read.sh:289-312`, `scripts/lib/dev-cycle-read.sh:547-575`, `test/scripts/dev-cycle.bats:1245-1274`, `$S/opts/probe.out`, `$S/t67/mutants.out`

---

## Claim 49: "check_brief (:343) and check_answer (:562) use the same "could not be read from the default branch" wording."

**Submitted by:** api-consistency-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:343`, `scripts/lib/dev-cycle-read.sh:562`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the trailing phrase of the two unreadable-blob skip lines. Their subjects differ by design ("the brief" against the file path). It does not establish that the other skip lines in the two functions match each other. For example, check_brief's `error` line has no ", so … is not read" tail, while check_answer's has one.

`error) echo "skip $a: the brief could not be read from the default branch" ;;` (`scripts/lib/dev-cycle-read.sh:343`) and `|| { echo "skip $a: $f could not be read from the default branch"; return; }` (`scripts/lib/dev-cycle-read.sh:562`). Observed output: `skip Q-1: docs/working/questions.md could not be read from the default branch` (`$S/opts/probe.out`). Test 67 asserts `skip $b: the brief could not be read from the default branch`, and it passed in the full run.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/dev-cycle-read.sh:340-347`, `scripts/lib/dev-cycle-read.sh:560-562`, `test/scripts/dev-cycle.bats:1257-1259`, `$S/opts/probe.out`, `$S/bats/bats-full.out`

---

## Claim 50: "bats test/scripts/dev-cycle.bats passes 68/68 at 4aa2e98e."

**Submitted by:** api-consistency-reviewer
**Location:** `test/scripts/dev-cycle.bats:1`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this sandbox (bash 5.2.15, git 2.39.5, mawk, `LC_ALL=C.UTF-8`, TMPDIR unset) at 4aa2e98e's code files. It does not establish a dotted TMPDIR (test 21 is known to fail there, outside this diff), gawk or other awks, or other git versions.

Run: `bats test/scripts/dev-cycle.bats`, cwd `/workspace/.claude/wt-build-loop-u1a`, 2026-10-05T16:46:44Z, exit 0. 68 lines start `ok` and none `not ok`. The last line is `ok 68 --help prints the whole header, through its last line`.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `test/scripts/dev-cycle.bats:1-1280`, `$S/bats/bats-full.out`, `$S/bats/start`

---

## Claim 51: "check_answer no longer depends on the working tree: no need_root, no ROOT_REAL, nothing added to SKIPPED (lib:547-575; bats:1160)."

**Submitted by:** architecture-review
**Location:** `scripts/lib/dev-cycle-read.sh:547-575`, `test/scripts/dev-cycle.bats:1160-1175`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_answer and every lib function it reaches (main_by_name, main_entry, oddwhy). None references ROOT_REAL, SKIPPED, SKIP_AT, need_root, skipped, rawfile, plaindir, blocker, inrepo, dirok or a `[[ -f/-e/-d` test. Test 63 passes: with ROOT_REAL unset, from `docs/`, a symlinked archive leaves `skipped=0`. Claim 42 shows a broken working tree does not change an answer. It does not establish independence from the current directory for git's own repository discovery: the caller must still be inside the repo, and `--full-tree` makes paths independent of the subdirectory.

The removed working-tree reads are visible in the diff: `-    if skipped "$f"; then …` and `-    [[ -f "$f" ]] || continue` (paraphrased — no quote available because those lines no longer exist in the file at HEAD; they are in the diff hunk `@@ -462,13 +538,28 @@` of `shared/diff.patch`).

Runs: `./enum.sh` (cwd `$S/g1`, about 16:51Z, exit 0) printed `check_answer (547,575): 0 working-tree references`, and the same for main_entry (258,274), main_by_name (246) and oddwhy (231,241). Bats test 63 passed in the full run.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/dev-cycle-read.sh:231-274`, `scripts/lib/dev-cycle-read.sh:547-575`, `test/scripts/dev-cycle.bats:1160-1175`, `$S/g1/enum.sh`, `$S/g1/enum.out`, `$S/bats/bats-full.out`

---

## Claim 52: "A brief has one parser: check_brief takes its status from brief_fields (lib:289-312, 340-351)."

**Submitted by:** architecture-review
**Location:** `scripts/lib/dev-cycle-read.sh:289-312`, `scripts/lib/dev-cycle-read.sh:340-351`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the brief's field values in `scripts/dev-cycle.sh` and the lib. The only reader of a brief's content is brief_fields' awk, check_brief's status is `BRIEF[status]`, and dev-cycle.sh touches `docs/working/briefs` only through `skipdir` (`:463`). It does not establish two things. First, check_brief's commit lookup `git log … -G'^Status: '` (`:357`) is a separate, deliberately fence-blind line match over the brief's history, documented at `:352-356` (iteration 3 Claim 60a, Mostly accurate, made the same point against a broader wording). Second, it does not cover the skill's prose instructions for reading briefs.

```bash
# scripts/lib/dev-cycle-read.sh:340-351
  if ! brief_fields "$a"; then
    case "$BRIEF_ODD" in
      odd\ *) read -r _ n why <<<"$BRIEF_ODD"; echo "skip $a: line $n $(oddwhy "$why"), so the brief is not read" ;;
      error) echo "skip $a: the brief could not be read from the default branch" ;;
      *) echo "skip $a: the code fence opened at line ${BRIEF_ODD#unbalanced } is never closed, so the brief is not read" ;;
    esac
    return
  fi
  st="${BRIEF[status]-}"
  if [[ ! "$st" =~ ^Status:\ (open|done|dropped)$ ]]; then
    echo "skip $a: its first Status: line is not exactly Status: open, done or dropped"; return
  fi
```
(excerpt ends :351; enclosing check_brief() continues to :360 — read: the git log lookup and the `ok` line)

A grep of `scripts/dev-cycle.sh` and the lib for `Status:|Branch:|Asked:|Policy:|Paths:|Dispatched:|briefs/` in non-comment lines finds only `isbrief`/`writable` path regexes, check_brief's `:349-359`, brief_fields, and ANSWER_AWK's unrelated `**Status:**` (paraphrased — no quote available because this summarises a grep's output, recorded in my session, not a source span). Tests 65 and 66 (check_brief and brief_fields agree, T31) passed.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/dev-cycle-read.sh:289-360`, `scripts/dev-cycle.sh:463`, `test/scripts/dev-cycle.bats:1195-1243`, override-log row 226

---

## Claim 53: "main_entry is the one function for "regular file under plain directories on main" and answers error on no default branch, an ls-tree failure, or a name listed twice (lib:258-274)."

**Submitted by:** architecture-review
**Location:** `scripts/lib/dev-cycle-read.sh:258-274`
**Type:** Architectural / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `scripts/dev-cycle.sh` and the lib. The enumeration of `ls-tree|cat-file|git show|rev-parse …:` shows one ls-tree (in main_entry) and two `cat-file blob "$MAIN_SHA:…"` reads (brief_fields :297, check_answer :561), each gated on main_entry answering `blob`. The other `cat-file` (`dev-cycle.sh:296`) is a pre-existing `-e "HEAD:$f"` existence check for a decision record's date, which reads HEAD, not main. All six error triggers probed answer `error`: before resolve_main, the current-branch fallback (MAIN_BY_NAME empty), a branch named only `trunk`, a bad MAIN_SHA, a deleted root tree object, and a name listed twice (symlink+regular, and regular+regular). It does not cover the error list as exhaustive. A slash-named tree entry with no real path reads `absent`, not `error` (override row 236). It does not cover scripts outside these two files either.

```bash
# scripts/lib/dev-cycle-read.sh:261-269
  main_by_name || { echo error; return; }
  while [[ "$rest" == */* ]]; do p="${p:+$p/}${rest%%/*}"; rest="${rest#*/}"; want+=("$p"); done
  out="$(git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1" 2>/dev/null)" || { echo error; return; }
  while IFS=$'\t' read -r mode path; do
    [[ -n "$path" ]] || continue
    [[ -z "${m[$path]+set}" ]] || dup=1
    m["$path"]="${mode%% *}"
  done <<<"$out"
  [[ -z "$dup" ]] || { echo error; return; }
```
(excerpt ends :269; enclosing main_entry() continues to :274 — read)

Probe: `./probe.sh`, cwd `$S/g3`, 2026-10-05T16:51:53Z, exit 0. It printed `before resolve_main: error`, `control: blob / absent path: absent / tree: notfile`, `current-branch fallback (MAIN_BY_NAME empty): error`, `bad sha: error`, `only branch trunk (…by name=[]): error`, `root tree object deleted: error`, and both `questions.md listed twice …: error`.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/dev-cycle-read.sh:247-274`, `scripts/lib/dev-cycle-read.sh:294-297`, `scripts/lib/dev-cycle-read.sh:552-561`, `scripts/dev-cycle.sh:296`, `$S/g3/probe.sh`, `$S/g3/probe.out`

---

## Claim 54: "Dependencies point one way: dev-cycle.sh -> lib -> git and awk; build-loop.sh appears only in comments."

**Submitted by:** architecture-review
**Location:** `scripts/dev-cycle.sh:91-95`, `scripts/lib/dev-cycle-read.sh:1-575`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** The direction holds. No dev-cycle.sh function (need, skipdir, skipnote, exact, matches, check_path, check_write, check_fix, trig) is used in the lib, and the lib names no script except in comments. The `build-loop.sh` mentions in the four code files are the comments `scripts/lib/dev-cycle-read.sh:3`, `:11` and `scripts/dev-cycle.sh:87`. The lib's outgoing edge list is incomplete for the lib as a whole: besides git and awk it runs perl (`scrub`), grep, tr, realpath and pwd. The functions this diff adds (main_entry, brief_fields, check_answer) use only git, awk and env. Two things are not established: the runtime callback `scrub_reexec` (`bash "$self"`, which re-runs a caller-supplied script path), and the scripts outside these files.

The precise version: "dev-cycle.sh → lib → git, awk, perl, grep, tr, realpath (the new functions: git and awk only)". The lib's re-exec of its caller is `{ DEV_CYCLE_SCRUBBED=1 bash "$self" "$@" 2>&1 1>&3 3>&- | scrub >&2; } 3>&1 | scrub` (`scripts/lib/dev-cycle-read.sh:79`). The extra commands appear as `env -u PERL_UNICODE -u PERL5OPT -u PERLIO LC_ALL=C perl -C0 -ne '` (`:50`), `r="$(realpath -e -- "$1" 2>/dev/null)"` (`:93`), `lower() { printf '%s' "$1" | tr …` (`:430`) and `| env LC_ALL=C grep -zaiE …` (`:446`). The command count from a grep of non-comment lines was awk 2, git 14, grep 2, perl 1, pwd 1, realpath 3, tr 2 (paraphrased — no quote available because this is a tally over the whole file, recorded in my session).

**Legibility-target:** for-author

**Evidence:** `scripts/lib/dev-cycle-read.sh:3`, `scripts/lib/dev-cycle-read.sh:11`, `scripts/lib/dev-cycle-read.sh:48-80`, `scripts/lib/dev-cycle-read.sh:93-96`, `scripts/lib/dev-cycle-read.sh:430-458`, `scripts/dev-cycle.sh:87-95`

---

## Claim 55: "--help is taken from the header and a test pins its last line (dev-cycle.sh:111-112; bats:1276-1280)."

**Submitted by:** architecture-review
**Location:** `scripts/dev-cycle.sh:111-112`, `test/scripts/dev-cycle.bats:1276-1280`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** The same evidence as Claim 45. The output is byte-identical to header lines 2-81, and test 68 fails against the `2,80p` and `2,77p` mutants. It does not establish the range's behaviour for a future header with an empty or indented-`#` line, nor BSD sed.

`-h|--help) sed -n '2,/^[^#]/{/^#/p}' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;` (`scripts/dev-cycle.sh:112`), and the test's `[[ "${lines[${#lines[@]}-1]}" == *"Printed repo text is data." ]]` (`test/scripts/dev-cycle.bats:1279`). Runs: see Claim 45 (cwd `$S/help`, 2026-10-05T16:49:59Z).

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/dev-cycle.sh:111-112`, `test/scripts/dev-cycle.bats:1276-1280`, `$S/help/help.out`, `$S/help/mutants.out`

---

## Claim 56: "The test of the lib's sourced names lists main_entry, brief_fields, BRIEF and BRIEF_ODD (bats:1032, 1036)."

**Submitted by:** architecture-review
**Location:** `test/scripts/dev-cycle.bats:1032`, `test/scripts/dev-cycle.bats:1036`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two lines and the test's power to fail. Test 54, "sourcing the reader lib defines its functions and calls neither git nor perl", fails with `missing main_entry`, `missing brief_fields` and `unset BRIEF_ODD` against the three corresponding mutants. It does not establish detection of an undeclared `BRIEF` alone (not mutated), nor that the test checks `BRIEF`'s associative type (`declare -p` passes for any declared variable).

```bash
# test/scripts/dev-cycle.bats:1032
                 oddwhy check_brief check_branch resolve_main main_by_name main_entry brief_fields lower imported_names check_answer; do
# test/scripts/dev-cycle.bats:1036
        for v in SKIPPED SKIP_AT MAIN MAIN_SHA MAIN_BY_NAME IMPORTED IMPORTED_DONE BRIEF BRIEF_ODD; do declare -p "$v" >/dev/null 2>&1 || echo "unset $v"; done
```
(excerpt ends :1036; enclosing test continues to :1040 — read)

Mutants: a copy of `scripts/` and the test under `$S/g6/mut`, cwd `$S/g6`, 2026-10-05T16:52:24Z, each run with `bats -f 'sourcing the reader lib defines its functions and calls neither git nor perl'`. Renaming `main_entry()` gave exit 1 with `# missing main_entry`. Renaming `brief_fields()` gave exit 1 with `# missing brief_fields`. Dropping `BRIEF_ODD=""` from `:288` gave exit 1 with `# unset BRIEF_ODD`.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `test/scripts/dev-cycle.bats:1024-1040`, `scripts/lib/dev-cycle-read.sh:288`, `$S/g6/mutants.out`, `$S/g6/main_entry.out`, `$S/g6/brief_fields.out`, `$S/g6/BRIEF_ODD.out`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 54** (`scripts/lib/dev-cycle-read.sh:48-80, 430-458`): the direction is right, but the lib also runs perl, grep, tr and realpath, not only git and awk. Say "dev-cycle.sh → lib → git, awk, perl, grep, tr, realpath; the new functions use git and awk only".

### Unverifiable
(none)

## Legibility notes

- The residues named in the Scope fields are already known. `local -` before bash 5.1 (Claims 40, 41, 48) and BSD sed (Claims 45, 55) were escalated by stage 1. The stale bats:767 title (Claim 46) was flagged by stage-1 r2. The slash-named tree entry (Claim 53) is override row 236. The unscrubbed `fatal:` line (Claim 40) is override row 238.
- All claims were checked under mawk and GNU sed only.

## Goal-Alignment Note
- Success criterion (restated verbatim): A report saved to docs/reviews/code-fact-check-submitted-claims-build-loop-u1a.md, first line `Commit: 4aa2e98e`, with a `## Submitted Claims` section, claims numbered from 40.
- Answered: yes. All 17 submitted claims (S1-S3, P1-P2, A1-A6, G1-G6 → 40-56) have verdicts: 16 Verified and 1 Mostly accurate (Claim 54). 15 rest on executed probes, mutants or the bats run. The universally quantified claims (47, 51, 53, 54) show their enumerations.
- Out of scope: there was no fresh harvesting from the diff, and `docs/reviews/hallucination-patterns.md` was not updated (no Incorrect verdict). bash below 5.2, BSD sed, gawk and other git versions were not run.
- Escalate: nothing merge-blocking. Claim 54's dependency list could be tightened in the architecture critique. The bats:767 test title (Claim 46 Scope) is stale and still unaddressed.
- Decisions I made: I verdicted G2 (Claim 52) Verified rather than Mostly accurate, because it claims only that the status comes from brief_fields. The git log -G history match is named in its Scope as the residue that made iteration 3's broader Claim 60a Mostly accurate. I judged G4 (Claim 54) on the lib as a whole, the natural reading of "lib -> git and awk", which made it Mostly accurate.
