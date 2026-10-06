Commit: d07cc89c

# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u2a1, branch feat/build-loop-u2a1)
**Scope:** branch diff `git diff main...HEAD` (main 900c47d0 .. d07cc89c): scripts/build-loop.sh, scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, skills/dev-cycle/SKILL.md, test/lib/build-loop-fixtures.bash, test/scripts/build-loop-read.bats, test/scripts/dev-cycle.bats, test/scripts/fixture-git-env.bats, docs/working/plan-build-loop-handoff.md (U2 split note), docs/working/questions.md (Q-119), the rubric's iteration-2 section, the 2026-10-06 `feat/build-loop-u2a1` rows of docs/reviews/override-log.md, and the messages of 91469367 and d07cc89c. Earlier commits' message claims (settled by Accepted-immutable rows) and other docs/reviews/*.md artifacts were skipped as instructed.
**Replication:** replicate r3 of three (iteration 3, final confirming pass)
**Checked:** 2026-10-06
**Total claims checked:** 39
**Summary:** 36 verified, 3 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Execution provenance. Every executed claim ran with `S=/home/node/.claude/jobs/814a541d/tmp/review-u2a1-i3/fc3`, `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`, and each command under `timeout`. Mutants ran only on `$S/copy`, a `git archive d07cc89c` export (restored with `git checkout -- .` after each mutant). Suite runs used `TMPDIR=$(mktemp -d /tmp/u2a1i3-XXXX)` (deleted after; a cleanup script file). Captured output is in `$S/logs/` (named per claim below). Runs took place 2026-10-06T16:47Z-16:56Z, all from cwd `/workspace/.claude/wt-build-loop-u2a1` unless the claim names `$S/copy` or `$S`. No process was left running; victim repos (`$S/fix/`) were deleted. No tracked file was modified except this report.

Hallucination-pattern log consulted (`docs/reviews/hallucination-patterns.md`). Claims 9 and 33 (per-suite test tallies in a rubric and a commit message) are in the class of the logged patterns "All 85 tests ... pass claimed in commit 59ca38f" and "mode1-equiv 33 claimed in commit 37c5ea9". Here the counts match. No claim in this run is a fabrication.

---

## Claim 1: "233 changed code lines after iteration 2's fixes"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:4`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the count with the dispatch's own formula at d07cc89c (whose code equals 91469367's: d07cc89c touches only docs/reviews/); does not establish the count under any other definition of "code line".

`git diff --numstat main...HEAD -- ':(top)' ':(top,exclude)docs/' | awk '{n+=$1+$2} END{print n}'` (cwd worktree, 2026-10-06T16:47Z, exit 0) printed `233`. `git show --stat d07cc89c` lists only `docs/reviews/` files, so the figure is the same as after 91469367.

**Evidence:** `$S/logs/numstat.txt`

---

## Claim 2: "53 clusters: 44 Verified, 9 Mostly accurate, 0 Incorrect. Agreement 88.7% (47/53)"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:11`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the tally and the percentage against the merged iteration-2 report (also stated in commit d07cc89c's body: "0 Must Fix, 0 Incorrect (53 merged claims, 88.7% replicate agreement)"); does not re-derive the per-cluster agreement or re-verdict that report's claims.

The merged report's header reads `**Total claims checked:** 53` and `**Summary:** 44 verified, 9 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable` (`docs/reviews/code-fact-check-report-build-loop-u2a1.md:10-11`), and its tail reads `Agreement rate: 47/53 = 88.7% over all clusters` (`docs/reviews/code-fact-check-report-build-loop-u2a1.md:1135`). 47/53 = 88.68%, which rounds to 88.7%. No row of the iteration-2 table carries a Must Fix severity (paraphrased — no quote available because this is the absence of a severity across rubric rows `:20-31`).

**Evidence:** `docs/reviews/code-fact-check-report-build-loop-u2a1.md:10-11`, `docs/reviews/code-fact-check-report-build-loop-u2a1.md:1135`, `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:20-31`

---

## Claim 3: "entry_why read `$2` bare; called with one argument under `set -u` it printed an empty reason"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:21`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers d48f4645's entry_why spliced into an `echo` argument, the form check_brief and check_answer use; does not cover a bare `x="$(entry_why w)"` assignment, which under `set -e` ends the caller instead of printing anything.

With d48f4645's lib saved as `$S/lib-d48.sh`, `bash -c 'set -euo pipefail; source "$1"; echo "skip a: $(entry_why notfile)"; echo after'` printed `lib-d48.sh: line 284: 2: unbound variable`, then `skip a: ` (an empty reason) and `after`. The same call as `x="$(entry_why notfile)"` printed only the unbound-variable error and ended the shell.

**Evidence:** run inline at 2026-10-06T16:52Z, cwd `$S`, exit 0; output captured in this claim's text and reproducible from `$S/lib-d48.sh`

---

## Claim 4: "The `unset` line is pinned by no test: replacing it with `:` passes every test while a victim repo gains 7 and 5 commits"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both halves as test-strategy G1 measured them ("every test" = dev-cycle.bats and build-loop-read.bats run normally; "7 and 5" = the one test of each suite that fixture-git-env.bats now runs); does not mean the full suites pass under an inherited GIT_DIR (they do not: run whole under a victim GIT_DIR with the mutant, dev-cycle.bats fails 75/75 and build-loop-read.bats 13/19, and the victims gain 81 and 72 commits).

`$S/a10b.sh` on `$S/copy` with both `unset` lines replaced by `:` printed `mutant, no GIT_DIR: exit=0 ok=94 notok=0`, then `dev-cycle single test under victim: exit=1 victim_commits=8` and `build-loop-read single test under victim: exit=0 victim_commits=6` (victims start at 1 commit: +7 and +5).

**Evidence:** `$S/logs/a10b-summary.txt`, `$S/logs/a10b-plain.txt`, `$S/logs/a10-gitdir-only.txt` (2026-10-06T16:52Z)

---

## Claim 5: "isclosed's `closed/*` prefix guard is pinned by no test: without it `--check-write 2026-01-01-x.md` prints ok (the write gate fails open)"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:24`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the mutant's effect on `--check-write` and the new test's failure on it (also commit 91469367's "dropping isclosed's prefix guard made --check-write print ok for 2026-01-01-x.md"); does not cover other brief-shaped names than the three the test uses.

Mutant M3 rewrote `isclosed() { [[ "$1" == docs/working/briefs/closed/* ]] && isbrief ...` to `isclosed() { isbrief ...` (`scripts/lib/dev-cycle-read.sh:158`). The new test "a closed brief is a closed/ path only" then failed, printing `ok 2026-01-01-x.md` where it expects `skip 2026-01-01-x.md: not one of the dev cycle's own files`.

**Evidence:** `$S/logs/mut-M3-isclosed-prefix.txt`, `$S/logs/mutants-summary.txt` (2026-10-06T16:49Z, exit 1 as expected), `test/scripts/dev-cycle.bats:1371-1380`

---

## Claim 6: "main_entry's guard order (error before badform with no default branch) ... Fixed: comment and one test line"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the comment's presence, the test line, and that the test fails when the two guards are swapped; does not cover callers, which check main_by_name themselves first.

The comment says `It runs main_by_name, then pathform, itself, before any read (so with no default branch even a refused form answers error` (`scripts/lib/dev-cycle-read.sh:258-260`), and the test ends `MAIN_SHA=""; main_entry .gitattributes` expecting `error` (`test/scripts/dev-cycle.bats:1356-1369`). Mutant M4 swapped `if ! main_by_name ...` and `if ! pathform ...` (`scripts/lib/dev-cycle-read.sh:266-267`); the badform test failed.

**Evidence:** `$S/logs/mut-M4-guard-order.txt`, `$S/logs/mutants-summary.txt`

---

## Claim 7: "Five other suites write into an inherited GIT_DIR"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:27`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers whether the list (here and in override row `docs/reviews/override-log.md:327`) names every suite that writes into an inherited GIT_DIR among this branch's files; does not re-execute the five suites named.

The list omits test/scripts/fixture-git-env.bats, added in 91469367, before this rubric section was written. Its setup does not unset the repo-local variables: it runs `git init -q -b main "$V"` and `git -C "$V" ... commit -q --allow-empty -m only` with the caller's environment (`test/scripts/fixture-git-env.bats:9-15`). Run with `GIT_DIR=$S/fix/victim2/.git` (cwd worktree, 2026-10-06T16:50Z, exit 1), both its tests failed and the victim went from 1 commit to 3. The precise version is "six other suites", or the C7 row's trigger should also cover fixture-git-env.bats's own setup.

**Evidence:** `$S/logs/fge-under-gitdir.txt`, `test/scripts/fixture-git-env.bats:9-15`, `docs/reviews/override-log.md:327`

---

## Claim 8: C4 row corrected to "0.3-0.5 ms, by host" and "~17-37 µs more per brief pair"; rubric C11 "measured 0.42-0.52 ms, 18-37 µs"

**Location:** `docs/reviews/override-log.md:325`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the order of magnitude and the Won't-Fix conclusion, re-measured on this host; does not establish exact figures, which moved with load (one run fell outside both stated ranges).

`timeout 200 env LC_ALL=C bash $S/perf.sh scripts/lib/dev-cycle-read.sh` (2026-10-06T16:51Z, exit 0) printed `entry_why subshell: 408.5 us/call` and `568.8 us/call`, and per pair `old 44.0 us new 62.0 us` and `old 49.3 us new 55.8 us` (deltas 18.0 and 6.5 µs). These are the same order the row states, and below the ~1 ms git fork each refusal path already pays. The row's figures match the merged iteration-2 report's measured range (`~0.4-0.5 ms per entry_why subshell and ~18-37 µs per pair`, `docs/reviews/code-fact-check-report-build-loop-u2a1.md:1106`), which d07cc89c's "the C4 row's timings are corrected to the re-measured range" claims.

**Evidence:** `$S/logs/perf.txt`, `docs/reviews/override-log.md:325`, `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:31`

---

## Claim 9: "Tests after 91469367: 98/98 (dev-cycle 75, build-loop-read 19, fixture-git-env 2, hermeticity 2) under a TMPDIR with no dot-prefixed part; shellcheck clean"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:37`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the counts and pass at d07cc89c (same code as 91469367) and shellcheck over the three scripts and the fixture lib (also commit 91469367's "Tests: ... 98/98 ... shellcheck clean"); does not cover shellcheck over .bats files, which the repo does not hold to it (main's dev-cycle.bats alone has 19 findings) and where the new fixture-git-env.bats draws two info-level SC2015 notes; does not cover "the fix-drift check ... found nothing".

`TMPDIR=/tmp/u2a1i3-8YRE timeout 580 bats test/scripts/dev-cycle.bats test/scripts/build-loop-read.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats` (2026-10-06T16:47Z) exited 0 with 98 `ok` lines and no `not ok`. `bats --count` gives 75, 19, 2 and 2. `shellcheck -x scripts/lib/dev-cycle-read.sh scripts/dev-cycle.sh scripts/build-loop.sh test/lib/build-loop-fixtures.bash` exited 0.

**Evidence:** `$S/logs/suite-head.txt`, `$S/logs/shellcheck.txt`

---

## Claim 10: "Each test's setup now starts git once for `--local-env-vars` (~1 ms, ~0.1 s per run of both suites)"

**Location:** `docs/reviews/override-log.md:328`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the arithmetic from the setups and the performance report's measurement; does not re-time the git call on this host.

Both setups run `unset $(git rev-parse --local-env-vars)` once per test (`test/scripts/dev-cycle.bats:13`, `test/lib/build-loop-fixtures.bash:15`). The performance report measured `1,068 µs/call` (`docs/reviews/performance-reviewer-review-2026-10-06-final-build-loop-u2a1.md:24`). 75 + 19 = 94 tests at ~1.07 ms is ~0.10 s.

**Evidence:** `test/scripts/dev-cycle.bats:13`, `test/lib/build-loop-fixtures.bash:15`, `docs/reviews/performance-reviewer-review-2026-10-06-final-build-loop-u2a1.md:24`

---

## Claim 11: "Untested: entry_why's newline folding of the word argument (no caller produces such a word; the mutant survives)"

**Location:** `docs/reviews/override-log.md:329`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the word-folding mutant against dev-cycle.bats; does not cover the row's other two untested items (check_brief's notdir/error through the CLI, main_file's error through --settings), which were not mutated here.

Mutant M11 replaced `local w="${1//$'\n'/ }"` with `local w="$1"` (`scripts/lib/dev-cycle-read.sh:287`). dev-cycle.bats then ran 75 ok, 0 not ok (exit 0). No caller passes a word that did not come from main_entry, whose words have no newline (paraphrased — no quote available because this spans main_entry's six `echo` sites at `scripts/lib/dev-cycle-read.sh:266-279`, where only `notdir $p` carries a path, and pathform refuses a newline in that path first).

**Evidence:** `$S/logs/mut-M11-word-newline.txt` (2026-10-06T16:54Z)

---

## Claim 12: "build-loop-read.bats:84 keeps an older `git replace ... && git config` chain ... Guarded by its own `git replace -d` at :85"

**Location:** `docs/reviews/override-log.md:330`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two cited lines; does not judge whether the chain needs splitting.

```bash
# test/scripts/build-loop-read.bats:84-85
    git replace "$(git rev-parse main:docs/dev-cycle.md)" "$(git hash-object -w docs/dev-cycle.md)" && git config core.useReplaceRefs true
    settings_like policy "policy review set:"; git replace -d "$(git rev-parse main:docs/dev-cycle.md)"
```

**Evidence:** `test/scripts/build-loop-read.bats:84-85`

---

## Claim 13: "U1 measured four units against a planned one, and U2 carries about twenty override rows"

**Location:** `docs/working/plan-build-loop-handoff.md:273`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the unit count and the order of the row count; does not fix which filter "carries" means.

`git log --oneline main` names branches `feat/build-loop-u1a` through `feat/build-loop-u1d` (four units). On main's override log, 26 rows have a `Revisit trigger:` naming U2 (paraphrased — no quote available because this is a count over table rows). "About twenty" is the right order.

**Evidence:** `docs/reviews/override-log.md` (main), `git log --oneline main`

---

## Claim 14: "Markup that adds letters (a checked task box, a tag) can still hide a copy"

**Location:** `scripts/build-loop.sh:44-46`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers SETTINGS_AWK's key detection; does not cover what a hidden copy does downstream.

```awk
# scripts/build-loop.sh:155-156 (excerpt ends :156; SETTINGS_AWK continues to :165 — read)
  s = tolower($0); gsub(/[^a-z]/, "", s); k = ""
  if (index(s, "buildlooppolicy") == 1) k = "policy"
```

An unchecked `- [ ]` adds no letters, so its line is still found; a checked `- [x]` adds `x`, so `xbuildlooppolicy` does not start with the key and the copy is hidden.

**Evidence:** `scripts/build-loop.sh:150-165`

---

## Claim 15: "A tip on a branch not ahead of main, or whose subject does not start "handoff:", is working"

**Location:** `scripts/build-loop.sh:65-66`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers status_line's ahead test; does not cover marker_kind's subject parsing.

```bash
# scripts/build-loop.sh:352-354 (excerpt of status_line, which runs :325-362 — read)
  loop=working
  if [[ "$ahead" -gt 0 ]]; then
    kind="$(marker_kind "$sha")"
```

Any `ahead` of 0 (level with main or behind it) keeps `working`, so "not ahead" is the exact condition.

**Evidence:** `scripts/build-loop.sh:325-362`

---

## Claim 16: main_file's refusal is entry_why's reason for every word but blob and absent, and both callers treat it as a refusal

**Location:** `scripts/build-loop.sh:133`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers main_file and its two callers in read_settings; does not cover main_file's error reason through `--settings`, which no test drives (override row 329).

```bash
# scripts/build-loop.sh:130-134 (excerpt of main_file, which runs :126-141 — read)
  case "$e" in
    blob) ;;
    absent) FILE_WHY=absent; return 1 ;;
    *) FILE_WHY="$(entry_why "$e" "$f")"; return 1 ;;
```

read_settings turns any non-absent FILE_WHY into `NEVER_LINE="never malformed: $why"` (self-merge off) (`scripts/build-loop.sh:217`), and constraints into `CONSTRAINTS_LINE="constraints unreadable: $FILE_WHY"` (`scripts/build-loop.sh:265`). Both paths pass fixed names (`docs/dev-cycle.md`, `docs/constraints.md`), so badform cannot occur there.

**Evidence:** `scripts/build-loop.sh:126-141`, `scripts/build-loop.sh:208-218`, `scripts/build-loop.sh:262-265`

---

## Claim 17: "--check-fix ... (not ... dev-cycle.md, constraints.md, ...; compared ignoring case)"

**Location:** `scripts/dev-cycle.sh:50-55`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers docs/constraints.md in any case and docs/thoughts/ staying fixable; does not cover case-insensitive filesystems beyond the lower-casing.

check_fix compares the lower-cased path: `|| "$lp" == docs/dev-cycle.md || "$lp" == docs/constraints.md ||` (`scripts/dev-cycle.sh:180`), with `lp` from `tr 'ABC...' 'abc...'` (`scripts/dev-cycle.sh:175`). The test passes `docs/Constraints.md` and `docs/thoughts/t.md` and expects `skip docs/Constraints.md: in-cycle fixes edit only` and `ok docs/thoughts/t.md` (`test/scripts/dev-cycle.bats:1016-1032`); it passed at HEAD and failed under mutant M7 (the `constraints.md` comparison removed).

**Evidence:** `$S/logs/suite-head.txt`, `$S/logs/mut-M7-constraints.txt`, `scripts/dev-cycle.sh:170-184`

---

## Claim 18: "the header's --check-fix paragraph is the rule, and the skip messages below repeat it. constraints.md is the user's (plan D2); docs/thoughts/ stays fixable."

**Location:** `scripts/dev-cycle.sh:167-169`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers agreement among the header paragraph, check_fix's three rule-bearing skip messages and SKILL.md; does not cover check_path's own skip lines (tracked, plain).

The header lists `the cycle's own files, working/, human-author/, reviews/, decisions/, dev-cycle.md, constraints.md, a dot-directory or dotfile, an instruction file, or a file an instruction file imports with @` (`scripts/dev-cycle.sh:50-54`). The skip messages say `one of the cycle's own files (use --check-write)` (`:178`), `(not working/, human-author/, reviews/, decisions/, dev-cycle.md, constraints.md, dot-directories or dotfiles, or instruction files) and README.md` (`:181`), and `an instruction file imports it with @` (`:183`). Together they repeat the header list. SKILL.md lists the same set, `docs/constraints.md` included (`skills/dev-cycle/SKILL.md:72-76`).

**Evidence:** `scripts/dev-cycle.sh:50-55`, `scripts/dev-cycle.sh:170-185`, `skills/dev-cycle/SKILL.md:72-76`

---

## Claim 19: "A change here must pass test/scripts/dev-cycle.bats and build-loop.sh's suites (build-loop-*.bats). ... check_brief, check_branch and check_answer skip every argument unless it returned 0 with main found by name (main_entry and brief_fields answer error)."

**Location:** `scripts/lib/dev-cycle-read.sh:10-23`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the suites the glob names and main_entry's answer with no main by name; does not cover the reflowed header's other sentences, which this diff only re-wrapped.

`test/scripts/build-loop-read.bats` is the one file matching `build-loop-*.bats` (paraphrased — no quote available because this is a directory listing). With `MAIN_BY_NAME=""` or `MAIN_SHA=""`, `main_entry .gitattributes` printed `error` (probe, 2026-10-06T16:48Z), and brief_fields maps any answer but blob to `BRIEF_ODD=error` (`scripts/lib/dev-cycle-read.sh:316`).

**Evidence:** `$S/logs/probe.txt`, `scripts/lib/dev-cycle-read.sh:263-279`, `scripts/lib/dev-cycle-read.sh:311-334`

---

## Claim 20: isclosed spells the closed/ rule once, equal to writable's regex, check_brief's regex and shared_branches' prefix substitution

**Location:** `scripts/lib/dev-cycle-read.sh:158`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers 22 edge cases (case, double closed/, `closedx/`, empty slug, trailing newline, a leading `x/`, `//`, non-ASCII digits, `.md.md`, `.MD`, a slash in the slug) against both old spellings; does not prove equality over all strings.

```bash
# scripts/lib/dev-cycle-read.sh:158
isclosed() { [[ "$1" == docs/working/briefs/closed/* ]] && isbrief "docs/working/briefs/${1#docs/working/briefs/closed/}"; }
```

`$S/isclosed-eq.sh` compared `isclosed` with the old regex `^docs/working/briefs/closed/$DIGIT{4}-$DIGIT{2}-$DIGIT{2}-$SLUG\.md$` (writable's and check_brief's, identical in the diff), and `isbrief X || isclosed X` with the old `isbrief "${f/#docs\/working\/briefs\/closed\//docs/working/briefs/}"`. It printed `cases=22 diffs=0` (exit 0, 2026-10-06T16:48Z).

**Evidence:** `$S/logs/isclosed-eq.txt`, `scripts/build-loop.sh:318`, `scripts/lib/dev-cycle-read.sh:159-162`, `scripts/lib/dev-cycle-read.sh:348`

---

## Claim 21: main_entry prints "blob", "absent", "notfile", "notdir PART", "badform" (a path pathform refuses) or "error" (no default branch found by name, ls-tree failed, or a name listed twice); badform needs no git call

**Location:** `scripts/lib/dev-cycle-read.sh:247-256`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the word set and badform's zero git calls on seven refused forms; does not cover ls-tree failure, exercised by existing tests.

```bash
# scripts/lib/dev-cycle-read.sh:266-267 (excerpt of main_entry, which runs :263-279 — read)
  if ! main_by_name; then echo error; return; fi
  if ! pathform "$1"; then echo badform; return; fi
```

With a git shim counting calls on PATH, `.gitattributes`, `.github/x.yml`, `a"b`, `../x`, `-x`, `docs//x` and `.GIT/x` each printed `badform` with `git calls: 0`; the control `docs/f.md` printed `blob` with 1 call. The remaining arms print `absent`, `notdir $p`, `error` (dup) and `blob`/`notfile` (`scripts/lib/dev-cycle-read.sh:268-278`).

**Evidence:** `$S/logs/probe.txt` (2026-10-06T16:48Z, exit 0), `scripts/lib/dev-cycle-read.sh:263-279`

---

## Claim 22: "Only blob reads the file, and only absent means there is none: every other word is a refusal."

**Location:** `scripts/lib/dev-cycle-read.sh:256-257`
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every caller of main_entry (check_brief, check_answer, brief_fields, build-loop.sh main_file, and shared_branches and status_line through brief_fields and check_brief); does not cover a future caller such as U2a2's floor.

check_brief: `absent) echo "ok $a new"; return ;; blob) ;; *) echo "skip $a: $(entry_why "$e" "")"; return ;;` (`scripts/lib/dev-cycle-read.sh:355-359`). check_answer: `absent) continue ;; blob) ;; *) echo "skip $a: ... so no entry in $f is read"; return ;;` (`:573-577`). brief_fields: `[[ "$(main_entry "$1")" != blob ]]` → `BRIEF_ODD=error; return 1` (`:316`), so absent is a refusal there too (it needs a file). main_file: Claim 16. shared_branches skips any brief brief_fields refuses (`scripts/build-loop.sh:318`), and status_line echoes any non-`ok` check_brief line (`scripts/build-loop.sh:328-329`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:311-334`, `scripts/lib/dev-cycle-read.sh:343-376`, `scripts/lib/dev-cycle-read.sh:567-591`, `scripts/build-loop.sh:126-141`, `scripts/build-loop.sh:306-332`

---

## Claim 23: "It runs main_by_name, then pathform, itself, before any read (so with no default branch even a refused form answers error ...)"

**Location:** `scripts/lib/dev-cycle-read.sh:257-260`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the order and its observable result; does not cover pathform's "ls-tree prints the name unquoted" clause, unchanged by this diff.

The guards are in that order (`scripts/lib/dev-cycle-read.sh:266-267`, quoted in Claim 21). With `MAIN_BY_NAME=""` and with `MAIN_SHA=""`, `main_entry .gitattributes` printed `error` both times. Mutant M4 (guards swapped) failed the badform test.

**Evidence:** `$S/logs/probe.txt`, `$S/logs/mut-M4-guard-order.txt`

---

## Claim 24a: "$2 is the path asked about, or "" when the skip line already names it: notfile and badform make it the subject ("$2 is not ..."; no subject when ""), ... and notdir names only the directory above it."

**Location:** `scripts/lib/dev-cycle-read.sh:281-284`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the notfile, badform and notdir arms with and without a path; does not cover the error/default arms' "" case (Claim 24b).

```bash
# scripts/lib/dev-cycle-read.sh:286-296 (all of entry_why)
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

The entry_why test pins all ten outputs (`test/scripts/dev-cycle.bats:1338-1354`) and passed at HEAD; mutant M9 (notfile's subject made unconditional) failed it.

**Evidence:** `$S/logs/suite-head.txt`, `$S/logs/mut-M9-entry_why-subject.txt`

---

## Claim 24b: "error and any other word end "for $2""

**Location:** `scripts/lib/dev-cycle-read.sh:283-284`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the error and default arms; does not affect any caller's output (check_brief's "" error line is the pre-branch wording).

With `$2` empty these arms drop the "for" clause too: `${p:+ for $p}` (`scripts/lib/dev-cycle-read.sh:293-294`), so `entry_why error ""` prints `the tree of the default branch could not be read` (`test/scripts/dev-cycle.bats:1350`). The comment states the "" case only for notfile and badform ("no subject when \"\""). A precise version: "error and any other word end "for $2" (nothing when \"\")".

**Evidence:** `scripts/lib/dev-cycle-read.sh:281-296`, `test/scripts/dev-cycle.bats:1349-1350`

---

## Claim 25: "A newline in either becomes a space, so the reason stays one line."

**Location:** `scripts/lib/dev-cycle-read.sh:285`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both arguments' folding by code and the path's folding by test; does not establish that the word's folding is pinned by a test (it is not: Claim 11).

Both expansions fold: `local w="${1//$'\n'/ }"` and `p="${p//$'\n'/ }"` (`scripts/lib/dev-cycle-read.sh:287-288`). The test's `entry_why badform "a\nok b"` expects `a ok b is not an allowed path form` (`test/scripts/dev-cycle.bats:1340-1354`); mutant M6 (path folding removed) failed it.

**Evidence:** `$S/logs/mut-M6-path-newline.txt`, `$S/logs/mut-M11-word-newline.txt`

---

## Claim 26: entry_why reads `${2-}`, so a one-argument call works under `set -u`

**Location:** `scripts/lib/dev-cycle-read.sh:287`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers one-argument calls for all five word kinds under `set -euo pipefail`; does not cover callers, which all pass two arguments.

Under `set -euo pipefail`, `entry_why notfile` / `badform` / `error` / `"notdir docs"` / `odd` printed `[not a regular file on the default branch]`, `[not an allowed path form]`, `[the tree of the default branch could not be read]`, `[docs is not a directory on the default branch]`, `[the default branch answered odd]`, with no unbound-variable error.

**Evidence:** `$S/logs/probe.txt` (2026-10-06T16:48Z, exit 0)

---

## Claim 27: check_brief's wording is unchanged by entry_why "" and check_answer ends every main_entry refusal "so no entry in $f is read"

**Location:** `scripts/lib/dev-cycle-read.sh:358`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers check_brief's notdir/notfile/error lines against main's text and check_answer's single refusal arm at `:576`; does not cover check_brief's badform arm, which its own pathform check (`:347`) makes unreachable.

check_brief now prints `skip $a: $(entry_why "$e" "")` (`:358`). With "", the notdir, notfile and error arms give `X is not a directory on the default branch`, `not a regular file on the default branch` and `the tree of the default branch could not be read`, which are main's three lines word for word (paraphrased — no quote available because main's lines are the removed `-` lines of the diff hunk at `scripts/lib/dev-cycle-read.sh:337-345`). check_answer's one arm is `*) echo "skip $a: $(entry_why "$e" "$f"), so no entry in $f is read"; return ;;` (`:576`). The tests at `test/scripts/dev-cycle.bats:1198`, `:1203`, `:1226-1228` and `:1327` pin the exact lines; mutant M8 (arm ending changed back to "so $f is not read") failed test 9.

**Evidence:** `$S/logs/mut-M8-answer-ending.txt`, `scripts/lib/dev-cycle-read.sh:343-376`, `scripts/lib/dev-cycle-read.sh:567-591`

---

## Claim 28: No doc, help text, SKILL.md or test still quotes a main_entry refusal wording no longer printed

**Location:** `scripts/lib/dev-cycle-read.sh:281`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers scripts/, skills/, test/, docs/dev-cycle.md and the plan; does not cover docs/reviews/ artifacts, which quote old wordings as history.

`rg` for `default branch's tree could not be read`, `no entry in it is read`, `questions.md is not read"` and `so $f is not read` outside docs/reviews/ and archive/ found no hit in a refusal context (paraphrased — no quote available because the claim is an absence of matches). The remaining "is not read" hits (`test/scripts/dev-cycle.bats:196,237,267`) are the digest's own messages, not check_answer's.

**Evidence:** `scripts/build-loop.sh:136-139`, `test/scripts/dev-cycle.bats:196`, `test/scripts/dev-cycle.bats:1327`

---

## Claim 29: "An inherited GIT_DIR (a run from a git hook, say) would send every fixture command to that repo ...; git lists every such repo-local variable itself (GIT_CONFIG_PARAMETERS too)."

**Location:** `test/lib/build-loop-fixtures.bash:11-15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers git 2.39.5's list and the effect of removing the unset (Claim 4); does not cover other git versions' lists.

`git rev-parse --local-env-vars` printed `GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_CONFIG GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT GIT_OBJECT_DIRECTORY GIT_DIR GIT_WORK_TREE GIT_IMPLICIT_WORK_TREE GIT_GRAFT_FILE GIT_INDEX_FILE GIT_NO_REPLACE_OBJECTS GIT_REPLACE_REF_BASE GIT_PREFIX GIT_INTERNAL_SUPER_PREFIX GIT_SHALLOW_FILE GIT_COMMON_DIR` (cwd `$S`, outside a repo, exit 0). The same unset is at `test/scripts/dev-cycle.bats:13`, which makes the fixture file's header "the same hermetic git environment as test/scripts/dev-cycle.bats" (`:3`) true.

**Evidence:** `test/lib/build-loop-fixtures.bash:1-24`, `test/scripts/dev-cycle.bats:8-22`, `$S/logs/a10b-summary.txt`

---

## Claim 30: "A marker whose message body holds a NUL byte (one commit on top of base, with its tree)."

**Location:** `test/scripts/build-loop-read.bats:264`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the fixture's tree and parent; does not cover the assertion that follows.

```bash
# test/scripts/build-loop-read.bats:265-266 (excerpt; the test continues past :268 — read)
    o="$(printf 'tree %s\nparent %s\n...handoff: ready\n\n\0x\n' "$(git rev-parse "$base^{tree}")" "$base" \
        | git hash-object -t commit --literally -w --stdin)"
```

Tree is base's tree and the one parent is base.

**Evidence:** `test/scripts/build-loop-read.bats:264-270`

---

## Claim 31: Each new or changed dev-cycle.bats test fails when the behaviour it pins is reverted

**Location:** `test/scripts/dev-cycle.bats:1338`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers mutants M3-M10 (prefix guard, guard order, badform→error, path folding, constraints.md, check_answer ending, notfile subject, writable without isclosed); does not cover the word-folding mutant M11, which survives (Claim 11, an accepted Won't-Fix).

`$S/mutants.sh` (cwd `$S/copy`, 2026-10-06T16:49Z) printed for each: M3, M4, M5, M6, M7, M9 `0 ok, 1 not ok`; M8 `10 ok, 1 not ok` (test 9, `--check-answer refuses a questions file or directory that is not plain on main`); M10 `74 ok, 1 not ok` (test 40, closed briefs). M1/M2: Claim 32.

**Evidence:** `$S/logs/mutants-summary.txt`, `$S/logs/mut-M*.txt`

---

## Claim 32: "One test of each suite runs here with both pointed at a victim repo."; both fail when the unset lines are replaced by `:`

**Location:** `test/scripts/fixture-git-env.bats:3-6`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the filters, the pass at HEAD and both mutants (also commit 91469367's "both fail with the unset lines replaced by `:`"); does not cover the suite's own hermeticity (Claim 7).

`bats --count -f '^prints all eight sections' test/scripts/dev-cycle.bats` and `bats --count -f 'exact policy line is set' test/scripts/build-loop-read.bats` each printed `1`; the only matching tests are `test/scripts/dev-cycle.bats:40` and `test/scripts/build-loop-read.bats:13`. Both tests passed at HEAD. Mutant M1 (dev-cycle.bats unset → `:`) failed test 1, whose inner run failed (`not ok 1 prints all eight sections`, status check at `:19`); mutant M2 (bl_setup unset → `:`) failed test 2 on the victim check, with the victim's log showing the fixture's `cr`, `settings`, `initial` commits.

**Evidence:** `$S/logs/mut-M1-unset-devcycle.txt`, `$S/logs/mut-M2-unset-bl.txt`, `$S/logs/suite-head.txt`

---

## Claim 33: test/scripts/fixture-git-env.bats is picked up by the runner as `@category fast` and scanned by the hermeticity lint

**Location:** `test/scripts/fixture-git-env.bats:2`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers run-tests.sh `--fast`/`--slow` selection and the lint's file count; does not cover a full `run-tests.sh --all` run.

In `$S/copy`, `scripts/run-tests.sh --fast test/scripts/fixture-git-env.bats` (2026-10-06T16:55Z) exited 0 with `ok 1` and `ok 2`; `--slow` on the same file printed `No test files matched category: slow`. run-tests.sh discovers files with `find "$TEST_DIR" -name '*.bats'` (`scripts/run-tests.sh:213`). `scripts/hermeticity-lint --root . --json` reported `"bash": 127`, and `rg --files test -g '*.bats' | wc -l` is 127, so every suite, this one included, was scanned, with `"findings": []`.

**Evidence:** `$S/logs/run-tests-fge.txt`, `$S/logs/run-tests-fge-slow.txt`, `scripts/run-tests.sh:195-213`

---

## Claim 34: "entry_why's comment states each word's use of $2 ..., and reads it as ${2-} like the lib's other optional arguments"

**Location:** commit 91469367 (message body)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the "like the lib's other optional arguments" comparison; does not affect behaviour (both forms are set -u safe and default to "").

The lib's other optional positional arguments read `${2:-}` and `${2:-file}`: `[[ "${2:-}" == glob ]]` (`scripts/lib/dev-cycle-read.sh:142`) and `blocker "$1" "${2:-file}"` (`scripts/lib/dev-cycle-read.sh:125`). entry_why's `p="${2-}"` (`:287`) is the only `${N-}` positional read. The `-` form matches the lib's associative-array reads (`${m[$1]-}`, `${BRIEF[status]-}`), not its optional arguments. Commit message: immutable history.

**Evidence:** `scripts/lib/dev-cycle-read.sh:125`, `scripts/lib/dev-cycle-read.sh:142`, `scripts/lib/dev-cycle-read.sh:287`

---

## Claim 35: "the G1 suite runs bats inside bats (about 2 s)"

**Location:** commit 91469367 (message body, Notes)
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the order of magnitude; does not fix the host-dependent figure.

`time timeout 120 bats test/scripts/fixture-git-env.bats` gave `real 0m0.964s` here (2026-10-06T16:55Z, exit 0): about a second, under the stated ~2 s and the same order.

**Evidence:** run inline, cwd worktree, output in this claim's text

---

## Claim 36: "Four declined findings get override rows (C7-C10); the C4 row's timings are corrected to the re-measured range."

**Location:** commit d07cc89c (message body)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the rows' existence and decisions; does not re-verdict each row (Claims 7, 8, 10, 11, 12).

Rows `docs/reviews/override-log.md:327-330` are C7 (Defer), C8 (Won't-Fix), C9 (Won't-Fix) and C10 (Defer), matching the rubric's statuses (`docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:27-30`). The C4 row now reads `0.3-0.5 ms, by host` and `~17-37 µs` with `figures re-measured in iteration 2` (`:325`).

**Evidence:** `docs/reviews/override-log.md:325-330`, `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:27-31`

---

## Claim 37: "The merge kept claims 21b and 41a Verified where a replicate's compound verdict blamed only the sibling part (decision 033), as the merged report records."

**Location:** commit d07cc89c (message body, Notes)
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the merged report's record of it; does not re-verdict claims 21b and 41a.

The merged report says `Claims 21b and 41a disagree only through a sibling's compound verdict` (`docs/reviews/code-fact-check-report-build-loop-u2a1.md:1135`).

**Evidence:** `docs/reviews/code-fact-check-report-build-loop-u2a1.md:1135`

---

## Claim 38: "found an iteration-1 regression in wording (A7: entry_why's path argument), two Medium test gaps (A10, A11; executed)"

**Location:** commit d07cc89c (message body)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the commit's summary against the rubric rows; the gaps themselves are Claims 4 and 5.

The rubric rows read `| A7 | After A4, entry_why's `$2` plays a different role per word` (Minor), `| A10 | ... | Medium (test gap) |` and `| A11 | ... | Medium (test gap; executed) |` (`docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:20,23,24`).

**Evidence:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:20-24`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 7** (`docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:27`, also `docs/reviews/override-log.md:327`): "five other suites" leaves out the new test/scripts/fixture-git-env.bats, whose own setup writes 2 commits into an inherited GIT_DIR (executed: victim 1 to 3). Name it, or extend C7's trigger to it.
- **Claim 24b** (`scripts/lib/dev-cycle-read.sh:283-284`): error and the default arm also drop "for" when `$2` is ""; the comment states the "" case only for notfile and badform.
- **Claim 34** (commit 91469367): `${2-}` is not "like the lib's other optional arguments", which read `${2:-}`/`${2:-file}`; the behaviour is the same. Immutable history.

### Unverifiable
(none)

## Escalations
- E1 (informational, for the orchestrator): test/scripts/fixture-git-env.bats, the suite that pins the setups' `unset`, does not unset the repo-local variables in its own setup (`:9-15`). Run under an inherited GIT_DIR it fails both tests and commits into that repo (Claim 7). This is the C7 class (Defer), not a regression of this unit's code; adding the same `unset` line to its setup would close it.

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved at the replicate path named below (inside the worktree), structured per the code-fact-check skill, with `Commit: d07cc89c` as its first line.
- Answered: yes. All nine focus areas are verdicted, and the behavioural ones were executed: suites (98/98), the numstat count, the isclosed equivalence (22 cases), badform's git-call count, the guard order, one-argument entry_why, 11 mutants, A10's victim counts, the runner and lint pickup, and the new suite under an inherited GIT_DIR.
- Out of scope: earlier commits' message claims (Accepted-immutable rows); docs/reviews/*.md artifacts other than the rubric's iteration-2 section and the new override rows; U2a2/U2b/U2c plan bullets.
- Escalate: E1 (informational). Nothing blocking; 0 Incorrect.
- Decisions I made: graded the C4 and "about 2 s" timings Verified on order of magnitude, though single runs fell outside the stated ranges, because both are marked approximate and the conclusions hold. Read the rubric's A10 "passes every test" as test-strategy G1 measured it (the normal suite run) and stated the residue in its Scope.
