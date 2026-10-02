Commit: db0e5ca

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-digest (branch feat/dev-cycle-digest)
**Scope:** `git diff main...HEAD -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (both new, 241 + 263 lines), plus the commit messages of d9e4cb9 and db0e5ca
**Checked:** 2026-10-01
**Total claims checked:** 46
**Summary:** 31 verified, 12 mostly accurate, 0 stale, 3 incorrect, 0 unverifiable

Execution provenance (applies to every `executed` claim). All commands ran with cwd `/workspace/.claude/wt-digest` between 2026-10-01T19:07:49-07:00 and 19:12:29-07:00. The brief forbids writing into the worktree, so the raw output is captured under the session scratchpad, `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc-r3-logs/` (called `LOGS/` below). Throwaway repos were built with `mktemp -d` and deleted. Every process ran under `timeout`.

| Run | Command | Exit | Log |
|---|---|---|---|
| E1 | `bats test/scripts/dev-cycle.bats` (HEAD) | 0, 18/18 ok | `LOGS/bats-head.log` |
| E2 | `shellcheck scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (HEAD) | 0 | `LOGS/shellcheck.log` |
| E3 | `git archive d9e4cb9 scripts test` into a temp dir, then `bats`, then `shellcheck` | 0 (16/16), 0 | `LOGS/bats-d9e4cb9.log`, `LOGS/sc-d9e4cb9.log` |
| E4 | HEAD's bats file run against baa46e3's script | 1: tests 1, 3, 4, 5, 17, 18 fail | `LOGS/bats-headtests-on-baa46e3.log` |
| E5 | HEAD's bats file run against d9e4cb9's script | 1: tests 1, 17, 18 fail | `LOGS/bats-headtests-on-d9e4cb9.log` |
| E6 | Mutants M1–M6 of HEAD's script (python string replace), each run with `bats -f <test>` | M1–M4, M6: 1; M5: 0 | `LOGS/mut-M1.log` … `LOGS/mut-M6.log` |
| E7 | `bash LOGS/probes.sh scripts/dev-cycle.sh` (P1–P7) | 0 | `LOGS/probes.log` |
| E8 | `bash LOGS/probes2.sh scripts/dev-cycle.sh` (P9–P11, P6b) | 0 | `LOGS/probes2.log` |
| E9 | the `scrub()` lines (`:28-30`) eval'd, then fed invalid UTF-8 / C1 / RLO with and without `PERL_UNICODE=SD` | — | `LOGS/scrub-probe.log` |
| E10 | `bash LOGS/probe-ro.sh scripts/dev-cycle.sh` (read-only check, `--help`) | 0 | `LOGS/probe-ro.log` |
| E11 | `bash LOGS/probe-unreadable.sh scripts/dev-cycle.sh` | 0 | `LOGS/probe-unreadable.log` |
| E12 | `bash LOGS/probe-misc.sh scripts/dev-cycle.sh` (no perl; forged subject / file name) | 0 | `LOGS/probe-misc.log` |
| E13 | `echo 'aab' \| mawk '/^a{2}b/…'`; `printf 'a\0b…' \| mawk -v RS='\0'` (mawk 1.3.4 20200120, Debian 12) | 0 | inline in the transcript; result restated in Claim 25 |

No `docs/reviews/hallucination-patterns.md` pattern applies: none of the claims names a symbol, flag or API that does not exist.

---

## Claim 1: "--since   start of the cycle window: merges committed on or after this date."

**Location:** `scripts/dev-cycle.sh:10`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which merges are counted for a given `--since` (sections 1, 4, 6). Does not establish section 7's file list, which uses a different base rule (Claim 21).
**Legibility-target:** for-author

The filter compares `%cs`, the committer date in the committer's own time zone:

```bash
# scripts/dev-cycle.sh:99
merges_full="$(git log "$MAIN_SHA" --first-parent --merges --format='%cs %H %h %ad %s' --date=short | awk -v s="$SINCE" '$1 >= s')"
```

So "this date" means the date on the committer's clock, not on the reader's. Probe P4 (E7) made a merge at `2026-09-30 23:00:00 -1000`, which is `2026-10-01 02:00:00 -0700` locally. With `--since=2026-10-01` it was left out ("3 merge(s)", not 4). A precise wording would be: "merges whose committer date, in the committer's own time zone, is on or after this date". The old text said "(midnight, local time)". That is no longer what the code does.

**Evidence:** `scripts/dev-cycle.sh:99-102`; `LOGS/probes.log` (P4)

---

## Claim 2: "Default: the date in the newest docs/working/cycles/cycle-YYYY-MM-DD.md (only its file name is read), else 14 days ago. The digest says which."

**Location:** `scripts/dev-cycle.sh:11-12`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the default-window selection and the `source_note` it prints. Does not establish that a future-dated record is ignored; that is Claim 12.
**Legibility-target:** for-orchestrator-synthesis

The loop only globs names: `for f in docs/working/cycles/cycle-[0-9]…md; do … d="${f##*/cycle-}"` (`scripts/dev-cycle.sh:75-79`). A grep of the script for `cycles/` and `Main at` finds no other reference that opens a record. The fallback is `SINCE="$(date -d "$TODAY - 14 days" +%F)"` (`:85`). Tests 1 and 7 pass in E1 ("no cycle record found"; "Window: since 2026-02-10 (from the last cycle record").

**Evidence:** `scripts/dev-cycle.sh:74-87`; `test/scripts/dev-cycle.bats:114-121`; `LOGS/bats-head.log`

---

## Claim 3: "Every revisit trigger is printed in full every run; nothing carries forward."

**Location:** `scripts/dev-cycle.sh:15`
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every readable `docs/decisions/NNN-*.md` that has a `## Revisit triggers` heading, and every log row matching `revisit`. Does not hold for an unreadable record, which is dropped silently.
**Legibility-target:** for-author

The carry-forward code is gone. A grep for `carr|Main at|merge-base|cmp ` matches only this comment. Test 3 passes at HEAD and fails against baa46e3 (E4). One case slips through:

