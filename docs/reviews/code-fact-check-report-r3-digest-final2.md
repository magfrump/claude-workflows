Commit: de53069

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-digest (branch feat/dev-cycle-digest)
**Scope:** `git diff main...HEAD -- scripts test` (scripts/dev-cycle.sh, test/scripts/dev-cycle.bats) plus commit messages `git log main..HEAD` (3aee138, 83e7895); final confirming pass 2, replicate r3
**Checked:** 2026-09-29
**Total claims checked:** 23
**Summary:** 18 verified, 4 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

Hallucination pattern log read (`docs/reviews/hallucination-patterns.md`). The closest logged family is test-count claims in commit messages (e.g. "mode1-equiv 33 claimed … but holds 25"). I checked this unit's counts (13 tests, 396 and 400 lines) against it, and they hold.

Execution provenance used by several claims below:
- **E1 (bats):** `timeout 300 bats test/scripts/dev-cycle.bats`, cwd `/workspace/.claude/wt-digest`, exit 0, 2026-09-29T02:37:52-07:00. Output: `docs/reviews/execution-logs/r3-digest-final2-bats.txt` (13/13 ok).
- **E2 (probes):** `bash probe.txt > probe-out.txt 2>&1`, cwd `/tmp/claude-1000/-workspace/fba1bfc0-301f-41fe-8500-89690af4d400/scratchpad/r3` (throwaway repos p1–p11), exit 0, finished 2026-09-29T02:37:36-07:00. Script: `docs/reviews/execution-logs/r3-digest-final2-probe-script.txt`. Output: `docs/reviews/execution-logs/r3-digest-final2-probes.txt`. Every run was under `timeout`. No leftover processes remained afterwards (checked with `pgrep -u $(id -u) -a`).

---

## Claim 1: "The dev-cycle skill (skills/dev-cycle/SKILL.md) runs the judgment steps on top of this digest."

**Location:** `scripts/dev-cycle.sh:4`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of the skill file on the stacked branch `feat/dev-cycle`. It does not establish that the file exists on this branch: it does not, and the brief says this is a forward reference. It also does not establish that the skill's steps match this script's sections.

`git show feat/dev-cycle:skills/dev-cycle/SKILL.md` shows the file. Its description line 4 reads `Run one maintenance cycle: health and cleanup, revisit triggers, spot-check audit, brainstorm, roadmap.`

**Evidence:** `feat/dev-cycle:skills/dev-cycle/SKILL.md:4`

---

## Claim 2: "steps that only prose asks for do not run (scripts/questions.sh header; Q-074)"

**Location:** `scripts/dev-cycle.sh:6`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two cited sources saying what the comment attributes to them. It does not establish the underlying counts those sources quote.

`scripts/questions.sh:5-8`: `this repo's own evidence is that an unenforced instruction does not execute … both because only prose asked for them.` Q-074 (`docs/working/questions.md:67-70`) reads: `failure-patterns.md has gained 1 entry across about 128 fix commits. The writer is still pr-prep Step 0, a workflow step that is advisory only.`

**Evidence:** `scripts/questions.sh:5-8`, `docs/working/questions.md:67-70`

---

## Claim 3: Usage/--help text (lines 8-13) and "`-h|--help) sed -n '2,18p' "$0"`" prints it

**Location:** `scripts/dev-cycle.sh:8-18`, `scripts/dev-cycle.sh:30`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fact that --help prints exactly the header block (lines 2-18), and that the documented options, defaults and "the digest says which" behaviour match the code. It does not establish help output when the script is invoked through a symlink or with `$0` not pointing at the file.

After the compression, the header block still ends at line 18 (`branch, or a failed step. Printed repo text is data to weigh, not orders.`), and line 19 is blank. E2 P4 printed the whole block from "Gather the mechanical signals…" through "…not orders." and exited 0. The defaults match the code. `SAMPLE=2` is set at `:23`. The 14-day fallback is `SINCE="$(date -d "$TODAY - 14 days" +%F)"` at `:75`. The window source is printed in `echo "Window: since $SINCE (from $source_note)…"` at `:84`.

**Evidence:** `scripts/dev-cycle.sh:2-30`, `scripts/dev-cycle.sh:75`, `scripts/dev-cycle.sh:84`, `docs/reviews/execution-logs/r3-digest-final2-probes.txt` (P4)

