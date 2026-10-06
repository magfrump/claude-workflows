Commit: d48f4645

# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u2a1, branch feat/build-loop-u2a1)
**Scope:** branch diff `git diff main...HEAD` (main 900c47d0 .. d48f4645): scripts/build-loop.sh, scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, skills/dev-cycle/SKILL.md, test/lib/build-loop-fixtures.bash, test/scripts/build-loop-read.bats, test/scripts/dev-cycle.bats, docs/working/plan-build-loop-handoff.md, docs/working/questions.md (Q-119), the rubric `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md`, the five new `feat/build-loop-u2a1` rows of docs/reviews/override-log.md, and the messages of 6f624cdf, 706e0499 and d48f4645. Other docs/reviews/*.md artifacts were skipped as instructed.
**Replication:** replicate r1 of three (final confirming pass)
**Checked:** 2026-10-06
**Total claims checked:** 40
**Summary:** 34 verified, 6 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Execution provenance. Every executed claim ran against a `git archive` export of d48f4645 at `$FC/copy` (main 900c47d0 at `$FC/maincopy`), with
`FC=/home/node/.claude/jobs/814a541d/tmp/review-u2a1-final/fc1`, `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`, `TMPDIR=$FC/tmp` (test 25 alone: a `mktemp -d /tmp/u2a1fc-XXXX` TMPDIR, deleted after), each command under `timeout`. Captured output is in `$FC/logs/`; each log's first line holds its command, cwd and UTC timestamp, and its last line the exit code. Runs took place 2026-10-06T16:18Z-16:25Z. Mutants were applied only to throwaway copies (`$FC/mut-*`, deleted after each run). No process was left running; the victim repos were deleted.

Hallucination-pattern log consulted (`docs/reviews/hallucination-patterns.md`). Claims 34 and 37 (per-suite test tallies in commit messages) are in the class of the logged patterns "All 85 tests ... pass claimed in commit 59ca38f" and "mode1-equiv 33 claimed in commit 37c5ea9". Here the counts match. No claim in this run is a fabrication.

---

## Claim 1: "`code-fact-check-report-build-loop-u2a1.md`: k=1. 24 claims: 20 Verified, 3 Mostly accurate, 1 Unverifiable, 0 Incorrect."

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:11`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the tally against the iteration-1 report's header. It does not re-verdict that report's 24 claims.

The iteration-1 report's header reads `**Total claims checked:** 24` and `**Summary:** 20 verified, 3 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable` (`docs/reviews/code-fact-check-report-build-loop-u2a1.md:8-9`).

**Evidence:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:11`, `docs/reviews/code-fact-check-report-build-loop-u2a1.md:8-9`

---

## Claim 2: A1 "setup() did not clear an inherited `GIT_DIR`: executed, the suite wrote 2 commits and branch f1 into a victim repo ... ✅ Fixed: both setups run `unset $(git rev-parse --local-env-vars)`; checked, the victim keeps 1 commit"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:21`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the pre-fix damage (main's suite, the security reviewer's `trunk` victim and test filter) and the post-fix result for a valid inherited GIT_DIR across both full suites. It does not cover other inherited variables that are not repo-local (GIT_CONFIG_KEY_n without a COUNT, GIT_EXEC_PATH) or hermeticity-lint's static rules.

Pre-fix: `GIT_DIR=$V/.git timeout 300 bats -f 'check-fix refuses files an instruction file imports' test/scripts/dev-cycle.bats` in `$FC/maincopy`, with `$V` a one-commit repo on `trunk`, printed `exit=1 victim_commits=3 branches=f1,trunk,` (2026-10-06T16:24:13Z, `$FC/logs/victim-main-trunk.log`). That is 2 new commits and branch f1.
Post-fix: both full suites in `$FC/copy` with `GIT_DIR=$V/.git` printed `victim_commits=1 branches=main, status=0` (`$FC/logs/victim-full.log`, 2026-10-06T16:19:38Z; dev-cycle.bats exit 1 only for the environmental test 25, build-loop-read.bats exit 0). Both setups hold the line: `unset $(git rev-parse --local-env-vars)` (`test/scripts/dev-cycle.bats:13`, `test/lib/build-loop-fixtures.bash:15`).

**Evidence:** `test/scripts/dev-cycle.bats:8-22`, `test/lib/build-loop-fixtures.bash:7-23`, `$FC/logs/victim-main-trunk.log`, `$FC/logs/victim-full.log`, `$FC/logs/victim.log`

---

## Claim 3: A6 "Row 319 residue: short lines in the lib header (`:13`, `:25`) ... ✅ Fixed: reflowed"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:26`
**Type:** Staleness
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers line lengths of the lib header (lines 8-32) at 6f624cdf and d48f4645. It does not judge whether row 319 requires any particular width.

`awk 'NR>=8 && NR<=32 {print NR": "length($0)}' scripts/lib/dev-cycle-read.sh` (worktree, 2026-10-06T16:19Z) shows that :13 went from 27 characters at 6f624cdf to 79, so it was reflowed. But line 25 is still short (52 characters):

```
# scripts/lib/dev-cycle-read.sh:25
# scrub, read it as `out="$(check_brief ...)"` under
```

The reflow also made line 16 96 characters long, the only header line over 79:

```
# scripts/lib/dev-cycle-read.sh:16
# ROOT_REAL is set, is the current directory and is a repository's top level; while ROOT_REAL is
```

A precise version would be "reflowed :12-15; :25 is still short and :16 now runs to 96 columns".

**Evidence:** `scripts/lib/dev-cycle-read.sh:12-27`

---

## Claim 4: "Tests after the fixes: 95/95 (dev-cycle 74 with the new entry_why test, build-loop-read 19, hermeticity 2); shellcheck clean. Size after the fixes: 165 changed code lines."

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:38`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the three suites, shellcheck over the four changed shell files, and the numstat count at d48f4645. It does not cover other suites in the repo.

`timeout 900 bats test/scripts/dev-cycle.bats` in `$FC/copy` gave 73 ok and `not ok 25 an origin/HEAD naming an option-like branch cannot make git write a file` (`$FC/logs/dev-cycle.log`). The same test run alone with a non-dotted TMPDIR printed `ok 1 an origin/HEAD naming an option-like branch ...`, exit 0 (2026-10-06T16:19:04Z, `$FC/logs/dc-test25.log`). That makes 74/74. build-loop-read.bats gave 19 ok, exit 0, and test/fixture-hermeticity.bats gave 2 ok, exit 0 (`$FC/logs/build-loop-read.log`, `$FC/logs/fixture-hermeticity.log`). `grep -c '^@test'` gives 74, 19 and 2. Total: 95.
`git diff --numstat main...HEAD -- ':(top)' ':(top,exclude)docs/' | awk '{n+=$1+$2} END{print n}'` printed `165`. shellcheck on scripts/dev-cycle.sh, scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh and test/lib/build-loop-fixtures.bash exited 0 (`$FC/logs/counts.log`, 2026-10-06T16:19:09Z).

**Evidence:** `$FC/logs/dev-cycle.log`, `$FC/logs/dc-test25.log`, `$FC/logs/build-loop-read.log`, `$FC/logs/fixture-hermeticity.log`, `$FC/logs/counts.log`

---

## Claim 5: "Commit 6f624cdf's Notes say 'the lib's check_fix keeps reading the IMPORTED cache'; check_fix is in scripts/dev-cycle.sh and reads the lib's cache"

**Location:** `docs/reviews/override-log.md:321`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers where check_fix is defined and what it reads. It does not cover U2a2's planned `isimported`.

`check_fix() {` is at `scripts/dev-cycle.sh:170`, and the function reads the cache: `elif [[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]]; then` (`scripts/dev-cycle.sh:182`). `rg -n "check_fix\(\)" scripts/lib/` finds no definition (paraphrased, no quote available because the claim is about the absence of code).

**Evidence:** `scripts/dev-cycle.sh:170-185`

---

## Claim 6: "check_fix adds constraints.md inline ... This row closes 204: constraints.md is refused, docs/thoughts/ stays fixable on purpose"

**Location:** `docs/reviews/override-log.md:322`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers today's check_fix behaviour for constraints.md and docs/thoughts/. It does not establish what U2a2's floor will list (future work).

The test is inline in check_fix: `|| "$lp" == docs/dev-cycle.md || "$lp" == docs/constraints.md || "$a" == */.* ...` (`scripts/dev-cycle.sh:180`). Run against a throwaway repo, `--check-fix` printed `skip docs/constraints.md: in-cycle fixes edit only ...`, the same for `docs/CONSTRAINTS.MD` and `docs/Constraints.md`, and `ok docs/thoughts/t.md`, `ok docs/thoughts/constraints.md` (`$FC/logs/probe.log`, 2026-10-06T16:21:39Z).

**Evidence:** `scripts/dev-cycle.sh:170-185`, `$FC/logs/probe.log`

---

## Claim 7: "Three call sites write `isbrief X || isclosed X` themselves (lib writable, check_brief; build-loop.sh shared_branches)"

**Location:** `docs/reviews/override-log.md:323`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the call sites of isclosed in scripts/. It does not cover tests.

`rg -n isclosed scripts/` finds exactly three callers. `... ]] || isbrief "$1" || isclosed "$1"` is at `scripts/lib/dev-cycle-read.sh:161`, `if ! isbrief "$a" && ! isclosed "$a"; then` (the negated form) at `:344`, and `if ! { isbrief "$f" || isclosed "$f"; } || ! brief_fields "$f"; then continue; fi` at `scripts/build-loop.sh:318`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:158-162,344`, `scripts/build-loop.sh:318`