```bash
# scripts/dev-cycle.sh:111-113 (excerpt ends :113; the for loop continues to :120 — read)
for f in docs/decisions/[0-9][0-9][0-9]-*.md; do
  [[ -f "$f" ]] || continue
  grep -q '^## Revisit triggers' "$f" || continue
```

`grep` exits 2 on a file it cannot read, and `|| continue` swallows that. Probe E11 made `001-a.md` mode 000: the digest exited 0, section 2 printed only `002-b.md`, and the only trace was a stderr line, `grep: docs/decisions/001-a.md: Permission denied`. A precise version would add: "(an unreadable record is skipped with a stderr warning)".

**Evidence:** `scripts/dev-cycle.sh:109-133`; `LOGS/probe-unreadable.log`; `LOGS/bats-headtests-on-baa46e3.log` (test 3)

---

## Claim 4: "Read-only: writes nothing to the repo (one temp file, removed on exit)."

**Location:** `scripts/dev-cycle.sh:17`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `.git` and the working tree across one full run that includes the questions path (the temp file), with `TMPDIR` checked afterwards. Does not establish behaviour when the run is killed by SIGKILL, which the EXIT trap cannot catch.
**Legibility-target:** for-orchestrator-synthesis

The only temp file is `qs_err="$(mktemp)"; trap 'rm -f "$qs_err"' EXIT` (`scripts/dev-cycle.sh:139`). `git hash-object -t tree /dev/null` at `:203` has no `-w`, so it writes nothing. In E10, a recursive listing of `.git` with full-iso mtimes was identical before and after a run. That run had `docs/working/questions.md`, so `mktemp` fired, and 0 entries were left in the private `TMPDIR`.

**Evidence:** `scripts/dev-cycle.sh:139,203`; `LOGS/probe-ro.log`

---

## Claim 5a: "Exit: … 1 bad usage, not a git repo, no default branch or no perl"

**Location:** `scripts/dev-cycle.sh:18-19`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers no perl, unknown option, malformed or unreal `--since`, `--since` with no value, and (statically) the not-a-repo and no-branch branches. Does not establish the exit code of a mid-digest failure (Claim 5c).
**Legibility-target:** for-orchestrator-synthesis

The runs gave these results:

- E12: with `PATH=/nonexistent`, the script printed `dev-cycle.sh needs perl (to scrub its output)` and exited 1.
- E7 P2: a bare `--since` hits `${2:?--since needs a date}` and exits 1.
- Test 16 (E1) covers `2026/01/01`, `2026-13-45` and `--bogus`.
- The not-a-repo and no-branch branches are `|| { echo …; exit 1; }` at `:48` and `:72` (read statically).

**Evidence:** `scripts/dev-cycle.sh:23,37,45,48,72,88`; `LOGS/probe-misc.log`; `LOGS/probes.log` (P2)

---

## Claim 5b: "Exit: 0 digest printed"

**Location:** `scripts/dev-cycle.sh:18`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers when the output is complete relative to the script's exit. Does not establish ordering inside stdout, which is preserved because one perl handles it.
**Legibility-target:** for-author

All output goes through two process substitutions, and bash does not wait for them:

```bash
# scripts/dev-cycle.sh:31
exec > >(scrub) 2> >(scrub >&2)
```

A reader on a pipe or a `$(…)` gets everything, because EOF waits for the perl processes. A caller that redirects to a file and reads it as soon as `wait` returns may not:

- **Stderr after exit.** In E8 P9, `(bash dev-cycle.sh --bogus; echo AFTER) >o 2>&1` put `AFTER` before the script's own error line in 20 of 20 runs.
- **Truncated stdout.** In E8 P10 (300,039 lines), the file was short right after exit in 1 of 20 runs.
- **Reordered stderr.** E7 shows P2's stderr arriving after P3's header line.

So "printed" should read "printed, though perl may still be flushing it when the script exits".

**Evidence:** `scripts/dev-cycle.sh:28-31`; `LOGS/probes2.log` (P9, P10); `LOGS/probes.log` (P2/P3 interleave)

---

## Claim 5c: "a failed step exits non-zero mid-digest"

**Location:** `scripts/dev-cycle.sh:19`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers steps run as plain commands or assignments under `set -euo pipefail`. Does not hold for failures behind `|| continue`, `|| true`, or inside an `echo "$(…)"` argument.
**Legibility-target:** for-author

The status does propagate through the `exec` redirect. In E7 P3, an unreadable `docs/roadmap.md` made the `awk` at `:175` fail, and the run exited 2 after the section 5 heading. Some failures do not exit:

- An unreadable decision record (`grep -q … || continue`, `:113`) exits 0 (Claim 3, E11).
- `echo "- $(git log -1 --format='%h %ad %s' --date=short "$full") …"` (`:190`) would mask a `git log` failure, because `set -e` ignores a failing substitution inside an argument (paraphrased — no quote available because this is bash `set -e` semantics, not code in the repo; not reproduced).

**Evidence:** `scripts/dev-cycle.sh:21,113,175,190`; `LOGS/probes.log` (P3); `LOGS/probe-unreadable.log`

---

## Claim 6: "drops C0 controls but TAB and LF, DEL, C1 controls (U+0080-009F), bidi controls (U+200E/F, U+202A-202E, U+2066-2069) and tag characters (U+E0000-E007F)"

