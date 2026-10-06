Commit: d07cc89c

# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u2a1, branch feat/build-loop-u2a1)
**Scope:** branch diff `git diff main...HEAD` (main 900c47d0 .. d07cc89c): scripts/build-loop.sh, scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, skills/dev-cycle/SKILL.md, test/lib/build-loop-fixtures.bash, test/scripts/build-loop-read.bats, test/scripts/dev-cycle.bats, test/scripts/fixture-git-env.bats, docs/working/plan-build-loop-handoff.md, docs/working/questions.md (Q-119), the rubric's iteration-2 section, the 2026-10-06 `feat/build-loop-u2a1` override rows, and the messages of 91469367 and d07cc89c. Earlier commits' messages are settled by Accepted-immutable rows. Other docs/reviews/*.md artifacts were not checked.
**Replication:** replicate r2 of three (iteration 3, final confirming pass)
**Checked:** 2026-10-06
**Total claims checked:** 38
**Summary:** 35 verified, 3 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Execution provenance. `FC=/home/node/.claude/jobs/814a541d/tmp/review-u2a1-i3/fc2`. Suite runs used the worktree itself and read
only. A `TMPDIR=$(mktemp -d /tmp/u2a1i3-XXXX)` was deleted after each run. Mutants ran on copies of `scripts/` and `test/` under
`$FC/copy-*` through `$FC/mut.sh`, `$FC/mut2.sh`, `$FC/mut3.sh` and `$FC/mut4.sh`, and each copy was deleted after its run. Git
fixtures used `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`. Every command ran under `timeout`. Captured output is in
`$FC/logs/`. Runs took place 2026-10-06T16:47Z-16:54Z. No process of this replicate was left running. Copy-based runs of
build-loop-read.bats test 4 fail in every copy because they read `$REPO_ROOT/docs/dev-cycle.md`, and the copies hold no
`docs/`. That failure is environmental and is ignored below.

Hallucination-pattern log consulted (`docs/reviews/hallucination-patterns.md`). Claims 10 and 34 (per-suite test tallies in a
commit message and the rubric) belong to the class of the logged patterns "All 85 tests ... claimed in commit 59ca38f" and
"mode1-equiv 33 claimed in commit 37c5ea9". This time every count matches.

---

## Claim 1: "233 changed code lines after iteration 2's fixes"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:4`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the count at d07cc89c, which has the same code as 91469367 (d07cc89c touches only docs/). It does not cover any other way of counting.

`git diff --numstat main...HEAD -- ':(top)' ':(top,exclude)docs/' | awk '{n+=$1+$2} END{print n}'` (cwd the worktree, exit 0,
2026-10-06T16:51:30Z) printed `233`. The diff stat of 91469367..d07cc89c lists only `docs/reviews/*` files (paraphrased — no quote available because the claim is about which files a commit touches, from `git diff --stat`).

**Evidence:** `$FC/logs/numstat.txt`

---

## Claim 2: "code-fact-check-report-build-loop-u2a1.md, merged, k=3 (replicates -r1/-r2/-r3: 40, 34, 37 claims). 53 clusters: 44 Verified, 9 Mostly accurate, 0 Incorrect. Agreement 88.7% (47/53)."

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:11`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the agreement of the tallies with the replicate headers and the merged report's statistics. It does not re-verdict the merged claims.

The replicate headers read `**Total claims checked:** 40` (r1) and `**Total claims checked:** 37 (Claims 1-35, 36a, 36b)` (r3).
r2 read `**Total claims checked:** 34` at d48f4645 (read before this report overwrote it). The merged report has
`- Clusters where all reporting replicates agreed: 47 of 53.` and `44 Verified and 9 Mostly accurate` (`docs/reviews/code-fact-check-report-build-loop-u2a1.md:1127,1140`).
47/53 = 0.8868, which rounds to 88.7%.

**Evidence:** `docs/reviews/code-fact-check-report-build-loop-u2a1-r1.md`, `docs/reviews/code-fact-check-report-build-loop-u2a1-r3.md`, `docs/reviews/code-fact-check-report-build-loop-u2a1.md:1126-1140`

---

## Claim 3: "A7 ... ✅ Fixed (91469367): comment states each word's use; check_answer ends every refusal \"so no entry in $f is read\""

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:20`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers check_answer's main_entry-refusal arm and the entry_why comment. It does not cover check_answer's other skip lines ("could not be read", "more than one entry", "in both").

```bash
# scripts/lib/dev-cycle-read.sh:572-577
    e="$(main_entry "$f")"
    case "$e" in
      absent) continue ;;
      blob) ;;
      *) echo "skip $a: $(entry_why "$e" "$f"), so no entry in $f is read"; return ;;
    esac
```
(excerpt ends :577; enclosing check_answer() continues to :593 — read). check_answer has one refusal arm, and its odd, unbalanced
and quoted arms at `:584-586` also end `so no entry in $f is read`. The mutant that rewrites that ending to `so $f is not read`
fails tests 65, 67 and 71 (`$FC/mut.sh answer-ending`, exit 1, 72 ok and 3 not ok, 2026-10-06T16:49:32Z). The comment is Claim 28.

**Evidence:** `scripts/lib/dev-cycle-read.sh:566-593`, `$FC/logs/mut-answer-ending.txt`

---

## Claim 4: "A8 | entry_why read `$2` bare; called with one argument under `set -u` it printed an empty reason | ✅ Fixed: `${2-}`"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:21`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a one-argument call inside `$(...)` at d48f4645 and at HEAD. It does not cover a bare (non-subshell) call at d48f4645, which would end the caller's shell under set -e.

At d48f4645 the line was `local w="${1//$'\n'/ }" p="${2//$'\n'/ }"`. `bash -c 'set -euo pipefail; source lib-d48.sh; echo "[$(entry_why notfile)]"'`
(cwd `$FC`, exit 0, 2026-10-06T16:54:03Z) printed `line 284: 2: unbound variable` and then `[]`. At HEAD, `local w="${1//$'\n'/ }" p="${2-}"`
(`scripts/lib/dev-cycle-read.sh:287`) gives `not a regular file on the default branch` for `entry_why notfile` under `set -euo pipefail`.

**Evidence:** `$FC/logs/a8-d48.txt`, `$FC/logs/probe-badform-onearg.txt`, `scripts/lib/dev-cycle-read.sh:286-296`

---

## Claim 5: "A10 | The `unset` line is pinned by no test: replacing it with `:` passes every test while a victim repo gains 7 and 5 commits | ✅ Fixed: test/scripts/fixture-git-env.bats; fails on that mutant"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the victim counts for the two inner tests the new suite runs and the new suite's failure on the `:` mutant. It does not cover the GIT_INDEX_FILE half (Claim 31b).

`$FC/mut4.sh` (2026-10-06T16:52:51Z) replaced both `unset` lines with `:` and ran each filtered inner test against a fresh
victim. It printed `dev-cycle.bats: victim commits 8, refs 4` and `build-loop-read.bats: victim commits 6, refs 1`, which is 7 and 5
commits above the victim's 1. `$FC/mut2.sh` (exit 1) ran the new suite on the same mutant and printed `not ok 1 dev-cycle.bats fixtures ...`
and `not ok 2 build-loop-read.bats fixtures ...`. Test 1 fails at the inner run's own status (the inner dev-cycle test fails with
the victim as its repo) before it reaches the victim check. Test 2 fails at the victim check.

**Evidence:** `$FC/logs/mut-colon-victim.txt`, `$FC/logs/mut-unsetboth.txt`, `test/scripts/fixture-git-env.bats:17-32`

---

## Claim 6: "A11 | isclosed's `closed/*` prefix guard is pinned by no test: without it `--check-write 2026-01-01-x.md` prints ok ... ✅ Fixed: new dev-cycle.bats test; fails on that mutant"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:24`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the guard-dropped mutant against the new test. It does not cover other isclosed mutants.

The mutant `isclosed() { isbrief "docs/working/briefs/${1#docs/working/briefs/closed/}"; }` (`$FC/mut.sh isclosed-prefix`, exit 1,
2026-10-06T16:49:21Z) fails `a closed brief is a closed/ path only ...`. The captured output starts `# ok 2026-01-01-x.md`. The
`closedx/` and `docs/` lines in that test do not tell the mutant apart (their prefix is not stripped either way). Only the bare name does.

**Evidence:** `$FC/logs/mut-isclosed-prefix.txt`, `test/scripts/dev-cycle.bats:1371-1379`

---

## Claim 7: "A12 | main_entry's guard order (error before badform with no default branch) is unstated and unpinned | Low | ... ✅ Fixed: comment and one test line"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the swapped-guard mutant against the badform test. It does not cover the comment's wording (Claim 27).

The mutant that puts `if ! pathform "$1"; then echo badform; return; fi` before the main_by_name line (`$FC/mut.sh guard-order`,
exit 1) fails the test at its last expected line, `error" ] || ...` (test file line 1368). The test sets `MAIN_SHA=""; main_entry .gitattributes`
(`test/scripts/dev-cycle.bats:1359`).

**Evidence:** `$FC/logs/mut-guard-order.txt`, `test/scripts/dev-cycle.bats:1356-1369`

---

## Claim 8: "A13 | Wording: \"the skip message below repeats it\" (three messages do); the lib header's :16 and :25 | ✅ Fixed: \"skip messages\"; header reflowed whole"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:26`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the check_fix comment and lib header lines 8-27. It does not cover the scrub comment's long line at `:36`, which is outside the header paragraph.

`scripts/dev-cycle.sh:168` reads `# is the rule, and the skip messages below repeat it.`. Lib header lines 8-27 are all filled to
about 78 columns with no short line (paraphrased — no quote available because the claim is about line lengths across 20 lines).

**Evidence:** `scripts/dev-cycle.sh:167-169`, `scripts/lib/dev-cycle-read.sh:8-31`

---

## Claim 9: "C11 | C4 override row's timings (measured 0.42-0.52 ms, 18-37 µs) | Mostly accurate | fact-check 13 | ✅ Row's figures corrected; the conclusion holds"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:31`
**Type:** Reference / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the fact that the row changed and that the measured range matches the merged report. It does not establish that the row now states exactly that range (Claim 37).

The merged report's Claim 13 lists 417-523 µs per call and deltas of 18-36.9 µs (`docs/reviews/code-fact-check-report-build-loop-u2a1.md:312-314`). In 91469367..d07cc89c the row
changed from `(~0.3 ms)` / `~17 µs` to `(0.3-0.5 ms, by host)` / `~17-37 µs`. This replicate measured 443.5 and 482.9 µs per
call and pair deltas of 18.6 and 20.3 µs (`$FC/perf.sh`, exit 0, 2026-10-06T16:52:02Z). The conclusion holds: the refusal costs well under the ~1 ms git call each path makes.

**Evidence:** `docs/reviews/override-log.md:325`, `$FC/logs/perf.txt`

---

## Claim 10: "Tests after 91469367: 98/98 (dev-cycle 75, build-loop-read 19, fixture-git-env 2, hermeticity 2) under a TMPDIR with no dot-prefixed part; shellcheck clean"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:37`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the four suites and shellcheck over the changed .sh/.bash files at d07cc89c (the same code as 91469367). It does not cover the "fix-drift check" sentence or shellcheck over .bats files.

`TMPDIR=/tmp/u2a1i3-XXXX timeout 900 bats test/scripts/dev-cycle.bats test/scripts/build-loop-read.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats`
(cwd the worktree, exit 0, 2026-10-06T16:47:15Z) printed 98 `ok` lines and no `not ok`. `grep -c '^@test'` gives 75, 19, 2 and 2.
`shellcheck scripts/lib/dev-cycle-read.sh scripts/build-loop.sh scripts/dev-cycle.sh test/lib/build-loop-fixtures.bash` exited 0 with no output.
`shellcheck -s bash` over the .bats files reports one SC2015 info at `test/scripts/fixture-git-env.bats:19`. The repo's
shellcheck gate covers only .sh/.bash files (`scripts/health-check.sh:34`: `shellcheck passes on all .sh/.bash files`).

**Evidence:** `$FC/logs/suites-head.txt`, `$FC/logs/shellcheck.txt`, `$FC/logs/shellcheck-bats.txt`

---

## Claim 11: "entry_why adds one subshell (0.3-0.5 ms, by host) per refused argument, and isclosed costs ~17-37 µs more per brief pair in shared_branches than the old substitution"

**Location:** `docs/reviews/override-log.md:325`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers this host's measurement, which falls inside both ranges. It does not cover the "suite delta within run-to-run noise" clause.

`$FC/perf.sh` ran twice (exit 0, 2026-10-06T16:52:02Z) and printed `entry_why in $(...): 443.5 us/call` with `new 42.1 us/pair old 23.5 us/pair`, then
`482.9 us/call` with `new 38.5 old 18.2`. The deltas are 18.6 and 20.3 µs. Timings depend on load. Medium confidence for that reason.

**Evidence:** `$FC/perf.sh`, `$FC/logs/perf.txt`

---

## Claim 12: "Other suites still write fixture commits into an inherited GIT_DIR: test/merge-safety.bats:20-24 ..., and by reading test/cc-push.bats:35-36, test/scripts/archive-working-docs.bats:97,114, test/si-clean-state.bats:40, test/cc-isolated-functions.bats:1489"

**Location:** `docs/reviews/override-log.md:327`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the cited lines (each a `git init` or fixture commit) and the absence of any unset in those five files. It does not re-run the row's merge-safety victim execution.

`test/merge-safety.bats:24` reads `git init -q -b main`, and its next line is `echo a > f && git add f && git commit -qm init`.
The other cited lines read `git init -q --bare "$T/upstream.git"`, `git init -q`, `git init -q -b main` and `git init -q --bare "$TEST_TMPDIR/remote.git"`.
`grep -l 'local-env-vars\|unset GIT_DIR'` over the five files prints nothing.

**Evidence:** `test/merge-safety.bats:18-25`, `test/cc-push.bats:34-37`, `test/scripts/archive-working-docs.bats:97,114`, `test/si-clean-state.bats:40`, `test/cc-isolated-functions.bats:1489`

---

## Claim 13: "Each test's setup now starts git once for `--local-env-vars`"

**Location:** `docs/reviews/override-log.md:328`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two setups. It does not cover the "~0.1 s per run" figure.

`test/scripts/dev-cycle.bats:13` and `test/lib/build-loop-fixtures.bash:15` each hold one `unset $(git rev-parse --local-env-vars)`,
in setup() and bl_setup().

**Evidence:** `test/scripts/dev-cycle.bats:8-16`, `test/lib/build-loop-fixtures.bash:6-20`

---

## Claim 14: "Untested: entry_why's newline folding of the word argument (no caller produces such a word; the mutant survives), check_brief's notdir and error words through the CLI, main_file's error reason through --settings"

**Location:** `docs/reviews/override-log.md:329`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the word-folding mutant. It does not establish the absence of CLI tests for every word (by reading, none feeds check_brief a notdir or error word).

The mutant `local w="$1"` (`$FC/mut.sh why-wfold`, exit 0) passes the entry_why test, so it survives. The path-folding mutant
(`why-pfold`) fails it. The one word main_entry can print with a newline would be `notdir PART`, and pathform's character set has no newline
(paraphrased — no quote available because this is inferred from pathform at `:141-149` and main_entry at `:263-279` together).

**Evidence:** `$FC/logs/mut-why-wfold.txt`, `$FC/logs/mut-why-pfold.txt`, `scripts/lib/dev-cycle-read.sh:141-149`

---

## Claim 15: "build-loop-read.bats:84 keeps an older `git replace ... && git config` chain ... Guarded by its own `git replace -d` at :85."

**Location:** `docs/reviews/override-log.md:330`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two cited lines. It does not cover whether `-d` runs when the line-85 assertion fails.

`test/scripts/build-loop-read.bats:84`: `git replace "$(git rev-parse main:docs/dev-cycle.md)" "$(git hash-object -w docs/dev-cycle.md)" && git config core.useReplaceRefs true`.
`:85`: `settings_like policy "policy review set:"; git replace -d "$(git rev-parse main:docs/dev-cycle.md)"`.

**Evidence:** `test/scripts/build-loop-read.bats:82-86`

---

## Claim 16: "U2a1: `main_entry`'s `badform` word with one shared reason mapping, `entry_why` ...; one spelling of the closed/ rule, `isclosed` ...; `check_fix` also refuses `docs/constraints.md` (... `docs/thoughts/` stays fixable in-cycle ...); U1d's carried wording and fixture rows."

**Location:** `docs/working/plan-build-loop-handoff.md:274`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the U2a1 bullet against the branch's code. It does not cover the U2a2/U2b/U2c bullets, which are future work. Q-119's option [1] (`docs/working/questions.md:386`) gives the same list and is covered too.

Each item is in the diff: `if ! pathform "$1"; then echo badform; return; fi` (`scripts/lib/dev-cycle-read.sh:267`), `entry_why()` (`:286`),
`isclosed()` (`:158`), `|| "$lp" == docs/constraints.md` (`scripts/dev-cycle.sh:181`), and `"ok docs/thoughts/t.md"` (`test/scripts/dev-cycle.bats:1029`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:158,263-296`, `scripts/dev-cycle.sh:170-185`, `docs/working/questions.md:376-392`

---

## Claim 17: "Markup that adds letters (a checked task box, a tag) can still hide a copy; only an exact line ever sets a value."

**Location:** `scripts/build-loop.sh:44-46`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the copy count in SETTINGS_AWK. It does not cover tags made only of non-letters.

`s = tolower($0); gsub(/[^a-z]/, "", s)` then `if (index(s, "buildlooppolicy") == 1) k = "policy"` (`scripts/build-loop.sh:155-156`).
`- [x] Build-loop policy:` folds to `xbuildlooppolicy`, which does not start with the key, so it hides a copy. `- [ ]` adds no letter.
This matches the header's `:18-20` (an unchecked task box is seen, a checked one is missed).

**Evidence:** `scripts/build-loop.sh:18-20,150-164`

---

## Claim 18: "A tip on a branch not ahead of main, or whose subject does not start \"handoff:\", is working."

**Location:** `scripts/build-loop.sh:65-66`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers status_line's loop word. It does not cover the absent case, which prints `absent`.

`loop=working` then `if [[ "$ahead" -gt 0 ]]; then kind="$(marker_kind "$sha")"` (`scripts/build-loop.sh:352-353`), where
`ahead` is `git rev-list --count "$MAIN_SHA..$sha"` (`scripts/lib/dev-cycle-read.sh:400`). A branch behind main also has 0 there, so "not ahead" is the precise condition.
marker_kind prints `working` when `[[ "$subj" == handoff:* ]]` fails (`scripts/build-loop.sh:286`).

**Evidence:** `scripts/build-loop.sh:280-305,322-362`, `scripts/lib/dev-cycle-read.sh:390-402`

---

## Claim 19: "it returns 1 with FILE_WHY \"absent\" or why it was not read (main_entry, a failed read, or FENCE_AWK's ...)" — main_file's refusal reason from entry_why, naming its file

**Location:** `scripts/build-loop.sh:122-140`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers main_file and its two callers in read_settings. It does not cover a badform word, which neither fixed path can produce.

`*) FILE_WHY="$(entry_why "$e" "$f")"; return 1 ;;` (`:133`). read_settings prints it as `policy review unset: $why` or `constraints unreadable: $FILE_WHY`
(`:214`, `:265`). A mutant that passes `""` instead of `"$f"` (`$FC/mut.sh mainfile-why`, exit 1) fails build-loop-read tests 3 and 8
(test 4 is the environmental copy failure).

**Evidence:** `scripts/build-loop.sh:126-141,206-266`, `$FC/logs/mut-mainfile-why.txt`

---

## Claim 20: shared_branches' `if ! { isbrief "$f" || isclosed "$f"; }` equals the old `isbrief "${f/#docs\/working\/briefs\/closed\//docs/working/briefs/}"`

**Location:** `scripts/build-loop.sh:318`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers 25 edge paths. It does not cover paths holding bytes outside pathform's set, which git grep could list but brief_fields refuses anyway.

`$FC/eq.sh` (exit 0, 2026-10-06T16:53:12Z) compared the old substitution, `isbrief || isclosed`, the old check_brief regex and the old writable
against the new code on 25 paths (closed/closed/, closedx/, Closed/, a bare name, `closed//`, a newline, `x.md.md`, a sub-directory, and others). It printed `cases=25 diffs=0`.
Dropping isclosed at `:318` (`$FC/mut.sh shared-closed`) fails build-loop-read test 16 (T28).

**Evidence:** `$FC/eq.sh`, `$FC/logs/isclosed-eq.txt`, `$FC/logs/mut-shared-closed.txt`

---

## Claim 21: "--check-fix \"ok <path>\" for ... a tracked .md file under docs/ (not ... dev-cycle.md, constraints.md, ...; compared ignoring case) or README.md"

**Location:** `scripts/dev-cycle.sh:52-58`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the constraints.md and docs/thoughts/ cases in any case. It does not re-check the other exclusions.

`|| "$lp" == docs/dev-cycle.md || "$lp" == docs/constraints.md` (`:181`), with `lp` lower-cased by `tr` at `:176`. The test
expects `skip docs/Constraints.md: in-cycle fixes edit only` and `ok docs/thoughts/t.md` and passes at HEAD. The mutant without
the constraints.md term (`$FC/mut.sh fix-constraints`, exit 1) fails it with `missing: skip docs/Constraints.md: in-cycle fixes edit only`.
SKILL.md matches: `` `docs/decisions/`, `docs/dev-cycle.md`, `docs/constraints.md`, a dot-directory or dotfile `` (`skills/dev-cycle/SKILL.md:74`).

**Evidence:** `scripts/dev-cycle.sh:170-185`, `test/scripts/dev-cycle.bats:1016-1032`, `$FC/logs/mut-fix-constraints.txt`

---

## Claim 22: "An in-cycle fix edits documentation only; the header's --check-fix paragraph is the rule, and the skip messages below repeat it. constraints.md is the user's (plan D2); docs/thoughts/ stays fixable."

**Location:** `scripts/dev-cycle.sh:167-169`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the skip messages taken together against the header's list. It does not claim that any one message carries the whole rule. No message says "compared ignoring case".

The own-files message (`:179`), the long message listing `working/, human-author/, reviews/, decisions/, dev-cycle.md, constraints.md, dot-directories or dotfiles, or instruction files) and README.md` (`:182`)
and the @-import message (`:184`) together cover each exclusion in the header paragraph. Plan D2 says `A repo with no docs/constraints.md gets no dispatch` (`docs/working/plan-build-loop-handoff.md:21`), and the U2a1 bullet says `the user writes it, D2` (`:274`).

**Evidence:** `scripts/dev-cycle.sh:52-58,167-185`, `docs/working/plan-build-loop-handoff.md:21,274`

---

## Claim 23: "A change here must pass test/scripts/dev-cycle.bats and build-loop.sh's suites (build-loop-*.bats). The caller sets -euo pipefail (check_answer and brief_fields also set pipefail for themselves)"

**Location:** `scripts/lib/dev-cycle-read.sh:10-12`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the suite names and the two pipefail settings. It does not cover the new fixture-git-env.bats, which the sentence does not name (it runs one test of each named suite).

`test/scripts/build-loop-read.bats` exists and is the only `build-loop-*.bats` (paraphrased — no quote available because this is a directory listing).
`local - out l; set -o pipefail` (`:313`) and `local - a="$1" f e r hit="" where="" n why; set -o pipefail` (`:567`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:8-31,309-313,566-567`

---

## Claim 24: "check_brief, check_branch and check_answer skip every argument unless it returned 0 with main found by name (main_entry and brief_fields answer error)."

**Location:** `scripts/lib/dev-cycle-read.sh:20-23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers main_entry's error with no main (including a refused form) and brief_fields' error. It does not re-verify check_branch's skip.

`if ! main_by_name; then echo error; return; fi` (`:266`) runs before pathform. brief_fields sets `BRIEF_ODD=error` for any
answer but `blob` (`:316`). The badform test's last line (`MAIN_SHA=""; main_entry .gitattributes` → `error`) passes at HEAD.

**Evidence:** `scripts/lib/dev-cycle-read.sh:263-279,309-316`, `$FC/logs/suites-head.txt`

---

## Claim 25: isclosed is the one spelling of the closed/ rule for writable and check_brief, equal to their old regexes

**Location:** `scripts/lib/dev-cycle-read.sh:158-162`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers writable, check_brief's gate (`:348`) and shared_branches (Claim 20) on 25 paths. It does not cover locale effects, because DIGIT and SLUG are spelled out and need no locale.

`isclosed() { [[ "$1" == docs/working/briefs/closed/* ]] && isbrief "docs/working/briefs/${1#docs/working/briefs/closed/}"; }`.
The remainder must match isbrief's `$DIGIT{4}-$DIGIT{2}-$DIGIT{2}-$SLUG\.md$`, where SLUG has no `/`. That equals the old
`^docs/working/briefs/closed/$DIGIT{4}-...-$SLUG\.md$`. `$FC/eq.sh` printed `cases=25 diffs=0` for writable and the brief gate.

**Evidence:** `scripts/lib/dev-cycle-read.sh:155-162,348`, `$FC/logs/isclosed-eq.txt`

---

## Claim 26: main_entry's word list: "blob", "absent", "notfile", "notdir PART", "badform" (a path pathform refuses: a .git* part such as .gitattributes, say) or "error" (no default branch found by name, ls-tree failed, or the tree lists a name twice ...)

**Location:** `scripts/lib/dev-cycle-read.sh:248-257`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every echo in main_entry. It does not cover git's own handling of a name listed twice beyond the dup check.

The echoes are `error` (`:266`), `badform` (`:267`), `error` on ls-tree failure (`:269`), `error` on dup (`:275`), `absent` or `notdir $p` (`:277`)
and `absent`/`blob`/`notfile` (`:279`). Nothing else is printed. The badform test prints `absent` and then `badform` for `"a\"b.md" ../x -x docs//x.md .gitattributes .github/x.yml`, and it passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:263-279`, `test/scripts/dev-cycle.bats:1356-1369`

---

## Claim 27: "Only blob reads the file, and only absent means there is none: every other word is a refusal. It runs main_by_name, then pathform, itself, before any read (so with no default branch even a refused form answers error; pathform also means ls-tree prints the name unquoted)."

**Location:** `scripts/lib/dev-cycle-read.sh:257-261`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every caller: check_brief, check_answer, brief_fields, build-loop.sh main_file, and shared_branches/status_line through check_brief and brief_fields. It does not cover callers outside this repo.

All callers were read in full. check_brief: `absent) echo "ok $a new"` / `blob) ;;` / `*) echo "skip $a: ..."` (`:356-359`). check_answer: `absent) continue` / `blob)` / `*) ... return` (`:574-577`).
main_file: `blob) ;;` / `absent) FILE_WHY=absent; return 1` / `*) ...; return 1` (`scripts/build-loop.sh:131-133`). brief_fields: `[[ "$(main_entry "$1")" != blob ]]` → error (`:316`). That is stricter, because absent is refused too, and its callers reach it only after check_brief has seen blob, or for git grep hits.
No caller lets a third word fall through to a read. With a logging `git` shim first on PATH, `main_entry .gitattributes` and `main_entry "a b"` printed `badform` twice with `git calls: 0` (`$FC/probe`, exit 0, 2026-10-06T16:51:24Z). The guard order is pinned in Claim 7.

**Evidence:** `scripts/lib/dev-cycle-read.sh:263-279,309-316,336-375,566-593`, `scripts/build-loop.sh:126-141,306-321,322-335`, `$FC/logs/probe-badform-onearg.txt`

---

## Claim 28: "$2 is the path asked about, or \"\" when the skip line already names it: notfile and badform make it the subject (\"$2 is not ...\"; no subject when \"\"), error and any other word end \"for $2\", and notdir names only the directory above it. A newline in either becomes a space, so the reason stays one line."

**Location:** `scripts/lib/dev-cycle-read.sh:281-285`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each arm with and without a path, the newline folding, and one-argument calls. It does not cover a CR, which is not folded and which no caller passes.

```bash
# scripts/lib/dev-cycle-read.sh:286-296
entry_why() {
  local w="${1//$'\n'/ }" p="${2-}"
  p="${p//$'\n'/ }"
  case "$w" in
    notdir\ *) echo "${w#notdir } is not a directory on the default branch" ;;
    notfile) echo "${p:+$p is }not a regular file on the default branch" ;;
    badform) echo "${p:+$p is }not an allowed path form" ;;
    error) echo "the tree of the default branch could not be read${p:+ for $p}" ;;
    *) echo "the default branch answered $w${p:+ for $p}" ;;
  esac
}
```
The test at `test/scripts/dev-cycle.bats:1338-1354` pins every arm with both forms and a newline path, and passes. One-argument calls
printed subjectless reasons under `set -euo pipefail` (Claim 4). Callers produce one line each: check_brief passes `""`
(`skip $a: not a regular file ...`), check_answer passes `$f` and appends `, so no entry in $f is read`, and main_file passes `$f`. The mutant passing
`"$a"` from check_brief fails test 55 (`$FC/mut.sh brief-emptyarg`). No doc, help, SKILL.md or test outside docs/reviews quotes a retired wording.
`rg` for the old phrasings (`default branch's tree could not be read`, `no entry in it is read`, `level with main`, `(a task box`) found only
`docs/working/checkpoint-build-loop-handoff.md:29`, a pre-U2a1 checkpoint note on main that describes the then-current `error` meaning.

**Evidence:** `scripts/lib/dev-cycle-read.sh:281-296,358,576`, `scripts/build-loop.sh:133`, `$FC/logs/mut-brief-emptyarg.txt`

---

## Claim 29: brief_fields' "error" covers "a path pathform refuses, any main_entry answer but blob, its error included, or the blob could not be read"

**Location:** `scripts/lib/dev-cycle-read.sh:305-308`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers brief_fields' two error paths. It does not cover the odd/unbalanced paths.

`if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]; then BRIEF_ODD=error; return 1; fi` (`:316`) and `|| { BRIEF_ODD=error; return 1; }` after the cat-file pipeline (`:326`). badform is caught by the
pathform check first and, failing that, by `!= blob`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:309-335`

---

## Claim 30: "An inherited GIT_DIR (a run from a git hook, say) would send every fixture command to that repo instead of the throwaway one; git lists every such repo-local variable itself (GIT_CONFIG_PARAMETERS too)." / dev-cycle.bats: "As bl_setup: an inherited GIT_DIR would send fixture commits to that repo."

**Location:** `test/lib/build-loop-fixtures.bash:11-15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers git 2.39.5's list and the GIT_DIR consequence. It does not cover other git versions' lists. The same applies to `test/scripts/dev-cycle.bats:11-13`.

`git rev-parse --local-env-vars` prints `... GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT GIT_OBJECT_DIRECTORY GIT_DIR GIT_WORK_TREE ... GIT_INDEX_FILE ...` (git 2.39.5).
With the unset replaced by `:`, a victim gains 7 and 5 commits (Claim 5). The later `export GIT_CONFIG_GLOBAL=...` lines are unaffected because GIT_CONFIG_GLOBAL is not in the list.

**Evidence:** `test/lib/build-loop-fixtures.bash:6-20`, `test/scripts/dev-cycle.bats:8-16`, `$FC/logs/mut-colon-victim.txt`

---

## Claim 31a: "each suite's setup unsets every variable `git rev-parse --local-env-vars` lists. One test of each suite runs here with both pointed at a victim repo."

**Location:** `test/scripts/fixture-git-env.bats:3-6`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the setup mechanism and that each test runs exactly one inner test with both variables set. It does not cover what the check detects (31b).

`run env GIT_DIR="$V/.git" GIT_INDEX_FILE="$V/.git/index" bats -f '^prints all eight sections' ...` (`:25`) and `-f 'exact policy line is set'` (`:30`).
Each filter matches one `@test` name in its suite (`grep '^@test' | grep -c` gives 1 and 1), and `victim_unchanged` requires `*"1..1"*"ok 1 "*` with status 0 (`:19`). Both pass at HEAD.

**Evidence:** `test/scripts/fixture-git-env.bats:1-32`, `test/scripts/dev-cycle.bats:40`, `test/scripts/build-loop-read.bats:13`, `$FC/logs/suites-head.txt`

---

## Claim 31b: "The dev-cycle and build-loop suites must keep their fixtures out of a repo named by an inherited GIT_DIR or GIT_INDEX_FILE ... One test of each suite runs here with both pointed at a victim repo." (read as: this suite checks both)

**Location:** `test/scripts/fixture-git-env.bats:3-6`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers what the victim check detects. It does not cover whether any real caller inherits GIT_INDEX_FILE without GIT_DIR.

The check counts only commits and refs: `[ "$(git -C "$V" rev-list --all --count)" = 1 ] && [ "$(git -C "$V" for-each-ref --format=x | wc -l)" = 1 ]` (`:20`).
A mutant that unsets only `GIT_DIR` in both setups (`$FC/mut3.sh`, exit 0, 2026-10-06T16:52:33Z) passes both tests (`ok 1`, `ok 2`).
Run directly against a victim, the same mutant left the victim at 1 commit but rewrote its index from 65 to 174 bytes, which then
lists `docs/dev-cycle.md`. The suite pins the GIT_DIR half. The GIT_INDEX_FILE half the header names is not detected. Precise
version: "keeps their fixture commits and refs out of an inherited GIT_DIR", or add an index check (for example, the victim's index is unchanged).

**Evidence:** `test/scripts/fixture-git-env.bats:17-21`, `$FC/mut3.sh`, `$FC/logs/mut-gitdironly.txt`

---

## Claim 32: "# @category fast" — the suite is picked up by scripts/run-tests.sh and by the hermeticity lint

**Location:** `test/scripts/fixture-git-env.bats:2`
**Type:** Architectural / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers discovery by both tools. It does not cover whether the suite meets the "<1s each" wording of `--fast` (the inner bats takes about 2 s).

run-tests.sh discovers with `find "$TEST_DIR" -name '*.bats' -print0` with `TEST_DIR="$REPO_ROOT/test"` (`scripts/run-tests.sh:119,213`), which is recursive, and the
tag is present. The lint's bash adapter uses `"test_globs": ["test/**/*.bats", "test/*.bats"]` (`scripts/hermeticity/adapters/bash.json:5`). A python
`-I` replay of `discover()` gave 127 files with `test/scripts/fixture-git-env.bats` among them. `hermeticity-lint --json` reports `"bash": 127` and `"findings": []`.

**Evidence:** `scripts/run-tests.sh:119,195-213`, `scripts/hermeticity-lint:892-898`, `scripts/hermeticity/adapters/bash.json:5-6`

---

## Claim 33: "A marker whose message body holds a NUL byte (one commit on top of base, with its tree)."

**Location:** `test/scripts/build-loop-read.bats:297`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the object the next line builds. It does not cover what the test then asserts.

`printf 'tree %s\nparent %s\n...' "$(git rev-parse "$base^{tree}")" "$base"` (`:298`): one parent, `base`, with base's tree.

**Evidence:** `test/scripts/build-loop-read.bats:297-300`

---

## Claim 34: "Tests: dev-cycle.bats 75, build-loop-read.bats 19, fixture-git-env.bats 2, hermeticity 2: 98/98 under a TMPDIR with no dot-prefixed part. shellcheck clean. The G1 and G2 tests each fail on their mutant."

**Location:** commit 91469367 (message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the counts, the run, shellcheck over .sh/.bash, and the G1 (`:` mutant) and G2 (prefix-guard mutant) failures. It does not cover the "about 2 s" note.

See Claims 5, 6 and 10: 98 ok at d07cc89c (same code), counts 75/19/2/2, shellcheck exit 0, `mut-unsetboth` 2 not ok, and `mut-isclosed-prefix` 1 not ok.
The message's other bullets ("New test: ... dropping isclosed's prefix guard made --check-write print ok for 2026-01-01-x.md"; "both fail with the unset lines replaced by `:`") are the same facts.

**Evidence:** `$FC/logs/suites-head.txt`, `$FC/logs/mut-unsetboth.txt`, `$FC/logs/mut-isclosed-prefix.txt`

---

## Claim 35: "entry_why's comment states each word's use of $2 (subject, \"for $2\", or unused for notdir), and reads it as ${2-} like the lib's other optional arguments"

**Location:** commit 91469367 (message body)
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the comment and the expansion form. It does not cover behaviour, because both forms are unset-safe.

The comment part holds (Claim 28). The lib's other optional arguments are read as `${2:-}`, not `${2-}`: `"${2:-file}"` (`scripts/lib/dev-cycle-read.sh:125`) and `"${2:-}" == glob` (`:142`).
entry_why's `${2-}` (`:287`) is a sibling form. It behaves the same here, because an empty `p` gives no subject either way. Precise version: "reads it unset-safe, as the lib's other optional arguments do".

**Evidence:** `scripts/lib/dev-cycle-read.sh:125,142,287`

---

## Claim 36: "Run as the final confirming pass: 0 Must Fix, 0 Incorrect (53 merged claims, 88.7% replicate agreement). It found an iteration-1 regression in wording (A7 ...), two Medium test gaps (A10, A11; executed) and wording items, fixed in 91469367"

**Location:** commit d07cc89c (message body)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers agreement with the rubric and the merged report. It does not re-verdict the merged report's claims.

The rubric gives `53 clusters: 44 Verified, 9 Mostly accurate, 0 Incorrect. Agreement 88.7% (47/53)` (`:11`). A10 and A11 are `Medium (test gap)` (`:23-24`).
No row is Must Fix (paraphrased — no quote available because this is the absence of a severity across the table at `:18-31`). A7-A13 are marked fixed in 91469367.

**Evidence:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:6-37`

---

## Claim 37: "Four declined findings get override rows (C7-C10); the C4 row's timings are corrected to the re-measured range."

**Location:** commit d07cc89c (message body)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the rows added and changed in 91469367..d07cc89c. It does not cover the Accepted-immutable row added beside them (`:326`), which the sentence does not count.

C7-C10 are the rows at `docs/reviews/override-log.md:327-330`. The C4 row now reads `(0.3-0.5 ms, by host)` and `~17-37 µs`. The re-measured range in the rubric
is `0.42-0.52 ms, 18-37 µs` (rubric `:31`). The row's range is the union with iteration 1's ~0.3 ms / ~17 µs figures, and its 0.5 ms top is below the 0.52 ms that was measured.
Precise version: "widened to cover iteration 1's and iteration 2's measurements". The difference changes no conclusion.

**Evidence:** `docs/reviews/override-log.md:325-330`, `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:31`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 31b** (`test/scripts/fixture-git-env.bats:3-6`): the header names GIT_INDEX_FILE, but the victim check counts only commits and refs. Executed, a GIT_DIR-only unset passes both tests while the victim's index is rewritten. Narrow the header, or add an index check.
- **Claim 35** (commit 91469367): "${2-} like the lib's other optional arguments". The others use `${2:-}`. History only.
- **Claim 37** (commit d07cc89c): the "corrected to the re-measured range" row reads 0.3-0.5 ms / ~17-37 µs, which is the union with iteration 1's figures and not the 0.42-0.52 ms re-measurement. History only.

### Unverifiable
(none)

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved at the replicate path named below (inside the worktree), structured per the code-fact-check skill, with `Commit: d07cc89c` as its first line.
- Answered: yes. All nine focus areas are verdicted. The behavioural claims are executed: suites at HEAD, 12 mutants, the badform no-git probe, the isclosed equivalence and the timing.
- Out of scope: review artifacts other than the rubric and the u2a1 override rows. Earlier commits' messages are settled by Accepted-immutable rows. `docs/working/checkpoint-build-loop-handoff.md:29` (on main, not in the diff) still describes the pre-badform `error` meaning.
- Escalate: Claim 31b, a test gap where the GIT_INDEX_FILE half of the new suite's stated purpose is unpinned. It is low-severity, because the real unset clears both variables.
- Decisions I made: I split the fixture-git-env header into 31a (mechanism, Verified) and 31b (coverage the header implies, Mostly accurate). I graded the C4 row's correction Mostly accurate rather than Verified because the row is not the re-measured range the commit names.
