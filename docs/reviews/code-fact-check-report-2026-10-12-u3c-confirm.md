Commit: 0f0c7e1c
**Replication:** k=1 (confirming pass after the loop cap; Q-137 precedent)

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3c (branch feat/build-loop-u3c)
**Scope:** PARTIAL: `git diff 4aad0f9c..0f0c7e1c` minus docs/reviews outputs (scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-orchestrator.bats, test/scripts/health-check-lock.bats, docs/working/plan-build-loop-handoff.md As-built note, docs/reviews/override-log.md row 745), commit 0f0c7e1c's message, plus five submitted claims. The rest of the branch (`main..4aad0f9c`) is context only.
**Checked:** 2026-10-12 (runs 2026-10-13T06:47Z to 06:53Z UTC)
**Total claims checked:** 27
**Summary:** 23 verified, 4 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination pattern log (`docs/reviews/hallucination-patterns.md`, 8 entries) read first; no claim below matches a logged pattern (all logged entries are corpus or test-count statistics; the one count claim here, "396 code lines", was executed).

Execution provenance: the brief allows this report as the only repo write, so captured output lives in the agent scratch dir `S=/tmp/claude-1000/-workspace/f335f5f6-1b17-4519-891d-602641cba507/scratchpad/fc-u3c-confirm/`, not in `docs/reviews/execution-logs/`. Every probe ran from scratch copies (`git archive HEAD` or a `git clone` under `$S/p-*`); the worktree was not modified.

| Run | Command (cwd) | Exit | Time (UTC) | Output |
|---|---|---|---|---|
| E1 | `TMPDIR=$(mktemp -d /tmp/u3c-fcc-XXXX) bats test/scripts/build-loop-orchestrator.bats` (worktree) | 0 (24/24 ok) | 06:47:12 | `$S/bats-orch.log` |
| E2 | `bash $S/mutants.sh` (scratch archives of HEAD; T38 filter) | 0; each mutant's bats exit 1 | 06:48:09 | `$S/mutant-no-all.log`, `$S/mutant-no-whole.log`, `$S/mutant-index-only.log` |
| E3 | `bash $S/probe-answer.sh` (scratch) | 0 | 06:48:46 | `$S/probe-answer.log` |
| E4 | `python3 -I $S/fuzz.py $S/fuzz-run 7 2000`; `... $S/fuzz-run2 23 3000` | 0, 0 | 06:51:08 | `$S/fuzz.out`, `$S/fuzz2.out`, `$S/fuzz-run*/fuzz.log` (empty: no violation) |
| E5 | `bash $S/perf.sh` (scratch clone of the worktree) | 0 | 06:52:57 | `$S/perf.log` |
| E6 | `TMPDIR=$(mktemp -d /tmp/u3c-fcc-XXXX) bats test/scripts/health-check-lock.bats` (worktree) | 0 (2/2 ok) | 06:53:15 | `$S/bats-lock.log` |
| E7 | `git diff --numstat main...HEAD -- . ':!docs'` (worktree) | 0 | 06:52 | inline below (claim 21) |

Mutants in E2 (perl substitutions on `scripts/build-loop.sh` in a scratch archive): **no-all** drops `--all` from `git merge-base`; **no-whole** replaces the ANSWER_AWK whole-copy refusal with `:`; **index-only** adds `|| $p == o` so only the index copy is judged.

---

## Claim 1: "Two classes are U4 duties now ...: a chore commit that changes GATE_CODE (the readers that decide what an answer is) and a brief's `Asked:` line pointed at a different ID ... must be refused or listed for the user by U4's step 9"

**Location:** `docs/reviews/override-log.md:745`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that --cycle-diff judges neither GATE_CODE paths nor brief files and that GATE_CODE holds the answer reader; does not establish what U4 will do (not built) or that a retargeted `Asked:` line reuses a keep end to end (read from the security report, not re-run).

cycle_diff judges only four paths and skips everything else: `docs/roadmap.md|docs/working/idea-log.md) ;;` then `*) continue ;;` (`scripts/build-loop.sh:1820-1822`). GATE_CODE is `'^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/'` (`scripts/lib/dev-cycle-read.sh:1962`), and `scripts/lib/` holds ANSWER_AWK and check_answer (`scripts/lib/dev-cycle-read.sh:2062`, `:2131`). `Asked:` is a brief field the lib reads (`scripts/lib/dev-cycle-read.sh:421`: `"Paths:", "Asked:" or "Dispatched:"`). A brief path (`docs/working/briefs/*.md`) is not among the four judged paths, so a changed `Asked:` line is not judged.

