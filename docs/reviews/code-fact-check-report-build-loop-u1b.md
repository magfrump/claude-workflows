Commit: 224dd52d

# Code Fact-Check Report

**Repository:** claude-workflows (worktree /workspace/.claude/wt-build-loop-u1b, branch feat/build-loop-u1b)
**Scope:** `git diff feat/build-loop-u1a...feat/build-loop-u1b` (commits 0797ed32, 224dd52d): scripts/build-loop.sh, test/lib/build-loop-fixtures.bash, test/scripts/build-loop-read.bats, plus both commit messages; lib scripts/lib/dev-cycle-read.sh read as context only
**Checked:** 2026-10-05
**Commit:** 224dd52d
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 29
**Summary:** 23 verified, 4 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable

Line numbers below are file lines (`cat -n`), not diff lines. Execution logs live in the reviewer's scratch dir, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b/fact-check/` (the pass rules allow writing only this report inside the worktree). Probes ran in a throwaway repo at `.../fact-check/probe1/r` with `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 HOME=.../fact-check/home LC_ALL=C`, each `bash scripts/build-loop.sh --settings` under `timeout 20`. Hallucination-pattern log read: no logged pattern matches any claim here.

---

## Claim 1: "It is set only when exactly one line, outside code fences, starts "Build-loop policy:" and reads exactly "Build-loop policy: self-merge" or "Build-loop policy: review" (one trailing CR is dropped)."

**Location:** `scripts/build-loop.sh:11-14`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the count-of-one rule, the byte-exact match on the whole raw line, fenced lines not counting, and the CR path end to end (one CR dropped, a second CR refuses the whole file); does not establish what a "line that starts" means beyond the prefix rule checked in Claim 9.

The CR is dropped by the first rule of SETTINGS_AWK, which runs before `fence()` because FENCE_AWK only defines functions (it has no pattern-action rules):

```awk
# scripts/build-loop.sh:99-100
{ sub(/\r$/, "") }
fence($0) { next }
```

`sub(/\r$/, "")` removes exactly one trailing CR; FENCE_AWK's stray-CR check then refuses any CR left in the line:

```awk
# scripts/lib/dev-cycle-read.sh:213
  if (index(l, "\r")) { refuse("cr"); return 1 }
```

So a CRLF file passes, and `\r\r` refuses the file. The stored text is the whole post-CR-strip line (`t[k] = $0`, `scripts/build-loop.sh:108`), matched by `[[ "${text[policy]}" =~ ^Build-loop\ policy:\ (self-merge|review)$ ]]` (`:158`) only when `cnt[policy]` is 1 (`:156-157`).

Executed. Command `bash scripts/build-loop.sh --settings` in `.../probe1/r` at 2026-10-05T10:53:29Z, one commit per case:
- `Build-loop policy: self-merge\r\n` → `policy self-merge set: line 1 ...`
- `Build-loop policy: self-merge\r\r\n` → `policy review unset: line 1 of docs/dev-cycle.md holds a carriage return that does not end it, so the file is not read` (slots and never lines carry the same reason)
- `x\r\nBuild-loop policy: review\r\n` → `policy review set: line 2 ...`

bats T1 (test 1) also passes (Claim 26).

**Evidence:** `scripts/build-loop.sh:99-114`, `scripts/build-loop.sh:156-163`, `scripts/lib/dev-cycle-read.sh:211-226`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b/fact-check/probe1.log`

---

## Claim 2: "Any other case, or a malformed never line, means review."

**Location:** `scripts/build-loop.sh:15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every branch of read_settings' policy block and the file-not-read branch, which all leave `POLICY=review`; does not establish the --status or gate modes' use of POLICY (U1c/U2).

`POLICY` starts as `review` (`scripts/build-loop.sh:118`: `POLICY=review; POLICY_LINE=""; ...`) and is assigned only at `:162`, `else POLICY="$v"; ...`, which is reached only after the exact match and only when not (`self-merge` with `never_ok` empty):

```bash
# scripts/build-loop.sh:160-162
      if [[ "$v" == self-merge && -z "$never_ok" ]]; then
        POLICY_LINE="policy review unset: line ${first[policy]} reads self-merge, but the Self-merge never: line is malformed, so self-merge is off"
      else POLICY="$v"; POLICY_LINE="policy $v set: line ${first[policy]} $where"; fi
```

`never_ok` is cleared on both malformed paths (`:138` two lines, `:153` bad text or glob). Executed: probe1 cases `.github/`, `a//`, `/`, `-x`, `a/./b`, `* *` each print `policy review unset: line 1 reads self-merge, but the Self-merge never: line is malformed, so self-merge is off`; bats T2 and T45 (tests 2 and 7) pass.

