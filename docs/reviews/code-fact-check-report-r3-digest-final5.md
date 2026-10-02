Commit: 28c6178 (A) / c079e8c (B)

# Code Fact-Check Report

**Repository:** claude-workflows — A: `/workspace/.claude/wt-digest` (feat/dev-cycle-digest @ 28c6178); B: `/workspace/.claude/wt-devcycle` (feat/dev-cycle @ c079e8c)
**Scope:** Final pass 5 (delta confirming pass, partial scope). A: `git diff db0e5ca..28c6178 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` and commit messages 26b7590, 28c6178. B: `git diff 6ee33e3..c079e8c -- skills/dev-cycle/SKILL.md docs/decisions/log.md docs/roadmap.md guides/skill-creation.md global-instructions/CLAUDE.md docs/dev-cycle-sources.md` and commit message c079e8c. Also the A↔B contract (digest sections, line formats and paths the skill relies on; formats the skill writes that the digest reads). Everything else on both branches is context only.
**Checked:** 2026-10-01 (executions 2026-10-02T03:09Z–03:16Z UTC)
**Total claims checked:** 47 (44 numbered; 21, 22 and 33 split into a/b)
**Summary:** 31 verified, 8 mostly accurate, 1 stale, 6 incorrect, 1 unverifiable

Execution logs are in `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc5-r3/` (shortened to `$FC/` below). Every probe ran under `timeout` in a `mktemp -d` dir below `$FC/`. Nothing was written into either worktree except this report. Hallucination-pattern log: read. No claim matches a logged pattern. The test-count claims ("20/20") belong to the logged "specific measured value" class, and they were re-counted and hold. No new pattern qualifies (no Incorrect verdict is a fabricated symbol), and the brief forbids worktree writes, so the log is unchanged.

Baseline runs used by several claims:
- **Suite on A.** `timeout 300 bats test/scripts/dev-cycle.bats`, cwd `/workspace/.claude/wt-digest`, 2026-10-02T03:09:40Z. Exit 0, 20/20 ok. Output: `$FC/bats-A.log`.
- **New tests on old code.** The 28c6178 test file was run against db0e5ca's `scripts/dev-cycle.sh` and `questions.sh`, copied into `$FC/old.myBI/`: `timeout 300 bats $FC/old.myBI/test/scripts/dev-cycle.bats`, 2026-10-02T03:09:52Z. Exit 1. Tests 5, 6, 19 and 20 fail; the other 16 pass. Output: `$FC/bats-new-tests-on-db0e5ca.log`.

---

## Claim 1: "--since start of the cycle window: commits whose committer date, in the committer's own time zone (git's %cs), is on or after this date."

**Location:** `scripts/dev-cycle.sh:10-11`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the date filter of sections 1, 4 and 6 (`merges_full`, `commits`) and section 7 (the `@%cs` lines), and shows that the committer's zone, not `TZ`, decides the date. Does not establish author-date behaviour, which no code uses.

The filters compare `%cs` as strings: `merges_full="$(git log "$MAIN_SHA" --first-parent --merges --format='%cs %H %h %ad %s' --date=short | awk -v s="$SINCE" '$1 >= s')"` (`scripts/dev-cycle.sh:117`), `commits=... --format=%cs | awk -v s="$SINCE" '$1 >= s'` (`:120`), and `--format='@%cs'` with `on = (substr($0, 2) >= s)` (`:221-222`).

Probe: a commit dated `2026-01-01T23:30:00-10:00`, which is 2026-01-02 in UTC. Under `TZ=UTC`, `%cs` printed `2026-01-01`. The digest counted 0 commits with `--since=2026-01-02` and 1 with `--since=2026-01-01`, so the committer's own zone decides.

**Evidence:** `scripts/dev-cycle.sh:117`, `:120`, `:221-222`. Command: `TZ=UTC bash scripts/dev-cycle.sh --since=2026-01-0{2,1}`, cwd `$FC/tz.*`, exit 0, 2026-10-02T03:15:34Z. Output: `$FC/tz-probe.log`.

---

## Claim 2: "drops C0 controls but TAB and LF, DEL, C1 controls (U+0080-009F), bidi controls (U+200E/F, U+202A-202E, U+2066-2069) and tag characters (U+E0000-E007F)"

**Location:** `scripts/dev-cycle.sh:25-27`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the byte patterns for exactly the listed ranges, with PERLIO, PERL_UNICODE and PERL5OPT unset. Does not establish that the list is every bidi control (U+061C ARABIC LETTER MARK passes; see Claim 5), and does not cover behaviour under `PERLIO=:utf8` (Claim 3).

The code is `tr/\000-\010\013-\037\177//d; 1 while s/\xC2[\x80-\x9F]|\xE2\x80[\x8E\x8F\xAA-\xAE]|\xE2\x81[\xA6-\xA9]|\xF3\xA0[\x80\x81][\x80-\xBF]//g` (`scripts/dev-cycle.sh:34`). These are the UTF-8 encodings of the listed ranges: U+0080-009F = C2 80..9F, U+200E/F = E2 80 8E/8F, U+202A-202E = E2 80 AA..AE, U+2066-2069 = E2 81 A6..A9, U+E0000-E007F = F3 A0 80 80..F3 A0 81 BF.

The probe removed C1 CSI, LRM, ESC, CR and DEL, and kept TAB. Test 5 also passes.

**Evidence:** `scripts/dev-cycle.sh:34`. Command: `bash $FC/probe-scrub.sh`, cwd `$FC`, exit 0, 2026-10-02T03:10:56Z. Output: `$FC/probe-scrub.log`, first block.

---

## Claim 3: "Perl is pinned to bytes (-C0, and PERL_UNICODE / PERL5OPT removed: either could turn on UTF-8 decoding and switch the byte patterns off)."

**Location:** `scripts/dev-cycle.sh:27-29`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the scrub under the three environment variables that can change perl's I/O layers (PERL_UNICODE, PERL5OPT, PERLIO). Does not establish whether other perl variables (e.g. PERL5LIB) matter.

The scrub removes two variables: `env -u PERL_UNICODE -u PERL5OPT LC_ALL=C perl -C0 -pe '...'` (`scripts/dev-cycle.sh:34`). `PERLIO` is a third variable, and it also turns on UTF-8 decoding. Neither `-C0` nor the `env -u` list overrides it.

With `PERLIO=:utf8` set, the scrub probe returned `61 c2 9b 62` unchanged for C1 CSI and `61 e2 80 8e 62` unchanged for LRM. The nested cases left a reassembled `c2 9b`.