**Evidence:** `scripts/build-loop.sh:1817-1823`, `scripts/lib/dev-cycle-read.sh:421`, `scripts/lib/dev-cycle-read.sh:1962`, `docs/reviews/security-review-2026-10-12-u3c-final.md:122`

---

## Claim 2: "BASE is the single merge base of HEAD and MAIN_SHA; none (`refuse HEAD`) or several (a criss-cross history the land would merge through a virtual base ...; `refuse HEAD`, merge main first)"

**Location:** `docs/working/plan-build-loop-handoff.md:333`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the none and several cases of `git merge-base --all` and their refusal text, executed in T38 and by mutant; does not re-run the security reviewer's virtual-base laundering reproduction (claim 18).

```bash
# scripts/build-loop.sh:1808-1810
  if ! base="$(git merge-base --all HEAD "$MAIN_SHA" 2>/dev/null)" || [[ -z "$base" ]]; then echo "refuse HEAD: it shares no commit with the default branch's $MAIN_SHA, or could not be read"; return 1; fi
  # The land merges through a virtual base when there are several (criss-cross): judge none (final security F1).
  [[ "$base" != *$'\n'* ]] || { echo "refuse HEAD: it has more than one merge base with the default branch's $MAIN_SHA; merge the default branch into HEAD first"; return 1; }
```
(excerpt ends :1810; enclosing cycle_diff continues to :1872 — read)

E1: T38 passes with its criss-cross case (`test/scripts/build-loop-orchestrator.bats:434-437`). E2 mutant no-all: T38 goes red at that case with `status 0` / `ok` instead of the refusal (`$S/mutant-no-all.log`).

**Evidence:** `scripts/build-loop.sh:1806-1810`, `test/scripts/build-loop-orchestrator.bats:434-437`, `$S/bats-orch.log`, `$S/mutant-no-all.log`

---

## Claim 3: "A questions change refuses while main's questions files differ from BASE's (`refuse docs/working/questions.md: the default branch changed ...; merge it into HEAD`), and a failed listing is `refuse index`"

**Location:** `docs/working/plan-build-loop-handoff.md:333`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the main-changed refusal (executed, exact text pinned by T38) and the failed-listing branch (static: an ls-tree failure was not induced); does not establish anything for roadmap or idea-log changes, which this rule does not cover (only reached when a questions file is staged, `:1835`).

```bash
# scripts/build-loop.sh:1840-1842
  gate_git ls-tree -z "$base" -- docs/working/questions.md docs/working/questions-archive.md > "$t.lb" \
    && gate_git ls-tree -z "$MAIN_SHA" -- docs/working/questions.md docs/working/questions-archive.md > "$t.lm" || { echo "refuse index: the questions files could not be listed"; return 1; }
  cmp -s "$t.lb" "$t.lm" || { echo "refuse docs/working/questions.md: the default branch changed the questions files since the fork point $base; merge it into HEAD, then stage again"; return 1; }
```
(excerpt ends :1842; enclosing cycle_diff continues to :1872 — read)

`A && B || refuse` refuses when either listing fails (the `||` binds to the whole `&&` list); `cmp` failure is the only path to the main-changed text. T38 pins that text (`test/scripts/build-loop-orchestrator.bats:429`), passing in E1.

**Evidence:** `scripts/build-loop.sh:1835-1842`, `test/scripts/build-loop-orchestrator.bats:429`, `$S/bats-orch.log`

---

## Claim 4: "A copy `--check-answer` skips whole (FENCE_AWK's refusals, a fenced question heading) refuses; the verdict comes from the lib's ANSWER_AWK itself, run with id `Q-` ...; on BASE's side only a fix on main clears it"

**Location:** `docs/working/plan-build-loop-handoff.md:333`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both sides' whole-copy refusal (unbalanced and quoted index cases, quoted base case, all red under mutants) and that BASE's questions copies equal main's whenever this check runs; does not establish that "id `Q-`" matches no heading (it can: claim 13) or anything when no questions file is staged (the check is not reached).