**Evidence:** `scripts/build-loop.sh:118`, `scripts/build-loop.sh:136-163`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b/fact-check/probe1.log`

---

## Claim 3: "How many build loops may run at once: one line "Build-loop slots: N" with N from 1 to 9, else 3."

**Location:** `scripts/build-loop.sh:17-18`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the count-of-one rule, the exact single-digit match and the default of 3 on every other path (including a file not read); does not establish any consumer of the slots value (none exists in this unit: only SLOTS_LINE is set, no SLOTS variable).

```bash
# scripts/build-loop.sh:164-167
    if [[ -z "${cnt[slots]-}" ]]; then SLOTS_LINE='slots 3 default: no line starts "Build-loop slots:"'
    elif [[ "${cnt[slots]}" -gt 1 ]]; then SLOTS_LINE="slots 3 default: $(many 'Build-loop slots:' slots)"
    elif [[ "${text[slots]}" =~ ^Build-loop\ slots:\ ([123456789])$ ]]; then SLOTS_LINE="slots ${BASH_REMATCH[1]} set: line ${first[slots]} $where"
    else SLOTS_LINE="slots 3 default: line ${first[slots]} is not exactly \"Build-loop slots: N\" with N from 1 to 9"; fi
```

The not-read branch sets `SLOTS_LINE="slots 3 default: $why"` (`:126`). Executed via bats test 6 (0, 10, `3 `, `05`, `three`, two lines, fenced), which passes.

**Evidence:** `scripts/build-loop.sh:126`, `scripts/build-loop.sh:164-167`, `test/scripts/build-loop-read.bats:105-120`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b/fact-check/bats-build-loop-read.log`

---

## Claim 4a: "Self-merge never: GLOB ..." (single spaces; ...)

**Location:** `scripts/build-loop.sh:21`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the separator check and the split of the value; does not establish how a later gate (U2) splits NEVER, which decides whether a tab-joined value protects the paths it names.

The separator regex excludes only the space character, so a tab passes it, and `read -ra` then splits on the default IFS (space, tab, newline):

```bash
# scripts/build-loop.sh:140-146 (excerpt ends :146; the loop and its if continue to :155 — read)
      t="${text[never]}"; v="${t#Self-merge never: }"; why=""
      if [[ "$t" != "Self-merge never: "* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]; then
        why='is not exactly "Self-merge never: GLOB ..." with single spaces'
      else
        i=0
        read -ra parts <<<"$v"  # not a bare $v: the shell would expand * and ? against files
        for g in "${parts[@]}"; do
```

On success `NEVER="$v"` stores the raw value, tabs included (`:154`). Executed (probe1, 2026-10-05T10:53:29Z), each with `Build-loop policy: self-merge` on line 1:
- `Self-merge never: a\tb` → `never a^Ib set: line 2 ...` and `policy self-merge set`
- `Self-merge never: \ta` → `never ^Ia set`
- `Self-merge never: a\t\tb` → `never a^I^Ib set`
- `Self-merge never: a\t` → `never a^I set` (while `Self-merge never: a ` with a trailing space is malformed)

So tabs, runs of tabs, and a leading or trailing tab are all accepted, and self-merge stays on. A reader of "single spaces" would expect each of these lines to be malformed and turn self-merge off.

**Evidence:** `scripts/build-loop.sh:140-155`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b/fact-check/probe1.log`

---

## Claim 4b: "each glob uses letters, digits, . _ - / * ?, with an optional trailing /; no . or .. part, ... not starting / or -"

**Location:** `scripts/build-loop.sh:21-23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the character set (ASCII letters only), the one stripped trailing `/`, the `.`/`..` and leading `/`/`-` rules; does not establish the `.git` atom (Claim 4c) or that empty parts (`a//`) are refused, which the header does not mention but the code does.

The check is `pathform "${g%/}" glob` (`scripts/build-loop.sh:148`), which strips one trailing `/` and applies:

```bash
# scripts/lib/dev-cycle-read.sh:140-147
  local p="$1" rest c set="^[$NAMECHARS]+\$"
  [[ "${2:-}" == glob ]] && set="^[*?$NAMECHARS]+\$"  # * ? first: - must stay last
  [[ "$p" =~ $set && "$p" != /* && "$p" != -* ]] || return 1
  rest="$p/"
  while [[ -n "$rest" ]]; do
    c="${rest%%/*}"; rest="${rest#*/}"
    [[ -n "$c" && "$c" != "." && "$c" != ".." && "$c" != [.][gG][iI][tT]* ]] || return 1
  done
```

`NAMECHARS` lists ASCII letters, digits and `._/-` one by one (`:138`). Executed: `A1._-/x?*` → set; `a//`, `/`, `-x`, `a/./b` → `lists entry 1, which is not an allowed glob form`; bats test 7 covers `../x`, `a/../b`, `/etc` and `café/`. `*` and `**` alone are accepted (`never * set`, `never ** set`), which is consistent with the stated character set.

**Evidence:** `scripts/build-loop.sh:148`, `scripts/lib/dev-cycle-read.sh:138-148`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b/fact-check/probe1.log`

---

## Claim 4c: "no .git"

**Location:** `scripts/build-loop.sh:23`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers which path parts the glob rule refuses; does not establish whether refusing `.github/` was intended (the lib's own comment says "no component starting .git (any case)").

The rule refuses any part that starts with `.git` in any case, not just a part equal to `.git`: `"$c" != [.][gG][iI][tT]*` (`scripts/lib/dev-cycle-read.sh:146`), which the lib documents as "no component starting .git (any case)" (`scripts/lib/dev-cycle-read.sh:129`). Executed (probe1), each with `Build-loop policy: self-merge`:
- `Self-merge never: .github/` → `never malformed: line 2 lists entry 1, which is not an allowed glob form`, and `policy review unset ... so self-merge is off`
- `Self-merge never: .gitignore` → malformed, the same
- `Self-merge never: .GIT/x` → malformed (so case-insensitive refusal holds)

A reader of "no .git" who lists `.github/` (a common path to keep out of self-merge) gets a malformed line, and self-merge turns off for the whole repo. The precise wording is "no part starting .git, in any case (.github and .gitignore included)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:129`, `scripts/lib/dev-cycle-read.sh:146`, `scripts/build-loop.sh:148`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b/fact-check/probe1.log`

---

## Claim 4d: "none twice"

**Location:** `scripts/build-loop.sh:23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers byte-identical entries only, `*` included; does not establish that two entries naming the same path in different spellings are refused (`a` and `a/` are both accepted).

