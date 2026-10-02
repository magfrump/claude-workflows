Commit: 28c6178 (A) / c079e8c (B)

# Code Fact-Check Report

**Repository:** claude-workflows — unit A worktree `/workspace/.claude/wt-digest` (feat/dev-cycle-digest), unit B worktree `/workspace/.claude/wt-devcycle` (feat/dev-cycle)
**Scope:** Partial (the final-pass-4 fixes only). A: `git diff db0e5ca..28c6178 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` plus commit messages 26b7590, 28c6178. B: `git diff 6ee33e3..c079e8c -- skills/dev-cycle/SKILL.md docs/decisions/log.md docs/roadmap.md guides/skill-creation.md global-instructions/CLAUDE.md docs/dev-cycle-sources.md` plus commit message c079e8c. The A↔B contract (digest sections, formats, paths) is in scope. Replicate r2.
**Checked:** 2026-10-01
**Total claims checked:** 80
**Summary:** 66 verified, 10 mostly accurate, 0 stale, 3 incorrect, 1 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). Claim 32 resembles the logged family "commit message states a verification result the repo does not bear out" (e.g. "All 85 tests … pass", first seen in that log); it is a false lint-status claim, not a fabricated symbol, so no new entry is due — and the brief forbids writing outside this report in any case.

## Execution provenance

All runs: user `node`, bash 5.2.15, git 2.39.5, perl 5.36.0, shellcheck from `/usr/bin`, 2026-10-01 between 20:11 and 20:17 -07:00. Throwaway repos were built under a `mktemp -d` dir in the scratch directory and deleted afterwards; `git status` in both worktrees was clean (bar the pre-existing untracked `devcontainer-config/` files) before and after. Captured output lives in `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc5-r2/` (written `$S/` below).

| ID | Command | cwd | Exit | Time | Output |
|---|---|---|---|---|---|
| E1 | `timeout 300 bats test/scripts/dev-cycle.bats` | wt-digest | 0 | 20:11:36 | `$S/bats-28c6178.txt` (20/20 ok) |
| E2 | the same 20 tests run against `git show db0e5ca:scripts/dev-cycle.sh` (tree copied into a temp dir) | temp dir | 1 | 20:11:49 | `$S/bats-newtests-on-db0e5ca.txt` (tests 5, 6, 19, 20 fail) |
| E3 | `shellcheck -x -e SC1091 -s bash -S warning <f>` (health-check.sh:480 flags) on the bats file and script at 26b7590 and at 28c6178 | wt-digest | 1 at 26b7590's bats file; 0 for the others | 20:11:58 | `$S/shellcheck.txt` |
| E4 | `bash $S/probe1.sh <tmp>` — help, unknown option, bad --since, not a repo, subdirectory run, DEV_CYCLE_SCRUBBED, forced mid-digest failure (a `shuf` shim exiting 7), section 6 | temp repo | 0 | 20:12:13 | `$S/probe1.out` |
| E5 | `bash $S/probe2.sh <tmp>` — section 6 when the last loop pass is unflagged, the cap of 30, `@`-named paths, a name with a control character | temp repo | 0 | 20:12:28 | `$S/probe2.out` |
| E6 | `LC_ALL=C bash $S/probe3.sh` — the `scrub()` body extracted verbatim from scripts/dev-cycle.sh:33-35 and given adversarial bytes | scratch | 0 | 20:12:43 | `$S/probe3.out` |
| E7 | `bash $S/order-harness.sh` (the :33-44 block verbatim, with a body that alternates 200 stdout and 200 stderr lines), both streams sent to one file, compared with the body's order; then with body exit 5 | scratch | 0 / 5 | 20:16:27 | `$S/order-harness.out` |
| E8 | `bash $S/big-harness.sh` (same block; the body writes 3 MB to each stream and exits), redirected to two files, sizes checked on return, ×3 | scratch | 0 | 20:13:03 | `$S/big-harness.out` |
| E9 | `bash $S/probe4.sh <tmp>` — committed symlinks out of the repo (decisions dir, roadmap, idea log, questions, log.md) and one in-repo symlink | temp repo | 0 | 20:13:15 | `$S/probe4.out` |
| E10 | `LC_ALL=C timeout 120 bash scripts/dev-cycle.sh` (git status before/after) | wt-devcycle | 0 | 20:13:42 | `$S/digest-wt-devcycle.md` |
| E11 | `bash $S/probe5.sh <tmp>` — test 4's history under old `git log --since` vs the post-walk filter; a non-ASCII skill path in section 7 | temp repo | 0 | 20:14:19 | `$S/probe5.out` |
| E12 | `TZ=UTC git log -1 --format='%cs \| %ci'` on a commit dated `2026-01-01T23:30:00-1000` | temp repo | 0 | 20:14:31 | `$S/cs-zone.txt` |

---

## Claim 1: "--since   start of the cycle window: commits whose committer date, in the committer's own time zone (git's %cs), is on or after this date."

**Location:** `scripts/dev-cycle.sh:10-11`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the %cs zone semantics and the post-walk `>=` filter in sections 1, 6 and 7. It does not establish how the default (`14 days ago`) is computed: `date -d "$TODAY - 14 days"` uses the local zone.

E12 printed `2026-01-01 | 2026-01-01 23:30:00 -1000` under `TZ=UTC`, so %cs keeps the committer's own offset. The filters are `awk -v s="$SINCE" '$1 >= s'` over `--format='%cs …'` (`scripts/dev-cycle.sh:117`, `:120`) and `on = (substr($0, 2) >= s)` over `--format='@%cs'` (`:221-222`). E4 shows `--help` prints the new wording.

**Evidence:** `scripts/dev-cycle.sh:10-11`, `:117`, `:120`, `:221-222`; `$S/cs-zone.txt`; `$S/probe1.out`

---

## Claim 2: "drops C0 controls but TAB and LF, DEL, C1 controls (U+0080-009F), bidi controls (U+200E/F, U+202A-202E, U+2066-2069) and tag characters (U+E0000-E007F)"

**Location:** `scripts/dev-cycle.sh:25-27`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the enumerated ranges as UTF-8 byte sequences. It does not establish that the list is every bidi control: Unicode's Bidi_Control set also contains U+061C (ARABIC LETTER MARK), which passes unchanged (see Claim 4).

The code is `tr/\000-\010\013-\037\177//d; 1 while s/\xC2[\x80-\x9F]|\xE2\x80[\x8E\x8F\xAA-\xAE]|\xE2\x81[\xA6-\xA9]|\xF3\xA0[\x80\x81][\x80-\xBF]//g` (`scripts/dev-cycle.sh:34`). In E6, LRM (`e2 80 8e`), PDI (`e2 81 a9`), FSI, tag U+E007F (`f3 a0 81 bf`) and ESC were all removed, and TAB (`09`) was kept.

**Evidence:** `scripts/dev-cycle.sh:34`; `$S/probe3.out`

---

## Claim 3: "Perl is pinned to bytes (-C0, and PERL_UNICODE / PERL5OPT removed: either could turn on UTF-8 decoding and switch the byte patterns off). C0 goes first and the substitution repeats until nothing changes, so neither a control byte inside a sequence nor a nested sequence can reassemble one."

