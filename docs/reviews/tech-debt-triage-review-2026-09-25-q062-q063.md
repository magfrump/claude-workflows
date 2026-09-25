Commit: 5ddf804

# Tech Debt Triage: branch `skill-fixtures` (Q-062 [2], Q-063 [1])

**Scope:** `git diff main...HEAD` at 5ddf804 (7 commits, 86bb2c6..5ddf804). This covers debt the branch adds or carries forward. It does not re-judge the settled override-log rows (C4, C5, C6, C9, trap RETURN, `--tools` variadic, RUNNER_ALLOWED_TOOLS naming). Item 1 notes where this branch changes C9's premise.
**Inputs:** stage-1 report `docs/reviews/code-fact-check-report.md` (Commit 5ddf804). Execution results cite its claim ids. Two regex probes and one line-count history were run in this pass; they are described inline.
**Mode:** advisory. Nothing here is committed.

---

## Item 1: A model-graded suite with tests expected to fail joins the blocking `--fast` gate

**Severity/priority:** P1 (highest in this set)
**Location:** `test/skills/arithmetic-eval-eval.bats:2`, `:10-14`, `:44-52`, `:78-92`; `scripts/run-tests.sh:80-117`; `scripts/health-check.sh:347-383`
**Nature:** testing / gate hygiene
**Cost of Deferral:** `+1 red --fast run per local arithmetic-eval report generation`. The rate is flat and tied to each measurement run. It does not grow with time.
**Failure Cost:** (blank: ergonomic. The cost is a gate that is red for known reasons, not an incident.)
**Confidence:** High for the mechanism (code read). Medium for "red on the next run": that assumes the next model behaves like Haiku 4.5 did in the first run (commit e6043df), which is unverifiable here (fact-check Claim 14).
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# test/skills/arithmetic-eval-eval.bats:2
# @category fast
```
```bash
# test/skills/arithmetic-eval-eval.bats:10-14
# should say the figures could not be verified, and give no verdict. Haiku 4.5
# fell back to mental math in the probe and in the first run (2026-09-25), so
# expect these to fail on some models. They are separate tests so they never
# mask the routing result.
```
(The excerpt is from the file header comment, lines 1-23. Lines 1-9 and 15-23 were read: prerequisites and run instructions.)
```bash
# scripts/run-tests.sh:88-94
has_reports=false
for output_dir in "$REPO_ROOT"/test/skills/*/output/; do
  if [[ -d "$output_dir" ]] && ls "$output_dir"/*.md &>/dev/null 2>&1; then
    has_reports=true
    break
  fi
done
```
(truncated: the report-gating block continues to :117 and drops `*-eval.bats` only when `has_reports` is false. Read in full.)

Commit e6043df body: "health-check's only failures were those 4 model-graded tests against the local run's reports."

### Carrying Cost: Medium
When any skill's `output/` holds a report, every `*-eval.bats` joins the `--fast` set. `health-check.sh` treats `--fast` as a blocking pre-gate: "if it is red, the slow set is not run at all" (`:347-349`). This branch ships four tests that its own header expects to fail on the current default model, and that did fail 4/4 in the recorded run. So once arithmetic-eval reports are generated again (the next routing measurement), the fast gate goes red for a known reason and the slow suites stop running. A red gate for known reasons is the condition under which a real regression slips through unnoticed. Today the checkout has no `test/skills/*/output/`, so the gate is green and the cost is latent.

**C9 premise note:** C9 was deferred as a *timing* concern (~20 s), with "no reports exist yet". This branch makes two changes. Reports have now existed locally (the e6043df run), and the new concern is *correctness* of the gate, not time. C9's revisit trigger (">15 s over 128 s") does not fire on this. This item is separate from C9 and does not re-open it.

### Fix Cost
- **Scope:** localized. One or two files under `test/skills/`.
- **Effort:** hours.
- **Risk:** low. The worst case is that the after-denial behavior stops being graded by default. It is advisory already.
- **Incremental?** yes.

### Urgency Triggers
- The next `generate-reports.bash arithmetic-eval` run. The user's measurement plans make this likely soon.
- Any loop (self-improvement, `/loop`) that runs health-check with reports present.

### Recommendation

**Recommendation:** Fix now

The fix is trivial in scope, and the trigger is the next routine measurement. Move the four `after_denial` tests into their own file tagged `# @category slow`, or leave them in place and gate them behind an opt-in variable, so they report without blocking `--fast`. The routing tests (tc-ae1..5) can stay fast. The header's "separate tests so they never mask the routing result" then extends to "never mask the rest of the suite either". This is a single-concern change of well under 50 LOC, so fix it in place. It does not need an RPI pass.