**Location:** `scripts/dev-cycle.sh:24-26`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the byte patterns against the listed code-point ranges in the default environment. Does not establish behaviour when the caller's environment sets `PERL_UNICODE` or `PERL5OPT` (Claim 8).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/dev-cycle.sh:29
LC_ALL=C perl -pe 's/\xC2[\x80-\x9F]|\xE2\x80[\x8E\x8F\xAA-\xAE]|\xE2\x81[\xA6-\xA9]|\xF3\xA0[\x80\x81][\x80-\xBF]//g; tr/\000-\010\013-\037\177//d'
```

Each pattern decodes to its range:

| Pattern | Code points |
|---|---|
| `C2 80-9F` | U+0080–009F |
| `E2 80 8E/8F` | U+200E/F |
| `E2 80 AA-AE` | U+202A–202E |
| `E2 81 A6-A9` | U+2066–2069 |
| `F3 A0 80-81 xx` | U+E0000–E007F |

The `tr` keeps `\011` (TAB) and `\012` (LF). Test 5 passes. Mutants M3 (stdout-only scrub) and M4 (C1 pattern removed) each make it fail (E6). In E9 the default-environment run turned `a\xff\xfeb\xc2\x9bc\xe2\x80\xaed` into `a\377\376bcd`.

**Evidence:** `scripts/dev-cycle.sh:28-31`; `LOGS/mut-M3.log`; `LOGS/mut-M4.log`; `LOGS/scrub-probe.log`

---

## Claim 7: "The one scrub for everything printed, stdout and stderr"

**Location:** `scripts/dev-cycle.sh:24`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers everything the script writes after `:31`, including `--help` and the `${2:?}` messages. Does not cover the fixed perl-missing message at `:23`, written before the `exec`, or perl's own warnings, which go to the original stderr unscrubbed (Claim 8).
**Legibility-target:** for-orchestrator-synthesis

The only output before the `exec` is `command -v perl >/dev/null || { echo "dev-cycle.sh needs perl (to scrub its output)" >&2; exit 1; }` (`:23`), and it is fixed text. The `--help` `sed` at `:41` runs after `:31`. Test 5's stderr half (`$'--bo\033gus'` → `Unknown option: --bogus`) fails under mutant M3.

**Evidence:** `scripts/dev-cycle.sh:23,31,41`; `LOGS/mut-M3.log`

---

## Claim 8: "Byte patterns under LC_ALL=C, so invalid UTF-8 in a file name cannot make perl warn or die."

**Location:** `scripts/dev-cycle.sh:26-27`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the default environment (no `PERL_UNICODE`/`PERL5OPT`). Does not hold when the caller exports `PERL_UNICODE=SD` (or `PERL5OPT=-CSD`): perl then warns, and the scrub stops working.
**Legibility-target:** for-author

`LC_ALL=C` neutralises only locale-conditional UTF-8 layers (the `L` flag of `-C`). `PERL_UNICODE=SD` puts UTF-8 layers on STDIN and STDOUT whatever the locale.

In E9, with `PERL_UNICODE=SD`, perl printed `Malformed UTF-8 character …` warnings. Worse, the C1 byte pair `302 233` and RLO `342 200 256` passed through unchanged, because the byte regexes now match against decoded characters. `PERL5OPT=-CSD` behaved the same. The default environment is clean: no warning, all removed.

A precise version: "Byte patterns under LC_ALL=C, with no PERL_UNICODE/PERL5OPT in the environment". The script could also clear those itself, for example `env -u PERL_UNICODE -u PERL5OPT` or `perl -C0`.

**Evidence:** `scripts/dev-cycle.sh:28-30`; `LOGS/scrub-probe.log`

---

## Claim 9: "before the cd: relative paths work"

**Location:** `scripts/dev-cycle.sh:47`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers resolving `SCRIPT_DIR` from a relative script path run in a subdirectory. Does not establish symlinked-script behaviour.
**Legibility-target:** for-orchestrator-synthesis

The code is `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`, and it precedes `cd "$ROOT"` (`:47-49`). Test 11 runs a relative path from `sub/dir` and passes (E1).

**Evidence:** `scripts/dev-cycle.sh:47-49`; `test/scripts/dev-cycle.bats:156-165`

---

## Claim 10: "DEV_CYCLE_TODAY exists only so tests can pin the date. File names are literal, not pathspecs."

**Location:** `scripts/dev-cycle.sh:50-52`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the variable's single use and the export. Does not establish test coverage of `GIT_LITERAL_PATHSPECS` (none exists; pass-3 C5).
**Legibility-target:** for-orchestrator-synthesis

The line is `TODAY="${DEV_CYCLE_TODAY:-$(date +%F)}"; export GIT_LITERAL_PATHSPECS=1` (`:52`). Every later git call that takes a path (`:116`, `:172`, `:204`) runs with literal pathspecs.

**Evidence:** `scripts/dev-cycle.sh:52,116,172,204`

---

## Claim 11: "Pass git only a hash for the default branch: … a branch named `--output=<path>` would reach `git log` as an option."

**Location:** `scripts/dev-cycle.sh:53-54`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that only `$MAIN_SHA` reaches git and `-*` names are skipped. Does not re-examine the origin/HEAD trust model.
**Legibility-target:** for-orchestrator-synthesis

The code skips option-like names (`[[ "$c" == -* ]] && continue`, `:61`) and resolves `refs/heads/$c^{commit}` (`:62`). Test 15 passes, and the victim file stays `keep` (E1).

**Evidence:** `scripts/dev-cycle.sh:55-72`; `test/scripts/dev-cycle.bats:218-228`

---

## Claim 12: "ignore future-dated"

**Location:** `scripts/dev-cycle.sh:78`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers records dated after `$TODAY`. Does not cover malformed dates that still match the glob (for example `cycle-2026-99-99.md`), which are rejected later by the `--since` validation at `:88`.
**Legibility-target:** for-orchestrator-synthesis

The guard is `[[ "$d" > "$last_record" && ! "$d" > "$TODAY" ]]`. Test 7 includes `cycle-9999-12-31.md` and selects 2026-02-10 (E1).

**Evidence:** `scripts/dev-cycle.sh:75-79`; `test/scripts/dev-cycle.bats:114-121`

---

## Claim 13: Window line — "Merges and commits: those on `$MAIN` at … committed on or after $SINCE, filtered by date after a full walk. Triggers: all of them, from the working tree. Questions, roadmap, idea log: the working tree."

**Location:** `scripts/dev-cycle.sh:92`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers sections 1, 2, 3, 4, 5, 6 and the step 5 inputs. Does not describe section 7's step-4b file list, and "committed on" is the committer's own-zone date.
**Legibility-target:** for-author

Sections 1, 4 and 6 read `merges_full`/`merges`, filtered at `:99`. That matches the line, with Claim 1's time-zone qualifier (P4).

Section 7's step-4b list is not "those committed on or after $SINCE". It is the net diff from the parent of the oldest in-window first-parent commit to `MAIN_SHA`: `changed="$(git diff --name-only -z "$base" "$MAIN_SHA" -- skills workflows docs/decisions | tr '\0\n' '\n ')"` (`:204`). That includes old-dated commits after the base, and omits changes that cancel out (Claim 21, P6b).

The "last committed on this branch" dates in sections 2 and 5 come from `git log -1 … -- "$f"` on HEAD, not on `$MAIN` (`:116`, `:172`). The line does not mention that. It is labelled "this branch" in the output itself.

**Evidence:** `scripts/dev-cycle.sh:92,99,116,172,199-204`; `LOGS/probes.log` (P4); `LOGS/probes2.log` (P6b)

---

## Claim 14: "`--since` stops at the first old-dated commit, so one such commit hid every merge after it."

**Location:** `scripts/dev-cycle.sh:96-97`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what baa46e3's `--since` walk returned in test 4's scenario. Does not establish git's walk-stop rule beyond that observed scenario.
**Legibility-target:** for-author

Running HEAD's test 4 against baa46e3's script (E4) printed "1 merge(s) …" and listed `merge: feature 4`, the merge made after the old commit in history. The three merges older than the old commit were hidden. "After it" is right only in walk order (newest first). In history order the hidden merges came before it. A precise version: "so one such commit hid every merge older than it".

**Evidence:** `LOGS/bats-headtests-on-baa46e3.log` (test 4 output); `scripts/dev-cycle.sh:96-102`

---

## Claim 15: "%cs is the committer date as YYYY-MM-DD, which compares as a string."

**Location:** `scripts/dev-cycle.sh:98`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers lexical-equals-chronological ordering for zero-padded 4-digit-year dates. Does not cover which time zone the date is in (Claim 1).
**Legibility-target:** for-orchestrator-synthesis

`awk -v s="$SINCE" '$1 >= s'` compares two strings, because `SINCE` is validated to `^[0-9]{4}-[0-9]{2}-[0-9]{2}$` (`:88`) and `%cs` has the same shape. For fixed-width zero-padded dates, string order equals date order. E7 P4 shows `%cs` printing `2026-09-30` for a `-1000` committer.

**Evidence:** `scripts/dev-cycle.sh:88,99,102`

---

## Claim 16: "A newline in a file name would otherwise print a line of its own." (and, per brief item 5, whether any repo text can still print its own line)

**Location:** `scripts/dev-cycle.sh:117-118`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `###` heading, merge subjects in sections 1/4/6, section-7 file names, log rows, roadmap lines, record trigger lines and questions.sh output. Does not establish that heading-like text inside a single line is harmless to the reading agent; it is only kept off line start.
**Legibility-target:** for-orchestrator-synthesis

