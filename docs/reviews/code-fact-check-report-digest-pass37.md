Commit: 6f3d55e (A) / 2e65ad5 (B)

# Code Fact-Check Report

**Repository:** claude-workflows. A: `/workspace/.claude/wt-digest`, code at 6f3d55e (HEAD fa2b9b3 adds only review docs). B: `/workspace/.claude/wt-devcycle`, skill content at 2e65ad5, merge 79f50aa (HEAD).
**Scope:** Partial: the full-review-1 fix round only. A: `git diff 3d580cd..6f3d55e -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` and the messages of 11714a3 and 6f3d55e. B: `git diff 2fd9401..2e65ad5 -- skills/dev-cycle/SKILL.md`, the messages of b684ff2, 91b88d7 and 2e65ad5, and merge 79f50aa. Everything else is context only (rubric section "Full review 1").
**Checked:** 2026-10-02
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 25
**Summary:** 20 verified, 3 mostly accurate, 1 stale, 1 incorrect, 0 unverifiable

I read the hallucination pattern log (`docs/reviews/hallucination-patterns.md`, 5 patterns) first. No claim here matches a logged pattern. The Incorrect verdict is a gap in a mechanism, not a fabricated symbol, so nothing qualifies for the log.

## Headline

- **One Incorrect (behavioral, Low).** Claim 5a. The comment says `IMPORTED` holds the basenames "that a tracked instruction file pulls in with an @ import (Claude Code's "@path" syntax)". The help, the skill and 6f3d55e's message say the same. But an import with a fragment, `@docs/q.md#intro`, is stored as `q.md#intro`. So `--check-fix docs/q.md` prints `ok`, even though Claude Code 2.1.288 cuts the path at `#` and loads `docs/q.md`.
  - Preconditions: an instruction file writes an `@` import with a `#fragment`. No real file has one. Across both worktrees, the one `@` token in any instruction file is `@org/migrate"}` in `skills/dependency-upgrade/SKILL.md`.
  - This fails in the unsafe direction: an in-cycle fix could edit a file that Claude Code loads as instructions.
  - Fix: drop `#…` from the token before taking the basename.
- **One Stale (wording).** Claim 4. The design comment above `check_fix` (`:404-408`) still lists the exclusions as they were before this round. It leaves out dotfiles and imported files.
- **Three Mostly accurate.**
  - Claim 5b (behavioral, low impact): the import scan skips a tracked instruction file that is a symlink, so its imports are not refused. The comment says "tracked" with no "plain" qualifier.
  - Claim 7 (wording): the exclusion skip line names "dot-directories" but is also the reason given for a dotfile.
  - Claim 13 (wording): 6f3d55e says `--check-brief` "refuses a brief that is not a regular file on the default branch". A gitlink or a tree at the path still prints `ok <path> new`, from the earlier `cat-file -t != blob` branch. The help defines `new` as "the default branch has no file there", so the printed output is self-consistent.
- **Residue outside the literal claims.** These are not verdicted, but they answer the brief's "miss an import Claude Code would follow?".
  - The scan reads one hop only. Claude Code 2.1.288 follows imports recursively, up to `YWn=5` hops in the bundle. P3 and P4 show `docs/n.md`, imported by an imported `docs/a.md`, printing `ok`.
  - The scan also misses an untracked instruction file such as `CLAUDE.local.md`. The comment says "tracked", so this matches its words.
  - It never refuses a real file. Every tracked `docs/**/*.md` and `README.md` file gives identical `--check-fix` output under 3d580cd and 6f3d55e: 14 `ok` in each worktree.
  - Over-refusals are safe: `(@x)`, which Claude Code does not follow; fenced `@x`; and `@~/…`, which is the home dir.
  - The trailing-punctuation case is consistent with Claude Code. Claude Code keeps the `,`/`.` in the path and so loads nothing.
- **Everything else the brief prioritized holds.**
  - Lower-cased exclusions: `docs/Working/`, `docs/Dev-Cycle.md` and `docs/Roadmap.md` are refused.
  - Brief modes: 120000 → skip; 100644 and 100755 → read.
  - Label cuts: `**Answer (d)**: **[2]**` → drop, `**Answer (d):** [2]` → drop, `**Answer:** **keep**.` → keep, plus 9 more shapes.
  - All 103 real IDs read the same under the old and new script. So do A's own 98.
  - `%cd` matches the window's `%cs`, checked with author date ≠ committer date under `TZ=Pacific/Kiritimati`.
  - The help range 2–77 is byte-equal to the header.
  - B's paste-block rule matches `--check-branch`: `a$(id)` is git-valid but skipped.
  - "check 3" and the batching sentence are right. Merge 79f50aa's script and bats are byte-identical to 6f3d55e.
