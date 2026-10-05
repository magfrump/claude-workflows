Commit: 2e711a7b

# Code Fact-Check Report

**Commit:** 2e711a7b
**Replication:** k=3
**Repository:** /workspace/.claude/wt-build-loop-u1b (claude-workflows, branch feat/build-loop-u1b)
**Scope:** Unit diff `feat/build-loop-u1a...2e711a7b`: comments, test names and test comments in scripts/build-loop.sh, test/lib/build-loop-fixtures.bash and test/scripts/build-loop-read.bats; the u1b override-log rows (256-264 in depth, plus row 239 whose premise changed); and commit 2e711a7b's message. Review iteration 4 (final confirming pass). Merged from replicates `-r1.md` (47 claims), `-r2.md` (32) and `-r3.md` (35), most-severe-wins, with annotations merged by union, emitted at the finest granularity any replicate used.
**Checked:** 2026-10-05
**Total claims checked:** 58
**Summary:** 46 verified, 7 mostly accurate, 1 stale, 2 incorrect, 2 unverifiable

The baseline `bats test/scripts/build-loop-read.bats` passed 9/9 for all three replicates. Execution logs are in each replicate's scratch dir, written below as `$S1`, `$S2`, `$S3` = `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i4/fc-r{1,2,3}`. Execution records (E-numbers) are each replicate's own and are defined in that replicate's report header. All three replicates read the hallucination-pattern log; r1 and r3 checked the one count claim ("~417") against it, and it holds.

Where a replicate verdicted only a compound claim, its verdict appears on each sub-claim row marked `(compound)`. On five rows (Claims 20, 39, 43, 44 and 22b) the merged verdict needed a ruling on a compound verdict. Following the precedent of the iteration-3 merge, a compound verdict decides a sub-claim row only when the replicate's reasoning ties its severity to that sub-claim. Claims 20 and 44 stay Verified because the compound's Mostly accurate comes from a sibling sub-claim. Each case says this in its Replicate annotations.

---

## Claims Requiring Attention

### Incorrect
- **Claim 16b** (`scripts/build-loop.sh:67-69`): "add a command-line config pair after any the caller passed" fails for a caller's `git -c` pairs (`GIT_CONFIG_PARAMETERS`, which git reads after the `GIT_CONFIG_COUNT` pairs) and for a leading-zero `GIT_CONFIG_COUNT` (`010`, `08`). Each gave `policy self-merge set` through a replace ref when the repo config sets `core.useReplaceRefs`. Fix: say "after any GIT_CONFIG_COUNT pair the caller passed", and/or validate the count as plain decimal and handle `GIT_CONFIG_PARAMETERS`. The problem is only in the caller's environment. (r1, r2 Incorrect; r3 Mostly accurate.)
- **Claim 40** (commit 2e711a7b, A16 bullet): the same "appended after any the caller passed" overclaim, in history. (r1, r2 Incorrect; r3 Mostly accurate (compound).)

### Stale
- **Claim 46** (`docs/reviews/override-log.md:239`): the row says --help prints a fixed line range that each edit re-derives. Since 2e711a7b, help prints the header up to its first non-comment line (`scripts/build-loop.sh:57`). (r3 only.)

### Mostly Accurate
- **Claim 4b** (`scripts/build-loop.sh:16-17`): a hidden never list turns self-merge off only when it is the sole never line. Next to an exact never line it is skipped (settled, row 256). Only the wording needs changing.
- **Claim 15** (`scripts/build-loop.sh:57`): the help range ends at the first line that starts with a character other than `#`, not at an empty line. Today's output is exactly lines 2-38. (r1 only; r2 and r3 Verified with the same caveat.)
- **Claim 19** (`scripts/build-loop.sh:99-100`): "the line after the first" should be "the next line outside a fence, or none (NEXT 1)". A21 fixed the header and the WHY but not this comment. (All three.)
- **Claim 33** (`test/scripts/build-loop-read.bats:117`): the same wording as 4b, in the test comment.
- **Claim 39** (commit 2e711a7b, Q-112 bullet): the same qualifier as 4b. (r3 (compound).)
- **Claim 43** (commit 2e711a7b, --help bullet): the same nuance as Claim 15. (r1 (compound).)
- **Claim 48** (`docs/reviews/override-log.md:257`): "any link" is not a verbatim phrase of 1d79ffef, which says "a link ... so any of them".

### Unverifiable
- **Claim 22b** (`scripts/build-loop.sh:130-131`): POLICY/NEVER consumers (--status, the gate) are not built yet. Verifying it needs U1c and U2. (r2; r1 and r3 Verified (compound) with the same does-not-establish clause.)
- **Claim 49** (`docs/reviews/override-log.md:258`): r2 found that the 4 KB cut bounds printed output, not globform's input, and did not re-measure the timing. r1 (10.3 s) and r3 (22.2 s) measured the timing and Verified it.

---

## Claim 1: "three lines from the default branch's commit, never the working tree (a build loop can write any working tree)"