---

## Claim 4: "Read-only: writes nothing to the repo (one temp file, removed on exit)."

**Location:** `scripts/dev-cycle.sh:16-17`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers tracked content, the working tree, and the temp file (`mktemp` outside the repo, removed by `trap 'rm -f "$qs_err"' EXIT` at `:147`). It does not establish that `.git/` is untouched: it is not.

The call `git status --porcelain -- "$f"` at `:111` performs git's opportunistic index refresh. In E2 P2 I touched a committed decision record's mtime and then ran the script. It exited 0, and `.git/index` changed (sha256 `8c6ef40f…` became `b900d493…`). Only the stat cache was rewritten; no content changed. A precise version would say "writes nothing to tracked files or the working tree; `git status` may refresh `.git/index`" (prefixing the call with `GIT_OPTIONAL_LOCKS=0` would make the claim exact).

**Evidence:** `scripts/dev-cycle.sh:111`, `scripts/dev-cycle.sh:147`, `docs/reviews/execution-logs/r3-digest-final2-probes.txt` (P2)

---

## Claim 5: "Exit: 0 digest printed; 1 bad usage, not a git repo, no default branch, or a failed step."

**Location:** `scripts/dev-cycle.sh:17-18`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exit 0 on success and exit 1 for bad usage, a missing `--since` argument and an invalid date (all `exit 1` or `${2:?}`). It does not establish that a failed step exits 1: a failed step exits with the failing command's own status, after a partial digest has already reached stdout.

Under `set -euo pipefail` (`:20`), a failing command propagates its own status. In E2 P3 I made `docs/roadmap.md` unreadable. The awk at `:183` failed with `awk: cannot open docs/roadmap.md (Permission denied)`, and the script exited **2**, not 1, after printing sections 1-5 up to the roadmap heading. E2 P6 confirms that `--since` with no value exits 1 (`line 26: 2: --since needs a date`). A precise version would say "1 on bad usage, not a git repo or no default branch; non-zero (the failing command's status) on a failed step."

**Evidence:** `scripts/dev-cycle.sh:20`, `scripts/dev-cycle.sh:26`, `scripts/dev-cycle.sh:183`, `docs/reviews/execution-logs/r3-digest-final2-probes.txt` (P3, P6)

---

## Claim 6: "Pass git only a hash for the default branch: … a branch named `--output=<path>` would reach `git log` as an option."

**Location:** `scripts/dev-cycle.sh:43-44`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the resolution loop (`:45-62`): it skips names starting with `-`, resolves through `refs/heads/$c^{commit}`, and every later git call receives `$MAIN_SHA`. It does not establish the display-only uses of `$MAIN` in echo text (not an injection vector for git).

The loop reads `[[ "$c" == -* ]] && continue` and `sha="$(git rev-parse --verify --quiet "refs/heads/$c^{commit}" …)"` (`:51-52`). Every later git call takes `"$MAIN_SHA"`: lines `:88`, `:90` and `:111`. E1 test 12 ("an origin/HEAD naming an option-like branch cannot make git write a file") passes.

**Evidence:** `scripts/dev-cycle.sh:45-62`, `scripts/dev-cycle.sh:88-111`, `test/scripts/dev-cycle.bats:191-201`, `docs/reviews/execution-logs/r3-digest-final2-bats.txt`

---

## Claim 7: "ignore future-dated" (cycle records)

**Location:** `scripts/dev-cycle.sh:68`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rule that records dated after `$TODAY` are skipped and a record dated today is kept (`! "$d" > "$TODAY"`). It does not establish handling of an impossible past date in a record name (e.g. `cycle-2026-02-30.md`). The glob accepts such a name, and the script then rejects it with the `--since must be a real … date` message even though no `--since` was given.

The code is `[[ "$d" > "$last_record" && ! "$d" > "$TODAY" ]] && last_record="$d"`. E1 test 4 includes `cycle-9999-12-31.md` and still asserts `Window: since 2026-02-10`; it passes.

**Evidence:** `scripts/dev-cycle.sh:65-69`, `scripts/dev-cycle.sh:78`, `test/scripts/dev-cycle.bats:87-94`, `docs/reviews/execution-logs/r3-digest-final2-bats.txt`