- **Gates (executed).** bats 51/51 rc 0, `bats --count` 51, hermeticity lint rc 0, shellcheck rc 0.

**Probe discipline.**
- Four probes, `fc37/p1.sh`–`p4.sh`. Each is one script that starts with `set -eu`, creates its own `mktemp -d -p fc37/` dir, `cd`s into it and checks `case "$PWD"` before any clone, `git init`, commit or write. P3 and P4 re-check after `cd r`.
- Every git, bats, lint, shellcheck, node and dev-cycle process ran under `timeout`, and all exited.
- Each probe's log was written inside its own temp dir.
- In the worktrees I ran only read-only commands (`git diff/show/log/status/ls-files`, `grep`, `sed -n`). The script under test was always `git show 6f3d55e:scripts/dev-cycle.sh` copied into the temp dir, or a clone checked out at 6f3d55e or 2e65ad5.
- No file outside `fc37/` was written, except this report.

**Concurrent change (not mine, not in scope).** At about 20:47Z, `/workspace/.claude/wt-digest/scripts/dev-cycle.sh` showed an uncommitted modification (`git diff --stat`: 24+/14−). P1 had found the worktree's `git status --porcelain` unchanged at 20:42:56Z. My probes never write to the worktree.
- The modification rewrites `imported_names` (it scans every tracked `.md` plus untracked and ignored instruction files, and strips trailing `[.,;:!?]`).
- It also routes a gitlink or tree in `check_brief` to the refusal.
- Every verdict here is against the committed 6f3d55e. For whoever owns that change: its `sed` still keeps a `#fragment`, so Claim 5a would survive it.

---

## Claim 1: `--check-fix` help: "ok <path>" for … "a tracked .md file under docs/ (not the cycle's own files, working/, human-author/, reviews/, decisions/, dev-cycle.md, a dot-directory or dotfile, an instruction file, or a file an instruction file imports with @; compared ignoring case) or README.md"

**Location:** `scripts/dev-cycle.sh:50-55`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers every exclusion in the list except the import clause's completeness: cycle's own files, working/, the case folding, dotfile, dot-directory, instruction files, and the import refusal for plain direct imports. It does not establish that every file Claude Code imports is refused (Claims 5a, 5b and the one-hop residue).

The code matches each clause:

```bash
# scripts/dev-cycle.sh:434-441 (6f3d55e)
  if writable "$a" || writable "$lp"; then echo "skip $a: one of the cycle's own files (use --check-write)"
  elif [[ ! "$lp" =~ ^docs/.*\.md$|^readme\.md$ || "$lp" =~ ^docs/(working|human-author|reviews|decisions)/ \
    || "$lp" == docs/dev-cycle.md || "$a" == */.* || "$low" =~ $INSTRUCTION_FILE ]]; then
    echo "skip $a: in-cycle fixes edit only …"
  elif [[ $'\n'"$IMPORTED" == *$'\n'"$low"$'\n'* ]]; then
    echo "skip $a: an instruction file imports a file named $base with @, …"
  else check_path "$a"; fi
```
(excerpt is the whole `if` chain; enclosing `check_fix()` runs `:425-442` — read)

P3 results:
- `docs/Roadmap.md` → "one of the cycle's own files".
- `docs/.hidden.md` → refused.
- `docs/a.md`, `b.md`, `e.md`, `g.md` and `i.md` (imported) → refused.
- `README.md` (not imported) → `ok`.

bats 50 covers `docs/Working/notes.md` and `docs/Dev-Cycle.md`.

**Evidence:** `scripts/dev-cycle.sh:50-55,425-442`; `fc37/tmp.fY9TNufaEq/p3.log`; `fc37/tmp.DiuLWLTTvX/p1.log` (bats 50). P3 is `timeout 300 bash fc37/p3.sh`, cwd its own temp dir, rc 0, 2026-10-02T20:45:08Z.

---