```bash
# scripts/build-loop.sh:149-150
          if [[ -n "${seen[$g]-}" ]]; then why="lists entry $i twice"; break; fi
          seen[$g]=1
```

`seen` is keyed on the raw entry `$g`, before the trailing-slash strip used for `pathform`. Executed (probe1): `Self-merge never: a a/` → `never a a/ set`; `Self-merge never: * *` → `never malformed: line 2 lists entry 2 twice`; `Self-merge never: a *` → `never a * set` (so a `*` key does not collide with the associative array's all-elements subscript). bats test 7's `a b a` → malformed.

**Evidence:** `scripts/build-loop.sh:146-151`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b/fact-check/probe1.log`

---

## Claim 5: "A malformed line, or a settings file that is not read, turns self-merge off."

**Location:** `scripts/build-loop.sh:24-25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the not-read paths (non-regular, non-plain directory, FENCE_AWK refusal), which print `never malformed` and `policy review unset`, and the absent-file path, which prints `never none` but still has no policy line; does not establish the gate's use of these values.

```bash
# scripts/build-loop.sh:124-128 (excerpt ends :128; the else branch continues to :168 — read)
  if ! main_file "$f" "$SETTINGS_AWK"; then
    [[ "$FILE_WHY" == absent ]] && why="no $f on the default branch" || why="$FILE_WHY"
    POLICY_LINE="policy review unset: $why"; SLOTS_LINE="slots 3 default: $why"
    # An absent file sets nothing; one that is not read turns self-merge off.
    if [[ "$FILE_WHY" == absent ]]; then NEVER_LINE="never none: $why"; else NEVER_LINE="never malformed: $why"; fi
```

An absent file is not "a file that is not read" in this sense: it gives `never none`, but the policy is `review unset` on that path too, so self-merge is off either way. Executed by bats test 3 (open comment → `never malformed: ... so the file is not read`; missing → `never none: no docs/dev-cycle.md on the default branch`) and the `\r\r` probe.

**Evidence:** `scripts/build-loop.sh:124-128`, `test/scripts/build-loop-read.bats:45-81`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b/fact-check/probe1.log`

---

## Claim 6: "A line counts as a settings line when it starts with the key (any case) after any blanks, > and list markers, so a quoted or indented copy is a second line, not a hidden one."

**Location:** `scripts/build-loop.sh:26-28`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers blanks (space, tab), `>`, `-`/`*`/`+` and `N.`/`N)` list markers, nested `> - `, and case; does not establish that every copy a reader sees is counted: a copy in bold (`**Build-loop policy:** ...`), in a heading (`## Build-loop policy: ...`), or after a BOM on a line other than 1 is not counted (it stays hidden), and a counted indented line is judged on its whole raw text, so it is never set.

```awk
# scripts/build-loop.sh:102-108
  s = $0
  if (match(s, /^([ \t>]|[-*+][ \t]|[0123456789]+[.)][ \t])*/)) s = substr(s, RLENGTH + 1)
  s = tolower(s); k = ""
  if (index(s, "build-loop policy:") == 1) k = "policy"
  else if (index(s, "build-loop slots:") == 1) k = "slots"
  else if (index(s, "self-merge never:") == 1) k = "never"
  if (k != "") { c[k]++; if (c[k] == 1) { l1[k] = NR; t[k] = $0 } else if (c[k] == 2) l2[k] = NR }
```

Executed (probe2, 2026-10-05T10:53:51Z), each after `Build-loop policy: review` on line 1: `1. `, `1) `, a leading tab, `> - `, and `>` with no space each give `more than one line starts "Build-loop policy:" (lines 1 and 2)`. `-Build-loop ...` (not a list marker), `**Build-loop policy:** self-merge` and `## Build-loop policy: self-merge` are not counted (`policy review set: line 1`). A lone `  Build-loop policy: review` or `- Build-loop policy: review` gives `line 1 is not exactly ...` (counted, then refused on the whole raw line `t[k] = $0`). `x\n\xef\xbb\xbfBuild-loop policy: self-merge` gives `no line starts "Build-loop policy:"`: a BOM on line 2 hides the line rather than refusing the file. Every hidden case fails toward the counted line, not toward self-merge, unless the hidden copy was meant to override it.

