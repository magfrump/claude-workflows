Commit: 3aee138

# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-digest, branch feat/dev-cycle-digest)
**Scope:** `git diff main...HEAD` (scripts/dev-cycle.sh, test/scripts/dev-cycle.bats) plus the commit message of 3aee138 — final confirming pass, replicate r3
**Checked:** 2026-09-29
**Total claims checked:** 32
**Summary:** 24 verified, 4 mostly accurate, 0 stale, 4 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read before checking. Its five
entries are all "a specific measured value quoted from an artifact set that does not contain it";
the two numeric claims in this unit (claims 24 and 26: "13 tests", "531 / 400 lines") were
recomputed with that pattern in mind and hold.

Execution logs (all under `docs/reviews/execution-logs/`, cwd `/workspace/.claude/wt-digest`
unless stated; every probe ran in throwaway repos under the session scratchpad with
`GIT_CONFIG_GLOBAL=/dev/null`, isolated `HOME`, and `timeout`):

| Log | Command | Exit | Time |
|---|---|---|---|
| `r3-digest-final-bats-baseline.txt` | `timeout 300 bats test/scripts/dev-cycle.bats` | 0 (13/13 ok) | 2026-09-29T02:23:10-07:00 |
| `r3-digest-final-pre-review-89a3d3b.txt` | `timeout 300 bats <scratch>/old/test/scripts/dev-cycle.bats` (HEAD tests vs 89a3d3b script) | 1 (11/13 not ok) | 2026-09-29T02:23:31-07:00 |
| `r3-digest-final-probes.txt` | `timeout 240 bash <scratch>/probe1.txt` (script copied to `r3-digest-final-probe1-script.txt`) | 0 | 2026-09-29T02:24:38-07:00 |
| `r3-digest-final-probes2.txt` | `timeout 400 bash <scratch>/probe2.txt` (script copied to `r3-digest-final-probe2-script.txt`) | 0 | 2026-09-29T02:25:13-07:00 |
| `r3-digest-final-mutations.txt` | `timeout 590 bash <scratch>/mutate.txt` (script copied to `r3-digest-final-mutate-script.txt`) | 0 | 2026-09-29T02:26:02-07:00 |
| `r3-digest-final-mutation-t6-repeat.txt` | T6 random-seed mutant repeated 6× | 0 | 2026-09-29T02:26:18-07:00 |
| `r3-digest-final-worktree-run.txt` | `timeout 60 bash scripts/dev-cycle.sh` (read-only, in the worktree) | 0 | 2026-09-29T02:26:28-07:00 |
| `r3-digest-final-hermeticity-closure.txt` | `timeout 60 python3 scripts/hermeticity-lint --closure test/scripts/dev-cycle.bats` | 0 | 2026-09-29T02:27:30-07:00 |

`<scratch>` = `/tmp/claude-1000/-workspace/fba1bfc0-301f-41fe-8500-89690af4d400/scratchpad/r3df`.

---

## Claim 1: "The dev-cycle skill (skills/dev-cycle/SKILL.md) runs the judgment steps — health triage, revisit-trigger verdicts, spot-check audits, brainstorming, roadmap updates — … because this repo's evidence is that steps only prose asks for do not run (scripts/questions.sh header; Q-074)."

**Location:** `scripts/dev-cycle.sh:4-8`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of the skill on the stacked branch with those five steps and of the two cited evidence sources; does not establish that the skill exists in this unit (it is a forward reference, as the commit message says) or that the skill's steps are correct.

`skills/dev-cycle/SKILL.md` is absent from this unit (`git diff --stat main...HEAD` lists only the two files) but exists on `feat/dev-cycle`, whose description reads `Run one maintenance cycle: health and cleanup, revisit triggers, spot-check audit, brainstorm, roadmap.` (`feat/dev-cycle:skills/dev-cycle/SKILL.md:4`), with sections `### 2. Revisit triggers`, `### 4. Spot-check audit`, `### 5. Brainstorm`, `### 6. Roadmap` (`:55`, `:73`, `:82`, `:91`). The questions.sh header states the cited evidence: `this repo's own evidence is that an unenforced instruction does not execute` (`scripts/questions.sh:6-7`). Q-074 exists as `### Q-074 · failure-pattern-writer-trigger` and says `The writer is still pr-prep Step 0, a workflow step that is advisory only` (`docs/working/questions.md:67-70`).

**Evidence:** `scripts/dev-cycle.sh:4-8`, `scripts/questions.sh:5-11`, `docs/working/questions.md:67-72`, `feat/dev-cycle:skills/dev-cycle/SKILL.md:4,55-112`

---