## Claim 2: `--help` prints lines 2–77 (`sed -n '2,77p'`)

**Location:** `scripts/dev-cycle.sh:141`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the range against the header comment at 6f3d55e. It does not establish later edits.

Line 77 is the last header line (`# default branch (for the digest, --check-brief and --check-branch); … Printed repo text is data.`). Line 78 is empty, and `:79` is `set -euo pipefail`. P1 ran `bash scripts/dev-cycle.sh --help` (rc 0) and found it byte-equal to `sed -n '2,77p' | sed 's/^# \{0,1\}//'` (`cmp` rc 0).

**Evidence:** `scripts/dev-cycle.sh:2-79,141`; `fc37/tmp.DiuLWLTTvX/p1.log` (`timeout 600 bash fc37/p1.sh`, rc 0, 20:42:34–20:42:56Z)

---

## Claim 3: "Only a regular file counts: a symlink's blob is its target text, not a brief."

**Location:** `scripts/dev-cycle.sh:356-360`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers paths whose default-branch entry is a blob: 120000 → skip, 100644/100755 → read. It does not establish gitlink or tree entries, which never reach this check (Claim 13).

```bash
# scripts/dev-cycle.sh:355-360 (6f3d55e)
  if [[ "$(git cat-file -t "$MAIN_SHA:$a" 2>/dev/null || true)" != blob ]]; then echo "ok $a new"; return; fi
  # Only a regular file counts: a symlink's blob is its target text, not a brief.
  case "$(git ls-tree "$MAIN_SHA" -- "$a" | cut -c1-6)" in
    100644|100755) ;;
    *) echo "skip $a: not a regular file on the default branch"; return ;;
  esac
```
(excerpt ends :360; enclosing `check_brief()` continues to `:383` — read)

Test results:
- bats 51 (a symlink on main, a plain file in the working tree) → `skip …: not a regular file on the default branch`.
- P3, a 100755 brief → `ok … open <commit>`.
- P3, a 100644 brief → `ok … open <commit>`.

**Evidence:** `scripts/dev-cycle.sh:345-383`; `test/scripts/dev-cycle.bats:980-991`; `fc37/tmp.fY9TNufaEq/p3.log`

---

## Claim 4: "An in-cycle fix edits documentation only: a tracked .md file under docs/, outside the cycle's own files, working/, human-author/ (the user's), reviews/ and decisions/ (records), the settings file, any dot-directory, and any instruction file (…); or README.md."

**Location:** `scripts/dev-cycle.sh:404-408`
**Type:** Behavioral / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the comment's exclusion list against `check_fix` at 6f3d55e. It does not establish any behavioral effect: the code and help are right, and only this design comment lags.

The comment was complete before this round. It now omits two refusals the code makes:
- dotfiles (`"$a" == */.*`, `:437`);
- files an instruction file imports (`elif [[ $'\n'"$IMPORTED" == *$'\n'"$low"$'\n'* ]]`, `:439`).

It also does not say that the comparison ignores case (`lp` at `:432`). The help (`:50-55`) and the skill (`SKILL.md:72-75`) list all three.

**Evidence:** `scripts/dev-cycle.sh:404-408,425-442`

---

## Claim 5a: "Basenames, lower-cased, that a tracked instruction file pulls in with an @ import (Claude Code's "@path" syntax)": the import-fragment case

**Location:** `scripts/dev-cycle.sh:413-415` (also the help `:52-53`, `skills/dev-cycle/SKILL.md:74-75` at 2e65ad5, and 6f3d55e's first bullet, "--check-fix refuses a file that a tracked instruction file pulls in with an @ import")
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers an import written with a `#fragment` in a plain tracked instruction file. It does not establish what other harnesses do with such a token, or anything about real files, none of which has one.

The token runs to the next blank, backtick or `)`. Only directories are stripped, never a fragment:

```bash
# scripts/dev-cycle.sh:423-424 (6f3d55e)
    IMPORTED+="$( { env LC_ALL=C grep -oE '(^|[[:space:](])@[^[:space:]`)]+' -- "$f" || true; } \
      | sed 's/.*@//; s#^\./##; s#^~/##; s#.*/##' | tr 'ABC…' 'abc…')"$'\n'
