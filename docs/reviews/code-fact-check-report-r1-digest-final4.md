Commit: db0e5ca

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-digest (branch feat/dev-cycle-digest)
**Scope:** `git diff main...HEAD -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (both new files, 241 + 263 lines), plus commit messages d9e4cb9 and db0e5ca. Replicate r1, final pass 4.
**Checked:** 2026-10-01
**Total claims checked:** 56
**Summary:** 40 verified, 11 mostly accurate, 0 stale, 4 incorrect, 1 unverifiable

Execution provenance. Every executed claim ran from the cwd it names, under `timeout`, between 2026-10-01T19:06:49-07:00 and 19:13:01-07:00. Throwaway repos were built with `mktemp -d` under /tmp. Captured output is in the session scratchpad, not in the worktree, because the brief forbids writing anything there except this report: `$S` = `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fcl-final4/`. Main logs:
- `$S/bats-head.log`: `bats test/scripts/dev-cycle.bats`, cwd worktree, exit 0, 18/18.
- `$S/shellcheck.log`: `shellcheck scripts/dev-cycle.sh test/scripts/dev-cycle.bats`, exit 0, empty.
- `$S/bats-d9e4cb9.log`: d9e4cb9's script and tests (git archive), exit 0, 1..16 all ok.
- `$S/bats-headtests-on-baa46e3.log`: HEAD's bats file run against baa46e3's script. Exit 1. Tests 1, 3, 4, 5, 17 and 18 fail; 2 and 6–16 pass.
- `$S/mutations.log`: single-mutant runs, M1–M5.
- `$S/probe-*.log`: the probes P1–P16 cited below.
- `$S/run-on-worktree.out`: a full run on this worktree (exit 0).

Hallucination-pattern log read: its test-count entry (a "N tests pass" figure that never held) is the pattern for Claims 43 and 47. Both counts reproduce here.

---

## Claim 1: "The dev-cycle skill (skills/dev-cycle/SKILL.md) runs the judgment steps on top of this digest."

**Location:** `scripts/dev-cycle.sh:4`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the referenced file exists in the stacked unit (feat/dev-cycle, 70cc7dc), with step 0 reading this digest. Does not establish that the file exists on this branch or on main (it exists on neither), or that the skill text matches sections 6–7 (see Claims 28, 29).

Paraphrased — no quote available because the claim is about file presence across branches: `ls skills/dev-cycle` fails in this worktree, while `git show feat/dev-cycle:skills/dev-cycle/SKILL.md` has `### 0. Digest` at :39. The digest is the lower unit of the split.

**Evidence:** `scripts/dev-cycle.sh:4`; feat/dev-cycle `skills/dev-cycle/SKILL.md:39`

---

## Claim 2: "steps that only prose asks for do not run (scripts/questions.sh header; Q-074)"

**Location:** `scripts/dev-cycle.sh:6`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both references exist and say this. Does not establish the underlying empirical claim.

`scripts/questions.sh:5-8`: "this repo's own evidence is that an unenforced instruction does not execute … because only prose asked for them." Q-074 is at `docs/working/questions.md:67` (`### Q-074 · failure-pattern-writer-trigger`).

**Evidence:** `scripts/questions.sh:5-11`, `docs/working/questions.md:67`

---

## Claim 3: "--since   start of the cycle window: merges committed on or after this date."

**Location:** `scripts/dev-cycle.sh:10`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the date comparison in all three walks (`:99`, `:102`, `:199`). Does not establish behavior for author dates (`%ad` is printed but never filtered on).

The filter compares `%cs` with the date as strings:

```bash
# scripts/dev-cycle.sh:99
merges_full="$(git log "$MAIN_SHA" --first-parent --merges --format='%cs %H %h %ad %s' --date=short | awk -v s="$SINCE" '$1 >= s')"
```

`%cs` is the date in the committer's own time zone, not the local one, and the help text omits that qualifier. On this -0700 machine, probe P10b made a merge at 2026-09-30T23:30-12:00 (local: Thu Oct 1 04:30). `%cs` is 2026-09-30, so `--since=2026-10-01` leaves it out of section 1. Local-midnight `git log --since=2026-10-01T00:00` includes it. P9 shows the reverse: a commit made at local Sep 30 09:30 in +09:00 is included as 2026-10-01. Compared with baa46e3, which used local midnight, the window edge now moves with each committer's offset. The mechanism (filter by date, inclusive) is right. The precise text is "on or after this date, as each committer's own time zone dates it".

Command: the P9/P10b script in `$S/probe-tz.log`. Cwd: mktemp repo. Script exit 0 each run. 2026-10-01T19:09-19:10 -0700.

**Evidence:** `scripts/dev-cycle.sh:96-102`, `$S/probe-tz.log`

---

## Claim 4: "Default: the date in the newest docs/working/cycles/cycle-YYYY-MM-DD.md (only its file name is read), else 14 days ago. The digest says which."

**Location:** `scripts/dev-cycle.sh:11-12`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers selection by file name (future-dated names ignored), the 14-day fallback and the source note. Does not establish behavior for a cycle record that is a directory or a dangling symlink (both skipped by `-f`).

```bash
# scripts/dev-cycle.sh:75-87
for f in docs/working/cycles/cycle-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md; do
  [[ -f "$f" ]] || continue
  d="${f##*/cycle-}"; d="${d%.md}"
  [[ "$d" > "$last_record" && ! "$d" > "$TODAY" ]] && last_record="$d"  # ignore future-dated
done
…
  SINCE="$(date -d "$TODAY - 14 days" +%F)"
```

The loop never opens the file. Test 7 passes, and the run on this worktree prints "since 2026-09-17 (from no cycle record found, so the default of 14 days …)".

**Evidence:** `scripts/dev-cycle.sh:74-87`, `test/scripts/dev-cycle.bats:114-121`, `$S/bats-head.log`, `$S/run-on-worktree.out`

---

## Claim 5: "--sample  how many merges to sample for the spot-check (default 2)."

