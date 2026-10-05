# Code Fact-Check Report

**Commit:** 0ae7d801

**Repository:** /workspace/.claude/wt-build-loop-u1b (branch feat/build-loop-u1b)
**Scope:** unit diff feat/build-loop-u1a...feat/build-loop-u1b: scripts/build-loop.sh, test/lib/build-loop-fixtures.bash, test/scripts/build-loop-read.bats, and commit messages 0797ed32, 224dd52d, 30676e57, 0ae7d801 (replicate r2 of 3)
**Checked:** 2026-10-05
**Total claims checked:** 31
**Summary:** 27 verified, 2 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first. Its recurring class is "a specific measured value quoted from a checked-in artifact set that does not contain it" (test counts, line counts). The commit 0ae7d801 line counts (426, 398) were checked against it and hold (Claim 29a). The two Incorrect verdicts are about what tests catch, not invented symbols, so the log is not appended.

Execution logs (scratch dir, outside the repo): `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i2/fc-r2/`
- `bats.log`: `cd /workspace/.claude/wt-build-loop-u1b && LC_ALL=C.UTF-8 bats test/scripts/build-loop-read.bats test/scripts/dev-cycle.bats`, exit 0, 75/75 ok (9 + 66), 2026-10-05T11:1xZ (timestamp is the first line of the log).
- `probe1.sh` / `probe1.log`: `timeout 120 bash probe1.sh` (cwd: the scratch dir; it builds the repo `p/`), exit 0, 2026-10-05T11:11:59Z. Covers never-line and key-strip edge cases, `-h` output, and whether .git is left unchanged.
- `probe2.sh` / `probe2.log`: `timeout 60 bash probe2.sh` (repo `q/`), exit 0, 2026-10-05T11:12:58Z. Covers exit codes: no perl, `-h`, `--help x`, an empty repo.
- `mutations.sh` / `mutations.log`: `timeout 500 bash mutations.sh` (a copy in `copy/`; the worktree is never touched), exit 0, 2026-10-05T11:13:12Z. Mutants: M1 reverts A4, M2 reads the working tree, M3 drops IFS=' ', M4 drops the tab test, M5 drops both. Each runs against the HEAD tests and, where stated, the 30676e57 tests.
- `andlist.bats`: a bats 1.8.2 check that a failing left operand of `&&` on a non-final line of a test does not fail the test.

---

## Claim 1: "It is set only when exactly one line, outside code fences, starts "Build-loop policy:" and reads exactly "Build-loop policy: self-merge" or "Build-loop policy: review" (one trailing CR is dropped). Any other case, or a malformed never line, means review."

**Location:** `scripts/build-loop.sh:12-17`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count-then-exact-match rule, the CR drop, and the malformed-never override over the policy line. It does not establish that "starts" means only a literal column-0 start: "starts" is widened by the prefix strip in Claim 5.
**Legibility-target:** for-orchestrator-synthesis

The awk drops one trailing CR, `{ sub(/\r$/, "") }` (`scripts/build-loop.sh:102`). read_settings then requires a count of 1 and an exact match: `elif [[ "${cnt[policy]}" -gt 1 ]]; then POLICY_LINE="policy review unset: ...` and `elif [[ "${text[policy]}" =~ ^Build-loop\ policy:\ (self-merge|review)$ ]]` (`scripts/build-loop.sh:173-174`). The malformed-never override is at `:176-177` (Claim 19). T1 and T2 pass (bats.log), covering the CR, case, trailing-space, double-space, suffix, and duplicate variants.

**Evidence:** `scripts/build-loop.sh:102`, `scripts/build-loop.sh:172-179`, `test/scripts/build-loop-read.bats:13-40`, bats.log

---

## Claim 2: "How many build loops may run at once: one line "Build-loop slots: N" with N from 1 to 9, else 3."

**Location:** `scripts/build-loop.sh:18-19`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 1–9 range, the exact-line rule, and the default of 3 for missing, duplicate, or malformed lines. It does not establish how a later mode uses the slot count.
**Legibility-target:** for-orchestrator-synthesis

The code reads `elif [[ "${text[slots]}" =~ ^Build-loop\ slots:\ ([123456789])$ ]]; then SLOTS_LINE="slots ${BASH_REMATCH[1]} set: ...` (`scripts/build-loop.sh:182`). Every other branch prints `slots 3 default`. The slots test passes with 0, 10, `3 `, 05, three, a duplicate line, and a fenced line (bats.log).