```
(excerpt ends :424; enclosing `imported_names()` continues to `:425` `done < <(git ls-files -z)` — read)

Claude Code 2.1.288 cuts the fragment off before it resolves the path:

```js
// installed bundle, function VWn
let S=/(?:^|\s)@((?:[^\s\\]|\\ )+)/g … let B=w[1]; … let H=B.indexOf("#");if(H!==-1)B=B.substring(0,H);
```

**What P4 shows.**
- A `CLAUDE.md` holding `Read @docs/q.md#intro and @docs/a.md` gives `ok docs/q.md` and `skip docs/a.md: an instruction file imports …`.
- The regex copied from the bundle extracts `"docs/q.md"` from the same line.

So a reader relying on the comment, the help or the skill would take `docs/q.md` to be protected, and it is not.

**Severity.** Low.
- Precondition: someone commits an instruction file with a fragment import.
- No such import exists in either worktree. P2 scanned the 44 and 45 instruction files: one `@` token in total.
- The failure direction is unsafe: an in-cycle fix may edit an instruction-loaded file.

**Evidence:** `scripts/dev-cycle.sh:413-425,439`; installed `@anthropic-ai/claude-code/bin/claude.exe` (2.1.288, function `VWn`); `fc37/tmp.o9puMLbDaW/p4.log` (`timeout 120 bash fc37/p4.sh`, rc 0, 20:46:15Z); `fc37/tmp.o16eG7cC5f/p2.log`

---

## Claim 5b: the same comment: "a tracked instruction file": a tracked instruction file that is a symlink

**Location:** `scripts/dev-cycle.sh:413,421`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the script's side: the imports of a tracked `CLAUDE.md` symlink are not collected. It does not establish, by running it, that Claude Code loads a symlinked `CLAUDE.md`. The bundle has symlink handling for memory files (`N$`), but I did not trace it end to end, hence Medium.

```bash
# scripts/dev-cycle.sh:421 (6f3d55e)
    if [[ ! "$b" =~ $INSTRUCTION_FILE ]] || ! inrepo "$f"; then continue; fi
```
(excerpt is one line of the loop body; enclosing `imported_names()` runs `:417-426` — read)

`inrepo` requires a plain regular file. P3 committed `CLAUDE.md -> notes/real.md` containing `see @docs/l.md`, and `--check-fix docs/l.md` printed `ok docs/l.md`. The precise version is "a tracked instruction file that is a plain regular file (not a symlink)". The `inrepo` gate is deliberate, so the fix is either the qualifier or reading the link's target.

**Evidence:** `scripts/dev-cycle.sh:163-165,417-426`; `fc37/tmp.fY9TNufaEq/p3.log`

---

## Claim 5c: the same comment's other parts: the token forms, case and fences, and "Computed once, on first use"

**Location:** `scripts/dev-cycle.sh:413-425`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers `./`, `~/`, nested directories, upper case, `(@…)`, fenced and inline-code imports, trailing punctuation, `foo@…` and `"@…"`, and the once-only computation. It does not establish imports reached through an imported file (one hop only; Claude Code follows up to 5), or untracked instruction files such as `CLAUDE.local.md`, which the comment's "tracked" excludes.

P3 results, with a `GEMINI.md` holding each form:
- Refused (basename match, lower-cased): `@./docs/a.md`, `@~/docs/b.md`, `(@docs/e.md)`, fenced `@docs/g.md`, `@docs/I.md` (→ `i.md`).
- Not refused, each consistent with Claude Code: `` `@docs/f.md` `` (inline code, which Claude Code also skips), `foo@docs/h.md`, `"@docs/k.md"`, and `@docs/sub/c.md.` / `@docs/d.md,` / `@docs/j.md:`. For the last three, Claude Code keeps the punctuation in the path and so loads nothing (P4: `"docs/d.md,"`).

The over-refusals (`(@`, fenced, `~/`) fail toward filing, as 6f3d55e's Notes say. The once-only computation is `[[ -n "$IMPORTED_DONE" ]] && return; IMPORTED_DONE=1` (`:419`).

**Evidence:** `scripts/dev-cycle.sh:416-425`; `fc37/tmp.fY9TNufaEq/p3.log`; `fc37/tmp.o9puMLbDaW/p4.log`

---

## Claim 6: "Compared lower-cased: on a case-insensitive filesystem docs/Working/ is docs/working/."

