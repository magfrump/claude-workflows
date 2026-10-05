Commit: 2e711a7b

# Code Fact-Check Report

**Repository:** claude-workflows (worktree /workspace/.claude/wt-build-loop-u1b, branch feat/build-loop-u1b)
**Scope:** Unit diff `feat/build-loop-u1a...2e711a7b`: scripts/build-loop.sh, test/lib/build-loop-fixtures.bash, test/scripts/build-loop-read.bats, override-log rows 222-264 for u1b (rows 256-264 checked in detail), and commit 2e711a7b's message. Replicate r1 of 3, iteration 4 (final confirming pass).
**Checked:** 2026-10-05
**Total claims checked:** 47 (45 numbered; 4 and 16 split into a/b)
**Summary:** 39 verified, 6 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). The relevant prior pattern is "a specific count claimed in a commit message" (e.g. `mode1-equiv 33`); Claim 38 (`~417 changed code lines`) was checked against it and does not match it (the count holds).

Scratch dir for every execution: `S=/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i4/fc-r1`. Execution records cited by the claims:

- **E1** `bats test/scripts/build-loop-read.bats`, cwd `$S/base` (a copy of scripts/, the two test files and docs/dev-cycle.md at 2e711a7b), `LC_ALL=C.UTF-8 TMPDIR=$S/tmp`, exit 0, 2026-10-05T16:41:12Z, output `$S/logs/baseline.log` (9/9 ok).
- **E2** `./mutants.sh`, cwd `$S`, 2026-10-05T16:41:24Z. Each mutant is a copy of base with one perl edit to build-loop.sh, then bats. Summary `$S/logs/mutants-summary.log`, per-mutant `$S/logs/mutant-<name>.log`. Results: `nocfg` (drop the GIT_CONFIG pair, :69) exit 1, test 5 fails; `nonoreplace` (drop GIT_NO_REPLACE_OBJECTS=1) exit 0, all pass; `noneverok` (make the :179 check never fire) exit 1, test 7 fails; `dupnever_ok` (set never_ok=1 in the two-never-lines arm, :153) exit 1, test 7 fails; `headread` (`HEAD:$f` in place of `$MAIN_SHA:$f`, :89) exit 1, tests 5, 7, 9 fail; `nonone` (drop both `none` arms, :160/:172) exit 1, test 7 fails; `nonext` (drop the next-line arm, :159) exit 1, test 7 fails; `absentok` (a refused file gives `never none`, :143) exit 1, test 3 fails.
- **E3** `./cfg-exp.sh`, cwd `$S/repo-cfg` (main holds "Build-loop policy: review"; a replace ref swaps in a self-merge blob; `core.useReplaceRefs true` in .git/config), exit 0, 2026-10-05T16:42:04Z, `$S/logs/cfg-exp.log`.
- **E4** `./cfg-exp2.sh`, same repo, exit 0, 2026-10-05T16:42:28Z, `$S/logs/cfg-exp2.log`.
- **E5** `./cfg-exp3.sh`, same repo, exit 0, 2026-10-05T16:42:33Z, `$S/logs/cfg-exp3.log`.
- **E6** `./settings-exp.sh`, cwd `$S/repo-set` (23 committed docs/dev-cycle.md shapes, then the file removed), exit 0, 2026-10-05T16:42:51Z, `$S/logs/settings-exp.log`.
- **E7** `bash $S/base/scripts/build-loop.sh -h`, cwd `$S/repo-set`, exit 0, 2026-10-05T16:43:07Z, output `$S/logs/help.out`, compared to lines 2-38 (de-#ed) in `$S/logs/help.want`: identical, 37 lines. Also `sed -n '2,/^[^#]/{/^#/p}'` on a copy whose header line 32 `#` became an empty line, plus `printf '%s\n' | od -c`, 2026-10-05T16:44:48Z, exit 0, `$S/logs/help-blank-and-printf.log`.
- **E8** `bash $S/perf.sh scripts/build-loop.sh` (globform copied from :121-128, one 79,999-byte `a/a/...` entry), exit 0, 2026-10-05T16:43:35Z, `$S/logs/perf.log`.
- **E9** `cd sub && bash ../../base/scripts/build-loop.sh --settings`, cwd `$S/repo-set/sub`, exit 0, 2026-10-05T16:43:58Z, `$S/logs/relpath.log`.

---

## Claim 1: "three lines from the default branch's commit, never the working tree (a build loop can write any working tree)"

**Location:** `scripts/build-loop.sh:9-10`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the one read path, `git cat-file blob "$MAIN_SHA:$f"` after `main_entry` (which lists `$MAIN_SHA`'s tree), for an uncommitted edit, a commit on a checked-out loop branch, a subdirectory and a linked worktree. It does not establish which commit counts as the default branch when origin/HEAD names a loop's branch (override row 247, deferred).

The only blob read is at `scripts/build-loop.sh:89`: `FILE_OUT="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk "$FENCE_AWK$2")"` (excerpt ends :89; enclosing main_file() continues to :95 — read), and the entry check is `main_entry`, which runs `git ls-tree -t --full-tree "$MAIN_SHA"` (`scripts/lib/dev-cycle-read.sh:263`). E1: tests 5 and 9 pass. E2: the `headread` mutant fails tests 5, 7 and 9, and test 9 fails on the worktree case (`[.../wt] policy review set`).

**Evidence:** `scripts/build-loop.sh:78-95`, `scripts/lib/dev-cycle-read.sh:258-274`, `test/scripts/build-loop-read.bats:78-91`, `test/scripts/build-loop-read.bats:169-186`; `$S/logs/baseline.log`, `$S/logs/mutant-headread.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 2: "a second copy, or a file the lib's FENCE_AWK refuses, gives review, 3 and malformed (WHY says which)"

**Location:** `scripts/build-loop.sh:11-12`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the per-key reading (a second copy of a key gives that key's fallback: policy `review unset`, slots `3 default`, never `malformed`) and the whole-file reading for a refused file (all three lines). It does not claim, and the code does not do, that a copy of one key changes the other two lines. An absent file is a third case, which gives `never none` (Claim 8).

Per key, `scripts/build-loop.sh:153`, `:176`, `:184` print `never malformed: $(many ...)`, `policy review unset: $(many ...)`, `slots 3 default: $(many ...)`. A refused file takes the `main_file` failure arm: `POLICY_LINE="policy review unset: $why"; SLOTS_LINE="slots 3 default: $why"` and `NEVER_LINE="never malformed: $why"` (`scripts/build-loop.sh:141-143`). E6: "second copy of all three keys" prints `policy review unset: more than one line ...`, `slots 3 default: more than one line ...`, `never malformed: more than one line ...`; "second copy of policy only" leaves `slots 4 set` and `never none: line 4 ...`; "refused file (html)" prints review/3/malformed, each naming line 2's reason.

**Evidence:** `scripts/build-loop.sh:139-188`; `$S/logs/settings-exp.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 3: "Set only by \"Build-loop policy: self-merge\" or \"...: review\", exactly (one trailing CR dropped); else review."

**Location:** `scripts/build-loop.sh:14-15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exact-match regex, the single trailing CR (removed by `sub(/\r$/, "")`), and the refusal of a second CR (FENCE_AWK's `cr`). It does not cover the self-merge precondition, which is Claim 4.

`scripts/build-loop.sh:177`: `elif [[ "${text[policy]}" =~ ^Build-loop\ policy:\ (self-merge|review)$ ]]; then`; `:104`: `{ sub(/\r$/, "") }`. E1 test 1 (CR) and test 2 (five variants) pass. E6 "policy two CRs" gives `policy review unset: line 1 ... holds a carriage return that does not end it`.

**Evidence:** `scripts/build-loop.sh:104`, `scripts/build-loop.sh:175-182`, `scripts/lib/dev-cycle-read.sh:215`; `$S/logs/baseline.log`, `$S/logs/settings-exp.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 4a: "Self-merge also needs a valid never line"

**Location:** `scripts/build-loop.sh:15-16` (also `:151`: "self-merge needs a valid one (never_ok)")
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every path that leaves `never_ok` empty (no never line, two never lines, a malformed line, a file not read): none of them yields `policy self-merge set`. Only `:172` (`none`) and `:173` (a checked list) set `never_ok=1`, and both need `cnt[never]` to be 1, the text to start `Self-merge never: `, single spaces, a blank next line and every entry to pass globform. It does not establish anything about the gate (U2) honouring POLICY.

`scripts/build-loop.sh:179-181`:
```bash
      if [[ "$v" == self-merge && -z "$never_ok" ]]; then
        POLICY_LINE="policy review unset: line ${first[policy]} reads self-merge, but there is no valid Self-merge never: line (\"Self-merge never: none\" for an empty list), so self-merge is off"
      else POLICY="$v"; POLICY_LINE="policy $v set: line ${first[policy]} $where"; fi
```
`never_ok` starts empty (`local ... never_ok=""`, `:135`) and is set only at `:172-173`. On the not-read arm (`:139-143`) the policy line is `review unset` without reaching `:179`. E2: `noneverok` and `dupnever_ok` each fail test 7. E6: every malformed or missing never case prints the `reads self-merge, but there is no valid ...` line.

**Evidence:** `scripts/build-loop.sh:134-188`; `$S/logs/mutants-summary.log`, `$S/logs/settings-exp.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 4b: "so a list hidden in markup turns it off rather than being skipped"

**Location:** `scripts/build-loop.sh:16-17`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** True when the hidden list is the only never-like line. It does not hold when an exact never line is also present: then the hidden list is skipped and the exact line governs. That behaviour is settled (override row 256: "A hidden copy next to an exact line is ignored, and the exact line governs"). This verdict is about the wording only. It does not re-raise the defect: the hidden line neither raises the policy nor adds self-merge, which the exact `none` line already allowed.

E6, "hidden link never copy only" (`[x](y) Self-merge never: b/`): `policy review unset: line 1 reads self-merge, but there is no valid ...` and `never none: no line starts "Self-merge never:"`, so the claim holds. E6, "hidden task-box never copy + exact none" (`Self-merge never: none`, blank, `- [x] Self-merge never: b/`): `policy self-merge set` and `never none: line 2 ... lists none`, so the hidden `b/` list is skipped. Precise version: "a never list hidden in markup, when there is no exact never line, turns self-merge off rather than being skipped; next to an exact never line it is ignored (best effort)."

**Evidence:** `scripts/build-loop.sh:108-112`, `scripts/build-loop.sh:152-173`; `$S/logs/settings-exp.log`
**Legibility-target:** for-author

---

## Claim 5: "Loops at once: \"Build-loop slots: N\", N from 1 to 9; else 3."

**Location:** `scripts/build-loop.sh:19`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regex and the fallback. It does not establish that any later mode uses the number (U1b only prints it).

`scripts/build-loop.sh:185`: `elif [[ "${text[slots]}" =~ ^Build-loop\ slots:\ ([123456789])$ ]]; then SLOTS_LINE="slots ${BASH_REMATCH[1]} set: ...`. E1 test 6 passes (0, 10, a trailing space, 05, three, a copy, fenced). E6 "slots with CR" gives `slots 5 set`.

**Evidence:** `scripts/build-loop.sh:183-186`; `$S/logs/baseline.log`, `$S/logs/settings-exp.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 6: "\"Self-merge never: GLOB ...\" (or \"...: none\"), single spaces, and the next line outside a fence blank or the end."

**Location:** `scripts/build-loop.sh:21-23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the next-line rule across a fence, a CR-only line, a whitespace-only line, end of file, a one-line HTML comment and a plain text line. It does not cover lines FENCE_AWK refuses, since those refuse the whole file (Claim 2).

In SETTINGS_AWK, `fence($0) { next }` (`:105`) runs before `if (pk != "") { nx[pk] = ($0 ~ /^[ \t]*$/); pk = "" }` (`:107`), so fence lines and fenced content never decide NEXT, and `nx[k] = 1` is set when the key line is first seen (`:112`), which covers end of file. E6: "never then fence then b/" gives malformed; "fence then blank", "fence to EOF", "CR-only line", "whitespace-only line" and "at EOF" give `never a/ set`; "one-line html comment" gives malformed.

**Evidence:** `scripts/build-loop.sh:103-118`, `scripts/build-loop.sh:157-160`; `$S/logs/settings-exp.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 7: "A glob uses letters, digits, . _ - / * ? (a trailing / ignored when comparing), has no empty, . or .. part, does not start with / or -, and is listed once."

**Location:** `scripts/build-loop.sh:23-26`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers globform and the `seen` check, both on `${g%/}`. It does not establish how U2's gate will match the globs.

`scripts/build-loop.sh:123`: `[[ "$1" =~ ^[*?$NAMECHARS]+$ && "$1" != /* && "$1" != -* ]] || return 1`; `:126`: `[[ -n "$c" && "$c" != "." && "$c" != ".." ]] || return 1`; `:166-168` call `globform "${g%/}"` and check `seen[${g%/}]`. `NAMECHARS` is the ASCII list at `scripts/lib/dev-cycle-read.sh:139`. E6: `*.sh ??/` set; `a a/` gives "lists entry 2 twice"; `a//` gives "not an allowed glob form" (only one `/` is stripped). E1 test 7's 15 malformed variants pass.

**Evidence:** `scripts/build-loop.sh:121-128`, `scripts/build-loop.sh:161-170`; `$S/logs/settings-exp.log`, `$S/logs/baseline.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 8: "Malformed (or a file not read) turns self-merge off." / "An absent file sets nothing; one that is not read turns self-merge off."

**Location:** `scripts/build-loop.sh:26-27`, `scripts/build-loop.sh:142`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `never malformed` for a refused or unreadable file, `never none` for an absent one, and `policy review unset` in both. It does not cover main_file's `error` and failed-read arms by test (override row 260); they share the same `else` branch at `:143`.

`scripts/build-loop.sh:143`: `if [[ "$FILE_WHY" == absent ]]; then NEVER_LINE="never none: $why"; else NEVER_LINE="never malformed: $why"; fi`. E6 "absent": `never none: no docs/dev-cycle.md on the default branch`. E2: `absentok` fails test 3.

**Evidence:** `scripts/build-loop.sh:139-143`; `$S/logs/settings-exp.log`, `$S/logs/mutant-absentok.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 9: "Copies are found best effort: a line counts as one when its letters alone, case folded, start with the key's (\"buildlooppolicy\"). Markup that adds letters (a task box, a tag) can still hide a copy; only an exact line ever sets a value."

**Location:** `scripts/build-loop.sh:28-31`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the letters-only, ASCII case-folded prefix match (mawk, LC_ALL=C), the task-box and link shapes that hide a copy, and the exactness of every setting (policy and slots regexes, never prefix plus single-space shape). It does not enumerate every hiding shape: entities and zero-width characters are settled (rows 248, 256).

`scripts/build-loop.sh:108-111`: `s = tolower($0); gsub(/[^a-z]/, "", s); ...; if (index(s, "buildlooppolicy") == 1) k = "policy"`. E6: `- [ ] Build-loop policy: self-merge` alone gives `no line starts "Build-loop policy:"` (hidden, review); `\xef\xbb\xbfBuild-loop policy: review` on line 2 counts as a copy; "Build-loop policies are listed above." is not a copy ("policies" ≠ "policy" at letter 15).

**Evidence:** `scripts/build-loop.sh:103-118`, `scripts/build-loop.sh:157`, `:177`, `:185`; `$S/logs/settings-exp.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 10: "Acts on $PWD's git repo, like dev-cycle.sh, and needs its default branch found by name (origin/HEAD, main or master). Read-only: writes nothing."

**Location:** `scripts/build-loop.sh:33-34`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `rev-parse --show-toplevel` and cd, and the `main_by_name` exit. Read-only rests on the git commands used (rev-parse, show-ref, symbolic-ref, ls-tree, cat-file), none of which writes. It does not establish the absence of git-internal side effects such as lazy object fetches.

`scripts/build-loop.sh:62`: `ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Not inside a git repository" >&2; exit 1; }`; `:72`: `main_by_name || { echo "build-loop.sh needs a default branch found by name ..." >&2; exit 1; }`. E1 test 8 (a branch renamed to trunk: exit 1, "needs a default branch") passes. That the script uses no writing git command is paraphrased — no quote available because the claim is about the absence of code (grep of the script and lib's resolve_main/main_entry finds only the read commands listed above).

**Evidence:** `scripts/build-loop.sh:62-72`, `scripts/lib/dev-cycle-read.sh:389-411`; `$S/logs/baseline.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 11: "Output passes through the lib's scrub (but for the start-up errors about perl and the lib); printed repo text is data."

**Location:** `scripts/build-loop.sh:35-36`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the order: the perl and lib errors (`:42`, `:48`) come before `scrub_reexec` (`:51`), and every later message comes after it. It does not re-verify the scrub's own coverage (U1a's lib).

`scripts/build-loop.sh:42-51`: the `command -v perl` and `[[ -f "$READ_LIB" ]]` exits, then `source "$READ_LIB"` and `scrub_reexec "${BASH_SOURCE[0]}" "$@"`. `scripts/lib/dev-cycle-read.sh:79`: `{ DEV_CYCLE_SCRUBBED=1 bash "$self" "$@" 2>&1 1>&3 3>&- | scrub >&2; } 3>&1 | scrub` covers both streams.

**Evidence:** `scripts/build-loop.sh:40-51`, `scripts/lib/dev-cycle-read.sh:76-81`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 12: "Exit: 0 every line printed (or help); 1 bad usage, not a git repo, no perl or lib/dev-cycle-read.sh, or no default branch found by name."

**Location:** `scripts/build-loop.sh:37-38`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed exit. It does not cover caller-environment failures outside the list: a `GIT_CONFIG_COUNT` git rejects (`abc`, `08`, a count with no KEY_0) exits 1 with the message "Not inside a git repository" (git rev-parse fails first), and `GIT_CONFIG_COUNT=' 1'` exits 1 through bash's `export: not a valid identifier`.

`scripts/build-loop.sh:53`: `usage() { echo "$1 (usage: build-loop.sh --settings)" >&2; exit 1; }`; `:57`: `... exit 0 ;;`. E1 tests 8 and 9 pass (usage, no default branch, not a repo, missing lib). E3/E4: the `GIT_CONFIG_COUNT` cases above.

**Evidence:** `scripts/build-loop.sh:42-72`, `scripts/build-loop.sh:190-195`; `$S/logs/baseline.log`, `$S/logs/cfg-exp.log`, `$S/logs/cfg-exp2.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 13: "before the cd: relative paths work"

**Location:** `scripts/build-loop.sh:43`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a relative script path given from a subdirectory. It does not cover a script reached through a symlink (`dirname` of the link, not its target).

`scripts/build-loop.sh:43`: `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` runs before `cd "$ROOT"` (`:63`). E9: `bash ../../base/scripts/build-loop.sh --settings` from `repo-set/sub` prints three lines, exit 0.

**Evidence:** `scripts/build-loop.sh:43-63`; `$S/logs/relpath.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 14: "The reader shared with dev-cycle.sh, from this script's own directory (never the target repo's scripts/lib/), so a copy of scripts/ with its lib/ is self-contained."

**Location:** `scripts/build-loop.sh:44-48`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers sourcing from `$SCRIPT_DIR/lib/` and the missing-lib exit. It does not establish that dev-cycle.sh sources the same file (U1a).

`scripts/build-loop.sh:47`: `READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"`. E1 test 9 (a planted `scripts/lib/dev-cycle-read.sh` in the target repo is not run; a lone copy exits 1 naming the missing lib) passes, and E1 itself ran from a copy of scripts/.

**Evidence:** `scripts/build-loop.sh:44-50`, `test/scripts/build-loop-read.bats:169-176`; `$S/logs/baseline.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 15: "# the header, to its first non-comment line"

**Location:** `scripts/build-loop.sh:57`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** The output today is exactly lines 2-38 with `# ` removed. The verdict concerns the stated stopping rule: an empty line does not end the range, only a line whose first character is not `#`, and the empty line 39 prints nothing. It does not establish behaviour for a header that starts with a non-comment line 2.

`scripts/build-loop.sh:57`: `sed -n '2,/^[^#]/{/^#/p}' "$0" | sed 's/^# \{0,1\}//'`. `^[^#]` needs a first character, so the empty line 39 does not match, and the range ends at line 40 (`set -euo pipefail`). E7: `help.out` equals `help.want` (37 lines). With header line 32's `#` replaced by an empty line, the range still prints 36 lines, through line 38. Precise version: "the header's # lines, up to the first line that starts with another character".

**Evidence:** `scripts/build-loop.sh:1-40`, `scripts/build-loop.sh:57`; `$S/logs/help.out`, `$S/logs/help.want`, `$S/logs/help-blank-and-printf.log`
**Legibility-target:** for-author

---

## Claim 16a: "Read main's own objects: a replace ref could swap in any settings blob. core.useReplaceRefs in the repo's config would override the variable"

**Location:** `scripts/build-loop.sh:66-67`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5: with `core.useReplaceRefs true` in .git/config, `GIT_NO_REPLACE_OBJECTS=1` alone does not stop a replace ref on main's blob. It does not establish other git versions. It also leaves out a side observation: with the config pair present, `GIT_NO_REPLACE_OBJECTS=1` is redundant under the tests (mutant `nonoreplace` passes).

E2: mutant `nocfg` (pair removed, `GIT_NO_REPLACE_OBJECTS=1` kept) fails test 5 at `test/scripts/build-loop-read.bats:84` with `policy self-merge set: line 1`, so the replaced blob was read.

**Evidence:** `scripts/build-loop.sh:66-70`, `test/scripts/build-loop-read.bats:82-84`; `$S/logs/mutant-nocfg.log`, `$S/logs/mutants-summary.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 16b: "add a command-line config pair after any the caller passed."

**Location:** `scripts/build-loop.sh:67-69`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Holds for caller pairs passed through `GIT_CONFIG_COUNT`/`KEY_n`/`VALUE_n` with a plain decimal count (E3: `COUNT=1` or `2` with a pair setting `true` still reads `policy review set`). It is refuted for two caller inputs. All of them are the orchestrator's own environment, not something repo text or a loop's working tree can set. This verdict does not rate exploitability.

`scripts/build-loop.sh:69`: `cfg="${GIT_CONFIG_COUNT:-0}"; export "GIT_CONFIG_KEY_$cfg=core.useReplaceRefs" "GIT_CONFIG_VALUE_$cfg=false" GIT_CONFIG_COUNT=$((cfg + 1))`.
1. A caller's `git -c` pairs (`GIT_CONFIG_PARAMETERS`) are read after the `GIT_CONFIG_COUNT` pairs, so they win. E3: `GIT_CONFIG_PARAMETERS="'core.useReplaceRefs'='true'"` gives `policy self-merge set` (the replaced blob) and `never none: line 3`. `git config --show-origin --get-all` with both lists `command line: false` then `command line: true`.
2. A count with a leading zero is octal to bash and decimal to git. E5: `GIT_CONFIG_COUNT=010` (pairs 0-9 set) exports `GIT_CONFIG_KEY_010` and `GIT_CONFIG_COUNT=9`, so git reads pairs 0-8 and never the guard. Output: `policy self-merge set`.

What the code does: it appends one pair at index `$GIT_CONFIG_COUNT` (read by bash arithmetic) and sets the count to one more. That puts the pair after the caller's `GIT_CONFIG_COUNT` pairs, but not after its `GIT_CONFIG_PARAMETERS` pairs, and not when the count has leading zeros. Same wording in commit 2e711a7b's A16 bullet (Claim 36).

**Evidence:** `scripts/build-loop.sh:69-70`; `$S/logs/cfg-exp.log`, `$S/logs/cfg-exp3.log`
**Legibility-target:** for-author

---

## Claim 17: "A file on main: FILE_OUT is what awk program $2 (after FENCE_AWK) printed over it; or it returns 1 with FILE_WHY \"absent\" or why it was not read (main_entry, a failed read, or FENCE_AWK's \"odd N WHY\" / \"unbalanced N\")."

**Location:** `scripts/build-loop.sh:74-76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every return arm of main_file (`:78-95`). It does not claim FILE_OUT is empty on failure (it can hold the `odd`/`unbalanced` line), and the error and failed-read arms are verified only statically (override row 260).

`scripts/build-loop.sh:82-93` map each main_entry answer and awk result to FILE_WHY, as quoted in the diff (`absent) FILE_WHY=absent; return 1 ;;` ... `unbalanced\ *) FILE_WHY="the code fence opened at line ${FILE_OUT#unbalanced } of $f is never closed, so the file is not read"; return 1 ;;`). E1 test 3 covers the absent, notdir, notfile, odd (comment, BOM) and unbalanced arms.

**Evidence:** `scripts/build-loop.sh:74-95`; `$S/logs/baseline.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 18: "(best effort: most markup, a BOM or a misplaced colon cannot hide a copy)"

**Location:** `scripts/build-loop.sh:98-99`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the shapes in tests 2 and 7 (list marker, bold, heading, BOM on a later line, bold key, one-line comment, emphasis, code span, table, link label, `Self-merge never : `). It does not cover letter-adding markup, which the comment says is best effort.

E1 tests 2 and 7 pass. E6 "BOM on line 2 copy" gives `more than one line starts "Build-loop policy:" (lines 1 and 2)`. A BOM on line 1 refuses the file instead (FENCE_AWK `bom`, `scripts/lib/dev-cycle-read.sh:217`).

**Evidence:** `scripts/build-loop.sh:108-111`, `test/scripts/build-loop-read.bats:33-37`, `test/scripts/build-loop-read.bats:130-134`; `$S/logs/baseline.log`, `$S/logs/settings-exp.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 19: "whether the line after the first is blank (NEXT 1) or not"

**Location:** `scripts/build-loop.sh:99-100`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Right about the blank test. Imprecise about "the line after": NEXT is computed from the next line outside a fence (fence lines and fenced content are skipped), and NEXT is also 1 when no line follows. It does not affect the header (`:22`) or the WHY (`:159`), which say "outside a fence".

`scripts/build-loop.sh:105-107`: `fence($0) { next }` comes before `if (pk != "") { nx[pk] = ($0 ~ /^[ \t]*$/); pk = "" }`, and `:112` sets `nx[k] = 1` at the key line. E6: "never then fence then blank" gives NEXT 1 (set) although the physical next line is a fence. Precise version: "whether the next line outside a fence is blank, or there is none (NEXT 1)". Iteration 3's A21 asked for this; 2e711a7b fixed the header and the WHY but not this comment.

**Evidence:** `scripts/build-loop.sh:97-118`; `$S/logs/settings-exp.log`
**Legibility-target:** for-author

---

## Claim 20: "\"KEY COUNT FIRST SECOND NEXT<TAB>LINE\""

**Location:** `scripts/build-loop.sh:101`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the END print and the reader at `:145-149`. SECOND is 0 when there is no second copy. It does not cover a LINE that holds a tab, where `${l#*$'\t'}` cuts at the first tab, which is the separator (correct).

`scripts/build-loop.sh:117`: `else for (k in c) print k " " c[k] " " l1[k] " " (k in l2 ? l2[k] : 0) " " nx[k] "\t" t[k]`; `:147`: `read -r k c l1 l2 nx <<<"${l%%$'\t'*}"`.

**Evidence:** `scripts/build-loop.sh:114-118`, `scripts/build-loop.sh:145-149`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 21: "A never entry: pathform's rule, but a .git* part (.github/) is allowed, since the list only adds refusals"

**Location:** `scripts/build-loop.sh:119-120`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers rule equivalence with `pathform "$1" glob` apart from the `[.][gG][iI][tT]*` component test. It does not verify the rationale (that the gate only adds refusals), which is U2's.

The lib's `pathform` (`scripts/lib/dev-cycle-read.sh:142-147`) uses `^[*?$NAMECHARS]+$`, `!= /*`, `!= -*`, and per part `-n`, `!= .`, `!= ..`, `!= [.][gG][iI][tT]*`. globform (`scripts/build-loop.sh:123-126`) has the same tests without the last one. E6 "never with .GIT part": `never .GIT/x .git set`.

**Evidence:** `scripts/build-loop.sh:119-128`, `scripts/lib/dev-cycle-read.sh:140-149`; `$S/logs/settings-exp.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 22: "Sets POLICY, POLICY_LINE, SLOTS_LINE, NEVER (an array of the checked globs, each as written, a trailing / kept) and NEVER_LINE from main's commit. POLICY and NEVER are for the modes that judge a brief (--status, then the gate)."

**Location:** `scripts/build-loop.sh:129-131`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the assignments in read_settings (`:134-188`) and the plan's interface: --status prints POLICY (plan `:205`), and the gate applies S rules "when the stricter policy is self-merge" (plan `:212`). It does not establish that those future modes read these globals (U1c/U2 code). NEVER is set whenever the never line is valid, also under a review policy.

`scripts/build-loop.sh:173`: `else never_ok=1; NEVER=("${parts[@]}"); NEVER_LINE="never $v set: ..."`. `parts` holds the entries as split, before `${g%/}`.

**Evidence:** `scripts/build-loop.sh:129-188`, `docs/working/plan-build-loop-handoff.md:205`, `docs/working/plan-build-loop-handoff.md:212`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 23: "Split on single spaces only; globform then refuses any other blank in an entry."

**Location:** `scripts/build-loop.sh:156`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers tab, leading tab, trailing tab, space+tab and double space (test 7). It does not separately test other blanks such as VT, FF or NBSP; NAMECHARS excludes them (static).

`scripts/build-loop.sh:157` requires `^[^\ ]+(\ [^\ ]+)*$`, and `:163` splits with `IFS=' ' read -ra parts`. A tab is not in IFS, so it stays in the entry, and globform's NAMECHARS class refuses it. E1 test 7 passes, including its no-tab-echoed assertion.

**Evidence:** `scripts/build-loop.sh:155-169`, `test/scripts/build-loop-read.bats:119-127`; `$S/logs/baseline.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 24: "is followed by a non-blank line outside a fence (it may continue the list)"

**Location:** `scripts/build-loop.sh:159`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers when this WHY fires (NEXT 0) for a text line, across a fence, and for a one-line comment. It does not cover the policy and slots keys, which have no next-line rule (override row 264).

Quoted at `scripts/build-loop.sh:159`: `elif [[ "${next[never]}" != 1 ]]; then why="is followed by a non-blank line outside a fence (it may continue the list)"`. E6 cases as in Claim 6. E2 `nonext` fails test 7.

**Evidence:** `scripts/build-loop.sh:159`; `$S/logs/settings-exp.log`, `$S/logs/mutant-nonext.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 25: "not a bare $v: the shell would expand * and ? against files"

**Location:** `scripts/build-loop.sh:163`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers bash pathname expansion of an unquoted `$v` (no `set -f` in the script; cwd is the repo root after `:63`). It does not test an alternative implementation.

`scripts/build-loop.sh:163`: `IFS=' ' read -ra parts <<<"$v"`. Neither the script nor the lib runs `set -f` (paraphrased — no quote available because the claim covers absence of code: a grep for `set -f`/`noglob` finds no match), so an unquoted `$v` would be glob-expanded. E6 "never with * and ? set" prints `*.sh ??/` unexpanded.

**Evidence:** `scripts/build-loop.sh:40`, `scripts/build-loop.sh:163`; `$S/logs/settings-exp.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 26: "a throwaway repo under $BATS_TEST_TMPDIR with a main branch, the same hermetic git environment as test/scripts/dev-cycle.bats"

**Location:** `test/lib/build-loop-fixtures.bash:2-4`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the exported git variables and HOME. It does not cover LC_ALL: the fixture also pins `LC_ALL=C`, which dev-cycle.bats's setup does not.

The fixture exports `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`, the author and committer pairs, and `HOME="$BATS_TEST_TMPDIR/home" LC_ALL=C` (`test/lib/build-loop-fixtures.bash:11-14`). `test/scripts/dev-cycle.bats:11-15` exports the same git variables and HOME.

**Evidence:** `test/lib/build-loop-fixtures.bash:7-19`, `test/scripts/dev-cycle.bats:11-15`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 27: "settings LINE...: docs/dev-cycle.md holding these lines (printf %s\n each), committed. With no lines the file holds one empty line."

**Location:** `test/lib/build-loop-fixtures.bash:24-25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers printf's behaviour with no arguments. It does not cover the commit.

`test/lib/build-loop-fixtures.bash:26`: `settings() { mkdir -p docs && printf '%s\n' "$@" > docs/dev-cycle.md && commit_all settings; }`. E7: `printf '%s\n' | od -c` prints one `\n`.

**Evidence:** `test/lib/build-loop-fixtures.bash:24-26`; `$S/logs/help-blank-and-printf.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 28: "settings_is KEY WANT / settings_like KEY PREFIX: run --settings; its KEY line must equal WANT, or start with PREFIX. On a mismatch, print the whole output." / "line KEY: the --settings output line that starts with KEY."

**Location:** `test/lib/build-loop-fixtures.bash:28-29`, `test/lib/build-loop-fixtures.bash:34`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the helpers' match and their failure output (stdout and stderr). It does not cover `grep -m1 "^$1 "` with a regex-special KEY; all callers pass policy, slots or never.

E2 `mutant-nocfg.log` shows the failure print: `# want: policy review set:...` followed by all three output lines.

**Evidence:** `test/lib/build-loop-fixtures.bash:28-36`; `$S/logs/mutant-nocfg.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 29: Test names and their named properties fail under mutation (T1, T3, T4, T45, test 8, test 9)

**Location:** `test/scripts/build-loop-read.bats:13`, `:43`, `:78`, `:106`, `:151`, `:169`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the eight mutants in E2: each property the brief named (the GIT_CONFIG pair, the never_ok check, the two-never-lines arm, `HEAD:$f`, the `none` arm) and two more (the next-line arm, absent vs refused) makes at least one named test fail. Mutating `GIT_NO_REPLACE_OBJECTS=1` alone is not caught (the pair covers it). Not every assertion was mutated.

E2 results as listed in the header.

**Evidence:** `test/scripts/build-loop-read.bats:13-186`; `$S/logs/mutants-summary.log`, `$S/logs/mutant-*.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 30: "--settings on this repo's own docs/dev-cycle.md: review, unset by the interim note (T3, G19)"

**Location:** `test/scripts/build-loop-read.bats:70`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers docs/dev-cycle.md at 2e711a7b. The test asserts only the policy line (also noted in override row 257).

`docs/dev-cycle.md:7`: `Build-loop policy: review (interim; Q-103)`, which fails the exact regex. E1 test 4 passes.

**Evidence:** `docs/dev-cycle.md:7`, `test/scripts/build-loop-read.bats:70-76`; `$S/logs/baseline.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 31: "A replace ref for main's blob, even with core.useReplaceRefs set, is not followed."

**Location:** `test/scripts/build-loop-read.bats:82`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the repo-config case the test plants. It does not cover caller `-c` or octal-count environments (Claim 16b).

E1 test 5 passes. E2 `nocfg` fails it at `:84`.

**Evidence:** `test/scripts/build-loop-read.bats:82-84`; `$S/logs/baseline.log`, `$S/logs/mutant-nocfg.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 32: "A never list hidden in markup turns self-merge off rather than being skipped."

**Location:** `test/scripts/build-loop-read.bats:117`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** The test's own case (`- [x] Self-merge never: b/` as the only never line) does turn self-merge off. As a general statement it misses the settled case of a hidden list next to an exact never line, which is skipped (Claim 4b; override row 256). It does not re-raise that behaviour.

`test/scripts/build-loop-read.bats:118`: `settings 'Build-loop policy: self-merge' '- [x] Self-merge never: b/'; settings_is policy "$no"` passes (E1). E6 "hidden task-box never copy + exact none" gives `policy self-merge set`.

**Evidence:** `test/scripts/build-loop-read.bats:117-118`; `$S/logs/baseline.log`, `$S/logs/settings-exp.log`
**Legibility-target:** for-author

---

## Claim 33: A18: the duplicate-never case asserts that self-merge goes off

**Location:** `test/scripts/build-loop-read.bats:128-129`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two-never-lines case. It does not cover a review policy with a malformed never line (override row 246, deferred).

`test/scripts/build-loop-read.bats:129`: `settings_is never 'never malformed: more than one line starts "Self-merge never:" (lines 2 and 3)'; settings_is policy "$no"`. E2 `dupnever_ok` fails test 7.

**Evidence:** `test/scripts/build-loop-read.bats:128-129`; `$S/logs/mutants-summary.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 34: "Copies in some markup, a table, a link label or with a misplaced colon count as second lines too." / "A never line the next unfenced line may continue is malformed."

**Location:** `test/scripts/build-loop-read.bats:130`, `test/scripts/build-loop-read.bats:139`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the eight listed copy shapes and the next-line rule. The test exercises only a directly adjacent line (`:140-141`); the fenced case is verified by E6, not by the suite.

E1 test 7 passes. E6 covers the fenced next-line cases (Claim 6).

**Evidence:** `test/scripts/build-loop-read.bats:130-143`; `$S/logs/baseline.log`, `$S/logs/settings-exp.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 35: "From a subdirectory and from a linked worktree, it reads the same main." (A19: "the worktree in the G20 test now commits its own change")

**Location:** `test/scripts/build-loop-read.bats:177-185`; commit 2e711a7b, A19 bullet
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the worktree's own commit (`git -C .../wt commit -qam wt`) and the `HEAD:$f` mutant being caught. The subdirectory case alone would not catch that mutant (its HEAD is main).

`test/scripts/build-loop-read.bats:180`: `for d in . "$BATS_TEST_TMPDIR/wt"; do printf 'Build-loop policy: review\n' > "$d/docs/dev-cycle.md"; done; git -C "$BATS_TEST_TMPDIR/wt" commit -qam wt`. E2 `headread` fails test 9 on `[.../wt] policy review set`.

**Evidence:** `test/scripts/build-loop-read.bats:177-185`; `$S/logs/mutant-headread.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 36: Commit 2e711a7b, A16 bullet: "A GIT_CONFIG_COUNT pair, appended after any the caller passed, sets it false; a test plants a replace ref with the config set."

**Location:** commit 2e711a7b message (`scripts/build-loop.sh:69`)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** "a test plants a replace ref with the config set" is true (Claim 31). "appended after any the caller passed" is refuted for caller `GIT_CONFIG_PARAMETERS` pairs and leading-zero counts, as in Claim 16b. The most severe part decides the verdict. Both inputs are caller environment only.

Same evidence as Claim 16b: `policy self-merge set` under `GIT_CONFIG_PARAMETERS="'core.useReplaceRefs'='true'"` (E3) and under `GIT_CONFIG_COUNT=010` (E5).

**Evidence:** `scripts/build-loop.sh:69`; `$S/logs/cfg-exp.log`, `$S/logs/cfg-exp3.log`
**Legibility-target:** for-author

---

## Claim 37: Commit 2e711a7b: Q-112/R4/A17, A18, A20-A22 bullets and "Merges feat/build-loop-u1a's iteration-4 fix first"

**Location:** commit 2e711a7b message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each bullet against the code at 2e711a7b. The "A21 ... next unfenced line" bullet holds for the header and the WHY, but the SETTINGS_AWK comment was not updated (Claim 19). It does not cover the `--help` bullet (Claim 38) or A16 (Claim 36).

Q-112/A17: Claim 4a. A18: Claim 33. A20: header `scripts/build-loop.sh:11-12` (Claim 2). A21: `:22`, `:159`. A22: `test/scripts/build-loop-read.bats:130` says "some markup". Merge: 2e711a7b's parent is d06e61a6, `Merge branch 'feat/build-loop-u1a' into feat/build-loop-u1b`, whose second parent is 4aa2e98e `fix(dev-cycle): help prints the whole header; readers set pipefail themselves (U1a iteration 4 ...)`.

**Evidence:** `scripts/build-loop.sh:11-23`, `scripts/build-loop.sh:159`, `test/scripts/build-loop-read.bats:129-130`; `git log -1 --format=%P 2e711a7b`; `$S/logs/mutants-summary.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 38: Commit 2e711a7b: "--help prints the header up to its first non-comment line (no fixed range), as dev-cycle.sh now does." and "~417 changed code lines against U1a"

**Location:** commit 2e711a7b message
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** "No fixed range" and "as dev-cycle.sh now does" are verified (`scripts/dev-cycle.sh:112` has the same sed). "~417" is verified (195 + 36 + 186 from `git diff --stat`). "First non-comment line" carries the empty-line imprecision from Claim 15, which is the only thing that keeps this from Verified.

`scripts/dev-cycle.sh:112`: `-h|--help) sed -n '2,/^[^#]/{/^#/p}' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;`. `git diff --stat feat/build-loop-u1a...2e711a7b`: `scripts/build-loop.sh | 195`, `test/lib/build-loop-fixtures.bash | 36`, `test/scripts/build-loop-read.bats | 186`.

**Evidence:** `scripts/build-loop.sh:57`, `scripts/dev-cycle.sh:112`; `$S/logs/help-blank-and-printf.log`
**Legibility-target:** for-author

---

## Claim 39: Commit 2e711a7b: "Override-log rows: R4 (per Q-112), A23 and iteration 3's C1, C2, C4-C6, C8, C9."

**Location:** commit 2e711a7b message; `docs/reviews/override-log.md:256-264`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the mapping to rows 256 (R4), 257 (A23), 258 (C1), 259 (C2), 260 (C4), 261 (C5), 262 (C6), 263 (C8), 264 (C9). It does not cover the rows' reasons (Claims 40-45).

Each row cites its item, e.g. `docs/reviews/override-log.md:258` "(performance; iteration 3 C1)" and `:264` "(iteration 3 C9)".

**Evidence:** `docs/reviews/override-log.md:256-264`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 40: Row 256: "self-merge now needs a valid exact never line, so a hidden never list turns self-merge off. A hidden copy next to an exact line is ignored, and the exact line governs."

**Location:** `docs/reviews/override-log.md:256`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both halves on task-box and link shapes. It does not judge the acceptance decision (Q-112, the user's).

E6: "hidden link never copy only" turns self-merge off; "hidden task-box never copy + exact none" has the exact line governing (`never none: line 2`); "hidden task-box policy copy + exact review" is detected as a copy; "hidden task-box policy copy only" gives review. No hidden shape raised the policy.

**Evidence:** `scripts/build-loop.sh:108-112`, `scripts/build-loop.sh:175-182`; `$S/logs/settings-exp.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 41: Row 257: "1d79ffef's message says \"any link\", and \"T3's real-file test would catch one\" holds for the policy key only"

**Location:** `docs/reviews/override-log.md:257`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** The second half is verified (test 4 asserts only the policy line). The quoted phrase "any link" is not in 1d79ffef's message, which says "a link ... so any of them is a second line". The row's reading of that sentence is fair, but the quotation marks present a paraphrase as a quote.

1d79ffef message: "copies with markup closing before the colon, a table cell, a link or \"Self-merge never :\" were hidden. A line now counts as a copy when its letters alone, case folded, start with the key's, so any of them is a second line"; Notes: "(docs/dev-cycle.md has none; T3's real-file test would catch one)". `test/scripts/build-loop-read.bats:74` checks `line policy` only.

**Evidence:** `git log -1 --format=%B 1d79ffef`; `test/scripts/build-loop-read.bats:70-76`
**Legibility-target:** for-author

---

## Claim 42: Row 258: "globform is quadratic per entry, ~11 s on an 80 KB entry"

**Location:** `docs/reviews/override-log.md:258`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one 79,999-byte `a/a/...` entry on this host (10.3 s). It does not measure other shapes or hosts.

Each loop pass copies the rest of the entry (`c="${rest%%/*}"; rest="${rest#*/}"`, `scripts/build-loop.sh:125`). E8: `globform: 10.267 s`, rc 0.

**Evidence:** `scripts/build-loop.sh:121-128`; `$S/logs/perf.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 43: Row 259: "dev-cycle.sh's lib readers have no replace-ref guard" and Row 262: "The plan's \":74\" still says pathform globs; never uses globform"

**Location:** `docs/reviews/override-log.md:259`, `docs/reviews/override-log.md:262`
**Type:** Reference / Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers dev-cycle.sh at 2e711a7b and the plan's line 74. It does not cover U3b's planned guard.

A grep of scripts/dev-cycle.sh for `replace|useReplaceRefs` finds nothing (paraphrased — no quote available because the claim covers absence of code). `docs/working/plan-build-loop-handoff.md:74`: "`docs/dev-cycle.md` may add `Self-merge never: GLOB …` (pathform globs, one line, read from main's commit)".

**Evidence:** `scripts/dev-cycle.sh`, `docs/working/plan-build-loop-handoff.md:74`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 44: Row 260: "The lib's own tests cover main_entry's error and a failed blob read (dev-cycle.bats)"

**Location:** `docs/reviews/override-log.md:260`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the presence of the two assertions in dev-cycle.bats. It does not establish that build-loop.sh's own arms (`scripts/build-loop.sh:86`, `:89-90`) are exercised.

`test/scripts/dev-cycle.bats:1273`: `[ "$output" = "skip Q-1: the default branch's tree could not be read, so docs/working/questions.md is not read" ]`; `:1257`: `[ "$output" = "skip Q-1: docs/working/questions.md could not be read from the default branch" ]`.

**Evidence:** `test/scripts/dev-cycle.bats:1257`, `test/scripts/dev-cycle.bats:1273`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 45: Row 261: "With Q-112's rule, self-merge implies a valid never line, so an empty NEVER under self-merge means \"none\"." and Row 264: "\"Build-loop policy: self-merge\" followed by \"except on Fridays\" still reads as set"

**Location:** `docs/reviews/override-log.md:261`, `docs/reviews/override-log.md:264`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Row 261 holds because `POLICY=self-merge` needs `never_ok`, and the only `never_ok` path with an empty NEVER is the `none` arm (`:172`). Row 264 holds as stated. It does not judge either acceptance.

`scripts/build-loop.sh:172`: `elif [[ "$v" == none ]]; then never_ok=1; NEVER_LINE="never none: ..."` (NEVER stays `()` from `:137`). E6 "row 264: policy then except on Fridays": `policy self-merge set: line 1`.

**Evidence:** `scripts/build-loop.sh:137`, `scripts/build-loop.sh:171-181`; `$S/logs/settings-exp.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claims Requiring Attention

### Incorrect
- **Claim 16b** (`scripts/build-loop.sh:67-69`): "add a command-line config pair after any the caller passed" fails for a caller's `git -c` pairs (`GIT_CONFIG_PARAMETERS`, read after the COUNT pairs; `policy self-merge set` through a replace ref) and for a leading-zero `GIT_CONFIG_COUNT` (`010`: the pair lands at index "010" while bash sets the count to 9 (octal), so git reads pairs 0-8 and never the guard). Fix: say "after any GIT_CONFIG_COUNT pair the caller passed", and/or validate the count as plain decimal and handle `GIT_CONFIG_PARAMETERS`. Caller environment only.
- **Claim 36** (commit 2e711a7b, A16 bullet): same "appended after any the caller passed" overclaim. History only.

### Stale
- None.

### Mostly Accurate
- **Claim 4b** (`scripts/build-loop.sh:16-17`): a hidden never list turns self-merge off only when it is the sole never line; next to an exact never line it is skipped (settled, row 256). Wording only.
- **Claim 15** (`scripts/build-loop.sh:57`): the help range ends at the first line starting with a character other than `#`, not at an empty line; output today is exactly lines 2-38.
- **Claim 19** (`scripts/build-loop.sh:99-100`): "the line after the first" should be "the next line outside a fence, or none (NEXT 1)", as A21 asked; only this comment was left.
- **Claim 32** (`test/scripts/build-loop-read.bats:117`): same as 4b, in the test comment.
- **Claim 38** (commit 2e711a7b, --help bullet): same nuance as Claim 15; the "~417" count holds.
- **Claim 41** (`docs/reviews/override-log.md:257`): "any link" is not a verbatim phrase of 1d79ffef (it says "a link ... so any of them").

### Unverifiable
- None.

---

## Goal-Alignment Note

**Success criterion (verbatim):** A report saved at the output path named in your tail, structured per your skill, covering the full unit diff at 2e711a7b.

**Answered:** Yes. Saved at `docs/reviews/code-fact-check-report-build-loop-u1b-r1.md` with `Commit: 2e711a7b` first. It covers every checkable claim in scripts/build-loop.sh, the fixture, the bats suite, commit 2e711a7b's message and override rows 256-264, plus the ten brief items. Each executed claim has its command, cwd, exit code, timestamp and log file.

**Out of scope:** scripts/lib/dev-cycle-read.sh's own claims (U1a; read only as context); U1c's constraints and --status; the earlier docs/reviews/* artifacts; whether the settled residuals (Q-112, Q-113, rows 222-264) are the right calls.

**Escalate:**
- Claim 16b / 36 (Incorrect): the replace-ref guard's "after any the caller passed" does not hold against a caller's `git -c` (`GIT_CONFIG_PARAMETERS`) or a leading-zero `GIT_CONFIG_COUNT`. Both showed `policy self-merge set` from a replaced blob in a scratch repo. This is the orchestrator's own environment, not repo text, so it is not a raise by a loop. It is new at 2e711a7b (A16's fix) and not covered by any override row, so the orchestrator should route it (comment fix, or a decimal check plus `GIT_CONFIG_PARAMETERS` handling).
- No input found where hidden markup raises the policy or adds self-merge. The Q-112 premise holds at 2e711a7b.

**Questions / Decisions:** None for the user. Side observation, not a claim verdict: with the config pair in place, `GIT_NO_REPLACE_OBJECTS=1` is redundant under the suite (mutant `nonoreplace` passes).
