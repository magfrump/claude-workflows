Commit: 2e711a7b

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u1b (claude-workflows, branch feat/build-loop-u1b)
**Scope:** Unit diff `feat/build-loop-u1a...2e711a7b`: scripts/build-loop.sh, test/lib/build-loop-fixtures.bash, test/scripts/build-loop-read.bats, the override-log rows the unit adds (docs/reviews/override-log.md), and commit 2e711a7b's message. Replicate r3, final confirming pass (iteration 4).
**Checked:** 2026-10-05
**Total claims checked:** 35 (33 numbered; 3 and 10 split into a/b)
**Summary:** 29 verified, 5 mostly accurate, 1 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). Its entries are wrong counts in commit messages and docs. The one count claim here, "~417 changed code lines" (Claim 28), was checked against that pattern and matches `git diff --stat` (417).

Execution environment for every `executed` claim: git 2.39.5, bats 1.8.2, GNU bash, `LC_ALL=C.UTF-8`, `TMPDIR` = scratch. Scratch root (all copies, mutants and repos): `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i4/fc-r3/` (written as `$S` below). `$S/scripts`, `$S/test` and `$S/docs/dev-cycle.md` are `git archive 2e711a7b` extracts. Captured output is in `$S/logs/`. Mutants come from `$S/mut.sh NAME PERL-EXPR`, which copies the extract, applies one `perl -0pi` edit to scripts/build-loop.sh (diff saved as `logs/mut-NAME.diff`) and runs the suite (`logs/mut-NAME.log`).

| Run | Command (cwd) | Exit | Time (UTC) | Output |
|---|---|---|---|---|
| E1 baseline | `bats test/scripts/build-loop-read.bats` (`$S`) | 0 (9/9 ok) | 2026-10-05T16:40:50Z | `logs/baseline.log` |
| E2 mutants | `./mut.sh noconfig`, `noconfig_noenv`, `nevercheck`, `neverinit1`, `headread`, `nonearm`, `nextcheck` (`$S`) | per mutant, see claims | 2026-10-05T16:41:11Z | `logs/mut-*.log`, `logs/mut-*.diff` |
| E3 mutants | `./mut.sh nevercheck2`, `./mut.sh dupnever` (`$S`) | 1 each (test 7 fails) | ~2026-10-05T16:41:40Z | `logs/mut-nevercheck2.log`, `logs/mut-dupnever.log` |
| E4 replace refs | `./replace-exp.sh` (`$S`; builds `$S/repo-replace`) | 0 | 2026-10-05T16:41:58Z | `logs/replace-exp.log` |
| E5 octal count | `env GIT_CONFIG_COUNT=010/08 … bash scripts/build-loop.sh --settings` (`$S/repo-replace`) | 0 and 0 | ~2026-10-05T16:42:20Z | `logs/replace-octal.log` |
| E6 help | `bash $S/scripts/build-loop.sh -h` (`$S/repo-replace`), then diffed against `sed -n 2,38p` of the script | 0; diff empty | ~2026-10-05T16:42:30Z | `logs/help.out`, `logs/help.expected`, `logs/help.exit` |
| E7 next line | `./nextline-exp.sh` (`$S`; builds `$S/repo-next`) | 0 | 2026-10-05T16:42:57Z | `logs/nextline-exp.log` |
| E8 hidden copies | inline loop over three hidden never shapes (`$S/repo-next`) | 0 | ~2026-10-05T16:43:20Z | `logs/hidden-exp.log` |
| E9 rows | "except on Fridays" policy; timing for an 80 KB and a 40 KB never entry (`$S/repo-next`) | 0 | 2026-10-05T16:43:51Z | `logs/rows-exp.log` |

---

## Claim 1: "a second copy, or a file the lib's FENCE_AWK refuses, gives review, 3 and malformed (WHY says which)"

**Location:** `scripts/build-loop.sh:11-12`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the per-key reading (a second copy of the policy key gives review, of the slots key gives 3, of the never key gives malformed) and the whole-file reading (a refused or unbalanced file gives all three), plus the absent-file and not-a-regular-file arms; does not establish anything about hidden copies (Claim 6) or about readers other than `--settings`.

The not-read arm sets all three lines from FILE_WHY, and the never line distinguishes absent from not read:

```bash
# scripts/build-loop.sh:139-143
  if ! main_file "$f" "$SETTINGS_AWK"; then
    [[ "$FILE_WHY" == absent ]] && why="no $f on the default branch" || why="$FILE_WHY"
    POLICY_LINE="policy review unset: $why"; SLOTS_LINE="slots 3 default: $why"
    # An absent file sets nothing; one that is not read turns self-merge off.
    if [[ "$FILE_WHY" == absent ]]; then NEVER_LINE="never none: $why"; else NEVER_LINE="never malformed: $why"; fi
```

The copy arms are per key: `:153` (`never malformed: $(many …)`), `:176` (`policy review unset: $(many …)`), `:184` (`slots 3 default: $(many …)`). Two policy copies leave the never line untouched (E7: "two policy lines, exact never" printed `policy review unset: more than one line starts "Build-loop policy:" (lines 1 and 2)` with `never none: line 4 … lists none`). A file refused at line 4 (`<div>`) printed `policy review unset: line 4 … starts with < …, so the file is not read` and `never malformed: line 4 …` (E7). The suite's T3 test asserts the comment-refusal case for policy and never (`test/scripts/build-loop-read.bats:40-42`) and the absent file's `never none` (`:50`).

**Evidence:** `scripts/build-loop.sh:139-143`, `scripts/build-loop.sh:150-153`, `scripts/build-loop.sh:175-186`, `test/scripts/build-loop-read.bats:35-60`, `$S/logs/nextline-exp.log`, `$S/logs/baseline.log`

---

## Claim 2: "Set only by "Build-loop policy: self-merge" or "...: review", exactly (one trailing CR dropped); else review."

**Location:** `scripts/build-loop.sh:14-15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the exact-match regex, the one-CR strip and the review default for variants. It does not cover the additional never-line condition on self-merge, which is Claims 3a and 3b.

```bash
# scripts/build-loop.sh:177
    elif [[ "${text[policy]}" =~ ^Build-loop\ policy:\ (self-merge|review)$ ]]; then