---

## Claim 8: "A bare date means "this time of day" to git; anchor it at midnight."

**Location:** `scripts/dev-cycle.sh:79-80`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fact that every `--since` passed to git uses `SINCE_TS="$SINCE 00:00:00"`. It does not establish timezone behaviour across DST changes.

`SINCE_TS` is used at `:88`, `:90` and `:111`; the bare `$SINCE` goes only to the string comparison at `:126` and to display. E1 test 5 passes: a commit at 00:00:30 today is counted.

**Evidence:** `scripts/dev-cycle.sh:80-111`, `test/scripts/dev-cycle.bats:96-102`, `docs/reviews/execution-logs/r3-digest-final2-bats.txt`

---

## Claim 9: Window line "Merges and commits: `$MAIN` at …; triggers, questions and roadmap: the working tree." (83e7895: "Window line states which sections read the default branch and which the working tree")

**Location:** `scripts/dev-cycle.sh:84`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the content sources: merge and commit counts come from `$MAIN_SHA`, and trigger text, questions and roadmap text come from working-tree files. It does not establish two things. First, section 2's printed-in-full vs carried-forward split, which reads the default branch's history (`git log … "$MAIN_SHA" -- "$f"`, `:111`) as well as the working tree. Second, the "last committed" dates, which read the current HEAD's history.

The "last committed" dates come from `d="$(git log -1 --format=%ad --date=short -- "$f")"` (`:114`) and from the roadmap equivalent (`:180`). Neither passes a revision, so both read HEAD, which may not be the default branch or the working tree. The line needs the qualifier "triggers are selected by the default branch's history."

**Evidence:** `scripts/dev-cycle.sh:84`, `scripts/dev-cycle.sh:111`, `scripts/dev-cycle.sh:114`, `scripts/dev-cycle.sh:180`

---

## Claim 10: "control characters stripped from merge subjects" (83e7895)

**Location:** `scripts/dev-cycle.sh:88`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stripping of C0 controls except TAB and LF, plus DEL, from the merge list printed in section 1 and sampled in section 4. It does not establish stripping of the other printed repo text: record, log-row and roadmap text is quoted with "> ", not filtered.

The filter is `tr -d '\000-\010\013-\037\177'`. In E2 P9 the subject `merge: \033[31mred\033[0m\ttab` came out as `merge: [31mred[0m\ttab` (per the `od -c` output): ESC is removed and the tab is kept.

**Evidence:** `scripts/dev-cycle.sh:88`, `docs/reviews/execution-logs/r3-digest-final2-probes.txt` (P9)

---

## Claim 11: "Merge list: `sed -n '1,30p'` instead of `head -30`, which hit SIGPIPE under pipefail past ~64 KB of merges and exited 141 mid-digest." (83e7895)

**Location:** `scripts/dev-cycle.sh:93`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pipeline behaviour: `sed -n '1,30p'` consumes all its input, so the writer never gets SIGPIPE, whereas `head -30` does. It does not establish a 64 KB+ merge list running end to end through the script (not run; deferred as "SIGPIPE fix untested").

The line now reads `printf '%s\n' "$merges" | sed -n '1,30p'`. In E2 P7, under `set -o pipefail` with 300,000 lines of input, the sed pipeline exited `sed=0` and the head pipeline exited `head=141`.

**Evidence:** `scripts/dev-cycle.sh:93`, `docs/reviews/execution-logs/r3-digest-final2-probes.txt` (P7)

---

## Claim 12: "Changed = merged into the default branch in the window (first-parent, so a branch commit dated earlier counts at its merge), or uncommitted here."

**Location:** `scripts/dev-cycle.sh:109-111`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers merge-commit (`--no-ff`) integration and uncommitted files: with `--first-parent`, the merge commit is diffed against its first parent and dated by its own commit time. It does not establish the fast-forward case. With no merge commit, a branch commit whose committer date is before the window is still carried forward (see Claim 19).