**Location:** `scripts/dev-cycle.sh:27-31`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers sequences inside one line: C0 or DEL bytes inside a sequence, nesting to any depth, mixed families, and both env variables. It does not cover a sequence split by LF. Perl `-p` works line by line and LF is kept, so `C2 0A 9B` leaves a lone `C2` and a lone `9B` (which is Claim 4's residue, not a reassembly).

The code is `env -u PERL_UNICODE -u PERL5OPT LC_ALL=C perl -C0 -pe 'BEGIN { $| = 1 } tr/…//d; 1 while s/…//g'` (`scripts/dev-cycle.sh:34`). In E6:
- `C2 C2 C2 9B 9B 9B` gave `61 62 0a`.
- A C0 between nested layers (`C2 C2 01 9B 9B`) gave `61 62`.
- A DEL split (`C2 7F 9B`) gave `61 62`.
- A C1 inside a bidi sequence (`E2 80 C2 9B AE`) gave `61 62`.
- Nested tags gave `61 62`.
- A CR split gave `61 62`.
- With `PERL_UNICODE=SDA`, `PERL5OPT=-CSD` and both together, the output was `61 62 63 0a`.

Bats test 5 (E1) passes, and it fails on db0e5ca (E2). The loop terminates because each successful `s///` removes at least 2 bytes. Because `tr` runs first and `s///` only deletes multi-byte sequences, no C0 byte can appear afterwards.

**Evidence:** `scripts/dev-cycle.sh:33-35`; `test/scripts/dev-cycle.bats:94-109`; `$S/probe3.out`; `$S/bats-28c6178.txt`; `$S/bats-newtests-on-db0e5ca.txt`

---

## Claim 4: "Not covered: a lone 0x9B byte (invalid UTF-8, inert on a UTF-8 terminal) and zero-width characters (cannot start a line)."

**Location:** `scripts/dev-cycle.sh:31-32`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what passes the scrub unchanged. It does not establish how any particular terminal renders these bytes.

The listed items do pass, but the list is incomplete. In E6 every lone C1 byte passes, not only 0x9B: `lone90-dcs: 61 90 62`, and `lone9d-osc: 61 9d 30 3b 78 9c 62` (an 8-bit OSC … ST). U+061C ALM (`d8 9c`), U+2028 (`e2 80 a8`) and U+2029 (`e2 80 a9`) also pass. A precise version would read: "Not covered: lone bytes 0x80-0x9F (invalid UTF-8; 0x9B CSI, 0x9D OSC and 0x90 DCS among them), U+061C, U+2028/2029 and zero-width characters."

**Evidence:** `scripts/dev-cycle.sh:31-34`; `$S/probe3.out`

---

## Claim 5: "Run the body as a child whose stdout and stderr each pass through scrub as members of one pipeline, so the shell waits for both filters before exiting: a redirected digest is complete when the script returns."

**Location:** `scripts/dev-cycle.sh:36-38`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers completeness of both streams when redirected to files. It does not establish ordering *between* the two streams (Claim 26) or behavior when the reader closes early (Claim 7).

The code is `{ DEV_CYCLE_SCRUBBED=1 bash "${BASH_SOURCE[0]}" "$@" 2>&1 1>&3 3>&- | scrub >&2; } 3>&1 | scrub` (`scripts/dev-cycle.sh:42`). Bash waits for every member of a foreground pipeline: the outer scrub, plus the brace group, which itself waits for the inner scrub. In E8 a body writing 3 MB to each stream and then exiting gave `out=3029999 err=3029999` on all three runs. Bats test 7 passes (E1).

**Evidence:** `scripts/dev-cycle.sh:41-44`; `$S/big-harness.out`; `$S/bats-28c6178.txt`

---

## Claim 6: "stdout goes to fd 3, stderr takes the inner pipe, then fd 3 takes the outer one."

**Location:** `scripts/dev-cycle.sh:38-39`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers where each stream ends up: body stdout goes to the outer scrub and then the real stdout; body stderr goes to the inner scrub and then the real stderr. It does not establish the order in which bash applies the redirections; `3>&1` on the group is applied before the inner ones, so the comment's "then" is narrative. It also does not establish that the inner scrub inherits fd 3 (it does; this is harmless).

`2>&1 1>&3 3>&-` applied inside the group, where fd 1 is the inner pipe and fd 3 is the outer pipe (`scripts/dev-cycle.sh:42`), sends stderr to the inner pipe and stdout to the outer one. Bats test 5 asserts that an ESC-bearing unknown-option message arrives on `$stderr` scrubbed, and that stdout carries the digest (E1).

**Evidence:** `scripts/dev-cycle.sh:42`; `test/scripts/dev-cycle.bats:105-108`; `$S/bats-28c6178.txt`

---

## Claim 7: "Exit status: the body's (pipefail; scrub itself does not fail)."

**Location:** `scripts/dev-cycle.sh:39-40`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the body's status when the reader drains both streams. It does not establish the status when a downstream reader closes early: in E4, `| head -3` gave 141 (SIGPIPE in scrub or the body). Under `set -e` the script also exits at line 42 itself, before line 43, with the same status.

E4: the forced `shuf` failure exited 7 after printing 4 section headings; unknown option, bad `--since` and not-a-repo each exited 1. E7: body `exit 5` gave script exit 5. With `pipefail` (`scripts/dev-cycle.sh:22`), each pipeline's status is its rightmost non-zero member, which is the body.

**Evidence:** `scripts/dev-cycle.sh:22`, `:41-44`; `$S/probe1.out`; `$S/order-harness.out`

---

## Claim 8: "DEV_CYCLE_SCRUBBED marks the child."

**Location:** `scripts/dev-cycle.sh:40-41`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the marker's effect. It does not establish anything about environments that export it by accident.

The guard is `if [[ -z "${DEV_CYCLE_SCRUBBED:-}" ]]; then` (`scripts/dev-cycle.sh:41`). In E4 the ESC count in the output was `0` normally and `1` with `DEV_CYCLE_SCRUBBED=1`, so setting the marker skips the scrub, as commit 26b7590's Notes state.

**Evidence:** `scripts/dev-cycle.sh:41`; `$S/probe1.out`

---

## Claim 9: "A regular file whose real path stays inside the repo: a committed symlink (to the file or a parent directory) must not make the digest print text from outside the checkout."

**Location:** `scripts/dev-cycle.sh:64-67`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every site that reads file text: decision records (`:130`), log.md (`:139`), questions.md before `questions.sh open` (`:156`), the roadmap (`:189`, `:236`) and the idea log (`:245`). It does not cover a `QUESTIONS_LIVE` env override, which `questions.sh` honours (`scripts/questions.sh:85`) after the gate, or a race between the check and the read. The cycle-record glob (`:93-97`) and the `git log -- f` calls read names or git objects only. When a file is skipped, the digest prints "No docs/roadmap.md yet — create it this cycle" even though a symlink exists there.

The check is `inrepo() { local r; [[ -f "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" && [[ "$r" == "$ROOT_REAL"/* ]]; }` (`scripts/dev-cycle.sh:67`). In E9, symlinks to outside files and to an outside `docs/decisions` directory produced 0 `SECRET` lines, and an in-repo symlink target was still read (count 1). Bats test 6 passes and fails on db0e5ca (E1, E2).

**Evidence:** `scripts/dev-cycle.sh:63-67`, `:130`, `:139`, `:156`, `:189`, `:236`, `:245`; `scripts/questions.sh:85`; `$S/probe4.out`

---

## Claim 10: Window line — "Merges, commits and section 7's changed files: those on `$MAIN` at … whose committer date (in the committer's time zone) is on or after $SINCE, filtered after a full walk. Triggers: all of them, from the working tree. Questions, roadmap, idea log: the working tree."

**Location:** `scripts/dev-cycle.sh:110`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers sections 1, 4 and 6 (all derived from `merges_full`) and section 7. It does not establish that "commits" means first-parent only: `:120` counts every commit reachable from `$MAIN`, and section 1 itself says "merged branches included".

`merges_full` (`:117`) feeds section 1 (`:118`), section 4 (`:183`) and section 6 (`:208`), all filtered by `%cs >= SINCE` after an unbounded `git log`. Section 7 uses `--format='@%cs'` with the same comparison (`:221-222`). E10 printed this line in the real repo.

**Evidence:** `scripts/dev-cycle.sh:110`, `:117-120`, `:208`, `:221-222`; `$S/digest-wt-devcycle.md`

---

## Claim 11: "`--since` stops at the first old-dated commit, so one such commit hid every merge behind it."

**Location:** `scripts/dev-cycle.sh:114-115`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git's `--since` walk on a first-parent line holding an old-dated commit. It does not cover a non-monotonic date that appears only on a side branch.

In E11, test 4's history gave `merge: feature 4` alone under `git log --first-parent --merges --since=…`, while the post-walk awk filter listed all four merges.

**Evidence:** `scripts/dev-cycle.sh:114-117`; `$S/probe5.out`

---

## Claim 12: "A merge whose diff against its first parent touches files but no doc (a path under docs/, a *.md file, or a file named README or README.*, any case): step 4 checks each one (rule: undocumented is broken). Listed up to 30."

**Location:** `scripts/dev-cycle.sh:199-201`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the README basename test (case-insensitive, `readme` or `readme.` prefix), `docs/`, `.md`, and the cap. It does not establish case-insensitivity for `docs/` or `.md`: `$0 ~ /^docs\//` and `$0 ~ /\.md$/` are case-sensitive, so `NOTES.MD` counts as code. "any case" attaches to README only.

The test is `b = tolower($0); sub(/.*\//, "", b); if ($0 ~ /^docs\// || $0 ~ /\.md$/ || b == "readme" || index(b, "readme.") == 1) d++; else c++` (`:205`). The cap is `printf '%s\n' "${flagged[@]:0:30}"; [[ ${#flagged[@]} -le 30 ]] || echo "… $((${#flagged[@]} - 30)) more"` (`:212-213`). In E5, 34 code-only merges printed 30 lines plus `… 4 more`. With the oldest (last-iterated) merge unflagged, the script exited 0, so the trailing `&&` (`:207`) does not trip `set -e`. Bats test 19 passes and fails on db0e5ca.

**Evidence:** `scripts/dev-cycle.sh:198-214`; `$S/probe2.out`; `$S/bats-newtests-on-db0e5ca.txt`

---

## Claim 13: section 6 reuses `merges_full`'s `rest` field for the listed line (commit 26b7590: "section 6 reuses merges_full")

**Location:** `scripts/dev-cycle.sh:203-207`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the format matches the earlier per-merge `git log -1 --format='%h %ad %s' --date=short`. It does not establish that leading or trailing whitespace in a subject is kept, since `read` without `IFS=` trims it.

`merges_full` uses `--format='%cs %H %h %ad %s' --date=short` (`:117`), and `while read -r _ full rest` (`:203`) leaves `rest` = `%h %ad %s`. E4 shows `- 07074d5 2026-10-01 merge f2 (1 file(s), no doc change)`.

**Evidence:** `scripts/dev-cycle.sh:117`, `:203-207`; `$S/probe1.out`

---

## Claim 14: "Every file any first-parent commit in the window touched (a merge counts its diff against its first parent), not a net diff: a change reverted inside the window still counts."

**Location:** `scripts/dev-cycle.sh:217-219`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what reaches `changed` (`:221-222`). It does not hold for the printed lists (`:223-224`) when a name is git-quoted.

The walk is right: `git log "$MAIN_SHA" --first-parent --diff-merges=first-parent --name-only --format='@%cs' -- skills workflows docs/decisions` (`:221`). Test 20 lists `workflows/flow.md`, which was added by a merge and deleted later. But git quotes any name with non-ASCII or control bytes under the default `core.quotePath`, and the filters `grep -E '^(skills/.*/SKILL\.md|workflows/[^/]*\.md)$'` (`:223`) and `'^docs/decisions/…'` (`:224`) then miss it. In E11 a merge adding `skills/café/SKILL.md` produced `"skills/caf\303\251/SKILL.md"` from git and `Skill or workflow files changed … : 0` from the digest. A precise version would read: "every file … touched, except names git quotes (non-ASCII or control bytes), which the lists below drop."

**Evidence:** `scripts/dev-cycle.sh:217-224`; `$S/probe5.out`; `$S/bats-28c6178.txt`

---

## Claim 15: "\"@\" lines carry each commit's date; git quotes a name holding a control character, so each name is one line."

**Location:** `scripts/dev-cycle.sh:219-220`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the one-line-per-name property and the `@` parse. It does not establish that quoted names are used afterwards (Claim 14). The quoting also applies to non-ASCII bytes.

In E5, `od -c` of the git output for `skills/a<LF>b/SKILL.md` was `@2026-10-01 \n \n " s k i l l s / a \ n b / S K I L L . m d "`, with or without `core.quotePath=false`. A path line cannot begin with `@`: with the pathspec, every name begins `skills`, `workflows` or `docs/decisions`, or a quote. In E5, `skills/@2099-01-01/SKILL.md` and `workflows/@x.md` were listed correctly and did not reset the date gate.

**Evidence:** `scripts/dev-cycle.sh:221-222`; `$S/probe2.out`

---

## Claim 16: "The skill's step 5 appends \"## Brainstorm YYYY-MM-DD\" after reading the log (its ideas go to the roadmap); seeding appends \"- \" lines after that heading."

**Location:** `scripts/dev-cycle.sh:246-247`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the skill text at c079e8c for the default log path. It does not cover the seed-log path itself (Claim 52).

The skill says "Then append `## Brainstorm YYYY-MM-DD` to the idea log, so the next digest counts seeds from here; the surviving ideas go to the roadmap's Ideas" (`skills/dev-cycle/SKILL.md:159-160`) and "appends one line to the idea log, `- <idea> (signal: <what prompted it>)`" (`:41-42`). The digest counts `/^- /` lines and resets at each `## Brainstorm` heading (`scripts/dev-cycle.sh:250`).

**Evidence:** `scripts/dev-cycle.sh:244-256`; `skills/dev-cycle/SKILL.md:41-44`, `:159-160`

---

## Claim 17: test 4 — "--since used to stop its walk at the old commit, so it counted only the newest merge and hid the three older ones behind the old commit."

**Location:** `test/scripts/dev-cycle.bats:81-83`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the old mechanism on this exact history. It does not cover db0e5ca, where test 4 passes because the post-walk filter was already there.

`make_repo` creates three merges (`test/scripts/dev-cycle.bats:28-33`), and E11 reproduced "only `merge: feature 4`".

**Evidence:** `test/scripts/dev-cycle.bats:22-35`, `:80-91`; `$S/probe5.out`

---

## Claim 18: test 5 — "Split by a C0 byte, and nested: neither may reassemble a sequence." (plus the env loop)

**Location:** `test/scripts/dev-cycle.bats:98-103`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fixture bytes in `002-y.md` and the three env settings. It does not cover the residue named in Claim 4.

The fixture holds C0-split (`\xc2\x01\x9b`, `\xe2\x80\x01\xae`) and nested (`\xc2\xc2\x9b\x9b`, `\xe2\x80\xe2\x80\xae\xae`, a doubled tag) cases. It passes at 28c6178 and fails at db0e5ca.

**Evidence:** `test/scripts/dev-cycle.bats:94-109`; `$S/bats-28c6178.txt`; `$S/bats-newtests-on-db0e5ca.txt`

---

## Claim 19: test name "the exit status and the whole digest survive a redirect to a file"

**Location:** `test/scripts/dev-cycle.bats:122-128`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers that the test passes and checks section 7's heading, the final `idea-log` line, and exit 1 on a bad `--since`. It does not establish that it detects truncation: it also passes on db0e5ca (E2), as commit 26b7590's Notes say. Claim 5 (E8) carries the real completeness evidence.

**Evidence:** `test/scripts/dev-cycle.bats:122-128`; `$S/bats-newtests-on-db0e5ca.txt`

---

## Claim 20: test 10 — "--since includes commits from the start date itself" / "All commits here are from today: a window starting today counts all of them."

**Location:** `test/scripts/dev-cycle.bats:147-149`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the inclusive `>=` comparison on the start date. It does not cover zone edge cases (Claim 1).

The test passes (E1); its assertion is `*"; $total commit(s)"*`.

**Evidence:** `test/scripts/dev-cycle.bats:147-153`; `$S/bats-28c6178.txt`

---

## Claim 21: test 19 — "README_gen.sh is code; a README.txt or docs/ alone is a doc."

**Location:** `test/scripts/dev-cycle.bats:272`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four specs and the per-spec expected verdict. It does not cover upper-case `.MD` or `DOCS/` (Claim 12).

The specs include `"readme-like:src/README_gen.sh:flag"` and `"readme-txt:x.sh lib/README.txt:ok"`, and the loop asserts `flag`/`ok` per branch. It passes at 28c6178 and fails at db0e5ca.

**Evidence:** `test/scripts/dev-cycle.bats:272-286`; `$S/bats-newtests-on-db0e5ca.txt`

---

## Claim 22: test 20 — "Changed and reverted inside the window: still a change."

**Location:** `test/scripts/dev-cycle.bats:291-292`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the test's assertions can observe. It does not dispute the digest behavior, which Claim 14 verifies.

The line under the comment adds and removes `skills/demo/tmp.md` (`:292`). That path never matches the `skills/.*/SKILL\.md` filter (`scripts/dev-cycle.sh:223`), so no assertion can see it. The revert the test actually checks is the next pair of lines: `workflows/flow.md` is added by "merge: wf" and removed by "drop wf" (`:293-294`), and `"    - workflows/flow.md"` is asserted (`:300`). The comment sits on a case that is not asserted.

**Evidence:** `test/scripts/dev-cycle.bats:288-304`; `scripts/dev-cycle.sh:223`

---

## Claim 23: commit 26b7590 — "R1/A1 (X1): scrub pins perl to bytes (-C0, PERL_UNICODE/PERL5OPT removed), deletes C0 first, and repeats the substitution until stable; test 5 adds split, nested and env cases."

**Location:** `commit 26b7590 message`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mechanism and the test additions. It does not cover the residue in Claim 4.

See Claims 3 and 18. The diff shows `for env in "" PERL_UNICODE=SDA PERL5OPT=-CSD; do` added to test 5 (`test/scripts/dev-cycle.bats:100`).

**Evidence:** `scripts/dev-cycle.sh:34`; `test/scripts/dev-cycle.bats:98-103`; `$S/probe3.out`

---

## Claim 24: commit 26b7590 — "A5: the body runs as a child whose stdout and stderr pass through scrub as pipeline members, so the shell waits for both filters … Exit status is the body's."

**Location:** `commit 26b7590 message`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claims 5 and 7. The ordering clause in the same bullet is split out as Claim 25.

**Evidence:** `scripts/dev-cycle.sh:41-44`; `$S/big-harness.out`; `$S/order-harness.out`

---

## Claim 25: commit 26b7590 — "perl autoflushes, so stream order follows the body."

**Location:** `commit 26b7590 message`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the relative order of stdout and stderr lines when both reach one destination, such as a terminal or `>f 2>&1`. It does not dispute that each stream's own order is kept.

Autoflush (`BEGIN { $| = 1 }`, `scripts/dev-cycle.sh:34`) only flushes each perl's output. The two streams go through two independent perl processes (`:42`), and nothing synchronizes them. In E7, each of three runs whose body alternated `out i` / `err i` produced a different interleaving from the body's (e.g. `2d1 < err 1`, `11d10 < out 6`). Each stream stayed in order on its own. A precise version would read: "each stream keeps its own order; the interleaving of stdout with stderr is not preserved."

**Evidence:** `scripts/dev-cycle.sh:34`, `:42`; `$S/order-harness.out`

---

## Claim 26: commit 26b7590 — "A4: inrepo() reads only regular files whose real path is inside the checkout (symlinked records, log, roadmap, questions, idea log skipped)."

**Location:** `commit 26b7590 message`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which files are skipped. It does not cover the `QUESTIONS_LIVE` residue in Claim 9.

The first clause is exact. The parenthetical over-states it: a symlink whose target is inside the checkout is not skipped. In E9 an in-repo `docs/roadmap.md -> real-road.md` was read (`INREPO-road` count 1). The precise version is "symlinks that resolve outside the checkout are skipped".

**Evidence:** `scripts/dev-cycle.sh:67`; `$S/probe4.out`

---

## Claim 27: commit 26b7590 — "A6 … A7: doc = docs/, *.md, or a file named README / README.* (any case). … A9, C8: test 4's comment and name corrected. C1 (part): section 6 reuses merges_full and caps its list at 30."

**Location:** `commit 26b7590 message`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named change being present and behaving as stated. "any case" applies to README only (Claim 12).

The diff shows the `--help` and Window rewording (`scripts/dev-cycle.sh:10-11`, `:110`), the "midnight" test renamed (`test/scripts/dev-cycle.bats:147`), the README rule (`:205`), test 4's renamed name and comment (`test/scripts/dev-cycle.bats:80-83`), and the cap (`:212-213`). See Claims 1, 12, 13, 17 and 20.

**Evidence:** `git diff db0e5ca..28c6178 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats`; `$S/probe2.out`

---

## Claim 28: commit 26b7590 — "A8: section 7 lists every file a first-parent commit in the window touched (path-limited walk), not a net diff; no base commit any more."

**Location:** `commit 26b7590 message`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 14.

The walk and the removal of `base`/`oldest` are as stated: the diff deletes `oldest=…`, `base=…` and `git diff … "$base" "$MAIN_SHA"`. "Lists every file" does not hold for names git quotes (E11: `skills/café/SKILL.md` was not counted).

**Evidence:** `scripts/dev-cycle.sh:216-224`; `$S/probe5.out`

---

## Claim 29: commit 26b7590 — "20/20 tests; the new scrub, symlink, section 6 and section 7 tests fail on db0e5ca."

**Location:** `commit 26b7590 message`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the HEAD 28c6178 test file against both scripts. It does not cover 26b7590's own bats file (it differs only in test 19's loop and has the same test count).

