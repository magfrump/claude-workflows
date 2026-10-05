Commit: 13380172

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u1c (claude-workflows, branch feat/build-loop-u1c)
**Scope:** fix commit 13380172 only (range 32bef87b..13380172): scripts/build-loop.sh, test/scripts/build-loop-read.bats, the commit message, plus adjacent help text the changed lines interact with
**Checked:** 2026-10-05
**Commit:** 13380172
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 13
**Summary:** 9 verified, 3 mostly accurate, 1 stale, 0 incorrect, 0 unverifiable

Execution provenance (all claims marked `executed`): every probe ran under `timeout` from the scratch dir `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i4/fact-check/` (abbreviated `$S` below), in hermetic throwaway repos built by `$S/lib.sh` (a copy of test/lib/build-loop-fixtures.bash's approach: `GIT_CONFIG_NOSYSTEM=1`, `GIT_CONFIG_GLOBAL` pointing at a per-probe file, `HOME` in scratch, `LC_ALL=C`), running `bash /workspace/.claude/wt-build-loop-u1c/scripts/build-loop.sh --status ...` from inside the probe repo. Raw output is captured in `$S/*.log`. All processes exited; none left running. Hallucination-pattern log read: no entry matches any claim below; no fabrication found, so the log is not updated.

---

## Claim 1: "A tip on a branch level with main, or whose subject does not start "handoff:", is working."

**Location:** `scripts/build-loop.sh:61-62`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ok-line LOOP value for a 0-ahead tip (malformed and well-formed handoff subjects) and for a non-"handoff:" subject; does not establish the consistency of the separate skip clause at :69-71 (Claim 2).

The code only reads a marker when the branch is ahead:

```bash
# scripts/build-loop.sh:345-353
  loop=working
  if [[ "$ahead" -gt 0 ]]; then
    kind="$(marker_kind "$sha")"
    case "$kind" in
      bad\ *) echo "skip $a: the tip of $br starts \"handoff:\" but is not a marker: ${kind#bad }"; return ;;
      stopped\ *) loop=stopped; reason=" ${kind#stopped }" ;;
      *) loop="$kind" ;;
    esac
  fi
```

and `marker_kind` prints `working` for a subject not starting `handoff:` (`scripts/build-loop.sh:280` `[[ "$subj" == handoff:* ]] || { echo working; return; }`). Executed: branches `feat/a` (tip subject `handoff: junk`) and `feat/r` (tip `handoff: ready`), both 0 commits ahead of main (`git rev-list --count main..feat/a` = 0), print `ok ... feat/a working <sha> 2026-10-05 0` and `ok ... feat/r working ...`; one commit later on feat/a (1 ahead, `handoff: junk`) prints the skip.

Command: `timeout 120 bash p4.sh > p4.log 2>&1` · cwd `$S` · exit 0 · 2026-10-05T18:25:04Z.

**Evidence:** `scripts/build-loop.sh:61-62`, `scripts/build-loop.sh:276-296`, `scripts/build-loop.sh:345-353`, `$S/p4.sh`, `$S/p4.log`

---

## Claim 2: skip clause "... or the tip's subject (its message's first line) starts "handoff:" but it is not a marker."

**Location:** `scripts/build-loop.sh:69-71`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the skip clause's agreement with the code for tips ahead of main and for tips level with main; does not establish anything about lines changed in 13380172 (this clause is unchanged by it, read here because A22's fix must agree with it).

Lines 55-56 define a marker as requiring the branch to be "at least one commit ahead of main", so a 0-ahead tip whose subject starts `handoff:` is literally "not a marker" and the skip clause predicts a skip; the new :61-62 sentence (Claim 1) predicts working, and the code prints working (p4.log: `ok docs/working/briefs/2026-10-01-a.md open review feat/a working ...` for a 0-ahead `handoff: junk` tip). The help's two clauses therefore disagree for that case and only the code decides it; A22's sentence is right, the skip clause is missing its qualifier. Precise version: "... or the tip of a branch ahead of main has a subject that starts "handoff:" but it is not a marker."