The heading uses `echo "### ${f//$'\n'/ } (…)"`. Mutant M1 (no replacement) makes test 6 fail (E6). Test 6 also passes on baa46e3, because the heading fix predates d9e4cb9. R1's carried list is removed by deletion, not guarded by this test.

E12 tried the remaining sources:

- A merge message `"merge: line one\n## 3. Forged heading"` printed as one line, `… merge: line one ## 3. Forged heading`, in sections 1 and 4, because `%s` joins the subject paragraph.
- A skill path `skills/a\n## 3. Fake/SKILL.md` printed as `    - skills/a ## 3. Fake/SKILL.md`, through the `tr '\0\n' '\n '` at `:204`.

`grep -n '^## '` found only the seven real headings. The other sources cannot carry a newline (paraphrased — no quote available because this is a claim of absence across many lines):

- Log rows come from `read -r` lines.
- Trigger and roadmap lines get a `> ` prefix (`:119`, `:175`).
- Questions lines get a `- ` prefix (`:145`).
- The questions.sh error text is fixed messages with fixed paths (`scripts/questions.sh:135`).
- The idea log is only counted.

**Evidence:** `scripts/dev-cycle.sh:105,118-119,130,145,165,175,190,204`; `LOGS/mut-M1.log`; `LOGS/probe-misc.log`

---

## Claim 17: "The whole clause to the cell's end; prefer a capitalised "Revisit" (the trigger sentence) over an earlier "revisit-trigger verdicts" mention."

**Location:** `scripts/dev-cycle.sh:126-127`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the clause extraction for a row with both forms. Does not cover a row whose trigger text contains a literal `|`, which ends the clause early.
**Legibility-target:** for-orchestrator-synthesis

The extraction is `grep -oE 'Revisit[^|]*' … | head -1`, with a case-insensitive fallback (`:128-129`). Test 2 has a 500-char clause after a lowercase `revisit-trigger verdicts` cell and passes (E1).

**Evidence:** `scripts/dev-cycle.sh:121-132`; `test/scripts/dev-cycle.bats:51-63`

---

## Claim 18: "`open` prints "ID  route  slug" in columns of 2+ spaces; a route can contain one space ("you: judgment"), a slug can contain "trigger"."

**Location:** `scripts/dev-cycle.sh:141-142`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers questions.sh's `open` format and the route-column match. Does not cover a route padded past 14 characters.
**Legibility-target:** for-orchestrator-synthesis

The format is `printf '%s  %-14s  %s\n' "$id" "$route" "$slug"` (`scripts/questions.sh:412`). Test 12 (slug `a-trigger-in-the-slug`, route `agent`) passes (E1).

**Evidence:** `scripts/questions.sh:408-414`; `scripts/dev-cycle.sh:143-150`

---

## Claim 19: "Seeded by a hash of the date: same day, same merges; different days usually differ."

**Location:** `scripts/dev-cycle.sh:162-163`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers rerun stability and multi-date variation in tests 9–10. Does not establish distribution quality.
**Legibility-target:** for-orchestrator-synthesis

The seed is `seed="$(printf '%s' "$TODAY" | sha256sum | cut -c1-64)"` and feeds `shuf --random-source=<(yes "$seed")`. Tests 9 and 10 pass (E1).

**Evidence:** `scripts/dev-cycle.sh:161-168`

---

## Claim 20: "A merge whose diff against its first parent touches files but no docs/ path, *.md or README is a step 4 finding to check"

**Location:** `scripts/dev-cycle.sh:181-182`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the classification awk and the first-parent diff for every merge in `merges_full`. Does not establish the rename-only case by execution (static reading only).
**Legibility-target:** for-author

