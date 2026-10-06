Commit: d48f4645

# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u2a1, branch feat/build-loop-u2a1)
**Scope:** branch diff `git diff main...HEAD` (main 900c47d0 .. d48f4645, commits 6f624cdf, 706e0499, d48f4645): scripts/lib/dev-cycle-read.sh, scripts/build-loop.sh, scripts/dev-cycle.sh, skills/dev-cycle/SKILL.md, test/lib/build-loop-fixtures.bash, test/scripts/build-loop-read.bats, test/scripts/dev-cycle.bats, docs/working/plan-build-loop-handoff.md, docs/working/questions.md (Q-119), the rubric and the five new override-log rows, and the three commit messages. Other docs/reviews/*.md artifacts were skipped as instructed.
**Replication:** replicate r3 of k=3 (final confirming pass)
**Checked:** 2026-10-06
**Total claims checked:** 37 (Claims 1-35, 36a, 36b)
**Summary:** 32 verified, 5 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, 5 patterns). The relevant one is the per-suite test-count pattern ("All 85 tests ... but the suites hold 97", "mode1-equiv 33 ... holds 25"). Every test count in scope was re-counted by running the suite (Claims 7, 34, 36). None of them matches the pattern.

## Execution provenance

All runs went against a `git archive` export of HEAD d48f4645 at `S=/home/node/.claude/jobs/814a541d/tmp/review-u2a1-final/fc3/wt` (no repo files were touched). Raw output is in `$S/../logs/` (absolute: `/home/node/.claude/jobs/814a541d/tmp/review-u2a1-final/fc3/logs/`). Mutants ran on separate copies under `fc3/mut-*`, which were removed after each run. Git fixtures used `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`. Every process ran under `timeout`.

| ID | Command (cwd `fc3/wt` unless noted) | Exit | UTC time | Log |
|---|---|---|---|---|
| E1 | `TMPDIR=$(mktemp -d /tmp/u2a1fc-XXXX) bats test/scripts/dev-cycle.bats` (temp dir deleted after) | 0, 74/74 ok | 16:18:33 | logs/dev-cycle.log |
| E2 | `bats test/scripts/build-loop-read.bats` | 0, 19/19 ok | 16:18:57 | logs/build-loop-read.log |
| E3 | `bats test/fixture-hermeticity.bats`; `shellcheck scripts/build-loop.sh scripts/dev-cycle.sh scripts/lib/dev-cycle-read.sh test/lib/build-loop-fixtures.bash` | 0 (2/2 ok); 0 | ~16:19 | logs/fixture-hermeticity.log |
| E4 | `git diff --numstat main...HEAD -- ':(top)' ':(top,exclude)docs/' \| awk '{n+=$1+$2} END{print n}'` (cwd the worktree), then the same for `main 6f624cdf` | 0: 165; 128 | ~16:19 | (inline: 165 / 128) |
| E5 | victim repo (`main`, 1 commit) and then `GIT_DIR=$victim/.git bats test/scripts/dev-cycle.bats test/scripts/build-loop-read.bats` | 0, 93 ok; victim still has 1 commit and only refs/heads/main | 16:19:56 | logs/victim-head.log |
| E6 | the same with both `unset $(git rev-parse --local-env-vars)` lines deleted (copy `mut1`) | 1; victim grows to 81, then 153 commits, with branches f1-f3, loop, lower, trunk | ~16:20 | logs/victim-mut-dc.log, logs/victim-mut-bl.log |
| E7 | victim (`trunk`, 1 commit), then `GIT_DIR=… bats -f 'check-fix refuses files an instruction file imports' test/scripts/dev-cycle.bats` on `mut1` and on `wt` | mut1: 1, victim 3 commits plus `f1`; wt: 0, victim 1 commit | ~16:21 | logs/victim-filter-mut1.log, logs/victim-filter-wt.log |
| E8 | `fc3/probe1.sh` (isclosed against the three old spellings, 23 paths, and main_entry's words) | 0 | 16:21:21 | logs/probe1.log |
| E9 | `fc3/probe2.sh` (counts git calls per main_entry word through a `git` function shim) | 0 | ~16:21 | logs/probe2.log |
| E10 | `fc3/probe3.sh` (build-loop.sh --settings with docs/constraints.md stored as a symlink, under a symlinked dir, and in a tree that lists it twice) | 0 | ~16:21 | logs/probe3.log |
| E11 | `fc3/mutants.sh` and `fc3/mutants2.sh` (12 mutants, each run on its own copy with `bats -f`) | see Claims 26, 32, 34, 35 | 16:22:31 | logs/mut-*.log |
| E12 | `bash -c 'source lib; entry_why …'` with a newline in the word, and with empty and non-empty paths | 0 | ~16:23 | logs/entry_why-direct.log |
| E13 | `fc3/probe4.sh` (checked and unchecked task-box copies in --settings; timings for the entry_why subshell and for isclosed) | 0 | ~16:25 | logs/probe4.log |
| E14 | `bash scripts/questions.sh check` | 0 | ~16:24 | logs/questions-check.log |
| E15 | `GIT_DIR=$victim GIT_CONFIG_COUNT=1 git rev-parse --local-env-vars`, then the E7 filtered run with that environment | 0; 0, victim 1 commit | ~16:25 | logs/victim-cc.log |

---

## Claim 1: "24 claims: 20 Verified, 3 Mostly accurate, 1 Unverifiable, 0 Incorrect" / "1 Medium, 1 Low, 2 Informational" / "2 Informational" / "3 Minor, 1 Informational" / "0 Structural, 0 Coupling, 1 Minor, 3 Informational"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:11-15`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the per-report tallies against each report's verdict and severity lines. It does not establish that those reports' own findings are correct.
**Legibility-target:** for-orchestrator-synthesis

A count of `**Verdict:**` lines in `code-fact-check-report-build-loop-u2a1.md` gives `20 Verified`, `3 Mostly accurate` and `1 Unverifiable`. The security summary table rows are `| 1 | … | Medium |`, `| 2 | … | Low |`, `| 3 | … | Informational |` and `| 4 | … | Informational |` (`security-reviewer-review-2026-10-06-build-loop-u2a1.md:188-191`). Performance has two `Informational` rows (`performance-reviewer-…:102-103`). The api-consistency severities read `Minor, Minor, Informational, Minor`. The architecture summary table has `| 1 | … | Minor |` and then three `Informational` rows (`architecture-review-…:141-144`).

**Evidence:** `docs/reviews/code-fact-check-report-build-loop-u2a1.md`, `docs/reviews/security-reviewer-review-2026-10-06-build-loop-u2a1.md:184-191`, `docs/reviews/performance-reviewer-review-2026-10-06-build-loop-u2a1.md:98-103`, `docs/reviews/architecture-review-review-2026-10-06-build-loop-u2a1.md:137-144`

---

## Claim 2: "rows 228, 292, 306, 314, 317-320 are Defer rows whose triggers this unit meets, and the diff addresses each"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:17`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each listed row against the HEAD code: 228, 292, 306, 314, 317, 318 and 320 are fully addressed, and 319 is addressed except for its short-line residue. It does not check rows 202, 203, 233, 284, 298 or 312, which stay with later units.
**Legibility-target:** for-author

The following rows are addressed in full:
- Row 228 (shared mapping): `entry_why` (`scripts/lib/dev-cycle-read.sh:283-292`) is called by all three former case blocks (`:354`, `:573-574`, `scripts/build-loop.sh:133`).
- Row 292: `isclosed` at `:158`.
- Row 306: `if ! pathform "$1"; then echo badform; return; fi` (`:266`).
- Row 314: `unset $(git rev-parse --local-env-vars)` (`test/lib/build-loop-fixtures.bash:15`).
- Row 317: the chains are split (Claim 32).
- Row 318: the T7 comment (Claim 31).
- Row 320: the `x` → `absent` control (Claim 35).

Row 319 named "the lib header's 'once that second caller lands' … with short lines". The phrase is gone, but the header still has a short line at `:25` (52 chars: `# scrub, read it as \`out="$(check_brief ...)"\` under`), and the reflow added a 96-char line at `:16` (`# ROOT_REAL is set, is the current directory and is a repository's top level; while ROOT_REAL is`). Line lengths were measured with awk over the header (paraphrased, no quote available because the claim is about line lengths, not text). Precise version: "…addresses each, except row 319's short-line wrap at lib :25".

**Evidence:** `scripts/lib/dev-cycle-read.sh:12-27`, `docs/reviews/override-log.md:306-320`

---

## Claim 3: "A1 … executed, the suite wrote 2 commits and branch f1 into a victim repo … ✅ Fixed: both setups run `unset $(git rev-parse --local-env-vars)`; checked, the victim keeps 1 commit"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:21`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an inherited `GIT_DIR` (and the other variables that `--local-env-vars` lists) for the single test the security reviewer ran and for both whole suites. It does not establish protection from non-local variables such as `GIT_CEILING_DIRECTORIES` or `GIT_CONFIG_GLOBAL` (which setup overrides anyway).
**Legibility-target:** for-orchestrator-synthesis

With the unset lines removed (E7, mut1), the filtered test left the victim at 3 commits plus `refs/heads/f1`, which is "2 commits and branch f1" exactly. At HEAD the same run left 1 commit and only `trunk`. The whole-suite runs at HEAD (E5) left the victim at 1 commit, while the mutant (E6) wrote 80 and then 152 commits into it. Both setups now carry the line: `unset $(git rev-parse --local-env-vars)` (`test/scripts/dev-cycle.bats:13`, `test/lib/build-loop-fixtures.bash:15`).

**Evidence:** `test/scripts/dev-cycle.bats:8-23`, `test/lib/build-loop-fixtures.bash:7-23`, logs/victim-filter-mut1.log, logs/victim-filter-wt.log, logs/victim-head.log, logs/victim-mut-dc.log

---

## Claim 4: "A2 | `entry_why` echoed the raw path … ✅ Fixed: entry_why turns newlines into spaces; new test"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:22`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the newline translation of both arguments and the new test's pinning of a newline in the path. It does not establish that the test pins a newline in the word: that mutant survives (see Claim 34). The word cannot carry a newline today, because only pathform-clean paths reach `notdir PART`.
**Legibility-target:** for-orchestrator-synthesis

The code: `local w="${1//$'\n'/ }" p="${2//$'\n'/ }"` (`scripts/lib/dev-cycle-read.sh:284`). Run directly (E12), `entry_why $'notdir a\nok b' x` printed `a ok b is not a directory on the default branch` on one line. The test's `entry_why badform "a\nok b"` expects `a ok b is not an allowed path form` (`test/scripts/dev-cycle.bats:1341-1353`), and the mutant that reverts both translations fails it (logs/mut-nl-word.log).

**Evidence:** `scripts/lib/dev-cycle-read.sh:280-292`, `test/scripts/dev-cycle.bats:1338-1354`, logs/entry_why-direct.log, logs/mut-nl-word.log

---

## Claim 5: "A3 … ✅ Fixed: the error arm names the path when given" / "A4 … check_brief passes ""; check_answer says 'so no entry in it is read' (in `$f` after notdir)"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:23-24`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the skip line each caller prints for notdir, notfile and error. Badform is unreachable from all three callers today (check_brief runs pathform first, and the other two pass fixed paths), so it was checked only through entry_why directly.
**Legibility-target:** for-orchestrator-synthesis

The code:
- `error) echo "the tree of the default branch could not be read${p:+ for $p}" ;;` (`scripts/lib/dev-cycle-read.sh:289`).
- check_brief: `*) echo "skip $a: $(entry_why "$e" "")"; return ;;` (`:354`).
- check_answer: `notdir\ *) echo "skip $a: $(entry_why "$e" "$f"), so no entry in $f is read"` / `*) echo "skip $a: $(entry_why "$e" "$f"), so no entry in it is read"` (`:573-574`).

When executed, E10 printed `constraints unreadable: the tree of the default branch could not be read for docs/constraints.md`, `… docs/constraints.md is not a regular file on the default branch` and `… docs is not a directory on the default branch`. E1's tests at `dev-cycle.bats:1198`, `:1203`, `:1327` and `:1042` assert the check_answer and check_brief lines and pass.

**Evidence:** `scripts/lib/dev-cycle-read.sh:339-355`, `scripts/lib/dev-cycle-read.sh:563-575`, `scripts/build-loop.sh:126-140`, logs/probe3.log, logs/dev-cycle.log

---

## Claim 6: "A6 | Row 319 residue: short lines in the lib header (`:13`, `:25`) | … | ✅ Fixed: reflowed" (also d48f4645: "A6: the lib header's short lines reflowed (row 319's residue)")

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:26`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the header's line lengths at 6f624cdf and at d48f4645. It does not assess whether the wrap matters.
**Legibility-target:** for-author

At 6f624cdf, `:13` was `# pipefail for themselves),` (27 chars) and `:25` was `# with one printed line per argument that` (41 chars). At HEAD, the first is reflowed into `:12-16`, but `:25` is still short at `# scrub, read it as \`out="$(check_brief ...)"\` under` (52 chars), and `:16` now runs to 96 chars (`…is a repository's top level; while ROOT_REAL is`). Lengths were measured with awk (paraphrased, no quote available because the property is line length). Precise version: ":13 reflowed; :25 still short, and :16 now overlong".

**Evidence:** `scripts/lib/dev-cycle-read.sh:12-27`, `git show 6f624cdf:scripts/lib/dev-cycle-read.sh` lines 12-27

---

## Claim 7: "Tests after the fixes: 95/95 (dev-cycle 74 …, build-loop-read 19, hermeticity 2); shellcheck clean. Size after the fixes: 165 changed code lines." (also C6: "Resolved: 95/95 with test 25 run under a TMPDIR with no dot-prefixed part")

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:38`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three suites at d48f4645 (with test 25 run under `/tmp/u2a1fc-*`), shellcheck on the four changed shell files, and the numstat count. It does not cover other suites in the repo.
**Legibility-target:** for-orchestrator-synthesis

E1 gives `ok 74 main_entry answers badform …` and no `not ok`. E2 gives 19 `ok`, and E3 gives `1..2` with both `ok`. Shellcheck exits 0. E4 prints `165`. This does not match the hallucination log's test-count pattern.

**Evidence:** logs/dev-cycle.log, logs/build-loop-read.log, logs/fixture-hermeticity.log, E4 output

---

## Claim 8: "Commit 6f624cdf's Notes say 'the lib's check_fix keeps reading the IMPORTED cache'; check_fix is in scripts/dev-cycle.sh and reads the lib's cache"

**Location:** `docs/reviews/override-log.md:321`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where check_fix lives and what it reads. It does not cover U2a2's isimported, which does not exist yet.
**Legibility-target:** for-orchestrator-synthesis

`check_fix() {` is at `scripts/dev-cycle.sh:170`, and it reads `elif [[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]]` (`:182`). The cache is declared in the lib: `IMPORTED=$'\n'; IMPORTED_DONE=""` (`scripts/lib/dev-cycle-read.sh:444`).

**Evidence:** `scripts/dev-cycle.sh:167-184`, `scripts/lib/dev-cycle-read.sh:444-476`

---

## Claim 9: "This row closes 204: constraints.md is refused, docs/thoughts/ stays fixable on purpose … (architecture F1, `scripts/dev-cycle.sh:181-183`)"

**Location:** `docs/reviews/override-log.md:322`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_fix's answers for docs/Constraints.md and docs/thoughts/t.md, and the cited line range at 6f624cdf (where the architecture review read it; at HEAD those lines are `:179-181`). It does not establish that the floor (U2a2) will share the list.
**Legibility-target:** for-orchestrator-synthesis

The test expects `"skip docs/Constraints.md: in-cycle fixes edit only" "ok docs/thoughts/t.md"` (`test/scripts/dev-cycle.bats:1029`) and passes (E1). The mutant that removes `|| "$lp" == docs/constraints.md` fails it (logs/mut-constraints-ok.log). At 6f624cdf, `:181-183` are the `elif` condition and the skip echo.

**Evidence:** `scripts/dev-cycle.sh:177-183`, `test/scripts/dev-cycle.bats:1016-1032`, logs/mut-constraints-ok.log

---

## Claim 10: "Three call sites write `isbrief X || isclosed X` themselves (lib writable, check_brief; build-loop.sh shared_branches)"

**Location:** `docs/reviews/override-log.md:323`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the call sites in scripts/ at HEAD. It does not cover U2b's planned fourth caller.
**Legibility-target:** for-orchestrator-synthesis

The three sites are `… ]] || isbrief "$1" || isclosed "$1"` (`scripts/lib/dev-cycle-read.sh:161`), `if ! isbrief "$a" && ! isclosed "$a"; then` (`:344`, the negated form) and `if ! { isbrief "$f" || isclosed "$f"; }` (`scripts/build-loop.sh:318`). `rg isclosed scripts` finds no other caller (paraphrased, no quote available because the claim covers the absence of other matches).

**Evidence:** `scripts/lib/dev-cycle-read.sh:158-162`, `scripts/lib/dev-cycle-read.sh:344`, `scripts/build-loop.sh:318`

---

## Claim 11: "U2a2's floor must run its own rules … so `.github/x.yml` is refused under D5's dot rule rather than as badform … with a test that changes `.gitattributes`"

**Location:** `docs/reviews/override-log.md:324`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the present-tense premise that main_entry answers badform for `.github/x.yml` and `.gitattributes`. The rest of the row is a prescription for U2a2 and is not checkable.
**Legibility-target:** for-orchestrator-synthesis

E8/E9 printed `.gitattributes -> badform, git calls: 0` and `.github/x.yml -> badform, git calls: 0`. The test pins both: `for p in x … .gitattributes .github/x.yml` (`test/scripts/dev-cycle.bats:1358`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:265-266`, logs/probe2.log

---

## Claim 12: "entry_why adds one subshell (~0.3 ms) per refused argument, and isclosed costs ~17 µs more per brief pair in shared_branches than the old substitution"

**Location:** `docs/reviews/override-log.md:325`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the order of magnitude on this host. It does not establish the exact figure, which depends on the machine.
**Legibility-target:** for-orchestrator-synthesis

E13 timed 1000 runs of `$(entry_why notfile docs/x.md)` at 0.468 s, against 0.011 s for direct calls, so about 0.46 ms per subshell here. It timed 5000 pairs of the old substitution at 0.211 s and of `isbrief || isclosed` at 0.300 s, so about 18 µs more per pair. The callers' refusal arms all return straight after the reason, as quoted in Claim 5.

**Evidence:** logs/probe4.log, `scripts/lib/dev-cycle-read.sh:354`, `scripts/build-loop.sh:318`

---

## Claim 13: "U2a1: main_entry's badform word with one shared reason mapping, entry_why (rows 228, 306); … isclosed (row 292); check_fix also refuses docs/constraints.md (row 204: the user writes it, D2; docs/thoughts/ stays fixable in-cycle as a living doc, so check_fix and the floor differ there on purpose)"

**Location:** `docs/working/plan-build-loop-handoff.md:274`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the unit contents against the code, plus D2 and the floor's read-as-truth list in the plan. It does not cover the U2a2, U2b or U2c bullets, which describe future work.
**Legibility-target:** for-orchestrator-synthesis

D2 says "Creating the doc is your work" (`plan-build-loop-handoff.md:50`). The floor's item 4 lists "`docs/constraints.md`, `docs/decisions/`, `docs/thoughts/`" (`:72`). check_fix refuses constraints.md and leaves thoughts/ alone (Claim 9). The code items match Claims 2, 22 and 23.

**Evidence:** `docs/working/plan-build-loop-handoff.md:43-50`, `docs/working/plan-build-loop-handoff.md:72`, `docs/working/plan-build-loop-handoff.md:273-279`

---

## Claim 14: Q-119: "Interim: [1]. Split recorded in the U2a rubric and commit e8f76379 on `feat/build-loop-u2a`"; "Blocks: nothing"

**Location:** `docs/working/questions.md:376-392`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the existence of the commit and the rubric section, and the questions-doc structure check. It does not judge the split.
**Legibility-target:** for-orchestrator-synthesis

`git log -1 e8f76379` gives `docs(reviews): U2a iteration 3 (final pass, k=3) and the iteration-4 gate decision: split`, and `git branch --contains` gives `feat/build-loop-u2a`. That branch's rubric has `### Iteration-4 gate decision: \`split\`` and `- **U2a1** (\`feat/build-loop-u2a1\`, from main, fresh loop)` at `:69-74`. E14 prints `✓ questions: structure valid, indexes current`.

**Evidence:** `feat/build-loop-u2a:docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md:69-74`, logs/questions-check.log

---

## Claim 15: "Markup that adds letters (a checked task box, a tag) can still hide a copy; only an exact line ever sets a value."

**Location:** `scripts/build-loop.sh:44-46`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers checked and unchecked task boxes on the policy key. It does not test tags. The `<` start is refused by FENCE_AWK, so only a tag that is not first on the line applies.
**Legibility-target:** for-orchestrator-synthesis

The copy count works as `s = tolower($0); gsub(/[^a-z]/, "", s)` … `index(s, "buildlooppolicy") == 1` (`scripts/build-loop.sh:154-156`). In E13, `- [x] Build-loop policy: review` above an exact self-merge line gave `policy self-merge set: line 2`, so the copy was hidden. `- [ ] …` gave `more than one line starts "Build-loop policy:" (lines 1 and 2)`, so the copy was counted. This agrees with `:18-20` ("an unchecked task box … counts as a copy … one it misses (a checked task box …) is ignored").

**Evidence:** `scripts/build-loop.sh:16-20`, `scripts/build-loop.sh:143-163`, logs/probe4.log

---

## Claim 16: "A tip on a branch not ahead of main, or whose subject does not start 'handoff:', is working."

**Location:** `scripts/build-loop.sh:73-74`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers status_line's LOOP default and its ahead gate. It does not cover marker_kind's bad arms.
**Legibility-target:** for-orchestrator-synthesis

In status_line, `loop=working` is followed by `if [[ "$ahead" -gt 0 ]]; then kind="$(marker_kind "$sha")"` (`scripts/build-loop.sh:352-353`). `ahead` is `git rev-list --count "$MAIN_SHA..$sha"` from check_branch (`scripts/lib/dev-cycle-read.sh:396`), and that count is 0 for a branch level with main or behind it. marker_kind does `[[ "$subj" == handoff:* ]] || { echo working; return; }` (`scripts/build-loop.sh:286`).

**Evidence:** `scripts/build-loop.sh:279-301`, `scripts/build-loop.sh:323-361`, `scripts/lib/dev-cycle-read.sh:386-399`

---

## Claim 17: main_file's "it returns 1 with FILE_WHY 'absent' or why it was not read (main_entry, …)", and every non-blob, non-absent word is a refusal in its consumers

**Location:** `scripts/build-loop.sh:122-133`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main_file and its two consumers in read_settings (dev-cycle.md and constraints.md). It does not cover badform, which these fixed paths cannot reach.
**Legibility-target:** for-orchestrator-synthesis

The three arms are `blob) ;;`, `absent) FILE_WHY=absent; return 1 ;;` and `*) FILE_WHY="$(entry_why "$e" "$f")"; return 1 ;;` (`:131-133`). For dev-cycle.md, any FILE_WHY other than absent gives `POLICY_LINE="policy review unset: $why"` and `NEVER_LINE="never malformed: $why"` (`:215-217`), which turns self-merge off. For constraints.md it gives `CONSTRAINTS_LINE="constraints unreadable: $FILE_WHY"` (`:265`), and the plan dispatches only on `ok`. E10 shows all three refusal lines.

**Evidence:** `scripts/build-loop.sh:122-141`, `scripts/build-loop.sh:208-276`, logs/probe3.log

---

## Claim 18: shared_branches' `isbrief "$f" || isclosed "$f"` equals the old `isbrief "${f/#docs\/working\/briefs\/closed\//docs/working/briefs/}"`

**Location:** `scripts/build-loop.sh:318`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 23 edge-case paths compared under both spellings: double closed/, a newline inside and at the end, an Arabic-Indic digit, é, an upper-case W, a trailing slash, globs, the empty string. It does not cover the files git grep happens to list.
**Legibility-target:** for-orchestrator-synthesis

E8 prints `isclosed cases: 23, differences: 0` for the old shared_branches substitution, the old writable/check_brief regex and the new predicates. `isclosed` is `[[ "$1" == docs/working/briefs/closed/* ]] && isbrief "docs/working/briefs/${1#docs/working/briefs/closed/}"` (`scripts/lib/dev-cycle-read.sh:158`), and é is refused under C, en_US.UTF-8 and C.UTF-8.

**Evidence:** `scripts/lib/dev-cycle-read.sh:155-162`, `scripts/build-loop.sh:305-324`, logs/probe1.log

---

## Claim 19: --check-fix refuses "constraints.md" (header, skip message, SKILL.md), compared ignoring case; docs/thoughts/ stays ok

**Location:** `scripts/dev-cycle.sh:50-54`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three texts against check_fix's condition and the test. It does not cover the import walk.
**Legibility-target:** for-orchestrator-synthesis

The condition is `|| "$lp" == docs/dev-cycle.md || "$lp" == docs/constraints.md || …` on `lp`, the lower-cased path (`scripts/dev-cycle.sh:175`, `:179-180`). The skip message lists `dev-cycle.md, constraints.md` (`:181`), and SKILL.md lists `` `docs/dev-cycle.md`, `docs/constraints.md` `` (`skills/dev-cycle/SKILL.md:74`). E1 passes the docs/Constraints.md and docs/thoughts/t.md assertions (Claim 9).

**Evidence:** `scripts/dev-cycle.sh:50-54`, `scripts/dev-cycle.sh:170-184`, `skills/dev-cycle/SKILL.md:72-79`, logs/dev-cycle.log

---

## Claim 20: "An in-cycle fix edits documentation only; the header's --check-fix paragraph is the rule, and the skip message below repeats it."

**Location:** `scripts/dev-cycle.sh:167-168`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the header paragraph, the one exclusion-list skip message and the code's arms. It does not cover SKILL.md, which matches the header (Claim 19).
**Legibility-target:** for-author

The header excludes "the cycle's own files, working/, …, constraints.md, a dot-directory or dotfile, an instruction file, or a file an instruction file imports with @" (`scripts/dev-cycle.sh:50-53`). The skip message's list is "(not working/, human-author/, reviews/, decisions/, dev-cycle.md, constraints.md, dot-directories or dotfiles, or instruction files)" (`:181`), so it leaves out own files and @-imports. Each of those has its own skip line: `one of the cycle's own files (use --check-write)` (`:178`) and `an instruction file imports it with @` (`:183`). Precise version: "the skip messages below repeat it".

**Evidence:** `scripts/dev-cycle.sh:50-54`, `scripts/dev-cycle.sh:167-184`

---

## Claim 21: "A change here must pass test/scripts/dev-cycle.bats and build-loop.sh's suites (build-loop-*.bats)."

**Location:** `scripts/lib/dev-cycle-read.sh:10-11`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which suites exist and that they pass at HEAD. It does not establish any CI enforcement.
**Legibility-target:** for-orchestrator-synthesis

`ls test/scripts` lists `build-loop-read.bats` as the only `build-loop-*.bats`, and E1 and E2 both pass. The stale "once that second caller lands" wording is gone.

**Evidence:** `test/scripts/`, logs/dev-cycle.log, logs/build-loop-read.log

---

## Claim 22: isclosed "spells the closed/ brief path rule once" and equals writable's regex and check_brief's regex

**Location:** `scripts/lib/dev-cycle-read.sh:158`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers equivalence with both removed regexes on the 23 paths of Claim 18. Character classes are listed one by one, so locale does not matter.
**Legibility-target:** for-orchestrator-synthesis

The old regex `^docs/working/briefs/closed/$DIGIT{4}-$DIGIT{2}-$DIGIT{2}-$SLUG\.md$` was compared with `isclosed` in E8 (`old_writable_closed` and old check_brief), with 0 differences.

**Evidence:** `scripts/lib/dev-cycle-read.sh:155-162`, `scripts/lib/dev-cycle-read.sh:344`, logs/probe1.log

---

## Claim 23: main_entry prints … "badform" (a path pathform refuses: a .git* part such as .gitattributes, say) or "error" (no default branch found by name, ls-tree failed, or the tree lists a name twice …)

**Location:** `scripts/lib/dev-cycle-read.sh:252-256`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every return path of main_entry (`:262-279`). With no main found by name, a badform path answers `error`, because main_by_name runs first. The comment does not say otherwise.
**Legibility-target:** for-orchestrator-synthesis

The returns are:
```bash
# scripts/lib/dev-cycle-read.sh:265-268
  if ! main_by_name; then echo error; return; fi
  if ! pathform "$1"; then echo badform; return; fi
  while [[ "$rest" == */* ]]; do p="${p:+$p/}${rest%%/*}"; rest="${rest#*/}"; want+=("$p"); done
  out="$(git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1" 2>/dev/null)" || { echo error; return; }
