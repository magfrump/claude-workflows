Commit: 5bdee46

# Tech Debt Triage, iteration 4 (user-authorized terminal pass): branch `skill-fixtures` (Q-062 [2], Q-063 [1])

**Scope:** the whole branch, `git diff main...HEAD` at 5bdee46 (79 files, +9996/−94). This pass answers two questions: what net debt the branch carries into `main` after four passes, and what debt 37c5ea9 added. Earlier items get status changes only. Rows marked Fixed are not re-reported unless the fix is wrong. Settled rows are not re-judged: the override log (C4, C5, C6, C9, trap RETURN, `--tools` variadic, RUNNER_ALLOWED_TOOLS naming), A1 (Q-064), A20, C24 and C30 (Deferred), and C3/C4/C6/C8/C13/C14/C15 (open by choice).
**Inputs:**
- the stage-1 report, `docs/reviews/code-fact-check-report.md` (5bdee46). Its claim ids are cited below, and command outcomes about the branch's tests come from it;
- the iteration-3 triage, `docs/reviews/tech-debt-triage-review-2026-09-25-q062-q063-iter3.md` (c7747c7).

**What this pass ran itself:**
- `git show <rev>:<file> | wc -l` over main, 8664e22, f9feb2c and 37c5ea9 for the five growing files;
- `bats --count` per harness file;
- `git diff --numstat` and `git ls-files` counts over `docs/reviews/`.

No `claude` or network commands were run.
**Mode:** advisory. Not committed.

---

## Status of earlier triage items

| Item | Earlier rec. | Change in 37c5ea9 | Status at merge |
|---|---|---|---|
| iter-3 A: fix-commit gate claims did not come from the gate, so `main`'s fast gate would go red | Fix now | 37c5ea9 ran `scripts/health-check.sh` and quoted its result ("All checks passed", exit 0, including shellcheck). Fact-check re-ran it: Verified (Claim 24d). R1's SC2314 is fixed and mutation-checked (Claim 10). | **Retired for the gate.** The part that remains is the *hand-composed* test tally: "mode1-equiv 33" (Claim 24b, Incorrect) and the skip attribution (Claim 24c). That is Item A below. |
| iter-3 B: deny-record contract restated in prose; the DD doc and log #56 were stale | Fix now | Log #56 and the DD doc "As built" now point at the generator's `FIXTURE_BASH` header entry and `DENY_RECORD_FLAGS` (Claims 5, 9a, Verified). | **Mostly retired, one defect left.** The site everything now points at, the generator header, lists 2 of the 4 voiding conditions (Claim 18, Stale). See Item D. |
| iter-3 C: `tool_inputs_checked` skipped the name check when there was no init event | Fix opportunistically | An init event is now required. Junk and empty files fail with "No init event" (Claim 16a, Verified). | **Retired.** The only residue is wording: "truncated" covers only a cut before the init line (Claim 16b). See Item D. |
| iter-3 D / C14: `install.sh` size and the catch-all `elif` | Defer and monitor | The rc handling is now a `case` with its own `*)` error (Claim 3, Verified). +12 lines. | Catch-all **fixed**. Size carried as Item E. |
| iter-3 E: `docs/reviews/` artifact volume | Defer and monitor | +3,058 tracked lines of review docs in iteration 3. | Carried as Item F with updated numbers. |
| iter-1 #6 / C8: tripwire implemented more than once | Carry intentionally (C8 open by choice) | **Footprint grew again, and the copies now disagree.** The generator's tripwire counts only denials whose `tool_name` is Bash. mode1-equiv's counts every denial (Claim 9b). The mode1-equiv copy is also where Claim 13's tracebacks come from (`mode1-equiv.py:178-183`). | C8 stays open by choice. The consequence for the re-firing exit contract is Item B. |
| iter-1 #3: per-fixture value lists | Carry intentionally | — | Unchanged. |

**Growth across the branch** (`wc -l` at main · 8664e22 · f9feb2c · 37c5ea9):

| File | main | 8664e22 | f9feb2c | 37c5ea9 |
|---|---|---|---|---|
| `install.sh` | 1228 | 1314 | 1326 | 1338 |
| `eval-helpers.bash` | 390 | 438 | 488 | 496 |
| `generate-reports.bash` | 270 | 321 | 331 | 346 |
| `mode1-equiv.py` | — | 166 | 195 | 211 |
| `runner-contract.bash` | 85 | 120 | 122 | 125 |

