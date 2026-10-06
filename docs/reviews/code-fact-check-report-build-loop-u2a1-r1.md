Commit: d07cc89c

# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u2a1, branch feat/build-loop-u2a1)
**Scope:** branch diff `git diff main...HEAD` (main 900c47d0 .. d07cc89c; commits 6f624cdf, 706e0499, d48f4645, 91469367, d07cc89c): scripts/build-loop.sh, scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, skills/dev-cycle/SKILL.md, test/lib/build-loop-fixtures.bash, test/scripts/build-loop-read.bats, test/scripts/dev-cycle.bats, test/scripts/fixture-git-env.bats (new), docs/working/plan-build-loop-handoff.md, docs/working/questions.md (Q-119), the rubric's iteration-2 section, the ten `feat/build-loop-u2a1` rows of docs/reviews/override-log.md, and the messages of 91469367 and d07cc89c. Earlier commits' message claims are settled by Accepted-immutable rows and are not re-verdicted. Other docs/reviews/*.md artifacts were skipped. Replicate r1 of 3 (iteration 3, final confirming pass).
**Checked:** 2026-10-06
**Total claims checked:** 47 (Claims 1-45, 46a, 46b)
**Summary:** 39 verified, 6 mostly accurate, 1 stale, 1 incorrect, 0 unverifiable

## Execution provenance

All runs: cwd `/workspace/.claude/wt-build-loop-u2a1` (or a `git archive` export of a named commit under the scratch dir), `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1` wherever a fixture repo was made, every process under `timeout`, TMPDIR a `mktemp -d /tmp/u2a1i3-XXXX` directory (no dot-prefixed part), deleted at the end with the export copies and victim repos (`$FC/cleanup.sh`). `FC=/home/node/.claude/jobs/814a541d/tmp/review-u2a1-i3/fc1`; logs in `$FC/logs/`. Runs 2026-10-06T16:47Z-16:56Z. Mutants ran only on exports of HEAD (`$FC/mutants.sh`), never on the worktree; `git status --short` in the worktree was empty after the runs. Bats 1.8.2. No process left running.

| Run | Command | Exit | Log |
|---|---|---|---|
| E1 | `TMPDIR=$d bats test/scripts/dev-cycle.bats test/scripts/build-loop-read.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats` (16:47:15Z) | 0; `1..98`, 98 ok | `$FC/logs/suite.log` |
| E2 | `$FC/mutants.sh` (13 mutants on HEAD exports, 16:48:37Z) | per mutant, see Claims | `$FC/logs/mutants-summary.log`, `$FC/logs/mut-*.log` |
| E3 | `bash $FC/equiv.sh` (isclosed vs the three old spellings, 110 paths, 16:51:56Z) | 0; `cases=110 diffs=0` | `$FC/logs/isclosed-equiv.log` |
| E4 | `bash $FC/timing.sh` ×3 (16:52:39Z) | 0 | `$FC/logs/timing.log` |
| E5 | entry_why one-argument calls under `set -euo pipefail`, d48f4645's lib (`$FC/lib-d48.sh`) and HEAD's (16:52:50Z) | 1 (assignment form) / 0 (inline form) at d48f4645; 0 at HEAD | `$FC/logs/a8-d48.log` |
| E6 | `bash $FC/a10c.sh`: d48f4645 export, both unset lines `:`; both suites normally, then each fixture-git-env filter with GIT_DIR+GIT_INDEX_FILE at a fresh victim (16:53:57Z) | 0 | `$FC/logs/a10c-summary.log`, `a10c-*.log` |
| E7 | `git rev-parse --local-env-vars` ×200, with `git --version` and `$(true)` baselines (16:55:04Z) | 0 | `$FC/logs/c8.log` |
| E8 | `bats --timing test/scripts/fixture-git-env.bats`, and two wall-clock runs (16:55:25Z) | 0 | `$FC/logs/fge-timing.log`, `$FC/logs/fge-wall.log` |
| E9 | `scripts/hermeticity-lint --root . --json` (16:55:35Z) | 0; `"bash": 127`, no findings | `$FC/logs/herm.json` |
| E10 | `shellcheck scripts/lib/dev-cycle-read.sh scripts/build-loop.sh scripts/dev-cycle.sh test/lib/build-loop-fixtures.bash`; `git diff --numstat main...HEAD -- ':(top)' ':(top,exclude)docs/' \| awk ...` | 0; 233 | (inline: shellcheck printed nothing; numstat rows quoted in Claim 1) |

Hallucination-pattern log consulted (`docs/reviews/hallucination-patterns.md`). The per-suite test-count claims were compared against its two count patterns ("All 85 tests ... commit 59ca38f", "mode1-equiv 33 ... commit 37c5ea9"). Every count matched this time (Claims 9, 44).

---

## Claim 1: "233 changed code lines after iteration 2's fixes"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:4`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the brief's counting command over main...HEAD (d07cc89c); does not establish that the count excludes non-code files outside docs/ (SKILL.md is counted, 2 lines).
**Legibility-target:** for-orchestrator-synthesis

Executed (E10): the command prints `233`, from the numstat rows `6 7 scripts/build-loop.sh`, `6 8 scripts/dev-cycle.sh`, `49 35 scripts/lib/dev-cycle-read.sh`, `1 1 skills/dev-cycle/SKILL.md`, `5 0 test/lib/build-loop-fixtures.bash`, `10 4 test/scripts/build-loop-read.bats`, `55 14 test/scripts/dev-cycle.bats`, `32 0 test/scripts/fixture-git-env.bats`. d07cc89c changes no code, so the count at 91469367 is the same.

**Evidence:** E10 output (numstat rows quoted above)

---

## Claim 2: "53 clusters: 44 Verified, 9 Mostly accurate, 0 Incorrect. Agreement 88.7% (47/53)" and "replicates -r1/-r2/-r3: 40, 34, 37 claims"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:11`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the figures against the merged report and the three replicate headers as committed at d07cc89c; does not re-derive the clustering.
**Legibility-target:** for-orchestrator-synthesis

The merged report at d07cc89c has `**Total claims checked:** 53` and `**Summary:** 44 verified, 9 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable` (`docs/reviews/code-fact-check-report-build-loop-u2a1.md`, header), 53 `## Claim` headings and a verdict tally of 44/9, and states `Agreement rate: 47/53 = 88.7%` (same file, line 1135). The replicate headers (`git show HEAD:...-r1.md` etc.) read `Total claims checked:** 40`, `34`, and `37 (Claims 1-35, 36a, 36b)`. 47/53 = 0.8868.

**Evidence:** `docs/reviews/code-fact-check-report-build-loop-u2a1.md:1127-1135` (at d07cc89c), replicate headers at d07cc89c

---

## Claim 3: A7 "✅ Fixed (91469367): comment states each word's use; check_answer ends every refusal 'so no entry in $f is read'"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:20`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers entry_why's comment against its arms and check_answer's main_entry refusal arm; does not cover check_answer's other refusal lines (they already ended that way) or check_brief/main_file wording.
**Legibility-target:** for-orchestrator-synthesis

check_answer's case now has one refusal arm:

```bash
# scripts/lib/dev-cycle-read.sh:573-577
    case "$e" in
      absent) continue ;;
      blob) ;;
      *) echo "skip $a: $(entry_why "$e" "$f"), so no entry in $f is read"; return ;;
    esac
```

(excerpt ends :577; enclosing check_answer() continues to :595 — read). The comment `:281-285` names each word's use of `$2` (see Claim 31). Mutant E2 `answer-ending` (that arm back to "so no entry in it is read") fails three tests (65, 67, 71).

**Evidence:** `scripts/lib/dev-cycle-read.sh:281-295`, `:567-595`; `$FC/logs/mut-answer-ending.log`

---

## Claim 4: A8 "entry_why read `$2` bare; called with one argument under `set -u` it printed an empty reason"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:21`
**Type:** Behavioral / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers d48f4645's entry_why called with one argument under `set -euo pipefail`, inline and as an assignment; does not establish any caller made such a call (none did).
**Legibility-target:** for-author

At d48f4645 entry_why opened with `local w="${1//$'\n'/ }" p="${2//$'\n'/ }"` (d48f4645 `scripts/lib/dev-cycle-read.sh:284`). Executed (E5): `echo "skip x: $(entry_why error)"` printed `line 284: 2: unbound variable` on stderr, then `skip x: ` and carried on (exit 0), which is the claim. But `r="$(entry_why notfile)"`, the form main_file uses (`FILE_WHY="$(entry_why ...)"`, `scripts/build-loop.sh:133`), ended the whole shell with exit 1 instead. Precise version: "printed an empty reason when spliced into a line, and ended the caller's shell when assigned". HEAD reads `p="${2-}"` (`scripts/lib/dev-cycle-read.sh:287`) and E5 at HEAD prints each one-argument reason with no error. The fix is right either way.

**Evidence:** `scripts/lib/dev-cycle-read.sh:286-295`; d48f4645 `scripts/lib/dev-cycle-read.sh:283-292`; `$FC/logs/a8-d48.log`

---

## Claim 5: A10 "replacing it with `:` passes every test while a victim repo gains 7 and 5 commits" and "✅ Fixed: test/scripts/fixture-git-env.bats; fails on that mutant"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the d48f4645 mutant (both unset lines `:`) run normally and through the two fixture-git-env filters, and HEAD's new suite against the same mutant; does not cover a GIT_DIR-only victim (no GIT_INDEX_FILE), where the whole suite fails instead.
**Legibility-target:** for-orchestrator-synthesis

Executed (E6) on a d48f4645 export with both lines `:`: a normal run of both suites gave `93 ok, 0 not ok`. The dev-cycle filter `^prints all eight sections` with GIT_DIR and GIT_INDEX_FILE at a one-commit victim left it at `victim commits 8`, and the build-loop-read filter `exact policy line is set` left another at `victim commits 6`: +7 and +5. On HEAD exports (E2) the mutant `unset-dc` fails fixture-git-env test 1 and `unset-bl` fails test 2 (`not ok 1 dev-cycle.bats fixtures stay out ...`, `not ok 2 build-loop-read.bats fixtures stay out ...`).

**Evidence:** `$FC/logs/a10c-summary.log`, `$FC/logs/mut-unset-dc.log`, `$FC/logs/mut-unset-bl.log`

---

## Claim 6: A11 "without it `--check-write 2026-01-01-x.md` prints ok (the write gate fails open)" and "✅ Fixed: new dev-cycle.bats test; fails on that mutant"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:24`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the prefix-guard mutant against the new test; does not establish what a successful --check-write would let a caller write.
**Legibility-target:** for-orchestrator-synthesis

Mutant E2 `isclosed-prefix` turns `isclosed() { [[ "$1" == docs/working/briefs/closed/* ]] && isbrief ...` into `isclosed() { isbrief ...`. The test at `test/scripts/dev-cycle.bats:1371` fails, and the run's output starts `# ok 2026-01-01-x.md`, so the mutant's --check-write prints ok.

**Evidence:** `scripts/lib/dev-cycle-read.sh:158`; `test/scripts/dev-cycle.bats:1371-1378`; `$FC/logs/mut-isclosed-prefix.log`

---

## Claim 7: A12 "✅ Fixed: comment and one test line"; A13 "✅ Fixed: 'skip messages'; header reflowed whole"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:25-26`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the comment text, the test line and its mutant, the check_fix comment word and the header's line widths; does not judge the reflow's wording.
**Legibility-target:** for-orchestrator-synthesis

The comment says `main_by_name, then pathform, itself, before any read (so with no default branch even a refused form answers error` (`scripts/lib/dev-cycle-read.sh:257-259`). The test ends with `MAIN_SHA=""; main_entry .gitattributes` expecting a last `error` (`test/scripts/dev-cycle.bats:1359-1368`). Mutant E2 `guard-order` fails it (the last line becomes `badform`). The check_fix comment reads `the skip messages below repeat it` (`scripts/dev-cycle.sh:168`). The header lines `:8-31` now run 69-80 columns, with no short line left (paraphrased — no quote available because the claim is about line lengths, measured with awk).

**Evidence:** `scripts/lib/dev-cycle-read.sh:8-32`, `:246-262`; `scripts/dev-cycle.sh:167-169`; `$FC/logs/mut-guard-order.log`

---

## Claim 8: C11 "C4 override row's timings (measured 0.42-0.52 ms, 18-37 µs)" with status "✅ Row's figures corrected; the conclusion holds"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:31`
**Type:** Performance / Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the rubric's figures against the corrected row and against a re-measurement on this host; does not establish other hosts' timings.
**Legibility-target:** for-author

The row now reads `entry_why adds one subshell (0.3-0.5 ms, by host) ... ~17-37 µs` (`docs/reviews/override-log.md:325`). That is not the range this rubric line quotes as measured (0.42-0.52 ms, 18-37 µs). It is that range widened to take in iteration 1's original 0.3 ms and 17 µs, with 0.52 rounded down. My re-measurement (E4: 0.48-0.54 ms per subshell, 18.7-21.5 µs per pair) sits inside the rubric's figures, apart from 0.54, and above the row's 0.5 ceiling. Precise version: "row's figures widened to 0.3-0.5 ms (iteration 1 and 2 together)". The conclusion (negligible) holds.

**Evidence:** `docs/reviews/override-log.md:325`; `$FC/logs/timing.log`

---

## Claim 9: "Tests after 91469367: 98/98 (dev-cycle 75, build-loop-read 19, fixture-git-env 2, hermeticity 2) under a TMPDIR with no dot-prefixed part; shellcheck clean"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:37`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four suites and shellcheck of the four changed shell files at d07cc89c (no code change since 91469367); does not cover shellcheck of the .bats files or the "fix-drift check".
**Legibility-target:** for-orchestrator-synthesis

E1 printed `1..98` and 98 `ok` lines, exit 0. `grep -c '^@test'` gives 75, 19 and 2 for the three test/scripts suites and 2 for test/fixture-hermeticity.bats. E10 shellcheck printed nothing, exit 0. Matches no logged hallucination pattern.

**Evidence:** `$FC/logs/suite.log`

---

## Claim 10: C1 row's location "`scripts/dev-cycle.sh:181-183`"

**Location:** `docs/reviews/override-log.md:322`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line citation only; the row's substance (constraints.md inline in check_fix, docs/thoughts/ fixable) is correct (Claims 26, 39).
**Legibility-target:** for-author

At 6f624cdf, :181-183 held check_fix's condition and the constraints.md echo. d48f4645 shortened the comment above check_fix by two lines, so at HEAD the condition and skip message are at `:179-181`:

```bash
# scripts/dev-cycle.sh:179-181
  elif [[ ! "$lp" =~ ^docs/.*\.md$|^readme\.md$ || "$lp" =~ ^docs/(working|human-author|reviews|decisions)/ \
    || "$lp" == docs/dev-cycle.md || "$lp" == docs/constraints.md || "$a" == */.* || "$low" =~ $INSTRUCTION_FILE ]]; then
    echo "skip $a: in-cycle fixes edit only tracked .md documentation under docs/ (...)"
