Commit: 3aee138

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-digest (branch feat/dev-cycle-digest)
**Scope:** `git diff main...HEAD` (scripts/dev-cycle.sh, test/scripts/dev-cycle.bats) plus the commit message of 3aee138; final confirming pass (replicate r1)
**Checked:** 2026-09-29
**Total claims checked:** 34
**Summary:** 25 verified, 7 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first. No claim here matches a logged pattern, and neither Incorrect verdict is a fabrication, so the log is not updated.

All executed probes ran in throwaway repos under the session scratchpad (`.../scratchpad/fc1/`), each under `timeout`, cwd as stated in the log, with captured output under `docs/reviews/execution-logs/r1-digest-final-*.txt`. Each log opens with its ISO timestamp. No process outlived its command.

---

## Claim 1: "The dev-cycle skill (skills/dev-cycle/SKILL.md) runs the judgment steps … (scripts/questions.sh header; Q-074)"

**Location:** `scripts/dev-cycle.sh:4-8`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the three cited sources exist and say what is attributed to them; does not establish that the skill is present on this branch (it is a forward reference to the stacked unit).

`scripts/questions.sh:5-6` says: "this repo's own evidence is that an unenforced instruction does not execute". `docs/working/questions.md:67` holds `### Q-074 · failure-pattern-writer-trigger`. The skill file is absent from this branch but present on the stacked branch: `git show feat/dev-cycle:skills/dev-cycle/SKILL.md` line 33 reads "Run `~/.claude/scripts/dev-cycle.sh` from the repo root". The commit message states that these are forward references.

**Evidence:** `scripts/questions.sh:5-11`, `docs/working/questions.md:67`, `feat/dev-cycle:skills/dev-cycle/SKILL.md:33`

---

## Claim 2: "--since start of the cycle window (midnight, local time). Default: the date in the newest docs/working/cycles/cycle-YYYY-MM-DD.md, else 14 days ago. The digest says which."

**Location:** `scripts/dev-cycle.sh:12-14`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers midnight anchoring, newest-record selection, the 14-day fallback and the source note in the Window line. It does not establish that impossible dates are rejected (see Claim 11).

```bash
# scripts/dev-cycle.sh:72-87
for f in docs/working/cycles/cycle-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md; do
  ...
  [[ "$d" > "$last_record" ]] && last_record="$d"
...
  SINCE="$(date -d '14 days ago' +%F)"
...
SINCE_TS="$SINCE 00:00:00"
```

`--since=*` is parsed at `scripts/dev-cycle.sh:32`. The Window line at `:91` prints `$source_note`. The following were executed:
- bats test 4 (newest of two records chosen, "from the last cycle record")
- bats test 1 ("no cycle record found")
- bats test 5 (midnight)
- probe3: a bare `--since=2026-09-29` counted 0 of 2 commits dated today 00:00:30 and 01:00, and `"2026-09-29 00:00:00"` counted 2. A commit at exactly 00:00:00 is counted, so the lower bound is inclusive.

Command: `timeout 300 bats test/scripts/dev-cycle.bats`, cwd the worktree, exit 0, 2026-09-29T02:22:33-07:00. Command: `bash probe3.txt`, 2026-09-29T02:23:28-07:00, exit 0.

**Evidence:** `scripts/dev-cycle.sh:72-91`, docs/reviews/execution-logs/r1-digest-final-bats.txt, docs/reviews/execution-logs/r1-digest-final-probe3.txt

---

## Claim 3: "--sample how many merges to sample for the spot-check audit (default 2)."

**Location:** `scripts/dev-cycle.sh:15`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the default value and its use as `shuf -n`; does not establish behaviour when N exceeds the merge count (shuf then prints all merges, which is benign).

`scripts/dev-cycle.sh:28` reads `SAMPLE=2`, and `:184` reads `shuf -n "$SAMPLE"`.

**Evidence:** `scripts/dev-cycle.sh:28`, `scripts/dev-cycle.sh:180-184`

---

## Claim 4: "Acts on the git repo of $PWD (like questions.sh), so the installed copy at ~/.claude/scripts/dev-cycle.sh serves any project."

**Location:** `scripts/dev-cycle.sh:17-18`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers resolving the toplevel of $PWD and the install link. It does not establish identical out-of-repo behaviour: questions.sh falls back to $PWD, but this script exits 1 there, as its header documents.

