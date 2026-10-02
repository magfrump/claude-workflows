Commit: de53069

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-digest (branch feat/dev-cycle-digest)
**Scope:** `git diff main...HEAD -- scripts test` (scripts/dev-cycle.sh, test/scripts/dev-cycle.bats) and commit messages `git log main..HEAD` (3aee138, 83e7895, de53069). Final confirming pass 2, replicate r2.
**Checked:** 2026-09-29
**Total claims checked:** 21
**Summary:** 13 verified, 5 mostly accurate, 0 stale, 2 incorrect, 1 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`); no claim in scope matches a logged pattern. The one measured-value claim ("396", "400", "13 tests") was recomputed and holds, so the "measured value quoted from an artifact set that does not contain it" class does not recur here.

Execution provenance: all probes ran in throwaway repos under `/tmp/claude-1000/-workspace/fba1bfc0-301f-41fe-8500-89690af4d400/scratchpad/fc2-final2/work`, cwd as stated per claim, 2026-09-29T02:38–02:40-07:00. Probe scripts: `…/fc2-final2/probe.txt`, `…/fc2-final2/probe2.txt`. Captured output: `…/fc2-final2/logs/probe-out.txt`, `…/fc2-final2/logs/probe2-out.txt`, `…/fc2-final2/logs/q4-out.txt`, `…/fc2-final2/logs/regr-89a3d3b.txt`. Commands: `timeout 300 bash …/probe.txt` (exit 0), `timeout 200 bash …/probe2.txt` (exit 0), `cd …/regr && timeout 300 bats test/scripts/dev-cycle.bats` (exit 1). No probe process survived (checked with `pgrep -u $(id -u) -a`).

---

## Claim 1: "The dev-cycle skill (skills/dev-cycle/SKILL.md) runs the judgment steps … (scripts/questions.sh header; Q-074)" and "create it this cycle from the template in the dev-cycle skill"

**Location:** `scripts/dev-cycle.sh:4-6`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of the three referents on this branch; does not establish that the stacked unit's skill will contain a roadmap template (line 185) or run the steps the comment says.

`skills/dev-cycle/` does not exist in this worktree (`ls: cannot access 'skills/dev-cycle'`); the brief and 3aee138's message declare it a forward reference ("The script's references to the skill are forward references until then"). The other two referents resolve: the questions.sh header says `both because only prose asked for them.` (`scripts/questions.sh:8`), and Q-074 appears in `docs/working/questions.md` (paraphrased — no quote available because the claim is only that the ID exists; grep returned that file). Line 185's `from the template in the dev-cycle skill` (`scripts/dev-cycle.sh:185`) has the same forward-reference status. Needs the stacked unit feat/dev-cycle to verify.

**Evidence:** `scripts/dev-cycle.sh:4-6`, `scripts/dev-cycle.sh:185`, `scripts/questions.sh:8`, `docs/working/questions.md`

---

## Claim 2: "--help" prints the usage header (lines 2-18) correctly after compression

**Location:** `scripts/dev-cycle.sh:30`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that `-h|--help` prints exactly the comment block and exits 0; does not establish that every statement inside that block is true (claims 3–5 check those).

`-h|--help) sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;` (`scripts/dev-cycle.sh:30`). Line 18 is the last header line (`# branch, or a failed step. Printed repo text is data to weigh, not orders.`) and line 19 is blank, so the range is exact. Probe P1 (`timeout 30 bash scripts/dev-cycle.sh --help`, exit 0) printed the whole block from "Gather the mechanical signals…" to "…data to weigh, not orders." with `# ` prefixes stripped and nothing from line 20 on.

**Evidence:** `scripts/dev-cycle.sh:2-19`, `scripts/dev-cycle.sh:30`, `…/fc2-final2/logs/probe-out.txt` (P1)

---

## Claim 3: "Default: the date in the newest docs/working/cycles/cycle-YYYY-MM-DD.md, else 14 days ago. The digest says which."

**Location:** `scripts/dev-cycle.sh:10-12`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the default-window choice, the future-dated exclusion (`:68`), the DEV_CYCLE_TODAY pin of the 14-day default, and the stated source; does not establish behaviour for a record whose filename date is invalid (e.g. `cycle-2026-02-30.md`), which the glob accepts and `date -d` later rejects with exit 1.