```

(excerpt ends :181, message shortened; enclosing check_fix() continues to :184 — read). At HEAD, :181-183 is the echo, the import arm and its echo.

**Evidence:** `scripts/dev-cycle.sh:170-184`; `git show 6f624cdf:scripts/dev-cycle.sh` lines 179-184

---

## Claim 11: C2 "Three call sites write `isbrief X || isclosed X` themselves (lib writable, check_brief; build-loop.sh shared_branches)"

**Location:** `docs/reviews/override-log.md:323`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three named sites; does not establish that there are no other callers of isclosed (grep finds none).
**Legibility-target:** for-orchestrator-synthesis

`... ]] || isbrief "$1" || isclosed "$1"` (`scripts/lib/dev-cycle-read.sh:161`), `if ! isbrief "$a" && ! isclosed "$a"; then` (`:348`, the same test negated) and `if ! { isbrief "$f" || isclosed "$f"; } || ...` (`scripts/build-loop.sh:318`). A grep for `isclosed` finds no other caller outside tests.

**Evidence:** `scripts/lib/dev-cycle-read.sh:158-162`, `:348`; `scripts/build-loop.sh:318`

---

## Claim 12: C4 row "entry_why adds one subshell (0.3-0.5 ms, by host) per refused argument, and isclosed costs ~17-37 µs more per brief pair ... figures re-measured in iteration 2"

**Location:** `docs/reviews/override-log.md:325`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the per-call costs on this host; does not establish the "suite delta within run-to-run noise" sentence (not re-measured).
**Legibility-target:** for-author

E4 measured entry_why's `$(...)` at 0.485, 0.514 and 0.542 ms per call, and `isbrief || isclosed` on a closed/ path at 18.7-21.5 µs more than the old substitution (`$FC/logs/timing.log`). The isclosed range holds, and the subshell cost is at or just above the row's 0.5 ms ceiling. As Claim 8 says, the "re-measured" range quoted in the rubric is 0.42-0.52 ms. The row's 0.3 floor is iteration 1's figure. The conclusion (Won't-Fix, negligible against the ~1 ms git start on the same path) holds.

**Evidence:** `$FC/logs/timing.log`; `$FC/timing.sh`

---

## Claim 13: "91469367 reflows the header whole and states the final wording"

**Location:** `docs/reviews/override-log.md:326`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the resolution sentence of the row; the row's history claims about 706e0499/d48f4645 are Accepted-immutable and not re-verdicted.
**Legibility-target:** for-orchestrator-synthesis

The header `scripts/lib/dev-cycle-read.sh:8-31` has no short line left (see Claim 7). 91469367's message says `Wording: the lib header reflowed whole` and gives the final check_answer wording `ends every main_entry refusal with "so no entry in $f is read"`, which `:576` prints.

**Evidence:** `scripts/lib/dev-cycle-read.sh:8-31`, `:576`; `git log -1 91469367`

---

## Claim 14: C7 "Other suites still write fixture commits into an inherited GIT_DIR: test/merge-safety.bats:20-24 ..., and by reading test/cc-push.bats:35-36, test/scripts/archive-working-docs.bats:97,114, test/si-clean-state.bats:40, test/cc-isolated-functions.bats:1489"

**Location:** `docs/reviews/override-log.md:327`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that each cited line runs `git init`/`git commit` and that none of the five files unsets `GIT_DIR` or `--local-env-vars`; does not re-execute the merge-safety victim run.
**Legibility-target:** for-orchestrator-synthesis

`test/merge-safety.bats:20-24` reads `export GIT_CONFIG_GLOBAL=/dev/null ...`, `REPO=$(mktemp -d)`, `git init -q -b main`, `echo a > f && git add f && git commit -qm init`. `test/cc-push.bats:35-36` runs `git init -q --bare "$T/upstream.git"` and `git init -q "$T/co"`. `archive-working-docs.bats:97,114` are `git init -q`, `si-clean-state.bats:40` is `git init -q -b main` and `cc-isolated-functions.bats:1489` is `git init -q --bare "$TEST_TMPDIR/remote.git"`. `rg 'local-env-vars|unset GIT_DIR'` over the five files finds nothing.

**Evidence:** the cited lines

---

## Claim 15: C8 "Each test's setup now starts git once for `--local-env-vars` (~1 ms, ~0.1 s per run of both suites)"

**Location:** `docs/reviews/override-log.md:328`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the per-call cost on this host, warm; does not cover a cold first call (one 200-call loop averaged 15 ms in a fresh directory).
**Legibility-target:** for-orchestrator-synthesis

E7: three warm 200-call loops gave 1.55, 1.00 and 1.04 ms per call, against 1.13-1.80 ms for `git --version`. 94 setups × ~1 ms ≈ 0.1 s. One earlier cold loop averaged 15.5 ms. I count it as an outlier, since the same command then measured ~1 ms three times.

**Evidence:** `$FC/logs/c8.log`; `test/scripts/dev-cycle.bats:13`; `test/lib/build-loop-fixtures.bash:15`

---

## Claim 16: C9 "Untested: entry_why's newline folding of the word argument (no caller produces such a word; the mutant survives), check_brief's notdir and error words through the CLI, main_file's error reason through --settings"

**Location:** `docs/reviews/override-log.md:329`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the word-folding mutant and the absence of CLI tests for the two other cases; does not establish that no caller could ever pass such a word.
**Legibility-target:** for-orchestrator-synthesis

Mutant E2 `why-word-nl` (`local w="$1"`) passes the entry_why test: `1 ok, 0 not ok`. main_entry's words are fixed strings or `notdir $p`, and `$p` passed pathform (`scripts/lib/dev-cycle-read.sh:266-277`), so no caller gets a word holding a newline. A grep of both suites finds no expected line `could not be read for docs/dev-cycle.md` and no check_brief notdir line (paraphrased — no quote available because the claim covers absence of code).

**Evidence:** `$FC/logs/mut-why-word-nl.log`; `scripts/lib/dev-cycle-read.sh:263-280`

---

## Claim 17: C10 "build-loop-read.bats:84 keeps an older `git replace ... && git config` chain ... Guarded by its own `git replace -d` at :85"

**Location:** `docs/reviews/override-log.md:330`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two lines; does not judge whether the chain can fail silently.
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/scripts/build-loop-read.bats:84-85
    git replace "$(git rev-parse main:docs/dev-cycle.md)" "$(git hash-object -w docs/dev-cycle.md)" && git config core.useReplaceRefs true
    settings_like policy "policy review set:"; git replace -d "$(git rev-parse main:docs/dev-cycle.md)"
```

