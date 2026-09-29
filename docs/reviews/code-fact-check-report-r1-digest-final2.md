Commit: de53069

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-digest (branch feat/dev-cycle-digest)
**Scope:** `git diff main...HEAD -- scripts test` (scripts/dev-cycle.sh, test/scripts/dev-cycle.bats) plus commit messages `git log main..HEAD` (3aee138, 83e7895, de53069). Final confirming pass 2, replicate r1.
**Checked:** 2026-09-29
**Total claims checked:** 32
**Summary:** 25 verified, 5 mostly accurate, 0 stale, 1 incorrect, 1 unverifiable

Hallucination-pattern log read before checking (`docs/reviews/hallucination-patterns.md`, 5 entries). No claim below matches a logged pattern; the closest class ("a specific measured value quoted from an artifact set") was checked for the test-count and line-count claims (Claims 27, 28, 29), and those values hold, except 531, which cannot be re-measured.

Execution logs (scratchpad, bare paths; cwd for each is noted in the claim):
- `S=/tmp/claude-1000/-workspace/fba1bfc0-301f-41fe-8500-89690af4d400/scratchpad/fcd2`
- `$S/bats.log`: `bats test/scripts/dev-cycle.bats`, cwd the worktree, 2026-09-29T02:38:02-07:00, exit 0, 13/13 ok
- `$S/help.log`: `bash scripts/dev-cycle.sh --help`, cwd the worktree, exit 0
- `$S/probe.log` (script `$S/probe.txt`): `bash probe.txt <worktree>/scripts/dev-cycle.sh`, cwd `$S`, 2026-09-29T02:38:33-07:00, exit 0 (the exit codes of individual probes are logged inline)
- `$S/probe2.log` (script `$S/probe2.txt`): cwd `$S`, 2026-09-29T02:39:14-07:00, exit 0
- `$S/old-bats.log`: the 3aee138 test file run against the 89a3d3b script, cwd `$S/old`, exit 1
- `$S/numstat.log`: line counts, cwd the worktree, 2026-09-29T02:40:12-07:00, exit 0

Every probe ran in a throwaway repo under `$S/work` with `timeout`; no leftover processes (checked with `pgrep -u $(id -u) -a`).

---

## Claim 1: "The dev-cycle skill (skills/dev-cycle/SKILL.md) runs the judgment steps on top of this digest. … steps that only prose asks for do not run (scripts/questions.sh header; Q-074)."

**Location:** `scripts/dev-cycle.sh:4-6`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two cited sources existing and saying what is attributed to them; does not establish that the skill file exists in this unit (it is a forward reference to the stacked unit feat/dev-cycle, per the brief).

The questions.sh header makes the cited argument: `scripts/questions.sh:5-7` "Why a script and not a convention: this repo's own evidence is that an unenforced instruction does not execute". Q-074 exists and is about that same failure: `docs/working/questions.md:67` "### Q-074 · failure-pattern-writer-trigger", whose body says the writer "is still pr-prep Step 0, a workflow step that is advisory only".

**Evidence:** `scripts/questions.sh:5-11`, `docs/working/questions.md:67-73`

---

## Claim 2: "--since start of the cycle window (midnight, local time). Default: the date in the newest docs/working/cycles/cycle-YYYY-MM-DD.md, else 14 days ago. The digest says which."

