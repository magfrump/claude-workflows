Commit: 7697c6e6

# Code Fact-Check Report

**Commit:** 7697c6e6
**Replication:** k=3 (replicate)
**Repository:** /workspace/.claude/wt-build-loop-u2a2 (branch feat/build-loop-u2a2)
**Scope:** NET diff `git diff main...HEAD` (main 20347279, HEAD 7697c6e6): scripts/lib/dev-cycle-read.sh, scripts/dev-cycle.sh, test/scripts/build-loop-check.bats, test/scripts/fixture-git-env.bats, test/scripts/dev-cycle.bats, docs/working/plan-build-loop-handoff.md, docs/working/questions.md, docs/reviews/override-log.md (rows 353-356); commit messages 39ed1d53, bff4ded2, 7697c6e6. Final confirming pass (Stage 1 replicate).
**Checked:** 2026-10-06
**Total claims checked:** 41
**Summary:** 34 verified, 3 mostly accurate, 1 stale, 2 incorrect, 1 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, 5 entries). Nothing below matches a logged pattern, and no Incorrect verdict is a fabricated symbol, so nothing is appended (the shared rules also forbid writing outside this report).

Execution provenance. The skill asks for captured output under `docs/reviews/execution-logs/`. The shared rules allow no repo writes except this report, so captured output is in the scratch dir `/tmp/u2a2f-fc3-p9d0/logs/`, which is cited by bare path. Every execution ran under `timeout`. No process is left running. The executions are listed under X1-X12 at the end.

---

## Claim 1: Override row 353 (d8003fbf's commit-message errors, Accepted-immutable)

**Location:** `docs/reviews/override-log.md:353`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the row's subject (d8003fbf's message) describes main_imports, which is no longer in the net diff, and that the row is Accepted-immutable as the shared rules say. It does not re-verify each quoted phrase of d8003fbf (out of scope per shared3).

The net diff holds no `main_imports` (paraphrased — no quote available because the claim covers absence of code: `git diff main...HEAD -- scripts | grep main_imports` matches only comments naming U2a3). The row's status `Accepted-immutable` matches the shared rule ("their errors are U2a3's or already Accepted-immutable rows").

**Evidence:** `docs/reviews/override-log.md:353`, `scripts/lib/dev-cycle-read.sh:509-510`

---

## Claim 2: Override row 354: "at 39ed1d53 they are `:18` and `:21`"

**Location:** `docs/reviews/override-log.md:354`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the line numbers of the two short header lines at 39ed1d53 and at HEAD. It does not judge the Won't-Fix.