**Location:** `scripts/dev-cycle.sh:13`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the default and the use of N. Does not establish behavior when N exceeds the number of merges (shuf prints all).

`SAMPLE=2` (`:34`); `shuf -n "$SAMPLE"` (`:165`). Test 9 passes.

**Evidence:** `scripts/dev-cycle.sh:34,165`, `$S/bats-head.log`

---

## Claim 6a: "nothing carries forward."

**Location:** `scripts/dev-cycle.sh:15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the absence of carry-forward code and output. Does not establish what the skill does with the previous record's verdicts.

`grep -nE 'Main at|[Cc]arr|git show|cmp |merge-base|SINCE_TS' scripts/dev-cycle.sh` hits only this header line. Test 3 passes at HEAD and fails on baa46e3's script.

**Evidence:** `scripts/dev-cycle.sh:15,107-133`, `$S/bats-head.log`, `$S/bats-headtests-on-baa46e3.log`

---

## Claim 6b: "Every revisit trigger is printed in full every run"

**Location:** `scripts/dev-cycle.sh:15` (also `:108`, "Every trigger, in full")
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `## Revisit triggers` section in `docs/decisions/NNN-*.md` and every numbered log row containing "revisit". Does not establish coverage of triggers written inline in a record's body, of record names outside the 3-digit glob, or of blank lines inside a section.

Section 2 reads only two shapes:

```bash
# scripts/dev-cycle.sh:110-113
trig() { awk '/^## Revisit triggers/ { on = 1; next } on && /^## / { exit } on && NF { print }'; }
for f in docs/decisions/[0-9][0-9][0-9]-*.md; do
  [[ -f "$f" ]] || continue
  grep -q '^## Revisit triggers' "$f" || continue
```

(excerpt ends :113; the loop continues to :120 and the log-row block to :132 — read.)

In this repo, `docs/decisions/013-failure-pattern-library-after-bug-diagnosis-removal.md:21` ends with an inline trigger, "Revisit if the pattern-learning loop visibly decays." It has no such heading, so the digest does not print it (`$S/run-on-worktree.out`, section 2). `on && NF` also drops blank lines. "Every trigger" is precise for the two structured forms only.

**Evidence:** `scripts/dev-cycle.sh:107-133`, `docs/decisions/013-failure-pattern-library-after-bug-diagnosis-removal.md:21`, `$S/run-on-worktree.out`

---

## Claim 7: "Acts on $PWD's git repo (like questions.sh), so the installed copy serves any project."

**Location:** `scripts/dev-cycle.sh:16`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the repo root comes from the cwd and that questions.sh resolves it the same way. Does not establish questions.sh's `QUESTIONS_LIVE`/`QUESTIONS_ARCHIVE` overrides, which dev-cycle's own `-f docs/working/questions.md` gate ignores.

`ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"` then `cd "$ROOT"` (`:48-49`). questions.sh: `PROJECT_ROOT="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || pwd)"` (`scripts/questions.sh:84`). Test 11 passes: it runs a copy outside the repo from a subdirectory.

**Evidence:** `scripts/dev-cycle.sh:47-49`, `scripts/questions.sh:84-86`, `$S/bats-head.log`

---

## Claim 8: "Read-only: writes nothing to the repo (one temp file, removed on exit)."

**Location:** `scripts/dev-cycle.sh:17`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the script's own writes and the `questions.sh open` subcommand it calls. Does not establish behavior when `$TMPDIR` points inside the repo, or git's own lazy writes (none seen).

The only write is `qs_err="$(mktemp)"; trap 'rm -f "$qs_err"' EXIT` (`:139`), made only when questions.md and questions.sh both exist. `cmd_open` (`scripts/questions.sh:408-414`) calls `require_files`, `parse_entries` and `printf` and writes no file. `git hash-object -t tree /dev/null` (`:203`) has no `-w`. After a full run on this worktree, `git status --porcelain` showed nothing beyond the pre-existing untracked devcontainer-config files.

Command: `timeout 60 bash scripts/dev-cycle.sh`. Cwd: worktree. Exit 0. 2026-10-01T19:11:23-07:00.

**Evidence:** `scripts/dev-cycle.sh:139,203`, `scripts/questions.sh:408-414`, `$S/run-on-worktree.out`

---

## Claim 9a: "Exit: … 1 bad usage, not a git repo, no default branch or no perl"

**Location:** `scripts/dev-cycle.sh:18-19`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers missing `--since` value, bad `--sample`, bad `--since`, unknown option and non-repo (executed), plus no-perl and no-default-branch (static). Does not establish the exit code of `-h` (0, as expected).

P15: `--since` with no value → 1 (`${2:?}` in a non-interactive shell), `--sample=x` → 1, non-repo → 1 with "Not inside a git repository". Test 16 covers the malformed date and unknown option. No perl: `command -v perl >/dev/null || { …; exit 1; }` (`:23`). No branch: `[[ -n "$MAIN_SHA" ]] || { …; exit 1; }` (`:72`).

**Evidence:** `scripts/dev-cycle.sh:23,37-45,48,72,88`, `$S/probe-s7-exit.log`

---

## Claim 9b: "a failed step exits non-zero mid-digest."

**Location:** `scripts/dev-cycle.sh:19`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exit status after a failing pipeline step with the scrub in place. Does not establish where the error text appears relative to the digest: with `2>&1` it comes first (see Claim 9c).

P5: a `shuf` shim exiting 3 makes the script exit 3. Stdout has sections 1–4 and stops there, and stderr carries "shuf boom". `set -euo pipefail` (`:21`) holds, and the `exec` redirection does not mask the status.

**Evidence:** `scripts/dev-cycle.sh:21,31,165`, `$S/probe-exec.log`

---

## Claim 9c: "Exit: 0 digest printed"

**Location:** `scripts/dev-cycle.sh:18`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers when output is complete and how the two streams are ordered. Does not establish how often a real perl start-up loses this race (200 unperturbed runs never did).