`scripts/dev-cycle.sh:43-44`: `ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { ...; exit 1; }` then `cd "$ROOT"`. `devcontainer-config/link-claude-home.sh:50`: `ENTRIES=(skills workflows guides patterns hooks scripts CLAUDE.md)` links the whole `scripts/` directory into `~/.claude/`, so the installed path exists.

**Evidence:** `scripts/dev-cycle.sh:43-44`, `devcontainer-config/link-claude-home.sh:43-50`, `scripts/questions.sh:35-39`

---

## Claim 5: "Read-only: prints to stdout and writes nothing."

**Location:** `scripts/dev-cycle.sh:18-19`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every write site in the script. It does not establish that questions.sh `open` itself writes nothing (not re-audited here), or what git may write internally.

The script never writes into the repo. It does create one temporary file:

```bash
# scripts/dev-cycle.sh:156
  qs_err="$(mktemp)"; trap 'rm -f "$qs_err"' EXIT
```

The trap removes it on exit. Error text also goes to stderr (`:36`, `:39`, `:43`, `:69`, `:85`). A more precise wording would be: "writes nothing to the repo (one mktemp file for questions.sh's stderr, removed on exit)".

**Evidence:** `scripts/dev-cycle.sh:156`, `scripts/dev-cycle.sh:36-85`

---

## Claim 6: "Exit codes: 0 digest printed, 1 bad usage or not a git repo / no resolvable default branch."

**Location:** `scripts/dev-cycle.sh:19-20`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listed exit paths and one unlisted one found by execution. It does not enumerate every `set -e` failure path, such as a missing `shuf` or `sha256sum`.

The listed codes hold. Probe1 recorded exit 1 for each of: `--since` with no argument, `--sample=x`, running outside a repo, and an empty repo with no commits. `-h` exits 0.

The list is not exhaustive, though. The script runs under `set -euo pipefail` (`:25`), and Activity prints through a pipe into `head`:

```bash
# scripts/dev-cycle.sh:100
[[ -n "$merges" ]] && { echo; echo '```'; printf '%s\n' "$merges" | head -30; [[ "$n_merges" -gt 30 ]] && echo "… $((n_merges - 30)) more"; echo '```'; }
```

When the window's merge list exceeds the pipe buffer, `head` exits early and `printf` takes SIGPIPE. Pipefail then kills the script with exit 141. The digest stops after the opening fence and nothing goes to stderr. Probe6 reproduced these lines verbatim with 3,000 merge lines (184,892 bytes): output ended at the opening fence, and `exit=141`. For scale, this repo's full first-parent history is 385 merges and 27,801 bytes, which ran fine: `--since=2000-01-01`, exit 0. So the trigger is roughly 1,000 or more merges in the window, for example an old `--since` on a larger repo. Consuming the whole list, or using `sed -n 1,30p`, would avoid it.

Commands: `bash probe1.txt` (2026-09-29T02:22:55-07:00, exit 0) and `timeout 20 bash probe6.txt` (2026-09-29T02:27:17-07:00, exit 141).

**Evidence:** `scripts/dev-cycle.sh:25`, `scripts/dev-cycle.sh:100`, docs/reviews/execution-logs/r1-digest-final-probe1.txt, docs/reviews/execution-logs/r1-digest-final-probe6.txt

---

## Claim 7: "Resolved before the cd below, so a relative invocation path still works."

**Location:** `scripts/dev-cycle.sh:41`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers SCRIPT_DIR resolution for the questions.sh lookup. It does not cover `--help`, which still reads `"$0"` relatively but runs before the cd (`:35`), so it is also fine.

`scripts/dev-cycle.sh:42` reads `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` and comes before `cd "$ROOT"` at `:44`. bats test 8 passes. Mutation M9b moved the line after the cd, and test 8 then failed.

**Evidence:** `scripts/dev-cycle.sh:41-44`, docs/reviews/execution-logs/r1-digest-final-mutations.txt

---

## Claim 8: "DEV_CYCLE_TODAY exists only so tests can pin the date."

**Location:** `scripts/dev-cycle.sh:45`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the variable's uses in this unit; does not establish that no later caller sets it.

