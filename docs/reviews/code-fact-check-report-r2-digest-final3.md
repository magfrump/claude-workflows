Commit: baa46e3

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-digest (branch feat/dev-cycle-digest; HEAD 65bd433, code at baa46e3; `git diff baa46e3 HEAD -- scripts test` is empty)
**Scope:** scripts/dev-cycle.sh (comments, header, user-facing claim text), test/scripts/dev-cycle.bats (test names and comments), commit messages 4225753..baa46e3 (weight on baa46e3), fix claims F1-F6 from the review brief
**Checked:** 2026-09-30
**Total claims checked:** 32 (31 numbered; Claim 27 split into 27a/27b)
**Summary:** 21 verified, 9 mostly accurate, 1 stale, 1 incorrect, 0 unverifiable

Replicate r2 of 3. Hallucination-pattern log read (docs/reviews/hallucination-patterns.md). No claim here matches a logged pattern; the closest is the tally-type pattern ("All 85 tests…"). Claim 29 (a line count) was checked with that in mind, and the count itself is right.

Execution logs (all under `docs/reviews/execution-logs/`, cwd noted inside each):
- `r2-digest-final3-bats.txt`: `bats test/scripts/dev-cycle.bats`, cwd worktree root, 2026-09-30T21:06Z, exit 0, 13/13 ok.
- `r2-digest-final3-old-script.txt`: the same bats file run against `git show de53069:scripts/dev-cycle.sh` in a mktemp copy. Exit 1; tests 2 and 3 fail, the other 11 pass.
- `r2-digest-final3-probes.txt` and `r2-digest-final3-probes2.txt`: probe scripts P1-P11 (scratchpad `probe.sh` / `probe2.sh`, run under `timeout 120`) against the worktree script, one fresh `mktemp -d` repo per probe. Both exit 0; timestamps 2026-09-30T21:07:13Z and 21:07:30Z.
- `r2-digest-final3-mutants.txt`: mutant copies of the script (M1 ignore "Main at:", M2 file-level compare, M3 no output filter) run against tests 2 and 3, 2026-09-30T21:07:41Z.

All temp dirs were removed. No background processes were started.

---

## Claim 1: "Default: the date in the newest docs/working/cycles/cycle-YYYY-MM-DD.md, else 14 days ago. The digest says which."

**Location:** `scripts/dev-cycle.sh:10-12`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the default window source when no --since is given, including ignoring future-dated records. Does not establish behavior for records whose names match the glob but are not regular files.
**Legibility-target:** for-orchestrator-synthesis

`scripts/dev-cycle.sh:65-77` loops over `cycle-[0-9]…md`, keeps the newest date not later than `$TODAY`, and otherwise sets `SINCE="$(date -d "$TODAY - 14 days" +%F)"` with a `source_note` that is printed on the Window line. Bats test 4 ("the window defaults to the newest cycle record's date and says so") passes, and it includes a `cycle-9999-12-31.md` decoy.

**Evidence:** `scripts/dev-cycle.sh:64-77`, `test/scripts/dev-cycle.bats:89-96`, docs/reviews/execution-logs/r2-digest-final3-bats.txt

---

## Claim 2: "Read-only: writes nothing to the repo (one temp file, removed on exit)." (F2: "No git status call, so nothing writes .git/index")

**Location:** `scripts/dev-cycle.sh:15-16`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every git command in the script (log, rev-list, show, merge-base, rev-parse, symbolic-ref) on a repo whose index is stat-dirty, and the absence of any `git status` call. Does not establish behavior under repo configs that trigger background maintenance or commit-graph writes, or that the `questions.sh open` child writes nothing (not audited here).
**Legibility-target:** for-orchestrator-synthesis

`grep -n status scripts/dev-cycle.sh` finds no git status call. In de53069 the call sat at line 111: `$(git status --porcelain -- "$f")`. Probe P5 touched a tracked file after its commit, so the index was stat-dirty, then ran the script twice (default and `--since=2000-01-01`). A recursive `ls -laR --time-style=full-iso .git` gave the same md5 before and after: ".git listing unchanged". The temp file is `qs_err="$(mktemp)"; trap 'rm -f "$qs_err"' EXIT` (`scripts/dev-cycle.sh:148`), which is created in $TMPDIR, not in the repo.

**Evidence:** `scripts/dev-cycle.sh:148`, docs/reviews/execution-logs/r2-digest-final3-probes.txt (P5)

---

## Claim 3: "Exit: 0 digest printed; 1 bad usage, not a git repo or no default branch; a failed step exits non-zero mid-digest." (F4)