End to end, `PERLIO=:utf8 bash scripts/dev-cycle.sh` in a repo whose decision record holds `a\xc2\x9bb\xe2\x80\xaec` printed `20 61 c2 9b 62 e2 80 ae 63 64` to stdout, with exit 0: a raw C1 CSI and a raw RLO. Without PERLIO the same run printed `abcd`.

`PERL_UNICODE=SDA` and `PERL5OPT=-CSD` are neutralised as the comment says. `PERLIO=:encoding(UTF-8)` did not bypass the scrub in this probe. So the "pinned to bytes" invariant does not hold: an inherited `PERLIO` switches the byte patterns off, which is the same failure class as final pass 4's A1.

**Evidence:** `scripts/dev-cycle.sh:33-35`. Command: `PERLIO=:utf8 bash $FC/probe-scrub.sh`, exit 0, 2026-10-02T03:10:56Z. Output: `$FC/probe-scrub.log`, block "PERLIO=:utf8". Command: `PERLIO=:utf8 timeout 60 bash /workspace/.claude/wt-digest/scripts/dev-cycle.sh`, cwd `$FC/e2e.eJmg/repo`, exit 0, 2026-10-02T03:11:10Z. Output: `$FC/e2e-perlio.log`.

---

## Claim 4: "C0 goes first and the substitution repeats until nothing changes, so neither a control byte inside a sequence nor a nested sequence can reassemble one."

**Location:** `scripts/dev-cycle.sh:29-31`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers sequences within one line, with PERLIO unset. Does not establish behaviour under `PERLIO=:utf8` (Claim 3). A sequence split by LF (`c2 0a 9b`) is not reassembled, but it leaves a lone 0x9B, which is Claim 5's residue.

The order in the code is `tr/.../d;` first, then `1 while s/.../g` (`scripts/dev-cycle.sh:34`). Removing a sequence cannot create a C0 byte, so one `tr` pass before the loop is enough.

Probe outputs: `c2 01 9b` → empty; `c2 c2 9b 9b` → empty; a C0 byte between nested layers, `c2 01 c2 9b 01 9b` → empty; a triple-nested tag sequence → empty. Test 5's split and nested cases pass on 28c6178 and fail on db0e5ca.

**Evidence:** `scripts/dev-cycle.sh:34`. Outputs: `$FC/probe-scrub.log`, `$FC/bats-A.log` (test 5), `$FC/bats-new-tests-on-db0e5ca.log` (test 5 not ok).

---

## Claim 5: "Not covered: a lone 0x9B byte (invalid UTF-8, inert on a UTF-8 terminal) and zero-width characters (cannot start a line)."

**Location:** `scripts/dev-cycle.sh:31-32`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what passes the scrub unchanged in the default environment. Does not establish terminal behaviour, which was not tested on a real emulator.

Both listed items do pass. But the list is narrower than what the scrub leaves through:
- every other lone C1 byte, e.g. 8-bit OSC: `61 9d 35 32 3b ...` passed (only the C0 BEL was removed);
- the overlong encoding `c0 9b` passed;
- U+061C ARABIC LETTER MARK (`d8 9c`), a Unicode Bidi_Control character outside the comment's bidi list, passed.

All of these fall in the same "invalid UTF-8 / inert on a UTF-8 terminal" class, except ALM, which is a valid bidi control. A precise version: "Not covered: lone or overlong C1/C0 bytes (0x80-0x9F alone, C0 xx; invalid UTF-8), U+061C, and zero-width characters."

**Evidence:** `scripts/dev-cycle.sh:34`. Output: `$FC/probe-scrub.log`, rows "lone 9D", "overlong ESC C0 9B", "ALM U+061C", "ZWSP U+200B".

---

## Claim 6: "so the shell waits for both filters before exiting: a redirected digest is complete when the script returns"

**Location:** `scripts/dev-cycle.sh:36-38`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers runs with stdout and stderr redirected to files, where the script returned normally. Does not establish behaviour when the outer process is killed by a signal.

The construct is a pipeline in the foreground: `{ DEV_CYCLE_SCRUBBED=1 bash "${BASH_SOURCE[0]}" "$@" 2>&1 1>&3 3>&- | scrub >&2; } 3>&1 | scrub` (`:42`), followed by `exit "${PIPESTATUS[0]}"` (`:43`). A foreground pipeline returns only after all its members exit.

In 40 consecutive redirected runs, all exited 0 and every last line was the idea-log line (`incomplete=0`). Test 7 passes. As the commit Notes say, it also passes on db0e5ca.

**Evidence:** `scripts/dev-cycle.sh:41-44`. Command: a 40× loop of `bash scripts/dev-cycle.sh > r.md 2>/dev/null` plus a `tail -n 1` check, cwd `$FC/e2e.eJmg/repo`, exit 0, 2026-10-02T03:11:50Z. Output: `$FC/reexec-probes.log`.

---

## Claim 7: "stdout goes to fd 3, stderr takes the inner pipe, then fd 3 takes the outer one."

**Location:** `scripts/dev-cycle.sh:38-39`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the redirection order on `:42`. Does not establish the fd set of the inner `scrub`, which inherits fd 3 and is not closed by `3>&-`.

The final wiring is right: the body's stdout reaches the outer `| scrub`, and its stderr reaches `| scrub >&2`. The order is reversed, though. `3>&1` on the brace group (`} 3>&1 | scrub`, `:42`) is applied when the group starts, before the child's own `2>&1 1>&3 3>&-`. So fd 3 takes the outer pipe first, not "then".

The inner `scrub >&2` also inherits fd 3 (paraphrased — no quote available because the claim concerns an absent `3>&-` on the second pipeline member). It holds the outer pipe open until it exits. This causes no hang in practice (Claim 6 runs).

**Evidence:** `scripts/dev-cycle.sh:42`.

---

## Claim 8: "Exit status: the body's (pipefail; scrub itself does not fail)."

**Location:** `scripts/dev-cycle.sh:39-40`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the success and usage-error exits with both scrubs succeeding. Does not establish the status when a scrub dies of SIGPIPE (e.g. `| head`); under pipefail that status would then be the scrub's.

`set -euo pipefail` (`:22`) is active, so a failing pipeline makes errexit exit with the pipefail status (the rightmost failure). That is the body's status when the scrubs exit 0. The `exit "${PIPESTATUS[0]}"` line (`:43`) is reached only when the pipeline succeeds. Under `PERLIO=:utf8` perl only warns, and the digest still exited 0.

