Commit: 8389c477
**Replication:** k=1 (second confirming pass)

# Code Fact-Check Report

**Repository:** claude-workflows (worktree /workspace/.claude/wt-build-loop-u4a, branch feat/build-loop-u4a)
**Scope:** partial: fix range ca95fead..8389c477 (daa09b5f: `scripts/build-loop.sh` header and `cycle_rules`, `test/scripts/build-loop-orchestrator.bats`, and its commit message; 8389c477's commit message). The rest of the branch is context only.
**Checked:** 2026-10-13
**Total claims checked:** 12
**Summary:** 10 verified, 2 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination log (`docs/reviews/hallucination-patterns.md`) read first. No claim below matches a logged pattern. The log was not updated: the brief allows writing only this file, and no claim is Incorrect.

Execution provenance (shared by the executed claims):
- E1, the branch suite: `LC_ALL=C TMPDIR=$(mktemp -d /tmp/u4a-fcc2-XXXX) timeout 900 bats test/scripts/build-loop-orchestrator.bats`, cwd `/workspace/.claude/wt-build-loop-u4a`, started 2026-10-13T21:35:40Z, exit 0, 27/27 ok. Output: `/tmp/u4a-fcc2-logs/bats.log`.
- E2, probe at HEAD 8389c477: `LC_ALL=C TMPDIR="$T" timeout 300 bats probe.bats` (probe copied to `/tmp/u4a-fcc2-logs/probe.bats`; it loads `test/lib/build-loop-fixtures.bash`, builds each throwaway repo under `$BATS_TEST_TMPDIR`, and runs the worktree's `scripts/build-loop.sh --cycle-diff`), cwd a fresh `mktemp -d /tmp/u4a-fcc2-XXXX` dir, started 2026-10-13T21:36:44Z, exit 0. Output: `/tmp/u4a-fcc2-logs/slugs.out`, `/tmp/u4a-fcc2-logs/paths.out`.
- E3, the same probe against the pre-fix script (`git archive ca95fead scripts` into `/tmp/u4a-fcc2-epDj/old`), cwd `/tmp/u4a-fcc2-epDj`, started 2026-10-13T21:37:01Z, exit 0. Output: `/tmp/u4a-fcc2-logs/slugs-old.out`, `/tmp/u4a-fcc2-logs/paths-old.out`.

Whole units read: `cycle_rules` (`scripts/build-loop.sh:1916-2001`), `questions_rules` (`:2009-2044`, which writes `$t.new` consumed at `:1969`), `QKEYS_AWK` (`:1822-1830`), the lib's `isbrief`/`anybrief`/`isrecord`/`writable` (`scripts/lib/dev-cycle-read.sh:238-249`), `truthrule` (`:1914-1924`), and `dev-cycle.sh`'s `check_fix` (`scripts/dev-cycle.sh:184-197`).

---

## Claim 1: "A path other than the cycle's own files, a .md under docs/ or README.md, compared lower-cased, refuses"

**Location:** `scripts/build-loop.sh:216-218`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers which paths pass or fail the allowlist test at `:1938` once the earlier gate-code, truth and cycle-case tests have passed; does not establish anything about the import walk (which `cycle_rules` does not run) or about `land_cycle`'s inputs beyond the shared `cycle_rules`.

```bash
# scripts/build-loop.sh:1938
    if [[ "$TRUTH_WHY" != cycle && "$lp" != docs/*.md && "$lp" != readme.md ]]; then echo "refuse $p: not a file the cycle changes (its own files, a .md under docs/ or README.md)"; bad=1; continue; fi
```

`lp` is `lp="$(lower "$p")"` (`:1920`), and the lib's `lower` is `tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz'` (`scripts/lib/dev-cycle-read.sh:917`). In E2, `readme.md`, `README.MD`, `Readme.Md`, `Docs/x.md`, `DOCS/X.MD` and `Docs/sub/y.MD` each print `ok`; `docs/x.markdown`, `Docs/x.txt`, `Skills/x/y.md`, `SCRIPTS/x.md`, `Readme.markdown` and `sub/README.md` each refuse with the `not a file the cycle changes` line (`/tmp/u4a-fcc2-logs/paths.out`). The bash `[[ == ]]` glob `docs/*.md` matches across `/`, so a nested `.md` passes (`Docs/sub/y.MD` ok).

**Evidence:** `scripts/build-loop.sh:1920`, `scripts/build-loop.sh:1938`, `scripts/lib/dev-cycle-read.sh:917`, `/tmp/u4a-fcc2-logs/paths.out`

---

## Claim 2: "(the paths an in-cycle fix may touch; wider than --check-fix, whose other refusals the rules here repeat only in part)"

**Location:** `scripts/build-loop.sh:218-220`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the comparison of `cycle_rules`' allowlist with `check_fix`'s path rules; does not establish whether the wider set is acceptable (the deferred override rows' subject, not a fact-check question).

`check_fix` refuses more than `cycle_rules` does:

```bash
# scripts/dev-cycle.sh:191
  elif [[ -n "$TRUTH_WHY" || ! "$lp" =~ ^docs/.*\.md$|^readme\.md$ || "$lp" =~ ^docs/(working|reviews)/ ]]; then
```

and then runs `truthwalk tree "$lp"` (`scripts/dev-cycle.sh:193`), the import walk. `cycle_rules` has no `docs/(working|reviews)/` test and no walk (paraphrased — no quote available because the claim covers absence of code: `cycle_rules` at `scripts/build-loop.sh:1916-2001` contains no `truthwalk` call and no `docs/(working|reviews)/` test). In E2, `docs/working/notes.md`, `docs/reviews/r.md` and `docs/thoughts/t.md` print `ok` (`/tmp/u4a-fcc2-logs/paths.out`), which `check_fix` would skip for the first two. The truth refusals it does repeat (`truthrule`'s words) are shared, as Claim 4 shows. "Wider" and "repeat only in part" both hold.

**Evidence:** `scripts/dev-cycle.sh:184-197`, `scripts/build-loop.sh:1916-1940`, `/tmp/u4a-fcc2-logs/paths.out`

---

## Claim 3: "whose heading (after " · ") is WORDS-STEM-N (WORDS lower-case letters and hyphens, STEM the brief's file name without .md, N digits, as keep-or-drop-STEM-N)"

**Location:** `scripts/build-loop.sh:233-236`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the heading test at `:1995` for every shape probed; does not establish that the dev-cycle skill writes only conforming slugs (that is U4b's step-6 grammar), and the imprecision is that WORDS is stricter than "lower-case letters and hyphens".

```bash
# scripts/build-loop.sh:1995
      elif ! [[ "${newh[$id]#* · }" =~ ^[abcdefghijklmnopqrstuvwxyz]+(-[abcdefghijklmnopqrstuvwxyz]+)*-"${f%.md}"-[0123456789]+$ ]]; then echo "refuse ${ap[$f]}: its first Asked: line adds $x, whose entry's heading is not WORDS-${f%.md}-N (an entry filed for this brief)"; bad=1
```

`newh[$id]` is the whole heading line (`QKEYS_AWK` prints `id "\t" f "\th\t" $0` at `:1825`; `questions_rules` strips the first three fields at `:2041`), so `#* · ` drops `### Q-NNN · `. The quoted `"${f%.md}"` is matched literally. E2 results (`/tmp/u4a-fcc2-logs/slugs.out`): `keep-or-drop-2026-10-01-x-1` and `blocked-2026-10-01-x-3` pass on brief x; `keep-or-drop-2026-10-01-a1-b2-1` passes on `2026-10-01-a1-b2` (digits and hyphens in the stem); a heading with no ` · ` refuses (the whole line then starts `###`); a trailing ` · extra` refuses. The precise version: WORDS is one or more lower-case letter runs joined by single hyphens — `keep--2026-10-01-x-1` and `Keep-2026-10-01-x-1` both refuse, so a leading, trailing or doubled hyphen is not allowed, which "lower-case letters and hyphens" does not say. No cycle-written slug is affected.

**Evidence:** `scripts/build-loop.sh:1825`, `scripts/build-loop.sh:1969`, `scripts/build-loop.sh:1995`, `scripts/build-loop.sh:2041`, `/tmp/u4a-fcc2-logs/slugs.out`

---

## Claim 4: The newly admitted lower-cased paths cannot escape the gate-code, truth and cycle-case rules that run before the allowlist (brief check 2; the header's ordering at `:221-226`)

**Location:** `scripts/build-loop.sh:221-226`, `scripts/build-loop.sh:1927-1932`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every case variant probed of the truth words (instr, dot, cycle, settings, user, record) and of the cycle files, for `--cycle-diff`; does not establish behavior on a case-insensitive filesystem's index (git stores the spelled path, which is what was probed) or of `GATE_CODE` for non-`skills/dev-cycle/` skill dirs (unchanged by the range).

```bash
# scripts/build-loop.sh:1927-1932
    if [[ "$lp" =~ $GATE_CODE ]]; then echo "refuse $p: the gate's own code; an in-cycle fix never edits it"; bad=1; continue; fi
    if truthrule "$lp" && [[ "$TRUTH_WHY" != cycle ]]; then
      w="the dev cycle's settings file"; [[ "$TRUTH_WHY" == settings ]] || w="$(floor_why "$TRUTH_WHY")"
      echo "refuse $p: $w; an in-cycle fix never edits it (--check-fix refuses it too)"; bad=1; continue
    fi
    if [[ "$TRUTH_WHY" == cycle && "$p" != "$lp" ]]; then echo "refuse $p: one of the dev cycle's own files, spelled in another case, which these rules do not read"; bad=1; continue; fi
```

`truthrule` resets `TRUTH_WHY=""` on entry (`scripts/lib/dev-cycle-read.sh:1915`), so no stale word reaches `:1938`. All three tests take `lp`. In E2: `Docs/Dev-Cycle.md` (settings), `DOCS/CONSTRAINTS.MD` (user), `Docs/Decisions/a.md` and `Docs/Human-Author/a.md` (record), `Docs/.x/a.md` and `Docs/.x.md` (dot), `docs/AGENTS.MD` (instr) refuse with their truth line; `Docs/Roadmap.md`, `Docs/Working/Idea-Log.md`, `docs/working/briefs/2026-10-01-Z.md` and `Docs/working/cycles/cycle-2026-10-12.md` refuse with the cycle-case line (`/tmp/u4a-fcc2-logs/paths.out`). The fix only changed the operand of the last test, from `$p` to `$lp`, so every path the earlier tests refuse is still refused first.

**Evidence:** `scripts/build-loop.sh:1920-1938`, `scripts/lib/dev-cycle-read.sh:1914-1924`, `/tmp/u4a-fcc2-logs/paths.out`

---

## Claim 5: "Any other path is one an in-cycle fix may touch: a .md under docs/ or README.md, compared lower-cased as --check-fix compares (confirming security F-B). A commit the chore branch carries from elsewhere (a loop's branch) refuses here when it touches another path"

**Location:** `scripts/build-loop.sh:1933-1937`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the lower-casing being the same as `check_fix`'s (`lower` on the path, then a lower-case pattern) and the refusal of a non-allowlisted path; does not establish that a carried commit touching only allowlisted paths is refused (the comment's "when it touches another path" correctly limits it).

`check_fix` lowers first: `if ! lp="$(lower "$a")"; then ...` (`scripts/dev-cycle.sh:189`), then tests `^docs/.*\.md$|^readme\.md$` on `lp` (`:191`). `cycle_rules` does the same with `lower` at `:1920` and the globs at `:1938` (Claim 1's quote). The carried-commit refusal is shown by the branch test at `test/scripts/build-loop-orchestrator.bats:498-501` (`src/app.sh` refuses), which passes in E1, and by E2's `SCRIPTS/x.md` and `sub/README.md` refusals.

**Evidence:** `scripts/dev-cycle.sh:189-191`, `scripts/build-loop.sh:1933-1938`, `/tmp/u4a-fcc2-logs/bats.log`, `/tmp/u4a-fcc2-logs/paths.out`

---

## Claim 6: "(its heading's slug is WORDS-STEM-N, WORDS letters and hyphens only, so no other stem, which starts with a date, fits before STEM: confirming security F-A; as step 6's keep-or-drop-STEM-N)"

**Location:** `scripts/build-loop.sh:1972-1974`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the binding's uniqueness for brief names `isbrief` admits and the F-A shape; does not establish anything for brief names outside `isbrief` (none reach this rule, since `anybrief` gates it at `:1939`), and the imprecision is "letters" where the code requires lower-case letter runs joined by single hyphens.

Every stem starts with a date's digit:

```bash
# scripts/lib/dev-cycle-read.sh:238-242
DIGIT='[0123456789]'
SLUG='[abcdefghijklmnopqrstuvwxyz0123456789-]+'
isbrief() { [[ "$1" =~ ^docs/working/briefs/$DIGIT{4}-$DIGIT{2}-$DIGIT{2}-$SLUG\.md$ ]]; }
isclosed() { [[ "$1" == docs/working/briefs/closed/* ]] && isbrief "docs/working/briefs/${1#docs/working/briefs/closed/}"; }
anybrief() { isbrief "$1" || isclosed "$1"; }
```

So WORDS, which holds no digit, ends exactly before the first digit-led component, and the remainder `STEM-N` splits uniquely at its last `-digits`. E2 (`/tmp/u4a-fcc2-logs/slugs.out`): the F-A shape `keep-or-drop-2026-10-02-foo-2026-10-01-x-1` refuses on brief `2026-10-01-x` and passes on its own brief `2026-10-02-foo-2026-10-01-x`; `keep-or-drop-2026-10-01-x-1-2` refuses on `2026-10-01-x` and passes on `2026-10-01-x-1`; `keep-or-drop-2026-10-01-x-12` refuses on `2026-10-01-x-1`. E3 shows the pre-fix rule passed the F-A shape on brief x (`/tmp/u4a-fcc2-logs/slugs-old.out`: `ok`, exit 0). Mostly accurate only because "letters" omits lower-case and the single-hyphen grouping (Claim 3), which the header states in part.

**Evidence:** `scripts/lib/dev-cycle-read.sh:238-242`, `scripts/build-loop.sh:1939`, `scripts/build-loop.sh:1995`, `/tmp/u4a-fcc2-logs/slugs.out`, `/tmp/u4a-fcc2-logs/slugs-old.out`

---

## Claim 7: "Step 6's rewrites: ... an idea appended, any other allowed path."

**Location:** `test/scripts/build-loop-orchestrator.bats:449`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the "other path" the test writes (`docs/other.md`) is on the allowlist and the step passes; does not establish anything about other allowlisted paths.

`echo x > docs/other.md; git add -A; cd_is ok` (`test/scripts/build-loop-orchestrator.bats:451`); `docs/other.md` matches `docs/*.md` at `scripts/build-loop.sh:1938`. Test 24 passes in E1.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:449-451`, `/tmp/u4a-fcc2-logs/bats.log`

---

## Claim 8: "An entry for a brief whose name ends in this one's does not fit (confirming F-A)."

**Location:** `test/scripts/build-loop-orchestrator.bats:479-481`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the test's heading `keep-or-drop-2026-10-02-foo-2026-10-01-x-1` refused on brief x with the exact message; does not establish the positive case for brief `2026-10-02-foo-2026-10-01-x` (no such brief exists in that fixture; E2 covers it).

```bash
# test/scripts/build-loop-orchestrator.bats:480-481
    sed -i '/^Asked: Q-002$/d' "$Y"; sed -i 's/^### Q-002 · .*/### Q-002 · keep-or-drop-2026-10-02-foo-2026-10-01-x-1/' docs/working/questions.md; sed -i 's/^Asked: .*/&, Q-002/' "$F"; git add -A
    cd_is "refuse $F: $A Q-002, whose entry's heading is not WORDS-2026-10-01-x-N (an entry filed for this brief)"; git reset -q --hard; printf '%s\n' "$E" "$N OPEN" >> docs/working/questions.md; git add -A
```

`2026-10-02-foo-2026-10-01-x` is itself a valid `isbrief` name, so the shape is a real one. Test 25 passes in E1; E3 confirms the pre-fix code passed it.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:478-481`, `/tmp/u4a-fcc2-logs/bats.log`, `/tmp/u4a-fcc2-logs/slugs-old.out`

---

## Claim 9: "Compared lower-cased, as --check-fix compares (confirming F-B)." with `echo r > readme.md; mkdir -p Docs; echo d > Docs/x.md; git add -A; cd_is ok`

**Location:** `test/scripts/build-loop-orchestrator.bats:502-503`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `readme.md` and `Docs/x.md` passing together at HEAD and being refused before the fix; does not cover `DOCS/X.MD`-style suffix case in the branch test (E2 covers it).

Passes in E1 (test 25). E3 shows both refused by the pre-fix script (`refuse readme.md: not a file the cycle changes (..., which --check-fix may allow)`, same for `Docs/x.md`, `/tmp/u4a-fcc2-logs/paths-old.out`), so the test discriminates the fix.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:502-503`, `/tmp/u4a-fcc2-logs/bats.log`, `/tmp/u4a-fcc2-logs/paths-old.out`

---

## Claim 10: daa09b5f message: "The slug before the brief's stem may hold only lower-case letters and hyphens, so no other brief's stem (which starts with a date) fits before it: keep-or-drop-2026-10-02-foo-2026-10-01-x-1 no longer binds to 2026-10-01-x (confirming fact-check claim 3b; security F-A)."

**Location:** commit `daa09b5f` message, bullet 1
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the before/after binding of the named heading to brief x; does not establish more than Claims 3 and 6 do about the WORDS grammar's hyphen strictness ("lower-case letters and hyphens" carries the same small imprecision, which does not change the bullet's point).

E3 `ok` (pre-fix) versus E2 `refuse ... whose entry's heading is not WORDS-2026-10-01-x-N` (post-fix) for this exact heading on brief `2026-10-01-x` (`/tmp/u4a-fcc2-logs/slugs-old.out`, `/tmp/u4a-fcc2-logs/slugs.out`). The regex at `scripts/build-loop.sh:1995` is Claim 3's quote.

**Evidence:** `scripts/build-loop.sh:1995`, `/tmp/u4a-fcc2-logs/slugs.out`, `/tmp/u4a-fcc2-logs/slugs-old.out`

---

## Claim 11: daa09b5f message: "The path allowlist compares the lower-cased path, as --check-fix does (security F-B: readme.md and Docs/x.md were refused). Wording: the allowlist is the paths an in-cycle fix may touch, wider than --check-fix (fact-check claims 1, 9)."

**Location:** commit `daa09b5f` message, bullets 2-3
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the lower-casing, the pre-fix refusals of the two named paths, and the wording change in both header and comment; does not re-verdict the first pass's claims 1 and 9 themselves.

Pre-fix refusals: E3 (`/tmp/u4a-fcc2-logs/paths-old.out`). Post-fix: Claims 1, 2 and 5. The diff replaces "(what --check-fix may allow an in-cycle fix)" with "(the paths an in-cycle fix may touch; wider than --check-fix, ...)" at `scripts/build-loop.sh:217-220` and drops ", which --check-fix may allow" from the refusal line at `:1938` (paraphrased — no quote available because the removed text exists only in the diff `/tmp/claude-1000/-workspace/8681a912-a74a-4649-a416-551a1bfd4a4f/scratchpad/u4a-conf2.diff`, hunks 1 and 3).

**Evidence:** `scripts/build-loop.sh:216-220`, `scripts/build-loop.sh:1938`, `/tmp/u4a-fcc2-logs/paths-old.out`, `/tmp/u4a-fcc2-logs/paths.out`

---

## Claim 12: daa09b5f "Notes: Q-141 interim [1] (the Q-138 precedent)" and 8389c477 "merge stopped by D1 (Q-141); interim [1] fixed in the previous commit."

**Location:** commit `daa09b5f` and `8389c477` messages
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that Q-141's option [1] on main names this fix and that daa09b5f is 8389c477's parent; does not establish the D1 verdict in the rubric itself (a prior pass's finding).

`git log --oneline ca95fead..8389c477` lists `8389c477` then `daa09b5f`, so daa09b5f is "the previous commit". Main's `docs/working/questions.md:292` (Q-141) option [1]: "The slug's prefix may hold only letters and hyphens (`^[a-z]+(-[a-z]+)*-STEM-N$`; a stem starts with a date's digit, so no other stem fits), the allowlist compares lower-cased", and `:297` "**Interim:** [1] (the Q-138 precedent)". The code's regex at `scripts/build-loop.sh:1995` is that regex with `[a-z]` spelled out.

**Evidence:** `main:docs/working/questions.md:280-298`, `scripts/build-loop.sh:1995`

---

## Claims Requiring Attention

### Incorrect
None.

### Stale
None.

### Mostly Accurate
- **Claim 3** (`scripts/build-loop.sh:233-236`): WORDS is lower-case letter runs joined by single hyphens (no leading, trailing or doubled hyphen), stricter than "lower-case letters and hyphens". Doc-only.
- **Claim 6** (`scripts/build-loop.sh:1972-1974`): "letters and hyphens only" omits lower-case and the single-hyphen grouping. Doc-only.

### Unverifiable
None.

---

## Goal-Alignment Note

Success criterion (verbatim from the brief): "a markdown report saved at the exact path your own prompt names, structured per your skill." This report is saved at `/workspace/.claude/wt-build-loop-u4a/docs/reviews/code-fact-check-report-2026-10-13-u4a-confirm2.md`, first line `Commit: 8389c477`, replication tag k=1 (second confirming pass). It covers the fix range's header, comments, test comments and both commit messages, plus the brief's three named checks (slug shapes, the lower-cased allowlist against the earlier rules, the header/comments/tests). Every claim carries the seven fields and a Legibility-target; executed verdicts cite command, cwd, exit code, time and captured output under `/tmp/u4a-fcc2-logs/`. No Must Fix or Must Address is raised by this pass: no claim is Incorrect.