**Evidence:** `scripts/build-loop.sh:55-56`, `scripts/build-loop.sh:69-71`, `scripts/build-loop.sh:346`, `$S/p4.log`

---

## Claim 3: "# shellcheck disable=SC2034  # NEVER: for the planned gate"

**Location:** `scripts/build-loop.sh:202`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which variables SC2034 flags in read_settings (with and without the directive, with the lib followed) and that the directive placed before `read_settings() {` suppresses it; does not establish the pre-existing SC2100 at :334 (see note).

With the directive, the health-check invocation (`scripts/health-check.sh:480` `shellcheck -x -e SC1091 -s bash -S warning "$f"`) on scripts/build-loop.sh exits 0 (`$S/sc-with.log` empty). With the line removed (copy in `$S/m5/`, lib alongside so `-x` follows it), the only SC2034 is NEVER:

```
In build-loop.sh line 241:
      else never_ok=1; NEVER=("${parts[@]}"); NEVER_LINE="never $v set: line ${first[never]} $where"; fi
                       ^---^ SC2034 (warning): NEVER appears unused.
```

POLICY is not flagged (it is read at :334), so "NEVER" alone is right and the directive above the function covers the assignment inside it. Note (pre-existing, not from this diff): when shellcheck actually follows `lib/dev-cycle-read.sh` (cwd `scripts/`, or a copy with lib/ beside it), it reports SC2100 at `:334` `pol=self-merge`, at 4dc84ce4 too (`:332`); from the repo root the `source=lib/...` path does not resolve, SC1091 is disabled, and the gate passes.

Commands: `shellcheck -x -e SC1091 -s bash -S warning scripts/build-loop.sh` · cwd worktree · exit 0 · 2026-10-05T18:25:52Z; `shellcheck -x build-loop.sh` · cwd `$S/m5` · exit 1 · 2026-10-05T18:25:14Z.

**Evidence:** `scripts/build-loop.sh:202-241`, `scripts/health-check.sh:480`, `$S/sc-with.log`, `$S/sc-without.log`

---

## Claim 4: nosuccess reason "has no success: line before the next constraint or "#" heading"

**Location:** `scripts/build-loop.sh:266`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what ends a pending hard constraint's success search in CONSTRAINTS_AWK and the help's matching wording at :33-34; does not establish that a "#" line is a Markdown heading (any column-0 "#" line counts) — the quoted `"#"` says exactly that.

A pending hard constraint is closed as nosuccess by the next constraint line, a column-0 `#` line, or end of file:

```awk
# scripts/build-loop.sh:167-171,174,176-181 (CONSTRAINTS_AWK; read whole, :164-182)
  if (bad == "" && pend != "") bad = "nosuccess " pend " " pendl
...
/^#/ { if (bad == "" && pend != "") bad = "nosuccess " pend " " pendl; pend = ""; next }  # a heading ends a pending one
...
    if (bad == "" && pend != "") bad = "nosuccess " pend " " pendl
```

