**Commit:** 1d79ffef

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u1b (branch feat/build-loop-u1b)
**Scope:** `feat/build-loop-u1a...feat/build-loop-u1b` at 1d79ffef: scripts/build-loop.sh, test/lib/build-loop-fixtures.bash, test/scripts/build-loop-read.bats, and the message of 1d79ffef (earlier commits' messages were verdicted at 0ae7d801 in docs/reviews/code-fact-check-report-build-loop-u1b.md; HEAD did not re-touch the code they describe in a way that changes those verdicts, and A9/A10 are settled Won't-Fix)
**Checked:** 2026-10-05
**Total claims checked:** 39
**Summary:** 34 verified, 4 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Execution provenance common to all `executed` claims: logs live in the scratch dir
`/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i3/fc-r2/logs/` (abbreviated `FC/logs/` below; `FC` = that
scratch dir). Each log starts with its UTC timestamp and ends with `exit N`. Probes were run through
`FC/probe.sh NAME LINE...`, which builds a fresh repo under `FC/repos/NAME` (main branch, docs/dev-cycle.md =
the lines via `printf '%s\n'`, one commit, hermetic git env, `LC_ALL=C`) and runs
`bash /workspace/.claude/wt-build-loop-u1b/scripts/build-loop.sh --settings`. Mutants are copies of
`scripts/` and `test/` under `FC/m-*/`, run with `cd FC/m-X && bats test/scripts/build-loop-read.bats`
(`LC_ALL=C.UTF-8`). Baseline: `cd /workspace/.claude/wt-build-loop-u1b && export LC_ALL=C.UTF-8 && bats test/scripts/build-loop-read.bats` → 9/9 ok, exit 0, 2026-10-05T11:42:53Z, `FC/logs/baseline.log`.
The hallucination-pattern log was read; no claim below matches a logged pattern (all logged entries are
measured-value fabrications; the one measured value here, "400 changed code lines", reproduces).

---

## Claim 1: "Each comes from one line of docs/dev-cycle.md; a second copy, or a file the lib's FENCE_AWK refuses, leaves the default (WHY says which)"

**Location:** `scripts/build-loop.sh:10-12`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what a second copy / refused file does to each of the three printed lines; does not establish behaviour for a hidden (non-ASCII) copy (Claim 5).
**Legibility-target:** for-author

For policy and slots it holds: `POLICY_LINE="policy review unset: $(many 'Build-loop policy:' policy)"` (`scripts/build-loop.sh:167`), `SLOTS_LINE="slots 3 default: $(many ...)"` (`:175`). For the never line it does not "leave the default" (`never none`): a second copy prints `never malformed` and clears `never_ok`, which turns self-merge off — `elif [[ "${cnt[never]}" -gt 1 ]]; then NEVER_LINE="never malformed: $(many 'Self-merge never:' never)"; never_ok=""` (`scripts/build-loop.sh:146`); a refused file likewise prints `never malformed` (`:136`). Executed: probe n9 (`Self-merge never: a/` then `Self-merge never: b/`) printed `never malformed: more than one line starts "Self-merge never:" (lines 2 and 3)` and `policy review unset: line 1 reads self-merge, but the Self-merge never: line is malformed`. Only the NEVER array stays at its default (empty). Precise version: "...leaves policy and slots at their defaults and makes the never line malformed (WHY says which)". The never paragraph (`:23-24`) mentions "a file not read" but not a second copy.

**Evidence:** `scripts/build-loop.sh:10-12`, `scripts/build-loop.sh:136`, `scripts/build-loop.sh:146`, `scripts/build-loop.sh:167`, `scripts/build-loop.sh:175`, `test/scripts/build-loop-read.bats:120-121`, `FC/logs/probe-next.log` (n9 run interactively; same shape asserted by bats :121 in `FC/logs/baseline.log`)

---

## Claim 2: "Set only by "Build-loop policy: self-merge" or "...: review", exactly (one trailing CR dropped); else review."