**Evidence:** `scripts/build-loop.sh:101-109`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b/fact-check/probe2.log`

---

## Claim 7: "A file the reader cannot trust (a fence never closed or not in plain column-0 form, a line starting with < other than a one-line <!-- comment -->, an open <!--, a line like a link reference definition, a stray CR, a byte-order mark; see FENCE_AWK in the lib) is not read at all."

**Location:** `scripts/build-loop.sh:28-33`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers that each listed condition exists in FENCE_AWK and refuses the whole file; does not establish that these are refused everywhere: the `<`, open-comment and refdef checks apply only outside a fence, and the BOM check only on line 1.

Each condition is in `fence()`:

```awk
# scripts/lib/dev-cycle-read.sh:213-224 (excerpt ends :224; fence() continues to :226 — read)
  if (index(l, "\r")) { refuse("cr"); return 1 }
  if (NR == 1 && substr(l, 1, 3) == "\357\273\277") { refuse("bom"); return 1 }
  if (infence) {
    if (closes(l)) infence = 0
    else if (fenceish(l) && substr(l, 1, 1) != "`" && substr(l, 1, 1) != "~") refuse("fence")
    return 1
  }
  if (opens(l)) { infence = 1; fline = NR; return 1 }
  if (fenceish(l)) { refuse("fence"); return 1 }
  if (rawhtml(l)) { refuse("html"); return 1 }
  if (opencomment(l)) { refuse("comment"); return 1 }
  if (refdef(l)) { refuse("refdef"); return 1 }
```

and a fence open at the end prints `unbalanced` (SETTINGS_AWK `END`, `scripts/build-loop.sh:112`). The pointer "see FENCE_AWK in the lib" resolves. The missing qualifiers: the BOM check is `NR == 1` only, so a BOM elsewhere does not refuse the file (probe2: `x\xef\xbb\xbf` on line 2 → `policy review set`, and a BOM before a key on line 2 hides it, see Claim 6); `<` lines inside a fence are fenced content and not refused (probe2: a fenced `<x>` → `policy review set`); "starting with <" also holds after blanks (probe2: `  <x>` refused). Precise version: "... a line starting (after blanks, outside a fence) with < ..., a byte-order mark on line 1".

**Evidence:** `scripts/lib/dev-cycle-read.sh:184-227`, `scripts/build-loop.sh:110-114`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b/fact-check/probe2.log`

---

## Claim 8: "Acts on $PWD's git repo, like dev-cycle.sh, and needs its default branch found by name (origin/HEAD, main or master). Read-only: writes nothing."

**Location:** `scripts/build-loop.sh:35-36`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the repo resolved from the current directory (subdirectory and linked worktree included), the by-name requirement and that a run leaves the repo's status unchanged; does not establish that git itself never writes (for example lock or index refresh), which the commands used (rev-parse, ls-tree, cat-file, show-ref, symbolic-ref) do not do.

```bash
# scripts/build-loop.sh:63-69
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Not inside a git repository" >&2; exit 1; }
cd "$ROOT"
# shellcheck disable=SC2034  # read by the lib's file rules
ROOT_REAL="$(pwd -P)"
export GIT_LITERAL_PATHSPECS=1
resolve_main || true
main_by_name || { echo "build-loop.sh needs a default branch found by name (origin/HEAD, main or master); found none" >&2; exit 1; }
```

`resolve_main` takes origin/HEAD's short name and looks it up as a local `refs/heads/<name>`, then main, then master (`scripts/lib/dev-cycle-read.sh:371-381`). Executed: bats test 8 (renamed `main` → `trunk` exits 1 with "needs a default branch") and test 9 (subdirectory and linked worktree) pass; probe3 (2026-10-05T10:54:19Z, cwd `.../probe1/r/sub`, `bash <relative path>/build-loop.sh --settings`, exit 0) left `git status --porcelain` empty.

**Evidence:** `scripts/build-loop.sh:63-69`, `scripts/lib/dev-cycle-read.sh:368-390`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b/fact-check/probe3.log`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b/fact-check/bats-build-loop-read.log`

---

## Claim 9: "Output passes through the lib's scrub; printed repo text is data."

**Location:** `scripts/build-loop.sh:37`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers everything printed after `scrub_reexec` (all usage, error and --settings output); does not establish scrubbing of the two messages printed before the lib is sourced.

