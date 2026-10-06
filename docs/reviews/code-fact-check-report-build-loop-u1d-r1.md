Commit: 83cdb005

# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u1d, branch feat/build-loop-u1d)
**Scope:** `git diff main...HEAD` (one commit, 83cdb005): scripts/build-loop.sh, scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-read.bats, test/scripts/dev-cycle.bats, and the commit message. Replicate r1 of k=3.
**Checked:** 2026-10-06
**Total claims checked:** 19
**Summary:** 13 verified, 6 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Execution provenance (applies to every `executed` claim below). Working directory for suites and mutants: a scratch copy of the worktree's `scripts/`, `test/` and `docs/dev-cycle.md` at `/tmp/claude-1000/-workspace/57e599b8-f769-48da-96c7-3a02f99f2a8d/scratchpad/review-u1d/fc1/base` (mutants in sibling `m-<id>/` copies). Probe repos live under the same `fc1/` directory and run the worktree's own unmodified scripts. Logs: `fc1/logs/`. Baseline at 83cdb005: `bats test/scripts/build-loop-read.bats` 19/19 pass (exit 0) and `bats test/scripts/dev-cycle.bats` 73/73 pass (exit 0) (`fc1/logs/mutant-a-blr.txt` is a surviving mutant whose run equals the baseline; `fc1/logs/baseline-dc.txt`). The very first baseline run of build-loop-read.bats (04:30:41Z) failed only T3/G19, because the copy lacked `docs/dev-cycle.md`; that file was then copied in. Mutant runs: 04:33:02Z (a-d), 04:35:04Z (f-w), about 04:36Z (p, p2), 04:37:50Z (dev-cycle.bats: m, l, n). Mutant diffs: `fc1/logs/mutant-diffs-build-loop.txt` and `fc1/logs/mutant-diffs-lib-dc.txt`. Per-mutant results: `fc1/logs/mutant-summary.txt`.

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, 5 entries). No claim here resembles a logged pattern, and none asserts a fabricated symbol.

---

## Claim 1: "Self-merge also needs a valid never line, so a never list hidden in markup, with no exact never line beside it, turns it off."

**Location:** `scripts/build-loop.sh:16-18`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what read_settings does for a hidden never copy with and without an exact never line beside it (bold, task-box and fenced copies). Does not establish that adding an exact line beside a hidden copy keeps self-merge on, which the qualifier implies: that holds only when the letters check misses the copy.

The literal statement holds. A hidden list on its own always leaves POLICY at review. A copy the letters check detects (bold) is counted and is not exact. A copy it misses (a task box) leaves no never line at all:

```awk
# scripts/build-loop.sh:155-156
  else if (index(s, "selfmergenever") == 1) k = "never"
  if (k != "") { c[k]++; if (c[k] == 1) { l1[k] = NR; t[k] = $0; nx[k] = 1; pk = k } else if (c[k] == 2) l2[k] = NR }
```
```bash
# scripts/build-loop.sh:223-224, 250-251 (excerpt ends :251; enclosing read_settings() continues to :273 — read)
    if [[ -z "${cnt[never]-}" ]]; then NEVER_LINE='never none: no line starts "Self-merge never:"'
    elif [[ "${cnt[never]}" -gt 1 ]]; then NEVER_LINE="never malformed: $(many 'Self-merge never:' never)"
...
      if [[ "$v" == self-merge && -z "$never_ok" ]]; then
        POLICY_LINE="policy review unset: line ${first[policy]} reads self-merge, ...
```

The qualifier "with no exact never line beside it" suggests that an exact line beside the hidden copy keeps self-merge on. The probes split on whether the letters check detects the copy (`fc1/logs/p12-settings-probes.txt`):
- h1, `**Self-merge never:** a/` alone: `never malformed ... not exactly`, so policy is review.
- h2, the same bold copy plus an exact `Self-merge never: a/`: `never malformed: more than one line starts "Self-merge never:" (lines 3 and 5)`, so policy is review. The exact line does not rescue it.
- h3, `- [x] Self-merge never: a/` plus an exact line: `policy self-merge set`, `never a/ set: line 5`. The task-box copy is skipped.
- h5, a bold copy inside a fence plus an exact line: `policy self-merge set`.