```
(excerpt ends :268; enclosing main_entry() continues to :279, read: the dup check `[[ -z "$dup" ]] || { echo error; return; }` is at :274.) In E8, `.gitattributes`, `.github/x.yml`, `../x`, `a b`, `a\nb` and `docs//x.md` all give `badform`, and with `MAIN_BY_NAME=""`, `.gitattributes` gives `error`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:248-279`, logs/probe1.log

---

## Claim 24: "Only blob reads the file, and only absent means there is none: every other word is a refusal." Every caller treats a non-blob, non-absent word as a refusal

**Location:** `scripts/lib/dev-cycle-read.sh:256-257`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all four direct callers (check_brief, check_answer, brief_fields, main_file) and the indirect ones (status_line through check_brief and brief_fields, shared_branches through brief_fields). It does not establish fail-closed behaviour for F31's duplicate-branch count. There, a brief that is refused is not counted (`continue`), as recorded in rows 293 and 308, which predate this unit.
**Legibility-target:** for-orchestrator-synthesis

The callers handle the words as follows:
- check_brief: `absent) echo "ok $a new"` / `blob) ;;` / `*) echo "skip …"; return` (`:352-354`).
- check_answer: `absent) continue` / `blob) ;;` / `notdir\ *)` and `*)` both print a skip and return (`:570-574`).
- brief_fields: `[[ "$(main_entry "$1")" != blob ]]` gives `BRIEF_ODD=error; return 1` (`:312`).
- main_file: the arms quoted in Claim 17.
- status_line: `[[ "$out" == "ok "* ]] || { echo "$out"; return; }` (`scripts/build-loop.sh:329`).
- shared_branches: `|| ! brief_fields "$f"; then continue` (`scripts/build-loop.sh:318`).