Output goes through process substitutions that bash does not wait for:

```bash
# scripts/dev-cycle.sh:31
exec > >(scrub) 2> >(scrub >&2)
```

The process can therefore exit 0 before the digest is printed. P8 slowed perl start-up by 0.3 s with a shim: `bash dev-cycle.sh > o8` returned exit 0 with o8 at 0 lines, and 47 lines a second later. A pipe reader (`| cat`, bats `run`) waits for EOF, so captures are complete; P7 saw 200/200 complete files without the delay. The two streams are scrubbed by separate perl processes, so under `2>&1` they lose their order. In P6, 20/20 runs printed the failing step's error on line 1, ahead of the sections that ran before it. Exit 0 is correct, but the digest can still be in flight at that moment.

**Evidence:** `scripts/dev-cycle.sh:28-31`, `$S/probe-exec.log` (P6–P8)

---

## Claim 10: "The one scrub for everything printed, stdout and stderr"

**Location:** `scripts/dev-cycle.sh:24`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that both streams pass through `scrub()` from `:31` on, and that nothing repo-derived prints before it. Does not establish what the filter removes (Claim 11).

`:31` redirects both streams. The only earlier output is the fixed perl-missing message at `:23`. Test 5's stderr half passes, and mutant M2 (drop `2> >(scrub >&2)`) makes test 5 fail.

**Evidence:** `scripts/dev-cycle.sh:23-31`, `$S/mutations.log` (M2), `$S/bats-head.log`

---

## Claim 11: "drops C0 controls but TAB and LF, DEL, C1 controls (U+0080-009F), bidi controls (U+200E/F, U+202A-202E, U+2066-2069) and tag characters (U+E0000-E007F)."

**Location:** `scripts/dev-cycle.sh:24-26`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the filter's output for these classes, both when they appear intact and when a C0 byte is placed inside their encodings. Does not establish bidi controls missing from the list (e.g. U+061C), or raw single-byte 0x80–0x9F.

The byte patterns match the listed code points: `\xC2[\x80-\x9F]`, `\xE2\x80[\x8E\x8F\xAA-\xAE]`, `\xE2\x81[\xA6-\xA9]`, `\xF3\xA0[\x80\x81][\x80-\xBF]` (`:29`). Removal runs in one pass, in this order:

```perl
# scripts/dev-cycle.sh:29
s/…//g; tr/\000-\010\013-\037\177//d
```

The multibyte strip runs before C0 deletion. A C0 byte placed inside a sequence hides it from `s///g`, then `tr` deletes the C0 byte and reassembles the sequence. P1 put `\xc2\x01\x9b`, `\xe2\x80\x01\xae` and `\xf3\xa0\x01\x81\x81` into a trigger line. The digest printed `302 233` (U+009B CSI), `342 200 256` (U+202E RLO) and `363 240 201 201` (U+E0041), all three classes the comment says are dropped. Test 5 uses only intact sequences, so it passes. The stated output property is false for repo-controlled text.

Command: P1 in `$S/probe-scrub.log`. Cwd: mktemp repo. Exit 0. 2026-10-01T19:09 -0700.

**Evidence:** `scripts/dev-cycle.sh:24-31`, `test/scripts/dev-cycle.bats:93-104`, `$S/probe-scrub.log` (P1)

---

## Claim 12: "Byte patterns under LC_ALL=C, so invalid UTF-8 in a file name cannot make perl warn or die."

**Location:** `scripts/dev-cycle.sh:26-27`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the default environment and `PERL_UNICODE=S`. Does not establish other `PERL5OPT`/`-C` settings.

In the default environment this holds. P2 used a record named `002-\xff\xfebad.md`: exit 0, no stderr. P16 gave the scrub `\xff\xfe` directly: bytes passed, no warning. `LC_ALL=C` does not neutralise `PERL_UNICODE`, though. With `PERL_UNICODE=S` exported, P16 printed "Malformed UTF-8 character" warnings, and P3 shows U+009B passing the scrub in a full run. The precise version adds "unless PERL_UNICODE / PERL5OPT puts a UTF-8 layer on the standard streams".

**Evidence:** `scripts/dev-cycle.sh:28-30`, `$S/probe-scrub.log` (P2, P3), `$S/probe-scrub-env.log` (P16)

---

## Claim 13: "before the cd: relative paths work"

**Location:** `scripts/dev-cycle.sh:47`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a relative script path run from a subdirectory. Does not establish symlinked installs.

`SCRIPT_DIR` is computed at `:47`, before `cd "$ROOT"` at `:49`. Test 11 passes.

**Evidence:** `scripts/dev-cycle.sh:47-49`, `test/scripts/dev-cycle.bats:156-165`, `$S/bats-head.log`

---

## Claim 14: "DEV_CYCLE_TODAY exists only so tests can pin the date. File names are literal, not pathspecs."

**Location:** `scripts/dev-cycle.sh:50-52`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the export and that tests are the only setter of `DEV_CYCLE_TODAY`. Does not establish a test for the literal-pathspec behavior (no test covers it; earlier rubric C5).

`TODAY="${DEV_CYCLE_TODAY:-$(date +%F)}"; export GIT_LITERAL_PATHSPECS=1` (`:52`). Tests 10 and 18 set `DEV_CYCLE_TODAY`.

**Evidence:** `scripts/dev-cycle.sh:52`, `test/scripts/dev-cycle.bats:149,256`

---

## Claim 15: "Pass git only a hash for the default branch: origin/HEAD comes from the remote, and a branch named `--output=<path>` would reach `git log` as an option."

**Location:** `scripts/dev-cycle.sh:53-54`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every git call that takes the branch: all use `$MAIN_SHA`, and `$MAIN` is only printed. Does not establish `--` separation for other argv.

`sha="$(git rev-parse --verify --quiet "refs/heads/$c^{commit}" …)"` (`:62`). The walks at `:99,102,199,204` use `"$MAIN_SHA"`. Test 15 passes.

