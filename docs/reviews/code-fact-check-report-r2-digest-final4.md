Commit: db0e5ca

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-digest (branch feat/dev-cycle-digest)
**Scope:** `git diff main...HEAD -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (both files new on the branch, 241 + 263 lines), plus the commit messages of d9e4cb9 and db0e5ca. Context read, not reviewed: `skills/dev-cycle/SKILL.md` on `feat/dev-cycle` (70cc7dc), `scripts/questions.sh`, `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md`.
**Checked:** 2026-10-01
**Total claims checked:** 44
**Summary:** 30 verified, 10 mostly accurate, 0 stale, 1 incorrect, 3 unverifiable

Reviewer: code-fact-check, replicate r2, digest final pass 4 (session dc1aa358).

## Execution provenance

All commands ran under `timeout` at 2026-10-01 19:06-19:14 -07:00, with mawk 1.3.4 20200120 as `awk`, perl 5 and GNU coreutils. The sandbox sets `LC_ALL=en_US.UTF-8`, a locale that is not installed, so un-pinned perl and bash print `setlocale` warnings; they are filtered from quotes below. Throwaway repos were built only under the session scratchpad and removed. Nothing in the worktree was written except this report. Captured output lives outside the worktree, because the brief forbids writing anything else into it. Its directory is `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fcr2-logs/` (abbreviated `$LOGS` below), and the probe scripts sit one directory up.

| ID | Command (cwd) | Exit | Time | Output |
|---|---|---|---|---|
| E1 | `bats test/scripts/dev-cycle.bats` (worktree) | 0 | 19:06:59 | `$LOGS/bats-head.txt` (18/18 ok) |
| E2 | `shellcheck scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (worktree) | 0 | 19:07 | `$LOGS/shellcheck-head.txt` |
| E3 | `wc -l scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (worktree) | 0 | 19:07 | `$LOGS/wc-head.txt` (241, 263) |
| E4 | `bats` and `shellcheck` on `git archive d9e4cb9` / `git archive baa46e3` trees (temp dir) | 0 / 0 | 19:07 | `$LOGS/bats-d9e4cb9.txt` (16/16), `$LOGS/sc-d9e4cb9.txt`, `$LOGS/bats-baa46e3.txt` (13/13) |
| E5 | HEAD's `dev-cycle.bats` run against the baa46e3 and d9e4cb9 scripts (temp dir) | 1 / 1 | 19:08 | `$LOGS/headtests-vs-baa46e3.txt`, `$LOGS/headtests-vs-d9e4cb9.txt` |
| E6 | `bash probe1.sh $DC` (`--since` walk; time-zone window) | 0 | 19:09:39 | `$LOGS/probe1.txt` |
| E7 | `bash probe2.sh $DC` (scrub byte behaviour; completeness; no-perl PATH) | 0 | 19:09:59 | `$LOGS/probe2.txt` |
| E8 | perl scrub regex with default env and with `PERL_UNICODE=SDA LC_ALL=C` | 0 | 19:10:20 | `$LOGS/probe3.txt`, `$LOGS/p3c-err.txt` |
| E9 | `bash probe4.sh $DC` (failing step: root commit object deleted; `2>&1` order, 10 runs) | 0 (digest exits 128) | 19:10:47 | `$LOGS/probe4.txt` |
| E10 | `bash probe5.sh $DC` (section 6 README/rename; section 7 revert; roadmap; idea log) | 0 | 19:11:46 | `$LOGS/probe5.txt` |
| E11 | `bash mut.sh` (8 mutants of HEAD's script, each run against the full HEAD bats file) | 0 | 19:12:05 | `$LOGS/mutations.txt` |
| E12 | mawk `{4}` probe; `shuf --random-source` raw vs hashed date | 0 | 19:13:05 | `$LOGS/probe6.txt` |
| E13 | digest run on a scratch clone of this repo, then file-change check | 0 | 19:13:20, 19:13:27 | `$LOGS/probe7.txt` |

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) was read. The relevant prior pattern is "test counts in commit messages wrong" (commit 59ca38f: 85 vs 97; 37c5ea9: 33 vs 25). Claims 33 and 37 match it in kind, and both were executed. They hold this time.

---

## Claim 1: "Everything that needs no judgment lives here, because steps that only prose asks for do not run (scripts/questions.sh header; Q-074)."

**Location:** `scripts/dev-cycle.sh:5-6`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both cited sources exist and say this; does not establish that every no-judgment step of the skill actually lives in this script.
**Legibility-target:** for-orchestrator-synthesis

`scripts/questions.sh:8` reads `# log went unwritten for nine runs, both because only prose asked for them.`, and `docs/working/questions.md:67` holds `### Q-074 · failure-pattern-writer-trigger`.

**Evidence:** `scripts/questions.sh:8`, `docs/working/questions.md:67`

---

## Claim 2: "--since   start of the cycle window: merges committed on or after this date."

**Location:** `scripts/dev-cycle.sh:10`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which merges and commits the window admits; does not establish what section 7's file lists admit (see Claim 22).
**Legibility-target:** for-author

The filter compares each commit's committer date, written in the committer's own time zone, with the given date as a string:

```bash
# scripts/dev-cycle.sh:99
merges_full="$(git log "$MAIN_SHA" --first-parent --merges --format='%cs %H %h %ad %s' --date=short | awk -v s="$SINCE" '$1 >= s')"
```

"This date" therefore means the calendar date in each committer's own zone, not the reader's. The pre-d9e4cb9 `--since` window started at local midnight, so the meaning has changed. E6 ran with `TZ` = -0700 and `--since=2026-10-01`. It admitted a merge stamped `2026-10-01 00:30:00 +1400`, which is 2026-09-30 03:30 local. It left out a merge stamped `2026-09-30 23:31:00 -1200`, which is 2026-10-01 04:31 local. A precise wording: "merges whose committer date, in the committer's own time zone, is on or after this date". For a solo developer committing in one zone the two readings agree.

**Evidence:** `scripts/dev-cycle.sh:96-102`; `$LOGS/probe1.txt` (section "P2")

---