**Location:** `scripts/dev-cycle.sh:17-18`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exit status with the `exec > >(tr …)` filter in place: a failing mid-digest step (shuf shimmed to exit 3), bad --since, --sample and unknown options, captured through `$(…)` and through a pipe. Does not establish the order of stdout and stderr on an interactive terminal (see Claim 6).
**Legibility-target:** for-orchestrator-synthesis

- **P6 (failing step):** with `shuf` shimmed to `exit 3`, the script exited `exit=3`. The captured output ended at "## 4. Spot-check sample", so the digest stops mid-way. Piping to `wc -l` delivered 27 lines, with `pipestatus=3 0`, so the filter neither swallows the status nor truncates the flushed text.
- **P10 (bad usage):** `--since` with no value exits 1, and `--sample=x` exits 1.
- **Bats test 13:** covers a malformed --since and an unknown option.

**Evidence:** `scripts/dev-cycle.sh:20`, `scripts/dev-cycle.sh:42`, `scripts/dev-cycle.sh:174`, docs/reviews/execution-logs/r2-digest-final3-probes.txt (P6, P10)

---

## Claim 4: "before the cd: relative paths work"

**Location:** `scripts/dev-cycle.sh:36`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers running a relative script path from a repo subdirectory. Does not establish symlinked installs.
**Legibility-target:** for-orchestrator-synthesis

`SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` runs before `cd "$ROOT"` (`scripts/dev-cycle.sh:36-38`). Bats test 8 passes.

**Evidence:** `scripts/dev-cycle.sh:36-38`, `test/scripts/dev-cycle.bats:131-140`, docs/reviews/execution-logs/r2-digest-final3-bats.txt

---

## Claim 5: "File names are literal, not pathspecs" (F5 first half; baa46e3: "file names are literal pathspecs")

**Location:** `scripts/dev-cycle.sh:39-41`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the `-- "$f"` pathspec uses at :118 and :181, which inherit `export GIT_LITERAL_PATHSPECS=1`. Does not establish anything for `git show "$base:$f"` (a revision:path, not a pathspec). The export also reaches the `questions.sh` child; it has no pathspec uses (its only git calls are `rev-parse`, `scripts/questions.sh:80-84`), so this is harmless.
**Legibility-target:** for-orchestrator-synthesis

`TODAY=…; export GIT_LITERAL_PATHSPECS=1` (`scripts/dev-cycle.sh:41`). Probe P11 committed a file named `docs/decisions/007-*.md` and left `007-zz.md` uncommitted. The digest printed `007-*.md (last committed on this branch: 2026-09-30)` and `007-zz.md (… never, uncommitted)`. Confidence is Medium because P11 does not tell literal from glob matching for this layout, since the glob would not match another committed file. The verdict rests on the export, which reaches every child process.

**Evidence:** `scripts/dev-cycle.sh:41`, `scripts/dev-cycle.sh:118`, `scripts/dev-cycle.sh:181`, docs/reviews/execution-logs/r2-digest-final3-probes2.txt (P11)

---

## Claim 6: "control characters are stripped from everything printed" (F3; baa46e3: "All output passes through one control-character filter")

**Location:** `scripts/dev-cycle.sh:40-42`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers stdout after line 42, including the questions.sh error text `cat "$qs_err"` at :163 and all awk/sed output. Does not cover stderr, C1 controls, or terminal ordering.
**Legibility-target:** for-author

The mechanism holds for stdout: `exec > >(LC_ALL=C tr -d '\000-\010\013-\037\177')` (`scripts/dev-cycle.sh:42`) filters everything written to fd 1 after that line. The questions.sh stderr is captured to a file and echoed on stdout (`:149`, `:163`), so it is filtered too. Probe P4 showed ESC removed: the output reads `A 302 233 3 1 m B [ 3 1 m C`.

Three things fall outside "everything printed":
- **C1 controls survive.** The UTF-8 bytes `\xc2\x9b` (U+009B, the 8-bit CSI that some terminals honour) came through as `302 233` in P4.
- **stderr is not filtered.** Only fd 1 is redirected. Messages at `:62` and `:78`, and any git or bash error, reach the terminal raw. None of these echo record text by design.
- **Output can land after the prompt.** The parent does not wait for the `tr` process, so on a terminal the output may appear after the shell prompt returns. `$(…)` and pipes are unaffected because they wait for EOF (see Claim 3). This was not executed, because it needs a TTY.

The precise version: "C0 control characters except TAB/LF, and DEL, are stripped from stdout."

**Evidence:** `scripts/dev-cycle.sh:42`, `scripts/dev-cycle.sh:149`, `scripts/dev-cycle.sh:163`, docs/reviews/execution-logs/r2-digest-final3-probes.txt (P4)