**Evidence:** `scripts/build-loop.sh:180-183`, `test/scripts/build-loop-read.bats:87-98`, bats.log

---

## Claim 3: Self-merge never: grammar: "(single spaces, no tab; each glob uses letters, digits, . _ - / * ?, with an optional trailing /; no empty, . or .. part, not starting / or -; none twice, a trailing / ignored)"

**Location:** `scripts/build-loop.sh:20-25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed rule, executed one at a time. It does not establish that "letters" means only ASCII letters; it does (NAMECHARS lists a–z and A–Z), and the header does not say so.
**Legibility-target:** for-orchestrator-synthesis

Whitespace check: `"$v" == *[$'\t\v\f\r']* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$` (`:157`). Per entry: `globform "${g%/}"` and `seen[${g%/}]` (`:164-166`). globform itself is `[[ "$1" =~ ^[*?$NAMECHARS]+$ && "$1" != /* && "$1" != -* ]]` plus the part loop `[[ -n "$c" && "$c" != "." && "$c" != ".." ]]` (`:124-127`).

Executed in probe1.log, all malformed as claimed: `a\vb` ("single spaces"), `a//` (empty part), `a/b/ a/b` ("lists entry 2 twice"), and `a\b` (not an allowed glob form). T45 covers the tab, `..`, `/etc`, `-x`, `./b`, `a a/`, and `café/` cases. `lib/ *`, `* lib/` and `a ?` are accepted.

**Evidence:** `scripts/build-loop.sh:122-128`, `scripts/build-loop.sh:154-170`, probe1.log, `test/scripts/build-loop-read.bats:107-116`

---

## Claim 4: "A malformed line, or a settings file that is not read, turns self-merge off."

**Location:** `scripts/build-loop.sh:26-27`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the malformed paths (duplicate, bad form) and the file-not-read paths (refused, unbalanced, not a regular file, notdir). It does not cover an absent file, which prints `never none`; policy is still review there because no policy line exists.
**Legibility-target:** for-orchestrator-synthesis

For a file that is not read: `POLICY_LINE="policy review unset: $why"` with `NEVER_LINE="never malformed: $why"` unless the file is absent (`:140-143`). For a malformed line, `never_ok=""` makes self-merge refused (`:176-177`). T3 (an open comment gives both lines) and T45 pass.

**Evidence:** `scripts/build-loop.sh:139-143`, `scripts/build-loop.sh:176-178`, `test/scripts/build-loop-read.bats:46-49`, bats.log

---

## Claim 5: "A line outside a fence counts as a settings line when it starts with the key (any case) after any blanks, >, list markers, # * _ ` ~ and byte-order marks, so a quoted, bold, heading or indented copy is a second line, not a hidden one."

**Location:** `scripts/build-loop.sh:28-31`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every prefix the claim lists and the four named copy shapes (quoted, bold, heading, indented), plus numbered lists and tab indents. It does NOT establish that every Markdown rendering of the key is counted. Four shapes that render with the key text are still uncounted (hidden), executed in probe1.log, where policy stays `self-merge set` beside them: a task-list item `- [ ] Build-loop policy: review`, a table cell `| Build-loop policy: review |`, link text `[Build-loop policy: review](x)`, and an NBSP-indented line `\xc2\xa0Build-loop policy: review`. "Any case" is ASCII-only (awk under LC_ALL=C).
**Legibility-target:** for-author

The strip is `match(s, /^([ \t>#*_`~]|[-+][ \t]|[0123456789]+[.)][ \t]|\357\273\277)*/)` (`:106`), followed by `s = tolower(s)` (`:107`). In probe1.log, `1. `, `* `, `+ `, tab, and `~~` copies are counted. Lines like `+Build-loop` and `1.Build-loop` are not, which is correct because they are not list markers. The four uncounted shapes above are outside what the sentence promises. A reader taking "not a hidden one" as a general guarantee should know about them. The fix would be to strip `[ ] `/`[x] ` and `|`, or to say the guarantee covers only the named shapes.

**Evidence:** `scripts/build-loop.sh:104-112`, probe1.log, `test/scripts/build-loop-read.bats:33-36`, `test/scripts/build-loop-read.bats:119-123`

---

## Claim 6: "A file the lib's FENCE_AWK refuses (its comment lists each shape) is not read at all, and the line printed says why."

**Location:** `scripts/build-loop.sh:31-33`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers refusal via SETTINGS_AWK's `odd`/`unbalanced` END output and that all three lines carry the reason. It does not establish that FENCE_AWK's comment matches FENCE_AWK (lib, U0/U1a scope).
**Legibility-target:** for-orchestrator-synthesis

`odd\ *) ... FILE_WHY="line $n of $f $(oddwhy "$why"), so the file is not read"; return 1` (`:91`). read_settings then puts `$why` in POLICY_LINE, SLOTS_LINE and NEVER_LINE (`:140-143`). T3 asserts the open-comment, BOM, and unbalanced-fence reasons on the policy line and the never line.

**Evidence:** `scripts/build-loop.sh:89-93`, `scripts/build-loop.sh:139-143`, `test/scripts/build-loop-read.bats:46-53`

---

## Claim 7: "Acts on $PWD's git repo ... Read-only: writes nothing."

**Location:** `scripts/build-loop.sh:35-36`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the --settings path. Its git calls are rev-parse, symbolic-ref, show-ref, ls-tree and cat-file, and .git's recursive listing with mtimes is unchanged across a run. It does not establish read-only behavior for modes not yet written (U1c).
**Legibility-target:** for-orchestrator-synthesis

probe1.log ends `.git unchanged`. The script contains no redirect to a file other than `>/dev/null` (`:45`); this is paraphrased — no quote available because the claim covers the absence of write code across the file, checked by reading `scripts/build-loop.sh:1-192`.

**Evidence:** `scripts/build-loop.sh:45-71`, `scripts/lib/dev-cycle-read.sh:256-267`, probe1.log

---

## Claim 8: "Output passes through the lib's scrub (all but the two start-up errors before it, about perl and the lib, which carry no repo text)"

**Location:** `scripts/build-loop.sh:37-39`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order: the perl check (`:45`) and the lib check (`:51`) run before `scrub_reexec` (`:54`), and everything after, including usage errors and `-h`, runs in the scrubbed child. It does not establish the scrub's own coverage (lib comment, U0 scope).
**Legibility-target:** for-orchestrator-synthesis

`command -v perl >/dev/null || { echo "build-loop.sh needs perl (to scrub its output)" >&2; exit 1; }` (`:45`). `[[ -f "$READ_LIB" ]] || { echo "build-loop.sh needs $READ_LIB" >&2; exit 1; }` (`:51`). `scrub_reexec "${BASH_SOURCE[0]}" "$@"` (`:54`). probe2.log shows the unscrubbed perl error and exit 1.

**Evidence:** `scripts/build-loop.sh:43-54`, `scripts/lib/dev-cycle-read.sh:76-81`, probe2.log

---

## Claim 9: "Exit: 0 every line printed; 1 bad usage, not a git repo, no perl or lib/dev-cycle-read.sh, or no default branch found by name."

**Location:** `scripts/build-loop.sh:40-41`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every exit-1 cause listed: no perl, empty repo, and no default branch in probe2.log; usage, non-repo, and missing lib in the bats tests. It does not establish exit behavior for ls-tree or cat-file failures (those return through main_file's `*)` arm and still exit 0).
**Legibility-target:** for-author

All listed causes hold. The list omits the help path: `-h|--help) sed -n '2,41p' "$0" | ...; exit 0` (`:60`) exits 0 with help, not "every line" of --settings, and `--help x` also exits 0 (probe2.log). The extra-argument case is settled Won't-Fix in the override log. The precise version would add "0 also for -h/--help".

**Evidence:** `scripts/build-loop.sh:56-71`, probe2.log, `test/scripts/build-loop-read.bats:134-150`

---

## Claim 10: help range `sed -n '2,41p'` covers the header

**Location:** `scripts/build-loop.sh:60`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers lines 2–41 being the whole comment header: line 41 is the last `#` line, and line 42 is blank. It does not establish that the range stays right when U1c edits the header.
**Legibility-target:** for-orchestrator-synthesis