The variable's only read is `scripts/dev-cycle.sh:46`, `TODAY="${DEV_CYCLE_TODAY:-$(date +%F)}"`, and the only setter is `test/scripts/dev-cycle.bats:116` (`DEV_CYCLE_TODAY=$d bash "$DC"`). Established by grep.

**Evidence:** `scripts/dev-cycle.sh:46`, `test/scripts/dev-cycle.bats:116`

---

## Claim 9: "Resolve the default branch to a commit hash once, and pass only the hash to git afterwards. The name comes from origin/HEAD … a branch named like an option (`--output=<path>`) would otherwise reach `git log` as an option and truncate a file"

**Location:** `scripts/dev-cycle.sh:48-51`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every git call after resolution and hostile names tried by execution: `--output=<path>`, `-p`, origin/HEAD pointing at a missing ref, an option-like current branch, and a tag shadowing `main`. It does not establish that origin/HEAD's own target is used: the name is looked up only as a local `refs/heads/<name>`, so a repo with only `origin/main` falls through to the current branch (probe2 H6).

```bash
# scripts/dev-cycle.sh:57-61
for c in "${candidates[@]}"; do
  [[ "$c" == -* ]] && continue
  sha="$(git rev-parse --verify --quiet "refs/heads/$c^{commit}" 2>/dev/null || true)"
  if [[ -n "$sha" ]]; then MAIN="$c"; MAIN_SHA="$sha"; break; fi
done
```

After this block, `$MAIN` appears only in `echo` lines (`:91`, `:99`). Every git call takes `"$MAIN_SHA"` (`:95`, `:97`).

Executed checks:
- Test 12 passes.
- Probe2 H5: an option-like current branch `--output=<victim>` with no main or master gives exit 1, and the victim file still reads `keep`.
- Probe2 H2 (`-p`) and H7 (tag `main` alongside branch `main`) both resolve to the branch.
- Git itself refuses names with `*`, so glob names cannot be created (probe2 H3).
- Mutations: removing either defense layer alone leaves test 12 green (M13, M13b); removing both makes it fail (M13c). The test pins the two layers jointly.

**Evidence:** `scripts/dev-cycle.sh:52-69`, `scripts/dev-cycle.sh:95-97`, docs/reviews/execution-logs/r1-digest-final-probe2.txt, docs/reviews/execution-logs/r1-digest-final-mutations.txt

---

## Claim 10: "A repo on some other branch name: use the current branch." / error "tried origin/HEAD, main, master, the current branch"

**Location:** `scripts/dev-cycle.sh:63`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a repo on `trunk`, a detached HEAD and an empty repo. It does not establish which branch is chosen when HEAD sits on a feature branch while the real default exists only as a remote-tracking ref (the current branch is used).

`scripts/dev-cycle.sh:64-66`: `cur="$(git symbolic-ref --quiet --short HEAD ...)"` with `[[ -n "$cur" && "$cur" != -* ]]`. Probe2 H3 gave "on `trunk`" with exit 0. H4 (detached HEAD, no main or master) printed the documented error with exit 1. Probe1 (empty repo) printed the same error with exit 1.

**Evidence:** `scripts/dev-cycle.sh:62-69`, docs/reviews/execution-logs/r1-digest-final-probe2.txt, docs/reviews/execution-logs/r1-digest-final-probe1.txt

---

## Claim 11: "--since must be YYYY-MM-DD" (validation message) / usage `[--since=YYYY-MM-DD]`

**Location:** `scripts/dev-cycle.sh:85`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers shape validation. It does not establish date validity, and git's reading of out-of-range dates was observed, not specified.

`scripts/dev-cycle.sh:85` reads `[[ "$SINCE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]`. The check is on shape only. Probe7 passed `--since=2026-13-45`, `2026-02-30` and `9999-99-99`. All three printed a digest ("Window: since 9999-99-99"), and all three counted every commit, so an impossible date silently widens the window to all history. Test 13 covers only `2026/01/01`. The precise version is "must look like YYYY-MM-DD". Validating with `date -d "$SINCE"` would close the gap.

Command: `bash dev-cycle.sh --since=<d>` in scratch repo h7, 2026-09-29T02:27:33-07:00. The per-run exit code was not captured because of a pipe, but the digest printed.

**Evidence:** `scripts/dev-cycle.sh:85`, docs/reviews/execution-logs/r1-digest-final-probe7.txt