```bash
# scripts/build-loop.sh:1856-1860
    for p in o n; do
      # The whole-file verdict from --check-answer's own reader (id Q- names no entry): FENCE_AWK's refusals and a fenced question heading.
      k=base; [[ "$p" == o ]] || k=index; md="$(LC_ALL=C awk -v id=Q- "$FENCE_AWK$ANSWER_AWK" "$t.$p")" || md="unread"
      [[ -z "$md" ]] || { echo "refuse $f: --check-answer refuses its $k copy whole ($md)"; return 1; }
      LC_ALL=C awk -v f="${f##*/}" "$FENCE_AWK$QKEYS_AWK" "$t.$p" >> "$t.q$p" || { echo "refuse $f: it could not be read"; return 1; }
```
(excerpt ends :1860; the loop closes at :1862, cycle_diff continues to :1872 — read)

The program string is the same `"$FENCE_AWK$ANSWER_AWK"` check_answer runs, also under `LC_ALL=C` (`scripts/lib/dev-cycle-read.sh:2141`). "Only a fix on main": by the time this loop runs, `cmp` at `:1842` has established BASE's questions listing equals MAIN_SHA's, and BASE can only move by merging main into HEAD (paraphrased — no quote available because this is an inference from the merge-base definition plus the `:1842` guard, not one line). E2: no-whole turns T38 red at the index-side `unbalanced 12` case; index-only turns it red at the base-side `quoted 2` case (`$S/mutant-*.log`).

**Evidence:** `scripts/build-loop.sh:1842-1862`, `scripts/lib/dev-cycle-read.sh:2141`, `test/scripts/build-loop-orchestrator.bats:425-433`, `$S/mutant-no-whole.log`, `$S/mutant-index-only.log`

---

## Claim 5: "A questions refusal's WHY starts with the entry's ID"

**Location:** `docs/working/plan-build-loop-handoff.md:333`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two per-entry refusals (gone, new); does not cover the other questions refusals, which carry no ID.

True for the per-entry lines: `echo "refuse docs/working/$f: $i's heading, Needs or answer lines changed ..."` and `... $i is a new entry filed answered ...` (`scripts/build-loop.sh:1867-1868`). Not true of the other refusals a questions change can get: `--check-answer refuses its $k copy whole ($md)` (`:1859`), `the default branch changed the questions files since the fork point $base` (`:1842`), `the entries could not be compared` (`:1864`). The header's own wording scopes it correctly ("a new entry filed answered ...; WHY starts with its ID", `scripts/build-loop.sh:197`). Precise version: "an entry refusal's WHY starts with its ID".

**Evidence:** `scripts/build-loop.sh:197`, `scripts/build-loop.sh:1842`, `scripts/build-loop.sh:1859`, `scripts/build-loop.sh:1864-1870`

---

## Claim 6: "`--answered` IDs match exactly, repeats and unused IDs are ignored"

**Location:** `docs/working/plan-build-loop-handoff.md:333`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the argument grammar and QDIFF_AWK's exact-string ok set; does not establish anything about recording the IDs (an override row's U4 duty).

`[[ "$1" == --answered && $# -ge 2 && "$2" =~ ^Q-[0123456789]+$ ]]` (`scripts/build-loop.sh:493`) admits only blank-free IDs; QDIFF builds `ok[x[i]] = 1` from the space-joined list (`scripts/build-loop.sh:1768`) and tests `id in ok` by string, so Q-14 is not Q-014 and repeats collapse; an unused ID is never looked up. T38 runs `cd_is ok --answered Q-003 --answered Q-001` with Q-003 unused (`test/scripts/build-loop-orchestrator.bats:405`), passing in E1.

**Evidence:** `scripts/build-loop.sh:490-495`, `scripts/build-loop.sh:1768-1775`, `$S/bats-orch.log`

---

## Claim 7: "Done is matched as dev-cycle.sh matches a section."

**Location:** `docs/working/plan-build-loop-handoff.md:333`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the heading test's three forms and CR/case handling; does not establish that dev-cycle.sh reads a Done section (it reads Next with the same rule).

ROADMAP_AWK: `{ sub(/\r$/, "") ...}` then `d = tolower($0); done[s] = (d == "## done" || index(d, "## done ") == 1 || index(d, "## done(") == 1)` (`scripts/build-loop.sh:1784-1785`); dev-cycle.sh: `sub(/\r$/, ""); t = tolower($0) } t == "## next" || index(t, "## next ") == 1 || index(t, "## next(") == 1` (`scripts/dev-cycle.sh:442`). Same rule.