Probes: `--sample=x` → 1, `--bogus` → 1, run outside a repo → 1, normal run → 0, run from a subdirectory with a relative script path → 0. Test 18 (`--since=nope` → 1) passes.

**Evidence:** `scripts/dev-cycle.sh:22`, `:42-43`. Output: `$FC/reexec-probes.log` (2026-10-02T03:11:50Z, cwd `$FC/e2e.eJmg/repo`, exits as listed).

---

## Claim 9: "DEV_CYCLE_SCRUBBED marks the child." (with commit 26b7590 Notes: "an environment that sets it skips the scrub; a repo cannot")

**Location:** `scripts/dev-cycle.sh:40-41`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the guard and its bypass by environment. Does not establish that no tool a user runs (e.g. direnv) sets it from repo content.

The guard is `if [[ -z "${DEV_CYCLE_SCRUBBED:-}" ]]; then` (`:41`). With `DEV_CYCLE_SCRUBBED=1` set, output carried raw `c2 9b`, `e2 80 ae` and `1b` bytes, which confirms the scrub is skipped. The variable is read only from the environment.

**Evidence:** `scripts/dev-cycle.sh:41-42`. Output: `$FC/reexec-probes.log`, block "DEV_CYCLE_SCRUBBED=1".

---

## Claim 10: "A regular file whose real path stays inside the repo: a committed symlink (to the file or a parent directory) must not make the digest print text from outside the checkout."

**Location:** `scripts/dev-cycle.sh:64-67`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every content-read site: decision records `:130`, log.md `:139`, questions.md `:156` (questions.sh `open` reads only `$LIVE`, the same path), roadmap `:189` and `:236`, and the idea log `:245`. Does not cover the cycle-record glob `:93-97`, which reads file names only.

`inrepo() { local r; [[ -f "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" && [[ "$r" == "$ROOT_REAL"/* ]]; }` (`:67`) guards every site that reads file content. `git log -- f` reads history, not files.

The probe linked `docs/decisions` and `docs/working` to directories outside the checkout. Record text from outside was not printed, and an in-repo symlinked roadmap was correctly followed.

However, the window line printed `since 2020-05-05 (from the last cycle record, docs/working/cycles/cycle-2020-05-05.md)`, a file name that exists only outside the checkout. The glob uses `[[ -f "$f" ]]` (`:94`), not `inrepo`. The leaked text is limited to a `YYYY-MM-DD` pattern, but it does move the window. Precise version: "...must not print file *content* from outside the checkout; cycle-record names are still read through a symlinked parent."

**Evidence:** `scripts/dev-cycle.sh:67`, `:93-97`, `:130`, `:139`, `:156`, `:189`, `:236`, `:245`, `scripts/questions.sh:408-413`. Command: the digest in `$FC/p2.*/r2` with symlinked parents, exit 0, 2026-10-02T03:15:04Z. Output: `$FC/inrepo-sec7-probes.log`.

---

## Claim 11: Window line: "Merges, commits and section 7's changed files: those on `$MAIN` at … whose committer date (in the committer's time zone) is on or after $SINCE, filtered after a full walk."

**Location:** `scripts/dev-cycle.sh:110`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers sections 1, 4 and 6 (all built from `merges_full`/`commits`) and section 7. Does not establish anything about triggers or the working-tree sections, which the line separately says come from the working tree.

Section 6 iterates `merges_full` (`:208`), and section 7 walks the full first-parent history and filters by `@%cs` (`:221-222`). The time-zone semantics are as in Claim 1.

**Evidence:** `scripts/dev-cycle.sh:110`, `:117-120`, `:203-208`, `:221-222`. Output: `$FC/tz-probe.log`.

---

## Claim 12: "`--since` stops at the first old-dated commit, so one such commit hid every merge behind it."