---

## Claim 12: "A bare date means "this time of day" to git; anchor it at midnight."

**Location:** `scripts/dev-cycle.sh:86-87`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git's reading of a date-only `--since` and the `00:00:00` fix. It does not establish DST-edge behaviour.

Probe3 at 02:23:28 local time: `bare --since=2026-09-29: 0` and `--since='2026-09-29 00:00:00': 2`. Mutation M6, which reverted to the bare date, fails test 5.

**Evidence:** `scripts/dev-cycle.sh:87`, docs/reviews/execution-logs/r1-digest-final-probe3.txt, docs/reviews/execution-logs/r1-digest-final-mutations.txt

---

## Claim 13: "N merge(s) on `$MAIN`'s first-parent line; M commit(s) reachable from it, merged branches included."

**Location:** `scripts/dev-cycle.sh:99`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the two counts on normally ordered history. It does not establish correct counts under committer-date skew: probe5, with a newest commit dated before the window, reported `0 merge(s) … 0 commit(s)` because git's `--since` stops walking. Branch commits dated before the window but merged inside it are also not counted.

`:95` runs `git log "$MAIN_SHA" --first-parent --merges --since="$SINCE_TS"`, and `:97` runs `git rev-list --count --since="$SINCE_TS" "$MAIN_SHA"`, which includes second parents. Test 1 checks "3 merge(s)". Test 5 checks the commit total. On this repo, `--since=2000-01-01` gave 385 merges and 1,884 commits with exit 0.

**Evidence:** `scripts/dev-cycle.sh:95-99`, docs/reviews/execution-logs/r1-digest-final-probe5.txt

---

## Claim 14: "Printed in full: triggers in decision records changed since $SINCE, and log rows dated on or after it. Listed by name only: the rest, whose verdict carries forward from docs/working/cycles/cycle-$last_record.md …"

**Location:** `scripts/dev-cycle.sh:107`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the full-vs-carried split for committed records and dated log rows, including both boundaries. It does not establish the carry-forward premise for records the cycle record never saw, as explained below.

```bash
# scripts/dev-cycle.sh:118-119, 132
  changed="$(git log -1 --since="$SINCE_TS" --format=%h -- "$f" 2>/dev/null || true)"
  if [[ $full -eq 1 || -n "$changed" ]]; then
...
    if [[ $full -eq 1 || ! "$d" < "$SINCE" ]]; then
```

The boundaries are correct. Probe4: a log row dated exactly on SINCE printed in full, and the row dated the day before was carried. Probe5: a record committed at exactly `SINCE 00:00:00` printed, and one at 23:59:59 the previous day was carried.

"Changed" means a *committed* change, however. A new decision record that is still uncommitted (probe4 `005-u.md`) goes into "Carried forward", and the cycle record cannot hold a verdict for it. The same happens under date skew (probe5). The precise text would read "committed in decision records changed since …".

Mutation M4 (`>=` changed to `>`) survives test 3, so the on-SINCE boundary is not pinned by any test.

**Evidence:** `scripts/dev-cycle.sh:105-147`, docs/reviews/execution-logs/r1-digest-final-probe4.txt, docs/reviews/execution-logs/r1-digest-final-probe5.txt

---

## Claim 15a: "No earlier cycle record to carry verdicts from" (printed whenever carry-forward is off)

**Location:** `scripts/dev-cycle.sh:110`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the message in the explicit-`--since` case. It does not concern the no-record case, where the message is true.

The branch condition has two clauses. The message states only one of them:

```bash
# scripts/dev-cycle.sh:105-110
if [[ -n "$last_record" && "$source_note" != "--since" ]]; then
  ...
else
  full=1
  echo "No earlier cycle record to carry verdicts from, so every trigger is printed in full."
```

Probe1 P2 set up a repo containing `docs/working/cycles/cycle-2026-09-01.md` and ran with `--since=2026-09-20`. The digest printed "No earlier cycle record to carry verdicts from". That statement is false: the record exists. An agent acting on it could conclude the previous cycle never recorded its verdicts. The message should branch, for example "--since given, so every trigger is printed in full."

Command: `bash probe1.txt`, 2026-09-29T02:22:55-07:00, exit 0.