The code is `changed="$(git log -1 --first-parent --since="$SINCE_TS" --format=%h "$MAIN_SHA" -- "$f" 2>/dev/null)$(git status --porcelain -- "$f")"`. E1 test 3 passes: `003-late.md`, committed on a branch in 2020 and merged `--no-ff` today, prints in full, and `004-wip.md` (uncommitted) prints in full. In E2 P1, a 2020-dated branch commit that was fast-forwarded onto main today was listed as `Carried forward (1): 005-ff.md`. The comment's wording ("counts at its merge") is exact for merge commits, so the claim as written is Verified.

**Evidence:** `scripts/dev-cycle.sh:109-119`, `test/scripts/dev-cycle.bats:64-85`, `docs/reviews/execution-logs/r3-digest-final2-bats.txt`, `docs/reviews/execution-logs/r3-digest-final2-probes.txt` (P1)

---

## Claim 13: "Uncommitted files show "never: uncommitted", not an empty date." (83e7895)

**Location:** `scripts/dev-cycle.sh:114-115`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers decision-record headings. It does not establish the roadmap line, which uses different wording: `${d:-never (uncommitted)}` at `:181`.

The heading is built as `echo "### $f (last committed ${d:-never: uncommitted})"`. E2 P8 printed `### docs/decisions/001-a.md (last committed never: uncommitted)`.

**Evidence:** `scripts/dev-cycle.sh:114-115`, `docs/reviews/execution-logs/r3-digest-final2-probes.txt` (P8)

---

## Claim 14: "The whole clause to the cell's end; prefer a capitalised "Revisit" (the trigger sentence) over an earlier "revisit-trigger verdicts" mention."

**Location:** `scripts/dev-cycle.sh:127-130`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the case-sensitive-first match (`grep -oE 'Revisit[^|]*'`), which runs to the next `|`, with a case-insensitive fallback. It does not establish rows whose earlier cell also contains a capitalised "Revisit".

E1 test 2 passes. The row there contains `revisit-trigger verdicts` before `Revisit if gizmos appear <500 x> end.`, and the output holds the full clause through ` end. `.

**Evidence:** `scripts/dev-cycle.sh:127-131`, `test/scripts/dev-cycle.bats:50-62`, `docs/reviews/execution-logs/r3-digest-final2-bats.txt`

---

## Claim 15: "`open` prints "ID  route  slug" in columns of 2+ spaces; a route can contain one space ("you: judgment"), a slug can contain "trigger"."

**Location:** `scripts/dev-cycle.sh:149-151`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers questions.sh's current output format and the awk split on `  +`. It does not establish routes longer than 14 characters (none exist in the route set at `scripts/questions.sh:21-25`).

`scripts/questions.sh:412`: `printf '%s  %-14s  %s\n' "$id" "$route" "$slug"`. The longest route, `you: judgment` or `you: terminal`, is 13 characters and so is padded to 14, which keeps the fixed two-space separator. E1 test 9 passes: the slug `a-trigger-in-the-slug` is not listed, and the output reads `agent=1, trigger=1`.

**Evidence:** `scripts/questions.sh:408-414`, `scripts/dev-cycle.sh:151-158`, `test/scripts/dev-cycle.bats:140-168`, `docs/reviews/execution-logs/r3-digest-final2-bats.txt`

---

## Claim 16: "Seeded by a hash of the date: same day, same merges; different days usually differ."

**Location:** `scripts/dev-cycle.sh:170-173`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers determinism for the same `$TODAY` and merge list, and variation across four sample dates on a 20-merge repo. It does not establish the parenthetical claim that the raw date "seeded almost nothing" (historical rationale, not re-run).

The code is `seed="$(printf '%s' "$TODAY" | sha256sum | cut -c1-64)"` followed by `shuf -n "$SAMPLE" --random-source=<(yes "$seed")`. E1 tests 6 and 7 pass.

**Evidence:** `scripts/dev-cycle.sh:170-173`, `test/scripts/dev-cycle.bats:104-127`, `docs/reviews/execution-logs/r3-digest-final2-bats.txt`

---

## Claim 17: "Each test builds a throwaway repo under $BATS_TEST_TMPDIR; this repo is untouched."

**Location:** `test/scripts/dev-cycle.bats:3-4`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the fact that every test works in `$BATS_TEST_TMPDIR`, with global and system git config and HOME redirected. It does not establish anything beyond the one read of this repo: test 8 reads `$REPO_ROOT/scripts` via `cp -r` into the temp dir, without writing to it.