**Location:** `scripts/dev-cycle.sh:114-115` (also the test 4 name and comment, `test/scripts/dev-cycle.bats:80-83`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git's `--since` on a first-parent merge walk. Does not establish git's internal slop heuristics for other walk shapes.

Probe repo: three merges, a fast-forwarded 2020-dated commit, then one more merge. `git log --first-parent --merges --since=<today>` printed only `merge 4`. The walk-then-filter form printed all four. Test 4 expects `4 merge(s)` and passes.

**Evidence:** `scripts/dev-cycle.sh:117`, `test/scripts/dev-cycle.bats:80-92`. Command: see `$FC/since-probe.log`, cwd `$FC/since.*`, exit 0, 2026-10-02T03:15:45Z.

---

## Claim 13: "a doc (a path under docs/, a *.md file, or a file named README or README.*, any case): step 4 checks each one (rule: undocumented is broken). Listed up to 30."

**Location:** `scripts/dev-cycle.sh:199-201`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the classifier and the 30 cap. "Any case" applies to README only: `docs/` and `.md` are case-sensitive, as worded. The cap's "… N more" line was read, not executed.

The classifier is `b = tolower($0); sub(/.*\//, "", b); if ($0 ~ /^docs\// || $0 ~ /\.md$/ || b == "readme" || index(b, "readme.") == 1) d++` (`:205`). The output is `printf '%s\n' "${flagged[@]:0:30}"` then `[[ ${#flagged[@]} -le 30 ]] || echo "… $((${#flagged[@]} - 30)) more"` (`:212-213`).

The `rest` field from `read -r _ full rest` holds `%h %ad %s` with `--date=short`, the same as the old `git log -1 --format='%h %ad %s'`. Test 19 (README_gen.sh flagged; README.txt, docs/ and *.md not flagged) passes on A and fails on db0e5ca.

**Evidence:** `scripts/dev-cycle.sh:117`, `:202-214`. Outputs: `$FC/bats-A.log`, `$FC/bats-new-tests-on-db0e5ca.log`.

---

## Claim 14: "Every file any first-parent commit in the window touched (a merge counts its diff against its first parent), not a net diff: a change reverted inside the window still counts."

**Location:** `scripts/dev-cycle.sh:217-219`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `changed` within the pathspec `skills workflows docs/decisions`. Does not establish that every such file reaches the printed 4b lists: quoted names are dropped (Claim 15).

The command is `git log "$MAIN_SHA" --first-parent --diff-merges=first-parent --name-only --format='@%cs' -- skills workflows docs/decisions` (`:221`). Test 20 (an added-then-removed `skills/demo/tmp.md`, and a merged-then-deleted `workflows/flow.md`) passes on A and fails on db0e5ca.

**Evidence:** `scripts/dev-cycle.sh:221-224`, `test/scripts/dev-cycle.bats:286-305`. Outputs: `$FC/bats-A.log`, `$FC/bats-new-tests-on-db0e5ca.log`.

---

## Claim 15: "'@' lines carry each commit's date; git quotes a name holding a control character, so each name is one line."

**Location:** `scripts/dev-cycle.sh:219-220`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one-line-per-name, and that no path line can begin with `@`: every path begins with a pathspec prefix or with `"`. Does not establish that quoted names are counted. They are not.

Raw output for a newline name was `"skills/a\nb/SKILL.md"`, on one line. Downstream, though, `grep -E '^(skills/.*/SKILL\.md|workflows/[^/]*\.md)$'` (`:223`) drops every quoted name. Under git's default `core.quotePath=true` that includes non-ASCII names: the probe changed `skills/café/SKILL.md`, `skills/a\nb/SKILL.md` and `skills/ok/SKILL.md`, and section 7 printed "Skill or workflow files changed … : 1", listing only `skills/ok`.

**Evidence:** `scripts/dev-cycle.sh:221-224`. Command: the digest with `--since=2000-01-01` in `$FC/p2.*/r1`, exit 0, 2026-10-02T03:15:04Z. Output: `$FC/inrepo-sec7-probes.log`.

---

## Claim 16: "The skill's step 5 appends "## Brainstorm YYYY-MM-DD" after reading the log (its ideas go to the roadmap); seeding appends "- " lines after that heading."

**Location:** `scripts/dev-cycle.sh:246-247`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with B's skill text for the default log path. Does not establish the custom seed-log case (Claim 33b).

B's skill says: "Then append `## Brainstorm YYYY-MM-DD` to the idea log, so the next digest counts seeds from here; the surviving ideas go to the roadmap's Ideas" (`skills/dev-cycle/SKILL.md:159-160`). Seeding is "`- <idea> (signal: <what prompted it>)`" (`:41-42`).

**Evidence:** `scripts/dev-cycle.sh:249-250`, `skills/dev-cycle/SKILL.md:41-44`, `:159-160` (wt-devcycle).

---

## Claim 17: test 5 comment "Split by a C0 byte, and nested: neither may reassemble a sequence." and its env loop `"" PERL_UNICODE=SDA PERL5OPT=-CSD`

**Location:** `test/scripts/dev-cycle.bats:98-102`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cases the test builds. Does not establish coverage of `PERLIO` (Claim 3), which the env loop does not include.

The test's fixture is `if g\xc2\x01\x9bh...` and its loop is `for env in "" PERL_UNICODE=SDA PERL5OPT=-CSD`. It passes on A and fails on db0e5ca.

**Evidence:** `test/scripts/dev-cycle.bats:94-109`. Outputs: `$FC/bats-A.log`, `$FC/bats-new-tests-on-db0e5ca.log`.

---

## Claim 18: test name "the exit status and the whole digest survive a redirect to a file"

**Location:** `test/scripts/dev-cycle.bats:122`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers what the test asserts: the redirected run exits 0 (bats fails the test on a non-zero bare command), section 7 is present, and the last line is the idea-log line. The non-zero exit is checked on an unredirected `run`. Does not establish that the test detects truncation (it passes on db0e5ca).

**Evidence:** `test/scripts/dev-cycle.bats:122-128`. Outputs: `$FC/bats-A.log`, `$FC/bats-new-tests-on-db0e5ca.log` (test 7 ok on old code).

---

## Claim 19: test 10 "--since includes commits from the start date itself" / "All commits here are from today: a window starting today counts all of them."

**Location:** `test/scripts/dev-cycle.bats:147-149`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test's fixture, a commit at `T00:00:30` today with `--since=today`. Does not establish anything about time-of-day handling beyond date equality.

**Evidence:** `test/scripts/dev-cycle.bats:147-153`. Output: `$FC/bats-A.log` (ok 10).

---

## Claim 20: test 19 comment "README_gen.sh is code; a README.txt or docs/ alone is a doc." and test 20 comment "Changed and reverted inside the window: still a change."

**Location:** `test/scripts/dev-cycle.bats:272`, `:292`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fixtures each comment introduces. Does not establish other README-like names.

The specs `"readme-like:src/README_gen.sh:flag" "readme-txt:x.sh lib/README.txt:ok" "docs-only:docs/a.txt y.sh:ok"` match the comment. Both tests pass on A and fail on db0e5ca.

**Evidence:** `test/scripts/dev-cycle.bats:270-305`. Outputs: `$FC/bats-A.log`, `$FC/bats-new-tests-on-db0e5ca.log`.

---

## Claim 21a: Commit 26b7590: "R1/A1 (X1): scrub pins perl to bytes (-C0, PERL_UNICODE/PERL5OPT removed)"

**Location:** commit 26b7590 message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 3: covers PERL_UNICODE, PERL5OPT and PERLIO. Does not establish other perl variables.

`PERLIO=:utf8` disables the byte patterns end to end. Raw C1 CSI and RLO reached stdout.

**Evidence:** `scripts/dev-cycle.sh:34`. Output: `$FC/e2e-perlio.log`.

## Claim 21b: Commit 26b7590: "deletes C0 first, and repeats the substitution until stable; test 5 adds split, nested and env cases"

**Location:** commit 26b7590 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** As Claims 4 and 17.

**Evidence:** `scripts/dev-cycle.sh:34`, `test/scripts/dev-cycle.bats:98-102`. Output: `$FC/probe-scrub.log`.

---

## Claim 22a: Commit 26b7590: "A5: the body runs as a child whose stdout and stderr pass through scrub as pipeline members, so the shell waits for both filters … Exit status is the body's."

**Location:** commit 26b7590 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** As Claims 6 and 8.

**Evidence:** `scripts/dev-cycle.sh:41-44`. Output: `$FC/reexec-probes.log`.

## Claim 22b: Commit 26b7590: "perl autoflushes, so stream order follows the body."

**Location:** commit 26b7590 message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the relative order of stdout and stderr lines when both reach one destination. Each stream on its own does keep the body's order.

The two streams pass through two separate perl processes, so their interleaving is a scheduling race, and autoflush cannot order them. A harness using the exact construct from `:41-44`, with a body alternating `echo "out $i"` and `echo "err $i" >&2`, produced an order different from the body's in 20 of 20 runs with `2>&1`. For example, `err 1` arrived after `out 4`.

**Evidence:** `scripts/dev-cycle.sh:41-44`. Command: `LC_ALL=C timeout 30 bash $FC/order-harness.sh 2>&1`, 20 runs, cwd `$FC`, exit 0, 2026-10-02T03:15:25Z. Output: `$FC/order-probe.log`.

---

## Claim 23: Commit 26b7590: "A4: inrepo() reads only regular files whose real path is inside the checkout (symlinked records, log, roadmap, questions, idea log skipped)."

**Location:** commit 26b7590 message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the six content sites. Does not cover the cycle-record name glob (Claim 10).

The parenthetical overstates the rule: only symlinks that resolve outside the checkout are skipped. An in-repo symlinked `docs/roadmap.md` was followed and printed (`> - INREPO-LINK`). A precise version: "symlinks resolving outside the checkout are skipped".

**Evidence:** `scripts/dev-cycle.sh:67`. Output: `$FC/inrepo-sec7-probes.log`.

---

## Claim 24: Commit 26b7590: A6, A7, A8, "A9, C8: test 4's comment and name corrected", "C1 (part): section 6 reuses merges_full and caps its list at 30"

**Location:** commit 26b7590 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed item against the diff and the tests. Does not re-review the substance of rubric items A9/C8 beyond the renamed text.

A6: `--help` lines 10-11 and the Window line (Claims 1 and 11); the midnight test is renamed (Claim 19). A7: Claim 13. A8: Claim 14; the `oldest`/`base` code is removed in the diff. A9/C8: Claim 12. C1: `done <<< "$merges_full"` and the 30 cap (`:208`, `:212-213`).

**Evidence:** `git diff db0e5ca..28c6178 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats`. Output: `$FC/bats-A.log`.

---

## Claim 25: Commit 26b7590: "20/20 tests; the new scrub, symlink, section 6 and section 7 tests fail on db0e5ca."

**Location:** commit 26b7590 message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 28c6178's suite (26b7590 differs only inside test 19's assertions, and its test count is the same) and the four named tests on db0e5ca. Does not establish anything about other environments.