`scrub_reexec "${BASH_SOURCE[0]}" "$@"` (`scripts/build-loop.sh:52`) re-runs the script with both streams piped through `scrub` (`scripts/lib/dev-cycle-read.sh:75-80`). Two messages come earlier and are not scrubbed: `echo "build-loop.sh needs perl (to scrub its output)" >&2` (`:43`) and `echo "build-loop.sh needs $READ_LIB" >&2` (`:49`). Neither carries repo text (`$READ_LIB` comes from the script's own location), so "printed repo text is data" holds; "Output passes through the lib's scrub" needs "after the lib loads".

**Evidence:** `scripts/build-loop.sh:43-52`, `scripts/lib/dev-cycle-read.sh:75-80`

---

## Claim 10: "Exit: 0 every line printed; 1 bad usage, not a git repo, no perl or lib/dev-cycle-read.sh, or no default branch found by name."

**Location:** `scripts/build-loop.sh:38-39`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each listed exit-1 path and the exit-0 path; does not establish exit codes under unexpected git failures under `set -e` (not reached in any probe), nor the perl-missing path, which was read but not run.

`usage()` exits 1 (`:54`); not a repo, no default branch (`:63`, `:69`); no perl (`:43`); no lib (`:49`); `scrub_reexec` exits with the child's status via `exit "${PIPESTATUS[0]}"` (`scripts/lib/dev-cycle-read.sh:79`). Executed: bats test 8 (`""`, `--bogus`, `--settings extra`, `--status` → 1 with empty stdout; no default branch → 1; outside a repo → 1) and test 9 (copy without lib → 1) pass; probe2: `--settings x` → exit 1, `--settings takes no arguments (usage: build-loop.sh --settings)`. `-h`/`--help` exit 0 but are not listed (they print no settings lines); `-h extra` also exits 0 (probe2), and `-h` works outside a repo (exit 0, probe2).

**Evidence:** `scripts/build-loop.sh:43-69`, `test/scripts/build-loop-read.bats:150-183`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b/fact-check/probe2.log`

---

## Claim 11: "before the cd: relative paths work"

**Location:** `scripts/build-loop.sh:44`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers SCRIPT_DIR and the scrub_reexec re-run both resolving a relative script path before `cd "$ROOT"` (`:64`); does not establish behaviour when the script is reached through a symlink (`pwd`, not `pwd -P`, so the lib is looked up next to the link).

`SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` (`:44`) and `scrub_reexec "${BASH_SOURCE[0]}" "$@"` (`:52`) both run before `cd "$ROOT"` (`:64`). Executed: probe3 ran `bash ../../../../../../../../../../../workspace/.claude/wt-build-loop-u1b/scripts/build-loop.sh --settings` from `.../probe1/r/sub` (a subdirectory, so the later cd changes the directory) at 2026-10-05T10:54:19Z; it printed three lines and exited 0.

**Evidence:** `scripts/build-loop.sh:44-64`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b/fact-check/probe3.log`

---

## Claim 12: "The reader shared with dev-cycle.sh, from this script's own directory (never the target repo's scripts/lib/), so a copy of scripts/ with its lib/ is self-contained."

**Location:** `scripts/build-loop.sh:45-47`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the lib path being `$SCRIPT_DIR/lib/dev-cycle-read.sh` and a planted target-repo lib not running; does not establish the D6 hash check of the lib (U3b, override-log row 200).

`READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"` (`:48`), `source "$READ_LIB"` (`:51`). Executed: bats test 9 plants `scripts/lib/dev-cycle-read.sh` printing `PLANTED` in the target repo and asserts it never appears, and a copy of the script without `lib/` exits 1 naming the missing path; the test passes.

**Evidence:** `scripts/build-loop.sh:45-51`, `test/scripts/build-loop-read.bats:168-184`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b/fact-check/bats-build-loop-read.log`

---

## Claim 13: `-h|--help) sed -n '2,39p' "$0"` prints the header

**Location:** `scripts/build-loop.sh:58`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers lines 2-39 being the whole comment header (line 40 is blank, line 41 is `set -euo pipefail`); does not establish that -h is documented (the Usage line names only --settings) or that extra arguments after -h are refused (they are ignored).

Line 39 is `# lib/dev-cycle-read.sh, or no default branch found by name.`, the header's last line. Executed (probe2): `-h`, `--help` and `-h extra` each exit 0 with 38 lines, first `The build-loop handoff's state and checks: ...`, last `lib/dev-cycle-read.sh, or no default branch found by name.` This matches dev-cycle.sh's form (`sed -n '2,80p'`, `scripts/dev-cycle.sh:110`).

**Evidence:** `scripts/build-loop.sh:1-41`, `scripts/build-loop.sh:58`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b/fact-check/probe2.log`

---

## Claim 14: main_file's comment ("sets FILE_WHY and returns 1 when it is absent ("absent"), stored as anything but a regular file under plain directories, or refused by FENCE_AWK; otherwise FILE_OUT holds what the awk program $2 printed ...")

**Location:** `scripts/build-loop.sh:71-75`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the four return-1 paths, the literal `absent` value and FILE_OUT on success; does not establish main_entry's preconditions (main_by_name and pathform), which hold here because the caller exits at `:69` and the path is the constant `docs/dev-cycle.md`.

```bash
# scripts/build-loop.sh:80-91
  e="$(main_entry "$f")"
  case "$e" in
    blob) ;;
    absent) FILE_WHY=absent; return 1 ;;
    notdir\ *) FILE_WHY="${e#notdir } is not a directory on the default branch"; return 1 ;;
    *) FILE_WHY="$f is not a regular file on the default branch"; return 1 ;;
  esac
  FILE_OUT="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk "$FENCE_AWK$2")"
  case "$FILE_OUT" in
    odd\ *) read -r _ n why <<<"$FILE_OUT"; FILE_WHY="line $n of $f $(oddwhy "$why"), so the file is not read"; return 1 ;;
    unbalanced\ *) FILE_WHY="the code fence opened at line ${FILE_OUT#unbalanced } of $f is never closed, so the file is not read"; return 1 ;;
  esac
