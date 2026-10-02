Commit: baa46e3

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-digest (branch feat/dev-cycle-digest; code under review at baa46e3, identical in scripts/ and test/ to HEAD 65bd433)
**Scope:** scripts/dev-cycle.sh (187 lines) and test/scripts/dev-cycle.bats (212 lines), read whole; commit messages 4225753..baa46e3 (weight on baa46e3); fixes F1-F6 from the brief. Replicate r3 of 3.
**Checked:** 2026-09-30
**Total claims checked:** 33
**Summary:** 26 verified, 4 mostly accurate, 1 stale, 1 incorrect, 1 unverifiable

Execution logs, all under `docs/reviews/execution-logs/`:
- `r3-digest-final3-bats-head.txt`: `bats test/scripts/dev-cycle.bats`, cwd `/workspace/.claude/wt-digest`, 2026-09-30T14:05:35-07:00, exit 0 (13/13 ok).
- `r3-digest-final3-bats-on-de53069.txt`: baa46e3's tests run against de53069's script, cwd a `mktemp -d` copy, 2026-09-30T14:05:50-07:00, exit 1 (tests 2 and 3 fail).
- `r3-digest-final3-mutations.txt`: five one-line mutations of baa46e3's script with the full bats suite run against each, cwd a `mktemp -d` copy, 2026-09-30T14:08:08-07:00. The printed `bats exit=` is the exit status of the grep that filters failures (0 = a test failed, 1 = none failed). A note in the log says so.
- `r3-digest-final3-probes.txt`: `timeout 300 bash <scratchpad>/r3/probes.sh`, which runs probes P1-P11 in throwaway repos, cwd `/workspace/.claude/wt-digest`, 2026-09-30T14:07:42-07:00, exit 0.
- `r3-digest-final3-probes2.txt`: `timeout 120 bash <scratchpad>/r3/probes2.sh`, which runs probes Q1-Q3, same cwd, 2026-09-30T14:08:57-07:00, exit 0.

The probe scripts are in the session scratchpad (`/tmp/claude-1000/-workspace/21797f19-046e-4351-9c55-0471f4b3d3b6/scratchpad/r3/`). Every repo was built under `mktemp -d` and deleted afterwards. The runs started no background processes.

I checked `docs/reviews/hallucination-patterns.md`, which holds 8 entries. No claim here matches a logged pattern. The one Incorrect verdict (Claim 29) is a behavioural gap, not a fabricated symbol, so nothing is appended.

---

## Claim 1: "The dev-cycle skill (skills/dev-cycle/SKILL.md) runs the judgment steps on top of this digest."

**Location:** `scripts/dev-cycle.sh:4-5`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the existence of the named skill in the stacked unit and its use of the digest. It does not establish that this branch contains the skill: it is a forward reference until feat/dev-cycle lands, as 3aee138 says.

`/workspace/.claude/wt-devcycle/skills/dev-cycle/SKILL.md` exists. Its step 7 template begins `Main at: <sha from the digest, on its own unindented line>` (SKILL.md, "### 7. Close"). The file is absent on this branch (paraphrased — no quote available because the claim covers absence of code: `skills/dev-cycle/` does not exist in wt-digest).

**Evidence:** `scripts/dev-cycle.sh:4-5`, `/workspace/.claude/wt-devcycle/skills/dev-cycle/SKILL.md` (step 7 template)

---

## Claim 2: "steps that only prose asks for do not run (scripts/questions.sh header; Q-074)"

**Location:** `scripts/dev-cycle.sh:6`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the existence and gist of both cited sources. It does not assess the argument itself.

`scripts/questions.sh:5-8`: "this repo's own evidence is that an unenforced instruction does not execute … both because only prose asked for them." Q-074 exists in `docs/working/questions.md:67` ("The writer is still pr-prep Step 0, a workflow step that is advisory only").

**Evidence:** `scripts/questions.sh:5-8`, `docs/working/questions.md:67-72`

---

## Claim 3: "--since … Default: the date in the newest docs/working/cycles/cycle-YYYY-MM-DD.md, else 14 days ago. The digest says which." / "--sample … (default 2)"

**Location:** `scripts/dev-cycle.sh:10-13`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both defaults and the source note. It does not establish behaviour when the newest record file is unreadable; the loop tests only `-f`.