**Location:** `scripts/dev-cycle.sh:431`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the exclusion and own-file comparisons. It does not establish the final `check_path`, which still requires the exact tracked spelling (P3: `DOCS/p.md` → "no tracked file … matches").

`lp="$(printf '%s' "$a" | tr 'ABC…' 'abc…')"` (`:432`) feeds `writable "$lp"` and every exclusion except the dot test, which is case-free. Test results:
- bats 50 → `docs/Working/notes.md` and `docs/Dev-Cycle.md` refused.
- P3 → `docs/Roadmap.md` → own file.

**Evidence:** `scripts/dev-cycle.sh:431-442`; `fc37/tmp.DiuLWLTTvX/p1.log`; `fc37/tmp.fY9TNufaEq/p3.log`

---

## Claim 7: skip reason "(not working/, human-author/, reviews/, decisions/, dev-cycle.md, dot-directories or instruction files)"

**Location:** `scripts/dev-cycle.sh:438`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the reason text printed for this branch. It does not establish anything about the other two skip lines, which are accurate.

P3: `docs/.hidden.md` → `skip docs/.hidden.md: in-cycle fixes edit only … (not …, dot-directories or instruction files) …`. The help now says "a dot-directory or dotfile" (`:52`). The printed reason should say "dot-directories or dotfiles" too. Wording only.

**Evidence:** `scripts/dev-cycle.sh:437-438`; `fc37/tmp.fY9TNufaEq/p3.log`

---

## Claim 8: skip reason "an instruction file imports a file named $base with @, so it is read as instructions"

**Location:** `scripts/dev-cycle.sh:440`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the wording against the basename match ("a file named", not "this file"). It does not establish the set's completeness (Claim 5a).

P3 printed `skip docs/a.md: an instruction file imports a file named a.md with @, …` for an import of `./docs/a.md`. That is exactly the basename match at `:439`.

**Evidence:** `scripts/dev-cycle.sh:439-440`; `fc37/tmp.fY9TNufaEq/p3.log`

---

## Claim 9: ANSWER_AWK: "Its text starts after the label: at ':**' when the label alone is bold, else at the first ': ', and then ends at the bold's close if it opened inside the bold … (a word must be followed by the end, punctuation or a dash)"; inline: "is the bold of the label still open at ': '?"

**Location:** `scripts/dev-cycle.sh:462-467,510`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers 12 synthetic label shapes and all 103 real IDs. It does not establish CommonMark-exact bold parity: the inline test looks only at the first `**` before `": "`. No shape I could build gives a different option, because `*` after a word now counts as punctuation.

```awk
# scripts/dev-cycle.sh:506-513 (6f3d55e)
  if ((c = index(rest, ":**")) > 0 && (c < (d = index(rest, ": ")) || !d)) {
    rest = substr(rest, c + 3)
  } else if ((c = index(rest, ": ")) > 0) {
    e = index(rest, "**"); inbold = !(e > 0 && e < c)   # is the bold of the label still open at ": "?
    rest = substr(rest, c + 2)
    if (inbold && (e = index(rest, "**")) > 0) rest = substr(rest, 1, e - 1)
  } else next
  result = option(rest); done = 1
```
(excerpt is the end of the `!done` rule, which begins at `:500` — read)

P3 results:

| Answer line | Read |
|---|---|
| `**Answer (d)**: **[2]**` | drop |
| `**Answer (d):** [2]` | drop |
| `**Answer:** **keep**.` | keep |
| `**Answer: keep** more` | keep |
| `**Answer (d)**: keep it` | unrecognized (as the word rule says) |
| `**Answer (d)**: drop** x` | drop |
| `**Answer (see **x**): keep** y` | keep |
| `**Answer (d)**: keep*` | keep |
| `**Answer: [2]** because` | drop |
| `**Answer (d)**: **drop** because` | drop |
| `**Answer: drop it**` | unrecognized |
| `**Answered (d)**: **done**` | done |

P2: all 103 IDs in B's questions files, and A's 98, give byte-identical `--check-answer` output under 3d580cd and 6f3d55e.

**Evidence:** `scripts/dev-cycle.sh:446-460,462-467,500-520`; `fc37/tmp.fY9TNufaEq/p3.log`; `fc37/tmp.o16eG7cC5f/p2.log` (`timeout 600 bash fc37/p2.sh`, rc 0, 20:43:17–20:43:39Z)