The 28c6178 suite ran 20/20 ok. On db0e5ca exactly tests 5 (scrub), 6 (symlink), 19 (section 6) and 20 (section 7) fail. The redirect test passes there, as the commit Notes say.

**Evidence:** `$FC/bats-A.log`, `$FC/bats-new-tests-on-db0e5ca.log`.

---

## Claim 26: Commit 26b7590: "shellcheck clean."

**Location:** commit 26b7590 message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two files 26b7590 changed, under health-check.sh's gate flags. Does not cover other files.

`scripts/dev-cycle.sh` at 26b7590 passes. But `test/scripts/dev-cycle.bats` at 26b7590 fails: `IFS=: read -r br files want <<< "$spec"` → `SC2034 (warning): want appears unused`, exit 1. The gate runs `shellcheck -x -e SC1091 -s bash -S warning "$f"` on .bats files (`scripts/health-check.sh:480`). 28c6178 itself says this failed the gate.

**Evidence:** `scripts/health-check.sh:460-480`. Command: `shellcheck -x -e SC1091 -s bash -S warning <file>` for both files at 26b7590 and at 28c6178, cwd `$FC/sc.4T8Y`, 2026-10-02T03:10:27Z. Exits: a.bats (26b7590) 1, dc26.sh 0, b.bats (28c6178) 0, dc.sh 0. Outputs: `$FC/shellcheck-gateflags.log`, `$FC/shellcheck-26b7590-bats.log`.

---

## Claim 27: Commit 26b7590 Notes: "A lone 0x9B byte and zero-width characters stay unscrubbed, as the comment says. The redirect test passes on db0e5ca too (truncation is timing-dependent)."

**Location:** commit 26b7590 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both statements as written. The "as the comment says" list is incomplete (Claim 5).

**Evidence:** `$FC/probe-scrub.log`, `$FC/bats-new-tests-on-db0e5ca.log` (ok 7).

---

## Claim 28: Commit 28c6178: "shellcheck SC2034 (unused "want") failed the health-check lint gate." / subject "use the expected-verdict field in the section 6 cases"

**Location:** commit 28c6178 message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the body (verified) and the subject (imprecise). Does not establish anything else.

The SC2034 failure is confirmed (Claim 26), and 28c6178 is clean. The subject is imprecise: the fix discards the first list's third field (`IFS=: read -r br files _`) and restates the expectations in a second list (`for spec in readme-like:flag readme-txt:ok ...; IFS=: read -r br want`). The original field is still unused. A precise version: "assert the expected verdict per section 6 case".

**Evidence:** `test/scripts/dev-cycle.bats:273-285`, `git diff 26b7590 28c6178`. Output: `$FC/shellcheck-gateflags.log`.

---

## Claim 29: Skill step 0: "Run `~/.claude/scripts/dev-cycle.sh` … It is read-only. Its sections feed the steps: 1 activity (context), 2 triggers (step 2), 3 watched questions (step 3), 4 spot-check sample and 6 merges with code but no docs (step 4), 5 roadmap (step 6), 7 inputs (steps 4b and 5)."

**Location:** `skills/dev-cycle/SKILL.md:64-68`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the install path (the installer stages all of `scripts/`), the section numbers and titles, and read-only behaviour. Does not establish runtime behaviour of the installed copy outside this repo.

`CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)` (`devcontainer-config/install.sh:135`). The digest headings `## 1. Activity` … `## 7. Inputs for steps 4b and 5` appear in test 1 (passes). The only write is `qs_err="$(mktemp)"; trap 'rm -f "$qs_err"' EXIT` (`scripts/dev-cycle.sh:157`).

**Evidence:** `devcontainer-config/install.sh:125-135`, `scripts/dev-cycle.sh:113-216`. Output: `$FC/bats-A.log` (ok 1).

---

## Claim 30: Skill step 0: window-start check, and "If the digest fails (non-zero exit or a missing section) … write **no** cycle record, so the next window still starts at the last good one."

**Location:** `skills/dev-cycle/SKILL.md:69-76`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the window source (the newest non-future record name) and non-zero exit on failure. Does not establish that every mid-digest failure prints a detectable missing section.

The window comes from `[[ "$d" > "$last_record" && ! "$d" > "$TODAY" ]] && last_record="$d"` (`scripts/dev-cycle.sh:96`). Failures exit non-zero (Claim 8).

**Evidence:** `scripts/dev-cycle.sh:92-105`. Outputs: `$FC/reexec-probes.log`, `$FC/bats-A.log` (ok 9).

---