37c5ea9's growth is modest: +8 in `eval-helpers.bash`, +15 in `generate-reports.bash`, +16 in `mode1-equiv.py`. `eval-helpers.bash` has flattened out and needs no item. `generate-reports.bash`'s growth is concentrated in one inline jq program, which is Item C.

---

## Item A: Test tallies in fix-commit bodies are composed by hand, and they are wrong at a steady rate

**Severity/priority:** P2
**Location:** commit bodies of f9feb2c and 37c5ea9; `workflows/review-fix-loop.md` (no rule on how a fix commit reports its tests); `docs/reviews/hallucination-patterns.md` (3 entries of this class)
**Nature:** process / verification gap
**Cost of Deferral:** `+1 wrong count per review-fix loop`. Both fix commits on this branch that give a per-suite tally have at least one wrong figure:
- f9feb2c: "127 pass", which was really 118 pass plus 9 skips (A20);
- 37c5ea9: "mode1-equiv 33", which is really 25 (Claim 24b); also "the 9 skips are the report-dependent eval tests", when 5 are report-dependent and 4 are opt-in (Claim 24c).

The project's hallucination log now holds three entries of the same class, "a specific measured value quoted from an artifact set that does not contain it" (2026-08-19, 2026-09-12, 2026-09-25).
**Failure Cost:** (blank: the damage is a misleading audit trail and a fact-check claim each pass, not an incident)
**Confidence:** High for the counts (`bats --count` this pass gives 38, 25, 7, 5, 18, 25, 9, 6, matching Claim 24a/b). Medium for the rate, which rests on two commits plus the log.
**Legibility-target:** for-author

**Evidence (verbatim):**
```
# commit 37c5ea9 body (excerpt; the Confidence/Notes lines follow)
Tests (this commit): harness suites 1..133 with 9 skips (generate-reports 38,
mode1-equiv 33, patterns 5, eval-helpers-transcript 7, gate/format/eval/
empty-report the rest; the 9 skips are the report-dependent eval tests);
install-host 91/91; scripts/health-check.sh: "All checks passed", exit 0,
including its shellcheck section.
```
```
# bats --count per file, this pass
38 test/generate-reports.bats
25 test/skills/mode1-equiv.bats
7 test/skills/eval-helpers-transcript.bats
5 test/skills/arithmetic-eval-after-denial-patterns.bats
```

The parts of the line copied from tool output are right: `1..133`, `9 skips`, `91/91` and "All checks passed" (Claims 24a and 24d, Verified). What goes wrong is what gets composed afterwards: a per-file breakdown, or a gloss on why tests skipped. Iteration 3's fix (run the real gate and quote it) worked for the gate line. It did not cover the breakdown around it.

### Carrying Cost: Medium
Each wrong figure costs a fact-check claim to find, a rubric row to record, and, because history is not rewritten, a correction note in the next commit (as with A20). It also weakens trust in the lines that are correct.

### Fix Cost
There are two cheap mechanical guards; either is enough.
- **(a) A rule, no tooling.** Fix-commit test lines hold only what a tool printed: the TAP plan line (`1..N`), plus `grep -c '^ok'`, `grep -c '# skip'` and `grep -c '^not ok'` over the saved TAP, plus health-check's final line. No per-file breakdown and no explanations of skips. This is one sentence in `workflows/review-fix-loop.md`'s fix-batch step.
- **(b) A tally printer.** A ~15-line `scripts/test-tally.sh <bats files…>` that prints `bats --count` per file and the ok/skip/not-ok totals from one run, pasted into the commit body as-is.

Both are:
- **Scope:** off-branch; a workflow file, or one new script.
- **Effort:** (a) minutes; (b) under an hour, with a bats test.
- **Risk:** low.
- **Incremental?** yes.

A commit-msg hook that re-derives the counts is not worth it. Which suites a commit reports on varies, so the hook would have to parse free text.

### Urgency Triggers
- The next review-fix loop on any branch. Nothing about this branch's merge depends on it.

### Recommendation

**Recommendation:** Fix now

This is a trivial off-branch change with a demonstrated, non-zero rate, and (a) costs one sentence. For this branch, following the A20 precedent: put the corrected tally in the merge commit body (mode1-equiv 25; 5 report-dependent skips and 4 opt-in).

---

## Item B: mode1-equiv's exit-code contract has re-fired four times, and the fifth fix should be structural