---

## Claim 10: "last committed on this branch: <date>" uses the committer date, as the window does (6f3d55e: "'last committed' dates … use the committer date, as the window does")

**Location:** `scripts/dev-cycle.sh:658,673,757`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers decision-record and roadmap dates for a commit whose author and committer dates differ, under a far-off local TZ. It does not establish section 1's merge list, which still prints `%ad`; that is unchanged and not a "last committed" claim.

All three call sites use `--format=%cd` or `'@%cd'` with `--date=short`, and `--date=short` keeps the committer's own zone, like `%cs`. P3 made one commit with author date 2026-01-05 and committer date `2026-10-01T23:30-1000` (`ad=2026-01-05 cd=2026-10-01 cs=2026-10-01`). Under `TZ=Pacific/Kiritimati` the digest printed `### docs/decisions/001-x.md (last committed on this branch: 2026-10-01)` and `docs/roadmap.md last committed on this branch: 2026-10-01`.

**Evidence:** `scripts/dev-cycle.sh:629,658,673,757`; `fc37/tmp.fY9TNufaEq/p3.log`

---

## Claim 11: bats test names "--check-fix refuses files an instruction file imports, and compares paths ignoring case" and "--check-brief refuses a brief that is a symlink on the default branch; a bold-closed label answer is read"

**Location:** `test/scripts/dev-cycle.bats:966-991`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers what each test asserts against its name. It does not establish coverage of the gaps in Claims 5a and 5b, which no test exercises.

Test 50 asserts the import skips for `docs/conventions.md` and `README.md` and the case skips for `docs/Working/notes.md` and `docs/Dev-Cycle.md`. Test 51 asserts the symlink skip and `drop` for both bold-closed labels. Both pass (`ok 50`, `ok 51`).

**Evidence:** `test/scripts/dev-cycle.bats:966-991`; `fc37/tmp.DiuLWLTTvX/p1.log`

---

## Claim 12: 11714a3: "the code skips them ('one of the cycle's own files (use --check-write)'); the help now says so. Help range moved."

**Location:** commit 11714a3 message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the message against its own diff. It does not establish the later range (Claim 2).

At 11714a3 the help reads `(not the cycle's own files, working/, …` and the range is `sed -n '2,76p'`, up from 75. Line 76 is the last header line at that commit (paraphrased — no quote available because it is a one-number change read from `git show 11714a3:scripts/dev-cycle.sh`, lines 74–78 and 140).

**Evidence:** `git show 11714a3:scripts/dev-cycle.sh` lines 50-53, 74-78, 140

---

## Claim 13: 6f3d55e: "--check-brief refuses a brief that is not a regular file on the default branch (a symlink's blob is its target text)."

**Location:** commit 6f3d55e message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers gitlink and tree entries at a brief path. It does not establish harm: `new` reads no blob, and the help defines `new` as "the default branch has no file there".

The `cat-file -t != blob` branch (`:355`) runs before the mode check. P3 results:
- 160000 gitlink at `docs/working/briefs/2026-01-01-g.md` → `ok … new`.
- Tree at `docs/working/briefs/2026-01-01-t.md` → `ok … new`.

So the refusal covers only blob-backed non-regular entries (symlinks). The precise version is "refuses a brief whose default-branch blob is not a regular file". Wording.

**Evidence:** `scripts/dev-cycle.sh:355-360`; `fc37/tmp.fY9TNufaEq/p3.log`

---

## Claim 14: 6f3d55e: "51/51; shellcheck and the hermeticity lint clean; all 103 real IDs read as before."

**Location:** commit 6f3d55e message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the gates at 6f3d55e. "103" is the count in B's questions files, which the merge brings together; A's own files hold 98, also unchanged. It does not establish anything about later commits.

P1 commands: `timeout 500 bats test/scripts/dev-cycle.bats` (rc 0, 51 `ok`), `bats --count` (51), `timeout 120 python3 scripts/hermeticity-lint --root .` (rc 0, "126 test file(s) checked, no unstubbed network spawns"), `timeout 120 shellcheck scripts/dev-cycle.sh` (rc 0). All ran in a clone at 6f3d55e. The ID result is in P2.

**Evidence:** `fc37/tmp.DiuLWLTTvX/p1.log`, `fc37/tmp.DiuLWLTTvX/bats.out`; `fc37/tmp.o16eG7cC5f/p2.log`