So the sentence holds as written. Its implied contrast holds only for copies the letters check misses. The header's own "a second copy ... gives review, 3 and malformed" (`scripts/build-loop.sh:12-13`) covers h2. A precise version: "a never list hidden in markup turns it off, unless markup that adds letters (or a fence) hides it from the copy check and an exact never line stands beside it."

Command: `fc1/p12/run.sh <label> <lines...>` (fresh repo per case, then `bash /workspace/.claude/wt-build-loop-u1d/scripts/build-loop.sh --settings`). Cwd: `fc1/p12`. Exit 0 for each case. Run at about 04:31Z.

**Evidence:** `scripts/build-loop.sh:12-13`, `scripts/build-loop.sh:147-162`, `scripts/build-loop.sh:205-253`, `fc1/logs/p12-settings-probes.txt`

---

## Claim 2: help skip list: "...names the same branch (ignoring case) or the open briefs on main could not be listed, or on a branch ahead of main the tip's subject (its message's first line) starts "handoff:" but it is not a marker."

**Location:** `scripts/build-loop.sh:68-72`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "could not be listed" skip (open briefs only) and the marker skip's limit to branches with ahead > 0, including tips that are level with main or behind it. Does not establish the wording of the unchanged context line 61 ("a branch level with main"), which also covers branches behind main.

The listing failure skips only open briefs, which is where the help places it ("for an open brief, ..."):

```bash
# scripts/build-loop.sh:338
  if [[ "$st" == open && "$SHARED_BRANCHES" == error ]]; then echo "skip $a: the open briefs on the default branch could not be listed"; return; fi
```

marker_kind runs only when the branch is ahead, and only a `bad` kind skips:

```bash
# scripts/build-loop.sh:348-357 (excerpt ends :357; enclosing status_line() continues to :358 — read)
  loop=working
  if [[ "$ahead" -gt 0 ]]; then
    kind="$(marker_kind "$sha")"
    case "$kind" in
      bad\ *) echo "skip $a: the tip of $br starts \"handoff:\" but is not a marker: ${kind#bad }"; return ;;
```

marker_kind returns `working` unless the subject starts `handoff:` (`scripts/build-loop.sh:283`: `[[ "$subj" == handoff:* ]] || { echo working; return; }`). Probe (`fc1/logs/p3-marker-ahead.txt`): feat/x and feat/y sit on a main ancestor whose subject is `handoff: junk` (0 ahead, behind main), and both print `ok ... working`. feat/z is one commit ahead with tip `handoff: junk2`, and it prints `skip ...: the tip of feat/z starts "handoff:" but is not a marker: ...`. Command: `bash .../scripts/build-loop.sh --status docs/working/briefs/2026-10-01-{x,y,z}.md`. Cwd: `fc1/p3/r`. Exit 0. Run at about 04:39Z.

**Evidence:** `scripts/build-loop.sh:278-298`, `scripts/build-loop.sh:321-358`, `fc1/logs/p3-marker-ahead.txt`

---

## Claim 3: "# the header, to the first non-empty line not starting with #"

**Location:** `scripts/build-loop.sh:99`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers GNU sed's `2,/^[^#]/{/^#/p}` on this file and on synthetic headers with empty and space-only lines. Does not establish BSD sed behaviour (out of scope per row 286).

`/^[^#]/` needs one character that is not `#`, so an empty line cannot end the range. A space-only line can, and it counts as non-empty. Inside the range only `#` lines print. Results (`fc1/logs/p4-sed-range.txt`):
- build-loop.sh: the first empty line after line 1 is 80, and the first non-empty non-`#` line is 81 (`set -euo pipefail`). The last printed line is `# lib/dev-cycle-read.sh, or no default branch found by name.` (line 79).
- Synthetic `#!x / # a / (empty) / # b / " " / # c / z`: prints `# a`, `# b`. The empty line did not end the range; the space-only line did.

Command: `sed -n '2,/^[^#]/{/^#/p}' <file>`. Cwd: `fc1/p4`. Exit 0. Run at about 04:39Z.

**Evidence:** `scripts/build-loop.sh:79-81`, `scripts/build-loop.sh:99`, `fc1/logs/p4-sed-range.txt`

---

## Claim 4: "whether the next line outside a fence after the first is blank or the end of the file (NEXT 1) or not"

