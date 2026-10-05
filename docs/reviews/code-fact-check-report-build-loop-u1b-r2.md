Commit: 2e711a7b

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u1b (branch feat/build-loop-u1b, replicate r2, iteration 4 final confirming pass)
**Scope:** `feat/build-loop-u1a...2e711a7b`: scripts/build-loop.sh, test/lib/build-loop-fixtures.bash, test/scripts/build-loop-read.bats, the 2026-10-05 u1b rows of docs/reviews/override-log.md (rows 256-264 in depth), and commit 2e711a7b's message
**Checked:** 2026-10-05
**Total claims checked:** 32 (30 numbered; 14 and 18 split into a/b)
**Summary:** 27 verified, 1 mostly accurate, 0 stale, 2 incorrect, 2 unverifiable

Execution environment: git 2.39.5, GNU bash 5.2.15, mawk 1.3.4, bats at /usr/bin/bats. The HEAD tree (`git archive 2e711a7b scripts test docs/dev-cycle.md`) was extracted to the scratch dir `S=/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i4/fc-r2`. Every command ran with `LC_ALL=C.UTF-8` (bats) or `LC_ALL=C` (scratch repos), `TMPDIR=$S/tmp`, between 2026-10-05T16:39Z and 16:46Z. Logs are under `$S/logs/`. Harnesses: `$S/run.sh NAME` commits stdin as docs/dev-cycle.md in a fresh repo and runs `--settings`. `$S/rep.sh` builds the replace-ref repo. `$S/mut.sh NAME PERL` copies the tree, mutates scripts/build-loop.sh and runs the suite. Baseline: `cd $S && bats test/scripts/build-loop-read.bats` gave exit 0, 9/9 ok (`$S/logs/baseline.log`).

Hallucination-pattern log: read. None of its entries matches a claim here.

---

## Claim 1: "three lines from the default branch's commit, never the working tree (a build loop can write any working tree)"

**Location:** `scripts/build-loop.sh:9-10`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the blob read in main_file (`$MAIN_SHA:$f`) and the main_entry type check, from the repo root, a subdirectory, a linked worktree and a checked-out loop branch. It does not establish how resolve_main chooses MAIN_SHA when origin/HEAD names a loop branch (override row C18, deferred).
**Legibility-target:** for-orchestrator-synthesis

`scripts/build-loop.sh:89`: `FILE_OUT="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk "$FENCE_AWK$2")"`. The entry check comes first at `:81` (`e="$(main_entry "$f")"`), and main_entry (`scripts/lib/dev-cycle-read.sh:258-275`) runs `git ls-tree -t --full-tree "$MAIN_SHA"`. I applied the mutant `head-not-main` (`$MAIN_SHA:$f` changed to `HEAD:$f`). Tests 5, 7 and 9 failed, so the working-tree, loop-branch and linked-worktree assertions each pin this read.

Command: `cd $S && ./mut.sh head-not-main 's/\$MAIN_SHA:\$f/HEAD:\$f/'`. cwd `$S`, exit 0 (harness), 2026-10-05T16:44Z.

**Evidence:** `scripts/build-loop.sh:78-95`, `scripts/lib/dev-cycle-read.sh:258-275`, `$S/logs/mutants.log`, `$S/logs/baseline.log`

---

## Claim 2: "a second copy, or a file the lib's FENCE_AWK refuses, gives review, 3 and malformed (WHY says which)"

**Location:** `scripts/build-loop.sh:11-12`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers two readings. A second copy of a key gives that key's fail-closed value (policy review, slots 3, never malformed). A FENCE_AWK-refused file gives all three at once. It does not establish that a second copy of one key changes the other two lines, and it does not.
**Legibility-target:** for-orchestrator-synthesis

`scripts/build-loop.sh:153`, `:176`, `:184` map a count over 1 to `never malformed:`, `policy review unset:` and `slots 3 default:` respectively. When the file is refused, `:141-143` set all three, with `never malformed` for any non-absent reason. Executed (`$S/logs/cases1.log`):
- `copy-policy` gives `policy review unset: more than one line starts "Build-loop policy:" (lines 1 and 5)`.
- `copy-slots` gives `slots 3 default: more than one line ...`, and policy stays `self-merge set`.
- `copy-never` gives `never malformed: more than one line ...`.
- `refused` (a `[x]: y` refdef line) gives all three lines carrying the refdef WHY: `policy review unset: line 6 ... so the file is not read` / `slots 3 default: ...` / `never malformed: ...`.

An ABSENT file is a different case. It gives `never none: no docs/dev-cycle.md on the default branch` (`:143`, test 3 `:57-58`). The header does not group absent with "refuses", so this is consistent. The header separately notes that "a file not read" turns self-merge off (claim 8).

Command: `cd $S && printf ... | ./run.sh <case>` (cases copy-policy, copy-slots, copy-never, refused). cwd `$S`, each rc=0, 2026-10-05T16:41Z.

