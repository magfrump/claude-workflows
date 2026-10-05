**Commit:** 0ae7d801

# Code Fact-Check Report

**Repository:** claude-workflows (worktree /workspace/.claude/wt-build-loop-u1b, branch feat/build-loop-u1b)
**Scope:** `git diff feat/build-loop-u1a...feat/build-loop-u1b`: scripts/build-loop.sh, test/lib/build-loop-fixtures.bash, test/scripts/build-loop-read.bats, plus commit messages 0797ed32, 224dd52d, 30676e57, 0ae7d801; scripts/lib/dev-cycle-read.sh read as context only
**Checked:** 2026-10-05
**Commit:** 0ae7d801
**Replication:** replicate r3 of 3 (review-fix loop iteration 2, full panel)
**Total claims checked:** 38
**Summary:** 29 verified, 5 mostly accurate, 0 stale, 4 incorrect, 0 unverifiable

Execution logs (scratch dir, per the pass rules; not under docs/reviews/execution-logs/), all in `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i2/fc-r3/`:

- `bats.log` — `export LC_ALL=C.UTF-8 && bats test/scripts/build-loop-read.bats test/scripts/dev-cycle.bats`, cwd the worktree, 2026-10-05T11:09:07Z, exit 0, 75/75 ok (9 + 66).
- `cases1.log`, `cases2.log` — `bash cases1.sh` / `bash cases2.sh`, cwd the scratch dir, 2026-10-05T11:14:19Z / 11:11:29Z, exit 0. Each case commits the shown text as docs/dev-cycle.md in a fresh repo (`probe.sh`) and runs the worktree's `scripts/build-loop.sh --settings`.
- `cases3.log` (11:12:52Z) and `cases4.log` (11:13:06Z) — `bash cases3.sh`, `bash cases4.sh`, cwd the scratch dir, exit 0: scrub of a usage error, relative script path, `-h` range, `printf '%s\n'` with no arguments, read-only snapshot, no-perl exit.
- `mutation.log` — copies under `mut/{base,m1,m2,m3,t1}` (scripts/, test/lib, test/scripts copied from the worktree), each `bats -f 'T4\)|T45' test/scripts/build-loop-read.bats`, cwd the copy, 2026-10-05T11:11:09Z; per-copy exit codes in the log.
- `glob.log` — bash demonstration of bare `$v` vs `IFS=' ' read -ra`.

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`); no claim below matches a logged pattern. No fabricated symbol was found, so nothing qualifies for the log (and this pass writes nothing in the worktree except this report).

---

## Claim 1: "three lines, from the default branch's commit (never the working tree, which a build loop can write)"

**Location:** `scripts/build-loop.sh:9-10`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the settings file is read as `$MAIN_SHA:docs/dev-cycle.md` and that working-tree and other-branch edits do not decide; does not establish behaviour when origin/HEAD names a branch other than main (resolve_main, lib, not exercised by a test here).

```bash
# scripts/build-loop.sh:89
  FILE_OUT="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk "$FENCE_AWK$2")"
```
T4 (working tree says self-merge / slots 7, main says review → `policy review set`, `slots 3 default`; a merged branch then decides) passes (`bats.log`, ok 5).

**Evidence:** `scripts/build-loop.sh:79-94`, `test/scripts/build-loop-read.bats:77-85`, `bats.log`

---

## Claim 2: "It is set only when exactly one line, outside code fences, starts "Build-loop policy:" and reads exactly ... (one trailing CR is dropped). Any other case, or a malformed never line, means review."

**Location:** `scripts/build-loop.sh:11-16`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers count-of-one, exact whole-line match, fenced lines not counting, one trailing CR dropped, a second CR refusing the file, and the malformed-never override; "starts" means after the prefix strip of Claim 6a (any case), which the header states two lines later.

```awk
# scripts/build-loop.sh:102
{ sub(/\r$/, "") }
```
```bash
# scripts/build-loop.sh:174
    elif [[ "${text[policy]}" =~ ^Build-loop\ policy:\ (self-merge|review)$ ]]; then
```
(excerpt ends :174; enclosing read_settings() continues to :185 — read). `cases1.log`: `Build-loop policy: self-merge\r\n` → `policy self-merge set`; `...\r\r\n` → file refused ("holds a carriage return that does not end it"). T1/T2/T3 pass.

**Evidence:** `scripts/build-loop.sh:101-117`, `scripts/build-loop.sh:172-179`, `cases1.log`, `bats.log`

---

## Claim 3: "one line "Build-loop slots: N" with N from 1 to 9, else 3"

**Location:** `scripts/build-loop.sh:17-19`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers 1–9 exact, 0/10/05/trailing space/word/duplicate/fenced/case-variant → 3; does not establish anything about how a later mode uses SLOTS (no SLOTS variable is set; only SLOTS_LINE).

```bash
# scripts/build-loop.sh:182
    elif [[ "${text[slots]}" =~ ^Build-loop\ slots:\ ([123456789])$ ]]; then SLOTS_LINE="slots ${BASH_REMATCH[1]} set: line ${first[slots]} $where"