**Location:** `scripts/build-loop.sh:14-15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exact-match regex, the one-CR strip and the review fallback for variants (case, trailing/double space, suffix, copies); does not establish behaviour of a self-merge line alongside a malformed never line (covered by Claim 4/16).

`{ sub(/\r$/, "") }` (`scripts/build-loop.sh:98`) drops one CR; a second CR is left in the line and FENCE_AWK's `if (index(l, "\r")) { refuse("cr"); return 1 }` (`scripts/lib/dev-cycle-read.sh:215`) refuses the file, so review. `elif [[ "${text[policy]}" =~ ^Build-loop\ policy:\ (self-merge|review)$ ]]` (`scripts/build-loop.sh:168`) is the only path to `POLICY="$v"` (`:172`). T1 and T2 pass at baseline; a mutant accepting one trailing space (`(self-merge|review)\ ?$`, `FC/m-loop`) fails T2 at bats line 29 (`FC/logs/mut-loop.log`, 2026-10-05T11:47:18Z, exit 1).

**Evidence:** `scripts/build-loop.sh:98`, `scripts/build-loop.sh:166-173`, `scripts/lib/dev-cycle-read.sh:215`, `test/scripts/build-loop-read.bats:13-41`, `FC/logs/baseline.log`, `FC/logs/mut-loop.log`

---

## Claim 3: "Loops at once: "Build-loop slots: N", N from 1 to 9; else 3."

**Location:** `scripts/build-loop.sh:16-17`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 1-9 regex, default 3 for absent/variant/duplicate/fenced lines; does not establish what any later mode does with the number.

`elif [[ "${text[slots]}" =~ ^Build-loop\ slots:\ ([123456789])$ ]]; then SLOTS_LINE="slots ${BASH_REMATCH[1]} set: ..."` and every other arm prints `slots 3 default` (`scripts/build-loop.sh:174-177`). Test 6 (0, 10, trailing space, 05, three, duplicate, fenced) passes at baseline.

**Evidence:** `scripts/build-loop.sh:174-177`, `test/scripts/build-loop-read.bats:90-101`, `FC/logs/baseline.log`

---

## Claim 4: never grammar — "single spaces ... A glob uses letters, digits, . _ - / * ? (a trailing / ignored when comparing), has no empty, . or .. part, does not start with / or -, and is listed once. Malformed (or a file not read) turns self-merge off."

**Location:** `scripts/build-loop.sh:19-24`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the character set, part rules, duplicate detection (including bash-special subscripts `*`, `?`, `a*`, `*/`), trailing-slash comparison and the self-merge consequence; the "then a blank line or the end" clause is verdicted separately in Claim 6.

`[[ "$1" =~ ^[*?$NAMECHARS]+$ && "$1" != /* && "$1" != -* ]]` plus the part loop `[[ -n "$c" && "$c" != "." && "$c" != ".." ]]` (`scripts/build-loop.sh:116-119`); duplicates `if [[ -n "${seen[${g%/}]-}" ]]; then why="lists entry $i twice"` (`:159`). Because the subscript is an expansion, `*` and `?` are ordinary keys of the associative array, not "all elements": probes `a/ *` and `* a/` print `set`, while `* *`, `? ?`, `a* a*`, `*/ *` and `a a/` print `lists entry 2 twice`; `a a//` and `a// b` are refused as forms (empty part); `@ x`, `a\vb` and `a<NBSP>b` are refused forms (`FC/logs/probe-never.log`). Malformed → `never_ok=""` → `policy review unset: ... so self-merge is off` (`:170-171`), asserted per variant at bats :115.

**Evidence:** `scripts/build-loop.sh:114-121`, `scripts/build-loop.sh:148-164`, `scripts/build-loop.sh:170-171`, `test/scripts/build-loop-read.bats:110-119`, `FC/logs/probe-never.log`, `FC/logs/baseline.log`

---

## Claim 5: "A line counts as a copy when its letters alone, case folded, start with the key's ("buildlooppolicy"), so markup, a table or a misplaced colon cannot hide one." / "(so markup, blanks, a BOM or a misplaced colon cannot hide a copy)"

**Location:** `scripts/build-loop.sh:25-27`, `scripts/build-loop.sh:90-92`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers ASCII markup, tables, links, task items, ordered lists, nested quotes, NBSP between words, a mid-file BOM, and a misplaced colon; does not establish that a copy whose key letters are non-ASCII (e.g. `pólicy`, a Cyrillic homoglyph) is counted — it is not — nor that fenced lines count (they are skipped by design), and it notes a one-line `<!-- -->` comment does count (over-count, fail-closed).

`s = tolower($0); gsub(/[^a-z]/, "", s)` then `index(s, "buildlooppolicy") == 1` (`scripts/build-loop.sh:101-102`), run under `env LC_ALL=C awk` (`:82`), so only ASCII a-z survive. Probes (`FC/logs/probe-copies.log`): `| Build-loop policy | review |`, `- [ ] Build-loop policy: review`, `1. Build-loop policy: review`, `> > Build-loop policy: review`, `Build<NBSP>loop policy: review`, a BOM-prefixed line 2, `[Build-loop policy](x): review`, `<!-- Build-loop policy: review -->` all print `more than one line starts "Build-loop policy:" (lines 1 and 2)`; `Self-merge never : b/` alone is counted (`never malformed: line 2 is not exactly ...`). Residue: `Build-loop p\xc3\xb3licy: review` (a7) and a fenced copy (a10) leave `policy self-merge set`. The non-ASCII case drops bytes inside the key (`buildloopplicy`), so it is hidden; that is the same class as settled C19 (only an exact line sets anything). Also the rule counts a prose line `Build-loop policy is set above` (a12) as a copy, as the commit Notes acknowledge.

**Evidence:** `scripts/build-loop.sh:82`, `scripts/build-loop.sh:96-111`, `test/scripts/build-loop-read.bats:33-37`, `test/scripts/build-loop-read.bats:122-127`, `FC/logs/probe-copies.log`

---

## Claim 6: "single spaces, then a blank line or the end" / "whether the line after the first is blank (NEXT 1) or not"

**Location:** `scripts/build-loop.sh:20`, `scripts/build-loop.sh:92-93`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which line SETTINGS_AWK inspects after the first key line and how EOF/whitespace/CRLF count; does not establish a fail-open (none found).

The checked line is not the physical next line but the next line FENCE_AWK passes as text: `fence($0) { next }` runs before `if (pk != "") { nx[pk] = ($0 ~ /^[ \t]*$/); pk = "" }` (`scripts/build-loop.sh:99-100`), and `nx[k] = 1` is preset on the first copy (`:105`), so EOF reads as blank. Executed: `Self-merge never: a/` followed by a ```` ``` ```` fence holding `b/` (n1) is accepted as `never a/ set` — a fence line also ends it; whitespace-only and tab-only next lines (n4, n5) count as blank; a CRLF file with a blank CRLF line is accepted and with `b/\r` is malformed (interactive run in `FC/repos/crlf`). The outcome matches CommonMark (a fence interrupts a paragraph), so this is imprecise wording, not a defect. Precise version: "the next line outside a fence is blank, or there is none".

**Evidence:** `scripts/build-loop.sh:20`, `scripts/build-loop.sh:92-93`, `scripts/build-loop.sh:98-105`, `scripts/build-loop.sh:152`, `FC/logs/probe-next.log`

---

## Claim 7: "is followed by a non-blank line (Markdown would join it as more globs)" (WHY text; same parenthetical in 1d79ffef's message: "Markdown would join the next line as more globs")

**Location:** `scripts/build-loop.sh:152`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reason printed for every non-blank next line; does not establish any fail-open (all cases fail closed).

`elif [[ "${next[never]}" != 1 ]]; then why="is followed by a non-blank line (Markdown would join it as more globs)"` (`scripts/build-loop.sh:152`) fires for any non-blank next text line. Executed (`FC/logs/probe-next.log`): `b/` (n10) — joined in Markdown, as stated; but `# Heading` (n7), `- item` (n8) and `<!-- c -->` (n2) also give this reason, and CommonMark does not join those (an ATX heading, a bullet list item and an HTML comment block each interrupt a paragraph). The rule is fail-closed over-refusal; only the stated mechanism is too broad. Precise version: "(Markdown may join it as more globs)".

**Evidence:** `scripts/build-loop.sh:152`, `test/scripts/build-loop-read.bats:131-133`, `FC/logs/probe-next.log`

---

## Claim 8: "Acts on $PWD's git repo, like dev-cycle.sh, and needs its default branch found by name (origin/HEAD, main or master). Read-only: writes nothing."

**Location:** `scripts/build-loop.sh:29-30`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the repo choice, the by-name requirement and that a run changes nothing under .git or docs/ in a probe repo; does not establish read-only behaviour of git's own hooks/config (none are invoked).

`ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" ... cd "$ROOT"` and `main_by_name || { echo "build-loop.sh needs a default branch found by name ..." >&2; exit 1; }` (`scripts/build-loop.sh:58-65`). Executed: `ls -laR --time-style=full-iso .git` and `docs/` listings before and after one `--settings` run in `FC/repos/vt` were byte-identical (`READONLY-SAME`, 2026-10-05). Test 8 covers the renamed-branch exit 1.

**Evidence:** `scripts/build-loop.sh:58-65`, `test/scripts/build-loop-read.bats:153-155`, `FC/repos/ro-before.txt`, `FC/repos/ro-after.txt`

---

## Claim 9: "Output passes through the lib's scrub (but for the start-up errors about perl and the lib); printed repo text is data."

**Location:** `scripts/build-loop.sh:31-32`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the ordering of the two pre-scrub errors and the scrub_reexec call; does not establish the scrub's own coverage (lib, U1a).

`command -v perl >/dev/null || { echo "build-loop.sh needs perl ..." >&2; exit 1; }` (`:38`), `[[ -f "$READ_LIB" ]] || { echo "build-loop.sh needs $READ_LIB" >&2; exit 1; }` (`:44`), then `source "$READ_LIB"` and `scrub_reexec "${BASH_SOURCE[0]}" "$@"` (`:46-47`); every later print is in the child whose stdout and stderr pass through `scrub` (`scripts/lib/dev-cycle-read.sh:79`).

**Evidence:** `scripts/build-loop.sh:38-47`, `scripts/lib/dev-cycle-read.sh:76-81`

---

## Claim 10: "Exit: 0 every line printed (or help); 1 bad usage, not a git repo, no perl or lib/dev-cycle-read.sh, or no default branch found by name."

**Location:** `scripts/build-loop.sh:33-34`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed exit path and that read failures inside read_settings still exit 0 with three lines; does not establish exit codes when perl itself crashes mid-scrub.

`-h|--help) sed -n '2,34p' "$0" | sed 's/^# \{0,1\}//'; exit 0` (`:53`); usage errors via `usage() { ...; exit 1; }` (`:49`). Executed: `bash scripts/build-loop.sh -h` exit 0, last line is header line 34 (`FC/logs/help.log`); test 8 asserts the usage, no-default-branch and not-a-repo exits; a repo whose main blob is missing prints three lines plus git's `fatal:` on stderr and exits 0 (`FC/logs/probe-git.log`, `== miss`).

**Evidence:** `scripts/build-loop.sh:49-56`, `test/scripts/build-loop-read.bats:143-159`, `FC/logs/help.log`, `FC/logs/probe-git.log`

---

## Claim 11: "before the cd: relative paths work" / "The reader shared with dev-cycle.sh, from this script's own directory (never the target repo's scripts/lib/), so a copy of scripts/ with its lib/ is self-contained."

**Location:** `scripts/build-loop.sh:39-42`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers sourcing from the script's directory and refusing a copy without lib/; does not establish a symlinked-script invocation.

`SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` precedes `cd "$ROOT"` (`:39` vs `:59`); `READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"` (`:43`). Test 9 (planted `scripts/lib/dev-cycle-read.sh` not echoed; bare copy exits 1 naming `.../bare/lib/dev-cycle-read.sh`) passes at baseline; FC/inproc and FC/old copies with their own lib/ ran from scratch dirs.

**Evidence:** `scripts/build-loop.sh:39-47`, `test/scripts/build-loop-read.bats:161-168`, `FC/logs/baseline.log`

---

## Claim 12: "Read main's own objects: a replace ref could swap in any settings blob."

**Location:** `scripts/build-loop.sh:62-63`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers replace refs on main's blob, commit and tree; does not establish behaviour against grafts files or `core.useReplaceRefs` overrides beyond the env var, and no test in the suite pins it.

`export GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1` (`:63`). Executed in `FC/repos/rep-{blob,commit,tree}` (main reads review, a replace ref points to a self-merge object): plain `git cat-file blob main:docs/dev-cycle.md` shows `self-merge` in all three; the script prints `policy review set`; a mutant without `GIT_NO_REPLACE_OBJECTS=1` (`FC/bl-norepl.sh`) prints `policy self-merge set` in all three (`FC/logs/probe-git.log`, 2026-10-05T11:47:37Z, exit 0).

**Evidence:** `scripts/build-loop.sh:62-63`, `FC/logs/probe-git.log`

---

## Claim 13: "A file on main: FILE_OUT is what awk program $2 (after FENCE_AWK) printed over it; or it returns 1 with FILE_WHY "absent" or why it was not read (main_entry, a failed read, or FENCE_AWK's "odd N WHY" / "unbalanced N")."

**Location:** `scripts/build-loop.sh:67-69`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every arm (absent, notdir, error, notfile, failed cat-file, odd, unbalanced) reaching the printed lines; does not establish behaviour if awk itself fails with output.

Arms at `scripts/build-loop.sh:75-87` (`error) FILE_WHY="the default branch's tree could not be read for $f"`, `|| { FILE_WHY="$f could not be read from the default branch"; return 1; }`). Executed: duplicate tree entry (`git mktree` with two `dev-cycle.md`) → `the default branch's tree could not be read for docs/dev-cycle.md`; tree pointing at a missing blob (`mktree --missing`) → `docs/dev-cycle.md could not be read from the default branch`; gitlink → `is not a regular file`; all exit 0 with `never malformed` (`FC/logs/probe-git.log`). absent/notdir/odd/unbalanced are asserted in T3 (baseline). The error and failed-read arms have no test (settled-adjacent; C14-C17 style gap).

**Evidence:** `scripts/build-loop.sh:67-88`, `scripts/lib/dev-cycle-read.sh:258-274`, `test/scripts/build-loop-read.bats:43-68`, `FC/logs/probe-git.log`

---

## Claim 14: "A never entry: pathform's rule, but a .git* part (.github/) is allowed, since the list only adds refusals and must not turn self-merge off by naming one."

**Location:** `scripts/build-loop.sh:112-113`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers globform vs `pathform ... glob`; does not establish that U2's gate interprets the globs as git pathspecs.

`globform` (`:114-121`) equals pathform's glob branch (`scripts/lib/dev-cycle-read.sh:140-149`) minus `"$c" != [.][gG][iI][tT]*`. Mutant `if ! pathform "${g%/}" glob` (`FC/m-path`) fails T45 at bats line 130 (`want: never .github/ .gitignore set:`) (`FC/logs/mut-path.log`, 2026-10-05T11:44:53Z, exit 1).

**Evidence:** `scripts/build-loop.sh:112-121`, `scripts/lib/dev-cycle-read.sh:140-149`, `test/scripts/build-loop-read.bats:128-130`, `FC/logs/mut-path.log`

---

## Claim 15: "Sets POLICY, POLICY_LINE, SLOTS_LINE, NEVER (an array of the checked globs, each as written, a trailing / kept) and NEVER_LINE from main's commit."

**Location:** `scripts/build-loop.sh:122-124`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers NEVER's content and the reset of POLICY/NEVER (and re-set of the three *_LINE strings) on each call; does not establish how --status/the gate (not yet written) consume them.

`POLICY=review; NEVER=()` at the start of each call (`:130`) and `NEVER=("${parts[@]}")` only on success (`:164`). Executed in-process (`FC/inproc/build-loop.sh`, the script's first 180 lines plus three calls with different MAIN_SHA): first call `NEVER=([0]="a/" [1]="b/*.sh" [2]=".github/" [3]="?")`, POLICY self-merge; second (duplicate entry) `POLICY="review"`, `NEVER=()`; third (absent file) `POLICY="review"`, `NEVER=()`, lines re-set (`FC/logs/probe-git.log`, in-process section).

**Evidence:** `scripts/build-loop.sh:122-179`, `FC/inproc/build-loop.sh`, `FC/logs/probe-git.log`

---

## Claim 16: "An absent file sets nothing; one that is not read turns self-merge off."

**Location:** `scripts/build-loop.sh:135`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the never line's none/malformed split; does not establish that "turns self-merge off" has any effect beyond POLICY already being review in this branch.

`if [[ "$FILE_WHY" == absent ]]; then NEVER_LINE="never none: $why"; else NEVER_LINE="never malformed: $why"; fi` (`:136`); T3 asserts both (`never none: no docs/dev-cycle.md ...`, `never malformed: line 1 ... opens an HTML comment`), and the probe-git runs show malformed for unread files.

**Evidence:** `scripts/build-loop.sh:132-136`, `test/scripts/build-loop-read.bats:49-50`, `test/scripts/build-loop-read.bats:57-58`, `FC/logs/probe-git.log`

---

## Claim 17: "Self-merge never: first, because a malformed line turns self-merge off."

**Location:** `scripts/build-loop.sh:144`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the evaluation order between the never and policy blocks; does not establish anything about slots.

`never_ok=""` is set in the never block (`:146`, `:163`) and read by the policy block `if [[ "$v" == self-merge && -z "$never_ok" ]]` (`:170`), which follows it.

**Evidence:** `scripts/build-loop.sh:144-173`

---

## Claim 18: "Split on single spaces only; globform then refuses any other blank in an entry."

**Location:** `scripts/build-loop.sh:149`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers tab, vertical tab and NBSP inside entries; does not establish behaviour for blanks the FENCE_AWK pass refuses first (CR, NUL).

`[[ ... ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]` (`:150`) then `IFS=' ' read -ra parts <<<"$v"` (`:155`); any other blank stays in an entry and fails `^[*?$NAMECHARS]+$` (`:116`). T45's tab variants pass at baseline; probes `a\vb` and `a<NBSP>b` → `lists entry 1, which is not an allowed glob form` (`FC/logs/probe-never.log`).

**Evidence:** `scripts/build-loop.sh:149-160`, `test/scripts/build-loop-read.bats:110-112`, `FC/logs/probe-never.log`

---

## Claim 19: "not a bare $v: the shell would expand * and ? against files"

**Location:** `scripts/build-loop.sh:155`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers pathname expansion of `?`; does not establish other word-splitting differences.

Executed in `FC/repos/ip` with a file `x` at the root: the real script gives `NEVER=(... [3]="?")`; a copy with `parts=($v)` (`FC/inproc/bare.sh`) gives `[3]="x"` (run interactively 2026-10-05).

**Evidence:** `scripts/build-loop.sh:155`, `FC/inproc/bare.sh`

---

## Claim 20: "a throwaway repo under $BATS_TEST_TMPDIR with a main branch, the same hermetic git environment as test/scripts/dev-cycle.bats"

**Location:** `test/lib/build-loop-fixtures.bash:2-5`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the git env variables and repo location; does not re-litigate settled C6 (not loading hermetic-env.bash).

`export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`, author/committer t / t@example.invalid, `HOME="$BATS_TEST_TMPDIR/home"` (`test/lib/build-loop-fixtures.bash:12-15`) match `test/scripts/dev-cycle.bats:11-15`; `git init -q -b main` (`:19`). bl_setup adds `LC_ALL=C`.

**Evidence:** `test/lib/build-loop-fixtures.bash:8-20`, `test/scripts/dev-cycle.bats:11-15`

---

## Claim 21: "settings LINE...: docs/dev-cycle.md holding these lines (printf %s\n each), committed. With no lines the file holds one empty line."

**Location:** `test/lib/build-loop-fixtures.bash:24-25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the no-argument case; does not establish any caller uses it.

`printf '%s\n' "$@" > docs/dev-cycle.md` (`:26`). Executed: `printf '%s\n' | od -c` → `\n` (one byte).

**Evidence:** `test/lib/build-loop-fixtures.bash:26`

---

## Claim 22: "settings_is KEY WANT / settings_like KEY PREFIX: run --settings; its KEY line must equal WANT, or start with PREFIX. On a mismatch, print the whole output."

**Location:** `test/lib/build-loop-fixtures.bash:28-29`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the comparison and the failure print (stdout and stderr); does not establish exit-status checking (neither helper checks `$status`).

`[ "$(line "$1")" = "$2" ] || { echo "want: $2"; echo "$output $stderr"; return 1; }` and the `== "$2"*` variant (`:31-32`). Mutant logs show the `want:` line and full output on failure (`FC/logs/mut-head.log`).

**Evidence:** `test/lib/build-loop-fixtures.bash:31-32`, `FC/logs/mut-head.log`

---

## Claim 23: "line KEY: the --settings output line that starts with KEY."

**Location:** `test/lib/build-loop-fixtures.bash:34`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers first-match selection on "KEY "; does not establish behaviour with multiple matching lines (output has exactly one per key).

`line() { printf '%s\n' "$output" | grep -m1 "^$1 " || true; }` (`:36`).

**Evidence:** `test/lib/build-loop-fixtures.bash:36`

---

## Claim 24: "Each test builds a throwaway repo under $BATS_TEST_TMPDIR ...; this repo is untouched. The lib ... is also tested from dev-cycle.sh's side, in test/scripts/dev-cycle.bats."

**Location:** `test/scripts/build-loop-read.bats:3-6`
**Type:** Invariant / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the suite leaves the worktree clean; does not establish dev-cycle.bats' coverage of the lib.

`setup() { bl_setup; }` (`:11`); test 4 only copies `$REPO_ROOT/docs/dev-cycle.md` out. After the baseline and mutant runs, `git status --porcelain` in the worktree printed nothing.

**Evidence:** `test/scripts/build-loop-read.bats:11`, `test/scripts/build-loop-read.bats:70-76`, `FC/logs/baseline.log`

---

## Claim 25: "--settings: an exact policy line is set, a trailing CR included (T1)"

**Location:** `test/scripts/build-loop-read.bats:13`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both values with and without CR; does not establish two-CR handling.

`printf 'Build-loop policy: %s\r\n' "$v" > docs/dev-cycle.md && commit_all cr` then `settings_is policy "policy $v set: line 1 ..."` (`:19-20`); passes at baseline.

**Evidence:** `test/scripts/build-loop-read.bats:13-22`, `FC/logs/baseline.log`

---

## Claim 26: "a fenced line, an open comment, a BOM or a file that is not plain on main reads review (T3)" / "Missing, a symlink, a directory, and a file only in the working tree."

**Location:** `test/scripts/build-loop-read.bats:43`, `test/scripts/build-loop-read.bats:55`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed shape (plus a symlinked docs/); does not cover the error and failed-read arms (Claim 13).

Each shape has a `settings_is`/`settings_like` assertion at `:45-67`; passes at baseline.

**Evidence:** `test/scripts/build-loop-read.bats:43-68`, `FC/logs/baseline.log`

---

## Claim 27: "--settings reads main's commit: the working tree and other branches never decide (T4)" / "Committed on a checked-out loop branch: HEAD is not main."

**Location:** `test/scripts/build-loop-read.bats:78`, `test/scripts/build-loop-read.bats:82`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers discrimination of a HEAD-reading and a working-tree-reading mutant; does not establish other-ref (origin/HEAD) cases (settled C18).

`git checkout -q -b loop && commit_all raise` then `settings_like policy "policy review set:"` (`:83-84`). Mutant `git cat-file blob "HEAD:$f"` fails T4 at line 84 (`FC/logs/mut-head.log`, 11:44:51Z, exit 1); mutant `cat "$f"` fails T4 at line 81 (`FC/logs/mut-wt.log`, 11:44:56Z, exit 1).

**Evidence:** `test/scripts/build-loop-read.bats:78-88`, `FC/logs/mut-head.log`, `FC/logs/mut-wt.log`

---

## Claim 28: "Copies in markup, a table, a link or with a misplaced colon count as second lines too."

**Location:** `test/scripts/build-loop-read.bats:122`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the eight listed shapes and that the loop discriminates the 0ae7d801 matcher; does not cover non-ASCII-letter copies (Claim 5 residue).

The loop asserts `settings_like never 'never malformed: more than one line starts "Self-merge never:"'` per shape (`:123-126`). The 0ae7d801 script (`FC/old/build-loop.sh`) leaves `never a/ set` for `**Self-merge never**: b/`, `[Self-merge never](x): b/` and `Self-merge never : b/` (interactive run), so the loop would fail on the old matcher; a loop-body helper failure is fatal (Claim 33).

**Evidence:** `test/scripts/build-loop-read.bats:122-127`, `scripts/build-loop.sh:101-105`, `FC/old/build-loop.sh`

---

## Claim 29: "A part starting .git is allowed: the list only adds refusals."

**Location:** `test/scripts/build-loop-read.bats:128`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `.github/` and `.gitignore`; same as Claim 14.

Path mutant fails at `:130` (`FC/logs/mut-path.log`).

**Evidence:** `test/scripts/build-loop-read.bats:128-130`, `FC/logs/mut-path.log`

---

## Claim 30: "A never line Markdown would continue on the next line is malformed."

**Location:** `test/scripts/build-loop-read.bats:131`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a paragraph-continuation line (`b/`) and the blank-line-then-key layout; does not establish that only continuation lines are refused (others are too, Claim 7).

`settings 'Build-loop policy: self-merge' 'Self-merge never: a/' 'b/'` → `settings_is never 'never malformed: line 2 is followed by a non-blank line ...'` (`:132-133`); passes at baseline.

**Evidence:** `test/scripts/build-loop-read.bats:131-135`, `FC/logs/baseline.log`

---

## Claim 31: "Raised only on a loop's branch or in the working tree: ignored."

**Location:** `test/scripts/build-loop-read.bats:136`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers HEAD- and working-tree-reading mutants; does not cover replace refs (Claim 12, untested).

Both mutants fail T45 at `:140` (`want: never workflows/ set:`) (`FC/logs/mut-head.log`, `FC/logs/mut-wt.log`).

**Evidence:** `test/scripts/build-loop-read.bats:136-140`, `FC/logs/mut-head.log`, `FC/logs/mut-wt.log`

---

## Claim 32: "From a subdirectory and from a linked worktree, it reads the same main."

**Location:** `test/scripts/build-loop-read.bats:169`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the behaviour and the test's discrimination of a working-tree-reading mutant; does NOT discriminate a mutant reading HEAD or the worktree's HEAD, because both checkouts' HEAD is main's commit (see Claim 36b).

`git worktree add -q -b wt "$BATS_TEST_TMPDIR/wt" main` (`:171`) creates branch `wt` at main's commit, and `sub` runs with HEAD = main; both working trees are edited to review (`:172`). The working-tree mutant fails at `:176` (`FC/logs/mut-wt.log`); the HEAD mutant passes test 9 (`FC/logs/mut-head.log`: `ok 9`).

**Evidence:** `test/scripts/build-loop-read.bats:169-178`, `FC/logs/mut-head.log`, `FC/logs/mut-wt.log`

---

## Claim 33: "R2: `settings_like A && settings_like B` never failed the test when A failed (not the last command). The checks are separate commands now; a mutation back to pathform fails T45."

**Location:** commit 1d79ffef message (`test/scripts/build-loop-read.bats:81`, `:87`, `:130`)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every settings_is/settings_like call and helper calls inside for-loop bodies; does not establish that setup chains such as `git merge -q loop && git checkout ... && printf` (`:86`) fail loudly (they are fixtures, and a broken fixture fails the following assertion).

`grep -nE 'settings_(is|like)[^;]*&&' test/scripts/build-loop-read.bats` → no match; paired checks use `;` (`:81`, `:87`, `:130`). Path mutant fails T45 at `:130` (`FC/logs/mut-path.log`). A failing helper inside a for-loop body is fatal: the trailing-space mutant fails T2 at `:29`, inside the loop (`FC/logs/mut-loop.log`).

**Evidence:** `test/scripts/build-loop-read.bats:26-30`, `test/scripts/build-loop-read.bats:78-88`, `test/scripts/build-loop-read.bats:128-130`, `FC/logs/mut-path.log`, `FC/logs/mut-loop.log`

---

## Claim 34: "R3/A5: ... A line now counts as a copy when its letters alone, case folded, start with the key's, so any of them is a second line (policy unset, never malformed). A never line followed by a non-blank line is malformed"

**Location:** commit 1d79ffef message (`scripts/build-loop.sh:96-111`, `:152`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rule and its effect on policy and never; the parenthetical reason is verdicted in Claim 7; non-ASCII residue as in Claim 5.

Same evidence as Claims 5 and 30 (`FC/logs/probe-copies.log`, `FC/logs/probe-next.log`).

**Evidence:** `scripts/build-loop.sh:96-111`, `scripts/build-loop.sh:152`, `FC/logs/probe-copies.log`, `FC/logs/probe-next.log`

---

## Claim 35: "A6: GIT_NO_REPLACE_OBJECTS=1 ... A7: main_file names main_entry's error and a failed blob read. A8: NEVER is an array of the checked entries. A11-A13: fixture and header comments; Exit names help; "Unknown option" as in the sibling scripts. C3: read_settings resets POLICY and NEVER; C13: the no-echo check covers tabs. Also merges feat/build-loop-u1a's iteration-2 fixes first."

**Location:** commit 1d79ffef message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed fix as present at HEAD; does not establish that A6/A7's new arms are pinned by tests (they are not).

A6: Claim 12. A7: Claim 13. A8/C3: Claim 15. A11: Claim 21. A12: Claim 10. A13: Claim 28. "Unknown option": `*) usage "Unknown option: $1" ;;` (`scripts/build-loop.sh:55`) matches `scripts/dev-cycle.sh:112` `echo "Unknown option: $1"`. C13: `"$output" != *$'\t'*` (`test/scripts/build-loop-read.bats:117`). Merge order: `git log --oneline` shows 93f09654 (merge of feat/build-loop-u1a) directly below 1d79ffef.

**Evidence:** `scripts/build-loop.sh:55`, `scripts/dev-cycle.sh:112`, `test/scripts/build-loop-read.bats:117`, `FC/logs/probe-git.log`

---

## Claim 36a: "A14/A15: ... T4 and T45 now have a working tree and a checked-out branch that differ from main; a mutant reading HEAD fails them."

**Location:** commit 1d79ffef message (`test/scripts/build-loop-read.bats:78-88`, `:136-141`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers T4 and T45 only.

HEAD mutant fails T4 (`:84`) and T45 (`:140`) (`FC/logs/mut-head.log`, 2026-10-05T11:44:51Z, exit 1).

**Evidence:** `test/scripts/build-loop-read.bats:82-84`, `test/scripts/build-loop-read.bats:137-140`, `FC/logs/mut-head.log`

---

## Claim 36b: "A14/A15: the subdirectory and worktree runs ... now have a working tree and a checked-out branch that differ from main; a mutant reading HEAD fails them."

**Location:** commit 1d79ffef message (`test/scripts/build-loop-read.bats:169-178`)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers test 9's subdirectory and linked-worktree runs; does not affect T4/T45 (Claim 36a), which do catch the HEAD mutant, so the suite as a whole still kills it.

The working trees differ from main (`for d in . "$BATS_TEST_TMPDIR/wt"; do printf 'Build-loop policy: review\n' > "$d/docs/dev-cycle.md"; done`, `:172`), but the checked-out commit does not: the subdirectory run uses the main repo, whose HEAD is main, and `git worktree add -q -b wt "$BATS_TEST_TMPDIR/wt" main` (`:171`) puts branch `wt` at main's own commit. The `git cat-file blob "HEAD:$f"` mutant passes test 9 (`ok 9` in `FC/logs/mut-head.log`); only the working-tree mutant fails it (`:176`, `FC/logs/mut-wt.log`). Original A14 ("could not tell main from ... worktree HEAD") is thus fixed for the working tree only. To be true, test 9 would need a commit on `wt` (or on a checked-out branch in the main repo) that differs from main.

**Evidence:** `test/scripts/build-loop-read.bats:169-178`, `FC/logs/mut-head.log`, `FC/logs/mut-wt.log`

---

## Claim 37: "The unit is 400 changed code lines (header wording tightened)."

**Location:** commit 1d79ffef message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers scripts/ and test/ in the three-dot diff; does not count docs/reviews/ artifacts.

`git diff --numstat feat/build-loop-u1a...HEAD -- scripts test` → `186 0 scripts/build-loop.sh`, `36 0 test/lib/build-loop-fixtures.bash`, `178 0 test/scripts/build-loop-read.bats` = 400 (run 2026-10-05, cwd the worktree, exit 0).

**Evidence:** `scripts/build-loop.sh:1-186`, `test/lib/build-loop-fixtures.bash:1-36`, `test/scripts/build-loop-read.bats:1-178`

---

## Claim 38: "the letters-only match can unset the policy for a prose line that starts with the key's words (docs/dev-cycle.md has none; T3's real-file test would catch one)"

**Location:** commit 1d79ffef message (Notes)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers docs/dev-cycle.md at HEAD and test 4's detection for each key; does not establish future edits.

"has none": the letters-only awk over `docs/dev-cycle.md` matches only line 7, `Build-loop policy: review (interim; Q-103)` (the setting itself). "T3's real-file test would catch one" holds only for the policy key: test 4 asserts only `line policy` (`test/scripts/build-loop-read.bats:74`). Executed in copies with one prose line appended: `Build-loop policy is read from main only.` → test 4 fails (`FC/logs/doc-policy.log`, exit 1); `Self-merge never lands a change to the instruction files.` → passes (`FC/logs/doc-never.log`, exit 0) though it would make the never line malformed and turn self-merge off; `Build-loop slots are counted per open brief.` → passes (`FC/logs/doc-slots.log`, exit 0) though slots would fall to 3. Precise version: "T3's real-file test would catch one for the policy key".

**Evidence:** `test/scripts/build-loop-read.bats:70-76`, `scripts/build-loop.sh:101-104`, `FC/logs/doc-policy.log`, `FC/logs/doc-never.log`, `FC/logs/doc-slots.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 36b** (commit 1d79ffef message; `test/scripts/build-loop-read.bats:169-178`): the subdirectory and worktree runs do not have a checked-out commit that differs from main, and a HEAD-reading mutant passes test 9. Only T4 and T45 catch it.

### Stale
- (none)

### Mostly Accurate
- **Claim 1** (`scripts/build-loop.sh:10-12`): a second never copy does not "leave the default". It prints `never malformed` and turns self-merge off.
- **Claim 6** (`scripts/build-loop.sh:20`, `:92-93`): NEXT is the next line outside a fence, or EOF. A fence line also ends a never line.
- **Claim 7** (`scripts/build-loop.sh:152`; same parenthetical in 1d79ffef's message): "Markdown would join it" is wrong for a heading, a list item or an HTML comment, which are refused too.
- **Claim 38** (1d79ffef Notes): T3's real-file test catches a prose copy only for the policy key, not for slots or never.

### Unverifiable
- (none)

---

## Goal-Alignment Note

**Success criterion (verbatim):** A markdown report saved to the path below, structured per the code-fact-check skill.

**Answered:** Yes. All comments and header claims in the three code files were checked, along with test titles and comments and 1d79ffef's message claims. Each claim got a verdict, and 35 of the 39 were verified by execution (probes, in-process runs and mutants in the scratch dir). The baseline suite passes 9/9.

**Out of scope:** Re-verdicting the messages of 0797ed32, 224dd52d, 30676e57 and 0ae7d801 (verdicted at 0ae7d801; A9/A10 are settled). Settled override-log rows. Lib behaviour beyond what build-loop.sh reaches. Quality findings about the code (for example, the A6/A7 arms and replace refs have no test).

**Escalate:** Claim 36b. A14's fix for the subdirectory and worktree test is partial. Test 9 still cannot tell main's commit from the checked-out HEAD, though T4 and T45 cover this for the suite as a whole. The orchestrator should decide whether this is an amber test gap or only a message inaccuracy (history is not rewritten).

**Questions/Decisions:** Claim 5 residue: a copy whose key letters include non-ASCII bytes (`pólicy`, Cyrillic homoglyphs) stays hidden. This is the same class as settled C19, and the C19 row's premise ("does not render as the key") is weaker for homoglyphs, which do render as the key. It is still fail-closed for the policy value, because only an exact ASCII line sets anything.