`-h` prints 40 lines, starting "The build-loop handoff's state and checks" and ending "lib/dev-cycle-read.sh, or no default branch found by name." (probe1.log). Line 42 is empty and line 43 is `set -euo pipefail` (`cat -A` of `:40-46`).

**Evidence:** `scripts/build-loop.sh:1-43`, probe1.log

---

## Claim 11: main_file: "sets FILE_WHY and returns 1 when it is absent ("absent"), stored as anything but a regular file under plain directories, or refused by FENCE_AWK; otherwise FILE_OUT holds what the awk program $2 printed over it (FENCE_AWK is prepended ...)"

**Location:** `scripts/build-loop.sh:73-77`
**Type:** Behavioral / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the four `main_entry` outcomes and the two awk refusal shapes. It does not establish ls-tree failure behavior beyond the misattributed reason described below.
**Legibility-target:** for-author

The code is:

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
(excerpt ends :88; enclosing main_file() continues to :94 — read)

main_entry can also print `error` when ls-tree fails: `out="$(git ls-tree ...)" || { echo error; return; }` (`scripts/lib/dev-cycle-read.sh:261`). That falls into `*)` and is reported as "is not a regular file on the default branch". It still returns 1 and fails closed. The comment's list leaves out this fourth cause, and the printed reason is wrong for it (check_brief/check_answer print a distinct "could not be read" for `error`). On refusal, FILE_OUT keeps the `odd ...` text, which is consistent with "otherwise".