**Evidence:** `scripts/build-loop.sh:139-187`, `$S/logs/cases1.log`

---

## Claim 3: "Set only by "Build-loop policy: self-merge" or "...: review", exactly (one trailing CR dropped); else review."

**Location:** `scripts/build-loop.sh:14-15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regex at `:177` and the CR strip at `:104`. It does not establish the self-merge precondition, which is claim 4.
**Legibility-target:** for-orchestrator-synthesis

`:104` `{ sub(/\r$/, "") }`. `:177` `[[ "${text[policy]}" =~ ^Build-loop\ policy:\ (self-merge|review)$ ]]`. A CR inside a line is refused by FENCE_AWK (`never-cr-mid` case: `holds a carriage return that does not end it, so the file is not read`). Tests T1 (CR line) and T2 (case, trailing blank, double space, suffix) pass at baseline.

Commands: baseline bats run, and `./run.sh never-cr-mid`. cwd `$S`, exit 0, 2026-10-05T16:39-41Z.

**Evidence:** `scripts/build-loop.sh:104`, `:175-182`, `test/scripts/build-loop-read.bats:13-41`, `$S/logs/baseline.log`, `$S/logs/cases1.log`

---

## Claim 4: "Self-merge also needs a valid never line, so a list hidden in markup turns it off rather than being skipped."

**Location:** `scripts/build-loop.sh:15-17` (and `:151`)
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every path that leaves `never_ok` empty: no never line, two or more lines, malformed form, continued line, and the file not read or absent (POLICY is never set on that branch). No input reached `policy self-merge set` without an exact, single, valid never line. It does not establish that a hidden copy NEXT TO an exact never line is noticed. Such a copy is ignored and the exact line governs (`hidden-never-next-exact`: `never none` plus self-merge while a hidden `- [x] Self-merge never: b/` is dropped). That is the shape override row 256 accepts, so it is not re-raised here.
**Legibility-target:** for-orchestrator-synthesis

`never_ok=1` is assigned only at `:172` and `:173`, both after `[[ -n "$why" ]]` failed at `:171`, inside the `cnt[never] == 1` arm. `:179-180`: `if [[ "$v" == self-merge && -z "$never_ok" ]]; then POLICY_LINE="policy review unset: ... so self-merge is off"` (excerpt ends :180; enclosing read_settings() continues to :188, read). The not-read branch `:139-143` never assigns POLICY, and `:137` resets it to review. Executed:
- `- [x] Self-merge never: b/` alone gives policy review (test 7 `:118`).
- The cases `fenced-next`, `comment-next`, `policy-then-never`, `trailing-slash-only`, `slash`, `bom-line5` and `linklabel` all give `policy review unset: line 1 reads self-merge, but there is no valid Self-merge never: line`.
- `hidden-policy-review` (an exact self-merge line plus `- [ ] Build-loop policy: review`) gives review. That is a copy that LOWERS the policy, not one that raises it.

Mutants `never-ok-ignored` (`:179` test made constant) and `copies-set-ok` (`never_ok=1` added on the `cnt>1` arm) both fail test 7.

Commands: `./run.sh <cases>` and `./mut.sh never-ok-ignored ...`, `./mut.sh copies-set-ok ...`. cwd `$S`, exit 0, 2026-10-05T16:41-44Z.

**Evidence:** `scripts/build-loop.sh:134-188`, `$S/logs/cases1.log`, `$S/logs/cases2.log`, `$S/logs/mutants.log`

---

## Claim 5: "Loops at once: "Build-loop slots: N", N from 1 to 9; else 3."

**Location:** `scripts/build-loop.sh:19`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `:185` regex and the defaults at `:183-186`. It does not establish any consumer of the slots value (none exists in this unit).
**Legibility-target:** for-orchestrator-synthesis

`:185` `=~ ^Build-loop\ slots:\ ([123456789])$`. Test 6 (0, 10, trailing space, 05, three, duplicate, fenced) passes at baseline.

**Evidence:** `scripts/build-loop.sh:183-186`, `test/scripts/build-loop-read.bats:93-104`, `$S/logs/baseline.log`

---

## Claim 6: ""Self-merge never: GLOB ..." (or "...: none"), single spaces, and the next line outside a fence blank or the end."

**Location:** `scripts/build-loop.sh:21-23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers fenced lines skipped (`:105` runs before the `pk` check at `:107`), whitespace-only lines, CRLF lines, end of file (`nx[k] = 1` at `:112`), and a one-line HTML comment counting as non-blank. It does not establish the same rule for the policy or slots keys. `nx` is computed for them but unused, as override row 264 accepts.
**Legibility-target:** for-orchestrator-synthesis