The help (`:33-34` "before the next constraint or "#" heading") now uses the same words. End of file is the vacuous case of "before the next ..." (no next one exists). T44's three assertions of the new string pass (bats run, Claim 13).

**Evidence:** `scripts/build-loop.sh:33-34`, `scripts/build-loop.sh:164-182`, `scripts/build-loop.sh:266`, `test/scripts/build-loop-read.bats:169,184,186`, `$S/bats.log`

---

## Claim 5: "local -A n=() BRIEF=()  # a local BRIEF: the caller's stays as it was"

**Location:** `scripts/build-loop.sh:303`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that brief_fields called inside shared_branches writes the local BRIEF (bash dynamic scoping) and that the caller's BRIEF survives with shared_branches called after brief_fields "$a"; does not establish anything for BRIEF_ODD, which stays global (no caller reads it after shared_branches — see below).

`brief_fields` assigns `BRIEF=(); BRIEF_ODD=""` and `BRIEF[k]=v` without declaring (`scripts/lib/dev-cycle-read.sh:293,309`), so under bash's dynamic scoping it writes the nearest `BRIEF` in the call stack. Executed with three copies of the script in `$S/m2/`: `order` moves `shared_branches` to after `br=` (:328, i.e. after `brief_fields "$a"` and before the Dispatched/Policy reads); `orderNoLocal` additionally drops `BRIEF=()` from the local. Briefs a (`Dispatched: 3`) and z (`Dispatched: 7`), both open:

```
== base          ok ...-a.md open review feat/a absent - - 3
== order         ok ...-a.md open review feat/a absent - - 3
== orderNoLocal  ok ...-a.md open review feat/a absent - - 7
```

So the local keeps the caller's fields whatever the order; without it the last brief shared_branches read leaks in. BRIEF_ODD: the only readers are `check_brief` immediately after its own `brief_fields` call (`scripts/lib/dev-cycle-read.sh:340-345`), and check_brief runs in `$(...)` at :321; no reader follows shared_branches (paraphrased — no quote available because the claim covers absence of code: `rg -n BRIEF_ODD scripts/` lists only lib lines 288, 293-294, 304, 308, 341-344).

Command: `timeout 120 bash p2.sh > p2.log 2>&1` · cwd `$S` · exit 0 · 2026-10-05T18:24:39Z.

**Evidence:** `scripts/build-loop.sh:301-317`, `scripts/build-loop.sh:318-355`, `scripts/lib/dev-cycle-read.sh:288-312`, `scripts/lib/dev-cycle-read.sh:340-345`, `$S/p2.log`

---

## Claim 6: "Exit 1 is "none"; any other failure fails closed (SHARED_BRANCHES=error: every open brief skips)."

**Location:** `scripts/build-loop.sh:304-306` (code :307-308, :335)
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every git grep exit status above 1 that I could trigger (six ways), exit 1 (no briefs dir; only done briefs), and the effect on open/done/dropped/new briefs; does not establish fail-closed for failures git grep reports with exit 0 (a missing blob), nor anything about stderr noise from other git calls.

```bash
# scripts/build-loop.sh:307-308
  list="$(git grep --no-color -l -E '^Status: open'$'\r''?$' "$MAIN_SHA" -- docs/working/briefs/)" || rc=$?
  if [[ "$rc" -gt 1 ]]; then SHARED_BRANCHES=error; return; fi
# scripts/build-loop.sh:335
  if [[ "$st" == open && "$SHARED_BRANCHES" == error ]]; then echo "skip $a: the open briefs on the default branch could not be listed (git grep failed)"; return; fi
```

Executed (p1/p1b/p1c):
- Colour: repo `color.ui=always`+`color.grep=always`, the same in a global config file (`GIT_CONFIG_GLOBAL`), and global `color.grep.filename='red bold'`: both open briefs on feat/x skip as shared; feat/d stays ok.
- `grep.patternType=bogus`: open a, b, d each print "could not be listed (git grep failed)"; done c, dropped e and the new path print their normal ok lines.
- Exit 128 by other routes: `grep.threads=-1`, `color.ui=bogus`, `color.grep=bogus`, `grep.extendedRegexp=bogus` (each `gg rc=128`), and a corrupt loose object for brief b: every queried open brief prints the error skip; done c stays ok.
- Exit 1: no `docs/working/briefs` on main, and only a done brief on main: `gg rc=1`, normal ok lines (`ok ... new review - absent - - 0`, `ok ... done review feat/c ...`).

Imprecision: with brief b's blob deleted (missing, not corrupt), git grep prints `error: ... unable to read` on stderr, lists a and d, and exits 0; a then prints `ok ... open review feat/x absent` though b names the same branch (p1b.log "== missing blob"). b itself skips as unreadable, and an unreadable brief is not counted in the normal path either (`brief_fields "$f"` failing → `continue`, :311), so this matches the design, but "any other failure" is broader than the code: precise version "any exit status above 1". Also observed: `grep.patternType=bogus` makes other git calls (check_brief's `git log -G`, `scripts/lib/dev-cycle-read.sh:357`) print `fatal:` on stderr; stdout is as above.