## Claim 31: Skill step 1 cross-references: `scripts/health-check.sh`; "triage them as pr-prep step 5a does (caused by recent work, pre-existing, flaky)"; `questions.sh archive` then `index`; `archive-working-docs.sh` "serves the self-improvement loop and moves files into a gitignored archive"; deleting merged branches "needs the user's approval"

**Location:** `skills/dev-cycle/SKILL.md:80-93`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence and behaviour of each named target. Does not run them.

- pr-prep step 5 lists the classes "Caused by this branch | Pre-existing on main | Flaky / infra / environmental" (`workflows/pr-prep.md:339-343`).
- `questions.sh` dispatches `index) cmd_index ;; archive) cmd_archive ;;` (`scripts/questions.sh:449-450`).
- `# Archive docs/working/ artifacts from a completed self-improvement run.` (`scripts/archive-working-docs.sh:2`), with `docs/working/archive/` in `.gitignore:16`.
- The global instructions require approval for "deleting branches" (`global-instructions/CLAUDE.md:220`).

**Evidence:** files as cited (wt-devcycle).

---

## Claim 32: Skill steps 2–4b and step 7 on digest output: "The digest prints every trigger in full"; "If the digest says `questions.sh open` failed"; "every merge the digest lists under 'Merges with code but no docs'"; 4b triggers "from the digest's section 7 and the last record"; "under the name the digest prints"; "The next digest starts its window from this file's date (only the file name is read)"

**Location:** `skills/dev-cycle/SKILL.md:98`, `:116`, `:123`, `:133-137`, `:220-222`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each phrase against the digest's output strings. Section 6 shows at most 30 merges ("… N more" beyond that), so "every merge the digest lists" is not every flagged merge.

The digest strings these phrases rely on:
- `echo "**questions.sh open failed** — ..."` (`scripts/dev-cycle.sh:170`)
- `"### ${f//$'\n'/ } (last committed ...)"` and `"- log row $n ($d): > $text"` (`:136`, `:148`); these match the record template's `docs/decisions/014-...md` and `log row 62` names
- `"The model version is not in git: compare it with the last cycle record's."` (`:225`) together with the template's `Model:` line (`SKILL.md:205`)
- the cycle-record glob reads only the name (`:93-96`)

Tests 3 and 9 pass.

**Evidence:** `scripts/dev-cycle.sh:93-96`, `:125-151`, `:170`, `:225`, `skills/dev-cycle/SKILL.md:200-218`. Output: `$FC/bats-A.log`.

---

## Claim 33a: Skill step 5 / seeding: "append `## Brainstorm YYYY-MM-DD` to the idea log, so the next digest counts seeds from here" — default log path

**Location:** `skills/dev-cycle/SKILL.md:159-160` (with `:41-44`)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers repos whose seed log is `docs/working/idea-log.md`, including this repo, whose `docs/dev-cycle-sources.md` names that path. Does not cover a custom seed log (33b).

The digest reads `LOG=docs/working/idea-log.md` (`scripts/dev-cycle.sh:244`) and resets its count at each `## Brainstorm` heading (`:250`). Test 20 ("Ideas seeded since: 2", "Last brainstorm: 2026-01-01") passes.

**Evidence:** `scripts/dev-cycle.sh:244-259`. Output: `$FC/bats-A.log`.

## Claim 33b: same sentence, for "the file `docs/dev-cycle-sources.md` names as its seed log"

**Location:** `skills/dev-cycle/SKILL.md:41-44`, `:146-151`, `:159-160`
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the installed digest in any repo whose sources file names a different seed log. Does not affect this repo today.

The skill says seeding goes to "the file `docs/dev-cycle-sources.md` names as its seed log when that file exists", and that the step 5 triggers (10+ seeds, a week since the last brainstorm) come from "the digest's section 7". The digest hard-codes `LOG=docs/working/idea-log.md` (`scripts/dev-cycle.sh:244`). No code in `scripts/dev-cycle.sh` reads `docs/dev-cycle-sources.md` (paraphrased — no quote available because the claim concerns absence: `grep dev-cycle-sources scripts/dev-cycle.sh` has no hits).

With a custom seed log, the next digest prints "No docs/working/idea-log.md: no ideas seeded, no brainstorm recorded" (`:258`). Two of the brainstorm triggers would then never fire from digest input.

**Evidence:** `scripts/dev-cycle.sh:244-259`, `skills/dev-cycle/SKILL.md:41-44`, `:146-151`.

---

## Claim 34: Skill step 3: "if it clears step 1's bar (mechanical, small, one commit)"

**Location:** `skills/dev-cycle/SKILL.md:111-112`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the cross-reference wording only.

Step 1's bar is "Fix what is mechanical now, one commit per concern. File the rest." (`SKILL.md:94`). "Small" is not in step 1. The approval doc's step 3 row uses the same parenthetical. A precise version: "(mechanical, one commit)", or add "small" to step 1.

**Evidence:** `skills/dev-cycle/SKILL.md:94`, `:111-112`.

---

## Claim 35: Skill roadmap template and landing order: sections `Now / In flight / Next / Ideas / Done`; briefs at `docs/working/handoffs/<date>-<slug>.md`; "Both land with step 7, so the briefs are on the default branch before any loop starts"; at most 3 in flight; "Under /active the user confirms this queue now; under /away it stands"; 6b "Runs after step 7 has landed"; RPI and divergent-design named

**Location:** `skills/dev-cycle/SKILL.md:164-196`, `:223-232`, `:158`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the headings the digest matches exactly (`$0 == h` for `## Now`, `## In flight`, `## Next`), that no cycle-written path is gitignored, the internal order 6 → 7 → 6b, and that the named workflows exist. Does not establish runtime behaviour of the build loops.

The digest counts sections with `awk -v h="## $sec" '$0 == h ...'` for `Now "In flight" Next` (`scripts/dev-cycle.sh:237-238`). Test 20 checks all three counts and passes. `git check-ignore` matched none of `docs/working/handoffs/x.md`, `cycles/cycle-*.md`, `idea-log.md`, `docs/roadmap.md` or `docs/dev-cycle-sources.md` (rc=1). `workflows/research-plan-implement.md` and `workflows/divergent-design.md` exist. The digest's no-roadmap message points to "the template in the dev-cycle skill" (`:195`), which is at `SKILL.md:166-178`.

**Evidence:** `scripts/dev-cycle.sh:195`, `:236-243`, `.gitignore:16-36`. Output: `$FC/bats-A.log`.

---

## Claim 36: Skill rule "Commits and merges follow the Operating Modes rules in the global instructions (in /active mode, ask first)"