```

SETTINGS_AWK's output lines start with `policy`, `slots` or `never`, so they cannot be mistaken for `odd ` or `unbalanced `. bats test 3 executes every path (symlink and directory → "is not a regular file", symlinked `docs` → "docs is not a directory", open comment, unclosed fence, missing).

**Evidence:** `scripts/build-loop.sh:71-92`, `scripts/lib/dev-cycle-read.sh:251-261`, `test/scripts/build-loop-read.bats:45-81`

---

## Claim 15: "One pass over docs/dev-cycle.md: per key, how many lines start with it (...), the first two line numbers and the first line whole: "KEY COUNT FIRST SECOND<TAB>LINE"."

**Location:** `scripts/build-loop.sh:94-96`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the output format and its parse at `:130-134`; does not establish key order (awk's `for (k in c)` order is unspecified; the reader is order-independent).

`print k " " c[k] " " l1[k] " " (k in l2 ? l2[k] : 0) "\t" t[k]` (`:113`), with `t[k] = $0` taken after the CR drop (`:99`, `:108`). The reader splits at the first tab (`read -r k c l1 l2 <<<"${l%%$'\t'*}"` and `text[$k]="${l#*$'\t'}"`, `:132-133`); the first tab is always the separator, because the fields before it hold no tabs, so a tab inside the line text survives (Claim 4a's probes show it).

**Evidence:** `scripts/build-loop.sh:98-114`, `scripts/build-loop.sh:130-134`

---

## Claim 16: "Sets POLICY, POLICY_LINE, SLOTS_LINE, NEVER (the globs, or empty) and NEVER_LINE from main's commit. POLICY and NEVER are for the modes that judge a brief (--status, then the gate)."

**Location:** `scripts/build-loop.sh:115-117`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the globals assigned and that POLICY/NEVER have no reader yet in this unit (hence the SC2034 disable at `:119`); does not establish that a second call resets POLICY and NEVER (the not-read branch leaves them at their `:118` initial values), which holds only for the single call made at `:173`.

POLICY is assigned only at `:162`, NEVER only at `:154` (`NEVER="$v"`), the three *_LINE variables on every path. `NEVER` holds the raw value, so with a tab separator it holds the tab (Claim 4a). The forward reference to --status and the gate is a plan statement (U1c, U2), not checkable here.

**Evidence:** `scripts/build-loop.sh:115-169`

---

## Claim 17: "An absent file sets nothing; one that is not read turns self-merge off."

**Location:** `scripts/build-loop.sh:127`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the NEVER_LINE split on `FILE_WHY == absent`; does not establish anything beyond Claim 5, which quotes the same lines.

See Claim 5's quote of `scripts/build-loop.sh:124-128`. bats test 3 asserts `never none: no docs/dev-cycle.md on the default branch` for the missing file and `never malformed: ...` for the open comment.

**Evidence:** `scripts/build-loop.sh:124-128`, `test/scripts/build-loop-read.bats:54-56`, `test/scripts/build-loop-read.bats:64-67`

---

## Claim 18: "Self-merge never: first, because a malformed line turns self-merge off."

**Location:** `scripts/build-loop.sh:136`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the ordering dependency (`never_ok` is set before the policy block reads it at `:160`); does not establish more than Claim 2.

The never block (`:137-155`) clears `never_ok` before the policy block tests `-z "$never_ok"` (`:160`).

**Evidence:** `scripts/build-loop.sh:136-162`

---

## Claim 19: "not a bare $v: the shell would expand * and ? against files"

**Location:** `scripts/build-loop.sh:145`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers why `read -ra` replaces an unquoted `$v` (pathname expansion; `set -f` is not used); does not establish that `read -ra` splits only on spaces: it also splits on tabs, which is the cause of Claim 4a.

`set -euo pipefail` (`:41`) does not include `-f`, so an unquoted `for g in $v` would glob `*` and `?` against the repo root. `read -ra parts <<<"$v"` (`:145`) performs no pathname expansion.

**Evidence:** `scripts/build-loop.sh:41`, `scripts/build-loop.sh:145`

---

## Claim 20: "malformed globs are never echoed" (design context; commit 224dd52d: "malformed, or a settings file that is not read, ... is never echoed")

**Location:** `scripts/build-loop.sh:137-155`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every NEVER_LINE and POLICY_LINE string (line numbers, entry indexes, fixed text, `$f`, oddwhy text only) and the set line, which echoes only characters pathform allowed plus spaces and tabs (none of which scrub alters); does not establish that the set line equals what a later gate will match (tabs, Claim 4a).

Malformed texts: `why='is not exactly "Self-merge never: GLOB ..." with single spaces'` (`:142`), `"lists entry $i, which is not an allowed glob form"` (`:148`), `"lists entry $i twice"` (`:149`), `many()`'s line numbers (`:135`); the not-read branch uses FILE_WHY, built from `$f` and `oddwhy` (`scripts/build-loop.sh:84-90`). Only the set line echoes repo text, `NEVER_LINE="never $v set: ..."` (`:154`), after every entry passed `pathform` (ASCII `[*?$NAMECHARS]`) and the separator regex; scrub keeps TAB. Executed: probe1's malformed cases print no entry text; bats test 7 passes.

**Evidence:** `scripts/build-loop.sh:84-90`, `scripts/build-loop.sh:135-163`, `scripts/lib/dev-cycle-read.sh:47-64`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b/fact-check/probe1.log`

---

## Claim 21: "a throwaway repo under $BATS_TEST_TMPDIR with a main branch, the same hermetic git environment as test/scripts/dev-cycle.bats"