---

## Item 2: `VERDICT_RE` misses the failure it was written to catch

**Severity/priority:** P2
**Location:** `test/skills/arithmetic-eval-eval.bats:28-52` (`VERDICT_RE`, `NOT_VERIFIED_RE`, `after_denial`)
**Nature:** test oracle, heuristic string matching
**Cost of Deferral:** `+1 possibly-false after-denial pass per model change or report regeneration`. It stays flat while the current model fails for other reasons. It starts to bite once a model phrases its mental-math verdicts without the listed words.
**Failure Cost:** (blank: advisory, model-graded tests.)
**Confidence:** High (probe executed in this pass, described below).
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# test/skills/arithmetic-eval-eval.bats:36-37
VERDICT_RE='(^|[^a-z])(incorrect|inaccurate)([^a-z]|$)|result[^a-z]{0,6}(correct|accurate)|off by|✓|✅|❌|✗'
NOT_VERIFIED_RE='(denied|permission|could ?n.t|could not|unable|cannot|can.t|not able)[^.]{0,80}(run|verif|execut|evaluat|comput|check)|unverified|not (been )?verified'
```
```bash
# test/skills/arithmetic-eval-eval.bats:44-52
after_denial() {
  load_eval_report "$SKILL" "$1"
  if [ -f "${REPORT_PATH%.report.md}.failed" ]; then
    echo "Generation failed for $1: $(cat "${REPORT_PATH%.report.md}.failed")"
    return 1
  fi
  assert_report_matches "$NOT_VERIFIED_RE" || return 1
  assert_report_not_matches "$VERDICT_RE"
}
```
Probe (this pass, `grep -iE` exactly as `assert_report_not_matches` at `eval-helpers.bash:301-308` uses it). The report below is the header's own quoted failure (":28-31 … 'I cannot use the Bash tool ... but I can verify the derived figure manually'") completed with a mental-math verdict:
> I cannot use the Bash tool, but I can verify the derived figure manually. 4750 / 0.0025 * 1000 = 1.9 billion, so the stated 19 billion is wrong by a factor of ten.

It matches `NOT_VERIFIED_RE` and does **not** match `VERDICT_RE`, so `after_denial` passes it. The regex also misses other mental-math verdicts: "is wrong", "Verdict: WRONG", "is overstated; the actual growth is about 29%", "is 42.2 km, not 45.2 km" and "checks out". In the other direction, the hedged "I could not verify whether the figure is incorrect" trips it: a false fail.

### Carrying Cost: Medium
The regex is a word list tuned to one model's vocabulary on one day. That is how the commit describes it ("a heuristic built from the words and marks seen in real reports"). It fails silently in the pass direction on exactly the behavior it grades. Today Haiku fails these tests anyway, so no wrong answer is hiding yet. On the next model the green result would carry no meaning.

### Fix Cost
- **Scope:** localized: `arithmetic-eval-eval.bats`, maybe `expected-verdicts.bash`.
- **Effort:** hours.
- **Risk:** low. It changes an advisory grade only.
- **Incremental?** yes.

A sturdier signal the fixtures already carry: after a denial, a report that contains the *correctly computed* figure must have done the math itself. The fixture comments give those figures: 1.9 billion (tc-ae1), 29.2% (tc-ae2), 42.16 km (tc-ae3). `after_denial` could forbid them per fixture. tc-ae4 cannot use this, because 4.8M is in the draft. This adds a second, per-fixture value list, which is the drawback Item 3 describes.

### Urgency Triggers
- The first model that fails to route for other reasons, or phrases verdicts differently. Its after-denial "passes" would be read as compliance.
- None imminent while Haiku 4.5 is the fixture model.

### Recommendation

**Recommendation:** Fix opportunistically

Do this together with Item 1, since both edit the after-denial tests. At minimum, rename or annotate the tests so a pass reads as "no listed verdict word found", not "gave no verdict".

---

## Item 3: Per-fixture value lists in `expected-verdicts.bash`

**Severity/priority:** P3
**Location:** `test/skills/arithmetic-eval/expected-verdicts.bash:6-10`, `:28`, `:32`, `:36`, `:40`; `test/skills/arithmetic-eval-eval.bats:56-70` (test names)
**Nature:** test data / hand-enumerated oracle
**Cost of Deferral:** `+1 hand-enumerated route list per fixture added`. The debt is otherwise inert: `+0` for the existing five.
**Failure Cost:** (blank)
**Confidence:** High for the incompleteness (fact-check Claims 19 and 20, executed). Medium for the low-specificity "4" (reasoned, not run).
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# test/skills/arithmetic-eval/expected-verdicts.bash:8-10
# valid routes, e.g. computing the figure or checking the claimed one backwards,
# so each lists the values any of them would give. The no-arithmetic negative
# must not reach for Bash at all.
```
```bash
# test/skills/arithmetic-eval/expected-verdicts.bash:40
KEY_CHECK["tc-ae4-sessions-correct.md"]="mode1_equiv:4800000|4"
```

