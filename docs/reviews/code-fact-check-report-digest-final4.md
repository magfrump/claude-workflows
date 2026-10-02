**Commit:** db0e5ca
**Replication:** k=3

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-digest (branch feat/dev-cycle-digest)
**Scope:** `git diff main...HEAD -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (both new, 241 + 263 lines), plus the commit messages of d9e4cb9 and db0e5ca. Final pass 4. Merged by the orchestrator from `code-fact-check-report-r{1,2,3}-digest-final4.md` (all `Commit: db0e5ca`): most-severe-wins verdicts, union of annotations, emitted at the finest granularity any replicate used.
**Checked:** 2026-10-01
**Total claims checked:** 62
**Summary:** 39 verified, 16 mostly accurate, 0 stale, 6 incorrect, 1 unverifiable

Execution provenance. Each replicate ran its own commands under `timeout` between 2026-10-01T19:06 and 19:14 -07:00, in `mktemp -d` throwaway repos, writing nothing into the worktree except its report. Logs live under the session scratchpad `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/`, one directory per replicate: r1 `fcl-final4/` (probes P1–P16, mutants M1–M5), r2 `fcr2-logs/` (runs E1–E13, mutants M1–M8), r3 `fc-r3-logs/` (runs E1–E13, mutants M1–M6). Probe and mutant numbers are per-replicate and are always cited with their replicate. All three replicates ran the suite at HEAD (18/18 ok), shellcheck (clean), d9e4cb9's suite (16/16), and HEAD's tests against baa46e3's script (tests 1, 3, 4, 5, 17, 18 fail).

---

## Claim 1: "The dev-cycle skill (skills/dev-cycle/SKILL.md) runs the judgment steps on top of this digest."

**Location:** `scripts/dev-cycle.sh:4`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the referenced file exists in the stacked unit (feat/dev-cycle, 70cc7dc), with step 0 reading this digest. Does not establish that the file exists on this branch or on main (it exists on neither), or that the skill text matches sections 6–7 (see Claims 30, 31).
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

r1: `ls skills/dev-cycle` fails in this worktree, while `git show feat/dev-cycle:skills/dev-cycle/SKILL.md` has `### 0. Digest` at :39. The digest is the lower unit of the split.

**Evidence:** `scripts/dev-cycle.sh:4`; feat/dev-cycle `skills/dev-cycle/SKILL.md:39`

---

## Claim 2: "Everything that needs no judgment lives here, because steps that only prose asks for do not run (scripts/questions.sh header; Q-074)."

**Location:** `scripts/dev-cycle.sh:5-6`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both cited sources exist and say this; does not establish that every no-judgment step of the skill actually lives in this script.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—
**Replicate annotations:** r1: verdicted only the clause "steps that only prose asks for do not run (…)" · r1: "Does not establish the underlying empirical claim."
**Legibility-target:** for-orchestrator-synthesis

r2: `scripts/questions.sh:8` reads `# log went unwritten for nine runs, both because only prose asked for them.`, and `docs/working/questions.md:67` holds `### Q-074 · failure-pattern-writer-trigger`.

**Evidence:** `scripts/questions.sh:5-11`, `docs/working/questions.md:67`

---

## Claim 3: "--since   start of the cycle window: merges committed on or after this date."

**Location:** `scripts/dev-cycle.sh:10`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the date comparison in all three walks (`:99`, `:102`, `:199`). Does not establish behavior for author dates (`%ad` is printed but never filtered on).
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r2+r3: "does not establish section 7's file list(s), which use a different base rule" · r1+r2+r3: the meaning changed from the pre-d9e4cb9 local-midnight window (r3: "The old text said '(midnight, local time)'") · r2: "For a solo developer committing in one zone the two readings agree."
**Legibility-target:** for-author