E1 gave `1..20`, all ok. E2 gave `not ok 5 … scrub`, `not ok 6 a symlink …`, `not ok 19 flags a merge …` and `not ok 20 prints the step 4b and step 5 inputs`; the other 16 were ok.

**Evidence:** `$S/bats-28c6178.txt`; `$S/bats-newtests-on-db0e5ca.txt`

---

## Claim 30: commit 26b7590 — "shellcheck clean."

**Location:** `commit 26b7590 message`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the files 26b7590 changed, linted with health-check.sh's own flags. It does not cover other files in the repo.

At 26b7590, `test/scripts/dev-cycle.bats` line 274 `IFS=: read -r br files want <<< "$spec"` raises `SC2034 (warning): want appears unused`, and shellcheck exits 1 with `-x -e SC1091 -s bash -S warning` (`scripts/health-check.sh:480`; that gate collects `*.bats`, `:459-462`). The script itself was clean. Commit 28c6178 exists to fix exactly this (Claim 31). The precise version is "scripts/dev-cycle.sh shellcheck clean".

**Evidence:** `scripts/health-check.sh:459-462`, `:480`; `$S/shellcheck.txt`

---

## Claim 31: commit 26b7590 Notes — "the re-exec uses DEV_CYCLE_SCRUBBED as an internal marker (an environment that sets it skips the scrub; a repo cannot). A lone 0x9B byte and zero-width characters stay unscrubbed, as the comment says. The redirect test passes on db0e5ca too (truncation is timing-dependent)."