**Location:** `scripts/build-loop.sh:9-10`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the one read path, `git cat-file blob "$MAIN_SHA:$f"` after `main_entry` (which lists `$MAIN_SHA`'s tree), for an uncommitted edit, a commit on a checked-out loop branch, a subdirectory and a linked worktree. It does not establish which commit counts as the default branch when origin/HEAD names a loop's branch (override row 247, deferred).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—
**Replicate annotations:** r1+r2: "does not establish how resolve_main chooses MAIN_SHA when origin/HEAD names a loop branch" (deferred; r1 cites row 247, r2 row C18).

The only blob read is at `scripts/build-loop.sh:89`: `FILE_OUT="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk "$FENCE_AWK$2")"`. The entry check is `main_entry`, which runs `git ls-tree -t --full-tree "$MAIN_SHA"` (`scripts/lib/dev-cycle-read.sh:263`). r1 E1: tests 5 and 9 pass. r1 E2: the `headread` mutant fails tests 5, 7 and 9, and test 9 fails on the worktree case (`[.../wt] policy review set`). r2's `head-not-main` mutant gave the same result.

**Evidence:** `scripts/build-loop.sh:78-95`, `scripts/lib/dev-cycle-read.sh:258-274`, `test/scripts/build-loop-read.bats:78-91`, `test/scripts/build-loop-read.bats:169-186`; `$S1/logs/baseline.log`, `$S1/logs/mutant-headread.log`

---

## Claim 2: "a second copy, or a file the lib's FENCE_AWK refuses, gives review, 3 and malformed (WHY says which)"

**Location:** `scripts/build-loop.sh:11-12`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the per-key reading (a second copy of a key gives that key's fallback: policy `review unset`, slots `3 default`, never `malformed`) and the whole-file reading for a refused file (all three lines). It does not claim, and the code does not do, that a copy of one key changes the other two lines. An absent file is a third case, which gives `never none` (Claim 8).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "The header does not group absent with 'refuses', so this is consistent." · r3: "does not establish anything about hidden copies (Claim 6) or about readers other than `--settings`."

Per key, `scripts/build-loop.sh:153`, `:176` and `:184` print `never malformed: $(many ...)`, `policy review unset: $(many ...)` and `slots 3 default: $(many ...)`. A refused file takes the `main_file` failure arm: `POLICY_LINE="policy review unset: $why"; SLOTS_LINE="slots 3 default: $why"` and `NEVER_LINE="never malformed: $why"` (`scripts/build-loop.sh:141-143`). r1 E6 "second copy of all three keys" prints all three fallbacks. "Second copy of policy only" leaves `slots 4 set` and `never none: line 4 ...`. "Refused file (html)" prints review/3/malformed, each naming line 2's reason. r2 and r3 ran the same shapes and got the same output (r2 `cases1.log`, r3 `nextline-exp.log`).

**Evidence:** `scripts/build-loop.sh:139-188`; `$S1/logs/settings-exp.log`, `$S2/logs/cases1.log`, `$S3/logs/nextline-exp.log`

---

## Claim 3: "Set only by \"Build-loop policy: self-merge\" or \"...: review\", exactly (one trailing CR dropped); else review."

**Location:** `scripts/build-loop.sh:14-15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the exact-match regex, the single trailing CR (removed by `sub(/\r$/, "")`), and the refusal of a second CR (FENCE_AWK's `cr`). It does not cover the self-merge precondition, which is Claim 4a.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

`scripts/build-loop.sh:177`: `elif [[ "${text[policy]}" =~ ^Build-loop\ policy:\ (self-merge|review)$ ]]; then`. `:104`: `{ sub(/\r$/, "") }`. E1 test 1 (CR) and test 2 (five variants) pass for all replicates. r1 E6 "policy two CRs" gives `policy review unset: line 1 ... holds a carriage return that does not end it`.

**Evidence:** `scripts/build-loop.sh:104`, `scripts/build-loop.sh:175-182`, `scripts/lib/dev-cycle-read.sh:209-215`; `$S1/logs/baseline.log`, `$S1/logs/settings-exp.log`

---

## Claim 4a: "Self-merge also needs a valid never line"

**Location:** `scripts/build-loop.sh:15-16` (also `:151`: "self-merge needs a valid one (never_ok)")
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every path that leaves `never_ok` empty (no never line, two never lines, a malformed line, a file not read): none of them yields `policy self-merge set`. Only `:172` (`none`) and `:173` (a checked list) set `never_ok=1`. Both need `cnt[never]` to be 1, the text to start `Self-merge never: `, single spaces, a blank next line and every entry to pass globform. It does not establish anything about the gate (U2) honouring POLICY.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r3: "does not establish how future consumers (U1c `--status`, U2's gate) use POLICY." · r2: `hidden-policy-review` (exact self-merge plus `- [ ] Build-loop policy: review`) gives review, "a copy that LOWERS the policy, not one that raises it".

`scripts/build-loop.sh:179-181`:
```bash
      if [[ "$v" == self-merge && -z "$never_ok" ]]; then
        POLICY_LINE="policy review unset: line ${first[policy]} reads self-merge, but there is no valid Self-merge never: line (\"Self-merge never: none\" for an empty list), so self-merge is off"
      else POLICY="$v"; POLICY_LINE="policy $v set: line ${first[policy]} $where"; fi
```
`never_ok` starts empty (`local ... never_ok=""`, `:135`) and is set only at `:172-173`. On the not-read arm (`:139-143`), the policy line is `review unset` without reaching `:179`. The mutants that remove this condition were killed in every replicate: r1 `noneverok` and `dupnever_ok` each fail test 7; r2 `never-ok-ignored` and `copies-set-ok` fail test 7; r3 `nevercheck2`, `neverinit1` and `dupnever` fail test 7. r1 E6: every malformed or missing never case prints the `reads self-merge, but there is no valid ...` line.

**Evidence:** `scripts/build-loop.sh:134-188`; `$S1/logs/mutants-summary.log`, `$S1/logs/settings-exp.log`, `$S2/logs/mutants.log`, `$S3/logs/mut-dupnever.log`

---

## Claim 4b: "so a list hidden in markup turns it off rather than being skipped"

**Location:** `scripts/build-loop.sh:16-17`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** True when the hidden list is the only never-like line. It does not hold when an exact never line is also present: then the hidden list is skipped and the exact line governs. That behaviour is settled (override row 256: "A hidden copy next to an exact line is ignored, and the exact line governs"). This verdict is about the wording only. It does not re-raise the defect: the hidden line neither raises the policy nor adds self-merge, which the exact `none` line already allowed.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r2 (scope of its Verified compound): "does not establish that a hidden copy NEXT TO an exact never line is noticed. Such a copy is ignored and the exact line governs ... That is the shape override row 256 accepts, so it is not re-raised here." · r3: "an unchecked task box `- [ ]` adds no letters and is caught as a copy ... so only a checked box hides one." · r3: the same wording is in `test/scripts/build-loop-read.bats:116` and in commit 2e711a7b's Q-112 bullet (Claims 33, 39).

r1 E6, "hidden link never copy only" (`[x](y) Self-merge never: b/`), gives `policy review unset: line 1 reads self-merge, but there is no valid ...` and `never none: no line starts "Self-merge never:"`, so the claim holds there. r1 E6, "hidden task-box never copy + exact none" (`Self-merge never: none`, blank, `- [x] Self-merge never: b/`), gives `policy self-merge set` and `never none: line 2 ... lists none`, so the hidden `b/` list is skipped. r3 E8 reproduces both cases. Precise version: "a never list hidden in markup, when there is no exact never line, turns self-merge off rather than being skipped; next to an exact never line it is ignored (best effort)."

**Evidence:** `scripts/build-loop.sh:108-112`, `scripts/build-loop.sh:152-173`, `docs/reviews/override-log.md:256`; `$S1/logs/settings-exp.log`, `$S3/logs/hidden-exp.log`

---

## Claim 5: "Loops at once: \"Build-loop slots: N\", N from 1 to 9; else 3."

**Location:** `scripts/build-loop.sh:18-19`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the regex and the fallback. It does not establish that any later mode uses the number (U1b only prints it).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

`scripts/build-loop.sh:185`: `elif [[ "${text[slots]}" =~ ^Build-loop\ slots:\ ([123456789])$ ]]; then SLOTS_LINE="slots ${BASH_REMATCH[1]} set: ...`. E1 test 6 passes in all replicates (0, 10, a trailing space, 05, three, a copy, fenced). r1 E6 "slots with CR" gives `slots 5 set`.

**Evidence:** `scripts/build-loop.sh:183-186`; `$S1/logs/baseline.log`, `$S1/logs/settings-exp.log`

---

## Claim 6: "\"Self-merge never: GLOB ...\" (or \"...: none\"), single spaces, and the next line outside a fence blank or the end."

**Location:** `scripts/build-loop.sh:21-23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the next-line rule across a fence, a CR-only line, a whitespace-only line, end of file, a one-line HTML comment and a plain text line. It does not cover lines FENCE_AWK refuses, since those refuse the whole file (Claim 2).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: "does not establish the same rule for the policy or slots keys. `nx` is computed for them but unused, as override row 264 accepts."

In SETTINGS_AWK, `fence($0) { next }` (`:105`) runs before `if (pk != "") { nx[pk] = ($0 ~ /^[ \t]*$/); pk = "" }` (`:107`), so fence lines and fenced content never decide NEXT. `nx[k] = 1` is set when the key line is first seen (`:112`), which covers end of file. r1 E6: "never then fence then b/" gives malformed. "Fence then blank", "fence to EOF", "CR-only line", "whitespace-only line" and "at EOF" give `never a/ set`. "One-line html comment" gives malformed. r2 (`fenced-next`, `ws-next`, `crlf-next`, `eof`, `comment-next`) and r3 E7 got the same results. The next-line mutant is killed by test 7 in all three replicates (r1 `nonext`, r2 `drop-next-check`, r3 `nextcheck`).

**Evidence:** `scripts/build-loop.sh:103-118`, `scripts/build-loop.sh:157-160`; `$S1/logs/settings-exp.log`, `$S2/logs/cases1.log`, `$S3/logs/nextline-exp.log`

---

## Claim 7: "A glob uses letters, digits, . _ - / * ? (a trailing / ignored when comparing), has no empty, . or .. part, does not start with / or -, and is listed once."

**Location:** `scripts/build-loop.sh:23-26`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers globform and the `seen` check, both on `${g%/}`. It does not establish how U2's gate will match the globs.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: "'A trailing /' means exactly one: `a//` is refused because an empty part remains." · r2+r3: a glob literally named `none` in a longer list reads as a glob (`Self-merge never: none a/` gives `never none a/ set`; r2 adds that `None` reads as a glob), consistent with the text. · r3: "'Letters' means ASCII letters (NAMECHARS)."

`scripts/build-loop.sh:123`: `[[ "$1" =~ ^[*?$NAMECHARS]+$ && "$1" != /* && "$1" != -* ]] || return 1`. `:126`: `[[ -n "$c" && "$c" != "." && "$c" != ".." ]] || return 1`. `:166-168` call `globform "${g%/}"` and check `seen[${g%/}]`. `NAMECHARS` is the ASCII list at `scripts/lib/dev-cycle-read.sh:139`. r1 E6: `*.sh ??/` is set. `a a/` gives "lists entry 2 twice". `a//` gives "not an allowed glob form" (only one `/` is stripped). E1 test 7's 15 malformed variants pass.

**Evidence:** `scripts/build-loop.sh:121-128`, `scripts/build-loop.sh:161-170`; `$S1/logs/settings-exp.log`, `$S1/logs/baseline.log`

---

## Claim 8: "Malformed (or a file not read) turns self-merge off." / "An absent file sets nothing; one that is not read turns self-merge off."

**Location:** `scripts/build-loop.sh:26-27`, `scripts/build-loop.sh:142-143`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `never malformed` for a refused or unreadable file, `never none` for an absent one, and `policy review unset` in both. It does not cover main_file's `error` and failed-read arms by test (override row 260); they share the same `else` branch at `:143`.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r2: the `error` and failed-read arms are not exercised by this suite (override row 260 defers to the lib's tests).

`scripts/build-loop.sh:143`: `if [[ "$FILE_WHY" == absent ]]; then NEVER_LINE="never none: $why"; else NEVER_LINE="never malformed: $why"; fi`. r1 E6 "absent": `never none: no docs/dev-cycle.md on the default branch`. r1 E2: `absentok` fails test 3.

**Evidence:** `scripts/build-loop.sh:139-143`; `$S1/logs/settings-exp.log`, `$S1/logs/mutant-absentok.log`

---

## Claim 9: "Copies are found best effort: a line counts as one when its letters alone, case folded, start with the key's (\"buildlooppolicy\"). Markup that adds letters (a task box, a tag) can still hide a copy; only an exact line ever sets a value."

**Location:** `scripts/build-loop.sh:28-31`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the letters-only, ASCII case-folded prefix match (mawk, LC_ALL=C), the task-box and link shapes that hide a copy, and the exactness of every setting (policy and slots regexes, never prefix plus single-space shape). It does not enumerate every hiding shape: entities and zero-width characters are settled (rows 248, 256).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r3: "A 'task box' hides a copy only when checked (`[x]` adds a letter, `[ ]` does not)." · r3: non-ASCII letter bytes are dropped like punctuation under `LC_ALL=C`. · r2: a prose line `Build-loop policy is described above.` counts as a copy (fails closed to review). · r1: "Build-loop policies are listed above." is not a copy ("policies" ≠ "policy" at letter 15).

`scripts/build-loop.sh:108-111`: `s = tolower($0); gsub(/[^a-z]/, "", s); ...; if (index(s, "buildlooppolicy") == 1) k = "policy"`. r1 E6: `- [ ] Build-loop policy: self-merge` alone gives `no line starts "Build-loop policy:"` (hidden, review). `\xef\xbb\xbfBuild-loop policy: review` on line 2 counts as a copy.

**Evidence:** `scripts/build-loop.sh:103-118`, `scripts/build-loop.sh:157`, `scripts/build-loop.sh:177`, `scripts/build-loop.sh:185`; `$S1/logs/settings-exp.log`, `$S3/logs/hidden-exp.log`

---

## Claim 10a: "Acts on $PWD's git repo, like dev-cycle.sh, and needs its default branch found by name (origin/HEAD, main or master)."

**Location:** `scripts/build-loop.sh:33`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the `rev-parse --show-toplevel` and cd, and the `main_by_name` exit. It does not establish which branch counts as default when origin/HEAD names a loop branch (Claim 1).
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=Verified (compound)
**Replicate annotations:** none

`scripts/build-loop.sh:62`: `ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Not inside a git repository" >&2; exit 1; }`. `:72`: `main_by_name || { echo "build-loop.sh needs a default branch found by name ..." >&2; exit 1; }`. r1 E1 test 8 (a branch renamed to trunk: exit 1, "needs a default branch") passes.

**Evidence:** `scripts/build-loop.sh:62-72`, `scripts/lib/dev-cycle-read.sh:389-411`; `$S1/logs/baseline.log`

---

## Claim 10b: "Read-only: writes nothing."

**Location:** `scripts/build-loop.sh:34`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers one `--settings` run on a clean scratch repo: no file or mtime under .git changed. It does not establish a dirty-index repo, where no command here refreshes the index (paraphrased, no quote available because this is an absence claim: no `git status`, `update-index` or write command appears in the script, by reading `:40-195`).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: "does not establish the absence of git-internal side effects such as lazy object fetches." · r1+r3: the script's git calls are only rev-parse, show-ref, symbolic-ref, ls-tree and cat-file (static reading of the script and the lib functions it calls).

r2 command: `cd $S2/repos/fridays && ls -laR .git (before) ; bash $S2/scripts/build-loop.sh --settings ; ls -laR .git (after) ; diff`. cwd `$S2/repos/fridays`, rc=0, diff empty, 2026-10-05T16:46Z.

**Evidence:** `scripts/build-loop.sh:40-195`; `$S2/logs/ro-before.txt`, `$S2/logs/ro-after.txt`, `$S2/logs/ro-diff.txt`

---

## Claim 11: "Output passes through the lib's scrub (but for the start-up errors about perl and the lib); printed repo text is data."

**Location:** `scripts/build-loop.sh:35-36`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the order: the perl and lib errors (`:42`, `:48`) come before `scrub_reexec` (`:51`), and every later message comes after it. It does not re-verify the scrub's own coverage (U1a's lib).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** none

`scripts/build-loop.sh:42-51` holds the `command -v perl` and `[[ -f "$READ_LIB" ]]` exits, then `source "$READ_LIB"` and `scrub_reexec "${BASH_SOURCE[0]}" "$@"`. `scripts/lib/dev-cycle-read.sh:79`: `{ DEV_CYCLE_SCRUBBED=1 bash "$self" "$@" 2>&1 1>&3 3>&- | scrub >&2; } 3>&1 | scrub` covers both streams.