The test with an `odd` word (E12, `dev-cycle.bats:1351-1352`) shows that an unknown word gets the default arm's wording. No arm anywhere maps a word other than blob to a read.

**Evidence:** `scripts/lib/dev-cycle-read.sh:307-330`, `scripts/lib/dev-cycle-read.sh:339-376`, `scripts/lib/dev-cycle-read.sh:563-591`, `scripts/build-loop.sh:122-141`, `scripts/build-loop.sh:305-361`

---

## Claim 25: "It runs main_by_name and pathform itself, before any read (pathform also means ls-tree prints the name unquoted)": badform is answered before any git call

**Location:** `scripts/lib/dev-cycle-read.sh:257-259`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the number of git invocations per word, counted with a `git` function shim. It does not cover git calls made by resolve_main earlier in the process.
**Legibility-target:** for-orchestrator-synthesis

E9 counts 0 git calls for each of `.gitattributes`, `.github/x.yml`, `../x` and `a\nb` (badform), and 1 for each of `x` and `docs/x.md` (absent). main_by_name is a variable test: `main_by_name() { [[ -n "$MAIN_SHA" && -n "$MAIN_BY_NAME" ]]; }` (`:247`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:247`, `scripts/lib/dev-cycle-read.sh:262-268`, logs/probe2.log

---

## Claim 26: "$2 is the path, named in the reason; pass "" when the skip line already names it."

**Location:** `scripts/lib/dev-cycle-read.sh:280-281`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all five arms of entry_why with an empty and a non-empty `$2`. It does not cover callers.
**Legibility-target:** for-author

The notfile, badform, error and default arms name `$2` when it is non-empty: `${p:+$p is }`, `${p:+ for $p}` (`:287-290`). The notdir arm ignores it: `notdir\ *) echo "${w#notdir } is not a directory on the default branch" ;;` (`:286`). E12 and the test (`dev-cycle.bats:1343-1344`) print the same line with and without a path. check_answer's comment at `:572` documents this. Precise version: "…named in the reason, except after notdir, which names the directory instead". The `empty-path` mutant (`notfile) echo "$p is …`) fails the new test (logs/mut-empty-path.log).