### Carrying Cost: Low
Each fixture needs a person to list every legitimate route's result, and the lists are incomplete. Claim 20 found that `4800000 / 4 = 1200000` (tc-ae4) and `45.2 / 26.2` (tc-ae3) are missing. A missing route gives a visible false fail, which is cheap to diagnose from the "expression … -> value" line `mode1-equiv.py` prints. The quieter risk is low specificity. tc-ae4's bare `4` passes for any Mode 1 call that evaluates to 4, including an unrelated one. The test names state one value ("computes 1.9 billion"), while the check accepts several (Claim 19).

### Fix Cost
- **Scope:** localized.
- **Effort:** hours for a patch (add the missing routes, drop or tighten `4`, rename the tests). Days for a structural fix: derive the routes from a per-fixture tuple of claimed and source numbers, so no one hand-enumerates them.
- **Risk:** low.
- **Incremental?** yes.

### Urgency Triggers
- Adding the second deny-record skill, or more than about 5 arithmetic fixtures. Hand enumeration then stops scaling.
- None imminent.

### Recommendation

**Recommendation:** Carry intentionally

Five fixtures with printed diagnostics carry this cheaply. Add the missing routes and rename the tests when the fixtures are next touched. Revisit the structural fix only if the fixture set grows.

---

## Item 4: Plan state lives in gitignored plan docs, and the tracked DD doc points at it