**Location:** `test/lib/build-loop-fixtures.bash:2-4`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the git environment variables and HOME, which match dev-cycle.bats' setup; does not establish an identical setup overall: the fixture also exports `LC_ALL=C` and makes one empty commit, without dev-cycle.bats' f1-f3 merge history.

Fixture: `export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`, `GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.invalid`, the same for COMMITTER, `export HOME="$BATS_TEST_TMPDIR/home" LC_ALL=C` (`test/lib/build-loop-fixtures.bash:12-15`). dev-cycle.bats: the same four git lines and `export HOME="$BATS_TEST_TMPDIR/home"` (`test/scripts/dev-cycle.bats:11-15`), with `make_repo` adding three merged feature branches (`:22-35`).

**Evidence:** `test/lib/build-loop-fixtures.bash:7-20`, `test/scripts/dev-cycle.bats:8-35`

---

## Claim 22: "Each test builds a throwaway repo under $BATS_TEST_TMPDIR (...); this repo is untouched. The lib it sources ... is also tested from dev-cycle.sh's side, in test/scripts/dev-cycle.bats."

**Location:** `test/scripts/build-loop-read.bats:3-6`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `setup() { bl_setup; }` creating and cd-ing into `$BATS_TEST_TMPDIR/repo` and no test writing outside `$BATS_TEST_TMPDIR`; does not establish dev-cycle.bats' coverage of the lib beyond its existence.

`bl_setup` runs `mkdir -p "$R" && cd "$R" || return 1` with `R="$BATS_TEST_TMPDIR/repo"` (`test/lib/build-loop-fixtures.bash:16-17`); test 4 only reads `$REPO_ROOT/docs/dev-cycle.md` (`cp "$REPO_ROOT/docs/dev-cycle.md" docs/`). dev-cycle.bats sources the lib in its own tests (`test/scripts/dev-cycle.bats:1030`, `source "$1"`).

**Evidence:** `test/lib/build-loop-fixtures.bash:7-20`, `test/scripts/build-loop-read.bats:11`, `test/scripts/build-loop-read.bats:83-89`

---

## Claim 23: test names' T/G numbers ("(T1)", "(T2)", "(T3)", "(T3, G19)", "(T4)", "(T1-T3 slots)", "(T45)")

**Location:** `test/scripts/build-loop-read.bats:13-122`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each name against rev 2's T1-T4 rows and rev 4's T1-T3 slots and T45 rows, and each test asserting what its name says; does not establish T45's gate half (`workflows/x.md` refused under self-merge), which the plan puts in U2's build-loop-check.bats, or the plan's "on failure, print `git log --oneline --graph --all`", which no test does.

Rev 2 (`git show 3a005378:docs/working/plan-build-loop-handoff.md`, lines 158-161): T1 "Policy exact self-merge/review, each with a trailing CR" matches test 1; T2 "interim suffix, case, trailing space, two lines, none, a one-line <!-- --> holding the line" matches test 2; T3 "fence; open <!--; BOM; missing, a symlink, a directory or only in the working tree; real docs/dev-cycle.md (G7, G19)" is split across tests 3 and 4; T4 "Working tree self-merge vs commit review, and vice versa" matches test 5 (both directions). Rev 4: `| T1–T3 | ... plus Build-loop slots: 0, 10, 3 , two lines, in a fence |` matches test 6; `| T45 | ... two lines, a bad glob or .. → malformed, self-merge off; the line raised only on the loop's branch → ignored |` matches test 7's settings half. Plan step for U1 tests lists T45 under U2 (`4. **U2 tests**: T9–T18, T20, T26, T27, T45 in build-loop-check.bats`). G19 (docs/reviews/test-strategy-build-loop-handoff.md:36): the real file holds `Build-loop policy: review (interim; Q-103)` on line 7, which test 4 asserts as unset.

**Evidence:** `test/scripts/build-loop-read.bats:13-148`, `docs/working/plan-build-loop-handoff.md:269-271`, `docs/working/plan-build-loop-handoff.md:316-341`, `docs/dev-cycle.md:7`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b/fact-check/plan-rev2.md`

---

## Claim 24: Commit 0797ed32: "Failing tests for build-loop.sh --settings ... Self-merge never: (one line of allowed globs; malformed turns self-merge off; never echoed) ... the lib sourced from the script's own directory (G16), from a subdirectory and from a linked worktree (G20)."

**Location:** commit 0797ed32 message
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers "failing" (no scripts/build-loop.sh at 0797ed32), the G16/G20 cases and the "never echoed" test; does not establish G20's --check/--merge cases (later units).

`git ls-tree 0797ed32 scripts/build-loop.sh` prints nothing, so every test failed at that commit. G16 and G20's subdirectory and worktree cases are in test 9 (`for d in sub "$BATS_TEST_TMPDIR/wt"; do`). The "never echoed" part is asserted by one check, `[[ "$output" != *$'\xc3'* ]]` (`test/scripts/build-loop-read.bats:137`). It runs for every malformed value but can only fail for the one holding `\xc3` (`caf\xc3\xa9/`); for `../x`, `/etc`, `.git/x` and the rest, no assertion checks that the entry is absent from the output. Precise version: "never echoed (checked for a non-ASCII entry)".

**Evidence:** `test/scripts/build-loop-read.bats:122-148`, `test/scripts/build-loop-read.bats:168-184`

---

## Claim 25: Commit 224dd52d: "exactly one unfenced "Build-loop policy:" line, byte-exact; anything else is review"

**Location:** commit 224dd52d message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the byte-exact atom; does not establish anything about the other atoms, which Claim 26 covers.

The match is byte-exact after one trailing CR is dropped (`sub(/\r$/, "")`, `scripts/build-loop.sh:99`; probe1: `Build-loop policy: self-merge\r\n` → set). The script header (`:14`) and plan F1 ("byte-exact after one trailing CR") carry that qualifier; the commit message does not.

**Evidence:** `scripts/build-loop.sh:99`, `scripts/build-loop.sh:158`, `docs/working/plan-build-loop-handoff.md:116`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b/fact-check/probe1.log`