**Evidence:** `scripts/lib/dev-cycle-read.sh:280-292`, `test/scripts/dev-cycle.bats:1338-1354`, logs/mut-empty-path.log

---

## Claim 27: "A newline in either becomes a space, so the reason stays one line."

**Location:** `scripts/lib/dev-cycle-read.sh:281-282`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers newlines in `$1` and `$2`. It does not cover other control characters, which scrub removes at output.
**Legibility-target:** for-orchestrator-synthesis

The code is `local w="${1//$'\n'/ }" p="${2//$'\n'/ }"` (`:284`). E12: `entry_why $'odd\nok' ""` gives `the default branch answered odd ok`, and `entry_why $'notdir a\nok b' x` gives `a ok b is not a directory …`, each on one line.

**Evidence:** `scripts/lib/dev-cycle-read.sh:283-292`, logs/entry_why-direct.log

---

## Claim 28: `# "it" is $f, except after notdir, whose reason names a directory above it.` and the resulting check_answer lines

**Location:** `scripts/lib/dev-cycle-read.sh:572`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the notdir, notfile and error lines. Badform and unknown words are unreachable here, because the paths are fixed.
**Legibility-target:** for-orchestrator-synthesis

E1 passes these expectations:
- `skip Q-1: docs/working is not a directory on the default branch, so no entry in docs/working/questions.md is read` (`dev-cycle.bats:1203`).
- `skip Q-1: docs/working/questions.md is not a regular file on the default branch, so no entry in it is read` (`:1198`).
- `skip Q-1: the tree of the default branch could not be read for docs/working/questions.md, so no entry in it is read` (`:1327`).