```bash
# scripts/dev-cycle.sh:186
counts="$(git diff --name-only -z "$full^1" "$full" | awk -v RS='\0' 'NF { if ($0 ~ /^docs\// || $0 ~ /\.md$/ || $0 ~ /(^|\/)README/) d++; else c++ } END { print c + 0, d + 0 }')"
```

`(^|\/)README` is unanchored at the end. It matches any path component that starts with README: `README_gen.sh`, `src/READMEish.py`, a directory `README/x.c`.

In E7 P5, a merge that changed only `src/READMEish.py` and `README_gen.sh` was not flagged. Both files counted as docs. A precise wording would be "…or a path component starting with README". Mutant M5, which drops the README clause, still passes test 17 (E6), so the clause is untested.

On the brief's other questions:

- **`$full^1` always exists.** Every line in `merges_full` comes from `--merges`, and shallow-boundary commits show as parentless, so they are not listed. P7, a `--depth 1` clone, exited 0.
- **Renames.** With git's default rename detection, `--name-only` lists the new name once, so a rename-only merge counts 1 code file (paraphrased — no quote available because this is git's diff default, not repo code; not executed).
- **NUL record separator.** `RS='\0'` works under mawk 1.3.4 (E13).

**Evidence:** `scripts/dev-cycle.sh:183-193`; `LOGS/probes.log` (P5, P7); `LOGS/mut-M5.log`

---

## Claim 21: "Base = the parent of the oldest first-parent commit in the window (the empty tree when that commit is the root). Old-dated commits after it are included: re-reading a file is cheap, missing one is not."

**Location:** `scripts/dev-cycle.sh:196-198`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the base selection, the root fallback and inclusion of old-dated commits after the base. Does not establish that every file touched in the window is listed: a change that is reverted inside the window shows no net diff and is omitted.
**Legibility-target:** for-orchestrator-synthesis

The code (`:199-204`) works as the comment says:

- `oldest` is the last `%cs >= SINCE` line of a newest-first, first-parent walk, so it is the topologically oldest in-window commit.
- The base is `git rev-parse --verify --quiet "$oldest^1" || git hash-object -t tree /dev/null`.
- Test 18 (`--since=2000-01-01`, so the root is in the window) lists both files (E1).

The comment does not claim more than that. The residue: E8 P6b changed `skills/a/SKILL.md` today and restored it in a later commit today, and section 7 printed "Skill or workflow files changed … : 0". The `tr '\0\n' '\n '` maps NUL to LF and LF-in-name to space. It works on `-z` output, which git does not quote (E12).

**Evidence:** `scripts/dev-cycle.sh:199-207`; `LOGS/probes2.log` (P6b); `LOGS/probe-misc.log`

---

## Claim 22: "Step 5 (brainstorm triggers; the thresholds are the skill's):"

**Location:** `scripts/dev-cycle.sh:218`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the dev-cycle skill as it exists on branch `feat/dev-cycle` (`skills/dev-cycle/SKILL.md`; there is none on main). Does not establish what the planned skill revision will say.
**Legibility-target:** for-author

The skill's step 5 has no thresholds and does not read roadmap counts or a last-brainstorm date:

```
# feat/dev-cycle:skills/dev-cycle/SKILL.md (### 5. Brainstorm; excerpt ends at the step's first sentence, section continues 4 lines — read)
Generate 3–8 candidate features or improvements. Each must name the **signal** that
motivates it …
```

Its roadmap template has `## Now`, `## Next`, `## Ideas` and `## Done`, and no `## In flight`, which `:220` counts. db0e5ca's Notes say the skill "must write" the matching format. As committed, the reference points at nothing. Confidence is Medium because the skill change is planned in the stacked unit.

**Evidence:** `scripts/dev-cycle.sh:218-226`; `feat/dev-cycle:skills/dev-cycle/SKILL.md` (§5 Brainstorm, §6 Roadmap template)

---

## Claim 23: "Step 5 heads each brainstorm "## Brainstorm YYYY-MM-DD"; ideas are "- " lines."

**Location:** `scripts/dev-cycle.sh:229`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the step-5 text on `feat/dev-cycle`. Does not establish the approval doc's wording, which is not present in this worktree or any local branch.
**Legibility-target:** for-author

`git grep -i -E 'idea-log|Brainstorm [0-9Y]|seeded'` across all local branches' `docs/` and `skills/` finds no such convention (paraphrased — no quote available because the claim's evidence is an absence of grep hits). The skill's step 5 puts surviving ideas in the roadmap: "**Ideas**: this cycle's surviving brainstorm items, unranked, each with its signal." (`feat/dev-cycle:skills/dev-cycle/SKILL.md`, §6). The comment states as current a format that the commit's Notes call future work.

**Evidence:** `scripts/dev-cycle.sh:227-241`; `feat/dev-cycle:skills/dev-cycle/SKILL.md` (§5, §6)

---

## Claim 24: "- Ideas seeded since: $seeded"

**Location:** `scripts/dev-cycle.sh:232,238`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what `seeded` counts. Does not establish what the skill means by "seeded since", which it does not define (Claim 23).
**Legibility-target:** for-author

```bash
# scripts/dev-cycle.sh:232
seeded="$(awk '/^## Brainstorm [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ { c = 0; next } /^- / { c++ } END { print c + 0 }' "$LOG")"
```

The count resets only at a Brainstorm heading. So it counts the last brainstorm's own `- ` items plus every column-0 `- ` line after them, under any later heading, to EOF. With no Brainstorm heading, it counts every `- ` line in the file. Test 18 expects 2 for a section holding the brainstorm's own two items "one" and "two" (E1). Under that test, "since" means "in and after the last brainstorm". Nested or `* ` items are not counted. "Last brainstorm" is the last heading in file order (`tail -1`), not the latest date.

**Evidence:** `scripts/dev-cycle.sh:231-238`; `test/scripts/dev-cycle.bats:250-263`

---

## Claim 25: "No {n} intervals in the awk regex: mawk, Debian's default awk, lacks them."