**Location:** `commit 26b7590 message`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each sentence as stated. It does not establish that the comment's list is complete (Claim 4 has the omissions).

E4: setting the marker skipped the scrub. E6: `lone9b: 61 9b 62`. E2: `ok 7 the exit status and the whole digest survive a redirect`.

**Evidence:** `$S/probe1.out`; `$S/probe3.out`; `$S/bats-newtests-on-db0e5ca.txt`

---

## Claim 32: commit 28c6178 — "shellcheck SC2034 (unused \"want\") failed the health-check lint gate."

**Location:** `commit 28c6178 message`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the finding and its removal. It does not establish that the whole health check is green at 28c6178 (only the shellcheck gate was run here).

E3: the 26b7590 bats file exits 1 with SC2034; the 28c6178 file exits 0. The fix is `IFS=: read -r br files _` plus a `want` field used in the assertion loop.

**Evidence:** `test/scripts/dev-cycle.bats:274-286`; `$S/shellcheck.txt`

---

## Claim 33: decision log row 67 — "the self-improvement loop's `feature-ideas*.md` is read as a signal in step 5, so the roadmap is the one backlog (Q-099 [1], 2026-09-30)."

**Location:** `docs/decisions/log.md:90`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Q-099 citation and the step 5 behavior. It does not cover the rest of row 67, which is outside this delta.

`docs/working/questions-archive.md:1800`: "**Answer (2026-09-30, answers-9-30-26.txt): [1].** The roadmap is the one backlog." The skill: "e.g. the self-improvement loop's `docs/working/feature-ideas*.md` in claude-workflows" (`skills/dev-cycle/SKILL.md:156`).

**Evidence:** `docs/working/questions-archive.md:1797-1800`; `skills/dev-cycle/SKILL.md:154-157`

---

## Claim 34: row 68 — "Carry-forward and the `Main at:` handshake are cut, so every trigger is judged every cycle (Q-101 [1])"

**Location:** `docs/decisions/log.md:91`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the skill and digest at their HEADs. It does not establish anything about cycle records already written.

`rg 'Main at' skills/dev-cycle/SKILL.md` returns no hits. The skill says "The previous record's verdicts are context, never the answer: decide each one again" (`skills/dev-cycle/SKILL.md:100-101`). Digest test 3 asserts `"$output" != *"Main at:"*` and passes (E1).

**Evidence:** `skills/dev-cycle/SKILL.md:96-104`; `test/scripts/dev-cycle.bats:66-78`; `$S/bats-28c6178.txt`

---

## Claim 35: row 68 — "step 4 is a claim spot-check and a new conditional step 4b files a full-history deep audit when a skill, the model or a major decision changes"

**Location:** `docs/decisions/log.md:91`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the skill. It does not establish that "files" means anything more than adding a roadmap task. The skill's trigger also includes workflow files.

The skill reads "### 4. Claim spot-check" (`:118`) and "a skill or workflow file added or substantially changed …; a decision record … that is a major design decision; the model running this cycle differs …. Any fired: add a scoped deep-audit task to the roadmap" (`:135-140`).

**Evidence:** `skills/dev-cycle/SKILL.md:118-141`

---

## Claim 36: row 68 — "brainstorm (step 5) is conditional (0–1 items ready, 10+ seeds, a week since the last, a reopened direction, or asked) while seeding is always on"

**Location:** `docs/decisions/log.md:91`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the list of conditions. It does not cover whether the digest supplies the inputs for them (Claims 52 and 64).

The skill's step 5 lists exactly these five conditions (`skills/dev-cycle/SKILL.md:148-152`), and "**Seeding is always on.**" appears at `:41`.

**Evidence:** `skills/dev-cycle/SKILL.md:41-44`, `:143-152`

---

## Claim 37: row 68 — "ready Now items get build briefs and are handed to autonomous RPI loops (step 6b, at most 3 in flight) after the cycle branch lands"

**Location:** `docs/decisions/log.md:91`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the skill text. It does not establish how "in flight" is counted mechanically.