Commands: `timeout 300 bash p1.sh > p1.log 2>&1` · cwd `$S` · exit 1 (script aborted at its own unset `$S` after the config cases; rerun as p1b) · 2026-10-05T18:23:58Z; `timeout 300 bash p1b.sh > p1b.log 2>&1` · exit 0 · 2026-10-05T18:24:06Z; `timeout 120 bash p1c.sh > p1c.log 2>&1` · exit 0 · 2026-10-05T18:24:19Z.

**Evidence:** `scripts/build-loop.sh:301-317`, `scripts/build-loop.sh:335`, `$S/p1.log`, `$S/p1b.log`, `$S/p1c.log`

---

## Claim 7: closed/ mapped only at the prefix (`${f/#docs\/working\/briefs\/closed\//docs/working/briefs/}`; commit: "the closed/ prefix is matched only at the start of the path")

**Location:** `scripts/build-loop.sh:311`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers non-prefix "closed/" paths (`2026-10-0closed/1-x.md`, `xclosed/2026-10-01-y.md`), a real `closed/` open brief, and a nested `closed/closed/` one; does not establish behaviour for paths git grep never lists.

With open briefs on feat/a at `docs/working/briefs/2026-10-0closed/1-x.md` and `docs/working/briefs/xclosed/2026-10-01-y.md`, the real open brief prints `ok ... open review feat/a absent - - 0` at 13380172 and `skip ...: another open brief ...` with 4dc84ce4's script (`$S/m3/old/`). Adding `docs/working/briefs/closed/2026-10-01-old.md` (open, feat/a) makes it skip; moving that to `closed/closed/` makes it ok again (the mapped path fails isbrief).

Command: `timeout 120 bash p3.sh > p3.log 2>&1` · cwd `$S` · exit 0 · 2026-10-05T18:24:48Z.

**Evidence:** `scripts/build-loop.sh:311`, `scripts/lib/dev-cycle-read.sh:157`, `$S/p3.log`

---

## Claim 8: commit 13380172, R1 paragraph: "with color.ui=always or color.grep=always, `git grep -l` wrapped each path in ANSI codes, and `|| true` turned a failed grep into an empty list ... The grep now runs with --no-color; exit 1 means no open brief, and any other exit makes every open brief skip"

**Location:** commit 13380172 message (code `scripts/build-loop.sh:307-308`)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ANSI wrapping with each setting alone, the removed `|| true` (4dc84ce4 line quoted in the diff), and the exit-status rule; does not establish the exit-0 partial-failure case (Claim 6).

`od -c` of `git grep -l` with only `color.ui=always`, and with only `color.grep=always`: `033 [ 3 5 m H E A D : docs/... .md 033 [ m`; with `--no-color`: plain `HEAD:docs/...md\n`. 4dc84ce4's line was `list="$(git grep -l -E ... -- docs/working/briefs/ || true)"` (diff in the shared block). "any other exit" is the exact form (contrast Claim 6's "any other failure").

Command: `timeout 60 bash p7.sh > p7.log 2>&1` · cwd `$S` · exit 0 · 2026-10-05T18:26:19Z.

**Evidence:** `scripts/build-loop.sh:307-308`, `$S/p7.log`, `$S/p1b.log`

---

## Claim 9: commit 13380172: "T28 runs with colour on and with a bogus grep.patternType; mutants without either guard fail it."