---

## Claim 7: "Pass git only a hash for the default branch … a branch named `--output=<path>` would reach `git log` as an option."

**Location:** `scripts/dev-cycle.sh:43-44`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the origin/HEAD option-name case in bats test 12. The accepted Won't-Fix (the test fails only when both defences are removed) still stands, and nothing here adds new evidence against it.
**Legibility-target:** for-orchestrator-synthesis

`[[ "$c" == -* ]] && continue` and `git rev-parse --verify --quiet "refs/heads/$c^{commit}"` (`:51-52`). Only `$MAIN_SHA` is passed to `git log` and `rev-list`. Test 12 passes.

**Evidence:** `scripts/dev-cycle.sh:45-62`, `test/scripts/dev-cycle.bats:193-203`, docs/reviews/execution-logs/r2-digest-final3-bats.txt

---

## Claim 8: "A bare date means 'this time of day' to git; anchor it at midnight."

**Location:** `scripts/dev-cycle.sh:79-80`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `--since` anchoring for the merge and commit counts. Does not establish timezone edge cases.
**Legibility-target:** for-orchestrator-synthesis

`SINCE_TS="$SINCE 00:00:00"` is used at `:89` and `:91`. Bats test 5 passes.

**Evidence:** `scripts/dev-cycle.sh:80`, `test/scripts/dev-cycle.bats:98-104`, docs/reviews/execution-logs/r2-digest-final3-bats.txt

---

## Claim 9: Window line: "Merges: `$MAIN` at <sha>. Triggers: the working tree, compared with `$MAIN` at the window start. Questions, roadmap: the working tree." (F6; baa46e3: "Window line states exactly which sections read what")

**Location:** `scripts/dev-cycle.sh:84`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers decision-record triggers without --since and with a usable base. Does not cover log rows, the --since path, or the roadmap's date source.
**Legibility-target:** for-author

The comparison exists for decision records only: `! cmp -s <(git show "$base:$f" 2>/dev/null | trig) <(trig < "$f")` (`:116`). The line is printed unconditionally, but three cases read differently from what it says:
- **Log rows** in the working tree are date-filtered, not compared with `$MAIN`: `if [[ $full -eq 1 || ! "$d" < "$SINCE" ]]` (`:130`).
- **With --since,** `full=1` and nothing is compared (`:97-102`).
- **The roadmap's "last committed on this branch" date** comes from HEAD's history, not from the working tree: `git log -1 --format=%ad --date=short -- docs/roadmap.md` (`:181`).

P9 shows the line printed in full when the recorded sha was unusable and the comparison silently used the date fallback instead.

The precise version: "Triggers: decision records in the working tree compared with `$MAIN` at the window start (not with --since); log rows by date."

**Evidence:** `scripts/dev-cycle.sh:84`, `scripts/dev-cycle.sh:97-102`, `scripts/dev-cycle.sh:130`, `scripts/dev-cycle.sh:181`, docs/reviews/execution-logs/r2-digest-final3-probes.txt (P9)

---

## Claim 10: "Main at: $MAIN_SHA (copy this line into the cycle record; the next digest compares triggers against it)"

**Location:** `scripts/dev-cycle.sh:85`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line pasted verbatim, unindented, at the start of the line (the skill template at `/workspace/.claude/wt-devcycle/skills/dev-cycle/SKILL.md:137` asks for exactly this), when the next run has no --since and the sha is still an ancestor. Does not establish any decorated form, which the parser silently ignores (see residue).
**Legibility-target:** for-orchestrator-synthesis

The parser is `sed -n 's/^Main at: \([0-9a-f]\{7,40\}\).*/\1/p'` (`:108`). The trailing `.*` accepts the digest's own parenthetical, so pasting the whole line works.

In P1, only the exact form made the fast-forwarded record print. Each of these fell back to the date and left `003-late` carried forward and never judged:
- `- Main at: <sha>`
- `**Main at:** <sha>`
- `` Main at: `<sha>` ``
- two-space indentation
- `` `Main at: <sha>` ``

The digest gives no sign that it fell back. This is a contract-fragility risk rather than a false comment, so it is routed below.

**Evidence:** `scripts/dev-cycle.sh:85`, `scripts/dev-cycle.sh:108-109`, `/workspace/.claude/wt-devcycle/skills/dev-cycle/SKILL.md:134-137`, docs/reviews/execution-logs/r2-digest-final3-probes.txt (P1), docs/reviews/execution-logs/r2-digest-final3-probes2.txt (P1b)

---

## Claim 11: "Printed in full: triggers in decision records changed since $SINCE, and log rows dated on or after it."