**Severity/priority:** P2
**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:31-36` (docstring), `:108-126` (`bash_calls`), `:159-206` (`main`, whole unit read); rubric A10 → A11 → A19 → Claim 13
**Nature:** fragile error boundary, plus a duplicated tripwire (C8)
**Cost of Deferral:** `+1 review claim and fix commit per review pass that touches mode1-equiv`. The contract was patched in 8664e22, f9feb2c and 37c5ea9, and a new shape escaped each time.
**Failure Cost:** (blank: fact-check confirms every escaping shape still fails the run, with no false pass)
**Confidence:** High (Claims 13 and 14, executed; I read `main` from signature to `sys.exit`).
**Legibility-target:** for-author

**Evidence (verbatim):**
```python
# test/skills/arithmetic-eval/mode1-equiv.py:174-186 (inside main(); the per-call loop and final "No Mode 1 call" return follow through :206)
        calls = bash_calls(evs)
    except SetupError as e:
        print("mode1-equiv: " + str(e), file=sys.stderr)
        return 2

    denied = {d.get("tool_use_id") for ev in evs
              if isinstance(ev, dict) and ev.get("type") == "result"
              for d in (ev.get("permission_denials") or []) if isinstance(d, dict)}
    denied.discard(None)
    # A call with no id counts as undenied (review iteration 3, C28).
    undenied = [cid for cid, _ in calls if cid is None or cid not in denied]
    if undenied:
        print(f"Bash tripwire: {len(undenied)} Bash call(s) not in permission_denials (may have executed): {undenied}")
        return 1
```

Each iteration enumerated the bad shapes it had seen and converted exactly those into `SetupError`. The docstring meanwhile promised the general property: "none can escape as a traceback with exit 1". So the next reviewer who tries a new shape finds a new escape. The tripwire block above sits outside the `try`, and it is a third copy of a check the generator already does more strictly. The generator filters by `tool_name == "Bash"` (Claim 9b), and `eval_fixture` fails the run on the generator's `.failed` marker before `mode1_equiv:` ever runs (`eval-helpers.bash:80-83`, Claim 16a).

### Carrying Cost: Medium
No wrong grade is reachable: the shapes are unlikely from the real CLI, and they fail closed. The cost is in the loop. It is the one row that has re-fired every iteration, and each re-fire costs a fact-check claim, a rubric row and a fix.

### Fix Cost
Claim 13 is escalated to the orchestrator, whose plan is to make the whole checker the boundary. As a debt matter, two structural fixes each end the series; per-shape patches do not.
- **(1) Boundary at the entry point.** In `if __name__ == "__main__"`, catch any exception that is not a `SetupError`, print "mode1-equiv: internal error: …" and exit 2. Add a table-driven test that feeds ~8 malformed shapes (those from Claims 13 and 14, plus any new ones) and asserts rc 2 and no `Traceback` on stderr.
  - The test pins the *property*, not a list of cases, which is what stops the re-fire.
  - Skipped-but-odd events (a non-object line, a string `content`) would still exit 1 through "No Mode 1 call". Either say so in the docstring or treat them as SetupError. That is a one-line decision.
- **(2) Delete mode1-equiv's tripwire** (`:178-186`). The generator's copy is stricter and runs first, and the pipeline never reaches this one. That removes the crash site, the Claim 9b divergence and one of C8's copies.
  - Second-order effect: `mode1-equiv.py` run by hand on a transcript that did not come from the generator loses its tripwire, and the docstring's "or the run fails whatever it computed" would have to go.
  - C8 is open by choice, so (2) is the author's call. This triage only notes that it is the cheaper option to carry.

Both are:
- **Scope:** one file plus one test.
- **Effort:** (1) about 30 minutes; (2) about 15 minutes.
- **Risk:** low. The exit-2 path is already labelled "SETUP ERROR, not a model result" by `assert_mode1_equiv` (A11).
- **Incremental?** yes.

### Urgency Triggers
- The merge. The docstring's promise is false as committed (Claim 13, Incorrect).

### Recommendation

**Recommendation:** Fix now

It is already escalated. The triage point is the *shape* of the fix: whichever option the orchestrator picks, it should come with a property test ("no malformed transcript produces a traceback or exit 1 from a setup fault"), not another list of cases. Without one, the fifth fix is likely to be followed by a sixth claim.

---

## Item C: The generator's deny-record verdict is a 12-line jq program inside a bash string, and its thorough tests live in an untracked review log

**Severity/priority:** P3
**Location:** `test/skills/generate-reports.bash:257-303` (comment :257-272, jq :275-286, verdict handling :287-303; the whole `if [ "$FIXTURE_BASH" = "deny-record" ]` block read); `test/generate-reports.bats:532-601` (5 stub-CLI cases); `docs/reviews/execution-logs/cfc-5bdee46-gen.jq` and `cfc-5bdee46-gen-jq-probes.sh` (untracked)
**Nature:** testability / structural
**Cost of Deferral:** `+1 re-extraction of the jq program per review pass`. Fact-check had to copy the program out verbatim to probe it against 24 transcripts (Claims 20a-20c), and that probe set is not a committed test. The same happens on every change to the checks.
**Failure Cost:** (blank)
**Confidence:** High for the structure (read). Medium for the rate: it rests on this pass's fact-check having needed the extraction.
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# test/skills/generate-reports.bash:273-278 (the jq program continues to :286; its result is parsed at :287-302)
    if [ "$FIXTURE_BASH" = "deny-record" ]; then
      local verdict
      verdict=$(jq -rRn '[inputs | fromjson? | objects] as $ev
        | ([$ev[] | select(.type == "system" and .subtype == "init")] | first) as $init
        | ([$ev[] | select(.type == "result") | .permission_denials[]?
            | select(type == "object" and .tool_name == "Bash") | .tool_use_id]) as $denied
```

