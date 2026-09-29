Commit: 3aee138

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-digest (branch feat/dev-cycle-digest)
**Scope:** `git diff main...HEAD`: scripts/dev-cycle.sh, test/scripts/dev-cycle.bats, and the commit message of 3aee138 (final confirming pass, replicate r2)
**Checked:** 2026-09-29
**Total claims checked:** 26
**Summary:** 22 verified, 3 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable (24 numbered claims; 13 and 15 are each split into an a/b pair and counted as two)

Execution provenance. Every executed probe ran under `timeout`, in throwaway repos under the scratchpad `/tmp/claude-1000/-workspace/fba1bfc0-301f-41fe-8500-89690af4d400/scratchpad/fc2` (called `$FC2` below), with `GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_NOSYSTEM=1` and `HOME=$FC2/home`. Probe scripts are saved as `$FC2/probe{1,2,3}.txt`. Every run exited 0 and left no processes behind.

| Run | Command (cwd) | Exit | Time | Output |
|---|---|---|---|---|
| E1 | `timeout 300 bats test/scripts/dev-cycle.bats` (cwd `$FC2/new`, HEAD's script) | 0 | 2026-09-29T02:23:19-07:00 | `$FC2/logs/bats-new.log` |
| E2 | same (cwd `$FC2/old`, script from `git show 89a3d3b:scripts/dev-cycle.sh`, HEAD's tests) | 1 | 2026-09-29T02:23:19-07:00 | `$FC2/logs/bats-old.log` |
| E3 | `timeout 200 bash probe1.txt` (cwd `$FC2`): help, exit codes, hostile branch names, temp-file cleanup | 0 | 2026-09-29T02:24:05-07:00 | `$FC2/logs/probe1.log` |
| E4 | `timeout 200 bash probe2.txt` (cwd `$FC2`), TZ=America/New_York: midnight window, carry-forward boundaries, explicit --since, default window | 0 | 2026-09-29T02:24:43-07:00 | `$FC2/logs/probe2.log` |
| E5 | `timeout 200 bash probe3.txt` (cwd `$FC2`): record committed exactly at midnight in a monotonic history; old vs new seed | 0 | 2026-09-29T02:25:11-07:00 | `$FC2/logs/probe3.log` |
| E6 | `timeout 300 bats test/scripts/dev-cycle.bats` on three mutated scratch copies m6/m9/m13 (cwd `$FC2/m*`) | 1 each (expected) | 2026-09-29T02:26:12-07:00 | `$FC2/logs/bats-m6.log`, `bats-m9.log`, `bats-m13.log` |
| E7 | `git diff --numstat main...<rev> -- ':(top)' ':(top,exclude)docs/' \| awk '{n+=$1+$2} END{print n}'` for HEAD, d8b0cca and 3268a5e (cwd worktree, read-only) | 0 | 2026-09-29T02:22-07:00 | inline in this report (400 / 531 / 529); read-only git queries |

Hallucination-pattern log: read. Its recurring class is a specific measured count quoted from an artifact set that does not contain it. The commit message makes three such claims (13 tests, 531 lines, 400 lines). All three were recomputed (claims 23 and 24) and none matches the pattern.

---

## Claim 1: "The dev-cycle skill (skills/dev-cycle/SKILL.md) runs the judgment steps — health triage, revisit-trigger verdicts, spot-check audits, brainstorming, roadmap updates — on top of this digest."

**Location:** `scripts/dev-cycle.sh:4-6`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the file's existence and description on the stacked branch feat/dev-cycle (3268a5e). Does not establish that the file exists at HEAD 3aee138 (it does not; this is a declared forward reference), or that the stacked unit will merge unchanged.

`ls skills/dev-cycle` at HEAD fails: "No such file or directory". The commit message declares the forward reference: "The script's references to the skill are forward references until then." On feat/dev-cycle, `skills/dev-cycle/SKILL.md:4` reads "Run one maintenance cycle: health and cleanup, revisit triggers, spot-check audit, brainstorm, roadmap." That matches the steps the comment lists.

**Evidence:** `scripts/dev-cycle.sh:4-6`, `feat/dev-cycle:skills/dev-cycle/SKILL.md:4`

---

## Claim 2: "this repo's evidence is that steps only prose asks for do not run (scripts/questions.sh header; Q-074)"

**Location:** `scripts/dev-cycle.sh:7-8`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two cited sources existing and saying this. Does not establish the general claim beyond what those sources measure.

`scripts/questions.sh:5-8`: "this repo's own evidence is that an unenforced instruction does not execute — docs/thoughts/failure-patterns.md holds 0 entries against 104 eligible fix commits … both because only prose asked for them." `docs/working/questions.md:67-71` (Q-074): "`docs/thoughts/failure-patterns.md` has gained 1 entry across about 128 `fix` commits. The writer is still pr-prep Step 0, a workflow step that is advisory only."

**Evidence:** `scripts/questions.sh:5-8`, `docs/working/questions.md:67-71`

---

## Claim 3: "--since   start of the cycle window (midnight, local time). Default: the date in the newest docs/working/cycles/cycle-YYYY-MM-DD.md, else 14 days ago. The digest says which."

**Location:** `scripts/dev-cycle.sh:12-14`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers local-midnight inclusivity, the newest-record default (newest by the date in the filename, not by mtime), the 14-day fallback, and the printed source note. Does not establish that the 14-day fallback follows `DEV_CYCLE_TODAY` (it does not; it uses the real clock; see claim 9), or behaviour with out-of-order committer dates (claim 13a).

Code: `SINCE="$last_record"; source_note="the last cycle record, …"` / `SINCE="$(date -d '14 days ago' +%F)"` (`scripts/dev-cycle.sh:79-83`), and `SINCE_TS="$SINCE 00:00:00"` (`:87`). In E4 (TZ=America/New_York) there were commits at 03-09 23:59:59, 03-10 00:00:00 and 03-10 00:00:01. `--since=2026-03-10` counted "2 commit(s)": the midnight commit is included and the previous-day commit is not. The same repo under TZ=UTC counted 3, which confirms the window is local time. Test 4 ("Window: since 2026-02-10 (from the last cycle record") passes in E1. E3 shows the fallback line: "Window: since 2026-09-15 (from no cycle record found, so the default of 14 days …)", and 2026-09-15 is 14 days before the run date.

**Evidence:** `scripts/dev-cycle.sh:71-87`, `$FC2/logs/probe2.log` (P20, P20b), `$FC2/logs/probe1.log` (P5), `$FC2/logs/bats-new.log` (ok 4)

---

## Claim 4: "--sample  how many merges to sample for the spot-check audit (default 2)."

**Location:** `scripts/dev-cycle.sh:15`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the default value and that N lines are printed. Does not establish behaviour when N is larger than the number of merges (by code reading, `shuf -n` then prints them all).

`SAMPLE=2` (`scripts/dev-cycle.sh:28`) feeds `shuf -n "$SAMPLE"` (`:184`). Test 6 ("--sample N lists N merges") passes in E1.

**Evidence:** `scripts/dev-cycle.sh:28`, `scripts/dev-cycle.sh:184`, `$FC2/logs/bats-new.log` (ok 6)

---

## Claim 5: "Acts on the git repo of $PWD (like questions.sh), so the installed copy at ~/.claude/scripts/dev-cycle.sh serves any project."

**Location:** `scripts/dev-cycle.sh:17-18`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the repo resolution and that the install links the whole `scripts/` directory. Does not establish that a host has actually run the installer.

`ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" … cd "$ROOT"` (`scripts/dev-cycle.sh:43-44`) resolves from `$PWD`. `ENTRIES=(skills workflows guides patterns hooks scripts CLAUDE.md)` (`devcontainer-config/link-claude-home.sh:50`) links `scripts/` into `~/.claude`. The questions.sh fallback `QS="$SCRIPT_DIR/questions.sh"` (`scripts/dev-cycle.sh:153`) then finds its sibling in the installed copy.

**Evidence:** `scripts/dev-cycle.sh:43-44`, `scripts/dev-cycle.sh:153-154`, `devcontainer-config/link-claude-home.sh:50`

---

## Claim 6: "Read-only: prints to stdout and writes nothing."

**Location:** `scripts/dev-cycle.sh:18-19`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the repo (nothing is written there) and the one temp file. Does not establish removal of the temp file if the process is SIGKILLed while section 3 runs.

The one write is `qs_err="$(mktemp)"; trap 'rm -f "$qs_err"' EXIT` (`scripts/dev-cycle.sh:156`). It creates a file in `$TMPDIR`, and the EXIT trap removes it. In E3 (P11), with TMPDIR set to an empty scratch directory, the directory held 0 files after a full run and 0 files after a run whose stdout was cut off by `head -1`. Errors go to stderr, not stdout (e.g. `:36`, `:69`). The precise wording: it writes nothing to the repo, and only a self-removing temp file elsewhere.

**Evidence:** `scripts/dev-cycle.sh:156`, `$FC2/logs/probe1.log` (P11)

---

## Claim 7: "Exit codes: 0 digest printed, 1 bad usage or not a git repo / no resolvable default branch."

**Location:** `scripts/dev-cycle.sh:19-20`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every enumerated case that was probed: help, missing argument values, a bad --sample, a bad --since, an unknown option, not a git repo, an empty repo, a detached HEAD, and an option-like current branch. Does not establish the exit code when an unexpected command fails under `set -e` (e.g. a missing `shuf`/`sha256sum`, or git erroring). Those give the failing command's status, not 1.

In E3: `--since` with no value gives exit 1 (`${2:?…}`), `--sample` with no value gives 1, `--sample=x` gives 1, a non-git directory gives 1, and an empty repo gives 1 with "Could not resolve a default branch (tried origin/HEAD, main, master, the current branch)". Help gives 0. Test 13 (malformed --since, unknown option → 1) passes in E1.

**Evidence:** `scripts/dev-cycle.sh:29-39`, `scripts/dev-cycle.sh:43`, `scripts/dev-cycle.sh:69`, `scripts/dev-cycle.sh:85`, `$FC2/logs/probe1.log` (P1-P4, P7, P8)

---

## Claim 8: "Resolved before the cd below, so a relative invocation path still works."

**Location:** `scripts/dev-cycle.sh:41-42`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers invocation by a relative path from a subdirectory. Does not establish invocation through a symlink to the script (`BASH_SOURCE` gives the link's directory, and `pwd` does not resolve it).

`SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` (`:42`) runs before `cd "$ROOT"` (`:44`). Test 8 passes in E1 and fails on 89a3d3b in E2.

**Evidence:** `scripts/dev-cycle.sh:42-44`, `$FC2/logs/bats-new.log` (ok 8), `$FC2/logs/bats-old.log` (not ok 8)

---

## Claim 9: "DEV_CYCLE_TODAY exists only so tests can pin the date."

**Location:** `scripts/dev-cycle.sh:45`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the variable controls. Does not establish anything about production use.

`TODAY="${DEV_CYCLE_TODAY:-$(date +%F)}"` (`:46`) feeds only the title (`:89`) and the seed (`:183`). The 14-day default window uses the real clock: `SINCE="$(date -d '14 days ago' +%F)"` (`:82`). In E4 (P23), `DEV_CYCLE_TODAY=2020-01-01` printed "# Dev-cycle digest — 2020-01-01" and "Window: since 2026-09-15". The precise version: it pins the title and the spot-check seed, not the default window.

**Evidence:** `scripts/dev-cycle.sh:46`, `scripts/dev-cycle.sh:82`, `scripts/dev-cycle.sh:183`, `$FC2/logs/probe2.log` (P23)

---

## Claim 10: "Resolve the default branch to a commit hash once, and pass only the hash to git afterwards. … a branch named like an option (`--output=<path>`) would otherwise reach `git log` as an option and truncate a file"

**Location:** `scripts/dev-cycle.sh:48-51`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the origin/HEAD path, names starting with `-`, the current-branch fallback, and the claim that only `$MAIN_SHA` reaches git. Does not establish that other repo-controlled strings are safe: file paths go after `--` or into `awk`, which was read but not fuzzed.

`sha="$(git rev-parse --verify --quiet "refs/heads/$c^{commit}" …)"` after `[[ "$c" == -* ]] && continue` (`:58-59`). Later git calls use `"$MAIN_SHA"` (`:95`, `:97`). `$MAIN` is only echoed (`:91`, `:99`). Test 12 passes in E1, and in E2 on 89a3d3b it fails with "victim file was modified". So the attack was real before the fix and is blocked now. E3: origin/HEAD pointing to `-p` falls back to "on `main`" (exit 0). An option-like *current* branch `--output=…` with no main/master exits 1 and the victim still reads "keep". A dangling origin/HEAD falls back to main. Names with spaces or glob characters cannot exist: `git update-ref 'refs/heads/a b'` gives "refusing to update ref with bad name".

**Evidence:** `scripts/dev-cycle.sh:52-69`, `scripts/dev-cycle.sh:95-97`, `$FC2/logs/bats-old.log` (not ok 12), `$FC2/logs/bats-new.log` (ok 12), `$FC2/logs/probe1.log` (P5, P6, P8, P10)

---

## Claim 11: "A repo on some other branch name: use the current branch."

**Location:** `scripts/dev-cycle.sh:63`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a repo with only a `trunk` branch checked out. Does not establish the case where a non-default branch is checked out and main/master are absent but the true default is another local branch: the digest then reports on whatever is checked out.

`cur="$(git symbolic-ref --quiet --short HEAD …)"; if [[ -n "$cur" && "$cur" != -* ]]; then MAIN="$cur"` (`:64-66`). E3 (P9): "on `trunk` at fa2e741", exit 0. With a detached HEAD (P7) the script exits 1, as claim 7 says.

**Evidence:** `scripts/dev-cycle.sh:62-69`, `$FC2/logs/probe1.log` (P7, P9)

---

## Claim 12: "A bare date means "this time of day" to git; anchor it at midnight."

**Location:** `scripts/dev-cycle.sh:86-87`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git's reading of a bare date and the midnight anchor for `git log --since`/`rev-list --since`. Does not establish anything about the `[[ "$d" < "$SINCE" ]]` string comparison for log rows, which uses no time of day at all.

In E2, the pre-fix script (bare date) printed "0 merge(s), 0 commit(s) on `main` in the window" for `--since=<today>` where 8 commits existed today. At HEAD, test 5 passes (E1), and E4 shows midnight inclusivity.

**Evidence:** `scripts/dev-cycle.sh:87`, `$FC2/logs/bats-old.log` (not ok 5, "expected 8"), `$FC2/logs/probe2.log` (P20)

---

## Claim 13a: printed "Printed in full: triggers in decision records changed since $SINCE, … Listed by name only: the rest, whose verdict carries forward from docs/working/cycles/cycle-$last_record.md" (the decision-record half)

**Location:** `scripts/dev-cycle.sh:107`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers records whose last commit is on or after SINCE midnight (printed) and before it (carried), in a monotonic history. Does not establish handling of uncommitted work: an untracked new record, or an uncommitted edit, is carried forward. It also does not establish handling of out-of-order committer dates at the tip, where git's `--since` walk can stop early.

"Changed" is measured by `changed="$(git log -1 --since="$SINCE_TS" --format=%h -- "$f" …)"` (`:118`), i.e. committed at or after midnight. E5 (P24/P25), monotonic history: a record committed at exactly 2026-03-10 00:00:00 with cycle-2026-03-10.md present printed in full, and records committed 03-09 23:59:59 and 03-01 were carried. The boundary is right. E4 (P21): an untracked new `004-d.md` and an uncommitted edit to `001-a.md` were both listed under "Carried forward (5): 001-a.md 002-b.md 003-c.md 004-d.md log row 5". For 004-d.md, "whose verdict carries forward" has no earlier verdict to point to. In the same P21 repo, a record committed at exactly midnight was also carried, because the branch tip had an older committer date (an artificial history) and git stopped walking. The precise version: "records *committed* since $SINCE". A working-tree-only record should either print or be flagged.

**Evidence:** `scripts/dev-cycle.sh:113-126`, `$FC2/logs/probe2.log` (P21), `$FC2/logs/probe3.log` (P24, P25)

---

## Claim 13b: printed "… and log rows dated on or after it" (the log-row half)

**Location:** `scripts/dev-cycle.sh:107`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers rows whose date cell is well-formed YYYY-MM-DD. Does not establish rows with a malformed or empty date cell: those compare below SINCE and are carried silently.

`if [[ $full -eq 1 || ! "$d" < "$SINCE" ]]` (`:132`) means d ≥ SINCE. E4 (P21): the row dated 2026-03-10 (equal to SINCE) printed "- log row 6 (2026-03-10): Revisit if row-on-since.", and the row dated 03-09 was carried. Test 3 (row 2099 prints, row 2020 carried) passes in E1.

**Evidence:** `scripts/dev-cycle.sh:127-143`, `$FC2/logs/probe2.log` (P21), `$FC2/logs/bats-new.log` (ok 3)

---

## Claim 14: printed "No earlier cycle record to carry verdicts from, so every trigger is printed in full." (no-record case)

**Location:** `scripts/dev-cycle.sh:110`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the case where no `cycle-*.md` exists. Does not cover the explicit-`--since` case, which prints the same sentence (claim 15b).

The `else` branch of `if [[ -n "$last_record" && "$source_note" != "--since" ]]` (`:105`) sets `full=1`. Tests 1 and 2 run with no record and print every trigger (E1 ok 1, ok 2).

**Evidence:** `scripts/dev-cycle.sh:105-111`, `$FC2/logs/bats-new.log`

---

## Claim 15a: explicit `--since` prints every trigger in full (brief's stated intent)

**Location:** `scripts/dev-cycle.sh:105`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the full-print behaviour when --since is given and a cycle record exists. Does not cover the explanatory sentence printed alongside it (claim 15b).

E4 (P22), with cycle-2026-03-10.md present and `--since=2026-03-10`: all four records and both log rows were printed, and nothing was carried.

**Evidence:** `scripts/dev-cycle.sh:105`, `$FC2/logs/probe2.log` (P22)

---

## Claim 15b: printed "No earlier cycle record to carry verdicts from" when `--since` is given and a cycle record exists

**Location:** `scripts/dev-cycle.sh:110`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reason the digest prints in the explicit-`--since` case. Does not affect which triggers print (claim 15a is right). The impact is limited to a false statement in the output.

The condition that selects this sentence is `[[ -n "$last_record" && "$source_note" != "--since" ]]` (`:105`). The else branch also fires when a record exists but `--since` was passed. E4 (P22) printed "No earlier cycle record to carry verdicts from, so every trigger is printed in full." while `docs/working/cycles/cycle-2026-03-10.md` existed. The stated reason is false in this case. An agent reading it may conclude the previous cycle wrote no record. The same run's Window line says "(from --since)" rather than naming the record. Fix: give the --since case its own sentence (e.g. "--since given, so every trigger is printed in full.").

**Evidence:** `scripts/dev-cycle.sh:105-111`, `$FC2/logs/probe2.log` (P22)

---

## Claim 16: "The whole revisit clause, to the end of its table cell. Prefer a capitalised "Revisit" (the trigger sentence) over a lowercase mention earlier in the row, such as "revisit-trigger verdicts"."

**Location:** `scripts/dev-cycle.sh:133-135`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the capitalised-first preference and whole-cell extraction (no length cut). Does not establish the right choice when a capitalised "Revisit" appears earlier in the row than the trigger sentence (the first capitalised match wins), or triggers phrased without the word "revisit" (such rows are not selected at all, `:142`).

`text="$(grep -oE 'Revisit[^|]*' <<< "$row" | head -1 || true)"` then a case-insensitive fallback (`:136-137`). Test 2, with a 500-character clause ending " end. ", passes in E1 and fails on 89a3d3b in E2.

**Evidence:** `scripts/dev-cycle.sh:132-142`, `$FC2/logs/bats-new.log` (ok 2), `$FC2/logs/bats-old.log` (not ok 2)

---

## Claim 17: "`open` prints "ID  route  slug" in columns of 2+ spaces; a route can contain one space ("you: judgment"), a slug can contain "trigger"."

**Location:** `scripts/dev-cycle.sh:158-159`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers questions.sh's `open` format and the route-column filter. Does not establish slugs that contain two consecutive spaces (the grammar's slug form makes these unlikely; not probed).

`printf '%s  %-14s  %s\n' "$id" "$route" "$slug"` (`scripts/questions.sh:412`). The longest route, "you: judgment"/"you: terminal", is 13 characters, so two or more spaces always follow it. The filter is `awk -F'  +' '$2 == "trigger" || $2 == "deferred"'` (`scripts/dev-cycle.sh:160`). Test 9 (slug "a-trigger-in-the-slug" excluded; "agent=1, trigger=1") passes in E1. Mutating the filter to `grep -E 'trigger|deferred'` fails test 9 (E6, m9).

**Evidence:** `scripts/questions.sh:408-414`, `scripts/dev-cycle.sh:160-167`, `$FC2/logs/bats-new.log` (ok 9), `$FC2/logs/bats-m9.log`

---

## Claim 18: "Seeded by a hash of the date: same day, same merges; different days differ. (The raw date seeded nothing: every date starts with the same bytes.)"

**Location:** `scripts/dev-cycle.sh:181-182`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers determinism for one date and variation across four sample dates over 20 lines with n=2. Does not establish that every pair of dates differs: collisions are possible by chance.

`seed="$(printf '%s' "$TODAY" | sha256sum | cut -c1-64)"` fed to `shuf … --random-source=<(yes "$seed")` (`:183-184`). E5 (P26): the old `yes "$d"` source picked "[merge 11,merge 1]" for all four dates. The sha seed picked four different pairs. Tests 6 and 7 pass in E1. Test 7 fails on 89a3d3b (E2). Removing the random source fails test 6 (E6, m6).

**Evidence:** `scripts/dev-cycle.sh:180-187`, `$FC2/logs/probe3.log` (P26), `$FC2/logs/bats-old.log` (not ok 7), `$FC2/logs/bats-m6.log`

---

## Claim 19: printed "No docs/roadmap.md yet — create it this cycle from the template in the dev-cycle skill."

**Location:** `scripts/dev-cycle.sh:197`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the template's existence in the stacked unit. Does not establish its existence at HEAD (a declared forward reference).

`feat/dev-cycle:skills/dev-cycle/SKILL.md:93`: "Update `docs/roadmap.md`, creating it from this template if missing:".

**Evidence:** `scripts/dev-cycle.sh:197`, `feat/dev-cycle:skills/dev-cycle/SKILL.md:91-93`

---

## Claim 20: "Each test builds a throwaway git repo under $BATS_TEST_TMPDIR, so nothing reads or writes this repo's own docs/."

**Location:** `test/scripts/dev-cycle.bats:4-5`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the `docs/` isolation. Does not establish full hermeticity: the tests read this repo's `scripts/` (test 8 copies it; every test runs the repo's questions.sh as the `$SCRIPT_DIR` sibling), and tests 3 and 5 depend on the wall-clock date.

`R="$BATS_TEST_TMPDIR/repo"; make_repo "$R" main; cd "$R"` (`test/scripts/dev-cycle.bats:19-21`). Test 8 uses `cp -r "$REPO_ROOT/scripts" "$BATS_TEST_TMPDIR/tools"` (`:125`), which is a read of `scripts/`, not `docs/`.

**Evidence:** `test/scripts/dev-cycle.bats:9-37`, `test/scripts/dev-cycle.bats:125`

---

## Claim 21: "HOME points at the temp dir so the ~/.claude/scripts fallback can't reach the real installed questions.sh."

**Location:** `test/scripts/dev-cycle.bats:15-16`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the `$HOME` fallback path. Does not establish which questions.sh the tests exercise: the primary path is the repo's own `scripts/questions.sh` (`$SCRIPT_DIR` sibling), so the fallback is never reached in these tests.

`export HOME="$BATS_TEST_TMPDIR/home"` (`:17`) against `[[ -f "$QS" ]] || QS="$HOME/.claude/scripts/questions.sh"` (`scripts/dev-cycle.sh:154`).

**Evidence:** `test/scripts/dev-cycle.bats:17`, `scripts/dev-cycle.sh:153-154`

---

## Claim 22: commit message: "13 hermetic tests; the regression tests fail on the pre-review version (89a3d3b)."

**Location:** `3aee138` commit message (paragraph 1)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count (13), all passing at HEAD, and the regression tests failing at 89a3d3b. The failing ones are 1, 2, 3, 4, 5, 7, 8, 10, 11 and 12. Tests 6, 9 and 13 pass on 89a3d3b because they cover behaviour the review did not change. "Hermetic" carries the residue named in claim 20.

E1: `ok 1` … `ok 13`, exit 0. E2 (89a3d3b's script with HEAD's tests): 10 "not ok", exit 1. Test 12 fails with "victim file was modified" and test 5 with "expected 8". The three tests that pass on 89a3d3b each fail under a targeted mutation in E6: m6 (no random source) fails test 6, m9 (route filter as grep) fails test 9, and m13 (--since format check removed) fails test 13. So every one of the 13 tests detects a break in the behaviour its name describes.

**Evidence:** `test/scripts/dev-cycle.bats:39-202`, `$FC2/logs/bats-new.log`, `$FC2/logs/bats-old.log`, `$FC2/logs/bats-m6.log`, `$FC2/logs/bats-m9.log`, `$FC2/logs/bats-m13.log`

---

## Claim 23: commit message: "split in /away mode because the combined unit was 531 code lines (cap 400); this unit is 400."

**Location:** `3aee138` commit message (Notes line)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pr-prep 1a count (outside `docs/`) at HEAD and at the pre-split tip d8b0cca. Does not establish the stacked branch's current size: after 3268a5e, feat/dev-cycle counts 529.

E7: HEAD gives 400 (dev-cycle.sh 198 + bats 202). d8b0cca (feat/dev-cycle before the seed-comment trim) gives 531: README 2, CLAUDE.md 1, skill-creation 1, dev-cycle.sh 200, SKILL.md 125, bats 202. 3268a5e gives 529. `git diff 3268a5e HEAD -- scripts test` is empty, so this unit's script and tests are byte-identical to the stacked tip's. This does not match the log's measured-count pattern.

**Evidence:** paraphrased — no quote available because the figures are command outputs recorded in the E7 row, not file lines; `scripts/dev-cycle.sh:1-198`, `test/scripts/dev-cycle.bats:1-202`

---

## Claim 24: commit message: "It resolves the default branch to a hash before passing it to git …, anchors --since at midnight, reports a questions.sh failure instead of hiding it, and works from any subdirectory and on master-only repos."

**Location:** `3aee138` commit message (paragraph 1)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the five listed fixes as exercised by tests 5, 8, 10, 11 and 12 and probes P5-P9 and P20. Does not establish subdirectory runs through a symlinked script path (claim 8).

Hash resolution: claim 10. Midnight: claim 12. questions.sh failure: `echo "**questions.sh open failed** — watched questions were NOT checked. Its error:"` (`scripts/dev-cycle.sh:169`), test 10 passes in E1 and fails in E2. Subdirectory: claim 8. Master-only: test 11 passes in E1 and fails in E2.

**Evidence:** `scripts/dev-cycle.sh:157-172`, `$FC2/logs/bats-new.log` (ok 5, 8, 10, 11, 12), `$FC2/logs/bats-old.log` (not ok 5, 8, 10, 11, 12)

---

## Claims Requiring Attention

### Incorrect
- **Claim 15b** (`scripts/dev-cycle.sh:110`): with `--since` given and a cycle record present, the digest prints "No earlier cycle record to carry verdicts from", which is false. Full printing is correct; give the `--since` case its own reason sentence.

### Stale
- None.

### Mostly Accurate
- **Claim 6** (`scripts/dev-cycle.sh:18-19`): "writes nothing". It writes a mktemp file in `$TMPDIR`, which its EXIT trap removes. More precise: "writes nothing to the repo".
- **Claim 9** (`scripts/dev-cycle.sh:45`): `DEV_CYCLE_TODAY` pins the title and seed but not the 14-day default window (`date -d '14 days ago'` uses the real clock).
- **Claim 13a** (`scripts/dev-cycle.sh:107`): "changed since" means *committed* since. An untracked new decision record, or an uncommitted edit, is listed as "Carried forward" even though no earlier verdict exists for it.

### Unverifiable
- None.

---

## Goal-Alignment Note
- **Answered:** Every claim in the header comments, the in-script comments, the printed explanatory text, the test header comments and the commit message was checked against behaviour, mostly by execution. The option-name fix held against `-p`, a dangling origin/HEAD, a detached HEAD, an empty repo and an option-like current branch. Names with spaces or globs cannot exist as refs. Carry-forward boundaries (midnight commit, row dated exactly on SINCE, explicit `--since`) behave as designed. All 13 tests detect a break in their named behaviour: 10 via 89a3d3b, 3 via mutation.
- **Out of scope:** Code-quality or design judgments. Whether carrying uncommitted records forward is acceptable is for the security/API critics or the author; this report states only what the digest says versus what it does.
- **Escalate:** Claim 15b (a false sentence in the `--since` output) and claim 13a (a new record that exists only in the working tree is carried forward with no prior verdict) are the two items the author should decide on before merge. Neither blocks: both concern explanatory text or an edge case, not the security fix.
