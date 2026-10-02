# Code Fact-Check Report

**Commit:** 28c6178 (unit A; unit B = c079e8c)
**Replication:** k=3
**Repository:** claude-workflows — unit A worktree `/workspace/.claude/wt-digest` (feat/dev-cycle-digest @ 28c6178), unit B worktree `/workspace/.claude/wt-devcycle` (feat/dev-cycle @ c079e8c)
**Scope:** Final pass 5, partial (the final-pass-4 fixes only). A: `git diff db0e5ca..28c6178 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` plus commit messages 26b7590 and 28c6178. B: `git diff 6ee33e3..c079e8c -- skills/dev-cycle/SKILL.md docs/decisions/log.md docs/roadmap.md guides/skill-creation.md global-instructions/CLAUDE.md docs/dev-cycle-sources.md` plus commit message c079e8c. The A↔B contract (digest sections, formats, paths) is in scope. Merged from replicates r1, r2 and r3 (`code-fact-check-report-r{1,2,3}-digest-final5.md`).
**Checked:** 2026-10-01
**Total claims checked:** 96
**Summary:** 72 verified, 16 mostly accurate, 1 stale, 6 incorrect, 1 unverifiable

Merge provenance: mechanical collation of three replicate reports under the most-severe-wins rule (`skills/code-review/SKILL.md`, "Merging replicate verdicts"). No claim or evidence was added by the merge. Replicate claim counts: r1 47, r2 80, r3 47 (44 numbered, 3 split into a/b). Clusters are emitted at the finest granularity any replicate used; a replicate that verdicted only a compound claim is recorded on each sub-claim row as `(compound)`. Where a compound replicate's own text gives an explicit per-atom verdict (r1 Claim 42's Scope; r3 Claims 28 and 44), that atom verdict is recorded and marked `(atom of compound)`. Replicate scratch output: `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc5-r1/` (`$S1/`), `…/fc5-r2/` (`$S2/`), `…/fc5-r3/` (`$S3/`). Replicate execution windows: r1 2026-10-01 20:09–20:16 -07:00; r2 20:11–20:17 -07:00; r3 2026-10-02T03:09Z–03:16Z. Hallucination-pattern log: all three replicates read it and found no qualifying new pattern.

---

## Claim 1: "--since   start of the cycle window: commits whose committer date, in the committer's own time zone (git's %cs), is on or after this date."

**Location:** `scripts/dev-cycle.sh:10-11`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the date and zone semantics of the filter used by sections 1 and 6 and by section 7's per-commit date lines. It does not cover `%ad` in the printed merge list, which is the author date.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish how the default (`14 days ago`) is computed: `date -d \"$TODAY - 14 days\"` uses the local zone" · r1+r3: author date (`%ad`) is not what the filter uses; r3: "no code uses" author-date behaviour

Filters: `merges_full=… --format='%cs %H %h %ad %s' --date=short | awk -v s="$SINCE" '$1 >= s'` (`:117`), `commits=… --format=%cs | awk … '$1 >= s'` (`:120`), and `@%cs` with `on = (substr($0, 2) >= s)` (`:221-222`). r1 probe P2: a commit with `GIT_COMMITTER_DATE="2026-01-01T23:30:00 -1000"` (2026-01-02 UTC) gives `%cs` `2026-01-01`; excluded at `--since=2026-01-02`, included at `--since=2026-01-01`. r2 (E12) and r3 (`$S3/tz-probe.log`) reproduced the same under `TZ=UTC`.

**Evidence:** `scripts/dev-cycle.sh:117,120,221-222`, `$S1/probes-A.log`, `$S2/cs-zone.txt`, `$S3/tz-probe.log`

---

## Claim 2: "Default: the date in the newest docs/working/cycles/cycle-YYYY-MM-DD.md (only its file name is read), else 14 days ago. The digest says which."

**Location:** `scripts/dev-cycle.sh:12-13`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the selection, the name-only read and the source note. It does not establish behavior for future-dated records, which are ignored (`:96`) without being mentioned in the help text.
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r1: future-dated records are ignored (`:96`) "without being mentioned in the help text"

The loop at `:93-97` takes the newest `cycle-YYYY-MM-DD.md` name not after `$TODAY` (`[[ "$d" > "$last_record" && ! "$d" > "$TODAY" ]] && last_record="$d"  # ignore future-dated`). Test 9 ("the window defaults to the newest cycle record's date and says so") passes.

**Evidence:** `scripts/dev-cycle.sh:93-105`, `$S1/bats-A.log`

---

## Claim 3: Help covers header lines 2–20; "Exit: 0 digest printed; 1 bad usage, not a git repo, no default branch or no perl"

**Location:** `scripts/dev-cycle.sh:19-20`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers `--help` output range and exit codes for help, a bad `--sample`, a bad `--since` and a non-repo, all through the re-exec. It does not cover the no-perl path (perl is present in the sandbox) or the no-default-branch path (test 16 covers master only).
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r1: no-perl and no-default-branch paths not exercised

`-h|--help) sed -n '2,20p' "$0"` (`:54`). Help ends at line 20 and exits 0. A bad sample gives `--sample must be a non-negative integer`, exit 1; a non-repo gives `Not inside a git repository`, exit 1; a bad `--since` exits 1 (tests 7 and 18).

**Evidence:** `scripts/dev-cycle.sh:19-20,48-58,61,106`, `$S1/probes-A.log`, `$S1/probes-A-exit.log`

---

## Claim 4: "drops C0 controls but TAB and LF, DEL, C1 controls (U+0080-009F), bidi controls (U+200E/F, U+202A-202E, U+2066-2069) and tag characters (U+E0000-E007F)"

**Location:** `scripts/dev-cycle.sh:25-27`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the byte patterns for exactly the listed ranges, with PERLIO, PERL_UNICODE and PERL5OPT unset. Does not establish that the list is every bidi control (U+061C ARABIC LETTER MARK passes; see Claim 7), and does not cover behaviour under `PERLIO=:utf8` (Claim 5).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: "does not establish that the list is every bidi control: Unicode's Bidi_Control set also contains U+061C (ARABIC LETTER MARK), which passes unchanged" · r1+r3: holds under the default environment only, not under `PERLIO` (Claim 5)

The code is `tr/\000-\010\013-\037\177//d; 1 while s/\xC2[\x80-\x9F]|\xE2\x80[\x8E\x8F\xAA-\xAE]|\xE2\x81[\xA6-\xA9]|\xF3\xA0[\x80\x81][\x80-\xBF]//g` (`:34`), the UTF-8 encodings of the listed ranges. Probes removed C1 CSI, LRM, PDI, FSI, tag U+E007F, ESC, CR and DEL, and kept TAB.

**Evidence:** `scripts/dev-cycle.sh:34`, `$S1/scrubprobe.log`, `$S2/probe3.out`, `$S3/probe-scrub.log`

---

## Claim 5: "Perl is pinned to bytes (-C0, and PERL_UNICODE / PERL5OPT removed: either could turn on UTF-8 decoding and switch the byte patterns off)."