The skill says "Take the Now items whose first step needs no open choice …, up to the in-flight cap: at most 3 loops in flight at once" (`:190-192`) and "Runs after step 7 has landed. … start an autonomous build loop (`research-plan-implement`)" (`:228-229`).

**Evidence:** `skills/dev-cycle/SKILL.md:190-196`, `:226-232`

---

## Claim 38: row 68 — "\"undocumented is broken\" is a rule, checked through the digest's code-without-docs section"

**Location:** `docs/decisions/log.md:91`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rule and the section existing and linking to each other. It does not cover classification edge cases (Claim 12).

The skill has the rule "**Undocumented is broken.**" (`:35`), and step 4 says "Also check every merge the digest lists under "Merges with code but no docs"" (`:123-124`). E10 prints `## 6. Merges with code but no docs`.

**Evidence:** `skills/dev-cycle/SKILL.md:35-39`, `:123-124`; `$S/digest-wt-devcycle.md`

---

## Claim 39: row 68 — "The double-diamond pass's 8 gaps were applied (landing order, in-flight state, 4b inputs, digest failure path, where filed work goes, readiness, subagent use, parallel steps)."

**Location:** `docs/decisions/log.md:91`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the gap names matching the approval doc and each fix appearing in the skill text. It does not establish that the user approved each fix (the doc's checklist items are not marked checked in the read).

The approval doc "Dev cycle skill — for your approval" (read through the Claude Docs connector) lists gaps 1–8 under these names and says "All eight fixes are applied to the steps above (2026-10-01)". Each fix is in the skill (paraphrased — no single quote available because the fixes span steps 0, 1, 6, 6b, 7 and the Rules):
- landing order: `:223-224`
- In flight and the handoff skip: `:89`, `:181`
- 4b inputs: `:133`
- failure path: `:74-76`
- the "work goes to the roadmap" rule: `:30-34`
- readiness: `:190-191`
- subagents: `:56-60`
- parallel steps: `:52`

**Evidence:** `skills/dev-cycle/SKILL.md:30-34`, `:52-60`, `:74-76`, `:89`, `:133`, `:181`, `:190-191`, `:223-224`; claude.ai artifact 78a2f851-e696-4a86-bfe8-474212e5e645 (rev 48)

---

## Claim 40: row 68 — "Revisit if the 6b cap of 3 starves or swamps the review, or if section 7's thresholds never fire in four cycles."

**Location:** `docs/decisions/log.md:91`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers where the thresholds live. It does not judge whether the trigger is a good one.

Section 7 has no thresholds. It prints counts, and says so: `echo "Step 5 (brainstorm triggers; the thresholds are the skill's):"` (`scripts/dev-cycle.sh:235`). The thresholds are in the skill's steps 4b and 5 (`skills/dev-cycle/SKILL.md:135-137`, `:148-152`). The precise version is "the 4b/5 thresholds (fed by section 7)".

**Evidence:** `scripts/dev-cycle.sh:235`; `skills/dev-cycle/SKILL.md:133-152`

---

## Claim 41: row 68 rationale — "User comments on the approval doc, 2026-10-01: the cycle boundary is the only place triggers are certain to be checked; audit is not code review; brainstorm matters most when little is planned; this is the standard loop, so it must hand off to build loops."

**Location:** `docs/decisions/log.md:91`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing beyond the doc body. It does not establish what the user's comments said.

The doc read returned only answered-comment markers (`<comment id='…' to='claude' answered='true'/>`), not comment bodies. The doc body does contain matching prose ("Step 4 … is closer to code review than to an audit"; "Its main trigger is a thin plan"). Verifying the attribution would need a `query` of the doc's comment threads.

**Evidence:** claude.ai artifact 78a2f851-e696-4a86-bfe8-474212e5e645 (rev 48)

---

## Claim 42: docs/dev-cycle-sources.md — "step 5 reads every source when it brainstorms, and always-on seeding appends to the seed log."

**Location:** `docs/dev-cycle-sources.md:3-4`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the skill. It does not cover whether the digest reads this file (it does not; Claim 52).

The skill says "read … the repo's idea sources (those `docs/dev-cycle-sources.md` lists …)" (`skills/dev-cycle/SKILL.md:154-155`) and "The idea log is the file `docs/dev-cycle-sources.md` names as its seed log" (`:42-43`).

**Evidence:** `docs/dev-cycle-sources.md:1-9`; `skills/dev-cycle/SKILL.md:41-44`, `:154-156`

---

## Claim 43: docs/dev-cycle-sources.md — "Feature ideas | docs/working/feature-ideas*.md | the self-improvement loop's idea files"

**Location:** `docs/dev-cycle-sources.md:8`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the path exists. It does not cover the "Done when" policy.

`docs/working/feature-ideas.md` exists. `scripts/archive-working-docs.sh:9` lists `feature-ideas.md` among the self-improvement loop's permanent files.

**Evidence:** `docs/working/feature-ideas.md`; `scripts/archive-working-docs.sh:9`

---

## Claim 44: docs/dev-cycle-sources.md — "Seed log | docs/working/idea-log.md | one `- <idea> (signal: …)` line per idea; step 5 appends `## Brainstorm YYYY-MM-DD` after reading it"

**Location:** `docs/dev-cycle-sources.md:9`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the skill and with the digest's parser for this repo. It does not establish that the file exists yet (it does not; E10 prints "No docs/working/idea-log.md").

The digest uses `LOG=docs/working/idea-log.md` with `^## Brainstorm [0-9]{4}-…` and `/^- /` (`scripts/dev-cycle.sh:244-250`), which matches this row.

**Evidence:** `scripts/dev-cycle.sh:244-250`; `$S/digest-wt-devcycle.md`

---

## Claim 45: docs/roadmap.md gains `## In flight` (commit c079e8c: "the roadmap's In flight section")

**Location:** `docs/roadmap.md:18`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exact-heading match the digest needs. It does not cover item content.

The digest matches `$0 == h` with `h="## $sec"` for `Now`, `In flight` and `Next` (`scripts/dev-cycle.sh:237-238`). E10 printed `Roadmap Now: 1`, `Roadmap In flight: 0` and `Roadmap Next: 5`.

**Evidence:** `docs/roadmap.md:13-20`; `scripts/dev-cycle.sh:236-240`; `$S/digest-wt-devcycle.md`

---

## Claim 46: global decision-tree row 12 — "health and cleanup, every revisit trigger, claim spot-check, conditional deep-audit check and brainstorm, roadmap (`docs/roadmap.md`), then hands ready items to autonomous build loops. User-started, no timer. Output is triage in `docs/working/questions.md`."

**Location:** `global-instructions/CLAUDE.md:32`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the repo copy. It does not cover the installed `~/.claude/CLAUDE.md`, which does not yet have row 12 (install state, out of scope).

This matches the skill's flow (`skills/dev-cycle/SKILL.md:51-54`) and "It runs when the user starts it; there is no timer" (`:14-15`).

**Evidence:** `global-instructions/CLAUDE.md:32`; `skills/dev-cycle/SKILL.md:9-16`, `:51-54`

---

## Claim 47: skill-creation guide row — "steps 0–7 plus conditional 4b and 5 and the 6b handoff … no human checkpoint mid-run beyond the Operating Modes rule (under /active the user confirms the handoff queue, as for any launch; decisions go to questions.md) … Its mechanical parts live in `scripts/dev-cycle.sh`."

**Location:** `guides/skill-creation.md:137`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the skill text at c079e8c. It does not cover human gates inside `pr-prep` when step 7 lands the branch.

The skill says "Under /active the user confirms this queue now; under /away it stands" (`skills/dev-cycle/SKILL.md:192-193`), and commits "follow the Operating Modes rules" (`:27-28`).

**Evidence:** `guides/skill-creation.md:137`; `skills/dev-cycle/SKILL.md:25-29`, `:190-196`

---

## Claim 48: "Every subagent brief this cycle writes (steps 2, 3, 4, 4b, 6b) says so."

**Location:** `skills/dev-cycle/SKILL.md:22-23`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers internal consistency of the skill. It does not judge whether build briefs should carry the line.

The build briefs that 6b launches are written in step 6, not 6b: "For each queued item, write a build brief at `docs/working/handoffs/<date>-<slug>.md` (goal, motive, acceptance criteria including the doc change, branch, out-of-scope, stop conditions)" (`:193-194`). That field list does not include the evidence-not-instructions line, so a reader of step 6 alone would omit it. The precise version is "(steps 2, 3, 4, 4b, and the build briefs step 6 writes)", with step 6's list naming the line.

**Evidence:** `skills/dev-cycle/SKILL.md:20-24`, `:190-196`, `:228-229`

---

## Claim 49: "Run `~/.claude/scripts/dev-cycle.sh` from the repo root (inside claude-workflows, its own `scripts/dev-cycle.sh`)"

**Location:** `skills/dev-cycle/SKILL.md:64-65`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the install mapping. It does not establish that the installed copy is current.

`devcontainer-config/link-claude-home.sh:50` has `ENTRIES=(skills workflows guides patterns hooks scripts CLAUDE.md)`, so `scripts/` is linked to `~/.claude/scripts/`.

**Evidence:** `devcontainer-config/link-claude-home.sh:43-50`

---

## Claim 50: "It is read-only."

**Location:** `skills/dev-cycle/SKILL.md:66`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the working tree and index of the repo it ran in. It does not cover the temp file outside the repo (`mktemp`, removed by `trap … EXIT`, `scripts/dev-cycle.sh:157`).

E10: `git status --short` in wt-devcycle was the same before and after the run.

**Evidence:** `scripts/dev-cycle.sh:157`; `$S/digest-wt-devcycle.md`

---

## Claim 51: "Its sections feed the steps: 1 activity (context), 2 triggers (step 2), 3 watched questions (step 3), 4 spot-check sample and 6 merges with code but no docs (step 4), 5 roadmap (step 6), 7 inputs (steps 4b and 5)."

**Location:** `skills/dev-cycle/SKILL.md:66-68`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers section numbers and names. It does not cover section 5 printing only the roadmap's Next section (`scripts/dev-cycle.sh:191-193`), although step 6 updates every section.

E10 headings: `## 1. Activity`, `## 2. Revisit triggers`, `## 3. Watched questions (trigger and deferred routes)`, `## 4. Spot-check sample`, `## 5. Roadmap`, `## 6. Merges with code but no docs`, `## 7. Inputs for steps 4b and 5`.

**Evidence:** `scripts/dev-cycle.sh:113`, `:125`, `:153`, `:178`, `:188`, `:198`, `:216`; `$S/digest-wt-devcycle.md`

---

## Claim 52: seed-log contract — "The idea log is the file `docs/dev-cycle-sources.md` names as its seed log when that file exists, else `docs/working/idea-log.md`" with step 5's "(inputs: the digest's section 7)" and "append `## Brainstorm YYYY-MM-DD` to the idea log, so the next digest counts seeds from here"

**Location:** `skills/dev-cycle/SKILL.md:42-44`, `:146`, `:159-160`
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers any repo whose `docs/dev-cycle-sources.md` names a seed log other than `docs/working/idea-log.md`. It does not affect claude-workflows today: its sources file names exactly that path (`docs/dev-cycle-sources.md:9`), so the two agree here.

The digest never reads `docs/dev-cycle-sources.md`: `rg dev-cycle-sources scripts/dev-cycle.sh` finds no hits. It hard-codes `LOG=docs/working/idea-log.md` (`scripts/dev-cycle.sh:244`). In a repo that names another seed log, section 7 would report "No docs/working/idea-log.md: no ideas seeded, no brainstorm recorded" (`:258`), or read a stale file, while seeds and the `## Brainstorm` heading go elsewhere. The "10+ ideas seeded" and "a week since the last brainstorm" triggers would then be decided on the wrong data, and "so the next digest counts seeds from here" would be false. The installed digest is meant to serve any project ("so the installed copy serves any project", `scripts/dev-cycle.sh:17-18`). Prior finding A2 (the section 7 step-5 contract) is therefore closed for the default path only. Either the digest reads the sources file's seed-log row, or the skill fixes the seed log at `docs/working/idea-log.md`.

**Evidence:** `skills/dev-cycle/SKILL.md:41-44`, `:143-160`; `scripts/dev-cycle.sh:17-18`, `:244-258`; `docs/dev-cycle-sources.md:9`

---

## Claim 53: "If the repo has no `docs/working/questions.md`, run `~/.claude/scripts/questions.sh init` first."

**Location:** `skills/dev-cycle/SKILL.md:68-69`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the subcommand existing and creating the file. It does not cover `questions.sh` refusing symlinked targets.

`scripts/questions.sh:447`: `init)    cmd_init ;;`. Its comment reads "Create whichever of the two files is missing" (`:416-418`).

**Evidence:** `scripts/questions.sh:416-447`

---

## Claim 54: "If the window starts before the last cycle you know ran (or says no cycle record was found when one ran), that cycle skipped step 7 … rerun with `--since` set to that cycle's date."

**Location:** `skills/dev-cycle/SKILL.md:69-72`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the digest's source note and `--since` override. It does not cover future-dated records, which the digest ignores (`scripts/dev-cycle.sh:96`).

The source note is `"no cycle record found, so the default of 14 days …"` or `"the last cycle record, docs/working/cycles/cycle-$last_record.md"` (`:101-104`). Bats test 9 (window from the record) and E10 (no record) print it.

**Evidence:** `scripts/dev-cycle.sh:92-105`; `$S/digest-wt-devcycle.md`; `$S/bats-28c6178.txt`

---

## Claim 55: "If the digest fails (non-zero exit or a missing section), stop the cycle"

**Location:** `skills/dev-cycle/SKILL.md:74-76`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a mid-digest failure being observable both ways. It does not cover a digest that exits 0 with a section whose content is wrong.

In E4 the forced `shuf` failure gave exit 7 with only 4 `## ` headings, so both detection signals fire. The header promises "a failed step exits non-zero mid-digest" (`scripts/dev-cycle.sh:19-20`), and Claim 7 shows the re-exec keeps that status.

**Evidence:** `scripts/dev-cycle.sh:19-20`, `:41-44`; `$S/probe1.out`

---

## Claim 56: "triage them as pr-prep step 5a does (caused by recent work, pre-existing, flaky)"

**Location:** `skills/dev-cycle/SKILL.md:83-84`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the reference target. It does not cover pr-prep's re-run procedure details.

`workflows/pr-prep.md:315`: "**a. Verify CI passes (automated).**" (under "#### 5. Verify and annotate"). The class table is at `:341-343`: "Caused by this branch | … Pre-existing on main | … Flaky / infra / environmental".

**Evidence:** `workflows/pr-prep.md:311-353`

---

## Claim 57: "`~/.claude/scripts/questions.sh archive` then `index`, so answered entries leave the live file."

**Location:** `skills/dev-cycle/SKILL.md:85-86`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the subcommands existing. It does not cover redundancy: `cmd_archive` already calls `cmd_index` (`scripts/questions.sh:393`).

The dispatch is `scripts/questions.sh:449-450`: `index)   cmd_index ;;` / `archive) cmd_archive ;;`.

**Evidence:** `scripts/questions.sh:374-393`, `:445-452`

---

## Claim 58: "Do not run `archive-working-docs.sh`: it serves the self-improvement loop and moves files into a gitignored archive."

**Location:** `skills/dev-cycle/SKILL.md:91-93`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the script header and gitignore. It does not cover its dry-run mode.

The script header says "Archive docs/working/ artifacts from a completed self-improvement run. … Moves all non-permanent files from docs/working/ into docs/working/archive/" (`scripts/archive-working-docs.sh:2-6`). `git check-ignore -v` gives `.gitignore:16:docs/working/archive/`.

**Evidence:** `scripts/archive-working-docs.sh:2-12`; `.gitignore:16`

---

## Claim 59: "If the digest says `questions.sh open` failed, fix that first; the section was not checked."

**Location:** `skills/dev-cycle/SKILL.md:116`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the digest's failure text. It does not cover a `questions.sh` that is missing entirely, which prints "No docs/working/questions.md (or questions.sh)".

`scripts/dev-cycle.sh:170`: `echo "**questions.sh open failed** — watched questions were NOT checked. Its error:"`. Bats test 15 passes.

**Evidence:** `scripts/dev-cycle.sh:156-176`; `$S/bats-28c6178.txt`

---

## Claim 60: "Also check every merge the digest lists under \"Merges with code but no docs\""

**Location:** `skills/dev-cycle/SKILL.md:123-124`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the section name. It does not cover merges past the cap of 30, which are counted, not listed (`scripts/dev-cycle.sh:213`).

`scripts/dev-cycle.sh:198`: `"## 6. Merges with code but no docs"`.

**Evidence:** `scripts/dev-cycle.sh:198-214`

---

## Claim 61: 4b "Its triggers, from the digest's section 7 and the last record"; "the model running this cycle differs from the last record's `Model:` line"

**Location:** `skills/dev-cycle/SKILL.md:133-137`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the inputs. It does not cover quoted-name omissions in section 7 (Claim 14), or whether "substantially changed" can be judged from a file list.

The digest prints `"Step 4b (deep-audit triggers). The model version is not in git: compare it with the last cycle record's."` (`scripts/dev-cycle.sh:225`) and the two lists (E10). The record template has `Model: <the model id running this cycle>` (`skills/dev-cycle/SKILL.md:205`).

**Evidence:** `scripts/dev-cycle.sh:225-233`; `skills/dev-cycle/SKILL.md:205`; `$S/digest-wt-devcycle.md`

---

## Claim 62: "e.g. the self-improvement loop's `docs/working/feature-ideas*.md` in claude-workflows"

**Location:** `skills/dev-cycle/SKILL.md:156`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the path exists. It does not cover the files' format.

`docs/working/feature-ideas.md` exists.

**Evidence:** `docs/working/feature-ideas.md`

---

## Claim 63: "A choice among 3+ approaches is flagged for `divergent-design`"; 6b "(`research-plan-implement`)"

**Location:** `skills/dev-cycle/SKILL.md:158`, `:229`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the named workflows exist. It does not cover how a build loop is launched (subagent or session).

`workflows/divergent-design.md` and `workflows/research-plan-implement.md` exist, as do their router skills.

**Evidence:** `workflows/divergent-design.md`; `workflows/research-plan-implement.md`

---

## Claim 64: "it runs only when one of these holds (inputs: the digest's section 7): roadmap Now + Next hold 0–1 items ready for 6b; …"

**Location:** `skills/dev-cycle/SKILL.md:146-148`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what section 7 supplies and the meaning of "ready for 6b". The seed-log path problem is Claim 52.

Section 7 supplies item counts per section (`scripts/dev-cycle.sh:237-239`), not readiness. Two of the five conditions (a fired trigger, the user asks) do not come from section 7. And only Now items can be handed to 6b ("Take the Now items whose first step needs no open choice", `skills/dev-cycle/SKILL.md:190`), so a Next item is never "ready for 6b". The precise version is "Now holds 0–1 items ready for 6b (section 7 gives the counts; readiness is judged)".

**Evidence:** `skills/dev-cycle/SKILL.md:146-152`, `:190`; `scripts/dev-cycle.sh:235-243`

---

## Claim 65: roadmap template headings "## Now / ## In flight / ## Next / ## Ideas / ## Done"

**Location:** `skills/dev-cycle/SKILL.md:173-177`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exact-match headings the digest counts and prints. It does not cover heading variants a user might type (e.g. `## In Flight`, which would count 0).

The digest matches `## Now`, `## In flight` and `## Next` exactly (`scripts/dev-cycle.sh:237-238`), and `/^## Next/` for section 5 (`:193`).

**Evidence:** `scripts/dev-cycle.sh:193`, `:237-238`; `$S/digest-wt-devcycle.md`

---

## Claim 66: handoff queue — briefs written in step 6, "Both land with step 7, so the briefs are on the default branch before any loop starts"; 6b "Runs after step 7 has landed"

**Location:** `skills/dev-cycle/SKILL.md:190-196`, `:228`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers internal consistency of landing order (step 6 writes, step 7 lands, 6b launches). It does not establish what happens when pr-prep in step 7 does not merge, a case the skill does not address.

The flow line reads `6 roadmap → 7 close (lands the branch) → 6b handoff → final message` (`:53`), and step 7 says "land … through `pr-prep` before step 6b" (`:223-224`).

**Evidence:** `skills/dev-cycle/SKILL.md:51-54`, `:190-196`, `:220-229`

---

## Claim 67: "at most 3 loops in flight at once, counting earlier cycles'"; "Under /active the user confirms this queue now; under /away it stands."

**Location:** `skills/dev-cycle/SKILL.md:191-193`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the approval doc and the commit Notes. It does not establish a mechanical count: the digest counts In flight items (`scripts/dev-cycle.sh:237-239`), and nothing removes a finished item until the next cycle (`:231-232`).

The approval doc's 6b row says "At most 3 loops are in flight at once, counting earlier cycles'" and "Under /active you confirm the queue before launch; under /away it launches."

**Evidence:** `skills/dev-cycle/SKILL.md:190-196`, `:231-232`; claude.ai artifact 78a2f851-e696-4a86-bfe8-474212e5e645

---

## Claim 68: "Write `docs/working/cycles/cycle-YYYY-MM-DD.md` (if one exists for today, update it in place)"

**Location:** `skills/dev-cycle/SKILL.md:200`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the name the digest globs. It does not cover names with a suffix (e.g. `cycle-2026-10-01b.md`), which the digest would ignore.

The digest globs `docs/working/cycles/cycle-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md` (`scripts/dev-cycle.sh:93`). Test 9 passes.

**Evidence:** `scripts/dev-cycle.sh:92-101`; `$S/bats-28c6178.txt`

---

## Claim 69: template verdict names "docs/decisions/014-secure-tool-guidance-layers.md" and "log row 62"; "Record one verdict for every trigger, under the name the digest prints."

**Location:** `skills/dev-cycle/SKILL.md:214-220`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the names matching real digest output. It does not cover the date suffix the digest appends (`(last committed …)`, `(2026-09-28)`), which the template drops.

E10 printed `### docs/decisions/014-secure-tool-guidance-layers.md (last committed on this branch: 2026-09-26)` and `- log row 62 (2026-09-28): > Revisit if …`.

**Evidence:** `scripts/dev-cycle.sh:136`, `:148`; `$S/digest-wt-devcycle.md`

---

## Claim 70: "The next digest starts its window from this file's date (only the file name is read)"

**Location:** `skills/dev-cycle/SKILL.md:220-221`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the digest at 28c6178. It does not cover future-dated names, which are ignored.

The date comes from the name: `d="${f##*/cycle-}"; d="${d%.md}"` (`scripts/dev-cycle.sh:95`). The file is never opened (`:93-97`). Test 3 writes a `Main at:` body and the digest does not echo it.

**Evidence:** `scripts/dev-cycle.sh:92-101`; `test/scripts/dev-cycle.bats:66-78`

---

## Claim 71: "if a cycle skips its record, the next window silently widens, so never skip it."

**Location:** `skills/dev-cycle/SKILL.md:221-222`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether the digest discloses the widened window. It does not judge the advice.

The window does widen, but the digest names its source: `source_note="the last cycle record, docs/working/cycles/cycle-$last_record.md"` or `"no cycle record found, so the default of 14 days (the previous cycle, if any, did not write its record)"` (`scripts/dev-cycle.sh:101-104`). Step 0 relies on that note (`skills/dev-cycle/SKILL.md:69-72`). The precise version is "widens, and only step 0's check of the Window line catches it".

**Evidence:** `scripts/dev-cycle.sh:98-105`; `skills/dev-cycle/SKILL.md:69-72`

---

## Claim 72: "land `chore/dev-cycle-<date>` on the default branch through `pr-prep` before step 6b: the next digest and the build loops both start from the default branch."

**Location:** `skills/dev-cycle/SKILL.md:223-224`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers which inputs come from the default branch. It does not dispute the landing order.

The digest walks the default branch only for merges, commits and section 7. The cycle-record date, triggers, questions, roadmap and idea log come from the working tree where it runs: "Triggers: all of them, from the working tree. Questions, roadmap, idea log: the working tree." (`scripts/dev-cycle.sh:110`). The next window comes from the record in that checkout, not from the default branch, so landing is necessary but not sufficient. The precise version is "… the next digest (run on an up-to-date default-branch checkout) and the build loops …".

**Evidence:** `scripts/dev-cycle.sh:92-110`

---

## Claim 73: skill description — "digest, health and cleanup, revisit triggers, watched questions, claim spot-check, conditional deep-audit check and brainstorm, roadmap, close, then hand ready roadmap items to autonomous build loops"

**Location:** `skills/dev-cycle/SKILL.md:4`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the step list. It does not cover trigger-phrase quality.

This matches headings 0–7, 4b and 6b (`:62`, `:78`, `:96`, `:106`, `:118`, `:128`, `:143`, `:162`, `:198`, `:226`).

**Evidence:** `skills/dev-cycle/SKILL.md:4`, `:62-226`

---

## Claim 74: "Steps 2, 3, 4 and 4b depend only on 0 and 1, not on each other: run them in parallel as subagents … Step 4 uses one read-only subagent per sampled merge."

**Location:** `skills/dev-cycle/SKILL.md:56-58`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers data independence of the steps' inputs. It does not cover write conflicts: step 3 may do up to 3 in-cycle fixes (`:112-113`) and step 4 may "fix it if mechanical" (`:124-125`), both on the same branch, in parallel.

Step 2 reads digest section 2, step 3 section 3, step 4 sections 4 and 6, and 4b section 7 plus the last record. None reads another's output.

**Evidence:** `skills/dev-cycle/SKILL.md:56-60`, `:96-141`

---

## Claim 75: step 3 — "One opened before the last cycle record is stale and gets an action now: if it clears step 1's bar (mechanical, small, one commit), do it in-cycle, at most 3 per cycle, oldest first"

**Location:** `skills/dev-cycle/SKILL.md:111-115`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with commit c079e8c and the approval doc. It does not cover how "opened" is read (the entry's `**Opened:**` field, which the digest does not print).

The approval doc's step 3 row says "one that clears step 1's bar (mechanical, small, one commit) is done in-cycle, at most 3, oldest first".

**Evidence:** `skills/dev-cycle/SKILL.md:106-116`; claude.ai artifact 78a2f851-e696-4a86-bfe8-474212e5e645

---

## Claim 76: step 1 — "Skip any branch or worktree an open handoff brief (`docs/working/handoffs/`) names"

**Location:** `skills/dev-cycle/SKILL.md:88-90`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the path matches where step 6 writes briefs. It does not establish that the directory exists yet (it does not).

Step 6 writes "a build brief at `docs/working/handoffs/<date>-<slug>.md`" (`:193`).

**Evidence:** `skills/dev-cycle/SKILL.md:88-90`, `:193`

---

## Claim 77: commit c079e8c bullets — "No `Main at:` line and no carried verdicts …; the record names the model for step 4b"; "Four rules (adds \"undocumented is broken\"); seeding always on, to the seed log docs/dev-cycle-sources.md names (default docs/working/idea-log.md)"; "Flow: 2, 3, 4, 4b in parallel …; 4b … and 5 … conditional, with the user's thresholds (0-1 ready items, 10+ seeds, a week by date)"; "Step 3 acts on stale agent entries (in-cycle when small, at most 3)"; "Roadmap gains In flight; step 6 writes the handoff briefs …; step 7 lands it via pr-prep; 6b then launches RPI build loops (at most 3 in flight); the final message comes last."

**Location:** `commit c079e8c message`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each bullet against the committed skill. It does not cover the digest-side gap for the non-default seed log (Claim 52).

The Rules section has 4 bullets (`skills/dev-cycle/SKILL.md:20-39`), and the template has `Model:` (`:205`). For the rest, see Claims 34–37, 66, 67 and 75. The final message is at `:234-235`.

**Evidence:** `skills/dev-cycle/SKILL.md:18-60`, `:190-235`

---

## Claim 78: commit c079e8c — "All 8 double-diamond gaps applied, incl. the digest failure path."

**Location:** `commit c079e8c message`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Same as Claim 39. Note that `docs/working/questions-archive.md` (Q-101's answer) still says "double-diamond gaps #1, #2, #4–8 still await the user". The approval doc later records them as applied; that archive line is outside this diff.

**Evidence:** claude.ai artifact 78a2f851-e696-4a86-bfe8-474212e5e645; `skills/dev-cycle/SKILL.md:74-76`

---

## Claim 79: commit c079e8c — "Also: decision log row 68, global decision-tree row 12, the skill-creation guide row, the roadmap's In flight section, and docs/dev-cycle-sources.md for this repo."

**Location:** `commit c079e8c message`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each listed change being in the diff. It does not cover completeness: the commit also edits decision log row 67 (the Q-099 wording, Claim 33), which the list does not name.

`git diff --stat 6ee33e3..c079e8c` touches exactly these 6 files.

**Evidence:** `docs/decisions/log.md:90-91`; `docs/dev-cycle-sources.md`; `docs/roadmap.md:18`; `global-instructions/CLAUDE.md:32`; `guides/skill-creation.md:137`

---

## Claim 80: commit c079e8c Notes — "brief-writing moved from 6b into step 6 so briefs land with the cycle branch … (the doc said 6b writes briefs; the landing-order fix required the move). The /active confirmation therefore happens at step 6."

**Location:** `commit c079e8c message`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the doc's 6b row and the skill's step 6. It does not cover the Rules line that still attributes the briefs to 6b (Claim 48).

The approval doc's 6b row says "Per item, a build brief at `docs/working/handoffs/<date>-<slug>.md` …". The skill's step 6 says "Under /active the user confirms this queue now; … For each queued item, write a build brief" (`skills/dev-cycle/SKILL.md:192-193`).

**Evidence:** `skills/dev-cycle/SKILL.md:190-196`; claude.ai artifact 78a2f851-e696-4a86-bfe8-474212e5e645

---

## Prior final-pass-4 findings: closure check (advisory)

- **R1** (scrub bypass by split or nested sequences): closed (Claim 3). The residue in Claim 4 is documented, but the list is incomplete.
- **A1** (PERL_UNICODE/PERL5OPT): closed (Claim 3).
- **R2/A3** (`Main at:` and carried verdicts in the skill): closed (Claim 34).
- **A2** (section 7 / step 5 contract): closed for the default seed-log path only (Claim 52).
- **A4** (symlinks followed): closed (Claim 9).
- **A5** (filters not waited for): closed (Claim 5).
- **A6** (committer-zone date): closed (Claim 1).
- **A7** (README classification): closed (Claim 12).
- **A8** (net diff misses reverts): closed (Claim 14), with a new residue: git-quoted names are dropped.
- **A9** (test 4 comment): closed (Claim 17).

## Claims Requiring Attention

### Incorrect
- **Claim 25** (`commit 26b7590`): "perl autoflushes, so stream order follows the body". Two independent scrub processes do not keep stdout/stderr interleaving (E7). Each stream keeps only its own order.
- **Claim 30** (`commit 26b7590`): "shellcheck clean". The bats file at 26b7590 fails SC2034 under the gate's flags (E3), which is why 28c6178 exists. Only the script was clean.
- **Claim 52** (`skills/dev-cycle/SKILL.md:42-44`, `:146`, `:159-160`): the seed log can be renamed via `docs/dev-cycle-sources.md`, but the digest hard-codes `docs/working/idea-log.md` (`scripts/dev-cycle.sh:244`), so section 7's seed count and last-brainstorm date would come from the wrong file in such a repo. Harmless in claude-workflows today.

### Stale
- (none)

### Mostly Accurate
- **Claim 4** (`scripts/dev-cycle.sh:31-32`): "Not covered" names only 0x9B. All lone 0x80–0x9F bytes (0x90 DCS, 0x9D OSC, 0x9C ST), U+061C and U+2028/2029 also pass.
- **Claim 14** (`scripts/dev-cycle.sh:217-219`): "every file … touched". Names git quotes (non-ASCII or control bytes) reach `changed` but the grep filters drop them; `skills/café/SKILL.md` counted 0 (E11).
- **Claim 22** (`test/scripts/dev-cycle.bats:291`): the "changed and reverted" comment sits on `skills/demo/tmp.md`, which no assertion can observe. The asserted revert is `workflows/flow.md`.
- **Claim 26** (`commit 26b7590`, A4): "symlinked … skipped". Only symlinks resolving outside the checkout are skipped.
- **Claim 28** (`commit 26b7590`, A8): "lists every file". Same quoted-name residue as Claim 14.
- **Claim 40** (`docs/decisions/log.md:91`): "section 7's thresholds". Section 7 prints inputs; the thresholds are the skill's.
- **Claim 48** (`skills/dev-cycle/SKILL.md:22`): lists "6b" as a brief-writing step. Step 6 writes the build briefs, and its field list omits the evidence-not-instructions line.
- **Claim 64** (`skills/dev-cycle/SKILL.md:146-148`): "Now + Next hold 0–1 items ready for 6b". Only Now items can be handed off; section 7 gives raw counts, not readiness; two of five conditions are not section 7 inputs.
- **Claim 71** (`skills/dev-cycle/SKILL.md:221`): "silently widens". The digest's Window line names the record or the 14-day fallback.
- **Claim 72** (`skills/dev-cycle/SKILL.md:223-224`): "the next digest … start[s] from the default branch". The window start, triggers, roadmap and questions come from the working tree where the digest runs.

### Unverifiable
- **Claim 41** (`docs/decisions/log.md:91`): the row 68 rationale attributes points to the user's doc comments. Checking it needs the comment threads (`query` on the doc). The doc body has matching prose.

## Goal-Alignment Note

Success criterion (verbatim from the brief): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-r2-digest-final5.md`. Its first line is `Commit: 28c6178 (A) / c079e8c (B)`. It is structured per `skills/code-fact-check/SKILL.md`: the header fields, then 80 claims, each with the seven mandatory fields, then Claims Requiring Attention. It covers units A and B and their contract, giving priority to the brief's nine "particularly need checking" items. Executed verdicts carry provenance in the table above, with captured outputs in the scratch directory. In line with the brief's probe-cleanup rule, nothing was written to either worktree apart from this file, all temp repos were removed, and no probe processes remain. As a consequence the hallucination-pattern log was not updated (no qualifying fabrication was found anyway). Nothing was committed.