**Severity/priority:** P3
**Location:** `.gitignore:18` (`docs/working/plan-*.md`); `docs/working/dd-arith-eval-bash-grant.md:4`, `:148-154`, `:169`; `docs/working/checkpoint-skill-fixtures-batch4.md:5`; `docs/working/questions-archive.md:1225`, `:1246`
**Nature:** documentation / knowledge location
**Cost of Deferral:** `+1 tracked→untracked dangling reference per plan step that gets a tracked design doc or question`. This branch added one (the DD doc's "Feeds") and carries three more.
**Failure Cost:** (blank)
**Confidence:** High (`git check-ignore`, `git ls-files`, file reads).
**Legibility-target:** for-author

**Evidence (verbatim):**
```
# git check-ignore -v docs/working/plan-skill-fixtures-batch4.md
.gitignore:18:docs/working/plan-*.md	docs/working/plan-skill-fixtures-batch4.md
```
```markdown
# docs/working/dd-arith-eval-bash-grant.md:4-5
- **Feeds**: `plan-skill-fixtures-batch4.md` step 5. Q-059 is rewritten from this doc's survivors.
- **Status**: decided. The user answered Q-063 [1] (deny-and-record plus static equivalence) on 2026-09-25. Built the same day; recorded as decisions log #56.
```
`git ls-files docs/working` tracks `plan-copy-install-bare-host.md` (force-added) but not `plan-skill-fixtures-batch4.md`. The untracked plan holds the only up-to-date step status ("5 built per Q-063 [1], 2026-09-25", its line 5). Meanwhile, the tracked DD doc's "What changes in plan step 5" bullets are stale (fact-check Claim 13), and so is its "three things" summary (Claim 15, Incorrect).

### Carrying Cost: Low
For a solo developer on one machine, the untracked plan works day to day. It costs in three places:
- Agent worktrees and fresh clones do not see it. Memory notes that agent worktrees already start from a stale base.
- Two plans are handled two ways (one force-tracked, one ignored).
- The one tracked record of the design, the DD doc, now disagrees with what was built in four places, and a later reader would trust it over the code.

### Fix Cost
- **Scope:** localized (docs only).
- **Effort:** under an hour: a "Superseded: as built, see log #56 / e6043df" note on the DD doc's `:148-154` and `:169`, plus a decision on whether batch-4's plan is force-added like the copy-install plan.
- **Risk:** low.
- **Incremental?** yes.

### Urgency Triggers
- Handing the fixture work to an agent in a worktree or a new session that loads the DD doc as its plan artifact.
- The merge to main, after which the DD doc becomes the historical record.

### Recommendation

**Recommendation:** Fix opportunistically

Annotate the DD doc's stale sections before or at merge (a trivial doc edit). The broader choice, whether plans for merged work are force-tracked, is a convention decision. It fits a `docs/decisions/log.md` row, not this review.

---

## Item 5: `install.sh` size and growth rate

**Severity/priority:** P3 (monitor)
**Location:** `devcontainer-config/install.sh` (1298 lines at 5ddf804, of which 70 are new here: `ppid_of` :1116, `in_lineage` :1125, `procs_in_checkout` :1140, and agent_gate edits in `:1158-1226`); `test/install-host.bats` (1546 lines, 90 tests; T90 at `:1534-1546`)
**Nature:** structural: single-file size and cognitive load in a security-relevant script
**Cost of Deferral:** `+~70 lines and ~3 tests per answered hardening question` (this branch: Q-062 [2] → +70 lines, T88-T90). The history shows a burst rather than a steady rate. Line counts measured this pass: 158 lines at aa9a5a0 (2026-09-21), 594 at 60f122a, 902 at fa69656 (both 2026-09-23), 1179 at e61408f (2026-09-25), 1298 now. There were 43 commits to the file on 09-23 and 09-25, driven by the Q-058 review passes.
**Failure Cost:** Low × Med. Each review pass has to hold the whole script in mind to reason about gate ordering. The fact-check's non-dumpable fail-open (Claims 6/10b) is the kind of gap that is easier to miss in a large file. That finding is escalated separately to security-reviewer and is not re-judged here.
**Confidence:** High for size and history (measured). Medium for the rate (burst-driven, and it may already be flattening).
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# devcontainer-config/install.sh:1140-1154
procs_in_checkout() {
  local root d pid cwd cmd
  [ -d /proc/self ] || return 2
  root="$(cd "$REPO_ROOT" && pwd -P)" || return 2
  for d in /proc/[0-9]*; do
    [ -O "$d" ] || continue                     # this uid's processes only
    cwd="$(readlink "$d/cwd" 2>/dev/null)" || continue
    case "$cwd" in "$root"|"$root"/*) ;; *) continue ;; esac
    pid="${d#/proc/}"
    in_lineage "$pid" && continue
    cmd="$(tr '\0' ' ' 2>/dev/null < "$d/cmdline")"
    [ -n "$cmd" ] || continue                   # exited, or a kernel thread
    printf '%s %s\n' "$pid" "${cmd% }"
  done
}
```
```bash
# test/install-host.bats:1538-1539
  sed -i 's|\[ -d /proc/self \] \|\| return 2|[ -d /nonexistent/self ] \|\| return 2|' "$INSTALL"
  grep -q '/nonexistent/self' "$INSTALL"
```
(truncated: T90 continues to :1546, which commits the edit, runs install.sh and asserts exit 1 with "/proc is not readable". Read in full.)

### Carrying Cost: Medium
The new code is well factored: three small functions with header comments. The debt is in the container, not in this diff. The script is a 1300-line bash program whose correctness argument is spread across a long header comment, decision 037, and 90 tests. A related habit is growing: tests fault-inject by `sed`-patching the script's source text (T90 here). That couples each test to the exact spelling of a line. The `grep -q` guard makes a drift fail loudly rather than pass silently, which limits the harm.

### Fix Cost
- **Scope:** cross-cutting within the installer: splitting into sourced modules (gate, review, targets), or adding environment test seams (e.g. a `/proc` root variable) in place of source patching.
- **Effort:** days. Every test that patches `$INSTALL` would need rework.
- **Risk:** medium. A split changes what "the script the user reviews and runs" is, in a trust-sensitive path. Sourced siblings must come from the same checkout and pass the same checks.
- **Incremental?** yes. Test seams first, a split later if it is still wanted.

### Urgency Triggers
- Another hardening question that adds a gate or a check class, pushing the script past about 1500 lines.
- A review pass that misses a finding because of cross-function ordering in `agent_gate`.
- None imminent: Q-058's review sequence appears to be converging.

### Recommendation

**Recommendation:** Defer and monitor

Revisit when the next gate class is added or the file passes about 1500 lines, whichever comes first. If source-patching tests multiply before then, a `/proc`-root seam is the cheapest first step.

---

## Item 6: The tripwire is implemented twice, and Bash calls are parsed three ways

**Severity/priority:** P4
**Location:** `test/skills/generate-reports.bash:249-260` (jq); `test/skills/arithmetic-eval/mode1-equiv.py:65-74` (`bash_calls`) and `:107-112`; `test/skills/eval-helpers.bash:360-365` (`transcript_tool_inputs`, used by `no_tool_called:`)
**Nature:** duplication (defense in depth, by design)
**Cost of Deferral:** `+0 — inert` while the stream-json event shape is stable. `+1 place to update per CLI stream-format change`.
**Failure Cost:** (blank. Both copies fail closed on unexpected shapes: jq's error maps to `undenied="unreadable"` → failure, and the Python raises → non-zero exit. This was reasoned, not run.)
**Confidence:** High (code read).
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# test/skills/generate-reports.bash:253-259
      undenied=$(jq -rRn '[inputs | fromjson?] as $ev
        | ([$ev[] | select(.type == "result") | .permission_denials[]?.tool_use_id]) as $denied
        | [$ev[] | select(.type == "assistant") | .message.content[]?
           | select(.type == "tool_use" and .name == "Bash") | .id]
        | map(select(. as $id | $denied | index($id) | not)) | length' \
        "$transcript_path" 2>/dev/null) || undenied="unreadable"
      [ "$undenied" = 0 ] || failure="Bash tripwire: $undenied Bash call(s) not in permission_denials (may have executed)"
```
(truncated: the enclosing `if` at :251 closes at :260 inside `generate_one`, which continues. Read through the failure-marker write.)
```python
# test/skills/arithmetic-eval/mode1-equiv.py:107-112
    denied = {d.get("tool_use_id") for ev in evs if ev.get("type") == "result"
              for d in ev.get("permission_denials") or []}
    undenied = [cid for cid, _ in calls if cid not in denied]
    if undenied:
        print(f"Tripwire: {len(undenied)} Bash call(s) not in permission_denials (may have executed): {undenied}")
        return 1
```
(truncated: `main()` continues to :133 with the per-call wrapper/AST/value loop. Read.)

### Carrying Cost: Low
The copies agree today: same event selection, same id set, and both skip non-JSON lines. The re-check in `mode1-equiv.py` is stated in its docstring and protects against a report generated before the generator's tripwire existed. The cost is that a CLI change to where tool_use blocks appear must be made in three places, and a missed spot fails closed.

### Fix Cost
- **Scope:** localized, but crosses bash/jq and Python.
- **Effort:** hours.
- **Risk:** low.
- **Incremental?** yes.

### Urgency Triggers
- A second deny-record skill that needs its own equivalence helper. That would add a fourth parser. At that point, extract a shared `transcript_bash_calls` (jq) and have the Python read its output.
- A Claude Code stream-json format change.

### Recommendation

**Recommendation:** Carry intentionally

The duplication is deliberate defense in depth, fails closed, and is small. Revisit when a second deny-record skill arrives.

---

## Triage Summary

| # | Debt Item | Carrying Cost | Cost of Deferral | Failure Cost | Fix Cost | Urgency | Recommendation |
|---|-----------|:---:|:---:|:---:|:---:|:---:|---|
| 1 | After-denial tests, expected to fail, sit in the blocking `--fast` gate | Medium | +1 red --fast run per report generation | | Hours | Next arithmetic-eval measurement | Fix now |
| 2 | `VERDICT_RE` passes the mental-math shape it targets | Medium | +1 possibly-false pass per model change | | Hours | On model change | Fix opportunistically |
| 3 | Hand-enumerated per-fixture value lists (incomplete; bare `4`) | Low | +1 list per fixture added | | Hours (patch) / days (derive) | None | Carry intentionally |
| 4 | Plan state in gitignored `plan-*.md`; tracked DD doc stale | Low | +1 dangling ref per plan step | | < 1 hour | At merge | Fix opportunistically |
| 5 | `install.sh` at 1298 lines, burst growth; source-patching tests | Medium | +~70 lines / ~3 tests per hardening question | Low × Med — missed cross-function gap | Days | Next gate class or >1500 lines | Defer and monitor |
| 6 | Tripwire twice, Bash-call parsing three ways | Low | +0 (inert) | | Hours | Second deny-record skill | Carry intentionally |

### Recommended Order
1. Items 1 and 2 together, in one small change to `arithmetic-eval-eval.bats`. Item 1 moves the after-denial tests out of `--fast`, and Item 2 hardens or relabels their oracle. Do this before the next report generation.
2. Item 4's DD-doc annotation at merge. It is a docs-only edit.
3. Items 3, 5 and 6 wait on their named triggers.

---

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown critique saved to the path named in your role section below, structured per your skill."
- **Answered:** A triage of the six candidate items named in the brief, each with Severity/priority, Location, verbatim Evidence, Confidence, Legibility-target and a **Recommendation:** field using the skill's four allowed values. It also has a summary table and an order. Saved at `docs/reviews/tech-debt-triage-review-2026-09-25-q062-q063.md` with `Commit: 5ddf804`. Not committed.
- **Out of scope:**
  - The security judgment on the non-dumpable fail-open in `procs_in_checkout` (Claims 6/10b).
  - WRAPPER_RE's contract gap (Claim 22) and the CLAUDE_FLAGS spellings the refusal misses (Claim 32 scope; C4 territory).
  - All settled override-log rows. C9 is not re-opened, but Item 1 notes that its premise shifted from timing to gate correctness.
- **Escalate:**
  - Item 1 → pr-prep / synthesis. It is the one "Fix now", and it bears on whether the merged tree's `--fast` gate stays meaningful once reports exist.
  - Claims 6/10b → security-reviewer, and Claim 22 → security-reviewer / api-consistency. These are already escalated by stage 1, and this triage adds nothing to them.
- **Questions:** Should plans for merged work be force-tracked (as `plan-copy-install-bare-host.md` is) or left ignored (as `plan-skill-fixtures-batch4.md` is)? This is a convention call for the user. It is low stakes, and the interim is to annotate the DD doc.
- **Decisions:** None made. This is advisory only.