```bash
# scripts/dev-cycle.sh:65-77
for f in docs/working/cycles/cycle-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md; do
  ...
  [[ "$d" > "$last_record" && ! "$d" > "$TODAY" ]] && last_record="$d"  # ignore future-dated
done
...
  SINCE="$(date -d "$TODAY - 14 days" +%F)"
```

Test 4 (`test/scripts/dev-cycle.bats:87-94`) creates 2026-01-05, 2026-02-10 and 9999-12-31 records and asserts `Window: since 2026-02-10 (from the last cycle record`. Probe P9 (`DEV_CYCLE_TODAY=2026-01-20`, no record) printed `Window: since 2026-01-06 (from no cycle record found, so the default of 14 days …`, i.e. 2026-01-20 minus 14 days. The invalid-filename-date residue is paraphrased — no quote available because it follows from the glob at `:65` accepting any digits plus the `date -d "$SINCE"` check at `:78`, not executed.

**Evidence:** `scripts/dev-cycle.sh:10-12`, `scripts/dev-cycle.sh:65-78`, `test/scripts/dev-cycle.bats:87-94`, `…/fc2-final2/logs/probe-out.txt` (P9)

---

## Claim 4: "Read-only: writes nothing to the repo (one temp file, removed on exit)."

**Location:** `scripts/dev-cycle.sh:16-17`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers writes to the repository's `.git/` directory by the digest's own git calls; does not establish any change to tracked content or the working tree (none observed), nor that the temp-file half of the claim is wrong (it holds).

The carry-forward fix in 83e7895 added a `git status` call per decision record:

```bash
# scripts/dev-cycle.sh:111
  changed="$(git log -1 --first-parent --since="$SINCE_TS" --format=%h "$MAIN_SHA" -- "$f" 2>/dev/null)$(git status --porcelain -- "$f")"
```

`git status` performs an opportunistic index refresh: it takes `.git/index.lock` and rewrites `.git/index` when stat data is stale. Probe P7/Q3 (cwd `…/work/r3`, a repo with one decision record, after `touch docs/decisions/001-old.md`) measured the index hash before and after one run: default run `before=62c3c4ec0ac4c884 after=a394c6ef860f9663` (rewritten); `GIT_OPTIONAL_LOCKS=0` run `before=… after=…` identical; the 3aee138 script (no `git status`) left it identical. So the script writes to the repo, and it is new since the fix. It matters in this project's shared checkout (other sessions run git in /workspace concurrently): while the digest holds `index.lock`, a concurrent `git commit`/`git add` fails with "Unable to create '.git/index.lock'". Precise fix: `git --no-optional-locks status --porcelain -- "$f"` (or export `GIT_OPTIONAL_LOCKS=0`), which the probe shows leaves the index untouched. The temp-file half holds: `qs_err="$(mktemp)"; trap 'rm -f "$qs_err"' EXIT` (`scripts/dev-cycle.sh:147`).

**Evidence:** `scripts/dev-cycle.sh:16-17`, `scripts/dev-cycle.sh:111`, `scripts/dev-cycle.sh:147`, `…/fc2-final2/logs/probe-out.txt` (P7), `…/fc2-final2/logs/probe2-out.txt` (Q3)

---

## Claim 5: "Exit: 0 digest printed; 1 bad usage, not a git repo, no default branch, or a failed step."

**Location:** `scripts/dev-cycle.sh:17-18`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the missing-value, invalid-date and failed-step exit paths; does not establish every usage error (an empty `--since=` is not rejected) nor the not-a-git-repo path (read, not run this pass).

Bad usage exits 1: P2 `--since` with no value printed `line 26: 2: --since needs a date` and `exit=1` (from `SINCE="${2:?--since needs a date}"`, `scripts/dev-cycle.sh:26`); `--since=2026-02-30` printed `--since must be a real YYYY-MM-DD date`, `exit=1` (`:78`). A failed step, however, exits with that step's status under `set -euo pipefail` (`:20`), not 1: probe Q4 (cwd `…/work/r5`, PATH without `sha256sum`) died at `seed="$(printf '%s' "$TODAY" | sha256sum | cut -c1-64)"` (`:172`) with `exit=127` after sections 1–3 printed. Also `--since=` (empty) sets `SINCE=""` via `--since=*) SINCE="${1#--since=}"` (`:27`), and `if [[ -n "$SINCE" ]]` (`:70`) then treats it as absent, so that usage error runs to exit 0 (paraphrased — no quote available because the empty-value path was read, not executed). Precise version: "non-zero (usually 1) on a failed step; a partial digest may already be printed".