**Evidence:** `scripts/build-loop.sh:73-94`, `scripts/lib/dev-cycle-read.sh:256-267`, `scripts/lib/dev-cycle-read.sh:321-327`

---

## Claim 12: SETTINGS_AWK comment: "per key, how many lines start with it (after blanks, >, list markers, heading and emphasis marks (# * _ ` ~) and a BOM, any case), the first two line numbers and the first line whole: "KEY COUNT FIRST SECOND<TAB>LINE"."

**Location:** `scripts/build-loop.sh:96-99`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regex at `:106` (every listed prefix strips) and the END format `k " " c[k] " " l1[k] " " (k in l2 ? l2[k] : 0) "\t" t[k]` (`:116`). "The first line whole" is `$0` after the CR drop. For the residue (task list, table, link, NBSP still uncounted), see Claim 5.
**Legibility-target:** for-orchestrator-synthesis

The regex is `/^([ \t>#*_`~]|[-+][ \t]|[0123456789]+[.)][ \t]|\357\273\277)*/` (`:106`), and `t[k] = $0` (`:111`). probe1.log confirms the strip for each listed class.

**Evidence:** `scripts/build-loop.sh:96-117`, probe1.log

---

## Claim 13: globform: "pathform's characters and glob marks, not starting / or -, no empty, . or .. part. Unlike pathform it allows a part starting .git (.github/, .gitignore): the list only adds refusals ..."

**Location:** `scripts/build-loop.sh:118-121`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers globform matching `pathform(..., glob)` minus the `[.][gG][iI][tT]*` part test (`scripts/lib/dev-cycle-read.sh:142-147`). It does not establish what a later reader (U2 gate) does with such entries.
**Legibility-target:** for-orchestrator-synthesis

globform uses the same `^[*?$NAMECHARS]+$` and part loop, without the `.git` test (`:124-127`). As the comment's "a part starting .git" implies, `.git/`, `.GIT` and `.git/x` are accepted too (probe1.log: `never .git/ .GIT .git/x set`). This is harmless under the stated rationale, because the list only adds refusals.

**Evidence:** `scripts/build-loop.sh:118-128`, `scripts/lib/dev-cycle-read.sh:139-149`, probe1.log

---

## Claim 14: "Sets POLICY, POLICY_LINE, SLOTS_LINE, NEVER (the globs, or empty) and NEVER_LINE from main's commit."

**Location:** `scripts/build-loop.sh:130-132`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which globals are set on each path. It does not verify the forward-looking clause "for the modes that judge a brief (--status, then the gate)" (U1c/U2, not written). An empty NEVER does not by itself distinguish "none" from "malformed"; malformed is signalled through POLICY staying review.
**Legibility-target:** for-orchestrator-synthesis

The defaults are `POLICY=review; POLICY_LINE=""; SLOTS_LINE=""; NEVER=""; NEVER_LINE=""` (`:133`). NEVER is set only on success: `else NEVER="$v"; NEVER_LINE="never $v set: ..."` (`:170`). POLICY is set only at `:178`. Every branch sets all three *_LINE values (read through `:136-185`).

**Evidence:** `scripts/build-loop.sh:130-185`

---

## Claim 15: "An absent file sets nothing; one that is not read turns self-merge off."

**Location:** `scripts/build-loop.sh:142`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `never none` vs `never malformed` split at `:143`. Claim 4 covers the effect on POLICY.
**Legibility-target:** for-orchestrator-synthesis

`if [[ "$FILE_WHY" == absent ]]; then NEVER_LINE="never none: $why"; else NEVER_LINE="never malformed: $why"; fi` (`:143`). T3 asserts `never none: no docs/dev-cycle.md on the default branch` and the malformed open-comment case.

**Evidence:** `scripts/build-loop.sh:139-143`, `test/scripts/build-loop-read.bats:48,57`

---

## Claim 16: "Single spaces only: a tab or other blank would split differently in a later reader." (with the check refusing tab, VT, FF, CR)

**Location:** `scripts/build-loop.sh:156-157`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers tab, VT, FF, and CR, and runs of spaces. Other blanks such as NBSP pass this check but are refused by globform's ASCII class. CR cannot reach here, because the awk drops a trailing CR and FENCE_AWK refuses an internal one.
**Legibility-target:** for-orchestrator-synthesis

The check is `"$v" == *[$'\t\v\f\r']* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$` (`:157`). T45's four tab cases pass. In probe1.log, `a\vb` gives "is not exactly ... with single spaces".

**Evidence:** `scripts/build-loop.sh:154-160`, probe1.log, bats.log

---

## Claim 17: "IFS=' ' read -ra parts <<<"$v"  # not a bare $v: the shell would expand * and ? against files"

**Location:** `scripts/build-loop.sh:161`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that pathname expansion is on: the script sets only `set -euo pipefail` (`:43`), with no `set -f`, so an unquoted `for g in $v` would glob against files in the cwd (the repo root after `cd "$ROOT"`). It does not establish anything beyond bash's documented word-splitting and pathname-expansion order.
**Legibility-target:** for-orchestrator-synthesis

`set -euo pipefail` (`:43`). `read -ra` with a here-string does no pathname expansion. probe1.log shows `lib/ *` stored verbatim as `never lib/ * set`.

**Evidence:** `scripts/build-loop.sh:43`, `scripts/build-loop.sh:161-167`, probe1.log

---

## Claim 18: "a" and "a/" count as the same entry for "none twice"; the stored NEVER value

**Location:** `scripts/build-loop.sh:163-170`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the duplicate key `${g%/}` and that NEVER/NEVER_LINE store the raw `$v` (trailing slashes as written), while validation ran on `${g%/}`. It does not establish how U2 will match the stored globs.
**Legibility-target:** for-orchestrator-synthesis

The code is `if [[ -n "${seen[${g%/}]-}" ]]; then why="lists entry $i twice"; break; fi` / `seen[${g%/}]=1` (`:165-166`), then `NEVER="$v"` (`:170`). T45 rejects `a a/`, and probe1.log rejects `a/b/ a/b` as "entry 2 twice". A `*` key in the associative array is literal: `lib/ *` and `* lib/` are both accepted (probe1.log), so the `seen[*]` all-elements expansion does not happen here.

**Evidence:** `scripts/build-loop.sh:161-170`, probe1.log

---

## Claim 19: "self-merge with a malformed never line prints policy review unset" and POLICY stays review

**Location:** `scripts/build-loop.sh:176-178`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both malformed paths (count > 1 at `:153`, bad form at `:169`), which both clear `never_ok`, and that POLICY is assigned only in the `else` branch. It does not cover the file-not-read path, which Claim 4 covers.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/build-loop.sh:176-178
      if [[ "$v" == self-merge && -z "$never_ok" ]]; then
        POLICY_LINE="policy review unset: line ${first[policy]} reads self-merge, but the Self-merge never: line is malformed, so self-merge is off"
      else POLICY="$v"; POLICY_LINE="policy $v set: line ${first[policy]} $where"; fi
```
(excerpt ends :178; enclosing read_settings() continues to :185 — read)