The mutant that changes the notdir tail fails the check-answer tests (logs/mut-check-answer-wording.log).

**Evidence:** `scripts/lib/dev-cycle-read.sh:563-575`, `test/scripts/dev-cycle.bats:1190-1206`, `test/scripts/dev-cycle.bats:1320-1328`, logs/mut-check-answer-wording.log

---

## Claim 29: no doc, help text, SKILL.md or test still quotes a skip wording that is no longer printed

**Location:** `scripts/lib/dev-cycle-read.sh:283-292`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the removed wordings "the default branch's tree could not be read", "…, so <file> is not read" from check_answer, and "could not be read, so". The search excluded docs/reviews, archive and runs. It does not cover wordings that review artifacts quote.
**Legibility-target:** for-orchestrator-synthesis

`rg "default branch's tree|so docs/working/questions.md is not read|could not be read, so"` outside docs/reviews, archive and runs found no hits (paraphrased, no quote available because the claim covers the absence of matches). The remaining "is not read" matches are other, unchanged messages (`build-loop.sh:138-139`, `lib:358-360`). The dev-cycle.sh --check-answer header ("a default branch whose tree or file could not be read", `scripts/dev-cycle.sh:67-68`) still describes the new lines.

**Evidence:** `scripts/dev-cycle.sh:55-68`, `scripts/build-loop.sh:136-139`, `scripts/lib/dev-cycle-read.sh:356-361`