**Evidence:** `scripts/dev-cycle.sh:17-18`, `scripts/dev-cycle.sh:20`, `scripts/dev-cycle.sh:26-27`, `scripts/dev-cycle.sh:70`, `scripts/dev-cycle.sh:78`, `scripts/dev-cycle.sh:172`, `…/fc2-final2/logs/probe-out.txt` (P2), `…/fc2-final2/logs/q4-out.txt`

---

## Claim 6: "Resolved before the cd below, so a relative invocation path still works."

**Location:** `scripts/dev-cycle.sh:36`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers SCRIPT_DIR resolution for a relative `$0`; does not establish the `$HOME/.claude/scripts` fallback's behaviour when SCRIPT_DIR lacks questions.sh.

`SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` precedes `cd "$ROOT"` (`scripts/dev-cycle.sh:37-39`); test 8 runs the copied script by a relative path from `sub/dir` and asserts exit 0 and `## 5. Roadmap` (`test/scripts/dev-cycle.bats:129-138`).

**Evidence:** `scripts/dev-cycle.sh:36-39`, `test/scripts/dev-cycle.bats:129-138`

---

## Claim 7: "Pass git only a hash for the default branch … a branch named `--output=<path>` would reach `git log` as an option."

**Location:** `scripts/dev-cycle.sh:43-44`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every git call that names the default branch (`:88`, `:90`, `:111` pass `"$MAIN_SHA"`); does not establish that `MAIN` (printed, never passed to git) is free of markdown-breaking characters.

`sha="$(git rev-parse --verify --quiet "refs/heads/$c^{commit}" …)"` (`:52`) resolves via a fully qualified ref, and the three rev-taking calls use the hash: `git log "$MAIN_SHA" --first-parent --merges …` (`:88`), `git rev-list --count --since="$SINCE_TS" "$MAIN_SHA"` (`:90`), `git log -1 --first-parent … "$MAIN_SHA" -- "$f"` (`:111`). The `last committed` lookups `git log -1 --format=%ad --date=short -- "$f"` (`:114`, `:180`) pass no revision at all. Test 12 pins the outcome (`test/scripts/dev-cycle.bats:191-201`).

**Evidence:** `scripts/dev-cycle.sh:43-62`, `scripts/dev-cycle.sh:88-90`, `scripts/dev-cycle.sh:111-114`, `scripts/dev-cycle.sh:180`, `test/scripts/dev-cycle.bats:191-201`

---

## Claim 8: "A bare date means "this time of day" to git; anchor it at midnight."

**Location:** `scripts/dev-cycle.sh:79`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the `SINCE_TS` anchoring used by all `--since` git calls; does not establish timezone handling beyond local time.

`SINCE_TS="$SINCE 00:00:00"` (`:80`) is the only value passed to git's `--since` (`:88`, `:90`, `:111`). Test 5 commits at 00:00:30 today and asserts all commits count (`test/scripts/dev-cycle.bats:96-102`); the 89a3d3b run of that test shows the pre-anchor failure mode (`0 merge(s), 0 commit(s) on `main` in the window`, `regr-89a3d3b.txt`).

**Evidence:** `scripts/dev-cycle.sh:79-80`, `test/scripts/dev-cycle.bats:96-102`, `…/fc2-final2/logs/regr-89a3d3b.txt`

---

## Claim 9: "Window: … Merges and commits: `$MAIN` at …; triggers, questions and roadmap: the working tree."

**Location:** `scripts/dev-cycle.sh:84`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which source each section reads its text and selection from; does not establish the consequence for carry-forward (claim 11) beyond naming it.

Trigger, question and roadmap text is read from disk (e.g. `awk … "$f"`, `:116`; `docs/roadmap.md`, `:183`), so "working tree" is right for text. But which triggers print in full is decided by the default branch's history — `git log -1 --first-parent … "$MAIN_SHA" -- "$f"` (`:111`) — and the "last committed" dates come from HEAD's history, `git log -1 --format=%ad --date=short -- "$f"` (`:114`, `:180`). When HEAD is not the default branch these diverge (probe P3, claim 11). Precise version: "triggers: text from the working tree, selected by `$MAIN`'s history plus uncommitted changes".