`:105` `fence($0) { next }`, `:107` `if (pk != "") { nx[pk] = ($0 ~ /^[ \t]*$/); pk = "" }`, `:159` gives the WHY. Executed:
- `fenced-next` (never line, fenced block, then `b/`) gives `never malformed: line 2 is followed by a non-blank line outside a fence`.
- `fenced-next-blank` (fence, then a blank line) gives `never a/ set`.
- `ws-next` (spaces and a tab) gives set.
- `crlf-next` gives set.
- `eof` (no trailing newline) gives set.
- `comment-next` (`<!-- x -->`) gives malformed.

Mutant `drop-next-check` fails test 7.

**Evidence:** `scripts/build-loop.sh:103-118`, `:154-174`, `$S/logs/cases1.log`, `$S/logs/mutants.log`

---

## Claim 7: "A glob uses letters, digits, . _ - / * ? (a trailing / ignored when comparing), has no empty, . or .. part, does not start with / or -, and is listed once."

**Location:** `scripts/build-loop.sh:23-26`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers globform (`:121-128`) applied to `${g%/}` and the `seen` check (`:166-168`). "A trailing /" means exactly one: `a//` is refused because an empty part remains. It does not establish what `none` means inside a longer list. `Self-merge never: none a/` reads as two globs, `none` and `a/` (`never none a/ set`), and `None` reads as a glob.
**Legibility-target:** for-orchestrator-synthesis

`:123` `[[ "$1" =~ ^[*?$NAMECHARS]+$ && "$1" != /* && "$1" != -* ]]`, `:126` `[[ -n "$c" && "$c" != "." && "$c" != ".." ]]`. NAMECHARS is `abc...XYZ0123456789._/-` (`scripts/lib/dev-cycle-read.sh:139`). Test 7's loop (`:119-127`) and the cases `trailing-slash-only` and `slash` (both malformed) pass as stated. `a a/` is "twice".

**Evidence:** `scripts/build-loop.sh:121-128`, `:160-169`, `scripts/lib/dev-cycle-read.sh:139`, `$S/logs/cases1.log`

---

## Claim 8: "Malformed (or a file not read) turns self-merge off." / ":142 An absent file sets nothing; one that is not read turns self-merge off."