**Evidence:** `scripts/build-loop.sh:1784-1785`, `scripts/dev-cycle.sh:442`

---

## Claim 8: "U4's duties are override rows dated 2026-10-12 on `feat/build-loop-u3c`."

**Location:** `docs/working/plan-build-loop-handoff.md:333`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the rows exist at the log's end with that date and branch; does not judge their content beyond claim 1.

Eight rows `| 2026-10-12 | \`feat/build-loop-u3c\` | ...` end the log (`docs/reviews/override-log.md:745-752`), naming U4 as revisit trigger (commit-takes-the-index, --answered unrecorded, hooks, lock wait, preamble date, compare-and-swap, row 722 re-key).

**Evidence:** `docs/reviews/override-log.md:745-752`

---

## Claim 9: "PATH is HEAD (no merge base, or several: merge main into HEAD), index (not listed) or the file."

**Location:** `scripts/build-loop.sh:189-190`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `refuse` PATH cycle_diff prints (HEAD, index, a judged file); does not establish that "not listed" is the only index reason word-for-word (the listing-failure texts differ: staged changes vs questions files).

The refusals' PATH values are `HEAD` (`:1808`, `:1810`), `index` (`:1814`, `:1841`) and a file path (all others in `scripts/build-loop.sh:1823-1868`). The several-bases case ran in E1/E2 (claim 2).

**Evidence:** `scripts/build-loop.sh:1806-1870`, `$S/bats-orch.log`

---

## Claim 10: "a copy it skips whole, FENCE_AWK's or a fenced question heading, refuses, and on BASE's side only a fix on main clears it"

**Location:** `scripts/build-loop.sh:192-194`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as claim 4 (header copy of it); does not cover the extra refusal a `### Q-` heading triggers (claim 13), which adds refusals and removes none.

See claim 4's quote of `scripts/build-loop.sh:1856-1860` and its executed mutants.

**Evidence:** `scripts/build-loop.sh:1842-1862`, `$S/mutant-no-whole.log`, `$S/mutant-index-only.log`

---

## Claim 11: "A file --check-answer skips whole is refused first, by ANSWER_AWK itself (final architecture 1)."

**Location:** `scripts/build-loop.sh:1743-1744`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that, per copy, the ANSWER_AWK verdict runs and refuses before QKEYS_AWK's output is appended, and that QKEYS_AWK no longer carries a fenced-heading or odd/unbalanced report; does not establish behaviour of QKEYS_AWK on a refused file (never consumed).

`md="$(LC_ALL=C awk -v id=Q- "$FENCE_AWK$ANSWER_AWK" "$t.$p")"` then `[[ -z "$md" ]] || { ...; return 1; }` precede `awk ... "$FENCE_AWK$QKEYS_AWK" "$t.$p" >> "$t.q$p"` (`scripts/build-loop.sh:1858-1860`). QKEYS_AWK's body (`:1746-1754`) now ends `print id "\t" f "\ta\t" $0 }` then `'`, with no END block.

**Evidence:** `scripts/build-loop.sh:1740-1754`, `scripts/build-loop.sh:1856-1860`

---

## Claim 12: "The land merges through a virtual base when there are several (criss-cross): judge none (final security F1)."

**Location:** `scripts/build-loop.sh:1809`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers that several bases refuse before any file is judged (executed) and git's documented recursive/ort behaviour; does not re-run the security reviewer's merge-tree laundering fixture.

The refusal at `scripts/build-loop.sh:1810` fires before the diff-index listing at `:1812`, so no path is judged. That the land would merge through a virtual base is git's ort/recursive behaviour with several merge bases (paraphrased — no quote available because it is git's merge strategy, not repo code); the security reviewer executed it: `git merge-tree --write-tree main chore gave a questions file for which the lib's FENCE_AWK+ANSWER_AWK reads keep` (`docs/reviews/security-review-2026-10-12-u3c-final.md:41`).

**Evidence:** `scripts/build-loop.sh:1808-1812`, `docs/reviews/security-review-2026-10-12-u3c-final.md:41`, `$S/mutant-no-all.log`

---

## Claim 13: "(id Q- names no entry)"

**Location:** `scripts/build-loop.sh:1857` (same claim: commit 0f0c7e1c body "id Q-, which names no entry")
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every heading in the questions grammar (`### Q-` plus digits) and both real questions files at HEAD and main; does not hold for a heading that is exactly `### Q-` or starts `### Q- ` / `### Q-<tab>`, where ANSWER_AWK reads an entry.