**Location:** `scripts/dev-cycle.sh:10-12`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the default-window selection and the source note; does not establish that the help text mentions that future-dated records are skipped (it doesn't, see Claim 9), nor the midnight anchoring beyond Claim 10's probe.

```bash
# scripts/dev-cycle.sh:70-77
if [[ -n "$SINCE" ]]; then
  source_note="--since"
elif [[ -n "$last_record" ]]; then
  SINCE="$last_record"; source_note="the last cycle record, docs/working/cycles/cycle-$last_record.md"
else
  SINCE="$(date -d "$TODAY - 14 days" +%F)"
```
(excerpt ends :75; the enclosing if continues to :77, read.) `source_note` is printed in the Window line at `scripts/dev-cycle.sh:84`. Bats test 4 ("the window defaults to the newest cycle record's date and says so") and test 1 (`no cycle record found`) passed.

**Evidence:** `scripts/dev-cycle.sh:64-84`, `test/scripts/dev-cycle.bats:87-94`, `$S/bats.log`

---

## Claim 3: "--sample how many merges to sample for the spot-check audit (default 2)."

**Location:** `scripts/dev-cycle.sh:13`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the default value; does not establish sampling behaviour (Claim 18).

`scripts/dev-cycle.sh:23` `SAMPLE=2`, used at `:169-173`.

**Evidence:** `scripts/dev-cycle.sh:23`, `scripts/dev-cycle.sh:169-173`

---

## Claim 4: "Read-only: writes nothing to the repo (one temp file, removed on exit)."

**Location:** `scripts/dev-cycle.sh:16-17`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers writes to the working tree, refs and `.git/index` during a run; does not establish behaviour under a concurrent git operation in the same checkout (not probed).

Nothing in the working tree or refs is written, and the temp file is created outside the repo and trapped: `scripts/dev-cycle.sh:147` `qs_err="$(mktemp)"; trap 'rm -f "$qs_err"' EXIT`. But `.git/index` is rewritten. The call at `scripts/dev-cycle.sh:111` runs `git status --porcelain -- "$f"`, and `git status` refreshes the index's stat cache and writes it back (with an opportunistic `index.lock`) when a tracked file's stat data is out of date. Probe P5 touched a committed record without changing it, ran the script, and saw the index mtime change: `index mtime before: …02:38:33.68…` / `after: …02:38:35.91…`. The control in probe2 shows the cause: with `GIT_OPTIONAL_LOCKS=0` the mtime is unchanged, and `git status --porcelain` alone changes it. The precise statement is "writes no tracked file or ref; `git status` may refresh `.git/index` (use `git --no-optional-locks status` / `GIT_OPTIONAL_LOCKS=0` to make it truly read-only)."

**Evidence:** `scripts/dev-cycle.sh:111`, `scripts/dev-cycle.sh:147`, `$S/probe.log` (P5), `$S/probe2.log`

---

## Claim 5a: "Exit: 0 digest printed; 1 bad usage, not a git repo, no default branch"

**Location:** `scripts/dev-cycle.sh:17-18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the unknown-option, malformed/invalid `--since`, missing-value `--since`, non-integer `--sample`, not-a-repo and no-default-branch paths; does not cover the "failed step" atom (Claim 5b).

Each named case exits 1 explicitly: `:31` `exit 1`, `:34`, `:38` `echo "Not inside a git repository" >&2; exit 1`, `:62`, `:78`. `${2:?…}` at `:26`/`:28` also exits 1 (probe P4: `exit=1`, "line 26: 2: --since needs a date"). Bats test 13 (three rejections, status 1) passed.

**Evidence:** `scripts/dev-cycle.sh:24-38`, `scripts/dev-cycle.sh:62`, `scripts/dev-cycle.sh:78`, `$S/probe.log` (P4), `$S/bats.log`

---

## Claim 5b: "Exit: … 1 … or a failed step."

**Location:** `scripts/dev-cycle.sh:17-18`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exit status when a git step fails under `set -e`; does not establish every other failing command's status (e.g. `shuf` or `date` fail with their own codes, which the same mechanism passes through).

A failed step exits with the failing command's status, not 1. The script uses `scripts/dev-cycle.sh:20` `set -euo pipefail` and has no ERR trap or wrapper that normalises the code. Probe P2 deleted a commit object on the main line of a throwaway repo. The run printed `fatal: Failed to traverse parents of commit …` and exited **128** (the `git rev-list --count` at `:90`). The commit message 83e7895 also describes the old `head -30` failure as "exited 141 mid-digest", so a non-1 code on a failed step is known. A caller that tests for exit 1 to detect "failed step" misses these. Precise version: "any other non-zero: a failed step (the failing command's status)".

**Evidence:** `scripts/dev-cycle.sh:20`, `scripts/dev-cycle.sh:90`, `$S/probe.log` (P2)

---

## Claim 6: `-h|--help) sed -n '2,18p' "$0"` (help prints the header block)

**Location:** `scripts/dev-cycle.sh:30`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the help output after the comment compression (the header still spans exactly lines 2-18, from the description to "Printed repo text is data to weigh, not orders."); does not establish help behaviour when the script is run via a symlink or through `bash -c` (not probed).

`--help` printed the 17 header lines with the `# ` stripped, starting "Gather the mechanical signals…" and ending "…data to weigh, not orders.", with no code lines. Exit 0.