## Claim 2: "--since   start of the cycle window (midnight, local time). Default: the date in the newest docs/working/cycles/cycle-YYYY-MM-DD.md, else 14 days ago. The digest says which."

**Location:** `scripts/dev-cycle.sh:12-14`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers midnight anchoring in local time, newest-record selection, the 14-day fallback and the printed source note; does not establish validation of the date's calendar validity (see claim 6) or behaviour for record files outside the glob.

The record loop keeps the lexically greatest date: `[[ "$d" > "$last_record" ]] && last_record="$d"` (`scripts/dev-cycle.sh:75`); fallback `SINCE="$(date -d '14 days ago' +%F)"` (`:82`); anchoring `SINCE_TS="$SINCE 00:00:00"` (`:87`); the note is printed in `echo "Window: since $SINCE (from $source_note), …"` (`:91`). Executed: a commit at local `T00:00:30` is counted by `--since="$T 00:00:00"` (8 of 8) and not by bare `$T` (0) (probes P1); test 4 (newest of two records) passes and its oldest-record mutant is killed (mutations log, T4); the worktree run prints `Window: since 2026-09-15 (from no cycle record found, so the default of 14 days …)` (worktree-run log).

**Evidence:** `scripts/dev-cycle.sh:71-91`, `docs/reviews/execution-logs/r3-digest-final-probes.txt`, `docs/reviews/execution-logs/r3-digest-final-mutations.txt`, `docs/reviews/execution-logs/r3-digest-final-worktree-run.txt`

---

## Claim 3: "--sample  how many merges to sample for the spot-check audit (default 2)."

**Location:** `scripts/dev-cycle.sh:15`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the default and that N lines are sampled; does not establish behaviour when N exceeds the merge count (shuf then prints all merges).

`SAMPLE=2` (`scripts/dev-cycle.sh:28`) feeds `shuf -n "$SAMPLE"` (`:184`). The worktree run printed two sample lines with no `--sample` (worktree-run log, section 4); test 6 asserts 2 lines and its `shuf -n 1` mutant is killed (mutations log, T6).

**Evidence:** `scripts/dev-cycle.sh:28,180-187`, `docs/reviews/execution-logs/r3-digest-final-worktree-run.txt`, `docs/reviews/execution-logs/r3-digest-final-mutations.txt`

---

## Claim 4: "Acts on the git repo of $PWD (like questions.sh), so the installed copy at ~/.claude/scripts/dev-cycle.sh serves any project."

**Location:** `scripts/dev-cycle.sh:17-18`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the script resolves the repo from `$PWD` and that the installer ships `scripts/` to `~/.claude/scripts`; does not establish identical non-repo behaviour (questions.sh falls back to `pwd`, dev-cycle.sh exits 1).

`ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { … exit 1; }` then `cd "$ROOT"` (`scripts/dev-cycle.sh:43-44`); questions.sh uses `PROJECT_ROOT="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || pwd)"` (`scripts/questions.sh:84`). The installer stages `CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)` (`devcontainer-config/install.sh:135`) and the linker links `ENTRIES=(skills workflows guides patterns hooks scripts CLAUDE.md)` (`devcontainer-config/link-claude-home.sh:50`), so the whole `scripts/` directory, including this file, lands at `~/.claude/scripts/`.

**Evidence:** `scripts/dev-cycle.sh:42-44`, `scripts/questions.sh:84-86`, `devcontainer-config/install.sh:125-135`, `devcontainer-config/link-claude-home.sh:44-50`

---

## Claim 5: "Read-only: prints to stdout and writes nothing."

**Location:** `scripts/dev-cycle.sh:18-19`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the repo (no tracked or untracked repo file written) and the temp-file lifecycle; does not establish anything about git's own internal caches.