**Location:** `scripts/build-loop.sh:143-145`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers fence lines and fenced content being skipped, EOF giving 1, and space/tab-only lines counting as blank. Does not establish that other whitespace counts as blank: a line holding only a vertical tab (or form feed) is non-blank, and so is a one-line `<!-- comment -->`.

```awk
# scripts/build-loop.sh:148-151 (excerpt ends :151; enclosing SETTINGS_AWK continues to :162 — read)
{ sub(/\r$/, "") }
fence($0) { next }
{
  if (pk != "") { nx[pk] = ($0 ~ /^[ \t]*$/); pk = "" }
```

`nx[k] = 1` is set when the first copy is seen (`:156`) and is overwritten only by the next line that gets past `fence($0) { next }`. So the end of the file leaves 1, and fence delimiters and fenced lines are never "the next line". Probes (`fc1/logs/p12-settings-probes.txt`):
- n1, the never line last in the file: `never a/ set`.
- n3, followed by an empty fence pair and nothing else: `set`.
- n2, followed by an empty fence pair and then `x`: `malformed: ... followed by a non-blank line`.
- n4, followed by a tab and a space: `set`.
- n5, followed by `\v`: `malformed`.
- n6, followed by `<!-- c -->`: `malformed`.

A fence still open at EOF refuses the whole file (`:160`), so it never reaches NEXT.

**Evidence:** `scripts/build-loop.sh:147-162`, `scripts/lib/dev-cycle-read.sh:214-230`, `fc1/logs/p12-settings-probes.txt`

---

## Claim 5: "Exit 1 is "none"; an exit above 1 fails closed (SHARED_BRANCHES=error: every open brief skips). A brief git grep cannot read is not counted (row 293)."

**Location:** `scripts/build-loop.sh:307-309`
**Type:** Error-handling / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git grep 2.39.5's exit status for a missing blob (0, or 1 when nothing else matches) and for a config error (128), and status_line's handling of each. Does not establish other fatal git grep paths, or exit codes on other git versions.

```bash
# scripts/build-loop.sh:310-311 (excerpt ends :311; enclosing shared_branches() continues to :320 — read)
  list="$(git grep --no-color -l -E '^Status: open'$'\r''?$' "$MAIN_SHA" -- docs/working/briefs/)" || rc=$?
  if [[ "$rc" -gt 1 ]]; then SHARED_BRANCHES=error; return; fi
```

Probe (`fc1/logs/p5-gitgrep-exit.txt`):
- A blob deleted from the object store: git grep prints `error: '...b.md': unable to read ...`, still lists the other file, and exits 0. With no other match it exits 1.
- `-c grep.patternType=bogus`: `fatal: bad grep.patterntype argument`, exit 128.

So a brief git grep cannot read is left out of the list, and only a fatal error fails closed.

Row 293 (`docs/reviews/override-log.md:293`) reads: "An unreadable open brief is not counted for F31 ... Won't-Fix | The unreadable brief skips in its own --status line". Its premise also holds for the git grep case. Probe `fc1/logs/p5b-missing-blob-status.txt`: two open briefs name feat/a and b's blob is missing. Brief a prints `ok ... open review feat/a absent - - 0` (b is not counted), and b prints `skip ...: the brief could not be read from the default branch`. Commands: as logged. Cwd: `fc1/p5/r` and `fc1/p5b/r`. Exit 0. Run at about 04:32Z and again at about 04:39Z.

**Evidence:** `scripts/build-loop.sh:303-320`, `docs/reviews/override-log.md:293`, `fc1/logs/p5-gitgrep-exit.txt`, `fc1/logs/p5b-missing-blob-status.txt`

---

## Claim 6: "(an answer only in the working tree is not seen: it reads what main's copy says until it lands there)"

**Location:** `scripts/dev-cycle.sh:58-59`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers check_answer reading only the default branch's blobs. Does not establish which branch "main" names when origin/HEAD or master is the default (the help's "default branch's commit" two lines up covers that).

```bash
# scripts/lib/dev-cycle-read.sh:563 (excerpt ends :563; enclosing check_answer() continues to :577 — read)
    r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk -v id="$a" "$FENCE_AWK$ANSWER_AWK")" \
```