**Evidence:** `test/scripts/build-loop-read.bats:84-85`

---

## Claim 18: F10 "Floor item 4 keeps the docs `check_fix` denied (`docs/decisions/`, `docs/thoughts/`, `docs/human-author/`, other briefs' working docs, cycle files)"

**Location:** `docs/working/plan-build-loop-handoff.md:125`
**Type:** Behavioral / Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the attribution of `docs/thoughts/` to check_fix's denials, at HEAD and on main; this line predates the branch and is outside the diff, but the diff's own note at `:274` now says the opposite. Does not judge the floor list itself.
**Legibility-target:** for-author

check_fix denies only `^docs/(working|human-author|reviews|decisions)/`, dev-cycle.md, constraints.md, dot parts and instruction files (`scripts/dev-cycle.sh:179-180`). docs/thoughts/ is fixable, and the branch's own test pins `"ok docs/thoughts/t.md"` (`test/scripts/dev-cycle.bats:1029`). The U2a1 note in the same plan says `docs/thoughts/ stays fixable in-cycle as a living doc, so check_fix and the floor differ there on purpose` (`docs/working/plan-build-loop-handoff.md:274`). Read together, the two lines contradict each other. Precise version: "floor item 4 keeps the docs check_fix denies (decisions/, human-author/, ...) plus docs/thoughts/ and constraints.md". The same row's "cycle files" also leaves out constraints.md, which check_fix now denies.

