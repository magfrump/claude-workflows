Commit: baa46e3

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-digest (branch feat/dev-cycle-digest; HEAD 65bd433, whose scripts/ and test/ are identical to baa46e3: `git diff --stat baa46e3 HEAD -- scripts test` is empty)
**Scope:** scripts/dev-cycle.sh (187 lines, read whole), test/scripts/dev-cycle.bats (212 lines, read whole), commit messages 4225753..baa46e3 (weight on baa46e3), fixes F1-F6 from the review brief; contract consumer /workspace/.claude/wt-devcycle/skills/dev-cycle/SKILL.md:130-140 (read-only context)
**Checked:** 2026-09-30
**Total claims checked:** 25 (Claims 1-24, with Claim 14 split into 14a/14b)
**Summary:** 17 verified, 5 mostly accurate, 0 stale, 3 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 5 entries) read first. None of the claims below matches a logged pattern; none of the Incorrect verdicts is a fabricated symbol, so the log is not updated.

Execution logs (all under `docs/reviews/execution-logs/`, all probes in `mktemp -d` repos, each process under `timeout`, temp dirs removed):
- `r1-digest-final3-bats.txt` — `bats test/scripts/dev-cycle.bats`, cwd worktree root, 2026-09-30T14:05:41-07:00, exit 0 (13/13).
- `r1-digest-final3-old-de53069.txt` — new tests against `git show de53069:scripts/dev-cycle.sh`, 2026-09-30T14:05:42-07:00, exit 1 (tests 2 and 3 fail).
- `r1-digest-final3-probe1.txt` — window-start fallback, decorated "Main at:" lines, Activity counts; 2026-09-30T14:07:19-07:00. Script: scratchpad `fc3/probe1.sh` (commands echoed in the log).
- `r1-digest-final3-probe2.txt` — newline file names, empty trigger section, `.git` write check, failing mid-digest step, C1 controls, output completeness; 2026-09-30T14:07:41-07:00.
- `r1-digest-final3-mutations.txt`, `r1-digest-final3-mutations2.txt` — single-line mutations of the script run against the suite; 2026-09-30T14:08:01 / 14:08:23-07:00. (Mutation M1 in the first log did not apply — "changed lines: 0" — and is superseded by M1b in the second.)

---

## Claim 1: "The dev-cycle skill (skills/dev-cycle/SKILL.md) runs the judgment steps on top of this digest ... (scripts/questions.sh header; Q-074)"

**Location:** `scripts/dev-cycle.sh:4-6`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers existence of the three referents; does not establish that the skill (stacked branch) lands, since the reference is forward until feat/dev-cycle merges.

`/workspace/.claude/wt-devcycle/skills/dev-cycle/SKILL.md` exists (stacked branch, as 3aee138 says: "The script's references to the skill are forward references until then"). `scripts/questions.sh:5-8`: "Why a script and not a convention: this repo's own evidence is that an unenforced instruction does not execute ... both because only prose asked for them." `docs/working/questions.md:67`: `### Q-074 · failure-pattern-writer-trigger`.

**Evidence:** `scripts/questions.sh:5-8`, `docs/working/questions.md:67`, `/workspace/.claude/wt-devcycle/skills/dev-cycle/SKILL.md`

---

## Claim 2: "--since start of the cycle window (midnight, local time). Default: the date in the newest docs/working/cycles/cycle-YYYY-MM-DD.md, else 14 days ago. The digest says which."

**Location:** `scripts/dev-cycle.sh:10-12`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the default source, the future-dated skip, and the midnight anchor; does not establish anything about the trigger comparison's base, which since baa46e3 is not the date (see Claims 12-14).

`scripts/dev-cycle.sh:65-77` picks the newest non-future record date, else `SINCE="$(date -d "$TODAY - 14 days" +%F)"`, and sets `source_note` accordingly; line 80 `SINCE_TS="$SINCE 00:00:00"`. Tests 4 ("the window defaults to the newest cycle record's date and says so", with a 9999-12-31 record ignored) and 5 ("--since counts from midnight") pass.