```
`cases1.log`: `Build-Loop Slots: 4` → `slots 3 default: line 2 is not exactly ...`. Slots test passes (ok 6).

**Evidence:** `scripts/build-loop.sh:180-183`, `test/scripts/build-loop-read.bats:87-97`, `cases1.log`

---

## Claim 4: "Self-merge never: GLOB ..." (single spaces, no tab; each glob uses letters, digits, . _ - / * ?, with an optional trailing /; no empty, . or .. part, not starting / or -; none twice, a trailing / ignored)

**Location:** `scripts/build-loop.sh:20-25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each listed rule by probe; does not establish rules the header leaves unstated — VT and FF are also refused, `.git`-prefixed parts (including `.git/` itself) are accepted (Claim 16), and only one trailing / is ignored (`a//` is malformed by its empty part).

```bash
# scripts/build-loop.sh:157
      if [[ "$t" != "Self-merge never: "* || "$v" == *[$'\t\v\f\r']* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]; then
```
```bash
# scripts/build-loop.sh:124
  [[ "$1" =~ ^[*?$NAMECHARS]+$ && "$1" != /* && "$1" != -* ]] || return 1
```
(excerpt ends :124; enclosing globform() continues to :129 — read). `cases2.log`: `a\vb`, `a\fb` → "not exactly ... with single spaces"; `a\xc2\xa0b`, `[ab]`, `a,b`, `/`, `a//`, `./a`, `a/./b` → "not an allowed glob form"; `*`, `*/ a`, `a/ *` → set. T45 covers tabs, double space, `..`, `/etc`, `-x`, duplicates, `a a/`, non-ASCII.

**Evidence:** `scripts/build-loop.sh:118-129`, `scripts/build-loop.sh:150-171`, `cases2.log`, `bats.log`

---

## Claim 5: "A malformed line, or a settings file that is not read, turns self-merge off."

**Location:** `scripts/build-loop.sh:26-27`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers malformed-by-count, malformed-by-form and not-read (refused, not regular, notdir) paths; an absent file prints `never none` but the policy is then unset anyway, so self-merge is off there too.

```bash
# scripts/build-loop.sh:143
    if [[ "$FILE_WHY" == absent ]]; then NEVER_LINE="never none: $why"; else NEVER_LINE="never malformed: $why"; fi
```
(excerpt ends :143; enclosing read_settings() continues to :185 — read). POLICY is assigned only at `:178` inside the file-read branch; T3/T45 and `cases1.log` (CR CR case) show `policy review unset` with `never malformed`.

**Evidence:** `scripts/build-loop.sh:135-185`, `cases1.log`, `bats.log`

---

## Claim 6a: "A line outside a fence counts as a settings line when it starts with the key (any case) after any blanks, >, list markers, # * _ ` ~ and byte-order marks"

**Location:** `scripts/build-loop.sh:28-30`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the strip as implemented: blanks are space and tab only, `-`/`+` and `N.`/`N)` count as list markers only when followed by a blank, `*` with or without; does not establish that other rendered-equivalent prefixes (NBSP, task-list `[ ]`, table `|`, zero-width characters) are stripped — they are not.

```awk
# scripts/build-loop.sh:106
  if (match(s, /^([ \t>#*_`~]|[-+][ \t]|[0123456789]+[.)][ \t]|\357\273\277)*/)) s = substr(s, RLENGTH + 1)
```
(excerpt ends :106; enclosing awk main rule continues to :112 — read). `cases1.log` (mawk): counted — `1.`, `1)`, tab, 4 spaces, `* `, `*`, `+ `, `#`, `> - # **...:**`, `~~`, long numbered marker; not counted — `\xc2\xa0` (NBSP), `- [ ] `, `- [x] `, `| ... |`, ZWSP, `-Key`, `1.Key`.

**Evidence:** `scripts/build-loop.sh:101-117`, `cases1.log`

---

## Claim 6b: "so a quoted, bold, heading or indented copy is a second line, not a hidden one"

**Location:** `scripts/build-loop.sh:30-31`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the bold/emphasis/code-span forms whose closing marks sit before the colon; does not establish whether hidden copies matter for any reader other than a human viewing rendered Markdown.

Bold works only when the colon is inside the bold: after the strip at `:106`, `**Build-loop policy**: review` becomes `build-loop policy**: review`, which does not start with `build-loop policy:`:

```awk
# scripts/build-loop.sh:108
  if (index(s, "build-loop policy:") == 1) k = "policy"
```
(excerpt ends :108; enclosing awk main rule continues to :112 — read). `cases2.log`: with `Build-loop policy: self-merge` on line 1, each of `**Build-loop policy**: review`, `*Build-loop policy*: review`, `` `Build-loop policy`: review `` leaves `policy self-merge set`; `**Self-merge never**: b/` after `Self-merge never: a/` leaves `never a/ set`. `cases1.log`: `__Build-loop policy__: review` likewise hidden. Rendered, each shows the key label followed by ": value", i.e. a second visible setting the script ignores. The tested form `**Build-loop policy:** review` (colon inside the bold) is counted. The precise version: a copy counts when the key text including its colon is contiguous after the stripped prefix; a bold/emphasis/code span that closes before the colon stays hidden.