## Claim 3: "Default: the date in the newest docs/working/cycles/cycle-YYYY-MM-DD.md (only its file name is read), else 14 days ago. The digest says which."

**Location:** `scripts/dev-cycle.sh:11-12`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers record selection by file name (future-dated names ignored), the 14-day fallback and the source note; does not establish behaviour for a lexically valid but impossible name such as `cycle-2026-13-45.md`, which would be chosen and then rejected by the `--since must be a real YYYY-MM-DD date` check at `:88` (static reading, not run).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/dev-cycle.sh:75-79
for f in docs/working/cycles/cycle-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md; do
  [[ -f "$f" ]] || continue
  d="${f##*/cycle-}"; d="${d%.md}"
  [[ "$d" > "$last_record" && ! "$d" > "$TODAY" ]] && last_record="$d"  # ignore future-dated
done
```

No line opens the record. Tests 1 (`no cycle record found`) and 7 (`Window: since 2026-02-10 (from the last cycle record`) pass in E1.

**Evidence:** `scripts/dev-cycle.sh:74-87`; `test/scripts/dev-cycle.bats:114-121`; `$LOGS/bats-head.txt`

---

## Claim 4: "--sample  how many merges to sample for the spot-check (default 2)."

**Location:** `scripts/dev-cycle.sh:13`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the default and the count drawn; does not establish anything about sample quality.
**Legibility-target:** for-orchestrator-synthesis

`SAMPLE=2` at `scripts/dev-cycle.sh:34`; `shuf -n "$SAMPLE"` at `:165`. Test 9 (`--sample N lists N merges`) passes in E1.

**Evidence:** `scripts/dev-cycle.sh:34,165`; `$LOGS/bats-head.txt`

---

## Claim 5: "Every revisit trigger is printed in full every run; nothing carries forward."

**Location:** `scripts/dev-cycle.sh:15`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that no carry-forward code is left and that every record matching the glob prints its whole `## Revisit triggers` section (blank lines dropped) on every run; does not establish coverage of records outside `docs/decisions/[0-9][0-9][0-9]-*.md` (4-digit numbers), headings spelled other than `## Revisit triggers` exactly, or log-row text before the first "Revisit" in its cell.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/dev-cycle.sh:110-120
trig() { awk '/^## Revisit triggers/ { on = 1; next } on && /^## / { exit } on && NF { print }'; }
for f in docs/decisions/[0-9][0-9][0-9]-*.md; do
  [[ -f "$f" ]] || continue
  grep -q '^## Revisit triggers' "$f" || continue
  found=1
  echo
  d="$(git log -1 --format=%ad --date=short -- "$f")"
  # A newline in a file name would otherwise print a line of its own.
  echo "### ${f//$'\n'/ } (last committed on this branch: ${d:-never, uncommitted})"
  trig < "$f" | sed 's/^/> /'
done
```

The script only reads cycle records' file names (Claim 3). A case-insensitive search for `main at`, `carr`, `git show`, `cmp` and `git status` matches only this comment line (static grep). Test 3 passes on HEAD and fails on the baa46e3 script (E5). This repo holds no 4-digit records today (E13: `ls docs/decisions | grep -cE '^[0-9]{4,}-'` gives 0). Log rows print only the clause from "Revisit" to the end of the cell, which is a deliberate design (Claim 16).

**Evidence:** `scripts/dev-cycle.sh:107-133`; `test/scripts/dev-cycle.bats:65-78`; `$LOGS/bats-head.txt`, `$LOGS/headtests-vs-baa46e3.txt`, `$LOGS/probe7.txt`

---

## Claim 6: "Read-only: writes nothing to the repo (one temp file, removed on exit)."

**Location:** `scripts/dev-cycle.sh:17`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a full run on a clone of this repo, which has `questions.md`, so the temp-file path ran; does not establish removal when the script is killed by a signal, or that `$TMPDIR` lies outside the repo.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/dev-cycle.sh:139
  qs_err="$(mktemp)"; trap 'rm -f "$qs_err"' EXIT
```

`git hash-object -t tree /dev/null` at `:203` has no `-w`, so it computes the hash without writing an object. In E13 the digest exited 0 on a scratch clone and changed no file anywhere in the clone, `.git` included (`find . -newer stamp` gave 0). With `TMPDIR` set to an empty directory, that directory was still empty after the run.

**Evidence:** `scripts/dev-cycle.sh:139,203`; `$LOGS/probe7.txt`

---

## Claim 7: "Exit: 0 digest printed; 1 bad usage, not a git repo, no default branch or no perl; a failed step exits non-zero mid-digest."

**Location:** `scripts/dev-cycle.sh:18-19`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers no perl (exit 1), bad usage (exit 1) and a failing `git log` in section 1 (exit 128, after the header printed); does not establish where the error lands relative to stdout when both go to one file (it lands first; see Claim 8c's scope).
**Legibility-target:** for-orchestrator-synthesis

In E7 the PATH held bash, git and coreutils but no perl. The script printed `dev-cycle.sh needs perl (to scrub its output)` and exited 1. Test 16 (bad `--since`, unknown option) passes in E1. In E9 the root commit object was deleted, the full walk at `:99` failed, and the script exited 128 after printing `# Dev-cycle digest` and the Window line.

**Evidence:** `scripts/dev-cycle.sh:23,42,45,48,72,88`; `$LOGS/probe2.txt` (P7), `$LOGS/probe4.txt`, `$LOGS/bats-head.txt`

---

## Claim 8a: "drops C0 controls but TAB and LF, DEL, C1 controls (U+0080-009F), bidi controls (U+200E/F, U+202A-202E, U+2066-2069) and tag characters (U+E0000-E007F)."

**Location:** `scripts/dev-cycle.sh:24-26`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regex's byte ranges against UTF-8 encodings of the listed code points in perl's default byte mode; does not establish the drop when the caller's environment sets `PERL_UNICODE` (or similar `-C` defaults), or for raw 8-bit C1 bytes that are not UTF-8.
**Legibility-target:** for-author

```bash
# scripts/dev-cycle.sh:28-31
scrub() {
  LC_ALL=C perl -pe 's/\xC2[\x80-\x9F]|\xE2\x80[\x8E\x8F\xAA-\xAE]|\xE2\x81[\xA6-\xA9]|\xF3\xA0[\x80\x81][\x80-\xBF]//g; tr/\000-\010\013-\037\177//d'
}
exec > >(scrub) 2> >(scrub >&2)
```

Each byte pattern matches the UTF-8 encoding of its range. U+E0000-E007F is `F3 A0 80 80` to `F3 A0 81 BF`. Test 5 confirms U+009B, U+202E, U+E0041, ESC and CR are all removed (E1). Two exceptions follow:
- E8: with `PERL_UNICODE=SDA` in the caller's environment, perl decodes input as characters, the byte patterns stop matching, and `a\xc2\x9bb\xe2\x80\xaec` comes out unchanged (`a 302 233 b 342 200 256 c`). `LC_ALL=C` does not prevent this. The script neither clears `PERL_UNICODE` nor passes `-C0`.
- E7 (P3d): a raw `\x9B` byte (8-bit C1, invalid UTF-8) passes through. U+2028 and U+061C pass too, but the comment does not list them.

A precise wording: "drops these code points in their UTF-8 encoding, while perl runs in byte mode (no PERL_UNICODE)".

**Evidence:** `scripts/dev-cycle.sh:24-31`; `$LOGS/probe3.txt`, `$LOGS/probe2.txt` (P3d), `$LOGS/bats-head.txt`

---

## Claim 8b: "Byte patterns under LC_ALL=C, so invalid UTF-8 in a file name cannot make perl warn or die."

**Location:** `scripts/dev-cycle.sh:26-27`
**Type:** Behavioral / Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stated mechanism (that `LC_ALL=C` is what makes the patterns byte patterns and keeps invalid UTF-8 harmless); does not establish any failure under the default environment, where the conclusion holds.
**Legibility-target:** for-author

The mechanism is wrong. Perl's I/O stays byte-oriented under any `LC_ALL` unless `-C` or `PERL_UNICODE` asks otherwise. Its effects were measured, not assumed:
- Without `LC_ALL=C` but with an installed UTF-8 locale (`LC_ALL=C.UTF-8`), invalid input `bad\xff\xfe a\xc2\x9bb` gave no warning and was scrubbed to `bad 377 376 a b` (E7, P3b). Invalid UTF-8 does not make perl warn in the default mode, whatever the locale.
- With `PERL_UNICODE=SDA` and `LC_ALL=C` exactly as the scrub sets it, perl printed `Malformed UTF-8 character: \xff\xfe... in transliteration (tr///)` twice, and the C1 and RLO characters passed through (E8, `$LOGS/p3c-err.txt`). `LC_ALL=C` did not prevent the warning.

The setting does have one measured effect: it silences `perl: warning: Setting locale failed` when the inherited locale is not installed, as in this sandbox (E7, P3a). A reader who trusts the comment would think the scrub cannot be disturbed by the environment, and it can. The comment should name the real dependency: no `PERL_UNICODE`/`-C`.

Not added to the hallucination log: this is a mis-stated mechanism, not a fabricated symbol or option.

**Evidence:** `scripts/dev-cycle.sh:26-29`; `$LOGS/probe2.txt` (P3a, P3b), `$LOGS/probe3.txt`, `$LOGS/p3c-err.txt`

---

## Claim 8c: "The one scrub for everything printed, stdout and stderr"

**Location:** `scripts/dev-cycle.sh:24`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that every byte the script and its children write after `:31` passes the filter, and that the stdout captured through a pipe or file is complete; does not establish ordering between the two streams (with `2>&1` into a file, the error came before the digest header in 10 of 10 runs, E9). It also does not cover the constant perl-missing message at `:23`, which is printed before the `exec` and is not filtered.
**Legibility-target:** for-orchestrator-synthesis

`exec > >(scrub) 2> >(scrub >&2)` (`:31`) redirects both descriptors before option parsing (`:33`). Mutant M2, which drops the stderr half, fails test 5 and only test 5 (E11). In E7 (P4) the output file did not grow after the script exited in any of 20 runs, so no late writes were seen. Exit status passes through, because the parent's status is the script's own (Claim 7: 128).

**Evidence:** `scripts/dev-cycle.sh:23,31`; `$LOGS/mutations.txt` (M2), `$LOGS/probe2.txt` (P4), `$LOGS/probe4.txt`

---

## Claim 9: "DEV_CYCLE_TODAY exists only so tests can pin the date. File names are literal, not pathspecs."

**Location:** `scripts/dev-cycle.sh:50-52`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the single use of the variable and the exported literal-pathspec setting; does not establish that no user sets `DEV_CYCLE_TODAY` outside tests.
**Legibility-target:** for-orchestrator-synthesis

`TODAY="${DEV_CYCLE_TODAY:-$(date +%F)}"; export GIT_LITERAL_PATHSPECS=1` (`:52`) is the variable's only use (static grep). Tests 10 and 18 set it.

**Evidence:** `scripts/dev-cycle.sh:52`; `test/scripts/dev-cycle.bats:149,256`

---

## Claim 10: "Pass git only a hash for the default branch: origin/HEAD comes from the remote, and a branch named `--output=<path>` would reach `git log` as an option."

**Location:** `scripts/dev-cycle.sh:53-54`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every git call that names the default branch (they use `$MAIN_SHA`); does not establish anything about `$MAIN`, which only appears in echoed text.
**Legibility-target:** for-orchestrator-synthesis

`sha="$(git rev-parse --verify --quiet "refs/heads/$c^{commit}" ...)"` (`:62`) skips names starting with `-` (`:61`). Every later git call passes `"$MAIN_SHA"`. Test 15 passes (E1).

**Evidence:** `scripts/dev-cycle.sh:55-72,99,102,199,204`; `$LOGS/bats-head.txt`

---

## Claim 11: "# ignore future-dated"

**Location:** `scripts/dev-cycle.sh:78`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers record names dated after `$TODAY`; does not establish handling of impossible dates (Claim 3).
**Legibility-target:** for-orchestrator-synthesis

`! "$d" > "$TODAY"` excludes them. Test 7 uses `cycle-9999-12-31.md` and still gets 2026-02-10 (E1).

**Evidence:** `scripts/dev-cycle.sh:78`; `test/scripts/dev-cycle.bats:114-118`

---

## Claim 12: Window line: "Merges and commits: those on `$MAIN` at <sha> committed on or after $SINCE, filtered by date after a full walk. Triggers: all of them, from the working tree. Questions, roadmap, idea log: the working tree."

**Location:** `scripts/dev-cycle.sh:92`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers sections 1-6 and section 7's roadmap and idea-log inputs; does not establish a description of section 7's step 4b file lists, which the line omits.
**Legibility-target:** for-author

Sections 1, 4 and 6 read `merges_full`/`merges` (`:99-100`, `:165`, `:192`) and section 1 reads `commits` (`:102`), all walked in full and then date-filtered, as stated. Triggers, the roadmap and the idea log are read from working-tree files (`:111-131`, `:171-175`, `:219-232`). Section 7's step 4b lists come from somewhere the line does not name:

```bash
# scripts/dev-cycle.sh:199-204
oldest="$(git log "$MAIN_SHA" --first-parent --format='%cs %H' | awk -v s="$SINCE" '$1 >= s { h = $2 } END { print h }')"
if [[ -z "$oldest" ]]; then
  changed=""
else
  base="$(git rev-parse --verify --quiet "$oldest^1" || git hash-object -t tree /dev/null)"
  changed="$(git diff --name-only -z "$base" "$MAIN_SHA" -- skills workflows docs/decisions | tr '\0\n' '\n ')"
```

(excerpt ends :204; enclosing if-block continues to :205 — read)

That is a net tree diff from a base to `$MAIN_SHA`, not a set of commits filtered by date. It includes old-dated commits after the base and nets out changes that were reverted (Claim 22). The "committed on or after" wording also carries Claim 2's time-zone qualifier. A tighter line would add: "4b lists: the net diff on `$MAIN` from just before the oldest in-window commit."

**Evidence:** `scripts/dev-cycle.sh:92,99-102,111-131,171-175,199-232`

---

## Claim 13a: "`--since` stops at the first old-dated commit, so one such commit hid every merge after it."

**Location:** `scripts/dev-cycle.sh:96-97`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git's `--since` on the first-parent walk (the walk stops) and on a full walk (that path stops; side branches still list); "after it" is true in walk order, meaning merges older than that commit in history, not ones made chronologically later.
**Legibility-target:** for-orchestrator-synthesis

In E6 (P1) the chain was init, a, old (2020), b, merge. `git log --since=yesterday --first-parent` listed only `mergef` and `b`, and the full walk still had `old`, `a` and `init` behind them. The baa46e3 script, which used `--since`, printed `1 merge(s)` where the right count was 4 in test 4's fixture (E5).

**Evidence:** `scripts/dev-cycle.sh:96-102`; `$LOGS/probe1.txt` (P1), `$LOGS/headtests-vs-baa46e3.txt`

---

## Claim 13b: "%cs is the committer date as YYYY-MM-DD, which compares as a string."

**Location:** `scripts/dev-cycle.sh:98`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the format and the string-order equivalence for zero-padded ISO dates; does not establish which time zone the date is in (the committer's own, see Claim 2).
**Legibility-target:** for-orchestrator-synthesis

E6 printed `%cs` values such as `2026-10-01` and `2020-01-02`. In mawk `$1 >= s` compares two non-numeric strings as strings.

**Evidence:** `scripts/dev-cycle.sh:98-102`; `$LOGS/probe1.txt`

---

## Claim 14: "$n_merges merge(s) on `$MAIN`'s first-parent line; $commits commit(s) reachable from it, merged branches included."

**Location:** `scripts/dev-cycle.sh:104`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what is counted; does not establish the time-zone semantics of "in the window" (Claim 2).
**Legibility-target:** for-orchestrator-synthesis

Merges come from `--first-parent --merges` (`:99`). Commits come from `git log "$MAIN_SHA" --format=%cs` with no `--first-parent` (`:102`). Tests 1, 4 and 8 check the counts (E1).

**Evidence:** `scripts/dev-cycle.sh:99-104`; `$LOGS/bats-head.txt`

---

## Claim 15: "A newline in a file name would otherwise print a line of its own."

**Location:** `scripts/dev-cycle.sh:117`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `###` heading; does not establish other outlets of repo text. Static reading found them prefixed (`> `, `- `, `    - `) or flattened (`%s` subjects, `tr '\0\n' '\n '` at `:204`), with one exception: `questions.sh`'s stderr is printed raw inside a code fence (`:154`), so a ```` ``` ```` line in it would close the fence. The NUL/newline handling at `:204` is not tested for names with newlines (mutant M7 removes the whole `tr` and fails only because the NUL separators break).
**Legibility-target:** for-orchestrator-synthesis

`echo "### ${f//$'\n'/ } ..."` (`:118`). Mutant M1, which prints `$f` raw, fails test 6 only (E11). Test 6 also passes on baa46e3, because that version already had this replacement (E5). The test guards this line; it does not guard the removed carried list.

**Evidence:** `scripts/dev-cycle.sh:118,145,154,204,214`; `$LOGS/mutations.txt` (M1, M7), `$LOGS/headtests-vs-baa46e3.txt`

---

## Claim 16: "The whole clause to the cell's end; prefer a capitalised "Revisit" (the trigger sentence) over an earlier "revisit-trigger verdicts" mention."

**Location:** `scripts/dev-cycle.sh:126-127`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers rows matching `^\| [0-9]+ \|` that contain "revisit"; does not establish handling of an escaped `\|` inside a cell (the clause would stop there).
**Legibility-target:** for-orchestrator-synthesis

`grep -oE 'Revisit[^|]*'` with a case-insensitive fallback (`:128-129`). Test 2 checks a 500-character clause that follows an earlier lowercase "revisit-trigger verdicts" (E1).

**Evidence:** `scripts/dev-cycle.sh:121-132`; `test/scripts/dev-cycle.bats:51-63`

---

## Claim 17: "`open` prints "ID  route  slug" in columns of 2+ spaces; a route can contain one space ("you: judgment"), a slug can contain "trigger"."

**Location:** `scripts/dev-cycle.sh:141-142`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the parsing exercised by test 12; does not establish the column format of every `questions.sh` version (the `$HOME` fallback may be older).
**Legibility-target:** for-orchestrator-synthesis

`awk -F'  +' '$2 == "trigger" || $2 == "deferred"'` (`:143`). Test 12 (a slug containing "trigger", route `agent`) passes (E1).

**Evidence:** `scripts/dev-cycle.sh:140-150`; `test/scripts/dev-cycle.bats:167-195`

---

## Claim 18: "Seeded by a hash of the date: same day, same merges; different days usually differ. (The raw date seeded almost nothing: dates share their first bytes.)"

**Location:** `scripts/dev-cycle.sh:162-163`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers determinism and variation on 20 items; does not establish how often adjacent days collide on small merge counts.
**Legibility-target:** for-orchestrator-synthesis

In E12, `shuf -n 3 --random-source=<(yes "$d")` gave `19,2,16` for four raw dates, and the sha256-seeded runs gave `3,18,1` and `8,19,14`. Tests 9 and 10 pass (E1).

**Evidence:** `scripts/dev-cycle.sh:164-165`; `$LOGS/probe6.txt`

---

## Claim 19: "A merge whose diff against its first parent touches files but no docs/ path, *.md or README is a step 4 finding to check"

**Location:** `scripts/dev-cycle.sh:181-182`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the classification awk and rename-detected diffs; does not establish behaviour with `diff.renames=false` in user config. It also does not cover a missing first parent, which cannot happen because `--merges` lists only commits whose parents are both present (in a shallow clone the boundary commit has no parents and is not listed; E7 P5 ran clean).
**Legibility-target:** for-author

```bash
# scripts/dev-cycle.sh:186
  counts="$(git diff --name-only -z "$full^1" "$full" | awk -v RS='\0' 'NF { if ($0 ~ /^docs\// || $0 ~ /\.md$/ || $0 ~ /(^|\/)README/) d++; else c++ } END { print c + 0, d + 0 }')"
```

`(^|\/)README` matches any path component that *starts with* `README`, case-sensitively. It is not limited to a README file. E10 found three gaps:
- A merge adding `src_READMEfoo.sh` and `lib/README_gen.py` was not flagged, because the second file counted as a doc.
- A merge adding `readme.txt` was flagged as code-only.
- A merge renaming `docs/guide.md` to `tools/guide.txt` was flagged "(1 file(s), no doc change)", because rename detection lists only the new path.

A tighter wording: "...no path under docs/, ending .md, or whose basename starts with README (case-sensitive); renames count by their new path". Mutant M5 drops both the `.md` and README clauses and passes all 18 tests (E11). Test 17 exercises only `docs/`.

**Evidence:** `scripts/dev-cycle.sh:184-193`; `$LOGS/probe5.txt`, `$LOGS/mutations.txt` (M5), `$LOGS/probe2.txt` (P5)

---

## Claim 20: "(rule: undocumented is broken)"

**Location:** `scripts/dev-cycle.sh:182`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers a search of this branch, `feat/dev-cycle` and both CLAUDE.md files; does not establish the rule's source outside them (the "approval doc, 2026-10-01" named in db0e5ca was not found in any branch).
**Legibility-target:** for-orchestrator-synthesis

Paraphrased — no quote available because the claim covers absence of code: `git grep -i 'undocumented is broken'` over HEAD and `feat/dev-cycle` matches only this comment, and `/workspace/CLAUDE.md` and `~/.claude/CLAUDE.md` have no match. db0e5ca calls it "rule 4". Verifying it needs the approval doc or the rule list it comes from.

**Evidence:** `scripts/dev-cycle.sh:182`; `skills/dev-cycle/SKILL.md` (feat/dev-cycle 70cc7dc)

---

## Claim 21: "Base = the parent of the oldest first-parent commit in the window (the empty tree when that commit is the root)."

**Location:** `scripts/dev-cycle.sh:196-197`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which commit becomes the base, where "oldest" means oldest by position on the first-parent line among commits dated in the window; does not establish that the test suite would catch an off-by-one (mutant M6, base = `$oldest` itself, passes all 18 tests because test 18's fixture puts the root in the window).
**Legibility-target:** for-orchestrator-synthesis

`git log ... --first-parent --format='%cs %H' | awk ... '$1 >= s { h = $2 } END { print h }'` (`:199`) keeps the last match of the newest-first walk. `git rev-parse --verify --quiet "$oldest^1" || git hash-object -t tree /dev/null` (`:203`) falls back to the empty tree when there is no parent, and test 18 runs that fallback (`--since=2000-01-01`, E1).

**Evidence:** `scripts/dev-cycle.sh:199-205`; `$LOGS/mutations.txt` (M6), `$LOGS/bats-head.txt`

---

## Claim 22: "Old-dated commits after it are included: re-reading a file is cheap, missing one is not."

**Location:** `scripts/dev-cycle.sh:197-198`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the over-inclusion, plus the implied "never misses" for files whose net content changed in the window; does not establish that a file changed and then restored within the window is listed (it is not).
**Legibility-target:** for-author

The over-inclusion is real: the diff spans `$base..$MAIN_SHA` whatever the dates in between (`:204`). It is a net diff, though. In E10 two in-window merges first changed `skills/k/SKILL.md` and then restored it, and section 7 printed `Skill or workflow files changed on main in the window: 0`. A precise wording: "never misses a file whose content differs between the window's start and `$MAIN`".

**Evidence:** `scripts/dev-cycle.sh:196-207`; `$LOGS/probe5.txt`

---

## Claim 23: "Step 5 (brainstorm triggers; the thresholds are the skill's)" and "Step 5 heads each brainstorm "## Brainstorm YYYY-MM-DD"; ideas are "- " lines."

**Location:** `scripts/dev-cycle.sh:208,218,229`
**Type:** Architectural / Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the skill as it stands on `feat/dev-cycle` (70cc7dc); does not establish the content of the approved step 0 ("approval doc, 2026-10-01"), which was not found.
**Legibility-target:** for-orchestrator-synthesis

Paraphrased — no quote available because the claim covers absence of text in another branch's file. `skills/dev-cycle/SKILL.md` on `feat/dev-cycle` has sections `### 0` to `### 7` with no step 4b. Its step 5 (`:95-102`) has no thresholds and no `## Brainstorm` heading. Its roadmap template is `## Now / ## Next / ## Ideas / ## Done`, with no `In flight` section, so `Roadmap In flight` (`:220`) always prints 0 for a roadmap made from it. It names no `docs/working/idea-log.md`. db0e5ca's Notes say the skill "must write" this marker, so the comment describes a contract that does not exist yet. With today's skill, section 7 prints "No docs/working/idea-log.md". Verifying it needs the approval doc or the landed skill change.

**Evidence:** `scripts/dev-cycle.sh:208,218-241`; `skills/dev-cycle/SKILL.md:95-129` (feat/dev-cycle)

---

## Claim 24: "- Ideas seeded since: $seeded" (ideas seeded since the last brainstorm)

**Location:** `scripts/dev-cycle.sh:232,238`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers what the count measures; does not establish whether that matches the intended idea-log format, which is not specified anywhere found (Claim 23).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/dev-cycle.sh:232
  seeded="$(awk '/^## Brainstorm [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ { c = 0; next } /^- / { c++ } END { print c + 0 }' "$LOG")"
```

It counts every `- ` line after the last Brainstorm heading, including the bullets under that heading itself and bullets under any later heading. With no Brainstorm heading at all, it counts every bullet in the file. In E10, `## Brainstorm 2026-09-20` / `- c1` / `## Seeded later` / `- s1` / `- s2` gave `Ideas seeded since: 3`. If a brainstorm writes its own ideas under its heading, those count as "seeded since". Test 18's fixture assumes they do (`- one`, `- two` under the heading count as 2).

**Evidence:** `scripts/dev-cycle.sh:227-241`; `$LOGS/probe5.txt`; `test/scripts/dev-cycle.bats:255-260`

---

## Claim 25: "No {n} intervals in the awk regex: mawk, Debian's default awk, lacks them."

**Location:** `scripts/dev-cycle.sh:230`
**Type:** Configuration / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers mawk 1.3.4 20200120 (this Debian image) and every awk program in the script; does not establish behaviour of newer mawk builds, which may support intervals.
**Legibility-target:** for-orchestrator-synthesis

In E12 `echo 2026 | mawk '/^[0-9]{4}$/'` printed nothing, and `/usr/bin/awk -> /etc/alternatives/awk -> /usr/bin/mawk`. The script's `{n}` uses are at `:88` (bash `=~`), `:207` and `:231` (`grep -E`). No awk program has one (static grep of lines containing `awk`).

**Evidence:** `scripts/dev-cycle.sh:88,207,230-232`; `$LOGS/probe6.txt`

---

## Claim 26: "Each test builds a throwaway repo under $BATS_TEST_TMPDIR; this repo is untouched."

**Location:** `test/scripts/dev-cycle.bats:3-4`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every test body; does not establish isolation from a parallel run sharing `$BATS_TEST_TMPDIR` (bats makes it per-test).
**Legibility-target:** for-orchestrator-synthesis

`R="$BATS_TEST_TMPDIR/repo"; make_repo "$R" main; cd "$R"` (`:17-19`). Test 11 copies `scripts/` out to `$BATS_TEST_TMPDIR/tools` (`:158`) and writes nothing back. `HOME` is redirected (`:15`).

**Evidence:** `test/scripts/dev-cycle.bats:8-35,156-165`

---

## Claim 27: test name "prints all seven sections in a repo with no docs"

**Location:** `test/scripts/dev-cycle.bats:37`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the seven headings plus four fixed strings; does not establish section contents.
**Legibility-target:** for-orchestrator-synthesis

The test loops over seven headings (`:40-44`). It fails against the d9e4cb9 script, which has five sections (E5).

**Evidence:** `test/scripts/dev-cycle.bats:37-49`; `$LOGS/headtests-vs-d9e4cb9.txt`

---

## Claim 28: test name "after a cycle record, every trigger still prints in full and nothing is carried"

**Location:** `test/scripts/dev-cycle.bats:65`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an old committed record, an uncommitted record and past and future log rows after a same-window cycle record; does not check the exit status (no `[ "$status" -eq 0 ]`).
**Legibility-target:** for-orchestrator-synthesis

It passes on HEAD and fails on the baa46e3 script, which carried triggers forward (E5).

**Evidence:** `test/scripts/dev-cycle.bats:65-78`; `$LOGS/headtests-vs-baa46e3.txt`

---

## Claim 29a: test name "an old-dated commit on main does not hide the merges after it"

**Location:** `test/scripts/dev-cycle.bats:80`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the test fails on `--since` walking (E5 vs baa46e3; mutant M3 fails it alone); does not cover the wording, since the merges it protects are the ones *behind* (older than) the old-dated commit, not the one after it.
**Legibility-target:** for-author

The fixture puts features 1-3 before the 2020 commit and feature 4 after it. The baa46e3 script showed `merge: feature 4`, the one after it, and hid features 1-3 (E5: `1 merge(s)`). The guard works, but "after it" is right only in walk order. "...does not hide the merges behind it" would say what it tests.

**Evidence:** `test/scripts/dev-cycle.bats:80-91`; `$LOGS/headtests-vs-baa46e3.txt`, `$LOGS/mutations.txt` (M3)

---

## Claim 29b: "--since used to stop its walk at the old commit and report 0 merges."

**Location:** `test/scripts/dev-cycle.bats:81-82`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the pre-fix script printed for this test's fixture; does not establish R3's own scenario (no merge after the old commit), where 0 is right.
**Legibility-target:** for-author

On this fixture the baa46e3 script printed `1 merge(s) on 'main''s first-parent line; 2 commit(s)` (E5), not 0. A precise wording: "...and report only the merges made after it".

**Evidence:** `test/scripts/dev-cycle.bats:81-90`; `$LOGS/headtests-vs-baa46e3.txt`

---

## Claim 30: test name "the scrub strips C0, C1, bidi and tag characters from stdout and stderr"

**Location:** `test/scripts/dev-cycle.bats:93`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one code point per class (U+009B, U+202E, U+E0041, ESC, CR) in the default perl environment; does not establish the other members of each range, or behaviour under `PERL_UNICODE` (Claim 8a).
**Legibility-target:** for-orchestrator-synthesis

It fails on baa46e3 (E5). Mutant M2, with stderr unscrubbed, fails it alone (E11).

**Evidence:** `test/scripts/dev-cycle.bats:93-104`; `$LOGS/headtests-vs-baa46e3.txt`, `$LOGS/mutations.txt` (M2)

---

## Claim 31: test name "a newline in a decision record's name cannot print a line of its own"

**Location:** `test/scripts/dev-cycle.bats:106`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the section 2 heading; does not establish section 7's name handling, and the test cannot fail on the R1 code it was written after (it passes on baa46e3, whose heading already replaced LF and whose carried path needs an unchanged committed record).
**Legibility-target:** for-orchestrator-synthesis

Mutant M1 fails it (E11). It passes on baa46e3 (E5).

**Evidence:** `test/scripts/dev-cycle.bats:106-112`; `$LOGS/mutations.txt` (M1), `$LOGS/headtests-vs-baa46e3.txt`

---

## Claim 32: test name "--since counts from midnight, not from the current time of day"

**Location:** `test/scripts/dev-cycle.bats:123`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers midnight in the committer's (here the local) time zone; does not establish cross-zone behaviour (Claim 2).
**Legibility-target:** for-orchestrator-synthesis

Mutant M4 switches the commit count back to `git log --since="$SINCE"`. Git takes a bare date to mean the current time of day, and M4 fails this test alone (E11). So the test still checks what its name says.

**Evidence:** `test/scripts/dev-cycle.bats:123-129`; `$LOGS/mutations.txt` (M4)

---

## Claim 33: test name "flags a merge that changed code with no doc change, not one that did both"

**Location:** `test/scripts/dev-cycle.bats:239`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `docs/` path rule; does not establish the `*.md` and README rules (mutant M5 removes both and passes).
**Legibility-target:** for-orchestrator-synthesis

It passes on HEAD and fails on d9e4cb9, which has no section 6 (E5).

**Evidence:** `test/scripts/dev-cycle.bats:239-248`; `$LOGS/mutations.txt` (M5)

---

## Claim 34: test name "prints the step 4b and step 5 inputs"

**Location:** `test/scripts/dev-cycle.bats:250`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers presence and counts on a fixture whose window includes the root; does not establish the base choice (M6 survives), reverted-in-window files, or names with newlines.
**Legibility-target:** for-orchestrator-synthesis

It fails on d9e4cb9 (E5) and on mutant M7 (E11).

**Evidence:** `test/scripts/dev-cycle.bats:250-263`; `$LOGS/mutations.txt` (M6, M7)

---

## Claim 35: d9e4cb9: "Tests: carry-forward test replaced; new tests for R3, the scrub and a newline in a record name. 16/16 pass; shellcheck clean."

**Location:** commit d9e4cb9 message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count, the pass result and shellcheck at the d9e4cb9 tree; does not establish that the newline test guards the removed R1 code (Claim 31). This matches the prior hallucination pattern of wrong test tallies in commit messages; the tally checks out this time.
**Legibility-target:** for-orchestrator-synthesis

E4: `1..16`, all `ok`, exit 0; shellcheck exit 0, no output. baa46e3 had 13 tests.

**Evidence:** `$LOGS/bats-d9e4cb9.txt`, `$LOGS/sc-d9e4cb9.txt`, `$LOGS/bats-baa46e3.txt`

---

## Claim 36: d9e4cb9: "(rubric pass 3: R1, R2, A1, A3, A5, A6, C1, C3 lose their code)"

**Location:** commit d9e4cb9 message
**Type:** Reference / Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the code each row names (carried list, "Main at:" parsing and key, short-sha regex, base comparison, empty-section carry, carried names) is gone at db0e5ca; does not establish that no new defect replaced them (Claims 8b, 19, 22 are new).
**Legibility-target:** for-orchestrator-synthesis

Paraphrased — no quote available because the claim covers absence of code: a case-insensitive search of `scripts/dev-cycle.sh` for `main at|carr|git show|cmp|git status` matches only `:15`. The rubric rows at `code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:81-102` each describe code in that removed mechanism.

**Evidence:** `scripts/dev-cycle.sh:15`; `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:81-102`

---

## Claim 37: d9e4cb9: "A2: one scrub() filters stdout AND stderr, set up before option parsing: C0 (but TAB/LF), DEL, C1, bidi controls, tag characters."

**Location:** commit d9e4cb9 message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers placement and the default-environment drop list; does not establish the drop under `PERL_UNICODE` (fails, Claim 8a) or for raw 8-bit C1 bytes.
**Legibility-target:** for-author

The placement is correct (`:31` comes before `:33`). The drop list carries Claim 8a's environment qualifier. The commit's Notes give the real reason perl is needed ("tr can't match UTF-8 sequences"), and that reason is correct.

**Evidence:** `scripts/dev-cycle.sh:23-33`; `$LOGS/probe3.txt`

---

## Claim 38: d9e4cb9: "A4, C2: the Window line and --help say what the window is and that nothing carries forward."

**Location:** commit d9e4cb9 message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Window line and `--help` (lines 2-19); does not establish that the Window line covers section 7's 4b lists (Claim 12).
**Legibility-target:** for-author

`--help` prints `:15` ("nothing carries forward"). The Window line says "Triggers: all of them". It already listed "idea log" at d9e4cb9, before any idea log was read (db0e5ca added that read). It names the time-zone-dependent "committed on or after" (Claim 2), and it does not describe section 7's net-diff lists.

**Evidence:** `scripts/dev-cycle.sh:41,92`; `git show d9e4cb9:scripts/dev-cycle.sh` line 92

---

## Claim 39: db0e5ca: "All stateless: nothing here reads a cycle record. 18/18 tests pass; shellcheck clean. Script is 241 lines."

**Location:** commit db0e5ca message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the new sections 6-7 and the counts at db0e5ca; "reads a cycle record" excludes the window default, which reads a record's file name (Claim 3).
**Legibility-target:** for-orchestrator-synthesis

E1 gave `1..18`, all ok, exit 0. E2 gave shellcheck exit 0. E3 counted `241 scripts/dev-cycle.sh`. Sections 6 and 7 (`:180-241`) never open `docs/working/cycles/`.

**Evidence:** `$LOGS/bats-head.txt`, `$LOGS/shellcheck-head.txt`, `$LOGS/wc-head.txt`; `scripts/dev-cycle.sh:180-241`

---

## Claim 40: db0e5ca: "the 4b window base is the parent of the oldest in-window first-parent commit (over-includes, never misses)"; also "the model version is compared with the last record by the skill, not parsed here. ... Thresholds stay in the skill."

**Location:** commit db0e5ca message
**Type:** Behavioral / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the base and over-inclusion (true) and "never misses" (false for files restored within the window); the skill-side halves (model-version compare, thresholds) are Unverifiable for the reason given in Claim 23 and are not what carries this verdict.
**Legibility-target:** for-author

The verdict comes from "never misses": E10 shows a skill file changed and then restored in the window is not listed (Claim 22). The skill on `feat/dev-cycle` has no step 4b, no model-version comparison and no step 5 thresholds (Claim 23).

**Evidence:** `scripts/dev-cycle.sh:196-218`; `$LOGS/probe5.txt`; `skills/dev-cycle/SKILL.md:95-102` (feat/dev-cycle)

---

## Claims Requiring Attention

### Incorrect
- **Claim 8b** (`scripts/dev-cycle.sh:26-27`): `LC_ALL=C` is not what keeps the scrub byte-oriented. Perl is byte-mode by default, and `PERL_UNICODE` in the caller's environment overrides `LC_ALL=C`: perl then warns on invalid UTF-8, and C1 and bidi characters pass unscrubbed. `LC_ALL=C` only silences locale-setup warnings. Name the real dependency, or pin it (e.g. `PERL_UNICODE=` / `-C0`).

### Mostly Accurate
- **Claim 2** (`scripts/dev-cycle.sh:10`): "on or after this date" means the date in each committer's own time zone (`%cs`), not local midnight as before d9e4cb9.
- **Claim 8a** (`scripts/dev-cycle.sh:24-26`): the drop list holds only in perl byte mode; raw 8-bit C1 bytes pass.
- **Claim 12** (`scripts/dev-cycle.sh:92`): the Window line does not describe section 7's net-diff 4b lists.
- **Claim 19** (`scripts/dev-cycle.sh:181-182`): "README" means any path component that starts with `README`, case-sensitively (`lib/README_gen.py` counts as a doc, `readme.txt` does not). A doc renamed out of `docs/` is flagged "no doc change". The `.md`/README rules are untested (M5 survives).
- **Claim 22** (`scripts/dev-cycle.sh:197-198`): a net diff misses a file changed and then restored inside the window.
- **Claim 29a** (`test/scripts/dev-cycle.bats:80`): the protected merges are the ones *behind* the old-dated commit, not after it.
- **Claim 29b** (`test/scripts/dev-cycle.bats:81-82`): on this fixture the old code reported 1 merge, not 0.
- **Claim 37** (d9e4cb9 message): the scrub drop list carries Claim 8a's qualifier.
- **Claim 38** (d9e4cb9 message): the Window line omits section 7's lists, and it named "idea log" before one was read.
- **Claim 40** (db0e5ca message): "never misses" is false for files restored within the window.

### Unverifiable
- **Claim 20** (`scripts/dev-cycle.sh:182`): "rule: undocumented is broken" is found nowhere in the repo or the CLAUDE.md files; needs the approval doc.
- **Claim 23** (`scripts/dev-cycle.sh:208,218,229`): step 4b, step 5 thresholds, `## Brainstorm YYYY-MM-DD` and `In flight` are absent from the skill on `feat/dev-cycle` (70cc7dc); needs the approval doc or the landed skill change.
- **Claim 24** (`scripts/dev-cycle.sh:232,238`): "Ideas seeded since" counts the last brainstorm's own bullets; whether that is intended depends on an unwritten idea-log format.

---

## Goal-Alignment Note

**Success criterion (verbatim from the brief):** "a markdown report saved at the path your role instructions give, structured per your skill file."

**Answered:** This report answers the criterion. It is saved at `docs/reviews/code-fact-check-report-r2-digest-final4.md` with `Commit: db0e5ca` first, and it covers 44 claims, each with the seven mandatory fields plus Legibility-target. All ten "claims that particularly need checking" were checked. The cut removed the code behind R1, R2, A1, A3, A5, A6, C1 and C3 (Claim 36). R3 is fixed and guarded (Claims 13a, 29a; M3). A2's stderr gap is closed and guarded (Claim 8c; M2). The only Incorrect is a new comment about the scrub's mechanism (Claim 8b), and it has a real environment-dependent consequence. Every new test fails on the code it guards against, except test 6. Test 6 guards the heading replacement but passes on baa46e3, so it does not prove the R1 removal (Claim 31). Two mutants survive: M5 (section 6's `.md`/README rules) and M6 (section 7's base off-by-one).

**Out of scope:** code quality and design of sections 6-7 beyond whether the comments match the code. The rubric's C6 ordering issue still reproduces (with `2>&1`, the error lands before the digest header, E9) but no comment claims an order, so it appears only as a Scope residue on Claim 8c. The hallucination-pattern log was not updated: the brief forbids writes beyond this report, and no Incorrect verdict is a fabricated symbol.

**Escalate:** Claim 23. Section 7's step 4b and step 5 inputs (the `## Brainstorm YYYY-MM-DD` idea log, `In flight`, step 4b, step 5 thresholds) depend on a skill contract that is not on `feat/dev-cycle` yet. db0e5ca's own Notes say the skill "must write" it. Merging this branch before that skill change lands means section 7 reports "No idea log" and "In flight: 0" for any roadmap built from today's template.

**Questions / Decisions:** Should the scrub pin perl's I/O mode (clear `PERL_UNICODE` or pass `-C0`), or should the comment just name the dependency? That decision is for the author and does not block this fact-check.