The filter compares `%cs` (committer date in the committer's own time zone) with the date as strings (`:99`, `awk -v s="$SINCE" '$1 >= s'`). r1 P10b (-0700 machine): a merge at 2026-09-30T23:30-12:00 (local Oct 1 04:30) has `%cs` 2026-09-30, so `--since=2026-10-01` leaves it out; P9 shows the reverse for a +09:00 commit at local Sep 30 09:30. r2 E6 and r3 P4 reproduce the same exclusion/inclusion pattern. Precise wording: "on or after this date, as each committer's own time zone dates it".

**Evidence:** `scripts/dev-cycle.sh:96-102`; r1 `fcl-final4/probe-tz.log` (P9, P10b); r2 `fcr2-logs/probe1.txt` (P2); r3 `fc-r3-logs/probes.log` (P4)

---

## Claim 4: "Default: the date in the newest docs/working/cycles/cycle-YYYY-MM-DD.md (only its file name is read), else 14 days ago. The digest says which."

**Location:** `scripts/dev-cycle.sh:11-12`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers record selection by file name (future-dated names ignored), the 14-day fallback and the source note; does not establish behaviour for a lexically valid but impossible name such as `cycle-2026-13-45.md`, which would be chosen and then rejected by the `--since must be a real YYYY-MM-DD date` check at `:88` (static reading, not run).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "Does not establish behavior for a cycle record that is a directory or a dangling symlink (both skipped by `-f`)." · r3 (Claim 12 scope, same substance as r2): malformed glob-matching dates such as `cycle-2026-99-99.md` are rejected later at `:88`
**Legibility-target:** for-orchestrator-synthesis

The loop at `:75-79` only globs names and never opens a record; fallback `SINCE="$(date -d "$TODAY - 14 days" +%F)"`. Tests 1 and 7 pass in all three replicates; r1's run on this worktree prints "since 2026-09-17 (from no cycle record found …)".

**Evidence:** `scripts/dev-cycle.sh:74-87`; `test/scripts/dev-cycle.bats:114-121`; r2 `fcr2-logs/bats-head.txt`

---

## Claim 5: "--sample  how many merges to sample for the spot-check (default 2)."

**Location:** `scripts/dev-cycle.sh:13`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the default and the use of N. Does not establish behavior when N exceeds the number of merges (shuf prints all).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—
**Replicate annotations:** r2: "does not establish anything about sample quality"
**Legibility-target:** for-orchestrator-synthesis

`SAMPLE=2` (`:34`); `shuf -n "$SAMPLE"` (`:165`). Test 9 passes.

**Evidence:** `scripts/dev-cycle.sh:34,165`; r1 `fcl-final4/bats-head.log`

---

## Claim 6a: "nothing carries forward."

**Location:** `scripts/dev-cycle.sh:15`
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every readable `docs/decisions/NNN-*.md` that has a `## Revisit triggers` heading, and every log row matching `revisit`. Does not hold for an unreadable record, which is dropped silently.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Mostly accurate (compound)
**Replicate annotations:** collation note: r3's compound Mostly-accurate residue (unreadable record skipped) attaches to the "every trigger" half; all three replicates found no carry-forward code and test 3 failing on baa46e3 · r1: "Does not establish what the skill does with the previous record's verdicts."
**Legibility-target:** for-author

r3: the carry-forward code is gone (a grep for `carr|Main at|merge-base|cmp ` matches only this comment; r1 and r2 ran equivalent greps with the same result). Test 3 passes at HEAD and fails against baa46e3. One case slips through: `grep -q '^## Revisit triggers' "$f" || continue` (`:113`) swallows grep's exit 2 on an unreadable file. r3 E11 made `001-a.md` mode 000: the digest exited 0, section 2 printed only `002-b.md`, and the only trace was `grep: docs/decisions/001-a.md: Permission denied` on stderr.

**Evidence:** `scripts/dev-cycle.sh:15,109-133`; r3 `fc-r3-logs/probe-unreadable.log`, `fc-r3-logs/bats-headtests-on-baa46e3.log`; r1 `fcl-final4/bats-headtests-on-baa46e3.log`

---

## Claim 6b: "Every revisit trigger is printed in full every run"

**Location:** `scripts/dev-cycle.sh:15` (also `:108`, "Every trigger, in full")
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `## Revisit triggers` section in `docs/decisions/NNN-*.md` and every numbered log row containing "revisit". Does not establish coverage of triggers written inline in a record's body, of record names outside the 3-digit glob, or of blank lines inside a section.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound) · r3=Mostly accurate (compound)
**Replicate annotations:** r3: "an unreadable record is dropped silently" (exit 0, only a grep stderr line; E11) · r1+r2: records outside `docs/decisions/[0-9][0-9][0-9]-*.md` (4-digit numbers) not covered; r2: "This repo holds no 4-digit records today" · r2: headings spelled other than `## Revisit triggers` exactly, and log-row text before the first "Revisit" in its cell, not covered · r1+r2: blank lines inside a section are dropped (`on && NF`)
**Legibility-target:** for-author

r1: section 2 reads only two shapes (`trig()` awk over `## Revisit triggers` sections, `:110-113`, and log rows to `:132`). `docs/decisions/013-failure-pattern-library-after-bug-diagnosis-removal.md:21` ends with an inline trigger, "Revisit if the pattern-learning loop visibly decays.", has no such heading, and is not printed by the run on this worktree. "Every trigger" is precise for the two structured forms only.

**Evidence:** `scripts/dev-cycle.sh:107-133`, `docs/decisions/013-failure-pattern-library-after-bug-diagnosis-removal.md:21`; r1 `fcl-final4/run-on-worktree.out`; r3 `fc-r3-logs/probe-unreadable.log`

---

## Claim 7: "Acts on $PWD's git repo (like questions.sh), so the installed copy serves any project."

**Location:** `scripts/dev-cycle.sh:16`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the repo root comes from the cwd and that questions.sh resolves it the same way. Does not establish questions.sh's `QUESTIONS_LIVE`/`QUESTIONS_ARCHIVE` overrides, which dev-cycle's own `-f docs/working/questions.md` gate ignores.
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

`ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"` then `cd "$ROOT"` (`:48-49`); questions.sh uses `git -C "$PWD" rev-parse --show-toplevel` (`scripts/questions.sh:84`). Test 11 runs a copy outside the repo from a subdirectory and passes.

**Evidence:** `scripts/dev-cycle.sh:47-49`, `scripts/questions.sh:84-86`; r1 `fcl-final4/bats-head.log`

---

## Claim 8: "Read-only: writes nothing to the repo (one temp file, removed on exit)."

**Location:** `scripts/dev-cycle.sh:17`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a full run on a clone of this repo, which has `questions.md`, so the temp-file path ran; does not establish removal when the script is killed by a signal, or that `$TMPDIR` lies outside the repo.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "Does not establish … git's own lazy writes (none seen)" · r3: SIGKILL specifically cannot be caught by the EXIT trap · r1: `cmd_open` (`scripts/questions.sh:408-414`) writes no file
**Legibility-target:** for-orchestrator-synthesis

The only temp file is `qs_err="$(mktemp)"; trap 'rm -f "$qs_err"' EXIT` (`:139`); `git hash-object -t tree /dev/null` (`:203`) has no `-w`. r2 E13: a full run on a scratch clone changed no file anywhere, `.git` included (`find . -newer stamp` gave 0), and a private `TMPDIR` was empty afterwards. r1 (`git status --porcelain` clean) and r3 (`.git` mtime listing identical) agree.

**Evidence:** `scripts/dev-cycle.sh:139,203`; r2 `fcr2-logs/probe7.txt`; r3 `fc-r3-logs/probe-ro.log`; r1 `fcl-final4/run-on-worktree.out`

---

## Claim 9a: "Exit: … 1 bad usage, not a git repo, no default branch or no perl"

**Location:** `scripts/dev-cycle.sh:18-19`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers missing `--since` value, bad `--sample`, bad `--since`, unknown option and non-repo (executed), plus no-perl and no-default-branch (static). Does not establish the exit code of `-h` (0, as expected).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r3: "Does not establish the exit code of a mid-digest failure" (Claim 9b) · r2+r3: no-perl executed (r2: PATH without perl; r3: `PATH=/nonexistent`), printing `dev-cycle.sh needs perl (to scrub its output)`, exit 1
**Legibility-target:** for-orchestrator-synthesis

r1 P15: `--since` with no value → 1 (`${2:?}`), `--sample=x` → 1, non-repo → 1 with "Not inside a git repository". Test 16 covers the malformed date and unknown option. No perl: `:23`; no branch: `:72`.

**Evidence:** `scripts/dev-cycle.sh:23,37-45,48,72,88`; r1 `fcl-final4/probe-s7-exit.log`; r3 `fc-r3-logs/probe-misc.log`

---

## Claim 9b: "a failed step exits non-zero mid-digest."

**Location:** `scripts/dev-cycle.sh:19`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers steps run as plain commands or assignments under `set -euo pipefail`. Does not hold for failures behind `|| continue`, `|| true`, or inside an `echo "$(…)"` argument.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r1+r2: with `2>&1` the error text comes first, ahead of sections that ran before it (r1 P6 20/20; r2 E9 10/10) · r1: P5 `shuf` shim exiting 3 → script exits 3, stdout stops after section 4 · r2: E9 deleted root commit object → exit 128 after the header and Window line
**Legibility-target:** for-author

r3: the status does propagate through the `exec` redirect (E7 P3: unreadable `docs/roadmap.md` made the awk at `:175` fail, exit 2 after the section 5 heading). Some failures do not exit: an unreadable decision record (`grep -q … || continue`, `:113`) exits 0 (Claim 6a, E11); `echo "- $(git log -1 … "$full") …"` (`:190`) would mask a `git log` failure, because `set -e` ignores a failing substitution inside an argument (bash semantics, not reproduced).

**Evidence:** `scripts/dev-cycle.sh:21,113,175,190`; r3 `fc-r3-logs/probes.log` (P3), `fc-r3-logs/probe-unreadable.log`; r1 `fcl-final4/probe-exec.log` (P5); r2 `fcr2-logs/probe4.txt`

---

## Claim 9c: "Exit: 0 digest printed"

**Location:** `scripts/dev-cycle.sh:18`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers when output is complete and how the two streams are ordered. Does not establish how often a real perl start-up loses this race (200 unperturbed runs never did).
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r3: "Does not establish ordering inside stdout, which is preserved because one perl handles it." · r3: E8 P9 `(bash dev-cycle.sh --bogus; echo AFTER) >o 2>&1` put `AFTER` before the script's error line in 20/20 runs; P10 (300,039 lines) file short right after exit in 1/20 runs · r2 (Claim 8c): in E7 P4 the output file did not grow after exit in any of 20 runs ("no late writes were seen"); with `2>&1` the error came before the digest header 10/10 (E9) · r1+r2+r3: a pipe reader (`| cat`, `$(…)`, bats `run`) waits for EOF and gets everything
**Legibility-target:** for-author

r1: output goes through process substitutions bash does not wait for (`exec > >(scrub) 2> >(scrub >&2)`, `:31`). P8 slowed perl start-up by 0.3 s with a shim: `bash dev-cycle.sh > o8` returned exit 0 with o8 at 0 lines, and 47 lines a second later. P7 saw 200/200 complete files without the delay. Under `2>&1`, P6 printed the failing step's error on line 1 in 20/20 runs. Exit 0 is correct, but the digest can still be in flight at that moment.

**Evidence:** `scripts/dev-cycle.sh:28-31`; r1 `fcl-final4/probe-exec.log` (P6–P8); r3 `fc-r3-logs/probes2.log` (P9, P10)

---

## Claim 10: "The one scrub for everything printed, stdout and stderr"

**Location:** `scripts/dev-cycle.sh:24`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that every byte the script and its children write after `:31` passes the filter, and that the stdout captured through a pipe or file is complete; does not establish ordering between the two streams (with `2>&1` into a file, the error came before the digest header in 10 of 10 runs, E9). It also does not cover the constant perl-missing message at `:23`, which is printed before the `exec` and is not filtered.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r3: the perl-missing message at `:23` is fixed text, the only output before the `exec` · r3: "perl's own warnings, which go to the original stderr unscrubbed (Claim 8)" (Claim 12 here) · r1: "Does not establish what the filter removes (Claim 11)."
**Legibility-target:** for-orchestrator-synthesis

`exec > >(scrub) 2> >(scrub >&2)` (`:31`) redirects both descriptors before option parsing (`:33`). Mutant M2 (r1, r2) / M3 (r3), which drops the stderr half, fails test 5. r2: exit status passes through (Claim 9b: 128).

**Evidence:** `scripts/dev-cycle.sh:23,31`; r2 `fcr2-logs/mutations.txt` (M2), `fcr2-logs/probe2.txt` (P4); r1 `fcl-final4/mutations.log` (M2); r3 `fc-r3-logs/mut-M3.log`

---

## Claim 11: "drops C0 controls but TAB and LF, DEL, C1 controls (U+0080-009F), bidi controls (U+200E/F, U+202A-202E, U+2066-2069) and tag characters (U+E0000-E007F)."

**Location:** `scripts/dev-cycle.sh:24-26`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the filter's output for these classes, both when they appear intact and when a C0 byte is placed inside their encodings. Does not establish bidi controls missing from the list (e.g. U+061C), or raw single-byte 0x80–0x9F.
**Replicate verdicts:** r1=Incorrect · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r2: with `PERL_UNICODE=SDA` in the caller's environment the byte patterns stop matching and `a\xc2\x9bb\xe2\x80\xaec` comes out unchanged; `LC_ALL=C` does not prevent this; the script neither clears `PERL_UNICODE` nor passes `-C0` (E8) · r3: "Does not establish behaviour when the caller's environment sets `PERL_UNICODE` or `PERL5OPT`" · r1+r2: raw 8-bit C1 bytes (invalid UTF-8) not covered; r2 E7 P3d: a raw `\x9B` passes through · r1+r2: unlisted bidi/format controls pass (r1: U+061C; r2: U+2028 and U+061C) · r1+r2+r3: the byte patterns match the listed code points, and intact sequences are removed (test 5; r3 E9 default env; r3 M4 removing the C1 pattern fails test 5) · r1: "Test 5 uses only intact sequences, so it passes."
**Legibility-target:** for-author

r1: removal runs in one pass, `s/…//g; tr/\000-\010\013-\037\177//d` (`:29`): the multibyte strip runs before C0 deletion. A C0 byte placed inside a sequence hides it from `s///g`, then `tr` deletes the C0 byte and reassembles the sequence. P1 put `\xc2\x01\x9b`, `\xe2\x80\x01\xae` and `\xf3\xa0\x01\x81\x81` into a trigger line; the digest printed `302 233` (U+009B CSI), `342 200 256` (U+202E RLO) and `363 240 201 201` (U+E0041) — all three classes the comment says are dropped. The stated output property is false for repo-controlled text.

**Evidence:** `scripts/dev-cycle.sh:24-31`, `test/scripts/dev-cycle.bats:93-104`; r1 `fcl-final4/probe-scrub.log` (P1); r2 `fcr2-logs/probe3.txt`, `fcr2-logs/probe2.txt` (P3d); r3 `fc-r3-logs/scrub-probe.log`

---

## Claim 12: "Byte patterns under LC_ALL=C, so invalid UTF-8 in a file name cannot make perl warn or die."

**Location:** `scripts/dev-cycle.sh:26-27`
**Type:** Behavioral / Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stated mechanism (that `LC_ALL=C` is what makes the patterns byte patterns and keeps invalid UTF-8 harmless); does not establish any failure under the default environment, where the conclusion holds.
**Replicate verdicts:** r1=Mostly accurate · r2=Incorrect · r3=Mostly accurate
**Replicate annotations:** r1+r3: in the default environment the conclusion holds (r1 P2: record named `002-\xff\xfebad.md`, exit 0, no stderr; P16 bytes pass, no warning; r3 E9 clean) · r1+r3: with `PERL_UNICODE=S`/`SD` (r3 also `PERL5OPT=-CSD`) perl prints "Malformed UTF-8 character" and C1/RLO pass (r1 P3, P16; r3 E9) · r3: "`LC_ALL=C` neutralises only locale-conditional UTF-8 layers (the `L` flag of `-C`)" · r1: "Does not establish other `PERL5OPT`/`-C` settings." · r2+r3: pin it in the script (r2: `PERL_UNICODE=` / `-C0`; r3: `env -u PERL_UNICODE -u PERL5OPT` or `perl -C0`)
**Legibility-target:** for-author

r2: the mechanism is wrong. Perl's I/O stays byte-oriented under any `LC_ALL` unless `-C` or `PERL_UNICODE` asks otherwise. Without `LC_ALL=C` but with an installed UTF-8 locale (`LC_ALL=C.UTF-8`), invalid input `bad\xff\xfe a\xc2\x9bb` gave no warning and was scrubbed (E7 P3b). With `PERL_UNICODE=SDA` and `LC_ALL=C` exactly as the scrub sets it, perl printed `Malformed UTF-8 character: \xff\xfe... in transliteration (tr///)` twice and C1/RLO passed (E8). The setting's one measured effect is silencing `perl: warning: Setting locale failed` when the inherited locale is not installed (E7 P3a). The comment should name the real dependency: no `PERL_UNICODE`/`-C`.

**Evidence:** `scripts/dev-cycle.sh:26-29`; r2 `fcr2-logs/probe2.txt` (P3a, P3b), `fcr2-logs/probe3.txt`, `fcr2-logs/p3c-err.txt`; r1 `fcl-final4/probe-scrub-env.log` (P16); r3 `fc-r3-logs/scrub-probe.log`

---

## Claim 13: "before the cd: relative paths work"

**Location:** `scripts/dev-cycle.sh:47`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a relative script path run from a subdirectory. Does not establish symlinked installs.
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

`SCRIPT_DIR` is computed at `:47`, before `cd "$ROOT"` at `:49`. Test 11 (relative path from `sub/dir`) passes.

**Evidence:** `scripts/dev-cycle.sh:47-49`, `test/scripts/dev-cycle.bats:156-165`

---

## Claim 14: "DEV_CYCLE_TODAY exists only so tests can pin the date. File names are literal, not pathspecs."

**Location:** `scripts/dev-cycle.sh:50-52`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the export and that tests are the only setter of `DEV_CYCLE_TODAY`. Does not establish a test for the literal-pathspec behavior (no test covers it; earlier rubric C5).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish that no user sets `DEV_CYCLE_TODAY` outside tests" · r3: every later path-taking git call (`:116`, `:172`, `:204`) runs with literal pathspecs
**Legibility-target:** for-orchestrator-synthesis

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
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "Does not re-examine the origin/HEAD trust model." · r2+r3: option-like names are skipped (`[[ "$c" == -* ]] && continue`, `:61`)
**Legibility-target:** for-orchestrator-synthesis

`sha="$(git rev-parse --verify --quiet "refs/heads/$c^{commit}" …)"` (`:62`); the walks at `:99,102,199,204` use `"$MAIN_SHA"`. Test 15 passes (r3: the victim file stays `keep`).

**Evidence:** `scripts/dev-cycle.sh:55-72,99,102,199,204`; `test/scripts/dev-cycle.bats:218-228`

---

## Claim 16: "ignore future-dated"

**Location:** `scripts/dev-cycle.sh:78`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers records dated after `$TODAY`. Does not cover malformed dates that still match the glob (for example `cycle-2026-99-99.md`), which are rejected later by the `--since` validation at `:88`.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "Does not establish anything about the record's content."
**Legibility-target:** for-orchestrator-synthesis

`[[ "$d" > "$last_record" && ! "$d" > "$TODAY" ]]`. Test 7 includes `cycle-9999-12-31.md` and selects 2026-02-10.

**Evidence:** `scripts/dev-cycle.sh:75-79`; `test/scripts/dev-cycle.bats:114-121`

---

## Claim 17: Window line — "Merges and commits: those on `$MAIN` at <sha> committed on or after $SINCE, filtered by date after a full walk. Triggers: all of them, from the working tree. Questions, roadmap, idea log: the working tree."

**Location:** `scripts/dev-cycle.sh:92`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers sections 1, 2, 3, 4, 5, 6 and the step 5 inputs. Does not describe section 7's step-4b file list, and "committed on" is the committer's own-zone date.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1: "Does not establish the skill's use of the line." · r1: "Triggers: all of them" carries the inline-trigger residue of Claim 6b · r3: the "last committed on this branch" dates in sections 2 and 5 come from HEAD, not `$MAIN` (`:116`, `:172`), which the line does not mention (labelled "this branch" in the output) · r1: on the same dates, "the line's 'the working tree' covers only the files' content, which is correct" · r2+r3: section 7's net diff also omits changes that cancel out (Claim 27b) · r2: suggested addition "4b lists: the net diff on `$MAIN` from just before the oldest in-window commit."
**Legibility-target:** for-author

Sections 1, 4 and 6 read `merges_full`/`merges` filtered at `:99`, matching the line with Claim 3's time-zone qualifier. Section 7's step-4b list is not "those committed on or after $SINCE": it is the net diff from the parent of the oldest in-window first-parent commit to `MAIN_SHA` (`git diff --name-only -z "$base" "$MAIN_SHA" -- skills workflows docs/decisions`, `:204`), which includes old-dated commits after the base (all three replicates).

**Evidence:** `scripts/dev-cycle.sh:92,99,116,172,199-204`; r3 `fc-r3-logs/probes.log` (P4), `fc-r3-logs/probes2.log` (P6b); r1 `fcl-final4/probe-s6s7.log`

---

## Claim 18: "`--since` stops at the first old-dated commit, so one such commit hid every merge after it."

**Location:** `scripts/dev-cycle.sh:96-97`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what baa46e3's `--since` walk returned in test 4's scenario. Does not establish git's walk-stop rule beyond that observed scenario.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r1+r2: "after it" is true in walk order (topologically older merges) — the reading under which they verdicted Verified · r1: "Does not establish git versions that have `--since-as-filter`, which the script does not use." · r2: E6 P1 chain init, a, old (2020), b, merge: `git log --since=yesterday --first-parent` listed only the merge and `b`; on a full walk side branches still list
**Legibility-target:** for-author

r3: running HEAD's test 4 against baa46e3's script (E4) printed "1 merge(s) …" and listed `merge: feature 4`, the merge made after the old commit in history; the three merges older than the old commit were hidden. "After it" is right only in walk order (newest first). Precise version: "so one such commit hid every merge older than it".

**Evidence:** `scripts/dev-cycle.sh:96-102`; r3 `fc-r3-logs/bats-headtests-on-baa46e3.log` (test 4); r2 `fcr2-logs/probe1.txt` (P1)

---

## Claim 19: "%cs is the committer date as YYYY-MM-DD, which compares as a string."

**Location:** `scripts/dev-cycle.sh:98`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the format and that string comparison orders it correctly. Does not establish whose time zone the date is in (the committer's: Claim 3).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

r1 P9 prints `%cs: 2026-10-01` for a +09:00 commit; fixed-width ISO dates compare lexicographically; tests 4 and 8 pass, and r1 mutant M3 (`>=` → `>`) fails test 8. r3: `SINCE` is validated to the same shape at `:88`.

**Evidence:** `scripts/dev-cycle.sh:88,98-102`; r1 `fcl-final4/probe-tz.log`, `fcl-final4/mutations.log` (M3)

---

## Claim 20: "$n_merges merge(s) on `$MAIN`'s first-parent line; $commits commit(s) reachable from it, merged branches included."

**Location:** `scripts/dev-cycle.sh:104`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that commits are counted over the full DAG and each is filtered by its own committer date. Does not establish that a branch commit made before the window but merged in it is counted (it is not, by design).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—
**Replicate annotations:** r2: "does not establish the time-zone semantics of 'in the window' (Claim 2)" (Claim 3 here)
**Legibility-target:** for-orchestrator-synthesis

`git log "$MAIN_SHA" --format=%cs | awk … | wc -l` (`:102`) has no `--first-parent`; merges come from `--first-parent --merges` (`:99`). Tests 1, 4 and 8 check the counts.

**Evidence:** `scripts/dev-cycle.sh:99-104`; r1 `fcl-final4/bats-head.log`

---

## Claim 21: "A newline in a file name would otherwise print a line of its own."

**Location:** `scripts/dev-cycle.sh:117`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `###` heading; does not establish other outlets of repo text. Static reading found them prefixed (`> `, `- `, `    - `) or flattened (`%s` subjects, `tr '\0\n' '\n '` at `:204`), with one exception: `questions.sh`'s stderr is printed raw inside a code fence (`:154`), so a ```` ``` ```` line in it would close the fence. The NUL/newline handling at `:204` is not tested for names with newlines (mutant M7 removes the whole `tr` and fails only because the NUL separators break).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: trigger body lines are prefixed `> ` "and so cannot forge a heading" · r3: E12 tried the remaining sources — a merge message with an embedded `## 3. Forged heading` printed as one line in sections 1 and 4; a skill path `skills/a\n## 3. Fake/SKILL.md` printed flattened through the `tr` at `:204`; `grep -n '^## '` found only the seven real headings · r3: "Does not establish that heading-like text inside a single line is harmless to the reading agent; it is only kept off line start." · r3: "The questions.sh error text is fixed messages with fixed paths (`scripts/questions.sh:135`)" (bears on r2's code-fence exception) · r1+r2+r3: test 6 also passes on baa46e3, which already had this replacement; it guards the heading, not the removed R1 carried list
**Legibility-target:** for-orchestrator-synthesis

`echo "### ${f//$'\n'/ } …"` (`:118`). Mutant M1 (`$f` raw) fails test 6 only (all three replicates).

**Evidence:** `scripts/dev-cycle.sh:118,145,154,204,214`; r2 `fcr2-logs/mutations.txt` (M1, M7); r3 `fc-r3-logs/probe-misc.log`, `fc-r3-logs/mut-M1.log`

---

## Claim 22: "The whole clause to the cell's end; prefer a capitalised 'Revisit' (the trigger sentence) over an earlier 'revisit-trigger verdicts' mention."

**Location:** `scripts/dev-cycle.sh:126-127`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers rows without an escaped `\|` in the cell. Does not establish rows where a markdown-escaped pipe ends the clause early (0 such rows in `docs/decisions/log.md` today), or a capitalised "Revisit" in an earlier cell.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: same pipe residue (r3: "a row whose trigger text contains a literal `|`, which ends the clause early")
**Legibility-target:** for-orchestrator-synthesis

`grep -oE 'Revisit[^|]*' … | head -1`, then a case-insensitive fallback (`:128-129`). Test 2 checks a 500-char clause after an earlier lowercase "revisit-trigger verdicts".

**Evidence:** `scripts/dev-cycle.sh:121-132`, `test/scripts/dev-cycle.bats:51-63`

---

## Claim 23: "`open` prints 'ID  route  slug' in columns of 2+ spaces; a route can contain one space ('you: judgment'), a slug can contain 'trigger'."

**Location:** `scripts/dev-cycle.sh:141-142`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers questions.sh's current `open` format. Does not establish a route containing two consecutive spaces.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish the column format of every `questions.sh` version (the `$HOME` fallback may be older)" (r2 Confidence Medium) · r3: "Does not cover a route padded past 14 characters."
**Legibility-target:** for-orchestrator-synthesis

`printf '%s  %-14s  %s\n' "$id" "$route" "$slug"` (`scripts/questions.sh:412`); dev-cycle splits on `awk -F'  +'` (`:143`). Test 12 (slug containing "trigger") passes.

**Evidence:** `scripts/questions.sh:408-414`, `scripts/dev-cycle.sh:143,150`

---

## Claim 24: "Seeded by a hash of the date: same day, same merges; different days usually differ."

**Location:** `scripts/dev-cycle.sh:162-163`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers determinism for the same date and input, and variation across four dates. Does not establish that the sample stays the same when the merge list changes.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish how often adjacent days collide on small merge counts"; E12: raw-date seeding gave `19,2,16` for four dates, the sha256 seed gave differing samples · r3: "Does not establish distribution quality."
**Legibility-target:** for-orchestrator-synthesis

`seed="$(printf '%s' "$TODAY" | sha256sum | cut -c1-64)"`, then `shuf … --random-source=<(yes "$seed")` (`:164-165`). Tests 9 and 10 pass.

**Evidence:** `scripts/dev-cycle.sh:162-165`; r2 `fcr2-logs/probe6.txt`

---

## Claim 25: "A merge whose diff against its first parent touches files but no docs/ path, *.md or README is a step 4 finding to check"

**Location:** `scripts/dev-cycle.sh:181-182`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the classification awk and rename-detected diffs; does not establish behaviour with `diff.renames=false` in user config. It also does not cover a missing first parent, which cannot happen because `--merges` lists only commits whose parents are both present (in a shallow clone the boundary commit has no parents and is not listed; E7 P5 ran clean).
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1: "Does not establish octopus or shallow-boundary merges." · r1: `docs/` is top-level only (`sub/docs/x.sh` flagged, correctly); a deletion-only and a rename-only merge each count as "1 file(s)" of code; newline names handled (mawk `RS='\0'`, P11/P12) · r3: rename-only established statically only · r1+r2+r3: `$full^1` always resolves (`--merges`; shallow boundary parentless; r3 P7 `--depth 1` clone exited 0) · r2+r3: README clause untested — r2 M5 (drops `.md` and README) passes all 18; r3 M5 (drops README) passes test 17 · r1 (Claim 45 here): M4 dropping `^docs/` survives because `docs/tool.md` also matches `\.md$`
**Legibility-target:** for-author

`(^|\/)README` (`:186`) matches any path component that *starts with* `README`, case-sensitively. r2 E10: a merge adding `src_READMEfoo.sh` and `lib/README_gen.py` was not flagged (the second counted as a doc); a merge adding `readme.txt` was flagged as code-only; a merge renaming `docs/guide.md` to `tools/guide.txt` was flagged "(1 file(s), no doc change)" because rename detection lists only the new path. r1 P11 (`READMEgen.py`, `src/README_tool.sh`) and r3 P5 (`src/READMEish.py`, `README_gen.sh`) reproduce the prefix match. Tighter wording: "…no path under docs/, ending .md, or whose basename starts with README (case-sensitive); renames count by their new path".

**Evidence:** `scripts/dev-cycle.sh:184-193`; r2 `fcr2-logs/probe5.txt`, `fcr2-logs/mutations.txt` (M5); r1 `fcl-final4/probe-s6s7.log` (P11, P12); r3 `fc-r3-logs/probes.log` (P5, P7)

---

## Claim 26: "(rule: undocumented is broken)"

**Location:** `scripts/dev-cycle.sh:182`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers a search of this branch, `feat/dev-cycle` and both CLAUDE.md files; does not establish the rule's source outside them (the "approval doc, 2026-10-01" named in db0e5ca was not found in any branch).
**Replicate verdicts:** r1=— · r2=Unverifiable · r3=— · single-replicate detection
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

r2: `git grep -i 'undocumented is broken'` over HEAD and `feat/dev-cycle` matches only this comment; `/workspace/CLAUDE.md` and `~/.claude/CLAUDE.md` have no match. db0e5ca calls it "rule 4". Verifying it needs the approval doc or the rule list it comes from.

**Evidence:** `scripts/dev-cycle.sh:182`; `skills/dev-cycle/SKILL.md` (feat/dev-cycle 70cc7dc)

---

## Claim 27a: "Base = the parent of the oldest first-parent commit in the window (the empty tree when that commit is the root)."

**Location:** `scripts/dev-cycle.sh:196-197`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which commit becomes the base, where "oldest" means oldest by position on the first-parent line among commits dated in the window; does not establish that the test suite would catch an off-by-one (mutant M6, base = `$oldest` itself, passes all 18 tests because test 18's fixture puts the root in the window).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: "Does not establish whether this is the right base for 4b (Claim 26b)" (Claim 27b here); P13: a 2020-dated commit in the middle of history did not move the base; r1 M5 (no `tr`) fails test 18 · r3 (compound): the net-zero residue recorded under Claim 27b
**Legibility-target:** for-orchestrator-synthesis

`git log … --first-parent --format='%cs %H' | awk … '$1 >= s { h = $2 } END { print h }'` (`:199`) keeps the last match of the newest-first walk; `git rev-parse --verify --quiet "$oldest^1" || git hash-object -t tree /dev/null` (`:203`) falls back to the empty tree, and test 18 runs that fallback (`--since=2000-01-01`).

**Evidence:** `scripts/dev-cycle.sh:199-205`; r2 `fcr2-logs/mutations.txt` (M6), `fcr2-logs/bats-head.txt`; r1 `fcl-final4/probe-s6s7.log` (P13)

---

## Claim 27b: "Old-dated commits after it are included: re-reading a file is cheap, missing one is not."

**Location:** `scripts/dev-cycle.sh:197-198`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the over-inclusion, plus the implied "never misses" for files whose net content changed in the window; does not establish that a file changed and then restored within the window is listed (it is not).
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Verified (compound)
**Replicate annotations:** r1: "Does not establish 4b's thresholds." · r1: P14 also added and then deleted `docs/decisions/005-x.md` in the window — both lists print 0; a file deleted in the window is listed under "added or changed" (from `--name-only` semantics; not separately executed) · r3 (compound Verified): "The comment does not claim more than that"; same residue reproduced (E8 P6b: edit and restore → "… : 0") · r3: `tr '\0\n' '\n '` works on `-z` output, which git does not quote (E12)
**Legibility-target:** for-author

r2: the over-inclusion is real — the diff spans `$base..$MAIN_SHA` whatever the dates in between (`:204`). It is a net diff, though: in E10 two in-window merges changed `skills/k/SKILL.md` and then restored it, and section 7 printed `Skill or workflow files changed on main in the window: 0`. Precise wording: "never misses a file whose content differs between the window's start and `$MAIN`".

**Evidence:** `scripts/dev-cycle.sh:196-207`; r2 `fcr2-logs/probe5.txt`; r1 `fcl-final4/probe-s7-exit.log` (P14); r3 `fc-r3-logs/probes2.log` (P6b)

---

## Claim 28: "The model version is not in git: compare it with the last cycle record's."

**Location:** `scripts/dev-cycle.sh:208`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers agreement with the approved spec. Does not establish that the committed skill on feat/dev-cycle (70cc7dc) has step 4b or a model-version field yet (it has neither).
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

r1: the approval doc "Dev cycle skill — for your approval" (read via Claude Docs, rev 48) step 7 says the record carries "the model version (4b compares it with the previous record)", and gap #3 says "a model version change isn't in git".

**Evidence:** `scripts/dev-cycle.sh:208`; approval doc https://claude.ai/code/artifact/78a2f851-e696-4a86-bfe8-474212e5e645 (steps 4b and 7, gap #3)

---

## Claim 29: Section 7 labels — "Roadmap Now / In flight / Next", "0 items ready for 6b", "Step 4b (deep-audit triggers)"

**Location:** `scripts/dev-cycle.sh:208-226`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers agreement with the approval doc and counting of top-level `- `, `* ` and `N. ` items under exact `## Now`, `## In flight` and `## Next` headings. Does not establish headings with suffixes (e.g. `## Now (Q4)` counts 0), nested items, or the committed skill (whose roadmap template has Now/Next/Ideas/Done, with no In flight and no 4b/6b).
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

r1: the approval doc's step 6 lists "Now / In flight … / Next … / Ideas / Done", and step 5's trigger is "roadmap Now + Next hold 0–1 items ready for 6b". Test 18 checks counts of 1/2/1.

**Evidence:** `scripts/dev-cycle.sh:218-226`, `test/scripts/dev-cycle.bats:250-263`, feat/dev-cycle `skills/dev-cycle/SKILL.md:115-118`, approval doc steps 5–6

---

## Claim 30: "Step 5 (brainstorm triggers; the thresholds are the skill's):"

**Location:** `scripts/dev-cycle.sh:218`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the dev-cycle skill as it exists on branch `feat/dev-cycle` (`skills/dev-cycle/SKILL.md`; there is none on main). Does not establish what the planned skill revision will say.
**Replicate verdicts:** r1=— · r2=Unverifiable (compound) · r3=Incorrect
**Replicate annotations:** r2 (compound Unverifiable): the skill on `feat/dev-cycle` has sections `### 0`–`### 7` with no step 4b; its step 5 (`:95-102`) has no thresholds; its roadmap template has no `In flight`, so `Roadmap In flight` (`:220`) always prints 0 for a roadmap made from it; "does not establish the content of the approved step 0 ('approval doc, 2026-10-01'), which was not found"; verifying needs the approval doc or the landed skill change · r3: "Confidence is Medium because the skill change is planned in the stacked unit." · collation cross-reference: r1 (Claim 29 here) read the approval doc (rev 48), whose step 5 trigger is "roadmap Now + Next hold 0–1 items ready for 6b"
**Legibility-target:** for-author

r3: the skill's step 5 has no thresholds and does not read roadmap counts or a last-brainstorm date ("Generate 3–8 candidate features or improvements. Each must name the **signal** …"). Its roadmap template has `## Now`, `## Next`, `## Ideas` and `## Done`, and no `## In flight`, which `:220` counts. db0e5ca's Notes say the skill "must write" the matching format. As committed, the reference points at nothing.

**Evidence:** `scripts/dev-cycle.sh:218-226`; `feat/dev-cycle:skills/dev-cycle/SKILL.md` (§5 Brainstorm, §6 Roadmap template), `skills/dev-cycle/SKILL.md:95-129` (feat/dev-cycle)

---

## Claim 31: "Step 5 heads each brainstorm '## Brainstorm YYYY-MM-DD'; ideas are '- ' lines."

**Location:** `scripts/dev-cycle.sh:229`
**Type:** Reference / Architectural
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the committed skill and the approved spec. Does not establish a future skill edit (db0e5ca's body says the skill "must write" this marker).
**Replicate verdicts:** r1=Incorrect · r2=Unverifiable (compound) · r3=Incorrect
**Replicate annotations:** r2 (compound Unverifiable): the approval doc was not found by r2; "Verifying it needs the approval doc or the landed skill change" · r3: `git grep -i -E 'idea-log|Brainstorm [0-9Y]|seeded'` across all local branches' `docs/` and `skills/` finds no such convention; the skill's step 5 puts surviving ideas in the roadmap's `## Ideas` (§6) · r3: "Does not establish the approval doc's wording, which is not present in this worktree or any local branch." · r1+r2+r3: db0e5ca's Notes call this a format the skill "must write"; the comment states it as present fact · r1+r2: no `idea-log.md` exists, so section 7 prints "No docs/working/idea-log.md" until the skill changes
**Legibility-target:** for-author

r1: neither source says this. The committed step 5 (feat/dev-cycle `SKILL.md:95-102`) does not write to `docs/working/idea-log.md` or write any brainstorm heading; it reads `docs/working/feature-ideas*.md`. The approval doc names `docs/working/idea-log.md` as the seed log, with format "one line per idea, naming its signal", and specifies no `## Brainstorm` heading and no `- ` bullet.

**Evidence:** `scripts/dev-cycle.sh:227-241`; feat/dev-cycle `skills/dev-cycle/SKILL.md:95-102`; approval doc ("Seeding vs brainstorm", sources draft); db0e5ca body

---

## Claim 32: "No {n} intervals in the awk regex: mawk, Debian's default awk, lacks them."

**Location:** `scripts/dev-cycle.sh:230`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the installed mawk 1.3.4 20200120 (`/usr/bin/awk` → mawk) and the absence of other awk intervals in the script. Does not establish newer mawk releases, which may support intervals (not checked; no network).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: states newer mawk releases "added interval support" (r1, r2: "may support") · r3: mutant M6, which puts `{4}` intervals in the `:232` regex, fails test 18 · r2: the script's `{n}` uses are at `:88` (bash `=~`), `:207` and `:231` (`grep -E`) (r1+r3 likewise for `:207`, `:231`)
**Legibility-target:** for-orchestrator-synthesis

`echo aaaa | mawk '/^a{4}$/'` prints nothing, and `echo 'a{2}' | mawk '/^a{2}$/'` matches the literal (r2 and r3 reproduce). No awk program in the script has an interval.

**Evidence:** `scripts/dev-cycle.sh:207,221,231-232`; r2 `fcr2-logs/probe6.txt`; r3 `fc-r3-logs/mut-M6.log`

---

## Claim 33: "- Ideas seeded since: $seeded"

**Location:** `scripts/dev-cycle.sh:232,238`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what `seeded` counts. Does not establish what the skill means by "seeded since", which it does not define (Claim 23) (Claim 31 here).
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable · r3=Mostly accurate
**Replicate annotations:** r1+r2: whether the count means "since" depends on an idea-log layout no spec defines (Claim 31) · r2: E10 `## Brainstorm 2026-09-20` / `- c1` / `## Seeded later` / `- s1` / `- s2` gave `Ideas seeded since: 3`; test 18's fixture assumes a brainstorm's own bullets count
**Legibility-target:** for-author

r3: the count resets only at a Brainstorm heading (`:232`), so it counts the last brainstorm's own `- ` items plus every column-0 `- ` line after them, under any later heading, to EOF; with no Brainstorm heading, every `- ` line. Test 18 expects 2 for the brainstorm's own two items. Nested or `* ` items are not counted. "Last brainstorm" is the last heading in file order (`tail -1`), not the latest date.

**Evidence:** `scripts/dev-cycle.sh:231-238`; `test/scripts/dev-cycle.bats:250-263`; r2 `fcr2-logs/probe5.txt`

---

## Claim 34: "Each test builds a throwaway repo under $BATS_TEST_TMPDIR; this repo is untouched."

**Location:** `test/scripts/dev-cycle.bats:3-4`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `setup()`/`make_repo` and the per-test `cd`. Does not audit global git config isolation beyond `GIT_CONFIG_GLOBAL=/dev/null`.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "Does not establish isolation from a real `~/.claude`, which line 15 handles separately"; after the suite the worktree's `git status` showed no change (executed) · r2: "does not establish isolation from a parallel run sharing `$BATS_TEST_TMPDIR` (bats makes it per-test)"
**Legibility-target:** for-orchestrator-synthesis

`R="$BATS_TEST_TMPDIR/repo"; make_repo "$R" main; cd "$R"` (`:17-19`). Test 11 copies `scripts/` out to `$BATS_TEST_TMPDIR/tools` and only reads the repo.

**Evidence:** `test/scripts/dev-cycle.bats:8-35,156-165`

---

## Claim 35: "HOME in the temp dir: the ~/.claude/scripts fallback can't reach the real one."

**Location:** `test/scripts/dev-cycle.bats:14`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the `$HOME` fallback at `scripts/dev-cycle.sh:137`. Does not apply to tests that call questions.sh via `$SCRIPT_DIR`, which is found first.
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified
**Replicate annotations:** r1: "Does not establish other HOME-derived paths (none)."
**Legibility-target:** for-orchestrator-synthesis

`export HOME="$BATS_TEST_TMPDIR/home"` (`:15`); the script falls back to `QS="$HOME/.claude/scripts/questions.sh"`.

**Evidence:** `test/scripts/dev-cycle.bats:14-16`, `scripts/dev-cycle.sh:136-137`

---

## Claim 36: test name "prints all seven sections in a repo with no docs"

**Location:** `test/scripts/dev-cycle.bats:37`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the seven headings plus four fixed strings; does not establish section contents.
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

r2: the test loops over seven headings (`:40-44`). It fails against the d9e4cb9 script, which has five sections (E5).

**Evidence:** `test/scripts/dev-cycle.bats:37-49`; r2 `fcr2-logs/headtests-vs-d9e4cb9.txt`

---

## Claim 37: test name "after a cycle record, every trigger still prints in full and nothing is carried"

**Location:** `test/scripts/dev-cycle.bats:65`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an old committed record, an uncommitted record and past and future log rows after a same-window cycle record; does not check the exit status (no `[ "$status" -eq 0 ]`).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "Does not establish inline triggers (Claim 6b)." · r3: "Does not cover unreadable records (Claim 3)" (Claim 6a here)
**Legibility-target:** for-orchestrator-synthesis

Passes on HEAD and fails on the baa46e3 script, which carried triggers forward (all three replicates; r3: "not printed in full").

**Evidence:** `test/scripts/dev-cycle.bats:65-78`; r2 `fcr2-logs/headtests-vs-baa46e3.txt`

---

## Claim 38: test name "an old-dated commit on main does not hide the merges after it"

**Location:** `test/scripts/dev-cycle.bats:80`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the test fails on `--since` walking (E5 vs baa46e3; mutant M3 fails it alone); does not cover the wording, since the merges it protects are the ones *behind* (older than) the old-dated commit, not the one after it.
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1 (Verified): covers the R3 regression with "after it" read in walk order; "Does not establish section 7's base under the same scenario (P13 does, separately)." · r3: the assertions `*"4 merge(s)"*` and `*"merge: feature 4"*` (`:88-89`) are right; suggested name "does not hide the merges before it"
**Legibility-target:** for-author

r2: the fixture puts features 1-3 before the 2020 commit and feature 4 after it. The baa46e3 script showed `merge: feature 4` and hid features 1-3 (E5: `1 merge(s)`). The guard works, but "after it" is right only in walk order; "…does not hide the merges behind it" would say what it tests.

**Evidence:** `test/scripts/dev-cycle.bats:80-91`; r2 `fcr2-logs/headtests-vs-baa46e3.txt`, `fcr2-logs/mutations.txt` (M3)

---

## Claim 39: "--since used to stop its walk at the old commit and report 0 merges."

**Location:** `test/scripts/dev-cycle.bats:81-82`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the old code on this test's own fixture. Does not establish the rubric's R3 scenario, where nothing was merged after the old commit and "0 merge(s)" was correct.
**Replicate verdicts:** r1=Incorrect · r2=Mostly accurate · r3=Incorrect
**Replicate annotations:** r2 (Mostly accurate): precise wording "…and report only the merges made after it" · r2+r3: same R3-scenario residue (r3: "where the old commit is the tip")
**Legibility-target:** for-author

r1: on this fixture, baa46e3 prints "1 merge(s) … `854f921 2026-10-01 merge: feature 4`", not 0. The old walk shows the merge made after the old commit and hides the three made before it. r2 and r3 reproduce the "1 merge(s)" output.

**Evidence:** `test/scripts/dev-cycle.bats:81-88`; r1 `fcl-final4/bats-headtests-on-baa46e3.log` (test 4 output); r3 `fc-r3-logs/bats-headtests-on-baa46e3.log`

---

## Claim 40: test name "the scrub strips C0, C1, bidi and tag characters from stdout and stderr"

**Location:** `test/scripts/dev-cycle.bats:93`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers intact sequences on stdout and an ESC on stderr. Does not establish the interleaved-C0 bypass of Claim 11, which the test does not exercise.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2+r3: one code point per class only; other range members (r3: U+200E/F, U+2066–2069, DEL) not tested individually, and not the `PERL_UNICODE` case
**Legibility-target:** for-orchestrator-synthesis

The test fails on baa46e3 and on the stderr-unscrubbed mutant (r1/r2 M2, r3 M3), and r3 M4 (no C1 pattern); passes at HEAD.

**Evidence:** `test/scripts/dev-cycle.bats:93-104`; r1 `fcl-final4/mutations.log` (M2); r3 `fc-r3-logs/mut-M4.log`

---

## Claim 41: "A non-repo error message carrying an ESC still reaches stderr scrubbed."

**Location:** `test/scripts/dev-cycle.bats:99`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what the next lines run. Does not establish the "Not inside a git repository" path, which is not exercised.
**Replicate verdicts:** r1=Mostly accurate · r2=— · r3=Verified (compound)
**Replicate annotations:** r3 (compound Verified): "'Non-repo' here means the text is user-supplied (an unknown option), not repo-derived."
**Legibility-target:** for-author

r1: the next lines run `bash "$DC" $'--bo\033gus'` inside the repo and check "Unknown option: --bogus". Read as "an error not from repo text", the comment holds; read as the non-repo error, it does not.

**Evidence:** `test/scripts/dev-cycle.bats:99-103`, `scripts/dev-cycle.sh:42`

---

## Claim 42: test name "a newline in a decision record's name cannot print a line of its own"

**Location:** `test/scripts/dev-cycle.bats:106`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the section 2 heading; does not establish section 7's name handling, and the test cannot fail on the R1 code it was written after (it passes on baa46e3, whose heading already replaced LF and whose carried path needs an unchanged committed record).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: newline names in section 7 are handled by `tr` but untested for newlines, and section 6 likewise · r3: "a new guard on the old heading fix (closes pass-3 C5's heading half), not a regression test for R1"
**Legibility-target:** for-orchestrator-synthesis

Mutant M1 fails it (all three replicates); it passes on baa46e3.

**Evidence:** `test/scripts/dev-cycle.bats:106-112`; r2 `fcr2-logs/mutations.txt` (M1)

---

## Claim 43: test name "--since counts from midnight, not from the current time of day"

**Location:** `test/scripts/dev-cycle.bats:123`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the inclusive date comparison (it fails on mutant M3). Does not establish committer offsets other than local, which the test never creates.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
**Replicate annotations:** r2 (Verified): mutant M4 switches the count back to `git log --since="$SINCE"` (current time of day) and fails this test alone, "So the test still checks what its name says." · r3 (Verified): mutant M2 (`git rev-list --count --since`) fails it; covers same-zone commits just after local midnight · r2+r3: cross-zone behaviour not established (Claim 3)
**Legibility-target:** for-author

r1: at HEAD no time of day enters the comparison at all: `%cs >= SINCE` (Claim 3). The test still guards inclusivity of the start date. It only stands for "from midnight" when commits are made in the local zone (`GIT_COMMITTER_DATE` with no offset, `:124`). Precise name: "--since includes every commit dated on that day".

**Evidence:** `test/scripts/dev-cycle.bats:123-129`; r1 `fcl-final4/mutations.log` (M3), `fcl-final4/probe-tz.log`; r2 `fcr2-logs/mutations.txt` (M4); r3 `fc-r3-logs/mut-M2.log`

---

## Claim 44: "No questions-archive.md: questions.sh open exits non-zero."

**Location:** `test/scripts/dev-cycle.bats:200`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `require_files` failing. Does not establish other failure modes of questions.sh.
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

`cmd_open` calls `require_files` first (`scripts/questions.sh:409`); `[[ $missing -eq 0 ]] || die …` (`:137`), printing `✗ missing:` (`:135`). Test 13 passes.

**Evidence:** `scripts/questions.sh:132-138,408-414`; `test/scripts/dev-cycle.bats:197-206`

---

## Claim 45: test name "flags a merge that changed code with no doc change, not one that did both"

**Location:** `test/scripts/dev-cycle.bats:239`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the flag and no-flag cases it builds. Does not establish the `^docs/` branch: mutant M4, which drops it, still passes, because `docs/tool.md` also matches `\.md$`. README handling is also untested (Claim 25).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: the `*.md` and README clauses are not exercised (r2 M5 removes both and passes; r3 M5 removes README and passes) · r3: the empty-diff feature merges are not flagged
**Legibility-target:** for-orchestrator-synthesis

Fails on d9e4cb9 and baa46e3 (no section 6), passes at HEAD.

**Evidence:** `test/scripts/dev-cycle.bats:239-248`; r1 `fcl-final4/mutations.log` (M4); r2 `fcr2-logs/mutations.txt` (M5)

---

## Claim 46: test name "prints the step 4b and step 5 inputs"

**Location:** `test/scripts/dev-cycle.bats:250`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listed outputs. Does not establish the records count line: `"in the window: 1"` matches only the skills label, since the records label reads "in the window (is any …): 1".
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: does not establish the base choice (M6 survives), reverted-in-window files, or names with newlines · r3: does not cover an in-window base with a parent, or the net-zero case (r2+r3 on net-zero)
**Legibility-target:** for-orchestrator-synthesis

Fails on d9e4cb9 and on the no-`tr` mutant (r1 M5, r2 M7) and r3 M6; passes at HEAD.

**Evidence:** `test/scripts/dev-cycle.bats:250-263`; r1 `fcl-final4/mutations.log` (M5); r2 `fcr2-logs/mutations.txt` (M6, M7)

---

## Claim 47: d9e4cb9 — "Tests: carry-forward test replaced; new tests for R3, the scrub and a newline in a record name. 16/16 pass; shellcheck clean."

**Location:** commit d9e4cb9 message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count, the pass result and shellcheck at the d9e4cb9 tree; does not establish that the newline test guards the removed R1 code (Claim 31) (Claim 42 here).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: verdicted "16/16 pass; shellcheck clean" only; "Does not establish the environment the author ran in." · r3: verdicted the count only; "Does not establish CI behaviour." · r1+r2: matches the hallucination-pattern log's test-count pattern in kind; the count holds this time · r2: baa46e3 had 13 tests
**Legibility-target:** for-orchestrator-synthesis

`git archive d9e4cb9` into a temp dir, then `bats` (exit 0, `1..16` all ok) and `shellcheck` (exit 0, no output) — all three replicates.

**Evidence:** r2 `fcr2-logs/bats-d9e4cb9.txt`, `fcr2-logs/sc-d9e4cb9.txt`; r1 `fcl-final4/bats-d9e4cb9.log`; r3 `fc-r3-logs/bats-d9e4cb9.log`

---

## Claim 48: d9e4cb9 — "the 'Main at:' handshake, the base lookup and the carried list are gone (rubric pass 3: R1, R2, A1, A3, A5, A6, C1, C3 lose their code)."

**Location:** commit d9e4cb9 message
**Type:** Reference / Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the removal of the carried list, the `Main at:` parsing, the sha lookup, ancestry and base logic, and the "changed since" carried wording. Does not establish C6 (asynchronous filter ordering), which persists and now applies to both streams (Claim 9c). It is not on the list.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: same C6 note ("async stderr ordering, still present") · r2: "does not establish that no new defect replaced them (Claims 8b, 19, 22 are new)" (Claims 12, 25, 27b here)
**Legibility-target:** for-orchestrator-synthesis

A case-insensitive grep of `scripts/dev-cycle.sh` for the removed mechanism (`carr|Main at|merge-base|cmp |…`) matches only `:15` (r3 also `:203`, section 7's unrelated `base=`). The rubric rows at `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:81-102` each describe code in that removed mechanism.

**Evidence:** `scripts/dev-cycle.sh:15,203`; `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:81-102`

---

## Claim 49: d9e4cb9 — "A2: one scrub() filters stdout AND stderr, set up before option parsing: C0 (but TAB/LF), DEL, C1, bidi controls, tag characters."

**Location:** commit d9e4cb9 message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 11. The "stdout AND stderr, set up before option parsing" part is Verified (Claim 10).
**Replicate verdicts:** r1=Incorrect · r2=Mostly accurate · r3=Verified (compound)
**Replicate annotations:** r2 (Mostly accurate): placement correct (`:31` before `:33`); the drop list carries the `PERL_UNICODE` qualifier and does not cover raw 8-bit C1 bytes · r3 (compound Verified): "Does not establish the scrub's robustness to `PERL_UNICODE` (Claim 8)" (Claim 12 here); `exec` at `:31` precedes the `while` at `:35`
**Legibility-target:** for-author

r1: P1 shows C1, RLO and tag characters passing when a C0 byte is interleaved, so A2 is not fully closed.

**Evidence:** `scripts/dev-cycle.sh:29`; r1 `fcl-final4/probe-scrub.log` (P1)

---

## Claim 50: d9e4cb9 — "R3: merges and commits are walked in full and filtered by committer date (%cs) afterwards"

**Location:** commit d9e4cb9 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers sections 1 and 4 (and later 6). Does not establish the time zone semantics (Claim 3).
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=Verified (compound)
**Replicate annotations:** r3: tests 4 and 5 fail on baa46e3 and pass at HEAD (E4)
**Legibility-target:** for-orchestrator-synthesis

The walks are `:99` and `:102`. See Claims 4, 18 and 19.

**Evidence:** `scripts/dev-cycle.sh:96-102`; r1 `fcl-final4/bats-headtests-on-baa46e3.log`

---

## Claim 51: d9e4cb9 — "The window still defaults to the newest record's file-name date, inclusive"

**Location:** commit d9e4cb9 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers sections 1 and 4 (and later 6). Does not establish the time zone semantics (Claim 3).
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=Verified (compound)
**Replicate annotations:** r3: "Covers the perl gate and the inclusive `>=` default. Does not evaluate alternatives to perl."
**Legibility-target:** for-orchestrator-synthesis

r3: `SINCE="$last_record"` (`:83`) with `$1 >= s` (`:99`) is inclusive. r1: see Claim 4.

**Evidence:** `scripts/dev-cycle.sh:83,99`

---

## Claim 52: d9e4cb9 Notes — "perl is now required (byte-pattern scrub; tr can't match UTF-8 sequences)."

**Location:** commit d9e4cb9 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the perl gate and the inclusive `>=` default. Does not evaluate alternatives to perl.
**Replicate verdicts:** r1=— · r2=— · r3=Verified (compound) · single-replicate detection
**Replicate annotations:** r2 (in its A2 claim, no separate verdict): "The commit's Notes give the real reason perl is needed ('tr can't match UTF-8 sequences'), and that reason is correct."
**Legibility-target:** for-orchestrator-synthesis

r3: the gate exits 1 without perl (E12). GNU `tr` works per byte and cannot delete a multibyte sequence while keeping the other bytes of the same values (coreutils behaviour, paraphrased).

**Evidence:** `scripts/dev-cycle.sh:23`; r3 `fc-r3-logs/probe-misc.log`

---

## Claim 53: d9e4cb9 — "A4, C2: the Window line and --help say what the window is and that nothing carries forward."

**Location:** commit d9e4cb9 message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Window line and `--help` (lines 2-19); does not establish that the Window line covers section 7's 4b lists (Claim 12) (Claim 17 here).
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r3: the Window line (`:92`) does not mention carry-forward; section 2's intro at `:108` does; "Does not cover section 2's intro line, which also states it." · r2: the Window line already listed "idea log" at d9e4cb9, before any idea log was read (db0e5ca added that read)
**Legibility-target:** for-author

r2: `--help` prints `:15` ("nothing carries forward"). The Window line says "Triggers: all of them". It names the time-zone-dependent "committed on or after" (Claim 3), and does not describe section 7's net-diff lists.

**Evidence:** `scripts/dev-cycle.sh:10-15,41,92,108`; `git show d9e4cb9:scripts/dev-cycle.sh` line 92

---

## Claim 54: db0e5ca — "18/18 tests pass; shellcheck clean. Script is 241 lines."

**Location:** commit db0e5ca message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers HEAD. Does not establish other bats versions.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r3: "Does not establish CI behaviour."
**Legibility-target:** for-orchestrator-synthesis

bats exit 0 with 1..18 ok; shellcheck exit 0; `wc -l scripts/dev-cycle.sh` = 241 (all three replicates; bats file 263).

**Evidence:** r1 `fcl-final4/bats-head.log`, `fcl-final4/shellcheck.log`; r2 `fcr2-logs/wc-head.txt`

---

## Claim 55: db0e5ca — "All stateless: nothing here reads a cycle record."

**Location:** commit db0e5ca message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers sections 6–7 ("here"). Does not establish the script as a whole, which reads cycle-record file names (not contents) for the default window (`:75-79`).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

Sections 6–7 (`:180-241`) open no file under `docs/working/cycles/`; `:208` only tells the reader to compare.

**Evidence:** `scripts/dev-cycle.sh:180-241`

---

## Claim 56: db0e5ca — "Section 6: merges whose first-parent diff touches files but no docs/ path, *.md or README"

**Location:** commit db0e5ca message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 25.
**Replicate verdicts:** r1=Mostly accurate · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none
**Legibility-target:** for-author

r1: "README" means any path component that starts with README (P11).

**Evidence:** `scripts/dev-cycle.sh:186`; r1 `fcl-final4/probe-s6s7.log` (P11)

---

## Claim 57: db0e5ca — "the 4b window base is the parent of the oldest in-window first-parent commit (over-includes, never misses)"; also "the model version is compared with the last record by the skill, not parsed here. ... Thresholds stay in the skill."

**Location:** commit db0e5ca message
**Type:** Behavioral / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the base and over-inclusion (true) and "never misses" (false for files restored within the window); the skill-side halves (model-version compare, thresholds) are Unverifiable for the reason given in Claim 23 (Claims 30–31 here) and are not what carries this verdict.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r3: verdicted the base/"never misses" sentence only · r2: the skill on `feat/dev-cycle` has no step 4b, no model-version comparison and no step 5 thresholds (Claim 30 here) · r1: P14 add-then-delete is also missed · r3: precise version "never misses a file whose content differs from the base"
**Legibility-target:** for-author

The verdict comes from "never misses": r2 E10 shows a skill file changed and then restored in the window is not listed (Claim 27b); r1 P14 and r3 P6b reproduce it.

**Evidence:** `scripts/dev-cycle.sh:196-218`; r2 `fcr2-logs/probe5.txt`; r1 `fcl-final4/probe-s7-exit.log` (P14); r3 `fc-r3-logs/probes2.log` (P6b)

---

## Claim 58: db0e5ca — "the idea log marker is '## Brainstorm YYYY-MM-DD' at docs/working/idea-log.md, which the skill (feat/dev-cycle) must write"

**Location:** commit db0e5ca message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the skill does not yet write it, which is why the sentence says "must". Does not establish that the skill will be changed.
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

r1: feat/dev-cycle `SKILL.md` has no `idea-log` or `## Brainstorm` text (grep, 70cc7dc).

**Evidence:** feat/dev-cycle `skills/dev-cycle/SKILL.md:95-102`

---

## Claims Requiring Attention

### Incorrect
- **Claim 11** (`scripts/dev-cycle.sh:24-26`; r1 only Incorrect): the scrub does not drop C1/bidi/tag characters when a C0 byte sits inside their encoding — `tr` runs after `s///g` and reassembles them (r1 P1: U+009B, U+202E, U+E0041 reach stdout).
- **Claim 12** (`scripts/dev-cycle.sh:26-27`; r2 only Incorrect): `LC_ALL=C` is not what keeps the scrub byte-oriented; `PERL_UNICODE`/`PERL5OPT` in the caller's environment overrides it, perl then warns on invalid UTF-8 and C1/bidi pass unscrubbed.
- **Claim 30** (`scripts/dev-cycle.sh:218`; r3 Incorrect, r2 Unverifiable): "the thresholds are the skill's" — the skill on feat/dev-cycle has no step-5 thresholds and no "In flight" roadmap section.
- **Claim 31** (`scripts/dev-cycle.sh:229`; r1+r3 Incorrect, r2 Unverifiable): "Step 5 heads each brainstorm '## Brainstorm YYYY-MM-DD'" — neither the committed skill nor the approval doc says this; nothing writes `docs/working/idea-log.md`.
- **Claim 39** (`test/scripts/dev-cycle.bats:81-82`; r1+r3 Incorrect, r2 Mostly accurate): baa46e3 reported 1 merge on this fixture, not 0.
- **Claim 49** (commit d9e4cb9; r1 only Incorrect): the A2 drop list, same defect as Claim 11 (immutable history).

### Stale
- None.

### Mostly Accurate
- **Claim 3** (`:10`): the date is the committer's own-zone date.
- **Claim 6a** (`:15`): carry-forward code is gone; the merged residue (r3, compound) is an unreadable record skipped silently.
- **Claim 6b** (`:15`): "every trigger" means `## Revisit triggers` sections and log rows; inline triggers (`docs/decisions/013-…md:21`), unreadable records and 4-digit names are not printed.
- **Claim 9b** (`:19`): failures behind `|| continue` (`:113`) and inside `echo "$(…)"` (`:190`) do not exit.
- **Claim 9c** (`:18`): process substitutions are not waited for; exit 0 can precede the digest (r1 P8, r3 P10) and stderr trails/precedes under `2>&1`.
- **Claim 17** (`:92`): the Window line does not describe section 7's net-diff base-to-tip list or the committer-zone date.
- **Claim 18** (`:96-97`): "after it" holds only in walk order; the hidden merges are older than the old-dated commit.
- **Claim 25** (`:181-182`): "README" matches any component starting with README, case-sensitively; a doc renamed out of `docs/` is flagged; README clause untested.
- **Claim 27b** (`:197-198`): net diff misses a file changed and restored (or added and deleted) within the window.
- **Claim 33** (`:232,238`): "Ideas seeded since" counts the last brainstorm's own bullets plus every later `- ` line.
- **Claim 38** (`bats:80`): the protected merges are behind (older than) the old-dated commit.
- **Claim 41** (`bats:99`): the error tested is the unknown-option error, not a non-repo error.
- **Claim 43** (`bats:123`): no time of day enters the comparison; the test guards date inclusivity for local-zone commits only.
- **Claim 53** (d9e4cb9): the Window line does not mention carry-forward or section 7's lists.
- **Claim 56** (db0e5ca): same README residue as Claim 25.
- **Claim 57** (db0e5ca): "never misses" fails for net-zero changes in the window.

### Unverifiable
- **Claim 26** (`:182`): "rule: undocumented is broken" is found nowhere in the repo or the CLAUDE.md files; needs the approval doc.

Legibility-target for all Verified and Unverifiable claims: for-orchestrator-synthesis; for all Incorrect and Mostly accurate claims: for-author.

---

## Escalations

- **orchestrator** (r1+r2+r3) — cross-unit contract gap, section 7 step 4b/5 inputs (`scripts/dev-cycle.sh:208-232`; Claims 30, 31): the `## Brainstorm YYYY-MM-DD` idea log, `In flight`, step 4b and step 5 thresholds depend on a skill contract not yet on `feat/dev-cycle`; db0e5ca's Notes say the skill "must write" it. r2: merging before that skill change lands means section 7 reports "No idea log" and "In flight: 0" for any roadmap built from today's template.
- **orchestrator** (r1) — scrub bypass (`scripts/dev-cycle.sh:24-29`; Claim 11): "the one scrub that Q-101 [1] asked for can be bypassed by repo-controlled bytes, so A2 is not closed. With carry-forward cut, a forged control sequence no longer steers the window, but it still reaches the terminal."
- **orchestrator** (r3; r2 as an author question) — scrub environment dependence (`scripts/dev-cycle.sh:26-29`; Claim 12): the scrub silently stops working under `PERL_UNICODE`/`PERL5OPT`, which defeats A2's fix in that environment. r2+r3 ask whether `scrub()` should clear `PERL_UNICODE`/`PERL5OPT` (or use `perl -C0`) or the comment should just name the dependency.
- **orchestrator** (r3 escalate; r2 out-of-scope note; r1 brief-check note) — async output / pass-3 C6 not closed (`scripts/dev-cycle.sh:31`; Claims 9c, 10, 48): r3: an output file can be incomplete when the script returns, and stderr always trails, affecting any caller that redirects to a file. r2: with `2>&1` the error lands before the digest header (E9), recorded only as a Scope residue because no comment claims an order. r1: "C6 persists on both streams (Claim 9c)". r3 asks whether the script should wait for its scrubs before exiting (e.g. close fds and `wait` on `$!` in an EXIT trap).
- **critics / rubric** (r1, out of scope) — "Code-quality judgments, and whether the defects block merge, are left to the critics and the rubric."
- **orchestrator** (r1+r2, routed note) — the hallucination-pattern log was not updated: the brief forbids writes beyond the report, and no Incorrect verdict is a fabricated symbol or API.
- **author** (r1; r3 asks the same) — window semantics (`scripts/dev-cycle.sh:10,99`; Claim 3): should the window be local-zone midnight (convert to `%ct` and compare with `date -d "$SINCE" +%s`), or is committer-zone dating accepted and documented?
- **author** (r1) — idea-log layout (`scripts/dev-cycle.sh:232`; Claim 33): whether the idea-log layout is the skill's decision to make first.
- **author** (r3) — README anchor (`scripts/dev-cycle.sh:186`; Claim 25): should `(^|/)README` be anchored, e.g. `(^|/)README(\.[^/]*)?$`?
- **author** (r3) — section 7 semantics (`scripts/dev-cycle.sh:204`; Claims 27b, 57): does the user want section 7 to count net changes or every change in the window?

---

## Verdict stability

- Clusters: 62 (compound rows counted per sub-claim: 6a/6b, 9a/9b/9c, 27a/27b; d9e4cb9's R3 / window-default / perl-required / A2 items split per the finest granularity used).
- All reporting replicates agreed: 46 (of which 9 are single-replicate detections: Claims 1, 7, 26, 28, 29, 36, 52, 56, 58).
- Disagreed (16):
  - Claim 6a: r1=Verified · r2=Verified (compound) · r3=Mostly accurate (compound)
  - Claim 6b: r1=Mostly accurate · r2=Verified (compound) · r3=Mostly accurate (compound)
  - Claim 9b: r1=Verified · r2=Verified (compound) · r3=Mostly accurate
  - Claim 9c: r1=Mostly accurate · r2=Verified (compound) · r3=Mostly accurate
  - Claim 11: r1=Incorrect · r2=Mostly accurate · r3=Verified
  - Claim 12: r1=Mostly accurate · r2=Incorrect · r3=Mostly accurate
  - Claim 18: r1=Verified · r2=Verified · r3=Mostly accurate
  - Claim 27b: r1=Mostly accurate · r2=Mostly accurate · r3=Verified (compound)
  - Claim 30: r1=— · r2=Unverifiable (compound) · r3=Incorrect
  - Claim 31: r1=Incorrect · r2=Unverifiable (compound) · r3=Incorrect
  - Claim 33: r1=Unverifiable · r2=Unverifiable · r3=Mostly accurate
  - Claim 38: r1=Verified · r2=Mostly accurate · r3=Mostly accurate
  - Claim 39: r1=Incorrect · r2=Mostly accurate · r3=Incorrect
  - Claim 41: r1=Mostly accurate · r2=— · r3=Verified (compound)
  - Claim 43: r1=Mostly accurate · r2=Verified · r3=Verified
  - Claim 49: r1=Incorrect · r2=Mostly accurate · r3=Verified (compound)
- Agreement rate: 46/62 ≈ 74.2% (counting single-replicate clusters as agreed); 37/53 ≈ 69.8% over the 53 clusters with two or more reporting replicates.
- Every merged Incorrect except Claims 31 and 39 rests on one replicate's Incorrect (Claims 11, 12, 30, 49); none of the six Incorrect clusters was unanimous.