**Location:** `scripts/dev-cycle.sh:99`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the section-2 intro in the carry-forward path. Does not establish when the recorded sha and the record's date differ.
**Legibility-target:** for-author

- **Decision records:** "changed" means the trigger section differs from `$base`, which is the recorded "Main at:" commit, else the last first-parent commit before `$SINCE` midnight (`:108-109`, `:116`). The recorded commit is main's tip when the previous digest ran, not `$SINCE` midnight, so "since $SINCE" is only an approximation.
- **Log rows:** the half about log rows is exact: `! "$d" < "$SINCE"` (`:130`). As the wording says, a row carrying an older date is carried forward even when it was added after the window start. P8 shows this with a 2020-dated row committed today: "Carried forward (2): 001-old.md log row 5".

The precise version: "triggers in decision records whose trigger section changed since the window start".

**Evidence:** `scripts/dev-cycle.sh:99`, `scripts/dev-cycle.sh:108-116`, `scripts/dev-cycle.sh:130`, docs/reviews/execution-logs/r2-digest-final3-probes.txt (P8)

---

## Claim 12: "An explicit --since was given, so every trigger is printed in full."

**Location:** `scripts/dev-cycle.sh:102`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers decision records and log rows under --since. Does not establish anything else.
**Legibility-target:** for-orchestrator-synthesis

`full=1` short-circuits both `:116` and `:130`. P11 with `--since=2000-01-01` printed every record, and bats test 4 checks the sentence.

**Evidence:** `scripts/dev-cycle.sh:100-102`, `scripts/dev-cycle.sh:116`, `scripts/dev-cycle.sh:130`, docs/reviews/execution-logs/r2-digest-final3-probes2.txt (P11)

---

## Claim 13: "Window start = the commit the last cycle recorded ("Main at:"), else by date."

**Location:** `scripts/dev-cycle.sh:107-109`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the selection logic. Does not establish that the fallback is ever reported, or that the date fallback catches fast-forwards (Claim 14 and Claim 22 carry that residue).
**Legibility-target:** for-orchestrator-synthesis

On line 109, `A && B && C || D` parses as `((A && B) && C) || D`, so any of these falls back to the date:
- **A:** empty `base` (no record, or no parseable line)
- **B:** `--since` given
- **C:** the sha is not an ancestor, or is unknown/ambiguous (`git merge-base --is-ancestor` fails)

P9 used `Main at: deadbeefdeadbeef` and fell back silently. P7 used a record with no line, and M1 forced `base=""`. Both fell back to `git rev-list -1 --first-parent --before="$SINCE_TS" "$MAIN_SHA"`.

On the empty-base path: with no last record, `sed` on `cycle-.md` fails, and `|| true` keeps `set -e` from firing. When no commit predates the window, `base` stays empty, and `-z "$base"` prints everything (`:116`).

**Evidence:** `scripts/dev-cycle.sh:106-109`, `scripts/dev-cycle.sh:116`, docs/reviews/execution-logs/r2-digest-final3-probes.txt (P7, P9), docs/reviews/execution-logs/r2-digest-final3-mutants.txt (M1)

---

## Claim 14: "Changed = its trigger section differs from the default branch's copy at the window start: merged, fast-forwarded, branch-only and uncommitted all count."

**Location:** `scripts/dev-cycle.sh:114-115`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the section comparison at :116 with a recorded base, and with the date fallback. Does not establish rename tracking (a renamed record prints in full because it is absent at base, which errs on the side of printing).
**Legibility-target:** for-author

The first sentence is exact: `cmp -s <(git show "$base:$f" 2>/dev/null | trig) <(trig < "$f")` (`:116`). If `git show` or `cmp` errors, the `!` treats the record as changed. Process-substitution exit codes are not seen by `set -e`/`pipefail`, so no abort happens.

The list "fast-forwarded … all count" holds only when `base` is a recorded "Main at:" sha. Two exceptions:
- **Date fallback (P7).** A record with no "Main at:" line is the case for the first cycle after this lands. There, a record committed with a 2020 date on a branch and fast-forwarded into main today was listed as "Carried forward (2): 001-old.md 003-late.md", never judged. The fallback uses committer dates (`rev-list --before`), and the baa46e3 message itself calls those unreliable after a fast-forward.
- **Empty trigger section (P2).** A brand-new record whose trigger section is empty compares equal to "absent at base", so it appears as "Carried forward (2): 001-old.md 005-empty.md". That claims a carried verdict that no cycle ever gave.

