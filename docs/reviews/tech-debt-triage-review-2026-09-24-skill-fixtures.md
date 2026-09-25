Commit: 04c0746

# Tech Debt Triage: skill-fixtures pass 1 (harness code)

Scope: the 40 harness files in pass 1 (`git diff answers-2026-09-20...skill-fixtures -- <files>`). Fixture data, eval-criteria and expected-verdicts are context only. I use the merged code-fact-check report (`docs/reviews/code-fact-check-report-skill-fixtures.md`) as the foundation and cite its claim numbers. I did not re-verify behavior it already documents.

History: 12 of the branch's 47 commits touch `generate-reports.bash` or `eval-helpers.bash`: bf172c5, 4f91e29, e37a0b4, 6c4489d, 39864de, 3023a20, 68ffae7, ef05331, 489a19f, 2e98d3c, fa3c5c0 and d700f62. The harness is churning, not stable. Several items below take their cost-of-deferral from that rate.

Severity vocabulary: this skill has no severity scale. Each item carries the skill's Carrying Cost (High/Medium/Low), an optional Failure Cost and one of the four Recommendations. Confidence is High / Medium / Low.

---

## Tech Debt Triage: D1. Tool-safety invariants that live in comments, not code

**Location:** `test/skills/generate-reports.bash:48-50`, `:89-94`; `test/generate-reports.bats:272-282`; the rationale comment repeated in about 12 inline `runner.bash` files
**Nature:** structural. A safety invariant is documented but not enforced.
**Cost of Deferral:** `+1 unenforced tool policy per new runner`. Each skill added to HC1 writes its tool list by hand against a guard that checks only two exact tokens.
**Failure Cost:** `Med × Med`. A runner that grants `Read` in inline mode, or `Bash`, `NotebookEdit` or `Write(*)` in any mode, passes every check (Claim 21, executed). If the model then reads `expected-verdicts.bash` or `eval-criteria.md`, eval pass rates go up without anyone noticing. The cost is corrupted measurement, not a production incident. That is the harm this harness exists to prevent. (Probability is Med: the runners are hand-written, 22 exist and more are planned.)
**Confidence:** High for the gap (Claims 2, 20 and 21 were executed). Medium for the probability.
**Legibility-target:** for-orchestrator-synthesis (the exploit side belongs to security-reviewer's escalation, `generate-reports.bash:89-94`, per the fact-check Escalations section)

Evidence:
```bash
# test/skills/generate-reports.bash:48-50
# Cheat prevention: the tool allowlist never includes Write, and in "repo" mode
# the working directory holds only the fixture, so the model cannot reach
# expected-verdicts.bash or eval-criteria.md. "inline" skills should omit Read.
```
```bash
# test/skills/generate-reports.bash:89-91
case ",$FIXTURE_TOOLS," in
  *,Write,*|*,Edit,*)
    echo "Error: $RUNNER_FILE: FIXTURE_TOOLS must not include Write or Edit" >&2
```
```bash
# test/generate-reports.bats:274-280 — the "accepts" test only checks the file exists (Claim 2)
@test "every committed fixture set has a runner the generator accepts" {
...
    [ -f "$skill_dir/runner.bash" ] || missing+=("$(basename "$skill_dir")")
```
(excerpt ends at :280; the test closes at :282. I read all of it.)

### Carrying Cost: Low
The 22 runners in the tree are all compliant today (Claim 20; Claim 2's scope note). Nobody pays friction day to day. The cost is latent. "Inline skills should omit Read" is enforced only by each author reading a comment. The comment is restated in about 12 runners. The one test named as if it checks the policy checks only that the file exists.

### Fix Cost
- **Scope:** localized. Two files: `generate-reports.bash` and `generate-reports.bats`.
- **Effort:** hours. Replace the deny-list `case` with a per-mode allow-list: inline allows `none|WebSearch|WebFetch|Agent`, repo and tree allow `Read|Grep|Glob`. Split on commas and trim spaces. Move the validation into a function the bats test can call after sourcing each committed runner. About 30–50 lines.
- **Risk:** low. The existing bats suite (19 tests) stubs `claude`. A new runner that needs a new tool has to widen the allow-list on purpose. That is the point.
- **Incremental?** Yes.

### Urgency Triggers
- The next HC1 batch, or any new runner. Each one is written against the unenforced policy.
- The A8 measurement and any later round that treats eval pass rates as signal. A leaked verdict file would silently invalidate those numbers.

### Recommendation

**Recommendation:** Fix opportunistically

Carrying cost is low. Failure cost is Med × Med, below the skill's fix-now bar (Med × High). The opportunity is right now, though: the branch is unmerged, the fix is hours in two files, and the policy already exists in prose. This is a multi-file change, so per the skill it goes through RPI. The scope is small enough that the review-fix loop's own fix pass can serve as that RPI.

---

## Tech Debt Triage: D2. `generate-reports.bash` width, and the duplicated claude invocation

**Location:** `test/skills/generate-reports.bash:130-233` (`generate_one`, about 100 lines, three modes plus the transcript option), `:197-201` and `:208-212` (two copies of the claude pipeline), `:224-229` (the summary line, specific to fact-check)
**Nature:** structural. One function has grown mode branches, and one command is copy-pasted.
**Cost of Deferral:** `+1 mode/option branch per new fixture shape`. The branch history bears this out: repo mode came in 4f91e29, the transcript option in 489a19f, tree mode in 2e98d3c, and the jq change in d700f62, all inside this one function. Each new claude flag has to be edited in two places.
**Failure Cost:** (not material; left blank)
**Confidence:** High
**Legibility-target:** for-author

Evidence:
```bash
# test/skills/generate-reports.bash:197-201
    (cd "$temp_dir" && printf '%s' "$prompt" \
      | claude "${claude_args[@]}" \
        $model_flag \
        ${CLAUDE_FLAGS:-} \
    ) > "$out_path" 2>/dev/null || true
```
```bash
# test/skills/generate-reports.bash:208-212
    printf '%s\n\n%s' "$prompt" "$fixture_content" \
      | claude "${claude_args[@]}" \
        $model_flag \
        ${CLAUDE_FLAGS:-} \
      > "$out_path" 2>/dev/null || true
```
```bash
# test/skills/generate-reports.bash:226-227
    # code-fact-check heads claims "## Claim N"; fact-check heads "## Verdict for CN:".
    claim_count=$(grep -cE '^## (Claim [0-9]+|Verdict for C[0-9]+)' "$report_path" || true)
```
(excerpt ends at :227; `generate_one` continues to :233. I read all of it.)

### Carrying Cost: Medium
At 265 lines the file is not large. The cost is concentration: every harness change on this branch went into `generate_one`, and the ordering invariants inside it are hard to hold in your head. D3 shows that the `--tools` placement comment was already wrong (Claim 27). The two pipelines duplicate the part most likely to change next (flags, redirection, error handling). Right now both discard claude's stderr and exit status (`2>/dev/null || true`), so any change there has to be made twice. The summary line prints "0 claims" for 20 of the 22 skills, which misleads whoever runs the generator.

### Fix Cost
- **Scope:** localized, one file.
- **Effort:** hours. Extract `prepare_workdir <mode>`, which echoes the working directory and the stdin payload, and a single `run_claude <dir> <stdin>`. Make the summary line generic (count `**Severity:**`, `**Verdict:**` and `**Recommendation:**` fields), or drop the claim count.
- **Risk:** low. `test/generate-reports.bats` stubs `claude` and records argv, so a refactor that changes the argv fails a test.
- **Incremental?** Yes. Merging the invocation first is a safe step on its own.

### Urgency Triggers
- The next mode or option (a fourth fixture shape, per-fixture tool overrides, capturing stderr for failed runs).
- Inline mode being changed to run in a temp dir (see D4). That rewrites the same branch.

### Recommendation

**Recommendation:** Fix opportunistically

Carrying cost is medium and growing at the rate the branch history shows. The fix is cheap and well covered by the stubbed bats suite. Do it the next time anyone touches `generate_one`. The duplicated invocation is the first piece to take.

---

## Tech Debt Triage: D3. Stale and wrong harness comments

**Location:** `test/skills/generate-reports.bash:32-33` (Claim 16, Stale), `:157-158` and `test/generate-reports.bats:126` (Claim 27, Incorrect), `test/skills/eval-helpers.bash:7` and `:135` (Claim 40, Stale), and the test name at `test/generate-reports.bats:274` (Claim 2, Incorrect)
**Nature:** documentation drift in a file that is changing fast.
**Cost of Deferral:** `+1 stale comment per harness commit`, on the evidence of this branch: three of these comments went stale in later commits on the same branch (4f91e29→2e98d3c, bf172c5→83c9681).
**Failure Cost:** (blank)
**Confidence:** High (the fact-check verdicts are High or Medium and agree across replicates, except Claim 27 r3=Unverifiable)
**Legibility-target:** for-author

Evidence:
```bash
# test/skills/generate-reports.bash:32-33
# them: in "repo" mode the fixture is copied in as subject.<ext>, and that
# neutral name is what fixture_prompt receives in both modes.
```
```bash
# test/skills/generate-reports.bash:157-158
  # --tools stays last before the model/extra flags: an empty value must not
  # swallow the next flag.
```
```bash
# test/skills/eval-helpers.bash:7
# Args: $1 = skill name (fact-check or code-fact-check)
```

### Carrying Cost: Medium
Claim 27 is the one that matters. It states a safety rationale for argument order that the code does not provide: `--model` is the "next flag" whenever `CLAUDE_MODEL` is set. A maintainer who trusts that comment will reason wrongly about argv ordering. The others are cosmetic, but they sit on the file's contract, the header every runner author reads.

### Fix Cost
- **Scope:** localized, three files.
- **Effort:** under an hour. The fact-check already gives the corrected wording.
- **Risk:** low.
- **Incremental?** Yes.

### Urgency Triggers
- None imminent. Stale comments build up at the harness's commit rate.

### Recommendation

**Recommendation:** Fix now

Each file needs only a comment edit, well under 50 lines, so per the skill they are fixed in place with no RPI. Claim 27 misstates a safety property on a trust-boundary path. For the renamed test at `generate-reports.bats:274`, either rename it to "…has a runner.bash" or, better, let D1's fix make the current name true.

---

## Tech Debt Triage: D4. The 22 near-duplicate `runner.bash` files

**Location:** `test/skills/*/runner.bash` (9–37 lines each; 12 set `FIXTURE_TOOLS="none"`, 7 set `Read,Grep,Glob` in repo mode)
**Nature:** duplication, but mostly in comments, not code.
**Cost of Deferral:** `+1 copy of the shared rationale per new skill`. The code in each file is two variables and one `printf`. That duplication is `+0 — inert`.
**Failure Cost:** (blank)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Evidence (the same rationale restated verbatim in form across runners):
```bash
# test/skills/cowen-critique/runner.bash:2-3
# Cowen critique: the draft goes inline in the prompt. No Read (inline mode runs
# in the real repo, where Read could reach expected-verdicts.bash) and no Write,
```
```bash
# test/skills/what-if-analysis/runner.bash:2-3
# What-if analysis: the proposal goes inline in the prompt. No Read, because
# inline mode runs claude in the real repo, where Read could reach
```
```bash
# test/skills/security-reviewer/runner.bash:5-6  (repo-mode runners share one shape)
FIXTURE_TOOLS="Read,Grep,Glob"
FIXTURE_MODE="repo"
```

### Carrying Cost: Low
The part that varies, the prompt text and per-skill notes such as the ai-personas catalog, dependency-upgrade's no-execution note and self-eval's `fixture_base`, is the real content of each file. A shared template would hide per-skill decisions that reviewers need to see. The repeated rationale is the one real cost: Claim 39 found it imprecise ("real repo" should be "caller's cwd") in about 11 copies at once. Every copy will go stale at the same moment if inline mode changes.

### Fix Cost
- **Scope:** cross-cutting across 22 files, but mechanical.
- **Effort:** hours.
- **Risk:** low.
- **Incremental?** Yes.

The better fix is structural and removes the rationale entirely. Run inline mode in an empty `mktemp -d` too (a D2-scale change in `generate_one`). Then "Read could reach expected-verdicts.bash" is no longer true, and each runner's comment can shrink to its skill-specific deviations. D1's allow-list then records the policy in one place.

### Urgency Triggers
- Any change to where inline mode runs. About 11 comments go stale together.
- none otherwise.

### Recommendation

**Recommendation:** Carry intentionally

The code duplication does not compound, and it is the right shape for per-skill configuration. Do not build a runner template or generator. Once D1 or the inline-temp-dir change lands, trim the repeated rationale from the runner comments in the same commit. Until then the copies are accurate enough (Claim 39: Mostly accurate).

---

## Tech Debt Triage: D5. Overlapping assertion helpers in `eval-helpers.bash`

**Location:** `test/skills/eval-helpers.bash:183-195` (`assert_severity`), `:200-208` (`assert_no_severity`), `:216-224` (`assert_no_verdict`), `:242-250` (`assert_field`), `:255-262` (`assert_no_field`)
**Nature:** mild duplication. `assert_severity` is `assert_field Severity`, and `assert_no_severity`/`assert_no_verdict` are `assert_no_field Severity|Verdict`.
**Cost of Deferral:** `+0 — inert`. New fields use the generic `field_match:`/`no_field:`, so no further copies are needed.
**Failure Cost:** (blank)
**Confidence:** High
**Legibility-target:** for-author

Evidence:
```bash
# test/skills/eval-helpers.bash:202-203
  hits=$(field_values Severity \
    | grep -iE "^(${forbidden})([^[:alpha:]]|$)" || true)
```
```bash
# test/skills/eval-helpers.bash:257
  hits=$(field_values "$field" | grep -iE "^(${forbidden})([^[:alpha:]]|$)" || true)
```

### Carrying Cost: Low
The logic is tiny, already shares `field_values`, and is tested (Claim 11). The named check types are the KEY_CHECK vocabulary that 22 expected-verdicts files use, so the names have to stay even if the bodies merge.

### Fix Cost
- **Scope:** localized, one file.
- **Effort:** under an hour. Make the three specific functions one-line wrappers.
- **Risk:** low. The messages would change slightly ("Severity" versus "severity").
- **Incremental?** Yes.

### Urgency Triggers
- none identified

### Recommendation

**Recommendation:** Carry intentionally

It is ergonomic, inert and tested. Collapse it only if someone is already editing these functions.

---

## Tech Debt Triage: D6. Title-window magic numbers coupled to SKILL.md preambles

**Location:** `assert_title_matches ... 12` in 7 format suites (`cowen-critique-format.bats:24`, `yglesias-critique-format.bats:24`, `business-plan-critique-*-format.bats`, `ai-personas-critique-format.bats:24`, `what-if-analysis-format.bats:39`); `pre-mortem-format.bats:26` (10); `self-eval-format.bats:19` (15)
**Nature:** coupling. Each window size encodes the length of the warning that SKILL.md puts above the title.
**Cost of Deferral:** `+0 — inert` until a SKILL.md preamble grows.
**Failure Cost:** (blank)
**Confidence:** Medium. The window sizes rest on Claims 3 and 7 (Mostly accurate), not on an enforced bound.
**Legibility-target:** for-author

Evidence:
```bash
# test/skills/cowen-critique-format.bats:22-24
  # SKILL.md puts the no-fact-check warning (up to 5 lines) above the title,
  # so the default 5-line window would fail a report that follows the skill.
  assert_title_matches '^# .*Cowen.*Critique' 12
```

### Carrying Cost: Low
The failure mode is loud: a format test goes red, and the comment next to it explains why. It never passes when it should fail.

### Fix Cost
- **Scope:** localized. **Effort:** hours. **Risk:** low. **Incremental?** Yes. One option is to skip a leading blockquote or warning block before applying the window.

### Urgency Triggers
- A SKILL.md warning or preamble edit that lengthens it past about 7 lines.

### Recommendation

**Recommendation:** Defer and monitor

Revisit when a SKILL.md preamble edit turns one of these title tests red.

---

## Not debt (checked)

- **arithmetic-eval-gate.bats extracts the live SKILL.md heredocs.** This is coupling by design, and it is guarded by non-empty-extraction tests plus a delimiter-uniqueness test. It is the opposite of a vendored copy that could drift (Claim 5, Verified, executed; Claim 44). No triage entry. Positive assertion: `route: code-fact-check`.
- **KEY_CHECK's `;` separator** (`eval-helpers.bash:78`) would split any pattern that contains a `;`. I grepped the committed expected-verdicts files: no KEY_CHECK value uses one today. The limitation is not documented at the check syntax. It is a one-line note, below the triage threshold.

---

## Triage Summary

| # | Debt Item | Carrying Cost | Cost of Deferral | Failure Cost | Fix Cost | Urgency | Recommendation |
|---|-----------|:---:|:---:|:---:|:---:|:---:|---|
| D1 | Tool-safety policy in comments; exact-token guard; "accepts" test checks existence only | Low | +1 unenforced tool policy per new runner | Med × Med — leaked verdicts inflate eval pass rates | Hours | Next HC1 batch / A8 | Fix opportunistically |
| D2 | `generate_one` width; duplicated claude invocation; fact-check-only summary | Medium | +1 mode/option branch per new fixture shape | | Hours | Next mode or flag | Fix opportunistically |
| D3 | Stale/wrong comments (Claims 2, 16, 27, 40) | Medium | +1 stale comment per harness commit | | <1 hour | None | Fix now |
| D4 | 22 near-duplicate runner.bash (mostly repeated rationale) | Low | +1 rationale copy per new skill | | Hours | Inline-mode cwd change | Carry intentionally |
| D5 | Overlapping assert_* helpers | Low | +0 — inert | | <1 hour | None | Carry intentionally |
| D6 | Title-window magic numbers | Low | +0 — inert | | Hours | Preamble growth | Defer and monitor |

### Recommended Order
1. **D3 first.** It is comment-only, and it fixes the one misleading safety rationale (Claim 27).
2. **D1 and D2 together, as one small RPI.** They touch the same function and the same bats file. Merge the claude invocation, move inline mode into a temp dir, and add the per-mode tool allow-list with a bats test that sources every committed runner through it. That also makes D3's renamed test name true again.
3. **Then trim D4's repeated runner comments** in the same commit, since the rationale they repeat will then be enforced centrally (or no longer true).
4. **Leave D5 and D6** unless someone is already in those lines.

---

## Goal-Alignment Note
- **Success criterion (restated verbatim):** a markdown critique saved to /workspace/docs/reviews/tech-debt-triage-review-2026-09-24-skill-fixtures.md with a `Commit: 04c0746` line at the top, structured per the tech-debt-triage skill, ending with a Goal-Alignment Note.
- **Answered:** yes. There are six debt items, each with carrying cost, cost of deferral, fix cost, urgency and one of the four allowed recommendations, followed by a summary table and an order. I covered all three suggested examples: runner duplication is D4, stale comments are D3 and generate-reports width is D2. I added D1, which I judge the most consequential.
- **Out of scope:** pass-2 fixture data and eval-criteria; whether the CLI actually accepts `Write(*)`/`Bash` or lets an empty `--tools` value swallow a flag (Claims 21 and 27 scope notes; the fact-check could not run claude); and whether matrix-analysis sub-agents inherit `--tools` (Claim 31). Those are exploit questions routed to security-reviewer.
- **Escalate:** D1's failure cost depends on the security-reviewer escalations at `generate-reports.bash:89-94` and `matrix-analysis/runner.bash:5-6`. If security-reviewer confirms that a slipping tool spelling actually grants write or read access, raise D1's failure cost to Med × High, which makes it **Fix now** per the skill.
- **Decisions I made:** I rated failure cost as corrupted eval measurement rather than production harm, since this is test infrastructure. I recommended against templating the runners, because the per-skill prompt is the real content. I ran no `claude` and did not run generate-reports.bash.