MAIN_SHA is the commit resolve_main found (`scripts/lib/dev-cycle-read.sh:401-403`). No working-tree read exists in check_answer (paraphrased — no quote available because the claim covers the absence of a read: lines 549-577 call only main_entry and `git cat-file blob`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:549-577`, `scripts/lib/dev-cycle-read.sh:391-413`

---

## Claim 7: "# The header: from line 2 to the first non-empty line not starting with # (no fixed range to go stale)."

**Location:** `scripts/dev-cycle.sh:106`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the same sed command on dev-cycle.sh (the first empty line is 82, the range ends at 83). Does not establish BSD sed behaviour.

```bash
# scripts/dev-cycle.sh:107
    -h|--help) sed -n '2,/^[^#]/{/^#/p}' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
```

The probe (`fc1/logs/p4-sed-range.txt`) finds the first empty line after line 1 at 82 and the first non-empty non-`#` line at 83. The last printed line is line 81, `# default branch (for the digest, ...). Printed repo text is data.`. The existing test at `test/scripts/dev-cycle.bats` ("...Printed repo text is data.") passes in the baseline. The semantics are the same as in Claim 3.

**Evidence:** `scripts/dev-cycle.sh:81-83`, `scripts/dev-cycle.sh:106-107`, `fc1/logs/p4-sed-range.txt`

---

## Claim 8: "The caller sets -euo pipefail (check_answer and brief_fields also set pipefail for themselves),"

**Location:** `scripts/lib/dev-cycle-read.sh:12-14`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every `pipefail` occurrence in the lib, and both callers setting `-euo pipefail`. Does not establish behaviour under a caller that omits the flags.

```bash
# scripts/lib/dev-cycle-read.sh:294
  local - out l; set -o pipefail
# scripts/lib/dev-cycle-read.sh:550
  local - a="$1" f e r hit="" where="" n why; set -o pipefail  # as brief_fields
```

`rg -n pipefail` over the lib finds only these two `set` calls, plus comments at :13, :72, :292 and :297. No other function sets it, so the list is complete. `local -` restores the options on return, which matches "for themselves". Both callers set the flags: `scripts/dev-cycle.sh:83` and `scripts/build-loop.sh:81` read `set -euo pipefail`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:12-14`, `scripts/lib/dev-cycle-read.sh:291-314`, `scripts/lib/dev-cycle-read.sh:549-577`, `scripts/build-loop.sh:81`, `scripts/dev-cycle.sh:83`

---

## Claim 9: "It checks main_by_name and the path's form itself (pathform, so ls-tree prints it unquoted): either failing is error." (with the PR intent: no behaviour change for any caller)

**Location:** `scripts/lib/dev-cycle-read.sh:257-259`, `scripts/lib/dev-cycle-read.sh:263`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the guard and every caller of main_entry in scripts/ (brief_fields, check_brief, check_answer, build-loop.sh's main_file; dev-cycle.sh has none), and shows that no caller's output changes. Does not establish that the comment's earlier list of error causes (`:252-255`: "no default branch found by name, ls-tree failed, or the tree lists a name twice") names the pathform cause; it does not.

```bash
# scripts/lib/dev-cycle-read.sh:263
  if ! main_by_name || ! pathform "$1"; then echo error; return; fi