**Evidence:** `scripts/dev-cycle.sh:106`, `scripts/dev-cycle.sh:109`, `scripts/dev-cycle.sh:114-123`, docs/reviews/execution-logs/r2-digest-final3-probes.txt (P2, P7)

---

## Claim 15: "### <file> (last committed on this branch: …)" heading, with newline replaced (F5 second half, F6)

**Location:** `scripts/dev-cycle.sh:118-119`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the heading line only. The carried-forward list at :122/:141 is not protected (Claim 26). Does not establish anything about other branches' history.
**Legibility-target:** for-orchestrator-synthesis

`echo "### ${f//$'\n'/ } (last committed on this branch: ${d:-never, uncommitted})"`, where `d` comes from `git log -1 … -- "$f"` on HEAD. P3b printed the newline-bearing name on one line: `### docs/decisions/002-a ### 999-forged (fake).md (last committed on this branch: 2026-09-30)`. "never, uncommitted" is the only spelling, used at `:119` and `:182` (F6).

**Evidence:** `scripts/dev-cycle.sh:118-119`, `scripts/dev-cycle.sh:182`, docs/reviews/execution-logs/r2-digest-final3-probes2.txt (P3b)

---

## Claim 16: "prefer a capitalised 'Revisit' (the trigger sentence) over an earlier 'revisit-trigger verdicts' mention"

**Location:** `scripts/dev-cycle.sh:131-134`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers log-row clause extraction. Does not establish anything about rows with pipes inside cells.
**Legibility-target:** for-orchestrator-synthesis

Bats test 2 asserts `log row 9 (2026-01-01): > Revisit if gizmos appear…` against a row that also contains "revisit-trigger verdicts". The test passes.

**Evidence:** `scripts/dev-cycle.sh:133-134`, `test/scripts/dev-cycle.bats:55-61`, docs/reviews/execution-logs/r2-digest-final3-bats.txt

---

## Claim 17: "`open` prints 'ID  route  slug' in columns of 2+ spaces; a route can contain one space…"

**Location:** `scripts/dev-cycle.sh:150-152`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers route filtering. Does not establish the questions.sh output format beyond the bats fixture.
**Legibility-target:** for-orchestrator-synthesis

Bats test 9 (a slug containing "trigger" is excluded, and the tally reads "agent=1, trigger=1") passes.

**Evidence:** `scripts/dev-cycle.sh:152-159`, `test/scripts/dev-cycle.bats:142-170`, docs/reviews/execution-logs/r2-digest-final3-bats.txt

---

## Claim 18: "Seeded by a hash of the date: same day, same merges; different days usually differ."

**Location:** `scripts/dev-cycle.sh:171-174`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers determinism and the fact that four dates are not all identical. Does not establish distribution quality.
**Legibility-target:** for-orchestrator-synthesis

Bats tests 6 and 7 pass.

**Evidence:** `scripts/dev-cycle.sh:173-174`, `test/scripts/dev-cycle.bats:106-129`, docs/reviews/execution-logs/r2-digest-final3-bats.txt

---

## Claim 19: "Each test builds a throwaway repo under $BATS_TEST_TMPDIR; this repo is untouched."

**Location:** `test/scripts/dev-cycle.bats:3-4`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers setup(): `HOME`, `GIT_CONFIG_GLOBAL=/dev/null`, `cd "$R"` under `$BATS_TEST_TMPDIR`, and test 8's copy of scripts/ into the temp dir. Does not establish that `questions.sh` spawned by the script leaves the real tree alone (it runs with `$PWD` = the temp repo).
**Legibility-target:** for-orchestrator-synthesis

`export HOME="$BATS_TEST_TMPDIR/home"`, `R="$BATS_TEST_TMPDIR/repo"`, `make_repo "$R" main`, `cd "$R"` (`test/scripts/dev-cycle.bats:15-19`).

**Evidence:** `test/scripts/dev-cycle.bats:8-20`, `test/scripts/dev-cycle.bats:131-135`

---

## Claim 20: Test "lists a decision record's revisit triggers …" asserts no ESC reaches output (F3 regression)

**Location:** `test/scripts/dev-cycle.bats:50-62`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers C0 ESC (an OSC 52 sequence) in record text. Does not test C1 controls or stderr (see Claim 6).
**Legibility-target:** for-orchestrator-synthesis

The test fails on the de53069 script at `:60` (`[[ … != *$'\033'* ]]`). It also fails on mutant M3, which replaces line 42 with `:`. It passes at baa46e3.

**Evidence:** `test/scripts/dev-cycle.bats:52`, `test/scripts/dev-cycle.bats:60`, docs/reviews/execution-logs/r2-digest-final3-old-script.txt, docs/reviews/execution-logs/r2-digest-final3-mutants.txt (M3)