**Location:** `scripts/build-loop.sh:26-27`, `scripts/build-loop.sh:142-143`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the not-read branch (refused, notdir, notfile, error, failed cat-file all print `never malformed`) and absent (`never none`, with policy unset anyway). It does not establish the error and failed-read arms by test in this suite (override row 260 defers that to the lib's tests).
**Legibility-target:** for-orchestrator-synthesis

`:143` `if [[ "$FILE_WHY" == absent ]]; then NEVER_LINE="never none: $why"; else NEVER_LINE="never malformed: $why"; fi`. Executed: test 3 `:49` (open comment) and `:58` (absent), plus `refused` in cases1.

**Evidence:** `scripts/build-loop.sh:139-143`, `test/scripts/build-loop-read.bats:43-68`, `$S/logs/cases1.log`

---

## Claim 9: "Copies are found best effort: a line counts as one when its letters alone, case folded, start with the key's ("buildlooppolicy"). Markup that adds letters (a task box, a tag) can still hide a copy; only an exact line ever sets a value." and ":98-99 (best effort: most markup, a BOM or a misplaced colon cannot hide a copy)"

**Location:** `scripts/build-loop.sh:28-31`, `scripts/build-loop.sh:97-99`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers SETTINGS_AWK's key match and the exact-line regexes for all three keys. It does not establish detection of entities, zero-width characters or letter-adding markup. The header names that residue, and override rows 256 and C19 accept it.
**Legibility-target:** for-orchestrator-synthesis

`:108-111`: `s = tolower($0); gsub(/[^a-z]/, "", s)` then `index(s, "buildlooppolicy") == 1`. A prose line `Build-loop policy is described above.` counts as a copy (`prose` case gives review; fail closed). A BOM on line 5 (`bom-line5`) and a link label `[Self-merge never](x): b/` (`linklabel`) count as copies. Setting values requires `:157`, `:177` or `:185` exact matches.

**Evidence:** `scripts/build-loop.sh:103-118`, `:155-158`, `:177`, `:185`, `$S/logs/cases1.log`, `$S/logs/cases2.log`

---

## Claim 10: "Read-only: writes nothing."

**Location:** `scripts/build-loop.sh:34`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers one `--settings` run on a clean scratch repo: no file or mtime under .git changed. It does not establish a dirty-index repo, where no command here refreshes the index (paraphrased, no quote available because this is an absence claim: no `git status`, `update-index` or write command appears in the script, by reading `:40-195`).
**Legibility-target:** for-orchestrator-synthesis

Command: `cd $S/repos/fridays && ls -laR .git (before) ; bash $S/scripts/build-loop.sh --settings ; ls -laR .git (after) ; diff`. cwd `$S/repos/fridays`, rc=0, diff empty, 2026-10-05T16:46Z.

**Evidence:** `scripts/build-loop.sh:40-195`, `$S/logs/ro-before.txt`, `$S/logs/ro-after.txt`, `$S/logs/ro-diff.txt`

---

## Claim 11: "Output passes through the lib's scrub (but for the start-up errors about perl and the lib)"

**Location:** `scripts/build-loop.sh:35-36`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers ordering: only `:42` and `:48` print before `scrub_reexec` at `:51`. It does not establish the scrub's own coverage (lib, U1a).
**Legibility-target:** for-orchestrator-synthesis

`:42` and `:48` echo to stderr and exit before `:51 scrub_reexec "${BASH_SOURCE[0]}" "$@"`. scrub_reexec (`scripts/lib/dev-cycle-read.sh:76-81`) pipes both stdout and stderr of the re-run child through `scrub`.

**Evidence:** `scripts/build-loop.sh:40-51`, `scripts/lib/dev-cycle-read.sh:76-81`

---

## Claim 12: "Exit: 0 every line printed (or help); 1 bad usage, not a git repo, no perl or lib/dev-cycle-read.sh, or no default branch found by name."

**Location:** `scripts/build-loop.sh:37-38`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listed exits (tests 8 and 9, `-h`, `-h extra` giving 0). It does not establish how a caller's malformed `GIT_CONFIG_COUNT` is reported. `GIT_CONFIG_COUNT=abc` or `=2` without keys breaks git's own config load, and the script exits 1 with "Not inside a git repository" (fail closed, but the stated reason is not the real one).
**Legibility-target:** for-orchestrator-synthesis

Executed: the baseline suite (test 8 `:151-167`, test 9 `:169-176`), `bash scripts/build-loop.sh -h extra` (rc 0) and `rep.sh` rows `count-abc` and `count-2-missing` (rc 1, "Not inside a git repository").

**Evidence:** `scripts/build-loop.sh:53-72`, `$S/logs/baseline.log`, `$S/logs/replace.log`

---

## Claim 13: "the header, to its first non-comment line"

**Location:** `scripts/build-loop.sh:57`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the current file: `-h` output equals lines 2-38 with `# ` stripped. It does not establish the sed range for every header shape. `2,/^[^#]/` needs a non-`#` character to end, so an EMPTY line inside the header does not end it. A later `#` block would print until the first non-empty, non-`#` line. Here that line is `:40` (`set -euo pipefail`), so `:39` (empty) is skipped by `/^#/p` and the result is unaffected.
**Legibility-target:** for-orchestrator-synthesis

Command: `cd $S && bash scripts/build-loop.sh -h > logs/help.out; sed -n '2,38p' scripts/build-loop.sh | sed 's/^# \{0,1\}//' > logs/help.expected; diff`. rc 0, diff empty (37 lines), 2026-10-05T16:40Z.

**Evidence:** `scripts/build-loop.sh:57`, `$S/logs/help.out`, `$S/logs/help.expected`

---

## Claim 14a: "Read main's own objects: a replace ref could swap in any settings blob. core.useReplaceRefs in the repo's config would override the variable"

**Location:** `scripts/build-loop.sh:66-69`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers repo-config `core.useReplaceRefs=true`, plus a caller's GIT_CONFIG_COUNT pair setting it true. In both, the script reads main's own blob. It does not establish the caller's `git -c` / GIT_CONFIG_PARAMETERS channel (claim 14b).
**Legibility-target:** for-orchestrator-synthesis

`rep.sh` built a repo where main's blob says `review` and a replace ref says `self-merge`, with `core.useReplaceRefs true` in .git/config. Plain `git cat-file` and `GIT_NO_REPLACE_OBJECTS=1 git cat-file` both returned `Build-loop policy: self-merge`, so the premise holds and the env var alone does not guard. The script printed `policy review set` for `repo-config-true` and for `caller-count-true` (`GIT_CONFIG_COUNT=1 KEY_0=core.useReplaceRefs VALUE_0=true`). Mutant `no-config-pair` (line `:69` removed) fails test 5.

Command: `timeout 60 $S/rep.sh`. cwd `$S`, rc 0, 2026-10-05T16:43Z.

**Evidence:** `scripts/build-loop.sh:66-70`, `test/scripts/build-loop-read.bats:82-84`, `$S/logs/replace.log`, `$S/logs/mutants.log`

---

## Claim 14b: "add a command-line config pair after any the caller passed."

**Location:** `scripts/build-loop.sh:67-69`
**Type:** Behavioral / Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both command-line config channels git reads. The pair lands after the caller's GIT_CONFIG_COUNT pairs, but BEFORE pairs the caller passed as `git -c` / GIT_CONFIG_PARAMETERS, which git 2.39 reads after GIT_CONFIG_COUNT. It does not establish that any real orchestrator invokes the script under `git -c` or a git alias.
**Legibility-target:** for-author

`:69`: `cfg="${GIT_CONFIG_COUNT:-0}"; export "GIT_CONFIG_KEY_$cfg=core.useReplaceRefs" "GIT_CONFIG_VALUE_$cfg=false" GIT_CONFIG_COUNT=$((cfg + 1))` appends to the GIT_CONFIG_COUNT list only. Executed:
- `GIT_CONFIG_PARAMETERS='x.y'='fromparams'` with `GIT_CONFIG_COUNT=1 KEY_0=x.y VALUE_0=fromcount`, then `git config --get-all --show-origin x.y`, prints `command line: fromcount` and then `command line: fromparams`. The params value comes last and wins.
- `rep.sh` row `caller-params-true` (`GIT_CONFIG_PARAMETERS='core.usereplacerefs'='true'`) printed `policy self-merge set: line 1 ...` and `never none: line 3 ... lists none`. Both come from the replace blob, so policy was raised to self-merge.
- `git -c core.useReplaceRefs=true -c "alias.bl=!bash $S/scripts/build-loop.sh --settings" bl` gave the same self-merge result. A caller that runs the script through any `git -c` alias passes such a pair without setting the env itself.

The guard holds against the repo's own config, which a loop can write (14a). It does not hold against "any the caller passed". Exporting `GIT_CONFIG_PARAMETERS` empty or unset before the pair, or saying "after any GIT_CONFIG_COUNT pairs", would make the comment true.

Commands: `timeout 60 $S/rep.sh` (rc 0), and the two `git config` / `git -c ... bl` commands in `$S/repos/replace` (rc 0). 2026-10-05T16:43-45Z.

**Evidence:** `scripts/build-loop.sh:66-70`, `$S/logs/replace.log`, `$S/logs/config-order.log`

---

## Claim 15: "A file on main: FILE_OUT is what awk program $2 (after FENCE_AWK) printed over it; or it returns 1 with FILE_WHY "absent" or why it was not read (main_entry, a failed read, or FENCE_AWK's "odd N WHY" / "unbalanced N")."

**Location:** `scripts/build-loop.sh:74-76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every arm of main_file (`:78-95`). The absent, notdir, notfile, odd and unbalanced arms were exercised by test 3 and cases1. It does not establish the `error` and failed-read arms by execution in this suite (lib tests cover them, row 260).
**Legibility-target:** for-orchestrator-synthesis

`:82-94` map `absent`, `notdir *`, `error`, `*`, a failed pipeline, `odd *` and `unbalanced *` to FILE_WHY and `return 1`. FENCE_AWK holds functions only, so `$2`'s rules run after it (`scripts/lib/dev-cycle-read.sh:186-229`).

**Evidence:** `scripts/build-loop.sh:74-95`, `scripts/lib/dev-cycle-read.sh:186-245`, `$S/logs/baseline.log`

---

## Claim 16: "whether the line after the first is blank (NEXT 1) or not"

**Location:** `scripts/build-loop.sh:99-100`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what NEXT measures. It does not establish anything about the other parts of the comment (claim 9 covers the best-effort clause).
**Legibility-target:** for-author

NEXT is set on the next line OUTSIDE A FENCE, not the next line: `:105` `fence($0) { next }` runs before `:107`. The `fenced-next-blank` case (never line, then a fenced block, then a blank line) gives `never a/ set`, although the literal next line is a fence opener. Iteration 4 (A21) fixed the header (`:22` "the next line outside a fence") and the WHY (`:159`). This internal comment is unchanged context in the iteration-4 diff (`iter4-fix.diff` line 66 is a context line). It should read "whether the next line outside a fence after the first is blank (or the end)".

**Evidence:** `scripts/build-loop.sh:97-112`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i4/iter4-fix.diff`, `$S/logs/cases1.log`

---

## Claim 17: "A never entry: pathform's rule, but a .git* part (.github/) is allowed"

**Location:** `scripts/build-loop.sh:119-120`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers globform against `pathform ... glob`. They are identical except for the missing `[.][gG][iI][tT]*` test. It does not establish that U2's gate matches these globs as git pathspecs.
**Legibility-target:** for-orchestrator-synthesis

`scripts/lib/dev-cycle-read.sh:142-147`: `set="^[*?$NAMECHARS]+\$"`, `... && "$c" != [.][gG][iI][tT]* ]]`. `scripts/build-loop.sh:123-126` has the same character class and part tests without the `.git` test. Test 7 `:137-138` (`.github/ .gitignore` set) passes.

**Evidence:** `scripts/build-loop.sh:119-128`, `scripts/lib/dev-cycle-read.sh:140-148`

---

## Claim 18a: "Sets POLICY, POLICY_LINE, SLOTS_LINE, NEVER (an array of the checked globs, each as written, a trailing / kept) and NEVER_LINE from main's commit."

**Location:** `scripts/build-loop.sh:129-130`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the assignments in read_settings. NEVER is non-empty only when `never_ok=1` with a list. It does not establish that NEVER is reset when the file is not read (it is: `:137` `NEVER=()`).
**Legibility-target:** for-orchestrator-synthesis

`:173` `NEVER=("${parts[@]}")`, where `parts` is the unstripped split (`:163`). Globform and seen use `${g%/}`, but the array keeps `g`.

**Evidence:** `scripts/build-loop.sh:129-188`

---

## Claim 18b: "POLICY and NEVER are for the modes that judge a brief (--status, then the gate)."

**Location:** `scripts/build-loop.sh:130-131`
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers only that no code in this unit reads POLICY or NEVER (paraphrased, no quote available because this is an absence claim: grep over scripts/ finds no reader outside build-loop.sh's own assignments). It does not establish the future consumers.
**Legibility-target:** for-orchestrator-synthesis

`--status` (U1c) and the gate (U2) are not built. Verifying this needs those units.

**Evidence:** `scripts/build-loop.sh:129-133`, `docs/working/plan-build-loop-handoff.md:74`

---

## Claim 19: "Split on single spaces only; globform then refuses any other blank in an entry." / "not a bare $v: the shell would expand * and ? against files"

**Location:** `scripts/build-loop.sh:156`, `scripts/build-loop.sh:163`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers tab handling (a tab stays inside an entry and fails NAMECHARS) and globbing (no `set -f` / `noglob` anywhere in the script or lib, so an unquoted `$v` would glob). It does not establish other Unicode blanks, which fail NAMECHARS anyway.
**Legibility-target:** for-orchestrator-synthesis

`:163` `IFS=' ' read -ra parts <<<"$v"`. Mutant `no-ifs-split` (IFS removed) fails test 7, where the tab cases are at `:121`. `grep -n 'set -f\|noglob'` over both files returns nothing.

**Evidence:** `scripts/build-loop.sh:155-169`, `$S/logs/mutants.log`

---

## Claim 20: "Shared setup ...: a throwaway repo under $BATS_TEST_TMPDIR with a main branch, the same hermetic git environment as test/scripts/dev-cycle.bats" and "settings LINE...: ... With no lines the file holds one empty line."

**Location:** `test/lib/build-loop-fixtures.bash:2-5`, `test/lib/build-loop-fixtures.bash:24-26`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the exported git and HOME variables, which match dev-cycle.bats `setup()` exactly. bl_setup also pins `LC_ALL=C`, which dev-cycle.bats does not. It does not establish hermetic-env.bash parity (override row C6, accepted).
**Legibility-target:** for-orchestrator-synthesis

`build-loop-fixtures.bash:11-14` export `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`, author/committer t, and `HOME="$BATS_TEST_TMPDIR/home" LC_ALL=C`. `test/scripts/dev-cycle.bats:10-15` exports the same set without LC_ALL. `printf '%s\n'` with no arguments prints a single `\n` (checked: `od -c` shows `\n`).

**Evidence:** `test/lib/build-loop-fixtures.bash:1-36`, `test/scripts/dev-cycle.bats:5-18`

---

## Claim 21: Test 4 name: "review, unset by the interim note"

**Location:** `test/scripts/build-loop-read.bats:70`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this repo's docs/dev-cycle.md at 2e711a7b, whose `:7` is `Build-loop policy: review (interim; Q-103)`. It does not establish the test's behavior when the source file is missing: `cp` failing inside an `&&` chain does not stop the test, but the assertion then fails, which I saw when the scratch tree lacked docs/.
**Legibility-target:** for-orchestrator-synthesis

Baseline test 4 ok. `docs/dev-cycle.md:7` is quoted above.

**Evidence:** `test/scripts/build-loop-read.bats:70-76`, `docs/dev-cycle.md:7`, `$S/logs/baseline.log`

---

## Claim 22: Test 5 comment: "A replace ref for main's blob, even with core.useReplaceRefs set, is not followed." (A16)

**Location:** `test/scripts/build-loop-read.bats:82-84`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the repo-config case and that the test kills the no-guard mutant. It does not establish the caller's `git -c` channel (claim 14b), which the test does not exercise.
**Legibility-target:** for-orchestrator-synthesis

`:83` `git replace ... && git config core.useReplaceRefs true`, `:84` `settings_like policy "policy review set:"`. Mutant `no-config-pair` fails test 5 only.

**Evidence:** `test/scripts/build-loop-read.bats:78-91`, `$S/logs/mutants.log`

---

## Claim 23: Test 7 comments: ":117 A never list hidden in markup turns self-merge off rather than being skipped", ":128-129 duplicate never (A18)", ":130 Copies in some markup, a table, a link label or with a misplaced colon count as second lines too", ":139 A never line the next unfenced line may continue is malformed", ":144 Raised only on a loop's branch or in the working tree: ignored"

**Location:** `test/scripts/build-loop-read.bats:106-149`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named property and that a mutant of it fails test 7: never-ok-ignored, copies-set-ok (only `:129` asserts policy on a `cnt>1` input, so `:129` carries A18), drop-next-check, no-ifs-split, head-not-main and drop-none-arm172. It does not establish a kill for removing the `:160` `none` arm. That mutant survives because it is equivalent: `none` passes globform and `:172` still prints `never none` with `never_ok=1`.
**Legibility-target:** for-orchestrator-synthesis

Mutant results are in `$S/logs/mutants.log`. Test 7 failed for every mutant except `no-config-pair` and `drop-none-arm160`.

**Evidence:** `test/scripts/build-loop-read.bats:106-149`, `scripts/build-loop.sh:160`, `:172`, `$S/logs/mutants.log`

---

## Claim 24: Test 9 comment: "From a subdirectory and from a linked worktree, it reads the same main." (A19)

**Location:** `test/scripts/build-loop-read.bats:177-185`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the worktree committing its own review line (`:180` `git -C "$BATS_TEST_TMPDIR/wt" commit -qam wt`), so HEAD differs from main there. It does not establish a worktree whose branch is main itself, which git refuses.
**Legibility-target:** for-orchestrator-synthesis

Mutant `head-not-main` fails test 9, which it did not do before A19 per the rubric.

**Evidence:** `test/scripts/build-loop-read.bats:169-186`, `$S/logs/mutants.log`

---

## Claim 25: Commit 2e711a7b, A16 bullet: "A GIT_CONFIG_COUNT pair, appended after any the caller passed, sets it false"

**Location:** `git log -1 2e711a7b` (commit message, A16 bullet)
**Type:** Reference / Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the same mechanism as claim 14b. The pair follows the caller's GIT_CONFIG_COUNT pairs but not the caller's `git -c` / GIT_CONFIG_PARAMETERS pairs, which override it. It does not establish anything about the rest of the commit message (claims 26-27).
**Legibility-target:** for-author

See claim 14b: the `caller-params-true` and `git -c ... bl` runs gave `policy self-merge set` from a replace blob.

**Evidence:** `scripts/build-loop.sh:69`, `$S/logs/replace.log`, `$S/logs/config-order.log`

---

## Claim 26: Commit 2e711a7b, other bullets: Q-112/R4/A17; A18; A19; A20-A22; "--help prints the header up to its first non-comment line (no fixed range), as dev-cycle.sh now does"; "Merges feat/build-loop-u1a's iteration-4 fix first"

**Location:** `git log -1 2e711a7b` (commit message)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each bullet against the code and tests at 2e711a7b. For A21 this means the header and WHY only: the internal SETTINGS_AWK comment still says "the line after" (claim 16). It does not establish the session-context statements (authorisation by Q-112).
**Legibility-target:** for-orchestrator-synthesis

- Q-112/A17: claim 4.
- A18: claim 23.
- A19: claim 24.
- A20: header `:11-12`, claim 2.
- A21: `:22`, `:159`.
- A22: test `:130` reads "some markup".
- The help line is identical in `scripts/dev-cycle.sh:112`: `-h|--help) sed -n '2,/^[^#]/{/^#/p}' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;`.
- `git log --oneline feat/build-loop-u1a..2e711a7b` lists `d06e61a6 Merge branch 'feat/build-loop-u1a' into feat/build-loop-u1b` directly before 2e711a7b.

**Evidence:** `scripts/build-loop.sh:9-31`, `:57`, `:159`, `scripts/dev-cycle.sh:112`, `test/scripts/build-loop-read.bats:130`

---

## Claim 27: Commit 2e711a7b Notes: "~417 changed code lines against U1a"

**Location:** `git log -1 2e711a7b` (commit message, Notes)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers scripts/ and test/ in the three-dot diff. It does not establish anything about the docs/ lines, which are not counted.
**Legibility-target:** for-orchestrator-synthesis

`git diff --numstat feat/build-loop-u1a...2e711a7b -- scripts test` prints 195 (build-loop.sh), 36 (fixtures) and 186 (bats), all additions: 417.

**Evidence:** `scripts/build-loop.sh:1-195`, `test/lib/build-loop-fixtures.bash:1-36`, `test/scripts/build-loop-read.bats:1-186`

---

## Claim 28: Override rows 256 and 261: "self-merge now needs a valid exact never line, so a hidden never list turns self-merge off. A hidden copy next to an exact line is ignored, and the exact line governs." / "With Q-112's rule, self-merge implies a valid never line, so an empty NEVER under self-merge means "none"."

**Location:** `docs/reviews/override-log.md:256`, `docs/reviews/override-log.md:261`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stated reasons against the code at 2e711a7b. It does not judge whether accepting the hidden-copy-next-to-exact shape is wise; that is settled.
**Legibility-target:** for-orchestrator-synthesis

`hidden-never-next-exact` gives `policy self-merge set` + `never none: line 2 ... lists none`, so the exact line governs. POLICY=self-merge requires never_ok (`:179`), and never_ok with an empty NEVER arises only at `:172` (`none`).

**Evidence:** `scripts/build-loop.sh:171-181`, `$S/logs/cases1.log`

---

## Claim 29: Override rows 259, 260, 262, 264: "dev-cycle.sh's lib readers have no replace-ref guard"; "The lib's own tests cover main_entry's error and a failed blob read (dev-cycle.bats)"; "The plan's ":74" still says pathform globs"; ""Build-loop policy: self-merge" followed by "except on Fridays" still reads as set"

**Location:** `docs/reviews/override-log.md:259-264`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each factual premise. Row 260's "main_entry's error" is covered through a tree listing a name twice. It does not establish coverage of ls-tree failing outright.
**Legibility-target:** for-orchestrator-synthesis

- `grep -n 'NO_REPLACE\|useReplaceRefs' scripts/dev-cycle.sh` finds nothing.
- `test/scripts/dev-cycle.bats:1257` asserts `could not be read from the default branch` after deleting blobs, and `:1273` asserts `the default branch's tree could not be read` for a duplicate-name tree.
- Plan `:74` reads `` `Self-merge never: GLOB …` (pathform globs, one line ...) ``.
- `fridays` case gives `policy self-merge set: line 1`.

**Evidence:** `test/scripts/dev-cycle.bats:1250-1274`, `docs/working/plan-build-loop-handoff.md:74`, `$S/logs/cases2.log`

---

## Claim 30: Override row 258: "globform is quadratic per entry ... The entry is the user's own settings line; a scrub-cut line is at most 4 KB."

**Location:** `docs/reviews/override-log.md:258`
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the reading that the 4 KB cut applies to PRINTED lines only. `scrub` (`dev-cycle-read.sh:48-66`) runs on output, and SETTINGS_AWK and globform read the full committed line, so the cut does not bound globform's input. It does not establish the ~11 s timing figure, which I did not re-measure.
**Legibility-target:** for-orchestrator-synthesis

`dev-cycle-read.sh:52`: `$_ = substr($_, 0, 4096) . " [line cut at 4096 bytes]" if length($_) > 4096;` is in the output filter. `build-loop.sh:166` calls globform on each entry of the uncut `$v`. As a statement about printed output the 4 KB atom is true. Read as a bound on globform's work it does not hold. The timing needs a measurement run.

**Evidence:** `scripts/lib/dev-cycle-read.sh:48-66`, `scripts/build-loop.sh:121-128`, `:163-169`

---

## Claims Requiring Attention

### Incorrect
- **Claim 14b** (`scripts/build-loop.sh:67-69`): the config pair is not "after any the caller passed". git reads a caller's `git -c` / GIT_CONFIG_PARAMETERS pairs after GIT_CONFIG_COUNT, so `-c core.useReplaceRefs=true` (including via a git alias) re-enables replace refs, and a replace blob raised policy to self-merge. Say "after any GIT_CONFIG_COUNT pairs", or also clear or override GIT_CONFIG_PARAMETERS.
- **Claim 25** (commit 2e711a7b, A16 bullet): the same mechanism claim, in history.

### Stale
- (none)

### Mostly Accurate
- **Claim 16** (`scripts/build-loop.sh:99-100`): NEXT is measured on the next line outside a fence, not "the line after the first". A21 updated the header and WHY but not this comment.

### Unverifiable
- **Claim 18b** (`scripts/build-loop.sh:130-131`): POLICY/NEVER consumers (--status, the gate) are not built yet; needs U1c/U2.
- **Claim 30** (`docs/reviews/override-log.md:258`): the 4 KB cut bounds printed output, not globform's input. The timing was not re-measured.

---

## Goal-Alignment Note

**Success criterion (verbatim):** A report saved at the output path named in your tail, structured per your skill, covering the full unit diff at 2e711a7b.

**Answered:** Yes. The report covers all three code files' checkable comments, the test names and comments, commit 2e711a7b's message and the u1b override rows 256-264, with 18 executed verdicts and mutation checks for every brief-listed mutant.

**Out of scope:** The lib (U1a) beyond what the claims depend on. Rows 222-255 were treated as settled, except where cited.

**Escalate:** Claim 14b / 25. The A16 guard is defeated by a caller's `git -c core.useReplaceRefs=true` (GIT_CONFIG_PARAMETERS overrides GIT_CONFIG_COUNT), and the result RAISES policy to self-merge from a replace blob. The premise is new at 2e711a7b, since the guard was introduced in this iteration. Practical exposure depends on whether the orchestrator can ever run under `git -c` or a git alias. The loop writes the repo config but not the caller's environment.

**Questions / Decisions:** (1) Is the caller's environment inside the trust boundary? If yes, a comment fix suffices. If no, unset or neutralise GIT_CONFIG_PARAMETERS before the pair. (2) Minor: a caller's malformed GIT_CONFIG_COUNT exits 1 as "Not inside a git repository" (claim 12 scope). This fails closed, but the reason given is wrong.