**Evidence:** `docs/working/plan-build-loop-handoff.md:125`, `:274`; `scripts/dev-cycle.sh:179-181`; `test/scripts/dev-cycle.bats:1016-1032`

---

## Claim 19: "U1 measured four units against a planned one, and U2 carries about twenty override rows"

**Location:** `docs/working/plan-build-loop-handoff.md:273`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers U1's unit count (U1a-U1d) and a grep count of override rows deferred to U2 on main; does not establish which rows the author counted.
**Legibility-target:** for-author

U1 landed as U1a, U1b, U1c and U1d (main's head commit: `docs(checkpoint): U1 complete (U1d landed at 4e12b03c)`). On main, `grep -E '\| Defer \|.*\bU2\b' docs/reviews/override-log.md` matches 26 rows. "About twenty" understates that. Precise version: "about twenty-five".

**Evidence:** `git log -1 900c47d0`; `git show main:docs/reviews/override-log.md`

---

## Claim 20: U2a1 bullet "`main_entry`'s `badform` word with one shared reason mapping, `entry_why` ...; one spelling of the closed/ rule, `isclosed` ...; `check_fix` also refuses `docs/constraints.md` (row 204: the user writes it, D2; `docs/thoughts/` stays fixable in-cycle ...)"

**Location:** `docs/working/plan-build-loop-handoff.md:274`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each named change against the code and plan D2; does not cover the U2a2/U2b/U2c bullets (future work).
**Legibility-target:** for-orchestrator-synthesis

The changes are `if ! pathform "$1"; then echo badform; return; fi` (`scripts/lib/dev-cycle-read.sh:267`), `entry_why()` (`:286`), used by all three callers (`:358`, `:576`, `scripts/build-loop.sh:133`), and `isclosed()` (`:158`). check_fix adds `"$lp" == docs/constraints.md` (`scripts/dev-cycle.sh:180`). Plan D2 says "Creating the doc is your work" (`docs/working/plan-build-loop-handoff.md:50`).

**Evidence:** cited lines

---

## Claim 21: Q-119 "Split recorded in the U2a rubric and commit e8f76379 on `feat/build-loop-u2a`"

**Location:** `docs/working/questions.md:391`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the commit and rubric references; does not judge the options.
**Legibility-target:** for-orchestrator-synthesis

`git log -1 e8f76379` gives `docs(reviews): U2a iteration 3 (final pass, k=3) and the iteration-4 gate decision: split`, and `git branch --contains` lists `feat/build-loop-u2a`. That branch's rubric has `### Iteration-4 gate decision: split` at :69, with the U2a1 contents at :74.

**Evidence:** `git show feat/build-loop-u2a:docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md:69-74`

---

## Claim 22: "Markup that adds letters (a checked task box, a tag) can still hide a copy"

**Location:** `scripts/build-loop.sh:44-46`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers SETTINGS_AWK's copy count for a `[x]` box; does not cover other markup.
**Legibility-target:** for-orchestrator-synthesis

`s = tolower($0); gsub(/[^a-z]/, "", s)` then `if (index(s, "buildlooppolicy") == 1)` (`scripts/build-loop.sh:155-156`). `- [x] Build-loop policy:` folds to `xbuildlooppolicy` and is missed, while `- [ ]` folds to `buildlooppolicy` and is counted, as `:18-20` says. The test at `test/scripts/build-loop-read.bats:118-120` pins the checked-box case.

**Evidence:** `scripts/build-loop.sh:150-164`; `test/scripts/build-loop-read.bats:118-120`

---

## Claim 23: "A tip on a branch not ahead of main, or whose subject does not start 'handoff:', is working"

**Location:** `scripts/build-loop.sh:65-66`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers status_line's loop state for `ahead` 0; does not cover how check_branch counts `ahead`.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/build-loop.sh:352-361
  loop=working
  if [[ "$ahead" -gt 0 ]]; then
    kind="$(marker_kind "$sha")"
    ...
  fi
  echo "ok $a $st $pol $br $loop $sha $date $disp$reason"
```

(excerpt elides :355-359, the marker case; status_line() ends :362 — read). `ahead` is check_branch's count of the branch's commits not on the default branch, so a branch behind main or level with it is also 0, which fits "not ahead".

**Evidence:** `scripts/build-loop.sh:325-362`

---

## Claim 24: main_file "returns 1 with FILE_WHY 'absent' or why it was not read (main_entry, ...)", now worded by `entry_why "$e" "$f"`

**Location:** `scripts/build-loop.sh:122-134`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each non-blob word's FILE_WHY and its two consumers; does not cover the error reason through --settings (untested, Claim 16).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/build-loop.sh:129-134
  e="$(main_entry "$f")"
  case "$e" in
    blob) ;;
    absent) FILE_WHY=absent; return 1 ;;
    *) FILE_WHY="$(entry_why "$e" "$f")"; return 1 ;;
  esac
```

(excerpt ends :134; main_file() continues to :141 — read). Both consumers read only `absent` as missing, and every other value is a refusal: `[[ "$FILE_WHY" == absent ]] && why="no $f ..." || why="$FILE_WHY"` (`:214`) and `constraints unreadable: $FILE_WHY` (`:265`). Mutant E2 `mainfile-why` (passing "") fails T3 and T44, which pin `docs/dev-cycle.md is not a regular file on the default branch` (`test/scripts/build-loop-read.bats:61,193`).

**Evidence:** `scripts/build-loop.sh:122-141`, `:210-218`, `:262-266`; `$FC/logs/mut-mainfile-why.log`

---

## Claim 25: shared_branches' `isbrief "$f" || isclosed "$f"` is the old `isbrief "${f/#docs\/working\/briefs\/closed\//docs/working/briefs/}"`

**Location:** `scripts/build-loop.sh:318`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the predicate's truth value over 110 constructed paths and the T28 test; does not cover git grep's listing.
**Legibility-target:** for-orchestrator-synthesis

E3 compared the old substitution with `isbrief || isclosed` over 10 prefixes × 11 names: `cases=110 diffs=0`. The names included closed/closed/, closedx/, Closed/, a doubled slash, a trailing newline and a nested name. Mutant E2 `shared-isclosed` (`isbrief "$f"` alone) fails T28 (`not ok 16 --status: two open briefs naming one branch both skip`).

**Evidence:** `$FC/equiv.sh`, `$FC/logs/isclosed-equiv.log`, `$FC/logs/mut-shared-isclosed.log`

---

## Claim 26: --check-fix header: not "... dev-cycle.md, constraints.md, a dot-directory or dotfile, an instruction file, or a file an instruction file imports with @; compared ignoring case"

**Location:** `scripts/dev-cycle.sh:50-55`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers constraints.md in any case and docs/thoughts/ fixable; does not re-verify the paragraph's other pre-existing items.
**Legibility-target:** for-orchestrator-synthesis

`lp` is the path lower-cased by `tr` (`scripts/dev-cycle.sh:175`), and the condition tests `"$lp" == docs/constraints.md` (`:180`). E1's run of `test/scripts/dev-cycle.bats:1016` expects `skip docs/Constraints.md: in-cycle fixes edit only` and `ok docs/thoughts/t.md`. Mutant E2 `constraints` (that condition removed) fails it.

**Evidence:** `scripts/dev-cycle.sh:170-184`; `$FC/logs/mut-constraints.log`

---

## Claim 27: "An in-cycle fix edits documentation only; the header's --check-fix paragraph is the rule, and the skip messages below repeat it. constraints.md is the user's (plan D2); docs/thoughts/ stays fixable."

**Location:** `scripts/dev-cycle.sh:167-169`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the agreement of header, skip messages, SKILL.md and code; does not cover check_path's own skip lines. The messages leave out "compared ignoring case", which the header states.
**Legibility-target:** for-orchestrator-synthesis

The three skip messages in check_fix are `one of the cycle's own files`, the list `(not working/, human-author/, reviews/, decisions/, dev-cycle.md, constraints.md, dot-directories or dotfiles, or instruction files) and README.md` and `an instruction file imports it with @` (`scripts/dev-cycle.sh:178-182`). Together they cover the header paragraph's items (`:50-55`). Plan D2 includes "Creating the doc is your work" (`docs/working/plan-build-loop-handoff.md:50`).

**Evidence:** `scripts/dev-cycle.sh:50-55`, `:167-184`

---

## Claim 28: "A change here must pass test/scripts/dev-cycle.bats and build-loop.sh's suites (build-loop-*.bats)"

**Location:** `scripts/lib/dev-cycle-read.sh:10-11`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the named suites exist and source the lib; does not name fixture-git-env.bats, which runs one test of each.
**Legibility-target:** for-orchestrator-synthesis

`rg --files test -g 'build-loop-*.bats'` lists only `test/scripts/build-loop-read.bats`. That suite loads `../lib/build-loop-fixtures`, whose `BL="$REPO_ROOT/scripts/build-loop.sh"` sources the lib.

**Evidence:** `test/lib/build-loop-fixtures.bash:10`; `scripts/build-loop.sh:92-95`

---

## Claim 29: isclosed spells the closed/ rule once for writable, check_brief and shared_branches, equal to the three old spellings

**Location:** `scripts/lib/dev-cycle-read.sh:158-162`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers equality with writable's and check_brief's old regex and shared_branches' substitution over 110 paths; does not cover paths with characters pathform refuses (writable is called after pathform).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/lib/dev-cycle-read.sh:158
isclosed() { [[ "$1" == docs/working/briefs/closed/* ]] && isbrief "docs/working/briefs/${1#docs/working/briefs/closed/}"; }
```

E3 compared `old_closed` (the removed regex `^docs/working/briefs/closed/$DIGIT{4}-$DIGIT{2}-$DIGIT{2}-$SLUG\.md$`) with isclosed: 0 differences. SLUG has no `/`, so the stripped rest must be exactly one brief name.

**Evidence:** `scripts/lib/dev-cycle-read.sh:153-162`; `$FC/logs/isclosed-equiv.log`

---

## Claim 30: main_entry prints "blob", "absent", "notfile", "notdir PART", "badform" (a path pathform refuses) or "error" (no default branch found by name, ls-tree failed, or the tree lists a name twice)

**Location:** `scripts/lib/dev-cycle-read.sh:246-256`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each arm of main_entry and badform's no-git path; does not re-test ls-tree failure (pre-existing).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/lib/dev-cycle-read.sh:266-268
  if ! main_by_name; then echo error; return; fi
  if ! pathform "$1"; then echo badform; return; fi
  while [[ "$rest" == */* ]]; do p="${p:+$p/}${rest%%/*}"; rest="${rest#*/}"; want+=("$p"); done
```

(excerpt ends :268; main_entry() continues to :280 with ls-tree, the dup check and the notdir/absent/blob/notfile arms — read). main_by_name is `[[ -n "$MAIN_SHA" && -n "$MAIN_BY_NAME" ]]` (`:247`) and pathform is pure bash (`:140-149`), so badform runs no git. E1's test `:1356` expects `absent` for `x`, then `badform` ×6, including `.gitattributes` and `.github/x.yml`. Mutant `badform-error` fails it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:243-280`; `$FC/logs/mut-badform-error.log`

---

## Claim 31: "Only blob reads the file, and only absent means there is none: every other word is a refusal"

**Location:** `scripts/lib/dev-cycle-read.sh:256-257`
**Type:** Invariant / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every main_entry caller (check_brief, check_answer, brief_fields, main_file) and the two that reach them (status_line, shared_branches); does not cover callers U2a2 will add.
**Legibility-target:** for-orchestrator-synthesis

- check_brief: `absent) echo "ok $a new"`, `blob) ;;`, `*) echo "skip $a: $(entry_why "$e" "")"; return` (`:355-359`).
- check_answer: `absent) continue`, `blob) ;;`, `*) echo "skip ..."; return` (`:574-577`).
- brief_fields: `[[ "$(main_entry "$1")" != blob ]]` gives `BRIEF_ODD=error; return 1` (`:316`), so it refuses absent too, which the invariant allows.
- main_file: `blob`, `absent`, `*` as in Claim 24.
- status_line runs check_brief first and passes on any non-`ok ` line (`scripts/build-loop.sh:328-329`). shared_branches skips any brief brief_fields refuses (`:318`).

No caller reads a blob for any other word.

**Evidence:** `scripts/lib/dev-cycle-read.sh:310-330`, `:341-381`, `:567-595`; `scripts/build-loop.sh:126-141`, `:305-362`

---

## Claim 32: "It runs main_by_name, then pathform, itself, before any read (so with no default branch even a refused form answers error; pathform also means ls-tree prints the name unquoted)"

**Location:** `scripts/lib/dev-cycle-read.sh:257-260`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the guard order and its test; the "unquoted" clause rests on pathform's character set (no quote-forcing characters) and was not re-executed.
**Legibility-target:** for-orchestrator-synthesis

The order is at `:266-267` (Claim 30). The test's last call `MAIN_SHA=""; main_entry .gitattributes` expects `error` (`test/scripts/dev-cycle.bats:1359,1368`). Mutant E2 `guard-order` (lines swapped) makes it print `badform` and the test fails.

**Evidence:** `scripts/lib/dev-cycle-read.sh:263-268`; `$FC/logs/mut-guard-order.log`

---

## Claim 33: entry_why: "$2 is the path asked about, or "" when the skip line already names it: notfile and badform make it the subject ("$2 is not ..."; no subject when ""), error and any other word end "for $2", and notdir names only the directory above it. A newline in either becomes a space, so the reason stays one line."

**Location:** `scripts/lib/dev-cycle-read.sh:281-285`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every arm with a path, with "", with one argument under `set -u`, and the path's newline folding. The comment does not say that "" also drops "for" on error and the default arm (the code does). The word's folding is untested (Claim 16).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/lib/dev-cycle-read.sh:286-295
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

E1's test `:1338` pins all ten two-argument lines and `a ok b is not an allowed path form`. E5 at HEAD: one-argument calls print `not a regular file on the default branch`, `the tree of the default branch could not be read`, `a is not a directory ...`, `not an allowed path form`, exit 0. Mutant `why-path-nl` fails the test. Mutant `why-2-unbraced` (`p="$2"`) passes all 94 tests, because no caller passes one argument.

**Evidence:** `test/scripts/dev-cycle.bats:1338-1354`; `$FC/logs/a8-d48.log`, `$FC/logs/mut-why-path-nl.log`, `$FC/logs/mut-why-2-unbraced.log`

---

## Claim 34: check_brief uses isclosed and words main_entry refusals by `entry_why "$e" ""`

**Location:** `scripts/lib/dev-cycle-read.sh:348`, `:358`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the notfile line through the CLI; check_brief's notdir and error lines through the CLI are untested (C9). badform is unreachable here because `:347` runs pathform first.
**Legibility-target:** for-orchestrator-synthesis

`if ! pathform "$a"; then echo "skip ...: not an allowed path form"; return; fi` (`:347`) runs before main_entry, so check_brief never gets badform. `*) echo "skip $a: $(entry_why "$e" "")"; return ;;` (`:358`) prints `skip docs/working/briefs/2026-01-01-s.md: not a regular file on the default branch`, which `test/scripts/dev-cycle.bats:1042` expects. Mutant E2 `brief-why` (passing `"$a"`) fails test 55.

**Evidence:** `scripts/lib/dev-cycle-read.sh:341-381`; `$FC/logs/mut-brief-why.log`

---

## Claim 35: SKILL.md: --check-fix prints ok for "a tracked .md file under docs/ (not ... docs/dev-cycle.md, docs/constraints.md, a dot-directory or dotfile, an instruction file, or a file an instruction file imports with @; compared ignoring case)"

**Location:** `skills/dev-cycle/SKILL.md:72-76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the agreement with check_fix and the header; does not cover the rest of SKILL.md.
**Legibility-target:** for-orchestrator-synthesis

The list matches the header (`scripts/dev-cycle.sh:50-55`) and the condition `:179-180`, including `"$lp" == docs/constraints.md`.

**Evidence:** `skills/dev-cycle/SKILL.md:72-76`; `scripts/dev-cycle.sh:179-182`

---

## Claim 36: bl_setup "An inherited GIT_DIR ... would send every fixture command to that repo ...; git lists every such repo-local variable itself (GIT_CONFIG_PARAMETERS too)"

**Location:** `test/lib/build-loop-fixtures.bash:11-15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the variable list and the unset's effect for one test; does not cover variables git does not list (e.g. GIT_CEILING_DIRECTORIES).
**Legibility-target:** for-orchestrator-synthesis

E7 printed the list: `GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_CONFIG GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT GIT_OBJECT_DIRECTORY GIT_DIR GIT_WORK_TREE ... GIT_INDEX_FILE ... GIT_COMMON_DIR`. With `GIT_DIR=/nonexistent/x`, `git rev-parse --local-env-vars` still prints 16 names, exit 0. Without the line, a victim gains 5 commits (Claim 5).

**Evidence:** `$FC/logs/c8.log`; `$FC/logs/a10c-summary.log`

---

## Claim 37: "A marker whose message body holds a NUL byte (one commit on top of base, with its tree)."

**Location:** `test/scripts/build-loop-read.bats:297`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the object the next line builds; does not cover how check_branch counts it.
**Legibility-target:** for-orchestrator-synthesis

`printf 'tree %s\nparent %s\n...' "$(git rev-parse "$base^{tree}")" "$base"` (`:298`) gives a commit whose parent is base and whose tree is base's.

**Evidence:** `test/scripts/build-loop-read.bats:296-301`

---

## Claim 38: The split fixture chains, with a standalone `git replace -d` (row 317)

**Location:** `test/scripts/build-loop-read.bats:436-440`, `:466-475`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three chains row 317 named; `:84` keeps its chain (C10).
**Legibility-target:** for-orchestrator-synthesis

`git replace ...` and `git config core.useReplaceRefs true` are now separate lines (`:436-437`), followed by `git replace -d "$(git rev-parse main:docs/dev-cycle.md)"` (`:440`). The `brief p ...`/`printf`/`commit_all crlf` chain and the `mkdir`/`printf`/`commit_all odd-dir` chain are now one command per line (`:466-468`, `:473-475`). E1: build-loop-read 19/19.

**Evidence:** `test/scripts/build-loop-read.bats:430-441`, `:460-480`; `$FC/logs/suite.log`

---

## Claim 39: dev-cycle.bats setup "As bl_setup: an inherited GIT_DIR would send fixture commits to that repo."

**Location:** `test/scripts/dev-cycle.bats:11-13`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one filtered test with GIT_DIR+GIT_INDEX_FILE set; does not cover every test's side effects.
**Legibility-target:** for-orchestrator-synthesis

Without the line, one test added 7 commits to the victim (E6), and mutant `unset-dc` fails fixture-git-env test 1 (E2). With it, fixture-git-env passes (E1).

**Evidence:** `$FC/logs/a10c-summary.log`, `$FC/logs/mut-unset-dc.log`

---

## Claim 40: test "--check-fix refuses files an instruction file imports ..." with "# docs/constraints.md is the user's (plan D2); docs/thoughts/ stays a living doc the cycle may fix."

**Location:** `test/scripts/dev-cycle.bats:1016-1032`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two new paths; does not cover docs/thoughts/ files that an instruction file imports (refused by the import arm).
**Legibility-target:** for-orchestrator-synthesis

The test expects `"skip docs/Constraints.md: in-cycle fixes edit only" "ok docs/thoughts/t.md"` (`:1029`). It passes at HEAD (E1) and fails on mutant `constraints` (E2).

**Evidence:** `$FC/logs/suite.log`, `$FC/logs/mut-constraints.log`

---

## Claim 41: test "entry_why words each main_entry refusal on one line, naming the path only when given (U2a1)"

**Location:** `test/scripts/dev-cycle.bats:1338-1354`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the path argument's folding and all arms; the word's folding survives its mutant (C9, accepted).
**Legibility-target:** for-orchestrator-synthesis

The test passes at HEAD and fails on `why-path-nl` (E2). `why-word-nl` survives, as row C9 says.

**Evidence:** `$FC/logs/mut-why-path-nl.log`, `$FC/logs/mut-why-word-nl.log`

---

## Claim 42: test "main_entry answers badform for a path pathform refuses, absent for a plain missing one (U1d, U2a1)" and its comment "The last line: with no main found by name, even a refused form answers error (the header's order)."

**Location:** `test/scripts/dev-cycle.bats:1356-1369`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the positive control (row 320), the badform words and the guard order; does not cover notdir/notfile (other tests).
**Legibility-target:** for-orchestrator-synthesis

The test fails on `badform-error` (all six refused forms print `error`) and on `guard-order` (the last line prints `badform`) (E2). The first expected line `absent` for `x` is the positive control.

**Evidence:** `$FC/logs/mut-badform-error.log`, `$FC/logs/mut-guard-order.log`

---

## Claim 43: test "a closed brief is a closed/ path only: a brief-shaped name elsewhere is neither writable nor a brief (U2a1)"

**Location:** `test/scripts/dev-cycle.bats:1371-1378`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the prefix-guard mutant; of the three paths, only the bare `2026-01-01-x.md` distinguishes the mutant (closedx/ and docs/ are refused by both).
**Legibility-target:** for-orchestrator-synthesis

See Claim 6: the test fails on `isclosed-prefix`, with `# ok 2026-01-01-x.md` in the output.

**Evidence:** `$FC/logs/mut-isclosed-prefix.log`

---

## Claim 44: fixture-git-env.bats: "One test of each suite runs here with both pointed at a victim repo"; victim_unchanged "The inner run must have run one test and passed, or this proves nothing"; `# @category fast`

**Location:** `test/scripts/fixture-git-env.bats:1-32`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the filters (one match each), pass at HEAD, failure on each unset mutant, runner and lint pickup, and per-test time under 1 s; does not cover running the suite through scripts/run-tests.sh itself (it writes .bats/ in the repo, which this pass may not modify).
**Legibility-target:** for-orchestrator-synthesis

- `grep -c 'prints all eight sections' test/scripts/dev-cycle.bats` gives 1 (`@test` at :40). `exact policy line is set` matches only `test/scripts/build-loop-read.bats:13`.
- `victim_unchanged` requires `[ "$status" -eq 0 ] && [[ "$output" == *"1..1"*"ok 1 "* ]]` (`:19`). `"ok 1 "` also matches `not ok 1`, but a failing inner test exits nonzero, so the status check covers that case.
- At HEAD both tests pass (E1, E8: 412 ms and 466 ms). `unset-dc` fails only test 1 and `unset-bl` only test 2 (E2).
- scripts/run-tests.sh picks up every `.bats` under test/ (`find "$TEST_DIR" -name '*.bats'`, `scripts/run-tests.sh:213`), and the file carries `# @category fast` (`:2`).
- The hermeticity lint's bash globs are `test/**/*.bats` (`scripts/hermeticity/adapters/bash.json:5`). E9 reports `"bash": 127`, which equals `rg --files test -g '*.bats' | wc -l`, so this file is among those scanned, with no findings.

**Evidence:** `test/scripts/fixture-git-env.bats:1-32`; `$FC/logs/suite.log`, `$FC/logs/fge-timing.log`, `$FC/logs/herm.json`, `$FC/logs/mut-unset-*.log`

---

## Claim 45: commit 91469367 body: the bullets, "Tests: dev-cycle.bats 75, build-loop-read.bats 19, fixture-git-env.bats 2, hermeticity 2: 98/98 ... shellcheck clean. The G1 and G2 tests each fail on their mutant." and Notes "the G1 suite runs bats inside bats (about 2 s)"

**Location:** commit 91469367 message
**Type:** Reference / Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers every bullet, the counts and the mutants (all hold) and the Notes timing (does not hold here). Split not used: the timing is the only divergent atom and is a Notes aside.
**Legibility-target:** for-author

All bullets hold against the code (Claims 3, 7, 32, 33, 43, 44). The counts are 75+19+2+2 = 98 (E1), shellcheck is clean (E10), and G1/G2 fail on their mutants (E2). The Notes' "about 2 s" does not match E8 here: the whole fixture-git-env file ran in 0.71 s and 0.73 s wall (412 ms + 466 ms per test). The figure is host-dependent and roughly 3× high on this host. Commit history: no fix is possible, so an Accepted-immutable row fits.

**Evidence:** `git log -1 91469367`; `$FC/logs/fge-wall.log`, `$FC/logs/fge-timing.log`

---

## Claim 46a: commit d07cc89c "0 Must Fix, 0 Incorrect (53 merged claims, 88.7% replicate agreement)", "Four declined findings get override rows (C7-C10)", Notes "The merge kept claims 21b and 41a Verified where a replicate's compound verdict blamed only the sibling part"

**Location:** commit d07cc89c message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the figures and row counts; does not re-judge the merge decision.
**Legibility-target:** for-orchestrator-synthesis

The figures match the merged report (Claim 2). Override-log rows `:327-330` are C7-C10. The merged report's Decisions bullet says it recorded those two verdicts `as (compound; carried by …)` and did not let them set the sub-claim's verdict.

**Evidence:** `docs/reviews/override-log.md:327-330`; merged report :1143 at d07cc89c

---

## Claim 46b: commit d07cc89c "the C4 row's timings are corrected to the re-measured range"

**Location:** commit d07cc89c message
**Type:** Reference / Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Same finding as Claims 8 and 12, as stated in the commit; does not establish other hosts' timings.
**Legibility-target:** for-author

The row now says `0.3-0.5 ms, by host` and `~17-37 µs` (`docs/reviews/override-log.md:325`), while the rubric's re-measured range is `0.42-0.52 ms, 18-37 µs` (rubric `:31`). The row's range spans iteration 1 and iteration 2 rather than the re-measured range. The figures I measured, 0.48-0.54 ms and 19-21 µs, sit near its top. Commit history: no fix possible.

**Evidence:** `docs/reviews/override-log.md:325`; `$FC/logs/timing.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 18** (`docs/working/plan-build-loop-handoff.md:125`): F10 lists `docs/thoughts/` among "the docs check_fix denied", but check_fix allows it (pinned by `dev-cycle.bats:1029`), and the same plan's U2a1 note (`:274`) says they differ on purpose. This line predates the branch. Reword to "the docs check_fix denies plus docs/thoughts/ and constraints.md".

### Stale
- **Claim 10** (`docs/reviews/override-log.md:322`): the C1 row cites `scripts/dev-cycle.sh:181-183`; since d48f4645 the condition and skip message are at `:179-181`.

### Mostly Accurate
- **Claim 4** (`docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:21`): A8's "printed an empty reason" holds only when the call is spliced into a line. Assigned (main_file's form), d48f4645's one-argument call ended the shell (exit 1).
- **Claim 8** (`docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:31`): C11's measured range (0.42-0.52 ms) is not what the "corrected" row says (0.3-0.5 ms, the union with iteration 1).
- **Claim 12** (`docs/reviews/override-log.md:325`): the subshell cost re-measured at 0.48-0.54 ms, at or above the row's 0.5 ceiling. The 0.3 floor is iteration 1's. The conclusion holds.
- **Claim 19** (`docs/working/plan-build-loop-handoff.md:273`): "about twenty override rows" for U2, but 26 Defer rows on main name U2.
- **Claim 45** (commit 91469367): Notes "about 2 s" for fixture-git-env; measured 0.71-0.73 s wall here. Every other part holds.
- **Claim 46b** (commit d07cc89c): "corrected to the re-measured range". The row's range is the iteration 1 and 2 union, not the re-measured range.

### Unverifiable
(none)

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved at the replicate path named below (inside the worktree), structured per the code-fact-check skill, with `Commit: d07cc89c` as its first line.
- Answered: yes. All nine focus areas are verdicted, and the behavioural ones were executed: the suites (98/98), 13 mutants, isclosed equivalence (110 paths), the A10 victim counts, entry_why with one argument at d48f4645 and HEAD, timings, and the lint scan.
- Out of scope: U2a2/U2b/U2c plan bullets (future work); other docs/reviews/*.md artifacts; earlier commits' message claims (Accepted-immutable); running scripts/run-tests.sh itself (it writes .bats/ in the repo).
- Escalate: nothing blocking. Claim 18 is a pre-existing plan line outside the diff that now contradicts the diff's own `:274`. Claims 8/12/46b are one timing-wording item. Claim 10 is a line-number drift in an override row.
- Decisions I made: verdicted plan `:125` although it is outside the diff, because it describes check_fix, the scoped code, and contradicts the new `:274`. Treated one 15 ms cold `rev-parse` loop as an outlier against three ~1 ms runs. Mutant `why-2-unbraced` surviving is reported as a scope note, not a gap: no caller passes one argument.