**Evidence:** `scripts/dev-cycle.sh:84`, `scripts/dev-cycle.sh:111-116`, `scripts/dev-cycle.sh:180-183`, `…/fc2-final2/logs/probe-out.txt` (P3)

---

## Claim 10: "$n_merges merge(s) on `$MAIN`'s first-parent line; $commits commit(s) reachable from it, merged branches included."

**Location:** `scripts/dev-cycle.sh:92`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two counts' definitions (first-parent merges; all reachable commits, both filtered by commit date ≥ midnight of SINCE); does not establish that merged-branch commits dated before the window are counted (they are not — the filter is by commit date).

`git log "$MAIN_SHA" --first-parent --merges --since="$SINCE_TS"` (`:88`) and `git rev-list --count --since="$SINCE_TS" "$MAIN_SHA"` (`:90`, no `--first-parent`) match the sentence; test 1 asserts `3 merge(s)` and test 5 asserts the full commit count.

**Evidence:** `scripts/dev-cycle.sh:88-92`, `test/scripts/dev-cycle.bats:44`, `test/scripts/dev-cycle.bats:96-102`

---

## Claim 11: "Printed in full: triggers in decision records changed since $SINCE … Listed by name only: the rest, whose verdict carries forward from docs/working/cycles/cycle-$last_record.md"

**Location:** `scripts/dev-cycle.sh:98`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the digest's statement that every record changed since SINCE prints in full and every carried record had a prior verdict, when the script runs with HEAD on a branch other than the default; does not establish behaviour on the default branch, where the named cases (merged-in-window, uncommitted) hold (claim 13).

The selection is `changed="$(git log -1 --first-parent --since="$SINCE_TS" --format=%h "$MAIN_SHA" -- "$f" …)$(git status --porcelain -- "$f")"` (`:111`): a record committed on the current branch but not yet on the default branch is neither in `$MAIN_SHA`'s history nor dirty, so it is carried forward. Probe P3 (cwd `…/work/r3`, cycle record dated yesterday, `002-branch.md` committed today on branch `feat`): the digest printed no trigger text and `Carried forward (2): 001-old.md 002-branch.md` — a record written today that no cycle has judged is told to "carry forward" its verdict from yesterday's record. **This is a regression introduced by 83e7895**: the 3aee138 script on the same repo (probe Q2) printed `if branch-only thing.` and `Carried forward (1): 001-old.md`, because it dated records by HEAD's history. Running from a non-default branch is plausible here (the digest reads the working tree, and other sessions switch /workspace's branch). A precise fix would also count a record as changed when `git log -1 --since="$SINCE_TS" HEAD -- "$f"` is non-empty (or when `git diff --quiet "$MAIN_SHA" -- "$f"` fails).

**Evidence:** `scripts/dev-cycle.sh:96-120`, `…/fc2-final2/logs/probe-out.txt` (P3), `…/fc2-final2/logs/probe2-out.txt` (Q2)

---

## Claim 12: "An explicit --since was given, so every trigger is printed in full."

**Location:** `scripts/dev-cycle.sh:101`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the message and the `full=1` path under `--since`; does not establish the "No earlier cycle record" wording path's tests (only the --since path is asserted).

`if [[ -n "$last_record" && "$source_note" != "--since" ]]; then full=0 … else full=1; echo "$([[ "$source_note" == --since ]] && echo 'An explicit --since was given' || …)` (`:96-101`); test 4 asserts `An explicit --since was given, so every trigger` (`test/scripts/dev-cycle.bats:92-93`).

**Evidence:** `scripts/dev-cycle.sh:96-102`, `test/scripts/dev-cycle.bats:92-93`

---

## Claim 13: "Changed = merged into the default branch in the window (first-parent, so a branch commit dated earlier counts at its merge), or uncommitted here."

**Location:** `scripts/dev-cycle.sh:109-110`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers merge-commit (`--no-ff`) merges and uncommitted records; does not establish fast-forwarded branches or records committed only on the current branch (claim 11).