**Location:** `skills/dev-cycle/SKILL.md:27-29`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers commits. Merges create commits. Does not cover launching loops (see Claim 43).

Under /active the global instructions say "**Require user approval before:** - Creating git commits" (`global-instructions/CLAUDE.md:194-195`).

**Evidence:** `global-instructions/CLAUDE.md:190-200`.

---

## Claim 37: Decision log row 67 (edited line): "the self-improvement loop's `feature-ideas*.md` is read as a signal in step 5, so the roadmap is the one backlog (Q-099 [1], 2026-09-30)"

**Location:** `docs/decisions/log.md:90`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Q-099 citation and the step 5 behaviour.

Q-099 reads: "**Answer (2026-09-30, answers-9-30-26.txt): [1].** The roadmap is the one backlog." (`docs/working/questions-archive.md:1800`). The skill's step 5 reads `docs/working/feature-ideas*.md` (`SKILL.md:156`).

**Evidence:** `docs/working/questions-archive.md:1797-1800`, `skills/dev-cycle/SKILL.md:154-157`.

---

## Claim 38: Decision log row 67 (same edited line): "Steps: digest → … → roadmap (Now / Next ≤5 / Ideas / Done) → cycle record"

**Location:** `docs/decisions/log.md:90`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the row's step and section list against the skill as committed. Row 68 records the revision, so this is low-stakes.

The skill's roadmap now has `## In flight` (`SKILL.md:174`), plus steps 4b and 6b. Row 67 was edited in c079e8c without updating its step or section list. A reader of row 67 alone would miss In flight, 4b and 6b. A short pointer such as "(revised by row 68)" would fix it.

**Evidence:** `docs/decisions/log.md:90-91`, `skills/dev-cycle/SKILL.md:51-54`, `:173-177`.

---

## Claim 39: Decision log row 68 decision text: carry-forward and `Main at:` cut (Q-101 [1]); step 4 claim spot-check; conditional 4b files a deep audit; conditional brainstorm with its five triggers; seeding always on; briefs and RPI loops (≤3 in flight) after the branch lands; "undocumented is broken" checked through the code-without-docs section. Also: "The double-diamond pass's 8 gaps were applied (landing order, in-flight state, 4b inputs, digest failure path, where filed work goes, readiness, subagent use, parallel steps)."

**Location:** `docs/decisions/log.md:91`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each sentence against the skill as committed, Q-101 and the approval doc's gap table (read through the Docs connector). Does not establish that the user approved the final text.

- The skill has no `Main at` (grep: 0 hits; 6ee33e3 had 2).
- Q-101's answer is "[1]. Cut carry-forward and `Main at:`" (`questions-archive.md:1817-1832`).
- The approval doc's gap table lists exactly these 8 gaps with the fixes, and states "All eight fixes are applied to the steps above (2026-10-01)".
- Each fix has matching text in the skill: landing order `:220-224`; In flight and step 1 skip `:87-90`, `:181`; Model line `:205`; failure path `:74-76`; "Work goes to the roadmap" `:30-31`; "names the roadmap item it blocks" `:33`; subagents `:56-60`; parallel `:51-57`.

**Evidence:** `skills/dev-cycle/SKILL.md` as cited, `docs/working/questions-archive.md:1817-1832`, approval doc 78a2f851 (gap table, read 2026-10-02).

---

## Claim 40: Decision log row 68 rationale: "User comments on the approval doc, 2026-10-01: the cycle boundary is the only place triggers are certain to be checked; audit is not code review; brainstorm matters most when little is planned; this is the standard loop, so it must hand off to build loops."

**Location:** `docs/decisions/log.md:91`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing beyond the doc body. The doc's body text reflects all four points ("Spot-check vs deep audit", "Its main trigger is a thin plan", the 6b handoff), but the user's comment threads themselves were not read.

To verify, query the doc's comment threads (the Claude Docs `query` verb) for the 2026-10-01 user comments.

**Evidence:** approval doc 78a2f851 body. Comment ids are present but their contents were not read.

---

## Claim 41: Decision log row 68 revisit trigger: "or if section 7's thresholds never fire in four cycles"

**Location:** `docs/decisions/log.md:91`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the attribution of the thresholds.

Section 7 prints inputs only. Its own heading says "Step 5 (brainstorm triggers; the thresholds are the skill's):" (`scripts/dev-cycle.sh:235`). The thresholds live in the skill's 4b and 5 lists (`SKILL.md:135-137`, `:148-152`). A precise version: "if the 4b/5 thresholds (fed by section 7) never fire in four cycles".

**Evidence:** `scripts/dev-cycle.sh:235`, `skills/dev-cycle/SKILL.md:133-152`.

---

## Claim 42: `docs/dev-cycle-sources.md`, `docs/roadmap.md` and global decision-tree row 12

**Location:** `docs/dev-cycle-sources.md:3-9`, `docs/roadmap.md:18`, `global-instructions/CLAUDE.md:32`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the skill, and that the named files exist. Does not establish the digest reading the sources file (it does not; Claim 33b).

- Sources file: "step 5 reads every source when it brainstorms, and always-on seeding appends to the seed log" matches `SKILL.md:41-44` and `:154-157`. The feature-ideas glob matches `docs/working/feature-ideas.md` (tracked) and the SI loop's `feature-ideas-round-N.md` (`scripts/self-improvement.sh:38`). The seed-log format matches seeding.
- Roadmap: `## In flight` sits between Now and Next, as in the template.
- Row 12: "every revisit trigger, claim spot-check, conditional deep-audit check and brainstorm, roadmap …, then hands ready items to autonomous build loops" matches the skill's flow (`SKILL.md:51-54`).

**Evidence:** files as cited.

---

## Claim 43: Skill-creation guide row: "with no human checkpoint mid-run beyond the Operating Modes rule (under /active the user confirms the handoff queue, as for any launch; decisions go to questions.md)"

**Location:** `guides/skill-creation.md:137`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the attribution of the step 6 confirmation to the Operating Modes rules. Does not judge whether the gate is a good idea.

The /active list in the global instructions is: commits, push, PRs, plan review gates, and design decisions not covered by the plan (`global-instructions/CLAUDE.md:194-200`). It has no launch rule: `rg -i launch global-instructions/` finds no hits (paraphrased — no quote available because the claim concerns absent text). The handoff-queue confirmation is the skill's own gate: "Under /active the user confirms this queue now" (`SKILL.md:192`).