---

## Claim 21: Test "after a cycle record, unchanged triggers carry forward and changed ones print", with comment "Committed on a branch before the window, fast-forwarded into main inside it."

**Location:** `test/scripts/dev-cycle.bats:64-87`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a fast-forwarded record dated 2020, an edit outside the section that is still carried, an uncommitted record, the boundary log row, and the recorded "Main at:" start. Does not test decorated "Main at:" forms, the date fallback's fast-forward miss, or an empty-section new record.
**Legibility-target:** for-orchestrator-synthesis

The fixture matches the comment. `late` is committed with `GIT_COMMITTER_DATE="2020-01-03T12:00:00"` on a branch, then `git merge -q --ff-only late` (`:73-75`).

The test fails in three setups:
- on the de53069 script ("not printed in full: if new thing.")
- on M1, which ignores the recorded sha, so the test depends on "Main at:"
- on M2, a file-level `git diff --quiet` compare; it fails on the uncommitted record's assertion first, and the "edit outside triggers" assertion at `:84` is the one that would catch a file-level compare that handled untracked files.

**Evidence:** `test/scripts/dev-cycle.bats:68-86`, docs/reviews/execution-logs/r2-digest-final3-old-script.txt, docs/reviews/execution-logs/r2-digest-final3-mutants.txt (M1, M2)

---

## Claim 22: baa46e3: "A record now prints in full when its '## Revisit triggers' section differs between the default branch at the window start and the working tree. That covers merges, fast-forwards, branch-only and uncommitted records, and ignores edits elsewhere in the file" (F1)

**Location:** commit baa46e3 message, bullet 1
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the recorded-sha path, which was verified for merges, fast-forwards, uncommitted records and outside edits. Does not hold for the date fallback or for a new record with an empty trigger section.
**Legibility-target:** for-author

The mechanism is exactly as stated (`scripts/dev-cycle.sh:116`). The claim covers all fast-forwards, but two cases escape it:
- **First cycle after landing (P7).** No existing cycle record carries a "Main at:" line, so the base comes from `rev-list --before` over committer dates. An old-dated fast-forwarded record is then carried forward unjudged, which is the F1 defect again.
- **Empty section (P2).** A new record with an empty section is listed as carried.

The precise version: "covers … once the previous record carries a 'Main at:' line".

**Evidence:** `scripts/dev-cycle.sh:108-123`, docs/reviews/execution-logs/r2-digest-final3-probes.txt (P2, P7)

---

## Claim 23: baa46e3: "The window start is the commit the last cycle recorded … and falls back to the last first-parent commit before the window when a record lacks it (commit dates alone are unreliable after a fast-forward)."

**Location:** commit baa46e3 message, bullet 2
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fallback conditions and what the fallback is based on. Does not establish anything about the dev-cycle skill's pasting behaviour.
**Legibility-target:** for-author

The fallback also fires when the line exists but:
- is decorated (P1)
- names a non-ancestor or unknown sha (P9)
- comes with --since

In none of these cases does the digest say so. The parenthetical reads as though the fallback avoids the date problem. In fact the fallback is committer-date based (`git rev-list -1 --first-parent --before="$SINCE_TS"`, `:109`) and carries the same unreliability (P7).

The precise version: "…falls back, silently, to the last first-parent commit whose committer date precedes the window whenever no usable 'Main at:' ancestor is found; that fallback keeps the fast-forward blind spot."

**Evidence:** `scripts/dev-cycle.sh:108-109`, docs/reviews/execution-logs/r2-digest-final3-probes.txt (P1, P7, P9)

---

## Claim 24: baa46e3: "No git status call, so nothing writes .git/index."

**Location:** commit baa46e3 message, bullet 3
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 2.
**Legibility-target:** for-orchestrator-synthesis

See Claim 2. P5 found an unchanged `.git` listing, including `.git/index`'s mtime, with a stat-dirty index.

**Evidence:** docs/reviews/execution-logs/r2-digest-final3-probes.txt (P5)

---

## Claim 25: baa46e3: "All output passes through one control-character filter"

**Location:** commit baa46e3 message, bullet 4
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 6.
**Legibility-target:** for-author

It is all stdout, not stderr, and the filter strips C0 and DEL only; C1 (`\xc2\x9b`) survives in P4. See Claim 6.

**Evidence:** `scripts/dev-cycle.sh:42`, docs/reviews/execution-logs/r2-digest-final3-probes.txt (P4)

---

## Claim 26: baa46e3: "a newline in a file name cannot forge a line" (F5)