**Evidence:** `scripts/build-loop.sh:40-51`, `scripts/lib/dev-cycle-read.sh:76-81`

---

## Claim 12: "Exit: 0 every line printed (or help); 1 bad usage, not a git repo, no perl or lib/dev-cycle-read.sh, or no default branch found by name."

**Location:** `scripts/build-loop.sh:37-38`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each listed exit. It does not cover caller-environment failures outside the list: a `GIT_CONFIG_COUNT` that git rejects (`abc`, `08`, a count with no KEY_0) exits 1 with the message "Not inside a git repository" (git rev-parse fails first), and `GIT_CONFIG_COUNT=' 1'` exits 1 through bash's `export: not a valid identifier`.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r2+r3: a caller's malformed `GIT_CONFIG_COUNT` (`abc`, or a count with missing keys) exits 1 as "Not inside a git repository" inside a valid repo, which fails closed but names the wrong cause (r2: "the stated reason is not the real one"). · r1: `GIT_CONFIG_COUNT=' 1'` exits 1 via `export: not a valid identifier`. · r2: `-h extra` gives exit 0.

`scripts/build-loop.sh:53`: `usage() { echo "$1 (usage: build-loop.sh --settings)" >&2; exit 1; }`. `:57`: `... exit 0 ;;`. E1 tests 8 and 9 pass in all replicates (usage, no default branch, not a repo, missing lib). r1 E3/E4 and r2 `replace.log` show the `GIT_CONFIG_COUNT` cases above.

**Evidence:** `scripts/build-loop.sh:42-72`, `scripts/build-loop.sh:190-195`; `$S1/logs/baseline.log`, `$S1/logs/cfg-exp.log`, `$S1/logs/cfg-exp2.log`, `$S2/logs/replace.log`, `$S3/logs/replace-exp.log`

---

## Claim 13: "before the cd: relative paths work"

**Location:** `scripts/build-loop.sh:43`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a relative script path given from a subdirectory. It does not cover a script reached through a symlink (`dirname` of the link, not its target).
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

`scripts/build-loop.sh:43`: `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` runs before `cd "$ROOT"` (`:63`). r1 E9: `bash ../../base/scripts/build-loop.sh --settings` from `repo-set/sub` prints three lines, exit 0.

**Evidence:** `scripts/build-loop.sh:43-63`; `$S1/logs/relpath.log`

---

## Claim 14: "The reader shared with dev-cycle.sh, from this script's own directory (never the target repo's scripts/lib/), so a copy of scripts/ with its lib/ is self-contained."

**Location:** `scripts/build-loop.sh:44-48`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers sourcing from `$SCRIPT_DIR/lib/` and the missing-lib exit. It does not establish that dev-cycle.sh sources the same file (U1a).
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified
**Replicate annotations:** r3: "does not establish anything about the lib's own contents."

`scripts/build-loop.sh:47`: `READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"`. E1 test 9 passes: a `scripts/lib/dev-cycle-read.sh` planted in the target repo is not run, and a lone copy exits 1 naming the missing lib. E1 itself ran from a copy of scripts/ (r1 and r3).

**Evidence:** `scripts/build-loop.sh:44-50`, `test/scripts/build-loop-read.bats:169-176`; `$S1/logs/baseline.log`, `$S3/logs/baseline.log`

---

## Claim 15: "# the header, to its first non-comment line"

**Location:** `scripts/build-loop.sh:57`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** The output today is exactly lines 2-38 with `# ` removed. The verdict concerns the stated stopping rule: an empty line does not end the range, only a line whose first character is not `#`, and the empty line 39 prints nothing. It does not establish behaviour for a header that starts with a non-comment line 2.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3 (scopes of their Verified): `2,/^[^#]/` needs a non-`#` character to end, so an empty line inside the header does not end it. A later `#` block would print until the first non-empty, non-`#` line, and the claim "does not establish behaviour for a future header with such a blank line". · r3: `scripts/dev-cycle.sh:112` uses the identical command, and `--help` from `/` also works.

`scripts/build-loop.sh:57`: `sed -n '2,/^[^#]/{/^#/p}' "$0" | sed 's/^# \{0,1\}//'`. `^[^#]` needs a first character, so the empty line 39 does not match, and the range ends at line 40 (`set -euo pipefail`). r1 E7: `help.out` equals `help.want` (37 lines). With header line 32's `#` replaced by an empty line, the range still prints 36 lines, through line 38. Precise version: "the header's # lines, up to the first line that starts with another character".

**Evidence:** `scripts/build-loop.sh:1-40`, `scripts/build-loop.sh:57`; `$S1/logs/help.out`, `$S1/logs/help.want`, `$S1/logs/help-blank-and-printf.log`

---

## Claim 16a: "Read main's own objects: a replace ref could swap in any settings blob. core.useReplaceRefs in the repo's config would override the variable"

**Location:** `scripts/build-loop.sh:66-67`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers git 2.39.5: with `core.useReplaceRefs true` in .git/config, `GIT_NO_REPLACE_OBJECTS=1` alone does not stop a replace ref on main's blob. It does not establish other git versions. It also leaves out a side observation: with the config pair present, `GIT_NO_REPLACE_OBJECTS=1` is redundant under the tests (mutant `nonoreplace` passes).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r3: "does not establish other git versions" (2.39.5 only). · r1: with the pair present, `GIT_NO_REPLACE_OBJECTS=1` is redundant under the suite (mutant `nonoreplace` survives). · r2: a caller's `GIT_CONFIG_COUNT` pair setting it true is also overridden. The guard does not cover the `git -c` / `GIT_CONFIG_PARAMETERS` channel (Claim 16b).

r1 E2: mutant `nocfg` (pair removed, `GIT_NO_REPLACE_OBJECTS=1` kept) fails test 5 at `test/scripts/build-loop-read.bats:84` with `policy self-merge set: line 1`, so the replaced blob was read. r3 E4: `git cat-file with only env (no config pair)` prints `Build-loop policy: self-merge`, and with the count pair added it prints `Build-loop policy: review`.

**Evidence:** `scripts/build-loop.sh:66-70`, `test/scripts/build-loop-read.bats:82-84`; `$S1/logs/mutant-nocfg.log`, `$S1/logs/mutants-summary.log`, `$S3/logs/replace-exp.log`

---

## Claim 16b: "add a command-line config pair after any the caller passed."

**Location:** `scripts/build-loop.sh:67-69`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Holds for caller pairs passed through `GIT_CONFIG_COUNT`/`KEY_n`/`VALUE_n` with a plain decimal count (r1 E3: `COUNT=1` or `2` with a pair setting `true` still reads `policy review set`). It is refuted for two caller inputs. Both come from the orchestrator's own environment; neither repo text nor a loop's working tree can set them. This verdict does not rate exploitability.
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Mostly accurate
**Replicate annotations:** r2: "does not establish that any real orchestrator invokes the script under `git -c` or a git alias". A caller that runs the script through any `git -c` alias passes such a pair without setting the environment itself (`git -c core.useReplaceRefs=true -c "alias.bl=!bash .../build-loop.sh --settings" bl` gave self-merge). · r3: `GIT_CONFIG_COUNT=08` makes bash print `line 69: 08: value too great for base`, discard the rest of that command line without `set -e` firing, and exit 0 with `policy self-merge set`. · r3: "The verdict does not establish whether either form can reach the orchestrator's environment; a build loop does not set it." · r1+r2+r3 (fix wording): "after any GIT_CONFIG_COUNT pair the caller passed" (r3 adds "(a decimal count without leading zeros); a caller's `git -c`/GIT_CONFIG_PARAMETERS setting still wins"), or also clear or override `GIT_CONFIG_PARAMETERS` (r2) and validate the count as decimal (r1). · r1+r2+r3: escalated (see Escalations E1).

`scripts/build-loop.sh:69`: `cfg="${GIT_CONFIG_COUNT:-0}"; export "GIT_CONFIG_KEY_$cfg=core.useReplaceRefs" "GIT_CONFIG_VALUE_$cfg=false" GIT_CONFIG_COUNT=$((cfg + 1))`.
1. A caller's `git -c` pairs (`GIT_CONFIG_PARAMETERS`) are read after the `GIT_CONFIG_COUNT` pairs, so they win. r1 E3: `GIT_CONFIG_PARAMETERS="'core.useReplaceRefs'='true'"` gives `policy self-merge set` (the replaced blob) and `never none: line 3`. `git config --show-origin --get-all` with both set lists `command line: false` then `command line: true`. r2 (`caller-params-true`, `config-order.log`) and r3 E4 reproduce it.
2. A count with a leading zero is octal to bash and decimal to git. r1 E5: `GIT_CONFIG_COUNT=010` (pairs 0-9 set) exports `GIT_CONFIG_KEY_010` and `GIT_CONFIG_COUNT=9`, so git reads pairs 0-8 and never the guard. Output: `policy self-merge set`. r3 E5 reproduces it.

What the code does: it appends one pair at index `$GIT_CONFIG_COUNT` (read by bash arithmetic) and sets the count to one more. That puts the pair after the caller's `GIT_CONFIG_COUNT` pairs, but not after its `GIT_CONFIG_PARAMETERS` pairs, and not when the count has leading zeros. The same wording is in commit 2e711a7b's A16 bullet (Claim 40).

**Evidence:** `scripts/build-loop.sh:69-70`; `$S1/logs/cfg-exp.log`, `$S1/logs/cfg-exp3.log`, `$S2/logs/replace.log`, `$S2/logs/config-order.log`, `$S3/logs/replace-exp.log`, `$S3/logs/replace-octal.log`

---

## Claim 17: "A file on main: FILE_OUT is what awk program $2 (after FENCE_AWK) printed over it; or it returns 1 with FILE_WHY \"absent\" or why it was not read (main_entry, a failed read, or FENCE_AWK's \"odd N WHY\" / \"unbalanced N\")."

