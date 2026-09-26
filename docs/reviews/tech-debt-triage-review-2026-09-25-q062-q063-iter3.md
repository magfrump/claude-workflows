Commit: c7747c7

# Tech Debt Triage, iteration 3 (terminal pass): branch `skill-fixtures` (Q-062 [2], Q-063 [1])

**Scope:** the whole branch, `git diff main...HEAD` at c7747c7 (62 files, +6756/−90). The question is what debt the branch carries into `main` after three iterations, plus any debt f9feb2c added. Items the rubric marks Fixed are not re-reported unless the fix itself is wrong. Settled rows are not re-judged: the override log (C4, C5, C6, C9, trap RETURN, `--tools` variadic, RUNNER_ALLOWED_TOOLS naming), A1 (pending Q-064), C24 (Deferred), and C3/C4/C6/C8/C13/C14/C15 (open by choice). Where f9feb2c changed the footprint of an open item, only the status table says so.
**Inputs:** the stage-1 report `docs/reviews/code-fact-check-report.md` (c7747c7); its claim ids are cited below. The iteration-2 triage is `docs/reviews/tech-debt-triage-review-2026-09-25-q062-q063-iter2.md` (d8c43ae).
**What this pass ran:**
- `shellcheck -x -e SC1091 -s bash -S warning` (health-check's flags, `scripts/health-check.sh:448`) on the seven changed shell files;
- the four harness bats suites;
- `wc -l` over the history of `install.sh`, `eval-helpers.bash` and `generate-reports.bash`;
- `git diff --numstat` and `git ls-files` counts over `docs/reviews/`.

No `claude` or network commands were run.
**Mode:** advisory. Not committed.

---

## Status of earlier triage items

| Item | Earlier rec. | Change in f9feb2c | Status at merge |
|---|---|---|---|
| iter-2 A: `Bash(**)` unpinned, a tool-removal change reads as a model regression, revisit trigger only in a commit body | Fix opportunistically | Canary added (`generate-reports.bash:275-287`). The probe date and CLI version now sit in a code comment beside `DENY_RECORD_FLAGS` (`:115-120`). | **Retired.** The canary voids exactly the failure mode that went unguarded (fact-check Claim 25, Verified). The CLI behaviour is still probed, not documented (Claim 26, Unverifiable). That is inherent, and it now fails loudly. The leftover doc drift is Item B. |
| iter-2 B: opt-in after-denial grade never runs; its regexes have no offline test | Fix opportunistically | "When to opt in" guidance added (`arithmetic-eval-eval.bats:18-21`). Patterns moved to a sourced file with a 4-test offline suite. | **Mostly retired, with one defect.** The offline suite's hedge negative `! hits …` at `arithmetic-eval-after-denial-patterns.bats:26` can never fail (Claim 8, proved). The orchestrator is fixing it; see Item A for the gate consequence. |
| iter-2 C: figure EREs imprecise both ways | Carry intentionally | EREs anchored, with neighbour tests (`21.9 billion`, `129%`, `4.2 km`) and a test that the draft's own figures never match. | **Retired.** The only residue is Claim 9's wording ("4.8M" where the draft says "4.8 million"), a one-word test-name fix. |
| iter-2 D / C14: `install.sh` size | Defer and monitor | +12 lines (1314 → 1326). | Carried forward as Item D with updated numbers. Recommendation unchanged. |
| iter-1 #3: per-fixture value lists | Carry intentionally | — | Unchanged. |
| iter-1 #6 / C8: tripwire implemented twice | Carry intentionally (C8 open by choice) | **Footprint grew.** The init-event `tools` query now appears verbatim in two files: the generator's canary (`generate-reports.bash:281`) and `tool_inputs_checked` (`eval-helpers.bash:387`). `mode1-equiv.py` parses the same stream a third way. On a mis-shaped JSON line the three disagree: jq errors and the generator voids the run as "unreadable", but Python tracebacks with exit 1 and no SETUP ERROR label (Claim 14). | Still C8, open by choice. In practice the gap is not reachable: `mode1-equiv.py` only sees transcripts that passed the generator's jq tripwire, since `eval_fixture` fails on the `.failed` marker first (`eval-helpers.bash:80-84`). Revisit when a transcript can reach a check without going through the generator (hand-kept transcripts, a second skill's checker). |

---

## Item A: Fix-commit gate claims were not produced by the gate, and `main`'s fast gate would go red on merge

**Severity/priority:** P1 (the only item that blocks the merge)
**Location:** commit f9feb2c body; `test/skills/arithmetic-eval-after-denial-patterns.bats:26`; `test/skills/mode1-equiv.bats:249`, `:257`; `scripts/health-check.sh:448`
**Nature:** process / verification gap
**Cost of Deferral:** `+1 red health-check on main per merged loop that self-reports its gates`. Here it is one merge, but the same loop runs on every reviewed branch.
**Failure Cost:** (blank: the damage is a red gate, not an incident)
**Confidence:** High. I re-ran the gate's shellcheck invocation and got the output below, which matches Claims 29a/29c.
**Legibility-target:** for-author

**Evidence (verbatim):**
```
# commit f9feb2c body (excerpt; the Confidence/Notes lines follow)
Tests: harness suites 127 pass (generate-reports 35, mode1-equiv 23,
eval-helpers-transcript 7, patterns 4, gate/format/eval/empty-report the
rest); install-host 90/90; shellcheck clean.
```
```
# shellcheck -x -e SC1091 -s bash -S warning, this pass
In test/skills/arithmetic-eval-after-denial-patterns.bats line 26:
  ! hits "$VERDICT_RE" "I cannot confirm whether the figure is correct."
  ^-- SC2314 (error): In Bats, ! does not cause a test failure. Use 'run ! ' (on Bats >= 1.5.0) instead.
In test/skills/mode1-equiv.bats line 249:
  EXPECTED_VERDICT["tc-1.md"]="any"
  ^-------------------------^ SC2034 (warning): EXPECTED_VERDICT appears unused. ...
In test/skills/mode1-equiv.bats line 257:
    KEY_CHECK["tc-1.md"]="$check"
    ^------------------^ SC2034 (warning): KEY_CHECK appears unused. ...
```

The defects are small, and the orchestrator is fixing them (Claims 8 and 29c were escalated). The debt is how they got through. Each fix commit states its gate results ("shellcheck clean", "127 pass") from invocations it chose itself, not from the gate `main` runs:
- health-check lints `.bats` files at `-S warning`;
- the "127 pass" figure counts 9 skips as passes (Claim 29a).

A self-reported gate line gives false assurance. In this case it would have let a vacuous test assertion into `main`, and made health-check fail there.

### Carrying Cost: Medium
The next reviewer trusts the commit body's test line, and fact-check has to rediscover what the gate would have said in seconds. This loop needed a full fact-check claim (29c) to find an SC2314 that `health-check.sh` reports directly.

### Fix Cost
- **Scope:** localized. For this branch: the two shellcheck fixes, then one gate run. For the process: fix commits in the review-fix loop quote the gate's own output (`scripts/health-check.sh`, or at least its shellcheck and `run-tests.sh --fast` steps), not ad-hoc runs.
- **Effort:** minutes for the branch. The process change is one line in the loop's fix-commit checklist (`workflows/review-fix-loop.md`).
- **Risk:** low.
- **Incremental?** yes.

### Urgency Triggers
- The local merge to `main`. This is imminent.

### Recommendation

**Recommendation:** Fix now

It is trivial, and the merge is the trigger. Run health-check's shellcheck and `--fast` steps after the orchestrator's fix and before merging, and put the gate's counts (pass/skip split) in the merge or fix commit body. Whether the loop's checklist should require this is the author's call. It is cheap, and it would have caught Claims 8 and 29c before stage 1.

---

## Item B: The deny-record contract is still restated in prose, and f9feb2c's "one definition" left two restatements stale

**Severity/priority:** P3
**Location:** `docs/working/dd-arith-eval-bash-grant.md:174` ("As built", Contract bullet); `docs/decisions/log.md:77` (#56); `test/skills/generate-reports.bash:115-116`
**Nature:** documentation drift / duplication
**Cost of Deferral:** `+1 stale restatement per change to the deny-record contract`. The contract changed in both fix commits, and each change left at least one restatement behind (A14 in iteration 2, Claims 5b and 6 now).
**Failure Cost:** (blank)
**Confidence:** High (Claims 5b, 6 and 23b; I read all three sites).
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# test/skills/generate-reports.bash:115-116 (comment head; the probe note and DENY_RECORD_FLAGS=(…) follow at :117-120)
# The flags that make every Bash call denied and recorded under deny-record
# (Q-063 [1]). The one definition: the prose elsewhere points here. Probed
```
```markdown
# docs/working/dd-arith-eval-bash-grant.md:174 (the whole Contract bullet)
- **Contract.** `FIXTURE_BASH=deny-record` needs `FIXTURE_TRANSCRIPT=1` and `FIXTURE_TOOLS=Bash` exactly. Under it, `CLAUDE_FLAGS` may not name `--permission-mode`, `--permission-prompt*`, `--allowedTools`, `--settings` or the skip-permission flags, and whitespace of any kind separates flags.
```
```markdown
# docs/decisions/log.md:77, #56 decision cell (excerpt; the Rationale and References cells follow)
Under deny-record the generator refuses permission-changing `CLAUDE_FLAGS`, and it voids a run if any Bash call is missing from `permission_denials` (tripwire).
```

C21 fixed the flag *list*: it is now one array. It did not fix the *contract around* it: the CLAUDE_FLAGS policy, the canary, and the `FIXTURE_TOOLS=Bash` restriction. That contract is still described in five places:
- the generator's header;
- the runner-contract comment;
- the DD doc's "As built" section;
- log #56;
- the commit bodies.

Only the first two were updated in f9feb2c. The DD doc's section is headed "As built (2026-09-25, review-fix loop iteration 1)", yet it reads as current: it still gives the old denylist and never mentions the canary.

### Carrying Cost: Low
A reader who starts from the DD doc or log #56 gets a contract that is laxer than the code (a denylist rather than a refusal), with no canary. Nothing executes differently. The cost is a wrong mental model, plus a fact-check claim for every stale copy on every pass.

### Fix Cost
- **Scope:** two docs.
  - DD "As built": replace the Contract bullet with one line pointing at the generator's `FIXTURE_BASH` header and `DENY_RECORD_FLAGS`, or state that the section records iteration 1 and point at the code for the current contract.
  - Log #56: "refuses `CLAUDE_FLAGS`" (drop "permission-changing"), and add the canary to the tripwire clause.
- **Effort:** under 15 minutes.
- **Risk:** low.
- **Incremental?** yes.

### Urgency Triggers
- The merge. Log #56 is the durable record, and after merge nobody re-reads the loop's commit bodies.

### Recommendation

**Recommendation:** Fix now

These are two trivial doc edits at the merge, which is the moment the log entry becomes the record. Making the DD section point at the code rather than restate it also removes the site that has drifted twice.

---

## Item C: `tool_inputs_checked`'s fail-closed promise depends on an init event being present

**Severity/priority:** P3
**Location:** `test/skills/eval-helpers.bash:376-393` (`tool_inputs_checked`), used by `assert_tool_called` and `assert_no_tool_called` (`:409-462`)
**Nature:** latent correctness (fail-open edge) + inaccurate comment
**Cost of Deferral:** `+0 (inert) until a transcript run without deny-record uses no_tool_called:`. Today the only negative check is tc-ae5 (`expected-verdicts.bash:46`), and it is a deny-record run.
**Failure Cost:** (blank: a false pass on an eval fixture, no product impact)
**Confidence:** High for the mechanism (read; Claim 16 probed it). Medium for "not reachable today", which rests on the `.failed` path traced below.
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# test/skills/eval-helpers.bash:376-393 (the whole function)
# tool_inputs_checked <transcript> <tool>: print the tool's inputs (as
# transcript_tool_inputs does), or fail with a message when the transcript
# cannot be parsed, or when its init event lists the run's tools and <tool> is
# not one of them (a misspelled name such as "bash" would otherwise match
# nothing and let a negative check pass).
tool_inputs_checked() {
  local t="$1" tool="$2" inputs known
  if ! inputs="$(transcript_tool_inputs "$t" "$tool")"; then
    echo "Could not read tool calls from $t"
    return 1
  fi
  known="$(jq -rR 'fromjson? | select(.type == "system" and .subtype == "init") | .tools[]?' "$t" 2>/dev/null || true)"
  if [ -n "$known" ] && ! printf '%s\n' "$known" | grep -qxF -e "$tool"; then
    echo "$tool is not a tool of this run (its tools: $(printf '%s\n' "$known" | tr '\n' ' '))"
    return 1
  fi
  printf '%s' "$inputs"
}
```

`fromjson?` skips junk lines, so a junk or truncated transcript reads as zero calls. `[ -n "$known" ]` then skips the name check when there is no init event. Together they let `no_tool_called:` pass on such a transcript, even with a misspelled tool name (Claim 16). The A12 fix closed the grep and jq-error paths, but it keyed the misspelling guard on data that may be missing.

Why it isn't reachable today: a deny-record run with no init event trips the generator's canary. The canary writes `.failed`, and `eval_fixture` fails on that marker before any check runs (`eval-helpers.bash:80-84`). Outside deny-record, the only transcript-check user is divergent-design's `tool_called:Read=…`, a positive check, and a positive check fails on zero calls anyway.

### Carrying Cost: Low
Inert today. The risk is the next skill that adds a `no_tool_called:` fixture without deny-record: it inherits a check that its comment says fails closed, and in this case it does not.

### Fix Cost
- **Scope:** one function plus one test in `mode1-equiv.bats` (or wherever C13 eventually moves the generic tests).
- **Change:** when `known` is empty, fail ("transcript has no init event; cannot tell which tools the run had") rather than skip the check. This is the same stance the generator's canary takes.
- **Effort:** about 20 minutes.
- **Risk:** low. Every committed transcript fixture is generated with an init event. A test that builds a hand-made transcript without one would need the event added.
- **Incremental?** yes.

### Urgency Triggers
- A second skill adds `no_tool_called:` (or any absence check on transcripts) outside deny-record.
- Transcripts become hand-kept or trimmed (e.g. committed golden transcripts).

### Recommendation

**Recommendation:** Fix opportunistically

The fix is small and it makes the comment true. But nothing reaches the gap today, so it does not need to hold the merge. If the orchestrator is already editing this comment for Claim 16, making the code match the comment is about the same effort as weakening the comment to match the code, and it is the better outcome.

---

## Item D: `install.sh` size and the `procs_in_checkout` return protocol (C14, updated)

**Severity/priority:** P3 (monitor)
**Location:** `devcontainer-config/install.sh` (1326 lines); `:1138-1170` `procs_in_checkout` (comment from :1138, body :1151-1170); `:1175-1254` `agent_gate`
**Nature:** structural / size; stringly-typed return protocol
**Cost of Deferral:** about `+12 lines per install.sh fix commit`. Iteration 2 measured this rate, and f9feb2c added exactly +12 more. Across the branch: `main 1228 · 5ddf804 1298 · 8664e22 1314 · f9feb2c 1326` (+98).
**Failure Cost:** (blank)
**Confidence:** High (line counts via `git show <rev>:devcontainer-config/install.sh | wc -l`; function read in full).
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# devcontainer-config/install.sh:1190-1200 (inside agent_gate; the awk de-dup and docker check follow through :1254)
  inrepo="$(procs_in_checkout)" || rc=$?
  if [ "$rc" -eq 3 ]; then
    echo "ERROR: could not resolve the checkout's path ($REPO_ROOT), so install.sh cannot" >&2
    echo "       check for processes working inside it (Q-062). $what" >&2
    exit 1
  elif [ "$rc" -ne 0 ]; then
    echo "ERROR: /proc is not mounted, so install.sh cannot check for processes working" >&2
    echo "       inside the checkout (Q-062). It needs Linux /proc. $what" >&2
    exit 1
  fi
```

`procs_in_checkout` now reports over three channels:
- stdout carries the process list;
- the return code is 0, 2 or 3;
- stderr carries the blind-scan NOTE.

`agent_gate` handles 3 explicitly. It maps *every other* non-zero code to "/proc is not mounted", so a future return code (for example Q-064 [2]/[3]'s "cwd unknown" class) would print a wrong message unless someone remembers this `elif`. The protocol is fine for its current size. It is the part that grows when Q-064 is answered. The NOTE's example list has its own accuracy problem (Claim 2b), which is routed to security-reviewer and not triaged here.

### Carrying Cost: Low
It is one readable region, covered by T88-T90. The cost is navigation plus the catch-all `elif`.

### Fix Cost
- **Scope:** within the installer. The seam from iteration 2 stands: split the gate family (`agent_gate`, `procs_in_checkout`, `in_lineage`, `ppid_of`) into a sourced file. Q-064 [2]/[3] would also want tagged output lines, not a new return code.
- **Effort:** half a day. T90 fault-injects with `sed` on install.sh's own source, so a split moves its target.
- **Risk:** medium. Install paths cannot be tested live (the sandbox has no Docker).
- **Incremental?** yes. A one-line change (`elif [ "$rc" -eq 2 ]` plus an `else` for unexpected codes) could land on its own at any time.

### Urgency Triggers
- Q-064 answered [2] or [3]. That adds a second output class, which is the natural moment to split the gate family and move to tagged lines.
- The file passes ~1500 lines (174 to go, about 14 fix commits at the current rate).

### Recommendation

**Recommendation:** Defer and monitor

Unchanged from iterations 1 and 2. The only addition is to fix the catch-all `elif` in the same change that answers Q-064, since that is when a new code or class would arrive.

---

## Item E: The review loop's own artifacts now dominate the branch and a large share of the repo

**Severity/priority:** P4
**Location:** `docs/reviews/` (37 files on this branch; 12 more untracked for iteration 3); `docs/reviews/execution-logs/`
**Nature:** repository hygiene / search noise
**Cost of Deferral:** `+~5,000 tracked lines per three-iteration branch review`. On this branch, `docs/reviews/` is 5200 of the 6756 added lines (77%). Iteration 3's artifacts are not yet counted.
**Failure Cost:** (blank)
**Confidence:** High for the counts (`git diff --numstat main...HEAD -- docs/reviews`; `git ls-files docs/reviews`). Medium for the carrying cost, which is judgment.
**Legibility-target:** for-author

**Evidence (verbatim):**
```
# this pass
branch: 37 files under docs/reviews, 5200 of 6756 added lines
repo:   710 tracked files under docs/reviews, ~122.5k of ~318.9k tracked lines
since 2026-09-01: 52 commits touching docs/reviews, +114,462 lines
```

The global CLAUDE.md says review artifacts are "versioned alongside the content they review", so keeping them is policy, not accident. I found no retention or pruning rule in `skills/code-review/`.

Two costs are real but modest:
1. **Search noise.** Review files quote code verbatim with line numbers. `rg <symbol>` returns stale excerpts, such as the old CLAUDE_FLAGS denylist or superseded `install.sh` line numbers, next to the live code. An agent that reads a quote as current is misled. This is the same drift mechanism as Item B, at larger scale.
2. **Diff and review weight.** Three quarters of this branch's diff is review output, which buries the ~1,500 lines of product change in `git diff --stat`.

### Carrying Cost: Low
Neither cost has caused a known error yet. The review pipeline itself relies on the archive: iteration N reads iteration N−1's triage and rubric.

### Fix Cost
Three options. None is recommended now:
- (a) An `.ignore` file that keeps `docs/reviews/execution-logs/` out of default `rg` runs (`rg --no-ignore` still reaches it). This takes minutes, but it hides evidence from agents searching for it.
- (b) A retention rule: after the merge, keep the final rubric, final fact-check and final triage, and drop the per-iteration critic outputs and execution logs, which git history still holds. About an hour to write into the code-review skill.
- (c) Carry as-is.

- **Risk:** low for (a) and (b), but (b) changes an established workflow.
- **Incremental?** yes.

### Urgency Triggers
- An agent is observed acting on a stale code excerpt from `docs/reviews/`.
- `docs/reviews/` passes half of the tracked lines. It is at 38% today, and at +114k lines a month it could get there within a month or two.

### Recommendation

**Recommendation:** Defer and monitor

This is a workflow-level question that spans branches, not debt this branch should settle. The branch only adds to it. If either trigger fires, option (b) is the one to evaluate, since it keeps the audit trail in git history. If the author wants it tracked, it belongs in `docs/working/questions.md` as a `you: judgment` entry rather than in this rubric.

---

## Triage Summary

| # | Debt Item | Carrying Cost | Cost of Deferral | Failure Cost | Fix Cost | Urgency | Recommendation |
|---|-----------|:---:|:---:|:---:|:---:|:---:|---|
| A | Fix-commit gate claims not from the gate; fast gate red as committed (SC2314, 2× SC2034) | Medium | +1 red main gate per self-reported loop merge |  | Minutes | Merge (imminent) | Fix now |
| B | Deny-record contract restated in prose; DD "As built" and log #56 stale after f9feb2c | Low | +1 stale copy per contract change |  | <15 min | Merge | Fix now |
| C | `tool_inputs_checked` skips the name check when there is no init event (junk transcript passes `no_tool_called:`) | Low | +0 (inert) until a non-deny-record negative check |  | ~20 min | Second `no_tool_called:` user | Fix opportunistically |
| D | `install.sh` 1326 lines (+98); catch-all `elif` in the return protocol | Low | ~+12 lines per fix commit |  | Half a day | Q-064 [2]/[3], or ~1500 lines | Defer and monitor |
| E | `docs/reviews/` is 77% of the branch diff and 38% of tracked lines; no retention rule | Low | +~5k lines per 3-iteration review |  | 1 hour (option b) | Stale-quote incident, or 50% of lines | Defer and monitor |

The earlier opt-in grading, hand-written patterns and CLI-probe items (iteration 2's A, B and C) are retired or reduced to the Claim 8/9 residue in the status table.

### Recommended Order
1. **Before the local merge:** the orchestrator's shellcheck/Claim 8 fixes, then run health-check's shellcheck and `--fast` steps and record the actual counts (Item A). In the same commit, fix the DD Contract bullet and log #56 (Item B).
2. **If the Claim 16 comment is being edited anyway:** make the code fail on a missing init event instead (Item C).
3. **At Q-064's answer:** Item D's split, plus the `elif` fix.
4. **Workflow level, not this branch:** Item E, only if a trigger fires.

---

## Goal-Alignment Note

- **Answered.** This is the terminal tech-debt triage of `skill-fixtures` at c7747c7. It covers the net debt the branch carries into `main` across the areas the brief named:
  - opt-in grading and hand-written patterns: status rows iter-2 B and C, now retired apart from the Claim 8/9 residue;
  - the CLI-probe dependency and its canary: status row iter-2 A, retired; its doc drift is Item B;
  - `install.sh` size and exit-code protocol: Item D;
  - eval-helpers growth: Item C, plus the C8 footprint row (`eval-helpers.bash` went 390 → 438 → 488 lines, and the init-event parsing is now duplicated);
  - the `docs/reviews` artifacts: Item E.

  f9feb2c added three debts: the gate-claim gap (Item A), the partial "one definition" (Item B), and the init-keyed fail-open (Item C). Earlier items get status changes only. Every item carries a priority, Location, verbatim Evidence, Confidence, Legibility-target and a **Recommendation:** using one of the four allowed values.
- **Fixes checked for regressions.** The canary (C17), the CLAUDE_FLAGS refusal (C16), the single `DENY_RECORD_FLAGS` array (C21), the FIXTURE_BASH ordering (C19) and the `SetupError` boundary (A11) add no new debt beyond what is listed. A11's boundary misses mis-shaped JSON lines (Claim 14), but in the pipeline no such line reaches `mode1-equiv.py` (status table, C8 row).
- **Not answered / out of scope.** The blind-scan NOTE's PID-namespace wording (Claim 2b) is with security-reviewer. The Claims 8/29c defects are with the orchestrator; this triage covers only the process debt behind them. Live CLI semantics (Claim 26) and the Haiku regrade (Claim 29d) cannot be checked without `claude`.