**Evidence:** `scripts/dev-cycle.sh:105-111`, docs/reviews/execution-logs/r1-digest-final-probe1.txt

---

## Claim 15b: "so every trigger is printed in full" (and the brief's expectation that explicit `--since` prints everything in full)

**Location:** `scripts/dev-cycle.sh:110`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `full=1` forcing every record and log row to print. It does not establish the wording of the reason (Claim 15a).

`full=1` (`:109`) short-circuits both tests (`:119`, `:132`). In probe1 P2, record `001-a.md` printed in full with no "Carried forward" line.

**Evidence:** `scripts/dev-cycle.sh:109-132`, docs/reviews/execution-logs/r1-digest-final-probe1.txt

---

## Claim 16: "The whole revisit clause, to the end of its table cell. Prefer a capitalised "Revisit" (the trigger sentence) over a lowercase mention earlier in the row"

**Location:** `scripts/dev-cycle.sh:133-135`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the whole-cell extraction and the preference for the capitalised form. It does not establish correct output for a cell containing an escaped `\|`, or a row where a capitalised "Revisit" appears before the trigger sentence. Neither case is tested: mutation M2, which dropped the capitalised pass, still passes test 2.

```bash
# scripts/dev-cycle.sh:136-137
      text="$(grep -oE 'Revisit[^|]*' <<< "$row" | head -1 || true)"
      [[ -n "$text" ]] || text="$(grep -oiE 'revisit[^|]*' <<< "$row" | head -1)"
```

Test 2 passes with a clause longer than 500 characters. Mutation M1, which truncated output to 400 characters, fails it.

**Evidence:** `scripts/dev-cycle.sh:133-138`, docs/reviews/execution-logs/r1-digest-final-mutations.txt

---

## Claim 17: "`open` prints "ID  route  slug" in columns of 2+ spaces; a route can contain one space ("you: judgment"), a slug can contain "trigger"."

**Location:** `scripts/dev-cycle.sh:158-159`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers questions.sh's current `open` format and the awk split. It does not establish behaviour when `QUESTIONS_LIVE` points elsewhere: this script checks for `docs/working/questions.md` itself at `:155`.

`scripts/questions.sh:412` reads `printf '%s  %-14s  %s\n' "$id" "$route" "$slug"`. That is two literal spaces around a 14-wide route, and the longest route, "you: judgment", is 13 characters. Test 9 passes: a slug containing "trigger" is excluded. Mutation M10, a substring match, fails it.

**Evidence:** `scripts/questions.sh:408-414`, `scripts/dev-cycle.sh:160`, docs/reviews/execution-logs/r1-digest-final-mutations.txt

---

## Claim 18a: "Seeded by a hash of the date: same day, same merges … (The raw date seeded nothing: every date starts with the same bytes.)"

**Location:** `scripts/dev-cycle.sh:181-182`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers same-day determinism and the failure of the raw-date seed. It does not establish uniformity of the sample.

Probe4 S1 drew 3 of 20 lines. With `yes "$d"` as the source, all five dates gave `11,1,14`. With the sha256 seed, the five dates gave five different samples. Test 6 passes: a rerun gives the same sample. Mutation M7 (unseeded) failed test 6 in 6 of 7 trials, and the one pass was a 1-in-6 chance collision.

**Evidence:** `scripts/dev-cycle.sh:183-184`, docs/reviews/execution-logs/r1-digest-final-probe4.txt, docs/reviews/execution-logs/r1-digest-final-mutations.txt

---

## Claim 18b: "different days differ"

**Location:** `scripts/dev-cycle.sh:181`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the distribution of outcomes across days for a small window. It does not establish anything for large windows, where collisions are rare.

The seed differs by day, but the sample often does not. Probe4 S2 sampled 2 of 3 merges on each of 60 consecutive days: the outcomes were `a,b` 18 times, `a,c` 19 times and `b,c` 23 times. Two days coincide about a third of the time. The precise version is "different days usually differ". Test 7 asserts only that 2 or more of 4 dates differ, with 20 merges.

**Evidence:** `scripts/dev-cycle.sh:181-184`, docs/reviews/execution-logs/r1-digest-final-probe4.txt

---

## Claim 19: "docs/roadmap.md last changed … || echo 'never (uncommitted)'"