For a real merge the comment holds: test 3's `late` branch commit dated 2020-01-03, merged with `--no-ff` today, prints `if late thing.` (`test/scripts/dev-cycle.bats:71-80`), and the uncommitted `004-wip.md` prints via `git status --porcelain` (`:111`). But "counts at its merge" needs a merge commit: probe P4 (cwd `…/work/r4`) fast-forwarded a branch whose only commit (adding `003-ff.md`) was dated 2020-01-03; with no merge commit on the first-parent line inside the window, the digest printed `Carried forward (1): 003-ff.md`. This project's merge path is `git merge --no-ff` (workflows/pr-prep.md), so the common case holds. Precise version: "…counts at its merge commit; a fast-forward keeps the branch commit's date".

**Evidence:** `scripts/dev-cycle.sh:109-111`, `test/scripts/dev-cycle.bats:71-83`, `…/fc2-final2/logs/probe-out.txt` (P4)

---

## Claim 14: "prefer a capitalised "Revisit" (the trigger sentence) over an earlier "revisit-trigger verdicts" mention."

**Location:** `scripts/dev-cycle.sh:127-128`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the preference order and whole-clause capture to the cell's `|`; does not establish handling of a row whose trigger clause contains a literal `|`.

`text="$(grep -oE 'Revisit[^|]*' <<< "$row" | head -1 || true)"` then a case-insensitive fallback (`:129-130`); test 2 puts `revisit-trigger verdicts` in an earlier cell and asserts `log row 9 (2026-01-01): > Revisit if gizmos appear`…` end. ` (`test/scripts/dev-cycle.bats:55-61`).

**Evidence:** `scripts/dev-cycle.sh:127-131`, `test/scripts/dev-cycle.bats:50-62`

---

## Claim 15: "`open` prints "ID  route  slug" in columns of 2+ spaces; a route can contain one space ("you: judgment"), a slug can contain "trigger"."

**Location:** `scripts/dev-cycle.sh:149-150`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers questions.sh's current `open` format and the awk split on it; does not establish routes of 15+ characters (none exist in the grammar), where `%-14s` padding would still leave two spaces.

`printf '%s  %-14s  %s\n' "$id" "$route" "$slug"` (`scripts/questions.sh:412`) always emits at least two spaces between columns, and `awk -F'  +' '$2 == "trigger" || $2 == "deferred"'` (`scripts/dev-cycle.sh:151`) splits on 2+; test 9 uses slug `a-trigger-in-the-slug` and asserts only Q-002 lists and `agent=1, trigger=1` (`test/scripts/dev-cycle.bats:140-168`).

**Evidence:** `scripts/questions.sh:408-414`, `scripts/dev-cycle.sh:149-158`, `test/scripts/dev-cycle.bats:140-168`

---

## Claim 16: "Seeded by a hash of the date: same day, same merges; different days usually differ."

**Location:** `scripts/dev-cycle.sh:170-171`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers determinism per date and variation across dates as asserted by tests 6–7; does not establish statistical uniformity of the sample.

`seed="$(printf '%s' "$TODAY" | sha256sum | cut -c1-64)"; printf '%s\n' "$merges" | shuf -n "$SAMPLE" --random-source=<(yes "$seed")` (`:172-173`); tests 6 and 7 assert rerun equality and ≥2 distinct samples over four dates (`test/scripts/dev-cycle.bats:104-127`).

**Evidence:** `scripts/dev-cycle.sh:168-176`, `test/scripts/dev-cycle.bats:104-127`

---

## Claim 17: "Each test builds a throwaway repo under $BATS_TEST_TMPDIR; this repo is untouched." / "HOME in the temp dir: the ~/.claude/scripts fallback can't reach the real one."

**Location:** `test/scripts/dev-cycle.bats:3-4`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers repo creation, cwd and HOME isolation in setup; does not establish that the digest's own `.git/index` refresh (claim 4) cannot touch a repo — the tests only run it in their temp repos.

`R="$BATS_TEST_TMPDIR/repo"; make_repo "$R" main; cd "$R"` and `export HOME="$BATS_TEST_TMPDIR/home"` (`test/scripts/dev-cycle.bats:15-19`); the only use of `$REPO_ROOT` besides `DC` is `cp -r "$REPO_ROOT/scripts" "$BATS_TEST_TMPDIR/tools"` (`:131`), a read.

**Evidence:** `test/scripts/dev-cycle.bats:3-20`, `test/scripts/dev-cycle.bats:131`