ANSWER_AWK's heading test is `return h == id || index(h, id " ") == 1 || index(h, id "\t") == 1` (`scripts/lib/dev-cycle-read.sh:2077-2081`), so with `id=Q-` a line `### Q-` or `### Q- note` is a heading. E3 executed it: `heading-Q-bare: rc=0 [keep|Q-]`, `heading-Q-space: rc=0 [open|Q- note]`, `heading-Q-twice: rc=0 [dup]` (`$S/probe-answer.log`). The effect fails closed: `md` is non-empty, so --cycle-diff refuses with `--check-answer refuses its index copy whole (open` / `Q- note)`, a two-line refusal for a copy --check-answer does not skip (check_answer only skips whole on odd, unbalanced or quoted, `scripts/lib/dev-cycle-read.sh:2145-2148`). No such heading exists in the real files (claim 26a). Precise version: "id Q- names no entry in the questions grammar (a heading `### Q-` or `### Q- ...` would be read as one and refuse)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:2077-2081`, `scripts/lib/dev-cycle-read.sh:2109-2115`, `scripts/build-loop.sh:1857-1859`, `$S/probe-answer.log`

---

## Claim 14: "--cycle-diff runs this program itself (id Q-) for the whole-file skips."

**Location:** `scripts/lib/dev-cycle-read.sh:2060`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the one call site in build-loop.sh; does not establish the "names no entry" property (claim 13).