**Location:** `scripts/dev-cycle.sh:193`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the uncommitted-roadmap fallback. The same empty-date defect exists at `:121` for an uncommitted decision record, which has no fallback at all. This does not establish the committed case, which prints a date correctly.

```bash
# scripts/dev-cycle.sh:193
  echo "docs/roadmap.md last changed $(git log -1 --format=%ad --date=short -- docs/roadmap.md 2>/dev/null || echo 'never (uncommitted)'). Its Next section:"
```

`git log -- <untracked path>` exits 0 with empty output, so the `||` never fires. Probe1 P1, with an uncommitted roadmap, printed `docs/roadmap.md last changed . Its Next section:`. The fallback text is dead code, and the digest shows an empty date. A fix is to test for empty output (`d=$(git log …); ${d:-never (uncommitted)}`).

**Evidence:** `scripts/dev-cycle.sh:193`, `scripts/dev-cycle.sh:121`, docs/reviews/execution-logs/r1-digest-final-probe1.txt

---

## Claim 20: "No docs/roadmap.md yet — create it this cycle from the template in the dev-cycle skill."

**Location:** `scripts/dev-cycle.sh:197`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the template's existence on the stacked branch; does not establish it on this branch (forward reference).

`feat/dev-cycle:skills/dev-cycle/SKILL.md:93` reads "Update `docs/roadmap.md`, creating it from this template if missing:".

**Evidence:** `feat/dev-cycle:skills/dev-cycle/SKILL.md:91-96`

---

## Claim 21: "Each test builds a throwaway git repo under $BATS_TEST_TMPDIR, so nothing reads or writes this repo's own docs/."

**Location:** `test/scripts/dev-cycle.bats:4-5`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every test body. It does not claim, and it is not true, that the tests read nothing from the repo: test 8 copies `scripts/`.

`setup()` makes `$BATS_TEST_TMPDIR/repo` and cds into it (`:19-21`). The only read of the repo is `cp -r "$REPO_ROOT/scripts"` (`:125`), which is outside `docs/`.

**Evidence:** `test/scripts/dev-cycle.bats:9-22`, `test/scripts/dev-cycle.bats:125`

---

## Claim 22: "HOME points at the temp dir so the ~/.claude/scripts fallback can't reach the real installed questions.sh."

**Location:** `test/scripts/dev-cycle.bats:15-16`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the HOME fallback at `scripts/dev-cycle.sh:154`; does not cover the primary lookup, which uses the repo's own `scripts/questions.sh` by design.

`:17` reads `export HOME="$BATS_TEST_TMPDIR/home"`, and the fallback path is `"$HOME/.claude/scripts/questions.sh"` (`scripts/dev-cycle.sh:154`).

**Evidence:** `test/scripts/dev-cycle.bats:17`, `scripts/dev-cycle.sh:153-154`

---

## Claim 23: "a window starting at midnight must count them all (a bare date would mean "today at the current time" to git and count none of them)."

**Location:** `test/scripts/dev-cycle.bats:90-92`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git semantics as run at 02:23 local time. It does not establish the test's behaviour when run within 30 seconds after midnight: the 00:00:30 commit is then in the future but is still counted, so the test stays correct.

Probe3 shows 0 counted with the bare date and all counted with midnight. Mutation M6 fails the test.

**Evidence:** `test/scripts/dev-cycle.bats:88-96`, docs/reviews/execution-logs/r1-digest-final-probe3.txt

---

## Claim 24: "No questions-archive.md: questions.sh open exits non-zero."

**Location:** `test/scripts/dev-cycle.bats:167`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the missing-archive path of `cmd_open`; does not cover other questions.sh failure modes.

`scripts/questions.sh:409` calls `require_files`, and `:137` reads `[[ $missing -eq 0 ]] || die "no questions doc here …"`. Test 10 passes. Mutation M11, which swallowed the failure, fails it.

**Evidence:** `scripts/questions.sh:132-137`, `scripts/questions.sh:408-409`, docs/reviews/execution-logs/r1-digest-final-mutations.txt

---

## Claim 25: The 13 test names, read as claims that each test fails when its named behaviour breaks

**Location:** `test/scripts/dev-cycle.bats:39-202`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 19 single-point mutations of scratch copies, at least one per test. It does not establish full mutation coverage.

paraphrased — no quote available because the evidence is a mutation table spanning 13 tests; see the log.