**Location:** `scripts/dev-cycle.sh:27-29`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers whether the environment can still switch perl's std handles to UTF-8. It does not cover whether that environment is a realistic attacker position (the variable is the operator's own).
**Replicate verdicts:** r1=Incorrect · r2=Verified (compound) · r3=Incorrect
**Replicate annotations:** r3: "Does not establish whether other perl variables (e.g. PERL5LIB) matter" · r3: "`PERLIO=:encoding(UTF-8)` did not bypass the scrub in this probe"; the nested cases left a reassembled `c2 9b` under `PERLIO=:utf8`; "the same failure class as final pass 4's A1" · r2 (compound with Claim 6): with `PERL_UNICODE=SDA`, `PERL5OPT=-CSD` and both together the output was `61 62 63 0a` — r2 did not probe `PERLIO` · r1+r3: fix is `-u PERLIO` (r3: also add it to test 5's env loop) or reword the comment

`PERLIO` is a third environment variable that switches perl's handles to UTF-8, and the scrub leaves it in place: `env -u PERL_UNICODE -u PERL5OPT LC_ALL=C perl -C0 -pe '…'` (`:34`). With `PERLIO=:utf8`, the scrub alone passes `c2 9b` (CSI) and `e2 80 ae` (RLO) unchanged (`$S1/perlio.log`: ` 61 c2 9b 62 e2 80 ae 63 0a`). End to end, a revisit trigger `if a\xc2\x9bb\xe2\x80\xaec.` prints as `a 302 233 b 342 200 256 c` (`$S1/perlio-e2e.log`); the default environment prints `abc`. `-C0` does not override `PERLIO`'s default layers. r3 reproduced end to end (`20 61 c2 9b 62 e2 80 ae 63 64`, exit 0).

**Evidence:** `scripts/dev-cycle.sh:27-34`, `$S1/perlio.log`, `$S1/perlio-e2e.log`, `$S3/probe-scrub.log`, `$S3/e2e-perlio.log`

---

## Claim 6: "C0 goes first and the substitution repeats until nothing changes, so neither a control byte inside a sequence nor a nested sequence can reassemble one."

**Location:** `scripts/dev-cycle.sh:29-31`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers reassembly within one line for the listed C1, bidi and tag sequences, including a C0 byte between nested layers. It does not cover sequences split across lines (perl `-p` works per line; the result is `c2 0a 9b`, which is two invalid fragments around an LF and not a reassembled sequence) or the PERLIO case (Claim 5).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1+r2+r3: an LF-split sequence (`c2 0a 9b`) is not reassembled but leaves a lone `9B` (Claim 7's residue) · r1+r3: not under `PERLIO=:utf8` (Claim 5)

Probes all give `61 62`: split (`a\xc2\x01\x9bb`), nested (`a\xc2\xc2\x9b\x9bb`), C0 between layers, C0 inside an inner bidi layer, nested tags; r2 adds DEL split, C1 inside a bidi sequence and triple nesting. The loop terminates because each successful `s///g` shortens the line. Test 5 covers split, nested and env cases and fails on db0e5ca.

**Evidence:** `scripts/dev-cycle.sh:34`, `$S1/scrubprobe.log`, `$S1/bats-on-db0e5ca.log`, `$S2/probe3.out`, `$S3/probe-scrub.log`

---

## Claim 7: "Not covered: a lone 0x9B byte (invalid UTF-8 …) and zero-width characters (cannot start a line)." — completeness of the list

**Location:** `scripts/dev-cycle.sh:31-32`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers whether the "Not covered" list is complete for byte forms that pass the scrub. It does not establish what any terminal does with them (Claim 8).
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate (compound) · r3=Mostly accurate (compound)
**Replicate annotations:** r1: overlong encodings `c0 9b`, `e0 82 9b` pass; U+061C (`d8 9c`) passes; U+2028 (`e2 80 a8`) passes · r2: "every lone C1 byte passes, not only 0x9B" (`lone90-dcs: 61 90 62`, `lone9d-osc: 61 9d 30 3b 78 9c 62`); U+2029 (`e2 80 a9`) passes · r3: lone 9D (8-bit OSC) and overlong `c0 9b` pass; ALM "is a valid bidi control" unlike the invalid-UTF-8 class · r2+r3: suggested wording "Not covered: lone [or overlong] bytes 0x80-0x9F (invalid UTF-8), U+061C, [U+2028/2029] and zero-width characters"

Both named items pass (lone `9b`: `61 9b 62`), so they are correctly listed, but the list leaves out other forms that also pass: overlong encodings of C1/C0 (`c0 9b`, `e0 82 9b`), U+061C ARABIC LETTER MARK (`d8 9c`, a Unicode Bidi_Control), and U+2028 LINE SEPARATOR (`e2 80 a8`). A precise version would add "overlong forms (invalid UTF-8, like 0x9B), U+061C and U+2028/9".

**Evidence:** `scripts/dev-cycle.sh:31-34`, `$S1/scrubprobe.log`, `$S2/probe3.out`, `$S3/probe-scrub.log`

---

## Claim 8: "a lone 0x9B byte (invalid UTF-8, inert on a UTF-8 terminal)" — terminal-behaviour half

**Location:** `scripts/dev-cycle.sh:31-32`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what passes the scrub unchanged. It does not establish how any particular terminal renders these bytes.
**Replicate verdicts:** r1=Unverifiable · r2=Mostly accurate (compound) · r3=Mostly accurate (compound)
**Replicate annotations:** r1 (the only replicate that verdicted this atom on its own): "Whether 0x9B is inert depends on the terminal emulator's decoder mode (for example, a terminal not in UTF-8 mode treats 0x9B as 8-bit CSI) … Verifying it needs runs on the target terminals (xterm, VS Code, Windows Terminal) in UTF-8 mode." · r3: "Does not establish terminal behaviour, which was not tested on a real emulator." · Merge note: the Mostly accurate verdict comes from r2/r3's compound verdict on the whole sentence (driven by list incompleteness, Claim 7), not from a terminal test

Carried from r2 (compound): the listed items do pass, but the list is incomplete; every lone C1 byte passes, not only 0x9B (0x90 DCS, 0x9D OSC), and U+061C, U+2028 and U+2029 also pass. "Invalid UTF-8" is true by definition (r1: 0x9B is a continuation byte); "inert on a UTF-8 terminal" was not tested by any replicate.

**Evidence:** `scripts/dev-cycle.sh:31-34`, `$S2/probe3.out`

---

## Claim 9: "Run the body as a child whose stdout and stderr each pass through scrub as members of one pipeline, so the shell waits for both filters before exiting: a redirected digest is complete when the script returns."

**Location:** `scripts/dev-cycle.sh:36-38`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the wait structure and completeness of a redirected digest. It does not establish that test 7 discriminates: the commit's Notes say test 7 also passes on db0e5ca, and I confirmed it does.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: test 7 also passes on db0e5ca, so it does not discriminate the fix · r2: "does not establish ordering *between* the two streams (Claim 32) or behavior when the reader closes early" · r3: "Does not establish behaviour when the outer process is killed by a signal"

`{ DEV_CYCLE_SCRUBBED=1 bash "${BASH_SOURCE[0]}" "$@" 2>&1 1>&3 3>&- | scrub >&2; } 3>&1 | scrub` then `exit "${PIPESTATUS[0]}"` (`:41-44`). Both scrubs are foreground pipeline members and bash waits for every member. r1: 30 redirected runs, `incomplete=0/30`; r2: 3 MB per stream, `out=3029999 err=3029999` on 3 runs; r3: 40 runs, `incomplete=0`. Running from a subdirectory with a relative path works.

**Evidence:** `scripts/dev-cycle.sh:36-44`, `$S1/probes-A.log`, `$S2/big-harness.out`, `$S3/reexec-probes.log`

---

## Claim 10: "stdout goes to fd 3, stderr takes the inner pipe, then fd 3 takes the outer one."

**Location:** `scripts/dev-cycle.sh:38-39`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the redirection order on `:42`. Does not establish the fd set of the inner `scrub`, which inherits fd 3 and is not closed by `3>&-`.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r2: "It does not establish the order in which bash applies the redirections; `3>&1` on the group is applied before the inner ones, so the comment's 'then' is narrative." · r2+r3: the inner scrub inherits fd 3 and holds the outer pipe open (harmless; no hang observed) · r1: final routing verified (stdout to stdout, stderr to stderr, both scrubbed; test 5 checks `Unknown option: --bogus` reaches `$stderr` scrubbed)

The final wiring is right: the body's stdout reaches the outer `| scrub`, and its stderr reaches `| scrub >&2`. The order is reversed, though. `3>&1` on the brace group (`} 3>&1 | scrub`, `:42`) is applied when the group starts, before the child's own `2>&1 1>&3 3>&-`. So fd 3 takes the outer pipe first, not "then". The inner `scrub >&2` also inherits fd 3 and holds the outer pipe open until it exits; this causes no hang in practice (Claim 9 runs).

**Evidence:** `scripts/dev-cycle.sh:42`

---

## Claim 11: "Exit status: the body's (pipefail; scrub itself does not fail)."

**Location:** `scripts/dev-cycle.sh:39-40`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers fd routing and exit status for the 0 and 1 paths. It does not cover exits under SIGPIPE: `dev-cycle.sh | head -1` exits 141 in all 6 runs, and it cannot be told apart whether that status is the body's or the outer scrub's.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: a downstream reader closing early (`| head`) gives exit 141; r3: "under pipefail that status would then be the scrub's" · r1+r2+r3: under `set -e` the script exits at `:42` with the pipefail status before reaching `:43`, same value · r3: under `PERLIO=:utf8` perl only warns and the digest still exits 0

`set -euo pipefail` (`:22`). Exit codes 0 and 1 propagate through the re-exec (help, bad sample, bogus option, non-repo, bad `--since`). r2: a forced `shuf` failure exited 7 after 4 section headings; a body `exit 5` gave script exit 5.

**Evidence:** `scripts/dev-cycle.sh:22,41-44`, `$S1/bats-A.log`, `$S1/probes-A-exit.log`, `$S2/probe1.out`, `$S2/order-harness.out`, `$S3/reexec-probes.log`

---

## Claim 12: "DEV_CYCLE_SCRUBBED marks the child." (with commit 26b7590's Note: "an environment that sets it skips the scrub; a repo cannot")

**Location:** `scripts/dev-cycle.sh:40-41`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the skip and the claim that repo content cannot set the variable. It does not establish that the variable stays unset in the grandchild environments (it is exported to questions.sh, which ignores it).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: exported to questions.sh, which ignores it · r2: "does not establish anything about environments that export it by accident" · r3: "Does not establish that no tool a user runs (e.g. direnv) sets it from repo content"

Guard: `if [[ -z "${DEV_CYCLE_SCRUBBED:-}" ]]; then` (`:41`). With `DEV_CYCLE_SCRUBBED=1`, output carried raw `c2 9b` (r1), an ESC (r2), and `c2 9b`, `e2 80 ae`, `1b` (r3). The script reads no repo-controlled source of environment variables.

**Evidence:** `scripts/dev-cycle.sh:41-42`, `$S1/probes-A.log`, `$S2/probe1.out`, `$S3/reexec-probes.log`

---

## Claim 13: "A regular file whose real path stays inside the repo: a committed symlink (to the file or a parent directory) must not make the digest print text from outside the checkout."

**Location:** `scripts/dev-cycle.sh:64-67`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every content-read site: decision records `:130`, log.md `:139`, questions.md `:156` (questions.sh `open` reads only `$LIVE`, the same path), roadmap `:189` and `:236`, and the idea log `:245`. Does not cover the cycle-record glob `:93-97`, which reads file names only.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r1+r2: does not cover `QUESTIONS_LIVE`, an operator environment override that `questions.sh` honours (`scripts/questions.sh:85`) after the gate, or TOCTOU between the check and the read · r2: when a file is skipped, the digest prints "No docs/roadmap.md yet — create it this cycle" even though a symlink exists there · r1+r2+r3: an in-repo symlink target is still read (correctly)

`inrepo() { local r; [[ -f "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" && [[ "$r" == "$ROOT_REAL"/* ]]; }` (`:67`) guards every site that reads file content; record text from outside was not printed (all three replicates). However, with `docs/working` symlinked outside, the window line printed `since 2020-05-05 (from the last cycle record, docs/working/cycles/cycle-2020-05-05.md)`, a file name that exists only outside the checkout. The glob uses `[[ -f "$f" ]]` (`:94`), not `inrepo`. The leaked text is limited to a `YYYY-MM-DD` pattern, but it moves the window. Precise version: "...must not print file *content* from outside the checkout; cycle-record names are still read through a symlinked parent."

**Evidence:** `scripts/dev-cycle.sh:67`, `:93-97`, `:130`, `:139`, `:156`, `:189`, `:236`, `:245`, `scripts/questions.sh:408-413`, `$S3/inrepo-sec7-probes.log`

---

## Claim 14: Window line — "Merges, commits and section 7's changed files: those on `$MAIN` at … whose committer date (in the committer's time zone) is on or after $SINCE, filtered after a full walk. Triggers: all of them, from the working tree. Questions, roadmap, idea log: the working tree."

**Location:** `scripts/dev-cycle.sh:110`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers sections 1, 4 and 6 (which share `merges_full`) and section 7's per-commit date filter. It does not establish the commit-population difference: section 1 counts all reachable commits, while section 7 lists files from first-parent commits only. The line says "on `$MAIN`" for both.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2: "commits" (`:120`) counts every commit reachable from `$MAIN` ("merged branches included"), while section 7 is first-parent only

Section 6 iterates `done <<< "$merges_full"` (`:208`); section 7 filters on `/^@/ { on = (substr($0, 2) >= s)` (`:222`). Neither walk uses `--since`. Zone semantics as in Claim 1.

**Evidence:** `scripts/dev-cycle.sh:110,117-120,202-208,221-222`, `$S1/probes-A.log`, `$S2/digest-wt-devcycle.md`

---

## Claim 15: "`--since` stops at the first old-dated commit, so one such commit hid every merge behind it."

**Location:** `scripts/dev-cycle.sh:114-115`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers git 2.39.5's non-limited `--since` walk on test 4's exact history. It does not cover other git versions.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: "does not cover a non-monotonic date that appears only on a side branch" · r3: "Does not establish git's internal slop heuristics for other walk shapes"

Rebuilding test 4's history, `git log main --first-parent --merges --since=<yesterday>` printed only `merge: feature 4`; the full walk plus filter printed all four merges (all three replicates).

**Evidence:** `scripts/dev-cycle.sh:114-117`, `$S1/test4-oldbehaviour.log`, `$S2/probe5.out`, `$S3/since-probe.log`

---

## Claim 16: "A merge whose diff against its first parent touches files but no doc (a path under docs/, a *.md file, or a file named README or README.*, any case): step 4 checks each one (rule: undocumented is broken). Listed up to 30."

**Location:** `scripts/dev-cycle.sh:199-201`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the README rule (any case), the cap and the `rest` reuse. The "any case" applies to README only: `docs/` and `*.md` are case-sensitive, so `NOTES.MD` and `Docs/x.sh` count as code, and so does `readme.d/x.sh` (basename only).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: "any case" attaches to README only; `docs/` and `.md` are case-sensitive (`NOTES.MD` counts as code) · r2: with the oldest merge unflagged the script exited 0, so the trailing `&&` (`:207`) does not trip `set -e` · r3: "The cap's '… N more' line was read, not executed" (r1 and r2 executed it)

`b = tolower($0); sub(/.*\//, "", b); if ($0 ~ /^docs\// || $0 ~ /\.md$/ || b == "readme" || index(b, "readme.") == 1) d++; else c++` (`:205`). r1 P9: 33 code-only merges printed 30 lines plus `… 3 more`; r2 E5: 34 merges, `… 4 more`. P10 flagged `upmd`, `docsUP`, `readmedir`, not `README` or `sub/Readme.rst`. Test 19 passes, and fails on db0e5ca.

**Evidence:** `scripts/dev-cycle.sh:198-214`, `$S1/probes-A2.log`, `$S2/probe2.out`, `$S3/bats-A.log`

---

## Claim 17: section 6 reuses `merges_full`'s `rest` field for the listed line (commit 26b7590: "section 6 reuses merges_full")

**Location:** `scripts/dev-cycle.sh:203-207`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the format matches the earlier per-merge `git log -1 --format='%h %ad %s' --date=short`. It does not establish that leading or trailing whitespace in a subject is kept, since `read` without `IFS=` trims it.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: `read` without `IFS=` trims leading/trailing whitespace in a subject

`merges_full` uses `--format='%cs %H %h %ad %s' --date=short` (`:117`), and `while read -r _ full rest` (`:203`) leaves `rest` = `%h %ad %s`. Output example: `- 07074d5 2026-10-01 merge f2 (1 file(s), no doc change)`.

**Evidence:** `scripts/dev-cycle.sh:117`, `:203-207`, `$S2/probe1.out`, `$S1/probes-A2.log`

---

## Claim 18: "Every file any first-parent commit in the window touched (a merge counts its diff against its first parent), not a net diff: a change reverted inside the window still counts."

**Location:** `scripts/dev-cycle.sh:217-219`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what reaches `changed` (`:221-222`). It does not hold for the printed lists (`:223-224`) when a name is git-quoted.
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r1: covers files under the `skills workflows docs/decisions` pathspec only, "which the comment does not claim" otherwise · r1+r3: quoted names drop out of the printed counts (their Claims 24 / 15) · r1+r3: test 20 passes at HEAD and fails on db0e5ca

The walk is right: `git log "$MAIN_SHA" --first-parent --diff-merges=first-parent --name-only --format='@%cs' -- skills workflows docs/decisions` (`:221`). But git quotes any name with non-ASCII or control bytes under the default `core.quotePath`, and the filters `grep -E '^(skills/.*/SKILL\.md|workflows/[^/]*\.md)$'` (`:223`) and `'^docs/decisions/…'` (`:224`) then miss it. A merge adding `skills/café/SKILL.md` produced `"skills/caf\303\251/SKILL.md"` from git and `Skill or workflow files changed … : 0` from the digest. A precise version: "every file … touched, except names git quotes (non-ASCII or control bytes), which the lists below drop."

**Evidence:** `scripts/dev-cycle.sh:217-224`, `$S2/probe5.out`, `$S2/bats-28c6178.txt`

---

## Claim 19: "'@' lines carry each commit's date; git quotes a name holding a control character, so each name is one line."

**Location:** `scripts/dev-cycle.sh:219-220`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers one name per line and the `@` parsing: a path line starts with `skills`, `workflows`, `docs/decisions` or `"`, never `@`. It does not establish that such names are counted. A quoted name (a control character, or non-ASCII under the default `core.quotePath=true`) starts with `"` and fails both filters (`:223-224`), so it silently drops out of section 7's counts.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: quoted names (control or non-ASCII bytes) silently drop out of section 7's counts · r2: `skills/@2099-01-01/SKILL.md` and `workflows/@x.md` were listed correctly and did not reset the date gate

r1 P11 printed `"skills/a\tb/SKILL.md"` and `"skills/caf\303\251/SKILL.md"` as single lines, then section 7 reported `Skill or workflow files changed … : 0`. r3: of `skills/café`, `skills/a\nb` and `skills/ok`, only `skills/ok` was counted.

**Evidence:** `scripts/dev-cycle.sh:219-224`, `$S1/probes-A2.log`, `$S2/probe2.out`, `$S3/inrepo-sec7-probes.log`

---

## Claim 20: Contract comment — "No docs/roadmap.md yet — create it this cycle from the template in the dev-cycle skill."

**Location:** `scripts/dev-cycle.sh:195`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers agreement with the committed skill text. It does not cover a configured non-default seed log (Claim 61).
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r3 (cited as evidence under a SKILL.md claim, not verdicted here): the template it points to is at `SKILL.md:166-178` · r2 (under Claim 13's scope): the same message is printed when a symlinked roadmap is skipped

The skill has the roadmap template (`skills/dev-cycle/SKILL.md:164-178`).

**Evidence:** `scripts/dev-cycle.sh:195`, `skills/dev-cycle/SKILL.md:164-178`

---

## Claim 21: "The skill's step 5 appends '## Brainstorm YYYY-MM-DD' after reading the log (its ideas go to the roadmap); seeding appends '- ' lines after that heading."

**Location:** `scripts/dev-cycle.sh:246-247`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers agreement with the committed skill text. It does not cover a configured non-default seed log (Claim 61).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: holds for the default log path only; a non-default seed log is Claim 61

The skill says "Then append `## Brainstorm YYYY-MM-DD` to the idea log … the surviving ideas go to the roadmap's Ideas" (`skills/dev-cycle/SKILL.md:159-160`). Seeding writes `- <idea> (signal: …)` (`:42`). The digest counts `/^- /` lines and resets at each `## Brainstorm` heading (`scripts/dev-cycle.sh:250`).

**Evidence:** `scripts/dev-cycle.sh:244-256`, `skills/dev-cycle/SKILL.md:41-44,159-178`

---

## Claim 22: Test 4 name — "an old-dated commit on main does not hide the merges behind it"

**Location:** `test/scripts/dev-cycle.bats:80`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the name matching what the test asserts. Its comment is covered by Claim 23.
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified (compound)
**Replicate annotations:** none

The test expects 4 merges after a 2020-dated fast-forward, and passes at HEAD.

**Evidence:** `test/scripts/dev-cycle.bats:80-92`, `$S1/bats-A.log`

---

## Claim 23: Test 4 comment — "--since used to stop its walk at the old commit, so it counted only the newest merge and hid the three older ones behind the old commit."

**Location:** `test/scripts/dev-cycle.bats:81-83`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers git 2.39.5's non-limited `--since` walk on test 4's exact history. It does not cover other git versions.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: "It does not cover db0e5ca, where test 4 passes because the post-walk filter was already there."

`make_repo` creates three merges (`:28-33`); the old form reproduced "only `merge: feature 4`".

**Evidence:** `test/scripts/dev-cycle.bats:22-35`, `:80-92`, `$S1/test4-oldbehaviour.log`, `$S2/probe5.out`

---

## Claim 24: Test 5 — "Split by a C0 byte, and nested: neither may reassemble a sequence." (plus the env loop `"" PERL_UNICODE=SDA PERL5OPT=-CSD`)

**Location:** `test/scripts/dev-cycle.bats:98-103`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fixture bytes in `002-y.md` and the three env settings. It does not cover the residue named in Claim 7.
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified
**Replicate annotations:** r3: "Does not establish coverage of `PERLIO` (Claim 5), which the env loop does not include."

Fixture holds C0-split (`\xc2\x01\x9b`, `\xe2\x80\x01\xae`) and nested (`\xc2\xc2\x9b\x9b`, `\xe2\x80\xe2\x80\xae\xae`, a doubled tag) cases. Passes at 28c6178, fails at db0e5ca.

**Evidence:** `test/scripts/dev-cycle.bats:94-109`, `$S2/bats-28c6178.txt`, `$S2/bats-newtests-on-db0e5ca.txt`

---

## Claim 25: Test 7 name — "the exit status and the whole digest survive a redirect to a file"

**Location:** `test/scripts/dev-cycle.bats:122-128`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers that the test passes and checks section 7's heading, the final `idea-log` line, and exit 1 on a bad `--since`. It does not establish that it detects truncation: it also passes on db0e5ca, as commit 26b7590's Notes say. Claim 9 carries the real completeness evidence.
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: passes on db0e5ca too, so it does not detect truncation · r3: the non-zero exit is checked on an unredirected `run`

**Evidence:** `test/scripts/dev-cycle.bats:122-128`, `$S2/bats-newtests-on-db0e5ca.txt`, `$S3/bats-new-tests-on-db0e5ca.log`

---

## Claim 26: Test 10 — "--since includes commits from the start date itself" / "All commits here are from today: a window starting today counts all of them."

**Location:** `test/scripts/dev-cycle.bats:147-153`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the name and comment against the assertion `"; $total commit(s)"`. It does not test zone boundaries (Claim 1 covers those).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: fixture is a commit at `T00:00:30` today; "Does not establish anything about time-of-day handling beyond date equality"

`run --separate-stderr bash "$DC" --since="$(date +%F)"` then `[[ "$output" == *"; $total commit(s)"* ]]` (`:151-152`). Passes.

**Evidence:** `test/scripts/dev-cycle.bats:147-153`, `$S1/bats-A.log`

---

## Claim 27: Test 19 comment — "README_gen.sh is code; a README.txt or docs/ alone is a doc."

**Location:** `test/scripts/dev-cycle.bats:272`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four specs and the per-spec expected verdict. It does not cover upper-case `.MD` or `DOCS/` (Claim 16).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r2: uppercase `.MD` / `Docs/` not exercised · r3: "Does not establish other README-like names"

Specs `"readme-like:src/README_gen.sh:flag"`, `"readme-txt:x.sh lib/README.txt:ok"`, `"docs-only:docs/a.txt y.sh:ok"`; the loop asserts per branch. Passes at 28c6178, fails at db0e5ca.

**Evidence:** `test/scripts/dev-cycle.bats:272-286`, `$S2/bats-newtests-on-db0e5ca.txt`

---

## Claim 28: Test 20 comment — "Changed and reverted inside the window: still a change."

**Location:** `test/scripts/dev-cycle.bats:291-292`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the test's assertions can observe. It does not dispute the digest behavior, which Claim 18 covers.
**Replicate verdicts:** r1=Verified (compound) · r2=Mostly accurate · r3=Verified (compound)
**Replicate annotations:** r1+r3: the test (tmp add/remove plus the `wf` merge and drop) passes at HEAD and fails on db0e5ca

The line under the comment adds and removes `skills/demo/tmp.md` (`:292`). That path never matches the `skills/.*/SKILL\.md` filter (`scripts/dev-cycle.sh:223`), so no assertion can see it. The revert the test actually checks is `workflows/flow.md`, added by "merge: wf" and removed by "drop wf" (`:293-294`), asserted as `"    - workflows/flow.md"` (`:300`). The comment sits on a case that is not asserted.

**Evidence:** `test/scripts/dev-cycle.bats:288-304`, `scripts/dev-cycle.sh:223`

---

## Claim 29: Commit 26b7590 — "R1/A1 (X1): scrub pins perl to bytes (-C0, PERL_UNICODE/PERL5OPT removed)"

**Location:** commit `26b7590` message
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** This is the same fact as Claim 5, in the commit's words. It does not cover the commit's other R1 items (C0 first, repeat until stable, the new test 5 cases), which are Claim 30.
**Replicate verdicts:** r1=Incorrect · r2=Verified (compound) · r3=Incorrect
**Replicate annotations:** r3: "Does not establish other perl variables" · r2 (compound): verified the mechanism against `PERL_UNICODE`/`PERL5OPT` only; did not probe `PERLIO`

`PERLIO=:utf8` unpins it, and C1 and RLO pass through the full digest. Details at Claim 5.

**Evidence:** `scripts/dev-cycle.sh:34`, `$S1/perlio.log`, `$S1/perlio-e2e.log`, `$S3/e2e-perlio.log`

---

## Claim 30: Commit 26b7590 — "deletes C0 first, and repeats the substitution until stable; test 5 adds split, nested and env cases"

**Location:** commit `26b7590` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** As Claims 6 and 24.
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1 (Claim 41 Scope, not a separate verdict): these R1 items "are verified at Claims 13 and 39" · r2: "does not cover the residue in Claim 4" (merged Claim 7)

The diff adds `for env in "" PERL_UNICODE=SDA PERL5OPT=-CSD; do` to test 5 (`test/scripts/dev-cycle.bats:100`). See Claims 6 and 24.

**Evidence:** `scripts/dev-cycle.sh:34`, `test/scripts/dev-cycle.bats:98-102`, `$S3/probe-scrub.log`

---

## Claim 31: Commit 26b7590 — "A5: the body runs as a child whose stdout and stderr pass through scrub as pipeline members, so the shell waits for both filters … Exit status is the body's."

**Location:** commit `26b7590` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** As Claims 9 and 11. The ordering clause in the same bullet is Claim 32.
**Replicate verdicts:** r1=Verified (atom of compound; r1 Claim 42's Verdict is Incorrect, carried by Claim 32) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "I split this claim by atom … 'Waits for both filters' and 'exit status is the body's' are verified at Claims 16 and 17. 'Stream order follows the body' is refuted."

**Evidence:** `scripts/dev-cycle.sh:41-44`, `$S2/big-harness.out`, `$S2/order-harness.out`, `$S3/reexec-probes.log`

---

## Claim 32: Commit 26b7590 — "perl autoflushes, so stream order follows the body."

**Location:** commit `26b7590` message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** This does not measure how often the digest itself interleaves its two streams, since its stderr is mostly fatal errors written last.
**Replicate verdicts:** r1=Incorrect (compound) · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r2+r3: each stream on its own keeps the body's order; only the interleaving is lost · r2 suggested wording: "each stream keeps its own order; the interleaving of stdout with stderr is not preserved."

r1 reproduced the exact pipeline shape and autoflushing scrub with a body that alternates `echo "out $i"` and `echo "err $i" >&2` 200 times. With both streams merged (`2>&1`) to one file, 10 of 10 runs came out misordered (`$S1/order.log`: `2d1 < err 1`, `4d2 < err 2`, …). Two independent filter processes give no cross-stream ordering, and autoflush does not change that. r2: 3 of 3 runs differed; r3: 20 of 20.

**Evidence:** `scripts/dev-cycle.sh:42`, `$S1/order.sh`, `$S1/order.log`, `$S2/order-harness.out`, `$S3/order-probe.log`

---

## Claim 33: Commit 26b7590 — "A4: inrepo() reads only regular files whose real path is inside the checkout (symlinked records, log, roadmap, questions, idea log skipped)."

**Location:** commit `26b7590` message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** This covers the parenthetical. The main clause is Claim 13.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r2: "does not cover the `QUESTIONS_LIVE` residue" · r3: "Does not cover the cycle-record name glob" (Claim 13)

A symlink whose real path stays inside the checkout passes `[[ "$r" == "$ROOT_REAL"/* ]]` (`scripts/dev-cycle.sh:67`) and is read; only symlinks that leave the checkout are skipped. r2 and r3 executed an in-repo `docs/roadmap.md` symlink and saw it read. Precise version: "(records, log, roadmap, questions, idea log symlinked out of the checkout are skipped)".

**Evidence:** `scripts/dev-cycle.sh:63-67`, `$S2/probe4.out`, `$S3/inrepo-sec7-probes.log`

---

## Claim 34: Commit 26b7590 — A6 (`--help`/Window committer date, test renamed), A7 ("doc = docs/, *.md, or a file named README / README.* (any case)"), A9/C8 (test 4 comment and name), C1 (part) ("section 6 reuses merges_full and caps its list at 30")

**Location:** commit `26b7590` message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named change being present and behaving as stated. "any case" applies to README only (Claim 16).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r2: "any case" holds for README only · r3: "Does not re-review the substance of rubric items A9/C8 beyond the renamed text"

The diff shows the `--help` and Window rewording (`scripts/dev-cycle.sh:10-11`, `:110`), the "midnight" test renamed (`test/scripts/dev-cycle.bats:147`), the README rule (`:205`), test 4's name and comment (`test/scripts/dev-cycle.bats:80-83`), and the cap (`:212-213`).

**Evidence:** `scripts/dev-cycle.sh:10-11,110,205,212-213`, `test/scripts/dev-cycle.bats:80-83,147`, `$S2/probe2.out`

---

## Claim 35: Commit 26b7590 — "A8: section 7 lists every file a first-parent commit in the window touched (path-limited walk), not a net diff; no base commit any more."

**Location:** commit `26b7590` message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 18.
**Replicate verdicts:** r1=Verified (compound) · r2=Mostly accurate · r3=Verified (compound)
**Replicate annotations:** r1: `base=`/`oldest=` are gone from the section 7 code (`:216-233`) · r3: "the `oldest`/`base` code is removed in the diff"

The walk and the removal of `base`/`oldest` are as stated: the diff deletes `oldest=…`, `base=…` and `git diff … "$base" "$MAIN_SHA"`. "Lists every file" does not hold for names git quotes (`skills/café/SKILL.md` was not counted).

**Evidence:** `scripts/dev-cycle.sh:216-224`, `$S2/probe5.out`

---

## Claim 36: Commit 26b7590 — "20/20 tests; the new scrub, symlink, section 6 and section 7 tests fail on db0e5ca."

**Location:** commit `26b7590` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the suite at 26b7590 and at 28c6178 run against the db0e5ca script. It does not establish that each test fails for the intended reason, beyond seeing that it fails.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: ran 28c6178's bats file (26b7590's differs only inside test 19, same count); r1 also ran 26b7590's own script and bats (20 ok) · r1: does not establish each test fails for the intended reason

- 26b7590's script and bats: 20 `ok`, exit 0 (`$S1/bats-26b7590.log`).
- 28c6178's bats against db0e5ca's script: `not ok 5`, `not ok 6`, `not ok 19`, `not ok 20`, everything else ok, including test 7 (`$S1/bats-on-db0e5ca.log`; exit 1). r2 and r3 reproduced the same four failures.

**Evidence:** scratchpad `fc5-r1/bats-26b7590.log`, `fc5-r1/bats-on-db0e5ca.log`, `fc5-r2/bats-newtests-on-db0e5ca.txt`, `fc5-r3/bats-new-tests-on-db0e5ca.log`

---

## Claim 37: Commit 26b7590 — "shellcheck clean."

**Location:** commit `26b7590` message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the health-check lint gate over the files the commit changed. Under the narrow reading the claim holds: the script alone is clean.
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r1+r2+r3: `scripts/dev-cycle.sh` itself was clean; 28c6178 fixed the bats warning, so this is history-only (r1) · r2: resembles the logged hallucination family "commit message states a verification result the repo does not bear out" (not a fabricated symbol; no new entry)

At 26b7590, `shellcheck -s bash dev-cycle.bats` reports `SC2034 (warning): want appears unused` at line 274, exit 1. The gate lints `.bats` files at warning level: `# Also include .bats files — they're bash` and `shellcheck -x -e SC1091 -s bash -S warning "$f"` (`scripts/health-check.sh:459,480`). 28c6178 records this failure and fixes it; at HEAD both files pass the gate's exact flags.

**Evidence:** `scripts/health-check.sh:427-486`, `$S1/shellcheck-26b7590-bats.log`, `$S1/shellcheck-head.log`, `$S2/shellcheck.txt`, `$S3/shellcheck-gateflags.log`

---

## Claim 38: Commit 26b7590 Notes — "the re-exec uses DEV_CYCLE_SCRUBBED as an internal marker (an environment that sets it skips the scrub; a repo cannot). A lone 0x9B byte and zero-width characters stay unscrubbed, as the comment says. The redirect test passes on db0e5ca too (truncation is timing-dependent)."

**Location:** commit `26b7590` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each sentence as stated. It does not establish that the comment's list is complete (Claim 7 has the omissions).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: "as the comment says" — the comment's list is incomplete (Claim 7)

Setting the marker skipped the scrub; `lone9b: 61 9b 62`; `ok 7 the exit status and the whole digest survive a redirect` on db0e5ca.

**Evidence:** scratchpad `fc5-r2/probe1.out`, `fc5-r2/probe3.out`, `fc5-r2/bats-newtests-on-db0e5ca.txt`, `fc5-r1/bats-on-db0e5ca.log`

---

## Claim 39: Commit 28c6178 body — "shellcheck SC2034 (unused 'want') failed the health-check lint gate."

**Location:** commit `28c6178` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the warning at 26b7590 and the gate's inclusion of `.bats` at warning level, and that the fix uses `want`. I did not run the whole health-check script.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (atom of compound; r3 Claim 28's Verdict is Mostly accurate, carried by Claim 40)
**Replicate annotations:** r1+r2: only the shellcheck gate was run, not the whole health check

See Claim 37's logs. At HEAD, `IFS=: read -r br want <<< "$spec"` followed by `if [[ "$want" == flag ]]` (`test/scripts/dev-cycle.bats:281-282`) uses the variable, and shellcheck exits 0.

**Evidence:** `test/scripts/dev-cycle.bats:272-285`, `$S1/shellcheck-26b7590-bats.log`, `$S1/shellcheck-head.log`

---

## Claim 40: Commit 28c6178 subject — "use the expected-verdict field in the section 6 cases"

**Location:** commit `28c6178` message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the body (verified) and the subject (imprecise). Does not establish anything else.
**Replicate verdicts:** r1=— · r2=— · r3=Mostly accurate · single-replicate detection
**Replicate annotations:** r2 (Claim 32 body, not a verdict on the subject): "The fix is `IFS=: read -r br files _` plus a `want` field used in the assertion loop."

The fix discards the first list's third field (`IFS=: read -r br files _`) and restates the expectations in a second list (`for spec in readme-like:flag readme-txt:ok ...; IFS=: read -r br want`). The original field is still unused. Precise version: "assert the expected verdict per section 6 case".

**Evidence:** `test/scripts/dev-cycle.bats:273-285`, `$S3/shellcheck-gateflags.log`

---

## Claim 41: Decision log row 67 — "the self-improvement loop's `feature-ideas*.md` is read as a signal in step 5, so the roadmap is the one backlog (Q-099 [1], 2026-09-30)"

**Location:** `docs/decisions/log.md:90`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers the Q-099 answer, its date and the step-5 reading of feature-ideas. It does not establish anything about the rest of row 67, which the row-68 revision supersedes and which is historical text outside this diff.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2: the rest of row 67 is not covered (r3 checks it: Claim 42)

`docs/working/questions-archive.md:1800`: `**Answer (2026-09-30, answers-9-30-26.txt): [1].** The roadmap is the one backlog.` Step 5 names `e.g. the self-improvement loop's \`docs/working/feature-ideas*.md\` in claude-workflows` (`skills/dev-cycle/SKILL.md:156`).

**Evidence:** `docs/working/questions-archive.md:1797-1815`, `skills/dev-cycle/SKILL.md:154-157`

---

## Claim 42: Decision log row 67 (same edited line) — "Steps: digest → … → roadmap (Now / Next ≤5 / Ideas / Done) → cycle record"

**Location:** `docs/decisions/log.md:90`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the row's step and section list against the skill as committed. Row 68 records the revision, so this is low-stakes.
**Replicate verdicts:** r1=— · r2=— · r3=Stale · single-replicate detection
**Replicate annotations:** r1 (Claim 1 Scope): the rest of row 67 is "superseded" by row 68 and "historical text outside this diff" · r2 (Claim 33 Scope): the rest of row 67 "is outside this delta"

The skill's roadmap now has `## In flight` (`SKILL.md:174`), plus steps 4b and 6b. Row 67 was edited in c079e8c without updating its step or section list. A reader of row 67 alone would miss In flight, 4b and 6b. A pointer such as "(revised by row 68)" would fix it.

**Evidence:** `docs/decisions/log.md:90-91`, `skills/dev-cycle/SKILL.md:51-54`, `:173-177`

---

## Claim 43: Row 68 — "Carry-forward and the `Main at:` handshake are cut, so every trigger is judged every cycle (Q-101 [1])"

**Location:** `docs/decisions/log.md:91`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the skill and digest at their HEADs. It does not establish anything about cycle records already written.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r3: 6ee33e3 had 2 `Main at` hits; HEAD has 0

`rg 'Main at' skills/dev-cycle/SKILL.md` returns no hits. The skill says "The previous record's verdicts are context, never the answer: decide each one again" (`:100-101`). Digest test 3 asserts `"$output" != *"Main at:"*` and passes. Q-101's answer: `[1]. Cut carry-forward and \`Main at:\`` (`questions-archive.md:1830`).

**Evidence:** `skills/dev-cycle/SKILL.md:96-104`, `test/scripts/dev-cycle.bats:66-78`, `docs/working/questions-archive.md:1817-1835`, `$S2/bats-28c6178.txt`

---

## Claim 44: Row 68 — "step 4 is a claim spot-check and a new conditional step 4b files a full-history deep audit when a skill, the model or a major decision changes"

**Location:** `docs/decisions/log.md:91`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the skill. It does not establish that "files" means anything more than adding a roadmap task. The skill's trigger also includes workflow files.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: "files" means adding a roadmap task; the skill's trigger also covers workflow files

`### 4. Claim spot-check` (`:118`); "a skill or workflow file added or substantially changed …; a decision record … that is a major design decision; the model running this cycle differs …. Any fired: add a scoped deep-audit task to the roadmap" (`:135-140`).

**Evidence:** `skills/dev-cycle/SKILL.md:118-141`

---

## Claim 45: Row 68 — "brainstorm (step 5) is conditional (0–1 items ready, 10+ seeds, a week since the last, a reopened direction, or asked) while seeding is always on"

**Location:** `docs/decisions/log.md:91`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the list of conditions. It does not cover whether the digest supplies the inputs for them (Claims 61 and 81).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** none

Step 5 lists exactly these five conditions (`skills/dev-cycle/SKILL.md:148-152`); `**Seeding is always on.**` is at `:41`.

**Evidence:** `skills/dev-cycle/SKILL.md:41-44`, `:143-152`

---

## Claim 46: Row 68 — "ready Now items get build briefs and are handed to autonomous RPI loops (step 6b, at most 3 in flight) after the cycle branch lands"

**Location:** `docs/decisions/log.md:91`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the skill text. It does not establish how "in flight" is counted mechanically.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: how "in flight" is counted mechanically is not established

"Take the Now items whose first step needs no open choice …, up to the in-flight cap: at most 3 loops in flight at once" (`:190-192`); "Runs after step 7 has landed. … start an autonomous build loop (`research-plan-implement`)" (`:228-229`).

**Evidence:** `skills/dev-cycle/SKILL.md:190-196`, `:226-232`

---

## Claim 47: Row 68 — "'undocumented is broken' is a rule, checked through the digest's code-without-docs section"

**Location:** `docs/decisions/log.md:91`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rule and the section existing and linking to each other. It does not cover classification edge cases (Claim 16).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** none

`**Undocumented is broken.**` (`SKILL.md:35`); step 4: "Also check every merge the digest lists under 'Merges with code but no docs'" (`:123-124`); the digest prints `## 6. Merges with code but no docs`.

**Evidence:** `skills/dev-cycle/SKILL.md:35-39`, `:123-124`, `$S2/digest-wt-devcycle.md`

---

## Claim 48: Row 68 — "The double-diamond pass's 8 gaps were applied (landing order, in-flight state, 4b inputs, digest failure path, where filed work goes, readiness, subagent use, parallel steps)."

**Location:** `docs/decisions/log.md:91`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers the count (8) and that each named gap has a matching skill passage. It does not establish that each fix matches the approval doc's wording exactly (see Claim 92).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: "does not establish that the user approved each fix (the doc's checklist items are not marked checked in the read)" · r3: "Does not establish that the user approved the final text"

Each of the 8 has a matching passage: landing order (`:223-224`); in-flight state (`:174,181`, step 1's skip `:89`); 4b inputs (`:133`); digest failure path (`:74-76`); where filed work goes (`:30-31`); readiness (`:33`); subagent use (`:58`); parallel steps (`:56`). The approval doc says "All eight fixes are applied to the steps above (2026-10-01)" (paraphrased by r1; quoted by r2 and r3 via the Docs connector).

**Evidence:** `skills/dev-cycle/SKILL.md:30-33,56-58,74-76,89,133,174-181,223-224`

---

## Claim 49: Row 68 — "Revisit if the 6b cap of 3 starves or swamps the review, or if section 7's thresholds never fire in four cycles."

**Location:** `docs/decisions/log.md:91`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** This covers where the thresholds live. It does not judge whether the trigger is a good one.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** none

Section 7 holds inputs, not thresholds. It prints `"Step 5 (brainstorm triggers; the thresholds are the skill's):"` (`scripts/dev-cycle.sh:235`), and the thresholds are in the skill's steps 4b and 5 (`skills/dev-cycle/SKILL.md:135-137,148-152`). Precise wording: "if the 4b/5 thresholds, fed by section 7, never fire in four cycles".

**Evidence:** `scripts/dev-cycle.sh:225,235`, `skills/dev-cycle/SKILL.md:133-152`

---

## Claim 50: Row 68 rationale — "User comments on the approval doc, 2026-10-01: the cycle boundary is the only place triggers are certain to be checked; audit is not code review; brainstorm matters most when little is planned; this is the standard loop, so it must hand off to build loops."

**Location:** `docs/decisions/log.md:91`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing beyond the doc body. It does not establish what the user's comments said.
**Replicate verdicts:** r1=— · r2=Unverifiable · r3=Unverifiable
**Replicate annotations:** r1 (Claim 2 Scope): "It does not cover the rationale cell's account of the user's comments, which live on the approval doc and are context." · r2+r3: the doc body contains matching prose ("Step 4 … is closer to code review than to an audit"; "Its main trigger is a thin plan"); verifying needs a `query` of the doc's comment threads

The doc read returned only answered-comment markers (`<comment id='…' to='claude' answered='true'/>`), not comment bodies.

**Evidence:** claude.ai artifact 78a2f851-e696-4a86-bfe8-474212e5e645 (rev 48), `docs/decisions/log.md:91`

---

## Claim 51: `docs/dev-cycle-sources.md` — "step 5 reads every source when it brainstorms, and always-on seeding appends to the seed log."

**Location:** `docs/dev-cycle-sources.md:3-4`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers agreement with the skill and the digest for this repo. It does not establish that the digest reads this file. It does not (see Claim 61).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r2+r3: the digest does not read this file (Claim 61) · r1: none of `docs/working/{idea-log,feature-ideas-x,questions}.md` is gitignored

The skill says "generate 3–8 ideas … Then append `## Brainstorm YYYY-MM-DD` to the idea log" (`skills/dev-cycle/SKILL.md:157-160`), "read … the repo's idea sources (those `docs/dev-cycle-sources.md` lists …)" (`:154-155`) and seeds `- <idea> (signal: <what prompted it>)` (`:42`).

**Evidence:** `docs/dev-cycle-sources.md:3-9`, `skills/dev-cycle/SKILL.md:41-44,154-160`

---

## Claim 52: `docs/dev-cycle-sources.md` — "Feature ideas | docs/working/feature-ideas*.md | the self-improvement loop's idea files"

**Location:** `docs/dev-cycle-sources.md:8`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the path exists. It does not cover the "Done when" policy.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r3: the glob also matches the SI loop's `feature-ideas-round-N.md` (`scripts/self-improvement.sh:38`) · r3 (Claim 44): the approval doc's sources draft used `docs/feature-ideas*.md` (see Claim 92)

`docs/working/feature-ideas.md` exists. `scripts/archive-working-docs.sh:9` lists `feature-ideas.md` among the self-improvement loop's permanent files.

**Evidence:** `docs/working/feature-ideas.md`, `scripts/archive-working-docs.sh:9`

---

## Claim 53: `docs/dev-cycle-sources.md` — "Seed log | docs/working/idea-log.md | one `- <idea> (signal: …)` line per idea; step 5 appends `## Brainstorm YYYY-MM-DD` after reading it"

**Location:** `docs/dev-cycle-sources.md:9`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the skill and with the digest's parser for this repo. It does not establish that the file exists yet (it does not; the digest prints "No docs/working/idea-log.md").
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: the file does not exist yet

The digest uses `LOG=docs/working/idea-log.md` with `^## Brainstorm [0-9]{4}-…` and `/^- /` (`scripts/dev-cycle.sh:244-250`), which matches this row.

**Evidence:** `scripts/dev-cycle.sh:244-250`, `$S2/digest-wt-devcycle.md`

---

## Claim 54: `docs/roadmap.md` gains `## In flight` (commit c079e8c: "the roadmap's In flight section")

**Location:** `docs/roadmap.md:18`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exact-heading match the digest needs. It does not cover item content.
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r3: `## In flight` sits between Now and Next, as in the template

The digest matches `$0 == h` with `h="## $sec"` for `Now`, `In flight` and `Next` (`scripts/dev-cycle.sh:237-238`). The digest printed `Roadmap Now: 1`, `Roadmap In flight: 0`, `Roadmap Next: 5`.

**Evidence:** `docs/roadmap.md:13-20`, `scripts/dev-cycle.sh:236-240`, `$S2/digest-wt-devcycle.md`

---

## Claim 55: Global decision-tree row 12 — "The outer loop over rows 6/9: health and cleanup, every revisit trigger, claim spot-check, conditional deep-audit check and brainstorm, roadmap (`docs/roadmap.md`), then hands ready items to autonomous build loops. User-started, no timer."

**Location:** `global-instructions/CLAUDE.md:32`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers the step list and the row numbers. It does not establish how the router fires (the dev-cycle skill has no router file and is itself a skill).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: "does not cover the installed `~/.claude/CLAUDE.md`, which does not yet have row 12 (install state, out of scope)" · r1: router firing not established

Row 6 is `research-plan-implement.md`, row 9 is `pr-prep.md`. The steps match the skill's flow block `0 digest → 1 health and cleanup → { 2 triggers | 3 questions | 4 spot-check | 4b audit check } → 5 brainstorm (conditional) → 6 roadmap → 7 close … → 6b handoff` (`skills/dev-cycle/SKILL.md:52-53`) and "It runs when the user starts it; there is no timer" (`:14-15`).

**Evidence:** `global-instructions/CLAUDE.md:24-32`, `skills/dev-cycle/SKILL.md:9-16,51-54`

---

## Claim 56: "with no human checkpoint mid-run beyond the Operating Modes rule (under /active the user confirms the handoff queue, as for any launch; decisions go to questions.md)"

**Location:** `guides/skill-creation.md:137`
**Type:** Reference / Architectural
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** This covers whether the Operating Modes section has a launch-confirmation rule the handoff queue inherits. It does not establish whether launching a build loop should need confirmation.
**Replicate verdicts:** r1=Incorrect · r2=Verified · r3=Incorrect
**Replicate annotations:** r2: "does not cover human gates inside `pr-prep` when step 7 lands the branch" · r3: "the row's mechanism … is not in the cited rules … understates the skill's own mid-run human gate under /active. The guide's promotion criterion names exactly that kind of gate ('Promote it to a workflow … if a cycle ever needs a human gate mid-run')."

The Operating Modes /active list has no launch rule; it requires approval only for commits, pushes, PRs, plan review gates and architectural decisions outside the plan. `rg -i launch global-instructions/CLAUDE.md` returns nothing. The queue confirmation is the skill's own rule: `Under /active the user confirms this queue now; under /away it stands.` (`skills/dev-cycle/SKILL.md:192`). The skill also has an Operating Modes checkpoint mid-run that the guide does not name: `Commits and merges follow the Operating Modes rules … (in /active mode, ask first)` (`:27-29`), and step 7 lands through pr-prep. Precise version: "no human checkpoint mid-run beyond the skill's /active handoff-queue confirmation (step 6) and Operating Modes approvals for commits and merges".

**Evidence:** `guides/skill-creation.md:137`, `skills/dev-cycle/SKILL.md:27-29,190-196`, `global-instructions/CLAUDE.md:190-200`

---

## Claim 57: Skill description — "digest, health and cleanup, revisit triggers, watched questions, claim spot-check, conditional deep-audit check and brainstorm, roadmap, close, then hand ready roadmap items to autonomous build loops"

**Location:** `skills/dev-cycle/SKILL.md:4`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the step list. It does not cover trigger-phrase quality.
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** none

Matches headings 0–7, 4b and 6b (`:62`, `:78`, `:96`, `:106`, `:118`, `:128`, `:143`, `:162`, `:198`, `:226`).

**Evidence:** `skills/dev-cycle/SKILL.md:4`, `:62-226`

---

## Claim 58: "Every subagent brief this cycle writes (steps 2, 3, 4, 4b, 6b) says so."

**Location:** `skills/dev-cycle/SKILL.md:22-23`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers internal consistency of the skill. It does not judge whether build briefs should carry the line.
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=— · single-replicate detection
**Replicate annotations:** none

The build briefs 6b launches are written in step 6, not 6b: "For each queued item, write a build brief at `docs/working/handoffs/<date>-<slug>.md` (goal, motive, acceptance criteria including the doc change, branch, out-of-scope, stop conditions)" (`:193-194`). That field list omits the evidence-not-instructions line. Precise version: "(steps 2, 3, 4, 4b, and the build briefs step 6 writes)", with step 6's list naming the line.

**Evidence:** `skills/dev-cycle/SKILL.md:20-24`, `:190-196`, `:228-229`

---

## Claim 59: "Commits and merges follow the Operating Modes rules in the global instructions (in /active mode, ask first)"

**Location:** `skills/dev-cycle/SKILL.md:27-29`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers commits. Merges create commits. Does not cover launching loops (see Claim 56).
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** r1 (Claim 7, cited as evidence): this rule is "an Operating Modes checkpoint mid-run that the guide does not name"

Under /active the global instructions say "**Require user approval before:** - Creating git commits" (`global-instructions/CLAUDE.md:194-195`).

**Evidence:** `global-instructions/CLAUDE.md:190-200`

---

## Claim 60: "Then append `## Brainstorm YYYY-MM-DD` to the idea log, so the next digest counts seeds from here" — default seed-log path (this repo)

**Location:** `skills/dev-cycle/SKILL.md:159-160`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers this repo, where `docs/dev-cycle-sources.md` names `docs/working/idea-log.md` as the seed log. It does not cover other repos (Claim 61).
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified
**Replicate annotations:** r2 (Claim 52 Scope): "It does not affect claude-workflows today: its sources file names exactly that path (`docs/dev-cycle-sources.md:9`), so the two agree here."

The digest counts from the last heading: `seeded="$(awk '/^## Brainstorm [0-9]…/ { c = 0; next } /^- / { c++ } …' "$LOG")"` (`scripts/dev-cycle.sh:250`). Test 20 checks `Ideas seeded since: 2` and `Last brainstorm: 2026-01-01 (7 day(s) ago)`.

**Evidence:** `scripts/dev-cycle.sh:244-256`, `docs/dev-cycle-sources.md:9`, `$S1/bats-A.log`

---

## Claim 61: "The idea log is the file `docs/dev-cycle-sources.md` names as its seed log when that file exists, else `docs/working/idea-log.md`." combined with "… so the next digest counts seeds from here" — non-default seed log

**Location:** `skills/dev-cycle/SKILL.md:41-44,159-160`
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** This covers any repo whose sources file names a seed log other than the default. The skill is installed for every project (`~/.claude/scripts/dev-cycle.sh`, `SKILL.md:64`). It does not affect this repo today.
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r2: "The installed digest is meant to serve any project ('so the installed copy serves any project', `scripts/dev-cycle.sh:17-18`). Prior finding A2 (the section 7 step-5 contract) is therefore closed for the default path only." · r2: in such a repo the digest may also "read a stale file" · r3: "Two of the brainstorm triggers would then never fire from digest input"; "an A↔B contract gap that this repo does not hit today"

The digest hard-codes the path and never reads `docs/dev-cycle-sources.md` (`rg dev-cycle-sources scripts/dev-cycle.sh`: no hits):

```bash
# scripts/dev-cycle.sh:244-245
LOG=docs/working/idea-log.md
if inrepo "$LOG"; then
```

Where a sources file names another seed log, seeding and the `## Brainstorm` heading go there. The next digest then prints `- No docs/working/idea-log.md: no ideas seeded, no brainstorm recorded` (`:258`), and the step-5 "10+ seeds" and "a week since" triggers are fed wrong values. Either the digest reads the sources file's seed-log row, or the skill limits the configurable seed log to the default path.

**Evidence:** `scripts/dev-cycle.sh:17-18,244-258`, `skills/dev-cycle/SKILL.md:41-44,146-160`

---

## Claim 62: "Steps 2, 3, 4 and 4b depend only on 0 and 1, not on each other: run them in parallel as subagents … Step 4 uses one read-only subagent per sampled merge."

**Location:** `skills/dev-cycle/SKILL.md:56-58`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers data independence of the steps' inputs. It does not cover write conflicts: step 3 may do up to 3 in-cycle fixes (`:112-113`) and step 4 may "fix it if mechanical" (`:124-125`), both on the same branch, in parallel.
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** r2: write conflicts between parallel steps 3 and 4 (both may commit fixes on the same branch) are not covered

Step 2 reads digest section 2, step 3 section 3, step 4 sections 4 and 6, and 4b section 7 plus the last record. None reads another's output.

**Evidence:** `skills/dev-cycle/SKILL.md:56-60`, `:96-141`

---

## Claim 63: "Run `~/.claude/scripts/dev-cycle.sh` from the repo root (inside claude-workflows, its own `scripts/dev-cycle.sh`)"

**Location:** `skills/dev-cycle/SKILL.md:64-65`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the install mapping. It does not establish that the installed copy is current.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r3: `CLAUDE_HOME_SRC=(… scripts)` stages the whole `scripts/` directory (`devcontainer-config/install.sh:135`) · r3: "Does not establish runtime behaviour of the installed copy outside this repo"

`devcontainer-config/link-claude-home.sh:50` has `ENTRIES=(skills workflows guides patterns hooks scripts CLAUDE.md)`, so `scripts/` is linked to `~/.claude/scripts/`.

**Evidence:** `devcontainer-config/link-claude-home.sh:43-50`, `devcontainer-config/install.sh:125-135`

---

## Claim 64: "It is read-only."

**Location:** `skills/dev-cycle/SKILL.md:66`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the working tree and index of the repo it ran in. It does not cover the temp file outside the repo (`mktemp`, removed by `trap … EXIT`, `scripts/dev-cycle.sh:157`).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r2+r3: one temp file (`qs_err="$(mktemp)"; trap 'rm -f "$qs_err"' EXIT`) outside the repo

`git status --short` in wt-devcycle was the same before and after a run. The header says `Read-only: writes nothing to the repo (one temp file, removed on exit)` (`:18`).

**Evidence:** `scripts/dev-cycle.sh:18,157`, `$S2/digest-wt-devcycle.md`

---

## Claim 65: "Its sections feed the steps: 1 activity (context), 2 triggers (step 2), 3 watched questions (step 3), 4 spot-check sample and 6 merges with code but no docs (step 4), 5 roadmap (step 6), 7 inputs (steps 4b and 5)."

**Location:** `skills/dev-cycle/SKILL.md:66-68`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers section numbers and titles. It does not establish what each step does with them.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: "does not cover section 5 printing only the roadmap's Next section (`scripts/dev-cycle.sh:191-193`), although step 6 updates every section"

Headings: `## 1. Activity` (`:113`), `## 2. Revisit triggers` (`:125`), `## 3. Watched questions (trigger and deferred routes)` (`:153`), `## 4. Spot-check sample` (`:178`), `## 5. Roadmap` (`:188`), `## 6. Merges with code but no docs` (`:198`), `## 7. Inputs for steps 4b and 5` (`:216`).

**Evidence:** `scripts/dev-cycle.sh:113-216`

---

## Claim 66: "If the repo has no `docs/working/questions.md`, run `~/.claude/scripts/questions.sh init` first."

**Location:** `skills/dev-cycle/SKILL.md:68-69`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the subcommand existing and creating the file. It does not cover `questions.sh` refusing symlinked targets.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=—
**Replicate annotations:** none

`scripts/questions.sh:447`: `init)    cmd_init ;;`; comment "Create whichever of the two files is missing" (`:416-418`).

**Evidence:** `scripts/questions.sh:416-447`

---

## Claim 67: "If the window starts before the last cycle you know ran (or says no cycle record was found when one ran), that cycle skipped step 7 … rerun with `--since` set to that cycle's date."

**Location:** `skills/dev-cycle/SKILL.md:69-72`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the digest's source note and `--since` override. It does not cover future-dated records, which the digest ignores (`scripts/dev-cycle.sh:96`).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: future-dated records are ignored (`:96`)

Source note: `"no cycle record found, so the default of 14 days …"` or `"the last cycle record, docs/working/cycles/cycle-$last_record.md"` (`:101-104`). Test 9 and a no-record run print it.

**Evidence:** `scripts/dev-cycle.sh:92-105`, `$S2/digest-wt-devcycle.md`, `$S2/bats-28c6178.txt`

---

## Claim 68: "If the digest fails (non-zero exit or a missing section), stop the cycle … write **no** cycle record"

**Location:** `skills/dev-cycle/SKILL.md:74-76`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a mid-digest failure being observable both ways. It does not cover a digest that exits 0 with a section whose content is wrong.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r3: does not establish that every mid-digest failure leaves a section missing · r2: does not cover an exit-0 digest with wrong section content

A forced `shuf` failure gave exit 7 with only 4 `## ` headings, so both detection signals fire. The header promises "a failed step exits non-zero mid-digest" (`scripts/dev-cycle.sh:19-20`), and Claim 11 shows the re-exec keeps that status.

**Evidence:** `scripts/dev-cycle.sh:19-20`, `:41-44`, `$S2/probe1.out`

---

## Claim 69: Step 1 — "`scripts/health-check.sh` in claude-workflows"

**Location:** `skills/dev-cycle/SKILL.md:80-82`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers the existence of the named artifact. It does not establish whether health-check is green today.
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=Verified (compound)
**Replicate annotations:** none

`scripts/health-check.sh` exists.

**Evidence:** `scripts/health-check.sh`

---

## Claim 70: "triage them as pr-prep step 5a does (caused by recent work, pre-existing, flaky)"

**Location:** `skills/dev-cycle/SKILL.md:83-84`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the reference target. It does not cover pr-prep's re-run procedure details.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** none

`workflows/pr-prep.md:315`: "**a. Verify CI passes (automated).**" under "#### 5. Verify and annotate"; classes "Caused by this branch | … Pre-existing on main | … Flaky / infra / environmental" (`:341-343`).

**Evidence:** `workflows/pr-prep.md:311-353`

---

## Claim 71: "`~/.claude/scripts/questions.sh archive` then `index`, so answered entries leave the live file."

**Location:** `skills/dev-cycle/SKILL.md:85-86`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the subcommands existing. It does not cover redundancy: `cmd_archive` already calls `cmd_index` (`scripts/questions.sh:393`).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: `cmd_archive` already calls `cmd_index`, so the `index` step is redundant

`index)   cmd_index ;;` / `archive) cmd_archive ;;` (`scripts/questions.sh:449-450`).

**Evidence:** `scripts/questions.sh:374-393`, `:445-452`

---

## Claim 72: Step 1 — "Skip any branch or worktree an open handoff brief (`docs/working/handoffs/`) names"

**Location:** `skills/dev-cycle/SKILL.md:88-90`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the path matches where step 6 writes briefs. It does not establish that the directory exists yet (it does not).
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** r2: `docs/working/handoffs/` does not exist yet

Step 6 writes "a build brief at `docs/working/handoffs/<date>-<slug>.md`" (`:193`).

**Evidence:** `skills/dev-cycle/SKILL.md:88-90`, `:193`

---

## Claim 73: "Do not run `archive-working-docs.sh`: it serves the self-improvement loop and moves files into a gitignored archive."

**Location:** `skills/dev-cycle/SKILL.md:91-93`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the script header and gitignore. It does not cover its dry-run mode.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** none

"Archive docs/working/ artifacts from a completed self-improvement run. … Moves all non-permanent files from docs/working/ into docs/working/archive/" (`scripts/archive-working-docs.sh:2-6`); `.gitignore:16:docs/working/archive/`.

**Evidence:** `scripts/archive-working-docs.sh:2-12`, `.gitignore:16`

---

## Claim 74: Step 1 — deleting merged branches "needs the user's approval"

**Location:** `skills/dev-cycle/SKILL.md:80-93`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence and behaviour of each named target. Does not run them.
**Replicate verdicts:** r1=— · r2=— · r3=Verified (compound) · single-replicate detection
**Replicate annotations:** none

The global instructions require approval for "deleting branches" (`global-instructions/CLAUDE.md:220`).

**Evidence:** `global-instructions/CLAUDE.md:220`

---

## Claim 75: Step 2 — "The digest prints every trigger in full"

**Location:** `skills/dev-cycle/SKILL.md:98`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each phrase against the digest's output strings.
**Replicate verdicts:** r1=— · r2=— · r3=Verified (compound) · single-replicate detection
**Replicate annotations:** none

The digest prints records as `"### ${f//$'\n'/ } (last committed ...)"` and log rows as `"- log row $n ($d): > $text"` (`scripts/dev-cycle.sh:136`, `:148`). Tests 3 and 9 pass.

**Evidence:** `scripts/dev-cycle.sh:125-151`, `$S3/bats-A.log`

---

## Claim 76: Step 3 — "if it clears step 1's bar (mechanical, small, one commit)"

**Location:** `skills/dev-cycle/SKILL.md:111-112`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the cross-reference wording only.
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r2 (compound): the approval doc's step 3 row says "one that clears step 1's bar (mechanical, small, one commit) is done in-cycle, at most 3, oldest first" · r3: the approval doc's step 3 row uses the same parenthetical

Step 1's bar is "Fix what is mechanical now, one commit per concern. File the rest." (`SKILL.md:94`). "Small" is not in step 1. Precise version: "(mechanical, one commit)", or add "small" to step 1.

**Evidence:** `skills/dev-cycle/SKILL.md:94`, `:111-112`

---

## Claim 77: Step 3 — "One opened before the last cycle record is stale and gets an action now: … do it in-cycle, at most 3 per cycle, oldest first"

**Location:** `skills/dev-cycle/SKILL.md:111-115`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with commit c079e8c and the approval doc. It does not cover how "opened" is read (the entry's `**Opened:**` field, which the digest does not print).
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** r2: the digest does not print the entry's `**Opened:**` field

The approval doc's step 3 row says "one that clears step 1's bar (mechanical, small, one commit) is done in-cycle, at most 3, oldest first".

**Evidence:** `skills/dev-cycle/SKILL.md:106-116`, claude.ai artifact 78a2f851-e696-4a86-bfe8-474212e5e645

---

## Claim 78: "If the digest says `questions.sh open` failed, fix that first; the section was not checked."

**Location:** `skills/dev-cycle/SKILL.md:116`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the digest's failure text. It does not cover a `questions.sh` that is missing entirely, which prints "No docs/working/questions.md (or questions.sh)".
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified (compound)
**Replicate annotations:** none

`scripts/dev-cycle.sh:170`: `echo "**questions.sh open failed** — watched questions were NOT checked. Its error:"`. Test 15 passes.

**Evidence:** `scripts/dev-cycle.sh:156-176`, `$S2/bats-28c6178.txt`

---

## Claim 79: "Also check every merge the digest lists under 'Merges with code but no docs'" (the fourth rule)

**Location:** `skills/dev-cycle/SKILL.md:123-124`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the section name. It does not cover merges past the cap of 30, which are counted, not listed (`scripts/dev-cycle.sh:213`).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2+r3: section 6 lists at most 30 merges ("… N more" beyond that), so "every merge the digest lists" is not every flagged merge

`scripts/dev-cycle.sh:198`: `"## 6. Merges with code but no docs"`; the fourth rule is `**Undocumented is broken.**` (`SKILL.md:35`).

**Evidence:** `scripts/dev-cycle.sh:198-214`

---

## Claim 80: 4b — "Its triggers, from the digest's section 7 and the last record"; "the model running this cycle differs from the last record's `Model:` line"

**Location:** `skills/dev-cycle/SKILL.md:133-137`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the inputs. It does not cover quoted-name omissions in section 7 (Claim 18), or whether "substantially changed" can be judged from a file list.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: readiness, "substantially changed" and "major design decision" are judgment calls; the digest supplies only raw counts and lists · r2: quoted-name omissions in section 7

The digest prints `"Step 4b (deep-audit triggers). The model version is not in git: compare it with the last cycle record's."` (`scripts/dev-cycle.sh:225`) and the two lists. The record template has `Model: <the model id running this cycle>` (`skills/dev-cycle/SKILL.md:205`).

**Evidence:** `scripts/dev-cycle.sh:225-233`, `skills/dev-cycle/SKILL.md:205`, `$S2/digest-wt-devcycle.md`

---

## Claim 81: "it runs only when one of these holds (inputs: the digest's section 7): roadmap Now + Next hold 0–1 items ready for 6b; …"

**Location:** `skills/dev-cycle/SKILL.md:146-148`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what section 7 supplies and the meaning of "ready for 6b". The seed-log path problem is Claim 61.
**Replicate verdicts:** r1=Verified (compound) · r2=Mostly accurate · r3=—
**Replicate annotations:** r1 (compound): step 5's inputs (Roadmap Now/In flight/Next counts, last brainstorm with days ago, ideas seeded since) are at `scripts/dev-cycle.sh:237-256`; readiness is a judgment call the digest supplies only raw counts for

Section 7 supplies item counts per section (`scripts/dev-cycle.sh:237-239`), not readiness. Two of the five conditions (a fired trigger, the user asks) do not come from section 7. Only Now items can be handed to 6b ("Take the Now items whose first step needs no open choice", `skills/dev-cycle/SKILL.md:190`), so a Next item is never "ready for 6b". Precise version: "Now holds 0–1 items ready for 6b (section 7 gives the counts; readiness is judged)".

**Evidence:** `skills/dev-cycle/SKILL.md:146-152`, `:190`, `scripts/dev-cycle.sh:235-243`

---

## Claim 82: "e.g. the self-improvement loop's `docs/working/feature-ideas*.md` in claude-workflows"

**Location:** `skills/dev-cycle/SKILL.md:156`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the path exists. It does not cover the files' format.
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** none

`docs/working/feature-ideas.md` exists.

**Evidence:** `docs/working/feature-ideas.md`

---

## Claim 83: "A choice among 3+ approaches is flagged for `divergent-design`"; 6b "(`research-plan-implement`)"

**Location:** `skills/dev-cycle/SKILL.md:158`, `:229`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the named workflows exist. It does not cover how a build loop is launched (subagent or session).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** none

`workflows/divergent-design.md` and `workflows/research-plan-implement.md` exist, as do their router skills.

**Evidence:** `workflows/divergent-design.md`, `workflows/research-plan-implement.md`

---

## Claim 84: Roadmap template headings "## Now / ## In flight / ## Next / ## Ideas / ## Done"

**Location:** `skills/dev-cycle/SKILL.md:164-177`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exact-match headings the digest counts and prints. It does not cover heading variants a user might type (e.g. `## In Flight`, which would count 0).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: a variant like `## In Flight` would count 0 · r1+r3: none of the cycle-written paths (handoffs, cycles, idea log, roadmap, sources) is gitignored

The digest matches `## Now`, `## In flight` and `## Next` exactly (`scripts/dev-cycle.sh:237-238`), and `/^## Next/` for section 5 (`:193`). Test 20 checks all three counts.

**Evidence:** `scripts/dev-cycle.sh:193`, `:237-238`, `docs/roadmap.md:13-20`, `$S2/digest-wt-devcycle.md`

---

## Claim 85: Handoff queue — briefs written in step 6, "Both land with step 7, so the briefs are on the default branch before any loop starts"; 6b "Runs after step 7 has landed"

**Location:** `skills/dev-cycle/SKILL.md:190-196`, `:228`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers internal consistency of landing order (step 6 writes, step 7 lands, 6b launches). It does not establish what happens when pr-prep in step 7 does not merge, a case the skill does not address.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: the skill does not address pr-prep in step 7 failing to merge · r1: does not establish that pr-prep's landing succeeds

Flow: `6 roadmap → 7 close (lands the branch) → 6b handoff → final message` (`:53`); step 7: "land … through `pr-prep` before step 6b" (`:223-224`).

**Evidence:** `skills/dev-cycle/SKILL.md:51-54`, `:190-196`, `:220-229`

---

## Claim 86: "at most 3 loops in flight at once, counting earlier cycles'"; "Under /active the user confirms this queue now; under /away it stands."

**Location:** `skills/dev-cycle/SKILL.md:191-193`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the approval doc and the commit Notes. It does not establish a mechanical count: the digest counts In flight items (`scripts/dev-cycle.sh:237-239`), and nothing removes a finished item until the next cycle (`:231-232`).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r2: the cap is counted by hand from the roadmap's In flight section, not enforced mechanically · r2: nothing removes a finished item until the next cycle

The approval doc's 6b row says "At most 3 loops are in flight at once, counting earlier cycles'" and "Under /active you confirm the queue before launch; under /away it launches."

**Evidence:** `skills/dev-cycle/SKILL.md:190-196`, `:231-232`, claude.ai artifact 78a2f851-e696-4a86-bfe8-474212e5e645

---

## Claim 87: "Write `docs/working/cycles/cycle-YYYY-MM-DD.md` (if one exists for today, update it in place)"

**Location:** `skills/dev-cycle/SKILL.md:200`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the name the digest globs. It does not cover names with a suffix (e.g. `cycle-2026-10-01b.md`), which the digest would ignore.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=—
**Replicate annotations:** r2: suffixed names would be ignored

The digest globs `docs/working/cycles/cycle-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md` (`scripts/dev-cycle.sh:93`). Test 9 passes.

**Evidence:** `scripts/dev-cycle.sh:92-101`, `$S2/bats-28c6178.txt`

---

## Claim 88: Template verdict names "docs/decisions/014-secure-tool-guidance-layers.md" and "log row 62"; "Record one verdict for every trigger, under the name the digest prints."

**Location:** `skills/dev-cycle/SKILL.md:214-220`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the names matching real digest output. It does not cover the date suffix the digest appends (`(last committed …)`, `(2026-09-28)`), which the template drops.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: the template drops the digest's date suffix

The digest printed `### docs/decisions/014-secure-tool-guidance-layers.md (last committed on this branch: 2026-09-26)` and `- log row 62 (2026-09-28): > Revisit if …`.

**Evidence:** `scripts/dev-cycle.sh:136`, `:148`, `$S2/digest-wt-devcycle.md`

---

## Claim 89: "The next digest starts its window from this file's date (only the file name is read)"

**Location:** `skills/dev-cycle/SKILL.md:220-221`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the digest at 28c6178. It does not cover future-dated names, which are ignored.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r2: future-dated names are ignored · r3 (Claim 10): with a symlinked parent the name is still read from outside the checkout (merged Claim 13)

The date comes from the name: `d="${f##*/cycle-}"; d="${d%.md}"` (`scripts/dev-cycle.sh:95`); the file is never opened (`:93-97`). Test 3 writes a `Main at:` body and the digest does not echo it.

**Evidence:** `scripts/dev-cycle.sh:92-101`, `test/scripts/dev-cycle.bats:66-78`

---

## Claim 90: "if a cycle skips its record, the next window silently widens, so never skip it."

**Location:** `skills/dev-cycle/SKILL.md:221-222`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether the digest discloses the widened window. It does not judge the advice.
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=— · single-replicate detection
**Replicate annotations:** none

The window does widen, but the digest names its source: `"the last cycle record, docs/working/cycles/cycle-$last_record.md"` or `"no cycle record found, so the default of 14 days (the previous cycle, if any, did not write its record)"` (`scripts/dev-cycle.sh:101-104`). Step 0 relies on that note (`skills/dev-cycle/SKILL.md:69-72`). Precise version: "widens, and only step 0's check of the Window line catches it".

**Evidence:** `scripts/dev-cycle.sh:98-105`, `skills/dev-cycle/SKILL.md:69-72`

---

## Claim 91: "land `chore/dev-cycle-<date>` on the default branch through `pr-prep` before step 6b: the next digest and the build loops both start from the default branch."

**Location:** `skills/dev-cycle/SKILL.md:222-224`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** This covers what the digest reads from the default branch versus the working tree. It does not evaluate the landing procedure.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Verified (compound)
**Replicate annotations:** r2: "landing is necessary but not sufficient"; precise version "… the next digest (run on an up-to-date default-branch checkout) and the build loops …" · r3 (compound): verified the internal order 6 → 7 → 6b

The digest walks the default branch for sections 1, 4, 6 and 7 (`git log "$MAIN_SHA"`, `scripts/dev-cycle.sh:117,221`). The window start (the cycle-record glob, `:93`), the triggers, questions, roadmap and idea log come from the working tree the digest runs in, as the Window line says (`:110`). The landing order is right in practice, because the next cycle's branch is created from the default branch (`SKILL.md:26`). More precisely: "the next cycle's branch, whose working tree the digest reads, and the build loops both start from the default branch".

**Evidence:** `scripts/dev-cycle.sh:93,110,117,221`, `skills/dev-cycle/SKILL.md:25-27,222-224`

---

## Claim 92: Commit c079e8c — "The skill now matches 'Dev cycle skill — for your approval' (2026-10-01) and the digest after the carry-forward cut (Q-101 [1])"

**Location:** commit `c079e8c` message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** This covers a step-by-step comparison of the skill with the approval doc (read through the Claude Docs connector, rev 48). It does not cover the doc's free-text comment threads.
**Replicate verdicts:** r1=Mostly accurate · r2=— · r3=Mostly accurate (headline atom of compound)
**Replicate annotations:** r3: the doc's sources draft uses `docs/feature-ideas*.md` ("one idea per `##` heading"), while the committed sources file uses `docs/working/feature-ideas*.md`; the commit's "Also:" list omits the row 67 edit; precise version "matches the doc except as noted", with the sources path noted · r1+r3: the doc's 6b row moves items to In flight at launch, while the skill moves them at step 6 (implied by the Notes, not stated)

Steps 0–7, 4b and 6b, the four rules, the thresholds and the 8 gaps all match. The commit's Notes disclose one deviation (briefs written in step 6). Undisclosed: the doc says that without a sources file "step 5 looks for a backlog and records which file it used", but the skill has no record-the-file instruction (`else its own idea backlog wherever it keeps one`, `skills/dev-cycle/SKILL.md:155-156`); and the doc moves an item to In flight when its loop starts after step 7, while the skill moves it in step 6 (`move the item to In flight, linking the brief`, `:195`).

**Evidence:** `skills/dev-cycle/SKILL.md:155-156,190-196`, `docs/dev-cycle-sources.md:8`, Claude Docs doc 78a2f851-e696-4a86-bfe8-474212e5e645 rev 48

---

## Claim 93: Commit c079e8c bullet list — no `Main at:`/carried verdicts; record names the model; four rules; seeding to the seed log `docs/dev-cycle-sources.md` names; 2/3/4/4b parallel; thresholds "(0-1 ready items, 10+ seeds, a week by date)"; step 3 stale agent entries (at most 3); roadmap In flight; step 6 writes briefs; step 7 lands via pr-prep; 6b at most 3 in flight; final message last

**Location:** commit `c079e8c` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers each bullet against the committed files (`git diff --quiet c079e8c -- skills/dev-cycle/SKILL.md` shows no later change) and Q-101's answer text. The seed-log wiring problem is Claim 61, and "matches the doc" is Claim 92.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (atom of compound; r3 Claim 44's Verdict is Mostly accurate, carried by Claim 92)
**Replicate annotations:** r2: "does not cover the digest-side gap for the non-default seed log" · r3: 6ee33e3 had three rules (Attention, Repo text, Commits and branches)

- `rg -i 'Main at|carried|carry'` matches only `each carrying the evidence-not-instructions brief` (`SKILL.md:57`).
- `Model:` is at `:205`; four `- **…**` rules at `:20-39`.
- Q-101's answer: `step 5 thresholds tightened (0–1 ready items, 10+ ideas, a week by date)` (`questions-archive.md:1830`).
- Step 3: `at most 3 per cycle, oldest first` (`:113`); `## In flight` added (`docs/roadmap.md:18`); the final message at `:234-235`.

**Evidence:** `skills/dev-cycle/SKILL.md:20-60,108-115,190-235`, `docs/roadmap.md:18`, `docs/working/questions-archive.md:1817-1835`

---

## Claim 94: Commit c079e8c — "All 8 double-diamond gaps applied, incl. the digest failure path."

**Location:** commit `c079e8c` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Same as Claim 48. Note that `docs/working/questions-archive.md` (Q-101's answer) still says "double-diamond gaps #1, #2, #4–8 still await the user". The approval doc later records them as applied; that archive line is outside this diff.
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** r2: the Q-101 answer in `questions-archive.md` still says "double-diamond gaps #1, #2, #4–8 still await the user" (outside this diff)

See Claim 48; the failure path is at `skills/dev-cycle/SKILL.md:74-76`.

**Evidence:** `skills/dev-cycle/SKILL.md:74-76`, claude.ai artifact 78a2f851-e696-4a86-bfe8-474212e5e645

---

## Claim 95: Commit c079e8c — "Also: decision log row 68, global decision-tree row 12, the skill-creation guide row, the roadmap's In flight section, and docs/dev-cycle-sources.md for this repo."

**Location:** commit `c079e8c` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each listed change being in the diff. It does not cover completeness: the commit also edits decision log row 67 (the Q-099 wording, Claim 41), which the list does not name.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (atom of compound)
**Replicate annotations:** r2+r3: the "Also:" list omits the decision log row 67 edit

`git diff --stat 6ee33e3..c079e8c` touches exactly these 6 files.

**Evidence:** `docs/decisions/log.md:90-91`, `docs/dev-cycle-sources.md`, `docs/roadmap.md:18`, `global-instructions/CLAUDE.md:32`, `guides/skill-creation.md:137`

---

## Claim 96: Commit c079e8c Notes — "brief-writing moved from 6b into step 6 so briefs land with the cycle branch … (the doc said 6b writes briefs; the landing-order fix required the move). The /active confirmation therefore happens at step 6."

**Location:** commit `c079e8c` message
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the doc's 6b row and the skill's step 6. It does not cover the Rules line that still attributes the briefs to 6b (Claim 58).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (atom of compound)
**Replicate annotations:** r2: the Rules line (`SKILL.md:22-23`) still attributes the briefs to 6b (Claim 58)

The approval doc's 6b row says "Per item, a build brief at `docs/working/handoffs/<date>-<slug>.md` …". The skill's step 6 says "Under /active the user confirms this queue now; … For each queued item, write a build brief" (`skills/dev-cycle/SKILL.md:192-193`).

**Evidence:** `skills/dev-cycle/SKILL.md:190-196`, claude.ai artifact 78a2f851-e696-4a86-bfe8-474212e5e645

---

## Claims Requiring Attention

### Incorrect
- **Claim 5** (`scripts/dev-cycle.sh:27-29`): "pinned to bytes" is refuted. `PERLIO=:utf8` makes the scrub pass C1 CSI and RLO through the whole digest. Add `-u PERLIO` (and to test 5's env loop) or narrow the claim. (r1, r3; r2 did not probe PERLIO.)
- **Claim 29** (commit `26b7590`, R1/A1): "scrub pins perl to bytes" — the same refutation as Claim 5.
- **Claim 32** (commit `26b7590`, A5): "perl autoflushes, so stream order follows the body" is false. Two filters give no cross-stream order (r1 10/10, r2 3/3, r3 20/20 runs misordered); each stream keeps only its own order.
- **Claim 37** (commit `26b7590`): "shellcheck clean" was false for the bats file (SC2034, which failed the gate). 28c6178 fixed it, so this is history-only.
- **Claim 56** (`guides/skill-creation.md:137`): no Operating Modes rule covers "any launch". The handoff-queue confirmation is the skill's own step-6 rule, and Operating Modes approvals for commits and merges also apply mid-run. (r1, r3; r2 Verified.)
- **Claim 61** (`skills/dev-cycle/SKILL.md:41-44,159-160`): a seed log configured through `docs/dev-cycle-sources.md` is never read by the digest (`LOG=docs/working/idea-log.md`, `scripts/dev-cycle.sh:244`), so "the next digest counts seeds from here" fails in any repo with a non-default seed log. Harmless in claude-workflows today.

### Stale
- **Claim 42** (`docs/decisions/log.md:90`): row 67, edited in c079e8c, still lists the roadmap as Now/Next/Ideas/Done and omits 4b and 6b, with no pointer to row 68. (r3 only.)

### Mostly Accurate
- **Claim 7** (`scripts/dev-cycle.sh:31-32`): the "Not covered" list omits other lone C1 bytes, overlong encodings, U+061C and U+2028/2029.
- **Claim 8** (`scripts/dev-cycle.sh:31-32`): "inert on a UTF-8 terminal" — Mostly accurate only via the compound verdict; r1 rated this atom Unverifiable (needs runs on target terminals).
- **Claim 10** (`scripts/dev-cycle.sh:38-39`): fd 3 takes the outer pipe first, not "then", and the inner scrub inherits fd 3.
- **Claim 13** (`scripts/dev-cycle.sh:64-67`): the cycle-record name, a date only, is still read through a symlinked parent outside the checkout. (r3 only.)
- **Claim 18** (`scripts/dev-cycle.sh:217-219`): git-quoted names reach `changed` but the grep filters drop them.
- **Claim 28** (`test/scripts/dev-cycle.bats:291-292`): the "changed and reverted" comment sits on `skills/demo/tmp.md`, which no assertion can observe.
- **Claim 33** (commit `26b7590`, A4): in-repo symlinks are followed; only links out of the checkout are skipped.
- **Claim 35** (commit `26b7590`, A8): "lists every file" — same quoted-name residue as Claim 18.
- **Claim 40** (commit `28c6178` subject): the first list's field is now discarded and the expectations restated in a second list.
- **Claim 49** (`docs/decisions/log.md:91`): the thresholds are the skill's steps 4b and 5, fed by section 7, not "section 7's".
- **Claim 58** (`skills/dev-cycle/SKILL.md:22-23`): lists 6b as a brief-writing step; step 6 writes the build briefs and its field list omits the evidence-not-instructions line.
- **Claim 76** (`skills/dev-cycle/SKILL.md:111-112`): step 1's bar does not include "small".
- **Claim 81** (`skills/dev-cycle/SKILL.md:146-148`): only Now items can be handed off; section 7 gives counts, not readiness; two of five conditions are not section 7 inputs.
- **Claim 90** (`skills/dev-cycle/SKILL.md:221-222`): "silently widens" — the digest's Window line names the record or the 14-day fallback.
- **Claim 91** (`skills/dev-cycle/SKILL.md:222-224`): the window start, triggers, questions, roadmap and idea log come from the working tree where the digest runs.
- **Claim 92** (commit `c079e8c`): undisclosed deviations from the approval doc (missing "records which file it used", In flight move at step 6, sources path/format differs from the doc's draft, "Also:" omits row 67).

### Unverifiable
- **Claim 50** (`docs/decisions/log.md:91`): the row 68 rationale attributes points to the user's doc comments; checking needs the comment threads (`query` on the doc). The doc body has matching prose.

---

## Escalations

No replicate's Goal-Alignment note carried an `Escalate:` bullet or a critic-naming `Out of scope:` bullet. The entries below collect escalation-shaped notes from claim prose and the replicates' advisory sections; none names a critic, so all are addressed to `orchestrator`.

- `scripts/dev-cycle.sh:31-32` — r1 — orchestrator: "inert on a UTF-8 terminal" needs runs on the target terminal emulators (xterm, VS Code, Windows Terminal) in UTF-8 mode (Claim 8).
- `docs/decisions/log.md:91` — r2+r3 — orchestrator: verify the row 68 rationale by querying the approval doc's comment threads (Claude Docs `query`) for the 2026-10-01 user comments (Claim 50).
- `scripts/dev-cycle.sh:219-224` — r1+r2+r3 — orchestrator: section 7 silently drops git-quoted names (control characters, or any non-ASCII path under the default `core.quotePath`) from its skill and decision-record counts (r1 "Residues worth a reviewer's eye"; r3 "Adjacent observation"; r2 Claim 14; merged Claims 18, 19, 35).
- `scripts/dev-cycle.sh:205` — r1 (residues list; r2+r3 in scope lines) — orchestrator: `*.md` and `docs/` matching is case-sensitive (`NOTES.MD`, `Docs/` count as code) (Claim 16).
- `test/scripts/dev-cycle.bats:122-128` — r1+r2+r3 — orchestrator: test 7 passes on db0e5ca too, so it does not discriminate the A5 fix (Claims 9, 25).
- `scripts/dev-cycle.sh:41-44` — r1+r2+r3 — orchestrator: `| head` gives exit 141, and it cannot be told whether that is the body's status or a scrub's (Claim 11).
- `scripts/dev-cycle.sh:27-34` — r3 — orchestrator: prior final-pass-4 findings R1 and A1 are reopened by `PERLIO` (r3 Goal-Alignment: "R1 is closed for split and nested sequences but reopened by `PERLIO`"; "A1 is partly closed (`PERLIO` remains)") (Claims 5, 29).
- `skills/dev-cycle/SKILL.md:41-44` / `scripts/dev-cycle.sh:244` — r2 — orchestrator: prior finding A2 (section 7 / step 5 contract) is "closed for the default seed-log path only" (r2 closure check; Claim 61).
- `scripts/dev-cycle.sh:93-97` — r3 — orchestrator: prior finding A4 is closed "except the cycle-record names", which are still read through a symlinked parent (r3 Goal-Alignment; Claim 13).

---

## Verdict stability

- **Total clusters:** 96 (merged claim rows at finest granularity).
- **Multi-replicate clusters:** 80. **Single-replicate clusters:** 16 (Claims 2, 3, 20, 40, 42, 57, 58, 59, 62, 72, 74, 75, 77, 82, 90, 94; by replicate: r1 3, r2 9, r3 4 — note r2 surfaced 80 claims against 47 each for r1 and r3).
- **All reporting replicates agreed:** 68 of 80 multi-replicate clusters. Agreement counts a compound verdict as that replicate's verdict on the row, except where the replicate's own text gave an explicit per-atom verdict (Claims 31, 39, 93, 95, 96), where the atom verdict is used.
- **Verdicts disagreed (12):**
  - Claim 5: r1=Incorrect · r2=Verified (compound) · r3=Incorrect
  - Claim 8: r1=Unverifiable · r2=Mostly accurate (compound) · r3=Mostly accurate (compound)
  - Claim 10: r1=Verified (compound) · r2=Verified · r3=Mostly accurate
  - Claim 13: r1=Verified · r2=Verified · r3=Mostly accurate
  - Claim 18: r1=Verified · r2=Mostly accurate · r3=Verified
  - Claim 28: r1=Verified (compound) · r2=Mostly accurate · r3=Verified (compound)
  - Claim 29: r1=Incorrect · r2=Verified (compound) · r3=Incorrect
  - Claim 35: r1=Verified (compound) · r2=Mostly accurate · r3=Verified (compound)
  - Claim 56: r1=Incorrect · r2=Verified · r3=Incorrect
  - Claim 76: r1=— · r2=Verified (compound) · r3=Mostly accurate
  - Claim 81: r1=Verified (compound) · r2=Mostly accurate · r3=—
  - Claim 91: r1=Mostly accurate · r2=Mostly accurate · r3=Verified (compound)
- **Agreement rate:** 68/80 = 85.0% of multi-replicate clusters (84/96 = 87.5% if single-replicate clusters are counted as agreeing). Below the ≥90% falsifier threshold in `skills/code-review/SKILL.md` step 5; k=3 stands. Severity-changing disagreements (a replicate below the merged verdict): all 12; on Incorrect clusters, 3 of 6 (Claims 5, 29, 56) had one replicate at Verified.