---

## Claim 15: 6f3d55e's other bullets and Notes (lower-cased exclusions; the label cut and `*`; help names dotfiles and imported files; "the import rule matches basenames, so it can over-refuse a same-named file elsewhere; that fails toward filing the fix")

**Location:** commit 6f3d55e message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers these bullets as executed in Claims 1, 6, 9 and 5c. It does not cover the import and brief bullets (Claims 5a, 5b, 13).

Each bullet holds in P3 (see the cited claims). Over-refusal by basename is visible in bats 50, where `@README.md` refuses the top-level `README.md` regardless of path.

**Evidence:** `fc37/tmp.fY9TNufaEq/p3.log`; `test/scripts/dev-cycle.bats:966-978`

---

## Claim 16: SKILL: in-cycle fix scope "(not the cycle's own files, `docs/working/`, …, a dot-directory or dotfile, an instruction file, or a file an instruction file imports with `@`; compared ignoring case) or `README.md`"

**Location:** `skills/dev-cycle/SKILL.md:71-77` (2e65ad5)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers agreement with `--check-fix` at merge 79f50aa, whose script is byte-identical to 6f3d55e. It does not establish import completeness (Claim 5a applies to this sentence too).

The list matches the help (`:50-55`) clause for clause. P3 exercises each clause (Claim 1).

**Evidence:** `skills/dev-cycle/SKILL.md:71-77`; `scripts/dev-cycle.sh:50-55,425-442`

---

## Claim 17: SKILL: "Every mode takes many arguments: batch a step's values into one call per mode."

**Location:** `skills/dev-cycle/SKILL.md:101-102`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the argument loop for all six modes. It does not establish ARG_MAX limits, which are not a concern at cycle sizes.

```bash
# scripts/dev-cycle.sh:572-583 (6f3d55e)
if [[ -n "$CHECK" ]]; then
  for a in "${CHECK_ARGS[@]}"; do
    case "$CHECK" in
      --check-path) check_path "$a" ;;
      …
      --check-answer) check_answer "$a" ;;
    esac
  done
  exit 0
fi
```

P2 ran `--check-fix` with 684 arguments and `--check-answer` with 103, each in one call.

**Evidence:** `scripts/dev-cycle.sh:572-583`; `fc37/tmp.o16eG7cC5f/p2.log`

---

## Claim 18: SKILL: "Only a name that `--check-branch` prints `ok` for goes into that entry's paste block (git allows names such as `a$(id)`, which a paste would run)"

**Location:** `skills/dev-cycle/SKILL.md:171-175`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers git's acceptance of the name and the `--check-branch` filter. An `ok` name holds only letters, digits, `.`, `_`, `-` and `/`, and does not start with `-`. It does not establish how an agent quotes names in the paste.

P3 results:
- `git check-ref-format --branch` allows `a$(id)`, `` a`id` `` and `a;b`.
- `git branch 'a$(id)'` succeeds.
- `--check-branch 'a$(id)' feat/x main` prints `skip a$(id): not an allowed branch name`, `ok feat/x …`, and `skip main: the default branch`.

The filter is the `NAMECHARS` test at `:394`.

**Evidence:** `scripts/dev-cycle.sh:394-404`; `fc37/tmp.fY9TNufaEq/p3.log`

---

## Claim 19: SKILL: "`Asked:` line (check 3 below writes them …)" and "the next keep-or-drop entry, which check 3 files"

**Location:** `skills/dev-cycle/SKILL.md:290,299`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers the cross-references inside In flight. It does not establish anything about other step references.

In flight's item 3 (`:304-311`) files the `keep-or-drop-…` entry "and add its ID to `Asked:`". "Step 3" is `### 3. Watched questions` (`:194`), and the skill calls the In flight items "check 1" at `:91` and `:274`.

**Evidence:** `skills/dev-cycle/SKILL.md:91,194,274,290,299,304-311`

---

## Claim 20: b684ff2: "'step 3' is also the Watched questions step; the In flight sub-items are called checks elsewhere in the skill."

**Location:** commit b684ff2 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the message against the skill. It does not cover anything beyond that.

Same evidence as Claim 19. The diff changes exactly the two occurrences.

**Evidence:** `skills/dev-cycle/SKILL.md:91,194,274,290,299`