---

## Claim 18: 3aee138 — "test/scripts/dev-cycle.bats: 13 hermetic tests; the regression tests fail on the pre-review version (89a3d3b)" and "this unit is 400"

**Location:** commit 3aee138 message
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test count, the size count at 3aee138, and that 3aee138's regression tests fail against 89a3d3b's script; does not establish that those failures are specific to the regressions (every test but the usage test fails there, largely on changed output wording).

`bats --count test/scripts/dev-cycle.bats` → `13`. `git diff --numstat main...3aee138 -- ':(top)' ':(top,exclude)docs/' | awk …` → `400`. Running 3aee138's bats file against `git show 89a3d3b:scripts/dev-cycle.sh` (cwd `…/fc2-final2/regr`, exit 1) gave `not ok` for tests 1–12 and `ok 13`; test 5's failure shows the unanchored window (`0 merge(s), 0 commit(s) on `main` in the window`), but test 1 fails on status alone, so the run does not isolate the regressions.

**Evidence:** `test/scripts/dev-cycle.bats:1-210`, `…/fc2-final2/logs/regr-89a3d3b.txt`

---

## Claim 19: 83e7895 — "Merge list: `sed -n '1,30p'` instead of `head -30`, which hit SIGPIPE under pipefail past ~64 KB of merges and exited 141 mid-digest."

