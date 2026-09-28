Commit: 795ff71

# Tech-debt triage — branch integrate/q077-q078-q080

Critic: tech-debt-triage (contextual, advisory). All findings are **Consider** tier. None qualifies for the executable-defect channel.
Scope: debt this branch adds or accepts in Q-077 (auto-approve deny backstop), Q-078 (narrowed report stamp, committable reports) and Q-080 (front-loaded skill descriptions). I relied on the fact-check reports named in the critic brief for what the code does, and did not re-verify it. Git-history rates come from `git log --since=2026-08-27 main`.

## Triage Summary

| # | Debt item | Carrying cost | Cost of deferral | Failure cost | Fix cost | Urgency | Recommendation |
|---|-----------|:---:|:---:|:---:|:---:|:---:|---|
| 1 | Sandbox half of Q-070 [1] not built, and nothing in `questions.md` tracks it once Q-077 closes | Low | +1 closed question that loses the only tracker, at this merge | Med × High (credential exfiltration by an obfuscated spelling; the deny rule is the only boundary) | Hours to file the question; days or more to build the sandbox | Imminent (the tracker is lost at merge) | Fix now (file the question only) |
| 2 | Allow and deny readers each walk the three settings files separately | Low | +0 (inert until a settings source is added) | Low × High (a source read for allow but not for deny means approving a denied command) | Hours, ~20 LOC, one file | None | Fix opportunistically |
| 3 | Accepted bypass spellings pinned as passing tests | Low | +0 (inert) | Med × High (same threat as #1) | Not fixable in the hook: patching spellings one at a time does not converge (decision log 53) | Tied to #1 | Carry intentionally |
| 4 | `Bash(rm *)` vs bare `rm`: documented divergence, no test | Low | +0 (inert: no deny rule in the repo uses the `X *` form) | — | Hours | Trigger: first `Bash(X *)` deny rule, or Claude Code documents the semantics | Defer and monitor |
| 5 | Shared harness left out of the report stamp | Low (0 reports exist) | +0 now; after regeneration, +1 silently stale report set per output-changing harness edit (21 harness commits in 30 days) | — | Hours | Trigger: first regenerated report committed (Q-067) | Defer and monitor |
| 6 | Reports can be committed but none are | Low | +0 (tracked as Q-067, deferred behind A8) | — | Model compute, not code | Q-067 | Carry intentionally |
| 7 | Trigger phrases duplicated between description and body in 25 skills, in two different styles | Medium | +1 chance of drift per trigger-phrase edit (36 SKILL.md commits in 30 days, 10 of them to code-review) | — | Hours: one bats check | None | Fix opportunistically |
| 8 | Hook size: 697 lines (593 on main), over the 500-line guideline | Low | about +100 lines per security amendment (4 hook commits in 30 days) | — | Hours to days; splitting needs a deploy decision | None | Carry intentionally |

---

## 1. Sandbox half not built, and no open question tracks it

**Severity:** Consider · **Confidence:** medium-high · **Legibility-target:** for-orchestrator-synthesis
**Location:** `docs/decisions/log.md:74` (row 53 amendment); `docs/working/questions.md` (Q-077 entry)
**Evidence:**
- log.md row 53: `The sandbox half of Q-070 [1] is not built: it needs image and runArgs changes that are open as a follow-up question.`
- questions.md Q-077: `Implement Q-070 [1]. The cc-isolated settings merge gains Bash deny rules for the credentials path and a sandbox config.`
- A grep of `docs/working/questions.md` and `questions-archive.md` for `sandbox half|runArgs|bubblewrap` found no entry. The only sandbox mention in the open index is Q-066, which is unrelated (tool-map drift).

**Nature:** tracking and process debt on top of accepted security debt.
**Cost of deferral:** a step change rather than a rate. Once this branch merges, Q-077 will be marked ANSWERED and archived. After that, "open as a follow-up question" refers to nothing. Row 53's revisit condition ("if the sandbox is removed") has held since the start, so the log alone will not prompt anyone.
**Failure cost:** `Med × High`. In cc-isolated, `permissions.deny` is now the only thing between a prompt-injected agent and `~/.claude/.credentials.json`. The branch itself pins three spellings that get past it (#3).

### Carrying cost: Low
Nothing breaks day to day. The cost is that the one mitigation that would close the class of bypasses (a sandbox that denies the file read, whatever the command spelling) has no owner or trigger.

### Fix cost
- **Scope:** localized. It is one new `questions.md` entry.
- **Effort:** minutes to file, with `scripts/questions.sh next-id` and `index`. Building the sandbox itself is a separate item of days or more: image, bwrap, socat, and user namespaces or a runArgs change.
- **Risk:** low.
- **Incremental?** yes.

### Urgency Triggers
- Imminent: the merge closes Q-077, the only tracker.
- A second prompt-injection reproduction using an obfuscated spelling.

**Recommendation:** Fix now

Before or with the merge, file a new `Q-NNN · cc-isolated-sandbox-half` entry with `Needs: you: judgment`, since the image and runArgs changes carry a privilege tradeoff. Point row 53 at that ID instead of "a follow-up question". Building the sandbox is not part of this recommendation; it is Defer and monitor under the new entry. Related, same fix pass: Q-077's `Interim:` line still reads `The reproduction has still not been re-run first-hand`, but row 53 now says `re-run first-hand: allow`. Update it when Q-077 closes.

---

## 2. Deny and allow each walk the settings files separately

**Severity:** Consider · **Confidence:** high · **Legibility-target:** for-author
**Location:** `hooks/auto-approve-allowed-commands.sh:132-151` (`get_deny_globs`) and `:170-196` (`get_allowed_prefixes`)
**Evidence (both functions read in full):**
```
get_deny_globs() {                          # :132
  ...
    extract_deny_from_file "$HOME/.claude/settings.json"
    if [[ -n "$git_root" ]]; then
      extract_deny_from_file "$git_root/.claude/settings.json"
      extract_deny_from_file "$git_root/.claude/settings.local.json"
    else
      extract_deny_from_file ".claude/settings.json"
      extract_deny_from_file ".claude/settings.local.json"
```
```
get_allowed_prefixes() {                    # :170
  ...
    extract_prefixes_from_file "$HOME/.claude/settings.json"
    if [[ -n "$git_root" ]]; then
      extract_prefixes_from_file "$git_root/.claude/settings.json"
      extract_prefixes_from_file "$git_root/.claude/settings.local.json"
    else
      extract_prefixes_from_file ".claude/settings.json"
      extract_prefixes_from_file ".claude/settings.local.json"
```
**Nature:** structural duplication on a security path.
**Cost of deferral:** `+0 — inert`. The two lists match today.
**Failure cost:** `Low × High`. Suppose someone adds a settings source to the allow walk only, for example `~/.claude/settings.local.json` or managed settings. The hook would then approve commands from that source while never reading its deny rules, which is the exact failure Q-077 exists to prevent. The test "deny rules from the project settings are honored as well as the global ones" covers the current files but would not catch a new source added to one list.

### Carrying cost: Low
Four hook commits in 30 days. Anyone widening the allow sources has to remember a second list that nothing points them to.

### Fix cost
- **Scope:** localized, one file.
- **Effort:** hours, about 20 LOC. Add a `settings_files()` helper that prints the paths, and have both readers loop over it.
- **Risk:** low. The existing bats suite covers both readers.
- **Incremental?** yes.

### Urgency Triggers
- Any change to the set of settings files the hook reads.

**Recommendation:** Fix opportunistically

It is a trivial single-file fix under 50 LOC, so do it in place the next time the hook is touched rather than through RPI.

---

## 3. Accepted bypass spellings pinned as passing tests

**Severity:** Consider · **Confidence:** high · **Legibility-target:** for-orchestrator-synthesis
**Location:** `test/auto-approve-allowed-commands.bats` (the three `string-match limit: … (documented, not fixed)` tests, diff lines +336–361)
**Evidence:**
```
@test "string-match limit: a spelling without the literal name is still approved (documented, not fixed)" {
  # Deny rules are string matches. This pins the limit the header and
  # wiring.json _comment state, so the docs cannot silently overclaim.
```
**Nature:** accepted security debt, deliberately made visible.
**Cost of deferral:** `+0 — inert`. The set of bypasses does not grow over time; it is fixed by the choice of string matching.
**Failure cost:** `Med × High`, the same threat as #1.

### Carrying cost: Low
The tests are the right way to hold this debt. If a future filter change starts catching one of these spellings, the test fails and forces the header, the `wiring.json` `_comment` and decision 53 to be updated together, so the docs cannot silently overclaim. One small cost: a test that asserts `allow` for an exfiltration command reads as an endorsement unless the reader knows the pattern. The `(documented, not fixed)` suffix handles that.

### Fix cost
- **Scope:** systemic. The real fix is the sandbox (#1), not the hook.
- **Effort:** not bounded in the hook. Decision 53 records that patching constructs one at a time does not converge.
- **Risk:** high if attempted in the hook: false confidence plus more hook growth (#8).
- **Incremental?** no.

### Urgency Triggers
- Whatever escalates #1.

**Recommendation:** Carry intentionally

These tests are good debt bookkeeping. The recommendation depends on #1 being tracked. Without that, "carry" turns into "forget".

---

## 4. `Bash(rm *)` vs bare `rm`: documented, not pinned

**Severity:** Consider · **Confidence:** medium · **Legibility-target:** for-author
**Location:** `hooks/auto-approve-allowed-commands.sh:54-58` (header `KNOWN DIVERGENCE`)
**Evidence:**
```
# bare `Bash` deny rule denies everything. KNOWN DIVERGENCE: whether Claude
# Code's `Bash(rm *)` also matches a bare `rm` with no arguments is not
# documented anywhere this repo records. Here it does not (`rm *` needs the
# space).
```
**Nature:** semantic divergence from an upstream matcher whose behavior is unknown.
**Cost of deferral:** `+0 — inert`. The only Bash deny rule in `hooks/wiring.json` is `Bash(*.credentials.json*)`, and it does not depend on the space question. The legacy `rm -rf:*` test uses the `:*` form.

### Carrying cost: Low
It only matters once someone writes a `Bash(X *)` deny rule and expects it to cover bare `X`. The header tells them to use `Bash(X:*)` instead.

### Fix cost
- **Scope:** localized.
- **Effort:** hours. Add one bats test pinning the current behavior (`Bash(rm *)` does not deny bare `rm`), so a future matcher change shows up as a deliberate decision.
- **Risk:** low.
- **Incremental?** yes.

### Urgency Triggers
- The first `Bash(X *)`-form deny rule added to `wiring.json` or to any settings file.
- Claude Code documents its matcher semantics, or the #39344 follow-up resolves them.

**Recommendation:** Defer and monitor

Unlike the three bypass spellings, this behavior is not pinned. A pinning test costs about 10 lines and would put it on the same footing as #3, so it is worth adding the next time the test file is touched.

---

## 5. Shared harness left out of the report stamp

**Severity:** Consider · **Confidence:** high · **Legibility-target:** for-author
**Location:** `test/skills/runner-contract.bash:187-203` (`report_stamp` and its comment)
**Evidence:**
```
# skill's own. Shared harness files are deliberately not stamped: this file,
# generate-reports.bash, transcript.jq. ...
# The accepted cost: a harness change that alters
# generated output goes unnoticed until the affected skill is regenerated.
```
**Nature:** a test-infrastructure freshness gap that was accepted deliberately (Q-071 [1]).
**Cost of deferral:** `+0` today, because `git ls-files 'test/skills/*/output/*'` returns 0 files, so there is nothing to go stale. After the first regeneration, each output-changing harness edit leaves one stale report set that passes as fresh. The harness had 21 commits on main in the last 30 days, although most of them do not change output.

### Carrying cost: Low
It is inert until reports exist. The alternative, stamping the harness, kept every report red, which is why this tradeoff was chosen.

### Fix cost
- **Scope:** localized.
- **Effort:** hours. One option: record a `harness <sha>` line in the stamp that `check_report_stamp` reports as a **warning**, not a failure. That shows harness drift without re-creating the "every report is red" problem. Old-format stamps already read as stale, so a format change is cheap until the first reports are committed.
- **Risk:** low. Changing the stamp format after reports are committed would stale them all once.
- **Incremental?** yes.

### Urgency Triggers
- Q-067 regeneration, meaning the first committed reports. After that, a format change costs one full regeneration (about 180 model runs), so the cheapest time to decide is before it.

**Recommendation:** Defer and monitor

Re-evaluate before Q-067 runs. A one-line note on Q-067 ("decide the harness-warning line before regenerating") would attach the trigger to the event.

---

## 6. Reports can be committed but none are

**Severity:** Consider · **Confidence:** high · **Legibility-target:** for-orchestrator-synthesis
**Location:** `.gitignore:11-20`
**Evidence:** `# Generated eval reports are to be committed once generated (Q-071 [1]; none` / `# yet)`. `git ls-files 'test/skills/*/output/*'` returns 0.
**Nature:** policy set up in advance, with nothing yet to exercise it.
**Cost of deferral:** `+0 — inert`. It is tracked as Q-067 (deferred behind A8), and health-check warns about NOT RUN suites.

### Carrying cost: Low
The comment says "none yet", so the state is honest. The negation patterns (`output/*` plus `!*.report.md` and the rest) will first be exercised on a real commit. A tree-mode fixture that writes into a subdirectory of `output/` would be ignored silently, but I found no such fixture writer. That last point is `[unverified — submitted as claim]`.

### Fix cost
Compute (Q-067), not code.

### Urgency Triggers
- Q-067 / A8.

**Recommendation:** Carry intentionally

---

## 7. Trigger phrases duplicated between description and body, in two styles

**Severity:** Consider · **Confidence:** high · **Legibility-target:** for-author
**Location:** `skills/*/SKILL.md` (all 25). Example: `skills/tech-debt-triage/SKILL.md:6-8` against `:22`. Counter-example: `skills/pre-mortem/SKILL.md:4-8` against `:57`.
**Evidence:**
- tech-debt-triage description: `Triggers: "should we fix this", "is this worth refactoring", ...`. The body `## When to use` repeats the full list and extends it (`... scoping a cleanup sprint, refactor week, or backlog grooming pass`).
- pre-mortem body: `More trigger phrases: "it's six months later and this didn't work — what happened", ...`. Here the body holds only the displaced phrases.
- I ran a scratch script that checks whether each quoted phrase in the description also appears in the body. 23 of 25 skills repeat every description phrase in the body. pre-mortem (4 phrases) and design-space-situating (1 phrase, `"situate this decision"`, which the body has only in title case) use the remainder-only style instead.

**Nature:** content duplication with two coexisting conventions.
**Cost of deferral:** `+1 chance of drift per trigger-phrase edit`. SKILL.md files had 36 commits on main in 30 days, 10 of them to code-review. Q-080 explicitly chose not to de-overlap, so each future routing tweak has to be made in two places. Nothing checks that the two copies agree, or which style a skill uses.

### Carrying cost: Medium
The description is the routing surface, and it is also the copy that gets edited when routing misbehaves. With the body as a second copy, the likely drift is a phrase added to or removed from the description only, leaving the body's "When to use" section stale and misleading. Having two styles means an editor cannot tell from one skill how another is laid out.

### Fix cost
- **Scope:** localized, test-only.
- **Effort:** hours. Add a bats check along the lines of my scratch script: every quoted phrase in the frontmatter description appears in the body, case-insensitively. That enforces "body is a superset" and would flag only pre-mortem, which would need its 4 description phrases copied into the body. Alternatively, pick remainder-only and assert disjointness. Either choice removes the ambiguity.
- **Risk:** low.
- **Incremental?** yes.

### Urgency Triggers
- None imminent. It becomes more pressing with each routing-misfire fix under Q-073.

**Recommendation:** Fix opportunistically

This is not a reason to hold the merge. The user explicitly accepted overlap. The debt is the unguarded duplication, not the overlap itself.

---

## 8. Hook size

**Severity:** Consider · **Confidence:** medium · **Legibility-target:** for-author
**Location:** `hooks/auto-approve-allowed-commands.sh` (697 lines; `main()` spans `:218-418`)
**Evidence:** `wc -l` gives 697 on this branch and 593 on main. 252 of the lines are comments, and about 30 header lines were added here.
**Nature:** structural and size debt.
**Cost of deferral:** about `+100 lines per security amendment`, based on this branch. Four hook commits in 30 days.

### Carrying cost: Low
Roughly 445 lines are code, so the file is under the 500-line guideline once comments are excluded. The header comments are load-bearing documentation of accepted risks (decision 53), and cutting them would cost more than the length does. `main()` at about 200 lines is the densest part.

### Fix cost
- **Scope:** localized, but splitting it into a sourced library has a deploy cost: `wiring.json` invokes the hook as a single file at `{{CLAUDE_DIR}}/hooks/…` on bare hosts. `[unverified — submitted as claim]`: whether a sourced sibling file would ship with it.
- **Effort:** hours to days.
- **Risk:** medium. This is the permission-granting path.
- **Incremental?** yes.

### Urgency Triggers
- A further hook amendment of similar size, or code rather than comments passing about 500 lines.

**Recommendation:** Carry intentionally

Doing #2 reduces duplication without a split.

---

## Recommended Order

1. **#1**: file the sandbox-half question and repoint row 53 before or with the merge. It takes minutes and prevents the only tracker from disappearing.
2. **#2 and #4** together, the next time the hook or its tests are touched. Both are small single-file changes to the same pair of files.
3. **#5**: decide the harness-warning line before Q-067 regeneration. A note on Q-067 is enough for now.
4. **#7**: a description-to-body phrase check, whenever skills are next edited in bulk.
5. **#3, #6, #8**: carry.

## Goal-Alignment Note

- **Success criterion (verbatim):** A markdown report saved to /workspace/docs/reviews/tech-debt-triage-review-2026-09-27.md, structured per the tech-debt-triage skill, with a Goal-Alignment Note.
- **Answered:** I triaged all seven in-scope items from the dispatch, plus one found while reading (#2, the duplicated settings-file walk), each with carrying cost, `+X per Y` deferral, failure cost where material, fix cost, triggers and one of the four allowed recommendations. The output has a summary table and a recommended order.
- **Out of scope:** Q-076 (not on the branch); whether each Q-080 description routes correctly (a routing question, not a debt question); re-verifying hook behavior, which I took from the fact-check reports as instructed; building the sandbox.
- **Escalate:** #1. Decision 53 says the sandbox half is "open as a follow-up question", but no such entry exists, and merging closes Q-077, the only tracker. This is a `you: judgment` item for the orchestrator to file.
- **Decisions I made:** I counted #2 as in scope because the branch adds the second copy of the walk. I ran a scratch-only phrase-coverage script for #7 and did not add it to the repo. The rates come from 30-day `git log` counts on main.