---

## Claim 8: "so `.github/x.yml` is refused under D5's dot rule rather than as badform"

**Location:** `docs/reviews/override-log.md:324`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the premise that main_entry answers badform for `.github/x.yml` and `.gitattributes` today. It does not cover the floor's future ordering, which is a deferred requirement.

The probe printed `.github/x.yml -> badform` and `.gitattributes -> badform` (`$FC/logs/probe.log`). The new test pins both: `for p in x "a\"b.md" "../x" "-x" "docs//x.md" .gitattributes .github/x.yml; do main_entry "$p"; done` (`test/scripts/dev-cycle.bats:1358`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:264-266`, `test/scripts/dev-cycle.bats:1356-1366`, `$FC/logs/probe.log`

---

## Claim 9: "entry_why adds one subshell (~0.3 ms) per refused argument, and isclosed costs ~17 µs more per brief pair in shared_branches than the old substitution"

**Location:** `docs/reviews/override-log.md:325`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the cost of each construct on this machine, with 2000 iterations and two runs. It does not cover other hosts or the "within run-to-run noise" suite claim.

`timeout 120 env LC_ALL=C bash perf.sh copy/scripts/lib/dev-cycle-read.sh` (cwd `$FC`, 2026-10-06T16:22:28Z, exit 0) printed `entry_why in $(...): 489.0 us/call` and `490.8 us/call`, and `delta 19.0 us` and `delta 36.9 us` per pair (isbrief||isclosed against the old `${f/#.../}` substitution). Both costs are the same order as the row says and still negligible next to the git call each refusal path makes. But they measure ~0.5 ms and ~19-37 µs here, not ~0.3 ms and ~17 µs. A precise version is "~0.3-0.5 ms" and "tens of µs".

**Evidence:** `$FC/perf.sh`, `$FC/logs/perf.log`, `scripts/lib/dev-cycle-read.sh:158,283-292`, `scripts/build-loop.sh:318`

---

## Claim 10: "U1 measured four units against a planned one, and U2 carries about twenty override rows"

**Location:** `docs/working/plan-build-loop-handoff.md:273`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the U1 unit count in main's log and the count of Defer rows whose revisit trigger names U2. It does not assign rows to sub-units.

`git log --oneline main | rg -i "U1[a-d]"` shows `ba465de2 docs(checkpoint): U1 landed (U1a-U1c); U1d built ...` and `4e12b03c Merge branch 'feat/build-loop-u1d'`: four units. `awk '/^\| 20/ && /Defer/ && /Revisit trigger:[^|]*U2/' docs/reviews/override-log.md | wc -l` prints 26 at HEAD. Three of those are this branch's new rows (C1-C3, `:322-324`), so 23 existed when the note was written. That is "about twenty" (paraphrased, no quote available because this is a count over table rows).

**Evidence:** `docs/working/plan-build-loop-handoff.md:273`, `docs/reviews/override-log.md:322-324`

---

## Claim 11: "U2a1: `main_entry`'s `badform` word with one shared reason mapping, `entry_why` ...; `isclosed` ...; `check_fix` also refuses `docs/constraints.md` (row 204: the user writes it, D2; ...)"

**Location:** `docs/working/plan-build-loop-handoff.md:274`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the match between the bullet and this diff, and D2's ownership statement. It does not cover the U2a2/U2b/U2c bullets (future work).

The named pieces exist: `if ! pathform "$1"; then echo badform; return; fi` (`scripts/lib/dev-cycle-read.sh:266`), `entry_why() {` (`:283`), `isclosed() { ... }` (`:158`), `|| "$lp" == docs/constraints.md` (`scripts/dev-cycle.sh:180`). D2 says "Creating the doc is your work" (`docs/working/plan-build-loop-handoff.md:50`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:43-51,273-279`, `scripts/lib/dev-cycle-read.sh:158,266,283`, `scripts/dev-cycle.sh:180`

---

## Claim 12: "Interim: [1]. Split recorded in the U2a rubric and commit e8f76379 on `feat/build-loop-u2a`."

**Location:** `docs/working/questions.md:391`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the existence of the commit, its branch and the split record. It does not judge the split.

`git log -1 --format='%h %s' e8f76379` gives `e8f76379 docs(reviews): U2a iteration 3 (final pass, k=3) and the iteration-4 gate decision: split`, and `git branch --contains e8f76379` gives `feat/build-loop-u2a`. On that branch the U2a rubric has `### Iteration-4 gate decision: \`split\`` (line 69) and a `**U2a1**` bullet (line 74).

**Evidence:** `docs/working/questions.md:376-393`, `feat/build-loop-u2a:docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md:69-74`

---

## Claim 13: "Markup that adds letters (a checked task box, a tag) can still hide a copy"

**Location:** `scripts/build-loop.sh:44-46`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the copy count in SETTINGS_AWK. It does not cover fences, which are skipped separately.

The copy test drops every non-letter, then checks the prefix: `s = tolower($0); gsub(/[^a-z]/, "", s); k = ""` and `if (index(s, "buildlooppolicy") == 1) k = "policy"` (`scripts/build-loop.sh:155-156`). So `- [x] Build-loop policy:` becomes `xbuildlooppolicy` and is missed, while `- [ ]` adds no letter and is counted. That matches line 18's "an unchecked task box" (counted) and line 20's "a checked task box" (missed).

**Evidence:** `scripts/build-loop.sh:14-21,42-46,150-165`

---

## Claim 14: "A tip on a branch not ahead of main, or whose subject does not start 'handoff:', is working."

**Location:** `scripts/build-loop.sh:65-66`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers status_line's loop state for an existing branch. It does not cover absent branches or refused branch names.

`ahead` is check_branch's `$(git rev-list --count "$MAIN_SHA..$sha")` (`scripts/lib/dev-cycle-read.sh:396`). status_line sets `loop=working` and reads a marker only under `if [[ "$ahead" -gt 0 ]]; then` (`scripts/build-loop.sh:352-353`). marker_kind answers `working` when `[[ "$subj" == handoff:* ]]` fails (`:286`). A branch level with main, or behind it, has `ahead` 0, so "not ahead" is the exact condition.

**Evidence:** `scripts/build-loop.sh:280-301,326-358`, `scripts/lib/dev-cycle-read.sh:396`

---

## Claim 15: main_file "returns 1 with FILE_WHY 'absent' or why it was not read (main_entry, ...)"; every word but blob/absent is a refusal worded by entry_why

**Location:** `scripts/build-loop.sh:122-133`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers main_file's three arms and their reasons for notfile, notdir and error, as observed in --settings. It does not cover badform, which main_file's two constant paths cannot reach.

```
# scripts/build-loop.sh:129-134
  e="$(main_entry "$f")"
  case "$e" in
    blob) ;;
    absent) FILE_WHY=absent; return 1 ;;
    *) FILE_WHY="$(entry_why "$e" "$f")"; return 1 ;;
  esac
```
(excerpt ends :134; enclosing main_file() continues to :141 — read)

`timeout 120 bash probe2.sh` (cwd `$FC`, 2026-10-06T16:21:57Z, exit 0) printed `constraints unreadable: docs is not a directory on the default branch` (docs a symlink on main) and `constraints unreadable: the tree of the default branch could not be read for docs/constraints.md` (a tree listing `docs` twice). The error reason names its file, as A3 says. `bats` gave notfile as `constraints unreadable: docs/constraints.md is not a regular file on the default branch` (`test/scripts/build-loop-read.bats:193`, passing). Every non-`absent` FILE_WHY reaches "unset"/"malformed"/"unreadable" lines (`scripts/build-loop.sh:213-217,263-265`).

**Evidence:** `scripts/build-loop.sh:121-141,210-218,262-266`, `$FC/logs/probe2.log`, `$FC/logs/build-loop-read.log`

---

## Claim 16: "--check-fix ... (not the cycle's own files, working/, human-author/, reviews/, decisions/, dev-cycle.md, constraints.md, a dot-directory or dotfile, an instruction file, or a file an instruction file imports with @; compared ignoring case)"

**Location:** `scripts/dev-cycle.sh:50-55`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the new constraints.md item, its case folding and the docs/thoughts/ residue. The other items are unchanged by this diff and were not re-probed.

`lp` is the lower-cased path (`lp="$(printf '%s' "$a" | tr 'ABC...Z' 'abc...z')"`, `scripts/dev-cycle.sh:175`) and the test is `"$lp" == docs/constraints.md` (`:180`). The probe refused `docs/constraints.md`, `docs/CONSTRAINTS.MD` and `docs/Constraints.md` and accepted `docs/thoughts/t.md` (`$FC/logs/probe.log`).

**Evidence:** `scripts/dev-cycle.sh:50-55,170-185`, `$FC/logs/probe.log`

---

## Claim 17: "the header's --check-fix paragraph is the rule, and the skip message below repeats it"

**Location:** `scripts/dev-cycle.sh:167-168`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the agreement of the header paragraph, the skip messages and SKILL.md with check_fix's conditions. It does not cover check_path's own skip lines (tracked, plain).

The second skip message lists `not working/, human-author/, reviews/, decisions/, dev-cycle.md, constraints.md, dot-directories or dotfiles, or instruction files` (`scripts/dev-cycle.sh:181`). That matches the header's list minus two items: the header's "the cycle's own files" and "a file an instruction file imports with @" (`:51-54`). Those two have skip messages of their own: `one of the cycle's own files (use --check-write)` (`:178`) and `an instruction file imports it with @ ...` (`:183`). So no single "skip message below" repeats the rule; the three messages do together. Every item in the header, the messages and SKILL.md (`skills/dev-cycle/SKILL.md:72-76`) has a matching condition in check_fix, and none is missing. A precise version is "the three skip messages below repeat it".

**Evidence:** `scripts/dev-cycle.sh:50-55,167-185`, `skills/dev-cycle/SKILL.md:72-76`

---

## Claim 18: "constraints.md is the user's (plan D2); docs/thoughts/ stays fixable."

**Location:** `scripts/dev-cycle.sh:168-169`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers D2's ownership statement and check_fix's thoughts/ outcome. It does not cover the floor's planned treatment of thoughts/.

D2 says "Creating the doc is your work" (`docs/working/plan-build-loop-handoff.md:50`). check_fix's regex excludes only `^docs/(working|human-author|reviews|decisions)/` (`scripts/dev-cycle.sh:179`), and the probe printed `ok docs/thoughts/t.md` (`$FC/logs/probe.log`).

**Evidence:** `scripts/dev-cycle.sh:168-185`, `docs/working/plan-build-loop-handoff.md:50`, `$FC/logs/probe.log`

---

## Claim 19: "A change here must pass test/scripts/dev-cycle.bats and build-loop.sh's suites (build-loop-*.bats)."

**Location:** `scripts/lib/dev-cycle-read.sh:10-11`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the existence of the named suites and that they pass at d48f4645. It does not cover suites that other scripts may add later.

`ls test/scripts/build-loop-*.bats` lists only `test/scripts/build-loop-read.bats`. Both it and dev-cycle.bats pass (Claim 4). The plural "suites" is forward-looking: the glob matches the one suite that exists today (paraphrased, no quote available because this is a directory listing).

**Evidence:** `scripts/lib/dev-cycle-read.sh:10-11`, `$FC/logs/dev-cycle.log`, `$FC/logs/build-loop-read.log`

---

## Claim 20: "`isclosed` spells the closed/ brief path rule once (writable, check_brief, shared_branches)", equal to the three old spellings

**Location:** `scripts/lib/dev-cycle-read.sh:158`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers equality with the old writable regex, the old check_brief regex and the old shared_branches substitution over 27 edge-case paths. It is not an exhaustive proof, although the static argument below covers the general case.

```
# scripts/lib/dev-cycle-read.sh:157-158
isbrief() { [[ "$1" =~ ^docs/working/briefs/$DIGIT{4}-$DIGIT{2}-$DIGIT{2}-$SLUG\.md$ ]]; }
isclosed() { [[ "$1" == docs/working/briefs/closed/* ]] && isbrief "docs/working/briefs/${1#docs/working/briefs/closed/}"; }
```

`timeout 60 env LC_ALL=C bash isclosed-eq.sh copy/scripts/lib/dev-cycle-read.sh` (cwd `$FC`, 2026-10-06T16:20:18Z, exit 0) printed `cases=27 diffs=0`. The cases included a trailing newline, a nested `closed/closed/`, `closed/sub/`, a `2026-10-0closed` directory, a doubled `docs/working/briefs` prefix, upper case, `//` and a full-width digit. Statically, SLUG and DIGIT hold no `/` or newline, so the stripped remainder must be a single file name, the same constraint the old anchored regex imposed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:155-162,344`, `scripts/build-loop.sh:318`, `$FC/isclosed-eq.sh`, `$FC/logs/isclosed-eq.log`

---

## Claim 21: "'badform' (a path pathform refuses: a .git* part such as .gitattributes, say) or 'error' (...). Only blob reads the file, and only absent means there is none: every other word is a refusal."

**Location:** `scripts/lib/dev-cycle-read.sh:252-259`
**Type:** Invariant / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every caller of main_entry in scripts/ (check_brief, check_answer, brief_fields, build-loop.sh main_file, and shared_branches/status_line through brief_fields/check_brief). With no default branch found by name, a refused path answers `error`, not `badform`, because main_by_name runs first; the comment's word list does not state that order.

`rg -n main_entry scripts/` finds four call sites. Each treats only blob as readable and every word but absent as a refusal:
- check_brief: `absent) echo "ok $a new"; return ;;`, `blob) ;;`, `*) echo "skip $a: $(entry_why "$e" "")"; return ;;` (`scripts/lib/dev-cycle-read.sh:351-354`).
- check_answer: `absent) continue ;;`, `blob) ;;`, and two skip arms (`:569-574`).
- brief_fields: `[[ "$(main_entry "$1")" != blob ]]` → `BRIEF_ODD=error; return 1` (`:312`). Absent is a refusal here too, which is stricter than the comment and consistent with it.
- main_file (Claim 15).

shared_branches goes through brief_fields (`scripts/build-loop.sh:318`), and status_line goes through check_brief and brief_fields (`:327-330`). The probe printed `no main + bad path -> error` (`$FC/logs/probe.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:247-279,306-315,337-355,562-575`, `scripts/build-loop.sh:126-141,306-331`, `$FC/logs/probe.log`

---

## Claim 22: "It runs main_by_name and pathform itself, before any read"; badform is answered before any git call

**Location:** `scripts/lib/dev-cycle-read.sh:257-258`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the six refused path shapes probed and one valid path. It does not cover git calls made by resolve_main, which runs before main_entry.

```
# scripts/lib/dev-cycle-read.sh:265-266
  if ! main_by_name; then echo error; return; fi
  if ! pathform "$1"; then echo badform; return; fi