**Location:** commit baa46e3 message, bullet 4
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the carried-forward list in section 2. The heading path is protected (Claim 15). Other echo sites of `$f` were not probed.
**Legibility-target:** for-author

Only the heading substitutes newlines (`:119`). The carried path stores the raw name, `carried+=("${f#docs/decisions/}")` (`:122`), and prints it with `printf '\nCarried forward (%s): %s\n' "${#carried[@]}" "${carried[*]}"` (`:141`). The glob `docs/decisions/[0-9][0-9][0-9]-*.md` (`:110`) matches names containing a newline.

In P3b, a committed, unchanged record named `$'002-a\n### 999-forged (fake).md'` produced:

```
Carried forward (2): 001-old.md 002-a
### 999-forged (fake).md
```

That second line is a forged heading line in the digest.

**Evidence:** `scripts/dev-cycle.sh:110`, `scripts/dev-cycle.sh:119`, `scripts/dev-cycle.sh:122`, `scripts/dev-cycle.sh:141`, docs/reviews/execution-logs/r2-digest-final3-probes2.txt (P3b)

---

## Claim 27a: baa46e3: "Header: a failed step exits non-zero mid-digest; 'uncommitted' spelled one way" (F4, F6)

**Location:** commit baa46e3 message, bullet 5
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the header wording and the exit status (Claim 3), and the single spelling (Claim 15). Does not cover the Window-line half (27b).
**Legibility-target:** for-orchestrator-synthesis

The exit is 3 when shuf fails (P6). The spelling is "never, uncommitted" at `:119` and `:182`.

**Evidence:** `scripts/dev-cycle.sh:17-18`, `scripts/dev-cycle.sh:119`, `scripts/dev-cycle.sh:182`, docs/reviews/execution-logs/r2-digest-final3-probes.txt (P6)

---

## Claim 27b: baa46e3: "Window line states exactly which sections read what"

**Location:** commit baa46e3 message, bullet 5
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 9.
**Legibility-target:** for-author

"Exactly" is too strong. The line leaves out log rows (date-based) and the --since no-compare path, and the roadmap date reads HEAD history. See Claim 9.

**Evidence:** `scripts/dev-cycle.sh:84`, `scripts/dev-cycle.sh:130`, `scripts/dev-cycle.sh:181`

---

## Claim 28: baa46e3: "Tests: fast-forwarded old-dated record, edit outside the trigger section (still carried), recorded 'Main at:' start, control codes in record text. Both fail on de53069."

**Location:** commit baa46e3 message, bullet 6
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four listed cases as they exist in tests 2 and 3, and those two tests failing on the de53069 script. Does not describe them as new @test cases: the count is 13 at both de53069 and baa46e3, and the cases were added to existing tests.
**Legibility-target:** for-orchestrator-synthesis

"Both" refers to the two edited tests (2 and 3). Both fail on de53069 (`not ok 2`, `not ok 3`), and the other 11 pass there. `grep -c '^@test'` gives 13 at both commits.

**Evidence:** `test/scripts/dev-cycle.bats:50-87`, docs/reviews/execution-logs/r2-digest-final3-old-script.txt

---

## Claim 29: baa46e3: "Unit stays at 399 lines."

**Location:** commit baa46e3 message, bullet 6
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line count of the two unit files at each commit. Does not establish the cap-counting rule itself.
**Legibility-target:** for-author

- At baa46e3: 187 + 212 = 399 (`git diff --numstat 4225753..baa46e3`: `187 0`, `212 0`).
- At de53069 and 83e7895: 186 + 210 = 396, which matches 83e7895's own "(396)".

So the unit grew from 396 to 399 rather than staying at 399. The precise version: "Unit is now 399 lines (was 396), under the 400 cap."