`setup()` exports `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1` and `HOME="$BATS_TEST_TMPDIR/home"`, and runs `make_repo "$R" main; cd "$R"` (`:11-19`). The victim file in test 12 is also under `$BATS_TEST_TMPDIR` (`:192`). After E1, `git status --porcelain` in the worktree showed only my own untracked review artifacts.

**Evidence:** `test/scripts/dev-cycle.bats:8-20`, `test/scripts/dev-cycle.bats:129-138`, `test/scripts/dev-cycle.bats:191-201`

---

## Claim 18: "Committed on a branch before the window, merged into main inside it."

**Location:** `test/scripts/dev-cycle.bats:71-74`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the test's setup matching its comment. It does not establish the fast-forward variant, which this test does not exercise.

The setup is `GIT_COMMITTER_DATE="2020-01-03T12:00:00" git commit … -m late`, then `git merge -q --no-ff late -m "merge: late"` on main. The merge is dated now, and the window starts yesterday (`cycle-$(date -d yesterday +%F).md`, `:77`).

**Evidence:** `test/scripts/dev-cycle.bats:71-77`

---

## Claim 19: "A decision record now counts as changed when it entered the default branch in the window (first-parent history, so a branch commit dated earlier counts at its merge) or is uncommitted" (83e7895 message)

**Location:** `scripts/dev-cycle.sh:111`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mechanism, which is right for merge commits, and the uncommitted case. It does not establish the stated conclusion, "entered the default branch in the window", for fast-forward integration, where that conclusion fails.

The mechanism is right: see Claim 12 and E1 test 3. The conclusion needs the qualifier "via a merge commit". In E2 P1, a record committed on a branch in 2020 and fast-forwarded (`git merge --ff-only`) onto main today was reported as `Carried forward (1): 005-ff.md` even though it entered main in the window. This repo's merges are `--no-ff` (pr-prep's local-merge path), so the gap only reaches other projects that use the installed copy (`:15-16`: "so the installed copy serves any project"). Git keeps no record of when a fast-forward happened apart from the reflog.

**Evidence:** `scripts/dev-cycle.sh:111`, `scripts/dev-cycle.sh:15-16`, `docs/reviews/execution-logs/r3-digest-final2-probes.txt` (P1), `docs/reviews/execution-logs/r3-digest-final2-bats.txt`

---

## Claim 20: "Explicit --since says so …; --since must be a real date; DEV_CYCLE_TODAY pins the default window too; --sample=0 message; … future-dated cycle records ignored." (83e7895)

**Location:** `scripts/dev-cycle.sh:75-78`, `scripts/dev-cycle.sh:101`, `scripts/dev-cycle.sh:175`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed behaviour as observed. It does not establish behaviour when DEV_CYCLE_TODAY itself is malformed: `date -d` at `:75` then fails under `set -e` with no script-level message.

- **Explicit --since:** E1 test 4 asserts `An explicit --since was given, so every trigger`.
- **Real date:** E1 test 13 asserts that `--since=2026-13-45` exits 1.
- **DEV_CYCLE_TODAY:** in E2 P10, `DEV_CYCLE_TODAY=2026-01-20` gave `Window: since 2026-01-06`.
- **--sample=0:** E2 P11 printed `Sample size 0: no spot-check requested.`
- **Future-dated records:** see Claim 7.

**Evidence:** `scripts/dev-cycle.sh:75-78`, `scripts/dev-cycle.sh:101`, `scripts/dev-cycle.sh:175`, `docs/reviews/execution-logs/r3-digest-final2-bats.txt`, `docs/reviews/execution-logs/r3-digest-final2-probes.txt` (P10, P11)

---

## Claim 21: "Tests extended: branch-merged, uncommitted and SINCE-dated items print in full; capitalised "Revisit" preferred; explicit --since sentence; invalid date rejected. … within the 400-line unit cap (396)." (83e7895)

**Location:** `test/scripts/dev-cycle.bats:50-94`, `test/scripts/dev-cycle.bats:203-210`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named test's presence and its pass in E1, and the line count. It does not establish that the new tests fail on 3aee138 (not run).