**Evidence:** `scripts/dev-cycle.sh:64-80`, `test/scripts/dev-cycle.bats:89-104`, `docs/reviews/execution-logs/r1-digest-final3-bats.txt`

---

## Claim 3: "Read-only: writes nothing to the repo (one temp file, removed on exit)." / baa46e3: "No git status call, so nothing writes .git/index."

**Location:** `scripts/dev-cycle.sh:16`; commit baa46e3 body
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the script's own git commands (rev-parse, symbolic-ref, log, rev-list, merge-base, show) and the questions.sh-absent path in a probe repo; does not establish behavior under repo-local hooks or config that makes read commands write (none of these commands runs hooks), nor the questions.sh `open` path's writes beyond the temp file.

`grep -n 'status' scripts/dev-cycle.sh` returns nothing (paraphrased — no quote available because the claim is an absence of code). Probe F: `ls -laR --time-style=full-iso .git` before and after a full run (exit 0) printed ".git listing identical". The one temp file is `qs_err="$(mktemp)"; trap 'rm -f "$qs_err"' EXIT` (`scripts/dev-cycle.sh:148`), created only when questions.md and questions.sh exist, and in `$TMPDIR`, not the repo.

**Evidence:** `scripts/dev-cycle.sh:148`, `docs/reviews/execution-logs/r1-digest-final3-probe2.txt` (section F)

---

## Claim 4: "Exit: 0 digest printed; 1 bad usage, not a git repo or no default branch; a failed step exits non-zero mid-digest." (F4)

**Location:** `scripts/dev-cycle.sh:17-18`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bad option/date (test 13), `--since` with no value (exit 1), and a mid-digest failure injected via a failing `shuf` shim; does not establish output ordering on an interactive terminal (stdout goes through `tr`, stderr does not).

Probe G put a `shuf` that exits 3 first on PATH: the run exited 3 with sections 1-3 printed and "## 4. Spot-check sample" as the last line, so the output filter at line 42 does not mask the status and the digest is visibly cut mid-section. Probe I: `bash dev-cycle.sh --since` exited 1 (`${2:?...}`, line 26). Test 13 asserts status 1 for `--since 2026/01/01`, `--since=2026-13-45`, `--bogus`.

**Evidence:** `scripts/dev-cycle.sh:26,31,34,37,62,78`, `test/scripts/dev-cycle.bats:205-212`, `docs/reviews/execution-logs/r1-digest-final3-probe2.txt` (G, I)

---

## Claim 5: "before the cd: relative paths work"

**Location:** `scripts/dev-cycle.sh:36`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers invocation by relative path from a subdirectory; does not establish symlinked installs (`BASH_SOURCE` is not resolved through links).

`SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` runs before `cd "$ROOT"` (line 38). Test 8 ("runs from a subdirectory with a relative script path") passes.

**Evidence:** `scripts/dev-cycle.sh:36-38`, `test/scripts/dev-cycle.bats:131-140`, `docs/reviews/execution-logs/r1-digest-final3-bats.txt`

---

## Claim 6: "File names are literal, not pathspecs" (F5, first half)

**Location:** `scripts/dev-cycle.sh:40-41`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the `-- "$f"` and `-- docs/roadmap.md` pathspecs (lines 118, 181), which read the exported variable; does not establish a test for it — mutation M5 (drop the export) leaves all 13 tests passing.

Line 41: `export GIT_LITERAL_PATHSPECS=1`, set before every git call that takes a pathspec (lines 118, 181). The `"$base:$f"` form at line 116 is a revision:path, not a pathspec, and is unaffected either way (paraphrased — no quote available because this is git's documented rev:path syntax, not code in the repo).

**Evidence:** `scripts/dev-cycle.sh:41,116,118,181`, `docs/reviews/execution-logs/r1-digest-final3-mutations.txt` (M5)

---

## Claim 7: "control characters are stripped from everything printed" (F3)

**Location:** `scripts/dev-cycle.sh:40,42`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every stdout byte, including questions.sh's error text (cat'd to stdout at line 163) and awk/sed output; does not establish stripping of stderr or of C1 controls.