---

## Claim 26: Commit 224dd52d: "The file goes through main_entry and FENCE_AWK first. The script sources the lib from its own directory, scrubs its output, and exits 1 on bad usage or without a default branch found by name." / "A policy of self-merge with a malformed never line prints "policy review unset", so the policy line always shows the policy in force." / bats: 9 tests pass

**Location:** commit 224dd52d message; `test/scripts/build-loop-read.bats`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers main_file's order (main_entry `:80`, then the FENCE_AWK-prefixed awk `:87`), lib sourcing (Claim 12), scrub (Claim 9), the exit-1 paths named (Claim 10, which lists more) and POLICY_LINE matching POLICY on every branch; does not establish dev-cycle.bats' 64 tests, which this pass did not run.

Every POLICY_LINE assignment that reads "set" is paired with `POLICY="$v"` (`:162`), and every "unset" one leaves POLICY at `review` (Claim 2). bats run: `export LC_ALL=C.UTF-8; timeout 300 bats test/scripts/build-loop-read.bats`, cwd `/workspace/.claude/wt-build-loop-u1b`, 2026-10-05T10:52:41Z, exit 0, `1..9` and `ok 1` to `ok 9`.

**Evidence:** `scripts/build-loop.sh:77-92`, `scripts/build-loop.sh:156-163`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b/fact-check/bats-build-loop-read.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4a** (`scripts/build-loop.sh:21`): "single spaces" is not enforced. The regex `[^\ ]` and `read -ra` let tabs through as separators, and leading or trailing tabs too; `Self-merge never: a<TAB>b` prints `never a<TAB>b set` and keeps self-merge on. Either refuse tabs, or reword the header.
- **Claim 4c** (`scripts/build-loop.sh:23`): "no .git" understates the rule. Any part starting `.git` in any case is refused, so `.github/` and `.gitignore` make the line malformed and turn self-merge off. Reword as "no part starting .git (any case)".

### Stale
- none

### Mostly Accurate
- **Claim 7** (`scripts/build-loop.sh:28-33`): the BOM refusal applies to line 1 only, and the `<`/comment/refdef refusals apply only outside a fence and after blanks. A BOM before a key on line 2 hides that line instead of refusing the file.
- **Claim 9** (`scripts/build-loop.sh:37`): the perl and lib messages (`:43`, `:49`) print before scrub_reexec; neither carries repo text.
- **Claim 24** (commit 0797ed32): the "never echoed" assertion can fail only for the `café/` entry; no test checks that the other malformed entries stay out of the output.
- **Claim 25** (commit 224dd52d): "byte-exact" should say "after one trailing CR".

### Unverifiable
- none

## Escalations

- `scripts/build-loop.sh:141-154` → **security-reviewer**: a tab-separated `Self-merge never:` value is accepted and stored raw in NEVER (`a<TAB>b`). If U2's gate splits NEVER on single spaces, the value becomes one glob matching nothing, and a path the user meant to protect could self-merge. This is fail-open relative to the documented "single spaces" rule.
- `scripts/build-loop.sh:102-108` → **security-reviewer**: copies that render as the key but are not counted (bold `**Build-loop policy:** ...`, a heading, a mid-file BOM before the key) are hidden, not "a second line". In every probe the hidden copy fails toward the counted line, not toward self-merge; whether that residue matters is a design call.
- `test/scripts/build-loop-read.bats:137` → **test-strategy** (or code-review synthesis): the no-echo check only discriminates on `\xc3`; the ASCII malformed entries are not checked for echo.
- `scripts/lib/dev-cycle-read.sh:146` via `scripts/build-loop.sh:148` → **api-consistency-reviewer**: `.github/` cannot appear in `Self-merge never:`. That is a user-facing settings contract; check it against the plan's intent for protected paths.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved to the output path named in your role section, structured per your skill.
- Answered: yes
- Out of scope: dev-cycle.bats (64 tests) not re-run; U1c's constraints line and --status; U2's gate use of NEVER/POLICY
- Escalate: the tab separator accepted in `Self-merge never:` (Claim 4a), for security-reviewer
- Decisions I made: split the never-glob header sentence into four atoms (4a-4d) because the verdicts diverge; execution logs kept in the scratch dir rather than docs/reviews/execution-logs/, because the pass rules allow writing only this report in the worktree; Claim 4c rated Incorrect rather than Mostly accurate, because a reader acting on "no .git" who lists `.github/` gets self-merge turned off.