Twelve of the 13 names are pinned by at least one mutation that the named test catches (M1, M3, M5, M6, M7, M8, M9b, M10, M11, M13c, M14, M15, M16). The gaps:
- Test 2's name promises the "whole revisit clause", which is pinned, but the capitalised-over-lowercase fix from pass 1 is not (M2 survives).
- Test 3 does not pin the on-SINCE log-row boundary (M4 survives).
- Test 11 ("only branch is master works") still passes with `master` removed from the candidates (M12), because the current-branch fallback covers it. The name stays true, but the master candidate itself is unpinned.
- Test 12 catches only the removal of both defense layers (M13c), not either one alone.

**Evidence:** `test/scripts/dev-cycle.bats:52-79`, `test/scripts/dev-cycle.bats:175-195`, docs/reviews/execution-logs/r1-digest-final-mutations.txt

---

## Claim 26: "test/scripts/dev-cycle.bats: 13 hermetic tests"

**Location:** commit 3aee138 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers count, pass status and isolation. It does not establish date-independence: the tests use the real clock, which is safe for their assertions.

`bats --count test/scripts/dev-cycle.bats` printed `13`. The full file ran 13 of 13 ok with exit 0 (2026-09-29T02:22:33-07:00). Isolation comes from `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1` and a temp HOME and repo (`test/scripts/dev-cycle.bats:12-21`).

**Evidence:** `test/scripts/dev-cycle.bats:12-21`, docs/reviews/execution-logs/r1-digest-final-bats.txt

---

## Claim 27: "the regression tests fail on the pre-review version (89a3d3b)"

**Location:** commit 3aee138 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the HEAD test file run against `89a3d3b:scripts/dev-cycle.sh` with HEAD's questions.sh. It does not separate "fails on the regression" from "fails on changed wording" for tests 1 and 4.

`cd scratch/old && timeout 300 bats test/scripts/dev-cycle.bats` ran at 2026-09-29T02:23:36-07:00. Tests 1–5, 7, 8 and 10–12 failed. Tests 6, 9 and 13 passed; those are not regression tests. The failure reasons checked were: test 10 showed `None open.`, test 11 exited non-zero, and test 12 printed `victim file was modified`.

**Evidence:** docs/reviews/execution-logs/r1-digest-final-old-89a3d3b.txt

---

## Claim 28: "It resolves the default branch to a hash before passing it to git (an option-like branch name cannot reach git as an option)"

**Location:** commit 3aee138 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 9.

See Claim 9: `scripts/dev-cycle.sh:59` `git rev-parse --verify --quiet "refs/heads/$c^{commit}"`, plus probe2 H2/H5 and test 12.

**Evidence:** `scripts/dev-cycle.sh:52-69`, docs/reviews/execution-logs/r1-digest-final-probe2.txt

---

## Claim 29: "anchors --since at midnight, reports a questions.sh failure instead of hiding it, and works from any subdirectory and on master-only repos"

**Location:** commit 3aee138 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four behaviours as exercised by tests 5, 10, 8 and 11 and by probe3. It does not establish detached-HEAD support, which exits 1 by design (Claim 10).

`scripts/dev-cycle.sh:87` reads `SINCE_TS="$SINCE 00:00:00"`, and `:169` reads `echo "**questions.sh open failed** — watched questions were NOT checked. Its error:"`. `:42` resolves SCRIPT_DIR before the cd, and `:56` reads `candidates+=(main master)`. All four tests pass at HEAD and fail at 89a3d3b.

**Evidence:** `scripts/dev-cycle.sh:42`, `scripts/dev-cycle.sh:56`, `scripts/dev-cycle.sh:87`, `scripts/dev-cycle.sh:169`, docs/reviews/execution-logs/r1-digest-final-bats.txt

---

## Claim 30: "revisit triggers needing a verdict (records changed and log rows dated in the window print in full; the rest carry forward)"

**Location:** commit 3aee138 message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 14. It does not mention that an explicit `--since` disables carry-forward (Claim 15b).

Accurate for committed changes. An uncommitted new record, or a skewed history, goes to "carried forward" with no verdict to carry. See Claim 14 for the quoted lines `scripts/dev-cycle.sh:118-119` and the probes.