**Evidence:** `scripts/build-loop.sh:106-110`, `cases2.log`, `cases1.log`

---

## Claim 7: "A file the lib's FENCE_AWK refuses (its comment lists each shape) is not read at all, and the line printed says why."

**Location:** `scripts/build-loop.sh:31-33`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the odd/unbalanced paths and that all three printed lines carry FILE_WHY; FENCE_AWK's own shape list (lib:163-179) was read as context, not re-verified here.

```bash
# scripts/build-loop.sh:91-92
    odd\ *) read -r _ n why <<<"$FILE_OUT"; FILE_WHY="line $n of $f $(oddwhy "$why"), so the file is not read"; return 1 ;;
    unbalanced\ *) FILE_WHY="the code fence opened at line ${FILE_OUT#unbalanced } of $f is never closed, so the file is not read"; return 1 ;;
```
`cases1.log` CR CR case prints the reason on policy, slots and never lines; T3 covers open comment, BOM, unbalanced fence.

**Evidence:** `scripts/build-loop.sh:79-94`, `scripts/build-loop.sh:139-143`, `cases1.log`, `bats.log`

---

## Claim 8: "Acts on $PWD's git repo, like dev-cycle.sh, and needs its default branch found by name (origin/HEAD, main or master)."

**Location:** `scripts/build-loop.sh:35-36`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the top-level resolution from a subdirectory and the exit when only a non-main branch exists; the origin/HEAD candidate is lib behaviour, read statically only.

```bash
# scripts/build-loop.sh:65,71
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Not inside a git repository" >&2; exit 1; }
main_by_name || { echo "build-loop.sh needs a default branch found by name (origin/HEAD, main or master); found none" >&2; exit 1; }
```
Test 8 (branch renamed to trunk → exit 1, "needs a default branch") passes; `cases3.log` runs from `sub/`.

**Evidence:** `scripts/build-loop.sh:65-71`, `cases3.log`, `bats.log`

---

## Claim 9: "Read-only: writes nothing."

**Location:** `scripts/build-loop.sh:36`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers one `--settings` run in a repo with a dirty working tree (paths, sizes, mtimes, modes of the tree and .git unchanged); does not establish git-config-driven side effects (hooks, auto-maintenance) under non-hermetic configs.