The script writes one file: `qs_err="$(mktemp)"; trap 'rm -f "$qs_err"' EXIT` (`scripts/dev-cycle.sh:156`), in `$TMPDIR`, removed on exit (probe P7: `leftovers in TMPDIR: 0`). With an unwritable `TMPDIR` the `mktemp` failure aborts the digest under `set -e` after sections 1–2 are printed, exit 1 (probe P7, `mktemp: failed to create file … Permission denied`, `[exit 1]`). The repo itself is untouched (worktree run left no new repo files beyond this review's logs). Precise version: "writes nothing to the repo; uses one temp file for questions.sh's stderr".

**Evidence:** `scripts/dev-cycle.sh:25,153-175`, `docs/reviews/execution-logs/r3-digest-final-probes.txt`

---

## Claim 6: "Exit codes: 0 digest printed, 1 bad usage or not a git repo / no resolvable default branch."

**Location:** `scripts/dev-cycle.sh:19-20`
**Type:** Behavioral / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listed exit paths and the extra ones found; does not establish exit codes on platforms without GNU `date -d`, `shuf` or `sha256sum` (they would exit non-zero under `set -e`).

The named paths hold: missing value `--since needs a date` → `[exit 1]`; `--sample x` → `[exit 1]`; detached HEAD with no main/master, an empty repo, and an option-like current branch all → `Could not resolve a default branch …` `[exit 1]` (probes P5, P6). Imprecisions: (a) exit 1 also arises from any `set -e` failure mid-digest, e.g. `mktemp` (claim 5), after a partial digest is printed; (b) `-h` exits 0 with help, not a digest (`-h|--help) sed -n '2,23p' "$0" … exit 0 ;;`, `:35`); (c) "bad usage" is not all rejected — the check is shape-only, `[[ "$SINCE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]` (`:85`), so `--since 2026-13-45` runs to `[exit 0]` (probe P6), and an empty `--since=` sets `SINCE=""` (`--since=*) SINCE="${1#--since=}"`, `:32`) which the later `[[ -n "$SINCE" ]]` (`:77`) treats as not given (paraphrased — no quote available because the empty-value path was read, not executed; it follows from lines 32 and 77 together).

**Evidence:** `scripts/dev-cycle.sh:29-39,62-69,77-85,156`, `docs/reviews/execution-logs/r3-digest-final-probes.txt`

---

## Claim 7: "Resolved before the cd below, so a relative invocation path still works."

**Location:** `scripts/dev-cycle.sh:41`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers locating questions.sh beside a relatively invoked script from a subdirectory; does not establish symlinked-script resolution (BASH_SOURCE is not canonicalised).

`SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` precedes `cd "$ROOT"` (`scripts/dev-cycle.sh:42-44`). Test 8 (relative path from `sub/dir`) passes, and the mutant that moves SCRIPT_DIR after the cd is killed (mutations log, T8).

**Evidence:** `scripts/dev-cycle.sh:41-44`, `docs/reviews/execution-logs/r3-digest-final-mutations.txt`

---

## Claim 8: "DEV_CYCLE_TODAY exists only so tests can pin the date."

**Location:** `scripts/dev-cycle.sh:45`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every in-repo reference; does not establish that no external caller sets it.

`grep -rn DEV_CYCLE_TODAY scripts test` returns only `scripts/dev-cycle.sh:45-46` and `test/scripts/dev-cycle.bats:116` (`out=$(DEV_CYCLE_TODAY=$d bash "$DC" --since=2000-01-01 --sample=3 …`).

**Evidence:** `scripts/dev-cycle.sh:45-46`, `test/scripts/dev-cycle.bats:116`

---

## Claim 9: "Resolve the default branch to a commit hash once, and pass only the hash to git afterwards. The name comes from origin/HEAD, which a clone copies from the remote: a branch named like an option (`--output=<path>`) would otherwise reach `git log` as an option and truncate a file."

**Location:** `scripts/dev-cycle.sh:48-51`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every git invocation that consumes the branch (only `$MAIN_SHA` is passed; `$MAIN` is only echoed) and the hostile names tried (`--output=…`, `-p`, dangling origin/HEAD, option-like current branch); does not establish safety of the echoed `$MAIN` as markdown (a name can contain backticks) and does not claim the `-*` skip is load-bearing (it is not; see below).

Resolution: `sha="$(git rev-parse --verify --quiet "refs/heads/$c^{commit}" …)"` (`scripts/dev-cycle.sh:59`); consumers use the hash: `git log "$MAIN_SHA" --first-parent --merges …` (`:95`), `git rev-list --count --since="$SINCE_TS" "$MAIN_SHA"` (`:97`); `$MAIN` appears only in `echo` lines (`:91`, `:99`) (paraphrased — no quote available because the claim covers absence: grep of `"$MAIN"` finds no git call). Executed: test 12 (`--output=<victim>`) passes; the mutant passing `$MAIN` to `git log` with the dash-skip removed is killed; `-p` via origin/HEAD and a dangling origin/HEAD both fall through to `main` (probes P5); an option-like current branch with no main exits 1 and leaves the victim file `keep`. The mutant removing only `[[ "$c" == -* ]] && continue` survives — the hash, not the skip, is the guard, which matches the comment's wording.

**Evidence:** `scripts/dev-cycle.sh:48-69,91-99`, `docs/reviews/execution-logs/r3-digest-final-probes.txt`, `docs/reviews/execution-logs/r3-digest-final-mutations.txt`

---

## Claim 10: "A repo on some other branch name: use the current branch."

**Location:** `scripts/dev-cycle.sh:63`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a repo on `trunk` with no main/master; does not establish behaviour when the current branch differs from the intended default (it silently uses whatever is checked out).

`cur="$(git symbolic-ref --quiet --short HEAD …)"; if [[ -n "$cur" && "$cur" != -* ]]; then MAIN="$cur"; MAIN_SHA="$(git rev-parse --verify --quiet HEAD …)"` (`scripts/dev-cycle.sh:64-67`). Probe P5 on a `trunk`-only repo prints ``on `trunk` at 7281955``; detached HEAD yields exit 1 with the stated message.

**Evidence:** `scripts/dev-cycle.sh:62-69`, `docs/reviews/execution-logs/r3-digest-final-probes.txt`

---

## Claim 11: "A bare date means "this time of day" to git; anchor it at midnight."

**Location:** `scripts/dev-cycle.sh:86`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git's `--since=<date>` parsing in this git version; does not establish behaviour of other git versions.

Probe P1: with every commit made today, `bare: 0`, `midnight: 8`, `total: 8`; a commit at exactly `2020-06-01T00:00:00` is included by `--since="2020-06-01 00:00:00"`. Test 5 passes and its bare-date mutant is killed.

**Evidence:** `scripts/dev-cycle.sh:86-87`, `docs/reviews/execution-logs/r3-digest-final-probes.txt`, `docs/reviews/execution-logs/r3-digest-final-mutations.txt`

---

## Claim 12a: "Printed in full: … log rows dated on or after it."

**Location:** `scripts/dev-cycle.sh:107`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the on-or-after boundary for ISO dates in the log's date column; does not establish behaviour for rows whose date cell is not an ISO date (compared lexically).

`if [[ $full -eq 1 || ! "$d" < "$SINCE" ]]` (`scripts/dev-cycle.sh:132`). Probe P3 with record `cycle-2026-03-10.md`: `- log row 5 (2026-03-10): Revisit if on-boundary.` printed in full, `Carried forward (1): log row 4` (dated 2026-03-09). Note: the boundary itself has no test (the `>`-instead-of-`>=` mutant survives, mutations log T3).

**Evidence:** `scripts/dev-cycle.sh:127-143`, `docs/reviews/execution-logs/r3-digest-final-probes.txt`, `docs/reviews/execution-logs/r3-digest-final-mutations.txt`

---

## Claim 12b: "Printed in full: triggers in decision records changed since $SINCE … Listed by name only: the rest, whose verdict carries forward from docs/working/cycles/cycle-$last_record.md"

**Location:** `scripts/dev-cycle.sh:107`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which decision records print vs carry forward; does not establish how often a record is authored before and merged after a cycle-record date in practice.

"Changed" is computed as `changed="$(git log -1 --since="$SINCE_TS" --format=%h -- "$f" …)"` (`scripts/dev-cycle.sh:118`): the last commit touching the file on HEAD with a *commit date* on or after SINCE, under git's default history simplification. A record committed on a branch before the cycle-record date and merged into main after it is carried forward by name, though it was not on main when the previous cycle wrote its verdicts: probe Q1 (branch commit 2026-03-05, record `cycle-2026-03-10.md`, merge now) prints the merge in section 1 but `Carried forward (1): 003-late.md` in section 2. Records added or edited in the working tree but not committed are also carried (probe P2: `Carried forward (2): 001-a.md 002-b.md`, where 002-b is untracked and 001-a has an uncommitted new trigger line). A reader told the verdict "carries forward" would skip a trigger no cycle has judged. The midnight boundary itself is right: a record committed at `2026-03-10T00:00:00` prints in full (probe P4). The query also runs against HEAD, not `$MAIN_SHA` (no revision argument on line 118), unlike section 1.

**Evidence:** `scripts/dev-cycle.sh:105-126`, `docs/reviews/execution-logs/r3-digest-final-probes.txt`, `docs/reviews/execution-logs/r3-digest-final-probes2.txt`

---

## Claim 13a: "No earlier cycle record to carry verdicts from, so every trigger is printed in full." (no cycle record present)

**Location:** `scripts/dev-cycle.sh:110`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the case where no `cycle-*.md` exists; does not cover the explicit `--since` case (claim 13b).

With no record, `full=1` (`scripts/dev-cycle.sh:109`) makes every record and row print (test 2 passes; probe P2's second run prints all records in full).

**Evidence:** `scripts/dev-cycle.sh:105-111,119,132`, `docs/reviews/execution-logs/r3-digest-final-probes.txt`

---

## Claim 13b: "No earlier cycle record to carry verdicts from, so every trigger is printed in full." (explicit --since with a cycle record present)

**Location:** `scripts/dev-cycle.sh:110`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the printed reason under `--since`; the conclusion (everything in full) is right and matches the brief's intended behaviour; does not establish that any reader acts on the wrong reason.

The branch condition is `if [[ -n "$last_record" && "$source_note" != "--since" ]]` (`scripts/dev-cycle.sh:105`), so the else-branch message also prints when a record exists but `--since` was given. Probe P2 (record `cycle-2026-09-28.md` present, `--since=2026-09-28`) prints `No earlier cycle record to carry verdicts from`. The stated mechanism is false in that case; a precise message would say "--since given, so every trigger is printed in full". Low impact: the Window line on the same page says `(from --since)`.

**Evidence:** `scripts/dev-cycle.sh:77-78,105-111`, `docs/reviews/execution-logs/r3-digest-final-probes.txt`

---

## Claim 14: "docs/roadmap.md last changed $(git log -1 --format=%ad --date=short -- docs/roadmap.md 2>/dev/null || echo 'never (uncommitted)')"

**Location:** `scripts/dev-cycle.sh:193`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the uncommitted-roadmap fallback and the same pattern for decision records at `:121`; does not establish any effect beyond the printed text.

The fallback never fires: `git log -1 -- <untracked path>` exits 0 with empty output, so the `||` branch is unreachable. Probe P2 with an untracked `docs/roadmap.md` prints `docs/roadmap.md last changed . Its Next section:`. The same shape at `echo "### $f (last changed $(git log -1 --format=%ad --date=short -- "$f"))"` (`:121`) prints `### docs/decisions/002-b.md (last changed )` for an untracked record in full mode (probe P2, second run). Fix direction: test for empty output instead of exit status.

**Evidence:** `scripts/dev-cycle.sh:121,193`, `docs/reviews/execution-logs/r3-digest-final-probes.txt`

---

## Claim 15: "The whole revisit clause, to the end of its table cell. Prefer a capitalised "Revisit" (the trigger sentence) over a lowercase mention earlier in the row, such as "revisit-trigger verdicts"."

**Location:** `scripts/dev-cycle.sh:133-135`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers extraction on synthetic rows and the real log (rows 65, 66 printed from "Revisit" to cell end); does not establish handling of a pipe inside a cell (escaped `\|` or code span would end the clause early) and the capitalised preference has no regression test.

`text="$(grep -oE 'Revisit[^|]*' <<< "$row" | head -1 || true)"`, then `[[ -n "$text" ]] || text="$(grep -oiE 'revisit[^|]*' <<< "$row" | head -1)"` (`scripts/dev-cycle.sh:136-137`). The worktree run prints `- log row 66 (2026-09-29): Revisit if, over the first three dev cycles after install, …` in full. Test 2 kills the 400-character-cut mutant, but the mutant that drops the capitalised preference survives (mutations log, T2): no test row has an earlier lowercase "revisit".

**Evidence:** `scripts/dev-cycle.sh:127-143`, `docs/reviews/execution-logs/r3-digest-final-worktree-run.txt`, `docs/reviews/execution-logs/r3-digest-final-mutations.txt`

---

## Claim 16: "`open` prints "ID  route  slug" in columns of 2+ spaces; a route can contain one space ("you: judgment"), a slug can contain "trigger"."

**Location:** `scripts/dev-cycle.sh:158-159`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers questions.sh's current `open` format and the awk field split; does not establish stability if a route ever exceeds the 14-column pad (two literal spaces still separate fields).

questions.sh prints `printf '%s  %-14s  %s\n' "$id" "$route" "$slug"` (`scripts/questions.sh:412`). Running it read-only in the worktree gives `Q-084  you: terminal   q076-live-checks` (probes2, Q4). The digest splits with `awk -F'  +' '$2 == "trigger" || $2 == "deferred"'` (`scripts/dev-cycle.sh:160`); test 9 (slug `a-trigger-in-the-slug`) passes and its whole-line-match mutant is killed.

**Evidence:** `scripts/questions.sh:408-414`, `scripts/dev-cycle.sh:157-167`, `docs/reviews/execution-logs/r3-digest-final-probes2.txt`, `docs/reviews/execution-logs/r3-digest-final-mutations.txt`

---

## Claim 17a: "Seeded by a hash of the date: same day, same merges"

**Location:** `scripts/dev-cycle.sh:181`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers determinism for a fixed date and fixed merge list; does not establish stability if the merge list changes during the day.

`seed="$(printf '%s' "$TODAY" | sha256sum | cut -c1-64)"` and `shuf -n "$SAMPLE" --random-source=<(yes "$seed")` (`scripts/dev-cycle.sh:183-184`). Probe Q2: two runs with `DEV_CYCLE_TODAY=2026-05-01` → `same day: identical`; test 6 passes.

**Evidence:** `scripts/dev-cycle.sh:180-187`, `docs/reviews/execution-logs/r3-digest-final-probes2.txt`

---

## Claim 17b: "different days differ. (The raw date seeded nothing: every date starts with the same bytes.)"

**Location:** `scripts/dev-cycle.sh:181-182`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hashed seed's variation across days and the old raw-date seed; does not establish uniformity of the hashed sample.

Both halves are directionally right but overstated. Different days *usually* differ, not always: with 3 merges and `--sample 2`, 15 of 29 adjacent days drew the same set (probes2, Q2), as expected with only 3 possible sets; across 30 days all three sets occur (16/8/6). The raw date seeded nothing *within a shared prefix*: four 2026 dates all drew `merge 19,merge 2,merge 5`, but dates in different decades (1999, 2026, 3000) drew three different sets (probes2, Q2), so "every date starts with the same bytes" should read "dates in the same year share their leading bytes, which is all shuf reads for a small sample". Test 7 (four dates, 20 merges, sample 3) is deterministic, so it cannot flake.

**Evidence:** `scripts/dev-cycle.sh:180-187`, `test/scripts/dev-cycle.bats:108-121`, `docs/reviews/execution-logs/r3-digest-final-probes2.txt`

---

## Claim 18: "No docs/roadmap.md yet — create it this cycle from the template in the dev-cycle skill."

**Location:** `scripts/dev-cycle.sh:197`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the template's existence in the stacked unit; does not establish it in this unit (forward reference).

`feat/dev-cycle:skills/dev-cycle/SKILL.md:93` reads ``Update `docs/roadmap.md`, creating it from this template if missing:`` followed by a `# Roadmap` template (`:96`).

**Evidence:** `scripts/dev-cycle.sh:196-198`, `feat/dev-cycle:skills/dev-cycle/SKILL.md:91-112`

---

## Claim 19: "Each test builds a throwaway git repo under $BATS_TEST_TMPDIR, so nothing reads or writes this repo's own docs/."

**Location:** `test/scripts/dev-cycle.bats:4-5`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every test's working directory and paths; does not establish independence from this repo's `scripts/` (tests read the script under test, and test 8 copies `scripts/`).

`setup()` sets `R="$BATS_TEST_TMPDIR/repo"`, `make_repo "$R" main`, `cd "$R"` (`test/scripts/dev-cycle.bats:19-21`); tests 11 and 12 use `$BATS_TEST_TMPDIR/mrepo` and `$BATS_TEST_TMPDIR/victim.txt` (`:176`, `:186`); test 8 copies `"$REPO_ROOT/scripts"` into `$BATS_TEST_TMPDIR/tools` (`:125`). No test references `$REPO_ROOT/docs` (paraphrased — no quote available because the claim covers absence of matching references in the file).

**Evidence:** `test/scripts/dev-cycle.bats:9-37,123-132,175-195`

---

## Claim 20: "HOME points at the temp dir so the ~/.claude/scripts fallback can't reach the real installed questions.sh."

**Location:** `test/scripts/dev-cycle.bats:15-16`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the fallback path; does not establish that the fallback is ever exercised by the suite (it is not: `$SCRIPT_DIR/questions.sh` always exists beside the script under test).

`export HOME="$BATS_TEST_TMPDIR/home"` (`test/scripts/dev-cycle.bats:17`) and the script's fallback is `QS="$HOME/.claude/scripts/questions.sh"` only when `[[ -f "$QS" ]]` fails for `QS="$SCRIPT_DIR/questions.sh"` (`scripts/dev-cycle.sh:153-154`).

**Evidence:** `test/scripts/dev-cycle.bats:15-18`, `scripts/dev-cycle.sh:153-154`

---

## Claim 21: "a window starting at midnight must count them all (a bare date would mean "today at the current time" to git and count none of them)."

**Location:** `test/scripts/dev-cycle.bats:90-92`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fixture's commits (all made earlier today); does not establish the test's behaviour if run within 30 seconds after midnight (the 00:00:30 commit is then in the future but still counted).

Probe P1 reproduces the fixture: `bare: 0`, `midnight: 8`, `total: 8`.

**Evidence:** `test/scripts/dev-cycle.bats:88-96`, `docs/reviews/execution-logs/r3-digest-final-probes.txt`

---

## Claim 22: "No questions-archive.md: questions.sh open exits non-zero."

**Location:** `test/scripts/dev-cycle.bats:167`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers questions.sh's `open` with a missing archive; does not establish other failure modes of `open`.

`cmd_open() { require_files …` (`scripts/questions.sh:408-409`); `require_files` checks both files and calls `die` (`:132-138`), which is `die() { echo "  ✗ questions.sh: $*" >&2; exit 1; }` (`:76`). Test 10 passes and the failure-swallowing mutant is killed.

**Evidence:** `scripts/questions.sh:76,132-138,408-414`, `docs/reviews/execution-logs/r3-digest-final-mutations.txt`

---

## Claim 23: The 13 test names (each names a behaviour it guards)

**Location:** `test/scripts/dev-cycle.bats:39-202`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 20 targeted mutants of the script (one or more per test); does not establish coverage of behaviours no test names.

All 13 pass at HEAD (bats-baseline). Of 20 mutants, 15 were killed (mutations log). Survivors: (1) T2 — dropping the capitalised-"Revisit" preference (the row-67 pass-1 fix has no regression test); (2) T3 — changing log-row "on or after" to "after" (boundary untested); (3) T6 — a per-run random seed is caught only probabilistically (killed 4 of 7 runs across both logs) because 3 merges choose 2 give few outcomes; (4) T11 — dropping `master` from the candidates survives because the current-branch fallback also finds `master` (the test still guards the named behaviour: removing both is killed); (5) T12 — removing only the `-*` skip survives because the hash is the load-bearing guard (removing the hash use is killed). Survivors 1–3 are real gaps against behaviours the test names or the commit message cites; 4–5 are redundancy, not gaps.

**Evidence:** `test/scripts/dev-cycle.bats:39-202`, `docs/reviews/execution-logs/r3-digest-final-bats-baseline.txt`, `docs/reviews/execution-logs/r3-digest-final-mutations.txt`, `docs/reviews/execution-logs/r3-digest-final-mutation-t6-repeat.txt`

---

## Claim 24: "test/scripts/dev-cycle.bats: 13 hermetic tests"

**Location:** commit 3aee138 message, body paragraph 1
**Type:** Configuration / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test count and filesystem/config/network isolation; does not establish wall-clock independence (tests use `date`, e.g. `date -d yesterday` at `:73`).

bats reports `1..13` (bats-baseline). Isolation: `export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1` and `export HOME="$BATS_TEST_TMPDIR/home"` (`test/scripts/dev-cycle.bats:12,17`); the hermeticity lint's closure lists `test/scripts/dev-cycle.bats`, `scripts/dev-cycle.sh`, `scripts/questions.sh` with no network binary (hermeticity-closure log).

**Evidence:** `test/scripts/dev-cycle.bats:9-22`, `docs/reviews/execution-logs/r3-digest-final-bats-baseline.txt`, `docs/reviews/execution-logs/r3-digest-final-hermeticity-closure.txt`

---

## Claim 25: "the regression tests fail on the pre-review version (89a3d3b)."

**Location:** commit 3aee138 message, body paragraph 1
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the HEAD suite run against 89a3d3b's `scripts/dev-cycle.sh` and `scripts/questions.sh`; does not establish that every pass-1 fix has a regression test (the capitalised-"Revisit" preference does not; claim 23).

11 of 13 fail against 89a3d3b; tests 6 and 13 pass (pre-review-89a3d3b log). Tests 1 and 4 fail partly on changed wording (`no cycle record found` absent), not only on fixed bugs.

**Evidence:** `docs/reviews/execution-logs/r3-digest-final-pre-review-89a3d3b.txt`

---

## Claim 26: "split in /away mode because the combined unit was 531 code lines (cap 400); this unit is 400."

**Location:** commit 3aee138 message, `Notes:` line
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pr-prep 1a count (docs/ excluded) for this unit and for the combined branch at the split point; does not establish the count on `feat/dev-cycle` today (529, after 3268a5e tightened a comment).

`git diff --numstat main...HEAD -- ':(top)' ':(top,exclude)docs/'` gives `198 0 scripts/dev-cycle.sh` and `202 0 test/scripts/dev-cycle.bats` = 400. The same count for the combined branch is 531 at d8b0cca (the pass-1 fix commit) and 529 at 3268a5e / `feat/dev-cycle` (paraphrased — no quote available because these are command outputs run in this session's shell, not saved as a separate log; rerun with the command above against each commit).

**Evidence:** commit `3aee138`, `d8b0cca`, `3268a5e`

---

## Claim 27: "revisit triggers needing a verdict (records changed and log rows dated in the window print in full; the rest carry forward)"

**Location:** commit 3aee138 message, body paragraph 1
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Same behaviour as claims 12a/12b; the log-row half is Verified, the records half carries the verdict (most-severe part).

The "records changed … in the window" half is refuted as in claim 12b: a record merged to main in the window but committed on its branch before it is carried forward (probe Q1, `Carried forward (1): 003-late.md`), as are uncommitted records. Not split here because claim 12a/12b already carry the split.

**Evidence:** `scripts/dev-cycle.sh:105-143`, `docs/reviews/execution-logs/r3-digest-final-probes2.txt`

---

## Claim 28: "It resolves the default branch to a hash before passing it to git (an option-like branch name cannot reach git as an option), anchors --since at midnight, reports a questions.sh failure instead of hiding it, and works from any subdirectory and on master-only repos."

**Location:** commit 3aee138 message, body paragraph 1
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the five listed properties via tests 5, 8, 10, 11, 12 and probes; does not establish handling of a `mktemp` failure (aborts, claim 5) or claims beyond these five.

Evidence per property: claim 9 (hash), claim 11 (midnight), claim 22 and test 10 (failure reported: the section prints `**questions.sh open failed** — watched questions were NOT checked.`, `scripts/dev-cycle.sh:169`), claim 7 (subdirectory), test 11 plus the master-drop-and-fallback-removed mutant killed (master-only).

**Evidence:** `scripts/dev-cycle.sh:41-69,86-87,153-175`, `docs/reviews/execution-logs/r3-digest-final-mutations.txt`, `docs/reviews/execution-logs/r3-digest-final-probes.txt`

---

## Claim 29: "the dev-cycle skill, roadmap and docs that use this script land in the stacked unit feat/dev-cycle."

**Location:** commit 3aee138 message, body paragraph 2
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers presence of the skill and roadmap on `feat/dev-cycle`; does not establish that the stacked unit is rebased on this one.

`git diff --stat 3268a5e HEAD` shows `skills/dev-cycle/SKILL.md`, `docs/roadmap.md`, `README.md`, `global-instructions/CLAUDE.md`, `guides/skill-creation.md` present on `feat/dev-cycle` (3268a5e is its tip) and absent here; `feat/dev-cycle:docs/roadmap.md:1` is `# Roadmap`.

**Evidence:** `feat/dev-cycle:skills/dev-cycle/SKILL.md`, `feat/dev-cycle:docs/roadmap.md:1-3`

---

## Claims Requiring Attention

### Incorrect
- **Claim 12b** (`scripts/dev-cycle.sh:107,118`): records "changed since $SINCE" means "last commit on HEAD with commit date ≥ SINCE"; a record merged in the window but committed earlier on its branch, or an uncommitted record, is carried forward by name though no cycle judged it. Consider `git log -1 --first-parent "$MAIN_SHA" --since=… -- "$f"` (and say uncommitted records are not seen).
- **Claim 13b** (`scripts/dev-cycle.sh:110`): under explicit `--since` the digest says "No earlier cycle record" even when one exists; give the real reason.
- **Claim 14** (`scripts/dev-cycle.sh:121,193`): `|| echo 'never (uncommitted)'` is unreachable (git log exits 0 with empty output); prints "last changed ." / "(last changed )".
- **Claim 27** (commit message): repeats 12b's records half.

### Stale
- None.

### Mostly Accurate
- **Claim 5** (`scripts/dev-cycle.sh:18-19`): writes one temp file (removed on exit); unwritable TMPDIR aborts with exit 1.
- **Claim 6** (`scripts/dev-cycle.sh:19-20`): exit 1 also on mid-digest `set -e` failures; `-h` exits 0 without a digest; `--since 2026-13-45` and empty `--since=` are accepted.
- **Claim 17b** (`scripts/dev-cycle.sh:181-182`): different days differ only probabilistically; the raw-date failure holds within a shared year prefix, not for "every date".
- **Claim 23** (`test/scripts/dev-cycle.bats`): untested — capitalised-"Revisit" preference, log-row on-or-after boundary; T6 catches a nondeterministic seed only ~4/7 of the time.

### Unverifiable
- None.

---

## Goal-Alignment Note
- **Answered:** every checkable claim in the two header comments, inline comments, output-text assertions and the commit message, with the brief's execute-where-possible rule applied; hostile-name probes (`-p`, dangling origin/HEAD, option-like current branch, detached HEAD, empty repo; spaces and globs are rejected by git itself), carry-forward boundaries (row on SINCE, record at midnight, explicit `--since`), and a 20-mutant sweep across all 13 tests.
- **Out of scope:** code quality and security judgments beyond whether comments match behaviour; the stacked unit's skill content (checked only for existence of referenced sections).
- **Escalate:** claim 12b (branch-authored-early records silently carried forward) is the one finding that can make a cycle skip an unjudged trigger; claim 14 is a cosmetic but real dead fallback. No hallucination-pattern entry added (no Incorrect verdict is a fabrication).