**Location:** `scripts/dev-cycle.sh:230`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers mawk 1.3.4 20200120 (Debian 12 here) and every awk program in the script. Does not establish newer mawk releases, which added interval support.
**Legibility-target:** for-orchestrator-synthesis

In E13, `echo aab | mawk '/^a{2}b/'` printed nothing, and `echo 'a{2}b' | mawk '/^a{2}b/'` matched, so the braces are taken literally. Mutant M6, which puts `{4}` intervals in the `:232` regex, fails test 18 (E6).

`grep -n awk scripts/dev-cycle.sh | grep -E '\{[0-9]'` finds no other intervals. The `{4}`/`{2}` at `:231` and `:207` are in `grep -E`, not awk.

**Evidence:** `scripts/dev-cycle.sh:110,143,150,175,186,199,221,232`; `LOGS/mut-M6.log`

---

## Claim 26: "Each test builds a throwaway repo under $BATS_TEST_TMPDIR; this repo is untouched."

**Location:** `test/scripts/dev-cycle.bats:3-4`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `setup()`/`make_repo` and the per-test `cd`. Does not audit global git config isolation beyond `GIT_CONFIG_GLOBAL=/dev/null`.
**Legibility-target:** for-orchestrator-synthesis

The setup is `R="$BATS_TEST_TMPDIR/repo"; make_repo "$R" main; cd "$R"` (`:17-19`). Test 11 copies `scripts/` out to `$BATS_TEST_TMPDIR/tools` and only reads the repo.

**Evidence:** `test/scripts/dev-cycle.bats:8-35,156-165`

---

## Claim 27: "HOME in the temp dir: the ~/.claude/scripts fallback can't reach the real one."

**Location:** `test/scripts/dev-cycle.bats:14`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the `$HOME` fallback at `scripts/dev-cycle.sh:137`. Does not apply to tests that call questions.sh via `$SCRIPT_DIR`, which is found first.
**Legibility-target:** for-orchestrator-synthesis

The test sets `export HOME="$BATS_TEST_TMPDIR/home"`. The script falls back to `QS="$HOME/.claude/scripts/questions.sh"`.

**Evidence:** `test/scripts/dev-cycle.bats:15-16`; `scripts/dev-cycle.sh:136-137`

---

## Claim 28: test name "an old-dated commit on main does not hide the merges after it"

**Location:** `test/scripts/dev-cycle.bats:80`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the test guards: the count of all four merges. Does not change the result that the test fails on baa46e3.
**Legibility-target:** for-author

The test fails on baa46e3 (E4), so it guards R3. The old code hid the merges older than the old commit (features 1–3). It showed the one after it (`merge: feature 4`). The assertions `*"4 merge(s)"*` and `*"merge: feature 4"*` (`:88-89`) are right. The name has the direction backwards in history order; "does not hide the merges before it" would match.

**Evidence:** `test/scripts/dev-cycle.bats:80-91`; `LOGS/bats-headtests-on-baa46e3.log`

---

## Claim 29: "--since used to stop its walk at the old commit and report 0 merges."

**Location:** `test/scripts/dev-cycle.bats:81-82`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers baa46e3's output in this test's exact scenario. Does not cover rubric R3's own scenario, where the old commit is the tip.
**Legibility-target:** for-author

In this test's scenario, baa46e3 reported "1 merge(s) on `main`'s first-parent line; 2 commit(s)" and listed `215253e … merge: feature 4` (E4 failure output). It did not report 0. "0 merges" holds when the old-dated commit is the newest first-parent commit, as in R3. Here a merge is made after it.

**Evidence:** `LOGS/bats-headtests-on-baa46e3.log` (not ok 4 block)

---

## Claim 30: test name "after a cycle record, every trigger still prints in full and nothing is carried"

**Location:** `test/scripts/dev-cycle.bats:65`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers old, uncommitted and future-dated triggers with a recent record that holds a `Main at:` line. Does not cover unreadable records (Claim 3).
**Legibility-target:** for-orchestrator-synthesis

The test passes at HEAD and fails against baa46e3 (E4: "not printed in full").

**Evidence:** `test/scripts/dev-cycle.bats:65-78`; `LOGS/bats-headtests-on-baa46e3.log`

---

## Claim 31: test name "the scrub strips C0, C1, bidi and tag characters from stdout and stderr" (and `:99` "A non-repo error message carrying an ESC still reaches stderr scrubbed.")

**Location:** `test/scripts/dev-cycle.bats:93,99`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one code point each of C1, RLO, tag, ESC and CR on stdout, and ESC on stderr. Does not test U+200E/F, U+2066–2069 or DEL individually, or the `PERL_UNICODE` case (Claim 8).
**Legibility-target:** for-orchestrator-synthesis

The test fails on baa46e3 (E4), under M3 (stdout-only scrub) and under M4 (no C1 pattern) (E6). "Non-repo" here means the text is user-supplied (an unknown option), not repo-derived.

**Evidence:** `test/scripts/dev-cycle.bats:93-104`; `LOGS/mut-M3.log`; `LOGS/mut-M4.log`

---

## Claim 32: test name "a newline in a decision record's name cannot print a line of its own"

**Location:** `test/scripts/dev-cycle.bats:106`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `###` heading's replacement. Does not guard R1's carried list: that code was deleted, and this test also passes on baa46e3.
**Legibility-target:** for-orchestrator-synthesis