`scripts/dev-cycle.sh:23` `SAMPLE=2`. `:64-77` picks the newest non-future record date, else `date -d "$TODAY - 14 days"`, and sets `source_note`, which line 84 prints. Test 4 ("Window: since 2026-02-10 (from the last cycle record") and test 1 ("no cycle record found") pass. Command `bats test/scripts/dev-cycle.bats`, cwd wt-digest, exit 0, 2026-09-30T14:05:35-07:00.

**Evidence:** `scripts/dev-cycle.sh:23`, `scripts/dev-cycle.sh:64-77`, `test/scripts/dev-cycle.bats:37-48`, `test/scripts/dev-cycle.bats:89-96`, docs/reviews/execution-logs/r3-digest-final3-bats-head.txt

---

## Claim 4: "Read-only: writes nothing to the repo (one temp file, removed on exit)." (with F2: "No git status call, so nothing writes .git/index")

**Location:** `scripts/dev-cycle.sh:16`; commit baa46e3 message
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the whole `.git` tree (full-iso `ls -laR` listing plus a content hash of every file) across one run in a repo with a stat-dirty index, a modified tracked file, an untracked file and a Main-at record. It also covers the absence of `git status` in the script. It does not establish behaviour under user git config (the probes ran with GIT_CONFIG_GLOBAL=/dev/null), for example `core.fsmonitor` or hooks.

`grep -n status scripts/dev-cycle.sh` finds no git status call; the only matches are the word in comments and text. de53069 had `$(git status --porcelain -- "$f")` at line 111. Probe P7 output: `.git UNCHANGED` for baa46e3 and `old: .git CHANGED` for the de53069 control, so the check detects a write. The git commands the script runs are log, rev-list, rev-parse, symbolic-ref, merge-base and show, none of which refreshes the index or runs auto-gc (paraphrased — no quote available because the claim covers the absence of any writing git subcommand across the file). The temp file comes from `mktemp` (`:148`), which uses $TMPDIR, not the repo, and `trap 'rm -f "$qs_err"' EXIT` removes it.

**Evidence:** `scripts/dev-cycle.sh:148`, `scripts/dev-cycle.sh:89-118`, docs/reviews/execution-logs/r3-digest-final3-probes.txt (P7)

---

## Claim 5: "Exit: 0 digest printed; 1 bad usage, not a git repo or no default branch; a failed step exits non-zero mid-digest." (F4)

**Location:** `scripts/dev-cycle.sh:17-18`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the exit status with the stdout filter in place (P8: a failing `shuf` shim gives exit 3, sections 1-3 and the `## 4` heading printed, nothing after it) and the usage exits (test 13). It does not cover the ordering of stderr against stdout. In combined `2>&1` output, `shuf: boom` came out as line 2, ahead of every section, because stderr bypasses the `tr` filter. A reader of a combined log cannot tell from position which step failed.

`set -euo pipefail` (`:20`) with the pipeline `printf … | shuf … | sed` (`:174`) propagates shuf's status. The filter runs in a process substitution, so bash's exit status is its own: P8 recorded `exit=3`. P9 redirected output to a file 200 times and read it back as soon as bash returned; no run was short (0/200 truncated). That is an observation about this machine, not a guarantee, since bash does not wait for the `tr` substitution.

**Evidence:** `scripts/dev-cycle.sh:20`, `scripts/dev-cycle.sh:42`, `scripts/dev-cycle.sh:174`, `test/scripts/dev-cycle.bats:205-212`, docs/reviews/execution-logs/r3-digest-final3-probes.txt (P8, P9)

---

## Claim 6: "before the cd: relative paths work"

**Location:** `scripts/dev-cycle.sh:36`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers invocation by a relative path from a subdirectory (test 8). It does not cover invocation through a symlink.

`SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` runs before `cd "$ROOT"` at `:38`. Test 8, "runs from a subdirectory with a relative script path", passes.

**Evidence:** `scripts/dev-cycle.sh:36-38`, `test/scripts/dev-cycle.bats:131-140`, docs/reviews/execution-logs/r3-digest-final3-bats-head.txt

---

## Claim 7: "control characters are stripped from everything printed." (F3; baa46e3: "All output passes through one control-character filter")

**Location:** `scripts/dev-cycle.sh:40`, `scripts/dev-cycle.sh:42`; commit baa46e3 message
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers all stdout written after line 42, including the `cat "$qs_err"` at `:163` and every awk/sed/printf in the sections. It does not cover stderr, which is never filtered, or stdout written before line 42 (`--help`). LF and TAB pass by design; TAB is an accepted override.