---

## Claim 21: 91b88d7: "a cycle made about 18 single-item check calls where about 7 batched calls carry the same inputs; every mode already takes many arguments."

**Location:** commit 91b88d7 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the citation of the performance review and the "every mode" clause. It does not re-derive the review's 18/7 estimate, which is its own worked example.

The full-review performance report says "about 18 calls per cycle where about 7 would do" (`docs/reviews/performance-review-2026-10-02-devcycle-fullreview.md:67`, worked out at `:78`). The "every mode" clause is Claim 17.

**Evidence:** `docs/reviews/performance-review-2026-10-02-devcycle-fullreview.md:67,78,141` (wt-devcycle)

---

## Claim 22: 2e65ad5: "Step 1's merged-branch list goes into the you: terminal paste block only for names --check-branch prints ok for … The in-cycle fix scope names dotfiles and files an instruction file imports with @, compared ignoring case, as --check-fix now does."

**Location:** commit 2e65ad5 message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the message against its diff and against `--check-fix` as merged in 79f50aa ("now does" is true once merged; 2e65ad5's own tree still has the older script). It does not cover import completeness (Claim 5a).

The diff makes exactly these two changes (Claims 16 and 18).

**Evidence:** `git diff 91b88d7..2e65ad5 -- skills/dev-cycle/SKILL.md`; `fc37/tmp.fY9TNufaEq/p3.log`

---

## Claim 23: merge 79f50aa brings the digest fix round into `feat/dev-cycle` without changing the skill

**Location:** merge commit 79f50aa (parents 2839cc4, fa2b9b3)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the script, the bats file and the skill. It does not cover the review docs carried in fa2b9b3/2839cc4, whose stale message the brief says is already recorded.

`git show <rev>:scripts/dev-cycle.sh | md5sum` gives `0fead6b1…` for both 79f50aa and 6f3d55e. The bats file gives `d4424cf4…` for both. `git diff --stat 2e65ad5 79f50aa -- skills/` is empty.

**Evidence:** `git show 79f50aa:scripts/dev-cycle.sh`, `git show 6f3d55e:scripts/dev-cycle.sh`, `git diff 2e65ad5 79f50aa -- skills/`

---

## Claims Requiring Attention

### Incorrect
- **Claim 5a** (`scripts/dev-cycle.sh:413-425`; help `:52-53`; `SKILL.md:74-75`; 6f3d55e): an `@path#fragment` import is stored as `name.md#fragment`, so the file Claude Code loads is not refused. Strip `#…` before the basename. Behavioral, Low.

### Stale
- **Claim 4** (`scripts/dev-cycle.sh:404-408`): the design comment omits dotfiles, imported files and the case folding. Wording.

### Mostly Accurate
- **Claim 5b** (`scripts/dev-cycle.sh:413,421`): a symlinked tracked instruction file's imports are not scanned. Fix with a "plain" qualifier, or by reading the target. Behavioral, low impact.
- **Claim 7** (`scripts/dev-cycle.sh:438`): the skip reason should say "dot-directories or dotfiles". Wording.
- **Claim 13** (6f3d55e message): a gitlink or tree at a brief path prints `ok … new`, not a refusal. Wording.

### Unverifiable
- None.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

**Where and how it is saved.** This report is at `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass37.md`. Its first line is `Commit: 6f3d55e (A) / 2e65ad5 (B)`, and its header carries `**Replication:** k=1 (loop pass, decision 031)`. It follows `skills/code-fact-check/SKILL.md`:
- header fields;
- per-claim Location, Type, Verdict, Confidence, Verification mode (with command, cwd, rc, timestamp and log path for executed claims), Scope and Evidence, plus the brief's Legibility-target;
- the quote-or-tagged-paraphrase rule with truncation markers;
- Claims Requiring Attention.

**For the user goal** (a delta pass with no known issue, then the k=1 full review), this pass leaves one known issue open:
- Claim 5a, a Low behavioral gap in the new import refusal. It is outside decision log 69's accepted limit, which concerns the fence reader, not imports.
- Its neighbours, both in the unsafe direction: the one-hop limit and the symlinked-instruction-file case (Claim 5b).
- Three wording items: Claims 4, 7 and 13.

The concurrent uncommitted edit in wt-digest addresses several of these but not the fragment case. Nothing was committed.