**Evidence:** `scripts/dev-cycle.sh:55-72,99,102,199,204`, `$S/bats-head.log`

---

## Claim 16: "ignore future-dated"

**Location:** `scripts/dev-cycle.sh:78`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers record names dated after `$TODAY`. Does not establish anything about the record's content.

`! "$d" > "$TODAY"`. Test 7 includes `cycle-9999-12-31.md` and expects 2026-02-10.

**Evidence:** `scripts/dev-cycle.sh:78`, `test/scripts/dev-cycle.bats:114-121`

---

## Claim 17: Window line — "Merges and commits: those on `$MAIN` at <sha> committed on or after $SINCE, filtered by date after a full walk. Triggers: all of them, from the working tree. Questions, roadmap, idea log: the working tree."

**Location:** `scripts/dev-cycle.sh:92`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what each section reads compared with this line. Does not establish the skill's use of the line.

Sections 1, 4 and 6 read exactly the date-filtered set (`merges_full`/`merges`, `:99-102,184-192`). Three things go unsaid:
- Section 7's 4b file list is a diff from a base commit to `$MAIN_SHA` (`:199-204`). It includes old-dated commits after the base, which is not "committed on or after $SINCE" (the `:197` comment says so, but this line does not).
- The date is the committer's own-zone date (Claim 3).
- "Triggers: all of them" has the inline-trigger residue of Claim 6b.

The `last committed on this branch` dates in sections 2 and 5 read HEAD, and the line's "the working tree" covers only the files' content, which is correct.

**Evidence:** `scripts/dev-cycle.sh:92,99-105,180-207`, `$S/probe-s6s7.log`

---

## Claim 18: "`--since` stops at the first old-dated commit, so one such commit hid every merge after it."

**Location:** `scripts/dev-cycle.sh:96-97`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git's `--since` on a first-parent walk ("after it" in walk order, i.e. topologically older merges). Does not establish git versions that have `--since-as-filter`, which the script does not use.

HEAD's test 4, run against baa46e3's `--since` script, prints "1 merge(s)": the merge made after the 2020 commit is shown, and the three before it are hidden. At HEAD it prints 4.

**Evidence:** `scripts/dev-cycle.sh:96-99`, `$S/bats-headtests-on-baa46e3.log` (test 4)

---

## Claim 19: "%cs is the committer date as YYYY-MM-DD, which compares as a string."