T45's loop asserts this exact line for all 15 malformed values.

**Evidence:** `scripts/build-loop.sh:151-179`, `test/scripts/build-loop-read.bats:110-113`, bats.log

---

## Claim 20: "a throwaway repo under $BATS_TEST_TMPDIR with a main branch, the same hermetic git environment as test/scripts/dev-cycle.bats"

**Location:** `test/lib/build-loop-fixtures.bash:2-4`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the GIT_CONFIG_GLOBAL, GIT_CONFIG_NOSYSTEM, author/committer, and HOME exports matching `test/scripts/dev-cycle.bats:11-15`. The fixture also adds `LC_ALL=C`, which dev-cycle.bats does not set in that block.
**Legibility-target:** for-orchestrator-synthesis

`export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1` ... `export HOME="$BATS_TEST_TMPDIR/home" LC_ALL=C` (`test/lib/build-loop-fixtures.bash:13-16`). The dev-cycle.bats side is `export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1` ... `export HOME="$BATS_TEST_TMPDIR/home"` (`test/scripts/dev-cycle.bats:11-15`).

**Evidence:** `test/lib/build-loop-fixtures.bash:6-20`, `test/scripts/dev-cycle.bats:9-17`

---

## Claim 21: "settings_is KEY WANT / settings_like KEY PREFIX: run --settings; its KEY line must equal WANT, or start with PREFIX. On a mismatch, print the whole output."