**Evidence:** `scripts/dev-cycle.sh:118-132`, docs/reviews/execution-logs/r1-digest-final-probe4.txt

---

## Claim 31: "the combined unit was 531 code lines (cap 400); this unit is 400."

**Location:** commit 3aee138 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pr-prep 1a count, which excludes `docs/` and measures against merge-base `4225753`, the same as main. It does not establish which commit "the combined unit" meant beyond the match below.

`git diff --numstat main...HEAD -- ':(top)' ':(top,exclude)docs/' | awk …` gives 400 (198 + 202). The same count at `d8b0cca` (the pass-1 fix commit on feat/dev-cycle) gives 531. The later `3268a5e` gives 529.

**Evidence:** `scripts/dev-cycle.sh:1-198`, `test/scripts/dev-cycle.bats:1-202`

---

## Claim 32: "The script's references to the skill are forward references until then."

**Location:** commit 3aee138 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two skill references (`:4`, `:197`); does not establish when the stacked unit lands.

`skills/dev-cycle/` is absent at HEAD and present on `feat/dev-cycle` (see Claims 1 and 20).

**Evidence:** `scripts/dev-cycle.sh:4`, `scripts/dev-cycle.sh:197`

---

## Claims Requiring Attention

### Incorrect
- **Claim 15a** (`scripts/dev-cycle.sh:110`): when `--since` is given and a cycle record exists, the digest says "No earlier cycle record to carry verdicts from". The record exists. Branch the message on the actual reason.
- **Claim 19** (`scripts/dev-cycle.sh:193`): the `|| echo 'never (uncommitted)'` fallback never fires, because `git log` on an untracked path exits 0 with empty output. The digest prints "last changed ." The same empty date appears at `:121` for uncommitted decision records.

### Stale
- None.

### Mostly Accurate
- **Claim 5** (`scripts/dev-cycle.sh:18-19`): "writes nothing" should be "writes nothing to the repo". The script creates a mktemp file, removed on exit.
- **Claim 6** (`scripts/dev-cycle.sh:19-20`): the exit-code list is not exhaustive. With a large window (over 64 KB of merge lines) the script dies with exit 141 mid-digest and prints nothing to stderr (`printf | head -30` under pipefail, `:100`).
- **Claim 11** (`scripts/dev-cycle.sh:85`): validation is shape-only. `9999-99-99` and `2026-13-45` are accepted, and the window silently becomes all history.
- **Claim 14** (`scripts/dev-cycle.sh:107`) and **Claim 30** (commit message): "changed since" means "committed since". Uncommitted new records, and records on skewed history, land in "carried forward" with no verdict to carry.
- **Claim 18b** (`scripts/dev-cycle.sh:181`): "different days differ" should be "usually differ". With 3 merges and a sample of 2, days coincide about a third of the time.
- **Claim 25** (`test/scripts/dev-cycle.bats`): three pinning gaps. The capitalised-"Revisit" preference is untested (M2). The on-SINCE log-row boundary is untested (M4). Test 12 does not catch either defense layer removed alone (M13, M13b).

### Unverifiable
- None.

---

## Goal-Alignment Note
- **Answered:** I checked every claim in the header comments, the in-code comments that make claims, the key output strings, the test comments and names, and the commit message. Every executable guarantee was run. Pass-1 fixes that hold: option-name resolution, midnight anchor, whole-cell log clause, questions.sh failure reporting, master-only and subdirectory runs, the hash seed, and carry-forward. Hostile names tried: `-p`, `--output=<path>`, glob names (git refuses them), origin/HEAD pointing at a missing ref, detached HEAD, an empty repo, an option-like current branch, and a tag shadowing main. Boundaries tried: a row dated exactly on SINCE, a record committed exactly at midnight, and explicit `--since`. Mutation results are in Claim 25.
- **Out of scope:** I did not re-audit questions.sh internals beyond `open`'s format and missing-file exit. I did not test DST edges. I ran neither the full suite nor health-check.sh, per the brief.
- **Escalate:** two Incorrect items, both low-severity output-text defects: Claim 15a's misleading carry-forward message under `--since`, and Claim 19's dead `never (uncommitted)` fallback. One behavioural edge the orchestrator may want triaged as Must Address vs Consider: Claim 6, exit 141 with a truncated digest when the window holds more than ~64 KB of merges.