```
(excerpt ends :266; enclosing main_entry() continues to :278 — read; the first git call is ls-tree at :268)

With a PATH shim logging every git call, six refused paths (`.gitattributes`, `.github/x.yml`, `../x`, `a"b`, `docs//x.md`, `-x`) each printed `badform` and made `git calls for 6 refused paths: 0`. One valid path then printed `blob` after 1 call (`$FC/logs/probe.log`, 2026-10-06T16:21:39Z, exit 0). Mutant M4 (pathform check deleted) fails the pinning test (`$FC/logs/mutants.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:262-279`, `$FC/probe.sh`, `$FC/logs/probe.log`, `$FC/logs/mutants.log`

---

## Claim 23: "$2 is the path, named in the reason; pass "" when the skip line already names it. A newline in either becomes a space, so the reason stays one line."

**Location:** `scripts/lib/dev-cycle-read.sh:280-282`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers all five arms with and without a path, and a newline in the path. It does not cover a CR or other control characters, which the comment does not claim to handle (scrub handles them downstream).

```
# scripts/lib/dev-cycle-read.sh:283-292
entry_why() {
  local w="${1//$'\n'/ }" p="${2//$'\n'/ }"
  case "$w" in
    notdir\ *) echo "${w#notdir } is not a directory on the default branch" ;;
    notfile) echo "${p:+$p is }not a regular file on the default branch" ;;
    badform) echo "${p:+$p is }not an allowed path form" ;;
    error) echo "the tree of the default branch could not be read${p:+ for $p}" ;;
    *) echo "the default branch answered $w${p:+ for $p}" ;;
  esac
}
```