Mutant M1 fails it (E6). It passes against baa46e3 (E4), so it is a new guard on the old heading fix (closes pass-3 C5's heading half), not a regression test for R1.

**Evidence:** `test/scripts/dev-cycle.bats:106-112`; `LOGS/mut-M1.log`

---

## Claim 33: test name "--since counts from midnight, not from the current time of day" (and `:125` "a midnight window counts all")

**Location:** `test/scripts/dev-cycle.bats:123-129`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers same-zone commits made just after local midnight. Does not establish behaviour for commits in other time zones, where "midnight" is the committer's own (Claim 1).
**Legibility-target:** for-orchestrator-synthesis

Mutant M2 replaces the `%cs` count with `git rev-list --count --since="$SINCE"`, which git reads as the current time of day. It fails this test (E6, run at 19:09 local). The test still checks what its name says, now through the string compare.

**Evidence:** `test/scripts/dev-cycle.bats:123-129`; `LOGS/mut-M2.log`

---

## Claim 34: "No questions-archive.md: questions.sh open exits non-zero."

**Location:** `test/scripts/dev-cycle.bats:200`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `require_files` failing on a missing archive. Does not cover other `open` failures.
**Legibility-target:** for-orchestrator-synthesis

`cmd_open` calls `require_files` first (`scripts/questions.sh:409`), which prints `✗ missing:` (`:135`). Test 13 passes (E1).

**Evidence:** `scripts/questions.sh:135,408-414`; `test/scripts/dev-cycle.bats:197-206`

---

## Claim 35: test name "flags a merge that changed code with no doc change, not one that did both"

**Location:** `test/scripts/dev-cycle.bats:239`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the code-only versus code-plus-`docs/` distinction, and that the empty-diff feature merges are not flagged. Does not exercise the README or `*.md` clauses (mutant M5 passes).
**Legibility-target:** for-orchestrator-synthesis

The test fails on d9e4cb9 and baa46e3, where section 6 is absent (E4, E5), and passes at HEAD.

**Evidence:** `test/scripts/dev-cycle.bats:239-248`; `LOGS/mut-M5.log`; `LOGS/bats-headtests-on-d9e4cb9.log`

---

## Claim 36: test name "prints the step 4b and step 5 inputs"

**Location:** `test/scripts/dev-cycle.bats:250`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the root-in-window base, both lists, the three roadmap counts, the last-brainstorm age and the seeded count. Does not cover an in-window base with a parent, or the net-zero case (Claim 21).
**Legibility-target:** for-orchestrator-synthesis

The test fails on d9e4cb9 (E5) and under M6 (E6), and passes at HEAD.

**Evidence:** `test/scripts/dev-cycle.bats:250-263`; `LOGS/mut-M6.log`

---

## Claim 37: d9e4cb9 — "16/16 pass; shellcheck clean."

**Location:** commit d9e4cb9 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers d9e4cb9's own bats file and script, run in this environment. Does not establish CI behaviour.
**Legibility-target:** for-orchestrator-synthesis

E3 ran `bats` at d9e4cb9 with exit 0 (`1..16`, 16 `ok`), and `shellcheck` with exit 0.

**Evidence:** `LOGS/bats-d9e4cb9.log`; `LOGS/sc-d9e4cb9.log`

---

## Claim 38: d9e4cb9 — "the "Main at:" handshake, the base lookup and the carried list are gone (rubric pass 3: R1, R2, A1, A3, A5, A6, C1, C3 lose their code)."

**Location:** commit d9e4cb9 message
**Type:** Reference / Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the presence of the code each finding cites in the pass-3 rubric (`docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:81-102`). Does not cover pass-3 C6, which is not in the list: async stderr ordering, still present (Claim 5b).
**Legibility-target:** for-orchestrator-synthesis

The cited code is gone. `grep -n -i -E 'carr|Main at|merge-base|cmp |base=|changed since' scripts/dev-cycle.sh` finds only `:15` (the new comment) and `:203` (section 7's unrelated `base=`). The removed code, from the d9e4cb9 diff, is:

- the `carried+=` list (R1, C1)
- the `Main at:` echo and parse (R2, A1, A3, C3)
- the "changed since" text (A5)
- the `cmp`-based comparison (A6)

**Evidence:** `scripts/dev-cycle.sh:15,203`; `git diff baa46e3 d9e4cb9 -- scripts/dev-cycle.sh`

---

## Claim 39: d9e4cb9 — "R3: merges and commits are walked in full and filtered by committer date (%cs) afterwards" / "A2: one scrub() filters stdout AND stderr, set up before option parsing"

**Location:** commit d9e4cb9 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers sections 1, 4 and 6 (all from `merges_full`) and the `exec` placement. Does not establish the scrub's robustness to `PERL_UNICODE` (Claim 8).
**Legibility-target:** for-orchestrator-synthesis

The walks are `:99` and `:102`. `exec > >(scrub) 2> >(scrub >&2)` at `:31` comes before the `while` at `:35`. Tests 4 and 5 fail on baa46e3 and pass at HEAD (E4).

**Evidence:** `scripts/dev-cycle.sh:31-35,99-102`; `LOGS/bats-headtests-on-baa46e3.log`

---

## Claim 40: d9e4cb9 — "A4, C2: the Window line and --help say what the window is and that nothing carries forward."

**Location:** commit d9e4cb9 message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the text of `:10-15` and `:92`. Does not cover section 2's intro line, which also states it.
**Legibility-target:** for-author

`--help` says it: "Every revisit trigger is printed in full every run; nothing carries forward." (`:15`). The Window line (`:92`) does not mention carry-forward; section 2's intro at `:108` does. The Window line's account of the window also misses section 7's base rule (Claim 13).

**Evidence:** `scripts/dev-cycle.sh:10-15,92,108`

---

## Claim 41: d9e4cb9 Notes — "perl is now required (byte-pattern scrub; tr can't match UTF-8 sequences). The window still defaults to the newest record's file-name date, inclusive"

**Location:** commit d9e4cb9 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the perl gate and the inclusive `>=` default. Does not evaluate alternatives to perl.
**Legibility-target:** for-orchestrator-synthesis

The gate exits 1 without perl (E12). `SINCE="$last_record"` (`:83`) with `$1 >= s` (`:99`) is inclusive. GNU `tr` works per byte and cannot delete a multibyte sequence while keeping the other bytes of the same values (paraphrased — no quote available because this is coreutils behaviour, not repo code).

**Evidence:** `scripts/dev-cycle.sh:23,83,99`; `LOGS/probe-misc.log`

---

## Claim 42: db0e5ca — "18/18 tests pass; shellcheck clean. Script is 241 lines."

**Location:** commit db0e5ca message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers HEAD in this environment. Does not establish CI behaviour.
**Legibility-target:** for-orchestrator-synthesis

E1 gave exit 0 with 18 `ok`. E2 `shellcheck` exited 0. `wc -l` gives 241 for `scripts/dev-cycle.sh` and 263 for the bats file.

**Evidence:** `LOGS/bats-head.log`; `LOGS/shellcheck.log`

---

## Claim 43: db0e5ca — "All stateless: nothing here reads a cycle record."

**Location:** commit db0e5ca message
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers sections 6 and 7, which db0e5ca added. Does not apply to the script as a whole: the default window still globs cycle-record file names, without opening them (Claim 2).
**Legibility-target:** for-orchestrator-synthesis

Sections 6–7 (`:180-241`) reference `merges_full`, `MAIN_SHA`, `SINCE`, `docs/roadmap.md` and `docs/working/idea-log.md`, and no `docs/working/cycles/` path (paraphrased — no quote available because the claim is an absence across 62 lines).

**Evidence:** `scripts/dev-cycle.sh:180-241`

---

## Claim 44: db0e5ca Notes — "the 4b window base is the parent of the oldest in-window first-parent commit (over-includes, never misses)"

**Location:** commit db0e5ca message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers files whose content at `MAIN_SHA` differs from the base. Does not hold for files changed and then restored inside the window.
**Legibility-target:** for-author

The base rule and the over-inclusion are as stated (Claim 21). "Never misses" is refuted by E8 P6b. A skill edited and reverted within the window is reported as "0" changed, because the list is a net `git diff base MAIN_SHA`, not a union of per-commit changes. A precise version: "never misses a file whose content differs from the base".

**Evidence:** `scripts/dev-cycle.sh:199-207`; `LOGS/probes2.log` (P6b)

---

## Claims Requiring Attention

### Incorrect
- **Claim 22** (`scripts/dev-cycle.sh:218`): "the thresholds are the skill's". The dev-cycle skill (feat/dev-cycle) has no step-5 thresholds and no "In flight" roadmap section. Either say the skill must add them, or land the skill change.
- **Claim 23** (`scripts/dev-cycle.sh:229`): "Step 5 heads each brainstorm '## Brainstorm YYYY-MM-DD'". No skill text writes that format, and step 5 puts ideas in roadmap `## Ideas`. State it as the format the skill must adopt.
- **Claim 29** (`test/scripts/dev-cycle.bats:81-82`): "report 0 merges". baa46e3 reported 1 merge (`feature 4`) in this scenario and hid the three older ones.

### Stale
(none)

### Mostly Accurate
- **Claim 1** (`scripts/dev-cycle.sh:10`): "committed on or after this date" means the committer's own-zone date (`%cs`). A 02:00-local merge from a −1000 committer falls outside a same-day window.
- **Claim 3** (`scripts/dev-cycle.sh:15`): an unreadable decision record is skipped silently (`grep -q … || continue`), with exit 0.
- **Claim 5b** (`scripts/dev-cycle.sh:18`): "0 digest printed". The async perl scrubs can still be writing at exit: stderr trailed exit in 20/20 runs, and a large stdout to a file was short in 1/20.
- **Claim 5c** (`scripts/dev-cycle.sh:19`): "a failed step exits non-zero". Failures behind `|| continue` (`:113`) and inside `echo "$(…)"` (`:190`) do not exit.
- **Claim 8** (`scripts/dev-cycle.sh:26-27`): LC_ALL=C does not protect against `PERL_UNICODE=SD`/`PERL5OPT=-CSD` in the caller's environment. Perl then warns, and C1/RLO pass unscrubbed.
- **Claim 13** (`scripts/dev-cycle.sh:92`): the Window line does not describe section 7's net-diff-from-base list, or the committer-zone date.
- **Claim 14** (`scripts/dev-cycle.sh:96-97`): "hid every merge after it". The hidden merges are the ones older than the old-dated commit.
- **Claim 20** (`scripts/dev-cycle.sh:181-182`): `(^|\/)README` matches any component starting with README (`READMEish.py`, `README_gen.sh`), so such code merges are not flagged. The clause is untested.
- **Claim 24** (`scripts/dev-cycle.sh:232,238`): "Ideas seeded since" counts the last brainstorm's own items plus every later `- ` line, under any heading.
- **Claim 28** (`test/scripts/dev-cycle.bats:80`): the test name says "after it", but the merges the old code hid came before it.
- **Claim 40** (commit d9e4cb9): the Window line does not say nothing carries forward. `--help` and section 2 do.
- **Claim 44** (commit db0e5ca): "never misses" fails for a file changed and reverted within the window.

### Unverifiable
(none)

---

## Goal-Alignment Note

**Success criterion (verbatim from the brief):** a markdown report saved at the path your role instructions give, structured per your skill file.

**Answered:**

- All ten "claims that particularly need checking" were verdicted, most by execution.
- The cut did delete R1/R2/A1/A3/A5/A6 (and C1/C3) code (Claim 38).
- R3 and A2 are fixed and their tests fail on baa46e3 (Claims 30, 31, 39).
- No repo-derived text could print a line of its own in any section tried (Claim 16).
- There are no awk `{n}` intervals left (Claim 25).
- Commit-message counts (16/16, 18/18, 241 lines, shellcheck) hold.
- Nothing new of the R1 kind replaced the removed code.

**Out of scope:**

- Whether the merge should happen.
- Code-quality judgements on the fixes.
- The dev-cycle skill on `feat/dev-cycle` itself (read only to check the references in Claims 22–23).

**Escalate:**

- **Claim 8:** the scrub silently stops working under `PERL_UNICODE`/`PERL5OPT`, which defeats A2's fix in that environment.
- **Claim 5b:** an output file can be incomplete when the script returns, and stderr always trails. This affects any caller that redirects to a file, and pass-3 C6 is not closed.
- **Claims 22–23:** the step-4b/5 inputs reference a skill format that does not exist yet on any branch.

**Questions / Decisions:**

- Should `scrub()` clear `PERL_UNICODE`/`PERL5OPT` (or use `perl -C0`)?
- Should the script wait for its scrubs before exiting, for example by closing fds and `wait`-ing on `$!` in an EXIT trap?
- Should `(^|/)README` be anchored, for example `(^|/)README(\.[^/]*)?$`?
- Does the user want section 7 to count net changes or every change in the window?