`git show 39ed1d53:scripts/lib/dev-cycle-read.sh | sed -n '18p;21p'` prints `# Call the exiting checks in the caller's shell, not inside $(...) or` and `# process (a second call re-reads main); check_brief, check_branch and`. HEAD has the same text at `scripts/lib/dev-cycle-read.sh:18` and `:21`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:18`, `scripts/lib/dev-cycle-read.sh:21`

---

## Claim 3: Override row 355: "The walks' queue pop (`queue=("${queue[@]:1}")`) is O(q²) and each import edge forks `lower` before the seen check"

**Location:** `docs/reviews/override-log.md:355`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the tree walk at HEAD. It does not establish the "~3 ms per edge" or "2 ms per 100 pops" timings (not re-measured), and "walks'" (plural) refers partly to U2a3's main_imports, which is not in this diff.

```bash
# scripts/lib/dev-cycle-read.sh:500-507
  while [[ ${#queue[@]} -gt 0 ]]; do
    f="${queue[0]}"; queue=("${queue[@]:1}")
    ...
    while IFS= read -r p; do
      IMPORTED+="$(lower "$p")"$'\n'
      if [[ "$seen" != *$'\n'"$p"$'\n'* ]] && inrepo_here "$p"; then seen+="$p"$'\n'; queue+=("$p"); fi
    done < <(import_targets "$d" < "$f")
  done
```
Each pop copies the remaining queue, and `lower` forks before the seen test.

**Evidence:** `scripts/lib/dev-cycle-read.sh:491-508`

---

## Claim 4: Override row 356: "Claude Code 2.1.292's import regex `/(?:^|\s)@((?:[^\s\\]|\\ )+)/g` keeps trailing punctuation, so `@docs/style.md.` reads `docs/style.md.` ... import_targets now yields a punctuation-ended token's whole name as well as its stripped one"

**Location:** `docs/reviews/override-log.md:356`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the regex's presence in the installed 2.1.292 binary, its trailing-punctuation behaviour under node, and import_targets' whole-plus-stripped output. It does not establish how marked's lexer splits every Markdown construct before the regex runs.

`claude --version` prints `2.1.292 (Claude Code)`. The binary holds `function reo(e,n){let r=new Set;function s(h){let S=/(?:^|\s)@((?:[^\s\\]|\\ )+)/g` (X9). Under node the regex reads `"@docs/st.md."` as `["docs/st.md."]` (X8). import_targets prints both `docs/x.md.,;` and `docs/x.md` for `@docs/x.md.,;` (X1). The kept-name mutant fails test 1 (X5, `want: docs/st.md.: imported`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:470-479`; /tmp/u2a2f-fc3-p9d0/logs/cc-binary-grep.txt, /tmp/u2a2f-fc3-p9d0/logs/cc-reo.txt, /tmp/u2a2f-fc3-p9d0/logs/cc-regex.txt, /tmp/u2a2f-fc3-p9d0/logs/probe1.txt, /tmp/u2a2f-fc3-p9d0/logs/mut-kept.txt

---

## Claim 5: Plan F10: "Floor item 4 keeps the docs `check_fix` denies (`docs/decisions/`, `docs/human-author/`, other briefs' working docs, cycle files) and adds `docs/thoughts/`, which `check_fix` still fixes"

**Location:** `docs/working/plan-build-loop-handoff.md:125`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the check_fix half (what it denies and that docs/thoughts/ passes its doc rule). It does not establish the floor half, which is U2a4 and is not written yet.

```bash
# scripts/dev-cycle.sh:177-179
  if writable "$a" || writable "$lp"; then echo "skip $a: one of the cycle's own files (use --check-write)"
  elif [[ ! "$lp" =~ ^docs/.*\.md$|^readme\.md$ || "$lp" =~ ^docs/(working|human-author|reviews|decisions)/ \
    || "$lp" == docs/dev-cycle.md || "$lp" == docs/constraints.md || "$a" == */.* || "$low" =~ $INSTRUCTION_FILE ]]; then
```
`docs/thoughts/` is in no denial, so it reaches `check_path`.

**Evidence:** `scripts/dev-cycle.sh:170-183`

---

## Claim 6: Plan F11: "Floor item 1 walks main's commit with `main_imports` (U2a3, stacked on U2a2's shared token parser), not `check_fix`'s working-tree walk, whose known issues A2/A3 remain. U2a3's rows and known-issue entry state what it models and what it refuses."

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers that U2a3's branch defines main_imports on import_targets, that A2/A3 stay open in known-issues, and that U2a3 carries an A5 entry. It does not verify U2a3's content (context only).

`git show feat/build-loop-u2a3:scripts/lib/dev-cycle-read.sh` has `main_imports() {` at :542 and calls `import_targets` at :577 and :583. `docs/working/known-issues-dev-cycle.md:16-17` still list A2 and A3. U2a3's known-issues file has `| A5 | 🟡 Medium | The gate's walk (`main_imports`, U2a2) ...` (see E4).

**Evidence:** `docs/working/known-issues-dev-cycle.md:16-17`; `feat/build-loop-u2a3:scripts/lib/dev-cycle-read.sh:542`

---

## Claim 7: Plan :273: "U2 carries 26 override rows"

**Location:** `docs/working/plan-build-loop-handoff.md:273`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the count under the U2a1 fact-check's filter (`| Defer |` rows naming `U2`). It does not establish that the author used the same filter.

`git show 20347279:docs/reviews/override-log.md | grep -cE '\| Defer \|.*\bU2\b'` gives `26`, and HEAD gives `26` too (X10). The filter is the one the U2a1 report used (`code-fact-check-report-build-loop-u2a1.md:443`).

**Evidence:** `docs/reviews/code-fact-check-report-build-loop-u2a1.md:443`, `docs/reviews/override-log.md` (X10; the count was printed in session and the command can be re-run)

---

## Claim 8: Plan U2a2 bullet: "`import_targets` (UTF-8 spaces including U+FEFF end a token; a token ending in punctuation yields its whole and its stripped name; a `..x` name is followed; text holding a NUL is read), `isimported tree`, which `check_fix` calls, and U2a1's carried rows C12-C14"

**Location:** `docs/working/plan-build-loop-handoff.md:275`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers each listed rule as worded ("end a token"). It does not establish that a token after a Unicode space is read; it is not (Claim 18b).

The rules hold under X1 and the X5 mutants. `scripts/dev-cycle.sh:181` reads `elif isimported tree "$lp"; then`. C12-C14 are in 39ed1d53 (Claim 35).

**Evidence:** `scripts/lib/dev-cycle-read.sh:468-482`, `scripts/dev-cycle.sh:181`; /tmp/u2a2f-fc3-p9d0/logs/probe1.txt

---

## Claim 9: Plan U2a4 bullet: "with the shared check_fix/floor predicate (rows C1, C3, 308)"

**Location:** `docs/working/plan-build-loop-handoff.md:277`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers resolving the three row references. It does not judge U2a4's design.

"308" is an override-log line, while "C1" and "C3" are U2a1 iteration-1 rubric IDs. The plan gives no branch for them, so they mean nothing on their own. They resolve to `override-log.md:322` (`... (architecture F1 ...; iteration 1 C1) | ... Revisit trigger: U2a2's floor, which should put the shared subset in one lib predicate that check_fix also calls.`) and `:324` (`... extends row 308; iteration 1 C3) | ... Revisit trigger: U2a2's floor function ...`). Both triggers still say "U2a2's floor", and the floor is now U2a4. More precise: "(override rows 322, 324 and 308)".

**Evidence:** `docs/reviews/override-log.md:308`, `docs/reviews/override-log.md:322`, `docs/reviews/override-log.md:324`

---

## Claim 10a: Q-119 update: "U2a2 is the shared token parser and `isimported tree`, U2a3 the commit-reading walk, U2a4 the floor ... Under [3], U2a3 is the unit replaced."

**Location:** `docs/working/questions.md:392`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the unit structure against the plan bullets and the branches. It does not cover the line counts (10b).

It matches plan `:275-277` and the branches `feat/build-loop-u2a2` / `feat/build-loop-u2a3` (paraphrased — no quote available because the claim spans the plan bullets already quoted in Claims 6, 8 and 9).

**Evidence:** `docs/working/plan-build-loop-handoff.md:275-277`

---

## Claim 10b: Q-119 update: "U2a2 (the floor plus the walk, 400 code lines before U2a1's carried rows) ... (fixes and tests put it near 480 lines)"

**Location:** `docs/working/questions.md:392`
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers whether a committed artifact holds the two counts. It does not dispute them.

The floor-plus-walk design was split before any U2a2 commit. The first commit, d8003fbf, measured 326 (`code-fact-check-report-build-loop-u2a2.md:488`: "sums to `326`"). "Near 480" is a projection the rubric repeats ("would take the unit to ~480 code lines"), not a measurement. Verifying either needs the uncommitted trees they were measured on.

**Evidence:** `docs/reviews/code-fact-check-report-build-loop-u2a2.md:488`, `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a2.md:11`

---

## Claim 11: Q-119 "If the answer differs: ... [3] replaces U2a2's walk."

**Location:** `docs/working/questions.md:393`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the unchanged line beside this diff's update. It does not cover option [1]'s row, which also says "U2a2 rebuilds the floor's import walk".

The update one line above says `Under [3], U2a3 is the unit replaced.` (`docs/working/questions.md:392`). The walk is U2a3's now, so `[3] replaces U2a2's walk` is stale, and the entry contradicts itself. A reader answering `Q-119: [3]` from the "If the answer differs" line gets the wrong unit.

**Evidence:** `docs/working/questions.md:390-393`

---

## Claim 12: Check_fix change "only toward refusing more" (PR description, brief item 5) and "does any path now refused ... change an existing --check-fix test's expectation?"

**Location:** `scripts/dev-cycle.sh:181`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the refusal order, the removed eager call, the parser changes (`-a`, `..x`, whole names, UNI cut) on direct and transitive targets, and the existing test expectations. It does not establish behaviour when a command inside the walk fails (the walk now runs inside an `elif` condition, where errexit is off, while main called `imported_names` as a plain statement). That residue was read, not executed.

Order is unchanged: glob, pathform, `writable`, the doc rule, then `elif isimported tree "$lp"` where main had `elif [[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]]` (`scripts/dev-cycle.sh:181`), then `check_path`. `-a`, following `..x` and emitting whole names only add names. The UNI cut can remove one. A file named with a Unicode space, read as an intermediate on main, is cut to a different name at HEAD, so what it imports is no longer refused. X3: `AGENTS.md` = `See @docs/x<NBSP>y.md`, `docs/x<NBSP>y.md` = `then @z.md`. Main prints `skip docs/z.md: an instruction file imports it ...` and HEAD prints `ok docs/z.md`. HEAD matches Claude Code here (its `\s` ends the token at the NBSP, so Claude Code reads `docs/x`, not that file). A direct target never changes: pathform admits only `NAMECHARS='abc...XYZ0123456789._/-'` (`scripts/lib/dev-cycle-read.sh:142`). Existing expectations: the dev-cycle.bats diff touches only the inventory test and entry_why's test, and all 75 dev-cycle tests pass (X2). Precise version: "toward refusing more, except names reached through a file whose name holds a Unicode space, which now resolve as Claude Code resolves them".

**Evidence:** `scripts/dev-cycle.sh:170-183`, `scripts/lib/dev-cycle-read.sh:142`, `scripts/lib/dev-cycle-read.sh:509-520`; /tmp/u2a2f-fc3-p9d0/logs/checkfix-nbsp-intermediate.txt, /tmp/u2a2f-fc3-p9d0/logs/suites.txt

---

## Claim 13: Lib header: "inrepo, dirok, skipped, check_brief, isimported and the walk (imported_names) exit 1 (need_root) unless ROOT_REAL is set, is the current directory and is a repository's top level"

**Location:** `scripts/lib/dev-cycle-read.sh:14-16`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers that each named function calls need_root and need_root's three exits. It does not establish that the list is complete: import_targets reads ROOT_REAL with no need_root and is not listed, which is correct for a stdin parser.

`inrepo() { need_root; inrepo_here "$1"; }` (:121), `dirok() { need_root; ...` (:127), `skipped() { need_root; ...` (:128), `check_brief` `need_root` (:349), `isimported` `need_root` (:516), `imported_names` `need_root` (:493). need_root (:91-95) exits on an unset ROOT_REAL, on `"$ROOT_REAL" == "$(pwd -P)"` failing, and on `[[ -e .git ]]` failing.

**Evidence:** `scripts/lib/dev-cycle-read.sh:91-95`, `:121`, `:127-128`, `:349`, `:493`, `:516`

---

## Claim 14: Lib header Inputs: "imported_names reads the working tree at ROOT_REAL"

**Location:** `scripts/lib/dev-cycle-read.sh:29-31`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers imported_names and, through it, isimported tree. It does not cover import_targets, which reads stdin.

`done < <({ git ls-files -z; untracked_md; } | instruction_names)` lists the starts, and `done < <(import_targets "$d" < "$f")` reads each checkout file (`scripts/lib/dev-cycle-read.sh:499`, `:506`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:491-508`

---

## Claim 15: "inrepo for a caller that has run need_root itself (a walk, per path); it has no need_root of its own."

**Location:** `scripts/lib/dev-cycle-read.sh:122-124`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the body and every caller in scripts/ and test/. It does not establish U2a3's callers.

`inrepo_here() { [[ -z "$(blocker "$1" file)" && -f "$1" ]]; }` (:124). The callers are `inrepo` (:121, after need_root) and imported_names (:496, :505, after need_root at :493). A grep over scripts/ and test/ finds no others (X11).

**Evidence:** `scripts/lib/dev-cycle-read.sh:121-124`, `:493-505`

---

## Claim 16: entry_why: "$2 is the path asked about, or "" (or no $2) ... error and any other word end "for $2" unless it is """

**Location:** `scripts/lib/dev-cycle-read.sh:284-288`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers each case arm with $2 set, empty and absent. It does not cover callers' wording.

`local w="${1//$'\n'/ }" p="${2-}"` and `error) echo "the tree of the default branch could not be read${p:+ for $p}" ;;` (:290, :296). The dev-cycle.bats test now calls `entry_why error` with no $2 and expects `the tree of the default branch could not be read`. It passes (X2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:289-299`, `test/scripts/dev-cycle.bats:1339-1355`; /tmp/u2a2f-fc3-p9d0/logs/suites.txt

---

## Claim 17: imported_names' comment: "The walk starts at every instruction file in the checkout, tracked or not ... resolves each @path against the importing file's directory as Claude Code does ... reads each plain file it reaches once (import_targets has the token rules). One result is cached, for the root in IMPORTED_DONE"

**Location:** `scripts/lib/dev-cycle-read.sh:440-448`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers start listing, directory-relative resolution, the once-only read and the cache key. It does not establish parity with Claude Code's start set (known issue A2: `.claude/rules/`, symlinked starts).

`if [[ "$f" == */* ]]; then d="${f%/*}"; else d=""; fi` feeds `import_targets "$d"`, and the seen test gates `queue+=` (:502-505). `[[ "$IMPORTED_DONE" == "$ROOT_REAL" ]] && return` (:494). Claude Code resolves with `Ye(H,FT(n))` in the binary (X9). A mistaken fixture of mine confirmed the resolution: `@docs/z.md` inside `docs/x<NBSP>y.md` resolved to `docs/docs/z.md` on main. The seen mutant hangs test 1 until timeout (X5).

**Evidence:** `scripts/lib/dev-cycle-read.sh:491-508`; /tmp/u2a2f-fc3-p9d0/logs/mut-seen.txt, /tmp/u2a2f-fc3-p9d0/logs/cc-reo.txt

---

## Claim 18a: UNI_SPACES: "U+00A0, U+1680, U+2000-200A, U+2028/2029, U+202F, U+205F, U+3000 and U+FEFF"

**Location:** `scripts/lib/dev-cycle-read.sh:450-455`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the 19 byte sequences decoded, and their equality with JavaScript's `\s` minus ASCII. It does not cover tokens after such a space (18b).

Decoding the array with iconv gives `a0 1680 2000 ... 200a 2028 2029 202f 205f 3000 feff`, 19 entries. node's `/\s/` over all code points gives `9 a b c d 20` plus exactly that set (X7).

**Evidence:** `scripts/lib/dev-cycle-read.sh:453-455`; /tmp/u2a2f-fc3-p9d0/logs/unispaces.txt

---

## Claim 18b: "UTF-8 spaces that end an import token, as a blank does"

**Location:** `scripts/lib/dev-cycle-read.sh:450`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers what follows a Unicode space inside one grep match. It does not establish how often this occurs (the same text on main was also missed, so this is not a regression).

After a blank, a following `@` starts a new token, because grep's match ends at `[:space:]`. A Unicode space is not ASCII `[:space:]` under `LC_ALL=C`, so the grep match runs on through it, and import_targets then cuts at it and throws the remainder away:
```bash
# scripts/lib/dev-cycle-read.sh:470-472 (excerpt ends :472; enclosing import_targets() continues to :482 — read)
  while IFS= read -r t; do
    t="${t#*@}"
    for u in "${UNI_SPACES[@]}"; do t="${t%%"$u"*}"; done
```
So `@docs/a.md<NBSP>@docs/b.md` yields only `docs/a.md`, and the same holds for U+FEFF and for `<NBSP>and<NBSP>@docs/c.md` (X1). Claude Code's regex yields `["docs/a.md","docs/b.md"]` and `["docs/a.md","docs/c.md"]` (X8). End to end, X4: `AGENTS.md` = `See @docs/a.md<NBSP>@docs/b.md`, and HEAD prints `skip docs/a.md: an instruction file imports it ...` but `ok docs/b.md`, so --check-fix lets through a file Claude Code imports. The plan U2a2 bullet and test 1's name ("Unicode spaces end a token") are accurate as worded. "As a blank does" is not. See E1.

**Evidence:** `scripts/lib/dev-cycle-read.sh:450-482`; /tmp/u2a2f-fc3-p9d0/logs/probe1.txt, /tmp/u2a2f-fc3-p9d0/logs/cc-regex.txt, /tmp/u2a2f-fc3-p9d0/logs/checkfix-nbsp.txt

---

## Claim 18c: "Claude Code's token ends at JavaScript's \s, which includes U+FEFF"

**Location:** `scripts/lib/dev-cycle-read.sh:451-452`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the installed 2.1.292 regex and JS `\s`. It does not establish that the token also ends at an unescaped backslash, which is true (`[^\s\\]`) and is listed in the import_targets comment.

The binary holds `/(?:^|\s)@((?:[^\s\\]|\\ )+)/g` (X9). `/\s/.test("﻿")` is true (X7).

**Evidence:** /tmp/u2a2f-fc3-p9d0/logs/cc-binary-grep.txt, /tmp/u2a2f-fc3-p9d0/logs/unispaces.txt

---

## Claim 19: "Every import walk shares these rules, so a change here changes --check-fix too."

**Location:** `scripts/lib/dev-cycle-read.sh:459-460`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the call chain at HEAD and U2a3's walk. It does not cover walks added later.

`check_fix` → `isimported tree` (`scripts/dev-cycle.sh:181`) → `imported_names` (`:518`) → `import_targets "$d" < "$f"` (`:506`). U2a3's main_imports calls import_targets at its :577 and :583.

**Evidence:** `scripts/dev-cycle.sh:181`, `scripts/lib/dev-cycle-read.sh:506`, `:518`

---

## Claim 20: "A token may follow any byte but a letter or digit (so user@host is not one)"

**Location:** `scripts/lib/dev-cycle-read.sh:460-461`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the code's start rule. It does not claim Claude Code parity: Claude Code needs `^` or `\s` before `@`, so the code also reads `x(@p.md`, which Claude Code does not. That over-reads, so it can only over-refuse. The rule also fails for a byte after an earlier token in the same match (18b).

`IMPORT_RE='(^|[^[:alnum:]])@[^][:space:]\\#`()]+'` (:456). X1: `user@host.md a@b x(@p.md` yields only `p.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:456`; /tmp/u2a2f-fc3-p9d0/logs/probe1.txt

---

## Claim 21: "it ends at a blank, a UNI_SPACES space, \, #, a backtick, ( ) [ or ]"

**Location:** `scripts/lib/dev-cycle-read.sh:461-462`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers each listed end character. It does not establish a security effect: the code reads `[` as Claude Code does, so this mismatch is in the comment only (for `(`, `)` and `]`, see E2).

`[` does not end a token. In the bracket expression `[^][:space:]\\#`()]`, the leading `]` is a literal and `[:space:]` is a class, so no literal `[` is excluded. X1: `@docs/a[b.md` yields `docs/a[b.md`, while `@docs/a]b.md` yields `docs/a`. Every other listed character ends the token (`@a\b.md @c#d.md @e`f.md @g(h.md @i)j.md` yields `a c e g i`). "Blank" here means all of C-locale `[:space:]`, which includes CR, VT and FF. The text predates the diff (main's imported_names comment) and is restated on the new function. Precise version: "... a backtick, ( ) or ] (not [)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:456`, `:461-462`; /tmp/u2a2f-fc3-p9d0/logs/probe1.txt

---

## Claim 22: "grep -a reads text holding a NUL."

**Location:** `scripts/lib/dev-cycle-read.sh:462-463`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers tokens before and after a NUL. It does not cover a NUL inside a token: `read` drops the byte, so `@docs/a<NUL>b.md` yields `docs/ab.md`, a name no file has, which is harmless.

`done < <(env LC_ALL=C grep -aoE "$IMPORT_RE" || true)` (:481). X1: `@docs/a.md<NUL> then @docs/b.md` yields both. With `-a` removed, test 1 fails (X5 `noa`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:481`; /tmp/u2a2f-fc3-p9d0/logs/probe1.txt, /tmp/u2a2f-fc3-p9d0/logs/mut-noa.txt

---

## Claim 23: "a token ending in . , ; : ! ? * _ or ~ yields both its whole and its stripped name"

**Location:** `scripts/lib/dev-cycle-read.sh:463-465`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers several trailing marks, all-mark tokens, and tokens one of whose readings is dropped. It does not establish uniqueness of output lines (one path can print twice from two tokens, which is harmless to the substring test).

```bash
# scripts/lib/dev-cycle-read.sh:473-479
    v="$t"; while [[ "$v" == *[.,\;:!?*_~] ]]; do v="${v%?}"; done
    for t in "$t" "$v"; do
      [[ -n "$t" && "$t" != "~"* && "$t" != /* ]] || continue
      p="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${1:+$1/}$t" 2>/dev/null)" || continue
      [[ "$p" != .. && "$p" != ../* ]] || continue
      printf '%s\n' "$p"
      [[ "$v" != "$t" ]] || break
```
X1: `@docs/x.md.,;` → `docs/x.md.,;` and `docs/x.md`. `@...` → `...` (the empty stripped name is skipped). `@*_~` → `*_~`. `@..,` → `..,` (the stripped `..` is dropped). `@~/x.md.`, `@/etc/x.md.` and `@../x.md.` → nothing. When the whole reading is skipped by `continue`, the `break` is not reached, so the stripped reading is still tried. `**@docs/x.md**` → `docs/x.md**` and `docs/x.md`. The X5 kept mutant fails test 1. The output is the same under LC_ALL=C and C.UTF-8 (X6).

**Evidence:** `scripts/lib/dev-cycle-read.sh:468-482`; /tmp/u2a2f-fc3-p9d0/logs/probe1.txt, /tmp/u2a2f-fc3-p9d0/logs/mut-kept.txt

---

## Claim 24: "~/ and absolute paths, and paths leaving the repo (.. or ../, not a ..x name), are dropped."

**Location:** `scripts/lib/dev-cycle-read.sh:466-467`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the three drop rules and `..x` names, including leaving via a subdirectory. Any `~`-prefixed token is dropped, not just `~/`, so the code drops more than the comment names (Claude Code also skips `~x`). It does not cover absolute paths into the repo (known issue A3).

X1: `@.. @../ @..x.md` → only `..x.md`. `@../../x.md` from `docs` → nothing. `@../y.md` from `docs` → `y.md`. `@~x.md` → nothing. Test 1's `..x.md` and `docs/hid.md` assertions fail under main's `[[ "$p" != ..* ]]` (X5 `dotdot`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:475-477`; /tmp/u2a2f-fc3-p9d0/logs/probe1.txt, /tmp/u2a2f-fc3-p9d0/logs/mut-dotdot.txt

---

## Claim 25: instruction_names: "It matches INSTRUCTION_FILE's names; the walk's own test stays the authority. LC_ALL=C makes -i ASCII-only."

**Location:** `scripts/lib/dev-cycle-read.sh:483-487`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers ASCII names, top-level and nested. It does not establish equivalence for names holding a newline (the walk's own regex test re-filters).

`env LC_ALL=C grep -zaiE '(^|/)((claude|agents?|gemini)(\.[a-z0-9_-]+)?|skill)\.md$'` against `INSTRUCTION_FILE='^(claude|agents?|gemini)(\.[abcdefghijklmnopqrstuvwxyz0123456789_-]+)?\.md$|^skill\.md$'` on the lowered basename (:437, :487, :496). X12: `CLAUDE.local.md` and `sub/AGENTS.MD` pass, and `top.md` does not.

**Evidence:** `scripts/lib/dev-cycle-read.sh:437`, `:487`, `:496`; /tmp/u2a2f-fc3-p9d0/logs/untracked.txt

---

## Claim 26: untracked_md: "The checkout's untracked and ignored .md files, NUL-separated: --others without --exclude-standard already lists ignored files."

**Location:** `scripts/lib/dev-cycle-read.sh:488-490`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers ignored top-level and ignored-directory files and case. It does not cover an untracked file inside a nested repository.

X12: with `.gitignore` = `CLAUDE.local.md` / `sub/`, `untracked_md` lists `CLAUDE.local.md`, `sub/AGENTS.MD` and `top.md`, and does not list `x.txt`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:490`; /tmp/u2a2f-fc3-p9d0/logs/untracked.txt

---

## Claim 27: isimported: "tree (U2a3 adds main ...). A walk name it does not know answers imported (0), so a caller testing it with `if` refuses. Run it in the caller's shell: the walk exits through need_root and caches its result."

**Location:** `scripts/lib/dev-cycle-read.sh:509-513`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers both arms, the need_root exit and the cache. It does not cover a missing $2: `lower "$2"` under `set -u` aborts the shell even under `if`.

```bash
# scripts/lib/dev-cycle-read.sh:514-521
isimported() {
  local lp
  need_root
  lp="$(lower "$2")"
  case "$1" in
    tree) imported_names; [[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]] ;;
    *) return 0 ;;
  esac
}
```
Test 2 prints `bogus: imported`. Making the arm `return 1` fails it (X5 `unknown`). U2a3 adds `main) main_imports || return 0; ...` at its :615.

**Evidence:** `scripts/lib/dev-cycle-read.sh:514-521`, `test/scripts/build-loop-check.bats:41-45`; /tmp/u2a2f-fc3-p9d0/logs/mut-unknown.txt

---

## Claim 28: build-loop-check.bats header: "Each test builds a throwaway repo under $BATS_TEST_TMPDIR (test/lib/build-loop-fixtures.bash); this repo is untouched."

**Location:** `test/scripts/build-loop-check.bats:3-7`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers bl_setup. It does not cover U2a3/U2a4 tests yet to be added.

`R="$BATS_TEST_TMPDIR/repo"; mkdir -p "$R" && cd "$R"`, after `unset $(git rev-parse --local-env-vars)` (`test/lib/build-loop-fixtures.bash:15-22`).

**Evidence:** `test/lib/build-loop-fixtures.bash:7-23`

---

## Claim 29: imps/want comments: "walk: ok" or "walk: failed" (main_imports' return; tree always reads ok) ... "timeout: a walk that never ends ... fails the test" ... want: "holds exactly "PATH: WORD""

**Location:** `test/scripts/build-loop-check.bats:14-25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the tree arm and the timeout path. It does not cover the main arm, which needs U2a3.

`if [[ "$w" != main ]] || main_imports; then echo "walk: ok"` (:21). `grep -qxF "$1: $2"` (:25). The seen mutant prints `walk: ok`, hangs, and fails on `[ "$status" -eq 0 ]` (X5).

**Evidence:** `test/scripts/build-loop-check.bats:17-25`; /tmp/u2a2f-fc3-p9d0/logs/mut-seen.txt

---

## Claim 30: Test 1 name: "Unicode spaces end a token, punctuation is read kept and stripped, a ..x name is followed, a NUL hides no import, a cycle ends"

**Location:** `test/scripts/build-loop-check.bats:27-39`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each named rule with a mutant that fails the test. It does not assert a token after a Unicode space (18b), and it does not assert `docs/a.md`, the token just before the NUL.

Mutants in a copy (X5), each failing test 1: U+FEFF removed, U+00A0 removed, kept name removed, seen check removed (timeout), `-a` removed, main's `..*` rule. "A cycle ends": `docs/c.md` imports `@c.md` (itself) and `@../CLAUDE.md`. No assertion passes vacuously: each `want` line needs an exact line, and the negatives `docs/other.md -` and `docs/nb.md. -` need the walk to have run.

**Evidence:** `test/scripts/build-loop-check.bats:27-39`; /tmp/u2a2f-fc3-p9d0/logs/mut-feff.txt, /tmp/u2a2f-fc3-p9d0/logs/mut-nbsp.txt, /tmp/u2a2f-fc3-p9d0/logs/mut-kept.txt, /tmp/u2a2f-fc3-p9d0/logs/mut-seen.txt, /tmp/u2a2f-fc3-p9d0/logs/mut-noa.txt, /tmp/u2a2f-fc3-p9d0/logs/mut-dotdot.txt

---

## Claim 31: Test 2: "isimported answers imported under if for a walk name it does not know"

**Location:** `test/scripts/build-loop-check.bats:41-45`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the unknown-word arm under `if`. It does not cover a known walk failing (U2a3).

`[ "$output" = "bogus: imported" ]`. The `return 1` mutant fails it, and a failed `resolve_main` would also fail it (empty output), so it cannot pass vacuously.

**Evidence:** `test/scripts/build-loop-check.bats:41-45`; /tmp/u2a2f-fc3-p9d0/logs/mut-unknown.txt

---

## Claim 32: fixture-git-env.bats: "This suite's own fixture must stay out of an inherited GIT_DIR too." / "The inner runs name the victim's index too: it must come out byte for byte."

**Location:** `test/scripts/fixture-git-env.bats:11-19`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the setup unset and the index comparison. It does not cover the other suites in row 327.

`unset $(git rev-parse --local-env-vars)` (:13), `cp "$V/.git/index" ...` (:19), and `cmp -s ... "$V/.git/index"` (:27). Mutant: dev-cycle.bats' setup unsets only GIT_DIR. Test 1 then fails at the `cmp` line (:27), with the victim index holding `docs/working/questions.md` (X5 `idx`). The inner test stages (`git add -A && git commit -qm q`, `test/scripts/dev-cycle.bats:1209`), and `victim_unchanged` needs `1..1` and `ok 1`.

**Evidence:** `test/scripts/fixture-git-env.bats:9-28`, `test/scripts/dev-cycle.bats:1207-1212`; /tmp/u2a2f-fc3-p9d0/logs/mut-idx.txt

---

## Claim 33: Commit 39ed1d53: C12/C13 patches "applied ... as written"; C14; "C16 ... none is edited here"; "Tests: 105 across dev-cycle, build-loop-read, build-loop-check, fixture-git-env and hermeticity"

**Location:** commit 39ed1d53
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the patch identity, the counts at that commit and C16's trigger. It does not re-run the suites at 39ed1d53.

The Appendix patches (`test-strategy-review-2026-10-06-i3-build-loop-u2a1.md:110-142`, `:148-171`) applied to d8003fbf's two test files reproduce 39ed1d53's files byte for byte (X11). `@test` counts at 39ed1d53 are 7+75+2+19+2 = 105. Row 327's suites (merge-safety, cc-push, archive-working-docs, si-clean-state, cc-isolated-functions) are not in the branch diff.

**Evidence:** `docs/reviews/test-strategy-review-2026-10-06-i3-build-loop-u2a1.md:107-172`, `docs/reviews/override-log.md:327`

---

## Claim 34a: Commit bff4ded2: "Tests: build-loop-check.bats 2 ...; mutants of U+FEFF, the kept name and the tree walk's seen check each fail. 100 across the five suites. 166 changed code lines against main."

**Location:** commit bff4ded2
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the counts at bff4ded2 and HEAD, which have the same code. It does not cover timing.

The five suites give 100 ok, 0 not ok (X2). `git diff --numstat main...HEAD -- ':(top)' ':(top,exclude)docs/'` sums to 166, and to 166 at bff4ded2 too (X10). All three named mutants fail test 1 (X5).

**Evidence:** /tmp/u2a2f-fc3-p9d0/logs/suites.txt, /tmp/u2a2f-fc3-p9d0/logs/mut-feff.txt, /tmp/u2a2f-fc3-p9d0/logs/mut-kept.txt, /tmp/u2a2f-fc3-p9d0/logs/mut-seen.txt

---

## Claim 34b: Commit bff4ded2: "main_imports, isimported main, their tests, known issue A5 and plan F11 move to U2a3" and "B13's evidence recorded on the settled token-form row"

**Location:** commit bff4ded2
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers what the net diff holds. It does not cover U2a3's branch content.

At bff4ded2, F11 equals main's text (`Floor item 1 reuses check_fix's import walk ...`). But 7697c6e6 then rewrites F11 on this branch, so the net diff does carry an F11 change. B13's evidence is a new row (`override-log.md:356`, "Executed evidence on the `feat/build-loop-u2a` row ..."), not an edit of the settled row, as an append-only log requires. Precise: "F11's rewrite waits for a later commit; B13's evidence is a new row citing the settled one."

**Evidence:** `docs/working/plan-build-loop-handoff.md:126`, `docs/reviews/override-log.md:356`

---

## Claim 34c: Commit bff4ded2 Notes: "emitting a punctuation-ended token's whole name makes --check-fix refuse slightly more (never less)"

**Location:** commit bff4ded2
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the whole-name change only. The UNI cut's one refuse-less case is in Claim 12.

The whole name is printed in addition to the stripped one (`for t in "$t" "$v"`, :474), so IMPORTED only gains lines.

**Evidence:** `scripts/lib/dev-cycle-read.sh:473-479`

---

## Claim 35: Commit 7697c6e6: "F11 names U2a3's main_imports as the floor's walk"

**Location:** commit 7697c6e6
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the plan diff of that commit.

F11 now reads `Floor item 1 walks main's commit with main_imports (U2a3, ...)` (plan :126).

**Evidence:** `docs/working/plan-build-loop-handoff.md:126`

---

## Claim 36: Override rows dated 2026-10-06 for feat/build-loop-u2a2 and rubric B-row statuses B1, B5 (tree half), B7, B9, B10 (inrepo_here), B13

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a2.md:19-30`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the U2a2-unit rows against code and mutants. It does not cover U2a3-routed rows.

B1: `$'\xef\xbb\xbf'` is in UNI_SPACES, and its mutant fails. B5: the cycle fixture plus `timeout 60`. B7: row 355. B9: the rules and contract are on import_targets (:458-467). B10: inrepo_here's comment (:122-123). B13: whole names (Claim 23). There are four feat/build-loop-u2a2 rows (353-356), not three (see E3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:122-123`, `:455`, `:458-467`; `docs/reviews/override-log.md:353-356`

---

## Claims Requiring Attention

### Incorrect
- **Claim 18b** (`scripts/lib/dev-cycle-read.sh:450`): "as a blank does" is false. A token after a Unicode space in the same grep match is dropped (`@a.md<NBSP>@b.md` reads only a.md), so `--check-fix` prints `ok` for a file Claude Code imports (executed). Pre-existing on main, and not in any settled row. See E1.
- **Claim 21** (`scripts/lib/dev-cycle-read.sh:461-462`): `[` does not end a token (`@docs/a[b.md` → `docs/a[b.md`). The comment lists it. The code matches Claude Code here, so this is a comment-only error.

### Stale
- **Claim 11** (`docs/working/questions.md:393`): "[3] replaces U2a2's walk". The update one line above says U2a3.

### Mostly Accurate
- **Claim 9** (`docs/working/plan-build-loop-handoff.md:277`): "rows C1, C3, 308" mixes U2a1 rubric IDs with a log line. They mean override rows 322, 324 and 308, whose triggers still say "U2a2's floor".
- **Claim 12** (`scripts/dev-cycle.sh:181`): "only toward refusing more" holds except for names reached through a file whose name holds a Unicode space (now resolved as Claude Code resolves them). The walk also now runs where errexit is off (read, not executed).
- **Claim 34b** (commit bff4ded2): F11 was later rewritten on this branch by 7697c6e6. B13's evidence is a new row.

### Unverifiable
- **Claim 10b** (`docs/working/questions.md:392`): the "400" and "near 480" line counts have no committed measurement. 326 is the measured first-commit figure.

## Escalations

- **E1 (Medium, fail-open, new): a token after a Unicode space is never read.** `scripts/lib/dev-cycle-read.sh:470-472`. Evidence: `for u in "${UNI_SPACES[@]}"; do t="${t%%"$u"*}"; done` cuts the grep match at the first Unicode space and drops the rest, and any `@` token in the rest goes with it. Executed: HEAD `--check-fix docs/b.md` → `ok docs/b.md` with `AGENTS.md` = `See @docs/a.md<NBSP>@docs/b.md`. Claude Code 2.1.292's regex reads both (X4, X8). Main misses it too (main never cut at all), so this is not a regression of check_fix. But the shared parser carries it into U2a3's main_imports and so into the self-merge floor. It is not among the settled `feat/build-loop-u2a` A5 row's gaps (symlinked directory, case-insensitive names, absolute imports, backslash/trailing-`_`), nor in known issues A2/A3, nor in B14. Confidence: High. Route: a fix here, or a U2a3 row before the floor relies on it.
- **E2 (Low/Informational, fail-open, new): `(`, `)` or `]` inside a real file name ends the token early.** Executed (X4b): `AGENTS.md` = `See @docs/a(b).md and @docs/c[d].md`, where those files import `@z.md` and `@y.md`. HEAD and main both print `ok docs/z.md` and `ok docs/y.md`. Claude Code's regex reads `docs/a(b).md` and `docs/c[d].md` (marked may still turn `[d]` into link text when a reference definition exists). Direct targets cannot carry these characters (pathform), so only intermediate files matter. B14 (carried to U2a3) names `[`/`]` but not `(`/`)`. Confidence: High for the walk, Medium for Claude Code (I checked the regex, not marked's lexer).
- **E3 (brief accuracy):** the brief says "the three override rows dated 2026-10-06 for feat/build-loop-u2a2". The log has four (353-356), and all four are checked above.
- **E4 (U2a3 context only):** U2a3's `docs/working/known-issues-dev-cycle.md:18` says `The gate's walk (main_imports, U2a2)`. Since the split, it is U2a3. For U2a3's review.

## Executions (X1-X12)

All ran on 2026-10-06 between 21:06Z and 21:15Z, with cwd as noted, under `timeout`.

- X1 `timeout 30 env LC_ALL=C bash /tmp/u2a2f-fc3-p9d0/probe.sh <HEAD lib>`, cwd /tmp/u2a2f-fc3-p9d0/r, exit 0 → /tmp/u2a2f-fc3-p9d0/logs/probe1.txt
- X2 `TMPDIR=$(mktemp -d /tmp/u2a2f-x-XXXX) timeout 600 bats test/scripts/build-loop-check.bats test/scripts/dev-cycle.bats test/scripts/fixture-git-env.bats test/scripts/build-loop-read.bats test/fixture-hermeticity.bats`, cwd the worktree, 21:06:47Z, exit 0, 100 ok → /tmp/u2a2f-fc3-p9d0/logs/suites.txt
- X3 `timeout 60 bash <main|head>/scripts/dev-cycle.sh --check-fix docs/z.md`, cwd /tmp/u2a2f-fc3-p9d0/fx2, 21:10:20Z, exit 0 both → /tmp/u2a2f-fc3-p9d0/logs/checkfix-nbsp-intermediate.txt
- X4 the same with `--check-fix docs/a.md docs/b.md ...`, cwd /tmp/u2a2f-fc3-p9d0/fx, 21:09:42Z, exit 0 → /tmp/u2a2f-fc3-p9d0/logs/checkfix-nbsp.txt. X4b, cwd /tmp/u2a2f-fc3-p9d0/fx3, 21:14:35Z, exit 0 → /tmp/u2a2f-fc3-p9d0/logs/checkfix-paren.txt
- X5 `/tmp/u2a2f-fc3-p9d0/mut.sh <name> <perl edit> <file> <suite>` (copy of `git archive 7697c6e6 scripts test`, `timeout 300 bats`), 21:11:41Z-21:13:01Z, exit 1 each (killed) → /tmp/u2a2f-fc3-p9d0/logs/mut-{feff,nbsp,kept,seen,noa,dotdot,unknown,idx}.txt
- X6 `timeout 30 env LC_ALL={C,C.UTF-8} bash probe2.sh`, cwd /tmp/u2a2f-fc3-p9d0/r, exit 0, identical output (printed in session)
- X7 a bash decode of UNI_SPACES with iconv, and `node -e` over `/\s/`, cwd the worktree, exit 0 → /tmp/u2a2f-fc3-p9d0/logs/unispaces.txt
- X8 `timeout 10 node -e` with the Claude Code regex, exit 0 → /tmp/u2a2f-fc3-p9d0/logs/cc-regex.txt
- X9 `timeout 60 grep -ao` over `/usr/local/share/npm-global/lib/node_modules/@anthropic-ai/claude-code/bin/claude.exe` (2.1.292, as of 21:14Z), exit 0 → /tmp/u2a2f-fc3-p9d0/logs/cc-binary-grep.txt, /tmp/u2a2f-fc3-p9d0/logs/cc-reo.txt
- X10 `git diff --numstat main...HEAD -- ':(top)' ':(top,exclude)docs/' | awk` → 166 (also 166 at bff4ded2), and the override-row grep → 26 on main and HEAD. cwd the worktree, exit 0, printed in session.
- X11 `git apply` of the two Appendix patches onto `git archive d8003fbf` copies, then `cmp` against 39ed1d53, cwd /tmp/u2a2f-fc3-p9d0/pt, exit 0 (identical). Callers of inrepo_here from `grep -n` over scripts/ and test/.
- X12 `untracked_md` / `instruction_names` in a scratch repo, cwd /tmp/u2a2f-fc3-p9d0/fx4, exit 0 → /tmp/u2a2f-fc3-p9d0/logs/untracked.txt

## Goal-Alignment Note

- **Success criterion (verbatim):** "a markdown report saved at the path given in your tail, structured per your skill, with `Commit: 7697c6e6` as its first line."
- **Answered:** brief items 1-9, each against code, tests, real bash/grep/git behaviour and the installed Claude Code 2.1.292 import regex. The suites pass (100). The commit counts and mutants hold. Two comment claims are Incorrect: 18b ("as a blank does", fail-open, executed) and 21 (`[`). One Q-119 line is Stale.
- **Out of scope:** U2a3's main_imports and rows B2-B6, B8, B10-B12, B14. Commit messages d8003fbf and 7f295cdb. The added `*-build-loop-u2a*.md` review files (context only). Timing figures in override rows (not re-measured).
- **Escalate:** E1 (a token after a Unicode space is lost: fail-open on --check-fix today, and inherited by U2a3's floor walk) is the one item that may change this unit's verdict. E2 is lower. Neither is a regression against main.
- **Questions / Decisions:** captured output lives in /tmp/u2a2f-fc3-p9d0/logs/ rather than docs/reviews/execution-logs/, per the shared no-repo-writes rule.