**Location:** `scripts/dev-cycle.sh:98`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the format and that string comparison orders it correctly. Does not establish whose time zone the date is in (the committer's: Claim 3).

P9 prints `%cs: 2026-10-01` for a +09:00 commit. Fixed-width ISO dates compare lexicographically. Tests 4 and 8 pass, and mutant M3 (`>=` → `>`) fails test 8.

**Evidence:** `scripts/dev-cycle.sh:98-102`, `$S/probe-tz.log`, `$S/mutations.log` (M3)

---

## Claim 20: "$n_merges merge(s) on `$MAIN`'s first-parent line; $commits commit(s) reachable from it, merged branches included."

**Location:** `scripts/dev-cycle.sh:104`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that commits are counted over the full DAG and each is filtered by its own committer date. Does not establish that a branch commit made before the window but merged in it is counted (it is not, by design).

`git log "$MAIN_SHA" --format=%cs | awk … | wc -l` (`:102`) has no `--first-parent`. Test 8 counts every commit.

**Evidence:** `scripts/dev-cycle.sh:102,104`, `$S/bats-head.log`

---

## Claim 21: "A newline in a file name would otherwise print a line of its own."

**Location:** `scripts/dev-cycle.sh:117`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `###` heading. Does not establish the trigger body lines, which are prefixed `> ` and so cannot forge a heading.

`echo "### ${f//$'\n'/ } …"` (`:118`). Mutant M1 (`$f` unreplaced) fails test 6. Test 6 also passes on baa46e3, which already had this replacement; R1 was about the carried list, which is now gone.

**Evidence:** `scripts/dev-cycle.sh:117-119`, `$S/mutations.log` (M1), `$S/bats-headtests-on-baa46e3.log`

---

## Claim 22: "The whole clause to the cell's end; prefer a capitalised 'Revisit' (the trigger sentence) over an earlier 'revisit-trigger verdicts' mention."

**Location:** `scripts/dev-cycle.sh:126-127`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers rows without an escaped `\|` in the cell. Does not establish rows where a markdown-escaped pipe ends the clause early (0 such rows in `docs/decisions/log.md` today), or a capitalised "Revisit" in an earlier cell.

`grep -oE 'Revisit[^|]*' … | head -1`, then a case-insensitive fallback (`:128-129`). Test 2 checks a 500-char clause and the preference.

**Evidence:** `scripts/dev-cycle.sh:121-132`, `test/scripts/dev-cycle.bats:51-63`

---

## Claim 23: "`open` prints 'ID  route  slug' in columns of 2+ spaces; a route can contain one space ('you: judgment'), a slug can contain 'trigger'."

**Location:** `scripts/dev-cycle.sh:141-142`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers questions.sh's current `open` format. Does not establish a route containing two consecutive spaces.

`printf '%s  %-14s  %s\n' "$id" "$route" "$slug"` (`scripts/questions.sh:412`). Test 12 passes.

**Evidence:** `scripts/questions.sh:408-414`, `scripts/dev-cycle.sh:143,150`, `$S/bats-head.log`

---

## Claim 24: "Seeded by a hash of the date: same day, same merges; different days usually differ."

**Location:** `scripts/dev-cycle.sh:162-163`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers determinism for the same date and input, and variation across four dates. Does not establish that the sample stays the same when the merge list changes.

`seed="$(printf '%s' "$TODAY" | sha256sum | cut -c1-64)"`, then `shuf … --random-source=<(yes "$seed")` (`:164-165`). Tests 9 and 10 pass.

**Evidence:** `scripts/dev-cycle.sh:162-165`, `$S/bats-head.log`

---

## Claim 25: "A merge whose diff against its first parent touches files but no docs/ path, *.md or README is a step 4 finding to check"

**Location:** `scripts/dev-cycle.sh:181-182`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the classifier on names, prefixes, deletions, renames and newline names. Does not establish octopus or shallow-boundary merges.

```bash
# scripts/dev-cycle.sh:186
… | awk -v RS='\0' 'NF { if ($0 ~ /^docs\// || $0 ~ /\.md$/ || $0 ~ /(^|\/)README/) d++; else c++ } …'
```

`(^|\/)README` is unanchored at the end, so it matches any path component that *begins* with README. In P11, merges touching only `READMEgen.py` or `src/README_tool.sh` were counted as doc changes and not flagged. `docs/` is top-level only (`sub/docs/x.sh` was flagged, correctly). A deletion-only merge and a rename-only merge each count as "1 file(s)" of code. A newline in a name is handled (P11), because mawk splits on `RS='\0'` (P12). The precise version is "a README* path component".

The first-parent question: `--merges` lists only commits with 2+ parents, and a shallow boundary grafts commits as parentless, so `$full^1` always resolves.

**Evidence:** `scripts/dev-cycle.sh:180-193`, `$S/probe-s6s7.log` (P11, P12)

---

## Claim 26a: "Base = the parent of the oldest first-parent commit in the window (the empty tree when that commit is the root)."

**Location:** `scripts/dev-cycle.sh:196-197`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers base selection, with "oldest" meaning topologically earliest in the first-parent walk, and the root fallback. Does not establish whether this is the right base for 4b (Claim 26b).

```bash
# scripts/dev-cycle.sh:199-204
oldest="$(git log "$MAIN_SHA" --first-parent --format='%cs %H' | awk -v s="$SINCE" '$1 >= s { h = $2 } END { print h }')"
if [[ -z "$oldest" ]]; then
  changed=""
else
  base="$(git rev-parse --verify --quiet "$oldest^1" || git hash-object -t tree /dev/null)"
  changed="$(git diff --name-only -z "$base" "$MAIN_SHA" -- skills workflows docs/decisions | tr '\0\n' '\n ')"
```

(excerpt ends :204; the `if` closes at :205 and `changed` is first used at :206-207 — read.) In P13 a 2020-dated commit in the middle of history did not move the base. Test 18 passes, and mutant M5 (no `tr`) fails it.

**Evidence:** `scripts/dev-cycle.sh:196-207`, `$S/probe-s6s7.log` (P13), `$S/mutations.log` (M5)

---

## Claim 26b: "Old-dated commits after it are included: re-reading a file is cheap, missing one is not."

**Location:** `scripts/dev-cycle.sh:197-198`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which changed files the base-to-tip diff reports. Does not establish 4b's thresholds.

The implied guarantee is that no file changed in the window is missed. That fails for net-zero changes. P14 edited `skills/s/SKILL.md` and reverted it, and added and then deleted `docs/decisions/005-x.md`, all in the window. Both lists print 0, because `git diff base MAIN` reports only net differences. Old-dated commits are included as stated. A file deleted in the window is listed under "added or changed" (from the meaning of `--name-only`; paraphrased — no quote available because this follows from git's diff semantics and was not separately executed). The precise version is "a file whose content differs between the base and main is never missed".

**Evidence:** `scripts/dev-cycle.sh:196-215`, `$S/probe-s7-exit.log` (P14)

---

## Claim 27: "The model version is not in git: compare it with the last cycle record's."

**Location:** `scripts/dev-cycle.sh:208`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers agreement with the approved spec. Does not establish that the committed skill on feat/dev-cycle (70cc7dc) has step 4b or a model-version field yet (it has neither).

The approval doc "Dev cycle skill — for your approval" (read via Claude Docs, rev 48) step 7 says the record carries "the model version (4b compares it with the previous record)", and gap #3 says "a model version change isn't in git".

**Evidence:** `scripts/dev-cycle.sh:208`; approval doc https://claude.ai/code/artifact/78a2f851-e696-4a86-bfe8-474212e5e645 (steps 4b and 7, gap #3)

---

## Claim 28: Section 7 labels — "Roadmap Now / In flight / Next", "0 items ready for 6b", "Step 4b (deep-audit triggers)"

**Location:** `scripts/dev-cycle.sh:208-226`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers agreement with the approval doc and counting of top-level `- `, `* ` and `N. ` items under exact `## Now`, `## In flight` and `## Next` headings. Does not establish headings with suffixes (e.g. `## Now (Q4)` counts 0), nested items, or the committed skill (whose roadmap template has Now/Next/Ideas/Done, with no In flight and no 4b/6b).

The approval doc's step 6 lists "Now / In flight … / Next … / Ideas / Done", and step 5's trigger is "roadmap Now + Next hold 0–1 items ready for 6b". Test 18 checks counts of 1/2/1.

**Evidence:** `scripts/dev-cycle.sh:218-226`, `test/scripts/dev-cycle.bats:250-263`, feat/dev-cycle `skills/dev-cycle/SKILL.md:115-118`, approval doc steps 5–6

---

## Claim 29: "Step 5 heads each brainstorm '## Brainstorm YYYY-MM-DD'; ideas are '- ' lines."

**Location:** `scripts/dev-cycle.sh:229`
**Type:** Reference / Architectural
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the committed skill and the approved spec. Does not establish a future skill edit (db0e5ca's body says the skill "must write" this marker).

Neither source says this. The committed step 5 (feat/dev-cycle `SKILL.md:95-102`) does not write to `docs/working/idea-log.md` or write any brainstorm heading. It reads `docs/working/feature-ideas*.md`. The approval doc names `docs/working/idea-log.md` as the seed log, with format "one line per idea, naming its signal", and specifies no `## Brainstorm` heading and no `- ` bullet. The comment states as present fact a contract that the commit message itself calls a choice made without the user. No `idea-log.md` exists on main, so section 7 always prints "No docs/working/idea-log.md" until the skill changes (`$S/run-on-worktree.out`).

**Evidence:** `scripts/dev-cycle.sh:227-241`; feat/dev-cycle `skills/dev-cycle/SKILL.md:95-102`; approval doc ("Seeding vs brainstorm", sources draft); db0e5ca body

---

## Claim 30: "No {n} intervals in the awk regex: mawk, Debian's default awk, lacks them."

**Location:** `scripts/dev-cycle.sh:230`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the installed mawk 1.3.4 20200120 (`/usr/bin/awk` → mawk) and the absence of other awk intervals in the script. Does not establish newer mawk releases, which may support intervals (not checked; no network).

`echo aaaa | mawk '/^a{4}$/'` prints nothing, and `echo 'a{2}' | mawk '/^a{2}$/'` matches the literal. `grep -nE "awk.*\{[0-9]"` finds no awk interval. The `{4}`/`{3}` intervals at `:207,231` are in `grep -E`, which supports them.

Command: the mawk lines above. Cwd: worktree. Exit 0. 2026-10-01T19:08 -0700. Output recorded in this report (one-line results).

**Evidence:** `scripts/dev-cycle.sh:207,221,231-232`

---

## Claim 31: "- Ideas seeded since: $seeded"

**Location:** `scripts/dev-cycle.sh:232,238`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what the counter counts: `- ` lines after the last `## Brainstorm YYYY-MM-DD` heading, or all of them if there is none. Does not establish whether those are ideas seeded *since* the brainstorm or the brainstorm's own output, because no spec defines what a brainstorm writes under its heading.

`awk '/^## Brainstorm …/ { c = 0; next } /^- / { c++ } END { print c + 0 }'` (`:232`). Test 18's fixture puts `- one`/`- two` under the heading and expects "2". Settling this needs the skill's step 5 to define the idea-log layout (see Claim 29).

**Evidence:** `scripts/dev-cycle.sh:229-238`, `test/scripts/dev-cycle.bats:255-260`

---

## Claim 32: "Each test builds a throwaway repo under $BATS_TEST_TMPDIR; this repo is untouched."

**Location:** `test/scripts/dev-cycle.bats:3-4`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers setup and test bodies. Does not establish isolation from a real `~/.claude`, which line 15 handles separately.

`R="$BATS_TEST_TMPDIR/repo"; make_repo "$R" main; cd "$R"` (`:17-19`). After the suite, the worktree's `git status` showed no change.

**Evidence:** `test/scripts/dev-cycle.bats:8-35`, `$S/bats-head.log`

---

## Claim 33: "HOME in the temp dir: the ~/.claude/scripts fallback can't reach the real one."

**Location:** `test/scripts/dev-cycle.bats:14`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the `$HOME/.claude/scripts/questions.sh` fallback at `dev-cycle.sh:137`. Does not establish other HOME-derived paths (none).

`export HOME="$BATS_TEST_TMPDIR/home"` (`:15`).

**Evidence:** `test/scripts/dev-cycle.bats:14-16`, `scripts/dev-cycle.sh:136-137`

---

## Claim 34: test "after a cycle record, every trigger still prints in full and nothing is carried"

**Location:** `test/scripts/dev-cycle.bats:65`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the test passes at HEAD and fails on baa46e3's carry-forward script. Does not establish inline triggers (Claim 6b).

The test fails on baa46e3 and passes at HEAD.

**Evidence:** `test/scripts/dev-cycle.bats:65-78`, `$S/bats-headtests-on-baa46e3.log`, `$S/bats-head.log`

---

## Claim 35a: test "an old-dated commit on main does not hide the merges after it"

**Location:** `test/scripts/dev-cycle.bats:80`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the R3 regression ("after it" in walk order). Does not establish section 7's base under the same scenario (P13 does, separately).

The test fails on baa46e3 ("1 merge(s)") and passes at HEAD ("4 merge(s)").

**Evidence:** `test/scripts/dev-cycle.bats:80-91`, `$S/bats-headtests-on-baa46e3.log`

---

## Claim 35b: "--since used to stop its walk at the old commit and report 0 merges."

**Location:** `test/scripts/dev-cycle.bats:81-82`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the old code on this test's own fixture. Does not establish the rubric's R3 scenario, where nothing was merged after the old commit and "0 merge(s)" was correct.

On this fixture, baa46e3 prints "1 merge(s) … `854f921 2026-10-01 merge: feature 4`", not 0. The old walk shows the merge made after the old commit and hides the three made before it.

**Evidence:** `test/scripts/dev-cycle.bats:81-88`, `$S/bats-headtests-on-baa46e3.log` (test 4 output)

---

## Claim 36: test "the scrub strips C0, C1, bidi and tag characters from stdout and stderr"

**Location:** `test/scripts/dev-cycle.bats:93`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers intact sequences on stdout and an ESC on stderr. Does not establish the interleaved-C0 bypass of Claim 11, which the test does not exercise.

The test fails on baa46e3 and on mutant M2, and passes at HEAD.

**Evidence:** `test/scripts/dev-cycle.bats:93-104`, `$S/mutations.log` (M2), `$S/bats-headtests-on-baa46e3.log`

---

## Claim 37: "A non-repo error message carrying an ESC still reaches stderr scrubbed."

**Location:** `test/scripts/dev-cycle.bats:99`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what the next lines run. Does not establish the "Not inside a git repository" path, which is not exercised.

The next lines run `bash "$DC" $'--bo\033gus'` inside the repo and check "Unknown option: --bogus". The message is the unknown-option error built from argv. Read as "an error not from repo text", the comment holds. Read as the non-repo error, it does not.

**Evidence:** `test/scripts/dev-cycle.bats:99-103`, `scripts/dev-cycle.sh:42`

---

## Claim 38: test "a newline in a decision record's name cannot print a line of its own"

**Location:** `test/scripts/dev-cycle.bats:106`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the section 2 heading (it fails on mutant M1). Does not establish newline names in section 7 (handled by `tr` but untested for newlines) or section 6.

The test fails on mutant M1. It passes on baa46e3, which already replaced LF in the heading.

**Evidence:** `test/scripts/dev-cycle.bats:106-112`, `$S/mutations.log` (M1)

---

## Claim 39: test "--since counts from midnight, not from the current time of day"

**Location:** `test/scripts/dev-cycle.bats:123`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the inclusive date comparison (it fails on mutant M3). Does not establish committer offsets other than local, which the test never creates.

At HEAD no time of day enters the comparison at all: `%cs >= SINCE` (Claim 3). The test still guards inclusivity of the start date. It only stands for "from midnight" when commits are made in the local zone (`GIT_COMMITTER_DATE` with no offset, `:124`). The precise name is "--since includes every commit dated on that day".

**Evidence:** `test/scripts/dev-cycle.bats:123-129`, `$S/mutations.log` (M3), `$S/probe-tz.log`

---

## Claim 40: "No questions-archive.md: questions.sh open exits non-zero."

**Location:** `test/scripts/dev-cycle.bats:200`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `require_files` failing. Does not establish other failure modes of questions.sh.

`[[ $missing -eq 0 ]] || die …` (`scripts/questions.sh:137`). Test 13 passes.

**Evidence:** `scripts/questions.sh:132-138`, `$S/bats-head.log`

---

## Claim 41: test "flags a merge that changed code with no doc change, not one that did both"

**Location:** `test/scripts/dev-cycle.bats:239`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the flag and no-flag cases it builds. Does not establish the `^docs/` branch: mutant M4, which drops it, still passes, because `docs/tool.md` also matches `\.md$`. README handling is also untested (Claim 25).

The test fails on baa46e3 (no section 6) and passes at HEAD. M4 survives.

**Evidence:** `test/scripts/dev-cycle.bats:239-248`, `$S/mutations.log` (M4)

---

## Claim 42: test "prints the step 4b and step 5 inputs"

**Location:** `test/scripts/dev-cycle.bats:250`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listed outputs. Does not establish the records count line: `"in the window: 1"` matches only the skills label, since the records label reads "in the window (is any …): 1".

The test fails on baa46e3 and on mutant M5, and passes at HEAD.

**Evidence:** `test/scripts/dev-cycle.bats:250-263`, `$S/mutations.log` (M5)

---

## Claim 43: d9e4cb9 — "16/16 pass; shellcheck clean."

**Location:** commit d9e4cb9 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers d9e4cb9's two files. Does not establish the environment the author ran in.

Command: `git archive d9e4cb9 …` into a mktemp dir, then `bats test/scripts/dev-cycle.bats` (exit 0, 1..16 all ok) and `shellcheck` on both files (exit 0). Compared against the logged test-count pattern: the count matches.

**Evidence:** `$S/bats-d9e4cb9.log`

---

## Claim 44: d9e4cb9 — "rubric pass 3: R1, R2, A1, A3, A5, A6, C1, C3 lose their code"

**Location:** commit d9e4cb9 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the removal of the carried list, the `Main at:` parsing, the sha lookup, ancestry and base logic, and the "changed since" carried wording. Does not establish C6 (asynchronous filter ordering), which persists and now applies to both streams (Claim 9c). It is not on the list.

The grep in Claim 6a returns no carry code. The rubric's rows are at `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:81-102`.

**Evidence:** `scripts/dev-cycle.sh:1-241`, rubric `:81-105`

---

## Claim 45: d9e4cb9 — "A2: one scrub() filters stdout AND stderr … C0 (but TAB/LF), DEL, C1, bidi controls, tag characters."

**Location:** commit d9e4cb9 message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 11. The "stdout AND stderr, set up before option parsing" part is Verified (Claim 10).

P1 shows C1, RLO and tag characters passing when a C0 byte is interleaved, so A2 is not fully closed.

**Evidence:** `$S/probe-scrub.log` (P1), `scripts/dev-cycle.sh:29`

---

## Claim 46: d9e4cb9 — "R3: merges and commits are walked in full and filtered by committer date (%cs) afterwards" / "The window still defaults to the newest record's file-name date, inclusive"

**Location:** commit d9e4cb9 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers sections 1 and 4 (and later 6). Does not establish the time zone semantics (Claim 3).

See Claims 4, 18 and 19.

**Evidence:** `scripts/dev-cycle.sh:96-102`, `$S/bats-headtests-on-baa46e3.log`

---

## Claim 47: db0e5ca — "18/18 tests pass; shellcheck clean. Script is 241 lines."

**Location:** commit db0e5ca message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers HEAD. Does not establish other bats versions.

bats exit 0 with 1..18 ok; shellcheck exit 0; `wc -l scripts/dev-cycle.sh` = 241.

**Evidence:** `$S/bats-head.log`, `$S/shellcheck.log`

---

## Claim 48: db0e5ca — "All stateless: nothing here reads a cycle record."

**Location:** commit db0e5ca message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers sections 6–7 ("here"). Does not establish the script as a whole, which reads cycle-record file names (not contents) for the default window (`:75-79`).

Sections 6–7 (`:180-241`) open no file under `docs/working/cycles/`. `:208` only tells the reader to compare.

**Evidence:** `scripts/dev-cycle.sh:180-241`

---

## Claim 49: db0e5ca — "Section 6: merges whose first-parent diff touches files but no docs/ path, *.md or README"

**Location:** commit db0e5ca message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 25.

"README" means any path component that starts with README (P11).

**Evidence:** `$S/probe-s6s7.log` (P11)

---

## Claim 50: db0e5ca — "the 4b window base is the parent of the oldest in-window first-parent commit (over-includes, never misses)"

**Location:** commit db0e5ca message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claims 26a/26b.

The base description is right. "Never misses" fails for net-zero changes in the window (P14).

**Evidence:** `$S/probe-s7-exit.log` (P14)

---

## Claim 51: db0e5ca — "the idea log marker is '## Brainstorm YYYY-MM-DD' at docs/working/idea-log.md, which the skill (feat/dev-cycle) must write"

**Location:** commit db0e5ca message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the skill does not yet write it, which is why the sentence says "must". Does not establish that the skill will be changed.

feat/dev-cycle `SKILL.md` has no `idea-log` or `## Brainstorm` text (grep, 70cc7dc).

**Evidence:** feat/dev-cycle `skills/dev-cycle/SKILL.md:95-102`

---

## Claims Requiring Attention

### Incorrect
- **Claim 11** (`scripts/dev-cycle.sh:24-26`), **Legibility-target: for-author**: the scrub does not drop C1/bidi/tag characters when a C0 byte sits inside their encoding. `tr` runs after `s///g` and reassembles them (P1: U+009B, U+202E and U+E0041 reach stdout). Delete C0 first, or loop until the line stops changing.
- **Claim 29** (`scripts/dev-cycle.sh:229`), **Legibility-target: for-author**: "Step 5 heads each brainstorm '## Brainstorm YYYY-MM-DD'". Neither the committed skill nor the approval doc says this, and nothing writes `docs/working/idea-log.md`. The comment presents a pending contract as fact.
- **Claim 35b** (`test/scripts/dev-cycle.bats:81-82`), **Legibility-target: for-author**: the old code reported 1 merge on this fixture, not 0.
- **Claim 45** (commit d9e4cb9), **Legibility-target: for-author**: the A2 scrub list, same defect as Claim 11 (immutable history).

### Stale
- None.

### Mostly Accurate
- **Claim 3** (`:10`), **for-author**: the date is the committer's own time zone date. A merge at local 04:30 on the start day by a −12:00 committer is excluded (P10b).
- **Claim 6b** (`:15`), **for-author**: "every trigger" means `## Revisit triggers` sections and log rows. The inline trigger at `docs/decisions/013-…md:21` is not printed.
- **Claim 9c** (`:18`), **for-author**: process substitutions are not waited for. Exit 0 can precede the digest (P8, delayed perl), and under `2>&1` errors print first (P6, 20/20).
- **Claim 12** (`:26-27`), **for-author**: holds unless `PERL_UNICODE`/`PERL5OPT` adds a UTF-8 layer. Then perl warns on invalid UTF-8 and C1 passes (P3, P16).
- **Claim 17** (`:92`), **for-author**: the Window line does not say that section 7's file list is base-to-tip (old-dated commits included), or that dates are committer-zone.
- **Claim 25** / **Claim 49** (`:181-182`; db0e5ca), **for-author**: "README" matches any component starting with README (`READMEgen.py`, `src/README_tool.sh` count as docs).
- **Claim 26b** / **Claim 50** (`:197-198`; db0e5ca), **for-author**: "never misses" fails for net-zero changes (edit and revert, add and delete) in the window (P14).
- **Claim 37** (`bats:99`), **for-author**: the error tested is the unknown-option error, not a non-repo error.
- **Claim 39** (`bats:123`), **for-author**: no time of day enters the comparison any more. The test guards date inclusivity for local-zone commits only.

### Unverifiable
- **Claim 31** (`:238`), **Legibility-target: for-orchestrator-synthesis**: "Ideas seeded since" counts every `- ` line after the last heading. Whether that means "since" depends on an idea-log layout no spec defines yet.

Legibility-target for all Verified claims (1, 2, 4, 5, 6a, 7, 8, 9a, 9b, 10, 13–16, 18–24, 26a, 27, 28, 30, 32–34, 35a, 36, 38, 40–44, 46–48, 51): for-orchestrator-synthesis.

### Brief checks answered
- Prior findings: R1, R2, A1, A3, A5, A6, C1 and C3 have no remaining code (Claim 44). R3 is fixed (Claims 18, 35a). A2 is only partly fixed (Claim 11). A4 is mostly fixed (Claim 17). C6 persists on both streams (Claim 9c). The new code introduces no carry state.
- Repo text printing its own line: record headings (replaced), trigger bodies (`> `), log rows (single line), questions (`- `), samples (`- `), roadmap (`> `), section 6 (`%s` subject), section 7 names (`tr` plus indent). No new forging path was found. The scrub's reassembly bypass (Claim 11) is a control-character issue, not a line-forging one.
- Other awk `{n}` intervals: none (Claim 30).
- Hallucination-pattern log: not updated. No Incorrect verdict is a fabricated symbol or API, and the brief forbids writing outside this report.

---

## Goal-Alignment Note

**Success criterion (verbatim from the brief):** "a markdown report saved at the path your role instructions give, structured per your skill file."

**Answered:** All ten "claims that particularly need checking" were verdicted, most by execution:
- header (Claims 6–9c)
- scrub, plus completeness, order and status (10–12, 9b, 9c)
- post-walk filter and time zones (3, 18, 19, 39)
- Window line (17)
- section 2 and line forging (6b, 21, 22, "Brief checks")
- section 6 (25)
- section 7 (26a, 26b, 28, 29, 31)
- mawk (30)
- both commit messages (43–51)
- new tests, run against baa46e3 and against mutants (34–42)

The report is saved at `docs/reviews/code-fact-check-report-r1-digest-final4.md` with `Commit: db0e5ca` first.

**Out of scope:** files other than the two scoped ones (read only as context: questions.sh, the rubric, feat/dev-cycle's SKILL.md, the approval doc). Code-quality judgments, and whether the defects block merge, are left to the critics and the rubric.

**Escalate:** Claim 11 is the substantive correctness finding. The one scrub that Q-101 [1] asked for can be bypassed by repo-controlled bytes, so A2 is not closed. With carry-forward cut, a forged control sequence no longer steers the window, but it still reaches the terminal. Claim 29 is a cross-unit contract gap: section 7's step 5 input reads a file and heading that nothing writes yet.

**Questions / Decisions:**
- Claim 3: should the window be local-zone midnight (convert to `%ct` and compare with `date -d "$SINCE" +%s`), or is committer-zone dating accepted and documented?
- Claim 31: whether the idea-log layout is the skill's decision to make first.