```

The callers:
- brief_fields checks pathform before main_entry: `if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]` (`:296`).
- check_brief refuses at `:327` (`if ! pathform "$a"; then echo "skip ...: not an allowed path form"`) before main_entry at `:334`.
- check_answer passes only `docs/working/questions.md` and `docs/working/questions-archive.md` (`:553`).
- main_file is called only with `docs/dev-cycle.md` and `docs/constraints.md` (`scripts/build-loop.sh:206,259`).

`pathform` accepts all four fixed names (executed: `ok` for each, cwd the worktree, exit 0, about 04:40Z). `rg "main_entry"` outside docs/ finds no other caller. So the guard's new `error` cannot fire for any current caller, and no caller maps it differently.

Mutant m (the guard reverted to `main_by_name || {...}`) makes `dev-cycle.bats` test 73 print `absent / error / absent / absent` instead of four `error`s (`fc1/logs/mutant-m-dc.txt`, exit 1). So the guard is what produces `error` for three of the four paths.

**Evidence:** `scripts/lib/dev-cycle-read.sh:248-276`, `:296`, `:323-341`, `:553-554`, `scripts/build-loop.sh:121-138`, `fc1/logs/mutant-m-dc.txt`

---

## Claim 10: test "--settings: deferred cases: reasons, review with a malformed never line, the next-line rule, an absent file, a caller's config (U1d)" and its comments ("Under review a malformed never line leaves the policy as written", "The next line outside a fence decides; a whitespace-only line is blank", "A caller's own GIT_CONFIG_COUNT pairs stay, and the guard still applies after them")

**Location:** `test/scripts/build-loop-read.bats:402-426`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which mutants this test kills. Does not establish that "the caller's own pairs stay": the test never reads them back.

Mutants and results (`fc1/logs/mutant-summary.txt`; build-loop-read.bats; cwd `fc1/m-<id>`; 04:35:04Z):
- v (a malformed never line turns review off too): test 17 fails (exit 1).
- t (blank is `/^$/`): test 17 fails.
- u (the next-line update moved ahead of `fence($0) { next }`): test 17 fails.
- j (`GIT_CONFIG_COUNT=1` instead of `cfg + 1`, so the guard pair is dropped when a caller passes a count): only test 17 fails.
- f (the guard line deleted): tests 5 and 17 fail.
- i (`cfg=0`, so the guard overwrites the caller's KEY_0/VALUE_0): **survives** (exit 0).

The test only checks `policy review set` after the caller's pair:

```bash
# test/scripts/build-loop-read.bats:424-425
    run --separate-stderr env GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=user.name GIT_CONFIG_VALUE_0=caller bash "$BL" --settings
    [[ "$(line policy)" == "policy review set:"* ]] || { echo "$output $stderr"; return 1; }
```

So "pairs stay" is true of the code (`scripts/build-loop.sh:112` writes at index `$cfg` only), but this test does not assert it. "An absent file" checks the slots line for an absent file only; see Claim 17 for the unread case.

**Evidence:** `test/scripts/build-loop-read.bats:402-426`, `scripts/build-loop.sh:108-113`, `fc1/logs/mutant-diffs-build-loop.txt`, `fc1/logs/mutant-summary.txt`, `fc1/logs/mutant-i-blr.txt`, `fc1/logs/mutant-j-blr.txt`

---

## Claim 11: test "build-loop.sh --help prints the whole header, through its last line (U1d)"

**Location:** `test/scripts/build-loop-read.bats:428-432`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the assertions: exit 0, the first line, and the last line. Does not establish "the whole header": no middle line is checked, and a range that stops at the first empty line gives identical output, because this header holds no empty line.

```bash
# test/scripts/build-loop-read.bats:430-431
    [ "$status" -eq 0 ] && [[ "${lines[0]}" == "The build-loop handoff's state and checks"* ]] \
        && [[ "${lines[${#lines[@]}-1]}" == *"or no default branch found by name." ]] || { echo "$output"; return 1; }