The named tests map as follows:
- Branch-merged, uncommitted and SINCE-dated items: test 3 (`if late thing.`, `if uncommitted thing.`, and the log row dated yesterday, `Revisit if boundary.`).
- Capitalised "Revisit": test 2.
- Explicit --since sentence: test 4.
- Invalid date: test 13.

`git diff --stat main...HEAD -- scripts test` reports `396 insertions(+)`: 186 lines in the script and 210 in the tests.

**Evidence:** `test/scripts/dev-cycle.bats:50-94`, `test/scripts/dev-cycle.bats:203-210`, `docs/reviews/execution-logs/r3-digest-final2-bats.txt`

---

## Claim 22a: "test/scripts/dev-cycle.bats: 13 hermetic tests" and "this unit is 400" (3aee138)

**Location:** `test/scripts/dev-cycle.bats:37-210`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test count at HEAD (E1: `1..13`) and the 400-line figure at 3aee138. It does not establish the regression-failure claim (Claim 22b).

There are 13 `@test` blocks, and E1 reports `1..13`. `git diff --numstat main...3aee138 -- ':(top)' ':(top,exclude)docs/'` gives `198` and `202`, which sum to 400.

**Evidence:** `test/scripts/dev-cycle.bats:37-210`, `docs/reviews/execution-logs/r3-digest-final2-bats.txt`

---

## Claim 22b: "the regression tests fail on the pre-review version (89a3d3b)" (3aee138)

**Location:** `test/scripts/dev-cycle.bats:1`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing beyond the claim's existence. Establishing it would mean running the suite against 89a3d3b's script, which this pass did not do.

This is an executable guarantee, so the mandatory-execution rule caps a static reading at Unverifiable. Blocker: execution was not attempted in this pass. The claim is historical and was already in scope for earlier passes, and the brief does not re-open it. Verifying it needs `git show 89a3d3b:scripts/dev-cycle.sh` run under the current bats file in a throwaway directory (paraphrased — no quote available because the claim concerns an unrun historical execution, not a line of code).

**Evidence:** `test/scripts/dev-cycle.bats:1`

---

## Claims Requiring Attention

### Incorrect
- (none)

### Stale
- (none)

### Mostly Accurate
- **Claim 4** (`scripts/dev-cycle.sh:16-17`): "writes nothing to the repo". `git status --porcelain` (`:111`) can rewrite `.git/index` (observed). The claim should read "no tracked or working-tree writes", or the call should use `GIT_OPTIONAL_LOCKS=0`.
- **Claim 5** (`scripts/dev-cycle.sh:17-18`): "1 … a failed step". A failed step exits with the failing command's status (2 observed, from awk), after a partial digest.
- **Claim 9** (`scripts/dev-cycle.sh:84`): the window line says triggers come from the working tree. Which ones print in full is decided by the default branch's history, and the "last committed" dates read HEAD.
- **Claim 19** (83e7895 message / `scripts/dev-cycle.sh:111`): "entered the default branch in the window" holds only for merge commits. A fast-forwarded old branch commit is carried forward (observed). Harmless for this repo's `--no-ff` merges.

### Unverifiable
- **Claim 22b** (3aee138 message): the regression tests failing on 89a3d3b was not re-executed in this pass. Verifying it needs the bats file run against `git show 89a3d3b:scripts/dev-cycle.sh`.

Hallucination-pattern log: no Incorrect verdicts, so no fabrications to append.

## Goal-Alignment Note
- **Answered:** Every fix from 83e7895 that the brief lists holds: first-parent carry-forward, uncommitted records, the explicit-`--since` sentence, the "never: uncommitted" label, the sed SIGPIPE fix, the window line, date validation, DEV_CYCLE_TODAY, `--sample=0`, "> " quoting, control-character stripping and future-dated records. The compressed --help still prints the full, correct block (lines 2-18). All 13 tests pass. Nothing new rises to Incorrect. Four Mostly-accurate items are new wording gaps: index refresh, exit-code value, window-line sources, and fast-forward integration.
- **Out of scope:** Code quality and design. The deferred items listed in the brief were not re-filed. Claim 22b's historical regression check was not re-run.
- **Escalate:** Nothing blocking. The orchestrator decides whether Claim 19's fast-forward gap merits a wording tweak or an override row. My three untracked execution-log files are under `docs/reviews/execution-logs/r3-digest-final2-*`, alongside this report.