---

## Claim 30: "the same hermetic git environment as test/scripts/dev-cycle.bats" and "git lists every such repo-local variable itself (GIT_CONFIG_PARAMETERS too)"

**Location:** `test/lib/build-loop-fixtures.bash:2-4`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the git-related environment of both setups and what git 2.39.5 lists. bl_setup also sets `LC_ALL=C`, which dev-cycle.bats does not. That is not a git variable. The scope does not establish behaviour with other git versions.
**Legibility-target:** for-orchestrator-synthesis

Both setups run `unset $(git rev-parse --local-env-vars)` and then `export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`, the same author and committer variables, and a HOME under the temp dir (`dev-cycle.bats:13-19`, `build-loop-fixtures.bash:15-20`). `git rev-parse --local-env-vars` prints 16 names, among them `GIT_CONFIG_PARAMETERS`, `GIT_CONFIG_COUNT`, `GIT_DIR` and `GIT_INDEX_FILE`. It works with a bogus `GIT_DIR` and with a broken `GIT_CONFIG_COUNT=1` (E15: rc 0, victim untouched). No suite relies on an inherited one: `GIT_CONFIG_COUNT` appears only per command as `run --separate-stderr env GIT_CONFIG_COUNT=1 …` (`build-loop-read.bats:438`, `:483`).