C28 made the program one pass with O(1) lookups (Claim 20a, Verified), which is a real improvement. It also turned four small queries into one dense program that is fully exercised only through a stub `claude`. The five bats cases cover each voiding message once. The edge cases fact-check found worth probing, and which the program handles correctly, have no committed test:
- denials split across two result events;
- duplicate ids;
- a string `permission_denials`;
- sub-agent calls;
- init at the end of the stream (Claim 20c).

### Carrying Cost: Low
The program is correct today, and one tool (jq 1.6) runs it. The cost is that each future change to the deny-record checks has to be re-probed by hand. The program has changed in every iteration so far (C17, C28, A16, A17).

### Fix Cost
- **Scope:**
  - move the program to `test/skills/deny-record-verdict.jq`, called with `jq -rRn -f`;
  - commit the probe transcripts as a table-driven bats that runs the `.jq` file directly, with no stub CLI;
  - leave the generator's verdict handling unchanged.
- **Effort:** 1-2 hours. The probe script and its 24 inputs already exist in the execution log.
- **Risk:** low. The existing 5 stub-CLI cases still cover the wiring.
- **Incremental?** yes.

### Urgency Triggers
- The next change to the deny-record checks, or a CLI event-shape change that trips the parser canary.
- A second skill adopting `FIXTURE_BASH=deny-record`.

### Recommendation

**Recommendation:** Fix opportunistically

It does not block the merge. The next person to edit the verdict should do the extraction first, since the probe set that would otherwise be rebuilt by hand already exists.

---

## Item D: Prose residue at merge, led by the contract's single reference lagging the code

