Commit: 9c73ae4

# Tech Debt Triage, iteration 5 (terminal pass): branch `skill-fixtures` (Q-062 [2], Q-063 [1])

**Scope:** the whole branch, `git diff main...HEAD` at 9c73ae4 (121 files, +17,300/−292), with the focus on 272bc83 ("one strict transcript reader"). This pass answers two questions:
- **(a)** What net debt does the branch carry into `main`?
- **(b)** Is the deny-record harness's complexity worth what it protects? Is a simpler posture defensible, and what would it retire?

Settled rows are not re-judged: the override log (C4, C5, C6, C9, trap RETURN, `--tools` variadic, RUNNER_ALLOWED_TOOLS naming), A1 (Q-064), A20, C24 and C30 (Deferred), and C3/C4/C6/C8/C13/C14/C15/C34/C35 (open by choice).

**Inputs:**
- the stage-1 report, `docs/reviews/code-fact-check-report.md` (9c73ae4). Command outcomes about the branch's tests and probes come from it and are cited by claim id;
- the iteration-4 triage, `docs/reviews/tech-debt-triage-review-2026-09-25-q062-q063-iter4.md` (5bdee46);
- `docs/working/dd-arith-eval-bash-grant.md` (the design's own size budget), and decisions log rows #17, #53 and #56.

**What this pass ran itself:**
- `git diff --numstat` and `git show --numstat` over the branch and the five deny-record commits;
- `wc -l` and `grep -c '^@test'` on the harness files;
- one hermetic jq 1.6 probe of a shape-agnostic `tool_use` search, quoted in Item C. It used a scratchpad file and no `claude`.

No `claude` or network command was run.
**Mode:** advisory. Not committed.

---

## Status of earlier triage items

| Item | Iter-4 rec. | What 272bc83 did | Status at merge |
|---|---|---|---|
| iter-4 A: hand-typed test tallies | Fix now | The tallies are pasted TAP plan lines. Fact-check re-ran every suite, and each figure matches exactly (Claim 31, Verified). | **Retired.** |
| iter-4 B: mode1-equiv exit contract, re-fired 4× | Fix now (structural) | Transcript reading moved out of the script, and a `__main__` catch-all was added (Claims 3 and 15, Verified). | **Retired for tracebacks.** A fifth instance remains: a non-raising evaluator failure exits 1 (Claim 14, Incorrect). The wording goes in Item A, the structural fix in Item E. |
| iter-4 C: verdict held in an inline jq string, probe set uncommitted | Fix opportunistically | Replaced by the `transcript.jq` module plus a committed 13-shape table (`malformed-transcripts.bash`), run in both suites and mutation-checked (Claims 2 and 32, Verified). | **Retired.** |
| iter-4 D: prose residue | Fix now | A24–A26 wording fixed (Claims 6–8). | **Recurs.** The new module's own contract sentences overclaim (Claims 26 and 29), and two lists went stale (Claims 1 and 16). See Item A. |
| iter-4 E / C14: `install.sh` size | Defer and monitor | None. Q-062 is unchanged since iteration 4. | Still 1338 lines. C14 is open by choice, so not re-judged. |
| iter-4 F / C30: `docs/reviews/` volume | Defer and monitor | +6,893 lines under `docs/reviews/` in 7bd0974, 272bc83 and 9c73ae4 together. | C30 is Deferred (settled), so no new item. The numbers are cost evidence for Item B: 94 files, +15,212 of +17,300 branch lines (87.9%). |

---

## Item A: The deny-record contract is stated as absolutes that the code does not meet, at about eight sites

**Severity/priority:** P1 (before the local merge)
**Location:**
- `test/skills/transcript.jq:4-7` and `:68-69`;
- `test/skills/eval-helpers.bash:77-79`, `:380-381` and `:387-391`;
- `test/skills/arithmetic-eval/mode1-equiv.py:6-10` and `:34-37`;
- `test/skills/generate-reports.bash:156` and `:328`;
- `docs/working/dd-arith-eval-bash-grant.md` "As built" (`:175-176` and `:182` in fact-check's numbering);
- `docs/decisions/log.md:77` (#56).

**Nature:** documentation / contract accuracy
**Cost of Deferral:** `+1 Incorrect fact-check claim, and a fix commit, per review pass that reads these files`. The history shows it:
- the shape class was flagged four times: A16 (iteration 3), then A22, then R2 (iteration 4), then Claims 26 and 29 (this pass);
- the exit contract was flagged five times: A10, A11, A19, A21, then Claim 14.

Each time, the code closed the named instances and the sentence kept its universal quantifier.
**Failure Cost:** (blank. Fact-check found no false pass reachable with the current CLI. The cost is the reader's trust and the loop tax.)
**Confidence:** High. Every site is a fact-check verdict: Claims 1, 12, 14, 16, 18, 22b, 26 and 29.
**Legibility-target:** for-author

**Evidence (verbatim):**
```jq
# test/skills/transcript.jq:4-7
# (R2, A21): each consumer used to parse the stream its own way and skip
# whatever it could not read, so an event of an unexpected shape could carry a
# Bash call past every check. Here an unexpected shape is a problem, never
# skipped, and "a Bash call", "denied" and "seen" are defined once.
```
```jq
# test/skills/transcript.jq:68-72 (whole definition)
# Tool calls: {id, name, input} for every tool_use, at any depth (sub-agents'
# events are assistant events too).
def tool_uses:
  [.[] | objects | select(.type == "assistant") | .message.content[]? | objects | select(.type == "tool_use")
   | {id, name, input}];
```
```python
# test/skills/arithmetic-eval/mode1-equiv.py:34-37 (docstring; it closes at :38)
Exit 0 on a match (or a valid spec), 1 on no match (per-command diagnostics on
stdout), 2 on anything else: a usage, spec, file or SKILL.md problem, or any
unexpected error in this script (message on stderr). Exit 1 therefore always
means "the model's commands did not compute the value", never a checker fault.
```
```bash
# test/skills/generate-reports.bash:328 (inside generate_one(), which runs to :335)
  # Every check passed: only now is the fail-closed marker removed.
```

The same file already states the right posture, a few lines above:
```bash
# test/skills/generate-reports.bash:283-284 (end of the "Transcript checks" comment)
    # These catch accidental breaches, not concealed ones: a command that did
    # run could rewrite the transcript before this reads it (C29).
```

### Carrying Cost: Medium
Each loop pass pays for these sentences. A probing fact-checker can always find a shape outside an enumerated set, so "never skipped", "at any depth" and "always" will keep drawing Incorrect verdicts, whatever the code does. Reviewers and future sessions also take the sentences at face value. The iteration-4 security endorsement (R2) was built on the same kind of claim.

### Fix Cost
- **Scope:** localized. About eight sentences, prose only, with no code or test change.
- **Effort:** under 30 minutes. Fact-check has already written a "Precise version" for each site (Claims 1, 8, 12, 14, 16, 18, 21, 22b, 25, 26, 29, 30).
- **Risk:** low. Comments and docs only. `scripts/health-check.sh` still gates shellcheck on the touched `.bash` files.
- **Incremental?** Yes, but one commit is cheapest.

Suggested contract sentence, for use in `transcript.jq:6-7`, DD "As built" and log #56:
> A malformed line, and an unexpected shape inside an assistant, user or result event, is a problem. Tool calls are read only from the content of assistant events, and other event types are not inspected. The checks catch accidental breaches of the shapes the CLI is known to emit, not every conceivable shape and not concealed ones (C29). The known residual is listed in Item C of the iteration-5 triage.

For mode1-equiv:
> Exit 1 means no command matched, including when SKILL.md's evaluator fails or prints an unexpected format.

For the marker:
> removed only after the checks pass. A field lost in the verdict split skips them (iteration-5 triage, Item D).

### Urgency Triggers
- The local merge. After it, these sentences become `main`'s description of the harness, and the next session reads them as fact.

### Recommendation

**Recommendation:** Fix now

This is the one change that moves the harness to a defensible posture (Item B). It spends no review pass on code, and it stops the one pattern that recurred in every iteration: an absolute claim meets a new counterexample. It is a trivial, multi-site prose fix, so make it in place in one commit. It needs no RPI.

---

## Item B: The deny-record harness has grown to about 7× its design budget, protecting a low-severity failure. Freeze it; do not grow or dismantle it

**Severity/priority:** P2 (a posture decision, not a code change)
**Location:**
- `test/skills/transcript.jq`, `malformed-transcripts.bash`, `arithmetic-eval/mode1-equiv.py`;
- the deny-record parts of `eval-helpers.bash`, `generate-reports.bash` and `runner-contract.bash`;
- their suites: `mode1-equiv.bats`, the deny-record tests in `generate-reports.bats`, `arithmetic-eval-eval.bats` and `arithmetic-eval-after-denial-patterns.bats`.

**Nature:** structural / over-investment relative to the risk
**Cost of Deferral:** `+0 — inert` if frozen, meaning the code does not rot on its own. If the review loop keeps treating shape completeness as its goal, the rate is `+~500 lines of test/ churn and ~3–7k lines of review artifacts per pass`: 272bc83 was +496/−161 in `test/`, and iteration 4 added +6,893 under `docs/reviews/`.
**Failure Cost:** `Low × Low`. An accidental Bash execution needs the CLI's `Bash(**)` deny rule to stop denying *and* the call to arrive in a shape the reader does not read. It would run as the session user, in a fresh temp directory, inside the cc-isolated container with SNI-filtered egress. The prompts are arithmetic drafts. The executions probed so far were read-only (`pwd`, `ls`, `echo`: DD "As built"). The container's reach includes the rw-mounted checkout, so the severity is not zero. It stays Low because the plausible commands are benign and the checkout is under git. The container context is inferred: `claude` and `/etc/cc-config-hash` are present in this environment. That the A8 runs happen here is not verified.
**Confidence:** High for the size and history numbers. Medium for the failure-cost estimate, which rests on where generation runs.
**Legibility-target:** for-author

**Evidence (verbatim):**
```
# docs/working/dd-arith-eval-bash-grant.md: the design's budget
| S5 | Small: under about 100 lines of harness code | soft | |
| [2] deny-and-record + equivalence | ~0.5 day, ~90 lines (helper ~50, contract/generator ~15, tests ~25 + fixtures) | low | 4/4 | …
                                                            (row continues: key downside)
```
```
# this pass: git diff --numstat main...HEAD (added / deleted)
101  0   test/skills/transcript.jq
188  0   test/skills/arithmetic-eval/mode1-equiv.py
47   0   test/skills/malformed-transcripts.bash
164  14  test/skills/eval-helpers.bash
105  8   test/skills/generate-reports.bash
42   2   test/skills/runner-contract.bash
359  0   test/skills/mode1-equiv.bats
280  3   test/generate-reports.bats
98   0   test/skills/arithmetic-eval-eval.bats
87   0   test/skills/arithmetic-eval-after-denial-patterns.bats
```
```
# this pass: test/ churn per deny-record commit (git show --numstat)
e6043df +642 -2   (feature)
8664e22 +233 -99  (loop 1)
f9feb2c +398 -103 (loop 2)
37c5ea9 +260 -92  (loop 3)
272bc83 +496 -161 (loop 4)
```

**Sizing (arithmetic over the numstat above):**
- **Harness code:** about 623 net lines. That is roughly 7× the DD's ~90-line estimate, and 6× S5's soft budget.
- **Tests:** about 821 added lines, in 58 `@test` blocks (15 deny-record tests in `generate-reports.bats`, 29 in `mode1-equiv.bats`, 9 eval, 5 after-denial). With the 13-shape table run in both suites, that is about 82 cases.
- **Review:** five passes. At least 11 rubric rows come from the two recurring classes (A10, A11, A16, A19, A21, A22, R2, C28, C31, C32, C33).
- **What it protects:** grading validity for 5 fixtures of one skill (4 routing positives and 1 negative), plus a loud signal if the deny flags stop denying.

### Carrying Cost: Low (if frozen)
The code is now well factored: one reader, one table, one list of voiding conditions. It is tested and mutation-checked (Claims 2 and 32). If nobody extends it, it costs nothing day to day. The cost so far came from the *review loop*, not from the code. Each pass asked "is every shape rejected?" That question has no finite answer (Item A), so each pass produced a new counterexample and a new commit.

### Is a simpler posture defensible? Yes. The repo has already chosen it once.

Decisions log #53 settled the same pattern for the auto-approve hook:
```
# docs/decisions/log.md:74 (#53, "Why" column; the row's third column, the reference, follows)
User call: the gaps are too hard to avoid. Patching constructs one at a time does not converge on a sound filter, and the hook is a convenience layer; `permissions.deny` and the sandbox are the boundary. Revisit if the hook is ever relied on as a security control or the sandbox is removed.
```
The deny-record harness has the same structure:
- The **control** is `DENY_RECORD_FLAGS` (`generate-reports.bash:123`: `--disallowedTools 'Bash(**)' --permission-mode dontAsk --permission-prompts none`), plus the container.
- `transcript.jq` and the canaries are a **detector** of the control failing. The detector's realistic trigger is a CLI update that stops denying. The calls then arrive in the normal assistant-event shape, and the tripwire catches them (Claim 23a, Verified).
- The refuted shapes (Claims 26 and 29) matter only if that failure *coincides* with the CLI moving `tool_use` to an event type it has never used.
- C29 (accepted) already limits the detector to "accidental, not concealed". Adding "known shapes" is the same kind of limit.

**Option 1: "Accidental breaches of known shapes", documented residual (recommended).**
- Cost: Item A's prose, plus a residual list (Item C).
- **Retires:** the review-loop work of hunting shapes. Future passes would verify the stated contract, which is finite, instead of refuting an unbounded one. It retires no code, and no code should be retired. Removing the tested canaries would cost a review pass and buy nothing.

**Option 2: sandbox the generation so that execution is harmless.**
- Nesting a sandbox inside the session container is blocked. Log #17 records that sessions run in Docker "where `CapEff=0` and seccomp blocks `CLONE_NEWUSER`, so the agent cannot confine itself".
- So this means a host-side throwaway container per generation run: new infrastructure, a `you: terminal` step, and about days of effort. The DD pruned the same idea as [7], failing its constraint H3.
- **What it would retire is less than it seems.** It lowers the failure severity from "execution in the checkout" to nil. But the canaries also protect *grading validity*: a run where Bash executed showed the model real output, so its after-denial grading is meaningless, and it must still be voided. The tripwire, the init canary and the strict reader would all stay.
- What could go: the orphan canary and the foreign-denial voiding, about 6 lines and 1 test, whose job is partly about safety. That does not pay for a new container workflow.
- **Not recommended** unless another reason brings host-side isolated generation (for example, if Q-063 is ever upgraded to DD candidate [3], live approval).

**Option 3: dismantle to the original ~90-line design.** Not recommended. It would reintroduce R2's array-wrapped and string-content holes, which were real, found by execution, in shapes adjacent to what the CLI emits. The rewrite would also cost a review pass.

### Fix Cost (of Option 1)
- **Scope:** prose (Item A) plus one working-rule sentence in the DD "As built" or log #56. Suggested rule: "a new shape finding is added to the residual list, not to the code, unless it is observed in a real transcript or is a one-line closure".
- **Effort:** under 1 hour, together with Item A.
- **Risk:** low. The residual is written down, not hidden.
- **Incremental?** Yes.

### Urgency Triggers
- **The A8 measurement** (memory `run-a8-measurement-after-settling`) is the first run whose transcripts are kept. Commit one or two real deny-record transcripts as positive controls, after checking them for secrets. That settles Claim 27a (the "13 real runs" are not in the repo), and it anchors the "known shapes" list to evidence rather than memory. At present no test checks the reader against a real transcript; all 13 table shapes are synthetic.
- The harness is reused for a second skill, or relied on as a security control: the #53 revisit condition.
- A CLI release that changes the stream-json schema.

### Recommendation

**Recommendation:** Carry intentionally

Keep what exists and stop growing it. The measured cost is almost entirely review-loop churn, driven by an unbounded completeness claim, while the protected failure is Low × Low. The repo's own precedent (#53) and the already-accepted C29 posture make a "known shapes" contract the consistent choice. Sandboxing retires too little to justify new host-side infrastructure. Dismantling reopens holes that were real.

---

## Item C: The known residual: a `tool_use` outside assistant-event content is validated or ignored, but never counted

**Severity/priority:** P3
**Location:** `test/skills/transcript.jq:38-44` (validates the content of user events), `:70-72` (`tool_uses` reads assistant events only), `:66`/`:75`/`:78` (other definitions filter by type)
**Nature:** coverage gap in a detector (latent, never observed)
**Cost of Deferral:** `+0 — inert`. It compounds only if the CLI changes, and that is the trigger below.
**Failure Cost:** `Low × Low`. This is Item B's conjunction. Under deny-record, an executed call still leaves a `tool_result` in a user event, so the orphan canary would void it (Claim 26, last paragraph). The plain `no_tool_called` check has no such backstop, which leaves one negative fixture open to a false pass. That is a grading error, not harm.
**Confidence:** High for the gap: fact-check probes P9, P10 and E2 are executed. Medium for "never emitted by the CLI": no transcript is kept (Claim 27a).
**Legibility-target:** for-author

**Evidence (verbatim):** `tool_uses`, quoted in full in Item A. This pass's probe of a shape-agnostic alternative used jq 1.6 and a synthetic transcript with four Bash calls: g1 in an assistant event (denied), u1 in a user event, r1 in an event of type `assistant_message`, and n1 nested in a tool_result:
```
$ jq -cR -n -L /workspace/test/skills 'import "transcript" as t; t::events | {current: [t::tool_uses[].id], recursive: [.[] | objects | .. | objects | select(.type == "tool_use") | .id], counts: t::deny_record_counts}' t.jsonl
{"current":["g1"],"recursive":["g1","u1","r1","n1"],"counts":{"undenied":0,"unseen":0,"orphans":0,"foreign":0}}
```

### Carrying Cost: Low
The gap is inert until the CLI's schema changes. Its real cost is the next reviewer finding it again. Writing it down (Items A and B) stops that.

### Fix Cost
- **Scope:** `transcript.jq` only. A recursive search (`[.[] | objects | .. | objects | select(.type == "tool_use") | {id, name, input}]`) closes every case fact-check listed, without enumerating shapes, as the probe shows. `problems` would need the same recursion for the id and name string checks, which is about 2 lines. Then add one or two rows to `MALFORMED_SHAPES`.
- **Effort:** 1–2 hours with tests.
- **Risk:** medium, and it cannot be judged in this sandbox. Without a real transcript, nobody knows whether the CLI nests tool_use-typed objects anywhere legitimate, for example inside an Agent tool_result or a sub-agent echo. If it does, the recursion would double-count, or void good runs of *other* skills that use `tool_called:`/`subagents_min:`. This is why the fix waits for A8's transcripts.
- **Incremental?** Yes.

### Urgency Triggers
- A8's kept transcripts exist. Run the recursive form against them and, if they agree, take it.
- A CLI release that adds event types, or moves content blocks.

### Recommendation

**Recommendation:** Defer and monitor

The fix is cheap, but its risk is exactly the unknown that A8's transcripts will settle. Until then, list the gap as the documented residual (Item A's sentence). Revisit when A8 runs.

---

## Item D: The generator's verdict split silently drops the counts field when `cli_version` holds a newline (Claim 22b)

**Severity/priority:** P3
**Location:** `test/skills/generate-reports.bash:289`, `:297`, `:307-309`
**Nature:** fail-open parse in a fail-closed path
**Cost of Deferral:** `+0 — inert`. The input is written by the CLI, and the model cannot set it except by rewriting the transcript (C29, accepted).
**Failure Cost:** `Low × Low`. Probe P1 shows the marker removed with an undenied call present, but only with a hand-made init event.
**Confidence:** High (executed: P1, with control P4)
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# test/skills/generate-reports.bash:289 (inside the jq program :286-291)
        (t::init | .claude_code_version // "unknown"),
```
```bash
# test/skills/generate-reports.bash:297
      IFS=$'\x1f' read -r n_problems problems init_state cli_version counts <<< "$verdict"
```
```bash
# test/skills/generate-reports.bash:307-309 (excerpt ends :309; the if-block continues to :318)
        if [ -n "$counts" ]; then
          local undenied unseen orphans foreign
          read -r undenied unseen orphans foreign <<< "$counts"
```

### Carrying Cost: Low
Invisible unless the input is hostile or the CLI writes a strange version string.

### Fix Cost
- **Scope:** one file. The class-level fix is a guard: under deny-record, `n_problems = 0` with an empty `counts` is itself a failure ("verdict could not be split"). Any field-split breakage then fails closed, whichever field carries the bad character. Optionally, also sanitize the version in jq (`| tostring | gsub("[\\u0000-\\u001f]"; "?")`).
- **Effort:** under 30 minutes, including a test built from P1's input.
- **Risk:** low.
- **Incremental?** Yes.

### Urgency Triggers
- The next edit to `generate_one`'s transcript checks.
- Item A's commit, if the author wants code in it. This is the one code change small enough to ride along. Adding it means the commit is no longer prose-only.

### Recommendation

**Recommendation:** Fix opportunistically

It is real, but reachable only through an input the model cannot write. A 2-line fail-closed guard closes the whole class. Take it at the next edit to these lines.

---

## Item E: mode1-equiv trusts SKILL.md's evaluator output without ever testing it (Claim 14, fifth instance of the exit contract)

**Severity/priority:** P3
**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:76-88` (`reference`), `:124-137` (`evaluate`), `:140-147` (`--check-spec`)
**Nature:** missing self-check / wrong layer for the guarantee
**Cost of Deferral:** `+0 — inert` until SKILL.md's Mode 1 block changes.
**Failure Cost:** (blank. The failure is a false *fail* with exit 1, graded as "the model did not route". It is loud, and it has no safety dimension.)
**Confidence:** High (Claim 14: E5 was executed against a SKILL.md copy whose output format was changed)
**Legibility-target:** for-author

**Evidence (verbatim):**
```python
# test/skills/arithmetic-eval/mode1-equiv.py:124-137 (whole function)
def evaluate(program, expr):
    """Run <expr> through the reference evaluator; return its value or None."""
    try:
        r = subprocess.run(["python3", "-c", program], input=expr + "\n",
                           capture_output=True, text=True, timeout=10)
    except subprocess.TimeoutExpired:
        return None
    m = re.search(r"-> (\S+)\s*\Z", r.stdout)
    if r.returncode != 0 or not m:
        return None
    try:
        return float(m.group(1))
    except ValueError:
        return None
```

### Carrying Cost: Low
The failure fires only when someone edits SKILL.md's Mode 1 print format or the evaluator's behavior. That is also the moment the gate suite (`arithmetic-eval-gate.bats`) is being re-read.

### Fix Cost
- **Scope:** one file. In `reference()`, after extraction, run `evaluate(program, "6 * 7")` and raise `SetupError` unless it returns 42. `--check-spec` then catches a changed format before any paid run, and exit 1 regains the meaning its docstring claims.
- **Effort:** about 30 minutes, plus one test adapted from fact-check's E5.
- **Risk:** low. It adds one subprocess per checker call.
- **Incremental?** Yes. The prose narrowing in Item A is the interim.

### Urgency Triggers
- The next edit to SKILL.md's Mode 1 block, or to the evaluator's output line.

### Recommendation

**Recommendation:** Fix opportunistically

The recurring part is the absolute word "always". Item A removes it now, at no cost. The self-test is the structural fix, and its natural trigger is the only event that can make the failure happen.

---

## Item F: Two lenient side-parsers outside the strict reader (Claims 11 and 21)

**Severity/priority:** P4
**Location:** `test/skills/eval-helpers.bash:473-483` (`assert_subagents_min`), `test/skills/generate-reports.bash:252-257` (report text and `is_error`)
**Nature:** duplicated parsing (the residue of iter-1 #6 / C8, open by choice)
**Cost of Deferral:** `+0 — inert`
**Failure Cost:** (blank. Voiding never depends on these parsers: the strict reader runs after them, Claim 21. Through `eval_fixture`, a voided run fails first on its marker, Claim 11.)
**Confidence:** High
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# test/skills/eval-helpers.bash:476-478 (excerpt starts inside assert_subagents_min(), which begins :473; continues to :483)
  n=$(jq -rR 'fromjson? | select(.type == "assistant" and .parent_tool_use_id == null)
       | .message.content[]? | select(.type == "tool_use" and .name == "Agent")
       | .name' "$t" | grep -c . || true)
```

### Carrying Cost: Low
The effect is a "defined once" claim that is slightly untrue. Item A's wording ("checked through", not "read through") covers it.

### Fix Cost
- **Effort:** under 1 hour. Route `assert_subagents_min` through `transcript_checked` and `transcript_jq`. That needs a `parent_tool_use_id` field in `tool_uses`, or a sibling definition.
- **Risk:** low for deny-record. It is medium for the skills that use `subagents_min:`, whose real transcripts have not been run through the strict reader in this review.

### Urgency Triggers
- The next edit to `subagents_min:`, or the A8 run for a sub-agent skill.

### Recommendation

**Recommendation:** Carry intentionally

It is harmless to voiding and to deny-record grading. Folding it in now would widen the strict reader's reach to other skills' untested transcripts, which is the same unknown as Item C.

---

## Triage Summary

| # | Debt Item | Carrying Cost | Cost of Deferral | Failure Cost | Fix Cost | Urgency | Recommendation |
|---|-----------|:---:|:---:|:---:|:---:|:---:|---|
| A | Contract absolutes ("never skipped", "any depth", "exit 1 always", "only after every check"), plus 2 stale lists, at ~8 sites | Medium | +1 Incorrect claim + fix per pass |  | <30 min, prose | Merge | Fix now |
| B | Harness ≈7× its design budget (623 code / 821 test lines, 5 passes) for a Low × Low failure; posture decision | Low if frozen | +0 frozen / +~500 test lines per pass if not | Low × Low — needs deny failure + new shape together | <1 h (Option 1) | A8 run; reuse for another skill | Carry intentionally |
| C | tool_use outside assistant-event content is never counted (Claims 26, 29) | Low | +0 (inert) | Low × Low — orphan canary backstops deny-record; `no_tool_called` has none | 1–2 h, but risk unknown until real transcripts | A8 run | Defer and monitor |
| D | `read` split drops counts on a newline in `cli_version` (Claim 22b) | Low | +0 (inert) | Low × Low — CLI-written field | <30 min | Next edit to generate_one | Fix opportunistically |
| E | mode1-equiv never tests SKILL.md's evaluator; exit 1 can be a checker fault (Claim 14) | Low | +0 (inert) |  | ~30 min | Next Mode 1 edit | Fix opportunistically |
| F | `assert_subagents_min` and report/is_error extraction stay lenient (Claims 11, 21) | Low | +0 (inert) |  | <1 h | Next `subagents_min:` edit | Carry intentionally |

**Net debt at merge:** after Item A lands, nothing on the branch is above Low carrying cost. The branch leaves behind:
- one posture decision (B, carry and freeze);
- one monitored residual tied to A8 (C);
- two cheap opportunistic fixes (D, E);
- one intentional carry (F);
- two items already settled as Deferred or open by choice (C14 `install.sh`, C30 `docs/reviews/`).

The remaining fact-check findings are Mostly accurate or Stale wording (Claims 8, 10, 18, 23b, 25, 30). They are one-phrase fixes, and they fold into Item A's commit.

### Recommended Order
1. **Before the local merge:** Item A, a prose-only commit. Include the Mostly-accurate one-phrase fixes, and Item B's one-sentence working rule in DD "As built" or log #56. Optionally add Item D's 2-line guard with a test; the commit is then no longer prose-only. Nothing here requires another review pass: it narrows claims to what fact-check verified.
2. **At the A8 measurement:** keep and commit one or two real deny-record transcripts as positive controls (Item B trigger, Claim 27a). Then evaluate Item C's recursive `tool_uses` against them.
3. **At the next edit to SKILL.md's Mode 1 block:** Item E.
4. **At the next edit to `generate_one`'s checks or `subagents_min:`:** Items D and F.

---

## Goal-Alignment Note

- **Answered.** The brief asked for a tech-debt triage of `skill-fixtures` at 9c73ae4, saved to this path with `Commit: 9c73ae4` at the top. Each focus item is covered:
  - **(a) Net debt at merge:** the status table, the summary table and the "Net debt at merge" paragraph. Every iteration-4 item has a status. Three were retired by 272bc83 (tallies, the inline jq, exit-contract tracebacks), and the prose residue recurs (Item A).
  - **(b) Cost/benefit of the harness's complexity:** Item B. It gives measured size against the DD's own ~90-line budget, the per-pass churn, and what the harness protects. It then assesses the simpler postures: Option 1, "known shapes, documented residual", is defensible, has precedent in #53, and retires the review-loop shape hunt, not code. Option 2, sandboxed generation, cannot be nested in the session container (#17), and it retires only about 6 lines, because the canaries also protect grading validity. Option 3, dismantling, would reopen the real R2 holes.

  Every item carries priority, Location, verbatim Evidence, Confidence, Legibility-target and a **Recommendation:** using one of the four allowed values.
- **Assumptions to check.**
  - That A8 generation runs inside the cc-isolated container is inferred from `claude` and `/etc/cc-config-hash` being present here, not confirmed. If generation runs on the bare host, Item B's failure severity rises: the host has no egress filter and has the user's home directory. Option 1 then still holds for the shape hunt, but Option 2 gains value.
  - The brief's premise that "the CLI emits none of the refuted shapes" is plausible but unverified in the repo (Claim 27a). Item B's A8 trigger is how to verify it.
- **Not answered / out of scope.**
  - Live CLI behavior: no `claude` was run.
  - Q-062's `install.sh` gate, unchanged since iteration 4.
  - The settled rows (override log, A1/Q-064, A20, C24, C30 and the open-by-choice set).
  - Nothing was committed.