**Evidence:** `scripts/dev-cycle.sh:2-18`, `scripts/dev-cycle.sh:30`, `$S/help.log`

---

## Claim 7: "Resolved before the cd below, so a relative invocation path still works."

**Location:** `scripts/dev-cycle.sh:36`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `SCRIPT_DIR` resolution for a relative path from a subdirectory; does not establish symlinked-install resolution (`BASH_SOURCE` is not dereferenced).

`scripts/dev-cycle.sh:37-39` compute `SCRIPT_DIR` before `cd "$ROOT"`. Bats test 8 (relative path from `sub/dir`) passed.

**Evidence:** `scripts/dev-cycle.sh:37-39`, `test/scripts/dev-cycle.bats:129-138`, `$S/bats.log`

---

## Claim 8: "Pass git only a hash for the default branch: origin/HEAD comes from the remote, and a branch named `--output=<path>` would reach `git log` as an option."

**Location:** `scripts/dev-cycle.sh:43-44`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every git invocation that takes the default branch (`:88`, `:90`, `:111` all pass `"$MAIN_SHA"`) and the option-like-name skip; does not establish that `$MAIN` (the name) is never passed to git (it isn't, it is only echoed at `:84` and `:92`), nor that the Could-not-resolve message's "tried origin/HEAD" means the remote ref (it means a *local* branch with origin/HEAD's name, `:52`).

```bash
# scripts/dev-cycle.sh:50-53
for c in "${candidates[@]}"; do
  [[ "$c" == -* ]] && continue
  sha="$(git rev-parse --verify --quiet "refs/heads/$c^{commit}" 2>/dev/null || true)"
  if [[ -n "$sha" ]]; then MAIN="$c"; MAIN_SHA="$sha"; break; fi
```
(excerpt ends :53; the loop closes at :54, and the current-branch fallback at :55-61 also skips `-*`, read.) Bats test 12 (the victim file is unchanged, status 0) passed.

**Evidence:** `scripts/dev-cycle.sh:45-62`, `scripts/dev-cycle.sh:88-90`, `scripts/dev-cycle.sh:111`, `$S/bats.log`

---

## Claim 9: "# ignore future-dated" (cycle records)

**Location:** `scripts/dev-cycle.sh:68`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers records dated after `$TODAY` being skipped and a record dated today being kept; does not establish behaviour when `DEV_CYCLE_TODAY` is not a date (string comparison then decides; test-only variable).

`scripts/dev-cycle.sh:68` `[[ "$d" > "$last_record" && ! "$d" > "$TODAY" ]] && last_record="$d"`. Bats test 4 creates `cycle-9999-12-31.md` and still sees `since 2026-02-10`.

**Evidence:** `scripts/dev-cycle.sh:65-69`, `test/scripts/dev-cycle.bats:87-91`, `$S/bats.log`

---

## Claim 10: "A bare date means "this time of day" to git; anchor it at midnight."

**Location:** `scripts/dev-cycle.sh:79`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git's `--since` parsing of a bare date against a `DATE 00:00:00` anchor on this machine's git; does not establish timezone behaviour across DST boundaries.

Probe P6: a commit at 00:00:30 today; `--since=<today>` counts **0**, `--since="<today> 00:00:00"` counts **1** (run at 02:38). `scripts/dev-cycle.sh:80` `SINCE_TS="$SINCE 00:00:00"` is what every `--since` uses (`:88`, `:90`, `:111`).

**Evidence:** `scripts/dev-cycle.sh:80`, `$S/probe.log` (P6), `test/scripts/dev-cycle.bats:96-102`

---

## Claim 11: "Window: … Merges and commits: `$MAIN` at <sha>; triggers, questions and roadmap: the working tree."

**Location:** `scripts/dev-cycle.sh:84`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which source each section reads; does not establish that the mixed sources give wrong output in practice (no case was found where they do).

Merges and commits do read `$MAIN_SHA` (`:88`, `:90`), and trigger, question and roadmap *text* is read from the working tree (`:116`, `:146-148`, `:183`). But the trigger section also reads history. Whether a record prints in full or is carried forward depends on the default branch's first-parent log plus `git status`: `scripts/dev-cycle.sh:111` `git log -1 --first-parent --since="$SINCE_TS" --format=%h "$MAIN_SHA" -- "$f"`. And the "last committed" dates come from HEAD's history, not `$MAIN`'s: `scripts/dev-cycle.sh:114` `git log -1 --format=%ad --date=short -- "$f"` and `:180` for the roadmap. Those dates are also author dates (`%ad`), not commit dates. More precise: "trigger selection: `$MAIN` plus uncommitted changes; text: the working tree; 'last committed' dates: HEAD (author date)."

**Evidence:** `scripts/dev-cycle.sh:84-90`, `scripts/dev-cycle.sh:111-116`, `scripts/dev-cycle.sh:180-183`

---

## Claim 12: "control characters stripped from merge subjects" (commit 83e7895; implemented by the `tr -d` at :88)

**Location:** `scripts/dev-cycle.sh:88`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers merge-list lines (used in sections 1 and 4); does not establish sanitising of other printed repo text (trigger text, log rows, roadmap, question slugs), which the claim does not assert.

`scripts/dev-cycle.sh:88` `| tr -d '\000-\010\013-\037\177'` deletes C0 controls and DEL, except TAB (\011) and LF (\012). Probe P7 merged with the subject `merge:\tTAB\033[31mESC`. The ESC byte was removed, but the TAB survived: the od output shows `:  \t   T   A   B   [   3   1   m   E   S   C`. Precise version: "control characters other than tab stripped". The remaining `[31m` is inert without its ESC.

**Evidence:** `scripts/dev-cycle.sh:88`, `$S/probe.log` (P7)

---

## Claim 13: "$n_merges merge(s) on `$MAIN`'s first-parent line; $commits commit(s) reachable from it, merged branches included."

**Location:** `scripts/dev-cycle.sh:92`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the two git commands' selection (first-parent merges; all reachable commits); does not establish completeness when an older-committer-dated commit sits above newer ones (git's `--since` stops walking at the first too-old commit rather than filtering, cf. `--since-as-filter`), so "reachable" counts can undercount on skewed history.

`scripts/dev-cycle.sh:88` `git log "$MAIN_SHA" --first-parent --merges --since=…` and `:90` `git rev-list --count --since="$SINCE_TS" "$MAIN_SHA"` (no `--first-parent`, so merged branch commits count). Bats tests 1 and 5 passed (`3 merge(s)`, `; $total commit(s)`).

**Evidence:** `scripts/dev-cycle.sh:88-92`, `$S/bats.log`

---

## Claim 14a: "(first-parent, so a branch commit dated earlier counts at its merge)"

**Location:** `scripts/dev-cycle.sh:109-110`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers records that reach the default branch via a merge commit dated in the window; does not cover fast-forward or rebase merges, which have no merge commit (Claim 14b).

`scripts/dev-cycle.sh:111` walks `$MAIN_SHA`'s first-parent line, and the merge commit's diff against its first parent contains the file. Bats test 3 commits `003-late.md` on branch `late` dated 2020-01-03, merges it `--no-ff` today, and "if late thing." prints in full (passed).

**Evidence:** `scripts/dev-cycle.sh:111-112`, `test/scripts/dev-cycle.bats:71-80`, `$S/bats.log`

---

## Claim 14b: "Changed = merged into the default branch in the window … or uncommitted here."

**Location:** `scripts/dev-cycle.sh:109-110`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fast-forward-merge case and the uncommitted case; does not establish rebase-and-merge (same mechanism as fast-forward: no merge commit, original committer dates kept only if not re-committed; not probed).

The uncommitted half holds (bats test 3, `004-wip.md` prints). The "merged in the window" definition holds only for merge commits. Probe P1 committed `003-ff.md` on a branch dated 2020-01-03, fast-forwarded main to it (`git merge --ff-only`), and wrote a cycle record for yesterday. The record is **carried forward** although it entered the default branch inside the window: `Carried forward (1): 003-ff.md`. With a fast-forward, the first-parent line holds the branch commit at its own 2020 committer date, so `--since` excludes it. This repo merges with `--no-ff`, but the header says the installed copy "serves any project" (`:15-16`). Precise version: "merged into the default branch by a merge commit in the window". This is the same class of gap the previous pass fixed: a record carried forward that no cycle has judged.

**Evidence:** `scripts/dev-cycle.sh:111-118`, `scripts/dev-cycle.sh:15-16`, `$S/probe.log` (P1)

---

## Claim 15: "### $f (last committed ${d:-never: uncommitted})"

**Location:** `scripts/dev-cycle.sh:115`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the empty-date fallback for files with no commit in HEAD's history; does not establish which branch's history the date comes from (HEAD, see Claim 11).

`scripts/dev-cycle.sh:114` `d="$(git log -1 --format=%ad --date=short -- "$f")"` is empty when no HEAD commit touches `$f`, so the label reads "never: uncommitted". Bats test 3 prints the uncommitted record, but it asserts only the trigger text, not this label.

**Evidence:** `scripts/dev-cycle.sh:114-116`, `test/scripts/dev-cycle.bats:75-80`

---

## Claim 16: "The whole clause to the cell's end; prefer a capitalised "Revisit" (the trigger sentence) over an earlier "revisit-trigger verdicts" mention."

**Location:** `scripts/dev-cycle.sh:127-128`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers extraction to the next `|` and the preference for a capitalised match; does not establish the right pick when an earlier cell holds a *capitalised* "Revisit" mention (the first capitalised match wins).

```bash
# scripts/dev-cycle.sh:129-130
text="$(grep -oE 'Revisit[^|]*' <<< "$row" | head -1 || true)"
[[ -n "$text" ]] || text="$(grep -oiE 'revisit[^|]*' <<< "$row" | head -1)"
```
Bats test 2 (a row with `revisit-trigger verdicts` before `Revisit if gizmos appear <500 x> end.`) asserts the full clause after it (passed). The unguarded `:130` cannot fail under `set -e`: rows reach it only through `grep -i 'revisit'` at `:135`.

**Evidence:** `scripts/dev-cycle.sh:122-135`, `test/scripts/dev-cycle.bats:50-62`, `$S/bats.log`

---

## Claim 17: "`open` prints "ID  route  slug" in columns of 2+ spaces; a route can contain one space ("you: judgment"), a slug can contain "trigger"."

**Location:** `scripts/dev-cycle.sh:149-150`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the format for routes up to 14 characters (all five defined routes); does not establish parsing of a route of 14+ characters, where `%-14s` adds no padding (none exists).

`scripts/questions.sh:411-413` `printf '%s  %-14s  %s\n' "$id" "$route" "$slug"`. Bats test 9 (a slug containing "trigger" under route `agent`) passed with `agent=1, trigger=1`.

**Evidence:** `scripts/questions.sh:408-414`, `scripts/dev-cycle.sh:151`, `test/scripts/dev-cycle.bats:140-168`, `$S/bats.log`

---

## Claim 18: "Seeded by a hash of the date: same day, same merges; different days usually differ. (The raw date seeded almost nothing: dates share their first bytes.)"

**Location:** `scripts/dev-cycle.sh:170-171`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers determinism for the same date and input and variation across four dates; does not establish the historical parenthetical about the raw-date seed (not re-run), nor determinism across coreutils versions of `shuf`.

`scripts/dev-cycle.sh:172-173` seed from `sha256sum` of `$TODAY`, `shuf -n "$SAMPLE" --random-source=<(yes "$seed")`. Bats test 6 (identical reruns) and test 7 (at least 2 distinct samples across 4 dates) passed. `cut -c1-64` keeps exactly the 64 hex digits and drops sha256sum's `  -` suffix.

**Evidence:** `scripts/dev-cycle.sh:169-176`, `test/scripts/dev-cycle.bats:104-127`, `$S/bats.log`

---

## Claim 19: "Each test builds a throwaway repo under $BATS_TEST_TMPDIR; this repo is untouched."

**Location:** `test/scripts/dev-cycle.bats:3-4`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the repo and working directory each test uses; does not establish date-hermeticity (tests 3 and 5 use the real `date`).

`test/scripts/dev-cycle.bats:17-19` `R="$BATS_TEST_TMPDIR/repo"; make_repo "$R" main; cd "$R"`. The only other reads of the repo are `$REPO_ROOT/scripts`, which test 8 copies (`:131` `cp -r "$REPO_ROOT/scripts" "$BATS_TEST_TMPDIR/tools"`).

**Evidence:** `test/scripts/dev-cycle.bats:8-20`, `test/scripts/dev-cycle.bats:129-133`

---

## Claim 20: "HOME in the temp dir: the ~/.claude/scripts fallback can't reach the real one."

**Location:** `test/scripts/dev-cycle.bats:14`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the questions.sh fallback path; does not establish that the fallback is ever taken (the tests run the in-repo script, whose sibling questions.sh exists).

`test/scripts/dev-cycle.bats:15` `export HOME="$BATS_TEST_TMPDIR/home"`; the fallback is `scripts/dev-cycle.sh:145` `QS="$HOME/.claude/scripts/questions.sh"`.

**Evidence:** `test/scripts/dev-cycle.bats:15`, `scripts/dev-cycle.sh:144-145`

---

## Claim 21: "Committed on a branch before the window, merged into main inside it."

**Location:** `test/scripts/dev-cycle.bats:71`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the fixture's `--no-ff` merge; does not cover a fast-forward merge (Claim 14b).

`test/scripts/dev-cycle.bats:73-74` commits with `GIT_COMMITTER_DATE="2020-01-03T12:00:00"`, then `git merge -q --no-ff late -m "merge: late"`, dated now. The window is yesterday (`:77`).

**Evidence:** `test/scripts/dev-cycle.bats:71-77`

---

## Claim 22: "All commits here are from today, before "now": a midnight window counts all."

**Location:** `test/scripts/dev-cycle.bats:98`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the fixture as normally run; does not hold if the test runs between 00:00:00 and 00:00:30, or across midnight between `setup` and `:97`.

`make_repo` commits at setup time (`:22-35`) and `:97` adds one at `$(date +%F)T00:00:30`.

**Evidence:** `test/scripts/dev-cycle.bats:22-35`, `test/scripts/dev-cycle.bats:97-101`

---

## Claim 23: "No questions-archive.md: questions.sh open exits non-zero."

**Location:** `test/scripts/dev-cycle.bats:173`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `open`'s precondition; does not establish other questions.sh failure modes being reported (only this one is exercised).

`scripts/questions.sh:409` `require_files` → `:137` `die "no questions doc here — …"`. Bats test 10 saw "questions.sh open failed", not "None open." (passed).

**Evidence:** `scripts/questions.sh:132-138`, `scripts/questions.sh:408-409`, `scripts/dev-cycle.sh:148-163`, `$S/bats.log`

---

## Claim 24: "Merge list: `sed -n '1,30p'` instead of `head -30`, which hit SIGPIPE under pipefail past ~64 KB of merges and exited 141 mid-digest."

**Location:** commit 83e7895 (implemented at `scripts/dev-cycle.sh:93`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the old and new pipelines in isolation on a 150,892-byte input; does not establish the exact threshold (pipe capacity, ~64 KB on Linux, not bisected) nor a full-script run with 2,000+ real merges.

probe2: `set -euo pipefail; printf '%s\n' "$m" | head -30` → `head exit=141`; the same with `sed -n '1,30p'` → `survived`, `sed exit=0`. (An earlier variant in probe.log gave 141 for both because its `yes | head` generator itself took SIGPIPE; it is superseded.) `scripts/dev-cycle.sh:93` uses `sed -n '1,30p'`.

**Evidence:** `scripts/dev-cycle.sh:93`, `$S/probe2.log`, `$S/probe2.txt`

---

## Claim 25: "A decision record now counts as changed when it entered the default branch in the window (first-parent history, so a branch commit dated earlier counts at its merge) or is uncommitted"

**Location:** commit 83e7895
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Same scope and finding as Claims 14a/14b; does not add evidence beyond them.

Same wording as the code comment. It holds for merge commits and uncommitted files, but a record that entered by fast-forward in the window is carried forward (probe P1: `Carried forward (1): 003-ff.md`).

**Evidence:** `scripts/dev-cycle.sh:109-118`, `$S/probe.log` (P1)

---

## Claim 26: "Tests extended: branch-merged, uncommitted and SINCE-dated items print in full; capitalised "Revisit" preferred; explicit --since sentence; invalid date rejected."

**Location:** commit 83e7895
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of each named assertion; does not establish that each would fail without its fix (not mutation-tested here).

Branch-merged, uncommitted and SINCE-dated items: `test/scripts/dev-cycle.bats:79` `for t in "if new thing." "if late thing." "if uncommitted thing." "Revisit if boundary."` (row 7 is dated yesterday, which is `$SINCE`). Capitalised preferred: `:55` and `:61`. Explicit --since: `:93`. Invalid date: `:206` `--since=2026-13-45`.

**Evidence:** `test/scripts/dev-cycle.bats:55-61`, `test/scripts/dev-cycle.bats:72-83`, `test/scripts/dev-cycle.bats:92-93`, `test/scripts/dev-cycle.bats:206-207`

---

## Claim 27: "Comments and section echoes compressed to stay within the 400-line unit cap (396)."

**Location:** commit 83e7895
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the code-line count of this unit against main; does not establish the stacked unit's count.

`$S/numstat.log`: `186 0 scripts/dev-cycle.sh`, `210 0 test/scripts/dev-cycle.bats` = 396.

**Evidence:** `$S/numstat.log`

---

## Claim 28: "test/scripts/dev-cycle.bats: 13 hermetic tests; the regression tests fail on the pre-review version (89a3d3b)."

**Location:** commit 3aee138
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the test count and that the 3aee138 tests fail against the 89a3d3b script; does not establish *which* tests the message means by "the regression tests", nor that each failure is for its intended reason (11 of 13 fail, several probably on output wording).

The file holds 13 `@test` blocks (`test/scripts/dev-cycle.bats:37,50,64,87,96,104,114,129,140,170,181,191,203`), and bats ran 13 (`$S/bats.log`). The 3aee138 test file run against `git show 89a3d3b:scripts/dev-cycle.sh` exits 1: `not ok` on tests 1-5 and 7-12, `ok` on 6 and 13.

**Evidence:** `test/scripts/dev-cycle.bats:37-210`, `$S/old-bats.log`, `$S/bats.log`

---

## Claim 29: "split in /away mode because the combined unit was 531 code lines (cap 400); this unit is 400."

**Location:** commit 3aee138
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers "this unit is 400" (verified) and the 531 figure (not re-measurable); does not establish the current stacked-unit size against the cap.

Most-severe part: the 531 figure. `git diff --numstat main...3aee138` sums to **400**, so that part holds. `feat/dev-cycle` measured now against main, with `docs/` excluded, is **529**, not 531. Both that branch and main have moved since the split, so the split-time figure cannot be reproduced from current refs (paraphrased — no quote available because the claim concerns a point-in-time measurement of refs that no longer hold that state). Verifying it needs the stacked branch's tip at split time.

**Evidence:** `$S/numstat.log`

---

## Claim 30: "Uncommitted files show "never: uncommitted", not an empty date." / "Explicit --since says so instead of "No earlier cycle record"."

**Location:** commit 83e7895
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both labels; does not establish the roadmap's parallel label, which uses different text: `never (uncommitted)` at `:181`.

`scripts/dev-cycle.sh:115` `${d:-never: uncommitted}`; `:101` `$([[ "$source_note" == --since ]] && echo 'An explicit --since was given' || …)`. Bats test 4 asserts the --since sentence (passed).

**Evidence:** `scripts/dev-cycle.sh:101`, `scripts/dev-cycle.sh:115`, `scripts/dev-cycle.sh:181`, `$S/bats.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 5b** (`scripts/dev-cycle.sh:17-18`): "1 … a failed step" is wrong: under `set -e` a failed step exits with the failing command's status (probe: a git traversal failure exits 128). Either say "non-zero (the failing command's status)" or normalise with an ERR trap.

### Stale
- (none)

### Mostly Accurate
- **Claim 4** (`scripts/dev-cycle.sh:16-17`): "writes nothing to the repo": `git status` at `:111` refreshes `.git/index` (probe: the index mtime changed; no change with `GIT_OPTIONAL_LOCKS=0`). Use `git --no-optional-locks status`, or qualify the claim.
- **Claim 11** (`scripts/dev-cycle.sh:84`): trigger selection reads `$MAIN` history plus `git status`, and the "last committed" dates read HEAD (author date), not "the working tree".
- **Claim 12** (`scripts/dev-cycle.sh:88`, commit 83e7895): TAB is kept; "control characters other than tab".
- **Claim 14b** (`scripts/dev-cycle.sh:109-110`) and **Claim 25** (commit 83e7895): a record that entered the default branch by fast-forward in the window is carried forward (probe P1). Qualify it as "by a merge commit", or also treat the window's first-parent commits as merged.

### Unverifiable
- **Claim 29** (commit 3aee138): the 531-line split-time figure needs feat/dev-cycle's tip at split time; it measures 529 now. The "this unit is 400" part holds.

---

## Goal-Alignment Note
- **Answered:** Every fix from the previous pass was verified. Carry-forward now uses first-parent plus `git status` (Verified for `--no-ff` merges and uncommitted files). The explicit `--since` sentence, the `never: uncommitted` label, the `sed` SIGPIPE fix (executed old vs new), real-date validation, `DEV_CYCLE_TODAY` pinning the window, the `--sample=0` message, `> ` quoting, control-char stripping and future-dated records all hold. The compressed `--help` output is correct, and all 13 tests pass. New findings: one Incorrect (the exit-code contract, 5b) and four Mostly accurate atoms (index write, window-line sources, TAB kept, fast-forward merges carried forward). The fast-forward gap belongs to the carry-forward class the previous pass fixed.
- **Out of scope:** I did not run health-check.sh or the full suite. I did not judge code quality. The override-log deferrals (file-level carry-forward cost, option-name test defences, untested SIGPIPE fix, carried-list format) were not re-filed. Rebase-merge and concurrent-git behaviour were not probed.
- **Escalate:** Claim 14b is a judgment call for the orchestrator. It is harmless in this repo, which merges `--no-ff`, but the script says it serves any project. Whether a fast-forward merge counts as "merged in the window" decides whether it is a comment fix or a code fix. Logs are in the scratchpad (`$S`), not `docs/reviews/execution-logs/`, because the brief forbids editing tracked files other than this report.