**Severity/priority:** P3
**Location:** `test/skills/generate-reports.bash:34-37` (Claim 18); `:265` "must start with" (Claim 20c); `test/skills/eval-helpers.bash:378-379` "truncated" (Claim 16b); `test/skills/arithmetic-eval/mode1-equiv.py:28` "No … '+'" (Claim 12) and `:109-110` (Claim 14); `test/skills/mode1-equiv.bats:241` test name (Claim 21); `docs/working/dd-arith-eval-bash-grant.md:175` "repeats the tripwire" (Claim 9b)
**Nature:** documentation drift
**Cost of Deferral:** `+1 stale site per contract change`. The rate is unchanged from iteration 3's Item B. What changed is where the drift lands: it has moved from the restatements to the one reference they now point at.
**Failure Cost:** (blank)
**Confidence:** High (fact-check Claims 9b, 12, 14, 16b, 18, 20c, 21; I read the header and the block comment).
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# test/skills/generate-reports.bash:31-37 (the whole FIXTURE_BASH header entry)
#   FIXTURE_BASH (optional) — "deny-record" lets FIXTURE_TOOLS be exactly Bash
#                     and pins DENY_RECORD_FLAGS (defined below, with why), so
#                     every Bash call is denied and only recorded (Q-063 [1]).
#                     Needs FIXTURE_TRANSCRIPT=1; refuses CLAUDE_FLAGS. A run is
#                     recorded as failed when any Bash call is missing from the
#                     result's permission_denials (it may have executed), or
#                     when the init event does not list Bash (canary).
```

A18's fix made the DD doc name this header entry as "the reference". 37c5ea9 added the parser canary and the missing-init void in the block comment at :257-272 but did not add them here. So the reference now lists 2 of 4 conditions, while log #56 and the DD "Run voiding" bullet list all four (Claims 5, 9a). The other six sites are one-phrase wording fixes. The fix-drift lite check ran over 37c5ea9 and caught none of them. Most sit outside the diff hunk that changed the behaviour.

### Carrying Cost: Low
Nothing executes differently. A reader who trusts the named reference under-counts the voiding conditions.

### Fix Cost
- **Scope:** comments and one test name.
  - For the header, the durable fix is to stop enumerating: "A run is recorded as failed on any of the deny-record checks in `generate_one` (tripwire, parser canary, init canary)". Then the list lives in one place, the block comment beside the code.
  - Precise wordings for the other six are in the fact-check report's "Claims Requiring Attention".
  - Claim 14's docstring goes away if Item B's option (1) or (2) lands.
- **Effort:** under 20 minutes.
- **Risk:** none.
- **Incremental?** yes.

### Urgency Triggers
- The merge. The header is what the durable docs point at.

### Recommendation

**Recommendation:** Fix now

These are trivial edits, and the merge is the last cheap moment to make them. Make the header point at the block comment rather than re-list the conditions, so the next check added cannot re-stale it.

---

## Item E: `install.sh` size (C14, updated)

**Severity/priority:** P3 (monitor)
**Location:** `devcontainer-config/install.sh` (1338 lines); `procs_in_checkout` `:1157-1173`; `agent_gate` gate `case` `:1193-1211`
**Nature:** structural / size
**Cost of Deferral:** `+12 lines per install.sh fix commit`. The rate held exactly across the three fix commits: 1314 → 1326 → 1338 (+110 over main).
**Failure Cost:** (blank)
**Confidence:** High (`wc -l` per revision).
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# devcontainer-config/install.sh:1193-1211, as quoted in fact-check Claim 3 (the second echo lines of arms 2 and 3 abbreviated there with "…")
  inrepo="$(procs_in_checkout)" || rc=$?
  case "$rc" in
    0) ;;
    2)
      echo "ERROR: /proc is not mounted, …" >&2
      … exit 1 ;;
    3)
      echo "ERROR: could not resolve the checkout's path ($REPO_ROOT), …" >&2
      … exit 1 ;;
    4)
      echo "NOTE: no process's working directory could be read under /proc: processes inside"
      echo "      the checkout not checked, treated as none (Q-062)."
      inrepo="" ;;
    *)
      echo "ERROR: the check for processes inside the checkout failed (exit $rc, Q-062). $what" >&2
      exit 1 ;;
  esac
```