`grep` finds ANSWER_AWK in build-loop.sh only at `md="$(LC_ALL=C awk -v id=Q- "$FENCE_AWK$ANSWER_AWK" "$t.$p")"` (`scripts/build-loop.sh:1858`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:2060`, `scripts/build-loop.sh:1858`

---

## Claim 15: "A criss-cross history (each side merged the other's older tip): the land would merge through a virtual base (final security F1)."

**Location:** `test/scripts/build-loop-orchestrator.bats:434`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the fixture builds two merge bases (main merges HEAD's c1; HEAD merges main's older tip M) and that the assertion matches the refusal; does not exercise a questions change under criss-cross (the refusal is unconditional).

```bash
# test/scripts/build-loop-orchestrator.bats:435-437
    git reset -q --hard; git commit -q --allow-empty -m c1; onmain x.md x; M="$(git rev-parse main)"
    git update-ref refs/heads/main "$(git commit-tree 'main^{tree}' -p main -p HEAD -m m2)"; git merge -q --no-edit "$M"
    cd_is "refuse HEAD: it has more than one merge base with the default branch's $(git rev-parse main); merge the default branch into HEAD first"
```
(excerpt ends :437; the test's last line, its closing brace at :438 — read)

E1 green; E2 no-all makes this exact assertion fail with `ok`, so the fixture has more than one base.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:434-438`, `$S/bats-orch.log`, `$S/mutant-no-all.log`

---

## Claim 16: the main-changed refusal text is pinned ("C4: ... the main-changed refusal's text is pinned")

**Location:** `test/scripts/build-loop-orchestrator.bats:429`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers byte equality of the refusal through `cd_is` (exact `$output`, empty stderr, exit 2); does not test the failed-listing branch.

`cd_is "refuse docs/working/questions.md: the default branch changed the questions files since the fork point $(git rev-parse HEAD); merge it into HEAD, then stage again" --answered Q-001` (`test/scripts/build-loop-orchestrator.bats:429`); `cd_is` asserts `[ "$output" = "$w" ]` (`:393`). E1 green.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:393`, `test/scripts/build-loop-orchestrator.bats:429`, `$S/bats-orch.log`

---

## Claim 17: "T43 (plan D14, U3c): health-check.sh runs one at a time per repository (a flock in the common git dir); each test copies it and its libs into a throwaway repo, check 5's runner stubbed."

**Location:** `test/scripts/health-check-lock.bats:3-4`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reworded header against setup() and take_lock; does not re-verify take_lock's other properties (context, verified in earlier passes).

setup copies `scripts/health-check.sh` and `scripts/lib/{log-format,md-utils,skill-paths}.sh` and exports `HEALTH_CHECK_RUN_TESTS="$BATS_TEST_TMPDIR/stub"` (`test/scripts/health-check-lock.bats:10-13`); take_lock reads `git ... rev-parse --path-format=absolute --git-common-dir` and runs `flock -n -E 75 -o "$lk" bash ...` (`scripts/health-check.sh:1107`, `:1113`). E6: both T43 tests ok.

**Evidence:** `test/scripts/health-check-lock.bats:1-14`, `scripts/health-check.sh:1097-1116`, `$S/bats-lock.log`

---

## Claim 18: "C2 (final security F1, reproduced): with a criss-cross history git merge-base picks one base while the land merges through a virtual one, which defeated the main-changed rule. merge-base --all; several refuse ('merge the default branch into HEAD first'). T38 case, red without it."

**Location:** commit 0f0c7e1c message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fix, its refusal text and "red without it" (E2 no-all); the "defeated" part rests on the security reviewer's executed fixture, not re-run here.

See claims 2, 12 and 15; "reproduced" matches `Executed in a fixture under my scratch dir (crisscross.sh): with two merge bases, --cycle-diff printed ok with no --answered` (`docs/reviews/security-review-2026-10-12-u3c-final.md:41`).

**Evidence:** `scripts/build-loop.sh:1808-1810`, `$S/mutant-no-all.log`, `docs/reviews/security-review-2026-10-12-u3c-final.md:41`

---

## Claim 19: "C3 ...: --cycle-diff now runs the lib's ANSWER_AWK itself (id Q-, which names no entry) for every whole-file skip; QKEYS_AWK keeps only key lines."

**Location:** commit 0f0c7e1c message
**Type:** Architectural / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the call (claim 14), QKEYS_AWK's trimmed body (claim 11) and the whole-file shapes (claim 26a); "names no entry" carries claim 13's qualifier.

Mechanism verified; the parenthetical "which names no entry" is false for a `### Q-` / `### Q- ...` heading (E3: `[open|Q- note]`), which fails closed.

**Evidence:** `scripts/build-loop.sh:1746-1754`, `scripts/build-loop.sh:1858`, `$S/probe-answer.log`

---

## Claim 20: "C4: a failed listing of the questions files is 'refuse index' ... C5: the plan's As-built note. C6: a BASE-side whole-copy refusal needs a fix on main (header). C7 (final security F2): row 722's re-key names GATE_CODE changes and a retargeted Asked: line as U4 duties."

**Location:** commit 0f0c7e1c message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that each named change is in the diff (`scripts/build-loop.sh:1841`, plan :333, header :193-194, log :745); content verdicts are claims 1, 3, 4, 10.

`|| { echo "refuse index: the questions files could not be listed"; return 1; }` (`scripts/build-loop.sh:1841`); header `or a fenced question heading, refuses, and on BASE's side only a fix on main clears it` (`:193-194`); plan `**As built (2026-10-12; ...` (`docs/working/plan-build-loop-handoff.md:333`); log `Two classes are U4 duties now, not later (final security F2)` (`docs/reviews/override-log.md:745`). The message does not mention the header compaction in `test/scripts/health-check-lock.bats` (an omission, not a false claim).

**Evidence:** `scripts/build-loop.sh:189-194`, `scripts/build-loop.sh:1841`, `docs/working/plan-build-loop-handoff.md:333`, `docs/reviews/override-log.md:745`

---

## Claim 21: "396 code lines."

**Location:** commit 0f0c7e1c message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers insertions plus deletions outside `docs/` over `main...HEAD` (the plan's row-62 measure); does not establish a non-blank or non-comment count.

E7 numstat: `214 29 scripts/build-loop.sh`, `31 0 scripts/health-check.sh`, `6 2 scripts/lib/dev-cycle-read.sh`, `75 0 test/scripts/build-loop-orchestrator.bats`, `39 0 test/scripts/health-check-lock.bats`; 365 + 31 = 396.

**Evidence:** E7 (inline numstat above)

---

## Submitted Claims

## Claim 22: "The whole-file skip refuses on either side: a copy --check-answer skips whole (FENCE_AWK odd/unbalanced, a fenced `### Q-NNN ` heading) refuses --cycle-diff whether it is the base's or the index's copy" (now via ANSWER_AWK with `-v id=Q-`)

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:1856-1860`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both copies of each questions file whenever a questions file is staged (an unchanged file's base copy is judged on both sides, `:1850-1854`); does not apply when no questions file is staged (`:1835` returns first), and ANSWER_AWK's `quoted` needs the fenced heading followed by a space (`### Q-005` alone in a fence is not quoted, E3 `fenced-noslug: []`, matching check_answer since it is the same program).

Code at claim 4. Executed: T38's index-side `unbalanced 12` and `quoted 13` and base-side `quoted 2` cases (E1); mutants no-whole and index-only each turn T38 red (E2). E3 prints the refusal line for every FENCE_AWK shape: `unbalanced 5`, `quoted 3`, `odd 2 html`, `odd 2 fence`, `odd 2 refdef`, `odd 2 comment`, `odd 1 cr`, `odd 1 bom`.

**Evidence:** `scripts/build-loop.sh:1835-1862`, `scripts/lib/dev-cycle-read.sh:2083-2084`, `$S/bats-orch.log`, `$S/mutant-no-whole.log`, `$S/mutant-index-only.log`, `$S/probe-answer.log`

---

## Claim 23: "For one ID in a file not refused whole, ANSWER_AWK's result is determined by the ordered sequence of that ID's heading, **Needs:** and answer-labelled lines; QKEYS_AWK tags a superset, so with a single merge base a changed --check-answer result implies changed key lines."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:1746-1754` vs `scripts/lib/dev-cycle-read.sh:2062-2115`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers one file at a time (static reading plus a differential fuzz over ~3,000 pairs) and the two-file concatenation by static reading; does not establish that a changed key line is refused for a new ID (only answered new entries refuse, claim 24), nor the result under several merge bases (now refused).

Static: both programs strip a trailing CR, run fence() first, end an entry at `/^(#|##|###) /` and match the same heading forms (`/^### Q-[0123456789]+([ \t]|$)/`, `scripts/build-loop.sh:1750`, vs `h == id || index(h, id " ") == 1 || index(h, id "\t") == 1`, `scripts/lib/dev-cycle-read.sh:2083`). ANSWER_AWK reads the first `**Needs:**` line and the first line starting (after `- `) with `id ":"` or `^\*\*answer(:|ed| \()` (`scripts/lib/dev-cycle-read.sh:2088-2108`); QKEYS_AWK tags every `**Needs:**` line and every line starting `Q-<digits>:` or that label (`scripts/build-loop.sh:1752-1753`), a superset, in file order. Inserting a heading or fence inside an entry moves or hides lines in both readers alike, so the ID's key list changes. Across the two files QDIFF concatenates per ID without the file field, and QKEYS restarts `id` per file (one awk per file, `:1860`), so a dup or both-files entry changes the key list too (paraphrased — no quote available because this follows from the per-file invocation and QDIFF's `o[id] = o[id] "\n" k l`, `scripts/build-loop.sh:1770`, together).

Executed (E4): random base files from a 25-line vocabulary (headings incl. `### Q-0010`, `## Section`, `#### `, Needs with ANSWERED/OPEN/double Status, own- and other-ID answer lines, labels, fences) mutated by 1-3 inserts/deletes/swaps; for Q-001, Q-002, Q-0010, any changed ANSWER_AWK result with an unchanged QKEYS key list counts a violation. Seed 7: `pairs=1230 ... result_change_without_key_change=0`; seed 23: `pairs=1812 ... =0`. Medium because fuzzing is not proof.

**Evidence:** `scripts/build-loop.sh:1746-1775`, `scripts/lib/dev-cycle-read.sh:2077-2115`, `$S/fuzz.out`, `$S/fuzz2.out`, `$S/fuzz.py`

---

## Claim 24: "A new entry carrying any Status-ANSWERED Needs field or any answer line refuses without --answered."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:1762-1775` (QDIFF_AWK answered())
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers IDs absent from BASE's key lines; a second entry with an existing ID is judged as a change ("gone") instead; does not establish that "**Status:**  ANSWERED" (two spaces) counts (neither reader counts it).

```awk
# scripts/build-loop.sh:1762-1767
function answered(k, l,   n, i, g) {
  if (k == "a") return 1
  n = split(l, fld, " · ")
  for (i = 1; i <= n; i++) { g = fld[i]; sub(/^[ \t]+/, "", g); sub(/[ \t]+$/, "", g); if (k == "n" && g == "**Status:** ANSWERED") return 1 }
  return 0
}
```
and `for (id in nw) if (!(id in o) && !(id in ok) && an[id]) print id " " nf[id] " new"` (`:1774`). Every Needs line counts (ANSWER_AWK reads only the first and its last Status field, `scripts/lib/dev-cycle-read.sh:2088-2093`), so this is stricter. Executed: T38's Q-004 case (E1); E4 checked 314 new IDs across both seeds for an ANSWER_AWK keep/drop/done result that QDIFF did not refuse: `new_answered_unrefused=0`.

**Evidence:** `scripts/build-loop.sh:1762-1775`, `test/scripts/build-loop-orchestrator.bats:418-420`, `$S/fuzz.out`, `$S/fuzz2.out`

---

## Claim 25: "On this repo's real questions files, --cycle-diff costs about the same as --state (~0.8 s) whether no file or all four guarded files are staged; state_start dominates."

**Submitted by:** performance-reviewer
**Location:** `scripts/build-loop.sh:1885-1889` (cycle-diff mode)
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers a scratch clone at HEAD 0f0c7e1c with main dafc0e74's real files (questions.md 277 lines, archive 2,581 lines), three runs each, on a host at load average ~12; does not establish timings on an idle host or with larger files.

E5: `--state` 0.706 / 0.735 / 0.669 s; `--cycle-diff` with nothing staged 0.702 / 0.706 / 0.718 s; with all four files staged (an open entry appended, an archive body line, an idea-log and a roadmap append) `--state` 0.696 / 0.674 / 0.708 s, `--cycle-diff` 0.807 / 0.837 / 0.821 s. The four-file case adds ~0.1 s (~15%) over --state; the rest is the shared `state_start` (`cycle-diff) state_start; cycle_diff || exit 2`, `:1886-1887`). "~0.8 s" fits the upper case; ~0.7 s for the rest.

**Evidence:** `scripts/build-loop.sh:1885-1889`, `$S/perf.log`, `$S/perf.sh`

---

## Claim 26a: ANSWER_AWK with `id=Q-` prints nothing for a clean real questions file (docs/working/questions.md and questions-archive.md at HEAD) and prints the odd/unbalanced/quoted line for each refused shape

**Submitted by:** orchestrator (brief)
**Location:** `scripts/lib/dev-cycle-read.sh:2109-2115`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both files at HEAD and at main and the eight FENCE_AWK/quoted shapes listed in claim 22; does not cover a trailing-CR-only file (stripped, prints nothing, as check_answer).

E3: `HEAD:docs/working/questions.md lines=277 headings=17: rc=0 []`, `HEAD:docs/working/questions-archive.md lines=2581 headings=123: rc=0 []`, same for main; refused shapes as in claim 22.

**Evidence:** `scripts/lib/dev-cycle-read.sh:2109-2115`, `$S/probe-answer.log`

---

## Claim 26b: "it can never print a dup/open/keep line (no heading equals or starts with "Q- ")"

**Submitted by:** orchestrator (brief)
**Location:** `scripts/lib/dev-cycle-read.sh:2077-2081`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Holds for every file whose headings follow the `### Q-<digits>` grammar, both real files included; a heading `### Q-`, `### Q- ...` or `### Q-<tab>...` does print dup/open/keep.

Same mechanism as claim 13: E3 printed `[keep|Q-]`, `[open|Q- note]` and `[dup]` for those headings. Fails closed (a refusal), with a two-line, misleading WHY.

**Evidence:** `scripts/lib/dev-cycle-read.sh:2077-2081`, `$S/probe-answer.log`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- **Claim 5** (`docs/working/plan-build-loop-handoff.md:333`): "A questions refusal's WHY starts with the entry's ID" holds only for entry refusals (gone/new); whole-copy, main-changed and compare refusals carry no ID. Say "an entry refusal's WHY".
- **Claim 13** (`scripts/build-loop.sh:1857`): "id Q- names no entry" is false for a heading `### Q-` / `### Q- ...` (ANSWER_AWK's `heading()` matches); the result is a fail-closed, two-line "refuses its copy whole (open / Q- note)" for a copy check_answer reads normally. Qualify to the Q-<digits> grammar.
- **Claim 19** (commit 0f0c7e1c message): same "which names no entry" qualifier (immutable).
- **Claim 26b** (brief's confirmation item): "can never print dup/open/keep" holds only for grammar headings; executed counterexamples print keep, open and dup.

### Unverifiable
- None.

## Escalations
- None blocking. The `### Q-` edge (claims 13, 19, 26b) fails closed, and no real file has such a heading. If wanted, a one-character change removes it (e.g. an id no heading can equal, or a check that `md` starts with odd/unbalanced/quoted).