Every git call in the script is a read (`rev-parse`, `ls-tree`, `cat-file`, `show-ref`, `symbolic-ref`) (paraphrased — no quote available because the calls span the script and the lib's main_entry/resolve_main). `cases4.log`: "tree and .git unchanged (paths, sizes, mtimes, modes)".

**Evidence:** `scripts/build-loop.sh:65-71`, `scripts/build-loop.sh:89`, `cases4.log`

---

## Claim 10: "Output passes through the lib's scrub (all but the two start-up errors before it, about perl and the lib, which carry no repo text)"

**Location:** `scripts/build-loop.sh:37-39`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers stdout and stderr after `scrub_reexec` (usage errors included) and the two pre-scrub messages; does not establish messages bash itself would print before `:54` (e.g. a failing `cd` in SCRIPT_DIR's substitution), which carry no repo text either.

```bash
# scripts/build-loop.sh:45,51,54
command -v perl >/dev/null || { echo "build-loop.sh needs perl (to scrub its output)" >&2; exit 1; }
[[ -f "$READ_LIB" ]] || { echo "build-loop.sh needs $READ_LIB" >&2; exit 1; }
scrub_reexec "${BASH_SOURCE[0]}" "$@"
```
`cases3.log`: an option holding ESC and U+202E comes back as `unknown option: --x[31mREDZ` (both removed). `cases4.log`: no perl on PATH → the perl message, exit 1.

**Evidence:** `scripts/build-loop.sh:45-54`, `scripts/lib/dev-cycle-read.sh:76-81`, `cases3.log`, `cases4.log`

---

## Claim 11: "Exit: 0 every line printed; 1 bad usage, not a git repo, no perl or lib/dev-cycle-read.sh, or no default branch found by name."

**Location:** `scripts/build-loop.sh:40-41`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers each listed 1 path (executed: usage, not a repo, no default branch, no lib, no perl) and 0 for `--settings`; does not establish exits from unexpected git failures under `set -e`.

All listed paths behave as stated (tests 8 and 9, `cases4.log`). Missing qualifier: `-h|--help` also exits 0 without printing the three lines:

```bash
# scripts/build-loop.sh:60
  -h|--help) sed -n '2,41p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
```
Precise version: "0 every line printed, or help shown".

**Evidence:** `scripts/build-loop.sh:56-71`, `cases4.log`, `bats.log`

---

## Claim 12: help prints the header (`sed -n '2,41p'`)

**Location:** `scripts/build-loop.sh:60`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that lines 2–41 are exactly the header comment (line 42 is blank, 43 is `set -euo pipefail`); does not establish the range stays right after future header edits.

`cases3.log`: `-h` prints 40 lines, first "The build-loop handoff's state and checks...", last "lib/dev-cycle-read.sh, or no default branch found by name."

**Evidence:** `scripts/build-loop.sh:1-43`, `cases3.log`

---

## Claim 13: "before the cd: relative paths work" / the lib "from this script's own directory (never the target repo's scripts/lib/), so a copy of scripts/ with its lib/ is self-contained"

**Location:** `scripts/build-loop.sh:46-51`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a relative script path run from a subdirectory and the planted-lib / bare-copy cases; does not establish behaviour when the script is reached through a symlink (BASH_SOURCE is not resolved).

```bash
# scripts/build-loop.sh:46,50
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  # before the cd: relative paths work
READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"
```
`cases3.log`: `bash ../../…/scripts/build-loop.sh --settings` from `sub/` prints all three lines, exit 0. Test 9 (PLANTED lib in the target repo not sourced; bare copy exits 1 naming `bare/lib/dev-cycle-read.sh`) passes.

**Evidence:** `scripts/build-loop.sh:45-54`, `test/scripts/build-loop-read.bats:152-168`, `cases3.log`, `bats.log`

---

## Claim 14: main_file "sets FILE_WHY and returns 1 when it is absent ("absent"), stored as anything but a regular file under plain directories, or refused by FENCE_AWK; otherwise FILE_OUT holds what the awk program $2 printed"

**Location:** `scripts/build-loop.sh:73-77`
**Type:** Behavioral / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers every branch of main_file; does not establish how often main_entry's `error` is reachable (it needs ls-tree to fail after main_by_name passed).

The three listed causes match the code. A fourth return-1 path is not named: main_entry's `error` (ls-tree failed) falls into the catch-all and is reported as "not a regular file":

```bash
# scripts/build-loop.sh:82-88
  e="$(main_entry "$f")"
  case "$e" in
    blob) ;;
    absent) FILE_WHY=absent; return 1 ;;
    notdir\ *) FILE_WHY="${e#notdir } is not a directory on the default branch"; return 1 ;;
    *) FILE_WHY="$f is not a regular file on the default branch"; return 1 ;;
  esac
```
(excerpt ends :88; enclosing main_file() continues to :94 — read). The lib's own callers print "the default branch's tree could not be read" for `error` (`scripts/lib/dev-cycle-read.sh:325`). On a refusal FILE_OUT keeps the `odd …`/`unbalanced …` text (not cleared), which the comment does not contradict. Precise version: add "or its tree could not be read (reported as not a regular file)".

**Evidence:** `scripts/build-loop.sh:73-94`, `scripts/lib/dev-cycle-read.sh:256-267`, `scripts/lib/dev-cycle-read.sh:320-327`

---

## Claim 15: SETTINGS_AWK: "per key, how many lines start with it (after blanks, >, list markers, heading and emphasis marks (# * _ ` ~) and a BOM, any case), the first two line numbers and the first line whole: "KEY COUNT FIRST SECOND<TAB>LINE"."

**Location:** `scripts/build-loop.sh:96-99`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the strip (same probes as Claim 6a; any number of BOMs, not one), the record format (SECOND is 0 when absent; LINE is `$0` after the CR drop, prefix included); does not establish the rendered-equivalence conclusion (Claim 6b).

```awk
# scripts/build-loop.sh:111,116
  if (k != "") { c[k]++; if (c[k] == 1) { l1[k] = NR; t[k] = $0 } else if (c[k] == 2) l2[k] = NR }
  else for (k in c) print k " " c[k] " " l1[k] " " (k in l2 ? l2[k] : 0) "\t" t[k]
```
**Evidence:** `scripts/build-loop.sh:96-117`, `cases1.log`, `cases2.log`

---

## Claim 16: globform: "pathform's characters and glob marks, not starting / or -, no empty, . or .. part. Unlike pathform it allows a part starting .git (.github/, .gitignore): the list only adds refusals"

**Location:** `scripts/build-loop.sh:118-121`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the comparison with pathform (same NAMECHARS + `*?`, same leading and part rules, minus pathform's `[.][gG][iI][tT]*` refusal); does not establish whether accepting `.git`, `.git/`, `.GIT` and `.git/config` matters — they are accepted (`cases2.log`), and since git never tracks a `.git` path, such entries can only add refusals that never match.

```bash
# scripts/build-loop.sh:122-129
globform() {
  local rest="$1/" c
  [[ "$1" =~ ^[*?$NAMECHARS]+$ && "$1" != /* && "$1" != -* ]] || return 1
  while [[ -n "$rest" ]]; do
    c="${rest%%/*}"; rest="${rest#*/}"
    [[ -n "$c" && "$c" != "." && "$c" != ".." ]] || return 1
  done
}
```
vs `scripts/lib/dev-cycle-read.sh:147` `[[ -n "$c" && "$c" != "." && "$c" != ".." && "$c" != [.][gG][iI][tT]* ]] || return 1`.

**Evidence:** `scripts/build-loop.sh:118-129`, `scripts/lib/dev-cycle-read.sh:139-149`, `cases2.log`

---

## Claim 17: "Sets POLICY, POLICY_LINE, SLOTS_LINE, NEVER (the globs, or empty) and NEVER_LINE from main's commit."

**Location:** `scripts/build-loop.sh:130-132`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers which globals each branch assigns; NEVER holds the value as written (`$v`, trailing slashes kept) while validation and the duplicate check used `${g%/}`; does not establish how --status or the gate will use them (U1c/U2).

```bash
# scripts/build-loop.sh:170
      else NEVER="$v"; NEVER_LINE="never $v set: line ${first[never]} $where"; fi
```
(excerpt ends :170; enclosing read_settings() continues to :185 — read). POLICY is assigned only at `:178`; on the not-read path only the three *_LINE globals are set and POLICY/NEVER keep their `review`/empty initial values (`:133`).

**Evidence:** `scripts/build-loop.sh:130-185`

---

## Claim 18: "Single spaces only: a tab or other blank would split differently in a later reader." / "not a bare $v: the shell would expand * and ? against files"

**Location:** `scripts/build-loop.sh:156-161`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers refusal of tab, VT, FF (executed) and the no-glob split; CR in the bracket is unreachable (a trailing CR is dropped at `:102`, any other CR refuses the file in FENCE_AWK), which is harmless.

```bash
# scripts/build-loop.sh:161
        IFS=' ' read -ra parts <<<"$v"  # not a bare $v: the shell would expand * and ? against files
```
`glob.log`: with `a.sh b.sh` present, a bare `for g in $v` over `*.sh x?` yields `a.sh`, `b.sh`; the `read -ra` split yields `*.sh`, `x?`. `cases2.log`: VT and FF → malformed.

**Evidence:** `scripts/build-loop.sh:155-168`, `glob.log`, `cases2.log`

---

## Claim 19: "a" and "a/" counted as the same entry ("none twice, a trailing / ignored")

**Location:** `scripts/build-loop.sh:164-166`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `a a/` (T45) and that keys `*` and `@` from a variable are not treated as array-wide subscripts (`a/ *`, `* a/` → set); does not establish equivalence of `a` and `a/**` or other glob-equivalent spellings (not deduplicated).

```bash
# scripts/build-loop.sh:165-166
          if [[ -n "${seen[${g%/}]-}" ]]; then why="lists entry $i twice"; break; fi
          seen[${g%/}]=1
```
**Evidence:** `scripts/build-loop.sh:162-167`, `cases2.log`, `bats.log`

---

## Claim 20: a self-merge policy with a malformed never line prints "policy review unset" and POLICY stays review

**Location:** `scripts/build-loop.sh:176-178`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers malformed-by-form and malformed-by-count never lines; does not establish U2's gate honouring POLICY.

```bash
# scripts/build-loop.sh:176-178
      if [[ "$v" == self-merge && -z "$never_ok" ]]; then
        POLICY_LINE="policy review unset: line ${first[policy]} reads self-merge, but the Self-merge never: line is malformed, so self-merge is off"
      else POLICY="$v"; POLICY_LINE="policy $v set: line ${first[policy]} $where"; fi
```
T45 asserts the exact line for 15 malformed values (`bats.log`); `cases2.log` repeats it.

**Evidence:** `scripts/build-loop.sh:150-179`, `bats.log`, `cases2.log`

---

## Claim 21: "the same hermetic git environment as test/scripts/dev-cycle.bats"

**Location:** `test/lib/build-loop-fixtures.bash:2-4`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers GIT_CONFIG_GLOBAL, GIT_CONFIG_NOSYSTEM, author/committer, HOME (identical to `test/scripts/dev-cycle.bats:10-15`); the fixture adds `LC_ALL=C`, which dev-cycle.bats's setup does not set.

```bash
# test/lib/build-loop-fixtures.bash:12-15
    export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
    export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.invalid
    export GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.invalid
    export HOME="$BATS_TEST_TMPDIR/home" LC_ALL=C
```
**Evidence:** `test/lib/build-loop-fixtures.bash:7-21`, `test/scripts/dev-cycle.bats:7-19`

---

## Claim 22: "settings LINE...: docs/dev-cycle.md holding these lines (printf %s\n each), committed. Pass no lines for an empty file."

**Location:** `test/lib/build-loop-fixtures.bash:26-28`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the no-argument case; no current test calls `settings` with no lines, so no test is affected today.

```bash
# test/lib/build-loop-fixtures.bash:28
settings() { mkdir -p docs && printf '%s\n' "$@" > docs/dev-cycle.md && commit_all settings; }
```
`printf '%s\n'` with no arguments still applies the format once: `cases3.log` shows the file is one byte, `\n` (one empty line), not empty. A later test using it for a 0-byte settings file would test a one-blank-line file instead.

**Evidence:** `test/lib/build-loop-fixtures.bash:26-28`, `cases3.log`

---

## Claim 23: "settings_is KEY WANT / settings_like KEY PREFIX: run --settings; its KEY line must equal WANT, or start with PREFIX. On a mismatch, print the whole output."

**Location:** `test/lib/build-loop-fixtures.bash:30-34`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the helpers' return value and failure print (stdout and stderr); does not establish that a mismatch fails the test in every call position — as the first operand of `&&` it does not (Claim 29b) — and the helpers do not check `$status`.

```bash
# test/lib/build-loop-fixtures.bash:33
settings_is() { run --separate-stderr bash "$BL" --settings; [ "$(line "$1")" = "$2" ] || { echo "want: $2"; echo "$output $stderr"; return 1; }; }
```
**Evidence:** `test/lib/build-loop-fixtures.bash:30-38`, `mutation.log`

---

## Claim 24: "Each test builds a throwaway repo under $BATS_TEST_TMPDIR ...; this repo is untouched. The lib it sources ... is also tested from dev-cycle.sh's side, in test/scripts/dev-cycle.bats."

**Location:** `test/scripts/build-loop-read.bats:3-6`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the write locations (all under `$R`/`$BATS_TEST_TMPDIR`; this repo is only read: `cp "$REPO_ROOT/docs/dev-cycle.md"`, `cp "$BL"`) and that dev-cycle.bats sources the lib directly; does not establish coverage depth of those lib tests.

`test/scripts/dev-cycle.bats:1037` `echo sourced' _ "$REPO_ROOT/scripts/lib/dev-cycle-read.sh"` and `:1054` `"$REPO_ROOT/scripts/lib/dev-cycle-read.sh" $check`.

**Evidence:** `test/scripts/build-loop-read.bats:1-11`, `test/scripts/dev-cycle.bats:1025-1064`

---

## Claim 25: test names T1, T2, T3, G19, T4, slots, T45, usage/exit, lib-from-own-directory describe what each test asserts

**Location:** `test/scripts/build-loop-read.bats:13`, `:24`, `:42`, `:69`, `:77`, `:87`, `:100`, `:134`, `:152`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each name against its assertions and a passing run; G19 matches this repo's `docs/dev-cycle.md:7` `Build-loop policy: review (interim; Q-103)`; does not establish the strength of the `&&`-chained assertions at `:80` and `:126` (Claim 29b) or the worktree discrimination (Claim 26).

`bats.log`: ok 1–9 under these names.

**Evidence:** `test/scripts/build-loop-read.bats:13-168`, `docs/dev-cycle.md:7`, `bats.log`

---

## Claim 26: "From a subdirectory and from a linked worktree, it reads the same main."

**Location:** `test/scripts/build-loop-read.bats:160`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers that the script runs and reports main's policy from `sub/` and from a linked worktree; does not establish that it reads main rather than those working trees there.

```bash
# test/scripts/build-loop-read.bats:161-162
    settings 'Build-loop policy: self-merge'
    git worktree add -q -b wt "$BATS_TEST_TMPDIR/wt" main && mkdir -p sub
```
The linked worktree is checked out from main and `sub/` sits in main's clean checkout, so main's commit and the working tree hold the same text at both locations; a reader of the working tree would pass too. The main-vs-working-tree distinction is tested only from the top level (T4). Precise version: "...it runs and finds the same main".

**Evidence:** `test/scripts/build-loop-read.bats:160-167`

---

## Claim 27: no-echo check covers plain-ASCII malformed entries (A3)

**Location:** `test/scripts/build-loop-read.bats:114-115`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the strings checked (`\xc3`, `../x`, `/etc`, `-x`, `./b`) over all 15 malformed values; does not establish non-echo of values not in that list (e.g. `a\tb`, `a b a`), though no malformed message interpolates `$v`.

```bash
# test/scripts/build-loop-read.bats:114
        [[ "$output" != *$'\xc3'* && "$output" != *../x* && "$output" != */etc* && "$output" != *-x* && "$output" != *./b* ]] \
```
**Evidence:** `test/scripts/build-loop-read.bats:106-116`, `scripts/build-loop.sh:158`, `scripts/build-loop.sh:164-169`

---

## Claim 28: "Bold, heading and emphasis copies count as second lines too."

**Location:** `test/scripts/build-loop-read.bats:119`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** True for the four tested forms, all with the colon inside the markup; does not hold for bold/emphasis closing before the colon (Claim 6b).

```bash
# test/scripts/build-loop-read.bats:120
    for c in '**Self-merge never:** b/' '## Self-merge never: b/' '_self-merge never: b/_' '`Self-merge never: b/`'; do
```
`cases2.log`: `**Self-merge never**: b/` is not counted (`never a/ set`). Precise version: "...copies with the colon inside the markup count".

**Evidence:** `test/scripts/build-loop-read.bats:119-123`, `cases2.log`

---

## Claim 29a: "U1b is 398 lines" (commit 0ae7d801)

**Location:** commit `0ae7d801` message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers changed code lines in the three code files over the unit diff; docs/reviews/ files excluded as review records.

`git diff --stat feat/build-loop-u1a...feat/build-loop-u1b -- scripts test` → 192 + 38 + 168 = 398 insertions (paraphrased — no quote available because this is command output, run in the worktree during this pass, exit 0).

**Evidence:** `scripts/build-loop.sh:1-192`, `test/lib/build-loop-fixtures.bash:1-38`, `test/scripts/build-loop-read.bats:1-168`

---

## Claim 29b: "No assertion was dropped" (commit 0ae7d801)

**Location:** commit `0ae7d801` message; `test/scripts/build-loop-read.bats:80`, `:126`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers `git diff 30676e57 0ae7d801 -- test/`: every comparison survives textually; does not establish that each still fails the test on its own — two do not.

Two former `[[ A && B ]] || { ...; return 1; }` checks became `settings_like A && settings_like B`:

```bash
# test/scripts/build-loop-read.bats:80
    settings_like policy "policy review set:" && settings_like slots "slots 3 default:"
# test/scripts/build-loop-read.bats:126
    settings_like never "never .github/ .gitignore set:" && settings_like policy "policy self-merge set:"
```
Neither is a test's last command, and bats' errexit/ERR trap ignores a failure in a non-final `&&` operand. `mutation.log` (copy `t1`): with the first operands changed to `"policy BOGUS"` and `"never BOGUS"`, T4 and T45 still pass. The regressions they target are still caught by the second operands (a working-tree read would also flip `slots`; a refused `.github/` would also unset the policy), so coverage is mostly kept, but the two literal assertions no longer fail anything.

**Evidence:** `test/scripts/build-loop-read.bats:77-85`, `test/scripts/build-loop-read.bats:124-126`, `mutation.log`

---

## Claim 30a: "A mutation check: without the IFS=' ' split, T45 fails on the tab cases" (commit 0ae7d801)

**Location:** commit `0ae7d801` message; `scripts/build-loop.sh:157`, `:161`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers three mutations of a scratch copy; does not establish what mutation the author actually ran.

`mutation.log`: m1 (only `IFS=' '` removed, explicit tab check kept) → T45 **passes** (exit 0); m2 (only the `*[$'\t\v\f\r']*` check removed) → passes; m3 (both removed) → T45 fails on `Self-merge never: a<TAB>b` (`never a	b set`). The explicit check at `:157` refuses every tab case before the split at `:161` runs, so the IFS split is not what T45's tab cases exercise:

```bash
# scripts/build-loop.sh:157
      if [[ "$t" != "Self-merge never: "* || "$v" == *[$'\t\v\f\r']* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]; then
```
(excerpt ends :157; enclosing read_settings() continues to :185 — read). Precise version: T45 fails only when both the explicit check and the IFS split are removed; each alone is redundant for T45.

**Evidence:** `scripts/build-loop.sh:155-168`, `mutation.log`

---

## Claim 30b: "the explicit tab test is a second guard (globform also refuses a tab inside an entry)" (commit 0ae7d801)

**Location:** commit `0ae7d801` message; `scripts/build-loop.sh:124`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the parenthetical: with the split on spaces only, a tab stays inside an entry and globform's character class refuses it (m2 passes); does not establish which guard is "first" — in code order the explicit check runs first (Claim 30a).

`mutation.log` m2: T45 passes with the explicit check removed.

**Evidence:** `scripts/build-loop.sh:122-129`, `mutation.log`

---

## Claim 31a: commit 30676e57's R1/A1, A3, A4, "a and a/", header and merge bullets

**Location:** commit `30676e57` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers: tab/VT/FF/CR refused and the IFS=' ' split (R1/A1); plain-ASCII no-echo checks (A3); `.github/ .gitignore` accepted via globform (A4); `a a/` a duplicate; Usage lists `-h`; a091d8fa (u1a's NUL fix) merged before it. The header wording it describes was later replaced by 0ae7d801's FENCE_AWK pointer (superseded, not stale: the message describes its own commit).

`scripts/build-loop.sh:7` `#        scripts/build-loop.sh -h | --help`; `git log` shows a091d8fa between 224dd52d and 30676e57. Remaining evidence as in Claims 4, 16, 18, 19, 27.

**Evidence:** `scripts/build-loop.sh:6-7`, `scripts/build-loop.sh:118-168`, `test/scripts/build-loop-read.bats:106-126`, `cases2.log`, `bats.log`

---

## Claim 31b: "A2: a bold, heading, emphasis or code-span copy of a key ... The key strip now also drops # * _ ` ~ and BOMs, so such a copy is a second line" (commit 30676e57)

**Location:** commit `30676e57` message; `scripts/build-loop.sh:106`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Same defect as Claim 6b; heading copies and mid-file BOM copies are counted (Verified part); bold, emphasis and code-span copies whose markup closes before the colon are not.

`cases2.log`/`cases1.log`: `**Build-loop policy**: review`, `*Build-loop policy*: review`, `` `Build-loop policy`: review ``, `__Build-loop policy__: review`, `**Self-merge never**: b/` all stay hidden. The fix strips leading marks only; the key match still needs `key:` contiguous.

**Evidence:** `scripts/build-loop.sh:106-110`, `cases1.log`, `cases2.log`

---

## Claim 32: "The wider key strip fails closed: a prose line starting "**Build-loop policy:**" now unsets the policy." (commit 30676e57)

**Location:** commit `30676e57` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both cases: alongside an exact line (count 2 → unset) and alone (counted, not exact → unset); "fails closed" holds only for prefixes the strip removes (Claim 6b).

`cases2.log`: `**Build-loop policy:** self-merge` alone → `policy review unset: line 1 is not exactly ...`; T2 covers it with a second exact line.

**Evidence:** `scripts/build-loop.sh:106-111`, `scripts/build-loop.sh:172-179`, `cases2.log`, `bats.log`

---

## Claim 33: "malformed, or a settings file that is not read, turns self-merge off and is never echoed" (commit 224dd52d)

**Location:** commit `224dd52d` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every `never malformed` message (none interpolates `$v` or the line text; they name line numbers and entry indexes); does not establish anything about the `set` line, which echoes validated globs by design.

```bash
# scripts/build-loop.sh:158,164,169
        why='is not exactly "Self-merge never: GLOB ..." with single spaces'
          if ! globform "${g%/}"; then why="lists entry $i, which is not an allowed glob form"; break; fi
      if [[ -n "$why" ]]; then NEVER_LINE="never malformed: line ${first[never]} $why"; never_ok=""
```
**Evidence:** `scripts/build-loop.sh:150-171`, `test/scripts/build-loop-read.bats:106-116`, `bats.log`

---

## Claim 34: "U1 is split three ways ...: U1a the lib, U1b --settings' settings-file lines, U1c the constraints line (T44) and --status" (commit 0797ed32)

**Location:** commit `0797ed32` message
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that this diff has no constraints line or --status (`--status` is a usage error, asserted in test 8); does not establish U1c's content.

```bash
# test/scripts/build-loop-read.bats:139
    for args in "" "--bogus" "--settings extra" "--status"; do
```
**Evidence:** `scripts/build-loop.sh:56-63`, `scripts/build-loop.sh:187-192`, `test/scripts/build-loop-read.bats:134-150`

---

## Claims Requiring Attention

### Incorrect
- **Claim 6b** (`scripts/build-loop.sh:30-31`): bold/emphasis/code-span copies with the markup closing before the colon (`**Build-loop policy**: review`, `**Self-merge never**: b/`) stay hidden; only colon-inside forms are counted.
- **Claim 22** (`test/lib/build-loop-fixtures.bash:27`): `settings` with no lines writes one newline, not an empty file.
- **Claim 30a** (commit 0ae7d801): removing `IFS=' '` alone leaves T45 passing; T45 fails only when the explicit tab check is removed too.
- **Claim 31b** (commit 30676e57, A2): the same hidden-copy gap as 6b; the bullet claims all bold/emphasis/code-span copies count.

### Stale
- None.

### Mostly Accurate
- **Claim 11** (`scripts/build-loop.sh:40-41`): exit list omits `-h` → 0.
- **Claim 14** (`scripts/build-loop.sh:73-77`): main_file also returns 1 on main_entry `error`, reported as "not a regular file".
- **Claim 26** (`test/scripts/build-loop-read.bats:160`): the subdirectory/worktree test cannot tell main from those working trees (same content).
- **Claim 28** (`test/scripts/build-loop-read.bats:119`): true only for colon-inside markup.
- **Claim 29b** (commit 0ae7d801; `test/scripts/build-loop-read.bats:80`, `:126`): the first operand of each `&&` line no longer fails the test (bogus expectations pass); companion assertions keep most coverage.

### Unverifiable
- None.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report in the code-fact-check schema saved at the path below, with `**Commit:** 0ae7d801` at the top, every claim tagged with a Legibility-target, and a Goal-Alignment Note at the end.
- Answered: yes
- Out of scope: U1c (constraints line T44, --status) and U2's use of POLICY/NEVER; the lib's FENCE_AWK shape list (context only); settled override-log rows (byte-exact wording, --graph output, `-h extra`) not re-raised.
- Escalate: Claim 6b/31b (a hidden bold-key copy, e.g. `**Build-loop policy**: review` beside an exact `Build-loop policy: self-merge`, leaves self-merge set) for security-reviewer; Claim 29b (non-final `&&` assertions are not enforced under bats) for the test-strategy view.
- Decisions I made: split 29 and 30 because their parts got different verdicts; rated 29b Mostly accurate rather than Incorrect because the regressions those two assertions target are still caught by their companion operands; rated 22 Incorrect though no current caller is affected, because the comment states a behaviour the code does not have; execution logs kept in the scratch dir because the pass rules allow writing only this report in the worktree; no hallucination-pattern entry (no fabricated symbol, and the log is in the worktree).