**Location:** commit 83e7895 message; `scripts/dev-cycle.sh:93`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the old and new constructs in isolation with ~244 KB of input; does not establish the exact threshold (it depends on line length relative to the pipe buffer — a full-repo probe with 40 × 3 KB subjects did not trip it because head's 30 lines already consumed most of the input).

Probe Q1 ran the old line's shape under `set -euo pipefail` with 4,000 × 61-byte lines: `printf "%s\n" "$merges" | head -30` → output stopped after the opening fence, `old-construct exit=141`; the same with `sed -n "1,30p"` → `more`, closing fence, `reached-after`, `new-construct exit=0`. Current line: `printf '%s\n' "$merges" | sed -n '1,30p'` (`scripts/dev-cycle.sh:93`).

**Evidence:** `scripts/dev-cycle.sh:93`, `…/fc2-final2/logs/probe2-out.txt` (Q1), `…/fc2-final2/logs/probe-out.txt` (P6)

---

## Claim 20: 83e7895 — "control characters stripped from merge subjects"

**Location:** commit 83e7895 message; `scripts/dev-cycle.sh:88`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers sections 1 and 4 (both print `$merges`); does not establish stripping of any other printed repo text (records, log rows, roadmap, questions output are not filtered).

`| tr -d '\000-\010\013-\037\177'` (`:88`) keeps TAB (`\011`) and newline (`\012`). Probe P5 (subject `merge: evil\033[31mRED\ttab\rCR`): `od -c` of section 1 shows `e v i l [ 3 1 m R E D \t t a` — ESC and CR gone, TAB retained; section 4 had no ESC. Precise version: "control characters other than TAB stripped". Harmless in practice (the printable `[31m` residue is inert).

**Evidence:** `scripts/dev-cycle.sh:88`, `…/fc2-final2/logs/probe-out.txt` (P5)

---

## Claim 21: 83e7895 — remaining fix claims: "Uncommitted files show "never: uncommitted", not an empty date"; "--since must be a real date"; "DEV_CYCLE_TODAY pins the default window too"; "--sample=0 message"; "text quoted with "> ""; "future-dated cycle records ignored"; tests extended as listed; "Comments and section echoes compressed to stay within the 400-line unit cap (396)"

**Location:** commit 83e7895 message
**Type:** Behavioral / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed fix against the current script and tests; does not establish the carry-forward fix (claims 11, 13) or the SIGPIPE and control-character fixes (claims 19, 20).

All hold except one wording detail. Uncommitted decision records print `### $f (last committed ${d:-never: uncommitted})` (`:115`), but the uncommitted roadmap prints `docs/roadmap.md last committed ${d:-never (uncommitted)}` (`:181`; probe P8 output `last committed never (uncommitted)`), so "uncommitted files show 'never: uncommitted'" is true for records only; neither is empty. Real-date check: P2 `--since=2026-02-30` → exit 1; test 13 `2026-13-45` → exit 1. DEV_CYCLE_TODAY: P9 (claim 3). `--sample=0`: `echo "Sample size 0: no spot-check requested."` (`:175`). Quoting: `print "> " $0` (`:116`, `:183`) and `echo "- log row $n ($d): > $text"` (`:131`). Future-dated: `! "$d" > "$TODAY"` (`:68`), test 4. Tests extended: branch-merged (`003-late`), uncommitted (`004-wip`), SINCE-dated (log row 7 dated yesterday = SINCE) in test 3; capitalised Revisit in test 2; explicit --since in test 4; invalid date in test 13 (`test/scripts/dev-cycle.bats:50-94`, `:203-210`). Size: `git diff --numstat main...HEAD -- ':(top)' ':(top,exclude)docs/'` → `396`.

**Evidence:** `scripts/dev-cycle.sh:68`, `scripts/dev-cycle.sh:115-116`, `scripts/dev-cycle.sh:131`, `scripts/dev-cycle.sh:175`, `scripts/dev-cycle.sh:181-183`, `test/scripts/dev-cycle.bats:50-94`, `test/scripts/dev-cycle.bats:203-210`, `…/fc2-final2/logs/probe-out.txt` (P2, P8, P9)

---

## Claims Requiring Attention

### Incorrect
- **Claim 4** (`scripts/dev-cycle.sh:16-17`): "writes nothing to the repo" — the `git status` added by 83e7895 (`:111`) refreshes and rewrites `.git/index` under `index.lock` (executed: index hash changed; unchanged with `GIT_OPTIONAL_LOCKS=0` and with the 3aee138 script). Fix: `git --no-optional-locks status --porcelain -- "$f"`. New since the previous pass.
- **Claim 11** (`scripts/dev-cycle.sh:98`, selection at `:111`): run from a non-default branch, a decision record committed on that branch in the window is "carried forward" though no cycle has judged it (probe P3). Regression introduced by 83e7895; 3aee138 printed it (probe Q2). Fix: also treat a record as changed when HEAD's history touches it in the window, or when it differs from `$MAIN_SHA`.

### Stale
- None.

### Mostly Accurate
- **Claim 5** (`scripts/dev-cycle.sh:17-18`): a failed step exits with its own status (127 observed), not 1; empty `--since=` is accepted as "not given".
- **Claim 9** (`scripts/dev-cycle.sh:84`): trigger selection uses `$MAIN`'s history and "last committed" dates use HEAD's; only the text comes from the working tree.
- **Claim 13** (`scripts/dev-cycle.sh:109-110`): "counts at its merge" needs a merge commit; a fast-forwarded branch commit dated before the window is carried (probe P4).
- **Claim 20** (83e7895; `scripts/dev-cycle.sh:88`): TAB is kept; say "control characters other than TAB".
- **Claim 21** (83e7895): uncommitted roadmap prints "never (uncommitted)", records "never: uncommitted".

### Unverifiable
- **Claim 1** (`scripts/dev-cycle.sh:4-6`, `:185`): `skills/dev-cycle/SKILL.md` and its roadmap template are forward references to the stacked unit feat/dev-cycle.

---

## Goal-Alignment Note

- **Answered:** Every checkable claim in the scripts/test diff and in the three commit messages was verdicted; each listed fix from the previous pass was checked (carry-forward, explicit --since text, uncommitted date, SIGPIPE, window line, real-date check, DEV_CYCLE_TODAY, --sample=0, "> " quoting, control-character stripping, future-dated records, --help after compression). Two things the fixes broke were found and executed: the new `git status` writes `.git/index` (claim 4) and the new carry-forward rule drops branch-committed records (claim 11).
- **Out of scope:** I did not run scripts/health-check.sh or the full suite; the dev-cycle bats suite at HEAD was not re-run (only 3aee138's suite against 89a3d3b's script, in a copy). The not-a-git-repo exit path and the `$HOME/.claude/scripts` fallback were read, not run. Deferred override rows (file-level carry-forward cost, option-name test, SIGPIPE test, carried-list format) were not re-filed.
- **Escalate:** Claims 4 and 11 are both one-line fixes, but this is the loop's last allowed iteration. Whether they block merge or become deferred rows is the orchestrator's call. Claim 11 only affects runs from a non-default branch; claim 4 affects every run with a stale index, and matters in the shared /workspace checkout.