The notdir arm names the directory from `$1`, not `$2`, so its reason is the same with or without a path. The test pins this (`test/scripts/dev-cycle.bats:1340`, expected lines 1343-1344). The new test passes, and mutants M1 (newline fold removed) and M2 (notfile always prints `$p is`) each fail it (`$FC/logs/mutants.log`, 2026-10-06T16:20:51Z-16:20:52Z). The callers' skip lines:
- check_brief passes `""`: `skip docs/working/briefs/2026-10-01-l.md: not a regular file on the default branch` and `skip docs/working/briefs/closed/2026-10-01-z.md: docs/working/briefs/closed is not a directory on the default branch` (`$FC/logs/probe2.log`).
- main_file (Claim 15) and check_answer (Claim 25) pass the path.

`rg` over skills/, docs/working/, docs/*.md and scripts/ finds no doc or help text quoting an old wording that is no longer printed (paraphrased, no quote available because the claim covers the absence of matches).

**Evidence:** `scripts/lib/dev-cycle-read.sh:280-292,351-354`, `test/scripts/dev-cycle.bats:1338-1354`, `$FC/logs/mutants.log`, `$FC/logs/probe2.log`

---

## Claim 24: brief_fields' "error (no default branch found by name, a path pathform refuses, any main_entry answer but blob, its error included, or the blob could not be read)"

**Location:** `scripts/lib/dev-cycle-read.sh:302-305`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers brief_fields' refusal paths with the new badform word. It does not cover the odd/unbalanced arms, which are unchanged.

`if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]; then BRIEF_ODD=error; return 1; fi` (`scripts/lib/dev-cycle-read.sh:312`). badform falls under "any main_entry answer but blob". pathform runs first, so main_entry never answers badform here. The read failure is `|| { BRIEF_ODD=error; return 1; }` (`:322`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:293-330`

---

## Claim 25: check_answer's `# "it" is $f, except after notdir, whose reason names a directory above it.` and its skip lines

**Location:** `scripts/lib/dev-cycle-read.sh:572-574`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the notdir, notfile and error lines, observed in passing tests. It does not cover badform, which check_answer's two constant paths cannot reach, though the `*)` arm would word it.

```
# scripts/lib/dev-cycle-read.sh:572-574
      # "it" is $f, except after notdir, whose reason names a directory above it.
      notdir\ *) echo "skip $a: $(entry_why "$e" "$f"), so no entry in $f is read"; return ;;
      *) echo "skip $a: $(entry_why "$e" "$f"), so no entry in it is read"; return ;;
```
(excerpt ends :574; enclosing check_answer() continues to :591 — read)

The passing tests pin each line:
- notdir: `skip Q-1: docs/working is not a directory on the default branch, so no entry in docs/working/questions.md is read` (`test/scripts/dev-cycle.bats:1203`).
- error: `skip Q-1: the tree of the default branch could not be read for docs/working/questions.md, so no entry in it is read` (`:1327`).
- notfile: `... docs/working/questions.md is not a regular file on the default branch, so no entry in it is read` (`:1198`).

In each `*)` line, "it" follows the path that entry_why named.

**Evidence:** `scripts/lib/dev-cycle-read.sh:557-591`, `test/scripts/dev-cycle.bats:1198,1203,1327`, `$FC/logs/dev-cycle.log`

---

## Claim 26: "`--check-fix '<path>'` prints `ok` for: a tracked `.md` file under `docs/` (not ... `docs/dev-cycle.md`, `docs/constraints.md`, a dot-directory or dotfile, ...)"

**Location:** `skills/dev-cycle/SKILL.md:72-76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the agreement of the SKILL.md list with check_fix and the script header. It does not cover the rest of SKILL.md.

SKILL.md's list matches the header item for item (`scripts/dev-cycle.sh:50-55`), including the new `docs/constraints.md`, and each item has its condition in check_fix (`scripts/dev-cycle.sh:178-183`; Claim 17).

**Evidence:** `skills/dev-cycle/SKILL.md:72-76`, `scripts/dev-cycle.sh:50-55,170-185`

---

## Claim 27: "a throwaway repo ... the same hermetic git environment as test/scripts/dev-cycle.bats"

**Location:** `test/lib/build-loop-fixtures.bash:2-4`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the git-related environment of both setups. It does not cover LC_ALL, which bl_setup sets to C and dev-cycle.bats' setup does not (a locale setting, not a git one).

Both setups run `unset $(git rev-parse --local-env-vars)` (`test/lib/build-loop-fixtures.bash:15`, `test/scripts/dev-cycle.bats:13`) and export `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`, the same author and committer, and HOME under `$BATS_TEST_TMPDIR` (`test/lib/build-loop-fixtures.bash:16-20`, `test/scripts/dev-cycle.bats:14-19`).

**Evidence:** `test/lib/build-loop-fixtures.bash:1-23`, `test/scripts/dev-cycle.bats:8-22`

---

## Claim 28: "An inherited GIT_DIR (a run from a git hook, say) would send every fixture command to that repo ...; git lists every such repo-local variable itself (GIT_CONFIG_PARAMETERS too)." / "As bl_setup: an inherited GIT_DIR would send fixture commits to that repo."

**Location:** `test/lib/build-loop-fixtures.bash:11-15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers git 2.39.5's list, both suites with a valid inherited GIT_DIR, and one test with an invalid GIT_DIR. It does not cover GIT_CONFIG_KEY_n/VALUE_n, which git does not list. No test relies on them being inherited: the build-loop tests pass GIT_CONFIG_COUNT per command with `env`.

`git rev-parse --local-env-vars` prints 16 names, including `GIT_DIR`, `GIT_WORK_TREE`, `GIT_INDEX_FILE`, `GIT_CONFIG_PARAMETERS` and `GIT_CONFIG_COUNT`, and the earlier list's six (paraphrased, no quote available because this is command output, not repo text). Claim 2 shows the damage before the fix and none after it, for both suites. With `GIT_DIR=/nonexistent/x`, `prints all eight sections ...` still passed (`$FC/logs/victim.log`), so a broken GIT_DIR does not stop the setup. The build-loop-read tests that pass `env GIT_CONFIG_COUNT=1 ...` per command still pass (`test/scripts/build-loop-read.bats:438,483`; Claim 4). The same comment (row 314) also appears at `test/scripts/dev-cycle.bats:11` (paraphrased, no quote available because the location is given in this claim's title).

**Evidence:** `test/lib/build-loop-fixtures.bash:11-15`, `test/scripts/dev-cycle.bats:11-13`, `$FC/logs/victim.log`, `$FC/logs/victim-full.log`

---

## Claim 29: "# A marker whose message body holds a NUL byte (one commit on top of base, with its tree)."

**Location:** `test/scripts/build-loop-read.bats:297`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the hand-made object's tree and parent. It does not cover the assertion that follows.

`printf 'tree %s\nparent %s\n...' "$(git rev-parse "$base^{tree}")" "$base"` (`test/scripts/build-loop-read.bats:298`): one parent, base, and base's tree.

**Evidence:** `test/scripts/build-loop-read.bats:296-301`

---

## Claim 30: the split fixture chains (row 317) make a failed fixture step fail the test

**Location:** `test/scripts/build-loop-read.bats:436-440`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the three chains row 317 names (:436, the CRLF overwrite :466-468, the closed-directory file :473-475). It does not cover the older chain at :84, which row 317 does not name, or a step that succeeds but does the wrong thing.

The mutants, each run on a copy:
- M7b, `git replace 0000000000000000000000000000000000000000 ...` at :436: `not ok 1 --settings: deferred cases ...`.
- M8, CRLF write to `/nonexistent/b` at :467: `not ok 2 --status: deferred cases ...`.
- M9, closed-dir write to `/nonexistent/c` at :474: `not ok 2`.

All three are in `$FC/logs/mutants.log` (2026-10-06T16:20:57Z-16:21:17Z). The standalone `git replace -d` at :440 also fails when the replace never happened: M7c, which restores the old `&&` chain with the bad replace, still fails, at the `-d`.

**Evidence:** `test/scripts/build-loop-read.bats:414-441,451-476`, `$FC/mut.sh`, `$FC/logs/mutants.log`

---

## Claim 31: "# docs/constraints.md is the user's (plan D2); docs/thoughts/ stays a living doc the cycle may fix." with the extended --check-fix test

**Location:** `test/scripts/dev-cycle.bats:1026`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the test pins the constraints.md refusal. It does not pin docs/thoughts/ against a future over-broad refusal beyond the one `ok docs/thoughts/t.md` line.

The test passes, and mutant M6 (`|| "$lp" == docs/constraints.md` deleted) gives `not ok 1 --check-fix refuses files an instruction file imports, and compares paths ignoring case` (`$FC/logs/mutants.log`, 2026-10-06T16:20:54Z).

**Evidence:** `test/scripts/dev-cycle.bats:1016-1032`, `$FC/logs/mutants.log`

---

## Claim 32: "entry_why words each main_entry refusal on one line, naming the path only when given (U2a1)"

**Location:** `test/scripts/dev-cycle.bats:1338`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the newline fold and the empty-path forms. It does not test a newline in the word `$1` alone; the newline case puts it in `$2`.

The test passes. M1 (newline fold removed) and M2 (notfile ignores the empty path) each fail it (`$FC/logs/mutants.log`). The newline case is `entry_why badform "a\nok b"` expecting `a ok b is not an allowed path form` (`test/scripts/dev-cycle.bats:1341-1353`, input at :1341-1342, expectation at :1353).

**Evidence:** `test/scripts/dev-cycle.bats:1338-1354`, `$FC/logs/mutants.log`

---

## Claim 33: "main_entry answers badform for a path pathform refuses, absent for a plain missing one (U1d, U2a)" (positive control, row 320)

**Location:** `test/scripts/dev-cycle.bats:1356`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the reverts and fixture loss this test should catch. The test name says "U2a", while the unit is U2a1 (a label, not a behaviour).

Three mutants each fail the test (`$FC/logs/mutants.log`):
- M3 (badform reverted to error).
- M4 (the pathform guard deleted).
- M5 (the fixture renames main to trunk before `resolve_main || true`, so main is not found by name and every line answers `error`). This is the vacuous-pass case row 320 named: the first line, `x` → `absent`, is the control that catches it.

**Evidence:** `test/scripts/dev-cycle.bats:1356-1366`, `$FC/logs/mutants.log`

---

## Claim 34: commit 6f624cdf "Tests: dev-cycle.bats 73, build-loop-read.bats 19, hermeticity 2 pass. 128 changed code lines." and its row list (314, 317-320, 228, 292, 306, 204)

**Location:** commit 6f624cdf message
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the test counts and line count at 6f624cdf, and that each named row's change is in the diff. The suites were run here only at d48f4645, not at 6f624cdf (the iteration-1 report ran them there).

`git show 6f624cdf:<suite> | grep -c '^@test'` gives 73, 19 and 2. `git diff --numstat main...6f624cdf -- ':(top)' ':(top,exclude)docs/'` sums to `128` (`$FC/logs/counts.log`). Each named row's change is present: 306/228 → badform and entry_why (Claims 21-23), 292 → isclosed (Claim 20), 204 → constraints.md (Claim 16), 314 → bl_setup's unset (at 6f624cdf, `unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES`), 317 → the three split chains (Claim 30), 318 → T7's comment (Claim 29), 319 → header wording (Claims 13, 14, 19), 320 → the positive control (Claim 33).

**Evidence:** `6f624cdf:test/lib/build-loop-fixtures.bash:11-13`, `$FC/logs/counts.log`

---

## Claim 35: commit 6f624cdf Notes "the lib's check_fix keeps reading the IMPORTED cache until U2a2's isimported."

**Location:** commit 6f624cdf message
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers where check_fix lives. It is already recorded as an Accepted-immutable override row (`docs/reviews/override-log.md:321`), and this report does not ask for any change.

check_fix is defined at `scripts/dev-cycle.sh:170`, not in the lib, and it reads the lib's `IMPORTED` (`:182`). A precise version is "dev-cycle.sh's check_fix keeps reading the lib's IMPORTED cache" (see Claim 5).

**Evidence:** `scripts/dev-cycle.sh:170-185`, `docs/reviews/override-log.md:321`

---

## Claim 36: commit 706e0499 "0 Must Fix; 1 Medium ..., 1 Low, 4 Minor ... Four declined findings get override rows (C1-C4), and row 204 is closed by C1's row." / "213 KB of enclosing files is over the inline budget"

**Location:** commit 706e0499 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the tallies against the rubric and override log, and the byte count of the changed scripts/ and test/ files at 6f624cdf. It does not establish what the "inline budget" is.

The rubric has A1 Medium and A2 Low (`docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:21-22`). The Minor count is api 3 + architecture 1 (`:14-15`). C1-C4 have rows at `docs/reviews/override-log.md:322-325`, and C1's row says "This row closes 204". The changed non-docs files other than SKILL.md at 6f624cdf total 213,119 bytes: build-loop.sh 21,775, dev-cycle.sh 29,961, lib 35,165, fixtures 3,722, build-loop-read.bats 35,321, dev-cycle.bats 87,175 (`git cat-file -s`).

**Evidence:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:11-32`, `docs/reviews/override-log.md:321-325`

---

## Claim 37: commit d48f4645 "Tests: dev-cycle.bats 74 ..., build-loop-read.bats 19, hermeticity 2, all pass; test 25 passes run with a TMPDIR that has no dot-prefixed part. shellcheck clean. 165 changed code lines against main."

**Location:** commit d48f4645 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Same runs as Claim 4. It does not cover other suites.

See Claim 4: 73 + test 25 under `/tmp/u2a1fc-RUQO` = 74, 19 and 2 pass, shellcheck exits 0, and numstat prints 165.

**Evidence:** `$FC/logs/dev-cycle.log`, `$FC/logs/dc-test25.log`, `$FC/logs/build-loop-read.log`, `$FC/logs/fixture-hermeticity.log`, `$FC/logs/counts.log`

---

## Claim 38: commit d48f4645 "With GIT_DIR pointing at a victim repo, the suite no longer writes into it (checked: 1 commit before and after)."

**Location:** commit d48f4645 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** As Claim 2.

Both full suites with an inherited GIT_DIR left the victim at `victim_commits=1 branches=main, status=0` (`$FC/logs/victim-full.log`).

**Evidence:** `$FC/logs/victim-full.log`

---

## Claim 39: commit d48f4645 "check_answer goes back to 'so no entry in it is read' (in $f after notdir ...)" and Notes "the old, pre-U2a1 sentences come back except where a path is now named"

**Location:** commit d48f4645 message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers check_answer's three skip sentences on main and at d48f4645. It does not cover check_brief or main_file, which do keep main's sentences (check_brief verbatim; main_file's notdir/notfile verbatim, error reworded).

Only the notfile sentence is main's verbatim. On main, two sentences ended differently:

```
# main:scripts/lib/dev-cycle-read.sh (check_answer, notdir and error arms)
notdir\ *) echo "skip $a: ${e#notdir } is not a directory on the default branch, so $f is not read"; return ;;
error) echo "skip $a: the tree of the default branch could not be read, so $f is not read"; return ;;
```

At d48f4645 both end "so no entry in ... is read" (`scripts/lib/dev-cycle-read.sh:573-574`). The changed test expectations confirm it, for example `... so no entry in docs/working/questions.md is read` (`test/scripts/dev-cycle.bats:1203`, formerly `... so docs/working/questions.md is not read`). For notdir no path was newly named, yet the sentence changed. The commit's A4 bullet ("goes back to 'so no entry in it is read'") is right relative to 6f624cdf. The Notes sentence is right only for notfile. No doc quotes the old endings (Claim 23), so nothing drifted.

**Evidence:** `scripts/lib/dev-cycle-read.sh:568-575`, `main:scripts/lib/dev-cycle-read.sh` (check_answer), `test/scripts/dev-cycle.bats:1203,1327`

---

## Claim 40: commit d48f4645 "A6: the lib header's short lines reflowed (row 319's residue)."

**Location:** commit d48f4645 message
**Type:** Staleness
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** As Claim 3.

Lines 12-15 were reflowed, but :25 is still 52 characters and :16 is now 96 (Claim 3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:12-27`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 3** (`docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:26`): A6 "Fixed: reflowed" is partial. `scripts/lib/dev-cycle-read.sh:25` is still a 52-column line, and `:16` now runs to 96 columns.
- **Claim 9** (`docs/reviews/override-log.md:325`): measured here at ~0.49 ms per entry_why subshell and 19-37 µs per pair, not ~0.3 ms and ~17 µs. Same order; the Won't-Fix reasoning holds.
- **Claim 17** (`scripts/dev-cycle.sh:167-168`): "the skip message below repeats it". It takes the three skip messages (`:178`, `:181`, `:183`) together to repeat the header's list.
- **Claim 35** (commit 6f624cdf): check_fix is in `scripts/dev-cycle.sh:170`, not the lib. This is already an Accepted-immutable row (`docs/reviews/override-log.md:321`).
- **Claim 39** (commit d48f4645): the Notes sentence "the old, pre-U2a1 sentences come back" holds only for check_answer's notfile line. The notdir and error lines now end "so no entry in ... is read" (`scripts/lib/dev-cycle-read.sh:573-574`). This is commit history; nothing quotes the old endings.
- **Claim 40** (commit d48f4645): same residue as Claim 3.

### Unverifiable
(none)

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved at the replicate path named below (inside the worktree), structured per the code-fact-check skill, with `Commit: d48f4645` as its first line.
- Answered: yes. All nine focus areas are verdicted. The behavioural ones were executed: suites, the victim GIT_DIR before and after, the isclosed equivalence, the git-call count and 10 mutants.
- Out of scope: U2a2/U2b/U2c plan bullets and the floor's future ordering (future work); docs/reviews/*.md artifacts other than the rubric and the new override-log rows.
- Escalate: nothing blocking. Claims 3/40 (the header reflow residue at `:16` and `:25`) and Claim 17 are wording-only.
- Decisions I made: counted test 25 as passing on its isolated non-dotted-TMPDIR run, per the dispatch. Graded the perf figures and the comment's "the skip message" Mostly accurate rather than Verified, because each states a specific value or count that differs.