**Location:** `test/lib/build-loop-fixtures.bash:30-31`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the helpers' own behavior: they return 1 and print on a mismatch. It does not establish that a mismatch fails the calling test. A helper used as the left operand of `&&` on a non-final test line is not enforced; see Claim 29b.
**Legibility-target:** for-orchestrator-synthesis

`settings_like() { run --separate-stderr bash "$BL" --settings; [[ "$(line "$1")" == "$2"* ]] || { echo "want: $2..."; echo "$output $stderr"; return 1; }; }` (`:34`). mutations.log M2 shows the printed "want: policy review set:..." block.

**Evidence:** `test/lib/build-loop-fixtures.bash:30-38`, mutations.log

---

## Claim 22: test titles T1, T2, T3, T3/G19, slots, and usage/exit codes describe what they assert

**Location:** `test/scripts/build-loop-read.bats:13,24,42,69,87,134`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each title against its body and a passing run. G19 reads the real `docs/dev-cycle.md:7` (`Build-loop policy: review (interim; Q-103)`), and its "unset by the interim note" holds. It does not establish the discriminating power of each assertion beyond what is read.
**Legibility-target:** for-orchestrator-synthesis

All 9 tests pass (bats.log). The real file line 7 reads `Build-loop policy: review (interim; Q-103)` (`docs/dev-cycle.md:7`), which matches the G19 assertion `"policy review unset: line "*' is not exactly ...'` (`:73`).

**Evidence:** `test/scripts/build-loop-read.bats:13-98,134-150`, `docs/dev-cycle.md:7`, bats.log

---

## Claim 23: "--settings reads main's commit: the working tree and other branches never decide (T4)"

**Location:** `test/scripts/build-loop-read.bats:77-85`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the script's behavior and that T4 fails under a working-tree-reading mutant (M2). It does NOT establish that every T4 step is enforced: the first conjunct of `:80` (`settings_like policy "policy review set:" && ...`) is on a non-final line, so its failure is ignored. M2 is caught only by the final line `:84`.
**Legibility-target:** for-orchestrator-synthesis

mutations.log M2: T4 fails at line 84. The "want: policy review set:..." output from `:80` is printed but does not fail the test there.

**Evidence:** `test/scripts/build-loop-read.bats:77-85`, mutations.log, andlist.bats

---

## Claim 24: no-echo check: malformed entries are never echoed (A3: "now also checks plain-ASCII malformed entries")

**Location:** `test/scripts/build-loop-read.bats:114-115`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the discriminating cases `../x`, `/etc`, `-x`, `./b` and `\xc3`. It does not discriminate for `a b a`, `a a/`, `a  b` or the tab cases, whose entries (`a`, `b`) appear in any output. Never echoing these is still true in code (NEVER_LINE malformed prints only `line N $why`, `:169`).
**Legibility-target:** for-orchestrator-synthesis

`[[ "$output" != *$'\xc3'* && "$output" != *../x* && "$output" != */etc* && "$output" != *-x* && "$output" != *./b* ]]` (`:114`). The never-echo path is `NEVER_LINE="never malformed: line ${first[never]} $why"` (`scripts/build-loop.sh:169`).

**Evidence:** `test/scripts/build-loop-read.bats:107-116`, `scripts/build-loop.sh:169`

---

## Claim 25: "build-loop.sh sources the lib from its own directory, never the target repo's; without it, exit 1" and "From a subdirectory and from a linked worktree, it reads the same main." (G16, G20)

**Location:** `test/scripts/build-loop-read.bats:152-167`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the planted `echo PLANTED` lib, which is discriminating (if sourced, output would contain PLANTED and scrub_reexec would be undefined). It also covers the bare copy's error and exit 1, and a successful run from `sub/` and a linked worktree. It does NOT establish that the worktree run reads main rather than its own working tree: the worktree `wt` is created from main with identical content, so the subdirectory and worktree half is a smoke test, not a discriminating one.
**Legibility-target:** for-orchestrator-synthesis

`READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"` (`scripts/build-loop.sh:50`). `git worktree add -q -b wt "$BATS_TEST_TMPDIR/wt" main` (`:162`). The test passes (bats.log).

