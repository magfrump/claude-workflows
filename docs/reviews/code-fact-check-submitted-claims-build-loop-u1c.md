Commit: c143b929

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u1c (claude-workflows, branch feat/build-loop-u1c)
**Scope:** Submitted claims 45-47 from security-reviewer (Stage 2.5, U1c final confirming pass); scripts/build-loop.sh at c143b929. No harvested claims in this report.
**Checked:** 2026-10-05
**Total claims checked:** 5 (claim 45 split into 45a, 45b, 45c on verdict divergence)
**Summary:** 3 verified, 1 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Hallucination pattern log read (`docs/reviews/hallucination-patterns.md`, 5 entries): no submitted claim matches a logged pattern.

All probes ran in throwaway repos under `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i2/submitted/` with git 2.39.5, `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`, TMPDIR unset, every script run under `timeout`. Crafted tips were written with `git hash-object -t commit --literally -w --stdin` and set with `git update-ref`; each was read with `bash /workspace/.claude/wt-build-loop-u1c/scripts/build-loop.sh --status docs/working/briefs/2026-10-01-a.md`.

---

## Submitted Claims

## Claim 45a: "For the crafted tip objects tested, marker_kind reads parents, tree ... as git does: duplicate-parent, two-tree, orphan, merge, non-empty, NUL ... `handoff:` tips are skips"

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:273-293`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the six structural cases (two parent lines with the same SHA, two tree lines, no parent line, two distinct parents, a tree differing from the parent's, a NUL byte in the subject or in the body) on a branch one commit ahead of main, each with a `handoff: ready` subject; does not establish behavior under grafts or a shallow repo (rev-list honours both), under a repo-local `i18n.logOutputEncoding`, or for tips whose subject does not start `handoff:` (those return `working` before any structural check).

Read the whole of `marker_kind` (:273-293) and its one caller's use (:337-344). Parents come from git, not from parsing the object:

```bash
# scripts/build-loop.sh:276-282
  read -ra p <<<"$(git rev-list --parents -n 1 "$1")"
  msg="$(git log -1 --format=%B "$1")"; subj="${msg%%$'\n'*}"
  [[ "$subj" == handoff:* ]] || { echo working; return; }
  if [[ "$(git cat-file commit "$1" | tr -cd '\000' | wc -c)" -gt 0 ]]; then echo "bad it holds a NUL byte"; return; fi
  if [[ ${#p[@]} -eq 1 ]]; then echo "bad it has no parent"; return; fi
  if [[ ${#p[@]} -gt 2 ]]; then echo "bad it has $(( ${#p[@]} - 1 )) parents"; return; fi
  if [[ "$(git rev-parse --verify "$1^{tree}")" != "$(git rev-parse --verify "${p[1]}^{tree}")" ]]; then echo "bad it changes files"; return; fi
```
(excerpt ends :282; enclosing marker_kind() continues to :293 — read)

Executed results (from `probe45.log`): duplicate parent: `git rev-list --parents` printed the parent twice and `--status` gave `skip B: ... it has 2 parents`; two-tree: rev-list printed no parent (git stops at the second tree line), `skip ... it has no parent`; orphan: `skip ... it has no parent`; merge: `skip ... it has 2 parents`; non-empty (main's tree on base): `skip ... it changes files`; NUL in body and NUL inside the subject: both `skip ... it holds a NUL byte`. In every case the parent count the script reports equals what `git rev-list --parents` printed for the same object.

**Evidence:** `scripts/build-loop.sh:273-293`, `scripts/build-loop.sh:337-344`; command `timeout 300 bash probe45.sh > probe45.log 2>&1`, cwd `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i2/submitted`, exit 0, 2026-10-05T17:10:47Z; output `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i2/submitted/probe45.log`; script `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i2/submitted/probe45.sh`

---

## Claim 45b: "... UTF-7 and Latin-1 encoded `handoff:` tips are skips"

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:277`, `scripts/build-loop.sh:285-292`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers objects with an `encoding UTF-7`, `encoding ISO-8859-1` or unknown `encoding` header under git 2.39.5 with no i18n config; does not establish behavior with a repo-local `i18n.logOutputEncoding`, other git versions (whether UTF-7 is decoded), or encodings that put NUL bytes in the raw object.

The subject is the first line of `git log -1 --format=%B` (:277), so it is git's re-encoded message, and an encoding header alone does not make a tip a skip. Only a tip whose re-encoded subject is not exactly a marker subject is a skip. Precise version: "an encoded `handoff:` tip is a skip when the subject git prints (after re-encoding) is not exactly `handoff: ready`, `handoff: blocked` or `handoff: stopped: <1-120 printable ASCII>`; an encoding header over an ASCII subject reads as that marker."

Executed results (`probe45.log`):
- Skips: Latin-1 `handoff: stopped: caf\351` (git printed `caf\303\251`, UTF-8 é); Latin-1 `handoff:\240ready` (git printed `\302\240`, a no-break space); UTF-7 header with raw `handoff:+ACA-ready` (git printed it raw, not as a space).
- Not skips: UTF-7 header + `handoff: ready` → `ok ... ready`; ISO-8859-1 header + `handoff: ready` → `ok ... ready`; `encoding NOSUCH` + `handoff: ready` → `ok ... ready`; UTF-7 header + `handoff: stopped: a+AOk-b` → `ok ... stopped ... a+AOk-b`. The system iconv does decode `a+AOk-b` to `aéb` (`probe45b.log`), but git 2.39.5 printed the raw bytes, and the script took git's reading.

So for every case the script agrees with what git prints (the "as git does" part holds); the conclusion "encoded tips are skips" holds only for the non-exact ones.

**Evidence:** `scripts/build-loop.sh:277`, `scripts/build-loop.sh:285-292`; command `timeout 300 bash probe45.sh > probe45.log 2>&1`, cwd `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i2/submitted`, exit 0, 2026-10-05T17:10:47Z; outputs `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i2/submitted/probe45.log`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i2/submitted/probe45b.log`

---

## Claim 45c: "marker_kind reads ... subject as git does: ... a leading-blank message reads `working`"

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:277-278`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers raw messages that start with one or more blank or whitespace-only lines before `handoff: ready`; establishes that the outcome is `working` (true, fail-safe) but that git's own subject for these objects is `handoff: ready`, so "reads the subject as git does" is refuted for this case; does not establish how the orchestrator or `--marker` treat such tips.

The outcome part is true: `--status` printed `ok B open review feat/a working <sha> 1970-01-01 0` for raw messages `\nhandoff: ready`, `\n\nhandoff: ready` and ` \nhandoff: ready`. The mechanism part is not. The script takes the first line of the raw body:

```bash
# scripts/build-loop.sh:277-278
  msg="$(git log -1 --format=%B "$1")"; subj="${msg%%$'\n'*}"
  [[ "$subj" == handoff:* ]] || { echo working; return; }
```
(excerpt ends :278; enclosing marker_kind() continues to :293 — read)

`%B` keeps the leading blank line (`od -c` of `%B`: `\n h a n d o f f : r e a d y \n`), so `subj` is empty and the tip reads `working`. But git's own subject skips leading blank and whitespace-only lines: `git log --format=%s` and `git log --oneline` both print `handoff: ready` for the same objects (`probe45.log`, `probe45b.log`: `oneline: 56d8dd4 handoff: ready`). The script's reading matches its own help text ("the tip's subject (its message's first line)", :67-68). It does not match git's subject. The error is fail-safe: the tip is never taken as a marker, so nothing is dispatched or merged on it. The cost is that a tip `git log --oneline` shows as `handoff: ready` is reported as `working`, not as a `skip` for a spoofed marker, so the help text's skip rule for "starts handoff: but is not a marker" (:67-69) does not fire for it. The fix belongs in the claim's wording: "a message whose first raw line is blank reads `working` even though git's `%s` shows `handoff: ...`".

**Evidence:** `scripts/build-loop.sh:277-278`, `scripts/build-loop.sh:62-69`; command `timeout 300 bash probe45.sh > probe45.log 2>&1`, cwd `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i2/submitted`, exit 0, 2026-10-05T17:10:47Z, plus the `%B`/`--oneline` check saved to `probe45b.log` (exit 0, 2026-10-05T17:11Z); outputs `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i2/submitted/probe45.log`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i2/submitted/probe45b.log`

---

## Claim 46: "An open brief stored under docs/working/briefs/closed/ that names the same branch (case-folded) as an open brief in briefs/ makes the latter skip, and status_line builds the shared set itself on first use."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:298-309`, `scripts/build-loop.sh:326-329`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers brief-form files directly in `docs/working/briefs/closed/` on main's commit with `Status: open` and a `Branch:` name differing only in ASCII case; does not establish counting of closed/ files in subdirectories or with non-brief names (both are ignored), non-ASCII case folding (`lower` maps A-Z only), or that the set is used before a brief passes check_brief, the new-state return and the Branch:/Dispatched: checks (:312-324), which run first.

The set is built from main's tree, and the closed/ prefix is stripped before the name check:

```bash
# scripts/build-loop.sh:301-305
  list="$(git ls-tree --full-tree --name-only "$MAIN_SHA" -- docs/working/briefs/ docs/working/briefs/closed/)"
  while IFS= read -r f; do
    if ! isbrief "${f/closed\//}" || ! brief_fields "$f"; then continue; fi
    [[ "${BRIEF[status]-}" == "Status: open" && "${BRIEF[branch]-}" =~ ^Branch:\ ([^\ ]+)$ ]] || continue
    b="$(lower "${BASH_REMATCH[1]}")"; n[$b]=$(( ${n[$b]-0} + 1 ))
```
(excerpt ends :305; enclosing shared_branches() continues to :309 — read)

`status_line` fills it on first use, and the status mode never calls `shared_branches` itself:

```bash
# scripts/build-loop.sh:326-329
  [[ -n "$SHARED_BRANCHES" ]] || shared_branches
  if [[ "$st" == open && "$SHARED_BRANCHES" == *$'\n'"$(lower "$br")"$'\n'* ]]; then
    echo "skip $a: another open brief on the default branch names the same branch (compared ignoring case)"; return
  fi
```

`shared_branches` always sets the variable to at least `$'\n'` (:307), so it runs once per process. The `brief_fields` calls inside it overwrite the global `BRIEF` and `BASH_REMATCH`. `status_line` has already copied `br` (:319), `disp` (:323) and `pol` (:325) before :326 and reads neither global afterwards, so the overwrite has no effect.

Executed results (`probe46.log`): baseline `ok ... feat/d absent`. With `closed/2026-10-01-old.md` = `Status: open` / `Branch: FEAT/D` on main, `--status d e closed-old` printed `skip d: another open brief ...`, then `ok e ...`, then `skip closed-old: ...`, so the shared set was built inside status_line within one run. With the closed/ brief `Status: done`: `ok`. With it on main but deleted from the working tree: still `skip` (main's commit is read). Renamed to `2026-10-01-Old.md` (not brief form): `ok`. Moved to `closed/sub/`: `ok`.

**Evidence:** `scripts/build-loop.sh:297-309`, `scripts/build-loop.sh:310-346`, `scripts/build-loop.sh:348-352`, `scripts/lib/dev-cycle-read.sh:157`, `scripts/lib/dev-cycle-read.sh:430`; command `timeout 200 bash probe46.sh > probe46.log 2>&1`, cwd `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i2/submitted`, exit 0, 2026-10-05T17:11:48Z; output `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i2/submitted/probe46.log`; script `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i2/submitted/probe46.sh`

---

## Claim 47: "The STOPPED reason printed on a --status line is limited to 1-120 printable ASCII bytes with no blank at either end, checked in the C locale."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:289-292`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reason as `git log %B` prints it (after git's re-encoding) and as it reaches the scrubbed `--status` output, under caller locales C and C.UTF-8; does not establish how consumers split a reason containing inner spaces, or the reason's relation to the raw object bytes when a repo-local `i18n.logOutputEncoding` is set.

```bash
# scripts/build-loop.sh:289-292
  r="${subj#handoff: stopped: }"
  # grep in the C locale: the ranges are ASCII bytes, and no locale is switched here.
  if [[ "$subj" == "handoff: stopped: "* ]] && printf '%s\n' "$r" | LC_ALL=C grep -qxE '[!-~]([ -~]{0,118}[!-~])?'; then echo "stopped $r"
  else echo 'bad its subject is not exactly "handoff: ready", "handoff: blocked" or "handoff: stopped: REASON" (REASON: 1 to 120 printable ASCII characters, no blank at either end)'; fi
```
(:293 closes marker_kind — read)

`r` holds no newline (`subj` is cut at the first one, :277), so the whole-line `-x` match covers all of it. `LC_ALL=C` makes `[!-~]` bytes 0x21-0x7E and `[ -~]` bytes 0x20-0x7E. The caller prints `reason=" ${kind#stopped }"` (:341) as the last field (:345).

Executed results (`probe47.log`, both caller locales identical): accepted, with the printed reason measured: `x` (1), `!` (1), `~` (1), `a b` (3), 119 r's (119), 120 r's (120). Skipped: 121 bytes; 119 r's plus a trailing space; leading space; trailing space; a lone space; inner tab; trailing tab; trailing CR; DEL; ESC; UTF-8 é; a Latin-1 byte 0xE9; UTF-8 no-break space; fullwidth `a`.

**Evidence:** `scripts/build-loop.sh:277`, `scripts/build-loop.sh:289-293`, `scripts/build-loop.sh:338-345`; command `LC_ALL=C timeout 400 bash probe47.sh > probe47.log 2>&1` (the script runs the CLI under LC_ALL=C and LC_ALL=C.UTF-8 per case), cwd `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i2/submitted`, exit 0, 2026-10-05T17:12:17Z; output `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i2/submitted/probe47.log`; script `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i2/submitted/probe47.sh`

---

## Claims Requiring Attention

### Incorrect
- **Claim 45c** (`scripts/build-loop.sh:277-278`): marker_kind does not read the subject as git does when the raw message starts with a blank or whitespace-only line. git's `%s`/`--oneline` show `handoff: ready`, but the script reads the empty first line of `%B` and reports `working`. The result is fail-safe, but such a tip is never reported as a spoofed-marker skip.

### Mostly Accurate
- **Claim 45b** (`scripts/build-loop.sh:277`, `:285-292`): encoded tips are skips only when git's re-encoded subject is not exact. A UTF-7, Latin-1 or unknown encoding header over an ASCII `handoff: ready` subject reads `ready`, and UTF-7 `handoff: stopped: a+AOk-b` reads `stopped`.