The catch-all that iteration 3 flagged is gone: each code has its own arm. The function still reports over three channels (stdout list, rc 0/2/3/4, and the NOTE, now on the caller's stdout). A fifth outcome, as Q-064 [2]/[3] would add, is a new arm here.

### Carrying Cost: Low
It is one readable region, covered by T88-T91.

### Fix Cost
Unchanged from iteration 3:
- split the gate family into a sourced file when Q-064 lands (half a day);
- T90's `sed` fault injection moves with the split.

### Urgency Triggers
- Q-064 answered [2] or [3].
- The file passes ~1500 lines (162 to go, about 13 fix commits at +12 each).

### Recommendation

**Recommendation:** Defer and monitor

Unchanged. The only thing iteration 3 asked to bundle with Q-064, the catch-all, is already done.

---

## Item F: Review artifacts are 83% of the branch diff (updated)

**Severity/priority:** P4
**Location:** `docs/reviews/` (54 files changed on this branch; 20 more untracked from this iteration's stage 1)
**Nature:** repository hygiene / search noise
**Cost of Deferral:** `+~3,000 tracked lines per review iteration` (iteration 3 alone: +3,058 in `docs/reviews/` between c7747c7 and 5bdee46).
**Failure Cost:** (blank)
**Confidence:** High for the counts. Medium for the carrying cost, which is judgment.
**Legibility-target:** for-author

**Evidence (verbatim):**
```
# this pass
branch: 54 files under docs/reviews, +8256 of +9996 lines (83%)
repo:   727 tracked files under docs/reviews, ~125.6k of ~322.0k tracked lines (39%)
iteration 3 alone: +3058 lines under docs/reviews
```

This pass supplies a concrete example of the search-noise cost: the fact-check's verbatim jq extraction (`cfc-5bdee46-gen.jq`) and the old triage quotes of `install.sh` line numbers now sit beside the live code.

### Carrying Cost: Low
No known error has come from it yet. The pipeline relies on the archive, since each iteration reads the last.

### Fix Cost
Options unchanged from iteration 3 (a: `.ignore` the execution logs; b: a post-merge retention rule; c: carry). Option (b) is about an hour in the code-review skill.

### Urgency Triggers
- An agent is observed acting on a stale excerpt from `docs/reviews/`.
- `docs/reviews/` reaches 50% of tracked lines (39% today, up from 38% at iteration 3).

### Recommendation

**Recommendation:** Defer and monitor

This is a workflow-level question, not this branch's to settle. If the author wants it tracked, it belongs in `docs/working/questions.md` as a `you: judgment` entry.

---

## Triage Summary

| # | Debt Item | Carrying Cost | Cost of Deferral | Failure Cost | Fix Cost | Urgency | Recommendation |
|---|-----------|:---:|:---:|:---:|:---:|:---:|---|
| A | Fix-commit test tallies hand-composed (f9feb2c "127 pass", 37c5ea9 "mode1-equiv 33") | Medium | +1 wrong count per loop |  | Minutes (rule) / <1 h (script) | Next loop | Fix now |
| B | mode1-equiv exit contract re-fired 4× (A10→A11→A19→Claim 13); third tripwire copy is the crash site | Medium | +1 claim + fix per pass |  | 15-30 min + property test | Merge (escalated) | Fix now |
| C | Deny-record verdict is inline jq; its 24-case probe set is uncommitted | Low | +1 re-extraction per pass |  | 1-2 h | Next edit to the checks | Fix opportunistically |
| D | Generator header (the named contract reference) lists 2 of 4 voids; six one-phrase wording residues | Low | +1 stale site per contract change |  | <20 min | Merge | Fix now |
| E | `install.sh` 1338 lines (+110) | Low | +12 lines per fix commit |  | Half a day | Q-064 [2]/[3], or ~1500 lines | Defer and monitor |
| F | `docs/reviews/` 83% of branch diff, 39% of repo | Low | +~3k lines per iteration |  | 1 h (option b) | Stale-quote incident, or 50% | Defer and monitor |

**Net debt at merge:** after B and D land, nothing on the branch itself is above Low carrying cost. Four passes retired every earlier Fix-now item. The branch leaves two things behind:
- one structural carry (C, opportunistic) plus two monitored items (E, F);
- one process fix (A), which is off-branch.

### Recommended Order
1. **Before the local merge:** Item B (the orchestrator's structural fix, with a property test) and Item D (header plus wording), in one commit. The merge commit body carries the corrected 37c5ea9 tally (Item A, per the A20 precedent).
2. **Before the next review-fix loop on any branch:** Item A's rule (a), optionally with the (b) script.
3. **At the next edit to the deny-record checks:** Item C.
4. **At Q-064's answer:** Item E.
5. **Workflow level, only if a trigger fires:** Item F.

---

## Goal-Alignment Note

- **Answered.** This is the tech-debt triage for iteration 4 of `skill-fixtures` at 5bdee46, saved to `docs/reviews/tech-debt-triage-review-2026-09-25-q062-q063-iter4.md` with `Commit: 5bdee46` at the top. It covers each focus the brief named:
  - **net debt at merge after four passes:** the status table and the "Net debt at merge" line;
  - **debt 37c5ea9 added:** B (re-fire site), C (jq density) and D (header lag);
  - **growth of `generate-reports`' jq, `eval-helpers` and `mode1-equiv`:** the growth table, Items B and C; `eval-helpers` has flattened to +8 lines and needs no item;
  - **the recurring wrong-counts pattern:** Item A, with two cheap guards, (a) a rule and (b) a tally script, and a reason to skip a commit-msg hook.

  Earlier items get status changes only. Every item carries priority, Location, verbatim Evidence, Confidence, Legibility-target and a **Recommendation:** using one of the four allowed values.
- **Regressions from 37c5ea9.** No executable regression was found. The two prose regressions are Claim 18 (Item D) and the false Claim 13 promise (Item B). Neither causes a false pass (fact-check).
- **Not answered / out of scope.**
  - Which of Item B's two options to take: C8 is open by choice, so that is the author's call.
  - Live CLI behaviour, which cannot be checked without `claude`.
  - The settled rows (A1/Q-064, A20, C24, C30, the override log).
  - Nothing was committed.