```

SETTINGS_AWK drops one trailing CR, `{ sub(/\r$/, "") }` (`scripts/build-loop.sh:104`), and FENCE_AWK then refuses any CR left in the line: `if (index(l, "\r")) { refuse("cr"); return 1 }` (`scripts/lib/dev-cycle-read.sh:211`). So a second CR leaves the file unread and the policy at review. Tests T1 and T2 pass (E1). Their inputs are a CRLF line, a parenthesised suffix, the wrong case, a trailing space and a double space.

**Evidence:** `scripts/build-loop.sh:104`, `scripts/build-loop.sh:175-182`, `scripts/lib/dev-cycle-read.sh:209-212`, `test/scripts/build-loop-read.bats:12-40`, `$S/logs/baseline.log`

---

## Claim 3a: "Self-merge also needs a valid never line"

**Location:** `scripts/build-loop.sh:15-16`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every path into `POLICY=self-merge` in `read_settings` at 2e711a7b. That means `never_ok` is set only by the exact single never line, in either its `none` arm or its set arm. It does not establish how future consumers (U1c `--status`, U2's gate) use POLICY.

```bash
# scripts/build-loop.sh:179-181 (excerpt of read_settings' policy branch :175-182 — read)
      if [[ "$v" == self-merge && -z "$never_ok" ]]; then
        POLICY_LINE="policy review unset: line ${first[policy]} reads self-merge, but there is no valid Self-merge never: line (\"Self-merge never: none\" for an empty list), so self-merge is off"
      else POLICY="$v"; POLICY_LINE="policy $v set: line ${first[policy]} $where"; fi
```

`never_ok` starts empty (`local … never_ok=""`, `:135`). It is set to 1 only at `:172` (`never none: … lists none`) and `:173` (`never $v set`), and both run only when `cnt[never]` is 1 and `why` is empty. The no-line arm (`:152`), the duplicate arm (`:153`), the malformed arm (`:171`) and the file-not-read arm (`:139-143`, where the policy is review anyway) all leave it empty. Mutants: `nevercheck2` (the `:179` condition replaced by `false`) fails test 7. `neverinit1` (`never_ok=1` initially) fails test 7. `dupnever` (`never_ok=1` added to the duplicate arm) fails test 7 at `build-loop-read.bats:129` (E3, E2).

**Evidence:** `scripts/build-loop.sh:134-188`, `test/scripts/build-loop-read.bats:105-129`, `$S/logs/mut-nevercheck2.log`, `$S/logs/mut-neverinit1.log`, `$S/logs/mut-dupnever.log`

---

## Claim 3b: "so a list hidden in markup turns it off rather than being skipped"

**Location:** `scripts/build-loop.sh:16-17` (same wording in `test/scripts/build-loop-read.bats:116` and commit 2e711a7b's Q-112 bullet)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers what a hidden never list does when it is the only never-like line, and when it sits next to an exact never line. It does not re-raise the accepted residual hidden shapes (override row 256): this is a wording qualifier only. The behaviour cannot raise the policy or add self-merge beyond what the exact lines already give.

The claim holds only when the hidden list is the only never line. When an exact `Self-merge never: none` line is also present, the hidden list is skipped and self-merge stays on. E8, from `$S/logs/hidden-exp.log`:

```
== hidden first: - [x] Self-merge never: hk/        (file also holds "Build-loop policy: self-merge" and "Self-merge never: none")
policy self-merge set: line 3 of docs/dev-cycle.md on the default branch
never none: line 5 of docs/dev-cycle.md on the default branch lists none
== hidden only: - [x] Self-merge never: hk/
policy review unset: line 1 reads self-merge, but there is no valid Self-merge never: line (...)
```

This matches override row 256 ("A hidden copy next to an exact line is ignored, and the exact line governs"), so the behaviour is settled. Header `:30-31` also says markup "can still hide a copy". The sentence at `:16-17` read alone still says a hidden list is never skipped. A more precise version: "so a never list hidden in markup, when it is the only one, turns it off rather than being skipped". Note also that an unchecked task box `- [ ]` adds no letters and is caught as a copy (E7, "hidden task-box never after exact none" → `never malformed: … (lines 3 and 5)`), so only a checked box hides one.

**Evidence:** `scripts/build-loop.sh:15-17`, `scripts/build-loop.sh:28-31`, `scripts/build-loop.sh:108-112`, `docs/reviews/override-log.md:256`, `$S/logs/hidden-exp.log`, `$S/logs/nextline-exp.log`

---

## Claim 4: "Loops at once: "Build-loop slots: N", N from 1 to 9; else 3."

**Location:** `scripts/build-loop.sh:18-19`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the slots regex and the default of 3 for variants, copies, a fenced line and an unread file. It does not establish what a consumer does with the number; no consumer exists in this unit.

```bash
# scripts/build-loop.sh:185
    elif [[ "${text[slots]}" =~ ^Build-loop\ slots:\ ([123456789])$ ]]; then SLOTS_LINE="slots ${BASH_REMATCH[1]} set: line ${first[slots]} $where"