**Evidence:** `test/lib/build-loop-fixtures.bash:1-23`, `test/scripts/dev-cycle.bats:8-23`, `test/scripts/build-loop-read.bats:432-440`, logs/victim-head.log, logs/victim-cc.log

---

## Claim 31: "# A marker whose message body holds a NUL byte (one commit on top of base, with its tree)."

**Location:** `test/scripts/build-loop-read.bats:297`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the fixture object the comment describes. It does not cover marker_kind's verdict on it.
**Legibility-target:** for-orchestrator-synthesis

The fixture is `printf 'tree %s\nparent %s\n…' "$(git rev-parse "$base^{tree}")" "$base"` (`:298`): its parent is base and its tree is base's tree.

**Evidence:** `test/scripts/build-loop-read.bats:297-300`

---

## Claim 32: the three fixture `&&` chains are split (with a standalone `git replace -d`), so a failed fixture step fails the test

**Location:** `test/scripts/build-loop-read.bats:436-440`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three chains named in row 317 (`:436`, `:466-468`, `:473-475` at HEAD). It does not cover the older chain at `:84`, `git replace … && git config core.useReplaceRefs true`, which row 317 did not name.
**Legibility-target:** for-orchestrator-synthesis

With each split step made to fail on its own copy, the target test fails:
- `replace-fails` (the replace given a zero object id): `not ok 10 … (in test file …, line 436)`.
- `crlf-fails` and `odddir-fails` (each printf redirected into a missing directory): 1 failing each.

The standalone `git replace -d "$(git rev-parse main:docs/dev-cycle.md)"` (`:440`) also fails the test when no replacement was made (`replace-fails-chain`: 1 failing).

**Evidence:** `test/scripts/build-loop-read.bats:430-441`, `test/scripts/build-loop-read.bats:465-476`, logs/mut-replace-fails.log, logs/mut-crlf-fails.log, logs/mut-odddir-fails.log, logs/mut-replace-fails-chain.log

---

## Claim 33: "# As bl_setup: an inherited GIT_DIR would send fixture commits to that repo."

**Location:** `test/scripts/dev-cycle.bats:11-13`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers dev-cycle.bats with and without the line. It does not cover suites outside these two.
**Legibility-target:** for-orchestrator-synthesis

Without the line (E6/E7), the victim receives fixture commits and branches. With it (E5/E7), the victim keeps 1 commit. See Claim 3.

**Evidence:** `test/scripts/dev-cycle.bats:8-23`, logs/victim-filter-mut1.log, logs/victim-head.log

---

## Claim 34: the new entry_why test pins "each main_entry refusal on one line, naming the path only when given"

**Location:** `test/scripts/dev-cycle.bats:1338-1354`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers newlines in the path and the empty-path wording of all five arms. It does not pin the translation of a newline in the word (`$1`): the `nl-word-only` mutant `local w="$1"` passes, because no input word holds a newline. That input is unreachable from main_entry, whose words come from paths that pathform has cleared.
**Legibility-target:** for-orchestrator-synthesis