Line 42: `exec > >(LC_ALL=C tr -d '\000-\010\013-\037\177')` — C0 except TAB/LF, plus DEL, on fd 1 only. Probe D2: a trigger line containing ESC and UTF-8 U+009B (bytes C2 9B, the 8-bit CSI) printed as `> if c1 M-BM-^[31mred and [31mesc.` — ESC removed, the C1 CSI kept. stderr (lines 31, 34, 62, 78 and any git error under `set -e`) is not redirected through the filter. TAB is kept by design (accepted Won't-Fix F8). Probes J/K: 20 piped runs and 20 file-redirected runs each yielded the same 1286 bytes, so no truncation was observed from `tr` outliving the parent. Precise version: "C0 control characters (except TAB and newline) and DEL are stripped from stdout."

**Evidence:** `scripts/dev-cycle.sh:42,163`, `docs/reviews/execution-logs/r1-digest-final3-probe2.txt` (D2, J, K), `docs/reviews/execution-logs/r1-digest-final3-mutations.txt` (M3)

---

## Claim 8: "Pass git only a hash for the default branch: origin/HEAD comes from the remote, and a branch named `--output=<path>` would reach `git log` as an option."

**Location:** `scripts/dev-cycle.sh:43-44`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the default-branch resolution (lines 45-62) and test 12; does not re-examine the accepted Won't-Fix that the test fails only when both defences are removed.

Line 51 `[[ "$c" == -* ]] && continue`; line 52 resolves `refs/heads/$c^{commit}` to a sha, which is what lines 89/91/109 pass. Test 12 passes.

**Evidence:** `scripts/dev-cycle.sh:45-62`, `test/scripts/dev-cycle.bats:193-203`, `docs/reviews/execution-logs/r1-digest-final3-bats.txt`

---

## Claim 9: "Window: since $SINCE ... Triggers: the working tree, compared with `$MAIN` at the window start. Questions, roadmap: the working tree." (F6)

**Location:** `scripts/dev-cycle.sh:84`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers decision-record triggers when a verbatim "Main at:" line is present; does not establish that log rows are compared at all (they are selected by date) or that "the window start" is the window start on the date fallback.

Decision records: line 116 compares `git show "$base:$f"` with the working tree — matches. Log rows: line 130 `if [[ $full -eq 1 || ! "$d" < "$SINCE" ]]` selects by the row's own date, not by comparing with `$MAIN` at the window start. The "window start" is the "Main at:" commit (the default branch when the previous digest ran, not at the `$SINCE` midnight), or on fallback the first first-parent commit with a committer date before `$SINCE_TS`, which probe A shows can be a fast-forwarded commit that lies after in-window commits (Claim 14). Precise version: "Decision-record triggers: the working tree, compared with `$MAIN` at the last recorded commit (else a date estimate); log rows: by their date."

**Evidence:** `scripts/dev-cycle.sh:84,108-109,116,130`, `docs/reviews/execution-logs/r1-digest-final3-probe1.txt` (A)

---

## Claim 10: "Main at: $MAIN_SHA (copy this line into the cycle record; the next digest compares triggers against it)"

**Location:** `scripts/dev-cycle.sh:85`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a line copied verbatim and unindented (the form the skill's template at SKILL.md:137 prescribes), including a 7-char short sha; does not establish that any decorated copy is read — bullet, backticks, bold, leading spaces and upper-case hex all fall back silently with no message.

Line 108: `sed -n 's/^Main at: \([0-9a-f]\{7,40\}\).*/\1/p'` matches the printed line (`.*` absorbs the parenthetical). Probe B: the verbatim line and `Main at: caa6018` both printed 002-new and 003-late in full and carried only 001-old; `- Main at:`, `` Main at: `sha` ``, `**Main at:**`, two-space indent and upper-case hex each carried all three records, identical to the no-line case. Mutation M1b (`base=""` at line 108) fails test 3, so the suite guards the read.

**Evidence:** `scripts/dev-cycle.sh:85,108-109`, `/workspace/.claude/wt-devcycle/skills/dev-cycle/SKILL.md:134-137`, `docs/reviews/execution-logs/r1-digest-final3-probe1.txt` (B), `docs/reviews/execution-logs/r1-digest-final3-mutations2.txt`

---

## Claim 11: "N merge(s) on `$MAIN`'s first-parent line; M commit(s) reachable from it, merged branches included."

**Location:** `scripts/dev-cycle.sh:89-93`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the Activity counts (and therefore the section-4 sample, which draws from `$merges`) when the first-parent line holds a commit whose committer date is older than the window; does not establish behavior with monotonic dates, where the counts were correct in tests 1, 5 and 11. Present since 3aee138, not introduced by baa46e3.

Lines 89 and 91 use `git log "$MAIN_SHA" --first-parent --merges --since="$SINCE_TS"` and `git rev-list --count --since="$SINCE_TS"`; git's `--since` stops the walk at old-dated commits. Probe C: two `--no-ff` merges made today sit beneath a fast-forwarded commit dated 2020-01-03, and the digest printed "0 merge(s) on `main`'s first-parent line; 0 commit(s) reachable from it" while `git log --first-parent --merges main` lists both. This is the same fast-forward, old-date scenario baa46e3's message names ("commit dates alone are unreliable after a fast-forward"), and the new test 3 builds it without checking section 1. The same walk-stop is why test 3 fails on de53069 at "if new thing." (the old line-116 equivalent used `git log -1 --first-parent --since`).

**Evidence:** `scripts/dev-cycle.sh:89-94,170-174`, `docs/reviews/execution-logs/r1-digest-final3-probe1.txt` (A, C), `docs/reviews/execution-logs/r1-digest-final3-old-de53069.txt`

---

## Claim 12: "Printed in full: triggers in decision records changed since $SINCE, and log rows dated on or after it. Listed by name only: the rest, whose verdict carries forward ..."

**Location:** `scripts/dev-cycle.sh:99`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the text against lines 106-140 as read in full; does not establish that the recorded commit equals the state at `$SINCE`.

"changed since $SINCE" describes a date, but the code compares with `$base`, the recorded "Main at:" commit (lines 108-109, 116), which is the default branch at the time the previous digest ran (any time on the `$SINCE` day, or later if the record is updated in place). Log rows are date-selected as stated (line 130). Precise version: "triggers in decision records changed since the commit the last record names (Main at), and log rows dated on or after $SINCE."

**Evidence:** `scripts/dev-cycle.sh:99,106-140`

---

## Claim 13: "Window start = the commit the last cycle recorded ("Main at:"), else by date."

**Location:** `scripts/dev-cycle.sh:107-109`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `A && B || C` list at line 109 as read (with `--since`, with no record, with a non-matching line); does not establish that the date branch yields the window start (Claim 14).

Line 109: `[[ -n "$base" && "$source_note" != --since ]] && git merge-base --is-ancestor "$base" "$MAIN_SHA" 2>/dev/null || base="$(git rev-list -1 --first-parent --before="$SINCE_TS" "$MAIN_SHA")"`. Precedence is `(A && B) || C`, so the fallback runs when there is no line, when `--since` was given, or when the sha is not an ancestor (ambiguous short sha, sha from another default branch, rewritten history); with `--since` or no record `full=1` (line 101), so `base` is unused. The fallback is silent — no digest line says which start was used — and it also covers decorated lines (Claim 10). `base` empty (no commit before the window) makes line 116's `-z "$base"` print everything. Precise version: "... else, silently, the first first-parent commit with a committer date before the window."

**Evidence:** `scripts/dev-cycle.sh:97-109,116`, `docs/reviews/execution-logs/r1-digest-final3-probe1.txt` (A, B)

---

## Claim 14a: "Changed = its trigger section differs from the default branch's copy at the window start: merged, fast-forwarded, branch-only and uncommitted all count." — with a verbatim, ancestor "Main at:" line

**Location:** `scripts/dev-cycle.sh:114-116`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers merged, fast-forwarded (old-dated), uncommitted and in-window committed records, plus the edit-outside-the-section case, when `$base` comes from the record; does not establish the fallback path (14b), renamed records (printed in full: absent at base), or a new record whose trigger section is empty (carried: both sides empty — probe E, "009-new-empty.md" in the carried list).

Test 3 builds all four kinds and passes; probe B (verbatim line) printed 002-new and 003-late and carried 001-old. `cmp -s <(git show "$base:$f" 2>/dev/null | trig) <(trig < "$f")` treats a `git show` failure or a `cmp` error as "differs" (printed), the safe direction; `set -e`/`pipefail` do not reach inside the process substitutions. A path containing ':' is fine in `<sha>:<path>` form. Mutations: M2 (compare whole file) fails test 3 at `!= *"if old thing."*`; M1b (ignore the line) fails test 3 at "if new thing.".

**Evidence:** `scripts/dev-cycle.sh:106,110-124`, `test/scripts/dev-cycle.bats:64-87`, `docs/reviews/execution-logs/r1-digest-final3-probe1.txt` (B), `docs/reviews/execution-logs/r1-digest-final3-probe2.txt` (E), `docs/reviews/execution-logs/r1-digest-final3-mutations.txt` (M2), `docs/reviews/execution-logs/r1-digest-final3-mutations2.txt`

---

## Claim 14b: same comment (and baa46e3: "That covers merges, fast-forwards, branch-only and uncommitted records") — on the date fallback

**Location:** `scripts/dev-cycle.sh:114-116` (with `:109`)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fallback path (record without a line, a decorated line, or a non-ancestor sha); does not establish how often that path is reached — no cycle record exists yet in this repo (`docs/working/cycles` absent on main and both worktrees), and the skill's template writes the line verbatim, so it is reached by a mis-copied line or rewritten history, not by the first cycle.

Probe A (record with no "Main at:" line; main's first-parent line: old record 2020-01-02 → two merges today → "new record" today → fast-forwarded "late" dated 2020-01-03): the fallback `git rev-list -1 --first-parent --before="$SINCE_TS"` picked `70a542e ... late` — the fast-forwarded commit itself, after the in-window "new record" commit. The digest printed "Carried forward (3): 001-old.md 002-new.md 003-late.md": the fast-forwarded record and a record committed today on main were both carried forward unjudged. This is F1's failure reproduced on the fallback, through the committer-date reliance the commit message itself calls unreliable.

**Evidence:** `scripts/dev-cycle.sh:109,116`, `docs/reviews/execution-logs/r1-digest-final3-probe1.txt` (A)

---

## Claim 15: "### ${f//$'\n'/ } (last committed on this branch: ${d:-never, uncommitted})" (F5 heading, F6 labels)

**Location:** `scripts/dev-cycle.sh:118-119`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the heading line only; does not establish the carried-forward list (Claim 16) or a test — mutation M4 (drop the replacement) passes all 13 tests.

Line 118 `git log -1 --format=%ad --date=short -- "$f"` walks HEAD, i.e. "this branch". Probe D2: a file named `006-b<LF>Carried forward (9): forged.md` printed as one heading line `### docs/decisions/006-b Carried forward (9): forged.md (last committed on this branch: 2026-09-30)`. "never, uncommitted" is the only spelling in the file (lines 119, 182).

**Evidence:** `scripts/dev-cycle.sh:118-119,181-182`, `docs/reviews/execution-logs/r1-digest-final3-probe2.txt` (D2), `docs/reviews/execution-logs/r1-digest-final3-mutations.txt` (M4)

---

## Claim 16: baa46e3: "a newline in a file name cannot forge a line" (F5)

**Location:** commit baa46e3 body; code at `scripts/dev-cycle.sh:122,141`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the carried-forward list; does not establish other output paths (merge subjects are single-line `%s`; log rows come from line-oriented grep).

Only the heading (line 119) replaces the newline. The carry branch stores the raw name, `carried+=("${f#docs/decisions/}")` (line 122), and line 141 prints it: `printf '\nCarried forward (%s): %s\n' "${#carried[@]}" "${carried[*]}"`. Probe D1 (records unchanged since the recorded commit): output was two lines, `Carried forward (3): 006-b` and a forged `Carried forward (9): forged.md 007-empty.md 008-c1.md`. The same file name in full mode (D2) was neutralised, so the claim holds only for printed-in-full records.

**Evidence:** `scripts/dev-cycle.sh:119,122,141`, `docs/reviews/execution-logs/r1-digest-final3-probe2.txt` (D1, D2)

---

## Claim 17: "prefer a capitalised "Revisit" (the trigger sentence) over an earlier "revisit-trigger verdicts" mention."

**Location:** `scripts/dev-cycle.sh:131-134`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the capitalised-first extraction; does not establish rows with two capitalised "Revisit" clauses (the first wins).

Line 133 `grep -oE 'Revisit[^|]*' <<< "$row" | head -1`, falling back to case-insensitive at 134. Test 2 asserts `log row 9 (2026-01-01): > Revisit if gizmos appear` for a row whose earlier cell says "revisit-trigger verdicts"; passes.

**Evidence:** `scripts/dev-cycle.sh:125-140`, `test/scripts/dev-cycle.bats:50-62`, `docs/reviews/execution-logs/r1-digest-final3-bats.txt`

---

## Claim 18: "`open` prints "ID  route  slug" in columns of 2+ spaces; a route can contain one space ("you: judgment"), a slug can contain "trigger"."

**Location:** `scripts/dev-cycle.sh:150-152`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the route filter and the per-route tally in test 9; does not establish slugs containing two consecutive spaces.

`awk -F'  +' '$2 == "trigger" || $2 == "deferred"'` (line 152). Test 9 (Q-001 slug "a-trigger-in-the-slug", route agent) passes and asserts "agent=1, trigger=1".

**Evidence:** `scripts/dev-cycle.sh:147-164`, `test/scripts/dev-cycle.bats:142-170`, `docs/reviews/execution-logs/r1-digest-final3-bats.txt`

---

## Claim 19: "Seeded by a hash of the date: same day, same merges; different days usually differ."

**Location:** `scripts/dev-cycle.sh:171-174`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers tests 6 and 7; does not establish the sample when `$merges` is undercounted (Claim 11).

Line 173 `seed="$(printf '%s' "$TODAY" | sha256sum | cut -c1-64)"`, line 174 `shuf -n "$SAMPLE" --random-source=<(yes "$seed")`. Tests 6 and 7 pass.

**Evidence:** `scripts/dev-cycle.sh:169-177`, `test/scripts/dev-cycle.bats:106-129`, `docs/reviews/execution-logs/r1-digest-final3-bats.txt`

---

## Claim 20: test 3 name and comment: "after a cycle record, unchanged triggers carry forward and changed ones print"; "Committed on a branch before the window, fast-forwarded into main inside it."

**Location:** `test/scripts/dev-cycle.bats:64-87`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the assertions for the four printed kinds, the edit-outside case, and the carried list; does not establish the exit status (test 3 has no `[ "$status" -eq 0 ]`) or section 1, which this scenario undercounts (Claim 11).

Lines 73-75 commit 003-late on branch `late` with dates 2020-01-03 and `git merge -q --ff-only late`; line 79 writes `Main at: $start`. The test fails under M1b and M2 and on de53069, so it would catch a revert of either half of the fix.

**Evidence:** `test/scripts/dev-cycle.bats:64-87`, `docs/reviews/execution-logs/r1-digest-final3-mutations.txt`, `docs/reviews/execution-logs/r1-digest-final3-mutations2.txt`, `docs/reviews/execution-logs/r1-digest-final3-old-de53069.txt`

---

## Claim 21: test 2: control codes in record text are not printed

**Location:** `test/scripts/dev-cycle.bats:52,60`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers ESC in a decision record's trigger text; does not establish C1 controls or stderr (Claim 7).

Line 52 writes `\033]52;c;eA==\a` into the trigger; line 60 asserts `"$output" != *$'\033'*`. Fails under M3 (filter dropped) and on de53069.

**Evidence:** `test/scripts/dev-cycle.bats:50-62`, `docs/reviews/execution-logs/r1-digest-final3-mutations.txt` (M3)

---

## Claim 22: baa46e3: "falls back to the last first-parent commit before the window when a record lacks it (commit dates alone are unreliable after a fast-forward)"

**Location:** commit baa46e3 body; code at `scripts/dev-cycle.sh:109`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what `rev-list -1 --first-parent --before` returns; does not establish that the fallback avoids the unreliability the parenthetical names (it does not — Claim 14b).

"Last first-parent commit before the window" is by committer date in walk order: probe A returned the fast-forwarded "late" commit (dated 2020), which sits after the in-window "new record" commit on the first-parent line. The fallback also fires on decorated or non-ancestor lines, not only when "a record lacks it" (Claim 10, 13). Precise version: "falls back, silently, to the newest first-parent commit whose committer date precedes the window — itself unreliable after a fast-forward."

**Evidence:** `scripts/dev-cycle.sh:109`, `docs/reviews/execution-logs/r1-digest-final3-probe1.txt` (A)

---

## Claim 23: baa46e3: "Tests: fast-forwarded old-dated record, edit outside the trigger section (still carried), recorded "Main at:" start, control codes in record text. Both fail on de53069."

**Location:** commit baa46e3 body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four listed items (in tests 3 and 2, the two tests the diff changes) and their failure on de53069; does not establish tests for F2 (no .git write), F5 (literal pathspecs, newline) — none exist, per M4/M5.

The new suite against de53069's script: "not ok 2" (line 60, ESC present) and "not ok 3" (line 82, "if new thing." not printed); the other 11 pass; exit 1.

**Evidence:** `test/scripts/dev-cycle.bats:50-87`, `docs/reviews/execution-logs/r1-digest-final3-old-de53069.txt`

---

## Claim 24: baa46e3: "Unit stays at 399 lines."

**Location:** commit baa46e3 body
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two code files' line counts at HEAD (identical to baa46e3); does not establish how the 400-line cap counts review artifacts.

`wc -l scripts/dev-cycle.sh test/scripts/dev-cycle.bats` → 187 + 212 = 399 total.

**Evidence:** `scripts/dev-cycle.sh:187`, `test/scripts/dev-cycle.bats:212`

---

## Claims Requiring Attention

### Incorrect
- **Claim 11** (`scripts/dev-cycle.sh:89-93`): `--since` stops the walk at an old-dated fast-forwarded commit; probe C printed "0 merge(s) ... 0 commit(s)" with two merges made today. Pre-existing (3aee138), but it is baa46e3's own scenario and test 3 builds it without checking section 1.
- **Claim 14b** (`scripts/dev-cycle.sh:109,114-116`): on the date fallback (missing, decorated or non-ancestor "Main at:") the base is the fast-forwarded commit itself; probe A carried a record committed today and the fast-forwarded record, both unjudged — F1 on that path.
- **Claim 16** (baa46e3 body; `scripts/dev-cycle.sh:122,141`): "a newline in a file name cannot forge a line" — only the heading is fixed; the carried-forward list printed a forged `Carried forward (9): ...` line (probe D1).

### Stale
- None.

### Mostly Accurate
- **Claim 7** (`scripts/dev-cycle.sh:40,42`): "everything printed" is C0 (minus TAB/LF) and DEL on stdout; C1 controls (U+009B passed in probe D2) and stderr are not filtered.
- **Claim 9** (`scripts/dev-cycle.sh:84`): log rows are date-selected, not compared; "window start" is the recorded commit or a date estimate.
- **Claim 12** (`scripts/dev-cycle.sh:99`): "changed since $SINCE" — the comparison is against the recorded commit, not the date.
- **Claim 13** (`scripts/dev-cycle.sh:107`): the "else by date" fallback is silent and also swallows decorated/upper-case/non-ancestor lines.
- **Claim 22** (baa46e3 body): the fallback is by committer date in walk order, which is the unreliability the same sentence names.

### Unverifiable
- None.

---

## Legibility targets

- Claim 1 — Verified — **Legibility-target:** for-orchestrator-synthesis
- Claim 2 — Verified — **Legibility-target:** for-orchestrator-synthesis
- Claim 3 — Verified — **Legibility-target:** for-orchestrator-synthesis
- Claim 4 — Verified — **Legibility-target:** for-orchestrator-synthesis
- Claim 5 — Verified — **Legibility-target:** for-orchestrator-synthesis
- Claim 6 — Verified — **Legibility-target:** for-orchestrator-synthesis
- Claim 7 — Mostly accurate — **Legibility-target:** for-author
- Claim 8 — Verified — **Legibility-target:** for-orchestrator-synthesis
- Claim 9 — Mostly accurate — **Legibility-target:** for-author
- Claim 10 — Verified — **Legibility-target:** for-orchestrator-synthesis
- Claim 11 — Incorrect — **Legibility-target:** for-author
- Claim 12 — Mostly accurate — **Legibility-target:** for-author
- Claim 13 — Mostly accurate — **Legibility-target:** for-author
- Claim 14a — Verified — **Legibility-target:** for-orchestrator-synthesis
- Claim 14b — Incorrect — **Legibility-target:** for-author
- Claim 15 — Verified — **Legibility-target:** for-orchestrator-synthesis
- Claim 16 — Incorrect — **Legibility-target:** for-author
- Claim 17 — Verified — **Legibility-target:** for-orchestrator-synthesis
- Claim 18 — Verified — **Legibility-target:** for-orchestrator-synthesis
- Claim 19 — Verified — **Legibility-target:** for-orchestrator-synthesis
- Claim 20 — Verified — **Legibility-target:** for-orchestrator-synthesis
- Claim 21 — Verified — **Legibility-target:** for-orchestrator-synthesis
- Claim 22 — Mostly accurate — **Legibility-target:** for-author
- Claim 23 — Verified — **Legibility-target:** for-orchestrator-synthesis
- Claim 24 — Verified — **Legibility-target:** for-orchestrator-synthesis

(Tally: 25 verdicts — 17 Verified, 5 Mostly accurate, 3 Incorrect.)

Fix check F1-F6: F1 holds with a verbatim ancestor "Main at:" line (14a) and fails on the silent fallback (14b); F2 holds (Claim 3); F3 holds for C0 on stdout (Claim 7, Mostly accurate); F4 holds (Claim 4); F5 holds for pathspecs (Claim 6) and the heading (Claim 15), fails for the carried list (Claim 16); F6 holds for spelling and "on this branch" (Claim 15), Window line still imprecise (Claim 9).

---

## Goal-Alignment Note

- **Success criterion:** "a markdown report saved at the output path named at the end of this prompt, structured per your skill, with a Goal-Alignment Note."
- **Answered:** Every checkable comment/header claim in scripts/dev-cycle.sh, the changed tests' names/comments, the baa46e3 message claims, and F1-F6 — each with executed verification where the claim is executable. Areas 1-7 of the brief are covered: window-start regex vs line 85 and decorated copies (Claim 10), `A && B || C` (13), fallback (14b, 22), cmp/process substitution (14a), line 99 vs code (12), output filter incl. stderr, flush and exit status (4, 7), no .git writes (3), commit-message claims (22-24), test strength by mutation (20, 21, 23).
- **Out of scope:** Whether the fallback, the Activity walk-stop or the carried-list newline should be fixed now or overridden (author/orchestrator decision); code quality; the skill unit beyond its "Main at:" template.
- **Escalate:**
  - security-reviewer: Claim 16 — a newline in a decision-record file name forges a "Carried forward" line (the agent reads that list as the set of already-judged records), and Claim 7 — C1 controls (8-bit CSI) pass the filter.
  - performance-reviewer: none.
  - api-consistency-reviewer: Claim 10/13 — the "Main at:" contract with the skill silently accepts only the undecorated form and gives no message on fallback; the digest does not say which base it used.
- **Questions / Decisions:**
  - Claim 11 is pre-existing (3aee138) but exercised by baa46e3's own scenario; the orchestrator decides whether it is in this pass's fix scope.
  - Claim 14b's reach is narrow in practice (no records exist yet; the skill template writes the line verbatim), which bears on severity but not on the verdict.