**Evidence:** `scripts/build-loop.sh:46-54`, `test/scripts/build-loop-read.bats:152-167`, bats.log

---

## Claim 26: commit 0797ed32: failing tests for the policy line, slots, Self-merge never: ("never echoed"), usage and exit codes, lib from the script's own directory (G16), subdirectory and linked worktree (G20)

**Location:** `0797ed32 (commit message)`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the listed test areas exist in the bats file at HEAD. It does not re-run the tests at 0797ed32 to confirm they failed then.
**Legibility-target:** for-orchestrator-synthesis

The test titles at `test/scripts/build-loop-read.bats:13,24,42,69,77,87,100,134,152` match the list; this is paraphrased — no quote available because the claim is a list of nine test areas mapped across the whole file.

**Evidence:** `test/scripts/build-loop-read.bats:13-167`

---

## Claim 27: commit 224dd52d Notes: "A policy of self-merge with a malformed never line prints "policy review unset", so the policy line always shows the policy in force."

**Location:** `224dd52d (commit message)`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the HEAD behavior (Claim 19). Its body's key-strip description ("after blanks, > and list markers") was widened by 30676e57; that is history, not drift, and is not verdicted. "Byte-exact" is settled Won't-Fix.
**Legibility-target:** for-orchestrator-synthesis

See Claim 19's quoted `scripts/build-loop.sh:176-178`.

**Evidence:** `scripts/build-loop.sh:176-178`, bats.log

---

## Claim 28: commit 30676e57 bullets (R1/A1 tab/VT/FF/CR malformed and IFS=' ' split; A2 # * _ ` ~ and BOM strip; A3 plain-ASCII no-echo; A4 globform allows .github/.gitignore; "a" and "a/" same entry; header changes) and "The wider key strip fails closed: a prose line starting "**Build-loop policy:**" now unsets the policy."

**Location:** `30676e57 (commit message)`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each code bullet against HEAD (Claims 3, 5, 13, 16, 18, 24), and that the A4 test as written at 30676e57 caught an A4 revert (mutations.log). It does not cover the header bullet's FENCE_AWK detail ("which apply outside a fence ... BOM refusal is line 1 only"), which 0ae7d801 replaced with a pointer to FENCE_AWK and so no longer appears at HEAD. "Fails closed" holds because the strip can only add counted lines, a count above 1 unsets policy and marks never malformed, and a single counted line must still match `$0` exactly.
**Legibility-target:** for-orchestrator-synthesis

`settings 'Build-loop policy: self-merge' "$c"` with `'**Build-loop policy:** review'` gives `more than one line starts` (`test/scripts/build-loop-read.bats:33-35`). With 30676e57's tests, the M1 (A4 reverted) run fails at old-read.bats line 155 (mutations.log).

**Evidence:** `scripts/build-loop.sh:106`, `scripts/build-loop.sh:124-127`, `scripts/build-loop.sh:157-166`, mutations.log

---

## Claim 29a: commit 0ae7d801: "The review fixes took U1b to 426 changed code lines ... U1b is 398 lines."

**Location:** `0ae7d801 (commit message)`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers insertions over the three code files, from u1a's tip to 30676e57 and to HEAD. It does not establish how pr-prep's cap counts lines. Checked against the hallucination log's measured-value pattern; no match.
**Legibility-target:** for-orchestrator-synthesis