**Location:** `scripts/build-loop.sh:74-76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every return arm of main_file (`:78-95`). It does not claim FILE_OUT is empty on failure (it can hold the `odd`/`unbalanced` line), and the error and failed-read arms are verified only statically (override row 260).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "FILE_WHY for odd and unbalanced is a sentence built from FENCE_AWK's output, not the raw token." · r3: `set -o pipefail` (`:40`) is inherited by the `$(...)`, so a failed `cat-file` is caught. · r2: "FENCE_AWK holds functions only, so `$2`'s rules run after it."

`scripts/build-loop.sh:82-93` map each main_entry answer and awk result to FILE_WHY, from `absent) FILE_WHY=absent; return 1 ;;` through `unbalanced\ *) FILE_WHY="the code fence opened at line ${FILE_OUT#unbalanced } of $f is never closed, so the file is not read"; return 1 ;;`. E1 test 3 covers the absent, notdir, notfile, odd (comment, BOM) and unbalanced arms.

**Evidence:** `scripts/build-loop.sh:74-95`; `$S1/logs/baseline.log`

---

## Claim 18: "(best effort: most markup, a BOM or a misplaced colon cannot hide a copy)"

**Location:** `scripts/build-loop.sh:98-99`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the shapes in tests 2 and 7 (list marker, bold, heading, BOM on a later line, bold key, one-line comment, emphasis, code span, table, link label, `Self-merge never : `). It does not cover letter-adding markup, which the comment says is best effort.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1+r3: a BOM on line 1 refuses the file (FENCE_AWK `bom`, `scripts/lib/dev-cycle-read.sh:213`), while on a later line the BOM bytes are dropped as non-letters and the line counts as a copy.

r1 E1: tests 2 and 7 pass. r1 E6 "BOM on line 2 copy" gives `more than one line starts "Build-loop policy:" (lines 1 and 2)`.

**Evidence:** `scripts/build-loop.sh:108-111`, `scripts/lib/dev-cycle-read.sh:213`, `test/scripts/build-loop-read.bats:33-37`, `test/scripts/build-loop-read.bats:130-134`; `$S1/logs/baseline.log`, `$S1/logs/settings-exp.log`

---

## Claim 19: "whether the line after the first is blank (NEXT 1) or not"

**Location:** `scripts/build-loop.sh:99-100`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Right about the blank test. Imprecise about "the line after": NEXT is computed from the next line outside a fence (fence lines and fenced content are skipped), and NEXT is also 1 when no line follows. This does not affect the header (`:22`) or the WHY (`:159`), which say "outside a fence".
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate (compound)
**Replicate annotations:** r3: a whitespace-only (`[ \t]*`) line also counts as blank. · r1+r2+r3: A21 updated the header and the WHY but not this comment. r2 adds that this comment is a context line in the iteration-4 diff (`iter4-fix.diff` line 66).

`scripts/build-loop.sh:105-107`: `fence($0) { next }` comes before `if (pk != "") { nx[pk] = ($0 ~ /^[ \t]*$/); pk = "" }`, and `:112` sets `nx[k] = 1` at the key line. r1 E6: "never then fence then blank" gives NEXT 1 (set), although the physical next line is a fence. Precise version: "whether the next line outside a fence is blank, or there is none (NEXT 1)".

**Evidence:** `scripts/build-loop.sh:97-118`; `$S1/logs/settings-exp.log`, `$S2/logs/cases1.log`, `$S3/logs/nextline-exp.log`

---

## Claim 20: "One pass over docs/dev-cycle.md: per key, how many lines start with it, the first two line numbers, ... and the first line whole: \"KEY COUNT FIRST SECOND NEXT<TAB>LINE\""

**Location:** `scripts/build-loop.sh:101`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the END print and the reader at `:145-149`. SECOND is 0 when there is no second copy. It does not cover a LINE that holds a tab, where `${l#*$'\t'}` cuts at the first tab, which is the separator (correct).
**Replicate verdicts:** r1=Verified · r2=— · r3=Mostly accurate (compound)
**Replicate annotations:** r3 (merge note): r3 verdicted `:97-101` as one compound (its Claim 12). Its Mostly accurate is for the NEXT wording (Claim 19); r3 states "The output format matches `:117`", so its compound verdict does not decide this sub-claim.

`scripts/build-loop.sh:117`: `else for (k in c) print k " " c[k] " " l1[k] " " (k in l2 ? l2[k] : 0) " " nx[k] "\t" t[k]`. `:147`: `read -r k c l1 l2 nx <<<"${l%%$'\t'*}"`.

**Evidence:** `scripts/build-loop.sh:114-118`, `scripts/build-loop.sh:145-149`

---

## Claim 21: "A never entry: pathform's rule, but a .git* part (.github/) is allowed, since the list only adds refusals"

**Location:** `scripts/build-loop.sh:119-120`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers rule equivalence with `pathform "$1" glob` apart from the `[.][gG][iI][tT]*` component test. It does not verify the rationale (that the gate only adds refusals), which is U2's.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: does not establish "that U2's gate matches these globs as git pathspecs". · r3: does not establish "that U2 will use globform rather than pathform; override rows 238 and 262 defer that."

The lib's `pathform` (`scripts/lib/dev-cycle-read.sh:142-147`) uses `^[*?$NAMECHARS]+$`, `!= /*`, `!= -*`, and per part `-n`, `!= .`, `!= ..`, `!= [.][gG][iI][tT]*`. globform (`scripts/build-loop.sh:123-126`) has the same tests without the last one. r1 E6 "never with .GIT part" gives `never .GIT/x .git set`. Test 7 accepts `.github/ .gitignore`.

**Evidence:** `scripts/build-loop.sh:119-128`, `scripts/lib/dev-cycle-read.sh:140-149`; `$S1/logs/settings-exp.log`

---

## Claim 22a: "Sets POLICY, POLICY_LINE, SLOTS_LINE, NEVER (an array of the checked globs, each as written, a trailing / kept) and NEVER_LINE from main's commit."

**Location:** `scripts/build-loop.sh:129-130`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the assignments in read_settings (`:134-188`). NEVER is set whenever the never line is valid, also under a review policy.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: NEVER is reset when the file is not read (`:137` `NEVER=()`). · r1+r2+r3: `parts` is the unstripped split (`:163`); globform and `seen` use `${g%/}`, but the array keeps `g`.

`scripts/build-loop.sh:173`: `else never_ok=1; NEVER=("${parts[@]}"); NEVER_LINE="never $v set: ..."`. `parts` holds the entries as split, before `${g%/}`.

**Evidence:** `scripts/build-loop.sh:129-188`

---

## Claim 22b: "POLICY and NEVER are for the modes that judge a brief (--status, then the gate)."

**Location:** `scripts/build-loop.sh:130-131`
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers only that no code in this unit reads POLICY or NEVER (paraphrased, no quote available because this is an absence claim: grep over scripts/ finds no reader outside build-loop.sh's own assignments). It does not establish the future consumers.
**Replicate verdicts:** r1=Verified (compound) · r2=Unverifiable · r3=Verified (compound)
**Replicate annotations:** r1: the plan's interface matches. --status prints POLICY (`docs/working/plan-build-loop-handoff.md:205`), and the gate applies S rules "when the stricter policy is self-merge" (plan `:212`), but this "does not establish that those future modes read these globals (U1c/U2 code)". · r3: "does not establish the forward-looking purpose: no reader of POLICY or NEVER exists in this unit". The only mode at 2e711a7b prints the three `_LINE` variables (`:190-195`).

`--status` (U1c) and the gate (U2) are not built. Verifying this needs those units.

**Evidence:** `scripts/build-loop.sh:129-133`, `docs/working/plan-build-loop-handoff.md:74`, `docs/working/plan-build-loop-handoff.md:205`

---

## Claim 23: "Split on single spaces only; globform then refuses any other blank in an entry."

**Location:** `scripts/build-loop.sh:156`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers tab, leading tab, trailing tab, space+tab and double space (test 7). It does not separately test other blanks such as VT, FF or NBSP; NAMECHARS excludes them (static).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r3: NBSP was run (E7) and is refused by the prefix check when it follows the colon. · r2: mutant `no-ifs-split` (IFS removed) fails test 7.

`scripts/build-loop.sh:157` requires `^[^\ ]+(\ [^\ ]+)*$`, and `:163` splits with `IFS=' ' read -ra parts`. A tab is not in IFS, so it stays in the entry, and globform's NAMECHARS class refuses it. E1 test 7 passes, including its no-tab-echoed assertion.

**Evidence:** `scripts/build-loop.sh:155-169`, `test/scripts/build-loop-read.bats:119-127`; `$S1/logs/baseline.log`, `$S2/logs/mutants.log`

---

## Claim 24: "is followed by a non-blank line outside a fence (it may continue the list)"

**Location:** `scripts/build-loop.sh:159`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers when this WHY fires (NEXT 0) for a text line, across a fence, and for a one-line comment. It does not cover the policy and slots keys, which have no next-line rule (override row 264).
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

Quoted at `scripts/build-loop.sh:159`: `elif [[ "${next[never]}" != 1 ]]; then why="is followed by a non-blank line outside a fence (it may continue the list)"`. r1 E6 cases as in Claim 6. r1 E2 `nonext` fails test 7.

**Evidence:** `scripts/build-loop.sh:159`; `$S1/logs/settings-exp.log`, `$S1/logs/mutant-nonext.log`

---

## Claim 25: "not a bare $v: the shell would expand * and ? against files"

**Location:** `scripts/build-loop.sh:163`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers bash pathname expansion of an unquoted `$v` (no `set -f` in the script; cwd is the repo root after `:63`). It does not test an alternative implementation.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r3: "The globbing half rests on documented bash semantics for unquoted expansion and was not executed."

`scripts/build-loop.sh:163`: `IFS=' ' read -ra parts <<<"$v"`. Neither the script nor the lib runs `set -f` (paraphrased — no quote available because the claim covers absence of code: a grep for `set -f`/`noglob` finds no match, in r1 and r2), so an unquoted `$v` would be glob-expanded. r1 E6 "never with * and ? set" prints `*.sh ??/` unexpanded.

**Evidence:** `scripts/build-loop.sh:40`, `scripts/build-loop.sh:163`; `$S1/logs/settings-exp.log`

---

## Claim 26: "a throwaway repo under $BATS_TEST_TMPDIR with a main branch, the same hermetic git environment as test/scripts/dev-cycle.bats"

**Location:** `test/lib/build-loop-fixtures.bash:2-4`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the exported git variables and HOME. It does not cover LC_ALL: the fixture also pins `LC_ALL=C`, which dev-cycle.bats's setup does not.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r1+r2+r3: the fixture also pins `LC_ALL=C`, which dev-cycle.bats does not (r3: override row 240 records this). · r2: "does not establish hermetic-env.bash parity (override row C6, accepted)."

The fixture exports `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`, the author and committer pairs, and `HOME="$BATS_TEST_TMPDIR/home" LC_ALL=C` (`test/lib/build-loop-fixtures.bash:11-14`). `test/scripts/dev-cycle.bats:11-15` exports the same git variables and HOME.

**Evidence:** `test/lib/build-loop-fixtures.bash:7-19`, `test/scripts/dev-cycle.bats:11-15`

---

## Claim 27: "settings LINE...: docs/dev-cycle.md holding these lines (printf %s\n each), committed. With no lines the file holds one empty line."

**Location:** `test/lib/build-loop-fixtures.bash:24-25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers printf's behaviour with no arguments. It does not cover the commit.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** none

`test/lib/build-loop-fixtures.bash:26`: `settings() { mkdir -p docs && printf '%s\n' "$@" > docs/dev-cycle.md && commit_all settings; }`. r1 E7: `printf '%s\n' | od -c` prints one `\n` (r2 checked the same).

**Evidence:** `test/lib/build-loop-fixtures.bash:24-26`; `$S1/logs/help-blank-and-printf.log`

---

## Claim 28: "settings_is KEY WANT / settings_like KEY PREFIX: run --settings; its KEY line must equal WANT, or start with PREFIX. On a mismatch, print the whole output." / "line KEY: the --settings output line that starts with KEY."

**Location:** `test/lib/build-loop-fixtures.bash:28-29`, `test/lib/build-loop-fixtures.bash:34`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the helpers' match and their failure output (stdout and stderr). It does not cover `grep -m1 "^$1 "` with a regex-special KEY; all callers pass policy, slots or never.
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

r1 E2 `mutant-nocfg.log` shows the failure print: `# want: policy review set:...` followed by all three output lines.

**Evidence:** `test/lib/build-loop-fixtures.bash:28-36`; `$S1/logs/mutant-nocfg.log`

---

## Claim 29: "this repo is untouched" (each test builds a throwaway repo under $BATS_TEST_TMPDIR)

**Location:** `test/scripts/build-loop-read.bats:3-4`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the suite's cwd: every test runs in `$BATS_TEST_TMPDIR/repo`, and test 4 only reads `$REPO_ROOT/docs/dev-cycle.md` with `cp`. The suite ran from the archived copy in `$S3`, so the worktree was not exposed during this check.
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** none

`setup() { bl_setup; }` (`build-loop-read.bats:11`) runs `cd "$R"` with `R="$BATS_TEST_TMPDIR/repo"` (`build-loop-fixtures.bash:16-17`). Test 4 is `cp "$REPO_ROOT/docs/dev-cycle.md" docs/` (`:71`), which only reads. r3 E1 ran with `TMPDIR=$S3/tmp`, so bats placed every `$BATS_TEST_TMPDIR` under `$S3/tmp`. The failure output in `$S3/logs/mut-headread.log` shows a path under `$S3/tmp/bats-run-*/test/9/wt` (paraphrased — no quote available because this is an observation of where the runs wrote, not a snippet).

**Evidence:** `test/scripts/build-loop-read.bats:1-11`, `test/scripts/build-loop-read.bats:70-76`, `test/lib/build-loop-fixtures.bash:7-19`; `$S3/logs/baseline.log`

---

## Claim 30: Test names and their named properties fail under mutation (T1, T3, T4, T45, test 8, test 9)

**Location:** `test/scripts/build-loop-read.bats:13`, `test/scripts/build-loop-read.bats:43`, `test/scripts/build-loop-read.bats:78`, `test/scripts/build-loop-read.bats:106`, `test/scripts/build-loop-read.bats:151`, `test/scripts/build-loop-read.bats:169`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the eight mutants in r1 E2. Mutating each property the brief named (the GIT_CONFIG pair, the never_ok check, the two-never-lines arm, `HEAD:$f`, the `none` arm) makes at least one named test fail, and so does mutating two more (the next-line arm, absent vs refused). Mutating `GIT_NO_REPLACE_OBJECTS=1` alone is not caught (the pair covers it). Not every assertion was mutated.
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r1: "Mutating `GIT_NO_REPLACE_OBJECTS=1` alone is not caught (the pair covers it)."

The r1 E2 results are listed in r1's header: `nocfg` fails test 5; `nonoreplace` passes; `noneverok`, `dupnever_ok`, `nonone` and `nonext` fail test 7; `headread` fails tests 5, 7 and 9; `absentok` fails test 3.

**Evidence:** `test/scripts/build-loop-read.bats:13-186`; `$S1/logs/mutants-summary.log`, `$S1/logs/mutant-*.log`

---

## Claim 31: "--settings on this repo's own docs/dev-cycle.md: review, unset by the interim note (T3, G19)"

**Location:** `test/scripts/build-loop-read.bats:70`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers docs/dev-cycle.md at 2e711a7b. The test asserts only the policy line (also noted in override row 257).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r3: the test asserts only the policy line, not slots or never in the real file (override row 257). · r2: "`cp` failing inside an `&&` chain does not stop the test, but the assertion then fails, which I saw when the scratch tree lacked docs/."

`docs/dev-cycle.md:7`: `Build-loop policy: review (interim; Q-103)`, which fails the exact regex. E1 test 4 passes in all replicates.

**Evidence:** `docs/dev-cycle.md:7`, `test/scripts/build-loop-read.bats:70-76`; `$S1/logs/baseline.log`

---

## Claim 32: "A replace ref for main's blob, even with core.useReplaceRefs set, is not followed."

**Location:** `test/scripts/build-loop-read.bats:82`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the repo-config case the test plants. It does not cover caller `-c` or octal-count environments (Claim 16b).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: the test does not exercise the caller `git -c` / `GIT_CONFIG_PARAMETERS` channel (r1, r3 also the octal count) from Claim 16b. · r3: it "does not test C3's other forms". · r2: mutant `no-config-pair` "fails test 5 only".

E1 test 5 passes. The no-guard mutant fails it at `:84` in every replicate (r1 `nocfg`, r2 `no-config-pair`, r3 `noconfig`). r3: the replacement blob holds `Build-loop policy: self-merge` and `Self-merge never: none` (`:80`), so following the replace ref would give `policy self-merge set`.

**Evidence:** `test/scripts/build-loop-read.bats:78-91`; `$S1/logs/baseline.log`, `$S1/logs/mutant-nocfg.log`, `$S3/logs/mut-noconfig.log`

---

## Claim 33: "A never list hidden in markup turns self-merge off rather than being skipped."

**Location:** `test/scripts/build-loop-read.bats:117`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** The test's own case (`- [x] Self-merge never: b/` as the only never line) does turn self-merge off. As a general statement it misses the settled case of a hidden list next to an exact never line, which is skipped (Claim 4b; override row 256). It does not re-raise that behaviour.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r3 (Claim 3b location): the same wording as `scripts/build-loop.sh:16-17` appears here, and its qualifier applies. · r3 (scope of its Verified compound): "Covers what the test exercises: a sole hidden list ... For the hidden list next to an exact line, see Claim 3b." · r2 (compound over test 7's comments): every named mutant fails test 7. A mutant that drops only the `:160` `none` arm survives because it is equivalent: `none` passes globform, and `:172` still prints `never none` with `never_ok=1`. r3 reports the same equivalent mutant (`nonearm`).

`test/scripts/build-loop-read.bats:118`: `settings 'Build-loop policy: self-merge' '- [x] Self-merge never: b/'; settings_is policy "$no"` passes (E1). r1 E6 "hidden task-box never copy + exact none" gives `policy self-merge set`.

**Evidence:** `test/scripts/build-loop-read.bats:117-118`; `$S1/logs/baseline.log`, `$S1/logs/settings-exp.log`

---

## Claim 34: A18: the duplicate-never case asserts that self-merge goes off

**Location:** `test/scripts/build-loop-read.bats:128-129`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two-never-lines case. It does not cover a review policy with a malformed never line (override row 246, deferred).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: "only `:129` asserts policy on a `cnt>1` input, so `:129` carries A18."

`test/scripts/build-loop-read.bats:129`: `settings_is never 'never malformed: more than one line starts "Self-merge never:" (lines 2 and 3)'; settings_is policy "$no"`. The mutant that sets `never_ok=1` on the duplicate arm fails test 7 in every replicate (r1 `dupnever_ok`, r2 `copies-set-ok`, r3 `dupnever`, which fails at `:129`).

**Evidence:** `test/scripts/build-loop-read.bats:128-129`; `$S1/logs/mutants-summary.log`, `$S3/logs/mut-dupnever.log`

---

## Claim 35: "Copies in some markup, a table, a link label or with a misplaced colon count as second lines too."

**Location:** `test/scripts/build-loop-read.bats:130`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the eight shapes in the loop at `:131-134`, all of which pass. "Some markup" correctly no longer claims all markup (A22).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** none

The loop's shapes are `**…:** b/`, `**…**: b/`, `## …`, `_…_`, a backtick span, a table cell, `[Self-merge never](x): b/` and `Self-merge never : b/`. Each asserts `never malformed: more than one line starts …` (r3 E1).

**Evidence:** `test/scripts/build-loop-read.bats:130-134`; `$S3/logs/baseline.log`

---

## Claim 36: "A never line the next unfenced line may continue is malformed."

**Location:** `test/scripts/build-loop-read.bats:139`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the next-line rule. The test exercises only a directly adjacent line (`:140-141`); the fenced case is verified by r1 E6, not by the suite.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=—
**Replicate annotations:** r1: the suite exercises only a directly adjacent line; the fenced next-line case is verified outside the suite (r1 E6).

r1 E1 test 7 passes. r1 E6 covers the fenced next-line cases (Claim 6).

**Evidence:** `test/scripts/build-loop-read.bats:139-143`; `$S1/logs/baseline.log`, `$S1/logs/settings-exp.log`

---

## Claim 37: "Raised only on a loop's branch or in the working tree: ignored"

**Location:** `test/scripts/build-loop-read.bats:144`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the named property and that a mutant of it fails test 7 (r2's `head-not-main` fails tests 5, 7 and 9). It does not establish a kill for every assertion in the test.
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=— · single-replicate detection
**Replicate annotations:** none

r2's mutant results are in `$S2/logs/mutants.log`. Test 7 failed for every mutant except `no-config-pair` and `drop-none-arm160`, including `head-not-main`, which reads `HEAD:$f` in place of `$MAIN_SHA:$f`.

**Evidence:** `test/scripts/build-loop-read.bats:106-149`; `$S2/logs/mutants.log`

---

## Claim 38: "From a subdirectory and from a linked worktree, it reads the same main."

**Location:** `test/scripts/build-loop-read.bats:177-185`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the worktree's own commit (`git -C .../wt commit -qam wt`) and the `HEAD:$f` mutant being caught. The subdirectory case alone would not catch that mutant (its HEAD is main).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1+r3: the subdirectory arm alone would not detect a HEAD-reading mutant, since HEAD is main there. · r2: "does not establish a worktree whose branch is main itself, which git refuses."

`test/scripts/build-loop-read.bats:180`: `for d in . "$BATS_TEST_TMPDIR/wt"; do printf 'Build-loop policy: review\n' > "$d/docs/dev-cycle.md"; done; git -C "$BATS_TEST_TMPDIR/wt" commit -qam wt`. The `HEAD:$f` mutant fails test 9 on `[.../wt] policy review set` (r1 `headread`, r2 `head-not-main`, r3 `headread`).

**Evidence:** `test/scripts/build-loop-read.bats:177-185`; `$S1/logs/mutant-headread.log`, `$S3/logs/mut-headread.log`

---

## Claim 39: Commit 2e711a7b, Q-112/R4/A17 bullet: "so a never list hidden in markup turns self-merge off instead of being skipped"

**Location:** commit 2e711a7b message, Q-112 bullet (`scripts/build-loop.sh:179`)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** The same qualifier as Claim 4b: a hidden list is skipped when an exact never line also exists. The rest of the bullet is verified. History is not expected to be rewritten.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Mostly accurate (compound)
**Replicate annotations:** r1+r2: the Q-112/A17 mechanism (self-merge needs `never_ok`) holds (Claim 4a). · r3 (merge note): r3's compound (its Claim 29, Q-112 and A16 bullets) gives each bullet its own qualifier, so its Mostly accurate applies to this row.

r3: the evidence is in Claim 4b (paraphrased — no quote available because the evidence is the captured r3 E8 output already quoted there).

**Evidence:** `scripts/build-loop.sh:179-181`; `$S3/logs/hidden-exp.log`

---

## Claim 40: Commit 2e711a7b, A16 bullet: "A GIT_CONFIG_COUNT pair, appended after any the caller passed, sets it false; a test plants a replace ref with the config set."

**Location:** commit 2e711a7b message, A16 bullet (`scripts/build-loop.sh:69`)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** "a test plants a replace ref with the config set" is true (Claim 32). "appended after any the caller passed" is refuted for caller `GIT_CONFIG_PARAMETERS` pairs and for leading-zero counts, as in Claim 16b. The most severe part decides the verdict. Both inputs come only from the caller's environment.
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Mostly accurate (compound)
**Replicate annotations:** r3: "History is not expected to be rewritten." · r3: "the `core.useReplaceRefs` override is real on git 2.39.5". · r2: "does not establish anything about the rest of the commit message".

The evidence is the same as for Claim 16b: `policy self-merge set` under `GIT_CONFIG_PARAMETERS="'core.useReplaceRefs'='true'"` (r1 E3, r2 `caller-params-true`, r3 E4) and under `GIT_CONFIG_COUNT=010` (r1 E5, r3 E5).

**Evidence:** `scripts/build-loop.sh:69`; `$S1/logs/cfg-exp.log`, `$S1/logs/cfg-exp3.log`, `$S2/logs/replace.log`, `$S3/logs/replace-octal.log`

---

## Claim 41: Commit 2e711a7b: A18, A20-A22 bullets and "Merges feat/build-loop-u1a's iteration-4 fix first"

**Location:** commit 2e711a7b message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each bullet against the code at 2e711a7b. The "A21 ... next unfenced line" bullet holds for the header and the WHY, but the SETTINGS_AWK comment was not updated (Claim 19).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r1+r2+r3: A21 holds for the header (`:22`) and the WHY (`:159`) only. The awk comment at `:99-100` was missed (Claim 19).

A18: Claim 34. A20: header `scripts/build-loop.sh:11-12` (Claim 2). A21: `:22`, `:159`. A22: `test/scripts/build-loop-read.bats:130` says "some markup". Merge: 2e711a7b's parent is d06e61a6, `Merge branch 'feat/build-loop-u1a' into feat/build-loop-u1b`, whose second parent is 4aa2e98e `fix(dev-cycle): help prints the whole header; readers set pipefail themselves (U1a iteration 4 ...)` (r1; r3 confirms the parents `3b0adc25` and `4aa2e98e`).

**Evidence:** `scripts/build-loop.sh:11-23`, `scripts/build-loop.sh:159`, `test/scripts/build-loop-read.bats:129-130`; `git log -1 --format=%P 2e711a7b`; `$S1/logs/mutants-summary.log`

---

## Claim 42: Commit 2e711a7b, A19 bullet: "the worktree in the G20 test now commits its own change"

**Location:** commit 2e711a7b message, A19 bullet (`test/scripts/build-loop-read.bats:180`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the worktree's own commit and the `HEAD:$f` mutant being caught on it (Claim 38).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: the `head-not-main` mutant now fails test 9, "which it did not do before A19 per the rubric".

`test/scripts/build-loop-read.bats:180`: `git -C "$BATS_TEST_TMPDIR/wt" commit -qam wt`. r1 E2 `headread` fails test 9 on `[.../wt] policy review set`.

**Evidence:** `test/scripts/build-loop-read.bats:177-185`; `$S1/logs/mutant-headread.log`

---

## Claim 43: Commit 2e711a7b: "--help prints the header up to its first non-comment line (no fixed range), as dev-cycle.sh now does."

**Location:** commit 2e711a7b message, --help bullet (`scripts/build-loop.sh:57`)
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** "No fixed range" and "as dev-cycle.sh now does" are verified (`scripts/dev-cycle.sh:112` has the same sed). "First non-comment line" carries the empty-line imprecision from Claim 15, which is the only thing that keeps this from Verified.
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r1 (merge note): r1's compound (its Claim 38, --help bullet plus "~417") ties its Mostly accurate to this bullet. · r2+r3: the help line is identical in `scripts/dev-cycle.sh:112`.

`scripts/dev-cycle.sh:112`: `-h|--help) sed -n '2,/^[^#]/{/^#/p}' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;`. See Claim 15 for the stopping rule.

**Evidence:** `scripts/build-loop.sh:57`, `scripts/dev-cycle.sh:112`; `$S1/logs/help-blank-and-printf.log`

---

## Claim 44: Commit 2e711a7b Notes: "~417 changed code lines against U1a"

**Location:** commit 2e711a7b message, Notes
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers scripts/ and test/ in the three-dot diff. It does not establish anything about the docs/ lines, which are not counted.
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1 (merge note): r1's compound Mostly accurate comes from the --help part (Claim 43). r1 states that "~417" is verified (195 + 36 + 186), so its compound verdict does not decide this sub-claim. · r1+r3: checked against the hallucination-pattern log's commit-message-count pattern, and it does not match.

`git diff --numstat feat/build-loop-u1a...2e711a7b -- scripts test` prints 195 (build-loop.sh), 36 (fixtures) and 186 (bats), all additions: 417 (r2; r1 and r3 got the same with `--stat`).

**Evidence:** `scripts/build-loop.sh:1-195`, `test/lib/build-loop-fixtures.bash:1-36`, `test/scripts/build-loop-read.bats:1-186`

---

## Claim 45: Commit 2e711a7b: "Override-log rows: R4 (per Q-112), A23 and iteration 3's C1, C2, C4-C6, C8, C9."

**Location:** commit 2e711a7b message; `docs/reviews/override-log.md:256-264`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the mapping to rows 256 (R4), 257 (A23), 258 (C1), 259 (C2), 260 (C4), 261 (C5), 262 (C6), 263 (C8), 264 (C9). It does not cover the rows' reasons (Claims 47-54).
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified (compound)
**Replicate annotations:** r3: row 263 (U1c's reader) has no checkable content and was not verdicted.

Each row cites its item, e.g. `docs/reviews/override-log.md:258` "(performance; iteration 3 C1)" and `:264` "(iteration 3 C9)".

**Evidence:** `docs/reviews/override-log.md:256-264`

---

## Claim 46: Override-log row 239: "--help prints a fixed line range (architecture M3; C5) … Won't-Fix … Same as dev-cycle.sh; each edit re-derives the range, and help is checked by hand."

**Location:** `docs/reviews/override-log.md:239`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the row's premise at 2e711a7b. The row's own outcome (Won't-Fix) is left as recorded. This row is settled, and it is raised only because its premise changed at 2e711a7b.
**Replicate verdicts:** r1=— · r2=— · r3=Stale · single-replicate detection
**Replicate annotations:** r3: "This row is settled, and it is raised only because its premise changed at 2e711a7b."

The premise changed in this iteration. `-h` no longer prints a fixed line range: it uses `sed -n '2,/^[^#]/{/^#/p}' "$0"` (`scripts/build-loop.sh:57`), and dev-cycle.sh does the same (`scripts/dev-cycle.sh:112`). Commit 2e711a7b says: "--help prints the header up to its first non-comment line (no fixed range), as dev-cycle.sh now does". So C5 is resolved in code, and the row's "each edit re-derives the range" no longer describes the code (r3 E6). An accurate row would say it was resolved by 2e711a7b.

**Evidence:** `docs/reviews/override-log.md:239`, `scripts/build-loop.sh:57`, `scripts/dev-cycle.sh:112`; `$S3/logs/help.out`

---

## Claim 47: Row 256: "self-merge now needs a valid exact never line, so a hidden never list turns self-merge off. A hidden copy next to an exact line is ignored, and the exact line governs."

**Location:** `docs/reviews/override-log.md:256`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both halves on task-box and link shapes. It does not judge the acceptance decision (Q-112, the user's).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r3: "does not establish that every residual hidden shape behaves the same way; entities, homoglyphs and inline tags were not re-run here." · r2: "does not judge whether accepting the hidden-copy-next-to-exact shape is wise; that is settled." · r1+r3: no hidden shape raised the policy.

r1 E6: "hidden link never copy only" turns self-merge off. "Hidden task-box never copy + exact none" has the exact line governing (`never none: line 2`). "Hidden task-box policy copy + exact review" is detected as a copy. "Hidden task-box policy copy only" gives review. r2 (`hidden-never-next-exact`) and r3 E8 agree.

**Evidence:** `scripts/build-loop.sh:108-112`, `scripts/build-loop.sh:175-182`; `$S1/logs/settings-exp.log`, `$S3/logs/hidden-exp.log`

---

## Claim 48: Row 257: "1d79ffef's message says \"any link\", and \"T3's real-file test would catch one\" holds for the policy key only"

**Location:** `docs/reviews/override-log.md:257`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** The second half is verified (test 4 asserts only the policy line). The quoted phrase "any link" is not in 1d79ffef's message, which says "a link ... so any of them is a second line". The row's reading of that sentence is fair, but the quotation marks present a paraphrase as a quote.
**Replicate verdicts:** r1=Mostly accurate · r2=— · r3=Mostly accurate
**Replicate annotations:** r3: "It does not judge the row's outcome." A more accurate row would say: "says 'any of them' (including a link)".

1d79ffef message: "copies with markup closing before the colon, a table cell, a link or \"Self-merge never :\" were hidden. A line now counts as a copy when its letters alone, case folded, start with the key's, so any of them is a second line". Notes: "(docs/dev-cycle.md has none; T3's real-file test would catch one)". `test/scripts/build-loop-read.bats:74` checks `line policy` only.

**Evidence:** `git log -1 --format=%B 1d79ffef`; `test/scripts/build-loop-read.bats:70-76`

---

## Claim 49: Row 258: "globform is quadratic per entry, ~11 s on an 80 KB entry ... The entry is the user's own settings line; a scrub-cut line is at most 4 KB."

**Location:** `docs/reviews/override-log.md:258`
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the reading that the 4 KB cut applies to PRINTED lines only. `scrub` (`dev-cycle-read.sh:48-66`) runs on output, while SETTINGS_AWK and globform read the full committed line, so the cut does not bound globform's input. It does not establish the ~11 s timing figure, which r2 did not re-measure.
**Replicate verdicts:** r1=Verified · r2=Unverifiable · r3=Verified
**Replicate annotations:** r1: measured one 79,999-byte `a/a/...` entry at 10.267 s on this host (rc 0). It "does not measure other shapes or hosts". · r3 (Verified, Medium): measured 22.165 s for 80,000 bytes and 6.539 s for 40,000 bytes (×3.4 for ×2 size), superlinear. "Absolute times depend on the host ... not ~11 s", and the measurement is of the whole `--settings` run, not globform alone. · r2: the 4 KB cut bounds only printed output, so it does not bound the work globform does on the entry. · Merge note: r1 and r3 verdicted only the timing sentence; r2 verdicted the row including the 4 KB sentence. No replicate split the row, so most-severe-wins applies to it as one claim.

`dev-cycle-read.sh:52`: `$_ = substr($_, 0, 4096) . " [line cut at 4096 bytes]" if length($_) > 4096;` is in the output filter. `build-loop.sh:166` calls globform on each entry of the uncut `$v`. As a statement about printed output, the 4 KB part is true. Read as a bound on globform's work, it does not hold. The timing needs a measurement run, and r1 and r3 supplied one (above).

**Evidence:** `scripts/lib/dev-cycle-read.sh:48-66`, `scripts/build-loop.sh:121-128`, `scripts/build-loop.sh:163-169`; `$S1/logs/perf.log`, `$S3/logs/rows-exp.log`

---

## Claim 50: Row 259: "dev-cycle.sh's lib readers have no replace-ref guard"

**Location:** `docs/reviews/override-log.md:259`
**Type:** Reference / Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers scripts/dev-cycle.sh and scripts/lib/dev-cycle-read.sh at 2e711a7b. It does not establish U3b's planned refusal.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** none

`rg -n REPLACE scripts/dev-cycle.sh` returns nothing. The only `GIT_NO_REPLACE_OBJECTS` in scripts/ is at `scripts/build-loop.sh:70` (paraphrased — no quote available because the claim covers absence of code; there were no matching grep results). r1 and r2 grepped for `useReplaceRefs` and `NO_REPLACE` with the same result.

**Evidence:** `scripts/build-loop.sh:66-70`, `scripts/dev-cycle.sh`

---

## Claim 51: Row 260: "The lib's own tests cover main_entry's error and a failed blob read (dev-cycle.bats)"

**Location:** `docs/reviews/override-log.md:260`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the presence of the two assertions in dev-cycle.bats. It does not establish that build-loop.sh's own arms (`scripts/build-loop.sh:86`, `:89-90`) are exercised.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: "main_entry's error" is covered through a tree listing a name twice. It "does not establish coverage of ls-tree failing outright." · r3: build-loop.sh's own `main_file` error and failed-read arms are not tested, "which is the deferral".

`test/scripts/dev-cycle.bats:1273`: `[ "$output" = "skip Q-1: the default branch's tree could not be read, so docs/working/questions.md is not read" ]`. `:1257`: `[ "$output" = "skip Q-1: docs/working/questions.md could not be read from the default branch" ]`.

**Evidence:** `test/scripts/dev-cycle.bats:1257`, `test/scripts/dev-cycle.bats:1273`

---

## Claim 52: Row 261: "With Q-112's rule, self-merge implies a valid never line, so an empty NEVER under self-merge means \"none\"."

**Location:** `docs/reviews/override-log.md:261`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Row 261 holds because `POLICY=self-merge` needs `never_ok`, and the only `never_ok` path with an empty NEVER is the `none` arm (`:172`). It does not judge the acceptance.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r3: in the set arm NEVER is non-empty because `v` matched `^[^\ ]+(\ [^\ ]+)*$`. It "does not establish how consumers read NEVER."

`scripts/build-loop.sh:172`: `elif [[ "$v" == none ]]; then never_ok=1; NEVER_LINE="never none: ..."` (NEVER stays `()` from `:137`). Winner r1 (tie on Verified among all three; r1 is the lowest replicate number among the equally specific Scopes).

**Evidence:** `scripts/build-loop.sh:137`, `scripts/build-loop.sh:171-181`; `$S1/logs/settings-exp.log`

---

## Claim 53: Row 262: "The plan's \":74\" still says pathform globs; never uses globform"

**Location:** `docs/reviews/override-log.md:262`
**Type:** Reference / Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the plan's line 74 at 2e711a7b. It does not cover U2's eventual choice of rule.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** none

`docs/working/plan-build-loop-handoff.md:74`: "`docs/dev-cycle.md` may add `Self-merge never: GLOB …` (pathform globs, one line, read from main's commit)".

**Evidence:** `docs/working/plan-build-loop-handoff.md:74`

---

## Claim 54: Row 264: "\"Build-loop policy: self-merge\" followed by \"except on Fridays\" still reads as set"

**Location:** `docs/reviews/override-log.md:264`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Row 264 holds as stated, run against an exact `Self-merge never: none` line. It does not judge the acceptance.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** none

r1 E6 "row 264: policy then except on Fridays": `policy self-merge set: line 1`. r2 (`fridays`) and r3 E9 agree.

**Evidence:** `scripts/build-loop.sh:175-182`; `$S1/logs/settings-exp.log`, `$S2/logs/cases2.log`, `$S3/logs/rows-exp.log`

---

## Goal-Alignment Note

**Success criterion (verbatim, all three replicates):** A report saved at the output path named in your tail, structured per your skill, covering the full unit diff at 2e711a7b.

**Answered:** Yes, by all three replicates. Each saved `docs/reviews/code-fact-check-report-build-loop-u1b-r{1,2,3}.md` with `Commit: 2e711a7b` first. Together they cover the checkable comments in scripts/build-loop.sh, the fixture and the bats suite (test names and comments, with mutation checks for every brief-listed mutant), commit 2e711a7b's message, and override rows 256-264, plus row 239 (r3). r1 and r3 confirm that no input gives `policy self-merge set` without an exact valid never line, and that no hidden shape raises the policy (the Q-112 premise holds). The one surviving mutant (dropping only the `:160` `none` arm, reported by r2 and r3) is equivalent and does not mark a test gap.

**Out of scope (union):** scripts/lib/dev-cycle-read.sh's own claims (U1a), except where a claim depends on it (r1, r2, r3); U1c's constraints and `--status` (r1, r3); the earlier docs/reviews artifacts (r1, r3); whether the settled residuals (Q-112, Q-113, rows 222-255) are the right calls (r1, r2); code-quality judgments (r3). No out-of-scope bullet names a critic.

**Escalate:** consolidated in `## Escalations` below.

**Questions / Decisions:** r2 asks (1) whether the caller's environment is inside the trust boundary (if yes, a comment fix suffices; if not, neutralise `GIT_CONFIG_PARAMETERS` before the pair) and (2) notes the wrong-reason exit for a malformed `GIT_CONFIG_COUNT`. r1: side observation that with the config pair in place, `GIT_NO_REPLACE_OBJECTS=1` is redundant under the suite (mutant `nonoreplace` passes). r3: none.

---

## Escalations

- **E1** · `scripts/build-loop.sh:67-69` (Claims 16b, 40; commit 2e711a7b A16 bullet) · raised by **r1+r2+r3** · addressee: **orchestrator**. The replace-ref guard's "after any the caller passed" does not hold against a caller's `git -c` / `GIT_CONFIG_PARAMETERS` (all three) or a zero-padded `GIT_CONFIG_COUNT` (`010`, `08`; r1+r3). Each gave `policy self-merge set` from a replace blob when the repo config sets `core.useReplaceRefs`, so the policy was RAISED. The inputs come from the caller's environment, not from repo text or a loop's working tree. The problem is new at 2e711a7b (A16's fix) and no override row covers it. Routing options named by the replicates: a comment fix ("after any GIT_CONFIG_COUNT pair"), or a decimal check on the count plus unsetting or overriding `GIT_CONFIG_PARAMETERS`. r2 frames the decision as whether the caller's environment is inside the trust boundary; r3 rates it low severity.
- **E2** · `scripts/build-loop.sh:62` / `:69` (Claim 12) · raised by **r2+r3** (r1 records the same in Claim 12's Scope, not as an escalation) · addressee: **orchestrator**. A caller's malformed `GIT_CONFIG_COUNT` (`abc`, or a count with missing keys) exits 1 with "Not inside a git repository" inside a valid repo. It fails closed, but the message names the wrong cause.
- **E3** (informational) · `scripts/build-loop.sh:179-181` (Claims 4a, 47) · raised by **r1** (r3 states the same under Answered) · addressee: **orchestrator**. No input was found where hidden markup raises the policy or adds self-merge. The Q-112 premise holds at 2e711a7b.
- **E4** (informational, superseded) · no path (r3's report-level status) · raised by **r3** · addressee: **orchestrator**. r3's Escalate lists "No Incorrect verdicts. No claim reached blocking grade." After the merge, Claims 16b and 40 are Incorrect at High confidence (r1+r2), so this status no longer holds.

---

## Verdict stability

- **Total clusters (sub-claim rows):** 58
- **Clusters where all reporting replicates agreed:** 47 (including 7 single-replicate clusters: 13, 24, 28, 29, 30, 37, 46)
- **Clusters where verdicts disagreed:** 11
  - Claim 4b: r1=Mostly accurate · r2=Verified (compound) · r3=Mostly accurate
  - Claim 15: r1=Mostly accurate · r2=Verified · r3=Verified
  - Claim 16b: r1=Incorrect · r2=Incorrect · r3=Mostly accurate
  - Claim 20: r1=Verified · r2=— · r3=Mostly accurate (compound)
  - Claim 22b: r1=Verified (compound) · r2=Unverifiable · r3=Verified (compound)
  - Claim 33: r1=Mostly accurate · r2=Verified (compound) · r3=Verified (compound)
  - Claim 39: r1=Verified (compound) · r2=Verified (compound) · r3=Mostly accurate (compound)
  - Claim 40: r1=Incorrect · r2=Incorrect · r3=Mostly accurate (compound)
  - Claim 43: r1=Mostly accurate (compound) · r2=Verified (compound) · r3=Verified (compound)
  - Claim 44: r1=Mostly accurate (compound) · r2=Verified · r3=Verified (compound)
  - Claim 49: r1=Verified · r2=Unverifiable · r3=Verified
- **Agreement rate:** 47/58 = 81.0% (computed with python3). Excluding the single-replicate clusters: 40/51 = 78.4%.
- Five of the 11 disagreements (20, 39, 43, 44, and 22b in part) involve a compound verdict set against a sub-claim, not two replicates verdicting the same atom differently. That leaves 6 atom-level disagreements, the two Incorrect rows among them. This sample is ≥20 claims and below the 90% falsifier, so k stays at 3.

## Submitted Claims

Appended from the Stage-2.5 pass (`code-fact-check-submitted-claims-build-loop-u1b.md`, k=1, Commit: 2e711a7b): 55 and 56 from security-reviewer, 57 and 58 from performance-reviewer. 55, 56 and 58 Verified (executed); 57 Mostly accurate (executed).

## Claim 55: "With `core.useReplaceRefs=true` in the target repo's `.git/config` and a replace ref on main's `docs/dev-cycle.md`, `--settings` reads main's original blob."

**Submitted by:** security-reviewer
**Legibility-target:** security-reviewer (A16 / C3 closure: the replace-ref guard against repo config)
**Location:** `scripts/build-loop.sh:69-70`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a replace ref on main's settings blob with `core.useReplaceRefs=true` set in the repo's own `.git/config`, and also a caller passing `core.useReplaceRefs=true` through `GIT_CONFIG_COUNT`; confirms by mutation that the GIT_CONFIG_COUNT line is what holds. Does not establish anything for a caller that sets `GIT_CONFIG_PARAMETERS` (the critic's own scoped-out case: it does bypass the guard, reproduced below), for a non-numeric `GIT_CONFIG_COUNT`, or for dev-cycle.sh's lib readers (override row: no guard there, deferred to U3b).

The guard appends a command-line config pair after any the caller passed, and sets the env switch:

```bash
# scripts/build-loop.sh:69-70
cfg="${GIT_CONFIG_COUNT:-0}"; export "GIT_CONFIG_KEY_$cfg=core.useReplaceRefs" "GIT_CONFIG_VALUE_$cfg=false" GIT_CONFIG_COUNT=$((cfg + 1))
export GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1
```

In probe55, main's blob reads `Build-loop policy: review` and a replace object reads `Build-loop policy: self-merge`. On git 2.39.5 the repo config does defeat the env variable alone: `GIT_NO_REPLACE_OBJECTS=1 git cat-file blob main:docs/dev-cycle.md` printed `Build-loop policy: self-merge` once `core.useReplaceRefs true` was set. The real script, with the same config, printed `policy review set: line 1 of docs/dev-cycle.md on the default branch` (the original blob). A mutant copy with line 69 deleted printed `policy self-merge set: line 1 ...`, so line 69 is what holds the guard. With the caller passing `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.useReplaceRefs GIT_CONFIG_VALUE_0=true`, the script still printed `policy review set`, because its pair is index 1 and read later. With `GIT_CONFIG_PARAMETERS="'core.usereplacerefs'='true'"` from the caller, the script printed `policy self-merge set` (git reads that variable after the counted pairs). This matches the critic's scoped-out note and is outside the claim.

**Evidence:** `scripts/build-loop.sh:69-72`, `scripts/build-loop.sh:89`, `test/scripts/build-loop-read.bats:82-84` (T4's replace-ref assertion), `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i4/submitted/probe55.sh`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i4/submitted/probe55-out.txt`

---

## Claim 56: "`policy self-merge set` is printed only when an exact policy line and an exact, single, valid never line (`never_ok`) are both present on main's commit; a never line hidden in markup with no exact line gives `policy review unset`."

**Submitted by:** security-reviewer
**Legibility-target:** security-reviewer (Q-112 [1] / A17 closure: self-merge cannot be raised without a valid never line)
**Location:** `scripts/build-loop.sh:151-182`
**Type:** Invariant / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every assignment to POLICY_LINE in read_settings (`:134-188`, read whole, including the slots branch after `:182` and main_file's failure arm at `:139-143`) and 17 executed file shapes; "single" means single as the letters-only copy count sees it. Does not establish that every hidden copy is detected (a copy in markup that adds letters, such as a task box next to an exact never line, is not counted and the exact line governs: the settled override row for iteration 3's R4), and does not cover how later modes (U1c's --status, U2's gate) consume POLICY.

The only line that prints `policy self-merge set` is the exact-regex branch, and it requires `never_ok` for self-merge:

```bash
# scripts/build-loop.sh:177-181
    elif [[ "${text[policy]}" =~ ^Build-loop\ policy:\ (self-merge|review)$ ]]; then
      v="${BASH_REMATCH[1]}"
      if [[ "$v" == self-merge && -z "$never_ok" ]]; then
        POLICY_LINE="policy review unset: line ${first[policy]} reads self-merge, but there is no valid Self-merge never: line (\"Self-merge never: none\" for an empty list), so self-merge is off"
      else POLICY="$v"; POLICY_LINE="policy $v set: line ${first[policy]} $where"; fi
```

That branch is reached only after the count branches `:175-176` (no line, or more than one), and `never_ok` starts empty (`local ... never_ok=""` at `:135`) and is set only where the never line had one copy, began `Self-merge never: `, used single spaces, was followed by a blank or the end, and every entry passed globform with no repeat (`why` empty):

```bash
# scripts/build-loop.sh:171-173 (excerpt ends :173; the never block opens at :152 and read_settings continues to :188 — read)
      if [[ -n "$why" ]]; then NEVER_LINE="never malformed: line ${first[never]} $why"
      elif [[ "$v" == none ]]; then never_ok=1; NEVER_LINE="never none: line ${first[never]} $where lists none"
      else never_ok=1; NEVER=("${parts[@]}"); NEVER_LINE="never $v set: line ${first[never]} $where"; fi
```

When main_file fails (absent, not a file, odd or unbalanced), `:141` sets `policy review unset` and never reaches `:177`. Executed in probe56: `policy self-merge set` appeared only for an exact policy line plus an exact never line (`none`, a glob list, CRLF endings, and case 13, an exact line beside a task-box copy). Every other shape printed `policy review unset`: no never line; a never line in a task box (`- [x] Self-merge never: b/`, which reads `never none: no line starts ...`), in bold or in an HTML comment (both `never malformed`); two exact never lines; a `../x` entry; a never line continued by `b/`; a never line only inside a fence; a policy line with a trailing space; two policy lines; an exact never line plus a bold copy; and an unread file. A review policy with a malformed never line prints `policy review set`, which is not self-merge and is consistent with the claim.

**Evidence:** `scripts/build-loop.sh:134-188`, `scripts/build-loop.sh:103-118` (SETTINGS_AWK copy count), `test/scripts/build-loop-read.bats:106-149` (T45), `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i4/submitted/probe56.sh`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i4/submitted/probe56-out.txt`

---

## Claim 57: "The `--settings` run makes a fixed 6 git process calls, independent of file size and never-list length (GIT_TRACE count)."

**Submitted by:** performance-reviewer
**Legibility-target:** performance-reviewer (fork budget of the settings read, for U2's gate)
**Location:** `scripts/build-loop.sh:62-72`, `scripts/build-loop.sh:78-95`; `scripts/lib/dev-cycle-read.sh:246` (main_by_name), `:258-274` (main_entry), `:389-411` (resolve_main)
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the GIT_TRACE count across file size (1.5 KB to 0.93 MB), a 500-entry never list, an absent file and three default-branch shapes; does not establish counts for a repo with no default branch found by name (exits after resolve_main) or for the later modes (--status, the gate) that will call the same lib.

The count does not depend on file size or never-list length: it was 6 for a small file, a 500-entry never list and a 928,947-byte file. The calls were `rev-parse --show-toplevel`, `symbolic-ref ... refs/remotes/origin/HEAD`, `show-ref --verify --hash refs/heads/main`, `rev-parse --verify --quiet '<sha>^{commit}'`, `ls-tree -t --full-tree <sha> -- docs docs/dev-cycle.md` and `cat-file blob <sha>:docs/dev-cycle.md`. "Fixed 6" holds only for a repo whose default branch is `main` and whose file exists, because resolve_main tries one candidate per `show-ref`:

```bash
# scripts/lib/dev-cycle-read.sh:395-401 (excerpt ends :401; resolve_main continues to :411 — read)
  for c in "${candidates[@]}"; do
    [[ "$c" == -* ]] && continue
    # show-ref --verify takes only the exact ref, so a tag named refs/heads/<c>
    # cannot stand in for a missing branch (rev-parse would accept it).
    sha="$(git show-ref --verify --hash "refs/heads/$c" 2>/dev/null || true)"
    [[ -z "$sha" ]] || sha="$(git rev-parse --verify --quiet "$sha^{commit}" 2>/dev/null || true)"
    if [[ -n "$sha" ]]; then MAIN="$c"; MAIN_SHA="$sha"; MAIN_BY_NAME=1; break; fi
```

Measured: 5 with no `docs/dev-cycle.md` (no cat-file), 7 with the default branch named `master`, and 8 with origin/HEAD naming a branch that has no local copy. The count is a small constant per repo shape (5-8), not 6 everywhere. The claim's scaling point is correct.

**Evidence:** `scripts/build-loop.sh:62`, `scripts/build-loop.sh:71-72`, `scripts/build-loop.sh:81`, `scripts/build-loop.sh:89`, `scripts/lib/dev-cycle-read.sh:263`, `scripts/lib/dev-cycle-read.sh:389-411`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i4/submitted/probe57.sh`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i4/submitted/probe57-out.txt`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i4/submitted/probe57b.sh`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i4/submitted/probe57b-out.txt`

---

## Claim 58: "The settings file is read in one awk pass and the run scales linearly with file size (2 KB ≈ 20 ms, 1.27 MB ≈ 39 ms, 5.11 MB ≈ 102 ms)."

**Submitted by:** performance-reviewer
**Legibility-target:** performance-reviewer (cost of the settings read as docs/dev-cycle.md grows)
**Location:** `scripts/build-loop.sh:89`, `scripts/build-loop.sh:103-118`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the number of awk processes per run (PATH shim) and wall time over line-heavy files from 1.5 KB to 17.8 MB plus one 5 MB single line, on this host; the submitted millisecond figures are machine-dependent and were checked for agreement in shape, not exactly. Does not establish the cost of the perl scrub on very long output lines (output is three lines, at most a 4 KB never line per the settled override row) or the quadratic globform cost on one huge never entry (settled override row, ~11 s at 80 KB).

The blob goes through one pipeline, FENCE_AWK and SETTINGS_AWK concatenated into one program:

```bash
# scripts/build-loop.sh:89-90 (excerpt ends :90; main_file continues to :95 — read)
  FILE_OUT="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk "$FENCE_AWK$2")" \
    || { FILE_WHY="$f could not be read from the default branch"; return 1; }
```

A PATH shim on `awk` (probe58b) logged exactly one awk process per `--settings` run, with a 2,877-byte program. SETTINGS_AWK's per-line work is one `tolower`, one `gsub` and three `index` calls (`:108-112`), and its END prints at most three lines, so the bash loop at `:145-149` reads at most three records. Median of 7 runs (probe58): 1,536 B 18 ms; 1,110,056 B 34 ms; 4,440,056 B 87 ms; 17,760,056 B 302 ms; a 5,000,057 B file of one long line 97 ms. The marginal cost is 14.4, 15.5 and 16.0 ms/MB across the three larger steps, which is linear, and it agrees with the submitted points (interpolated: about 38 ms at 1.27 MB and 97 ms at 5.11 MB).

**Evidence:** `scripts/build-loop.sh:78-95`, `scripts/build-loop.sh:103-118`, `scripts/build-loop.sh:139-149`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i4/submitted/probe58.sh`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i4/submitted/probe58-out.txt`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i4/submitted/probe58b.sh`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i4/submitted/probe58b-out.txt`

---