```

The test fails on a range that stops early or late, which is the A27 regression. It would pass for output that drops middle lines (paraphrased — no quote available because this is a statement about which lines the assertion does not reference). A precise title: "...prints the header from its first line through its last".

**Evidence:** `test/scripts/build-loop-read.bats:428-432`, `scripts/build-loop.sh:2-79`

---

## Claim 12: test "--status: deferred cases: NUL, F31's open-only filter, no open brief, CRLF, BRIEF kept, an unanchored closed (U1d)" and its step comments

**Location:** `test/scripts/build-loop-read.bats:434-462`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which steps kill which mutants. Does not establish the CRLF step comment's second half at that step, either single layer of the open-only filter, or the exit-1 branch as distinct from the error branch.

Kills (`fc1/logs/mutant-summary.txt`):
- b (BRIEF dropped from the local and the call moved after `brief_fields "$a"`): fails at `:457` with `ok ... feat/q absent - - 3`.
- d (`${f/closed\//}` restored): fails at `:453` with `skip ...: another open brief`.
- q (git grep without `\r?`): fails at `:443`, the CRLF step.
- p2 (both open filters removed): fails at `:443`.

Gaps:
1. The CRLF step's comment says "the queried brief keeps its own Dispatched value whatever F31 read". At that step the queried brief is skipped, and the assertion is only `[[ "$output" == "skip $o: another open brief"* ]]` (`:448`). Brief p's `Dispatched: 3` is overwritten by `printf 'Status: open\r\nBranch: feat/x\r\n' > "$B"` (`:446`), so no Dispatched value is in play there. The property is asserted later, at the "read by F31 after o" step (`:455-457`).
2. "F31's open-only filter" is two layers: git grep's `'^Status: open'` and `[[ "${BRIEF[status]-}" == "Status: open" && ...` (`scripts/build-loop.sh:315`). The step kills only the mutant that removes both (p2). Mutant o (line 315's status test removed) and mutant p (git grep's pattern widened to `'^Status: '`) each survive the suite. A brief whose first Status line is `done` and a later one `open` would reach line 315 untested.
3. "No open brief on main at all (git grep exits 1)" (`:436`). Mutant r (`rc -gt 0`, so exit 1 becomes error) survives. That is output-equivalent: exit 1 means no queried brief is open on main, and the error skip applies only to open briefs (`scripts/build-loop.sh:338`). So the step exercises the path, but no --status output can distinguish the regression.

Mutant w (the `#` anchor removed but the full `docs/working/briefs/closed/` prefix kept) also survives. It differs from the code only for a path holding that prefix below its start.

**Evidence:** `test/scripts/build-loop-read.bats:434-462`, `scripts/build-loop.sh:303-320`, `scripts/build-loop.sh:338`, `fc1/logs/mutant-b-blr.txt`, `fc1/logs/mutant-d-blr.txt`, `fc1/logs/mutant-o-blr.txt`, `fc1/logs/mutant-p-blr.txt`, `fc1/logs/mutant-p2-blr.txt`, `fc1/logs/mutant-q-blr.txt`, `fc1/logs/mutant-r-blr.txt`, `fc1/logs/mutant-w-blr.txt`

---

## Claim 13: test "--check-brief, --check-branch and --check-answer need a default branch found by name; the others do not" (loop extended to `--check-answer feat/x`)

**Location:** `test/scripts/dev-cycle.bats:813-822`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `--check-answer` iteration failing for the script-level default-branch guard. Does not establish anything about check_answer's own `main_by_name` skip, which this argument never reaches: with the guard gone, the ID check at `:551` answers first.

```bash
# scripts/dev-cycle.sh:193-194
if [[ "$CHECK" == --check-brief || "$CHECK" == --check-branch || "$CHECK" == --check-answer ]] && ! main_by_name; then
  echo "$CHECK needs a default branch (origin/HEAD, main or master); found none" >&2; exit 1
```

Mutant n (`--check-answer` dropped from that guard) makes test 45 fail at `[ "$status" -eq 1 ]` (`:818`). Test 66 also fails (`fc1/logs/mutant-n-dc.txt`, exit 1, 04:37:50Z). So the iteration fails for the default-branch reason. Without the guard, `feat/x` gets check_answer's `skip feat/x: not a question ID` with exit 0, which fails the status assertion. The pre-existing test 66 already covered the same guard.

**Evidence:** `test/scripts/dev-cycle.bats:813-822`, `scripts/dev-cycle.sh:188-207`, `scripts/lib/dev-cycle-read.sh:549-552`, `fc1/logs/mutant-n-dc.txt`

---

## Claim 14: test "main_entry refuses a path pathform refuses, before any read (U1d)"

**Location:** `test/scripts/dev-cycle.bats:1328-1335`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four paths answering `error`. Does not establish "before any read": a mutant that runs ls-tree first and checks pathform afterwards passes.

The code does refuse before any read (`scripts/lib/dev-cycle-read.sh:263` precedes the ls-tree at `:265`). But the test asserts only the four `error` lines. Mutant l moves the pathform check to after the ls-tree and the dup check (`pathform "$1" || { echo error; return; }` inserted after `:271`). It **survives** dev-cycle.bats (exit 0, `fc1/logs/mutant-l-dc.txt`). Mutant m (no pathform check at all) fails this test (Claim 9). A precise title: "main_entry answers error for a path pathform refuses".

**Evidence:** `test/scripts/dev-cycle.bats:1328-1335`, `scripts/lib/dev-cycle-read.sh:260-276`, `fc1/logs/mutant-diffs-lib-dc.txt`, `fc1/logs/mutant-l-dc.txt`

---

## Claim 15: commit message, Code: "main_entry checks the path's form itself (pathform) as well as main_by_name; either failing is error (U1a C16)." / "--status' "could not be listed" skip drops "(git grep failed)", matching the other reasons (U1c C38)."

**Location:** commit 83cdb005 message; `scripts/lib/dev-cycle-read.sh:263`; `scripts/build-loop.sh:338`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both code changes and the updated T28 assertion. Does not establish behaviour beyond Claim 9's caller analysis.

The diff changes `main_by_name || { echo error; return; }` to `if ! main_by_name || ! pathform "$1"; then echo error; return; fi`. It also changes `...could not be listed (git grep failed)"` to `...could not be listed"` (`scripts/build-loop.sh:338`). T28's expected line was updated to match (`test/scripts/build-loop-read.bats:388`: `"skip $d: the open briefs on the default branch could not be listed"`). No other skip reason in status_line names a mechanism in parentheses except "(compared ignoring case)" (`:340`), which names a rule rather than a mechanism.

**Evidence:** `scripts/lib/dev-cycle-read.sh:263`, `scripts/build-loop.sh:321-358`, `test/scripts/build-loop-read.bats:385-390`

---

## Claim 16: commit message, Wording bullets (U1a A19-A22, C19; U1b A25-A27; U1c A24, A25, C37: "the help is re-wrapped"; "the F31 comment says an exit above 1 fails closed")

**Location:** commit 83cdb005 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each bullet against the diff hunk it names. Does not establish that each new wording is accurate; Claims 1-8 verdict that.

Each bullet maps to a hunk:
- A19, test title and loop: `dev-cycle.bats:813,816`.
- A20, "until it lands there": `dev-cycle.sh:59`.
- A21 and A27, the help ranges: `dev-cycle.sh:106`, `build-loop.sh:99`.
- A22, the main_entry comment: `lib:257-259`.
- C19, the pipefail note: `lib:13-14`.
- A25, the never rule: `build-loop.sh:17-18`.
- A26, the NEXT comment: `build-loop.sh:143-145`.
- A24 and C37, the skip list: `build-loop.sh:68-72`.
- U1c A25: `build-loop.sh:308`.

For "re-wrapped", `awk 'NR<=80 && length($0)>80'` over build-loop.sh's header prints nothing (exit 0, cwd the worktree, about 04:40Z). Before the change, line 62 ran to 115 columns per row 26's text. The four added lines over 80 columns are all code or comment lines outside the header block.

**Evidence:** `scripts/build-loop.sh:2-79`, the diff in the shared context

---

## Claim 17: commit message, Tests: "(U1b C10-C12, U1c C17, C18, C26, C28, C39, and U1a C16)" ... "the slots line for an absent file; a caller's own GIT_CONFIG_COUNT pairs with a replace ref; ... --status with no open brief on main; a done brief sharing an open brief's branch; a CRLF open brief counting for F31; ..."

**Location:** commit 83cdb005 message
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that every named case is present and which of them fail on a regression. Does not establish row 246's "unread" half (C26), which the message lists as resolved.

Every named case appears in the new tests. Most fail on a regression (Claims 10, 12-14). The residues:
- (a) Row 246 (C26's parent) asks for "the slots line for an absent or unread file". Only the absent case is asserted (`test/scripts/build-loop-read.bats:419`: `settings_is slots "slots 3 default: no docs/dev-cycle.md on the default branch"`). Mutant k changes the slots line only for a file that was not read (`[[ "$FILE_WHY" == absent ]] && SLOTS_LINE=... || SLOTS_LINE="slots 9 set: x"`), and it survives the whole suite (`fc1/logs/mutant-k-blr.txt`, exit 0). The bullet's own words ("for an absent file") are accurate, but listing C26 as resolved overstates.
- (b) The caller-pair case does not assert that the caller's pairs survive (mutant i survives; Claim 10).
- (c) "no open brief on main" cannot fail on a regression of the exit-1 branch, because the regression is output-equivalent (Claim 12, gap 3).
- (d) "a done brief sharing an open brief's branch" kills only the removal of both filter layers (Claim 12, gap 2).

**Evidence:** `test/scripts/build-loop-read.bats:402-462`, `test/scripts/dev-cycle.bats:1328-1335`, `docs/reviews/override-log.md:246`, `fc1/logs/mutant-summary.txt`, `fc1/logs/mutant-k-blr.txt`

---

## Claim 18: commit message: "Mutants that drop the local BRIEF (moving the call), or un-anchor the closed/ prefix, fail the new --status test."

**Location:** commit 83cdb005 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the drop-plus-move mutant and the C39-defined un-anchor mutant (`${f/closed\//}`). Does not establish that either change alone is killed: dropping the local without moving the call, or moving the call without dropping the local, survives the suite, as does removing only the `#` anchor while keeping the full prefix.

Command: `bats test/scripts/build-loop-read.bats`, cwd `fc1/m-<id>`, 04:33:02Z.
- Mutant b (local `BRIEF=()` removed and `[[ -n "$SHARED_BRANCHES" ]] || shared_branches` moved after `brief_fields "$a"`): exit 1. Test 19 fails at `:457`, and T28 (test 16) also fails.
- Mutant d (`isbrief "${f/closed\//}"`, the pre-13380172 form per `git log -L314`): exit 1. Test 19 fails at `:453`.
- Mutant a (drop only): exit 0.
- Mutant c (move only): exit 0.
- Mutant w (`${f/docs\/working\/briefs\/closed\//...}` without `#`): exit 0.

The parenthetical "(moving the call)" correctly signals that the drop alone is not detected. That drop is inert while the call stays first in status_line (`scripts/build-loop.sh:323`).

**Evidence:** `fc1/logs/mutant-diffs-build-loop.txt`, `fc1/logs/mutant-a-blr.txt`, `fc1/logs/mutant-b-blr.txt`, `fc1/logs/mutant-c-blr.txt`, `fc1/logs/mutant-d-blr.txt`, `fc1/logs/mutant-w-blr.txt`, `scripts/build-loop.sh:303-328`

---

## Claim 19: commit message: "Notes: 118 changed code lines."

**Location:** commit 83cdb005 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers pr-prep step 1a's count against main. Does not establish any other counting rule.

Command: `git diff --numstat main...HEAD -- ':(top)' ':(top,exclude)docs/' | awk '{ n += $1 + $2 } END { print n+0 }'`, cwd `/workspace/.claude/wt-build-loop-u1d`, exit 0, about 04:40Z. Output `118`, from 15+12, 2+2, 6+4, 63+1 and 11+2 (`fc1/logs/linecount.txt`). The command is quoted from `workflows/pr-prep.md:91`.

**Evidence:** `workflows/pr-prep.md:86-91`, `fc1/logs/linecount.txt`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 1** (`scripts/build-loop.sh:17-18`): an exact never line beside a hidden copy that the letters check detects (bold) still gives "more than one line", so self-merge stays off. The qualifier's implied rescue holds only for task-box or fenced copies.
- **Claim 10** (`test/scripts/build-loop-read.bats:420`): "A caller's own GIT_CONFIG_COUNT pairs stay" is not asserted. Mutant i (guard clobbers KEY_0) survives.
- **Claim 11** (`test/scripts/build-loop-read.bats:428`): "the whole header" checks only the first and last lines.
- **Claim 12** (`test/scripts/build-loop-read.bats:444-448`): the CRLF step's "keeps its own Dispatched value" is not asserted there (o is skipped and p has no Dispatched line). Single-layer open-filter mutants o and p survive. The exit-1 step is output-equivalent under mutant r.
- **Claim 14** (`test/scripts/dev-cycle.bats:1328`): "before any read" is not asserted. Mutant l (pathform after ls-tree) survives.
- **Claim 17** (commit message): C26 / row 246's "unread file" slots case is untested (mutant k survives), and items (b)-(d) above apply.

### Unverifiable
(none)

## Goal-Alignment Note

The goal is to review and land U1d, whose intent is wording and tests for the deferred rows, plus main_entry's guard, with no other behaviour change. No comment, help text or commit claim is contradicted by the code (no Incorrect verdicts). The guard changes no caller's output (Claim 9). The two named mutants are killed (Claim 18). The remaining gaps are in test coverage, not wording. Untested are:
- the "unread file" slots case from row 246 (C26), listed as resolved;
- the survival of the caller's GIT_CONFIG pairs;
- each single layer of F31's open-only filter;
- main_entry's refuse-before-read ordering.

Three test texts claim more than they assert: the CRLF step comment, and the "whole header" and "before any read" titles. Whether these warrant a fix commit or a deferral row is for the rubric stage.