`git diff --shortstat feat/build-loop-u1a 30676e57 -- <3 files>` gives `3 files changed, 426 insertions(+)`. `git diff --stat feat/build-loop-u1a...feat/build-loop-u1b` gives `398 insertions(+)` (run in the worktree, exit 0; output in this session's transcript, reproduced by the same commands).

**Evidence:** `scripts/build-loop.sh:1-192`, `test/lib/build-loop-fixtures.bash:1-38`, `test/scripts/build-loop-read.bats:1-168`

---

## Claim 29b: commit 0ae7d801: "Two test helpers replace the repeated three-line ... blocks ... No assertion was dropped"

**Location:** `0ae7d801 (commit message)`; affected `test/scripts/build-loop-read.bats:80,126`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether every pre-refactor assertion still fails its test when violated. It does not claim that any assertion text was deleted; every assertion is still written.
**Legibility-target:** for-author

The refactor split single `[[ A && B ]] || { ...; return 1; }` assertions into `settings_like A && settings_like B` lists. Under bats' errexit, a failing left operand of `&&` that is not the test's final command does not fail the test (andlist.bats: `false && true` mid-test → `ok`). Two left operands are therefore no longer enforced:

```bash
# test/scripts/build-loop-read.bats:80
    settings_like policy "policy review set:" && settings_like slots "slots 3 default:"
# test/scripts/build-loop-read.bats:126
    settings_like never "never .github/ .gitignore set:" && settings_like policy "policy self-merge set:"
```

The `:126` case drops the only test guard for review finding A4. With globform's `.git*` refusal restored (M1), the HEAD T45 passes (`ok 1 ... (T45)`), while 30676e57's T45 fails at its line 155 (mutations.log). For `:80`, the working-tree mutant M2 is still caught, but only by the final line `:84`. What to fix: make each `&&` list a separate statement, or end each with `|| return 1`.

**Evidence:** `test/scripts/build-loop-read.bats:77-85`, `test/scripts/build-loop-read.bats:124-126`, `test/lib/build-loop-fixtures.bash:33-34`, mutations.log, andlist.bats

---

## Claim 29c: commit 0ae7d801: "A mutation check: without the IFS=' ' split, T45 fails on the tab cases; the explicit tab test is a second guard (globform also refuses a tab inside an entry)."

**Location:** `0ae7d801 (commit message)`; code `scripts/build-loop.sh:157,161`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three mutants M3 (no IFS=' '), M4 (no tab test) and M5 (both) against HEAD's T45. It does not establish behavior under other mutants.
**Legibility-target:** for-author

mutations.log:
- **M3**, IFS=' ' removed (`read -ra parts <<<"$v"`): T45 passes (`ok 1`).
- **M4**, tab test removed: T45 passes.
- **M5**, both removed: T45 fails at the tab cases (`settings_like never "never malformed: line 2 "` failed).

Removing the IFS=' ' split alone does not fail T45, because the explicit tab check `"$v" == *[$'\t\v\f\r']*` (`:157`) refuses every tab case before the split at `:161` is reached. The roles are the reverse of what the message says. The tab test is the first guard. The IFS=' ' split together with globform's refusal of a tab inside an entry is the second guard, and it matters only if the tab test is removed. Each guard alone is sufficient for T45.

**Evidence:** `scripts/build-loop.sh:154-167`, mutations.log

---

## Claims Requiring Attention

### Incorrect
- **Claim 29b** (`test/scripts/build-loop-read.bats:80,126`; commit 0ae7d801): "No assertion was dropped" is false in effect. Two `settings_like X && settings_like Y` lines on non-final test lines no longer fail when X fails. The A4 guard (`.github/ .gitignore` accepted) is now unenforced: reverting A4 passes T45. Fix by splitting the `&&` lists or adding `|| return 1`.
- **Claim 29c** (commit 0ae7d801; `scripts/build-loop.sh:157,161`): the mutation claim has the guards reversed. With the tab test present, removing IFS=' ' does not fail T45; only removing both does.

### Mostly Accurate
- **Claim 9** (`scripts/build-loop.sh:40-41`): the exit list omits that `-h`/`--help` (with or without extra arguments) exits 0.
- **Claim 11** (`scripts/build-loop.sh:73-77`): main_file also returns 1 on main_entry `error` (ls-tree failure), and reports it as "is not a regular file on the default branch". The comment and the printed reason omit or misname that case.

### Verified with a residue worth surfacing
- **Claim 5 / 12** (`scripts/build-loop.sh:28-31,106`): task-list `- [ ] KEY`, table `| KEY |`, link `[KEY](x)` and NBSP-indented copies render as the key but are still not counted (probe1.log). The header's promise covers only the four named shapes.
- **Claim 25** (`test/scripts/build-loop-read.bats:160-166`): the linked-worktree check does not tell main apart from the worktree's own tree, because they have identical content.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report in the code-fact-check schema saved at the path below, with `**Commit:** 0ae7d801` at the top, every claim tagged with a Legibility-target, and a Goal-Alignment Note at the end.
- Answered: yes. All 10 requested claim areas were checked, with execution (bats 75/75, probes, five mutants).
- Out of scope: lib-internal claims (FENCE_AWK's comment, the scrub), docs/dev-cycle.md prose (not in the diff), and U1c modes.
- Escalate: Claim 29b, the A4 regression guard silently disabled by the 0ae7d801 refactor. It is a test fix of a few lines but touches the 400-line cap.
- Decisions I made: I verdicted the header's counting sentence (Claim 5) Verified with a named residue rather than Mostly accurate, because it promises only the named shapes. I treated 30676e57's superseded header bullet as history, not as Stale.