**Location:** commit 13380172 message; `test/scripts/build-loop-read.bats:381-390`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers T28 against 4dc84ce4's script and two single-guard mutants; does not establish regression tests for C29 or C30 (the commit claims none — mutants of those survive, see below).

T28 (`bats -f T28`, copies in `$S/mut/<v>/` with scripts/, lib/, test/ laid out as in the repo):

| Variant | Change | T28 |
|---|---|---|
| head | none | ok (rc 0) |
| old | 4dc84ce4's build-loop.sh | fails at :385 (`ok ...-a.md open review feat/x absent`) |
| noNoColor | `--no-color` removed | fails at :385 |
| noRc | `|| rc=$?` → `|| true)` | fails at :389 (`ok ...-d.md open ...`) |
| noLocal | `BRIEF=()` dropped from the local | passes; full suite: only test 4 fails, a harness artifact (it copies the repo's own docs/dev-cycle.md, absent in the copy) |
| oldClosed | `${f/closed\//}` restored | passes; full suite as noLocal |

So T28 catches R1 through either guard; C29 and C30 have no test that kills their mutants (Claim 5 and Claim 7 probes show the behaviour instead).

Command: `for v in ...; do (cd mut/$v && timeout 300 bats -f 'T28' test/scripts/build-loop-read.bats > $S/mut-$v.log 2>&1); done` · cwd `$S` · exit codes as in the table · 2026-10-05T18:26:30Z (full-suite runs 18:26:46Z, 18:26:55Z).

**Evidence:** `test/scripts/build-loop-read.bats:366-400`, `$S/mut-head.log`, `$S/mut-old.log`, `$S/mut-noNoColor.log`, `$S/mut-noRc.log`, `$S/mut-noLocal.log`, `$S/mut-oldClosed.log`, `$S/mut-noLocal-full.log`, `$S/mut-oldClosed-full.log`

---

## Claim 10: commit 13380172: finding IDs and override-log rows ("C29 ... C30 ... A22, A23, C32 ..."; "Override-log rows: A20 (deferrals re-pointed to U1d), A21, C28, C31, C33-C36.")

**Location:** commit 13380172 message; `docs/reviews/override-log.md:297-301`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that each named finding has a code change (Claims 1, 3, 4, 5, 7) or an override row in the diff; does not re-judge the rows' dispositions (settled 2026-10-05 rows).

The diff adds five rows naming "(iteration 3 A20)", "(architecture F1; iteration 3 A21)", "(test-strategy; iteration 3 C28, C33)", "(iteration 3 C31)" and "(iteration 3 C34-C36)" (`docs/reviews/override-log.md:297-301` in the shared block's diff). Together with R1, A22, A23, C29, C30, C32 fixed in code, every iteration-3 ID the PR intent lists is accounted for.

**Evidence:** `docs/reviews/override-log.md:297-301`, `scripts/build-loop.sh:61-62,202,266,303,307-311,335`

---

## Claim 11: commit 13380172 Notes: "448 changed code lines against main"

**Location:** commit 13380172 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count under decision-log row 62's rule (added+removed, outside docs/, against main); does not establish the waiver's existence (Claim 12).

`git diff --numstat main...13380172` outside `docs/`: build-loop.sh 179+9, dev-cycle.sh 1+1, lib/dev-cycle-read.sh 2+2, test/lib/build-loop-fixtures.bash 32+2, test/scripts/build-loop-read.bats 217+3 = 448 (paraphrased — no quote available because the figure is a sum over five numstat rows, listed here in full). Row 62 (`docs/decisions/log.md:85`): "Added and removed lines both count ... counted outside `docs/`".

Command: `git diff --numstat main...13380172` · cwd worktree · exit 0 · 2026-10-05T18:27Z (output reproduced above; not separately captured).

**Evidence:** `docs/decisions/log.md:85`, `workflows/pr-prep.md:86`

---

## Claim 12: commit 13380172 Notes: "the user extended U1c's waiver to ~450 in chat (Q-116)."

**Location:** commit 13380172 message
**Type:** Reference
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which questions entry the ID resolves to on main now; does not dispute that the user extended the waiver (the answer text is present under Q-118).

Three minutes after 13380172, main's 5c0a7521 ("fix(questions): undo the Q-116 ID collision; the U1c ruling is Q-118") renumbered the entry. On main, `docs/working/questions-archive.md:1940` is `### Q-118 · build-loop-u1c-r1-and-size` with `**Answer (2026-10-05, in chat):** "Fix + scoped 4th pass (Recommended)", then "Extend to ~450 (Recommended)"`, while `docs/working/questions.md:97` is `### Q-116 · digest-scan-working-dd-triggers` (open, unrelated). The commit's "(Q-116)" now points at the wrong entry; the shared preamble's "Q-114 + Q-116" carries the same old ID. The current ID is Q-118.

**Evidence:** `main:docs/working/questions-archive.md:1940-1945`, `main:docs/working/questions.md:97`, commit 5c0a7521

---

## Claim 13: T28 comment "Colour config on, or a git grep that fails, never empties the check: the first still finds the pair, the second skips every open brief." and the suite (16 tests)

**Location:** `test/scripts/build-loop-read.bats:381-382`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the comment against the code (Claims 6, 8) and the suite passing at 13380172; does not establish that the test itself checks "every" open brief (it asserts one open, $d, and one done, $c — the probe in Claim 6 covers all of them).

`cd /workspace/.claude/wt-build-loop-u1c && export LC_ALL=C.UTF-8 && bats test/scripts/build-loop-read.bats`: `1..16`, all 16 `ok`, including `ok 16 --status: two open briefs naming one branch both skip; many briefs keep their order (T28)`.

Command as above · cwd worktree · exit 0 · 2026-10-05T18:23:28Z.

**Evidence:** `test/scripts/build-loop-read.bats:381-390`, `$S/bats.log`

---

## Claims Requiring Attention

Legibility targets: Incorrect/Stale/Mostly accurate → for-author; Verified/Unverifiable → for-orchestrator-synthesis.

### Incorrect
- None.

### Stale
- **Claim 12** (commit 13380172 message) [for-author]: "(Q-116)" now resolves to an unrelated open question; the U1c waiver ruling is Q-118 (renumbered by 5c0a7521). History only: amend if not yet merged, else note it where the waiver is cited (PR description, preamble).

### Mostly Accurate
- **Claim 2** (`scripts/build-loop.sh:69-71`) [for-author]: the skip clause covers a 0-ahead tip starting "handoff:" (not a marker by :55-56) that the code, and A22's new :61-62 sentence, call working; add "of a branch ahead of main".
- **Claim 6** (`scripts/build-loop.sh:304-306`) [for-author]: "any other failure" — precisely "any exit status above 1"; a missing blob makes git grep exit 0 with errors, and that brief is then just not counted (as an unreadable brief is anyway).

### Unverifiable
- None.

Verified (for-orchestrator-synthesis): Claims 1, 3, 4, 5, 7, 8, 9, 10, 11, 13. Test-gap note from Claim 9: mutants reverting C29 (local BRIEF) and C30 (prefix anchor) survive the whole suite.

---

## Goal-Alignment Note

Success criterion (verbatim from the preamble): "A markdown report saved at the path named in your tail, structured per your skill, with a `Commit: 13380172` first line."

This report is saved at `/workspace/.claude/wt-build-loop-u1c/docs/reviews/code-fact-check-report-build-loop-u1c.md`, first line `Commit: 13380172`, with the skill's header fields, seven mandatory per-claim fields, Verification mode provenance for executed claims, and the Claims Requiring Attention section. Scope stayed on 32bef87b..13380172; no other repo file was edited (probe files and logs live in the scratch dir), nothing was committed, and every probe process has exited.