So the row's mechanism ("the Operating Modes rule … as for any launch") is not in the cited rules. Its conclusion, no mid-run checkpoint beyond that rule, therefore understates the skill's own mid-run human gate under /active. The guide's promotion criterion names exactly that kind of gate ("Promote it to a workflow … if a cycle ever needs a human gate mid-run").

**Evidence:** `guides/skill-creation.md:137`, `global-instructions/CLAUDE.md:190-200`, `skills/dev-cycle/SKILL.md:190-196`.

---

## Claim 44: Commit c079e8c: "The skill now matches 'Dev cycle skill — for your approval' (2026-10-01)", its bullet list, and Notes ("brief-writing moved from 6b into step 6 … The /active confirmation therefore happens at step 6")

**Location:** commit c079e8c message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the bullets and Notes (all verified) and the "matches the doc" headline.

Verified items:
- Bullets: no `Main at:`; `Model:` line; four rules (6ee33e3 had three: Attention, Repo text, Commits and branches); seeding to the sources-named log; 2/3/4/4b in parallel; thresholds "0-1 ready items, 10+ seeds, a week by date", which Q-101's answer records; step 3 at most 3; In flight; 6 → 7 → 6b; "Also:" files (diff stat).
- Notes: the step 6 / /active move matches `SKILL.md:190-196`.

The headline holds except for undisclosed deviations from the doc:
- The doc's sources draft uses `docs/feature-ideas*.md` ("one idea per `##` heading"). The committed sources file uses `docs/working/feature-ideas*.md` ("the self-improvement loop's idea files").
- The doc's step 6b row moves items to In flight at launch; the skill moves them at step 6. This is implied by the Notes but not stated.
- The commit's "Also:" list omits the row 67 edit.

A precise version: "matches the doc except as noted", with the sources path noted.

**Evidence:** `git show c079e8c --stat`, `skills/dev-cycle/SKILL.md`, `docs/dev-cycle-sources.md:8`, approval doc 78a2f851 (step table and sources draft).

---

## Claims Requiring Attention

### Incorrect
- **Claim 3** (`scripts/dev-cycle.sh:27-29`): perl is not pinned to bytes. An inherited `PERLIO=:utf8` disables the byte patterns, and raw C1 CSI and RLO reach stdout end to end. Either add `-u PERLIO` to the `env` (and to test 5's env loop), or reword the comment.
- **Claim 21a** (commit 26b7590): "scrub pins perl to bytes", the same defect as Claim 3.
- **Claim 22b** (commit 26b7590): "perl autoflushes, so stream order follows the body" is false across streams: 20/20 runs interleaved differently from the body's order. Only each stream's own order is kept.
- **Claim 26** (commit 26b7590): "shellcheck clean" was false. The test file failed the gate with SC2034, which 28c6178 fixed.
- **Claim 33b** (`skills/dev-cycle/SKILL.md:41-44`, `:159-160`): with a seed log named by `docs/dev-cycle-sources.md`, the digest still reads only `docs/working/idea-log.md`. The "next digest counts seeds" claim and the 10+-seeds and week triggers fail there. This is an A↔B contract gap that this repo does not hit today.
- **Claim 43** (`guides/skill-creation.md:137`): the /active handoff-queue confirmation is the skill's own gate, not an Operating Modes rule. No "launch" rule exists.

### Stale
- **Claim 38** (`docs/decisions/log.md:90`): row 67, edited in this commit, still lists the roadmap as Now/Next/Ideas/Done and omits 4b and 6b. Row 68 supersedes it, but row 67 has no pointer to row 68.

### Mostly Accurate
- **Claim 5** (`scripts/dev-cycle.sh:31-32`): the "Not covered" list omits other lone or overlong C1/C0 bytes and U+061C ALM.
- **Claim 7** (`scripts/dev-cycle.sh:38-39`): fd 3 takes the outer pipe first, not "then", and the inner scrub inherits fd 3.
- **Claim 10** (`scripts/dev-cycle.sh:64-67`): the cycle-record name, a date only, is still read through a symlinked parent outside the checkout.
- **Claim 23** (commit 26b7590): only symlinks that escape the checkout are skipped, not all symlinked files.
- **Claim 28** (commit 28c6178): the subject says the field is used, but the first list's field is now discarded and the expectations are restated in a second list.
- **Claim 34** (`skills/dev-cycle/SKILL.md:111-112`): step 1's bar does not include "small".
- **Claim 41** (`docs/decisions/log.md:91`): the thresholds are the skill's; section 7 only prints their inputs.
- **Claim 44** (commit c079e8c): matches the approval doc except for the sources-file path and format, which differ from the doc's draft without being noted.

### Unverifiable
- **Claim 40** (`docs/decisions/log.md:91`): the content of the user's doc comments; needs the Docs comment threads read.

Adjacent observation (not a comment claim, recorded under Claim 15's Scope): section 7's 4b lists silently drop git-quoted names, including every non-ASCII path under the default `core.quotePath`, so the printed "files changed … : N" count can be low.

---

## Goal-Alignment Note

Success criterion, verbatim: "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-r3-digest-final5.md`, and its first line is `Commit: 28c6178 (A) / c079e8c (B)`. It follows code-fact-check's output format: header fields, seven mandatory fields per claim, Na/Nb splits where verdicts diverge, the attention summary, and a Legibility-target per claim in the appendix below.

All nine brief priority items were covered:
- scrub: Claims 2–5, 17, 21
- re-exec: 6–9, 22
- `inrepo`: 10, 23
- Window/help: 1, 11
- section 6: 13
- section 7: 14–15
- commits: 21–28, 44
- skill statements: 29–36, 43
- row 68 and the guide row: 39–41, 43

Final pass 4's prior findings were re-checked:
- R1 is closed for split and nested sequences but reopened by `PERLIO`.
- A1 is partly closed (`PERLIO` remains).
- R2/A3 are closed (no `Main at:`).
- A2, A4 (except the cycle-record names), A5, A6, A7, A8 and A9 are closed.

Not done: the hallucination-pattern log was not appended. No entry qualified, and the brief forbids worktree writes.

### Legibility-target per claim
- for-author (Incorrect / Stale / Mostly accurate): 3, 5, 7, 10, 21a, 22b, 23, 26, 28, 33b, 34, 38, 41, 43, 44
- for-orchestrator-synthesis (Verified / Unverifiable): 1, 2, 4, 6, 8, 9, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21b, 22a, 24, 25, 27, 29, 30, 31, 32, 33a, 35, 36, 37, 39, 40, 42