**Evidence:** scripts/dev-cycle.sh, test/scripts/dev-cycle.bats (wc -l at 83e7895, de53069, baa46e3; commands recorded in this report's run, output quoted above)

---

## Claim 30: baa46e3 Notes: "The skill must copy the 'Main at:' line into each cycle record (stacked unit)."

**Location:** commit baa46e3 message, Notes
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the skill's close-step template. Does not establish that an agent following it produces the bare form (P1 shows decorated forms fail silently).
**Legibility-target:** for-orchestrator-synthesis

`Main at: <sha from the digest, on its own unindented line>` and "keeping a single `Main at:` line" (`/workspace/.claude/wt-devcycle/skills/dev-cycle/SKILL.md:134-137`).

**Evidence:** `/workspace/.claude/wt-devcycle/skills/dev-cycle/SKILL.md:134-137`

---

## Claim 31: 83e7895: "Uncommitted files show 'never: uncommitted', not an empty date." / "A decision record now counts as changed when it entered the default branch in the window (first-parent history…) or is uncommitted"

**Location:** commit 83e7895 message
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers 83e7895's description against the code at baa46e3. It was accurate for 83e7895's code, which used `git log --first-parent --since` plus `git status --porcelain` per de53069:111. Historical, and nothing to fix in a commit message.
**Legibility-target:** for-author

The code now prints `never, uncommitted` (`scripts/dev-cycle.sh:119`) and uses the section comparison (`:116`), not window-entry history. The earlier pass's F6 reconciled the spelling.

**Evidence:** `scripts/dev-cycle.sh:116-119`

---

## Unverifiable (noted, not numbered as a separate claim)

**Claim 6 residue:** that output can print after the shell prompt on an interactive terminal (the parent does not wait for `tr`). This needs a TTY, and none is available in the sandbox, so it was not executed. The claim itself is counted under Claim 6 and this residue is not counted separately.

## Claims Requiring Attention

### Incorrect
- **Claim 26** (commit baa46e3, bullet 4; code `scripts/dev-cycle.sh:122,141`): the carried-forward list prints raw file names, so a newline in a name forges a line (P3b). Only the heading at `:119` is protected.

### Stale
- **Claim 31** (commit 83e7895): it describes the replaced first-parent-plus-git-status mechanism and the "never: uncommitted" spelling. Historical, nothing to fix.

### Mostly Accurate
- **Claim 6** (`scripts/dev-cycle.sh:40-42`): the filter covers stdout only, and C0+DEL only. C1 `\xc2\x9b` survives and stderr is unfiltered.
- **Claim 9** (`scripts/dev-cycle.sh:84`): the Window line omits that log rows are date-filtered, that --since skips the comparison, and that the roadmap date reads HEAD history.
- **Claim 11** (`scripts/dev-cycle.sh:99`): "changed since $SINCE" is really "trigger section changed since the recorded or fallback base commit".
- **Claim 14** (`scripts/dev-cycle.sh:114-115`): "fast-forwarded … all count" fails under the date fallback (P7), and an empty-section new record is carried (P2).
- **Claim 22** (commit baa46e3, bullet 1): the F1 coverage holds only once a record carries a usable "Main at:" line. The first cycle after landing reintroduces the fast-forward miss.
- **Claim 23** (commit baa46e3, bullet 2): the fallback also fires on decorated, non-ancestor or --since input, does so silently, and is itself committer-date based.
- **Claim 25** (commit baa46e3, bullet 4): "all output" means all stdout, and only C0+DEL.
- **Claim 27b** (commit baa46e3, bullet 5): "exactly" overstates the Window line.
- **Claim 29** (commit baa46e3, bullet 6): the unit went from 396 to 399 lines; it did not "stay at 399".

### Unverifiable
- **Claim 6 residue:** output ordering relative to the shell prompt on a TTY. Needs an interactive terminal.

## Goal-Alignment Note

- **Success criterion (verbatim from the brief):** "a markdown report saved at the output path named at the end of this prompt, structured per your skill, with a Goal-Alignment Note."
- **Answered:** yes. Every comment and header claim in scripts/dev-cycle.sh, the test names and comments in test/scripts/dev-cycle.bats, the baa46e3 message (plus the stale 83e7895 wording) and F1-F6 were each checked, mostly by execution:
  - **Held:** F2, F3 (stdout), F4, and F6's spelling.
  - **Partly held:** F1 holds on the recorded-sha path but not on the date fallback. F5 holds for literal pathspecs and the heading, but not for the carried list.
  - **Tests:** both edited tests fail on de53069 and on the relevant mutants.
- **Out of scope:** whether the design (silent fallback, date-based log rows) is the right one; questions.sh's own write behaviour; TTY output ordering (no TTY).
- **Escalate:**
  - **security-reviewer:**
    - line forging through a newline in a file name in the "Carried forward" list (`:122`, `:141`; P3b)
    - C1 control bytes (U+009B CSI) passing the `tr` filter (P4)
    - unfiltered stderr
  - **api-consistency-reviewer:**
    - the "Main at:" contract between digest and skill: decorated pastes, a non-ancestor sha, and missing lines all fall back to the date silently. The digest never says which base it used (P1, P9).
    - the Window line not naming the log-row and --since semantics
  - **performance-reviewer:** nothing to route.
- **Decisions:** the first cycle after this lands will have no "Main at:" line in any record, so its comparison runs on the committer-date fallback, which has the F1 fast-forward blind spot (P7). Whoever gates this merge should decide whether that one-time exposure is acceptable, or whether the first run should use --since.