`exec > >(LC_ALL=C tr -d '\000-\010\013-\037\177')` (`:42`) redirects stdout only. Test 2 plants `\033]52;c;eA==\a` in a record and asserts no ESC in `$output`. It passes, and fails under mutation M2 (filter removed). Probe P10 shows that stderr keeps control bytes: `Unknown option: --bogus^[X`. That message comes from before line 42, but nothing after line 42 filters stderr either (git's own error messages, for example). The precise version: "control characters are stripped from everything printed to stdout".

**Evidence:** `scripts/dev-cycle.sh:40-42`, `scripts/dev-cycle.sh:161-163`, `test/scripts/dev-cycle.bats:50-62`, docs/reviews/execution-logs/r3-digest-final3-probes.txt (P10), docs/reviews/execution-logs/r3-digest-final3-mutations.txt (M2)

---

## Claim 8: "File names are literal, not pathspecs" (F5: GIT_LITERAL_PATHSPECS=1; baa46e3: "file names are literal pathspecs")

**Location:** `scripts/dev-cycle.sh:39-41`; commit baa46e3 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the pathspec uses `git log -1 … -- "$f"` (`:118`) and `-- docs/roadmap.md` (`:181`), which are exported via `export GIT_LITERAL_PATHSPECS=1`. It does not cover `git show "$base:$f"` (`:116`), which is a rev:path, not a pathspec, though probe P5 shows `001-a:b.md` and `002-*.md` resolve and carry correctly. No test pins this: mutation M4 (export removed) passes every test.

`TODAY=…; export GIT_LITERAL_PATHSPECS=1` (`:41`). Git documents this variable as treating every pathspec literally. That comes from outside the repo and was not run for the `git log` date case (paraphrased — no quote available because the source is git's documentation, which is not in the repo).

**Evidence:** `scripts/dev-cycle.sh:41`, `scripts/dev-cycle.sh:116-118`, `scripts/dev-cycle.sh:181`, docs/reviews/execution-logs/r3-digest-final3-probes.txt (P5), docs/reviews/execution-logs/r3-digest-final3-mutations.txt (M4)

---

## Claim 9: "Pass git only a hash for the default branch … a branch named `--output=<path>` would reach `git log` as an option."

**Location:** `scripts/dev-cycle.sh:43-44`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the origin/HEAD option-name case in test 12. That test fails only when both defences are removed, an accepted override.

`MAIN_SHA` comes from `git rev-parse --verify --quiet "refs/heads/$c^{commit}"` (`:52`) and names starting with `-` are skipped (`:51`). Git calls receive `"$MAIN_SHA"` (`:89`, `:91`, `:109`). Test 12 passes.

**Evidence:** `scripts/dev-cycle.sh:45-62`, `test/scripts/dev-cycle.bats:193-203`, docs/reviews/execution-logs/r3-digest-final3-bats-head.txt

---

## Claim 10: "A repo on some other branch name: use the current branch."

**Location:** `scripts/dev-cycle.sh:56`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the fallback when neither origin/HEAD, main nor master resolves. It does not cover a detached HEAD, which exits 1 at `:62`.

`cur="$(git symbolic-ref --quiet --short HEAD …)"; if [[ -n "$cur" && "$cur" != -* ]]; then MAIN="$cur"; MAIN_SHA="$(git rev-parse --verify --quiet HEAD …)"` (`:57-60`).

**Evidence:** `scripts/dev-cycle.sh:55-62`

---

## Claim 11: "ignore future-dated"

**Location:** `scripts/dev-cycle.sh:68`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the lexical date comparison against TODAY. It does not cover malformed dates that still match the glob.

`[[ "$d" > "$last_record" && ! "$d" > "$TODAY" ]]`. Test 4 plants `cycle-9999-12-31.md`, and 2026-02-10 is still chosen.

**Evidence:** `scripts/dev-cycle.sh:64-69`, `test/scripts/dev-cycle.bats:89-93`

---

## Claim 12: "A bare date means "this time of day" to git; anchor it at midnight."

**Location:** `scripts/dev-cycle.sh:79-80`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `--since` in `git log` and `rev-list --count`, and `--before` in the fallback (`:109`). It does not cover time zones other than local.

`SINCE_TS="$SINCE 00:00:00"`. Test 5 passes.

**Evidence:** `scripts/dev-cycle.sh:79-80`, `test/scripts/dev-cycle.bats:98-104`

---

## Claim 13: Window line: "Merges: `$MAIN` at <sha>. Triggers: the working tree, compared with `$MAIN` at the window start. Questions, roadmap: the working tree." (F6; baa46e3: "Window line states exactly which sections read what")

**Location:** `scripts/dev-cycle.sh:84`; commit baa46e3 message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers what each section reads. It does not establish that "the window start" for triggers is the `since $SINCE` point the same line names: it is the recorded Main-at commit when one parses.

Two imprecisions:
- Log rows are also "triggers", but they are filtered by date from the working tree and never compared with `$MAIN` (`:130`: `if [[ $full -eq 1 || ! "$d" < "$SINCE" ]]`, in the loop `:125-140`).
- For decision records, "the window start" is `base` (`:108-109`), the Main-at sha, not midnight of `$SINCE`. In Q2, a trigger edit committed at 10:00 on the SINCE day, before the recorded sha, is carried, not printed.

The precise version: "Decision-record triggers: the working tree compared with `$MAIN` at the recorded Main-at commit (else the last commit before $SINCE); log rows: working tree, by row date."

**Evidence:** `scripts/dev-cycle.sh:84`, `scripts/dev-cycle.sh:106-140`, docs/reviews/execution-logs/r3-digest-final3-probes2.txt (Q2)

---

## Claim 14: "Main at: $MAIN_SHA (copy this line into the cycle record; the next digest compares triggers against it)"

**Location:** `scripts/dev-cycle.sh:85`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the line when copied verbatim or as `Main at: <sha>` at column 0, which is the form SKILL.md step 7 prescribes ("on its own unindented line"). It also covers 64-hex SHA-256 ids, whose 40-hex capture still resolves (Q3). It does not cover decorated copies. P1 shows `- Main at:`, `` `Main at: …` ``, `**Main at:** …`, indented, `Main at: `sha``, lower-case `main at:` and an upper-case sha all fall back to the date silently, and the digest does not say which base it used.

The regex is `sed -n 's/^Main at: \([0-9a-f]\{7,40\}\).*/\1/p'` (`:108`). The verbatim line, including the trailing parenthetical, matched and printed the fast-forwarded record in P1. The value flows to `:109` (`git merge-base --is-ancestor "$base" "$MAIN_SHA"`), then to its first use at `:116` (`git show "$base:$f"`).

**Evidence:** `scripts/dev-cycle.sh:85`, `scripts/dev-cycle.sh:106-116`, docs/reviews/execution-logs/r3-digest-final3-probes.txt (P1), docs/reviews/execution-logs/r3-digest-final3-probes2.txt (Q3)

---

## Claim 15: "Printed in full: triggers in decision records changed since $SINCE, and log rows dated on or after it. Listed by name only: the rest, whose verdict carries forward from docs/working/cycles/cycle-$last_record.md …"

**Location:** `scripts/dev-cycle.sh:99`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the decision-record half against the code at `:108-123`; the log-row half matches `:130`. It does not establish that every carried item has a prior verdict. A new record whose trigger section is empty (P3, `005-empty.md`) is listed as carried with nothing to judge.

The code compares against the commit recorded in the last cycle record, not against the date `$SINCE`, so the two disagree in both directions:
- Q2: triggers edited after `$SINCE` midnight but before the recorded sha are carried, not "changed since $SINCE".
- Test 3 and P1: an edit dated in 2020 that was fast-forwarded in the window is printed.

The mechanism, "changed since the window start", and the conclusion, that changes print and the rest carry, are right. The date wording is imprecise: "changed since the last cycle's recorded `Main at:` commit" is the precise form when that line parses.

**Evidence:** `scripts/dev-cycle.sh:96-141`, docs/reviews/execution-logs/r3-digest-final3-probes2.txt (Q2), docs/reviews/execution-logs/r3-digest-final3-probes.txt (P3)

---

## Claim 16: "Window start = the commit the last cycle recorded ("Main at:"), else by date."

**Location:** `scripts/dev-cycle.sh:107`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers these paths: a parsed ancestor sha is used (P1, test 3); a non-ancestor sha falls back (P6); no line falls back (P2); `--since` or no record means `full=1`, so `base` is never consulted. It does not establish that "by date" finds the default branch's state at the window start after a fast-forward (see Claim 17).

`[[ -n "$base" && "$source_note" != --since ]] && git merge-base --is-ancestor "$base" "$MAIN_SHA" 2>/dev/null || base="$(git rev-list -1 --first-parent --before="$SINCE_TS" "$MAIN_SHA")"` (`:109`). `A && B && C || D` runs D whenever any of A, B or C fails, which is the intended precedence. Mutation M1 (`base=""` at `:108`) fails test 3, so the test pins the recorded-start path. If the fallback finds nothing, `base` is empty and `-z "$base"` at `:116` prints everything.

**Evidence:** `scripts/dev-cycle.sh:106-116`, docs/reviews/execution-logs/r3-digest-final3-probes.txt (P1, P2, P6), docs/reviews/execution-logs/r3-digest-final3-mutations.txt (M1)

---

## Claim 17: "Changed = its trigger section differs from the default branch's copy at the window start: merged, fast-forwarded, branch-only and uncommitted all count." (with baa46e3: "That covers merges, fast-forwards, branch-only and uncommitted records"; F1)

**Location:** `scripts/dev-cycle.sh:114-115`; commit baa46e3 message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers all four cases when the last record has a parseable `Main at:` line: fast-forwarded (test 3, P1), merged with an old-dated branch commit and committed branch-only (Q1), and uncommitted (test 3, P3). It does not cover the date fallback, where a fast-forwarded old-dated record is carried unjudged.

The fallback case is P2 and P11: the record has no Main-at line, and `003-late.md` is fast-forwarded in the window with a 2020 committer date. `rev-list -1 --first-parent --before=<yesterday>` picks the fast-forwarded commit `ece86d2 2020-01-03 late` itself, and the digest prints `Carried forward (1): 003-late.md`. That is F1's original failure. The fallback will run on the first cycle after this lands, because no existing record carries the line, and on any decorated copy (Claim 14). baa46e3's message discloses the fallback, but its parenthetical, "commit dates alone are unreliable after a fast-forward", is the reason the fallback fails this case. The precise version: "… all count when the last cycle record carries a `Main at:` line; without one, a record fast-forwarded with an old commit date is carried."

A second, minor case: a new record whose trigger section is empty matches the empty output of a failing `git show` and is carried (P3).

**Evidence:** `scripts/dev-cycle.sh:106-123`, docs/reviews/execution-logs/r3-digest-final3-probes.txt (P2, P3, P11), docs/reviews/execution-logs/r3-digest-final3-probes2.txt (Q1)

---

## Claim 18: "last committed on this branch: ${d:-never, uncommitted}" (F6: one spelling; "on this branch")

**Location:** `scripts/dev-cycle.sh:119`, `scripts/dev-cycle.sh:182`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both occurrences: `git log -1 -- "$f"` reads HEAD's history, and the spelling is the same in both places. It does not cover a detached HEAD, where "this branch" means HEAD.

`grep -n uncommitted` finds `:115`, a comment, then `:119` and `:182`, both `never, uncommitted`. Q1 prints `(last committed on this branch: 2026-09-30)` for a record that exists only on `topic`.

**Evidence:** `scripts/dev-cycle.sh:118-119`, `scripts/dev-cycle.sh:181-182`, docs/reviews/execution-logs/r3-digest-final3-probes2.txt (Q1)

---

## Claim 19: "prefer a capitalised "Revisit" (the trigger sentence) over an earlier "revisit-trigger verdicts" mention."

**Location:** `scripts/dev-cycle.sh:131-132`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers rows that contain both forms (test 2). It does not cover rows with two capitalised "Revisit" clauses; the first wins.

`grep -oE 'Revisit[^|]*' … | head -1`, then a case-insensitive fallback (`:133-134`). Test 2 asserts `> Revisit if gizmos appear…end.`

**Evidence:** `scripts/dev-cycle.sh:131-135`, `test/scripts/dev-cycle.bats:55-61`

---

## Claim 20: "`open` prints "ID  route  slug" in columns of 2+ spaces; a route can contain one space ("you: judgment"), a slug can contain "trigger"."

**Location:** `scripts/dev-cycle.sh:150-151`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers questions.sh `cmd_open`'s format and the route-column split. It does not cover a slug that contains two consecutive spaces.

`printf '%s  %-14s  %s\n' "$id" "$route" "$slug"` (`scripts/questions.sh:412`). The digest splits with `awk -F'  +'`. Test 9 passes; its slug contains "trigger".

**Evidence:** `scripts/questions.sh:408-414`, `scripts/dev-cycle.sh:152`, `test/scripts/dev-cycle.bats:142-170`

---

## Claim 21: "Seeded by a hash of the date: same day, same merges; different days usually differ."

**Location:** `scripts/dev-cycle.sh:171-172`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the determinism and variation that tests 6 and 7 assert. It does not quantify "usually".

`seed="$(printf '%s' "$TODAY" | sha256sum | cut -c1-64)"`, then `shuf --random-source=<(yes "$seed")`. Tests 6 and 7 pass.

**Evidence:** `scripts/dev-cycle.sh:170-177`, `test/scripts/dev-cycle.bats:106-129`

---

## Claim 22: "Each test builds a throwaway repo under $BATS_TEST_TMPDIR; this repo is untouched." / "HOME in the temp dir: the ~/.claude/scripts fallback can't reach the real one."

**Location:** `test/scripts/dev-cycle.bats:3-4`, `test/scripts/dev-cycle.bats:14`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers setup and every test body. Test 8 copies `scripts/` out and never writes to it.

`R="$BATS_TEST_TMPDIR/repo"; make_repo "$R" main; cd "$R"` (`:17-19`); `export HOME="$BATS_TEST_TMPDIR/home"` (`:15`). No test writes under `$REPO_ROOT` (paraphrased — no quote available because the claim covers the absence of any write to `$REPO_ROOT` across all 13 test bodies).

**Evidence:** `test/scripts/dev-cycle.bats:8-35`, `test/scripts/dev-cycle.bats:131-140`

---

## Claim 23: Test 2 "lists a decision record's revisit triggers and a log row's whole revisit clause" (now with control codes in record text)

**Location:** `test/scripts/dev-cycle.bats:50-62`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the heading, section text, exclusion of text outside the section, ESC stripping, and the whole log clause. It does not cover BEL or other control bytes on their own: only `\033` is asserted, though `tr` removes BEL too.

The test passes at baa46e3. It fails against de53069's script at `:60` and under mutation M2.

**Evidence:** `test/scripts/dev-cycle.bats:50-62`, docs/reviews/execution-logs/r3-digest-final3-bats-on-de53069.txt, docs/reviews/execution-logs/r3-digest-final3-mutations.txt (M2)

---

## Claim 24: Test 3 "after a cycle record, unchanged triggers carry forward and changed ones print"; comment "Committed on a branch before the window, fast-forwarded into main inside it."

**Location:** `test/scripts/dev-cycle.bats:64-87`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the recorded-Main-at start, the fast-forward, an edit outside the section and an uncommitted record. It does not cover the no-Main-at fallback (Claim 17) or a newline in a carried file name (Claim 29).

`git merge -q --ff-only late` (`:75`) runs today, inside the window from yesterday, on a 2020-dated commit, so the comment holds. The test fails on de53069 (`not printed in full: if new thing.`), under M1 (Main-at ignored) and under M3 (whole-file compare: `if old thing.` printed).

**Evidence:** `test/scripts/dev-cycle.bats:64-87`, docs/reviews/execution-logs/r3-digest-final3-bats-on-de53069.txt, docs/reviews/execution-logs/r3-digest-final3-mutations.txt (M1, M3)

---

## Claim 25: "All commits here are from today, before "now": a midnight window counts all." / "No questions-archive.md: questions.sh open exits non-zero."

**Location:** `test/scripts/dev-cycle.bats:100`, `test/scripts/dev-cycle.bats:175`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both test premises as they hold when the tests run. Test 5's premise does not hold if the suite runs across midnight.

`make_repo` commits with no date override (`:22-35`). `cmd_open` calls `require_files` (`scripts/questions.sh:409`). Tests 5 and 10 pass.

**Evidence:** `test/scripts/dev-cycle.bats:22-35`, `test/scripts/dev-cycle.bats:98-104`, `test/scripts/dev-cycle.bats:172-181`, `scripts/questions.sh:408-410`

---

## Claim 26: "ignores edits elsewhere in the file (which also resolves the deferred file-level cost, performance Medium)"

**Location:** commit baa46e3 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the behavioural half: a `## Other` edit is carried in test 3, and M3 fails. It does not assess the performance half, which I route to performance-reviewer: the loop still runs one `git show` and two awk per record.

`cmp -s <(git show "$base:$f" 2>/dev/null | trig) <(trig < "$f")` (`:116`). `trig` prints only non-blank lines between `## Revisit triggers` and the next `## ` (`:106`).

**Evidence:** `scripts/dev-cycle.sh:106`, `scripts/dev-cycle.sh:116`, docs/reviews/execution-logs/r3-digest-final3-mutations.txt (M3)

---

## Claim 27: "falls back to the last first-parent commit before the window when a record lacks it (commit dates alone are unreliable after a fast-forward)"

**Location:** commit baa46e3 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the fallback's mechanism (`rev-list -1 --first-parent --before`) and its trigger (a missing, non-ancestor or unparseable line). It does not establish that the fallback survives a fast-forward. P11 shows it does not (Claim 17), which is consistent with the parenthetical.

`base="$(git rev-list -1 --first-parent --before="$SINCE_TS" "$MAIN_SHA")"` (`:109`). P11 prints `fallback base: ece86d2` for the fast-forwarded 2020-dated commit.

**Evidence:** `scripts/dev-cycle.sh:109`, docs/reviews/execution-logs/r3-digest-final3-probes.txt (P11)

---

## Claim 28: "the digest prints a "Main at: <sha>" line for the record"; "The skill must copy the "Main at:" line into each cycle record (stacked unit)."

**Location:** commit baa46e3 message
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the producer (`:85`) and the consumer template in the stacked SKILL.md. It does not establish that an agent following the skill writes the line undecorated; see Claim 14 for which forms parse.

`echo "Main at: $MAIN_SHA (copy this line …)"` (`:85`). SKILL.md step 7: "keeping a single `Main at:` line" and the template "Main at: <sha from the digest, on its own unindented line>".

**Evidence:** `scripts/dev-cycle.sh:85`, `/workspace/.claude/wt-devcycle/skills/dev-cycle/SKILL.md` (step 7)

---

## Claim 29: "a newline in a file name cannot forge a line" (F5)

**Location:** commit baa46e3 message; code at `scripts/dev-cycle.sh:119`, `scripts/dev-cycle.sh:122`, `scripts/dev-cycle.sh:141`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers every place a decision-record file name is printed. The newline is replaced only in the `###` heading of a printed record. It does not cover log rows, which are read line by line and cannot hold a newline.

The replacement is only in the heading: `echo "### ${f//$'\n'/ } (last committed on this branch: …)"` (`:119`). The carried branch stores the raw name, `carried+=("${f#docs/decisions/}")` (`:122`), and prints it with `printf '\nCarried forward (%s): %s\n' "${#carried[@]}" "${carried[*]}"` (`:141`). The `tr` filter keeps `\n` (`\012` is outside `\000-\010\013-\037`). P4 commits `001-a\n### FORGED heading.md` unchanged since the recorded start, and the digest prints:

```
Carried forward (1): 001-a$
### FORGED heading.md$
```

That is a forged `###` heading line in section 2, which is the case F5 said was closed. To fix it, apply the same replacement at `:122`.

**Evidence:** `scripts/dev-cycle.sh:119-122`, `scripts/dev-cycle.sh:141`, docs/reviews/execution-logs/r3-digest-final3-probes.txt (P4)

---

## Claim 30: "Tests: fast-forwarded old-dated record, edit outside the trigger section (still carried), recorded "Main at:" start, control codes in record text. Both fail on de53069. Unit stays at 399 lines."

**Location:** commit baa46e3 message
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the four cases, which are extensions of two existing tests (2 and 3), not new tests; the count stays at 13. It also covers "Both fail on de53069" and the line count. The F5 newline and GIT_LITERAL_PATHSPECS fixes have no test: M4 and M5 pass the whole suite.

`git diff de53069 baa46e3 -- test/scripts/dev-cycle.bats` changes only tests 2 and 3. Against de53069's script both fail and the other 11 pass. `wc -l`: 187 + 212 = 399.

**Evidence:** `test/scripts/dev-cycle.bats:50-87`, docs/reviews/execution-logs/r3-digest-final3-bats-on-de53069.txt, docs/reviews/execution-logs/r3-digest-final3-mutations.txt (M4, M5)

---

## Claim 31: "test/scripts/dev-cycle.bats: 13 hermetic tests"

**Location:** commit 3aee138 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the count at 3aee138 and at baa46e3. For hermeticity, see Claim 22.

`grep -c '^@test'` returns 13 at 83e7895 and 13 at HEAD.

**Evidence:** `test/scripts/dev-cycle.bats:37-212`

---

## Claim 32: "Uncommitted files show "never: uncommitted", not an empty date." and "A decision record now counts as changed when it entered the default branch in the window (first-parent history …)"

**Location:** commit 83e7895 message
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers these two 83e7895 statements against the code as it is now. Both were accurate at 83e7895 and were superseded by baa46e3. No action is needed beyond not quoting 83e7895 as the current contract.

At 83e7895: `echo "### $f (last committed ${d:-never: uncommitted})"` (line 115) and `never (uncommitted)` (line 181). Now both read `never, uncommitted` (`:119`, `:182`). The changed-test is now the section comparison at `:116`, not first-parent history.

**Evidence:** `scripts/dev-cycle.sh:116-119`, `scripts/dev-cycle.sh:182`

---

## Claim 33: "the deferred file-level cost, performance Medium" is resolved

**Location:** commit baa46e3 message
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers nothing beyond noting that the per-record cost is now one `git show` plus two awk pipelines. It does not establish whether that meets the performance reviewer's earlier finding, which lives in a report I did not verdict.

To verify, the performance-reviewer should compare the cost with the Medium finding in the final-pass-1 report and time a run with about 100 records.

**Evidence:** `scripts/dev-cycle.sh:110-124`

---

## Claims Requiring Attention

### Incorrect
- **Claim 29** (`scripts/dev-cycle.sh:122`, `:141`; baa46e3 message, F5): a newline in a *carried* record's file name still forges a line, e.g. `### FORGED heading.md` in P4. Apply `${f//$'\n'/ }` at `:122` too.

### Stale
- **Claim 32** (83e7895 message): the "never: uncommitted" spelling and the first-parent changed-test were superseded by baa46e3. The message is historical, so no fix is needed.

### Mostly Accurate
- **Claim 7** (`scripts/dev-cycle.sh:40`, `:42`; baa46e3 "All output"): only stdout is filtered, not stderr. Say "everything printed to stdout".
- **Claim 13** (`scripts/dev-cycle.sh:84`): log rows are filtered by date, not "compared with `$MAIN`"; the trigger "window start" is the recorded sha, not $SINCE midnight.
- **Claim 15** (`scripts/dev-cycle.sh:99`): "changed since $SINCE" is really "changed since the recorded Main-at commit". Q2 shows the two disagree.
- **Claim 17** (`scripts/dev-cycle.sh:114-115`; baa46e3 "covers … fast-forwards"): this holds only when the last record has a parseable `Main at:` line. Under the date fallback, which the first cycle after landing will use, a fast-forwarded old-dated record is carried unjudged (P2, P11).

### Unverifiable
- **Claim 33** (baa46e3 message): the performance resolution needs the performance-reviewer's baseline and a timed run.

---

## Goal-Alignment Note

- **Success criterion (verbatim from the brief):** "a markdown report saved at the output path named at the end of this prompt, structured per your skill, with a Goal-Alignment Note."
- **Answered:** yes. Every comment and header claim in scripts/dev-cycle.sh, the test names and comments, the 4225753..baa46e3 commit messages and F1-F6 carry a verdict:
  - F2, F4 and F6 hold (Claims 4, 5, 18).
  - F3 holds for stdout (Claim 7).
  - F1 holds only when a parseable `Main at:` line exists (Claims 14, 16, 17).
  - F5 is half fixed: literal pathspecs hold, the newline fix does not (Claims 8, 29).
  - The new test assertions fail on de53069 and under the matching mutations (Claims 23, 24, 30).
- **Out of scope:** whether the design (a recorded sha rather than a date) is the right one; the SKILL.md wording beyond its template line; code quality.
- **Escalate:**
  - **api-consistency-reviewer:** the `Main at:` contract between the digest (`:85`) and the skill template is parsed by an exact-prefix regex. Any markdown decoration, and an upper-case sha, falls back silently to the date base, and the digest never says which base it used (P1). The first cycle after landing will always hit the fallback, because no existing record has the line (Claim 17).
  - **security-reviewer:** the carried-list line forgery (Claim 29). Control output also goes unfiltered on stderr (Claim 7), though no repo-derived text currently reaches stderr after line 42.
  - **performance-reviewer:** Claim 33 (per-record `git show` cost versus the deferred Medium).
- **Questions:** should the digest print which base it compared against (recorded sha vs date fallback), so a silent fallback is visible to the agent judging the triggers?