The mutant results are `nl-word: bats exit 1 (1 failing)`, `empty-path: bats exit 1 (1 failing)` and `nl-word-only: bats exit 0 (0 failing)`.

**Evidence:** `test/scripts/dev-cycle.bats:1338-1354`, logs/mut-nl-word.log, logs/mut-empty-path.log, logs/mut-nl-word-only.log

---

## Claim 35: "main_entry answers badform for a path pathform refuses, absent for a plain missing one" (the x → absent positive control)

**Location:** `test/scripts/dev-cycle.bats:1356-1366`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers three reversions: badform reverted to error, every path answered badform, and the fixture's `resolve_main` dropped. It does not cover a mutant that reorders main_by_name and pathform.
**Legibility-target:** for-orchestrator-synthesis

`badform-to-error`, `all-badform` (`if true; then echo badform`) and `no-main-error` (`resolve_main` removed) each fail the test, with 1 failing each (E11).

**Evidence:** `test/scripts/dev-cycle.bats:1356-1366`, logs/mut-badform-to-error.log, logs/mut-all-badform.log, logs/mut-no-main-error.log

---

## Claim 36a: commit messages: 6f624cdf ("Tests: dev-cycle.bats 73, build-loop-read.bats 19, hermeticity 2 pass. 128 changed code lines."; the carried rows 314, 317-320), 706e0499 ("0 Must Fix; 1 Medium …, 1 Low, 4 Minor … Four declined findings get override rows (C1-C4), and row 204 is closed by C1's row"), d48f4645 (A1-A5 and "Tests: dev-cycle.bats 74 …, build-loop-read.bats 19, hermeticity 2 … shellcheck clean. 165 changed code lines against main"; "checked: 1 commit before and after")

**Location:** `git log main..HEAD` (commits 6f624cdf, 706e0499, d48f4645)
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test counts (from `^@test` at each commit, and from running them at HEAD), the line counts, the severity tallies against the rubric, and A1-A5 against the code. A6 is Claim 6, and the Notes line is Claim 36b. 6f624cdf's own Notes line is already logged as Accepted-immutable (Claim 8).
**Legibility-target:** for-orchestrator-synthesis

The `@test` counts are `6f624cdf dc=73 bl=19 fh=2` and `d48f4645 dc=74 bl=19 fh=2`. E4 gives 128 (main..6f624cdf) and 165 (main...HEAD). At 6f624cdf, bl_setup has `unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES` (row 314). The rubric rows A3, A4, A5 and C1 are the 4 Minor; A1 is Medium and A2 is Low (`rubric:21-27`). The diff adds override rows `:321-325`: one Accepted-immutable plus C1-C4. "1 commit before and after" is reproduced in E7 and E5.

**Evidence:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:19-38`, `docs/reviews/override-log.md:321-325`, E4 output, logs/victim-filter-wt.log

---

## Claim 36b: d48f4645 Notes: "the old, pre-U2a1 sentences come back except where a path is now named"

**Location:** `git show d48f4645` (commit message, Notes line)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each skip sentence at main against HEAD for check_brief, check_answer and main_file. It does not cover sentences that never went through main_entry.
**Legibility-target:** for-author

check_brief's three sentences match main's exactly, and so does check_answer's notfile line. Three others changed even though main's version already named the path:
- check_answer notdir: main had `…, so $f is not read` (removed line in `git diff main...HEAD -- scripts/lib/dev-cycle-read.sh`), and HEAD has `…, so no entry in $f is read` (`:573`). The test expectation at `dev-cycle.bats:1203` changed to match.
- check_answer error: main had `the tree of the default branch could not be read, so $f is not read`, and HEAD has `…could not be read for $f, so no entry in it is read`.
- main_file error: main had `the default branch's tree could not be read for $f`, and HEAD has `the tree of the default branch could not be read for $f`.

Precise version: "check_brief's and the notfile sentences come back; the notdir and error sentences take the shared wording".

**Evidence:** `scripts/lib/dev-cycle-read.sh:563-575`, `scripts/build-loop.sh:129-133`, `test/scripts/dev-cycle.bats:1203`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 2** (`docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:17`): "the diff addresses each" holds for every row except row 319's short-line residue (lib header `:25` is still 52 chars).
- **Claim 6** (`docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:26`, also d48f4645's A6): "reflowed" is partial. `:13` is fixed, but `:25` is still short and `:16` now runs to 96 chars.
- **Claim 20** (`scripts/dev-cycle.sh:167-168`): "the skip message below repeats it". The exclusion-list message leaves out own files and @-imports, each of which has its own skip line, so it should read "the skip messages below".
- **Claim 26** (`scripts/lib/dev-cycle-read.sh:280-281`): "$2 is the path, named in the reason". The notdir arm ignores `$2` and names the directory.
- **Claim 36b** (d48f4645 Notes): "the old sentences come back except where a path is now named". check_answer's notdir and error sentences and main_file's error sentence are reworded, though main's versions already named the path.

### Unverifiable
(none)

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved at the replicate path named below (inside the worktree), structured per the code-fact-check skill, with `Commit: d48f4645` as its first line.
- Answered: yes. All nine focus areas were checked, mostly by execution (suites, victim GIT_DIR, 12 mutants, probes).
- Out of scope: review artifacts other than the rubric and the new override rows; U2a2/U2b/U2c prescriptions in the override rows (not checkable yet).
- Escalate: nothing blocking. All five non-Verified claims are wording-only. The unpinned word-newline arm of entry_why (Claim 34) is unreachable today.
- Decisions I made: numbered row 319's residue twice, once as the rubric's "addresses each" (Claim 2) and once as A6's "reflowed" (Claim 6), because they are separate statements. Counted the older unsplit `:84` chain as outside row 317 rather than as a defect.