```

Test 6 passes (E1). It covers 0, 10, a trailing space, 05, three, two copies and a fenced copy.

**Evidence:** `scripts/build-loop.sh:183-186`, `test/scripts/build-loop-read.bats:85-96`, `$S/logs/baseline.log`

---

## Claim 5: "Paths self-merge never lands: "Self-merge never: GLOB ..." (or "...: none"), single spaces, and the next line outside a fence blank or the end. A glob uses letters, digits, . _ - / * ? (a trailing / ignored when comparing), has no empty, . or .. part, does not start with / or -, and is listed once. Malformed (or a file not read) turns self-merge off."

**Location:** `scripts/build-loop.sh:21-27`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the format, the next-unfenced-line rule (fenced lines are skipped, whitespace-only and CR-only lines count as blank, the end of file passes), the glob rules and the self-merge-off consequence. "Letters" means ASCII letters (NAMECHARS). It does not establish whether `none hk/` (a glob literally named `none` plus another) is intended. It reads as two globs, which is consistent with the text.

The next-line flag is updated only on lines that survive `fence($0) { next }`:

```awk
# scripts/build-loop.sh:104-107 (excerpt of SETTINGS_AWK :103-118 — read)
{ sub(/\r$/, "") }
fence($0) { next }
{
  if (pk != "") { nx[pk] = ($0 ~ /^[ \t]*$/); pk = "" }
```

`nx[k] = 1` at the first copy (`:112`) makes the end of the file pass. E7 results: fence-after-never then EOF → set; fence then `c/` → malformed with "is followed by a non-blank line outside a fence"; fence, blank, `c/` → set; spaces, tab or CR-only line → set; never as the last line with no newline → set; a one-line `<!-- c/ -->` after → malformed. The glob rules are at `:121-128` and `:157-169`. Test 7 passes, and mutant `nextcheck` (`:159` removed) fails test 7 (E2).

**Evidence:** `scripts/build-loop.sh:103-128`, `scripts/build-loop.sh:152-174`, `scripts/lib/dev-cycle-read.sh:139`, `test/scripts/build-loop-read.bats:98-141`, `$S/logs/nextline-exp.log`, `$S/logs/mut-nextcheck.log`

---

## Claim 6: "Copies are found best effort: a line counts as one when its letters alone, case folded, start with the key's ("buildlooppolicy"). Markup that adds letters (a task box, a tag) can still hide a copy; only an exact line ever sets a value."

**Location:** `scripts/build-loop.sh:28-31`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the letters-only match under `LC_ALL=C` (ASCII a–z only; non-ASCII letter bytes are dropped like punctuation) and the exactness of every value-setting arm. It does not establish the residual hidden shapes, which override row 256 and Q-112 [1] accept. A "task box" hides a copy only when checked (`[x]` adds a letter, `[ ]` does not).

```awk
# scripts/build-loop.sh:108-112 (excerpt of SETTINGS_AWK :103-118 — read)
  s = tolower($0); gsub(/[^a-z]/, "", s); k = ""
  if (index(s, "buildlooppolicy") == 1) k = "policy"
  else if (index(s, "buildloopslots") == 1) k = "slots"
  else if (index(s, "selfmergenever") == 1) k = "never"
```

`main_file` runs the awk under `env LC_ALL=C` (`:89`). The value-setting arms are the policy regex `:177`, the slots regex `:185`, and for never the prefix plus single-space regex `:157` followed by globform. E8: `- [x] Self-merge never: hk/` is hidden. `[Self-merge never: hk/](x)` is a copy. `<b>…</b>` refuses the file (FENCE_AWK html). Test 2's and test 7's copy loops pass (E1).

**Evidence:** `scripts/build-loop.sh:89`, `scripts/build-loop.sh:108-112`, `scripts/build-loop.sh:157`, `scripts/build-loop.sh:177`, `scripts/build-loop.sh:185`, `$S/logs/hidden-exp.log`, `$S/logs/baseline.log`

---

## Claim 7: "Acts on $PWD's git repo, like dev-cycle.sh, and needs its default branch found by name (origin/HEAD, main or master). Read-only: writes nothing. Output passes through the lib's scrub (but for the start-up errors about perl and the lib) … Exit: 0 every line printed (or help); 1 bad usage, not a git repo, no perl or lib/dev-cycle-read.sh, or no default branch found by name."

**Location:** `scripts/build-loop.sh:33-38`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the exit codes and messages that test 8 and test 9 assert, the ordering of the perl and lib checks before `scrub_reexec`, and the absence of write commands. Residue, not covered: under an unusual caller environment the message names the wrong cause. With `GIT_CONFIG_COUNT=abc`, git refuses the bogus count, so `rev-parse` fails and the script prints "Not inside a git repository" (exit 1) inside a valid repo (E4, `logs/replace-exp.log`).

```bash
# scripts/build-loop.sh:42-51
command -v perl >/dev/null || { echo "build-loop.sh needs perl (to scrub its output)" >&2; exit 1; }
...
[[ -f "$READ_LIB" ]] || { echo "build-loop.sh needs $READ_LIB" >&2; exit 1; }
...
scrub_reexec "${BASH_SOURCE[0]}" "$@"
```

`:62` exits 1 with "Not inside a git repository". `:72` exits 1 when `main_by_name` fails. `usage` exits 1 (`:53`). Test 8 asserts exit 1 for each usage error, for a renamed default branch and outside a repo. Test 9 asserts it for a missing lib (E1). The script's git calls are only `rev-parse`, `ls-tree`, `cat-file`, `symbolic-ref` and `show-ref` (paraphrased — no quote available because the claim covers absence of write commands across the script and the lib functions it calls; checked by reading `scripts/build-loop.sh:62-195` and `scripts/lib/dev-cycle-read.sh:245-287,389-412`).

**Evidence:** `scripts/build-loop.sh:40-72`, `scripts/lib/dev-cycle-read.sh:76-81`, `test/scripts/build-loop-read.bats:143-159`, `$S/logs/baseline.log`, `$S/logs/replace-exp.log`

---

## Claim 8: "The reader shared with dev-cycle.sh, from this script's own directory (never the target repo's scripts/lib/), so a copy of scripts/ with its lib/ is self-contained."

**Location:** `scripts/build-loop.sh:43-47`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the lib is sourced from `$SCRIPT_DIR/lib`, which is resolved before the `cd`. It does not establish anything about the lib's own contents.

```bash
# scripts/build-loop.sh:43,47
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  # before the cd: relative paths work
READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"
```

Test 9 plants `scripts/lib/dev-cycle-read.sh` printing `PLANTED` in the target repo, and it is not run. A bare copy without `lib/` exits 1 (E1). The whole suite also passes from the archived copy in `$S` (E1), so a copy of scripts/ with its lib/ is self-contained.

**Evidence:** `scripts/build-loop.sh:43-51`, `test/scripts/build-loop-read.bats:161-168`, `$S/logs/baseline.log`

---

## Claim 9: "# the header, to its first non-comment line"

**Location:** `scripts/build-loop.sh:57`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the output of `-h` at 2e711a7b, which is lines 2–38 with `# ` stripped. The range ends at the first line starting with a non-`#` character, so an empty line does not end it. A blank line inside the header would be skipped, not treated as its end. The claim does not establish behaviour for a future header with such a blank line.

```bash
# scripts/build-loop.sh:57
  -h|--help) sed -n '2,/^[^#]/{/^#/p}' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;  # the header, to its first non-comment line
```

E6: `-h` exits 0. Its 37 lines are identical to `sed -n '2,38p' | sed 's/^# \{0,1\}//'` (`diff` empty). Line 39 is empty and is neither printed nor an end. The range ends at `:40` `set -euo pipefail`. `--help` from `/` also works. `scripts/dev-cycle.sh:112` uses the identical command.

**Evidence:** `scripts/build-loop.sh:57`, `scripts/dev-cycle.sh:112`, `$S/logs/help.out`, `$S/logs/help.expected`, `$S/logs/help.exit`

---

## Claim 10a: "Read main's own objects: a replace ref could swap in any settings blob. core.useReplaceRefs in the repo's config would override the variable"

**Location:** `scripts/build-loop.sh:66-67`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers git 2.39.5, the version in this sandbox. Under it, repo config `core.useReplaceRefs=true` re-enables replace refs that `GIT_NO_REPLACE_OBJECTS=1` alone had disabled. It does not establish behaviour under other git versions.

E4, from `$S/logs/replace-exp.log`, using a repo whose main blob says review, with a replace ref to a self-merge blob and `core.useReplaceRefs=true`:

```
== git cat-file with only env (no config pair)
Build-loop policy: self-merge
== git cat-file with env + count pair
Build-loop policy: review
```

Mutants `noconfig` (`:69` removed) and `noconfig_noenv` both fail test 5 at the replace-ref step (`build-loop-read.bats:84`) (E2).

**Evidence:** `scripts/build-loop.sh:66-70`, `test/scripts/build-loop-read.bats:82-84`, `$S/logs/replace-exp.log`, `$S/logs/mut-noconfig.log`

---

## Claim 10b: "add a command-line config pair after any the caller passed."

**Location:** `scripts/build-loop.sh:67-69` (same wording in commit 2e711a7b's A16 bullet: "A GIT_CONFIG_COUNT pair, appended after any the caller passed, sets it false")
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the caller's `GIT_CONFIG_COUNT`/`KEY_n`/`VALUE_n` pairs written with a plain decimal count, which the guard does follow; an empty or unset count also works. Residue: two caller forms defeat it. The first is `GIT_CONFIG_PARAMETERS` (what `git -c` exports). The second is a zero-padded count. The verdict does not establish whether either form can reach the orchestrator's environment; a build loop does not set it.

```bash
# scripts/build-loop.sh:69
cfg="${GIT_CONFIG_COUNT:-0}"; export "GIT_CONFIG_KEY_$cfg=core.useReplaceRefs" "GIT_CONFIG_VALUE_$cfg=false" GIT_CONFIG_COUNT=$((cfg + 1))
```

E4 results, each with a replace ref plus repo `core.useReplaceRefs=true`:
- Caller `GIT_CONFIG_COUNT=1 KEY_0=core.useReplaceRefs VALUE_0=true` → `policy review set` (guard holds).
- Count empty, or 0 → review (holds).
- Caller `GIT_CONFIG_PARAMETERS="'core.usereplacerefs'='true'"` → `policy self-merge set`. Git applies `GIT_CONFIG_PARAMETERS` after the `GIT_CONFIG_COUNT` pairs, so the script's pair is not last.

E5, from `$S/logs/replace-octal.log`:
- `GIT_CONFIG_COUNT=010` with ten innocuous pairs. Bash reads 010 as octal 8, so the script writes `KEY_010` and sets the count to 9. Git reads decimal keys 0–8 and never sees the pair, so the result is `policy self-merge set` and the caller's tenth pair is silently dropped.
- `GIT_CONFIG_COUNT=08` → `line 69: 08: value too great for base`. Bash discards the rest of that command line without `set -e` firing, the run continues, and it exits 0 with `policy self-merge set`.

The precise version: "after any GIT_CONFIG_COUNT pair the caller passed (a decimal count without leading zeros); a caller's `git -c`/GIT_CONFIG_PARAMETERS setting still wins".

**Evidence:** `scripts/build-loop.sh:66-70`, `$S/logs/replace-exp.log`, `$S/logs/replace-octal.log`

---

## Claim 11: "A file on main: FILE_OUT is what awk program $2 (after FENCE_AWK) printed over it; or it returns 1 with FILE_WHY "absent" or why it was not read (main_entry, a failed read, or FENCE_AWK's "odd N WHY" / "unbalanced N")."

**Location:** `scripts/build-loop.sh:74-76`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every return arm of `main_file` (`:78-95`). It does not establish that the `error` arm and the failed-read arm are exercised by this unit's tests: override row 260 defers that, and they were read statically here. FILE_WHY for odd and unbalanced is a sentence built from FENCE_AWK's output, not the raw token.

```bash
# scripts/build-loop.sh:89-94 (excerpt of main_file :78-95 — read)
  FILE_OUT="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk "$FENCE_AWK$2")" \
    || { FILE_WHY="$f could not be read from the default branch"; return 1; }
  case "$FILE_OUT" in
    odd\ *) read -r _ n why <<<"$FILE_OUT"; FILE_WHY="line $n of $f $(oddwhy "$why"), so the file is not read"; return 1 ;;
    unbalanced\ *) FILE_WHY="the code fence opened at line ${FILE_OUT#unbalanced } of $f is never closed, so the file is not read"; return 1 ;;
  esac
```

`set -o pipefail` (`:40`) is inherited by the `$(...)`, so a failed `cat-file` is caught. Test 3 exercises the absent, notfile (symlink, directory), notdir, odd (comment, BOM) and unbalanced arms (E1).

**Evidence:** `scripts/build-loop.sh:40`, `scripts/build-loop.sh:74-95`, `scripts/lib/dev-cycle-read.sh:258-287`, `test/scripts/build-loop-read.bats:35-60`, `$S/logs/baseline.log`

---

## Claim 12: "One pass over docs/dev-cycle.md: per key, how many lines start with it …, the first two line numbers, whether the line after the first is blank (NEXT 1) or not, and the first line whole: "KEY COUNT FIRST SECOND NEXT<TAB>LINE"."

**Location:** `scripts/build-loop.sh:97-101`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the output format and the meaning of NEXT. Fenced lines are skipped, a whitespace-only line counts as blank, and NEXT is 1 at the end of the file. It does not re-check the copy-detection rule (Claim 13).

The output format matches `:117` (`print k " " c[k] " " l1[k] " " (k in l2 ? l2[k] : 0) " " nx[k] "\t" t[k]`), with SECOND 0 when there is no second copy. The awk does not test "the line after the first", though. It tests the next line that `fence()` lets through, because `fence($0) { next }` (`:105`) runs before the `pk` update (`:107`). It counts `[ \t]*` lines as blank, and it gives 1 when no later line exists (`nx[k] = 1`, `:112`). E7: a never line followed by a fenced block and then the end of the file gives NEXT 1 (set), although the literal next line is a fence. The header (`:22-23`) and the WHY (`:159`) were updated for iteration 3's A21. This comment still says "the line after the first". A precise version: "whether the next line outside a fence is blank or there is none (NEXT 1)".

**Evidence:** `scripts/build-loop.sh:97-118`, `scripts/build-loop.sh:22-23`, `scripts/build-loop.sh:159`, `$S/logs/nextline-exp.log`

---

## Claim 13: "(best effort: most markup, a BOM or a misplaced colon cannot hide a copy)"

**Location:** `scripts/build-loop.sh:98-99`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the BOM case (on line 1 FENCE_AWK refuses the file; on a later line the BOM bytes are dropped as non-letters) and a misplaced colon (`Self-merge never : b/`). "Most markup" covers the shapes in tests 2 and 7. Letter-adding markup is excluded, as Claim 6 states.

```awk
# scripts/lib/dev-cycle-read.sh:213
  if (NR == 1 && substr(l, 1, 3) == "\357\273\277") { refuse("bom"); return 1 }
```

Test 2 puts a BOM copy on line 2, and it is counted (`build-loop-read.bats:31-35`). Test 3 puts a BOM on line 1, and the file is refused (`:44-45`). Test 7 covers the colon case (`:131`). All pass (E1).

**Evidence:** `scripts/build-loop.sh:108`, `scripts/lib/dev-cycle-read.sh:213`, `test/scripts/build-loop-read.bats:31-35`, `test/scripts/build-loop-read.bats:44-45`, `test/scripts/build-loop-read.bats:130-134`, `$S/logs/baseline.log`

---

## Claim 14: "A never entry: pathform's rule, but a .git* part (.github/) is allowed, since the list only adds refusals and must not turn self-merge off by naming one."

**Location:** `scripts/build-loop.sh:119-120`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers parity with `pathform "$p" glob`, minus the `.git*` part check. It does not establish that U2 will use globform rather than pathform; override rows 238 and 262 defer that.

```bash
# scripts/build-loop.sh:121-128
globform() {
  local rest="$1/" c
  [[ "$1" =~ ^[*?$NAMECHARS]+$ && "$1" != /* && "$1" != -* ]] || return 1
  while [[ -n "$rest" ]]; do
    c="${rest%%/*}"; rest="${rest#*/}"
    [[ -n "$c" && "$c" != "." && "$c" != ".." ]] || return 1
  done
}
```

Compared with `pathform` (`scripts/lib/dev-cycle-read.sh:140-148`), the only difference is the removed `&& "$c" != [.][gG][iI][tT]*` clause. Test 7 accepts `.github/ .gitignore` (E1).

**Evidence:** `scripts/build-loop.sh:119-128`, `scripts/lib/dev-cycle-read.sh:139-148`, `test/scripts/build-loop-read.bats:135-137`, `$S/logs/baseline.log`

---

## Claim 15: "Sets POLICY, POLICY_LINE, SLOTS_LINE, NEVER (an array of the checked globs, each as written, a trailing / kept) and NEVER_LINE from main's commit. POLICY and NEVER are for the modes that judge a brief (--status, then the gate)."

**Location:** `scripts/build-loop.sh:129-131`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers what `read_settings` assigns. It does not establish the forward-looking purpose: no reader of POLICY or NEVER exists in this unit (U1c and U2 are not in the diff).

```bash
# scripts/build-loop.sh:173
      else never_ok=1; NEVER=("${parts[@]}"); NEVER_LINE="never $v set: line ${first[never]} $where"; fi
```

`parts` comes from `IFS=' ' read -ra parts <<<"$v"` (`:163`), with each entry unmodified. Only the `seen` key and the globform argument strip `/` (`${g%/}`, `:166-168`). POLICY is assigned at `:137` and `:181`. The only mode at 2e711a7b prints the three `_LINE` variables (`:190-195`).

**Evidence:** `scripts/build-loop.sh:129-195`

---

## Claim 16: "Split on single spaces only; globform then refuses any other blank in an entry." / "not a bare $v: the shell would expand * and ? against files"

**Location:** `scripts/build-loop.sh:156`, `scripts/build-loop.sh:163`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers tabs (test 7 has four tab shapes), NBSP (E7, refused by the prefix check when it follows the colon) and the use of `read -ra`, which does not glob. The globbing half rests on documented bash semantics for unquoted expansion and was not executed.

```bash
# scripts/build-loop.sh:157 and :163
      if [[ "$t" != "Self-merge never: "* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]; then
        IFS=' ' read -ra parts <<<"$v"  # not a bare $v: the shell would expand * and ? against files
```

Test 7 asserts that `$'Self-merge never: a\tb'`, `$'… \ta'`, `$'… a\t'` and `$'… a \tb'` are malformed and that no tab is echoed (E1). Removing the `IFS` split was confirmed by an earlier iteration to fail T45 (override row 235); that was not re-run here.

**Evidence:** `scripts/build-loop.sh:155-170`, `test/scripts/build-loop-read.bats:117-125`, `$S/logs/baseline.log`, `$S/logs/nextline-exp.log`

---

## Claim 17: "Shared setup for test/scripts/build-loop-*.bats: a throwaway repo under $BATS_TEST_TMPDIR with a main branch, the same hermetic git environment as test/scripts/dev-cycle.bats, and helpers that write the files the script reads from main's commit." / "With no lines the file holds one empty line."

**Location:** `test/lib/build-loop-fixtures.bash:2-5`, `test/lib/build-loop-fixtures.bash:18-20`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the exported git variables and HOME, compared with `test/scripts/dev-cycle.bats:11-16`, and printf's behaviour with no arguments. The fixture also pins `LC_ALL=C`, which dev-cycle.bats' setup does not set (override row 240 records this).

```bash
# test/lib/build-loop-fixtures.bash:12-16 (excerpt of bl_setup :7-19 — read)
    export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
    export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.invalid
    export GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.invalid
    export HOME="$BATS_TEST_TMPDIR/home" LC_ALL=C
```

`settings() { mkdir -p docs && printf '%s\n' "$@" > docs/dev-cycle.md && commit_all settings; }` (`:26`). With no arguments, `printf '%s\n'` prints one newline.

**Evidence:** `test/lib/build-loop-fixtures.bash:1-36`, `test/scripts/dev-cycle.bats:11-16`

---

## Claim 18: "this repo is untouched" (each test builds a throwaway repo under $BATS_TEST_TMPDIR)

**Location:** `test/scripts/build-loop-read.bats:3-4`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the suite's cwd: every test runs in `$BATS_TEST_TMPDIR/repo`, and test 4 only reads `$REPO_ROOT/docs/dev-cycle.md` with `cp`. The suite ran from the archived copy in `$S`, so the worktree was not exposed during this check.

`setup() { bl_setup; }` (`build-loop-read.bats:11`) runs `cd "$R"` with `R="$BATS_TEST_TMPDIR/repo"` (`build-loop-fixtures.bash:16-17`). Test 4 is `cp "$REPO_ROOT/docs/dev-cycle.md" docs/` (`:71`), which reads only. E1 ran with `TMPDIR=$S/tmp`, so bats placed every `$BATS_TEST_TMPDIR` under `$S/tmp`. The failure output in `$S/logs/mut-headread.log` shows a path under `$S/tmp/bats-run-*/test/9/wt` (paraphrased — no quote available because this is an observation of where the runs wrote, not a snippet).

**Evidence:** `test/scripts/build-loop-read.bats:1-11`, `test/scripts/build-loop-read.bats:70-76`, `test/lib/build-loop-fixtures.bash:7-19`, `$S/logs/baseline.log`

---

## Claim 19: "--settings on this repo's own docs/dev-cycle.md: review, unset by the interim note (T3, G19)"

**Location:** `test/scripts/build-loop-read.bats:70`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers docs/dev-cycle.md at 2e711a7b. Its policy line is `Build-loop policy: review (interim; Q-103)` (line 7), which fails the exact match. The test checks only the policy line: it asserts nothing about slots or never in the real file (override row 257's point).

`git show 2e711a7b:docs/dev-cycle.md` line 7: `Build-loop policy: review (interim; Q-103)`. Test 4 passes (E1).

**Evidence:** `docs/dev-cycle.md:7`, `test/scripts/build-loop-read.bats:70-76`, `$S/logs/baseline.log`

---

## Claim 20: "A replace ref for main's blob, even with core.useReplaceRefs set, is not followed."

**Location:** `test/scripts/build-loop-read.bats:82`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the test's repo-config case and confirms the test catches removal of the guard. It does not test the caller-environment residue in Claim 10b, and it does not test C3's other forms.

```bash
# test/scripts/build-loop-read.bats:83-84 (excerpt of test 5 :78-91 — read)
    git replace "$(git rev-parse main:docs/dev-cycle.md)" "$(git hash-object -w docs/dev-cycle.md)" && git config core.useReplaceRefs true
    settings_like policy "policy review set:"; git replace -d "$(git rev-parse main:docs/dev-cycle.md)"
```

The replacement blob is the working-tree file, which holds `Build-loop policy: self-merge` and `Self-merge never: none` (`:80`), so following the replace ref would give `policy self-merge set`. Mutant `noconfig` fails test 5 at line 84 (E2).

**Evidence:** `test/scripts/build-loop-read.bats:78-91`, `$S/logs/mut-noconfig.log`

---

## Claim 21: "A never list hidden in markup turns self-merge off rather than being skipped." (test comment) and the duplicate-never assertion (A18)

**Location:** `test/scripts/build-loop-read.bats:116-117`, `test/scripts/build-loop-read.bats:128-129`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers what the test exercises: a sole hidden list (`- [x] Self-merge never: b/`), and two never lines asserting policy off. For the hidden list next to an exact line, see Claim 3b.

```bash
# test/scripts/build-loop-read.bats:117 and :129
    settings 'Build-loop policy: self-merge' '- [x] Self-merge never: b/'; settings_is policy "$no"
    settings_is never 'never malformed: more than one line starts "Self-merge never:" (lines 2 and 3)'; settings_is policy "$no"
```

The mutants `nevercheck2`, `neverinit1` and `dupnever` each fail test 7. `dupnever` fails at `:129`, so the A18 assertion catches the mutation it names (E2, E3).

**Evidence:** `test/scripts/build-loop-read.bats:105-129`, `$S/logs/mut-dupnever.log`, `$S/logs/mut-nevercheck2.log`, `$S/logs/mut-neverinit1.log`

---

## Claim 22: "Copies in some markup, a table, a link label or with a misplaced colon count as second lines too."

**Location:** `test/scripts/build-loop-read.bats:130`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the eight shapes in the loop at `:131-134`, all of which pass. "Some markup" correctly no longer claims all markup (A22).

The loop's shapes are `**…:** b/`, `**…**: b/`, `## …`, `_…_`, a backtick span, a table cell, `[Self-merge never](x): b/` and `Self-merge never : b/`. Each asserts `never malformed: more than one line starts …` (E1).

**Evidence:** `test/scripts/build-loop-read.bats:130-134`, `$S/logs/baseline.log`

---

## Claim 23: "From a subdirectory and from a linked worktree, it reads the same main."

**Location:** `test/scripts/build-loop-read.bats:177`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the worktree arm now detects a HEAD-reading mutant, because the worktree commits its own change (A19). The subdirectory arm alone would not detect it, since HEAD is main there.

```bash
# test/scripts/build-loop-read.bats:179-180 (excerpt of test 9 :161-186 — read)
    git worktree add -q -b wt "$BATS_TEST_TMPDIR/wt" main && mkdir -p sub
    for d in . "$BATS_TEST_TMPDIR/wt"; do printf 'Build-loop policy: review\n' > "$d/docs/dev-cycle.md"; done; git -C "$BATS_TEST_TMPDIR/wt" commit -qam wt
```

Mutant `headread` (`"$MAIN_SHA:$f"` → `"HEAD:$f"` at `:89`) fails test 9 on the `…/wt` iteration with `policy review set` (E2). It also fails tests 5 and 7.

**Evidence:** `test/scripts/build-loop-read.bats:161-186`, `$S/logs/mut-headread.log`

---

## Claim 24: Override-log row 239 — "--help prints a fixed line range (architecture M3; C5) … Won't-Fix … Same as dev-cycle.sh; each edit re-derives the range, and help is checked by hand."

**Location:** `docs/reviews/override-log.md:239`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the row's premise at 2e711a7b. The row's own outcome (Won't-Fix) is left as recorded. This row is settled, and it is raised only because its premise changed at 2e711a7b.

The premise changed in this iteration. `-h` no longer prints a fixed line range: it uses `sed -n '2,/^[^#]/{/^#/p}' "$0"` (`scripts/build-loop.sh:57`), and dev-cycle.sh does the same (`scripts/dev-cycle.sh:112`). Commit 2e711a7b says: "--help prints the header up to its first non-comment line (no fixed range), as dev-cycle.sh now does". So C5 is resolved in code, and the row's "each edit re-derives the range" no longer describes the code (E6). A precise row would say it was resolved by 2e711a7b.

**Evidence:** `docs/reviews/override-log.md:239`, `scripts/build-loop.sh:57`, `scripts/dev-cycle.sh:112`, `$S/logs/help.out`

---

## Claim 25: Override-log row 256 — "self-merge now needs a valid exact never line, so a hidden never list turns self-merge off. A hidden copy next to an exact line is ignored, and the exact line governs."

**Location:** `docs/reviews/override-log.md:256`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both halves for a checked-task-box copy, both before and after an exact line. It does not establish that every residual hidden shape behaves the same way; entities, homoglyphs and inline tags were not re-run here.

E8: a sole hidden copy gives `policy review unset: … no valid Self-merge never: line`. A hidden copy before an exact `none` gives `policy self-merge set` and `never none: line 5`. The mechanism is `:179` (quoted in Claim 3a).

**Evidence:** `scripts/build-loop.sh:179-181`, `$S/logs/hidden-exp.log`

---

## Claim 26: Override-log row 257 — "1d79ffef's message says "any link", and "T3's real-file test would catch one" holds for the policy key only"

**Location:** `docs/reviews/override-log.md:257`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the quotation against `git log -1 1d79ffef` and the real-file test's assertions. It does not judge the row's outcome.

The phrase "any link" does not occur in 1d79ffef's message. The message says "copies with markup closing before the colon, a table cell, a link or "Self-merge never :" were hidden. … so any of them is a second line". The row's quote paraphrases that. The second half is accurate: the message's "(docs/dev-cycle.md has none; T3's real-file test would catch one)" refers to a test that asserts only the policy line (`test/scripts/build-loop-read.bats:74-75`). A precise row would say: "says 'any of them' (including a link)".

**Evidence:** `docs/reviews/override-log.md:257`, commit 1d79ffef message lines 8-12 and 35, `test/scripts/build-loop-read.bats:70-76`

---

## Claim 27: Override-log row 258 — "globform is quadratic per entry, ~11 s on an 80 KB entry"

**Location:** `docs/reviews/override-log.md:258`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers superlinear growth and the order of magnitude. Absolute times depend on the host: this sandbox measured 22.2 s for 80 KB, not ~11 s. The measurement is the whole `--settings` run, not globform alone.

`while [[ -n "$rest" ]]; do c="${rest%%/*}"; rest="${rest#*/}"` (`scripts/build-loop.sh:124-125`) copies the remainder once per part. E9: one entry `a/a/…` of 80,000 bytes took `secs 22.165`, and of 40,000 bytes `secs 6.539` (×3.4 for ×2 size), with exit 0 both times.

**Evidence:** `scripts/build-loop.sh:121-128`, `$S/logs/rows-exp.log`

---

## Claim 28: Commit 2e711a7b — A18, A19, A20–A22, the --help bullet, the merge bullet, the override-row list and "~417 changed code lines against U1a"

**Location:** commit 2e711a7b message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers these bullets only. The Q-112 and A16 bullets are Claim 29, and the Q-113 waiver is a chat record that cannot be checked from the repo.

- A18: `dupnever` fails at `:129` (Claim 21).
- A19: `git -C "$BATS_TEST_TMPDIR/wt" commit -qam wt` (`build-loop-read.bats:180`), and `headread` fails on the worktree (Claim 23).
- A20: header `:11-12` (Claim 1).
- A21: header `:22-23` and the WHY at `:159` (Claim 5). The awk comment at `:99-100` was missed (Claim 12).
- A22: "some markup" (`:130`).
- --help: Claim 9.
- Merge: `d06e61a6` has parents `3b0adc25` and `4aa2e98e`, U1a's iteration-4 fix.
- Rows: 256 R4, 257 A23, 258 C1, 259 C2, 260 C4, 261 C5, 262 C6, 263 C8, 264 C9 — nine rows, matching "R4, A23 and iteration 3's C1, C2, C4-C6, C8, C9".
- Size: `git diff --stat feat/build-loop-u1a...2e711a7b -- scripts test` gives `3 files changed, 417 insertions(+)`.

**Evidence:** `test/scripts/build-loop-read.bats:129-130`, `test/scripts/build-loop-read.bats:180`, `docs/reviews/override-log.md:256-264`, `$S/logs/mut-dupnever.log`, `$S/logs/mut-headread.log`

---

## Claim 29: Commit 2e711a7b — Q-112 bullet "so a never list hidden in markup turns self-merge off instead of being skipped" and A16 bullet "A GIT_CONFIG_COUNT pair, appended after any the caller passed, sets it false"

**Location:** commit 2e711a7b message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** The same two qualifiers as Claims 3b and 10b. A hidden list is skipped when an exact never line also exists. A caller's `GIT_CONFIG_PARAMETERS`, or a zero-padded count, overrides or loses the pair. The rest of each bullet is verified: the `core.useReplaceRefs` override is real on git 2.39.5, and a test plants a replace ref with the config set. History is not expected to be rewritten.

The evidence is in Claims 3b and 10b (paraphrased — no quote available because the evidence is the captured E4, E5 and E8 output already quoted there).

**Evidence:** `$S/logs/hidden-exp.log`, `$S/logs/replace-exp.log`, `$S/logs/replace-octal.log`

---

## Claim 30: Override-log row 259 — "dev-cycle.sh's lib readers have no replace-ref guard"

**Location:** `docs/reviews/override-log.md:259`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers scripts/dev-cycle.sh and scripts/lib/dev-cycle-read.sh at 2e711a7b. It does not establish U3b's planned refusal.

`rg -n REPLACE scripts/dev-cycle.sh` returns nothing. The only `GIT_NO_REPLACE_OBJECTS` in scripts/ is at `scripts/build-loop.sh:70` (paraphrased — no quote available because the claim covers absence of code; there were no matching grep results).

**Evidence:** `scripts/build-loop.sh:66-70`, `scripts/dev-cycle.sh`

---

## Claim 31: Override-log row 260 — "The lib's own tests cover main_entry's error and a failed blob read (dev-cycle.bats)"

**Location:** `docs/reviews/override-log.md:260`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the existence of those tests in dev-cycle.bats, for the lib's readers. It does not establish that build-loop.sh's own `main_file` error and failed-read arms are tested (they are not, which is the deferral).

```bash
# test/scripts/dev-cycle.bats:1245 and :1273
@test "an unreadable blob or a tree naming a file twice is a skip, never a fall-through or a read of the other copy" {
    [ "$output" = "skip Q-1: the default branch's tree could not be read, so docs/working/questions.md is not read" ] || { echo "$output"; return 1; }
```

Line `:1255` deletes the blob objects, and `:1257` asserts "could not be read from the default branch".

**Evidence:** `test/scripts/dev-cycle.bats:1245-1273`

---

## Claim 32: Override-log row 261 — "With Q-112's rule, self-merge implies a valid never line, so an empty NEVER under self-merge means "none"."

**Location:** `docs/reviews/override-log.md:261`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `read_settings` at 2e711a7b. POLICY is self-merge only when `never_ok` is 1 (Claim 3a). `never_ok` is 1 either in the `none` arm, where NEVER stays `()` from `:137`, or in the set arm, where NEVER is non-empty because `v` matched `^[^\ ]+(\ [^\ ]+)*$`. It does not establish how consumers read NEVER.

```bash
# scripts/build-loop.sh:172-173
      elif [[ "$v" == none ]]; then never_ok=1; NEVER_LINE="never none: line ${first[never]} $where lists none"
      else never_ok=1; NEVER=("${parts[@]}"); NEVER_LINE="never $v set: line ${first[never]} $where"; fi
```

**Evidence:** `scripts/build-loop.sh:134-181`

---

## Claim 33: Override-log rows 262 and 264 — "The plan's ":74" still says pathform globs" / ""Build-loop policy: self-merge" followed by "except on Fridays" still reads as set"

**Location:** `docs/reviews/override-log.md:262`, `docs/reviews/override-log.md:264`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the plan text at line 74, and the Fridays example run against an exact `Self-merge never: none` line. Row 263 (U1c's reader) has no checkable content and was not verdicted.

The plan's line 74 reads: `` `docs/dev-cycle.md` may add `Self-merge never: GLOB …` (pathform globs, one line, read from main's commit) `` (`docs/working/plan-build-loop-handoff.md:74`). E9: `Build-loop policy: self-merge` / `except on Fridays` / blank / `Self-merge never: none` gives `policy self-merge set: line 1 …`.

**Evidence:** `docs/working/plan-build-loop-handoff.md:74`, `$S/logs/rows-exp.log`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
- **Claim 24** (`docs/reviews/override-log.md:239`): The row says --help prints a fixed line range that each edit re-derives. Since 2e711a7b, help prints the header to its first non-comment line (`scripts/build-loop.sh:57`), so the row could note it was resolved.

### Mostly Accurate
- **Claim 3b** (`scripts/build-loop.sh:16-17`): "a list hidden in markup turns it off" holds only when the hidden list is the only never line. Beside an exact never line the hidden list is skipped (the behaviour row 256 accepts). Add "when it is the only one".
- **Claim 10b** (`scripts/build-loop.sh:67-69`): "after any the caller passed" holds for GIT_CONFIG_COUNT pairs with a plain decimal count. A caller's `GIT_CONFIG_PARAMETERS` (`git -c`) is applied after it and wins, and a zero-padded count (`010`, `08`) loses the pair. With repo `core.useReplaceRefs=true` plus a replace ref, all three runs printed `policy self-merge set`.
- **Claim 12** (`scripts/build-loop.sh:99-100`): The SETTINGS_AWK comment still says "the line after the first is blank". The code tests the next line outside a fence, counts whitespace-only lines as blank, and gives 1 at the end of the file.
- **Claim 26** (`docs/reviews/override-log.md:257`): Quotes "any link"; 1d79ffef's message says "any of them".
- **Claim 29** (commit 2e711a7b): The Q-112 and A16 bullets carry the same two qualifiers as Claims 3b and 10b.

### Unverifiable
(none)

---

## Goal-Alignment Note

**Success criterion (restated verbatim):** "A report saved at the output path named in your tail, structured per your skill, covering the full unit diff at 2e711a7b."

**Answered:** Yes. The report is saved at `docs/reviews/code-fact-check-report-build-loop-u1b-r3.md` with `Commit: 2e711a7b` first. It covers scripts/build-loop.sh (header, every comment block, main_file, SETTINGS_AWK, globform, read_settings), the fixture, the suite (test names and comments, each checked against a mutant where the brief asked), the override-log rows this iteration added (256–264, row 263 not checkable), row 239 (premise changed), and commit 2e711a7b's message. All ten brief items are covered:
1. Claim 1.
2. Claims 3a and 3b. No input gives `policy self-merge set` without an exact valid never line. No hidden shape raised the policy or added self-merge beyond the exact lines.
3. Claims 5 and 12.
4. Claims 6 and 13.
5. Claims 7 and 9.
6. Claims 10a and 10b.
7. Claims 11, 14 and 15.
8. Claims 17–23. Every named mutant was killed except `nonearm`. Dropping only the `:160` `none` arm is an equivalent mutant, because `none` passes globform and the `:172` arm still prints `never none … lists none`. It does not show a test gap in any claimed property.
9. Claims 28 and 29.
10. Claims 24–27 and 30–33.

**Out of scope:** U1a's lib, apart from the functions build-loop.sh calls. U1c's constraints and `--status`. The earlier docs/reviews artifacts. Code-quality judgments.

**Escalate:**
- Claim 10b (low severity, not settled by any override row): two caller-environment forms defeat the replace-ref guard. One is `GIT_CONFIG_PARAMETERS` setting `core.useReplaceRefs=true`. The other is a zero-padded `GIT_CONFIG_COUNT` (`08` also prints a bash error and carries on with exit 0). Each gives `policy self-merge set` from a replace ref when the repo config sets useReplaceRefs. A build loop cannot set the orchestrator's environment, so this is a wording fix to the comment, unless the orchestrator thinks a caller-environment `-c` is in its threat model. An adjacent quirk: `GIT_CONFIG_COUNT=abc` exits 1 with "Not inside a git repository".
- No Incorrect verdicts. No claim reached blocking grade.

**Questions / Decisions:** None.
